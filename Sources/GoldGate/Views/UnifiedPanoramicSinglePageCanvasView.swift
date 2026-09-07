import AppKit
import Foundation
import SwiftUI

// MARK: - Unified Panoramic Single-Page Canvas View
/// Locks Zenith (Chat Studio), Horizon (Clean Desktop), and Nadir (Applications Atelier)
/// into a single, continuous, vertical viewport that scrolls like a fluid single-page web app.
public struct UnifiedPanoramicSinglePageCanvasView: View {
    @ObservedObject var coordinator: UnifiedPanoramicStationCoordinator = .shared
    @ObservedObject var appModel: AppModel
    @ObservedObject var wallpaperManager: WallpaperManager = .shared
    @ObservedObject var desktopFilesManager: DesktopFilesManager = .shared
    @ObservedObject var localModels: LocalModelManager = .shared
    @ObservedObject var domEngine: SwiftDOMEngine = .shared

    var screen: NSScreen? = nil

    @State private var dragVelocityTracker: CGFloat = 0.0
    @State private var lastDragTime: TimeInterval = 0.0
    @State private var lastDragLocationY: CGFloat = 0.0
    @State private var isStationIndicatorDragging: Bool = false
    @State private var indicatorDragOffset: CGFloat = 0.0

    // ── Meta-Sandbox Orbit Mode & Pinch-to-Zoom Scale ──
    @State private var zoomScale: CGFloat = 1.0
    @State private var isOrbitGalaxyMode: Bool = false
    @ObservedObject var spatialManager: SpatialPlaneManager = .shared
    @ObservedObject var desktopsManager: MacDesktopsManager = .shared

    init(appModel: AppModel, screen: NSScreen? = nil) {
        self.appModel = appModel
        self.screen = screen
    }

    public var body: some View {
        GeometryReader { geo in
            let screenSize = geo.size
            let screenH = screenSize.height
            let screenW = screenSize.width
            let translationY = coordinator.canvasTranslationY(screenHeight: screenH)

            ZStack(alignment: .topLeading) {
                // ── 1. Parallax Liquid Glass Wallpaper Layer ──
                parallaxWallpaperBackdrop(screenSize: screenSize)

                // ── 2. Unified Continuous 3-Station Viewport Canvas ──
                // Positioned continuously on a single vertical column: [-H, 0, +H]
                ZStack(alignment: .topLeading) {
                    // Zenith Station (Chat Studio & Search): Positioned at -H
                    zenithStationView(screenSize: screenSize)
                        .frame(width: screenW, height: screenH)
                        .offset(y: -screenH)

                    // Horizon Station (Clean Desktop & Files): Positioned at 0
                    horizonStationView(screenSize: screenSize)
                        .frame(width: screenW, height: screenH)
                        .offset(y: 0)

                    // Nadir Station (Applications Atelier & Formations): Positioned at +H
                    nadirStationView(screenSize: screenSize)
                        .frame(width: screenW, height: screenH)
                        .offset(y: screenH)
                }
                .frame(width: screenW, height: screenH * 3, alignment: .topLeading)
                .offset(y: translationY)
                .scaleEffect(zoomScale)
                .rotation3DEffect(
                    .degrees(isOrbitGalaxyMode ? 14.0 : 0.0),
                    axis: (x: 1, y: 0, z: 0),
                    perspective: 0.75
                )
                .opacity(isOrbitGalaxyMode ? 0.35 : 1.0)
                .animation(
                    coordinator.isInteracting ? UnifiedPanoramicStationCoordinator.interactiveDragSpring : UnifiedPanoramicStationCoordinator.stationSnapSpring,
                    value: translationY
                )
                .animation(.spring(response: 0.42, dampingFraction: 0.84), value: zoomScale)
                .animation(.spring(response: 0.42, dampingFraction: 0.84), value: isOrbitGalaxyMode)

                // ── 3. High-Precision 3-Dot Right-Edge Station Indicator ──
                if !isOrbitGalaxyMode {
                    rightEdgeStationIndicator(screenSize: screenSize)
                }

                // ── 4. Floating Station HUD Breadcrumb & Orbit Switcher ──
                floatingStationHeaderHUD(screenSize: screenSize)

                // ── 5. Meta-Sandbox Orbit Galaxy View (3x3 Universe Grid) ──
                if isOrbitGalaxyMode {
                    orbitGalaxySandboxView(screenSize: screenSize)
                        .transition(.scale(scale: 0.90).combined(with: .opacity))
                }
            }
            .frame(width: screenW, height: screenH)
            .clipped()
            .contentShape(Rectangle())
            // ── Interactive 1:1 Vertical Gesture Dragging & Momentum Physics ──
            .gesture(
                DragGesture(minimumDistance: 6)
                    .onChanged { gesture in
                        guard !isOrbitGalaxyMode else { return }
                        let now = ProcessInfo.processInfo.systemUptime
                        let dt = now - lastDragTime
                        if dt > 0.001 {
                            dragVelocityTracker = (gesture.location.y - lastDragLocationY) / CGFloat(dt)
                        }
                        lastDragTime = now
                        lastDragLocationY = gesture.location.y

                        coordinator.onDragChanged(
                            translationY: gesture.translation.height,
                            screenHeight: screenH
                        )
                    }
                    .onEnded { gesture in
                        guard !isOrbitGalaxyMode else { return }
                        coordinator.onDragEnded(
                            translationY: gesture.translation.height,
                            velocityY: dragVelocityTracker,
                            screenHeight: screenH
                        )
                        dragVelocityTracker = 0.0
                    }
            )
            // ── Meta-Sandbox Pinch-to-Zoom Gesture ──
            .gesture(
                MagnificationGesture()
                    .onChanged { scale in
                        let targetScale = min(1.25, max(0.35, scale))
                        zoomScale = targetScale
                        if targetScale < 0.80 && !isOrbitGalaxyMode {
                            withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                                isOrbitGalaxyMode = true
                            }
                        }
                    }
                    .onEnded { scale in
                        if scale < 0.80 || isOrbitGalaxyMode {
                            withAnimation(.spring(response: 0.42, dampingFraction: 0.84)) {
                                zoomScale = 0.45
                                isOrbitGalaxyMode = true
                            }
                        } else {
                            withAnimation(.spring(response: 0.42, dampingFraction: 0.84)) {
                                zoomScale = 1.0
                                isOrbitGalaxyMode = false
                            }
                        }
                    }
            )
        }
        .ignoresSafeArea()
        // ── Keyboard Shortcuts ──
        .onKeyPress(.upArrow) {
            coordinator.cyclePreviousStation()
            return .handled
        }
        .onKeyPress(.downArrow) {
            coordinator.cycleNextStation()
            return .handled
        }
        .onKeyPress(KeyEquivalent("1")) { coordinator.scrollToStation(.zenith); return .handled }
        .onKeyPress(KeyEquivalent("2")) { coordinator.scrollToStation(.horizon); return .handled }
        .onKeyPress(KeyEquivalent("3")) { coordinator.scrollToStation(.nadir); return .handled }
        .onKeyPress(KeyEquivalent("o")) {
            // Toggle Meta-Sandbox Orbit View
            withAnimation(.spring(response: 0.42, dampingFraction: 0.84)) {
                isOrbitGalaxyMode.toggle()
                zoomScale = isOrbitGalaxyMode ? 0.45 : 1.0
            }
            return .handled
        }
        .onKeyPress(.tab) { coordinator.cycleNextStation(); return .handled }
        .onKeyPress(.escape) {
            if isOrbitGalaxyMode {
                withAnimation(.spring(response: 0.42, dampingFraction: 0.84)) {
                    isOrbitGalaxyMode = false
                    zoomScale = 1.0
                }
            } else {
                coordinator.scrollToStation(.horizon)
            }
            return .handled
        }
        .onKeyPress(.return) { coordinator.scrollToStation(.horizon); return .handled }
        .onAppear {
            let initialScreen = screen ?? NSScreen.main ?? NSScreen()
            let w = initialScreen.frame.width > 0 ? initialScreen.frame.width : 1440
            let h = initialScreen.frame.height > 0 ? initialScreen.frame.height : 900
            domEngine.buildUniverseTree(screenWidth: w, screenHeight: h)
            let initialY = coordinator.canvasTranslationY(screenHeight: h)
            domEngine.reconcile(cameraOffset: CGSize(width: 0, height: initialY), viewportSize: CGSize(width: w, height: h))
        }
        .onChange(of: coordinator.continuousOffset) { _, _ in
            let initialScreen = screen ?? NSScreen.main ?? NSScreen()
            let w = initialScreen.frame.width > 0 ? initialScreen.frame.width : 1440
            let h = initialScreen.frame.height > 0 ? initialScreen.frame.height : 900
            let currentY = coordinator.canvasTranslationY(screenHeight: h)
            domEngine.reconcile(cameraOffset: CGSize(width: 0, height: currentY), viewportSize: CGSize(width: w, height: h))
        }
        .onReceive(spatialManager.$vectorZoomScale) { newScale in
            if newScale < 0.80 && !isOrbitGalaxyMode {
                withAnimation(.spring(response: 0.42, dampingFraction: 0.84)) {
                    isOrbitGalaxyMode = true
                    zoomScale = 0.45
                }
            } else if newScale >= 0.80 && isOrbitGalaxyMode {
                withAnimation(.spring(response: 0.42, dampingFraction: 0.84)) {
                    isOrbitGalaxyMode = false
                    zoomScale = 1.0
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusToggleSpatialOrbitMode"))) { _ in
            withAnimation(.spring(response: 0.42, dampingFraction: 0.84)) {
                isOrbitGalaxyMode.toggle()
                zoomScale = isOrbitGalaxyMode ? 0.45 : 1.0
            }
        }
    }

    // MARK: - Parallax Wallpaper Backdrop
    @ViewBuilder
    private func parallaxWallpaperBackdrop(screenSize: CGSize) -> some View {
        ZStack {
            if let wallpaper = wallpaperManager.activeWallpaperImage {
                Image(nsImage: wallpaper)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: screenSize.width, height: screenSize.height)
                    .clipped()
                    .scaleEffect(coordinator.parallaxWallpaperScale)
                    .blur(radius: coordinator.parallaxWallpaperBlur)
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.08, green: 0.10, blue: 0.18),
                        Color(red: 0.03, green: 0.04, blue: 0.08)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }

            // Dynamic liquid glass shading and atmospheric darkening
            Color.black
                .opacity(coordinator.atmosphericDarkeningOpacity)
                .animation(.spring(response: 0.35, dampingFraction: 0.85), value: coordinator.atmosphericDarkeningOpacity)
        }
        .frame(width: screenSize.width, height: screenSize.height)
        .offset(y: coordinator.canvasTranslationY(screenHeight: screenSize.height) * 0.35)
        .rotation3DEffect(
            .degrees(Double(min(12.0, max(-12.0, coordinator.canvasTranslationY(screenHeight: screenSize.height) / 75.0)))),
            axis: (x: 1, y: 0, z: 0),
            perspective: 0.85
        )
        .allowsHitTesting(false)
    }

    // MARK: - Station 1: Zenith (Top: Chat Studio & Omni Search)
    @ViewBuilder
    private func zenithStationView(screenSize: CGSize) -> some View {
        ZStack {
            // Ambient glass backdrop
            VisualEffectBlur(material: .fullScreenUI, blendingMode: .behindWindow, state: .active)
                .opacity(0.45)

            VStack(spacing: 16) {
                // Header strip
                HStack(alignment: .center, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.cyan)

                        VStack(alignment: .leading, spacing: 1) {
                            HStack(spacing: 6) {
                                Text("Zenith • Dialogue Studio & Search")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)

                                Text("Top Station (-H)")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(.cyan)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color.cyan.opacity(0.18)))
                            }

                            Text("Claude, Gemma & Hugging Face Intelligence Kernel")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.65))
                        }
                    }

                    Spacer()

                    Button(action: {
                        coordinator.scrollToStation(.horizon)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down")
                                .font(.system(size: 11, weight: .bold))
                            Text("Desktop Canvas (Esc)")
                                .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color.white.opacity(0.12)))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 48)
                .padding(.top, 40)

                // Embedded Finder Chat Container
                FinderStyleChatWindowView()
                    .padding(.horizontal, 48)
                    .padding(.bottom, 28)
            }
        }
    }

    // MARK: - Station 2: Horizon (Center: Clean Desktop & Files)
    @ViewBuilder
    private func horizonStationView(screenSize: CGSize) -> some View {
        ZStack {
            // Clean pass-through surface
            Color.clear

            VStack {
                Spacer()

                // Minimalist Center Desktop HUD
                VStack(spacing: 12) {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                            .shadow(color: Color.green.opacity(0.8), radius: 4)

                        Text("Horizon Desktop Space")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.85))

                        Text("Offset 0")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.white.opacity(0.10)))
                    }

                    HStack(spacing: 14) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up")
                            Text("Zenith (Chat Studio)")
                        }
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.cyan.opacity(0.8))

                        Text("•")
                            .foregroundColor(.white.opacity(0.3))

                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down")
                            Text("Nadir (Applications)")
                        }
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(Color(red: 1.0, green: 0.55, blue: 0.15).opacity(0.9))
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.black.opacity(0.35))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.8)
                )
                .padding(.bottom, 64)
            }
        }
    }

    // MARK: - Station 3: Nadir (Bottom: Applications Atelier & Formations)
    @ViewBuilder
    private func nadirStationView(screenSize: CGSize) -> some View {
        ZStack {
            // Ambient glass backdrop
            VisualEffectBlur(material: .fullScreenUI, blendingMode: .behindWindow, state: .active)
                .opacity(0.50)

            VStack(spacing: 16) {
                // Header strip
                HStack(alignment: .center, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "square.grid.3x3.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(Color(red: 1.0, green: 0.55, blue: 0.15))

                        VStack(alignment: .leading, spacing: 1) {
                            HStack(spacing: 6) {
                                Text("Nadir • Applications Atelier")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)

                                Text("Bottom Station (+H)")
                                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    .foregroundColor(Color(red: 1.0, green: 0.55, blue: 0.15))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill(Color.orange.opacity(0.18)))
                            }

                            Text("\(appModel.visibleApps.count) Native Apps • Geometric Formations & Matrices")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.65))
                        }
                    }

                    Spacer()

                    Button(action: {
                        coordinator.scrollToStation(.horizon)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up")
                                .font(.system(size: 11, weight: .bold))
                            Text("Desktop Canvas (Esc)")
                                .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color.white.opacity(0.12)))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 48)
                .padding(.top, 40)

                // Applications Overlay View
                ApplicationsOverlayView()
                    .padding(.horizontal, 48)
                    .padding(.bottom, 28)
            }
        }
    }

    // MARK: - 3-Dot Right-Edge Station Indicator
    @ViewBuilder
    private func rightEdgeStationIndicator(screenSize: CGSize) -> some View {
        let currentStation = coordinator.currentStation
        let activeColor = currentStation.themeColor
        let slotSpacing: CGFloat = 28.0

        let thumbY: CGFloat = {
            if isStationIndicatorDragging {
                return indicatorDragOffset
            }
            return coordinator.continuousOffset * slotSpacing
        }()

        HStack {
            Spacer()

            ZStack(alignment: .center) {
                // Liquid glass background capsule track
                Capsule()
                    .fill(.ultraThinMaterial)
                    .frame(
                        width: coordinator.isStationIndicatorHovered ? 18 : 14,
                        height: 96
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        coordinator.isStationIndicatorHovered ? activeColor.opacity(0.65) : Color.white.opacity(0.28),
                                        Color.white.opacity(0.08)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ),
                                lineWidth: coordinator.isStationIndicatorHovered ? 1.0 : 0.6
                            )
                    )
                    .shadow(color: Color.black.opacity(0.35), radius: 10, y: 2)

                // Active Sliding Thumb Glow Aura
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [activeColor.opacity(0.65), activeColor.opacity(0.30)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: coordinator.isStationIndicatorHovered ? 14 : 10, height: 22)
                    .overlay(
                        Capsule().strokeBorder(activeColor.opacity(0.9), lineWidth: 0.8)
                    )
                    .shadow(color: activeColor.opacity(0.70), radius: 8, y: 0)
                    .offset(y: thumbY)
                    .animation(isStationIndicatorDragging ? .interactiveSpring() : .spring(response: 0.32, dampingFraction: 0.78), value: thumbY)

                // 3 Clickable Station Target Dots
                VStack(spacing: 0) {
                    // Dot 0: Zenith (Chat)
                    stationDotButton(station: .zenith, isHovered: coordinator.isStationIndicatorHovered)

                    // Dot 1: Horizon (Desktop)
                    stationDotButton(station: .horizon, isHovered: coordinator.isStationIndicatorHovered)

                    // Dot 2: Nadir (Applications)
                    stationDotButton(station: .nadir, isHovered: coordinator.isStationIndicatorHovered)
                }
            }
            .contentShape(Capsule())
            .padding(.trailing, 16)
            .onHover { h in
                withAnimation(.spring(response: 0.24, dampingFraction: 0.76)) {
                    coordinator.isStationIndicatorHovered = h
                }
            }
            .gesture(
                DragGesture(minimumDistance: 4)
                    .onChanged { gesture in
                        isStationIndicatorDragging = true
                        let clamped = max(-slotSpacing, min(slotSpacing, gesture.location.y - 48.0))
                        indicatorDragOffset = clamped
                        coordinator.continuousOffset = clamped / slotSpacing
                    }
                    .onEnded { gesture in
                        isStationIndicatorDragging = false
                        let finalY = indicatorDragOffset
                        indicatorDragOffset = 0.0

                        if finalY < -10.0 {
                            coordinator.scrollToStation(.zenith)
                        } else if finalY > 10.0 {
                            coordinator.scrollToStation(.nadir)
                        } else {
                            coordinator.scrollToStation(.horizon)
                        }
                    }
            )
        }
        .frame(maxHeight: .infinity)
        .allowsHitTesting(true)
    }

    @ViewBuilder
    private func stationDotButton(station: CanvasStation, isHovered: Bool) -> some View {
        let isSelected = coordinator.currentStation == station
        let color = station.themeColor

        Button(action: {
            coordinator.scrollToStation(station)
        }) {
            ZStack {
                if isSelected {
                    Circle()
                        .fill(color.opacity(0.35))
                        .frame(width: 14, height: 14)
                        .blur(radius: 2)
                }

                Circle()
                    .fill(isSelected ? color : Color.white.opacity(0.40))
                    .frame(
                        width: isSelected ? (isHovered ? 7.5 : 6.5) : 4.0,
                        height: isSelected ? (isHovered ? 7.5 : 6.5) : 4.0
                    )
                    .shadow(color: isSelected ? color.opacity(0.8) : Color.clear, radius: 4)
            }
            .frame(width: 28, height: 28)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(station.title)
    }

    // MARK: - Floating Station Header HUD Breadcrumb & Orbit Toggle
    @ViewBuilder
    private func floatingStationHeaderHUD(screenSize: CGSize) -> some View {
        VStack {
            HStack(spacing: 8) {
                // Station Icon & Badge
                HStack(spacing: 6) {
                    Image(systemName: isOrbitGalaxyMode ? "circle.grid.3x3.circle.fill" : coordinator.currentStation.systemImage)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(isOrbitGalaxyMode ? .purple : coordinator.currentStation.themeColor)

                    Text(isOrbitGalaxyMode ? "Galaxy Orbit Mode • 9 Spaces" : coordinator.currentStation.shortTitle)
                        .font(.system(size: 11.5, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4.5)
                .background(
                    Capsule()
                        .fill((isOrbitGalaxyMode ? Color.purple : coordinator.currentStation.themeColor).opacity(0.18))
                )
                .overlay(
                    Capsule()
                        .strokeBorder((isOrbitGalaxyMode ? Color.purple : coordinator.currentStation.themeColor).opacity(0.35), lineWidth: 0.8)
                )

                // Meta-Sandbox Orbit Toggle Button
                Button(action: {
                    HapticFeedback.selection()
                    withAnimation(.spring(response: 0.42, dampingFraction: 0.84)) {
                        isOrbitGalaxyMode.toggle()
                        zoomScale = isOrbitGalaxyMode ? 0.45 : 1.0
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: isOrbitGalaxyMode ? "arrow.down.right.and.arrow.up.left" : "sparkles.rectangle.stack.fill")
                            .font(.system(size: 10, weight: .semibold))
                        Text(isOrbitGalaxyMode ? "Dive In (Esc)" : "Orbit (O)")
                            .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.12))
                    )
                }
                .buttonStyle(.plain)

                // Continuous Scroll Hint
                if !isOrbitGalaxyMode {
                    Text("Scroll ↕ or Press 1/2/3 to Glide")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.55))
                }
            }
            .padding(4)
            .padding(.horizontal, 6)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.65))
            )
            .padding(.top, 14)
            .padding(.leading, 24)

            Spacer()
        }
        .opacity((coordinator.currentStation == .horizon && !isOrbitGalaxyMode) ? 0.0 : 1.0)
        .animation(.spring(response: 0.32, dampingFraction: 0.80), value: coordinator.currentStation)
        .animation(.spring(response: 0.32, dampingFraction: 0.80), value: isOrbitGalaxyMode)
    }

    // MARK: - Meta-Sandbox: 3x3 Galaxy Orbit Grid Overlay
    @ViewBuilder
    private func orbitGalaxySandboxView(screenSize: CGSize) -> some View {
        let columns = [
            GridItem(.flexible(), spacing: 20),
            GridItem(.flexible(), spacing: 20),
            GridItem(.flexible(), spacing: 20)
        ]

        ZStack {
            // Dark glass cosmic canvas backdrop
            VisualEffectBlur(material: .fullScreenUI, blendingMode: .behindWindow, state: .active)
                .opacity(0.85)
                .ignoresSafeArea()

            Color.black.opacity(0.60)
                .ignoresSafeArea()

            VStack(spacing: 20) {
                // Meta-Universe Top Indicator
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("SPATIAL MULTIVERSE SANDBOX")
                            .font(.system(size: 11, weight: .heavy, design: .monospaced))
                            .foregroundColor(.purple)
                            .tracking(1.5)

                        Text("Select a Space or Pinch In to Dive")
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    // Quick Jump Badges
                    HStack(spacing: 6) {
                        let totalSlots = max(3, min(9, desktopsManager.spaces.count))
                        ForEach(1...totalSlots, id: \.self) { slot in
                            let isCurrent = desktopsManager.currentSpaceIndex == slot
                            Button(action: {
                                diveIntoSpace(slot: slot)
                            }) {
                                Text("\(slot)")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(isCurrent ? Color.black : Color.white)
                                    .frame(width: 24, height: 24)
                                    .background(
                                        Circle()
                                            .fill(isCurrent ? Color.cyan : Color.white.opacity(0.15))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 48)
                .padding(.top, 50)

                // 3x3 Space Matrix Galaxy
                LazyVGrid(columns: columns, spacing: 20) {
                    ForEach(1...9, id: \.self) { slotIndex in
                        orbitSpaceCard(slotIndex: slotIndex, screenSize: screenSize)
                    }
                }
                .padding(.horizontal, 48)
                .padding(.bottom, 36)
            }
        }
    }

    // MARK: - Individual Space Sandbox Card in Orbit Mode
    @ViewBuilder
    private func orbitSpaceCard(slotIndex: Int, screenSize: CGSize) -> some View {
        let isCurrentSpace = desktopsManager.currentSpaceIndex == slotIndex
        let planeCache = spatialManager.desktopPlaneCacheBuffers[slotIndex]
        let spaceName = planeCache?.name ?? "Space \(slotIndex)"
        let compassText = planeCache?.compassOrientation ?? "Slot \(slotIndex)"

        Button(action: {
            diveIntoSpace(slot: slotIndex)
        }) {
            VStack(alignment: .leading, spacing: 8) {
                // Header: Slot Number & Compass Orientation
                HStack {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(isCurrentSpace ? Color.green : Color.white.opacity(0.35))
                            .frame(width: 6, height: 6)

                        Text(spaceName)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    Text(compassText)
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.55))
                }

                // Live Preview / Dynamic Mipmap Texture
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color(red: 0.12, green: 0.14, blue: 0.22))

                    let previewImg: NSImage? = desktopsManager.desktopLivePreviews[slotIndex] ?? planeCache?.thumbnail

                    if let preview = previewImg {
                        Image(nsImage: preview)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxHeight: 120)
                            .clipped()
                            .cornerRadius(10)
                    } else if let wallpaper = wallpaperManager.activeWallpaperImage {
                        Image(nsImage: wallpaper)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxHeight: 120)
                            .clipped()
                            .cornerRadius(10)
                            .opacity(0.60)
                    }

                    // 3-Station Mini Indicator Bar (Visualizing the inner sandbox filmstrip)
                    VStack {
                        Spacer()
                        HStack(spacing: 4) {
                            Circle().fill(Color.cyan).frame(width: 4, height: 4) // Zenith
                            Circle().fill(Color.white).frame(width: 4, height: 4) // Horizon
                            Circle().fill(Color.orange).frame(width: 4, height: 4) // Nadir
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.black.opacity(0.65)))
                        .padding(.bottom, 6)
                    }
                }
                .frame(height: 110)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(
                            isCurrentSpace ? Color.cyan : Color.white.opacity(0.12),
                            lineWidth: isCurrentSpace ? 2.0 : 0.8
                        )
                )

                // Footer: Running Apps Count or Active Indicator
                HStack {
                    if let apps = planeCache?.runningAppNames, !apps.isEmpty {
                        Text("\(apps.count) Active Apps")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.65))
                    } else {
                        Text(isCurrentSpace ? "Active Sandbox" : "Idle Sandbox")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(isCurrentSpace ? .cyan : .white.opacity(0.40))
                    }

                    Spacer()

                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.50))
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(red: 0.08, green: 0.10, blue: 0.16).opacity(0.85))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        isCurrentSpace ? Color.cyan.opacity(0.70) : Color.white.opacity(0.15),
                        lineWidth: isCurrentSpace ? 1.5 : 0.8
                    )
            )
            .shadow(color: isCurrentSpace ? Color.cyan.opacity(0.35) : Color.black.opacity(0.3), radius: isCurrentSpace ? 12 : 6)
        }
        .buttonStyle(.plain)
    }

    private func diveIntoSpace(slot: Int) {
        HapticFeedback.selection()
        desktopsManager.switchToDesktop(index: slot)
        spatialManager.focusedPlaneIndex = slot
        withAnimation(.spring(response: 0.42, dampingFraction: 0.84)) {
            isOrbitGalaxyMode = false
            zoomScale = 1.0
        }
    }
}
