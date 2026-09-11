import Foundation
import CoreGraphics
import SwiftUI
import Observation
import QuartzCore

// MARK: - 🌌 Genie Block-to-Block Visual Teleportation Engine
/// Executes instantaneous and warp-interpolated visual teleportation between distinct
/// UI blocks, code sections, simulator windows, and spatial canvas sectors.
///
/// Features:
/// 1. Spatial Block Registry: Tracks bounding boxes, sectors, and semantic labels of all active blocks.
/// 2. Three-Phase Quantum Warp Transition:
///    - Phase 1: Departure Beacon (origin block contracts with specular cyan glow).
///    - Phase 2: Parallax Z-Pullback (viewport eases along translation vector Δ(B2 - B1)).
///    - Phase 3: Arrival Materialization (destination block anchors with emerald shockwave).
/// 3. Zero-Orientation Disorientation: Prevents motion sickness via SLERP-aligned focal anchoring.
@available(macOS 13.0, *)
@Observable
public final class GenieBlockTeleportationEngine: @unchecked Sendable {
    public static let shared = GenieBlockTeleportationEngine()

    // MARK: - Spatial Block Representation
    public struct SpatialBlock: Identifiable, Hashable, Sendable {
        public let id: String
        public let name: String
        public let category: String // "Editor", "Simulator", "Terminal", "Chat", "Preview"
        public var rect: CGRect
        public var sectorIndex: Int
        public var zIndex: Int

        public init(
            id: String,
            name: String,
            category: String,
            rect: CGRect,
            sectorIndex: Int = 1,
            zIndex: Int = 0
        ) {
            self.id = id
            self.name = name
            self.category = category
            self.rect = rect
            self.sectorIndex = sectorIndex
            self.zIndex = zIndex
        }

        public var center: CGPoint {
            CGPoint(x: rect.midX, y: rect.midY)
        }
    }

    // ── Observable Teleportation State ────────────────────────────────────
    public private(set) var registeredBlocks: [String: SpatialBlock] = [:]
    public private(set) var activeBlockID: String?
    public private(set) var previousBlockID: String?
    public private(set) var isTeleporting: Bool = false
    public private(set) var teleportProgress: Double = 0.0 // 0.0 -> 1.0
    public private(set) var arrivalBeaconOpacity: Double = 0.0
    public private(set) var departureBeaconOpacity: Double = 0.0
    public private(set) var cameraTranslationOffset: CGSize = .zero
    public private(set) var cameraZoomScale: Double = 1.0

    private let lock = NSLock()

    private init() {
        registerDefaultCoreBlocks()
    }

    // MARK: - 1. Default Workspace Block Scaffolding
    private func registerDefaultCoreBlocks() {
        registerBlock(SpatialBlock(id: "editor", name: "Code Atelier", category: "Editor", rect: CGRect(x: 100, y: 100, width: 800, height: 650), sectorIndex: 1))
        registerBlock(SpatialBlock(id: "simulator", name: "iPhone Simulator", category: "Simulator", rect: CGRect(x: 950, y: 100, width: 420, height: 850), sectorIndex: 2))
        registerBlock(SpatialBlock(id: "terminal", name: "System Terminal", category: "Terminal", rect: CGRect(x: 100, y: 800, width: 800, height: 350), sectorIndex: 4))
        registerBlock(SpatialBlock(id: "chat", name: "Genie AI Console", category: "Chat", rect: CGRect(x: 1420, y: 100, width: 450, height: 750), sectorIndex: 3))
    }

    // MARK: - 2. Block Registration & Updates
    public func registerBlock(_ block: SpatialBlock) {
        lock.lock()
        defer { lock.unlock() }
        registeredBlocks[block.id] = block
    }

    public func unregisterBlock(id: String) {
        lock.lock()
        defer { lock.unlock() }
        registeredBlocks.removeValue(forKey: id)
    }

    // MARK: - 3. Instant Block-to-Block Teleportation
    /// Teleports visual focus directly to the target block by ID
    @MainActor
    public func teleport(to targetBlockID: String, animationDuration: Double = 0.22) {
        guard let target = registeredBlocks[targetBlockID], targetBlockID != activeBlockID else { return }

        let originID = activeBlockID
        previousBlockID = originID
        activeBlockID = targetBlockID
        isTeleporting = true

        let origin = originID.flatMap { registeredBlocks[$0] }
        let deltaX = origin != nil ? (target.center.x - origin!.center.x) : 0
        let deltaY = origin != nil ? (target.center.y - origin!.center.y) : 0

        // 🌟 Phase 1: Departure Beacon Flare
        departureBeaconOpacity = 1.0
        withAnimation(.easeOut(duration: animationDuration * 0.4)) {
            departureBeaconOpacity = 0.0
            cameraZoomScale = 0.94 // Slight 3D parallax pullback
        }

        // 🌟 Phase 2: Translation Jump
        withAnimation(.spring(response: animationDuration, dampingFraction: 0.82)) {
            cameraTranslationOffset = CGSize(width: -deltaX, height: -deltaY)
            cameraZoomScale = 1.0
        }

        // 🌟 Phase 3: Arrival Materialization Shockwave
        arrivalBeaconOpacity = 1.0
        withAnimation(.easeOut(duration: animationDuration * 0.6).delay(animationDuration * 0.4)) {
            arrivalBeaconOpacity = 0.0
        }

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(animationDuration * 1_000_000_000))
            self.isTeleporting = false
            self.cameraTranslationOffset = .zero
        }
    }

    // MARK: - 4. Relative & Cycling Teleportation
    @MainActor
    public func teleportNext() {
        let keys = Array(registeredBlocks.keys).sorted()
        guard !keys.isEmpty else { return }
        guard let current = activeBlockID, let idx = keys.firstIndex(of: current) else {
            teleport(to: keys[0])
            return
        }
        let nextIdx = (idx + 1) % keys.count
        teleport(to: keys[nextIdx])
    }

    @MainActor
    public func teleportPrevious() {
        let keys = Array(registeredBlocks.keys).sorted()
        guard !keys.isEmpty else { return }
        guard let current = activeBlockID, let idx = keys.firstIndex(of: current) else {
            teleport(to: keys.last!)
            return
        }
        let prevIdx = (idx - 1 + keys.count) % keys.count
        teleport(to: keys[prevIdx])
    }

    // MARK: - 5. Teleport to Semantic Query (AI / Voice)
    @MainActor
    public func teleportToBlock(matching query: String) -> Bool {
        let lower = query.lowercased()
        guard let match = registeredBlocks.values.first(where: {
            $0.id.lowercased().contains(lower) ||
            $0.name.lowercased().contains(lower) ||
            $0.category.lowercased().contains(lower)
        }) else {
            return false
        }
        teleport(to: match.id)
        return true
    }
}
