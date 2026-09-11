import AppKit
import SwiftUI

// MARK: - 🪟 Notch-Anchored Mini Dock Panel
// Hosts the mini dock in its own borderless floating panel centred under the camera notch
// instead of cramming it into the status item at the far right of the menu bar. The panel
// stays tucked up behind the menu bar until the cursor enters the notch zone, then slides
// down into view — and retracts once the cursor leaves.
@MainActor
public final class NotchDockPanelManager: NSObject {
    public static let shared = NotchDockPanelManager()

    private var panel: NSPanel?
    private var hosting: NSHostingView<MenuBarAppStripView>?
    private var proximityTimer: Timer?
    private var isRevealed = false

    /// How far either side of the notch still counts as "reaching for the dock".
    private static let notchZoneSlack: CGFloat = 80.0
    /// Depth below the top of the screen that still counts as being in the trigger zone.
    private static let notchZoneDepth: CGFloat = 6.0

    public var isEnabled: Bool {
        UserDefaults.standard.object(forKey: PrefKey.notchDockEnabled) as? Bool ?? false
    }

    public func setup() {
        guard isEnabled else { return }
        buildPanelIfNeeded()
        startProximityMonitoring()
    }

    public func teardown() {
        proximityTimer?.invalidate()
        proximityTimer = nil
        panel?.orderOut(nil)
        panel = nil
        hosting = nil
        isRevealed = false
    }

    private func buildPanelIfNeeded() {
        guard panel == nil else { return }

        let p = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 30),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        p.isOpaque = false
        p.backgroundColor = .clear
        p.hasShadow = false
        // Above the menu bar so it reads as coming out of the notch itself.
        p.level = .statusBar
        p.isMovable = false
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        p.hidesOnDeactivate = false
        p.isReleasedWhenClosed = false
        p.isExcludedFromWindowsMenu = true

        let host = NSHostingView(rootView: MenuBarAppStripView())
        host.autoresizingMask = [.width, .height]
        p.contentView = host

        panel = p
        hosting = host
    }

    // MARK: Geometry
    /// Frame the dock rests in once revealed: centred on the notch, flush under the camera housing.
    private func revealedFrame(for size: NSSize, screen: NSScreen) -> NSRect {
        let notch = ScreenNotchInfo.forScreen(screen)
        let centerX = notch.hasNotch ? notch.notchRect.midX : screen.frame.midX
        let topBarHeight = notch.hasNotch ? notch.notchHeight : max(screen.safeAreaInsets.top, screen.frame.maxY - screen.visibleFrame.maxY)
        return NSRect(
            x: centerX - size.width / 2,
            y: screen.frame.maxY - topBarHeight - size.height,
            width: size.width,
            height: size.height
        )
    }

    /// Where the dock hides: tucked up behind the menu bar/notch so it appears to emerge from it.
    private func hiddenFrame(for size: NSSize, screen: NSScreen) -> NSRect {
        var frame = revealedFrame(for: size, screen: screen)
        frame.origin.y = screen.frame.maxY
        return frame
    }

    private func isCursorInNotchZone(screen: NSScreen) -> Bool {
        let notch = ScreenNotchInfo.forScreen(screen)
        let mouse = NSEvent.mouseLocation
        let triggerDepth = notch.hasNotch ? (notch.notchHeight + 12.0) : 10.0
        guard screen.frame.maxY - mouse.y <= triggerDepth else { return false }
        let centerX = notch.hasNotch ? notch.notchRect.midX : screen.frame.midX
        let halfWidth = (notch.hasNotch ? notch.notchWidth / 2 : 90) + Self.notchZoneSlack
        return abs(mouse.x - centerX) <= halfWidth
    }

    // MARK: Reveal / Retract

    private func startProximityMonitoring() {
        guard proximityTimer == nil else { return }
        proximityTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.checkProximity() }
        }
    }

    private func checkProximity() {
        guard isEnabled, let screen = NSScreen.main else { return }

        // Once revealed, keep it open while the cursor is anywhere over the panel itself,
        // otherwise it would snap shut the moment you moved down onto the icons.
        let mouse = NSEvent.mouseLocation
        let overPanel = isRevealed && (panel?.frame.insetBy(dx: -6, dy: -6).contains(mouse) ?? false)
        let shouldReveal = isCursorInNotchZone(screen: screen) || overPanel

        guard shouldReveal != isRevealed else { return }
        isRevealed = shouldReveal
        shouldReveal ? reveal(on: screen) : retract(on: screen)
    }

    private func reveal(on screen: NSScreen) {
        buildPanelIfNeeded()
        guard let panel else { return }

        let size = panel.frame.size
        if !panel.isVisible {
            panel.setFrame(hiddenFrame(for: size, screen: screen), display: false)
            panel.alphaValue = 0
            panel.orderFrontRegardless()
        }

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.28
            ctx.timingFunction = CAMediaTimingFunction(controlPoints: 0.2, 1.1, 0.4, 1.0)
            panel.animator().alphaValue = 1
            panel.animator().setFrame(revealedFrame(for: size, screen: screen), display: true)
        }
    }

    private func retract(on screen: NSScreen) {
        guard let panel, panel.isVisible else { return }
        let size = panel.frame.size
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.20
            panel.animator().alphaValue = 0
            panel.animator().setFrame(hiddenFrame(for: size, screen: screen), display: true)
        }, completionHandler: {
            panel.orderOut(nil)
        })
    }
}
