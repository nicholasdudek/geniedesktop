//
//  ContinuousStationScrollEngine.swift
//  GoldGate
//
//  Production-ready continuous vertical canvas scroll physics engine:
//  1. 1:1 Direct live trackpad finger tracking with asymptotic rubber-banding.
//  2. Momentum coasting with fluid exponential decay (e^-γt).
//  3. Magnetic snap-to-station anchors (Zenith at -H, Horizon at 0, Nadir at +H)
//     driven by critically damped harmonic spring physics (response: 0.38, dampingFraction: 0.82).
//  4. Discrete mouse wheel notch interpolation with normalized acceleration curves and natural scrolling support.
//  5. Standalone Swift coordinator and NSViewRepresentable SwiftUI bridge.
//

import AppKit
import Combine
import Foundation
import QuartzCore
import SwiftUI

// MARK: - Canvas Station Coordinate & Geometry

/// The 3 distinct vertical spatial stations locking Chat, Desktop, and Applications
/// into a single seamless continuous vertical canvas.
public enum CanvasStation: Int, CaseIterable, Identifiable, Sendable {
    /// Zenith (Top Station): Dialogue Studio, AI Engines & Omni-Search (y = -H)
    case zenith = 0
    /// Horizon (Center Station): Clean Desktop, Live Files & Ambient Murals (y = 0)
    case horizon = 1
    /// Nadir (Bottom Station): Applications Atelier, Formations & Matrix (y = +H)
    case nadir = 2

    public var id: Int { rawValue }

    public var title: String {
        switch self {
        case .zenith: return "Zenith • Dialogue Studio"
        case .horizon: return "Horizon • Desktop Canvas"
        case .nadir: return "Nadir • Applications Atelier"
        }
    }

    public var badgeLabel: String? {
        switch self {
        case .zenith: return "Chat"
        case .horizon: return nil
        case .nadir: return "Apps"
        }
    }

    public var systemImageName: String {
        switch self {
        case .zenith: return "bubble.left.and.bubble.right.fill"
        case .horizon: return "macwindow"
        case .nadir: return "square.grid.3x3.fill"
        }
    }

    public var systemImage: String {
        systemImageName
    }

    public var shortTitle: String {
        switch self {
        case .zenith: return "Chat Studio"
        case .horizon: return "Desktop"
        case .nadir: return "Applications"
        }
    }

    public var themeColor: Color {
        switch self {
        case .zenith: return Color.cyan
        case .horizon: return Color.white
        case .nadir: return Color(red: 1.0, green: 0.55, blue: 0.15)
        }
    }

    /// Normalized vertical position (-1.0 for Zenith, 0.0 for Horizon, +1.0 for Nadir).
    public var normalizedPosition: CGFloat {
        switch self {
        case .zenith: return -1.0
        case .horizon: return 0.0
        case .nadir: return 1.0
        }
    }

    public var normalizedOffset: CGFloat {
        normalizedPosition
    }

    /// Target offset in points given station height H.
    /// Zenith (-1.0) -> -H, Horizon (0.0) -> 0, Nadir (+1.0) -> +H.
    public func targetOffset(forStationHeight height: CGFloat) -> CGFloat {
        return normalizedPosition * height
    }

    /// Nearest station for a given normalized progress in [-1.0, 1.0].
    public static func nearest(normalizedProgress: CGFloat) -> CanvasStation {
        if normalizedProgress < -0.5 {
            return .zenith
        } else if normalizedProgress > 0.5 {
            return .nadir
        } else {
            return .horizon
        }
    }

    /// Map from WorkspaceStation
    public init(from workspaceStation: WorkspaceStation) {
        switch workspaceStation {
        case .chat: self = .zenith
        case .desktop: self = .horizon
        case .applications: self = .nadir
        }
    }

    public init(workspaceStation: WorkspaceStation) {
        self.init(from: workspaceStation)
    }

    /// Map to WorkspaceStation
    public var workspaceStation: WorkspaceStation {
        switch self {
        case .zenith: return .chat
        case .horizon: return .desktop
        case .nadir: return .applications
        }
    }
}

// MARK: - Station Physics Parameters

/// Tuning parameters for the continuous inertial scroll engine.
public struct StationPhysicsParameters: Sendable, Equatable {
    /// Harmonic spring response period in seconds (default 0.38s).
    public var response: Double
    /// Harmonic spring damping ratio zeta (default 0.82 for snappy critically-damped feel).
    public var dampingFraction: Double
    /// Viscous drag decay coefficient gamma in s^-1 for exponential momentum decay e^(-gamma * t).
    public var fluidFrictionGamma: Double
    /// Rubber-band maximum overshoot ratio relative to station height (default 0.35).
    public var maxRubberBandRatio: Double
    /// Velocity threshold in pt/s to trigger directional snap on release (default 250 pt/s).
    public var flickVelocityThreshold: Double
    /// Base impulse velocity in pt/s per discrete mouse notch click (default 420 pt/s).
    public var notchBaseImpulse: Double
    /// Non-linear mouse acceleration power exponent (default 1.25).
    public var notchAccelExponent: Double
    /// Maximum coasting velocity clamp in pt/s (default 4500 pt/s).
    public var maxVelocity: Double
    /// Cutoff velocity in pt/s below which momentum transitions to magnetic snap (default 18 pt/s).
    public var snapTransitionVelocity: Double
    /// Position epsilon in pt for spring settling (default 0.15 pt).
    public var settlePositionEpsilon: Double
    /// Velocity epsilon in pt/s for spring settling (default 1.0 pt/s).
    public var settleVelocityEpsilon: Double

    public static let `default` = StationPhysicsParameters(
        response: 0.38,
        dampingFraction: 0.82,
        fluidFrictionGamma: 4.2,
        maxRubberBandRatio: 0.35,
        flickVelocityThreshold: 250.0,
        notchBaseImpulse: 420.0,
        notchAccelExponent: 1.25,
        maxVelocity: 4500.0,
        snapTransitionVelocity: 18.0,
        settlePositionEpsilon: 0.15,
        settleVelocityEpsilon: 1.0
    )

    public init(
        response: Double = 0.38,
        dampingFraction: Double = 0.82,
        fluidFrictionGamma: Double = 4.2,
        maxRubberBandRatio: Double = 0.35,
        flickVelocityThreshold: Double = 250.0,
        notchBaseImpulse: Double = 420.0,
        notchAccelExponent: Double = 1.25,
        maxVelocity: Double = 4500.0,
        snapTransitionVelocity: Double = 18.0,
        settlePositionEpsilon: Double = 0.15,
        settleVelocityEpsilon: Double = 1.0
    ) {
        self.response = response
        self.dampingFraction = dampingFraction
        self.fluidFrictionGamma = fluidFrictionGamma
        self.maxRubberBandRatio = maxRubberBandRatio
        self.flickVelocityThreshold = flickVelocityThreshold
        self.notchBaseImpulse = notchBaseImpulse
        self.notchAccelExponent = notchAccelExponent
        self.maxVelocity = maxVelocity
        self.snapTransitionVelocity = snapTransitionVelocity
        self.settlePositionEpsilon = settlePositionEpsilon
        self.settleVelocityEpsilon = settleVelocityEpsilon
    }

    /// Angular natural frequency: omega_n = 2 * pi / response.
    public var naturalFrequency: Double {
        return (2.0 * .pi) / max(0.001, response)
    }

    /// Damped natural frequency: omega_d = omega_n * sqrt(1 - zeta^2) (for zeta < 1.0).
    public var dampedFrequency: Double {
        let zeta = dampingFraction
        let wn = naturalFrequency
        if zeta < 1.0 {
            return wn * sqrt(1.0 - zeta * zeta)
        } else {
            return 0.0
        }
    }
}

// MARK: - Kinetic Interaction State

public enum KineticScrollState: Equatable, Sendable {
    case idle
    case trackingLiveFinger   // 1:1 Live finger translation during touch
    case coastingMomentum     // Exponential fluid drag glide
    case snappingMagnetic     // Critically damped spring driving towards anchor
}

// MARK: - Velocity Tracker Sample

private struct VelocitySample {
    let timestamp: TimeInterval
    let position: CGFloat
}

// MARK: - Continuous Station Scroll Engine

/// Main coordinator orchestrating continuous trackpad/mouse physics across 3 vertical stations.
@MainActor
public final class ContinuousStationScrollEngine: ObservableObject {
    public static let shared = ContinuousStationScrollEngine()

    // ── Observable Published States ──

    /// Current continuous vertical offset in points (-H = Zenith, 0 = Horizon, +H = Nadir).
    @Published public private(set) var currentOffset: CGFloat = 0.0

    /// Normalized continuous progress in [-1.0, 1.0] (with rubber-band overshoot).
    @Published public private(set) var normalizedProgress: CGFloat = 0.0

    /// Currently active or target station.
    @Published public private(set) var activeStation: CanvasStation = .horizon

    /// Current physics state.
    @Published public private(set) var kineticState: KineticScrollState = .idle

    /// Instantaneous velocity in pt/s (positive = moving towards Nadir/Apps, negative = moving towards Zenith/Chat).
    @Published public private(set) var currentVelocity: CGFloat = 0.0

    // ── Configuration ──

    public var parameters: StationPhysicsParameters = .default
    public var stationHeight: CGFloat = 900.0

    /// When true, sliding/rolling the mouse wheel down reveals the top screen (Zenith / Dialogue Studio).
    /// Defaults to true; user can reverse direction anytime via preferences.
    public var slideDownShowsTopStation: Bool {
        get {
            UserDefaults.standard.object(forKey: PrefKey.wheelSlideDownShowsTopStation) as? Bool ?? true
        }
        set {
            UserDefaults.standard.set(newValue, forKey: PrefKey.wheelSlideDownShowsTopStation)
        }
    }

    /// Explicit reverse toggle for wheel scrolling direction (up vs down).
    public var reverseWheelDirection: Bool {
        get {
            UserDefaults.standard.bool(forKey: PrefKey.reverseStationScrollWheelDirection)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: PrefKey.reverseStationScrollWheelDirection)
        }
    }

    // ── Callbacks ──

    public var onStationChanged: ((CanvasStation) -> Void)?
    public var onOffsetChanged: ((CGFloat) -> Void)?
    public var onSettle: ((CanvasStation) -> Void)?
    /// Analytical result of the most recent regenerative linear regression release calculation.
    public private(set) var lastRegressionFit: RegressionFitResult = .zero

    // ── Internal Physics State ──

    private var targetStation: CanvasStation = .horizon
    private var unconstrainedPosition: CGFloat = 0.0
    private var velocityHistory: [VelocitySample] = []
    private var displayLinkTimer: Timer?
    private var lastFrameTime: TimeInterval = 0.0
    private var isGestureActive: Bool = false
    private var lastNotchImpulseTime: TimeInterval = 0.0
    private var consecutiveNotchCount: Int = 0

    // MARK: - Initialization

    public init(stationHeight: CGFloat = 900.0, parameters: StationPhysicsParameters = .default) {
        self.stationHeight = stationHeight
        self.parameters = parameters
        self.currentOffset = 0.0
        self.normalizedProgress = 0.0
        self.activeStation = .horizon
        self.unconstrainedPosition = 0.0
    }

    deinit {
        displayLinkTimer?.invalidate()
    }

    // MARK: - Viewport Height Configuration

    public func setStationHeight(_ height: CGFloat) {
        guard height > 0 else { return }
        let oldHeight = self.stationHeight
        self.stationHeight = height
        if kineticState == .idle {
            self.currentOffset = activeStation.targetOffset(forStationHeight: height)
            self.unconstrainedPosition = self.currentOffset
            self.normalizedProgress = activeStation.normalizedOffset
        } else if oldHeight > 0 {
            // Scale offset proportionally
            let ratio = height / oldHeight
            self.currentOffset *= ratio
            self.unconstrainedPosition *= ratio
        }
    }

    // MARK: - Public Control API

    /// Smoothly snaps to the specified station using critically damped spring physics.
    public func snapTo(station: CanvasStation, animated: Bool = true, initialVelocity: CGFloat = 0.0) {
        targetStation = station
        if !animated {
            stopAnimation()
            currentVelocity = 0.0
            currentOffset = station.targetOffset(forStationHeight: stationHeight)
            unconstrainedPosition = currentOffset
            normalizedProgress = station.normalizedOffset
            kineticState = .idle
            if activeStation != station {
                activeStation = station
                notifyStationSettled(station)
            }
            return
        }

        kineticState = .snappingMagnetic
        currentVelocity = initialVelocity
        startPhysicsLoopIfNeeded()
    }

    /// Programmatically set immediate normalized offset.
    public func setDirectOffset(_ offset: CGFloat) {
        stopAnimation()
        currentVelocity = 0.0
        currentOffset = offset
        unconstrainedPosition = offset
        normalizedProgress = (stationHeight > 0) ? (offset / stationHeight) : 0.0
        let nearest = CanvasStation.nearest(normalizedProgress: normalizedProgress)
        if activeStation != nearest {
            activeStation = nearest
            onStationChanged?(nearest)
        }
        onOffsetChanged?(currentOffset)
    }

    // MARK: - 1. Live Trackpad Finger Tracking (1:1 Translation)

    /// Process raw NSEvent from trackpad or scroll wheel.
    public func handleScrollEvent(_ event: NSEvent) {
        let now = ProcessInfo.processInfo.systemUptime

        // Handle Discrete Mouse Wheel (Traditional Mouse)
        if !event.hasPreciseScrollingDeltas || event.momentumPhase.contains(.began) || (event.phase.isEmpty && event.momentumPhase.isEmpty) {
            guard UserDefaults.standard.bool(forKey: PrefKey.enableScrollWheelStationNavigation) else { return }
            handleDiscreteMouseWheel(event, timestamp: now)
            return
        }

        // Handle Trackpad Gestures with Precision Deltas
        if event.phase == .began {
            beginDirectTracking(timestamp: now)
        }

        if event.phase == .changed {
            // 1:1 Live Finger Following
            let rawDeltaY = event.scrollingDeltaY
            // AppKit Natural Scrolling:
            // When isDirectionInvertedFromDevice is true (Natural Scrolling ON):
            // - Pushing fingers UP gives negative deltaY.
            // - Pushing fingers DOWN gives positive deltaY.
            // Physical mapping:
            // Pushing fingers UP moves screen toward Zenith (Chat, -H offset).
            // Pushing fingers DOWN moves screen toward Nadir (Apps, +H offset).
            let translationDelta: CGFloat
            if event.isDirectionInvertedFromDevice {
                translationDelta = -rawDeltaY
            } else {
                translationDelta = rawDeltaY
            }

            applyDirectTrackingDelta(translationDelta, timestamp: now)
        }

        if event.phase == .ended || event.phase == .cancelled {
            endDirectTracking(timestamp: now)
        }

        // Catch momentum phases generated by macOS trackpad driver if we use our internal physics
        if !event.momentumPhase.isEmpty {
            if event.momentumPhase == .began && kineticState == .trackingLiveFinger {
                endDirectTracking(timestamp: now)
            }
        }
    }

    /// Begin 1:1 direct tracking session.
    public func beginDirectTracking(timestamp: TimeInterval) {
        stopAnimation()
        kineticState = .trackingLiveFinger
        isGestureActive = true
        velocityHistory.removeAll(keepingCapacity: true)
        unconstrainedPosition = currentOffset
        recordVelocitySample(position: currentOffset, timestamp: timestamp)
    }

    /// Apply live 1:1 delta with asymptotic rubber-banding beyond boundaries (<-H and >+H).
    public func applyDirectTrackingDelta(_ delta: CGFloat, timestamp: TimeInterval) {
        guard kineticState == .trackingLiveFinger else {
            beginDirectTracking(timestamp: timestamp)
            return
        }

        unconstrainedPosition += delta
        recordVelocitySample(position: unconstrainedPosition, timestamp: timestamp)

        // Asymptotic Rubber-Banding
        let minBound = -stationHeight  // Zenith (-H)
        let maxBound = stationHeight   // Nadir (+H)
        let maxOvershoot = stationHeight * CGFloat(parameters.maxRubberBandRatio)

        if unconstrainedPosition < minBound {
            let over = minBound - unconstrainedPosition
            currentOffset = minBound - maxOvershoot * tanh(over / maxOvershoot)
        } else if unconstrainedPosition > maxBound {
            let over = unconstrainedPosition - maxBound
            currentOffset = maxBound + maxOvershoot * tanh(over / maxOvershoot)
        } else {
            currentOffset = unconstrainedPosition
        }

        normalizedProgress = (stationHeight > 0) ? (currentOffset / stationHeight) : 0.0

        let nearest = CanvasStation.nearest(normalizedProgress: normalizedProgress)
        if activeStation != nearest {
            activeStation = nearest
            HapticFeedback.tick()
            onStationChanged?(nearest)
            DesktopWindowManager.shared.syncCurrentStation(
                fromPage: (nearest == .horizon ? 0 : 1),
                appDisplayStage: (nearest == .nadir ? .fullScreen : .hidden),
                isTopSearchBarPoppedDown: (nearest == .zenith)
            )
        }

        onOffsetChanged?(currentOffset)
    }

    /// Conclude 1:1 tracking and initiate momentum coasting or magnetic snapping.
    public func endDirectTracking(timestamp: TimeInterval) {
        guard isGestureActive else { return }
        isGestureActive = false

        // Compute release velocity via weighted regression over the last 100ms
        let computedVelocity = calculateReleaseVelocity(currentTimestamp: timestamp)
        currentVelocity = max(-CGFloat(parameters.maxVelocity), min(CGFloat(parameters.maxVelocity), computedVelocity))

        // Check if released in rubber-band zone
        let minBound = -stationHeight
        let maxBound = stationHeight

        if currentOffset < minBound {
            // Beyond Zenith -> Snap back to Zenith
            targetStation = .zenith
            kineticState = .snappingMagnetic
            startPhysicsLoopIfNeeded()
            return
        } else if currentOffset > maxBound {
            // Beyond Nadir -> Snap back to Nadir
            targetStation = .nadir
            kineticState = .snappingMagnetic
            startPhysicsLoopIfNeeded()
            return
        }

        // Inside bounds: Check if velocity warrants momentum coasting with intent validation
        let isIntentConfident = lastRegressionFit.rSquared >= 0.50 || abs(currentVelocity) > CGFloat(parameters.flickVelocityThreshold)
        if abs(currentVelocity) >= CGFloat(parameters.snapTransitionVelocity) && isIntentConfident {
            kineticState = .coastingMomentum
            // Intent-aware regenerative ballistic station projection
            let (_, regenDisplacement, _) = GenieRegenerativeLinearRegressionEngine.shared.projectBallisticDisplacement(
                velocity: currentVelocity,
                rSquared: lastRegressionFit.rSquared,
                gamma: Double(parameters.fluidFrictionGamma)
            )
            let projectedPosition = currentOffset + regenDisplacement
            let projectedProgress = (stationHeight > 0) ? (projectedPosition / stationHeight) : 0.0

            // Apply directional bias if flicking with intent
            if abs(currentVelocity) > CGFloat(parameters.flickVelocityThreshold) {
                if currentVelocity < 0 {
                    // Moving Upwards (towards Zenith)
                    if activeStation == .nadir {
                        targetStation = .horizon
                    } else {
                        targetStation = .zenith
                    }
                } else {
                    // Moving Downwards (towards Nadir)
                    if activeStation == .zenith {
                        targetStation = .horizon
                    } else {
                        targetStation = .nadir
                    }
                }
            } else {
                targetStation = CanvasStation.nearest(normalizedProgress: projectedProgress)
            }

            startPhysicsLoopIfNeeded()
        } else {
            // Low velocity or low-confidence erratic release: Magnetically snap to nearest station
            targetStation = CanvasStation.nearest(normalizedProgress: normalizedProgress)
            kineticState = .snappingMagnetic
            startPhysicsLoopIfNeeded()
        }
    }

    // MARK: - 2. Momentum Coasting & Kinetic Decay (e^-γt)

    private func stepMomentumCoasting(dt: CGFloat) {
        let gamma = CGFloat(parameters.fluidFrictionGamma)
        let decayFactor = exp(-gamma * dt)

        // Exact integration of v(t) = v0 * e^(-gamma * t)
        // dx = v0 * (1 - e^(-gamma * dt)) / gamma
        let displacement = currentVelocity * (1.0 - decayFactor) / gamma
        currentOffset += displacement
        unconstrainedPosition = currentOffset
        currentVelocity *= decayFactor

        normalizedProgress = (stationHeight > 0) ? (currentOffset / stationHeight) : 0.0

        // Boundary collision check
        let minBound = -stationHeight
        let maxBound = stationHeight

        if currentOffset <= minBound {
            currentOffset = minBound
            unconstrainedPosition = minBound
            targetStation = .zenith
            kineticState = .snappingMagnetic
            return
        } else if currentOffset >= maxBound {
            currentOffset = maxBound
            unconstrainedPosition = maxBound
            targetStation = .nadir
            kineticState = .snappingMagnetic
            return
        }

        let nearest = CanvasStation.nearest(normalizedProgress: normalizedProgress)
        if activeStation != nearest {
            activeStation = nearest
            HapticFeedback.tick()
            onStationChanged?(nearest)
            DesktopWindowManager.shared.syncCurrentStation(
                fromPage: (nearest == .horizon ? 0 : 1),
                appDisplayStage: (nearest == .nadir ? .fullScreen : .hidden),
                isTopSearchBarPoppedDown: (nearest == .zenith)
            )
        }

        onOffsetChanged?(currentOffset)

        // If speed drops below snap transition threshold, seamlessly engage magnetic spring
        if abs(currentVelocity) < CGFloat(parameters.snapTransitionVelocity) {
            kineticState = .snappingMagnetic
        }
    }

    // MARK: - 3. Magnetic Snap Springs (Critically Damped Harmonic ODE)

    /// Exact analytical integration of the 2nd order underdamped / critically-damped spring ODE:
    /// y''(t) + 2*zeta*omega_n*y'(t) + omega_n^2*(y(t) - y*) = 0
    private func stepMagneticSpring(dt: CGFloat) {
        let targetY = targetStation.targetOffset(forStationHeight: stationHeight)
        let x0 = currentOffset - targetY
        let v0 = currentVelocity

        let zeta = CGFloat(parameters.dampingFraction)
        let wn = CGFloat(parameters.naturalFrequency)
        let wd = CGFloat(parameters.dampedFrequency)

        let expDecay = exp(-zeta * wn * dt)

        let nextX: CGFloat
        let nextV: CGFloat

        if zeta < 0.999 && wd > 0.001 {
            // Underdamped Harmonic Oscillator (zeta < 1.0)
            let cosWd = cos(wd * dt)
            let sinWd = sin(wd * dt)
            let c1 = x0
            let c2 = (v0 + zeta * wn * x0) / wd

            nextX = expDecay * (c1 * cosWd + c2 * sinWd)
            nextV = expDecay * (v0 * cosWd - (c1 * wd + c2 * zeta * wn) * sinWd)
        } else {
            // Critically Damped (zeta ~ 1.0)
            let c1 = x0
            let c2 = v0 + wn * x0
            nextX = expDecay * (c1 + c2 * dt)
            nextV = expDecay * (v0 - c2 * wn * dt)
        }

        currentOffset = targetY + nextX
        unconstrainedPosition = currentOffset
        currentVelocity = nextV
        normalizedProgress = (stationHeight > 0) ? (currentOffset / stationHeight) : 0.0

        let nearest = CanvasStation.nearest(normalizedProgress: normalizedProgress)
        if activeStation != nearest {
            activeStation = nearest
            HapticFeedback.tick()
            onStationChanged?(nearest)
            DesktopWindowManager.shared.syncCurrentStation(
                fromPage: (nearest == .horizon ? 0 : 1),
                appDisplayStage: (nearest == .nadir ? .fullScreen : .hidden),
                isTopSearchBarPoppedDown: (nearest == .zenith)
            )
        }

        onOffsetChanged?(currentOffset)

        // Settle Check
        let posError = abs(currentOffset - targetY)
        let velMagnitude = abs(currentVelocity)

        if posError < CGFloat(parameters.settlePositionEpsilon) && velMagnitude < CGFloat(parameters.settleVelocityEpsilon) {
            // Settle exactly at target station anchor
            currentOffset = targetY
            unconstrainedPosition = targetY
            currentVelocity = 0.0
            normalizedProgress = targetStation.normalizedOffset
            kineticState = .idle
            stopAnimation()

            if activeStation != targetStation {
                activeStation = targetStation
            }
            notifyStationSettled(targetStation)
        }
    }

    private func notifyStationSettled(_ station: CanvasStation) {
        HapticFeedback.selection()
        onSettle?(station)
        DesktopWindowManager.shared.switchToStation(station.workspaceStation)
    }

    // MARK: - 4. Discrete Mouse Wheel Acceleration & Inversion Handling

    private func handleDiscreteMouseWheel(_ event: NSEvent, timestamp: TimeInterval) {
        let rawDeltaY = event.scrollingDeltaY
        guard abs(rawDeltaY) > 0.05 else { return }

        // Respect macOS natural scrolling inversion preference
        var direction: CGFloat
        if event.isDirectionInvertedFromDevice {
            direction = (rawDeltaY < 0) ? -1.0 : 1.0
        } else {
            direction = (rawDeltaY > 0) ? -1.0 : 1.0
        }

        // When slideDownShowsTopStation is active (default), rolling wheel DOWN shows Zenith (top screen).
        // The reverseWheelDirection toggle allows flipping this direction at any time.
        let shouldInvert = slideDownShowsTopStation != reverseWheelDirection
        if shouldInvert {
            direction = -direction
        }

        // Notch cadence booster: Consecutive rapid notches compound acceleration
        let timeSinceLastNotch = timestamp - lastNotchImpulseTime
        if timeSinceLastNotch < 0.28 {
            consecutiveNotchCount = min(6, consecutiveNotchCount + 1)
        } else {
            consecutiveNotchCount = 1
        }
        lastNotchImpulseTime = timestamp

        let multiplier = pow(CGFloat(consecutiveNotchCount), CGFloat(parameters.notchAccelExponent - 1.0))
        let impulseMagnitude = CGFloat(parameters.notchBaseImpulse) * multiplier
        let notchImpulse = direction * impulseMagnitude

        // Inject kinetic impulse into simulation
        currentVelocity += notchImpulse
        currentVelocity = max(-CGFloat(parameters.maxVelocity), min(CGFloat(parameters.maxVelocity), currentVelocity))

        // Determine destination station
        if direction < 0 {
            // Upwards impulse -> Move toward Zenith
            if activeStation == .nadir {
                targetStation = .horizon
            } else {
                targetStation = .zenith
            }
        } else {
            // Downwards impulse -> Move toward Nadir
            if activeStation == .zenith {
                targetStation = .horizon
            } else {
                targetStation = .nadir
            }
        }

        kineticState = .coastingMomentum
        startPhysicsLoopIfNeeded()
    }

    // MARK: - Physics Simulation Loop

    private func startPhysicsLoopIfNeeded() {
        guard displayLinkTimer == nil else { return }
        lastFrameTime = ProcessInfo.processInfo.systemUptime

        // 120 FPS high-precision physics stepping timer scheduled in common runloop modes
        displayLinkTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 120.0, repeats: true) { [weak self] timer in
            guard let self = self else {
                timer.invalidate()
                return
            }
            Task { @MainActor in
                self.tickPhysics()
            }
        }
        RunLoop.main.add(displayLinkTimer!, forMode: .common)
    }

    private func stopAnimation() {
        displayLinkTimer?.invalidate()
        displayLinkTimer = nil
    }

    private func tickPhysics() {
        let now = ProcessInfo.processInfo.systemUptime
        let dt = min(0.033, max(0.001, CGFloat(now - lastFrameTime)))
        lastFrameTime = now

        switch kineticState {
        case .idle, .trackingLiveFinger:
            stopAnimation()
        case .coastingMomentum:
            stepMomentumCoasting(dt: dt)
        case .snappingMagnetic:
            stepMagneticSpring(dt: dt)
        }
    }

    // MARK: - Velocity Tracker Calculations

    private func recordVelocitySample(position: CGFloat, timestamp: TimeInterval) {
        velocityHistory.append(VelocitySample(timestamp: timestamp, position: position))
        // Prune samples older than 120ms
        let cutoff = timestamp - 0.12
        velocityHistory.removeAll { $0.timestamp < cutoff }
    }

    private func calculateReleaseVelocity(currentTimestamp: TimeInterval) -> CGFloat {
        guard velocityHistory.count >= 2 else {
            self.lastRegressionFit = .zero
            return 0.0
        }
        let validSamples = velocityHistory
            .filter { currentTimestamp - $0.timestamp <= 0.12 }
            .map { KinematicSample(timestamp: $0.timestamp, position: $0.position) }

        guard validSamples.count >= 2 else {
            self.lastRegressionFit = .zero
            return 0.0
        }

        let fit = GenieRegenerativeLinearRegressionEngine.shared.fit(
            samples: validSamples,
            referenceTimestamp: currentTimestamp
        )
        self.lastRegressionFit = fit

        // If regression successfully fit with valid timeSpan, return intent-adjusted velocity;
        // otherwise fallback to instantaneous two-point delta.
        if fit.timeSpan > 0.002 && abs(fit.adjustedVelocity) > 0.001 {
            return fit.adjustedVelocity
        } else if let first = validSamples.first, let last = validSamples.last {
            let dt = CGFloat(last.timestamp - first.timestamp)
            guard dt > 0.005 else { return 0.0 }
            return (last.position - first.position) / dt
        }

        return 0.0
    }
}

// MARK: - SwiftUI Continuous Canvas Scroll Coordinator & Bridge

/// NSView that catches continuous scroll wheel events and forwards them with zero latency to the engine.
@MainActor
public final class ContinuousScrollCatcherView: NSView {
    public var engine: ContinuousStationScrollEngine = .shared

    public override func hitTest(_ point: NSPoint) -> NSView? {
        // Transparent to clicks so SwiftUI buttons underneath remain fully interactive
        return nil
    }

    public override func scrollWheel(with event: NSEvent) {
        engine.handleScrollEvent(event)
    }
}

/// SwiftUI Representable Bridge to attach the continuous scroll engine to any view hierarchy.
@MainActor
public struct ContinuousStationScrollBridge: NSViewRepresentable {
    @ObservedObject public var engine: ContinuousStationScrollEngine

    public init(engine: ContinuousStationScrollEngine) {
        self.engine = engine
    }

    public init() {
        self.engine = .shared
    }

    public func makeNSView(context: Context) -> ContinuousScrollCatcherView {
        let view = ContinuousScrollCatcherView()
        view.engine = engine
        return view
    }

    public func updateNSView(_ nsView: ContinuousScrollCatcherView, context: Context) {
        nsView.engine = engine
    }
}
