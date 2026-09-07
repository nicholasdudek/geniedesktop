import AppKit
import Foundation

// MARK: - Smart Tiling & Window Management Engine
// Provides instantaneous keyboard-driven window layouts: halves, thirds, quarters, and golden ratio.

public enum TilingPosition: String, CaseIterable {
    case leftHalf = "Left Half"
    case rightHalf = "Right Half"
    case topHalf = "Top Half"
    case bottomHalf = "Bottom Half"
    case topLeftQuarter = "Top-Left Quarter"
    case topRightQuarter = "Top-Right Quarter"
    case bottomLeftQuarter = "Bottom-Left Quarter"
    case bottomRightQuarter = "Bottom-Right Quarter"
    case leftTwoThirds = "Left Two-Thirds"
    case rightOneThird = "Right One-Third"
    case centerGolden = "Center Golden Ratio"
    case maximize = "Maximize"

    public var shortcutHint: String {
        switch self {
        case .leftHalf: return "⌥⌘←"
        case .rightHalf: return "⌥⌘→"
        case .topHalf: return "⌥⌘↑"
        case .bottomHalf: return "⌥⌘↓"
        case .topLeftQuarter: return "⌃⌥←"
        case .topRightQuarter: return "⌃⌥→"
        case .bottomLeftQuarter: return "⌃⌥↓"
        case .bottomRightQuarter: return "⌃⌥↑"
        case .leftTwoThirds: return "⌥⌘["
        case .rightOneThird: return "⌥⌘]"
        case .centerGolden: return "⌥⌘C"
        case .maximize: return "⌥⌘F"
        }
    }
}

public final class GenieSmartTilingEngine {
    public static let shared = GenieSmartTilingEngine()

    public func calculateTargetFrame(for position: TilingPosition, on screen: NSScreen) -> CGRect {
        let visibleFrame = screen.visibleFrame
        let x = visibleFrame.origin.x
        let y = visibleFrame.origin.y
        let w = visibleFrame.width
        let h = visibleFrame.height

        switch position {
        case .leftHalf:
            return CGRect(x: x, y: y, width: w * 0.5, height: h)
        case .rightHalf:
            return CGRect(x: x + w * 0.5, y: y, width: w * 0.5, height: h)
        case .topHalf:
            return CGRect(x: x, y: y + h * 0.5, width: w, height: h * 0.5)
        case .bottomHalf:
            return CGRect(x: x, y: y, width: w, height: h * 0.5)
        case .topLeftQuarter:
            return CGRect(x: x, y: y + h * 0.5, width: w * 0.5, height: h * 0.5)
        case .topRightQuarter:
            return CGRect(x: x + w * 0.5, y: y + h * 0.5, width: w * 0.5, height: h * 0.5)
        case .bottomLeftQuarter:
            return CGRect(x: x, y: y, width: w * 0.5, height: h * 0.5)
        case .bottomRightQuarter:
            return CGRect(x: x + w * 0.5, y: y, width: w * 0.5, height: h * 0.5)
        case .leftTwoThirds:
            return CGRect(x: x, y: y, width: w * (2.0 / 3.0), height: h)
        case .rightOneThird:
            return CGRect(x: x + w * (2.0 / 3.0), y: y, width: w * (1.0 / 3.0), height: h)
        case .centerGolden:
            let gw = w * 0.618
            let gh = h * 0.618
            return CGRect(x: x + (w - gw) * 0.5, y: y + (h - gh) * 0.5, width: gw, height: gh)
        case .maximize:
            return visibleFrame
        }
    }

    /// Tile the frontmost active application window
    @MainActor
    public func tileFrontmostWindow(to position: TilingPosition) {
        guard let frontApp = NSWorkspace.shared.frontmostApplication,
              let screen = NSScreen.main else { return }

        let targetRect = calculateTargetFrame(for: position, on: screen)
        let pid = frontApp.processIdentifier
        let appRef = AXUIElementCreateApplication(pid)

        var windowValue: AnyObject?
        let result = AXUIElementCopyAttributeValue(appRef, kAXFocusedWindowAttribute as CFString, &windowValue)
        guard result == .success, let focusedWindow = windowValue,
              CFGetTypeID(focusedWindow) == AXUIElementGetTypeID() else { return }

        let windowElement = focusedWindow as! AXUIElement
        var origin = targetRect.origin
        // AX coordinates: y=0 is top of primary display
        if let primaryScreen = NSScreen.screens.first {
            origin.y = primaryScreen.frame.height - (targetRect.origin.y + targetRect.height)
        }

        var size = targetRect.size
        if let posVal = AXValueCreate(.cgPoint, &origin),
           let sizeVal = AXValueCreate(.cgSize, &size) {
            AXUIElementSetAttributeValue(windowElement, kAXPositionAttribute as CFString, posVal)
            AXUIElementSetAttributeValue(windowElement, kAXSizeAttribute as CFString, sizeVal)
        }
    }
}
