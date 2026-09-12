// MARK: - GenieMysticalIconView.swift
// Golden Gate Engineering • © 2026 Nicholas M. Dudek
//
// Ultra-Cool Mystical Living Genie Icon with Ambient Ethereal Aura,
// Orbiting Stardust, Billowing Smoke, and Sporadic Wish Whisperer Floating Bubble.

import AppKit
import Foundation
import SwiftUI

// MARK: - 🧞‍♂️ Mystical Genie Living Icon View
public struct GenieMysticalIconView: View {
    @ObservedObject private var wishEngine = GenieSporadicWishEngine.shared

    public var glyphImage: NSImage
    public var isHovered: Bool
    public var size: CGFloat
    public var onPrimaryClick: (() -> Void)?

    @State private var hoverRubCounter: Int = 0
    @State private var lastHoverTime: TimeInterval = 0
    @State private var isShowingWishInput: Bool = false
    @FocusState private var isWishFieldFocused: Bool

    public init(
        glyphImage: NSImage,
        isHovered: Bool = false,
        size: CGFloat = 20,
        onPrimaryClick: (() -> Void)? = nil
    ) {
        self.glyphImage = glyphImage
        self.isHovered = isHovered
        self.size = size
        self.onPrimaryClick = onPrimaryClick
    }

    public var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let isAsking = wishEngine.isBubbleVisible
            let isRubbed = wishEngine.isRubbing
            let isGranting = wishEngine.mood == .grantingWish

            // Playful bobbing & lamp rub tilt
            let bobY = CGFloat(sin(time * 2.4)) * (isAsking ? 1.8 : 0.8)
            let wiggleAngle = isRubbed ? Angle(degrees: sin(time * 24.0) * 8.0) : (isAsking ? Angle(degrees: sin(time * 3.5) * 4.0) : Angle.zero)
            let auraScale = CGFloat(1.0 + sin(time * 2.2) * 0.08) * CGFloat(wishEngine.auraIntensity)

            ZStack {
                // 1. Ethereal Breathing Aura Halo (Cyan, Royal Purple, Celestial Gold)
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                (isGranting ? Color.yellow : (isRubbed ? Color.cyan : Color(red: 0.0, green: 0.92, blue: 0.88))).opacity(isHovered || isAsking ? 0.45 : 0.22),
                                (isGranting ? Color.orange : Color(red: 0.65, green: 0.28, blue: 0.95)).opacity(isHovered || isAsking ? 0.30 : 0.12),
                                (isGranting ? Color.white : Color(red: 1.0, green: 0.82, blue: 0.20)).opacity(isAsking ? 0.18 : 0.04),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 1.0,
                            endRadius: size * 1.3
                        )
                    )
                    .frame(width: size * 2.4, height: size * 2.4)
                    .scaleEffect(auraScale)

                // 2. Rising Billowing Smoke Filaments
                GenieMiniSmokePlumes(time: time, width: size, height: size * 1.3, isEnergized: isHovered || isAsking || isRubbed)
                    .offset(y: -size * 0.35)

                // 3. Orbiting Stardust Particles
                ForEach(0..<3) { i in
                    let phase = time * 2.8 + Double(i) * (2.0 * .pi / 3.0)
                    let radiusX = size * 0.75
                    let radiusY = size * 0.42
                    let sparkX = CGFloat(cos(phase)) * radiusX
                    let sparkY = CGFloat(sin(phase)) * radiusY - 2.0
                    let sparkScale = CGFloat(0.55 + 0.45 * sin(phase + 1.2))

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.white, (i == 1 ? Color.yellow : Color.cyan)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 2.8, height: 2.8)
                        .scaleEffect(sparkScale)
                        .shadow(color: (i == 1 ? Color.yellow : Color.cyan), radius: 2)
                        .offset(x: sparkX, y: sparkY)
                        .opacity(isHovered || isAsking ? 1.0 : 0.7)
                }

                // 4. Central Genie Icon Glyph with Lamp Rub Tilt
                Image(nsImage: glyphImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
                    .rotationEffect(wiggleAngle)
                    .offset(y: bobY)
                    .scaleEffect(isHovered ? 1.12 : (isRubbed ? 1.18 : 1.0))
                    .shadow(color: Color.black.opacity(isHovered ? 0.45 : 0.20), radius: 2.0, y: 1.2)
                    .shadow(color: isAsking ? Color.cyan.opacity(0.85) : Color.clear, radius: 4)

                // 5. Smoke Puff Burst on Lamp Rub or Wish Grant
                if isRubbed || isGranting {
                    MiniDockSmokePuffView(color: isGranting ? Color.yellow : Color.cyan)
                        .frame(width: size * 1.6, height: size * 1.6)
                }

                // 6. Whimsical Wink Sparkle Star on the spout tip
                if isAsking || isHovered {
                    Image(systemName: "sparkle")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(.yellow)
                        .shadow(color: .orange, radius: 2)
                        .offset(x: size * 0.38, y: -size * 0.32 + bobY)
                        .scaleEffect(0.8 + 0.3 * CGFloat(sin(time * 6.0)))
                }
            }
            .frame(width: size + 10, height: size + 6)
            .contentShape(Rectangle())
            .modifier(TapGestureOptionalModifier(action: onPrimaryClick))
            .onHover { hovering in
                if hovering {
                    let now = ProcessInfo.processInfo.systemUptime
                    if now - lastHoverTime < 0.8 {
                        // User is actively scrubbing/hovering -> Lamp Rub gesture!
                        hoverRubCounter += 1
                        if hoverRubCounter >= 2 {
                            wishEngine.rubLamp()
                        }
                    } else {
                        hoverRubCounter = 1
                    }
                    lastHoverTime = now
                }
            }
            .popover(isPresented: $wishEngine.isBubbleVisible, arrowEdge: .bottom) {
                GenieFloatingWishBubbleView()
            }
        }
    }
}

// MARK: - 💨 Mini Smoke Plumes Canvas
private struct GenieMiniSmokePlumes: View {
    let time: Double
    let width: CGFloat
    let height: CGFloat
    let isEnergized: Bool

    var body: some View {
        Canvas { context, sz in
            let w = sz.width
            let h = sz.height
            let count = isEnergized ? 3 : 2

            for i in 0..<count {
                let offset = Double(i) * 2.1
                let speed = isEnergized ? 2.4 : 1.4
                let plumeX = w * 0.5 + CGFloat(sin(time * speed + offset)) * (w * 0.24)
                let plumeY = h * 0.7 - CGFloat(fmod(time * 18.0 + Double(i * 12), Double(h * 0.85)))
                let radius: CGFloat = 2.5 + CGFloat(sin(time * 2.0 + offset)) * 1.0

                let rect = CGRect(x: plumeX - radius, y: plumeY - radius, width: radius * 2, height: radius * 2)
                let alpha = max(0.0, min(0.38, 0.40 * (1.0 - (h * 0.7 - plumeY) / (h * 0.75))))

                let smokeColor = (i == 1) ? Color.purple : Color.cyan
                context.fill(
                    Path(ellipseIn: rect),
                    with: .radialGradient(
                        Gradient(colors: [
                            smokeColor.opacity(alpha),
                            smokeColor.opacity(alpha * 0.3),
                            Color.clear
                        ]),
                        center: CGPoint(x: plumeX, y: plumeY),
                        startRadius: 0.5,
                        endRadius: radius
                    )
                )
            }
        }
        .frame(width: width, height: height)
        .allowsHitTesting(false)
    }
}

// MARK: - 💬 Floating Wish Speech Bubble
public struct GenieFloatingWishBubbleView: View {
    @ObservedObject private var wishEngine = GenieSporadicWishEngine.shared
    @State private var customWishText: String = ""
    @FocusState private var isCustomFieldFocused: Bool

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            // Header: Title & Close Button
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.cyan, Color.purple, Color.yellow],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text(wishEngine.bubbleTitle)
                    .font(.system(size: 11.5, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Spacer()

                Button(action: {
                    wishEngine.dismissBubble()
                    HapticFeedback.selection()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.55))
                }
                .buttonStyle(.plain)
            }

            Text(wishEngine.bubbleSubtitle)
                .font(.system(size: 9.5))
                .foregroundColor(.white.opacity(0.68))
                .lineLimit(2)

            // Quick Wish Chips Row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 5) {
                    ForEach(wishEngine.quickWishes) { wish in
                        Button(action: {
                            wishEngine.grantWish(wish.promptText, targetTab: wish.targetTab)
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: wish.icon)
                                    .font(.system(size: 9))
                                    .foregroundColor(.cyan)

                                Text(wish.label)
                                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3.5)
                            .background(
                                Capsule()
                                    .fill(Color.white.opacity(0.12))
                                    .overlay(Capsule().strokeBorder(Color.cyan.opacity(0.35), lineWidth: 0.7))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Inline Custom Wish Input Field
            HStack(spacing: 5) {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 10))
                    .foregroundColor(.yellow)

                TextField("Whisper your wish here...", text: $customWishText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 10.5, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .focused($isCustomFieldFocused)
                    .onSubmit {
                        if !customWishText.isEmpty {
                            wishEngine.grantWish(customWishText)
                            customWishText = ""
                        }
                    }

                if !customWishText.isEmpty {
                    Button(action: {
                        wishEngine.grantWish(customWishText)
                        customWishText = ""
                    }) {
                        Text("Grant ✨")
                            .font(.system(size: 9.5, weight: .bold, design: .rounded))
                            .foregroundColor(.black)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2.5)
                            .background(Capsule().fill(Color.cyan))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.black.opacity(0.45))
                    .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).stroke(Color.white.opacity(0.15), lineWidth: 0.5))
            )
        }
        .padding(10)
        .frame(width: 280)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(red: 0.08, green: 0.09, blue: 0.14).opacity(0.94))
                .shadow(color: Color.black.opacity(0.55), radius: 10, y: 5)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.cyan.opacity(0.65), Color.purple.opacity(0.45), Color.yellow.opacity(0.35)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.0
                        )
                )
        )
    }
}

private struct TapGestureOptionalModifier: ViewModifier {
    let action: (() -> Void)?
    func body(content: Content) -> some View {
        if let action = action {
            content.onTapGesture {
                action()
            }
        } else {
            content
        }
    }
}
