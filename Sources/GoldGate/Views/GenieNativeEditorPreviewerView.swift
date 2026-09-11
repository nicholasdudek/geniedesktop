//
//  GenieNativeEditorPreviewerView.swift
//  GoldGate • © 2026 Nicholas M. Dudek
//
//  A native, lightweight code editor and shared live previewer designed with
//  Apple colorways, language selection, live HTML/Markdown preview, and
//  deep macOS integration.
//

import AppKit
import Foundation
import SwiftUI
import WebKit

// MARK: - 🎨 Apple Colorways
public enum AppleColorway: String, CaseIterable, Identifiable {
    case cupertinoDark = "Cupertino Charcoal"
    case spaceGrayPro = "Space Gray Pro"
    case oledMidnight = "OLED Midnight"
    case xcodeDark = "Xcode Canvas"
    case californiaSunset = "California Sunset"
    case titaniumSilver = "Titanium Silver"

    public var id: String { rawValue }

    public var swatchColor: Color {
        switch self {
        case .cupertinoDark: return Color(red: 0.12, green: 0.12, blue: 0.14)
        case .spaceGrayPro: return Color(red: 0.10, green: 0.11, blue: 0.13)
        case .oledMidnight: return Color.black
        case .xcodeDark: return Color(red: 0.16, green: 0.16, blue: 0.19)
        case .californiaSunset: return Color(red: 0.14, green: 0.10, blue: 0.15)
        case .titaniumSilver: return Color(red: 0.15, green: 0.16, blue: 0.18)
        }
    }

    public var accentColor: Color {
        switch self {
        case .cupertinoDark: return Color(red: 0.04, green: 0.52, blue: 1.00) // SF Blue
        case .spaceGrayPro: return Color(red: 0.39, green: 0.82, blue: 1.00) // Icy Cyan
        case .oledMidnight: return Color(red: 0.69, green: 0.32, blue: 0.87) // Cyber Purple
        case .xcodeDark: return Color(red: 0.99, green: 0.70, blue: 0.25) // Amber
        case .californiaSunset: return Color(red: 1.00, green: 0.39, blue: 0.23) // Sunset Coral
        case .titaniumSilver: return Color(red: 0.39, green: 0.90, blue: 0.89) // Mint
        }
    }

    public var editorBackground: Color {
        switch self {
        case .cupertinoDark: return Color(red: 0.11, green: 0.11, blue: 0.13)
        case .spaceGrayPro: return Color(red: 0.09, green: 0.10, blue: 0.12)
        case .oledMidnight: return Color.black
        case .xcodeDark: return Color(red: 0.15, green: 0.16, blue: 0.18)
        case .californiaSunset: return Color(red: 0.12, green: 0.09, blue: 0.13)
        case .titaniumSilver: return Color(red: 0.13, green: 0.14, blue: 0.16)
        }
    }

    public var gutterBackground: Color {
        switch self {
        case .cupertinoDark: return Color(red: 0.14, green: 0.14, blue: 0.16)
        case .spaceGrayPro: return Color(red: 0.12, green: 0.13, blue: 0.15)
        case .oledMidnight: return Color(red: 0.05, green: 0.05, blue: 0.06)
        case .xcodeDark: return Color(red: 0.18, green: 0.19, blue: 0.21)
        case .californiaSunset: return Color(red: 0.16, green: 0.12, blue: 0.17)
        case .titaniumSilver: return Color(red: 0.16, green: 0.17, blue: 0.19)
        }
    }

    public var textColor: Color {
        Color.white.opacity(0.92)
    }

    public var gutterTextColor: Color {
        Color.white.opacity(0.35)
    }

    public var borderColor: Color {
        Color.white.opacity(0.12)
    }
}

// MARK: - 💻 Supported Editor Languages
public enum EditorLanguage: String, CaseIterable, Identifiable {
    case swift = "Swift"
    case python = "Python"
    case html = "HTML"
    case css = "CSS"
    case javascript = "JavaScript"
    case typescript = "TypeScript"
    case markdown = "Markdown"
    case json = "JSON"
    case rust = "Rust"
    case go = "Go"
    case shell = "Shell"
    case plaintext = "Plain Text"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .swift: return "swift"
        case .python: return "chevron.left.forwardslash.chevron.right"
        case .html, .css: return "globe"
        case .javascript, .typescript: return "curlybraces"
        case .markdown: return "doc.plaintext"
        case .json: return "doc.badge.gearshape"
        case .rust, .go: return "gearshape.2.fill"
        case .shell: return "terminal.fill"
        case .plaintext: return "doc.text.fill"
        }
    }

    public var fileExtension: String {
        switch self {
        case .swift: return "swift"
        case .python: return "py"
        case .html: return "html"
        case .css: return "css"
        case .javascript: return "js"
        case .typescript: return "ts"
        case .markdown: return "md"
        case .json: return "json"
        case .rust: return "rs"
        case .go: return "go"
        case .shell: return "sh"
        case .plaintext: return "txt"
        }
    }

    public var defaultSnippet: String {
        switch self {
        case .swift:
            return """
            import SwiftUI

            // Genie Native Swift Atelier
            struct WelcomeCard: View {
                var body: some View {
                    VStack(spacing: 8) {
                        Text("Hello from Genie Native Studio ✨")
                            .font(.headline)
                            .foregroundColor(.cyan)
                    }
                    .padding()
                }
            }
            """
        case .python:
            return """
            # Genie Python Environment
            def main():
                print("Hello from Apple Silicon & Genie! 🚀")

            if __name__ == "__main__":
                main()
            """
        case .html:
            return """
            <!DOCTYPE html>
            <html lang="en">
            <head>
              <meta charset="UTF-8">
              <style>
                body {
                  margin: 0;
                  height: 100vh;
                  display: flex;
                  flex-direction: column;
                  align-items: center;
                  justify-content: center;
                  background: radial-gradient(circle at center, #1E1B4B 0%, #030712 100%);
                  color: white;
                  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
                }
                .glow {
                  font-size: 2.5rem;
                  font-weight: 800;
                  background: linear-gradient(135deg, #38BDF8, #818CF8, #C084FC);
                  -webkit-background-clip: text;
                  -webkit-text-fill-color: transparent;
                  margin-bottom: 0.5rem;
                }
                .badge {
                  padding: 6px 14px;
                  background: rgba(255, 255, 255, 0.10);
                  border: 1px solid rgba(255, 255, 255, 0.20);
                  border-radius: 999px;
                  font-size: 0.85rem;
                  letter-spacing: 0.5px;
                }
              </style>
            </head>
            <body>
              <div class="glow">Genie Living Studio</div>
              <div class="badge">Live Shared Previewer</div>
            </body>
            </html>
            """
        case .markdown:
            return """
            # Project Notes & Spec

            Welcome to the **Genie Native Editor**!

            - ⚡ **Zero Latency**: Real-time Apple Silicon responsive editing.
            - 🎨 **Apple Colorways**: Cupertino, Space Gray, OLED Midnight, and Sunset.
            - 🔄 **Shared Previewer**: Edits render live side-by-side.
            """
        case .json:
            return """
            {
              "name": "Genie",
              "version": "1.0.0",
              "runtime": "Apple Silicon ARM64",
              "theme": "Cupertino Charcoal"
            }
            """
        default:
            return "// Write your code or paste text here...\n"
        }
    }

    public static func from(url: URL) -> EditorLanguage {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "swift": return .swift
        case "py": return .python
        case "html", "htm": return .html
        case "css": return .css
        case "js", "jsx": return .javascript
        case "ts", "tsx": return .typescript
        case "md", "markdown": return .markdown
        case "json": return .json
        case "rs": return .rust
        case "go": return .go
        case "sh", "zsh", "bash": return .shell
        default: return .plaintext
        }
    }
}

// MARK: - 📑 Shared Previewer Mode
public enum EditorPreviewMode: String, CaseIterable, Identifiable {
    case split = "Split View"
    case editorOnly = "Editor Only"
    case previewOnly = "Preview Only"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .split: return "rectangle.split.2x1"
        case .editorOnly: return "chevron.left.forwardslash.chevron.right"
        case .previewOnly: return "eye.fill"
        }
    }
}

// MARK: - 🪟 Genie Native Editor & Shared Previewer View
public struct GenieNativeEditorPreviewerView: View {
    @AppStorage("genieEditorColorway") private var selectedColorwayRaw: String = AppleColorway.cupertinoDark.rawValue
    @AppStorage("genieEditorFontSize") private var fontSize: Double = 13.0
    @AppStorage("genieEditorPreviewMode") private var previewModeRaw: String = EditorPreviewMode.split.rawValue

    public var fileURL: URL?
    public var onCodeChange: ((String) -> Void)?

    @State private var codeText: String = ""
    @State private var selectedLanguage: EditorLanguage = .swift
    @State private var isSaved: Bool = true
    @State private var statusMessage: String? = nil
    @State private var splitFraction: CGFloat = 0.52

    private var activeColorway: AppleColorway {
        AppleColorway(rawValue: selectedColorwayRaw) ?? .cupertinoDark
    }

    private var previewMode: EditorPreviewMode {
        EditorPreviewMode(rawValue: previewModeRaw) ?? .split
    }

    private var previewModeBinding: Binding<EditorPreviewMode> {
        Binding(
            get: { EditorPreviewMode(rawValue: previewModeRaw) ?? .split },
            set: { previewModeRaw = $0.rawValue }
        )
    }

    public init(
        fileURL: URL? = nil,
        initialCode: String? = nil,
        onCodeChange: ((String) -> Void)? = nil
    ) {
        self.fileURL = fileURL
        self.onCodeChange = onCodeChange

        if let initial = initialCode, !initial.isEmpty {
            _codeText = State(initialValue: initial)
        } else if let url = fileURL, let content = try? String(contentsOf: url, encoding: .utf8) {
            _codeText = State(initialValue: content)
        } else {
            _codeText = State(initialValue: EditorLanguage.html.defaultSnippet)
        }

        if let url = fileURL {
            _selectedLanguage = State(initialValue: EditorLanguage.from(url: url))
        } else {
            _selectedLanguage = State(initialValue: .html)
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            // ── Top Glass Control Ribbon ──
            editorHeaderToolbar

            Divider().background(activeColorway.borderColor)

            // ── Main Shared Canvas (Editor + Live Preview) ──
            GeometryReader { geo in
                let totalW = geo.size.width
                let totalH = geo.size.height

                HStack(spacing: 0) {
                    // Left / Main: Code Editor Pane
                    if previewMode != .previewOnly {
                        codeEditorBuffer
                            .frame(width: previewMode == .split ? max(280, totalW * splitFraction) : totalW, height: totalH)
                    }

                    // Draggable Split Divider
                    if previewMode == .split {
                        splitHandleView(totalWidth: totalW)
                    }

                    // Right: Live Shared Previewer Pane
                    if previewMode != .editorOnly {
                        livePreviewPane
                            .frame(width: previewMode == .split ? max(260, totalW * (1.0 - splitFraction) - 4) : totalW, height: totalH)
                    }
                }
                .frame(width: totalW, height: totalH)
            }

            Divider().background(activeColorway.borderColor)

            // ── Bottom Telemetry & Status Bar ──
            editorStatusBar
        }
        .background(activeColorway.editorBackground)
        .onAppear {
            loadFileIfNeeded()
        }
        .onChange(of: fileURL) { _, newURL in
            loadFile(from: newURL)
        }
    }

    // MARK: - 🎛️ Header Toolbar
    private var editorHeaderToolbar: some View {
        HStack(spacing: 10) {
            // File / Title Identifier
            HStack(spacing: 6) {
                Image(systemName: selectedLanguage.icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(activeColorway.accentColor)

                Text(fileURL?.lastPathComponent ?? "Untitled.\(selectedLanguage.fileExtension)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                if !isSaved {
                    Circle()
                        .fill(activeColorway.accentColor)
                        .frame(width: 6, height: 6)
                        .help("Unsaved changes")
                }
            }
            .padding(.leading, 12)

            Spacer()

            // Language Selector Menu
            Menu {
                ForEach(EditorLanguage.allCases) { lang in
                    Button(action: {
                        selectedLanguage = lang
                        if codeText.isEmpty || codeText == EditorLanguage.html.defaultSnippet || codeText == EditorLanguage.swift.defaultSnippet {
                            codeText = lang.defaultSnippet
                        }
                    }) {
                        Label(lang.rawValue, systemImage: lang.icon)
                    }
                }
            } label: {
                HStack(spacing: 5) {
                    Text(selectedLanguage.rawValue)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                    Image(systemName: "chevron.down")
                        .font(.system(size: 8))
                }
                .foregroundColor(.white.opacity(0.85))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.white.opacity(0.08)))
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.16), lineWidth: 0.5))
            }
            .menuStyle(.borderlessButton)
            .fixedSize()

            // Apple Colorways Theme Picker
            Menu {
                ForEach(AppleColorway.allCases) { colorway in
                    Button(action: {
                        selectedColorwayRaw = colorway.rawValue
                    }) {
                        HStack {
                            Text(colorway.rawValue)
                            if activeColorway == colorway {
                                Text("✓")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Circle()
                        .fill(activeColorway.accentColor)
                        .frame(width: 8, height: 8)

                    Text(activeColorway.rawValue)
                        .font(.system(size: 11, weight: .medium, design: .rounded))

                    Image(systemName: "paintpalette.fill")
                        .font(.system(size: 9))
                }
                .foregroundColor(.white.opacity(0.85))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.white.opacity(0.08)))
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.16), lineWidth: 0.5))
            }
            .menuStyle(.borderlessButton)
            .fixedSize()

            // View Mode Selector (Editor / Split / Preview)
            Picker("", selection: previewModeBinding) {
                ForEach(EditorPreviewMode.allCases) { mode in
                    Label(mode.rawValue, systemImage: mode.icon).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(maxWidth: 240)

            // Save Button
            Button(action: { saveCurrentFile() }) {
                Image(systemName: "square.and.arrow.down.fill")
                    .font(.system(size: 11))
                    .foregroundColor(isSaved ? .white.opacity(0.6) : activeColorway.accentColor)
                    .frame(width: 26, height: 26)
                    .background(Circle().fill(Color.white.opacity(0.08)))
            }
            .buttonStyle(.plain)
            .help("Save to disk (⌘S)")
            .keyboardShortcut("s", modifiers: .command)

            // Open in Real VS Code Insiders Action Button
            Button(action: { openInVSCodeInsiders() }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.forward.app")
                        .font(.system(size: 10))
                    Text("VS Code Insiders")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white.opacity(0.85))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.cyan.opacity(0.20)))
                .overlay(Capsule().strokeBorder(Color.cyan.opacity(0.45), lineWidth: 0.6))
            }
            .buttonStyle(.plain)
            .help("Open current file in real VS Code Insiders with your full extensions & settings")
            .padding(.trailing, 12)
        }
        .frame(height: 38)
        .background(activeColorway.editorBackground.opacity(0.95))
    }

    // MARK: - 📝 Text Editor Buffer with Line Numbers
    private var codeEditorBuffer: some View {
        HStack(alignment: .top, spacing: 0) {
            // Line Numbers Gutter
            lineNumbersGutter
                .frame(minWidth: 38, alignment: .trailing)
                .padding(.vertical, 8)
                .padding(.horizontal, 6)
                .background(activeColorway.gutterBackground)

            Rectangle()
                .fill(activeColorway.borderColor)
                .frame(width: 1)

            // Code Text Editor
            TextEditor(text: $codeText)
                .font(.system(size: CGFloat(fontSize), weight: .regular, design: .monospaced))
                .foregroundColor(activeColorway.textColor)
                .scrollContentBackground(.hidden)
                .padding(8)
                .onChange(of: codeText) { _, newCode in
                    isSaved = false
                    onCodeChange?(newCode)
                }
        }
        .background(activeColorway.editorBackground)
    }

    // Line Numbers Gutter
    private var lineNumbersGutter: some View {
        let count = max(1, codeText.components(separatedBy: "\n").count)
        return VStack(alignment: .trailing, spacing: 4.2) {
            ForEach(1...count, id: \.self) { line in
                Text("\(line)")
                    .font(.system(size: max(9.5, CGFloat(fontSize) - 2.5), design: .monospaced))
                    .foregroundColor(activeColorway.gutterTextColor)
            }
            Spacer()
        }
    }

    // MARK: - 🪟 Shared Live Previewer Pane
    private var livePreviewPane: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 5) {
                    Circle().fill(Color.green).frame(width: 6, height: 6)
                    Text("LIVE RENDER")
                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7))
                }
                Spacer()
                Text(selectedLanguage.rawValue)
                    .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.black.opacity(0.25))

            Divider().background(activeColorway.borderColor)

            // Dynamic Live WebKit / Artifact Render
            EditorHTMLPreviewWebView(content: liveRenderableHTML)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.black.opacity(0.40))
    }

    // Generates valid HTML representation for real-time previewing
    private var liveRenderableHTML: String {
        switch selectedLanguage {
        case .html:
            return codeText
        case .markdown:
            let escaped = codeText
                .replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")
            return """
            <!DOCTYPE html>
            <html>
            <head>
              <meta charset="utf-8">
              <style>
                body {
                  margin: 20px;
                  background: #0D1117;
                  color: #C9D1D9;
                  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
                  line-height: 1.6;
                }
                pre { background: #161B22; padding: 12px; border-radius: 6px; overflow-x: auto; }
                h1, h2, h3 { color: #58A6FF; border-bottom: 1px solid #21262D; padding-bottom: 6px; }
                code { color: #FF7B72; font-family: monospace; }
              </style>
            </head>
            <body>
              <pre>\(escaped)</pre>
            </body>
            </html>
            """
        default:
            let escaped = codeText
                .replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")
            return """
            <!DOCTYPE html>
            <html>
            <head>
              <meta charset="utf-8">
              <style>
                body {
                  margin: 20px;
                  background: #0A0A0C;
                  color: #00F0FF;
                  font-family: "SF Mono", Menlo, Monaco, monospace;
                  font-size: 12px;
                  line-height: 1.5;
                }
                pre { margin: 0; white-space: pre-wrap; word-break: break-all; }
              </style>
            </head>
            <body>
              <pre>\(escaped)</pre>
            </body>
            </html>
            """
        }
    }

    // MARK: - ↕️ Split Handle View
    private func splitHandleView(totalWidth: CGFloat) -> some View {
        ZStack {
            Rectangle()
                .fill(activeColorway.borderColor)
                .frame(width: 4)

            Capsule()
                .fill(Color.white.opacity(0.35))
                .frame(width: 3, height: 28)
        }
        .contentShape(Rectangle())
        .gesture(
            DragGesture()
                .onChanged { val in
                    let newFraction = val.location.x / max(1, totalWidth)
                    splitFraction = min(0.85, max(0.15, newFraction))
                }
        )
    }

    // MARK: - 📊 Bottom Status Bar
    private var editorStatusBar: some View {
        HStack(spacing: 14) {
            // Lines and Character Count
            let lines = codeText.components(separatedBy: "\n").count
            let chars = codeText.count
            Text("\(lines) lines • \(chars) chars")
                .font(.system(size: 9.5, design: .monospaced))
                .foregroundColor(.white.opacity(0.55))

            Spacer()

            if let msg = statusMessage {
                Text(msg)
                    .font(.system(size: 9.5, weight: .medium, design: .rounded))
                    .foregroundColor(activeColorway.accentColor)
            }

            Text("UTF-8")
                .font(.system(size: 9.5, design: .monospaced))
                .foregroundColor(.white.opacity(0.40))

            Text(selectedLanguage.rawValue)
                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                .foregroundColor(activeColorway.accentColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .background(activeColorway.gutterBackground)
    }

    // MARK: - 💾 File Helpers
    private func loadFileIfNeeded() {
        guard let url = fileURL else { return }
        loadFile(from: url)
    }

    private func loadFile(from url: URL?) {
        guard let url = url else { return }
        if let text = try? String(contentsOf: url, encoding: .utf8) {
            codeText = text
            selectedLanguage = EditorLanguage.from(url: url)
            isSaved = true
            statusMessage = "Loaded \(url.lastPathComponent)"
        }
    }

    private func saveCurrentFile() {
        let targetURL: URL
        if let url = fileURL {
            targetURL = url
        } else {
            let desktop = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
            targetURL = desktop.appendingPathComponent("Untitled.\(selectedLanguage.fileExtension)")
        }

        do {
            try codeText.write(to: targetURL, atomically: true, encoding: .utf8)
            isSaved = true
            statusMessage = "Saved to \(targetURL.lastPathComponent) ✓"
            HapticFeedback.selection()
        } catch {
            statusMessage = "Error saving: \(error.localizedDescription)"
        }
    }

    private func openInVSCodeInsiders() {
        let appBundleID = "com.microsoft.VSCodeInsiders"
        let fallbackPath = "/Applications/Visual Studio Code - Insiders.app"

        if let target = fileURL {
            let config = NSWorkspace.OpenConfiguration()
            if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: appBundleID) {
                NSWorkspace.shared.open([target], withApplicationAt: appURL, configuration: config) { _, _ in }
                statusMessage = "Opened in VS Code Insiders 💻"
                return
            }
            if FileManager.default.fileExists(atPath: fallbackPath) {
                let appURL = URL(fileURLWithPath: fallbackPath)
                NSWorkspace.shared.open([target], withApplicationAt: appURL, configuration: config) { _, _ in }
                statusMessage = "Opened in VS Code Insiders 💻"
                return
            }
        }

        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: appBundleID) {
            NSWorkspace.shared.open(appURL)
            statusMessage = "Launched VS Code Insiders 🚀"
        } else if FileManager.default.fileExists(atPath: fallbackPath) {
            NSWorkspace.shared.open(URL(fileURLWithPath: fallbackPath))
            statusMessage = "Launched VS Code Insiders 🚀"
        } else {
            statusMessage = "VS Code Insiders not found at /Applications"
        }
    }
}

// MARK: - 🌐 Native WKWebView for Shared Live Previewer
public struct EditorHTMLPreviewWebView: NSViewRepresentable {
    public let content: String

    public init(content: String) {
        self.content = content
    }

    public func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let wv = WKWebView(frame: .zero, configuration: config)
        wv.setValue(false, forKey: "drawsBackground")
        wv.loadHTMLString(content, baseURL: nil)
        return wv
    }

    public func updateNSView(_ nsView: WKWebView, context: Context) {
        nsView.loadHTMLString(content, baseURL: nil)
    }
}
