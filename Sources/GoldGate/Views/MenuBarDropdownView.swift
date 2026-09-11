import AppKit
import SwiftUI

// MARK: - Flagship Sidebar Navigation & Dynamic Master-Detail Control Center

enum DropdownSidebarTab: String, CaseIterable, Identifiable {
    // Flagship Intelligence (First Page)
    case chat = "Genie Chat"

    // Spatial Canvas & Applications
    case applications = "Applications"
    case workspace = "Desktop Spaces"
    case formations = "Grid Formations"

    // Intelligence & Settings
    case aiModels = "AI Models & Keys"
    case virtualMachines = "AI Stations & Virtual Machines"
    case expansion = "Feature Packs"
    case system = "General Settings"
    case privacy = "Privacy & Permissions"

    // Appearance & Finishes
    case themes = "Themes & Appearance"
    case snuggies = "Window Housings"
    case typography = "Typography & Fonts"
    case wallpapers = "Wallpapers & Shaders"

    // Controls & Hardware
    case trackpad = "Gestures & Shortcuts"
    case soundHaptics = "Sound & Haptics"
    case petsAndPinball = "Interactive Widgets"
    case menuBar = "Menu Bar & Docks"
    case battery = "Battery Indicator"

    // Utilities
    case worldClock = "World Clock"

    var id: String { rawValue }

    init(caseInsensitive raw: String) {
        if let match = DropdownSidebarTab.allCases.first(where: { $0.rawValue.caseInsensitiveCompare(raw) == .orderedSame }) {
            self = match
        } else if raw.lowercased().contains("chat") || raw.caseInsensitiveCompare("Genie Chat") == .orderedSame {
            self = .chat
        } else if raw.lowercased().contains("ai") || raw.lowercased().contains("model") || raw.lowercased().contains("gpt") || raw.lowercased().contains("gemini") || raw.caseInsensitiveCompare("Executive Intelligence & Models") == .orderedSame {
            self = .aiModels
        } else if raw.lowercased().contains("vm") || raw.lowercased().contains("station") || raw.lowercased().contains("virtual machine") || raw.lowercased().contains("hypervisor") || raw.caseInsensitiveCompare("AI Stations & Virtual Machines") == .orderedSame {
            self = .virtualMachines
        } else if raw.lowercased().contains("store") || raw.lowercased().contains("expan") || raw.lowercased().contains("cart") || raw.lowercased().contains("shop") || raw.lowercased().contains("shopping") || raw.lowercased().contains("addon") || raw.lowercased().contains("add-on") || raw.caseInsensitiveCompare("Bespoke Commissions") == .orderedSame {
            self = .expansion
        } else if raw.lowercased().contains("mouse") || raw.lowercased().contains("track") || raw.lowercased().contains("touch") || raw.caseInsensitiveCompare("Kinetic Gestures & Inertia") == .orderedSame {
            self = .trackpad
        } else if raw.lowercased().contains("sound") || raw.lowercased().contains("audio") || raw.lowercased().contains("haptic") || raw.caseInsensitiveCompare("Acoustic Signatures & Force Haptics") == .orderedSame {
            self = .soundHaptics
        } else if raw.lowercased().contains("pet") || raw.lowercased().contains("pinball") || raw.lowercased().contains("creature") || raw.caseInsensitiveCompare("Spatial Kinetic Complications") == .orderedSame {
            self = .petsAndPinball
        } else if raw.lowercased().contains("notch") || raw.lowercased().contains("menu bar") || raw.lowercased().contains("custom bar") || raw.caseInsensitiveCompare("Grand Horizon & Status Rail") == .orderedSame {
            self = .menuBar
        } else if raw.lowercased().contains("theme") || raw.lowercased().contains("glass") || raw.caseInsensitiveCompare("Atelier Finishes & Vitreous Glass") == .orderedSame {
            self = .themes
        } else if raw.lowercased().contains("snug") || raw.caseInsensitiveCompare("Haute Bezels & Housings") == .orderedSame {
            self = .snuggies
        } else if raw.lowercased().contains("font") || raw.lowercased().contains("type") || raw.caseInsensitiveCompare("Haute Typography & Numerals") == .orderedSame {
            self = .typography
        } else if raw.lowercased().contains("wall") || raw.lowercased().contains("shader") || raw.lowercased().contains("fx") || raw.caseInsensitiveCompare("Atmospheric Shaders & Murals") == .orderedSame {
            self = .wallpapers
        } else if raw.lowercased().contains("appear") {
            self = .themes
        } else if raw.lowercased().contains("sys") || raw.lowercased().contains("pref") || raw.lowercased().contains("general") || raw.caseInsensitiveCompare("Console Preferences") == .orderedSame {
            self = .system
        } else if raw.lowercased().contains("app") || raw.caseInsensitiveCompare("Application Atelier") == .orderedSame {
            self = .applications
        } else if raw.lowercased().contains("batt") || raw.lowercased().contains("power") || raw.lowercased().contains("charge") || raw.caseInsensitiveCompare("Power Reserve & Telemetry") == .orderedSame {
            self = .battery
        } else if raw.lowercased().contains("format") || raw.lowercased().contains("shape") || raw.caseInsensitiveCompare("Spatial Formations & Geometries") == .orderedSame {
            self = .formations
        } else if raw.lowercased().contains("workspace") || raw.lowercased().contains("grid") || raw.caseInsensitiveCompare("Architectural Canvas") == .orderedSame {
            self = .workspace
        } else if raw.lowercased().contains("interact") || raw.lowercased().contains("trail") || raw.lowercased().contains("motion") {
            self = .trackpad
        } else if raw.lowercased().contains("priv") || raw.lowercased().contains("perm") || raw.lowercased().contains("secur") || raw.caseInsensitiveCompare("Security Governance & Attestation") == .orderedSame {
            self = .privacy
        } else if raw.lowercased().contains("clock") || raw.lowercased().contains("world") || raw.lowercased().contains("time zone") {
            self = .worldClock
        } else {
            self = .chat
        }
    }

    var icon: String {
        switch self {
        case .chat: return "bubble.left.and.bubble.right.fill"
        case .applications: return "square.grid.2x2.fill"
        case .workspace: return "macwindow.on.rectangle"
        case .formations: return "circle.grid.cross.fill"
        case .aiModels: return "sparkles"
        case .virtualMachines: return "server.rack"
        case .expansion: return "bag.fill"
        case .system: return "gearshape.fill"
        case .privacy: return "hand.raised.fill"
        case .themes: return "paintbrush.fill"
        case .snuggies: return "app.dashed"
        case .typography: return "textformat"
        case .wallpapers: return "sparkles.rectangle.stack"
        case .trackpad: return "hand.tap.fill"
        case .soundHaptics: return "speaker.wave.2.fill"
        case .petsAndPinball: return "pawprint.fill"
        case .menuBar: return "menubar.rectangle"
        case .battery: return "battery.100.bolt"
        case .worldClock: return "clock.fill"
        }
    }

    var tintColor: Color {
        switch self {
        case .chat: return .cyan
        case .applications: return .indigo
        case .workspace: return .teal
        case .formations: return .pink
        case .aiModels: return .purple
        case .virtualMachines: return .blue
        case .expansion: return .orange
        case .system: return .blue
        case .privacy: return .red
        case .themes: return .purple
        case .snuggies: return .yellow
        case .typography: return .orange
        case .wallpapers: return .cyan
        case .trackpad: return .green
        case .soundHaptics: return .yellow
        case .petsAndPinball: return .pink
        case .menuBar: return .cyan
        case .battery: return .green
        case .worldClock: return .orange
        }
    }
}

public enum MenuBarDropdownMode: String, CaseIterable, Identifiable {
    case applications = "Applications"
    case settings = "Settings"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .applications: return "square.grid.2x2.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

// MARK: - Apple System Settings Modern Inset-Grouped Components

struct AppleSettingsSection<Content: View>: View {
    var title: String? = nil
    @ViewBuilder let content: () -> Content

    init(_ title: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let title = title {
                Text(title.uppercased())
                    .font(.system(size: 9.5, weight: .bold))
                    .foregroundColor(.secondary.opacity(0.80))
                    .padding(.horizontal, 4)
            }
            VStack(spacing: 0) {
                content()
            }
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.42))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
            )
        }
        .frame(maxWidth: .infinity)
    }
}

struct AppleSettingsRow<Content: View>: View {
    let title: String
    var subtitle: String? = nil
    var icon: String? = nil
    var iconColor: Color = .blue
    @ViewBuilder let trailing: () -> Content

    init(title: String, subtitle: String? = nil, icon: String? = nil, iconColor: Color = .blue, @ViewBuilder trailing: @escaping () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.iconColor = iconColor
        self.trailing = trailing
    }

    var body: some View {
        HStack(spacing: 10) {
            if let icon = icon {
                ZStack {
                    RoundedRectangle(cornerRadius: 5.5, style: .continuous)
                        .fill(iconColor)
                        .frame(width: 22, height: 22)
                    Image(systemName: icon)
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundColor(.white)
                }
            }

            VStack(alignment: .leading, spacing: 1.5) {
                Text(title)
                    .font(.system(size: 11.5, weight: .regular))
                    .foregroundColor(.primary)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 9.5))
                        .foregroundColor(.secondary)
                }
            }

            Spacer(minLength: 12)

            trailing()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
    }
}

struct MenuBarDropdownView: View {
    @AppStorage(PrefKey.appLanguage) var appLanguage: String = "English (US)"
    @ObservedObject var appModel: AppModel
    @ObservedObject var batteryMonitor = BatteryMonitor.shared
    @ObservedObject private var desktopFilesManager = DesktopFilesManager.shared
    @ObservedObject private var permissionsManager = PermissionsManager.shared
    @AppStorage(PrefKey.barFolderPath) var barFolderPath: String = AppDefaultsManager.defaultBarFolderPath
    @AppStorage(PrefKey.dockActiveAppsOnly) var dockActiveAppsOnly: Bool = false

    @AppStorage(PrefKey.dropdownMode) var rawDropdownMode: String = MenuBarDropdownMode.applications.rawValue

    var dropdownMode: MenuBarDropdownMode {
        get {
            MenuBarDropdownMode(rawValue: rawDropdownMode) ?? .applications
        }
        nonmutating set {
            rawDropdownMode = newValue.rawValue
        }
    }

    @AppStorage(PrefKey.customStatusEmoji) var customStatusEmoji: String = ""
    @State private var customEmojiInput: String = ""

    @AppStorage(PrefKey.selectedStudioTab) private var rawSelectedTab: String = DropdownSidebarTab.chat.rawValue

    var selectedTab: DropdownSidebarTab {
        get {
            DropdownSidebarTab(caseInsensitive: rawSelectedTab)
        }
        nonmutating set {
            rawSelectedTab = newValue.rawValue
        }
    }

    // Flagship Genie Chat Integration
    @ObservedObject var localModels = LocalModelManager.shared
    @State private var chatPromptText: String = ""
    @State private var chatPromptMode: BarMode = .chat
    @State private var chatLayoutMode: WindowLayoutMode = .chatOnly
    @State private var selectedAppSuggestionIndex: Int = 0
    @AppStorage(PrefKey.aiEmotion) private var selectedEmotionRaw: String = AIEmotionType.mystical.rawValue

    private var currentChatEmotion: AIEmotionType {
        if !localModels.activeEmotionRaw.isEmpty, let em = AIEmotionType(rawValue: localModels.activeEmotionRaw) {
            return em
        }
        if localModels.isGenerating {
            return .contemplative
        }
        return AIEmotionType(rawValue: selectedEmotionRaw) ?? .mystical
    }
    @AppStorage(PrefKey.formationAppLimit) var formationAppLimit: Int = 0
    @AppStorage(PrefKey.customFormationColumns) var customFormationColumns: Int = 4
    @State private var formationSearchQuery: String = ""
    @State private var themeSearchQuery: String = ""
    private func cycleNextTab() {
        let all = DropdownSidebarTab.allCases
        if let idx = all.firstIndex(of: selectedTab) {
            let nextIdx = (idx + 1) % all.count
            HapticFeedback.selection()
            withAnimation(.spring(response: 0.22, dampingFraction: 0.82)) {
                selectedTab = all[nextIdx]
            }
        } else {
            selectedTab = .system
        }
    }

    private func selectNextTab() {
        let all = DropdownSidebarTab.allCases
        if let idx = all.firstIndex(of: selectedTab) {
            let nextIdx = min(all.count - 1, idx + 1)
            if nextIdx != idx {
                HapticFeedback.selection()
                withAnimation(.spring(response: 0.20, dampingFraction: 0.82)) {
                    selectedTab = all[nextIdx]
                }
            }
        }
    }

    private func selectPreviousTab() {
        let all = DropdownSidebarTab.allCases
        if let idx = all.firstIndex(of: selectedTab) {
            let prevIdx = max(0, idx - 1)
            if prevIdx != idx {
                HapticFeedback.selection()
                withAnimation(.spring(response: 0.20, dampingFraction: 0.82)) {
                    selectedTab = all[prevIdx]
                }
            }
        }
    }
    @State private var themeCategoryFilter: String = "All"
    @State private var keyMonitor: Any?
    @State private var hiddenAppsRevision: Int = 0
    @State private var previewPhase: CGFloat = 0.0
    @State private var appSearchQuery: String = ""
    @State private var showResetConfirmOverlay: Bool = false
    @State private var windowDragStartOrigin: CGPoint? = nil
    @State private var sidebarWidth: CGFloat = 192
    @State private var sidebarDragStartWidth: CGFloat? = nil
    @AppStorage(PrefKey.isSidebarPinned) var isSidebarPinned: Bool = false
    @State private var isSidebarHovered: Bool = false
    @State private var isSidebarHoverTriggered: Bool = false
    @State private var appViewMode: String = "list" // "list" or "grid"
    @State private var appVisibilityFilter: String = "all" // "all", "visible", "hidden"
    @State private var appSectionMode: String = "manager" // "manager" or "launcher"
    @State private var hoveredPidApp: String? = nil
    @StateObject private var storeManager = ExpansionStoreManager.shared

    // Window Sizing & Dropdown Background Engine
    @AppStorage(PrefKey.isFoldedToBar) var isFoldedToBar: Bool = false
    @AppStorage(PrefKey.menuCompactMode) var menuCompactMode: Bool = true
    @AppStorage(PrefKey.windowSizeMode) var windowSizeMode: String = "normal"
    @AppStorage(PrefKey.dropdownBgPreset) var dropdownBgPreset: String = "wallpaper_mirror"
    @AppStorage(PrefKey.dropdownBgOpacity) var dropdownBgOpacity: Double = 0.40
    @AppStorage(PrefKey.dropdownBgBlur) var dropdownBgBlur: Double = 16.0
    @State private var showDropdownBgPicker: Bool = false

    // Desktop Grid Controls
    @AppStorage(PrefKey.desktopPlaneEnabled) var desktopPlaneEnabled: Bool = true
    @AppStorage(PrefKey.alwaysOnDesktop) var alwaysOnDesktop: Bool = false
    @AppStorage(PrefKey.iconSize) var iconSize: Double = 64.0
    @AppStorage(PrefKey.textSize) var textSize: Double = 11.0
    @AppStorage(PrefKey.showAppNames) var showAppNames: Bool = false
    @AppStorage(PrefKey.showPageIndicator) var showPageIndicator: Bool = false
    @AppStorage(PrefKey.spacing) var itemSpacing: Double = 16.0
    @AppStorage(PrefKey.enableMagnification) var enableMagnification: Bool = false
    @AppStorage(PrefKey.magnificationScale) var maxMagnification: Double = 1.65
    @AppStorage(PrefKey.dockAnimationStyle) var dockAnimationStyleRaw: String = "None"
    @AppStorage(PrefKey.dockAnimationIntensity) var dockAnimationIntensity: Double = 0.7
    @AppStorage(PrefKey.dockBackgroundOpacity) var dockBackgroundOpacity: Double = 0.70
    @AppStorage(PrefKey.danceToMusicEnabled) var danceToMusicEnabled: Bool = false
    @AppStorage(PrefKey.liquidGlassEnabled) var liquidGlassEnabled: Bool = true
    @ObservedObject var musicMonitor: MusicPlaybackMonitor = .shared
    @AppStorage(PrefKey.soundEnabled) var soundEnabled: Bool = true
    @AppStorage(PrefKey.soundVolume) var soundVolume: Double = 0.85
    @AppStorage(PrefKey.soundProfile) var soundProfile: String = "Apple Modern"
    @AppStorage(PrefKey.hapticsEnabled) var hapticsEnabled: Bool = true
    @AppStorage(PrefKey.appIconTheme) var appIconTheme: String = "Default"
    @AppStorage(PrefKey.appIconTintColor) var appIconTintColor: String = "Emerald"
    @AppStorage(PrefKey.iconSnuggie) var iconSnuggie: String = "None"

    // Page 1 vs Page 2 Default Behavior
    @AppStorage(PrefKey.defaultPageMode) var defaultPageMode: String = "Page 1 (Apps Direct)"
    @AppStorage(PrefKey.desktopSplitMode) var desktopSplitMode: String = "Full Screen"

    // Dynamic Wallpaper FX Controls
    @AppStorage(PrefKey.wallpaperMode) var wallpaperMode: String = "Genie"
    @AppStorage(PrefKey.sameWallpaperMode) var sameWallpaperMode: Bool = true
    @AppStorage(PrefKey.wallpaperMatchingStyle) var wallpaperMatchingStyle: String = "Exact Mirror (1:1)"
    @AppStorage(PrefKey.wallpaperTreatment) var wallpaperTreatment: String = "Exact Mirror (1:1)"
    @AppStorage(PrefKey.hideWallpaperBehindApps) var hideWallpaperBehindApps: Bool = false
    @AppStorage(PrefKey.wallpaperFxEnabled) var wallpaperFxEnabled: Bool = false
    @AppStorage(PrefKey.wallpaperFxType) var wallpaperFxType: String = "Cosmic Aurora"
    @AppStorage(PrefKey.wallpaperFxIntensity) var wallpaperFxIntensity: Double = 0.35

    // Window Graphics & Vibrancy Backing Engine
    @ObservedObject private var wallpaperManager = WallpaperManager.shared
    @AppStorage(PrefKey.windowGraphicsEnabled) var windowGraphicsEnabled: Bool = false
    @AppStorage(PrefKey.windowGlassVibrancy) var windowGlassVibrancy: Double = 0.75
    @AppStorage(PrefKey.windowShaderFxEnabled) var windowShaderFxEnabled: Bool = false

    // Living Background App Physics Simulation
    @AppStorage(PrefKey.appPhysicsSimulation) var appPhysicsSimulation: String = "None"

    // Cursor FX Animation Engine
    @AppStorage(PrefKey.cursorFxType) var cursorFxType: String = "None"

    // Arcade Pinball Mode
    @AppStorage(PrefKey.pinballModeEnabled) var pinballModeEnabled: Bool = false
    @AppStorage(PrefKey.attachWorldClockWidget) var attachWorldClockWidget: Bool = false
    @AppStorage(PrefKey.attachAnimatedChatWidget) var attachAnimatedChatWidget: Bool = false

    // Genie Summon Animation & Smoke Engine
    @AppStorage(PrefKey.genieAnimEnabled) var genieAnimEnabled: Bool = false
    @AppStorage(PrefKey.genieAnimOrigin) var genieAnimOrigin: String = "Top Glyph 🪔"
    @AppStorage(PrefKey.smokeEffectsEnabled) var smokeEffectsEnabled: Bool = false
    @AppStorage(PrefKey.smokeStyle) var smokeStyle: String = "Mystical Cyan 🧞‍♂️"

    // Menu Bar Aesthetics & Apple Logo Colors
    @AppStorage(PrefKey.menuBarAppleColor) var appleColor: String = "Retro Rainbow 🌈"
    @AppStorage(PrefKey.menuBarTextColor) var textColorName: String = "Pure White ⚪️"
    @AppStorage(PrefKey.menuBarActiveAppColor) var activeAppColorName: String = "Neon Cyan ⚡️"
    @AppStorage(PrefKey.menuBarColorsEnabled) var menuBarColorsEnabled: Bool = true
    @AppStorage(PrefKey.menuBarTimeFormat) var timeFormat: String = "Date & Time (12-Hour)"
    @AppStorage(PrefKey.menuBarFontFamily) var fontFamily: String = "SF Pro (Apple Default)"
    @AppStorage(PrefKey.menuBarFontWeight) var fontWeight: String = "Regular"
    @AppStorage(PrefKey.menuBarFontSize) var menuBarFontSize: Double = 13.0
    @AppStorage(PrefKey.customMenuBarEnabled) var customMenuBarEnabled: Bool = false
    @AppStorage(PrefKey.miniDockDisplayMode) var miniDockDisplayMode: String = "Always Shown"
    @AppStorage(PrefKey.menuBarBackgroundStyle) var backgroundStyle: String = "Liquid Glass (Apple Modern) 💎"
    @ObservedObject var multiOutputVolume = MultiOutputVolumeManager.shared

    @State private var genieScale: CGFloat = 1.0
    @State private var genieOpacity: Double = 1.0
    @State private var genieAnchor: UnitPoint = .topTrailing
    @State private var genieOffsetY: CGFloat = 0.0
    @State private var popoverBounds: CGSize = CGSize(width: 880, height: 560)
    @State private var isPanelVisible: Bool = false

    // Studio Dropdown Theme & International Language
    @AppStorage(PrefKey.studioTheme) var studioTheme: String = "System (Auto)"
@Environment(\.colorScheme) private var systemColorScheme

    private var isStudioLight: Bool {
        switch studioTheme {
        case "macOS Light", "VS Code Light+", "Solarized Light":
            return true
        case "macOS Dark", "VS Code Dark+":
            return false
        default:
            return systemColorScheme == .light
        }
    }

    private var studioThemePalette: (bg: Color, topBar: Color, sidebar: Color, content: Color, border: Color, primaryText: Color, secondaryText: Color, accent: Color) {
        let glass = windowGraphicsEnabled
        let v = max(0.25, min(1.0, windowGlassVibrancy))
        switch studioTheme {
        case "VS Code Light+":
            return (
                bg: glass ? Color(red: 0.98, green: 0.98, blue: 0.98, opacity: 0.70 * v) : Color(red: 0.98, green: 0.98, blue: 0.98),
                topBar: glass ? Color(red: 0.95, green: 0.95, blue: 0.95, opacity: 0.78 * v) : Color(red: 0.95, green: 0.95, blue: 0.95),
                sidebar: glass ? Color(red: 0.93, green: 0.93, blue: 0.94, opacity: 0.62 * v) : Color(red: 0.93, green: 0.93, blue: 0.94),
                content: glass ? Color(red: 1.0, green: 1.0, blue: 1.0, opacity: 0.55 * v) : Color(red: 1.0, green: 1.0, blue: 1.0),
                border: Color(red: 0.85, green: 0.85, blue: 0.86),
                primaryText: Color(red: 0.15, green: 0.15, blue: 0.15),
                secondaryText: Color(red: 0.45, green: 0.45, blue: 0.48),
                accent: Color(red: 0.0, green: 0.48, blue: 0.80)
            )
        case "Solarized Light":
            return (
                bg: glass ? Color(red: 0.99, green: 0.96, blue: 0.89, opacity: 0.72 * v) : Color(red: 0.99, green: 0.96, blue: 0.89),
                topBar: glass ? Color(red: 0.96, green: 0.93, blue: 0.85, opacity: 0.80 * v) : Color(red: 0.96, green: 0.93, blue: 0.85),
                sidebar: glass ? Color(red: 0.93, green: 0.91, blue: 0.83, opacity: 0.65 * v) : Color(red: 0.93, green: 0.91, blue: 0.83),
                content: glass ? Color(red: 0.99, green: 0.96, blue: 0.89, opacity: 0.58 * v) : Color(red: 0.99, green: 0.96, blue: 0.89),
                border: Color(red: 0.85, green: 0.82, blue: 0.74),
                primaryText: Color(red: 0.03, green: 0.21, blue: 0.26),
                secondaryText: Color(red: 0.35, green: 0.43, blue: 0.46),
                accent: Color(red: 0.15, green: 0.55, blue: 0.82)
            )
        case "macOS Light":
            return (
                bg: glass ? Color(red: 0.95, green: 0.95, blue: 0.96, opacity: 0.65 * v) : Color(red: 0.95, green: 0.95, blue: 0.96),
                topBar: glass ? Color(red: 0.97, green: 0.97, blue: 0.98, opacity: 0.74 * v) : Color(red: 0.97, green: 0.97, blue: 0.98),
                sidebar: glass ? Color(red: 0.92, green: 0.92, blue: 0.93, opacity: 0.55 * v) : Color(red: 0.92, green: 0.92, blue: 0.93),
                content: glass ? Color(red: 0.97, green: 0.97, blue: 0.98, opacity: 0.50 * v) : Color(red: 0.97, green: 0.97, blue: 0.98),
                border: Color.black.opacity(0.12),
                primaryText: Color(red: 0.12, green: 0.12, blue: 0.12),
                secondaryText: Color(red: 0.48, green: 0.48, blue: 0.50),
                accent: Color.teal
            )
        case "VS Code Dark+":
            return (
                bg: glass ? Color(red: 0.12, green: 0.12, blue: 0.12, opacity: 0.65 * v) : Color(red: 0.12, green: 0.12, blue: 0.12),
                topBar: glass ? Color(red: 0.15, green: 0.15, blue: 0.15, opacity: 0.75 * v) : Color(red: 0.15, green: 0.15, blue: 0.15),
                sidebar: glass ? Color(red: 0.14, green: 0.14, blue: 0.15, opacity: 0.58 * v) : Color(red: 0.14, green: 0.14, blue: 0.15),
                content: glass ? Color(red: 0.12, green: 0.12, blue: 0.12, opacity: 0.50 * v) : Color(red: 0.12, green: 0.12, blue: 0.12),
                border: Color(red: 0.28, green: 0.28, blue: 0.30),
                primaryText: Color.white,
                secondaryText: Color(white: 0.65),
                accent: Color(red: 0.0, green: 0.48, blue: 0.80)
            )
        default:
            if isStudioLight {
                return (
                    bg: glass ? Color(nsColor: .windowBackgroundColor).opacity(0.35 * v) : Color(red: 0.95, green: 0.95, blue: 0.96),
                    topBar: glass ? Color.clear : Color(red: 0.97, green: 0.97, blue: 0.98),
                    sidebar: glass ? Color(nsColor: .controlBackgroundColor).opacity(0.20 * v) : Color(red: 0.92, green: 0.92, blue: 0.93),
                    content: glass ? Color(nsColor: .windowBackgroundColor).opacity(0.25 * v) : Color(red: 0.97, green: 0.97, blue: 0.98),
                    border: Color.black.opacity(0.12),
                    primaryText: Color(red: 0.12, green: 0.12, blue: 0.12),
                    secondaryText: Color(red: 0.48, green: 0.48, blue: 0.50),
                    accent: Color.teal
                )
            } else {
                return (
                    bg: glass ? Color(nsColor: .windowBackgroundColor).opacity(0.35 * v) : Color(red: 0.12, green: 0.12, blue: 0.13),
                    topBar: glass ? Color.clear : Color(red: 0.14, green: 0.14, blue: 0.15),
                    sidebar: glass ? Color(nsColor: .controlBackgroundColor).opacity(0.20 * v) : Color(red: 0.10, green: 0.10, blue: 0.11),
                    content: glass ? Color(nsColor: .windowBackgroundColor).opacity(0.25 * v) : Color(red: 0.12, green: 0.12, blue: 0.13),
                    border: Color.white.opacity(0.16),
                    primaryText: Color.white,
                    secondaryText: Color.secondary,
                    accent: Color.teal
                )
            }
        }
    }

    // Portfolio Formations & Living Pets / Entities
    @AppStorage(PrefKey.appFormation) var appFormation: String = "Responsive Grid"
    @AppStorage(PrefKey.chatGridPadding) var chatGridPadding: Double = 48.0
    @AppStorage(PrefKey.ambientEntity) var ambientEntity: String = "None"
    @AppStorage(PrefKey.dragonFollowCursor) var dragonFollowCursor: Bool = true
    @AppStorage(PrefKey.dockAvoidanceEnabled) var dockAvoidanceEnabled: Bool = true
    @AppStorage(PrefKey.dockRestPeriod) var dockRestPeriod: Double = 0.65
    @AppStorage(PrefKey.gridTransitionDirection) var gridTransitionDirection: String = "Slide from Right (iPhone Mode 📱)"
    @AppStorage(PrefKey.rightEdgeCursorTrigger) var rightEdgeCursorTrigger: Bool = false
    @AppStorage(PrefKey.bottomEdgeCursorTrigger) var bottomEdgeCursorTrigger: Bool = false
    @AppStorage(PrefKey.bottomRightHotCorner) var bottomRightHotCorner: Bool = false
    @AppStorage(PrefKey.topRightHotCorner) var topRightHotCorner: Bool = false
    @AppStorage(PrefKey.doubleControlTrigger) var doubleControlTrigger: Bool = true
    @AppStorage(PrefKey.doubleOptionTrigger) var doubleOptionTrigger: Bool = false
    @AppStorage(PrefKey.orbitSpeed) var orbitSpeed: Double = 1.0
    @AppStorage(PrefKey.orbitClockwise) var orbitClockwise: Bool = true
    @AppStorage(PrefKey.pulseIntensity) var pulseIntensity: Double = 0.5

    // Category Filter States
    @State private var formationCategoryFilter: String = "All"
    @State private var shaderCategoryFilter: String = "All"
    @State private var entityCategoryFilter: String = "All"
    @State private var snuggieCategoryFilter: String = "All"
    @State private var batteryStyleCategoryFilter: String = "All"

    // Status Bar & Battery Controls
    @AppStorage(PrefKey.batteryEnabled) var batteryEnabled: Bool = true
    @AppStorage(PrefKey.batteryStyle) var batteryStyle: String = "Horizontal Fill"
    @AppStorage(PrefKey.iconEnabled) var iconEnabled: Bool = true
    @AppStorage(PrefKey.showBatteryPercentage) var showBatteryPercentage: Bool = true
    @AppStorage(PrefKey.iconStyle) var iconStyle: String = "Apple Minimal"
    @AppStorage(PrefKey.animSpeed) var animSpeed: Double = 0.03
    @AppStorage(PrefKey.batteryColorMode) var batteryColorMode: String = "Dynamic Level"
    @AppStorage(PrefKey.batteryNumberTheme) var batteryNumberTheme: String = "Dynamic Match"
    @AppStorage(PrefKey.statusIconStyle) var statusIconStyle: String = "Genie Lamp 🪔"
    @AppStorage(PrefKey.showChargingBolt) var showChargingBolt: Bool = false

    private var statusIconGlyphs: [String] {
        [
            "Leo Maltese 🐶", "Genie Lamp 🪔", "Genie Portal 🌀", "Mystical Orb 🔮", "Neon Golden Glow 🌟", "Cyber Bolt ⚡️",
            "Solar Flare ☀️", "Pixel Heart 💖", "Star Sparkle ✨", "Diamond Facet 💎",
            "Crown Jewel 👑", "Minimal Dot ⚪", "Radioactive Pulse ☢️", "Infinity Loop ♾️",
            "Fire Flame 🔥", "Water Droplet 💧", "Golden Comet 💫", "Cosmic Planet 🪐",
            "Golden Shield 🛡️", "Golden Key 🔑", "Music Note 🎵", "Arcade Gamepad 🎮",
            "Ghost Spirit 👻", "Compass Rose 🧭", "Lightning Cloud ⛈️", "Cyber Eye 👁️",
            "Atom Core ⚛️", "Golden Gear ⚙️", "Magic Wand 🪄", "Paper Plane ✈️",
            "Green Leaf 🍃", "Sun Horizon 🌅", "Crescent Moon 🌙", "Terminal Hacker 💻",
            "Quantum Beam 📡", "High Voltage ⚡️", "Golden Bell 🔔", "Vault Lock 🔒",
            "Studio Camera 📷", "Champion Flag 🚩", "Gold Trophy 🏆", "King Pin 🎳", "Apple Modern "
        ]
    }

    // Window & Position
    @AppStorage(PrefKey.menuBarSnapMode) var snapMode: String = "right"
    @AppStorage(PrefKey.popoverFreePositionEnabled) var popoverFreePositionEnabled: Bool = true
    @AppStorage(PrefKey.pinToDesktopEnabled) var pinToDesktopEnabled: Bool = false
    @AppStorage(PrefKey.studioAlwaysOnTop) var studioAlwaysOnTop: Bool = true
    @State private var showingOnboardingWizard: Bool = !UserDefaults.standard.bool(forKey: PrefKey.hasCompletedInitialSetup)

    var onRefreshApps: (() -> Void)?
    var onQuitApp: (() -> Void)?

    @ObservedObject private var loginItemManager = LoginItemManager.shared

    // 52+ Curated Ultra-HD App Themes
    private var allThemes: [(name: String, category: String, desc: String)] {
        [
            // Category: macOS Sequoia
            ("Default", "macOS Sequoia", "Classic macOS App Icons"),
            ("Translucent", "macOS Sequoia", "Ultra-Thin Frosted Glass & Aero Glow 🪟"),
            ("Wallpaper Camouflage", "macOS Sequoia", "Stealth Wallpaper Chameleon 🦎"),
            ("Dark", "macOS Sequoia", "Deep Onyx Night Shadows"),
            ("Clear", "macOS Sequoia", "Translucent Frosted Monochrome"),
            ("Tinted", "macOS Sequoia", "Custom Accent Inset Tint"),
            ("Vintage Aqua", "macOS Sequoia", "Glossy macOS X Tiger Aqua 💧"),
            ("iOS Minimal", "macOS Sequoia", "Clean High-Vibrancy Flat"),
            ("Frost Glass Acrylic", "macOS Sequoia", "Frosted Acrylic Aero Glass 🪟"),
            ("Monochrome Studio", "macOS Sequoia", "Swiss Architectural Minimalist ⚪️"),
            ("Golden Kintsugi", "macOS Sequoia", "Porcelain Repaired with 24K Gold 🏺"),

            // Category: 3D Spatial
            ("3D Hologram Spinner", "3D Spatial", "Continuous 3D Turntable Spin with Speed Boost 🛸"),
            ("3D Coin Flip", "3D Spatial", "Vertical 3D Spinning Coin with Gold Bevel 🪙"),
            ("3D Quantum Vortex", "3D Spatial", "Multi-Axis Gyro 3D Prism Vortex 🌪️"),
            ("3D Skater Kickflip", "3D Spatial", "360° Barrel Roll with Sparks & Kickflip 🛹"),
            ("3D Hypercube 4D", "3D Spatial", "Tesseract Spatial Wireframe Orbit 🧊"),
            ("3D Kinetic Gyroscope", "3D Spatial", "Rotating Concentric Brass Rings 🧭"),
            ("3D Diamond Facet", "3D Spatial", "Faceted Sparkling Brilliant Cut 💎"),
            ("3D Orbiting Satellites", "3D Spatial", "Miniature Planetary Moon Orbit 🪐"),

            // Category: Futuristic FX
            ("Inferno", "Futuristic FX", "Dynamic Solar Fire Shader 🔥"),
            ("Cyberpunk", "Futuristic FX", "Neon Cyan & Magenta Hologram ⚡️"),
            ("Matrix", "Futuristic FX", "Terminal Green Code Stream 🟢"),
            ("Solar Flare", "Futuristic FX", "Radiant Amber Stellar Flare ☀️"),
            ("Frost Glaze", "Futuristic FX", "Glacial Sub-Zero Crystal ❄️"),
            ("Void", "Futuristic FX", "Cosmic Singularity Wormhole 🌌"),
            ("Quantum Prism", "Futuristic FX", "Full Spectrum Quantum Light 🌈"),
            ("Toxic Plasma", "Futuristic FX", "Radioactive Bio-Plasma ☣️"),
            ("Supernova", "Futuristic FX", "Hyper-Luminous Stellar Blast 💥"),
            ("Midnight Gold", "Futuristic FX", "Regal 24K Gold Lustre ✨"),
            ("Diamond Crystal Glass", "Futuristic FX", "Faceted Refraction Glass 💎"),
            ("Arcane Rune", "Futuristic FX", "Mystic Occult Glyphs 🔮"),
            ("Liquid Chrome", "Futuristic FX", "Mercury Metal Reflection 🪩"),
            ("Electric Lightning Plasma", "Futuristic FX", "Crackling High-Voltage Arcs ⚡️"),
            ("Holographic Chromatic Prism", "Futuristic FX", "RGB Shifting Dispersion Lens 🌈"),
            ("Cyber Glitch Distortion", "Futuristic FX", "Digital Pixel Anomaly Artifacts 👾"),
            ("HUD Tactical Combat", "Futuristic FX", "Sci-Fi Telemetry & Targeting Reticle 🎯"),
            ("Black Hole Singularity", "Futuristic FX", "Gravitational Lensing Accretion Disk 🕳️"),
            ("Tokyo Neon Rain", "Futuristic FX", "Wet Shimmering Asphalt Neon Glow 🌧️"),

            // Category: Nature & Organic
            ("Bio-Organic Flora", "Nature & Organic", "Bioluminescent Moss & Vines 🌿"),
            ("Bioluminescent Abyssal", "Nature & Organic", "Deep Sea Jellyfish Phosphor 🪼"),
            ("Sakura Blossom Drift", "Nature & Organic", "Falling Japanese Cherry Petals 🌸"),
            ("Firefly Enchanted Forest", "Nature & Organic", "Warm Glowing Forest Fireflies 🌲"),
            ("Celestial Aurora", "Nature & Organic", "Shimmering Polar Magnetosphere 🌌"),
            ("Ocean Caustics", "Nature & Organic", "Refracted Underwater Sunlight Caustics 🌊"),
            ("Desert Solar Mirage", "Nature & Organic", "Heat Shimmering Golden Dunes 🏜️"),
            ("Volcanic Obsidian Lava", "Nature & Organic", "Smoldering Molten Magma Cracks 🌋"),

            // Category: Retro & Synth
            ("8-Bit Arcade", "Retro & Synth", "Scanline Retro Pixel Graphics 🕹️"),
            ("Synthwave", "Retro & Synth", "80s Outrun Magenta Sunset 🌆"),
            ("Neon Vaporwave", "Retro & Synth", "Electric Teal & Hot Pink 🌴"),
            ("Cyber Noir", "Retro & Synth", "High-Contrast Silver Monochrome 🕶️"),
            ("CRT Phosphor Terminal", "Retro & Synth", "Vintage Amber Computer Display 📺"),
            ("GameBoy Dot Matrix", "Retro & Synth", "Retro 4-Shade Greenish LCD 👾"),
            ("Tron Vector Grid", "Retro & Synth", "Glowing Cyber Wireframe Horizon 🏍️"),
            ("Steampunk Brass Gears", "Retro & Synth", "Polished Copper & Riveted Cogwheels ⚙️"),

            // Category: Pop Punk & Indie Rock 🎸
            ("Pop Punk Artist", "Pop Punk & Indie 🎸", "Distressed Neon Pink, Chunky Outlines & Tour Poster Type 🎸"),
            ("Skate Punk Stickers", "Pop Punk & Indie 🎸", "High-Contrast Checkerboard & Die-Cut Sticker Decals 🛹"),
            ("Ice Cream Dream", "Pop Punk & Indie 🎸", "Pastel Soft-Serve Swirls & Rainbow Sprinkles 🍦")
        ]
    }

    private var filteredThemes: [(name: String, category: String, desc: String)] {
        var list = allThemes
        if themeCategoryFilter != "All" {
            list = list.filter { $0.category == themeCategoryFilter }
        }
        if !themeSearchQuery.trimmingCharacters(in: .whitespaces).isEmpty {
            let q = themeSearchQuery.lowercased()
            list = list.filter { $0.name.lowercased().contains(q) || $0.desc.lowercased().contains(q) }
        }
        return list
    }

    private var wallpaperFxOptions: [String] {
        [
            "Mystical Genie Smoke 💨",
            "Liquid Glass ✨",
            "4K Ocean Caustics 🌊", "4K Marine Bioluminescence ✨",
            "Fluid Ink Chromatography 🎨", "Electric Plasma Lightning Storm ⚡️",
            "Matrix Digital Rain Stream 🟢", "Sakura Petal Blizzard 🌸",
            "Retro CRT Vector Grid 🕹️", "Supermassive Black Hole Lens 🕳️",
            "4K Tokyo Neon Night Rain 🌧️", "Hyperdrive Warp Speed ⚡️",
            "Cosmic Aurora", "Fluid Waves",
            "Cyber Horizon", "Floating Stardust", "Starfield Warp",
            "Prismatic Rays", "Volcanic Magma", "Bioluminescent Sea", "None"
        ]
    }

    private var appPhysicsOptions: [String] {
        [
            "Random Pulsing Bubbles 🫧", "Live Bulge & Breathing 🫁", "Jelly Bounce 🍮",
            "Springy Trampoline 🤸", "Cosmic Anti-Gravity 🪐", "Matrix Quantum Wave ⚡️",
            "Zero-G Float", "Micro-Orbit", "Harmonic Pulse",
            "Tidal Waves", "Quantum Jitter", "None"
        ]
    }

    @State private var cursorFxCategoryFilter: String = "All"

    private var cursorFxCategories: [String] {
        ["All", "Sweet Treats 🍦", "Cosmic & Magic ✨", "Cyber & Arcade ⚡️", "Nature & Elements 🌊"]
    }

    private var cursorFxCategoryMap: [String: String] {
        [
            "Ice Cream Cone & Sprinkles 🍦": "Sweet Treats 🍦",
            "Cotton Candy Clouds 🍭": "Sweet Treats 🍦",

            "Stardust Sparkles ✨": "Cosmic & Magic ✨",
            "Rainbow Nebula Comet 🌈": "Cosmic & Magic ✨",
            "Golden Gate Bridge Shimmer 🌉": "Cosmic & Magic ✨",
            "Hyperdrive Warp Beams 🌌": "Cosmic & Magic ✨",
            "Quantum Vortex 🌪️": "Cosmic & Magic ✨",

            "Cyber Neon Ribbon ⚡️": "Cyber & Arcade ⚡️",
            "Electric Lightning Arc ⚡": "Cyber & Arcade ⚡️",
            "Matrix Green Binary Stream 🟢": "Cyber & Arcade ⚡️",
            "Pixel 8-Bit Arcade Blast 👾": "Cyber & Arcade ⚡️",
            "Cyber Ring & Target 🎯": "Cyber & Arcade ⚡️",

            "Fire Ember Sparks 🔥": "Nature & Elements 🌊",
            "Deep Ocean Bubble Wake 🫧": "Nature & Elements 🌊",
            "Heart Petal Drift 🌸": "Nature & Elements 🌊",

            "None": "All"
        ]
    }

    private var cursorFxOptions: [String] {
        [
            "Ice Cream Cone & Sprinkles 🍦", "Cotton Candy Clouds 🍭",
            "Stardust Sparkles ✨", "Rainbow Nebula Comet 🌈", "Cyber Neon Ribbon ⚡️",
            "Fire Ember Sparks 🔥", "Deep Ocean Bubble Wake 🫧", "Electric Lightning Arc ⚡",
            "Matrix Green Binary Stream 🟢", "Golden Gate Bridge Shimmer 🌉", "Hyperdrive Warp Beams 🌌",
            "Heart Petal Drift 🌸", "Pixel 8-Bit Arcade Blast 👾", "Cyber Ring & Target 🎯",
            "Quantum Vortex 🌪️", "None"
        ]
    }

    private var filteredCursorFx: [String] {
        if cursorFxCategoryFilter == "All" {
            return cursorFxOptions
        }
        return cursorFxOptions.filter { cursorFxCategoryMap[$0] == cursorFxCategoryFilter || $0 == "None" }
    }

    private var appFormations: [String] {
        [
            "Responsive Grid", "Surround Search Bar Grid 🪔", "Lined Up Above Chat ⬆️", "Custom Formation 🛠️", "Simple Square ⏹️", "Simple Circle ⭕️", "Simple Triangle 🔺",
            "Smart Resizable Matrix 🔲",
            "Left Rail Train 🚂", "Right Rail Train 🚂", "Top Horizon Train 🚂", "Bottom Dock Train 🚂", "Vanishing V-Formation 🦅",
            "Centered Single Dock ↔️", "Centered Column Strip ↕️",
            "Orbiting Border Ring 🔄", "Random Pulsing Bubbles 🫧",
            "Jelly Bulge 🍮", "Springy Trampoline 🤸", "Floating Lotus Flower 🪷",
            "Cyber Neon City Grid 🏙️", "Hyperspace Star Gate 🌌", "Floating Island Clusters 🏝️",
            "Rectangular Frame 🔲", "Center Monolith Box ⏹️", "Golden Rectangle 📐",
            "Bottom Shelf & Active Desktop 🖥️", "Bottom Dock Arc ⬇️", "Four Corners Quad ⊞", "Dual Column Grid 📑",
            "Top Horizon Bar ⬆️", "Left Column Dock ◀️", "Right Column Dock ▶️",
            "Dual Flank Wings 🪽", "Fibonacci Galaxy 🌀", "DNA Double Helix 🧬",
            "Spiral Nautilus 🐚", "Hourglass Infinity ⏳", "Solar System Orbit 🪐",
            "Pyramid Monolith 🏛️", "Crescent Moon 🌙", "Cyber Vortex 🌪️",
            "Kaleidoscope Prism 🔮", "Heart Cluster ❤️", "Diamond Lattice 💎",
            "Honeycomb Lattice ⬡", "Stellar Wave 🌊", "Supernova Burst 💥",
            "Tesseract Hypercube 🧊", "Zen Garden Yin-Yang ☯️", "Halfpipe Arc 🛹",
            "Dolphin Breach Arc 🐬", "Reef Vortex 🐠"
        ]
    }

    private let formationCategories: [String] = [
        "All", "Basic Shapes 📐", "Infinite Trains & Rails 🚂", "Kinetic & Orbiting 🔄", "Rectangles & Docks 🔲", "Geometric & Cosmic 🌌"
    ]

    private var formationCategoryMap: [String: String] {
        [
            "Lined Up Above Chat ⬆️": "Basic Shapes 📐",
            "Custom Formation 🛠️": "Basic Shapes 📐",
            "Simple Square ⏹️": "Basic Shapes 📐",
            "Simple Circle ⭕️": "Basic Shapes 📐",
            "Simple Triangle 🔺": "Basic Shapes 📐",
            "Left Rail Train 🚂": "Infinite Trains & Rails 🚂",
            "Right Rail Train 🚂": "Infinite Trains & Rails 🚂",
            "Top Horizon Train 🚂": "Infinite Trains & Rails 🚂",
            "Bottom Dock Train 🚂": "Infinite Trains & Rails 🚂",
            "Vanishing V-Formation 🦅": "Infinite Trains & Rails 🚂",

            "Smart Resizable Matrix 🔲": "Rectangles & Docks 🔲",
            "Centered Single Dock ↔️": "Rectangles & Docks 🔲",
            "Centered Column Strip ↕️": "Rectangles & Docks 🔲",
            "Orbiting Border Ring 🔄": "Kinetic & Orbiting 🔄",
            "Random Pulsing Bubbles 🫧": "Kinetic & Orbiting 🔄",
            "Jelly Bulge 🍮": "Kinetic & Orbiting 🔄",
            "Springy Trampoline 🤸": "Kinetic & Orbiting 🔄",
            "Floating Lotus Flower 🪷": "Kinetic & Orbiting 🔄",
            "Hyperspace Star Gate 🌌": "Kinetic & Orbiting 🔄",
            "DNA Double Helix 🧬": "Kinetic & Orbiting 🔄",
            "Cyber Vortex 🌪️": "Kinetic & Orbiting 🔄",
            "Kaleidoscope Prism 🔮": "Kinetic & Orbiting 🔄",
            "Stellar Wave 🌊": "Kinetic & Orbiting 🔄",
            "Supernova Burst 💥": "Kinetic & Orbiting 🔄",
            "Halfpipe Arc 🛹": "Kinetic & Orbiting 🔄",
            "Dolphin Breach Arc 🐬": "Kinetic & Orbiting 🔄",
            "Reef Vortex 🐠": "Kinetic & Orbiting 🔄",

            "Responsive Grid": "Rectangles & Docks 🔲",
            "Rectangular Frame 🔲": "Rectangles & Docks 🔲",
            "Center Monolith Box ⏹️": "Rectangles & Docks 🔲",
            "Golden Rectangle 📐": "Rectangles & Docks 🔲",
            "Bottom Shelf & Active Desktop 🖥️": "Rectangles & Docks 🔲",
            "Bottom Dock Arc ⬇️": "Rectangles & Docks 🔲",
            "Four Corners Quad ⊞": "Rectangles & Docks 🔲",
            "Dual Column Grid 📑": "Rectangles & Docks 🔲",
            "Top Horizon Bar ⬆️": "Rectangles & Docks 🔲",
            "Left Column Dock ◀️": "Rectangles & Docks 🔲",
            "Right Column Dock ▶️": "Rectangles & Docks 🔲",
            "Dual Flank Wings 🪽": "Rectangles & Docks 🔲",
            "Cyber Neon City Grid 🏙️": "Rectangles & Docks 🔲",

            "Floating Island Clusters 🏝️": "Geometric & Cosmic 🌌",
            "Fibonacci Galaxy 🌀": "Geometric & Cosmic 🌌",
            "Spiral Nautilus 🐚": "Geometric & Cosmic 🌌",
            "Hourglass Infinity ⏳": "Geometric & Cosmic 🌌",
            "Solar System Orbit 🪐": "Geometric & Cosmic 🌌",
            "Pyramid Monolith 🏛️": "Geometric & Cosmic 🌌",
            "Crescent Moon 🌙": "Geometric & Cosmic 🌌",
            "Heart Cluster ❤️": "Geometric & Cosmic 🌌",
            "Diamond Lattice 💎": "Geometric & Cosmic 🌌",
            "Honeycomb Lattice ⬡": "Geometric & Cosmic 🌌",
            "Tesseract Hypercube 🧊": "Geometric & Cosmic 🌌",
            "Zen Garden Yin-Yang ☯️": "Geometric & Cosmic 🌌"
        ]
    }

    private var filteredFormations: [String] {
        var list = appFormations
        if formationCategoryFilter != "All" {
            list = list.filter { formationCategoryMap[$0] == formationCategoryFilter }
        }
        if !formationSearchQuery.trimmingCharacters(in: .whitespaces).isEmpty {
            let q = formationSearchQuery.lowercased()
            list = list.filter { $0.lowercased().contains(q) }
        }
        return list
    }

    private let shaderCategories: [String] = [
        "All", "4K Dynamic 🌊", "Cosmic & Space 🌌", "Sci-Fi & Cyber ⚡️"
    ]

    private var shaderCategoryMap: [String: String] {
        [
            "Mystical Genie Smoke 💨": "4K Dynamic 🌊",
            "Liquid Glass ✨": "4K Dynamic 🌊",
            "4K Ocean Caustics 🌊": "4K Dynamic 🌊",
            "4K Marine Bioluminescence ✨": "4K Dynamic 🌊",
            "Sakura Petal Blizzard 🌸": "4K Dynamic 🌊",
            "Fluid Waves": "4K Dynamic 🌊",
            "Fluid Ink Chromatography 🎨": "4K Dynamic 🌊",
            "Volcanic Magma": "4K Dynamic 🌊",
            "Bioluminescent Sea": "4K Dynamic 🌊",

            "Supermassive Black Hole Lens 🕳️": "Cosmic & Space 🌌",
            "Hyperdrive Warp Speed ⚡️": "Cosmic & Space 🌌",
            "Cosmic Aurora": "Cosmic & Space 🌌",
            "Floating Stardust": "Cosmic & Space 🌌",
            "Starfield Warp": "Cosmic & Space 🌌",
            "Prismatic Rays": "Cosmic & Space 🌌",

            "Electric Plasma Lightning Storm ⚡️": "Sci-Fi & Cyber ⚡️",
            "Matrix Digital Rain Stream 🟢": "Sci-Fi & Cyber ⚡️",
            "4K Tokyo Neon Night Rain 🌧️": "Sci-Fi & Cyber ⚡️",
            "Cyber Horizon": "Sci-Fi & Cyber ⚡️",
            "Retro CRT Vector Grid 🕹️": "Sci-Fi & Cyber ⚡️"
        ]
    }

    private var filteredShaders: [String] {
        if shaderCategoryFilter == "All" { return wallpaperFxOptions }
        return wallpaperFxOptions.filter { shaderCategoryMap[$0] == shaderCategoryFilter || $0 == "None" }
    }

    private let entityCategories: [String] = [
        "All", "Ocean & Marine 🐬", "Fantasy & Dragons 🐉", "Cyber & Beasts 🐺", "Sports & Dynamics ⚽"
    ]

    private var entityCategoryMap: [String: String] {
        [
            "Pacific Ocean Dolphins 🐬": "Ocean & Marine 🐬",
            "Coral Reef Aquaria 🐠": "Ocean & Marine 🐬",
            "Deep Sea Mantas 🌊": "Ocean & Marine 🐬",
            "Japanese Koi Pond 🎏": "Ocean & Marine 🐬",
            "Gliding Sea Turtle 🐢": "Ocean & Marine 🐬",
            "Bioluminescent Jellyfish 🪼": "Ocean & Marine 🐬",
            "Baby Octo Float 🐙": "Ocean & Marine 🐬",
            "Cosmic Star Whale": "Ocean & Marine 🐬",
            "Cosmic Star Whale 🐋": "Ocean & Marine 🐬",
            "Deep Void Star Kraken 🦑": "Ocean & Marine 🐬",
            "Japanese Koi Sanctuary 🎏": "Ocean & Marine 🐬",

            "Celestial Dragon": "Fantasy & Dragons 🐉",
            "Inferno Fire Dragon 🔥": "Fantasy & Dragons 🐉",
            "Frost Wyrm (Ice Dragon) ❄️": "Fantasy & Dragons 🐉",
            "Void Shadow Dragon 🔮": "Fantasy & Dragons 🐉",
            "Cyber Phoenix": "Fantasy & Dragons 🐉",
            "Spirit Kitsune": "Fantasy & Dragons 🐉",
            "Cherry Blossom 9-Tail Kitsune 🦊": "Fantasy & Dragons 🐉",
            "Floating Pixie Fairy ✨": "Fantasy & Dragons 🐉",
            "Origami Paper Cranes 🕊️": "Fantasy & Dragons 🐉",
            "Golden Fireflies 🏮": "Fantasy & Dragons 🐉",

            "Red Panda Climber 🐾": "Cyber & Beasts 🐺",
            "Cute Capybara with Citrus 🍊": "Cyber & Beasts 🐺",
            "Monarch Butterflies 🦋": "Cyber & Beasts 🐺",
            "Floating Astronaut Spacewalk 👨‍🚀": "Cyber & Beasts 🐺",
            "Cyber Sentry Drone 🛸": "Cyber & Beasts 🐺",
            "Pixel Cyber Neko 🐱": "Cyber & Beasts 🐺",
            "Cyber Alpha Wolf 🐺": "Cyber & Beasts 🐺",
            "8-Bit Arcade Ghost 👻": "Cyber & Beasts 🐺",
            "Pixel Yoshi Companion 🦖": "Cyber & Beasts 🐺",
            "Matrix Rain": "Cyber & Beasts 🐺",

            
            "Champions Soccer ⚽": "Sports & Dynamics ⚽",
            "Hoops Basketball 🏀": "Sports & Dynamics ⚽",
            "Formula Racing 🏎️": "Sports & Dynamics ⚽",
            "Autumn Leaves 🍁": "Sports & Dynamics ⚽",
            "Sakura Storm 🌸": "Sports & Dynamics ⚽"
        ]
    }

    private var filteredEntities: [String] {
        if entityCategoryFilter == "All" { return ambientEntities }
        return ambientEntities.filter { entityCategoryMap[$0] == entityCategoryFilter || $0 == "None" }
    }

    private let snuggieCategories: [String] = [
        "All", "Cute Pets 🐱", "Cosmic & Cyber ⚡️", "Festive & Luxury 👑"
    ]

    private var snuggieCategoryMap: [String: String] {
        [
            "Sleeping Kitty 🐱": "Cute Pets 🐱",
            "Fox & Tail 🦊": "Cute Pets 🐱",
            "Panda Hug 🐼": "Cute Pets 🐱",
            "Sprout Leaf 🌱": "Cute Pets 🐱",
            "Living Vines 🌿": "Cute Pets 🐱",

            "Cyber Frame ⚡️": "Cosmic & Cyber ⚡️",
            "Astronaut Visor 👨‍🚀": "Cosmic & Cyber ⚡️",
            "Cyber Samurai Mask 🥷": "Cosmic & Cyber ⚡️",
            "Flame Corona 🔥": "Cosmic & Cyber ⚡️",
            "Pixel Heart Armor ❤️": "Cosmic & Cyber ⚡️",

            "Winter Scarf 🧣": "Festive & Luxury 👑",
            
            "Sakura Wreath 🌸": "Festive & Luxury 👑",
            "Sakura Shinto Gate ⛩️": "Festive & Luxury 👑",
            "Golden Halo Corona 😇": "Festive & Luxury 👑",
            "Diamond Bezel 💎": "Festive & Luxury 👑",
            "Imperial Crown 👑": "Festive & Luxury 👑",
            "Dragon Scales 🐉": "Festive & Luxury 👑",
            "Coral Reef Ring 🪸": "Festive & Luxury 👑",
            "Ice Cream Cone 🍦": "Festive & Luxury 👑"
        ]
    }

    private var filteredSnuggies: [(name: String, desc: String, icon: String, tint: Color)] {
        if snuggieCategoryFilter == "All" { return iconSnuggies }
        return iconSnuggies.filter { snuggieCategoryMap[$0.name] == snuggieCategoryFilter || $0.name == "None" }
    }

    private var ambientEntities: [String] {
        [
            "Pacific Ocean Dolphins 🐬", "Coral Reef Aquaria 🐠", "Deep Sea Mantas 🌊",
            "Japanese Koi Pond 🎏", "Japanese Koi Sanctuary 🎏", "Red Panda Climber 🐾",
            "Gliding Sea Turtle 🐢", "Origami Paper Cranes 🕊️", "Bioluminescent Jellyfish 🪼",
            "Cute Capybara with Citrus 🍊", "Floating Astronaut Spacewalk 👨‍🚀", "Baby Octo Float 🐙",
            "Champions Soccer ⚽", "Hoops Basketball 🏀", "Formula Racing 🏎️",
            "Golden Fireflies 🏮", "Autumn Leaves 🍁", "Sakura Storm 🌸",
            "Floating Pixie Fairy ✨", "Cyber Sentry Drone 🛸", "Celestial Dragon",
            "Inferno Fire Dragon 🔥", "Frost Wyrm (Ice Dragon) ❄️", "Void Shadow Dragon 🔮",
            "Cyber Phoenix", "Spirit Kitsune", "Cosmic Star Whale", "Cosmic Star Whale 🐋",
            "Pixel Cyber Neko 🐱", "Cyber Alpha Wolf 🐺", "Cherry Blossom 9-Tail Kitsune 🦊",
            "Deep Void Star Kraken 🦑", "8-Bit Arcade Ghost 👻", "Pixel Yoshi Companion 🦖",
            "Monarch Butterflies 🦋", "Matrix Rain", "None"
        ]
    }

    private var iconSnuggies: [(name: String, desc: String, icon: String, tint: Color)] {
        [
            ("None", "Standard clean icon frame", "slash.circle", .secondary),
            ("Sleeping Kitty 🐱", "Curled cat sleeping on top with swaying tail", "cat.fill", .orange),
            ("Fox & Tail 🦊", "Fluffy red fox wrapped around icon perimeter", "pawprint.fill", .red),
            ("Panda Hug 🐼", "Cute panda hanging onto top corners with paws", "circle.grid.cross.fill", .purple),
            ("Winter Scarf 🧣", "Cozy knit woolen scarf with dangling fringes", "wind", .pink),
            ("Cyber Frame ⚡️", "Sci-fi neon glowing corner brackets & conduits", "bolt.fill", .cyan),
            ("Living Vines 🌿", "Lush green ivy creeping with tiny blossoms", "leaf.fill", .green),
            ("Coral Reef Ring 🪸", "Ocean anemone tentacles and bubble ring", "water.waves", .blue),
            ("Diamond Bezel 💎", "Luxury sparkling diamond facet bezel", "diamond.fill", .purple),
            ("Flame Corona 🔥", "Fiery solar plasma licking around icon edges", "flame.fill", .yellow),
            ("Sakura Wreath 🌸", "Delicate pink cherry blossom garland frame", "leaf.arrow.circlepath", .pink),
            ("Dragon Scales 🐉", "Golden dragon horns perched with emerald scales", "flame", .green),
            ("Astronaut Visor 👨‍🚀", "Curved space helmet glass dome visor", "globe", .cyan),
            ("Cyber Samurai Mask 🥷", "Futuristic neon demon battle mask visor", "shield.fill", .cyan),
            ("Pixel Heart Armor ❤️", "8-Bit retro arcade heart protective battle armor frame", "heart.fill", .pink),
            ("Sakura Shinto Gate ⛩️", "Ornate Japanese vermillion Torii gate shrine", "house.fill", .red),
            ("Golden Halo Corona 😇", "Divine glowing angelic light ring with radiant rays", "sun.max.fill", .yellow),
            ("Sprout Leaf 🌱", "Cute anime plant seedling growing on top", "leaf", .green),
            ("Imperial Crown 👑", "Royal gold tiara with glowing gemstones", "crown.fill", .yellow),
            ("Ice Cream Cone 🍦", "Waffle cone perched with melting neapolitan scoops & rainbow sprinkles", "sparkles", .pink)
        ]
    }

    private var tintColors: [String] {
        ["Emerald", "Cyan", "Electric Blue", "Cyber Pink", "Purple", "Solar Amber", "Ruby Red", "Gold"]
    }

    private var iconStyles: [String] {
        [
            "Digital Clock 7-Segment", "Retro LCD Matrix Clock", "Cyber Neon Digits",
            "Nixie Tube Digits", "Bold Minimal Digital", "Digital LED Dot Matrix", "VisionOS Digital Pill",
            "Apple Minimal", "Minimal Pill", "VisionOS Pill", "10-Bar Gauge", "10-Bar Equalizer",
            "Equalizer Bars", "Liquid Wave", "Dynamic Wave", "10 Neon LEDs", "Tesla Cell Pack",
            "Audio VU Meter", "Pixel Heart", "Cyberpunk Matrix", "DNA Helix",
            "Circular Dual Arc", "Radial Ring", "Animated Hex", "Tachometer Arc",
            "Solar Core", "8-Bit Arcade", "Prism Pulse", "Retro Dot Matrix",
            "Ocean Dolphin 🐬", "Coral Reef Fish 🐠", "Skateboard Deck 🛹",
            "Genie Logo", "Genie Bolt", "Monochrome"
        ]
    }

    private let batteryStyleCategories: [String] = [
        "All", "Digital 🔢", "Minimal 🍏", "Equalizers 🎵", "Cyber & Sci-Fi ⚡️", "Gauges & Rings 🧭", "Pixel & Retro 👾"
    ]

    private var batteryStyleCategoryMap: [String: String] {
        [
            "Digital Clock 7-Segment": "Digital 🔢",
            "Retro LCD Matrix Clock": "Digital 🔢",
            "Cyber Neon Digits": "Digital 🔢",
            "Nixie Tube Digits": "Digital 🔢",
            "Bold Minimal Digital": "Digital 🔢",
            "Digital LED Dot Matrix": "Digital 🔢",
            "VisionOS Digital Pill": "Digital 🔢",

            "Apple Minimal": "Minimal 🍏",
            "Minimal Pill": "Minimal 🍏",
            "VisionOS Pill": "Minimal 🍏",
            "Monochrome": "Minimal 🍏",
            "Genie Logo": "Minimal 🍏",
            "Genie Bolt": "Minimal 🍏",

            "10-Bar Equalizer": "Equalizers 🎵",
            "Equalizer Bars": "Equalizers 🎵",
            "Audio VU Meter": "Equalizers 🎵",
            "Liquid Wave": "Equalizers 🎵",
            "Dynamic Wave": "Equalizers 🎵",
            "10-Bar Gauge": "Equalizers 🎵",

            "10 Neon LEDs": "Cyber & Sci-Fi ⚡️",
            "Tesla Cell Pack": "Cyber & Sci-Fi ⚡️",
            "Cyberpunk Matrix": "Cyber & Sci-Fi ⚡️",
            "DNA Helix": "Cyber & Sci-Fi ⚡️",
            "Animated Hex": "Cyber & Sci-Fi ⚡️",
            "Solar Core": "Cyber & Sci-Fi ⚡️",
            "Prism Pulse": "Cyber & Sci-Fi ⚡️",

            "Circular Dual Arc": "Gauges & Rings 🧭",
            "Radial Ring": "Gauges & Rings 🧭",
            "Tachometer Arc": "Gauges & Rings 🧭",
            "Ocean Dolphin 🐬": "Gauges & Rings 🧭",
            "Coral Reef Fish 🐠": "Gauges & Rings 🧭",

            "Pixel Heart": "Pixel & Retro 👾",
            "8-Bit Arcade": "Pixel & Retro 👾",
            "Retro Dot Matrix": "Pixel & Retro 👾"
        ]
    }

    private var filteredBatteryStyles: [String] {
        if batteryStyleCategoryFilter == "All" { return iconStyles }
        return iconStyles.filter { batteryStyleCategoryMap[$0] == batteryStyleCategoryFilter }
    }

    private var batteryColorModes: [String] {
        [
            "Dynamic Level", "Neon Cyan", "Cyber Pink", "Electric Violet", "Emerald Green",
            "Solar Orange", "Crimson Red", "Monochrome White", "Monochrome Dim", "Rainbow Aura"
        ]
    }

    private var batteryNumberThemes: [String] {
        [
            "Dynamic Match", "Classic Mono", "Matrix Glow", "Cyber Neon", "Solar Amber",
            "Electric Violet", "Minimal Thin"
        ]
    }

    private var hiddenAppIDs: Set<String> {
        let _ = hiddenAppsRevision
        return Set(UserDefaults.standard.stringArray(forKey: PrefKey.hiddenAppIDs) ?? [])
    }

    private var filteredAllApps: [AppInfo] {
        var list = appModel.apps
        if !appSearchQuery.isEmpty {
            list = list.filter { $0.name.localizedCaseInsensitiveContains(appSearchQuery) }
        }
        switch appVisibilityFilter {
        case "visible":
            return list.filter { !hiddenAppIDs.contains($0.id) }
        case "hidden":
            return list.filter { hiddenAppIDs.contains($0.id) }
        default:
            return list
        }
    }

    private func colorGradientForMode(_ mode: String) -> LinearGradient {
        switch mode {
        case "Rainbow Aura", "Rainbow Flow":
            return LinearGradient(colors: [.red, .orange, .yellow, .green, .blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "Neon Cyan":
            return LinearGradient(colors: [Color(red: 0.0, green: 0.95, blue: 1.0), Color(red: 0.0, green: 0.6, blue: 0.9)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "Cyber Pink":
            return LinearGradient(colors: [Color(red: 1.0, green: 0.15, blue: 0.70), Color(red: 0.8, green: 0.0, blue: 0.5)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "Electric Violet":
            return LinearGradient(colors: [Color(red: 0.85, green: 0.45, blue: 1.0), Color(red: 0.5, green: 0.1, blue: 0.9)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "Emerald Green":
            return LinearGradient(colors: [Color(red: 0.2, green: 0.9, blue: 0.4), Color(red: 0.0, green: 0.7, blue: 0.3)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "Solar Orange":
            return LinearGradient(colors: [Color(red: 1.0, green: 0.6, blue: 0.1), Color(red: 1.0, green: 0.3, blue: 0.0)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "Crimson Red":
            return LinearGradient(colors: [Color(red: 1.0, green: 0.2, blue: 0.3), Color(red: 0.7, green: 0.0, blue: 0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "Monochrome White":
            return LinearGradient(colors: [.white, .gray.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case "Monochrome Dim":
            return LinearGradient(colors: [.gray, .black], startPoint: .topLeading, endPoint: .bottomTrailing)
        default: // Dynamic Level
            return LinearGradient(colors: [.green, .yellow, .red], startPoint: .leading, endPoint: .trailing)
        }
    }

    var body: some View {
        studioBody
    }

    private var studioBody: some View {
        ZStack {
            // MARK: - Window Graphics Backing (Aero Glass Vibrancy, Background Images & Shaders)
            if windowGraphicsEnabled {
                // 1. Native Apple Frosted Glass Blur behind window
                VisualEffectBlur(
                    material: .popover,
                    blendingMode: .behindWindow,
                    state: .active,
                    cornerRadius: 18
                )

                // 2. Dropdown Window Background Image / Preset
                GeometryReader { bgGeo in
                    ZStack {
                        if dropdownBgPreset == "custom", let customImg = DropdownBackgroundManager.shared.customImage {
                            Image(nsImage: customImg)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: bgGeo.size.width, height: bgGeo.size.height)
                                .clipped()
                                .blur(radius: CGFloat(dropdownBgBlur))
                                .opacity(dropdownBgOpacity)
                        } else if dropdownBgPreset == "wallpaper_mirror" {
                            if let wp = wallpaperManager.activeWallpaperImage {
                                Image(nsImage: wp)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: bgGeo.size.width, height: bgGeo.size.height)
                                    .clipped()
                                    .blur(radius: CGFloat(dropdownBgBlur))
                                    .opacity(dropdownBgOpacity)
                            } else {
                                let preset = DropdownBackgroundManager.shared.currentPreset()
                                LinearGradient(
                                    colors: preset.gradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                .frame(width: bgGeo.size.width, height: bgGeo.size.height)
                                .blur(radius: CGFloat(dropdownBgBlur))
                                .opacity(dropdownBgOpacity)
                            }
                        } else {
                            let preset = DropdownBackgroundManager.shared.currentPreset()
                            LinearGradient(
                                colors: preset.gradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            .frame(width: bgGeo.size.width, height: bgGeo.size.height)
                            .blur(radius: CGFloat(dropdownBgBlur))
                            .opacity(dropdownBgOpacity)
                        }

                        // 3. Dynamic Atmospheric Shader Canvas (Matching the Desktop Shaders!)
                        if isPanelVisible && windowShaderFxEnabled && (wallpaperFxEnabled || wallpaperFxType != "None") {
                            AtmosphericShaderCanvas(
                                type: wallpaperFxType,
                                intensity: CGFloat(wallpaperFxIntensity * 0.70),
                                isPaused: !isPanelVisible
                            )
                            .frame(width: bgGeo.size.width, height: bgGeo.size.height)
                        }
                    }
                }
                .allowsHitTesting(false)
            }

            // Studio Theme Tint (Translucent liquid glass backdrop matching macOS System Settings!)
            RoundedRectangle(cornerRadius: isFoldedToBar ? 12 : 18, style: .continuous)
                .fill(studioThemePalette.bg.opacity(isFoldedToBar ? 0.75 : 0.35))

            VStack(spacing: 0) {
                // Top Minimalist Floating Bubble Overlay Bar (Apple Theme Standards)
                if selectedTab != .chat {
                    topGlobalBar
                        .padding(.horizontal, 14)
                        .padding(.vertical, isFoldedToBar ? 6 : 8)
                        .background(WindowDragAreaView())
                }

                if !isFoldedToBar {
                    GeometryReader { geo in
                        detailContentPanel
                            .frame(width: geo.size.width, height: geo.size.height)
                            .clipped()
                            .background(selectedTab == .chat ? Color.clear : studioThemePalette.content)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .transition(.opacity.combined(with: .scale(scale: 0.99)))
                }
            }

            if showResetConfirmOverlay {
                Color.black.opacity(0.40)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .onTapGesture {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                            showResetConfirmOverlay = false
                        }
                    }

                VStack(spacing: 12) {
                    Image(systemName: "arrow.counterclockwise.circle.fill")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.orange)

                    Text(LocalizedStrings.translateText("Reset to Default Clean Grid?", lang: appLanguage))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primary)

                    Text(LocalizedStrings.translateText("This will restore the standard responsive grid and disable all active creatures, wallpaper shaders, and cursor trails.", lang: appLanguage))
                        .font(.system(size: 11.5))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)

                    HStack(spacing: 10) {
                        Button(action: {
                            HapticFeedback.selection()
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                                showResetConfirmOverlay = false
                            }
                        }) {
                            Text(LocalizedStrings.translateText("Cancel", lang: appLanguage))
                                .font(.system(size: 12, weight: .medium))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(RoundedRectangle(cornerRadius: 7).fill(Color.primary.opacity(0.08)))
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            HapticFeedback.heavy()
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                                showResetConfirmOverlay = false
                            }
                            restoreCleanDefaults()
                        }) {
                            Text(LocalizedStrings.translateText("Reset Defaults", lang: appLanguage))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(RoundedRectangle(cornerRadius: 7).fill(Color.orange))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                }
                .padding(20)
                .background(
                    VisualEffectBlur(material: .popover, blendingMode: .withinWindow, cornerRadius: 18)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(Color.orange.opacity(0.6), lineWidth: 1.2)
                        )
                        .shadow(color: Color.black.opacity(0.4), radius: 24, x: 0, y: 10)
                )
                .frame(maxWidth: 340)
                .transition(.scale(scale: 0.94).combined(with: .opacity))
            }

            if showingOnboardingWizard {
                QuickSetupWizardView(isPresented: $showingOnboardingWizard)
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
            }
        }
        .frame(minWidth: 460, maxWidth: .infinity, minHeight: 360, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.38),
                            Color.white.opacity(0.14),
                            Color.white.opacity(0.06),
                            Color.white.opacity(0.22)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.75
                )
        )
        .overlay(
            GeometryReader { geo in
                ZStack {
                    if smokeEffectsEnabled {
                        GenieSmokeOverlayView(
                            style: smokeStyle,
                            bounds: geo.size
                        )
                    }
                }
                .onAppear {
                    popoverBounds = geo.size
                }
            }
            .allowsHitTesting(false)
        )
        .scaleEffect(genieScale, anchor: genieAnchor)
        .opacity(genieOpacity)
        .offset(y: genieOffsetY)
        .onAppear {
            isFoldedToBar = false
            UserDefaults.standard.set(false, forKey: PrefKey.isFoldedToBar)
            genieScale = 1.0
            genieOpacity = 1.0
            genieOffsetY = 0.0
            installKeyMonitorIfNeeded()
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                previewPhase = 1.0
            }
        }
        .onDisappear {
            genieScale = 1.0
            genieOpacity = 1.0
            genieOffsetY = 0.0
            if let keyMonitor {
                NSEvent.removeMonitor(keyMonitor)
                self.keyMonitor = nil
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusMenuBarPanelVisibilityChanged"))) { notif in
            if let isVis = notif.object as? Bool {
                isPanelVisible = isVis
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusGenieReset"))) { _ in
            genieScale = 1.0
            genieOpacity = 1.0
            genieOffsetY = 0.0
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusGenieSummon"))) { notif in
            genieScale = 1.0
            genieOpacity = 1.0
            genieOffsetY = 0.0
            guard genieAnimEnabled else { return }

            var origin = "glyph"
            var glyphPct: CGFloat = 0.85
            if let dict = notif.object as? [String: Any] {
                origin = (dict["origin"] as? String) ?? "glyph"
                glyphPct = (dict["glyphXPercent"] as? CGFloat) ?? 0.85
            }

            let isDock = origin == "dock" || genieAnimOrigin.contains("Dock")

            if isDock {
                genieAnchor = .bottom
                genieScale = 0.88
                genieOpacity = 0.85
                genieOffsetY = 20
                withAnimation(.spring(response: 0.30, dampingFraction: 0.82)) {
                    genieScale = 1.0
                    genieOpacity = 1.0
                    genieOffsetY = 0.0
                }
                if smokeEffectsEnabled {
                    GenieSmokeEngine.shared.triggerBurst(
                        origin: .dock,
                        bounds: popoverBounds,
                        style: smokeStyle,
                        count: 36
                    )
                }
            } else {
                // Top Glyph
                genieAnchor = UnitPoint(x: glyphPct, y: 0.0)
                genieScale = 0.92
                genieOpacity = 0.90
                genieOffsetY = -10
                withAnimation(.spring(response: 0.28, dampingFraction: 0.84)) {
                    genieScale = 1.0
                    genieOpacity = 1.0
                    genieOffsetY = 0.0
                }
                if smokeEffectsEnabled {
                    GenieSmokeEngine.shared.triggerBurst(
                        origin: .topGlyph(xPercent: glyphPct),
                        bounds: popoverBounds,
                        style: smokeStyle,
                        count: 36
                    )
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusGenieDismiss"))) { notif in
            guard genieAnimEnabled else { return }
            let origin = (notif.object as? [String: Any])?["origin"] as? String ?? ""
            let isDock = origin == "dock" || genieAnimOrigin.contains("Dock")
            if isDock {
                genieAnchor = .bottom
                withAnimation(.spring(response: 0.22, dampingFraction: 0.88)) {
                    genieScale = 0.85
                    genieOpacity = 0.2
                    genieOffsetY = 20
                }
            } else {
                withAnimation(.spring(response: 0.20, dampingFraction: 0.90)) {
                    genieScale = 0.90
                    genieOpacity = 0.2
                    genieOffsetY = -10
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusSelectStudioTab"))) { notif in
            if let tabName = notif.object as? String {
                let matched = DropdownSidebarTab(caseInsensitive: tabName)
                withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                    selectedTab = matched
                    dropdownMode = .settings
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusCycleSettingsTab"))) { _ in
            withAnimation(.spring(response: 0.22, dampingFraction: 0.82)) {
                dropdownMode = .settings
                cycleNextTab()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusSetDropdownMode"))) { notif in
            if let modeStr = notif.object as? String, let mode = MenuBarDropdownMode(rawValue: modeStr) {
                withAnimation(.spring(response: 0.24, dampingFraction: 0.82)) {
                    dropdownMode = mode
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusIconStyleChanged"))) { _ in
            if let g = UserDefaults.standard.string(forKey: PrefKey.statusIconGlyph) ?? UserDefaults.standard.string(forKey: PrefKey.statusIconStyle) {
                statusIconStyle = g
            }
            if let s = UserDefaults.standard.string(forKey: PrefKey.batteryStyle) ?? UserDefaults.standard.string(forKey: PrefKey.iconStyle) {
                iconStyle = s
            }
            if let e = UserDefaults.standard.object(forKey: PrefKey.iconEnabled) as? Bool {
                iconEnabled = e
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusShowSetupWizard"))) { _ in
            withAnimation(.spring(response: 0.30, dampingFraction: 0.82)) {
                showingOnboardingWizard = true
            }
        }
    }

    // MARK: - Top Global Minimalist Bubble Bar (Apple Theme Standards)

    private var topGlobalBar: some View {
        HStack(alignment: .center, spacing: 8) {
            // ── 1. Left Bubble Pill: Traffic Lights & Sidebar Pop-out & Brand ──
            HStack(spacing: 7) {
                AppleTrafficLightsControl {
                    NotificationCenter.default.post(name: NSNotification.Name("NexusClose"), object: nil)
                }

                BrandLogoHeaderBadgeView()
                    .fixedSize()

                Text(LocalizedStrings.translateText("Genie", lang: appLanguage))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.35))
                    .overlay(VisualEffectBlur(material: .popover, blendingMode: .withinWindow).clipShape(Capsule()).opacity(0.5))
            )
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.18), lineWidth: 0.7))
            .shadow(color: Color.black.opacity(0.25), radius: 6, y: 2)

            Spacer(minLength: 6)

            // ── 2. Center Bubble Pill: Dynamic Model & Mode Selector Menu ──
            if selectedTab == .chat {
                Menu {
                    Toggle(isOn: Binding(
                        get: { localModels.autoSelectEnabled },
                        set: { if $0 { localModels.enableAutoSelect() } else { localModels.autoSelectEnabled = false } }
                    )) {
                        Text("Auto-Select Available Local Models")
                    }

                    Divider()

                    ForEach(LocalModelManager.cloudModels) { model in
                        Button(action: { localModels.selectModel(model.id) }) {
                            Text(localModels.effectiveModel == model.id ? "\(model.displayName) ✓" : model.displayName)
                        }
                    }

                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.cyan)

                        Text("Genie Chat")
                            .font(.system(size: 11.5, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text(localModels.selectedModelDisplayName)
                            .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                            .foregroundColor(.cyan)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1.5)
                            .background(Capsule().fill(Color.cyan.opacity(0.18)))

                        Image(systemName: "chevron.down")
                            .font(.system(size: 7.5, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4.5)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.35))
                            .overlay(VisualEffectBlur(material: .popover, blendingMode: .withinWindow).clipShape(Capsule()).opacity(0.5))
                    )
                    .overlay(Capsule().strokeBorder(Color.white.opacity(0.20), lineWidth: 0.7))
                    .shadow(color: Color.black.opacity(0.25), radius: 6, y: 2)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            } else {
                HStack(spacing: 6) {
                    HStack(spacing: 2) {
                        Button(action: { selectPreviousTab() }) {
                            Image(systemName: "chevron.up")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(selectedTab == DropdownSidebarTab.allCases.first ? .secondary.opacity(0.3) : .primary)
                                .frame(width: 18, height: 18)
                                .background(Circle().fill(Color.white.opacity(0.06)))
                        }
                        .buttonStyle(.plain)
                        .disabled(selectedTab == DropdownSidebarTab.allCases.first)

                        Button(action: { selectNextTab() }) {
                            Image(systemName: "chevron.down")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(selectedTab == DropdownSidebarTab.allCases.last ? .secondary.opacity(0.3) : .primary)
                                .frame(width: 18, height: 18)
                                .background(Circle().fill(Color.white.opacity(0.06)))
                        }
                        .buttonStyle(.plain)
                        .disabled(selectedTab == DropdownSidebarTab.allCases.last)
                    }

                    Image(systemName: selectedTab.icon)
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundColor(selectedTab.tintColor)

                    Text(LocalizedStrings.tabTitle(selectedTab.rawValue, lang: appLanguage))
                        .font(.system(size: 11.5, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    if selectedTab == .applications {
                        Text("\(appModel.visibleApps.count)")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4.5)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(Color.white.opacity(0.10)))
                    }
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 4.5)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.35))
                        .overlay(VisualEffectBlur(material: .popover, blendingMode: .withinWindow).clipShape(Capsule()).opacity(0.5))
                )
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.18), lineWidth: 0.7))
                .shadow(color: Color.black.opacity(0.25), radius: 6, y: 2)
            }

            Spacer(minLength: 6)

            // ── 3. Right Bubble Pill: Action Bubble Overlay ──
            HStack(spacing: 5) {
                if selectedTab == .chat {
                    // New Chat
                    Button(action: {
                        localModels.clearChatHistory()
                        HapticFeedback.selection()
                    }) {
                        HStack(spacing: 3.5) {
                            Image(systemName: "plus")
                                .font(.system(size: 8.5, weight: .bold))
                            Text("New")
                                .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3.5)
                        .background(Capsule().fill(Color.white.opacity(0.14)))
                    }
                    .buttonStyle(.plain)
                    .help("Start fresh chat")

                    // Consolidated Chat Actions Menu (...)
                    Menu {
                        Button(action: {
                            let text = localModels.chatHistory.map { "\($0.role.capitalized): \($0.content)" }.joined(separator: "\n\n")
                            _ = DesktopNotePrinter.shared.printNote(content: text, openInFile: true)
                            HapticFeedback.success()
                        }) {
                            Label("Save Chat to Desktop Note", systemImage: "doc.text")
                        }

                        if !localModels.chatHistory.isEmpty {
                            Divider()
                            Button(action: {
                                localModels.clearChatHistory()
                                HapticFeedback.tick()
                            }) {
                                Label("Clear Chat History", systemImage: "trash")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white.opacity(0.70))
                            .frame(width: 20, height: 20)
                            .background(Circle().fill(Color.white.opacity(0.08)))
                    }
                    .menuStyle(.borderlessButton)
                    .menuIndicator(.hidden)
                    .help("Chat Actions (Save Note, Clear)")
                } else if selectedTab == .applications {
                    Button(action: {
                        HapticFeedback.selection()
                        onRefreshApps?()
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 9.5, weight: .medium))
                            .foregroundColor(.secondary)
                            .frame(width: 20, height: 20)
                            .background(Circle().fill(Color.white.opacity(0.08)))
                    }
                    .buttonStyle(.plain)
                    .help("Refresh Applications")
                }

                // Window Expander (Restore / ^)
                Button(action: {
                    HapticFeedback.selection()
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        if windowSizeMode == "fullscreen" {
                            windowSizeMode = "normal"
                        } else {
                            windowSizeMode = "fullscreen"
                        }
                        menuCompactMode = false
                        NotificationCenter.default.post(name: NSNotification.Name("NexusWindowSizeModeChanged"), object: windowSizeMode)
                    }
                }) {
                    HStack(spacing: 2.5) {
                        Image(systemName: windowSizeMode == "fullscreen" ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 8.5, weight: .bold))
                        Text(windowSizeMode == "fullscreen" ? "Restore" : "^")
                            .font(.system(size: 9.5, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(windowSizeMode == "fullscreen" ? .accentColor : .white.opacity(0.85))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3.5)
                    .background(Capsule().fill(windowSizeMode == "fullscreen" ? Color.accentColor.opacity(0.20) : Color.white.opacity(0.10)))
                }
                .buttonStyle(.plain)
                .help(windowSizeMode == "fullscreen" ? "Restore Window Size" : "Expand Window (^)")

                // Window Options Menu
                Menu {
                    Section(LocalizedStrings.translateText("Window Size", lang: appLanguage)) {
                        Button("Normal Window (880 × 520)\(windowSizeMode == "normal" ? " ✓" : "")") {
                            HapticFeedback.selection()
                            windowSizeMode = "normal"
                            menuCompactMode = false
                            NotificationCenter.default.post(name: NSNotification.Name("NexusWindowSizeModeChanged"), object: "normal")
                        }
                        Button("Half Screen (50%)\(windowSizeMode == "half" ? " ✓" : "")") {
                            HapticFeedback.selection()
                            windowSizeMode = "half"
                            menuCompactMode = false
                            NotificationCenter.default.post(name: NSNotification.Name("NexusWindowSizeModeChanged"), object: "half")
                        }
                        Button("Full Screen Window\(windowSizeMode == "fullscreen" ? " ✓" : "")") {
                            HapticFeedback.selection()
                            windowSizeMode = "fullscreen"
                            menuCompactMode = false
                            NotificationCenter.default.post(name: NSNotification.Name("NexusWindowSizeModeChanged"), object: "fullscreen")
                        }
                    }

                    Section(LocalizedStrings.translateText("Screen Snapping", lang: appLanguage)) {
                        Button("Snap Left (⌘←)\(snapMode == "left" ? " ✓" : "")") {
                            HapticFeedback.selection()
                            snapMode = "left"
                            NotificationCenter.default.post(name: NSNotification.Name("NexusSnapPopover"), object: "left")
                        }
                        Button("Snap Under Menu Icon\(snapMode == "icon" ? " ✓" : "")") {
                            HapticFeedback.selection()
                            snapMode = "icon"
                            NotificationCenter.default.post(name: NSNotification.Name("NexusSnapPopover"), object: "icon")
                        }
                        Button("Snap Right (⌘→)\(snapMode == "right" ? " ✓" : "")") {
                            HapticFeedback.selection()
                            snapMode = "right"
                            NotificationCenter.default.post(name: NSNotification.Name("NexusSnapPopover"), object: "right")
                        }
                    }

                    Section(LocalizedStrings.translateText("Desktop Tiling (⌘⌥Space)", lang: appLanguage)) {
                        Button(LocalizedStrings.translateText("Bring All Windows to Screen", lang: appLanguage)) {
                            SmartGridManager.shared.bringAllToScreen()
                        }
                        Button(LocalizedStrings.translateText("Optimal Dynamic (Auto)", lang: appLanguage)) {
                            SmartGridManager.shared.activeChoice = .auto
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundColor(.white.opacity(0.85))
                        .frame(width: 20, height: 20)
                        .background(Circle().fill(Color.white.opacity(0.10)))
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                .help("Window Sizing & Snapping Options")
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.35))
                    .overlay(VisualEffectBlur(material: .popover, blendingMode: .withinWindow).clipShape(Capsule()).opacity(0.5))
            )
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.18), lineWidth: 0.7))
            .shadow(color: Color.black.opacity(0.25), radius: 6, y: 2)
        }
        .frame(height: 30)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Left Navigation Sidebar

    private var navigationSidebar: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 6) {
                // Sidebar Header: Pin / Auto-Hide Status & Collapse Button
                HStack(spacing: 6) {
                    Text("WORKSPACE")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary.opacity(0.85))

                    Spacer()

                    // Pin toggle button
                    Button(action: {
                        HapticFeedback.selection()
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                            isSidebarPinned.toggle()
                        }
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: isSidebarPinned ? "pin.fill" : "pin")
                                .font(.system(size: 8.5))
                            Text(isSidebarPinned ? "Pinned" : "Pin")
                                .font(.system(size: 9, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(isSidebarPinned ? .cyan : .secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2.5)
                        .background(Capsule().fill(isSidebarPinned ? Color.cyan.opacity(0.18) : Color.primary.opacity(0.06)))
                    }
                    .buttonStyle(.plain)
                    .help(isSidebarPinned ? "Unpin (Auto pop-out on hover)" : "Pin Sidebar side-by-side")

                    // Dismiss hover drawer
                    if !isSidebarPinned {
                        Button(action: {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.85)) {
                                isSidebarHoverTriggered = false
                                isSidebarHovered = false
                            }
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 8.5, weight: .bold))
                                .foregroundColor(.secondary)
                                .frame(width: 18, height: 18)
                                .background(Circle().fill(Color.primary.opacity(0.06)))
                        }
                        .buttonStyle(.plain)
                        .help("Hide Sidebar (⌘S)")
                    }
                }
                .padding(.horizontal, 10)
                .padding(.top, 6)
                .padding(.bottom, 2)

                sidebarSectionView(title: "Intelligence & Models", tabs: [.aiModels, .virtualMachines, .chat])
                sidebarSectionView(title: "Workspace & Applications", tabs: [.applications, .workspace, .formations])
                sidebarSectionView(title: "Utilities & Time", tabs: [.worldClock, .battery])
                sidebarSectionView(title: "Controls & Hardware", tabs: [.menuBar, .trackpad, .soundHaptics, .petsAndPinball])
                sidebarSectionView(title: "Appearance & Finishes", tabs: [.themes, .snuggies, .typography, .wallpapers])
                sidebarSectionView(title: "System & Governance", tabs: [.system, .privacy, .expansion])

                sidebarFooterControls
                    .padding(.top, 10)
            }
            .padding(.horizontal, 10)
            .padding(.top, 8)
            .padding(.bottom, 16)
        }
    }

    private var sidebarFooterControls: some View {
        VStack(spacing: 8) {
            Divider()
                .opacity(0.25)
                .padding(.horizontal, 4)

            // Bottom row: Light/Dark Theme + Reset Button
            HStack(spacing: 6) {
                LightDarkModeButton(studioTheme: $studioTheme, isStudioLight: isStudioLight, appLanguage: appLanguage)

                Spacer()

                Button(action: { askResetToDefaultConfirmation() }) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 9.5, weight: .semibold))
                        .foregroundColor(.orange.opacity(0.95))
                        .frame(width: 24, height: 24)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(Color.orange.opacity(0.14))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .strokeBorder(Color.orange.opacity(0.35), lineWidth: 0.6)
                        )
                }
                .buttonStyle(.plain)
                .help("Reset to default clean grid")
            }
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 8)
        .padding(.top, 4)
    }


    private func sidebarSectionView(title: String, tabs: [DropdownSidebarTab]) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(LocalizedStrings.translateText(title, lang: appLanguage).uppercased())
                .font(.system(size: 8.5, weight: .bold))
                .foregroundColor(.secondary.opacity(0.65))
                .padding(.horizontal, 10)
                .padding(.top, 6)
                .padding(.bottom, 1)

            ForEach(tabs) { tab in
                SidebarTabItemView(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    appLanguage: appLanguage,
                    badgeText: tab == .applications ? "\(appModel.visibleApps.count)" : (tab == .chat && localModels.chatHistory.count > 0 ? "\(localModels.chatHistory.count)" : nil),
                    onSelect: {
                        HapticFeedback.selection()
                        if tab == .chat && UserDefaults.standard.bool(forKey: PrefKey.unifyChatWindow) {
                            FinderChatWindowManager.shared.show(tab: .chat)
                            (NSApp.delegate as? AppDelegate)?.dismissMenuBarPopover()
                            return
                        }
                        withAnimation(.spring(response: 0.20, dampingFraction: 0.78)) {
                            selectedTab = tab
                        }
                    }
                )
            }
        }
    }

    // MARK: - Right Detail Content Panel

    @ViewBuilder
    private var detailContentPanel: some View {
        switch selectedTab {
        case .chat:
            chatDetailView
        case .applications:
            applicationsDetailView
        case .worldClock:
            WorldClockPaneView()
        case .virtualMachines:
            VirtualMachinesDashboardView()
        default:
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 14) {
                    switch selectedTab {
                    case .chat, .applications, .worldClock, .virtualMachines:
                        EmptyView()
                    case .workspace:
                        desktopGridDetailView
                    case .formations:
                        formationsDetailView
                    case .aiModels:
                        aiModelsDetailView
                    case .expansion:
                        expansionPacksDetailView
                    case .system:
                        preferencesDetailView
                    case .privacy:
                        privacyPermissionsDetailView
                    case .themes:
                        themesSubSectionView
                    case .snuggies:
                        snuggiesSubSectionView
                    case .typography:
                        FontsTabContentView()
                    case .wallpapers:
                        wallpaperFxDetailView
                    case .trackpad:
                        mouseAndTrackpadDetailView
                    case .soundHaptics:
                        soundsDetailView
                    case .petsAndPinball:
                        livingPetsAndPinballDetailView
                    case .menuBar:
                        menuBarSettingsDetailView
                    case .battery:
                        batteryDetailView
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
            }
        }
    }

    // MARK: - Flagship Genie Chat View (Dropdown First Page)

    private var chatDetailView: some View {
        VStack(spacing: 0) {
            // Live Mirror & Single Window Unification Header
            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                    Text("Live Mirror • Synced with Program Window")
                        .font(.system(size: 10.5, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.75))
                }

                Spacer()

                Button(action: {
                    HapticFeedback.selection()
                    FinderChatWindowManager.shared.show(tab: .chat)
                    (NSApp.delegate as? AppDelegate)?.dismissMenuBarPopover()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.forward.and.arrow.down.backward")
                            .font(.system(size: 9, weight: .bold))
                        Text("Merge into Single Window")
                            .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3.5)
                    .background(Capsule().fill(Color.cyan.opacity(0.16)))
                    .overlay(Capsule().strokeBorder(Color.cyan.opacity(0.35), lineWidth: 0.6))
                }
                .buttonStyle(.plain)
                .help("Focus and merge into the primary program window")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.25))

            FinderStyleChatWindowView(isEmbedded: true)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    /// Live predictive matches for the "apps" prompt mode — recognizes installed
    /// applications by name as you type, using the IPE-backed fuzzy search on AppModel.
    private var appPromptSuggestions: [AppInfo] {
        guard chatPromptMode == .apps else { return [] }
        let clean = chatPromptText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return [] }
        return Array(appModel.filteredApps(search: clean, category: nil).prefix(6))
    }

    private func abbreviatedPath(_ url: URL) -> String {
        (url.path as NSString).abbreviatingWithTildeInPath
    }

    private var appPredictionOverlay: some View {
        let suggestions = appPromptSuggestions
        return VStack(spacing: 0) {
            if !suggestions.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(suggestions.enumerated()), id: \.element.id) { index, app in
                        let isSelected = index == selectedAppSuggestionIndex
                        Button(action: {
                            selectedAppSuggestionIndex = index
                            handleChatPromptSubmit()
                        }) {
                            HStack(spacing: 8) {
                                Image(nsImage: app.icon)
                                    .resizable()
                                    .interpolation(.high)
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 22, height: 22)

                                VStack(alignment: .leading, spacing: 1) {
                                    HStack(spacing: 5) {
                                        Text(app.name)
                                            .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                                            .foregroundColor(.white)
                                        if index == 0 {
                                            Text("TOP HIT")
                                                .font(.system(size: 7.5, weight: .heavy, design: .rounded))
                                                .foregroundColor(.black)
                                                .padding(.horizontal, 4)
                                                .padding(.vertical, 1.5)
                                                .background(Capsule().fill(Color.orange.opacity(0.85)))
                                        }
                                    }
                                    Text(abbreviatedPath(app.url))
                                        .font(.system(size: 9.5, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.55))
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                }

                                Spacer()

                                if isSelected {
                                    Text("↵")
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.cyan)
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(isSelected ? Color.cyan.opacity(0.18) : Color.clear)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .onHover { hovering in
                            if hovering { selectedAppSuggestionIndex = index }
                        }
                        .contextMenu {
                            Button("Launch \(app.name)") {
                                selectedAppSuggestionIndex = index
                                handleChatPromptSubmit()
                            }
                            Button("Reveal in Finder") {
                                NSWorkspace.shared.activateFileViewerSelecting([app.url])
                            }
                            Button("Copy Path") {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(app.url.path, forType: .string)
                            }
                        }
                    }

                    Divider().opacity(0.15)

                    HStack(spacing: 10) {
                        Text("↑↓ select")
                        Text("↵ launch")
                        Text("⇥ reveal in Finder")
                    }
                    .font(.system(size: 8.5, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.40))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                }
                .padding(.vertical, 4)
                .background(
                    ZStack {
                        VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow, state: .active)
                        Color.black.opacity(0.55)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.14), lineWidth: 0.75)
                )
                .shadow(color: Color.black.opacity(0.35), radius: 12, y: 4)
                .padding(.horizontal, 14)
                .padding(.bottom, 4)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
    }

    private func moveAppSuggestionSelection(by delta: Int) {
        let count = appPromptSuggestions.count
        guard count > 0 else { return }
        selectedAppSuggestionIndex = (selectedAppSuggestionIndex + delta + count) % count
        HapticFeedback.selection()
    }

    private func revealSelectedAppSuggestion() {
        let suggestions = appPromptSuggestions
        guard !suggestions.isEmpty else { return }
        let idx = min(selectedAppSuggestionIndex, suggestions.count - 1)
        NSWorkspace.shared.activateFileViewerSelecting([suggestions[idx].url])
        HapticFeedback.selection()
    }

    private var chatBottomPromptBar: some View {
        VStack(spacing: 0) {
            appPredictionOverlay
            chatBottomPromptBarField
        }
        .animation(.spring(response: 0.24, dampingFraction: 0.85), value: appPromptSuggestions.map(\.id))
    }

    private var chatBottomPromptBarField: some View {
        HStack(spacing: 8) {
            // Mode Switcher Pill
            Button(action: {
                chatPromptMode = chatPromptMode.next()
                HapticFeedback.selection()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: chatPromptMode.icon)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(chatPromptMode.iconColor)
                    Text(chatPromptMode.title)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(Capsule().fill(chatPromptMode.iconColor.opacity(0.20)))
                .overlay(Capsule().stroke(chatPromptMode.iconColor.opacity(0.40), lineWidth: 0.6))
            }
            .buttonStyle(.plain)
            .help("Switch mode: Chat 💬 / Search 🌐 / Note 📄 / Terminal 💻 / Vision 👁️")

            // Layout Mode Switcher Menu
            Menu {
                Button(action: { chatLayoutMode = .chatOnly }) {
                    Label("Chat Stream Only", systemImage: "bubble.left.and.bubble.right.fill")
                }
                Button(action: { chatLayoutMode = .split }) {
                    Label("Split View (Visualizer & Chat)", systemImage: "rectangle.split.2x1.fill")
                }
                Button(action: { chatLayoutMode = .mediaOnly }) {
                    Label("Visualizer / Creations Only", systemImage: "paintpalette.fill")
                }
            } label: {
                Image(systemName: chatLayoutMode == .split ? "rectangle.split.2x1" : (chatLayoutMode == .mediaOnly ? "paintpalette" : "bubble.left"))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(Color.primary.opacity(0.06)))
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .help("Toggle Chat & Visualizer Layout")

            // Prompt Text Field
            TextField(
                chatPromptMode == .chat ? "Ask \(localModels.selectedModelDisplayName)..." : chatPromptMode.placeholder,
                text: $chatPromptText
            )
            .textFieldStyle(.plain)
            .font(.system(size: 12.5))
            .foregroundColor(.primary)
            .onSubmit {
                handleChatPromptSubmit()
            }
            .onChange(of: chatPromptText) { _, _ in
                selectedAppSuggestionIndex = 0
            }
            .onKeyPress(.upArrow) {
                guard chatPromptMode == .apps, !appPromptSuggestions.isEmpty else { return .ignored }
                moveAppSuggestionSelection(by: -1)
                return .handled
            }
            .onKeyPress(.downArrow) {
                guard chatPromptMode == .apps, !appPromptSuggestions.isEmpty else { return .ignored }
                moveAppSuggestionSelection(by: 1)
                return .handled
            }
            .onKeyPress(.tab) {
                guard chatPromptMode == .apps, !appPromptSuggestions.isEmpty else { return .ignored }
                revealSelectedAppSuggestion()
                return .handled
            }

            // Clear Prompt Button
            if !chatPromptText.isEmpty {
                Button(action: { chatPromptText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary.opacity(0.7))
                }
                .buttonStyle(.plain)
            }

            // Submit Button
            Button(action: {
                handleChatPromptSubmit()
            }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(chatPromptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.secondary.opacity(0.35) : .cyan)
            }
            .buttonStyle(.plain)
            .disabled(chatPromptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.40))
                .overlay(VisualEffectBlur(material: .popover, blendingMode: .withinWindow).clipShape(Capsule()).opacity(0.5))
        )
        .overlay(Capsule().strokeBorder(Color.white.opacity(0.18), lineWidth: 0.7))
        .shadow(color: Color.black.opacity(0.30), radius: 10, y: 4)
        .padding(.horizontal, 14)
        .padding(.bottom, 10)
    }

    private func handleChatPromptSubmit() {
        let clean = chatPromptText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        chatPromptText = ""

        switch chatPromptMode {
        case .chat, .file, .polaroid, .screenMirror, .settings:
            localModels.generate(prompt: clean)
        case .apps:
            let matches = appModel.filteredApps(search: clean, category: nil)
            let pickIndex = min(selectedAppSuggestionIndex, max(0, matches.count - 1))
            if let app = matches.isEmpty ? nil : matches[pickIndex] {
                appModel.launch(app)
            } else {
                Process.launchedProcess(launchPath: "/usr/bin/open", arguments: ["-a", clean])
            }
            selectedAppSuggestionIndex = 0
        case .vision:
            GenieVisionEngine.shared.askAIWithVision(query: clean)
        case .search:
            localModels.performInternetSearch(query: clean)
        case .terminal:
            NotificationCenter.default.post(name: NSNotification.Name("NexusExecuteTerminalCommand"), object: clean)
        }
        HapticFeedback.selection()
    }

    private var applicationsDetailView: some View {
        VStack(spacing: 0) {
            // Mode Bar: [ 🎛️ Visibility & Toggles ] [ 📱 App Launcher Grid ]
            HStack(spacing: 4) {
                Button(action: {
                    withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
                        appSectionMode = "manager"
                    }
                    HapticFeedback.selection()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "switch.2")
                            .font(.system(size: 10, weight: .semibold))
                        Text(LocalizedStrings.translateText("Visibility & Toggles", lang: appLanguage))
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(appSectionMode == "manager" ? Color.white : Color.secondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4.5)
                    .background(RoundedRectangle(cornerRadius: 6).fill(appSectionMode == "manager" ? Color.accentColor : Color.clear))
                }
                .buttonStyle(.plain)

                Button(action: {
                    withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
                        appSectionMode = "launcher"
                    }
                    HapticFeedback.selection()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "square.grid.2x2.fill")
                            .font(.system(size: 10, weight: .semibold))
                        Text(LocalizedStrings.translateText("Launcher Grid", lang: appLanguage))
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(appSectionMode == "launcher" ? Color.white : Color.secondary)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4.5)
                    .background(RoundedRectangle(cornerRadius: 6).fill(appSectionMode == "launcher" ? Color.accentColor : Color.clear))
                }
                .buttonStyle(.plain)

                Spacer()

                // Unabbreviated Language Selector
                TopLanguageSelectorMenu(appLanguage: $appLanguage)

                // Refresh Applications Button
                Button(action: {
                    HapticFeedback.selection()
                    onRefreshApps?()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 10, weight: .semibold))
                        Text(LocalizedStrings.translateText("Refresh", lang: appLanguage))
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(.primary.opacity(0.85))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4.5)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.primary.opacity(0.06))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .strokeBorder(Color.primary.opacity(0.12), lineWidth: 0.5)
                    )
                }
                .buttonStyle(.plain)
                .help("Refresh Applications List")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(Color.primary.opacity(0.03))

            Divider().opacity(0.2)

            if appSectionMode == "manager" {
                appManagerDetailView
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
            } else {
                MinimalModeDropdownView(
                    appModel: appModel,
                    menuCompactMode: $menuCompactMode,
                    isEmbedded: true,
                    onRefreshApps: { onRefreshApps?() },
                    onQuitApp: { onQuitApp?() },
                    onSwitchToSettings: {
                        withAnimation(.spring(response: 0.20, dampingFraction: 0.78)) {
                            selectedTab = .battery
                        }
                    }
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Tab 1: App Manager Detail View

    private var appManagerDetailView: some View {
        VStack(alignment: .leading, spacing: 8) {

            // ── Search + View Toggle ──────────────────────────────────────
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                TextField(LocalizedStrings.searchPlaceholder(lang: appLanguage), text: $appSearchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11))
                if !appSearchQuery.isEmpty {
                    Button(action: { appSearchQuery = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
                // List / Grid toggle
                HStack(spacing: 2) {
                    Button(action: { appViewMode = "list" }) {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 11, weight: appViewMode == "list" ? .bold : .regular))
                            .foregroundColor(appViewMode == "list" ? Color.accentColor : Color.secondary)
                            .frame(width: 24, height: 22)
                            .background(appViewMode == "list" ? Color.accentColor.opacity(0.12) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                    .buttonStyle(.plain)
                    Button(action: { appViewMode = "grid" }) {
                        Image(systemName: "square.grid.3x3.fill")
                            .font(.system(size: 11, weight: appViewMode == "grid" ? .bold : .regular))
                            .foregroundColor(appViewMode == "grid" ? Color.accentColor : Color.secondary)
                            .frame(width: 24, height: 22)
                            .background(appViewMode == "grid" ? Color.accentColor.opacity(0.12) : Color.clear)
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color(nsColor: .controlColor).opacity(0.5)))

            // ── Visibility Filter Pills ──────────────────────────────────
            HStack(spacing: 4) {
                visibilityFilterButton(title: "All Apps", count: appModel.apps.count, mode: "all")
                visibilityFilterButton(title: "Visible", count: appModel.visibleApps.count, mode: "visible")
                visibilityFilterButton(title: "Hidden", count: hiddenAppIDs.count, mode: "hidden")
                Spacer()
            }
            .padding(.vertical, 2)

            // ── Content ───────────────────────────────────────────────────
            if appViewMode == "list" {
                // LIST VIEW WITH TOGGLE SWITCHES
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVStack(spacing: 4) {
                        ForEach(filteredAllApps) { app in
                            let isHidden = hiddenAppIDs.contains(app.id)
                            HStack(spacing: 8) {
                                Button(action: {
                                    HapticFeedback.heavy()
                                    appModel.launch(app)
                                    NotificationCenter.default.post(name: NSNotification.Name("NexusClose"), object: nil)
                                }) {
                                    HStack(spacing: 8) {
                                        Image(nsImage: app.icon)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 22, height: 22)
                                            .opacity(isHidden ? 0.35 : 1.0)
                                        Text(app.name)
                                            .font(.system(size: 11.5, weight: .medium))
                                            .foregroundColor(isHidden ? Color.secondary : Color.primary)
                                            .lineLimit(1)
                                    }
                                }
                                .buttonStyle(.plain)

                                Spacer()

                                // Native macOS Toggle Switch for Hidden/Unhidden
                                Toggle(isOn: Binding(
                                    get: { !isHidden },
                                    set: { isVisible in
                                        HapticFeedback.selection()
                                        withAnimation(.spring(response: 0.25, dampingFraction: 0.78)) {
                                            if isVisible {
                                                appModel.unhideApp(id: app.id)
                                            } else {
                                                appModel.hideApp(app)
                                            }
                                            hiddenAppsRevision += 1
                                        }
                                    }
                                )) {
                                    HStack(spacing: 4) {
                                        Image(systemName: isHidden ? "eye.slash" : "eye.fill")
                                            .font(.system(size: 9))
                                        Text(isHidden ? "Hidden" : "Visible")
                                            .font(.system(size: 10.5, weight: .medium, design: .rounded))
                                    }
                                    .foregroundColor(isHidden ? Color.secondary : Color.primary)
                                }
                                .toggleStyle(.switch)
                                .controlSize(.small)
                                .help(isHidden ? "Switch on to show in Genie" : "Switch off to hide from Genie")
                            }
                            .padding(.vertical, 3)
                            .padding(.horizontal, 4)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(hoveredPidApp == app.id ? 0.04 : 0.0)))
                            .onHover { inside in
                                hoveredPidApp = inside ? app.id : nil
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            } else {
                // ICON GRID VIEW WITH TOGGLE SWITCHES
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 80, maximum: 100), spacing: 10)],
                        spacing: 12
                    ) {
                        ForEach(filteredAllApps) { app in
                            let isHidden = hiddenAppIDs.contains(app.id)
                            ZStack(alignment: .topTrailing) {
                                // App tile
                                VStack(spacing: 4) {
                                    ZStack {
                                        Image(nsImage: app.icon)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 44, height: 44)
                                            .opacity(isHidden ? 0.35 : 1.0)
                                        if isHidden {
                                            Image(systemName: "eye.slash.fill")
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundColor(.white)
                                                .shadow(radius: 2)
                                        }
                                    }
                                    Text(app.name)
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundColor(isHidden ? Color.secondary : Color.primary)
                                        .lineLimit(1)
                                        .multilineTextAlignment(.center)

                                    // Toggle Switch on Card
                                    Toggle("", isOn: Binding(
                                        get: { !isHidden },
                                        set: { isVisible in
                                            HapticFeedback.selection()
                                            withAnimation(.spring(response: 0.25, dampingFraction: 0.78)) {
                                                if isVisible {
                                                    appModel.unhideApp(id: app.id)
                                                } else {
                                                    appModel.hideApp(app)
                                                }
                                                hiddenAppsRevision += 1
                                            }
                                        }
                                    ))
                                    .labelsHidden()
                                    .toggleStyle(.switch)
                                    .controlSize(.mini)
                                    .help(isHidden ? "Switch on to make Visible" : "Switch off to Hide")
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 7)
                                .padding(.horizontal, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(isHidden
                                              ? Color.secondary.opacity(0.08)
                                              : Color(nsColor: .controlColor).opacity(0.45))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(isHidden ? Color.secondary.opacity(0.2) : Color.clear, lineWidth: 1)
                                )
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    HapticFeedback.heavy()
                                    appModel.launch(app)
                                    NotificationCenter.default.post(name: NSNotification.Name("NexusClose"), object: nil)
                                }

                                // Eye badge
                                Image(systemName: isHidden ? "eye.slash.fill" : "eye.fill")
                                    .font(.system(size: 7.5, weight: .bold))
                                    .foregroundColor(isHidden ? Color.secondary : Color.accentColor)
                                    .frame(width: 16, height: 16)
                                    .background(Circle().fill(Color(nsColor: .windowBackgroundColor)))
                                    .overlay(Circle().strokeBorder(Color.secondary.opacity(0.2), lineWidth: 0.5))
                                    .offset(x: 2, y: -2)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // ── Footer ────────────────────────────────────────────────────
            Divider().opacity(0.4)
            HStack {
                Text("\(appModel.visibleApps.count) visible · \(hiddenAppIDs.count) hidden")
                    .font(.system(size: 10.5))
                    .foregroundColor(.secondary)
                Spacer()
                if !hiddenAppIDs.isEmpty {
                    Button(action: { clearHiddenApps() }) {
                        Text(LocalizedStrings.translateText("Unhide All", lang: appLanguage))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func visibilityFilterButton(title: String, count: Int, mode: String) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
                appVisibilityFilter = mode
            }
            HapticFeedback.selection()
        }) {
            HStack(spacing: 3) {
                Text(title)
                    .font(.system(size: 10, weight: appVisibilityFilter == mode ? .bold : .medium, design: .rounded))
                Text("(\(count))")
                    .font(.system(size: 9, weight: .regular))
                    .opacity(0.75)
            }
            .foregroundColor(appVisibilityFilter == mode ? Color.white : Color.secondary)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Capsule().fill(appVisibilityFilter == mode ? Color.accentColor : Color.primary.opacity(0.06)))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Tab 2: Desktop Grid Detail View

    private var desktopGridDetailView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(LocalizedStrings.translateText("Desktop Grid", lang: appLanguage))
                    .font(.system(size: 12))
                Spacer()
                Toggle("", isOn: $desktopPlaneEnabled)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.small)
            }

            if desktopPlaneEnabled {
                Divider().opacity(0.4)

                // 0. Stacked Desktop Workspaces Deck
                StackedDesktopLayersDeckView()

                Divider().opacity(0.4)

                // 1. Keep Files on Desktop Toggle
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 5) {
                            Image(systemName: desktopFilesManager.areDesktopFilesVisible ? "folder.fill" : "folder.badge.minus")
                                .foregroundColor(desktopFilesManager.areDesktopFilesVisible ? .blue : .secondary)
                            Text(LocalizedStrings.translateText("Keep Files on Desktop", lang: appLanguage))
                                .font(.system(size: 11.5, weight: .semibold))
                        }
                        Text(desktopFilesManager.areDesktopFilesVisible
                            ? "Files and folders stay visible on your desktop wallpaper."
                            : "Files and folders are hidden for an ultra-clean desktop.")
                            .font(.system(size: 9.5))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { desktopFilesManager.areDesktopFilesVisible },
                        set: { visible in
                            HapticFeedback.selection()
                            desktopFilesManager.setDesktopFilesVisible(visible)
                        }
                    ))
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.small)
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.blue.opacity(0.08)))

                Divider().opacity(0.4)

                // 2. Always-On Desktop Matrix (Desktop Replacement Mode)
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 5) {
                            Image(systemName: "sparkles.tv")
                                .foregroundColor(.indigo)
                            Text(LocalizedStrings.translateText("Always-On Desktop Matrix", lang: appLanguage))
                                .font(.system(size: 11.5, weight: .semibold))
                        }
                        Text(LocalizedStrings.translateText("Applications live permanently on your desktop wallpaper behind other windows. Swipe down reveals the classic desktop.", lang: appLanguage))
                            .font(.system(size: 9.5))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: $alwaysOnDesktop)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .controlSize(.small)
                        .onChange(of: alwaysOnDesktop) { _, isEnabled in
                            HapticFeedback.selection()
                            NotificationCenter.default.post(name: NSNotification.Name("NexusAlwaysOnDesktopToggled"), object: isEnabled)
                        }
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.indigo.opacity(0.10)))

                Divider().opacity(0.4)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(LocalizedStrings.translateText("Icon Size", lang: appLanguage))
                            .font(.system(size: 12, weight: .medium))
                        Spacer()
                        Text("\(Int(iconSize)) pt")
                            .font(.system(size: 11, weight: .semibold).monospacedDigit())
                            .foregroundColor(.accentColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(RoundedRectangle(cornerRadius: 4).fill(Color.accentColor.opacity(0.12)))
                    }

                    // Matching 4-Column Icon Size Preset Chips
                    HStack(spacing: 4) {
                        ForEach([
                            (label: "Compact", size: 44.0, ptText: "44 pt"),
                            (label: "Standard", size: 60.0, ptText: "60 pt"),
                            (label: "Large", size: 76.0, ptText: "76 pt"),
                            (label: "Jumbo", size: 96.0, ptText: "96 pt")
                        ], id: \.label) { preset in
                            Button(action: {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                    iconSize = preset.size
                                }
                                HapticFeedback.selection()
                            }) {
                                let isSelected = abs(iconSize - preset.size) < 5
                                VStack(spacing: 1.5) {
                                    Text(preset.label)
                                        .font(.system(size: 9.5, weight: isSelected ? .bold : .medium))
                                        .foregroundColor(isSelected ? .accentColor : .primary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.85)
                                    Text(preset.ptText)
                                        .font(.system(size: 8, weight: .regular).monospacedDigit())
                                        .foregroundColor(isSelected ? .accentColor : .secondary)
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 30)
                                .background(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.primary.opacity(0.04))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .strokeBorder(isSelected ? Color.accentColor.opacity(0.5) : Color.primary.opacity(0.08), lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    HStack(spacing: 8) {
                        Text(LocalizedStrings.translateText("36 pt", lang: appLanguage))
                            .font(.system(size: 9.5).monospacedDigit())
                            .foregroundColor(.secondary)
                        Slider(value: $iconSize, in: 36...96, step: 2)
                            .controlSize(.small)
                        Text(LocalizedStrings.translateText("96 pt", lang: appLanguage))
                            .font(.system(size: 9.5).monospacedDigit())
                            .foregroundColor(.secondary)
                    }
                }

                HStack {
                    Text(LocalizedStrings.translateText("Show App Names", lang: appLanguage))
                        .font(.system(size: 12))
                    Spacer()
                    Toggle("", isOn: $showAppNames)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .controlSize(.small)
                }

                if showAppNames {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(LocalizedStrings.translateText("App Name Text Size", lang: appLanguage))
                                .font(.system(size: 12, weight: .medium))
                            Spacer()
                            Text("\(String(format: "%.1f", textSize)) pt")
                                .font(.system(size: 11, weight: .semibold).monospacedDigit())
                                .foregroundColor(.accentColor)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(RoundedRectangle(cornerRadius: 4).fill(Color.accentColor.opacity(0.12)))
                        }

                        // Matching 4-Column Text Size Preset Chips (Exactly matching Icon Size width & style)
                        HStack(spacing: 4) {
                            ForEach([
                                (label: "Compact", pt: 9.5, ptText: "9.5 pt"),
                                (label: "Standard", pt: 11.0, ptText: "11 pt"),
                                (label: "Large", pt: 13.5, ptText: "13.5 pt"),
                                (label: "Jumbo", pt: 16.0, ptText: "16 pt")
                            ], id: \.label) { preset in
                                Button(action: {
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                        textSize = preset.pt
                                    }
                                    HapticFeedback.selection()
                                }) {
                                    let isSelected = abs(textSize - preset.pt) < 0.6
                                    VStack(spacing: 1.5) {
                                        Text(preset.label)
                                            .font(.system(size: 9.5, weight: isSelected ? .bold : .medium))
                                            .foregroundColor(isSelected ? .accentColor : .primary)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.85)
                                        Text(preset.ptText)
                                            .font(.system(size: 8, weight: .regular).monospacedDigit())
                                            .foregroundColor(isSelected ? .accentColor : .secondary)
                                            .lineLimit(1)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 30)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.primary.opacity(0.04))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .strokeBorder(isSelected ? Color.accentColor.opacity(0.5) : Color.primary.opacity(0.08), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        // Slider with min/max scale
                        HStack(spacing: 8) {
                            Text(LocalizedStrings.translateText("9 pt", lang: appLanguage))
                                .font(.system(size: 9.5).monospacedDigit())
                                .foregroundColor(.secondary)
                            Slider(value: $textSize, in: 9...16, step: 0.5)
                                .controlSize(.small)
                            Text(LocalizedStrings.translateText("16 pt", lang: appLanguage))
                                .font(.system(size: 9.5).monospacedDigit())
                                .foregroundColor(.secondary)
                        }

                        // Live Typography & Icon Scale Reference Card
                        HStack(spacing: 12) {
                            VStack(spacing: 4) {
                                let previewIconDim = max(26.0, min(48.0, CGFloat(iconSize) * 0.55))
                                ZStack {
                                    RoundedRectangle(cornerRadius: previewIconDim * 0.22, style: .continuous)
                                        .fill(LinearGradient(colors: [Color.blue, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                                        .frame(width: previewIconDim, height: previewIconDim)
                                        .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                                    Image(systemName: "app.fill")
                                        .font(.system(size: previewIconDim * 0.46))
                                        .foregroundColor(.white)
                                }
                                .frame(width: 52, height: 48)

                                Text(LocalizedStrings.translateText("Genie", lang: appLanguage))
                                    .font(.system(size: CGFloat(textSize), weight: .medium))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                            }
                            .frame(width: 58)

                            Divider().frame(height: 44).opacity(0.3)

                            VStack(alignment: .leading, spacing: 3) {
                                HStack(spacing: 5) {
                                    Text(LocalizedStrings.translateText("Reference Scale:", lang: appLanguage))
                                        .font(.system(size: 9.5, weight: .semibold))
                                        .foregroundColor(.secondary)
                                    Text(
                                        textSize <= 9.5 ? "Compact (Dense Grid)" :
                                        textSize <= 11.5 ? "macOS Standard" :
                                        textSize <= 14.0 ? "Large (Readability)" : "Jumbo (High Visibility)"
                                    )
                                    .font(.system(size: 9.5, weight: .semibold))
                                    .foregroundColor(.accentColor)
                                }

                                Text(LocalizedStrings.translateText("The quick brown fox jumps over the lazy dog", lang: appLanguage))
                                    .font(.system(size: CGFloat(textSize), weight: .regular))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                            }
                            Spacer()
                        }
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.primary.opacity(0.03)))
                        .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).strokeBorder(Color.primary.opacity(0.08), lineWidth: 1))
                    }
                    .padding(.vertical, 4)
                }

                Divider().opacity(0.4)

                HStack {
                    Text(LocalizedStrings.translateText("Show Page Indicator Dots", lang: appLanguage))
                        .font(.system(size: 12))
                    Spacer()
                    Toggle("", isOn: $showPageIndicator)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .controlSize(.small)
                }

                Divider().opacity(0.4)

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(LocalizedStrings.translateText("Grid Spacing", lang: appLanguage))
                            .font(.system(size: 12))
                        Spacer()
                        Text("\(Int(itemSpacing)) pt")
                            .font(.system(size: 11).monospacedDigit())
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $itemSpacing, in: 8...64, step: 2)
                        .controlSize(.small)
                }



                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "iphone.gen3")
                            .font(.system(size: 11))
                            .foregroundColor(.pink)
                        Text(LocalizedStrings.translateText("Genie Entrance & Direction", lang: appLanguage))
                            .font(.system(size: 12, weight: .semibold))
                        Spacer()
                    }

                    Picker("", selection: $gridTransitionDirection) {
                        Text(LocalizedStrings.translateText("📱 iPhone Mode (Right to Left)", lang: appLanguage)).tag("Slide from Right (iPhone Mode 📱)")
                        Text(LocalizedStrings.translateText("⬆️ Classic Dock (Bottom Up)", lang: appLanguage)).tag("Pull Up from Bottom")
                        Text(LocalizedStrings.translateText("⬅️ Left Sidebar", lang: appLanguage)).tag("Slide from Left (Sidebar ⬅️)")
                        Text(LocalizedStrings.translateText("⬇️ Top Drop-Down", lang: appLanguage)).tag("Drop Down from Top (Menu Bar ⬇️)")
                        Text(LocalizedStrings.translateText("✨ Spatial Zoom (Center)", lang: appLanguage)).tag("Spatial Zoom from Center (Holographic ✨)")
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()

                    Text(gridTransitionDirection == "Slide from Right (iPhone Mode 📱)"
                        ? "Glides in from the right edge like an iPhone slide-over. Swipe right-to-left or push the right screen edge."
                        : "Controls the spatial entrance trajectory when summoning Genie.")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)

                    if gridTransitionDirection == "Slide from Right (iPhone Mode 📱)" {
                        HStack {
                            Image(systemName: "arrow.left.to.line.compact")
                                .font(.system(size: 10))
                                .foregroundColor(.pink)
                            Text(LocalizedStrings.translateText("Right Edge Cursor Summon", lang: appLanguage))
                                .font(.system(size: 11))
                            Spacer()
                            Toggle("", isOn: $rightEdgeCursorTrigger)
                                .labelsHidden()
                                .toggleStyle(.switch)
                                .controlSize(.small)
                        }
                    }
                }

                Divider().opacity(0.4)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "dock.rectangle")
                            .font(.system(size: 11))
                            .foregroundColor(.cyan)
                        Text(LocalizedStrings.translateText("Intelligent Dock Inset & Avoidance", lang: appLanguage))
                            .font(.system(size: 12, weight: .medium))
                        Spacer()
                        Toggle("", isOn: $dockAvoidanceEnabled)
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .controlSize(.small)
                    }

                    if dockAvoidanceEnabled {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(LocalizedStrings.translateText("Dock Rest Period (Anti-Accidental Hover)", lang: appLanguage))
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(String(format: "%.2fs", dockRestPeriod))
                                    .font(.system(size: 10.5).monospacedDigit())
                                    .foregroundColor(.secondary)
                            }
                            Slider(value: $dockRestPeriod, in: 0.30...1.20, step: 0.05)
                                .controlSize(.small)
                            Text(LocalizedStrings.translateText("Requires an intentional rest period before summoning from the bottom edge (0.65s recommended).", lang: appLanguage))
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                    }
                }

                Divider().opacity(0.4)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "arrow.down.to.line.compact")
                            .font(.system(size: 11))
                            .foregroundColor(.teal)
                        Text(LocalizedStrings.translateText("Bottom Edge Cursor Summon", lang: appLanguage))
                            .font(.system(size: 12, weight: .medium))
                        Spacer()
                        Toggle("", isOn: $bottomEdgeCursorTrigger)
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .controlSize(.small)
                    }
                    Text(LocalizedStrings.translateText("Push cursor to the bottom center edge to summon Genie (automatically shields third-party apps).", lang: appLanguage))
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }

                Divider().opacity(0.4)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "rectangle.inset.bottomtrailing.filled")
                            .font(.system(size: 11))
                            .foregroundColor(.purple)
                        Text(LocalizedStrings.translateText("Bottom-Right Hot Corner", lang: appLanguage))
                            .font(.system(size: 12, weight: .medium))
                        Spacer()
                        Toggle("", isOn: $bottomRightHotCorner)
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .controlSize(.small)
                    }
                    Text(LocalizedStrings.translateText("Quick Note style: move cursor to the bottom-right corner to toggle Genie on and off.", lang: appLanguage))
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }

                Divider().opacity(0.4)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "rectangle.inset.toptrailing.filled")
                            .font(.system(size: 11))
                            .foregroundColor(.indigo)
                        Text(LocalizedStrings.translateText("Top-Right Hot Corner", lang: appLanguage))
                            .font(.system(size: 12, weight: .medium))
                        Spacer()
                        Toggle("", isOn: $topRightHotCorner)
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .controlSize(.small)
                    }
                    Text(LocalizedStrings.translateText("Move cursor to the top-right corner to toggle Genie on and off.", lang: appLanguage))
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }

                Divider().opacity(0.4)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "keyboard")
                            .font(.system(size: 11))
                            .foregroundColor(.orange)
                        Text(LocalizedStrings.translateText("Double-Tap Shortcuts", lang: appLanguage))
                            .font(.system(size: 12, weight: .medium))
                    }
                    HStack {
                        Text(LocalizedStrings.translateText("Double-Tap ⌃ Control", lang: appLanguage))
                            .font(.system(size: 11))
                        Spacer()
                        Toggle("", isOn: $doubleControlTrigger)
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .controlSize(.small)
                    }
                    HStack {
                        Text(LocalizedStrings.translateText("Double-Tap ⌥ Option", lang: appLanguage))
                            .font(.system(size: 11))
                        Spacer()
                        Toggle("", isOn: $doubleOptionTrigger)
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .controlSize(.small)
                    }
                }

                Divider().opacity(0.4)

                // Quick Link to Formations
                HStack(spacing: 8) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.pink.opacity(0.16))
                            .frame(width: 28, height: 28)
                        Image(systemName: "circle.grid.cross.fill")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.pink)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(LocalizedStrings.translateText("Geometric Formations", lang: appLanguage))
                            .font(.system(size: 12, weight: .semibold))
                        Text(LocalizedStrings.translateText(appFormation, lang: appLanguage))
                            .font(.system(size: 10))
                            .foregroundColor(.pink)
                    }

                    Spacer()

                    Button(action: {
                        HapticFeedback.selection()
                        withAnimation(.spring(response: 0.20, dampingFraction: 0.78)) {
                            selectedTab = .formations
                        }
                    }) {
                        HStack(spacing: 3) {
                            Text(LocalizedStrings.translateText("Choose Formation", lang: appLanguage))
                                .font(.system(size: 11, weight: .semibold))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(Color.pink.opacity(0.14)))
                        .foregroundColor(.pink)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.primary.opacity(0.03)))
                .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Color.pink.opacity(0.20), lineWidth: 0.8))
            }
        }
    }

    // MARK: - Tab 3: Theme Library Detail View

    // MARK: - Tab: Themes Library Detail View

    private var themesSubSectionView: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Active Theme Spotlight & Quick Tint Bar
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(LocalizedStrings.translateText("Active Theme", lang: appLanguage).uppercased())
                        .font(.system(size: 8.5, weight: .bold))
                        .foregroundColor(.purple)
                    Text(LocalizedStrings.translateText(appIconTheme, lang: appLanguage))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.primary)
                }

                Spacer()

                if appIconTheme == "Tinted" {
                    HStack(spacing: 5) {
                        ForEach(tintColors, id: \.self) { color in
                            Circle()
                                .fill(tintColorDisplay(color))
                                .frame(width: 13, height: 13)
                                .overlay(Circle().stroke(appIconTintColor == color ? Color.white : Color.clear, lineWidth: 2))
                                .onTapGesture {
                                    HapticFeedback.selection()
                                    appIconTintColor = color
                                }
                        }
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.primary.opacity(0.06)))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.55))
            )

            // Search Field
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                TextField(LocalizedStrings.translateText("Search themes...", lang: appLanguage), text: $themeSearchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11))
                if !themeSearchQuery.isEmpty {
                    Button(action: { themeSearchQuery = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.primary.opacity(0.04))
            )

            // Category Pills
            FilterPillBar(
                categories: ["All", "macOS Sequoia", "Pop Punk & Indie 🎸", "3D Spatial", "Futuristic FX", "Nature & Organic", "Retro & Synth"],
                selectedCategory: $themeCategoryFilter,
                tintColor: .purple
            )

            // Compact Themes Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                ForEach(filteredThemes, id: \.name) { themeItem in
                    let isSel = appIconTheme == themeItem.name
                    Button(action: {
                        HapticFeedback.selection()
                        withAnimation(.spring(response: 0.22, dampingFraction: 0.70)) {
                            appIconTheme = themeItem.name
                        }
                    }) {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(LocalizedStrings.translateText(themeItem.name, lang: appLanguage))
                                    .font(.system(size: 10.5, weight: isSel ? .bold : .medium))
                                    .foregroundColor(isSel ? .purple : .primary)
                                    .lineLimit(1)
                                Spacer(minLength: 0)
                                if isSel {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 9.5))
                                        .foregroundColor(.purple)
                                }
                            }

                            Text(LocalizedStrings.translateText(themeItem.desc, lang: appLanguage))
                                .font(.system(size: 8.5))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(isSel ? Color.purple.opacity(0.12) : Color(nsColor: .controlBackgroundColor).opacity(0.50))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(isSel ? Color.purple : Color.primary.opacity(0.06), lineWidth: isSel ? 1.2 : 0.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Tab: Icon Snuggies Detail View

    private var snuggiesSubSectionView: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Snuggies Header View
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(LocalizedStrings.translateText("Active Snuggie", lang: appLanguage).uppercased())
                        .font(.system(size: 8.5, weight: .bold))
                        .foregroundColor(.yellow)
                    Text(iconSnuggie)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.primary)
                }
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.55))
            )

            FilterPillBar(
                categories: snuggieCategories,
                selectedCategory: $snuggieCategoryFilter,
                tintColor: .yellow
            )

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                ForEach(filteredSnuggies, id: \.name) { snuggie in
                    let isSel = iconSnuggie == snuggie.name
                    Button(action: {
                        HapticFeedback.selection()
                        withAnimation(.spring(response: 0.22, dampingFraction: 0.70)) {
                            iconSnuggie = snuggie.name
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: snuggie.icon)
                                .font(.system(size: 11))
                                .foregroundColor(isSel ? snuggie.tint : .secondary)
                                .frame(width: 14)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(snuggie.name)
                                    .font(.system(size: 10.5, weight: isSel ? .bold : .medium))
                                    .foregroundColor(isSel ? snuggie.tint : .primary)
                                    .lineLimit(1)
                                Text(snuggie.desc)
                                    .font(.system(size: 8))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer(minLength: 0)
                            if isSel {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(snuggie.tint)
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(isSel ? snuggie.tint.opacity(0.12) : Color(nsColor: .controlBackgroundColor).opacity(0.50))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(isSel ? snuggie.tint : Color.primary.opacity(0.06), lineWidth: isSel ? 1.2 : 0.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Tab 4: Shapes & Formations Detail View

    private var formationsDetailView: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Consolidated Formation Control Header
            VStack(spacing: 8) {
                // Active Formation Badge & App Count Control
                HStack(alignment: .center, spacing: 8) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(LocalizedStrings.translateText("Active Formation", lang: appLanguage).uppercased())
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundColor(.pink)
                        Text(LocalizedStrings.translateText(appFormation, lang: appLanguage))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                    }

                    Spacer()

                    // Quick Launch / Toggle on Desktop
                    Button(action: {
                        HapticFeedback.selection()
                        NotificationCenter.default.post(name: NSNotification.Name("NexusToggleDesktopGrid"), object: nil)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles.tv")
                                .font(.system(size: 9.5, weight: .bold))
                            Text(LocalizedStrings.translateText("Desktop", lang: appLanguage))
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .padding(.horizontal, 7)
                        .padding(.vertical, 4.5)
                        .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(Color.pink.opacity(0.14)))
                        .foregroundColor(.pink)
                    }
                    .buttonStyle(.plain)
                    .help("Show/Hide Desktop Grid with Active Formation")

                    // Apps in Formation Limit (custom formation would be like how many apps)
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(LocalizedStrings.translateText("Apps in Formation", lang: appLanguage).uppercased())
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundColor(.secondary)

                        HStack(spacing: 4) {
                            Button(action: {
                                HapticFeedback.selection()
                                if formationAppLimit == 0 {
                                    formationAppLimit = min(12, appModel.visibleApps.count)
                                } else if formationAppLimit > 1 {
                                    formationAppLimit -= 1
                                }
                                NotificationCenter.default.post(name: NSNotification.Name("NexusFormationLimitChanged"), object: formationAppLimit)
                            }) {
                                Image(systemName: "minus")
                                    .font(.system(size: 8.5, weight: .bold))
                                    .frame(width: 18, height: 18)
                                    .background(RoundedRectangle(cornerRadius: 4).fill(Color.primary.opacity(0.08)))
                            }
                            .buttonStyle(.plain)

                            Text(formationAppLimit == 0 ? "All (\(appModel.visibleApps.count))" : "\(formationAppLimit)")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .frame(minWidth: 46)

                            Button(action: {
                                HapticFeedback.selection()
                                if formationAppLimit == 0 {
                                    // already all
                                } else if formationAppLimit < appModel.visibleApps.count {
                                    formationAppLimit += 1
                                } else {
                                    formationAppLimit = 0
                                }
                                NotificationCenter.default.post(name: NSNotification.Name("NexusFormationLimitChanged"), object: formationAppLimit)
                            }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 8.5, weight: .bold))
                                    .frame(width: 18, height: 18)
                                    .background(RoundedRectangle(cornerRadius: 4).fill(Color.primary.opacity(0.08)))
                            }
                            .buttonStyle(.plain)

                            if formationAppLimit != 0 {
                                Button(action: {
                                    HapticFeedback.selection()
                                    formationAppLimit = 0
                                    NotificationCenter.default.post(name: NSNotification.Name("NexusFormationLimitChanged"), object: formationAppLimit)
                                }) {
                                    Text(LocalizedStrings.translateText("All", lang: appLanguage))
                                        .font(.system(size: 8.5, weight: .bold))
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 2)
                                        .background(Capsule().fill(Color.pink.opacity(0.15)))
                                        .foregroundColor(.pink)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(nsColor: .controlBackgroundColor).opacity(0.55))
                )

                // ── Chat & Icons Layout & Padding Section ──
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "bubble.left.and.text.bubble.right.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.pink)
                        Text(LocalizedStrings.translateText("Chat & Icons Layout", lang: appLanguage))
                            .font(.system(size: 11, weight: .bold))
                        Spacer()
                    }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                        let quickFormats: [(title: String, formation: String, icon: String)] = [
                            ("Line Up Above Chat", "Lined Up Above Chat ⬆️", "arrow.up.and.line.horizontal.and.arrow.down"),
                            ("Surround Chat", "Surround Search Bar Grid 🪔", "square.grid.3x3.topleft.filled"),
                            ("Dual Flank Wings", "Dual Flank Wings 🪽", "arrow.left.and.right.square"),
                            ("Bottom Shelf Dock", "Bottom Shelf & Active Desktop 🖥️", "menubar.dock.rectangle"),
                            ("Centered Single Dock", "Centered Single Dock ↔️", "menubar.rectangle"),
                            ("Dynamic Orbit Ring", "Orbiting Border Ring 🔄", "arrow.triangle.2.circlepath.circle.fill")
                        ]

                        ForEach(quickFormats, id: \.formation) { item in
                            let isSelected = (appFormation == item.formation) || (item.formation == "Surround Search Bar Grid 🪔" && appFormation == "Responsive Grid")
                            Button(action: {
                                HapticFeedback.selection()
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                                    appFormation = item.formation
                                }
                                NotificationCenter.default.post(name: NSNotification.Name("NexusFormationChanged"), object: appFormation)
                            }) {
                                HStack(spacing: 5) {
                                    Image(systemName: item.icon)
                                        .font(.system(size: 9.5, weight: .bold))
                                    Text(LocalizedStrings.translateText(item.title, lang: appLanguage))
                                        .font(.system(size: 10, weight: .medium))
                                        .lineLimit(1)
                                }
                                .padding(.horizontal, 7)
                                .padding(.vertical, 6)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .fill(isSelected ? Color.pink.opacity(0.22) : Color.primary.opacity(0.06))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .stroke(isSelected ? Color.pink : Color.clear, lineWidth: 1.0)
                                )
                                .foregroundColor(isSelected ? .pink : .primary)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Padding Slider between Chat & Icons
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.up.and.down.and.arrow.left.and.right")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Text(LocalizedStrings.translateText("Chat & Icons Padding", lang: appLanguage))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(chatGridPadding)) pt")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.pink)
                    }

                    HStack(spacing: 8) {
                        Text("20")
                            .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                        Slider(value: $chatGridPadding, in: 20...80, step: 2)
                            .tint(.pink)
                        Text("80")
                            .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color(nsColor: .controlBackgroundColor).opacity(0.55))
                )

                // Slider for Quick App Count Adjustment when custom count is active
                if formationAppLimit > 0 && appModel.visibleApps.count > 1 {
                    HStack(spacing: 8) {
                        Text(LocalizedStrings.translateText("1", lang: appLanguage))
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                        Slider(
                            value: Binding(
                                get: { Double(formationAppLimit) },
                                set: { formationAppLimit = max(1, min(Int($0), appModel.visibleApps.count)) }
                            ),
                            in: 1...Double(max(2, appModel.visibleApps.count)),
                            step: 1
                        )
                        .tint(.pink)
                        Text("\(appModel.visibleApps.count)")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 6)
                }

                // If Custom Formation is chosen, offer column configuration
                if appFormation == "Custom Formation 🛠️" {
                    HStack {
                        Image(systemName: "rectangle.split.3x1")
                            .foregroundColor(.pink)
                            .font(.system(size: 11))
                        Text(LocalizedStrings.translateText("Columns", lang: appLanguage))
                            .font(.system(size: 11, weight: .medium))
                        Spacer()
                        Picker("", selection: $customFormationColumns) {
                            ForEach(2...9, id: \.self) { c in
                                Text("\(c)").tag(c)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 220)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color.pink.opacity(0.08))
                    )
                }

                // Search field for Formations
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    TextField(LocalizedStrings.translateText("Search formations...", lang: appLanguage), text: $formationSearchQuery)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11))
                    if !formationSearchQuery.isEmpty {
                        Button(action: { formationSearchQuery = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.primary.opacity(0.04))
                )
            }

            FilterPillBar(
                categories: formationCategories,
                selectedCategory: $formationCategoryFilter,
                tintColor: .pink
            )

            if appFormation == "Orbiting Border Ring 🔄" || formationCategoryFilter == "Kinetic & Orbiting 🔄" || formationCategoryMap[appFormation] == "Kinetic & Orbiting 🔄" {
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "gauge.with.dots.needle.50percent")
                            .foregroundColor(.pink)
                        Text(LocalizedStrings.translateText("Orbit & Movement Speed", lang: appLanguage))
                            .font(.system(size: 11, weight: .medium))
                        Spacer()
                        Text(String(format: "%.1fx", orbitSpeed))
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.pink)
                    }
                    Slider(value: $orbitSpeed, in: 0.2...3.5, step: 0.1)
                        .tint(.pink)

                    HStack {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .foregroundColor(.pink)
                        Text(LocalizedStrings.translateText("Rotation Direction", lang: appLanguage))
                            .font(.system(size: 11, weight: .medium))
                        Spacer()
                        Picker("", selection: $orbitClockwise) {
                            Text(LocalizedStrings.translateText("Clockwise ↻", lang: appLanguage)).tag(true)
                            Text(LocalizedStrings.translateText("Counter ↺", lang: appLanguage)).tag(false)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 170)
                    }

                    Divider().opacity(0.4)

                    HStack {
                        Image(systemName: "waveform.path.ecg")
                            .foregroundColor(.pink)
                        Text(LocalizedStrings.translateText("Pulse & Elastic Intensity", lang: appLanguage))
                            .font(.system(size: 11, weight: .medium))
                        Spacer()
                        Text("\(Int(pulseIntensity * 100))%")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.pink)
                    }
                    Slider(value: $pulseIntensity, in: 0.0...1.0, step: 0.05)
                        .tint(.pink)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(Color.pink.opacity(0.08))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.pink.opacity(0.25), lineWidth: 1.0)
                )
            }

            // Compact 3-Column Formation Grid
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                ForEach(filteredFormations, id: \.self) { formation in
                    let isSel = appFormation == formation
                    Button(action: {
                        HapticFeedback.selection()
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                            appFormation = formation
                        }
                        UserDefaults.standard.set(formation, forKey: PrefKey.appFormation)
                        NotificationCenter.default.post(name: NSNotification.Name("NexusFormationChanged"), object: formation)
                    }) {
                        HStack(spacing: 4) {
                            Text(LocalizedStrings.translateText(formation, lang: appLanguage))
                                .font(.system(size: 10, weight: isSel ? .bold : .medium))
                                .foregroundColor(isSel ? .pink : .primary)
                                .lineLimit(1)
                            Spacer(minLength: 0)
                            if isSel {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.pink)
                            }
                        }
                        .padding(.horizontal, 7)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(isSel ? Color.pink.opacity(0.14) : Color(nsColor: .controlBackgroundColor).opacity(0.48))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(isSel ? Color.pink.opacity(0.7) : Color.primary.opacity(0.05), lineWidth: isSel ? 1.2 : 0.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Tab: Sounds & Audio Studio Detail View

    private var soundsDetailView: some View {
        VStack(alignment: .leading, spacing: 14) {
            // ── Master Volume Genie & Multi-Speaker Output ──
            Text(LocalizedStrings.translateText("MASTER VOLUME GENIE & MULTI-SPEAKER OUTPUT", lang: appLanguage))
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary)

            VStack(spacing: 8) {
                // Master Volume Slider & Mute
                HStack(spacing: 8) {
                    Button(action: {
                        multiOutputVolume.toggleMasterMute()
                    }) {
                        Image(systemName: multiOutputVolume.isMasterMuted ? "speaker.slash.fill" : "speaker.wave.3.fill")
                            .font(.system(size: 13))
                            .foregroundColor(multiOutputVolume.isMasterMuted ? .red : .yellow)
                            .frame(width: 20)
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text(LocalizedStrings.translateText("Master Output Volume", lang: appLanguage))
                                .font(.system(size: 11.5, weight: .medium))
                            Spacer()
                            Text("\(Int(multiOutputVolume.masterVolume * 100))%")
                                .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                                .foregroundColor(.yellow)
                        }

                        Slider(value: Binding(
                            get: { multiOutputVolume.masterVolume },
                            set: { multiOutputVolume.setMasterVolume($0) }
                        ), in: 0.0...1.0)
                        .accentColor(.yellow)
                    }
                }

                Divider().opacity(0.3)

                // Sync toggle
                HStack {
                    VStack(alignment: .leading, spacing: 1) {
                        Text(LocalizedStrings.translateText("Sync All Speakers with Master Volume", lang: appLanguage))
                            .font(.system(size: 11, weight: .medium))
                        Text(LocalizedStrings.translateText("Broadcast master slider to all output audio devices simultaneously", lang: appLanguage))
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: $multiOutputVolume.syncAllSpeakers)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .controlSize(.small)
                }

                Divider().opacity(0.3)

                // Detected speakers cards
                Text(LocalizedStrings.translateText("CONNECTED OUTPUT SPEAKERS & DEVICES", lang: appLanguage))
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                ForEach(multiOutputVolume.devices) { dev in
                    VStack(spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: dev.iconName)
                                .font(.system(size: 11))
                                .foregroundColor(dev.isDefault ? .yellow : .primary)
                                .frame(width: 16)

                            Text(dev.name)
                                .font(.system(size: 11, weight: dev.isDefault ? .bold : .medium))
                                .lineLimit(1)

                            Spacer()

                            if dev.isDefault {
                                Text(LocalizedStrings.translateText("DEFAULT", lang: appLanguage))
                                    .font(.system(size: 8, weight: .heavy))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1.5)
                                    .background(Color.yellow.opacity(0.20))
                                    .foregroundColor(.yellow)
                                    .cornerRadius(3)
                            } else {
                                Button(LocalizedStrings.translateText("Set Default", lang: appLanguage)) {
                                    multiOutputVolume.setDefaultDevice(id: dev.id)
                                }
                                .font(.system(size: 9))
                                .buttonStyle(.borderless)
                            }

                            if dev.canSetMute {
                                Button(action: {
                                    multiOutputVolume.toggleDeviceMute(id: dev.id)
                                }) {
                                    Image(systemName: dev.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(dev.isMuted ? .red : .secondary)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        if dev.canSetVolume {
                            HStack(spacing: 6) {
                                Slider(value: Binding(
                                    get: { dev.volume },
                                    set: { multiOutputVolume.setDeviceVolume(id: dev.id, volume: $0) }
                                ), in: 0.0...1.0)
                                .accentColor(.yellow)

                                Text("\(Int(dev.volume * 100))%")
                                    .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                                    .foregroundColor(.secondary)
                                    .frame(width: 32, alignment: .trailing)
                            }
                        } else {
                            HStack {
                                Text(LocalizedStrings.translateText(dev.channels > 0 ? "Multi-channel fixed / aggregate" : "Fixed volume", lang: appLanguage))
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                        }
                    }
                    .padding(6)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(0.04)))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.55))
            )

            // Master Controls
            Text(LocalizedStrings.translateText("MASTER AUDIO & HAPTICS ENGINE", lang: appLanguage))
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary)

            VStack(spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(LocalizedStrings.translateText("Sound Effects & Audio Clicks", lang: appLanguage))
                            .font(.system(size: 11.5, weight: .medium))
                        Text(LocalizedStrings.translateText("Tactile audio feedback on hover, clicks, launches & typing", lang: appLanguage))
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: $soundEnabled)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .controlSize(.small)
                }

                Divider().opacity(0.3)

                HStack {
                    Text(LocalizedStrings.translateText("Master Audio Volume", lang: appLanguage))
                        .font(.system(size: 11, weight: .medium))
                    Spacer()
                    Text("\(Int(soundVolume * 100))%")
                        .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                        .foregroundColor(.yellow)
                }

                Slider(value: $soundVolume, in: 0.10...1.0, step: 0.05)
                    .accentColor(.yellow)

                Divider().opacity(0.3)

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(LocalizedStrings.translateText("Trackpad Haptic Pulses", lang: appLanguage))
                            .font(.system(size: 11.5, weight: .medium))
                        Text(LocalizedStrings.translateText("Physical micro-vibrations on Apple Force Touch trackpads", lang: appLanguage))
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: $hapticsEnabled)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .controlSize(.small)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.55))
            )

            // Audio Themes
            Text(LocalizedStrings.translateText("AUDIO THEME PROFILES", lang: appLanguage))
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach([
                    ("Apple Modern", "Crisp Apple HIG pops and tinks", "apple.logo"),
                    ("Mechanical Keyboard", "Tactile clicky blue switches and thocs", "keyboard"),
                    ("Sci-Fi Cyberpunk", "Futuristic warp synth pulses & chirps", "bolt.fill"),
                    ("Ocean & Nature", "Aquatic bubble drops and sonar pings", "water.waves"),
                    ("Arcade 8-Bit", "Retro 80s chiptune coins and lasers", "gamecontroller.fill"),
                ], id: \.0) { title, desc, iconName in
                    Button(action: {
                        HapticFeedback.selection()
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.70)) {
                            soundProfile = title
                        }
                    }) {
                        HStack {
                            Image(systemName: iconName)
                                .font(.system(size: 12))
                                .foregroundColor(soundProfile == title ? .yellow : .secondary)
                                .frame(width: 16)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(title)
                                    .font(.system(size: 11, weight: soundProfile == title ? .bold : .medium))
                                    .foregroundColor(soundProfile == title ? .yellow : .primary)
                                Text(desc)
                                    .font(.system(size: 8.5))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            if soundProfile == title {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.yellow)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(soundProfile == title ? Color.yellow.opacity(0.12) : Color(nsColor: .controlBackgroundColor).opacity(0.55))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(soundProfile == title ? Color.yellow : Color.primary.opacity(0.06), lineWidth: soundProfile == title ? 1.5 : 0.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            // Interactive Soundboard Test Bench
            Text(LocalizedStrings.translateText("INTERACTIVE SOUNDBOARD (TEST BENCH)", lang: appLanguage))
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                Button(action: { HapticFeedback.tick() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "cursorarrow.rays")
                        Text(LocalizedStrings.translateText("Hover Tick", lang: appLanguage))
                    }
                    .font(.system(size: 10, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(Color(nsColor: .controlBackgroundColor).opacity(0.6))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)

                Button(action: { HapticFeedback.selection() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "hand.tap.fill")
                        Text(LocalizedStrings.translateText("Selection Pop", lang: appLanguage))
                    }
                    .font(.system(size: 10, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(Color(nsColor: .controlBackgroundColor).opacity(0.6))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)

                Button(action: { HapticFeedback.heavy() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.horizontal.fill")
                        Text(LocalizedStrings.translateText("Launch Punch", lang: appLanguage))
                    }
                    .font(.system(size: 10, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(Color(nsColor: .controlBackgroundColor).opacity(0.6))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)

                Button(action: { HapticFeedback.playTypingSound() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "keyboard")
                        Text(LocalizedStrings.translateText("Typing Click", lang: appLanguage))
                    }
                    .font(.system(size: 10, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(Color(nsColor: .controlBackgroundColor).opacity(0.6))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)

                Button(action: { HapticFeedback.testWaterDrop() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "drop.fill")
                        Text(LocalizedStrings.translateText("Ocean Drop", lang: appLanguage))
                    }
                    .font(.system(size: 10, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 7)
                    .background(Color(nsColor: .controlBackgroundColor).opacity(0.6))
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)

            }
        }
    }

    // MARK: - Tab 5: Wallpaper & Atmospheric FX Detail View

    private var wallpaperFxDetailView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section 0: Window Graphics & Translucent Vibrancy
            VStack(alignment: .leading, spacing: 9) {
                HStack {
                    Image(systemName: "macwindow.and.cursorarrow")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.teal)
                    Text(LocalizedStrings.translateText("GENIE WINDOW GRAPHICS & VIBRANCY", lang: appLanguage))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                    Spacer()
                    Toggle("", isOn: $windowGraphicsEnabled)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .controlSize(.small)
                }

                if windowGraphicsEnabled {
                    HStack(spacing: 12) {
                        Toggle(isOn: $windowShaderFxEnabled) {
                            Text(LocalizedStrings.translateText("Atmospheric Shaders in Window", lang: appLanguage))
                                .font(.system(size: 11, weight: .medium))
                        }
                        .toggleStyle(.checkbox)
                        .controlSize(.small)
                    }

                    HStack {
                        Text(LocalizedStrings.translateText("Window Glass Vibrancy", lang: appLanguage))
                            .font(.system(size: 11))
                        Spacer()
                        Text("\(Int(windowGlassVibrancy * 100))%")
                            .font(.system(size: 10.5).monospacedDigit())
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $windowGlassVibrancy, in: 0.35...1.0, step: 0.05)
                        .controlSize(.small)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.40))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.primary.opacity(0.06), lineWidth: 1)
            )

            Divider().opacity(0.4)

            // Section 1: Wallpaper Source & Selection
                Text(LocalizedStrings.translateText("POP-UP APPS GRID WALLPAPER DYNAMICS", lang: appLanguage))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    // Option 1: Genie (Pure 1:1 Desktop Pass-Through)
                    Button(action: {
                        HapticFeedback.selection()
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.70)) {
                            wallpaperMode = "Genie"
                            sameWallpaperMode = true
                            wallpaperMatchingStyle = "Exact Mirror (1:1)"
                            wallpaperTreatment = "Exact Mirror (1:1)"
                            UserDefaults.standard.set("Genie", forKey: PrefKey.wallpaperMode)
                            UserDefaults.standard.set(true, forKey: PrefKey.sameWallpaperMode)
                            UserDefaults.standard.set("Exact Mirror (1:1)", forKey: PrefKey.wallpaperMatchingStyle)
                            UserDefaults.standard.set("Exact Mirror (1:1)", forKey: PrefKey.wallpaperTreatment)
                            UserDefaults.standard.set("", forKey: PrefKey.customWallpaperPath)
                            WallpaperManager.shared.refresh()
                        }
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 13))
                                    .foregroundColor(.teal)
                                Text(LocalizedStrings.translateText("Genie Filter", lang: appLanguage))
                                    .font(.system(size: 11, weight: (wallpaperMode == "Genie" || wallpaperMode == "1:1 Camouflage") ? .bold : .medium))
                                    .foregroundColor((wallpaperMode == "Genie" || wallpaperMode == "1:1 Camouflage") ? .teal : .primary)
                                Spacer()
                                if wallpaperMode == "Genie" || wallpaperMode == "1:1 Camouflage" {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 11))
                                        .foregroundColor(.teal)
                                }
                            }
                            Text(LocalizedStrings.translateText("Pure 100% transparent pass-through gliding over your authentic desktop", lang: appLanguage))
                                .font(.system(size: 8.5))
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill((wallpaperMode == "Genie" || wallpaperMode == "1:1 Camouflage") ? Color.teal.opacity(0.12) : Color(nsColor: .controlBackgroundColor).opacity(0.55))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke((wallpaperMode == "Genie" || wallpaperMode == "1:1 Camouflage") ? Color.teal : Color.primary.opacity(0.06), lineWidth: (wallpaperMode == "Genie" || wallpaperMode == "1:1 Camouflage") ? 1.5 : 0.5)
                        )
                    }
                    .buttonStyle(.plain)

                    // Option 2: Translucent (Paired Wallpaper Blur)
                    Button(action: {
                        HapticFeedback.selection()
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.70)) {
                            wallpaperMode = "Translucent"
                            sameWallpaperMode = false
                            wallpaperTreatment = "Golden Gate Sunset"
                            UserDefaults.standard.set("Translucent", forKey: PrefKey.wallpaperMode)
                            UserDefaults.standard.set(false, forKey: PrefKey.sameWallpaperMode)
                            UserDefaults.standard.set("Golden Gate Sunset", forKey: PrefKey.wallpaperTreatment)
                        }
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "sparkles.rectangle.stack")
                                    .font(.system(size: 13))
                                    .foregroundColor(.cyan)
                                Text(LocalizedStrings.translateText("Translucent", lang: appLanguage))
                                    .font(.system(size: 11, weight: wallpaperMode == "Translucent" ? .bold : .medium))
                                    .foregroundColor(wallpaperMode == "Translucent" ? .cyan : .primary)
                                Spacer()
                                if wallpaperMode == "Translucent" {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 11))
                                        .foregroundColor(.cyan)
                                }
                            }
                            Text(LocalizedStrings.translateText("Paired wallpaper blur effect with frosted glass over your open apps", lang: appLanguage))
                                .font(.system(size: 8.5))
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(wallpaperMode == "Translucent" ? Color.cyan.opacity(0.12) : Color(nsColor: .controlBackgroundColor).opacity(0.55))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(wallpaperMode == "Translucent" ? Color.cyan : Color.primary.opacity(0.06), lineWidth: wallpaperMode == "Translucent" ? 1.5 : 0.5)
                        )
                    }
                    .buttonStyle(.plain)

                    // Option 3: Independent Second Wallpaper for Apps Grid
                    Button(action: {
                        HapticFeedback.selection()
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.70)) {
                            wallpaperMode = "Second Wallpaper"
                            sameWallpaperMode = false
                            if wallpaperMatchingStyle == "Exact Mirror (1:1)" {
                                wallpaperMatchingStyle = "Sequoia Dark"
                                WallpaperManager.shared.activeWallpaperImage = WallpaperManager.shared.generateCuratedWallpaper(named: "Sequoia Dark")
                            }
                            UserDefaults.standard.set("Second Wallpaper", forKey: PrefKey.wallpaperMode)
                            UserDefaults.standard.set(false, forKey: PrefKey.sameWallpaperMode)
                        }
                    }) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "photo.stack.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(.purple)
                                Text(LocalizedStrings.translateText("Second Wallpaper", lang: appLanguage))
                                    .font(.system(size: 11, weight: (wallpaperMode == "Second Wallpaper" && !sameWallpaperMode) ? .bold : .medium))
                                    .foregroundColor((wallpaperMode == "Second Wallpaper" && !sameWallpaperMode) ? .purple : .primary)
                                Spacer()
                                if wallpaperMode == "Second Wallpaper" && !sameWallpaperMode {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 11))
                                        .foregroundColor(.purple)
                                }
                            }
                            Text(LocalizedStrings.translateText("Displays a distinct 4K wallpaper specifically when the App Grid pops up", lang: appLanguage))
                                .font(.system(size: 8.5))
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        .padding(.horizontal, 9)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill((wallpaperMode == "Second Wallpaper" && !sameWallpaperMode) ? Color.purple.opacity(0.12) : Color(nsColor: .controlBackgroundColor).opacity(0.55))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke((wallpaperMode == "Second Wallpaper" && !sameWallpaperMode) ? Color.purple : Color.primary.opacity(0.06), lineWidth: (wallpaperMode == "Second Wallpaper" && !sameWallpaperMode) ? 1.5 : 0.5)
                        )
                    }
                    .buttonStyle(.plain)
                }

                // Hide Wallpaper Behind Applications Toggle
                Toggle(isOn: $hideWallpaperBehindApps) {
                    HStack(spacing: 6) {
                        Image(systemName: "eye.slash.fill")
                            .foregroundColor(.teal)
                            .font(.system(size: 11))
                        VStack(alignment: .leading, spacing: 1) {
                            Text(LocalizedStrings.translateText("Hide Wallpaper Behind Applications", lang: appLanguage))
                                .font(.system(size: 11, weight: .medium))
                            Text(LocalizedStrings.translateText("Applications swipe up/down cleanly over your authentic desktop with no wallpaper", lang: appLanguage))
                                .font(.system(size: 8.5))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .toggleStyle(.switch)
                .controlSize(.small)
                .padding(.vertical, 3)

                // Wallpaper Treatment & Glass Style for Genie or Selected Wallpaper
                VStack(alignment: .leading, spacing: 6) {
                    Text(sameWallpaperMode ? "GENIE & DESKTOP TREATMENT / GLASS STYLE" : "WALLPAPER TREATMENT & GLASS STYLE")
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundColor(sameWallpaperMode ? .teal : .purple)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                        ForEach([
                            ("Golden Gate Sunset", "Amber & purple dusk aero glow"),
                            ("Clear Water Caustics", "Crystalline clear water refraction"),
                            ("Cyber Vector Grid", "Cyan holographic grid matrix"),
                            ("Soft Frosted Glass", "Translucent acrylic blur"),
                            ("Obsidian Velvet Tint", "High-contrast dark backdrop"),
                            ("Exact Mirror (1:1)", "Pure 1:1 desktop mirror"),
                            ("Dimmed Focus (15% Darker)", "Subtle dark focus")
                        ], id: \.0) { styleName, styleDesc in
                            Button(action: {
                                HapticFeedback.selection()
                                withAnimation(.spring(response: 0.22, dampingFraction: 0.70)) {
                                    wallpaperTreatment = styleName
                                }
                            }) {
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack {
                                        Text(styleName)
                                            .font(.system(size: 10, weight: wallpaperTreatment == styleName ? .bold : .medium))
                                            .foregroundColor(wallpaperTreatment == styleName ? (sameWallpaperMode ? .teal : .purple) : .primary)
                                        Spacer()
                                        if wallpaperTreatment == styleName {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 9, weight: .bold))
                                                .foregroundColor(sameWallpaperMode ? .teal : .purple)
                                        }
                                    }
                                    Text(styleDesc)
                                        .font(.system(size: 8))
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .fill(wallpaperTreatment == styleName ? (sameWallpaperMode ? Color.teal.opacity(0.14) : Color.purple.opacity(0.14)) : Color(nsColor: .controlBackgroundColor).opacity(0.5))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .stroke(wallpaperTreatment == styleName ? (sameWallpaperMode ? Color.teal : Color.purple) : Color.primary.opacity(0.06), lineWidth: 1.0)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.vertical, 2)

                // Section 2: Curated 4K Dynamic Wallpapers
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(LocalizedStrings.translateText("CURATED 4K DYNAMIC WALLPAPERS", lang: appLanguage))
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                        Spacer()
                        if sameWallpaperMode {
                            Text(LocalizedStrings.translateText("Dimmed in Pass-Through", lang: appLanguage))
                                .font(.system(size: 8.5, weight: .semibold))
                                .foregroundColor(.teal)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.teal.opacity(0.12)))
                        }
                    }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach([
                            ("Genie Cosmic Spirit", "Mystic Sapphire & Stardust Aura", "sparkles"),
                            ("Sequoia Dark", "Sequoia Dark Horizon", "mountain.2"),
                            ("Golden Sunset", "Golden Gate Sunset", "sun.haze"),
                            ("Cosmic Nebula", "Deep Space Nebula", "sparkles"),
                            ("Cyber Grid", "Cyberpunk Neon Grid", "squareshape.split.2x2"),
                            ("Ocean Caustics", "4K Blue Ocean Wave", "water.waves"),
                            ("Tokyo Neon", "Midnight Cyber Tokyo", "building.2.crop.circle"),
                            ("Emerald Forest", "Deep Redwood Canopy", "leaf"),
                            ("Matrix Digital", "Phosphor Digital Stream", "terminal")
                        ], id: \.0) { title, desc, iconName in
                            Button(action: {
                                HapticFeedback.selection()
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.70)) {
                                    wallpaperMode = "Second Wallpaper"
                                    sameWallpaperMode = false
                                    wallpaperMatchingStyle = title
                                    UserDefaults.standard.set("Second Wallpaper", forKey: PrefKey.wallpaperMode)
                                    UserDefaults.standard.set(false, forKey: PrefKey.sameWallpaperMode)
                                    UserDefaults.standard.set(title, forKey: PrefKey.wallpaperMatchingStyle)
                                    WallpaperManager.shared.activeWallpaperImage = WallpaperManager.shared.generateCuratedWallpaper(named: title)
                                }
                            }) {
                                HStack {
                                    Image(systemName: iconName)
                                        .font(.system(size: 12))
                                        .foregroundColor((!sameWallpaperMode && wallpaperMatchingStyle == title) ? .teal : .secondary)
                                        .frame(width: 16)
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(title)
                                            .font(.system(size: 11, weight: (!sameWallpaperMode && wallpaperMatchingStyle == title) ? .bold : .medium))
                                            .foregroundColor((!sameWallpaperMode && wallpaperMatchingStyle == title) ? .teal : .primary)
                                        Text(desc)
                                            .font(.system(size: 8.5))
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }
                                    Spacer()
                                    if !sameWallpaperMode && wallpaperMatchingStyle == title {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.teal)
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill((!sameWallpaperMode && wallpaperMatchingStyle == title) ? Color.teal.opacity(0.12) : Color(nsColor: .controlBackgroundColor).opacity(0.55))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke((!sameWallpaperMode && wallpaperMatchingStyle == title) ? Color.teal : Color.primary.opacity(0.06), lineWidth: (!sameWallpaperMode && wallpaperMatchingStyle == title) ? 1.5 : 0.5)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .opacity(sameWallpaperMode ? 0.55 : 1.0)
                }

                // Section 3: Discovered System Wallpapers & Custom Upload
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(LocalizedStrings.translateText("SYSTEM & 4K MAC WALLPAPERS (ON YOUR MAC)", lang: appLanguage))
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(WallpaperManager.shared.availableWallpapers.count) Found")
                            .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                            .foregroundColor(.teal)
                    }

                    Button(action: {
                        let openPanel = NSOpenPanel()
                        openPanel.allowsMultipleSelection = false
                        openPanel.canChooseDirectories = false
                        openPanel.canCreateDirectories = false
                        openPanel.allowedContentTypes = [.image, .jpeg, .png, .heic, .html]
                        openPanel.title = "Upload / Select Custom Desktop Wallpaper"
                        openPanel.level = NSWindow.Level(rawValue: max(NSWindow.Level.statusBar.rawValue, NSApp.keyWindow?.level.rawValue ?? 0) + 10)
                        NSApp.activate(ignoringOtherApps: true)
                        openPanel.center()
                        openPanel.orderFrontRegardless()
                        if openPanel.runModal() == .OK, let url = openPanel.url {
                            sameWallpaperMode = false
                            wallpaperMatchingStyle = url.deletingPathExtension().lastPathComponent
                            _ = WallpaperManager.shared.setSystemWallpaper(path: url.path)
                        }
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 13))
                                .foregroundColor(.teal)
                            Text(LocalizedStrings.translateText("Upload / Select Custom Image from Mac...", lang: appLanguage))
                                .font(.system(size: 11, weight: .semibold))
                            Spacer()
                            Image(systemName: "photo.on.rectangle.angled")
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.teal.opacity(0.12))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.teal.opacity(0.3), lineWidth: 1.0)
                        )
                    }
                    .buttonStyle(.plain)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(WallpaperManager.shared.availableWallpapers.filter { !$0.isSystemActive }.prefix(24), id: \.id) { wpItem in
                            Button(action: {
                                HapticFeedback.selection()
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.70)) {
                                    sameWallpaperMode = false
                                    wallpaperMatchingStyle = wpItem.name
                                    _ = WallpaperManager.shared.setSystemWallpaper(path: wpItem.path)
                                }
                            }) {
                                VStack(spacing: 3) {
                                    ZStack(alignment: .topTrailing) {
                                        if let thumb = WallpaperManager.shared.thumbnail(for: wpItem) {
                                            Image(nsImage: thumb)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(height: 52)
                                                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                                        } else {
                                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                                .fill(Color.gray.opacity(0.3))
                                                .frame(height: 52)
                                                .overlay(Image(systemName: "photo").foregroundColor(.secondary))
                                        }

                                        if !sameWallpaperMode && (wallpaperMatchingStyle == wpItem.name || wallpaperMatchingStyle == wpItem.path) {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 14))
                                                .foregroundColor(.teal)
                                                .background(Circle().fill(Color.black.opacity(0.7)))
                                                .padding(4)
                                        }
                                    }

                                    Text(wpItem.name)
                                        .font(.system(size: 9, weight: (!sameWallpaperMode && wallpaperMatchingStyle == wpItem.name) ? .bold : .medium))
                                        .foregroundColor((!sameWallpaperMode && wallpaperMatchingStyle == wpItem.name) ? .teal : .primary)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                }
                                .padding(4)
                                .background(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill((!sameWallpaperMode && (wallpaperMatchingStyle == wpItem.name || wallpaperMatchingStyle == wpItem.path)) ? Color.teal.opacity(0.15) : Color(nsColor: .controlBackgroundColor).opacity(0.55))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke((!sameWallpaperMode && (wallpaperMatchingStyle == wpItem.name || wallpaperMatchingStyle == wpItem.path)) ? Color.teal : Color.primary.opacity(0.06), lineWidth: 1.5)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                Divider().opacity(0.4)

                // Section 2: Atmospheric FX Shaders
                HStack {
                    Text(LocalizedStrings.translateText("Enable Atmospheric Shaders", lang: appLanguage))
                        .font(.system(size: 12, weight: .medium))
                    Spacer()
                    Toggle("", isOn: $wallpaperFxEnabled)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .controlSize(.small)
                }

                HStack {
                    Text(LocalizedStrings.translateText("ATMOSPHERIC FX SHADERS", lang: appLanguage))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(filteredShaders.count) shaders")
                        .font(.system(size: 9.5))
                        .foregroundColor(.secondary)
                }

                FilterPillBar(
                    categories: shaderCategories,
                    selectedCategory: $shaderCategoryFilter,
                    tintColor: .teal
                )

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(filteredShaders, id: \.self) { fx in
                        Button(action: {
                            HapticFeedback.selection()
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.70)) {
                                wallpaperFxType = fx
                            }
                        }) {
                            HStack {
                                Text(fx)
                                    .font(.system(size: 11, weight: wallpaperFxType == fx ? .bold : .medium))
                                    .foregroundColor(wallpaperFxType == fx ? .teal : .primary)
                                    .lineLimit(1)
                                Spacer()
                                if wallpaperFxType == fx {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.teal)
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 9)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(wallpaperFxType == fx ? Color.teal.opacity(0.12) : Color(nsColor: .controlBackgroundColor).opacity(0.55))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(wallpaperFxType == fx ? Color.teal : Color.primary.opacity(0.06), lineWidth: wallpaperFxType == fx ? 1.5 : 0.5)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                if wallpaperFxType != "None" {
                    Divider().opacity(0.4)

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(LocalizedStrings.translateText("Effect Intensity", lang: appLanguage))
                                .font(.system(size: 12))
                            Spacer()
                            Text("\(Int(wallpaperFxIntensity * 100))%")
                                .font(.system(size: 11).monospacedDigit())
                                .foregroundColor(.secondary)
                        }
                        Slider(value: $wallpaperFxIntensity, in: 0.10...0.80, step: 0.05)
                            .controlSize(.small)
                    }
                }
            }
            .padding(.trailing, 4)
    }

    private var motionFxDetailView: some View {
        VStack(alignment: .leading, spacing: 12) {

            // MARK: - 1. Genie Summon Animation & Smoke Effects
            GenieSummonAndSmokeCard(
                genieAnimEnabled: $genieAnimEnabled,
                genieAnimOrigin: $genieAnimOrigin,
                smokeEffectsEnabled: $smokeEffectsEnabled,
                smokeStyle: $smokeStyle,
                popoverBounds: popoverBounds
            )

            Divider().opacity(0.4)

            // Trackpad Multi-Touch Gesture & Quick Trigger Engine
            Text(LocalizedStrings.translateText("QUICK SUMMON & TRACKPAD GESTURES ⚡️", lang: appLanguage))
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary)

            VStack(spacing: 8) {
                // Trigger 1: Double-Tap Control Key (Interactive test + enable)
                Button(action: {
                    HapticFeedback.selection()
                    NotificationCenter.default.post(name: NSNotification.Name("NexusToggleDesktopGrid"), object: nil)
                }) {
                    HStack {
                        Image(systemName: "keyboard.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.yellow)
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(LocalizedStrings.translateText("Double-Tap Control Key (Instant ⚡️)", lang: appLanguage))
                                    .font(.system(size: 11.5, weight: .bold))
                                    .foregroundColor(.primary)
                                Text(LocalizedStrings.translateText("TAP TO TEST", lang: appLanguage))
                                    .font(.system(size: 8, weight: .heavy))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(Capsule().fill(Color.yellow.opacity(0.20)))
                                    .foregroundColor(.yellow)
                            }
                            Text(LocalizedStrings.translateText("Press ⌃ Control twice rapidly from anywhere on your Mac to toggle apps.", lang: appLanguage))
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "bolt.circle.fill")
                            .font(.system(size: 15))
                            .foregroundColor(.yellow)
                    }
                    .padding(.horizontal, 11)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.yellow.opacity(0.10))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.yellow.opacity(0.4), lineWidth: 1.0)
                    )
                }
                .buttonStyle(.plain)

                // Trigger 2: Four-Finger / Multi-Finger Drag Down (Interactive test)
                Button(action: {
                    HapticFeedback.selection()
                    NotificationCenter.default.post(name: NSNotification.Name("NexusToggleDesktopGrid"), object: nil)
                }) {
                    HStack {
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.cyan)
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(LocalizedStrings.translateText("Trackpad Multi-Finger Swipe (🖐️)", lang: appLanguage))
                                    .font(.system(size: 11.5, weight: .bold))
                                    .foregroundColor(.primary)
                                Text(LocalizedStrings.translateText("TAP TO TEST", lang: appLanguage))
                                    .font(.system(size: 8, weight: .heavy))
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 1)
                                    .background(Capsule().fill(Color.cyan.opacity(0.20)))
                                    .foregroundColor(.cyan)
                            }
                            Text(LocalizedStrings.translateText("Drag fingers up/down on trackpad or click here to summon / dismiss.", lang: appLanguage))
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Image(systemName: "hand.tap.fill")
                            .font(.system(size: 15))
                            .foregroundColor(.cyan)
                    }
                    .padding(.horizontal, 11)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.cyan.opacity(0.10))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.cyan.opacity(0.4), lineWidth: 1.0)
                    )
                }
                .buttonStyle(.plain)
            }

            Divider().opacity(0.4)

            Text(LocalizedStrings.translateText("BACKGROUND APP PHYSICS", lang: appLanguage))
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(appPhysicsOptions, id: \.self) { sim in
                    Button(action: {
                        HapticFeedback.selection()
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.70)) {
                            appPhysicsSimulation = sim
                        }
                    }) {
                        HStack {
                            Text(sim)
                                .font(.system(size: 11, weight: appPhysicsSimulation == sim ? .bold : .medium))
                                .foregroundColor(appPhysicsSimulation == sim ? .cyan : .primary)
                                .lineLimit(1)
                            Spacer()
                            if appPhysicsSimulation == sim {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.cyan)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 9)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(appPhysicsSimulation == sim ? Color.cyan.opacity(0.12) : Color(nsColor: .controlBackgroundColor).opacity(0.55))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(appPhysicsSimulation == sim ? Color.cyan : Color.primary.opacity(0.06), lineWidth: appPhysicsSimulation == sim ? 1.5 : 0.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider().opacity(0.4)

            HStack {
                Text(LocalizedStrings.translateText("INTERACTIVE CURSOR TRAILS", lang: appLanguage))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(filteredCursorFx.count) styles")
                    .font(.system(size: 9.5))
                    .foregroundColor(.secondary)
            }

            FilterPillBar(
                categories: cursorFxCategories,
                selectedCategory: $cursorFxCategoryFilter
            )

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(filteredCursorFx, id: \.self) { cfx in
                    Button(action: {
                        HapticFeedback.selection()
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.70)) {
                            cursorFxType = cfx
                            GenieGlobalCursorFXOverlayManager.shared.setCursorFxType(cfx)
                        }
                    }) {
                        HStack {
                            Text(cfx)
                                .font(.system(size: 11, weight: cursorFxType == cfx ? .bold : .medium))
                                .foregroundColor(cursorFxType == cfx ? .cyan : .primary)
                                .lineLimit(1)
                            Spacer()
                            if cursorFxType == cfx {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.cyan)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 9)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(cursorFxType == cfx ? Color.cyan.opacity(0.16) : Color(nsColor: .controlBackgroundColor).opacity(0.55))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(cursorFxType == cfx ? Color.cyan.opacity(0.75) : Color.white.opacity(0.06), lineWidth: cursorFxType == cfx ? 1.5 : 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider().opacity(0.4)

            HStack {
                Image(systemName: "gamecontroller.fill")
                    .foregroundColor(.yellow)
                Text(LocalizedStrings.translateText("Desktop Pinball Arcade Mode", lang: appLanguage))
                    .font(.system(size: 12))
                Spacer()
                Toggle("", isOn: $pinballModeEnabled)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.small)
            }

            Text(LocalizedStrings.translateText("💡 Tip: Double-click any empty desktop space to drop sparkling treats 🌟 for your living pets!", lang: appLanguage))
                .font(.system(size: 10.5))
                .foregroundColor(.secondary)
                .padding(.top, 2)
        }
    }

    // MARK: - Dedicated Mouse & Cursor Trails Detail View

    private var mouseTrailsDetailView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "cursorarrow.rays")
                    .font(.system(size: 11))
                    .foregroundColor(.teal)
                Text(LocalizedStrings.translateText("MOUSE CURSOR FILTERS & TRAILS", lang: appLanguage))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(filteredCursorFx.count) filters")
                    .font(.system(size: 9.5))
                    .foregroundColor(.secondary)
            }

            FilterPillBar(
                categories: cursorFxCategories,
                selectedCategory: $cursorFxCategoryFilter,
                tintColor: .teal
            )

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(filteredCursorFx, id: \.self) { cfx in
                    Button(action: {
                        HapticFeedback.selection()
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.70)) {
                            cursorFxType = cfx
                            GenieGlobalCursorFXOverlayManager.shared.setCursorFxType(cfx)
                        }
                    }) {
                        HStack {
                            Text(cfx)
                                .font(.system(size: 11, weight: cursorFxType == cfx ? .bold : .medium))
                                .foregroundColor(cursorFxType == cfx ? .teal : .primary)
                                .lineLimit(1)
                            Spacer()
                            if cursorFxType == cfx {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.teal)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 9)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(cursorFxType == cfx ? Color.teal.opacity(0.16) : Color(nsColor: .controlBackgroundColor).opacity(0.55))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(cursorFxType == cfx ? Color.teal.opacity(0.75) : Color.white.opacity(0.06), lineWidth: cursorFxType == cfx ? 1.5 : 1)
                                )
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider().opacity(0.4)

            // Mouse Interaction Settings
            VStack(alignment: .leading, spacing: 6) {
                Text(LocalizedStrings.translateText("MOUSE & DESKTOP INTERACTIONS", lang: appLanguage))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)

                HStack {
                    Image(systemName: "cursorarrow.rays")
                        .foregroundColor(.teal)
                    Text(LocalizedStrings.translateText("Living Pets Follow Mouse Cursor", lang: appLanguage))
                        .font(.system(size: 12))
                    Spacer()
                    Toggle("", isOn: $dragonFollowCursor)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .controlSize(.small)
                }

                HStack {
                    Image(systemName: "hand.tap.fill")
                        .foregroundColor(.yellow)
                    Text(LocalizedStrings.translateText("Double-Click Desktop Drops Pet Food 🌟", lang: appLanguage))
                        .font(.system(size: 12))
                    Spacer()
                    Text(LocalizedStrings.translateText("Active", lang: appLanguage))
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.green)
                }
            }
        }
    }

    // MARK: - Tab 7: Living Entities & Pets Detail View

    private var entitiesDetailView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(LocalizedStrings.translateText("LIVING PETS & AMBIENT CREATURES", lang: appLanguage))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(filteredEntities.count) companions")
                    .font(.system(size: 9.5))
                    .foregroundColor(.secondary)
            }

            FilterPillBar(
                categories: entityCategories,
                selectedCategory: $entityCategoryFilter,
                tintColor: .orange
            )

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(filteredEntities, id: \.self) { entity in
                    Button(action: {
                        HapticFeedback.selection()
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.70)) {
                            ambientEntity = entity
                        }
                    }) {
                        HStack {
                            Text(entity)
                                .font(.system(size: 11, weight: ambientEntity == entity ? .bold : .medium))
                                .foregroundColor(ambientEntity == entity ? .orange : .primary)
                                .lineLimit(1)
                            Spacer()
                            if ambientEntity == entity {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.orange)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 9)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(ambientEntity == entity ? Color.orange.opacity(0.12) : Color(nsColor: .controlBackgroundColor).opacity(0.55))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(ambientEntity == entity ? Color.orange : Color.primary.opacity(0.06), lineWidth: ambientEntity == entity ? 1.5 : 0.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            if ambientEntity != "None" {
                Divider().opacity(0.4)

                HStack {
                    Image(systemName: "cursorarrow.rays")
                        .font(.system(size: 11))
                        .foregroundColor(.teal)
                    Text(LocalizedStrings.translateText("Follow & Play with Cursor", lang: appLanguage))
                        .font(.system(size: 12))
                    Spacer()
                    Toggle("", isOn: $dragonFollowCursor)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .controlSize(.small)
                }
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Tab: Mouse & Trackpad Detail View

    private var mouseAndTrackpadDetailView: some View {
        VStack(alignment: .leading, spacing: 14) {
            AppleSettingsSection("Trackpad Gestures & Dismissal") {
                AppleSettingsRow(title: "Trackpad Swipe Sensitivity", subtitle: "Deliberate downward swipe to reveal desktop", icon: "hand.draw.fill", iconColor: .green) {
                    Picker("", selection: Binding(
                        get: { UserDefaults.standard.string(forKey: PrefKey.swipeSensitivity) ?? "Deliberate (Firm Swipe)" },
                        set: { UserDefaults.standard.set($0, forKey: PrefKey.swipeSensitivity) }
                    )) {
                        Text("Deliberate (Firm)").tag("Deliberate (Firm Swipe)")
                        Text("Natural / Fluid").tag("Natural (Fluid Flick)")
                        Text("Sensitive (Light)").tag("Sensitive (Light Swipe)")
                    }
                    .labelsHidden()
                    .frame(width: 140)
                }
            }

            motionFxDetailView

            mouseTrailsDetailView
        }
    }

    // MARK: - Tab: Living Pets & Pinball Detail View

    private var livingPetsAndPinballDetailView: some View {
        VStack(alignment: .leading, spacing: 14) {
            attachableAnimatedChatWidgetSection

            Divider().opacity(0.3)

            attachableWorldClockWidgetSection

            Divider().opacity(0.3)

            entitiesDetailView

            Divider().opacity(0.3)

            AppleSettingsSection("Desktop Pinball Arcade Mode") {
                AppleSettingsRow(title: "Pinball Arcade Simulation", subtitle: "Bounce interactive pinballs with realistic desktop physics", icon: "gamecontroller.fill", iconColor: .yellow) {
                    Toggle("", isOn: $pinballModeEnabled)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .controlSize(.small)
                }
            }

            Text(LocalizedStrings.translateText("💡 Tip: Double-click any empty desktop space to drop sparkling treats 🌟 for your living pets!", lang: appLanguage))
                .font(.system(size: 10.5))
                .foregroundColor(.secondary)
                .padding(.top, 2)
        }
    }

    private var attachableAnimatedChatWidgetSection: some View {
        AppleSettingsSection("Animated Living AI Chat Widget") {
            AppleSettingsRow(
                title: "Pin Animated Chat Widget to Desktop",
                subtitle: "Floating living AI complication with pulsing neural aura and dynamic equalizer",
                icon: "bubble.left.and.bubble.right.fill",
                iconColor: .cyan
            ) {
                Toggle("", isOn: $attachAnimatedChatWidget)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.small)
            }

            if attachAnimatedChatWidget {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(RadialGradient(colors: [Color.cyan.opacity(0.8), Color.purple.opacity(0.3), Color.clear], center: .center, startRadius: 2, endRadius: 14))
                                .frame(width: 28, height: 28)
                            Circle()
                                .fill(Color.cyan)
                                .frame(width: 8, height: 8)
                        }

                        VStack(alignment: .leading, spacing: 1) {
                            Text("Genie Copilot Complication")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                            Text("Live floating complication • Drag anywhere on desktop")
                                .font(.system(size: 9.5))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Button(action: {
                            HapticFeedback.selection()
                            selectedTab = .chat
                        }) {
                            HStack(spacing: 4) {
                                Text("Open Chat")
                                    .font(.system(size: 10, weight: .semibold))
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 8, weight: .bold))
                            }
                            .foregroundColor(.cyan)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.cyan.opacity(0.15)))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                }
            }
        }
    }

    private var attachableWorldClockWidgetSection: some View {
        AppleSettingsSection("Attachable World Clock Widget") {
            AppleSettingsRow(
                title: "Pin World Clock to Desktop",
                subtitle: "Attach floating OLED blackout world clock widget to your workspace",
                icon: "clock.badge.checkmark.fill",
                iconColor: .orange
            ) {
                Toggle("", isOn: $attachWorldClockWidget)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.small)
            }

            if attachWorldClockWidget {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Widget Card Layout Tier")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        Spacer()
                        Picker("", selection: Binding(
                            get: { GenieWorldClockStore.shared.settings.size },
                            set: { GenieWorldClockStore.shared.resizeAll(to: $0) }
                        )) {
                            ForEach(GeniePillowSize.allCases) { size in
                                Label(size.label, systemImage: size.icon).tag(size)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 240)
                        .controlSize(.small)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)

                    // Live preview of the clock widget in mini form
                    HStack(spacing: 12) {
                        TimelineView(.periodic(from: .now, by: 1)) { timelineContext in
                            HStack(spacing: 8) {
                                ForEach(Array(GenieWorldClockStore.shared.settings.cities.prefix(3))) { city in
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(city.accent.color)
                                            .frame(width: 6, height: 6)
                                        Text(city.name)
                                            .font(.system(size: 10, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                        Text(city.offsetDescription(from: .current, at: timelineContext.date))
                                            .font(.system(size: 8.5, design: .monospaced))
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(Color.white.opacity(0.07)))
                                }
                            }
                        }
                        Spacer()
                        Button(action: {
                            HapticFeedback.selection()
                            selectedTab = .worldClock
                        }) {
                            HStack(spacing: 4) {
                                Text("Manage Cities & Alarms")
                                    .font(.system(size: 10, weight: .semibold))
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 8, weight: .bold))
                            }
                            .foregroundColor(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.orange.opacity(0.15)))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 6)
                }
            }
        }
    }

    // MARK: - Tab: Menu Bar & Notch Detail View

    private var menuBarSettingsDetailView: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Live Interactive Preview
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("LIVE MENU BAR PREVIEW")
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(fontFamily.components(separatedBy: " ").first ?? fontFamily) • \(fontWeight) • \(String(format: "%.1f", menuBarFontSize))pt")
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 12) {
                    // Apple Logo
                    AppleLogoView(style: appleColor, size: 13)

                    // App Name (Active Program Name Color)
                    Text("Genie")
                        .font(MenuBarThemeManager.resolveFont(family: fontFamily, size: CGFloat(menuBarFontSize), weightName: "Bold"))
                        .foregroundColor(activeAppColorName == "Matching Menu Items" ? MenuBarThemeManager.resolveColor(textColorName) : MenuBarThemeManager.resolveColor(activeAppColorName))

                    // Sample Menus
                    HStack(spacing: 10) {
                        Text("File")
                        Text("Edit")
                        Text("View")
                        Text("Window")
                        Text("Help")
                    }
                    .font(MenuBarThemeManager.resolveFont(family: fontFamily, size: CGFloat(menuBarFontSize), weightName: fontWeight))
                    .foregroundColor(MenuBarThemeManager.resolveColor(textColorName).opacity(0.85))

                    Spacer()

                    // Battery & Percentage
                    HStack(spacing: 5) {
                        Image(systemName: "battery.100")
                            .font(.system(size: 11))
                            .foregroundColor(MenuBarThemeManager.resolveColor(textColorName))
                        Text("100%")
                            .font(MenuBarThemeManager.resolveFont(family: fontFamily, size: CGFloat(menuBarFontSize), weightName: fontWeight).monospacedDigit())
                            .foregroundColor(MenuBarThemeManager.resolveColor(textColorName))
                    }

                    // Clock
                    Text(MenuBarThemeManager.formatDate(Date(), format: timeFormat))
                        .font(MenuBarThemeManager.resolveFont(family: fontFamily, size: CGFloat(menuBarFontSize), weightName: fontWeight).monospacedDigit())
                        .foregroundColor(MenuBarThemeManager.resolveColor(textColorName))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(
                    ZStack {
                        VisualEffectBlur(material: .menu, blendingMode: .withinWindow)
                        MenuBarThemeManager.resolveBackground(backgroundStyle)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.8)
                    )
                )
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.primary.opacity(0.03)))

            // Menu Bar Typography & Font Sizing
            AppleSettingsSection("Menu Bar Typography & Font Sizing") {
                // Font Family Picker
                AppleSettingsRow(title: "Font Family", subtitle: "Curated typography across system and display fonts", icon: "textformat", iconColor: .blue) {
                    Picker("", selection: $fontFamily) {
                        ForEach(MenuBarThemeManager.fontFamilyOptions, id: \.self) { fam in
                            Text(fam).tag(fam)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 175)
                    .onChange(of: fontFamily) { _, newFam in
                        UserDefaults.standard.set(newFam, forKey: PrefKey.menuBarFontFamily)
                        NotificationCenter.default.post(name: NSNotification.Name("NexusMenuBarThemeChanged"), object: nil)
                    }
                }

                Divider().padding(.leading, 42).opacity(0.25)

                // Font Weight Picker
                AppleSettingsRow(title: "Font Weight", subtitle: "Weight from Regular to Heavy", icon: "bold", iconColor: .indigo) {
                    Picker("", selection: $fontWeight) {
                        ForEach(MenuBarThemeManager.fontWeightOptions, id: \.self) { weight in
                            Text(weight).tag(weight)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 120)
                    .onChange(of: fontWeight) { _, newWeight in
                        UserDefaults.standard.set(newWeight, forKey: PrefKey.menuBarFontWeight)
                        NotificationCenter.default.post(name: NSNotification.Name("NexusMenuBarThemeChanged"), object: nil)
                    }
                }

                Divider().padding(.leading, 42).opacity(0.25)

                // Font Size Slider
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 5.5, style: .continuous)
                                .fill(Color.teal)
                                .frame(width: 22, height: 22)
                            Image(systemName: "textformat.size")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Font Size")
                                .font(.system(size: 11.5))
                            Text("Adjust Menu Bar text scale")
                                .font(.system(size: 9.5))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Text("\(String(format: "%.1f", menuBarFontSize)) pt")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(.secondary)

                        Button("Reset") {
                            HapticFeedback.selection()
                            menuBarFontSize = 13.0
                            UserDefaults.standard.set(13.0, forKey: PrefKey.menuBarFontSize)
                            NotificationCenter.default.post(name: NSNotification.Name("NexusMenuBarThemeChanged"), object: nil)
                        }
                        .font(.system(size: 9.5, weight: .medium))
                        .buttonStyle(.borderless)
                        .padding(.leading, 4)
                    }

                    Slider(value: $menuBarFontSize, in: 10.0...18.0, step: 0.5) {
                        Text("Font Size")
                    } minimumValueLabel: {
                        Text("10pt").font(.system(size: 8.5)).foregroundColor(.secondary)
                    } maximumValueLabel: {
                        Text("18pt").font(.system(size: 8.5)).foregroundColor(.secondary)
                    }
                    .onChange(of: menuBarFontSize) { _, newSize in
                        UserDefaults.standard.set(newSize, forKey: PrefKey.menuBarFontSize)
                        NotificationCenter.default.post(name: NSNotification.Name("NexusMenuBarThemeChanged"), object: nil)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
            }

            // Menu Bar Text Color Palette
            // Menu Bar Text Color Palette
            AppleSettingsSection("Menu Bar Text Color Palette") {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Menu Bar Accent Colors")
                                .font(.system(size: 11.5, weight: .semibold))
                            Text(menuBarColorsEnabled ? "Colors active (App Title & Menus)" : "Using Classic Apple Monochrome White")
                                .font(.system(size: 9.5))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        Toggle("", isOn: $menuBarColorsEnabled)
                            .toggleStyle(SwitchToggleStyle())
                            .onChange(of: menuBarColorsEnabled) { _, val in
                                UserDefaults.standard.set(val, forKey: PrefKey.menuBarColorsEnabled)
                                UserDefaults.standard.synchronize()
                                NotificationCenter.default.post(name: NSNotification.Name("NexusMenuBarThemeChanged"), object: nil)
                            }
                    }

                    // Quick Theme Presets
                    HStack(spacing: 6) {
                        Button(action: {
                            HapticFeedback.selection()
                            menuBarColorsEnabled = false
                            textColorName = "Pure White ⚪️"
                            activeAppColorName = "Pure White ⚪️"
                            UserDefaults.standard.set(false, forKey: PrefKey.menuBarColorsEnabled)
                            UserDefaults.standard.set("Pure White ⚪️", forKey: PrefKey.menuBarTextColor)
                            UserDefaults.standard.set("Pure White ⚪️", forKey: PrefKey.menuBarActiveAppColor)
                            UserDefaults.standard.synchronize()
                            NotificationCenter.default.post(name: NSNotification.Name("NexusMenuBarThemeChanged"), object: nil)
                        }) {
                            Text("⚪️ White (Off)")
                                .font(.system(size: 9.5, weight: !menuBarColorsEnabled ? .bold : .medium))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3.5)
                                .background(Capsule().fill(!menuBarColorsEnabled ? Color.white.opacity(0.2) : Color.primary.opacity(0.06)))
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            HapticFeedback.selection()
                            menuBarColorsEnabled = true
                            activeAppColorName = "Neon Cyan ⚡️"
                            textColorName = "Hot Pink 💖"
                            UserDefaults.standard.set(true, forKey: PrefKey.menuBarColorsEnabled)
                            UserDefaults.standard.set("Neon Cyan ⚡️", forKey: PrefKey.menuBarActiveAppColor)
                            UserDefaults.standard.set("Hot Pink 💖", forKey: PrefKey.menuBarTextColor)
                            UserDefaults.standard.synchronize()
                            NotificationCenter.default.post(name: NSNotification.Name("NexusMenuBarThemeChanged"), object: nil)
                        }) {
                            Text("⚡️💖 Cyberpunk")
                                .font(.system(size: 9.5, weight: (menuBarColorsEnabled && textColorName.contains("Pink")) ? .bold : .medium))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3.5)
                                .background(Capsule().fill((menuBarColorsEnabled && textColorName.contains("Pink")) ? Color.pink.opacity(0.25) : Color.primary.opacity(0.06)))
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            HapticFeedback.selection()
                            menuBarColorsEnabled = true
                            activeAppColorName = "Royal Gold 👑"
                            textColorName = "Solar Amber ☀️"
                            UserDefaults.standard.set(true, forKey: PrefKey.menuBarColorsEnabled)
                            UserDefaults.standard.set("Royal Gold 👑", forKey: PrefKey.menuBarActiveAppColor)
                            UserDefaults.standard.set("Solar Amber ☀️", forKey: PrefKey.menuBarTextColor)
                            UserDefaults.standard.synchronize()
                            NotificationCenter.default.post(name: NSNotification.Name("NexusMenuBarThemeChanged"), object: nil)
                        }) {
                            Text("👑 Gold")
                                .font(.system(size: 9.5, weight: (menuBarColorsEnabled && textColorName.contains("Amber")) ? .bold : .medium))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3.5)
                                .background(Capsule().fill((menuBarColorsEnabled && textColorName.contains("Amber")) ? Color.orange.opacity(0.25) : Color.primary.opacity(0.06)))
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            HapticFeedback.selection()
                            menuBarColorsEnabled = true
                            activeAppColorName = "Emerald Matrix 🟢"
                            textColorName = "Emerald Matrix 🟢"
                            UserDefaults.standard.set(true, forKey: PrefKey.menuBarColorsEnabled)
                            UserDefaults.standard.set("Emerald Matrix 🟢", forKey: PrefKey.menuBarActiveAppColor)
                            UserDefaults.standard.set("Emerald Matrix 🟢", forKey: PrefKey.menuBarTextColor)
                            UserDefaults.standard.synchronize()
                            NotificationCenter.default.post(name: NSNotification.Name("NexusMenuBarThemeChanged"), object: nil)
                        }) {
                            Text("🟢 Emerald")
                                .font(.system(size: 9.5, weight: (menuBarColorsEnabled && textColorName.contains("Emerald")) ? .bold : .medium))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3.5)
                                .background(Capsule().fill((menuBarColorsEnabled && textColorName.contains("Emerald")) ? Color.green.opacity(0.25) : Color.primary.opacity(0.06)))
                        }
                        .buttonStyle(.plain)
                    }

                    if menuBarColorsEnabled {
                        Divider().opacity(0.25)

                        HStack {
                            Text("MENU ITEMS COLOR")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text(textColorName)
                                .font(.system(size: 9.5, weight: .semibold))
                                .foregroundColor(MenuBarThemeManager.resolveColor(textColorName))
                        }

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(MenuBarThemeManager.textColorOptions, id: \.self) { colorOpt in
                                    let isSelected = (textColorName == colorOpt)
                                    let clr = MenuBarThemeManager.resolveColor(colorOpt)
                                    Button(action: {
                                        HapticFeedback.selection()
                                        textColorName = colorOpt
                                        UserDefaults.standard.set(colorOpt, forKey: PrefKey.menuBarTextColor)
                                        UserDefaults.standard.synchronize()
                                        NotificationCenter.default.post(name: NSNotification.Name("NexusMenuBarThemeChanged"), object: nil)
                                        NotificationCenter.default.post(name: NSNotification.Name("NexusIconStyleChanged"), object: nil)
                                    }) {
                                        HStack(spacing: 5) {
                                            Circle()
                                                .fill(clr)
                                                .frame(width: 10, height: 10)
                                                .overlay(Circle().strokeBorder(Color.white.opacity(0.3), lineWidth: 0.8))
                                                .shadow(color: clr.opacity(0.5), radius: 2)

                                            Text(colorOpt.replacingOccurrences(of: " ⚪️", with: "")
                                                .replacingOccurrences(of: " ⚡️", with: "")
                                                .replacingOccurrences(of: " 👑", with: "")
                                                .replacingOccurrences(of: " 🟢", with: "")
                                                .replacingOccurrences(of: " 💜", with: "")
                                                .replacingOccurrences(of: " 💖", with: "")
                                                .replacingOccurrences(of: " ☀️", with: "")
                                                .replacingOccurrences(of: " ❄️", with: ""))
                                                .font(.system(size: 10.5, weight: isSelected ? .bold : .regular))
                                                .foregroundColor(isSelected ? .white : .primary.opacity(0.85))
                                        }
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 5)
                                        .background(
                                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                                .fill(isSelected ? Color.accentColor : Color.primary.opacity(0.06))
                                        )
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                                .strokeBorder(isSelected ? Color.white.opacity(0.3) : Color.white.opacity(0.08), lineWidth: 1)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
            }

            //  Apple Logo Accent Color
            AppleSettingsSection(" Apple Logo Accent Color") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("APPLE LOGO ACCENT")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(appleColor)
                            .font(.system(size: 9.5, weight: .semibold))
                            .foregroundColor(.secondary)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(MenuBarThemeManager.appleColorOptions, id: \.self) { opt in
                                let isSelected = (appleColor == opt)
                                Button(action: {
                                    HapticFeedback.selection()
                                    appleColor = opt
                                    UserDefaults.standard.set(opt, forKey: PrefKey.menuBarAppleColor)
                                    NotificationCenter.default.post(name: NSNotification.Name("NexusMenuBarAppleColorChanged"), object: opt)
                                    NotificationCenter.default.post(name: NSNotification.Name("NexusIconStyleChanged"), object: nil)
                                }) {
                                    VStack(spacing: 4) {
                                        AppleLogoView(style: opt, size: 16)
                                            .frame(width: 28, height: 24)

                                        Text(opt.split(separator: " ").first.map(String.init) ?? opt)
                                            .font(.system(size: 9, weight: isSelected ? .bold : .regular))
                                            .foregroundColor(isSelected ? .accentColor : .secondary)
                                            .lineLimit(1)
                                    }
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 6)
                                    .frame(minWidth: 54)
                                    .background(
                                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                                            .fill(isSelected ? Color.accentColor.opacity(0.18) : Color.primary.opacity(0.05))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                                            .strokeBorder(isSelected ? Color.accentColor : Color.white.opacity(0.08), lineWidth: isSelected ? 1.5 : 0.8)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
            }

            // Active Program Name Color
            AppleSettingsSection("Active Program Name Color") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("ACTIVE PROGRAM COLOR")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(activeAppColorName)
                            .font(.system(size: 9.5, weight: .semibold))
                            .foregroundColor(activeAppColorName == "Matching Menu Items" ? MenuBarThemeManager.resolveColor(textColorName) : MenuBarThemeManager.resolveColor(activeAppColorName))
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(MenuBarThemeManager.activeAppColorOptions, id: \.self) { colorOpt in
                                let isSelected = (activeAppColorName == colorOpt)
                                let clr = colorOpt == "Matching Menu Items" ? MenuBarThemeManager.resolveColor(textColorName) : MenuBarThemeManager.resolveColor(colorOpt)
                                Button(action: {
                                    HapticFeedback.selection()
                                    activeAppColorName = colorOpt
                                    UserDefaults.standard.set(colorOpt, forKey: PrefKey.menuBarActiveAppColor)
                                    NotificationCenter.default.post(name: NSNotification.Name("NexusMenuBarActiveAppColorChanged"), object: colorOpt)
                                    CustomMenuBarManager.shared.rebuildWindows()
                                }) {
                                    HStack(spacing: 5) {
                                        Circle()
                                            .fill(clr)
                                            .frame(width: 10, height: 10)
                                            .overlay(Circle().strokeBorder(Color.white.opacity(0.3), lineWidth: 0.8))
                                            .shadow(color: clr.opacity(0.5), radius: 2)

                                        Text(colorOpt.replacingOccurrences(of: " ⚡️", with: "")
                                            .replacingOccurrences(of: " 👑", with: "")
                                            .replacingOccurrences(of: " 💖", with: "")
                                            .replacingOccurrences(of: " 🟢", with: "")
                                            .replacingOccurrences(of: " ☀️", with: "")
                                            .replacingOccurrences(of: " 💜", with: "")
                                            .replacingOccurrences(of: " ❄️", with: "")
                                            .replacingOccurrences(of: " 🔴", with: "")
                                            .replacingOccurrences(of: " 🍊", with: "")
                                            .replacingOccurrences(of: " 🔵", with: "")
                                            .replacingOccurrences(of: " ⚪️", with: ""))
                                            .font(.system(size: 10.5, weight: isSelected ? .bold : .regular))
                                            .foregroundColor(isSelected ? .white : .primary.opacity(0.85))
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 5)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .fill(isSelected ? Color.accentColor : Color.primary.opacity(0.06))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .strokeBorder(isSelected ? Color.white.opacity(0.3) : Color.white.opacity(0.08), lineWidth: 1)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
            }

            // Menu Bar Date & Time Format
            AppleSettingsSection("Menu Bar Date & Time Format") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("DATE & TIME FORMAT")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(MenuBarThemeManager.formatDate(Date(), format: timeFormat))
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.accentColor)
                    }

                    Picker("Time Format", selection: $timeFormat) {
                        ForEach(MenuBarThemeManager.timeFormatOptions, id: \.self) { fmt in
                            Text(fmt).tag(fmt)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: timeFormat) { _, newFmt in
                        UserDefaults.standard.set(newFmt, forKey: PrefKey.menuBarTimeFormat)
                        NotificationCenter.default.post(name: NSNotification.Name("NexusMenuBarTimeFormatChanged"), object: newFmt)
                    }

                    Divider().opacity(0.3)

                    HStack(spacing: 12) {
                        Button(action: {
                            MenuBarThemeManager.cycleNextTimeFormat()
                            if let cur = UserDefaults.standard.string(forKey: PrefKey.menuBarTimeFormat) {
                                timeFormat = cur
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.triangle.2.circlepath")
                                Text("Cycle Next Format")
                            }
                            .font(.system(size: 10, weight: .medium))
                        }
                        .buttonStyle(.borderless)

                        Spacer()

                        Button(action: {
                            if let url = URL(string: "x-apple.systempreferences:com.apple.Date-Time-Settings.extension") {
                                NSWorkspace.shared.open(url)
                            } else {
                                NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/System Settings.app"))
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "gearshape")
                                Text("System Date & Time...")
                            }
                            .font(.system(size: 10, weight: .medium))
                        }
                        .buttonStyle(.borderless)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
            }

            // Floating Liquid Menu Bar Overlay
            AppleSettingsSection("Floating Liquid Menu Bar Overlay") {
                AppleSettingsRow(title: "Enable Floating Liquid Menu Bar", subtitle: "Full macOS menu bar replacement across all screens with liquid glass", icon: "macwindow.on.rectangle", iconColor: .purple) {
                    Toggle("", isOn: $customMenuBarEnabled)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .controlSize(.small)
                        .onChange(of: customMenuBarEnabled) { _, enabled in
                            UserDefaults.standard.set(enabled, forKey: PrefKey.customMenuBarEnabled)
                            CustomMenuBarManager.shared.isEnabled = enabled
                        }
                }

                if customMenuBarEnabled {
                    Divider().padding(.leading, 42).opacity(0.25)

                    AppleSettingsRow(title: "Liquid Background Style", subtitle: "Glass blur, obsidian dark, or gradient themes", icon: "paintpalette.fill", iconColor: .pink) {
                        Picker("", selection: $backgroundStyle) {
                            ForEach(MenuBarThemeManager.backgroundOptions, id: \.self) { bg in
                                Text(bg).tag(bg)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 175)
                        .onChange(of: backgroundStyle) { _, newBg in
                            UserDefaults.standard.set(newBg, forKey: PrefKey.menuBarBackgroundStyle)
                            CustomMenuBarManager.shared.rebuildWindows()
                        }
                    }
                }
            }

            // Mini Dock & Full macOS Dock
            AppleSettingsSection("Mini Dock & Full macOS Dock") {
                AppleSettingsRow(title: "Mini Dock Display Mode", subtitle: "Choose whether the mini dock is permanently shown or always hidden and pops down on hover", icon: "dock.rectangle", iconColor: .teal) {
                    Picker("", selection: $miniDockDisplayMode) {
                        Text("Always On").tag("Always Shown")
                        Text("Always Hidden (Pop Down)").tag("Always Hidden")
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 220)
                    .onChange(of: miniDockDisplayMode) { _, mode in
                        UserDefaults.standard.set(mode, forKey: PrefKey.miniDockDisplayMode)
                        NotificationCenter.default.post(name: NSNotification.Name("NexusMiniDockModeChanged"), object: mode)
                    }
                }

                Divider().padding(.leading, 42).opacity(0.25)

                AppleSettingsRow(title: "Active Applications Only", subtitle: "Show only currently open apps, or display the whole macOS Dock with all pinned apps", icon: "app.badge.checkmark", iconColor: .blue) {
                    Toggle("", isOn: $dockActiveAppsOnly)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .controlSize(.small)
                        .onChange(of: dockActiveAppsOnly) { _, enabled in
                            UserDefaults.standard.set(enabled, forKey: PrefKey.dockActiveAppsOnly)
                            NotificationCenter.default.post(name: NSNotification.Name("NexusDockActiveAppsOnlyChanged"), object: enabled)
                        }
                }
            }

            // Status Emoji & Brand Icon
            AppleSettingsSection("Status Emoji & Brand Icon") {
                // Toggle Show Brand Glyph
                AppleSettingsRow(title: "Show Brand Glyph in Menu Bar", subtitle: "Icon shown next to battery", icon: "sparkles", iconColor: .purple) {
                    Toggle("", isOn: $iconEnabled)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .controlSize(.small)
                        .onChange(of: iconEnabled) { _, enabled in
                            UserDefaults.standard.set(enabled, forKey: PrefKey.iconEnabled)
                            NotificationCenter.default.post(name: .init("NexusIconStyleChanged"), object: nil)
                        }
                }

                if iconEnabled {
                    Divider().padding(.leading, 42).opacity(0.25)

                    // Quick Emoji Chips
                    VStack(alignment: .leading, spacing: 6) {
                        Text("CHOOSE AN EMOJI")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.secondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(["🪔", "🐶", "", "⚡️", "🔥", "💎", "✨", "💻", "☕️", "👑", "🦄", "🪐", "🕹️", "👾", "🍕", "🌈", "🍀"], id: \.self) { emoji in
                                    let isSelected = statusIconStyle.contains(emoji)
                                    Button(action: {
                                        HapticFeedback.selection()
                                        statusIconStyle = emoji
                                        BrandLogoManager.shared.setCustomEmoji(emoji)
                                    }) {
                                        Text(emoji)
                                            .font(.system(size: 16))
                                            .frame(width: 28, height: 28)
                                            .background(
                                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                                    .fill(isSelected ? Color.accentColor.opacity(0.25) : Color.primary.opacity(0.06))
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                                    .strokeBorder(isSelected ? Color.accentColor : Color.white.opacity(0.08), lineWidth: isSelected ? 1.5 : 0.8)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)

                    Divider().padding(.leading, 42).opacity(0.25)

                    // Pick Their Own Emoji (Custom Input Textfield)
                    HStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 5.5, style: .continuous)
                                .fill(Color.indigo)
                                .frame(width: 22, height: 22)
                            Image(systemName: "face.smiling.fill")
                                .font(.system(size: 10.5, weight: .semibold))
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 1) {
                            Text("Custom Emoji")
                                .font(.system(size: 11.5))
                            Text("Type or paste any emoji")
                                .font(.system(size: 9.5))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        HStack(spacing: 6) {
                            TextField("e.g. 🦊", text: $customEmojiInput)
                                .textFieldStyle(.plain)
                                .font(.system(size: 12))
                                .frame(width: 55)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(RoundedRectangle(cornerRadius: 5, style: .continuous).fill(Color.primary.opacity(0.06)))
                                .overlay(RoundedRectangle(cornerRadius: 5, style: .continuous).strokeBorder(Color.white.opacity(0.12), lineWidth: 0.8))
                                .onSubmit {
                                    if !customEmojiInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        HapticFeedback.selection()
                                        statusIconStyle = customEmojiInput
                                        BrandLogoManager.shared.setCustomEmoji(customEmojiInput)
                                    }
                                }

                            Button(action: {
                                if !customEmojiInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    HapticFeedback.selection()
                                    statusIconStyle = customEmojiInput
                                    BrandLogoManager.shared.setCustomEmoji(customEmojiInput)
                                }
                            }) {
                                Text("Set")
                                    .font(.system(size: 10, weight: .bold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3.5)
                                    .background(Capsule().fill(Color.accentColor))
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                }
            }
        }
    }

    // MARK: - Tab: Genie AI & Models Detail View

    private var aiModelsDetailView: some View {
        VStack(alignment: .leading, spacing: 14) {
            // 1. Intelligence Engines & API Keys (Gemini, Claude, OpenAI)
            AppleSettingsSection("Bring Your Own API Keys (Gemini, Claude, OpenAI)") {
                // Google Gemini
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Image(systemName: "sparkles")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.blue)
                        Text("Google Gemini API Key")
                            .font(.system(size: 11.5, weight: .semibold))
                        Spacer()
                        if !LocalModelManager.shared.geminiApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text("Active ✓")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.green)
                        } else {
                            Text("Optional")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                    HStack(spacing: 6) {
                        TextField("AQ.... or AIzaSy... (Gemini 2.5 Pro / Flash)", text: Binding(
                            get: { LocalModelManager.shared.geminiApiKey },
                            set: { LocalModelManager.shared.geminiApiKey = $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 11, design: .monospaced))

                        Button(action: {
                            if let clip = NSPasteboard.general.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines), !clip.isEmpty {
                                LocalModelManager.shared.geminiApiKey = clip
                                HapticFeedback.selection()
                            }
                        }) {
                            Text("Paste")
                                .font(.system(size: 10.5, weight: .medium))
                        }
                    }

                }
                .padding(.vertical, 4)

                Divider().opacity(0.35)

                // Anthropic Claude
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.orange)
                        Text("Anthropic Claude API Key")
                            .font(.system(size: 11.5, weight: .semibold))
                        Spacer()
                        if !LocalModelManager.shared.claudeApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text("Active ✓")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.green)
                        } else {
                            Text("Optional")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                    HStack(spacing: 6) {
                        TextField("sk-ant-... (Claude 3.7 Sonnet / Thinking)", text: Binding(
                            get: { LocalModelManager.shared.claudeApiKey },
                            set: { LocalModelManager.shared.claudeApiKey = $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 11, design: .monospaced))

                        Button(action: {
                            if let clip = NSPasteboard.general.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines), !clip.isEmpty {
                                LocalModelManager.shared.claudeApiKey = clip
                                HapticFeedback.selection()
                            }
                        }) {
                            Text("Paste")
                                .font(.system(size: 10.5, weight: .medium))
                        }
                    }
                }
                .padding(.vertical, 4)

                Divider().opacity(0.35)

                // OpenAI
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Image(systemName: "cpu")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.green)
                        Text("OpenAI API Key")
                            .font(.system(size: 11.5, weight: .semibold))
                        Spacer()
                        if !LocalModelManager.shared.openaiApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text("Active ✓")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.green)
                        } else {
                            Text("Optional")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                    HStack(spacing: 6) {
                        TextField("sk-proj-... (GPT-4o, o3-mini, o1)", text: Binding(
                            get: { LocalModelManager.shared.openaiApiKey },
                            set: { LocalModelManager.shared.openaiApiKey = $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 11, design: .monospaced))

                        Button(action: {
                            if let clip = NSPasteboard.general.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines), !clip.isEmpty {
                                LocalModelManager.shared.openaiApiKey = clip
                                HapticFeedback.selection()
                            }
                        }) {
                            Text("Paste")
                                .font(.system(size: 10.5, weight: .medium))
                        }
                    }
                }
                .padding(.vertical, 4)

                Divider().opacity(0.35)

                // xAI Grok
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Image(systemName: "bolt.shield.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.purple)
                        Text("xAI Grok API Key")
                            .font(.system(size: 11.5, weight: .semibold))
                        Spacer()
                        if !LocalModelManager.shared.grokApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text("Active ✓")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.green)
                        } else {
                            Text("Optional")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                    HStack(spacing: 6) {
                        TextField("xai-... (Grok 2 / Grok 2 Vision)", text: Binding(
                            get: { LocalModelManager.shared.grokApiKey },
                            set: { LocalModelManager.shared.grokApiKey = $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 11, design: .monospaced))

                        Button(action: {
                            if let clip = NSPasteboard.general.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines), !clip.isEmpty {
                                LocalModelManager.shared.grokApiKey = clip
                                HapticFeedback.selection()
                            }
                        }) {
                            Text("Paste")
                                .font(.system(size: 10.5, weight: .medium))
                        }
                    }
                }
                .padding(.vertical, 4)

                Divider().opacity(0.35)

                // DeepSeek
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Image(systemName: "atom")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.cyan)
                        Text("DeepSeek API Key")
                            .font(.system(size: 11.5, weight: .semibold))
                        Spacer()
                        if !LocalModelManager.shared.deepseekApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text("Active ✓")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.green)
                        } else {
                            Text("Optional")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                    HStack(spacing: 6) {
                        TextField("sk-... (DeepSeek-V3 / DeepSeek-R1)", text: Binding(
                            get: { LocalModelManager.shared.deepseekApiKey },
                            set: { LocalModelManager.shared.deepseekApiKey = $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 11, design: .monospaced))

                        Button(action: {
                            if let clip = NSPasteboard.general.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines), !clip.isEmpty {
                                LocalModelManager.shared.deepseekApiKey = clip
                                HapticFeedback.selection()
                            }
                        }) {
                            Text("Paste")
                                .font(.system(size: 10.5, weight: .medium))
                        }
                    }
                }
                .padding(.vertical, 4)

                Divider().opacity(0.35)

                // Local Models Engine & Shutoff Control
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "desktopcomputer")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.teal)
                        Text("Local Models Engine (Ollama / LM Studio)")
                            .font(.system(size: 11.5, weight: .semibold))
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { LocalModelManager.shared.localModelsEnabled },
                            set: { enabled in
                                if enabled {
                                    LocalModelManager.shared.enableLocalModels()
                                } else {
                                    LocalModelManager.shared.shutoffLocalModels()
                                }
                            }
                        ))
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .controlSize(.mini)
                    }

                    HStack {
                        Text(LocalModelManager.shared.localModelsEnabled
                             ? (LocalModelManager.shared.isConnectedToLocalEngine ? "Running / Connected 🟢" : "Enabled (Waiting for engine) 🟡")
                             : "Shut Off / Disabled ⏻")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(LocalModelManager.shared.localModelsEnabled ? (LocalModelManager.shared.isConnectedToLocalEngine ? .green : .orange) : .secondary)

                        Spacer()

                        if LocalModelManager.shared.localModelsEnabled {
                            Button(action: {
                                LocalModelManager.shared.shutoffLocalModels()
                                HapticFeedback.heavy()
                            }) {
                                HStack(spacing: 3) {
                                    Image(systemName: "power")
                                    Text("Shut Off & Eject Models ⏻")
                                }
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.red.opacity(0.9))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(RoundedRectangle(cornerRadius: 4).fill(Color.red.opacity(0.12)))
                            }
                            .buttonStyle(.plain)
                        } else {
                            Button(action: {
                                LocalModelManager.shared.enableLocalModels()
                                HapticFeedback.selection()
                            }) {
                                HStack(spacing: 3) {
                                    Image(systemName: "bolt.fill")
                                    Text("Turn On Local Models ⚡️")
                                }
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.cyan)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(RoundedRectangle(cornerRadius: 4).fill(Color.cyan.opacity(0.15)))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if LocalModelManager.shared.localModelsEnabled {
                        TextField("http://localhost:11434", text: Binding(
                            get: { LocalModelManager.shared.ollamaHost },
                            set: { LocalModelManager.shared.ollamaHost = $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 11, design: .monospaced))
                    }
                }
                .padding(.vertical, 4)

                // Live thermal / CPU / memory telemetry with local model stop controls
                SystemStatsCardView()
                    .padding(.vertical, 4)

                Divider().opacity(0.35)

                // Terminal Tool Execution & Developer Access
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "terminal.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.green)
                        Text("Terminal Tool Access & Command Runner")
                            .font(.system(size: 11.5, weight: .semibold))
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { LocalModelManager.shared.terminalAccessEnabled },
                            set: { LocalModelManager.shared.terminalAccessEnabled = $0 }
                        ))
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .controlSize(.mini)
                    }

                    Text("Gives the AI model access to run shell commands, check files, test code, and use macOS developer tools.")
                        .font(.system(size: 9.5))
                        .foregroundColor(.secondary)

                    if LocalModelManager.shared.terminalAccessEnabled {
                        HStack {
                            Text("Auto-Execute Terminal Commands")
                                .font(.system(size: 10.5, weight: .medium))
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { LocalModelManager.shared.terminalAutoExecute },
                                set: { LocalModelManager.shared.terminalAutoExecute = $0 }
                            ))
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .controlSize(.mini)
                        }
                        .padding(.top, 2)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    // MARK: - Tab: Battery & Status Detail View (Apple System Inset Design)

    private var batteryDetailView: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Battery Indicator Section
            AppleSettingsSection("Battery Indicator") {
                // Style Picker
                AppleSettingsRow(title: "Indicator Style", icon: "battery.100", iconColor: .green) {
                    Picker("", selection: $iconStyle) {
                        ForEach(iconStyles, id: \.self) { style in
                            Text(style).tag(style)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 140)
                    .onChange(of: iconStyle) { _, newStyle in
                        UserDefaults.standard.set(newStyle, forKey: PrefKey.batteryStyle)
                        UserDefaults.standard.set(newStyle, forKey: PrefKey.iconStyle)
                        NotificationCenter.default.post(name: .init("NexusIconStyleChanged"), object: nil)
                    }
                }

                Divider().padding(.leading, 42).opacity(0.25)

                // Show Percentage
                AppleSettingsRow(title: "Show Percentage (%)", icon: "percent", iconColor: .teal) {
                    Toggle("", isOn: $showBatteryPercentage)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .controlSize(.small)
                        .onChange(of: showBatteryPercentage) { _, _ in
                            NotificationCenter.default.post(name: .init("NexusIconStyleChanged"), object: nil)
                        }
                }

                Divider().padding(.leading, 42).opacity(0.25)

                // Show Charging Bolt
                AppleSettingsRow(title: "Show Charging Bolt (⚡)", icon: "bolt.fill", iconColor: .yellow) {
                    Toggle("", isOn: $showChargingBolt)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .controlSize(.small)
                        .onChange(of: showChargingBolt) { _, _ in
                            NotificationCenter.default.post(name: .init("NexusIconStyleChanged"), object: nil)
                        }
                }

                Divider().padding(.leading, 42).opacity(0.25)

                // Color Palette Dots
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        HStack(spacing: 10) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 5.5, style: .continuous)
                                    .fill(Color.orange)
                                    .frame(width: 22, height: 22)
                                Image(systemName: "paintpalette.fill")
                                    .font(.system(size: 10.5, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            Text("Color Palette")
                                .font(.system(size: 11.5, weight: .regular))
                                .foregroundColor(.primary)
                        }
                        Spacer()
                        Text(batteryColorMode)
                            .font(.system(size: 10.5, weight: .medium))
                            .foregroundColor(.secondary)
                    }

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(batteryColorModes, id: \.self) { mode in
                                let isSelected = (batteryColorMode == mode)
                                Button(action: {
                                    HapticFeedback.selection()
                                    withAnimation(.spring(response: 0.22, dampingFraction: 0.75)) {
                                        batteryColorMode = mode
                                    }
                                    NotificationCenter.default.post(name: .init("NexusIconStyleChanged"), object: nil)
                                }) {
                                    Circle()
                                        .fill(colorGradientForMode(mode))
                                        .frame(width: 18, height: 18)
                                        .overlay(
                                            Circle()
                                                .stroke(isSelected ? Color.white : Color.clear, lineWidth: 2)
                                        )
                                        .shadow(color: isSelected ? Color.accentColor.opacity(0.6) : Color.clear, radius: 3)
                                }
                                .buttonStyle(.plain)
                                .help(mode)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
            }

            // 3. Status Emoji & Brand Icon ("pick their own emoji lol")
            AppleSettingsSection("Status Emoji & Brand Icon") {
                // Toggle Show Brand Glyph
                AppleSettingsRow(title: "Show Brand Glyph in Menu Bar", subtitle: "Icon shown next to battery", icon: "sparkles", iconColor: .purple) {
                    Toggle("", isOn: $iconEnabled)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .controlSize(.small)
                        .onChange(of: iconEnabled) { _, enabled in
                            UserDefaults.standard.set(enabled, forKey: PrefKey.iconEnabled)
                            NotificationCenter.default.post(name: .init("NexusIconStyleChanged"), object: nil)
                        }
                }

                if iconEnabled {
                    Divider().padding(.leading, 42).opacity(0.25)

                    // Quick Emoji Chips
                    VStack(alignment: .leading, spacing: 6) {
                        Text("CHOOSE AN EMOJI")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.secondary)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(["🪔", "🐶", "", "⚡️", "🔥", "💎", "✨", "💻", "☕️", "👑", "🦄", "🪐", "🕹️", "👾", "🍕", "🌈", "🍀"], id: \.self) { emoji in
                                    let isSelected = statusIconStyle.contains(emoji)
                                    Button(action: {
                                        HapticFeedback.selection()
                                        statusIconStyle = emoji
                                        BrandLogoManager.shared.setCustomEmoji(emoji)
                                    }) {
                                        Text(emoji)
                                            .font(.system(size: 16))
                                            .frame(width: 28, height: 28)
                                            .background(
                                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                                    .fill(isSelected ? Color.accentColor.opacity(0.25) : Color.primary.opacity(0.06))
                                            )
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                                    .strokeBorder(isSelected ? Color.accentColor : Color.white.opacity(0.08), lineWidth: isSelected ? 1.5 : 0.8)
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)

                    Divider().padding(.leading, 42).opacity(0.25)

                    // Pick Their Own Emoji (Custom Input Textfield)
                    HStack(spacing: 8) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 5.5, style: .continuous)
                                .fill(Color.indigo)
                                .frame(width: 22, height: 22)
                            Image(systemName: "face.smiling.fill")
                                .font(.system(size: 10.5, weight: .semibold))
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 1) {
                            Text("Custom Emoji")
                                .font(.system(size: 11.5))
                            Text("Type or paste any emoji")
                                .font(.system(size: 9.5))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        HStack(spacing: 6) {
                            TextField("e.g. 🦊", text: $customEmojiInput)
                                .textFieldStyle(.plain)
                                .font(.system(size: 12))
                                .frame(width: 55)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(RoundedRectangle(cornerRadius: 5, style: .continuous).fill(Color.primary.opacity(0.06)))
                                .overlay(RoundedRectangle(cornerRadius: 5, style: .continuous).strokeBorder(Color.white.opacity(0.12), lineWidth: 0.8))
                                .onSubmit {
                                    if !customEmojiInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        HapticFeedback.selection()
                                        statusIconStyle = customEmojiInput
                                        BrandLogoManager.shared.setCustomEmoji(customEmojiInput)
                                    }
                                }

                            Button(action: {
                                if !customEmojiInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                    HapticFeedback.selection()
                                    statusIconStyle = customEmojiInput
                                    BrandLogoManager.shared.setCustomEmoji(customEmojiInput)
                                }
                            }) {
                                Text("Set")
                                    .font(.system(size: 10, weight: .bold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3.5)
                                    .background(Capsule().fill(Color.accentColor))
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)

                    Divider().padding(.leading, 42).opacity(0.25)

                    // Photo Logo Upload
                    HStack(spacing: 10) {
                        Button(action: {
                            BrandLogoManager.shared.promptPictureUpload()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "photo.badge.plus")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.secondary)
                                Text("Upload Custom Image Logo...")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.primary)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundColor(.secondary.opacity(0.7))
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }



            // 5. Menu Bar Quick Folder Setting
            AppleSettingsSection("Menu Bar Quick Folder") {
                // Current Folder Row
                AppleSettingsRow(
                    title: "Folder Destination",
                    subtitle: barFolderDisplayPath,
                    icon: "folder.badge.gearshape",
                    iconColor: .blue
                ) {
                    Button(action: {
                        chooseCustomBarFolder()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "folder")
                                .font(.system(size: 10.5))
                            Text("Change...")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3.5)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(0.08)))
                    }
                    .buttonStyle(.plain)
                }

                Divider().padding(.leading, 42).opacity(0.25)

                // Preset Destinations
                VStack(alignment: .leading, spacing: 6) {
                    Text("QUICK PRESETS")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(barFolderPresets, id: \.name) { preset in
                                let isSelected = (barFolderPath == preset.path)
                                Button(action: {
                                    HapticFeedback.selection()
                                    barFolderPath = preset.path
                                    UserDefaults.standard.set(preset.path, forKey: PrefKey.barFolderPath)
                                    NotificationCenter.default.post(name: NSNotification.Name("NexusBarFolderChanged"), object: preset.path)
                                }) {
                                    HStack(spacing: 5) {
                                        Image(systemName: preset.icon)
                                            .font(.system(size: 10, weight: .medium))
                                        Text(preset.name)
                                            .font(.system(size: 10.5, weight: isSelected ? .semibold : .regular))
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .fill(isSelected ? Color.accentColor.opacity(0.22) : Color.primary.opacity(0.05))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                                            .strokeBorder(isSelected ? Color.accentColor : Color.white.opacity(0.08), lineWidth: 0.8)
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
            }
        }
    }

    private var barFolderDisplayPath: String {
        let path = barFolderPath
        let home = NSHomeDirectory()
        if path == home {
            return "~ (Home)"
        } else if path.hasPrefix(home) {
            return "~" + path.dropFirst(home.count)
        }
        return path
    }

    private var barFolderPresets: [(name: String, path: String, icon: String)] {
        let home = NSHomeDirectory()
        return [
            ("Desktop", home + "/Desktop", "sparkles.tv"),
            ("Downloads", home + "/Downloads", "arrow.down.circle"),
            ("Documents", home + "/Documents", "doc.text"),
            ("Home", home, "house"),
            ("Applications", "/Applications", "square.grid.2x2"),
            ("Developer", home + "/Developer", "chevron.left.forwardslash.chevron.right")
        ]
    }

    private func chooseCustomBarFolder() {
        let panel = NSOpenPanel()
        panel.title = "Choose Folder Destination"
        panel.message = "Select the folder to open from your Genie Mini Dock:"
        panel.prompt = "Set Folder"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.directoryURL = URL(fileURLWithPath: (barFolderPath as NSString).expandingTildeInPath)

        // Elevate window level so it floats OVER all menus, popovers, and status bar
        panel.level = NSWindow.Level(max(NSWindow.Level.statusBar.rawValue, NSWindow.Level.floating.rawValue) + 50)

        // Center and position down more on screen (comfortably below top panels/menu bars)
        let targetScreen = NSScreen.main ?? (NSScreen.screens.first ?? NSScreen())
        let visFrame = targetScreen.visibleFrame
        let panelW: CGFloat = 640
        let panelH: CGFloat = 460
        let posX = visFrame.midX - (panelW / 2)
        let posY = max(visFrame.minY + 50, visFrame.midY - (panelH / 2) - 80)
        panel.setFrame(NSRect(x: posX, y: posY, width: panelW, height: panelH), display: true)

        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)

        if panel.runModal() == .OK, let selectedURL = panel.url {
            barFolderPath = selectedURL.path
            UserDefaults.standard.set(selectedURL.path, forKey: PrefKey.barFolderPath)
            NotificationCenter.default.post(name: NSNotification.Name("NexusBarFolderChanged"), object: selectedURL.path)
        }
    }

    // MARK: - Privacy & Permissions Detail View

    private var privacyPermissionsDetailView: some View {
        VStack(alignment: .leading, spacing: 14) {
            // 1. Header Hero Card
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    Image(systemName: "hand.raised.fill")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.blue)
                    Text("Privacy & System Permissions")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.primary)
                }
                Text("Genie runs 100% locally on your Mac. All application detection, window management, and menu bar features operate strictly on-device with zero telemetry or background tracking.")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .lineSpacing(2)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.42))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 0.8)
            )

            // 2. Proactive Actions Card
            AppleSettingsSection("Permissions Setup") {
                AppleSettingsRow(
                    title: "Ask for All Permissions",
                    subtitle: "Triggers system prompts for all missing permissions",
                    icon: "checkmark.shield.fill",
                    iconColor: .blue
                ) {
                    Button(action: {
                        HapticFeedback.selection()
                        permissionsManager.requestAllPermissions()
                    }) {
                        Text("Request All")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4.5)
                            .background(Capsule().fill(Color.blue))
                    }
                    .buttonStyle(.plain)
                }

                Divider().padding(.leading, 42).opacity(0.25)

                AppleSettingsRow(
                    title: "Refresh Permissions Status",
                    subtitle: "Re-query authorization status from macOS",
                    icon: "arrow.clockwise",
                    iconColor: .indigo
                ) {
                    Button(action: {
                        HapticFeedback.selection()
                        permissionsManager.refreshAll()
                    }) {
                        Text("Check Now")
                            .font(.system(size: 11, weight: .medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4.5)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(0.08)))
                    }
                    .buttonStyle(.plain)
                }
            }

            // 3. Core Permissions Status
            AppleSettingsSection("System Permissions") {
                // Accessibility
                AppleSettingsRow(
                    title: "Accessibility Access",
                    subtitle: "Required for window snapping, app switching, and mouse actions",
                    icon: "figure.walk.circle.fill",
                    iconColor: .green
                ) {
                    if permissionsManager.isAccessibilityGranted {
                        permissionGrantedBadge
                    } else {
                        Button("Grant Access") {
                            permissionsManager.requestAccessibility()
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 3.5)
                        .background(Capsule().fill(Color.blue))
                    }
                }

                Divider().padding(.leading, 42).opacity(0.25)

                // Screen Recording
                AppleSettingsRow(
                    title: "Screen Recording",
                    subtitle: "Required for live preview, wallpaper mirror, and magnification",
                    icon: "record.circle.fill",
                    iconColor: .purple
                ) {
                    if permissionsManager.isScreenCaptureGranted {
                        permissionGrantedBadge
                    } else {
                        Button("Grant Access") {
                            permissionsManager.requestScreenCapture()
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 3.5)
                        .background(Capsule().fill(Color.blue))
                    }
                }

                Divider().padding(.leading, 42).opacity(0.25)

                // Files and Folders
                AppleSettingsRow(
                    title: "Files & Folders Access",
                    subtitle: "Required to display desktop files and open configured bar folders",
                    icon: "folder.fill",
                    iconColor: .orange
                ) {
                    if permissionsManager.isFullDiskGranted {
                        permissionGrantedBadge
                    } else {
                        Button("Open Settings") {
                            permissionsManager.requestFullDiskAccess()
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 3.5)
                        .background(Capsule().fill(Color.blue))
                    }
                }

                Divider().padding(.leading, 42).opacity(0.25)

                // Notifications
                AppleSettingsRow(
                    title: "System Notifications",
                    subtitle: "Enables battery alerts and charging status notifications",
                    icon: "bell.badge.fill",
                    iconColor: .red
                ) {
                    if permissionsManager.isNotificationsGranted {
                        permissionGrantedBadge
                    } else {
                        Button("Enable") {
                            permissionsManager.requestNotifications()
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 3.5)
                        .background(Capsule().fill(Color.blue))
                    }
                }
            }
        }
        .onAppear {
            permissionsManager.refreshAll()
        }
    }

    private var permissionGrantedBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: "checkmark")
                .font(.system(size: 9, weight: .bold))
            Text("Granted")
                .font(.system(size: 10.5, weight: .semibold))
        }
        .foregroundColor(.green)
        .padding(.horizontal, 8)
        .padding(.vertical, 3.5)
        .background(Capsule().fill(Color.green.opacity(0.12)))
    }

    // MARK: - Tab 9: VIP Expansion Packs Detail View

    private var expansionPacksDetailView: some View {
        VStack(alignment: .leading, spacing: 14) {
            subscriptionPlansHeaderSection

            Divider().opacity(0.3)

            // Header Banner
            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Image(systemName: "sparkles")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.yellow)
                    Text(LocalizedStrings.translateText("FEATURE PACKS & COMPANIONS", lang: appLanguage))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.yellow)
                    Spacer()
                }

                Text(LocalizedStrings.translateText("Included living companions, atmospheric shaders, 3D formations, and window themes.", lang: appLanguage))
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            // Available Expansion Packs Cards
            VStack(spacing: 12) {
                ForEach(storeManager.availablePacks) { pack in
                    expansionPackCard(pack: pack)
                }
            }
        }
    }

    private var subscriptionPlansHeaderSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "crown.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.orange)
                Text(LocalizedStrings.translateText("GENIE MEMBERSHIP & FOUNDER PASSES", lang: appLanguage))
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.orange)
                Spacer()
                Text("First Month Free on All Plans")
                    .font(.system(size: 9.5, weight: .semibold))
                    .foregroundColor(.green)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.green.opacity(0.15)))
            }

            VStack(spacing: 8) {
                ForEach(storeManager.subscriptionPlans) { plan in
                    let isSelected = storeManager.activePlanName == plan.name
                    Button(action: {
                        HapticFeedback.selection()
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            storeManager.selectPlan(plan)
                        }
                    }) {
                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(plan.name)
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(.white)
                                    if let badge = plan.badge {
                                        Text(badge)
                                            .font(.system(size: 8, weight: .heavy))
                                            .foregroundColor(plan.isPopular ? .orange : .cyan)
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 1.5)
                                            .background(Capsule().fill((plan.isPopular ? Color.orange : Color.cyan).opacity(0.2)))
                                    }
                                }

                                Text("\(plan.billingCadence) • \(plan.effectiveMonthlyRate)")
                                    .font(.system(size: 9.5))
                                    .foregroundColor(.white.opacity(0.65))

                                if let trial = plan.trialText {
                                    Text("🎁 \(trial)")
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundColor(.green)
                                }
                            }

                            Spacer()

                            VStack(alignment: .trailing, spacing: 2) {
                                Text(plan.priceDisplay)
                                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                                    .foregroundColor(isSelected ? .orange : .white)

                                if isSelected {
                                    Text("ACTIVE PLAN")
                                        .font(.system(size: 8, weight: .bold))
                                        .foregroundColor(.green)
                                } else {
                                    Text("Select")
                                        .font(.system(size: 9.5, weight: .semibold))
                                        .foregroundColor(.cyan)
                                }
                            }
                        }
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(isSelected ? Color.orange.opacity(0.12) : Color.white.opacity(0.04))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(isSelected ? Color.orange.opacity(0.7) : Color.white.opacity(0.1), lineWidth: isSelected ? 1.2 : 0.8)
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
    }

    @ViewBuilder
    private func expansionPackCard(pack: ExpansionPackItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(LinearGradient(colors: pack.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 32, height: 32)

                    Image(systemName: pack.icon)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(pack.title)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.primary)

                        Text(pack.badge)
                            .font(.system(size: 8, weight: .black))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(pack.gradient.first?.opacity(0.35) ?? Color.yellow.opacity(0.35)))
                            .foregroundColor(pack.gradient.first ?? .yellow)
                    }

                    Text(pack.subtitle)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Spacer()
            }

            // Included items list (Clickable to equip individual items!)
            VStack(alignment: .leading, spacing: 4) {
                ForEach(pack.includes, id: \.self) { inc in
                    includedItemEquipRow(inc)
                }
            }
            .padding(.vertical, 2)

            // Action Buttons
            HStack {
                // Active status pill
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 11, weight: .bold))
                    Text(LocalizedStrings.translateText("UNLOCKED", lang: appLanguage))
                        .font(.system(size: 9.5, weight: .bold))
                }
                .foregroundColor(.green)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.green.opacity(0.14)))

                Spacer()

                equipButton(for: pack)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.primary.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.green.opacity(0.35), lineWidth: 1)
                )
        )
    }

    private func includedItemEquipRow(_ inc: String) -> some View {
        Button(action: {
            storeManager.applyIncludedItem(inc)
            HapticFeedback.selection()
            if inc.hasPrefix("Companion: ") {
                ambientEntity = String(inc.dropFirst("Companion: ".count))
            } else if inc.hasPrefix("Shader: ") {
                wallpaperFxType = String(inc.dropFirst("Shader: ".count))
                wallpaperFxEnabled = true
                windowShaderFxEnabled = true
            } else if inc.hasPrefix("Formation: ") {
                appFormation = String(inc.dropFirst("Formation: ".count))
            } else if inc.hasPrefix("Snuggie: ") || inc.hasPrefix("Apparel: ") {
                iconSnuggie = String(inc.dropFirst(inc.hasPrefix("Snuggie: ") ? "Snuggie: ".count : "Apparel: ".count))
            } else if inc.hasPrefix("Style: ") {
                batteryStyle = "8-Bit Arcade"
            }
        }) {
            HStack(spacing: 5) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.accentColor)
                Text(inc)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
                Text("Equip")
                    .font(.system(size: 8, weight: .semibold))
                    .foregroundColor(.accentColor.opacity(0.8))
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Capsule().fill(Color.accentColor.opacity(0.1)))
            }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func equipButton(for pack: ExpansionPackItem) -> some View {
        let isEquipped: Bool = storeManager.isPackEquipped(pack.id)
        let primaryColor: Color = pack.gradient.first ?? Color.cyan
        Button(action: { equipPackAction(pack) }) {
            HStack(spacing: 5) {
                Image(systemName: isEquipped ? "checkmark.circle.fill" : "wand.and.stars")
                    .font(.system(size: 11, weight: .bold))
                Text(isEquipped ? LocalizedStrings.translateText("EQUIPPED ✓", lang: appLanguage) : LocalizedStrings.translateText("EQUIP PACK", lang: appLanguage))
                    .font(.system(size: 10.5, weight: .bold))
            }
            .foregroundColor(isEquipped ? Color.white : primaryColor)
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(isEquipped ? Color.green : primaryColor.opacity(0.18))
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(isEquipped ? Color.green : primaryColor.opacity(0.6), lineWidth: 1.2)
            )
        }
        .buttonStyle(.plain)
    }

    private func equipPackAction(_ pack: ExpansionPackItem) {
        storeManager.applyPack(pack)
        HapticFeedback.success()
        switch pack.id {
        case ExpansionStoreManager.cyberpunkID, ExpansionStoreManager.legacyCyberpunkID:
            ambientEntity = "Cyber Alpha Wolf 🐺"
            wallpaperFxType = "4K Tokyo Neon Night Rain 🌧️"
            wallpaperFxEnabled = true
            windowShaderFxEnabled = true
            appFormation = "Tesseract Hypercube 🧊"
            iconSnuggie = "Cyber Samurai Mask 🥷"
            statusIconStyle = "Cyber Bolt ⚡️"
            studioTheme = "Midnight Cyberpunk"
            appIconTintColor = "Neon Cyan"
        case ExpansionStoreManager.zenID, ExpansionStoreManager.legacyZenID:
            ambientEntity = "Cherry Blossom 9-Tail Kitsune 🦊"
            wallpaperFxType = "Sakura Petal Blizzard 🌸"
            wallpaperFxEnabled = true
            windowShaderFxEnabled = true
            appFormation = "Zen Garden Yin-Yang ☯️"
            iconSnuggie = "Sakura Shinto Gate ⛩️"
            statusIconStyle = "Green Leaf 🍃"
            appIconTintColor = "Sakura Pink"
        case ExpansionStoreManager.cosmosID, ExpansionStoreManager.legacyCosmosID:
            ambientEntity = "Cosmic Star Whale 🐋"
            wallpaperFxType = "Supermassive Black Hole Lens 🕳️"
            wallpaperFxEnabled = true
            windowShaderFxEnabled = true
            appFormation = "Supernova Burst 💥"
            iconSnuggie = "Astronaut Visor 👨‍🚀"
            statusIconStyle = "Cosmic Planet 🪐"
            appIconTintColor = "Amethyst"
        case ExpansionStoreManager.retroID, ExpansionStoreManager.legacyRetroID:
            ambientEntity = "8-Bit Arcade Ghost 👻"
            wallpaperFxType = "Retro CRT Vector Scanline Grid 🕹️"
            wallpaperFxEnabled = true
            windowShaderFxEnabled = true
            iconSnuggie = "Pixel Heart Armor ❤️"
            batteryStyle = "8-Bit Arcade"
            statusIconStyle = "Arcade Gamepad 🎮"
            appIconTintColor = "Emerald"
        case ExpansionStoreManager.ultimateID, ExpansionStoreManager.legacyUltimateID:
            ambientEntity = "Genie Portal 🌀"
            wallpaperFxType = "Fluid Ink Chromatography 🎨"
            wallpaperFxEnabled = true
            windowShaderFxEnabled = true
            appFormation = "Tesseract Hypercube 🧊"
            iconSnuggie = "Crown Jewel 👑"
            batteryStyle = "Tesla Cell Pack"
            statusIconStyle = "Crown Jewel 👑"
            appIconTintColor = "Royal Gold"
        default:
            break
        }
    }

    // MARK: - Tab 10: Preferences Detail View

    private var preferencesDetailView: some View {
        VStack(alignment: .leading, spacing: 14) {
            // 1. Language & Region (people can select language first)
            AppleSettingsSection("Language & Region") {
                AppleSettingsRow(title: "Language", subtitle: "Select your preferred display language", icon: "globe", iconColor: .blue) {
                    Picker("", selection: $appLanguage) {
                        ForEach(AppLanguage.allCases) { lang in
                            Text("\(lang.flag)  \(lang.rawValue)").tag(lang.rawValue)
                        }
                    }
                    .labelsHidden()
                    .frame(maxWidth: 160)
                    .onChange(of: appLanguage) { _, newLang in
                        HapticFeedback.selection()
                        UserDefaults.standard.set(newLang, forKey: PrefKey.appLanguage)
                    }
                }

                AppleSettingsRow(
                    title: "Keyboard Layout Detection",
                    subtitle: "Active: \(GenieLanguageInputDetector.shared.activeKeyboardLayoutName)",
                    icon: "keyboard",
                    iconColor: .purple
                ) {
                    Toggle("", isOn: Binding(
                        get: { GenieLanguageInputDetector.shared.autoDetectFromKeyboard },
                        set: { GenieLanguageInputDetector.shared.autoDetectFromKeyboard = $0 }
                    ))
                    .labelsHidden()
                    .toggleStyle(.switch)
                }

                AppleSettingsRow(
                    title: "Input Language Detection",
                    subtitle: "Auto-detect Korean, Japanese & other languages as you type",
                    icon: "text.magnifyingglass",
                    iconColor: .green
                ) {
                    Toggle("", isOn: Binding(
                        get: { GenieLanguageInputDetector.shared.autoDetectFromInput },
                        set: { GenieLanguageInputDetector.shared.autoDetectFromInput = $0 }
                    ))
                    .labelsHidden()
                    .toggleStyle(.switch)
                }
            }

            // 2. Genie Intelligence & Bring Your Own Keys (BYOK)
            AppleSettingsSection("Bring Your Own API Keys (Gemini, Claude, OpenAI)") {
                // Google Gemini
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Image(systemName: "sparkles")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.blue)
                        Text("Google Gemini API Key")
                            .font(.system(size: 11.5, weight: .semibold))
                        Spacer()
                        if !LocalModelManager.shared.geminiApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text("Active ✓")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.green)
                        } else {
                            Text("Optional")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                    HStack(spacing: 6) {
                        TextField("AQ.... or AIzaSy... (Gemini 2.5 Pro / Flash)", text: Binding(
                            get: { LocalModelManager.shared.geminiApiKey },
                            set: { LocalModelManager.shared.geminiApiKey = $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 11, design: .monospaced))

                        Button(action: {
                            if let clip = NSPasteboard.general.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines), !clip.isEmpty {
                                LocalModelManager.shared.geminiApiKey = clip
                                HapticFeedback.selection()
                            }
                        }) {
                            Text("Paste")
                                .font(.system(size: 10.5, weight: .medium))
                        }
                    }

                }
                .padding(.vertical, 4)

                Divider().opacity(0.35)

                // Anthropic Claude
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.orange)
                        Text("Anthropic Claude API Key")
                            .font(.system(size: 11.5, weight: .semibold))
                        Spacer()
                        if !LocalModelManager.shared.claudeApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text("Active ✓")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.green)
                        } else {
                            Text("Optional")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                    HStack(spacing: 6) {
                        TextField("sk-ant-... (Claude 3.7 / 3.5 Sonnet)", text: Binding(
                            get: { LocalModelManager.shared.claudeApiKey },
                            set: { LocalModelManager.shared.claudeApiKey = $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 11, design: .monospaced))

                        Button(action: {
                            if let clip = NSPasteboard.general.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines), !clip.isEmpty {
                                LocalModelManager.shared.claudeApiKey = clip
                                HapticFeedback.selection()
                            }
                        }) {
                            Text("Paste")
                                .font(.system(size: 10.5, weight: .medium))
                        }
                    }
                }
                .padding(.vertical, 4)

                Divider().opacity(0.35)

                // OpenAI
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Image(systemName: "cpu")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.green)
                        Text("OpenAI API Key")
                            .font(.system(size: 11.5, weight: .semibold))
                        Spacer()
                        if !LocalModelManager.shared.openaiApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text("Active ✓")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.green)
                        } else {
                            Text("Optional")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                    HStack(spacing: 6) {
                        TextField("sk-proj-... (GPT-4o, o3-mini, o1)", text: Binding(
                            get: { LocalModelManager.shared.openaiApiKey },
                            set: { LocalModelManager.shared.openaiApiKey = $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 11, design: .monospaced))

                        Button(action: {
                            if let clip = NSPasteboard.general.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines), !clip.isEmpty {
                                LocalModelManager.shared.openaiApiKey = clip
                                HapticFeedback.selection()
                            }
                        }) {
                            Text("Paste")
                                .font(.system(size: 10.5, weight: .medium))
                        }
                    }
                }
                .padding(.vertical, 4)

                Divider().opacity(0.35)

                // xAI Grok
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Image(systemName: "bolt.shield.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.purple)
                        Text("xAI Grok API Key")
                            .font(.system(size: 11.5, weight: .semibold))
                        Spacer()
                        if !LocalModelManager.shared.grokApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text("Active ✓")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.green)
                        } else {
                            Text("Optional")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                    HStack(spacing: 6) {
                        TextField("xai-... (Grok 2 / Grok 2 Vision)", text: Binding(
                            get: { LocalModelManager.shared.grokApiKey },
                            set: { LocalModelManager.shared.grokApiKey = $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 11, design: .monospaced))

                        Button(action: {
                            if let clip = NSPasteboard.general.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines), !clip.isEmpty {
                                LocalModelManager.shared.grokApiKey = clip
                                HapticFeedback.selection()
                            }
                        }) {
                            Text("Paste")
                                .font(.system(size: 10.5, weight: .medium))
                        }
                    }
                }
                .padding(.vertical, 4)

                Divider().opacity(0.35)

                // DeepSeek
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Image(systemName: "atom")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.cyan)
                        Text("DeepSeek API Key")
                            .font(.system(size: 11.5, weight: .semibold))
                        Spacer()
                        if !LocalModelManager.shared.deepseekApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            Text("Active ✓")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.green)
                        } else {
                            Text("Optional")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                    HStack(spacing: 6) {
                        TextField("sk-... (DeepSeek-V3 / DeepSeek-R1)", text: Binding(
                            get: { LocalModelManager.shared.deepseekApiKey },
                            set: { LocalModelManager.shared.deepseekApiKey = $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 11, design: .monospaced))

                        Button(action: {
                            if let clip = NSPasteboard.general.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines), !clip.isEmpty {
                                LocalModelManager.shared.deepseekApiKey = clip
                                HapticFeedback.selection()
                            }
                        }) {
                            Text("Paste")
                                .font(.system(size: 10.5, weight: .medium))
                        }
                    }
                }
                .padding(.vertical, 4)

                Divider().opacity(0.35)

                // Local Models Engine & Shutoff Control
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "desktopcomputer")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.teal)
                        Text("Local Models Engine (Ollama / LM Studio)")
                            .font(.system(size: 11.5, weight: .semibold))
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { LocalModelManager.shared.localModelsEnabled },
                            set: { enabled in
                                if enabled {
                                    LocalModelManager.shared.enableLocalModels()
                                } else {
                                    LocalModelManager.shared.shutoffLocalModels()
                                }
                            }
                        ))
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .controlSize(.mini)
                    }

                    HStack {
                        Text(LocalModelManager.shared.localModelsEnabled
                             ? (LocalModelManager.shared.isConnectedToLocalEngine ? "Running / Connected 🟢" : "Enabled (Waiting for engine) 🟡")
                             : "Shut Off / Disabled ⏻")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(LocalModelManager.shared.localModelsEnabled ? (LocalModelManager.shared.isConnectedToLocalEngine ? .green : .orange) : .secondary)

                        Spacer()

                        if LocalModelManager.shared.localModelsEnabled {
                            Button(action: {
                                LocalModelManager.shared.shutoffLocalModels()
                                HapticFeedback.heavy()
                            }) {
                                HStack(spacing: 3) {
                                    Image(systemName: "power")
                                    Text("Shut Off & Eject Models ⏻")
                                }
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.red.opacity(0.9))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(RoundedRectangle(cornerRadius: 4).fill(Color.red.opacity(0.12)))
                            }
                            .buttonStyle(.plain)
                        } else {
                            Button(action: {
                                LocalModelManager.shared.enableLocalModels()
                                HapticFeedback.selection()
                            }) {
                                HStack(spacing: 3) {
                                    Image(systemName: "bolt.fill")
                                    Text("Turn On Local Models ⚡️")
                                }
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.cyan)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(RoundedRectangle(cornerRadius: 4).fill(Color.cyan.opacity(0.15)))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if LocalModelManager.shared.localModelsEnabled {
                        TextField("http://localhost:11434", text: Binding(
                            get: { LocalModelManager.shared.ollamaHost },
                            set: { LocalModelManager.shared.ollamaHost = $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .font(.system(size: 11, design: .monospaced))
                    }
                }
                .padding(.vertical, 4)

                // Live thermal / CPU / memory telemetry with local model stop controls
                SystemStatsCardView()
                    .padding(.vertical, 4)

                Divider().opacity(0.35)

                // Terminal Tool Execution & Developer Access
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "terminal.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.green)
                        Text("Terminal Tool Access & Command Runner")
                            .font(.system(size: 11.5, weight: .semibold))
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { LocalModelManager.shared.terminalAccessEnabled },
                            set: { LocalModelManager.shared.terminalAccessEnabled = $0 }
                        ))
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .controlSize(.mini)
                    }

                    Text("Gives the AI model access to run shell commands, check files, test code, and use macOS developer tools.")
                        .font(.system(size: 9.5))
                        .foregroundColor(.secondary)

                    if LocalModelManager.shared.terminalAccessEnabled {
                        HStack {
                            Text("Auto-Execute Terminal Commands")
                                .font(.system(size: 10.5, weight: .medium))
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { LocalModelManager.shared.terminalAutoExecute },
                                set: { LocalModelManager.shared.terminalAutoExecute = $0 }
                            ))
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .controlSize(.mini)
                        }
                        .padding(.top, 2)
                    }
                }
                .padding(.vertical, 4)
            }

            HStack {
                Text(LocalizedStrings.translateText("Sound Effects & Audio Clicks", lang: appLanguage))
                    .font(.system(size: 12))
                Spacer()
                Toggle("", isOn: $soundEnabled)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.small)
            }

            Divider().opacity(0.4)

            HStack {
                Text(LocalizedStrings.translateText("Trackpad Haptic Pulses", lang: appLanguage))
                    .font(.system(size: 12))
                Spacer()
                Toggle("", isOn: $hapticsEnabled)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.small)
            }

            Divider().opacity(0.4)

            HStack {
                Text(LocalizedStrings.translateText("Hover Magnification", lang: appLanguage))
                    .font(.system(size: 12))
                Spacer()
                Toggle("", isOn: $enableMagnification)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.small)
            }

            if enableMagnification {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(LocalizedStrings.translateText("Magnification Scale", lang: appLanguage))
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(String(format: "%.2fx", maxMagnification))
                            .font(.system(size: 11).monospacedDigit())
                            .foregroundColor(.secondary)
                    }
                    Slider(value: $maxMagnification, in: 1.15...1.60, step: 0.03)
                        .controlSize(.small)
                }
            }

            Divider().opacity(0.4)

            // MARK: - Dock Animation, Dance to Music & Liquid Glass
            dockAnimationSettingsSection

            Divider().opacity(0.4)

            // MARK: - Appearance & Studio Theme Section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: isStudioLight ? "sun.max.fill" : "moon.stars.fill")
                        .font(.system(size: 11))
                        .foregroundColor(isStudioLight ? .orange : .indigo)
                    Text(LocalizedStrings.translateText("APPEARANCE & STUDIO THEME", lang: appLanguage))
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(studioTheme)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.accentColor)
                }

                HStack(spacing: 8) {
                    // System Auto
                    Button(action: {
                        HapticFeedback.selection()
                        withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
                            studioTheme = "System (Auto)"
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "circle.righthalf.filled")
                                .font(.system(size: 10))
                            Text(LocalizedStrings.translateText("System", lang: appLanguage))
                                .font(.system(size: 11, weight: studioTheme == "System (Auto)" ? .bold : .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5.5)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(studioTheme == "System (Auto)" ? Color.accentColor.opacity(0.16) : Color.primary.opacity(0.04))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(studioTheme == "System (Auto)" ? Color.accentColor : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)

                    // Light Mode
                    Button(action: {
                        HapticFeedback.selection()
                        withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
                            studioTheme = "macOS Light"
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "sun.max.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.orange)
                            Text(LocalizedStrings.translateText("Light", lang: appLanguage))
                                .font(.system(size: 11, weight: studioTheme == "macOS Light" ? .bold : .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5.5)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(studioTheme == "macOS Light" ? Color.orange.opacity(0.16) : Color.primary.opacity(0.04))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(studioTheme == "macOS Light" ? Color.orange : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)

                    // Dark Mode
                    Button(action: {
                        HapticFeedback.selection()
                        withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
                            studioTheme = "macOS Dark"
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "moon.stars.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.indigo)
                            Text(LocalizedStrings.translateText("Dark", lang: appLanguage))
                                .font(.system(size: 11, weight: studioTheme == "macOS Dark" ? .bold : .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 5.5)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(studioTheme == "macOS Dark" ? Color.indigo.opacity(0.16) : Color.primary.opacity(0.04))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(studioTheme == "macOS Dark" ? Color.indigo : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider().opacity(0.4)

            // MARK: - iPhone Setup Style Language Selector
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "globe")
                        .font(.system(size: 11))
                        .foregroundColor(.blue)
                    Text(LocalizedStrings.translateText("LANGUAGE & REGION", lang: appLanguage))
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(appLanguage)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.blue)
                }

                VStack(spacing: 4) {
                    ForEach([
                        ("English (US)", "Hello", "🇺🇸"),
                        ("Español", "Hola", "🇪🇸"),
                        ("Français", "Bonjour", "🇫🇷"),
                        ("Deutsch", "Hallo", "🇩🇪"),
                        ("日本語", "こんにちは", "🇯🇵"),
                        ("简体中文", "你好", "🇨🇳"),
                        ("Italiano", "Ciao", "🇮🇹"),
                        ("한국어", "안녕하세요", "🇰🇷"),
                        ("Português", "Olá", "🇧🇷"),
                        ("العربية", "مرحبا", "🇸🇦")
                    ], id: \.0) { lang, greeting, flag in
                        let isSelected = appLanguage == lang
                        Button(action: {
                            HapticFeedback.selection()
                            withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
                                appLanguage = lang
                            }
                        }) {
                            HStack(spacing: 8) {
                                Text(flag)
                                    .font(.system(size: 14))

                                Text(lang)
                                    .font(.system(size: 11.5, weight: isSelected ? .bold : .regular))
                                    .foregroundColor(isSelected ? .blue : .primary)

                                Spacer()

                                Text(greeting)
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)

                                if isSelected {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(isSelected ? Color.blue.opacity(0.12) : Color.primary.opacity(0.03))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Divider().opacity(0.4)

            // MARK: - Dock & Desktop Integration Section
            VStack(alignment: .leading, spacing: 8) {
                Text(LocalizedStrings.translateText("DOCK & DESKTOP INTEGRATION", lang: appLanguage))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)

                // 1. Keep in Dock Toggle
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(LocalizedStrings.translateText("Keep Genie in macOS Dock", lang: appLanguage))
                            .font(.system(size: 12, weight: .medium))
                            .lineLimit(1)
                        Text(LocalizedStrings.translateText("Show active icon in the Dock and allow pinning to your system Dock", lang: appLanguage))
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { DockAndDesktopManager.shared.isDockIconEnabled },
                        set: { isEnabled in
                            HapticFeedback.selection()
                            if isEnabled {
                                DockAndDesktopManager.shared.pinToMacOSDock()
                            } else {
                                DockAndDesktopManager.shared.removeFromMacOSDock()
                            }
                        }
                    ))
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.small)
                }

                // 2. Dock Action Buttons
                HStack(spacing: 8) {
                    Button(action: {
                        HapticFeedback.selection()
                        DockAndDesktopManager.shared.pinToMacOSDock()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "dock.rectangle")
                                .font(.system(size: 10))
                            Text(LocalizedStrings.translateText("Pin to macOS Dock", lang: appLanguage))
                                .font(.system(size: 10.5, weight: .semibold))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.accentColor.opacity(0.12)))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.accentColor.opacity(0.25), lineWidth: 0.8))
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        HapticFeedback.tick()
                        DockAndDesktopManager.shared.removeFromMacOSDock()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "xmark.circle")
                                .font(.system(size: 10))
                            Text(LocalizedStrings.translateText("Remove from Dock", lang: appLanguage))
                                .font(.system(size: 10.5, weight: .semibold))
                        }
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(0.06)))
                    }
                    .buttonStyle(.plain)
                }

                // 3. Desktop & Home Folder Icon Creation
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(LocalizedStrings.translateText("Desktop & Home Folder Shortcuts", lang: appLanguage))
                            .font(.system(size: 12, weight: .medium))
                        Text(LocalizedStrings.translateText("Places a direct application icon on your Desktop and in your Home folder (~/)", lang: appLanguage))
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button(action: {
                        HapticFeedback.selection()
                        DockAndDesktopManager.shared.createDesktopAndHomeShortcuts()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "desktopcomputer")
                                .font(.system(size: 10))
                            Text(LocalizedStrings.translateText("Add Desktop & Home Icon", lang: appLanguage))
                                .font(.system(size: 10.5, weight: .semibold))
                        }
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.green.opacity(0.12)))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.green.opacity(0.25), lineWidth: 0.8))
                    }
                    .buttonStyle(.plain)
                }

                // 4. Show / Hide Desktop Files (Finder icons)
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(LocalizedStrings.translateText("Show Files on Desktop", lang: appLanguage))
                            .font(.system(size: 12, weight: .medium))
                        Text(LocalizedStrings.translateText("Toggles all Finder icons on your desktop via com.apple.finder CreateDesktop", lang: appLanguage))
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { desktopFilesManager.areDesktopFilesVisible },
                        set: { visible in
                            HapticFeedback.selection()
                            desktopFilesManager.setDesktopFilesVisible(visible)
                        }
                    ))
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.small)
                }
            }
            .padding(.vertical, 4)

            Divider().opacity(0.4)

            HStack {
                Text(LocalizedStrings.translateText("Free Window Positioning", lang: appLanguage))
                    .font(.system(size: 12))
                Spacer()
                Toggle("", isOn: $popoverFreePositionEnabled)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .onChange(of: popoverFreePositionEnabled) { _, newValue in
                        NotificationCenter.default.post(name: .init("NexusPopoverUnlockChanged"), object: newValue)
                    }
            }

            if popoverFreePositionEnabled {
                HStack {
                    Spacer()
                    Button(action: {
                        NotificationCenter.default.post(name: .init("NexusResetPopoverPosition"), object: nil)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 10))
                            Text(LocalizedStrings.translateText("Reset Window Position", lang: appLanguage))
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
            }

            Divider().opacity(0.4)

            HStack {
                Text(LocalizedStrings.translateText("App Layout Order", lang: appLanguage))
                    .font(.system(size: 12))
                Spacer()
                Button(action: {
                    HapticFeedback.selection()
                    appModel.resetAppOrder()
                }) {
                    Text(LocalizedStrings.translateText("Reset Order", lang: appLanguage))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Bottom Global Footer

    private var bottomGlobalFooter: some View {
        VStack(spacing: 5) {
            // Launch at Login toggle
            HStack(spacing: 5) {
                Image(systemName: loginItemManager.isEnabled ? "sunrise.fill" : "sunrise")
                    .font(.system(size: 9.5))
                    .foregroundColor(loginItemManager.isEnabled ? .orange : .secondary)
                Text(LocalizedStrings.launchAtLogin(lang: appLanguage))
                    .font(.system(size: 10.5))
                    .foregroundColor(.primary)
                Spacer()
                Toggle("", isOn: Binding(
                    get: { loginItemManager.isEnabled },
                    set: { val in
                        HapticFeedback.selection()
                        loginItemManager.setEnabled(val)
                    }
                ))
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.mini)
            }

            Divider().opacity(0.3)

            HStack {
                Button(action: {
                    HapticFeedback.selection()
                    NotificationCenter.default.post(name: NSNotification.Name("NexusRefreshApps"), object: nil)
                    onRefreshApps?()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 9.5))
                        Text(LocalizedStrings.refreshApps(lang: appLanguage))
                            .font(.system(size: 11))
                    }
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: {
                    HapticFeedback.heavy()
                    onQuitApp?()
                    NSApp.terminate(nil)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "power")
                            .font(.system(size: 9.5))
                        Text(LocalizedStrings.quitGenie(lang: appLanguage))
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.red.opacity(0.85))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Helpers

    private func tintColorDisplay(_ name: String) -> Color {
        switch name {
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

    private func clearHiddenApps() {
        UserDefaults.standard.removeObject(forKey: PrefKey.hiddenAppIDs)
        hiddenAppsRevision += 1
        appModel.objectWillChange.send()
    }


    private func askResetToDefaultConfirmation() {
        HapticFeedback.selection()
        withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
            showResetConfirmOverlay = true
        }
    }

    private func restoreCleanDefaults() {
        HapticFeedback.heavy()
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            desktopPlaneEnabled = true
            appFormation = "Responsive Grid"
            appIconTheme = "Default"
            iconSize = 64.0
            itemSpacing = 24.0
            showAppNames = true
            textSize = 12.0
            enableMagnification = false
            dockAnimationStyleRaw = "None"
            danceToMusicEnabled = false
            genieAnimEnabled = false
            smokeEffectsEnabled = false
            windowGraphicsEnabled = false
            windowShaderFxEnabled = false
            appPhysicsSimulation = "None"
            maxMagnification = 1.45
            ambientEntity = "None"
            wallpaperFxEnabled = false
            wallpaperFxType = "None"
            cursorFxType = "None"
            pinballModeEnabled = false
            soundEnabled = true
            hapticsEnabled = true
            soundVolume = 0.85
            soundProfile = "Apple Modern"
            iconStyle = "Apple Minimal"
            showBatteryPercentage = true
            batteryColorMode = "Dynamic Level"
            barFolderPath = AppDefaultsManager.defaultBarFolderPath
        }
            wallpaperMode = "Genie"
            sameWallpaperMode = true
            wallpaperTreatment = "Exact Mirror (1:1)"
            wallpaperMatchingStyle = "Exact Mirror (1:1)"
        WallpaperSampler.shared.refresh()
        NotificationCenter.default.post(name: NSNotification.Name("NexusDesktopPlaneToggled"), object: nil)
        NotificationCenter.default.post(name: NSNotification.Name("NexusSettingsChanged"), object: nil)
    }

    private func installKeyMonitorIfNeeded() {
        guard keyMonitor == nil else { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // If user is editing in a text field, pass keys through normally
            if let firstResponder = NSApp.keyWindow?.firstResponder,
               firstResponder is NSText || firstResponder is NSTextView || firstResponder is NSTextField {
                return event
            }

            if event.keyCode == 53 { // ESC
                NotificationCenter.default.post(name: NSNotification.Name("NexusClose"), object: nil)
                return nil
            }

            if event.keyCode == 125 { // Down Arrow
                selectNextTab()
                return nil
            } else if event.keyCode == 126 { // Up Arrow
                selectPreviousTab()
                return nil
            }

            return event
        }
    }
}



// MARK: - Authentic Apple macOS Traffic Lights Control 🚦

struct AppleTrafficLightsControl: View {
    @AppStorage(PrefKey.appLanguage) var appLanguage: String = "English (US)"
var onClose: () -> Void
    @State private var isHovered: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            // Close Button (Red)
            Button(action: {
                HapticFeedback.selection()
                onClose()
            }) {
                ZStack {
                    Circle()
                        .fill(Color(red: 255/255, green: 95/255, blue: 86/255))
                        .overlay(Circle().stroke(Color(red: 224/255, green: 68/255, blue: 62/255), lineWidth: 0.5))

                    Image(systemName: "xmark")
                        .font(.system(size: 6.5, weight: .black))
                        .foregroundColor(Color(red: 77/255, green: 0/255, blue: 0/255).opacity(0.85))
                        .opacity(isHovered ? 1.0 : 0.0)
                }
                .frame(width: 12, height: 12)
            }
            .buttonStyle(.plain)
            .help("Close Window")

            // Minimize Button (Yellow)
            Button(action: {
                HapticFeedback.selection()
                onClose()
            }) {
                ZStack {
                    Circle()
                        .fill(Color(red: 255/255, green: 189/255, blue: 46/255))
                        .overlay(Circle().stroke(Color(red: 222/255, green: 161/255, blue: 35/255), lineWidth: 0.5))

                    Image(systemName: "minus")
                        .font(.system(size: 7.5, weight: .black))
                        .foregroundColor(Color(red: 153/255, green: 87/255, blue: 0/255).opacity(0.85))
                        .opacity(isHovered ? 1.0 : 0.0)
                }
                .frame(width: 12, height: 12)
            }
            .buttonStyle(.plain)
            .help("Minimize Window")

            // Zoom / Window Size Button (Green)
            Button(action: {
                HapticFeedback.selection()
                let current = UserDefaults.standard.string(forKey: PrefKey.windowSizeMode) ?? "normal"
                let next: String
                switch current {
                case "normal": next = "half"
                case "half": next = "fullscreen"
                default: next = "normal"
                }
                UserDefaults.standard.set(next, forKey: PrefKey.windowSizeMode)
                UserDefaults.standard.set(false, forKey: PrefKey.menuCompactMode)
                NotificationCenter.default.post(name: NSNotification.Name("NexusWindowSizeModeChanged"), object: next)
            }) {
                ZStack {
                    Circle()
                        .fill(Color(red: 39/255, green: 201/255, blue: 63/255))
                        .overlay(Circle().stroke(Color(red: 26/255, green: 171/255, blue: 41/255), lineWidth: 0.5))

                    Image(systemName: "plus")
                        .font(.system(size: 7.0, weight: .black))
                        .foregroundColor(Color(red: 0/255, green: 100/255, blue: 0/255).opacity(0.85))
                        .opacity(isHovered ? 1.0 : 0.0)
                }
                .frame(width: 12, height: 12)
            }
            .buttonStyle(.plain)
            .help("Zoom / Resize Window (Normal -> Half -> Fullscreen)")
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.12)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Light / Dark Mode Header Button ☀️/🌙

struct LightDarkModeButton: View {
@Binding var studioTheme: String
    var isStudioLight: Bool
    var appLanguage: String = "English (US)"

    private var isAuto: Bool {
        studioTheme == "System (Auto)"
    }

    private func toggleSystemAppearance(dark: Bool?) {
        // nil = System Auto, true = Dark, false = Light
        if let dark = dark {
            NSApp.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
        } else {
            NSApp.appearance = nil  // follow system
        }

        // System Events owns the appearance setting. Sending the Apple Event
        // in-process via NSAppleScript keeps this working in both builds —
        // `com.apple.systemevents` is entitled in each profile — where spawning
        // /usr/bin/osascript is not reachable under the sandbox. The
        // `defaults write -globalDomain` that followed is dropped: System
        // Events already persists the change, and writing another app's domain
        // is not permitted to a sandboxed app.
        guard let dark else {
            // System Auto: clear the AppleInterfaceStyle override in the global
            // domain. `CFPreferencesSetAppValue(_, nil, _)` removes the key,
            // which is exactly what `defaults delete -globalDomain` did.
            guard GenieCapabilities.canModifySystemPreferenceDomains else { return }
            CFPreferencesSetAppValue(
                "AppleInterfaceStyle" as CFString,
                nil,
                kCFPreferencesAnyApplication
            )
            CFPreferencesAppSynchronize(kCFPreferencesAnyApplication)
            return
        }
        let source = "tell application \"System Events\" to tell appearance preferences to set dark mode to \(dark)"
        DispatchQueue.main.async {
            guard let script = NSAppleScript(source: source) else { return }
            var errorInfo: NSDictionary?
            script.executeAndReturnError(&errorInfo)
        }
    }

    var body: some View {
        Button(action: {
            HapticFeedback.selection()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                if studioTheme == "System (Auto)" {
                    studioTheme = "macOS Light"
                    toggleSystemAppearance(dark: false)
                } else if studioTheme == "macOS Light" || studioTheme == "VS Code Light+" || studioTheme == "Solarized Light" {
                    studioTheme = "macOS Dark"
                    toggleSystemAppearance(dark: true)
                } else {
                    studioTheme = "System (Auto)"
                    toggleSystemAppearance(dark: nil)
                }
            }
        }) {
            HStack(spacing: 4) {
                Image(systemName: isAuto ? "circle.righthalf.filled" : (isStudioLight ? "sun.max.fill" : "moon.stars.fill"))
                    .font(.system(size: 9.5, weight: .bold))
                    .foregroundColor(isAuto ? .teal : (isStudioLight ? .orange : Color(red: 0.0, green: 0.88, blue: 1.0)))

                Text(isAuto ? "Auto" : (isStudioLight ? LocalizedStrings.lightMode(lang: appLanguage) : LocalizedStrings.darkMode(lang: appLanguage)))
                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                    .foregroundColor(isAuto ? .teal : (isStudioLight ? .orange : Color(red: 0.0, green: 0.88, blue: 1.0)))
            }
            .padding(.horizontal, 7)
            .frame(height: 24)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isAuto ? Color.teal.opacity(0.14) : (isStudioLight ? Color.orange.opacity(0.14) : Color.cyan.opacity(0.14)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(
                        isAuto ? Color.teal.opacity(0.35) : (isStudioLight ? Color.orange.opacity(0.35) : Color.cyan.opacity(0.35)),
                        lineWidth: 0.6
                    )
            )
        }
        .buttonStyle(.plain)
        .help("Theme: \(studioTheme). Click to cycle Auto → Light → Dark.")
        .contextMenu {
            Button(LocalizedStrings.translateText("System (Auto) 💻", lang: appLanguage)) {
                HapticFeedback.selection()
                studioTheme = "System (Auto)"
                toggleSystemAppearance(dark: nil)
            }
            Divider()
            Button(LocalizedStrings.translateText("macOS Light ☀️", lang: appLanguage)) {
                HapticFeedback.selection()
                studioTheme = "macOS Light"
                toggleSystemAppearance(dark: false)
            }
            Button(LocalizedStrings.translateText("macOS Dark 🌙", lang: appLanguage)) {
                HapticFeedback.selection()
                studioTheme = "macOS Dark"
                toggleSystemAppearance(dark: true)
            }
            Divider()
            Button(LocalizedStrings.translateText("VS Code Light+ 💡", lang: appLanguage)) {
                HapticFeedback.selection()
                studioTheme = "VS Code Light+"
            }
            Button(LocalizedStrings.translateText("VS Code Dark+ 💻", lang: appLanguage)) {
                HapticFeedback.selection()
                studioTheme = "VS Code Dark+"
            }
            Button(LocalizedStrings.translateText("Solarized Light 🌅", lang: appLanguage)) {
                HapticFeedback.selection()
                studioTheme = "Solarized Light"
            }
        }
    }
}

// MARK: - Unabbreviated Top Language Selector Menu 🌐

struct TopLanguageSelectorMenu: View {
    @Binding var appLanguage: String

    private var currentLanguage: AppLanguage {
        AppLanguage.allCases.first(where: { $0.rawValue == appLanguage }) ?? .english
    }

    var body: some View {
        Menu {
            ForEach(AppLanguage.allCases) { lang in
                Button(action: {
                    HapticFeedback.selection()
                    withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
                        appLanguage = lang.rawValue
                        UserDefaults.standard.set(lang.rawValue, forKey: PrefKey.appLanguage)
                    }
                }) {
                    HStack {
                        Text("\(lang.flag) \(lang.rawValue)")
                        if appLanguage == lang.rawValue {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 5) {
                Text(currentLanguage.flag)
                    .font(.system(size: 11))
                Text(currentLanguage.rawValue)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.primary.opacity(0.88))
                    .lineLimit(1)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 7, weight: .semibold))
                    .foregroundColor(.secondary.opacity(0.7))
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 3.5)
            .background(
                RoundedRectangle(cornerRadius: 5.5, style: .continuous)
                    .fill(Color.primary.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 5.5, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.12), lineWidth: 0.6)
            )
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .help("Language: \(currentLanguage.rawValue) (Click to switch)")
    }
}


// MARK: - Sidebar Tab Item Button View

struct SidebarTabItemView: View {
    let tab: DropdownSidebarTab
    let isSelected: Bool
    var appLanguage: String = "English (US)"
    var badgeText: String? = nil
    let onSelect: () -> Void
    @State private var isHovered: Bool = false

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 8) {
                // Colored icon badge with inner highlight
                ZStack {
                    RoundedRectangle(cornerRadius: 5.5, style: .continuous)
                        .fill(tab.tintColor)
                        .frame(width: 22, height: 22)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5.5, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.20), lineWidth: 0.8)
                        )
                    Image(systemName: tab.icon)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                }

                if let image = NSImage(named: tab.rawValue) {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height: 14)
                } else {
                    Text(LocalizedStrings.tabTitle(tab.rawValue, lang: appLanguage))
                        .font(.system(size: 11.5, weight: isSelected ? .semibold : .medium))
                        .foregroundColor(isSelected ? .white : .primary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                if let badge = badgeText {
                    Text(badge)
                        .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                        .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1.5)
                        .background(Capsule().fill(isSelected ? Color.white.opacity(0.25) : Color.primary.opacity(0.08)))
                }
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 5.5)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 7.5, style: .continuous)
                    .fill(
                        isSelected
                            ? Color(red: 0.0, green: 0.48, blue: 1.0)
                            : (isHovered ? Color.primary.opacity(0.06) : Color.clear)
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.20, dampingFraction: 0.78), value: isSelected)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.10)) { isHovered = hovering }
        }
    }
}

// MARK: - Reusable Sub-Category Filter Pill Bar

struct FilterPillBar: View {
    @AppStorage(PrefKey.appLanguage) var appLanguage: String = "English (US)"
let categories: [String]
    @Binding var selectedCategory: String
    var tintColor: Color = .accentColor

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(categories, id: \.self) { cat in
                    let isSelected = selectedCategory == cat
                    Button(action: {
                        HapticFeedback.selection()
                        withAnimation(.spring(response: 0.22, dampingFraction: 0.75)) {
                            selectedCategory = cat
                        }
                    }) {
                        Text(cat)
                            .font(.system(size: 10.5, weight: isSelected ? .bold : .medium))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .foregroundColor(isSelected ? .white : .primary)
                            .background(
                                Capsule()
                                    .fill(isSelected ? tintColor : Color(nsColor: .controlColor).opacity(0.45))
                            )
                            .overlay(
                                Capsule()
                                    .stroke(isSelected ? tintColor : Color.primary.opacity(0.08), lineWidth: 0.8)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
        .frame(maxWidth: .infinity)
    }
}




// MARK: - Dock Animation Settings Section
extension MenuBarDropdownView {
    private var selectedDockAnimationStyle: DockAnimationStyle {
        DockAnimationStyle(preferenceValue: dockAnimationStyleRaw)
    }

    @ViewBuilder
    var dockAnimationSettingsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "dock.rectangle")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.cyan)
                Text(LocalizedStrings.translateText("DOCK ANIMATION", lang: appLanguage))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)
                Spacer()
                if musicMonitor.isMusicPlaying {
                    HStack(spacing: 4) {
                        Image(systemName: "waveform")
                            .symbolEffect(.variableColor.iterative, options: .repeating)
                        Text(LocalizedStrings.translateText("Music detected", lang: appLanguage))
                    }
                    .font(.system(size: 9.5, weight: .semibold))
                    .foregroundColor(.pink)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.pink.opacity(0.14)))
                } else {
                    Text(selectedDockAnimationStyle.rawValue)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.accentColor)
                }
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(DockAnimationStyle.allCases) { style in
                    let isSelected = selectedDockAnimationStyle == style
                    Button(action: {
                        HapticFeedback.selection()
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.70)) {
                            dockAnimationStyleRaw = style.rawValue
                        }
                    }) {
                        HStack(spacing: 7) {
                            Image(systemName: style.symbolName)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(isSelected ? .cyan : .secondary)
                                .frame(width: 16)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(LocalizedStrings.translateText(style.rawValue, lang: appLanguage))
                                    .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                                    .foregroundColor(isSelected ? .cyan : .primary)
                                    .lineLimit(1)
                                Text(LocalizedStrings.translateText(style.subtitle, lang: appLanguage))
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer(minLength: 0)
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.cyan)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .genieLiquidGlass(cornerRadius: 9, tint: isSelected ? Color.cyan.opacity(0.25) : nil, interactive: true)
                        .overlay(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .stroke(isSelected ? Color.cyan : Color.primary.opacity(0.06), lineWidth: isSelected ? 1.5 : 0.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(LocalizedStrings.translateText("Animation Intensity", lang: appLanguage))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "%.0f%%", dockAnimationIntensity * 100))
                        .font(.system(size: 11).monospacedDigit())
                        .foregroundColor(.secondary)
                }
                Slider(value: $dockAnimationIntensity, in: 0.0...1.0, step: 0.05)
                    .controlSize(.small)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(LocalizedStrings.translateText("Dock Transparency", lang: appLanguage))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "%.0f%%", dockBackgroundOpacity * 100))
                        .font(.system(size: 11).monospacedDigit())
                        .foregroundColor(.secondary)
                }
                Slider(value: $dockBackgroundOpacity, in: 0.10...0.95, step: 0.05)
                    .controlSize(.small)
            }

            HStack {
                Image(systemName: "music.note.list")
                    .font(.system(size: 10))
                    .foregroundColor(.pink)
                VStack(alignment: .leading, spacing: 1) {
                    Text(LocalizedStrings.translateText("Apps dance when music is playing", lang: appLanguage))
                        .font(.system(size: 12))
                    Text(LocalizedStrings.translateText("Detects playback on", lang: appLanguage) + " " + musicMonitor.outputDeviceName)
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Toggle("", isOn: $danceToMusicEnabled)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.small)
            }

            HStack {
                Image(systemName: "drop.halffull")
                    .font(.system(size: 10))
                    .foregroundColor(.cyan)
                VStack(alignment: .leading, spacing: 1) {
                    Text(LocalizedStrings.translateText("Apple Liquid Glass ✨", lang: appLanguage))
                        .font(.system(size: 12))
                    Text(LocalizedStrings.translateText(LiquidGlassSettings.isNativelySupported ? "Native refractive glass on every panel and dock" : "Glass-style material (native Liquid Glass needs macOS 26+)", lang: appLanguage))
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
                Spacer()
                Toggle("", isOn: $liquidGlassEnabled)
                    .labelsHidden()
                    .toggleStyle(.switch)
                    .controlSize(.small)
            }
        }
    }
}
