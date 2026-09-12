import AppKit
import SwiftUI

// MARK: - Menu Bar Width Preference Key
public struct StripWidthPreferenceKey: PreferenceKey {
    public static var defaultValue: CGFloat = 80
    public static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Menu Bar App Strip View
// Renders directly on the real system menu bar:
// [ 🐶 Leo Glyph ]  [ ── Running App Switcher Strip ── ]  [ 🔋 Battery ]
public struct MenuBarAppStripView: View {
    @AppStorage(PrefKey.appLanguage) var appLanguage: String = "English (US)"
@ObservedObject var batteryMonitor = BatteryMonitor.shared
    @ObservedObject var gridManager = SmartGridManager.shared
    @ObservedObject var desktopsManager = MacDesktopsManager.shared
    @ObservedObject var desktopFilesManager = DesktopFilesManager.shared
    @ObservedObject var trashMonitor = TrashMonitor.shared
    @ObservedObject var localModels = LocalModelManager.shared

    @AppStorage(PrefKey.batteryEnabled) var batteryEnabled: Bool = true
    @AppStorage(PrefKey.batteryStyle) var batteryStyle: String = "Classic Apple Battery"
    @AppStorage(PrefKey.batteryColorMode) var batteryColorMode: String = "Dynamic Level"
    @AppStorage(PrefKey.showBatteryPercentage) var showBatteryPercentage: Bool = true
    @AppStorage(PrefKey.isVelcroDetached) var isVelcroDetached: Bool = false
    @AppStorage(PrefKey.smokeEffectsEnabled) var smokeEffectsEnabled: Bool = false
    @AppStorage(PrefKey.smokeStyle) var smokeStyle: String = "Mystical Cyan 🧞‍♂️"
    @AppStorage(PrefKey.statusIconGlyph) var statusIconGlyph: String = "Genie Person 🧞‍♂️"
    @AppStorage(PrefKey.statusIconStyle) var statusIconStyle: String = "Genie Person 🧞‍♂️"
    @AppStorage(PrefKey.menuBarAppSwitcherEnabled) var menuBarAppSwitcherEnabled: Bool = true
    @AppStorage(PrefKey.miniDockDisplayMode) var miniDockDisplayMode: String = "Always Hidden" // "Always Shown", "Always Hidden", "Auto-Hide"
    private var isHiddenMode: Bool {
        miniDockDisplayMode == "Always Hidden" || miniDockDisplayMode == "Auto-Hide"
    }
    @AppStorage(PrefKey.dockActiveAppsOnly) var dockActiveAppsOnly: Bool = false
    @AppStorage(PrefKey.menuBarDockInactiveAppsOnly) var menuBarDockInactiveAppsOnly: Bool = true
    @AppStorage(PrefKey.miniDockBackgroundStyle) var miniDockBackgroundStyle: String = "Clear (Transparent)"
    @AppStorage(PrefKey.menuBarAppleColor) var appleColor: String = "Retro Rainbow 🌈"
    @AppStorage(PrefKey.showAppleLogoOnStrip) var showAppleLogoOnStrip: Bool = true
    @AppStorage(PrefKey.menuBarTextColor) var textColorName: String = "Pure White ⚪️"
    @AppStorage(PrefKey.menuBarActiveAppColor) var activeAppColorName: String = "Pure White ⚪️"
    @AppStorage(PrefKey.menuBarColorsEnabled) var menuBarColorsEnabled: Bool = false
    @AppStorage(PrefKey.menuBarFontFamily) var fontFamily: String = "SF Pro (Apple Default)"
    @AppStorage(PrefKey.menuBarFontWeight) var fontWeight: String = "Regular"
    @AppStorage(PrefKey.menuBarFontSize) var menuBarFontSize: Double = 15.0
    @AppStorage(PrefKey.folderStacksRetracted) var folderStacksRetracted: Bool = false
    @AppStorage(PrefKey.dockShowFolderStacks) var dockShowFolderStacks: Bool = true
    @AppStorage(PrefKey.barFolderPath) var barFolderPath: String = AppDefaultsManager.defaultBarFolderPath
    @AppStorage(PrefKey.finderColor) var finderColor: String = "Classic Blue 🔵"
    @AppStorage(PrefKey.finderIconStyle) var finderIconStyle: String = "Finder Face (Default)"

    @AppStorage(PrefKey.menuBarAppCount) var menuBarAppCount: Int = 3
    @AppStorage(PrefKey.gridTransitionDirection) var gridTransitionDirection: String = "Slide from Right (iPhone Mode 📱)"
    @AppStorage(PrefKey.showChargingBolt) var showChargingBolt: Bool = true
    @AppStorage(PrefKey.showMiniDesktopsInMenuBar) var showMiniDesktopsInMenuBar: Bool = true
    @AppStorage(PrefKey.menuBarAppsPlacement) var appsPlacement: String = "Right Side (Classic Dock)"
    @AppStorage(PrefKey.dockAlwaysShowFinder) var dockAlwaysShowFinder: Bool = true
    @AppStorage(PrefKey.dockAlwaysShowSettings) var dockAlwaysShowSettings: Bool = true
    @AppStorage(PrefKey.dockAlwaysShowTrash) var dockAlwaysShowTrash: Bool = true
    @AppStorage(PrefKey.dockAlwaysShowGenie) var dockAlwaysShowGenie: Bool = true

    @ObservedObject var dockManager = DockAndDesktopManager.shared
    private var dockItems: [DockAppItem] {
        dockManager.dockItems
    }
    private var activePid: pid_t {
        dockManager.activePid
    }
    @State private var animPhase: CGFloat = 0.0

    @State private var hoveredItemId: String? = nil
    @State private var bouncingItemId: String? = nil
    @State private var smokingItemId: String? = nil

    @State private var hoveredPid: pid_t? = nil
    @State private var bouncingPid: pid_t? = nil
    @State private var smokingPid: pid_t? = nil
    @State private var isStripHovered: Bool = false
    @State private var isTriggerHovered: Bool = false
    @State private var dismissTimer: Timer? = nil
    @State private var isFinderHovered: Bool = false
    @State private var isTrashHovered: Bool = false
    @State private var isLeoHovered: Bool = false
    @State private var isChatHovered: Bool = false
    @State private var isEditorHovered: Bool = false
    @State private var isSettingsHovered: Bool = false
    @State private var isChevronHovered: Bool = false
    @State private var isBatteryHovered: Bool = false
    @State private var isCloudHovered: Bool = false
    @State private var isSwitcherHovered: Bool = false
    @State private var isNearScreenEdge: Bool = false
    @AppStorage(PrefKey.dockAnimationStyle) var dockAnimationStyleRaw: String = "None"
    @AppStorage(PrefKey.dockAnimationIntensity) var dockAnimationIntensity: Double = 0.7
    @AppStorage(PrefKey.danceToMusicEnabled) var danceToMusicEnabled: Bool = false
    @ObservedObject private var musicMonitor: MusicPlaybackMonitor = .shared
    @ObservedObject private var dispatcher = MenuBarActionDispatcher.shared
    @AppStorage("genieZenModeEnabled") private var isZenModeEnabled: Bool = false
    @State private var showPutBackPopover: Bool = false
    @State private var showMoreAppsPopover: Bool = false
    @State private var draggingItemId: String? = nil
    @State private var dragOffset: CGFloat = 0.0
    @State private var dragYOffset: CGFloat = 0.0
    @State private var isDragOffThreshold: Bool = false
    @State private var hoverDebounceTimer: Timer? = nil


    private var displayApps: [NSRunningApplication] {
        dockItems.compactMap { $0.runningApp }
    }

    private var activeDockItems: [DockAppItem] {
        var seenPids = Set<pid_t>()
        var seenBundleIds = Set<String>()
        var result: [DockAppItem] = []
        let currentActivePid = dockManager.activePid > 0 ? dockManager.activePid : (NSWorkspace.shared.frontmostApplication?.processIdentifier ?? 0)

        for item in dockItems {
            if menuBarDockInactiveAppsOnly {
                // Inactive applications only: must be running, but NOT the active (frontmost) app!
                guard item.isRunning, let app = item.runningApp, !app.isTerminated else { continue }
                let isFrontmost = (item.processIdentifier == currentActivePid || app.processIdentifier == currentActivePid || app.isActive)
                if isFrontmost { continue }

                // Exclude Genie itself from the inactive app switcher (Genie is anchored via genieLauncherButton)
                let lowerBid = (item.bundleIdentifier ?? "").lowercased()
                let lowerName = item.name.lowercased()
                if lowerBid.contains("com.nicholasdudek.genie") || lowerName == "genie" {
                    continue
                }
            } else if dockActiveAppsOnly && !item.isRunning {
                continue
            }
            let lowerName = item.name.lowercased()
            let lowerBid = (item.bundleIdentifier ?? "").lowercased()
            let lowerId = item.id.lowercased()

            // Strict duplicate Trash filter (dedicated trashItemView is rendered separately)
            if lowerName == "trash" || lowerName == "bin" || lowerName == "corbeille" || lowerBid.contains("trash") || lowerId == "trash" || lowerId.contains("trash") {
                continue
            }

            // Merge duplicate Settings icons: macOS System Settings is merged into the dedicated Genie Settings pill
            if lowerBid.contains("com.apple.systempreferences") || lowerName == "system settings" || lowerName == "system preferences" || lowerId.contains("systempreferences") {
                continue
            }

            // Filter out items user closed or hid from the pill dock
            if dockManager.isItemHidden(id: item.id) || dockManager.isItemHidden(id: item.bundleIdentifier ?? "") {
                continue
            }
            if let pid = item.runningApp?.processIdentifier, pid > 0 {
                if seenPids.contains(pid) { continue }
                seenPids.insert(pid)
            }
            if let bid = item.bundleIdentifier, !bid.isEmpty {
                if seenBundleIds.contains(bid.lowercased()) { continue }
                seenBundleIds.insert(bid.lowercased())
            }
            result.append(item)
        }

        let screenW = NSScreen.main?.visibleFrame.width ?? 1920.0
        let maxAllowedApps = max(16, min(64, Int((screenW - 200.0) / 20.0)))
        return Array(result.prefix(maxAllowedApps))
    }

    private var visibleDockItems: [DockAppItem] {
        if isZenModeEnabled || activeDockItems.count > 6 {
            return Array(activeDockItems.prefix(5))
        }
        return activeDockItems
    }

    private var overflowDockItems: [DockAppItem] {
        if isZenModeEnabled || activeDockItems.count > 6 {
            return Array(activeDockItems.dropFirst(5))
        }
        return []
    }

    private var isSystemMagnificationEnabled: Bool {
        if let val = UserDefaults(suiteName: "com.apple.dock")?.object(forKey: "magnification") as? Bool {
            return val
        }
        return true
    }

    private var magnificationScale: CGFloat {
        let largeSize = CGFloat(UserDefaults(suiteName: "com.apple.dock")?.double(forKey: "largesize") ?? 96.0)
        let tileSize = max(16.0, CGFloat(UserDefaults(suiteName: "com.apple.dock")?.double(forKey: "tilesize") ?? 48.0))
        let ratio = largeSize / tileSize
        return max(1.45, min(1.80, 1.0 + (ratio - 1.0) * 0.80))
    }

    private var allDockIds: [String] {
        var ids = activeDockItems.map { $0.id }
        if !menuBarDockInactiveAppsOnly {
            if dockShowFolderStacks {
                ids.append(contentsOf: dockManager.dockFolders.map { "folder_\($0.id)" })
            }
            if dockAlwaysShowTrash { ids.append("trash") }
            ids.append("pill_chat")
            ids.append("pill_settings")
        }
        return ids
    }

    private func magnificationWave(for itemId: String) -> (scale: CGFloat, yOffset: CGFloat, zIndex: Double) {
        guard isSystemMagnificationEnabled else {
            return (1.0, 0.0, 1.0)
        }
        guard let myIdx = allDockIds.firstIndex(of: itemId) else {
            return (1.0, 0.0, 1.0)
        }
        let hoveredIdx = hoveredItemId.flatMap { allDockIds.firstIndex(of: $0) }
        let t = DockAnimationEngine.transform(
            style: DockAnimationStyle(preferenceValue: dockAnimationStyleRaw),
            index: myIdx,
            hoveredIndex: hoveredIdx,
            time: Date().timeIntervalSinceReferenceDate,
            intensity: dockAnimationIntensity,
            isMusicPlaying: musicMonitor.isMusicPlaying,
            danceToMusic: danceToMusicEnabled,
            anchorDown: true
        )

        // The menu bar is only ~22pt tall, so the engine's full-size dock motion is scaled down
        // here — anything larger visibly clips against the menu bar's bounds.
        let scale = 1.0 + (t.scale - 1.0) * 0.30
        let yOffset = t.offset.height * 0.25
        let distance = hoveredIdx.map { abs($0 - myIdx) } ?? Int.max
        let zIndex: Double = distance == 0 ? 100.0 : (distance == 1 ? 60.0 : (distance == 2 ? 30.0 : 1.0))
        return (max(0.9, min(1.14, scale)), yOffset, zIndex)
    }

    private func magnificationDisplacement(for itemId: String) -> CGFloat {
        return 0.0
    }


    private func handleItemHover(id: String, hovering: Bool) {
        if hovering {
            hoverDebounceTimer?.invalidate()
            hoverDebounceTimer = nil
            withAnimation(.spring(response: 0.18, dampingFraction: 0.75)) {
                hoveredItemId = id
            }
        } else if hoveredItemId == id {
            hoverDebounceTimer?.invalidate()
            hoverDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.06, repeats: false) { _ in
                Task { @MainActor in
                    withAnimation(.spring(response: 0.20, dampingFraction: 0.75)) {
                        if hoveredItemId == id {
                            hoveredItemId = nil
                        }
                    }
                }
            }
        }
    }

    private var notchFillerGapWidth: CGFloat {
        // The right dock cluster is now placed in the right auxiliary section of the menu bar.
        // The central Spacer() in CustomMenuBarView naturally bridges across the camera notch,
        // so no internal gap is needed inside the dock strip. This ensures Date & Time never clips.
        return 0
    }

    private func shouldShowNotchGap(before item: DockAppItem) -> Bool {
        return false
    }

    // Loads all persistent apps from the user's macOS Dock in EXACT order (including Apple apps, loaded or unloaded)
    static func loadSystemDockApps() -> [DockAppItem] {
        var items: [DockAppItem] = []
        let fm = FileManager.default

        // 1. Check permanent dock plist (com.apple.dock.plist)
        let dockDict: [[String: Any]]? = {
            if let apps = UserDefaults(suiteName: "com.apple.dock")?.array(forKey: "persistent-apps") as? [[String: Any]] {
                return apps
            }
            if let dict = NSDictionary(contentsOf: URL(fileURLWithPath: NSHomeDirectory() + "/Library/Preferences/com.apple.dock.plist")),
               let apps = dict["persistent-apps"] as? [[String: Any]] {
                return apps
            }
            return nil
        }()

        if let dockEntries = dockDict {
            for entry in dockEntries {
                guard let tileData = entry["tile-data"] as? [String: Any] else { continue }
                let bundleId = (tileData["bundle-identifier"] as? String) ?? ""
                let label = (tileData["file-label"] as? String) ?? (bundleId.isEmpty ? "App" : bundleId)

                // Skip Genie itself from appearing inside its own mini-dock strip
                if bundleId == "com.nicholasdudek.genie" || label.lowercased() == "genie" {
                    continue
                }
                // Skip Trash and Finder as they are dedicated items
                if bundleId.contains("trash") || label.lowercased() == "trash" || label.lowercased() == "bin" {
                    continue
                }
                if bundleId.contains("finder") || label.lowercased() == "finder" {
                    continue
                }

                var bundleURL: URL? = nil
                if let fileData = tileData["file-data"] as? [String: Any],
                   let urlString = fileData["_CFURLString"] as? String {
                    bundleURL = URL(string: urlString)
                }
                if bundleURL == nil && !bundleId.isEmpty {
                    bundleURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId)
                }

                let icon: NSImage? = {
                    if let path = bundleURL?.path, fm.fileExists(atPath: path) {
                        return NSWorkspace.shared.icon(forFile: path)
                    }
                    if !bundleId.isEmpty, let u = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
                        return NSWorkspace.shared.icon(forFile: u.path)
                    }
                    return nil
                }()

                let id = bundleId.isEmpty ? label : bundleId
                let newItem = DockAppItem(
                    id: id,
                    name: label,
                    bundleURL: bundleURL,
                    bundleIdentifier: bundleId.isEmpty ? nil : bundleId,
                    icon: icon,
                    runningApp: nil
                )
                if !items.contains(where: { $0.representsSameApplication(as: newItem) }) {
                    items.append(newItem)
                }
            }
        }

        return items
    }

    public init() {}

    private var activeGlyph: String {
        let style = statusIconGlyph.isEmpty ? statusIconStyle : statusIconGlyph
        if !style.isEmpty && !style.contains("") && !style.lowercased().contains("apple") {
            return style
        }
        return "Genie Person 🧞‍♂️"
    }

    private var glyphImage: NSImage {
        StatusIconRenderer.generateGlyphImage(glyph: activeGlyph, size: 18, phase: animPhase)
    }

    private var isDigitalNumberOnlyStyle: Bool {
        [
            "Digital Clock 7-Segment",
            "Retro LCD Matrix Clock",
            "Cyber Neon Digits",
            "Nixie Tube Digits",
            "Bold Minimal Digital",
            "Digital LED Dot Matrix",
            "VisionOS Digital Pill",
            "Text Only (% Only)"
        ].contains(effectiveBatteryStyle)
    }

    private var percentageColor: Color {
        let pct = batteryMonitor.batteryPct ?? 100
        let isCharging = batteryMonitor.isCharging

        switch batteryColorMode {
        case "Neon Cyan", "Deep Ocean":
            return Color(red: 0.0, green: 0.90, blue: 1.0)
        case "Pure White", "Monochrome White":
            return textColorName != "Pure White ⚪️" ? MenuBarThemeManager.resolveColor(textColorName) : Color.white
        case "Emerald Green", "Apple Green":
            return Color(red: 0.20, green: 0.95, blue: 0.45)
        case "Solar Orange", "Solar Flare":
            return Color(red: 1.0, green: 0.60, blue: 0.15)
        case "Cyber Pink", "Cyber Neon":
            return Color(red: 1.0, green: 0.25, blue: 0.75)
        case "Electric Violet":
            return Color(red: 0.82, green: 0.45, blue: 1.0)
        case "Monochrome Dim":
            return (textColorName != "Pure White ⚪️" ? MenuBarThemeManager.resolveColor(textColorName) : Color.white).opacity(0.65)
        default: // "Dynamic Level"
            if textColorName != "Pure White ⚪️" {
                return MenuBarThemeManager.resolveColor(textColorName)
            }
            if isCharging {
                return Color(red: 0.25, green: 0.95, blue: 0.50)
            }
            if pct > 45 {
                return Color(red: 0.25, green: 0.92, blue: 0.45)
            } else if pct > 20 {
                return Color(red: 1.0, green: 0.78, blue: 0.20)
            } else {
                return Color(red: 1.0, green: 0.30, blue: 0.30)
            }
        }
    }

    private var genieBatteryColor: Color {
        let pct = batteryMonitor.batteryPct ?? 100
        let isCharging = batteryMonitor.isCharging
        if isCharging {
            return Color(red: 0.20, green: 0.95, blue: 0.45) // Charging Emerald Green
        }
        if pct > 60 {
            return Color(red: 0.0, green: 0.90, blue: 1.0)  // Full / Normal Cyan
        } else if pct > 25 {
            return Color(red: 1.0, green: 0.75, blue: 0.20) // Medium Amber Gold
        } else {
            return Color(red: 1.0, green: 0.30, blue: 0.30) // Low Battery Crimson Red
        }
    }

    private var batteryImage: NSImage? {
        _ = batteryStyle
        _ = batteryColorMode
        return StatusIconRenderer.generateBatteryImage(phase: animPhase, showPct: false)
    }

    private var effectiveBatteryStyle: String {
        batteryStyle
    }

    @ViewBuilder
    private var miniDockBackground: some View {
        let isHovered = isStripHovered || isBatteryHovered
        switch miniDockBackgroundStyle {
        case "Clear (Transparent)", "Clear", "Transparent":
            Capsule()
                .fill(isHovered ? Color.white.opacity(0.12) : Color.clear)
                .overlay(
                    Capsule()
                        .strokeBorder(isHovered ? Color.white.opacity(0.20) : Color.clear, lineWidth: 0.5)
                )

        case "Dark Obsidian Glass", "Dark Translucent", "Obsidian":
            ZStack {
                Capsule()
                    .fill(Color.black.opacity(isHovered ? 0.50 : 0.35))
                LinearGradient(
                    colors: [Color.white.opacity(isHovered ? 0.20 : 0.09), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .clipShape(Capsule())
            }
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(isHovered ? 0.40 : 0.20), Color.white.opacity(0.06)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.65
                    )
            )
            .shadow(color: Color.black.opacity(0.35), radius: isHovered ? 4.0 : 2.0, y: 1.0)

        case "Cosmic Aurora", "Neon Aurora Glass", "Neon Tint":
            ZStack {
                Capsule()
                    .fill(Color(red: 0.05, green: 0.08, blue: 0.18).opacity(isHovered ? 0.65 : 0.45))
                LinearGradient(
                    colors: [
                        Color.cyan.opacity(isHovered ? 0.40 : 0.25),
                        Color.purple.opacity(isHovered ? 0.30 : 0.18),
                        Color.pink.opacity(isHovered ? 0.20 : 0.10)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(Capsule())
            }
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.cyan.opacity(isHovered ? 0.85 : 0.55),
                                Color.purple.opacity(isHovered ? 0.70 : 0.40),
                                Color.pink.opacity(isHovered ? 0.50 : 0.25)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.85
                    )
            )
            .shadow(color: Color.cyan.opacity(isHovered ? 0.55 : 0.25), radius: isHovered ? 6.0 : 3.0, y: 1.0)

        case "Liquid Gold & Champagne", "Liquid Gold", "Gold":
            ZStack {
                Capsule()
                    .fill(Color(red: 0.15, green: 0.10, blue: 0.04).opacity(isHovered ? 0.60 : 0.40))
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.84, blue: 0.0).opacity(isHovered ? 0.40 : 0.22),
                        Color(red: 0.85, green: 0.65, blue: 0.13).opacity(isHovered ? 0.25 : 0.14),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(Capsule())
            }
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.90, blue: 0.45).opacity(isHovered ? 0.90 : 0.60),
                                Color(red: 0.85, green: 0.65, blue: 0.13).opacity(isHovered ? 0.60 : 0.35)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.85
                    )
            )
            .shadow(color: Color(red: 1.0, green: 0.84, blue: 0.0).opacity(isHovered ? 0.45 : 0.20), radius: isHovered ? 6.0 : 2.5, y: 1.0)

        case "Emerald Rainforest", "Emerald Glass", "Emerald":
            ZStack {
                Capsule()
                    .fill(Color(red: 0.02, green: 0.12, blue: 0.06).opacity(isHovered ? 0.60 : 0.40))
                LinearGradient(
                    colors: [
                        Color(red: 0.0, green: 0.90, blue: 0.50).opacity(isHovered ? 0.38 : 0.20),
                        Color(red: 0.0, green: 0.65, blue: 0.40).opacity(isHovered ? 0.22 : 0.12),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(Capsule())
            }
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color(red: 0.2, green: 1.0, blue: 0.6).opacity(isHovered ? 0.85 : 0.55),
                                Color(red: 0.0, green: 0.65, blue: 0.4).opacity(isHovered ? 0.55 : 0.30)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.85
                    )
            )
            .shadow(color: Color(red: 0.0, green: 0.90, blue: 0.50).opacity(isHovered ? 0.45 : 0.20), radius: isHovered ? 6.0 : 2.5, y: 1.0)

        case "Amethyst Nebula", "Amethyst Glass", "Amethyst":
            ZStack {
                Capsule()
                    .fill(Color(red: 0.10, green: 0.04, blue: 0.16).opacity(isHovered ? 0.60 : 0.40))
                LinearGradient(
                    colors: [
                        Color(red: 0.70, green: 0.30, blue: 0.95).opacity(isHovered ? 0.40 : 0.24),
                        Color(red: 0.45, green: 0.15, blue: 0.75).opacity(isHovered ? 0.25 : 0.14),
                        Color.clear
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(Capsule())
            }
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color(red: 0.85, green: 0.50, blue: 1.0).opacity(isHovered ? 0.85 : 0.55),
                                Color(red: 0.45, green: 0.15, blue: 0.75).opacity(isHovered ? 0.55 : 0.30)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.85
                    )
            )
            .shadow(color: Color.purple.opacity(isHovered ? 0.50 : 0.22), radius: isHovered ? 6.0 : 2.5, y: 1.0)

        case "Sunset Mirage", "Sunset Gradient", "Sunset":
            ZStack {
                Capsule()
                    .fill(Color(red: 0.16, green: 0.05, blue: 0.06).opacity(isHovered ? 0.60 : 0.40))
                LinearGradient(
                    colors: [
                        Color(red: 1.0, green: 0.45, blue: 0.25).opacity(isHovered ? 0.42 : 0.25),
                        Color(red: 0.95, green: 0.20, blue: 0.50).opacity(isHovered ? 0.30 : 0.16),
                        Color(red: 1.0, green: 0.75, blue: 0.20).opacity(isHovered ? 0.20 : 0.10)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(Capsule())
            }
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.60, blue: 0.40).opacity(isHovered ? 0.90 : 0.60),
                                Color(red: 0.95, green: 0.20, blue: 0.50).opacity(isHovered ? 0.65 : 0.35)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.85
                    )
            )
            .shadow(color: Color(red: 1.0, green: 0.45, blue: 0.25).opacity(isHovered ? 0.48 : 0.22), radius: isHovered ? 6.0 : 2.5, y: 1.0)

        case "Diamond Ice", "Diamond Glass", "Diamond":
            ZStack {
                Capsule()
                    .fill(Color.white.opacity(isHovered ? 0.24 : 0.14))
                LinearGradient(
                    stops: [
                        .init(color: Color.white.opacity(isHovered ? 0.55 : 0.35), location: 0.0),
                        .init(color: Color.cyan.opacity(isHovered ? 0.18 : 0.08), location: 0.45),
                        .init(color: Color.clear, location: 0.85)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .clipShape(Capsule())
            }
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isHovered ? 0.90 : 0.65),
                                Color.cyan.opacity(isHovered ? 0.50 : 0.30),
                                Color.white.opacity(0.20)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.90
                    )
            )
            .shadow(color: Color.white.opacity(isHovered ? 0.35 : 0.15), radius: isHovered ? 5.0 : 2.0, y: 1.0)

        default: // "Apple Liquid Glass", "Frosted Glass", "Matching System"
            ZStack {
                Capsule()
                    .fill(Color.white.opacity(isHovered ? 0.18 : 0.10))
                LinearGradient(
                    stops: [
                        .init(color: Color.white.opacity(isHovered ? 0.35 : 0.22), location: 0.0),
                        .init(color: Color.white.opacity(isHovered ? 0.10 : 0.04), location: 0.35),
                        .init(color: Color.clear, location: 0.80)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .clipShape(Capsule())
            }
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(isHovered ? 0.50 : 0.32), location: 0.0),
                                .init(color: Color.white.opacity(0.14), location: 0.40),
                                .init(color: Color.white.opacity(0.06), location: 0.70),
                                .init(color: Color.white.opacity(isHovered ? 0.28 : 0.18), location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.75
                    )
            )
            .shadow(color: Color.black.opacity(isHovered ? 0.22 : 0.10), radius: isHovered ? 4.0 : 2.0, x: 0, y: 1.0)
        }
    }

    @ViewBuilder
    private func batteryPillBackground(isHovered: Bool) -> some View {
        miniDockBackground
    }

    @ViewBuilder
    private func applyFinderColor<Content: View>(_ content: Content) -> some View {
        switch finderColor {
        case "Neon Cyan ⚡️":
            content.hueRotation(Angle(degrees: -20))
        case "Liquid Gold 👑":
            content.hueRotation(Angle(degrees: -160))
        case "Emerald Green 🟢":
            content.hueRotation(Angle(degrees: -85))
        case "Ruby Red 🔴":
            content.hueRotation(Angle(degrees: -210))
        case "Amethyst Purple 💜":
            content.hueRotation(Angle(degrees: 55))
        case "Hot Pink 💖":
            content.hueRotation(Angle(degrees: 95))
        case "Tangerine Orange 🍊":
            content.hueRotation(Angle(degrees: -180))
        case "Silver / Monochrome ⚪️":
            content.saturation(0.0)
        default: // "Classic Blue 🔵"
            content
        }
    }

    private var barFolderIcon: NSImage {
        let path = (barFolderPath as NSString).expandingTildeInPath
        if FileManager.default.fileExists(atPath: path) {
            let icon = NSWorkspace.shared.icon(forFile: path)
            icon.size = NSSize(width: 32, height: 32)
            return icon
        }
        if let img = NSImage(contentsOfFile: "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/GenericFolderIcon.icns") {
            img.size = NSSize(width: 32, height: 32)
            return img
        }
        let icon = NSWorkspace.shared.icon(forFile: NSHomeDirectory() + "/Downloads")
        icon.size = NSSize(width: 32, height: 32)
        return icon
    }

    private var barFolderDisplayName: String {
        let path = (barFolderPath as NSString).expandingTildeInPath
        if path == NSHomeDirectory() + "/Desktop" { return "Desktop" }
        if path == NSHomeDirectory() + "/Downloads" { return "Downloads" }
        if path == NSHomeDirectory() + "/Documents" { return "Documents" }
        if path == "/Applications" { return "Applications" }
        if path == NSHomeDirectory() { return "Home" }
        let name = URL(fileURLWithPath: path).lastPathComponent
        return name.isEmpty ? "Folder" : name
    }

    private var isTrashFull: Bool {
        trashMonitor.isTrashFull
    }

    private var trashIcon: NSImage {
        let icnsPath = isTrashFull
            ? "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/FullTrashIcon.icns"
            : "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/TrashIcon.icns"
        if let img = NSImage(contentsOfFile: icnsPath) {
            img.size = NSSize(width: 32, height: 32)
            return img
        }
        let conf = NSImage.SymbolConfiguration(pointSize: 14, weight: .regular)
        return NSImage(systemSymbolName: isTrashFull ? "trash.fill" : "trash", accessibilityDescription: "Trash")?.withSymbolConfiguration(conf) ?? NSImage()
    }

    private struct BatteryCategory {
        let name: String
        let styles: [String]
    }

    private var batteryCategories: [BatteryCategory] {
        [
            BatteryCategory(name: "Digital Numbers Only 🔢", styles: [
                "Digital Clock 7-Segment",
                "Retro LCD Matrix Clock",
                "Cyber Neon Digits",
                "Nixie Tube Digits",
                "Bold Minimal Digital",
                "Digital LED Dot Matrix",
                "VisionOS Digital Pill",
                "Text Only (% Only)"
            ]),
            BatteryCategory(name: "Minimal 🍏", styles: [
                "Apple Minimal", "Classic Apple Battery", "Minimal Pill", "VisionOS Pill",
                "Monochrome", "Genie Logo", "Genie Bolt"
            ]),
            BatteryCategory(name: "Equalizers & Meters 🎵", styles: [
                "10-Bar Equalizer", "Equalizer Bars", "Audio VU Meter", "10-Bar Gauge",
                "Liquid Wave", "Dynamic Wave"
            ]),
            BatteryCategory(name: "Cyber & Sci-Fi ⚡️", styles: [
                "Tesla Cell Pack", "10 Neon LEDs", "Cyberpunk Matrix", "DNA Helix",
                "Animated Hex", "Solar Core", "Prism Pulse"
            ]),
            BatteryCategory(name: "Gauges & Rings 🧭", styles: [
                "Circular Dual Arc", "Radial Ring", "Tachometer Arc", "Ocean Dolphin 🐬",
                "Coral Reef Fish 🐠"
            ]),
            BatteryCategory(name: "Pixel & Retro 👾", styles: [
                "Pixel Heart", "8-Bit Arcade", "Retro Dot Matrix", "Skateboard Deck 🛹"
            ])
        ]
    }

    private func selectBatteryStyle(_ style: String) {
        HapticFeedback.selection()
        batteryStyle = style
        UserDefaults.standard.set(style, forKey: PrefKey.batteryStyle)
        UserDefaults.standard.set(style, forKey: PrefKey.iconStyle)
        NotificationCenter.default.post(name: NSNotification.Name("NexusIconStyleChanged"), object: style)
        AppDelegate.shared?.renderIcon()
    }

    @ViewBuilder
    private var genieLauncherButton: some View {
        let gWave = magnificationWave(for: "leoLauncher")
        let isHovered = (hoveredItemId == "leoLauncher" || isLeoHovered)
        Button(action: {
            HapticFeedback.selection()
            FinderChatWindowManager.shared.toggle(tab: .chat)
        }) {
            ZStack {
                GenieMysticalIconView(
                    glyphImage: glyphImage,
                    isHovered: isHovered,
                    size: 20
                ) {
                    HapticFeedback.selection()
                    FinderChatWindowManager.shared.toggle(tab: .chat)
                }
            }
            .frame(width: 30, height: 24)
            .scaleEffect(gWave.scale, anchor: .top)
            .offset(x: magnificationDisplacement(for: "leoLauncher"), y: gWave.yOffset)
            .contentShape(Rectangle())
        }
        .background(
            GeometryReader { geo in
                Color.clear.preference(key: LeoFrameKey.self, value: geo.frame(in: .named("StripRoot")))
            }
        )
        .buttonStyle(DockIconButtonStyle())
        .zIndex(gWave.zIndex)
        .onHover { h in
            isLeoHovered = h
            if h {
                dismissTimer?.invalidate()
                dismissTimer = nil
                isStripHovered = true
            }
            handleItemHover(id: "leoLauncher", hovering: h)
        }
        .help("Genie Studio & Chat (⌘⌥Space) • Rub the Lamp for Wishes 🪔")
        .contextMenu {
            Button("Genie Chat & Studio (⌘⌥Space)") {
                FinderChatWindowManager.shared.toggle(tab: .chat)
            }
            Button("✨ Whisper a Wish (Sporadic Whim)") {
                GenieSporadicWishEngine.shared.triggerSporadicWhim()
            }
            Button("🪔 Rub the Magic Lamp") {
                GenieSporadicWishEngine.shared.rubLamp()
            }
            Button("Toggle Architectural Canvas (⌘⇧D)") {
                NotificationCenter.default.post(name: NSNotification.Name("NexusToggleDesktopGrid"), object: nil)
            }
            Divider()
            Button("Quit Genie (⌘Q)") {
                NSApp.terminate(nil)
            }
        }
    }

    @ViewBuilder
    private var menuBarAIStreamingTickerView: some View {
        let isGenerating = localModels.isGenerating
        let currentText = isGenerating ? (localModels.currentResponse.isEmpty ? "Thinking..." : localModels.currentResponse) : (localModels.chatHistory.last?.content ?? "")
        let cleanText = currentText.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)

        if isGenerating || (!cleanText.isEmpty && isStripHovered) {
            Button(action: {
                HapticFeedback.selection()
                FinderChatWindowManager.shared.show()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: isGenerating ? "sparkles" : "arrow.right.circle.fill")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(isGenerating ? .cyan : .white.opacity(0.80))
                        .scaleEffect(isGenerating ? 1.15 : 1.0)

                    Text(cleanText.isEmpty ? "AI Stream" : cleanText)
                        .font(.system(size: 10.5, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: isGenerating ? 220 : 150, alignment: .leading)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2.5)
                .background(
                    Capsule()
                        .fill(Color.cyan.opacity(isGenerating ? 0.25 : 0.12))
                )
                .overlay(
                    Capsule()
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.cyan.opacity(isGenerating ? 0.80 : 0.45), Color.blue.opacity(0.30)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 0.75
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .scale(scale: 0.8, anchor: .leading)),
                removal: .opacity.combined(with: .scale(scale: 0.8, anchor: .leading))
            ))
            .help("Live AI Stream — Click to drop down Chat Studio 💬")
        }
    }


    @ViewBuilder
    private var putBackPillButton: some View {
        if !dockManager.hiddenBundleIDs.isEmpty {
            Button(action: {
                showPutBackPopover.toggle()
                HapticFeedback.selection()
            }) {
                HStack(spacing: 3) {
                    Image(systemName: "arrow.uturn.backward.circle.fill")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.cyan)
                    Text("Put Back (\(dockManager.hiddenBundleIDs.count))")
                        .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2.5)
                .background(Capsule().fill(Color.cyan.opacity(0.18)))
                .overlay(Capsule().strokeBorder(Color.cyan.opacity(0.40), lineWidth: 0.6))
            }
            .buttonStyle(.plain)
            .help("Restore closed or hidden apps to pill bar")
            .popover(isPresented: $showPutBackPopover, arrowEdge: .bottom) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("Put Back Apps (\(dockManager.hiddenBundleIDs.count))", systemImage: "arrow.uturn.backward")
                            .font(.system(size: 11.5, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Spacer()
                        Button("Put Back All") {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                                dockManager.restoreAllHiddenDockApps()
                                showPutBackPopover = false
                            }
                            HapticFeedback.success()
                        }
                        .font(.system(size: 10, weight: .bold))
                        .buttonStyle(.borderedProminent)
                        .tint(.cyan)
                    }

                    Divider().background(Color.white.opacity(0.12))

                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(spacing: 4) {
                            ForEach(dockManager.getHiddenDockItems()) { hiddenItem in
                                HStack(spacing: 8) {
                                    if let icon = hiddenItem.icon {
                                        Image(nsImage: icon)
                                            .resizable()
                                            .frame(width: 18, height: 18)
                                    } else {
                                        Image(systemName: "app.fill")
                                            .font(.system(size: 14))
                                    }
                                    Text(hiddenItem.name)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.white)
                                        .lineLimit(1)
                                    Spacer()
                                    Button("Put Back") {
                                        withAnimation(.spring(response: 0.25, dampingFraction: 0.82)) {
                                            dockManager.unhideDockItem(id: hiddenItem.id)
                                            if let bid = hiddenItem.bundleIdentifier {
                                                dockManager.unhideDockItem(id: bid)
                                            }
                                        }
                                        HapticFeedback.selection()
                                    }
                                    .font(.system(size: 10, weight: .semibold))
                                    .buttonStyle(.bordered)
                                }
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.06)))
                            }
                        }
                    }
                    .frame(maxHeight: 180)
                }
                .padding(12)
                .frame(width: 250)
                .background(Color.black.opacity(0.94))
            }
        }
    }

    // Split into label / popover-body helpers: as one expression this exceeded
    // the type checker's budget in release builds.
    @ViewBuilder
    private var moreAppsPillLabel: some View {
        let count: Int = overflowDockItems.count
        Text("+\(count)")
            .font(.system(size: 9.5, weight: .bold, design: .rounded))
            .foregroundColor(.white.opacity(0.85))
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(Capsule().fill(Color.white.opacity(0.14)))
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.24), lineWidth: 0.5))
    }

    @ViewBuilder
    private var moreAppsPopoverBody: some View {
        let items: [DockAppItem] = overflowDockItems
        VStack(alignment: .leading, spacing: 8) {
            Text("Additional Running Apps")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Divider().background(Color.white.opacity(0.12))

            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 4) {
                    ForEach(items) { app in
                        overflowAppRow(app)
                    }
                }
            }
            .frame(maxHeight: 200)
        }
        .padding(12)
        .frame(width: 220)
        .background(Color.black.opacity(0.94))
    }

    @ViewBuilder
    private var moreAppsPillButton: some View {
        if !overflowDockItems.isEmpty {
            Button(action: {
                showMoreAppsPopover.toggle()
                HapticFeedback.selection()
            }) {
                moreAppsPillLabel
            }
            .buttonStyle(.plain)
            .help("+\(overflowDockItems.count) more apps running in background")
            .popover(isPresented: $showMoreAppsPopover, arrowEdge: .bottom) {
                moreAppsPopoverBody
            }
        }
    }

    private func overflowAppRow(_ app: DockAppItem) -> some View {
        Button(action: {
            showMoreAppsPopover = false
            app.activate()
            HapticFeedback.selection()
        }) {
            HStack(spacing: 8) {
                if let icon = app.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 18, height: 18)
                } else {
                    Image(systemName: "app.fill")
                        .font(.system(size: 14))
                }
                Text(app.name)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.06)))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var appsClusterPillView: some View {
        // Smart edge reveal: in hidden/auto-hide mode, the dock has no visible handle to click —
        // it simply appears when the cursor nears the screen edge it lives on (see isNearScreenEdge,
        // driven by MenuBarActionDispatcher's edge-proximity monitor) and retreats when it leaves,
        // the same way the real macOS Dock auto-reveals.
        let showActiveApps = (!isHiddenMode || isStripHovered || isNearScreenEdge)
        if showActiveApps {
            if menuBarDockInactiveAppsOnly {
                // Sleek Inactive Applications Pill: Genie Launcher + Inactive (Background) Running Apps
                HStack(alignment: .center, spacing: 8.5) {
                    genieLauncherButton

                    if !activeDockItems.isEmpty {
                        Rectangle()
                            .fill(Color.white.opacity(0.20))
                            .frame(width: 1, height: 16)
                            .padding(.horizontal, 4)

                        HStack(alignment: .center, spacing: 8.5) {
                            ForEach(visibleDockItems) { item in
                                dockAppItemView(item: item)
                            }
                        }
                        .padding(.horizontal, 8)

                        moreAppsPillButton
                    }

                    putBackPillButton
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 4.0)
            } else {
                HStack(alignment: .center, spacing: 8.5) {
                    // 0. Primary GENIE menu bar icon (brings to chat!)
                    genieLauncherButton

                    Rectangle()
                        .fill(Color.white.opacity(0.20))
                        .frame(width: 1, height: 16)
                        .padding(.horizontal, 4)

                    // 1. Applications in exact bottom macOS Dock order (Finder, System Settings, Chrome, Stickies, Mail, Genie, etc.)
                    HStack(alignment: .center, spacing: 8.5) {
                        ForEach(visibleDockItems) { item in
                            dockAppItemView(item: item)
                        }
                    }
                    .padding(.horizontal, 8)

                    moreAppsPillButton

                    putBackPillButton

                    // 2. Vertical Divider before Folder Stacks & Trash
                    if (dockShowFolderStacks && !dockManager.dockFolders.isEmpty) || dockAlwaysShowTrash {
                        Rectangle()
                            .fill(Color.white.opacity(0.20))
                            .frame(width: 1, height: 16)
                            .padding(.horizontal, 4)
                    }

                    // 3. Pinned Folder Stacks (Applications, Downloads)
                    if dockShowFolderStacks && !dockManager.dockFolders.isEmpty {
                        ForEach(dockManager.dockFolders) { folder in
                            dockFolderPillItemView(folder: folder)
                        }
                    }

                    // 4. Native macOS Live Trash Slot
                    if dockAlwaysShowTrash {
                        trashItemView
                    }

                    // 5. Vertical Divider before Chat, Editor & Settings
                    Rectangle()
                        .fill(Color.white.opacity(0.20))
                        .frame(width: 1, height: 16)
                        .padding(.horizontal, 4)

                    // 6. Genie Chat Inside Pill Dock
                    chatPillItemView

                    // 7. Genie Studio Inside Pill Dock
                    editorPillItemView

                    // 8. Genie Settings Inside Pill Dock
                    settingsPillItemView
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 4.0)
            }
        } else {
            // When apps are hidden or collapsed, ALWAYS keep the nice animated Genie launcher in the menu bar!
            HStack(alignment: .center, spacing: 0) {
                genieLauncherButton
            }
            .padding(.horizontal, 5)
            .padding(.vertical, 2.5)
        }
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 6.0) {
            // ── Unified Running Apps Pill (Mini Dock with 1:1 bottom dock order) ──
            // The real system battery item is left alone now (see PrefKey removal note in
            // AppDefaultsManager) — Genie no longer draws its own battery pill here.
            appsClusterPillView
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.1, anchor: .trailing)
                        .combined(with: .opacity)
                        .combined(with: .offset(x: -25)),
                    removal: .scale(scale: 0.1, anchor: .trailing)
                        .combined(with: .opacity)
                        .combined(with: .offset(x: -25))
                ))
        }


        .opacity(1.0)
        .transition(.opacity)
        .onHover { hovering in
            if hovering {
                dismissTimer?.invalidate()
                dismissTimer = nil
                withAnimation(.spring(response: 0.32, dampingFraction: 0.78)) {
                    isStripHovered = true
                }
            } else {
                dismissTimer?.invalidate()
                dismissTimer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: false) { _ in
                    Task { @MainActor in
                        withAnimation(.spring(response: 0.30, dampingFraction: 0.82)) {
                            isStripHovered = false
                        }
                    }
                }
            }
        }
        .animation(.spring(response: 0.32, dampingFraction: 0.78), value: isStripHovered)
        .padding(.horizontal, 2)
        .fixedSize(horizontal: true, vertical: false)
        .coordinateSpace(name: "StripRoot")
        .background(
            GeometryReader { geo in
                Color.clear.preference(key: StripWidthPreferenceKey.self, value: ceil(geo.size.width) + 16)
            }
        )
        .onPreferenceChange(StripWidthPreferenceKey.self) { newWidth in
            AppDelegate.shared?.updateStatusItemWidth(newWidth)
            MenuBarActionDispatcher.shared.stripWidth = newWidth
        }
        .onPreferenceChange(LeoFrameKey.self) { MenuBarActionDispatcher.shared.leoFrame = $0 }
        .onPreferenceChange(AppFramesKey.self) { MenuBarActionDispatcher.shared.appFrames = $0 }
        .onPreferenceChange(FinderFrameKey.self) { MenuBarActionDispatcher.shared.finderFrame = $0 }
        .onPreferenceChange(TrashFrameKey.self) { MenuBarActionDispatcher.shared.trashFrame = $0 }
        .onAppear {
            dockManager.refreshDockApps()
            BatteryMonitor.shared.refresh()
            if statusIconGlyph.isEmpty || statusIconGlyph == "Golden Gate Arch" || statusIconGlyph == "Leo Maltese 🐶" || statusIconGlyph == "Genie Lamp 🪔" {
                statusIconGlyph = "Genie Person 🧞‍♂️"
                UserDefaults.standard.set("Genie Person 🧞‍♂️", forKey: PrefKey.statusIconGlyph)
                UserDefaults.standard.set("Genie Person 🧞‍♂️", forKey: PrefKey.statusIconStyle)
                UserDefaults.standard.set("Genie Person", forKey: PrefKey.brandIconStyle)
                BrandLogoManager.shared.brandIconStyle = "Genie Person"
            }
            refreshApps()
            MenuBarActionDispatcher.shared.dockItems = self.activeDockItems
            MenuBarActionDispatcher.shared.displayApps = self.displayApps
            MenuBarActionDispatcher.shared.startEdgeProximityMonitoring()
        }
        .onDisappear {
            hoverDebounceTimer?.invalidate()
            hoverDebounceTimer = nil
            MenuBarActionDispatcher.shared.stopEdgeProximityMonitoring()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusAnimTick"))) { notif in
            if let p = notif.object as? CGFloat {
                animPhase = p
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusMenuBarEdgeProximity"))) { notif in
            let near = (notif.object as? Bool) ?? false
            if near {
                dismissTimer?.invalidate()
                dismissTimer = nil
                withAnimation(.spring(response: 0.30, dampingFraction: 0.80)) {
                    isNearScreenEdge = true
                }
            } else {
                withAnimation(.spring(response: 0.30, dampingFraction: 0.82)) {
                    isNearScreenEdge = false
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusBatteryColorModeChanged"))) { notif in
            if let mode = notif.object as? String {
                batteryColorMode = mode
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusIconStyleChanged"))) { notif in
            if let style = notif.object as? String {
                batteryStyle = style
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusShowChargingBoltChanged"))) { notif in
            if let val = notif.object as? Bool {
                showChargingBolt = val
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusMenuBarAppleColorChanged"))) { notif in
            if let col = notif.object as? String {
                appleColor = col
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusMenuBarThemeChanged"))) { _ in
            textColorName = UserDefaults.standard.string(forKey: PrefKey.menuBarTextColor) ?? textColorName
            fontFamily = UserDefaults.standard.string(forKey: PrefKey.menuBarFontFamily) ?? fontFamily
            fontWeight = UserDefaults.standard.string(forKey: PrefKey.menuBarFontWeight) ?? fontWeight
            let savedSize = UserDefaults.standard.double(forKey: PrefKey.menuBarFontSize)
            if savedSize > 0 {
                menuBarFontSize = savedSize
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusDockActiveAppsOnlyChanged"))) { notif in
            if let val = notif.object as? Bool {
                dockActiveAppsOnly = val
            }
            refreshApps()
        }
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didActivateApplicationNotification)) { notif in
            if let app = notif.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                dockManager.activePid = app.processIdentifier
            } else {
                dockManager.activePid = NSWorkspace.shared.frontmostApplication?.processIdentifier ?? 0
            }
            refreshApps()
        }
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didDeactivateApplicationNotification)) { _ in
            dockManager.activePid = NSWorkspace.shared.frontmostApplication?.processIdentifier ?? 0
            refreshApps()
        }
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didLaunchApplicationNotification)) { _ in
            dockManager.refreshDockApps()
            refreshApps()
        }
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didTerminateApplicationNotification)) { _ in
            dockManager.refreshDockApps()
            refreshApps()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusMiniDockModeChanged"))) { notif in
            if let val = notif.object as? String {
                miniDockDisplayMode = val
            } else {
                miniDockDisplayMode = UserDefaults.standard.string(forKey: PrefKey.miniDockDisplayMode) ?? "Always Shown"
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusMenuBarAppsPlacementChanged"))) { notif in
            if let val = notif.object as? String {
                appsPlacement = val
            } else {
                appsPlacement = UserDefaults.standard.string(forKey: PrefKey.menuBarAppsPlacement) ?? "Right Side (Classic Dock)"
            }
        }
    }

    // MARK: - Unified Connected Dock Subviews

    private var folderItemView: some View {
        let fWave = magnificationWave(for: "barFolder")
        return Button(action: {
            openNativeFinder()
        }) {
            ZStack(alignment: .center) {
                RoundedRectangle(cornerRadius: 6.5, style: .continuous)
                    .fill((hoveredItemId == "barFolder" || isFinderHovered) ? Color.white.opacity(0.15) : Color.clear)
                    .frame(width: 26, height: 26)

                Image(nsImage: barFolderIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 21, height: 21)
                    .shadow(color: Color.black.opacity((hoveredItemId == "barFolder" || isFinderHovered) ? 0.35 : 0.15), radius: 1.0, y: 0.8)
            }
            .frame(width: 26, height: 26)
            .scaleEffect(fWave.scale, anchor: .center)
            .offset(x: magnificationDisplacement(for: "barFolder"), y: fWave.yOffset)
            .contentShape(RoundedRectangle(cornerRadius: 6.5, style: .continuous))
        }
        .background(
            GeometryReader { geo in
                Color.clear.preference(key: FinderFrameKey.self, value: geo.frame(in: .named("StripRoot")))
            }
        )
        .buttonStyle(DockIconButtonStyle())
        .zIndex(fWave.zIndex)
        .onHover { h in
            isFinderHovered = h
            handleItemHover(id: "barFolder", hovering: h)
        }
        .help("\(barFolderDisplayName) — Click to open in Finder")
        .contextMenu {
            Button(LocalizedStrings.translateText("Open \(barFolderDisplayName)", lang: appLanguage)) {
                openNativeFinder()
            }
            Button(LocalizedStrings.translateText("Change Folder in Settings...", lang: appLanguage)) {
                openGenieSettings()
            }
            Button(LocalizedStrings.translateText("Choose Folder Destination...", lang: appLanguage)) {
                chooseFolderDestinationDirectly()
            }

            Divider()

            Menu(LocalizedStrings.translateText("Finder Color", lang: appLanguage)) {
                ForEach([
                    "Classic Blue 🔵",
                    "Neon Cyan ⚡️",
                    "Liquid Gold 👑",
                    "Emerald Green 🟢",
                    "Ruby Red 🔴",
                    "Amethyst Purple 💜",
                    "Hot Pink 💖",
                    "Tangerine Orange 🍊",
                    "Silver / Monochrome ⚪️"
                ], id: \.self) { color in
                    Button(action: {
                        finderColor = color
                        UserDefaults.standard.set(color, forKey: PrefKey.finderColor)
                        AppDelegate.shared?.renderIcon()
                    }) {
                        HStack {
                            Text(color)
                            if finderColor == color { Text("✓") }
                        }
                    }
                }
            }

            Menu(LocalizedStrings.translateText("Finder Icon Style", lang: appLanguage)) {
                ForEach(["Finder Face (Default)", "Folder"], id: \.self) { style in
                    Button(action: {
                        finderIconStyle = style
                        UserDefaults.standard.set(style, forKey: PrefKey.finderIconStyle)
                        AppDelegate.shared?.renderIcon()
                    }) {
                        HStack {
                            Text(style)
                            if finderIconStyle == style { Text("✓") }
                        }
                    }
                }
            }

            Divider()

            Button(LocalizedStrings.translateText("New Finder Window", lang: appLanguage)) {
                let homeURL = FileManager.default.homeDirectoryForCurrentUser
                let finderBundleURL = URL(fileURLWithPath: "/System/Library/CoreServices/Finder.app")
                let config = NSWorkspace.OpenConfiguration()
                config.activates = true
                NSWorkspace.shared.open([homeURL], withApplicationAt: finderBundleURL, configuration: config, completionHandler: nil)
            }
            Button(LocalizedStrings.translateText("Go to Desktop", lang: appLanguage)) {
                let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSHomeDirectory() + "/Desktop")
                NSWorkspace.shared.open(desktopURL)
                if let finderApp = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.finder").first {
                    finderApp.unhide()
                    finderApp.activate(options: [.activateAllWindows])
                }
            }
            Button(LocalizedStrings.translateText("Go to Downloads", lang: appLanguage)) {
                let dlURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSHomeDirectory() + "/Downloads")
                NSWorkspace.shared.open(dlURL)
                if let finderApp = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.finder").first {
                    finderApp.unhide()
                    finderApp.activate(options: [.activateAllWindows])
                }
            }
            Button(LocalizedStrings.translateText("Go to Applications", lang: appLanguage)) {
                let appsURL = URL(fileURLWithPath: "/Applications")
                NSWorkspace.shared.open(appsURL)
                if let finderApp = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.finder").first {
                    finderApp.unhide()
                    finderApp.activate(options: [.activateAllWindows])
                }
            }

            Divider()

            Button(LocalizedStrings.translateText("Genie Settings...", lang: appLanguage)) {
                openGenieSettings()
            }
        }
    }

    @ViewBuilder
    private func dockFolderPillItemView(folder: DockFolderItem) -> some View {
        let itemId = "folder_\(folder.id)"
        let fWave = magnificationWave(for: itemId)
        Button(action: {
            HapticFeedback.selection()
            folder.openInFinder()
        }) {
            ZStack(alignment: .center) {
                RoundedRectangle(cornerRadius: 6.5, style: .continuous)
                    .fill((hoveredItemId == itemId) ? Color.white.opacity(0.15) : Color.clear)
                    .frame(width: 26, height: 26)

                if let icon = folder.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 21, height: 21)
                        .shadow(color: Color.black.opacity((hoveredItemId == itemId) ? 0.35 : 0.15), radius: 1.0, y: 0.8)
                } else {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color(red: 0.35, green: 0.70, blue: 1.0))
                }
            }
            .frame(width: 26, height: 26)
            .scaleEffect(fWave.scale, anchor: .center)
            .offset(x: magnificationDisplacement(for: itemId), y: fWave.yOffset)
            .contentShape(RoundedRectangle(cornerRadius: 6.5, style: .continuous))
        }
        .buttonStyle(DockIconButtonStyle())
        .zIndex(fWave.zIndex)
        .onHover { h in
            handleItemHover(id: itemId, hovering: h)
        }
        .help("\(folder.name) — Click to open folder in Finder")
        .contextMenu {
            Button("Open \(folder.name)") {
                folder.openInFinder()
            }
            Button("Show in Finder") {
                NSWorkspace.shared.activateFileViewerSelecting([folder.folderURL])
            }
        }
    }

    private var trashItemView: some View {
        let tWave = magnificationWave(for: "trash")
        return Button(action: {
            openNativeTrash()
        }) {
            ZStack(alignment: .center) {
                RoundedRectangle(cornerRadius: 6.5, style: .continuous)
                    .fill((hoveredItemId == "trash" || isTrashHovered) ? Color.white.opacity(0.15) : Color.clear)
                    .frame(width: 26, height: 26)

                Image(nsImage: trashIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 20, height: 20)
                    .shadow(color: Color.black.opacity((hoveredItemId == "trash" || isTrashHovered) ? 0.35 : 0.15), radius: 1.0, y: 0.8)
            }
            .frame(width: 26, height: 26)
            .scaleEffect(tWave.scale, anchor: .center)
            .offset(x: magnificationDisplacement(for: "trash"), y: tWave.yOffset)
            .contentShape(RoundedRectangle(cornerRadius: 6.5, style: .continuous))
        }
        .background(
            GeometryReader { geo in
                Color.clear.preference(key: TrashFrameKey.self, value: geo.frame(in: .named("StripRoot")))
            }
        )
        .buttonStyle(DockIconButtonStyle())
        .zIndex(tWave.zIndex)
        .onHover { h in
            isTrashHovered = h
            handleItemHover(id: "trash", hovering: h)
        }
        .help("Trash — Click to open Trash")
        .contextMenu {
            Button(LocalizedStrings.translateText("Open Trash", lang: appLanguage)) {
                openNativeTrash()
            }
            Button(LocalizedStrings.translateText("Empty Trash", lang: appLanguage)) {
                emptyNativeTrash()
            }
            Divider()
            Button(LocalizedStrings.translateText("Genie Settings...", lang: appLanguage)) {
                openGenieSettings()
            }
        }
    }

    // MARK: - Inside-the-Pill Chat, Editor & Settings Actions
    private var chatPillItemView: some View {
        let cWave = magnificationWave(for: "pill_chat")
        let isHovered = (hoveredItemId == "pill_chat" || isChatHovered)
        let isChatActive = FinderChatWindowManager.shared.isVisible && FinderChatWindowManager.shared.activeTab == .chat
        return Button(action: {
            HapticFeedback.selection()
            FinderChatWindowManager.shared.toggle(tab: .chat)
        }) {
            ZStack(alignment: .center) {
                Circle()
                    .fill(isHovered ? Color.cyan.opacity(0.35) : (isChatActive ? Color.cyan.opacity(0.25) : Color.white.opacity(0.08)))
                    .frame(width: 22, height: 22)

                Image(systemName: isChatActive ? "bubble.left.and.bubble.right.fill" : "bubble.left.and.bubble.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(isChatActive ? .cyan : (isHovered ? .white : .white.opacity(0.80)))
                    .shadow(color: Color.cyan.opacity(isChatActive ? 0.60 : 0.0), radius: 2)
            }
            .frame(width: 26, height: 26)
            .scaleEffect(cWave.scale, anchor: .center)
            .offset(x: magnificationDisplacement(for: "pill_chat"), y: cWave.yOffset)
            .contentShape(Circle())
        }
        .buttonStyle(DockIconButtonStyle())
        .zIndex(cWave.zIndex)
        .onHover { h in
            isChatHovered = h
            handleItemHover(id: "pill_chat", hovering: h)
        }
        .help("Genie Chat 💬 — Click to open Chat Studio")
    }

    private var editorPillItemView: some View {
        let eWave = magnificationWave(for: "pill_editor")
        let isHovered = (hoveredItemId == "pill_editor" || isEditorHovered)
        let isEditorActive = FinderChatWindowManager.shared.isVisible && FinderChatWindowManager.shared.activeTab == .editor
        return Button(action: {
            HapticFeedback.selection()
            FinderChatWindowManager.shared.toggle(tab: .editor)
        }) {
            ZStack(alignment: .center) {
                Circle()
                    .fill(isHovered ? Color.green.opacity(0.35) : (isEditorActive ? Color.green.opacity(0.25) : Color.white.opacity(0.08)))
                    .frame(width: 22, height: 22)

                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(isEditorActive ? .green : (isHovered ? .white : .white.opacity(0.80)))
                    .shadow(color: Color.green.opacity(isEditorActive ? 0.60 : 0.0), radius: 2)
            }
            .frame(width: 26, height: 26)
            .scaleEffect(eWave.scale, anchor: .center)
            .offset(x: magnificationDisplacement(for: "pill_editor"), y: eWave.yOffset)
            .contentShape(Circle())
        }
        .buttonStyle(DockIconButtonStyle())
        .zIndex(eWave.zIndex)
        .onHover { h in
            isEditorHovered = h
            handleItemHover(id: "pill_editor", hovering: h)
        }
        .help("Genie Editor 💻 — Click to open Code Editor & Files")
    }

    private var settingsPillItemView: some View {
        let sWave = magnificationWave(for: "pill_settings")
        let isHovered = (hoveredItemId == "pill_settings" || isSettingsHovered)
        let isSettingsActive = FinderChatWindowManager.shared.isVisible && FinderChatWindowManager.shared.activeTab == .settings
        return Button(action: {
            HapticFeedback.selection()
            FinderChatWindowManager.shared.toggle(tab: .settings)
        }) {
            ZStack(alignment: .center) {
                Circle()
                    .fill(isHovered ? Color.purple.opacity(0.35) : (isSettingsActive ? Color.purple.opacity(0.25) : Color.white.opacity(0.08)))
                    .frame(width: 22, height: 22)

                Image(systemName: "gearshape.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(isSettingsActive ? .purple : (isHovered ? .white : Color.white.opacity(0.80)))
                    .shadow(color: Color.purple.opacity(isSettingsActive ? 0.60 : 0.0), radius: 2)
            }
            .frame(width: 26, height: 26)
            .scaleEffect(sWave.scale, anchor: .center)
            .offset(x: magnificationDisplacement(for: "pill_settings"), y: sWave.yOffset)
            .contentShape(Circle())
        }
        .buttonStyle(DockIconButtonStyle())
        .zIndex(sWave.zIndex)
        .onHover { h in
            isSettingsHovered = h
            handleItemHover(id: "pill_settings", hovering: h)
        }
        .help("Genie Settings ⚙️ — System Preferences & Configurations")
        .contextMenu {
            Button("Genie Settings (⌘,)") {
                FinderChatWindowManager.shared.show(tab: .settings)
            }
            Button("macOS System Settings...") {
                NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/System Settings.app"))
            }
        }
    }

    // MARK: - Dedicated Native Battery Bar Gauge View
    @ViewBuilder
    private var batteryBarGaugeView: some View {
        let pct = batteryMonitor.batteryPct ?? 100
        let pctFloat = CGFloat(max(0, min(100, pct))) / 100.0
        let isCharging = batteryMonitor.isCharging

        let fillColor: Color = {
            if isCharging {
                return Color(red: 0.20, green: 0.96, blue: 0.52)
            }
            if pct > 45 {
                return Color(red: 0.25, green: 0.92, blue: 0.45)
            } else if pct > 20 {
                return Color(red: 1.0, green: 0.78, blue: 0.20)
            } else {
                return Color(red: 1.0, green: 0.28, blue: 0.28)
            }
        }()

        HStack(spacing: 1.5) {
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3.0, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.40), lineWidth: 1.0)
                    .background(RoundedRectangle(cornerRadius: 3.0, style: .continuous).fill(Color.white.opacity(0.12)))
                    .frame(width: 24, height: 11.5)

                RoundedRectangle(cornerRadius: 1.8, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [fillColor, fillColor.opacity(0.85)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: max(2.0, 20.0 * pctFloat), height: 8.0)
                    .padding(.leading, 1.8)
                    .animation(.spring(response: 0.35, dampingFraction: 0.75), value: pctFloat)

                if isCharging {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 7.0, weight: .black))
                        .foregroundColor(.black.opacity(0.90))
                        .shadow(color: .white.opacity(0.6), radius: 0.5)
                        .frame(width: 24, height: 11.5, alignment: .center)
                }
            }

            RoundedRectangle(cornerRadius: 1.0, style: .continuous)
                .fill(Color.white.opacity(0.40))
                .frame(width: 1.8, height: 5.0)
        }
    }

    private var batteryItemView: some View {
        Button(action: {
            if NSEvent.modifierFlags.contains(.option) {
                MenuBarActionDispatcher.shared.cycleNextBatteryStyle()
            } else {
                HapticFeedback.selection()
            }
        }) {
            HStack(spacing: 4.0) {
                if let bImg = batteryImage, effectiveBatteryStyle != "Classic Apple Battery" {
                    let bW = max(18.0, min(50.0, bImg.size.width * (16.0 / max(1.0, bImg.size.height))))
                    Image(nsImage: bImg)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: bW, height: 16)
                } else {
                    batteryBarGaugeView
                }

                if showChargingBolt && batteryMonitor.isCharging && effectiveBatteryStyle != "Classic Apple Battery" {
                    AnimatedChargingEffectView()
                        .transition(.scale.combined(with: .opacity))
                }

                if showBatteryPercentage && !isDigitalNumberOnlyStyle {
                    Text("\(batteryMonitor.batteryPct ?? 100)%")
                        .font(MenuBarThemeManager.resolveFont(family: fontFamily, size: CGFloat(menuBarFontSize), weightName: fontWeight).monospacedDigit())
                        .foregroundColor(percentageColor)
                }
            }
            .frame(height: 26)
            .padding(.horizontal, 9)
            .background(
                Capsule()
                    .fill(isBatteryHovered ? Color.white.opacity(0.18) : Color.white.opacity(0.07))
                    .overlay(
                        Capsule()
                            .strokeBorder(isBatteryHovered ? Color.white.opacity(0.32) : Color.white.opacity(0.12), lineWidth: 0.8)
                    )
            )
            .fixedSize()
            .contentShape(Capsule())
        }
        .onHover { h in isBatteryHovered = h }
        .background(
            GeometryReader { geo in
                Color.clear.preference(key: BatteryFrameKey.self, value: geo.frame(in: .named("StripRoot")))
            }
        )
        .buttonStyle(DockIconButtonStyle())
        .help("Battery Bar: \(batteryMonitor.batteryPct ?? 100)% (\(effectiveBatteryStyle)) — Click for Applications, right-click or ⌥-click to change style")
        .contextMenu {
            // Live Battery Power Header
            let bm = BatteryMonitor.shared
            let pct = bm.batteryPct ?? 100
            let pwrText = bm.isCharging ? "\(pct)% — Charging on Power Adapter ⚡" : (bm.isPluggedIn ? "\(pct)% — Power Adapter Connected 🔌" : "\(pct)% — On Battery Power 🔋")
            Text(pwrText)
            
            Button("macOS Battery Settings...") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.battery") {
                    NSWorkspace.shared.open(url)
                }
            }
            
            Divider()
            
            // 1. Running Applications Submenu
            let running = NSWorkspace.shared.runningApplications.filter { $0.activationPolicy == .regular && !$0.isTerminated }
            Menu("Running Applications (\(running.count))") {
                ForEach(running, id: \.processIdentifier) { app in
                    Button(action: {
                        MenuBarActionDispatcher.shared.activateApp(app)
                    }) {
                        HStack {
                            Text(app.localizedName ?? "Application")
                            if app.isActive { Text("✓") }
                        }
                    }
                }
            }
            
            // 2. Mini Dock & ALL Pinned Apps Submenu
            let allDockItems = dockManager.dockItems.isEmpty ? DockAndDesktopManager.loadSystemDockApps() : dockManager.dockItems
            Menu("Mini Dock & Pinned Apps (\(allDockItems.count))") {
                ForEach(allDockItems) { item in
                    Button(action: {
                        MenuBarActionDispatcher.shared.handleAppClick(item)
                    }) {
                        HStack {
                            Text(item.name)
                            if item.isRunning { Text("●") }
                        }
                    }
                }
            }

            // 3. Folders & Stacks Submenu
            let allDockFolders = dockManager.dockFolders.isEmpty ? DockAndDesktopManager.loadSystemDockFolders() : dockManager.dockFolders
            Menu("Folders & Stacks") {
                ForEach(allDockFolders) { folder in
                    Button(action: {
                        folder.openInFinder()
                    }) {
                        Text(folder.name)
                    }
                }
                Divider()
                Button("Downloads") {
                    if let url = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first {
                        NSWorkspace.shared.open(url)
                    }
                }
                Button("Documents") {
                    if let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                        NSWorkspace.shared.open(url)
                    }
                }
                Button("Desktop") {
                    if let url = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first {
                        NSWorkspace.shared.open(url)
                    }
                }
                Button("Applications") {
                    NSWorkspace.shared.open(URL(fileURLWithPath: "/Applications"))
                }
            }

            Divider()

            // 4. Mini Dock Options Submenu
            Menu("Mini Dock Display Options") {
                Toggle("Active Applications Only", isOn: $dockActiveAppsOnly)
                    .onChange(of: dockActiveAppsOnly) { _, val in
                        UserDefaults.standard.set(val, forKey: PrefKey.dockActiveAppsOnly)
                        NotificationCenter.default.post(name: NSNotification.Name("NexusDockActiveAppsOnlyChanged"), object: val)
                    }
                Toggle("Show Folder Stacks", isOn: $dockShowFolderStacks)
                    .onChange(of: dockShowFolderStacks) { _, val in
                        UserDefaults.standard.set(val, forKey: PrefKey.dockShowFolderStacks)
                        NotificationCenter.default.post(name: NSNotification.Name("NexusDockShowFolderStacksChanged"), object: val)
                    }
                Toggle("Always Show Finder", isOn: $dockAlwaysShowFinder)
                Toggle("Always Show Trash", isOn: $dockAlwaysShowTrash)
            }

            Divider()
            Divider()
            Button(action: {
                desktopFilesManager.toggleDesktopFiles()
                HapticFeedback.selection()
            }) {
                HStack {
                    Image(systemName: desktopFilesManager.areDesktopFilesVisible ? "eye.slash" : "eye")
                    Text(desktopFilesManager.areDesktopFilesVisible ? "Hide Desktop Files (⌘⇧D)" : "Show Desktop Files (⌘⇧D)")
                }
            }
            Divider()
            Menu(LocalizedStrings.translateText("Battery Style", lang: appLanguage)) {
                ForEach(batteryCategories, id: \.name) { cat in
                    Menu(cat.name) {
                        ForEach(cat.styles, id: \.self) { style in
                            Button(action: { selectBatteryStyle(style) }) {
                                HStack {
                                    Text(style)
                                    if batteryStyle == style { Text("✓") }
                                }
                            }
                        }
                    }
                }
            }
            Toggle(LocalizedStrings.translateText("Show Battery Percentage (%)", lang: appLanguage), isOn: $showBatteryPercentage)
            Toggle(LocalizedStrings.translateText("Show Charging Bolt (⚡)", lang: appLanguage), isOn: $showChargingBolt)
                .onChange(of: showChargingBolt) { _, val in
                    UserDefaults.standard.set(val, forKey: PrefKey.showChargingBolt)
                    NotificationCenter.default.post(name: NSNotification.Name("NexusShowChargingBoltChanged"), object: val)
                    AppDelegate.shared?.renderIcon()
                }
            Menu(LocalizedStrings.translateText("Percentage Color", lang: appLanguage)) {
                ForEach(["Dynamic Level", "Pure White", "Neon Cyan", "Emerald Green", "Solar Orange", "Cyber Pink", "Electric Violet"], id: \.self) { mode in
                    Button(action: {
                        batteryColorMode = mode
                        UserDefaults.standard.set(mode, forKey: PrefKey.batteryColorMode)
                        AppDelegate.shared?.renderIcon()
                    }) {
                        HStack {
                            Text(mode)
                            if batteryColorMode == mode { Text("✓") }
                        }
                    }
                }
            }
            Divider()
            Button("Activity Monitor...") {
                NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app"))
            }
            Button("Force Quit Applications...") {
                MenuBarActionDispatcher.shared.openForceQuit()
            }
            Button("Lock Screen (⌃⌘Q)") {
                MenuBarActionDispatcher.shared.lockScreenAction()
            }
            Button("Sleep Mac") {
                MenuBarActionDispatcher.shared.sleepMacAction()
            }
            Divider()
            Button(LocalizedStrings.translateText("Genie Settings...", lang: appLanguage)) {
                openBatterySettings()
            }
            Divider()
            Button(LocalizedStrings.translateText("Quit Genie", lang: appLanguage)) {
                NSApplication.shared.terminate(nil)
            }
        }
    }

    @ViewBuilder
    private var cloudMenuView: some View {
        Menu {
            Section("💻 Genie Local AI") {
                ForEach(LocalModelManager.cloudModels) { model in
                    Button(action: {
                        LocalModelManager.shared.selectModel(model.id)
                        DesktopWindowManager.shared.switchToStation(.chat)
                    }) {
                        HStack {
                            Text(model.displayName)
                            if LocalModelManager.shared.effectiveModel == model.id {
                                Text("✓")
                            }
                        }
                    }
                }
            }
            Divider()
            Section("Workspaces") {
                Button("Chat & Dialogue...") {
                    DesktopWindowManager.shared.switchToStation(.chat)
                }
                Button("Applications Grid...") {
                    DesktopWindowManager.shared.switchToStation(.applications)
                }
                Button("Desktop Canvas...") {
                    DesktopWindowManager.shared.switchToStation(.desktop)
                }
                Divider()
                Button("Genie Settings...") {
                    AppDelegate.shared?.showMenuBarSettingsDropdown(targetTab: .workspace)
                }
            }
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 6.0, style: .continuous)
                    .fill(isCloudHovered ? Color.white.opacity(0.20) : Color.white.opacity(0.06))
                    .frame(width: 22, height: 22)

                Image(systemName: "cloud.fill")
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundColor(.white.opacity(isCloudHovered ? 1.0 : 0.85))
                    .scaleEffect(isCloudHovered ? 1.12 : 1.0)
            }
            .frame(width: 22, height: 22)
            .contentShape(RoundedRectangle(cornerRadius: 6.0, style: .continuous))
        }
        .menuStyle(.borderlessButton)
        .onHover { h in withAnimation(.spring(response: 0.20, dampingFraction: 0.75)) { isCloudHovered = h } }
        .help("AI Models & Workspaces")
    }

    @ViewBuilder
    private var switcherItemView: some View {
        let sWave = magnificationWave(for: "switcher")
        let isHovered = (hoveredItemId == "switcher" || isSwitcherHovered)
        Button(action: {
            HapticFeedback.selection()
            DesktopWindowManager.shared.cycleWorkspaceSwitcher()
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 6.0, style: .continuous)
                    .fill(isHovered ? Color.white.opacity(0.20) : Color.white.opacity(0.06))
                    .frame(width: 22, height: 22)

                Image(systemName: switcherSymbol)
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundColor(.white.opacity(isHovered ? 1.0 : 0.85))
                    .scaleEffect(isHovered ? 1.12 : 1.0)
            }
            .frame(width: 22, height: 22)
            .scaleEffect(sWave.scale, anchor: .top)
            .offset(x: magnificationDisplacement(for: "switcher"), y: sWave.yOffset)
            .contentShape(RoundedRectangle(cornerRadius: 6.0, style: .continuous))
        }
        .buttonStyle(DockIconButtonStyle())
        .zIndex(sWave.zIndex)
        .onHover { h in
            isSwitcherHovered = h
            handleItemHover(id: "switcher", hovering: h)
        }
        .help(switcherHelpText)
        .contextMenu {
            Button(action: {
                DesktopWindowManager.shared.switchToStation(.chat)
            }) {
                HStack {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                    Text("Chat & Dialogue Studio")
                    if DesktopWindowManager.shared.currentStation == .chat { Text("✓") }
                }
            }
            Button(action: {
                DesktopWindowManager.shared.switchToStation(.applications)
            }) {
                HStack {
                    Image(systemName: "square.grid.3x3.fill")
                    Text("Applications Atelier & Formations")
                    if DesktopWindowManager.shared.currentStation == .applications { Text("✓") }
                }
            }
            Button(action: {
                DesktopWindowManager.shared.switchToStation(.desktop)
            }) {
                HStack {
                    Image(systemName: "macwindow")
                    Text("Desktop Canvas")
                    if DesktopWindowManager.shared.currentStation == .desktop { Text("✓") }
                }
            }
            Divider()
            Button(LocalizedStrings.translateText("Next Workspace Station ❯", lang: appLanguage)) {
                HapticFeedback.selection()
                DesktopWindowManager.shared.cycleWorkspaceSwitcher()
            }
            Divider()
            Button(LocalizedStrings.translateText("Genie Settings...", lang: appLanguage)) {
                AppDelegate.shared?.showMenuBarSettingsDropdown(targetTab: .workspace)
            }
        }
    }

    private var switcherSymbol: String {
        switch DesktopWindowManager.shared.currentStation {
        case .desktop: return "macwindow"
        case .chat: return "bubble.left.and.bubble.right.fill"
        case .applications: return "square.grid.3x3.fill"
        }
    }

    private var switcherHelpText: String {
        switch DesktopWindowManager.shared.currentStation {
        case .desktop: return "Desktop Canvas — Click to switch to Chat (⌘⇧D)"
        case .chat: return "Dialogue Studio — Click to switch to Applications (⌘⇧D)"
        case .applications: return "Application Atelier — Click to return to Desktop (⌘⇧D)"
        }
    }

    @ViewBuilder
    private var tuckedColorsAndFontsMenu: some View {
        Menu(LocalizedStrings.translateText("🎨 Colors & Fonts", lang: appLanguage)) {
            Button(action: {
                menuBarColorsEnabled.toggle()
                UserDefaults.standard.set(menuBarColorsEnabled, forKey: PrefKey.menuBarColorsEnabled)
                UserDefaults.standard.synchronize()
                NotificationCenter.default.post(name: NSNotification.Name("NexusMenuBarThemeChanged"), object: nil)
            }) {
                HStack {
                    Text(menuBarColorsEnabled ? LocalizedStrings.translateText("Colors: Enabled (Custom Accent)", lang: appLanguage) : LocalizedStrings.translateText("Colors: Disabled (Classic Apple White)", lang: appLanguage))
                    if menuBarColorsEnabled { Text("✓") }
                }
            }

            Divider()

            Menu(LocalizedStrings.translateText("Color Presets", lang: appLanguage)) {
                Button("⚪️ Classic Apple White (Colors Off)") {
                    menuBarColorsEnabled = false
                    textColorName = "Pure White ⚪️"
                    activeAppColorName = "Pure White ⚪️"
                    UserDefaults.standard.set(false, forKey: PrefKey.menuBarColorsEnabled)
                    UserDefaults.standard.set("Pure White ⚪️", forKey: PrefKey.menuBarTextColor)
                    UserDefaults.standard.set("Pure White ⚪️", forKey: PrefKey.menuBarActiveAppColor)
                    UserDefaults.standard.synchronize()
                    NotificationCenter.default.post(name: NSNotification.Name("NexusMenuBarThemeChanged"), object: nil)
                }
                Button("⚡️💖 Cyberpunk (Neon Cyan & Hot Pink)") {
                    menuBarColorsEnabled = true
                    activeAppColorName = "Neon Cyan ⚡️"
                    textColorName = "Hot Pink 💖"
                    UserDefaults.standard.set(true, forKey: PrefKey.menuBarColorsEnabled)
                    UserDefaults.standard.set("Neon Cyan ⚡️", forKey: PrefKey.menuBarActiveAppColor)
                    UserDefaults.standard.set("Hot Pink 💖", forKey: PrefKey.menuBarTextColor)
                    UserDefaults.standard.synchronize()
                    NotificationCenter.default.post(name: NSNotification.Name("NexusMenuBarThemeChanged"), object: nil)
                }
                Button("👑☀️ Royal Gold & Solar Amber") {
                    menuBarColorsEnabled = true
                    activeAppColorName = "Royal Gold 👑"
                    textColorName = "Solar Amber ☀️"
                    UserDefaults.standard.set(true, forKey: PrefKey.menuBarColorsEnabled)
                    UserDefaults.standard.set("Royal Gold 👑", forKey: PrefKey.menuBarActiveAppColor)
                    UserDefaults.standard.set("Solar Amber ☀️", forKey: PrefKey.menuBarTextColor)
                    UserDefaults.standard.synchronize()
                    NotificationCenter.default.post(name: NSNotification.Name("NexusMenuBarThemeChanged"), object: nil)
                }
                Button("🟢 Matrix Emerald") {
                    menuBarColorsEnabled = true
                    activeAppColorName = "Emerald Matrix 🟢"
                    textColorName = "Emerald Matrix 🟢"
                    UserDefaults.standard.set(true, forKey: PrefKey.menuBarColorsEnabled)
                    UserDefaults.standard.set("Emerald Matrix 🟢", forKey: PrefKey.menuBarActiveAppColor)
                    UserDefaults.standard.set("Emerald Matrix 🟢", forKey: PrefKey.menuBarTextColor)
                    UserDefaults.standard.synchronize()
                    NotificationCenter.default.post(name: NSNotification.Name("NexusMenuBarThemeChanged"), object: nil)
                }
                Button("💜🔵 Soft Lilac & Blue") {
                    menuBarColorsEnabled = true
                    activeAppColorName = "Classic Blue 🔵"
                    textColorName = "Soft Lilac 💜"
                    UserDefaults.standard.set(true, forKey: PrefKey.menuBarColorsEnabled)
                    UserDefaults.standard.set("Classic Blue 🔵", forKey: PrefKey.menuBarActiveAppColor)
                    UserDefaults.standard.set("Soft Lilac 💜", forKey: PrefKey.menuBarTextColor)
                    UserDefaults.standard.synchronize()
                    NotificationCenter.default.post(name: NSNotification.Name("NexusMenuBarThemeChanged"), object: nil)
                }
            }

            Menu(LocalizedStrings.translateText("Menu Items Color", lang: appLanguage)) {
                ForEach(MenuBarThemeManager.textColorOptions, id: \.self) { colorOpt in
                    Button(action: {
                        menuBarColorsEnabled = true
                        textColorName = colorOpt
                        UserDefaults.standard.set(true, forKey: PrefKey.menuBarColorsEnabled)
                        UserDefaults.standard.set(colorOpt, forKey: PrefKey.menuBarTextColor)
                        UserDefaults.standard.synchronize()
                        NotificationCenter.default.post(name: NSNotification.Name("NexusMenuBarThemeChanged"), object: nil)
                    }) {
                        HStack {
                            Text(colorOpt)
                            if textColorName == colorOpt && menuBarColorsEnabled { Text("✓") }
                        }
                    }
                }
            }

            Menu(LocalizedStrings.translateText("Active App Color", lang: appLanguage)) {
                ForEach(MenuBarThemeManager.activeAppColorOptions, id: \.self) { colorOpt in
                    Button(action: {
                        menuBarColorsEnabled = true
                        activeAppColorName = colorOpt
                        UserDefaults.standard.set(true, forKey: PrefKey.menuBarColorsEnabled)
                        UserDefaults.standard.set(colorOpt, forKey: PrefKey.menuBarActiveAppColor)
                        UserDefaults.standard.synchronize()
                        NotificationCenter.default.post(name: NSNotification.Name("NexusMenuBarThemeChanged"), object: nil)
                    }) {
                        HStack {
                            Text(colorOpt)
                            if activeAppColorName == colorOpt && menuBarColorsEnabled { Text("✓") }
                        }
                    }
                }
            }

            Divider()

            Menu(LocalizedStrings.translateText("Font Family", lang: appLanguage)) {
                ForEach(MenuBarThemeManager.fontFamilyOptions, id: \.self) { fam in
                    Button(action: {
                        fontFamily = fam
                        UserDefaults.standard.set(fam, forKey: PrefKey.menuBarFontFamily)
                        UserDefaults.standard.synchronize()
                        NotificationCenter.default.post(name: NSNotification.Name("NexusMenuBarThemeChanged"), object: nil)
                        NotificationCenter.default.post(name: NSNotification.Name("NexusMenuBarFontFamilyChanged"), object: fam)
                    }) {
                        HStack {
                            Text(fam)
                            if fontFamily == fam { Text("✓") }
                        }
                    }
                }
            }

            Menu(LocalizedStrings.translateText("Font Weight", lang: appLanguage)) {
                ForEach(MenuBarThemeManager.fontWeightOptions, id: \.self) { weight in
                    Button(action: {
                        fontWeight = weight
                        UserDefaults.standard.set(weight, forKey: PrefKey.menuBarFontWeight)
                        UserDefaults.standard.synchronize()
                        NotificationCenter.default.post(name: NSNotification.Name("NexusMenuBarThemeChanged"), object: nil)
                    }) {
                        HStack {
                            Text(weight)
                            if fontWeight == weight { Text("✓") }
                        }
                    }
                }
            }

            Menu(LocalizedStrings.translateText("Font Size", lang: appLanguage)) {
                ForEach(MenuBarThemeManager.fontSizeOptions, id: \.self) { sz in
                    Button(action: {
                        menuBarFontSize = sz
                        UserDefaults.standard.set(sz, forKey: PrefKey.menuBarFontSize)
                        UserDefaults.standard.synchronize()
                        NotificationCenter.default.post(name: NSNotification.Name("NexusMenuBarThemeChanged"), object: nil)
                    }) {
                        HStack {
                            Text("\(Int(sz)) pt" + (sz == 12.0 ? " (Default)" : ""))
                            if menuBarFontSize == sz { Text("✓") }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var dockContextMenu: some View {
        Button(LocalizedStrings.translateText("Genie Settings...", lang: appLanguage)) {
            openGenieSettings()
        }
        Button(LocalizedStrings.translateText("Applications...", lang: appLanguage)) {
            toggleApplicationsOverlay()
        }
        Divider()
        tuckedColorsAndFontsMenu
        Divider()
        Menu(LocalizedStrings.translateText("Workspaces", lang: appLanguage)) {
            Button(LocalizedStrings.translateText("Chat & Dialogue", lang: appLanguage)) {
                DesktopWindowManager.shared.switchToStation(.chat)
            }
            Button(LocalizedStrings.translateText("Applications Grid", lang: appLanguage)) {
                DesktopWindowManager.shared.switchToStation(.applications)
            }
            Button(LocalizedStrings.translateText("Desktop Canvas", lang: appLanguage)) {
                DesktopWindowManager.shared.switchToStation(.desktop)
            }
        }
        Menu(LocalizedStrings.translateText("Mini Dock Style", lang: appLanguage)) {
            ForEach(["Apple Liquid Glass", "Frosted Glass", "Dark Obsidian Glass", "Neon Aurora Glass", "Clear (Transparent)"], id: \.self) { style in
                Button(style) {
                    miniDockBackgroundStyle = style
                    UserDefaults.standard.set(style, forKey: PrefKey.miniDockBackgroundStyle)
                    NotificationCenter.default.post(name: NSNotification.Name("NexusMiniDockStyleChanged"), object: style)
                    AppDelegate.shared?.renderIcon()
                }
            }
        }
        Menu(LocalizedStrings.translateText("Mini Dock Mode", lang: appLanguage)) {
            Button(action: {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                    miniDockDisplayMode = "Always Shown"
                    UserDefaults.standard.set("Always Shown", forKey: PrefKey.miniDockDisplayMode)
                    NotificationCenter.default.post(name: NSNotification.Name("NexusMiniDockModeChanged"), object: "Always Shown")
                }
            }) {
                HStack {
                    Text("Always On (Permanently Shown)")
                    if !isHiddenMode { Text("✓") }
                }
            }
            Button(action: {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                    miniDockDisplayMode = "Always Hidden"
                    UserDefaults.standard.set("Always Hidden", forKey: PrefKey.miniDockDisplayMode)
                    NotificationCenter.default.post(name: NSNotification.Name("NexusMiniDockModeChanged"), object: "Always Hidden")
                }
            }) {
                HStack {
                    Text("Always Hidden (Pops Down on Hover)")
                    if isHiddenMode { Text("✓") }
                }
            }
        }
        Button(LocalizedStrings.translateText(isHiddenMode ? "Enable Always On" : "Always Hide (Pop Down)", lang: appLanguage)) {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                let newMode = isHiddenMode ? "Always Shown" : "Always Hidden"
                miniDockDisplayMode = newMode
                UserDefaults.standard.set(newMode, forKey: PrefKey.miniDockDisplayMode)
                NotificationCenter.default.post(name: NSNotification.Name("NexusMiniDockModeChanged"), object: newMode)
            }
        }
        Divider()
        Button(action: {
            dockActiveAppsOnly.toggle()
            UserDefaults.standard.set(dockActiveAppsOnly, forKey: PrefKey.dockActiveAppsOnly)
            NotificationCenter.default.post(name: NSNotification.Name("NexusDockActiveAppsOnlyChanged"), object: dockActiveAppsOnly)
            refreshApps()
        }) {
            if dockActiveAppsOnly {
                Text(LocalizedStrings.translateText("Active Applications Only ✓", lang: appLanguage))
            } else {
                Text(LocalizedStrings.translateText("Show All Dock Items", lang: appLanguage))
            }
        }
        Divider()
        Button(LocalizedStrings.translateText("Quit Genie", lang: appLanguage)) {
            NSApplication.shared.terminate(nil)
        }
    }

    private func openNativeFinder() {
        let expandedPath = (barFolderPath as NSString).expandingTildeInPath
        let folderURL = URL(fileURLWithPath: expandedPath)
        let targetURL = FileManager.default.fileExists(atPath: folderURL.path) ? folderURL : FileManager.default.homeDirectoryForCurrentUser
        let finderBundleURL = URL(fileURLWithPath: "/System/Library/CoreServices/Finder.app")

        // 1. Direct frontmost activation for Finder process (Dock Parity)
        if let finderApp = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.finder").first {
            finderApp.unhide()
            finderApp.activate(options: [.activateAllWindows])
        }

        // 2. Open configured folder with Finder application bundle
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        config.addsToRecentItems = false
        NSWorkspace.shared.open([targetURL], withApplicationAt: finderBundleURL, configuration: config) { _, error in
            if error != nil {
                DispatchQueue.main.async {
                    NSWorkspace.shared.openApplication(at: finderBundleURL, configuration: config, completionHandler: nil)
                    _ = NSWorkspace.shared.open(targetURL)
                }
            }
        }
    }

    private func chooseFolderDestinationDirectly() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.canCreateDirectories = true
        panel.prompt = "Select Folder"
        panel.message = "Choose folder destination for Mini Dock"
        panel.level = NSWindow.Level(rawValue: max(NSWindow.Level.statusBar.rawValue, NSWindow.Level.floating.rawValue) + 50)

        if let screen = NSScreen.main {
            let visFrame = screen.visibleFrame
            let panelW: CGFloat = 620
            let panelH: CGFloat = 460
            let posX = visFrame.midX - (panelW / 2)
            let posY = max(visFrame.minY + 50, visFrame.midY - (panelH / 2) - 80)
            panel.setFrame(NSRect(x: posX, y: posY, width: panelW, height: panelH), display: true)
        }

        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)

        panel.begin { response in
            if response == .OK, let selectedURL = panel.url {
                barFolderPath = selectedURL.path
                HapticFeedback.selection()
            }
        }
    }

    private func openNativeTrash() {
        MenuBarActionDispatcher.shared.openNativeTrash()
    }

    private func emptyNativeTrash() {
        MenuBarActionDispatcher.shared.emptyNativeTrash()
    }

    private func activateApp(_ item: DockAppItem) {
        if item.bundleIdentifier == "com.nicholasdudek.genie" || item.id == "com.nicholasdudek.genie" || item.name.lowercased() == "genie" {
            HapticFeedback.selection()
            FinderChatWindowManager.shared.toggle()
            return
        }
        if item.id == "com.apple.Terminal" || item.name.lowercased() == "terminal" {
            let termURL = URL(fileURLWithPath: "/System/Applications/Utilities/Terminal.app")
            NSWorkspace.shared.open(termURL)
            return
        }
        if item.processIdentifier > 0 {
            dockManager.activePid = item.processIdentifier
        }
        withAnimation(.spring(response: 0.28, dampingFraction: 0.45)) {
            bouncingItemId = item.id
        }
        if smokeEffectsEnabled {
            smokingItemId = item.id
            GenieSmokeEngine.shared.triggerBurst(
                origin: .dock,
                bounds: AppDelegate.shared?.menuBarPanel?.frame.size ?? CGSize(width: 880, height: 600),
                style: smokeStyle,
                count: 24
            )
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            if bouncingItemId == item.id { bouncingItemId = nil }
            if smokingItemId == item.id { smokingItemId = nil }
        }

        MenuBarActionDispatcher.shared.handleAppClick(item)
    }

    private func activateApp(_ app: NSRunningApplication) {
        dockManager.activePid = app.processIdentifier
        MenuBarActionDispatcher.shared.activateApp(app)

        let itemId = app.bundleIdentifier ?? "\(app.processIdentifier)"
        if smokeEffectsEnabled {
            smokingItemId = itemId
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                if smokingItemId == itemId {
                    smokingItemId = nil
                }
            }
            GenieSmokeEngine.shared.triggerBurst(
                origin: .dock,
                bounds: AppDelegate.shared?.menuBarPanel?.frame.size ?? CGSize(width: 880, height: 600),
                style: smokeStyle,
                count: 24
            )
        }
        withAnimation(.spring(response: 0.20, dampingFraction: 0.45)) {
            bouncingItemId = itemId
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
            if bouncingItemId == itemId {
                bouncingItemId = nil
            }
        }

        gridManager.bringToFront(app: app)
    }

    // MARK: - Dedicated Subviews for Fast Type-Checking & Modularity

    private func horizontalDisplacement(for item: DockAppItem) -> CGFloat {
        guard let draggingId = draggingItemId, draggingId != item.id else { return 0 }
        guard let fromIndex = dockItems.firstIndex(where: { $0.id == draggingId }),
              let myIndex = dockItems.firstIndex(where: { $0.id == item.id }) else { return 0 }
        let slotWidth: CGFloat = 27.0
        let offsetSlots = Int(round(dragOffset / slotWidth))
        let targetIndex = max(0, min(dockItems.count - 1, fromIndex + offsetSlots))
        if targetIndex > fromIndex && myIndex > fromIndex && myIndex <= targetIndex {
            return -slotWidth
        } else if targetIndex < fromIndex && myIndex < fromIndex && myIndex >= targetIndex {
            return slotWidth
        }
        return 0
    }

    private func saveCustomDockOrder() {
        let order = dockItems.map { $0.id }
        UserDefaults.standard.set(order, forKey: PrefKey.customDockAppOrder)

        // Sync real macOS System Dock persistent-apps order
        let identifiers = dockItems.compactMap { item -> String? in
            item.bundleIdentifier ?? item.name
        }
        DockAndDesktopManager.shared.syncDockAppOrder(orderedIdentifiers: identifiers)
    }

    private func moveDockItem(id: String, direction: Int) {
        guard let idx = dockItems.firstIndex(where: { $0.id == id }) else { return }
        let newIdx = idx + direction
        guard newIdx >= 0 && newIdx < dockItems.count else { return }
        withAnimation(.spring(response: 0.25, dampingFraction: 0.78)) {
            dockManager.reorder(fromIndex: idx, toIndex: newIdx)
            HapticFeedback.selection()
        }
    }

    @ViewBuilder
    private func dockAppItemView(item: DockAppItem) -> some View {
        let wave = magnificationWave(for: item.id)
        let isBouncing = bouncingItemId == item.id
        let isHovered = hoveredItemId == item.id
        let isSmoking = smokingItemId == item.id
        let isCurrentActive = (item.runningApp != nil && (activePid == item.processIdentifier || item.runningApp?.isActive == true))
        let isDragging = (draggingItemId == item.id)
        let neighborOffset = horizontalDisplacement(for: item)
        let magOffset = magnificationDisplacement(for: item.id)
        let totalXOffset = isDragging ? dragOffset : (neighborOffset + magOffset)

        Button(action: {
            activateApp(item)
        }) {
            dockAppButtonContent(item: item, isHovered: isHovered, isBouncing: isBouncing, isSmoking: isSmoking, isCurrentActive: isCurrentActive)
                .frame(width: 28, height: 28)
                .scaleEffect(
                    isDragging ? (isDragOffThreshold ? 0.75 : 1.22) : (wave.scale * (isBouncing ? 1.28 : 1.0)),
                    anchor: .center
                )
                .offset(x: totalXOffset, y: isDragging ? dragYOffset : wave.yOffset)
                .opacity(isDragging && isDragOffThreshold ? 0.45 : 1.0)
                .shadow(color: isDragging ? Color.cyan.opacity(0.75) : Color.clear, radius: isDragging ? 6 : 0)
                .contentShape(Rectangle())
        }
        .background(
            GeometryReader { geo in
                Color.clear.preference(
                    key: AppFramesKey.self,
                    value: [AppFrameItem(id: item.id, pid: item.processIdentifier, frame: geo.frame(in: .named("StripRoot")))]
                )
            }
        )
        .buttonStyle(DockIconButtonStyle())
        .zIndex(isDragging ? 100 : wave.zIndex)
        .simultaneousGesture(
            DragGesture(minimumDistance: 14)
                .onChanged { val in
                    if draggingItemId == nil {
                        draggingItemId = item.id
                        HapticFeedback.selection()
                    }
                    withAnimation(.spring(response: 0.20, dampingFraction: 0.8)) {
                        dragOffset = val.translation.width
                        dragYOffset = val.translation.height
                        isDragOffThreshold = abs(val.translation.height) > 28.0
                    }
                }
                .onEnded { val in
                    let isOff = abs(val.translation.height) > 28.0
                    if isOff {
                        // Dragged off the menu bar downwards -> Remove from dock!
                        HapticFeedback.heavy()
                        NSSound(named: "Basso")?.play()
                        dockManager.removeDockItem(item)
                        if smokeEffectsEnabled {
                            GenieSmokeEngine.shared.triggerBurst(
                                origin: .dock,
                                bounds: AppDelegate.shared?.menuBarPanel?.frame.size ?? CGSize(width: 880, height: 600),
                                style: smokeStyle,
                                count: 28
                            )
                        }
                    } else if abs(val.translation.width) < 8.0 && abs(val.translation.height) < 8.0 {
                        // Micro-movement / tap release: activate the app directly!
                        activateApp(item)
                    } else if let draggingId = draggingItemId,
                       let fromIndex = dockItems.firstIndex(where: { $0.id == draggingId }) {
                        let slotWidth: CGFloat = 30.0
                        let offsetSlots = Int(round(val.translation.width / slotWidth))
                        let targetIndex = max(0, min(dockItems.count - 1, fromIndex + offsetSlots))
                        if targetIndex != fromIndex {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.78)) {
                                dockManager.reorder(fromIndex: fromIndex, toIndex: targetIndex)
                                HapticFeedback.selection()
                            }
                        }
                    }
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.78)) {
                        draggingItemId = nil
                        dragOffset = 0
                        dragYOffset = 0
                        isDragOffThreshold = false
                    }
                }
        )
        .onHover { hovering in
            handleItemHover(id: item.id, hovering: hovering)
        }
        .help(menuBarDockInactiveAppsOnly ? "\(item.name) (Background) — Click to switch to application" : (item.isRunning ? "\(item.name) — Click to bring to front, drag to reorder or drag off to remove" : "\(item.name) — Click to launch, drag to reorder or drag off to remove"))
        .contextMenu {
            dockAppContextMenu(item: item)
        }
    }

    @ViewBuilder
    private func dockAppButtonContent(item: DockAppItem, isHovered: Bool, isBouncing: Bool, isSmoking: Bool, isCurrentActive: Bool) -> some View {
        ZStack(alignment: .center) {
            // Radiant Genie Aura Glow
            if isHovered || isBouncing {
                Circle()
                    .fill(
                        RadialGradient(
                            gradient: Gradient(colors: [
                                Color(red: 0.0, green: 0.85, blue: 1.0).opacity(isBouncing ? 0.70 : 0.40),
                                Color(red: 1.0, green: 0.82, blue: 0.20).opacity(isBouncing ? 0.50 : 0.20),
                                Color.clear
                            ]),
                            center: .center,
                            startRadius: 1,
                            endRadius: 16
                        )
                    )
                    .frame(width: 32, height: 32)
                    .blur(radius: 3)
            }

            // Dock-style slot highlight on hover
            RoundedRectangle(cornerRadius: 6.5, style: .continuous)
                .fill(isHovered ? Color.white.opacity(0.18) : Color.clear)
                .frame(width: 26, height: 26)

            VStack(spacing: 1.5) {
                ZStack(alignment: .bottomTrailing) {
                    if let icon = item.icon {
                        Image(nsImage: icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 21, height: 21)
                    } else {
                        Image(systemName: "app.dashed")
                            .font(.system(size: 14))
                            .frame(width: 21, height: 21)
                    }
                }
                .shadow(
                    color: Color.black.opacity(isHovered ? 0.45 : 0.18),
                    radius: isHovered ? 2.5 : 0.8,
                    y: isHovered ? 1.2 : 0.8
                )

                // macOS Dock Running Indicator Dot (Native Apple translucent white)
                if item.isRunning {
                    Circle()
                        .fill(Color.white.opacity(isCurrentActive ? 1.0 : 0.65))
                        .frame(width: isCurrentActive ? 3.0 : 2.2, height: isCurrentActive ? 3.0 : 2.2)
                        .shadow(
                            color: Color.black.opacity(0.35),
                            radius: 0.5,
                            y: 0.5
                        )
                } else {
                    Spacer().frame(height: 2.2)
                }
            }

            if smokeEffectsEnabled && isSmoking {
                let (prim, _, _) = GenieSmokeEngine.colors(for: smokeStyle)
                MiniDockSmokePuffView(color: prim)
            }

            // Instant hover close badge to remove/hide app from menu bar pill
            if isHovered {
                Button(action: {
                    dockManager.hideDockItem(id: item.id)
                    if let bid = item.bundleIdentifier {
                        dockManager.hideDockItem(id: bid)
                    }
                    HapticFeedback.selection()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white.opacity(0.95))
                        .background(Circle().fill(Color.black.opacity(0.85)))
                }
                .buttonStyle(.plain)
                .offset(x: 9, y: -9)
                .help("Remove \(item.name) from bar")
            }
        }
    }

    @ViewBuilder
    private func dockAppContextMenu(item: DockAppItem) -> some View {
        Button("Remove \(item.name) from Bar") {
            dockManager.hideDockItem(id: item.id)
            if let bid = item.bundleIdentifier {
                dockManager.hideDockItem(id: bid)
            }
            HapticFeedback.selection()
        }

        if menuBarDockInactiveAppsOnly {
            Text("\(item.name) • Background Application")
            Divider()
        }
        if item.bundleIdentifier == "com.nicholasdudek.genie" || item.id == "com.nicholasdudek.genie" || item.name.lowercased() == "genie" {
            Button("Genie Chat & Settings (⌘⌥Space)") {
                FinderChatWindowManager.shared.toggle()
            }
            Button("Toggle Architectural Canvas (⌘⇧D)") {
                NotificationCenter.default.post(name: NSNotification.Name("NexusToggleDesktopGrid"), object: nil)
            }
            Divider()
        }
        if let app = item.runningApp, !app.isTerminated {
            Button(LocalizedStrings.translateText("Bring All to Front", lang: appLanguage)) {
                app.unhide()
                _ = app.activate(options: [.activateAllWindows])
                gridManager.bringToFront(app: app)
            }
            Button(LocalizedStrings.translateText("Show All Windows", lang: appLanguage)) {
                app.unhide()
                _ = app.activate(options: [.activateAllWindows])
                gridManager.bringToFront(app: app)
            }
            if app.isHidden {
                Button(LocalizedStrings.translateText("Unhide", lang: appLanguage)) {
                    app.unhide()
                    _ = app.activate()
                }
            } else {
                Button(LocalizedStrings.translateText("Hide", lang: appLanguage)) {
                    app.hide()
                }
            }
            Button(LocalizedStrings.translateText("Quit", lang: appLanguage)) {
                app.terminate()
            }
            Button(LocalizedStrings.translateText("Force Quit", lang: appLanguage)) {
                app.forceTerminate()
            }
            Divider()
            Button(LocalizedStrings.translateText("Show in Finder", lang: appLanguage)) {
                let targetURL = app.bundleURL ?? (app.bundleIdentifier != nil ? NSWorkspace.shared.urlForApplication(withBundleIdentifier: app.bundleIdentifier!) : nil)
                if let url = targetURL {
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                }
            }
        } else {
            Button("\(LocalizedStrings.translateText("Open", lang: appLanguage)) \(item.name)") {
                activateApp(item)
            }
            if let url = item.bundleURL {
                Button(LocalizedStrings.translateText("Show in Finder", lang: appLanguage)) {
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                }
            }
        }
        Divider()
        Menu(LocalizedStrings.translateText("Move to Screen", lang: appLanguage)) {
            ForEach(Array(NSScreen.screens.enumerated()), id: \.offset) { index, screen in
                Button(LocalizedStrings.translateText("Screen \(index + 1) (\(screen.localizedName))", lang: appLanguage)) {
                    ScreenWarpManager.shared.moveAppWindowsToScreen(pid: item.processIdentifier, targetScreenIndex: index)
                }
            }
            Divider()
            Button(LocalizedStrings.translateText("Next Screen (⌃⌥→)", lang: appLanguage)) {
                ScreenWarpManager.shared.moveAppWindowsToNextScreen(pid: item.processIdentifier, direction: 1)
            }
            Button(LocalizedStrings.translateText("Previous Screen (⌃⌥←)", lang: appLanguage)) {
                ScreenWarpManager.shared.moveAppWindowsToNextScreen(pid: item.processIdentifier, direction: -1)
            }
        }
        Divider()
        Menu(LocalizedStrings.translateText("Reorder in Mini Dock", lang: appLanguage)) {
            Button(LocalizedStrings.translateText("Move Left (←)", lang: appLanguage)) {
                moveDockItem(id: item.id, direction: -1)
            }
            .disabled(dockItems.first?.id == item.id)

            Button(LocalizedStrings.translateText("Move Right (→)", lang: appLanguage)) {
                moveDockItem(id: item.id, direction: 1)
            }
            .disabled(dockItems.last?.id == item.id)

            Divider()

            Button(LocalizedStrings.translateText("Reset to System Dock Order", lang: appLanguage)) {
                UserDefaults.standard.removeObject(forKey: PrefKey.customDockAppOrder)
                refreshApps()
            }
        }
        Button(LocalizedStrings.translateText("Remove from Mini Dock", lang: appLanguage)) {
            removeDockItem(item)
        }
        Menu(LocalizedStrings.translateText("Mini Dock Options", lang: appLanguage)) {
            Menu(LocalizedStrings.translateText("App Display Filter", lang: appLanguage)) {
                Button(action: {
                    dockActiveAppsOnly = false
                    UserDefaults.standard.set(false, forKey: PrefKey.dockActiveAppsOnly)
                    NotificationCenter.default.post(name: NSNotification.Name("NexusDockActiveAppsOnlyChanged"), object: false)
                    refreshApps()
                }) {
                    HStack {
                        Text(LocalizedStrings.translateText("Show All (Running & Pinned)", lang: appLanguage))
                        if !dockActiveAppsOnly { Text("✓") }
                    }
                }
                Button(action: {
                    dockActiveAppsOnly = true
                    UserDefaults.standard.set(true, forKey: PrefKey.dockActiveAppsOnly)
                    NotificationCenter.default.post(name: NSNotification.Name("NexusDockActiveAppsOnlyChanged"), object: true)
                    refreshApps()
                }) {
                    HStack {
                        Text(LocalizedStrings.translateText("Active Applications Only", lang: appLanguage))
                        if dockActiveAppsOnly { Text("✓") }
                    }
                }
            }
            Divider()
            Toggle(LocalizedStrings.translateText("Always Show Finder", lang: appLanguage), isOn: Binding(
                get: { dockAlwaysShowFinder },
                set: { val in
                    dockAlwaysShowFinder = val
                    UserDefaults.standard.set(val, forKey: PrefKey.dockAlwaysShowFinder)
                    refreshApps()
                }
            ))
            Toggle(LocalizedStrings.translateText("Always Show Settings", lang: appLanguage), isOn: Binding(
                get: { dockAlwaysShowSettings },
                set: { val in
                    dockAlwaysShowSettings = val
                    UserDefaults.standard.set(val, forKey: PrefKey.dockAlwaysShowSettings)
                    refreshApps()
                }
            ))
            Toggle(LocalizedStrings.translateText("Always Show Trash", lang: appLanguage), isOn: Binding(
                get: { dockAlwaysShowTrash },
                set: { val in
                    dockAlwaysShowTrash = val
                    UserDefaults.standard.set(val, forKey: PrefKey.dockAlwaysShowTrash)
                    refreshApps()
                }
            ))
            Toggle(LocalizedStrings.translateText("Always Show Genie Hub", lang: appLanguage), isOn: Binding(
                get: { dockAlwaysShowGenie },
                set: { val in
                    dockAlwaysShowGenie = val
                    UserDefaults.standard.set(val, forKey: PrefKey.dockAlwaysShowGenie)
                    refreshApps()
                }
            ))
            Divider()
            Button(LocalizedStrings.translateText("Restore Hidden Apps (Reset Mini Dock)", lang: appLanguage)) {
                restoreAllHiddenDockApps()
            }
        }
        Divider()
        Button(LocalizedStrings.translateText("Genie Settings...", lang: appLanguage)) {
            openGenieSettings()
        }
    }

    private func removeDockItem(_ item: DockAppItem) {
        dockManager.removeDockItem(item)
    }

    private func restoreAllHiddenDockApps() {
        dockManager.restoreAllHiddenDockApps()
    }

    private func refreshApps() {
        dockManager.refreshDockApps()
    }

    private func openGenieSettings() {
        FinderChatWindowManager.shared.show(tab: .settings)
    }

    private func openBatterySettings() {
        AppDelegate.shared?.showMenuBarSettingsDropdown(targetTab: .battery)
    }

    private func toggleGenieNoteBar() {
        MenuBarActionDispatcher.shared.handleLeoClick()
    }

    private func toggleApplicationsOverlay() {
        if AppDelegate.shared?.menuBarPanel?.isVisible == true {
            AppDelegate.shared?.dismissMenuBarPopover()
        }
        NotificationCenter.default.post(name: NSNotification.Name("NexusToggleDesktopGrid"), object: nil)

        let smokeOn = UserDefaults.standard.object(forKey: PrefKey.smokeEffectsEnabled) == nil ? true : UserDefaults.standard.bool(forKey: PrefKey.smokeEffectsEnabled)
        if smokeOn {
            let targetScreen = NSScreen.main ?? (NSScreen.screens.first ?? NSScreen())
            GenieSmokeEngine.shared.triggerBurst(
                origin: .topGlyph(xPercent: 0.88),
                bounds: targetScreen.frame.size,
                style: smokeStyle,
                count: 36
            )
        }
    }
}

// MARK: - Mini Dock Smoke Puff Burst Effect
public struct MiniDockSmokePuffView: View {
    @AppStorage(PrefKey.appLanguage) var appLanguage: String = "English (US)"
let color: Color
    @State private var anim: CGFloat = 0.0

    public init(color: Color) {
        self.color = color
    }

    public var body: some View {
        ZStack {
            ForEach(0..<6) { i in
                let angle = Double(i) * (2.0 * .pi / 6.0)
                let dist = anim * 11.0
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                color.opacity(0.85 * (1.0 - anim)),
                                color.opacity(0.20 * (1.0 - anim)),
                                Color.clear
                            ],
                            center: .center,
                            startRadius: 1,
                            endRadius: 7
                        )
                    )
                    .frame(width: 8 + anim * 8, height: 8 + anim * 8)
                    .offset(x: cos(angle) * dist, y: sin(angle) * dist)
                    .blur(radius: 1.8)
            }
            // Sparkles
            ForEach(0..<4) { j in
                let sAngle = Double(j) * (2.0 * .pi / 4.0) + 0.35
                let sDist = anim * 13.0
                Circle()
                    .fill(Color.white.opacity(1.0 - anim))
                    .frame(width: 2.5, height: 2.5)
                    .offset(x: cos(sAngle) * sDist, y: sin(sAngle) * sDist)
                    .shadow(color: color, radius: 2)
            }
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.easeOut(duration: 0.26)) {
                anim = 1.0
            }
        }
    }
}

// MARK: - Dock Icon Button Style (Apple HIG Parity: Stable Hitbox, Zero Click Dropping)
public struct DockIconButtonStyle: ButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.72 : 1.0)
            .brightness(configuration.isPressed ? -0.06 : 0.0)
            .animation(.easeInOut(duration: 0.08), value: configuration.isPressed)
    }
}

// MARK: - Animated Charging Aura & Pulse View
public struct AnimatedChargingEffectView: View {
    @State private var isBreathing = false

    public init() {}

    public var body: some View {
        ZStack {
            // Ambient electrical aura pulse
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 1.0, green: 0.88, blue: 0.15).opacity(isBreathing ? 0.65 : 0.20),
                            Color(red: 0.20, green: 0.85, blue: 0.45).opacity(isBreathing ? 0.35 : 0.05),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 1,
                        endRadius: 9
                    )
                )
                .frame(width: 18, height: 18)
                .scaleEffect(isBreathing ? 1.25 : 0.85)

            // Neon glowing electric bolt
            Image(systemName: "bolt.fill")
                .font(.system(size: 9.5, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            Color.white,
                            Color(red: 1.0, green: 0.90, blue: 0.20),
                            Color(red: 0.30, green: 0.95, blue: 0.55)
                        ],
                        startPoint: isBreathing ? .top : .bottom,
                        endPoint: isBreathing ? .bottom : .top
                    )
                )
                .shadow(color: Color(red: 1.0, green: 0.85, blue: 0.15).opacity(isBreathing ? 0.90 : 0.40), radius: isBreathing ? 4.0 : 1.5, x: 0, y: 0)
                .shadow(color: Color(red: 0.20, green: 0.95, blue: 0.50).opacity(isBreathing ? 0.60 : 0.15), radius: 5.5, x: 0, y: 0)
                .scaleEffect(isBreathing ? 1.14 : 0.94)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.95).repeatForever(autoreverses: true)) {
                isBreathing = true
            }
        }
    }
}



