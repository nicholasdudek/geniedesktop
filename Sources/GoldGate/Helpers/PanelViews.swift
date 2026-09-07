import AppKit
import SwiftUI

// MARK: - Menu Bar Popover Panel

class MenuBarPopoverPanel: NSPanel, NSWindowDelegate {
    init(contentRect: NSRect) {
        super.init(
            contentRect: contentRect,
            styleMask: [.borderless, .resizable],
            backing: .buffered,
            defer: false
        )
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.level = NSWindow.Level(Int(CGWindowLevelForKey(.popUpMenuWindow)) + 5)
        self.isMovable = true
        self.isMovableByWindowBackground = true
        self.minSize = NSSize(width: 460, height: 44)
        self.maxSize = NSSize(width: 2200, height: 1600)
        self.showsResizeIndicator = true
        self.collectionBehavior = [
            .canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle, .stationary,
        ]
        self.isExcludedFromWindowsMenu = true
        self.sharingType = .readOnly
        self.hidesOnDeactivate = false
        self.canHide = false
        self.ignoresMouseEvents = false
        self.acceptsMouseMovedEvents = true
        self.delegate = self
    }

    override var canBecomeKey: Bool {
        return true
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers?.lowercased() == "q" {
            NSApp.terminate(nil)
            return true
        }
        if event.keyCode == 53 { // Escape key
            NotificationCenter.default.post(name: NSNotification.Name("NexusClose"), object: nil)
            return true
        }
        if let mainMenu = NSApp.mainMenu, mainMenu.performKeyEquivalent(with: event) {
            return true
        }
        return super.performKeyEquivalent(with: event)
    }

    override func keyDown(with event: NSEvent) {
        if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers?.lowercased() == "q" {
            NSApp.terminate(nil)
            return
        }
        if event.keyCode == 53 { // Escape key
            NotificationCenter.default.post(name: NSNotification.Name("NexusClose"), object: nil)
            return
        }
        super.keyDown(with: event)
    }

    func windowDidMove(_ notification: Notification) {
        UserDefaults.standard.set(Double(self.frame.origin.x), forKey: PrefKey.popoverCustomX)
        UserDefaults.standard.set(Double(self.frame.origin.y), forKey: PrefKey.popoverCustomY)
        UserDefaults.standard.set(true, forKey: PrefKey.isVelcroDetached)
        UserDefaults.standard.set("free", forKey: PrefKey.menuBarSnapMode)
    }

    @discardableResult
    static func applyMagneticSnapping(to window: NSWindow) -> String {
        let screen = window.screen ?? NSScreen.main ?? (NSScreen.screens.first ?? NSScreen())
        let visFrame = screen.visibleFrame
        let frame = window.frame
        let panelW = frame.width
        let panelH = frame.height

        let topMenuBarY = visFrame.maxY - panelH - 4
        let leftSnapX = visFrame.minX + 12
        let rightSnapX = visFrame.maxX - panelW - 12

        var newX = frame.origin.x
        var newY = frame.origin.y
        var detectedMode = "free"

        let isNearTop = abs(frame.maxY - visFrame.maxY) <= 36 || frame.maxY > visFrame.maxY
        let isNearRight = abs(frame.maxX - (visFrame.maxX - 12)) <= 40 || frame.maxX > (visFrame.maxX - 12)
        let isNearLeft = abs(frame.minX - leftSnapX) <= 40 || frame.minX < leftSnapX

        let wasDetached = UserDefaults.standard.bool(forKey: PrefKey.isVelcroDetached)

        if isNearTop {
            newY = topMenuBarY
            if wasDetached {
                // Snapped back to menu bar like velcro!
                UserDefaults.standard.set(false, forKey: PrefKey.isVelcroDetached)
                HapticFeedback.playVelcroSnap()
                NotificationCenter.default.post(name: NSNotification.Name("NexusVelcroStateChanged"), object: false)
            }
        } else {
            // Dragged away from the top bar - rip off like velcro!
            detectedMode = "free"
            if !wasDetached {
                UserDefaults.standard.set(true, forKey: PrefKey.isVelcroDetached)
                HapticFeedback.playVelcroRip()
                NotificationCenter.default.post(name: NSNotification.Name("NexusVelcroStateChanged"), object: true)
            }
        }

        if isNearTop {
            if isNearRight {
                newX = rightSnapX
                detectedMode = "right"
            } else if isNearLeft {
                newX = leftSnapX
                detectedMode = "left"
            } else if let btn = (NSApp.delegate as? AppDelegate)?.statusItem?.button,
                      let btnFrame = btn.window?.convertToScreen(btn.convert(btn.bounds, to: nil)),
                      btnFrame.width > 0 {
                let iconMidX = btnFrame.midX - (panelW / 2.0)
                if abs(frame.origin.x - iconMidX) <= 36 {
                    newX = max(leftSnapX, min(rightSnapX, iconMidX))
                    detectedMode = "icon"
                }
            }
        }

        UserDefaults.standard.set(detectedMode, forKey: PrefKey.menuBarSnapMode)

        if newX != frame.origin.x || newY != frame.origin.y {
            HapticFeedback.tick()
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.28
                ctx.timingFunction = CAMediaTimingFunction(controlPoints: 0.16, 1.0, 0.3, 1.0)
                window.animator().setFrameOrigin(CGPoint(x: newX, y: newY))
            }
        }

        if detectedMode == "free" {
            UserDefaults.standard.set(Double(newX), forKey: PrefKey.popoverCustomX)
            UserDefaults.standard.set(Double(newY), forKey: PrefKey.popoverCustomY)
        } else {
            UserDefaults.standard.removeObject(forKey: PrefKey.popoverCustomX)
            UserDefaults.standard.removeObject(forKey: PrefKey.popoverCustomY)
        }

        NotificationCenter.default.post(name: NSNotification.Name("NexusSnapModeUpdated"), object: detectedMode)

        return detectedMode
    }

    func windowDidEndLiveResize(_ notification: Notification) {
        UserDefaults.standard.set(Double(self.frame.width), forKey: PrefKey.popoverCustomWidth)
        UserDefaults.standard.set(Double(self.frame.height), forKey: PrefKey.popoverCustomHeight)
        UserDefaults.standard.set(Double(self.frame.origin.x), forKey: PrefKey.popoverCustomX)
        UserDefaults.standard.set(Double(self.frame.origin.y), forKey: PrefKey.popoverCustomY)
    }

    func windowDidResize(_ notification: Notification) {
        UserDefaults.standard.set(Double(self.frame.width), forKey: PrefKey.popoverCustomWidth)
        UserDefaults.standard.set(Double(self.frame.height), forKey: PrefKey.popoverCustomHeight)
    }
}

// MARK: - NSHostingView subclass accepting first click & active mouse tracking

class NexusHostingView<Content: View>: NSHostingView<Content> {
    private var trackingArea: NSTrackingArea?
    private var touchStartPositions: [Int: CGPoint] = [:]

    required init(rootView: Content) {
        super.init(rootView: rootView)
        self.allowedTouchTypes = [.indirect]
        self.wantsRestingTouches = true
    }

    @objc required dynamic init?(coder: NSCoder) {
        super.init(coder: coder)
        self.allowedTouchTypes = [.indirect]
        self.wantsRestingTouches = true
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }

    override func layout() {
        super.layout()
        if let sub = subviews.first {
            sub.frame = self.bounds
        }
    }

    override func touchesBegan(with event: NSEvent) {
        let touches = event.touches(matching: .touching, in: self)
        for touch in touches {
            touchStartPositions[touch.identity.hash] = touch.normalizedPosition
        }
        super.touchesBegan(with: event)
    }

    override func touchesMoved(with event: NSEvent) {
        let touches = event.touches(matching: .touching, in: self)
        if touches.count >= 3 {
            var totalDeltaY: CGFloat = 0
            var totalDeltaX: CGFloat = 0
            var count: CGFloat = 0
            for touch in touches {
                if let start = touchStartPositions[touch.identity.hash] {
                    totalDeltaY += (touch.normalizedPosition.y - start.y)
                    totalDeltaX += (touch.normalizedPosition.x - start.x)
                    count += 1
                }
            }
            if count >= 3 {
                let avgDeltaY = totalDeltaY / count
                let avgDeltaX = totalDeltaX / count
                if abs(avgDeltaX) > abs(avgDeltaY) {
                    if avgDeltaX < -0.030 {
                        NotificationCenter.default.post(name: NSNotification.Name("NexusThreeFingerDragLeft"), object: nil)
                        touchStartPositions.removeAll()
                    } else if avgDeltaX > 0.030 {
                        NotificationCenter.default.post(name: NSNotification.Name("NexusThreeFingerDragRight"), object: nil)
                        touchStartPositions.removeAll()
                    }
                } else {
                    if avgDeltaY > 0.030 {
                        NotificationCenter.default.post(name: NSNotification.Name("NexusThreeFingerDragUp"), object: nil)
                        SpatialPlaneManager.shared.toggleZoomOutPlane()
                        touchStartPositions.removeAll()
                    } else if avgDeltaY < -0.030 {
                        NotificationCenter.default.post(name: NSNotification.Name("NexusThreeFingerDragDown"), object: nil)
                        touchStartPositions.removeAll()
                    }
                }
            }
        }
        super.touchesMoved(with: event)
    }

    override func touchesEnded(with event: NSEvent) {
        let touches = event.touches(matching: .ended, in: self)
        for touch in touches {
            touchStartPositions.removeValue(forKey: touch.identity.hash)
        }
        super.touchesEnded(with: event)
    }

    override func touchesCancelled(with event: NSEvent) {
        touchStartPositions.removeAll()
        super.touchesCancelled(with: event)
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }
        let options: NSTrackingArea.Options = [
            .mouseMoved, .mouseEnteredAndExited, .activeAlways, .inVisibleRect,
        ]
        trackingArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        if let trackingArea = trackingArea {
            addTrackingArea(trackingArea)
        }
    }
}

// MARK: - Native Window Dragging Component

struct WindowDragAreaView: NSViewRepresentable {
    func makeNSView(context: Context) -> WindowDragNSView {
        return WindowDragNSView()
    }

    func updateNSView(_ nsView: WindowDragNSView, context: Context) {}
}

class WindowDragNSView: NSView {
    private var initialMouseScreenLoc: CGPoint?
    private var dragStartOrigin: CGPoint?

    override func mouseDown(with event: NSEvent) {
        guard let win = self.window else { return }
        initialMouseScreenLoc = NSEvent.mouseLocation
        dragStartOrigin = win.frame.origin
        // Use native macOS performDrag
        win.performDrag(with: event)
        // Magnetically snap to top menu bar and left/right edges upon drag completion
        MenuBarPopoverPanel.applyMagneticSnapping(to: win)
        NotificationCenter.default.post(name: NSWindow.didMoveNotification, object: win)
    }

    override func mouseDragged(with event: NSEvent) {
        guard let win = self.window else { return }
        if let startOrigin = dragStartOrigin, let startMouse = initialMouseScreenLoc {
            let curMouse = NSEvent.mouseLocation
            let dx = curMouse.x - startMouse.x
            let dy = curMouse.y - startMouse.y
            win.setFrameOrigin(CGPoint(x: startOrigin.x + dx, y: startOrigin.y + dy))
        }
        NotificationCenter.default.post(name: NSWindow.didMoveNotification, object: win)
    }

    override func mouseUp(with event: NSEvent) {
        dragStartOrigin = nil
        initialMouseScreenLoc = nil
        guard let win = self.window else { return }
        NotificationCenter.default.post(name: NSWindow.didMoveNotification, object: win)
    }
}

