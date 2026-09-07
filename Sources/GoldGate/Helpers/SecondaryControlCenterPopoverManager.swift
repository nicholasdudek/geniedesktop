import AppKit
import SwiftUI

// MARK: - Dedicated Secondary Control Center Popover Panel
public final class SecondaryControlCenterPanel: NSPanel {
    public init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.level = NSWindow.Level(Int(CGWindowLevelForKey(.popUpMenuWindow)) + 6)
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        self.isExcludedFromWindowsMenu = true
        self.sharingType = .readOnly
        self.hidesOnDeactivate = false
        self.canHide = false
        self.ignoresMouseEvents = false
        self.acceptsMouseMovedEvents = true
        self.isReleasedWhenClosed = false
    }

    public override var canBecomeKey: Bool { true }
    public override var canBecomeMain: Bool { false }

    public override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers?.lowercased() == "q" {
            NSApp.terminate(nil)
            return true
        }
        if event.keyCode == 53 { // Escape
            SecondaryControlCenterPopoverManager.shared.dismiss()
            return true
        }
        return super.performKeyEquivalent(with: event)
    }

    public override func keyDown(with event: NSEvent) {
        if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers?.lowercased() == "q" {
            NSApp.terminate(nil)
            return
        }
        if event.keyCode == 53 { // Escape
            SecondaryControlCenterPopoverManager.shared.dismiss()
            return
        }
        super.keyDown(with: event)
    }
}

// MARK: - Secondary Control Center Popover Manager Singleton
@MainActor
public final class SecondaryControlCenterPopoverManager: ObservableObject {
    public static let shared = SecondaryControlCenterPopoverManager()

    private var panel: SecondaryControlCenterPanel?
    private var globalClickMonitor: Any?
    private var localKeyMonitor: Any?

    @Published public private(set) var isVisible: Bool = false

    private init() {}

    public func toggle(screen: NSScreen? = nil) {
        if isVisible {
            dismiss()
        } else {
            show(screen: screen)
        }
    }

    public func show(screen: NSScreen? = nil) {
        let targetScreen = screen ?? NSScreen.main ?? (NSScreen.screens.first ?? NSScreen())
        let visFrame = targetScreen.visibleFrame

        let panelW: CGFloat = 348
        let panelH: CGFloat = 490

        // Position under the menu bar near the right edge (slightly offset from primary control center if open)
        let posX = max(visFrame.minX + 16, visFrame.maxX - panelW - 48)
        let posY = visFrame.maxY - panelH - 6

        let frame = NSRect(x: posX, y: posY, width: panelW, height: panelH)

        if panel == nil {
            let newPanel = SecondaryControlCenterPanel(contentRect: frame)
            let hostView = NSHostingView(rootView: SecondaryControlCenterPopoverView())
            newPanel.contentView = hostView
            panel = newPanel
        } else {
            panel?.setFrame(frame, display: true)
        }

        guard let p = panel else { return }

        // Start animation from slightly higher up and transparent
        let startFrame = NSRect(x: posX, y: posY + 12, width: panelW, height: panelH)
        p.setFrame(startFrame, display: false)
        p.alphaValue = 0.0
        p.orderFrontRegardless()
        p.makeKeyAndOrderFront(nil)

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.22
            ctx.timingFunction = CAMediaTimingFunction(controlPoints: 0.16, 1.0, 0.3, 1.0)
            p.animator().setFrame(frame, display: true)
            p.animator().alphaValue = 1.0
        }

        isVisible = true
        HapticFeedback.selection()

        setupDismissMonitors()
    }

    public func dismiss() {
        guard isVisible, let p = panel else { return }
        removeDismissMonitors()

        let endFrame = NSRect(x: p.frame.origin.x, y: p.frame.origin.y + 10, width: p.frame.width, height: p.frame.height)

        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.16
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            p.animator().setFrame(endFrame, display: true)
            p.animator().alphaValue = 0.0
        }, completionHandler: { [weak self] in
            p.orderOut(nil)
            DispatchQueue.main.async {
                self?.isVisible = false
            }
        })
    }

    private func setupDismissMonitors() {
        removeDismissMonitors()

        // 1. Outside click dismissal
        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self, self.isVisible, let p = self.panel else { return }
            let mouseLoc = NSEvent.mouseLocation
            if !p.frame.contains(mouseLoc) {
                Task { @MainActor in
                    self.dismiss()
                }
            }
        }

        // 2. Escape key dismissal
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // ESC
                Task { @MainActor in
                    self?.dismiss()
                }
                return nil
            }
            return event
        }
    }

    private func removeDismissMonitors() {
        if let g = globalClickMonitor {
            NSEvent.removeMonitor(g)
            globalClickMonitor = nil
        }
        if let l = localKeyMonitor {
            NSEvent.removeMonitor(l)
            localKeyMonitor = nil
        }
    }
}
