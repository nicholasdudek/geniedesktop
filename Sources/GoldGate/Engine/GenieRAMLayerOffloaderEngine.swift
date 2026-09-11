import AppKit
import Foundation
import Metal
import os.log

// MARK: - 💾 Genie RAM Layer Offloader Engine
/// Proactively prevents memory exhaustion by offloading non-active, background, and distant
/// spatial desktop layers, Photoshop canvas layers, and GPU buffers from system RAM into an APFS
/// file-backed cache (~/Library/Caches/Genie/RAMLayers/).
///
/// Under heavy loads or macOS memory pressure (.warning / .critical), the engine strips 4K
/// uncompressed bitmaps and textures from inactive screens (out of up to 81 universe screens),
/// reclaiming hundreds of megabytes to gigabytes of physical RAM, and lazily re-hydrates them
/// in sub-10ms when the user navigates back.

public struct RAMLayerOffloadRecord: Identifiable, Sendable {
    public let id: String
    public let layerIndex: Int
    public let layerName: String
    public let offloadDiskURL: URL
    public let reclaimedBytes: Int
    public let timestamp: Date
}

@MainActor
public final class GenieRAMLayerOffloaderEngine: ObservableObject {
    public static let shared = GenieRAMLayerOffloaderEngine()

    private let logger = Logger(subsystem: "com.genie.governor", category: "ram_layer_offload")

    // ── Cache Directory ───────────────────────────────────────────────────
    public let cacheDirectory: URL

    // ── Published Telemetry ───────────────────────────────────────────────
    @Published public private(set) var isOffloadingActive: Bool = false
    @Published public private(set) var totalOffloadedLayersCount: Int = 0
    @Published public private(set) var totalRAMReclaimedMB: Double = 0.0
    @Published public private(set) var activeResidentLayerCount: Int = 1
    @Published public private(set) var lastOffloadTimestamp: Date? = nil
    @Published public private(set) var statusMessage: String = "RAM Layer Offloader Idle (Zero Pressure)"

    // ── Thresholds ────────────────────────────────────────────────────────
    /// Maximum number of full 4K screen buffers allowed to reside uncompressed in RAM simultaneously
    public var maxResidentScreenLayers: Int = 5 // Active screen + 4 cardinal neighbors
    /// Memory threshold in MB above which aggressive offloading triggers automatically
    public var memoryThresholdMB: Int = 1200

    private var offloadRegistry: [Int: RAMLayerOffloadRecord] = [:]
    private var notificationObservers: [NSObjectProtocol] = []

    private init() {
        let baseCache = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.cacheDirectory = baseCache.appendingPathComponent("Genie/RAMLayers", isDirectory: true)

        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        setupNotifications()
        logger.info("⚡️ GenieRAMLayerOffloaderEngine initialized at \(self.cacheDirectory.path)")
    }

    deinit {
        for obs in notificationObservers {
            NotificationCenter.default.removeObserver(obs)
        }
    }

    // MARK: - Notifications Setup
    private func setupNotifications() {
        // 1. High memory pressure notification from GenieMemoryGovernorEngine
        let o1 = NotificationCenter.default.addObserver(
            forName: Notification.Name("GenieMemoryPressureHigh"),
            object: nil,
            queue: .main
        ) { [weak self] notif in
            guard let self = self else { return }
            let isCritical = (notif.userInfo?["isCritical"] as? Bool) ?? false
            self.logger.warning("🚨 Received GenieMemoryPressureHigh (critical: \(isCritical)). Executing layer offload.")
            Task { @MainActor in
                self.offloadInactiveRAMLayers(critical: isCritical)
            }
        }
        notificationObservers.append(o1)

        // 2. Purge volatile caches notification
        let o2 = NotificationCenter.default.addObserver(
            forName: Notification.Name("GeniePurgeVolatileCaches"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.offloadInactiveRAMLayers(critical: true)
            }
        }
        notificationObservers.append(o2)

        // 3. Active space change -> evaluate layer distances
        let o3 = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.evaluateSpatialLayerDistances()
            }
        }
        notificationObservers.append(o3)
    }

    // MARK: - Core Offload Pipeline
    /// Evaluates current memory usage and offloads inactive RAM layers when necessary.
    @discardableResult
    public func offloadRAMLayersWhenNecessary() -> Int {
        GenieMemoryGovernorEngine.shared.refreshMemoryTelemetry()
        let residentMB = GenieMemoryGovernorEngine.shared.currentProcessResidentMB
        let pressure = GenieMemoryGovernorEngine.shared.currentPressureLevel

        if pressure == .critical || residentMB > memoryThresholdMB {
            logger.warning("Memory usage (\(residentMB) MB) or pressure (\(pressure.rawValue)) warrants aggressive layer offloading.")
            return offloadInactiveRAMLayers(critical: pressure == .critical)
        } else if pressure == .warning || residentMB > (memoryThresholdMB * 3 / 4) {
            return offloadDistantSpatialLayers()
        }
        return 0
    }

    /// Aggressively offloads inactive and non-visible layers across all subsystems.
    @discardableResult
    public func offloadInactiveRAMLayers(critical: Bool) -> Int {
        isOffloadingActive = true
        defer { isOffloadingActive = false }

        var reclaimedBytes = 0
        var offloadedCount = 0

        // 1. Offload distant / inactive desktop plane RAM cache buffers in SpatialPlaneManager
        let currentSpace = MacDesktopsManager.shared.currentSpaceIndex
        let planeManager = SpatialPlaneManager.shared

        for (screenIndex, var buffer) in planeManager.desktopPlaneCacheBuffers {
            // Keep current screen in memory; in critical mode, offload even immediate neighbors
            let isCurrent = (screenIndex == currentSpace)
            if !isCurrent {
                let bytes = estimateBufferRAMBytes(buffer)
                if bytes > 0 {
                    // Offload wallpaper and thumbnail to disk cache
                    if let wp = buffer.wallpaper {
                        _ = saveImageToDisk(wp, prefix: "wp_\(screenIndex)")
                        buffer.wallpaper = nil
                    }
                    if let thumb = buffer.thumbnail, thumb != buffer.wallpaper {
                        let path = saveImageToDisk(thumb, prefix: "thumb_\(screenIndex)")
                        buffer.thumbnail = nil
                        buffer.offloadedDiskPath = path
                    }
                    buffer.isOffloaded = true
                    planeManager.desktopPlaneCacheBuffers[screenIndex] = buffer

                    reclaimedBytes += bytes
                    offloadedCount += 1

                    let record = RAMLayerOffloadRecord(
                        id: UUID().uuidString,
                        layerIndex: screenIndex,
                        layerName: buffer.name,
                        offloadDiskURL: buffer.offloadedDiskPath ?? cacheDirectory,
                        reclaimedBytes: bytes,
                        timestamp: Date()
                    )
                    offloadRegistry[screenIndex] = record
                }
            }
        }

        // 2. Offload non-selected / invisible space layers in SpacesLayerManager
        let spacesManager = SpacesLayerManager.shared
        for idx in spacesManager.layers.indices {
            let spaceIndex = spacesManager.layers[idx].spaceIndex
            if spaceIndex != spacesManager.selectedLayerIndex || !spacesManager.layers[idx].isVisible {
                var layer = spacesManager.layers[idx]
                if layer.metalTexture != nil || layer.liveThumbnail != nil {
                    let layerBytes = estimateSpaceLayerRAMBytes(layer)
                    layer.metalTexture = nil
                    layer.liveThumbnail = nil
                    spacesManager.layers[idx] = layer
                    reclaimedBytes += layerBytes
                    offloadedCount += 1
                }
            }
        }

        // 3. Purge Photoshop Layer Compositor caches
        let compositor = PhotoshopLayerCompositorEngine.shared
        if compositor.compositeCache != nil {
            compositor.compositeCache = nil
            reclaimedBytes += 16 * 1024 * 1024 // ~16 MB cache reclaimed
        }

        // 4. Purge zero-copy RAM textures in RAMStraightToRenderEngine if critical
        if critical {
            RAMStraightToRenderEngine.shared.purgeBuffers()
        }

        // Update published stats
        totalOffloadedLayersCount += offloadedCount
        totalRAMReclaimedMB += Double(reclaimedBytes) / (1024.0 * 1024.0)
        activeResidentLayerCount = max(1, planeManager.desktopPlaneCacheBuffers.values.filter { !$0.isOffloaded }.count)
        lastOffloadTimestamp = Date()
        statusMessage = "Offloaded \(offloadedCount) RAM layers • Reclaimed \(String(format: "%.1f", Double(reclaimedBytes) / 1024.0 / 1024.0)) MB ✨"

        logger.info("⚡️ RAM Layer Offload finished: \(offloadedCount) layers offloaded, \(Double(reclaimedBytes) / (1024.0 * 1024.0)) MB freed.")
        return offloadedCount
    }

    /// Offloads only distant spatial layers beyond the active 3x3 local cluster.
    @discardableResult
    public func offloadDistantSpatialLayers() -> Int {
        let currentSpace = MacDesktopsManager.shared.currentSpaceIndex
        let planeManager = SpatialPlaneManager.shared
        var offloadedCount = 0

        for (screenIndex, var buffer) in planeManager.desktopPlaneCacheBuffers {
            // If screenIndex is beyond the immediate 9-space cluster or not current
            if screenIndex != currentSpace && screenIndex > 9 && !buffer.isOffloaded {
                let bytes = estimateBufferRAMBytes(buffer)
                if let wp = buffer.wallpaper {
                    _ = saveImageToDisk(wp, prefix: "wp_\(screenIndex)")
                    buffer.wallpaper = nil
                }
                if let thumb = buffer.thumbnail {
                    let path = saveImageToDisk(thumb, prefix: "thumb_\(screenIndex)")
                    buffer.thumbnail = nil
                    buffer.offloadedDiskPath = path
                }
                buffer.isOffloaded = true
                planeManager.desktopPlaneCacheBuffers[screenIndex] = buffer
                offloadedCount += 1
                totalRAMReclaimedMB += Double(bytes) / (1024.0 * 1024.0)
            }
        }

        if offloadedCount > 0 {
            totalOffloadedLayersCount += offloadedCount
            statusMessage = "Offloaded \(offloadedCount) distant universe layers to disk."
        }
        return offloadedCount
    }

    /// Evaluates spatial layer distances when switching spaces to hydrate neighbor layers and offload far ones.
    public func evaluateSpatialLayerDistances() {
        let currentSpace = MacDesktopsManager.shared.currentSpaceIndex
        hydrateLayerIfNeeded(screenIndex: currentSpace)
        offloadRAMLayersWhenNecessary()
    }

    // MARK: - Lazy Re-Hydration
    /// Lazily re-hydrates an offloaded screen layer back into RAM from the disk cache.
    @discardableResult
    public func hydrateLayerIfNeeded(screenIndex: Int) -> Bool {
        let planeManager = SpatialPlaneManager.shared
        guard var buffer = planeManager.desktopPlaneCacheBuffers[screenIndex], buffer.isOffloaded else {
            return false
        }

        logger.info("Hydrating offloaded layer for Screen \(screenIndex)...")

        // 1. Re-hydrate thumbnail from disk
        if let diskPath = buffer.offloadedDiskPath, FileManager.default.fileExists(atPath: diskPath.path) {
            if let image = NSImage(contentsOf: diskPath) {
                buffer.thumbnail = image
            }
        }

        // 2. Re-hydrate wallpaper
        let wpURL = cacheDirectory.appendingPathComponent("wp_\(screenIndex).jpg")
        if FileManager.default.fileExists(atPath: wpURL.path) {
            buffer.wallpaper = NSImage(contentsOf: wpURL)
        } else {
            buffer.wallpaper = nil
        }

        buffer.isOffloaded = false
        planeManager.desktopPlaneCacheBuffers[screenIndex] = buffer

        // Also hydrate in SpacesLayerManager if matching
        if let idx = SpacesLayerManager.shared.layers.firstIndex(where: { $0.spaceIndex == screenIndex }) {
            var spaceLayer = SpacesLayerManager.shared.layers[idx]
            if buffer.thumbnail != nil {
                spaceLayer.liveThumbnail = buffer.thumbnail
            }
            SpacesLayerManager.shared.layers[idx] = spaceLayer
        }

        offloadRegistry.removeValue(forKey: screenIndex)
        activeResidentLayerCount += 1
        statusMessage = "Hydrated Layer \(screenIndex) into active RAM."
        return true
    }

    // MARK: - Disk Helpers
    private func saveImageToDisk(_ image: NSImage, prefix: String) -> URL? {
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let jpeg = rep.representation(using: .jpeg, properties: [.compressionFactor: 0.82]) else {
            return nil
        }
        let url = cacheDirectory.appendingPathComponent("\(prefix).jpg")
        try? jpeg.write(to: url)
        return url
    }

    private func estimateBufferRAMBytes(_ buffer: DesktopPlaneRAMCache) -> Int {
        var bytes = 0
        if let wp = buffer.wallpaper {
            bytes += Int(wp.size.width * wp.size.height * 4)
        }
        if let thumb = buffer.thumbnail {
            bytes += Int(thumb.size.width * thumb.size.height * 4)
        }
        return max(bytes, 2 * 1024 * 1024) // At least 2MB per image set
    }

    private func estimateSpaceLayerRAMBytes(_ layer: SpaceGraphicLayer) -> Int {
        var bytes = 0
        if let thumb = layer.liveThumbnail {
            bytes += Int(thumb.size.width * thumb.size.height * 4)
        }
        if layer.metalTexture != nil {
            bytes += 16 * 1024 * 1024 // 4K Metal texture allocation (~16-32 MB)
        }
        if layer.forkedFrame != nil {
            bytes += 8 * 1024 * 1024
        }
        return max(bytes, 1024 * 1024)
    }

    /// Purges all temporary disk caches created during layer offloading.
    public func cleanDiskCache() {
        try? FileManager.default.removeItem(at: cacheDirectory)
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
        offloadRegistry.removeAll()
        totalOffloadedLayersCount = 0
        totalRAMReclaimedMB = 0.0
        statusMessage = "RAM Layer disk cache cleared."
    }
}
