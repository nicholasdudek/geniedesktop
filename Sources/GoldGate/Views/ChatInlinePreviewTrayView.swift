import AppKit
import SwiftUI

// MARK: - 🗂️ Chat Inline Preview Item Types
public enum ChatInlinePreviewType: Equatable {
    case wallpaper(item: WallpaperItem)
    case customWallpaper(path: String, name: String)
    case theme(id: String, name: String, icon: String)
    case code(fileName: String, code: String, language: String)
    case systemSetting(title: String, paneURL: String, description: String)
    case web(url: URL, title: String)
    case terminal(cmd: String, output: String)
    case visualLookup(image: NSImage, ocrText: String, lineCount: Int, wordCount: Int)
    case tricksterApp(appName: String, profile: VirtualScreenProfile, targetSize: CGSize, slot: Int)
    case creationsGallery

    public static func == (lhs: ChatInlinePreviewType, rhs: ChatInlinePreviewType) -> Bool {
        switch (lhs, rhs) {
        case (.creationsGallery, .creationsGallery):
            return true
        case let (.wallpaper(a), .wallpaper(b)):
            return a.id == b.id
        case let (.customWallpaper(p1, _), .customWallpaper(p2, _)):
            return p1 == p2
        case let (.theme(id1, _, _), .theme(id2, _, _)):
            return id1 == id2
        case let (.code(f1, _, _), .code(f2, _, _)):
            return f1 == f2
        case let (.systemSetting(t1, _, _), .systemSetting(t2, _, _)):
            return t1 == t2
        case let (.web(u1, _), .web(u2, _)):
            return u1 == u2
        case let (.terminal(c1, _), .terminal(c2, _)):
            return c1 == c2
        case let (.visualLookup(img1, text1, _, _), .visualLookup(img2, text2, _, _)):
            return img1 == img2 && text1 == text2
        case let (.tricksterApp(app1, prof1, _, slot1), .tricksterApp(app2, prof2, _, slot2)):
            return app1 == app2 && prof1 == prof2 && slot1 == slot2
        default:
            return false
        }
    }
}

// MARK: - 🕹️ Chat Inline Preview Manager
@MainActor
public final class ChatInlinePreviewManager: ObservableObject {
    public static let shared = ChatInlinePreviewManager()

    @Published public var activePreview: ChatInlinePreviewType? = nil
    @Published public var previewNotice: String? = nil

    /// Most recent creations shown in the tray, newest first, capped to `maxRecentCreations`.
    /// Feeds `.creationsGallery` (see `showCreationsGallery`).
    @Published public private(set) var recentCreations: [ChatInlinePreviewType] = []
    private let maxRecentCreations = 12

    private init() {}

    private func recordCreation(_ preview: ChatInlinePreviewType) {
        recentCreations.removeAll { $0 == preview }
        recentCreations.insert(preview, at: 0)
        if recentCreations.count > maxRecentCreations {
            recentCreations.removeLast(recentCreations.count - maxRecentCreations)
        }
    }

    public func showTricksterAppPreview(appName: String, profile: VirtualScreenProfile, targetSize: CGSize, slot: Int, notice: String? = nil) {
        let preview = ChatInlinePreviewType.tricksterApp(appName: appName, profile: profile, targetSize: targetSize, slot: slot)
        recordCreation(preview)
        withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
            self.activePreview = preview
            self.previewNotice = notice ?? "Virtual Screen Size Spoofed: \(appName) 🎩"
        }
        HapticFeedback.selection()
    }

    public func showVisualLookupPreview(image: NSImage, ocrText: String, lineCount: Int, wordCount: Int, notice: String? = nil) {
        let preview = ChatInlinePreviewType.visualLookup(image: image, ocrText: ocrText, lineCount: lineCount, wordCount: wordCount)
        recordCreation(preview)
        withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
            self.activePreview = preview
            self.previewNotice = notice ?? "Atomic Visual Grounding Active 👁️"
        }
        HapticFeedback.selection()
    }

    public func showWallpaperPreview(item: WallpaperItem, notice: String? = nil) {
        let preview = ChatInlinePreviewType.wallpaper(item: item)
        recordCreation(preview)
        withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
            self.activePreview = preview
            self.previewNotice = notice ?? "Wallpaper Selected 🖼️"
        }
        HapticFeedback.selection()
    }

    public func showCustomWallpaperPreview(path: String, name: String, notice: String? = nil) {
        let preview = ChatInlinePreviewType.customWallpaper(path: path, name: name)
        recordCreation(preview)
        withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
            self.activePreview = preview
            self.previewNotice = notice ?? "Custom Wallpaper Ready 🖼️"
        }
        HapticFeedback.selection()
    }

    public func showCodePreview(fileName: String, code: String, language: String, notice: String? = nil) {
        let preview = ChatInlinePreviewType.code(fileName: fileName, code: code, language: language)
        recordCreation(preview)
        withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
            self.activePreview = preview
            self.previewNotice = notice ?? "Code Generated 💻"
        }
        HapticFeedback.selection()
    }

    public func showSettingPreview(title: String, paneURL: String, description: String, notice: String? = nil) {
        let preview = ChatInlinePreviewType.systemSetting(title: title, paneURL: paneURL, description: description)
        recordCreation(preview)
        withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
            self.activePreview = preview
            self.previewNotice = notice ?? "System Setting Action ⚙️"
        }
        HapticFeedback.selection()
    }

    public func showThemePreview(id: String, name: String, icon: String, notice: String? = nil) {
        let preview = ChatInlinePreviewType.theme(id: id, name: name, icon: icon)
        recordCreation(preview)
        withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
            self.activePreview = preview
            self.previewNotice = notice ?? "Theme Activated 🎨"
        }
        HapticFeedback.selection()
    }

    /// Shows the "latest top artifact creations" gallery: a strip of everything recently
    /// shown in the tray (code, wallpapers, themes, etc.), newest first, tap to reopen.
    public func showCreationsGallery(notice: String? = nil) {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
            self.activePreview = .creationsGallery
            self.previewNotice = notice ?? "Latest Creations ✨"
        }
        HapticFeedback.selection()
    }

    /// Re-opens a past creation from the gallery as the active preview, without re-recording it
    /// (it's already in `recentCreations`).
    public func reopen(_ preview: ChatInlinePreviewType, notice: String? = nil) {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
            self.activePreview = preview
            self.previewNotice = notice
        }
        HapticFeedback.selection()
    }

    public func dismiss() {
        withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
            self.activePreview = nil
            self.previewNotice = nil
        }
        HapticFeedback.tick()
    }
}

// MARK: - 🎬 Chat Inline Preview Tray (Renderer)
// Floats above the chat input bar and renders whatever `ChatInlinePreviewManager.shared`
// is currently showing. Self-contained: drop it into a `ZStack(alignment: .bottom)` in
// any chat surface and it shows/hides itself as `activePreview` changes.
public struct ChatInlinePreviewTrayView: View {
    @ObservedObject private var manager = ChatInlinePreviewManager.shared

    public init() {}

    public var body: some View {
        Group {
            if let preview = manager.activePreview {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(manager.previewNotice ?? "Preview")
                            .font(.system(size: 10.5, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.90))
                            .lineLimit(1)

                        Spacer()

                        Button(action: { manager.dismiss() }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 13))
                                .foregroundColor(.white.opacity(0.55))
                        }
                        .buttonStyle(.plain)
                    }

                    previewContent(for: preview)
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .genieLiquidGlass(cornerRadius: 16, tint: tint(for: preview))
                .padding(.horizontal, 10)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    @ViewBuilder
    private func previewContent(for preview: ChatInlinePreviewType) -> some View {
        switch preview {
        case .wallpaper(let item):
            HStack(spacing: 10) {
                thumbnailImage(WallpaperManager.shared.thumbnail(for: item))
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    Text(item.category.rawValue)
                        .font(.system(size: 9.5, design: .rounded))
                        .foregroundColor(.white.opacity(0.55))
                }
                Spacer()
            }

        case .customWallpaper(let path, let name):
            HStack(spacing: 10) {
                thumbnailImage(NSImage(contentsOfFile: path))
                Text(name)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
            }

        case .theme(_, let name, let icon):
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.cyan)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.white.opacity(0.08)))
                Text(name)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
            }

        case .code(let fileName, let code, let language):
            GenieCodeArtifactView(language: language, code: code, title: fileName)

        case .systemSetting(let title, let paneURL, let description):
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(.white.opacity(0.70))
                    Text(title)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    openButton(title: "Open") {
                        if let url = URL(string: paneURL) { NSWorkspace.shared.open(url) }
                    }
                }
                Text(description)
                    .font(.system(size: 10, design: .rounded))
                    .foregroundColor(.white.opacity(0.60))
            }

        case .web(let url, let title):
            HStack(spacing: 8) {
                Image(systemName: "globe")
                    .foregroundColor(.cyan)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Text(url.absoluteString)
                        .font(.system(size: 9.5, design: .monospaced))
                        .foregroundColor(.white.opacity(0.50))
                        .lineLimit(1)
                }
                Spacer()
                openButton(title: "Open") { NSWorkspace.shared.open(url) }
            }

        case .terminal(let cmd, let output):
            VStack(alignment: .leading, spacing: 4) {
                Text("$ \(cmd)")
                    .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                    .foregroundColor(.green.opacity(0.90))
                    .textSelection(.enabled)
                if !output.isEmpty {
                    ScrollView(.vertical, showsIndicators: true) {
                        Text(verbatim: output)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.white.opacity(0.80))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 100)
                }
            }
            .padding(8)
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.black.opacity(0.35)))

        case .visualLookup(let image, let ocrText, let lineCount, let wordCount):
            HStack(alignment: .top, spacing: 10) {
                thumbnailImage(image, size: 56)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text("\(lineCount) lines")
                        Text("\(wordCount) words")
                    }
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.50))

                    Text(ocrText)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.white.opacity(0.75))
                        .lineLimit(3)
                }
            }

        case .tricksterApp(let appName, let profile, let targetSize, let slot):
            HStack(spacing: 10) {
                Image(systemName: profile.icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.purple)
                    .frame(width: 32, height: 32)
                    .background(Circle().fill(Color.white.opacity(0.08)))
                VStack(alignment: .leading, spacing: 2) {
                    Text(appName)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    Text("\(profile.rawValue) · \(Int(targetSize.width))×\(Int(targetSize.height)) · slot \(slot)")
                        .font(.system(size: 9.5, design: .rounded))
                        .foregroundColor(.white.opacity(0.55))
                        .lineLimit(1)
                }
                Spacer()
            }

        case .creationsGallery:
            galleryContent
        }
    }

    private var galleryContent: some View {
        Group {
            if manager.recentCreations.isEmpty {
                Text("Nothing created yet this session.")
                    .font(.system(size: 10.5, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(manager.recentCreations.enumerated()), id: \.offset) { _, item in
                            Button(action: { manager.reopen(item) }) {
                                galleryCell(for: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private func galleryCell(for item: ChatInlinePreviewType) -> some View {
        VStack(spacing: 4) {
            Image(systemName: galleryIcon(for: item))
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(tint(for: item))
                .frame(width: 40, height: 40)
                .background(Circle().fill(Color.white.opacity(0.08)))
            Text(galleryLabel(for: item))
                .font(.system(size: 8.5, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.65))
                .lineLimit(1)
        }
        .frame(width: 60)
    }

    private func galleryIcon(for item: ChatInlinePreviewType) -> String {
        switch item {
        case .wallpaper, .customWallpaper: return "photo.fill"
        case .theme(_, _, let icon): return icon
        case .code: return "chevron.left.forwardslash.chevron.right"
        case .systemSetting: return "gearshape.fill"
        case .web: return "globe"
        case .terminal: return "terminal.fill"
        case .visualLookup: return "eye.fill"
        case .tricksterApp(_, let profile, _, _): return profile.icon
        case .creationsGallery: return "sparkles"
        }
    }

    private func galleryLabel(for item: ChatInlinePreviewType) -> String {
        switch item {
        case .wallpaper(let wp): return wp.name
        case .customWallpaper(_, let name): return name
        case .theme(_, let name, _): return name
        case .code(let fileName, _, _): return fileName
        case .systemSetting(let title, _, _): return title
        case .web(_, let title): return title
        case .terminal(let cmd, _): return cmd
        case .visualLookup: return "Visual Lookup"
        case .tricksterApp(let appName, _, _, _): return appName
        case .creationsGallery: return "Gallery"
        }
    }

    private func thumbnailImage(_ image: NSImage?, size: CGFloat = 44) -> some View {
        Group {
            if let image {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Color.white.opacity(0.08)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }

    private func openButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            HapticFeedback.selection()
            action()
        }) {
            Text(title)
                .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                .foregroundColor(.cyan)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule().fill(Color.cyan.opacity(0.15)))
        }
        .buttonStyle(.plain)
    }

    private func tint(for preview: ChatInlinePreviewType) -> Color {
        switch preview {
        case .wallpaper, .customWallpaper: return .orange
        case .theme: return .purple
        case .code: return .green
        case .systemSetting: return .white
        case .web: return .cyan
        case .terminal: return .green
        case .visualLookup: return .cyan
        case .tricksterApp: return .purple
        case .creationsGallery: return .cyan
        }
    }
}

