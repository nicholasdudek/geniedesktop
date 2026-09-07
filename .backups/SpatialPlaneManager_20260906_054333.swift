import AppKit
import Foundation
import SwiftUI
import ScreenCaptureKit

// MARK: - Spatial Cardinal Direction
public enum SpatialPlaneDirection: String, CaseIterable, Sendable {
    case east = "East (Right)"
    case west = "West (Left)"
    case north = "North (Up)"
    case south = "South (Down)"

    public var opposite: SpatialPlaneDirection {
        switch self {
        case .east: return .west
        case .west: return .east
        case .north: return .south
        case .south: return .north
        }
    }

    public var arrowIcon: String {
        switch self {
        case .east: return "arrow.right"
        case .west: return "arrow.left"
        case .north: return "arrow.up"
        case .south: return "arrow.down"
        }
    }
}

// MARK: - Desktop Plane RAM Cache Model
public struct DesktopPlaneRAMCache: Identifiable {
    public let id: Int // Slot 1..9
    public var name: String
    public var compass: String
    public var col: Int // 0..2
    public var row: Int // 0..2
    public var windows: [ManagedWindowInfo] = []
    public var runningAppNames: [String] = []
    public var runningAppIcons: [NSImage] = []
    public var thumbnail: NSImage? = nil
    public var wallpaper: NSImage? = nil
    public var isCurrent: Bool = false
    public var lastUpdated: Date = Date()
}

// MARK: - Spatial Plane Manager
// Orchestrates the 9-Desktop 3x3 Spatial Plane, RAM Pre-loading,
// and Continuous Edge Window Passing ("Extended Desktop on a Lap").
@MainActor
public final class SpatialPlaneManager: ObservableObject {
    public static let shared = SpatialPlaneManager()

    // ── Published States ──
    @Published public var isZoomedOut: Bool = false
    @Published public var focusedPlaneIndex: Int = 5 // Center/Home by default
    @Published public var ramBuffers: [Int: DesktopPlaneRAMCache] = [:]
    @Published public var activeEdgeAura: SpatialPlaneDirection? = nil
    @Published public var isPreloadingRAM: Bool = false
    @Published public var lastEdgeTransportMessage: String? = nil

    // ── Continuous 9-Desktop Scrollable Canvas & Above-Level Cursor ──
    @AppStorage("nexus.aboveLevelCursorEnabled") public var aboveLevelCursorEnabled: Bool = true
    @AppStorage("nexus.continuousCanvasFormation") public var continuousCanvasFormation: String = "1:1 Continuous Mega-Canvas"
    @Published public var macroCameraOffset: CGSize = .zero
    @Published public var macroTargetSpaceIndex: Int = 1

    // ── Settings ──
    @AppStorage("nexus.extendedDesktopEdgeGlideEnabled") public var edgeGlideEnabled: Bool = true
    @AppStorage("nexus.preloadExtraDesktopInRAM") public var preloadExtraDesktopInRAM: Bool = true

    // ── Internal Monitors & State ──
    private var globalMouseDragMonitor: Any? = nil
    private var globalMouseUpMonitor: Any? = nil
    private var globalScrollMonitor: Any? = nil
    private var globalKeyMonitor: Any? = nil
    private var localKeyMonitor: Any? = nil
    private var edgeDwellTimer: Timer? = nil
    private var edgeEnterTime: TimeInterval = 0.0
    private var candidateEdgeDirection: SpatialPlaneDirection? = nil
    private var lastEdgeCrossingTime: TimeInterval = 0.0
    private var overlayWindow: NSWindow? = nil
    private var isDraggingActive: Bool = false

    private init() {
        initializeRAMBuffers()
    }

    deinit {
        if let m = globalMouseDragMonitor { NSEvent.removeMonitor(m) }
        if let u = globalMouseUpMonitor { NSEvent.removeMonitor(u) }
        if let s = globalScrollMonitor { NSEvent.removeMonitor(s) }
        if let k = globalKeyMonitor { NSEvent.removeMonitor(k) }
        if let l = localKeyMonitor { NSEvent.removeMonitor(l) }
        edgeDwellTimer?.invalidate()
    }

    // MARK: - Setup
    public func setup() {
        Self.tuneOSFor9GridSpaces()
        registerGlobalDragMonitors()
        registerGlobalHotkeys()
        ensureExtraDesktopPreloaded()
        refreshAllRAMBuffers()

        // Listen for space changes to keep RAM buffers synchronized
        NotificationCenter.default.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshAllRAMBuffers()
            }
        }
    }

    // MARK: - 3x3 Spatial Plane Coordinate System
    // Row 0: [1: NW]  [2: N]  [3: NE]
    // Row 1: [4: W]   [5: C]  [6: E]
    // Row 2: [7: SW]  [8: S]  [9: SE]

    public static func gridCoordinate(for index: Int) -> (col: Int, row: Int) {
        let clamped = max(1, min(9, index))
        let row = (clamped - 1) / 3
        let col = (clamped - 1) % 3
        return (col, row)
    }

    public static func indexForGrid(col: Int, row: Int) -> Int {
        let c = max(0, min(2, col))
        let r = max(0, min(2, row))
        return r * 3 + c + 1
    }

    public static func compassBearing(for index: Int) -> String {
        switch index {
        case 1: return "NW"
        case 2: return "North"
        case 3: return "NE"
        case 4: return "West"
        case 5: return "Center • Home"
        case 6: return "East"
        case 7: return "SW"
        case 8: return "South"
        case 9: return "SE"
        default: return "Space \(index)"
        }
    }

    public func neighbor(from index: Int, direction: SpatialPlaneDirection) -> Int? {
        let (col, row) = Self.gridCoordinate(for: index)
        switch direction {
        case .east:
            return col < 2 ? Self.indexForGrid(col: col + 1, row: row) : nil
        case .west:
            return col > 0 ? Self.indexForGrid(col: col - 1, row: row) : nil
        case .north:
            return row > 0 ? Self.indexForGrid(col: col, row: row - 1) : nil
        case .south:
            return row < 2 ? Self.indexForGrid(col: col, row: row + 1) : nil
        }
    }

    // MARK: - RAM Pre-loading Engine
    // Keeps extra virtual desktop spaces allocated and warm in memory.

    public func ensureExtraDesktopPreloaded() {
        guard preloadExtraDesktopInRAM else { return }
        let currentSpaces = MacDesktopsManager.shared.spaces
        if currentSpaces.count < 2 {
            self.isPreloadingRAM = true
            _ = MacDesktopsManager.shared.executeHardwareSpaceCreation()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                MacDesktopsManager.shared.refreshSpaces()
                self?.isPreloadingRAM = false
                self?.refreshAllRAMBuffers()
            }
        }
    }

    private func initializeRAMBuffers() {
        for idx in 1...9 {
            let (col, row) = Self.gridCoordinate(for: idx)
            let compass = Self.compassBearing(for: idx)
            ramBuffers[idx] = DesktopPlaneRAMCache(
                id: idx,
                name: "Desktop \(idx)",
                compass: compass,
                col: col,
                row: row,
                wallpaper: WallpaperManager.shared.activeWallpaperImage
            )
        }
    }

    public func refreshAllRAMBuffers() {
        let currentIdx = MacDesktopsManager.shared.currentSpaceIndex
        self.focusedPlaneIndex = max(1, min(9, currentIdx))

        let currentWP = WallpaperManager.shared.activeWallpaperImage
        let screens = NSScreen.screens
        let primaryHeight = screens.first?.frame.height ?? 1080

        // Query visible application windows
        let currentWindows = SmartGridManager.shared.getVisibleWindows(primaryHeight: primaryHeight)

        for idx in 1...9 {
            let isCur = (idx == currentIdx)
            var buffer = ramBuffers[idx] ?? DesktopPlaneRAMCache(
                id: idx,
                name: "Desktop \(idx)",
                compass: Self.compassBearing(for: idx),
                col: Self.gridCoordinate(for: idx).col,
                row: Self.gridCoordinate(for: idx).row
            )

            buffer.isCurrent = isCur
            if isCur {
                buffer.windows = currentWindows
                buffer.wallpaper = currentWP
                buffer.thumbnail = MacDesktopsManager.shared.desktopLivePreviews[idx] ?? currentWP
                buffer.runningAppNames = Array(Set(currentWindows.map { $0.ownerName }))
                buffer.runningAppIcons = buffer.runningAppNames.compactMap { name in
                    NSWorkspace.shared.runningApplications.first(where: { $0.localizedName == name })?.icon
                }
            } else {
                if buffer.wallpaper == nil {
                    buffer.wallpaper = currentWP
                }
                if let preview = MacDesktopsManager.shared.desktopLivePreviews[idx] {
                    buffer.thumbnail = preview
                }
            }
            buffer.lastUpdated = Date()
            ramBuffers[idx] = buffer
        }
    }

    // MARK: - Continuous Edge Window Dragging ("Dual Monitors on a Lap")
    // Detects when user drags a window to the screen boundary and seamlessly transports
    // it to the neighboring desktop on the 3x3 plane.

    private func registerGlobalDragMonitors() {
        if globalMouseDragMonitor != nil { return }

        // Monitor left mouse drag events globally
        globalMouseDragMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDragged]) { [weak self] event in
            Task { @MainActor [weak self] in
                self?.handleMouseDragged(event)
            }
        }

        // Monitor left mouse up events globally to clear aura and reset timers
        globalMouseUpMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseUp]) { [weak self] event in
            Task { @MainActor [weak self] in
                self?.handleMouseUp(event)
            }
        }

        // Monitor global scroll wheel events for 3-finger Above-Level Cursor panning
        globalScrollMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.scrollWheel]) { [weak self] event in
            Task { @MainActor [weak self] in
                self?.handleScrollWheel(event)
            }
        }
    }

    // MARK: - Above-Level Cursor & Trackpad Scroll Pan
    public func handleScrollWheel(_ event: NSEvent) {
        guard isZoomedOut, aboveLevelCursorEnabled else { return }
        let factor: CGFloat = event.hasPreciseScrollingDeltas ? 1.35 : 12.0
        let dx = event.scrollingDeltaX * factor
        let dy = event.scrollingDeltaY * factor

        macroCameraOffset.width += dx
        macroCameraOffset.height += dy

        // Clamp within canvas bounds
        let maxPanX: CGFloat = 360.0
        let maxPanY: CGFloat = 260.0
        macroCameraOffset.width = max(-maxPanX, min(maxPanX, macroCameraOffset.width))
        macroCameraOffset.height = max(-maxPanY, min(maxPanY, macroCameraOffset.height))

        updateFocusedSectorFromCamera()
    }

    private func updateFocusedSectorFromCamera() {
        let colOffset = Int(round(macroCameraOffset.width / 180.0))
        let rowOffset = Int(round(-macroCameraOffset.height / 140.0))

        let targetCol = max(0, min(2, 1 + colOffset))
        let targetRow = max(0, min(2, 1 + rowOffset))
        let targetSlot = Self.indexForGrid(col: targetCol, row: targetRow)
        if targetSlot != focusedPlaneIndex {
            focusedPlaneIndex = targetSlot
            macroTargetSpaceIndex = targetSlot
            HapticFeedback.selection()
        }
    }

    private func handleMouseDragged(_ event: NSEvent) {
        guard edgeGlideEnabled, !isZoomedOut else { return }

        let now = Date().timeIntervalSince1970
        // Cooldown between cross-desktop transports (0.6s) to prevent rapid ping-pong
        guard now - lastEdgeCrossingTime > 0.6 else { return }

        let mouseLoc = NSEvent.mouseLocation
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(mouseLoc) }) ?? NSScreen.main else { return }
        let f = screen.frame
        let edgeThreshold: CGFloat = 4.0

        var detectedDir: SpatialPlaneDirection? = nil

        // Right edge
        if mouseLoc.x >= f.maxX - edgeThreshold {
            detectedDir = .east
        }
        // Left edge
        else if mouseLoc.x <= f.minX + edgeThreshold {
            detectedDir = .west
        }
        // Top edge (avoiding center notch area if custom menu bar is present)
        else if mouseLoc.y >= f.maxY - edgeThreshold && abs(mouseLoc.x - f.midX) > 120 {
            detectedDir = .north
        }
        // Bottom edge
        else if mouseLoc.y <= f.minY + edgeThreshold && abs(mouseLoc.x - f.midX) > 140 {
            detectedDir = .south
        }

        guard let dir = detectedDir else {
            // Mouse exited edge zone
            if candidateEdgeDirection != nil {
                candidateEdgeDirection = nil
                activeEdgeAura = nil
                edgeDwellTimer?.invalidate()
                edgeDwellTimer = nil
            }
            return
        }

        // Mouse entered or is dwelling at edge
        if candidateEdgeDirection != dir {
            candidateEdgeDirection = dir
            edgeEnterTime = now
            activeEdgeAura = dir

            // Schedule edge dwell trigger (0.16s dwell is buttery responsive without false triggers)
            edgeDwellTimer?.invalidate()
            let timer = Timer(timeInterval: 0.16, repeats: false) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    let mousePoint = NSEvent.mouseLocation
                    let sc = NSScreen.screens.first(where: { $0.frame.contains(mousePoint) }) ?? NSScreen.main
                    if let sc = sc {
                        self.triggerContinuousEdgeTransport(direction: dir, screen: sc)
                    }
                }
            }
            RunLoop.main.add(timer, forMode: .common)
            edgeDwellTimer = timer
        }
    }

    private func handleMouseUp(_ event: NSEvent) {
        candidateEdgeDirection = nil
        activeEdgeAura = nil
        edgeDwellTimer?.invalidate()
        edgeDwellTimer = nil
    }

    // Executes the seamless cross-desktop window transport
    private func triggerContinuousEdgeTransport(direction: SpatialPlaneDirection, screen: NSScreen) {
        guard let dir = candidateEdgeDirection, dir == direction else { return }
        candidateEdgeDirection = nil
        activeEdgeAura = nil
        edgeDwellTimer?.invalidate()
        edgeDwellTimer = nil

        let currentIdx = MacDesktopsManager.shared.currentSpaceIndex
        guard let targetIdx = neighbor(from: currentIdx, direction: direction) else {
            // At boundary of 3x3 plane (e.g. Right edge on East-most column)
            NSSound(named: "Tink")?.play()
            return
        }

        // Ensure target desktop is available
        MacDesktopsManager.shared.refreshSpaces()
        if targetIdx > MacDesktopsManager.shared.spaces.count {
            _ = MacDesktopsManager.shared.executeHardwareSpaceCreation()
            MacDesktopsManager.shared.refreshSpaces()
        }

        // Find the frontmost window being dragged (excluding Genie itself)
        let myPid = ProcessInfo.processInfo.processIdentifier
        var targetApp = NSWorkspace.shared.frontmostApplication
        if targetApp == nil || targetApp?.processIdentifier == myPid {
            let otherApps = NSWorkspace.shared.runningApplications
                .filter { $0.activationPolicy == .regular && $0.processIdentifier != myPid && !$0.isTerminated }
            targetApp = otherApps.first
        }
        guard let app = targetApp, app.processIdentifier != myPid else { return }

        let pid = app.processIdentifier
        let primaryHeight = NSScreen.screens.first?.frame.height ?? 1080
        let visibleWindows = SmartGridManager.shared.getVisibleWindows(primaryHeight: primaryHeight)
        guard let winInfo = visibleWindows.first(where: { $0.pid == pid }) else { return }

        // Compute entering window position on destination screen (Dual-monitor continuous geometry!)
        let vis = screen.visibleFrame
        var newX = winInfo.frame.minX
        var newY = winInfo.frame.minY

        switch direction {
        case .east:
            // Exiting Right -> Enters from Left border
            newX = vis.minX + 24
        case .west:
            // Exiting Left -> Enters from Right border
            newX = vis.maxX - winInfo.frame.width - 24
        case .north:
            // Exiting Top -> Enters from Bottom border
            newY = vis.minY + 40
        case .south:
            // Exiting Bottom -> Enters from Top border
            newY = vis.maxY - winInfo.frame.height - 40
        }

        // Reposition window in memory
        let appElem = AXUIElementCreateApplication(pid)
        var windowListRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(appElem, kAXWindowsAttribute as CFString, &windowListRef) == .success,
           let windowList = windowListRef as? [AXUIElement], let frontWin = windowList.first {
            var targetPt = CGPoint(x: newX, y: primaryHeight - (newY + winInfo.frame.height))
            if let posVal = AXValueCreate(.cgPoint, &targetPt) {
                _ = AXUIElementSetAttributeValue(frontWin, kAXPositionAttribute as CFString, posVal)
            }
        }

        // Teleport window to target desktop space via SkyLight
        SmartGridManager.shared.moveAppToDesktop(pid: pid, targetDesktopIndex: targetIdx)

        // Haptic & Sound feedback (Satisfying portal glide)
        HapticFeedback.heavy()
        NSSound(named: "Pop")?.play()

        // Switch to the target space so the user travels with the window!
        MacDesktopsManager.shared.switchToDesktop(index: targetIdx)

        // Re-activate application in destination space
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            app.activate()
        }

        lastEdgeCrossingTime = Date().timeIntervalSince1970
        lastEdgeTransportMessage = "Glided \(app.localizedName ?? "App") to Desktop \(targetIdx) (\(Self.compassBearing(for: targetIdx))) ✨"
    }

    // MARK: - Global Hotkeys & Trackpad Pinch
    private func registerGlobalHotkeys() {
        if globalKeyMonitor != nil { return }

        // ⌘⌥9: Toggle 9-Desktop Spatial Plane Zoom
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.handleKeyEvent(event) == true {
                return nil
            }
            return event
        }

        globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            Task { @MainActor in
                _ = self?.handleKeyEvent(event)
            }
        }
    }

    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        let flags = event.modifierFlags.intersection([.command, .option, .control, .shift])
        
        // 1. ⌘⌥9 (keyCode 25 is '9'): Toggle 3x3 Spatial Overview Plane
        if flags == [.command, .option] && event.keyCode == 25 {
            toggleZoomOutPlane()
            return true
        }

        // 2. 2D 9-Grid Spatial Navigation via ^⌥[Arrow Keys] or ⌘⌥[Arrow Keys]
        // Left: 123, Right: 124, Down: 125, Up: 126
        if flags == [.control, .option] || (flags == [.command, .option] && !isZoomedOut) {
            let currentIdx = MacDesktopsManager.shared.currentSpaceIndex
            var targetDir: SpatialPlaneDirection? = nil

            switch event.keyCode {
            case 124: targetDir = .east   // Move East (Right in 3x3 Grid: 1->2, 2->3, 4->5, etc.)
            case 123: targetDir = .west   // Move West (Left in 3x3 Grid: 3->2, 2->1, 6->5, etc.)
            case 125: targetDir = .south  // Move South (Down in 3x3 Grid: 1->4, 2->5, 3->6, 4->7, 5->8, 6->9)
            case 126: targetDir = .north  // Move North (Up in 3x3 Grid: 7->4, 8->5, 9->6, 4->1, 5->2, 6->3)
            default: break
            }

            if let dir = targetDir, let targetIdx = neighbor(from: currentIdx, direction: dir) {
                HapticFeedback.heavy()
                MacDesktopsManager.shared.switchToDesktop(index: targetIdx)
                return true
            }
        }

        // 3. Direct 9-Grid Number Jumps via ⌘⌥1..8 (when not zoomed out)
        if flags == [.command, .option] && !isZoomedOut {
            let numMap: [UInt16: Int] = [
                18: 1, 19: 2, 20: 3,
                21: 4, 23: 5, 22: 6,
                26: 7, 28: 8
            ]
            if let slot = numMap[event.keyCode] {
                HapticFeedback.heavy()
                MacDesktopsManager.shared.switchToDesktop(index: slot)
                return true
            }
        }

        return false
    }

    // MARK: - OS Spaces 9-Grid Reprogramming
    public static func tuneOSFor9GridSpaces() {
        // Disable MRU space shuffling so spaces 1..9 stay fixed in their 3x3 spots
        UserDefaults(suiteName: "com.apple.dock")?.set(false, forKey: "mru-spaces")
        CFPreferencesSetValue("mru-spaces" as CFString, kCFBooleanFalse, "com.apple.dock" as CFString, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
        CFPreferencesSynchronize("com.apple.dock" as CFString, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)
    }

    public func handleMagnification(delta: CGFloat) {
        if delta < -0.12 && !isZoomedOut {
            // Pinch out -> Zoom to 9-Desktop Plane
            zoomOutToPlane()
        } else if delta > 0.12 && isZoomedOut {
            // Pinch in -> Zoom into focused desktop
            zoomInToSelectedDesktop()
        }
    }

    // MARK: - Zoom In / Zoom Out Plane Controller

    public func toggleZoomOutPlane() {
        if isZoomedOut {
            zoomInToSelectedDesktop()
        } else {
            zoomOutToPlane()
        }
    }

    public func zoomOutToPlane() {
        guard !isZoomedOut else { return }
        refreshAllRAMBuffers()
        let currentIdx = max(1, min(9, MacDesktopsManager.shared.currentSpaceIndex))
        focusedPlaneIndex = currentIdx

        let screen = NSScreen.main ?? NSScreen.screens.first
        let screenW = screen?.frame.width ?? 1440.0
        let screenH = screen?.frame.height ?? 900.0
        let (col, row) = Self.gridCoordinate(for: currentIdx)

        if continuousCanvasFormation == "1:1 Continuous Mega-Canvas" {
            macroCameraOffset = CGSize(width: -CGFloat(col) * screenW, height: -CGFloat(row) * screenH)
        } else {
            macroCameraOffset = .zero
        }

        HapticFeedback.heavy()
        NSSound(named: "Blow")?.play()

        showOverlayWindow()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            self.isZoomedOut = true
        }
    }

    public func zoomInToSelectedDesktop(index: Int? = nil) {
        let target = index ?? focusedPlaneIndex
        HapticFeedback.heavy()
        NSSound(named: "Pop")?.play()

        withAnimation(.spring(response: 0.30, dampingFraction: 0.85)) {
            self.isZoomedOut = false
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
            self?.hideOverlayWindow()
            MacDesktopsManager.shared.switchToDesktop(index: target)
        }
    }

    private func showOverlayWindow() {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }
        if overlayWindow == nil {
            let win = NSWindow(
                contentRect: screen.frame,
                styleMask: [.borderless, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            win.isOpaque = false
            win.backgroundColor = .clear
            win.hasShadow = false
            win.level = .floating
            win.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
            win.isExcludedFromWindowsMenu = true
            win.sharingType = .none
            win.hidesOnDeactivate = false
            win.acceptsMouseMovedEvents = true
            win.contentView = SpatialTouchHostingView(rootView: SpatialDesktopPlaneCanvasView())
            self.overlayWindow = win
        }
        overlayWindow?.setFrame(screen.frame, display: true)
        overlayWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate()
    }

    private func hideOverlayWindow() {
        overlayWindow?.orderOut(nil)
    }

    public func handleThreeFingerScrollDelta(dx: CGFloat, dy: CGFloat) {
        guard isZoomedOut else { return }
        let screen = NSScreen.main ?? NSScreen.screens.first
        let screenW = screen?.frame.width ?? 1440.0
        let screenH = screen?.frame.height ?? 900.0

        if continuousCanvasFormation == "1:1 Continuous Mega-Canvas" {
            macroCameraOffset.width += dx
            macroCameraOffset.height += dy

            let minX = -screenW * 2.0
            let minY = -screenH * 2.0
            macroCameraOffset.width = max(minX, min(0, macroCameraOffset.width))
            macroCameraOffset.height = max(minY, min(0, macroCameraOffset.height))

            let targetCol = min(2, max(0, Int(round(-macroCameraOffset.width / screenW))))
            let targetRow = min(2, max(0, Int(round(-macroCameraOffset.height / screenH))))
            let newSlot = Self.indexForGrid(col: targetCol, row: targetRow)
            if newSlot != focusedPlaneIndex {
                focusedPlaneIndex = newSlot
                macroTargetSpaceIndex = newSlot
                HapticFeedback.selection()
            }
        } else {
            macroCameraOffset.width += dx * 0.35
            macroCameraOffset.height += dy * 0.35
            let maxPan: CGFloat = 360.0
            macroCameraOffset.width = max(-maxPan, min(maxPan, macroCameraOffset.width))
            macroCameraOffset.height = max(-maxPan, min(maxPan, macroCameraOffset.height))
            updateFocusedSectorFromCamera()
        }
    }

    public func updateTrackpadDirectSector(slotIndex: Int, normalized: CGPoint) {
        guard isZoomedOut else { return }
        let clamped = max(1, min(9, slotIndex))
        if clamped != focusedPlaneIndex {
            focusedPlaneIndex = clamped
            macroTargetSpaceIndex = clamped
            HapticFeedback.selection()
        }
        let offsetX = (normalized.x - 0.5) * 360.0
        let offsetY = -(normalized.y - 0.5) * 260.0
        withAnimation(.interactiveSpring(response: 0.2, dampingFraction: 0.85)) {
            macroCameraOffset = CGSize(width: offsetX, height: offsetY)
        }
    }
}

// MARK: - Spatial Touch Hosting View
// Enables direct and indirect trackpad multi-touch recognition so the physical trackpad's
// 3x3 geometry maps 1-to-1 to the 9 desktops ("the track pad has all the right spots for it").
public final class SpatialTouchHostingView<Content: View>: NSHostingView<Content> {
    private var lastThreeFingerPosition: CGPoint? = nil

    @MainActor public required dynamic init(rootView: Content) {
        super.init(rootView: rootView)
        self.allowedTouchTypes = [.indirect, .direct]
    }

    @MainActor public required dynamic init?(coder: NSCoder) {
        super.init(coder: coder)
        self.allowedTouchTypes = [.indirect, .direct]
    }

    public override func touchesBegan(with event: NSEvent) {
        handleTrackpadTouch(event)
        super.touchesBegan(with: event)
    }

    public override func touchesMoved(with event: NSEvent) {
        handleTrackpadTouch(event)
        super.touchesMoved(with: event)
    }

    private func handleTrackpadTouch(_ event: NSEvent) {
        let touches = event.touches(matching: .touching, in: self)

        // ── 3-Finger Continuous Panning Across 1:1 Canvas ──
        if touches.count >= 3 {
            var sumX: CGFloat = 0
            var sumY: CGFloat = 0
            for t in touches {
                sumX += t.normalizedPosition.x
                sumY += t.normalizedPosition.y
            }
            let avgX = sumX / CGFloat(touches.count)
            let avgY = sumY / CGFloat(touches.count)
            let currentPos = CGPoint(x: avgX, y: avgY)

            if let last = lastThreeFingerPosition {
                let screen = NSScreen.main ?? NSScreen.screens.first
                let screenW = screen?.frame.width ?? 1440.0
                let screenH = screen?.frame.height ?? 900.0
                let dx = (currentPos.x - last.x) * screenW * 2.5
                let dy = (currentPos.y - last.y) * screenH * 2.5
                SpatialPlaneManager.shared.handleThreeFingerScrollDelta(dx: dx, dy: dy)
            }
            lastThreeFingerPosition = currentPos
            return
        } else {
            lastThreeFingerPosition = nil
        }

        // ── 1-Finger Direct Spot Snapping ──
        guard let primary = touches.first else { return }
        let norm = primary.normalizedPosition
        let col = min(2, max(0, Int(norm.x * 3.0)))
        let row = min(2, max(0, 2 - Int(norm.y * 3.0))) // Inverted Y: row 0 is top
        let slotIndex = SpatialPlaneManager.indexForGrid(col: col, row: row)
        SpatialPlaneManager.shared.updateTrackpadDirectSector(slotIndex: slotIndex, normalized: norm)
    }

    public override func touchesEnded(with event: NSEvent) {
        lastThreeFingerPosition = nil
        super.touchesEnded(with: event)
    }

    public override func touchesCancelled(with event: NSEvent) {
        lastThreeFingerPosition = nil
        super.touchesCancelled(with: event)
    }
}