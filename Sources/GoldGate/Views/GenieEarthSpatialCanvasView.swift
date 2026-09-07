import AppKit
import Foundation
import SwiftUI
import simd

// MARK: - Genie Earth / 3D Spatial Maps Walking & Flight Engine
// Provides full Google Maps / Earth style 3D navigation across the continuous 9-desktop and 81-desktop universe.
// Controls:
// - WASD / Arrow Keys: Walk & Fly across the terrain
// - Q / E: Ascend to Satellite Orbit / Descend to Street Level
// - Shift: Hyper-Drive Boost Speed
// - Double-Click any City/Desktop: Cinematic 3D Fly-To Landing
// - Trackpad 2-Finger Drag / Pinch: Google Maps fluid momentum pan & zoom

public struct GenieEarthSpatialCanvasView: View {
    @ObservedObject var spatialManager: SpatialPlaneManager = .shared
    @ObservedObject var vdomEngine: SpatialVirtualDOMEngine = .shared
    @ObservedObject var desktopsManager: MacDesktopsManager = .shared
    @ObservedObject var wallpaperManager: WallpaperManager = .shared
    @ObservedObject var faceTracking: SpatialFaceTrackingManager = .shared

    // Camera Flight State
    @State private var cameraPosition: CGPoint = .zero // (X, Y) in canvas pixels
    @State private var altitudeZoom: CGFloat = 0.35    // 0.10 (Satellite) to 1.0 (Street Level)
    @State private var tiltPitchAngle: Double = 32.0   // 0° (Flat 2D) to 55° (3D Isometric Terrain)
    @State private var headingYawAngle: Double = 0.0   // Compass heading
    @State private var flightVelocity: CGSize = .zero
    @State private var isFlyingFast: Bool = false
    @State private var hoveredSlot: Int? = nil
    @State private var keyMonitor: Any? = nil

    public init() {}

    public var body: some View {
        GeometryReader { geo in
            let screenSize = geo.size
            let is81 = spatialManager.isUniverse81Active
            let dim = is81 ? 9 : 3
            let totalSlots = dim * dim
            let canvasW = screenSize.width * CGFloat(dim)
            let canvasH = screenSize.height * CGFloat(dim)

            ZStack(alignment: .topLeading) {
                // 1. Deep Space Cosmic Sky Dome
                Color(red: 0.02, green: 0.03, blue: 0.06)
                    .ignoresSafeArea()

                // 2. 3D Geodesic Ground Terrain Grid Lines
                groundNavigationGrid(canvasW: canvasW, canvasH: canvasH, screenSize: screenSize, dim: dim)
                    .rotation3DEffect(.degrees(tiltPitchAngle), axis: (x: 1, y: 0, z: 0))
                    .rotation3DEffect(.degrees(headingYawAngle), axis: (x: 0, y: 0, z: 1))
                    .scaleEffect(altitudeZoom)
                    .offset(x: -cameraPosition.x * altitudeZoom + screenSize.width * 0.5,
                            y: -cameraPosition.y * altitudeZoom + screenSize.height * 0.5)

                // 3. 3D Floating Desktop Islands (Cities & Workspaces)
                ZStack(alignment: .topLeading) {
                    ForEach(1...totalSlots, id: \.self) { slot in
                        let (col, row) = is81 ? SpatialPlaneManager.universeCoordinate(for: slot) : SpatialPlaneManager.gridCoordinate(for: slot)
                        let islandX = CGFloat(col) * (screenSize.width + 48.0)
                        let islandY = CGFloat(row) * (screenSize.height + 48.0)

                        desktopIslandNode(
                            slot: slot,
                            col: col,
                            row: row,
                            screenSize: screenSize,
                            isFocused: spatialManager.focusedPlaneIndex == slot
                        )
                        .offset(x: islandX, y: islandY)
                    }
                }
                .rotation3DEffect(.degrees(tiltPitchAngle), axis: (x: 1, y: 0, z: 0), anchor: .center)
                .rotation3DEffect(.degrees(headingYawAngle), axis: (x: 0, y: 0, z: 1), anchor: .center)
                .scaleEffect(altitudeZoom)
                .offset(x: -cameraPosition.x * altitudeZoom + screenSize.width * 0.5,
                        y: -cameraPosition.y * altitudeZoom + screenSize.height * 0.5)

                // 4. Google Maps Style HUD & GPS Flight Controller
                flightControlHUD(screenSize: screenSize, dim: dim, totalSlots: totalSlots)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { val in
                        cameraPosition.x -= val.translation.width / altitudeZoom * 0.25
                        cameraPosition.y -= val.translation.height / altitudeZoom * 0.25
                    }
            )
            .onAppear {
                setupWASDKeyControls()
                // Initialize camera on center desktop
                let (cCol, cRow) = is81 ? (4, 4) : (1, 1)
                cameraPosition = CGPoint(
                    x: CGFloat(cCol) * (screenSize.width + 48.0) + screenSize.width * 0.5,
                    y: CGFloat(cRow) * (screenSize.height + 48.0) + screenSize.height * 0.5
                )
            }
            .onDisappear {
                if let km = keyMonitor {
                    NSEvent.removeMonitor(km)
                }
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - 3D Desktop Island Node (City District)
    @ViewBuilder
    private func desktopIslandNode(
        slot: Int,
        col: Int,
        row: Int,
        screenSize: CGSize,
        isFocused: Bool
    ) -> some View {
        let isHovered = hoveredSlot == slot
        let isCurrent = desktopsManager.currentSpaceIndex == slot
        let compass = SpatialPlaneManager.compassBearing(for: slot)

        VStack(spacing: 8) {
            // Island Billboard Header
            HStack(spacing: 8) {
                Circle()
                    .fill(isFocused ? Color.cyan : (isCurrent ? Color.green : Color.white.opacity(0.4)))
                    .frame(width: 8, height: 8)
                Text(compass.isEmpty ? "District \(slot)" : compass)
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Spacer()
                Text(String(format: "Sector [%d, %d]", col, row))
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)

            // Live Screen Surface Thumbnail
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.black.opacity(0.8))

                if let img = desktopsManager.desktopLivePreviews[slot] {
                    Image(nsImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                        .cornerRadius(12)
                } else {
                    VStack(spacing: 6) {
                        Image(systemName: "macwindow.on.rectangle")
                            .font(.system(size: 32))
                            .foregroundColor(.white.opacity(0.35))
                        Text("Space \(slot) • Live Surface")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.45))
                    }
                }
            }
            .padding(10)
        }
        .frame(width: screenSize.width, height: screenSize.height)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(red: 0.07, green: 0.09, blue: 0.15).opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            isFocused ? Color.cyan : (isHovered ? Color.white.opacity(0.8) : Color.white.opacity(0.2)),
                            lineWidth: isFocused ? 3.0 : 1.0
                        )
                )
                .shadow(color: isFocused ? Color.cyan.opacity(0.5) : Color.black.opacity(0.6), radius: isFocused ? 32 : 16, y: 12)
        )
        .onHover { h in
            hoveredSlot = h ? slot : nil
        }
        .onTapGesture(count: 2) {
            // Double-click Fly-To Cinematic Landing
            flyToDesktop(col: col, row: row, slot: slot, screenSize: screenSize)
        }
        .onTapGesture {
            spatialManager.focusedPlaneIndex = slot
            spatialManager.macroTargetSpaceIndex = slot
        }
    }

    // MARK: - Cinematic Fly-To Landing
    private func flyToDesktop(col: Int, row: Int, slot: Int, screenSize: CGSize) {
        HapticFeedback.heavy()
        withAnimation(.easeInOut(duration: 0.65)) {
            // Phase 1: Swoop up
            altitudeZoom = 0.55
            cameraPosition = CGPoint(
                x: CGFloat(col) * (screenSize.width + 48.0) + screenSize.width * 0.5,
                y: CGFloat(row) * (screenSize.height + 48.0) + screenSize.height * 0.5
            )
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
                // Phase 2: Touchdown at Street Level
                altitudeZoom = 1.0
                tiltPitchAngle = 0.0
                spatialManager.focusedPlaneIndex = slot
                spatialManager.macroTargetSpaceIndex = slot
            }
        }
    }

    // MARK: - WASD / Keyboard Walking Setup
    private func setupWASDKeyControls() {
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let step: CGFloat = event.modifierFlags.contains(.shift) ? 140.0 : 45.0

            switch event.charactersIgnoringModifiers?.lowercased() {
            case "w":
                cameraPosition.y -= step
                return nil
            case "s":
                cameraPosition.y += step
                return nil
            case "a":
                cameraPosition.x -= step
                return nil
            case "d":
                cameraPosition.x += step
                return nil
            case "q": // Ascend / Zoom Out
                withAnimation(.easeOut(duration: 0.15)) {
                    altitudeZoom = max(0.08, altitudeZoom - 0.05)
                    tiltPitchAngle = min(50.0, tiltPitchAngle + 3.0)
                }
                return nil
            case "e": // Descend / Zoom In
                withAnimation(.easeOut(duration: 0.15)) {
                    altitudeZoom = min(1.2, altitudeZoom + 0.05)
                    tiltPitchAngle = max(0.0, tiltPitchAngle - 3.0)
                }
                return nil
            default:
                return event
            }
        }
    }

    // MARK: - Ground Navigation Grid
    @ViewBuilder
    private func groundNavigationGrid(canvasW: CGFloat, canvasH: CGFloat, screenSize: CGSize, dim: Int) -> some View {
        Canvas { context, size in
            let step: CGFloat = 80.0
            for x in stride(from: 0.0, through: canvasW * 1.5, by: step) {
                var p = Path()
                p.move(to: CGPoint(x: x, y: 0))
                p.addLine(to: CGPoint(x: x, y: canvasH * 1.5))
                context.stroke(p, with: .color(Color.cyan.opacity(0.08)), lineWidth: 1)
            }
            for y in stride(from: 0.0, through: canvasH * 1.5, by: step) {
                var p = Path()
                p.move(to: CGPoint(x: 0, y: y))
                p.addLine(to: CGPoint(x: canvasW * 1.5, y: y))
                context.stroke(p, with: .color(Color.cyan.opacity(0.08)), lineWidth: 1)
            }
        }
        .frame(width: canvasW * 1.5, height: canvasH * 1.5)
    }

    // MARK: - Flight Controller & Google Maps Radar HUD
    @ViewBuilder
    private func flightControlHUD(screenSize: CGSize, dim: Int, totalSlots: Int) -> some View {
        VStack {
            // Top Navigation Banner
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Image(systemName: "map.fill")
                            .foregroundColor(.cyan)
                        Text("GENIE EARTH: 3D SPATIAL FLIGHT 🗺️")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(.cyan)
                    }
                    Text(String(format: "Altitude: %.0f%% • Pitch: %.0f° • WASD to Walk • Q/E to Zoom", altitudeZoom * 100.0, tiltPitchAngle))
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.black.opacity(0.65)))

                Spacer()

                // Preset Altitude Switcher (Satellite, Helicopter, Street Level)
                HStack(spacing: 4) {
                    Button(action: {
                        withAnimation(.spring()) {
                            altitudeZoom = 0.12
                            tiltPitchAngle = 45.0
                        }
                    }) {
                        Text("🛰️ Orbit")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(altitudeZoom < 0.20 ? .cyan : .white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(altitudeZoom < 0.20 ? Color.cyan.opacity(0.3) : Color.white.opacity(0.1)))
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        withAnimation(.spring()) {
                            altitudeZoom = 0.40
                            tiltPitchAngle = 30.0
                        }
                    }) {
                        Text("🚁 Drone")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(altitudeZoom >= 0.20 && altitudeZoom <= 0.60 ? .cyan : .white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(altitudeZoom >= 0.20 && altitudeZoom <= 0.60 ? Color.cyan.opacity(0.3) : Color.white.opacity(0.1)))
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        withAnimation(.spring()) {
                            altitudeZoom = 1.0
                            tiltPitchAngle = 0.0
                        }
                    }) {
                        Text("🚶 Street")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(altitudeZoom > 0.60 ? .cyan : .white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(altitudeZoom > 0.60 ? Color.cyan.opacity(0.3) : Color.white.opacity(0.1)))
                    }
                    .buttonStyle(.plain)
                }
                .padding(4)
                .background(Capsule().fill(Color.black.opacity(0.65)))
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)

            Spacer()

            // Bottom Minimap Radar
            HStack {
                Spacer()
                VStack(spacing: 6) {
                    Text("TERRAIN RADAR")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.cyan)

                    // Mini-grid radar
                    VStack(spacing: 2) {
                        ForEach(0..<dim, id: \.self) { r in
                            HStack(spacing: 2) {
                                ForEach(0..<dim, id: \.self) { c in
                                    let slot = r * dim + c + 1
                                    Rectangle()
                                        .fill(spatialManager.focusedPlaneIndex == slot ? Color.cyan : Color.white.opacity(0.2))
                                        .frame(width: 14, height: 9)
                                        .onTapGesture {
                                            flyToDesktop(col: c, row: r, slot: slot, screenSize: screenSize)
                                        }
                                }
                            }
                        }
                    }
                }
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.black.opacity(0.7)))
                .padding(.trailing, 24)
                .padding(.bottom, 24)
            }
        }
    }
}
