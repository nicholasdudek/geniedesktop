import AppKit
import Foundation
import SwiftUI
import WebKit

// MARK: - 📑 Creation Preview Tab State
public enum CreationPreviewTab: String, CaseIterable, Identifiable {
    case visual = "Visual Output"
    case rawHtml = "Raw HTML"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .visual: return "eye.fill"
        case .rawHtml: return "chevron.left.forwardslash.chevron.right"
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

    @State private var selectedTab: CreationPreviewTab = .visual
    @State private var isCopied: Bool = false
    @State private var reloadToken: UUID = UUID()
    @State private var statusFeedback: String? = nil
    /// Nil until the user types. Once set, this is what renders and what gets saved,
    /// so edits in the source tab show up in Visual Output.
    @State private var editedHtml: String? = nil

    public init(
        title: String,
        rawHtml: String,
        fileURL: URL? = nil,
        emotion: AIEmotionType = .calm,
        onClose: (() -> Void)? = nil
    ) {
        self.title = title
        self.rawHtml = rawHtml
        self.fileURL = fileURL
        self.emotion = emotion
        self.onClose = onClose
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
        try? self.effectiveHtml.write(to: url, atomically: true, encoding: .utf8)
        return url
    }

    // Guarantee self-contained, high-fidelity HTML boilerplate
    /// What the rest of the view renders, copies and writes: the user's edits when
    /// there are any, otherwise the model's original output.
    private var effectiveHtml: String {
        editedHtml ?? formattedSelfContainedHtml
    }

    private var formattedSelfContainedHtml: String {
        let code = rawHtml.trimmingCharacters(in: .whitespacesAndNewlines)
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
                } else {
                    rawHtmlTab
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        // Re-render on the way back to Visual Output rather than per keystroke, so
        // typing in the source stays smooth but the preview is never stale.
        .onChange(of: selectedTab) { _, tab in
            if tab == .visual { reloadToken = UUID() }
        }
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(red: 0.08, green: 0.09, blue: 0.12))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.8)
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - 🎛️ Header Bar
    private var headerBar: some View {
        HStack(spacing: 8) {
            // Left: Title
            HStack(spacing: 6) {
                Image(systemName: "paintpalette.fill")
                    .foregroundColor(.yellow)
                    .font(.system(size: 11))

                Text(title)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .frame(minWidth: 100, alignment: .leading)

            Spacer()

            // Center: Segmented Two-Tab Selector
            tabSelector

            Spacer()

            // Right: Actions (Safari, Finder, Copy, Close)
            HStack(spacing: 6) {
                if selectedTab == .visual {
                    // Open in Safari
                    Button(action: {
                        openInSafari()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "safari")
                                .font(.system(size: 10))
                            Text("Safari")
                                .font(.system(size: 9.5, weight: .semibold))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.cyan.opacity(0.22)))
                        .foregroundColor(.cyan)
                    }
                    .buttonStyle(.plain)
                    .help("Open and run this creation in Safari")

                    // Reload
                    Button(action: {
                        reloadToken = UUID()
                        HapticFeedback.selection()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 10))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.white.opacity(0.10)))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    .help("Reload WebKit Preview")

                    // Reveal on Desktop
                    Button(action: {
                        revealInFinder()
                    }) {
                        Image(systemName: "folder")
                            .font(.system(size: 10))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.white.opacity(0.10)))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .buttonStyle(.plain)
                    .help("Reveal file on Desktop")
                } else {
                    // Copy Raw HTML
                    Button(action: {
                        copyRawHtml()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 9.5, weight: .bold))
                                .foregroundColor(isCopied ? .green : .white.opacity(0.9))
                            Text(isCopied ? "Copied!" : "Copy HTML")
                                .font(.system(size: 9.5, weight: .semibold))
                                .foregroundColor(isCopied ? .green : .white.opacity(0.9))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(isCopied ? Color.green.opacity(0.20) : Color.white.opacity(0.12)))
                    }
                    .buttonStyle(.plain)
                    .help("Copy complete raw HTML to clipboard")

                    // Open in TextEdit
                    Button(action: {
                        openInTextEdit()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "text.alignleft")
                                .font(.system(size: 9.5))
                            Text("TextEdit")
                                .font(.system(size: 9.5, weight: .semibold))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.white.opacity(0.10)))
                        .foregroundColor(.white.opacity(0.85))
                    }
                    .buttonStyle(.plain)
                    .help("Open source code in TextEdit")
                }

                if let close = onClose {
                    Button(action: {
                        close()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                    .help("Close Preview")
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.40))
    }

    // MARK: - 📑 Tab Selector Capsule
    /// A stock segmented control rather than a custom capsule row. The hand-rolled
    /// version had no intrinsic width, so in a narrow pane its labels wrapped mid-word
    /// ("Visu al Outp ut"). AppKit's own control never does that, and it picks up
    /// keyboard focus, accessibility and the platform's selection behaviour for free.
    private var tabSelector: some View {
        Picker("View", selection: $selectedTab) {
            ForEach(CreationPreviewTab.allCases) { tab in
                Label(tab.rawValue, systemImage: tab.icon).tag(tab)
            }
        }
        .pickerStyle(.segmented)
        .labelsHidden()
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
                emotionColorHex: emotion.accentColor.toHex()
            )
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .padding(4)
        }
    }

    // MARK: - 💻 Raw HTML Tab
    private var rawHtmlTab: some View {
        VStack(spacing: 0) {
            // Code metadata bar
            HStack(spacing: 12) {
                Label("HTML5 Document", systemImage: "chevron.left.forwardslash.chevron.right")
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

            // Monospaced Code Text with Line Numbers
            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                HStack(alignment: .top, spacing: 0) {
                    // Line numbers gutter
                    VStack(alignment: .trailing, spacing: 3) {
                        ForEach(1...max(1, lineCount), id: \.self) { idx in
                            Text("\(idx)")
                                .font(.system(size: 10, weight: .regular, design: .monospaced))
                                .foregroundColor(.white.opacity(0.25))
                                .frame(minWidth: 28, alignment: .trailing)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 6)
                    .background(Color(red: 0.04, green: 0.05, blue: 0.07))

                    Divider().opacity(0.15)

                    // Editable source. Typing here re-renders Visual Output and is what
                    // Copy, Save and Open in Safari all act on.
                    TextEditor(text: Binding(
                        get: { effectiveHtml },
                        set: { editedHtml = $0 }
                    ))
                    .font(.system(size: 10.5, weight: .regular, design: .monospaced))
                    .foregroundColor(Color(red: 0.88, green: 0.92, blue: 0.98))
                    .scrollContentBackground(.hidden)
                    .background(Color.clear)
                    .padding(4)
                    .frame(maxWidth: .infinity, minHeight: 220, alignment: .leading)
                    .accessibilityLabel("HTML source")
                }
            }
            .background(Color(red: 0.06, green: 0.07, blue: 0.10))
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

    private func formatBytes(_ bytes: Int) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
