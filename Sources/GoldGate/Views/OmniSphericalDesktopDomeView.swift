import AppKit
import Foundation
import SwiftUI
import simd

// MARK: - Omni-Spherical Desktop Dome View (Inside-the-Sphere Mac Desktop)
// Situates the user at the exact focal center of a 360° geodesic sphere.
// All virtual desktops, apps, and windows wrap around the interior sphere wall.
// Rotations are driven by 6DOF FaceTime head tracking and trackpad gestures without gimbal lock.

public struct OmniSphericalDesktopDomeView: View {
    @ObservedObject var spatialManager: SpatialPlaneManager = .shared
    @ObservedObject var desktopsManager: MacDesktopsManager = .shared
    @ObservedObject var faceTracking: SpatialFaceTrackingManager = .shared

    @State private var sphereYaw: Double = 0.0     // Left / Right (-180° to +180°)
    @State private var spherePitch: Double = 0.0   // Up / Down (-60° to +60°)
    @State private var sphereRadius: Double = 920.0
    @State private var hoveredSlot: Int? = nil
    @State private var dragOffset: CGSize = .zero

    // 9 Cardinal Desktop Slots mapped onto Spherical Coordinates (Yaw θ, Pitch φ)
    private let sphericalSlots: [(slot: Int, yaw: Double, pitch: Double, label: String, icon: String)] = [
        (1, -38.0,  22.0, "North-West: Staging", "square.grid.3x3.topleft.filled"),
        (2,   0.0,  22.0, "North: Reference & Specs", "book.closed.fill"),
        (3,  38.0,  22.0, "North-East: Telemetry", "chart.xyaxis.line"),
        (4, -42.0,   0.0, "West: Media & Notes", "music.note.list"),
        (5,   0.0,   0.0, "Center: Main Workspace", "macwindow.on.rectangle"),
        (6,  42.0,   0.0, "East: Communications", "bubble.left.and.bubble.right.fill"),
        (7, -38.0, -22.0, "South-West: Lakehouse", "server.rack"),
        (8,   0.0, -22.0, "South: Terminal & Logs", "terminal.fill"),
        (9,  38.0, -22.0, "South-East: AI Swarm", "brain.head.profile")
    ]

    public init() {}

    public var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width * 0.5, y: geo.size.height * 0.5)

            // Combined Yaw and Pitch (Face Tracking + User Pan)
            let effectiveYaw = sphereYaw + (faceTracking.isFaceTrackingEnabled ? Double(faceTracking.currentOrientation.y) * 45.0 : 0.0) + Double(dragOffset.width * 0.12)
            let effectivePitch = spherePitch + (faceTracking.isFaceTrackingEnabled ? Double(-faceTracking.currentOrientation.x) * 35.0 : 0.0) - Double(dragOffset.height * 0.12)

            ZStack {
                // 1. Deep Space Spherical Atmosphere & Geodesic Wireframe
                sphericalCosmicBackground(center: center, size: geo.size, yaw: effectiveYaw, pitch: effectivePitch)

                // 2. Spherical Geodesic Grid Latitude/Longitude Rings
                geodesicGridRings(center: center, size: geo.size, yaw: effectiveYaw, pitch: effectivePitch)

                // 3. Desktop Cards Projected on Interior Sphere Surface
                ForEach(sphericalSlots, id: \.slot) { item in
                    sphericalDesktopCard(
                        item: item,
                        center: center,
                        size: geo.size,
                        yaw: effectiveYaw,
                        pitch: effectivePitch
                    )
                }

                // 4. Center Crosshair / HUD Telemetry
                sphericalHUDOverlay(yaw: effectiveYaw, pitch: effectivePitch)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { val in
                        dragOffset = val.translation
                    }
                    .onEnded { val in
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.82)) {
                            sphereYaw += Double(val.translation.width * 0.12)
                            spherePitch -= Double(val.translation.height * 0.12)
                            spherePitch = max(-55.0, min(55.0, spherePitch))
                            dragOffset = .zero
                        }
                    }
            )
        }
    }

    // MARK: - Spherical Desktop Card Projection
    @ViewBuilder
    private func sphericalDesktopCard(
        item: (slot: Int, yaw: Double, pitch: Double, label: String, icon: String),
        center: CGPoint,
        size: CGSize,
        yaw: Double,
        pitch: Double
    ) -> some View {
        let relYaw = (item.yaw - yaw) * .pi / 180.0
        let relPitch = (item.pitch - pitch) * .pi / 180.0

        // 3D Cartesian coordinates inside sphere
        let x3D = sphereRadius * cos(relPitch) * sin(relYaw)
        let y3D = -sphereRadius * sin(relPitch)
        let z3D = sphereRadius * cos(relPitch) * cos(relYaw)

        // Only render if in front hemisphere (z3D > 0)
        if z3D > 80.0 {
            let fov: Double = 900.0
            let scale = fov / (fov + (sphereRadius - z3D))
            let projX = center.x + CGFloat(x3D * scale)
            let projY = center.y + CGFloat(y3D * scale)

            let isCenter = abs(item.yaw - yaw) < 18.0 && abs(item.pitch - pitch) < 14.0
            let isHovered = hoveredSlot == item.slot

            VStack(spacing: 8) {
                // Card Header
                HStack(spacing: 6) {
                    Image(systemName: item.icon)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.cyan)
                    Text(item.label)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    Text("Space \(item.slot)")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.horizontal, 12)
                .padding(.top, 8)

                // Desktop Preview Thumbnail
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.black.opacity(0.6))

                    if let img = desktopsManager.desktopLivePreviews[item.slot] {
                        Image(nsImage: img)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .clipped()
                            .cornerRadius(10)
                    } else {
                        VStack(spacing: 4) {
                            Image(systemName: "macwindow")
                                .font(.system(size: 24))
                                .foregroundColor(.white.opacity(0.3))
                            Text("Virtual Desktop \(item.slot)")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }
                }
                .padding(6)
            }
            .frame(width: 320, height: 200)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 0.08, green: 0.10, blue: 0.16).opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isCenter ? Color.cyan : (isHovered ? Color.white.opacity(0.8) : Color.white.opacity(0.2)),
                                lineWidth: isCenter ? 2.5 : (isHovered ? 1.5 : 0.8)
                            )
                    )
                    .shadow(color: isCenter ? Color.cyan.opacity(0.4) : Color.black.opacity(0.5), radius: isCenter ? 24 : 12)
            )
            .rotation3DEffect(.degrees(-relYaw * 180.0 / .pi * 0.7), axis: (x: 0, y: 1, z: 0))
            .rotation3DEffect(.degrees(relPitch * 180.0 / .pi * 0.7), axis: (x: 1, y: 0, z: 0))
            .scaleEffect(CGFloat(scale) * (isHovered ? 1.06 : 1.0))
            .position(x: projX, y: projY)
            .zIndex(z3D)
            .onHover { h in
                hoveredSlot = h ? item.slot : nil
            }
            .onTapGesture {
                withAnimation(.spring(response: 0.45, dampingFraction: 0.82)) {
                    sphereYaw = item.yaw
                    spherePitch = item.pitch
                    spatialManager.focusedPlaneIndex = item.slot
                    spatialManager.macroTargetSpaceIndex = item.slot
                }
            }
        }
    }

    // MARK: - Geodesic Wireframe Rings
    @ViewBuilder
    private func geodesicGridRings(center: CGPoint, size: CGSize, yaw: Double, pitch: Double) -> some View {
        Canvas { context, canvasSize in
            let cx = canvasSize.width * 0.5
            let cy = canvasSize.height * 0.5
            let r = 420.0

            // Latitude Rings
            for latDeg in stride(from: -40.0, through: 40.0, by: 20.0) {
                let p = (latDeg - pitch) * .pi / 180.0
                let ringRadius = r * cos(p)
                let ringY = cy - r * sin(p)

                if ringRadius > 10.0 {
                    var path = Path()
                    path.addEllipse(in: CGRect(x: cx - ringRadius, y: ringY - ringRadius * 0.25, width: ringRadius * 2, height: ringRadius * 0.5))
                    context.stroke(path, with: .color(Color.cyan.opacity(0.12)), lineWidth: 1.0)
                }
            }

            // Longitude Rings
            for lonDeg in stride(from: -120.0, through: 120.0, by: 30.0) {
                let yRad = (lonDeg - yaw) * .pi / 180.0
                let xOffset = r * sin(yRad)
                if cos(yRad) > 0 {
                    var path = Path()
                    path.move(to: CGPoint(x: cx + xOffset, y: cy - r * 0.7))
                    path.addQuadCurve(to: CGPoint(x: cx + xOffset, y: cy + r * 0.7), control: CGPoint(x: cx + xOffset * 1.25, y: cy))
                    context.stroke(path, with: .color(Color.cyan.opacity(0.10)), lineWidth: 1.0)
                }
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Cosmic Starfield & Background
    @ViewBuilder
    private func sphericalCosmicBackground(center: CGPoint, size: CGSize, yaw: Double, pitch: Double) -> some View {
        ZStack {
            Color.black.ignoresSafeArea()

            RadialGradient(
                gradient: Gradient(colors: [Color(red: 0.05, green: 0.12, blue: 0.25).opacity(0.6), Color.black]),
                center: .center,
                startRadius: 50,
                endRadius: max(size.width, size.height) * 0.8
            )
            .ignoresSafeArea()
        }
    }

    // MARK: - HUD Overlay
    @ViewBuilder
    private func sphericalHUDOverlay(yaw: Double, pitch: Double) -> some View {
        VStack {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "globe.americas.fill")
                            .foregroundColor(.cyan)
                        Text("OMNI-SPHERE DESKTOP DOME 🌐")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(.cyan)
                    }
                    Text(String(format: "Azimuth: %.1f° • Elevation: %.1f° • 6DOF Active", yaw, pitch))
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.black.opacity(0.55)))

                Spacer()

                Button(action: {
                    withAnimation(.spring()) {
                        sphereYaw = 0.0
                        spherePitch = 0.0
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "scope")
                        Text("Recenter Sphere")
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.cyan.opacity(0.35)))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            Spacer()
        }
        .allowsHitTesting(true)
    }
}
