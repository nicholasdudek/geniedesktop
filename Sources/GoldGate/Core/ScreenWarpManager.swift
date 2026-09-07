import AppKit
import Foundation
import SwiftUI

// MARK: - Screen Warp Manager (Blazing Fast Display-to-Display Register Teleportation)
// Solves the decades-old macOS problem of moving applications between screens instantly.
@MainActor
public final class ScreenWarpManager: ObservableObject {
    public static let shared = ScreenWarpManager()

    @Published public var lastWarpedAppName: String? = nil
    private var globalKeyMonitor: Any? = nil
    private var localKeyMonitor: Any? = nil

    private init() {}

    deinit {
        if let g = globalKeyMonitor { NSEvent.removeMonitor(g) }
        if let l = localKeyMonitor { NSEvent.removeMonitor(l) }
    }

    public func setup() {
        registerGlobalKeyShortcuts()
    }

    // MARK: - Global Keyboard Shortcuts (⌃⌥→ Next Screen, ⌃⌥← Previous Screen)

    private func registerGlobalKeyShortcuts() {
        if globalKeyMonitor != nil { return }

        // Local monitor when app is active
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.handleKeyEvent(event) == true {
                return nil
            }
            return event
        }

        // Global monitor for when any other app is frontmost
        globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            Task { @MainActor in
                _ = self?.handleKeyEvent(event)
            }
        }
    }

    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        let flags = event.modifierFlags.intersection([.control, .option, .command, .shift])
        // Check for Control + Option (⌃⌥)
        guard flags == [.control, .option] else { return false }

        // Right Arrow (keyCode 124) -> Next Screen
        if event.keyCode == 124 {
            moveFrontmostWindowToNextScreen(direction: 1)
            return true
        }
        // Left Arrow (keyCode 123) -> Previous Screen
        if event.keyCode == 123 {
            moveFrontmostWindowToNextScreen(direction: -1)
            return true
        }
        // Return Key (keyCode 36) -> Maximize to Top Edge (Edge-to-Edge through Menu Bar)
        if event.keyCode == 36 {
            SmartGridManager.shared.maximizeFrontmostWindowToTopEdge(includeMenuBarArea: true)
            return true
        }
        return false
    }

    // MARK: - Instant Frontmost Window Teleportation

    /// Moves the frontmost focused window to the next (or previous) display register in sub-milliseconds
    public func moveFrontmostWindowToNextScreen(direction: Int = 1) {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else {
            NSSound.beep()
            return
        }
        moveAppWindowsToNextScreen(pid: frontApp.processIdentifier, direction: direction)
    }

    /// Moves the frontmost window directly to a specific target display register
    public func moveFrontmostWindow(to targetScreenIndex: Int) {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else {
            NSSound.beep()
            return
        }
        moveAppWindowsToScreen(pid: frontApp.processIdentifier, targetScreenIndex: targetScreenIndex)
    }

    /// Moves the frontmost window directly to a specific target NSScreen
    public func moveFrontmostWindow(to targetScreen: NSScreen) {
        if let idx = NSScreen.screens.firstIndex(of: targetScreen) {
            moveFrontmostWindow(to: idx)
        }
    }

    /// Moves all windows of a specific application (by pid) to the next display register (or next virtual extended screen)
    public func moveAppWindowsToNextScreen(pid: pid_t, direction: Int = 1) {
        let screens = NSScreen.screens
        if screens.count <= 1 {
            // Single monitor: Teleport across Virtual Extended Screens / Spatial Desktops!
            let currentSpace = MacDesktopsManager.shared.currentSpaceIndex
            let totalSpaces = max(3, MacDesktopsManager.shared.spaces.count)
            let nextVirtualSpace = ((currentSpace - 1 + direction + totalSpaces) % totalSpaces) + 1

            // Teleport window via SkyLight / Accessibility to next virtual space
            SmartGridManager.shared.moveAppToDesktop(pid: pid, targetDesktopIndex: nextVirtualSpace)
            MacDesktopsManager.shared.switchToDesktop(index: nextVirtualSpace)
            lastWarpedAppName = "Virtual Screen \(nextVirtualSpace)"
            HapticFeedback.heavy()
            NSSound(named: "Pop")?.play()
            return
        }

        guard let currentScreenIndex = detectScreenIndexForApp(pid: pid) else {
            // Fallback to moving to secondary screen
            moveAppWindowsToScreen(pid: pid, targetScreenIndex: 1 % screens.count)
            return
        }

        let targetIndex = (currentScreenIndex + direction + screens.count) % screens.count
        moveAppWindowsToScreen(pid: pid, targetScreenIndex: targetIndex)
    }

    /// Blazing fast teleportation of an application's windows to a specific target display register
    public func moveAppWindowsToScreen(pid: pid_t, targetScreenIndex: Int) {
        let screens = NSScreen.screens
        guard targetScreenIndex >= 0 && targetScreenIndex < screens.count else { return }
        let targetScreen = screens[targetScreenIndex]
        guard let primaryScreen = screens.first else { return }
        let primaryHeight = primaryScreen.frame.height

        let appElement = AXUIElementCreateApplication(pid)
        var windowListRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowListRef)
        guard result == .success, let windowList = windowListRef as? [AXUIElement], !windowList.isEmpty else {
            // Fallback via AppleScript System Events if AX is restricted
            moveViaAppleScript(pid: pid, targetScreen: targetScreen)
            return
        }

        // Detect current screen of the main window to calculate proportional offset
        let sourceScreenIndex = detectScreenIndexForApp(pid: pid) ?? 0
        let sourceScreen = screens.indices.contains(sourceScreenIndex) ? screens[sourceScreenIndex] : (screens.first ?? targetScreen)

        HapticFeedback.heavy()
        NSSound(named: "Pop")?.play()

        for winElement in windowList {
            // Unminimize if minimized
            AXUIElementSetAttributeValue(winElement, kAXMinimizedAttribute as CFString, kCFBooleanFalse)

            // Read current window position and size in Quartz coordinates
            var posRef: CFTypeRef?
            var sizeRef: CFTypeRef?
            var currentPos = CGPoint.zero
            var currentSize = CGSize(width: 800, height: 600)

            if AXUIElementCopyAttributeValue(winElement, kAXPositionAttribute as CFString, &posRef) == .success,
               let val = posRef, CFGetTypeID(val) == AXValueGetTypeID() {
                let axVal = val as! AXValue
                _ = AXValueGetValue(axVal, .cgPoint, &currentPos)
            }

            if AXUIElementCopyAttributeValue(winElement, kAXSizeAttribute as CFString, &sizeRef) == .success,
               let val = sizeRef, CFGetTypeID(val) == AXValueGetTypeID() {
                let axVal = val as! AXValue
                _ = AXValueGetValue(axVal, .cgSize, &currentSize)
            }

            // Convert Quartz coordinate (top-left 0,0) to Cocoa coordinate (bottom-left 0,0)
            let cocoaWinX = currentPos.x
            let cocoaWinY = primaryHeight - (currentPos.y + currentSize.height)

            // Calculate relative proportions on source screen
            let srcVis = sourceScreen.visibleFrame
            let relX = (cocoaWinX - srcVis.origin.x) / max(1.0, srcVis.width)
            let relY = (cocoaWinY - srcVis.origin.y) / max(1.0, srcVis.height)
            let relW = min(1.0, currentSize.width / max(1.0, srcVis.width))
            let relH = min(1.0, currentSize.height / max(1.0, srcVis.height))

            // Compute target frame on destination screen
            let dstVis = targetScreen.visibleFrame
            let newWidth = max(400, min(dstVis.width, relW * dstVis.width))
            let newHeight = max(300, min(dstVis.height, relH * dstVis.height))
            var newCocoaX = dstVis.origin.x + (relX * dstVis.width)
            var newCocoaY = dstVis.origin.y + (relY * dstVis.height)

            // Clamp inside target visible frame
            newCocoaX = max(dstVis.minX, min(newCocoaX, dstVis.maxX - newWidth))
            newCocoaY = max(dstVis.minY, min(newCocoaY, dstVis.maxY - newHeight))

            // Convert back to Quartz coordinates for AXUIElement
            var targetQuartzPt = CGPoint(
                x: newCocoaX,
                y: primaryHeight - (newCocoaY + newHeight)
            )
            var targetQuartzSize = CGSize(width: newWidth, height: newHeight)

            // Set size and position instantaneously in memory via WindowServer
            if let sizeVal = AXValueCreate(.cgSize, &targetQuartzSize) {
                _ = AXUIElementSetAttributeValue(winElement, kAXSizeAttribute as CFString, sizeVal)
            }
            if let posVal = AXValueCreate(.cgPoint, &targetQuartzPt) {
                _ = AXUIElementSetAttributeValue(winElement, kAXPositionAttribute as CFString, posVal)
            }

            // Bring window to front
            AXUIElementPerformAction(winElement, kAXRaiseAction as CFString)
        }

        // Record feedback
        if let app = NSRunningApplication(processIdentifier: pid) {
            self.lastWarpedAppName = app.localizedName
        }
    }

    // MARK: - Screen Detection Helpers

    public func detectScreenIndexForApp(pid: pid_t) -> Int? {
        let screens = NSScreen.screens
        guard let primary = screens.first else { return nil }
        let primaryHeight = primary.frame.height

        let appElement = AXUIElementCreateApplication(pid)
        var windowRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &windowRef) != .success {
            var listRef: CFTypeRef?
            _ = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &listRef)
            if let list = listRef as? [AXUIElement], let first = list.first {
                windowRef = first
            }
        }

        guard let ref = windowRef, CFGetTypeID(ref) == AXUIElementGetTypeID() else { return nil }
        let winElem = (ref as! AXUIElement)

        var posRef: CFTypeRef?
        var currentPos = CGPoint.zero
        if AXUIElementCopyAttributeValue(winElem, kAXPositionAttribute as CFString, &posRef) == .success,
           let val = posRef, CFGetTypeID(val) == AXValueGetTypeID() {
            let axVal = val as! AXValue
            _ = AXValueGetValue(axVal, .cgPoint, &currentPos)
        }

        // Convert to Cocoa coordinate
        let cocoaPt = CGPoint(x: currentPos.x + 50, y: primaryHeight - (currentPos.y + 50))
        for (idx, screen) in screens.enumerated() {
            if screen.frame.contains(cocoaPt) {
                return idx
            }
        }
        return 0
    }

    private func centerAndFitWindow(pid: pid_t) {
        guard let screen = NSScreen.main else { return }
        let vis = screen.visibleFrame
        let appElement = AXUIElementCreateApplication(pid)
        var windowRef: CFTypeRef?
        _ = AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &windowRef)
        guard let ref = windowRef, CFGetTypeID(ref) == AXUIElementGetTypeID() else { return }
        let winElem = (ref as! AXUIElement)

        var sz = CGSize(width: min(vis.width * 0.85, 1200), height: min(vis.height * 0.85, 800))
        var pt = CGPoint(x: vis.midX - sz.width / 2, y: screen.frame.height - (vis.midY + sz.height / 2))

        if let sVal = AXValueCreate(.cgSize, &sz) {
            _ = AXUIElementSetAttributeValue(winElem, kAXSizeAttribute as CFString, sVal)
        }
        if let pVal = AXValueCreate(.cgPoint, &pt) {
            _ = AXUIElementSetAttributeValue(winElem, kAXPositionAttribute as CFString, pVal)
        }
        AXUIElementPerformAction(winElem, kAXRaiseAction as CFString)
    }

    private func moveViaAppleScript(pid: pid_t, targetScreen: NSScreen) {
        let vis = targetScreen.visibleFrame
        guard let primary = NSScreen.screens.first else { return }
        let qY = primary.frame.height - (vis.maxY - 40)
        let script = """
        tell application "System Events"
            set procList to every process whose unix id is \(pid)
            if (count of procList) > 0 then
                set p to item 1 of procList
                tell p
                    if (count of windows) > 0 then
                        set position of window 1 to {\(Int(vis.minX + 20)), \(Int(qY))}
                    end if
                end tell
            end if
        end tell
        """
        DispatchQueue.global(qos: .userInteractive).async {
            var error: NSDictionary?
            if let appleScript = NSAppleScript(source: script) {
                appleScript.executeAndReturnError(&error)
            }
        }
    }
}
