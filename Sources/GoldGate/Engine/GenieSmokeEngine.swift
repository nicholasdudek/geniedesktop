import AppKit
import SwiftUI

// MARK: - Smoke Origin & Style Types

public enum GenieSmokeOrigin {
    case topGlyph(xPercent: CGFloat)
    case dock
    case center
}

public struct GenieSmokeParticle: Identifiable {
    public let id = UUID()
    public var x: CGFloat
    public var y: CGFloat
    public var vx: CGFloat
    public var vy: CGFloat
    public var size: CGFloat
    public var targetSize: CGFloat
    public var rotation: Double
    public var rotSpeed: Double
    public var opacity: Double
    public var maxOpacity: Double
    public var age: Double
    public var lifespan: Double
    public var color: Color
    public var secondaryColor: Color
    public var isSparkle: Bool
    public var swirlPhase: Double
    public var swirlSpeed: Double
}

// MARK: - Genie Smoke Particle Engine

@MainActor
public final class GenieSmokeEngine: ObservableObject {
    public static let shared = GenieSmokeEngine()

    @Published public private(set) var particles: [GenieSmokeParticle] = []
    @Published public var isSummoning: Bool = false
    @Published public var animProgress: CGFloat = 1.0

    private var displayLinkTimer: Timer?
    private var lastTickTime: TimeInterval = 0

    private init() {}

    // MARK: - Color Palettes

    public static func colors(for style: String) -> (primary: Color, secondary: Color, ember: Color) {
        if style.contains("Gold") || style.contains("Vapor") {
            return (
                Color(red: 1.0, green: 0.82, blue: 0.25),
                Color(red: 0.95, green: 0.55, blue: 0.10),
                Color(red: 1.0, green: 0.95, blue: 0.70)
            )
        } else if style.contains("Purple") || style.contains("Cosmic") {
            return (
                Color(red: 0.65, green: 0.20, blue: 0.95),
                Color(red: 0.90, green: 0.15, blue: 0.65),
                Color(red: 0.80, green: 0.60, blue: 1.0)
            )
        } else if style.contains("Ethereal") || style.contains("White") {
            return (
                Color(red: 0.92, green: 0.95, blue: 1.0),
                Color(red: 0.70, green: 0.80, blue: 0.95),
                Color.white
            )
        } else if style.contains("Rainbow") {
            return (
                Color(hue: Double.random(in: 0...1), saturation: 0.85, brightness: 1.0),
                Color(hue: Double.random(in: 0...1), saturation: 0.75, brightness: 0.95),
                Color.white
            )
        } else {
            // Default: Mystical Cyan (Genie Aladdin Blue / Turquoise)
            return (
                Color(red: 0.0, green: 0.95, blue: 0.85),
                Color(red: 0.15, green: 0.55, blue: 1.0),
                Color(red: 0.60, green: 1.0, blue: 0.95)
            )
        }
    }

    // MARK: - Trigger Smoke Plume Burst

    public func triggerBurst(
        origin: GenieSmokeOrigin,
        bounds: CGSize,
        style: String = "Mystical Cyan 🧞‍♂️",
        count: Int = 34
    ) {
        guard bounds.width > 0, bounds.height > 0 else { return }

        let (primCol, secCol, emberCol) = Self.colors(for: style)

        let startX: CGFloat
        let startY: CGFloat
        let vyBase: CGFloat

        switch origin {
        case .topGlyph(let xPercent):
            startX = bounds.width * max(0.08, min(0.92, xPercent))
            startY = 4.0
            vyBase = 1.8 // Downward flow from top glyph
        case .dock:
            startX = bounds.width * 0.50
            startY = bounds.height - 8.0
            vyBase = -2.8 // Upward eruption from dock
        case .center:
            startX = bounds.width * 0.50
            startY = bounds.height * 0.50
            vyBase = -0.5
        }

        var newParticles: [GenieSmokeParticle] = []

        for i in 0..<count {
            let isSparkle = (i % 4 == 0)
            let angle = Double.random(in: 0...(2.0 * .pi))
            let speed = isSparkle ? CGFloat.random(in: 1.5...4.5) : CGFloat.random(in: 0.8...3.2)

            let spreadX = CGFloat(cos(angle)) * speed * 2.2
            let spreadY = (CGFloat(sin(angle)) * speed) + vyBase

            let initialSize: CGFloat = isSparkle ? CGFloat.random(in: 3.0...6.0) : CGFloat.random(in: 12.0...22.0)
            let targetSize: CGFloat = isSparkle ? initialSize * 1.5 : CGFloat.random(in: 40.0...85.0)

            let lifespan: Double = isSparkle ? Double.random(in: 0.45...0.90) : Double.random(in: 0.75...1.45)
            let maxOp: Double = isSparkle ? Double.random(in: 0.75...0.95) : Double.random(in: 0.38...0.68)

            let color = isSparkle ? emberCol : ((i % 2 == 0) ? primCol : secCol)

            let p = GenieSmokeParticle(
                x: startX + CGFloat.random(in: -12...12),
                y: startY + CGFloat.random(in: -6...6),
                vx: spreadX,
                vy: spreadY,
                size: initialSize,
                targetSize: targetSize,
                rotation: Double.random(in: 0...(2 * .pi)),
                rotSpeed: Double.random(in: -2.5...2.5),
                opacity: 0.05,
                maxOpacity: maxOp,
                age: 0,
                lifespan: lifespan,
                color: color,
                secondaryColor: secCol,
                isSparkle: isSparkle,
                swirlPhase: Double.random(in: 0...(2 * .pi)),
                swirlSpeed: Double.random(in: 2.0...5.0)
            )
            newParticles.append(p)
        }

        self.particles.append(contentsOf: newParticles)
        startEngineLoopIfNeeded()
    }

    // MARK: - Ambient Mist Emission

    public func emitAmbientMist(bounds: CGSize, style: String) {
        guard bounds.width > 0, bounds.height > 0 else { return }
        guard particles.count < 45 else { return }

        let (primCol, secCol, _) = Self.colors(for: style)

        let rx = CGFloat.random(in: 20...(bounds.width - 20))
        let ry = CGFloat.random(in: 10...40)

        let p = GenieSmokeParticle(
            x: rx,
            y: ry,
            vx: CGFloat.random(in: -0.6...0.6),
            vy: CGFloat.random(in: 0.3...1.0),
            size: CGFloat.random(in: 16...28),
            targetSize: CGFloat.random(in: 45...70),
            rotation: Double.random(in: 0...6.28),
            rotSpeed: Double.random(in: -1.2...1.2),
            opacity: 0.02,
            maxOpacity: Double.random(in: 0.18...0.30),
            age: 0,
            lifespan: Double.random(in: 1.2...2.2),
            color: primCol,
            secondaryColor: secCol,
            isSparkle: false,
            swirlPhase: Double.random(in: 0...6.28),
            swirlSpeed: 1.8
        )
        particles.append(p)
        startEngineLoopIfNeeded()
    }

    // MARK: - Simulation Tick

    public func update(dt: Double = 0.016) {
        var alive: [GenieSmokeParticle] = []
        alive.reserveCapacity(particles.count)

        for var p in particles {
            p.age += dt
            if p.age >= p.lifespan { continue }

            let progress = p.age / p.lifespan

            // Expand as smoke billows
            p.size = p.size + (p.targetSize - p.size) * CGFloat(dt * 2.8)

            // Swirling turbulence curl
            p.swirlPhase += p.swirlSpeed * dt
            let curlX = CGFloat(sin(p.swirlPhase)) * 0.85
            let curlY = CGFloat(cos(p.swirlPhase)) * 0.40

            // Apply velocity with atmospheric resistance
            p.x += (p.vx + curlX)
            p.y += (p.vy + curlY)
            p.vx *= 0.965
            p.vy *= 0.965

            // Spin
            p.rotation += p.rotSpeed * dt

            // Opacity curve: Fast rise, lingering plume, soft fade
            if progress < 0.22 {
                p.opacity = p.maxOpacity * (progress / 0.22)
            } else {
                let fade = 1.0 - ((progress - 0.22) / 0.78)
                p.opacity = p.maxOpacity * pow(fade, 1.4)
            }

            alive.append(p)
        }

        self.particles = alive

        if alive.isEmpty {
            stopEngineLoop()
        }
    }

    private func startEngineLoopIfNeeded() {
        guard displayLinkTimer == nil else { return }
        lastTickTime = ProcessInfo.processInfo.systemUptime
        displayLinkTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.update(dt: 1.0 / 60.0)
            }
        }
    }

    private func stopEngineLoop() {
        displayLinkTimer?.invalidate()
        displayLinkTimer = nil
    }
}

// MARK: - Genie Smoke Canvas Overlay View

public struct GenieSmokeOverlayView: View {
    @ObservedObject var engine: GenieSmokeEngine = .shared
    public let style: String
    public let bounds: CGSize

    public init(style: String = "Mystical Cyan 🧞‍♂️", bounds: CGSize) {
        self.style = style
        self.bounds = bounds
    }

    public var body: some View {
        Canvas { context, size in
            for p in engine.particles {
                guard p.opacity > 0.01 else { continue }

                if p.isSparkle {
                    drawSparkle(context: context, p: p)
                } else {
                    drawSmokePuff(context: context, p: p)
                }
            }
        }
        .allowsHitTesting(false)
    }

    private func drawSmokePuff(context: GraphicsContext, p: GenieSmokeParticle) {
        let half = p.size / 2.0
        let rect = CGRect(x: p.x - half, y: p.y - half, width: p.size, height: p.size)

        var ctx = context
        ctx.opacity = p.opacity
        ctx.translateBy(x: p.x, y: p.y)
        ctx.rotate(by: Angle(radians: p.rotation))
        ctx.translateBy(x: -p.x, y: -p.y)

        // Soft luminous radial plume
        let plumeGradient = Gradient(colors: [
            p.color.opacity(0.85),
            p.secondaryColor.opacity(0.45),
            p.color.opacity(0.0)
        ])

        ctx.fill(
            Path(ellipseIn: rect),
            with: .radialGradient(
                plumeGradient,
                center: CGPoint(x: p.x, y: p.y),
                startRadius: 0,
                endRadius: half
            )
        )

        // Secondary offset organic lobe
        let lobeHalf = half * 0.72
        let lobeRect = CGRect(x: p.x - lobeHalf + (half * 0.25), y: p.y - lobeHalf - (half * 0.15), width: lobeHalf * 2, height: lobeHalf * 2)
        ctx.fill(
            Path(ellipseIn: lobeRect),
            with: .radialGradient(
                plumeGradient,
                center: CGPoint(x: lobeRect.midX, y: lobeRect.midY),
                startRadius: 0,
                endRadius: lobeHalf
            )
        )
    }

    private func drawSparkle(context: GraphicsContext, p: GenieSmokeParticle) {
        let r = p.size * 0.9
        var starPath = Path()
        starPath.move(to: CGPoint(x: p.x, y: p.y - r))
        starPath.addQuadCurve(to: CGPoint(x: p.x + r, y: p.y), control: CGPoint(x: p.x + (r * 0.2), y: p.y - (r * 0.2)))
        starPath.addQuadCurve(to: CGPoint(x: p.x + r, y: p.y + r), control: CGPoint(x: p.x + (r * 0.2), y: p.y + (r * 0.2)))
        starPath.addQuadCurve(to: CGPoint(x: p.x - r, y: p.y + r), control: CGPoint(x: p.x - (r * 0.2), y: p.y + (r * 0.2)))
        starPath.addQuadCurve(to: CGPoint(x: p.x - r, y: p.y), control: CGPoint(x: p.x - (r * 0.2), y: p.y - (r * 0.2)))
        starPath.closeSubpath()

        var ctx = context
        ctx.opacity = p.opacity
        ctx.fill(starPath, with: .color(p.color))

        // Center bright gleam
        let coreRect = CGRect(x: p.x - 1.5, y: p.y - 1.5, width: 3.0, height: 3.0)
        ctx.fill(Path(ellipseIn: coreRect), with: .color(.white))
    }
}
