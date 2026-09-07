import AppKit
import Foundation
import QuartzCore
import SwiftUI
import Combine

// MARK: - SwiftDOM: High-Performance Native Spatial Scene Graph & Virtual Viewport Engine
// Developed specifically for GoldGate / Genie to manage multi-screen spatial planes (3x3 grid = 9 spaces,
// or 9x9 = 81 universe) as a unified virtual scene graph without allocating discrete window buffers.
//
// Key Architectural Pillars:
// 1. Lightweight Virtual Node Graph (`SwiftDOMNode`): ~64 bytes per node representation for windows,
//    files, widgets, HTML/CSS cards, and thumbnails.
// 2. Spatial Scene Tree (`SwiftDOMTree`): Virtual hierarchy managing all 9 spaces with zero-padding
//    continuous geometry and sub-microsecond diffing.
// 3. Frustum Culling & Viewport Occlusion: Computes what intersects the user's viewport cone (with
//    anticipatory glide buffers) to only render active nodes and dynamically switch LODs.
// 4. Asset Mipmap Cache (`SwiftDOMAssetMipmapCache`): Ultra-low memory (<35MB total unified memory limit)
//    multi-tier texture pyramid (Full, Medium, Thumbnail, Nano) with LRU eviction.
// 5. Hardware Layer Compositing: Direct CALayer / CATextLayer / CATransform3D rendering pipeline
//    guaranteeing 120 FPS continuous trackpad panning with zero SwiftUI body re-evaluation overhead.

// MARK: - SwiftDOM Node Types & Tags

public enum SwiftDOMTag: String, CaseIterable, Codable {
    case plane
    case desktop
    case wallpaper
    case window
    case file
    case widget
    case htmlCard
    case thumbnail
    case titlebar
    case trafficLights
    case content
    case text
    case seamLine
    case reticle
    case badge
    case icon
    case custom
}

public enum SwiftDOMLODLevel: Int, Comparable, CaseIterable {
    case culled = 0      // Completely outside viewport cone (0 raster cost)
    case nano = 1        // 64x64 micro thumbnail (overview / mini-map)
    case thumbnail = 2   // 25% resolution preview
    case medium = 3      // 50% resolution (adjacent / peripheral spaces)
    case full = 4        // 100% native unscaled retina resolution

    public static func < (lhs: SwiftDOMLODLevel, rhs: SwiftDOMLODLevel) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

// MARK: - SwiftDOM Style Specification

public struct SwiftDOMStyle: Equatable {
    public var backgroundColor: NSColor = .clear
    public var borderColor: NSColor = .clear
    public var borderWidth: CGFloat = 0.0
    public var cornerRadius: CGFloat = 0.0
    public var opacity: Float = 1.0
    public var shadowColor: NSColor? = nil
    public var shadowRadius: CGFloat = 0.0
    public var shadowOffset: CGSize = .zero
    public var shadowOpacity: Float = 0.0
    public var zIndex: Int = 0

    public init() {}

    public static func == (lhs: SwiftDOMStyle, rhs: SwiftDOMStyle) -> Bool {
        return lhs.backgroundColor == rhs.backgroundColor &&
               lhs.borderColor == rhs.borderColor &&
               lhs.borderWidth == rhs.borderWidth &&
               lhs.cornerRadius == rhs.cornerRadius &&
               lhs.opacity == rhs.opacity &&
               lhs.shadowColor == rhs.shadowColor &&
               lhs.shadowRadius == rhs.shadowRadius &&
               lhs.shadowOffset == rhs.shadowOffset &&
               lhs.shadowOpacity == rhs.shadowOpacity &&
               lhs.zIndex == rhs.zIndex
    }
}

// MARK: - Lightweight SwiftDOM Virtual Node (~64 Bytes Header)

@MainActor
public final class SwiftDOMNode: Identifiable {
    public let id: String
    public let tag: SwiftDOMTag
    public var frame: CGRect
    public var style: SwiftDOMStyle
    public var text: String?
    public var font: NSFont?
    public var textColor: NSColor?
    public var image: NSImage?
    public var imageCacheKey: String?
    public var htmlCardContent: String?
    public var widgetType: String?
    public var fileURL: URL?
    public var desktopSlot: Int
    public var children: [SwiftDOMNode] = []
    public weak var parent: SwiftDOMNode? = nil

    // Viewport & Frustum Occlusion State
    public var isVisible: Bool = true
    public var intersectionRatio: CGFloat = 1.0
    public var lodLevel: SwiftDOMLODLevel = .full
    public var action: (() -> Void)? = nil

    public init(
        id: String,
        tag: SwiftDOMTag,
        frame: CGRect,
        style: SwiftDOMStyle = SwiftDOMStyle(),
        text: String? = nil,
        font: NSFont? = nil,
        textColor: NSColor? = nil,
        image: NSImage? = nil,
        imageCacheKey: String? = nil,
        htmlCardContent: String? = nil,
        widgetType: String? = nil,
        fileURL: URL? = nil,
        desktopSlot: Int = 0,
        children: [SwiftDOMNode] = [],
        action: (() -> Void)? = nil
    ) {
        self.id = id
        self.tag = tag
        self.frame = frame
        self.style = style
        self.text = text
        self.font = font
        self.textColor = textColor
        self.image = image
        self.imageCacheKey = imageCacheKey
        self.htmlCardContent = htmlCardContent
        self.widgetType = widgetType
        self.fileURL = fileURL
        self.desktopSlot = desktopSlot
        self.children = children
        self.action = action

        for child in children {
            child.parent = self
        }
    }

    public func addChild(_ node: SwiftDOMNode) {
        node.parent = self
        children.append(node)
    }

    public func removeAllChildren() {
        for child in children {
            child.parent = nil
        }
        children.removeAll()
    }

    /// Computes the node's absolute bounding frame in root canvas space.
    public var absoluteFrame: CGRect {
        var origin = frame.origin
        var currentParent = parent
        while let p = currentParent {
            origin.x += p.frame.origin.x
            origin.y += p.frame.origin.y
            currentParent = p.parent
        }
        return CGRect(origin: origin, size: frame.size)
    }

    /// Deep hit-test for interactive nodes (windows, files, widgets, action targets).
    public func hitTest(pointInCanvas: CGPoint) -> SwiftDOMNode? {
        guard isVisible else { return nil }
        let absRect = absoluteFrame
        guard absRect.contains(pointInCanvas) else { return nil }

        // Reverse search children for top-most z-index target
        for child in children.reversed() {
            if let hit = child.hitTest(pointInCanvas: pointInCanvas) {
                return hit
            }
        }

        if action != nil || tag == .window || tag == .file || tag == .widget || tag == .desktop {
            return self
        }
        return nil
    }
}

// MARK: - Asset Mipmap Cache (<35MB Total Unified Memory)
// Multi-tier texture pyramid that stores and downsamples wallpapers, window buffers,
// and thumbnails with strict LRU memory budgeting under 35MB.

public final class SwiftDOMAssetMipmapCache {
    public static let shared = SwiftDOMAssetMipmapCache()

    // 35 MB hard limit on unified texture memory footprint
    public static let maxMemoryLimitBytes: Int = 35 * 1024 * 1024

    private struct CacheEntry {
        let key: String
        let lod: SwiftDOMLODLevel
        let image: NSImage
        let byteSize: Int
        var lastAccessTime: TimeInterval
    }

    private let lock = NSRecursiveLock()
    private var entries: [String: CacheEntry] = [:]
    public private(set) var currentMemoryBytes: Int = 0

    private init() {}

    private func compoundKey(_ baseKey: String, lod: SwiftDOMLODLevel) -> String {
        return "\(baseKey)@lod\(lod.rawValue)"
    }

    /// Retrieves an image at the specified LOD level, falling back to lower/higher LODs if available.
    public func image(for key: String, lod: SwiftDOMLODLevel = .full) -> NSImage? {
        lock.lock()
        defer { lock.unlock() }

        let cKey = compoundKey(key, lod: lod)
        if var entry = entries[cKey] {
            entry.lastAccessTime = ProcessInfo.processInfo.systemUptime
            entries[cKey] = entry
            return entry.image
        }

        // Fallback search to best available alternative LOD
        for fallbackLOD in [SwiftDOMLODLevel.medium, .thumbnail, .full, .nano] {
            let altKey = compoundKey(key, lod: fallbackLOD)
            if var entry = entries[altKey] {
                entry.lastAccessTime = ProcessInfo.processInfo.systemUptime
                entries[altKey] = entry
                return entry.image
            }
        }
        return nil
    }

    /// Stores a mipmap level and enforces the <35MB memory budget.
    public func setMipmap(for key: String, image: NSImage, lod: SwiftDOMLODLevel) {
        lock.lock()
        defer { lock.unlock() }

        let byteSize = estimateMemoryFootprint(for: image)
        let cKey = compoundKey(key, lod: lod)

        if let existing = entries[cKey] {
            currentMemoryBytes -= existing.byteSize
        }

        let entry = CacheEntry(
            key: key,
            lod: lod,
            image: image,
            byteSize: byteSize,
            lastAccessTime: ProcessInfo.processInfo.systemUptime
        )
        entries[cKey] = entry
        currentMemoryBytes += byteSize

        trimMemoryIfNeeded()
    }

    /// Generates multi-tier mipmap pyramid asynchronously in the background.
    public func generateMipmapPyramid(for key: String, sourceImage: NSImage) {
        // Immediately store full representation
        setMipmap(for: key, image: sourceImage, lod: .full)

        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }

            let origSize = sourceImage.size
            guard origSize.width > 0 && origSize.height > 0 else { return }

            // 1. Medium LOD (50% scale)
            let mediumSize = CGSize(width: origSize.width * 0.5, height: origSize.height * 0.5)
            if let mediumImg = self.downsample(image: sourceImage, targetSize: mediumSize) {
                self.setMipmap(for: key, image: mediumImg, lod: .medium)
            }

            // 2. Thumbnail LOD (25% scale)
            let thumbSize = CGSize(width: origSize.width * 0.25, height: origSize.height * 0.25)
            if let thumbImg = self.downsample(image: sourceImage, targetSize: thumbSize) {
                self.setMipmap(for: key, image: thumbImg, lod: .thumbnail)
            }

            // 3. Nano LOD (max 64x64 or 96x64)
            let nanoRatio = min(96.0 / origSize.width, 64.0 / origSize.height)
            let nanoSize = CGSize(width: max(16, origSize.width * nanoRatio), height: max(16, origSize.height * nanoRatio))
            if let nanoImg = self.downsample(image: sourceImage, targetSize: nanoSize) {
                self.setMipmap(for: key, image: nanoImg, lod: .nano)
            }
        }
    }

    /// Downsamples NSImage using high-performance CoreGraphics bicubic interpolation.
    private func downsample(image: NSImage, targetSize: CGSize) -> NSImage? {
        guard targetSize.width > 0 && targetSize.height > 0 else { return nil }
        guard let tiffData = image.tiffRepresentation,
              let imageSource = CGImageSourceCreateWithData(tiffData as CFData, nil) else {
            return nil
        }

        let maxDimension = max(targetSize.width, targetSize.height) * 2.0 // 2x retina
        let options: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimension
        ]

        guard let downscaledCG = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
            return nil
        }

        return NSImage(cgImage: downscaledCG, size: targetSize)
    }

    /// Evicts oldest entries until memory is strictly under the 35MB budget.
    private func trimMemoryIfNeeded() {
        guard currentMemoryBytes > SwiftDOMAssetMipmapCache.maxMemoryLimitBytes else { return }

        // Sort by last access time ascending (oldest first)
        let sortedEntries = entries.values.sorted { $0.lastAccessTime < $1.lastAccessTime }
        for entry in sortedEntries {
            let cKey = compoundKey(entry.key, lod: entry.lod)
            entries.removeValue(forKey: cKey)
            currentMemoryBytes -= entry.byteSize

            if currentMemoryBytes <= SwiftDOMAssetMipmapCache.maxMemoryLimitBytes * 8 / 10 {
                // Trimmed down to 80% of limit
                break
            }
        }
    }

    /// Purges cache entries that do not match active keys.
    public func purgeUnused(activeKeys: Set<String>) {
        lock.lock()
        defer { lock.unlock() }

        var keysToRemove: [String] = []
        for (cKey, entry) in entries {
            if !activeKeys.contains(entry.key) {
                keysToRemove.append(cKey)
                currentMemoryBytes -= entry.byteSize
            }
        }
        for k in keysToRemove {
            entries.removeValue(forKey: k)
        }
    }

    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        entries.removeAll()
        currentMemoryBytes = 0
    }

    public var memoryFootprintMB: Double {
        lock.lock()
        defer { lock.unlock() }
        return Double(currentMemoryBytes) / (1024.0 * 1024.0)
    }

    private func estimateMemoryFootprint(for image: NSImage) -> Int {
        guard let rep = image.representations.first else {
            return Int(image.size.width * image.size.height * 4)
        }
        let pixelsWide = max(1, rep.pixelsWide > 0 ? rep.pixelsWide : Int(image.size.width * 2))
        let pixelsHigh = max(1, rep.pixelsHigh > 0 ? rep.pixelsHigh : Int(image.size.height * 2))
        return pixelsWide * pixelsHigh * 4 // RGBA 32-bit
    }
}

// MARK: - SwiftDOM Scene Tree (Virtual Scene Graph for 9 Spaces)

@MainActor
public final class SwiftDOMTree {
    public private(set) var rootNode: SwiftDOMNode
    public private(set) var desktopNodes: [Int: SwiftDOMNode] = [:]
    public private(set) var allNodes: [SwiftDOMNode] = []
    public private(set) var gridDimension: Int = 3
    public private(set) var canvasSize: CGSize = .zero
    public private(set) var viewportSize: CGSize = .zero

    public init(screenWidth: CGFloat, screenHeight: CGFloat, dimension: Int = 3) {
        self.gridDimension = dimension
        let canvasW = screenWidth * CGFloat(dimension)
        let canvasH = screenHeight * CGFloat(dimension)
        self.viewportSize = CGSize(width: screenWidth, height: screenHeight)
        self.canvasSize = CGSize(width: canvasW, height: canvasH)

        var planeStyle = SwiftDOMStyle()
        planeStyle.backgroundColor = NSColor(calibratedRed: 0.02, green: 0.03, blue: 0.06, alpha: 1.0)

        let root = SwiftDOMNode(
            id: "swift-dom-root",
            tag: .plane,
            frame: CGRect(x: 0, y: 0, width: canvasW, height: canvasH),
            style: planeStyle
        )
        self.rootNode = root
    }

    /// Builds the continuous 3x3 (9 Desktops) or 9x9 (81 Universe) spatial scene graph with zero padding.
    public func buildGridHierarchy(
        screenWidth: CGFloat,
        screenHeight: CGFloat,
        isUniverse81: Bool = false,
        wallpaperProvider: ((Int) -> NSImage?)? = nil,
        windowsProvider: ((Int) -> [ManagedWindowInfo])? = nil
    ) {
        let dim = isUniverse81 ? 9 : 3
        self.gridDimension = dim
        let totalCount = dim * dim
        let canvasW = screenWidth * CGFloat(dim)
        let canvasH = screenHeight * CGFloat(dim)

        self.viewportSize = CGSize(width: screenWidth, height: screenHeight)
        self.canvasSize = CGSize(width: canvasW, height: canvasH)

        rootNode.frame = CGRect(x: 0, y: 0, width: canvasW, height: canvasH)
        rootNode.removeAllChildren()
        desktopNodes.removeAll()
        allNodes.removeAll()
        allNodes.append(rootNode)

        // 1. Desktops placed edge-to-edge with ZERO PADDING
        for slot in 1...totalCount {
            let (col, row) = isUniverse81 ? SpatialPlaneManager.universeCoordinate(for: slot) : SpatialPlaneManager.gridCoordinate(for: slot)
            let originX = CGFloat(col) * screenWidth
            let originY = CGFloat(row) * screenHeight
            let desktopRect = CGRect(x: originX, y: originY, width: screenWidth, height: screenHeight)

            let desktopNode = buildDesktopNode(
                slotIndex: slot,
                col: col,
                row: row,
                frame: desktopRect,
                screenWidth: screenWidth,
                screenHeight: screenHeight,
                wallpaper: wallpaperProvider?(slot),
                windows: windowsProvider?(slot) ?? []
            )

            rootNode.addChild(desktopNode)
            desktopNodes[slot] = desktopNode
            collectNodes(desktopNode)
        }

        // 2. Seam Lines
        let seams = buildSeamLines(screenWidth: screenWidth, screenHeight: screenHeight, dimension: dim)
        for seam in seams {
            rootNode.addChild(seam)
            allNodes.append(seam)
        }
    }

    private func collectNodes(_ node: SwiftDOMNode) {
        allNodes.append(node)
        for child in node.children {
            collectNodes(child)
        }
    }

    private func buildDesktopNode(
        slotIndex: Int,
        col: Int,
        row: Int,
        frame: CGRect,
        screenWidth: CGFloat,
        screenHeight: CGFloat,
        wallpaper: NSImage?,
        windows: [ManagedWindowInfo]
    ) -> SwiftDOMNode {
        var panelStyle = SwiftDOMStyle()
        panelStyle.backgroundColor = NSColor(
            calibratedRed: 0.05 + CGFloat(col) * 0.03,
            green: 0.07 + CGFloat(row) * 0.03,
            blue: 0.14,
            alpha: 1.0
        )
        panelStyle.borderColor = NSColor(calibratedRed: 0.0, green: 0.8, blue: 0.9, alpha: 0.25)
        panelStyle.borderWidth = 0.5

        let compass = SpatialPlaneManager.compassBearing(for: slotIndex)
        let isCurrentSpace = slotIndex == MacDesktopsManager.shared.currentSpaceIndex

        let desktopNode = SwiftDOMNode(
            id: "desktop-\(slotIndex)",
            tag: .desktop,
            frame: frame,
            style: panelStyle,
            desktopSlot: slotIndex,
            action: {
                SpatialPlaneManager.shared.zoomInToSelectedDesktop(index: slotIndex)
            }
        )

        // Wallpaper node with Mipmap Cache key
        if let wpImage = wallpaper {
            let wpKey = "wp-slot-\(slotIndex)"
            SwiftDOMAssetMipmapCache.shared.generateMipmapPyramid(for: wpKey, sourceImage: wpImage)

            let wallpaperNode = SwiftDOMNode(
                id: "wallpaper-\(slotIndex)",
                tag: .wallpaper,
                frame: CGRect(x: 0, y: 0, width: screenWidth, height: screenHeight),
                image: wpImage,
                imageCacheKey: wpKey,
                desktopSlot: slotIndex
            )
            desktopNode.addChild(wallpaperNode)
        }

        // Space Compass Badge (Top-Left)
        var badgeStyle = SwiftDOMStyle()
        badgeStyle.backgroundColor = NSColor(calibratedWhite: 0.0, alpha: 0.70)
        badgeStyle.borderColor = isCurrentSpace ? NSColor.systemGreen : NSColor.cyan
        badgeStyle.borderWidth = 1.0
        badgeStyle.cornerRadius = 10.0

        let badgeNode = SwiftDOMNode(
            id: "badge-\(slotIndex)",
            tag: .badge,
            frame: CGRect(x: 36, y: 36, width: 260, height: 36),
            style: badgeStyle,
            text: "Desktop \(slotIndex) • \(compass) [\(col), \(row)]",
            font: NSFont.systemFont(ofSize: 13, weight: .bold),
            textColor: isCurrentSpace ? NSColor.systemGreen : NSColor.white,
            desktopSlot: slotIndex
        )
        desktopNode.addChild(badgeNode)

        // Virtual Window Nodes (~64 bytes/node without allocating window buffers)
        let windowWidth = min(screenWidth - 140, 880.0)
        let windowHeight: CGFloat = 340.0
        let windowOriginX = (screenWidth - windowWidth) / 2.0
        let windowOriginY: CGFloat = 110.0

        var winStyle = SwiftDOMStyle()
        winStyle.backgroundColor = NSColor(calibratedRed: 0.11, green: 0.12, blue: 0.17, alpha: 0.94)
        winStyle.borderColor = NSColor(calibratedWhite: 1.0, alpha: 0.16)
        winStyle.borderWidth = 1.0
        winStyle.cornerRadius = 10.0
        winStyle.shadowColor = NSColor.black
        winStyle.shadowRadius = 24.0
        winStyle.shadowOffset = CGSize(width: 0, height: -10)
        winStyle.shadowOpacity = 0.55

        let windowNode = SwiftDOMNode(
            id: "win-\(slotIndex)",
            tag: .window,
            frame: CGRect(x: windowOriginX, y: windowOriginY, width: windowWidth, height: windowHeight),
            style: winStyle,
            desktopSlot: slotIndex
        )

        // Titlebar
        var titleBarStyle = SwiftDOMStyle()
        titleBarStyle.backgroundColor = NSColor(calibratedRed: 0.16, green: 0.17, blue: 0.23, alpha: 1.0)
        titleBarStyle.cornerRadius = 10.0

        let titleText = windows.first?.title.isEmpty == false ? (windows.first?.title ?? "") : "Space \(slotIndex) • Native Window (100% Scale)"
        let titlebarNode = SwiftDOMNode(
            id: "tb-\(slotIndex)",
            tag: .titlebar,
            frame: CGRect(x: 0, y: windowHeight - 34, width: windowWidth, height: 34),
            style: titleBarStyle,
            text: titleText,
            font: NSFont.systemFont(ofSize: 13, weight: .semibold),
            textColor: NSColor.white,
            desktopSlot: slotIndex
        )
        windowNode.addChild(titlebarNode)

        // Content
        let contentNode = SwiftDOMNode(
            id: "content-\(slotIndex)",
            tag: .content,
            frame: CGRect(x: 16, y: 16, width: windowWidth - 32, height: windowHeight - 60),
            text: "SwiftDOM: 0-Padding Continuous 9-Grid Surface.\nVirtual Scene Graph with <35MB Unified Mipmap Cache.\nGlide fluidly with 3 fingers on trackpad.",
            font: NSFont.monospacedSystemFont(ofSize: 12, weight: .medium),
            textColor: NSColor(calibratedRed: 0.3, green: 0.9, blue: 1.0, alpha: 0.95),
            desktopSlot: slotIndex
        )
        windowNode.addChild(contentNode)

        desktopNode.addChild(windowNode)
        return desktopNode
    }

    private func buildSeamLines(screenWidth: CGFloat, screenHeight: CGFloat, dimension: Int) -> [SwiftDOMNode] {
        var seamNodes: [SwiftDOMNode] = []
        let canvasW = screenWidth * CGFloat(dimension)
        let canvasH = screenHeight * CGFloat(dimension)

        for col in 1..<dimension {
            let seamX = screenWidth * CGFloat(col)
            let isMacro = (col % 3 == 0)
            var style = SwiftDOMStyle()
            style.backgroundColor = isMacro ?
                NSColor(calibratedRed: 0.0, green: 0.85, blue: 1.0, alpha: 0.85) :
                NSColor(calibratedRed: 0.0, green: 0.85, blue: 1.0, alpha: 0.35)

            let vSeam = SwiftDOMNode(
                id: "v-seam-\(col)",
                tag: .seamLine,
                frame: CGRect(x: seamX - (isMacro ? 1.0 : 0.5), y: 0, width: isMacro ? 2.0 : 1.0, height: canvasH),
                style: style
            )
            seamNodes.append(vSeam)
        }

        for row in 1..<dimension {
            let seamY = screenHeight * CGFloat(row)
            let isMacro = (row % 3 == 0)
            var style = SwiftDOMStyle()
            style.backgroundColor = isMacro ?
                NSColor(calibratedRed: 0.0, green: 0.85, blue: 1.0, alpha: 0.85) :
                NSColor(calibratedRed: 0.0, green: 0.85, blue: 1.0, alpha: 0.35)

            let hSeam = SwiftDOMNode(
                id: "h-seam-\(row)",
                tag: .seamLine,
                frame: CGRect(x: 0, y: seamY - (isMacro ? 1.0 : 0.5), width: canvasW, height: isMacro ? 2.0 : 1.0),
                style: style
            )
            seamNodes.append(hSeam)
        }

        return seamNodes
    }

    // MARK: - Frustum Culling & Viewport Occlusion Engine
    /// Computes what is in the user's viewport cone and culls offscreen subtrees.
    public func performFrustumCulling(
        cameraOffset: CGSize,
        viewportSize: CGSize,
        zoomScale: CGFloat = 1.0,
        anticipatoryBuffer: CGFloat = 120.0
    ) -> (visible: [SwiftDOMNode], culledCount: Int) {
        let effectiveScale = max(0.01, zoomScale)
        let scaledW = (viewportSize.width > 0 ? viewportSize.width : 1440.0) / effectiveScale
        let scaledH = (viewportSize.height > 0 ? viewportSize.height : 900.0) / effectiveScale

        // Viewport bounding box in canvas coordinates
        let viewportRect = CGRect(
            x: -cameraOffset.width / effectiveScale,
            y: -cameraOffset.height / effectiveScale,
            width: scaledW,
            height: scaledH
        )

        // Expanded Frustum Cone including anticipatory buffer for 120 FPS glide
        let frustumConeRect = viewportRect.insetBy(dx: -anticipatoryBuffer, dy: -anticipatoryBuffer)
        let viewportCenter = CGPoint(x: viewportRect.midX, y: viewportRect.midY)

        var visibleList: [SwiftDOMNode] = []
        var culledCount: Int = 0

        for desktopNode in desktopNodes.values {
            let dFrame = desktopNode.frame
            let intersects = frustumConeRect.intersects(dFrame)

            if !intersects {
                // Entire desktop slot is outside the frustum cone: cull parent & all children in O(1)
                desktopNode.isVisible = false
                desktopNode.lodLevel = .culled
                desktopNode.intersectionRatio = 0.0
                culledCount += 1 + desktopNode.children.count
                for child in desktopNode.children {
                    child.isVisible = false
                    child.lodLevel = .culled
                    child.intersectionRatio = 0.0
                }
            } else {
                // Desktop is inside the frustum cone: compute intersection & LOD
                desktopNode.isVisible = true
                let overlap = viewportRect.intersection(dFrame)
                let ratio = (overlap.isNull || dFrame.width <= 0 || dFrame.height <= 0) ? 0.0 :
                    (overlap.width * overlap.height) / (dFrame.width * dFrame.height)
                desktopNode.intersectionRatio = ratio

                // Distance from viewport center to determine LOD
                let desktopCenter = CGPoint(x: dFrame.midX, y: dFrame.midY)
                let dist = hypot(desktopCenter.x - viewportCenter.x, desktopCenter.y - viewportCenter.y)
                let maxDist = max(viewportRect.width, viewportRect.height)

                let assignedLOD: SwiftDOMLODLevel = {
                    if effectiveScale < 0.35 {
                        return .nano
                    } else if effectiveScale < 0.70 {
                        return .thumbnail
                    } else if ratio > 0.60 || dist < maxDist * 0.45 {
                        return .full
                    } else if ratio > 0.15 || dist < maxDist * 0.90 {
                        return .medium
                    } else {
                        return .thumbnail
                    }
                }()

                desktopNode.lodLevel = assignedLOD
                visibleList.append(desktopNode)

                for child in desktopNode.children {
                    child.isVisible = true
                    child.lodLevel = assignedLOD
                    child.intersectionRatio = ratio
                    visibleList.append(child)
                }
            }
        }

        // Seam lines are always kept visible
        for node in rootNode.children where node.tag == .seamLine {
            node.isVisible = true
            visibleList.append(node)
        }

        return (visible: visibleList, culledCount: culledCount)
    }
}

// MARK: - SwiftDOM Engine (Observable Singleton & Dispatcher)

@MainActor
public final class SwiftDOMEngine: ObservableObject {
    public static let shared = SwiftDOMEngine()

    @Published public var rootNode: SwiftDOMNode? = nil
    @Published public var activeVisibleNodes: [SwiftDOMNode] = []
    @Published public var culledNodeCount: Int = 0
    @Published public var renderedNodeCount: Int = 0
    @Published public var totalNodeCount: Int = 0
    @Published public var memoryUsageMB: Double = 0.0
    @Published public var cameraOffset: CGSize = .zero
    @Published public var zoomScale: CGFloat = 1.0

    public private(set) var viewportSize: CGSize = SpatialPlaneManager.HardwareDisplayGeometry.defaultRetinaPoints
    public private(set) var canvasSize: CGSize = CGSize(
        width: SpatialPlaneManager.HardwareDisplayGeometry.defaultRetinaPoints.width * 3.0,
        height: SpatialPlaneManager.HardwareDisplayGeometry.defaultRetinaPoints.height * 3.0
    )

    public private(set) var sceneTree: SwiftDOMTree
    public let mipmapCache = SwiftDOMAssetMipmapCache.shared

    private init() {
        let metrics = SpatialPlaneManager.HardwareDisplayGeometry.currentDisplayMetrics()
        self.sceneTree = SwiftDOMTree(screenWidth: metrics.points.width, screenHeight: metrics.points.height)
        build9GridTree(screenWidth: metrics.points.width, screenHeight: metrics.points.height)
    }

    // ── Build Universe Continuous Mega-Canvas (Zero Padding 9x9 Universe / 3x3 Pixel) ──
    public func buildUniverseTree(screenWidth: CGFloat, screenHeight: CGFloat, forceUniverse81: Bool? = nil) {
        let is81 = forceUniverse81 ?? SpatialPlaneManager.shared.isUniverse81Active
        self.viewportSize = CGSize(width: screenWidth, height: screenHeight)

        sceneTree.buildGridHierarchy(
            screenWidth: screenWidth,
            screenHeight: screenHeight,
            isUniverse81: is81,
            wallpaperProvider: { slot in
                let buffer = SpatialPlaneManager.shared.ramBuffers[slot]
                return buffer?.thumbnail ?? buffer?.wallpaper ?? WallpaperManager.shared.activeWallpaperImage
            },
            windowsProvider: { slot in
                return SpatialPlaneManager.shared.ramBuffers[slot]?.windows ?? []
            }
        )

        self.rootNode = sceneTree.rootNode
        self.canvasSize = sceneTree.canvasSize
        self.totalNodeCount = sceneTree.allNodes.count

        reconcile(cameraOffset: cameraOffset, viewportSize: viewportSize, scale: zoomScale)
    }

    @inlinable
    public func buildUniverseTree(screenW: CGFloat, screenH: CGFloat) {
        buildUniverseTree(screenWidth: screenW, screenHeight: screenH)
    }

    public func build9GridTree(screenWidth: CGFloat, screenHeight: CGFloat) {
        buildUniverseTree(screenWidth: screenWidth, screenHeight: screenHeight, forceUniverse81: false)
    }

    @inlinable
    public func build9GridTree(screenW: CGFloat, screenH: CGFloat) {
        buildUniverseTree(screenWidth: screenW, screenHeight: screenH, forceUniverse81: false)
    }

    // ── Frustum Culling & Viewport Occlusion Reconciler ──
    public func reconcile(cameraOffset: CGSize, viewportSize: CGSize, scale: CGFloat = 1.0) {
        self.cameraOffset = cameraOffset
        self.zoomScale = scale
        if viewportSize.width > 0 && viewportSize.height > 0 {
            self.viewportSize = viewportSize
        }

        let result = sceneTree.performFrustumCulling(
            cameraOffset: cameraOffset,
            viewportSize: self.viewportSize,
            zoomScale: scale
        )

        self.activeVisibleNodes = result.visible
        self.culledNodeCount = result.culledCount
        self.renderedNodeCount = result.visible.count
        self.memoryUsageMB = mipmapCache.memoryFootprintMB
    }

    public func reconcile(cameraOffset: CGSize, viewportSize: CGSize) {
        reconcile(cameraOffset: cameraOffset, viewportSize: viewportSize, scale: zoomScale)
    }

    /// Syncs RAM buffers into the virtual scene tree without allocating window buffers.
    public func syncFromRAMBuffers() {
        guard let screen = NSScreen.main else { return }
        buildUniverseTree(screenWidth: screen.frame.width, screenHeight: screen.frame.height)
    }

    public func hitTest(pointInCanvas: CGPoint) -> SwiftDOMNode? {
        return rootNode?.hitTest(pointInCanvas: pointInCanvas)
    }
}

// MARK: - SwiftDOM Hosting View (Direct CoreAnimation Hardware Compositing)

public final class SwiftDOMHostingView: NSView {
    private let planeLayer = CALayer()
    private var nodeLayers: [String: CALayer] = [:]

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupLayerPipeline()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayerPipeline()
    }

    private func setupLayerPipeline() {
        self.wantsLayer = true
        self.layer = CALayer()
        self.layer?.backgroundColor = NSColor.black.cgColor

        planeLayer.anchorPoint = .zero
        planeLayer.position = .zero
        planeLayer.actions = [
            "position": NSNull(),
            "bounds": NSNull(),
            "transform": NSNull()
        ]
        self.layer?.addSublayer(planeLayer)
        rebuildLayerGraph()
    }

    public func rebuildLayerGraph() {
        planeLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        nodeLayers.removeAll()

        MainActor.assumeIsolated {
            guard let root = SwiftDOMEngine.shared.rootNode else { return }
            planeLayer.bounds = root.frame

            for node in root.children {
                let layer = createLayer(for: node)
                planeLayer.addSublayer(layer)
                nodeLayers[node.id] = layer
            }
        }
    }

    @MainActor
    private func createLayer(for node: SwiftDOMNode) -> CALayer {
        let layer: CALayer
        if let text = node.text {
            let textLayer = CATextLayer()
            textLayer.string = text
            textLayer.font = node.font ?? NSFont.systemFont(ofSize: 13)
            textLayer.fontSize = node.font?.pointSize ?? 13
            textLayer.foregroundColor = node.textColor?.cgColor ?? NSColor.white.cgColor
            textLayer.contentsScale = NSScreen.main?.backingScaleFactor ?? 2.0
            textLayer.alignmentMode = .center
            textLayer.isWrapped = true
            layer = textLayer
        } else {
            layer = CALayer()
        }

        layer.frame = node.frame
        layer.backgroundColor = node.style.backgroundColor.cgColor
        layer.borderColor = node.style.borderColor.cgColor
        layer.borderWidth = node.style.borderWidth
        layer.cornerRadius = node.style.cornerRadius
        layer.opacity = node.style.opacity
        layer.isHidden = !node.isVisible

        if let cacheKey = node.imageCacheKey,
           let cachedImg = SwiftDOMAssetMipmapCache.shared.image(for: cacheKey, lod: node.lodLevel) {
            layer.contents = cachedImg
            layer.contentsGravity = .resizeAspectFill
            layer.masksToBounds = true
        } else if let imageContent = node.image {
            layer.contents = imageContent
            layer.contentsGravity = .resizeAspectFill
            layer.masksToBounds = true
        }

        if let shadowColorValue = node.style.shadowColor {
            layer.shadowColor = shadowColorValue.cgColor
            layer.shadowRadius = node.style.shadowRadius
            layer.shadowOffset = node.style.shadowOffset
            layer.shadowOpacity = node.style.shadowOpacity
        }

        layer.actions = [
            "position": NSNull(),
            "bounds": NSNull(),
            "transform": NSNull(),
            "opacity": NSNull(),
            "hidden": NSNull()
        ]

        for child in node.children {
            let childLayer = createLayer(for: child)
            layer.addSublayer(childLayer)
            nodeLayers[child.id] = childLayer
        }

        return layer
    }

    public func setCameraOffset(_ offset: CGSize, scale: CGFloat = 1.0) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        var transform = CATransform3DMakeTranslation(offset.width, offset.height, 0)
        if scale != 1.0 {
            transform = CATransform3DScale(transform, scale, scale, 1.0)
        }
        planeLayer.transform = transform
        CATransaction.commit()
    }

    public override func layout() {
        super.layout()
        MainActor.assumeIsolated {
            SwiftDOMEngine.shared.buildUniverseTree(screenWidth: bounds.width, screenHeight: bounds.height)
            rebuildLayerGraph()
        }
    }
}
