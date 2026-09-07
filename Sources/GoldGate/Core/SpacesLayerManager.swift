import AppKit
import Foundation
import SwiftUI
import ApplicationServices

// MARK: - 🎨 Spaces Layer Manager (Photoshop-Style Spatial Desktop Stack)
// Treats every macOS Desktop Space (1..9 or 1..81) as a Photoshop-style Graphic Layer
// with individual Blend Modes, Opacity, Live Eyeball Visibility, Non-destructive Filters,
// and Direct SkyLight WindowServer synchronization.

public enum SpaceBlendMode: String, CaseIterable, Identifiable, Sendable {
    case normal = "Normal"
    case multiply = "Multiply"
    case screen = "Screen"
    case overlay = "Overlay"
    case softLight = "Soft Light"
    case hardLight = "Hard Light"
    case colorDodge = "Color Dodge"
    case difference = "Difference"
    case luminosity = "Luminosity"

    public var id: String { rawValue }

    public var swiftUIBlendMode: BlendMode {
        switch self {
        case .normal: return .normal
        case .multiply: return .multiply
        case .screen: return .screen
        case .overlay: return .overlay
        case .softLight: return .softLight
        case .hardLight: return .hardLight
        case .colorDodge: return .colorDodge
        case .difference: return .difference
        case .luminosity: return .luminosity
        }
    }

    public var icon: String {
        switch self {
        case .normal: return "square.fill"
        case .multiply: return "multiply.square.fill"
        case .screen: return "sparkles.square.fill"
        case .overlay: return "square.2.layers.3d.top.filled"
        case .softLight: return "sun.min.fill"
        case .hardLight: return "sun.max.fill"
        case .colorDodge: return "bolt.shield.fill"
        case .difference: return "circle.lefthalf.filled"
        case .luminosity: return "rays"
        }
    }
}

// MARK: - Space Graphic Layer Model
public struct SpaceGraphicLayer: Identifiable, Equatable {
    public var id: Int { spaceIndex }
    public let spaceIndex: Int // 1..9 (or 1..81)
    public var name: String
    public var blendMode: SpaceBlendMode
    public var opacity: Double // 0.0 ... 1.0
    public var fillOpacity: Double // 0.0 ... 1.0
    public var isVisible: Bool // Eyeball toggle
    public var isLocked: Bool // Protection lock
    public var isSolo: Bool // Solo focus mode
    public var blurRadius: Double // Gaussian frosted glass radius
    public var brightness: Double // -1.0 ... 1.0
    public var contrast: Double // 0.5 ... 2.0
    public var runningAppNames: [String]
    public var runningAppIcons: [NSImage]
    public var liveThumbnail: NSImage?

    public init(
        spaceIndex: Int,
        name: String,
        blendMode: SpaceBlendMode = .normal,
        opacity: Double = 1.0,
        fillOpacity: Double = 1.0,
        isVisible: Bool = true,
        isLocked: Bool = false,
        isSolo: Bool = false,
        blurRadius: Double = 0.0,
        brightness: Double = 0.0,
        contrast: Double = 1.0,
        runningAppNames: [String] = [],
        runningAppIcons: [NSImage] = [],
        liveThumbnail: NSImage? = nil
    ) {
        self.spaceIndex = spaceIndex
        self.name = name
        self.blendMode = blendMode
        self.opacity = opacity
        self.fillOpacity = fillOpacity
        self.isVisible = isVisible
        self.isLocked = isLocked
        self.isSolo = isSolo
        self.blurRadius = blurRadius
        self.brightness = brightness
        self.contrast = contrast
        self.runningAppNames = runningAppNames
        self.runningAppIcons = runningAppIcons
        self.liveThumbnail = liveThumbnail
    }

    public static func == (lhs: SpaceGraphicLayer, rhs: SpaceGraphicLayer) -> Bool {
        lhs.spaceIndex == rhs.spaceIndex &&
        lhs.name == rhs.name &&
        lhs.blendMode == rhs.blendMode &&
        lhs.opacity == rhs.opacity &&
        lhs.isVisible == rhs.isVisible &&
        lhs.isLocked == rhs.isLocked &&
        lhs.isSolo == rhs.isSolo
    }
}

// MARK: - Spaces Layer Manager Core
@MainActor
public final class SpacesLayerManager: ObservableObject {
    public static let shared = SpacesLayerManager()

    // ── Published Layer Stack ──────────────────────────────────────────────
    @Published public var layers: [SpaceGraphicLayer] = []
    @Published public var selectedLayerIndex: Int = 1
    @Published public var isLayerPaletteOpen: Bool = true
    @Published public var isMultiSpaceGhostingEnabled: Bool = false
    @Published public var globalStackOpacity: Double = 1.0
    @Published public var statusMessage: String = "Spaces Layer Manager Initialized ✨"

    private let desktopsManager = MacDesktopsManager.shared
    private let skyLightBridge = SkyLightNativeBridge.shared
    private let neuralGovernor = SkyLightNeuralGovernorEngine.shared

    private init() {
        synchronizeLayersWithMacOSSpaces()
    }

    // MARK: - 1. Synchronize Layers with macOS Mission Control Spaces
    public func synchronizeLayersWithMacOSSpaces() {
        desktopsManager.refreshSpaces()
        let spaces = desktopsManager.spaces

        var newLayers: [SpaceGraphicLayer] = []
        for space in spaces {
            let idx = space.index
            let defaultName: String
            switch idx {
            case 1: defaultName = "Layer 1 • Prime Desktop"
            case 2: defaultName = "Layer 2 • Code & Matrix"
            case 3: defaultName = "Layer 3 • Design & Media"
            case 4: defaultName = "Layer 4 • Research & Canvas"
            case 5: defaultName = "Layer 5 • Chat & Zenith"
            default: defaultName = "Layer \(idx) • Workspace"
            }

            // Retrieve saved layer states from UserDefaults if available
            let savedBlendRaw = UserDefaults.standard.string(forKey: "genie.spaceLayer.blend.\(idx)")
                ?? UserDefaults.standard.string(forKey: "goldgate.spaceLayer.blend.\(idx)") ?? "Normal"
            let savedBlend = SpaceBlendMode(rawValue: savedBlendRaw) ?? .normal
            let savedOpacity = UserDefaults.standard.object(forKey: "genie.spaceLayer.opacity.\(idx)") != nil
                ? UserDefaults.standard.double(forKey: "genie.spaceLayer.opacity.\(idx)")
                : (UserDefaults.standard.object(forKey: "goldgate.spaceLayer.opacity.\(idx)") != nil ? UserDefaults.standard.double(forKey: "goldgate.spaceLayer.opacity.\(idx)") : 1.0)
            let savedVisible = UserDefaults.standard.object(forKey: "genie.spaceLayer.visible.\(idx)") != nil
                ? UserDefaults.standard.bool(forKey: "genie.spaceLayer.visible.\(idx)")
                : (UserDefaults.standard.object(forKey: "goldgate.spaceLayer.visible.\(idx)") != nil ? UserDefaults.standard.bool(forKey: "goldgate.spaceLayer.visible.\(idx)") : true)
            let savedLocked = UserDefaults.standard.bool(forKey: "genie.spaceLayer.locked.\(idx)")
                || UserDefaults.standard.bool(forKey: "goldgate.spaceLayer.locked.\(idx)")

            let cachedPlane = SpatialPlaneManager.shared.desktopPlaneCacheBuffers[idx]
            let appNames = cachedPlane?.runningAppNames ?? []
            let appIcons = cachedPlane?.runningAppIcons ?? []
            let thumbnail = cachedPlane?.thumbnail ?? desktopsManager.desktopLivePreviews[idx]

            let layer = SpaceGraphicLayer(
                spaceIndex: idx,
                name: defaultName,
                blendMode: savedBlend,
                opacity: savedOpacity,
                isVisible: savedVisible,
                isLocked: savedLocked,
                runningAppNames: appNames,
                runningAppIcons: appIcons,
                liveThumbnail: thumbnail
            )
            newLayers.append(layer)
        }

        self.layers = newLayers
        self.selectedLayerIndex = desktopsManager.currentSpaceIndex
    }

    // MARK: - 2. Layer Adjustments (Opacity, Blend Mode, Visibility)
    public func setLayerBlendMode(spaceIndex: Int, blendMode: SpaceBlendMode) {
        guard let idx = layers.firstIndex(where: { $0.spaceIndex == spaceIndex }) else { return }
        layers[idx].blendMode = blendMode
        UserDefaults.standard.set(blendMode.rawValue, forKey: "genie.spaceLayer.blend.\(spaceIndex)")
        HapticFeedback.playClickSound()
        statusMessage = "Set \(layers[idx].name) to \(blendMode.rawValue) blend"
    }

    public func setLayerOpacity(spaceIndex: Int, opacity: Double) {
        guard let idx = layers.firstIndex(where: { $0.spaceIndex == spaceIndex }) else { return }
        let clamped = max(0.05, min(1.0, opacity))
        layers[idx].opacity = clamped
        UserDefaults.standard.set(clamped, forKey: "genie.spaceLayer.opacity.\(spaceIndex)")
    }

    public func toggleLayerVisibility(spaceIndex: Int) {
        guard let idx = layers.firstIndex(where: { $0.spaceIndex == spaceIndex }) else { return }
        layers[idx].isVisible.toggle()
        UserDefaults.standard.set(layers[idx].isVisible, forKey: "genie.spaceLayer.visible.\(spaceIndex)")
        HapticFeedback.playClickSound()
    }

    public func toggleLayerLock(spaceIndex: Int) {
        guard let idx = layers.firstIndex(where: { $0.spaceIndex == spaceIndex }) else { return }
        layers[idx].isLocked.toggle()
        UserDefaults.standard.set(layers[idx].isLocked, forKey: "genie.spaceLayer.locked.\(spaceIndex)")
        HapticFeedback.playClickSound()
    }

    public func toggleSoloLayer(spaceIndex: Int) {
        guard let targetIdx = layers.firstIndex(where: { $0.spaceIndex == spaceIndex }) else { return }
        let currentSolo = layers[targetIdx].isSolo
        for i in layers.indices {
            layers[i].isSolo = false
            if !currentSolo {
                layers[i].isVisible = (layers[i].spaceIndex == spaceIndex)
            } else {
                layers[i].isVisible = true
            }
        }
        layers[targetIdx].isSolo = !currentSolo
        HapticFeedback.playClickSound()
        statusMessage = !currentSolo ? "Soloing Space Layer \(spaceIndex) 🎯" : "Exited Solo Mode ✨"
    }

    // MARK: - 3. Layer Actions (New Space Layer, Merge Layers, Switch Layer)
    public func createNewSpaceLayer() {
        HapticFeedback.playClickSound()
        desktopsManager.createDesktop()
        synchronizeLayersWithMacOSSpaces()
        statusMessage = "Created new Space Layer ✨"
    }

    public func selectAndSwitchToLayer(spaceIndex: Int) {
        selectedLayerIndex = spaceIndex
        desktopsManager.switchToDesktop(index: spaceIndex)
        HapticFeedback.playClickSound()
        statusMessage = "Switched to Space Layer \(spaceIndex)"
    }

    public func mergeLayerDown(sourceSpaceIndex: Int) {
        guard sourceSpaceIndex > 1,
              layers.contains(where: { $0.spaceIndex == sourceSpaceIndex }) else { return }
        let targetSpaceIndex = sourceSpaceIndex - 1

        HapticFeedback.playClickSound()
        // Collect all windows on source space and migrate to target space via SkyLight
        let primaryHeight = NSScreen.screens.first?.frame.height ?? 1080
        let visibleWindows = SmartGridManager.shared.getVisibleWindows(primaryHeight: primaryHeight)

        if let targetSpace = desktopsManager.spaces.first(where: { $0.index == targetSpaceIndex }),
           let targetSpaceID = targetSpace.id64 {
            let winIDs = visibleWindows.map { $0.id }
            _ = skyLightBridge.moveWindowsToSpace(windowIDs: winIDs, spaceID: targetSpaceID)
        }

        statusMessage = "Merged Layer \(sourceSpaceIndex) down into Layer \(targetSpaceIndex) 🪄"
        synchronizeLayersWithMacOSSpaces()
    }
}
