import AppKit
import Foundation
import SwiftUI
import WebKit

// MARK: - 📑 Creation Preview Tab State
public enum CreationPreviewTab: String, CaseIterable, Identifiable {
    case visual = "Visual Output"
    case rawHtml = "Raw HTML"
    case fileViewer = "Universal Viewer"
    case browser = "Live Web & Stream"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .visual: return "eye.fill"
        case .rawHtml: return "chevron.left.forwardslash.chevron.right"
        case .fileViewer: return "doc.text.magnifyingglass"
        case .browser: return "play.tv.fill"
        }
    }
}

// MARK: - 🎨 Dual-Tab Creation Preview View (Visual & Raw HTML)
public struct GenieCreationDualTabPreviewView: View {
    public let title: String
    public let rawHtml: String
    public let fileURL: URL?
    public let emotion: AIEmotionType
    public var onClose: (() -> Void)? = nil
    public var onCollapse: (() -> Void)? = nil

    @State private var selectedTab: CreationPreviewTab = .visual
    @State private var isCopied: Bool = false
    @State private var reloadToken: UUID = UUID()
    @State private var statusFeedback: String? = nil
    /// Nil until the user types. Once set, this is what renders and what gets saved,
    /// so edits in the source tab show up in Visual Output.
    @State private var editedHtml: String? = nil

    // Live Web & Streaming Browser State
    @State private var streamURLString: String = "https://www.netflix.com"
    @State private var activeStreamURL: URL? = URL(string: "https://www.netflix.com")
    @State private var isStreamLoading: Bool = false
    @State private var canStreamGoBack: Bool = false
    @State private var canStreamGoForward: Bool = false
    @State private var streamPageTitle: String = "Netflix"

    public init(
        title: String,
        rawHtml: String,
        fileURL: URL? = nil,
        emotion: AIEmotionType = .calm,
        onClose: (() -> Void)? = nil,
        onCollapse: (() -> Void)? = nil
    ) {
        self.title = title
        self.rawHtml = rawHtml
        self.fileURL = fileURL
        self.emotion = emotion
        self.onClose = onClose
        self.onCollapse = onCollapse
    }

    // Ensures file exists on Desktop and returns its URL
    private var resolvedFileURL: URL {
        if let url = fileURL, FileManager.default.fileExists(atPath: url.path) {
            return url
        }
        let safeTitle = title
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let baseName = safeTitle.isEmpty ? "AI Creation" : safeTitle
        let desktop = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
        let url = desktop.appendingPathComponent("\(baseName).html")
        saveToDisk()
        return url
    }

    public func saveToDisk(content: String? = nil) {
        // Do not overwrite image or binary files with HTML text
        if let ext = fileURL?.pathExtension.lowercased(), !["html", "htm", "txt", "md", ""].contains(ext) {
            return
        }

        let textToSave = content ?? effectiveHtml
        let targetFileURL = fileURL
        let safeTitle = title
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let baseName = safeTitle.isEmpty ? "AI Creation" : safeTitle
        let desktop = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
        let desktopURL = desktop.appendingPathComponent("\(baseName).html")
        Task.detached(priority: .background) {
            if let fileURL = targetFileURL {
                try? textToSave.write(to: fileURL, atomically: true, encoding: .utf8)
            }
            try? textToSave.write(to: desktopURL, atomically: true, encoding: .utf8)
        }
    }

    private var fileExtension: String {
        fileURL?.pathExtension.lowercased() ?? ""
    }

    private var isImageFile: Bool {
        ["png", "jpg", "jpeg", "gif", "webp", "heic", "svg", "tiff", "bmp"].contains(fileExtension)
    }

    private var isMediaFile: Bool {
        ["mp4", "mov", "m4v", "mp3", "wav", "m4a", "aac"].contains(fileExtension)
    }

    private var isPdfFile: Bool {
        fileExtension == "pdf"
    }

    private var isHtmlFile: Bool {
        if !fileExtension.isEmpty {
            return ["html", "htm"].contains(fileExtension)
        }
        let code = rawHtml.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return code.contains("<!doctype html") || code.contains("<html") || code.contains("<div") || code.contains("<svg")
    }

    private var isTextOrCodeFile: Bool {
        let codeExts: Set<String> = [
            "swift", "py", "js", "ts", "jsx", "tsx", "html", "htm", "css", "scss",
            "json", "xml", "yaml", "yml", "sh", "zsh", "bash", "md", "markdown",
            "txt", "c", "h", "cpp", "hpp", "m", "mm", "rs", "go", "rb", "sql", "plist", "toml"
        ]
        return codeExts.contains(fileExtension)
    }

    public var detectedLanguage: String {
        switch fileExtension {
        case "swift": return "Swift Source"
        case "py": return "Python Script"
        case "js", "jsx": return "JavaScript"
        case "ts", "tsx": return "TypeScript"
        case "json": return "JSON Data"
        case "md", "markdown": return "Markdown Notes"
        case "html", "htm": return "HTML5 Document"
        case "css", "scss": return "CSS Stylesheet"
        case "sh", "zsh", "bash": return "Shell Script"
        case "rs": return "Rust Source"
        case "go": return "Go Source"
        case "sql": return "SQL Database Query"
        case "yaml", "yml": return "YAML Config"
        case "jpg", "jpeg": return "JPEG Photo"
        case "gif": return "Animated GIF"
        case "png": return "PNG Image"
        case "pdf": return "PDF Document"
        case "mp4", "mov": return "Video Media"
        default: return isHtmlFile ? "HTML5 Document" : "Source Code Document"
        }
    }

    private func determineInitialTab() {
        if isImageFile || isPdfFile || isMediaFile {
            selectedTab = .fileViewer
        } else if isHtmlFile {
            selectedTab = .visual
        } else if isTextOrCodeFile {
            selectedTab = .rawHtml
        } else {
            selectedTab = .fileViewer
        }
    }

    // Guarantee self-contained, high-fidelity HTML boilerplate
    /// What the rest of the view renders, copies and writes: the user's edits when
    /// there are any, otherwise the model's original output.
    private var effectiveHtml: String {
        if let edited = editedHtml { return edited }
        if !rawHtml.isEmpty { return formattedSelfContainedHtml }
        if let url = fileURL, let diskContent = try? String(contentsOf: url, encoding: .utf8) {
            return isHtmlFile ? formattedSelfContainedHtml(from: diskContent) : diskContent
        }
        return ""
    }

    private var formattedSelfContainedHtml: String {
        formattedSelfContainedHtml(from: rawHtml)
    }

    private func formattedSelfContainedHtml(from input: String) -> String {
        let code = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if !isHtmlFile {
            return code
        }
        if code.contains("<!DOCTYPE html") || code.contains("<html") {
            return code
        }
        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>\(title)</title>
            <style>
                *, *::before, *::after { box-sizing: border-box; }
                body {
                    margin: 0;
                    padding: 16px;
                    background-color: #0d1117;
                    color: #e6edf3;
                    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
                    overflow: auto;
                    display: flex;
                    flex-direction: column;
                    align-items: center;
                    justify-content: center;
                    min-height: 100vh;
                }
            </style>
        </head>
        <body>
            \(code)
        </body>
        </html>
        """
    }

    private var lineCount: Int {
        effectiveHtml.components(separatedBy: "\n").count
    }

    private var byteCount: Int {
        effectiveHtml.utf8.count
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            headerBar

            // Tab Content
            ZStack {
                if selectedTab == .visual {
                    visualOutputTab
                        .id(reloadToken)
                } else if selectedTab == .rawHtml {
                    rawHtmlTab
                } else if selectedTab == .fileViewer {
                    GenieUniversalFileViewer(url: resolvedFileURL, onClose: nil, showHeader: false)
                } else if selectedTab == .browser {
                    liveBrowserStreamTab
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        // Re-render on the way back to Visual Output rather than per keystroke, so
        // typing in the source stays smooth but the preview is never stale.
        .onChange(of: selectedTab) { _, tab in
            if tab == .visual { reloadToken = UUID() }
        }
        .onKeyPress(.return) {
            postHtmlToChat()
            return .handled
        }
        .onAppear {
            determineInitialTab()
            saveToDisk()
        }
        .onChange(of: fileURL) { _, _ in
            editedHtml = nil
            determineInitialTab()
            reloadToken = UUID()
        }
        .onKeyPress(.escape) {
            if let close = onClose {
                close()
                return .handled
            }
            return .ignored
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(red: 0.08, green: 0.09, blue: 0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.8)
        )
        .overlay(alignment: .topTrailing) {
            if let close = onClose {
                Button(action: {
                    close()
                    HapticFeedback.selection()
                }) {
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.85))
                            .frame(width: 22, height: 22)
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .black))
                            .foregroundColor(.white)
                    }
                    .shadow(color: Color.black.opacity(0.4), radius: 3, y: 1)
                }
                .buttonStyle(.plain)
                .padding(8)
                .help("Close Preview (Esc)")
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - 🎛️ Header Bar
    private var headerBar: some View {
        HStack(spacing: 6) {
            // Close Button (Prominent & Always Visible on Left)
            if let close = onClose {
                Button(action: {
                    close()
                    HapticFeedback.selection()
                }) {
                    HStack(spacing: 3.5) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11, weight: .bold))
                        Text("Close")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3.5)
                    .background(Capsule().fill(Color.red.opacity(0.85)))
                    .overlay(Capsule().strokeBorder(Color.white.opacity(0.35), lineWidth: 0.6))
                }
                .buttonStyle(.plain)
                .fixedSize()
                .help("Close Preview (Esc)")
            }

            // Title with Sparkles Badge
            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .foregroundColor(.cyan)
                    .font(.system(size: 9.5, weight: .semibold))

                Text(title)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .layoutPriority(0)

            Spacer(minLength: 4)

            // Center: Compact Liquid Glass Tab Selector
            tabSelector
                .layoutPriority(2)

            Spacer(minLength: 4)

            // Right: Enter into Chat + More Actions Menu + Collapse
            HStack(spacing: 5) {
                Button(action: {
                    postHtmlToChat()
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 8.5, weight: .bold))
                        Text("In Chat")
                            .font(.system(size: 9.5, weight: .bold))
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3.5)
                    .background(
                        Capsule().fill(Color.purple.opacity(0.45))
                    )
                    .overlay(
                        Capsule().strokeBorder(Color.cyan.opacity(0.50), lineWidth: 0.6)
                    )
                    .foregroundColor(.white)
                }
                .buttonStyle(.plain)
                .fixedSize()
                .help("Post this creation directly into Genie Chat (⏎ Enter)")

                // More Actions Menu (Safari, TextEdit, Reload, Finder)
                Menu {
                    Button(action: { openInSafari() }) {
                        Label("Open in Safari", systemImage: "safari")
                    }
                    Button(action: { reloadToken = UUID(); HapticFeedback.selection() }) {
                        Label("Reload WebKit", systemImage: "arrow.clockwise")
                    }
                    Button(action: { revealInFinder() }) {
                        Label("Reveal on Desktop", systemImage: "folder")
                    }
                    Button(action: { copyRawHtml() }) {
                        Label(isCopied ? "Copied!" : "Copy Code", systemImage: "doc.on.doc")
                    }
                    Button(action: { openInTextEdit() }) {
                        Label("Open in TextEdit", systemImage: "text.alignleft")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.80))
                        .frame(width: 22, height: 22)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()
                .help("Actions (Safari, TextEdit, Reload, Finder)")

                if let collapse = onCollapse {
                    Button(action: {
                        collapse()
                    }) {
                        Image(systemName: "chevron.left.to.line")
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundColor(.white.opacity(0.80))
                            .frame(width: 22, height: 22)
                            .background(Circle().fill(Color.white.opacity(0.08)))
                    }
                    .buttonStyle(.plain)
                    .help("Hide Editor Pane (⌘\\)")
                }
            }
            .fixedSize(horizontal: true, vertical: false)
            .layoutPriority(1)
        }
        .frame(height: 36)
        .padding(.horizontal, 10)
        .padding(.vertical, 3)
        .background(Color.black.opacity(0.60))
    }

    private var availableTabs: [CreationPreviewTab] {
        if isImageFile {
            return [.fileViewer, .browser]
        } else if isPdfFile || isMediaFile {
            return [.fileViewer, .browser]
        } else if isHtmlFile {
            return [.visual, .rawHtml, .fileViewer, .browser]
        } else if isTextOrCodeFile {
            return [.rawHtml, .fileViewer, .browser]
        } else {
            return CreationPreviewTab.allCases
        }
    }

    private func tabTitle(for tab: CreationPreviewTab) -> String {
        switch tab {
        case .visual:
            return isImageFile ? "Image" : "Visual"
        case .rawHtml:
            return isHtmlFile ? "HTML" : "Code"
        case .fileViewer:
            return isImageFile ? "Inspector" : (isPdfFile ? "PDF" : "Files")
        case .browser:
            return "Web"
        }
    }

    private func tabIcon(for tab: CreationPreviewTab) -> String {
        switch tab {
        case .visual:
            return isImageFile ? "photo.fill" : "eye.fill"
        case .rawHtml:
            return isHtmlFile ? "chevron.left.forwardslash.chevron.right" : "curlybraces"
        case .fileViewer:
            return isImageFile ? "magnifyingglass" : (isPdfFile ? "doc.richtext.fill" : "doc.text.magnifyingglass")
        case .browser:
            return "play.tv.fill"
        }
    }

    // MARK: - 📑 Tab Selector Capsule (Genie Liquid Glass Capsule)
    private var tabSelector: some View {
        HStack(spacing: 2) {
            ForEach(availableTabs) { tab in
                Button(action: {
                    HapticFeedback.tick()
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        selectedTab = tab
                    }
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: tabIcon(for: tab))
                            .font(.system(size: 9.5, weight: .semibold))
                        Text(tabTitle(for: tab))
                            .font(.system(size: 11, weight: selectedTab == tab ? .semibold : .medium))
                            .lineLimit(1)
                    }
                    .foregroundColor(selectedTab == tab ? .black : .white.opacity(0.75))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4.5)
                    .background(
                        Capsule()
                            .fill(selectedTab == tab ? Color.white : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2.5)
        .background(Capsule().fill(Color.white.opacity(0.08)))
        .overlay(
            Capsule()
                .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
        )
        .fixedSize()
        .accessibilityLabel("Preview mode")
    }


    // MARK: - 👁️ Visual Output Tab
    private var visualOutputTab: some View {
        ZStack {
            // High-contrast clean dark canvas backing to avoid black-on-transparent invisibility
            Color(red: 0.05, green: 0.06, blue: 0.09)

            InteractiveHtmlWebView(
                htmlString: effectiveHtml,
                emotionColorHex: emotion.accentColor.toHex(),
                customBaseURL: resolvedFileURL.deletingLastPathComponent()
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .padding(4)
        }
    }

    // MARK: - 💻 Raw HTML & Source Code Tab
    private var rawHtmlTab: some View {
        VStack(spacing: 0) {
            // Code metadata bar
            HStack(spacing: 12) {
                Label(detectedLanguage, systemImage: isHtmlFile ? "chevron.left.forwardslash.chevron.right" : "curlybraces")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.cyan)

                Text("•")
                    .foregroundColor(.white.opacity(0.3))

                Text("\(lineCount) lines")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))

                Text("•")
                    .foregroundColor(.white.opacity(0.3))

                Text("\(formatBytes(byteCount))")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))

                Spacer()

                Text("UTF-8")
                    .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.45))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(Color(red: 0.05, green: 0.06, blue: 0.08))

            Divider().opacity(0.2)

            // Editable source. Typing here immediately saves to disk after every
            // character and live-updates Visual Output, Safari and Finder.
            //
            // TextEditor scrolls itself. It used to sit inside a
            // ScrollView([.horizontal, .vertical]) next to a line-number gutter,
            // which proposed unbounded height to a view that sizes itself from
            // the height it is offered — so it collapsed and the pane rendered
            // blank while the metadata bar above still reported the real line
            // and byte count. The gutter went with it: keeping numbers aligned
            // to a TextEditor's internal layout needs an NSTextView-backed
            // editor, not a VStack guessing at line height.
            TextEditor(text: Binding(
                get: { effectiveHtml },
                set: { newCode in
                    editedHtml = newCode
                    saveToDisk(content: newCode)
                    reloadToken = UUID()
                }
            ))
            .font(.system(size: 10.5, weight: .regular, design: .monospaced))
            .foregroundColor(Color(red: 0.88, green: 0.92, blue: 0.98))
            .scrollContentBackground(.hidden)
            .background(Color(red: 0.06, green: 0.07, blue: 0.10))
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .accessibilityLabel("HTML source")
        }
    }

    // MARK: - 🍿 Live Browser & Streaming Tab
    private var liveBrowserStreamTab: some View {
        VStack(spacing: 0) {
            // Streaming & URL Control Bar
            HStack(spacing: 8) {
                // Navigation controls
                HStack(spacing: 4) {
                    Button(action: {
                        if canStreamGoBack {
                            MiniBrowserManager.shared.activeWebView?.goBack()
                        }
                    }) {
                        Image(systemName: "chevron.backward")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(canStreamGoBack ? .white : .white.opacity(0.3))
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(Color.white.opacity(0.08)))
                    }
                    .buttonStyle(.plain)
                    .disabled(!canStreamGoBack)

                    Button(action: {
                        if canStreamGoForward {
                            MiniBrowserManager.shared.activeWebView?.goForward()
                        }
                    }) {
                        Image(systemName: "chevron.forward")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(canStreamGoForward ? .white : .white.opacity(0.3))
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(Color.white.opacity(0.08)))
                    }
                    .buttonStyle(.plain)
                    .disabled(!canStreamGoForward)

                    Button(action: {
                        if let url = activeStreamURL {
                            MiniBrowserManager.shared.activeWebView?.load(URLRequest(url: url))
                        }
                    }) {
                        Image(systemName: isStreamLoading ? "xmark" : "arrow.clockwise")
                            .font(.system(size: 10.5, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                            .frame(width: 24, height: 24)
                            .background(Circle().fill(Color.white.opacity(0.08)))
                    }
                    .buttonStyle(.plain)
                }

                // URL Input Bar
                HStack(spacing: 6) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 9.5))
                        .foregroundColor(.green.opacity(0.85))

                    TextField("Enter URL or search...", text: $streamURLString, onCommit: {
                        navigateToStreamURL(streamURLString)
                    })
                    .textFieldStyle(.plain)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.white)

                    if isStreamLoading {
                        ProgressView()
                            .scaleEffect(0.5)
                            .frame(width: 16, height: 16)
                    }

                    Button(action: {
                        navigateToStreamURL(streamURLString)
                    }) {
                        Text("Go")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2.5)
                            .background(Capsule().fill(Color.cyan))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4.5)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.08)))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.12), lineWidth: 0.6))

                // Streaming Quick Presets
                HStack(spacing: 5) {
                    streamPresetChip(label: "🍿 Netflix", url: "https://www.netflix.com")
                    streamPresetChip(label: "▶️ YouTube", url: "https://www.youtube.com")
                    streamPresetChip(label: "📺 Twitch", url: "https://www.twitch.tv")
                    streamPresetChip(label: "🎬 Apple TV", url: "https://tv.apple.com")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color(red: 0.07, green: 0.08, blue: 0.11))

            // Main Web & Streaming View
            ZStack {
                Color.black

                NativeWKWebView(
                    url: activeStreamURL,
                    isLoading: $isStreamLoading,
                    canGoBack: $canStreamGoBack,
                    canGoForward: $canStreamGoForward,
                    title: $streamPageTitle
                )
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .padding(2)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func streamPresetChip(label: String, url: String) -> some View {
        Button(action: {
            HapticFeedback.selection()
            streamURLString = url
            navigateToStreamURL(url)
        }) {
            Text(label)
                .font(.system(size: 9.5, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 7)
                .padding(.vertical, 3.5)
                .background(Capsule().fill(Color.white.opacity(0.12)))
                .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }

    private func navigateToStreamURL(_ text: String) {
        var trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.lowercased().hasPrefix("http://") && !trimmed.lowercased().hasPrefix("https://") {
            if trimmed.contains(".") && !trimmed.contains(" ") {
                trimmed = "https://" + trimmed
            } else {
                trimmed = "https://www.google.com/search?q=" + (trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed)
            }
        }
        if let target = URL(string: trimmed) {
            activeStreamURL = target
            MiniBrowserManager.shared.activeWebView?.load(URLRequest(url: target))
        }
    }

    // MARK: - 🚀 Actions
    private func copyRawHtml() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(effectiveHtml, forType: .string)
        HapticFeedback.success()
        withAnimation {
            isCopied = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            isCopied = false
        }
    }

    private func openInSafari() {
        let url = resolvedFileURL
        if let safariURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Safari") {
            NSWorkspace.shared.open([url], withApplicationAt: safariURL, configuration: NSWorkspace.OpenConfiguration())
        } else {
            NSWorkspace.shared.open(url)
        }
        HapticFeedback.selection()
    }

    private func openInTextEdit() {
        let url = resolvedFileURL
        if let textEditURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.TextEdit") {
            NSWorkspace.shared.open([url], withApplicationAt: textEditURL, configuration: NSWorkspace.OpenConfiguration())
        } else {
            NSWorkspace.shared.open(url)
        }
        HapticFeedback.selection()
    }

    private func revealInFinder() {
        let url = resolvedFileURL
        NSWorkspace.shared.activateFileViewerSelecting([url])
        HapticFeedback.selection()
    }

    private func postHtmlToChat() {
        let code = effectiveHtml
        let msg = ChatMessage(
            role: "user",
            content: "Rendered HTML Creation: **\(title)**\n\n```html\n\(code)\n```",
            mediaType: "html"
        )
        LocalModelManager.shared.chatHistory.append(msg)
        LocalModelManager.shared.saveChatHistory()
        HapticFeedback.selection()
        statusFeedback = "Rendered HTML entered into Genie ✨"
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            statusFeedback = nil
        }
    }

    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
