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

    public static func == (lhs: ChatInlinePreviewType, rhs: ChatInlinePreviewType) -> Bool {
        switch (lhs, rhs) {
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

    private init() {}

    public func showTricksterAppPreview(appName: String, profile: VirtualScreenProfile, targetSize: CGSize, slot: Int, notice: String? = nil) {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
            self.activePreview = .tricksterApp(appName: appName, profile: profile, targetSize: targetSize, slot: slot)
            self.previewNotice = notice ?? "Virtual Screen Size Spoofed: \(appName) 🎩"
        }
        HapticFeedback.selection()
    }

    public func showVisualLookupPreview(image: NSImage, ocrText: String, lineCount: Int, wordCount: Int, notice: String? = nil) {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
            self.activePreview = .visualLookup(image: image, ocrText: ocrText, lineCount: lineCount, wordCount: wordCount)
            self.previewNotice = notice ?? "Atomic Visual Grounding Active 👁️"
        }
        HapticFeedback.selection()
    }

    public func showWallpaperPreview(item: WallpaperItem, notice: String? = nil) {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
            self.activePreview = .wallpaper(item: item)
            self.previewNotice = notice ?? "Wallpaper Selected 🖼️"
        }
        HapticFeedback.selection()
    }

    public func showCustomWallpaperPreview(path: String, name: String, notice: String? = nil) {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
            self.activePreview = .customWallpaper(path: path, name: name)
            self.previewNotice = notice ?? "Custom Wallpaper Ready 🖼️"
        }
        HapticFeedback.selection()
    }

    public func showCodePreview(fileName: String, code: String, language: String, notice: String? = nil) {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
            self.activePreview = .code(fileName: fileName, code: code, language: language)
            self.previewNotice = notice ?? "Code Generated 💻"
        }
        HapticFeedback.selection()
    }

    public func showSettingPreview(title: String, paneURL: String, description: String, notice: String? = nil) {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
            self.activePreview = .systemSetting(title: title, paneURL: paneURL, description: description)
            self.previewNotice = notice ?? "System Setting Action ⚙️"
        }
        HapticFeedback.selection()
    }

    public func showThemePreview(id: String, name: String, icon: String, notice: String? = nil) {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
            self.activePreview = .theme(id: id, name: name, icon: icon)
            self.previewNotice = notice ?? "Theme Activated 🎨"
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

// MARK: - 🪟 Chat Inline Preview Tray View (Floats Above Search Bar)
public struct ChatInlinePreviewTrayView: View {
    @ObservedObject var previewManager = ChatInlinePreviewManager.shared
    @ObservedObject var wallpaperManager = WallpaperManager.shared

    public init() {}

    public var body: some View {
        if let preview = previewManager.activePreview {
            VStack(spacing: 0) {
                // Top Header Notice & Dismiss
                HStack(spacing: 8) {
                    Image(systemName: headerIcon(for: preview))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(headerTint(for: preview))

                    Text(previewManager.previewNotice ?? "INLINE LIVE PREVIEW")
                        .font(.system(size: 10, weight: .heavy, design: .monospaced))
                        .foregroundColor(.white.opacity(0.85))

                    Spacer()

                    Button(action: {
                        previewManager.dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.45))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Dismiss Inline Preview")
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)
                .padding(.bottom, 6)

                Divider().background(Color.white.opacity(0.12))

                // Preview Card Body Content
                Group {
                    switch preview {
                    case let .wallpaper(item):
                        wallpaperPreviewCard(item: item)
                    case let .customWallpaper(path, name):
                        customWallpaperPreviewCard(path: path, name: name)
                    case let .code(fileName, code, language):
                        codePreviewCard(fileName: fileName, code: code, language: language)
                    case let .systemSetting(title, paneURL, description):
                        systemSettingPreviewCard(title: title, paneURL: paneURL, description: description)
                    case let .theme(id, name, icon):
                        themePreviewCard(id: id, name: name, icon: icon)
                    case let .web(url, title):
                        webPreviewCard(url: url, title: title)
                    case let .terminal(cmd, output):
                        terminalPreviewCard(cmd: cmd, output: output)
                    case let .visualLookup(image, ocrText, lineCount, wordCount):
                        visualLookupPreviewCard(image: image, ocrText: ocrText, lineCount: lineCount, wordCount: wordCount)
                    case let .tricksterApp(appName, profile, targetSize, slot):
                        tricksterAppPreviewCard(appName: appName, profile: profile, targetSize: targetSize, slot: slot)
                    }
                }
                .padding(10)
            }
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color(red: 0.10, green: 0.12, blue: 0.16).opacity(0.96))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [headerTint(for: preview).opacity(0.6), Color.white.opacity(0.12)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.45), radius: 14, x: 0, y: 6)
            .padding(.horizontal, 14)
            .padding(.bottom, 6)
            .transition(.move(edge: .bottom).combined(with: .opacity))
        }
    }

    // MARK: - 🖼️ Wallpaper Preview Card
    private func wallpaperPreviewCard(item: WallpaperItem) -> some View {
        HStack(spacing: 12) {
            // High-Res Thumbnail Image
            if let thumb = wallpaperManager.thumbnail(for: item) {
                Image(nsImage: thumb)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 90, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.white.opacity(0.25), lineWidth: 0.8)
                    )
            } else {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 90, height: 56)
                    .overlay(
                        Image(systemName: "mountain.2.fill")
                            .foregroundColor(.white.opacity(0.7))
                    )
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(item.name)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text("Category: \(item.category.rawValue) • 4K Resolution")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.55))

                HStack(spacing: 6) {
                    Button(action: {
                        WallpaperManager.shared.setSystemWallpaper(path: item.path)
                        previewManager.previewNotice = "Applied \(item.name) to Desktop! ✨"
                        HapticFeedback.heavy()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 9.5))
                            Text("Set as Wallpaper")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.blue.opacity(0.85)))
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: {
                        cycleNextWallpaper(currentItem: item)
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "forward.fill")
                                .font(.system(size: 8))
                            Text("Next")
                                .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.white.opacity(0.12)))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.top, 2)
            }

            Spacer()
        }
    }

    // MARK: - 🖼️ Custom Wallpaper Preview Card
    private func customWallpaperPreviewCard(path: String, name: String) -> some View {
        HStack(spacing: 12) {
            if let img = NSImage(contentsOfFile: path) {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 90, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.white.opacity(0.25), lineWidth: 0.8)
                    )
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(name)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("Custom Image • \(path)")
                    .font(.system(size: 9.5))
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(1)

                Button(action: {
                    WallpaperManager.shared.setSystemWallpaper(path: path)
                    previewManager.previewNotice = "Desktop Wallpaper Updated! ✨"
                }) {
                    Text("Apply to Desktop 🖼️")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.blue))
                }
                .buttonStyle(PlainButtonStyle())
            }
            Spacer()
        }
    }

    // MARK: - 💻 Code Snippet Preview Card
    private func codePreviewCard(fileName: String, code: String, language: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Image(systemName: "curlybraces.square.fill")
                    .foregroundColor(Color(red: 0.95, green: 0.45, blue: 0.20))
                Text(fileName)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Spacer()
                Button(action: {
                    MovablePopupManager.shared.openPopup(id: "vscode", title: "VS Code Studio", icon: "curlybraces.square.fill", tint: Color(red: 0.95, green: 0.45, blue: 0.20), initialSize: CGSize(width: 720, height: 480))
                }) {
                    Text("Open in VS Code 💻")
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundColor(.cyan)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.cyan.opacity(0.15)))
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(code, forType: .string)
                    previewManager.previewNotice = "Code Copied to Clipboard! 📋"
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.7))
                }
                .buttonStyle(PlainButtonStyle())
            }

            Text(code.prefix(200) + (code.count > 200 ? "..." : ""))
                .font(.system(size: 10, weight: .regular, design: .monospaced))
                .foregroundColor(.white.opacity(0.8))
                .lineLimit(3)
                .padding(6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.black.opacity(0.35)))
        }
    }

    // MARK: - ⚙️ System Setting Preview Card
    private func systemSettingPreviewCard(title: String, paneURL: String, description: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 20))
                .foregroundColor(.cyan)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color.cyan.opacity(0.15)))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(description)
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(2)
            }

            Spacer()

            Button(action: {
                if let url = URL(string: paneURL) {
                    NSWorkspace.shared.open(url)
                }
                previewManager.previewNotice = "Opened \(title) Pane ⚙️"
            }) {
                Text("Open Settings ↗")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.cyan.opacity(0.85)))
            }
            .buttonStyle(PlainButtonStyle())
        }
    }

    // MARK: - 🎨 Theme Preview Card
    private func themePreviewCard(id: String, name: String, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(.purple)
                .frame(width: 40, height: 40)
                .background(Circle().fill(Color.purple.opacity(0.18)))

            VStack(alignment: .leading, spacing: 2) {
                Text("Theme: \(name)")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("Real-time GPU Shader & Visual Material")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.6))
            }
            Spacer()
        }
    }

    // MARK: - 🌐 Web Preview Card
    private func webPreviewCard(url: URL, title: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "globe")
                .foregroundColor(.blue)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                Text(url.absoluteString)
                    .font(.system(size: 9.5))
                    .foregroundColor(.white.opacity(0.55))
                    .lineLimit(1)
            }
            Spacer()
            Button("Open Browser 🌐") {
                MiniBrowserManager.shared.browse(url: url)
                MovablePopupManager.shared.openPopup(id: "browser", title: "Mini Browser", icon: "globe", tint: .blue, initialSize: CGSize(width: 680, height: 460))
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.mini)
        }
    }

    // MARK: - 💻 Terminal Preview Card
    private func terminalPreviewCard(cmd: String, output: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("$ \(cmd)")
                    .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                    .foregroundColor(.green)
                Spacer()
                Button("Open Terminal ⚡️") {
                    MovablePopupManager.shared.openPopup(id: "terminal", title: "Terminal Shell", icon: "terminal.fill", tint: .green, initialSize: CGSize(width: 640, height: 420))
                }
                .buttonStyle(.bordered)
                .controlSize(.mini)
            }
            Text(output.prefix(180))
                .font(.system(size: 9.5, design: .monospaced))
                .foregroundColor(.white.opacity(0.75))
                .lineLimit(2)
        }
    }

    // MARK: - 👁️ Atomic Visual Lookup Preview Card
    @ViewBuilder
    private func visualLookupPreviewCard(image: NSImage, ocrText: String, lineCount: Int, wordCount: Int) -> some View {
        HStack(spacing: 12) {
            // High-Res Retina Framebuffer Snapshot
            Image(nsImage: image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: 90, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color.cyan.opacity(0.8), Color.purple.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                )
                .shadow(color: Color.cyan.opacity(0.3), radius: 6, x: 0, y: 2)

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("Apple Vision OCR")
                        .font(.system(size: 11.5, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("• \(wordCount) words, \(lineCount) lines")
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.cyan)
                }

                Text(ocrText.prefix(140).replacingOccurrences(of: "\n", with: " "))
                    .font(.system(size: 9.5, weight: .regular, design: .monospaced))
                    .foregroundColor(.white.opacity(0.75))
                    .lineLimit(2)

                HStack(spacing: 6) {
                    Button(action: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(ocrText, forType: .string)
                        previewManager.previewNotice = "OCR Text Copied to Clipboard! 📋"
                        HapticFeedback.selection()
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 8.5))
                            Text("Copy OCR")
                                .font(.system(size: 9.5, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3.5)
                        .background(Capsule().fill(Color.cyan.opacity(0.75)))
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: {
                        _ = DesktopNotePrinter.shared.saveMarkdownToDesktop(content: "# Screen Capture OCR\n\n\(ocrText)")
                        previewManager.previewNotice = "Saved Optical Note to Desktop 📄"
                        HapticFeedback.playPrinterSound()
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "note.text.badge.plus")
                                .font(.system(size: 8.5))
                            Text("Save Note")
                                .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3.5)
                        .background(Capsule().fill(Color.white.opacity(0.12)))
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: {
                        Task {
                            _ = await GenieVisionEngine.shared.scanActiveScreenAndRecognize()
                        }
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 8.5))
                            Text("Re-Scan")
                                .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3.5)
                        .background(Capsule().fill(Color.white.opacity(0.12)))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.top, 2)
            }

            Spacer()
        }
    }

    // MARK: - 🎩 Virtual Screen Size Trickster Preview Card
    private func tricksterAppPreviewCard(appName: String, profile: VirtualScreenProfile, targetSize: CGSize, slot: Int) -> some View {
        HStack(spacing: 12) {
            Image(systemName: profile.icon)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.orange)
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color.orange.opacity(0.18)))

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(appName)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Slot \(slot) / 9")
                        .font(.system(size: 10, weight: .heavy, design: .monospaced))
                        .foregroundColor(.orange)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1.5)
                        .background(Capsule().fill(Color.orange.opacity(0.2)))
                }

                Text("Spoofed Size: \(Int(targetSize.width)) × \(Int(targetSize.height)) pt • \(profile.rawValue)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.65))

                HStack(spacing: 6) {
                    Button(action: {
                        Task {
                            await AppScreenSizeTricksterEngine.shared.launchWithSpoofedScreenSize(
                                appName: appName,
                                profile: profile,
                                slotIndex: slot
                            )
                        }
                    }) {
                        Text("Re-Launch Compact 🚀")
                            .font(.system(size: 9.5, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3.5)
                            .background(Capsule().fill(Color.orange.opacity(0.85)))
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: {
                        MovablePopupManager.shared.openPopup(id: "matrix3x3", title: "3×3 Program Matrix", icon: "square.grid.3x3.fill", tint: .cyan, initialSize: CGSize(width: 760, height: 520))
                    }) {
                        Text("View Matrix ▦")
                            .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.85))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3.5)
                            .background(Capsule().fill(Color.white.opacity(0.12)))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.top, 2)
            }

            Spacer()
        }
    }

    private func cycleNextWallpaper(currentItem: WallpaperItem) {
        let all = wallpaperManager.availableWallpapers
        guard !all.isEmpty else { return }
        if let idx = all.firstIndex(where: { $0.id == currentItem.id }) {
            let nextIdx = (idx + 1) % all.count
            let nextItem = all[nextIdx]
            previewManager.showWallpaperPreview(item: nextItem, notice: "Previewing: \(nextItem.name)")
        } else if let first = all.first {
            previewManager.showWallpaperPreview(item: first, notice: "Previewing: \(first.name)")
        }
    }

    private func headerIcon(for preview: ChatInlinePreviewType) -> String {
        switch preview {
        case .wallpaper, .customWallpaper: return "mountain.2.fill"
        case .theme: return "paintpalette.fill"
        case .code: return "curlybraces"
        case .systemSetting: return "gearshape.fill"
        case .web: return "globe"
        case .terminal: return "terminal.fill"
        case .visualLookup: return "eye.circle.fill"
        case .tricksterApp: return "macmini.fill"
        }
    }

    private func headerTint(for preview: ChatInlinePreviewType) -> Color {
        switch preview {
        case .wallpaper, .customWallpaper: return .blue
        case .theme: return .purple
        case .code: return Color(red: 0.95, green: 0.45, blue: 0.20)
        case .systemSetting: return .cyan
        case .web: return .blue
        case .terminal: return .green
        case .visualLookup: return .cyan
        case .tricksterApp: return .orange
        }
    }
}
