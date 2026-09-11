import AppKit
import SwiftUI

// MARK: - 💧 2028 Apple Liquid Glass & Water Caustic Engine
// Implements futuristic 2028 Apple living water aesthetics:
// - Realistic wave caustics and fluid surface ripples
// - Liquid glass refractive borders with chromatic aberration highlights
// - Interactive water droplets and ripple rings on hover/click

public struct Genie2028WaterRipple: Identifiable {
    public let id: UUID = UUID()
    public var position: CGPoint
    public var radius: CGFloat = 0
    public var opacity: Double = 0.85
}

// MARK: - ⚙️ 2028 Animated Liquid Water Settings Icon
public struct Genie2028LiquidSettingsIcon: View {
    @State private var rotation: Double = 0
    @State private var fluidPhase: Double = 0
    @State private var isHovered: Bool = false
    @State private var ripples: [Genie2028WaterRipple] = []

    public var size: CGFloat = 26
    public var isActive: Bool = false
    public var action: (() -> Void)? = nil

    public init(size: CGFloat = 26, isActive: Bool = false, action: (() -> Void)? = nil) {
        self.size = size
        self.isActive = isActive
        self.action = action
    }

    public var body: some View {
        Button(action: {
            triggerWaterSplash()
            action?()
        }) {
            ZStack {
                // 1. Water Ripple Expansions
                ForEach(ripples) { rip in
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.cyan.opacity(rip.opacity * 0.9),
                                    Color.blue.opacity(rip.opacity * 0.5),
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

                // 2. 2028 Liquid Caustic Backdrop Glass Circle
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                (isActive ? Color.cyan.opacity(0.35) : (isHovered ? Color.cyan.opacity(0.22) : Color.white.opacity(0.08))),
                                (isActive ? Color.blue.opacity(0.25) : Color.black.opacity(0.35))
                            ],
                            center: .center,
                            startRadius: 2,
                            endRadius: size * 0.75
                        )
                    )
                    .frame(width: size, height: size)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(isActive ? 0.70 : (isHovered ? 0.50 : 0.25)),
                                        Color.cyan.opacity(isActive ? 0.80 : 0.30),
                                        Color.blue.opacity(0.20),
                                        Color.white.opacity(0.40)
                                    ],
                                    startPoint: UnitPoint(x: 0.2 + 0.3 * cos(fluidPhase), y: 0.2 + 0.3 * sin(fluidPhase)),
                                    endPoint: UnitPoint(x: 0.8 - 0.3 * cos(fluidPhase), y: 0.8 - 0.3 * sin(fluidPhase))
                                ),
                                lineWidth: 1.0
                            )
                    )

                // 3. Fluid Undulating Water Ring
                Circle()
                    .strokeBorder(
                        AngularGradient(
                            gradient: Gradient(colors: [
                                .cyan,
                                .blue.opacity(0.8),
                                .purple.opacity(0.6),
                                .teal,
                                .cyan
                            ]),
                            center: .center,
                            angle: .degrees(fluidPhase * 60)
                        ),
                        lineWidth: 1.2
                    )
                    .frame(width: size - 3, height: size - 3)
                    .opacity(isActive || isHovered ? 0.90 : 0.45)
                    .scaleEffect(1.0 + 0.04 * sin(fluidPhase * 2))

                // 4. Animated Rotating Liquid Glass Gear
                Image(systemName: "gearshape.fill")
                    .font(.system(size: size * 0.44, weight: .bold))
                    .foregroundColor(isActive ? Color.cyan : (isHovered ? Color.white : Color.white.opacity(0.85)))
                    .rotationEffect(.degrees(rotation))
                    .shadow(color: Color.cyan.opacity(isActive ? 0.6 : (isHovered ? 0.4 : 0.1)), radius: 4, x: 0, y: 0)

                // 5. Specular Water Droplet Glint
                Circle()
                    .fill(Color.white.opacity(0.85))
                    .frame(width: 2.2, height: 2.2)
                    .offset(x: -size * 0.24, y: -size * 0.24)
                    .blur(radius: 0.3)
            }
            .frame(width: size + 8, height: size + 8)
            .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .onHover { inside in
            withAnimation(.spring(response: 0.30, dampingFraction: 0.75)) {
                isHovered = inside
            }
            if inside {
                triggerWaterSplash()
                withAnimation(.linear(duration: 4.0).repeatForever(autoreverses: false)) {
                    rotation += 360
                }
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: false)) {
                fluidPhase = .pi * 2
            }
        }
    }

    private func triggerWaterSplash() {
        let center = CGPoint(x: (size + 8) / 2, y: (size + 8) / 2)
        let newRipple = Genie2028WaterRipple(position: center, radius: 2, opacity: 0.9)
        ripples.append(newRipple)

        withAnimation(.easeOut(duration: 0.65)) {
            if let idx = ripples.firstIndex(where: { $0.id == newRipple.id }) {
                ripples[idx].radius = size * 0.95
                ripples[idx].opacity = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.70) {
            ripples.removeAll { $0.id == newRipple.id }
        }
    }
}

// MARK: - 🌊 2028 Water Glass Ribbon Pill Modifier
public struct Genie2028WaterPillModifier: ViewModifier {
    public var isSelected: Bool
    public var tint: Color
    @State private var isHovered: Bool = false

    public func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    if isSelected {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        tint.opacity(0.30),
                                        tint.opacity(0.12),
                                        Color.white.opacity(0.06)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        Capsule()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.65),
                                        tint.opacity(0.70),
                                        Color.white.opacity(0.20)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.8
                            )
                    } else if isHovered {
                        Capsule()
                            .fill(Color.white.opacity(0.09))
                        Capsule()
                            .strokeBorder(Color.white.opacity(0.22), lineWidth: 0.6)
                    } else {
                        Capsule()
                            .fill(Color.white.opacity(0.04))
                        Capsule()
                            .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
                    }
                }
            )
            .onHover { inside in
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                    isHovered = inside
                }
            }
    }
}

public extension View {
    func waterGlassPill(isSelected: Bool, tint: Color = .cyan) -> some View {
        modifier(Genie2028WaterPillModifier(isSelected: isSelected, tint: tint))
    }
}
