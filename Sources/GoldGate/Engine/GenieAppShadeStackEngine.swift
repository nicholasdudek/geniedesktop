import AppKit
import SwiftUI
import Combine

// MARK: - 🪟 Genie App Shade Stack
//
// Every running application is a "shade": a sheet of glass in a depth-ordered stack.
// Activating a shade brings it to full clarity; the shades in front of it turn
// translucent so the program underneath reads straight through them. One continuous
// axis controls how transparent the stack gets, so many apps compact into one view
// instead of fighting for screen area.
//
// Transparency is applied at the WindowServer compositor level via
// SkyLightWindowServerTransformBridge.setWindowAlpha, so it affects the real windows
// of other applications, not a picture of them.

public struct GenieAppShade: Identifiable, Equatable {
    public let id: pid_t
    public let name: String
    public let icon: NSImage?
    public let windowIDs: [CGWindowID]

    public static func == (lhs: GenieAppShade, rhs: GenieAppShade) -> Bool {
        lhs.id == rhs.id && lhs.windowIDs == rhs.windowIDs
    }
}

@MainActor
public final class GenieAppShadeStackEngine: ObservableObject {
    public static let shared = GenieAppShadeStackEngine()

    // MARK: Stack state

    @Published public private(set) var shades: [GenieAppShade] = []
    @Published public private(set) var isActive: Bool = false

    /// Index of the shade held at full clarity. Everything in front of it fades.
    @Published public var activeIndex: Int = 0 {
        didSet {
            guard activeIndex != oldValue else { return }
            applyShadeAlphas()
            HapticFeedback.selection()
        }
    }

    /// How see-through the stack is, 0 (solid, untouched desktop) to 1 (fully compacted).
    /// Tracks the finger continuously; never snaps.
    @Published public var clarity: Double = 0 {
        didSet {
            guard abs(clarity - oldValue) > 0.001 else { return }
            UserDefaults.standard.set(clarity, forKey: PrefKey.appShadeClarity)
            applyShadeAlphas()
        }
    }

    // MARK: Tuning

    /// A shade never fades past this, or it stops reading as a layer and just looks gone.
    private let minimumShadeAlpha: Double = 0.12
    /// Fade applied to the nearest shade in front of the active one at full clarity.
    private let baseFalloff: Double = 0.55
    /// Extra fade per additional layer of depth, capped so deep stacks stay legible.
    private let depthFalloff: Double = 0.15
    private let maximumCountedDepth: Int = 3

    /// CGWindowListCopyWindowInfo stalls the WindowServer watchdog if polled hard.
    private let refreshInterval: TimeInterval = 0.15
    private var lastRefresh: Date = .distantPast

    // MARK: Gesture accumulators

    private var horizontalAccumulator: CGFloat = 0
    /// Horizontal travel required to step one shade.
    private let shadeStepThreshold: CGFloat = 42
    /// Vertical travel that spans the whole clarity range.
    private let clarityTravel: CGFloat = 320

    // MARK: Monitors

    private var scrollMonitor: Any?
    private var localScrollMonitor: Any?
    private var swipeMonitor: Any?
    private var keyMonitor: Any?
    private var terminationObserver: NSObjectProtocol?

    private let bridge = SkyLightWindowServerTransformBridge.shared

    /// Every window this engine has dimmed, so deactivation can always put it back.
    private var touchedWindowIDs: Set<CGWindowID> = []

    private init() {
        let stored = UserDefaults.standard.double(forKey: PrefKey.appShadeClarity)
        clarity = stored > 0 ? min(1.0, stored) : 0.6

        // A crash or quit must never leave another app's windows stuck translucent.
        terminationObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main
        ) { _ in
            MainActor.assumeIsolated { GenieAppShadeStackEngine.shared.restoreAllShades() }
        }
    }

    // MARK: - Activation

    public func toggle() {
        isActive ? deactivate() : activate()
    }

    public func activate() {
        guard !isActive else { return }
        refreshShades(force: true)
        guard !shades.isEmpty else {
            statusMessage = "No application shades to stack"
            return
        }
        isActive = true
        UserDefaults.standard.set(true, forKey: PrefKey.appShadeStackEnabled)
        installMonitors()
        applyShadeAlphas()
        HapticFeedback.selection()
        statusMessage = "\(shades.count) app shades stacked"
    }

    public func deactivate() {
        guard isActive else { return }
        isActive = false
        UserDefaults.standard.set(false, forKey: PrefKey.appShadeStackEnabled)
        removeMonitors()
        restoreAllShades()
        statusMessage = "Shades cleared"
    }

    @Published public private(set) var statusMessage: String = ""

    // MARK: - Shade discovery

    /// Builds the depth-ordered stack. CGWindowListCopyWindowInfo already returns
    /// front-to-back, so the list is reversed to read bottom-to-top like a stack of glass.
    public func refreshShades(force: Bool = false) {
        if !force, Date().timeIntervalSince(lastRefresh) < refreshInterval { return }
        lastRefresh = Date()

        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let infoList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return
        }

        let myPid = ProcessInfo.processInfo.processIdentifier
        var windowsByPid: [pid_t: [CGWindowID]] = [:]
        var order: [pid_t] = []

        for dict in infoList {
            guard let layer = dict[kCGWindowLayer as String] as? Int, layer == 0 else { continue }
            guard let pid = dict[kCGWindowOwnerPID as String] as? pid_t, pid != myPid else { continue }
            guard let winId = dict[kCGWindowNumber as String] as? CGWindowID else { continue }

            let ownerName = dict[kCGWindowOwnerName as String] as? String ?? ""
            if ownerName.isEmpty || ownerName == "Dock" || ownerName == "Window Server" || ownerName == "Genie" {
                continue
            }

            guard let boundsDict = dict[kCGWindowBounds as String] as? [String: CGFloat],
                  let w = boundsDict["Width"], let h = boundsDict["Height"],
                  w > 120, h > 100 else { continue }

            if windowsByPid[pid] == nil { order.append(pid) }
            windowsByPid[pid, default: []].append(winId)
        }

        let running = NSWorkspace.shared.runningApplications
        let built: [GenieAppShade] = order.reversed().compactMap { pid in
            guard let ids = windowsByPid[pid], !ids.isEmpty else { return nil }
            let app = running.first { $0.processIdentifier == pid }
            return GenieAppShade(
                id: pid,
                name: app?.localizedName ?? "Application \(pid)",
                icon: app?.icon,
                windowIDs: ids
            )
        }

        guard built != shades else { return }

        // Keep the same app activated across refreshes rather than snapping to an index.
        let previouslyActive: pid_t? = shades.indices.contains(activeIndex) ? shades[activeIndex].id : nil
        shades = built
        if let previouslyActive, let moved = built.firstIndex(where: { $0.id == previouslyActive }) {
            activeIndex = moved
        } else {
            activeIndex = max(0, min(activeIndex, built.count - 1))
        }
        if isActive { applyShadeAlphas() }
    }

    // MARK: - Compositor alpha

    /// The active shade stays fully clear. Shades in front of it fade with depth so the
    /// active one reads through them; shades behind are already occluded, so they are
    /// left alone and stay crisp.
    public func alphaForShade(at index: Int) -> Double {
        guard index != activeIndex else { return 1.0 }
        let depth = index - activeIndex
        guard depth > 0 else { return 1.0 }
        let counted = Double(min(depth, maximumCountedDepth))
        let fade = clarity * (baseFalloff + depthFalloff * (counted - 1))
        return max(minimumShadeAlpha, 1.0 - fade)
    }

    /// Dimming a shade also stops it counting as an occluder, so the WindowServer marks
    /// the layers behind it visible again and those apps resume drawing. That is the point
    /// of the stack: the compositor works on every layer at once instead of on the thin
    /// front sliver it would otherwise be culled down to.
    private func applyShadeAlphas() {
        guard isActive else { return }
        for (index, shade) in shades.enumerated() {
            let alpha = Float(alphaForShade(at: index))
            for winId in shade.windowIDs {
                _ = bridge.setWindowAlpha(windowId: winId, alpha: alpha)
                touchedWindowIDs.insert(winId)
            }
        }
    }

    /// Puts every window this engine ever dimmed back to fully opaque.
    public func restoreAllShades() {
        for winId in touchedWindowIDs {
            _ = bridge.setWindowAlpha(windowId: winId, alpha: 1.0)
        }
        touchedWindowIDs.removeAll()
    }

    // MARK: - Shade navigation

    public func activateShade(at index: Int) {
        guard shades.indices.contains(index) else { return }
        activeIndex = index
    }

    public func stepShade(by delta: Int) {
        guard !shades.isEmpty else { return }
        let next = activeIndex + delta
        guard shades.indices.contains(next) else { return }
        activeIndex = next
    }

    /// Raises the active shade to the front of the real window stack.
    public func bringActiveShadeForward() {
        guard shades.indices.contains(activeIndex) else { return }
        let shade = shades[activeIndex]
        NSWorkspace.shared.runningApplications
            .first { $0.processIdentifier == shade.id }?
            .activate(options: [])
    }

    // MARK: - Gestures

    private func installMonitors() {
        // Horizontal travel walks the stack; vertical travel dials clarity continuously.
        if scrollMonitor == nil {
            scrollMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.scrollWheel]) { event in
                Task { @MainActor in
                    GenieAppShadeStackEngine.shared.handleScroll(event)
                }
            }
        }
        if localScrollMonitor == nil {
            localScrollMonitor = NSEvent.addLocalMonitorForEvents(matching: [.scrollWheel]) { event in
                GenieAppShadeStackEngine.shared.handleScroll(event)
                return event
            }
        }
        if swipeMonitor == nil {
            swipeMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.swipe]) { event in
                Task { @MainActor in
                    let dx = event.deltaX
                    guard dx != 0 else { return }
                    GenieAppShadeStackEngine.shared.stepShade(by: dx > 0 ? -1 : 1)
                }
            }
        }
        if keyMonitor == nil {
            keyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
                if event.keyCode == 53 { // Escape
                    GenieAppShadeStackEngine.shared.deactivate()
                    return nil
                }
                return event
            }
        }
    }

    private func removeMonitors() {
        if let m = scrollMonitor { NSEvent.removeMonitor(m); scrollMonitor = nil }
        if let m = localScrollMonitor { NSEvent.removeMonitor(m); localScrollMonitor = nil }
        if let m = swipeMonitor { NSEvent.removeMonitor(m); swipeMonitor = nil }
        if let m = keyMonitor { NSEvent.removeMonitor(m); keyMonitor = nil }
        horizontalAccumulator = 0
    }

    private func handleScroll(_ event: NSEvent) {
        guard isActive else { return }
        refreshShades()

        let dx = event.scrollingDeltaX
        let dy = event.scrollingDeltaY

        if abs(dx) > abs(dy) {
            horizontalAccumulator += dx
            while abs(horizontalAccumulator) >= shadeStepThreshold {
                let direction = horizontalAccumulator > 0 ? -1 : 1
                horizontalAccumulator += CGFloat(direction) * shadeStepThreshold
                stepShade(by: direction)
            }
        } else if dy != 0 {
            clarity = min(1.0, max(0.0, clarity + Double(dy / clarityTravel)))
        }

        if event.phase == .ended || event.momentumPhase == .ended {
            horizontalAccumulator = 0
        }
    }
}
