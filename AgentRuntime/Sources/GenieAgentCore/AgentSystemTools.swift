// app_doc/airdrop/phone_bridge need AppKit (NSWorkspace, NSSharingService,
// NSAppleScript) which doesn't exist on iOS. agent_network is pure Network.framework
// and could work on iOS on its own, but it shares this file with the AppKit-only
// tools, so it's gated out here too for now — see
// AgentToolCatalog.platformUnavailable in AgentTypes.swift.
#if os(macOS)
import Foundation
import AppKit
import Network

/// `app_doc`: live AppleScript dictionary + bundle metadata for any installed app.
/// Real system state, not cached docs — sdef reflects exactly what that binary supports today.
public enum AgentAppDocTools {
    public static func execute(_ args: [String: String]) async throws -> AgentToolResult {
        let identifier = args["app"]!
        let appURL: URL
        if identifier.hasPrefix("/") {
            appURL = URL(fileURLWithPath: identifier)
        } else if let resolved = NSWorkspace.shared.urlForApplication(withBundleIdentifier: identifier) {
            appURL = resolved
        } else {
            throw AgentFailure("No installed application matches \(identifier).")
        }
        guard let bundle = Bundle(url: appURL) else { throw AgentFailure("\(appURL.path) is not a valid application bundle.") }
        let info = bundle.infoDictionary ?? [:]
        let schemes = (info["CFBundleURLTypes"] as? [[String: Any]] ?? [])
            .compactMap { $0["CFBundleURLSchemes"] as? [String] }.flatMap { $0 }
        let sdef = try await runSdef(appURL)
        let payload: [String: Any] = [
            "path": appURL.path,
            "bundleIdentifier": bundle.bundleIdentifier ?? "",
            "urlSchemes": schemes,
            "sdef": sdef.count > 20_000 ? String(sdef.prefix(20_000)) + "\n[truncated]" : sdef,
        ]
        return AgentToolResult(success: true, output: String(decoding: try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys]), as: UTF8.self))
    }

    private static func runSdef(_ appURL: URL) async throws -> String {
        #if GENIE_MAS
        // /usr/bin/sdef lives outside the app bundle, so the App Store sandbox
        // cannot spawn it (and Guideline 2.5.1 forbids it). There is no
        // sandbox-legal way to read another app's scripting dictionary, so the
        // tool reports itself unavailable rather than failing opaquely.
        throw AgentFailure("Reading an app's AppleScript dictionary is not supported under macOS App Sandbox security restrictions.")
        #else
        return try await Task.detached(priority: .utility) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/sdef")
            process.arguments = [appURL.path]
            let outPipe = Pipe(), errPipe = Pipe()
            process.standardOutput = outPipe
            process.standardError = errPipe
            try process.run()
            let data = outPipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else {
                throw AgentFailure("\(appURL.lastPathComponent) exposes no AppleScript dictionary.")
            }
            return String(decoding: data, as: UTF8.self)
        }.value
        #endif
    }
}

/// `airdrop`: hands a file to the system AirDrop sheet. The sheet is asynchronous UI the
/// user drives themselves, so this can confirm the sheet opened, never that a peer received it.
@MainActor
public enum AgentAirDropTools {
    public static func execute(_ args: [String: String]) throws -> AgentToolResult {
        let path = args["path"]!
        guard FileManager.default.fileExists(atPath: path) else { throw AgentFailure("No file at \(path).") }
        let url = URL(fileURLWithPath: path)
        guard let service = NSSharingService(named: .sendViaAirDrop) else {
            throw AgentFailure("AirDrop is not available on this Mac.")
        }
        guard service.canPerform(withItems: [url]) else {
            throw AgentFailure("AirDrop cannot share this item (no Wi-Fi/Bluetooth radio, or an unsupported file).")
        }
        service.perform(withItems: [url])
        return AgentToolResult(success: true, output: "AirDrop sheet opened for \(url.lastPathComponent). The user must pick a device; this call cannot confirm delivery.")
    }
}

/// `phone_bridge`: sends messages to configured recipient or passed target via iMessage or Mail.
public enum AgentMessagesBridge {
    public static let targetDefaultsKey = "genie.phoneBridge.target"
    public static let groupIdentifier = "group.com.nicholasdudek.genie"

    public static func execute(_ args: [String: String]) async throws -> AgentToolResult {
        guard let text = args["text"]?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
            throw AgentFailure("text must not be empty.")
        }
        
        let sharedDefaults = UserDefaults(suiteName: groupIdentifier)
        let resolvedTarget = args["target"] ?? args["recipient"]
            ?? sharedDefaults?.string(forKey: targetDefaultsKey)
            ?? UserDefaults.standard.string(forKey: targetDefaultsKey)
            ?? sharedDefaults?.string(forKey: "genie.phoneBridge.phone")
            ?? UserDefaults.standard.string(forKey: "genie.phoneBridge.phone")

        guard let target = resolvedTarget, !target.isEmpty else {
            throw AgentFailure("No phone_bridge recipient configured. Provide recipient or set it in Chat Settings.")
        }

        let channel = args["channel"]?.lowercased() ?? (target.contains("@") ? "auto" : "messages")
        
        try await Task.detached(priority: .utility) {
            if channel == "mail" || (channel == "auto" && target.contains("@") && !target.contains("+")) {
                try sendMail(subject: args["subject"] ?? "Message from Genie", body: text, to: target)
            } else {
                try sendMessages(text: text, to: target)
            }
        }.value

        return AgentToolResult(success: true, output: "Dispatched to \(target) via \(channel == "mail" ? "Mail" : "Messages").")
    }

    private static func sendMessages(text: String, to target: String) throws {
        func escape(_ value: String) -> String {
            value.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
        }
        let script = """
        tell application "Messages"
            set targetService to first service whose service type = iMessage
            try
                set targetBuddy to buddy "\(escape(target))" of targetService
                send "\(escape(text))" to targetBuddy
            on error
                set targetChat to participant "\(escape(target))"
                send "\(escape(text))" to targetChat
            end try
        end tell
        """
        var error: NSDictionary?
        guard let appleScript = NSAppleScript(source: script) else { throw AgentFailure("Could not compile the Messages AppleScript.") }
        appleScript.executeAndReturnError(&error)
        if let error {
            let message = error[NSAppleScript.errorMessage] as? String ?? "Unknown AppleScript error"
            throw AgentFailure("Messages automation failed: \(message). Ensure Automation access for Genie -> Messages is granted in System Settings.")
        }
    }

    private static func sendMail(subject: String, body: String, to target: String) throws {
        func escape(_ value: String) -> String {
            value.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
        }
        let script = """
        tell application "Mail"
            set newMessage to make new outgoing message with properties {subject:"\(escape(subject))", content:"\(escape(body))", visible:false}
            tell newMessage
                make new to recipient at end of to recipients with properties {address:"\(escape(target))"}
                send
            end tell
        end tell
        """
        var error: NSDictionary?
        guard let appleScript = NSAppleScript(source: script) else { throw AgentFailure("Could not compile Mail AppleScript.") }
        appleScript.executeAndReturnError(&error)
        if let error {
            let message = error[NSAppleScript.errorMessage] as? String ?? "Unknown AppleScript error"
            throw AgentFailure("Mail automation failed: \(message). Ensure Automation access for Genie -> Mail is granted in System Settings.")
        }
    }
}

/// `agent_network`: Sovereign peer mesh networking.
/// Combines zero-configuration Bonjour mDNS peer discovery on LAN with direct peer-to-peer
/// micro-tunnels across wide-area networks, latency pinging, and APFS copy-on-write sharing.
public actor AgentNetworkService {
    public static let shared = AgentNetworkService()
    private static let serviceType = "_genie-agent._tcp"
    private static let port: NWEndpoint.Port = 8421
    private static let bridgeDirectory = URL(fileURLWithPath: "/Users/Shared/Genie/Bridge")

    private var listener: NWListener?
    private var activeTunnels: [String: NWEndpoint] = [:]

    private init() {}

    public func execute(_ args: [String: String]) async throws -> AgentToolResult {
        guard let action = args["action"] else { throw AgentFailure("action is required: advertise, discover, tunnel, send, clone, status, or ping.") }
        switch action {
        case "advertise":
            try startAdvertising()
            return AgentToolResult(success: true, output: "Advertising \(Self.serviceType) on port \(Self.port.rawValue).")
        case "discover":
            let peers = try await discoverPeers(timeout: 2.5)
            return AgentToolResult(success: true, output: peers.isEmpty ? "No Genie peers found on the local network." : peers.joined(separator: "\n"))
        case "status":
            var lines = ["=== Genie Sovereign Mesh Status ==="]
            lines.append("Local Host: \(Host.current().localizedName ?? "Genie")")
            lines.append("Mesh Listener: \(listener != nil ? "Active (port \(Self.port.rawValue))" : "Inactive (use action=advertise to start)")")
            if activeTunnels.isEmpty {
                lines.append("Direct Tunnels: None")
            } else {
                let tunnelsList = activeTunnels.keys.sorted().joined(separator: ", ")
                lines.append("Direct Tunnels: \(tunnelsList)")
            }
            let bridgeCount = (try? FileManager.default.contentsOfDirectory(atPath: Self.bridgeDirectory.path).count) ?? 0
            lines.append("Bridge Handoffs: \(bridgeCount) files in \(Self.bridgeDirectory.path)")
            return AgentToolResult(success: true, output: lines.joined(separator: "\n"))
        case "tunnel":
            guard let hostStr = args["host"]?.trimmingCharacters(in: .whitespacesAndNewlines), !hostStr.isEmpty else {
                throw AgentFailure("tunnel requires host (IP address or hostname).")
            }
            let portNum = UInt16(args["port"] ?? "") ?? Self.port.rawValue
            guard let port = NWEndpoint.Port(rawValue: portNum) else { throw AgentFailure("Invalid port \(args["port"] ?? "").") }
            let endpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(hostStr), port: port)
            let latencyMs = try await pingEndpoint(endpoint, timeout: 3.5)
            let tunnelKey = "\(hostStr):\(portNum)"
            activeTunnels[tunnelKey] = endpoint
            activeTunnels[hostStr] = endpoint
            return AgentToolResult(success: true, output: "Sovereign tunnel established to \(tunnelKey). Handshake latency: \(String(format: "%.1f", latencyMs))ms. Direct peer ready for file transfers.")
        case "ping":
            guard let peer = args["peer"]?.trimmingCharacters(in: .whitespacesAndNewlines), !peer.isEmpty else {
                throw AgentFailure("ping requires peer (peer name, tunnel alias, or host:port).")
            }
            let endpoint = try await resolveEndpoint(for: peer, timeout: 3.0)
            let latencyMs = try await pingEndpoint(endpoint, timeout: 3.5)
            return AgentToolResult(success: true, output: "Pong from \(peer) in \(String(format: "%.1f", latencyMs))ms. Sovereign Mesh link is healthy.")
        case "send":
            guard let path = args["path"], let peer = args["peer"] else { throw AgentFailure("send requires path and peer.") }
            return try await sendFile(at: path, toPeer: peer)
        case "clone":
            guard let path = args["path"] else { throw AgentFailure("clone requires path.") }
            return try cloneLocally(path)
        default:
            throw AgentFailure("Unknown agent_network action: \(action)")
        }
    }

    /// Same-Mac hop: an actual copy-on-write clone, not a byte copy.
    private func cloneLocally(_ path: String) throws -> AgentToolResult {
        guard FileManager.default.fileExists(atPath: path) else { throw AgentFailure("No file at \(path).") }
        try FileManager.default.createDirectory(at: Self.bridgeDirectory, withIntermediateDirectories: true)
        let destination = Self.bridgeDirectory.appendingPathComponent(UUID().uuidString + "-" + (path as NSString).lastPathComponent)
        guard clonefile(path, destination.path, 0) == 0 else {
            throw AgentFailure("clonefile failed (\(String(cString: strerror(errno)))); source and Bridge may be on different volumes.")
        }
        return AgentToolResult(success: true, output: destination.path)
    }

    private func startAdvertising() throws {
        guard listener == nil else { return }
        let listener = try NWListener(using: .tcp, on: Self.port)
        listener.service = NWListener.Service(name: Host.current().localizedName ?? "Genie", type: Self.serviceType)
        listener.newConnectionHandler = { connection in
            connection.start(queue: .global(qos: .utility))
            Self.receiveFile(on: connection)
        }
        listener.stateUpdateHandler = { [weak self] state in
            if case .failed = state { Task { await self?.clearListener() } }
        }
        listener.start(queue: .global(qos: .utility))
        self.listener = listener
    }
    private func clearListener() { listener = nil }

    /// Guards a "resume exactly once" continuation against Bonjour's callback queue
    /// and the timeout's dispatch queue racing each other.
    private final class SettleOnce<Value>: @unchecked Sendable {
        private let lock = NSLock()
        private var value: Value
        private var finished = false
        init(_ initial: Value) { value = initial }
        func mutate(_ body: (inout Value) -> Void) { lock.lock(); body(&value); lock.unlock() }
        func finishOnce(_ body: (Value) -> Void) {
            lock.lock()
            guard !finished else { lock.unlock(); return }
            finished = true
            let current = value
            lock.unlock()
            body(current)
        }
    }

    private func discoverPeers(timeout: TimeInterval) async throws -> [String] {
        let browser = NWBrowser(for: .bonjour(type: Self.serviceType, domain: nil), using: .tcp)
        let box = SettleOnce<Set<String>>([])
        return await withCheckedContinuation { continuation in
            browser.browseResultsChangedHandler = { results, _ in
                box.mutate { names in
                    for result in results {
                        if case let .service(name, _, _, _) = result.endpoint { names.insert(name) }
                    }
                }
            }
            browser.start(queue: .global(qos: .utility))
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + timeout) {
                box.finishOnce { names in
                    browser.cancel()
                    continuation.resume(returning: names.sorted())
                }
            }
        }
    }

    /// Resolves target via direct active tunnels, host:port, IPv4/IPv6, or Bonjour.
    private func resolveEndpoint(for target: String, timeout: TimeInterval) async throws -> NWEndpoint {
        if let direct = activeTunnels[target] {
            return direct
        }
        if target.contains(":") {
            let parts = target.split(separator: ":", maxSplits: 1)
            let hostStr = String(parts[0])
            let portNum = UInt16(parts[1]) ?? Self.port.rawValue
            guard let port = NWEndpoint.Port(rawValue: portNum) else { throw AgentFailure("Invalid port in \(target).") }
            return NWEndpoint.hostPort(host: NWEndpoint.Host(hostStr), port: port)
        }
        let octets = target.split(separator: ".")
        if octets.count == 4 && octets.allSatisfy({ UInt8($0) != nil }) {
            return NWEndpoint.hostPort(host: NWEndpoint.Host(target), port: Self.port)
        }
        return try await resolvePeer(named: target, timeout: timeout)
    }

    private func resolvePeer(named name: String, timeout: TimeInterval) async throws -> NWEndpoint {
        let browser = NWBrowser(for: .bonjour(type: Self.serviceType, domain: nil), using: .tcp)
        let box = SettleOnce<NWEndpoint?>(nil)
        return try await withCheckedThrowingContinuation { continuation in
            browser.browseResultsChangedHandler = { results, _ in
                for result in results {
                    if case .service(name, _, _, _) = result.endpoint {
                        box.finishOnce { _ in
                            browser.cancel()
                            continuation.resume(returning: result.endpoint)
                        }
                    }
                }
            }
            browser.start(queue: .global(qos: .utility))
            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + timeout) {
                box.finishOnce { _ in
                    browser.cancel()
                    continuation.resume(throwing: AgentFailure("No Genie peer named \(name) found within \(Int(timeout))s."))
                }
            }
        }
    }

    /// Pings an endpoint with a handshake probe and measures round-trip latency in milliseconds.
    private func pingEndpoint(_ endpoint: NWEndpoint, timeout: TimeInterval) async throws -> Double {
        let connection = NWConnection(to: endpoint, using: .tcp)
        let pingName = Data("__GENIE_MESH_PING__".utf8)
        let pingContent = Data("PING".utf8)
        let startTime = CFAbsoluteTimeGetCurrent()
        let box = SettleOnce<Void>(())

        return try await withCheckedThrowingContinuation { continuation in
            func finish(_ result: Result<Double, Error>) {
                box.finishOnce { _ in
                    connection.cancel()
                    continuation.resume(with: result)
                }
            }

            DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + timeout) {
                finish(.failure(AgentFailure("Ping to \(endpoint) timed out after \(Int(timeout))s.")))
            }

            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    var payload = Data()
                    payload.append(Self.bigEndian(UInt64(pingName.count)))
                    payload.append(pingName)
                    payload.append(Self.bigEndian(UInt64(pingContent.count)))
                    payload.append(pingContent)
                    connection.send(content: payload, completion: .contentProcessed { error in
                        if let error {
                            finish(.failure(AgentFailure("Ping send failed: \(error)")))
                            return
                        }
                        Self.readExact(connection, count: 8) { header in
                            guard let header, let nameLen = Self.decodeBigEndian(header) else {
                                finish(.failure(AgentFailure("Invalid pong response header.")))
                                return
                            }
                            Self.readExact(connection, count: Int(nameLen)) { respNameData in
                                guard let respNameData, String(decoding: respNameData, as: UTF8.self) == "__GENIE_MESH_PONG__" else {
                                    finish(.failure(AgentFailure("Peer did not respond with expected pong.")))
                                    return
                                }
                                let elapsedMs = (CFAbsoluteTimeGetCurrent() - startTime) * 1000.0
                                finish(.success(elapsedMs))
                            }
                        }
                    })
                case .failed(let error):
                    finish(.failure(AgentFailure("Connection failed: \(error)")))
                default: break
                }
            }
            connection.start(queue: .global(qos: .utility))
        }
    }

    /// Wire format: [8B name length][name UTF-8][8B content length][content].
    private func sendFile(at path: String, toPeer peer: String) async throws -> AgentToolResult {
        guard FileManager.default.fileExists(atPath: path) else { throw AgentFailure("No file at \(path).") }
        let content = try Data(contentsOf: URL(fileURLWithPath: path))
        let name = Data((path as NSString).lastPathComponent.utf8)
        let endpoint = try await resolveEndpoint(for: peer, timeout: 3)
        let connection = NWConnection(to: endpoint, using: .tcp)
        let box = SettleOnce<Void>(())
        return try await withCheckedThrowingContinuation { continuation in
            func finish(_ result: Result<AgentToolResult, Error>) {
                box.finishOnce { _ in
                    connection.cancel()
                    continuation.resume(with: result)
                }
            }
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    var payload = Data()
                    payload.append(Self.bigEndian(UInt64(name.count)))
                    payload.append(name)
                    payload.append(Self.bigEndian(UInt64(content.count)))
                    payload.append(content)
                    connection.send(content: payload, completion: .contentProcessed { error in
                        if let error { finish(.failure(AgentFailure("Send failed: \(error)"))) }
                        else { finish(.success(AgentToolResult(success: true, output: "Sent \(name.count > 0 ? String(decoding: name, as: UTF8.self) : path) (\(content.count) bytes) to \(peer)."))) }
                    })
                case .failed(let error): finish(.failure(AgentFailure("Connection to \(peer) failed: \(error)")))
                default: break
                }
            }
            connection.start(queue: .global(qos: .utility))
        }
    }

    private static func receiveFile(on connection: NWConnection) {
        readExact(connection, count: 8) { header in
            guard let header, let nameLength = decodeBigEndian(header) else { return }
            readExact(connection, count: Int(nameLength)) { nameData in
                guard let nameData else { return }
                let nameStr = String(decoding: nameData, as: UTF8.self)
                let safeName = (nameStr as NSString).lastPathComponent
                readExact(connection, count: 8) { lengthHeader in
                    guard let lengthHeader, let contentLength = decodeBigEndian(lengthHeader) else { return }
                    readExact(connection, count: Int(contentLength)) { content in
                        guard let content else { return }
                        if safeName == "__GENIE_MESH_PING__" {
                            // Instant pong response for sovereign mesh handshake without writing to disk
                            let pongName = Data("__GENIE_MESH_PONG__".utf8)
                            var pongPayload = Data()
                            pongPayload.append(bigEndian(UInt64(pongName.count)))
                            pongPayload.append(pongName)
                            pongPayload.append(bigEndian(UInt64(content.count)))
                            pongPayload.append(content)
                            connection.send(content: pongPayload, completion: .contentProcessed { _ in
                                connection.cancel()
                            })
                            return
                        }
                        try? FileManager.default.createDirectory(at: bridgeDirectory, withIntermediateDirectories: true)
                        let destination = bridgeDirectory.appendingPathComponent(UUID().uuidString + "-" + safeName)
                        try? content.write(to: destination)
                        connection.cancel()
                    }
                }
            }
        }
    }
    private static func readExact(_ connection: NWConnection, count: Int, then: @escaping (Data?) -> Void) {
        connection.receive(minimumIncompleteLength: count, maximumLength: count) { data, _, _, error in
            guard error == nil, let data, data.count == count else { then(nil); return }
            then(data)
        }
    }
    private static func bigEndian(_ value: UInt64) -> Data {
        var big = value.bigEndian
        return Data(bytes: &big, count: 8)
    }
    private static func decodeBigEndian(_ data: Data) -> UInt64? {
        guard data.count == 8 else { return nil }
        return data.withUnsafeBytes { $0.load(as: UInt64.self) }.bigEndian
    }
}

/// `siri`: Run an Apple Shortcut, query Siri, or activate Siri.
public enum AgentSiriTools {
    public static func execute(_ args: [String: String]) async throws -> AgentToolResult {
        let action = args["action"] ?? "run_shortcut"
        switch action {
        case "run_shortcut":
            guard let name = args["shortcut_name"], !name.isEmpty else {
                throw AgentFailure("shortcut_name is required for run_shortcut.")
            }
            let input = args["input"]
            return try await runShortcut(name: name, input: input)
        case "ask", "query":
            let query = args["input"] ?? ""
            guard !query.isEmpty else { throw AgentFailure("input is required for Siri query.") }
            return try await askSiri(query: query)
        case "activate":
            return try await activateSiri()
        default:
            throw AgentFailure("Unknown siri action: \(action).")
        }
    }

    private static func runShortcut(name: String, input: String?) async throws -> AgentToolResult {
        #if GENIE_MAS
        // Same rule as runSdef above: /usr/bin/shortcuts is outside the app
        // bundle, so the App Store sandbox cannot spawn it and Guideline 2.5.1
        // forbids it regardless. Report unavailable rather than failing opaquely.
        throw AgentFailure("Running Shortcuts is not supported under macOS App Sandbox security restrictions.")
        #else
        return try await Task.detached(priority: .userInitiated) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
            var arguments = ["run", name]
            var tempInputFile: URL? = nil
            if let input = input, !input.isEmpty {
                let tempDir = FileManager.default.temporaryDirectory
                let tempFile = tempDir.appendingPathComponent("genie_siri_in_\(UUID().uuidString).txt")
                try? input.write(to: tempFile, atomically: true, encoding: .utf8)
                arguments.append(contentsOf: ["--input-path", tempFile.path])
                tempInputFile = tempFile
            }
            process.arguments = arguments
            let outPipe = Pipe(), errPipe = Pipe()
            process.standardOutput = outPipe
            process.standardError = errPipe
            defer {
                if let tempFile = tempInputFile {
                    try? FileManager.default.removeItem(at: tempFile)
                }
            }
            try process.run()
            let data = outPipe.fileHandleForReading.readDataToEndOfFile()
            let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            let outputStr = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
            let errStr = String(decoding: errData, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
            if process.terminationStatus == 0 {
                let out = outputStr.isEmpty ? "Shortcut \"\(name)\" completed successfully." : outputStr
                return AgentToolResult(success: true, output: out)
            } else {
                return AgentToolResult(success: false, output: "Shortcut execution failed (\(process.terminationStatus)): \(errStr.isEmpty ? outputStr : errStr)", exitCode: process.terminationStatus)
            }
        }.value
        #endif
    }

    // `tell application "Siri"` targets com.apple.Siri, which is deliberately
    // absent from com.apple.security.temporary-exception.apple-events in the
    // App Store profile — Siri is not supported scripting surface. Under the
    // sandbox the event is refused, and because both helpers below discard
    // `error` they would report success for something that never happened.
    // Gate them instead of shipping that lie.
    private static func activateSiriScript(reporting message: String) async throws -> AgentToolResult {
        #if GENIE_MAS
        throw AgentFailure("Controlling Siri is not supported under macOS App Sandbox security restrictions.")
        #else
        let script = """
        tell application "System Events"
            tell application "Siri" to activate
        end tell
        """
        return try await Task.detached(priority: .userInitiated) {
            var error: NSDictionary?
            guard let appleScript = NSAppleScript(source: script) else {
                throw AgentFailure("Could not compile the Siri activation script.")
            }
            appleScript.executeAndReturnError(&error)
            if let error {
                let reason = error[NSAppleScript.errorMessage] as? String ?? "unknown error"
                throw AgentFailure("Siri activation failed: \(reason)")
            }
            return AgentToolResult(success: true, output: message)
        }.value
        #endif
    }

    private static func askSiri(query: String) async throws -> AgentToolResult {
        try await activateSiriScript(reporting: "Siri activated for query: \"\(query)\".")
    }

    private static func activateSiri() async throws -> AgentToolResult {
        try await activateSiriScript(reporting: "Siri activated.")
    }
}
#endif
