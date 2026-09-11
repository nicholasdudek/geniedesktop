// MARK: - AppleNotchIslandView.swift
// Golden Gate Engineering • © 2026 Nicholas M. Dudek
// Apache License, Version 2.0 (Apache-2.0)
//
// Modern Apple Camera Notch & Dynamic Island component matching Apple's latest
// hardware specifications and macOS continuous curvature (Squircle) styling.
// Smoothly integrates hardware camera cutout with fluid expandable island states.

import AppKit
import SwiftUI

// MARK: - Apple Notch Cutout Shape (Continuous Squircles with Ear Transitions)
/// Draws an authentic Apple camera notch silhouette with rounded bottom corners
/// and reverse curvature ear flares transitioning seamlessly into the top display bezel.
public struct AppleNotchCutoutShape: Shape {
    public var cornerRadius: CGFloat = 11.0
    public var earRadius: CGFloat = 9.0

    public init(cornerRadius: CGFloat = 11.0, earRadius: CGFloat = 9.0) {
        self.cornerRadius = cornerRadius
        self.earRadius = earRadius
    }

    public func path(in rect: CGRect) -> Path {
        var path = Path()

        let cr = min(cornerRadius, rect.height / 2.0, rect.width / 4.0)
        let er = min(earRadius, rect.height / 2.0, rect.width / 4.0)

        // Start top-left outside ear
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))

        // Left ear flare (curves downwards into notch wall)
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + er, y: rect.minY + er),
            control: CGPoint(x: rect.minX + er, y: rect.minY)
        )

        // Left vertical notch wall
        path.addLine(to: CGPoint(x: rect.minX + er, y: rect.maxY - cr))

        // Bottom-left rounded corner
        path.addQuadCurve(
            to: CGPoint(x: rect.minX + er + cr, y: rect.maxY),
            control: CGPoint(x: rect.minX + er, y: rect.maxY)
        )

        // Bottom flat edge
        path.addLine(to: CGPoint(x: rect.maxX - er - cr, y: rect.maxY))

        // Bottom-right rounded corner
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX - er, y: rect.maxY - cr),
            control: CGPoint(x: rect.maxX - er, y: rect.maxY)
        )

        // Right vertical notch wall
        path.addLine(to: CGPoint(x: rect.maxX - er, y: rect.minY + er))

        // Right ear flare (curves outwards to display bezel)
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY),
            control: CGPoint(x: rect.maxX - er, y: rect.minY)
        )

        path.closeSubpath()
        return path
    }
}

// MARK: - Apple Notch Island View
/// Complete component providing Apple's modern camera housing with interactive fluid expansion
public struct AppleNotchIslandView: View {
    let screen: NSScreen
    @ObservedObject var detector = GenieSystemAppearanceDetector.shared
    @ObservedObject var localModels = LocalModelManager.shared

    @State private var isHovered: Bool = false
    @State private var isExpanded: Bool = false

    public init(screen: NSScreen = NSScreen.main ?? NSScreen.screens.first!) {
        self.screen = screen
    }

    private var notch: ScreenNotchInfo {
        ScreenNotchInfo.forScreen(screen)
    }

    private var restingWidth: CGFloat {
        notch.hasNotch ? notch.notchWidth : 180.0
    }

    private var restingHeight: CGFloat {
        notch.hasNotch ? max(32.0, notch.notchHeight) : 32.0
    }

    public var body: some View {
        let currentWidth = isHovered || isExpanded ? max(restingWidth + 120.0, 360.0) : restingWidth
        let currentHeight = isHovered || isExpanded ? restingHeight + 28.0 : restingHeight

        ZStack(alignment: .top) {
            // Pitch black background with authentic squircle silhouette
            AppleNotchCutoutShape(
                cornerRadius: notch.hasNotch ? notch.cornerRadius : 14.0,
                earRadius: notch.hasNotch ? notch.earRadius : 10.0
            )
            .fill(Color.black)
            .overlay(
                AppleNotchCutoutShape(
                    cornerRadius: notch.hasNotch ? notch.cornerRadius : 14.0,
                    earRadius: notch.hasNotch ? notch.earRadius : 10.0
                )
                .stroke(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.18),
                            Color.cyan.opacity(isHovered ? 0.35 : 0.08),
                            Color.white.opacity(0.04)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.85
                )
            )
            .shadow(color: Color.black.opacity(isHovered ? 0.65 : 0.35), radius: isHovered ? 14 : 6, y: 3)

            // Content inside the notch / island
            VStack(spacing: 0) {
                // Top resting row (Camera aperture indicators & subtle status)
                HStack(spacing: 12) {
                    // Left Wing: Model or Assistant Status
                    if isHovered || isExpanded {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(localModels.isGenerating ? Color.green : Color.cyan)
                                .frame(width: 6, height: 6)
                            Text(localModels.isGenerating ? "Genie Thinking" : "Genie Ready")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .transition(.opacity.combined(with: .scale))
                    } else {
                        Spacer()
                    }

                    // Hardware Camera & Ambient Sensor Simulation
                    HStack(spacing: 10) {
                        // Ambient Light Sensor
                        Circle()
                            .fill(Color(red: 0.10, green: 0.10, blue: 0.15))
                            .frame(width: 4, height: 4)
                            .overlay(Circle().stroke(Color.white.opacity(0.06), lineWidth: 0.5))

                        // TrueDepth / 1080p FaceTime HD Camera lens with glass reflection
                        ZStack {
                            Circle()
                                .fill(Color(red: 0.05, green: 0.08, blue: 0.14))
                                .frame(width: 9, height: 9)
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [Color.blue.opacity(0.40), Color.clear],
                                        center: .topLeading,
                                        startRadius: 1,
                                        endRadius: 5
                                    )
                                )
                                .frame(width: 7, height: 7)
                            // Green indicator LED when camera / vision is active
                            if localModels.isGenerating {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 3.5, height: 3.5)
                                    .shadow(color: Color.green.opacity(0.8), radius: 3)
                            }
                        }
                    }

                    // Right Wing: Battery / System stats
                    if isHovered || isExpanded {
                        HStack(spacing: 5) {
                            Text("\(Int(detector.screenSize.width))×\(Int(detector.screenSize.height))")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.55))
                            Image(systemName: "sparkles")
                                .font(.system(size: 9))
                                .foregroundColor(.cyan)
                        }
                        .transition(.opacity.combined(with: .scale))
                    } else {
                        Spacer()
                    }
                }
                .frame(height: restingHeight)
                .padding(.horizontal, 16)

                // Expanded Dynamic Island Drawer (appears on hover or click)
                if isHovered || isExpanded {
                    HStack(spacing: 10) {
                        // Quick Action: Open Genie Chat
                        Button(action: {
                            FinderChatWindowManager.shared.openTab(.chat)
                            HapticFeedback.selection()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "bubble.left.and.bubble.right.fill")
                                    .font(.system(size: 9.5))
                                Text("Chat")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3.5)
                            .background(Capsule().fill(detector.folderBubbleGradient))
                        }
                        .buttonStyle(.plain)

                        // Quick Action: Open Terminal
                        Button(action: {
                            FinderChatWindowManager.shared.openTab(.terminal)
                            HapticFeedback.selection()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "terminal.fill")
                                    .font(.system(size: 9.5))
                                Text("Terminal")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                            }
                            .foregroundColor(.white.opacity(0.85))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3.5)
                            .background(Capsule().fill(Color.white.opacity(0.12)))
                        }
                        .buttonStyle(.plain)

                        // Quick Action: GitHub Studio
                        Button(action: {
                            FinderChatWindowManager.shared.openTab(.github)
                            HapticFeedback.selection()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.triangle.branch")
                                    .font(.system(size: 9.5))
                                Text("GitHub")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(.white.opacity(0.85))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3.5)
                            .background(Capsule().fill(Color.white.opacity(0.12)))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 6)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
        .frame(width: currentWidth, height: currentHeight)
        .animation(.spring(response: 0.30, dampingFraction: 0.82), value: isHovered)
        .animation(.spring(response: 0.30, dampingFraction: 0.82), value: isExpanded)
        .onHover { hovering in
            isHovered = hovering
            if hovering {
                HapticFeedback.selection()
            }
        }
    }
}
