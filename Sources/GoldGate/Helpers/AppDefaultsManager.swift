import AppKit
import Foundation

// MARK: - Centralized App Defaults & Factory Settings Manager

public final class AppDefaultsManager {
    public static let shared = AppDefaultsManager()

    public static var defaultBarFolderPath: String {
        FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first?.path ?? (NSHomeDirectory() + "/Desktop")
    }

    private init() {}

    /// Registers standard factory defaults dictionary with UserDefaults
    public static func registerDefaults() {
        let defaults: [String: Any] = [
            PrefKey.dropdownMode: "Settings",
            PrefKey.selectedStudioTab: "Battery",
            PrefKey.menuCompactMode: true,
            PrefKey.windowSizeMode: "normal",
            PrefKey.barFolderPath: defaultBarFolderPath,
            PrefKey.isCollapsedIntoBattery: false,
            PrefKey.iconEnabled: true,
            PrefKey.statusIconStyle: "🪔",
            PrefKey.iconStyle: "Minimal Pill",
            PrefKey.showBatteryPercentage: true,
            PrefKey.showChargingBolt: true,
            PrefKey.batteryColorMode: "Dynamic Level",
            PrefKey.batteryNumberTheme: "Dynamic",
            PrefKey.desktopPlaneEnabled: false,
            PrefKey.appFormation: "Responsive Grid",
            PrefKey.chatGridPadding: 48.0,
            PrefKey.isVelcroDetached: false,
            PrefKey.menuBarSnapMode: "icon",
            PrefKey.soundEnabled: true,
            PrefKey.hapticsEnabled: true,
            PrefKey.smokeEffectsEnabled: false,
            PrefKey.smokeStyle: "Mystical Cyan 🧞‍♂️",
            PrefKey.gridTransitionDirection: "Pull Up from Bottom",
            PrefKey.showPageIndicator: false,
            PrefKey.showAppNames: true,
            PrefKey.windowGraphicsEnabled: true,
            PrefKey.windowWallpaperEffect: true,
            PrefKey.windowShaderFxEnabled: true,
            PrefKey.dropdownBgPreset: "wallpaper_mirror",
            PrefKey.dropdownBgOpacity: 0.40,
            PrefKey.dropdownBgBlur: 16.0,
            PrefKey.iconSize: 56.0,
            PrefKey.textSize: 10.5,
            PrefKey.spacing: 24.0,
            PrefKey.enableMagnification: true,
            PrefKey.magnificationScale: 1.65,
            PrefKey.searchHotkeyChoice: "Option + Space (⌥ Space)",
            PrefKey.appLanguage: "English (US)",
            PrefKey.batteryStyle: "Classic Apple Battery",
            PrefKey.statusIconGlyph: "Genie Person 🧞‍♂️",
            PrefKey.doubleControlTrigger: true,
            PrefKey.doubleOptionTrigger: false,
            PrefKey.batteryEnabled: true,
            PrefKey.genieAnimEnabled: true,
            PrefKey.sameWallpaperMode: true,
            PrefKey.bottomEdgeCursorTrigger: false,
            PrefKey.topEdgeCursorTrigger: false,
            PrefKey.rightEdgeCursorTrigger: true,
            PrefKey.bottomRightHotCorner: false,
            PrefKey.dockRestPeriod: 0.65,
            PrefKey.soundVolume: 0.85,
            PrefKey.soundProfile: "Apple Modern",
            PrefKey.notePrinterSoundEnabled: true,
            PrefKey.studioAlwaysOnTop: true,
            PrefKey.popoverFreePositionEnabled: true,
            PrefKey.autoSelectLocalModel: true,
            PrefKey.localModelsEnabled: true,
            PrefKey.terminalAccessEnabled: true,
            PrefKey.terminalAutoExecute: false,
            PrefKey.webAccessEnabled: true,
            PrefKey.webAutoSearch: true,
            PrefKey.ollamaHost: "http://localhost:11434",
            PrefKey.geminiApiKey: "AQ.Ab8RN6KQdZll5kIJEFdF5jHHFDp8s5NxF8kZTRItnCRHb84ltw",
            PrefKey.menuBarTimeFormat: "Date & Time (12-Hour)",
            PrefKey.menuBarFontFamily: "SF Pro (Apple Default)",
            PrefKey.menuBarFontWeight: "Medium",
            PrefKey.menuBarFontSize: 15.0,
            PrefKey.menuBarTextColor: "Pure White ⚪️",
            PrefKey.menuBarActiveAppColor: "Pure White ⚪️",
            PrefKey.menuBarColorsEnabled: false,
            PrefKey.menuBarClockShowText: false,
            PrefKey.searchBarPlacement: "Centered Dynamic 🎯",
            PrefKey.appDisplayStage: 2,
            PrefKey.middleSplitRatio: 0.44,
            PrefKey.menuBarAppleLogoColor: "White (Pure)",
            PrefKey.menuBarLiquidBlur: 24.0,
            PrefKey.menuBarLiquidGlassAlpha: 0.40,
            PrefKey.menuBarAppsPlacement: "Right Side (Classic Dock)",
            PrefKey.dockAlwaysShowFinder: true,
            PrefKey.dockAlwaysShowSettings: true,
            PrefKey.dockAlwaysShowTrash: true,
            PrefKey.dockAlwaysShowGenie: true,
            PrefKey.miniDockDisplayMode: "Always Hidden",
            PrefKey.rightEdgeDocksEnabled: true,
            PrefKey.miniDockBackgroundStyle: "Clear (Transparent)",
            PrefKey.hasCompletedInitialSetup: true,
            PrefKey.barModeRaw: "apps",
            PrefKey.theatreModeEnabled: true,
            PrefKey.studioTheme: "System (Auto)",
            PrefKey.launchAtLogin: true,
            PrefKey.customMenuBarEnabled: true,
            PrefKey.unifiedCommandWindowEnabled: true,
            PrefKey.bareArrowAction: "Switch Desktops",
            PrefKey.desktopPreviewStyle: "Live Thumbnails (Windows)",
            PrefKey.menuBarFullScreenBehavior: "Auto-Hide on Hover",
            PrefKey.instantDesktopSwitching: true,
            PrefKey.extendedDesktopEdgeGlideEnabled: true,
            PrefKey.preloadExtraDesktopInRAM: true,
            PrefKey.isLeftChatDockOpen: false,
            PrefKey.isRightChatDockOpen: false,
            PrefKey.isRightAppsDockOpen: false,
            PrefKey.rightDocksCoexistMode: "Side-by-Side 📐",
            PrefKey.showMiniDockInChatBar: true,
            PrefKey.showAppsMiniMap: false,
            PrefKey.appIconTheme: "Apple Native Squircle",
            PrefKey.iconSnuggie: "Rounded Square",
            PrefKey.appIconTintColor: "Emerald",
            PrefKey.preventSystemSleep: true,
            PrefKey.imessageExtensionActive: true,
            PrefKey.dockAnimationStyle: "Classic Magnify 🔍",
            PrefKey.dockAnimationIntensity: 0.7,
            PrefKey.danceToMusicEnabled: true,
            PrefKey.liquidGlassEnabled: true,
            PrefKey.thermalAutoStopEnabled: true,
            PrefKey.thermalCPUAutoStopThreshold: 85.0
        ]
        UserDefaults.standard.register(defaults: defaults)
    }

    // MARK: - Legacy Preference Migration Map
    // Maps older unstructured or cryptic "nexus.*" keys to domain-namespaced keys ("canvas.*", "spatial.*", "audio.*")
    // while ensuring existing user preferences are automatically read, migrated, and mirrored so no settings are lost.
    public static let preferenceKeyMigrationMap: [String: String] = [
        "nexus.dropdownMode": "canvas.dropdownDisplayMode",
        "nexus.selectedStudioTab": "studio.activeTabIdentifier",
        "nexus.menuCompactMode": "menuBar.isCompactModeEnabled",
        "nexus.windowSizeMode": "window.displaySizeMode",
        "nexus.barFolderPath": "folderBar.storageFolderPath",
        "nexus.isCollapsedIntoBattery": "battery.isCollapsedIntoIcon",
        "nexus.desktopPlaneEnabled": "spatial.isDesktopPlaneEnabled",
        "nexus.isUniverse81Active": "spatial.isUniverse81Active",
        "nexus.appFormation": "canvas.applicationGridLayoutFormation",
        "nexus.soundEnabled": "audio.isFeedbackSoundEnabled",
        "nexus.hapticsEnabled": "haptics.isFeedbackHapticsEnabled",
        "nexus.smokeEffectsEnabled": "visualEffects.isSmokeSimulationEnabled",
        "nexus.extendedDesktopEdgeGlideEnabled": "spatial.isEdgeGlideNavigationEnabled",
        "nexus.preloadExtraDesktopInRAM": "spatial.isExtraDesktopMemoryPreloadEnabled",
        "nexus.continuousCanvasFormation": "canvas.continuousCanvasFormationMode",
        "nexus.vectorSnappingEnabled": "spatial.isVectorSnappingEnabled",
        "nexus.aboveLevelCursorEnabled": "cursor.isAboveLevelCursorTrackingEnabled"
    ]

    /// Automatically migrates legacy keys to modern namespaced keys while preserving bidirectional fallback
    public static func migrateLegacyPreferences(userDefaults: UserDefaults = .standard) {
        for (legacyKey, modernKey) in preferenceKeyMigrationMap {
            if let legacyValue = userDefaults.object(forKey: legacyKey), userDefaults.object(forKey: modernKey) == nil {
                userDefaults.set(legacyValue, forKey: modernKey)
            } else if let modernValue = userDefaults.object(forKey: modernKey), userDefaults.object(forKey: legacyKey) == nil {
                userDefaults.set(modernValue, forKey: legacyKey)
            }
        }
    }

    /// Retrieves a preference value with automatic fallback between modern namespaced key and legacy key
    public static func preferenceValue<T>(forModernKey modernKey: String, fallbackLegacyKey: String? = nil, userDefaults: UserDefaults = .standard) -> T? {
        if let directVal = userDefaults.object(forKey: modernKey) as? T {
            return directVal
        }
        if let fallbackKey = fallbackLegacyKey ?? preferenceKeyMigrationMap.first(where: { $0.value == modernKey })?.key,
           let fallbackVal = userDefaults.object(forKey: fallbackKey) as? T {
            return fallbackVal
        }
        return nil
    }

    /// Called on app startup to ensure valid configuration and clear corrupt state
    public static func applyInitialDefaults() {
        registerDefaults()
        migrateLegacyPreferences()

        let defaults = UserDefaults.standard

        // Ensure default folder path exists and is populated
        if defaults.string(forKey: PrefKey.barFolderPath) == nil || defaults.string(forKey: PrefKey.barFolderPath)?.isEmpty == true {
            defaults.set(defaultBarFolderPath, forKey: PrefKey.barFolderPath)
        }

        // Ensure dropdownMode is initialized to Settings
        if defaults.string(forKey: PrefKey.dropdownMode) == nil || defaults.string(forKey: PrefKey.dropdownMode) == "Applications" {
            defaults.set("Settings", forKey: PrefKey.dropdownMode)
        }

        // Mark initial setup as completed so user settings are never overwritten by walkthrough
        if !defaults.bool(forKey: PrefKey.hasCompletedInitialSetup) {
            defaults.set(true, forKey: PrefKey.hasCompletedInitialSetup)
        }

        // Sanitize out-of-screen or corrupt custom coordinates
        if !defaults.bool(forKey: PrefKey.isVelcroDetached) {
            defaults.removeObject(forKey: PrefKey.popoverCustomX)
            defaults.removeObject(forKey: PrefKey.popoverCustomY)
        }

        // Initialize Gemini API Key with user requested default
        let currentGeminiKey = defaults.string(forKey: PrefKey.geminiApiKey) ?? ""
        if currentGeminiKey.isEmpty || currentGeminiKey == "AQ.Ab8RN6K6XUFX2BFihmrdf6MxilstIPFooUlLITjJsN_h3bownw" {
            defaults.set("AQ.Ab8RN6KQdZll5kIJEFdF5jHHFDp8s5NxF8kZTRItnCRHb84ltw", forKey: PrefKey.geminiApiKey)
        }

        // User requested: clean Apple white text and no pink/blue text overlays
        let currentText = defaults.string(forKey: PrefKey.menuBarTextColor) ?? ""
        if currentText.contains("Pink") || currentText.contains("Cyan") || currentText.contains("Blue") {
            defaults.set("Pure White ⚪️", forKey: PrefKey.menuBarTextColor)
            defaults.set("Pure White ⚪️", forKey: PrefKey.menuBarActiveAppColor)
            defaults.set(false, forKey: PrefKey.menuBarColorsEnabled)
        }
        defaults.set("Clear (Transparent)", forKey: PrefKey.menuBarBackgroundStyle)
        defaults.set("Clear (Transparent)", forKey: PrefKey.miniDockBackgroundStyle)
        defaults.set("Clear (Transparent)", forKey: PrefKey.miniDockStyle)
        defaults.set(false, forKey: PrefKey.showPageIndicator)
        defaults.set(false, forKey: PrefKey.isUniverse81Active)
        defaults.set(false, forKey: PrefKey.desktopPlaneEnabled)
        defaults.set(false, forKey: PrefKey.bottomEdgeCursorTrigger)
        defaults.set(false, forKey: PrefKey.topEdgeCursorTrigger)
        defaults.set(false, forKey: PrefKey.rightEdgeCursorTrigger)
        defaults.set(false, forKey: PrefKey.bottomRightHotCorner)
        defaults.set(0, forKey: PrefKey.appDisplayStage)
        if defaults.object(forKey: PrefKey.customMenuBarEnabled) == nil {
            defaults.set(true, forKey: PrefKey.customMenuBarEnabled)
        }
        if defaults.object(forKey: PrefKey.launchAtLogin) == nil {
            defaults.set(true, forKey: PrefKey.launchAtLogin)
        }
        if defaults.bool(forKey: PrefKey.launchAtLogin) {
            LoginItemManager.shared.setEnabled(true)
        }
        defaults.set(true, forKey: PrefKey.showMiniDesktopsInMenuBar)
        defaults.set(true, forKey: PrefKey.dockAlwaysShowGenie)
        defaults.set(true, forKey: PrefKey.dockAlwaysShowFinder)
        defaults.set(true, forKey: PrefKey.dockAlwaysShowSettings)
        defaults.set(true, forKey: PrefKey.dockAlwaysShowTrash)
        defaults.set(true, forKey: PrefKey.batteryEnabled)
        defaults.set(true, forKey: PrefKey.iconEnabled)
        defaults.set("Always Hidden", forKey: PrefKey.miniDockDisplayMode)
        defaults.set(true, forKey: PrefKey.rightEdgeDocksEnabled)
        defaults.set(true, forKey: PrefKey.showBatteryPercentage)
        defaults.set(true, forKey: PrefKey.showChargingBolt)

        // Synchronize defaults immediately to disk
        defaults.synchronize()
    }

    /// Explicit helper to persist and immediately synchronize a setting
    public static func save<T>(_ value: T, forKey key: String) {
        UserDefaults.standard.set(value, forKey: key)
        UserDefaults.standard.synchronize()
    }

    /// Reset all settings back to pristine defaults
    public static func resetAllToDefaults() {
        let defaults = UserDefaults.standard
        defaults.set("Settings", forKey: PrefKey.dropdownMode)
        defaults.set("Battery", forKey: PrefKey.selectedStudioTab)
        defaults.set(true, forKey: PrefKey.menuCompactMode)
        defaults.set("normal", forKey: PrefKey.windowSizeMode)
        defaults.set(defaultBarFolderPath, forKey: PrefKey.barFolderPath)
        defaults.set(false, forKey: PrefKey.isCollapsedIntoBattery)
        defaults.set(true, forKey: PrefKey.iconEnabled)
        defaults.set("🪔", forKey: PrefKey.statusIconStyle)
        defaults.set("Minimal Pill", forKey: PrefKey.iconStyle)
        defaults.set(true, forKey: PrefKey.showBatteryPercentage)
        defaults.set(true, forKey: PrefKey.showChargingBolt)
        defaults.set("Dynamic Level", forKey: PrefKey.batteryColorMode)
        defaults.set(false, forKey: PrefKey.desktopPlaneEnabled)
        defaults.set("Responsive Grid", forKey: PrefKey.appFormation)
        defaults.set(false, forKey: PrefKey.isVelcroDetached)
        defaults.set("icon", forKey: PrefKey.menuBarSnapMode)
        defaults.set(true, forKey: PrefKey.soundEnabled)
        defaults.set(true, forKey: PrefKey.hapticsEnabled)
        defaults.set(false, forKey: PrefKey.smokeEffectsEnabled)
        defaults.set("Mystical Cyan 🧞‍♂️", forKey: PrefKey.smokeStyle)
        defaults.set("Pull Up from Bottom", forKey: PrefKey.gridTransitionDirection)
        defaults.set(false, forKey: PrefKey.showPageIndicator)
        defaults.set(true, forKey: PrefKey.showAppNames)
        defaults.set(true, forKey: PrefKey.windowGraphicsEnabled)
        defaults.set(true, forKey: PrefKey.windowWallpaperEffect)
        defaults.set(true, forKey: PrefKey.windowShaderFxEnabled)
        defaults.set("wallpaper_mirror", forKey: PrefKey.dropdownBgPreset)
        defaults.set(0.40, forKey: PrefKey.dropdownBgOpacity)
        defaults.set(16.0, forKey: PrefKey.dropdownBgBlur)
        defaults.set(56.0, forKey: PrefKey.iconSize)
        defaults.set(10.5, forKey: PrefKey.textSize)
        defaults.set(24.0, forKey: PrefKey.spacing)
        defaults.set(true, forKey: PrefKey.enableMagnification)
        defaults.set(1.65, forKey: PrefKey.magnificationScale)
        defaults.set("Classic Magnify 🔍", forKey: PrefKey.dockAnimationStyle)
        defaults.set(0.7, forKey: PrefKey.dockAnimationIntensity)
        defaults.set(true, forKey: PrefKey.danceToMusicEnabled)
        defaults.set(true, forKey: PrefKey.liquidGlassEnabled)
        defaults.set(true, forKey: PrefKey.thermalAutoStopEnabled)
        defaults.set("Option + Space (⌥ Space)", forKey: PrefKey.searchHotkeyChoice)
        defaults.set(false, forKey: PrefKey.bottomEdgeCursorTrigger)
        defaults.set(false, forKey: PrefKey.topEdgeCursorTrigger)
        defaults.set(false, forKey: PrefKey.rightEdgeCursorTrigger)
        defaults.set(false, forKey: PrefKey.bottomRightHotCorner)
        defaults.set(0, forKey: PrefKey.appDisplayStage)

        defaults.removeObject(forKey: PrefKey.popoverCustomX)
        defaults.removeObject(forKey: PrefKey.popoverCustomY)
        defaults.removeObject(forKey: PrefKey.popoverCustomWidth)
        defaults.removeObject(forKey: PrefKey.popoverCustomHeight)

        NotificationCenter.default.post(name: NSNotification.Name("NexusSettingsChanged"), object: nil)
        NotificationCenter.default.post(name: NSNotification.Name("NexusIconStyleChanged"), object: nil)
        NotificationCenter.default.post(name: NSNotification.Name("NexusDesktopPlaneToggled"), object: nil)
    }
}
