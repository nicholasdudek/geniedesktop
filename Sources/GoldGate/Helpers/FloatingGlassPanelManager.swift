import AppKit
import SwiftUI

// MARK: - 🪟 Reusable High-Performance Floating Glass NSPanel
public class FloatingGlassPanel: NSPanel {
    public var onEscape: (() -> Void)?

    public init(contentRect: NSRect, windowLevelOffset: Int = 5) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.level = NSWindow.Level(Int(CGWindowLevelForKey(.popUpMenuWindow)) + windowLevelOffset)
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
            onEscape?()
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
            onEscape?()
            return
        }
        super.keyDown(with: event)
    }
}

// MARK: - 🎯 Generic Floating Glass Panel Manager (Consolidates Duplicate AppKit Boilerplate)
@MainActor
open class GenericFloatingGlassPanelManager<Content: View>: ObservableObject {
    public private(set) var panel: FloatingGlassPanel?
    private var globalClickMonitor: Any?
    private var localKeyMonitor: Any?

    @Published public private(set) var isVisible: Bool = false

    public let panelSize: CGSize
    public let levelOffset: Int
    private let contentBuilder: () -> Content

    public init(panelSize: CGSize, levelOffset: Int = 5, content: @escaping () -> Content) {
        self.panelSize = panelSize
        self.levelOffset = levelOffset
        self.contentBuilder = content
    }

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

        let panelW = panelSize.width
        let panelH = panelSize.height
        let posX = max(visFrame.minX + 16, visFrame.maxX - panelW - 16)
        let posY = visFrame.maxY - panelH - 6
        let frame = NSRect(x: posX, y: posY, width: panelW, height: panelH)

        if panel == nil {
            let newPanel = FloatingGlassPanel(contentRect: frame, windowLevelOffset: levelOffset)
            newPanel.contentView = NSHostingView(rootView: contentBuilder())
            newPanel.onEscape = { [weak self] in
                Task { @MainActor in self?.dismiss() }
            }
            panel = newPanel
        } else {
            panel?.setFrame(frame, display: true)
        }

        guard let p = panel else { return }

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

        globalClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            guard let self = self, self.isVisible, let p = self.panel else { return }
            let mouseLoc = NSEvent.mouseLocation
            if !p.frame.contains(mouseLoc) {
                Task { @MainActor in self.dismiss() }
            }
        }

        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // ESC
                Task { @MainActor in self?.dismiss() }
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
