import AppKit
import SwiftUI
import Combine

// MARK: - Global Cursor Trail Point Model

public struct GlobalCursorTrailPoint: Identifiable, Sendable {
    public let id: UUID
    public let globalPoint: CGPoint
    public let timestamp: TimeInterval

    public init(id: UUID = UUID(), globalPoint: CGPoint, timestamp: TimeInterval) {
        self.id = id
        self.globalPoint = globalPoint
        self.timestamp = timestamp
    }
}

// MARK: - Global Cursor FX Overlay Manager

/// Manages a zero-overhead, floating, non-activating transparent overlay panel
/// across all screens. Ensures mouse trailing cursor FX (Build 12 themes) remain
/// ALWAYS ON:
/// - In Desktop mode
/// - In Wallpaper & Applications page
/// - Even when Genie is NOT the active application (e.g. browsing in Safari, Xcode, Finder)
@MainActor
public final class GenieGlobalCursorFXOverlayManager: ObservableObject {
    public static let shared = GenieGlobalCursorFXOverlayManager()

    @Published public var cursorFxType: String = "None"
    @Published public var globalMouseLocation: CGPoint = .zero
    @Published public var trailPoints: [GlobalCursorTrailPoint] = []
    @Published public var isPaused: Bool = true

    public var isEnabled: Bool {
        cursorFxType != "None"
    }

    private var panels: [NSPanel] = []
    private var globalMouseMonitor: Any?
    private var localMouseMonitor: Any?
    private var idleCheckTimer: Timer?
    private var lastMouseMoveTime: TimeInterval = 0
    private var cancellables = Set<AnyCancellable>()

    private init() {
        // Load initial preference
        let savedType = UserDefaults.standard.string(forKey: PrefKey.cursorFxType) ?? "None"
        self.cursorFxType = savedType
        self.isPaused = (savedType == "None")
    }

    public func start() {
        // Watch for preference changes
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.syncFromPreferences()
            }
            .store(in: &cancellables)

        // Watch for display geometry changes (monitors plugged / unplugged)
        NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.rebuildPanels()
            }
            .store(in: &cancellables)

        syncFromPreferences()
    }

    public func stop() {
        teardownMonitors()
        for panel in panels {
            panel.orderOut(nil)
        }
        panels.removeAll()
        isPaused = true
    }

    public func setCursorFxType(_ type: String) {
        guard cursorFxType != type else { return }
        self.cursorFxType = type
        UserDefaults.standard.set(type, forKey: PrefKey.cursorFxType)
        applyActiveState()
    }

    private func syncFromPreferences() {
        let current = UserDefaults.standard.string(forKey: PrefKey.cursorFxType) ?? "None"
        if current != cursorFxType {
            cursorFxType = current
            applyActiveState()
        }
    }

    private func applyActiveState() {
        if cursorFxType == "None" {
            teardownMonitors()
            for panel in panels {
                panel.orderOut(nil)
            }
            trailPoints.removeAll()
            isPaused = true
        } else {
            if panels.isEmpty {
                rebuildPanels()
            }
            setupMonitors()
            for panel in panels {
                panel.orderFrontRegardless()
            }
            isPaused = false
            recordMouseMove(NSEvent.mouseLocation)
        }
    }

    private func setupMonitors() {
        if globalMouseMonitor == nil {
            globalMouseMonitor = NSEvent.addGlobalMonitorForEvents(
                matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged]
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.recordMouseMove(NSEvent.mouseLocation)
                }
            }
        }

        if localMouseMonitor == nil {
            localMouseMonitor = NSEvent.addLocalMonitorForEvents(
                matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged]
            ) { [weak self] event in
                self?.recordMouseMove(NSEvent.mouseLocation)
                return event
            }
        }

        if idleCheckTimer == nil {
            idleCheckTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.pruneStalePoints()
                }
            }
        }
    }

    private func teardownMonitors() {
        if let g = globalMouseMonitor {
            NSEvent.removeMonitor(g)
            globalMouseMonitor = nil
        }
        if let l = localMouseMonitor {
            NSEvent.removeMonitor(l)
            localMouseMonitor = nil
        }
        idleCheckTimer?.invalidate()
        idleCheckTimer = nil
    }

    private func recordMouseMove(_ mouseLoc: CGPoint) {
        guard cursorFxType != "None" else { return }
        let now = CACurrentMediaTime()
        self.globalMouseLocation = mouseLoc
        self.lastMouseMoveTime = now
        self.isPaused = false

        trailPoints.append(GlobalCursorTrailPoint(globalPoint: mouseLoc, timestamp: now))
        // Prune older than 0.48s
        trailPoints.removeAll(where: { now - $0.timestamp > 0.48 })
        if trailPoints.count > 48 {
            trailPoints.removeFirst(trailPoints.count - 48)
        }
    }

    private func pruneStalePoints() {
        guard cursorFxType != "None" else {
            if !isPaused { isPaused = true }
            return
        }
        let now = CACurrentMediaTime()
        trailPoints.removeAll(where: { now - $0.timestamp > 0.48 })
        if trailPoints.isEmpty && (now - lastMouseMoveTime > 0.55) {
            // Idle state: pause rendering to keep 0% CPU & GPU usage
            if !isPaused {
                isPaused = true
            }
        }
    }

    public func rebuildPanels() {
        for p in panels {
            p.orderOut(nil)
        }
        panels.removeAll()

        guard cursorFxType != "None" else { return }

        for screen in NSScreen.screens {
            let panel = NSPanel(
                contentRect: screen.frame,
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = false
            panel.ignoresMouseEvents = true
            // Status bar level floats above ordinary windows and full screen spaces
            panel.level = .statusBar
            panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
            panel.isExcludedFromWindowsMenu = true
            // Crucial: stays visible and active even when Genie is not frontmost
            panel.hidesOnDeactivate = false
            panel.sharingType = .none

            let rootView = GlobalCursorFXCanvasView(manager: self, screen: screen)
            let hosting = NSHostingView(rootView: rootView)
            hosting.frame = CGRect(origin: .zero, size: screen.frame.size)
            panel.contentView = hosting

            panel.orderFrontRegardless()
            panels.append(panel)
        }
    }

    // MARK: - Build 12 Universal Cursor FX Drawing Engine

    static func drawCursorFX(
        context: GraphicsContext,
        W: CGFloat,
        H: CGFloat,
        time: Double,
        type: String,
        mouse: CGPoint,
        trail: [CursorTrailPoint]
    ) {
        switch type {
        case "Ice Cream Cone & Sprinkles 🍦", "Ice Cream Cone 🍦":
            // 1. Waffle Cone Cursor Pointer
            var cone = Path()
            cone.move(to: CGPoint(x: mouse.x, y: mouse.y + 14))
            cone.addLine(to: CGPoint(x: mouse.x - 7, y: mouse.y + 2))
            cone.addLine(to: CGPoint(x: mouse.x + 7, y: mouse.y + 2))
            cone.closeSubpath()
            context.fill(cone, with: .color(Color(red: 0.88, green: 0.65, blue: 0.35)))
            context.stroke(cone, with: .color(Color(red: 0.68, green: 0.45, blue: 0.20)), lineWidth: 1.0)

            // Strawberry scoop on top
            let scoop = Path(ellipseIn: CGRect(x: mouse.x - 8, y: mouse.y - 7, width: 16, height: 12))
            context.fill(scoop, with: .color(Color(red: 1.0, green: 0.50, blue: 0.65)))

            // 2. Falling Rainbow Sprinkles Trail
            let sprinkleColors: [Color] = [
                Color.red, Color.yellow, Color.cyan, Color.green, Color.orange, Color.purple, Color.white
            ]
            for (idx, pt) in trail.enumerated() {
                let age = time - pt.timestamp
                let progress = 1.0 - (age / 0.48)
                if progress > 0 {
                    // Gravity fall and flutter
                    let fallY = CGFloat(age * age * 120.0 + age * 20.0)
                    let swayX = CGFloat(sin(time * 6.0 + Double(idx * 3))) * 5.0
                    let p = CGPoint(x: pt.point.x + swayX, y: pt.point.y + fallY)
                    let col = sprinkleColors[idx % sprinkleColors.count]

                    // Pill-shaped sprinkle capsule
                    var sprinkle = Path()
                    let angle = Double(idx * 45) * .pi / 180.0
                    let len: CGFloat = 6.0 * CGFloat(progress)
                    sprinkle.move(to: CGPoint(x: p.x - CGFloat(cos(angle)) * len, y: p.y - CGFloat(sin(angle)) * len))
                    sprinkle.addLine(to: CGPoint(x: p.x + CGFloat(cos(angle)) * len, y: p.y + CGFloat(sin(angle)) * len))
                    context.stroke(sprinkle, with: .color(col.opacity(Double(progress * 0.95))), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
                }
            }

        case "Cotton Candy Clouds 🍭":
            for (idx, pt) in trail.enumerated() {
                let age = time - pt.timestamp
                let progress = 1.0 - (age / 0.50)
                if progress > 0 {
                    let p = pt.point
                    let rad = CGFloat((Double(idx % 3) * 4.0 + 8.0) * progress)
                    let col = (idx % 2 == 0)
                        ? Color(red: 1.0, green: 0.60, blue: 0.80, opacity: progress * 0.55)
                        : Color(red: 0.50, green: 0.85, blue: 1.0, opacity: progress * 0.55)
                    let cloud = Path(ellipseIn: CGRect(x: p.x - rad, y: p.y - rad, width: rad * 2, height: rad * 2))
                    context.fill(cloud, with: .color(col))
                }
            }

        case "Stardust Sparkles ✨", "Stardust Tail":
            for (_, pt) in trail.enumerated() {
                let age = time - pt.timestamp
                let progress = 1.0 - (age / 0.40)
                if progress > 0 {
                    let p = pt.point
                    let radius = CGFloat(progress * 6.0 + 1.2)

                    // 4-point diamond star burst
                    var starPath = Path()
                    starPath.move(to: CGPoint(x: p.x, y: p.y - radius * 1.5))
                    starPath.addLine(to: CGPoint(x: p.x + radius * 0.4, y: p.y - radius * 0.4))
                    starPath.addLine(to: CGPoint(x: p.x + radius * 1.5, y: p.y))
                    starPath.addLine(to: CGPoint(x: p.x + radius * 0.4, y: p.y + radius * 0.4))
                    starPath.move(to: CGPoint(x: p.x, y: p.y + radius * 1.5))
                    starPath.addLine(to: CGPoint(x: p.x - radius * 0.4, y: p.y + radius * 0.4))
                    starPath.addLine(to: CGPoint(x: p.x - radius * 1.5, y: p.y))
                    starPath.addLine(to: CGPoint(x: p.x - radius * 0.4, y: p.y - radius * 0.4))
                    starPath.closeSubpath()

                    let goldColor = Color(red: 1.0, green: 0.88, blue: 0.35, opacity: progress * 0.85)
                    context.fill(starPath, with: .color(goldColor))

                    let core = Path(ellipseIn: CGRect(x: p.x - radius * 0.6, y: p.y - radius * 0.6, width: radius * 1.2, height: radius * 1.2))
                    context.fill(core, with: .color(Color.white.opacity(progress * 0.90)))
                }
            }

        case "Rainbow Nebula Comet 🌈":
            guard !trail.isEmpty else { return }
            var ribbon = Path()
            if let first = trail.first {
                ribbon.move(to: first.point)
                for pt in trail.dropFirst() { ribbon.addLine(to: pt.point) }
                ribbon.addLine(to: mouse)
            }
            context.stroke(
                ribbon,
                with: .linearGradient(
                    Gradient(colors: [
                        Color.red.opacity(0.1),
                        Color.orange.opacity(0.4),
                        Color.yellow.opacity(0.7),
                        Color.green.opacity(0.85),
                        Color.cyan,
                        Color.purple,
                        Color.white
                    ]),
                    startPoint: trail.first?.point ?? mouse,
                    endPoint: mouse
                ),
                style: StrokeStyle(lineWidth: 5.5, lineCap: .round, lineJoin: .round)
            )
            // Glowing comet head
            let headGlow = Path(ellipseIn: CGRect(x: mouse.x - 9, y: mouse.y - 9, width: 18, height: 18))
            context.fill(headGlow, with: .color(Color.white.opacity(0.95)))

        case "Cyber Neon Ribbon ⚡️", "Plasma Ribbon":
            guard !trail.isEmpty else { return }
            var ribbon = Path()
            if let first = trail.first {
                ribbon.move(to: first.point)
                for pt in trail.dropFirst() { ribbon.addLine(to: pt.point) }
                ribbon.addLine(to: mouse)
            }
            // Outer magenta aura
            context.stroke(
                ribbon,
                with: .linearGradient(Gradient(colors: [Color.purple.opacity(0.1), Color.pink.opacity(0.6), Color.cyan]), startPoint: trail.first?.point ?? mouse, endPoint: mouse),
                style: StrokeStyle(lineWidth: 6.0, lineCap: .round, lineJoin: .round)
            )
            // Inner crisp laser core
            context.stroke(
                ribbon,
                with: .linearGradient(Gradient(colors: [Color.clear, Color.cyan, Color.white]), startPoint: trail.first?.point ?? mouse, endPoint: mouse),
                style: StrokeStyle(lineWidth: 2.0, lineCap: .round, lineJoin: .round)
            )

        case "Fire Ember Sparks 🔥":
            for (idx, pt) in trail.enumerated() {
                let age = time - pt.timestamp
                let progress = 1.0 - (age / 0.45)
                if progress > 0 {
                    let driftY = CGFloat(age * 55.0)
                    let jitterX = CGFloat(sin(time * 12.0 + Double(idx) * 2.1)) * 6.0
                    let p = CGPoint(x: pt.point.x + jitterX, y: pt.point.y - driftY)
                    let rad = CGFloat(progress * 4.5 + 1.0)

                    let sparkColor = (idx % 3 == 0)
                        ? Color(red: 1.0, green: 0.3, blue: 0.05, opacity: progress * 0.9)
                        : ((idx % 3 == 1)
                            ? Color(red: 1.0, green: 0.7, blue: 0.1, opacity: progress * 0.85)
                            : Color(red: 1.0, green: 0.95, blue: 0.3, opacity: progress * 0.75))

                    let spark = Path(ellipseIn: CGRect(x: p.x - rad, y: p.y - rad, width: rad * 2, height: rad * 2))
                    context.fill(spark, with: .color(sparkColor))
                }
            }

        case "Deep Ocean Bubble Wake 🫧":
            for (idx, pt) in trail.enumerated() {
                let age = time - pt.timestamp
                let progress = 1.0 - (age / 0.50)
                if progress > 0 {
                    let floatY = CGFloat(age * 30.0)
                    let p = CGPoint(x: pt.point.x + CGFloat(sin(Double(idx) + time * 3.0)) * 4.0, y: pt.point.y - floatY)
                    let rad = CGFloat((Double(idx % 4) + 2.5) * progress)

                    // Translucent bubble body
                    let bubble = Path(ellipseIn: CGRect(x: p.x - rad, y: p.y - rad, width: rad * 2, height: rad * 2))
                    context.fill(bubble, with: .color(Color.cyan.opacity(progress * 0.30)))
                    context.stroke(bubble, with: .color(Color.white.opacity(progress * 0.80)), lineWidth: 1.0)

                    // Specular glint
                    let glint = Path(ellipseIn: CGRect(x: p.x - rad * 0.4, y: p.y - rad * 0.5, width: rad * 0.5, height: rad * 0.3))
                    context.fill(glint, with: .color(Color.white.opacity(progress * 0.95)))
                }
            }

        case "Electric Lightning Arc ⚡":
            if trail.count >= 2 {
                var lightning = Path()
                lightning.move(to: mouse)
                for (i, pt) in trail.enumerated() {
                    let midJitterX = CGFloat(sin(time * 30.0 + Double(i) * 5.0)) * 7.0
                    let midJitterY = CGFloat(cos(time * 30.0 + Double(i) * 5.0)) * 7.0
                    let midPt = CGPoint(x: (pt.point.x + mouse.x) / 2.0 + midJitterX, y: (pt.point.y + mouse.y) / 2.0 + midJitterY)
                    lightning.addLine(to: midPt)
                    lightning.addLine(to: pt.point)
                }
                context.stroke(lightning, with: .color(Color(red: 0.4, green: 0.8, blue: 1.0, opacity: 0.85)), lineWidth: 2.2)
                context.stroke(lightning, with: .color(Color.white.opacity(0.95)), lineWidth: 0.8)
            }

        case "Matrix Green Binary Stream 🟢":
            for (idx, pt) in trail.enumerated() {
                let age = time - pt.timestamp
                let progress = 1.0 - (age / 0.45)
                if progress > 0 {
                    let char = ((idx + Int(time * 10)) % 2 == 0) ? "1" : "0"
                    let p = pt.point
                    context.draw(
                        Text(char)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(red: 0.0, green: 1.0, blue: 0.35, opacity: progress * 0.90)),
                        at: p
                    )
                }
            }

        case "Golden Gate Bridge Shimmer 🌉":
            for (idx, pt) in trail.enumerated() {
                let age = time - pt.timestamp
                let progress = 1.0 - (age / 0.45)
                if progress > 0 {
                    let p = pt.point
                    let rad = CGFloat(progress * 5.0 + 1.5)
                    let color = (idx % 2 == 0)
                        ? Color(red: 0.95, green: 0.40, blue: 0.15, opacity: progress * 0.90)
                        : Color(red: 1.00, green: 0.85, blue: 0.30, opacity: progress * 0.85)

                    let diamond = Path(ellipseIn: CGRect(x: p.x - rad, y: p.y - rad, width: rad * 2, height: rad * 2))
                    context.fill(diamond, with: .color(color))

                    var ray = Path()
                    ray.move(to: CGPoint(x: p.x - rad * 2, y: p.y))
                    ray.addLine(to: CGPoint(x: p.x + rad * 2, y: p.y))
                    context.stroke(ray, with: .color(Color.white.opacity(progress * 0.70)), lineWidth: 0.8)
                }
            }

        case "Hyperdrive Warp Beams 🌌":
            for pt in trail {
                let age = time - pt.timestamp
                let progress = 1.0 - (age / 0.35)
                if progress > 0 {
                    var beam = Path()
                    beam.move(to: pt.point)
                    beam.addLine(to: mouse)
                    context.stroke(
                        beam,
                        with: .color(Color(red: 0.6, green: 0.4, blue: 1.0, opacity: progress * 0.65)),
                        style: StrokeStyle(lineWidth: CGFloat(progress * 3.5), lineCap: .round)
                    )
                }
            }

        case "Heart Petal Drift 🌸":
            for (idx, pt) in trail.enumerated() {
                let age = time - pt.timestamp
                let progress = 1.0 - (age / 0.50)
                if progress > 0 {
                    let driftX = CGFloat(sin(time * 3.0 + Double(idx))) * 10.0
                    let p = CGPoint(x: pt.point.x + driftX, y: pt.point.y + CGFloat(age * 25.0))
                    let petalRad: CGFloat = 5.0 * CGFloat(progress)
                    let petal = Path(ellipseIn: CGRect(x: p.x - petalRad, y: p.y - petalRad * 0.6, width: petalRad * 2, height: petalRad * 1.2))
                    context.fill(petal, with: .color(Color(red: 1.0, green: 0.65, blue: 0.80, opacity: progress * 0.85)))
                }
            }

        case "Pixel 8-Bit Arcade Blast 👾":
            for (idx, pt) in trail.enumerated() {
                let age = time - pt.timestamp
                let progress = 1.0 - (age / 0.40)
                if progress > 0 {
                    let p = pt.point
                    let size = CGFloat(progress * 6.0 + 2.0)
                    let colors: [Color] = [.yellow, .green, .cyan, .pink, .orange]
                    let col = colors[idx % colors.count]
                    let square = Path(CGRect(x: p.x - size / 2, y: p.y - size / 2, width: size, height: size))
                    context.fill(square, with: .color(col.opacity(progress * 0.90)))
                }
            }

        case "Cyber Ring & Target 🎯", "Cyber Ring":
            let ringRadius: CGFloat = 16.0 + 3.0 * CGFloat(sin(time * 6.0))
            let ring = Path(ellipseIn: CGRect(x: mouse.x - ringRadius, y: mouse.y - ringRadius, width: ringRadius * 2, height: ringRadius * 2))
            context.stroke(ring, with: .color(Color.cyan.opacity(0.85)), lineWidth: 1.5)

            var cross = Path()
            cross.move(to: CGPoint(x: mouse.x - ringRadius - 4, y: mouse.y))
            cross.addLine(to: CGPoint(x: mouse.x - ringRadius + 3, y: mouse.y))
            cross.move(to: CGPoint(x: mouse.x + ringRadius - 3, y: mouse.y))
            cross.addLine(to: CGPoint(x: mouse.x + ringRadius + 4, y: mouse.y))
            cross.move(to: CGPoint(x: mouse.x, y: mouse.y - ringRadius - 4))
            cross.addLine(to: CGPoint(x: mouse.x, y: mouse.y - ringRadius + 3))
            cross.move(to: CGPoint(x: mouse.x, y: mouse.y + ringRadius - 3))
            cross.addLine(to: CGPoint(x: mouse.x, y: mouse.y + ringRadius + 4))
            context.stroke(cross, with: .color(Color.white.opacity(0.9)), lineWidth: 1.2)

        case "Quantum Vortex 🌪️", "Quantum Vortex":
            for i in 0..<4 {
                let angle = time * 5.0 + (Double(i) * .pi / 2.0)
                let px = mouse.x + CGFloat(cos(angle)) * 20.0
                let py = mouse.y + CGFloat(sin(angle)) * 20.0
                let dot = Path(ellipseIn: CGRect(x: px - 3, y: py - 3, width: 6, height: 6))
                context.fill(dot, with: .color(Color.mint.opacity(0.85)))

                var fluxLine = Path()
                fluxLine.move(to: mouse)
                fluxLine.addLine(to: CGPoint(x: px, y: py))
                context.stroke(fluxLine, with: .color(Color.cyan.opacity(0.35)), lineWidth: 0.8)
            }

        default:
            break
        }
    }
}

// MARK: - Global Cursor FX Canvas View

struct GlobalCursorFXCanvasView: View {
    @ObservedObject var manager: GenieGlobalCursorFXOverlayManager
    @ObservedObject private var governor = GenieResourceGovernor.shared
    let screen: NSScreen

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 120.0, paused: manager.isPaused || manager.cursorFxType == "None" || governor.isYieldingResources)) { timeline in
            Canvas { context, size in
                guard manager.cursorFxType != "None", !governor.isYieldingResources else { return }
                let time = timeline.date.timeIntervalSinceReferenceDate
                let screenFrame = screen.frame

                // Map global Cocoa mouse location (bottom-left origin) to screen-local top-left Canvas
                let localMouseX = manager.globalMouseLocation.x - screenFrame.minX
                let localMouseY = screenFrame.maxY - manager.globalMouseLocation.y
                let mouseLocal = CGPoint(x: localMouseX, y: localMouseY)

                // Map trail points
                let localTrail: [CursorTrailPoint] = manager.trailPoints.map { pt in
                    let px = pt.globalPoint.x - screenFrame.minX
                    let py = screenFrame.maxY - pt.globalPoint.y
                    return CursorTrailPoint(point: CGPoint(x: px, y: py), timestamp: pt.timestamp)
                }

                GenieGlobalCursorFXOverlayManager.drawCursorFX(
                    context: context,
                    W: size.width,
                    H: size.height,
                    time: time,
                    type: manager.cursorFxType,
                    mouse: mouseLocal,
                    trail: localTrail
                )
            }
        }
        .frame(width: screen.frame.width, height: screen.frame.height)
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}
