import AppKit
import SwiftUI
import Combine

// MARK: - 🪟 Unified Command Window
// One draggable floating window that stacks the custom menu bar's dock strip (spaces, canvas toggles,
// apps atelier, utilities) directly on top of the Genie chat command center. Replaces the split
// "strip pinned to the screen top + chat dock inside the desktop plane" arrangement.
@MainActor
public final class UnifiedCommandWindowManager: NSObject, NSWindowDelegate, ObservableObject {
    public static let shared = UnifiedCommandWindowManager()

    @Published public private(set) var isVisible: Bool = false

    private var panel: NSPanel?
    private var hosting: NSHostingView<UnifiedCommandWindowView>?
    private var cancellables = Set<AnyCancellable>()

    public static let width: CGFloat = 460
    private let originKey = PrefKey.unifiedCommandWindowOrigin

    private override init() {
        super.init()
        NotificationCenter.default.publisher(for: NSNotification.Name("NexusToggleUnifiedCommandWindow"))
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.toggle() }
            .store(in: &cancellables)
        NotificationCenter.default.publisher(for: NSNotification.Name("NexusOpenSettingsInChat"))
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                if UserDefaults.standard.bool(forKey: PrefKey.unifiedCommandWindowEnabled) { self?.show() }
            }
            .store(in: &cancellables)
        NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.clampOnScreen() }
            .store(in: &cancellables)
    }

    // MARK: Show / Hide
    public func toggle() {
        if isVisible { hide() } else { show() }
    }

    public func show() {
        if panel == nil { buildPanel() }
        guard let panel else { return }
        hosting?.rootView = UnifiedCommandWindowView()
        panel.setContentSize(preferredSize())
        panel.setFrameOrigin(resolvedOrigin(for: panel.frame.size))
        panel.alphaValue = 0
        panel.orderFrontRegardless()
        panel.makeKey()
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.22
            panel.animator().alphaValue = 1
        }
        isVisible = true
        CustomMenuBarManager.shared.setSuppressedByUnifiedWindow(true)
    }

    public func hide() {
        guard let panel, panel.isVisible else { isVisible = false; return }
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.18
            panel.animator().alphaValue = 0
        }, completionHandler: { [weak self] in
            panel.orderOut(nil)
            Task { @MainActor in
                self?.isVisible = false
                CustomMenuBarManager.shared.setSuppressedByUnifiedWindow(false)
            }
        })
    }

    private func buildPanel() {
        let p = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: Self.width, height: 800),
            styleMask: [.borderless, .nonactivatingPanel, .resizable],
            backing: .buffered,
            defer: false
        )
        p.isOpaque = false
        p.backgroundColor = .clear
        p.hasShadow = false                 // the SwiftUI card draws its own
        p.level = .normal
        p.isMovable = true
        p.isMovableByWindowBackground = false   // the strip is the drag region; the chat area keeps its gestures
        p.becomesKeyOnlyIfNeeded = true
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        p.hidesOnDeactivate = false
        p.isReleasedWhenClosed = false
        p.isExcludedFromWindowsMenu = true
        p.minSize = NSSize(width: Self.width, height: 420)
        p.maxSize = NSSize(width: Self.width, height: 2000)
        p.delegate = self

        let host = NSHostingView(rootView: UnifiedCommandWindowView())
        host.autoresizingMask = [.width, .height]
        p.contentView = host
        panel = p
        hosting = host
    }

    // MARK: Geometry
    private func preferredSize() -> NSSize {
        let vf = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let h = min(max(520, vf.height - 24), 1100)
        return NSSize(width: Self.width, height: h)
    }

    private func resolvedOrigin(for size: NSSize) -> NSPoint {
        let vf = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        if let dict = UserDefaults.standard.dictionary(forKey: originKey),
           let x = dict["x"] as? CGFloat, let y = dict["y"] as? CGFloat {
            return NSPoint(x: min(max(x, vf.minX), vf.maxX - size.width),
                           y: min(max(y, vf.minY), vf.maxY - size.height))
        }
        // Default: left edge, just under the menu bar (where the split pieces used to sit).
        return NSPoint(x: vf.minX + 10, y: vf.maxY - size.height - 8)
    }

    private func clampOnScreen() {
        guard let panel, panel.isVisible else { return }
        panel.setFrameOrigin(resolvedOrigin(for: panel.frame.size))
    }

    public func windowDidMove(_ notification: Notification) {
        guard let panel else { return }
        UserDefaults.standard.set(["x": panel.frame.origin.x, "y": panel.frame.origin.y], forKey: originKey)
    }

    public func windowDidResize(_ notification: Notification) {
        windowDidMove(notification)
    }
}

// MARK: - Drag region: empty space in the strip moves the whole window
public struct WindowDragRegion: NSViewRepresentable {
    public init() {}
    public func makeNSView(context: Context) -> DragRegionView { DragRegionView() }
    public func updateNSView(_ nsView: DragRegionView, context: Context) {}

    public final class DragRegionView: NSView {
        public override func mouseDown(with event: NSEvent) {
            window?.performDrag(with: event)
        }
        public override var mouseDownCanMoveWindow: Bool { true }
    }
}

// MARK: - Window content: strip header + chat command center
public struct UnifiedCommandWindowView: View {
    @ObservedObject private var manager = UnifiedCommandWindowManager.shared
    @ObservedObject private var desktopFiles = DesktopFilesManager.shared
    @State private var chatOpen: Bool = true

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            stripHeader
            RightSideChatDockView(
                isRightChatDockOpen: Binding(
                    get: { chatOpen },
                    set: { open in
                        chatOpen = open
                        if !open { UnifiedCommandWindowManager.shared.hide() }
                    }
                ),
                edge: .floating
            )
            .frame(maxHeight: .infinity)
        }
        .frame(width: UnifiedCommandWindowManager.width)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    LinearGradient(colors: [Color.white.opacity(0.28), Color.cyan.opacity(0.25), Color.white.opacity(0.06)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    lineWidth: 0.8
                )
        )
        .shadow(color: Color.black.opacity(0.45), radius: 26, y: 10)
        .padding(6)
    }

    // The custom menu bar's dock row, reused as this window's title bar.
    private var stripHeader: some View {
        HStack(spacing: 6) {
            // Grip
            VStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { _ in
                    Capsule().fill(Color.white.opacity(0.35)).frame(width: 12, height: 2)
                }
            }
            .frame(width: 18, height: 30)
            .help("Drag to move the Command Window")

            // Scrollable middle: spaces + canvas toggles + apps atelier. Utilities stay pinned on the right.
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    MiniMenuBarDesktopSpacesView()

                    stripButton(desktopFiles.areDesktopFilesVisible ? "eye.fill" : "eye.slash.fill",
                                dim: !desktopFiles.areDesktopFilesVisible,
                                help: "Toggle Desktop Files Visibility (Clean Canvas)") {
                        DesktopFilesManager.shared.setDesktopFilesVisible(!desktopFiles.areDesktopFilesVisible)
                    }
                    stripButton("square.grid.2x2.fill", help: "Architectural Canvas & Formations (⌘⇧D)") {
                        NotificationCenter.default.post(name: NSNotification.Name("NexusToggleDesktopGrid"), object: nil)
                    }

                    hairline

                    MenuBarDockAppsGridView()
                }
                .padding(.vertical, 2)
            }
            .frame(maxWidth: .infinity)
            .mask(
                HStack(spacing: 0) {
                    Rectangle()
                    LinearGradient(colors: [.black, .clear], startPoint: .leading, endPoint: .trailing).frame(width: 14)
                }
            )

            hairline

            stripButton("terminal.fill", help: "Launch Terminal Studio") { FinderChatWindowManager.shared.show() }
            stripButton("gearshape.fill", help: "Preferences") {
                AppDelegate.shared?.showMenuBarSettingsDropdown(targetTab: .menuBar)
            }
            stripButton("xmark", help: "Close Command Window") { UnifiedCommandWindowManager.shared.hide() }
        }
        .padding(.horizontal, 10)
        .frame(height: 46)
        .background(
            ZStack {
                VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow, state: .active)
                Color.black.opacity(0.45)
                WindowDragRegion()          // any empty spot in the strip drags the window
            }
        )
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(LinearGradient(colors: [Color.clear, Color.white.opacity(0.14), Color.clear], startPoint: .leading, endPoint: .trailing))
                .frame(height: 0.5)
        }
    }

    private var hairline: some View {
        Rectangle()
            .fill(LinearGradient(colors: [Color.clear, Color.white.opacity(0.22), Color.clear], startPoint: .top, endPoint: .bottom))
            .frame(width: 1, height: 18)
    }

    private func stripButton(_ symbol: String, dim: Bool = false, help: String, action: @escaping () -> Void) -> some View {
        Button {
            HapticFeedback.selection()
            action()
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 11.5, weight: .medium))
                .foregroundColor(.white.opacity(dim ? 0.45 : 0.88))
                .frame(width: 26, height: 26)
                .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(Color.white.opacity(0.06)))
        }
        .buttonStyle(.plain)
        .help(help)
    }
}
