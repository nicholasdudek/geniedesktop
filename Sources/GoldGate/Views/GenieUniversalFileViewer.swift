import AppKit
import Foundation
import QuickLookUI
import SwiftUI
import AVKit

// MARK: - 👁️ Native macOS Quick Look Embedded View (QLPreviewView)
public struct QuickLookEmbeddedView: NSViewRepresentable {
    public let url: URL

    public init(url: URL) {
        self.url = url
    }

    public func makeNSView(context: Context) -> QLPreviewView {
        let view = QLPreviewView(frame: .zero, style: .normal) ?? QLPreviewView()
        view.autoresizingMask = [.width, .height]
        view.previewItem = url as QLPreviewItem
        return view
    }

    public func updateNSView(_ nsView: QLPreviewView, context: Context) {
        if let currentItem = nsView.previewItem as? URL, currentItem == url {
            return
        }
        nsView.previewItem = url as QLPreviewItem
        nsView.refreshPreviewItem()
    }
}

// MARK: - 📑 Viewer Display Mode
public enum FileViewerMode: String, CaseIterable, Identifiable {
    case quickLook = "Quick Look"
    case visual = "Visual"
    case codeText = "Source / Text"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .quickLook: return "eye.fill"
        case .visual: return "sparkles"
        case .codeText: return "chevron.left.forwardslash.chevron.right"
        }
    }
}

// MARK: - 📦 Universal File Viewer for macOS
/// Fully featured multi-format file viewer supporting:
/// - PDFs with native pagination & selection
/// - Images (PNG, JPG, HEIC, WebP, SVG, GIF) with zoom/pan
/// - Audio / Video (MP4, MOV, MP3, WAV, M4A) with controls
/// - Code & Text (Swift, Python, JS, TS, HTML, CSS, JSON, Markdown, Shell) with line numbers
/// - 3D Models (USDZ) and Office/iWork docs via native QuickLookUI
public struct GenieUniversalFileViewer: View {
    public let url: URL
    public var onClose: (() -> Void)? = nil
    public var showHeader: Bool = true

    @State private var viewerMode: FileViewerMode = .quickLook
    @State private var isCopied: Bool = false
    @State private var imageZoom: CGFloat = 1.0
    @State private var textContent: String? = nil
    @State private var isTextLoading: Bool = false
    @State private var isPlayingGif: Bool = true
    @State private var imageMetadata: GenieImageMetadata? = nil

    public init(url: URL, onClose: (() -> Void)? = nil, showHeader: Bool = true) {
        self.url = url
        self.onClose = onClose
        self.showHeader = showHeader
    }

    private var fileExtension: String {
        url.pathExtension.lowercased()
    }

    private var isImageFile: Bool {
        ["png", "jpg", "jpeg", "heic", "webp", "gif", "tiff", "icns", "svg"].contains(fileExtension)
    }

    private var isPdfFile: Bool {
        fileExtension == "pdf"
    }

    private var isMediaFile: Bool {
        ["mp4", "mov", "m4v", "mp3", "wav", "m4a", "aac", "flac"].contains(fileExtension)
    }

    private var isTextOrCodeFile: Bool {
        let codeExts: Set<String> = [
            "swift", "py", "js", "ts", "jsx", "tsx", "html", "htm", "css", "scss",
            "json", "xml", "yaml", "yml", "sh", "zsh", "bash", "md", "markdown",
            "txt", "c", "h", "cpp", "hpp", "m", "mm", "rs", "go", "rb", "sql", "plist", "toml"
        ]
        return codeExts.contains(fileExtension)
    }

    private var formattedFileSize: String {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: url.path),
              let size = attrs[.size] as? Int64 else {
            return "0 KB"
        }
        let bcf = ByteCountFormatter()
        bcf.allowedUnits = [.useAll]
        bcf.countStyle = .file
        return bcf.string(fromByteCount: size)
    }

    private var fileIconName: String {
        if isImageFile { return "photo.fill" }
        if isPdfFile { return "doc.richtext.fill" }
        if isMediaFile { return "play.rectangle.fill" }
        if isTextOrCodeFile { return "chevron.left.forwardslash.chevron.right" }
        return "doc.fill"
    }

    private var fileTypeBadge: String {
        if fileExtension.isEmpty { return "FILE" }
        return fileExtension.uppercased()
    }

    public var body: some View {
        VStack(spacing: 0) {
            if showHeader {
                viewerHeaderBar
            }

            // Main Viewer Viewport
            ZStack {
                switch viewerMode {
                case .quickLook:
                    QuickLookEmbeddedView(url: url)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .visual:
                    visualPreviewBody
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                case .codeText:
                    codeTextBody
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .background(Color(red: 0.08, green: 0.09, blue: 0.12))
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.white.opacity(0.14), lineWidth: 0.8)
        )
        .onAppear {
            determineInitialMode()
            loadTextContentIfNeeded()
        }
        .onChange(of: url) { _, _ in
            textContent = nil
            imageMetadata = nil
            imageZoom = 1.0
            determineInitialMode()
            loadTextContentIfNeeded()
        }
    }

    private func determineInitialMode() {
        if isPdfFile || isMediaFile || ["usdz", "zip"].contains(fileExtension) {
            viewerMode = .quickLook
        } else if isImageFile {
            viewerMode = .visual
        } else if isTextOrCodeFile {
            viewerMode = .codeText
        } else {
            viewerMode = .quickLook
        }
    }

    private func loadTextContentIfNeeded() {
        guard isTextOrCodeFile, textContent == nil else { return }
        isTextLoading = true
        DispatchQueue.global(qos: .userInitiated).async {
            if let data = try? Data(contentsOf: url),
               let str = String(data: data.prefix(131072), encoding: .utf8) {
                DispatchQueue.main.async {
                    self.textContent = str
                    self.isTextLoading = false
                }
            } else {
                DispatchQueue.main.async {
                    self.textContent = "(Binary or non-UTF8 encoded content)"
                    self.isTextLoading = false
                }
            }
        }
    }

    // MARK: - 🎛️ Header Bar
    private var viewerHeaderBar: some View {
        HStack(spacing: 8) {
            // File Icon & Info
            HStack(spacing: 6) {
                Image(systemName: fileIconName)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.cyan)

                Text(url.lastPathComponent)
                    .font(.system(size: 11.5, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Text(fileTypeBadge)
                    .font(.system(size: 8.5, weight: .heavy, design: .monospaced))
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 4.5)
                    .padding(.vertical, 1.5)
                    .background(Capsule().fill(Color.cyan.opacity(0.18)))

                Text("(\(formattedFileSize))")
                    .font(.system(size: 9.5, design: .monospaced))
                    .foregroundColor(.white.opacity(0.55))
            }
            .frame(minWidth: 80, alignment: .leading)

            Spacer(minLength: 4)

            // Mode Switcher (When applicable)
            if isTextOrCodeFile || isImageFile {
                HStack(spacing: 2) {
                    ForEach([FileViewerMode.quickLook, (isImageFile ? .visual : .codeText)], id: \.self) { mode in
                        Button(action: {
                            HapticFeedback.tick()
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                viewerMode = mode
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: mode.icon)
                                    .font(.system(size: 8.5))
                                Text(mode.rawValue)
                                    .font(.system(size: 9.5, weight: viewerMode == mode ? .semibold : .regular))
                            }
                            .foregroundColor(viewerMode == mode ? .white : .white.opacity(0.65))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(
                                Capsule()
                                    .fill(viewerMode == mode ? Color.cyan.opacity(0.28) : Color.clear)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(2)
                .background(Capsule().fill(Color.white.opacity(0.06)))
            }

            Spacer(minLength: 4)

            // Actions
            HStack(spacing: 5) {
                // Ask Genie in Chat
                Button(action: {
                    HapticFeedback.selection()
                    FinderChatWindowManager.shared.stageFile(url: url)
                    NotificationCenter.default.post(
                        name: NSNotification.Name("NexusFocusGenieSearchBarWithMode"),
                        object: "Please analyze the file \(url.lastPathComponent):"
                    )
                }) {
                    HStack(spacing: 3.5) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 9))
                        Text("Chat")
                            .font(.system(size: 9.5, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3.5)
                    .background(Capsule().fill(Color.cyan.opacity(0.35)))
                    .overlay(Capsule().strokeBorder(Color.cyan.opacity(0.6), lineWidth: 0.5))
                }
                .buttonStyle(.plain)
                .help("Stage file & open in Genie Chat")

                // Open with system Default App
                Button(action: {
                    NSWorkspace.shared.open(url)
                }) {
                    Image(systemName: "arrow.up.forward.square")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.85))
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(Color.white.opacity(0.08)))
                }
                .buttonStyle(.plain)
                .help("Open in default system app")

                // Quick Look window
                Button(action: {
                    QuickLookPresenter.shared.present([url], current: url)
                }) {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.85))
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(Color.white.opacity(0.08)))
                }
                .buttonStyle(.plain)
                .help("Open Quick Look window (Spacebar)")

                // Reveal in Finder
                Button(action: {
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                }) {
                    Image(systemName: "folder")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.85))
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(Color.white.opacity(0.08)))
                }
                .buttonStyle(.plain)
                .help("Reveal file in Finder")

                if let close = onClose {
                    Button(action: {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            close()
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundColor(.white.opacity(0.8))
                            .frame(width: 22, height: 22)
                            .background(Circle().fill(Color.white.opacity(0.12)))
                    }
                    .buttonStyle(.plain)
                    .help("Close File Viewer")
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.48))
        .overlay(
            VStack {
                Spacer()
                Divider().background(Color.white.opacity(0.10))
            }
        )
    }

    // MARK: - 🖼️ Visual Preview Body (for Images & Media)
    @ViewBuilder
    private var visualPreviewBody: some View {
        if isImageFile {
            ZStack {
                Color.black.opacity(0.35)

                GenieAnimatedImageView(
                    url: url,
                    scaling: .scaleProportionallyUpOrDown,
                    animates: isPlayingGif,
                    onLoaded: { meta in
                        self.imageMetadata = meta
                    }
                )
                .scaleEffect(imageZoom)
                .padding(12)

                // Zoom controls overlay & metadata pill
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        if let meta = imageMetadata, meta.isAnimated {
                            Button(action: {
                                isPlayingGif.toggle()
                                HapticFeedback.selection()
                            }) {
                                HStack(spacing: 3) {
                                    Image(systemName: isPlayingGif ? "pause.fill" : "play.fill")
                                    Text(isPlayingGif ? "Pause" : "Play")
                                }
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(.pink)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.pink.opacity(0.20)))
                            }
                            .buttonStyle(.plain)
                            .help(isPlayingGif ? "Pause GIF" : "Play GIF")
                        }

                        Button(action: { imageZoom = max(0.25, imageZoom - 0.25) }) {
                            Image(systemName: "minus.magnifyingglass")
                        }
                        .buttonStyle(.plain)

                        Text("\(Int(imageZoom * 100))%")
                            .font(.system(size: 9.5, design: .monospaced))
                            .foregroundColor(.white)

                        Button(action: { imageZoom = min(4.0, imageZoom + 0.25) }) {
                            Image(systemName: "plus.magnifyingglass")
                        }
                        .buttonStyle(.plain)

                        Button("Reset") {
                            withAnimation { imageZoom = 1.0 }
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 9))

                        if let meta = imageMetadata, !meta.dimensionsString.isEmpty {
                            Text("• \(meta.dimensionsString)px")
                                .font(.system(size: 8.5, design: .monospaced))
                                .foregroundColor(.white.opacity(0.65))
                        }
                    }
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.black.opacity(0.75)))
                    .overlay(Capsule().strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5))
                    .padding(.bottom, 8)
                }
            }
        } else {
            QuickLookEmbeddedView(url: url)
        }
    }

    // MARK: - 💻 Code & Text Body
    @ViewBuilder
    private var codeTextBody: some View {
        if isTextLoading {
            VStack(spacing: 8) {
                ProgressView().scaleEffect(0.8)
                Text("Loading source code...")
                    .font(.system(size: 11, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let text = textContent {
            let lines = text.components(separatedBy: "\n")
            ScrollView([.horizontal, .vertical], showsIndicators: true) {
                HStack(alignment: .top, spacing: 0) {
                    // Line numbers
                    VStack(alignment: .trailing, spacing: 3) {
                        ForEach(0..<min(lines.count, 2000), id: \.self) { idx in
                            Text("\(idx + 1)")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.white.opacity(0.28))
                        }
                    }
                    .padding(.leading, 8)
                    .padding(.trailing, 8)
                    .padding(.vertical, 8)
                    .background(Color.black.opacity(0.30))

                    Divider().background(Color.white.opacity(0.08))

                    // Text content
                    VStack(alignment: .leading, spacing: 3) {
                        ForEach(0..<min(lines.count, 2000), id: \.self) { idx in
                            Text(lines[idx].isEmpty ? " " : lines[idx])
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.white.opacity(0.90))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(8)
                }
                .frame(minWidth: 400, alignment: .topLeading)
            }
            .background(Color.black.opacity(0.40))
        } else {
            QuickLookEmbeddedView(url: url)
        }
    }
}
