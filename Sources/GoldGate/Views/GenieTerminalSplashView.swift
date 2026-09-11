import SwiftUI
import AppKit
import Combine

// MARK: - 🎮 Futuristic Terminal / Pop-Art Mario Block CLI Console
// Drops down from the top of the app as an interactive Quake-style drop-down CLI.
// Features retro Mario 8-bit block typography, live zsh command execution,
// distributed calculation dispatch, command history, and quick action chips.

public struct GenieTerminalSplashView: View {
    public var compact: Bool = false
    public var onDismiss: (() -> Void)? = nil

    @ObservedObject private var localModels = LocalModelManager.shared

    // MARK: - Command History Entry
    public struct TerminalCommandEntry: Identifiable {
        public let id = UUID()
        public let command: String
        public let output: String
        public let exitCode: Int32
        public let timestamp: String
    }

    @State private var commandInput: String = ""
    @State private var isExecuting: Bool = false
    @State private var commandHistory: [TerminalCommandEntry] = []
    @State private var pastCommandStrings: [String] = []
    @State private var historyIndex: Int = -1
    @State private var isBlockBannerExpanded: Bool = true
    @State private var terminalHeight: CGFloat = 360
    @State private var cursorVisible: Bool = true
    @State private var blockGlowPulse: Double = 0.0
    @State private var popArtTilt: Double = 0.0
    @State private var starFloat: CGFloat = 0.0
    @FocusState private var isInputFocused: Bool

    private let timer = Timer.publish(every: 0.55, on: .main, in: .common).autoconnect()

    // Mario 8-bit block typography for "G E N I E"
    private let marioBlockLines: [String] = [
        "████   ████  █   █  ███  ████",
        "█      █     ██  █   █   █   ",
        "█  ██  ███   █ █ █   █   ███ ",
        "█   █  █     █  ██   █   █   ",
        "████   ████  █   █  ███  ████"
    ]

    private var username: String {
        let name = NSUserName()
        return name.isEmpty ? "user" : name
    }

    public init(compact: Bool = false, onDismiss: (() -> Void)? = nil) {
        self.compact = compact
        self.onDismiss = onDismiss
    }

    public var body: some View {
        VStack(spacing: 0) {
            // 1. Top Terminal Window Chrome Header
            terminalHeaderBar

            // 2. Main Terminal Content (Scrollable Output & Block Banner)
            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 10) {
                        // Iconic Pop-Art Mario Block Banner (Collapsible)
                        if isBlockBannerExpanded {
                            marioBlockCharactersBanner
                        } else {
                            compactBannerStrip
                        }

                        // Terminal Output History
                        if commandHistory.isEmpty {
                            welcomeMessageView
                        } else {
                            ForEach(commandHistory) { entry in
                                terminalEntryRow(entry)
                            }
                        }

                        // Bottom scroll anchor
                        Color.clear
                            .frame(height: 1)
                            .id("bottomAnchor")
                    }
                    .padding(12)
                }
                .frame(maxHeight: terminalHeight)
                .background(Color(red: 0.03, green: 0.03, blue: 0.04))
                .onChange(of: commandHistory.count) { _, _ in
                    withAnimation {
                        proxy.scrollTo("bottomAnchor", anchor: .bottom)
                    }
                }
            }

            Divider().background(Color.white.opacity(0.12))

            // 3. Interactive Command Input Line & Quick Action Chips
            terminalInteractiveInputBar

            // 4. Quick Action CLI Chips Row
            quickActionChipsStrip
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color(red: 1.0, green: 0.10, blue: 0.55).opacity(0.85),
                            Color(red: 0.0, green: 0.95, blue: 1.0).opacity(0.85),
                            Color(red: 1.0, green: 0.90, blue: 0.0).opacity(0.85)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.4
                )
        )
        .shadow(color: Color(red: 1.0, green: 0.10, blue: 0.55).opacity(0.35), radius: 18, x: 0, y: 6)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                blockGlowPulse = 1.0
                starFloat = -5.0
                popArtTilt = 1.2
            }
            isInputFocused = true
        }
        .onReceive(timer) { _ in
            cursorVisible.toggle()
        }
    }

    // MARK: - 1. Terminal Window Chrome Header
    private var terminalHeaderBar: some View {
        HStack(spacing: 8) {
            // Retro Traffic Lights with slide up / close
            HStack(spacing: 5) {
                Button(action: {
                    HapticFeedback.selection()
                    onDismiss?()
                }) {
                    Circle().fill(Color(red: 1.0, green: 0.35, blue: 0.35)).frame(width: 8, height: 8)
                }
                .buttonStyle(.plain)
                .help("Slide Up / Close CLI Drawer (⌘~)")

                Button(action: {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        isBlockBannerExpanded.toggle()
                    }
                    HapticFeedback.selection()
                }) {
                    Circle().fill(Color(red: 1.0, green: 0.80, blue: 0.25)).frame(width: 8, height: 8)
                }
                .buttonStyle(.plain)
                .help("Toggle Mario Block Banner")

                Button(action: {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        terminalHeight = (terminalHeight > 400) ? 280 : 500
                    }
                    HapticFeedback.selection()
                }) {
                    Circle().fill(Color(red: 0.30, green: 0.85, blue: 0.40)).frame(width: 8, height: 8)
                }
                .buttonStyle(.plain)
                .help("Expand / Shrink Height")
            }

            Spacer()

            // Header Title Breadcrumb
            HStack(spacing: 5) {
                Image(systemName: "terminal.fill")
                    .font(.system(size: 9))
                    .foregroundColor(.cyan)
                Text("GENIE_CLI // zsh (Apple Silicon arm64) • Quake Drop-Down")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.88))
            }

            Spacer()

            // Controls: Clear, Toggle Banner & Slide Up
            HStack(spacing: 6) {
                Button(action: {
                    commandHistory.removeAll()
                    HapticFeedback.selection()
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "trash")
                            .font(.system(size: 8))
                        Text("Clear")
                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    }
                    .foregroundColor(.white.opacity(0.65))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.08)))
                }
                .buttonStyle(.plain)
                .help("Clear Terminal Screen")

                Button(action: {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        isBlockBannerExpanded.toggle()
                    }
                    HapticFeedback.selection()
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: isBlockBannerExpanded ? "rectangle.split.2x1" : "rectangle.inset.filled")
                            .font(.system(size: 8))
                        Text(isBlockBannerExpanded ? "Compact" : "Banner")
                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    }
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Color.cyan.opacity(0.12)))
                }
                .buttonStyle(.plain)
                .help("Toggle Mario Block ASCII Banner")

                Button(action: {
                    HapticFeedback.selection()
                    onDismiss?()
                }) {
                    Image(systemName: "chevron.up.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.60))
                }
                .buttonStyle(.plain)
                .help("Slide Up / Close (⌘~)")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(Color(white: 0.10))
    }

    // MARK: - 2. Pop-Art Mario Block Characters Banner Box
    private var marioBlockCharactersBanner: some View {
        ZStack {
            // Pop-Art Magenta Offset 3D Drop-Shadow
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(red: 1.0, green: 0.10, blue: 0.55)) // Neon Pop Pink
                .offset(x: 4, y: 4)

            // Pop-Art Cyan Secondary Offset Accent
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color(red: 0.0, green: 0.95, blue: 1.0), lineWidth: 1.5)
                .offset(x: -2, y: -2)

            // Solid Pitch-Black Rectangle Behind Block Characters
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.black)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                )

            // Floating Pop-Art 8-bit Star Embellishments
            VStack {
                HStack {
                    Text("★")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(red: 1.0, green: 0.90, blue: 0.0)) // Pop Yellow
                        .offset(x: 8, y: starFloat)
                    Spacer()
                    Text("✦")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(red: 0.0, green: 0.95, blue: 1.0)) // Pop Cyan
                        .offset(x: -8, y: -starFloat)
                }
                Spacer()
            }
            .padding(4)

            // White Mario 8-Bit Block Characters for GENIE
            VStack(spacing: compact ? 1 : 2) {
                ForEach(0..<marioBlockLines.count, id: \.self) { idx in
                    Text(verbatim: marioBlockLines[idx])
                        .font(.system(size: compact ? 11 : 14, weight: .black, design: .monospaced))
                        .foregroundColor(.white)
                        .shadow(color: Color.white.opacity(0.55 + blockGlowPulse * 0.40), radius: 6)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                }
            }
            .padding(.horizontal, compact ? 10 : 16)
            .padding(.vertical, compact ? 8 : 10)
        }
        .padding(.horizontal, compact ? 4 : 8)
        .padding(.top, 4)
        .rotationEffect(.degrees(popArtTilt * 0.4))
    }

    private var compactBannerStrip: some View {
        HStack(spacing: 8) {
            Text("██ GENIE 8-BIT NEURAL CLI ██")
                .font(.system(size: 9.5, weight: .black, design: .monospaced))
                .foregroundColor(Color(red: 0.0, green: 0.95, blue: 1.0))
            Spacer()
            Text("Type commands below • 'help' for options")
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color.black.opacity(0.6))
        .cornerRadius(6)
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.cyan.opacity(0.3), lineWidth: 0.8))
    }

    // MARK: - Welcome Message View
    private var welcomeMessageView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(">>> GENIE NEURAL COMMAND LINE INTERFACE (v2.4)")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(Color(red: 1.0, green: 0.85, blue: 0.0))

            Text("Connected to native Apple Silicon environment (/bin/zsh).")
                .font(.system(size: 9.5, design: .monospaced))
                .foregroundColor(.white.opacity(0.70))

            Text("Type any shell command, or run 'help', 'status', 'dist_calc <expr>', or 'wish <text>'.")
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.white.opacity(0.45))
        }
        .padding(8)
        .background(Color.white.opacity(0.02))
        .cornerRadius(6)
    }

    // MARK: - Terminal Entry Row
    private func terminalEntryRow(_ entry: TerminalCommandEntry) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            // Prompt & command line
            HStack(spacing: 5) {
                Text("\(username)@macbook ~ %")
                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                    .foregroundColor(Color(red: 0.25, green: 0.88, blue: 0.82))

                Text(entry.command)
                    .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white)

                Spacer()

                // Exit status pill
                HStack(spacing: 3) {
                    Image(systemName: entry.exitCode == 0 ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.system(size: 8))
                        .foregroundColor(entry.exitCode == 0 ? .green : .red)
                    Text("\(entry.exitCode)")
                        .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                        .foregroundColor(entry.exitCode == 0 ? .green : .red)
                    Text("• \(entry.timestamp)")
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundColor(.white.opacity(0.40))
                }
            }

            // Command Output text
            if !entry.output.isEmpty {
                Text(entry.output)
                    .font(.system(size: 9.5, design: .monospaced))
                    .foregroundColor(entry.exitCode == 0 ? Color.white.opacity(0.85) : Color(red: 1.0, green: 0.45, blue: 0.45))
                    .padding(6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black.opacity(0.4))
                    .cornerRadius(4)
            }
        }
        .padding(.vertical, 2)
    }

    // MARK: - 3. Interactive Command Input Line
    private var terminalInteractiveInputBar: some View {
        HStack(spacing: 6) {
            Text("\(username)@macbook ~ %")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(Color(red: 0.25, green: 0.88, blue: 0.82))

            TextField("Type command (e.g. ls -lah, git status, dist_calc 2^32, wish <idea>)...", text: $commandInput)
                .textFieldStyle(.plain)
                .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                .foregroundColor(.white)
                .focused($isInputFocused)
                .onSubmit {
                    submitCommand()
                }

            if isExecuting {
                ProgressView()
                    .controlSize(.mini)
            } else {
                Button(action: {
                    submitCommand()
                }) {
                    Text("Run ⏎")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.black)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2.5)
                        .background(Capsule().fill(Color.cyan))
                }
                .buttonStyle(.plain)
                .disabled(commandInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(white: 0.08))
    }

    // MARK: - 4. Quick Action CLI Chips Row
    private var quickActionChipsStrip: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 5) {
                cliChip("ls -lah", color: .cyan)
                cliChip("git status", color: .green)
                cliChip("genie status", color: .yellow)
                cliChip("dist_calc 2^32; sqrt(1048576)", color: .purple)
                cliChip("wish build a swiftui clock", color: .pink)
                cliChip("sw_vers", color: .teal)
                cliChip("clear", color: .gray)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
        }
        .background(Color(white: 0.06))
    }

    private func cliChip(_ cmd: String, color: Color) -> some View {
        Button(action: {
            commandInput = cmd
            submitCommand()
        }) {
            HStack(spacing: 3) {
                Text("$")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(color)
                Text(cmd)
                    .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.85))
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.06)))
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(color.opacity(0.3), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Command Execution Logic
    private func submitCommand() {
        let cmd = commandInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cmd.isEmpty else { return }

        // Track in history
        pastCommandStrings.append(cmd)
        historyIndex = pastCommandStrings.count
        commandInput = ""
        isExecuting = true
        HapticFeedback.selection()

        let timeStr = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)

        Task { @MainActor in
            let lower = cmd.lowercased()

            // 1. Built-in special commands
            if lower == "clear" || lower == "cls" {
                commandHistory.removeAll()
                isExecuting = false
                return
            }

            if lower == "help" {
                let helpText = """
                GENIE NEURAL CLI COMMAND REFERENCE:
                  help                        Show this command reference
                  clear                       Clear terminal output screen
                  status, genie status        Inspect neural runtime & M-series performance
                  thirds                      Pop into 3-column Thirds Mode [Studio | Viewer | Chat]
                  wish <text>                 Whisper a wish to the Genie Wish Whisperer
                  rub, rub_lamp               Rub the magic lamp for 3 wishes
                  dist_calc <batch>           Run distributed calculations across CPU cores & VMs
                  <any shell command>         Executed directly in /bin/zsh (e.g. ls, git, python, swift)
                """
                commandHistory.append(TerminalCommandEntry(command: cmd, output: helpText, exitCode: 0, timestamp: timeStr))
                isExecuting = false
                return
            }

            if lower == "status" || lower == "genie status" {
                let cores = ProcessInfo.processInfo.activeProcessorCount
                let mem = ProcessInfo.processInfo.physicalMemory / (1024 * 1024 * 1024)
                let statusText = """
                GENIE NEURAL SYSTEM TELEMETRY:
                  Silicon: Apple M-Series (\(cores) active processor cores)
                  Host Memory: \(mem) GB Unified Memory
                  Local AI Model: \(localModels.effectiveModel)
                  Distributed Compute Engine: Online (\(GenieDistributedComputeEngine.shared.nodes.count) nodes)
                  Wish Whisperer: Ready (\(GenieSporadicWishEngine.shared.totalWishesGranted) wishes granted)
                """
                commandHistory.append(TerminalCommandEntry(command: cmd, output: statusText, exitCode: 0, timestamp: timeStr))
                isExecuting = false
                return
            }

            if lower.hasPrefix("dist_calc ") || lower.hasPrefix("calc ") {
                let expr = String(cmd.dropFirst(lower.hasPrefix("dist_calc ") ? 10 : 5))
                let result = await GenieDistributedComputeEngine.shared.executeDistributedCalculations(expr)
                commandHistory.append(TerminalCommandEntry(command: cmd, output: result, exitCode: 0, timestamp: timeStr))
                isExecuting = false
                return
            }

            if lower.hasPrefix("wish ") {
                let wish = String(cmd.dropFirst(5))
                GenieSporadicWishEngine.shared.grantWish(wish)
                let result = "✨ Granted wish: \"\(wish)\" — dispatched to Genie Chat & Studio!"
                commandHistory.append(TerminalCommandEntry(command: cmd, output: result, exitCode: 0, timestamp: timeStr))
                isExecuting = false
                return
            }

            if lower == "rub" || lower == "rub_lamp" {
                GenieSporadicWishEngine.shared.rubLamp()
                let result = "🪔 Rubbed the magic lamp! Check the menu bar for the Wish Whisperer!"
                commandHistory.append(TerminalCommandEntry(command: cmd, output: result, exitCode: 0, timestamp: timeStr))
                isExecuting = false
                return
            }

            if lower == "thirds" {
                FinderChatWindowManager.shared.snapTo(preset: .thirdsMode)
                let result = "⚏ Snapped to Thirds Mode [ Genie Studio | Viewer | Chat ]"
                commandHistory.append(TerminalCommandEntry(command: cmd, output: result, exitCode: 0, timestamp: timeStr))
                isExecuting = false
                return
            }

            // 2. Fallback: Run real shell command in /bin/zsh via LocalModelManager
            let (out, code) = await localModels.executeTerminalCommand(cmd)
            commandHistory.append(TerminalCommandEntry(command: cmd, output: out, exitCode: code, timestamp: timeStr))
            isExecuting = false
            if code == 0 {
                HapticFeedback.playClickSound(soundName: "Tink")
            } else {
                HapticFeedback.playClickSound(soundName: "Basso")
            }
        }
    }
}
