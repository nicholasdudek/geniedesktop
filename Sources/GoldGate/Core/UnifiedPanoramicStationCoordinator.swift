import AppKit
import Combine
import Foundation
import SwiftUI

// MARK: - Unified Panoramic Station Coordinator

/// Master coordinator managing the continuous vertical translation, parallax calculations,
/// momentum inertia physics, and station indicator synchronization for the unified 3-station single-page canvas.
@MainActor
public final class UnifiedPanoramicStationCoordinator: ObservableObject {
    public static let shared = UnifiedPanoramicStationCoordinator()

    // ── Continuous Viewport States ──

    /// Active snapped station
    @Published public private(set) var currentStation: CanvasStation = .horizon

    /// Continuous normalized vertical offset $[-1.0 \dots +1.0]$.
    /// -1.0 = Centered on Zenith (Chat)
    ///  0.0 = Centered on Horizon (Desktop)
    /// +1.0 = Centered on Nadir (Applications)
    @Published public var continuousOffset: CGFloat = 0.0

    /// Interactive drag translation in points (temporary drag accumulator)
    @Published public var interactiveDragOffset: CGFloat = 0.0

    /// Indicates whether the user is actively dragging or scrubbing the viewport
    @Published public var isInteracting: Bool = false

    /// Real-time parallax wallpaper scale factor $[1.00 \dots 1.08]$
    @Published public var parallaxWallpaperScale: CGFloat = 1.00

    /// Real-time parallax wallpaper blur radius $[0.0 \dots 12.0]$
    @Published public var parallaxWallpaperBlur: CGFloat = 0.0

    /// Real-time atmospheric backdrop darkening opacity $[0.0 \dots 0.40]$
    @Published public var atmosphericDarkeningOpacity: Double = 0.0

    /// Right-edge station slider hover state
    @Published public var isStationIndicatorHovered: Bool = false

    // ── Internal Physics & Event Handling ──
    private var cancellables = Set<AnyCancellable>()
    private var lastScrollEventTime: TimeInterval = 0.0
    private var scrollVelocityTracker: [CGFloat] = []
    private var animationTimer: Timer?

    // ── Dynamic Spring Configurations ──
    public static let stationSnapSpring = Animation.spring(response: 0.42, dampingFraction: 0.84, blendDuration: 0.1)
    public static let interactiveDragSpring = Animation.interactiveSpring(response: 0.28, dampingFraction: 0.86, blendDuration: 0.05)
    public static let fastGlideSpring = Animation.spring(response: 0.32, dampingFraction: 0.80, blendDuration: 0.08)

    private init() {
        setupObservers()
    }

    // MARK: - Observer Synchronization
    private func setupObservers() {
        // Synchronize with DesktopWindowManager station notifications
        NotificationCenter.default.publisher(for: NSNotification.Name("NexusSwitchToDesktopStation"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.scrollToStation(.horizon, animated: true)
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: NSNotification.Name("NexusSwitchToChatStation"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.scrollToStation(.zenith, animated: true)
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: NSNotification.Name("NexusSwitchToAppsStation"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.scrollToStation(.nadir, animated: true)
            }
            .store(in: &cancellables)

        // Observe global scroll events for fluid trackpad vertical gliding
        NotificationCenter.default.publisher(for: NSNotification.Name("NexusDesktopScrollWheel"))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notif in
                guard let self = self, let event = notif.object as? NSEvent else { return }
                self.handleTrackpadScrollEvent(event)
            }
            .store(in: &cancellables)
    }

    // MARK: - Viewport Offset Geometry

    /// Calculates the effective canvas translation in pixels for the given viewport height $H$.
    /// When continuousOffset is -1 (Zenith), translation is $+H$ (moves canvas down to reveal Zenith).
    /// When continuousOffset is 0 (Horizon), translation is $0$.
    /// When continuousOffset is +1 (Nadir), translation is $-H$ (moves canvas up to reveal Nadir).
    public func canvasTranslationY(screenHeight: CGFloat) -> CGFloat {
        let totalNormalized = continuousOffset + (screenHeight > 0 ? (interactiveDragOffset / screenHeight) : 0.0)
        let clamped = max(-1.15, min(1.15, totalNormalized)) // Elastic rubber-banding at edges
        return -clamped * screenHeight
    }

    /// Station card frame Y position in the continuous vertical plane relative to the canvas origin
    public func stationOriginY(for station: CanvasStation, screenHeight: CGFloat) -> CGFloat {
        switch station {
        case .zenith:
            return -screenHeight // Offset -H (Top)
        case .horizon:
            return 0.0           // Offset 0 (Center)
        case .nadir:
            return screenHeight  // Offset +H (Bottom)
        }
    }

    // MARK: - Parallax Scaling & Visual Effects

    /// Recalculates parallax depth transformations based on current continuous translation offset
    private func updateParallaxEffects() {
        let displacement = abs(continuousOffset) // 0.0 at Horizon, 1.0 at Zenith/Nadir
        let clampedDisplacement = max(0.0, min(1.0, displacement))

        // Parallax wallpaper scale: gently expands from 1.00x at Desktop up to 1.06x at Zenith / Nadir
        self.parallaxWallpaperScale = 1.00 + (clampedDisplacement * 0.06)

        // Parallax wallpaper blur: increases up to 8pt for focus at Zenith / Nadir
        self.parallaxWallpaperBlur = clampedDisplacement * 8.0

        // Atmospheric darkening: dims background wallpaper slightly when focused on Chat or Apps
        self.atmosphericDarkeningOpacity = Double(clampedDisplacement * 0.32)
    }

    // MARK: - Navigation & Fluid Station Gliding

    /// Transitions to the target station with smooth spring physics
    public func scrollToStation(_ station: CanvasStation, animated: Bool = true, haptic: Bool = true) {
        if haptic {
            HapticFeedback.selection()
        }

        self.currentStation = station
        self.isInteracting = false
        self.interactiveDragOffset = 0.0

        let targetNormalized = station.normalizedOffset

        if animated {
            withAnimation(Self.stationSnapSpring) {
                self.continuousOffset = targetNormalized
                self.updateParallaxEffects()
            }
        } else {
            self.continuousOffset = targetNormalized
            self.updateParallaxEffects()
        }

        // Keep DesktopWindowManager and DockTile in sync
        DesktopWindowManager.shared.currentStation = station.workspaceStation
        DesktopWindowManager.shared.updateDockTile(for: station.workspaceStation)
        if station == .horizon {
            DesktopWindowManager.shared.setPage(0)
        } else {
            DesktopWindowManager.shared.setPage(1)
        }
    }

    /// Cycles through the 3 stations in order (Zenith -> Horizon -> Nadir -> Zenith)
    public func cycleNextStation() {
        let next: CanvasStation
        switch currentStation {
        case .zenith: next = .horizon
        case .horizon: next = .nadir
        case .nadir: next = .zenith
        }
        scrollToStation(next, animated: true)
    }

    /// Cycles backwards through the 3 stations
    public func cyclePreviousStation() {
        let prev: CanvasStation
        switch currentStation {
        case .zenith: prev = .nadir
        case .horizon: prev = .zenith
        case .nadir: prev = .horizon
        }
        scrollToStation(prev, animated: true)
    }

    // MARK: - Interactive Continuous Dragging & Gesture Tracking

    public func onDragChanged(translationY: CGFloat, screenHeight: CGFloat) {
        guard screenHeight > 0 else { return }
        self.isInteracting = true
        self.interactiveDragOffset = translationY

        // Compute preview continuous offset with elastic edge resistance
        let deltaNormalized = -translationY / screenHeight
        let preview = currentStation.normalizedOffset + deltaNormalized

        // Rubber-band resistance past bounds
        let bounded: CGFloat
        if preview < -1.0 {
            let overscroll = -1.0 - preview
            bounded = -1.0 - (overscroll * 0.35)
        } else if preview > 1.0 {
            let overscroll = preview - 1.0
            bounded = 1.0 + (overscroll * 0.35)
        } else {
            bounded = preview
        }

        self.continuousOffset = bounded
        self.updateParallaxEffects()
    }

    public func onDragEnded(translationY: CGFloat, velocityY: CGFloat, screenHeight: CGFloat) {
        guard screenHeight > 0 else { return }
        self.isInteracting = false
        self.interactiveDragOffset = 0.0

        let effectiveOffset = continuousOffset

        // Velocity-assisted station decision (fast flick or drag threshold)
        let targetStation: CanvasStation
        if velocityY > 400.0 {
            // Strong downward swipe -> Zenith (Chat) or Horizon (Desktop)
            if effectiveOffset < 0.2 {
                targetStation = .zenith
            } else {
                targetStation = .horizon
            }
        } else if velocityY < -400.0 {
            // Strong upward swipe -> Nadir (Apps) or Horizon (Desktop)
            if effectiveOffset > -0.2 {
                targetStation = .nadir
            } else {
                targetStation = .horizon
            }
        } else {
            // Positional nearest snapping
            if effectiveOffset < -0.45 {
                targetStation = .zenith
            } else if effectiveOffset > 0.45 {
                targetStation = .nadir
            } else {
                targetStation = .horizon
            }
        }

        scrollToStation(targetStation, animated: true)
    }

    // MARK: - Trackpad Scroll Handling

    public func handleTrackpadScrollEvent(_ event: NSEvent) {
        let now = ProcessInfo.processInfo.systemUptime
        let factor: CGFloat = event.hasPreciseScrollingDeltas ? 1.0 : 16.0
        let deltaY = event.scrollingDeltaY * factor

        // Deliberate threshold to avoid accidental micro-scrolls
        guard abs(deltaY) > 2.5 else { return }
        guard now - lastScrollEventTime > 0.16 else { return }

        if deltaY > 8.0 {
            // Scrolling UP (Gesture moving fingers downward) -> Move viewport UP to Zenith (Chat)
            lastScrollEventTime = now
            if currentStation == .nadir {
                scrollToStation(.horizon, animated: true)
            } else if currentStation == .horizon {
                scrollToStation(.zenith, animated: true)
            }
        } else if deltaY < -8.0 {
            // Scrolling DOWN (Gesture moving fingers upward) -> Move viewport DOWN to Nadir (Apps)
            lastScrollEventTime = now
            if currentStation == .zenith {
                scrollToStation(.horizon, animated: true)
            } else if currentStation == .horizon {
                scrollToStation(.nadir, animated: true)
            }
        }
    }
}
