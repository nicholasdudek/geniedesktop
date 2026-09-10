import AppKit
import Foundation
import SwiftUI
import CoreGraphics
import QuartzCore

// MARK: - 📁 Tiny Folder-Sized App Pocket Model
/// Represents an application window that has been pocketed down to physical folder icon size (80x80 pt)
/// without modifying the application's internal window size, layout, or minimum window constraints.
public struct PocketedAppItem: Identifiable, Equatable, Sendable {
    public let id: CGWindowID
    public let processId: pid_t
    public let appName: String
    public let bundleIdentifier: String?
    public var originalBounds: CGRect
    public var pocketPosition: CGPoint
    public var isLiveActive: Bool
    public var scale: CGFloat // e.g. 0.08 to 0.12 (Exact folder icon scale)
    public var title: String

    public init(
        id: CGWindowID,
        processId: pid_t,
        appName: String,
        bundleIdentifier: String?,
        originalBounds: CGRect,
        pocketPosition: CGPoint,
        isLiveActive: Bool = true,
        scale: CGFloat = 0.10,
        title: String = ""
    ) {
        self.id = id
        self.processId = processId
        self.appName = appName
        self.bundleIdentifier = bundleIdentifier
        self.originalBounds = originalBounds
        self.pocketPosition = pocketPosition
        self.isLiveActive = isLiveActive
        self.scale = scale
        self.title = title
    }
}

// MARK: - 🎛️ Tiny Folder App Pocket Engine
/// High-performance Swift engine enabling any macOS program to shrink down to a compact desktop folder size (80×80 pt)
/// without resizing the application's actual window frame.
///
/// Mechanics:
/// 1. Hardware Compositor Scaling: Applies affine scale transforms directly via SkyLight WindowServer bridge (0.10x).
/// 2. Zero Window Reflow: The target app maintains its full native canvas (e.g. 1920x1080), avoiding UI truncation.
/// 3. Folder-Sized Desktop Snapping: Drag, park, and cluster pocketed apps anywhere on the desktop like folders.
/// 4. Instant Peep-Hole & One-Click Expansion: Hover for high-DPI live peep, click to spring back to full screen.
@MainActor
public final class TinyFolderAppPocketEngine: ObservableObject {
    public static let shared = TinyFolderAppPocketEngine()

    // ── Standard macOS Folder Icon Dimensions ───────────────────────────────────
    public static let defaultFolderSize = CGSize(width: 84, height: 84)
    public static let microFolderSize = CGSize(width: 64, height: 64)
    public static let jumboFolderSize = CGSize(width: 110, height: 110)

    // ── Published Observable States ─────────────────────────────────────────────
    @Published public var pocketedApps: [PocketedAppItem] = []
    @Published public var activeFolderSize: CGSize = defaultFolderSize
    @Published public var isPocketOverlayVisible: Bool = true
    @Published public var hoveredWindowId: CGWindowID? = nil
    @Published public var peekWindowId: CGWindowID? = nil
    @Published public var liveThumbnailMap: [CGWindowID: NSImage] = [:]

    // ── Telemetry & Settings ───────────────────────────────────────────────────
    @AppStorage(PrefKey.tinyFolderSpringStiffness) public var springStiffness: Double = 32.0
    @AppStorage(PrefKey.tinyFolderHoverExpand) public var hoverExpandEnabled: Bool = true
    @AppStorage(PrefKey.tinyFolderShowBadge) public var showAppBadge: Bool = true

    private let skyLight = SkyLightWindowServerTransformBridge.shared
    private var streamTimer: Timer?

    private init() {
        startThumbnailRefresher()
    }

    // MARK: - 1. Pocket Active / Frontmost Application
    /// Pockets the frontmost application window down to folder size without changing its window bounds
    public func pocketFrontmostApp(at dropPoint: CGPoint? = nil) {
        guard let frontApp = NSWorkspace.shared.frontmostApplication,
              frontApp.bundleIdentifier != Bundle.main.bundleIdentifier else { return }

        // Find frontmost window ID of this process
        let windowListInfo = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []
        for info in windowListInfo {
            let pid = (info[kCGWindowOwnerPID as String] as? pid_t) ?? 0
            let layer = (info[kCGWindowLayer as String] as? Int32) ?? 0
            let wid = (info[kCGWindowNumber as String] as? CGWindowID) ?? 0

            if pid == frontApp.processIdentifier && layer == 0 && wid > 0 {
                pocketWindow(windowId: wid, processId: pid, appName: frontApp.localizedName ?? "App", at: dropPoint)
                return
            }
        }
    }

    /// Pockets a running application by process identifier (PID)
    public func pocketApp(pid: pid_t, at dropPoint: CGPoint? = nil) {
        let windowListInfo = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] ?? []
        for info in windowListInfo {
            let winPid = (info[kCGWindowOwnerPID as String] as? pid_t) ?? 0
            let layer = (info[kCGWindowLayer as String] as? Int32) ?? 0
            let wid = (info[kCGWindowNumber as String] as? CGWindowID) ?? 0
            let name = (info[kCGWindowOwnerName as String] as? String) ?? "App"

            if winPid == pid && layer == 0 && wid > 0 {
                pocketWindow(windowId: wid, processId: pid, appName: name, at: dropPoint)
                return
            }
        }
    }

    // MARK: - 2. Pocket Specified Window ID
    public func pocketWindow(windowId: CGWindowID, processId: pid_t, appName: String, at targetPoint: CGPoint? = nil) {
        // Prevent double-pocketing
        if let existing = pocketedApps.first(where: { $0.id == windowId }) {
            restoreWindow(windowId: existing.id)
            return
        }

        guard let bounds = fetchWindowBounds(windowId: windowId) else { return }

        // Compute exact folder scale factor
        let targetSize = activeFolderSize
        let scaleX = targetSize.width / max(1.0, bounds.width)
        let scaleY = targetSize.height / max(1.0, bounds.height)
        let uniformScale = min(scaleX, scaleY)

        let initialPoint: CGPoint = targetPoint ?? defaultNextPocketPosition()

        let pocketItem = PocketedAppItem(
            id: windowId,
            processId: processId,
            appName: appName,
            bundleIdentifier: NSWorkspace.shared.runningApplications.first(where: { $0.processIdentifier == processId })?.bundleIdentifier,
            originalBounds: bounds,
            pocketPosition: initialPoint,
            isLiveActive: true,
            scale: uniformScale,
            title: appName
        )

        // 1. Apply hardware transform to shrink window to folder size
        if skyLight.isAvailable {
            let transform = CGAffineTransform(scaleX: uniformScale, y: uniformScale)
            skyLight.setWindowTransform(windowId: windowId, transform: transform)
            skyLight.setWindowOrigin(windowId: windowId, origin: initialPoint)
        }

        // 2. Capture instantaneous high-DPI thumbnail
        captureThumbnail(for: windowId, bounds: bounds)

        // 3. Register pocketed item
        pocketedApps.append(pocketItem)
        HapticFeedback.selection()
    }

    // MARK: - 3. Restore Pocketed Window Back to 1.0x Full Size
    public func restoreWindow(windowId: CGWindowID) {
        guard let index = pocketedApps.firstIndex(where: { $0.id == windowId }) else { return }
        let item = pocketedApps[index]

        // Reset hardware transform to 1.0x identity
        if skyLight.isAvailable {
            skyLight.resetWindowTransform(windowId: windowId)
            skyLight.setWindowOrigin(windowId: windowId, origin: item.originalBounds.origin)
        }

        // Bring the restored application to the front
        if let app = NSWorkspace.shared.runningApplications.first(where: { $0.processIdentifier == item.processId }) {
            app.unhide()
            app.activate(options: [.activateAllWindows])
        }

        pocketedApps.remove(at: index)
        liveThumbnailMap.removeValue(forKey: windowId)
        HapticFeedback.selection()
    }

    // MARK: - 4. Restore All Pocketed Windows
    public func restoreAll() {
        let allIds = pocketedApps.map { $0.id }
        for wid in allIds {
            restoreWindow(windowId: wid)
        }
    }

    // MARK: - 5. Drag & Reposition Folder Pocket
    public func movePocket(windowId: CGWindowID, to newPosition: CGPoint) {
        guard let index = pocketedApps.firstIndex(where: { $0.id == windowId }) else { return }
        pocketedApps[index].pocketPosition = newPosition

        if skyLight.isAvailable {
            skyLight.setWindowOrigin(windowId: windowId, origin: newPosition)
        }
    }

    // MARK: - Helper Methods
    private func defaultNextPocketPosition() -> CGPoint {
        let screen = NSScreen.main?.visibleFrame ?? CGRect(x: 0, y: 0, width: 1440, height: 900)
        let margin: CGFloat = 36.0
        let slotIndex = pocketedApps.count
        let col = slotIndex % 4
        let row = slotIndex / 4

        let x = screen.maxX - margin - activeFolderSize.width - (CGFloat(col) * (activeFolderSize.width + 16))
        let y = screen.minY + margin + (CGFloat(row) * (activeFolderSize.height + 28))
        return CGPoint(x: x, y: y)
    }

    private func fetchWindowBounds(windowId: CGWindowID) -> CGRect? {
        let list = CGWindowListCopyWindowInfo([.optionIncludingWindow], windowId) as? [[String: Any]] ?? []
        guard let first = list.first, let boundsDict = first[kCGWindowBounds as String] as? [String: Any] else { return nil }
        return CGRect(dictionaryRepresentation: boundsDict as CFDictionary)
    }

    private func captureThumbnail(for windowId: CGWindowID, bounds: CGRect) {
        if let imgRef = safeCGWindowListCreateImage(bounds, .optionIncludingWindow, windowId, [.bestResolution]) {
            let nsImg = NSImage(cgImage: imgRef, size: activeFolderSize)
            self.liveThumbnailMap[windowId] = nsImg
        }
    }

    private func startThumbnailRefresher() {
        streamTimer?.invalidate()
        streamTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, !self.pocketedApps.isEmpty else { return }
                for app in self.pocketedApps {
                    self.captureThumbnail(for: app.id, bounds: app.originalBounds)
                }
            }
        }
    }
}
