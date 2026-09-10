import AppKit
import Foundation
import SwiftUI

// MARK: - 🧠 Chain-of-Thought / Deep Reasoning Accordion View
public struct GenieThinkingAccordionView: View {
    public let thinking: String
    public let isStreaming: Bool
    public let elapsedSeconds: Double?

    @State private var isExpanded: Bool = false
    @State private var pulseOpacity: Double = 0.5

    public init(thinking: String, isStreaming: Bool = false, elapsedSeconds: Double? = nil) {
        self.thinking = thinking
        self.isStreaming = isStreaming
        self.elapsedSeconds = elapsedSeconds
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button(action: {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                    isExpanded.toggle()
                }
                HapticFeedback.selection()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.purple, Color.cyan],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .opacity(isStreaming ? pulseOpacity : 1.0)

                    Text(isStreaming ? "Thinking Process..." : "Deep Thought")
                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))

                    if let elapsed = elapsedSeconds {
                        Text(String(format: "%.1fs", elapsed))
                            .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.45))
                    } else if isStreaming {
                        Circle()
                            .fill(Color.cyan)
                            .frame(width: 5, height: 5)
                            .opacity(pulseOpacity)
                    }

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 9.5, weight: .semibold))
                        .foregroundColor(.white.opacity(0.50))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(
                            isStreaming ? Color.cyan.opacity(0.40) : Color.white.opacity(0.10),
                            lineWidth: 0.75
                        )
                )
            }
            .buttonStyle(.plain)

            if isExpanded {
                ScrollView(.vertical, showsIndicators: true) {
                    Text(verbatim: thinking)
                        .font(.system(size: 10.5, weight: .regular, design: .monospaced))
                        .foregroundColor(.white.opacity(0.68))
                        .italic()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                }
                .frame(maxHeight: 180)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.black.opacity(0.35))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.purple.opacity(0.25), lineWidth: 0.6)
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .onAppear {
            if isStreaming {
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    pulseOpacity = 1.0
                }
            }
        }
    }
}

// MARK: - 📦 Interactive Code & Syntax Artifact Viewer
public struct GenieCodeArtifactView: View {
    public let language: String
    public let code: String
    public let title: String?

    @State private var isCopied: Bool = false
    @State private var isRunning: Bool = false
    @State private var runOutput: String? = nil

    public init(language: String, code: String, title: String? = nil) {
        self.language = language
        self.code = code
        self.title = title
    }

    private var lineCount: Int {
        code.components(separatedBy: "\n").count
    }

    private var languageIcon: String {
        let l = language.lowercased()
        if l == "swift" { return "swift" }
        if l == "bash" || l == "sh" || l == "zsh" { return "terminal.fill" }
        if l == "json" { return "curlybraces" }
        if l == "python" || l == "py" { return "chevron.left.forwardslash.chevron.right" }
        if l == "html" || l == "css" || l == "js" || l == "ts" { return "globe" }
        if l == "diff" { return "plus.slash.minus" }
        return "doc.text.fill"
    }

    private var canRunInTerminal: Bool {
        let l = language.lowercased()
        return l == "bash" || l == "sh" || l == "zsh"
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack(spacing: 6) {
                Image(systemName: languageIcon)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.cyan)

                Text(title ?? (language.isEmpty ? "CODE" : language.uppercased()))
                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.90))

                Text("(\(lineCount) \(lineCount == 1 ? "line" : "lines"))")
                    .font(.system(size: 8.5, weight: .regular, design: .monospaced))
                    .foregroundColor(.white.opacity(0.40))

                Spacer()

                if canRunInTerminal {
                    Button(action: {
                        runCodeCommand()
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: isRunning ? "hourglass" : "play.fill")
                                .font(.system(size: 8.5))
                            Text(isRunning ? "Running..." : "Run")
                                .font(.system(size: 9, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.green.opacity(0.90))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2.5)
                        .background(Capsule().fill(Color.green.opacity(0.15)))
                    }
                    .buttonStyle(.plain)
                    .disabled(isRunning)
                }

                Button(action: {
                    copyCode()
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundColor(isCopied ? .green : .white.opacity(0.70))
                        Text(isCopied ? "Copied!" : "Copy")
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundColor(isCopied ? .green : .white.opacity(0.70))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2.5)
                    .background(Capsule().fill(Color.white.opacity(0.08)))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(red: 0.08, green: 0.09, blue: 0.13))

            Divider().opacity(0.25)

            // Code Content
            ScrollView(.horizontal, showsIndicators: true) {
                Text(verbatim: code)
                    .font(.system(size: 10.5, weight: .regular, design: .monospaced))
                    .foregroundColor(Color(red: 0.88, green: 0.90, blue: 0.95))
                    .padding(10)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(red: 0.04, green: 0.05, blue: 0.08))

            if let out = runOutput {
                Divider().opacity(0.25)
                VStack(alignment: .leading, spacing: 3) {
                    Text("OUTPUT:")
                        .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                        .foregroundColor(.green.opacity(0.80))
                    Text(verbatim: out)
                        .font(.system(size: 9.5, weight: .regular, design: .monospaced))
                        .foregroundColor(.white.opacity(0.80))
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.black.opacity(0.50))
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.75)
        )
    }

    private func copyCode() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(code, forType: .string)
        HapticFeedback.success()
        withAnimation {
            isCopied = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isCopied = false
        }
    }

    private func runCodeCommand() {
        isRunning = true
        HapticFeedback.selection()
        Task { @MainActor in
            let (output, exitCode) = await LocalModelManager.shared.executeTerminalCommand(code)
            withAnimation {
                self.runOutput = output.isEmpty ? "(Exit Code \(exitCode))" : output
                self.isRunning = false
            }
        }
    }
}

// MARK: - 🚨 GitHub / Antigravity Style Alert Callout View
public struct GenieAlertCalloutView: View {
    public enum AlertType: String {
        case note = "NOTE"
        case tip = "TIP"
        case important = "IMPORTANT"
        case warning = "WARNING"
        case caution = "CAUTION"

        public var color: Color {
            switch self {
            case .note: return .blue
            case .tip: return .green
            case .important: return .purple
            case .warning: return .orange
            case .caution: return .red
            }
        }

        public var icon: String {
            switch self {
            case .note: return "info.circle.fill"
            case .tip: return "lightbulb.fill"
            case .important: return "exclamationmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .caution: return "flame.fill"
            }
        }
    }

    public let type: AlertType
    public let content: String

    public var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: type.icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(type.color)
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 3) {
                Text(type.rawValue)
                    .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                    .foregroundColor(type.color)

                Text(verbatim: content)
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.88))
            }
            Spacer()
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(type.color.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(type.color.opacity(0.30), lineWidth: 0.75)
        )
    }
}

// MARK: - 🌊 Liquid Streaming Cursor View
public struct GenieStreamingCursorView: View {
    @State private var isPulsing: Bool = false

    public init() {}

    public var body: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(Color.cyan)
            .frame(width: 2.5, height: 13)
            .shadow(color: Color.cyan.opacity(0.8), radius: 3)
            .opacity(isPulsing ? 1.0 : 0.2)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
    }
}


// MARK: - 📝 Rich Markdown Segment Parser & Renderer
public struct GenieMarkdownMessageView: View {
    public let text: String
    public let isStreaming: Bool

    public init(text: String, isStreaming: Bool = false) {
        self.text = text
        self.isStreaming = isStreaming
    }

    private struct ContentSegment: Identifiable {
        let id = UUID()
        enum Kind {
            case regular(String)
            case codeBlock(lang: String, code: String)
            case thinking(String)
            case alert(type: GenieAlertCalloutView.AlertType, content: String)
        }
        let kind: Kind
    }

    private var parsedSegments: [ContentSegment] {
        var segments: [ContentSegment] = []
        var remaining = text

        // 1. Extract thinking block <thought>...</thought> if present
        if let startTag = remaining.range(of: "<thought>"),
           let endTag = remaining.range(of: "</thought>", range: startTag.upperBound..<remaining.endIndex) {
            let before = String(remaining[..<startTag.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !before.isEmpty {
                segments.append(contentsOf: parseCodeAndText(before))
            }
            let thinkContent = String(remaining[startTag.upperBound..<endTag.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !thinkContent.isEmpty {
                segments.append(ContentSegment(kind: .thinking(thinkContent)))
            }
            remaining = String(remaining[endTag.upperBound...])
        }

        segments.append(contentsOf: parseCodeAndText(remaining))
        return segments
    }

    private func parseCodeAndText(_ raw: String) -> [ContentSegment] {
        var segs: [ContentSegment] = []
        var cur = raw

        while let codeStart = cur.range(of: "```") {
            let textBefore = String(cur[..<codeStart.lowerBound])
            if !textBefore.isEmpty {
                segs.append(contentsOf: parseAlertsAndText(textBefore))
            }

            let afterStart = cur[codeStart.upperBound...]
            if let lineBreak = afterStart.range(of: "\n") {
                let lang = String(afterStart[..<lineBreak.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                let codeBodyAfter = afterStart[lineBreak.upperBound...]

                if let codeEnd = codeBodyAfter.range(of: "```") {
                    let code = String(codeBodyAfter[..<codeEnd.lowerBound])
                    segs.append(ContentSegment(kind: .codeBlock(lang: lang, code: code)))
                    cur = String(codeBodyAfter[codeEnd.upperBound...])
                } else {
                    // Streaming unclosed code block
                    let code = String(codeBodyAfter)
                    segs.append(ContentSegment(kind: .codeBlock(lang: lang, code: code)))
                    cur = ""
                    break
                }
            } else {
                cur = ""
                break
            }
        }

        if !cur.isEmpty {
            segs.append(contentsOf: parseAlertsAndText(cur))
        }

        return segs
    }

    private func parseAlertsAndText(_ raw: String) -> [ContentSegment] {
        var segs: [ContentSegment] = []
        let lines = raw.components(separatedBy: "\n")
        var regularBuffer: [String] = []

        var i = 0
        while i < lines.count {
            let line = lines[i]
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            var matchedAlert: GenieAlertCalloutView.AlertType? = nil
            if trimmed.hasPrefix("> [!NOTE]") { matchedAlert = .note }
            else if trimmed.hasPrefix("> [!TIP]") { matchedAlert = .tip }
            else if trimmed.hasPrefix("> [!IMPORTANT]") { matchedAlert = .important }
            else if trimmed.hasPrefix("> [!WARNING]") { matchedAlert = .warning }
            else if trimmed.hasPrefix("> [!CAUTION]") { matchedAlert = .caution }

            if let alertType = matchedAlert {
                if !regularBuffer.isEmpty {
                    segs.append(ContentSegment(kind: .regular(regularBuffer.joined(separator: "\n"))))
                    regularBuffer.removeAll()
                }

                var alertLines: [String] = []
                i += 1
                while i < lines.count {
                    let subLine = lines[i]
                    let subTrimmed = subLine.trimmingCharacters(in: .whitespaces)
                    if subTrimmed.hasPrefix(">") {
                        let stripped = subTrimmed.dropFirst().trimmingCharacters(in: .whitespaces)
                        alertLines.append(String(stripped))
                        i += 1
                    } else {
                        break
                    }
                }
                segs.append(ContentSegment(kind: .alert(type: alertType, content: alertLines.joined(separator: "\n"))))
            } else {
                regularBuffer.append(line)
                i += 1
            }
        }

        if !regularBuffer.isEmpty {
            let chunk = regularBuffer.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            if !chunk.isEmpty {
                segs.append(ContentSegment(kind: .regular(chunk)))
            }
        }

        return segs
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(parsedSegments) { segment in
                switch segment.kind {
                case .regular(let txt):
                    Text(LocalizedStringKey(txt))
                        .font(.system(size: 11.5, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.92))
                        .textSelection(.enabled)
                        .lineSpacing(3)

                case .codeBlock(let lang, let code):
                    GenieCodeArtifactView(language: lang, code: code)

                case .thinking(let think):
                    GenieThinkingAccordionView(thinking: think)

                case .alert(let type, let content):
                    GenieAlertCalloutView(type: type, content: content)
                }
            }

            if isStreaming {
                GenieStreamingCursorView()
            }
        }
    }
}

// MARK: - ⌨️ Quick Slash Commands Action Bar
public struct GenieSlashCommandsBarView: View {
    public let onCommandSelected: (String) -> Void

    public static let commands: [(cmd: String, title: String, icon: String, color: Color)] = [
        ("/goal", "Goal", "target", .cyan),
        ("/swarm", "Swarm Codebase", "ant.fill", .purple),
        ("/notes", "Desktop Notes", "note.text", .orange),
        ("/code", "Generate Code", "chevron.left.forwardslash.chevron.right", .green),
        ("/spaces", "Desktop Spaces", "square.3.layers.3d.down.right", .cyan),
        ("/recent", "Latest Creations", "sparkles", .yellow),
        ("/clear", "Clear Chat", "trash.fill", .red)
    ]

    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(Self.commands, id: \.cmd) { item in
                    Button(action: {
                        HapticFeedback.selection()
                        onCommandSelected(item.cmd)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: item.icon)
                                .font(.system(size: 9))
                                .foregroundColor(item.color)
                            Text(item.cmd)
                                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.90))
                            Text(item.title)
                                .font(.system(size: 9, weight: .regular, design: .rounded))
                                .foregroundColor(.white.opacity(0.55))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3.5)
                        .background(Capsule().fill(Color.white.opacity(0.08)))
                        .overlay(Capsule().stroke(item.color.opacity(0.35), lineWidth: 0.6))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
        }
    }
}
