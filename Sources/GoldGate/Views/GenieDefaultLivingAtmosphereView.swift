import AppKit
import Foundation
import SwiftUI

// MARK: - 💧 Genie Default Living Atmosphere & Visual Effects Engine
/// Renders Apple 2028 Living Liquid Water caustics, OLED Blackout specular rims,
/// and Quantum Glass iridescent particle fields that load *by default* behind
/// the chat, editor, and workspaces.
public struct GenieDefaultLivingAtmosphereView: View {
    public var theme: GenieTheme = .defaultTheme
    public var isGenerating: Bool = false

    @State private var ripples: [Genie2028WaterRipple] = []

    public init(theme: GenieTheme = .defaultTheme, isGenerating: Bool = false) {
        self.theme = theme
        self.isGenerating = isGenerating
    }

    public var body: some View {
        TimelineView(.animation) { timeline in
            let elapsed = timeline.date.timeIntervalSinceReferenceDate
            ZStack {
                // 1. Deep Base Canvas Tint
                theme.backgroundTint
                    .edgesIgnoringSafeArea(.all)

                // 2. Liquid Glass Vibrancy Material
                VisualEffectBlur(
                    material: theme.isLightAppearance ? .headerView : .hudWindow,
                    blendingMode: .behindWindow,
                    state: .active
                )
                .opacity(theme.isLightAppearance ? 0.75 : 0.40)

                // 3. Theme-Specific Visual Effects Layer
                switch theme {
                case .apple2028LiquidWater:
                    liquidWaterCausticsLayer(time: elapsed)
                case .apple2028OledPillow:
                    oledBlackoutPillowLayer(time: elapsed)
                case .apple2028QuantumGlass:
                    quantumTitaniumGlassLayer(time: elapsed)
                case .apple2028FrostedLight:
                    frostedAlabasterLightLayer(time: elapsed)
                case .mysticalAurora:
                    mysticalAuroraLayer(time: elapsed)
                case .contemplativeOcean:
                    contemplativeOceanLayer(time: elapsed)
                case .energeticAmber:
                    energeticAmberLayer(time: elapsed)
                case .playfulEmerald:
                    playfulEmeraldLayer(time: elapsed)
                }

                // 4. Interactive Fluid Water Ripples
                ForEach(ripples) { rip in
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    theme.accentColor.opacity(rip.opacity * 0.8),
                                    theme.secondaryAccentColor.opacity(rip.opacity * 0.4),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                        .frame(width: rip.radius * 2, height: rip.radius * 2)
                        .position(rip.position)
                        .allowsHitTesting(false)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { loc in
                addRipple(at: loc)
            }
        }
    }

    // MARK: - 💧 1. Apple 2028 Living Liquid Water Caustics
    private func liquidWaterCausticsLayer(time: Double) -> some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height

            // Undulating Caustic Glow 1
            let x1 = w * 0.35 + CGFloat(sin(time * 0.7)) * (w * 0.18)
            let y1 = h * 0.30 + CGFloat(cos(time * 0.5)) * (h * 0.15)
            let rect1 = CGRect(x: x1 - 180, y: y1 - 180, width: 360, height: 360)
            context.fill(
                Path(ellipseIn: rect1),
                with: .radialGradient(
                    Gradient(colors: [
                        Color(red: 0.10, green: 0.85, blue: 0.95).opacity(0.18),
                        Color(red: 0.05, green: 0.45, blue: 0.85).opacity(0.06),
                        Color.clear
                    ]),
                    center: CGPoint(x: x1, y: y1),
                    startRadius: 10,
                    endRadius: 180
                )
            )

            // Undulating Caustic Glow 2
            let x2 = w * 0.70 + CGFloat(cos(time * 0.6)) * (w * 0.15)
            let y2 = h * 0.65 + CGFloat(sin(time * 0.8)) * (h * 0.18)
            let rect2 = CGRect(x: x2 - 220, y: y2 - 220, width: 440, height: 440)
            context.fill(
                Path(ellipseIn: rect2),
                with: .radialGradient(
                    Gradient(colors: [
                        Color(red: 0.20, green: 0.50, blue: 1.0).opacity(0.15),
                        Color(red: 0.10, green: 0.85, blue: 0.95).opacity(0.05),
                        Color.clear
                    ]),
                    center: CGPoint(x: x2, y: y2),
                    startRadius: 10,
                    endRadius: 220
                )
            )

            // Floating Light Droplets
            for i in 0..<7 {
                let fi = Double(i)
                let px = w * (0.15 + 0.12 * CGFloat(i)) + CGFloat(sin(time * 0.4 + fi * 1.3)) * 30
                let py = h * (0.25 + 0.09 * CGFloat(i)) + CGFloat(cos(time * 0.5 + fi * 0.9)) * 25
                let r: CGFloat = 3.5 + CGFloat(sin(time + fi)) * 1.5
                let dropRect = CGRect(x: px - r, y: py - r, width: r * 2, height: r * 2)
                context.fill(
                    Path(ellipseIn: dropRect),
                    with: .color(Color.white.opacity(0.25 + 0.15 * sin(time * 1.2 + fi)))
                )
            }
        }
    }

    // MARK: - ⏱️ 2. Apple 2028 OLED Blackout Pillow
    private func oledBlackoutPillowLayer(time: Double) -> some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height

            // Pure #000000 fill with subtle breathing specular rim at top and corners
            let specularGlow = 0.10 + 0.04 * sin(time * 0.8)
            let topRimRect = CGRect(x: 0, y: 0, width: w, height: 80)
            context.fill(
                Path(topRimRect),
                with: .linearGradient(
                    Gradient(colors: [
                        Color.white.opacity(specularGlow),
                        Color.white.opacity(specularGlow * 0.3),
                        Color.clear
                    ]),
                    startPoint: CGPoint(x: w * 0.5, y: 0),
                    endPoint: CGPoint(x: w * 0.5, y: 80)
                )
            )

            // Subtle dial accent in bottom-right corner
            let dialX = w - 90
            let dialY = h - 90
            let dialRect = CGRect(x: dialX - 60, y: dialY - 60, width: 120, height: 120)
            context.stroke(
                Path(ellipseIn: dialRect),
                with: .color(Color.white.opacity(0.06)),
                lineWidth: 1.0
            )
        }
    }

    // MARK: - ✨ 3. Apple 2028 Quantum Titanium Glass
    private func quantumTitaniumGlassLayer(time: Double) -> some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height

            // Cosmic Iridescent Violet/Cyan Wash
            let x = w * 0.5 + CGFloat(sin(time * 0.5)) * (w * 0.2)
            let y = h * 0.4 + CGFloat(cos(time * 0.6)) * (h * 0.15)
            let rect = CGRect(x: x - 260, y: y - 260, width: 520, height: 520)
            context.fill(
                Path(ellipseIn: rect),
                with: .radialGradient(
                    Gradient(colors: [
                        Color(red: 0.70, green: 0.35, blue: 1.0).opacity(0.18),
                        Color(red: 0.15, green: 0.85, blue: 0.95).opacity(0.08),
                        Color.clear
                    ]),
                    center: CGPoint(x: x, y: y),
                    startRadius: 20,
                    endRadius: 260
                )
            )

            // Quantum Starlight Sparkles
            for i in 0..<12 {
                let fi = Double(i)
                let px = fmod((w * 0.08 * CGFloat(i) + CGFloat(sin(time * 0.3 + fi)) * 40), w)
                let py = fmod((h * 0.10 * CGFloat(i) + CGFloat(cos(time * 0.4 + fi)) * 35), h)
                let sparkle = 0.20 + 0.25 * sin(time * 1.5 + fi * 2.1)
                if sparkle > 0.1 {
                    context.fill(
                        Path(ellipseIn: CGRect(x: px, y: py, width: 3, height: 3)),
                        with: .color(Color.white.opacity(sparkle))
                    )
                }
            }
        }
    }

    // MARK: - ☀️ 4. Apple 2028 Frosted Alabaster Light
    private func frostedAlabasterLightLayer(time: Double) -> some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height

            // Sunlit Warmth Diffuse Halo
            let x = w * 0.80 + CGFloat(sin(time * 0.4)) * 30
            let y = h * 0.15 + CGFloat(cos(time * 0.3)) * 25
            let rect = CGRect(x: x - 200, y: y - 200, width: 400, height: 400)
            context.fill(
                Path(ellipseIn: rect),
                with: .radialGradient(
                    Gradient(colors: [
                        Color.orange.opacity(0.12),
                        Color.yellow.opacity(0.06),
                        Color.clear
                    ]),
                    center: CGPoint(x: x, y: y),
                    startRadius: 10,
                    endRadius: 200
                )
            )
        }
    }

    // MARK: - 🌌 5. Mystical Aurora
    private func mysticalAuroraLayer(time: Double) -> some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let x = w * 0.5 + CGFloat(sin(time * 0.5)) * 60
            let y = h * 0.4 + CGFloat(cos(time * 0.4)) * 50
            let rect = CGRect(x: x - 240, y: y - 240, width: 480, height: 480)
            context.fill(
                Path(ellipseIn: rect),
                with: .radialGradient(
                    Gradient(colors: [
                        Color.purple.opacity(0.20),
                        Color.indigo.opacity(0.12),
                        Color.clear
                    ]),
                    center: CGPoint(x: x, y: y),
                    startRadius: 20,
                    endRadius: 240
                )
            )
        }
    }

    // MARK: - 🌊 6. Contemplative Ocean
    private func contemplativeOceanLayer(time: Double) -> some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let yOffset = CGFloat(sin(time * 0.5)) * 40
            let rect = CGRect(x: -50, y: h * 0.4 + yOffset, width: w + 100, height: h * 0.6)
            context.fill(
                Path(rect),
                with: .linearGradient(
                    Gradient(colors: [
                        Color.clear,
                        Color(red: 0.05, green: 0.25, blue: 0.60).opacity(0.16),
                        Color(red: 0.02, green: 0.12, blue: 0.35).opacity(0.25)
                    ]),
                    startPoint: CGPoint(x: w * 0.5, y: h * 0.4 + yOffset),
                    endPoint: CGPoint(x: w * 0.5, y: h)
                )
            )
        }
    }

    // MARK: - ⚡ 7. Energetic Amber
    private func energeticAmberLayer(time: Double) -> some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let x = w * 0.6 + CGFloat(sin(time * 0.8)) * 50
            let y = h * 0.35 + CGFloat(cos(time * 0.7)) * 40
            let rect = CGRect(x: x - 200, y: y - 200, width: 400, height: 400)
            context.fill(
                Path(ellipseIn: rect),
                with: .radialGradient(
                    Gradient(colors: [
                        Color.orange.opacity(0.18),
                        Color.red.opacity(0.08),
                        Color.clear
                    ]),
                    center: CGPoint(x: x, y: y),
                    startRadius: 10,
                    endRadius: 200
                )
            )
        }
    }

    // MARK: - 🌿 8. Playful Emerald
    private func playfulEmeraldLayer(time: Double) -> some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            let x = w * 0.4 + CGFloat(cos(time * 0.6)) * 45
            let y = h * 0.5 + CGFloat(sin(time * 0.5)) * 45
            let rect = CGRect(x: x - 210, y: y - 210, width: 420, height: 420)
            context.fill(
                Path(ellipseIn: rect),
                with: .radialGradient(
                    Gradient(colors: [
                        Color.green.opacity(0.18),
                        Color.mint.opacity(0.08),
                        Color.clear
                    ]),
                    center: CGPoint(x: x, y: y),
                    startRadius: 10,
                    endRadius: 210
                )
            )
        }
    }

    private func addRipple(at location: CGPoint) {
        let ripple = Genie2028WaterRipple(position: location, radius: 2, opacity: 0.85)
        ripples.append(ripple)

        withAnimation(.easeOut(duration: 0.80)) {
            if let idx = ripples.firstIndex(where: { $0.id == ripple.id }) {
                ripples[idx].radius = 120
                ripples[idx].opacity = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
            ripples.removeAll { $0.id == ripple.id }
        }
    }
}
