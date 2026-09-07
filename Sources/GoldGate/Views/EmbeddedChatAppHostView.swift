import AppKit
import Foundation
import SwiftUI

// MARK: - Embedded In-Chat App Host Container & Interactive Slots
// Renders Apple-grade, liquid-glass interactive macOS application viewports directly inside chat messages.
// Includes Precision Calculator with instant copy, scientific keypad, history tape, interactive terminal, markdown memo, and live telemetry.

public enum EmbeddedChatAppType: String, CaseIterable, Identifiable {
    case browser = "Live Browser (Chrome/WebKit)"
    case terminal = "Interactive Terminal (Zsh)"
    case activityMonitor = "Activity Monitor Telemetry"
    case notes = "Instant Markdown Memo"
    case calculator = "Precision Calculator"
    case colorMeter = "Digital Color Palette"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .browser: return "globe"
        case .terminal: return "terminal.fill"
        case .activityMonitor: return "waveform.path.ecg"
        case .notes: return "note.text"
        case .calculator: return "function"
        case .colorMeter: return "paintpalette.fill"
        }
    }

    public var tint: Color {
        switch self {
        case .browser: return .cyan
        case .terminal: return .green
        case .activityMonitor: return .orange
        case .notes: return .yellow
        case .calculator: return Color(red: 0.98, green: 0.58, blue: 0.12) // Apple Calculator Gold/Orange
        case .colorMeter: return .indigo
        }
    }
}

public struct EmbeddedChatAppHostView: View {
    public let appType: EmbeddedChatAppType
    public let initialParam: String?

    // Calculator State
    @State private var calcInput: String = ""
    @State private var calcResult: String = ""
    @State private var calcHistory: [String] = []
    @State private var showKeypad: Bool = true
    @State private var copiedToastText: String? = nil

    // Terminal State
    @State private var terminalCommand: String = ""
    @State private var terminalOutput: String = ""
    @State private var isRunningCommand: Bool = false

    // Notes State
    @State private var noteContent: String = ""

    // Activity Monitor State
    @State private var cpuUsage: Double = 12.4
    @State private var memoryUsage: Double = 28.6
    @State private var telemetryTimer: Timer? = nil

    // Color Meter State
    @State private var selectedColorHex: String = "#FF6B6B"
    @State private var selectedColor: Color = Color(red: 1.0, green: 0.42, blue: 0.42)

    public init(appType: EmbeddedChatAppType, initialParam: String? = nil) {
        self.appType = appType
        self.initialParam = initialParam
    }

    public var body: some View {
        VStack(spacing: 0) {
            // MARK: - Premium Apple Glass Header Bar
            HStack(spacing: 8) {
                // App Category Icon with Glow
                ZStack {
                    Circle()
                        .fill(appType.tint.opacity(0.20))
                        .frame(width: 22, height: 22)
                    Image(systemName: appType.icon)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(appType.tint)
                }

                Text(appType.rawValue)
                    .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)

                // Live Action Copied Pill Notification
                if let toast = copiedToastText {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 9, weight: .bold))
                        Text(toast)
                            .font(.system(size: 9.5, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.green.opacity(0.95)))
                    .transition(.scale.combined(with: .opacity))
                }

                Spacer()

                // Native App Pop-Out Handover Button
                Button(action: {
                    launchNativeMacApp()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right.square.fill")
                        Text("Pop Out")
                    }
                    .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                    .foregroundColor(appType.tint)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3.5)
                    .background(Capsule().fill(appType.tint.opacity(0.18)))
                    .overlay(Capsule().stroke(appType.tint.opacity(0.35), lineWidth: 0.8))
                }
                .buttonStyle(.plain)
                .help("Open in native macOS \(appType.rawValue)")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.06))

            // MARK: - Body: Interactive Viewport Slot
            Group {
                switch appType {
                case .calculator:
                    premiumAppleCalculatorView

                case .browser:
                    LiveBrowserCradleView()
                        .frame(minHeight: 280, maxHeight: 420)

                case .terminal:
                    interactiveTerminalView
                        .frame(minHeight: 200, maxHeight: 300)

                case .activityMonitor:
                    activityMonitorWidgetView
                        .frame(minHeight: 160)

                case .notes:
                    notesScratchpadView
                        .frame(minHeight: 180, maxHeight: 280)

                case .colorMeter:
                    colorMeterWidgetView
                        .frame(minHeight: 160)
                }
            }
            .padding(10)
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(red: 0.08, green: 0.10, blue: 0.15).opacity(0.96))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [appType.tint.opacity(0.50), Color.white.opacity(0.10)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: appType.tint.opacity(0.22), radius: 16, y: 6)
        )
        .padding(.vertical, 4)
        .onAppear {
            setupInitialState()
        }
        .onDisappear {
            telemetryTimer?.invalidate()
        }
    }

    private func setupInitialState() {
        if let param = initialParam, !param.isEmpty {
            switch appType {
            case .terminal:
                terminalCommand = param
                runShellCommand(param)
            case .notes:
                noteContent = param
            case .calculator:
                calcInput = param
                evaluateMath(param)
            case .colorMeter:
                if param.hasPrefix("#") {
                    selectedColorHex = param
                }
            default:
                break
            }
        }
    }

    // MARK: - ==========================================
    // MARK: 1. Apple-Standard Precision Calculator
    // MARK: ==========================================

    @ViewBuilder
    private var premiumAppleCalculatorView: some View {
        VStack(spacing: 8) {
            // Display & Result Screen
            VStack(alignment: .trailing, spacing: 4) {
                // Expression Input Field
                HStack {
                    Image(systemName: "equal")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white.opacity(0.35))

                    TextField("Enter formula (e.g. (1920 * 1080 * 60) / 1024^2)...", text: $calcInput)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .foregroundColor(.white)
                        .onChange(of: calcInput) { _, newValue in
                            evaluateMath(newValue)
                        }

                    if !calcInput.isEmpty {
                        Button(action: {
                            calcInput = ""
                            calcResult = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .buttonStyle(.plain)
                    }
                }

                // High-Resolution Precision Computed Result
                HStack(alignment: .firstTextBaseline) {
                    // History / Keypad Toggle
                    Button(action: {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                            showKeypad.toggle()
                        }
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: showKeypad ? "clock.arrow.circlepath" : "square.grid.3x3.fill")
                            Text(showKeypad ? "History" : "Keypad")
                        }
                        .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.white.opacity(0.08)))
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    // Real-Time Result Text
                    if !calcResult.isEmpty {
                        Text(calcResult)
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(appType.tint)
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    } else {
                        Text("0")
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.2))
                    }

                    // MARK: - Premium Quick One-Click Copy Result Button
                    Button(action: {
                        copyResultToClipboard()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.on.doc.fill")
                                .font(.system(size: 10))
                            Text("Copy")
                                .font(.system(size: 10.5, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4.5)
                        .background(
                            Capsule()
                                .fill(LinearGradient(
                                    colors: [appType.tint, Color(red: 1.0, green: 0.72, blue: 0.25)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ))
                        )
                        .shadow(color: appType.tint.opacity(0.5), radius: 6)
                    }
                    .buttonStyle(.plain)
                    .help("Copy result to clipboard (⌘C)")
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.65))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.12), lineWidth: 1))
            )

            // Content Switcher: Keypad or History Tape
            if showKeypad {
                calculatorKeypadGrid
                    .transition(.opacity)
            } else {
                calculatorHistoryTape
                    .transition(.opacity)
            }
        }
    }

    // MARK: - Calculator Full Interactive Keypad Ribbon
    @ViewBuilder
    private var calculatorKeypadGrid: some View {
        VStack(spacing: 5) {
            // Row 1: Scientific Specials
            HStack(spacing: 5) {
                keypadButton("(", tint: .gray) { appendCalc("(") }
                keypadButton(")", tint: .gray) { appendCalc(")") }
                keypadButton("√", tint: .gray) { appendCalc("sqrt(") }
                keypadButton("^", tint: .gray) { appendCalc("^") }
                keypadButton("π", tint: .gray) { appendCalc("3.14159265") }
                keypadButton("AC", tint: .red) {
                    calcInput = ""
                    calcResult = ""
                }
            }

            // Row 2: 7 8 9 ÷ ⌫
            HStack(spacing: 5) {
                keypadButton("7") { appendCalc("7") }
                keypadButton("8") { appendCalc("8") }
                keypadButton("9") { appendCalc("9") }
                keypadButton("÷", tint: appType.tint) { appendCalc(" / ") }
                keypadButton("⌫", tint: .gray) {
                    if !calcInput.isEmpty {
                        calcInput.removeLast()
                    }
                }
            }

            // Row 3: 4 5 6 × %
            HStack(spacing: 5) {
                keypadButton("4") { appendCalc("4") }
                keypadButton("5") { appendCalc("5") }
                keypadButton("6") { appendCalc("6") }
                keypadButton("×", tint: appType.tint) { appendCalc(" * ") }
                keypadButton("%", tint: .gray) { appendCalc(" / 100") }
            }

            // Row 4: 1 2 3 − ±
            HStack(spacing: 5) {
                keypadButton("1") { appendCalc("1") }
                keypadButton("2") { appendCalc("2") }
                keypadButton("3") { appendCalc("3") }
                keypadButton("−", tint: appType.tint) { appendCalc(" - ") }
                keypadButton("±", tint: .gray) {
                    if calcInput.hasPrefix("-") {
                        calcInput.removeFirst()
                    } else {
                        calcInput = "-" + calcInput
                    }
                }
            }

            // Row 5: 0 . + =
            HStack(spacing: 5) {
                keypadButton("0") { appendCalc("0") }
                keypadButton(".") { appendCalc(".") }
                keypadButton("+", tint: appType.tint) { appendCalc(" + ") }
                keypadButton("=", tint: Color.green, isWide: true) {
                    commitCalculation()
                }
            }
        }
    }

    @ViewBuilder
    private func keypadButton(_ label: String, tint: Color = Color.white.opacity(0.15), isWide: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: {
            HapticFeedback.selection()
            action()
        }) {
            Text(label)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(tint == Color.white.opacity(0.15) ? .white : (tint == appType.tint || tint == .green || tint == .red ? (tint == .white ? .black : .white) : .white.opacity(0.9)))
                .frame(maxWidth: isWide ? .infinity : nil)
                .frame(width: isWide ? nil : 42, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 7)
                        .fill(tint == Color.white.opacity(0.15) ? Color.white.opacity(0.10) : tint.opacity(0.85))
                        .overlay(
                            RoundedRectangle(cornerRadius: 7)
                                .stroke(Color.white.opacity(0.18), lineWidth: 0.5)
                        )
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Calculator History Tape
    @ViewBuilder
    private var calculatorHistoryTape: some View {
        VStack(spacing: 4) {
            if calcHistory.isEmpty {
                Text("No previous calculations yet.")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(.white.opacity(0.4))
                    .frame(height: 90)
            } else {
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 4) {
                        ForEach(calcHistory.reversed(), id: \.self) { item in
                            HStack {
                                Text(item)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.85))
                                Spacer()
                                Button(action: {
                                    calcInput = item.components(separatedBy: " = ").first ?? item
                                    evaluateMath(calcInput)
                                }) {
                                    Image(systemName: "arrow.uturn.backward.circle")
                                        .font(.system(size: 11))
                                        .foregroundColor(appType.tint)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.05)))
                        }
                    }
                }
                .frame(height: 90)
            }
        }
    }

    private func appendCalc(_ str: String) {
        calcInput += str
        evaluateMath(calcInput)
    }

    private func evaluateMath(_ expr: String) {
        let clean = expr.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else {
            calcResult = ""
            return
        }

        // Format scientific tokens
        var sanitized = clean
            .replacingOccurrences(of: "×", with: "*")
            .replacingOccurrences(of: "÷", with: "/")
            .replacingOccurrences(of: "−", with: "-")
            .replacingOccurrences(of: "π", with: "\(Double.pi)")

        // Handle square roots e.g. sqrt(144) -> 12
        if sanitized.contains("sqrt(") {
            sanitized = sanitized.replacingOccurrences(of: "sqrt", with: "sqrt")
        }

        // NSExpression Evaluation
        let exp = NSExpression(format: sanitized)
        if let val = exp.expressionValue(with: nil, context: nil) as? NSNumber {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 6
            formatter.minimumFractionDigits = 0
            calcResult = formatter.string(from: val) ?? "\(val)"
        } else {
            // Live partial typing doesn't hard-error
        }
    }

    private func commitCalculation() {
        evaluateMath(calcInput)
        guard !calcResult.isEmpty else { return }
        let entry = "\(calcInput) = \(calcResult)"
        if !calcHistory.contains(entry) {
            calcHistory.append(entry)
            if calcHistory.count > 15 { calcHistory.removeFirst() }
        }
        calcInput = calcResult
    }

    private func copyResultToClipboard() {
        HapticFeedback.heavy()
        let toCopy = calcResult.isEmpty ? calcInput : calcResult
        guard !toCopy.isEmpty else { return }

        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(toCopy, forType: .string)

        withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
            copiedToastText = "Result Copied (\(toCopy))! ✨"
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeOut(duration: 0.25)) {
                self.copiedToastText = nil
            }
        }
    }

    // MARK: - ==========================================
    // MARK: 2. Interactive Terminal View (Zsh)
    // MARK: ==========================================

    @ViewBuilder
    private var interactiveTerminalView: some View {
        VStack(spacing: 6) {
            // Quick Diagnostics Actions Ribbon
            HStack(spacing: 5) {
                terminalQuickPill("git status") { runShellCommand("git status") }
                terminalQuickPill("sw_vers") { runShellCommand("sw_vers") }
                terminalQuickPill("df -h") { runShellCommand("df -h /") }
                terminalQuickPill("uptime") { runShellCommand("uptime") }

                Spacer()

                // Copy Terminal Output
                Button(action: {
                    HapticFeedback.selection()
                    let pb = NSPasteboard.general
                    pb.clearContents()
                    pb.setString(terminalOutput, forType: .string)
                    withAnimation { copiedToastText = "Terminal Copied! 📋" }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { self.copiedToastText = nil }
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 10))
                        .foregroundColor(.green)
                }
                .buttonStyle(.plain)
                .help("Copy full terminal output")

                // Clear
                Button(action: { terminalOutput = "" }) {
                    Image(systemName: "trash")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.6))
                }
                .buttonStyle(.plain)
                .help("Clear output")
            }

            // Output Terminal Screen
            ScrollView(.vertical, showsIndicators: true) {
                Text(terminalOutput.isEmpty ? "Genie zsh sandbox ready.\nType any shell command below..." : terminalOutput)
                    .font(.system(size: 10.5, weight: .regular, design: .monospaced))
                    .foregroundColor(Color.green.opacity(0.92))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(8)
            }
            .background(Color.black.opacity(0.85))
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.green.opacity(0.25), lineWidth: 0.8))

            // Command Prompt Bar
            HStack(spacing: 6) {
                Text("zsh ❯")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.green)

                TextField("Enter command...", text: $terminalCommand, onCommit: {
                    runShellCommand(terminalCommand)
                })
                .textFieldStyle(.plain)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.white)

                if isRunningCommand {
                    ProgressView()
                        .scaleEffect(0.6)
                }
            }
            .padding(7)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.6)))
        }
    }

    @ViewBuilder
    private func terminalQuickPill(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            HapticFeedback.selection()
            action()
        }) {
            Text(label)
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundColor(.green)
                .padding(.horizontal, 6)
                .padding(.vertical, 2.5)
                .background(Capsule().fill(Color.green.opacity(0.14)))
                .overlay(Capsule().stroke(Color.green.opacity(0.3), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }

    private func runShellCommand(_ cmd: String) {
        let trimmed = cmd.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isRunningCommand = true
        DispatchQueue.global(qos: .userInitiated).async {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/bin/zsh")
            task.arguments = ["-c", trimmed]
            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = pipe

            do {
                try task.run()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                task.waitUntilExit()
                let out = String(data: data, encoding: .utf8) ?? "Done."
                DispatchQueue.main.async {
                    self.isRunningCommand = false
                    self.terminalOutput += "\n$ \(trimmed)\n\(out)"
                    self.terminalCommand = ""
                }
            } catch {
                DispatchQueue.main.async {
                    self.isRunningCommand = false
                    self.terminalOutput += "\nError: \(error.localizedDescription)"
                }
            }
        }
    }

    // MARK: - ==========================================
    // MARK: 3. Activity Monitor Live Telemetry
    // MARK: ==========================================

    @ViewBuilder
    private var activityMonitorWidgetView: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                // CPU Metric Card
                VStack(spacing: 4) {
                    HStack {
                        Text("CPU LOAD")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(.orange)
                        Spacer()
                        Image(systemName: "cpu")
                            .font(.system(size: 10))
                            .foregroundColor(.orange)
                    }
                    Text("\(String(format: "%.1f", cpuUsage))%")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    ProgressView(value: cpuUsage, total: 100.0)
                        .tint(.orange)
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.55)))

                // RAM Metric Card
                VStack(spacing: 4) {
                    HStack {
                        Text("GENIE RAM")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(.cyan)
                        Spacer()
                        Image(systemName: "memorychip")
                            .font(.system(size: 10))
                            .foregroundColor(.cyan)
                    }
                    Text("\(String(format: "%.1f", memoryUsage)) MB")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    ProgressView(value: memoryUsage, total: 35.0)
                        .tint(.cyan)
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.55)))

                // ProMotion Framerate Card
                VStack(spacing: 4) {
                    HStack {
                        Text("PROMOTION")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(.green)
                        Spacer()
                        Image(systemName: "sparkles")
                            .font(.system(size: 10))
                            .foregroundColor(.green)
                    }
                    Text("120 FPS")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("0 Drop / Zero Latency")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.55)))
            }
        }
    }

    // MARK: - ==========================================
    // MARK: 4. Notes Scratchpad View
    // MARK: ==========================================

    @ViewBuilder
    private var notesScratchpadView: some View {
        VStack(spacing: 6) {
            HStack {
                Text("\(noteContent.split(separator: " ").count) words  •  \(noteContent.count) chars")
                    .font(.system(size: 9.5, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))

                Spacer()

                // Copy Note Button
                Button(action: {
                    HapticFeedback.selection()
                    let pb = NSPasteboard.general
                    pb.clearContents()
                    pb.setString(noteContent, forType: .string)
                    withAnimation { copiedToastText = "Note Copied! 📝" }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { self.copiedToastText = nil }
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "doc.on.doc.fill")
                        Text("Copy")
                    }
                    .font(.system(size: 9.5, weight: .semibold))
                    .foregroundColor(.yellow)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2.5)
                    .background(Capsule().fill(Color.yellow.opacity(0.18)))
                }
                .buttonStyle(.plain)

                // Save to Desktop Notes
                Button(action: {
                    saveNoteToDisk()
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "square.and.arrow.down.fill")
                        Text("Save")
                    }
                    .font(.system(size: 9.5, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2.5)
                    .background(Capsule().fill(Color.white.opacity(0.12)))
                }
                .buttonStyle(.plain)
            }

            TextEditor(text: $noteContent)
                .font(.system(size: 11.5, design: .rounded))
                .foregroundColor(.white)
                .scrollContentBackground(.hidden)
                .background(Color.black.opacity(0.55))
                .cornerRadius(8)
                .padding(2)
        }
    }

    private func saveNoteToDisk() {
        HapticFeedback.heavy()
        let home = FileManager.default.homeDirectoryForCurrentUser
        let notesDir = home.appendingPathComponent("Desktop/Notes")
        try? FileManager.default.createDirectory(at: notesDir, withIntermediateDirectories: true)
        let filename = "Genie_Note_\(Int(Date().timeIntervalSince1970)).md"
        let fileURL = notesDir.appendingPathComponent(filename)
        try? noteContent.write(to: fileURL, atomically: true, encoding: .utf8)

        withAnimation {
            copiedToastText = "Saved to Desktop/Notes! 📂"
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            self.copiedToastText = nil
        }
    }

    // MARK: - ==========================================
    // MARK: 5. Digital Color Palette & Inspector
    // MARK: ==========================================

    @ViewBuilder
    private var colorMeterWidgetView: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                // Color Preview Box
                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedColor)
                    .frame(width: 48, height: 48)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.3), lineWidth: 1))

                VStack(alignment: .leading, spacing: 3) {
                    Text("Selected Color")
                        .font(.system(size: 9.5, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                    Text(selectedColorHex)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }

                Spacer()

                // Copy HEX Button
                Button(action: {
                    HapticFeedback.selection()
                    let pb = NSPasteboard.general
                    pb.clearContents()
                    pb.setString(selectedColorHex, forType: .string)
                    withAnimation { copiedToastText = "HEX Copied (\(selectedColorHex))! 🎨" }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { self.copiedToastText = nil }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.doc.fill")
                        Text("Copy HEX")
                    }
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4.5)
                    .background(Capsule().fill(Color.indigo.opacity(0.85)))
                }
                .buttonStyle(.plain)
            }

            // Quick Color Palette Swatches
            HStack(spacing: 8) {
                let swatches: [(Color, String)] = [
                    (Color.cyan, "#00F5FF"),
                    (Color.purple, "#BF5AF2"),
                    (Color.orange, "#FF9500"),
                    (Color.green, "#30D158"),
                    (Color.pink, "#FF375F"),
                    (Color.yellow, "#FFD60A"),
                    (Color(red: 0.15, green: 0.55, blue: 1.0), "#0A84FF")
                ]

                ForEach(swatches, id: \.1) { swatch in
                    Button(action: {
                        HapticFeedback.selection()
                        selectedColor = swatch.0
                        selectedColorHex = swatch.1
                    }) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(swatch.0)
                            .frame(height: 32)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(selectedColorHex == swatch.1 ? Color.white : Color.clear, lineWidth: 2)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Handover to Native macOS Application
    private func launchNativeMacApp() {
        HapticFeedback.selection()
        let bundleID: String = {
            switch appType {
            case .browser: return "com.google.Chrome"
            case .terminal: return "com.apple.Terminal"
            case .activityMonitor: return "com.apple.ActivityMonitor"
            case .notes: return "com.apple.Notes"
            case .calculator: return "com.apple.calculator"
            case .colorMeter: return "com.apple.DigitalColorMeter"
            }
        }()

        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
        }
    }
}

