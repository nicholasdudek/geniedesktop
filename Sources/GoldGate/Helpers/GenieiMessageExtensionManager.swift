import AppKit
import CoreGraphics
import Foundation

// MARK: - 💬 Genie Dedicated Apple Messages Extension & Bridge Manager
/// Manages Genie's dedicated Apple Messages extension, contact identity, two-way conversational bridge,
/// and smart action dispatcher between Nicholas's iPhone and macOS desktop.
@MainActor
public final class GenieiMessageExtensionManager: ObservableObject {
    public static let shared = GenieiMessageExtensionManager()

    // ── Extension Status & Configuration ─────────────────────────────────────
    @Published public private(set) var isWatcherActive: Bool = false
    @Published public private(set) var isExtensionInstalled: Bool = false
    @Published public private(set) var totalMessagesRelayed: Int = 0
    @Published public private(set) var lastMessageReceived: String = "None"
    @Published public private(set) var lastReplySent: String = "None"
    @Published public private(set) var lastActiveDate: Date? = nil

    // Nicholas's Verified Identities
    @Published public var nicholasAppleID: String = "nicholas.dudek@icloud.com"
    @Published public var nicholasPhone: String = "+821020520225"

    // Known Contact Shortcuts
    public var knownContacts: [String: String] = [
        "markie": "+821075252038",
        "💜markie💜": "+821075252038",
        "me": "nicholas.dudek@icloud.com",
        "self": "nicholas.dudek@icloud.com"
    ]

    private var watcherTimer: Timer?
    private var lastObservedRowID: Int64 = 0
    private var sentRepliesCache: Set<String> = []
    private var processedRowIDs: Set<Int64> = []
    private let backgroundQueue = DispatchQueue(label: "com.genie.messages.extension", qos: .userInitiated)

    // Debounce & interaction buffering: wait for multiple rapid texts before generating a reply
    private var pendingPromptsBySender: [String: [String]] = [:]
    private var debounceTimersBySender: [String: DispatchWorkItem] = [:]
    private let interactionDebounceSeconds: TimeInterval = 3.5

    private init() {
        self.lastObservedRowID = Self.queryMaxChatDBRowID()
        installExtensionFiles()
        startWatcher()
    }

    // MARK: - Dedicated Extension Files Installation
    /// Installs Genie's Apple Messages extension script, desktop contact card (vCard), and shortcuts
    public func installExtensionFiles() {
        installAppleMessagesScript()
        exportGenieContactCard()
        self.isExtensionInstalled = true
    }

    /// Creates the AppleScript handler in ~/Library/Application Scripts/com.apple.iChat
    private func installAppleMessagesScript() {
        let scriptContent = """
        -- 🧞 Genie Dedicated Apple Messages Extension Handler
        -- Automatically triggers when messages arrive in Apple Messages
        using terms from application "Messages"
            on message received theMessage from theBuddy for theChat
                set senderID to id of theBuddy
                set msgContent to theMessage
                
                -- Skip messages originating from Genie itself
                if msgContent starts with "🧞" or msgContent starts with "✨ [Genie]" then
                    return
                end if
                
                -- Dispatch to Genie Phone Bridge HTTP daemon
                try
                    set encodedMsg to do shell script "python3 -c 'import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1]))' " & quoted form of msgContent
                    set encodedSender to do shell script "python3 -c 'import urllib.parse, sys; print(urllib.parse.quote(sys.argv[1]))' " & quoted form of senderID
                    do shell script "curl -s -m 2 'http://127.0.0.1:8765/api/imessage/received?sender=' & encodedSender & '&message=' & encodedMsg > /dev/null 2>&1 &"
                end try
            end message received
        end using terms from
        """

        let homeDir = NSHomeDirectory()
        let destinations = [
            "\(homeDir)/Library/Application Scripts/com.apple.iChat",
            "\(homeDir)/Library/Scripts/Messages",
            "\(homeDir)/Library/Application Support/Genie/Extensions"
        ]

        for dir in destinations {
            try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
            let path = "\(dir)/GenieiMessageExtension.applescript"
            try? scriptContent.write(toFile: path, atomically: true, encoding: .utf8)
        }
    }

    /// Generates a dedicated vCard (Genie AI.vcf) so Nicholas can add Genie as a standalone contact
    @discardableResult
    public func exportGenieContactCard(toDesktop: Bool = true) -> URL? {
        let vcard = """
        BEGIN:VCARD
        VERSION:3.0
        PRODID:-//Nicholas Dudek//Genie macOS Extension//EN
        N:AI;Genie;;;
        FN:Genie AI
        ORG:Genie Desktop Intelligence;
        EMAIL;type=INTERNET;type=WORK;type=pref:nicholas.dudek@icloud.com
        EMAIL;type=INTERNET;type=HOME:nicholas.m.dudek+genie@icloud.com
        TEL;type=CELL;type=VOICE;type=pref:\(nicholasPhone)
        NOTE:Genie macOS Desktop Assistant & iMessage Extension. Text anytime to check Mac status, control anti-sleep, capture screenshots, or run tasks.
        CATEGORIES:AI,Assistant,Genie
        END:VCARD
        """

        let appSupportDir = "\(NSHomeDirectory())/Library/Application Support/Genie"
        try? FileManager.default.createDirectory(atPath: appSupportDir, withIntermediateDirectories: true)
        let appSupportURL = URL(fileURLWithPath: "\(appSupportDir)/Genie AI.vcf")
        try? vcard.write(to: appSupportURL, atomically: true, encoding: .utf8)

        if toDesktop {
            let desktopURL = URL(fileURLWithPath: "\(NSHomeDirectory())/Desktop/Genie AI.vcf")
            try? vcard.write(to: desktopURL, atomically: true, encoding: .utf8)
            return desktopURL
        }
        return appSupportURL
    }

    // MARK: - Native Watcher & Poller Lifecycle
    public func startWatcher() {
        guard !isWatcherActive else { return }
        self.isWatcherActive = true

        backgroundQueue.async { [weak self] in
            let maxID = Self.queryMaxChatDBRowID()
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.lastObservedRowID = maxID
                self.watcherTimer?.invalidate()
                self.watcherTimer = Timer.scheduledTimer(withTimeInterval: 1.8, repeats: true) { [weak self] _ in
                    Task { @MainActor [weak self] in
                        self?.pollChatDB()
                    }
                }
                print("📱 [Genie iMessage Extension]: Poller active (Anchor row ID: \(maxID))")
            }
        }
    }

    public func stopWatcher() {
        watcherTimer?.invalidate()
        watcherTimer = nil
        isWatcherActive = false
    }

    // MARK: - Database Poller
    private func pollChatDB() {
        let chatDBPath = ("~/Library/Messages/chat.db" as NSString).expandingTildeInPath
        guard FileManager.default.fileExists(atPath: chatDBPath) else { return }

        let currentSinceID = self.lastObservedRowID
        let myAppleID = self.nicholasAppleID.lowercased()
        let myPhone = self.nicholasPhone.replacingOccurrences(of: " ", with: "")

        backgroundQueue.async { [weak self, currentSinceID, myAppleID, myPhone] in
            let query = """
            SELECT m.ROWID, m.text, m.is_from_me, h.id, m.date
            FROM message m
            LEFT JOIN handle h ON m.handle_id = h.ROWID
            WHERE m.ROWID > \(currentSinceID) AND m.text IS NOT NULL AND length(m.text) > 0
            ORDER BY m.ROWID ASC;
            """

            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/usr/bin/sqlite3")
            proc.arguments = [chatDBPath, query]
            let pipe = Pipe()
            proc.standardOutput = pipe

            do {
                try proc.run()
                proc.waitUntilExit()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                guard let output = String(data: data, encoding: .utf8), !output.isEmpty else { return }

                let lines = output.components(separatedBy: "\n").filter { !$0.isEmpty }
                var maxSeen = currentSinceID

                for line in lines {
                    let parts = line.components(separatedBy: "|")
                    guard parts.count >= 4, let rowID = Int64(parts[0]) else { continue }
                    maxSeen = max(maxSeen, rowID)

                    let rawText = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
                    let isFromMe = parts[2] == "1"
                    let handleID = parts[3].trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

                    // STRICT FILTER: Only interact if message is from Nicholas's Apple ID or Phone
                    // This prevents Genie from intercepting third-party contacts or friends!
                    let isNicholas = handleID.contains(myAppleID) || handleID.contains(myPhone) || (handleID.isEmpty && isFromMe)
                    let explicitlyForGenie = rawText.lowercased().hasPrefix("genie") ||
                                            rawText.lowercased().hasPrefix("@genie") ||
                                            rawText.hasPrefix("!") ||
                                            rawText.hasPrefix("/")

                    guard isNicholas || explicitlyForGenie else { continue }

                    Task { @MainActor [weak self] in
                        self?.processIncomingMessage(rowID: rowID, text: rawText, sender: handleID.isEmpty ? myAppleID : handleID)
                    }
                }

                Task { @MainActor [weak self] in
                    if let self = self {
                        self.lastObservedRowID = max(self.lastObservedRowID, maxSeen)
                    }
                }
            } catch {}
        }
    }

    // MARK: - Incoming Message Processor
    public func processIncomingMessage(rowID: Int64, text: String, sender: String) {
        // 1. Skip if already processed
        if processedRowIDs.contains(rowID) { return }
        processedRowIDs.insert(rowID)
        if processedRowIDs.count > 250 { processedRowIDs.removeFirst() }

        // 2. Strict Echo Suppression: Never process messages sent by Genie!
        if text.hasPrefix("🧞") || text.hasPrefix("✨ [Genie]") || text.hasPrefix("[Genie]") {
            return
        }
        if sentRepliesCache.contains(text) {
            return
        }

        // Clean query text
        var cleanPrompt = text
        for p in ["@genie", "genie:", "genie,", "genie "] {
            if cleanPrompt.lowercased().hasPrefix(p) {
                cleanPrompt = String(cleanPrompt.dropFirst(p.count)).trimmingCharacters(in: .whitespacesAndNewlines)
                break
            }
        }
        guard !cleanPrompt.isEmpty else { return }

        self.lastMessageReceived = cleanPrompt
        self.lastActiveDate = Date()
        print("📩 [Genie Messages Extension] Query from \(sender): \"\(cleanPrompt)\"")

        // 3. Await Interactions / Debounce:
        // Accumulate messages from the same sender so multiple consecutive thoughts are merged.
        // If a command is explicitly a fast single-word command (e.g., /status, /sleep on, /screen), we can respond quicker,
        // but still give a brief window or buffer consecutive inputs.
        var pending = pendingPromptsBySender[sender] ?? []
        pending.append(cleanPrompt)
        pendingPromptsBySender[sender] = pending

        // Cancel previous timer for this sender if still awaiting further interaction
        debounceTimersBySender[sender]?.cancel()

        let workItem = DispatchWorkItem { [weak self] in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                guard let messages = self.pendingPromptsBySender.removeValue(forKey: sender), !messages.isEmpty else { return }
                self.debounceTimersBySender.removeValue(forKey: sender)

                let mergedPrompt = messages.joined(separator: " \n")
                print("⏳ [Genie Messages Extension] Awaited user interactions from \(sender) (\(messages.count) msg(s)): \"\(mergedPrompt)\"")

                let replyText = await self.handleSmartDispatch(prompt: mergedPrompt, sender: sender)
                self.sendiMessageReply(to: sender, message: replyText)
            }
        }

        debounceTimersBySender[sender] = workItem
        // Wait for interactions (3.5 seconds of silence before answering)
        DispatchQueue.main.asyncAfter(deadline: .now() + interactionDebounceSeconds, execute: workItem)
    }

    // MARK: - Smart Command & Intelligence Dispatcher
    private func handleSmartDispatch(prompt: String, sender: String) async -> String {
        let lower = prompt.lowercased()

        // ── Command 1: Sleep Prevention / Anti-Sleep ─────────────────────────────
        if lower.contains("turn off sleep") || lower.contains("anti-sleep on") || lower == "/sleep on" || lower == "keep awake" || lower == "nosleep" {
            GenieSleepPreventionManager.shared.enableSleepPrevention()
            return "☕ Anti-Sleep Active!\nGenie has disabled display and system sleep. The Mac display will stay on and will not lock."
        }

        if lower.contains("allow sleep") || lower.contains("sleep off") || lower == "/sleep off" || lower == "restore sleep" {
            GenieSleepPreventionManager.shared.disableSleepPrevention()
            return "🌙 Anti-Sleep Released!\nNormal macOS sleep and screen lock timers have been restored."
        }

        // ── Command 2: System Status ─────────────────────────────────────────────
        if lower == "/status" || lower == "status" || lower == "ping" || lower == "/ping" {
            let batt = GeniePhoneBridgeManager.quickBatteryStatus()
            let sleepStatus = GenieSleepPreventionManager.shared.statusDescription
            let activeApp = NSWorkspace.shared.frontmostApplication?.localizedName ?? "Desktop"
            let timeStr = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .short)
            return "🧞 Genie Status (\(timeStr))\n• Battery: \(batt)\n• Power: \(sleepStatus)\n• Active App: \(activeApp)\n• Bridge: Port 8765 Active"
        }

        // ── Command 3: Screenshot Request ────────────────────────────────────────
        if lower == "/screen" || lower == "/screenshot" || lower.contains("take a screenshot") || lower.contains("capture screen") {
            if let imgData = GeniePhoneBridgeManager.captureScreenJPEG(quality: 0.70) {
                let tmpPath = "/tmp/genie_screen.jpg"
                let url = URL(fileURLWithPath: tmpPath)
                try? imgData.write(to: url)
                let w = Int(NSScreen.main?.frame.width ?? 0)
                let h = Int(NSScreen.main?.frame.height ?? 0)
                return "📸 Screenshot Captured (\(w)x\(h)). Saved to Mac (/tmp/genie_screen.jpg)."
            }
            return "⚠️ Failed to capture screen."
        }

        // ── Command 4: Send Message to Contact ("send my Markie a message ...") ────
        if lower.hasPrefix("send ") || lower.hasPrefix("text ") || lower.hasPrefix("tell ") {
            if let (target, body) = parseSendContactCommand(prompt: prompt) {
                let success = sendiMessageDirect(to: target, message: body)
                let targetDisplay = knownContacts.first(where: { $0.value == target })?.key.capitalized ?? target
                if success {
                    return "✓ Sent \"\(body)\" to \(targetDisplay)!"
                } else {
                    return "⚠️ Could not deliver message to \(targetDisplay). Check Messages.app."
                }
            }
        }

        // ── Command 5: Run Terminal Shell Command ────────────────────────────────
        if lower.hasPrefix("/sh ") || lower.hasPrefix("/run ") {
            let cmd = String(prompt.dropFirst(4)).trimmingCharacters(in: .whitespacesAndNewlines)
            let out = runShellCommand(cmd)
            let truncated = out.count > 400 ? String(out.prefix(400)) + "..." : out
            return "💻 [Output]:\n\(truncated.isEmpty ? "(Success - no output)" : truncated)"
        }

        // ── Command 6: Help / Cheatsheet ─────────────────────────────────────────
        if lower == "/help" || lower == "help" || lower == "?" {
            return """
            🧞 Genie iMessage Extension Commands:
            • /status — Battery, anti-sleep & active app
            • /sleep on — Keep Mac & screen permanently awake
            • /sleep off — Restore normal macOS sleep timers
            • /screen — Capture Mac desktop screen
            • send [contact] [msg] — Text any contact
            • /sh [cmd] — Run shell command on Mac
            • Or ask any question for instant AI reasoning!
            """
        }

        // ── General Conversational Query: Invoke Local Genie AI ───────────────────
        return await invokeGenieAI(prompt: prompt)
    }

    // MARK: - Contact Resolution & Sending
    private func parseSendContactCommand(prompt: String) -> (recipient: String, body: String)? {
        let clean = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        // Patterns: "send Markie a message I love you", "send Markie I love you", "text +82... hello"
        var tokens = clean.components(separatedBy: " ")
        guard tokens.count >= 3 else { return nil }
        tokens.removeFirst() // remove "send" or "text" or "tell"

        // Skip optional "my" (e.g. "send my Markie ...")
        if tokens.first?.lowercased() == "my" {
            tokens.removeFirst()
        }

        guard let rawTarget = tokens.first else { return nil }
        tokens.removeFirst()

        // Skip "a message" if present
        if tokens.count >= 2 && tokens[0].lowercased() == "a" && tokens[1].lowercased() == "message" {
            tokens.removeFirst()
            tokens.removeFirst()
        }

        let body = tokens.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !body.isEmpty else { return nil }

        // Match against known contacts or phone number
        let targetKey = rawTarget.lowercased().replacingOccurrences(of: ":", with: "")
        var resolvedRecipient = rawTarget

        if let match = knownContacts[targetKey] {
            resolvedRecipient = match
        } else if let partial = knownContacts.first(where: { $0.key.contains(targetKey) || targetKey.contains($0.key) }) {
            resolvedRecipient = partial.value
        }

        return (recipient: resolvedRecipient, body: body)
    }

    // MARK: - Direct iMessage Transmission via AppleScript
    @discardableResult
    public func sendiMessageDirect(to recipient: String, message: String) -> Bool {
        let target = recipient.isEmpty ? self.nicholasAppleID : recipient
        let escapedMsg = message
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\r", with: " ")

        let script = """
        tell application "Messages"
            try
                set targetService to first account whose service type is iMessage
                set targetBuddyObj to participant "\(target)" of targetService
                send "\(escapedMsg)" to targetBuddyObj
                return "OK"
            on error errMsg
                return "ERROR: " & errMsg
            end try
        end tell
        """

        var errorDict: NSDictionary?
        if let appleScript = NSAppleScript(source: script) {
            let res = appleScript.executeAndReturnError(&errorDict)
            let out = res.stringValue ?? ""
            if out.contains("OK") {
                // Record in cache to prevent echo
                sentRepliesCache.insert(message)
                if sentRepliesCache.count > 200 { sentRepliesCache.removeFirst() }
                return true
            }
        }
        return false
    }

    public func sendiMessageReply(to sender: String, message: String) {
        let prefixed = "🧞 [Genie]: \(message)"
        self.lastReplySent = prefixed
        self.totalMessagesRelayed += 1

        let target = (sender.isEmpty || sender == "me") ? self.nicholasAppleID : sender
        _ = sendiMessageDirect(to: target, message: prefixed)

        // Also record turn in Genie's desktop Chat History so user sees it in Finder Chat
        Task { @MainActor in
            let userMsg = ChatMessage(role: "user", content: "📱 [iMessage]: \(self.lastMessageReceived)", model: "iMessage")
            let genieMsg = ChatMessage(role: "assistant", content: message, model: "Genie Extension")
            LocalModelManager.shared.chatHistory.append(userMsg)
            LocalModelManager.shared.chatHistory.append(genieMsg)
            LocalModelManager.shared.saveChatHistory()
        }
    }

    // MARK: - Local AI Query Invocation (Ollama Local Provider)
    private func invokeGenieAI(prompt: String) async -> String {
        guard let url = URL(string: "http://localhost:11434/api/generate") else {
            return "Mac active (Battery: \(GeniePhoneBridgeManager.quickBatteryStatus()))."
        }

        let timeStr = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .short)
        let battery = GeniePhoneBridgeManager.quickBatteryStatus()
        let sleepState = GenieSleepPreventionManager.shared.statusDescription

        let system = """
        You are Genie, Nicholas Dudek's intelligent personal macOS companion running directly on his Apple Silicon Mac.
        Nicholas is messaging you via the Genie iMessage Extension on his iPhone.
        Respond helpfully, concisely, and cleanly for mobile screen reading.
        Current Time: \(timeStr). Battery: \(battery). Power state: \(sleepState).
        """

        let payload: [String: Any] = [
            "model": "genie:latest",
            "prompt": "\(system)\n\nNicholas: \(prompt)\n\nGenie:",
            "stream": false,
            "options": [
                "temperature": 0.7,
                "num_predict": 300
            ]
        ]

        guard let body = try? JSONSerialization.data(withJSONObject: payload) else {
            return "Mac active and responsive."
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = body
        req.timeoutInterval = 20

        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let resp = json["response"] as? String {
                let trimmed = resp.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty { return trimmed }
            }
        } catch {}

        return "Mac active and responsive. (Battery: \(battery))."
    }

    // MARK: - Shell Command Helper
    private func runShellCommand(_ cmd: String) -> String {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/bin/zsh")
        proc.arguments = ["-c", cmd]
        let pipe = Pipe()
        proc.standardOutput = pipe
        proc.standardError = pipe
        do {
            try proc.run()
            proc.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        } catch {
            return "Error: \(error.localizedDescription)"
        }
    }

    // MARK: - Helper to Query Max Chat DB Row ID
    nonisolated public static func queryMaxChatDBRowID() -> Int64 {
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

    // MARK: - Custom URL Scheme Handler (genie:// and genie-imessage://)
    public func handleURL(_ url: URL) {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true) else { return }
        let host = components.host?.lowercased() ?? ""
        let path = components.path.lowercased()

        if host == "imessage" || host == "chat" || path.contains("imessage") {
            let prompt = components.queryItems?.first(where: { $0.name == "prompt" || $0.name == "text" })?.value ?? ""
            if !prompt.isEmpty {
                Task {
                    let reply = await handleSmartDispatch(prompt: prompt, sender: nicholasAppleID)
                    sendiMessageReply(to: nicholasAppleID, message: reply)
                }
            }
        } else if host == "sleep" {
            let state = components.queryItems?.first(where: { $0.name == "state" })?.value ?? "toggle"
            if state == "off" || state == "prevent" || state == "disable" {
                GenieSleepPreventionManager.shared.enableSleepPrevention()
            } else if state == "on" || state == "allow" {
                GenieSleepPreventionManager.shared.disableSleepPrevention()
            } else {
                GenieSleepPreventionManager.shared.toggleSleepPrevention()
            }
        }
    }
}
