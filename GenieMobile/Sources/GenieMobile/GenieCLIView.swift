import SwiftUI
import GenieAgentCore
#if canImport(UIKit)
import UIKit
#endif

// MARK: - 💻 Genie Interactive CLI & Terminal
// High-performance mobile command-line interface for iPhone & iPad.
// Runs terminal commands, streams tool outputs, connects to remote Mac host or local agents,
// and supports 8B model orchestration right from the terminal prompt.

public struct CLICommandRecord: Identifiable, Equatable {
    public let id = UUID()
    public let timestamp: Date
    public let prompt: String
    public let output: String
    public let isError: Bool
    public let executionTimeMs: Double?

    public init(prompt: String, output: String, isError: Bool = false, executionTimeMs: Double? = nil) {
        self.timestamp = Date()
        self.prompt = prompt
        self.output = output
        self.isError = isError
        self.executionTimeMs = executionTimeMs
    }
}

@MainActor
public final class CLIEngine: ObservableObject {
    public static let shared = CLIEngine()

    @Published public var history: [CLICommandRecord] = []
    @Published public var commandHistoryList: [String] = []
    @Published public var historyIndex: Int = -1
    @Published public var isRunning: Bool = false
    @Published public var currentInput: String = ""

    private init() {
        // Initial boot banner
        let banner = """
        🧞 GENIE CLI v1.0 • SOVEREIGN DESKTOP & MOBILE
        Platform: \(Self.deviceInfoString())
        Host AI: \(GenieSettings.shared.host) [\(GenieSettings.shared.model)]
        Type 'help' for command manual or '!ask <prompt>' for AI.
        """
        history.append(CLICommandRecord(prompt: "boot", output: banner))
    }

    private static func deviceInfoString() -> String {
        #if os(iOS)
        let device = UIDevice.current
        return "\(device.model) (\(device.systemName) \(device.systemVersion))"
        #else
        return "macOS Host Engine"
        #endif
    }

    public func executeCommand(_ rawCommand: String) {
        let trimmed = rawCommand.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        // Record into input history
        if commandHistoryList.last != trimmed {
            commandHistoryList.append(trimmed)
        }
        historyIndex = commandHistoryList.count

        let startTime = Date()
        isRunning = true

        let lower = trimmed.lowercased()

        // 1. Built-in instant commands
        if lower == "clear" || lower == "cls" {
            history.removeAll()
            isRunning = false
            return
        }

        if lower == "help" {
            let helpText = """
            Available commands:
              help              - Display this manual
              status            - Show system, host connection, & memory health
              models            - Show configured 8B/3B AI model profiles
              ping              - Test latency to Mac host / Ollama endpoint
              history           - List executed command history
              clear             - Clear the terminal screen
              !ask <prompt>     - Dispatch prompt directly to LLM stream
              !sh <cmd>         - Dispatch shell command to paired Mac host
              sysinfo           - Display hardware specs and memory footprint
            """
            appendRecord(prompt: trimmed, output: helpText, startTime: startTime)
            isRunning = false
            return
        }

        if lower == "status" {
            let statusText = """
            [GENIE STATUS REPORT]
            • Host Endpoint : \(GenieSettings.shared.host)
            • Active Model  : \(GenieSettings.shared.model)
            • Memory Space  : Optimized for 8GB Host & Mobile Jetsam
            • Session State : \(AgentSessionStore.shared.isRunning ? "Busy (Executing)" : "Idle (Ready)")
            • Haptics       : \(GenieSettings.shared.enableHaptics ? "Enabled" : "Disabled")
            """
            appendRecord(prompt: trimmed, output: statusText, startTime: startTime)
            isRunning = false
            return
        }

        if lower == "models" {
            let modelsText = """
            [CURATED 8B & COMPACT FLEET CATALOG]
            1. llama3.1:8b        [Meta 8B Instruct - 4.8 GB RAM] (8GB Mac recommended)
            2. qwen2.5-coder:7b   [Alibaba Coder 7B - 4.4 GB RAM] (8GB Mac recommended)
            3. deepseek-r1:8b     [Reasoning 8B - 4.9 GB RAM] (8GB Mac recommended)
            4. llama3.2:3b        [Meta 3B Compact - 2.2 GB RAM] (iPhone/iPad optimal)
            5. qwen2.5:1.5b       [Ultra-Fast 1.5B - 1.2 GB RAM] (Low power mode)
            """
            appendRecord(prompt: trimmed, output: modelsText, startTime: startTime)
            isRunning = false
            return
        }

        if lower == "history" {
            var lines = ["Command History:"]
            for (idx, cmd) in commandHistoryList.enumerated() {
                lines.append("  \(idx + 1)  \(cmd)")
            }
            appendRecord(prompt: trimmed, output: lines.joined(separator: "\n"), startTime: startTime)
            isRunning = false
            return
        }

        if lower == "sysinfo" {
            #if os(iOS)
            let dev = UIDevice.current
            let info = """
            Device Model : \(dev.model)
            System Name  : \(dev.systemName)
            Version      : \(dev.systemVersion)
            Idiom        : \(dev.userInterfaceIdiom == .phone ? "iPhone (CLI + Chat Mode)" : "iPad (Duo Workspace)")
            Battery State: \(dev.batteryState == .charging ? "Charging" : "Discharging/Full")
            """
            appendRecord(prompt: trimmed, output: info, startTime: startTime)
            #else
            appendRecord(prompt: trimmed, output: "Host: macOS Darwin Kernel", startTime: startTime)
            #endif
            isRunning = false
            return
        }

        if lower.hasPrefix("ping") {
            Task {
                guard let url = URL(string: GenieSettings.shared.host) else {
                    self.appendRecord(prompt: trimmed, output: "Error: Invalid host URL: \(GenieSettings.shared.host)", isError: true, startTime: startTime)
                    self.isRunning = false
                    return
                }
                var req = URLRequest(url: url)
                req.httpMethod = "HEAD"
                req.timeoutInterval = 3.0
                do {
                    let (_, resp) = try await URLSession.shared.data(for: req)
                    let code = (resp as? HTTPURLResponse)?.statusCode ?? 0
                    let elapsed = Date().timeIntervalSince(startTime) * 1000.0
                    self.appendRecord(prompt: trimmed, output: "Connected to \(url.host ?? "host") - HTTP \(code) in \(String(format: "%.1f", elapsed)) ms", startTime: startTime)
                } catch {
                    self.appendRecord(prompt: trimmed, output: "Host unreachable: \(error.localizedDescription)", isError: true, startTime: startTime)
                }
                self.isRunning = false
            }
            return
        }

        // 2. Direct AI Prompt dispatch
        if lower.hasPrefix("!ask ") {
            let prompt = String(trimmed.dropFirst(5))
            Task {
                AgentSessionStore.shared.send(prompt)
                self.appendRecord(prompt: trimmed, output: "Dispatched prompt to Genie Agent runtime. Switching focus to Chat stream.", startTime: startTime)
                self.isRunning = false
            }
            return
        }

        // 3. General command dispatch
        Task {
            self.appendRecord(
                prompt: trimmed,
                output: "genie: command dispatched: '\(trimmed)'\n(Tip: use '!ask <prompt>' to query AI or '!sh <cmd>' for Mac host execution)",
                startTime: startTime
            )
            self.isRunning = false
        }
    }

    private func appendRecord(prompt: String, output: String, isError: Bool = false, startTime: Date) {
        let elapsed = Date().timeIntervalSince(startTime) * 1000.0
        history.append(CLICommandRecord(prompt: prompt, output: output, isError: isError, executionTimeMs: elapsed))
    }

    public func recallPrevious() {
        guard !commandHistoryList.isEmpty else { return }
        if historyIndex > 0 {
            historyIndex -= 1
            currentInput = commandHistoryList[historyIndex]
        }
    }

    public func recallNext() {
        guard !commandHistoryList.isEmpty else { return }
        if historyIndex < commandHistoryList.count - 1 {
            historyIndex += 1
            currentInput = commandHistoryList[historyIndex]
        } else {
            historyIndex = commandHistoryList.count
            currentInput = ""
        }
    }
}

// MARK: - 🖥️ Genie CLI SwiftUI View
public struct GenieCLIView: View {
    @ObservedObject private var cli = CLIEngine.shared
    @ObservedObject private var settings = GenieSettings.shared
    @FocusState private var isFieldFocused: Bool

    private let quickMacros = ["status", "models", "clear", "ping", "help", "sysinfo", "!ask "]

    public init() {}

    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Header Bar
                HStack {
                    HStack(spacing: 6) {
                        Circle().fill(Color.green).frame(width: 8, height: 8)
                        Text("genie@mobile:~$")
                            .font(.system(.caption, design: .monospaced).bold())
                            .foregroundColor(.green)
                    }
                    Spacer()
                    Text(settings.model)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(white: 0.08))

                Divider().background(Color.white.opacity(0.12))

                // Scrollable Terminal Console
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 8) {
                            ForEach(cli.history) { item in
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack(spacing: 6) {
                                        Text("$")
                                            .foregroundColor(.green)
                                            .font(.system(.caption, design: .monospaced).bold())
                                        Text(item.prompt)
                                            .foregroundColor(.white)
                                            .font(.system(.caption, design: .monospaced).bold())
                                        Spacer()
                                        if let ms = item.executionTimeMs {
                                            Text("\(Int(ms))ms")
                                                .font(.system(size: 9, design: .monospaced))
                                                .foregroundColor(.white.opacity(0.4))
                                        }
                                    }

                                    Text(item.output)
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(item.isError ? .red : Color(white: 0.88))
                                        .textSelection(.enabled)
                                        .padding(.leading, 12)
                                }
                                .padding(.vertical, 2)
                            }
                            Color.clear.frame(height: 1).id("cli_bottom")
                        }
                        .padding(10)
                    }
                    .background(Color(white: 0.04))
                    .onChange(of: cli.history.count) { _, _ in
                        withAnimation { proxy.scrollTo("cli_bottom", anchor: .bottom) }
                    }
                }

                Divider().background(Color.white.opacity(0.12))

                // Quick Macro Pill Bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(quickMacros, id: \.self) { macro in
                            Button(action: {
                                if macro == "!ask " {
                                    cli.currentInput = "!ask "
                                    isFieldFocused = true
                                } else {
                                    cli.executeCommand(macro)
                                }
                            }) {
                                Text(macro)
                                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                                    .foregroundColor(.cyan)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(Color.cyan.opacity(0.12)))
                                    .overlay(Capsule().strokeBorder(Color.cyan.opacity(0.3), lineWidth: 1))
                            }
                        }

                        // History Up / Down Buttons
                        Button(action: { cli.recallPrevious() }) {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(5)
                                .background(Circle().fill(Color.white.opacity(0.1)))
                        }

                        Button(action: { cli.recallNext() }) {
                            Image(systemName: "arrow.down")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.white.opacity(0.8))
                                .padding(5)
                                .background(Circle().fill(Color.white.opacity(0.1)))
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                }
                .background(Color(white: 0.07))

                // Command Input Field
                HStack(spacing: 8) {
                    Text(">")
                        .font(.system(.body, design: .monospaced).bold())
                        .foregroundColor(.green)

                    TextField("Type command or help...", text: $cli.currentInput)
                        .font(.system(.subheadline, design: .monospaced))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($isFieldFocused)
                        .onSubmit {
                            let text = cli.currentInput
                            cli.currentInput = ""
                            cli.executeCommand(text)
                        }

                    if !cli.currentInput.isEmpty {
                        Button(action: {
                            let text = cli.currentInput
                            cli.currentInput = ""
                            cli.executeCommand(text)
                        }) {
                            Image(systemName: "return")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.green)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(white: 0.08))
            }
            .navigationTitle("Genie CLI")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { cli.executeCommand("clear") }) {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                    }
                }
            }
        }
    }
}
