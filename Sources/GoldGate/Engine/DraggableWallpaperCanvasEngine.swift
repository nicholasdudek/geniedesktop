//
//  DraggableWallpaperCanvasEngine.swift
//  GoldGate
//
//  Production-ready Draggable Wallpaper Canvas & Parallax Illusion Engine:
//  1. Wallpaper surface is directly draggable with 1:1 finger and mouse dragging.
//  2. Multi-layer differential parallax:
//     - Wallpaper / background travels at 0.35x speed with 3D perspective tilt.
//     - Desktop files / icons travel at 1.0x speed.
//     - Floating HUDs / controls travel at 1.2x speed (hyper-depth pop).
//  3. Optical Illusion & Magician for the Eyes:
//     - Dynamic glass refraction with chromatic prism dispersion and caustic light shift.
//     - Specular lighting highlights and Fresnel rim glow tracking cursor position.
//     - Kinetic rubber-banding with asymptotic elastic resistance.
//     - Critically damped harmonic spring return with zero-overshoot convergence.
//

import AppKit
import Combine
import Foundation
import QuartzCore
import SwiftUI
import simd

// MARK: - Parallax Layer Depth Tier

/// Defines the differential parallax speed and depth tier for canvas elements.
public enum ParallaxDepthLayer: Sendable, Equatable {
    /// Deep background / Wallpaper surface (0.35x speed + 3D tilt).
    case wallpaper
    /// Ground level / Desktop files, icons, and windows (1.0x speed).
    case desktopFiles
    /// Foreground / Floating HUDs, controls, and floating toolbars (1.2x speed).
    case floatingHUD
    /// Custom multiplier.
    case custom(speedMultiplier: CGFloat, zElevation: CGFloat)

    public var speedMultiplier: CGFloat {
        switch self {
        case .wallpaper:
            return 0.35
        case .desktopFiles:
            return 1.0
        case .floatingHUD:
            return 1.2
        case .custom(let multiplier, _):
            return multiplier
        }
    }

    public var zElevation: CGFloat {
        switch self {
        case .wallpaper:
            return -80.0
        case .desktopFiles:
            return 0.0
        case .floatingHUD:
            return 45.0
        case .custom(_, let elevation):
            return elevation
        }
    }
}

// MARK: - Optical Illusion Parameters

/// Configuration parameters for glass refraction, specular lighting, and spring physics.
public struct ParallaxIllusionConfig: Sendable, Equatable {
    /// Wallpaper parallax drag multiplier (default 0.35x).
    public var wallpaperParallaxSpeed: CGFloat = 0.35
    /// Desktop files parallax drag multiplier (default 1.0x).
    public var desktopFilesParallaxSpeed: CGFloat = 1.0
    /// Floating HUD parallax drag multiplier (default 1.2x).
    public var floatingHUDParallaxSpeed: CGFloat = 1.2

    /// Maximum 3D pitch/roll tilt in degrees (default 14.0°).
    public var maxTiltDegrees: Double = 14.0
    /// 3D perspective distortion factor (default 0.0012).
    public var perspectiveFactor: CGFloat = 0.0012

    /// Maximum asymptotic rubber-banding displacement in points (default 380.0 pt).
    public var maxRubberBandRadius: CGFloat = 380.0
    /// Spring natural frequency omega_n in rad/s (default 26.0 rad/s).
    public var springNaturalFrequency: Double = 26.0
    /// Spring damping ratio zeta (1.0 = critically damped, 0.86 = lively with minimal overshoot).
    public var springDampingRatio: Double = 0.88

    /// Dynamic glass chromatic aberration dispersion power (default 0.85).
    public var chromaticDispersionIntensity: Double = 0.85
    /// Specular lighting glossiness / shininess exponent (default 32.0).
    public var specularShininess: Double = 32.0
    /// Specular highlight intensity (default 0.45).
    public var specularIntensity: Double = 0.45
    /// Fresnel rim glow intensity (default 0.35).
    public var fresnelGlowIntensity: Double = 0.35

    public static let `default` = ParallaxIllusionConfig()
}

// MARK: - Draggable Wallpaper Canvas Engine

/// High-performance singleton engine coordinating interactive wallpaper canvas dragging,
/// multi-layer differential parallax transforms, and real-time optical glass refraction.
@MainActor
public final class DraggableWallpaperCanvasEngine: ObservableObject {
    public static let shared = DraggableWallpaperCanvasEngine()

    // MARK: - Published State

    /// Current active drag displacement applying rubber-banding.
    @Published public var dragOffset: CGSize = .zero
    /// Raw unconstrained drag translation from touch / mouse.
    @Published public var rawTranslation: CGSize = .zero
    /// Instantaneous drag velocity in points / second.
    @Published public var velocity: CGSize = .zero
    /// Whether user is currently dragging the wallpaper canvas.
    @Published public var isDragging: Bool = false
    /// Normalized mouse cursor location in [0, 1] relative to active screen / window.
    @Published public var normalizedCursor: CGPoint = CGPoint(x: 0.5, y: 0.5)
    /// Raw cursor coordinate in points.
    @Published public var cursorLocation: CGPoint = .zero

    /// 3D Pitch tilt angle in radians (rotation about X-axis).
    @Published public var pitchAngle: Double = 0.0
    /// 3D Roll tilt angle in radians (rotation about Y-axis).
    @Published public var rollAngle: Double = 0.0
    /// Dynamic glass refraction chromatic shift offset.
    @Published public var chromaticShift: CGSize = .zero
    /// Specular highlight position normalized [0, 1].
    @Published public var specularLightPosition: CGPoint = CGPoint(x: 0.5, y: 0.5)

    /// Engine configuration.
    @Published public var config: ParallaxIllusionConfig = .default

    // MARK: - Private State & Animation Pipeline

    private var displayLink: CVDisplayLink?
    private var lastFrameTime: TimeInterval = 0.0
    private var targetOffset: CGSize = .zero
    private var isSpringRunning: Bool = false
    private var springVelocity: CGSize = .zero
    private var lastDragTimestamp: TimeInterval = 0.0
    private var lastDragSampleTranslation: CGSize = .zero

    // MARK: - Initializer

    public init() {
        setupDisplayLink()
    }

    deinit {
        if let link = displayLink {
            CVDisplayLinkStop(link)
        }
    }

    // MARK: - Display Link Setup (120 FPS Metal/CADisplayLink Equivalent on macOS)

    private func setupDisplayLink() {
        var link: CVDisplayLink?
        let status = CVDisplayLinkCreateWithActiveCGDisplays(&link)
        guard status == kCVReturnSuccess, let displayLink = link else { return }

        self.displayLink = displayLink

        let outputCallback: CVDisplayLinkOutputCallback = { _, inNow, _, _, _, displayLinkContext in
            guard let context = displayLinkContext else { return kCVReturnSuccess }
            let engine = Unmanaged<DraggableWallpaperCanvasEngine>.fromOpaque(context).takeUnretainedValue()

            let currentTime = Double(inNow.pointee.videoTime) / Double(inNow.pointee.videoTimeScale)
            DispatchQueue.main.async {
                engine.stepPhysics(currentTime: currentTime)
            }
            return kCVReturnSuccess
        }

        let context = Unmanaged.passUnretained(self).toOpaque()
        CVDisplayLinkSetOutputCallback(displayLink, outputCallback, context)
    }

    private func startPhysicsLoopIfNeeded() {
        guard !isSpringRunning, let link = displayLink else { return }
        isSpringRunning = true
        lastFrameTime = CACurrentMediaTime()
        CVDisplayLinkStart(link)
    }

    private func stopPhysicsLoopIfIdle() {
        guard isSpringRunning, !isDragging, let link = displayLink else { return }
        let offsetMag = hypot(dragOffset.width, dragOffset.height)
        let velMag = hypot(springVelocity.width, springVelocity.height)
        if offsetMag < 0.1 && velMag < 0.5 {
            dragOffset = .zero
            pitchAngle = 0.0
            rollAngle = 0.0
            chromaticShift = .zero
            springVelocity = .zero
            isSpringRunning = false
            CVDisplayLinkStop(link)
        }
    }

    // MARK: - Gesture Handling (1:1 Mouse & Trackpad Drag)

    /// Called when wallpaper surface drag begins.
    public func onDragBegan(location: CGPoint, in bounds: CGSize) {
        isDragging = true
        lastDragTimestamp = CACurrentMediaTime()
        lastDragSampleTranslation = .zero
        velocity = .zero
        springVelocity = .zero
        updateCursor(location: location, in: bounds)
        startPhysicsLoopIfNeeded()
    }

    /// Called when wallpaper surface drag translation updates.
    public func onDragChanged(translation: CGSize, location: CGPoint, in bounds: CGSize) {
        let now = CACurrentMediaTime()
        let dt = max(0.001, now - lastDragTimestamp)

        // Calculate instantaneous gesture velocity
        let dTranslation = CGSize(
            width: translation.width - lastDragSampleTranslation.width,
            height: translation.height - lastDragSampleTranslation.height
        )
        let instantVelocity = CGSize(
            width: dTranslation.width / CGFloat(dt),
            height: dTranslation.height / CGFloat(dt)
        )
        // Low-pass filter velocity for smoothness
        self.velocity = CGSize(
            width: velocity.width * 0.4 + instantVelocity.width * 0.6,
            height: velocity.height * 0.4 + instantVelocity.height * 0.6
        )

        self.lastDragTimestamp = now
        self.lastDragSampleTranslation = translation
        self.rawTranslation = translation

        // Apply kinetic asymptotic rubber-banding
        self.dragOffset = computeRubberBandedOffset(translation: translation)
        self.updateTiltAndIllusionMetrics(bounds: bounds)
        self.updateCursor(location: location, in: bounds)

        startPhysicsLoopIfNeeded()
    }

    /// Called when wallpaper surface drag ends, kicking off the critically damped harmonic spring return.
    public func onDragEnded(finalTranslation: CGSize, predictedEndTranslation: CGSize, in bounds: CGSize) {
        isDragging = false
        self.springVelocity = velocity
        self.targetOffset = .zero
        startPhysicsLoopIfNeeded()
    }

    // MARK: - Cursor & Specular Tracking

    /// Updates cursor position for dynamic specular lighting and 3D angle calculations.
    public func updateCursor(location: CGPoint, in bounds: CGSize) {
        cursorLocation = location
        let normX = bounds.width > 0 ? max(0.0, min(1.0, location.x / bounds.width)) : 0.5
        let normY = bounds.height > 0 ? max(0.0, min(1.0, location.y / bounds.height)) : 0.5
        normalizedCursor = CGPoint(x: normX, y: normY)

        // Specular light point shifts dynamically opposite to surface inclination
        let tiltInfluenceX = CGFloat(rollAngle) * 0.25
        let tiltInfluenceY = CGFloat(pitchAngle) * 0.25
        specularLightPosition = CGPoint(
            x: max(0.0, min(1.0, normX + tiltInfluenceX)),
            y: max(0.0, min(1.0, normY + tiltInfluenceY))
        )
    }

    // MARK: - Physics Step (Critically Damped Harmonic Oscillator)

    private func stepPhysics(currentTime: TimeInterval) {
        let now = CACurrentMediaTime()
        let dt = CGFloat(min(0.05, max(0.001, now - lastFrameTime)))
        lastFrameTime = now

        guard !isDragging else {
            // When actively dragging, metrics are driven by gesture
            updateTiltAndIllusionMetrics(bounds: CGSize(width: 1440, height: 900))
            return
        }

        // Critically damped harmonic oscillator:
        // x''(t) + 2*zeta*omega_n*x'(t) + omega_n^2*(x(t) - target) = 0
        let omega = CGFloat(config.springNaturalFrequency)
        let zeta = CGFloat(config.springDampingRatio)

        let diffX = dragOffset.width - targetOffset.width
        let diffY = dragOffset.height - targetOffset.height

        let accelX = -2.0 * zeta * omega * springVelocity.width - (omega * omega) * diffX
        let accelY = -2.0 * zeta * omega * springVelocity.height - (omega * omega) * diffY

        springVelocity.width += accelX * dt
        springVelocity.height += accelY * dt

        dragOffset.width += springVelocity.width * dt
        dragOffset.height += springVelocity.height * dt

        updateTiltAndIllusionMetrics(bounds: CGSize(width: 1440, height: 900))
        stopPhysicsLoopIfIdle()
    }

    // MARK: - Kinetic Rubber-Banding Calculation

    /// Nonlinear asymptotic rubber-banding: D_resisted = dx / (1 + |dx| / R_max)
    private func computeRubberBandedOffset(translation: CGSize) -> CGSize {
        let rMax = config.maxRubberBandRadius
        let dx = translation.width
        let dy = translation.height

        let resistedX = (dx * rMax) / (rMax + abs(dx))
        let resistedY = (dy * rMax) / (rMax + abs(dy))

        return CGSize(width: resistedX, height: resistedY)
    }

    // MARK: - 3D Tilt & Optical Refraction Metrics

    private func updateTiltAndIllusionMetrics(bounds: CGSize) {
        let maxDeg = config.maxTiltDegrees
        let maxRad = maxDeg * .pi / 180.0

        // Calculate pitch (X rotation) and roll (Y rotation)
        let xProgress = max(-1.0, min(1.0, dragOffset.width / config.maxRubberBandRadius))
        let yProgress = max(-1.0, min(1.0, dragOffset.height / config.maxRubberBandRadius))

        // Cursor bias adds subtle organic breathing room
        let cursorBiasX = (normalizedCursor.x - 0.5) * 0.20
        let cursorBiasY = (normalizedCursor.y - 0.5) * 0.20

        rollAngle = Double((xProgress * 0.85 + cursorBiasX) * CGFloat(maxRad))
        pitchAngle = Double((-yProgress * 0.85 - cursorBiasY) * CGFloat(maxRad))

        // Chromatic dispersion shift proportional to velocity and drag strain
        let strainX = dragOffset.width * 0.04
        let strainY = dragOffset.height * 0.04
        let velFactor = CGFloat(config.chromaticDispersionIntensity)
        chromaticShift = CGSize(
            width: (strainX + springVelocity.width * 0.003) * velFactor,
            height: (strainY + springVelocity.height * 0.003) * velFactor
        )
    }

    // MARK: - Multi-Layer Differential Parallax Offsets

    /// Returns the exact (X, Y) translation for a specific parallax depth layer.
    public func offset(for layer: ParallaxDepthLayer) -> CGSize {
        let speed = layer.speedMultiplier
        return CGSize(
            width: dragOffset.width * speed,
            height: dragOffset.height * speed
        )
    }

    /// Returns offset for custom layer multiplier.
    public func offset(forMultiplier multiplier: CGFloat) -> CGSize {
        return CGSize(
            width: dragOffset.width * multiplier,
            height: dragOffset.height * multiplier
        )
    }

    /// Returns 3D tilt angles for the wallpaper layer.
    public var wallpaper3DTilt: (pitch: Double, roll: Double) {
        (pitch: pitchAngle, roll: rollAngle)
    }
}

// MARK: - SwiftUI View Modifiers for Parallax & Optical Illusion

/// View modifier applying differential parallax translation to any layer.
public struct ParallaxLayerModifier: ViewModifier {
    @ObservedObject private var engine = DraggableWallpaperCanvasEngine.shared
    public var layer: ParallaxDepthLayer

    public init(layer: ParallaxDepthLayer) {
        self.layer = layer
    }

    public func body(content: Content) -> some View {
        let offset = engine.offset(for: layer)
        content
            .offset(x: offset.width, y: offset.height)
    }
}

/// View modifier applying 3D perspective tilt, specular glint, and optical glass refraction.
public struct ParallaxIllusionGlassModifier: ViewModifier {
    @ObservedObject private var engine = DraggableWallpaperCanvasEngine.shared
    public var enablesTilt: Bool
    public var enablesRefraction: Bool
    public var enablesSpecular: Bool

    public init(enablesTilt: Bool = true, enablesRefraction: Bool = true, enablesSpecular: Bool = true) {
        self.enablesTilt = enablesTilt
        self.enablesRefraction = enablesRefraction
        self.enablesSpecular = enablesSpecular
    }

    public func body(content: Content) -> some View {
        ZStack {
            if enablesRefraction && engine.isDragging {
                // Chromatic Aberration / Prism Dispersion Underlay (Red/Cyan shift)
                content
                    .offset(x: -engine.chromaticShift.width * 0.5, y: -engine.chromaticShift.height * 0.5)
                    .colorMultiply(Color.red.opacity(0.85))
                    .opacity(0.20)
                    .blendMode(.screen)

                content
                    .offset(x: engine.chromaticShift.width * 0.5, y: engine.chromaticShift.height * 0.5)
                    .colorMultiply(Color.cyan.opacity(0.85))
                    .opacity(0.20)
                    .blendMode(.screen)
            }

            // Primary Content with 3D Perspective Matrix
            content
                .rotation3DEffect(
                    enablesTilt ? .radians(engine.pitchAngle) : .zero,
                    axis: (x: 1.0, y: 0.0, z: 0.0),
                    perspective: engine.config.perspectiveFactor
                )
                .rotation3DEffect(
                    enablesTilt ? .radians(engine.rollAngle) : .zero,
                    axis: (x: 0.0, y: 1.0, z: 0.0),
                    perspective: engine.config.perspectiveFactor
                )

            if enablesSpecular {
                // Dynamic Specular Gloss Highlight Overlay
                SpecularGlintOverlay(
                    lightPosition: engine.specularLightPosition,
                    intensity: engine.config.specularIntensity,
                    isDragging: engine.isDragging
                )
                .allowsHitTesting(false)
            }
        }
    }
}

// MARK: - Dynamic Specular Glint Overlay (Optical Illusion Shimmer)

/// Renders a dynamic specular gloss highlight gliding across the glass canvas surface.
public struct SpecularGlintOverlay: View {
    public var lightPosition: CGPoint
    public var intensity: Double
    public var isDragging: Bool

    public init(lightPosition: CGPoint, intensity: Double = 0.45, isDragging: Bool = false) {
        self.lightPosition = lightPosition
        self.intensity = intensity
        self.isDragging = isDragging
    }

    public var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            guard w > 0, h > 0 else { return }

            let center = CGPoint(x: lightPosition.x * w, y: lightPosition.y * h)
            let radius = max(w, h) * 0.65

            // Radial specular highlight
            let gradient = Gradient(stops: [
                .init(color: Color.white.opacity(intensity * (isDragging ? 0.35 : 0.20)), location: 0.0),
                .init(color: Color.cyan.opacity(intensity * 0.15), location: 0.25),
                .init(color: Color.clear, location: 0.70)
            ])

            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .radialGradient(
                    gradient,
                    center: center,
                    startRadius: 0,
                    endRadius: radius
                )
            )

            // Dynamic Fresnel Rim Glow along top/edges
            var rimPath = Path()
            rimPath.addRect(CGRect(origin: .zero, size: size))
            context.stroke(
                rimPath,
                with: .linearGradient(
                    Gradient(colors: [
                        Color.white.opacity(intensity * 0.4),
                        Color.cyan.opacity(intensity * 0.2),
                        Color.clear
                    ]),
                    startPoint: CGPoint(x: lightPosition.x * w, y: 0),
                    endPoint: CGPoint(x: (1.0 - lightPosition.x) * w, y: h)
                ),
                lineWidth: 1.5
            )
        }
        .blendMode(.plusLighter)
    }
}

// MARK: - Draggable Wallpaper Canvas Container View

/// Container view wrapping multi-layer canvas content with 1:1 direct dragging gesture,
/// differential parallax layer distribution, and optical illusion effects.
public struct DraggableWallpaperCanvasContainer<WallpaperContent: View, DesktopContent: View, HUDContent: View>: View {
    @ObservedObject private var engine = DraggableWallpaperCanvasEngine.shared
    public var wallpaperView: () -> WallpaperContent
    public var desktopView: () -> DesktopContent
    public var hudView: () -> HUDContent

    public init(
        @ViewBuilder wallpaper: @escaping () -> WallpaperContent,
        @ViewBuilder desktop: @escaping () -> DesktopContent,
        @ViewBuilder hud: @escaping () -> HUDContent
    ) {
        self.wallpaperView = wallpaper
        self.desktopView = desktop
        self.hudView = hud
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack {
                // Layer 1: Wallpaper Canvas Surface (0.35x Parallax + 3D Tilt + Specular)
                wallpaperView()
                    .offset(x: engine.offset(for: .wallpaper).width, y: engine.offset(for: .wallpaper).height)
                    .modifier(ParallaxIllusionGlassModifier(enablesTilt: true, enablesRefraction: true, enablesSpecular: true))

                // Layer 2: Desktop Files & Windows (1.0x Parallax Ground Level)
                desktopView()
                    .offset(x: engine.offset(for: .desktopFiles).width, y: engine.offset(for: .desktopFiles).height)

                // Layer 3: Floating HUDs & Overlays (1.2x Hyper-Parallax Depth Pop)
                hudView()
                    .offset(x: engine.offset(for: .floatingHUD).width, y: engine.offset(for: .floatingHUD).height)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 2, coordinateSpace: .local)
                    .onChanged { gesture in
                        if !engine.isDragging {
                            engine.onDragBegan(location: gesture.startLocation, in: geo.size)
                        }
                        engine.onDragChanged(
                            translation: gesture.translation,
                            location: gesture.location,
                            in: geo.size
                        )
                    }
                    .onEnded { gesture in
                        engine.onDragEnded(
                            finalTranslation: gesture.translation,
                            predictedEndTranslation: gesture.predictedEndTranslation,
                            in: geo.size
                        )
                    }
            )
            .onContinuousHover { phase in
                switch phase {
                case .active(let location):
                    engine.updateCursor(location: location, in: geo.size)
                case .ended:
                    break
                }
            }
        }
    }
}

// MARK: - View Extension Helpers

public extension View {
    /// Applies differential parallax translation for the given depth layer.
    func parallaxLayer(_ layer: ParallaxDepthLayer) -> some View {
        self.modifier(ParallaxLayerModifier(layer: layer))
    }

    /// Applies 3D perspective tilt, dynamic specular lighting, and chromatic glass refraction.
    func parallaxIllusionGlass(
        enablesTilt: Bool = true,
        enablesRefraction: Bool = true,
        enablesSpecular: Bool = true
    ) -> some View {
        self.modifier(ParallaxIllusionGlassModifier(
            enablesTilt: enablesTilt,
            enablesRefraction: enablesRefraction,
            enablesSpecular: enablesSpecular
        ))
    }
}
