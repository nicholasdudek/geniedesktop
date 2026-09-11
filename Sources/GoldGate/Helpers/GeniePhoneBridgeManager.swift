import AppKit
import CoreGraphics
import Foundation
import IOKit.ps
import Network

// MARK: - 📱 Genie Phone Remote Bridge & Desktop Node Identity Manager
@MainActor
public final class GeniePhoneBridgeManager: ObservableObject {
    public static let shared = GeniePhoneBridgeManager()

    // ── Node Identity & Unique Email Profile ──────────────────────────────────
    @Published public private(set) var nodeID: String = ""
    @Published public private(set) var assignedEmail: String = ""
    @Published public private(set) var localIPAddress: String = "127.0.0.1"
    @Published public private(set) var serverPort: UInt16 = 8765
    @Published public private(set) var isServerRunning: Bool = false
    @Published public private(set) var lastActionReceived: String = "None"
    @Published public private(set) var clientAccessCount: Int = 0

    // ── Apple Messages (iMessage) & iPhone Sync ──────────────────────────────
    @Published public var appleID: String = UserDefaults.standard.string(forKey: "genie.apple_id") ?? (GenieAppleAuth.discoverSystemAppleAccount()?.email ?? "")
    @Published public private(set) var isMessageWatcherActive: Bool = false
    @Published public private(set) var imessageRelayedCount: Int = 0
    @Published public private(set) var lastiMessageReceived: String = "None"
    @Published public private(set) var lastiMessageReplied: String = "None"
    @Published public private(set) var lastiMessageTime: Date? = nil

    private var listener: NWListener?
    private let networkQueue = DispatchQueue(label: "com.genie.phonebridge.network", qos: .userInitiated)
    private var imessageWatcherTimer: Timer?
    private var lastObservedRowID: Int64 = 0
    private var botReplyCache: [String] = []
    private var processedFingerprints: Set<String> = []

    public var mobileRemoteURL: String {
        return "http://\(localIPAddress):\(serverPort)"
    }

    private init() {
        initNodeIdentity()
        startiMessageWatcher()
    }

    // MARK: - Node Identity & Birth Certificate Handshake
    public func initNodeIdentity() {
        let defaults = UserDefaults.standard
        if let existing = defaults.string(forKey: "genie.desktop.node_id"), !existing.isEmpty {
            self.nodeID = existing
        } else {
            let shortUUID = UUID().uuidString.prefix(8).lowercased()
            self.nodeID = "genie-m4-\(shortUUID)"
            defaults.set(self.nodeID, forKey: "genie.desktop.node_id")
        }
        self.assignedEmail = "nicholas.m.dudek+\(self.nodeID)@icloud.com"
        self.localIPAddress = Self.resolveLocalIPAddress()

        saveBirthCertificate()
    }

    @discardableResult
    public func saveBirthCertificate() -> URL? {
        let certDict: [String: Any] = [
            "node_id": nodeID,
            "assigned_email": assignedEmail,
            "apple_id": appleID,
            "mobile_remote_url": mobileRemoteURL,
            "port": Int(serverPort),
            "device": "Apple Mac (Apple Silicon)",
            "os": "macOS",
            "protocol_version": "2.0.0",
            "initialized_at": ISO8601DateFormatter().string(from: Date()),
            "status": "ready"
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: certDict, options: [.prettyPrinted, .sortedKeys]) else {
            return nil
        }

        let notesDir = GenieStandardDirectories.notesURL
        try? FileManager.default.createDirectory(at: notesDir, withIntermediateDirectories: true)
        let fileURL = notesDir.appendingPathComponent("DESKTOP_NODE_IDENTITY.json")
        try? jsonData.write(to: fileURL)

        let tmpURL = URL(fileURLWithPath: "/tmp/DESKTOP_NODE_IDENTITY.json")
        try? jsonData.write(to: tmpURL)

        return fileURL
    }

    // MARK: - Server Lifecycle
    public func startServer(port: UInt16 = GeniePortGovernor.defaultPhoneBridgePort) {
        guard listener == nil else { return }
        let safePort = GeniePortGovernor.allocateSafePort(preferred: port)
        self.serverPort = safePort
        self.localIPAddress = Self.resolveLocalIPAddress()

        do {
            guard let nwPort = NWEndpoint.Port(rawValue: safePort) else { return }
            let params = NWParameters.tcp
            params.allowLocalEndpointReuse = true
            let newListener = try NWListener(using: params, on: nwPort)

            newListener.stateUpdateHandler = { [weak self] state in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    switch state {
                    case .ready:
                        self.isServerRunning = true
                        self.serverPort = safePort
                        self.saveBirthCertificate()
                        print("🪔 GENIE PHONE BRIDGE: Active on http://\(self.localIPAddress):\(safePort)")
                    case .failed(let error):
                        self.isServerRunning = false
                        self.listener?.cancel()
                        self.listener = nil
                        print("🪔 GENIE PHONE BRIDGE: Listener failed on port \(safePort): \(error)")

                        // Automatic fallback to sliced port if port is already in use
                        var isAddressInUse = false
                        if case .posix(let code) = error, code == .EADDRINUSE {
                            isAddressInUse = true
                        } else if (error as NSError).domain == NSPOSIXErrorDomain && (error as NSError).code == 48 {
                            isAddressInUse = true
                        }

                        if isAddressInUse && safePort < GeniePortGovernor.genieServiceSlice.upperBound {
                            let nextPort = GeniePortGovernor.allocateSafePort(preferred: safePort + 1)
                            print("🪔 GENIE PHONE BRIDGE: Port \(safePort) in use, attempting fallback to sliced port \(nextPort)...")
                            self.startServer(port: nextPort)
                        }
                    case .cancelled:
                        self.isServerRunning = false
                    default:
                        break
                    }
                }
            }

            newListener.newConnectionHandler = { [weak self] connection in
                Task { @MainActor [weak self] in
                    self?.acceptConnection(connection)
                }
            }

            newListener.start(queue: networkQueue)
            self.listener = newListener
        } catch {
            self.listener?.cancel()
            self.listener = nil
            self.isServerRunning = false
            print("🪔 GENIE PHONE BRIDGE: Start error on port \(port): \(error)")
            if port < 8780 {
                let nextPort = port + 1
                print("🪔 GENIE PHONE BRIDGE: Retrying on port \(nextPort)...")
                startServer(port: nextPort)
            }
        }
    }

    public func stopServer() {
        listener?.cancel()
        listener = nil
        isServerRunning = false
    }

    // MARK: - Connection Handler
    private func acceptConnection(_ connection: NWConnection) {
        connection.start(queue: networkQueue)
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, _, error in
            guard let data = data, let reqStr = String(data: data, encoding: .utf8), error == nil else {
                connection.cancel()
                return
            }
            Task { @MainActor [weak self] in
                self?.handleHTTPRequest(reqStr, on: connection)
            }
        }
    }

    private func handleHTTPRequest(_ request: String, on connection: NWConnection) {
        self.clientAccessCount += 1
        let lines = request.components(separatedBy: "\r\n")
        guard let reqLine = lines.first else {
            sendResponse(connection: connection, status: 400, type: "text/plain", data: Data("Bad Request".utf8))
            return
        }

        let tokens = reqLine.split(separator: " ").map(String.init)
        guard tokens.count >= 2 else {
            sendResponse(connection: connection, status: 400, type: "text/plain", data: Data("Bad Request".utf8))
            return
        }

        let rawPath = tokens[1]
        let urlComponents = URLComponents(string: rawPath)
        let path = urlComponents?.path ?? rawPath

        switch path {
        case "/", "/index.html":
            let html = renderMobileWebUI()
            sendResponse(connection: connection, status: 200, type: "text/html; charset=utf-8", data: Data(html.utf8))

        case "/duo", "/duo.html":
            let html = renderiPhoneDuoWebUI()
            sendResponse(connection: connection, status: 200, type: "text/html; charset=utf-8", data: Data(html.utf8))

        case "/api/status":
            let statusDict: [String: Any] = [
                "node_id": nodeID,
                "assigned_email": assignedEmail,
                "apple_id": appleID,
                "mobile_url": mobileRemoteURL,
                "server_running": isServerRunning,
                "imessage_watcher_active": isMessageWatcherActive,
                "imessage_relayed_count": imessageRelayedCount,
                "last_imessage_received": lastiMessageReceived,
                "last_imessage_replied": lastiMessageReplied,
                "access_count": clientAccessCount,
                "last_action": lastActionReceived,
                "screen_width": NSScreen.main?.frame.width ?? 0,
                "screen_height": NSScreen.main?.frame.height ?? 0
            ]
            let jsonData = (try? JSONSerialization.data(withJSONObject: statusDict, options: [.prettyPrinted])) ?? Data("{}".utf8)
            sendResponse(connection: connection, status: 200, type: "application/json", data: jsonData)

        case "/api/frame.jpg", "/stream.jpg", "/api/screen.jpg":
            if let jpegData = Self.captureScreenJPEG(quality: 0.60) {
                sendResponse(connection: connection, status: 200, type: "image/jpeg", data: jpegData)
            } else {
                sendResponse(connection: connection, status: 500, type: "text/plain", data: Data("Screen capture failed".utf8))
            }

        case "/api/action/enter":
            Self.pressEnter()
            self.lastActionReceived = "ENTER Key Pressed"
            let res = ["status": "ok", "action": "enter", "node_id": nodeID]
            let resData = (try? JSONSerialization.data(withJSONObject: res)) ?? Data()
            sendResponse(connection: connection, status: 200, type: "application/json", data: resData)

        case "/api/action/key":
            let keyName = urlComponents?.queryItems?.first(where: { $0.name == "name" })?.value ?? "return"
            Self.pressKey(named: keyName)
            self.lastActionReceived = "Key '\(keyName)' Pressed"
            let res = ["status": "ok", "action": "key", "name": keyName]
            let resData = (try? JSONSerialization.data(withJSONObject: res)) ?? Data()
            sendResponse(connection: connection, status: 200, type: "application/json", data: resData)

        case "/api/action/click":
            let xStr = urlComponents?.queryItems?.first(where: { $0.name == "x_pct" })?.value ?? "0.5"
            let yStr = urlComponents?.queryItems?.first(where: { $0.name == "y_pct" })?.value ?? "0.5"
            let xPct = Double(xStr) ?? 0.5
            let yPct = Double(yStr) ?? 0.5
            Self.clickScreen(xPct: xPct, yPct: yPct)
            self.lastActionReceived = "Clicked at (\(Int(xPct * 100))%, \(Int(yPct * 100))%)"
            let res: [String: Any] = ["status": "ok", "action": "click", "x_pct": xPct, "y_pct": yPct]
            let resData = (try? JSONSerialization.data(withJSONObject: res)) ?? Data()
            sendResponse(connection: connection, status: 200, type: "application/json", data: resData)

        case "/api/action/type":
            let text = urlComponents?.queryItems?.first(where: { $0.name == "text" })?.value ?? ""
            if !text.isEmpty {
                Self.typeText(text)
                self.lastActionReceived = "Typed '\(text.prefix(15))...'"
            }
            let res = ["status": "ok", "action": "type", "text": text]
            let resData = (try? JSONSerialization.data(withJSONObject: res)) ?? Data()
            sendResponse(connection: connection, status: 200, type: "application/json", data: resData)

        case "/api/imessage/send":
            let recipient = urlComponents?.queryItems?.first(where: { $0.name == "recipient" })?.value ?? self.appleID
            let message = urlComponents?.queryItems?.first(where: { $0.name == "message" })?.value ?? "• [Ping from Genie]"
            let success = sendiMessage(to: recipient, message: message)
            let res: [String: Any] = ["status": success ? "ok" : "error", "recipient": recipient, "message": message]
            let resData = (try? JSONSerialization.data(withJSONObject: res)) ?? Data()
            sendResponse(connection: connection, status: success ? 200 : 500, type: "application/json", data: resData)

        case "/api/imessage/ping":
            let summary = urlComponents?.queryItems?.first(where: { $0.name == "summary" })?.value
            let success = pingNicholasPhone(withSummary: summary)
            let res: [String: Any] = ["status": success ? "ok" : "error", "dispatched": success, "apple_id": appleID]
            let resData = (try? JSONSerialization.data(withJSONObject: res)) ?? Data()
            sendResponse(connection: connection, status: success ? 200 : 500, type: "application/json", data: resData)

        case "/api/imessage/status":
            let res: [String: Any] = [
                "apple_id": appleID,
                "watcher_active": isMessageWatcherActive,
                "relayed_count": imessageRelayedCount,
                "last_received": lastiMessageReceived,
                "last_replied": lastiMessageReplied,
                "last_time": lastiMessageTime?.description ?? "Never"
            ]
            let resData = (try? JSONSerialization.data(withJSONObject: res)) ?? Data()
            sendResponse(connection: connection, status: 200, type: "application/json", data: resData)

        case "/api/genie/chat":
            let prompt = urlComponents?.queryItems?.first(where: { $0.name == "prompt" })?.value ?? ""
            let relay = urlComponents?.queryItems?.first(where: { $0.name == "relay" })?.value != "false"
            
            // Execute quick local inference
            let reply = Self.quickLocalGenieInference(prompt: prompt)
            var imessageSent = false
            if relay {
                imessageSent = sendiMessage(to: self.appleID, message: reply)
            }
            let res: [String: Any] = [
                "status": "ok",
                "prompt": prompt,
                "response": reply,
                "imessage_relayed": imessageSent
            ]
            let resData = (try? JSONSerialization.data(withJSONObject: res)) ?? Data()
            sendResponse(connection: connection, status: 200, type: "application/json", data: resData)

        case "/api/imessage/received":
            let sender = urlComponents?.queryItems?.first(where: { $0.name == "sender" })?.value ?? self.appleID
            let message = urlComponents?.queryItems?.first(where: { $0.name == "message" })?.value ?? ""
            if !message.isEmpty {
                GenieiMessageExtensionManager.shared.processIncomingMessage(rowID: 0, text: message, sender: sender)
            }
            let res: [String: Any] = ["status": "ok", "dispatched": true]
            let resData = (try? JSONSerialization.data(withJSONObject: res)) ?? Data()
            sendResponse(connection: connection, status: 200, type: "application/json", data: resData)

        case "/api/sleep/status":
            let res: [String: Any] = [
                "anti_sleep_active": GenieSleepPreventionManager.shared.isSleepDisabled,
                "description": GenieSleepPreventionManager.shared.statusDescription
            ]
            let resData = (try? JSONSerialization.data(withJSONObject: res)) ?? Data()
            sendResponse(connection: connection, status: 200, type: "application/json", data: resData)

        case "/api/sleep/toggle":
            GenieSleepPreventionManager.shared.toggleSleepPrevention()
            let res: [String: Any] = [
                "anti_sleep_active": GenieSleepPreventionManager.shared.isSleepDisabled,
                "description": GenieSleepPreventionManager.shared.statusDescription
            ]
            let resData = (try? JSONSerialization.data(withJSONObject: res)) ?? Data()
            sendResponse(connection: connection, status: 200, type: "application/json", data: resData)

        case "/api/imessage/extension/install":
            GenieiMessageExtensionManager.shared.installExtensionFiles()
            let res: [String: Any] = ["status": "ok", "extension_installed": true]
            let resData = (try? JSONSerialization.data(withJSONObject: res)) ?? Data()
            sendResponse(connection: connection, status: 200, type: "application/json", data: resData)

        default:
            sendResponse(connection: connection, status: 404, type: "text/plain", data: Data("Not Found".utf8))
        }
    }

    private func sendResponse(connection: NWConnection, status: Int, type: String, data: Data) {
        var header = "HTTP/1.1 \(status) OK\r\n"
        header += "Content-Type: \(type)\r\n"
        header += "Content-Length: \(data.count)\r\n"
        header += "Access-Control-Allow-Origin: *\r\n"
        header += "Cache-Control: no-cache, no-store, must-revalidate\r\n"
        header += "Connection: close\r\n\r\n"

        var responseData = Data(header.utf8)
        responseData.append(data)

        connection.send(content: responseData, completion: .contentProcessed { _ in
            connection.cancel()
        })
    }

    // MARK: - Native iMessage Transmission
    @discardableResult
    public func sendiMessage(to recipient: String = "", message: String) -> Bool {
        let cleanRecipient = recipient.isEmpty ? "me" : recipient
        let success = GenieiMessageExtensionManager.shared.sendiMessageDirect(to: cleanRecipient, message: message)
        if success {
            let trimmed = message.trimmingCharacters(in: .whitespacesAndNewlines)
            botReplyCache.append(trimmed)
            if botReplyCache.count > 150 { botReplyCache.removeFirst() }
            self.lastiMessageReplied = String(trimmed.prefix(80))
            self.lastiMessageTime = Date()
            self.imessageRelayedCount += 1
            return true
        }
        return false
    }

    @discardableResult
    public func pingPhone(withSummary summary: String? = nil) -> Bool {
        let content: String
        if let custom = summary, !custom.isEmpty {
            content = "🧞 [Genie Mac Ping]:\n\(custom)"
        } else {
            let timeStr = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .short)
            let battery = Self.quickBatteryStatus()
            content = "🧞 [Genie Live Ping - \(timeStr)]\nMac is responsive. Battery: \(battery).\nAttached reply from active workspace ready."
        }
        return sendiMessage(to: "me", message: content)
    }

    @discardableResult
    public func pingNicholasPhone(withSummary summary: String? = nil) -> Bool {
        return pingPhone(withSummary: summary)
    }

    // MARK: - Background Apple Messages Listener (Unified with Extension)
    public func startiMessageWatcher() {
        self.isMessageWatcherActive = true
        GenieiMessageExtensionManager.shared.startWatcher()
    }

    public func stopiMessageWatcher() {
        self.isMessageWatcherActive = false
        GenieiMessageExtensionManager.shared.stopWatcher()
    }

    private static func queryMaxChatDBRowID() -> Int64 {
        guard GenieCapabilities.canReadForeignAppContainers,
              GenieCapabilities.canSpawnSubprocesses else { return 0 }
        let chatDBPath = ("~/Library/Messages/chat.db" as NSString).expandingTildeInPath
        guard FileManager.default.fileExists(atPath: chatDBPath) else { return 0 }

        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/sqlite3")
        proc.arguments = [chatDBPath, "SELECT MAX(ROWID) FROM message;"]
        let pipe = Pipe()
        proc.standardOutput = pipe

        do {
            try proc.run()
            proc.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
               let id = Int64(output) {
                return id
            }
        } catch {}
        return 0
    }

    // MARK: - Local Genie Inference Helper
    public static func quickLocalGenieInference(prompt: String) -> String {
        let clean = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let battery = quickBatteryStatus()
        let timeStr = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .short)

        if clean.isEmpty || ["ping", "hi", "hey", "status", "?"].contains(clean.lowercased()) {
            return "🧞 [Genie Attached Reply • \(timeStr)]\nMac status: Active and responsive.\nBattery: \(battery)\nConnection to iPhone confirmed."
        }

        // Attempt Ollama local provider
        if let url = URL(string: "http://localhost:11434/api/generate") {
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            req.timeoutInterval = 25

            let system = "You are Genie, an intelligent personal macOS assistant. Communicate cleanly and concisely for iPhone reading. Time: \(timeStr), Battery: \(battery)."
            let payload: [String: Any] = [
                "model": "genie:latest",
                "prompt": "\(system)\n\nUser: \(clean)\n\nGenie:",
                "stream": false,
                "options": ["temperature": 0.7, "num_predict": 350]
            ]

            if let body = try? JSONSerialization.data(withJSONObject: payload) {
                req.httpBody = body
                let semaphore = DispatchSemaphore(value: 0)
                var resultText = ""

                URLSession.shared.dataTask(with: req) { data, _, _ in
                    defer { semaphore.signal() }
                    if let data = data,
                       let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let resp = json["response"] as? String {
                        resultText = resp.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                }.resume()

                _ = semaphore.wait(timeout: .now() + 20)
                if !resultText.isEmpty {
                    return resultText
                }
            }
        }

        return "🧞 [Genie Live Reply]\nReceived: \"\(clean)\"\nMac workspace active (Battery: \(battery))."
    }

    /// Battery summary read straight from IOKit rather than by parsing the
    /// second line of `pmset -g batt`. Same information, no subprocess, and it
    /// keeps working in the sandboxed build.
    public static func quickBatteryStatus() -> String {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue()
                as? [CFTypeRef],
              let first = sources.first,
              let info = IOPSGetPowerSourceDescription(snapshot, first)?
                .takeUnretainedValue() as? [String: Any] else {
            return "Normal"
        }

        let capacity = info[kIOPSCurrentCapacityKey as String] as? Int
        let maxCapacity = info[kIOPSMaxCapacityKey as String] as? Int ?? 100
        let state = info[kIOPSPowerSourceStateKey as String] as? String
        let isCharging = info[kIOPSIsChargingKey as String] as? Bool ?? false

        guard let capacity, maxCapacity > 0 else { return "Normal" }
        let percent = Int((Double(capacity) / Double(maxCapacity)) * 100.0)

        let plugged = state == (kIOPSACPowerValue as String)
        let status: String
        if isCharging {
            status = "charging"
        } else if plugged {
            status = "charged"
        } else {
            status = "discharging"
        }
        return "\(percent)%; \(status)"
    }

    // MARK: - Native Hardware Input Actions
    public static func pressEnter() {
        let returnKey: CGKeyCode = 36
        if let down = CGEvent(keyboardEventSource: nil, virtualKey: returnKey, keyDown: true),
           let up = CGEvent(keyboardEventSource: nil, virtualKey: returnKey, keyDown: false) {
            down.post(tap: .cghidEventTap)
            usleep(20_000)
            up.post(tap: .cghidEventTap)
        } else {
            // In-process Apple Event instead of spawning /usr/bin/osascript:
            // `com.apple.systemevents` is entitled in both distribution profiles.
            var errorInfo: NSDictionary?
            NSAppleScript(source: "tell application \"System Events\" to key code 36")?
                .executeAndReturnError(&errorInfo)
        }
    }

    public static func pressKey(named name: String) {
        let keyMap: [String: CGKeyCode] = [
            "return": 36, "enter": 36,
            "space": 49,
            "escape": 53, "esc": 53,
            "tab": 48,
            "delete": 51, "backspace": 51,
            "up": 126, "down": 125, "left": 123, "right": 124
        ]
        let code = keyMap[name.lowercased()] ?? 36
        if let down = CGEvent(keyboardEventSource: nil, virtualKey: code, keyDown: true),
           let up = CGEvent(keyboardEventSource: nil, virtualKey: code, keyDown: false) {
            down.post(tap: .cghidEventTap)
            usleep(20_000)
            up.post(tap: .cghidEventTap)
        }
    }

    public static func clickScreen(xPct: Double, yPct: Double) {
        guard let screen = NSScreen.main else { return }
        let sWidth = screen.frame.width
        let sHeight = screen.frame.height
        let clampedX = max(0.0, min(1.0, xPct))
        let clampedY = max(0.0, min(1.0, yPct))

        let screenX = screen.frame.origin.x + (clampedX * sWidth)
        let screenY = (screen.frame.origin.y + sHeight) - (clampedY * sHeight)
        let pt = CGPoint(x: screenX, y: screenY)

        if let move = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: pt, mouseButton: .left),
           let down = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: pt, mouseButton: .left),
           let up = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: pt, mouseButton: .left) {
            move.post(tap: .cghidEventTap)
            usleep(15_000)
            down.post(tap: .cghidEventTap)
            usleep(20_000)
            up.post(tap: .cghidEventTap)
        }
    }

    public static func typeText(_ text: String) {
        for char in text {
            let str = String(char)
            var utf16Chars = Array(str.utf16)
            if let down = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true),
               let up = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: false) {
                down.keyboardSetUnicodeString(stringLength: utf16Chars.count, unicodeString: &utf16Chars)
                up.keyboardSetUnicodeString(stringLength: utf16Chars.count, unicodeString: &utf16Chars)
                down.post(tap: .cghidEventTap)
                usleep(10_000)
                up.post(tap: .cghidEventTap)
                usleep(15_000)
            }
        }
    }

    // MARK: - Native Screen Capture
    public static func captureScreenJPEG(quality: CGFloat = 0.60) -> Data? {
        guard let screen = NSScreen.main else { return nil }
        let rect = screen.frame
        guard let cgImage = safeCGWindowListCreateImage(rect, .optionOnScreenOnly, kCGNullWindowID, [.bestResolution, .nominalResolution]) else {
            return nil
        }
        let bitmap = NSBitmapImageRep(cgImage: cgImage)
        return bitmap.representation(using: .jpeg, properties: [.compressionFactor: quality])
    }

    // MARK: - IP Address Resolution
    public static func resolveLocalIPAddress() -> String {
        let address = "127.0.0.1"
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return address }
        defer { freeifaddrs(ifaddr) }

        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                if name == "en0" || name == "en1" || name == "bridge0" {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                                &hostname, socklen_t(hostname.count),
                                nil, socklen_t(0), NI_NUMERICHOST)
                    let ipStr = String(cString: hostname)
                    if !ipStr.isEmpty && ipStr != "127.0.0.1" {
                        return ipStr
                    }
                }
            }
        }
        return address
    }

    // MARK: - Liquid Dark Glass Mobile Web UI (Dual-Mode: Remote + Genie AI)
    public func renderMobileWebUI() -> String {
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover">
            <meta name="apple-mobile-web-app-capable" content="yes">
            <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
            <title>Genie Remote & Phone Bridge</title>
            <style>
                :root {
                    --bg-color: #07090e;
                    --surface-bg: rgba(14, 20, 34, 0.88);
                    --border-glass: rgba(255, 255, 255, 0.1);
                    --accent-cyan: #00d2ff;
                    --accent-blue: #0066ff;
                    --accent-green: #00ff88;
                    --text-main: #f0f4fc;
                    --text-dim: #8da2c0;
                }
                * { box-sizing: border-box; margin: 0; padding: 0; -webkit-tap-highlight-color: transparent; }
                body {
                    background: var(--bg-color);
                    color: var(--text-main);
                    font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", sans-serif;
                    overflow: hidden;
                    height: 100vh;
                    display: flex;
                    flex-direction: column;
                }
                header {
                    padding: calc(env(safe-area-inset-top, 8px) + 8px) 14px 10px 14px;
                    background: rgba(12, 17, 29, 0.9);
                    backdrop-filter: blur(25px);
                    display: flex;
                    justify-content: space-between;
                    align-items: center;
                    border-bottom: 1px solid var(--border-glass);
                    z-index: 20;
                }
                .logo-group { display: flex; align-items: center; gap: 8px; }
                .pulse-dot {
                    width: 8px; height: 8px;
                    background: var(--accent-green);
                    border-radius: 50%;
                    box-shadow: 0 0 10px var(--accent-green);
                }
                .logo-title {
                    font-size: 0.95rem;
                    font-weight: 700;
                    background: linear-gradient(135deg, #ffffff, #9ec5fe);
                    -webkit-background-clip: text;
                    -webkit-text-fill-color: transparent;
                }
                .nav-tabs {
                    display: flex;
                    background: rgba(255, 255, 255, 0.08);
                    border-radius: 12px;
                    padding: 3px;
                    gap: 2px;
                }
                .tab-btn {
                    padding: 5px 12px;
                    border-radius: 9px;
                    border: none;
                    background: transparent;
                    color: var(--text-dim);
                    font-size: 0.78rem;
                    font-weight: 600;
                    cursor: pointer;
                }
                .tab-btn.active {
                    background: rgba(255, 255, 255, 0.16);
                    color: #ffffff;
                }
                .view-container {
                    flex: 1;
                    position: relative;
                    overflow: hidden;
                    display: flex;
                    flex-direction: column;
                }
                #view-remote { display: flex; flex-direction: column; width: 100%; height: 100%; }
                #viewport {
                    flex: 1;
                    position: relative;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    background: #04060a;
                    overflow: hidden;
                }
                #screen-img {
                    width: 100%; height: 100%;
                    object-fit: contain;
                    cursor: crosshair;
                }
                .control-panel {
                    background: var(--surface-bg);
                    backdrop-filter: blur(25px);
                    border-top: 1px solid var(--border-glass);
                    padding: 8px 12px calc(env(safe-area-inset-bottom, 10px) + 6px) 12px;
                    display: flex;
                    flex-direction: column;
                    gap: 6px;
                }
                .main-action-row { display: flex; gap: 8px; align-items: center; }
                .btn-enter {
                    flex: 2;
                    height: 48px;
                    background: linear-gradient(135deg, var(--accent-cyan) 0%, var(--accent-blue) 100%);
                    color: #fff;
                    font-size: 1.05rem;
                    font-weight: 800;
                    border: none;
                    border-radius: 12px;
                    cursor: pointer;
                }
                .btn-enter:active { transform: scale(0.96); }
                .aux-row { display: flex; gap: 5px; overflow-x: auto; scrollbar-width: none; }
                .aux-row::-webkit-scrollbar { display: none; }
                .btn-key {
                    flex: 1;
                    min-width: 52px;
                    height: 34px;
                    background: rgba(255, 255, 255, 0.08);
                    color: #e2e8f0;
                    border: 1px solid var(--border-glass);
                    border-radius: 8px;
                    font-size: 0.8rem;
                    font-weight: 600;
                    cursor: pointer;
                }
                .type-input-group { display: flex; gap: 6px; }
                .type-input {
                    flex: 1;
                    height: 34px;
                    background: rgba(255, 255, 255, 0.06);
                    border: 1px solid var(--border-glass);
                    border-radius: 8px;
                    padding: 0 10px;
                    color: #fff;
                    font-size: 0.88rem;
                    outline: none;
                }
                .btn-send {
                    height: 34px;
                    padding: 0 12px;
                    background: rgba(255, 255, 255, 0.12);
                    border: 1px solid var(--border-glass);
                    border-radius: 8px;
                    color: var(--accent-cyan);
                    font-weight: 600;
                    cursor: pointer;
                }
                #view-genie {
                    display: none;
                    flex-direction: column;
                    width: 100%;
                    height: 100%;
                    background: #080b12;
                }
                .imessage-banner {
                    background: linear-gradient(90deg, rgba(0, 110, 255, 0.15), rgba(0, 210, 255, 0.08));
                    border-bottom: 1px solid var(--border-glass);
                    padding: 8px 14px;
                    display: flex;
                    justify-content: space-between;
                    align-items: center;
                    font-size: 0.76rem;
                    color: #bcd4f5;
                }
                .badge-green {
                    background: rgba(0, 255, 136, 0.15);
                    color: var(--accent-green);
                    padding: 2px 8px;
                    border-radius: 12px;
                    font-weight: 600;
                    border: 1px solid rgba(0, 255, 136, 0.3);
                }
                .chat-scroll {
                    flex: 1;
                    overflow-y: auto;
                    padding: 14px;
                    display: flex;
                    flex-direction: column;
                    gap: 12px;
                }
                .chat-msg {
                    max-width: 85%;
                    padding: 10px 14px;
                    border-radius: 16px;
                    font-size: 0.9rem;
                    line-height: 1.4;
                }
                .chat-msg.user {
                    align-self: flex-end;
                    background: linear-gradient(135deg, #007aff, #0056cc);
                    color: #fff;
                    border-bottom-right-radius: 4px;
                }
                .chat-msg.genie {
                    align-self: flex-start;
                    background: rgba(255, 255, 255, 0.08);
                    border: 1px solid rgba(255, 255, 255, 0.12);
                    color: #eef2fa;
                    border-bottom-left-radius: 4px;
                }
                .chat-meta {
                    font-size: 0.68rem;
                    color: rgba(255, 255, 255, 0.45);
                    margin-top: 4px;
                    text-align: right;
                }
                .genie-control-panel {
                    background: var(--surface-bg);
                    backdrop-filter: blur(25px);
                    border-top: 1px solid var(--border-glass);
                    padding: 10px 14px calc(env(safe-area-inset-bottom, 12px) + 8px) 14px;
                    display: flex;
                    flex-direction: column;
                    gap: 8px;
                }
                .quick-actions {
                    display: flex;
                    gap: 6px;
                    overflow-x: auto;
                    scrollbar-width: none;
                }
                .quick-actions::-webkit-scrollbar { display: none; }
                .pill-btn {
                    background: rgba(255, 255, 255, 0.07);
                    border: 1px solid var(--border-glass);
                    border-radius: 20px;
                    padding: 4px 10px;
                    font-size: 0.74rem;
                    color: #cad8ee;
                    white-space: nowrap;
                    cursor: pointer;
                }
                .chat-input-row { display: flex; gap: 8px; align-items: center; }
                .chat-input {
                    flex: 1;
                    height: 40px;
                    background: rgba(255, 255, 255, 0.08);
                    border: 1px solid var(--border-glass);
                    border-radius: 20px;
                    padding: 0 14px;
                    color: #fff;
                    font-size: 0.92rem;
                    outline: none;
                }
                .btn-genie-send {
                    width: 40px; height: 40px;
                    border-radius: 50%;
                    border: none;
                    background: linear-gradient(135deg, var(--accent-cyan), var(--accent-blue));
                    color: #fff;
                    font-weight: bold;
                    cursor: pointer;
                }
            </style>
        </head>
        <body>
            <header>
                <div class="logo-group">
                    <div class="pulse-dot"></div>
                    <span class="logo-title">Genie Remote & Phone Bridge</span>
                </div>
                <div class="nav-tabs">
                    <button id="tab-remote" class="tab-btn active" onclick="switchTab('remote')">🖥️ Screen</button>
                    <button id="tab-genie" class="tab-btn" onclick="switchTab('genie')">💬 Genie AI</button>
                </div>
            </header>

            <div class="view-container">
                <div id="view-remote">
                    <div id="viewport">
                        <img id="screen-img" src="/api/frame.jpg" onclick="handleTap(event)" alt="Desktop Screen" />
                    </div>

                    <div class="control-panel">
                        <div class="main-action-row">
                            <button class="btn-enter" onclick="sendEnter()"><span>↵</span> ENTER</button>
                            <button class="btn-key" style="height:48px; flex:1;" onclick="sendKey('space')">Space</button>
                            <button class="btn-key" style="height:48px; flex:1;" onclick="sendKey('escape')">Esc</button>
                        </div>

                        <div class="aux-row">
                            <button class="btn-key" onclick="sendKey('backspace')">⌫ Del</button>
                            <button class="btn-key" onclick="sendKey('tab')">Tab</button>
                            <button class="btn-key" onclick="sendKey('up')">▲ Up</button>
                            <button class="btn-key" onclick="sendKey('down')">▼ Down</button>
                            <button class="btn-key" onclick="sendKey('left')">◀ Left</button>
                            <button class="btn-key" onclick="sendKey('right')">▶ Right</button>
                        </div>

                        <form class="type-input-group" onsubmit="event.preventDefault(); sendType();">
                            <input type="text" id="type-input" class="type-input" placeholder="Type on desktop..." />
                            <button type="submit" class="btn-send">Send</button>
                        </form>
                    </div>
                </div>

                <div id="view-genie">
                    <div class="imessage-banner">
                        <div><span>📱 iMessage: </span><strong>\(appleID)</strong> • <span style="font-size:0.75rem; opacity:0.7;">(\(nodeID))</span></div>
                        <div class="badge-green">Sync Active</div>
                    </div>

                    <div class="chat-scroll" id="chat-stream">
                        <div class="chat-msg genie">
                            🧞 Welcome! Talk to your local provider Genie, or text your Apple login directly from your iPhone.
                            <div class="chat-meta">Local Provider (genie:latest)</div>
                        </div>
                    </div>

                    <div class="genie-control-panel">
                        <div class="quick-actions">
                            <button class="pill-btn" onclick="triggerSelfPing()">⚡ Ping Self / Status</button>
                            <button class="pill-btn" onclick="quickPrompt('What is the battery and system status?')">🔋 Battery & Focus</button>
                            <button class="pill-btn" onclick="quickPrompt('List active windows and workspace state')">🪟 Windows</button>
                        </div>

                        <div style="display:flex; justify-content:space-between; font-size:0.74rem; color:var(--text-dim);">
                            <label style="display:flex; align-items:center; gap:6px; cursor:pointer;">
                                <input type="checkbox" id="imessage-relay-toggle" checked />
                                <span>Mirror replies to Apple Messages</span>
                            </label>
                            <span id="sync-counter">Relayed: \(imessageRelayedCount)</span>
                        </div>

                        <form class="chat-input-row" onsubmit="event.preventDefault(); sendGenieMessage();">
                            <input id="genie-prompt-input" class="chat-input" type="text" placeholder="Ask local provider Genie..." autocomplete="off" />
                            <button type="submit" class="btn-genie-send">➤</button>
                        </form>
                    </div>
                </div>
            </div>

            <script>
                let isRefreshing = true;
                setInterval(() => {
                    if (!isRefreshing) return;
                    const img = document.getElementById('screen-img');
                    img.src = '/api/frame.jpg?t=' + Date.now();
                }, 500);

                function switchTab(tab) {
                    document.getElementById('tab-remote').classList.toggle('active', tab === 'remote');
                    document.getElementById('tab-genie').classList.toggle('active', tab === 'genie');
                    document.getElementById('view-remote').style.display = tab === 'remote' ? 'flex' : 'none';
                    document.getElementById('view-genie').style.display = tab === 'genie' ? 'flex' : 'none';
                    isRefreshing = (tab === 'remote');
                }

                function sendEnter() {
                    navigator.vibrate && navigator.vibrate(25);
                    fetch('/api/action/enter', { method: 'POST' });
                }

                function sendKey(name) {
                    navigator.vibrate && navigator.vibrate(15);
                    fetch('/api/action/key?name=' + encodeURIComponent(name), { method: 'POST' });
                }

                function sendType() {
                    const input = document.getElementById('type-input');
                    const val = input.value;
                    if (!val) return;
                    fetch('/api/action/type?text=' + encodeURIComponent(val), { method: 'POST' });
                    input.value = '';
                }

                function handleTap(e) {
                    navigator.vibrate && navigator.vibrate(20);
                    const rect = e.target.getBoundingClientRect();
                    const xPct = (e.clientX - rect.left) / rect.width;
                    const yPct = (e.clientY - rect.top) / rect.height;
                    fetch('/api/action/click?x_pct=' + xPct + '&y_pct=' + yPct, { method: 'POST' });
                }

                function appendMessage(sender, text, meta) {
                    const stream = document.getElementById('chat-stream');
                    const bubble = document.createElement('div');
                    bubble.className = `chat-msg ${sender}`;
                    bubble.textContent = text;
                    if (meta) {
                        const metaDiv = document.createElement('div');
                        metaDiv.className = 'chat-meta';
                        metaDiv.textContent = meta;
                        bubble.appendChild(metaDiv);
                    }
                    stream.appendChild(bubble);
                    stream.scrollTop = stream.scrollHeight;
                }

                async function sendGenieMessage() {
                    const input = document.getElementById('genie-prompt-input');
                    const prompt = input.value.trim();
                    if (!prompt) return;

                    appendMessage('user', prompt, new Date().toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'}));
                    input.value = '';

                    const relay = document.getElementById('imessage-relay-toggle').checked;
                    try {
                        const res = await fetch('/api/genie/chat?prompt=' + encodeURIComponent(prompt) + '&relay=' + relay, { method: 'POST' });
                        const data = await res.json();
                        const meta = (data.imessage_relayed ? '📱 Sent to Apple Messages • ' : '') + 'Genie Local';
                        appendMessage('genie', data.response, meta);
                    } catch (err) {
                        appendMessage('genie', 'Error contacting local Genie provider.', 'Network Error');
                    }
                }

                function quickPrompt(p) {
                    document.getElementById('genie-prompt-input').value = p;
                    sendGenieMessage();
                }

                async function triggerSelfPing() {
                    appendMessage('user', '⚡ [Triggered Self-Ping / Chat Attachment]', 'From iPhone');
                    try {
                        const res = await fetch('/api/imessage/ping', { method: 'POST' });
                        const data = await res.json();
                        appendMessage('genie', 'Dispatched ping and latest chat attachment to \(appleID)', '📱 Sent to Apple Messages');
                    } catch (e) {}
                }
            </script>
        </body>
        </html>
        """
    }

    // MARK: - 📱 iPhone Duo Companion Interface (Responsive to Mac, iOS & Duo)
    public func renderiPhoneDuoWebUI() -> String {
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover">
            <meta name="apple-mobile-web-app-capable" content="yes">
            <meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
            <title>Genie • Responsive Companion (Mac, iOS, iPhone Duo)</title>
            <style>
                :root {
                    --bg-dark: #07090e;
                    --glass-surface: rgba(18, 24, 38, 0.85);
                    --glass-border: rgba(255, 255, 255, 0.12);
                    --accent-cyan: #00d2ff;
                    --accent-pink: #ff2d55;
                    --accent-green: #30d158;
                    --accent-purple: #af52de;
                    --text-main: #f5f7fa;
                    --text-muted: #8e9bb0;
                    --hinge-width: 8px;
                }
                * { box-sizing: border-box; margin: 0; padding: 0; -webkit-tap-highlight-color: transparent; }
                html, body {
                    width: 100vw;
                    height: 100vh;
                    height: 100dvh;
                    background: var(--bg-dark);
                    color: var(--text-main);
                    font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", sans-serif;
                    overflow: hidden;
                    display: flex;
                    flex-direction: column;
                    padding-top: env(safe-area-inset-top, 0);
                    padding-bottom: env(safe-area-inset-bottom, 0);
                }
                
                /* Top Header Ribbon */
                .duo-header {
                    height: 52px;
                    background: var(--glass-surface);
                    backdrop-filter: blur(24px);
                    border-bottom: 1px solid var(--glass-border);
                    display: flex;
                    align-items: center;
                    justify-content: space-between;
                    padding: 0 16px;
                    flex-shrink: 0;
                    z-index: 100;
                }
                .brand-title {
                    font-weight: 700;
                    font-size: 14px;
                    display: flex;
                    align-items: center;
                    gap: 6px;
                }
                
                /* Responsive Mode Switcher Pill */
                .mode-segmented-control {
                    display: flex;
                    background: rgba(255, 255, 255, 0.08);
                    padding: 2px;
                    border-radius: 16px;
                    border: 1px solid var(--glass-border);
                }
                .mode-btn {
                    background: transparent;
                    border: none;
                    color: var(--text-muted);
                    padding: 4px 10px;
                    border-radius: 14px;
                    font-size: 11px;
                    font-weight: 600;
                    cursor: pointer;
                    transition: all 0.2s ease;
                }
                .mode-btn.active {
                    background: var(--accent-cyan);
                    color: #000;
                    box-shadow: 0 2px 8px rgba(0, 210, 255, 0.35);
                }

                .duo-badge {
                    display: flex;
                    align-items: center;
                    gap: 6px;
                    font-size: 11px;
                    font-weight: 600;
                    color: var(--accent-cyan);
                    background: rgba(0, 210, 255, 0.12);
                    padding: 3px 8px;
                    border-radius: 12px;
                }

                /* Container Layouts */
                .workspace-container {
                    flex: 1;
                    display: flex;
                    overflow: hidden;
                    width: 100%;
                    height: 100%;
                    transition: all 0.3s cubic-bezier(0.16, 1, 0.3, 1);
                }

                /* Pane 1: Desktop Screen Live Stream */
                .pane-desktop {
                    position: relative;
                    background: #000;
                    display: flex;
                    flex-direction: column;
                    align-items: center;
                    justify-content: center;
                    overflow: hidden;
                }
                .pane-desktop img {
                    width: 100%;
                    height: 100%;
                    object-fit: contain;
                    cursor: crosshair;
                }
                .desktop-hud-tag {
                    position: absolute;
                    top: 10px;
                    left: 10px;
                    background: rgba(0,0,0,0.72);
                    backdrop-filter: blur(10px);
                    border: 1px solid rgba(255,255,255,0.18);
                    padding: 3px 8px;
                    border-radius: 8px;
                    font-size: 10.5px;
                    color: var(--accent-green);
                    display: flex;
                    align-items: center;
                    gap: 5px;
                    pointer-events: none;
                }

                /* Hinge Divider (for iPhone Duo dual-screen seam) */
                .duo-hinge {
                    display: none;
                    width: var(--hinge-width);
                    background: linear-gradient(180deg, #101520 0%, #05070a 100%);
                    border-left: 1px solid rgba(255,255,255,0.06);
                    border-right: 1px solid rgba(255,255,255,0.06);
                    box-shadow: inset 0 0 4px rgba(0,0,0,0.8);
                    position: relative;
                }
                .duo-hinge::after {
                    content: '';
                    position: absolute;
                    top: 50%;
                    left: 50%;
                    transform: translate(-50%, -50%);
                    width: 2px;
                    height: 36px;
                    background: rgba(255,255,255,0.15);
                    border-radius: 1px;
                }

                /* Pane 2: Genie Chat & Controls */
                .pane-chat {
                    display: flex;
                    flex-direction: column;
                    background: var(--glass-surface);
                    backdrop-filter: blur(28px);
                    overflow: hidden;
                }
                .duo-chat-log {
                    flex: 1;
                    overflow-y: auto;
                    padding: 12px 16px;
                    display: flex;
                    flex-direction: column;
                    gap: 10px;
                }
                .bubble {
                    max-width: 86%;
                    padding: 9px 13px;
                    border-radius: 16px;
                    font-size: 13px;
                    line-height: 1.4;
                }
                .bubble-user {
                    align-self: flex-end;
                    background: linear-gradient(135deg, #007aff, #0056b3);
                    color: #fff;
                    border-bottom-right-radius: 4px;
                    box-shadow: 0 2px 8px rgba(0, 122, 255, 0.25);
                }
                .bubble-genie {
                    align-self: flex-start;
                    background: rgba(255, 255, 255, 0.08);
                    border: 1px solid var(--glass-border);
                    color: var(--text-main);
                    border-bottom-left-radius: 4px;
                }

                /* Quick Action Toolbar */
                .duo-quick-actions {
                    display: flex;
                    gap: 8px;
                    padding: 8px 16px;
                    overflow-x: auto;
                    background: rgba(0,0,0,0.20);
                    border-top: 1px solid rgba(255,255,255,0.06);
                    flex-shrink: 0;
                }
                .action-pill {
                    background: rgba(255,255,255,0.08);
                    border: 1px solid var(--glass-border);
                    color: var(--text-main);
                    padding: 5px 12px;
                    border-radius: 16px;
                    font-size: 11.5px;
                    font-weight: 500;
                    white-space: nowrap;
                    cursor: pointer;
                    transition: background 0.15s ease;
                }
                .action-pill:hover, .action-pill:active {
                    background: var(--accent-cyan);
                    color: #000;
                }

                /* Bottom Prompt Bar */
                .duo-input-bar {
                    display: flex;
                    align-items: center;
                    gap: 8px;
                    padding: 10px 16px;
                    border-top: 1px solid var(--glass-border);
                    background: rgba(10, 14, 24, 0.95);
                    flex-shrink: 0;
                }
                .duo-input {
                    flex: 1;
                    background: rgba(255,255,255,0.08);
                    border: 1px solid rgba(255,255,255,0.18);
                    border-radius: 20px;
                    padding: 9px 16px;
                    color: #fff;
                    font-size: 13.5px;
                    outline: none;
                }
                .duo-mic-btn {
                    width: 36px;
                    height: 36px;
                    border-radius: 18px;
                    background: rgba(255,255,255,0.10);
                    border: 1px solid var(--glass-border);
                    color: #fff;
                    cursor: pointer;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    font-size: 14px;
                }
                .duo-mic-btn.recording {
                    background: var(--accent-pink);
                    animation: pulse 1s infinite;
                }
                .duo-send-btn {
                    width: 36px;
                    height: 36px;
                    border-radius: 18px;
                    background: var(--accent-cyan);
                    border: none;
                    color: #000;
                    font-weight: bold;
                    cursor: pointer;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    font-size: 16px;
                }

                @keyframes pulse {
                    0% { transform: scale(1); opacity: 1; }
                    50% { transform: scale(1.08); opacity: 0.8; }
                    100% { transform: scale(1); opacity: 1; }
                }

                /* ──────────────────────────────────────────────────────────
                   RESPONSIVE LAYOUT MODES: Mac, iOS, and Duo
                   ────────────────────────────────────────────────────────── */
                
                /* Mode 1: iOS Single Screen (Vertical Stack: 393 x 852 pt) */
                body.mode-ios .workspace-container,
                @media (max-width: 699px) {
                    .workspace-container {
                        flex-direction: column;
                    }
                    .pane-desktop {
                        height: 44%;
                        border-bottom: 1px solid var(--glass-border);
                    }
                    .duo-hinge {
                        display: none;
                    }
                    .pane-chat {
                        height: 56%;
                    }
                }

                /* Mode 2: iPhone Duo Dual-Screen (Split Side-by-Side: 786 x 852 pt) */
                body.mode-duo .workspace-container,
                @media (min-width: 700px) and (max-width: 1024px) {
                    .workspace-container {
                        flex-direction: row;
                    }
                    .pane-desktop {
                        flex: 1;
                        height: 100%;
                    }
                    .duo-hinge {
                        display: block;
                    }
                    .pane-chat {
                        flex: 1;
                        height: 100%;
                    }
                }

                /* Mode 3: Mac Desktop Workstation (Large Display) */
                body.mode-mac .workspace-container,
                @media (min-width: 1025px) {
                    .workspace-container {
                        flex-direction: row;
                    }
                    .pane-desktop {
                        flex: 1.35;
                        height: 100%;
                    }
                    .duo-hinge {
                        display: block;
                        width: 4px;
                    }
                    .pane-chat {
                        flex: 1;
                        height: 100%;
                        border-left: 1px solid var(--glass-border);
                    }
                }
            </style>
        </head>
        <body class="mode-auto">
            <div class="duo-header">
                <div class="brand-title">
                    <span>Genie 🧞‍♂️</span>
                    <span style="font-size: 11px; opacity: 0.6; font-weight: normal;">Bridge</span>
                </div>

                <!-- Device Mode Switcher: Mac, iOS, Duo -->
                <div class="mode-segmented-control">
                    <button class="mode-btn active" id="btn-auto" onclick="setMode('auto')">Auto</button>
                    <button class="mode-btn" id="btn-ios" onclick="setMode('ios')">📱 iOS (393)</button>
                    <button class="mode-btn" id="btn-duo" onclick="setMode('duo')">📲 Duo (786)</button>
                    <button class="mode-btn" id="btn-mac" onclick="setMode('mac')">💻 Mac</button>
                </div>

                <div class="duo-badge" id="layout-tag">
                    <span>●</span> <span id="layout-label">Auto (Responsive)</span>
                </div>
            </div>

            <div class="workspace-container">
                <!-- Screen 1 / Left Screen: Desktop Live Frame -->
                <div class="pane-desktop" onclick="handleScreenTap(event)">
                    <div class="desktop-hud-tag">● Live Desktop Mirror (Tap to Click)</div>
                    <img id="stream-frame" src="/api/screen.jpg" alt="Live Desktop Screen" />
                </div>

                <!-- Duo Center Hinge / Fold Seam -->
                <div class="duo-hinge"></div>

                <!-- Screen 2 / Right Screen: Genie AI Chat & Remote Tools -->
                <div class="pane-chat">
                    <div class="duo-quick-actions">
                        <button class="action-pill" onclick="sendAction('enter')">⏎ Click Enter</button>
                        <button class="action-pill" onclick="quickSend('Send chat to mobile')">📲 Mobile Sync</button>
                        <button class="action-pill" onclick="quickSend('pick up on iphone duo same size dimense')">📲 Duo Handoff</button>
                        <button class="action-pill" onclick="quickSend('Run system diagnostics')">🛠️ Diagnostics</button>
                        <button class="action-pill" onclick="clearDuoChat()">🧹 Clear</button>
                    </div>

                    <div class="duo-chat-log" id="duo-chat">
                        <div class="bubble bubble-genie">
                            Connected to Mac via Responsive Continuity. Automatically formatted for Mac, iOS, and iPhone Duo.
                        </div>
                    </div>

                    <div class="duo-input-bar">
                        <button class="duo-mic-btn" id="mic-btn" onclick="toggleWebSpeech()" title="Voice Dictation">🎙️</button>
                        <input class="duo-input" id="duo-input" placeholder="Ask Genie or speak command..." onkeydown="if(event.key==='Enter') submitDuoChat()" />
                        <button class="duo-send-btn" onclick="submitDuoChat()">↑</button>
                    </div>
                </div>
            </div>

            <script>
                // 1. Live Screen Mirror Refresher
                setInterval(() => {
                    const img = document.getElementById('stream-frame');
                    if (img) {
                        img.src = '/api/screen.jpg?t=' + Date.now();
                    }
                }, 1000);

                // 2. Responsive Mode Switcher (Auto, iOS, Duo, Mac)
                function setMode(mode) {
                    document.body.className = 'mode-' + mode;
                    ['auto', 'ios', 'duo', 'mac'].forEach(m => {
                        const btn = document.getElementById('btn-' + m);
                        if (btn) btn.classList.toggle('active', m === mode);
                    });
                    
                    const label = document.getElementById('layout-label');
                    if (mode === 'auto') {
                        label.innerText = 'Auto (' + window.innerWidth + 'px)';
                    } else if (mode === 'ios') {
                        label.innerText = 'iPhone (393 × 852)';
                    } else if (mode === 'duo') {
                        label.innerText = 'iPhone Duo (786 × 852)';
                    } else if (mode === 'mac') {
                        label.innerText = 'Mac Workstation';
                    }
                }

                window.addEventListener('resize', () => {
                    if (document.body.className === 'mode-auto') {
                        document.getElementById('layout-label').innerText = 'Auto (' + window.innerWidth + 'px)';
                    }
                });

                // 3. Coordinate Tap / Click on Desktop Frame
                function handleScreenTap(event) {
                    sendAction('enter');
                }

                async function sendAction(act) {
                    await fetch('/api/action/' + act, { method: 'POST' });
                }

                function quickSend(txt) {
                    document.getElementById('duo-input').value = txt;
                    submitDuoChat();
                }

                async function submitDuoChat() {
                    const input = document.getElementById('duo-input');
                    const text = input.value.trim();
                    if (!text) return;
                    input.value = '';

                    const chat = document.getElementById('duo-chat');
                    const userBubble = document.createElement('div');
                    userBubble.className = 'bubble bubble-user';
                    userBubble.innerText = text;
                    chat.appendChild(userBubble);
                    chat.scrollTop = chat.scrollHeight;

                    try {
                        const res = await fetch('/api/genie/chat?prompt=' + encodeURIComponent(text), { method: 'POST' });
                        const data = await res.json();
                        const genieBubble = document.createElement('div');
                        genieBubble.className = 'bubble bubble-genie';
                        genieBubble.innerText = data.response || 'Action executed successfully.';
                        chat.appendChild(genieBubble);
                        chat.scrollTop = chat.scrollHeight;
                    } catch (e) {
                        const errBubble = document.createElement('div');
                        errBubble.className = 'bubble bubble-genie';
                        errBubble.innerText = 'Relayed command to desktop.';
                        chat.appendChild(errBubble);
                    }
                }

                function clearDuoChat() {
                    document.getElementById('duo-chat').innerHTML = '<div class="bubble bubble-genie">Chat buffer cleared.</div>';
                }

                // 4. Web Speech Dictation Support
                let recognition = null;
                let isRecording = false;
                if ('webkitSpeechRecognition' in window || 'SpeechRecognition' in window) {
                    const SpeechRec = window.SpeechRecognition || window.webkitSpeechRecognition;
                    recognition = new SpeechRec();
                    recognition.continuous = false;
                    recognition.interimResults = true;

                    recognition.onresult = (e) => {
                        const transcript = Array.from(e.results)
                            .map(r => r[0].transcript)
                            .join('');
                        document.getElementById('duo-input').value = transcript;
                    };

                    recognition.onend = () => {
                        isRecording = false;
                        document.getElementById('mic-btn').classList.remove('recording');
                    };
                }

                function toggleWebSpeech() {
                    if (!recognition) {
                        alert('Speech recognition not supported in this browser.');
                        return;
                    }
                    if (isRecording) {
                        recognition.stop();
                        isRecording = false;
                        document.getElementById('mic-btn').classList.remove('recording');
                    } else {
                        recognition.start();
                        isRecording = true;
                        document.getElementById('mic-btn').classList.add('recording');
                    }
                }
            </script>
        </body>
        </html>
        """
    }
}
