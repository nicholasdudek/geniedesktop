import AppKit
import Foundation
import SwiftUI
import CoreGraphics
import CoreImage
import CoreImage.CIFilterBuiltins
import Metal
import simd
import QuartzCore

// MARK: - 🎨 Photoshop Layer Blend Modes

public enum PhotoshopBlendMode: String, CaseIterable, Identifiable, Sendable, Codable {
    case normal = "Normal"
    case multiply = "Multiply"
    case screen = "Screen"
    case overlay = "Overlay"
    case softLight = "Soft Light"
    case hardLight = "Hard Light"
    case colorDodge = "Color Dodge"
    case colorBurn = "Color Burn"
    case darken = "Darken"
    case lighten = "Lighten"
    case difference = "Difference"
    case exclusion = "Exclusion"
    case hue = "Hue"
    case saturation = "Saturation"
    case color = "Color"
    case luminosity = "Luminosity"

    public var id: String { rawValue }

    public var category: String {
        switch self {
        case .normal:
            return "Standard"
        case .darken, .multiply, .colorBurn:
            return "Darken"
        case .lighten, .screen, .colorDodge:
            return "Lighten"
        case .overlay, .softLight, .hardLight:
            return "Contrast"
        case .difference, .exclusion:
            return "Inversion"
        case .hue, .saturation, .color, .luminosity:
            return "Component"
        }
    }

    /// Map to Apple CoreGraphics CGBlendMode
    public var cgBlendMode: CGBlendMode {
        switch self {
        case .normal: return .normal
        case .multiply: return .multiply
        case .screen: return .screen
        case .overlay: return .overlay
        case .softLight: return .softLight
        case .hardLight: return .hardLight
        case .colorDodge: return .colorDodge
        case .colorBurn: return .colorBurn
        case .darken: return .darken
        case .lighten: return .lighten
        case .difference: return .difference
        case .exclusion: return .exclusion
        case .hue: return .hue
        case .saturation: return .saturation
        case .color: return .color
        case .luminosity: return .luminosity
        }
    }

    /// Map to SwiftUI GraphicsContext.BlendMode
    public var graphicsContextBlendMode: GraphicsContext.BlendMode {
        switch self {
        case .normal: return .normal
        case .multiply: return .multiply
        case .screen: return .screen
        case .overlay: return .overlay
        case .softLight: return .softLight
        case .hardLight: return .hardLight
        case .colorDodge: return .colorDodge
        case .colorBurn: return .colorBurn
        case .darken: return .darken
        case .lighten: return .lighten
        case .difference: return .difference
        case .exclusion: return .exclusion
        case .hue: return .hue
        case .saturation: return .saturation
        case .color: return .color
        case .luminosity: return .luminosity
        }
    }

    /// CoreImage CIFilter name for blending
    public var ciFilterName: String? {
        switch self {
        case .normal: return "CISourceOverCompositing"
        case .multiply: return "CIMultiplyBlendMode"
        case .screen: return "CIScreenBlendMode"
        case .overlay: return "CIOverlayBlendMode"
        case .softLight: return "CISoftLightBlendMode"
        case .hardLight: return "CIHardLightBlendMode"
        case .colorDodge: return "CIColorDodgeBlendMode"
        case .colorBurn: return "CIColorBurnBlendMode"
        case .darken: return "CIDarkenBlendMode"
        case .lighten: return "CILightenBlendMode"
        case .difference: return "CIDifferenceBlendMode"
        case .exclusion: return "CIExclusionBlendMode"
        case .hue: return "CIHueBlendMode"
        case .saturation: return "CISaturationBlendMode"
        case .color: return "CIColorBlendMode"
        case .luminosity: return "CILuminosityBlendMode"
        }
    }

    public var mathematicalFormula: String {
        switch self {
        case .normal: return "f(a, b) = b"
        case .multiply: return "f(a, b) = a * b"
        case .screen: return "f(a, b) = 1 - (1 - a)(1 - b)"
        case .overlay: return "f(a, b) = a < 0.5 ? 2ab : 1 - 2(1-a)(1-b)"
        case .softLight: return "f(a, b) = 2ab + a²(1 - 2b)"
        case .hardLight: return "f(a, b) = b < 0.5 ? 2ab : 1 - 2(1-a)(1-b)"
        case .colorDodge: return "f(a, b) = a / (1 - b)"
        case .colorBurn: return "f(a, b) = 1 - (1 - a) / b"
        case .darken: return "f(a, b) = min(a, b)"
        case .lighten: return "f(a, b) = max(a, b)"
        case .difference: return "f(a, b) = |a - b|"
        case .exclusion: return "f(a, b) = a + b - 2ab"
        case .hue: return "Lum(a) + Sat(a) + Hue(b)"
        case .saturation: return "Lum(a) + Sat(b) + Hue(a)"
        case .color: return "Lum(a) + Sat(b) + Hue(b)"
        case .luminosity: return "Lum(b) + Sat(a) + Hue(a)"
        }
    }
}

// MARK: - 🎭 Graphic Layer Types

public enum GraphicLayerType: String, CaseIterable, Identifiable, Sendable, Codable {
    case wallpaper = "Background Wallpaper Layer"
    case spatialWindow = "Spatial Window Layer"
    case holographicHUD = "Holographic HUD Layer"
    case glassRefraction = "Glass Refraction Layer"
    case omniMenu = "Omni Menu Layer"
    case proceduralShader = "Procedural Shader FX"
    case vectorGraphic = "Vector Shape Layer"
    case textTypography = "Haute Typography Layer"
    case imageAsset = "Image Bitmap Layer"

    public var id: String { rawValue }

    public var iconName: String {
        switch self {
        case .wallpaper: return "photo.artframe"
        case .spatialWindow: return "macwindow.on.rectangle"
        case .holographicHUD: return "grid"
        case .glassRefraction: return "sparkles.rectangle.stack"
        case .omniMenu: return "menubar.dock.rectangle"
        case .proceduralShader: return "waveform.path.ecg"
        case .vectorGraphic: return "circle.hexagongrid.fill"
        case .textTypography: return "textformat"
        case .imageAsset: return "photo.fill"
        }
    }

    public var accentColor: Color {
        switch self {
        case .wallpaper: return .purple
        case .spatialWindow: return .blue
        case .holographicHUD: return .cyan
        case .glassRefraction: return .teal
        case .omniMenu: return .orange
        case .proceduralShader: return .green
        case .vectorGraphic: return .pink
        case .textTypography: return .yellow
        case .imageAsset: return .indigo
        }
    }
}

// MARK: - 🌈 Layer Color Adjustments

public struct LayerColorAdjustments: Equatable, Sendable, Codable {
    public var hueAngle: Double       // -180.0 ... +180.0
    public var saturation: Double     // 0.0 ... 2.0 (1.0 = normal)
    public var brightness: Double     // -1.0 ... 1.0 (0.0 = normal)
    public var contrast: Double       // 0.0 ... 2.0 (1.0 = normal)
    public var exposure: Double       // -2.0 ... 2.0 (0.0 = normal)
    public var temperature: Double    // -1.0 (cool/blue) ... +1.0 (warm/amber)

    public init(
        hueAngle: Double = 0.0,
        saturation: Double = 1.0,
        brightness: Double = 0.0,
        contrast: Double = 1.0,
        exposure: Double = 0.0,
        temperature: Double = 0.0
    ) {
        self.hueAngle = hueAngle
        self.saturation = saturation
        self.brightness = brightness
        self.contrast = contrast
        self.exposure = exposure
        self.temperature = temperature
    }

    public var isNeutral: Bool {
        abs(hueAngle) < 0.01 &&
        abs(saturation - 1.0) < 0.01 &&
        abs(brightness) < 0.01 &&
        abs(contrast - 1.0) < 0.01 &&
        abs(exposure) < 0.01 &&
        abs(temperature) < 0.01
    }

    public mutating func reset() {
        self = LayerColorAdjustments()
    }
}

// MARK: - 🌑 Layer Drop Shadow

public struct LayerDropShadow: Equatable, Sendable, Codable {
    public var isEnabled: Bool
    public var red: Double
    public var green: Double
    public var blue: Double
    public var opacity: Double       // 0.0 ... 1.0
    public var radius: CGFloat       // 0 ... 50
    public var xOffset: CGFloat      // -50 ... 50
    public var yOffset: CGFloat      // -50 ... 50
    public var spread: CGFloat       // 0 ... 20

    public init(
        isEnabled: Bool = false,
        red: Double = 0.0,
        green: Double = 0.0,
        blue: Double = 0.0,
        opacity: Double = 0.5,
        radius: CGFloat = 12.0,
        xOffset: CGFloat = 0.0,
        yOffset: CGFloat = 8.0,
        spread: CGFloat = 0.0
    ) {
        self.isEnabled = isEnabled
        self.red = red
        self.green = green
        self.blue = blue
        self.opacity = opacity
        self.radius = radius
        self.xOffset = xOffset
        self.yOffset = yOffset
        self.spread = spread
    }

    public var color: Color {
        Color(red: red, green: green, blue: blue).opacity(opacity)
    }

    public var cgColor: CGColor {
        CGColor(red: CGFloat(red), green: CGFloat(green), blue: CGFloat(blue), alpha: CGFloat(opacity))
    }
}

// MARK: - 🌫️ Layer Blur

public struct LayerBlur: Equatable, Sendable, Codable {
    public var isEnabled: Bool
    public var radius: CGFloat       // 0.0 ... 100.0

    public init(isEnabled: Bool = false, radius: CGFloat = 0.0) {
        self.isEnabled = isEnabled
        self.radius = radius
    }
}

// MARK: - ✂️ Layer Mask

public enum LayerMaskShape: String, CaseIterable, Identifiable, Sendable, Codable {
    case none = "None"
    case roundedRect = "Rounded Rect"
    case circle = "Circular Aperture"
    case vignetteGradient = "Radial Vignette"
    case horizontalSplit = "Horizontal Split"
    case diagonalSweep = "Diagonal Sweep"

    public var id: String { rawValue }
}

public struct LayerMask: Equatable, Sendable, Codable {
    public var isEnabled: Bool
    public var isInverted: Bool
    public var shape: LayerMaskShape
    public var featherRadius: CGFloat
    public var opacity: Double

    public init(
        isEnabled: Bool = false,
        isInverted: Bool = false,
        shape: LayerMaskShape = .none,
        featherRadius: CGFloat = 10.0,
        opacity: Double = 1.0
    ) {
        self.isEnabled = isEnabled
        self.isInverted = isInverted
        self.shape = shape
        self.featherRadius = featherRadius
        self.opacity = opacity
    }
}

// MARK: - 🧱 Graphic Layer Item

public struct GraphicLayerItem: Identifiable, Equatable, Sendable, Codable {
    public var id: UUID
    public var name: String
    public var type: GraphicLayerType
    public var isVisible: Bool
    public var isLocked: Bool
    public var opacity: Double       // 0.0 ... 1.0 (Layer Opacity)
    public var fillOpacity: Double   // 0.0 ... 1.0 (Fill Opacity - doesn't affect layer effects)
    public var blendMode: PhotoshopBlendMode
    public var isClippingMask: Bool  // True if clipped to layer below

    // Layer Styles & Effects
    public var dropShadow: LayerDropShadow
    public var blur: LayerBlur
    public var adjustments: LayerColorAdjustments
    public var mask: LayerMask

    // Spatial Layout
    public var frameNormalized: CGRect // Normalized relative to canvas (0..1)
    public var rotationDegrees: Double
    public var scale: Double

    // Procedural parameters
    public var primaryColorHex: String
    public var secondaryColorHex: String
    public var customTitle: String
    public var customDetail: String

    public init(
        id: UUID = UUID(),
        name: String,
        type: GraphicLayerType,
        isVisible: Bool = true,
        isLocked: Bool = false,
        opacity: Double = 1.0,
        fillOpacity: Double = 1.0,
        blendMode: PhotoshopBlendMode = .normal,
        isClippingMask: Bool = false,
        dropShadow: LayerDropShadow = LayerDropShadow(),
        blur: LayerBlur = LayerBlur(),
        adjustments: LayerColorAdjustments = LayerColorAdjustments(),
        mask: LayerMask = LayerMask(),
        frameNormalized: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1),
        rotationDegrees: Double = 0.0,
        scale: Double = 1.0,
        primaryColorHex: String = "#00D2FF",
        secondaryColorHex: String = "#3A7BD5",
        customTitle: String = "",
        customDetail: String = ""
    ) {
        self.id = id
        self.name = name
        self.type = type
        self.isVisible = isVisible
        self.isLocked = isLocked
        self.opacity = opacity
        self.fillOpacity = fillOpacity
        self.blendMode = blendMode
        self.isClippingMask = isClippingMask
        self.dropShadow = dropShadow
        self.blur = blur
        self.adjustments = adjustments
        self.mask = mask
        self.frameNormalized = frameNormalized
        self.rotationDegrees = rotationDegrees
        self.scale = scale
        self.primaryColorHex = primaryColorHex
        self.secondaryColorHex = secondaryColorHex
        self.customTitle = customTitle
        self.customDetail = customDetail
    }

    public var hasActiveFX: Bool {
        dropShadow.isEnabled || blur.isEnabled || !adjustments.isNeutral || mask.isEnabled || isClippingMask
    }
}

// MARK: - 📚 Graphic Layer Stack Model

public struct GraphicLayerStack: Equatable, Sendable, Codable {
    /// Layers stored from bottom (index 0) to top (index count - 1)
    public var layers: [GraphicLayerItem]
    public var canvasWidth: CGFloat
    public var canvasHeight: CGFloat

    public init(
        layers: [GraphicLayerItem] = [],
        canvasWidth: CGFloat = 1200,
        canvasHeight: CGFloat = 800
    ) {
        self.layers = layers
        self.canvasWidth = canvasWidth
        self.canvasHeight = canvasHeight
    }

    /// Layers reversed for top-to-bottom UI inspector display (Photoshop layer stack order)
    public var inspectorLayersTopToBottom: [GraphicLayerItem] {
        layers.reversed()
    }

    public var canvasSize: CGSize {
        CGSize(width: canvasWidth, height: canvasHeight)
    }

    /// Default Preset 5-Layer Photoshop Scene Stack
    public static var defaultPreset: GraphicLayerStack {
        let l1 = GraphicLayerItem(
            name: "Background Wallpaper Layer",
            type: .wallpaper,
            isVisible: true,
            isLocked: true,
            opacity: 1.0,
            fillOpacity: 1.0,
            blendMode: .normal,
            adjustments: LayerColorAdjustments(brightness: 0.05, contrast: 1.1),
            frameNormalized: CGRect(x: 0, y: 0, width: 1, height: 1),
            primaryColorHex: "#0F2027",
            secondaryColorHex: "#2C5364",
            customTitle: "Deep Space Aurora Nebula",
            customDetail: "8K HDR Wallpaper Canvas"
        )

        let l2 = GraphicLayerItem(
            name: "Spatial Window Layer",
            type: .spatialWindow,
            isVisible: true,
            isLocked: false,
            opacity: 0.95,
            fillOpacity: 1.0,
            blendMode: .normal,
            dropShadow: LayerDropShadow(isEnabled: true, opacity: 0.55, radius: 24, yOffset: 12),
            blur: LayerBlur(isEnabled: false, radius: 0),
            adjustments: LayerColorAdjustments(),
            frameNormalized: CGRect(x: 0.12, y: 0.15, width: 0.76, height: 0.70),
            primaryColorHex: "#1E1E24",
            secondaryColorHex: "#2B2D42",
            customTitle: "Spatial 3x3 Station Matrix",
            customDetail: "9 Interactive Desktop Surfaces"
        )

        let l3 = GraphicLayerItem(
            name: "Glass Refraction Layer",
            type: .glassRefraction,
            isVisible: true,
            isLocked: false,
            opacity: 0.82,
            fillOpacity: 0.75,
            blendMode: .screen,
            dropShadow: LayerDropShadow(isEnabled: true, red: 0.0, green: 0.85, blue: 1.0, opacity: 0.3, radius: 16),
            blur: LayerBlur(isEnabled: true, radius: 4.0),
            adjustments: LayerColorAdjustments(saturation: 1.25),
            frameNormalized: CGRect(x: 0.18, y: 0.22, width: 0.64, height: 0.56),
            primaryColorHex: "#00F2FE",
            secondaryColorHex: "#4FACFE",
            customTitle: "Atelier Smoked Glass Acrylic",
            customDetail: "Specular Bezel & Caustic Lens"
        )

        let l4 = GraphicLayerItem(
            name: "Holographic HUD Layer",
            type: .holographicHUD,
            isVisible: true,
            isLocked: false,
            opacity: 0.88,
            fillOpacity: 0.90,
            blendMode: .colorDodge,
            dropShadow: LayerDropShadow(isEnabled: true, red: 0.0, green: 0.95, blue: 0.85, opacity: 0.5, radius: 10),
            adjustments: LayerColorAdjustments(hueAngle: 15.0, saturation: 1.4),
            frameNormalized: CGRect(x: 0.05, y: 0.05, width: 0.90, height: 0.90),
            primaryColorHex: "#00F5D4",
            secondaryColorHex: "#7B2CBF",
            customTitle: "Quantum Telemetry HUD Grid",
            customDetail: "Real-Time 120 FPS Neural Gauges"
        )

        let l5 = GraphicLayerItem(
            name: "Omni Menu Layer",
            type: .omniMenu,
            isVisible: true,
            isLocked: false,
            opacity: 1.0,
            fillOpacity: 1.0,
            blendMode: .normal,
            dropShadow: LayerDropShadow(isEnabled: true, opacity: 0.65, radius: 20, yOffset: 6),
            adjustments: LayerColorAdjustments(),
            frameNormalized: CGRect(x: 0.02, y: 0.02, width: 0.96, height: 0.08),
            primaryColorHex: "#111116",
            secondaryColorHex: "#1F1F2E",
            customTitle: "Grand Horizon Omni MenuBar",
            customDetail: "Status Hub, Quick Switcher & Studio"
        )

        return GraphicLayerStack(layers: [l1, l2, l3, l4, l5])
    }
}

// MARK: - ⚙️ Photoshop Layer Compositor Engine

@MainActor
public final class PhotoshopLayerCompositorEngine: ObservableObject {
    public static let shared = PhotoshopLayerCompositorEngine()

    @Published public var stack: GraphicLayerStack = .defaultPreset
    @Published public var selectedLayerId: UUID? = nil
    @Published public var isRendering: Bool = false
    @Published public var previewRenderTimeMs: Double = 0.0
    @Published public var compositeCache: NSImage? = nil

    private let ciContext: CIContext

    public init() {
        if let defaultDevice = MTLCreateSystemDefaultDevice() {
            self.ciContext = CIContext(mtlDevice: defaultDevice, options: [.cacheIntermediates: false])
        } else {
            self.ciContext = CIContext(options: nil)
        }
        if let first = stack.layers.last {
            self.selectedLayerId = first.id
        }
    }

    // MARK: - Direct Layers Array Accessor

    public var layers: [GraphicLayerItem] {
        get { stack.layers }
        set { stack.layers = newValue }
    }

    // MARK: - Layer Selection & Mutation Accessors

    public var selectedLayer: GraphicLayerItem? {
        get {
            guard let id = selectedLayerId else { return nil }
            return stack.layers.first(where: { $0.id == id })
        }
        set {
            guard let id = selectedLayerId, let newLayer = newValue else { return }
            if let index = stack.layers.firstIndex(where: { $0.id == id }) {
                stack.layers[index] = newLayer
            }
        }
    }

    public func selectLayer(id: UUID) {
        self.selectedLayerId = id
    }

    public func toggleVisibility(id: UUID) {
        guard let index = stack.layers.firstIndex(where: { $0.id == id }) else { return }
        stack.layers[index].isVisible.toggle()
    }

    public func toggleVisibility(for id: UUID) {
        toggleVisibility(id: id)
    }

    public func toggleLock(id: UUID) {
        guard let index = stack.layers.firstIndex(where: { $0.id == id }) else { return }
        stack.layers[index].isLocked.toggle()
    }

    public func toggleLock(for id: UUID) {
        toggleLock(id: id)
    }

    public func updateBlendMode(id: UUID, blendMode: PhotoshopBlendMode) {
        guard let index = stack.layers.firstIndex(where: { $0.id == id }) else { return }
        stack.layers[index].blendMode = blendMode
    }

    public func updateBlendMode(_ mode: PhotoshopBlendMode, for id: UUID) {
        updateBlendMode(id: id, blendMode: mode)
    }

    public func updateOpacity(id: UUID, opacity: Double) {
        guard let index = stack.layers.firstIndex(where: { $0.id == id }) else { return }
        stack.layers[index].opacity = max(0.0, min(1.0, opacity))
    }

    public func updateOpacity(_ opacity: Double, for id: UUID) {
        updateOpacity(id: id, opacity: opacity)
    }

    public func updateFillOpacity(_ fillOpacity: Double, for id: UUID) {
        guard let index = stack.layers.firstIndex(where: { $0.id == id }) else { return }
        stack.layers[index].fillOpacity = max(0.0, min(1.0, fillOpacity))
    }

    public func updateDropShadow(_ shadow: LayerDropShadow, for id: UUID) {
        guard let index = stack.layers.firstIndex(where: { $0.id == id }) else { return }
        stack.layers[index].dropShadow = shadow
    }

    public func updateBlur(_ blur: LayerBlur, for id: UUID) {
        guard let index = stack.layers.firstIndex(where: { $0.id == id }) else { return }
        stack.layers[index].blur = blur
    }

    public func updateAdjustments(_ adjustments: LayerColorAdjustments, for id: UUID) {
        guard let index = stack.layers.firstIndex(where: { $0.id == id }) else { return }
        stack.layers[index].adjustments = adjustments
    }

    public func updateMask(_ mask: LayerMask, for id: UUID) {
        guard let index = stack.layers.firstIndex(where: { $0.id == id }) else { return }
        stack.layers[index].mask = mask
    }

    public func addNewLayer(type: GraphicLayerType = .vectorGraphic, name: String? = nil) {
        let count = stack.layers.count + 1
        let layerName = name ?? "Layer \(count) (\(type.rawValue.components(separatedBy: " ").first ?? "Graphic"))"
        let newLayer = GraphicLayerItem(
            name: layerName,
            type: type,
            isVisible: true,
            isLocked: false,
            opacity: 1.0,
            fillOpacity: 1.0,
            blendMode: .normal,
            dropShadow: LayerDropShadow(),
            blur: LayerBlur(),
            adjustments: LayerColorAdjustments(),
            mask: LayerMask(),
            frameNormalized: CGRect(x: 0.2, y: 0.2, width: 0.6, height: 0.6),
            primaryColorHex: "#FF007F",
            secondaryColorHex: "#7928CA",
            customTitle: "New Creative Asset",
            customDetail: "Vector Layer"
        )
        stack.layers.append(newLayer)
        selectedLayerId = newLayer.id
    }

    public func addLayer(name: String, type: GraphicLayerType) {
        addNewLayer(type: type, name: name)
    }

    public func duplicateLayer(id: UUID) {
        guard let index = stack.layers.firstIndex(where: { $0.id == id }) else { return }
        var dup = stack.layers[index]
        dup.id = UUID()
        dup.name = "\(dup.name) Copy"
        stack.layers.insert(dup, at: index + 1)
        selectedLayerId = dup.id
    }

    public func deleteLayer(id: UUID) {
        guard stack.layers.count > 1 else { return }
        if let index = stack.layers.firstIndex(where: { $0.id == id }) {
            stack.layers.remove(at: index)
            if selectedLayerId == id {
                selectedLayerId = stack.layers.last?.id
            }
        }
    }

    public func moveLayer(fromIndex: Int, toIndex: Int) {
        guard fromIndex >= 0, fromIndex < stack.layers.count,
              toIndex >= 0, toIndex < stack.layers.count,
              fromIndex != toIndex else { return }
        let layer = stack.layers.remove(at: fromIndex)
        stack.layers.insert(layer, at: toIndex)
    }

    public func moveLayerUp(id: UUID) {
        guard let index = stack.layers.firstIndex(where: { $0.id == id }), index < stack.layers.count - 1 else { return }
        stack.layers.swapAt(index, index + 1)
    }

    public func moveLayerDown(id: UUID) {
        guard let index = stack.layers.firstIndex(where: { $0.id == id }), index > 0 else { return }
        stack.layers.swapAt(index, index - 1)
    }

    public func resetToDefaultPreset() {
        self.stack = .defaultPreset
        self.selectedLayerId = stack.layers.last?.id
    }

    // MARK: - ⚡ Live CoreGraphics Layer Rendering Pass

    public func drawCompositedScene(
        in context: GraphicsContext,
        size: CGSize,
        elapsedTime: Double = 0.0
    ) {
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            let elapsedMs = (CFAbsoluteTimeGetCurrent() - startTime) * 1000.0
            DispatchQueue.main.async {
                self.previewRenderTimeMs = elapsedMs
            }
        }

        guard size.width > 0, size.height > 0 else { return }

        // Iterate from bottom layer (index 0) to top layer
        for index in 0..<stack.layers.count {
            let layer = stack.layers[index]
            guard layer.isVisible, layer.opacity > 0.001 else { continue }

            var layerContext = context
            layerContext.opacity = layer.opacity
            layerContext.blendMode = layer.blendMode.graphicsContextBlendMode

            let layerRect = CGRect(
                x: layer.frameNormalized.origin.x * size.width,
                y: layer.frameNormalized.origin.y * size.height,
                width: layer.frameNormalized.size.width * size.width,
                height: layer.frameNormalized.size.height * size.height
            )

            // 1. Draw Drop Shadow if enabled
            if layer.dropShadow.isEnabled, layer.dropShadow.opacity > 0.01 {
                let shadowRect = layerRect.offsetBy(dx: layer.dropShadow.xOffset, dy: layer.dropShadow.yOffset)
                let shadowColor = Color(
                    red: layer.dropShadow.red,
                    green: layer.dropShadow.green,
                    blue: layer.dropShadow.blue,
                    opacity: layer.dropShadow.opacity * layer.opacity
                )
                let shadowPath = Path(roundedRect: shadowRect, cornerRadius: 12)
                var shadowCtx = layerContext
                shadowCtx.addFilter(.blur(radius: layer.dropShadow.radius))
                shadowCtx.fill(shadowPath, with: .color(shadowColor))
            }

            // 2. Draw Layer Content by Type with Fill Opacity & Blur
            var contentCtx = layerContext
            contentCtx.opacity = layer.fillOpacity

            if layer.blur.isEnabled, layer.blur.radius > 0.5 {
                contentCtx.addFilter(.blur(radius: layer.blur.radius))
            }

            // Color adjustments
            if !layer.adjustments.isNeutral {
                if abs(layer.adjustments.hueAngle) > 0.5 {
                    contentCtx.addFilter(.hueRotation(.degrees(layer.adjustments.hueAngle)))
                }
                if abs(layer.adjustments.saturation - 1.0) > 0.01 {
                    contentCtx.addFilter(.saturation(layer.adjustments.saturation))
                }
                if abs(layer.adjustments.contrast - 1.0) > 0.01 {
                    contentCtx.addFilter(.contrast(layer.adjustments.contrast))
                }
                if abs(layer.adjustments.brightness) > 0.01 {
                    contentCtx.addFilter(.brightness(layer.adjustments.brightness))
                }
            }

            // Apply Mask Clipping if enabled
            if layer.mask.isEnabled {
                applyLayerMask(mask: layer.mask, in: &contentCtx, layerRect: layerRect)
            }

            // Procedural Layer Geometry Rendering
            drawLayerGraphics(layer: layer, in: contentCtx, rect: layerRect, canvasSize: size, time: elapsedTime)
        }
    }

    private func applyLayerMask(mask: LayerMask, in context: inout GraphicsContext, layerRect: CGRect) {
        switch mask.shape {
        case .none:
            break
        case .roundedRect:
            let insetRect = layerRect.insetBy(dx: 8, dy: 8)
            context.clip(to: Path(roundedRect: insetRect, cornerRadius: 16))
        case .circle:
            let minDim = min(layerRect.width, layerRect.height)
            let circleRect = CGRect(
                x: layerRect.midX - minDim * 0.45,
                y: layerRect.midY - minDim * 0.45,
                width: minDim * 0.9,
                height: minDim * 0.9
            )
            context.clip(to: Path(ellipseIn: circleRect))
        case .vignetteGradient:
            let insetRect = layerRect.insetBy(dx: 12, dy: 12)
            context.clip(to: Path(roundedRect: insetRect, cornerRadius: 24))
        case .horizontalSplit:
            let topHalf = CGRect(x: layerRect.minX, y: layerRect.minY, width: layerRect.width, height: layerRect.height * 0.6)
            context.clip(to: Path(topHalf))
        case .diagonalSweep:
            var path = Path()
            path.move(to: CGPoint(x: layerRect.minX, y: layerRect.minY))
            path.addLine(to: CGPoint(x: layerRect.maxX, y: layerRect.minY))
            path.addLine(to: CGPoint(x: layerRect.minX, y: layerRect.maxY))
            path.closeSubpath()
            context.clip(to: path)
        }
    }

    // MARK: - Procedural Layer Content Graphics

    private func drawLayerGraphics(
        layer: GraphicLayerItem,
        in context: GraphicsContext,
        rect: CGRect,
        canvasSize: CGSize,
        time: Double
    ) {
        let pColor = Color(hex: layer.primaryColorHex) ?? .cyan
        let sColor = Color(hex: layer.secondaryColorHex) ?? .blue

        switch layer.type {
        case .wallpaper:
            // High-grade procedurally shaded wallpaper canvas
            let gradient = Gradient(colors: [pColor, sColor, Color(hex: "#05050A") ?? .black])
            context.fill(
                Path(rect),
                with: .linearGradient(
                    gradient,
                    startPoint: CGPoint(x: rect.minX, y: rect.minY),
                    endPoint: CGPoint(x: rect.maxX, y: rect.maxY)
                )
            )

            // Celestial nebula glow orbs
            let orb1 = CGRect(x: rect.minX + rect.width * 0.15, y: rect.minY + rect.height * 0.2, width: rect.width * 0.4, height: rect.height * 0.4)
            var orbCtx = context
            orbCtx.addFilter(.blur(radius: 40))
            orbCtx.fill(Path(ellipseIn: orb1), with: .color(pColor.opacity(0.35)))

            let orb2 = CGRect(x: rect.minX + rect.width * 0.55, y: rect.minY + rect.height * 0.4, width: rect.width * 0.35, height: rect.height * 0.35)
            orbCtx.fill(Path(ellipseIn: orb2), with: .color(sColor.opacity(0.30)))

        case .spatialWindow:
            // macOS / Spatial Desktop window card
            let cardPath = Path(roundedRect: rect, cornerRadius: 14)
            context.fill(cardPath, with: .color(Color(hex: "#1A1A24")?.opacity(0.92) ?? Color.black.opacity(0.85)))
            context.stroke(cardPath, with: .color(Color.white.opacity(0.18)), lineWidth: 1.0)

            // Top titlebar
            let titleBarRect = CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: 32)
            context.fill(Path(roundedRect: titleBarRect, cornerRadius: 14), with: .color(Color.white.opacity(0.04)))

            // Window stoplights (Red, Yellow, Green)
            let stoplightY = rect.minY + 12
            context.fill(Path(ellipseIn: CGRect(x: rect.minX + 14, y: stoplightY, width: 8, height: 8)), with: .color(Color.red.opacity(0.85)))
            context.fill(Path(ellipseIn: CGRect(x: rect.minX + 26, y: stoplightY, width: 8, height: 8)), with: .color(Color.yellow.opacity(0.85)))
            context.fill(Path(ellipseIn: CGRect(x: rect.minX + 38, y: stoplightY, width: 8, height: 8)), with: .color(Color.green.opacity(0.85)))

            // Inner content layout - 3x3 station preview grid
            let contentRect = CGRect(x: rect.minX + 16, y: rect.minY + 44, width: rect.width - 32, height: rect.height - 60)
            let cols = 3
            let rows = 2
            let cellW = (contentRect.width - CGFloat(cols - 1) * 8) / CGFloat(cols)
            let cellH = (contentRect.height - CGFloat(rows - 1) * 8) / CGFloat(rows)

            for r in 0..<rows {
                for c in 0..<cols {
                    let cellX = contentRect.minX + CGFloat(c) * (cellW + 8)
                    let cellY = contentRect.minY + CGFloat(r) * (cellH + 8)
                    let cellBox = CGRect(x: cellX, y: cellY, width: cellW, height: cellH)
                    let isPrimaryCell = (r == 0 && c == 0)
                    let cellColor = isPrimaryCell ? pColor.opacity(0.25) : Color.white.opacity(0.06)

                    context.fill(Path(roundedRect: cellBox, cornerRadius: 6), with: .color(cellColor))
                    context.stroke(
                        Path(roundedRect: cellBox, cornerRadius: 6),
                        with: .color(isPrimaryCell ? pColor.opacity(0.8) : Color.white.opacity(0.12)),
                        lineWidth: isPrimaryCell ? 1.2 : 0.6
                    )
                }
            }

        case .glassRefraction:
            // Frosted Atelier Glass Refraction & Specular Bevel
            let glassPath = Path(roundedRect: rect, cornerRadius: 20)
            let glassGradient = Gradient(colors: [
                Color.white.opacity(0.35),
                pColor.opacity(0.15),
                sColor.opacity(0.20),
                Color.black.opacity(0.20)
            ])
            context.fill(
                glassPath,
                with: .linearGradient(glassGradient, startPoint: CGPoint(x: rect.minX, y: rect.minY), endPoint: CGPoint(x: rect.maxX, y: rect.maxY))
            )
            context.stroke(
                glassPath,
                with: .linearGradient(
                    Gradient(colors: [Color.white.opacity(0.8), pColor.opacity(0.5), Color.clear]),
                    startPoint: CGPoint(x: rect.minX, y: rect.minY),
                    endPoint: CGPoint(x: rect.maxX, y: rect.maxY)
                ),
                lineWidth: 1.5
            )

            // Specular sheen stripe across diagonal
            var sheenPath = Path()
            let sheenWidth: CGFloat = 30
            let sheenOffset = CGFloat(sin(time * 0.8)) * (rect.width * 0.4)
            sheenPath.move(to: CGPoint(x: rect.midX - sheenWidth + sheenOffset, y: rect.minY))
            sheenPath.addLine(to: CGPoint(x: rect.midX + sheenWidth + sheenOffset, y: rect.minY))
            sheenPath.addLine(to: CGPoint(x: rect.midX - sheenWidth - 40 + sheenOffset, y: rect.maxY))
            sheenPath.addLine(to: CGPoint(x: rect.midX + sheenWidth - 40 + sheenOffset, y: rect.maxY))
            sheenPath.closeSubpath()

            var sheenCtx = context
            sheenCtx.clip(to: glassPath)
            sheenCtx.fill(sheenPath, with: .color(Color.white.opacity(0.12)))

        case .holographicHUD:
            // Holographic Telemetry HUD Grid & Cybernetic Crosshairs
            context.stroke(
                Path(roundedRect: rect, cornerRadius: 10),
                with: .color(pColor.opacity(0.65)),
                lineWidth: 1.0
            )

            // Grid lines
            let step: CGFloat = 40.0
            var x = rect.minX + step
            while x < rect.maxX {
                var line = Path()
                line.move(to: CGPoint(x: x, y: rect.minY))
                line.addLine(to: CGPoint(x: x, y: rect.maxY))
                context.stroke(line, with: .color(pColor.opacity(0.15)), lineWidth: 0.5)
                x += step
            }
            var y = rect.minY + step
            while y < rect.maxY {
                var line = Path()
                line.move(to: CGPoint(x: rect.minX, y: y))
                line.addLine(to: CGPoint(x: rect.maxX, y: y))
                context.stroke(line, with: .color(pColor.opacity(0.15)), lineWidth: 0.5)
                y += step
            }

            // Central Crosshair & Circular HUD gauge
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let radius: CGFloat = min(rect.width, rect.height) * 0.22
            let circleRect = CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2)
            context.stroke(Path(ellipseIn: circleRect), with: .color(pColor.opacity(0.75)), lineWidth: 1.2)

            // Rotating HUD ticks
            let tickCount = 12
            for i in 0..<tickCount {
                let angle = Double(i) * (2.0 * .pi / Double(tickCount)) + time * 0.5
                let x1 = center.x + CGFloat(cos(angle)) * (radius - 6)
                let y1 = center.y + CGFloat(sin(angle)) * (radius - 6)
                let x2 = center.x + CGFloat(cos(angle)) * (radius + 4)
                let y2 = center.y + CGFloat(sin(angle)) * (radius + 4)
                var tick = Path()
                tick.move(to: CGPoint(x: x1, y: y1))
                tick.addLine(to: CGPoint(x: x2, y: y2))
                context.stroke(tick, with: .color(sColor.opacity(0.85)), lineWidth: 1.5)
            }

        case .omniMenu:
            // Top Grand Horizon MenuBar Dock
            let barPath = Path(roundedRect: rect, cornerRadius: 8)
            context.fill(barPath, with: .color(Color(hex: "#0A0A10")?.opacity(0.95) ?? Color.black.opacity(0.9)))
            context.stroke(barPath, with: .color(Color.cyan.opacity(0.35)), lineWidth: 0.8)

            // Apple Logo Icon & App Indicators
            let appleIconRect = CGRect(x: rect.minX + 12, y: rect.minY + (rect.height - 14) / 2, width: 14, height: 14)
            context.fill(Path(ellipseIn: appleIconRect), with: .color(.cyan))

            // Menu Items Pill
            let pillCount = 4
            let pillW: CGFloat = 60
            for i in 0..<pillCount {
                let pillX = rect.minX + 38 + CGFloat(i) * (pillW + 6)
                let pillRect = CGRect(x: pillX, y: rect.minY + 4, width: pillW, height: rect.height - 8)
                context.fill(Path(roundedRect: pillRect, cornerRadius: 4), with: .color(Color.white.opacity(0.08)))
            }

            // Right side status tray
            let trayW: CGFloat = 100
            let trayRect = CGRect(x: rect.maxX - trayW - 12, y: rect.minY + 4, width: trayW, height: rect.height - 8)
            context.fill(Path(roundedRect: trayRect, cornerRadius: 4), with: .color(Color.cyan.opacity(0.15)))
            context.stroke(Path(roundedRect: trayRect, cornerRadius: 4), with: .color(Color.cyan.opacity(0.4)), lineWidth: 0.6)

        case .proceduralShader:
            // Procedural Plasma / Waveform FX
            let count = 32
            let stepW = rect.width / CGFloat(count)
            for i in 0..<count {
                let waveH = CGFloat(sin(Double(i) * 0.35 + time * 2.0)) * (rect.height * 0.35) + (rect.height * 0.5)
                let barX = rect.minX + CGFloat(i) * stepW
                let barRect = CGRect(x: barX, y: rect.midY - waveH / 2, width: stepW * 0.7, height: waveH)
                context.fill(Path(roundedRect: barRect, cornerRadius: 2), with: .color(pColor.opacity(0.7)))
            }

        case .vectorGraphic:
            // Geometric Vector Emblem
            let center = CGPoint(x: rect.midX, y: rect.midY)
            let polyRadius = min(rect.width, rect.height) * 0.4
            var hexPath = Path()
            let sides = 6
            for i in 0..<sides {
                let angle = Double(i) * (2.0 * .pi / Double(sides)) - (.pi / 2)
                let pt = CGPoint(x: center.x + CGFloat(cos(angle)) * polyRadius, y: center.y + CGFloat(sin(angle)) * polyRadius)
                if i == 0 {
                    hexPath.move(to: pt)
                } else {
                    hexPath.addLine(to: pt)
                }
            }
            hexPath.closeSubpath()
            context.fill(hexPath, with: .linearGradient(Gradient(colors: [pColor, sColor]), startPoint: CGPoint(x: rect.minX, y: rect.minY), endPoint: CGPoint(x: rect.maxX, y: rect.maxY)))
            context.stroke(hexPath, with: .color(Color.white.opacity(0.9)), lineWidth: 2.0)

        case .textTypography:
            // Render stylized text placeholder box
            let bgPath = Path(roundedRect: rect, cornerRadius: 6)
            context.fill(bgPath, with: .color(Color.black.opacity(0.4)))
            context.stroke(bgPath, with: .color(pColor.opacity(0.6)), lineWidth: 1.0)

        case .imageAsset:
            // Bitmap placeholder
            let path = Path(roundedRect: rect, cornerRadius: 8)
            context.fill(path, with: .color(Color.gray.opacity(0.3)))
            context.stroke(path, with: .color(Color.white.opacity(0.2)), lineWidth: 1.0)
        }
    }

    // MARK: - 📸 CoreGraphics Bitmap Compositing & Export

    public func renderToImage(size: CGSize) -> NSImage? {
        guard size.width > 0, size.height > 0 else { return nil }

        let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(size.width),
            pixelsHigh: Int(size.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .calibratedRGB,
            bytesPerRow: 0,
            bitsPerPixel: 32
        )

        guard let rep = rep, let context = NSGraphicsContext(bitmapImageRep: rep) else { return nil }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context

        let cgContext = context.cgContext
        cgContext.clear(CGRect(origin: .zero, size: size))

        for layer in stack.layers {
            guard layer.isVisible, layer.opacity > 0.001 else { continue }

            cgContext.saveGState()
            cgContext.setAlpha(CGFloat(layer.opacity))
            cgContext.setBlendMode(layer.blendMode.cgBlendMode)

            let layerRect = CGRect(
                x: layer.frameNormalized.origin.x * size.width,
                y: layer.frameNormalized.origin.y * size.height,
                width: layer.frameNormalized.size.width * size.width,
                height: layer.frameNormalized.size.height * size.height
            )

            // Simple CoreGraphics fill for export bitmap
            if let col = NSColor(hex: layer.primaryColorHex) {
                cgContext.setFillColor(col.cgColor)
                cgContext.fill(layerRect)
            }

            cgContext.restoreGState()
        }

        NSGraphicsContext.restoreGraphicsState()

        let image = NSImage(size: size)
        image.addRepresentation(rep)
        return image
    }
}

// MARK: - Color Hex Helpers

fileprivate extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let length = hexSanitized.count
        if length == 6 {
            let r = Double((rgb & 0xFF0000) >> 16) / 255.0
            let g = Double((rgb & 0x00FF00) >> 8) / 255.0
            let b = Double(rgb & 0x0000FF) / 255.0
            self.init(red: r, green: g, blue: b)
        } else if length == 8 {
            let r = Double((rgb & 0xFF000000) >> 24) / 255.0
            let g = Double((rgb & 0x00FF0000) >> 16) / 255.0
            let b = Double((rgb & 0x0000FF00) >> 8) / 255.0
            let a = Double(rgb & 0x000000FF) / 255.0
            self.init(red: r, green: g, blue: b, opacity: a)
        } else {
            return nil
        }
    }
}

fileprivate extension NSColor {
    convenience init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let length = hexSanitized.count
        if length == 6 {
            let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
            let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
            let b = CGFloat(rgb & 0x0000FF) / 255.0
            self.init(calibratedRed: r, green: g, blue: b, alpha: 1.0)
        } else if length == 8 {
            let r = CGFloat((rgb & 0xFF000000) >> 24) / 255.0
            let g = CGFloat((rgb & 0x00FF0000) >> 16) / 255.0
            let b = CGFloat((rgb & 0x0000FF00) >> 8) / 255.0
            let a = CGFloat(rgb & 0x000000FF) / 255.0
            self.init(calibratedRed: r, green: g, blue: b, alpha: a)
        } else {
            return nil
        }
    }
}
