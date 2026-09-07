import AppKit
import Foundation
import SwiftUI

// MARK: - Spatial Desktop Plane Canvas View (3x3 Continuous Extended Virtual Desktops)
// Renders the full 9-desktop spatial plane for laptops, with live RAM-cached previews,
// interactive window repositioning across desktops, and fluid zoom-in/out transitions.
public struct SpatialDesktopPlaneCanvasView: View {
    @ObservedObject var spatialManager: SpatialPlaneManager = .shared
    @ObservedObject var desktopsManager: MacDesktopsManager = .shared
    @ObservedObject var wallpaperManager: WallpaperManager = .shared
    @ObservedObject var wallpaperCanvasEngine: DraggableWallpaperCanvasEngine = .shared

    @State private var hoveredCardIndex: Int? = nil
    @State private var draggedWindow: ManagedWindowInfo? = nil
    @State private var dragSourceDesktop: Int? = nil

    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 18),
        GridItem(.flexible(), spacing: 18),
        GridItem(.flexible(), spacing: 18)
    ]
    private let columns3x3: [GridItem] = Array(repeating: GridItem(.flexible(), spacing: 6), count: 9)

    public init() {}

    public var body: some View {
        ZStack {
            if spatialManager.continuousCanvasFormation == "Unified Panoramic (3 Stations) 🌌" || spatialManager.continuousCanvasFormation == "Unified 3-Station Viewport" {
                if let model = AppModel.shared {
                    UnifiedPanoramicSinglePageCanvasView(appModel: model)
                } else {
                    SpatialVirtualDOMCanvasView()
                }
            } else if spatialManager.continuousCanvasFormation == "Genie Earth Maps 🗺️" {
                GenieEarthSpatialCanvasView()
            } else if spatialManager.continuousCanvasFormation == "Omni-Spherical Dome 🌐" {
                OmniSphericalDesktopDomeView()
            } else if spatialManager.continuousCanvasFormation == "1:1 Continuous Mega-Canvas" {
                // 100% Native Scale SwiftDOM / Virtual DOM Canvas (Zero Padding Edge-to-Edge)
                SpatialVirtualDOMCanvasView()
            } else {
                // ── 1. Cosmic Liquid Glass Backdrop with Parallax Illusion ──
                ZStack {
                    VisualEffectBlur(material: .fullScreenUI, blendingMode: .behindWindow)
                        .ignoresSafeArea()

                    Color.black.opacity(0.68)
                        .ignoresSafeArea()

                    // Subtle 2D Plane Coordinate Grid Lines
                    SpatialPlaneGridLinesView()
                        .opacity(0.25)
                        .ignoresSafeArea()
                }
                .offset(x: wallpaperCanvasEngine.offset(for: .wallpaper).width, y: wallpaperCanvasEngine.offset(for: .wallpaper).height)
                .modifier(ParallaxIllusionGlassModifier(enablesTilt: true, enablesRefraction: true, enablesSpecular: true))

                // ── 2. Main Spatial Canvas Container ──
                VStack(spacing: 14) {
                    // Header Bar with Formation & Add Desktop (1.2x Floating HUD Parallax)
                    spatialHeaderBar
                        .offset(x: wallpaperCanvasEngine.offset(for: .floatingHUD).width, y: wallpaperCanvasEngine.offset(for: .floatingHUD).height)

                    Spacer(minLength: 2)

                    // Continuous Canvas Body (3x3 Plane, 3x3 Universe, or Stacked Vertical Ribbon)
                    ZStack {
                        if spatialManager.continuousCanvasFormation == "Stacked Vertical Ribbon" {
                            ScrollView(.vertical, showsIndicators: true) {
                                VStack(spacing: 18) {
                                    ForEach(1...max(3, desktopsManager.spaces.count), id: \.self) { slotIndex in
                                        spatialDesktopCard(for: slotIndex)
                                            .frame(maxWidth: 820)
                                    }
                                }
                                .padding(.horizontal, 48)
                                .padding(.vertical, 16)
                            }
                        } else if spatialManager.continuousCanvasFormation == "3x3 Universe Overview" || spatialManager.continuousCanvasFormation == "3x3 Fit" {
                            ScrollView([.vertical, .horizontal], showsIndicators: true) {
                                LazyVGrid(columns: columns3x3, spacing: 6) {
                                    ForEach(1...9, id: \.self) { slotIndex in
                                        spatialDesktopCard(for: slotIndex)
                                            .scaleEffect(0.85)
                                    }
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                            }
                        } else {
                            LazyVGrid(columns: columns, spacing: 16) {
                                ForEach(1...9, id: \.self) { slotIndex in
                                    spatialDesktopCard(for: slotIndex)
                                }
                            }
                            .padding(.horizontal, 48)
                            .offset(x: spatialManager.macroCameraOffset.width, y: spatialManager.macroCameraOffset.height)
                            .gesture(
                                DragGesture()
                                    .onChanged { gesture in
                                        spatialManager.macroCameraOffset.width += gesture.translation.width * 0.35
                                        spatialManager.macroCameraOffset.height += gesture.translation.height * 0.35
                                        let maxPan: CGFloat = 360.0
                                        spatialManager.macroCameraOffset.width = max(-maxPan, min(maxPan, spatialManager.macroCameraOffset.width))
                                        spatialManager.macroCameraOffset.height = max(-maxPan, min(maxPan, spatialManager.macroCameraOffset.height))
                                    }
                                    .onEnded { _ in
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                                            let colOffset = Int(round(spatialManager.macroCameraOffset.width / 180.0))
                                            let rowOffset = Int(round(-spatialManager.macroCameraOffset.height / 140.0))
                                            let targetCol = max(0, min(2, 1 + colOffset))
                                            let targetRow = max(0, min(2, 1 + rowOffset))
                                            spatialManager.focusedPlaneIndex = SpatialPlaneManager.indexForGrid(col: targetCol, row: targetRow)
                                            spatialManager.macroTargetSpaceIndex = spatialManager.focusedPlaneIndex
                                        }
                                    }
                            )

                            // ── Top-Level Viewport Bounding Box Cursor (Organic 2D Spatial Cursor) ──
                            if spatialManager.aboveLevelCursorEnabled {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .strokeBorder(
                                            LinearGradient(
                                                colors: [Color.cyan, Color.white, Color.cyan.opacity(0.8)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 2.0
                                        )
                                        .frame(width: 240, height: 155)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .fill(Color.cyan.opacity(0.08))
                                        )
                                        .shadow(color: Color.cyan.opacity(0.70), radius: 16)

                                    // Viewport HUD Badge on Bounding Box
                                    VStack {
                                        HStack(spacing: 4) {
                                            Circle().fill(Color.green).frame(width: 5, height: 5)
                                            Text("VIEWPORT [Desk \(spatialManager.focusedPlaneIndex)]")
                                                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                                                .foregroundColor(.black)
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .background(Capsule().fill(Color.cyan))
                                        .offset(y: -84)

                                        Spacer()
                                    }
                                }
                                .offset(x: spatialManager.macroCameraOffset.width, y: spatialManager.macroCameraOffset.height)
                                .allowsHitTesting(false)
                            }
                        }
                    }
                    .offset(x: wallpaperCanvasEngine.offset(for: .desktopFiles).width, y: wallpaperCanvasEngine.offset(for: .desktopFiles).height)

                    Spacer(minLength: 2)

                    // Footer Bar & Instructions (1.2x Floating HUD Parallax)
                    spatialFooterBar
                        .offset(x: wallpaperCanvasEngine.offset(for: .floatingHUD).width, y: wallpaperCanvasEngine.offset(for: .floatingHUD).height)
                }
                .padding(.vertical, 20)

                // ── 3. Active Edge Aura Portal Indicator ──
                if let auraDir = spatialManager.activeEdgeAura {
                    edgeAuraPortalOverlay(direction: auraDir)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onContinuousHover { phase in
            switch phase {
            case .active(let location):
                wallpaperCanvasEngine.updateCursor(location: location, in: CGSize(width: 1440, height: 900))
            case .ended:
                break
            }
        }
        .onKeyPress(.leftArrow) {
            navigateFocusedSlot(deltaCol: -1, deltaRow: 0)
            return .handled
        }
        .onKeyPress(.rightArrow) {
            navigateFocusedSlot(deltaCol: 1, deltaRow: 0)
            return .handled
        }
        .onKeyPress(.upArrow) {
            navigateFocusedSlot(deltaCol: 0, deltaRow: -1)
            return .handled
        }
        .onKeyPress(.downArrow) {
            navigateFocusedSlot(deltaCol: 0, deltaRow: 1)
            return .handled
        }
        .onKeyPress(KeyEquivalent("1")) { selectSlot(1); return .handled }
        .onKeyPress(KeyEquivalent("2")) { selectSlot(2); return .handled }
        .onKeyPress(KeyEquivalent("3")) { selectSlot(3); return .handled }
        .onKeyPress(KeyEquivalent("4")) { selectSlot(4); return .handled }
        .onKeyPress(KeyEquivalent("5")) { selectSlot(5); return .handled }
        .onKeyPress(KeyEquivalent("6")) { selectSlot(6); return .handled }
        .onKeyPress(KeyEquivalent("7")) { selectSlot(7); return .handled }
        .onKeyPress(KeyEquivalent("8")) { selectSlot(8); return .handled }
        .onKeyPress(KeyEquivalent("9")) { selectSlot(9); return .handled }
        .onKeyPress(.space) {
            spatialManager.zoomInToSelectedDesktop(index: spatialManager.focusedPlaneIndex)
            return .handled
        }
        .onKeyPress(.tab) {
            let nextSlot = (spatialManager.focusedPlaneIndex % 9) + 1
            selectSlot(nextSlot)
            return .handled
        }
        .onKeyPress(.return) {
            spatialManager.zoomInToSelectedDesktop(index: spatialManager.focusedPlaneIndex)
            return .handled
        }
        .onKeyPress(.escape) {
            spatialManager.zoomInToSelectedDesktop()
            return .handled
        }
    }

    // MARK: - Header Bar
    private var spatialHeaderBar: some View {
        HStack(alignment: .center, spacing: 14) {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.cyan.opacity(0.35), Color.blue.opacity(0.20)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 32, height: 32)

                    Image(systemName: "square.grid.3x3.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.cyan)
                }

                VStack(alignment: .leading, spacing: 1.5) {
                    HStack(spacing: 6) {
                        Text("Continuous Spatial Canvas")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text("1..9 Desktops Unified")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundColor(.cyan)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.cyan.opacity(0.18)))
                    }

                    Text("3-Finger Above-Level Pan • Edge Transport • ⌘⌥9 to Zoom")
                        .font(.system(size: 10.5, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.65))
                }
            }

            Spacer()

            // Formation Selector Pill
            HStack(spacing: 3) {
                Button(action: {
                    spatialManager.continuousCanvasFormation = "Unified Panoramic (3 Stations) 🌌"
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "rectangle.stack.fill")
                        Text("Panoramic 🌌")
                    }
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(spatialManager.continuousCanvasFormation == "Unified Panoramic (3 Stations) 🌌" ? .cyan : .white.opacity(0.6))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule().fill(spatialManager.continuousCanvasFormation == "Unified Panoramic (3 Stations) 🌌" ? Color.cyan.opacity(0.22) : Color.clear)
                    )
                }
                .buttonStyle(.plain)

                Button(action: {
                    spatialManager.continuousCanvasFormation = "Genie Earth Maps 🗺️"
                    selectSlot(spatialManager.focusedPlaneIndex)
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "map.fill")
                        Text("3D Earth 🗺️")
                    }
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(spatialManager.continuousCanvasFormation == "Genie Earth Maps 🗺️" ? .cyan : .white.opacity(0.6))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule().fill(spatialManager.continuousCanvasFormation == "Genie Earth Maps 🗺️" ? Color.cyan.opacity(0.22) : Color.clear)
                    )
                }
                .buttonStyle(.plain)

                Button(action: {
                    spatialManager.continuousCanvasFormation = "Omni-Spherical Dome 🌐"
                    selectSlot(spatialManager.focusedPlaneIndex)
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "globe.americas.fill")
                        Text("Sphere Dome 🌐")
                    }
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(spatialManager.continuousCanvasFormation == "Omni-Spherical Dome 🌐" ? .cyan : .white.opacity(0.6))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule().fill(spatialManager.continuousCanvasFormation == "Omni-Spherical Dome 🌐" ? Color.cyan.opacity(0.22) : Color.clear)
                    )
                }
                .buttonStyle(.plain)

                Button(action: {
                    spatialManager.continuousCanvasFormation = "1:1 Continuous Mega-Canvas"
                    selectSlot(spatialManager.focusedPlaneIndex)
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "rectangle.split.3x3.fill")
                        Text("1:1 Mega-Canvas")
                    }
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(spatialManager.continuousCanvasFormation == "1:1 Continuous Mega-Canvas" ? .cyan : .white.opacity(0.6))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule().fill(spatialManager.continuousCanvasFormation == "1:1 Continuous Mega-Canvas" ? Color.cyan.opacity(0.22) : Color.clear)
                    )
                }
                .buttonStyle(.plain)

                Button(action: {
                    spatialManager.continuousCanvasFormation = "3x3 Spatial Plane"
                    selectSlot(spatialManager.focusedPlaneIndex)
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "square.grid.3x3.fill")
                        Text("Birds-Eye")
                    }
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(spatialManager.continuousCanvasFormation == "3x3 Spatial Plane" ? .cyan : .white.opacity(0.6))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule().fill(spatialManager.continuousCanvasFormation == "3x3 Spatial Plane" ? Color.cyan.opacity(0.22) : Color.clear)
                    )
                }
                .buttonStyle(.plain)

                Button(action: {
                    spatialManager.continuousCanvasFormation = "Stacked Vertical Ribbon"
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "scroll.fill")
                        Text("Ribbon")
                    }
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(spatialManager.continuousCanvasFormation == "Stacked Vertical Ribbon" ? .cyan : .white.opacity(0.6))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule().fill(spatialManager.continuousCanvasFormation == "Stacked Vertical Ribbon" ? Color.cyan.opacity(0.22) : Color.clear)
                    )
                }
                .buttonStyle(.plain)

                Button(action: {
                    spatialManager.continuousCanvasFormation = "3x3 Universe Overview"
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "circle.grid.3x3.fill")
                        Text("3x3 Grid")
                    }
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor((spatialManager.continuousCanvasFormation == "3x3 Universe Overview" || spatialManager.continuousCanvasFormation == "3x3 Fit") ? .cyan : .white.opacity(0.6))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule().fill((spatialManager.continuousCanvasFormation == "3x3 Universe Overview" || spatialManager.continuousCanvasFormation == "3x3 Fit") ? Color.cyan.opacity(0.22) : Color.clear)
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(2)
            .background(Capsule().fill(Color.white.opacity(0.08)))

            // ── Trackpad 3x3 Sector Touch Map ──
            HStack(spacing: 8) {
                VStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { r in
                        HStack(spacing: 2) {
                            ForEach(0..<3, id: \.self) { cl in
                                let slot = r * 3 + cl + 1
                                let isFocused = (slot == spatialManager.focusedPlaneIndex)
                                RoundedRectangle(cornerRadius: 1.5)
                                    .fill(isFocused ? Color.cyan : Color.white.opacity(0.25))
                                    .frame(width: 7, height: 5)
                            }
                        }
                    }
                }
                .padding(3)
                .background(RoundedRectangle(cornerRadius: 3).fill(Color.black.opacity(0.35)))

                VStack(alignment: .leading, spacing: 1) {
                    Text("Trackpad Sector \(spatialManager.focusedPlaneIndex)")
                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        .foregroundColor(.cyan)
                    Text("Touch Spot or Keys 1–9")
                        .font(.system(size: 8.5, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.65))
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3.5)
            .background(Capsule().fill(Color.white.opacity(0.08)))
            .overlay(Capsule().strokeBorder(Color.cyan.opacity(0.25), lineWidth: 0.8))

            // + Grow Canvas (+1 Desktop)
            Button(action: {
                HapticFeedback.heavy()
                desktopsManager.createDesktop()
                spatialManager.refreshAllRAMBuffers()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "plus.rectangle.on.rectangle.fill")
                    Text("Grow Canvas (\(desktopsManager.spaces.count)/9)")
                }
                .font(.system(size: 10.5, weight: .bold, design: .rounded))
                .foregroundColor(.cyan)
                .padding(.horizontal, 9)
                .padding(.vertical, 4.5)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(Color.cyan.opacity(0.18))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .strokeBorder(Color.cyan.opacity(0.35), lineWidth: 0.8)
                )
            }
            .buttonStyle(.plain)
            .disabled(desktopsManager.spaces.count >= 9)
            .help("Add a new hardware desktop to expand the continuous canvas up to 9 spaces")

            // Status Badges
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                    Text("64-bit RAM Cache")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.green.opacity(0.9))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.green.opacity(0.12)))

                // ── Spatial & Display Controls Button (Second Control View) ──
                Button(action: {
                    SecondaryControlCenterPopoverManager.shared.toggle()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "slider.horizontal.2.square")
                            .font(.system(size: 10.5, weight: .bold))
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
                            .strokeBorder(Color.cyan.opacity(0.40), lineWidth: 0.8)
                    )
                }
                .buttonStyle(.plain)
                .help("Open Spatial Display & Aspect Ratio Controls")

                // Close / Zoom In Button
                Button(action: {
                    spatialManager.zoomInToSelectedDesktop()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.right.and.arrow.up.left")
                            .font(.system(size: 10, weight: .bold))
                        Text("Touchdown (Esc)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.white.opacity(0.15))
                    )
                }
                .buttonStyle(.plain)
                .help("Return to Desktop (Esc)")

                // Quit Genie Button
                Button(action: {
                    HapticFeedback.heavy()
                    NSApp.terminate(nil)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "power")
                            .font(.system(size: 10, weight: .bold))
                        Text("Quit (⌘Q)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.red.opacity(0.85))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.red.opacity(0.15))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(Color.red.opacity(0.35), lineWidth: 0.8)
                    )
                }
                .buttonStyle(.plain)
                .help("Quit Genie Workspace (⌘Q)")
            }
        }
        .padding(.horizontal, 48)
        .padding(.vertical, 6)
    }

    // MARK: - Spatial Desktop Card (1 of 9)
    private func cardBorderColor(isCurrent: Bool, isFocused: Bool, isHovered: Bool) -> Color {
        if isCurrent { return Color.cyan }
        if isFocused { return Color.white.opacity(0.8) }
        if isHovered { return Color.cyan.opacity(0.5) }
        return Color.white.opacity(0.18)
    }

    private func cardBorderWidth(isCurrent: Bool, isFocused: Bool, isHovered: Bool) -> CGFloat {
        if isCurrent { return 2.2 }
        if isFocused || isHovered { return 1.5 }
        return 0.8
    }

    private func cardScale(isFocused: Bool, isHovered: Bool) -> CGFloat {
        if isHovered { return 1.03 }
        if isFocused { return 1.01 }
        return 1.0
    }

    @ViewBuilder
    private func cardHeaderView(slotIndex: Int, isCurrent: Bool, compass: String) -> some View {
        let dummySpace = MacDesktopSpace(id: "\(slotIndex)", index: slotIndex, name: "Desktop \(slotIndex)", isCurrent: isCurrent)
        HStack(alignment: .center, spacing: 6) {
            HStack(spacing: 3) {
                Image(systemName: compassIcon(for: slotIndex))
                    .font(.system(size: 8.5, weight: .bold))
                Text(compass)
                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
            }
            .foregroundColor(isCurrent ? .cyan : .white.opacity(0.85))
            .padding(.horizontal, 6)
            .padding(.vertical, 2.5)
            .background(
                Capsule().fill(isCurrent ? Color.cyan.opacity(0.22) : Color.white.opacity(0.12))
            )

            Text(desktopsManager.workspaceName(for: dummySpace))
                .font(.system(size: 10.5, weight: isCurrent ? .bold : .medium, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)

            Spacer()

            if isCurrent {
                HStack(spacing: 3) {
                    Circle().fill(Color.cyan).frame(width: 5, height: 5)
                    Text("CURRENT")
                        .font(.system(size: 8, weight: .heavy, design: .monospaced))
                        .foregroundColor(.cyan)
                }
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color.cyan.opacity(0.20)))
            } else {
                Text("RAM")
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.35))
    }

    @ViewBuilder
    private func cardCanvasView(buffer: DesktopPlaneRAMCache?, isHovered: Bool) -> some View {
        let ratio = MacDesktopsManager.resolvedAspectRatio()
        let cardHeight: CGFloat = max(110, min(175, 230 / ratio))
        ZStack {
            if let wp = buffer?.thumbnail ?? buffer?.wallpaper ?? wallpaperManager.activeWallpaperImage {
                Image(nsImage: wp)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else {
                LinearGradient(
                    colors: [Color.blue.opacity(0.5), Color.purple.opacity(0.6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }

            Color.black.opacity(isHovered ? 0.10 : 0.25)

            if let wins = buffer?.windows, !wins.isEmpty {
                VStack(spacing: 3) {
                    ForEach(wins.prefix(3)) { win in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.white.opacity(0.7))
                                .frame(width: 3.5, height: 3.5)
                            Text(win.ownerName)
                                .font(.system(size: 8.5, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Spacer()
                            Text(win.title)
                                .font(.system(size: 7.5, weight: .regular, design: .rounded))
                                .foregroundColor(.white.opacity(0.75))
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(Color.black.opacity(0.55))
                        )
                        .contextMenu {
                            Text("Move \(win.ownerName) to:")
                                .font(.caption)
                            Divider()
                            ForEach(1...9, id: \.self) { targetSlot in
                                Button("Desktop \(targetSlot) • \(SpatialPlaneManager.compassBearing(for: targetSlot))") {
                                    SmartGridManager.shared.moveAppToDesktop(pid: win.pid, targetDesktopIndex: targetSlot)
                                }
                            }
                        }
                    }
                    Spacer(minLength: 0)
                }
                .padding(6)
            }

            if let icons = buffer?.runningAppIcons, !icons.isEmpty {
                VStack {
                    Spacer()
                    HStack(spacing: 4) {
                        ForEach(Array(icons.prefix(5).enumerated()), id: \.offset) { _, icon in
                            Image(nsImage: icon)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 15, height: 15)
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.black.opacity(0.40)))
                    .padding(4)
                }
            }
        }
        .frame(height: cardHeight)
    }

    private func spatialDesktopCard(for slotIndex: Int) -> some View {
        let buffer = spatialManager.ramBuffers[slotIndex]
        let isFocused = spatialManager.focusedPlaneIndex == slotIndex
        let isCurrent = slotIndex == desktopsManager.currentSpaceIndex
        let isHovered = hoveredCardIndex == slotIndex
        let compass = SpatialPlaneManager.compassBearing(for: slotIndex)
        let strokeColor = cardBorderColor(isCurrent: isCurrent, isFocused: isFocused, isHovered: isHovered)
        let strokeWidth = cardBorderWidth(isCurrent: isCurrent, isFocused: isFocused, isHovered: isHovered)
        let scale = cardScale(isFocused: isFocused, isHovered: isHovered)

        return Button(action: {
            spatialManager.zoomInToSelectedDesktop(index: slotIndex)
        }) {
            VStack(spacing: 0) {
                cardHeaderView(slotIndex: slotIndex, isCurrent: isCurrent, compass: compass)
                cardCanvasView(buffer: buffer, isHovered: isHovered)
            }
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.08))
            )
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(strokeColor, lineWidth: strokeWidth)
            )
            .shadow(color: isCurrent ? Color.cyan.opacity(0.40) : Color.black.opacity(0.35), radius: isCurrent ? 12 : 6, y: 3)
            .scaleEffect(scale)
            .animation(.spring(response: 0.24, dampingFraction: 0.80), value: isHovered)
            .animation(.spring(response: 0.24, dampingFraction: 0.80), value: isFocused)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            hoveredCardIndex = hovering ? slotIndex : nil
            if hovering {
                spatialManager.focusedPlaneIndex = slotIndex
            }
        }
    }

    // MARK: - Footer Bar
    private var spatialFooterBar: some View {
        HStack(spacing: 16) {
            HStack(spacing: 6) {
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 10, weight: .bold))
                Text("Trackpad 3×3 Sectors / Keys 1–9: Jump to Desktop")
                    .font(.system(size: 10.5, weight: .medium, design: .rounded))
            }

            Text("•")
                .foregroundColor(.white.opacity(0.3))

            HStack(spacing: 6) {
                Image(systemName: "arrow.left.and.right")
                    .font(.system(size: 10, weight: .bold))
                Text("Arrows / 2-Finger Pan: Glide Reticle")
                    .font(.system(size: 10.5, weight: .medium, design: .rounded))
            }

            Text("•")
                .foregroundColor(.white.opacity(0.3))

            HStack(spacing: 6) {
                Image(systemName: "return")
                    .font(.system(size: 10, weight: .bold))
                Text("Return / Space / Click: Land on Desktop")
                    .font(.system(size: 10.5, weight: .medium, design: .rounded))
            }

            Text("•")
                .foregroundColor(.white.opacity(0.3))

            HStack(spacing: 6) {
                Image(systemName: "hand.point.up.left.fill")
                    .font(.system(size: 10, weight: .bold))
                Text("Drag Window to Edge in normal view to glide across monitors")
                    .font(.system(size: 10.5, weight: .medium, design: .rounded))
            }

            if let msg = spatialManager.lastEdgeTransportMessage {
                Spacer()
                Text(msg)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.cyan.opacity(0.15)))
            }
        }
        .foregroundColor(.white.opacity(0.65))
        .padding(.horizontal, 48)
    }

    // MARK: - Edge Aura Overlay
    private func edgeAuraPortalOverlay(direction: SpatialPlaneDirection) -> some View {
        GeometryReader { geo in
            ZStack {
                switch direction {
                case .east:
                    HStack {
                        Spacer()
                        VStack(spacing: 6) {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.cyan)
                            Text("Gliding to Next Desktop...")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.cyan.opacity(0.28))
                        )
                        .padding(.trailing, 20)
                    }
                case .west:
                    HStack {
                        VStack(spacing: 6) {
                            Image(systemName: "arrow.left.circle.fill")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.cyan)
                            Text("Gliding to Previous Desktop...")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.cyan.opacity(0.28))
                        )
                        .padding(.leading, 20)
                        Spacer()
                    }
                case .north:
                    VStack {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.cyan)
                            Text("Gliding to Top Desktop...")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.cyan.opacity(0.28))
                        )
                        .padding(.top, 20)
                        Spacer()
                    }
                case .south:
                    VStack {
                        Spacer()
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.cyan)
                            Text("Gliding to Bottom Desktop...")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        .padding(14)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.cyan.opacity(0.28))
                        )
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .transition(.opacity)
    }

    // MARK: - Navigation Math
    private func selectSlot(_ index: Int) {
        let clamped = max(1, min(9, index))
        spatialManager.focusedPlaneIndex = clamped
        spatialManager.macroTargetSpaceIndex = clamped
        let (col, row) = SpatialPlaneManager.gridCoordinate(for: clamped)
        
        let screen = NSScreen.main ?? NSScreen.screens.first
        let screenW = screen?.frame.width ?? 1440.0
        let screenH = screen?.frame.height ?? 900.0

        if spatialManager.continuousCanvasFormation == "1:1 Continuous Mega-Canvas" {
            let targetX = -CGFloat(col) * screenW
            let targetY = -CGFloat(row) * screenH
            withAnimation(.spring(response: 0.35, dampingFraction: 0.86)) {
                spatialManager.macroCameraOffset = CGSize(width: targetX, height: targetY)
            }
        } else {
            let offsetX = CGFloat(col - 1) * 180.0
            let offsetY = CGFloat(row - 1) * 130.0
            withAnimation(.spring(response: 0.30, dampingFraction: 0.85)) {
                spatialManager.macroCameraOffset = CGSize(width: offsetX, height: offsetY)
            }
        }
        HapticFeedback.selection()
    }

    private func navigateFocusedSlot(deltaCol: Int, deltaRow: Int) {
        let (col, row) = SpatialPlaneManager.gridCoordinate(for: spatialManager.focusedPlaneIndex)
        let newCol = max(0, min(2, col + deltaCol))
        let newRow = max(0, min(2, row + deltaRow))
        let newIndex = SpatialPlaneManager.indexForGrid(col: newCol, row: newRow)
        selectSlot(newIndex)
    }

    private func compassIcon(for slotIndex: Int) -> String {
        switch slotIndex {
        case 1: return "arrow.up.left"
        case 2: return "arrow.up"
        case 3: return "arrow.up.right"
        case 4: return "arrow.left"
        case 5: return "target"
        case 6: return "arrow.right"
        case 7: return "arrow.down.left"
        case 8: return "arrow.down"
        case 9: return "arrow.down.right"
        default: return "circle"
        }
    }
}

// MARK: - Spatial Plane Grid Lines View
private struct SpatialPlaneGridLinesView: View {
    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height
            var path = Path()

            // Vertical 1/3 and 2/3 guidelines
            path.move(to: CGPoint(x: w / 3, y: 0))
            path.addLine(to: CGPoint(x: w / 3, y: h))
            path.move(to: CGPoint(x: w * 2 / 3, y: 0))
            path.addLine(to: CGPoint(x: w * 2 / 3, y: h))

            // Horizontal 1/3 and 2/3 guidelines
            path.move(to: CGPoint(x: 0, y: h / 3))
            path.addLine(to: CGPoint(x: w, y: h / 3))
            path.move(to: CGPoint(x: 0, y: h * 2 / 3))
            path.addLine(to: CGPoint(x: w, y: h * 2 / 3))

            context.stroke(
                path,
                with: .color(Color.cyan.opacity(0.3)),
                style: StrokeStyle(lineWidth: 0.8, dash: [4, 6])
            )
        }
    }
}
