import AppKit
import SwiftUI

// MARK: - 📐 Finder Chat Window Size & Snap Presets
public enum FinderWindowSizePreset: String, CaseIterable, Identifiable {
    case standard = "Standard (960×680)"
    case verticalTop = "Vertical Top (Full Height ↕️)"
    case mostScreen = "Most Screen (88% ⛶)"
    case fullScreen = "Full Screen (100% ⤢)"

    public var id: String { rawValue }

    public var shortTitle: String {
        switch self {
        case .standard: return "Standard"
        case .verticalTop: return "Vertical ↕️"
        case .mostScreen: return "Most Screen ⛶"
        case .fullScreen: return "Full Screen ⤢"
        }
    }

    public var icon: String {
        switch self {
        case .standard: return "rectangle.center.inset.filled"
        case .verticalTop: return "arrow.up.and.down.square.fill"
        case .mostScreen: return "rectangle.inset.filled"
        case .fullScreen: return "arrow.up.left.and.arrow.down.right.square.fill"
        }
    }
}

public enum FinderWindowTab: String, CaseIterable {
    case chat = "Chat"
    case files = "Files"
    // case note = "Note"      // Hidden for initial production release
    // case editor = "Editor"  // Hidden for initial production release
    case settings = "Settings"

    public var icon: String {
        switch self {
        case .chat: return "bubble.left.and.bubble.right.fill"
        case .files: return "folder.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

// MARK: - Finder Chat Window Manager (Authentic macOS Finder-Style Window)
@MainActor
public final class FinderChatWindowManager: ObservableObject {
    public static let shared = FinderChatWindowManager()

    @Published public private(set) var isVisible: Bool = false
    @Published public private(set) var isExpanded: Bool = false
    @Published public private(set) var currentSizePreset: FinderWindowSizePreset = .standard
    @Published public var activeTab: FinderWindowTab = .chat
    public var isShowingSettings: Bool {
        get { activeTab == .settings }
        set { activeTab = newValue ? .settings : .chat }
    }
    private var preExpandFrame: NSRect?
    private var window: NSPanel?

    private init() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NexusToggleFinderChatWindow"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.toggle()
            }
        }

        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NexusOpenMiniBrowser"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.show()
            }
        }
    }

    public func toggle() {
        if isVisible {
            hide()
        } else {
            show()
        }
    }

    public func snapTo(preset: FinderWindowSizePreset) {
        guard let win = window else { return }
        let screen = win.screen ?? NSScreen.main ?? NSScreen.screens.first ?? NSScreen()
        let sFrame = screen.visibleFrame

        let targetRect: NSRect
        switch preset {
        case .standard:
            let targetW: CGFloat = min(960, sFrame.width - 80)
            let targetH: CGFloat = min(680, sFrame.height - 100)
            let x = sFrame.minX + (sFrame.width - targetW) / 2
            let y = sFrame.minY + (sFrame.height - targetH) / 2
            targetRect = NSRect(x: x, y: y, width: targetW, height: targetH)
            isExpanded = false

        case .verticalTop:
            // Vertical full height from top menu bar down to screen bottom, width ~680
            let targetW: CGFloat = min(720, max(600, sFrame.width * 0.52))
            let targetH: CGFloat = sFrame.height - 8
            let x = sFrame.minX + (sFrame.width - targetW) / 2
            let y = sFrame.minY + 4
            targetRect = NSRect(x: x, y: y, width: targetW, height: targetH)
            isExpanded = false

        case .mostScreen:
            // Most Screen: 88-90% width & height centered
            let targetW: CGFloat = sFrame.width * 0.90
            let targetH: CGFloat = sFrame.height * 0.90
            let x = sFrame.minX + (sFrame.width - targetW) / 2
            let y = sFrame.minY + (sFrame.height - targetH) / 2
            targetRect = NSRect(x: x, y: y, width: targetW, height: targetH)
            isExpanded = true

        case .fullScreen:
            // Full Screen: 100% visible frame
            targetRect = NSRect(x: sFrame.minX + 2, y: sFrame.minY + 2, width: sFrame.width - 4, height: sFrame.height - 4)
            isExpanded = true
        }

        currentSizePreset = preset
        HapticFeedback.selection()
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.28
            ctx.timingFunction = CAMediaTimingFunction(controlPoints: 0.16, 1.0, 0.3, 1.0)
            win.animator().setFrame(targetRect, display: true)
        }
    }

    public func toggleExpand() {
        if isExpanded {
            snapTo(preset: .standard)
        } else {
            snapTo(preset: .mostScreen)
        }
    }

    public func show(tab: FinderWindowTab = .chat) {
        self.activeTab = tab

        // Consolidate UI: Close any secondary drawer or dock chat windows
        UserDefaults.standard.set(false, forKey: PrefKey.isRightChatDockOpen)
        NotificationCenter.default.post(name: NSNotification.Name("NexusCloseSecondaryChatWindows"), object: nil)
        NotificationCenter.default.post(name: NSNotification.Name("NexusCloseAllRollupsExceptChat"), object: nil)

        if window == nil {
            createWindow()
        }

        guard let win = window else { return }

        if win.isMiniaturized { win.deminiaturize(nil) }
        if isVisible {
            win.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        isExpanded = false
        currentSizePreset = .standard

        // Center on the active screen
        let screen = NSScreen.main ?? NSScreen.screens.first ?? NSScreen()
        let sFrame = screen.visibleFrame
        let targetW: CGFloat = min(960, sFrame.width - 80)
        let targetH: CGFloat = min(680, sFrame.height - 100)
        let x = sFrame.minX + (sFrame.width - targetW) / 2
        let y = sFrame.minY + (sFrame.height - targetH) / 2

        let startY = y + 20
        let startRect = NSRect(x: x, y: startY, width: targetW, height: targetH)
        let targetRect = NSRect(x: x, y: y, width: targetW, height: targetH)

        win.setFrame(startRect, display: true)
        win.alphaValue = 0.0
        win.makeKeyAndOrderFront(nil)
        win.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.28
            ctx.timingFunction = CAMediaTimingFunction(controlPoints: 0.16, 1.0, 0.3, 1.0)
            win.animator().setFrame(targetRect, display: true)
            win.animator().alphaValue = 1.0
        }

        isVisible = true
        HapticFeedback.selection()
    }

    public func show(settings: Bool) {
        show(tab: settings ? .settings : .chat)
    }

    public func minimize() {
        hide()
    }

    public func hide() {
        guard let win = window, isVisible else { return }
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.18
            ctx.timingFunction = CAMediaTimingFunction(controlPoints: 0.25, 0.1, 0.25, 1.0)
            win.animator().alphaValue = 0.0
        }, completionHandler: {
            MainActor.assumeIsolated {
                win.orderOut(nil)
                self.isVisible = false
            }
        })
        HapticFeedback.tick()
    }

    private func createWindow() {
        let panel = FinderChatPanel(
            contentRect: NSRect(x: 0, y: 0, width: 920, height: 640),
            styleMask: [.borderless, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        if #available(macOS 11.0, *) {
            panel.titlebarSeparatorStyle = .none
        }
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        panel.isMovable = true
        panel.isMovableByWindowBackground = true
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        panel.isExcludedFromWindowsMenu = false
        panel.sharingType = .readOnly
        // The floor is the tall, narrow shape the chat is actually used at. Below roughly this
        // width the tab row (Genie / Chat / Files / Settings / model chip) collides with itself,
        // and below this height the transcript collapses to a couple of visible lines.
        panel.minSize = NSSize(width: 460, height: 680)

        let host = NSHostingView(rootView: FinderStyleChatWindowView().ignoresSafeArea())
        host.autoresizingMask = [.width, .height]
        panel.contentView = host
        panel.invalidateShadow()
        self.window = panel

        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: panel,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.isVisible = false
            }
        }

        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, self.isVisible, let win = self.window else { return }
                win.orderFrontRegardless()
            }
        }
    }
}

// MARK: - Dedicated Finder Chat Panel Window Subclass
public final class FinderChatPanel: NSPanel {
    public override var canBecomeKey: Bool { true }
    public override var canBecomeMain: Bool { true }

    public override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers?.lowercased() == "q" {
            NSApp.terminate(nil)
            return true
        }
        if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers?.lowercased() == "w" {
            FinderChatWindowManager.shared.hide()
            return true
        }
        if event.keyCode == 53 { // Escape key
            FinderChatWindowManager.shared.hide()
            return true
        }
        if let mainMenu = NSApp.mainMenu, mainMenu.performKeyEquivalent(with: event) {
            return true
        }
        return super.performKeyEquivalent(with: event)
    }

    public override func keyDown(with event: NSEvent) {
        if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers?.lowercased() == "q" {
            NSApp.terminate(nil)
            return
        }
        if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers?.lowercased() == "w" {
            FinderChatWindowManager.shared.hide()
            return
        }
        if event.keyCode == 53 { // Escape key
            FinderChatWindowManager.shared.hide()
            return
        }
        super.keyDown(with: event)
    }
}

// MARK: - Native Window Dragging Background Helper
public struct WindowDragRepresentable: NSViewRepresentable {
    public init() {}
    public func makeNSView(context: Context) -> DraggingNSView {
        DraggingNSView()
    }
    public func updateNSView(_ nsView: DraggingNSView, context: Context) {}

    public final class DraggingNSView: NSView {
        public override func mouseDown(with event: NSEvent) {
            window?.performDrag(with: event)
        }
    }
}
