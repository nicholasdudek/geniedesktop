import AppKit
import SwiftUI
import CoreGraphics
import WebKit

// MARK: - 🪟 App Window Hover Preview Card
/// Popover preview card providing live window capture, window title, and quick actions (Bring Front, Summarize, Open Tab, Quit),
/// plus embedded Live Browser & Streaming preview (Netflix, YouTube, Twitch, etc.).
public struct AppWindowHoverPreviewCard: View {
    public let pid: pid_t
    public let name: String
    public let icon: NSImage?
    public let bundleId: String?
    public let runningApp: NSRunningApplication?
    public var onDismiss: (() -> Void)? = nil

    @State private var windowThumbnail: NSImage? = nil
    @State private var windowTitle: String? = nil
    @State private var isCapturing: Bool = false
    @State private var isSummarizing: Bool = false

    // Live Web & Streaming State (Netflix, YouTube, etc.)
    @State private var isLiveBrowserActive: Bool = false
    @State private var activeStreamURL: URL? = URL(string: "https://www.netflix.com")
    @State private var isBrowserLoading: Bool = false
    @State private var canBrowserGoBack: Bool = false
    @State private var canBrowserGoForward: Bool = false
    @State private var browserPageTitle: String = "Netflix"

    public init(
        pid: pid_t,
        name: String,
        icon: NSImage?,
        bundleId: String?,
        runningApp: NSRunningApplication?,
        onDismiss: (() -> Void)? = nil
    ) {
        self.pid = pid
        self.name = name
        self.icon = icon
        self.bundleId = bundleId
        self.runningApp = runningApp
        self.onDismiss = onDismiss
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            // Header Row: App Icon + Name + Badges + Stream Toggle
            HStack(spacing: 8) {
                if let ic = icon {
                    Image(nsImage: ic)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 24, height: 24)
                        .shadow(color: .black.opacity(0.35), radius: 2)
                }

                VStack(alignment: .leading, spacing: 1.5) {
                    HStack(spacing: 5) {
                        Text(name)
                            .font(.system(size: 12.5, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text("PID \(pid)")
                            .font(.system(size: 8.5, weight: .semibold, design: .monospaced))
                            .foregroundColor(.cyan.opacity(0.9))
                            .padding(.horizontal, 4.5)
                            .padding(.vertical, 1.5)
                            .background(Capsule().fill(Color.cyan.opacity(0.14)))
                    }

                    if let title = windowTitle, !title.isEmpty {
                        Text(title)
                            .font(.system(size: 9.5, weight: .regular))
                            .foregroundColor(.white.opacity(0.70))
                            .lineLimit(1)
                    } else {
                        Text("Background Application")
                            .font(.system(size: 9.5, weight: .regular))
                            .foregroundColor(.white.opacity(0.45))
                    }
                }

                Spacer()

                // Quick Stream Switcher Pill
                Button(action: {
                    HapticFeedback.selection()
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        isLiveBrowserActive.toggle()
                    }
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: isLiveBrowserActive ? "macwindow" : "play.tv.fill")
                            .font(.system(size: 8))
                        Text(isLiveBrowserActive ? "Window" : "Stream")
                            .font(.system(size: 8.5, weight: .bold))
                    }
                    .foregroundColor(isLiveBrowserActive ? .black : .white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2.5)
                    .background(Capsule().fill(isLiveBrowserActive ? Color.cyan : Color.red.opacity(0.85)))
                }
                .buttonStyle(.plain)
                .help(isLiveBrowserActive ? "Switch back to App Window snapshot" : "Activate Live Stream / Browser (Netflix, YouTube, etc.)")
            }

            // Window Thumbnail Preview OR Live Streaming Browser
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.black.opacity(0.55))
                    .frame(height: isLiveBrowserActive ? 155 : 120)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(isLiveBrowserActive ? Color.cyan.opacity(0.40) : Color.white.opacity(0.12), lineWidth: 0.8)
                    )

                if isLiveBrowserActive {
                    VStack(spacing: 0) {
                        // Mini Streaming Preset Header
                        HStack(spacing: 4) {
                            streamPresetChip(label: "🍿 Netflix", url: "https://www.netflix.com")
                            streamPresetChip(label: "▶️ YouTube", url: "https://www.youtube.com")
                            streamPresetChip(label: "📺 Twitch", url: "https://www.twitch.tv")

                            Spacer()

                            // Pop out to Full Live Browser Window
                            Button(action: {
                                HapticFeedback.selection()
                                FinderChatWindowManager.shared.show(tab: .browser)
                                onDismiss?()
                            }) {
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.white.opacity(0.85))
                                    .frame(width: 18, height: 18)
                                    .background(Circle().fill(Color.white.opacity(0.12)))
                            }
                            .buttonStyle(.plain)
                            .help("Pop out to Full Screen Genie Browser Cradle")
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(Color.black.opacity(0.70))

                        // Live Native WKWebView
                        NativeWKWebView(
                            url: activeStreamURL,
                            isLoading: $isBrowserLoading,
                            canGoBack: $canBrowserGoBack,
                            canGoForward: $canBrowserGoForward,
                            title: $browserPageTitle
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                } else if let thumb = windowThumbnail {
                    Image(nsImage: thumb)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 116)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                } else if isCapturing {
                    HStack(spacing: 6) {
                        ProgressView()
                            .scaleEffect(0.65)
                        Text("Capturing Window...")
                            .font(.system(size: 9.5, weight: .medium))
                            .foregroundColor(.white.opacity(0.55))
                    }
                } else {
                    VStack(spacing: 4) {
                        Image(systemName: "macwindow")
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.3))
                        Text("No active window on screen")
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
            }
            .frame(width: isLiveBrowserActive ? 256 : 230, height: isLiveBrowserActive ? 155 : 120)

            // Quick Actions Button Grid
            VStack(spacing: 5) {
                HStack(spacing: 6) {
                    // Bring to Front
                    Button(action: {
                        HapticFeedback.selection()
                        runningApp?.unhide()
                        _ = runningApp?.activate(options: [.activateAllWindows])
                        if let app = runningApp {
                            SmartGridManager.shared.bringToFront(app: app)
                        }
                        onDismiss?()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.forward.app")
                            Text("Bring Front")
                        }
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4.5)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.12)))
                    }
                    .buttonStyle(.plain)

                    // Summarize with Genie Vision OCR
                    Button(action: {
                        HapticFeedback.selection()
                        summarizeWithGenie()
                    }) {
                        HStack(spacing: 4) {
                            if isSummarizing {
                                ProgressView().scaleEffect(0.55)
                            } else {
                                Image(systemName: "sparkles")
                            }
                            Text("Summarize")
                        }
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.cyan)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4.5)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.cyan.opacity(0.15)))
                    }
                    .buttonStyle(.plain)
                }

                HStack(spacing: 6) {
                    // Watch Stream / Toggle Browser
                    Button(action: {
                        HapticFeedback.selection()
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                            isLiveBrowserActive.toggle()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: isLiveBrowserActive ? "macwindow" : "play.tv.fill")
                            Text(isLiveBrowserActive ? "Window Mode" : "Watch Stream")
                        }
                        .font(.system(size: 9.5, weight: .medium))
                        .foregroundColor(isLiveBrowserActive ? .cyan : .white.opacity(0.9))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                        .background(RoundedRectangle(cornerRadius: 6).fill(isLiveBrowserActive ? Color.cyan.opacity(0.18) : Color.red.opacity(0.18)))
                    }
                    .buttonStyle(.plain)

                    // Open as Chat Tab
                    Button(action: {
                        HapticFeedback.selection()
                        FinderChatWindowManager.shared.show(tab: .app(bundleId: bundleId ?? name, name: name))
                        onDismiss?()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.rectangle.on.rectangle")
                            Text("Open Tab")
                        }
                        .font(.system(size: 9.5, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.08)))
                    }
                    .buttonStyle(.plain)
                }

                HStack(spacing: 6) {
                    // Quit App
                    Button(action: {
                        HapticFeedback.selection()
                        runningApp?.terminate()
                        onDismiss?()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle")
                            Text("Quit")
                        }
                        .font(.system(size: 9.5, weight: .medium))
                        .foregroundColor(.red.opacity(0.9))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 4)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.red.opacity(0.10)))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(10)
        .frame(width: isLiveBrowserActive ? 276 : 250)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.black.opacity(0.78))
                .overlay(
                    VisualEffectBlur(material: .popover, blendingMode: .withinWindow, state: .active)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .opacity(0.35)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.8)
                )
        )
        .onAppear {
            capturePreview()
        }
    }

    private func streamPresetChip(label: String, url: String) -> some View {
        Button(action: {
            HapticFeedback.selection()
            if let target = URL(string: url) {
                activeStreamURL = target
                MiniBrowserManager.shared.activeWebView?.load(URLRequest(url: target))
            }
        }) {
            Text(label)
                .font(.system(size: 8, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 4.5)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color.white.opacity(0.14)))
        }
        .buttonStyle(.plain)
    }

    private func capturePreview() {
        isCapturing = true
        Task {
            guard let winList = CGWindowListCopyWindowInfo([.optionAll, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
                await MainActor.run { isCapturing = false }
                return
            }

            var foundWid: CGWindowID? = nil
            var title: String? = nil

            for info in winList {
                if let ownerPID = info[kCGWindowOwnerPID as String] as? pid_t, ownerPID == pid,
                   let wid = info[kCGWindowNumber as String] as? CGWindowID {
                    if let boundsDict = info[kCGWindowBounds as String] as? [String: Any],
                       let w = boundsDict["Width"] as? CGFloat, w > 80,
                       let h = boundsDict["Height"] as? CGFloat, h > 80 {
                        foundWid = wid
                        title = info[kCGWindowName as String] as? String
                        break
                    }
                }
            }

            var captured: NSImage? = nil
            if let wid = foundWid,
               let cgImg = safeCGWindowListCreateImage(.null, .optionIncludingWindow, wid, [.bestResolution, .nominalResolution]) {
                captured = NSImage(cgImage: cgImg, size: NSSize(width: cgImg.width, height: cgImg.height))
            }

            await MainActor.run {
                self.windowThumbnail = captured
                self.windowTitle = title
                self.isCapturing = false
            }
        }
    }

    private func summarizeWithGenie() {
        isSummarizing = true
        Task {
            let (_, title, ocr) = await GenieVisionEngine.shared.scanAppWindowAndRecognize(pid: pid)
            await MainActor.run {
                self.isSummarizing = false
                FinderChatWindowManager.shared.show(tab: .chat)

                let titleInfo = (title != nil && !title!.isEmpty) ? " (Window: \"\(title!)\")" : ""
                let query: String
                if !ocr.isEmpty {
                    let preview = String(ocr.prefix(350)).replacingOccurrences(of: "\n", with: " ")
                    query = "Summarize what is open in \(name)\(titleInfo). Text content preview: \"\(preview)\""
                } else {
                    query = "Summarize what is currently open in \(name)\(titleInfo)."
                }

                NotificationCenter.default.post(
                    name: NSNotification.Name("GenieSetChatPromptText"),
                    object: query
                )
                NotificationCenter.default.post(
                    name: NSNotification.Name("NexusSearchBarAppendText"),
                    object: query
                )
                onDismiss?()
            }
        }
    }
}
