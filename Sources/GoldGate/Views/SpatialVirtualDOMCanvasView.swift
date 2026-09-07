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
    @ObservedObject var faceTracker: SpatialFaceTrackingManager = .shared

    @State private var lastDragTranslation: CGSize = .zero
    @State private var hoveredSlotIndex: Int? = nil

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
                // ── 1. Cosmic Deep Space Liquid Canvas Backdrop ──
                Color.black
                    .ignoresSafeArea()

                // ── 2. The Continuous Mega-Canvas (Zero Padding 9x9 Universe / 3x3 Pixel) ──
                ZStack(alignment: .topLeading) {
                    ForEach(1...totalSlots, id: \.self) { slotIndex in
                        let (col, row) = is81 ? SpatialPlaneManager.universeCoordinate(for: slotIndex) : SpatialPlaneManager.gridCoordinate(for: slotIndex)
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

                    // Continuous Luminous Cyber Seams (Macro-Pixel Borders & Sub-Screen Seams)
                    canvasSeamLines(screenSize: screenSize, dimension: dim)

                    // High-Tech Rectangle Scanner Reticle Frame
                    RectangleScannerReticleView(
                        screenSize: screenSize,
                        focusedIndex: spatialManager.focusedPlaneIndex,
                        isUniverse81: is81
                    )
                }
                .frame(
                    width: canvasW,
                    height: canvasH,
                    alignment: .topLeading
                )
                .scaleEffect(spatialManager.vectorZoomScale, anchor: .topLeading)
                .offset(
                    x: spatialManager.macroCameraOffset.width,
                    y: spatialManager.macroCameraOffset.height
                )

                // ── 3. Clean Grid Zoom HUD (Fits 3x3, 2x2, 2 Screens, or 1x1) ──
                cleanGridPickerHUD(screenSize: screenSize)
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

                // App Owner & Space Transfer Menu
                Menu {
                    Text("Move \(win.ownerName) to:")
                        .font(.caption)
                    Divider()
                    ForEach(1...9, id: \.self) { targetSlot in
                        Button("Desktop \(targetSlot) • \(SpatialPlaneManager.compassBearing(for: targetSlot))") {
                            SmartGridManager.shared.moveAppToDesktop(pid: win.pid, targetDesktopIndex: targetSlot)
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(win.ownerName)
                            .font(.system(size: 10.5, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.85))
                        Image(systemName: "arrow.up.and.down.square")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.cyan)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2.5)
                    .background(Capsule().fill(Color.white.opacity(0.12)))
                }
                .menuStyle(.borderlessButton)
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

    // MARK: - Continuous Luminous Cyber Seams (Zero-Padding Dividers & Macro-Pixel Borders)
    @ViewBuilder
    private func canvasSeamLines(screenSize: CGSize, dimension: Int) -> some View {
        Canvas { context, size in
            let w = screenSize.width
            let h = screenSize.height
            let dim = CGFloat(dimension)

            // Vertical Seams
            for i in 1..<dimension {
                let x = w * CGFloat(i)
                let isMacroBorder = (i % 3 == 0) // Macro-Pixel Sector Boundary
                var path = Path()
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: h * dim))

                if isMacroBorder {
                    // Thick glowing Cyan border between Macro-Pixels
                    context.stroke(
                        path,
                        with: .color(Color.cyan.opacity(0.85)),
                        style: StrokeStyle(lineWidth: 2.5)
                    )
                } else {
                    // Subtle dashed seam between physical screens
                    context.stroke(
                        path,
                        with: .color(Color.cyan.opacity(0.35)),
                        style: StrokeStyle(lineWidth: 1.0, dash: [6, 4])
                    )
                }
            }

            // Horizontal Seams
            for j in 1..<dimension {
                let y = h * CGFloat(j)
                let isMacroBorder = (j % 3 == 0) // Macro-Pixel Sector Boundary
                var path = Path()
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: w * dim, y: y))

                if isMacroBorder {
                    context.stroke(
                        path,
                        with: .color(Color.cyan.opacity(0.85)),
                        style: StrokeStyle(lineWidth: 2.5)
                    )
                } else {
                    context.stroke(
                        path,
                        with: .color(Color.cyan.opacity(0.35)),
                        style: StrokeStyle(lineWidth: 1.0, dash: [6, 4])
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Clean Floating Grid Zoom Mode Picker HUD (3x3, 2x2, 2 Screens, 1x1)
    private func cleanGridPickerHUD(screenSize: CGSize) -> some View {
        VStack {
            HStack(spacing: 10) {
                gridModePill(title: "2×2 Grid", mode: "2x2 Grid", scale: 0.50)
                gridModePill(title: "2 Screens", mode: "2 Screens (Side-by-Side)", scale: 0.50)
                gridModePill(title: "1×1 Desktop", mode: "1x1 Desktop", scale: 1.0)

                Spacer()

                Button(action: {
                    spatialManager.zoomInToSelectedDesktop()
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "xmark.circle.fill")
                        Text("Exit Overview")
                    }
                    .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.white.opacity(0.15)))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.black.opacity(0.75))
            )
            .padding(.top, 14)
            .padding(.horizontal, 24)

            Spacer()
        }
    }

    private func gridModePill(title: String, mode: String, scale: CGFloat) -> some View {
        let isSelected = spatialManager.gridZoomFitMode == mode
        return Button(action: {
            spatialManager.gridZoomFitMode = mode
            withAnimation(.spring(response: 0.30, dampingFraction: 0.85)) {
                spatialManager.vectorZoomScale = scale
                spatialManager.macroCameraOffset = .zero
            }
            HapticFeedback.tick()
        }) {
            Text(title)
                .font(.system(size: 11.5, weight: isSelected ? .bold : .medium, design: .rounded))
                .foregroundColor(isSelected ? .black : .white)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.white : Color.white.opacity(0.15))
                )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Floating Mega-Canvas HUD (Fixed in Viewport)
    @ViewBuilder
    private func floatingMegaCanvasHUD(screenSize: CGSize) -> some View {
        VStack {
            HStack(spacing: 14) {
                // Universe indicator & Bearing
                HStack(spacing: 8) {
                    Image(systemName: "square.grid.3x3.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.cyan)

                    VStack(alignment: .leading, spacing: 1) {
                        Text("Default Desktop: 9×9 = 81 Big Screen")
                            .font(.system(size: 12.5, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        let organicX = Double(-spatialManager.macroCameraOffset.width / max(1.0, screenSize.width)) + 1.0
                        let organicY = Double(-spatialManager.macroCameraOffset.height / max(1.0, screenSize.height)) + 1.0
                        let compass = SpatialPlaneManager.compassBearing(for: spatialManager.activeMacroPixelSector)
                        Text("Pixel Size: 3×3 (Sector \(spatialManager.activeMacroPixelSector): \(compass)) • Screen \(spatialManager.focusedPlaneIndex) • [X: \(String(format: "%.2f", organicX)), Y: \(String(format: "%.2f", organicY))]")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.65))
                    }
                }

                Spacer()

                // ── Face Tracking Parallax Button ──
                Button(action: {
                    faceTracker.toggleFaceTracking()
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: faceTracker.isFaceTrackingEnabled ? "person.crop.circle.badge.checkmark" : "person.crop.circle.badge.xmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(faceTracker.isFaceTrackingEnabled ? .green : .white.opacity(0.6))
                        Text(faceTracker.isFaceTrackingEnabled ? "Face Parallax ON" : "Face Parallax")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(faceTracker.isFaceTrackingEnabled ? .green : .white.opacity(0.8))
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(faceTracker.isFaceTrackingEnabled ? Color.green.opacity(0.18) : Color.white.opacity(0.08))
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(faceTracker.isFaceTrackingEnabled ? Color.green.opacity(0.5) : Color.white.opacity(0.15), lineWidth: 0.8)
                    )
                }
                .buttonStyle(.plain)
                .help("Face Tracking: Lean back to see all screens, or turn head to pan")

                // ── Top Grid Spaces Bar (9 Macro-Pixel Sectors) ──
                HStack(spacing: 4) {
                    ForEach(1...9, id: \.self) { sector in
                        let isFocusedSector = spatialManager.activeMacroPixelSector == sector
                        let compass = SpatialPlaneManager.compassBearing(for: sector)
                        Button(action: {
                            spatialManager.teleportToSector(sector, screenSize: screenSize)
                        }) {
                            HStack(spacing: 3) {
                                if sector == 5 {
                                    Image(systemName: "star.fill").font(.system(size: 7)).foregroundColor(isFocusedSector ? .black : .yellow)
                                }
                                Text("S\(sector)")
                                    .font(.system(size: 9.5, weight: isFocusedSector ? .bold : .semibold, design: .monospaced))
                                    .foregroundColor(isFocusedSector ? .black : .white)
                            }
                            .padding(.horizontal, 5.5)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .fill(isFocusedSector ? Color.cyan : Color.white.opacity(0.10))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .strokeBorder(isFocusedSector ? Color.cyan : Color.white.opacity(0.12), lineWidth: 0.8)
                            )
                        }
                        .buttonStyle(.plain)
                        .help("Macro-Pixel Sector \(sector): \(compass) (3x3 Screens)")
                    }
                }

                Spacer()

                // Mini-Map Radar (9x9 Universe Preview)
                radarMinimap(screenSize: screenSize)

                // ── Webpage Screen Movement Mode: Hand Grab vs Follow Cursor ──
                HStack(spacing: 2) {
                    Button(action: {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                            spatialManager.screenWebpagePanMode = "Hand Drag & Scroll"
                            spatialManager.cursorFollowPanningEnabled = false
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "hand.draw.fill")
                                .font(.system(size: 10))
                            Text("Hand Grab")
                                .font(.system(size: 11, weight: spatialManager.screenWebpagePanMode == "Hand Drag & Scroll" ? .bold : .medium, design: .rounded))
                        }
                        .foregroundColor(spatialManager.screenWebpagePanMode == "Hand Drag & Scroll" ? .black : .white.opacity(0.80))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4.5)
                        .background(
                            Capsule().fill(spatialManager.screenWebpagePanMode == "Hand Drag & Scroll" ? Color.cyan : Color.white.opacity(0.08))
                        )
                    }
                    .buttonStyle(.plain)
                    .help("Hand Grab: Click & drag anywhere to move screen, flick to glide, 2-finger scroll, click space to land")

                    Button(action: {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                            spatialManager.screenWebpagePanMode = "Screen Follows Cursor"
                            spatialManager.cursorFollowPanningEnabled = true
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "cursorarrow.motionlines")
                                .font(.system(size: 10))
                            Text("Follow Cursor")
                                .font(.system(size: 11, weight: spatialManager.screenWebpagePanMode == "Screen Follows Cursor" ? .bold : .medium, design: .rounded))
                        }
                        .foregroundColor(spatialManager.screenWebpagePanMode == "Screen Follows Cursor" ? .black : .white.opacity(0.80))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4.5)
                        .background(
                            Capsule().fill(spatialManager.screenWebpagePanMode == "Screen Follows Cursor" ? Color.cyan : Color.white.opacity(0.08))
                        )
                    }
                    .buttonStyle(.plain)
                    .help("Follow Cursor: Simply move your cursor across the screen to glide the camera viewport")
                }
                .padding(2)
                .background(Capsule().fill(Color.black.opacity(0.40)))
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.12), lineWidth: 0.8))

                // ── Second Control View (Spatial & Display Controls) ──
                Button(action: {
                    SecondaryControlCenterPopoverManager.shared.toggle()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "slider.horizontal.2.square")
                            .font(.system(size: 10, weight: .bold))
                        Text("Controls")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.cyan.opacity(0.18))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(Color.cyan.opacity(0.35), lineWidth: 0.8)
                    )
                }
                .buttonStyle(.plain)
                .help("Open Spatial & Display Geometry Controls")

                // Touchdown / Land Button
                Button(action: {
                    spatialManager.zoomInToSelectedDesktop(index: spatialManager.focusedPlaneIndex)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.forward.and.arrow.up.backward")
                            .font(.system(size: 10, weight: .bold))
                        Text("Touchdown (Esc / ↵)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.black)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.cyan)
                    )
                    .shadow(color: Color.cyan.opacity(0.5), radius: 6)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 9)
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

    // MARK: - Radar Minimap (9x9 Universe with 3x3 Macro-Pixel Bounding Box)
    @ViewBuilder
    private func radarMinimap(screenSize: CGSize) -> some View {
        let is81 = spatialManager.isUniverse81Active
        let dim = is81 ? 9 : 3
        let radarW: CGFloat = is81 ? 64.0 : 46.0
        let radarH: CGFloat = is81 ? 40.0 : 30.0
        let boxW: CGFloat = radarW / CGFloat(dim)
        let boxH: CGFloat = radarH / CGFloat(dim)

        let maxOffX = max(1.0, screenSize.width * CGFloat(dim - 1))
        let maxOffY = max(1.0, screenSize.height * CGFloat(dim - 1))
        let normX = max(0.0, min(1.0, -spatialManager.macroCameraOffset.width / maxOffX))
        let normY = max(0.0, min(1.0, -spatialManager.macroCameraOffset.height / maxOffY))

        let cursorPosX = normX * (radarW - boxW)
        let cursorPosY = normY * (radarH - boxH)

        ZStack(alignment: .topLeading) {
            // Grid Slot Cells
            VStack(spacing: 1.5) {
                ForEach(0..<dim, id: \.self) { r in
                    HStack(spacing: 1.5) {
                        ForEach(0..<dim, id: \.self) { c in
                            let slot = is81 ? SpatialPlaneManager.indexForUniverse(col: c, row: r) : SpatialPlaneManager.indexForGrid(col: c, row: r)
                            let isCur = slot == desktopsManager.currentSpaceIndex
                            let (sector, _, _, _) = SpatialPlaneManager.macroPixelSector(for: slot)
                            let isCurSector = is81 && (sector == spatialManager.activeMacroPixelSector)

                            RoundedRectangle(cornerRadius: 1.0, style: .continuous)
                                .fill(
                                    isCur ? Color.green.opacity(0.70) :
                                    (isCurSector ? Color.cyan.opacity(0.35) : Color.white.opacity(0.12))
                                )
                                .frame(width: is81 ? 5.2 : 13.0, height: is81 ? 3.0 : 8.0)
                        }
                    }
                }
            }

            // Top-Level Holographic Bounding Box Cursor
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
        let is81 = spatialManager.isUniverse81Active
        let (col, row) = is81 ? SpatialPlaneManager.universeCoordinate(for: slot) : SpatialPlaneManager.gridCoordinate(for: slot)
        spatialManager.focusedPlaneIndex = slot
        spatialManager.macroTargetSpaceIndex = slot
        spatialManager.activeMacroPixelSector = SpatialPlaneManager.macroPixelSector(for: slot).sector
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

// MARK: - Futuristic Rectangle Scanner Reticle
private struct RectangleScannerReticleView: View {
    let screenSize: CGSize
    let focusedIndex: Int
    let isUniverse81: Bool

    @State private var scanPhase: CGFloat = 0.0

    var body: some View {
        let (col, row) = isUniverse81 ? SpatialPlaneManager.universeCoordinate(for: focusedIndex) : SpatialPlaneManager.gridCoordinate(for: focusedIndex)
        let rectX = CGFloat(col) * screenSize.width
        let rectY = CGFloat(row) * screenSize.height

        ZStack(alignment: .topLeading) {
            // Scanner Outer Bounding Glow Frame
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.cyan, Color.purple, Color.cyan.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2.5
                )
                .shadow(color: Color.cyan.opacity(0.8), radius: 12, x: 0, y: 0)

            // Scanning Laser Line
            GeometryReader { geo in
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.clear, Color.cyan.opacity(0.75), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(height: 6)
                    .offset(y: geo.size.height * scanPhase)
                    .shadow(color: Color.cyan, radius: 8)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            // Corner Brackets (High-Tech Scanner Optics)
            VStack {
                HStack {
                    cornerBracket(topLeft: true)
                    Spacer()
                    cornerBracket(topRight: true)
                }
                Spacer()
                HStack {
                    cornerBracket(bottomLeft: true)
                    Spacer()
                    cornerBracket(bottomRight: true)
                }
            }
            .padding(8)

            // Scanner HUD Data Badge
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Circle().fill(Color.cyan).frame(width: 6, height: 6)
                    Text("RECTANGLE SCANNER RETICLE")
                        .font(.system(size: 9.5, weight: .black, design: .monospaced))
                        .foregroundColor(.cyan)
                    Text("● LIVE")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(.green)
                }
                let compass = SpatialPlaneManager.compassBearing(for: focusedIndex)
                Text("SLOT \(focusedIndex) // \(compass) [GRID \(col + 1),\(row + 1)]")
                    .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.85))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.black.opacity(0.75))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.cyan.opacity(0.4), lineWidth: 0.8))
            )
            .padding(14)
        }
        .frame(width: screenSize.width, height: screenSize.height)
        .offset(x: rectX, y: rectY)
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                scanPhase = 0.94
            }
        }
    }

    @ViewBuilder
    private func cornerBracket(topLeft: Bool = false, topRight: Bool = false, bottomLeft: Bool = false, bottomRight: Bool = false) -> some View {
        Path { path in
            let l: CGFloat = 22.0
            if topLeft {
                path.move(to: CGPoint(x: 0, y: l))
                path.addLine(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: l, y: 0))
            } else if topRight {
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: l, y: 0))
                path.addLine(to: CGPoint(x: l, y: l))
            } else if bottomLeft {
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 0, y: l))
                path.addLine(to: CGPoint(x: l, y: l))
            } else if bottomRight {
                path.move(to: CGPoint(x: l, y: 0))
                path.addLine(to: CGPoint(x: l, y: l))
                path.addLine(to: CGPoint(x: 0, y: l))
            }
        }
        .stroke(Color.cyan, style: StrokeStyle(lineWidth: 3, lineCap: .square, lineJoin: .miter))
        .frame(width: 22, height: 22)
        .shadow(color: Color.cyan, radius: 4)
    }
}
