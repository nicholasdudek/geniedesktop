// MARK: - GenieFuturisticSmokeIconView.swift
// Golden Gate Engineering • © 2026 Nicholas M. Dudek
//
// Futuristic Genie with Mystical Billowing Smoke Icon & Interactive Magic Badge.
// Replaces the legacy plain lightbulb with an Apple 2028-grade fluid animated
// Genie lamp and glowing cyan/purple smoke plume simulation.

import AppKit
import Foundation
import SwiftUI

// MARK: - 🧞‍♂️ Futuristic Genie with Smoke & Magic Bottle Icon View
public struct GenieFuturisticSmokeIconView: View {
    public var size: CGFloat
    public var isGlowing: Bool
    public var showSmokeAnimation: Bool
    public var tintColor: Color
    public var isProcessing: Bool

    public init(
        size: CGFloat = 22,
        isGlowing: Bool = true,
        showSmokeAnimation: Bool = true,
        tintColor: Color = Color(red: 0.0, green: 0.95, blue: 0.85), // Mystical Cyan
        isProcessing: Bool = false
    ) {
        self.size = size
        self.isGlowing = isGlowing
        self.showSmokeAnimation = showSmokeAnimation
        self.tintColor = tintColor
        self.isProcessing = isProcessing
    }

    public var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let pulseSpeed = isProcessing ? 5.5 : 2.2
            let pulseScale = isProcessing ? (1.0 + CGFloat(sin(time * pulseSpeed)) * 0.14) : (1.0 + CGFloat(sin(time * pulseSpeed)) * 0.08)

            ZStack {
                // 1. Ambient Ethereal Glow Aura
                if isGlowing || isProcessing {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    (isProcessing ? Color(red: 0.15, green: 0.90, blue: 1.0) : tintColor).opacity(isProcessing ? 0.65 : 0.35),
                                    Color.purple.opacity(isProcessing ? 0.35 : 0.18),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 1,
                                endRadius: size * (isProcessing ? 1.2 : 0.9)
                            )
                        )
                        .frame(width: size * (isProcessing ? 1.8 : 1.5), height: size * (isProcessing ? 1.8 : 1.5))
                        .scaleEffect(pulseScale)
                }

                // 2. Rising Billowing Smoke Trails (Canvas Sine-Wave Filaments)
                if showSmokeAnimation || isProcessing {
                    GenieSmokeCanvas(time: time * (isProcessing ? 1.8 : 1.0), tint: isProcessing ? Color.cyan : tintColor, width: size, height: size)
                        .frame(width: size, height: size)
                }

                // 3. Futuristic Genie Magic Bottle / Lamp Core Talisman
                if isProcessing {
                    // Actively Processing: The Magical Glowing Genie Bottle
                    ZStack {
                        // Bottle Body Silhouette
                        GenieBottleShape()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(red: 0.0, green: 0.95, blue: 1.0),
                                        Color(red: 0.65, green: 0.30, blue: 1.0),
                                        Color(red: 0.20, green: 0.05, blue: 0.45)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: size * 0.72, height: size * 0.82)
                            .shadow(color: Color.cyan.opacity(0.9), radius: 5, x: 0, y: 0)

                        // Glass Rim Specular Highlight
                        GenieBottleShape()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white,
                                        Color.cyan.opacity(0.8),
                                        Color.purple.opacity(0.5)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: max(0.8, size * 0.04)
                            )
                            .frame(width: size * 0.72, height: size * 0.82)

                        // Inner Star Pulsing inside Bottle
                        Image(systemName: "sparkle")
                            .font(.system(size: size * 0.28, weight: .bold))
                            .foregroundColor(.white)
                            .rotationEffect(.degrees(time * 90.0))
                            .offset(y: size * 0.12)
                    }
                    .scaleEffect(pulseScale)
                    .offset(y: size * 0.04)
                } else {
                    // Idle Talisman
                    ZStack {
                        Image(systemName: "sparkles")
                            .font(.system(size: size * 0.48, weight: .black))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [
                                        tintColor,
                                        Color(red: 0.65, green: 0.35, blue: 1.0),
                                        Color.white
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: tintColor.opacity(0.8), radius: 4, x: 0, y: 0)
                    }
                    .offset(y: size * 0.08)
                }

                // 4. Orbiting Shimmering Sparkle
                let orbitSpeed = isProcessing ? 6.0 : 3.0
                Circle()
                    .fill(Color.white)
                    .frame(width: size * 0.14, height: size * 0.14)
                    .shadow(color: isProcessing ? Color.cyan : tintColor, radius: 3)
                    .offset(
                        x: CGFloat(cos(time * orbitSpeed)) * (size * 0.35),
                        y: CGFloat(sin(time * orbitSpeed)) * (size * 0.30) - (size * 0.1)
                    )
            }
            .frame(width: size, height: size)
        }
    }
}

// MARK: - 🏺 Authentic Arabian Genie Bottle Vector Shape
public struct GenieBottleShape: Shape {
    public init() {}

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height

        // Top Spout / Stopper Rim
        let rimTop = h * 0.04
        let rimBottom = h * 0.14
        let rimLeft = w * 0.38
        let rimRight = w * 0.62

        // Neck
        let neckBottom = h * 0.34
        let neckLeft = w * 0.42
        let neckRight = w * 0.58

        // Bulbous Belly
        let shoulderY = h * 0.46
        let bellyY = h * 0.72
        let bodyRight = w * 0.88
        let bodyLeft = w * 0.12
        let baseY = h * 0.95
        let baseLeft = w * 0.34
        let baseRight = w * 0.66

        path.move(to: CGPoint(x: rimLeft, y: rimBottom))
        path.addLine(to: CGPoint(x: rimLeft - w * 0.04, y: rimTop))
        path.addQuadCurve(to: CGPoint(x: rimRight + w * 0.04, y: rimTop), control: CGPoint(x: w * 0.5, y: rimTop - h * 0.03))
        path.addLine(to: CGPoint(x: rimRight, y: rimBottom))

        // Neck down to shoulder
        path.addLine(to: CGPoint(x: neckRight, y: neckBottom))
        path.addCurve(
            to: CGPoint(x: bodyRight, y: bellyY),
            control1: CGPoint(x: w * 0.68, y: shoulderY),
            control2: CGPoint(x: bodyRight, y: shoulderY + h * 0.12)
        )

        // Belly down to pedestal base
        path.addCurve(
            to: CGPoint(x: baseRight, y: baseY),
            control1: CGPoint(x: bodyRight, y: h * 0.88),
            control2: CGPoint(x: w * 0.78, y: baseY)
        )

        // Base
        path.addLine(to: CGPoint(x: baseLeft, y: baseY))

        // Left side up
        path.addCurve(
            to: CGPoint(x: bodyLeft, y: bellyY),
            control1: CGPoint(x: w * 0.22, y: baseY),
            control2: CGPoint(x: bodyLeft, y: h * 0.88)
        )
        path.addCurve(
            to: CGPoint(x: neckLeft, y: neckBottom),
            control1: CGPoint(x: bodyLeft, y: shoulderY + h * 0.12),
            control2: CGPoint(x: w * 0.32, y: shoulderY)
        )

        path.closeSubpath()
        return path
    }
}

// MARK: - 💨 Animated Smoke Canvas (Bezier & Sine Wave Swirls)
private struct GenieSmokeCanvas: View {
    let time: Double
    let tint: Color
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height

            // 3 Dynamic Smoke Plumes
            for i in 0..<3 {
                let phaseOffset = Double(i) * 2.1
                let plumeX = w * 0.5 + CGFloat(sin(time * 1.8 + phaseOffset)) * (w * 0.22)
                let plumeY = h * 0.45 - CGFloat(cos(time * 1.4 + phaseOffset) + 1.0) * (h * 0.22)
                let plumeRadius = w * 0.20 + CGFloat(sin(time * 2.5 + phaseOffset)) * 2.0

                let plumeRect = CGRect(
                    x: plumeX - plumeRadius,
                    y: plumeY - plumeRadius,
                    width: plumeRadius * 2,
                    height: plumeRadius * 2
                )

                let opacity = 0.28 + sin(time * 2.0 + phaseOffset) * 0.14
                let smokeColor = (i == 1) ? Color.purple : tint

                context.fill(
                    Path(ellipseIn: plumeRect),
                    with: .radialGradient(
                        Gradient(colors: [
                            smokeColor.opacity(opacity),
                            smokeColor.opacity(opacity * 0.4),
                            Color.clear
                        ]),
                        center: CGPoint(x: plumeX, y: plumeY),
                        startRadius: 1,
                        endRadius: plumeRadius
                    )
                )
            }
        }
    }
}

// MARK: - 🧞‍♂️ Interactive Futuristic Genie Magic Hints Badge
public struct GenieMagicBadgeView: View {
    public var title: String = "Genie Magic"
    public var isArmed: Bool = true
    public var action: () -> Void

    public init(title: String = "Genie Magic", isArmed: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.isArmed = isArmed
        self.action = action
    }

    public var body: some View {
        Button(action: {
            HapticFeedback.selection()
            action()
        }) {
            HStack(spacing: 5) {
                GenieFuturisticSmokeIconView(size: 16, isGlowing: isArmed, showSmokeAnimation: isArmed)

                Text(title)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 0.0, green: 0.95, blue: 0.85),
                                Color(red: 0.70, green: 0.50, blue: 1.0)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color(red: 0.08, green: 0.09, blue: 0.14).opacity(0.85))
            )
            .overlay(
                Capsule()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.cyan.opacity(0.60),
                                Color.purple.opacity(0.40)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
            )
            .shadow(color: Color.cyan.opacity(0.25), radius: 4, x: 0, y: 1)
        }
        .buttonStyle(GenieMagneticButtonStyle(scale: 1.08))
        .help("Toggle Genie Magic & Futuristic Shortcuts")
    }
}
