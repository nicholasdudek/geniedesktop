import AppKit
import AudioToolbox
import SwiftUI

// MARK: - Wallpaper Engine & Dynamic Camouflage

final class WallpaperSampler: ObservableObject {
    static let shared = WallpaperSampler()

    var wallpaperImage: NSImage? {
        WallpaperManager.shared.activeWallpaperImage
    }

    func refresh() {
        WallpaperManager.shared.refresh()
    }
}

// MARK: - Interactive Pet Treat & Pinball Arcade Models

struct PetTreat: Identifiable {
    let id = UUID()
    var position: CGPoint
    var opacity: Double = 1.0
    var scale: CGFloat = 1.0
    var isEaten: Bool = false
}

struct PinballBall: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGPoint
    var radius: CGFloat = 10.0
    var color: Color = .cyan
    var bounces: Int = 0
}

// MARK: - 3-Stage Applications Elevation Hierarchy
public enum AppDisplayStage: Int, CaseIterable {
    case hidden = 0
    case middle = 1
    case fullScreen = 2
}

// MARK: - Ultra-Fluid 120FPS Fullscreen Desktop View (Zero-Jank Metal Pipeline)

struct DesktopGridView: View {
    @AppStorage(PrefKey.appLanguage) var appLanguage: String = "English (US)"
@ObservedObject var appModel: AppModel
    var screen: NSScreen? = nil
    @StateObject private var wallpaperSampler = WallpaperSampler.shared
    @ObservedObject private var wallpaperManager = WallpaperManager.shared
    @ObservedObject private var desktopFilesManager = DesktopFilesManager.shared
    @ObservedObject private var windowManager = DesktopWindowManager.shared
    @ObservedObject private var wallpaperEngine = DraggableWallpaperCanvasEngine.shared

    @State private var currentPage: Int = 0
    @State private var isPageIndicatorHovered: Bool = false
    @State private var isEditing: Bool = false
    @State private var wiggle: Bool = false
    @State private var animPhase: Double = 0.0
    @State private var physicsOffsetPhase: Double = 0.0
    @State private var mouseLocation: CGPoint? = nil
    @State private var cursorTrail: [CursorTrailPoint] = []
    @State private var draggedAppID: String? = nil
    @State private var dragCurrentOffset: CGSize = .zero
    @State private var dragHoverTargetID: String? = nil
    @State private var lastScrollTime: TimeInterval = 0
    @State private var lastPageSwitchTime: TimeInterval = 0
    @State private var scrollAccumulator: CGFloat = 0
    @State private var shockwaves: [Shockwave] = []
    @State private var petTreats: [PetTreat] = []
    @State private var pinballs: [PinballBall] = []
    @State private var arcadeScore: Int = 0
    @State private var pullDragOffset: CGFloat = 0
    @State private var pullDragOffsetX: CGFloat = 0
    @State private var pullDragOffsetY: CGFloat = 0
    @State private var localKeyMonitor: Any? = nil
    @State private var globalKeyMonitor: Any? = nil
    @State private var mouseMonitor: Any? = nil
    @State private var stationDragOffsetY: CGFloat = 0.0
    @State private var isDraggingStationSlider: Bool = false
    @State private var isVerticalScrollBarHovered: Bool = false
    @State private var lastVerticalScrollTime: TimeInterval = 0

    // ── 3-Stage Applications Elevation Hierarchy (Hidden, Middle, FullScreen) ──
    @AppStorage(PrefKey.appDisplayStage) var appDisplayStageRaw: Int = 0 // Default: .hidden (0)
    @AppStorage(PrefKey.isChatDetached) var isChatDetached: Bool = false

    var appDisplayStage: AppDisplayStage {
        get {
            AppDisplayStage(rawValue: appDisplayStageRaw) ?? .hidden
        }
        nonmutating set {
            appDisplayStageRaw = newValue.rawValue
        }
    }

    // Appearance & Layout Shape Settings
    @AppStorage(PrefKey.showAppNames) var showAppNames: Bool = false
    @AppStorage(PrefKey.showPageIndicator) var showPageIndicator: Bool = false
    @AppStorage(PrefKey.iconSize) var iconSize: Double = 64.0
    @AppStorage(PrefKey.textSize) var textSize: Double = 11.0
    @AppStorage(PrefKey.spacing) var itemSpacing: Double = 16.0
    @AppStorage(PrefKey.enableMagnification) var enableMagnification: Bool = false
    @AppStorage(PrefKey.magnificationScale) var maxMagnification: Double = 1.65
    @AppStorage(PrefKey.wallpaperMode) var wallpaperMode: String = "Genie"
    @AppStorage(PrefKey.sameWallpaperMode) var sameWallpaperMode: Bool = true
    @AppStorage(PrefKey.wallpaperMatchingStyle) var wallpaperMatchingStyle: String = "Exact Mirror (1:1)"
    @AppStorage(PrefKey.wallpaperTreatment) var wallpaperTreatment: String = "Exact Mirror (1:1)"
    @AppStorage(PrefKey.appIconTheme) var appIconTheme: String = "Default"
    @AppStorage(PrefKey.alwaysOnDesktop) var alwaysOnDesktop: Bool = false
    @AppStorage(PrefKey.appIconTintColor) var appIconTintColor: String = "Emerald"
    @AppStorage(PrefKey.iconSnuggie) var iconSnuggie: String = "None"
    
    // Curated Selection-Guaranteed Shapes & Living Ambient Entities
    @AppStorage(PrefKey.appFormation) var appFormation: String = "Responsive Grid"
    @AppStorage(PrefKey.chatGridPadding) var chatGridPadding: Double = 48.0
    @AppStorage(PrefKey.ambientEntity) var ambientEntity: String = "None"
    @AppStorage(PrefKey.dragonFollowCursor) var dragonFollowCursor: Bool = true
    @State private var desktopScrollOffsetY: CGFloat = 0.0

    // Dynamic Wallpaper Effects Engine
    @AppStorage(PrefKey.wallpaperFxEnabled) var wallpaperFxEnabled: Bool = false
    @AppStorage(PrefKey.wallpaperFxType) var wallpaperFxType: String = "Cosmic Aurora"
    @AppStorage(PrefKey.wallpaperFxIntensity) var wallpaperFxIntensity: Double = 0.35

    // Kinetic & Orbit Dynamics
    @AppStorage(PrefKey.orbitSpeed) var orbitSpeed: Double = 1.0
    @AppStorage(PrefKey.orbitClockwise) var orbitClockwise: Bool = true
    @AppStorage(PrefKey.pulseIntensity) var pulseIntensity: Double = 0.5

    // Living Background App Physics Simulation
    @AppStorage(PrefKey.appPhysicsSimulation) var appPhysicsSimulation: String = "None"

    // Cursor FX Animation Engine
    @AppStorage(PrefKey.cursorFxType) var cursorFxType: String = "None"
    @AppStorage(PrefKey.smokeStyle) var smokeStyle: String = "Mystical Cyan 🧞‍♂️"

    // Page 1 vs Page 2 Default Behavior
    @AppStorage(PrefKey.defaultPageMode) var defaultPageMode: String = "Page 1 (Apps Direct)"
    @AppStorage(PrefKey.desktopSplitMode) var desktopSplitMode: String = "Full Screen"
    @AppStorage(PrefKey.gridTransitionDirection) var gridTransitionDirection: String = "Pull Up from Bottom"
    @AppStorage(PrefKey.searchBarPlacement) var searchBarPlacement: String = "Meet in Middle (Top Chat, Bottom Apps) ⚖️"
    @AppStorage(PrefKey.middleSplitRatio) var middleSplitRatio: Double = 0.44
    // Edge Sliding Dock (the merged Chat + Applications dock lives on the right only)
    @AppStorage(PrefKey.rightEdgeDocksEnabled) var rightEdgeDocksEnabled: Bool = true
    @AppStorage(PrefKey.isRightChatDockOpen) var isRightChatDockOpen: Bool = false
    @AppStorage(PrefKey.isRightAppsDockOpen) var isRightAppsDockOpen: Bool = false
    @AppStorage(PrefKey.rightDocksCoexistMode) var rightDocksCoexistMode: String = "Side-by-Side 📐"
    @State private var isTopSearchBarPoppedDown: Bool = false
    @State private var isSearchBarTyping: Bool = false
    @AppStorage(PrefKey.bottomEdgeCursorTrigger) var bottomEdgeCursorTrigger: Bool = false
    @AppStorage(PrefKey.topEdgeCursorTrigger) var topEdgeCursorTrigger: Bool = false
    @AppStorage(PrefKey.swipeSensitivity) var swipeSensitivity: String = "Deliberate (Firm Swipe)"
    @AppStorage(PrefKey.swipeTriggerZone) var swipeTriggerZone: String = "Both (Top & Bottom)"
    @AppStorage(PrefKey.dockAvoidanceEnabled) var dockAvoidanceEnabled: Bool = true
    @AppStorage(PrefKey.dockRestPeriod) var dockRestPeriod: Double = 0.65

    // Arcade Pinball Mode & Pin to Desktop
    @AppStorage(PrefKey.pinballModeEnabled) var pinballModeEnabled: Bool = false
    @AppStorage(PrefKey.pinToDesktopEnabled) var pinToDesktopEnabled: Bool = false
    @AppStorage(PrefKey.formationAppLimit) var formationAppLimit: Int = 0
    @AppStorage(PrefKey.customFormationColumns) var customFormationColumns: Int = 4

    private var apps: [AppInfo] {
        let all = appModel.visibleApps
        if formationAppLimit > 0 && formationAppLimit < all.count {
            return Array(all.prefix(formationAppLimit))
        }
        return all
    }

    private func determineInitialPage() -> Int {
        if alwaysOnDesktop || pinToDesktopEnabled {
            return 1
        }
        switch defaultPageMode {
        case "Page 1 (Apps Direct)":
            return 1
        case "Page 2 (Clean Desktop First)":
            return 0
        default: // "Auto (Page 2 if Desktop Files Exist)"
            return hasDesktopUserFiles() ? 0 : 1
        }
    }

    private func hasDesktopUserFiles() -> Bool {
        guard let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first else { return false }
        let keys: [URLResourceKey] = [.isHiddenKey]
        guard let contents = try? FileManager.default.contentsOfDirectory(at: desktopURL, includingPropertiesForKeys: keys, options: [.skipsHiddenFiles]) else {
            return false
        }
        let userFiles = contents.filter { fileURL in
            let name = fileURL.lastPathComponent
            return !name.hasPrefix(".") && !name.hasPrefix("Nexus_Backup")
        }
        return !userFiles.isEmpty
    }

    var body: some View {
        GeometryReader { screenGeo in
            let screenSize = screenGeo.size
            let targetScreen = self.screen ?? NSScreen.main ?? (NSScreen.screens.first ?? NSScreen())

            let notchHeight = targetScreen.safeAreaInsets.top
            let menuBarHeight = targetScreen.frame.maxY - targetScreen.visibleFrame.maxY
            let topClearance = max(notchHeight + 28.0, menuBarHeight + 20.0, 58.0)
            let dockInset = targetScreen.visibleFrame.minY - targetScreen.frame.minY
            let bottomClearance = dockAvoidanceEnabled ? max(78.0, dockInset + 28.0) : max(56.0, dockInset + 16.0)
            let sideMargin = max(40.0, max(targetScreen.visibleFrame.minX - targetScreen.frame.minX, targetScreen.frame.maxX - targetScreen.visibleFrame.maxX) + 24.0)

            let usableWidth = max(300.0, screenSize.width - (sideMargin * 2.0))
            let usableHeight = max(200.0, screenSize.height - topClearance - bottomClearance)
            let curIconSize = CGFloat(iconSize)
            let curTextSize = CGFloat(textSize)
            let curSpacing = CGFloat(itemSpacing)
            let nameHeight: CGFloat = showAppNames ? (curTextSize + 8.0) : 0.0

            ZStack(alignment: .top) {
                // 100% Pure Transparent Base & Dismiss on Empty Space Click or Pull
                Color.clear
                    .ignoresSafeArea()
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 8)
                            .onChanged { value in
                                guard !isEditing else { return }
                                if !wallpaperEngine.isDragging {
                                    wallpaperEngine.onDragBegan(location: value.startLocation, in: screenSize)
                                }
                                wallpaperEngine.onDragChanged(
                                    translation: CGSize(width: value.translation.width, height: value.translation.height),
                                    location: value.location,
                                    in: screenSize
                                )
                                let isHorizontal = (gridTransitionDirection == "Slide from Right (iPhone Mode 📱)" || gridTransitionDirection == "Slide from Left (Sidebar ⬅️)")
                                if isHorizontal {
                                    pullDragOffsetX = value.translation.width * 0.80
                                    pullDragOffsetY = 0
                                } else {
                                    pullDragOffsetX = 0
                                    // 1:1 Interactive iOS-style pull tracking with elastic resistance
                                    pullDragOffsetY = value.translation.height * 0.85
                                }
                            }
                            .onEnded { value in
                                guard !isEditing else { return }
                                wallpaperEngine.onDragEnded(
                                    finalTranslation: CGSize(width: value.translation.width, height: value.translation.height),
                                    predictedEndTranslation: CGSize(width: value.predictedEndTranslation.width, height: value.predictedEndTranslation.height),
                                    in: screenSize
                                )
                                let dy = value.translation.height
                                let predictedDy = value.predictedEndTranslation.height
                                let dx = value.translation.width
                                let predictedDx = value.predictedEndTranslation.width
                                let isHorizontal = (gridTransitionDirection == "Slide from Right (iPhone Mode 📱)" || gridTransitionDirection == "Slide from Left (Sidebar ⬅️)")

                                if isHorizontal {
                                    var shouldDismiss = false
                                    if gridTransitionDirection == "Slide from Right (iPhone Mode 📱)" {
                                        shouldDismiss = dx > 50 || predictedDx > 80
                                    } else {
                                        shouldDismiss = dx < -50 || predictedDx < -80
                                    }
                                    if shouldDismiss && !pinToDesktopEnabled && !alwaysOnDesktop {
                                        HapticFeedback.tick()
                                        withAnimation(.spring(response: 0.38, dampingFraction: 0.80)) {
                                            pullDragOffsetX = 0
                                            pullDragOffsetY = 0
                                            pullDragOffset = 0
                                            currentPage = 0
                                            appDisplayStage = .hidden
                                            isTopSearchBarPoppedDown = false
                                        }
                                        DesktopWindowManager.shared.setPage(0)
                                        NotificationCenter.default.post(name: NSNotification.Name("NexusDesktopPageChanged"), object: 0)
                                    } else {
                                        withAnimation(.spring(response: 0.30, dampingFraction: 0.78)) {
                                            pullDragOffsetX = 0
                                            pullDragOffsetY = 0
                                            pullDragOffset = 0
                                        }
                                    }
                                    return
                                }

                                // ── Unified Continuous Canvas Gesture Engine: Single Vertical Axis ──
                                let currentStation = DesktopWindowManager.shared.currentStation

                                if dy < -45 || predictedDy < -80 {
                                    // 🔼 Drag/Swipe UP: Ascend toward Desktop (from Apps) or Chat (from Desktop)
                                    HapticFeedback.selection()
                                    withAnimation(.spring(response: 0.38, dampingFraction: 0.80)) {
                                        pullDragOffsetX = 0
                                        pullDragOffsetY = 0
                                        pullDragOffset = 0
                                        if currentStation == .applications || appDisplayStage == .fullScreen {
                                            DesktopWindowManager.shared.switchToStation(.desktop)
                                        } else {
                                            DesktopWindowManager.shared.switchToStation(.chat)
                                        }
                                    }
                                } else if dy > 45 || predictedDy > 80 {
                                    // 🔽 Drag/Swipe DOWN: Descend toward Desktop (from Chat) or Applications (from Desktop)
                                    HapticFeedback.selection()
                                    withAnimation(.spring(response: 0.38, dampingFraction: 0.80)) {
                                        pullDragOffsetX = 0
                                        pullDragOffsetY = 0
                                        pullDragOffset = 0
                                        if currentStation == .chat || isTopSearchBarPoppedDown {
                                            DesktopWindowManager.shared.switchToStation(.desktop)
                                        } else {
                                            DesktopWindowManager.shared.switchToStation(.applications)
                                        }
                                    }
                                } else {
                                    // Elastic spring recovery on minor drag
                                    withAnimation(.spring(response: 0.30, dampingFraction: 0.78)) {
                                        pullDragOffsetX = 0
                                        pullDragOffsetY = 0
                                        pullDragOffset = 0
                                    }
                                }
                            }
                    )
                    .onTapGesture(count: 1) {
                        NotificationCenter.default.post(name: NSNotification.Name("NexusClose"), object: nil)
                        // Sidebar and chat dismiss together when clicking desktop
                        if isRightChatDockOpen || isRightAppsDockOpen || FinderChatWindowManager.shared.isVisible {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.80)) {
                                isRightChatDockOpen = false
                                isRightAppsDockOpen = false
                            }
                            FinderChatWindowManager.shared.hide()
                        }
                        guard !isEditing else {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                isEditing = false
                            }
                            return
                        }
                        if currentPage == 1 {
                            // Toggle click on inactive space toggles apps hidden/unhidden states for chat/apps
                            HapticFeedback.selection()
                            withAnimation(.spring(response: 0.30, dampingFraction: 0.82)) {
                                if appDisplayStage == .hidden {
                                    // Toggles apps UNHIDDEN (brings apps up alongside chat/wallpaper!)
                                    appDisplayStage = .fullScreen
                                } else {
                                    // Toggles apps HIDDEN (apps slide down, chat with wallpaper remains!)
                                    appDisplayStage = .hidden
                                    isTopSearchBarPoppedDown = true
                                }
                            }
                        }
                    }
                    // Only claim the whole screen while the plane is actually presenting. While it is
                    // dismissed this window still spans the display above the desktop icon layer, so a
                    // full-screen hit area here would swallow every click meant for the Finder desktop.
                    .allowsHitTesting(currentPage == 1)

                // WALLPAPER & TRANSLUCENT GLASS LAYER (Active on Page 1)
                // 1. "Genie" / "1:1 Camouflage": 100% transparent pass-through with NO background!
                //    The apps overlay directly on top of active desktop and open applications like a genie gliding up.
                // 2. "Translucent": Frosted acrylic aero glass blur overlaying open windows.
                // 3. "Second Wallpaper": Independent 4K curated or custom wallpaper.
                let activeTreatment = (wallpaperTreatment != "Exact Mirror (1:1)" ? wallpaperTreatment : wallpaperMatchingStyle)
                let isGenieMode = (wallpaperMode == "Genie" || wallpaperMode == "1:1 Camouflage" || sameWallpaperMode)
                let isTranslucentMode = !isGenieMode && (wallpaperMode == "Translucent" || activeTreatment == "Translucent" || activeTreatment == "Translucent Frosted Glass" || activeTreatment == "100% Translucent Pass-Through")

                ZStack {
                    let wallpaper = wallpaperManager.activeWallpaperImage ?? wallpaperSampler.wallpaperImage ?? WallpaperManager.shared.generateCuratedWallpaper(named: wallpaperMatchingStyle)
                    Image(nsImage: wallpaper)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: screenSize.width, height: screenSize.height)
                        .clipped()

                    if isTranslucentMode {
                        VisualEffectBlur(material: .fullScreenUI, blendingMode: .behindWindow, state: .active)
                            .opacity(0.88)
                    }

                    switch activeTreatment {
                    case "Clear Water Caustics", "Clear Water Glass":
                        ClearWaterCausticsCanvas(screenSize: screenSize, isPaused: currentPage != 1)
                    case "Cyber Vector Grid", "Cyber Grid":
                        CyberVectorGridCanvas(screenSize: screenSize)
                    case "Obsidian Velvet Tint":
                        Color.black.opacity(0.35)
                    case "Soft Frosted Glass", "Translucent Frosted Glass":
                        VisualEffectBlur(material: .fullScreenUI, blendingMode: .behindWindow, state: .active)
                            .opacity(0.65)
                    case "Golden Gate Sunset":
                        LinearGradient(
                            colors: [Color.orange.opacity(0.25), Color.purple.opacity(0.20)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    case "Dimmed Focus (15% Darker)":
                        Color.black.opacity(0.15)
                    default:
                        EmptyView()
                    }
                }
                .frame(width: screenSize.width, height: screenSize.height)
                .offset(
                    x: (pullDragOffsetX * 0.35) + wallpaperEngine.offset(for: .wallpaper).width,
                    y: (pullDragOffsetY * 0.35) + wallpaperEngine.offset(for: .wallpaper).height
                )
                .modifier(ParallaxIllusionGlassModifier(enablesTilt: true, enablesRefraction: true, enablesSpecular: true))
                .scaleEffect(isTopSearchBarPoppedDown ? 1.02 : 1.0)
                .blur(radius: isTopSearchBarPoppedDown ? 10.0 : 0.0)
                .overlay(
                    Color.black.opacity(isTopSearchBarPoppedDown ? 0.22 : 0.0)
                )
                .opacity(currentPage == 1 ? 1.0 : 0.0)
                .animation(.spring(response: 0.38, dampingFraction: 0.82), value: isTopSearchBarPoppedDown)
                .animation(.easeInOut(duration: 0.22), value: currentPage)
                .allowsHitTesting(false)

                // UNIFIED HARDWARE-ACCELERATED METAL CANVAS (Wallpaper FX, Living Pets, Cursor Trails, Pinballs)
                // Runs on the desktop plane as well as the summoned canvas so cursor trails and
                // ambient art stay visible while you work. The canvas pauses its own timeline when
                // no layer is enabled, so an idle desktop costs nothing.
                UnifiedAmbientMetalCanvas(
                    wallpaperEnabled: wallpaperFxEnabled && !isGenieMode,
                    wallpaperFxType: wallpaperFxType,
                    wallpaperIntensity: CGFloat(wallpaperFxIntensity),
                    ambientEntity: isEditing ? "None" : ambientEntity,
                    entityTheme: appIconTheme,
                    cursorFxType: cursorFxType,
                    mouseLocation: mouseLocation,
                    cursorTrail: cursorTrail,
                    dragonFollow: false,
                    petTreats: [],
                    pinballEnabled: false,
                    pinballs: [],
                    screenSize: screenSize
                )
                .allowsHitTesting(false)

                // INTERACTIVE LAUNCH SHOCKWAVES & BURSTS (Disabled for production stability)
                /*
                ForEach(shockwaves) { wave in
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [wave.color.opacity(wave.opacity), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: wave.lineWidth
                        )
                        .frame(width: wave.size, height: wave.size)
                        .position(wave.center)
                        .allowsHitTesting(false)
                }
                */


                // GEOMETRIC APPS MATRIX (120 FPS CoreAnimation Pipeline)
                GeometricAppsMatrix(
                    apps: apps,
                    formation: appFormation,
                    physicsSimulation: isEditing ? "None" : appPhysicsSimulation,
                    physicsPhase: physicsOffsetPhase,
                    orbitSpeed: orbitSpeed,
                    orbitClockwise: orbitClockwise,
                    pulseIntensity: pulseIntensity,
                    screenSize: screenSize,
                    usableWidth: usableWidth,
                    usableHeight: usableHeight,
                    topClearance: topClearance,
                    sideMargin: sideMargin,
                    iconSize: curIconSize,
                    textSize: curTextSize,
                    curSpacing: curSpacing,
                    nameHeight: nameHeight,
                    showName: showAppNames,
                    theme: appIconTheme,
                    tintColor: appIconTintColor,
                    iconSnuggie: iconSnuggie,
                    desktopSplitMode: desktopSplitMode,
                    customFormationColumns: customFormationColumns,
                    scrollOffsetY: desktopScrollOffsetY,
                    flamePhase: animPhase * 60.0,
                    wallpaperImage: wallpaperSampler.wallpaperImage,
                    isEditing: isEditing,
                    wiggle: wiggle,
                    enableMagnification: enableMagnification && !isEditing,
                    maxMagnification: CGFloat(maxMagnification),
                    mouseLocation: mouseLocation,
                    draggedAppID: $draggedAppID,
                    dragOffset: $dragCurrentOffset,
                    dragHoverTargetID: $dragHoverTargetID,
                    onLaunch: { app, center in
                        HapticFeedback.heavy()
                        triggerLaunchShockwave(at: center)
                        appModel.launch(app)
                        if !alwaysOnDesktop && !pinToDesktopEnabled {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                                    currentPage = 0
                                }
                                DesktopWindowManager.shared.setPage(0)
                            }
                        }
                    },
                    onHideApp: { app in
                        HapticFeedback.selection()
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                            appModel.hideApp(app)
                        }
                    },
                    onShowInFinder: { app in
                        appModel.showInFinder(app)
                    },
                    onEnterEditMode: {
                        HapticFeedback.selection()
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                            isEditing = true
                        }
                    },
                    onMoveApp: { srcID, dstID in
                        appModel.moveApp(from: srcID, to: dstID)
                    }
                )
                // Reserve the floating right dock's footprint so desktop icons remain clear of it.
                .padding(.trailing, rightEdgeDocksEnabled ? 82 : 0)
                .frame(width: screenSize.width, height: screenSize.height, alignment: .topLeading)
                .offset(
                    x: transitionOffset(screenSize: screenSize).x + pullDragOffsetX + wallpaperEngine.offset(for: .desktopFiles).width,
                    y: transitionOffset(screenSize: screenSize).y + pullDragOffsetY + wallpaperEngine.offset(for: .desktopFiles).height + (
                        (searchBarPlacement == "Meet in Middle (Top Chat, Bottom Apps) ⚖️" && appDisplayStage == .hidden && !appFormation.contains("Responsive") && !appFormation.contains("Surround"))
                            ? (isSearchBarTyping ? screenSize.height * 0.55 : screenSize.height * middleSplitRatio)
                            : (appDisplayStage == .hidden ? screenSize.height : (appDisplayStage == .middle ? screenSize.height * 0.22 : 0))
                    )
                )
                .scaleEffect(
                    (appDisplayStage == .hidden) ? 0.92
                        : (isTopSearchBarPoppedDown ? 0.94 : (isSearchBarTyping ? 0.94 : 1.0))
                )
                .blur(radius: (isTopSearchBarPoppedDown && appDisplayStage == .hidden) ? 4.0 : 0.0)
                .opacity(
                    (currentPage == 1 && appDisplayStage != .hidden) ? (isSearchBarTyping ? 0.08 : 1.0)
                        : (isTopSearchBarPoppedDown ? 0.12 : 0.0)
                )
                .allowsHitTesting(currentPage == 1 && appDisplayStage != .hidden && !isSearchBarTyping && !isTopSearchBarPoppedDown)
                .animation(.spring(response: 0.38, dampingFraction: 0.80), value: currentPage)
                .animation(.spring(response: 0.38, dampingFraction: 0.80), value: isSearchBarTyping)
                .animation(.spring(response: 0.38, dampingFraction: 0.80), value: appDisplayStageRaw)
                .animation(.spring(response: 0.38, dampingFraction: 0.80), value: isTopSearchBarPoppedDown)

                // Top Floating Overlays & Controls (1.2x Hyper-Parallax HUD Layer)
                topFloatingOverlays(
                    screenSize: screenSize,
                    usableWidth: usableWidth,
                    usableHeight: usableHeight,
                    topClearance: topClearance,
                    bottomClearance: bottomClearance,
                    sideMargin: sideMargin
                )
                .offset(x: wallpaperEngine.offset(for: .floatingHUD).width, y: wallpaperEngine.offset(for: .floatingHUD).height)

                // 📱 Right-Edge Sliding Docks & Floating Trigger Tabs (Disabled for production: single window consolidated)
                // rightEdgeDocksContainer(screenSize: screenSize, topClearance: topClearance, bottomClearance: bottomClearance)
                //     .zIndex(60)

                // Continuous Panoramic Vertical Scrollbar (Zenith Chat, Horizon Desktop, Nadir Apps)
                continuousVerticalScrollBar(screenSize: screenSize)
                    .zIndex(40)

                // 📱 iPhone Home Indicator Bar (Swipe Up for Apps, Swipe Down to Retrieve)
                if !isEditing && appDisplayStage == .hidden {
                    iPhoneHomeIndicatorBar(screenSize: screenSize, bottomClearance: bottomClearance)
                }
            }
            .coordinateSpace(name: "FullscreenCanvas")
            .frame(width: screenSize.width, height: screenSize.height)
            .onContinuousHover { phase in
                switch phase {
                case .active(let location):
                    mouseLocation = location
                    updateCursorTrail(location)
                    wallpaperEngine.updateCursor(location: location, in: screenSize)
                    if !isEditing {
                        let now = ProcessInfo.processInfo.systemUptime
                        if now - lastPageSwitchTime > 0.25 {
                            // 1. Left Edge: cursor left screen pops out our chat dock (opens the merged chat on the right sidebar)
                            if location.x <= 10 && !isRightChatDockOpen {
                                lastPageSwitchTime = now
                                HapticFeedback.selection()
                                withAnimation(.spring(response: 0.36, dampingFraction: 0.70)) {
                                    isRightChatDockOpen = true
                                    isRightAppsDockOpen = false
                                    isTopSearchBarPoppedDown = false
                                    appDisplayStage = .hidden
                                }
                            }
                            // 2. Mouse down to bottom edge: brings apps up! ("bottom dock normal is dock up")
                            else if (currentPage == 0 || appDisplayStage == .hidden) && location.y >= screenSize.height - 24 && bottomEdgeCursorTrigger {
                                lastPageSwitchTime = now
                                HapticFeedback.selection()
                                withAnimation(.spring(response: 0.36, dampingFraction: 0.70)) {
                                    currentPage = 1
                                    appDisplayStage = .fullScreen
                                    isTopSearchBarPoppedDown = false
                                    isRightChatDockOpen = false
                                    isRightAppsDockOpen = false
                                }
                                DesktopWindowManager.shared.setPage(1)
                                NotificationCenter.default.post(name: NSNotification.Name("NexusDesktopPageChanged"), object: 1)
                            }
                            // 3. Top edge: optional top dock down from notch! ("and optional top dock down")
                            else if (currentPage == 0 || appDisplayStage != .hidden || !isTopSearchBarPoppedDown) && location.y <= 6 && topEdgeCursorTrigger && !CustomMenuBarManager.shared.isEnabled {
                                lastPageSwitchTime = now
                                HapticFeedback.selection()
                                withAnimation(.spring(response: 0.36, dampingFraction: 0.70)) {
                                    currentPage = 1
                                    appDisplayStage = .hidden
                                    isTopSearchBarPoppedDown = true
                                    isRightChatDockOpen = false
                                    isRightAppsDockOpen = false
                                }
                                DesktopWindowManager.shared.setPage(1)
                                NotificationCenter.default.post(name: NSNotification.Name("NexusDesktopPageChanged"), object: 1)
                                NotificationCenter.default.post(name: NSNotification.Name("NexusFocusGenieSearchBar"), object: nil)
                            }
                            // 3b. Right Edge: bumping right edge of the screen reveals right dock / activates right edge tabs
                            else if location.x >= screenSize.width - 10 && !rightEdgeDocksEnabled {
                                lastPageSwitchTime = now
                                HapticFeedback.selection()
                                withAnimation(.spring(response: 0.36, dampingFraction: 0.70)) {
                                    rightEdgeDocksEnabled = true
                                }
                            }
                            // 4. Mouse up to hide: when apps are up, moving mouse up past the top boundary retrieves them down
                            else if currentPage == 1 && appDisplayStage == .fullScreen && location.y <= 4 && !isSearchBarTyping && !pinToDesktopEnabled && !alwaysOnDesktop && !CustomMenuBarManager.shared.isEnabled {
                                lastPageSwitchTime = now
                                HapticFeedback.tick()
                                withAnimation(.spring(response: 0.36, dampingFraction: 0.70)) {
                                    currentPage = 0
                                    appDisplayStage = .hidden
                                    isTopSearchBarPoppedDown = false
                                }
                                DesktopWindowManager.shared.setPage(0)
                                NotificationCenter.default.post(name: NSNotification.Name("NexusDesktopPageChanged"), object: 0)
                            }
                            // 5. Mouse down to hide: when chat is up, moving mouse down towards bottom edge can hide
                            else if currentPage == 1 && appDisplayStage == .hidden && isTopSearchBarPoppedDown && location.y >= screenSize.height - 12 && !isSearchBarTyping && !pinToDesktopEnabled && !alwaysOnDesktop {
                                lastPageSwitchTime = now
                                HapticFeedback.tick()
                                withAnimation(.spring(response: 0.36, dampingFraction: 0.70)) {
                                    currentPage = 0
                                    isTopSearchBarPoppedDown = false
                                }
                                DesktopWindowManager.shared.setPage(0)
                                NotificationCenter.default.post(name: NSNotification.Name("NexusDesktopPageChanged"), object: 0)
                            }
                        }
                    }
                case .ended:
                    mouseLocation = nil
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusDesktopScrollWheel"))) { notif in
                guard !isEditing, let event = notif.object as? NSEvent else { return }
                handleScrollEvent(event)
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusThreeFingerDragDown"))) { _ in
                guard !isEditing else { return }
                let now = ProcessInfo.processInfo.systemUptime
                guard now - lastPageSwitchTime > 0.20 else { return }
                lastPageSwitchTime = now
                HapticFeedback.tick()
                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                    pullDragOffsetX = 0
                    pullDragOffsetY = 0
                    pullDragOffset = 0
                    desktopScrollOffsetY = 0
                    currentPage = 0
                }
                DesktopWindowManager.shared.setPage(0)
                NotificationCenter.default.post(name: NSNotification.Name("NexusDesktopPageChanged"), object: 0)
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusDesktopPageChanged"))) { _ in
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusThreeFingerDragLeft"))) { _ in
                guard !isEditing else { return }
                let now = ProcessInfo.processInfo.systemUptime
                guard now - lastPageSwitchTime > 0.30 else { return }
                lastPageSwitchTime = now
                let isRightSlide = (gridTransitionDirection == "Slide from Right (iPhone Mode 📱)")
                let isLeftSlide = (gridTransitionDirection == "Slide from Left (Sidebar ⬅️)")
                if isRightSlide && currentPage == 0 {
                    HapticFeedback.selection()
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        currentPage = 1
                    }
                    NotificationCenter.default.post(name: NSNotification.Name("NexusDesktopPageChanged"), object: 1)
                } else if isLeftSlide && currentPage == 1 {
                    HapticFeedback.tick()
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        currentPage = 0
                    }
                    NotificationCenter.default.post(name: NSNotification.Name("NexusDesktopPageChanged"), object: 0)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusThreeFingerDragRight"))) { _ in
                guard !isEditing else { return }
                let now = ProcessInfo.processInfo.systemUptime
                guard now - lastPageSwitchTime > 0.30 else { return }
                lastPageSwitchTime = now
                let isRightSlide = (gridTransitionDirection == "Slide from Right (iPhone Mode 📱)")
                let isLeftSlide = (gridTransitionDirection == "Slide from Left (Sidebar ⬅️)")
                if isLeftSlide && currentPage == 0 {
                    HapticFeedback.selection()
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        currentPage = 1
                    }
                    NotificationCenter.default.post(name: NSNotification.Name("NexusDesktopPageChanged"), object: 1)
                } else if isRightSlide && currentPage == 1 {
                    HapticFeedback.tick()
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        currentPage = 0
                    }
                    NotificationCenter.default.post(name: NSNotification.Name("NexusDesktopPageChanged"), object: 0)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusSwitchToDesktopStation"))) { _ in
                withAnimation(.spring(response: 0.44, dampingFraction: 0.88)) {
                    pullDragOffsetX = 0
                    pullDragOffsetY = 0
                    pullDragOffset = 0
                    currentPage = 0
                    appDisplayStage = .hidden
                    isTopSearchBarPoppedDown = false
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusSwitchToChatStation"))) { _ in
                withAnimation(.spring(response: 0.44, dampingFraction: 0.88)) {
                    pullDragOffsetX = 0
                    pullDragOffsetY = 0
                    pullDragOffset = 0
                    currentPage = 1
                    appDisplayStage = .hidden
                    isTopSearchBarPoppedDown = false
                }
                FinderChatWindowManager.shared.show()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusSwitchToAppsStation"))) { _ in
                withAnimation(.spring(response: 0.44, dampingFraction: 0.88)) {
                    pullDragOffsetX = 0
                    pullDragOffsetY = 0
                    pullDragOffset = 0
                    currentPage = 1
                    appDisplayStage = .fullScreen
                    isTopSearchBarPoppedDown = false
                    isRightChatDockOpen = false
                    isRightAppsDockOpen = false
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusToggleRightChatDock"))) { _ in
                withAnimation(.spring(response: 0.36, dampingFraction: 0.70)) {
                    if !isRightChatDockOpen {
                        isRightAppsDockOpen = false
                        isTopSearchBarPoppedDown = false
                        appDisplayStage = .hidden
                    }
                    isRightChatDockOpen.toggle()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusToggleRightAppsDock"))) { _ in
                // No applications pop up
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusCloseAllRollupsExceptChat"))) { _ in
                withAnimation(.spring(response: 0.36, dampingFraction: 0.70)) {
                    isRightAppsDockOpen = false
                    isTopSearchBarPoppedDown = false
                    appDisplayStage = .hidden
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusCloseAllRollupsExceptApps"))) { _ in
                withAnimation(.spring(response: 0.36, dampingFraction: 0.70)) {
                    isRightChatDockOpen = false
                    isTopSearchBarPoppedDown = false
                    appDisplayStage = .hidden
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusDesktopPageChanged"))) { notif in
                if let targetPage = notif.object as? Int, targetPage != currentPage {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        pullDragOffsetX = 0
                        pullDragOffsetY = 0
                        pullDragOffset = 0
                        currentPage = targetPage
                        if targetPage == 1 && appDisplayStage == .hidden {
                            appDisplayStage = .fullScreen
                        }
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusSetDesktopPage"))) { notif in
                if let targetPage = notif.object as? Int {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
                        currentPage = targetPage
                        if targetPage == 1 && appDisplayStage == .hidden {
                            appDisplayStage = .fullScreen
                        }
                    }
                    NotificationCenter.default.post(name: NSNotification.Name("NexusDesktopPageChanged"), object: targetPage)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusAlwaysOnDesktopToggled"))) { notif in
                if let isEnabled = notif.object as? Bool {
                    alwaysOnDesktop = isEnabled
                    if isEnabled {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                            currentPage = 1
                            if appDisplayStage == .hidden {
                                appDisplayStage = .fullScreen
                            }
                        }
                        NotificationCenter.default.post(name: NSNotification.Name("NexusDesktopPageChanged"), object: 1)
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusBottomEdgeHit"))) { _ in
                guard !isEditing else { return }
                let now = ProcessInfo.processInfo.systemUptime
                guard now - lastPageSwitchTime > 0.20 else { return }
                lastPageSwitchTime = now
                HapticFeedback.selection()
                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                    if currentPage == 0 || appDisplayStage == .hidden {
                        currentPage = 1
                        appDisplayStage = .fullScreen
                        DesktopWindowManager.shared.setPage(1)
                        NotificationCenter.default.post(name: NSNotification.Name("NexusDesktopPageChanged"), object: 1)
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusTopEdgeHit"))) { _ in
                guard !isEditing else { return }
                let now = ProcessInfo.processInfo.systemUptime
                guard now - lastPageSwitchTime > 0.20 else { return }
                lastPageSwitchTime = now
                HapticFeedback.selection()
                FinderChatWindowManager.shared.toggle()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusDesktopFilesToggled"))) { notif in
                let isVisible = (notif.object as? Bool) ?? true
                withAnimation(.easeInOut(duration: 0.20)) {
                    desktopFilesManager.areDesktopFilesVisible = isVisible
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusPinToDesktopToggled"))) { notif in
                let isPinned = (notif.object as? Bool) ?? pinToDesktopEnabled
                if isPinned {
                    desktopFilesManager.setDesktopFilesVisible(false)
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        currentPage = 1
                    }
                } else {
                    desktopFilesManager.setDesktopFilesVisible(true)
                }
            }
        }
        .background(Color.clear)
        .onChange(of: pinballModeEnabled) { _, isEnabled in
            if !isEnabled {
                pinballs.removeAll()
                arcadeScore = 0
                shockwaves.removeAll()
            }
        }
        .onChange(of: defaultPageMode) { _, newMode in
            let targetPage: Int
            switch newMode {
            case "Page 1 (Apps Direct)": targetPage = 1
            case "Page 2 (Clean Desktop First)": targetPage = 0
            default: targetPage = determineInitialPage()
            }
            withAnimation(.spring(response: 0.38, dampingFraction: 0.86)) {
                currentPage = targetPage
            }
            NotificationCenter.default.post(name: NSNotification.Name("NexusDesktopPageChanged"), object: targetPage)
        }
        .onChange(of: currentPage) { _, newPage in
            if newPage != 1 {
                desktopScrollOffsetY = 0.0
                isSearchBarTyping = false
                // Clear transient pinballs, shockwaves, treats, and cursor trails on desktop dismissal
                pinballs.removeAll()
                shockwaves.removeAll()
                petTreats.removeAll()
                cursorTrail.removeAll()
            }
            NotificationCenter.default.post(name: NSNotification.Name("NexusDesktopPageChanged"), object: newPage)
            DesktopWindowManager.shared.syncCurrentStation(fromPage: newPage, appDisplayStage: appDisplayStage, isTopSearchBarPoppedDown: isTopSearchBarPoppedDown)
        }
        .onChange(of: appDisplayStageRaw) { _, newRaw in
            if newRaw != AppDisplayStage.hidden.rawValue {
                withAnimation(.spring(response: 0.36, dampingFraction: 0.70)) {
                    isRightChatDockOpen = false
                    isRightAppsDockOpen = false
                    isTopSearchBarPoppedDown = false
                }
            }
            DesktopWindowManager.shared.syncCurrentStation(fromPage: currentPage, appDisplayStage: appDisplayStage, isTopSearchBarPoppedDown: isTopSearchBarPoppedDown)
        }
        .onChange(of: isTopSearchBarPoppedDown) { _, isPopped in
            if isPopped {
                withAnimation(.spring(response: 0.36, dampingFraction: 0.70)) {
                    isRightChatDockOpen = false
                    isRightAppsDockOpen = false
                    appDisplayStage = .hidden
                }
            }
            DesktopWindowManager.shared.syncCurrentStation(fromPage: currentPage, appDisplayStage: appDisplayStage, isTopSearchBarPoppedDown: isTopSearchBarPoppedDown)
        }
        .onChange(of: isRightChatDockOpen) { _, isOpen in
            if isOpen {
                isRightChatDockOpen = false
                FinderChatWindowManager.shared.show()
                withAnimation(.spring(response: 0.36, dampingFraction: 0.70)) {
                    isRightAppsDockOpen = false
                    isTopSearchBarPoppedDown = false
                }
            }
        }
        .onChange(of: isRightAppsDockOpen) { _, isOpen in
            if isOpen {
                withAnimation(.spring(response: 0.36, dampingFraction: 0.70)) {
                    isRightChatDockOpen = false
                    isTopSearchBarPoppedDown = false
                    appDisplayStage = .hidden
                }
            }
        }
        .onChange(of: appFormation) { _, _ in
            desktopScrollOffsetY = 0.0
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusSearchBarTextDidChange"))) { notif in
            let text = (notif.object as? String) ?? ""
            let isTyping = !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            withAnimation(.spring(response: 0.30, dampingFraction: 0.80)) {
                isSearchBarTyping = isTyping
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusRevealSearchBarForTyping"))) { _ in
            FinderChatWindowManager.shared.show()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusSearchBarFocusChanged"))) { notif in
            let isFocused = (notif.object as? Bool) ?? false
            withAnimation(.spring(response: 0.30, dampingFraction: 0.80)) {
                if isFocused {
                    isSearchBarTyping = true
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusFormationChanged"))) { notif in
            if let f = notif.object as? String {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.78)) {
                    appFormation = f
                }
                desktopScrollOffsetY = 0.0
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusFormationLimitChanged"))) { notif in
            if let limit = notif.object as? Int {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.80)) {
                    formationAppLimit = limit
                }
            }
        }
        .onAppear {
            let initial = (pinToDesktopEnabled || alwaysOnDesktop) ? 1 : DesktopWindowManager.shared.currentPage
            currentPage = initial
            if appDisplayStage == .hidden {
                appDisplayStage = .fullScreen
            }
            wallpaperSampler.refresh()
            withAnimation(.linear(duration: 60.0).repeatForever(autoreverses: false)) {
                animPhase = 360.0
            }
            withAnimation(.linear(duration: 8.0).repeatForever(autoreverses: true)) {
                physicsOffsetPhase = 1.0
            }

            if localKeyMonitor == nil {
                localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                    let isCmd = event.modifierFlags.contains(.command)
                    let chars = event.charactersIgnoringModifiers ?? ""

                    // Cmd + / Cmd = : Zoom IN on apps
                    if isCmd && (event.keyCode == 24 || chars == "+" || chars == "=") {
                        HapticFeedback.selection()
                        withAnimation(.spring(response: 0.24, dampingFraction: 0.82)) {
                            iconSize = min(120.0, iconSize + 6.0)
                        }
                        return nil
                    }

                    // Cmd - / Cmd _ : Zoom OUT on apps
                    if isCmd && (event.keyCode == 27 || chars == "-" || chars == "_") {
                        HapticFeedback.selection()
                        withAnimation(.spring(response: 0.24, dampingFraction: 0.82)) {
                            iconSize = max(32.0, iconSize - 6.0)
                        }
                        return nil
                    }

                    // Cmd 0 : Reset Zoom
                    if isCmd && (event.keyCode == 29 || chars == "0") {
                        HapticFeedback.selection()
                        withAnimation(.spring(response: 0.24, dampingFraction: 0.82)) {
                            iconSize = 56.0
                        }
                        return nil
                    }

                    if event.keyCode == 53 { // Escape
                        if isEditing {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                                isEditing = false
                            }
                            return nil
                        } else if currentPage == 1 {
                            HapticFeedback.tick()
                            withAnimation(.interpolatingSpring(mass: 0.8, stiffness: 260, damping: 24)) {
                                currentPage = 0
                            }
                            return nil
                        }
                    }

                    // ── Type-To-Activate: if nothing is activated you can just start typing! ──
                    if !isCmd && !event.modifierFlags.contains(.control) && !event.modifierFlags.contains(.option) {
                        let kCode = event.keyCode
                        if kCode != 48 && kCode != 36 && kCode != 76 && kCode != 51 && kCode != 117 && !(kCode >= 123 && kCode <= 126) {
                            if !DesktopWindowManager.isTextInputFieldActive(),
                               let typed = event.characters,
                               !typed.isEmpty,
                               let scalar = typed.unicodeScalars.first,
                               !CharacterSet.controlCharacters.contains(scalar),
                               !CharacterSet.illegalCharacters.contains(scalar),
                               !typed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Task { @MainActor in
                                    DesktopWindowManager.shared.startTypingWithInitialCharacter(typed)
                                }
                                return nil
                            }
                        }
                    }

                    return event
                }
            }

            if globalKeyMonitor == nil {
                globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
                    let isCmd = event.modifierFlags.contains(.command)
                    let chars = event.charactersIgnoringModifiers ?? ""

                    if isCmd && (event.keyCode == 24 || chars == "+" || chars == "=") {
                        HapticFeedback.selection()
                        withAnimation(.spring(response: 0.24, dampingFraction: 0.82)) {
                            iconSize = min(120.0, iconSize + 6.0)
                        }
                    } else if isCmd && (event.keyCode == 27 || chars == "-" || chars == "_") {
                        HapticFeedback.selection()
                        withAnimation(.spring(response: 0.24, dampingFraction: 0.82)) {
                            iconSize = max(32.0, iconSize - 6.0)
                        }
                    } else if isCmd && (event.keyCode == 29 || chars == "0") {
                        HapticFeedback.selection()
                        withAnimation(.spring(response: 0.24, dampingFraction: 0.82)) {
                            iconSize = 56.0
                        }
                    }

                    // ── Global Type-To-Activate: start typing directly from desktop ──
                    if !isCmd && !event.modifierFlags.contains(.control) && !event.modifierFlags.contains(.option) {
                        let kCode = event.keyCode
                        if kCode != 53 && kCode != 48 && kCode != 36 && kCode != 76 && kCode != 51 && kCode != 117 && !(kCode >= 123 && kCode <= 126) {
                            if let typed = event.characters,
                               !typed.isEmpty,
                               let scalar = typed.unicodeScalars.first,
                               !CharacterSet.controlCharacters.contains(scalar),
                               !CharacterSet.illegalCharacters.contains(scalar),
                               !typed.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                let front = NSWorkspace.shared.frontmostApplication
                                let isFinder = (front?.bundleIdentifier == "com.apple.finder")
                                let isGenie = (front?.bundleIdentifier == Bundle.main.bundleIdentifier || front == nil)
                                if isGenie || (isFinder && DesktopWindowManager.shared.isFinderDesktopOnly()) {
                                    Task { @MainActor in
                                        DesktopWindowManager.shared.startTypingWithInitialCharacter(typed)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            if mouseMonitor == nil {
                mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved, .leftMouseDragged, .rightMouseDragged]) { _ in
                    guard self.currentPage == 1 else { return }
                    let mouseLoc = NSEvent.mouseLocation
                    let currentScreen = self.screen ?? NSScreen.main ?? (NSScreen.screens.first ?? NSScreen())
                    if NSPointInRect(mouseLoc, currentScreen.frame) {
                        let localX = mouseLoc.x - currentScreen.frame.minX
                        let localY = currentScreen.frame.maxY - mouseLoc.y
                        let loc = CGPoint(x: localX, y: localY)
                        Task { @MainActor in
                            self.mouseLocation = loc
                            if self.cursorFxType != "None" {
                                self.updateCursorTrail(loc)
                            }
                            if localY <= 16.0 && !self.isTopSearchBarPoppedDown {
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                                    self.isTopSearchBarPoppedDown = true
                                }
                            }
                        }
                    }
                }
            }
        }
        .onDisappear {
            if let l = localKeyMonitor {
                NSEvent.removeMonitor(l)
                localKeyMonitor = nil
            }
            if let g = globalKeyMonitor {
                NSEvent.removeMonitor(g)
                globalKeyMonitor = nil
            }
            if let m = mouseMonitor {
                NSEvent.removeMonitor(m)
                mouseMonitor = nil
            }
        }
        .onChange(of: isEditing) { _, editing in
            if editing {
                withAnimation(.easeInOut(duration: 0.12).repeatForever(autoreverses: true)) {
                    wiggle = true
                }
            } else {
                wiggle = false
            }
        }
        .task {
            if appModel.apps.isEmpty {
                await appModel.load()
            }
        }
    }

    // MARK: - Continuous Panoramic Vertical Scrollbar (Zenith Chat, Horizon Desktop, Nadir Apps)

    @ViewBuilder
    private func continuousVerticalScrollBar(screenSize: CGSize) -> some View {
        HStack {
            Spacer()
            RunningApplicationSlider()
                .padding(.trailing, 58)
        }
        .frame(maxHeight: .infinity, alignment: .trailing)
    }

// MARK: - Continuous Panoramic Spaces Scroll Bridge

struct ContinuousSpacesScrollBridge: NSViewRepresentable {
    var onScrollDelta: (CGFloat) -> Void

    func makeNSView(context: Context) -> SpacesScrollCatcherView {
        let view = SpacesScrollCatcherView()
        view.onScrollDelta = onScrollDelta
        return view
    }

    func updateNSView(_ nsView: SpacesScrollCatcherView, context: Context) {
        nsView.onScrollDelta = onScrollDelta
    }

    class SpacesScrollCatcherView: NSView {
        var onScrollDelta: ((CGFloat) -> Void)?

        override func hitTest(_ point: NSPoint) -> NSView? {
            return nil // Never intercept clicks from SwiftUI buttons
        }

        override func scrollWheel(with event: NSEvent) {
            let delta = (abs(event.scrollingDeltaX) > abs(event.scrollingDeltaY)) ? event.scrollingDeltaX : event.scrollingDeltaY
            onScrollDelta?(delta)
        }
    }
}

    // MARK: - Top Floating Overlays & Interaction Components

    @ViewBuilder
    private func topFloatingOverlays(screenSize: CGSize, usableWidth: CGFloat, usableHeight: CGFloat, topClearance: CGFloat, bottomClearance: CGFloat, sideMargin: CGFloat) -> some View {
        // 1. Top Floating Arcade HUD (Disabled for commercial production release)
        /*
        if currentPage == 1 && pinballModeEnabled && !isEditing {
            arcadeScoreHud(screenSize: screenSize, topClearance: topClearance, sideMargin: sideMargin)
        }
        */

        // 2. Editing Done Button
        if isEditing {
            editingDoneButton(topClearance: topClearance, sideMargin: sideMargin)
        }

        // 3. Liquid Glass Top Pull-Down Dashboard Panel
        if isTopSearchBarPoppedDown && !isEditing {
            LiquidGlassTopDashboardView(isPresented: $isTopSearchBarPoppedDown, screenSize: screenSize)
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
                .zIndex(99)
        }


        // 5. Genie Smoke Overlay Engine
        GenieSmokeOverlayView(style: smokeStyle, bounds: screenSize)
            .allowsHitTesting(false)

        // 6. Top Edge Smart Retractor Drop Zone
        if !isEditing {
            topRetractorDropZone(screenSize: screenSize)
        }

        // 7. Minimal 2-Dot Page Indicator
        if showPageIndicator && !isEditing && appDisplayStage == .hidden {
            pageIndicatorView(screenSize: screenSize)
        }

        // 8. 📱 Right-Edge Sliding Docks & Trigger Tabs (Consolidated into Chat Bar Layer Views)
        // Disabled completely per user request ("the right side bar you have on the right near with the buttons get rid of them put them in the chat")
    }

    // MARK: - 📱 Right-Edge Sliding Unified Dock (Chat, Applications, Screen Matrix, Settings)
    @ViewBuilder
    private func rightEdgeDocksContainer(screenSize: CGSize, topClearance: CGFloat, bottomClearance: CGFloat) -> some View {
        let usableHeight = max(320, screenSize.height - topClearance - bottomClearance - 28)
        let isDockOpen = isRightAppsDockOpen

        ZStack(alignment: .trailing) {
            // Unified Single Glass Dock (Zero overlap)
            if isDockOpen {
                RightSideUnifiedDockView(
                    isOpen: $isRightAppsDockOpen,
                    initialTab: .apps,
                    edge: .trailing
                )
                .frame(height: usableHeight)
                // RightEdgeDockTabsView's resting width (8pt leading + 28pt icon + 6pt trailing).
                // Without this the panel and the icon strip share the same trailing edge and overlap.
                .padding(.trailing, 42)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
            }

            // Keep the trigger dock visible as the anchor for the sliding panel.
            RightEdgeDockTabsView(
                isRightChatDockOpen: $isRightChatDockOpen,
                isRightAppsDockOpen: $isRightAppsDockOpen,
                coexistMode: rightDocksCoexistMode
            )
            .frame(maxHeight: .infinity, alignment: .trailing)
            .zIndex(20)
            .transition(.opacity)
        }
        .frame(width: screenSize.width, height: screenSize.height, alignment: .trailing)
    }

    @ViewBuilder
    private func arcadeScoreHud(screenSize: CGSize, topClearance: CGFloat, sideMargin: CGFloat) -> some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "gamecontroller.fill")
                    .foregroundColor(.yellow)
                Text("SCORE: \(arcadeScore)")
                    .font(.system(size: 13, weight: .bold).monospacedDigit())
                    .foregroundColor(.white)

                Button(action: { launchPinball(screenSize: screenSize) }) {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.circle.fill")
                        Text(LocalizedStrings.translateText("Launch Ball", lang: appLanguage))
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.yellow))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.65))
                    .overlay(Capsule().stroke(Color.yellow.opacity(0.4), lineWidth: 1))
            )
            .padding(.top, topClearance - 8)
            .padding(.leading, sideMargin)

            Spacer()
        }
    }

    @ViewBuilder
    private func editingDoneButton(topClearance: CGFloat, sideMargin: CGFloat) -> some View {
        HStack {
            Spacer()
            Button(action: {
                HapticFeedback.selection()
                withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                    isEditing = false
                }
            }) {
                Text(LocalizedStrings.translateText("Done", lang: appLanguage))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.blue.opacity(0.85))
                            .shadow(color: Color.black.opacity(0.35), radius: 6, x: 0, y: 3)
                    )
            }
            .buttonStyle(.plain)
            .padding(.top, topClearance - 8)
            .padding(.trailing, sideMargin)
            .transition(.scale.combined(with: .opacity))
        }
    }

    // MARK: - Applications Elevation Handle (Swipe/Click Up to Show, Down to Retrieve)
    @ViewBuilder
    private func appDrawerStageHandle(screenSize: CGSize) -> some View {
        if appDisplayStage == .hidden {
            Button(action: {
                HapticFeedback.selection()
                withAnimation(.spring(response: 0.36, dampingFraction: 0.70)) {
                    appDisplayStage = .fullScreen
                    isRightChatDockOpen = false
                    isRightAppsDockOpen = false
                    isTopSearchBarPoppedDown = false
                }
            }) {
                HStack(spacing: 6) {
                    Text("Show Applications (\(apps.count))")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.70))
                        .shadow(color: Color.black.opacity(0.40), radius: 8, x: 0, y: 4)
                )
                .overlay(Capsule().stroke(Color.white.opacity(0.28), lineWidth: 0.8))
            }
            .buttonStyle(.plain)
            .help("Show Applications Grid (Click or Swipe Up)")
        } else {
            Button(action: {
                HapticFeedback.tick()
                withAnimation(.spring(response: 0.36, dampingFraction: 0.70)) {
                    appDisplayStage = .hidden
                }
            }) {
                HStack(spacing: 6) {
                    Text("Applications")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.70))
                        .shadow(color: Color.black.opacity(0.40), radius: 8, x: 0, y: 4)
                )
                .overlay(Capsule().stroke(Color.orange.opacity(0.45), lineWidth: 0.8))
            }
            .buttonStyle(.plain)
            .help("Hide Applications (Click or Swipe Down)")
        }
    }

    // MARK: - 📱 iPhone Home Indicator & Fluid Gesture Bar
    @ViewBuilder
    private func iPhoneHomeIndicatorBar(screenSize: CGSize, bottomClearance: CGFloat) -> some View {
        let isAppsUp = (appDisplayStage == .fullScreen)
        VStack(spacing: 0) {
            Spacer()

            Button(action: {
                HapticFeedback.selection()
                withAnimation(.spring(response: 0.38, dampingFraction: 0.80)) {
                    if isAppsUp {
                        // Retrieve apps back down to bottom: Retrieve Applications ⬇️ / Retrieve to Bottom
                        appDisplayStage = .hidden
                    } else {
                        // Bring apps up from bottom
                        currentPage = 1
                        appDisplayStage = .fullScreen
                        isTopSearchBarPoppedDown = false
                        isRightChatDockOpen = false
                        isRightAppsDockOpen = false
                    }
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: isAppsUp ? "chevron.compact.down" : "chevron.compact.up")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white.opacity(0.45))

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.70), Color.white.opacity(0.45)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: 140, height: 5)

                    Image(systemName: isAppsUp ? "chevron.compact.down" : "chevron.compact.up")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white.opacity(0.45))
                }
                .shadow(color: Color.black.opacity(0.50), radius: 5, y: 2)
                .padding(.horizontal, 28)
                .padding(.vertical, 6)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .help(isAppsUp ? "Retrieve to Bottom (Hide Applications)" : "Swipe or Click Up to Show Applications")
            .padding(.bottom, max(8, bottomClearance - 48))
        }
        .frame(width: screenSize.width, height: screenSize.height, alignment: .bottom)
    }

    @ViewBuilder
    private func topRetractorDropZone(screenSize: CGSize) -> some View {
        VStack {
            Color.clear
                .frame(height: 28)
                .contentShape(Rectangle())
                .onTapGesture {
                    HapticFeedback.tick()
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                        isTopSearchBarPoppedDown.toggle()
                    }
                }
                .gesture(
                    DragGesture(minimumDistance: 8)
                        .onEnded { value in
                            if value.translation.height > 10 {
                                HapticFeedback.tick()
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                                    isTopSearchBarPoppedDown = true
                                }
                            } else if value.translation.height < -10 {
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                                    isTopSearchBarPoppedDown = false
                                }
                            }
                        }
                )
            Spacer()
        }
        .frame(width: screenSize.width, height: screenSize.height, alignment: .top)
    }

    @ViewBuilder
    private func pageIndicatorView(screenSize: CGSize) -> some View {
        VStack {
            Spacer()
            HStack(spacing: 8) {
                Button(action: {
                    HapticFeedback.selection()
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        currentPage = 0
                    }
                    NotificationCenter.default.post(name: NSNotification.Name("NexusDesktopPageChanged"), object: 0)
                }) {
                    Circle()
                        .fill(currentPage == 0 ? Color.white.opacity(0.95) : Color.white.opacity(0.30))
                        .frame(width: 7, height: 7)
                        .scaleEffect(currentPage == 0 ? 1.25 : 1.0)
                }
                .buttonStyle(.plain)
                .help("Switch to Clean Desktop (Page 1)")

                Button(action: {
                    HapticFeedback.selection()
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        currentPage = 1
                    }
                    NotificationCenter.default.post(name: NSNotification.Name("NexusDesktopPageChanged"), object: 1)
                }) {
                    Circle()
                        .fill(currentPage == 1 ? Color.white.opacity(0.95) : Color.white.opacity(0.30))
                        .frame(width: 7, height: 7)
                        .scaleEffect(currentPage == 1 ? 1.25 : 1.0)
                }
                .buttonStyle(.plain)
                .help("Switch to Applications Canvas (Page 2)")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.40))
                    .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 0.5))
            )
            .padding(.bottom, 12)
            .shadow(color: Color.black.opacity(0.35), radius: 4, x: 0, y: 2)
            // Stays out of the way until you reach for it: the pill is invisible but still
            // hit-testable, so moving the cursor over its spot fades it in.
            .opacity(isPageIndicatorHovered ? 1.0 : 0.0)
            .contentShape(Rectangle().inset(by: -10))
            .onHover { hovering in
                withAnimation(.easeOut(duration: 0.18)) {
                    isPageIndicatorHovered = hovering
                }
            }
        }
        .frame(width: screenSize.width, height: screenSize.height)
    }

    @ViewBuilder
    private func genieBackdropView(screenSize: CGSize) -> some View {
        Color.clear
    }

    private func dropPetTreat(at location: CGPoint) {
        HapticFeedback.selection()
        let treat = PetTreat(position: location)
        petTreats.append(treat)

        // Drop a cluster of food flakes for realistic fish feeding
        for _ in 1...2 {
            let offset = CGPoint(
                x: location.x + CGFloat.random(in: -18...18),
                y: location.y + CGFloat.random(in: -18...18)
            )
            var crumb = PetTreat(position: offset)
            crumb.scale = 0.75
            if petTreats.count >= 32 {
                petTreats.removeFirst(petTreats.count - 31)
            }
            petTreats.append(crumb)
        }

        // Trigger a water ripple ring at food drop location
        let wave = Shockwave(
            id: UUID(),
            center: location,
            size: 10,
            opacity: 0.8,
            lineWidth: 2.0,
            color: Color.cyan
        )
        if shockwaves.count >= 24 {
            shockwaves.removeFirst(shockwaves.count - 23)
        }
        shockwaves.append(wave)
        withAnimation(.easeOut(duration: 0.6)) {
            if let idx = shockwaves.firstIndex(where: { $0.id == wave.id }) {
                shockwaves[idx].size = 65
                shockwaves[idx].opacity = 0.0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
            shockwaves.removeAll(where: { $0.id == wave.id })
        }

        // Expire treat after 5 seconds with fade out
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            withAnimation(.easeOut(duration: 0.8)) {
                if let idx = petTreats.firstIndex(where: { $0.id == treat.id }) {
                    petTreats[idx].opacity = 0.0
                    petTreats[idx].scale = 0.2
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
                petTreats.removeAll(where: { $0.id == treat.id })
            }
        }
    }

    private func launchPinball(screenSize: CGSize) {
        HapticFeedback.heavy()
        let startX = CGFloat.random(in: screenSize.width * 0.3...screenSize.width * 0.7)
        let vx = CGFloat.random(in: -7...7)
        let vy = CGFloat.random(in: 6...12)
        let ball = PinballBall(position: CGPoint(x: startX, y: 80), velocity: CGPoint(x: vx, y: vy))
        if pinballs.count >= 20 {
            pinballs.removeFirst(pinballs.count - 19)
        }
        pinballs.append(ball)
        arcadeScore += 100
    }

    private func updateCursorTrail(_ point: CGPoint) {
        guard cursorFxType != "None" else { return }
        let now = Date().timeIntervalSinceReferenceDate
        cursorTrail.append(CursorTrailPoint(point: point, timestamp: now))
        cursorTrail.removeAll(where: { now - $0.timestamp > 0.35 })
        if cursorTrail.count > 48 {
            cursorTrail.removeFirst(cursorTrail.count - 48)
        }
    }

    private func triggerLaunchShockwave(at center: CGPoint) {
        let wave = Shockwave(
            id: UUID(),
            center: center,
            size: 20,
            opacity: 0.9,
            lineWidth: 4,
            color: (appIconTheme == "Inferno") ? Color.orange : ((appIconTheme == "Cyberpunk") ? Color.cyan : Color.white)
        )
        if shockwaves.count >= 24 {
            shockwaves.removeFirst(shockwaves.count - 23)
        }
        shockwaves.append(wave)

        withAnimation(.easeOut(duration: 0.50)) {
            if let idx = shockwaves.firstIndex(where: { $0.id == wave.id }) {
                shockwaves[idx].size = 240
                shockwaves[idx].opacity = 0.0
                shockwaves[idx].lineWidth = 0.8
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.55) {
            shockwaves.removeAll(where: { $0.id == wave.id })
        }
    }

    private func transitionOffset(screenSize: CGSize) -> (x: CGFloat, y: CGFloat, scale: CGFloat) {
        if currentPage == 1 {
            return (x: pullDragOffsetX, y: pullDragOffsetY, scale: 1.0)
        }
        switch gridTransitionDirection {
        case "Slide from Right (iPhone Mode 📱)":
            return (x: screenSize.width, y: 0, scale: 1.0)
        case "Slide from Left (Sidebar ⬅️)":
            return (x: -screenSize.width, y: 0, scale: 1.0)
        case "Drop Down from Top (Menu Bar ⬇️)":
            return (x: 0, y: -screenSize.height, scale: 1.0)
        case "Spatial Zoom from Center (Holographic ✨)":
            return (x: 0, y: 0, scale: 0.85)
        default: // "Pull Up from Bottom"
            return (x: 0, y: screenSize.height, scale: 1.0)
        }
    }

    private func handleScrollEvent(_ event: NSEvent) {
        let currentScreen = screen ?? NSScreen.main ?? (NSScreen.screens.first ?? NSScreen())
        let mouseLoc = NSEvent.mouseLocation

        // 1. Prioritize the screen currently under the user's cursor
        if NSScreen.screens.count > 1 {
            if !NSPointInRect(mouseLoc, currentScreen.frame) {
                return
            }
        }

        let now = ProcessInfo.processInfo.systemUptime

        // Anti-jitter cooldown between page/station flips
        guard now - lastPageSwitchTime > 0.18 else { return }

        // Ignore inertial momentum coasting after fingers lift from trackpad
        guard event.momentumPhase.isEmpty else {
            scrollAccumulator = 0
            return
        }

        // 2. Strict Active App Isolation:
        let frontApp = NSWorkspace.shared.frontmostApplication
        let frontBundle = frontApp?.bundleIdentifier
        let isDesktopOrFinder = (currentPage == 1 || frontBundle == "com.apple.finder" || frontBundle == Bundle.main.bundleIdentifier || frontApp == nil || DesktopWindowManager.shared.isOverDesktopOrEmptySpace())
        guard isDesktopOrFinder else { return }

        // Reset accumulator on new gesture begin
        if event.phase == .began {
            scrollAccumulator = 0
        }

        // 3. Process vertical delta with respect to device inversion (Natural Scrolling)
        let rawDeltaY = event.scrollingDeltaY
        let multiplier: CGFloat = event.hasPreciseScrollingDeltas ? 1.0 : 6.0
        let vDelta = rawDeltaY * multiplier

        if now - lastScrollTime > 0.35 || (scrollAccumulator > 0 && vDelta < 0) || (scrollAccumulator < 0 && vDelta > 0) {
            scrollAccumulator = 0
        }
        lastScrollTime = now
        scrollAccumulator += vDelta

        let flickThreshold: CGFloat = 6.0
        let longPullThreshold: CGFloat = 16.0

        let isNatural = event.isDirectionInvertedFromDevice
        // Physical UP: Fingers pushed upward on trackpad toward screen (or traditional wheel rolled up)
        var isSwipeUp: Bool = isNatural
            ? (vDelta <= -flickThreshold || scrollAccumulator <= -longPullThreshold)
            : (vDelta >= flickThreshold || scrollAccumulator >= longPullThreshold)

        // Physical DOWN: Fingers pulled downward on trackpad toward user (or traditional wheel rolled down)
        var isSwipeDown: Bool = isNatural
            ? (vDelta >= flickThreshold || scrollAccumulator >= longPullThreshold)
            : (vDelta <= -flickThreshold || scrollAccumulator <= -longPullThreshold)

        // When slideDownShowsTopStation is active (default: true), sliding wheel DOWN reveals the top screen (Zenith).
        // The reverseStationScrollWheelDirection toggle flips this back or forth.
        let slideDownShowsTop = (UserDefaults.standard.object(forKey: PrefKey.wheelSlideDownShowsTopStation) as? Bool ?? true) != UserDefaults.standard.bool(forKey: PrefKey.reverseStationScrollWheelDirection)
        if slideDownShowsTop {
            let temp = isSwipeUp
            isSwipeUp = isSwipeDown
            isSwipeDown = temp
        }

        // Determine current station
        let currentStation = DesktopWindowManager.shared.currentStation

        if isSwipeUp {
            // Two-finger physical swipe UP:
            // If on Applications (Bottom) -> slide UP to Desktop (Center)
            // If on Desktop (Center) -> slide UP to Chat Studio (Top)
            if currentStation == .applications || appDisplayStage == .fullScreen {
                scrollAccumulator = 0
                lastPageSwitchTime = now
                HapticFeedback.selection()
                withAnimation(.spring(response: 0.40, dampingFraction: 0.82)) {
                    DesktopWindowManager.shared.switchToStation(.desktop)
                }
            } else if currentStation == .desktop || (currentPage == 0 && !isTopSearchBarPoppedDown) {
                scrollAccumulator = 0
                lastPageSwitchTime = now
                HapticFeedback.selection()
                withAnimation(.spring(response: 0.40, dampingFraction: 0.82)) {
                    DesktopWindowManager.shared.switchToStation(.chat)
                }
            }
        } else if isSwipeDown {
            // Two-finger physical swipe DOWN:
            // If on Chat Studio (Top) -> slide DOWN to Desktop (Center)
            // If on Desktop (Center) -> slide DOWN to Applications (Bottom)
            if currentStation == .chat || isTopSearchBarPoppedDown {
                scrollAccumulator = 0
                lastPageSwitchTime = now
                HapticFeedback.selection()
                withAnimation(.spring(response: 0.40, dampingFraction: 0.82)) {
                    DesktopWindowManager.shared.switchToStation(.desktop)
                }
            } else if currentStation == .desktop || (currentPage == 0 && appDisplayStage == .hidden) {
                scrollAccumulator = 0
                lastPageSwitchTime = now
                HapticFeedback.selection()
                withAnimation(.spring(response: 0.40, dampingFraction: 0.82)) {
                    DesktopWindowManager.shared.switchToStation(.applications)
                }
            }
        }
    }
}

// MARK: - Shockwave Model

struct Shockwave: Identifiable {
    let id: UUID
    let center: CGPoint
    var size: CGFloat
    var opacity: Double
    var lineWidth: CGFloat
    var color: Color
}

// MARK: - Cursor Trail Point Model

struct CursorTrailPoint: Identifiable {
    let id = UUID()
    let point: CGPoint
    let timestamp: TimeInterval
}

// MARK: - Cyber Vector Grid Canvas

struct CyberVectorGridCanvas: View {
    @AppStorage(PrefKey.appLanguage) var appLanguage: String = "English (US)"
let screenSize: CGSize
    var body: some View {
        Canvas { ctx, size in
            let step: CGFloat = 44.0
            var path = Path()
            for x in stride(from: 0, to: size.width, by: step) {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
            }
            for y in stride(from: 0, to: size.height, by: step) {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
            }
            ctx.stroke(path, with: .color(Color.cyan.opacity(0.20)), lineWidth: 0.8)
        }
    }
}

struct ClearWaterCausticsCanvas: View {
    @AppStorage(PrefKey.appLanguage) var appLanguage: String = "English (US)"
    let screenSize: CGSize
    var isPaused: Bool = false

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: isPaused)) { timeline in
            Canvas { ctx, size in
                guard !isPaused else { return }
                let time = timeline.date.timeIntervalSinceReferenceDate
                let w = size.width
                let h = size.height

                for i in 0..<7 {
                    let fi = Double(i)
                    let offset = sin(time * 0.35 + fi * 0.85) * 35.0
                    let yPos = (h / 7.0) * CGFloat(i) + CGFloat(offset)

                    var path = Path()
                    path.move(to: CGPoint(x: 0, y: yPos))
                    for x in stride(from: 0.0, through: Double(w), by: 35.0) {
                        let yWave = yPos + CGFloat(sin((x * 0.007) + time * 0.75 + fi) * 16.0)
                        path.addLine(to: CGPoint(x: x, y: yWave))
                    }

                    ctx.stroke(
                        path,
                        with: .color(Color(red: 0.60, green: 0.88, blue: 1.0, opacity: 0.16)),
                        lineWidth: 2.2
                    )
                }
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Unified High-Performance Metal Canvas (Single 60/120Hz Loop)

struct UnifiedAmbientMetalCanvas: View {
    @AppStorage(PrefKey.appLanguage) var appLanguage: String = "English (US)"
let wallpaperEnabled: Bool
    let wallpaperFxType: String
    let wallpaperIntensity: CGFloat
    let ambientEntity: String
    let entityTheme: String
    let cursorFxType: String
    let mouseLocation: CGPoint?
    let cursorTrail: [CursorTrailPoint]
    let dragonFollow: Bool
    let petTreats: [PetTreat]
    let pinballEnabled: Bool
    let pinballs: [PinballBall]
    let screenSize: CGSize

    /// True when at least one layer would actually draw; otherwise the 60 Hz loop is paused.
    private var hasActiveLayer: Bool {
        (wallpaperEnabled && wallpaperFxType != "None")
            || ambientEntity != "None"
            || cursorFxType != "None"
            || (pinballEnabled && !pinballs.isEmpty)
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: !hasActiveLayer)) { timeline in
            Canvas { context, size in
                let time = timeline.date.timeIntervalSinceReferenceDate
                let W = size.width
                let H = size.height

                // 1. Atmospheric Wallpaper FX Layer
                if wallpaperEnabled, wallpaperFxType != "None" {
                    drawWallpaperFX(context: context, W: W, H: H, time: time, type: wallpaperFxType, alpha: wallpaperIntensity)
                }

                // 2. Living Pets & Ambient Entities Layer (with Treat Attraction)
                if ambientEntity != "None" {
                    let targetPoint = petTreats.first(where: { !$0.isEaten })?.position ?? (dragonFollow ? mouseLocation : nil)
                    drawAmbientEntity(context: context, W: W, H: H, time: time, type: ambientEntity, mouse: targetPoint)
                }

                // 3. Interactive Cursor FX Trails Layer
                if cursorFxType != "None", let mouse = mouseLocation {
                    drawCursorFX(context: context, W: W, H: H, time: time, type: cursorFxType, mouse: mouse, trail: cursorTrail)
                }

                // 4. Pinball Arcade Simulation Layer (Strictly only when enabled)
                if pinballEnabled && !pinballs.isEmpty {
                    drawPinballs(context: context, W: W, H: H, time: time)
                }
            }
        }
        .frame(width: screenSize.width, height: screenSize.height)
    }

    private func drawPinballs(context: GraphicsContext, W: CGFloat, H: CGFloat, time: Double) {
        guard W > 0 && H > 0 else { return }
        for (i, ball) in pinballs.enumerated() {
            let t = time * 8.0 + Double(i * 3)
            let px = (ball.position.x + CGFloat(sin(t) * 120.0)).truncatingRemainder(dividingBy: W)
            let py = (ball.position.y + CGFloat(cos(t * 1.2) * 160.0)).truncatingRemainder(dividingBy: H)

            let pCircle = Path(ellipseIn: CGRect(x: abs(px) - 8, y: abs(py) - 8, width: 16, height: 16))
            context.fill(pCircle, with: .color(Color.yellow.opacity(0.9)))

            let glow = Path(ellipseIn: CGRect(x: abs(px) - 16, y: abs(py) - 16, width: 32, height: 32))
            context.fill(glow, with: .color(Color.orange.opacity(0.4)))
        }
    }

    // --- ATMOSPHERIC WALLPAPER SHADERS ---
    private func drawWallpaperFX(context: GraphicsContext, W: CGFloat, H: CGFloat, time: Double, type: String, alpha: CGFloat) {
        AtmosphericShaderEngine.draw(context: context, W: W, H: H, time: time, type: type, alpha: alpha)
    }

    // --- LIVING PETS, SPORTS & INTERACTIVE ENTITIES ---
    private func drawAmbientEntity(context: GraphicsContext, W: CGFloat, H: CGFloat, time: Double, type: String, mouse: CGPoint?) {
        switch type {
        // 🐬 4K HYPER-REALISTIC NATURE & MARINE LIFE
        case "Pacific Ocean Dolphins 🐬", "Pacific Ocean Dolphins":
            drawPacificDolphins(context: context, W: W, H: H, time: time, mouse: mouse)

        case "Coral Reef Aquaria 🐠", "Coral Reef Aquaria":
            drawCoralReefAquaria(context: context, W: W, H: H, time: time, mouse: mouse)

        case "Deep Sea Mantas 🌊", "Deep Sea Mantas":
            drawDeepSeaMantas(context: context, W: W, H: H, time: time, mouse: mouse)

        case "Gliding Sea Turtle 🐢", "Gliding Sea Turtle":
            drawGlidingSeaTurtle(context: context, W: W, H: H, time: time, mouse: mouse)

        // 🐾 ILLUSTRATED LIVING PETS & BIRDS
        case "Red Panda Climber 🐾", "Red Panda Climber":
            drawRedPandaClimber(context: context, W: W, H: H, time: time, mouse: mouse)

        case "Origami Paper Cranes 🕊️", "Origami Paper Cranes":
            drawOrigamiPaperCranes(context: context, W: W, H: H, time: time, mouse: mouse)

        // 🎏 NATURE & COPYRIGHT-FREE AQUATIC
        case "Japanese Koi Pond 🎏", "Japanese Koi Pond", "Neon Koi School":
            drawJapaneseKoiPond(context: context, W: W, H: H, time: time, mouse: mouse)

        case "Bioluminescent Jellyfish 🪼":
            for j in 0..<4 {
                let t = time * 0.38 + Double(j) * 1.8
                var jx = (W * 0.15) + (W * 0.70) * (0.5 + 0.5 * sin(t * 0.5 + Double(j)))
                var jy = (H * 0.20) + (H * 0.60) * (0.5 + 0.5 * cos(t * 0.7 + Double(j)))
                if let mouse = mouse {
                    let dist = hypot(mouse.x - jx, mouse.y - jy)
                    if dist < 320 {
                        jx += (mouse.x - jx) * 0.25 * (1.0 - dist / 320)
                        jy += (mouse.y - jy) * 0.25 * (1.0 - dist / 320)
                    }
                }
                let pulse = 0.85 + 0.30 * sin(time * 3.5 + Double(j))
                let bellW: CGFloat = 36.0 * pulse
                let bellH: CGFloat = 26.0 * pulse

                var bell = Path()
                bell.move(to: CGPoint(x: jx - bellW / 2, y: jy))
                bell.addQuadCurve(to: CGPoint(x: jx + bellW / 2, y: jy), control: CGPoint(x: jx, y: jy - bellH))
                bell.addQuadCurve(to: CGPoint(x: jx - bellW / 2, y: jy), control: CGPoint(x: jx, y: jy + 6))
                let jellyCol = (j % 2 == 0) ? Color.cyan : Color.pink
                context.fill(bell, with: .color(jellyCol.opacity(0.40)))
                context.stroke(bell, with: .color(Color.white.opacity(0.80)), lineWidth: 1.2)

                for tent in 0..<6 {
                    let tx = jx - bellW * 0.4 + CGFloat(tent) * (bellW * 0.8 / 5.0)
                    var tPath = Path()
                    tPath.move(to: CGPoint(x: tx, y: jy + 2))
                    for step in 1...5 {
                        let ty = jy + CGFloat(step * 10)
                        let sway = sin(time * 5.0 + Double(j) + Double(step) * 0.8 + Double(tent)) * 6.0
                        tPath.addLine(to: CGPoint(x: tx + CGFloat(sway), y: ty))
                    }
                    context.stroke(tPath, with: .color(jellyCol.opacity(0.65)), lineWidth: 1.0)
                }
            }

        case "Monarch Butterflies 🦋":
            for b in 0..<5 {
                let t = time * 0.65 + Double(b) * 1.5
                var bx = (W * 0.15) + (W * 0.70) * (0.5 + 0.5 * sin(t * 0.8 + cos(Double(b))))
                var by = (H * 0.20) + (H * 0.60) * (0.5 + 0.5 * cos(t * 1.1 + sin(Double(b))))
                if let mouse = mouse {
                    let dist = hypot(mouse.x - bx, mouse.y - by)
                    if dist < 350 {
                        bx += (mouse.x - bx) * 0.35 * (1.0 - dist / 350)
                        by += (mouse.y - by) * 0.35 * (1.0 - dist / 350)
                    }
                }
                let flap = abs(sin(time * 12.0 + Double(b)))
                let wingW: CGFloat = 16.0 * flap
                let wingH: CGFloat = 18.0

                for side in [-1.0, 1.0] {
                    var wing = Path()
                    wing.move(to: CGPoint(x: bx, y: by))
                    wing.addQuadCurve(to: CGPoint(x: bx + CGFloat(side) * wingW, y: by - wingH * 0.6), control: CGPoint(x: bx + CGFloat(side) * wingW * 0.6, y: by - wingH))
                    wing.addQuadCurve(to: CGPoint(x: bx, y: by + 6), control: CGPoint(x: bx + CGFloat(side) * wingW * 0.8, y: by + 10))
                    wing.closeSubpath()
                    context.fill(wing, with: .color(Color(red: 1.0, green: 0.45, blue: 0.05, opacity: 0.85)))
                    context.stroke(wing, with: .color(Color.black.opacity(0.8)), lineWidth: 1.0)
                }
                context.fill(Path(ellipseIn: CGRect(x: bx - 1.5, y: by - 6, width: 3, height: 12)), with: .color(Color.black))
            }

        case "Golden Fireflies 🏮":
            for f in 0..<16 {
                let seed = Double(f) * 13.37
                let fx = (W * 0.1) + (W * 0.8) * CGFloat(sin(time * 0.3 + seed) * 0.5 + 0.5)
                let fy = (H * 0.15) + (H * 0.7) * CGFloat(cos(time * 0.25 + seed * 1.4) * 0.5 + 0.5)
                let blink = abs(sin(time * 2.5 + seed * 3.0))
                let glow = Path(ellipseIn: CGRect(x: fx - 10, y: fy - 10, width: 20, height: 20))
                context.fill(glow, with: .color(Color(red: 1.0, green: 0.85, blue: 0.2, opacity: blink * 0.45)))
                let core = Path(ellipseIn: CGRect(x: fx - 2, y: fy - 2, width: 4, height: 4))
                context.fill(core, with: .color(Color.white.opacity(blink * 0.95)))
            }

        case "Autumn Leaves 🍁":
            for l in 0..<14 {
                let seed = Double(l) * 11.11
                let speed = 40.0 + Double(l % 5) * 12.0
                let lx = (W * CGFloat(sin(seed) * 0.5 + 0.5)) + CGFloat(sin(time * 0.8 + seed) * 45.0)
                let ly = CGFloat((time * speed + seed * 70.0).truncatingRemainder(dividingBy: Double(H + 60))) - 30

                var leaf = Path()
                leaf.move(to: CGPoint(x: lx, y: ly - 10))
                leaf.addQuadCurve(to: CGPoint(x: lx + 10, y: ly), control: CGPoint(x: lx + 6, y: ly - 6))
                leaf.addQuadCurve(to: CGPoint(x: lx, y: ly + 10), control: CGPoint(x: lx + 6, y: ly + 6))
                leaf.addQuadCurve(to: CGPoint(x: lx - 10, y: ly), control: CGPoint(x: lx - 6, y: ly + 6))
                leaf.addQuadCurve(to: CGPoint(x: lx, y: ly - 10), control: CGPoint(x: lx - 6, y: ly - 6))
                let leafCol = (l % 3 == 0) ? Color.red : ((l % 3 == 1) ? Color.orange : Color(red: 0.9, green: 0.7, blue: 0.1))
                context.fill(leaf, with: .color(leafCol.opacity(0.80)))
            }

        // ⚽ SPORTS & ACTION GENRES
        case "Champions Soccer ⚽":
            let t = time * 1.8
            var sx = (W * 0.15) + (W * 0.70) * (0.5 + 0.5 * sin(t * 0.6))
            var sy = (H * 0.20) + (H * 0.60) * (0.5 + 0.5 * abs(cos(t * 1.2)))
            if let mouse = mouse {
                let dx = mouse.x - sx, dy = mouse.y - sy
                let dist = hypot(dx, dy)
                if dist < 300 {
                    sx += dx * 0.45 * (1.0 - dist / 300)
                    sy += dy * 0.45 * (1.0 - dist / 300)
                }
            }
            let ballR: CGFloat = 16.0
            let ball = Path(ellipseIn: CGRect(x: sx - ballR, y: sy - ballR, width: ballR * 2, height: ballR * 2))
            context.fill(ball, with: .color(Color.white))
            context.stroke(ball, with: .color(Color.black), lineWidth: 1.5)
            let penta = Path(ellipseIn: CGRect(x: sx - 5, y: sy - 5, width: 10, height: 10))
            context.fill(penta, with: .color(Color.black))

        case "Hoops Basketball 🏀":
            let t = time * 2.2
            var bx = (W * 0.20) + (W * 0.60) * (0.5 + 0.5 * cos(t * 0.5))
            var by = (H * 0.15) + (H * 0.65) * (0.5 + 0.5 * abs(sin(t * 1.4)))
            if let mouse = mouse {
                let dx = mouse.x - bx, dy = mouse.y - by
                let dist = hypot(dx, dy)
                if dist < 320 {
                    bx += dx * 0.40 * (1.0 - dist / 320)
                    by += dy * 0.40 * (1.0 - dist / 320)
                }
            }
            let bR: CGFloat = 17.0
            let bBall = Path(ellipseIn: CGRect(x: bx - bR, y: by - bR, width: bR * 2, height: bR * 2))
            context.fill(bBall, with: .color(Color(red: 0.96, green: 0.45, blue: 0.10)))
            context.stroke(bBall, with: .color(Color.black), lineWidth: 1.6)
            var bLine = Path()
            bLine.move(to: CGPoint(x: bx - bR, y: by))
            bLine.addLine(to: CGPoint(x: bx + bR, y: by))
            bLine.move(to: CGPoint(x: bx, y: by - bR))
            bLine.addLine(to: CGPoint(x: bx, y: by + bR))
            context.stroke(bLine, with: .color(Color.black.opacity(0.85)), lineWidth: 1.2)

        case "Formula Racing 🏎️":
            let t = time * 1.2
            var rx = (W * 0.15) + (W * 0.70) * (0.5 + 0.5 * sin(t * 0.8))
            var ry = (H * 0.20) + (H * 0.60) * (0.5 + 0.5 * sin(t * 1.6))
            if let mouse = mouse {
                let dx = mouse.x - rx, dy = mouse.y - ry
                let dist = hypot(dx, dy)
                if dist < 380 {
                    rx += dx * 0.50 * (1.0 - dist / 380)
                    ry += dy * 0.50 * (1.0 - dist / 380)
                }
            }
            var car = Path()
            car.move(to: CGPoint(x: rx + 24, y: ry))
            car.addLine(to: CGPoint(x: rx - 18, y: ry - 8))
            car.addLine(to: CGPoint(x: rx - 18, y: ry + 8))
            car.closeSubpath()
            context.fill(car, with: .color(Color.red))
            context.stroke(car, with: .color(Color.white), lineWidth: 1.4)
            let flame = Path(ellipseIn: CGRect(x: rx - 28, y: ry - 4, width: 10, height: 8))
            context.fill(flame, with: .color(Color.yellow.opacity(0.9)))

        // 🐉 MYTHIC BEASTS & DRAGONS
        case "Celestial Dragon", "Celestial Dragon 🐉":
            drawDragon(context: context, W: W, H: H, time: time, mouse: mouse, colors: [Color.yellow, Color.orange, Color.cyan], glowColor: Color.yellow, hasEmbers: true)

        case "Inferno Fire Dragon", "Inferno Fire Dragon 🔥":
            drawDragon(context: context, W: W, H: H, time: time * 1.2, mouse: mouse, colors: [Color.red, Color.orange, Color.yellow], glowColor: Color.red, hasEmbers: true)

        case "Frost Wyrm (Ice Dragon)", "Frost Wyrm (Ice Dragon) ❄️":
            drawDragon(context: context, W: W, H: H, time: time * 0.9, mouse: mouse, colors: [Color.cyan, Color.blue, Color.white], glowColor: Color.cyan, hasIceShards: true)

        case "Void Shadow Dragon", "Void Shadow Dragon 🔮":
            drawDragon(context: context, W: W, H: H, time: time * 0.85, mouse: mouse, colors: [Color.purple, Color(red: 0.6, green: 0.1, blue: 0.9), Color.cyan], glowColor: Color.purple, hasVoidPulse: true)

        case "Cyber Phoenix":
            let t = time * 0.52
            var px = (W * 0.15) + (W * 0.70) * (0.5 + 0.5 * cos(t * 0.85))
            var py = (H * 0.20) + (H * 0.60) * (0.5 + 0.5 * sin(t * 1.35))
            if let mouse = mouse {
                let dx = mouse.x - px
                let dy = mouse.y - py
                let dist = hypot(dx, dy)
                if dist < 300 {
                    px += dx * 0.35 * (1.0 - dist / 300)
                    py += dy * 0.35 * (1.0 - dist / 300)
                }
            }
            let wingSpan: CGFloat = 38.0 + 18.0 * CGFloat(sin(time * 6.0))

            var wing1 = Path()
            wing1.move(to: CGPoint(x: px, y: py))
            wing1.addQuadCurve(to: CGPoint(x: px - wingSpan, y: py - 18), control: CGPoint(x: px - wingSpan * 0.5, y: py + 12))
            context.stroke(wing1, with: .color(Color.cyan.opacity(0.65)), lineWidth: 2.5)

            var wing2 = Path()
            wing2.move(to: CGPoint(x: px, y: py))
            wing2.addQuadCurve(to: CGPoint(x: px + wingSpan, y: py - 18), control: CGPoint(x: px + wingSpan * 0.5, y: py + 12))
            context.stroke(wing2, with: .color(Color.cyan.opacity(0.65)), lineWidth: 2.5)

            let core = Path(ellipseIn: CGRect(x: px - 6, y: py - 6, width: 12, height: 12))
            context.fill(core, with: .color(Color.white.opacity(0.8)))

        case "Spirit Kitsune":
            let t = time * 0.60
            var fx = (W * 0.18) + (W * 0.64) * (0.5 + 0.5 * sin(t * 0.8))
            var fy = (H * 0.25) + (H * 0.50) * (0.5 + 0.5 * cos(t * 1.1))
            if let mouse = mouse {
                let dx = mouse.x - fx
                let dy = mouse.y - fy
                let dist = hypot(dx, dy)
                if dist < 350 {
                    fx += dx * 0.45 * (1.0 - dist / 350)
                    fy += dy * 0.45 * (1.0 - dist / 350)
                }
            }

            for tail in 0..<9 {
                let angle = Double(tail) * (2.0 * .pi / 9.0) + (time * 1.5)
                let tailLen: CGFloat = 26.0 + 8.0 * CGFloat(sin(time * 3.0 + Double(tail)))
                let tx = fx + CGFloat(cos(angle)) * tailLen
                let ty = fy + CGFloat(sin(angle)) * tailLen
                var tailPath = Path()
                tailPath.move(to: CGPoint(x: fx, y: fy))
                tailPath.addQuadCurve(to: CGPoint(x: tx, y: ty), control: CGPoint(x: fx + CGFloat(cos(angle + 0.3)) * (tailLen * 0.6), y: fy + CGFloat(sin(angle + 0.3)) * (tailLen * 0.6)))
                context.stroke(tailPath, with: .color(Color.pink.opacity(0.65)), lineWidth: 2.0)
            }
            let foxBody = Path(ellipseIn: CGRect(x: fx - 8, y: fy - 8, width: 16, height: 16))
            context.fill(foxBody, with: .color(Color.white.opacity(0.95)))

        case "Cosmic Star Whale":
            let t = time * 0.25
            let wx = (W * 0.1) + (W * 0.8) * (0.5 + 0.5 * cos(t * 0.5))
            let wy = (H * 0.2) + (H * 0.6) * (0.5 + 0.5 * sin(t * 0.7))
            let length: CGFloat = 55.0

            var whale = Path()
            whale.move(to: CGPoint(x: wx - length * 0.5, y: wy))
            whale.addQuadCurve(to: CGPoint(x: wx + length * 0.5, y: wy), control: CGPoint(x: wx, y: wy - 18))
            whale.addQuadCurve(to: CGPoint(x: wx - length * 0.5, y: wy), control: CGPoint(x: wx, y: wy + 18))
            context.fill(whale, with: .linearGradient(Gradient(colors: [Color.blue.opacity(0.6), Color.cyan.opacity(0.3)]), startPoint: CGPoint(x: wx - length * 0.5, y: wy), endPoint: CGPoint(x: wx + length * 0.5, y: wy)))

            let finY = wy + CGFloat(sin(time * 3.0)) * 6.0
            var fluke = Path()
            fluke.move(to: CGPoint(x: wx - length * 0.5, y: wy))
            fluke.addLine(to: CGPoint(x: wx - length * 0.5 - 16, y: finY - 10))
            fluke.addLine(to: CGPoint(x: wx - length * 0.5 - 16, y: finY + 10))
            fluke.closeSubpath()
            context.fill(fluke, with: .color(Color.cyan.opacity(0.6)))

        case "Pixel Cyber Neko":
            let t = time * 0.7
            var nx = (W * 0.15) + (W * 0.70) * (0.5 + 0.5 * sin(t * 0.9))
            var ny = (H * 0.30) + (H * 0.40) * (0.5 + 0.5 * cos(t * 0.6))
            if let mouse = mouse {
                let dx = mouse.x - nx
                let dy = mouse.y - ny
                let dist = hypot(dx, dy)
                if dist < 320 {
                    nx += dx * 0.40 * (1.0 - dist / 320)
                    ny += dy * 0.40 * (1.0 - dist / 320)
                }
            }

            let head = Path(ellipseIn: CGRect(x: nx - 10, y: ny - 10, width: 20, height: 20))
            context.fill(head, with: .color(Color(red: 1.0, green: 0.85, blue: 0.4, opacity: 0.9)))

            var ear1 = Path()
            ear1.move(to: CGPoint(x: nx - 8, y: ny - 6))
            ear1.addLine(to: CGPoint(x: nx - 14, y: ny - 18))
            ear1.addLine(to: CGPoint(x: nx - 2, y: ny - 8))
            ear1.closeSubpath()
            context.fill(ear1, with: .color(Color.pink.opacity(0.85)))

            var ear2 = Path()
            ear2.move(to: CGPoint(x: nx + 8, y: ny - 6))
            ear2.addLine(to: CGPoint(x: nx + 14, y: ny - 18))
            ear2.addLine(to: CGPoint(x: nx + 2, y: ny - 8))
            ear2.closeSubpath()
            context.fill(ear2, with: .color(Color.pink.opacity(0.85)))

        case "Cyber Alpha Wolf 🐺":
            let t = time * 0.45
            var wx = (W * 0.15) + (W * 0.70) * (0.5 + 0.5 * cos(t * 0.8))
            var wy = (H * 0.25) + (H * 0.50) * (0.5 + 0.5 * sin(t * 1.2))
            if let mouse = mouse {
                let dx = mouse.x - wx, dy = mouse.y - wy
                let dist = hypot(dx, dy)
                if dist < 360 {
                    wx += dx * 0.45 * (1.0 - dist / 360)
                    wy += dy * 0.45 * (1.0 - dist / 360)
                }
            }
            // Wolf Head & Cyber Ears
            var wolf = Path()
            wolf.move(to: CGPoint(x: wx - 14, y: wy + 8))
            wolf.addLine(to: CGPoint(x: wx, y: wy - 18)) // Snout
            wolf.addLine(to: CGPoint(x: wx + 14, y: wy + 8))
            wolf.addLine(to: CGPoint(x: wx + 8, y: wy + 4))
            wolf.addLine(to: CGPoint(x: wx - 8, y: wy + 4))
            wolf.closeSubpath()
            context.fill(wolf, with: .color(Color.cyan.opacity(0.85)))
            context.stroke(wolf, with: .color(Color.white), lineWidth: 1.5)
            // Cyber Eyes
            let eye1 = Path(ellipseIn: CGRect(x: wx - 6, y: wy - 4, width: 3, height: 3))
            let eye2 = Path(ellipseIn: CGRect(x: wx + 3, y: wy - 4, width: 3, height: 3))
            context.fill(eye1, with: .color(Color.yellow))
            context.fill(eye2, with: .color(Color.yellow))

        case "Cherry Blossom 9-Tail Kitsune 🦊":
            let t = time * 0.38
            var fx = (W * 0.20) + (W * 0.60) * (0.5 + 0.5 * sin(t * 0.7))
            var fy = (H * 0.25) + (H * 0.50) * (0.5 + 0.5 * cos(t * 0.9))
            if let mouse = mouse {
                let dx = mouse.x - fx, dy = mouse.y - fy
                let dist = hypot(dx, dy)
                if dist < 380 {
                    fx += dx * 0.50 * (1.0 - dist / 380)
                    fy += dy * 0.50 * (1.0 - dist / 380)
                }
            }
            // 9 Flowing spiritual tails
            for tail in 0..<9 {
                let angle = Double(tail) * (2.0 * .pi / 9.0) + (time * 1.6)
                let tailLen: CGFloat = 34.0 + 10.0 * CGFloat(sin(time * 3.5 + Double(tail)))
                let tx = fx + CGFloat(cos(angle)) * tailLen
                let ty = fy + CGFloat(sin(angle)) * tailLen
                var tailPath = Path()
                tailPath.move(to: CGPoint(x: fx, y: fy))
                tailPath.addQuadCurve(to: CGPoint(x: tx, y: ty), control: CGPoint(x: fx + CGFloat(cos(angle + 0.35)) * (tailLen * 0.7), y: fy + CGFloat(sin(angle + 0.35)) * (tailLen * 0.7)))
                context.stroke(tailPath, with: .color(Color(red: 1.0, green: 0.45, blue: 0.75).opacity(0.80)), lineWidth: 2.5)
            }
            let foxBody = Path(ellipseIn: CGRect(x: fx - 10, y: fy - 10, width: 20, height: 20))
            context.fill(foxBody, with: .color(Color.white))
            context.stroke(foxBody, with: .color(Color.pink.opacity(0.8)), lineWidth: 1.5)

        case "Japanese Koi Sanctuary 🎏":
            let t = time * 0.40
            // Two graceful koi swimming in harmony
            for koiIdx in 0..<2 {
                let phase = Double(koiIdx) * .pi
                var kx = (W * 0.20) + (W * 0.60) * (0.5 + 0.5 * sin(t * 0.7 + phase))
                var ky = (H * 0.25) + (H * 0.50) * (0.5 + 0.5 * cos(t * 0.5 + phase))
                if let mouse = mouse {
                    let dx = mouse.x - kx, dy = mouse.y - ky
                    let dist = hypot(dx, dy)
                    if dist < 350 {
                        kx += dx * 0.35 * (1.0 - dist / 350)
                        ky += dy * 0.35 * (1.0 - dist / 350)
                    }
                }
                // Ripple ring around koi
                let rippleRadius = 18.0 + CGFloat((time * 20.0 + Double(koiIdx * 15)).truncatingRemainder(dividingBy: 24.0))
                var ripple = Path()
                ripple.addEllipse(in: CGRect(x: kx - rippleRadius, y: ky - rippleRadius * 0.6, width: rippleRadius * 2, height: rippleRadius * 1.2))
                context.stroke(ripple, with: .color(Color.cyan.opacity(0.25)), lineWidth: 1.0)

                // Koi Body
                var koiBody = Path()
                koiBody.addEllipse(in: CGRect(x: kx - 14, y: ky - 7, width: 28, height: 14))
                let koiColor = koiIdx == 0 ? Color(red: 1.0, green: 0.35, blue: 0.1) : Color.white
                context.fill(koiBody, with: .color(koiColor.opacity(0.88)))
                context.stroke(koiBody, with: .color(Color.white.opacity(0.9)), lineWidth: 1.2)

                // Tail Fin Wave
                let tailAngle = sin(time * 4.5 + phase) * 0.4
                var tail = Path()
                tail.move(to: CGPoint(x: kx - 14, y: ky))
                tail.addLine(to: CGPoint(x: kx - 24 + CGFloat(cos(tailAngle) * 4), y: ky - 8 + CGFloat(sin(tailAngle) * 6)))
                tail.addLine(to: CGPoint(x: kx - 24 + CGFloat(cos(tailAngle) * 4), y: ky + 8 + CGFloat(sin(tailAngle) * 6)))
                tail.closeSubpath()
                context.fill(tail, with: .color(Color.red.opacity(0.75)))

                // Pectoral Fins
                var fin = Path()
                fin.addEllipse(in: CGRect(x: kx + 2, y: ky - 10, width: 8, height: 4))
                fin.addEllipse(in: CGRect(x: kx + 2, y: ky + 6, width: 8, height: 4))
                context.fill(fin, with: .color(Color.orange.opacity(0.7)))
            }

        case "Pixel Yoshi Companion 🦖":
            let t = time * 0.90
            var yx = (W * 0.15) + (W * 0.70) * (0.5 + 0.5 * sin(t * 0.8))
            var yy = (H * 0.25) + (H * 0.50) * (0.5 + 0.5 * cos(t * 0.6))
            if let mouse = mouse {
                let dx = mouse.x - yx, dy = mouse.y - yy
                let dist = hypot(dx, dy)
                if dist < 320 {
                    yx += dx * 0.45 * (1.0 - dist / 320)
                    yy += dy * 0.45 * (1.0 - dist / 320)
                }
            }
            // Pixel Dino Body (Vibrant Green)
            var yoshi = Path()
            yoshi.addRoundedRect(in: CGRect(x: yx - 12, y: yy - 12, width: 24, height: 24), cornerSize: CGSize(width: 6, height: 6))
            context.fill(yoshi, with: .color(Color(red: 0.2, green: 0.85, blue: 0.25)))
            context.stroke(yoshi, with: .color(Color.white), lineWidth: 1.5)

            // White Belly & Cheeks
            let belly = Path(roundedRect: CGRect(x: yx - 4, y: yy - 2, width: 14, height: 12), cornerRadius: 3)
            context.fill(belly, with: .color(Color.white.opacity(0.9)))

            // Red Saddle Shell
            let shell = Path(roundedRect: CGRect(x: yx - 15, y: yy - 4, width: 6, height: 10), cornerRadius: 2)
            context.fill(shell, with: .color(Color(red: 0.95, green: 0.2, blue: 0.15)))

            // Orange Pixel Boots (Stepping animation)
            let step = sin(time * 8.0) * 4.0
            let boot1 = Path(roundedRect: CGRect(x: yx - 10, y: yy + 12 + CGFloat(step), width: 8, height: 6), cornerRadius: 2)
            let boot2 = Path(roundedRect: CGRect(x: yx + 2, y: yy + 12 - CGFloat(step), width: 8, height: 6), cornerRadius: 2)
            context.fill(boot1, with: .color(Color.orange))
            context.fill(boot2, with: .color(Color.orange))

            // Big Friendly Pixel Eye
            let eye = Path(ellipseIn: CGRect(x: yx + 2, y: yy - 10, width: 6, height: 8))
            context.fill(eye, with: .color(Color.white))
            let pupil = Path(ellipseIn: CGRect(x: yx + 4, y: yy - 8, width: 3, height: 4))
            context.fill(pupil, with: .color(Color.black))

        case "Deep Void Star Kraken 🦑":
            let t = time * 0.28
            var kx = (W * 0.15) + (W * 0.70) * (0.5 + 0.5 * cos(t * 0.6))
            var ky = (H * 0.20) + (H * 0.60) * (0.5 + 0.5 * sin(t * 0.8))
            if let mouse = mouse {
                let dx = mouse.x - kx, dy = mouse.y - ky
                let dist = hypot(dx, dy)
                if dist < 400 {
                    kx += dx * 0.35 * (1.0 - dist / 400)
                    ky += dy * 0.35 * (1.0 - dist / 400)
                }
            }
            // Kraken Head/Mantle
            var mantle = Path()
            mantle.addEllipse(in: CGRect(x: kx - 18, y: ky - 28, width: 36, height: 45))
            context.fill(mantle, with: .color(Color(red: 0.4, green: 0.1, blue: 0.7).opacity(0.75)))
            context.stroke(mantle, with: .color(Color.cyan.opacity(0.85)), lineWidth: 1.5)
            // 8 Waving Cosmic Tentacles
            for tent in 0..<8 {
                let tAngle = (Double(tent) / 8.0) * .pi + (.pi * 0.0)
                let wave = sin(time * 4.0 + Double(tent) * 0.8) * 14.0
                var tentPath = Path()
                tentPath.move(to: CGPoint(x: kx + CGFloat(cos(tAngle)) * 12.0, y: ky + 12))
                tentPath.addQuadCurve(
                    to: CGPoint(x: kx + CGFloat(cos(tAngle)) * 26.0 + CGFloat(wave), y: ky + 48),
                    control: CGPoint(x: kx + CGFloat(cos(tAngle)) * 20.0, y: ky + 28)
                )
                context.stroke(tentPath, with: .color(Color.cyan.opacity(0.75)), lineWidth: 2.0)
            }

        case "8-Bit Arcade Ghost 👻":
            let t = time * 0.85
            var gx = (W * 0.15) + (W * 0.70) * (0.5 + 0.5 * sin(t * 0.9))
            var gy = (H * 0.25) + (H * 0.50) * (0.5 + 0.5 * cos(t * 0.7))
            if let mouse = mouse {
                let dx = mouse.x - gx, dy = mouse.y - gy
                let dist = hypot(dx, dy)
                if dist < 320 {
                    gx += dx * 0.40 * (1.0 - dist / 320)
                    gy += dy * 0.40 * (1.0 - dist / 320)
                }
            }
            // Pixelated Ghost Body
            var ghost = Path()
            ghost.move(to: CGPoint(x: gx - 14, y: gy + 14))
            ghost.addLine(to: CGPoint(x: gx - 14, y: gy - 8))
            ghost.addQuadCurve(to: CGPoint(x: gx + 14, y: gy - 8), control: CGPoint(x: gx, y: gy - 20))
            ghost.addLine(to: CGPoint(x: gx + 14, y: gy + 14))
            ghost.addLine(to: CGPoint(x: gx + 7, y: gy + 8))
            ghost.addLine(to: CGPoint(x: gx, y: gy + 14))
            ghost.addLine(to: CGPoint(x: gx - 7, y: gy + 8))
            ghost.closeSubpath()
            context.fill(ghost, with: .color(Color(red: 1.0, green: 0.2, blue: 0.4)))
            context.stroke(ghost, with: .color(Color.white), lineWidth: 1.2)
            // Ghost Pixel Eyes
            let eye1 = Path(ellipseIn: CGRect(x: gx - 8, y: gy - 6, width: 4, height: 6))
            let eye2 = Path(ellipseIn: CGRect(x: gx + 4, y: gy - 6, width: 4, height: 6))
            context.fill(eye1, with: .color(Color.white))
            context.fill(eye2, with: .color(Color.white))

        case "Sakura Storm":
            for p in 0..<45 {
                let seed = Double(p) * 7.7
                let speed = 25.0 + Double(p % 8) * 5.0
                let px = (W * CGFloat(sin(seed * 1.8) * 0.5 + 0.5)) + CGFloat(sin(time * 0.5 + seed) * 40.0)
                let py = CGFloat((time * speed + seed * 80.0).truncatingRemainder(dividingBy: Double(H + 40))) - 20

                var petal = Path()
                petal.addEllipse(in: CGRect(x: px - 4, y: py - 6, width: 8, height: 12))
                context.fill(petal, with: .color(Color(red: 1.0, green: 0.65, blue: 0.85, opacity: 0.65)))
            }

        case "Plasma Storm":
            if let mouse = mouse {
                for i in 0..<4 {
                    let seed = Double(i) * 1.57 + time * 2.0
                    let startX = W * CGFloat(sin(seed) * 0.5 + 0.5)
                    let startY = CGFloat(0)
                    var bolt = Path()
                    bolt.move(to: CGPoint(x: startX, y: startY))
                    let midX = (startX + mouse.x) * 0.5 + CGFloat(sin(time * 8.0 + Double(i)) * 30.0)
                    let midY = mouse.y * 0.5
                    bolt.addQuadCurve(to: mouse, control: CGPoint(x: midX, y: midY))
                    context.stroke(bolt, with: .color(Color.cyan.opacity(0.75)), lineWidth: 1.5)
                }
            }

        case "Quantum Comets":
            for cometIdx in 0..<5 {
                let seed = Double(cometIdx) * 1.75
                let t = (time * 0.36 + seed).truncatingRemainder(dividingBy: 1.0)
                let startX = W * CGFloat((sin(seed * 3) + 1) * 0.5)
                let cx = startX + (W * 0.4) * CGFloat(t)
                let cy = H * CGFloat(t)

                var tail = Path()
                tail.move(to: CGPoint(x: cx, y: cy))
                tail.addLine(to: CGPoint(x: cx - 40, y: cy - 40))
                context.stroke(tail, with: .linearGradient(Gradient(colors: [Color.pink.opacity(0.6), Color.clear]), startPoint: CGPoint(x: cx, y: cy), endPoint: CGPoint(x: cx - 40, y: cy - 40)), lineWidth: 2)

                let head = Path(ellipseIn: CGRect(x: cx - 3, y: cy - 3, width: 6, height: 6))
                context.fill(head, with: .color(Color.white))
            }

        case "Matrix Rain":
            let colCount = 18
            let colWidth = W / CGFloat(colCount)
            for c in 0..<colCount {
                let speed = 60.0 + Double((c * 7) % 50)
                let headY = CGFloat((time * speed + Double(c * 120)).truncatingRemainder(dividingBy: Double(H + 100))) - 50
                let cx = CGFloat(c) * colWidth + colWidth * 0.5

                for g in 0..<6 {
                    let gy = headY - CGFloat(g * 14)
                    if gy > 0 && gy < H {
                        let alpha = 1.0 - (Double(g) / 6.0)
                        let rect = Path(roundedRect: CGRect(x: cx - 2, y: gy - 4, width: 4, height: 8), cornerRadius: 1)
                        context.fill(rect, with: .color(Color(red: 0.0, green: 1.0, blue: 0.3, opacity: alpha * 0.7)))
                    }
                }
            }

        case "Constellation":
            let starCount = 14
            var stars: [CGPoint] = []
            for i in 0..<starCount {
                var sx = (W * 0.1) + (W * 0.8) * CGFloat(sin(Double(i) * 2.3 + time * 0.05) * 0.5 + 0.5)
                var sy = (H * 0.15) + (H * 0.7) * CGFloat(cos(Double(i) * 1.7 + time * 0.04) * 0.5 + 0.5)
                if let mouse = mouse {
                    let dist = hypot(mouse.x - sx, mouse.y - sy)
                    if dist < 200 {
                        let factor = (1.0 - dist / 200.0) * 0.25
                        sx += (mouse.x - sx) * factor
                        sy += (mouse.y - sy) * factor
                    }
                }
                stars.append(CGPoint(x: sx, y: sy))
            }

            for i in 0..<stars.count {
                for j in (i + 1)..<stars.count {
                    let p1 = stars[i], p2 = stars[j]
                    let dist = hypot(p1.x - p2.x, p1.y - p2.y)
                    if dist < 190 {
                        var line = Path()
                        line.move(to: p1)
                        line.addLine(to: p2)
                        let alpha = Double(1.0 - dist / 190.0) * 0.28
                        context.stroke(line, with: .color(Color.purple.opacity(alpha)), lineWidth: 1)
                    }
                }
                let starCircle = Path(ellipseIn: CGRect(x: stars[i].x - 2.5, y: stars[i].y - 2.5, width: 5, height: 5))
                context.fill(starCircle, with: .color(Color.white.opacity(0.65)))
            }

        case "Cute Capybara with Citrus 🍊":
            let t = time * 0.35
            var cx = (W * 0.20) + (W * 0.60) * (0.5 + 0.5 * sin(t * 0.6))
            var cy = (H * 0.40) + (H * 0.30) * (0.5 + 0.5 * cos(t * 0.5))
            if let mouse = mouse {
                let dist = hypot(mouse.x - cx, mouse.y - cy)
                if dist < 320 {
                    cx += (mouse.x - cx) * 0.30 * (1.0 - dist / 320)
                    cy += (mouse.y - cy) * 0.30 * (1.0 - dist / 320)
                }
            }
            let capyBody = Path(roundedRect: CGRect(x: cx - 22, y: cy - 14, width: 44, height: 28), cornerRadius: 12)
            context.fill(capyBody, with: .color(Color(red: 0.58, green: 0.40, blue: 0.24)))
            let snout = Path(roundedRect: CGRect(x: cx + 12, y: cy - 8, width: 14, height: 16), cornerRadius: 6)
            context.fill(snout, with: .color(Color(red: 0.45, green: 0.30, blue: 0.18)))
            let orange = Path(ellipseIn: CGRect(x: cx - 4, y: cy - 20, width: 10, height: 10))
            context.fill(orange, with: .color(Color.orange))
            let leaf = Path(ellipseIn: CGRect(x: cx - 2, y: cy - 24, width: 4, height: 4))
            context.fill(leaf, with: .color(Color.green))

        case "Floating Astronaut Spacewalk 👨‍🚀":
            let t = time * 0.40
            var ax = (W * 0.15) + (W * 0.70) * (0.5 + 0.5 * sin(t * 0.7))
            var ay = (H * 0.25) + (H * 0.50) * (0.5 + 0.5 * cos(t * 0.9))
            if let mouse = mouse {
                let dist = hypot(mouse.x - ax, mouse.y - ay)
                if dist < 360 {
                    ax += (mouse.x - ax) * 0.35 * (1.0 - dist / 360)
                    ay += (mouse.y - ay) * 0.35 * (1.0 - dist / 360)
                }
            }
            let helmet = Path(ellipseIn: CGRect(x: ax - 12, y: ay - 14, width: 24, height: 24))
            context.fill(helmet, with: .color(Color.white))
            let visor = Path(roundedRect: CGRect(x: ax - 8, y: ay - 10, width: 16, height: 12), cornerRadius: 4)
            context.fill(visor, with: .color(Color(red: 1.0, green: 0.75, blue: 0.1)))
            let suit = Path(roundedRect: CGRect(x: ax - 14, y: ay + 8, width: 28, height: 22), cornerRadius: 8)
            context.fill(suit, with: .color(Color(white: 0.92)))

        case "Baby Octo Float 🐙":
            let t = time * 0.50
            var ox = (W * 0.18) + (W * 0.64) * (0.5 + 0.5 * sin(t * 0.8))
            var oy = (H * 0.30) + (H * 0.45) * (0.5 + 0.5 * cos(t * 1.1))
            if let mouse = mouse {
                let dist = hypot(mouse.x - ox, mouse.y - oy)
                if dist < 320 {
                    ox += (mouse.x - ox) * 0.35 * (1.0 - dist / 320)
                    oy += (mouse.y - oy) * 0.35 * (1.0 - dist / 320)
                }
            }
            let octoHead = Path(ellipseIn: CGRect(x: ox - 14, y: oy - 14, width: 28, height: 26))
            context.fill(octoHead, with: .color(Color(red: 1.0, green: 0.35, blue: 0.55)))
            for k in 0..<6 {
                let tentX = ox - 12.0 + CGFloat(k) * 5.0
                let tentY = oy + 10.0 + CGFloat(sin(time * 6.0 + Double(k))) * 4.0
                let tent = Path(ellipseIn: CGRect(x: tentX, y: tentY, width: 4.5, height: 9))
                context.fill(tent, with: .color(Color(red: 1.0, green: 0.35, blue: 0.55)))
            }

        case "Floating Pixie Fairy ✨":
            let t = time * 0.80
            var px = (W * 0.15) + (W * 0.70) * (0.5 + 0.5 * sin(t * 1.2))
            var py = (H * 0.20) + (H * 0.60) * (0.5 + 0.5 * cos(t * 0.9))
            if let mouse = mouse {
                let dist = hypot(mouse.x - px, mouse.y - py)
                if dist < 380 {
                    px += (mouse.x - px) * 0.45 * (1.0 - dist / 380)
                    py += (mouse.y - py) * 0.45 * (1.0 - dist / 380)
                }
            }
            let core = Path(ellipseIn: CGRect(x: px - 5, y: py - 5, width: 10, height: 10))
            context.fill(core, with: .color(Color.white))
            let fairyGlow = Path(ellipseIn: CGRect(x: px - 14, y: py - 14, width: 28, height: 28))
            context.fill(fairyGlow, with: .color(Color(red: 1.0, green: 0.85, blue: 0.4, opacity: 0.5)))
            let wingW = 14.0 * abs(sin(time * 16.0))
            var wing = Path()
            wing.addEllipse(in: CGRect(x: px - 12 - wingW, y: py - 8, width: wingW, height: 8))
            wing.addEllipse(in: CGRect(x: px + 12, y: py - 8, width: wingW, height: 8))
            context.fill(wing, with: .color(Color.cyan.opacity(0.65)))

        case "Cyber Sentry Drone 🛸":
            let t = time * 0.60
            var dx = (W * 0.15) + (W * 0.70) * (0.5 + 0.5 * cos(t * 0.8))
            var dy = (H * 0.25) + (H * 0.50) * (0.5 + 0.5 * sin(t * 1.0))
            if let mouse = mouse {
                let dist = hypot(mouse.x - dx, mouse.y - dy)
                if dist < 400 {
                    dx += (mouse.x - dx) * 0.40 * (1.0 - dist / 400)
                    dy += (mouse.y - dy) * 0.40 * (1.0 - dist / 400)
                }
            }
            let hull = Path(roundedRect: CGRect(x: dx - 18, y: dy - 8, width: 36, height: 16), cornerRadius: 4)
            context.fill(hull, with: .color(Color(white: 0.2)))
            context.stroke(hull, with: .color(Color.cyan), lineWidth: 1.2)
            let eye = Path(ellipseIn: CGRect(x: dx - 4, y: dy - 3, width: 8, height: 6))
            context.fill(eye, with: .color(Color.cyan))

        default:
            break
        }
    }

    // --- 🐾 ILLUSTRATED LIVING PET: RED PANDA CLIMBER ---
    private func drawRedPandaClimber(context: GraphicsContext, W: CGFloat, H: CGFloat, time: Double, mouse: CGPoint?) {
        let cycle = (time * 0.25).truncatingRemainder(dividingBy: 1.0)
        let direction: CGFloat = (Int(time * 0.25) % 2 == 0) ? 1.0 : -1.0
        var px = (direction > 0) ? (W * 0.10 + (W * 0.80) * CGFloat(cycle)) : (W * 0.90 - (W * 0.80) * CGFloat(cycle))
        var py = H * 0.24 + CGFloat(sin(time * 3.5)) * 4.0

        if let mouse = mouse {
            let dx = mouse.x - px
            let dy = mouse.y - py
            let dist = hypot(dx, dy)
            if dist < 280 {
                px += dx * 0.20 * (1.0 - dist / 280)
                py += dy * 0.20 * (1.0 - dist / 280)
            }
        }

        let bodyW: CGFloat = 32.0
        let bodyH: CGFloat = 20.0
        let russet = Color(red: 0.88, green: 0.35, blue: 0.12)
        let darkRusset = Color(red: 0.65, green: 0.20, blue: 0.08)

        // 1. Striped Bushy Tail
        let tailSway = sin(time * 4.5) * 8.0
        var tail = Path()
        let tailRoot = CGPoint(x: px - (direction * bodyW * 0.4), y: py + 2)
        tail.move(to: tailRoot)
        tail.addQuadCurve(
            to: CGPoint(x: tailRoot.x - (direction * 28.0), y: tailRoot.y - 14.0 + CGFloat(tailSway)),
            control: CGPoint(x: tailRoot.x - (direction * 16.0), y: tailRoot.y + 8.0)
        )
        context.stroke(tail, with: .color(russet), lineWidth: 8.0)
        context.stroke(tail, with: .color(Color(red: 0.98, green: 0.85, blue: 0.70)), style: StrokeStyle(lineWidth: 6.0, dash: [4, 4]))

        // 2. Body
        let bodyRect = CGRect(x: px - bodyW / 2, y: py - bodyH / 2, width: bodyW, height: bodyH)
        context.fill(Path(roundedRect: bodyRect, cornerRadius: 8), with: .color(russet))

        // 3. Four Walking Paws
        for leg in 0..<4 {
            let legX = px - bodyW * 0.35 + CGFloat(leg) * (bodyW * 0.70 / 3.0)
            let legY = py + bodyH * 0.45 + CGFloat(sin(time * 8.0 + Double(leg) * 1.5)) * 3.0
            context.fill(Path(ellipseIn: CGRect(x: legX - 2.5, y: legY - 2.5, width: 5, height: 6)), with: .color(darkRusset))
        }

        // 4. Head & White Face Markings
        let headX = px + (direction * bodyW * 0.42)
        let headY = py - 4.0
        context.fill(Path(ellipseIn: CGRect(x: headX - 8, y: headY - 8, width: 16, height: 16)), with: .color(russet))
        context.fill(Path(ellipseIn: CGRect(x: headX - (direction * 2) - 4, y: headY - 2, width: 8, height: 6)), with: .color(Color.white.opacity(0.9)))

        // Ears
        context.fill(Path(ellipseIn: CGRect(x: headX - 8, y: headY - 12, width: 6, height: 6)), with: .color(Color.white))
        context.fill(Path(ellipseIn: CGRect(x: headX + 2, y: headY - 12, width: 6, height: 6)), with: .color(Color.white))
    }

    // --- 🐢 ILLUSTRATED LIVING PET: GLIDING SEA TURTLE ---
    private func drawGlidingSeaTurtle(context: GraphicsContext, W: CGFloat, H: CGFloat, time: Double, mouse: CGPoint?) {
        let t = time * 0.32
        var tx = (W * 0.12) + (W * 0.76) * (0.5 + 0.5 * sin(t * 0.6))
        var ty = (H * 0.18) + (H * 0.64) * (0.5 + 0.5 * cos(t * 0.8))

        if let mouse = mouse {
            let dx = mouse.x - tx
            let dy = mouse.y - ty
            let dist = hypot(dx, dy)
            if dist < 320 {
                tx += dx * 0.25 * (1.0 - dist / 320)
                ty += dy * 0.25 * (1.0 - dist / 320)
            }
        }

        let heading = t * 0.6 + sin(t * 0.4) * 0.3
        let shellW: CGFloat = 38.0
        let shellH: CGFloat = 28.0
        let strokePhase = sin(time * 3.2)

        // 1. Fore-Flippers (Elliptical Swimming Stroke)
        for side in [-1.0, 1.0] {
            var flipper = Path()
            let fRoot = CGPoint(x: tx + CGFloat(cos(heading)) * 8, y: ty + CGFloat(side) * 12)
            flipper.move(to: fRoot)
            let fTip = CGPoint(
                x: fRoot.x + CGFloat(cos(heading + side * 0.8 + strokePhase * 0.4)) * 26.0,
                y: fRoot.y + CGFloat(sin(heading + side * 0.8 + strokePhase * 0.4)) * 26.0
            )
            flipper.addQuadCurve(to: fTip, control: CGPoint(x: fRoot.x + CGFloat(side) * 18, y: fRoot.y - 10))
            flipper.addQuadCurve(to: fRoot, control: CGPoint(x: fRoot.x + CGFloat(side) * 12, y: fRoot.y + 10))
            context.fill(flipper, with: .color(Color(red: 0.25, green: 0.65, blue: 0.35)))
            context.stroke(flipper, with: .color(Color(red: 0.15, green: 0.45, blue: 0.25)), lineWidth: 1.0)
        }

        // 2. Carapace (Turtle Shell with Scute Geometry)
        let shellRect = CGRect(x: tx - shellW / 2, y: ty - shellH / 2, width: shellW, height: shellH)
        let shellPath = Path(ellipseIn: shellRect)
        context.fill(shellPath, with: .color(Color(red: 0.20, green: 0.55, blue: 0.30)))
        context.stroke(shellPath, with: .color(Color(red: 0.90, green: 0.75, blue: 0.35)), lineWidth: 2.0)

        // Central Scutes
        let scuteRect = CGRect(x: tx - 8, y: ty - 6, width: 16, height: 12)
        context.stroke(Path(roundedRect: scuteRect, cornerRadius: 3), with: .color(Color(red: 0.90, green: 0.75, blue: 0.35).opacity(0.8)), lineWidth: 1.2)

        // 3. Head & Hind Flippers
        let headCenter = CGPoint(x: tx + CGFloat(cos(heading)) * (shellW * 0.55), y: ty + CGFloat(sin(heading)) * (shellW * 0.55))
        context.fill(Path(ellipseIn: CGRect(x: headCenter.x - 5, y: headCenter.y - 4, width: 10, height: 8)), with: .color(Color(red: 0.30, green: 0.70, blue: 0.40)))

        // Trailing Bubble Wake
        for b in 0..<4 {
            let bx = tx - CGFloat(cos(heading)) * (shellW * 0.6 + CGFloat(b * 12)) + CGFloat(sin(time * 6.0 + Double(b))) * 4
            let by = ty - CGFloat(sin(heading)) * (shellW * 0.6 + CGFloat(b * 12)) + CGFloat(cos(time * 6.0 + Double(b))) * 4
            context.stroke(Path(ellipseIn: CGRect(x: bx - 2, y: by - 2, width: 4, height: 4)), with: .color(Color.white.opacity(0.65)), lineWidth: 0.8)
        }
    }

    // --- 🕊️ ILLUSTRATED LIVING ENTITY: ORIGAMI PAPER CRANES ---
    private func drawOrigamiPaperCranes(context: GraphicsContext, W: CGFloat, H: CGFloat, time: Double, mouse: CGPoint?) {
        let colors: [Color] = [
            Color.white,
            Color(red: 1.0, green: 0.80, blue: 0.88),
            Color(red: 0.75, green: 0.90, blue: 1.0),
            Color(red: 1.0, green: 0.92, blue: 0.65)
        ]

        for i in 0..<4 {
            let offset = Double(i) * 0.75
            let t = time * 0.42 + offset
            var cx = (W * 0.15) + (W * 0.70) * (0.5 + 0.5 * sin(t * 0.7 + Double(i) * 0.4))
            var cy = (H * 0.18) + (H * 0.64) * (0.5 + 0.5 * cos(t * 0.9 + Double(i) * 0.5))

            if let mouse = mouse {
                let dx = mouse.x - cx
                let dy = mouse.y - cy
                let dist = hypot(dx, dy)
                if dist < 320 {
                    cx += dx * 0.30 * (1.0 - dist / 320)
                    cy += dy * 0.30 * (1.0 - dist / 320)
                }
            }

            let wingFlap = CGFloat(sin(time * 6.5 + Double(i))) * 14.0
            let col = colors[i % colors.count]

            // Geometric Origami Body Creases
            var leftWing = Path()
            leftWing.move(to: CGPoint(x: cx, y: cy))
            leftWing.addLine(to: CGPoint(x: cx - 18, y: cy - 10 + wingFlap))
            leftWing.addLine(to: CGPoint(x: cx - 6, y: cy + 4))
            leftWing.closeSubpath()
            context.fill(leftWing, with: .color(col.opacity(0.85)))
            context.stroke(leftWing, with: .color(Color.black.opacity(0.3)), lineWidth: 0.8)

            var rightWing = Path()
            rightWing.move(to: CGPoint(x: cx, y: cy))
            rightWing.addLine(to: CGPoint(x: cx + 18, y: cy - 10 + wingFlap))
            rightWing.addLine(to: CGPoint(x: cx + 6, y: cy + 4))
            rightWing.closeSubpath()
            context.fill(rightWing, with: .color(col.opacity(0.95)))
            context.stroke(rightWing, with: .color(Color.black.opacity(0.3)), lineWidth: 0.8)

            // Neck & Tail Beak
            var spine = Path()
            spine.move(to: CGPoint(x: cx, y: cy - 12))
            spine.addLine(to: CGPoint(x: cx, y: cy + 12))
            context.stroke(spine, with: .color(Color.black.opacity(0.5)), lineWidth: 1.2)
        }
    }

    private func drawDragon(
        context: GraphicsContext,
        W: CGFloat,
        H: CGFloat,
        time: Double,
        mouse: CGPoint?,
        colors: [Color],
        glowColor: Color,
        hasEmbers: Bool = false,
        hasIceShards: Bool = false,
        hasVoidPulse: Bool = false
    ) {
        let segmentCount = 36
        let t = time * 0.48

        func dragonPos(at offsetTime: Double) -> CGPoint {
            var px = (W * 0.12) + (W * 0.76) * (0.5 + 0.5 * sin(offsetTime * 0.72 + sin(offsetTime * 0.25)))
            var py = (H * 0.18) + (H * 0.64) * (0.5 + 0.5 * sin(offsetTime * 1.18 + cos(offsetTime * 0.45)))
            if let mouse = mouse {
                let dx = mouse.x - px
                let dy = mouse.y - py
                let dist = hypot(dx, dy)
                if dist < 450.0 {
                    let factor = (1.0 - dist / 450.0) * 0.55
                    px += dx * factor
                    py += dy * factor
                }
            }
            return CGPoint(x: px, y: py)
        }

        var points: [CGPoint] = []
        for i in 0..<segmentCount {
            points.append(dragonPos(at: t - Double(i) * 0.035))
        }

        guard points.count >= 5 else { return }
        let head = points[0]
        let neck = points[1]
        let chest = points[4]
        let heading = atan2(head.y - neck.y, head.x - neck.x)

        // 1. FLAPPING DRAGON WINGS (Attached to Chest/Shoulders)
        let wingFlap = CGFloat(sin(time * 7.5)) * 24.0
        let wingSpan: CGFloat = 52.0
        let perpAngle = heading + (.pi / 2.0)

        for side in [-1.0, 1.0] {
            let rootX = chest.x + CGFloat(cos(perpAngle) * side * 10.0)
            let rootY = chest.y + CGFloat(sin(perpAngle) * side * 10.0)
            let tipX = rootX + CGFloat(cos(perpAngle) * side * wingSpan) - CGFloat(cos(heading) * 16.0)
            let tipY = rootY + CGFloat(sin(perpAngle) * side * wingSpan) - CGFloat(sin(heading) * 16.0) + wingFlap

            var wingPath = Path()
            wingPath.move(to: CGPoint(x: rootX, y: rootY))
            wingPath.addQuadCurve(to: CGPoint(x: tipX, y: tipY), control: CGPoint(x: rootX + CGFloat(cos(perpAngle) * side * 28.0), y: rootY + wingFlap * 0.6 - 12))
            wingPath.addQuadCurve(to: CGPoint(x: rootX - CGFloat(cos(heading) * 22.0), y: rootY - CGFloat(sin(heading) * 22.0)), control: CGPoint(x: tipX - 10, y: tipY + 14))
            wingPath.closeSubpath()

            context.fill(wingPath, with: .linearGradient(Gradient(colors: [colors.first?.opacity(0.55) ?? Color.red.opacity(0.55), Color.clear]), startPoint: CGPoint(x: rootX, y: rootY), endPoint: CGPoint(x: tipX, y: tipY)))
            context.stroke(wingPath, with: .color(glowColor.opacity(0.85)), lineWidth: 1.6)
        }

        // 2. DRAGON SPINE LINE
        var spinePath = Path()
        spinePath.move(to: points[0])
        for pt in points.dropFirst() { spinePath.addLine(to: pt) }
        context.stroke(
            spinePath,
            with: .linearGradient(Gradient(colors: colors), startPoint: points.first ?? .zero, endPoint: points.last ?? .zero),
            lineWidth: 3.8
        )

        // 3. ANATOMICAL BODY SEGMENTS & SCALES
        for (i, pt) in points.enumerated() {
            let progress = 1.0 - (Double(i) / Double(segmentCount))
            let radius = CGFloat(progress * 13.5 + 2.5)

            // Scaled Segment Sphere
            let circle = Path(ellipseIn: CGRect(x: pt.x - radius, y: pt.y - radius, width: radius * 2, height: radius * 2))
            let col = (i == 0) ? Color.white : colors[i % colors.count].opacity(0.58 * progress)
            context.fill(circle, with: .color(col))

            // Realistic Horned Dragon Skull & Glowing Ember Jaws
            if i == 0 {
                let headGlow = Path(ellipseIn: CGRect(x: pt.x - 22, y: pt.y - 22, width: 44, height: 44))
                context.fill(headGlow, with: .color(glowColor.opacity(0.40)))

                // Draconic Horns (Swept Back)
                for side in [-1.0, 1.0] {
                    let hornBaseX = pt.x + CGFloat(cos(perpAngle) * side * 6.0) - CGFloat(cos(heading) * 4.0)
                    let hornBaseY = pt.y + CGFloat(sin(perpAngle) * side * 6.0) - CGFloat(sin(heading) * 4.0)
                    let hornTipX = hornBaseX + CGFloat(cos(perpAngle) * side * 14.0) - CGFloat(cos(heading) * 18.0)
                    let hornTipY = hornBaseY + CGFloat(sin(perpAngle) * side * 14.0) - CGFloat(sin(heading) * 18.0)

                    var horn = Path()
                    horn.move(to: CGPoint(x: hornBaseX, y: hornBaseY))
                    horn.addLine(to: CGPoint(x: hornTipX, y: hornTipY))
                    context.stroke(horn, with: .color(Color.white.opacity(0.95)), lineWidth: 2.4)
                }

                // Glowing Predatory Eyes
                let eyeL = CGPoint(x: pt.x + CGFloat(cos(perpAngle) * -4.5) + CGFloat(cos(heading) * 3.0), y: pt.y + CGFloat(sin(perpAngle) * -4.5) + CGFloat(sin(heading) * 3.0))
                let eyeR = CGPoint(x: pt.x + CGFloat(cos(perpAngle) * 4.5) + CGFloat(cos(heading) * 3.0), y: pt.y + CGFloat(sin(perpAngle) * 4.5) + CGFloat(sin(heading) * 3.0))
                context.fill(Path(ellipseIn: CGRect(x: eyeL.x - 2, y: eyeL.y - 2, width: 4, height: 4)), with: .color(Color.white))
                context.fill(Path(ellipseIn: CGRect(x: eyeR.x - 2, y: eyeR.y - 2, width: 4, height: 4)), with: .color(Color.white))
            }

            // Dorsal Spikes / Fins along Spine
            if i % 2 == 0 && i > 0 && i < segmentCount - 3 {
                let spikeLen = CGFloat(progress * 12.0 + 3.0)
                let dorsalX = pt.x + CGFloat(cos(perpAngle) * sin(time * 6.0 + Double(i))) * 4.0 - CGFloat(cos(heading) * spikeLen)
                let dorsalY = pt.y + CGFloat(sin(perpAngle) * sin(time * 6.0 + Double(i))) * 4.0 - CGFloat(sin(heading) * spikeLen)
                var spike = Path()
                spike.move(to: pt)
                spike.addLine(to: CGPoint(x: dorsalX, y: dorsalY))
                context.stroke(spike, with: .color(colors[i % colors.count].opacity(0.85)), lineWidth: 1.8)
            }
        }

        // 4. REAL-TIME FIRE-BREATHING FLAME JET ENGINE
        if hasEmbers || hasIceShards || hasVoidPulse {
            let breathOrigin = CGPoint(x: head.x + CGFloat(cos(heading) * 14.0), y: head.y + CGFloat(sin(heading) * 14.0))
            let particleCount = 18

            for p in 0..<particleCount {
                let seed = Double(p) * 1.618
                let life = (time * 2.2 + seed).truncatingRemainder(dividingBy: 1.0)
                let spread = (sin(time * 12.0 + seed * 4.0) * 0.38)
                let pAngle = heading + spread
                let dist = CGFloat(life * 90.0 + 8.0)
                let px = breathOrigin.x + CGFloat(cos(pAngle) * dist)
                let py = breathOrigin.y + CGFloat(sin(pAngle) * dist)
                let pSize = CGFloat(life * 14.0 + 2.5)

                let pCircle = Path(ellipseIn: CGRect(x: px - pSize / 2, y: py - pSize / 2, width: pSize, height: pSize))
                let alpha = (1.0 - life) * 0.85

                if hasEmbers {
                    // White-hot core fading to blazing orange/red fire
                    let flameCol = (life < 0.25) ? Color.white : ((life < 0.65) ? Color.yellow : Color.red)
                    context.fill(pCircle, with: .color(flameCol.opacity(alpha)))
                } else if hasIceShards {
                    // Diamond cyan & crystalline frost shards
                    let iceCol = (life < 0.35) ? Color.white : Color.cyan
                    context.fill(pCircle, with: .color(iceCol.opacity(alpha)))
                } else if hasVoidPulse {
                    // Dark matter purple/magenta vortex particles
                    let voidCol = (life < 0.3) ? Color.white : Color.purple
                    context.fill(pCircle, with: .color(voidCol.opacity(alpha)))
                }
            }
        }
    }

    // --- AUTHENTIC JAPANESE KOI POND SIMULATION ---
    private func drawJapaneseKoiPond(context: GraphicsContext, W: CGFloat, H: CGFloat, time: Double, mouse: CGPoint?) {
        let koiCount = 6

        // 6 Authentic Japanese Koi Breeds:
        // 0: Kohaku (White with Vermilion Red Hi)
        // 1: Yamabuki Ogon (24K Pure Metallic Gold)
        // 2: Taisho Sanke (White with Red Hi & Black Sumi Ink spots)
        // 3: Tancho (Pure Pearl White with Crimson Sun Crown)
        // 4: Asagi (Cyan/Indigo Diamond Net Scales & Flame Orange Pectorals)
        // 5: Showa (Black Lacquer with Fire Red & White Fin Trim)
        
        for k in 0..<koiCount {
            let kPhase = Double(k) * (2.0 * .pi / Double(koiCount))
            let speed = 0.42 + Double(k % 3) * 0.08
            let t = time * speed + Double(k) * 1.7

            // Organic Figure-8 / Elliptical Pond Trajectory
            var kx = (W * 0.12) + (W * 0.76) * (0.5 + 0.5 * sin(t * 0.55 + sin(t * 0.22 + Double(k))))
            var ky = (H * 0.16) + (H * 0.68) * (0.5 + 0.5 * cos(t * 0.75 + cos(t * 0.31 + Double(k))))

            // Active Feeding & Target Swarm Physics
            var isFeeding = false
            if let target = mouse {
                let dx = target.x - kx
                let dy = target.y - ky
                let dist = hypot(dx, dy)
                if dist < 480 {
                    isFeeding = true
                    let rushFactor = (1.0 - dist / 480.0) * 0.72
                    kx += dx * rushFactor
                    ky += dy * rushFactor

                    // Feeding Surface Water Ring
                    if dist < 32 {
                        let biteRipple = Path(ellipseIn: CGRect(x: target.x - 16, y: target.y - 16, width: 32, height: 32))
                        context.stroke(biteRipple, with: .color(Color.cyan.opacity(0.80 * (1.0 - dist / 32.0))), lineWidth: 1.8)
                    }
                }
            }

            let heading = t * 0.75 + (k % 2 == 0 ? 0 : .pi * 0.2) + (isFeeding ? sin(time * 10.0) * 0.15 : 0)
            let length: CGFloat = 34.0
            let spineNodes = 7

            // Multi-Node S-Curve Spine Coordinates
            var spine: [CGPoint] = []
            for s in 0..<spineNodes {
                let sFraction = CGFloat(s) / CGFloat(spineNodes - 1)
                let undulation = sin(time * 7.5 + kPhase - Double(s) * 0.65) * (sFraction * 6.5)
                let perp = heading + (.pi / 2.0)
                let nodeX = kx - CGFloat(cos(heading)) * (sFraction * length) + CGFloat(cos(perp)) * undulation
                let nodeY = ky - CGFloat(sin(heading)) * (sFraction * length) + CGFloat(sin(perp)) * undulation
                spine.append(CGPoint(x: nodeX, y: nodeY))
            }

            guard spine.count >= 4 else { continue }
            let head = spine[0]
            let shoulders = spine[1]
            let mid = spine[3]
            let tailBase = spine.last ?? head

            // 1. FLOWING SILK CAUDAL TAIL FIN
            let tailFlutter = CGFloat(sin(time * 9.0 + kPhase)) * 8.0
            let tailEnd = CGPoint(
                x: tailBase.x - CGFloat(cos(heading)) * 18.0 + CGFloat(cos(heading + .pi / 2)) * tailFlutter,
                y: tailBase.y - CGFloat(sin(heading)) * 18.0 + CGFloat(sin(heading + .pi / 2)) * tailFlutter
            )
            var caudalFin = Path()
            caudalFin.move(to: tailBase)
            caudalFin.addQuadCurve(to: CGPoint(x: tailEnd.x - 10, y: tailEnd.y - 8), control: CGPoint(x: tailBase.x - 8, y: tailBase.y - 6))
            caudalFin.addLine(to: CGPoint(x: tailEnd.x - 10, y: tailEnd.y + 8))
            caudalFin.addQuadCurve(to: tailBase, control: CGPoint(x: tailBase.x - 8, y: tailBase.y + 6))
            caudalFin.closeSubpath()
            context.fill(caudalFin, with: .color(Color.white.opacity(0.65)))

            // 2. TRANSLUCENT PECTORAL FINS (Flapping symmetrically)
            let finFlap = CGFloat(sin(time * 6.5 + kPhase)) * 4.0
            for side in [-1.0, 1.0] {
                let pAngle = heading + (.pi / 2.0)
                let finRoot = CGPoint(x: shoulders.x + CGFloat(cos(pAngle) * side * 6.0), y: shoulders.y + CGFloat(sin(pAngle) * side * 6.0))
                let finTip = CGPoint(
                    x: finRoot.x + CGFloat(cos(pAngle) * side * 14.0) - CGFloat(cos(heading) * 6.0),
                    y: finRoot.y + CGFloat(sin(pAngle) * side * 14.0) - CGFloat(sin(heading) * 6.0) + finFlap
                )
                var pectoral = Path()
                pectoral.move(to: finRoot)
                pectoral.addQuadCurve(to: finTip, control: CGPoint(x: finRoot.x + CGFloat(cos(pAngle) * side * 10.0), y: finRoot.y - 4))
                pectoral.addQuadCurve(to: CGPoint(x: finRoot.x - CGFloat(cos(heading) * 10.0), y: finRoot.y - CGFloat(sin(heading) * 10.0)), control: CGPoint(x: finTip.x - 4, y: finTip.y + 4))
                pectoral.closeSubpath()
                let finCol = (k == 4) ? Color.orange.opacity(0.7) : Color.white.opacity(0.60)
                context.fill(pectoral, with: .color(finCol))
            }

            // 3. SCULPTED FUSELAGE KOI BODY
            var bodyPath = Path()
            bodyPath.move(to: head)
            let bodyWidth: CGFloat = 8.5
            let pAngle = heading + (.pi / 2.0)
            bodyPath.addQuadCurve(to: tailBase, control: CGPoint(x: mid.x + CGFloat(cos(pAngle) * bodyWidth), y: mid.y + CGFloat(sin(pAngle) * bodyWidth)))
            bodyPath.addQuadCurve(to: head, control: CGPoint(x: mid.x - CGFloat(cos(pAngle) * bodyWidth), y: mid.y - CGFloat(sin(pAngle) * bodyWidth)))
            bodyPath.closeSubpath()

            // Realistic Breed Coloration
            switch k {
            case 0: // Kohaku (White + Crimson Red Plates)
                context.fill(bodyPath, with: .color(Color.white.opacity(0.95)))
                let hi1 = Path(ellipseIn: CGRect(x: shoulders.x - 5, y: shoulders.y - 4, width: 10, height: 8))
                let hi2 = Path(ellipseIn: CGRect(x: mid.x - 4, y: mid.y - 3, width: 8, height: 6))
                context.fill(hi1, with: .color(Color(red: 0.95, green: 0.20, blue: 0.10)))
                context.fill(hi2, with: .color(Color(red: 0.95, green: 0.20, blue: 0.10)))

            case 1: // Yamabuki Ogon (Pure 24K Metallic Gold)
                context.fill(bodyPath, with: .linearGradient(Gradient(colors: [Color(red: 1.0, green: 0.85, blue: 0.20), Color(red: 0.95, green: 0.60, blue: 0.10)]), startPoint: head, endPoint: tailBase))

            case 2: // Taisho Sanke (White + Red + Black Sumi Spots)
                context.fill(bodyPath, with: .color(Color.white.opacity(0.95)))
                let hi = Path(ellipseIn: CGRect(x: shoulders.x - 5, y: shoulders.y - 4, width: 10, height: 7))
                let sumi1 = Path(ellipseIn: CGRect(x: mid.x - 2, y: mid.y - 4, width: 4, height: 4))
                let sumi2 = Path(ellipseIn: CGRect(x: mid.x + 1, y: mid.y + 1, width: 3.5, height: 3.5))
                context.fill(hi, with: .color(Color(red: 0.95, green: 0.20, blue: 0.10)))
                context.fill(sumi1, with: .color(Color.black.opacity(0.9)))
                context.fill(sumi2, with: .color(Color.black.opacity(0.9)))

            case 3: // Tancho (Pure Pearl White + Perfect Crimson Sun Crown)
                context.fill(bodyPath, with: .color(Color.white.opacity(0.96)))
                let tanchoSun = Path(ellipseIn: CGRect(x: head.x - 3.5, y: head.y - 3.5, width: 7, height: 7))
                context.fill(tanchoSun, with: .color(Color(red: 0.92, green: 0.15, blue: 0.15)))

            case 4: // Asagi (Cyan/Indigo Scale Mesh + Flame Belly)
                context.fill(bodyPath, with: .linearGradient(Gradient(colors: [Color.cyan.opacity(0.9), Color.blue.opacity(0.7)]), startPoint: head, endPoint: tailBase))
                let flameTrim = Path(ellipseIn: CGRect(x: mid.x - 3, y: mid.y - 3, width: 6, height: 6))
                context.fill(flameTrim, with: .color(Color.orange))

            default: // Showa (Black base + Crimson & White)
                context.fill(bodyPath, with: .color(Color(white: 0.12, opacity: 0.95)))
                let hi = Path(ellipseIn: CGRect(x: shoulders.x - 4, y: shoulders.y - 4, width: 8, height: 8))
                context.fill(hi, with: .color(Color(red: 0.95, green: 0.25, blue: 0.15)))
            }
            context.stroke(bodyPath, with: .color(Color.white.opacity(0.5)), lineWidth: 0.8)

            // 4. EYES & WHISKER BARBELS
            let eyeL = CGPoint(x: head.x + CGFloat(cos(pAngle) * -3.5), y: head.y + CGFloat(sin(pAngle) * -3.5))
            let eyeR = CGPoint(x: head.x + CGFloat(cos(pAngle) * 3.5), y: head.y + CGFloat(sin(pAngle) * 3.5))
            context.fill(Path(ellipseIn: CGRect(x: eyeL.x - 1.5, y: eyeL.y - 1.5, width: 3, height: 3)), with: .color(Color.black))
            context.fill(Path(ellipseIn: CGRect(x: eyeR.x - 1.5, y: eyeR.y - 1.5, width: 3, height: 3)), with: .color(Color.black))

            // Whiskers (Left & Right)
            for side in [-1.0, 1.0] {
                var whisker = Path()
                whisker.move(to: CGPoint(x: head.x + CGFloat(cos(pAngle) * side * 2.5), y: head.y + CGFloat(sin(pAngle) * side * 2.5)))
                whisker.addLine(to: CGPoint(x: head.x + CGFloat(cos(heading) * 6.0) + CGFloat(cos(pAngle) * side * 5.0), y: head.y + CGFloat(sin(heading) * 6.0) + CGFloat(sin(pAngle) * side * 5.0)))
                context.stroke(whisker, with: .color(Color.white.opacity(0.8)), lineWidth: 0.9)
            }
        }
    }

    // 🐬 4K HYPER-REALISTIC PACIFIC OCEAN DOLPHINS
    private func drawPacificDolphins(context: GraphicsContext, W: CGFloat, H: CGFloat, time: Double, mouse: CGPoint?) {
        let dolphinCount = 3
        for d in 0..<dolphinCount {
            let dOffset = Double(d) * 2.2
            let speed = 0.38 + Double(d) * 0.06
            let t = time * speed + dOffset

            // Swimming trajectory + surface breach arcs
            let breachCycle = sin(t * 0.7)
            let isBreaching = breachCycle > 0.4
            let breachHeight: CGFloat = isBreaching ? CGFloat(breachCycle - 0.4) * 120.0 : 0.0

            var dx = (W * 0.15) + (W * 0.70) * (0.5 + 0.5 * sin(t * 0.45 + Double(d) * 0.8))
            var dy = (H * 0.25) + (H * 0.50) * (0.5 + 0.5 * cos(t * 0.60 + Double(d) * 0.5)) - breachHeight

            // Interactive Bow-Wave Cursor Surfing
            if let mouse = mouse {
                let dist = hypot(mouse.x - dx, mouse.y - dy)
                if dist < 420 {
                    let attract = (1.0 - dist / 420.0) * 0.65
                    dx += (mouse.x - dx) * attract
                    dy += (mouse.y - dy) * attract

                    // Surfacing bubble ring
                    if dist < 60 {
                        let bubbleRing = Path(ellipseIn: CGRect(x: dx - 20, y: dy - 12, width: 40, height: 24))
                        context.stroke(bubbleRing, with: .color(Color.cyan.opacity(0.85 * (1.0 - dist / 60.0))), lineWidth: 1.5)
                    }
                }
            }

            let heading = t * 0.65 + Double(d) * 0.4
            let length: CGFloat = 52.0
            let bodyNodes = 8

            // Sinusoidal Multi-Node Fluke Spine
            var spine: [CGPoint] = []
            for s in 0..<bodyNodes {
                let sFrac = CGFloat(s) / CGFloat(bodyNodes - 1)
                let flukeWave = sin(time * 6.5 + dOffset - Double(s) * 0.75) * (sFrac * 8.0)
                let perp = heading + (.pi / 2.0)
                let nx = dx - CGFloat(cos(heading)) * (sFrac * length) + CGFloat(cos(perp)) * flukeWave
                let ny = dy - CGFloat(sin(heading)) * (sFrac * length) + CGFloat(sin(perp)) * flukeWave
                spine.append(CGPoint(x: nx, y: ny))
            }

            guard spine.count >= 6 else { continue }
            let snout = spine[0]
            let melon = spine[1]
            let shoulders = spine[2]
            let midBody = spine[4]
            let tailPeduncle = spine.last ?? snout
            let perp = heading + (.pi / 2.0)

            // 1. DOLPHIN HORIZONTAL CAUDAL FLUKE (Tail Fluke)
            let flukeFlutter = CGFloat(sin(time * 8.0 + dOffset)) * 6.0
            var fluke = Path()
            fluke.move(to: tailPeduncle)
            let fLeft = CGPoint(x: tailPeduncle.x + CGFloat(cos(perp) * -16.0) - CGFloat(cos(heading) * 8.0), y: tailPeduncle.y + CGFloat(sin(perp) * -16.0) - CGFloat(sin(heading) * 8.0) + flukeFlutter)
            let fRight = CGPoint(x: tailPeduncle.x + CGFloat(cos(perp) * 16.0) - CGFloat(cos(heading) * 8.0), y: tailPeduncle.y + CGFloat(sin(perp) * 16.0) - CGFloat(sin(heading) * 8.0) + flukeFlutter)
            fluke.addQuadCurve(to: fLeft, control: CGPoint(x: tailPeduncle.x - 6, y: tailPeduncle.y - 4))
            fluke.addLine(to: CGPoint(x: tailPeduncle.x - CGFloat(cos(heading) * 4.0), y: tailPeduncle.y - CGFloat(sin(heading) * 4.0)))
            fluke.addLine(to: fRight)
            fluke.addQuadCurve(to: tailPeduncle, control: CGPoint(x: tailPeduncle.x + 6, y: tailPeduncle.y - 4))
            fluke.closeSubpath()
            context.fill(fluke, with: .color(Color(red: 0.28, green: 0.38, blue: 0.48)))

            // 2. PECTORAL FLIPPERS
            for side in [-1.0, 1.0] {
                let flipRoot = CGPoint(x: shoulders.x + CGFloat(cos(perp) * side * 6.5), y: shoulders.y + CGFloat(sin(perp) * side * 6.5))
                let flipTip = CGPoint(x: flipRoot.x + CGFloat(cos(perp) * side * 16.0) - CGFloat(cos(heading) * 10.0), y: flipRoot.y + CGFloat(sin(perp) * side * 16.0) - CGFloat(sin(heading) * 10.0))
                var flipper = Path()
                flipper.move(to: flipRoot)
                flipper.addQuadCurve(to: flipTip, control: CGPoint(x: flipRoot.x + CGFloat(cos(perp) * side * 8.0), y: flipRoot.y - 6))
                flipper.addQuadCurve(to: CGPoint(x: flipRoot.x - CGFloat(cos(heading) * 8.0), y: flipRoot.y - CGFloat(sin(heading) * 8.0)), control: CGPoint(x: flipTip.x - 4, y: flipTip.y + 4))
                flipper.closeSubpath()
                context.fill(flipper, with: .color(Color(red: 0.32, green: 0.42, blue: 0.52)))
            }

            // 3. CURVED DORSAL FIN
            var dorsal = Path()
            let dorsalBase = midBody
            let dorsalTip = CGPoint(x: dorsalBase.x - CGFloat(cos(heading) * 14.0) + CGFloat(cos(perp) * 12.0), y: dorsalBase.y - CGFloat(sin(heading) * 14.0) + CGFloat(sin(perp) * 12.0))
            dorsal.move(to: dorsalBase)
            dorsal.addQuadCurve(to: dorsalTip, control: CGPoint(x: dorsalBase.x - 4, y: dorsalBase.y - 8))
            dorsal.addQuadCurve(to: CGPoint(x: dorsalBase.x - CGFloat(cos(heading) * 12.0), y: dorsalBase.y - CGFloat(sin(heading) * 12.0)), control: CGPoint(x: dorsalTip.x - 6, y: dorsalTip.y - 2))
            dorsal.closeSubpath()
            context.fill(dorsal, with: .color(Color(red: 0.25, green: 0.34, blue: 0.44)))

            // 4. STREAMLINED CETACEAN BODY (Dorsal Cape & Pearl Ventral Belly)
            var dolphinBody = Path()
            dolphinBody.move(to: snout)
            let bWidth: CGFloat = 11.5
            dolphinBody.addQuadCurve(to: tailPeduncle, control: CGPoint(x: melon.x + CGFloat(cos(perp) * bWidth), y: melon.y + CGFloat(sin(perp) * bWidth)))
            dolphinBody.addQuadCurve(to: snout, control: CGPoint(x: melon.x - CGFloat(cos(perp) * bWidth), y: melon.y - CGFloat(sin(perp) * bWidth)))
            dolphinBody.closeSubpath()

            // Realistic oceanic slate-gray to luminous pearl belly gradient
            context.fill(
                dolphinBody,
                with: .linearGradient(
                    Gradient(colors: [
                        Color(red: 0.22, green: 0.32, blue: 0.42),
                        Color(red: 0.40, green: 0.52, blue: 0.64),
                        Color(red: 0.88, green: 0.94, blue: 0.98)
                    ]),
                    startPoint: CGPoint(x: melon.x + CGFloat(cos(perp) * bWidth), y: melon.y + CGFloat(sin(perp) * bWidth)),
                    endPoint: CGPoint(x: melon.x - CGFloat(cos(perp) * bWidth), y: melon.y - CGFloat(sin(perp) * bWidth))
                )
            )
            context.stroke(dolphinBody, with: .color(Color.white.opacity(0.45)), lineWidth: 0.8)

            // 5. BLOWHOLE SPRAY MIST WHEN SURFACING
            if isBreaching {
                for m in 0..<8 {
                    let mx = melon.x + CGFloat(sin(Double(m) * 1.5)) * 12.0
                    let my = melon.y - 12.0 - CGFloat(m * 4)
                    let mist = Path(ellipseIn: CGRect(x: mx - 2, y: my - 2, width: 4, height: 4))
                    context.fill(mist, with: .color(Color.white.opacity(0.85)))
                }
            }
        }
    }

    // 🐠 4K VIBRANT TROPICAL CORAL REEF AQUARIA (Clownfish, Blue Tang, Yellow Tang, Moorish Idol)
    private func drawCoralReefAquaria(context: GraphicsContext, W: CGFloat, H: CGFloat, time: Double, mouse: CGPoint?) {
        let fishCount = 8
        for f in 0..<fishCount {
            let fPhase = Double(f) * 1.4
            let speed = 0.45 + Double(f % 4) * 0.08
            let t = time * speed + fPhase

            var fx = (W * 0.10) + (W * 0.80) * (0.5 + 0.5 * sin(t * 0.6 + Double(f) * 1.1))
            var fy = (H * 0.15) + (H * 0.70) * (0.5 + 0.5 * cos(t * 0.8 + sin(t * 0.3 + Double(f))))

            if let mouse = mouse {
                let dist = hypot(mouse.x - fx, mouse.y - fy)
                if dist < 240 {
                    let repel = (1.0 - dist / 240.0) * 0.55
                    fx -= (mouse.x - fx) * repel
                    fy -= (mouse.y - fy) * repel
                }
            }

            let heading = t * 0.75 + (f % 2 == 0 ? 0 : .pi * 0.15)
            let length: CGFloat = 28.0
            let pAngle = heading + (.pi / 2.0)
            let breed = f % 4

            let head = CGPoint(x: fx, y: fy)
            let tail = CGPoint(x: fx - CGFloat(cos(heading)) * length, y: fy - CGFloat(sin(heading)) * length)
            let mid = CGPoint(x: fx - CGFloat(cos(heading)) * (length * 0.5), y: fy - CGFloat(sin(heading)) * (length * 0.5))

            // 1. FLUTTERING TAIL FIN
            let finFlutter = CGFloat(sin(time * 11.0 + fPhase)) * 5.0
            var tailFin = Path()
            tailFin.move(to: tail)
            let t1 = CGPoint(x: tail.x - CGFloat(cos(heading)) * 12.0 + CGFloat(cos(pAngle) * 8.0), y: tail.y - CGFloat(sin(heading)) * 12.0 + CGFloat(sin(pAngle) * 8.0) + finFlutter)
            let t2 = CGPoint(x: tail.x - CGFloat(cos(heading)) * 12.0 - CGFloat(cos(pAngle) * 8.0), y: tail.y - CGFloat(sin(heading)) * 12.0 - CGFloat(sin(pAngle) * 8.0) + finFlutter)
            tailFin.addLine(to: t1)
            tailFin.addLine(to: t2)
            tailFin.closeSubpath()

            let tailColor: Color = (breed == 1) ? Color.yellow : ((breed == 2) ? Color.yellow : Color.orange)
            context.fill(tailFin, with: .color(tailColor.opacity(0.85)))

            // 2. SCULPTED FISH BODY WITH ICONIC MARKINGS
            var fishBody = Path()
            fishBody.move(to: head)
            let bWidth: CGFloat = (breed == 3) ? 14.0 : 8.0 // Moorish Idol is disc-shaped
            fishBody.addQuadCurve(to: tail, control: CGPoint(x: mid.x + CGFloat(cos(pAngle) * bWidth), y: mid.y + CGFloat(sin(pAngle) * bWidth)))
            fishBody.addQuadCurve(to: head, control: CGPoint(x: mid.x - CGFloat(cos(pAngle) * bWidth), y: mid.y - CGFloat(sin(pAngle) * bWidth)))
            fishBody.closeSubpath()

            switch breed {
            case 0: // Clownfish (Orange + White Stripes)
                context.fill(fishBody, with: .color(Color(red: 1.0, green: 0.45, blue: 0.05)))
                let s1 = Path(ellipseIn: CGRect(x: mid.x - 3, y: mid.y - 7, width: 6, height: 14))
                context.fill(s1, with: .color(Color.white))
                context.stroke(s1, with: .color(Color.black), lineWidth: 0.8)

            case 1: // Blue Tang (Royal Blue + Yellow Palette)
                context.fill(fishBody, with: .color(Color(red: 0.05, green: 0.35, blue: 0.95)))
                let pal = Path(ellipseIn: CGRect(x: mid.x - 2, y: mid.y - 4, width: 6, height: 8))
                context.fill(pal, with: .color(Color.black.opacity(0.9)))

            case 2: // Yellow Tang (Pure Canary Yellow)
                context.fill(fishBody, with: .color(Color(red: 1.0, green: 0.88, blue: 0.15)))

            default: // Moorish Idol (Black / White / Yellow Tall Stripes)
                context.fill(fishBody, with: .color(Color.white))
                let stripe = Path(CGRect(x: mid.x - 4, y: mid.y - 12, width: 8, height: 24))
                context.fill(stripe, with: .color(Color.black.opacity(0.9)))
            }
            context.stroke(fishBody, with: .color(Color.white.opacity(0.4)), lineWidth: 0.8)

            // Rising Micro-Bubbles
            let bY = fy - CGFloat((time * 24.0 + Double(f) * 60.0).truncatingRemainder(dividingBy: 80.0))
            let bubble = Path(ellipseIn: CGRect(x: fx - 2, y: bY - 2, width: 4, height: 4))
            context.stroke(bubble, with: .color(Color.white.opacity(0.75)), lineWidth: 0.8)
        }
    }

    // 🌊 4K DEEP SEA GIANT MANTA RAYS
    private func drawDeepSeaMantas(context: GraphicsContext, W: CGFloat, H: CGFloat, time: Double, mouse: CGPoint?) {
        for m in 0..<2 {
            let t = time * 0.28 + Double(m) * 3.2
            var mx = (W * 0.2) + (W * 0.6) * (0.5 + 0.5 * sin(t * 0.45 + Double(m)))
            var my = (H * 0.25) + (H * 0.55) * (0.5 + 0.5 * cos(t * 0.65 + Double(m)))

            if let mouse = mouse {
                let dist = hypot(mouse.x - mx, mouse.y - my)
                if dist < 360 {
                    mx += (mouse.x - mx) * 0.3 * (1.0 - dist / 360.0)
                    my += (mouse.y - my) * 0.3 * (1.0 - dist / 360.0)
                }
            }

            let heading = t * 0.6 + Double(m) * 0.5
            let pAngle = heading + (.pi / 2.0)
            let wingSpan: CGFloat = 64.0
            let wingWave = CGFloat(sin(time * 4.0 + Double(m) * 2.0)) * 12.0

            let head = CGPoint(x: mx, y: my)
            let tailRoot = CGPoint(x: mx - CGFloat(cos(heading)) * 36.0, y: my - CGFloat(sin(heading)) * 36.0)
            let leftTip = CGPoint(x: mx + CGFloat(cos(pAngle) * -wingSpan), y: my + CGFloat(sin(pAngle) * -wingSpan) + wingWave)
            let rightTip = CGPoint(x: mx + CGFloat(cos(pAngle) * wingSpan), y: my + CGFloat(sin(pAngle) * wingSpan) + wingWave)

            // Diamond Wing Body
            var manta = Path()
            manta.move(to: head)
            manta.addQuadCurve(to: leftTip, control: CGPoint(x: head.x - 10, y: head.y - 12))
            manta.addQuadCurve(to: tailRoot, control: CGPoint(x: leftTip.x + 20, y: leftTip.y + 14))
            manta.addQuadCurve(to: rightTip, control: CGPoint(x: rightTip.x - 20, y: rightTip.y + 14))
            manta.addQuadCurve(to: head, control: CGPoint(x: head.x + 10, y: head.y - 12))
            manta.closeSubpath()

            context.fill(
                manta,
                with: .linearGradient(
                    Gradient(colors: [Color(red: 0.10, green: 0.16, blue: 0.26), Color(red: 0.22, green: 0.38, blue: 0.55)]),
                    startPoint: head,
                    endPoint: tailRoot
                )
            )
            context.stroke(manta, with: .color(Color.white.opacity(0.6)), lineWidth: 1.0)

            // Long Whip Tail
            var whipTail = Path()
            whipTail.move(to: tailRoot)
            let whipEnd = CGPoint(x: tailRoot.x - CGFloat(cos(heading)) * 54.0, y: tailRoot.y - CGFloat(sin(heading)) * 54.0)
            whipTail.addQuadCurve(to: whipEnd, control: CGPoint(x: tailRoot.x - 20, y: tailRoot.y + 8))
            context.stroke(whipTail, with: .color(Color.white.opacity(0.7)), lineWidth: 1.2)
        }
    }


    // --- CURSOR FX TRAILS ---
    private func drawCursorFX(context: GraphicsContext, W: CGFloat, H: CGFloat, time: Double, type: String, mouse: CGPoint, trail: [CursorTrailPoint]) {
        switch type {
        case "Ice Cream Cone & Sprinkles 🍦":
            // 1. Waffle Cone Cursor Pointer
            var cone = Path()
            cone.move(to: CGPoint(x: mouse.x, y: mouse.y + 14))
            cone.addLine(to: CGPoint(x: mouse.x - 7, y: mouse.y + 2))
            cone.addLine(to: CGPoint(x: mouse.x + 7, y: mouse.y + 2))
            cone.closeSubpath()
            context.fill(cone, with: .color(Color(red: 0.88, green: 0.65, blue: 0.35)))
            context.stroke(cone, with: .color(Color(red: 0.68, green: 0.45, blue: 0.20)), lineWidth: 1.0)

            // Strawberry scoop on top
            let scoop = Path(ellipseIn: CGRect(x: mouse.x - 8, y: mouse.y - 7, width: 16, height: 12))
            context.fill(scoop, with: .color(Color(red: 1.0, green: 0.50, blue: 0.65)))

            // 2. Falling Rainbow Sprinkles Trail
            let sprinkleColors: [Color] = [
                Color.red, Color.yellow, Color.cyan, Color.green, Color.orange, Color.purple, Color.white
            ]
            for (idx, pt) in trail.enumerated() {
                let age = time - pt.timestamp
                let progress = 1.0 - (age / 0.48)
                if progress > 0 {
                    // Gravity fall and flutter
                    let fallY = CGFloat(age * age * 120.0 + age * 20.0)
                    let swayX = CGFloat(sin(time * 6.0 + Double(idx * 3))) * 5.0
                    let p = CGPoint(x: pt.point.x + swayX, y: pt.point.y + fallY)
                    let col = sprinkleColors[idx % sprinkleColors.count]

                    // Pill-shaped sprinkle capsule
                    var sprinkle = Path()
                    let angle = Double(idx * 45) * .pi / 180.0
                    let len: CGFloat = 6.0 * CGFloat(progress)
                    sprinkle.move(to: CGPoint(x: p.x - CGFloat(cos(angle)) * len, y: p.y - CGFloat(sin(angle)) * len))
                    sprinkle.addLine(to: CGPoint(x: p.x + CGFloat(cos(angle)) * len, y: p.y + CGFloat(sin(angle)) * len))
                    context.stroke(sprinkle, with: .color(col.opacity(Double(progress * 0.95))), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
                }
            }

        case "Cotton Candy Clouds 🍭":
            for (idx, pt) in trail.enumerated() {
                let age = time - pt.timestamp
                let progress = 1.0 - (age / 0.50)
                if progress > 0 {
                    let p = pt.point
                    let rad = CGFloat((Double(idx % 3) * 4.0 + 8.0) * progress)
                    let col = (idx % 2 == 0)
                        ? Color(red: 1.0, green: 0.60, blue: 0.80, opacity: progress * 0.55)
                        : Color(red: 0.50, green: 0.85, blue: 1.0, opacity: progress * 0.55)
                    let cloud = Path(ellipseIn: CGRect(x: p.x - rad, y: p.y - rad, width: rad * 2, height: rad * 2))
                    context.fill(cloud, with: .color(col))
                }
            }

        case "Stardust Sparkles ✨", "Stardust Tail":
            for (_, pt) in trail.enumerated() {
                let age = time - pt.timestamp
                let progress = 1.0 - (age / 0.40)
                if progress > 0 {
                    let p = pt.point
                    let radius = CGFloat(progress * 6.0 + 1.2)
                    
                    // 4-point diamond star burst
                    var starPath = Path()
                    starPath.move(to: CGPoint(x: p.x, y: p.y - radius * 1.5))
                    starPath.addLine(to: CGPoint(x: p.x + radius * 0.4, y: p.y - radius * 0.4))
                    starPath.addLine(to: CGPoint(x: p.x + radius * 1.5, y: p.y))
                    starPath.addLine(to: CGPoint(x: p.x + radius * 0.4, y: p.y + radius * 0.4))
                    starPath.move(to: CGPoint(x: p.x, y: p.y + radius * 1.5))
                    starPath.addLine(to: CGPoint(x: p.x - radius * 0.4, y: p.y + radius * 0.4))
                    starPath.addLine(to: CGPoint(x: p.x - radius * 1.5, y: p.y))
                    starPath.addLine(to: CGPoint(x: p.x - radius * 0.4, y: p.y - radius * 0.4))
                    starPath.closeSubpath()
                    
                    let goldColor = Color(red: 1.0, green: 0.88, blue: 0.35, opacity: progress * 0.85)
                    context.fill(starPath, with: .color(goldColor))
                    
                    let core = Path(ellipseIn: CGRect(x: p.x - radius * 0.6, y: p.y - radius * 0.6, width: radius * 1.2, height: radius * 1.2))
                    context.fill(core, with: .color(Color.white.opacity(progress * 0.90)))
                }
            }

        case "Rainbow Nebula Comet 🌈":
            guard !trail.isEmpty else { return }
            var ribbon = Path()
            if let first = trail.first {
                ribbon.move(to: first.point)
                for pt in trail.dropFirst() { ribbon.addLine(to: pt.point) }
                ribbon.addLine(to: mouse)
            }
            context.stroke(
                ribbon,
                with: .linearGradient(
                    Gradient(colors: [
                        Color.red.opacity(0.1),
                        Color.orange.opacity(0.4),
                        Color.yellow.opacity(0.7),
                        Color.green.opacity(0.85),
                        Color.cyan,
                        Color.purple,
                        Color.white
                    ]),
                    startPoint: trail.first?.point ?? mouse,
                    endPoint: mouse
                ),
                style: StrokeStyle(lineWidth: 5.5, lineCap: .round, lineJoin: .round)
            )
            // Glowing comet head
            let headGlow = Path(ellipseIn: CGRect(x: mouse.x - 9, y: mouse.y - 9, width: 18, height: 18))
            context.fill(headGlow, with: .color(Color.white.opacity(0.95)))

        case "Cyber Neon Ribbon ⚡️", "Plasma Ribbon":
            guard !trail.isEmpty else { return }
            var ribbon = Path()
            if let first = trail.first {
                ribbon.move(to: first.point)
                for pt in trail.dropFirst() { ribbon.addLine(to: pt.point) }
                ribbon.addLine(to: mouse)
            }
            // Outer magenta aura
            context.stroke(
                ribbon,
                with: .linearGradient(Gradient(colors: [Color.purple.opacity(0.1), Color.pink.opacity(0.6), Color.cyan]), startPoint: trail.first?.point ?? mouse, endPoint: mouse),
                style: StrokeStyle(lineWidth: 6.0, lineCap: .round, lineJoin: .round)
            )
            // Inner crisp laser core
            context.stroke(
                ribbon,
                with: .linearGradient(Gradient(colors: [Color.clear, Color.cyan, Color.white]), startPoint: trail.first?.point ?? mouse, endPoint: mouse),
                style: StrokeStyle(lineWidth: 2.0, lineCap: .round, lineJoin: .round)
            )

        case "Fire Ember Sparks 🔥":
            for (idx, pt) in trail.enumerated() {
                let age = time - pt.timestamp
                let progress = 1.0 - (age / 0.45)
                if progress > 0 {
                    let driftY = CGFloat(age * 55.0)
                    let jitterX = CGFloat(sin(time * 12.0 + Double(idx) * 2.1)) * 6.0
                    let p = CGPoint(x: pt.point.x + jitterX, y: pt.point.y - driftY)
                    let rad = CGFloat(progress * 4.5 + 1.0)
                    
                    let sparkColor = (idx % 3 == 0)
                        ? Color(red: 1.0, green: 0.3, blue: 0.05, opacity: progress * 0.9)
                        : ((idx % 3 == 1)
                            ? Color(red: 1.0, green: 0.7, blue: 0.1, opacity: progress * 0.85)
                            : Color(red: 1.0, green: 0.95, blue: 0.3, opacity: progress * 0.75))
                    
                    let spark = Path(ellipseIn: CGRect(x: p.x - rad, y: p.y - rad, width: rad * 2, height: rad * 2))
                    context.fill(spark, with: .color(sparkColor))
                }
            }

        case "Deep Ocean Bubble Wake 🫧":
            for (idx, pt) in trail.enumerated() {
                let age = time - pt.timestamp
                let progress = 1.0 - (age / 0.50)
                if progress > 0 {
                    let floatY = CGFloat(age * 30.0)
                    let p = CGPoint(x: pt.point.x + CGFloat(sin(Double(idx) + time * 3.0)) * 4.0, y: pt.point.y - floatY)
                    let rad = CGFloat((Double(idx % 4) + 2.5) * progress)
                    
                    // Translucent bubble body
                    let bubble = Path(ellipseIn: CGRect(x: p.x - rad, y: p.y - rad, width: rad * 2, height: rad * 2))
                    context.fill(bubble, with: .color(Color.cyan.opacity(progress * 0.30)))
                    context.stroke(bubble, with: .color(Color.white.opacity(progress * 0.80)), lineWidth: 1.0)
                    
                    // Specular glint
                    let glint = Path(ellipseIn: CGRect(x: p.x - rad * 0.4, y: p.y - rad * 0.5, width: rad * 0.5, height: rad * 0.3))
                    context.fill(glint, with: .color(Color.white.opacity(progress * 0.95)))
                }
            }

        case "Electric Lightning Arc ⚡":
            if trail.count >= 2 {
                var lightning = Path()
                lightning.move(to: mouse)
                for (i, pt) in trail.enumerated() {
                    let midJitterX = CGFloat(sin(time * 30.0 + Double(i) * 5.0)) * 7.0
                    let midJitterY = CGFloat(cos(time * 30.0 + Double(i) * 5.0)) * 7.0
                    let midPt = CGPoint(x: (pt.point.x + mouse.x) / 2.0 + midJitterX, y: (pt.point.y + mouse.y) / 2.0 + midJitterY)
                    lightning.addLine(to: midPt)
                    lightning.addLine(to: pt.point)
                }
                context.stroke(lightning, with: .color(Color(red: 0.4, green: 0.8, blue: 1.0, opacity: 0.85)), lineWidth: 2.2)
                context.stroke(lightning, with: .color(Color.white.opacity(0.95)), lineWidth: 0.8)
            }

        case "Matrix Green Binary Stream 🟢":
            for (idx, pt) in trail.enumerated() {
                let age = time - pt.timestamp
                let progress = 1.0 - (age / 0.45)
                if progress > 0 {
                    let char = ((idx + Int(time * 10)) % 2 == 0) ? "1" : "0"
                    let p = pt.point
                    context.draw(
                        Text(char)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(Color(red: 0.0, green: 1.0, blue: 0.35, opacity: progress * 0.90)),
                        at: p
                    )
                }
            }

        case "Golden Gate Bridge Shimmer 🌉":
            for (idx, pt) in trail.enumerated() {
                let age = time - pt.timestamp
                let progress = 1.0 - (age / 0.45)
                if progress > 0 {
                    let p = pt.point
                    let rad = CGFloat(progress * 5.0 + 1.5)
                    let color = (idx % 2 == 0)
                        ? Color(red: 0.95, green: 0.40, blue: 0.15, opacity: progress * 0.90) // International Orange
                        : Color(red: 1.00, green: 0.85, blue: 0.30, opacity: progress * 0.85) // Sunset Gold
                    
                    let diamond = Path(ellipseIn: CGRect(x: p.x - rad, y: p.y - rad, width: rad * 2, height: rad * 2))
                    context.fill(diamond, with: .color(color))
                    
                    // Ray lines
                    var ray = Path()
                    ray.move(to: CGPoint(x: p.x - rad * 2, y: p.y))
                    ray.addLine(to: CGPoint(x: p.x + rad * 2, y: p.y))
                    context.stroke(ray, with: .color(Color.white.opacity(progress * 0.70)), lineWidth: 0.8)
                }
            }

        case "Hyperdrive Warp Beams 🌌":
            for pt in trail {
                let age = time - pt.timestamp
                let progress = 1.0 - (age / 0.35)
                if progress > 0 {
                    var beam = Path()
                    beam.move(to: pt.point)
                    beam.addLine(to: mouse)
                    context.stroke(
                        beam,
                        with: .color(Color(red: 0.6, green: 0.4, blue: 1.0, opacity: progress * 0.65)),
                        style: StrokeStyle(lineWidth: CGFloat(progress * 3.5), lineCap: .round)
                    )
                }
            }

        case "Heart Petal Drift 🌸":
            for (idx, pt) in trail.enumerated() {
                let age = time - pt.timestamp
                let progress = 1.0 - (age / 0.50)
                if progress > 0 {
                    let driftX = CGFloat(sin(time * 3.0 + Double(idx))) * 10.0
                    let p = CGPoint(x: pt.point.x + driftX, y: pt.point.y + CGFloat(age * 25.0))
                    let petalRad: CGFloat = 5.0 * CGFloat(progress)
                    let petal = Path(ellipseIn: CGRect(x: p.x - petalRad, y: p.y - petalRad * 0.6, width: petalRad * 2, height: petalRad * 1.2))
                    context.fill(petal, with: .color(Color(red: 1.0, green: 0.65, blue: 0.80, opacity: progress * 0.85)))
                }
            }

        case "Pixel 8-Bit Arcade Blast 👾":
            for (idx, pt) in trail.enumerated() {
                let age = time - pt.timestamp
                let progress = 1.0 - (age / 0.40)
                if progress > 0 {
                    let p = pt.point
                    let size = CGFloat(progress * 6.0 + 2.0)
                    let colors: [Color] = [.yellow, .green, .cyan, .pink, .orange]
                    let col = colors[idx % colors.count]
                    let square = Path(CGRect(x: p.x - size / 2, y: p.y - size / 2, width: size, height: size))
                    context.fill(square, with: .color(col.opacity(progress * 0.90)))
                }
            }

        case "Cyber Ring & Target 🎯", "Cyber Ring":
            let ringRadius: CGFloat = 16.0 + 3.0 * CGFloat(sin(time * 6.0))
            let ring = Path(ellipseIn: CGRect(x: mouse.x - ringRadius, y: mouse.y - ringRadius, width: ringRadius * 2, height: ringRadius * 2))
            context.stroke(ring, with: .color(Color.cyan.opacity(0.85)), lineWidth: 1.5)
            
            // Crosshairs
            var cross = Path()
            cross.move(to: CGPoint(x: mouse.x - ringRadius - 4, y: mouse.y))
            cross.addLine(to: CGPoint(x: mouse.x - ringRadius + 3, y: mouse.y))
            cross.move(to: CGPoint(x: mouse.x + ringRadius - 3, y: mouse.y))
            cross.addLine(to: CGPoint(x: mouse.x + ringRadius + 4, y: mouse.y))
            cross.move(to: CGPoint(x: mouse.x, y: mouse.y - ringRadius - 4))
            cross.addLine(to: CGPoint(x: mouse.x, y: mouse.y - ringRadius + 3))
            cross.move(to: CGPoint(x: mouse.x, y: mouse.y + ringRadius - 3))
            cross.addLine(to: CGPoint(x: mouse.x, y: mouse.y + ringRadius + 4))
            context.stroke(cross, with: .color(Color.white.opacity(0.9)), lineWidth: 1.2)

        case "Quantum Vortex 🌪️", "Quantum Vortex":
            for i in 0..<4 {
                let angle = time * 5.0 + (Double(i) * .pi / 2.0)
                let px = mouse.x + CGFloat(cos(angle)) * 20.0
                let py = mouse.y + CGFloat(sin(angle)) * 20.0
                let dot = Path(ellipseIn: CGRect(x: px - 3, y: py - 3, width: 6, height: 6))
                context.fill(dot, with: .color(Color.mint.opacity(0.85)))
                
                var fluxLine = Path()
                fluxLine.move(to: mouse)
                fluxLine.addLine(to: CGPoint(x: px, y: py))
                context.stroke(fluxLine, with: .color(Color.cyan.opacity(0.35)), lineWidth: 0.8)
            }

        default:
            break
        }
    }
}

// MARK: - Geometric Apps Matrix (Declarative Zero-Lag Pipeline)

// MARK: - Geometric Apps Matrix (Declarative 120 FPS CoreAnimation & Kinetic Pipeline)

struct AppFormationNode {
    var center: CGPoint
    var scale: CGFloat = 1.0
}

// MARK: - Surround Grid Metrics (Apps Framing & Surrounding Search Bar)
struct SurroundGridMetrics {
    let cols: Int
    let rows: Int
    let searchRow: Int
    let cellW: CGFloat
    let cellH: CGFloat
    let startX: CGFloat
    let startY: CGFloat
    let searchBarCenterY: CGFloat
    let searchBarExclusionRect: CGRect

    static func calculate(
        screenSize: CGSize,
        usableWidth: CGFloat,
        usableHeight: CGFloat,
        topClearance: CGFloat,
        sideMargin: CGFloat,
        iconSize: CGFloat,
        spacing: CGFloat,
        nameHeight: CGFloat,
        count: Int,
        desktopSplitMode: String = "Full Screen"
    ) -> SurroundGridMetrics {
        let nameH = nameHeight
        let effectiveSpacing = max(10.0, spacing)
        let cellW = iconSize + effectiveSpacing
        let cellH = iconSize + nameH + effectiveSpacing

        let isSplit = (desktopSplitMode == "Split Left (Files Right)" || desktopSplitMode == "Split Right (Files Left)")
        let isBothSides = (desktopSplitMode == "Split Center (Files Both)")
        let effectiveUsableWidth: CGFloat = isBothSides ? (usableWidth * 0.46) : (isSplit ? (usableWidth * 0.52) : usableWidth)

        // Search bar capsule dimensions
        let searchBarW = min(620.0, max(400.0, screenSize.width * 0.44))
        let searchBarH: CGFloat = 50.0
        let customPadding = CGFloat(UserDefaults.standard.double(forKey: PrefKey.chatGridPadding))
        let basePad = (customPadding > 0) ? customPadding : 48.0
        let clearanceX: CGFloat = max(basePad, effectiveSpacing * 1.8)
        let clearanceY: CGFloat = max(basePad * 0.85, effectiveSpacing * 1.6)
        let exclusionW = searchBarW + clearanceX * 2.0

        let maxCols = max(4, Int(floor((effectiveUsableWidth + effectiveSpacing) / cellW)))
        let maxRows = max(3, Int(floor((usableHeight + effectiveSpacing) / cellH)))

        // Number of columns the search bar spans in the center
        let searchSpanCols = max(2, Int(ceil(exclusionW / cellW)))
        let minColsNeeded = searchSpanCols + 2 // At least 1 column left and 1 column right

        let targetCols = min(maxCols, max(minColsNeeded, Int(ceil(sqrt(Double(count + searchSpanCols) * Double(effectiveUsableWidth / usableHeight))))))
        let cols = max(minColsNeeded, min(maxCols, targetCols))

        let slotsPerNormalRow = cols
        let slotsInSearchRow = max(2, cols - searchSpanCols)

        var rows = 3
        while rows < maxRows {
            let totalAvailable = (rows - 1) * slotsPerNormalRow + slotsInSearchRow
            if totalAvailable >= count {
                break
            }
            rows += 1
        }

        let searchRow = max(1, min(rows - 2, (rows - 1) / 2))

        let totalGridW = CGFloat(cols) * iconSize + CGFloat(max(0, cols - 1)) * effectiveSpacing

        let startX: CGFloat
        if desktopSplitMode == "Split Left (Files Right)" {
            startX = sideMargin
        } else if desktopSplitMode == "Split Right (Files Left)" {
            startX = screenSize.width - totalGridW - sideMargin
        } else {
            startX = max(sideMargin, (screenSize.width - totalGridW) / 2.0)
        }

        let startY = topClearance + 18.0

        let searchBarCenterY = startY + (iconSize / 2.0) + CGFloat(searchRow) * cellH
        let searchBarRect = CGRect(
            x: (screenSize.width - exclusionW) / 2.0,
            y: searchBarCenterY - (searchBarH / 2.0) - clearanceY,
            width: exclusionW,
            height: searchBarH + clearanceY * 2.0
        )

        return SurroundGridMetrics(
            cols: cols,
            rows: rows,
            searchRow: searchRow,
            cellW: cellW,
            cellH: cellH,
            startX: startX,
            startY: startY,
            searchBarCenterY: searchBarCenterY,
            searchBarExclusionRect: searchBarRect
        )
    }
}

struct GeometricAppsMatrix: View {
    @AppStorage(PrefKey.appLanguage) var appLanguage: String = "English (US)"
let apps: [AppInfo]
    let formation: String
    let physicsSimulation: String
    let physicsPhase: Double
    let orbitSpeed: Double
    let orbitClockwise: Bool
    let pulseIntensity: Double
    let screenSize: CGSize
    let usableWidth: CGFloat
    let usableHeight: CGFloat
    let topClearance: CGFloat
    let sideMargin: CGFloat
    let iconSize: CGFloat
    let textSize: CGFloat
    let curSpacing: CGFloat
    let nameHeight: CGFloat
    let showName: Bool
    let theme: String
    let tintColor: String
    var iconSnuggie: String = "None"
    var desktopSplitMode: String = "Full Screen"
    var customFormationColumns: Int = 4
    var scrollOffsetY: CGFloat = 0.0
    let flamePhase: Double
    let wallpaperImage: NSImage?
    let isEditing: Bool
    let wiggle: Bool
    let enableMagnification: Bool
    let maxMagnification: CGFloat
    let mouseLocation: CGPoint?
    @Binding var draggedAppID: String?
    @Binding var dragOffset: CGSize
    @Binding var dragHoverTargetID: String?
    let onLaunch: (AppInfo, CGPoint) -> Void
    let onHideApp: (AppInfo) -> Void
    let onShowInFinder: (AppInfo) -> Void
    let onEnterEditMode: () -> Void
    let onMoveApp: (String, String) -> Void

    @State private var hoveredAppID: String? = nil
    // Only formations whose geometry changes with `time` (orbits, bubbles, trains…) need the
    // 120 Hz timeline. Static grids/spirals pause it so an idle canvas costs zero CPU.
    @State private var isTimeDrivenFormation: Bool = true

    // Dance to Music: every app icon grooves while audio plays on the default output.
    @ObservedObject private var musicMonitor: MusicPlaybackMonitor = .shared
    @AppStorage(PrefKey.danceToMusicEnabled) private var danceToMusicEnabled: Bool = false
    @AppStorage(PrefKey.dockAnimationIntensity) private var dockAnimationIntensity: Double = 0.7

    private var isDancing: Bool {
        danceToMusicEnabled && !isEditing && musicMonitor.isMusicPlaying
    }

    /// Probes the layout at two instants; any drift means the formation animates with time.
    private func probeIsTimeDriven() -> Bool {
        let a = computeFormationLayout(time: 0.0)
        let b = computeFormationLayout(time: 0.37)
        guard a.count == b.count else { return true }
        for (id, nodeA) in a {
            guard let nodeB = b[id] else { return true }
            if nodeA.center != nodeB.center || nodeA.scale != nodeB.scale { return true }
        }
        return false
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 120.0, paused: !(isTimeDrivenFormation || isDancing))) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let appNodes = computeFormationLayout(time: time)
            let dancing = isDancing
            let danceK = CGFloat(0.35 + max(0.0, min(1.0, dockAnimationIntensity)) * 0.95)

            ZStack(alignment: .topLeading) {
                ForEach(Array(apps.enumerated()), id: \.element.id) { index, app in
                    let node = appNodes[app.id] ?? AppFormationNode(center: CGPoint(x: screenSize.width / 2, y: screenSize.height / 2), scale: 1.0)
                    let physOffset = computePhysicsOffset(for: index)
                    let dance = dancing ? DockAnimationEngine.dance(index: index, time: time, k: danceK) : .identity
                    let center = CGPoint(
                        x: node.center.x + physOffset.width + dance.offset.width,
                        y: node.center.y + physOffset.height + scrollOffsetY + dance.offset.height
                    )

                    AppleHomeAppTile(
                        app: app,
                        index: index,
                        itemCenter: center,
                        screenSize: screenSize,
                        iconSize: iconSize,
                        textSize: textSize,
                        showName: showName,
                        theme: theme,
                        tintColor: tintColor,
                        iconSnuggie: iconSnuggie,
                        physicsSimulation: physicsSimulation,
                        flamePhase: flamePhase,
                        wallpaperImage: wallpaperImage,
                        isEditing: isEditing,
                        wiggle: wiggle,
                        enableMagnification: enableMagnification,
                        hoverScale: maxMagnification,
                        isHovered: hoveredAppID == app.id,
                        isDragged: draggedAppID == app.id,
                        dragOffset: draggedAppID == app.id ? dragOffset : .zero,
                        isDropTarget: dragHoverTargetID == app.id && draggedAppID != app.id,
                        onLaunch: { onLaunch(app, center) },
                        onHide: { onHideApp(app) },
                        onShowInFinder: { onShowInFinder(app) },
                        onEnterEditMode: { onEnterEditMode() },
                        onHoverChanged: { isH in
                            withAnimation(.spring(response: 0.20, dampingFraction: 0.72)) {
                                if isH {
                                    hoveredAppID = app.id
                                } else if hoveredAppID == app.id {
                                    hoveredAppID = nil
                                }
                            }
                        },
                        onDragChanged: { offset in
                            draggedAppID = app.id
                            dragOffset = offset

                            let dragWorldPos = CGPoint(x: center.x + offset.width, y: center.y + offset.height)
                            var closestDist: CGFloat = iconSize * 1.2
                            var closestAppID: String? = nil

                            for (otherID, otherNode) in appNodes where otherID != app.id {
                                let dist = hypot(dragWorldPos.x - otherNode.center.x, dragWorldPos.y - otherNode.center.y)
                                if dist < closestDist {
                                    closestDist = dist
                                    closestAppID = otherID
                                }
                            }

                            if dragHoverTargetID != closestAppID {
                                dragHoverTargetID = closestAppID
                                if closestAppID != nil {
                                    HapticFeedback.tick()
                                }
                            }
                        },
                        onDragEnded: {
                            if let targetID = dragHoverTargetID, targetID != app.id {
                                HapticFeedback.selection()
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                                    onMoveApp(app.id, targetID)
                                }
                            }
                            withAnimation(.spring(response: 0.24, dampingFraction: 0.70)) {
                                draggedAppID = nil
                                dragOffset = .zero
                                dragHoverTargetID = nil
                            }
                        }
                    )
                    .rotationEffect(.degrees(dance.rotation))
                    .scaleEffect(node.scale * dance.scale)
                    .position(x: center.x, y: center.y + (nameHeight / 2.0))
                }
            }
        }
        .onChange(of: formation, initial: true) { _, _ in isTimeDrivenFormation = probeIsTimeDriven() }
        .onChange(of: apps.count) { _, _ in isTimeDrivenFormation = probeIsTimeDriven() }
        .onChange(of: pulseIntensity) { _, _ in isTimeDrivenFormation = probeIsTimeDriven() }
        .onChange(of: orbitSpeed) { _, _ in isTimeDrivenFormation = probeIsTimeDriven() }
    }

    private func computePhysicsOffset(for index: Int) -> CGSize {
        guard physicsSimulation != "None" else { return .zero }
        let i = Double(index)
        let p = physicsPhase * 2.0 * .pi

        switch physicsSimulation {
        case "Zero-G Float":
            let dx = sin(p + i * 0.75) * 5.0
            let dy = cos(p * 0.8 + i * 0.95) * 5.0
            return CGSize(width: dx, height: dy)

        case "Micro-Orbit":
            let angle = p * 1.2 + (i * 0.6)
            return CGSize(width: cos(angle) * 4.5, height: sin(angle) * 4.5)

        case "Harmonic Pulse":
            return CGSize(width: 0, height: sin(p * 2.0 + i * 0.4) * 4.0)

        case "Tidal Waves":
            return CGSize(width: 0, height: sin(p * 1.5 + i * 0.5) * 6.5)

        case "Quantum Jitter":
            let jx = sin(p * 5.0 + i * 2.3) * 2.0
            let jy = cos(p * 4.2 + i * 1.9) * 2.0
            return CGSize(width: jx, height: jy)

        case "Jelly Bounce 🍮":
            let seed = i * 0.73
            let bounceY = -abs(sin(p * 2.2 + seed)) * 12.0
            let bounceX = cos(p * 1.8 + seed) * 3.0
            return CGSize(width: bounceX, height: bounceY)

        case "Springy Trampoline 🤸":
            let seed = i * 0.55
            let sprY = sin(p * 3.0 + seed) * 10.0
            return CGSize(width: 0, height: sprY)

        case "Cosmic Anti-Gravity 🪐":
            let agX = sin(p * 0.7 + i * 0.4) * 8.0
            let agY = cos(p * 0.5 + i * 0.3) * 8.0
            return CGSize(width: agX, height: agY)

        case "Matrix Quantum Wave ⚡️":
            let qx = sin(p * 3.5 + i * 1.2) * 4.0
            let qy = sin(p * 2.0 + i * 0.8) * 8.0
            return CGSize(width: qx, height: qy)

        default:
            return .zero
        }
    }

    private func clampToScreen(_ point: CGPoint) -> CGPoint {
        let minX = sideMargin + (iconSize / 2.0)
        let maxX = max(minX, screenSize.width - sideMargin - (iconSize / 2.0))
        let minY = topClearance + (iconSize / 2.0)
        let maxY = max(minY, topClearance + usableHeight - (iconSize / 2.0))
        let clampedX = min(max(minX, point.x), maxX)
        let clampedY = min(max(minY, point.y), maxY)
        return CGPoint(
            x: clampedX.isFinite ? clampedX : screenSize.width / 2.0,
            y: clampedY.isFinite ? clampedY : screenSize.height / 2.0
        )
    }

    private func computeFormationLayout(time: Double) -> [String: AppFormationNode] {
        var nodes: [String: AppFormationNode] = [:]
        let count = apps.count
        guard count > 0 else { return nodes }

        let cx = screenSize.width / 2.0
        let cy = topClearance + (usableHeight / 2.0)
        let minClearance = iconSize + max(6.0, curSpacing)
        let safeSpeed = max(0.1, orbitSpeed)
        let safeIntensity = max(0.0, pulseIntensity)

        switch formation {
        case "Orbiting Border Ring 🔄", "Orbiting Border Ring", "Conveyor Belt Frame 🔁":
            // Apps travel continuously along the 4 borders of the screen with controllable speed & direction
            let marginX = sideMargin + (iconSize / 2.0) + 12.0
            let marginY = topClearance + (iconSize / 2.0) + 12.0
            let frameW = max(100.0, screenSize.width - (marginX * 2.0))
            let frameH = max(100.0, usableHeight - (iconSize + 24.0))
            let totalPerimeter = max(100.0, (frameW + frameH) * 2.0)
            let step = totalPerimeter / CGFloat(max(1, count))

            let directionMultiplier: Double = orbitClockwise ? 1.0 : -1.0
            let speedInPixelsPerSec = (Double(totalPerimeter) / 22.0) * safeSpeed
            let timeOffset = time * speedInPixelsPerSec * directionMultiplier

            for (i, app) in apps.enumerated() {
                var dist = CGFloat((Double(CGFloat(i) * step) + timeOffset + (Double(totalPerimeter) * 1000.0)).truncatingRemainder(dividingBy: Double(totalPerimeter)))
                if dist < 0 { dist += totalPerimeter }

                var px: CGFloat = 0
                var py: CGFloat = 0
                if dist < frameW {
                    // Top edge (left to right)
                    px = marginX + dist
                    py = marginY
                } else if dist < (frameW + frameH) {
                    // Right edge (top to bottom)
                    let d = dist - frameW
                    px = marginX + frameW
                    py = marginY + d
                } else if dist < ((frameW * 2.0) + frameH) {
                    // Bottom edge (right to left)
                    let d = dist - (frameW + frameH)
                    px = marginX + frameW - d
                    py = marginY + frameH
                } else {
                    // Left edge (bottom to top)
                    let d = dist - ((frameW * 2.0) + frameH)
                    px = marginX
                    py = marginY + frameH - d
                }
                nodes[app.id] = AppFormationNode(center: clampToScreen(CGPoint(x: px, y: py)), scale: 1.0)
            }

        case "Random Pulsing Bubbles 🫧", "Random Pulsing Bubbles", "Pulsing Bubbles 🫧", "Pulsing Bubbles":
            // Apps organically scale up and down with per-app randomized sine phase offsets
            let goldenAngle = 2.399963229728653
            for (i, app) in apps.enumerated() {
                let r = sqrt(Double(i) + 0.5) * Double(minClearance * 0.95)
                let theta = Double(i) * goldenAngle
                let phase = Double(i) * 1.6180339887 + sin(Double(i) * 3.14159) * 2.0
                let freq = 1.8 + Double(i % 5) * 0.25
                let pulse = sin(time * freq + phase)
                let dynamicScale = min(max(0.6, 1.0 + CGFloat(pulse * 0.25 * safeIntensity)), 1.8)

                let floatX = CGFloat(cos(time * 0.9 + phase) * 8.0 * safeIntensity)
                let floatY = CGFloat(sin(time * 1.1 + phase) * 8.0 * safeIntensity)
                let px = cx + CGFloat(cos(theta) * r) + floatX
                let py = cy + CGFloat(sin(theta) * r) + floatY
                nodes[app.id] = AppFormationNode(center: clampToScreen(CGPoint(x: px, y: py)), scale: dynamicScale)
            }

        case "Jelly Bulge 🍮", "Jelly Bulge", "Jelly Bounce 🍮":
            // Apps organically scale and wobble with jelly bulge physics
            let goldenAngle = 2.399963229728653
            for (i, app) in apps.enumerated() {
                let r = sqrt(Double(i) + 0.5) * Double(minClearance * 0.92)
                let theta = Double(i) * goldenAngle
                let phase = Double(i) * 1.6180339887 + sin(Double(i) * 2.7) * 1.8
                let freq = 2.4 + Double(i % 4) * 0.3
                let jellyPulse = sin(time * freq + phase) * 0.22 + cos(time * freq * 2.0 + phase) * 0.08
                let dynamicScale = min(max(0.6, 1.0 + CGFloat(jellyPulse * safeIntensity)), 1.8)

                let bulgeX = CGFloat(cos(time * 2.5 + phase) * 10.0 * safeIntensity)
                let bulgeY = CGFloat(sin(time * 3.0 + phase) * 12.0 * safeIntensity)
                let px = cx + CGFloat(cos(theta) * r) + bulgeX
                let py = cy + CGFloat(sin(theta) * r) + bulgeY
                nodes[app.id] = AppFormationNode(center: clampToScreen(CGPoint(x: px, y: py)), scale: dynamicScale)
            }

        case "Springy Trampoline 🤸", "Springy Trampoline":
            // Bouncy spring oscillations propagating across rows and columns
            let cols = max(4, Int(round(sqrt(Double(count) * Double(usableWidth / usableHeight)))))
            let rows = max(1, (count + cols - 1) / cols)
            let cellW = iconSize + curSpacing
            let cellH = iconSize + nameHeight + curSpacing
            let totalW = min(usableWidth, CGFloat(max(1, cols - 1)) * cellW)
            let totalH = min(usableHeight, CGFloat(max(1, rows - 1)) * cellH)
            let stepX = cols > 1 ? (totalW / CGFloat(cols - 1)) : 0
            let stepY = rows > 1 ? (totalH / CGFloat(rows - 1)) : 0
            let startX = cx - (totalW / 2.0)
            let startY = cy - (totalH / 2.0)

            for (i, app) in apps.enumerated() {
                let r = i / cols
                let c = i % cols
                let distFromCenter = hypot(Double(c) - Double(cols) / 2.0, Double(r) - Double(rows) / 2.0)
                let wave = sin(time * 4.5 - distFromCenter * 0.8)
                let springDecay = 1.0 + 0.3 * cos(time * 9.0 - distFromCenter * 1.6)
                let bounceY = CGFloat(wave * springDecay * 20.0 * safeIntensity)
                let bounceX = CGFloat(cos(time * 3.2 - Double(c) * 0.6) * 6.0 * safeIntensity)
                let dynamicScale = min(max(0.6, 1.0 + CGFloat(wave * 0.14 * safeIntensity)), 1.6)

                let px = startX + CGFloat(c) * stepX + bounceX
                let py = startY + CGFloat(r) * stepY + bounceY
                nodes[app.id] = AppFormationNode(center: clampToScreen(CGPoint(x: px, y: py)), scale: dynamicScale)
            }

        case "Floating Lotus Flower 🪷", "Floating Lotus Flower":
            // Blooming concentric lotus petal rings breathing and floating like water lilies
            let petals = 8
            let maxRadius = min(usableWidth, usableHeight) * 0.44
            for (i, app) in apps.enumerated() {
                let petalIdx = i % petals
                let ringIdx = i / petals
                let baseAngle = (Double(petalIdx) / Double(petals)) * 2.0 * .pi
                let bloom = 1.0 + 0.08 * sin(time * 1.4 + Double(ringIdx) * 0.5) * safeIntensity
                let rotDir = (ringIdx % 2 == 0) ? 1.0 : -1.0
                let ringRotation = time * 0.10 * rotDir * safeSpeed * (orbitClockwise ? 1.0 : -1.0)
                let angle = baseAngle + (Double(ringIdx) * 0.25) + ringRotation
                let ringRad = min(maxRadius, ((iconSize * 1.2) + CGFloat(ringIdx) * (minClearance * 0.95)) * CGFloat(bloom))
                let waterBob = sin(time * 1.6 + Double(i) * 0.3) * 6.0 * safeIntensity
                let px = cx + CGFloat(cos(angle)) * ringRad
                let py = cy + CGFloat(sin(angle)) * (ringRad * 0.78) + CGFloat(waterBob)
                let dynamicScale = min(max(0.6, 1.0 + CGFloat(sin(time * 1.8 + angle) * 0.08 * safeIntensity)), 1.5)
                nodes[app.id] = AppFormationNode(center: clampToScreen(CGPoint(x: px, y: py)), scale: dynamicScale)
            }

        case "Cyber Neon City Grid 🏙️", "Cyber Neon City Grid":
            // Futuristic perspective skyline with neon wave pulses across columns
            let cols = max(5, Int(round(sqrt(Double(count) * Double(usableWidth / usableHeight)))))
            let rows = max(1, (count + cols - 1) / cols)
            let cellW = iconSize + curSpacing
            let cellH = iconSize + nameHeight + curSpacing
            let totalW = min(usableWidth, CGFloat(max(1, cols - 1)) * cellW)
            let totalH = min(usableHeight, CGFloat(max(1, rows - 1)) * cellH)
            let stepX = cols > 1 ? (totalW / CGFloat(cols - 1)) : 0
            let stepY = rows > 1 ? (totalH / CGFloat(rows - 1)) : 0
            let startX = cx - (totalW / 2.0)
            let startY = cy - (totalH / 2.0)

            for (i, app) in apps.enumerated() {
                let r = i / cols
                let c = i % cols
                let towerOffset = sin(Double(c) * 1.4) * 22.0
                let neonPulse = sin(time * 3.5 - Double(c) * 0.75 + Double(r) * 0.4) * 16.0 * safeIntensity
                let px = startX + CGFloat(c) * stepX
                let py = startY + CGFloat(r) * stepY + CGFloat(towerOffset + neonPulse)
                let dynamicScale = min(max(0.6, 1.0 + CGFloat(sin(time * 2.8 - Double(c) * 0.6) * 0.10 * safeIntensity)), 1.5)
                nodes[app.id] = AppFormationNode(center: clampToScreen(CGPoint(x: px, y: py)), scale: dynamicScale)
            }

        case "Hyperspace Star Gate 🌌", "Hyperspace Star Gate":
            // Concentric relativistic stargate warp rings expanding with exponential depth
            for (i, app) in apps.enumerated() {
                let ring = (i / 6) + 1
                let inRing = i % 6
                let warpPhase = (time * 0.45 * safeSpeed + Double(ring) * 0.25).truncatingRemainder(dividingBy: 1.0)
                let rBase = CGFloat(ring) * (minClearance * 0.85)
                let rWarp = rBase * CGFloat(1.0 + warpPhase * 0.32 * safeIntensity)
                let speed = (1.4 / Double(ring)) * safeSpeed * (orbitClockwise ? 1.0 : -1.0)
                let angle = (Double(inRing) / 6.0) * 2.0 * .pi + time * speed
                let px = cx + CGFloat(cos(angle)) * rWarp
                let py = cy + CGFloat(sin(angle)) * (rWarp * 0.8)
                let dynamicScale = min(max(0.6, CGFloat(0.85 + warpPhase * 0.35 * safeIntensity)), 1.8)
                nodes[app.id] = AppFormationNode(center: clampToScreen(CGPoint(x: px, y: py)), scale: dynamicScale)
            }

        case "Floating Island Clusters 🏝️", "Floating Island Clusters":
            // 4 archipelago island clusters gently floating and bobbing in the sky
            let clusters = 4
            let perCluster = max(1, (count + clusters - 1) / clusters)
            let clusterSpreadX = min(usableWidth * 0.24, minClearance * 1.8)
            let clusterSpreadY = min(usableHeight * 0.20, minClearance * 1.4)
            let islandCenters: [CGPoint] = [
                CGPoint(x: cx - clusterSpreadX, y: cy - clusterSpreadY),
                CGPoint(x: cx + clusterSpreadX, y: cy - clusterSpreadY),
                CGPoint(x: cx - clusterSpreadX, y: cy + clusterSpreadY),
                CGPoint(x: cx + clusterSpreadX, y: cy + clusterSpreadY)
            ]
            for (i, app) in apps.enumerated() {
                let cIdx = min(clusters - 1, i / perCluster)
                let localIdx = i % perCluster
                let ic = islandCenters[cIdx]
                let clusterBob = sin(time * 1.2 + Double(cIdx) * 1.5) * 14.0 * safeIntensity
                let clusterDrift = cos(time * 0.8 + Double(cIdx) * 2.1) * 8.0 * safeIntensity
                let angle = (Double(localIdx) / Double(perCluster)) * 2.0 * .pi
                let rad = minClearance * 0.9 * CGFloat(1 + (localIdx / 6))
                let appFloat = sin(time * 2.0 + Double(i) * 0.8) * 4.0 * safeIntensity
                let px = ic.x + CGFloat(clusterDrift) + CGFloat(cos(angle)) * rad
                let py = ic.y + CGFloat(clusterBob) + CGFloat(sin(angle)) * rad + CGFloat(appFloat)
                let dynamicScale = min(max(0.6, 1.0 + CGFloat(sin(time * 1.5 + Double(i) * 0.7) * 0.08 * safeIntensity)), 1.5)
                nodes[app.id] = AppFormationNode(center: clampToScreen(CGPoint(x: px, y: py)), scale: dynamicScale)
            }

        case "Rectangular Frame 🔲", "Rectangular Frame", "Rectangular Perimeter":
            let margin = max(16.0, (64.0 - curSpacing) * 1.5)
            let marginX = sideMargin + (iconSize / 2) + margin
            let marginY = topClearance + (iconSize / 2) + margin
            let frameW = max(100.0, screenSize.width - (marginX * 2.0))
            let frameH = max(100.0, usableHeight - (iconSize + 24.0) - (margin * 1.2))
            let totalPerimeter = max(100.0, (frameW + frameH) * 2.0)
            let step = totalPerimeter / CGFloat(max(1, count))

            for (i, app) in apps.enumerated() {
                let dist = CGFloat(i) * step
                var px: CGFloat = 0
                var py: CGFloat = 0
                if dist < frameW {
                    px = marginX + dist
                    py = marginY
                } else if dist < (frameW + frameH) {
                    let d = dist - frameW
                    px = marginX + frameW
                    py = marginY + d
                } else if dist < ((frameW * 2.0) + frameH) {
                    let d = dist - (frameW + frameH)
                    px = marginX + frameW - d
                    py = marginY + frameH
                } else {
                    let d = dist - ((frameW * 2.0) + frameH)
                    px = marginX
                    py = marginY + frameH - d
                }
                nodes[app.id] = AppFormationNode(center: clampToScreen(CGPoint(x: px, y: py)), scale: 1.0)
            }

        case "Center Monolith Box ⏹️", "Center Monolith Box", "Centered Box":
            let cols = max(3, min(8, Int(ceil(sqrt(Double(count) * 1.3)))))
            let rows = max(1, (count + cols - 1) / cols)
            let cellW = minClearance * 1.05
            let cellH = minClearance * 1.05
            let totalW = CGFloat(cols) * cellW
            let totalH = CGFloat(rows) * cellH
            let startX = cx - (totalW / 2.0) + (cellW / 2.0)
            let startY = cy - (totalH / 2.0) + (cellH / 2.0)

            for (i, app) in apps.enumerated() {
                let r = i / cols
                let c = i % cols
                let px = startX + CGFloat(c) * cellW
                let py = startY + CGFloat(r) * cellH
                nodes[app.id] = AppFormationNode(center: clampToScreen(CGPoint(x: px, y: py)), scale: 1.0)
            }

        case "Golden Rectangle 📐", "Golden Rectangle":
            let goldenRatio: CGFloat = 16.0 / 9.0
            let rawCols = max(4, Int(round(sqrt(Double(count) * Double(goldenRatio)))))
            let cols = min(rawCols, count)
            let rows = max(1, (count + cols - 1) / cols)
            let cellW = minClearance * 1.06
            let cellH = minClearance * 1.06
            let totalW = CGFloat(cols) * cellW
            let totalH = CGFloat(rows) * cellH
            let startX = cx - (totalW / 2.0) + (cellW / 2.0)
            let startY = cy - (totalH / 2.0) + (cellH / 2.0)

            for (i, app) in apps.enumerated() {
                let r = i / cols
                let c = i % cols
                let px = startX + CGFloat(c) * cellW
                let py = startY + CGFloat(r) * cellH
                nodes[app.id] = AppFormationNode(center: clampToScreen(CGPoint(x: px, y: py)), scale: 1.0)
            }

        case "Dual Column Grid 📑", "Dual Column Grid":
            let half = (count + 1) / 2
            let leftCols = 2
            let rightCols = 2
            for (i, app) in apps.enumerated() {
                if i < half {
                    let col = i % leftCols
                    let row = i / leftCols
                    let px = sideMargin + 36.0 + CGFloat(col) * minClearance
                    let py = topClearance + 30.0 + CGFloat(row) * minClearance
                    nodes[app.id] = AppFormationNode(center: clampToScreen(CGPoint(x: px, y: py)), scale: 1.0)
                } else {
                    let rIdx = i - half
                    let col = rIdx % rightCols
                    let row = rIdx / rightCols
                    let px = screenSize.width - sideMargin - 36.0 - CGFloat(1 - col) * minClearance
                    let py = topClearance + 30.0 + CGFloat(row) * minClearance
                    nodes[app.id] = AppFormationNode(center: clampToScreen(CGPoint(x: px, y: py)), scale: 1.0)
                }
            }

        case "Bottom Shelf & Active Desktop 🖥️", "Bottom Shelf & Active Desktop", "Bottom App Shelf":
            let colWidth = max(56.0, iconSize + curSpacing)
            let rowHeight = iconSize + (showName ? nameHeight + 6.0 : 0.0) + curSpacing
            let maxCols = max(6, Int(floor(usableWidth / colWidth)))
            let totalRows = max(1, (count + maxCols - 1) / maxCols)
            let maxShelfH = min(usableHeight * 0.42, CGFloat(totalRows) * rowHeight)
            let actualRowStep = totalRows > 1 ? min(rowHeight, maxShelfH / CGFloat(totalRows)) : rowHeight
            let startY = (topClearance + usableHeight) - (CGFloat(totalRows) * actualRowStep) + (actualRowStep * 0.5) - 8.0

            for (i, app) in apps.enumerated() {
                let row = i / maxCols
                let col = i % maxCols
                let itemsInThisRow = min(count - (row * maxCols), maxCols)
                let rowWidth = CGFloat(itemsInThisRow) * colWidth
                let startX = cx - (rowWidth / 2.0) + (colWidth / 2.0)
                let px = startX + CGFloat(col) * colWidth
                let py = startY + CGFloat(row) * actualRowStep
                nodes[app.id] = AppFormationNode(center: clampToScreen(CGPoint(x: px, y: py)), scale: 1.0)
            }

        case "Halfpipe Arc 🛹", "Halfpipe Arc":
            let totalSpan = min(usableWidth, CGFloat(max(1, count - 1)) * (iconSize + curSpacing))
            let stepX = totalSpan / CGFloat(max(1, count - 1))
            let startX = cx - (totalSpan / 2.0)
            for (i, app) in apps.enumerated() {
                let frac = (CGFloat(i) / CGFloat(max(1, count - 1))) * 2.0 - 1.0
                let px = startX + CGFloat(i) * stepX
                let uCurve = pow(frac, 2.0)
                let py = cy + (usableHeight * 0.35) - (uCurve * (usableHeight * 0.65))
                nodes[app.id] = AppFormationNode(center: clampToScreen(CGPoint(x: px, y: py)), scale: 1.0)
            }

        case "Dolphin Breach Arc 🐬", "Dolphin Breach Arc":
            let totalSpan = min(usableWidth, CGFloat(max(1, count - 1)) * (iconSize + curSpacing))
            let stepX = totalSpan / CGFloat(max(1, count - 1))
            let startX = cx - (totalSpan / 2.0)
            for (i, app) in apps.enumerated() {
                let frac = (CGFloat(i) / CGFloat(max(1, count - 1))) * .pi
                let px = startX + CGFloat(i) * stepX
                let arch = sin(frac)
                let py = cy + (usableHeight * 0.32) - (arch * (usableHeight * 0.60))
                nodes[app.id] = AppFormationNode(center: clampToScreen(CGPoint(x: px, y: py)), scale: 1.0)
            }

        case "Reef Vortex 🐠", "Reef Vortex":
            let goldenAngle = 2.39996322972865332
            let maxRad = min(min(usableWidth, usableHeight) * 0.46, CGFloat(count) * (minClearance * 0.16) + (minClearance * 1.1))
            for (i, app) in apps.enumerated() {
                let t = Double(i) / Double(max(1, count))
                let angle = Double(i) * goldenAngle
                let rad = CGFloat(sqrt(t)) * maxRad
                let px = cx + CGFloat(cos(angle)) * rad
                let py = cy + CGFloat(sin(angle)) * rad
                nodes[app.id] = AppFormationNode(center: clampToScreen(CGPoint(x: px, y: py)), scale: 1.0)
            }

        case "Left Column Dock ◀️":
            let colWidth = minClearance
            let maxRows = max(1, Int(floor(usableHeight / minClearance)))
            for (i, app) in apps.enumerated() {
                let col = i / maxRows
                let row = i % maxRows
                let px = sideMargin + (iconSize / 2) + CGFloat(col) * colWidth + 24
                let py = topClearance + (iconSize / 2) + CGFloat(row) * minClearance + 20
                nodes[app.id] = AppFormationNode(center: clampToScreen(CGPoint(x: px, y: py)), scale: 1.0)
            }

        case "Right Column Dock ▶️":
            let colWidth = minClearance
            let maxRows = max(1, Int(floor(usableHeight / minClearance)))
            for (i, app) in apps.enumerated() {
                let col = i / maxRows
                let row = i % maxRows
                let px = screenSize.width - sideMargin - (iconSize / 2) - CGFloat(col) * colWidth - 24
                let py = topClearance + (iconSize / 2) + CGFloat(row) * minClearance + 20
                nodes[app.id] = AppFormationNode(center: clampToScreen(CGPoint(x: px, y: py)), scale: 1.0)
            }

        case "Four Corners Quad ⊞":
            let perCorner = max(1, (count + 3) / 4)
            let cornerCols = max(2, Int(ceil(sqrt(Double(perCorner)))))
            for (i, app) in apps.enumerated() {
                let cornerIdx = i / perCorner
                let localIdx = i % perCorner
                let col = localIdx % cornerCols
                let row = localIdx / cornerCols

                var px: CGFloat = 0, py: CGFloat = 0
                switch cornerIdx {
                case 0:
                    px = sideMargin + 30 + CGFloat(col) * minClearance
                    py = topClearance + 30 + CGFloat(row) * minClearance
                case 1:
                    px = screenSize.width - sideMargin - 30 - CGFloat(col) * minClearance
                    py = topClearance + 30 + CGFloat(row) * minClearance
                case 2:
                    px = sideMargin + 30 + CGFloat(col) * minClearance
                    py = screenSize.height - 50 - CGFloat(row) * minClearance
                default:
                    px = screenSize.width - sideMargin - 30 - CGFloat(col) * minClearance
                    py = screenSize.height - 50 - CGFloat(row) * minClearance
                }
                nodes[app.id] = AppFormationNode(center: clampToScreen(CGPoint(x: px, y: py)), scale: 1.0)
            }

        case "Dual Flank Wings 🪽":
            let half = (count + 1) / 2
            let maxRows = max(1, Int(floor(usableHeight / minClearance)))
            for (i, app) in apps.enumerated() {
                if i < half {
                    let col = i / maxRows
                    let row = i % maxRows
                    let px = sideMargin + 32 + CGFloat(col) * minClearance
                    let py = topClearance + 30 + CGFloat(row) * minClearance
                    nodes[app.id] = AppFormationNode(center: clampToScreen(CGPoint(x: px, y: py)), scale: 1.0)
                } else {
                    let rIdx = i - half
                    let col = rIdx / maxRows
                    let row = rIdx % maxRows
                    let px = screenSize.width - sideMargin - 32 - CGFloat(col) * minClearance
                    let py = topClearance + 30 + CGFloat(row) * minClearance
                    nodes[app.id] = AppFormationNode(center: clampToScreen(CGPoint(x: px, y: py)), scale: 1.0)
                }
            }

        case "Top Horizon Bar ⬆️":
            let maxCols = max(1, Int(floor(usableWidth / minClearance)))
            for (i, app) in apps.enumerated() {
                let row = i / maxCols
                let col = i % maxCols
                let px = sideMargin + (usableWidth / 2) + (CGFloat(col) - CGFloat(min(count, maxCols)) / 2) * minClearance + (minClearance / 2)
                let py = topClearance + 40 + CGFloat(row) * minClearance
                nodes[app.id] = AppFormationNode(center: clampToScreen(CGPoint(x: px, y: py)), scale: 1.0)
            }

        case "Bottom Dock Arc ⬇️":
            let arcSpan = min(usableWidth * 0.85, CGFloat(count) * minClearance)
            let step = arcSpan / CGFloat(max(1, count - 1))
            let startX = cx - (arcSpan / 2)
            for (i, app) in apps.enumerated() {
                let px = startX + CGFloat(i) * step
                let norm = (CGFloat(i) / CGFloat(max(1, count - 1))) * 2.0 - 1.0
                let py = screenSize.height - 70 - (1.0 - (norm * norm)) * 40.0
                nodes[app.id] = AppFormationNode(center: clampToScreen(CGPoint(x: px, y: py)), scale: 1.0)
            }

        case "Fibonacci Galaxy 🌀":
            let goldenAngle = 2.399963229728653
            for (i, app) in apps.enumerated() {
                let r = sqrt(Double(i) + 0.5) * Double(minClearance * 0.88)
                let theta = Double(i) * goldenAngle
                let px = cx + CGFloat(cos(theta) * r)
                let py = cy + CGFloat(sin(theta) * r)
                nodes[app.id] = AppFormationNode(center: clampToScreen(CGPoint(x: px, y: py)), scale: 1.0)
            }

        case "DNA Double Helix 🧬":
            let strandCount = count
            let desiredStepY = iconSize + curSpacing
            let maxStepY = (usableHeight * 0.82) / CGFloat(max(1, (strandCount / 2)))
            let stepY = min(maxStepY, desiredStepY)
            let totalH = CGFloat(max(1, (strandCount / 2) - 1)) * stepY
            let startY = cy - (totalH / 2.0)
            let radius = min(usableWidth * 0.32, minClearance * 2.2)

            for (i, app) in apps.enumerated() {
                let strand = i % 2
                let pairIdx = i / 2
                let angle = Double(pairIdx) * 0.52 + (strand == 0 ? 0 : .pi)
                let px = cx + CGFloat(cos(angle)) * radius
                let py = startY + CGFloat(pairIdx) * stepY
                nodes[app.id] = AppFormationNode(center: clampToScreen(CGPoint(x: px, y: py)), scale: 1.0)
            }

        case "Cyber Vortex 🌪️":
            let maxRad = min(usableWidth * 0.44, CGFloat(count) * (minClearance * 0.18) + (minClearance * 1.2))
            for (i, app) in apps.enumerated() {
                let progress = Double(i) / Double(max(1, count))
                let r = maxRad * CGFloat(1.0 - progress * 0.75)
                let angle = progress * 6.0 * .pi
                let px = cx + CGFloat(cos(angle)) * r
                let py = cy + CGFloat(sin(angle)) * r
                nodes[app.id] = AppFormationNode(center: clampToScreen(CGPoint(x: px, y: py)), scale: 1.0)
            }

        case "Kaleidoscope Prism 🔮":
            let axes = 6
            for (i, app) in apps.enumerated() {
                let axis = i % axes
                let ring = (i / axes) + 1
                let angle = Double(axis) * (2.0 * .pi / Double(axes))
                let r = CGFloat(ring) * (minClearance * 0.95)
                let px = cx + CGFloat(cos(angle)) * r
                let py = cy + CGFloat(sin(angle)) * r
                nodes[app.id] = AppFormationNode(center: clampToScreen(CGPoint(x: px, y: py)), scale: 1.0)
            }

        case "Heart Cluster ❤️":
            let maxRadius = min(min(usableWidth * 0.40, usableHeight * 0.40), CGFloat(count) * (minClearance * 0.18) + (minClearance * 1.8)) / 16.0
            for (i, app) in apps.enumerated() {
                let t = (Double(i) / Double(max(1, count))) * 2.0 * .pi - (.pi / 2.0)
                let hx = 16.0 * pow(sin(t), 3.0)
                let hy = -(13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))
                let px = cx + CGFloat(hx) * maxRadius
                let py = cy + CGFloat(hy) * maxRadius + (usableHeight * 0.04)
                nodes[app.id] = AppFormationNode(center: clampToScreen(CGPoint(x: px, y: py)), scale: 1.0)
            }

        case "Solar System Orbit 🪐", "Orbital System 🪐":
            var remaining = count
            var ringIdx = 0
            var assigned = 0

            while remaining > 0 && assigned < count {
                let ringRadius = (iconSize * 1.5) + CGFloat(ringIdx) * (iconSize + curSpacing + 18.0)
                let circumference = 2.0 * .pi * Double(ringRadius)
                let maxAppsInRing = max(4, Int(floor(circumference / Double(minClearance))))
                let appsInThisRing = min(remaining, maxAppsInRing)

                for i in 0..<appsInThisRing {
                    guard assigned < count else { break }
                    let angle = (Double(i) / Double(max(1, appsInThisRing))) * 2.0 * .pi + (Double(ringIdx) * 0.45)
                    let px = cx + CGFloat(cos(angle)) * ringRadius
                    let py = cy + CGFloat(sin(angle)) * ringRadius
                    nodes[apps[assigned].id] = AppFormationNode(center: clampToScreen(CGPoint(x: px, y: py)), scale: 1.0)
                    assigned += 1
                }
                remaining -= appsInThisRing
                ringIdx += 1
            }

        case "Diamond Lattice 💎":
            var remaining = count
            var tier = 1
            var assigned = 0

            while remaining > 0 && assigned < count {
                let tierStepX = CGFloat(tier) * (minClearance * 0.9)
                let tierStepY = CGFloat(tier) * (minClearance * 0.9)
                let perimeter = tier * 4
                let appsInTier = min(remaining, perimeter)

                for i in 0..<appsInTier {
                    guard assigned < count else { break }
                    let frac = (Double(i) / Double(max(1, appsInTier))) * 4.0
                    let quad = Int(frac)
                    let sub = CGFloat(frac.truncatingRemainder(dividingBy: 1.0))
                    var px = cx, py = cy
                    switch quad {
                    case 0: px = cx + (1.0 - sub) * tierStepX; py = cy - sub * tierStepY
                    case 1: px = cx - sub * tierStepX; py = cy - (1.0 - sub) * tierStepY
                    case 2: px = cx - (1.0 - sub) * tierStepX; py = cy + sub * tierStepY
                    default: px = cx + sub * tierStepX; py = cy + (1.0 - sub) * tierStepY
                    }
                    nodes[apps[assigned].id] = AppFormationNode(center: clampToScreen(CGPoint(x: px, y: py)), scale: 1.0)
                    assigned += 1
                }
                remaining -= appsInTier
                tier += 1
            }

        case "Honeycomb Lattice ⬡":
            let cols = max(6, Int(round(sqrt(Double(count) * Double(usableWidth / usableHeight)))))
            let cellW = iconSize + curSpacing
            let cellH = iconSize + nameHeight + curSpacing
            let rows = max(1, Int(ceil(Double(count) / Double(cols))))
            let startX = sideMargin + max(0, (usableWidth - (CGFloat(cols) * cellW)) / 2.0)
            let startY = topClearance + max(0, (usableHeight - (CGFloat(rows) * cellH)) / 2.0)

            for (i, app) in apps.enumerated() {
                let r = i / cols
                let c = i % cols
                let hexOffset = (r % 2 == 1) ? (cellW * 0.5) : 0.0
                let px = startX + CGFloat(c) * cellW + hexOffset + (iconSize / 2)
                let py = startY + CGFloat(r) * cellH + (iconSize / 2)
                nodes[app.id] = AppFormationNode(center: clampToScreen(CGPoint(x: px, y: py)), scale: 1.0)
            }

        case "Stellar Wave 🌊":
            let cols = max(5, Int(round(sqrt(Double(count) * Double(usableWidth / usableHeight)))))
            let rows = max(1, Int(ceil(Double(count) / Double(cols))))
            let cellW = iconSize + curSpacing
            let cellH = iconSize + nameHeight + curSpacing
            let totalW = min(usableWidth, CGFloat(max(1, cols - 1)) * cellW)
            let totalH = min(usableHeight, CGFloat(max(1, rows - 1)) * cellH)
            let stepX = cols > 1 ? (totalW / CGFloat(cols - 1)) : 0
            let stepY = rows > 1 ? (totalH / CGFloat(rows - 1)) : 0
            let startX = cx - (totalW / 2.0)
            let startY = cy - (totalH / 2.0)
            let amplitude: CGFloat = min(28.0, max(8.0, curSpacing * 0.5))

            for (i, app) in apps.enumerated() {
                let r = i / cols
                let c = i % cols
                let px = startX + CGFloat(c) * stepX
                let waveAngle: Double = Double(c) * 0.85 + Double(r) * 1.2
                let waveY: Double = sin(waveAngle) * Double(amplitude)
                let py = startY + CGFloat(r) * stepY + CGFloat(waveY)
                nodes[app.id] = AppFormationNode(center: clampToScreen(CGPoint(x: px, y: py)), scale: 1.0)
            }

        case "Spiral Nautilus 🐚":
            for (i, app) in apps.enumerated() {
                let angle = Double(i) * 0.48
                let radius = (iconSize * 0.8) + CGFloat(pow(Double(i), 1.15)) * (minClearance * 0.38)
                let px = cx + CGFloat(cos(angle)) * radius
                let py = cy + CGFloat(sin(angle)) * radius
                nodes[app.id] = AppFormationNode(center: clampToScreen(CGPoint(x: px, y: py)), scale: 1.0)
            }

        case "Hourglass Infinity ⏳":
            let scaleX = min(usableWidth * 0.38, CGFloat(count) * (minClearance * 0.16) + (minClearance * 1.3))
            let scaleY = min(usableHeight * 0.34, scaleX * 0.85)
            for (i, app) in apps.enumerated() {
                let t = (Double(i) / Double(max(1, count))) * 2.0 * .pi
                let px = cx + CGFloat(sin(t)) * scaleX
                let py = cy + CGFloat(sin(t * 2.0)) * scaleY
                nodes[app.id] = AppFormationNode(center: clampToScreen(CGPoint(x: px, y: py)), scale: 1.0)
            }

        case "Pyramid Monolith 🏛️":
            var remaining = count
            var level = 1
            var assigned = 0
            while remaining > 0 && assigned < count {
                let inLevel = min(remaining, level * 2 - 1)
                let rowWidth = CGFloat(inLevel) * minClearance
                let startX = cx - (rowWidth / 2.0) + (minClearance / 2.0)
                let py = topClearance + 50.0 + CGFloat(level - 1) * (minClearance * 0.92)
                for i in 0..<inLevel {
                    guard assigned < count else { break }
                    let px = startX + CGFloat(i) * minClearance
                    nodes[apps[assigned].id] = AppFormationNode(center: clampToScreen(CGPoint(x: px, y: py)), scale: 1.0)
                    assigned += 1
                }
                remaining -= inLevel
                level += 1
            }

        case "Crescent Moon 🌙":
            let r = min(min(usableWidth, usableHeight) * 0.44, CGFloat(count) * (minClearance * 0.18) + (minClearance * 1.2))
            for (i, app) in apps.enumerated() {
                let denom: Double = Double(max(1, count - 1))
                let ratio: Double = Double(i) / denom
                let frac: Double = ratio * (.pi * 1.3) - 0.45
                let px = cx + CGFloat(cos(frac)) * r
                let py = cy + CGFloat(sin(frac)) * r
                nodes[app.id] = AppFormationNode(center: clampToScreen(CGPoint(x: px, y: py)), scale: 1.0)
            }

        case "Supernova Burst 💥":
            for (i, app) in apps.enumerated() {
                let spoke = i % 8
                let step = i / 8
                let angle = (Double(spoke) / 8.0) * 2.0 * .pi
                let r = (iconSize * 1.4) + CGFloat(step) * (minClearance * 1.05)
                let px = cx + CGFloat(cos(angle)) * r
                let py = cy + CGFloat(sin(angle)) * r
                nodes[app.id] = AppFormationNode(center: clampToScreen(CGPoint(x: px, y: py)), scale: 1.0)
            }

        case "Tesseract Hypercube 🧊":
            let innerScale = min(usableWidth * 0.22, CGFloat(count) * (minClearance * 0.08) + (minClearance * 0.8))
            let outerScale = min(min(usableWidth, usableHeight) * 0.44, innerScale * 1.9)
            for (i, app) in apps.enumerated() {
                let isInner = (i % 2 == 0)
                let frac = (Double(i) / Double(max(1, count))) * 2.0 * .pi
                let scale = isInner ? innerScale : outerScale
                let px = cx + CGFloat(cos(frac)) * scale
                let py = cy + CGFloat(sin(frac)) * (scale * 0.65)
                nodes[app.id] = AppFormationNode(center: clampToScreen(CGPoint(x: px, y: py)), scale: 1.0)
            }

        case "Zen Garden Yin-Yang ☯️":
            let yinRadius = min(min(usableWidth, usableHeight) * 0.42, CGFloat(count) * (minClearance * 0.14) + (minClearance * 1.2))
            for (i, app) in apps.enumerated() {
                let isYin = (i < count / 2)
                let subIdx = isYin ? i : (i - count / 2)
                let subCount = max(1, count / 2)
                let frac = Double(subIdx) / Double(subCount)
                let angle = isYin ? (frac * .pi) : (frac * .pi + .pi)
                let r = CGFloat(sqrt(frac)) * yinRadius
                let px = cx + CGFloat(cos(angle)) * r
                let py = cy + CGFloat(sin(angle)) * r
                nodes[app.id] = AppFormationNode(center: clampToScreen(CGPoint(x: px, y: py)), scale: 1.0)
            }

        case "Simple Square ⏹️", "Simple Square", "Square ⏹️":
            // Geometric perfect square grid where columns = rows = sqrt(count)
            let nameH = showName ? (textSize + 8.0) : 0.0
            let side = max(2, Int(ceil(sqrt(Double(count)))))
            let cols = side
            let rows = side
            let effectiveSpacing = max(6.0, curSpacing)
            let cellW = iconSize + effectiveSpacing
            let cellH = iconSize + nameH + effectiveSpacing

            let totalW = CGFloat(cols) * cellW - effectiveSpacing
            let totalH = CGFloat(rows) * cellH - effectiveSpacing
            let startX = (screenSize.width - totalW) / 2.0
            let startY = topClearance + max(16.0, (usableHeight - totalH) / 2.0)

            for (i, app) in apps.enumerated() {
                let r = i / cols
                let c = i % cols
                let px = startX + (iconSize / 2.0) + CGFloat(c) * cellW
                let py = startY + (iconSize / 2.0) + CGFloat(r) * cellH
                nodes[app.id] = AppFormationNode(center: clampToScreen(CGPoint(x: px, y: py)), scale: 1.0)
            }

        case "Simple Circle ⭕️", "Simple Circle", "Circle ⭕️":
            // Pure geometric circle where radius and circumference spacing directly scale with curSpacing
            let spacing = max(8.0, curSpacing)
            if count <= 24 {
                let desiredRadius = (CGFloat(count) * (iconSize + spacing)) / (2.0 * .pi)
                let maxRadius = min(usableWidth, usableHeight) * 0.46
                let radius = min(maxRadius, max(iconSize * 1.5, desiredRadius))
                let angleStep = (2.0 * .pi) / Double(max(1, count))

                for (i, app) in apps.enumerated() {
                    let angle = Double(i) * angleStep - (.pi / 2.0)
                    let px = cx + CGFloat(cos(angle)) * radius
                    let py = cy + CGFloat(sin(angle)) * radius
                    nodes[app.id] = AppFormationNode(center: clampToScreen(CGPoint(x: px, y: py)), scale: 1.0)
                }
            } else {
                var appIdx = 0
                var ring = 1
                while appIdx < count {
                    let ringRadius = CGFloat(ring) * (iconSize + spacing) * 0.82
                    let perimeter = 2.0 * .pi * ringRadius
                    let ringCapacity = max(6, Int(perimeter / (iconSize + spacing)))
                    let ringApps = min(count - appIdx, ringCapacity)
                    let angleStep = (2.0 * .pi) / Double(max(1, ringApps))

                    for j in 0..<ringApps {
                        let i = appIdx + j
                        let app = apps[i]
                        let angle = Double(j) * angleStep - (.pi / 2.0) + (Double(ring) * 0.22)
                        let px = cx + CGFloat(cos(angle)) * ringRadius
                        let py = cy + CGFloat(sin(angle)) * ringRadius
                        nodes[app.id] = AppFormationNode(center: clampToScreen(CGPoint(x: px, y: py)), scale: 1.0)
                    }
                    appIdx += ringApps
                    ring += 1
                }
            }

        case "Simple Triangle 🔺", "Simple Triangle", "Triangle 🔺":
            // Symmetrical pyramid triangle where each row r has (r + 1) items
            let nameH = showName ? (textSize + 8.0) : 0.0
            let spacing = max(6.0, curSpacing)
            let stepX = iconSize + spacing
            let stepY = iconSize + nameH + spacing

            var totalCapacity = 0
            var totalPyramidRows = 1
            while totalCapacity < count {
                totalCapacity += totalPyramidRows
                if totalCapacity >= count { break }
                totalPyramidRows += 1
            }

            let totalPyramidH = CGFloat(totalPyramidRows) * stepY
            let topApexY = topClearance + max(20.0, (usableHeight - totalPyramidH) / 2.0)

            var currentApp = 0
            for r in 0..<totalPyramidRows {
                let itemsInRow = min(r + 1, count - currentApp)
                if itemsInRow <= 0 { break }
                let rowW = CGFloat(itemsInRow - 1) * stepX
                let rowStartX = cx - (rowW / 2.0)
                let rowY = topApexY + (iconSize / 2.0) + CGFloat(r) * stepY

                for c in 0..<itemsInRow {
                    let app = apps[currentApp]
                    let px = rowStartX + CGFloat(c) * stepX
                    nodes[app.id] = AppFormationNode(center: clampToScreen(CGPoint(x: px, y: rowY)), scale: 1.0)
                    currentApp += 1
                }
            }

        case "Left Rail Train 🚂":
            // Continuous infinite train of applications traveling along the left screen border
            let railX = sideMargin + (iconSize / 2.0)
            let trackLength = max(100.0, usableHeight)
            let spacing = max(iconSize + 14.0, curSpacing + iconSize)
            let trainSpeed = 48.0 * safeSpeed * (orbitClockwise ? 1.0 : -1.0)

            for (i, app) in apps.enumerated() {
                let rawDist = Double(CGFloat(i) * spacing) + (time * trainSpeed)
                var dist = CGFloat(rawDist.truncatingRemainder(dividingBy: Double(trackLength)))
                if dist < 0 { dist += trackLength }
                let py = topClearance + dist
                nodes[app.id] = AppFormationNode(center: clampToScreen(CGPoint(x: railX, y: py)), scale: 1.0)
            }

        case "Right Rail Train 🚂":
            // Continuous infinite train of applications traveling along the right screen border
            let railX = screenSize.width - sideMargin - (iconSize / 2.0)
            let trackLength = max(100.0, usableHeight)
            let spacing = max(iconSize + 14.0, curSpacing + iconSize)
            let trainSpeed = 48.0 * safeSpeed * (orbitClockwise ? 1.0 : -1.0)

            for (i, app) in apps.enumerated() {
                let rawDist = Double(CGFloat(i) * spacing) + (time * trainSpeed)
                var dist = CGFloat(rawDist.truncatingRemainder(dividingBy: Double(trackLength)))
                if dist < 0 { dist += trackLength }
                let py = topClearance + dist
                nodes[app.id] = AppFormationNode(center: clampToScreen(CGPoint(x: railX, y: py)), scale: 1.0)
            }

        case "Top Horizon Train 🚂":
            // Continuous infinite train of applications traveling horizontally beneath the menu bar
            let railY = topClearance + (iconSize / 2.0) + 6.0
            let trackLength = max(100.0, usableWidth)
            let spacing = max(iconSize + 14.0, curSpacing + iconSize)
            let trainSpeed = 52.0 * safeSpeed * (orbitClockwise ? 1.0 : -1.0)

            for (i, app) in apps.enumerated() {
                let rawDist = Double(CGFloat(i) * spacing) + (time * trainSpeed)
                var dist = CGFloat(rawDist.truncatingRemainder(dividingBy: Double(trackLength)))
                if dist < 0 { dist += trackLength }
                let px = sideMargin + dist
                nodes[app.id] = AppFormationNode(center: clampToScreen(CGPoint(x: px, y: railY)), scale: 1.0)
            }

        case "Bottom Dock Train 🚂":
            // Continuous infinite train of applications traveling horizontally above the dock
            let railY = topClearance + usableHeight - (iconSize / 2.0) - 6.0
            let trackLength = max(100.0, usableWidth)
            let spacing = max(iconSize + 14.0, curSpacing + iconSize)
            let trainSpeed = 52.0 * safeSpeed * (orbitClockwise ? 1.0 : -1.0)

            for (i, app) in apps.enumerated() {
                let rawDist = Double(CGFloat(i) * spacing) + (time * trainSpeed)
                var dist = CGFloat(rawDist.truncatingRemainder(dividingBy: Double(trackLength)))
                if dist < 0 { dist += trackLength }
                let px = sideMargin + dist
                nodes[app.id] = AppFormationNode(center: clampToScreen(CGPoint(x: px, y: railY)), scale: 1.0)
            }

        case "Vanishing V-Formation 🦅":
            // Apps travel down a V-shaped flight path from top wings, converging and vanishing at center
            let vertex = CGPoint(x: cx, y: topClearance + usableHeight * 0.76)
            let leftStart = CGPoint(x: sideMargin + 30.0, y: topClearance + 16.0)
            let rightStart = CGPoint(x: screenSize.width - sideMargin - 30.0, y: topClearance + 16.0)
            let armLength = max(100.0, hypot(vertex.x - leftStart.x, vertex.y - leftStart.y))
            let spacing = max(iconSize + 16.0, curSpacing + iconSize)
            let speed = 54.0 * safeSpeed * (orbitClockwise ? 1.0 : -1.0)

            for (i, app) in apps.enumerated() {
                let isLeft = (i % 2 == 0)
                let subIdx = i / 2
                let rawDist = Double(CGFloat(subIdx) * spacing) + (time * speed)
                var dist = CGFloat(rawDist.truncatingRemainder(dividingBy: Double(armLength)))
                if dist < 0 { dist += armLength }

                let progress = dist / armLength
                let startPoint = isLeft ? leftStart : rightStart
                let px = startPoint.x + (vertex.x - startPoint.x) * progress
                let py = startPoint.y + (vertex.y - startPoint.y) * progress

                let vanishScale = max(0.18, 1.0 - pow(Double(progress), 3.0))
                nodes[app.id] = AppFormationNode(center: clampToScreen(CGPoint(x: px, y: py)), scale: CGFloat(vanishScale))
            }

        case "Smart Resizable Matrix 🔲":
            // Resizable matrix that smart-sizes icon and text based on available space and app density
            let availableArea = usableWidth * usableHeight
            let targetCellArea = availableArea / CGFloat(max(1, count))
            let dynamicDim = sqrt(targetCellArea) * 0.76
            let smartIcon = min(max(34.0, dynamicDim - 22.0), 84.0)
            let smartScale = smartIcon / max(1.0, iconSize)
            let nameH = showName ? (textSize * smartScale + 6.0) : 0.0
            let effectiveSpacing = max(6.0, curSpacing * smartScale)

            let cellW = smartIcon + effectiveSpacing
            let cellH = smartIcon + nameH + effectiveSpacing

            let cols = max(2, min(count, Int(floor((usableWidth + effectiveSpacing) / cellW))))

            let totalW = CGFloat(cols) * smartIcon + CGFloat(max(0, cols - 1)) * effectiveSpacing

            let startX = max(sideMargin, (screenSize.width - totalW) / 2.0)
            let startY = topClearance + 20.0

            for (i, app) in apps.enumerated() {
                let r = i / cols
                let c = i % cols
                let px = startX + (smartIcon / 2.0) + CGFloat(c) * cellW
                let py = startY + (smartIcon / 2.0) + CGFloat(r) * cellH
                nodes[app.id] = AppFormationNode(center: clampToScreen(CGPoint(x: px, y: py)), scale: smartScale)
            }



        case "Centered Single Dock ↔️":
            // Single clean horizontal launcher row centered across the desktop
            let spacing = max(14.0, curSpacing)
            let totalW = CGFloat(count) * iconSize + CGFloat(max(0, count - 1)) * spacing
            let startX = max(sideMargin, (screenSize.width - totalW) / 2.0)
            let dockY = topClearance + usableHeight - (iconSize / 2.0) - 16.0

            for (i, app) in apps.enumerated() {
                let px = startX + (iconSize / 2.0) + CGFloat(i) * (iconSize + spacing)
                nodes[app.id] = AppFormationNode(center: clampToScreen(CGPoint(x: px, y: dockY)), scale: 1.0)
            }

        case "Centered Column Strip ↕️":
            // Single clean vertical launcher strip centered on the desktop
            let nameH = showName ? (textSize + 8.0) : 0.0
            let spacing = max(12.0, curSpacing)
            let startY = topClearance + 20.0

            for (i, app) in apps.enumerated() {
                let py = startY + (iconSize / 2.0) + CGFloat(i) * (iconSize + nameH + spacing)
                nodes[app.id] = AppFormationNode(center: clampToScreen(CGPoint(x: cx, y: py)), scale: 1.0)
            }

        case "Custom Formation 🛠️", "Custom Formation":
            let nameH = showName ? (textSize + 8.0) : 0.0
            let cols = max(1, min(max(1, customFormationColumns), count))
            let spacing = max(12.0, curSpacing)
            let totalW = CGFloat(cols) * iconSize + CGFloat(max(0, cols - 1)) * spacing
            let startX = max(sideMargin, (screenSize.width - totalW) / 2.0)
            let startY = topClearance + 20.0
            let minX = sideMargin + (iconSize / 2.0)
            let maxX = max(minX, screenSize.width - sideMargin - (iconSize / 2.0))

            for (i, app) in apps.enumerated() {
                let r = i / cols
                let c = i % cols
                let px = startX + (iconSize / 2.0) + CGFloat(c) * (iconSize + spacing)
                let py = startY + (iconSize / 2.0) + CGFloat(r) * (iconSize + nameH + spacing)
                let clampedX = min(max(minX, px), maxX)
                nodes[app.id] = AppFormationNode(center: CGPoint(x: clampedX, y: py), scale: 1.0)
            }

        case "Lined Up Above Chat ⬆️", "Icons Above Chat", "Lined Up Above Chat":
            // Clean symmetrical app matrix placed directly above the AI Chat & Search Bar with generous padding
            let nameH = showName ? (textSize + 8.0) : 0.0
            let spacing = max(14.0, curSpacing)
            let cellW = iconSize + spacing

            let maxCols = max(3, Int(floor((usableWidth - 40.0) / cellW)))
            let idealCols = min(maxCols, max(4, Int(ceil(sqrt(Double(count) * 1.8)))))
            let cols = max(1, idealCols)
            let rows = max(1, Int(ceil(Double(count) / Double(cols))))

            let startY = topClearance + 20.0

            let minX = sideMargin + (iconSize / 2.0)
            let maxX = max(minX, screenSize.width - sideMargin - (iconSize / 2.0))

            for (i, app) in apps.enumerated() {
                let r = i / cols
                let c = i % cols

                let itemsInRow = (r == rows - 1) ? (count - r * cols) : cols
                let rowW = CGFloat(itemsInRow) * iconSize + CGFloat(max(0, itemsInRow - 1)) * spacing
                let rowStartX = (screenSize.width - rowW) / 2.0

                let px = rowStartX + (iconSize / 2.0) + CGFloat(c) * (iconSize + spacing)
                let py = startY + (iconSize / 2.0) + CGFloat(r) * (iconSize + nameH + spacing)
                let clampedX = min(max(minX, px), maxX)
                nodes[app.id] = AppFormationNode(center: CGPoint(x: clampedX, y: py), scale: 1.0)
            }

        case "Surround Search Bar Grid 🪔", "Surround Search Bar", "Surround Search Bar Grid":
            fallthrough
        default: // "Responsive Grid" (Full Screen Springboard Matrix surrounding Search Bar)
            let nameH = showName ? (textSize + 8.0) : 0.0
            let metrics = SurroundGridMetrics.calculate(
                screenSize: screenSize,
                usableWidth: usableWidth,
                usableHeight: usableHeight,
                topClearance: topClearance,
                sideMargin: sideMargin,
                iconSize: iconSize,
                spacing: curSpacing,
                nameHeight: nameH,
                count: count,
                desktopSplitMode: desktopSplitMode
            )

            // Gather all available surround slots row-by-row in visual reading order:
            var orderedSlots: [CGPoint] = []
            let isChatDetached = UserDefaults.standard.bool(forKey: PrefKey.isChatDetached)
            let stageRaw = UserDefaults.standard.integer(forKey: PrefKey.appDisplayStage)
            let shouldExcludeChat = !isChatDetached && (stageRaw == 0)

            for r in 0..<metrics.rows {
                for c in 0..<metrics.cols {
                    let px = metrics.startX + (iconSize / 2.0) + CGFloat(c) * metrics.cellW
                    let yNudge: CGFloat = shouldExcludeChat ? ((r < metrics.searchRow) ? -8.0 : ((r > metrics.searchRow) ? 8.0 : 0.0)) : 0.0
                    let py = metrics.startY + (iconSize / 2.0) + CGFloat(r) * metrics.cellH + yNudge

                    // Check if this cell center overlaps search bar exclusion rect (auto-fill when open or detached)
                    if shouldExcludeChat && r == metrics.searchRow && (abs(px - (screenSize.width / 2.0)) < (metrics.searchBarExclusionRect.width / 2.0)) {
                        continue // Reserved for search bar when docked!
                    }

                    orderedSlots.append(CGPoint(x: px, y: py))
                }
            }

            let minX = sideMargin + (iconSize / 2.0)
            let maxX = max(minX, screenSize.width - sideMargin - (iconSize / 2.0))

            for (i, app) in apps.enumerated() {
                if i < orderedSlots.count {
                    let slot = orderedSlots[i]
                    let clampedX = min(max(minX, slot.x), maxX)
                    nodes[app.id] = AppFormationNode(center: CGPoint(x: clampedX, y: slot.y), scale: 1.0)
                } else {
                    let fallbackX = metrics.startX + (iconSize / 2.0) + CGFloat(i % metrics.cols) * metrics.cellW
                    let fallbackY = metrics.startY + (iconSize / 2.0) + CGFloat(i / metrics.cols) * metrics.cellH
                    nodes[app.id] = AppFormationNode(center: CGPoint(x: fallbackX, y: fallbackY), scale: 1.0)
                }
            }
        }

        return nodes
    }
}

// MARK: - Apple Home App Tile (Hyper-Magnification + Genie Lift & Tilt + Camouflage Shader)

struct AppleHomeAppTile: View {
    @AppStorage(PrefKey.appLanguage) var appLanguage: String = "English (US)"
let app: AppInfo
    let index: Int
    let itemCenter: CGPoint
    let screenSize: CGSize
    let iconSize: CGFloat
    let textSize: CGFloat
    let showName: Bool
    let theme: String
    let tintColor: String
    let iconSnuggie: String
    var physicsSimulation: String = "None"
    let flamePhase: Double
    let wallpaperImage: NSImage?
    let isEditing: Bool
    let wiggle: Bool
    let enableMagnification: Bool
    let hoverScale: CGFloat
    let isHovered: Bool
    let isDragged: Bool
    let dragOffset: CGSize
    let isDropTarget: Bool
    let onLaunch: () -> Void
    let onHide: () -> Void
    let onShowInFinder: () -> Void
    let onEnterEditMode: () -> Void
    let onHoverChanged: (Bool) -> Void
    let onDragChanged: (CGSize) -> Void
    let onDragEnded: () -> Void

@State private var isPressed: Bool = false

    private var liveBulgeScale: CGFloat {
        if physicsSimulation == "Random Pulsing Bubbles 🫧" || physicsSimulation == "Live Bulge & Breathing 🫁" {
            let seed = Double(index * 137)
            let pulse = sin((flamePhase * 0.05) + seed) * 0.18 + cos((flamePhase * 0.03) + (seed * 0.5)) * 0.08
            return CGFloat(1.0 + pulse)
        } else if physicsSimulation == "Jelly Bounce 🍮" {
            let seed = Double(index * 73)
            let bounce = abs(sin((flamePhase * 0.08) + seed)) * 0.18
            return CGFloat(0.94 + bounce)
        } else if physicsSimulation == "Springy Trampoline 🤸" {
            let seed = Double(index * 47)
            let spring = sin((flamePhase * 0.09) + seed) * 0.14
            return CGFloat(1.0 + spring)
        }
        return 1.0
    }

    private var magnificationMetrics: (scale: CGFloat, liftY: CGFloat) {
        if isPressed { return (0.88, -2) }
        if isDragged { return (1.25, -12) }
        if isDropTarget { return (1.15, -6) }
        if isEditing { return (1.0, 0) }

        if isHovered {
            let targetScale = enableMagnification ? max(1.10, hoverScale) : 1.06
            return (targetScale, -8)
        }

        return (1.0, 0)
    }

    private var wiggleAngle: Double {
        guard isEditing else { return 0.0 }
        let sign: Double = index.isMultiple(of: 2) ? 1.0 : -1.0
        return wiggle ? (sign * 1.6) : (-sign * 1.6)
    }

    var body: some View {
        let metrics = magnificationMetrics
        let currentScale = metrics.scale
        let currentLift = metrics.liftY

        ZStack(alignment: .topLeading) {
            Button(action: {
                if isEditing {
                    onHide()
                } else {
                    triggerLaunch()
                }
            }) {
                VStack(spacing: 4) {
                    ZStack {
                        ThemedAppIconLayer(
                            icon: app.icon,
                            size: iconSize,
                            theme: theme,
                            tintColorName: tintColor,
                            iconSnuggie: iconSnuggie,
                            itemCenter: itemCenter,
                            screenSize: screenSize,
                            wallpaperImage: wallpaperImage,
                            isHovered: isHovered,
                            flamePhase: flamePhase + Double(index * 25)
                        )
                        .scaleEffect(currentScale * liveBulgeScale)
                        .offset(y: currentLift)
                        .rotationEffect(.degrees(wiggleAngle))
                        .animation(.spring(response: 0.20, dampingFraction: 0.72), value: currentScale)
                        .animation(.spring(response: 0.20, dampingFraction: 0.72), value: currentLift)
                        .animation(.spring(response: 0.08, dampingFraction: 0.42), value: isPressed)
                    }
                    .frame(width: iconSize, height: iconSize)

                    if showName {
                        Text(app.name)
                            .font(
                                theme == "Pop Punk Artist"
                                    ? .system(size: textSize, weight: .heavy, design: .rounded)
                                    : (theme == "Skate Punk Stickers"
                                        ? .system(size: textSize, weight: .bold, design: .monospaced)
                                        : (theme == "Ice Cream Dream"
                                            ? .system(size: textSize, weight: .semibold, design: .rounded)
                                            : .system(size: textSize, weight: isHovered ? .semibold : .medium)))
                            )
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .foregroundColor(
                                theme == "Pop Punk Artist"
                                    ? (isHovered ? Color(red: 1.0, green: 0.92, blue: 0.10) : Color.white)
                                    : (theme == "Ice Cream Dream"
                                        ? (isHovered ? Color(red: 1.0, green: 0.70, blue: 0.85) : Color.white)
                                        : Color.white.opacity(0.98))
                            )
                            .shadow(
                                color: theme == "Pop Punk Artist"
                                    ? Color(red: 1.0, green: 0.08, blue: 0.58).opacity(isHovered ? 0.95 : 0.60)
                                    : (theme == "Ice Cream Dream"
                                        ? Color(red: 0.9, green: 0.4, blue: 0.7).opacity(0.60)
                                        : Color.black.opacity(0.95)),
                                radius: isHovered ? 4 : 2,
                                x: 0,
                                y: 1.0
                            )
                            .frame(maxWidth: max(iconSize * 1.15, 60.0))
                            .scaleEffect(isHovered ? 1.04 : 1.0)
                            .offset(y: currentLift * 0.3)
                    }
                }
                .frame(width: max(iconSize * 1.15, 60.0), height: iconSize + (showName ? (textSize + 6.0) : 0) + 8)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .contextMenu {
                Button(action: { triggerLaunch() }) {
                    Label(LocalizedStrings.openApp(name: app.name, lang: appLanguage), systemImage: "play.fill")
                }
                Button(action: { onShowInFinder() }) {
                    Label(LocalizedStrings.showInFinder(lang: appLanguage), systemImage: "folder")
                }
                Divider()
                Button(action: { onHide() }) {
                    Label(LocalizedStrings.hideFromDesktop(lang: appLanguage), systemImage: "eye.slash")
                }
                Button(action: { onEnterEditMode() }) {
                    Label(LocalizedStrings.editAppsAndLayout(lang: appLanguage), systemImage: "pencil")
                }
            }

            if isEditing {
                Button(action: { onHide() }) {
                    ZStack {
                        Circle()
                            .fill(Color(white: 0.22))
                            .frame(width: 20, height: 20)
                            .shadow(color: Color.black.opacity(0.4), radius: 2, x: 0, y: 1)

                        Image(systemName: "minus")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(.plain)
                .offset(x: -4, y: -4)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .offset(dragOffset)
        .zIndex(isDragged ? 100 : (isDropTarget ? 60 : (isHovered ? 50 : 1)))
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.40)
                .onEnded { _ in
                    HapticFeedback.heavy()
                    withAnimation(.spring(response: 0.30, dampingFraction: 0.72)) {
                        onEnterEditMode()
                    }
                }
        )
        .gesture(
            DragGesture(minimumDistance: 3)
                .onChanged { value in
                    guard isEditing else { return }
                    onDragChanged(value.translation)
                }
                .onEnded { _ in
                    guard isEditing else { return }
                    onDragEnded()
                }
        )
        .onHover { isH in
            onHoverChanged(isH)
            if isH && !isEditing {
                HapticFeedback.tick()
            }
        }
        .help(app.name)
    }

    private func triggerLaunch() {
        HapticFeedback.heavy()
        withAnimation(.spring(response: 0.08, dampingFraction: 0.40)) {
            isPressed = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.spring(response: 0.24, dampingFraction: 0.58)) {
                isPressed = false
            }
            onLaunch()
        }
    }
}

// MARK: - Themed App Icon Layer (28+ Rich Themes & Wallpaper Camouflage Engine)

struct ThemedAppIconLayer: View {
    @AppStorage(PrefKey.appLanguage) var appLanguage: String = "English (US)"
let icon: NSImage
    let size: CGFloat
    let theme: String
    let tintColorName: String
    var iconSnuggie: String = "None"
    var itemCenter: CGPoint = .zero
    var screenSize: CGSize = .zero
    var wallpaperImage: NSImage? = nil
    let isHovered: Bool
    let flamePhase: Double

    private var parsedTintColor: Color {
        switch tintColorName {
        case "Emerald": return Color.green
        case "Cyan": return Color.cyan
        case "Electric Blue": return Color.blue
        case "Cyber Pink": return Color(red: 1.0, green: 0.15, blue: 0.6)
        case "Purple": return Color.purple
        case "Solar Amber": return Color.orange
        case "Ruby Red": return Color.red
        case "Gold": return Color.yellow
        default: return Color.green
        }
    }

    private var spin3DAngle: Double {
        if theme == "3D Hologram Spinner" {
            let base = (flamePhase * 90.0).truncatingRemainder(dividingBy: 360.0)
            return isHovered ? (base * 2.5) : base
        } else if theme == "3D Coin Flip" {
            let base = (flamePhase * 130.0).truncatingRemainder(dividingBy: 360.0)
            return isHovered ? (base * 2.0) : base
        } else if theme == "3D Quantum Vortex" {
            let base = (flamePhase * 85.0).truncatingRemainder(dividingBy: 360.0)
            return isHovered ? (base * 2.2) : base
        } else if theme == "3D Skater Kickflip" {
            let base = (flamePhase * 150.0).truncatingRemainder(dividingBy: 360.0)
            return isHovered ? (base * 2.5) : base
        } else if theme == "3D Hypercube 4D" {
            let base = (flamePhase * 75.0).truncatingRemainder(dividingBy: 360.0)
            return isHovered ? (base * 2.0) : base
        } else if theme == "3D Kinetic Gyroscope" {
            let base = (flamePhase * 110.0).truncatingRemainder(dividingBy: 360.0)
            return isHovered ? (base * 2.3) : base
        } else if theme == "3D Diamond Facet" {
            let base = (flamePhase * 95.0).truncatingRemainder(dividingBy: 360.0)
            return isHovered ? (base * 2.1) : base
        } else if theme == "3D Orbiting Satellites" {
            let base = (flamePhase * 60.0).truncatingRemainder(dividingBy: 360.0)
            return isHovered ? (base * 2.0) : base
        }
        return 0.0
    }

    private var spin3DAxis: (x: CGFloat, y: CGFloat, z: CGFloat) {
        if theme == "3D Coin Flip" {
            return (x: 1.0, y: 0.0, z: 0.0)
        } else if theme == "3D Quantum Vortex" {
            return (x: 0.6, y: 1.0, z: 0.3)
        } else if theme == "3D Skater Kickflip" {
            return (x: 0.3, y: 1.0, z: 0.7)
        } else if theme == "3D Hypercube 4D" {
            return (x: 0.7, y: 0.7, z: 0.3)
        } else if theme == "3D Kinetic Gyroscope" {
            return (x: 0.2, y: 1.0, z: 0.8)
        } else if theme == "3D Diamond Facet" {
            return (x: 0.4, y: 0.9, z: 0.0)
        } else if theme == "3D Orbiting Satellites" {
            return (x: 0.0, y: 1.0, z: 0.5)
        }
        return (x: 0.0, y: 1.0, z: 0.0)
    }

    var body: some View {
        ZStack {
            // 0. WALLPAPER CAMOUFLAGE / CHAMELEON SHADER 🦎
            if theme == "Wallpaper Camouflage" {
                ZStack {
                    if let wp = wallpaperImage ?? WallpaperManager.shared.activeWallpaperImage, screenSize.width > 0, screenSize.height > 0 {
                        Image(nsImage: wp)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: screenSize.width, height: screenSize.height)
                            .position(
                                x: (screenSize.width / 2.0) - (itemCenter.x - size / 2.0),
                                y: (screenSize.height / 2.0) - (itemCenter.y - size / 2.0)
                            )
                            .frame(width: size, height: size)
                            .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                Color.white.opacity(isHovered ? 0.85 : 0.30),
                                                Color.clear,
                                                Color.white.opacity(isHovered ? 0.45 : 0.10)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: isHovered ? 1.8 : 0.8
                                    )
                            )
                    } else {
                        RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)
                                    .stroke(Color.white.opacity(isHovered ? 0.60 : 0.20), lineWidth: isHovered ? 1.5 : 0.8)
                            )
                    }
                }
                .shadow(color: Color.black.opacity(isHovered ? 0.40 : 0.18), radius: isHovered ? 14 : 4, x: 0, y: isHovered ? 6 : 2)
            }

            // GENIE GOLD 24K THEME ✨
            if theme == "Genie Gold 24K" || theme == "Gold Gate" {
                RadialGradient(
                    colors: [
                        Color(red: 1.0, green: 0.84, blue: 0.20, opacity: isHovered ? 0.95 : 0.65),
                        Color(red: 0.98, green: 0.45, blue: 0.10, opacity: isHovered ? 0.60 : 0.30),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: size * 0.15,
                    endRadius: size * 0.88
                )
                .frame(width: size * 1.45, height: size * 1.45)
                .blur(radius: isHovered ? 12 : 8)
            }

            // POP PUNK ARTIST THEME 🎸 (Neon Pink, Electric Yellow, Distressed Jagged Rim)
            if theme == "Pop Punk Artist" {
                RadialGradient(
                    colors: [
                        Color(red: 1.0, green: 0.08, blue: 0.58, opacity: isHovered ? 1.0 : 0.75), // Hot Pink
                        Color(red: 1.0, green: 0.92, blue: 0.05, opacity: isHovered ? 0.70 : 0.35), // Electric Yellow
                        Color.clear
                    ],
                    center: .center,
                    startRadius: size * 0.12,
                    endRadius: size * 0.92
                )
                .frame(width: size * 1.5, height: size * 1.5)
                .blur(radius: isHovered ? 11 : 6)
            }

            // SKATE PUNK STICKERS THEME 🛹
            if theme == "Skate Punk Stickers" {
                RadialGradient(
                    colors: [
                        Color.white.opacity(isHovered ? 0.95 : 0.65),
                        Color(red: 0.1, green: 0.85, blue: 0.95, opacity: 0.4),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: size * 0.15,
                    endRadius: size * 0.88
                )
                .frame(width: size * 1.45, height: size * 1.45)
                .blur(radius: 8)
            }

            // ICE CREAM DREAM THEME 🍦 (Pastel Mint, Strawberry Pink & Cream)
            if theme == "Ice Cream Dream" {
                RadialGradient(
                    colors: [
                        Color(red: 1.0, green: 0.65, blue: 0.80, opacity: isHovered ? 0.95 : 0.70), // Strawberry
                        Color(red: 0.60, green: 0.95, blue: 0.88, opacity: isHovered ? 0.60 : 0.35), // Mint
                        Color.clear
                    ],
                    center: .center,
                    startRadius: size * 0.15,
                    endRadius: size * 0.88
                )
                .frame(width: size * 1.45, height: size * 1.45)
                .blur(radius: 10)
            }

            // 1. INFERNO / FIRE EFFECT 🔥
            if theme == "Inferno" {
                RadialGradient(
                    colors: [
                        Color(red: 1.0, green: 0.35, blue: 0.0, opacity: isHovered ? 0.95 : 0.65),
                        Color(red: 1.0, green: 0.10, blue: 0.0, opacity: isHovered ? 0.65 : 0.35),
                        Color(red: 0.8, green: 0.0, blue: 0.0, opacity: 0.0)
                    ],
                    center: .center,
                    startRadius: size * 0.15,
                    endRadius: size * (isHovered ? 0.90 : 0.72)
                )
                .frame(width: size * 1.5, height: size * 1.5)
                .blur(radius: isHovered ? 12 : 8)
            }

            // 2. CYBERPUNK HOLOGRAM FX ⚡️
            if theme == "Cyberpunk" {
                RadialGradient(
                    colors: [Color.cyan.opacity(isHovered ? 0.90 : 0.55), Color(red: 1.0, green: 0.0, blue: 0.7, opacity: isHovered ? 0.60 : 0.30), Color.clear],
                    center: .center,
                    startRadius: size * 0.2,
                    endRadius: size * 0.85
                )
                .frame(width: size * 1.4, height: size * 1.4)
                .blur(radius: 10)
            }

            // 3. MATRIX CYBER FX 🟢
            if theme == "Matrix" {
                RadialGradient(
                    colors: [Color.green.opacity(isHovered ? 0.95 : 0.60), Color(red: 0.0, green: 0.4, blue: 0.1, opacity: 0.3), Color.clear],
                    center: .center,
                    startRadius: size * 0.2,
                    endRadius: size * 0.85
                )
                .frame(width: size * 1.4, height: size * 1.4)
                .blur(radius: 10)
            }

            // 4. SOLAR FLARE FX ☀️
            if theme == "Solar Flare" {
                RadialGradient(
                    colors: [Color.yellow.opacity(isHovered ? 0.95 : 0.65), Color.orange.opacity(isHovered ? 0.60 : 0.35), Color.clear],
                    center: .center,
                    startRadius: size * 0.2,
                    endRadius: size * 0.90
                )
                .frame(width: size * 1.5, height: size * 1.5)
                .blur(radius: 12)
            }

            // 5. FROST GLAZE FX ❄️
            if theme == "Frost Glaze" {
                RadialGradient(
                    colors: [Color.cyan.opacity(isHovered ? 0.90 : 0.60), Color.blue.opacity(isHovered ? 0.50 : 0.25), Color.clear],
                    center: .center,
                    startRadius: size * 0.2,
                    endRadius: size * 0.85
                )
                .frame(width: size * 1.4, height: size * 1.4)
                .blur(radius: 10)
            }

            // 6. VOID SINGULARITY FX 🌌
            if theme == "Void" {
                RadialGradient(
                    colors: [Color.purple.opacity(isHovered ? 0.90 : 0.60), Color(red: 0.1, green: 0.0, blue: 0.3, opacity: 0.4), Color.clear],
                    center: .center,
                    startRadius: size * 0.2,
                    endRadius: size * 0.85
                )
                .frame(width: size * 1.45, height: size * 1.45)
                .blur(radius: 10)
            }

            // 7. QUANTUM PRISM FX 🌈
            if theme == "Quantum Prism" {
                RadialGradient(
                    colors: [Color.pink.opacity(isHovered ? 0.90 : 0.55), Color.cyan.opacity(isHovered ? 0.60 : 0.30), Color.clear],
                    center: .center,
                    startRadius: size * 0.2,
                    endRadius: size * 0.85
                )
                .frame(width: size * 1.4, height: size * 1.4)
                .blur(radius: 11)
            }

            // 8. TOXIC PLASMA FX ☣️
            if theme == "Toxic Plasma" {
                RadialGradient(
                    colors: [Color(red: 0.4, green: 1.0, blue: 0.0, opacity: isHovered ? 0.95 : 0.65), Color(red: 0.0, green: 0.9, blue: 0.8, opacity: isHovered ? 0.60 : 0.30), Color.clear],
                    center: .center,
                    startRadius: size * 0.15,
                    endRadius: size * 0.85
                )
                .frame(width: size * 1.45, height: size * 1.45)
                .blur(radius: 11)
            }

            // 9. SUPERNOVA BLAST FX 💥
            if theme == "Supernova" {
                RadialGradient(
                    colors: [Color.white.opacity(isHovered ? 1.0 : 0.7), Color(red: 1.0, green: 0.4, blue: 0.1, opacity: isHovered ? 0.85 : 0.50), Color.clear],
                    center: .center,
                    startRadius: size * 0.1,
                    endRadius: size * 0.95
                )
                .frame(width: size * 1.55, height: size * 1.55)
                .blur(radius: 13)
            }

            // 10. MIDNIGHT GOLD FX ✨
            if theme == "Midnight Gold" {
                RadialGradient(
                    colors: [Color.yellow.opacity(isHovered ? 0.90 : 0.55), Color.orange.opacity(isHovered ? 0.60 : 0.30), Color.clear],
                    center: .center,
                    startRadius: size * 0.15,
                    endRadius: size * 0.85
                )
                .frame(width: size * 1.35, height: size * 1.35)
                .blur(radius: 8)
            }

            // 11. SYNTHWAVE SUNSET 🌆
            if theme == "Synthwave" {
                RadialGradient(
                    colors: [Color(red: 1.0, green: 0.1, blue: 0.6, opacity: 0.75), Color(red: 0.3, green: 0.0, blue: 0.8, opacity: 0.4), Color.clear],
                    center: .center,
                    startRadius: size * 0.15,
                    endRadius: size * 0.85
                )
                .frame(width: size * 1.45, height: size * 1.45)
                .blur(radius: 10)
            }

            // 12. VAPORWAVE 🌴
            if theme == "Neon Vaporwave" {
                RadialGradient(
                    colors: [Color.cyan.opacity(0.8), Color.pink.opacity(0.5), Color.clear],
                    center: .center,
                    startRadius: size * 0.15,
                    endRadius: size * 0.85
                )
                .frame(width: size * 1.45, height: size * 1.45)
                .blur(radius: 10)
            }

            // 13. DIAMOND GLASS 💎
            if theme == "Diamond Crystal Glass" {
                RadialGradient(
                    colors: [Color.white.opacity(isHovered ? 0.95 : 0.60), Color.cyan.opacity(0.4), Color.clear],
                    center: .topLeading,
                    startRadius: size * 0.1,
                    endRadius: size * 0.9
                )
                .frame(width: size * 1.4, height: size * 1.4)
                .blur(radius: 8)
            }

            // 14. ARCANE RUNE 🔮
            if theme == "Arcane Rune" {
                RadialGradient(
                    colors: [Color.purple.opacity(isHovered ? 0.95 : 0.65), Color.indigo.opacity(0.4), Color.clear],
                    center: .center,
                    startRadius: size * 0.15,
                    endRadius: size * 0.85
                )
                .frame(width: size * 1.4, height: size * 1.4)
                .blur(radius: 10)
            }

            // 15. BIO-ORGANIC FLORA 🌿
            if theme == "Bio-Organic Flora" {
                RadialGradient(
                    colors: [Color.green.opacity(isHovered ? 0.90 : 0.60), Color.mint.opacity(0.35), Color.clear],
                    center: .center,
                    startRadius: size * 0.15,
                    endRadius: size * 0.85
                )
                .frame(width: size * 1.4, height: size * 1.4)
                .blur(radius: 9)
            }

            // 16. LIQUID CHROME 🪩
            if theme == "Liquid Chrome" {
                RadialGradient(
                    colors: [Color.white.opacity(isHovered ? 0.90 : 0.55), Color.gray.opacity(0.4), Color.clear],
                    center: .topLeading,
                    startRadius: size * 0.1,
                    endRadius: size * 0.85
                )
                .frame(width: size * 1.35, height: size * 1.35)
                .blur(radius: 8)
            }

            // 🌊 4K NATURE & MARINE THEME SHADERS
            if theme == "4K Ultra-HD Marine Caustics" {
                RadialGradient(
                    colors: [
                        Color(red: 0.10, green: 0.90, blue: 1.0, opacity: isHovered ? 0.95 : 0.65),
                        Color(red: 0.05, green: 0.45, blue: 0.95, opacity: isHovered ? 0.70 : 0.35),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: size * 0.15,
                    endRadius: size * 0.90
                )
                .frame(width: size * 1.5, height: size * 1.5)
                .blur(radius: isHovered ? 12 : 8)
            }

            if theme == "Pacific Ocean Dolphins" {
                RadialGradient(
                    colors: [
                        Color(red: 0.30, green: 0.75, blue: 1.0, opacity: isHovered ? 0.90 : 0.60),
                        Color(red: 0.10, green: 0.35, blue: 0.65, opacity: isHovered ? 0.65 : 0.30),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: size * 0.15,
                    endRadius: size * 0.88
                )
                .frame(width: size * 1.45, height: size * 1.45)
                .blur(radius: isHovered ? 11 : 8)
            }

            if theme == "Coral Reef Aquaria" {
                RadialGradient(
                    colors: [
                        Color(red: 1.0, green: 0.45, blue: 0.20, opacity: isHovered ? 0.90 : 0.60),
                        Color(red: 0.0, green: 0.85, blue: 0.75, opacity: isHovered ? 0.65 : 0.30),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: size * 0.15,
                    endRadius: size * 0.88
                )
                .frame(width: size * 1.45, height: size * 1.45)
                .blur(radius: isHovered ? 11 : 8)
            }

            if theme == "Deep Sea Manta" {
                RadialGradient(
                    colors: [
                        Color(red: 0.15, green: 0.35, blue: 0.70, opacity: isHovered ? 0.90 : 0.55),
                        Color(red: 0.05, green: 0.10, blue: 0.30, opacity: isHovered ? 0.70 : 0.35),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: size * 0.15,
                    endRadius: size * 0.85
                )
                .frame(width: size * 1.4, height: size * 1.4)
                .blur(radius: isHovered ? 10 : 7)
            }

            // 🛹 SKATEBOARD THEME SHADERS
            if theme == "Street Skater & Grip Tape" {
                RadialGradient(
                    colors: [
                        Color(white: 0.25, opacity: isHovered ? 0.95 : 0.70),
                        Color(red: 1.0, green: 0.40, blue: 0.0, opacity: isHovered ? 0.60 : 0.25),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: size * 0.15,
                    endRadius: size * 0.88
                )
                .frame(width: size * 1.45, height: size * 1.45)
                .blur(radius: isHovered ? 10 : 6)
            }

            if theme == "Thrasher Flame" {
                RadialGradient(
                    colors: [
                        Color(red: 1.0, green: 0.80, blue: 0.0, opacity: isHovered ? 1.0 : 0.70),
                        Color(red: 1.0, green: 0.15, blue: 0.0, opacity: isHovered ? 0.75 : 0.40),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: size * 0.15,
                    endRadius: size * 0.92
                )
                .frame(width: size * 1.5, height: size * 1.5)
                .blur(radius: isHovered ? 12 : 8)
            }

            if theme == "Venice Beach Halfpipe" {
                RadialGradient(
                    colors: [
                        Color(red: 0.0, green: 0.95, blue: 0.85, opacity: isHovered ? 0.90 : 0.55),
                        Color(red: 1.0, green: 0.35, blue: 0.60, opacity: isHovered ? 0.65 : 0.30),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: size * 0.15,
                    endRadius: size * 0.88
                )
                .frame(width: size * 1.45, height: size * 1.45)
                .blur(radius: 10)
            }

            if theme == "Cyber Deck" {
                RadialGradient(
                    colors: [
                        Color(red: 0.0, green: 1.0, blue: 0.75, opacity: isHovered ? 0.95 : 0.60),
                        Color(red: 0.6, green: 0.0, blue: 1.0, opacity: isHovered ? 0.65 : 0.30),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: size * 0.15,
                    endRadius: size * 0.88
                )
                .frame(width: size * 1.45, height: size * 1.45)
                .blur(radius: 11)
            }

            // 17. ELECTRIC LIGHTNING PLASMA ⚡️
            if theme == "Electric Lightning Plasma" {
                RadialGradient(
                    colors: [Color.cyan.opacity(isHovered ? 1.0 : 0.70), Color.blue.opacity(isHovered ? 0.70 : 0.35), Color.clear],
                    center: .center,
                    startRadius: size * 0.15,
                    endRadius: size * 0.90
                )
                .frame(width: size * 1.5, height: size * 1.5)
                .blur(radius: isHovered ? 12 : 7)
            }

            // 18. HOLOGRAPHIC CHROMATIC PRISM 🌈
            if theme == "Holographic Chromatic Prism" {
                RadialGradient(
                    colors: [Color.pink.opacity(isHovered ? 0.90 : 0.60), Color.cyan.opacity(isHovered ? 0.75 : 0.45), Color.yellow.opacity(isHovered ? 0.60 : 0.20), Color.clear],
                    center: .topLeading,
                    startRadius: size * 0.1,
                    endRadius: size * 0.92
                )
                .frame(width: size * 1.45, height: size * 1.45)
                .blur(radius: 10)
            }

            // 19. CYBER GLITCH DISTORTION 👾
            if theme == "Cyber Glitch Distortion" {
                RadialGradient(
                    colors: [Color.green.opacity(isHovered ? 0.90 : 0.55), Color.purple.opacity(isHovered ? 0.70 : 0.35), Color.clear],
                    center: .center,
                    startRadius: size * 0.18,
                    endRadius: size * 0.88
                )
                .frame(width: size * 1.4, height: size * 1.4)
                .blur(radius: 9)
            }

            // 20. HUD TACTICAL COMBAT 🎯
            if theme == "HUD Tactical Combat" {
                RadialGradient(
                    colors: [Color(red: 0.1, green: 0.9, blue: 0.2, opacity: isHovered ? 0.90 : 0.55), Color.clear],
                    center: .center,
                    startRadius: size * 0.15,
                    endRadius: size * 0.85
                )
                .frame(width: size * 1.4, height: size * 1.4)
                .blur(radius: 8)
            }

            // 21. BLACK HOLE SINGULARITY 🕳️
            if theme == "Black Hole Singularity" {
                RadialGradient(
                    colors: [Color(red: 1.0, green: 0.45, blue: 0.05, opacity: isHovered ? 0.95 : 0.65), Color.purple.opacity(isHovered ? 0.70 : 0.35), Color.clear],
                    center: .center,
                    startRadius: size * 0.22,
                    endRadius: size * 0.90
                )
                .frame(width: size * 1.5, height: size * 1.5)
                .blur(radius: 11)
            }

            // 22. TOKYO NEON RAIN 🌧️
            if theme == "Tokyo Neon Rain" {
                RadialGradient(
                    colors: [Color.pink.opacity(isHovered ? 0.90 : 0.60), Color.blue.opacity(isHovered ? 0.75 : 0.40), Color.clear],
                    center: .center,
                    startRadius: size * 0.15,
                    endRadius: size * 0.88
                )
                .frame(width: size * 1.45, height: size * 1.45)
                .blur(radius: 10)
            }

            // 23. BIOLUMINESCENT ABYSSAL 🪼
            if theme == "Bioluminescent Abyssal" {
                RadialGradient(
                    colors: [Color.teal.opacity(isHovered ? 0.95 : 0.65), Color(red: 0.0, green: 0.3, blue: 0.6, opacity: 0.5), Color.clear],
                    center: .center,
                    startRadius: size * 0.15,
                    endRadius: size * 0.88
                )
                .frame(width: size * 1.45, height: size * 1.45)
                .blur(radius: 10)
            }

            // 24. SAKURA BLOSSOM DRIFT 🌸
            if theme == "Sakura Blossom Drift" {
                RadialGradient(
                    colors: [Color(red: 1.0, green: 0.70, blue: 0.82, opacity: isHovered ? 0.90 : 0.55), Color(red: 1.0, green: 0.40, blue: 0.60, opacity: 0.35), Color.clear],
                    center: .center,
                    startRadius: size * 0.15,
                    endRadius: size * 0.88
                )
                .frame(width: size * 1.4, height: size * 1.4)
                .blur(radius: 9)
            }

            // 25. FIREFLY ENCHANTED FOREST 🌲
            if theme == "Firefly Enchanted Forest" {
                RadialGradient(
                    colors: [Color(red: 0.9, green: 1.0, blue: 0.3, opacity: isHovered ? 0.95 : 0.60), Color(red: 0.1, green: 0.5, blue: 0.2, opacity: 0.4), Color.clear],
                    center: .center,
                    startRadius: size * 0.15,
                    endRadius: size * 0.88
                )
                .frame(width: size * 1.45, height: size * 1.45)
                .blur(radius: 10)
            }

            // 26. CELESTIAL AURORA 🌌
            if theme == "Celestial Aurora" {
                RadialGradient(
                    colors: [Color.green.opacity(isHovered ? 0.90 : 0.55), Color.purple.opacity(isHovered ? 0.70 : 0.35), Color.clear],
                    center: .center,
                    startRadius: size * 0.15,
                    endRadius: size * 0.90
                )
                .frame(width: size * 1.48, height: size * 1.48)
                .blur(radius: 11)
            }

            // 27. OCEAN CAUSTICS 🌊
            if theme == "Ocean Caustics" {
                RadialGradient(
                    colors: [Color.cyan.opacity(isHovered ? 0.95 : 0.65), Color.blue.opacity(0.4), Color.clear],
                    center: .center,
                    startRadius: size * 0.15,
                    endRadius: size * 0.88
                )
                .frame(width: size * 1.45, height: size * 1.45)
                .blur(radius: 10)
            }

            // 28. DESERT SOLAR MIRAGE 🏜️
            if theme == "Desert Solar Mirage" {
                RadialGradient(
                    colors: [Color(red: 1.0, green: 0.75, blue: 0.25, opacity: isHovered ? 0.95 : 0.65), Color.orange.opacity(0.4), Color.clear],
                    center: .center,
                    startRadius: size * 0.15,
                    endRadius: size * 0.88
                )
                .frame(width: size * 1.45, height: size * 1.45)
                .blur(radius: 10)
            }

            // 29. VOLCANIC OBSIDIAN LAVA 🌋
            if theme == "Volcanic Obsidian Lava" {
                RadialGradient(
                    colors: [Color.red.opacity(isHovered ? 0.95 : 0.70), Color.orange.opacity(0.5), Color.clear],
                    center: .center,
                    startRadius: size * 0.15,
                    endRadius: size * 0.88
                )
                .frame(width: size * 1.45, height: size * 1.45)
                .blur(radius: 10)
            }

            // 30. CRT PHOSPHOR TERMINAL 📺
            if theme == "CRT Phosphor Terminal" {
                RadialGradient(
                    colors: [Color(red: 1.0, green: 0.65, blue: 0.0, opacity: isHovered ? 0.90 : 0.55), Color.clear],
                    center: .center,
                    startRadius: size * 0.18,
                    endRadius: size * 0.85
                )
                .frame(width: size * 1.4, height: size * 1.4)
                .blur(radius: 8)
            }

            // 31. GAMEBOY DOT MATRIX 👾
            if theme == "GameBoy Dot Matrix" {
                RadialGradient(
                    colors: [Color(red: 0.60, green: 0.74, blue: 0.12, opacity: isHovered ? 0.90 : 0.55), Color.clear],
                    center: .center,
                    startRadius: size * 0.15,
                    endRadius: size * 0.85
                )
                .frame(width: size * 1.4, height: size * 1.4)
                .blur(radius: 8)
            }

            // 32. TRON VECTOR GRID 🏍️
            if theme == "Tron Vector Grid" {
                RadialGradient(
                    colors: [Color.cyan.opacity(isHovered ? 0.95 : 0.60), Color.blue.opacity(0.4), Color.clear],
                    center: .center,
                    startRadius: size * 0.15,
                    endRadius: size * 0.88
                )
                .frame(width: size * 1.45, height: size * 1.45)
                .blur(radius: 9)
            }

            // 33. STEAMPUNK BRASS GEARS ⚙️
            if theme == "Steampunk Brass Gears" {
                RadialGradient(
                    colors: [Color(red: 0.85, green: 0.60, blue: 0.20, opacity: isHovered ? 0.90 : 0.55), Color.brown.opacity(0.4), Color.clear],
                    center: .center,
                    startRadius: size * 0.15,
                    endRadius: size * 0.85
                )
                .frame(width: size * 1.4, height: size * 1.4)
                .blur(radius: 8)
            }

            // 34. FROST GLASS ACRYLIC / TRANSLUCENT 🪟
            if theme == "Frost Glass Acrylic" || theme == "Translucent" {
                RadialGradient(
                    colors: [Color.white.opacity(isHovered ? 0.85 : 0.45), Color.cyan.opacity(0.3), Color.clear],
                    center: .topLeading,
                    startRadius: size * 0.1,
                    endRadius: size * 0.88
                )
                .frame(width: size * 1.4, height: size * 1.4)
                .blur(radius: 8)
            }

            // 35. MONOCHROME STUDIO ⚪️
            if theme == "Monochrome Studio" {
                RadialGradient(
                    colors: [Color.white.opacity(isHovered ? 0.80 : 0.40), Color.clear],
                    center: .center,
                    startRadius: size * 0.1,
                    endRadius: size * 0.85
                )
                .frame(width: size * 1.35, height: size * 1.35)
                .blur(radius: 7)
            }

            // 36. GOLDEN KINTSUGI 🏺
            if theme == "Golden Kintsugi" {
                RadialGradient(
                    colors: [Color.yellow.opacity(isHovered ? 0.95 : 0.65), Color.orange.opacity(0.4), Color.clear],
                    center: .center,
                    startRadius: size * 0.15,
                    endRadius: size * 0.88
                )
                .frame(width: size * 1.45, height: size * 1.45)
                .blur(radius: 9)
            }

            // BASE APP ICON RENDERING WITH THEME SHADERS & 3D ROTATION ENGINE
            Image(nsImage: icon)
                .interpolation(.high)
                .antialiased(true)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
                .modifier(ThemeFilterModifier(theme: theme, tintColor: parsedTintColor, isHovered: isHovered))
                .rotation3DEffect(
                    .degrees(spin3DAngle),
                    axis: spin3DAxis,
                    perspective: 0.55
                )
                .shadow(
                    color: shadowColor,
                    radius: isHovered ? 20 : 4,
                    x: 0,
                    y: isHovered ? 12 : 2
                )

            // 10+ ILLUSTRATED ICON SNUGGIES & APPAREL WRAPPERS 🐱🧣
            if iconSnuggie != "None" {
                iconSnuggieOverlay(size: size)
            }
        }
    }

    @ViewBuilder
    private func iconSnuggieOverlay(size: CGFloat) -> some View {
        switch iconSnuggie {
        case "Sleeping Kitty 🐱":
            // Sleeping Calico / Orange Cat draped along the top edge with swaying tail
            ZStack {
                let catW = size * 0.72
                let catH = size * 0.26
                let tailSway = sin(flamePhase * 3.5) * 3.5

                // Soft furry sleeping cat body
                RoundedRectangle(cornerRadius: catH * 0.5, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.orange, Color(red: 0.95, green: 0.55, blue: 0.20), Color(red: 0.90, green: 0.40, blue: 0.10)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: catW, height: catH)
                    .overlay(
                        RoundedRectangle(cornerRadius: catH * 0.5, style: .continuous)
                            .stroke(Color.white.opacity(0.45), lineWidth: 0.8)
                    )
                    .offset(x: 0, y: -size * 0.46)
                    .shadow(color: Color.black.opacity(0.35), radius: 2, x: 0, y: 1)

                // Left & Right Cat Ears
                Path { p in
                    p.move(to: CGPoint(x: (size - catW) / 2 + 4, y: -size * 0.46 + 4))
                    p.addLine(to: CGPoint(x: (size - catW) / 2 + 10, y: -size * 0.46 - 8))
                    p.addLine(to: CGPoint(x: (size - catW) / 2 + 16, y: -size * 0.46 + 4))
                    p.closeSubpath()
                }
                .fill(Color.orange)

                Path { p in
                    p.move(to: CGPoint(x: (size + catW) / 2 - 16, y: -size * 0.46 + 4))
                    p.addLine(to: CGPoint(x: (size + catW) / 2 - 10, y: -size * 0.46 - 8))
                    p.addLine(to: CGPoint(x: (size + catW) / 2 - 4, y: -size * 0.46 + 4))
                    p.closeSubpath()
                }
                .fill(Color.orange)

                // Swaying tail curled around the right edge
                Path { p in
                    p.move(to: CGPoint(x: size * 0.38, y: -size * 0.38))
                    p.addQuadCurve(
                        to: CGPoint(x: size * 0.52 + CGFloat(tailSway), y: size * 0.20),
                        control: CGPoint(x: size * 0.56, y: -size * 0.10)
                    )
                }
                .stroke(Color.orange, style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                .shadow(color: Color.black.opacity(0.25), radius: 1.5, x: 1, y: 1)
            }

        case "Fox & Tail 🦊":
            // Curled Red Fox with bushy tail wrapping the bottom-left corner
            ZStack {
                let foxW = size * 0.70
                let foxH = size * 0.25

                RoundedRectangle(cornerRadius: foxH * 0.5, style: .continuous)
                    .fill(Color(red: 0.92, green: 0.36, blue: 0.12))
                    .frame(width: foxW, height: foxH)
                    .offset(x: 0, y: -size * 0.46)

                // White Muzzle & Dark Ears
                Circle()
                    .fill(Color.white.opacity(0.9))
                    .frame(width: 8, height: 8)
                    .offset(x: 0, y: -size * 0.44)

                // Bushy Tail curled around bottom corner
                Path { p in
                    p.move(to: CGPoint(x: -size * 0.36, y: -size * 0.35))
                    p.addQuadCurve(
                        to: CGPoint(x: -size * 0.10, y: size * 0.52),
                        control: CGPoint(x: -size * 0.56, y: size * 0.30)
                    )
                }
                .stroke(
                    LinearGradient(colors: [Color(red: 0.92, green: 0.36, blue: 0.12), Color.white], startPoint: .top, endPoint: .bottom),
                    style: StrokeStyle(lineWidth: 5.5, lineCap: .round)
                )
                .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
            }

        case "Panda Hug 🐼":
            // Little panda hugging the icon with paws wrapped around borders
            ZStack {
                // Panda Ears
                Circle()
                    .fill(Color.black)
                    .frame(width: size * 0.20, height: size * 0.20)
                    .offset(x: -size * 0.38, y: -size * 0.48)

                Circle()
                    .fill(Color.black)
                    .frame(width: size * 0.20, height: size * 0.20)
                    .offset(x: size * 0.38, y: -size * 0.48)

                // Panda Top Face Arc
                Path { p in
                    p.addArc(center: CGPoint(x: 0, y: -size * 0.38), radius: size * 0.32, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
                }
                .fill(Color.white)
                .frame(width: size, height: size)

                // Left & Right Hugging Paws
                Capsule()
                    .fill(Color.black)
                    .frame(width: size * 0.16, height: size * 0.22)
                    .offset(x: -size * 0.48, y: -size * 0.10)

                Capsule()
                    .fill(Color.black)
                    .frame(width: size * 0.16, height: size * 0.22)
                    .offset(x: size * 0.48, y: -size * 0.10)
            }

        case "Winter Scarf 🧣":
            // Knit woolen scarf wrapped along the icon base
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color(red: 0.85, green: 0.15, blue: 0.25), Color(red: 0.95, green: 0.35, blue: 0.40), Color(red: 0.85, green: 0.15, blue: 0.25)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: size * 1.06, height: size * 0.24)
                    .offset(y: size * 0.08)
                    .shadow(color: Color.black.opacity(0.35), radius: 3, x: 0, y: 2)

                // Dangling fringe
                Path { p in
                    p.move(to: CGPoint(x: size * 0.28, y: size * 0.50))
                    p.addLine(to: CGPoint(x: size * 0.36, y: size * 0.68))
                }
                .stroke(Color(red: 0.85, green: 0.15, blue: 0.25), style: StrokeStyle(lineWidth: 4, lineCap: .round))
            }

        case "Cyber Frame ⚡️":
            // Glowing sci-fi cyber brackets & neon corner nodes
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                    .stroke(
                        LinearGradient(colors: [Color.cyan, Color.purple, Color.cyan], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 1.8
                    )
                    .frame(width: size * 1.08, height: size * 1.08)
                    .shadow(color: Color.cyan.opacity(isHovered ? 0.95 : 0.60), radius: isHovered ? 8 : 4)

                // 4 Corner brackets
                ForEach([(-1.0, -1.0), (1.0, -1.0), (-1.0, 1.0), (1.0, 1.0)], id: \.0) { cx, cy in
                    Circle()
                        .fill(Color.white)
                        .frame(width: 4, height: 4)
                        .shadow(color: Color.cyan, radius: 3)
                        .offset(x: CGFloat(cx) * (size * 0.54), y: CGFloat(cy) * (size * 0.54))
                }
            }

        case "Living Vines 🌿":
            // Lush botanical ivy vines creeping around the icon
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                    .stroke(Color.green.opacity(0.75), lineWidth: 2.0)
                    .frame(width: size * 1.06, height: size * 1.06)

                // Tiny leaves & blossoms
                ForEach(0..<6) { i in
                    let angle = Double(i) * 60.0
                    Circle()
                        .fill((i % 2 == 0) ? Color(red: 0.4, green: 0.9, blue: 0.3) : Color(red: 1.0, green: 0.6, blue: 0.8))
                        .frame(width: 5, height: 5)
                        .offset(
                            x: CGFloat(cos(angle * .pi / 180.0)) * (size * 0.54),
                            y: CGFloat(sin(angle * .pi / 180.0)) * (size * 0.54)
                        )
                }
            }

        case "Coral Reef Ring 🪸":
            // Marine sea anemone ring with shimmering bubbles
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                    .stroke(
                        LinearGradient(colors: [Color.cyan, Color.blue, Color(red: 0.2, green: 0.8, blue: 0.9)], startPoint: .top, endPoint: .bottom),
                        lineWidth: 2.2
                    )
                    .frame(width: size * 1.08, height: size * 1.08)
                    .shadow(color: Color.cyan.opacity(0.6), radius: 5)

                ForEach(0..<8) { b in
                    let bAngle = Double(b) * 45.0 + flamePhase * 40.0
                    Circle()
                        .fill(Color.white.opacity(0.85))
                        .frame(width: 3.5, height: 3.5)
                        .offset(
                            x: CGFloat(cos(bAngle * .pi / 180.0)) * (size * 0.55),
                            y: CGFloat(sin(bAngle * .pi / 180.0)) * (size * 0.55)
                        )
                }
            }

        case "Diamond Bezel 💎":
            // Sparkling diamond crystal facet bezel
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                    .stroke(
                        LinearGradient(colors: [Color.white, Color.cyan.opacity(0.5), Color.white], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 2.5
                    )
                    .frame(width: size * 1.08, height: size * 1.08)
                    .shadow(color: Color.white.opacity(isHovered ? 0.9 : 0.4), radius: isHovered ? 8 : 3)
            }

        case "Flame Corona 🔥":
            // Fiery solar plasma tongues
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                    .stroke(
                        LinearGradient(colors: [Color.yellow, Color.orange, Color.red, Color.yellow], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 2.5
                    )
                    .frame(width: size * 1.10, height: size * 1.10)
                    .shadow(color: Color.orange.opacity(isHovered ? 0.95 : 0.65), radius: isHovered ? 12 : 6)
            }

        case "Sakura Wreath 🌸":
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                    .stroke(Color(red: 1.0, green: 0.65, blue: 0.80).opacity(0.85), lineWidth: 2.2)
                    .frame(width: size * 1.08, height: size * 1.08)
                ForEach(0..<8) { idx in
                    let angle = Double(idx) * 45.0
                    Circle()
                        .fill(Color(red: 1.0, green: 0.75, blue: 0.85))
                        .frame(width: 5.5, height: 5.5)
                        .offset(x: CGFloat(cos(angle * .pi / 180.0)) * (size * 0.54), y: CGFloat(sin(angle * .pi / 180.0)) * (size * 0.54))
                }
            }

        case "Dragon Scales 🐉":
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                    .stroke(
                        LinearGradient(colors: [Color.yellow, Color.green, Color.yellow], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 2.5
                    )
                    .frame(width: size * 1.08, height: size * 1.08)
                Path { p in
                    p.move(to: CGPoint(x: -size * 0.30, y: -size * 0.46))
                    p.addLine(to: CGPoint(x: -size * 0.38, y: -size * 0.58))
                    p.addLine(to: CGPoint(x: -size * 0.22, y: -size * 0.46))
                    p.closeSubpath()
                }
                .fill(Color.yellow)
                Path { p in
                    p.move(to: CGPoint(x: size * 0.30, y: -size * 0.46))
                    p.addLine(to: CGPoint(x: size * 0.38, y: -size * 0.58))
                    p.addLine(to: CGPoint(x: size * 0.22, y: -size * 0.46))
                    p.closeSubpath()
                }
                .fill(Color.yellow)
            }

        case "Astronaut Visor 👨‍🚀":
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.26, style: .continuous)
                    .stroke(Color.white.opacity(0.9), lineWidth: 3.0)
                    .frame(width: size * 1.10, height: size * 1.10)
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(Color(red: 1.0, green: 0.75, blue: 0.15).opacity(0.85))
                    .frame(width: size * 0.75, height: size * 0.16)
                    .offset(y: -size * 0.36)
            }

        case "Sprout Leaf 🌱":
            ZStack {
                Path { p in
                    p.move(to: CGPoint(x: 0, y: -size * 0.44))
                    p.addLine(to: CGPoint(x: 0, y: -size * 0.58))
                }
                .stroke(Color.green, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                Circle()
                    .fill(Color(red: 0.4, green: 0.9, blue: 0.3))
                    .frame(width: 8, height: 6)
                    .offset(x: -4, y: -size * 0.60)
                Circle()
                    .fill(Color(red: 0.4, green: 0.9, blue: 0.3))
                    .frame(width: 8, height: 6)
                    .offset(x: 4, y: -size * 0.60)
            }

        case "Imperial Crown 👑":
            ZStack {
                Path { p in
                    p.move(to: CGPoint(x: -size * 0.35, y: -size * 0.44))
                    p.addLine(to: CGPoint(x: -size * 0.40, y: -size * 0.62))
                    p.addLine(to: CGPoint(x: -size * 0.18, y: -size * 0.52))
                    p.addLine(to: CGPoint(x: 0, y: -size * 0.66))
                    p.addLine(to: CGPoint(x: size * 0.18, y: -size * 0.52))
                    p.addLine(to: CGPoint(x: size * 0.40, y: -size * 0.62))
                    p.addLine(to: CGPoint(x: size * 0.35, y: -size * 0.44))
                    p.closeSubpath()
                }
                .fill(
                    LinearGradient(colors: [Color.yellow, Color.orange, Color.yellow], startPoint: .leading, endPoint: .trailing)
                )
                .shadow(color: Color.orange.opacity(0.6), radius: 3)
            }

        case "Cyber Samurai Mask 🥷":
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                    .stroke(
                        LinearGradient(colors: [Color.cyan, Color.red, Color.cyan], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 2.2
                    )
                    .frame(width: size * 1.08, height: size * 1.08)
                // Horns & Visor
                Path { p in
                    p.move(to: CGPoint(x: -size * 0.32, y: -size * 0.44))
                    p.addLine(to: CGPoint(x: -size * 0.44, y: -size * 0.62))
                    p.addLine(to: CGPoint(x: -size * 0.22, y: -size * 0.48))
                    p.closeSubpath()
                }
                .fill(Color.red)
                Path { p in
                    p.move(to: CGPoint(x: size * 0.32, y: -size * 0.44))
                    p.addLine(to: CGPoint(x: size * 0.44, y: -size * 0.62))
                    p.addLine(to: CGPoint(x: size * 0.22, y: -size * 0.48))
                    p.closeSubpath()
                }
                .fill(Color.red)
            }

        case "Sakura Shinto Gate ⛩️":
            ZStack(alignment: .top) {
                // Vermillion Torii Top Beam
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Color(red: 0.90, green: 0.20, blue: 0.15))
                    .frame(width: size * 1.22, height: size * 0.12)
                    .offset(y: -size * 0.52)
                    .shadow(color: Color.black.opacity(0.3), radius: 2)

                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .fill(Color(red: 0.80, green: 0.15, blue: 0.10))
                    .frame(width: size * 1.08, height: size * 0.08)
                    .offset(y: -size * 0.38)
            }

        case "Pixel Heart Armor ❤️":
            ZStack {
                // Outer 8-Bit Pixelated Border
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .stroke(
                        LinearGradient(colors: [Color.pink, Color.red, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing),
                        lineWidth: 2.5
                    )
                    .frame(width: size * 1.10, height: size * 1.10)
                    .shadow(color: Color.pink.opacity(0.8), radius: 4)

                // 8-Bit Glowing Crest Heart at top right
                Image(systemName: "heart.fill")
                    .font(.system(size: size * 0.28, weight: .black))
                    .foregroundColor(.pink)
                    .offset(x: size * 0.42, y: -size * 0.42)
                    .shadow(color: Color.red, radius: 4)

                // Corner Pixel Rivets
                Circle().fill(Color.white).frame(width: 3, height: 3).offset(x: -size * 0.50, y: -size * 0.50)
                Circle().fill(Color.white).frame(width: 3, height: 3).offset(x: -size * 0.50, y: size * 0.50)
                Circle().fill(Color.white).frame(width: 3, height: 3).offset(x: size * 0.50, y: size * 0.50)
            }

        case "Golden Halo Corona 😇":
            ZStack {
                Circle()
                    .stroke(
                        LinearGradient(colors: [Color.yellow, Color.white, Color.yellow], startPoint: .top, endPoint: .bottom),
                        lineWidth: 3.0
                    )
                    .frame(width: size * 0.70, height: size * 0.25)
                    .offset(y: -size * 0.55)
                    .shadow(color: Color.yellow.opacity(0.9), radius: 6)
            }

        case "Ice Cream Cone 🍦":
            // Mini waffle cone perched at the top corner with dripping soft serve & sprinkles
            ZStack {
                // Strawberry scoop
                Circle()
                    .fill(Color(red: 1.0, green: 0.55, blue: 0.70))
                    .frame(width: size * 0.32, height: size * 0.32)
                    .offset(x: size * 0.34, y: -size * 0.54)
                    .shadow(color: Color.black.opacity(0.25), radius: 2)

                // Mint scoop
                Circle()
                    .fill(Color(red: 0.55, green: 0.95, blue: 0.85))
                    .frame(width: size * 0.26, height: size * 0.26)
                    .offset(x: size * 0.24, y: -size * 0.44)

                // Waffle Cone
                Path { p in
                    p.move(to: CGPoint(x: size * 0.22, y: -size * 0.40))
                    p.addLine(to: CGPoint(x: size * 0.44, y: -size * 0.40))
                    p.addLine(to: CGPoint(x: size * 0.33, y: -size * 0.18))
                    p.closeSubpath()
                }
                .fill(Color(red: 0.88, green: 0.65, blue: 0.35))
                .overlay(
                    Path { p in
                        p.move(to: CGPoint(x: size * 0.22, y: -size * 0.40))
                        p.addLine(to: CGPoint(x: size * 0.44, y: -size * 0.40))
                        p.addLine(to: CGPoint(x: size * 0.33, y: -size * 0.18))
                        p.closeSubpath()
                    }
                    .stroke(Color(red: 0.65, green: 0.42, blue: 0.18), lineWidth: 0.8)
                )

                // Sprinkles on scoop
                ForEach(0..<5) { sp in
                    let colors: [Color] = [.white, .yellow, .cyan, .red, .green]
                    Capsule()
                        .fill(colors[sp % colors.count])
                        .frame(width: 4, height: 1.8)
                        .rotationEffect(.degrees(Double(sp * 35)))
                        .offset(x: size * 0.32 + CGFloat((sp - 2) * 3), y: -size * 0.54 + CGFloat((sp % 3 - 1) * 3))
                }
            }

        default:
            EmptyView()
        }
    }

    private var shadowColor: Color {
        switch theme {
        case "3D Hologram Spinner", "3D Hypercube 4D": return Color.cyan.opacity(isHovered ? 0.95 : 0.45)
        case "3D Coin Flip", "3D Kinetic Gyroscope": return Color.yellow.opacity(isHovered ? 0.95 : 0.45)
        case "3D Quantum Vortex", "3D Diamond Facet": return Color.purple.opacity(isHovered ? 0.95 : 0.45)
        case "3D Skater Kickflip", "3D Orbiting Satellites": return Color.orange.opacity(isHovered ? 0.95 : 0.45)
        case "Genie Gold 24K", "Gold Gate", "Golden Kintsugi": return Color(red: 1.0, green: 0.75, blue: 0.20).opacity(isHovered ? 0.90 : 0.40)
        case "Wallpaper Camouflage", "Frost Glass Acrylic", "Monochrome Studio": return Color.white.opacity(isHovered ? 0.60 : 0.15)
        case "4K Ultra-HD Marine Caustics", "Ocean Caustics": return Color.cyan.opacity(isHovered ? 0.90 : 0.40)
        case "Pacific Ocean Dolphins": return Color(red: 0.2, green: 0.6, blue: 1.0).opacity(isHovered ? 0.85 : 0.35)
        case "Coral Reef Aquaria": return Color.orange.opacity(isHovered ? 0.85 : 0.35)
        case "Deep Sea Manta": return Color(red: 0.1, green: 0.3, blue: 0.7).opacity(isHovered ? 0.85 : 0.35)
        case "Street Skater & Grip Tape", "Skate Punk Stickers": return Color.orange.opacity(isHovered ? 0.90 : 0.40)
        case "Pop Punk Artist": return Color(red: 1.0, green: 0.08, blue: 0.58).opacity(isHovered ? 0.95 : 0.50)
        case "Ice Cream Dream": return Color(red: 1.0, green: 0.65, blue: 0.80).opacity(isHovered ? 0.90 : 0.45)
        case "Thrasher Flame", "Volcanic Obsidian Lava": return Color.red.opacity(isHovered ? 0.95 : 0.45)
        case "Venice Beach Halfpipe", "Sakura Blossom Drift": return Color.pink.opacity(isHovered ? 0.85 : 0.35)
        case "Cyber Deck", "Tron Vector Grid": return Color.teal.opacity(isHovered ? 0.85 : 0.35)
        case "Inferno": return Color.red.opacity(isHovered ? 0.85 : 0.35)
        case "Cyberpunk", "Electric Lightning Plasma": return Color.cyan.opacity(isHovered ? 0.80 : 0.30)
        case "Matrix", "HUD Tactical Combat": return Color.green.opacity(isHovered ? 0.80 : 0.30)
        case "Solar Flare", "Desert Solar Mirage": return Color.orange.opacity(isHovered ? 0.85 : 0.30)
        case "Frost Glaze": return Color.blue.opacity(isHovered ? 0.80 : 0.30)
        case "Void", "Black Hole Singularity": return Color.purple.opacity(isHovered ? 0.85 : 0.35)
        case "Quantum Prism", "Holographic Chromatic Prism": return Color.pink.opacity(isHovered ? 0.80 : 0.30)
        case "Toxic Plasma", "Bio-Organic Flora", "Firefly Enchanted Forest": return Color.green.opacity(isHovered ? 0.85 : 0.35)
        case "Supernova": return Color.orange.opacity(isHovered ? 0.85 : 0.35)
        case "Midnight Gold": return Color.yellow.opacity(isHovered ? 0.80 : 0.30)
        case "Synthwave", "Tokyo Neon Rain": return Color.purple.opacity(isHovered ? 0.85 : 0.35)
        case "Neon Vaporwave": return Color.pink.opacity(isHovered ? 0.85 : 0.35)
        case "Diamond Crystal Glass": return Color.cyan.opacity(isHovered ? 0.80 : 0.30)
        case "Arcane Rune", "Celestial Aurora": return Color.purple.opacity(isHovered ? 0.85 : 0.35)
        case "Liquid Chrome": return Color.white.opacity(isHovered ? 0.80 : 0.30)
        case "CRT Phosphor Terminal", "GameBoy Dot Matrix": return Color.orange.opacity(isHovered ? 0.80 : 0.30)
        case "Steampunk Brass Gears": return Color(red: 0.85, green: 0.60, blue: 0.20).opacity(isHovered ? 0.85 : 0.35)
        case "Bioluminescent Abyssal": return Color.teal.opacity(isHovered ? 0.90 : 0.40)
        default: return Color.black.opacity(isHovered ? 0.48 : 0.18)
        }
    }
}

// MARK: - Theme Filter Modifier

struct ThemeFilterModifier: ViewModifier {
let theme: String
    let tintColor: Color
    var isHovered: Bool = false

    @ViewBuilder
    func body(content: Content) -> some View {
        switch theme {
        case "4K Ultra-HD Marine Caustics", "Ocean Caustics":
            content
                .colorMultiply(Color(red: 0.85, green: 1.05, blue: 1.15))
                .contrast(1.25)
                .brightness(isHovered ? 0.08 : 0.02)

        case "Pacific Ocean Dolphins":
            content
                .colorMultiply(Color(red: 0.90, green: 1.02, blue: 1.12))
                .contrast(1.20)
                .brightness(isHovered ? 0.06 : 0.0)

        case "Coral Reef Aquaria":
            content
                .saturation(1.30)
                .contrast(1.18)
                .brightness(isHovered ? 0.05 : 0.0)

        case "Deep Sea Manta", "Bioluminescent Abyssal":
            content
                .colorMultiply(Color(red: 0.82, green: 0.92, blue: 1.15))
                .contrast(1.28)

        case "Street Skater & Grip Tape":
            content
                .contrast(1.35)
                .brightness(-0.04)

        case "Thrasher Flame", "Volcanic Obsidian Lava":
            content
                .colorMultiply(Color(red: 1.15, green: 0.95, blue: 0.70))
                .contrast(1.25)
                .brightness(isHovered ? 0.08 : 0.02)

        case "Venice Beach Halfpipe", "Sakura Blossom Drift":
            content
                .saturation(1.25)
                .colorMultiply(Color(red: 0.95, green: 1.05, blue: 1.08))
                .contrast(1.15)

        case "Cyber Deck", "Tron Vector Grid":
            content
                .colorMultiply(Color(red: 0.85, green: 1.10, blue: 1.10))
                .contrast(1.26)

        case "Genie Gold 24K", "Gold Gate", "Golden Kintsugi":
            content
                .colorMultiply(Color(red: 1.05, green: 0.95, blue: 0.70))
                .contrast(1.22)
                .brightness(isHovered ? 0.08 : 0.02)

        case "Wallpaper Camouflage":
            content
                .opacity(isHovered ? 1.0 : 0.65)
                .contrast(isHovered ? 1.15 : 1.25)
                .brightness(isHovered ? 0.05 : 0.0)

        case "Dark":
            content
                .colorMultiply(Color(white: 0.72))
                .contrast(1.25)
                .brightness(-0.08)

        case "Translucent", "Clear", "Frost Glass Acrylic", "Monochrome Studio":
            content
                .saturation(0.0)
                .opacity(0.85)

        case "Tinted":
            content
                .saturation(0.2)
                .colorMultiply(tintColor.opacity(0.88))
                .contrast(1.15)

        case "Vintage Aqua":
            content
                .saturation(1.35)
                .colorMultiply(Color(red: 0.80, green: 1.05, blue: 1.10))
                .contrast(1.15)

        case "iOS Minimal":
            content
                .saturation(1.25)
                .contrast(1.05)

        case "Inferno":
            content
                .colorMultiply(Color(red: 1.05, green: 0.90, blue: 0.75))
                .contrast(1.18)

        case "Cyberpunk", "Electric Lightning Plasma":
            content
                .colorMultiply(Color(red: 0.90, green: 1.05, blue: 1.15))
                .contrast(1.22)

        case "Matrix", "HUD Tactical Combat":
            content
                .saturation(0.2)
                .colorMultiply(Color.green)
                .contrast(1.3)

        case "Solar Flare", "Desert Solar Mirage":
            content
                .colorMultiply(Color(red: 1.10, green: 1.0, blue: 0.70))
                .contrast(1.15)

        case "Frost Glaze":
            content
                .colorMultiply(Color(red: 0.75, green: 0.92, blue: 1.15))
                .contrast(1.2)

        case "Void", "Black Hole Singularity":
            content
                .colorMultiply(Color(red: 0.80, green: 0.70, blue: 1.15))
                .contrast(1.35)

        case "Quantum Prism", "Holographic Chromatic Prism":
            content
                .colorMultiply(Color(red: 1.05, green: 1.05, blue: 1.10))
                .contrast(1.20)

        case "Toxic Plasma", "Firefly Enchanted Forest":
            content
                .colorMultiply(Color(red: 0.80, green: 1.15, blue: 0.85))
                .contrast(1.28)

        case "Supernova":
            content
                .colorMultiply(Color(red: 1.15, green: 0.95, blue: 0.85))
                .contrast(1.25)

        case "Midnight Gold":
            content
                .colorMultiply(Color(red: 1.10, green: 0.98, blue: 0.70))
                .contrast(1.22)

        case "8-Bit Arcade", "GameBoy Dot Matrix":
            content
                .saturation(1.4)
                .contrast(1.35)

        case "Synthwave", "Tokyo Neon Rain":
            content
                .saturation(1.3)
                .colorMultiply(Color(red: 1.15, green: 0.85, blue: 1.10))
                .contrast(1.25)

        case "Neon Vaporwave":
            content
                .saturation(1.25)
                .colorMultiply(Color(red: 0.90, green: 1.10, blue: 1.15))
                .contrast(1.2)

        case "Cyber Noir":
            content
                .saturation(0.0)
                .contrast(1.45)
                .brightness(0.05)

        case "Celestial Twilight", "Celestial Aurora":
            content
                .saturation(1.15)
                .colorMultiply(Color(red: 0.85, green: 0.85, blue: 1.20))
                .contrast(1.25)

        case "Diamond Crystal Glass":
            content
                .contrast(1.30)
                .brightness(0.08)

        case "Arcane Rune":
            content
                .colorMultiply(Color(red: 0.95, green: 0.80, blue: 1.25))
                .contrast(1.25)

        case "Bio-Organic Flora":
            content
                .colorMultiply(Color(red: 0.85, green: 1.15, blue: 0.85))
                .contrast(1.20)

        case "Liquid Chrome":
            content
                .saturation(0.15)
                .contrast(1.40)
                .brightness(0.10)

        case "CRT Phosphor Terminal":
            content
                .saturation(0.15)
                .colorMultiply(Color(red: 1.10, green: 0.75, blue: 0.15))
                .contrast(1.35)

        case "Steampunk Brass Gears":
            content
                .colorMultiply(Color(red: 1.08, green: 0.88, blue: 0.65))
                .contrast(1.25)

        case "3D Hologram Spinner", "3D Hypercube 4D":
            content
                .colorMultiply(Color(red: 0.85, green: 1.10, blue: 1.25))
                .contrast(1.25)
                .brightness(isHovered ? 0.12 : 0.04)

        case "3D Coin Flip", "3D Kinetic Gyroscope":
            content
                .colorMultiply(Color(red: 1.15, green: 1.02, blue: 0.75))
                .contrast(1.22)
                .brightness(isHovered ? 0.10 : 0.02)

        case "3D Quantum Vortex", "3D Diamond Facet":
            content
                .colorMultiply(Color(red: 1.05, green: 0.95, blue: 1.20))
                .contrast(1.28)
                .brightness(isHovered ? 0.12 : 0.05)

        case "3D Skater Kickflip", "3D Orbiting Satellites":
            content
                .colorMultiply(Color(red: 1.15, green: 0.95, blue: 0.85))
                .contrast(1.25)
                .brightness(isHovered ? 0.10 : 0.03)

        case "Pop Punk Artist":
            content
                .saturation(1.45)
                .contrast(1.30)
                .colorMultiply(Color(red: 1.10, green: 0.85, blue: 1.15)) // Hot punk saturation
                .brightness(isHovered ? 0.08 : 0.02)

        case "Skate Punk Stickers":
            content
                .contrast(1.40)
                .saturation(1.20)
                .brightness(isHovered ? 0.06 : 0.0)

        case "Ice Cream Dream":
            content
                .saturation(1.25)
                .colorMultiply(Color(red: 1.05, green: 0.95, blue: 1.08)) // Pastel cream
                .brightness(isHovered ? 0.09 : 0.03)

        default:
            content
        }
    }
}
