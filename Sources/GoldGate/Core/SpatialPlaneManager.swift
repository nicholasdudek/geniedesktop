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
    public let id: Int // Slot 1..9 (or 1..81 in universe mode)
    public var name: String
    public var compassOrientation: String
    public var columnCoordinate: Int // 0..2 (or 0..8)
    public var rowCoordinate: Int // 0..2 (or 0..8)
    public var windows: [ManagedWindowInfo] = []
    public var runningAppNames: [String] = []
    public var runningAppIcons: [NSImage] = []
    public var thumbnail: NSImage? = nil
    public var wallpaper: NSImage? = nil
    public var isCurrent: Bool = false
    public var lastUpdated: Date = Date()

    // ── Backward-compatible property aliases ──
    public var compass: String {
        get { compassOrientation }
        set { compassOrientation = newValue }
    }
    public var col: Int {
        get { columnCoordinate }
        set { columnCoordinate = newValue }
    }
    public var row: Int {
        get { rowCoordinate }
        set { rowCoordinate = newValue }
    }

    public init(
        id: Int,
        name: String,
        compassOrientation: String,
        columnCoordinate: Int,
        rowCoordinate: Int,
        windows: [ManagedWindowInfo] = [],
        runningAppNames: [String] = [],
        runningAppIcons: [NSImage] = [],
        thumbnail: NSImage? = nil,
        wallpaper: NSImage? = nil,
        isCurrent: Bool = false,
        lastUpdated: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.compassOrientation = compassOrientation
        self.columnCoordinate = columnCoordinate
        self.rowCoordinate = rowCoordinate
        self.windows = windows
        self.runningAppNames = runningAppNames
        self.runningAppIcons = runningAppIcons
        self.thumbnail = thumbnail
        self.wallpaper = wallpaper
        self.isCurrent = isCurrent
        self.lastUpdated = lastUpdated
    }

    public init(
        id: Int,
        name: String,
        compass: String,
        col: Int,
        row: Int,
        windows: [ManagedWindowInfo] = [],
        runningAppNames: [String] = [],
        runningAppIcons: [NSImage] = [],
        thumbnail: NSImage? = nil,
        wallpaper: NSImage? = nil,
        isCurrent: Bool = false,
        lastUpdated: Date = Date()
    ) {
        self.init(
            id: id,
            name: name,
            compassOrientation: compass,
            columnCoordinate: col,
            rowCoordinate: row,
            windows: windows,
            runningAppNames: runningAppNames,
            runningAppIcons: runningAppIcons,
            thumbnail: thumbnail,
            wallpaper: wallpaper,
            isCurrent: isCurrent,
            lastUpdated: lastUpdated
        )
    }
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
    @Published public var activeMacroPixelSector: Int = 5 // Sector 5 (Center • Home)
    @AppStorage(PrefKey.isUniverse81Active) public var isUniverse81Active: Bool = false // Default spatial plane is 9 sectors (3x3 grid)
    @Published public var desktopPlaneCacheBuffers: [Int: DesktopPlaneRAMCache] = [:]
    public var ramBuffers: [Int: DesktopPlaneRAMCache] {
        get { desktopPlaneCacheBuffers }
        set { desktopPlaneCacheBuffers = newValue }
    }
    @Published public var spatialAppRegistry: [Int: [ManagedWindowInfo]] = [:]
    @Published public var activeEdgeAura: SpatialPlaneDirection? = nil
    @Published public var isPreloadingRAM: Bool = false
    @Published public var lastEdgeTransportMessage: String? = nil

    @Published public var vectorZoomScale: CGFloat = 0.45 // Continuous 2D Vector Space Zoom (0.15x to 1.0x)
    @AppStorage(PrefKey.vectorSnappingEnabled) public var vectorSnappingEnabled: Bool = false // Continuous vector panning without rigid snap locking

    // ── Continuous 9-Desktop Scrollable Canvas & Above-Level Cursor ──
    @AppStorage(PrefKey.aboveLevelCursorEnabled) public var aboveLevelCursorEnabled: Bool = true
    @AppStorage(PrefKey.continuousCanvasFormation) public var continuousCanvasFormation: String = "1:1 Continuous Mega-Canvas"
    @AppStorage(PrefKey.screenWebpagePanMode) public var screenWebpagePanMode: String = "Hand Drag & Scroll" // "Hand Drag & Scroll", "Screen Follows Cursor"
    @AppStorage(PrefKey.cursorFollowPanningEnabled) public var cursorFollowPanningEnabled: Bool = false
    @Published public var macroCameraOffset: CGSize = .zero
    @Published public var macroTargetSpaceIndex: Int = 1
    @Published public var lastThreeFingerJumpTimestamp: TimeInterval = 0.0
    @AppStorage(PrefKey.gridZoomFitMode) public var gridZoomFitMode: String = "2x2 Grid"

    // ── Settings ──
    @AppStorage(PrefKey.extendedDesktopEdgeGlideEnabled) public var edgeGlideEnabled: Bool = true
    @AppStorage(PrefKey.preloadExtraDesktopInRAM) public var preloadExtraDesktopInRAM: Bool = true

    // ── Internal Monitors & State ──
    private var globalMouseDragMonitor: Any? = nil
    private var globalMouseUpMonitor: Any? = nil
    private var globalScrollMonitor: Any? = nil
    private var globalKeyMonitor: Any? = nil
    private var localKeyMonitor: Any? = nil
    private var notificationObservers: [NSObjectProtocol] = []
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
        for obs in notificationObservers {
            NotificationCenter.default.removeObserver(obs)
            NSWorkspace.shared.notificationCenter.removeObserver(obs)
            DistributedNotificationCenter.default().removeObserver(obs)
        }
        notificationObservers.removeAll()

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

        // Clean up previous observers before re-registering
        for obs in notificationObservers {
            NotificationCenter.default.removeObserver(obs)
            NSWorkspace.shared.notificationCenter.removeObserver(obs)
            DistributedNotificationCenter.default().removeObserver(obs)
        }
        notificationObservers.removeAll()

        // Listen for space changes to keep RAM buffers synchronized
        let o1 = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.refreshAllRAMBuffers()
            }
        }
        notificationObservers.append(o1)

        let o2 = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NexusToggleSpatialCanvas"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.toggleZoomOutPlane()
            }
        }
        notificationObservers.append(o2)

        let o3 = DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("com.nicholasdudek.genie.toggleSpatialCanvas"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.toggleZoomOutPlane()
            }
        }
        notificationObservers.append(o3)
    }


    // MARK: - 9x9 Big Screen Universe & 3x3 Pixel Geometry
    // Universe: 9x9 = 81 screens (the default desktop size).
    // Pixel Size: 3x3 = 9 screens (each macro-pixel / quantum sector).
    // Physical Monitor: 1x1 sub-pixel focal atom.
    public nonisolated static let universeDimension: Int = 9 // 9 columns x 9 rows = 81
    public nonisolated static let pixelDimension: Int = 3    // 3 columns x 3 rows = 9
    public nonisolated static let totalUniverseScreens: Int = 81
    public nonisolated static let totalMacroPixels: Int = 9

    // Returns (columnCoordinate: 0..8, rowCoordinate: 0..8) in the 81-screen universe
    public nonisolated static func universeCoordinate(for index: Int) -> (col: Int, row: Int) {
        let clampedIndex = max(1, min(totalUniverseScreens, index))
        let rowCoordinate = (clampedIndex - 1) / universeDimension
        let columnCoordinate = (clampedIndex - 1) % universeDimension
        return (columnCoordinate, rowCoordinate)
    }

    // Maps (columnCoordinate: 0..8, rowCoordinate: 0..8) to index 1..81
    public nonisolated static func indexForUniverse(columnCoordinate: Int, rowCoordinate: Int) -> Int {
        let clampedCol = max(0, min(8, columnCoordinate))
        let clampedRow = max(0, min(8, rowCoordinate))
        return clampedRow * universeDimension + clampedCol + 1
    }

    @inlinable
    public nonisolated static func indexForUniverse(col: Int, row: Int) -> Int {
        indexForUniverse(columnCoordinate: col, rowCoordinate: row)
    }

    // Macro-Pixel Sector (1..9) containing a slot (1..81)
    public nonisolated static func macroPixelSector(for slotIndex: Int) -> (sector: Int, compass: String, pCol: Int, pRow: Int) {
        let (columnCoordinate, rowCoordinate) = universeCoordinate(for: slotIndex)
        let pixelColumn = columnCoordinate / pixelDimension
        let pixelRow = rowCoordinate / pixelDimension
        let sectorIndex = pixelRow * 3 + pixelColumn + 1
        let compassBearing = compassBearing(for: sectorIndex)
        return (sectorIndex, compassBearing, pixelColumn, pixelRow)
    }

    // Center slot for a macro-pixel sector (1..9)
    public nonisolated static func centerSlotForSector(_ sectorIndex: Int) -> Int {
        let clampedSector = max(1, min(9, sectorIndex))
        let pixelRow = (clampedSector - 1) / 3
        let pixelColumn = (clampedSector - 1) % 3
        let centerColumn = pixelColumn * 3 + 1
        let centerRow = pixelRow * 3 + 1
        return indexForUniverse(columnCoordinate: centerColumn, rowCoordinate: centerRow)
    }

    // All slots in a 3x3 macro-pixel sector (1..9)
    public nonisolated static func slotsInMacroPixelSector(_ sectorIndex: Int) -> [Int] {
        let clampedSector = max(1, min(9, sectorIndex))
        let pixelRow = (clampedSector - 1) / 3
        let pixelCol = (clampedSector - 1) % 3
        var sectorSlots: [Int] = []
        for r in 0..<3 {
            for c in 0..<3 {
                let col = pixelCol * 3 + c
                let row = pixelRow * 3 + r
                sectorSlots.append(indexForUniverse(columnCoordinate: col, rowCoordinate: row))
            }
        }
        return sectorSlots
    }

    // MARK: - 3x3 Spatial Plane Coordinate System (Legacy & Local Pixel Compatible)
    public nonisolated static func gridCoordinate(for index: Int) -> (col: Int, row: Int) {
        if index > 9 {
            return universeCoordinate(for: index)
        }
        let clampedIndex = max(1, min(9, index))
        let rowCoordinate = (clampedIndex - 1) / 3
        let columnCoordinate = (clampedIndex - 1) % 3
        return (columnCoordinate, rowCoordinate)
    }

    public nonisolated static func indexForGrid(columnCoordinate: Int, rowCoordinate: Int) -> Int {
        if columnCoordinate > 2 || rowCoordinate > 2 {
            return indexForUniverse(columnCoordinate: columnCoordinate, rowCoordinate: rowCoordinate)
        }
        let clampedCol = max(0, min(2, columnCoordinate))
        let clampedRow = max(0, min(2, rowCoordinate))
        return clampedRow * 3 + clampedCol + 1
    }

    @inlinable
    public nonisolated static func indexForGrid(col: Int, row: Int) -> Int {
        indexForGrid(columnCoordinate: col, rowCoordinate: row)
    }

    public nonisolated static func compassBearing(for index: Int) -> String {
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
            return col < 2 ? Self.indexForGrid(col: col + 1, row: row) : Self.indexForGrid(col: 0, row: row)
        case .west:
            return col > 0 ? Self.indexForGrid(col: col - 1, row: row) : Self.indexForGrid(col: 2, row: row)
        case .north:
            return row > 0 ? Self.indexForGrid(col: col, row: row - 1) : Self.indexForGrid(col: col, row: 2)
        case .south:
            return row < 2 ? Self.indexForGrid(col: col, row: row + 1) : Self.indexForGrid(col: col, row: 0)
        }
    }

    // MARK: - RAM Pre-loading Engine
    // Keeps extra virtual desktop spaces allocated and warm in memory.

    public func ensureExtraDesktopPreloaded() {
        guard preloadExtraDesktopInRAM else { return }
        
        // Ensure RAM buffers are allocated and stitched for all 9 core desktops + 81 universe screens
        initializeRAMBuffers()
        refreshAllRAMBuffers()

        // PRELOAD 9 DESKTOPS: Warm up hardware-level WindowServer spaces up to a full 3x3 grid.
        // The whole spatial model assumes all nine slots exist, so this tops up to nine and then
        // verifies — WindowServer silently drops creation requests when they arrive too fast, and
        // the previous version also capped each pass at 7, so a one-space Mac never reached nine.
        createMissingGridSpaces(attemptsRemaining: 3)
    }

    private func createMissingGridSpaces(attemptsRemaining: Int) {
        MacDesktopsManager.shared.refreshSpaces()
        let existing = MacDesktopsManager.shared.spaces.count
        let needed = Self.totalGridSpaces - existing
        guard needed > 0, attemptsRemaining > 0 else {
            isPreloadingRAM = false
            refreshAllRAMBuffers()
            return
        }

        isPreloadingRAM = true
        for _ in 0..<needed {
            _ = MacDesktopsManager.shared.executeHardwareSpaceCreation()
        }

        // Re-check after WindowServer settles; anything it dropped gets retried.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            MainActor.assumeIsolated {
                self?.createMissingGridSpaces(attemptsRemaining: attemptsRemaining - 1)
            }
        }
    }

    /// The 3x3 plane is always nine slots — every sector lookup assumes all nine exist.
    public static let totalGridSpaces = 9

    private var themeWallpaperCache: [String: NSImage] = [:]

    private func themeWallpaper(for sector: Int) -> NSImage {
        let theme = MacDesktopsManager.curatedThemeForSlot(sector)
        if let cached = themeWallpaperCache[theme] {
            return cached
        }
        let wp = WallpaperManager.shared.generateCuratedWallpaper(named: theme)
        themeWallpaperCache[theme] = wp
        return wp
    }

    private func initializeRAMBuffers() {
        for screenIndex in 1...Self.totalUniverseScreens {
            let (columnCoordinate, rowCoordinate) = Self.universeCoordinate(for: screenIndex)
            let (sectorIndex, compassBearing, _, _) = Self.macroPixelSector(for: screenIndex)
            let distinctWP = themeWallpaper(for: sectorIndex)
            desktopPlaneCacheBuffers[screenIndex] = DesktopPlaneRAMCache(
                id: screenIndex,
                name: screenIndex <= 9 ? "Desktop \(screenIndex)" : "Screen \(screenIndex)",
                compassOrientation: screenIndex <= 9 ? Self.compassBearing(for: screenIndex) : "\(compassBearing) (\(screenIndex))",
                columnCoordinate: columnCoordinate,
                rowCoordinate: rowCoordinate,
                wallpaper: distinctWP
            )
        }
    }

    // MARK: - Desktop -1 Mirrored Coordinate Math
    public func mirrorCoordinatesToDesktopMinusOne(rect: CGRect) -> CGRect {
        let screen = NSScreen.main ?? NSScreen.screens.first ?? NSScreen()
        let screenWidth = screen.visibleFrame.width
        let mirroredOrigin = CGPoint(
            x: rect.origin.x - screenWidth,
            y: rect.origin.y
        )
        return CGRect(origin: mirroredOrigin, size: rect.size)
    }

    public func mirrorCoordinatesFromDesktopMinusOne(rect: CGRect) -> CGRect {
        let screen = NSScreen.main ?? NSScreen.screens.first ?? NSScreen()
        let screenWidth = screen.visibleFrame.width
        let homeOrigin = CGPoint(
            x: rect.origin.x + screenWidth,
            y: rect.origin.y
        )
        return CGRect(origin: homeOrigin, size: rect.size)
    }

    // MARK: - Spatial App Location Registry
    /// Moves an app window in the persistent spatial registry so that it remains anchored
    /// and remembered on its assigned desktop sector (1–9 or -1 Mirrored) across the connected plane.
    public func moveAppInSpatialRegistry(pid: pid_t, targetDesktopIndex: Int) {
        guard (targetDesktopIndex >= 1 && targetDesktopIndex <= 9) || targetDesktopIndex == -1 else { return }
        var movedWindows: [ManagedWindowInfo] = []

        // Extract window info for this PID from all registered slots in spatialAppRegistry
        for slotIndex in 1...Self.totalUniverseScreens {
            if let windows = spatialAppRegistry[slotIndex] {
                let matching = windows.filter { $0.pid == pid }
                if !matching.isEmpty {
                    movedWindows.append(contentsOf: matching)
                    spatialAppRegistry[slotIndex] = windows.filter { $0.pid != pid }
                }
            }
        }

        // Fallback: If not yet in registry, retrieve visible windows or construct from running app
        if movedWindows.isEmpty {
            let primaryHeight = NSScreen.screens.first?.frame.height ?? 1080
            let visible = SmartGridManager.shared.getVisibleWindows(primaryHeight: primaryHeight)
            let matchingVisible = visible.filter { $0.pid == pid }
            if !matchingVisible.isEmpty {
                movedWindows = matchingVisible
            } else if let app = NSWorkspace.shared.runningApplications.first(where: { $0.processIdentifier == pid }),
                      let appName = app.localizedName {
                movedWindows = [
                    ManagedWindowInfo(
                        id: CGWindowID(pid),
                        pid: pid,
                        ownerName: appName,
                        title: appName,
                        frame: CGRect(x: 100, y: 100, width: 800, height: 600)
                    )
                ]
            }
        }

        if !movedWindows.isEmpty {
            var targetWindows = spatialAppRegistry[targetDesktopIndex] ?? []
            let existingIDs = Set(targetWindows.map { $0.id })
            for win in movedWindows {
                if !existingIDs.contains(win.id) {
                    targetWindows.append(win)
                }
            }
            spatialAppRegistry[targetDesktopIndex] = targetWindows
        }

        refreshAllRAMBuffers()
    }

    public func refreshAllRAMBuffers() {
        let currentSpaceIndex = MacDesktopsManager.shared.currentSpaceIndex
        self.focusedPlaneIndex = max(1, min(Self.totalUniverseScreens, currentSpaceIndex))
        self.activeMacroPixelSector = Self.macroPixelSector(for: focusedPlaneIndex).sector

        let currentWP = WallpaperManager.shared.activeWallpaperImage
        let screens = NSScreen.screens
        let primaryHeight = screens.first?.frame.height ?? 1080

        // Query visible application windows for active desktop space
        let currentWindows = SmartGridManager.shared.getVisibleWindows(primaryHeight: primaryHeight)
        let filteredCurrentWindows = currentWindows.filter { $0.pid != ProcessInfo.processInfo.processIdentifier }

        // Live hardware space update: save current desktop's visible windows to registry
        spatialAppRegistry[currentSpaceIndex] = filteredCurrentWindows

        // Clean up PIDs: prune active currentSpaceIndex windows from other sectors to prevent ghost duplication,
        // and filter out terminated apps.
        let currentPIDs = Set(filteredCurrentWindows.map { $0.pid })
        let runningPIDs = Set(NSWorkspace.shared.runningApplications.map { $0.processIdentifier })

        for screenIndex in 1...Self.totalUniverseScreens {
            if screenIndex != currentSpaceIndex {
                if var existing = spatialAppRegistry[screenIndex] {
                    existing.removeAll { currentPIDs.contains($0.pid) || !runningPIDs.contains($0.pid) }
                    spatialAppRegistry[screenIndex] = existing
                }
            }
        }

        for screenIndex in 1...Self.totalUniverseScreens {
            let isCurrentDesktop = (screenIndex == currentSpaceIndex)
            let (columnCoordinate, rowCoordinate) = Self.universeCoordinate(for: screenIndex)
            let (sectorIndex, compassBearing, _, _) = Self.macroPixelSector(for: screenIndex)
            var buffer = desktopPlaneCacheBuffers[screenIndex] ?? DesktopPlaneRAMCache(
                id: screenIndex,
                name: screenIndex <= 9 ? "Desktop \(screenIndex)" : "Screen \(screenIndex)",
                compassOrientation: screenIndex <= 9 ? Self.compassBearing(for: screenIndex) : "\(compassBearing) (\(screenIndex))",
                columnCoordinate: columnCoordinate,
                rowCoordinate: rowCoordinate
            )

            buffer.isCurrent = isCurrentDesktop
            let assignedWindows = spatialAppRegistry[screenIndex] ?? (isCurrentDesktop ? filteredCurrentWindows : [])
            buffer.windows = assignedWindows
            buffer.runningAppNames = Array(Set(assignedWindows.map { $0.ownerName }))
            buffer.runningAppIcons = buffer.runningAppNames.compactMap { name in
                NSWorkspace.shared.runningApplications.first(where: { $0.localizedName == name })?.icon
            }

            if isCurrentDesktop {
                buffer.wallpaper = currentWP
                buffer.thumbnail = MacDesktopsManager.shared.desktopLivePreviews[screenIndex] ?? currentWP
            } else if screenIndex <= 9 {
                let distinctWP = themeWallpaper(for: screenIndex)
                buffer.wallpaper = distinctWP
                if let preview = MacDesktopsManager.shared.desktopLivePreviews[screenIndex], preview != currentWP {
                    buffer.thumbnail = preview
                } else {
                    buffer.thumbnail = distinctWP
                }
            } else {
                let distinctWP = themeWallpaper(for: sectorIndex)
                buffer.wallpaper = distinctWP
                buffer.thumbnail = distinctWP
            }
            buffer.lastUpdated = Date()
            desktopPlaneCacheBuffers[screenIndex] = buffer
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

    // MARK: - Discrete 3-Finger Screen Jumping (Scroll Panning Disabled)
    public func handleScrollWheel(_ event: NSEvent) {
        // Only jump or pan when explicitly zoomed out in the Spatial Plane canvas!
        // When not zoomed out, normal desktop & app scrolling is preserved with zero interference.
        guard isZoomedOut else { return }

        let factor: CGFloat = event.hasPreciseScrollingDeltas ? 1.0 : 18.0
        let dx = event.scrollingDeltaX * factor
        let dy = event.scrollingDeltaY * factor

        handleThreeFingerSwipeJump(dx: dx, dy: dy)
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
        // Top edge (avoiding center notch area and custom menu bar / mini dock)
        else if mouseLoc.y >= f.maxY - edgeThreshold && !CustomMenuBarManager.shared.isEnabled && abs(mouseLoc.x - f.midX) > 120 {
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
                MainActor.assumeIsolated {
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

        // Warp mouse cursor position so it flows seamlessly into the destination screen
        let targetPoint = CGPoint(x: newX, y: primaryHeight - newY)
        CGWarpMouseCursorPosition(targetPoint)

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
        
        // 1. ⌘⌥Space / ⌃⌥Space (keyCode 49): Toggle Spatial Canvas
        if (flags == [.command, .option] || flags == [.control, .option]) && event.keyCode == 49 {
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

    public func handleVectorZoom(deltaScale: CGFloat) {
        if !isZoomedOut && deltaScale < -0.05 {
            zoomOutToPlane()
            return
        }
        guard isZoomedOut else { return }
        let newScale = max(0.15, min(1.0, vectorZoomScale + deltaScale))
        withAnimation(.interactiveSpring(response: 0.18, dampingFraction: 0.85)) {
            vectorZoomScale = newScale
        }
    }

    public func handleMagnification(delta: CGFloat) {
        handleVectorZoom(deltaScale: delta)
    }

    // MARK: - Zoom In / Zoom Out Plane Controller

    public func toggleZoomOutPlane() {
        NotificationCenter.default.post(name: NSNotification.Name("NexusToggleSpatialOrbitMode"), object: nil)
        if isZoomedOut {
            zoomInToSelectedDesktop()
        } else {
            zoomOutToPlane()
        }
    }

    public func zoomOutToPlane() {
        // Spatial zoomed-out overview archived 2026-09-08 (~/Desktop/Genie/.backups/spatial-canvas-2026-09-08/).
        // Pinch-to-zoom-out is a no-op until/unless this feature returns.
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
            win.sharingType = .readOnly
            win.hidesOnDeactivate = false
            win.acceptsMouseMovedEvents = true
            win.contentView = NSView()
            self.overlayWindow = win
        }
        overlayWindow?.setFrame(screen.frame, display: true)
        overlayWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate()

        // ── Unencumbered 3x3 Extended Canvas: Auto-hide native dock, keep Mini Dock superseding canvas ──
        NSApp.presentationOptions = [.autoHideDock]
        if CustomMenuBarManager.shared.isEnabled {
            CustomMenuBarManager.shared.updateVisibility()
        } else {
            AppDelegate.shared?.statusItem?.isVisible = false
        }
    }

    private func hideOverlayWindow() {
        overlayWindow?.orderOut(nil)

        // ── Restore macOS Dock & Menu Bar on return to 1:1 Desktop Mode ──
        NSApp.presentationOptions = []
        CustomMenuBarManager.shared.updateVisibility()
        AppDelegate.shared?.statusItem?.isVisible = !CustomMenuBarManager.shared.isEnabled
    }

    // MARK: - Continuous Webpage Canvas Pan & Momentum Physics
    public func handleContinuousCanvasPanDelta(deltaX: CGFloat, deltaY: CGFloat, allowsRubberBanding: Bool = true) {
        guard isZoomedOut else { return }
        let screen = NSScreen.main ?? NSScreen.screens.first
        let screenWidth = screen?.frame.width ?? 1440.0
        let screenHeight = screen?.frame.height ?? 900.0

        if continuousCanvasFormation == "1:1 Continuous Mega-Canvas" {
            let maxColumns = isUniverse81Active ? 9 : 3
            let maxRows = isUniverse81Active ? 9 : 3
            let minCameraX = -screenWidth * CGFloat(maxColumns - 1)
            let maxCameraX: CGFloat = 0.0
            let minCameraY = -screenHeight * CGFloat(maxRows - 1)
            let maxCameraY: CGFloat = 0.0

            var newCameraX = macroCameraOffset.width + deltaX
            var newCameraY = macroCameraOffset.height + deltaY

            if allowsRubberBanding {
                // Apply elastic rubber-band resistance when pulled beyond bounds (0.30x factor)
                if newCameraX > maxCameraX {
                    let over = newCameraX - maxCameraX
                    newCameraX = maxCameraX + over * 0.30
                } else if newCameraX < minCameraX {
                    let over = minCameraX - newCameraX
                    newCameraX = minCameraX - over * 0.30
                }

                if newCameraY > maxCameraY {
                    let over = newCameraY - maxCameraY
                    newCameraY = maxCameraY + over * 0.30
                } else if newCameraY < minCameraY {
                    let over = minCameraY - newCameraY
                    newCameraY = minCameraY - over * 0.30
                }
            } else {
                newCameraX = max(minCameraX, min(maxCameraX, newCameraX))
                newCameraY = max(minCameraY, min(maxCameraY, newCameraY))
            }

            macroCameraOffset = CGSize(width: newCameraX, height: newCameraY)

            let targetColumn = min(maxColumns - 1, max(0, Int(round(-macroCameraOffset.width / screenWidth))))
            let targetRow = min(maxRows - 1, max(0, Int(round(-macroCameraOffset.height / screenHeight))))
            let newSlotIndex = isUniverse81Active ? Self.indexForUniverse(columnCoordinate: targetColumn, rowCoordinate: targetRow) : Self.indexForGrid(columnCoordinate: targetColumn, rowCoordinate: targetRow)
            if newSlotIndex != focusedPlaneIndex {
                focusedPlaneIndex = newSlotIndex
                macroTargetSpaceIndex = newSlotIndex
                activeMacroPixelSector = Self.macroPixelSector(for: newSlotIndex).sector
                HapticFeedback.selection()
            }
        } else {
            macroCameraOffset.width += deltaX * 0.35
            macroCameraOffset.height += deltaY * 0.35
            let maxPan: CGFloat = 360.0
            macroCameraOffset.width = max(-maxPan, min(maxPan, macroCameraOffset.width))
            macroCameraOffset.height = max(-maxPan, min(maxPan, macroCameraOffset.height))
            updateFocusedSectorFromCamera()
        }
    }

    @inlinable
    public func handleContinuousCanvasPanDelta(dx: CGFloat, dy: CGFloat, allowsRubberBanding: Bool = true) {
        handleContinuousCanvasPanDelta(deltaX: dx, deltaY: dy, allowsRubberBanding: allowsRubberBanding)
    }

    public func handleThreeFingerScrollDelta(deltaX: CGFloat, deltaY: CGFloat) {
        handleThreeFingerSwipeJump(deltaX: deltaX, deltaY: deltaY)
    }

    @inlinable
    public func handleThreeFingerScrollDelta(dx: CGFloat, dy: CGFloat) {
        handleThreeFingerScrollDelta(deltaX: dx, deltaY: dy)
    }

    public func handleThreeFingerSwipeJump(deltaX: CGFloat, deltaY: CGFloat) {
        let now = ProcessInfo.processInfo.systemUptime
        guard now - lastThreeFingerJumpTimestamp > 0.35 else { return }

        let swipeThreshold: CGFloat = 18.0
        guard abs(deltaX) >= swipeThreshold || abs(deltaY) >= swipeThreshold else { return }
        lastThreeFingerJumpTimestamp = now

        if abs(deltaX) > abs(deltaY) {
            if deltaX < -swipeThreshold {
                // 3-Finger Swipe Left -> Jump East (Right Desktop)
                navigateGridDirection(.east)
            } else if deltaX > swipeThreshold {
                // 3-Finger Swipe Right -> Jump West (Left Desktop)
                navigateGridDirection(.west)
            }
        } else {
            if deltaY > swipeThreshold {
                // 3-Finger Swipe Up -> Jump South (Bottom Desktop)
                navigateGridDirection(.south)
            } else if deltaY < -swipeThreshold {
                // 3-Finger Swipe Down -> Jump North (Top Desktop)
                navigateGridDirection(.north)
            }
        }
    }

    @inlinable
    public func handleThreeFingerSwipeJump(dx: CGFloat, dy: CGFloat) {
        handleThreeFingerSwipeJump(deltaX: dx, deltaY: dy)
    }

    public func handleCursorFollowPan(cursorLocationInScreen: CGPoint, screenSize: CGSize) {
        guard isZoomedOut else { return }
        let screenW = screenSize.width > 0 ? screenSize.width : 1440.0
        let screenH = screenSize.height > 0 ? screenSize.height : 900.0

        let maxCols = isUniverse81Active ? 9 : 3
        let maxRows = isUniverse81Active ? 9 : 3

        // AppKit origin is bottom-left. Invert Y so 0 is top, 1 is bottom.
        let normX = max(0.0, min(1.0, cursorLocationInScreen.x / screenW))
        let normY = max(0.0, min(1.0, 1.0 - (cursorLocationInScreen.y / screenH)))

        // Total scrollable range across mega-canvas
        let targetX = -normX * CGFloat(maxCols - 1) * screenW
        let targetY = -normY * CGFloat(maxRows - 1) * screenH

        withAnimation(.interactiveSpring(response: 0.18, dampingFraction: 0.85)) {
            macroCameraOffset = CGSize(width: targetX, height: targetY)
        }

        let targetCol = min(maxCols - 1, max(0, Int(round(normX * CGFloat(maxCols - 1)))))
        let targetRow = min(maxRows - 1, max(0, Int(round(normY * CGFloat(maxRows - 1)))))
        let newSlot = isUniverse81Active ? Self.indexForUniverse(col: targetCol, row: targetRow) : Self.indexForGrid(col: targetCol, row: targetRow)
        if newSlot != focusedPlaneIndex {
            focusedPlaneIndex = newSlot
            macroTargetSpaceIndex = newSlot
            activeMacroPixelSector = Self.macroPixelSector(for: newSlot).sector
            HapticFeedback.selection()
        }
    }

    public func teleportToSector(_ sector: Int, screenSize: CGSize? = nil) {
        let clamped = max(1, min(9, sector))
        activeMacroPixelSector = clamped
        let targetSlot = isUniverse81Active ? Self.centerSlotForSector(clamped) : clamped
        focusedPlaneIndex = targetSlot
        macroTargetSpaceIndex = targetSlot

        MacDesktopsManager.shared.switchToDesktop(index: targetSlot)

        let screen = NSScreen.main ?? NSScreen.screens.first
        let screenW = screenSize?.width ?? screen?.frame.width ?? 1440.0
        let screenH = screenSize?.height ?? screen?.frame.height ?? 900.0

        let (col, row) = isUniverse81Active ? Self.universeCoordinate(for: targetSlot) : Self.gridCoordinate(for: targetSlot)
        let targetOffset = CGSize(width: -CGFloat(col) * screenW, height: -CGFloat(row) * screenH)

        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            macroCameraOffset = targetOffset
        }
        HapticFeedback.heavy()
    }

    public func updateTrackpadDirectSector(slotIndex: Int, normalized: CGPoint) {
        guard isZoomedOut else { return }
        let clamped = max(1, min(9, slotIndex))
        teleportToSector(clamped)
    }

    // MARK: - 3-Finger Grid Navigation (Left, Right, Up, Down)
    public func navigateGridDirection(_ dir: SpatialPlaneDirection) {
        let (col, row) = isUniverse81Active ? Self.universeCoordinate(for: focusedPlaneIndex) : Self.gridCoordinate(for: focusedPlaneIndex)
        let maxLimit = isUniverse81Active ? 8 : 2
        var newCol = col
        var newRow = row

        switch dir {
        case .east: newCol = min(maxLimit, col + 1)
        case .west: newCol = max(0, col - 1)
        case .south: newRow = min(maxLimit, row + 1)
        case .north: newRow = max(0, row - 1)
        }

        let newSlot = isUniverse81Active ? Self.indexForUniverse(col: newCol, row: newRow) : Self.indexForGrid(col: newCol, row: newRow)
        if newSlot != focusedPlaneIndex {
            focusedPlaneIndex = newSlot
            macroTargetSpaceIndex = newSlot
            activeMacroPixelSector = Self.macroPixelSector(for: newSlot).sector

            MacDesktopsManager.shared.switchToDesktop(index: newSlot)

            let screen = NSScreen.main ?? NSScreen.screens.first
            let screenW = screen?.frame.width ?? 1440.0
            let screenH = screen?.frame.height ?? 900.0

            let targetOffset = CGSize(
                width: -CGFloat(newCol) * screenW,
                height: -CGFloat(newRow) * screenH
            )
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                macroCameraOffset = targetOffset
            }
            HapticFeedback.heavy()
        } else {
            // Edge of grid reached! Boundary collision feedback
            HapticFeedback.tick()
            NSSound(named: "Tink")?.play()
        }
    }

    public func settleToNearestSlot(withSpring: Bool = true) {
        guard isZoomedOut, continuousCanvasFormation == "1:1 Continuous Mega-Canvas" else { return }
        let screen = NSScreen.main ?? NSScreen.screens.first
        let screenW = screen?.frame.width ?? 1440.0
        let screenH = screen?.frame.height ?? 900.0

        let maxCols = isUniverse81Active ? 9 : 3
        let maxRows = isUniverse81Active ? 9 : 3
        let minX = -screenW * CGFloat(maxCols - 1)
        let maxX: CGFloat = 0.0
        let minY = -screenH * CGFloat(maxRows - 1)
        let maxY: CGFloat = 0.0

        // If pulled out of bounds, spring back to bound edges
        let clampedX = max(minX, min(maxX, macroCameraOffset.width))
        let clampedY = max(minY, min(maxY, macroCameraOffset.height))

        let targetCol = min(maxCols - 1, max(0, Int(round(-clampedX / screenW))))
        let targetRow = min(maxRows - 1, max(0, Int(round(-clampedY / screenH))))
        let targetSlot = isUniverse81Active ? Self.indexForUniverse(col: targetCol, row: targetRow) : Self.indexForGrid(col: targetCol, row: targetRow)
        focusedPlaneIndex = targetSlot
        macroTargetSpaceIndex = targetSlot
        activeMacroPixelSector = Self.macroPixelSector(for: targetSlot).sector

        MacDesktopsManager.shared.switchToDesktop(index: targetSlot)

        let slotCenterOffset = CGSize(
            width: -CGFloat(targetCol) * screenW,
            height: -CGFloat(targetRow) * screenH
        )

        let distToSlot = hypot(clampedX - slotCenterOffset.width, clampedY - slotCenterOffset.height)
        let finalOffset = vectorSnappingEnabled ? (distToSlot < 180.0 ? slotCenterOffset : CGSize(width: clampedX, height: clampedY)) : CGSize(width: clampedX, height: clampedY)

        if withSpring {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                macroCameraOffset = finalOffset
            }
        } else {
            macroCameraOffset = finalOffset
        }
    }
}

// MARK: - Spatial Touch Hosting View
// Direct AppKit event handling delivering 120Hz ProMotion webpage-like canvas manipulation:
// 1. Hand Grab & Drag: Click and drag anywhere to pan screen 1:1 with cursor (openHand -> closedHand).
// 2. Kinetic Momentum: Releasing a drag glides with natural friction and spring bounds.
// 3. Click-to-Land: A stationary click (<6pt) on any desktop space lands directly into it.
// 4. 2-Finger Trackpad & Wheel Scroll: Natural scrolling effortlessly navigates the 3x3 plane.
// 5. Screen Follows Cursor: Real-time mouse movement pans the screen camera viewport.
// 6. HUD Exclusion: Top 85pt of the screen remains fully click-through to buttons and controls.
@MainActor
public final class SpatialTouchHostingView<Content: View>: NSHostingView<Content> {
    private var isDragging: Bool = false
    private var dragStartLocation: CGPoint = .zero
    private var lastDragLocation: CGPoint = .zero
    private var totalDragDistance: CGFloat = 0.0
    private var dragVelocity: CGSize = .zero
    private var lastDragTimestamp: TimeInterval = 0.0
    private var momentumTimer: Timer? = nil
    private var settleTimer: Timer? = nil
    private var trackingArea: NSTrackingArea? = nil
    private var lastThreeFingerPosition: CGPoint? = nil
    private var lastThreeFingerDragTimestamp: TimeInterval = 0.0

    public required dynamic init(rootView: Content) {
        super.init(rootView: rootView)
        self.allowedTouchTypes = [.indirect, .direct]
        self.wantsLayer = true
    }

    public required dynamic init?(coder: NSCoder) {
        super.init(coder: coder)
        self.allowedTouchTypes = [.indirect, .direct]
        self.wantsLayer = true
    }

    public override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }
        let area = NSTrackingArea(
            rect: bounds,
            options: [.mouseMoved, .cursorUpdate, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(area)
        trackingArea = area
    }

    public override func cursorUpdate(with event: NSEvent) {
        if isDragging {
            NSCursor.closedHand.set()
        } else if event.locationInWindow.y > bounds.height - 85 {
            NSCursor.arrow.set()
        } else {
            NSCursor.openHand.set()
        }
    }

    public override func resetCursorRects() {
        super.resetCursorRects()
        if bounds.height > 85 {
            let canvasRect = NSRect(x: 0, y: 0, width: bounds.width, height: bounds.height - 85)
            addCursorRect(canvasRect, cursor: .openHand)
        }
    }

    public override func mouseDown(with event: NSEvent) {
        momentumTimer?.invalidate()
        momentumTimer = nil
        settleTimer?.invalidate()
        settleTimer = nil

        // Top 85pt belongs to the floating HUD controls (buttons, mode switchers, etc.)
        if event.locationInWindow.y > bounds.height - 85 {
            super.mouseDown(with: event)
            return
        }

        isDragging = true
        dragStartLocation = event.locationInWindow
        lastDragLocation = event.locationInWindow
        totalDragDistance = 0.0
        dragVelocity = .zero
        lastDragTimestamp = event.timestamp

        NSCursor.closedHand.set()
    }

    public override func mouseDragged(with event: NSEvent) {
        guard isDragging else {
            super.mouseDragged(with: event)
            return
        }

        let loc = event.locationInWindow
        let deltaX = loc.x - lastDragLocation.x
        // AppKit coordinates: y is 0 at bottom, but dragging mouse downward (negative deltaY in AppKit)
        // corresponds to moving the canvas down (+height in SwiftUI offset).
        let deltaY = -(loc.y - lastDragLocation.y)

        totalDragDistance += hypot(deltaX, deltaY)

        let dt = max(0.008, event.timestamp - lastDragTimestamp)
        let instantVx = deltaX / CGFloat(dt)
        let instantVy = deltaY / CGFloat(dt)
        dragVelocity = CGSize(
            width: dragVelocity.width * 0.4 + instantVx * 0.6,
            height: dragVelocity.height * 0.4 + instantVy * 0.6
        )

        lastDragLocation = loc
        lastDragTimestamp = event.timestamp

        SpatialPlaneManager.shared.handleContinuousCanvasPanDelta(dx: deltaX, dy: deltaY, allowsRubberBanding: true)
    }

    public override func mouseUp(with event: NSEvent) {
        guard isDragging else {
            super.mouseUp(with: event)
            return
        }
        isDragging = false
        NSCursor.openHand.set()

        // 1. Stationary Click-to-Land (Total drag < 6 points)
        if totalDragDistance < 6.0 {
            let screenW = bounds.width > 0 ? bounds.width : 1440.0
            let screenH = bounds.height > 0 ? bounds.height : 900.0

            let scale = SpatialPlaneManager.shared.vectorZoomScale > 0 ? SpatialPlaneManager.shared.vectorZoomScale : 1.0
            let clickX = (event.locationInWindow.x - SpatialPlaneManager.shared.macroCameraOffset.width) / scale
            let clickY = ((bounds.height - event.locationInWindow.y) - SpatialPlaneManager.shared.macroCameraOffset.height) / scale

            let maxCols = SpatialPlaneManager.shared.isUniverse81Active ? 9 : 3
            let maxRows = SpatialPlaneManager.shared.isUniverse81Active ? 9 : 3

            let col = min(maxCols - 1, max(0, Int(clickX / screenW)))
            let row = min(maxRows - 1, max(0, Int(clickY / screenH)))
            let slot = SpatialPlaneManager.shared.isUniverse81Active
                ? SpatialPlaneManager.indexForUniverse(col: col, row: row)
                : SpatialPlaneManager.indexForGrid(col: col, row: row)
            SpatialPlaneManager.shared.zoomInToSelectedDesktop(index: slot)
            return
        }

        // 2. Kinetic Glide Momentum Physics
        let speed = hypot(dragVelocity.width, dragVelocity.height)
        if speed > 100.0 {
            startMomentumGlide()
        } else {
            SpatialPlaneManager.shared.settleToNearestSlot(withSpring: true)
        }
    }

    private func startMomentumGlide() {
        momentumTimer?.invalidate()
        var currentVel = dragVelocity

        // Cap initial fling speed for comfort
        let maxSpeed: CGFloat = 3500.0
        let speed = hypot(currentVel.width, currentVel.height)
        if speed > maxSpeed {
            let factor = maxSpeed / speed
            currentVel.width *= factor
            currentVel.height *= factor
        }

        momentumTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] timer in
            MainActor.assumeIsolated {
                guard let self = self, self.momentumTimer != nil else {
                    timer.invalidate()
                    return
                }

                let dt: CGFloat = 1.0 / 60.0
                let dx = currentVel.width * dt
                let dy = currentVel.height * dt

                SpatialPlaneManager.shared.handleContinuousCanvasPanDelta(dx: dx, dy: dy, allowsRubberBanding: true)

                // Friction decay
                currentVel.width *= 0.92
                currentVel.height *= 0.92

                if hypot(currentVel.width, currentVel.height) < 15.0 {
                    timer.invalidate()
                    self.momentumTimer = nil
                    SpatialPlaneManager.shared.settleToNearestSlot(withSpring: true)
                }
            }
        }
    }

    public override func mouseMoved(with event: NSEvent) {
        if SpatialPlaneManager.shared.isZoomedOut {
            self.handleCornerToCornerCursorGlide(event)
            if SpatialPlaneManager.shared.screenWebpagePanMode == "Screen Follows Cursor" ||
               SpatialPlaneManager.shared.cursorFollowPanningEnabled {
                SpatialPlaneManager.shared.handleCursorFollowPan(cursorLocationInScreen: event.locationInWindow, screenSize: self.bounds.size)
            }
            if event.locationInWindow.y > self.bounds.height - 85 {
                NSCursor.arrow.set()
            } else {
                NSCursor.openHand.set()
            }
        }
        super.mouseMoved(with: event)
    }

    private func handleCornerToCornerCursorGlide(_ event: NSEvent) {
        let mouseLoc = NSEvent.mouseLocation
        guard let screen = NSScreen.screens.first(where: { $0.frame.contains(mouseLoc) }) ?? NSScreen.main else { return }
        let f = screen.frame
        
        let relX = (mouseLoc.x - f.minX) / max(1.0, f.width)
        let relY = (mouseLoc.y - f.minY) / max(1.0, f.height)
        
        var dx: CGFloat = 0
        var dy: CGFloat = 0
        
        if relX < 0.08 {
            dx = (0.08 - relX) * 40.0
        } else if relX > 0.92 {
            dx = -(relX - 0.92) * 40.0
        }
        
        if relY < 0.08 {
            dy = (0.08 - relY) * 40.0
        } else if relY > 0.92 {
            dy = -(relY - 0.92) * 40.0
        }
        
        if abs(dx) > 0.1 || abs(dy) > 0.1 {
            SpatialPlaneManager.shared.handleContinuousCanvasPanDelta(dx: dx, dy: dy, allowsRubberBanding: true)
        }
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
            lastThreeFingerDragTimestamp = ProcessInfo.processInfo.systemUptime
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
                let dy = -(currentPos.y - last.y) * screenH * 2.5
                SpatialPlaneManager.shared.handleContinuousCanvasPanDelta(dx: dx, dy: dy, allowsRubberBanding: true)
            }
            lastThreeFingerPosition = currentPos
            return
        } else {
            lastThreeFingerPosition = nil
        }

        // ── 1-Finger Direct Spot Snapping: Trackpad 3x3 sectors map to the 9 Macro-Pixels (3x3 Pixel Size) ──
        let timeSince3Finger = ProcessInfo.processInfo.systemUptime - lastThreeFingerDragTimestamp
        guard timeSince3Finger > 0.45 else { return }

        guard touches.count == 1, let primary = touches.first, primary.phase == .began else { return }
        let norm = primary.normalizedPosition
        let col = min(2, max(0, Int(norm.x * 3.0)))
        let row = min(2, max(0, 2 - Int(norm.y * 3.0))) // Inverted Y: row 0 is top
        let sector = row * 3 + col + 1
        SpatialPlaneManager.shared.teleportToSector(sector)
    }

    public override func swipe(with event: NSEvent) {
        let dx = CGFloat(event.deltaX * 100.0)
        let dy = CGFloat(event.deltaY * 100.0)
        SpatialPlaneManager.shared.handleThreeFingerSwipeJump(dx: dx, dy: dy)
    }

    public override func magnify(with event: NSEvent) {
        if event.magnification > 0.08 {
            SpatialPlaneManager.shared.zoomInToSelectedDesktop()
        } else if event.magnification < -0.08 {
            SpatialPlaneManager.shared.zoomOutToPlane()
        }
        super.magnify(with: event)
    }

    public override func touchesEnded(with event: NSEvent) {
        lastThreeFingerPosition = nil
        SpatialPlaneManager.shared.settleToNearestSlot(withSpring: true)
        super.touchesEnded(with: event)
    }

    public override func touchesCancelled(with event: NSEvent) {
        lastThreeFingerPosition = nil
        super.touchesCancelled(with: event)
    }

    public override func keyDown(with event: NSEvent) {
        if SpatialPlaneManager.shared.isZoomedOut {
            if event.keyCode == 53 /* Esc */ || event.keyCode == 36 /* Return */ || event.keyCode == 49 /* Space */ {
                SpatialPlaneManager.shared.zoomInToSelectedDesktop()
                return
            }
            switch event.keyCode {
            case 123: // Left Arrow
                SpatialPlaneManager.shared.navigateGridDirection(.west)
                return
            case 124: // Right Arrow
                SpatialPlaneManager.shared.navigateGridDirection(.east)
                return
            case 125: // Down Arrow
                SpatialPlaneManager.shared.navigateGridDirection(.south)
                return
            case 126: // Up Arrow
                SpatialPlaneManager.shared.navigateGridDirection(.north)
                return
            default:
                break
            }
        }
        super.keyDown(with: event)
    }
}

extension SpatialTouchHostingView: @unchecked Sendable {}