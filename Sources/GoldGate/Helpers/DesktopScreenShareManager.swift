import AppKit
import CoreGraphics
import ScreenCaptureKit
import SwiftUI

// MARK: - Shared Window Item Model
public struct SharedStreamWindowItem: Identifiable, Hashable {
    public let id: CGWindowID
    public let title: String
    public let appName: String
    public let bundleID: String
    public let bounds: CGRect

    public init(id: CGWindowID, title: String, appName: String, bundleID: String, bounds: CGRect) {
        self.id = id
        self.title = title
        self.appName = appName
        self.bundleID = bundleID
        self.bounds = bounds
    }
}

// MARK: - Floating / Drop-Down NSPanel
public final class DesktopScreenSharePanel: NSPanel {
    public init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .resizable, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        // Level 28: Stays securely over regular desktop windows so you can work under it
        self.level = NSWindow.Level(Int(CGWindowLevelForKey(.floatingWindow)) + 2)
        // Joins all spaces so it can stream Desktop 2 while sitting on Desktop 1
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        self.isExcludedFromWindowsMenu = true
        self.sharingType = .readOnly
        self.hidesOnDeactivate = false
        self.canHide = false
        self.isMovableByWindowBackground = true
        self.acceptsMouseMovedEvents = true
        self.isReleasedWhenClosed = false
    }

    public override var canBecomeKey: Bool { true }
    public override var canBecomeMain: Bool { false }
}

// MARK: - Desktop Screen Share Manager
@MainActor
public final class DesktopScreenShareManager: ObservableObject {
    public static let shared = DesktopScreenShareManager()

    @Published public private(set) var isVisible: Bool = false
    @Published public var targetSpaceIndex: Int = 2
    @Published public var isDropDownMode: Bool = true
    @Published public var currentFrame: NSImage?
    @Published public var isPaused: Bool = false
    @Published public var pipOpacity: Double = 0.98
    @Published public var selectedWindowID: CGWindowID? = nil
    @Published public var availableWindows: [SharedStreamWindowItem] = []
    @Published public var isAudioSynced: Bool = true

    private var panel: DesktopScreenSharePanel?
    private var streamTimer: Timer?
    private var isCapturing: Bool = false

    private init() {
        refreshAvailableWindows()
    }

    // MARK: - Toggle & Show
    public func toggle(targetSpaceIndex: Int = 2) {
        if isVisible {
            dismiss()
        } else {
            showDropDown(targetSpaceIndex: targetSpaceIndex)
        }
    }

    public func showDropDown(targetSpaceIndex: Int = 2) {
        self.targetSpaceIndex = targetSpaceIndex
        self.isDropDownMode = true
        presentPanel()
    }

    public func showFloatingPiP(targetSpaceIndex: Int = 2) {
        self.targetSpaceIndex = targetSpaceIndex
        self.isDropDownMode = false
        presentPanel()
    }

    public func dismiss() {
        stopStream()
        guard let p = panel else {
            isVisible = false
            return
        }

        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.18
            ctx.timingFunction = CAMediaTimingFunction(controlPoints: 0.16, 1.0, 0.3, 1.0)
            p.animator().alphaValue = 0.0
            if isDropDownMode {
                var f = p.frame
                f.origin.y += 24
                p.animator().setFrame(f, display: true)
            }
        }, completionHandler: { [weak self] in
            p.orderOut(nil)
            Task { @MainActor [weak self] in
                self?.isVisible = false
            }
        })
    }

    // MARK: - Present Panel
    private func presentPanel() {
        let screen = NSScreen.main ?? (NSScreen.screens.first ?? NSScreen())
        let visFrame = screen.visibleFrame

        let pipWidth: CGFloat = isDropDownMode ? 460 : 400
        let pipHeight: CGFloat = (pipWidth * 10.0 / 16.0) + 42.0

        let posX: CGFloat = {
            if isDropDownMode {
                // Drop down right below the top menu bar / notch
                return visFrame.midX - (pipWidth / 2.0)
            } else {
                // Hover in upper-right corner of Desktop 1
                return visFrame.maxX - pipWidth - 24
            }
        }()

        let posY: CGFloat = {
            if isDropDownMode {
                return visFrame.maxY - pipHeight - 6
            } else {
                return visFrame.maxY - pipHeight - 40
            }
        }()

        let finalFrame = NSRect(x: posX, y: posY, width: pipWidth, height: pipHeight)

        if panel == nil {
            let newPanel = DesktopScreenSharePanel(contentRect: finalFrame)
            let hostView = NSHostingView(rootView: DesktopScreenSharePiPView(manager: self))
            newPanel.contentView = hostView
            self.panel = newPanel
        } else {
            panel?.setFrame(finalFrame, display: true)
        }

        guard let p = panel else { return }

        let startFrame = NSRect(
            x: posX,
            y: isDropDownMode ? posY + 35 : posY + 15,
            width: pipWidth,
            height: pipHeight
        )
        p.setFrame(startFrame, display: false)
        p.alphaValue = 0.0
        p.orderFrontRegardless()
        p.makeKeyAndOrderFront(nil)

        isVisible = true
        startStream()

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.26
            ctx.timingFunction = CAMediaTimingFunction(controlPoints: 0.16, 1.0, 0.3, 1.0)
            p.animator().setFrame(finalFrame, display: true)
            p.animator().alphaValue = CGFloat(pipOpacity)
        }
    }

    // MARK: - Stream Engine (ScreenCaptureKit & Quartz Live Capture)
    public func startStream() {
        stopStream()
        isPaused = false
        refreshAvailableWindows()

        // 24 FPS Live Video Stream Loop
        streamTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 24.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, self.isVisible, !self.isPaused, !self.isCapturing else { return }
                self.captureFrame()
            }
        }
    }

    public func stopStream() {
        streamTimer?.invalidate()
        streamTimer = nil
        isCapturing = false
    }

    public func togglePause() {
        isPaused.toggle()
        if !isPaused && streamTimer == nil {
            startStream()
        }
    }

    public func refreshAvailableWindows() {
        guard CGPreflightScreenCaptureAccess() else { return }
        Task {
            do {
                let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: false)
                var items: [SharedStreamWindowItem] = []
                for win in content.windows {
                    let title = win.title ?? ""
                    let appName = win.owningApplication?.applicationName ?? ""
                    let bundle = win.owningApplication?.bundleIdentifier ?? ""
                    // Filter out invisible or tiny auxiliary windows
                    if win.frame.width > 200 && win.frame.height > 150 && !title.isEmpty {
                        items.append(SharedStreamWindowItem(
                            id: win.windowID,
                            title: title,
                            appName: appName,
                            bundleID: bundle,
                            bounds: win.frame
                        ))
                    }
                }
                self.availableWindows = items
            } catch {
                // Fallback to Quartz window info
                let list = CGWindowListCopyWindowInfo([.optionAll, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []
                var items: [SharedStreamWindowItem] = []
                for entry in list {
                    let wid = entry[kCGWindowNumber as String] as? CGWindowID ?? 0
                    let title = entry[kCGWindowName as String] as? String ?? ""
                    let appName = entry[kCGWindowOwnerName as String] as? String ?? ""
                    let boundsDict = entry[kCGWindowBounds as String] as? [String: CGFloat] ?? [:]
                    let w = boundsDict["Width"] ?? 0
                    let h = boundsDict["Height"] ?? 0
                    if w > 200 && h > 150 && !title.isEmpty {
                        let rect = CGRect(x: boundsDict["X"] ?? 0, y: boundsDict["Y"] ?? 0, width: w, height: h)
                        items.append(SharedStreamWindowItem(
                            id: wid,
                            title: title,
                            appName: appName,
                            bundleID: "",
                            bounds: rect
                        ))
                    }
                }
                self.availableWindows = items
            }
        }
    }

    private func captureFrame() {
        guard !isCapturing else { return }
        isCapturing = true

        let targetWid = selectedWindowID
        let spaceImg = MacDesktopsManager.shared.desktopLivePreviews[targetSpaceIndex]
        let screen = NSScreen.main ?? (NSScreen.screens.first ?? NSScreen())
        let screenBounds = screen.frame

        Task.detached(priority: .high) { [weak self] in
            defer {
                Task { @MainActor [weak self] in
                    self?.isCapturing = false
                }
            }

            var capturedImage: NSImage? = nil

            if let wid = targetWid {
                if let cgImg = safeCGWindowListCreateImage(.null, .optionIncludingWindow, wid, [.nominalResolution]) {
                    capturedImage = NSImage(cgImage: cgImg, size: NSSize(width: cgImg.width, height: cgImg.height))
                }
            }

            if capturedImage == nil {
                capturedImage = spaceImg
            }

            if capturedImage == nil {
                if let cgImg = safeCGWindowListCreateImage(screenBounds, .optionOnScreenOnly, kCGNullWindowID, [.nominalResolution]) {
                    capturedImage = NSImage(cgImage: cgImg, size: NSSize(width: 480, height: 300))
                }
            }

            if let img = capturedImage {
                Task { @MainActor [weak self] in
                    self?.currentFrame = img
                }
            }
        }
    }
}

// MARK: - Modern Liquid Glass PiP View
public struct DesktopScreenSharePiPView: View {
    @ObservedObject var manager: DesktopScreenShareManager
    @State private var isHovered: Bool = false
    @State private var showSettings: Bool = false

    public var body: some View {
        VStack(spacing: 0) {
            // ── LIQUID GLASS TITLE BAR ──
            HStack(spacing: 8) {
                // Window Action Dots
                HStack(spacing: 5) {
                    Button(action: {
                        HapticFeedback.selection()
                        manager.dismiss()
                    }) {
                        Circle()
                            .fill(Color.red.opacity(0.85))
                            .frame(width: 10, height: 10)
                            .overlay(
                                Image(systemName: "xmark")
                                    .font(.system(size: 6, weight: .black))
                                    .foregroundColor(.black.opacity(0.6))
                                    .opacity(isHovered ? 1.0 : 0.0)
                            )
                    }
                    .buttonStyle(.plain)
                    .help("Close Screen Share")

                    Button(action: {
                        HapticFeedback.selection()
                        manager.togglePause()
                    }) {
                        Circle()
                            .fill(manager.isPaused ? Color.gray : Color.yellow.opacity(0.85))
                            .frame(width: 10, height: 10)
                            .overlay(
                                Image(systemName: manager.isPaused ? "play.fill" : "pause.fill")
                                    .font(.system(size: 5, weight: .bold))
                                    .foregroundColor(.black.opacity(0.6))
                                    .opacity(isHovered ? 1.0 : 0.0)
                            )
                    }
                    .buttonStyle(.plain)
                    .help(manager.isPaused ? "Resume Stream" : "Pause Stream")

                    Button(action: {
                        HapticFeedback.selection()
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                            manager.isDropDownMode.toggle()
                        }
                    }) {
                        Circle()
                            .fill(Color.green.opacity(0.85))
                            .frame(width: 10, height: 10)
                            .overlay(
                                Image(systemName: manager.isDropDownMode ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                                    .font(.system(size: 5.5, weight: .bold))
                                    .foregroundColor(.black.opacity(0.6))
                                    .opacity(isHovered ? 1.0 : 0.0)
                            )
                    }
                    .buttonStyle(.plain)
                    .help("Toggle Drop-Down / Floating Mode")
                }
                .padding(.leading, 10)

                // Space Badge & Title
                HStack(spacing: 5) {
                    Image(systemName: "tv.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color.cyan)

                    Text("Desktop \(manager.targetSpaceIndex) Stream")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    if manager.isPaused {
                        Text("PAUSED")
                            .font(.system(size: 8.5, weight: .heavy))
                            .foregroundColor(.orange)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(Color.orange.opacity(0.2)))
                    } else {
                        HStack(spacing: 3) {
                            Circle().fill(Color.green).frame(width: 5, height: 5)
                            Text("LIVE")
                                .font(.system(size: 8, weight: .heavy))
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(Color.green.opacity(0.15)))
                    }
                }

                Spacer()

                // Header Controls
                HStack(spacing: 6) {
                    // Switch to Desktop 2 Jump Button
                    Button(action: {
                        HapticFeedback.selection()
                        MacDesktopsManager.shared.switchToDesktop(index: manager.targetSpaceIndex)
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 9))
                            Text("Go to Desktop \(manager.targetSpaceIndex)")
                                .font(.system(size: 9.5, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2.5)
                        .background(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(Color.white.opacity(0.18))
                        )
                    }
                    .buttonStyle(.plain)
                    .help("Jump directly to Desktop \(manager.targetSpaceIndex)")

                    // Settings Menu
                    Menu {
                        Section(header: Text("Stream Source")) {
                            Button("🖥️ Full Desktop \(manager.targetSpaceIndex)") {
                                manager.selectedWindowID = nil
                            }
                            ForEach(manager.availableWindows.prefix(8)) { win in
                                Button("\(win.appName): \(win.title.prefix(25))") {
                                    manager.selectedWindowID = win.id
                                }
                            }
                        }

                        Section(header: Text("Target Space")) {
                            ForEach(1...max(2, MacDesktopsManager.shared.spaces.count), id: \.self) { idx in
                                Button("Desktop \(idx)") {
                                    manager.targetSpaceIndex = idx
                                }
                            }
                        }

                        Section(header: Text("Layout")) {
                            Button(manager.isDropDownMode ? "✓ Drop Down from Menu Bar" : "Drop Down from Menu Bar") {
                                manager.isDropDownMode = true
                            }
                            Button(!manager.isDropDownMode ? "✓ Floating Picture-in-Picture" : "Floating Picture-in-Picture") {
                                manager.isDropDownMode = false
                            }
                        }
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color.white.opacity(0.8))
                            .frame(width: 18, height: 18)
                            .background(Circle().fill(Color.white.opacity(0.12)))
                    }
                    .menuStyle(.borderlessButton)
                    .frame(width: 20)
                }
                .padding(.trailing, 10)
            }
            .frame(height: 32)
            .background(
                ZStack {
                    VisualEffectBlur(material: .headerView, blendingMode: .behindWindow, state: .active)
                    Color.black.opacity(0.40)
                }
            )

            // ── 16:10 LIVE STREAM VIDEO DISPLAY ──
            ZStack {
                Color.black

                if let frame = manager.currentFrame {
                    Image(nsImage: frame)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 8) {
                        ProgressView().controlSize(.small)
                        Text("Streaming Desktop \(manager.targetSpaceIndex)...")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }

                // Hover Glass Action Bar (Over video)
                if isHovered {
                    VStack {
                        Spacer()
                        HStack(spacing: 12) {
                            Button(action: {
                                HapticFeedback.selection()
                                manager.togglePause()
                            }) {
                                Image(systemName: manager.isPaused ? "play.circle.fill" : "pause.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(.plain)

                            // Quick Space Switcher
                            HStack(spacing: 4) {
                                Text("Space:")
                                    .font(.system(size: 9.5, weight: .bold))
                                    .foregroundColor(.white.opacity(0.7))

                                ForEach(1...max(2, MacDesktopsManager.shared.spaces.count), id: \.self) { idx in
                                    Button(action: {
                                        manager.targetSpaceIndex = idx
                                    }) {
                                        Text("\(idx)")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(manager.targetSpaceIndex == idx ? .cyan : .white)
                                            .frame(width: 16, height: 16)
                                            .background(
                                                Circle().fill(manager.targetSpaceIndex == idx ? Color.white.opacity(0.25) : Color.clear)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.black.opacity(0.6)))

                            Spacer()

                            // Fullscreen / Switch Space Action
                            Button(action: {
                                HapticFeedback.heavy()
                                MacDesktopsManager.shared.switchToDesktop(index: manager.targetSpaceIndex)
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                                        .font(.system(size: 9))
                                    Text("Open Space")
                                        .font(.system(size: 9.5, weight: .semibold))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.blue.opacity(0.7)))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow, state: .active)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.8)
                                )
                        )
                        .padding(.horizontal, 10)
                        .padding(.bottom, 8)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.white.opacity(0.22), lineWidth: 0.85)
        )
        .shadow(color: Color.black.opacity(0.50), radius: 24, y: 12)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.18)) {
                isHovered = hovering
            }
        }
    }
}
