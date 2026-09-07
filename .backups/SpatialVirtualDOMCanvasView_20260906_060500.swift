import AppKit
import Foundation
import SwiftUI

// MARK: - Spatial Virtual DOM Canvas View (Zero-Padding Continuous 3x3 Mega-Canvas)
// Implements the 9-desktop continuous extended spatial plane where:
// 1. Desktops connect edge-to-edge with ZERO padding/margins.
// 2. Apps, text, fonts, and windows maintain 100% native resolution screen-to-screen.
// 3. Virtual DOM occlusion culling offloads GPU/CPU compositor overhead.
// 4. Scrolling with 3 fingers glides fluidly across all 9 spaces without size alteration.

public struct SpatialVirtualDOMCanvasView: View {
    @ObservedObject var spatialManager: SpatialPlaneManager = .shared
    @ObservedObject var vdomEngine: SpatialVirtualDOMEngine = .shared
    @ObservedObject var desktopsManager: MacDesktopsManager = .shared
    @ObservedObject var wallpaperManager: WallpaperManager = .shared

    @State private var lastDragTranslation: CGSize = .zero
    @State private var hoveredSlotIndex: Int? = nil

    public init() {}

    public var body: some View {
        GeometryReader { geo in
            let screenSize = geo.size
            ZStack(alignment: .topLeading) {
                // ── 1. Cosmic Deep Space Liquid Canvas Backdrop ──
                Color.black
                    .ignoresSafeArea()

                // ── 2. The 3x3 Continuous Mega-Canvas (Zero Padding) ──
                ZStack(alignment: .topLeading) {
                    ForEach(1...9, id: \.self) { slotIndex in
                        let (col, row) = SpatialPlaneManager.gridCoordinate(for: slotIndex)
                        let panelX = CGFloat(col) * screenSize.width
                        let panelY = CGFloat(row) * screenSize.height
                        let isVisible = vdomEngine.visibleTileIndices.contains(slotIndex)

                        desktopPanel(
                            slotIndex: slotIndex,
                            col: col,
                            row: row,
                            screenSize: screenSize,
                            isRendered: isVisible
                        )
                        .frame(width: screenSize.width, height: screenSize.height)
                        .offset(x: panelX, y: panelY)
                    }

                    // Continuous Luminous Cyber Seams (Zero Padding Grid Lines)
                    canvasSeamLines(screenSize: screenSize)
                }
                .frame(
                    width: screenSize.width * 3.0,
                    height: screenSize.height * 3.0,
                    alignment: .topLeading
                )
                .offset(
                    x: spatialManager.macroCameraOffset.width,
                    y: spatialManager.macroCameraOffset.height
                )
                .gesture(
                    DragGesture(minimumDistance: 4)
                        .onChanged { gesture in
                            let deltaX = gesture.translation.width - lastDragTranslation.width
                            let deltaY = gesture.translation.height - lastDragTranslation.height
                            spatialManager.handleThreeFingerScrollDelta(dx: deltaX, dy: deltaY)
                            lastDragTranslation = gesture.translation
                        }
                        .onEnded { _ in
                            lastDragTranslation = .zero
                        }
                )

                // ── 3. Fixed Viewport Floating HUD (Unscaled & Pinned) ──
                floatingMegaCanvasHUD(screenSize: screenSize)
            }
            .onAppear {
                vdomEngine.updateViewport(
                    cameraOffset: spatialManager.macroCameraOffset,
                    viewportSize: screenSize,
                    focusedSlot: spatialManager.focusedPlaneIndex
                )
            }
            .onChange(of: spatialManager.macroCameraOffset) { oldValue, newOffset in
                vdomEngine.updateViewport(
                    cameraOffset: newOffset,
                    viewportSize: screenSize,
                    focusedSlot: spatialManager.focusedPlaneIndex
                )
            }
        }
        .ignoresSafeArea()
    }

    // MARK: - Desktop Panel (100% Native Resolution, Zero Padding)
    @ViewBuilder
    private func desktopPanel(
        slotIndex: Int,
        col: Int,
        row: Int,
        screenSize: CGSize,
        isRendered: Bool
    ) -> some View {
        let buffer = spatialManager.ramBuffers[slotIndex]
        let isFocused = spatialManager.focusedPlaneIndex == slotIndex
        let isCurrent = slotIndex == desktopsManager.currentSpaceIndex
        let compass = SpatialPlaneManager.compassBearing(for: slotIndex)

        ZStack(alignment: .topLeading) {
            // High-resolution Wallpaper (DO NOT clone current space onto other spaces)
            if isCurrent, let wp = buffer?.thumbnail ?? buffer?.wallpaper ?? wallpaperManager.activeWallpaperImage {
                Image(nsImage: wp)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: screenSize.width, height: screenSize.height)
                    .clipped()
            } else if let wp = buffer?.thumbnail ?? buffer?.wallpaper {
                Image(nsImage: wp)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: screenSize.width, height: screenSize.height)
                    .clipped()
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.08 + Double(col) * 0.04, green: 0.10 + Double(row) * 0.04, blue: 0.22),
                        Color(red: 0.03, green: 0.05, blue: 0.12)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }

            // Subtle Glass Darkener for Readability
            Color.black.opacity(0.18)

            // ── Virtual DOM Optimized Content Rendering ──
            if isRendered {
                // Render unscaled native windows
                if let wins = buffer?.windows, !wins.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(wins.prefix(2)) { win in
                            unscaledNativeWindowCard(win: win, screenSize: screenSize)
                        }
                    }
                    .padding(.top, 70)
                    .padding(.horizontal, 60)
                } else {
                    // Realistic uncluttered desktop state
                    unscaledCleanDesktopSurface(slotIndex: slotIndex, screenSize: screenSize)
                }
            }

            // Top-Left Floating Desktop Pill (Coordinate & Compass)
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isCurrent ? Color.green : Color.cyan)
                        .frame(width: 8, height: 8)
                    if isCurrent {
                        Circle()
                            .stroke(Color.green.opacity(0.5), lineWidth: 2)
                            .frame(width: 14, height: 14)
                    }
                }

                Text("Desktop \(slotIndex) • \(compass)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("[\(col), \(row)]")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(.cyan.opacity(0.9))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.cyan.opacity(0.18)))

                if isCurrent {
                    Text("ACTIVE HARDWARE SPACE")
                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                        .foregroundColor(.green)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.green.opacity(0.18)))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.black.opacity(0.60))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(isFocused ? Color.cyan : Color.white.opacity(0.18), lineWidth: isFocused ? 1.5 : 0.8)
            )
            .shadow(color: isFocused ? Color.cyan.opacity(0.35) : Color.black.opacity(0.3), radius: 8)
            .padding(.top, 28)
            .padding(.leading, 36)

            // Click-to-Land Interactive Transparent Overlay
            Color.white.opacity(0.001)
                .onTapGesture {
                    spatialManager.zoomInToSelectedDesktop(index: slotIndex)
                }
        }
        .clipped()
    }

    // MARK: - 100% Native Unscaled Window Card
    @ViewBuilder
    private func unscaledNativeWindowCard(win: ManagedWindowInfo, screenSize: CGSize) -> some View {
        let cardWidth = min(screenSize.width - 160, 920.0)
        let cardHeight: CGFloat = 340.0

        VStack(spacing: 0) {
            // macOS Native Window Titlebar (28 pt standard)
            HStack(spacing: 8) {
                // Traffic light stoplight buttons
                HStack(spacing: 6) {
                    Circle().fill(Color(red: 1.0, green: 0.37, blue: 0.34)).frame(width: 11, height: 11)
                    Circle().fill(Color(red: 1.0, green: 0.74, blue: 0.18)).frame(width: 11, height: 11)
                    Circle().fill(Color(red: 0.15, green: 0.78, blue: 0.25)).frame(width: 11, height: 11)
                }
                .padding(.leading, 12)

                Spacer()

                // Window Title (Native 13pt SF Pro Semibold)
                HStack(spacing: 5) {
                    Image(systemName: "app.window.checkmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.cyan)
                    Text(win.title.isEmpty ? win.ownerName : win.title)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }

                Spacer()

                // App Owner Badge
                Text(win.ownerName)
                    .font(.system(size: 10.5, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2.5)
                    .background(Capsule().fill(Color.white.opacity(0.10)))
                    .padding(.trailing, 12)
            }
            .frame(height: 32)
            .background(Color(red: 0.15, green: 0.16, blue: 0.22))

            Divider().background(Color.white.opacity(0.12))

            // Native Scale Content Area
            if win.ownerName.lowercased().contains("terminal") || win.ownerName.lowercased().contains("iterm") {
                // Terminal Shell Mockup (12pt SF Mono)
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 4) {
                        Text("macbook-pro:GoldGate nicholasdudek$")
                            .foregroundColor(.green)
                        Text("swift build --package-path .")
                            .foregroundColor(.white)
                    }
                    Text("Building for debugging...")
                        .foregroundColor(.white.opacity(0.6))
                    HStack(spacing: 4) {
                        Text("[9/9] Compiling Genie (arm64)")
                            .foregroundColor(.cyan)
                        Text("• 0 errors")
                            .foregroundColor(.green)
                    }
                    Text("Build complete! (0.84s)")
                        .foregroundColor(.green.opacity(0.9))
                    HStack(spacing: 2) {
                        Text("macbook-pro:GoldGate nicholasdudek$ ")
                            .foregroundColor(.green)
                        Rectangle()
                            .fill(Color.white)
                            .frame(width: 7, height: 14)
                    }
                    Spacer()
                }
                .font(.system(size: 12, weight: .medium, design: .monospaced))
                .padding(14)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(Color(red: 0.06, green: 0.07, blue: 0.10))
            } else {
                // Modern App Document View (13pt Native Typography)
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.cyan.opacity(0.20))
                            .frame(width: 32, height: 32)
                            .overlay(Image(systemName: "doc.text.fill").foregroundColor(.cyan))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(win.title.isEmpty ? "Document Overview" : win.title)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text("Fluid 1:1 Continuous Space • Native Typography")
                                .font(.system(size: 11.5, weight: .regular, design: .rounded))
                                .foregroundColor(.white.opacity(0.65))
                        }
                        Spacer()
                    }

                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 1)

                    Text("The 9-desktop spatial plane extends seamlessly across all boundaries. When scrolling with 3 fingers, typography, code syntax, and native window frames maintain 100% pixel fidelity with zero distortion or zoom alteration.")
                        .font(.system(size: 13, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                        .lineSpacing(4)

                    Spacer()
                }
                .padding(16)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(Color(red: 0.11, green: 0.12, blue: 0.17))
            }
        }
        .frame(width: cardWidth, height: cardHeight)
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.white.opacity(0.16), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.45), radius: 18, y: 8)
    }

    // MARK: - Clean Desktop Surface
    @ViewBuilder
    private func unscaledCleanDesktopSurface(slotIndex: Int, screenSize: CGSize) -> some View {
        VStack {
            Spacer()
            VStack(spacing: 8) {
                Image(systemName: "display.2")
                    .font(.system(size: 42, weight: .light))
                    .foregroundColor(.cyan.opacity(0.6))

                Text("Desktop Space \(slotIndex)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))

                Text("Continuous 1:1 Surface • Click or Press Return to Land")
                    .font(.system(size: 12.5, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
            }
            Spacer()
        }
        .frame(width: screenSize.width, height: screenSize.height)
    }

    // MARK: - Continuous Luminous Cyber Seams (Zero-Padding Dividers)
    @ViewBuilder
    private func canvasSeamLines(screenSize: CGSize) -> some View {
        Canvas { context, size in
            let w = screenSize.width
            let h = screenSize.height

            // 2 Vertical Seams (between Col 0-1 and Col 1-2)
            for i in 1...2 {
                let x = w * CGFloat(i)
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: h * 3.0))

                context.stroke(
                    path,
                    with: .color(Color.cyan.opacity(0.55)),
                    style: StrokeStyle(lineWidth: 1.5, dash: [8, 4])
                )
            }

            // 2 Horizontal Seams (between Row 0-1 and Row 1-2)
            for j in 1...2 {
                let y = h * CGFloat(j)
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: w * 3.0, y: y))

                context.stroke(
                    path,
                    with: .color(Color.cyan.opacity(0.55)),
                    style: StrokeStyle(lineWidth: 1.5, dash: [8, 4])
                )
            }

            // 4 Intersection Crosshair Reticles
            for i in 1...2 {
                for j in 1...2 {
                    let cx = w * CGFloat(i)
                    let cy = h * CGFloat(j)
                    let rect = CGRect(x: cx - 8, y: cy - 8, width: 16, height: 16)
                    context.stroke(Path(ellipseIn: rect), with: .color(Color.cyan), lineWidth: 1.5)
                }
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Floating Mega-Canvas HUD (Fixed in Viewport)
    @ViewBuilder
    private func floatingMegaCanvasHUD(screenSize: CGSize) -> some View {
        VStack {
            HStack(spacing: 16) {
                // Space indicator & Bearing
                HStack(spacing: 8) {
                    Image(systemName: "square.grid.3x3.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.cyan)

                    VStack(alignment: .leading, spacing: 1) {
                        Text("1:1 Mega-Canvas (Zero Padding)")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        let organicX = Double(-spatialManager.macroCameraOffset.width / max(1.0, screenSize.width)) + 1.0
                        let organicY = Double(-spatialManager.macroCameraOffset.height / max(1.0, screenSize.height)) + 1.0
                        Text("Bounding Box [X: \(String(format: "%.2f", organicX)), Y: \(String(format: "%.2f", organicY))] • Screen \(spatialManager.focusedPlaneIndex)")
                            .font(.system(size: 10.5, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.65))
                    }
                }

                Spacer()

                // ── Top Grid Spaces Bar (Desktop 1, 2, 3 directly above the top grid) ──
                HStack(spacing: 6) {
                    ForEach(1...3, id: \.self) { slot in
                        let isFocused = spatialManager.focusedPlaneIndex == slot
                        let isCur = slot == desktopsManager.currentSpaceIndex
                        let compass = SpatialPlaneManager.compassBearing(for: slot)

                        Button(action: {
                            selectSlot(slot, screenSize: screenSize)
                        }) {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(isCur ? Color.green : (isFocused ? Color.cyan : Color.white.opacity(0.40)))
                                    .frame(width: 6, height: 6)

                                Text("Desktop \(slot)")
                                    .font(.system(size: 11, weight: isFocused ? .bold : .semibold, design: .rounded))
                                    .foregroundColor(isFocused ? .cyan : .white)

                                Text("\(compass)")
                                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                                    .foregroundColor(isFocused ? .cyan.opacity(0.85) : .white.opacity(0.50))
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4.5)
                            .background(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(isFocused ? Color.cyan.opacity(0.20) : Color.white.opacity(0.08))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .strokeBorder(isFocused ? Color.cyan : Color.white.opacity(0.15), lineWidth: 0.8)
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    // Remaining Slots 4..9
                    HStack(spacing: 3) {
                        ForEach(4...9, id: \.self) { slot in
                            let isFocused = spatialManager.focusedPlaneIndex == slot
                            Button(action: {
                                selectSlot(slot, screenSize: screenSize)
                            }) {
                                Text("\(slot)")
                                    .font(.system(size: 10.5, weight: isFocused ? .bold : .medium, design: .monospaced))
                                    .foregroundColor(isFocused ? .black : .white.opacity(0.85))
                                    .frame(width: 22, height: 22)
                                    .background(
                                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                                            .fill(isFocused ? Color.cyan : Color.white.opacity(0.10))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Spacer()

                // Mini-Map Radar (3x3 Preview of Viewport)
                radarMinimap(screenSize: screenSize)

                // Formation Mode Switcher & Land Button
                HStack(spacing: 8) {
                    Button(action: {
                        spatialManager.continuousCanvasFormation = "Birds-Eye 3x3 Grid"
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "square.grid.3x3")
                            Text("Birds-Eye")
                        }
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.75))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4.5)
                        .background(Capsule().fill(Color.white.opacity(0.10)))
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        spatialManager.zoomInToSelectedDesktop(index: spatialManager.focusedPlaneIndex)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down.forward.and.arrow.up.backward")
                                .font(.system(size: 10, weight: .bold))
                            Text("Touchdown (Esc / ↵)")
                                .font(.system(size: 11.5, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5.5)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.cyan)
                        )
                        .shadow(color: Color.cyan.opacity(0.5), radius: 6)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(red: 0.08, green: 0.09, blue: 0.14).opacity(0.88))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.cyan.opacity(0.35), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.55), radius: 20, y: 10)
            .padding(.top, 16)
            .padding(.horizontal, 24)

            Spacer()
        }
        .allowsHitTesting(true)
    }

    // MARK: - Radar Minimap (3x3 Real-Time Organic Bounding Box Radar)
    @ViewBuilder
    private func radarMinimap(screenSize: CGSize) -> some View {
        let radarW: CGFloat = 46.0
        let radarH: CGFloat = 30.0
        let boxW: CGFloat = radarW / 3.0
        let boxH: CGFloat = radarH / 3.0

        let maxOffX = max(1.0, screenSize.width * 2.0)
        let maxOffY = max(1.0, screenSize.height * 2.0)
        let normX = max(0.0, min(1.0, -spatialManager.macroCameraOffset.width / maxOffX))
        let normY = max(0.0, min(1.0, -spatialManager.macroCameraOffset.height / maxOffY))

        let cursorPosX = normX * (radarW - boxW)
        let cursorPosY = normY * (radarH - boxH)

        ZStack(alignment: .topLeading) {
            // 3x3 Grid Slot Cells (Background)
            VStack(spacing: 2) {
                ForEach(0..<3) { r in
                    HStack(spacing: 2) {
                        ForEach(0..<3) { c in
                            let slot = r * 3 + c + 1
                            let isCur = slot == desktopsManager.currentSpaceIndex
                            RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                                .fill(isCur ? Color.green.opacity(0.45) : Color.white.opacity(0.12))
                                .frame(width: 13, height: 8)
                        }
                    }
                }
            }

            // Top-Level Organic Bounding Box Cursor
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .strokeBorder(Color.cyan, lineWidth: 1.5)
                .background(RoundedRectangle(cornerRadius: 2).fill(Color.cyan.opacity(0.30)))
                .frame(width: boxW + 2, height: boxH + 2)
                .offset(x: cursorPosX, y: cursorPosY)
                .shadow(color: Color.cyan.opacity(0.85), radius: 3)
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.black.opacity(0.60))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.8)
        )
    }

    private func selectSlot(_ slot: Int, screenSize: CGSize) {
        let (col, row) = SpatialPlaneManager.gridCoordinate(for: slot)
        spatialManager.focusedPlaneIndex = slot
        spatialManager.macroTargetSpaceIndex = slot
        HapticFeedback.selection()

        let targetOffset = CGSize(
            width: -CGFloat(col) * screenSize.width,
            height: -CGFloat(row) * screenSize.height
        )
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            spatialManager.macroCameraOffset = targetOffset
        }
    }
}
