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
    @AppStorage("nexus.appLanguage") var appLanguage: String = "English (US)"
@ObservedObject var batteryMonitor = BatteryMonitor.shared
    @ObservedObject var gridManager = SmartGridManager.shared
    @ObservedObject var desktopsManager = MacDesktopsManager.shared
    @ObservedObject var desktopFilesManager = DesktopFilesManager.shared
    @ObservedObject var trashMonitor = TrashMonitor.shared

    @AppStorage("nexus.batteryEnabled") var batteryEnabled: Bool = true
    @AppStorage("nexus.batteryStyle") var batteryStyle: String = "Classic Apple Battery"
    @AppStorage("nexus.batteryColorMode") var batteryColorMode: String = "Dynamic Level"
    @AppStorage("nexus.showBatteryPercentage") var showBatteryPercentage: Bool = true
    @AppStorage("nexus.isVelcroDetached") var isVelcroDetached: Bool = false
    @AppStorage("nexus.smokeEffectsEnabled") var smokeEffectsEnabled: Bool = true
    @AppStorage("nexus.smokeStyle") var smokeStyle: String = "Mystical Cyan 🧞‍♂️"
    @AppStorage("nexus.statusIconGlyph") var statusIconGlyph: String = "Genie Person 🧞‍♂️"
    @AppStorage("nexus.statusIconStyle") var statusIconStyle: String = "Genie Person 🧞‍♂️"
    @AppStorage("nexus.menuBarAppSwitcherEnabled") var menuBarAppSwitcherEnabled: Bool = true
    @AppStorage("nexus.miniDockDisplayMode") var miniDockDisplayMode: String = "Always Shown" // "Always Shown", "Always Hidden", "Auto-Hide"
    private var isHiddenMode: Bool {
        miniDockDisplayMode == "Always Hidden" || miniDockDisplayMode == "Auto-Hide"
    }
    @AppStorage("nexus.dockActiveAppsOnly") var dockActiveAppsOnly: Bool = false
    @AppStorage("nexus.miniDockBackgroundStyle") var miniDockBackgroundStyle: String = "Clear (Transparent)"
    @AppStorage("nexus.menuBarAppleColor") var appleColor: String = "Retro Rainbow 🌈"
    @AppStorage("nexus.showAppleLogoOnStrip") var showAppleLogoOnStrip: Bool = true
    @AppStorage("nexus.menuBarTextColor") var textColorName: String = "Pure White ⚪️"
    @AppStorage("nexus.menuBarFontFamily") var fontFamily: String = "SF Pro (Apple Default)"
    @AppStorage("nexus.menuBarFontWeight") var fontWeight: String = "Regular"
    @AppStorage("nexus.menuBarFontSize") var menuBarFontSize: Double = 12.0
    @AppStorage("nexus.folderStacksRetracted") var folderStacksRetracted: Bool = false
    @AppStorage("nexus.barFolderPath") var barFolderPath: String = AppDefaultsManager.defaultBarFolderPath
    @AppStorage("nexus.finderColor") var finderColor: String = "Classic Blue 🔵"
    @AppStorage("nexus.finderIconStyle") var finderIconStyle: String = "Finder Face (Default)"

    @AppStorage("nexus.menuBarAppCount") var menuBarAppCount: Int = 3
    @AppStorage("nexus.gridTransitionDirection") var gridTransitionDirection: String = "Slide from Right (iPhone Mode 📱)"
    @AppStorage("nexus.showChargingBolt") var showChargingBolt: Bool = true
    @AppStorage("nexus.showMiniDesktopsInMenuBar") var showMiniDesktopsInMenuBar: Bool = true
    @AppStorage("nexus.menuBarAppsPlacement") var appsPlacement: String = "Right Side (Classic Dock)"
    @AppStorage("nexus.dockAlwaysShowFinder") var dockAlwaysShowFinder: Bool = true
    @AppStorage("nexus.dockAlwaysShowSettings") var dockAlwaysShowSettings: Bool = true
    @AppStorage("nexus.dockAlwaysShowTrash") var dockAlwaysShowTrash: Bool = true
    @AppStorage("nexus.dockAlwaysShowGenie") var dockAlwaysShowGenie: Bool = true

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
    @State private var isChevronHovered: Bool = false
    @State private var isBatteryHovered: Bool = false
    @State private var isCloudHovered: Bool = false
    @State private var isSwitcherHovered: Bool = false
    @AppStorage("nexus.isCollapsedIntoBattery") var isCollapsedIntoBattery: Bool = false
    @ObservedObject private var dispatcher = MenuBarActionDispatcher.shared
    @State private var draggingItemId: String? = nil
    @State private var dragOffset: CGFloat = 0.0
    @State private var dragYOffset: CGFloat = 0.0
    @State private var isDragOffThreshold: Bool = false
    @State private var hoverDebounceTimer: Timer? = nil

    private var displayApps: [NSRunningApplication] {
        dockItems.compactMap { $0.runningApp }
    }

    private var isSystemMagnificationEnabled: Bool {
        if let val = UserDefaults(suiteName: "com.apple.dock")?.object(forKey: "magnification") as? Bool {
            return val
        }
        return true
    }

    private var magnificationScale: CGFloat {
        let largeSize = CGFloat(UserDefaults(suiteName: "com.apple.dock")?.double(forKey: "largesize") ?? 87.0)
        let tileSize = max(16.0, CGFloat(UserDefaults(suiteName: "com.apple.dock")?.double(forKey: "tilesize") ?? 48.0))
        let ratio = largeSize / tileSize
        return max(1.35, min(1.65, 1.0 + (ratio - 1.0) * 0.70))
    }

    private var allDockIds: [String] {
        ["leoLauncher"] + dockItems.map { $0.id } + ["barFolder", "trash"]
    }

    private func magnificationWave(for itemId: String) -> (scale: CGFloat, yOffset: CGFloat, zIndex: Double) {
        guard let hoveredId = hoveredItemId,
              let hoveredIdx = allDockIds.firstIndex(of: hoveredId),
              let myIdx = allDockIds.firstIndex(of: itemId) else {
            return (1.0, 0.0, 1.0)
        }
        let dist = abs(hoveredIdx - myIdx)
        switch dist {
        case 0:
            return (1.24, -1.0, 20.0)
        case 1:
            return (1.12, -0.5, 10.0)
        case 2:
            return (1.04, 0.0, 5.0)
        default:
            return (1.0, 0.0, 1.0)
        }
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
        guard CustomMenuBarManager.shared.isEnabled, notchFillerGapWidth > 0 else { return false }
        let name = item.name.lowercased()
        let bid = (item.bundleIdentifier ?? "").lowercased()
        if bid.contains("chrome") || name.contains("chrome") {
            return true
        }
        let hasChrome = dockItems.contains(where: {
            let b = ($0.bundleIdentifier ?? "").lowercased()
            let n = $0.name.lowercased()
            return b.contains("chrome") || n.contains("chrome")
        })
        if !hasChrome, let idx = dockItems.firstIndex(where: { $0.id == item.id }), idx == 2 {
            return true
        }
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
        if !style.isEmpty {
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
            RoundedRectangle(cornerRadius: 8.0, style: .continuous)
                .fill(isHovered ? Color.white.opacity(0.10) : Color.clear)
                .overlay(
                    RoundedRectangle(cornerRadius: 8.0, style: .continuous)
                        .strokeBorder(isHovered ? Color.white.opacity(0.18) : Color.clear, lineWidth: 0.5)
                )
        case "Dark Obsidian Glass", "Dark Translucent", "Obsidian":
            ZStack {
                LiquidGlassBlur(cornerRadius: 8.0, material: .hudWindow, blendingMode: .behindWindow)
                RoundedRectangle(cornerRadius: 8.0, style: .continuous)
                    .fill(Color.black.opacity(isHovered ? 0.45 : 0.32))
                LinearGradient(
                    colors: [Color.white.opacity(isHovered ? 0.18 : 0.08), Color.clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
            }
            .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8.0, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(isHovered ? 0.35 : 0.18), Color.white.opacity(0.06)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.6
                    )
            )
            .shadow(color: Color.black.opacity(0.3), radius: isHovered ? 4.0 : 2.0, y: 1.0)
        case "Neon Aurora Glass", "Neon Tint":
            ZStack {
                LiquidGlassBlur(cornerRadius: 8.0, material: .hudWindow, blendingMode: .behindWindow)
                RoundedRectangle(cornerRadius: 8.0, style: .continuous)
                    .fill(Color.cyan.opacity(isHovered ? 0.18 : 0.10))
                LinearGradient(
                    colors: [Color.cyan.opacity(0.25), Color.purple.opacity(0.15), Color.clear],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
            }
            .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8.0, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.cyan.opacity(isHovered ? 0.70 : 0.40), Color.purple.opacity(isHovered ? 0.45 : 0.20)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.75
                    )
            )
            .shadow(color: Color.cyan.opacity(isHovered ? 0.4 : 0.15), radius: 4.0, y: 1.0)
        default: // "Apple Liquid Glass", "Frosted Glass", "Matching System"
            ZStack {
                LiquidGlassBlur(cornerRadius: 8.0, material: .hudWindow, blendingMode: .behindWindow)

                // Translucent Vitreous Glass Base
                RoundedRectangle(cornerRadius: 8.0, style: .continuous)
                    .fill(Color.white.opacity(isHovered ? 0.12 : 0.06))

                // Specular crest highlight (Apple liquid glass reflection)
                LinearGradient(
                    stops: [
                        .init(color: Color.white.opacity(isHovered ? 0.38 : 0.26), location: 0.0),
                        .init(color: Color.white.opacity(isHovered ? 0.10 : 0.04), location: 0.35),
                        .init(color: Color.clear, location: 0.80)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
            }
            .clipShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8.0, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(isHovered ? 0.55 : 0.38), location: 0.0),
                                .init(color: Color.white.opacity(0.14), location: 0.40),
                                .init(color: Color.white.opacity(0.06), location: 0.70),
                                .init(color: Color.white.opacity(isHovered ? 0.30 : 0.20), location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.75
                    )
            )
            .shadow(color: Color.black.opacity(isHovered ? 0.22 : 0.12), radius: isHovered ? 4.0 : 2.0, x: 0, y: 1.0)
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
                "Monochrome", "Gold Gate Logo", "Gold Gate Bolt"
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
        UserDefaults.standard.set(style, forKey: "nexus.batteryStyle")
        UserDefaults.standard.set(style, forKey: "nexus.iconStyle")
        NotificationCenter.default.post(name: NSNotification.Name("NexusIconStyleChanged"), object: style)
        AppDelegate.shared?.renderIcon()
    }

    public var body: some View {
        HStack(alignment: .center, spacing: 4) {
            // ── 0. Launcher Glyph, Cloud Menu & Mini Desktop Spaces ──
            if dockAlwaysShowGenie {
                // Genie Lamp — Pops down Chat Studio directly
                Button(action: {
                    HapticFeedback.selection()
                    DesktopWindowManager.shared.switchToStation(.chat)
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(isLeoHovered ? Color.white.opacity(0.20) : Color.clear)
                            .frame(width: 22, height: 22)

                        if statusIconStyle.contains("") || statusIconStyle.lowercased().contains("apple") {
                            AppleLogoView(style: appleColor, size: 14)
                        } else {
                            Image(nsImage: glyphImage)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 17, height: 17)
                                .scaleEffect(isLeoHovered ? 1.10 : 1.0)
                                .shadow(color: Color.black.opacity(isLeoHovered ? 0.35 : 0.15), radius: 1.0, y: 1.0)
                        }
                    }
                    .frame(width: 22, height: 22)
                    .contentShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
                .background(
                    GeometryReader { geo in
                        Color.clear.preference(key: LeoFrameKey.self, value: geo.frame(in: .named("StripRoot")))
                    }
                )
                .buttonStyle(DockIconButtonStyle())
                .onHover { h in withAnimation(.spring(response: 0.20, dampingFraction: 0.75)) { isLeoHovered = h } }
                .help("Genie — Pop down Dialogue Studio (Chat)")

                // Cloud Menu — Expand into Cloud AI models & services
                cloudMenuView

                // Separator between Genie/Cloud and Mini Viewers
                Capsule()
                    .fill(Color.white.opacity(0.20))
                    .frame(width: 1, height: 12)
                    .padding(.horizontal, 1)

                // Mini Viewers (16:10 Desktop Spaces live screen thumbnails)
                if !CustomMenuBarManager.shared.isEnabled && showMiniDesktopsInMenuBar {
                    MiniMenuBarDesktopSpacesView()

                    // Separator between Desktop Spaces and Running Apps
                    Capsule()
                        .fill(Color.white.opacity(0.20))
                        .frame(width: 1, height: 12)
                        .padding(.horizontal, 1)
                }
            }

            // ── 1. Mini Dock (Running Apps + Folder + Trash + Switcher): Stable in menu bar ──
            HStack(alignment: .center, spacing: 5) {
                if !CustomMenuBarManager.shared.isEnabled || appsPlacement != "Next to Menus (After Help)" {
                    ForEach(dockItems) { item in
                        dockAppItemView(item: item)
                    }

                    // Mini Dock Vertical Divider
                    Capsule()
                        .fill(Color.white.opacity(0.20))
                        .frame(width: 1, height: 12)
                        .padding(.horizontal, 1)
                }

                // ── Pinned Folder Stack (Downloads / Documents / Folder) ──
                folderItemView

                // ── TRASH CAN ──
                if dockAlwaysShowTrash {
                    trashItemView
                }

                // ── Workspace Station Switcher (Chat ➔ Apps ➔ Desktop) ──
                switcherItemView
            }

            // ── 2. Battery Connected Directly On The Dock ──
            if batteryEnabled {
                // Subtle glass divider separating Apps from Battery inside the same dock pill
                Capsule()
                    .fill(Color.white.opacity(0.20))
                    .frame(width: 1, height: 12)
                    .padding(.horizontal, 2)

                batteryItemView
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2.0)
        .background(miniDockBackground)
        .contentShape(RoundedRectangle(cornerRadius: 8.0, style: .continuous))
        .contextMenu {
            dockContextMenu
        }
        .opacity(1.0)
        .transition(.opacity)
        .onHover { hovering in
            if hovering {
                dismissTimer?.invalidate()
                dismissTimer = nil
                withAnimation(.spring(response: 0.28, dampingFraction: 0.72)) {
                    isStripHovered = true
                }
            } else if isHiddenMode {
                dismissTimer?.invalidate()
                dismissTimer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: false) { _ in
                    Task { @MainActor in
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                            isStripHovered = false
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 4)
        .frame(height: 24)
        .fixedSize(horizontal: true, vertical: false)
        .coordinateSpace(name: "StripRoot")
        .background(
            GeometryReader { geo in
                Color.clear.preference(key: StripWidthPreferenceKey.self, value: ceil(geo.size.width))
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
        .onPreferenceChange(ChevronFrameKey.self) { MenuBarActionDispatcher.shared.chevronFrame = $0 }
        .onPreferenceChange(BatteryFrameKey.self) { MenuBarActionDispatcher.shared.batteryFrame = $0 }
        .onChange(of: isCollapsedIntoBattery) { _, collapsed in
            MenuBarActionDispatcher.shared.isCollapsedIntoBattery = collapsed
        }
        .onAppear {
            batteryEnabled = true
            UserDefaults.standard.set(true, forKey: "nexus.batteryEnabled")
            showBatteryPercentage = true
            UserDefaults.standard.set(true, forKey: "nexus.showBatteryPercentage")
            BatteryMonitor.shared.refresh()
            if statusIconGlyph.isEmpty || statusIconGlyph == "Golden Gate Arch" || statusIconGlyph == "Leo Maltese 🐶" {
                statusIconGlyph = "Genie Person 🧞‍♂️"
                UserDefaults.standard.set("Genie Person 🧞‍♂️", forKey: "nexus.statusIconGlyph")
                UserDefaults.standard.set("Genie Person 🧞‍♂️", forKey: "nexus.statusIconStyle")
                UserDefaults.standard.set("Genie Person", forKey: "nexus.brandIconStyle")
                BrandLogoManager.shared.brandIconStyle = "Genie Person"
            }
            refreshApps()
            MenuBarActionDispatcher.shared.displayApps = self.displayApps
            MenuBarActionDispatcher.shared.isCollapsedIntoBattery = self.isCollapsedIntoBattery
        }
        .onDisappear {
            hoverDebounceTimer?.invalidate()
            hoverDebounceTimer = nil
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusAnimTick"))) { notif in
            if let p = notif.object as? CGFloat {
                animPhase = p
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusToggleDockCollapse"))) { _ in
            withAnimation(.spring(response: 0.32, dampingFraction: 0.76)) {
                isCollapsedIntoBattery.toggle()
            }
        }
        .onReceive(DistributedNotificationCenter.default().publisher(for: NSNotification.Name("com.user.nexus.toggleCollapse"))) { _ in
            withAnimation(.spring(response: 0.32, dampingFraction: 0.76)) {
                isCollapsedIntoBattery.toggle()
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
            textColorName = UserDefaults.standard.string(forKey: "nexus.menuBarTextColor") ?? textColorName
            fontFamily = UserDefaults.standard.string(forKey: "nexus.menuBarFontFamily") ?? fontFamily
            fontWeight = UserDefaults.standard.string(forKey: "nexus.menuBarFontWeight") ?? fontWeight
            let savedSize = UserDefaults.standard.double(forKey: "nexus.menuBarFontSize")
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
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusMiniDockModeChanged"))) { notif in
            if let val = notif.object as? String {
                miniDockDisplayMode = val
            } else {
                miniDockDisplayMode = UserDefaults.standard.string(forKey: "nexus.miniDockDisplayMode") ?? "Always Shown"
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusMenuBarAppsPlacementChanged"))) { notif in
            if let val = notif.object as? String {
                appsPlacement = val
            } else {
                appsPlacement = UserDefaults.standard.string(forKey: "nexus.menuBarAppsPlacement") ?? "Right Side (Classic Dock)"
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
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill((hoveredItemId == "barFolder" || isFinderHovered) ? Color.white.opacity(0.15) : Color.clear)
                    .frame(width: 22, height: 22)

                Image(nsImage: barFolderIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 15, height: 15)
                    .shadow(color: Color.black.opacity((hoveredItemId == "barFolder" || isFinderHovered) ? 0.35 : 0.15), radius: 1.0, y: 0.8)
            }
            .frame(width: 22, height: 22)
            .scaleEffect(fWave.scale)
            .offset(y: fWave.yOffset)
            .contentShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
        }
        .background(
            GeometryReader { geo in
                Color.clear.preference(key: FinderFrameKey.self, value: geo.frame(in: .named("StripRoot")))
            }
        )
        .buttonStyle(DockIconButtonStyle())
        .zIndex(fWave.zIndex)
        .onHover { h in
            withAnimation(.spring(response: 0.20, dampingFraction: 0.72)) {
                isFinderHovered = h
                if h { hoveredItemId = "barFolder" } else if hoveredItemId == "barFolder" { hoveredItemId = nil }
            }
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
                        UserDefaults.standard.set(color, forKey: "nexus.finderColor")
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
                        UserDefaults.standard.set(style, forKey: "nexus.finderIconStyle")
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

    private var trashItemView: some View {
        let tWave = magnificationWave(for: "trash")
        return Button(action: {
            openNativeTrash()
        }) {
            ZStack(alignment: .center) {
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill((hoveredItemId == "trash" || isTrashHovered) ? Color.white.opacity(0.15) : Color.clear)
                    .frame(width: 22, height: 22)

                Image(nsImage: trashIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 14.5, height: 14.5)
                    .shadow(color: Color.black.opacity((hoveredItemId == "trash" || isTrashHovered) ? 0.35 : 0.15), radius: 1.0, y: 0.8)
            }
            .frame(width: 22, height: 22)
            .scaleEffect(tWave.scale)
            .offset(y: tWave.yOffset)
            .contentShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
        }
        .background(
            GeometryReader { geo in
                Color.clear.preference(key: TrashFrameKey.self, value: geo.frame(in: .named("StripRoot")))
            }
        )
        .buttonStyle(DockIconButtonStyle())
        .zIndex(tWave.zIndex)
        .onHover { h in
            withAnimation(.spring(response: 0.20, dampingFraction: 0.72)) {
                isTrashHovered = h
                if h { hoveredItemId = "trash" } else if hoveredItemId == "trash" { hoveredItemId = nil }
            }
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

    private var batteryItemView: some View {
        Button(action: {
            if NSEvent.modifierFlags.contains(.option) {
                MenuBarActionDispatcher.shared.cycleNextBatteryStyle()
            } else {
                HapticFeedback.selection()
                MenuBarActionDispatcher.shared.handleBatteryClick()
            }
        }) {
            HStack(spacing: 3.5) {
                if let bImg = batteryImage {
                    let bW = max(18.0, min(50.0, bImg.size.width * (16.0 / max(1.0, bImg.size.height))))
                    Image(nsImage: bImg)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: bW, height: 16)
                } else {
                    Image(systemName: (batteryMonitor.isCharging && showChargingBolt) ? "battery.100.bolt" : "battery.100")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white)
                }

                if showChargingBolt && batteryMonitor.isCharging {
                    AnimatedChargingEffectView()
                        .transition(.scale.combined(with: .opacity))
                }

                if showBatteryPercentage && !isDigitalNumberOnlyStyle {
                    Text("\(batteryMonitor.batteryPct ?? 100)%")
                        .font(MenuBarThemeManager.resolveFont(family: fontFamily, size: CGFloat(menuBarFontSize), weightName: fontWeight).monospacedDigit())
                        .foregroundColor(percentageColor)
                }
            }
            .frame(height: 22)
            .padding(.horizontal, 4)
            .fixedSize()
            .contentShape(RoundedRectangle(cornerRadius: 6.0, style: .continuous))
        }
        .onHover { h in isBatteryHovered = h }
        .background(
            GeometryReader { geo in
                Color.clear.preference(key: BatteryFrameKey.self, value: geo.frame(in: .named("StripRoot")))
            }
        )
        .buttonStyle(DockIconButtonStyle())
        .help("Battery: \(batteryMonitor.batteryPct ?? 100)% (\(effectiveBatteryStyle)) — Click for Applications, right-click or ⌥-click to change style")
        .contextMenu {
            Button(LocalizedStrings.translateText("Next Battery Style ❯", lang: appLanguage)) {
                MenuBarActionDispatcher.shared.cycleNextBatteryStyle()
            }
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
            Menu(LocalizedStrings.translateText("Percentage Color", lang: appLanguage)) {
                ForEach(["Dynamic Level", "Pure White", "Neon Cyan", "Emerald Green", "Solar Orange", "Cyber Pink", "Electric Violet"], id: \.self) { mode in
                    Button(action: {
                        batteryColorMode = mode
                        UserDefaults.standard.set(mode, forKey: "nexus.batteryColorMode")
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
            Button(LocalizedStrings.translateText("Applications", lang: appLanguage)) {
                AppDelegate.shared?.toggleMenuBarApplicationsDropdown(anchor: .battery)
            }
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
            Section("⚡️ Google Gemini") {
                ForEach(LocalModelManager.cloudModels.filter { $0.provider == .gemini }) { model in
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
            Section("🧠 Anthropic Claude") {
                ForEach(LocalModelManager.cloudModels.filter { $0.provider == .claude }) { model in
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
            Section("❇️ OpenAI") {
                ForEach(LocalModelManager.cloudModels.filter { $0.provider == .openai }) { model in
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
            Section("💻 Local AI Models") {
                ForEach(LocalModelManager.cloudModels.filter { $0.provider == .local }) { model in
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
            Section("☁️ Cloud & System Services") {
                Button("Pop Down Chat (Dialogue Studio)...") {
                    DesktopWindowManager.shared.switchToStation(.chat)
                }
                Button("Application Atelier (Apps)...") {
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
        .help("Cloud AI & Services — Select Cloud Models (Gemini, Claude, OpenAI) & System")
    }

    @ViewBuilder
    private var switcherItemView: some View {
        Button(action: {
            HapticFeedback.selection()
            DesktopWindowManager.shared.cycleWorkspaceSwitcher()
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 6.0, style: .continuous)
                    .fill(isSwitcherHovered ? Color.white.opacity(0.20) : Color.white.opacity(0.06))
                    .frame(width: 22, height: 22)

                Image(systemName: switcherSymbol)
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundColor(.white.opacity(isSwitcherHovered ? 1.0 : 0.85))
                    .scaleEffect(isSwitcherHovered ? 1.12 : 1.0)
            }
            .frame(width: 22, height: 22)
            .contentShape(RoundedRectangle(cornerRadius: 6.0, style: .continuous))
        }
        .buttonStyle(DockIconButtonStyle())
        .onHover { h in withAnimation(.spring(response: 0.20, dampingFraction: 0.75)) { isSwitcherHovered = h } }
        .help(switcherHelpText)
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
    private var dockContextMenu: some View {
        Button(LocalizedStrings.translateText("Genie Settings...", lang: appLanguage)) {
            openGenieSettings()
        }
        Button(LocalizedStrings.translateText("Applications...", lang: appLanguage)) {
            toggleApplicationsOverlay()
        }
        Divider()
        Menu(LocalizedStrings.translateText("Cloud AI & Services", lang: appLanguage)) {
            Button("Pop Down Chat (Dialogue Studio)") {
                DesktopWindowManager.shared.switchToStation(.chat)
            }
            Button("Application Atelier (Apps)") {
                DesktopWindowManager.shared.switchToStation(.applications)
            }
            Button("Desktop Canvas") {
                DesktopWindowManager.shared.switchToStation(.desktop)
            }
        }
        Menu(LocalizedStrings.translateText("Mini Dock Style", lang: appLanguage)) {
            ForEach(["Apple Liquid Glass", "Frosted Glass", "Dark Obsidian Glass", "Neon Aurora Glass", "Clear (Transparent)"], id: \.self) { style in
                Button(style) {
                    miniDockBackgroundStyle = style
                    UserDefaults.standard.set(style, forKey: "nexus.miniDockBackgroundStyle")
                    NotificationCenter.default.post(name: NSNotification.Name("NexusMiniDockStyleChanged"), object: style)
                    AppDelegate.shared?.renderIcon()
                }
            }
        }
        Menu(LocalizedStrings.translateText("Mini Dock Mode", lang: appLanguage)) {
            Button(action: {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                    miniDockDisplayMode = "Always Shown"
                    UserDefaults.standard.set("Always Shown", forKey: "nexus.miniDockDisplayMode")
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
                    UserDefaults.standard.set("Always Hidden", forKey: "nexus.miniDockDisplayMode")
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
                UserDefaults.standard.set(newMode, forKey: "nexus.miniDockDisplayMode")
                NotificationCenter.default.post(name: NSNotification.Name("NexusMiniDockModeChanged"), object: newMode)
            }
        }
        Divider()
        Button(action: {
            dockActiveAppsOnly.toggle()
            UserDefaults.standard.set(dockActiveAppsOnly, forKey: "nexus.dockActiveAppsOnly")
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
        UserDefaults.standard.set(order, forKey: "nexus.customDockAppOrder")

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
        if shouldShowNotchGap(before: item) {
            Color.clear
                .frame(width: notchFillerGapWidth, height: 26)
                .contentShape(Rectangle())
                .onTapGesture {
                    HapticFeedback.selection()
                    _ = MenuBarThemeManager.cycleNextFontAndTheme()
                }
                .help(LocalizedStrings.translateText("Click open space to cycle Menu Bar Themes & Fonts 🎨", lang: appLanguage))
        }

        let wave = magnificationWave(for: item.id)
        let isBouncing = bouncingItemId == item.id
        let isHovered = hoveredItemId == item.id
        let isSmoking = smokingItemId == item.id
        let isCurrentActive = (item.runningApp != nil && (activePid == item.processIdentifier || item.runningApp?.isActive == true))
        let isDragging = (draggingItemId == item.id)
        let neighborOffset = horizontalDisplacement(for: item)
        let totalXOffset = isDragging ? dragOffset : neighborOffset

        Button(action: {
            if draggingItemId == nil {
                activateApp(item)
            }
        }) {
            dockAppButtonContent(item: item, isHovered: isHovered, isBouncing: isBouncing, isSmoking: isSmoking, isCurrentActive: isCurrentActive)
                .frame(width: 22, height: 22)
                .scaleEffect(isDragging ? (isDragOffThreshold ? 0.75 : 1.22) : (wave.scale * (isBouncing ? 1.28 : 1.0)))
                .offset(x: totalXOffset, y: isDragging ? dragYOffset : wave.yOffset)
                .opacity(isDragging && isDragOffThreshold ? 0.45 : 1.0)
                .shadow(color: isDragging ? Color.cyan.opacity(0.75) : Color.clear, radius: isDragging ? 6 : 0)
                .contentShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
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
            DragGesture(minimumDistance: 3)
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
                    } else if let draggingId = draggingItemId,
                       let fromIndex = dockItems.firstIndex(where: { $0.id == draggingId }) {
                        let slotWidth: CGFloat = 27.0
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
        .help(item.isRunning ? "\(item.name) — Click to bring to front, drag to reorder or drag off to remove" : "\(item.name) — Click to launch, drag to reorder or drag off to remove")
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
                    .frame(width: 26, height: 26)
                    .blur(radius: 3)
            }

            // Dock-style slot highlight on hover
            RoundedRectangle(cornerRadius: 5.5, style: .continuous)
                .fill(isHovered ? Color.white.opacity(0.18) : Color.clear)
                .frame(width: 22, height: 22)

            VStack(spacing: 1.2) {
                ZStack(alignment: .bottomTrailing) {
                    if let icon = item.icon {
                        Image(nsImage: icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 15.5, height: 15.5)
                            .clipShape(RoundedRectangle(cornerRadius: 4.0, style: .continuous))
                    } else {
                        Image(systemName: "app.dashed")
                            .font(.system(size: 11))
                            .frame(width: 15.5, height: 15.5)
                    }
                }
                .shadow(
                    color: Color.black.opacity(isHovered ? 0.45 : 0.18),
                    radius: isHovered ? 2.5 : 0.8,
                    y: isHovered ? 1.2 : 0.8
                )

                // macOS Dock Running Indicator Dot
                if item.isRunning {
                    Circle()
                        .fill(Color.white.opacity(isCurrentActive ? 1.0 : 0.70))
                        .frame(width: isCurrentActive ? 3.0 : 2.2, height: isCurrentActive ? 3.0 : 2.2)
                        .shadow(
                            color: isCurrentActive ? Color.white.opacity(0.9) : Color.black.opacity(0.5),
                            radius: isCurrentActive ? 1.5 : 0.5,
                            y: isCurrentActive ? 0 : 0.5
                        )
                } else {
                    Spacer().frame(height: 2.2)
                }
            }

            if smokeEffectsEnabled && isSmoking {
                let (prim, _, _) = GenieSmokeEngine.colors(for: smokeStyle)
                MiniDockSmokePuffView(color: prim)
            }
        }
    }

    @ViewBuilder
    private func dockAppContextMenu(item: DockAppItem) -> some View {
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
        Menu(LocalizedStrings.translateText("⚡️ Blazing Fast Move to Screen", lang: appLanguage)) {
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
                UserDefaults.standard.removeObject(forKey: "nexus.customDockAppOrder")
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
                    UserDefaults.standard.set(false, forKey: "nexus.dockActiveAppsOnly")
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
                    UserDefaults.standard.set(true, forKey: "nexus.dockActiveAppsOnly")
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
                    UserDefaults.standard.set(val, forKey: "nexus.dockAlwaysShowFinder")
                    refreshApps()
                }
            ))
            Toggle(LocalizedStrings.translateText("Always Show Settings", lang: appLanguage), isOn: Binding(
                get: { dockAlwaysShowSettings },
                set: { val in
                    dockAlwaysShowSettings = val
                    UserDefaults.standard.set(val, forKey: "nexus.dockAlwaysShowSettings")
                    refreshApps()
                }
            ))
            Toggle(LocalizedStrings.translateText("Always Show Trash", lang: appLanguage), isOn: Binding(
                get: { dockAlwaysShowTrash },
                set: { val in
                    dockAlwaysShowTrash = val
                    UserDefaults.standard.set(val, forKey: "nexus.dockAlwaysShowTrash")
                    refreshApps()
                }
            ))
            Toggle(LocalizedStrings.translateText("Always Show Genie Hub", lang: appLanguage), isOn: Binding(
                get: { dockAlwaysShowGenie },
                set: { val in
                    dockAlwaysShowGenie = val
                    UserDefaults.standard.set(val, forKey: "nexus.dockAlwaysShowGenie")
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
        AppDelegate.shared?.showMenuBarSettingsDropdown(targetTab: .system)
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

        let smokeOn = UserDefaults.standard.object(forKey: "nexus.smokeEffectsEnabled") == nil ? true : UserDefaults.standard.bool(forKey: "nexus.smokeEffectsEnabled")
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
    @AppStorage("nexus.appLanguage") var appLanguage: String = "English (US)"
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
            withAnimation(.easeOut(duration: 0.52)) {
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



