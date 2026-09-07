import AppKit
import SwiftUI

// MARK: - Dedicated Apple Control Center Popover Panel
public final class AppleControlCenterPanel: NSPanel {
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
        self.level = NSWindow.Level(Int(CGWindowLevelForKey(.popUpMenuWindow)) + 5)
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        self.isExcludedFromWindowsMenu = true
        self.sharingType = .none
        self.hidesOnDeactivate = false
        self.canHide = false
        self.ignoresMouseEvents = false
        self.acceptsMouseMovedEvents = true
        self.isReleasedWhenClosed = false
    }

    public override var canBecomeKey: Bool { true }
    public override var canBecomeMain: Bool { false }
}

// MARK: - Control Center Popover Manager Singleton
@MainActor
public final class ControlCenterPopoverManager: ObservableObject {
    public static let shared = ControlCenterPopoverManager()

    private var panel: AppleControlCenterPanel?
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

        let panelW: CGFloat = 336
        let panelH: CGFloat = 490

        // Position under the menu bar near the right edge
        let posX = max(visFrame.minX + 16, visFrame.maxX - panelW - 16)
        let posY = visFrame.maxY - panelH - 6

        let frame = NSRect(x: posX, y: posY, width: panelW, height: panelH)

        if panel == nil {
            let newPanel = AppleControlCenterPanel(contentRect: frame)
            let hostView = NSHostingView(rootView: AppleControlCenterPopoverView())
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
