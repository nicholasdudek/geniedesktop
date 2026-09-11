import AppKit
import SwiftUI

// MARK: - 🎨 Tool Category Metadata & Theme
public enum GenieToolCategory: String, CaseIterable, Sendable {
    case tail = "tail"
    case siri = "siri"
    case files = "files"
    case compile = "compile"
    case browser = "browser"
    case airlock = "airlock"
    case worker = "worker"
    case general = "general"

    public var title: String {
        switch self {
        case .tail: return "LOGS & RETRIEVAL"
        case .siri: return "SIRI AUTOMATION"
        case .files: return "FILE WORKSPACE"
        case .compile: return "NATIVE COMPILER"
        case .browser: return "WEB NAVIGATION"
        case .airlock: return "DESKTOP AIRLOCK"
        case .worker: return "APFS FORK WORKER"
        case .general: return "NATIVE ENGINE"
        }
    }

    public var icon: String {
        switch self {
        case .tail: return "scroll.fill"
        case .siri: return "waveform.circle.fill"
        case .files: return "doc.badge.gearshape.fill"
        case .compile: return "bolt.fill"
        case .browser: return "globe.americas.fill"
        case .airlock: return "archivebox.circle.fill"
        case .worker: return "cpu.fill"
        case .general: return "terminal.fill"
        }
    }

    public var primaryColor: Color {
        switch self {
        case .tail: return Color.orange
        case .siri: return Color(red: 0.98, green: 0.35, blue: 0.75) // Siri Magenta
        case .files: return Color.cyan
        case .compile: return Color.purple
        case .browser: return Color.blue
        case .airlock: return Color.green
        case .worker: return Color(red: 1.0, green: 0.82, blue: 0.20) // Gold
        case .general: return Color.cyan
        }
    }

    public var secondaryColor: Color {
        switch self {
        case .tail: return Color.yellow
        case .siri: return Color.cyan
        case .files: return Color.blue
        case .compile: return Color.indigo
        case .browser: return Color.teal
        case .airlock: return Color.mint
        case .worker: return Color.orange
        case .general: return Color.blue
        }
    }
}

// MARK: - 🎬 Genie Tool Command Animated View
/// Entertaining, vibrant, liquid-glass animated card for model tool calls and command execution.
public struct GenieToolCommandAnimatedView: View {
    public let toolName: String
    public let commandText: String
    public var isResult: Bool = false

    @State private var isExecuting: Bool = false
    @State private var executionResult: String? = nil
    @State private var isHovered: Bool = false
    @State private var isCopied: Bool = false
    @State private var showRawCode: Bool = false
    @State private var isExpanded: Bool = true
    @State private var rotationAngle: Double = 0.0
    @State private var laserOffset: CGFloat = -180.0
    @State private var pulseScale: CGFloat = 1.0

    public init(toolName: String, commandText: String, isResult: Bool = false) {
        self.toolName = toolName
        self.commandText = commandText
        self.isResult = isResult
    }

    private var category: GenieToolCategory {
        let name = toolName.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        if name.contains("tail") { return .tail }
        if name.contains("siri") || name.contains("shortcut") { return .siri }
        if name.contains("read") || name.contains("write") || name.contains("crawl") || name.contains("find") { return .files }
        if name.contains("compile") || name.contains("xcode") { return .compile }
        if name.contains("browser") || name.contains("web") { return .browser }
        if name.contains("airlock") || name.contains("trash") { return .airlock }
        if name.contains("worker") || name.contains("fork") { return .worker }
        return .general
    }

    private var cleanArguments: String {
        var str = commandText.trimmingCharacters(in: .whitespacesAndNewlines)
        // If the command body repeated the tool name, clean it
        let prefix = "tool:\(toolName)"
        if str.hasPrefix(prefix) {
            str = String(str.dropFirst(prefix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
        } else if str.hasPrefix(toolName) {
            str = String(str.dropFirst(toolName.count)).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return str.isEmpty ? commandText : str
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ── Holographic Entertaining Header ──
            cardHeaderView

            // ── Animated Command / Argument Body ──
            if isExpanded {
                cardBodyView
            }

            // ── Live Execution Result Drawer (if run interactively) ──
            if let result = executionResult {
                executionResultDrawer(result: result)
            }
        }
        .background(
            ZStack {
                // Glassmorphic Acrylic Base
                VisualEffectBlur(material: .popover, blendingMode: .withinWindow, state: .active)
                Color.black.opacity(0.48)

                // Subtle Radial Holographic Glow
                RadialGradient(
                    colors: [
                        category.primaryColor.opacity(isHovered ? 0.16 : 0.08),
                        Color.clear
                    ],
                    center: .topLeading,
                    startRadius: 10,
                    endRadius: 280
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay(
            // Glowing Specular Rim
            RoundedRectangle(cornerRadius: 15, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            category.primaryColor.opacity(isHovered ? 0.85 : 0.45),
                            category.secondaryColor.opacity(isHovered ? 0.65 : 0.25),
                            Color.white.opacity(0.12)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: isHovered ? 1.2 : 0.8
                )
        )
        .shadow(
            color: category.primaryColor.opacity(isHovered ? 0.28 : 0.12),
            radius: isHovered ? 14 : 6,
            y: 4
        )
        .onHover { hovering in
            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                isHovered = hovering
            }
        }
        .onAppear {
            // Continuous spinning orbital ring
            withAnimation(.linear(duration: 5.0).repeatForever(autoreverses: false)) {
                rotationAngle = 360.0
            }
            // Laser sweep line
            withAnimation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true)) {
                laserOffset = 180.0
            }
            // Status pulse
            withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true)) {
                pulseScale = 1.25
            }
        }
    }

    // MARK: - 🎛️ Header View
    private var cardHeaderView: some View {
        HStack(spacing: 8) {
            // 🌀 Spinning Holographic Icon Ring
            ZStack {
                // Rotating conic aura
                Circle()
                    .strokeBorder(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                category.primaryColor,
                                category.secondaryColor,
                                Color.white.opacity(0.2),
                                category.primaryColor
                            ]),
                            center: .center
                        ),
                        lineWidth: 1.5
                    )
                    .frame(width: 26, height: 26)
                    .rotationEffect(.degrees(rotationAngle))

                Circle()
                    .fill(category.primaryColor.opacity(0.18))
                    .frame(width: 22, height: 22)

                Image(systemName: category.icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(category.primaryColor)
                    .scaleEffect(isHovered ? 1.15 : 1.0)
            }

            // Title & Category Badge
            VStack(alignment: .leading, spacing: 1.5) {
                HStack(spacing: 6) {
                    Text(category.title)
                        .font(.system(size: 8, weight: .heavy, design: .monospaced))
                        .foregroundColor(category.secondaryColor.opacity(0.92))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1.5)
                        .background(Capsule().fill(category.primaryColor.opacity(0.18)))

                    if isExecuting {
                        HStack(spacing: 3) {
                            ProgressView()
                                .scaleEffect(0.5)
                                .frame(width: 10, height: 10)
                            Text("RUNNING...")
                                .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                                .foregroundColor(.cyan)
                        }
                    } else if executionResult != nil || isResult {
                        HStack(spacing: 3) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 7.5))
                                .foregroundColor(.green)
                            Text("VERIFIED")
                                .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                                .foregroundColor(.green)
                        }
                    } else {
                        HStack(spacing: 3) {
                            Circle()
                                .fill(category.primaryColor)
                                .frame(width: 5, height: 5)
                                .scaleEffect(pulseScale)
                            Text("READY")
                                .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.55))
                        }
                    }
                }

                Text(toolName.uppercased())
                    .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }

            Spacer()

            // Action Buttons
            HStack(spacing: 5) {
                // Execute Tool Button
                if !isResult && executionResult == nil {
                    Button(action: executeInteractiveTool) {
                        HStack(spacing: 4) {
                            Image(systemName: isExecuting ? "rays" : "play.fill")
                                .font(.system(size: 8.5, weight: .bold))
                            Text(isExecuting ? "Executing" : "Run")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [category.primaryColor, category.secondaryColor],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .overlay(Capsule().strokeBorder(Color.white.opacity(0.35), lineWidth: 0.6))
                        .shadow(color: category.primaryColor.opacity(0.45), radius: 5, y: 1)
                    }
                    .buttonStyle(.plain)
                    .disabled(isExecuting)
                    .help("Execute this tool command immediately")
                }

                // Copy Payload
                Button(action: copyCommand) {
                    Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 9))
                        .foregroundColor(isCopied ? .green : .white.opacity(0.70))
                        .padding(5)
                        .background(Circle().fill(Color.white.opacity(0.08)))
                }
                .buttonStyle(.plain)
                .help("Copy tool command")

                // Code toggle
                Button(action: {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.82)) {
                        showRawCode.toggle()
                    }
                    HapticFeedback.selection()
                }) {
                    Image(systemName: showRawCode ? "sparkles" : "chevron.left.forwardslash.chevron.right")
                        .font(.system(size: 8.5))
                        .foregroundColor(.white.opacity(0.70))
                        .padding(5)
                        .background(Circle().fill(Color.white.opacity(0.08)))
                }
                .buttonStyle(.plain)
                .help(showRawCode ? "Switch to interactive HUD card" : "View raw code syntax")

                // Collapse/Expand
                Button(action: {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.82)) {
                        isExpanded.toggle()
                    }
                    HapticFeedback.selection()
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 8.5, weight: .bold))
                        .foregroundColor(.white.opacity(0.60))
                        .padding(5)
                        .background(Circle().fill(Color.white.opacity(0.08)))
                }
                .buttonStyle(.plain)
                .help(isExpanded ? "Collapse tool details" : "Expand tool details")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            ZStack {
                Color.white.opacity(0.04)

                // Laser scanline sweeping effect
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.clear, category.primaryColor.opacity(0.35), Color.clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 80, height: 2)
                    .offset(x: laserOffset)
                    .frame(maxWidth: .infinity, alignment: .bottom)
            }
        )
    }

    // MARK: - 📜 Body View
    private var cardBodyView: some View {
        VStack(alignment: .leading, spacing: 6) {
            if showRawCode {
                // Raw Syntax View
                VStack(alignment: .leading, spacing: 4) {
                    Text("```tool:\(toolName)")
                        .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                        .foregroundColor(category.primaryColor.opacity(0.85))

                    Text(commandText)
                        .font(.system(size: 10, weight: .regular, design: .monospaced))
                        .foregroundColor(.white.opacity(0.92))
                        .textSelection(.enabled)

                    Text("```")
                        .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                        .foregroundColor(category.primaryColor.opacity(0.85))
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.40))
                .cornerRadius(8)
            } else {
                // Interactive Argument Chips & Display
                let args = cleanArguments
                VStack(alignment: .leading, spacing: 6) {
                    // Argument summary pills
                    argumentChipsView(args: args)

                    // Full payload display
                    if args.contains("\n") || args.count > 60 {
                        ScrollView(.vertical, showsIndicators: true) {
                            Text(args)
                                .font(.system(size: 10.5, weight: .regular, design: .monospaced))
                                .foregroundColor(.white.opacity(0.90))
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .textSelection(.enabled)
                        }
                        .frame(maxHeight: 140)
                        .background(Color.black.opacity(0.32))
                        .cornerRadius(8)
                    } else if !args.isEmpty && args != toolName {
                        HStack(spacing: 6) {
                            Image(systemName: "terminal")
                                .font(.system(size: 9))
                                .foregroundColor(category.primaryColor)
                            Text(args)
                                .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                                .foregroundColor(.white)
                                .textSelection(.enabled)
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.black.opacity(0.28))
                        .cornerRadius(8)
                    }
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - 🏷️ Argument Chips View
    @ViewBuilder
    private func argumentChipsView(args: String) -> some View {
        let tokens = args.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        if !tokens.isEmpty && tokens.count <= 6 {
            HStack(spacing: 5) {
                ForEach(Array(tokens.prefix(5).enumerated()), id: \.offset) { idx, tok in
                    HStack(spacing: 3) {
                        if tok.hasPrefix("/") || tok.hasPrefix("~") {
                            Image(systemName: "folder.fill")
                                .font(.system(size: 7.5))
                                .foregroundColor(.cyan)
                        } else if Int(tok) != nil {
                            Image(systemName: "number")
                                .font(.system(size: 7.5))
                                .foregroundColor(.orange)
                        } else {
                            Image(systemName: "tag.fill")
                                .font(.system(size: 7))
                                .foregroundColor(category.secondaryColor)
                        }

                        Text(tok)
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.90))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.white.opacity(0.08)))
                    .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.5))
                }
            }
        }
    }

    // MARK: - 📋 Execution Result Drawer
    private func executionResultDrawer(result: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: "arrow.turn.down.right")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.green)
                Text("RESULT OUTPUT")
                    .font(.system(size: 8, weight: .heavy, design: .monospaced))
                    .foregroundColor(.green.opacity(0.90))
                Spacer()
            }
            .padding(.top, 4)

            ScrollView(.vertical, showsIndicators: true) {
                Text(result)
                    .font(.system(size: 9.5, weight: .regular, design: .monospaced))
                    .foregroundColor(.white.opacity(0.85))
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
            }
            .frame(maxHeight: 120)
            .background(Color.black.opacity(0.40))
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(Color.green.opacity(0.30), lineWidth: 0.6)
            )
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }

    // MARK: - 🚀 Actions
    private func executeInteractiveTool() {
        guard !isExecuting else { return }
        isExecuting = true
        HapticFeedback.success()

        Task {
            let parts = commandText.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: "\n")
            let firstLine = parts.first ?? ""
            let payload = parts.dropFirst().joined(separator: "\n")
            let output = await GenieNativeToolEngine.shared.executeTool(name: toolName, argument: firstLine, payload: payload)
            await MainActor.run {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                    self.executionResult = output
                    self.isExecuting = false
                }
                HapticFeedback.tick()
            }
        }
    }

    private func copyCommand() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString("```tool:\(toolName)\n\(commandText)\n```", forType: .string)
        HapticFeedback.selection()
        withAnimation(.easeInOut(duration: 0.2)) {
            isCopied = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.2)) {
                isCopied = false
            }
        }
    }
}
