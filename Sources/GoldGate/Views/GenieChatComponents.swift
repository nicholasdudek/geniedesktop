import AppKit
import Foundation
import SwiftUI
import WebKit

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

                    Button(action: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(thinking, forType: .string)
                        HapticFeedback.success()
                    }) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 8.5))
                            .foregroundColor(.white.opacity(0.45))
                    }
                    .buttonStyle(.plain)
                    .help("Copy Thinking Process")

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
                        .textSelection(.enabled)
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

                // 🪟 Open in Split Window Button
                Button(action: {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("NexusAIDisplayCreation"),
                        object: code,
                        userInfo: ["title": title ?? "\(language.isEmpty ? "Code" : language.uppercased()) Artifact"]
                    )
                    HapticFeedback.selection()
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "rectangle.split.2x1.fill")
                            .font(.system(size: 8.5))
                        Text("Split View")
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2.5)
                    .background(Capsule().fill(Color.cyan.opacity(0.18)))
                    .overlay(Capsule().strokeBorder(Color.cyan.opacity(0.40), lineWidth: 0.5))
                }
                .buttonStyle(.plain)
                .help("Open Artifact in Split Window Pane")

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
                    .textSelection(.enabled)
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
            case toolCommand(toolName: String, rawCommand: String)
            case toolResult(toolName: String, result: String)
            case thinking(String)
            case alert(type: GenieAlertCalloutView.AlertType, content: String)
            case inlineImage(alt: String, pathOrURL: String)
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
            var textBefore = String(cur[..<codeStart.lowerBound])
            var activeToolResultName: String? = nil

            // Check if textBefore contains tool result header: 🛠️ **[Genie Native Tool: `<toolName>`]**
            if let markerRange = textBefore.range(of: "🛠️ **[Genie Native Tool: `") {
                let afterMarker = textBefore[markerRange.upperBound...]
                if let endTick = afterMarker.range(of: "`]") {
                    activeToolResultName = String(afterMarker[..<endTick.lowerBound])
                    // Clean marker from textBefore
                    textBefore = String(textBefore[..<markerRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }

            if !textBefore.isEmpty {
                segs.append(contentsOf: parseAlertsAndText(textBefore))
            }

            let afterStart = cur[codeStart.upperBound...]
            if let lineBreak = afterStart.range(of: "\n") {
                let lang = String(afterStart[..<lineBreak.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                let codeBodyAfter = afterStart[lineBreak.upperBound...]

                if let codeEnd = codeBodyAfter.range(of: "```") {
                    let code = String(codeBodyAfter[..<codeEnd.lowerBound])
                    if let toolName = activeToolResultName {
                        segs.append(ContentSegment(kind: .toolResult(toolName: toolName, result: code)))
                    } else if lang.lowercased().hasPrefix("tool:") {
                        let toolName = String(lang.dropFirst(5)).trimmingCharacters(in: .whitespacesAndNewlines)
                        segs.append(ContentSegment(kind: .toolCommand(toolName: toolName.isEmpty ? "engine" : toolName, rawCommand: code)))
                    } else if lang.lowercased() == "tool" || lang.lowercased().hasPrefix("tool ") {
                        let toolName = String(lang.dropFirst(4)).trimmingCharacters(in: .whitespacesAndNewlines)
                        segs.append(ContentSegment(kind: .toolCommand(toolName: toolName.isEmpty ? "engine" : toolName, rawCommand: code)))
                    } else {
                        segs.append(ContentSegment(kind: .codeBlock(lang: lang, code: code)))
                    }
                    cur = String(codeBodyAfter[codeEnd.upperBound...])
                } else {
                    // Streaming unclosed code block
                    let code = String(codeBodyAfter)
                    if let toolName = activeToolResultName {
                        segs.append(ContentSegment(kind: .toolResult(toolName: toolName, result: code)))
                    } else if lang.lowercased().hasPrefix("tool:") {
                        let toolName = String(lang.dropFirst(5)).trimmingCharacters(in: .whitespacesAndNewlines)
                        segs.append(ContentSegment(kind: .toolCommand(toolName: toolName.isEmpty ? "engine" : toolName, rawCommand: code)))
                    } else if lang.lowercased() == "tool" || lang.lowercased().hasPrefix("tool ") {
                        let toolName = String(lang.dropFirst(4)).trimmingCharacters(in: .whitespacesAndNewlines)
                        segs.append(ContentSegment(kind: .toolCommand(toolName: toolName.isEmpty ? "engine" : toolName, rawCommand: code)))
                    } else {
                        segs.append(ContentSegment(kind: .codeBlock(lang: lang, code: code)))
                    }
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
                segs.append(contentsOf: parseImagesAndText(chunk))
            }
        }

        return segs
    }

    // MARK: - Image & Screenshot Path Resolver
    public static func resolveImageFilePathOrURL(_ raw: String) -> URL? {
        var p = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if p.isEmpty { return nil }

        // Web URL
        if p.hasPrefix("http://") || p.hasPrefix("https://") {
            return URL(string: p)
        }

        // file:// scheme
        if p.hasPrefix("file://") {
            if let direct = URL(string: p), FileManager.default.fileExists(atPath: direct.path) {
                return direct
            }
            p = String(p.dropFirst(7))
        }

        // Strip enclosing quotes if present
        if (p.hasPrefix("\"") && p.hasSuffix("\"")) || (p.hasPrefix("'") && p.hasSuffix("'")) {
            p = String(p.dropFirst().dropLast())
        }

        // Unescape backslash-escaped spaces (e.g. Screenshot\ 2026...)
        p = p.replacingOccurrences(of: "\\ ", with: " ")

        // Expand tilde path
        if p.hasPrefix("~") {
            p = NSString(string: p).expandingTildeInPath
        }

        // Candidate 1: Direct path
        if FileManager.default.fileExists(atPath: p) {
            return URL(fileURLWithPath: p)
        }

        // Candidate 2: Replace narrow no-break space "\u{202F}" with standard space
        let normSpaces = p.replacingOccurrences(of: "\u{202F}", with: " ")
        if FileManager.default.fileExists(atPath: normSpaces) {
            return URL(fileURLWithPath: normSpaces)
        }

        // Candidate 3: macOS screencaptureui narrow spaces before AM/PM
        let narrowAM = p.replacingOccurrences(of: " AM.", with: "\u{202F}AM.")
                        .replacingOccurrences(of: " PM.", with: "\u{202F}PM.")
        if FileManager.default.fileExists(atPath: narrowAM) {
            return URL(fileURLWithPath: narrowAM)
        }

        // Candidate 4: Percent-decoded path
        if let decoded = p.removingPercentEncoding, FileManager.default.fileExists(atPath: decoded) {
            return URL(fileURLWithPath: decoded)
        }

        // Fallback: If path has an image extension and starts with / or ~, return URL
        let ext = (p as NSString).pathExtension.lowercased()
        let imageExts: Set<String> = ["png", "jpg", "jpeg", "gif", "webp", "heic", "tiff", "bmp", "svg"]
        if (p.hasPrefix("/") || p.hasPrefix("~")) && imageExts.contains(ext) {
            return URL(fileURLWithPath: p)
        }

        return nil
    }

    private func parseImagesAndText(_ raw: String) -> [ContentSegment] {
        var segs: [ContentSegment] = []
        // 1. Match ![alt](pathOrUrl) markdown image syntax
        let imgPattern = #"!\[([^\]]*)\]\(([^)]+)\)"#
        if let regex = try? NSRegularExpression(pattern: imgPattern, options: []) {
            let nsString = raw as NSString
            let matches = regex.matches(in: raw, options: [], range: NSRange(location: 0, length: nsString.length))
            if !matches.isEmpty {
                var lastIndex = 0
                for match in matches {
                    let beforeRange = NSRange(location: lastIndex, length: match.range.location - lastIndex)
                    if beforeRange.length > 0 {
                        let beforeText = nsString.substring(with: beforeRange).trimmingCharacters(in: .whitespacesAndNewlines)
                        if !beforeText.isEmpty {
                            segs.append(contentsOf: parseRawFilePathsAndText(beforeText))
                        }
                    }

                    let alt = nsString.substring(with: match.range(at: 1))
                    let pathOrURL = nsString.substring(with: match.range(at: 2)).trimmingCharacters(in: .whitespacesAndNewlines)
                    segs.append(ContentSegment(kind: .inlineImage(alt: alt, pathOrURL: pathOrURL)))

                    lastIndex = match.range.location + match.range.length
                }

                if lastIndex < nsString.length {
                    let remainingText = nsString.substring(from: lastIndex).trimmingCharacters(in: .whitespacesAndNewlines)
                    if !remainingText.isEmpty {
                        segs.append(contentsOf: parseRawFilePathsAndText(remainingText))
                    }
                }
                return segs
            }
        }

        // 2. If no markdown images found, parse raw file paths and screenshots in the text
        return parseRawFilePathsAndText(raw)
    }

    private func parseRawFilePathsAndText(_ input: String) -> [ContentSegment] {
        var segs: [ContentSegment] = []

        // Match raw screenshot / image paths (e.g. /var/folders/.../Screenshot...png, ~/Desktop/...jpg, etc.)
        let rawPathPattern = #"((?:/(?:[^/\n\r]+(?:\\ )*)+|\~/(?:[^/\n\r]+(?:\\ )*)+|file://(?:[^/\n\r]+(?:\\ )*)+)\.(?:png|jpg|jpeg|gif|webp|heic|tiff|bmp|svg))"#

        guard let regex = try? NSRegularExpression(pattern: rawPathPattern, options: [.caseInsensitive]) else {
            segs.append(ContentSegment(kind: .regular(input)))
            return segs
        }

        let nsString = input as NSString
        let matches = regex.matches(in: input, options: [], range: NSRange(location: 0, length: nsString.length))
        guard !matches.isEmpty else {
            segs.append(ContentSegment(kind: .regular(input)))
            return segs
        }

        var lastIndex = 0
        for match in matches {
            let beforeRange = NSRange(location: lastIndex, length: match.range.location - lastIndex)
            if beforeRange.length > 0 {
                let beforeText = nsString.substring(with: beforeRange)
                if !beforeText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    segs.append(ContentSegment(kind: .regular(beforeText)))
                }
            }

            let matchedPath = nsString.substring(with: match.range(at: 1))
            let filename = (matchedPath.replacingOccurrences(of: "\\ ", with: " ") as NSString).lastPathComponent
            segs.append(ContentSegment(kind: .inlineImage(alt: filename, pathOrURL: matchedPath)))

            lastIndex = match.range.location + match.range.length
        }

        if lastIndex < nsString.length {
            let remainingText = nsString.substring(from: lastIndex)
            if !remainingText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                segs.append(ContentSegment(kind: .regular(remainingText)))
            }
        }

        return segs
    }

    private func convertRawURLsToMarkdownLinks(_ input: String) -> String {
        // Only convert URLs that have a valid domain and TLD, avoiding dummy or unopenable links
        let pattern = "(?<!\\]\\()(https?://[a-zA-Z0-9\\-_]+(?:\\.[a-zA-Z0-9\\-_]+)+[a-zA-Z0-9\\.\\-_~:/?#@!$&'()*+,;=%]*[a-zA-Z0-9/])"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else {
            return input
        }
        let range = NSRange(input.startIndex..<input.endIndex, in: input)
        return regex.stringByReplacingMatches(in: input, options: [], range: range, withTemplate: "[$1]($1)")
    }

    private func extractURLs(from input: String) -> [URL] {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else { return [] }
        let matches = detector.matches(in: input, options: [], range: NSRange(location: 0, length: input.utf16.count))
        return matches.compactMap { match in
            guard let url = match.url else { return nil }
            // Only show URLs that have http/https and a valid host with a dot
            guard let scheme = url.scheme?.lowercased(), (scheme == "http" || scheme == "https") else { return nil }
            guard let host = url.host?.lowercased(), host.contains("."), !host.hasPrefix("."), !host.hasSuffix(".") else { return nil }
            // Filter out dummy/hallucinated placeholders like example.invalid, topic, system
            if host == "topic" || host == "system" || host.hasSuffix(".local") || host.hasSuffix(".invalid") {
                return nil
            }
            return url
        }
    }

    private func openWebURL(_ url: URL) {
        FinderChatWindowManager.shared.openTab(.browser)
        NotificationCenter.default.post(name: NSNotification.Name("GenieNavigateMiniBrowser"), object: url)
        HapticFeedback.selection()
    }

    /// Routes visual generation blocks (SVG, Canvas, Mermaid, Metal, GLSL, Python, Swift, LaTeX, ASCII, HTML)
    /// to the inline live preview bubble with its exact language tab; all others to the code artifact viewer.
    @ViewBuilder
    private func codeBlockView(lang: String, code: String) -> some View {
        if let visualType = GenieUniversalVisualGenerator.detectVisualLanguage(lang: lang, code: code) {
            GenieInlineHtmlBubble(
                code: code,
                language: visualType,
                onResubmit: { editedCode in
                    NotificationCenter.default.post(
                        name: NSNotification.Name("GenieSetChatPromptText"),
                        object: "Here is my edited \(visualType.tabLabel) code — please refine it further:\n```\(lang)\n\(editedCode)\n```"
                    )
                },
                onOpenSafari: { html in
                    let ext = visualType == .svg ? "svg" : "html"
                    let tmp = FileManager.default.temporaryDirectory
                        .appendingPathComponent("GenieVisualPreview.\(ext)")
                    try? html.write(to: tmp, atomically: true, encoding: .utf8)
                    if let safariURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Safari") {
                        NSWorkspace.shared.open([tmp], withApplicationAt: safariURL, configuration: NSWorkspace.OpenConfiguration())
                    } else {
                        NSWorkspace.shared.open(tmp)
                    }
                }
            )
        } else {
            GenieCodeArtifactView(language: lang, code: code)
        }
    }

    /// Ensures any code block is wrapped in a valid, self-contained HTML document for WKWebView.
    private func wrapCodeAsHtml(lang: String, code: String) -> String {
        let detected = GenieUniversalVisualGenerator.detectVisualLanguage(lang: lang, code: code) ?? .genericHtml
        return GenieUniversalVisualGenerator.wrapVisualAsHtml(type: detected, code: code, theme: .dark)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ForEach(parsedSegments) { segment in
                switch segment.kind {
                case .regular(let txt):
                    VStack(alignment: .leading, spacing: 4) {
                        Text(LocalizedStringKey(convertRawURLsToMarkdownLinks(txt)))
                            .font(.system(size: GenieSystemAppearanceDetector.shared.scaledPoint(11.5), weight: .regular, design: .rounded))
                            .foregroundColor(.white.opacity(0.92))
                            .textSelection(.enabled)
                            .lineSpacing(3)

                        let urls = extractURLs(from: txt)
                        if !urls.isEmpty {
                            HStack(spacing: 6) {
                                ForEach(urls, id: \.self) { url in
                                    Button(action: {
                                        openWebURL(url)
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "safari.fill")
                                                .font(.system(size: 9))
                                            Text(url.host ?? url.absoluteString)
                                                .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                                                .lineLimit(1)
                                        }
                                        .foregroundColor(.cyan)
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 3)
                                        .background(Capsule().fill(Color.cyan.opacity(0.12)))
                                        .overlay(Capsule().stroke(Color.cyan.opacity(0.35), lineWidth: 0.6))
                                    }
                                    .buttonStyle(.plain)
                                    .help("Open \(url.absoluteString) in Mini Browser")
                                }
                            }
                            .padding(.top, 2)
                        }
                    }

                case .codeBlock(let lang, let code):
                    codeBlockView(lang: lang, code: code)

                case .toolCommand(let toolName, let rawCommand):
                    GenieToolCommandAnimatedView(toolName: toolName, commandText: rawCommand)
                        .padding(.vertical, 3)

                case .toolResult(let toolName, let result):
                    GenieToolCommandAnimatedView(toolName: toolName, commandText: result, isResult: true)
                        .padding(.vertical, 3)

                case .thinking(let think):
                    GenieThinkingAccordionView(thinking: think)

                case .alert(let type, let content):
                    GenieAlertCalloutView(type: type, content: content)

                case .inlineImage(let alt, let pathOrURL):
                    let resolvedURL = Self.resolveImageFilePathOrURL(pathOrURL)
                    GenieImageCardView(url: resolvedURL, altText: alt.isEmpty ? nil : alt, maxDisplayHeight: 280)
                        .padding(.vertical, 3)
                }
            }

            if isStreaming {
                GenieStreamingCursorView()
            }
        }
        .environment(\.openURL, OpenURLAction { url in
            NSWorkspace.shared.open(url)
            return .handled
        })
        .contextMenu {
            Button(action: {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(text, forType: .string)
                HapticFeedback.success()
            }) {
                Label("Copy Message", systemImage: "doc.on.doc")
            }

            let allURLs = extractURLs(from: text)
            if let first = allURLs.first {
                Button(action: {
                    NSWorkspace.shared.open(first)
                    HapticFeedback.selection()
                }) {
                    Label("Open in Browser", systemImage: "safari")
                }
                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(first.absoluteString, forType: .string)
                    HapticFeedback.success()
                }) {
                    Label("Copy Link", systemImage: "link")
                }
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

// MARK: - 🌐 Inline HTML / SVG Preview Bubble (render HTML right inside the chat message)
// MARK: - 📸 Web View Snapshot Controller
@MainActor
public final class GenieWebSnapshotController: ObservableObject {
    public weak var webView: WKWebView?
    public init() {}
    public func takeSnapshot(completion: @escaping (NSImage?) -> Void) {
        guard let wv = webView else {
            completion(nil)
            return
        }
        wv.takeSnapshot(with: nil) { image, _ in
            completion(image)
        }
    }
}

// MARK: - 🌐 Inline Visual Image Bubble & Language Code Inspector
/// Drop this directly below any AI message that contains visual generation code
/// (SVG, Canvas, Mermaid, Metal, GLSL, Python, Swift, LaTeX, ASCII, HTML).
/// Shows an interactive rendered visual preview, an exact language code tab, theme switcher, and export actions.
public struct GenieInlineHtmlBubble: View {

    public enum PreviewTab { case preview, source }

    public let originalCode: String
    public let language: VisualLanguageType
    /// Called when the user edits the source and taps "Re-send to Genie"
    public var onResubmit: ((String) -> Void)?
    /// Called when the user taps "Run in Safari"
    public var onOpenSafari: ((String) -> Void)?

    @State private var activeTab: PreviewTab = .preview
    @State private var editableSource: String
    @State private var canvasTheme: VisualBackgroundTheme = .dark
    @State private var isCopiedCode: Bool = false
    @State private var isCopiedImage: Bool = false
    @State private var savedNotice: String? = nil
    @State private var previewHeight: CGFloat = 280
    @StateObject private var snapshotController = GenieWebSnapshotController()

    /// Backward-compatible initializer for existing callers passing HTML directly
    public init(
        html: String,
        onResubmit: ((String) -> Void)? = nil,
        onOpenSafari: ((String) -> Void)? = nil
    ) {
        let detected = GenieUniversalVisualGenerator.detectVisualLanguage(lang: "html", code: html) ?? .genericHtml
        self.init(code: html, language: detected, onResubmit: onResubmit, onOpenSafari: onOpenSafari)
    }

    public init(
        code: String,
        language: VisualLanguageType = .genericHtml,
        onResubmit: ((String) -> Void)? = nil,
        onOpenSafari: ((String) -> Void)? = nil
    ) {
        self.originalCode = code
        self.language = language
        self._editableSource = State(initialValue: code)
        self.onResubmit = onResubmit
        self.onOpenSafari = onOpenSafari
    }

    private var activeCode: String {
        activeTab == .source ? editableSource : originalCode
    }

    private var renderedHtml: String {
        GenieUniversalVisualGenerator.wrapVisualAsHtml(type: language, code: activeCode, theme: canvasTheme)
    }

    public var body: some View {
        VStack(spacing: 0) {
            // ── Header bar ──────────────────────────────────────────────────
            HStack(spacing: 6) {
                // Tab picker: Rendered Image Preview vs Exact Language Tab
                HStack(spacing: 0) {
                    tabPill(
                        label: "Image Preview",
                        icon: "photo.artframe",
                        tab: .preview
                    )
                    tabPill(
                        label: language.tabLabel,
                        icon: language.iconName,
                        tab: .source,
                        accentColor: language.accentColor
                    )
                }
                .background(Capsule().fill(Color.white.opacity(0.07)))
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.14), lineWidth: 0.6))

                if let notice = savedNotice {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.green)
                        Text(notice)
                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.95))
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.black.opacity(0.70)))
                    .overlay(Capsule().strokeBorder(Color.green.opacity(0.40), lineWidth: 0.6))
                    .transition(.opacity.combined(with: .scale))
                }

                Spacer()

                // Action buttons
                HStack(spacing: 5) {
                    if activeTab == .source {
                        // Re-send edited code to Genie
                        Button(action: {
                            onResubmit?(editableSource)
                            HapticFeedback.selection()
                        }) {
                            HStack(spacing: 3) {
                                Image(systemName: "arrow.up.circle.fill")
                                    .font(.system(size: 9, weight: .bold))
                                Text("Re-send to Genie")
                                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(.cyan)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.cyan.opacity(0.18)))
                            .overlay(Capsule().strokeBorder(Color.cyan.opacity(0.45), lineWidth: 0.6))
                        }
                        .buttonStyle(.plain)
                        .help("Edit the \(language.tabLabel) code and send it back to Genie for iteration")

                        // Copy Source Code
                        Button(action: {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(editableSource, forType: .string)
                            HapticFeedback.success()
                            isCopiedCode = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { isCopiedCode = false }
                        }) {
                            HStack(spacing: 3) {
                                Image(systemName: isCopiedCode ? "checkmark" : "doc.on.doc")
                                    .font(.system(size: 9, weight: .bold))
                                Text(isCopiedCode ? "Copied" : "Copy Code")
                                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(isCopiedCode ? .green : .white.opacity(0.85))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.white.opacity(0.09)))
                        }
                        .buttonStyle(.plain)
                        .help("Copy \(language.tabLabel) Source Code")

                    } else {
                        // Canvas Background Theme Switcher
                        Button(action: {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                switch canvasTheme {
                                case .dark: canvasTheme = .light
                                case .light: canvasTheme = .checkerboard
                                case .checkerboard: canvasTheme = .dark
                                }
                            }
                            HapticFeedback.tick()
                        }) {
                            HStack(spacing: 3) {
                                Image(systemName: canvasTheme.icon)
                                    .font(.system(size: 9))
                                Text(canvasTheme.rawValue)
                                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(.white.opacity(0.80))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.white.opacity(0.08)))
                            .overlay(Capsule().strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5))
                        }
                        .buttonStyle(.plain)
                        .help("Canvas Background: \(canvasTheme.rawValue) (Click to cycle Dark / Light / Grid)")

                        // Copy Rendered Image to Clipboard
                        Button(action: {
                            snapshotController.takeSnapshot { image in
                                guard let image = image else { return }
                                GenieUniversalVisualGenerator.copyImageToClipboard(image)
                                HapticFeedback.success()
                                isCopiedImage = true
                                savedNotice = "Copied Image! 📋"
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
                                    isCopiedImage = false
                                    savedNotice = nil
                                }
                            }
                        }) {
                            HStack(spacing: 3) {
                                Image(systemName: isCopiedImage ? "checkmark" : "photo.on.rectangle.angled")
                                    .font(.system(size: 9, weight: .semibold))
                                Text(isCopiedImage ? "Copied" : "Copy Image")
                                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(isCopiedImage ? .green : .white.opacity(0.85))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.white.opacity(0.09)))
                        }
                        .buttonStyle(.plain)
                        .help("Copy rendered image to clipboard")

                        // Save Image to Desktop
                        Button(action: {
                            snapshotController.takeSnapshot { image in
                                guard let image = image else { return }
                                let formatter = DateFormatter()
                                formatter.dateFormat = "yyyy-MM-dd_HHmmss"
                                let name = "Genie_\(language.tabLabel.replacingOccurrences(of: " ", with: "_"))_\(formatter.string(from: Date())).png"
                                if let _ = GenieUniversalVisualGenerator.saveImageToDesktop(image: image, customName: name) {
                                    HapticFeedback.success()
                                    savedNotice = "Saved to Desktop! 📸"
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                        savedNotice = nil
                                    }
                                }
                            }
                        }) {
                            HStack(spacing: 3) {
                                Image(systemName: "arrow.down.to.line")
                                    .font(.system(size: 9, weight: .bold))
                                Text("Save")
                                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(.cyan)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.cyan.opacity(0.18)))
                            .overlay(Capsule().strokeBorder(Color.cyan.opacity(0.40), lineWidth: 0.6))
                        }
                        .buttonStyle(.plain)
                        .help("Save rendered image to Desktop as PNG")
                    }

                    // Safari
                    Button(action: {
                        onOpenSafari?(renderedHtml)
                        HapticFeedback.selection()
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "safari")
                                .font(.system(size: 9))
                            Text("Safari")
                                .font(.system(size: 9, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.cyan)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.cyan.opacity(0.14)))
                        .overlay(Capsule().strokeBorder(Color.cyan.opacity(0.35), lineWidth: 0.6))
                    }
                    .buttonStyle(.plain)
                    .help("Open in Safari")

                    // Height toggle
                    Button(action: {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                            previewHeight = previewHeight < 400 ? 480 : 280
                        }
                        HapticFeedback.selection()
                    }) {
                        Image(systemName: previewHeight < 400 ? "arrow.up.left.and.arrow.down.right" : "arrow.down.right.and.arrow.up.left")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.white.opacity(0.60))
                            .frame(width: 22, height: 22)
                            .background(Circle().fill(Color.white.opacity(0.08)))
                    }
                    .buttonStyle(.plain)
                    .help(previewHeight < 400 ? "Expand preview" : "Compact preview")
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.35))

            Divider().opacity(0.20)

            // ── Content area ─────────────────────────────────────────────────
            if activeTab == .preview {
                GenieInlineWebView(
                    htmlString: renderedHtml,
                    snapshotController: snapshotController
                )
                .frame(height: previewHeight)
                .transition(.opacity)
            } else {
                ScrollView([.vertical, .horizontal], showsIndicators: true) {
                    TextEditor(text: $editableSource)
                        .font(.system(size: 10, weight: .regular, design: .monospaced))
                        .foregroundColor(Color(red: 0.88, green: 0.90, blue: 0.95))
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: previewHeight)
                .background(Color(red: 0.04, green: 0.05, blue: 0.08))
                .transition(.opacity)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.75)
        )
        .shadow(color: Color.black.opacity(0.35), radius: 8, y: 3)
    }

    @ViewBuilder
    private func tabPill(
        label: String,
        icon: String,
        tab: PreviewTab,
        accentColor: Color? = nil
    ) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) { activeTab = tab }
            HapticFeedback.tick()
        }) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 8.5, weight: .semibold))
                    .foregroundColor(activeTab == tab ? (accentColor ?? .black) : .white.opacity(0.70))

                Text(label)
                    .font(.system(size: 9.5, weight: activeTab == tab ? .bold : .medium, design: .rounded))
                    .foregroundColor(activeTab == tab ? .black : .white.opacity(0.75))

                if let accent = accentColor, activeTab != tab {
                    Circle()
                        .fill(accent)
                        .frame(width: 4, height: 4)
                }
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(activeTab == tab ? Capsule().fill(Color.white) : Capsule().fill(Color.clear))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - 🖥️ Lightweight inline WKWebView (NSViewRepresentable)
public struct GenieInlineWebView: NSViewRepresentable {
    public let htmlString: String
    public var snapshotController: GenieWebSnapshotController? = nil

    public func makeCoordinator() -> Coordinator { Coordinator() }

    public final class Coordinator {
        weak var webView: WKWebView?
        var lastHtml: String = ""
        var isInitialLoaded: Bool = false
    }

    public func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        let wv = WKWebView(frame: .zero, configuration: config)
        wv.setValue(false, forKey: "drawsBackground")
        context.coordinator.webView = wv
        snapshotController?.webView = wv

        let balanced = StreamingHTMLTagBalancer.balance(htmlString)
        context.coordinator.lastHtml = balanced
        context.coordinator.isInitialLoaded = true
        let baseURL = GenieWebAssetResolver.webBaseURL
        wv.loadHTMLString(balanced.isEmpty ? "<!DOCTYPE html><html><body style='background:transparent;'></body></html>" : balanced, baseURL: baseURL)
        return wv
    }

    public func updateNSView(_ nsView: WKWebView, context: Context) {
        context.coordinator.webView = nsView
        snapshotController?.webView = nsView

        let balanced = StreamingHTMLTagBalancer.balance(htmlString)
        guard !balanced.isEmpty else { return }
        guard context.coordinator.lastHtml != balanced else { return }
        context.coordinator.lastHtml = balanced
        let baseURL = GenieWebAssetResolver.webBaseURL

        if context.coordinator.isInitialLoaded {
            if let data = try? JSONSerialization.data(withJSONObject: [balanced]),
               let jsonArray = String(data: data, encoding: .utf8) {
                let js = """
                (() => {
                    try {
                        const html = (\(jsonArray))[0];
                        document.open();
                        document.write(html);
                        document.close();
                    } catch (e) {
                        console.error("Live inline HTML update failed:", e);
                        throw e;
                    }
                })();
                """
                nsView.evaluateJavaScript(js) { _, err in
                    if err != nil {
                        nsView.loadHTMLString(balanced, baseURL: baseURL)
                    }
                }
            } else {
                nsView.loadHTMLString(balanced, baseURL: baseURL)
            }
        } else {
            context.coordinator.isInitialLoaded = true
            nsView.loadHTMLString(balanced, baseURL: baseURL)
        }
    }

    public static func dismantleNSView(_ nsView: WKWebView, coordinator: Coordinator) {
        nsView.stopLoading()
        nsView.loadHTMLString("", baseURL: nil)
        coordinator.webView = nil
    }
}

