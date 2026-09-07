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
            "nexus.dropdownMode": "Applications",
            "nexus.selectedStudioTab": "Battery",
            "nexus.menuCompactMode": true,
            "nexus.windowSizeMode": "normal",
            "nexus.barFolderPath": defaultBarFolderPath,
            "nexus.isCollapsedIntoBattery": false,
            "nexus.iconEnabled": true,
            "nexus.statusIconStyle": "🪔",
            "nexus.iconStyle": "Minimal Pill",
            "nexus.showBatteryPercentage": true,
            "nexus.showChargingBolt": true,
            "nexus.batteryColorMode": "Dynamic Level",
            "nexus.batteryNumberTheme": "Dynamic",
            "nexus.desktopPlaneEnabled": false,
            "nexus.appFormation": "Responsive Grid",
            "nexus.chatGridPadding": 48.0,
            "nexus.isVelcroDetached": false,
            "nexus.menuBarSnapMode": "icon",
            "nexus.soundEnabled": true,
            "nexus.hapticsEnabled": true,
            "nexus.smokeEffectsEnabled": false,
            "nexus.smokeStyle": "Mystical Cyan 🧞‍♂️",
            "nexus.gridTransitionDirection": "Pull Up from Bottom",
            "nexus.showPageIndicator": false,
            "nexus.showAppNames": true,
            "nexus.windowGraphicsEnabled": true,
            "nexus.windowWallpaperEffect": true,
            "nexus.windowShaderFxEnabled": true,
            "nexus.dropdownBgPreset": "wallpaper_mirror",
            "nexus.dropdownBgOpacity": 0.40,
            "nexus.dropdownBgBlur": 16.0,
            "nexus.iconSize": 56.0,
            "nexus.textSize": 10.5,
            "nexus.spacing": 24.0,
            "nexus.enableMagnification": true,
            "nexus.magnificationScale": 1.65,
            "nexus.searchHotkeyChoice": "Option + Space (⌥ Space)",
            "nexus.appLanguage": "English (US)",
            "nexus.batteryStyle": "Classic Apple Battery",
            "nexus.statusIconGlyph": "Genie Person 🧞‍♂️",
            "nexus.doubleControlTrigger": true,
            "nexus.doubleOptionTrigger": false,
            "nexus.batteryEnabled": true,
            "nexus.genieAnimEnabled": true,
            "nexus.sameWallpaperMode": true,
            "nexus.bottomEdgeCursorTrigger": true,
            "nexus.topEdgeCursorTrigger": true,
            "nexus.rightEdgeCursorTrigger": true,
            "nexus.bottomRightHotCorner": true,
            "nexus.dockRestPeriod": 0.65,
            "nexus.soundVolume": 0.85,
            "nexus.soundProfile": "Apple Modern",
            "nexus.notePrinterSoundEnabled": true,
            "nexus.studioAlwaysOnTop": true,
            "nexus.popoverFreePositionEnabled": true,
            "nexus.autoSelectLocalModel": true,
            "nexus.localModelsEnabled": true,
            "nexus.terminalAccessEnabled": true,
            "nexus.terminalAutoExecute": false,
            "nexus.webAccessEnabled": true,
            "nexus.webAutoSearch": true,
            "nexus.ollamaHost": "http://localhost:11434",
            "nexus.geminiApiKey": "AQ.Ab8RN6KQdZll5kIJEFdF5jHHFDp8s5NxF8kZTRItnCRHb84ltw",
            "nexus.menuBarTimeFormat": "Date & Time (12-Hour)",
            "nexus.menuBarFontFamily": "SF Pro (Apple Default)",
            "nexus.menuBarFontWeight": "Medium",
            "nexus.menuBarFontSize": 12.0,
            "nexus.menuBarTextColor": "Pure White ⚪️",
            "nexus.menuBarActiveAppColor": "Pure White ⚪️",
            "nexus.menuBarColorsEnabled": false,
            "nexus.menuBarClockShowText": false,
            "nexus.searchBarPlacement": "Centered Dynamic 🎯",
            "nexus.appDisplayStage": 0,
            "nexus.middleSplitRatio": 0.44,
            "nexus.menuBarAppleLogoColor": "White (Pure)",
            "nexus.menuBarLiquidBlur": 24.0,
            "nexus.menuBarLiquidGlassAlpha": 0.40,
            "nexus.menuBarAppsPlacement": "Right Side (Classic Dock)",
            "nexus.dockAlwaysShowFinder": true,
            "nexus.dockAlwaysShowSettings": true,
            "nexus.dockAlwaysShowTrash": true,
            "nexus.dockAlwaysShowGenie": true,
            "nexus.miniDockDisplayMode": "Always Shown",
            "nexus.hasCompletedInitialSetup": true,
            "nexus.barModeRaw": "chat",
            "nexus.theatreModeEnabled": true,
            "nexus.studioTheme": "System (Auto)",
            "nexus.customMenuBarEnabled": false,
            "nexus.desktopPreviewStyle": "Live Thumbnails (Windows)",
            "nexus.menuBarFullScreenBehavior": "Auto-Hide on Hover",
            "nexus.instantDesktopSwitching": true,
            "nexus.extendedDesktopEdgeGlideEnabled": true,
            "nexus.preloadExtraDesktopInRAM": true,
            "nexus.rightEdgeDocksEnabled": false,
            "nexus.isRightChatDockOpen": false,
            "nexus.isRightAppsDockOpen": false,
            "nexus.rightDocksCoexistMode": "Side-by-Side 📐"
        ]
        UserDefaults.standard.register(defaults: defaults)
    }

    /// Called on app startup to ensure valid configuration and clear corrupt state
    public static func applyInitialDefaults() {
        registerDefaults()

        let defaults = UserDefaults.standard

        // Ensure default folder path exists and is populated
        if defaults.string(forKey: "nexus.barFolderPath") == nil || defaults.string(forKey: "nexus.barFolderPath")?.isEmpty == true {
            defaults.set(defaultBarFolderPath, forKey: "nexus.barFolderPath")
        }

        // Ensure dropdownMode is initialized to Applications
        if defaults.string(forKey: "nexus.dropdownMode") == nil {
            defaults.set("Applications", forKey: "nexus.dropdownMode")
        }

        // Mark initial setup as completed so user settings are never overwritten by walkthrough
        if !defaults.bool(forKey: "nexus.hasCompletedInitialSetup") {
            defaults.set(true, forKey: "nexus.hasCompletedInitialSetup")
        }

        // Sanitize out-of-screen or corrupt custom coordinates
        if !defaults.bool(forKey: "nexus.isVelcroDetached") {
            defaults.removeObject(forKey: "nexus.popoverCustomX")
            defaults.removeObject(forKey: "nexus.popoverCustomY")
        }

        // Initialize Gemini API Key with user requested default
        let currentGeminiKey = defaults.string(forKey: "nexus.geminiApiKey") ?? ""
        if currentGeminiKey.isEmpty || currentGeminiKey == "AQ.Ab8RN6K6XUFX2BFihmrdf6MxilstIPFooUlLITjJsN_h3bownw" {
            defaults.set("AQ.Ab8RN6KQdZll5kIJEFdF5jHHFDp8s5NxF8kZTRItnCRHb84ltw", forKey: "nexus.geminiApiKey")
        }

        // User requested: clean Apple white text and no pink/blue text overlays
        let currentText = defaults.string(forKey: "nexus.menuBarTextColor") ?? ""
        if currentText.contains("Pink") || currentText.contains("Cyan") || currentText.contains("Blue") {
            defaults.set("Pure White ⚪️", forKey: "nexus.menuBarTextColor")
            defaults.set("Pure White ⚪️", forKey: "nexus.menuBarActiveAppColor")
            defaults.set(false, forKey: "nexus.menuBarColorsEnabled")
        }
        if defaults.string(forKey: "nexus.menuBarBackgroundStyle") == nil || defaults.string(forKey: "nexus.menuBarBackgroundStyle") == "Translucent Glass Blur" || defaults.string(forKey: "nexus.menuBarBackgroundStyle") == "Clear (Transparent)" {
            defaults.set("Liquid Glass (Apple Modern) 💎", forKey: "nexus.menuBarBackgroundStyle")
        }

        // Original Mac menu bar on top: keep custom overlay disabled so native bar is untouched
        defaults.set(false, forKey: "nexus.customMenuBarEnabled")
        if defaults.string(forKey: "nexus.miniDockBackgroundStyle") == nil || defaults.string(forKey: "nexus.miniDockBackgroundStyle") == "Clear (Transparent)" || defaults.string(forKey: "nexus.miniDockBackgroundStyle") == "Clear" {
            defaults.set("Apple Liquid Glass", forKey: "nexus.miniDockBackgroundStyle")
        }
        defaults.set(true, forKey: "nexus.showMiniDesktopsInMenuBar")
        defaults.set(true, forKey: "nexus.dockAlwaysShowGenie")
        defaults.set(true, forKey: "nexus.dockAlwaysShowFinder")
        defaults.set(true, forKey: "nexus.dockAlwaysShowSettings")
        defaults.set(true, forKey: "nexus.dockAlwaysShowTrash")
        defaults.set(true, forKey: "nexus.batteryEnabled")
        defaults.set(true, forKey: "nexus.iconEnabled")
        defaults.set("Always Shown", forKey: "nexus.miniDockDisplayMode")
        defaults.set(false, forKey: "nexus.rightEdgeDocksEnabled")
        defaults.set(true, forKey: "nexus.showBatteryPercentage")
        defaults.set(true, forKey: "nexus.showChargingBolt")

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
        defaults.set("Applications", forKey: "nexus.dropdownMode")
        defaults.set("Battery", forKey: "nexus.selectedStudioTab")
        defaults.set(true, forKey: "nexus.menuCompactMode")
        defaults.set("normal", forKey: "nexus.windowSizeMode")
        defaults.set(defaultBarFolderPath, forKey: "nexus.barFolderPath")
        defaults.set(false, forKey: "nexus.isCollapsedIntoBattery")
        defaults.set(true, forKey: "nexus.iconEnabled")
        defaults.set("🪔", forKey: "nexus.statusIconStyle")
        defaults.set("Minimal Pill", forKey: "nexus.iconStyle")
        defaults.set(true, forKey: "nexus.showBatteryPercentage")
        defaults.set(true, forKey: "nexus.showChargingBolt")
        defaults.set("Dynamic Level", forKey: "nexus.batteryColorMode")
        defaults.set(false, forKey: "nexus.desktopPlaneEnabled")
        defaults.set("Responsive Grid", forKey: "nexus.appFormation")
        defaults.set(false, forKey: "nexus.isVelcroDetached")
        defaults.set("icon", forKey: "nexus.menuBarSnapMode")
        defaults.set(true, forKey: "nexus.soundEnabled")
        defaults.set(true, forKey: "nexus.hapticsEnabled")
        defaults.set(false, forKey: "nexus.smokeEffectsEnabled")
        defaults.set("Mystical Cyan 🧞‍♂️", forKey: "nexus.smokeStyle")
        defaults.set("Pull Up from Bottom", forKey: "nexus.gridTransitionDirection")
        defaults.set(false, forKey: "nexus.showPageIndicator")
        defaults.set(true, forKey: "nexus.showAppNames")
        defaults.set(true, forKey: "nexus.windowGraphicsEnabled")
        defaults.set(true, forKey: "nexus.windowWallpaperEffect")
        defaults.set(true, forKey: "nexus.windowShaderFxEnabled")
        defaults.set("wallpaper_mirror", forKey: "nexus.dropdownBgPreset")
        defaults.set(0.40, forKey: "nexus.dropdownBgOpacity")
        defaults.set(16.0, forKey: "nexus.dropdownBgBlur")
        defaults.set(56.0, forKey: "nexus.iconSize")
        defaults.set(10.5, forKey: "nexus.textSize")
        defaults.set(24.0, forKey: "nexus.spacing")
        defaults.set(true, forKey: "nexus.enableMagnification")
        defaults.set(1.65, forKey: "nexus.magnificationScale")
        defaults.set("Option + Space (⌥ Space)", forKey: "nexus.searchHotkeyChoice")

        defaults.removeObject(forKey: "nexus.popoverCustomX")
        defaults.removeObject(forKey: "nexus.popoverCustomY")
        defaults.removeObject(forKey: "nexus.popoverCustomWidth")
        defaults.removeObject(forKey: "nexus.popoverCustomHeight")

        NotificationCenter.default.post(name: NSNotification.Name("NexusSettingsChanged"), object: nil)
        NotificationCenter.default.post(name: NSNotification.Name("NexusIconStyleChanged"), object: nil)
        NotificationCenter.default.post(name: NSNotification.Name("NexusDesktopPlaneToggled"), object: nil)
    }
}
