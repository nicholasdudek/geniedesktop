import AppKit
import SwiftUI

// MARK: - Menu Bar Theme & Appearance Utilities
public struct MenuBarThemeManager {
    public static let appleColorOptions: [String] = [
        "Classic White ⚪️",
        "Subtle Monochrome",
        "Apple Blue 🔵"
    ]

    public static let textColorOptions: [String] = [
        "Pure White ⚪️",
        "Subtle Gray 🔘",
        "Apple Blue 🔵",
        "Neon Cyan ⚡️",
        "Hot Pink 💖",
        "Royal Gold 👑",
        "Solar Amber ☀️",
        "Emerald Matrix 🟢",
        "Soft Lilac 💜"
    ]

    public static let activeAppColorOptions: [String] = [
        "Pure White ⚪️",
        "Matching Menu Items",
        "Apple Blue 🔵",
        "Neon Cyan ⚡️",
        "Hot Pink 💖",
        "Royal Gold 👑",
        "Solar Amber ☀️",
        "Emerald Matrix 🟢",
        "Soft Lilac 💜"
    ]

    public static let timeFormatOptions: [String] = [
        "Date & Time (12-Hour)",
        "Date & Time with Seconds (12-Hour)",
        "Date & Time (24-Hour)",
        "Date & Time with Seconds (24-Hour)",
        "Full Day, Date & Time",
        "Compact Date & Time",
        "Numeric Date & Time",
        "Time Only (12-Hour)",
        "Time Only with Seconds (12-Hour)",
        "Time Only (24-Hour)",
        "Time Only with Seconds (24-Hour)",
        "ISO 8601 Timestamp"
    ]

    public static func formatDate(_ date: Date, format: String) -> String {
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "en_US_POSIX")
        switch format {
        case "Date & Time with Seconds (12-Hour)":
            fmt.dateFormat = "EEE MMM d  h:mm:ss a"
        case "Date & Time (24-Hour)":
            fmt.dateFormat = "EEE MMM d  HH:mm"
        case "Date & Time with Seconds (24-Hour)":
            fmt.dateFormat = "EEE MMM d  HH:mm:ss"
        case "Full Day, Date & Time":
            fmt.dateFormat = "EEEE, MMM d  h:mm a"
        case "Compact Date & Time":
            fmt.dateFormat = "M/d  h:mm a"
        case "Numeric Date & Time":
            fmt.dateFormat = "M/d/yy, h:mm a"
        case "Time Only (12-Hour)":
            fmt.dateFormat = "h:mm a"
        case "Time Only with Seconds (12-Hour)":
            fmt.dateFormat = "h:mm:ss a"
        case "Time Only (24-Hour)":
            fmt.dateFormat = "HH:mm"
        case "Time Only with Seconds (24-Hour)":
            fmt.dateFormat = "HH:mm:ss"
        case "ISO 8601 Timestamp":
            fmt.dateFormat = "yyyy-MM-dd HH:mm"
        default: // "Date & Time (12-Hour)"
            fmt.dateFormat = "EEE MMM d  h:mm a"
        }
        return fmt.string(from: date)
    }

    public static func cycleNextTimeFormat() {
        let current = UserDefaults.standard.string(forKey: PrefKey.menuBarTimeFormat) ?? "Date & Time (12-Hour)"
        if let idx = timeFormatOptions.firstIndex(of: current) {
            let nextIdx = (idx + 1) % timeFormatOptions.count
            let next = timeFormatOptions[nextIdx]
            UserDefaults.standard.set(next, forKey: PrefKey.menuBarTimeFormat)
            NotificationCenter.default.post(name: NSNotification.Name("NexusMenuBarTimeFormatChanged"), object: next)
        } else {
            UserDefaults.standard.set("Date & Time (12-Hour)", forKey: PrefKey.menuBarTimeFormat)
            NotificationCenter.default.post(name: NSNotification.Name("NexusMenuBarTimeFormatChanged"), object: "Date & Time (12-Hour)")
        }
    }

    public static let fontFamilyOptions: [String] = [
        "SF Pro (Apple Default)",
        "SF Pro Rounded 🍏",
        "SF Mono 💻",
        "New York (Apple Serif) 🏛️",
        "JetBrains Mono ⚡️"
    ]

    public static let fontWeightOptions: [String] = [
        "Regular",
        "Medium",
        "Semibold",
        "Bold"
    ]

    public static let fontSizeOptions: [Double] = [
        11.0,
        12.0,
        13.0,
        14.0,
        15.0,
        16.0
    ]

    public static func resolveFont(family: String, size: CGFloat, weightName: String) -> Font {
        let w = resolveWeight(weightName)
        if family.contains("Rounded") {
            return .system(size: size, weight: w, design: .rounded)
        } else if family.contains("Mono") || family.contains("JetBrains") {
            return .system(size: size, weight: w, design: .monospaced)
        } else if family.contains("New York") || family.contains("Serif") {
            return .system(size: size, weight: w, design: .serif)
        } else {
            return .system(size: size, weight: w, design: .default)
        }
    }

    public static func resolveWeight(_ name: String) -> Font.Weight {
        switch name {
        case "Medium": return .medium
        case "Semibold": return .semibold
        case "Bold": return .bold
        default: return .regular
        }
    }

    public static func resolveColor(_ name: String) -> Color {
        if name.contains("Cyan") {
            return Color(red: 0.15, green: 0.88, blue: 1.0)
        } else if name.contains("Pink") {
            return Color(red: 1.0, green: 0.32, blue: 0.65)
        } else if name.contains("Gold") {
            return Color(red: 1.0, green: 0.84, blue: 0.0)
        } else if name.contains("Amber") {
            return Color(red: 1.0, green: 0.65, blue: 0.15)
        } else if name.contains("Emerald") || name.contains("Green") {
            return Color(red: 0.20, green: 0.90, blue: 0.45)
        } else if name.contains("Lilac") || name.contains("Purple") {
            return Color(red: 0.75, green: 0.55, blue: 1.0)
        } else if name.contains("Blue") {
            return Color.accentColor
        } else if name.contains("Gray") {
            return Color.secondary
        } else {
            return Color.white
        }
    }

    public static let backgroundOptions: [String] = [
        "Vitreous Liquid Crystal",
        "Satin Frosted Crystal",
        "Prismatic Sapphire Crystal",
        "Obsidian Black Lacquer",
        "Celestial Luminescence",
        "Bioluminescent Azure",
        "Pure Optic Transparency"
    ]

    public static let spanModeOptions: [String] = [
        "Suspended Horizon Capsule",
        "Continuous Panoramic Horizon",
        "Sculpted Monolith Pill"
    ]

    public static let heightModeOptions: [String] = [
        "Grand Dual-Tier Horizon (Camera Inset Cleared)",
        "Precision Slim Profile (Single Tier)"
    ]

    @ViewBuilder
    public static func resolveBackground(_ style: String) -> some View {
        switch style {
        case "Vitreous Liquid Crystal", "Liquid Glass (Apple Modern) 💎", "Translucent Glass Blur":
            ZStack {
                VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow, state: .active)
                LinearGradient(
                    stops: [
                        .init(color: Color.white.opacity(0.20), location: 0.0),
                        .init(color: Color.white.opacity(0.06), location: 0.28),
                        .init(color: Color.clear, location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                Color.blue.opacity(0.03)
            }
        case "Satin Frosted Crystal", "Frosted Glass Blur ❄️":
            ZStack {
                VisualEffectBlur(material: .menu, blendingMode: .behindWindow, state: .active)
                Color.white.opacity(0.08)
            }
        case "Prismatic Sapphire Crystal", "Pure Aero Crystal Glass ✨":
            ZStack {
                VisualEffectBlur(material: .popover, blendingMode: .behindWindow, state: .active)
                LinearGradient(
                    colors: [Color.cyan.opacity(0.08), Color.purple.opacity(0.05), Color.white.opacity(0.12)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        case "Obsidian Black Lacquer", "Obsidian Dark Glass 🌑", "Obsidian Dark":
            ZStack {
                VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow, state: .active)
                Color.black.opacity(0.78)
            }
        case "Celestial Luminescence", "Aurora Borealis Glass 🌌":
            ZStack {
                VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow, state: .active)
                LinearGradient(
                    colors: [
                        Color(red: 0.05, green: 0.55, blue: 0.45).opacity(0.18),
                        Color(red: 0.35, green: 0.08, blue: 0.55).opacity(0.16)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
        case "Bioluminescent Azure", "Cyber Neon Glass ⚡️":
            ZStack {
                VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow, state: .active)
                LinearGradient(
                    colors: [
                        Color.cyan.opacity(0.14),
                        Color.purple.opacity(0.12)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        case "Pure Optic Transparency", "Clear (Transparent) 🪟", "Clear (Transparent)":
            Color.clear
        default:
            ZStack {
                VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow, state: .active)
                LinearGradient(
                    stops: [
                        .init(color: Color.white.opacity(0.18), location: 0.0),
                        .init(color: Color.white.opacity(0.06), location: 0.25),
                        .init(color: Color.clear, location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }

    @discardableResult
    public static func cycleNextFontFamily() -> String {
        let current = UserDefaults.standard.string(forKey: PrefKey.menuBarFontFamily) ?? "SF Pro (Apple Default)"
        let nextIdx: Int = {
            if let idx = fontFamilyOptions.firstIndex(of: current) {
                return (idx + 1) % fontFamilyOptions.count
            }
            return 0
        }()
        let next = fontFamilyOptions[nextIdx]
        UserDefaults.standard.set(next, forKey: PrefKey.menuBarFontFamily)
        NotificationCenter.default.post(name: NSNotification.Name("NexusMenuBarFontFamilyChanged"), object: next)
        return next
    }

    @discardableResult
    public static func cycleNextTheme() -> String {
        let current = UserDefaults.standard.string(forKey: PrefKey.menuBarBackgroundStyle) ?? "Liquid Glass (Apple Modern) 💎"
        let nextIdx: Int = {
            if let idx = backgroundOptions.firstIndex(of: current) {
                return (idx + 1) % backgroundOptions.count
            }
            return 0
        }()
        let next = backgroundOptions[nextIdx]
        UserDefaults.standard.set(next, forKey: PrefKey.menuBarBackgroundStyle)
        NotificationCenter.default.post(name: NSNotification.Name("NexusMenuBarBackgroundStyleChanged"), object: next)
        return next
    }

    @discardableResult
    @MainActor
    public static func cycleNextFontAndTheme() -> (font: String, theme: String) {
        let nextFont = cycleNextFontFamily()
        let nextTheme = cycleNextTheme()
        CustomMenuBarManager.shared.rebuildWindows()
        return (nextFont, nextTheme)
    }
}

// MARK: -  Apple Logo Multi-Style View
public struct AppleLogoView: View {
    let style: String
    var size: CGFloat = 14

    public init(style: String, size: CGFloat = 14) {
        self.style = style
        self.size = size
    }

    public var body: some View {
        Image(systemName: "apple.logo")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .foregroundColor(.white)
            .shadow(color: Color.black.opacity(0.30), radius: 1, y: 0.5)
    }
}

// MARK: - Native Apple System Dropdowns (Original Control Center & Spotlight)
public enum NativeSystemMenuHelper {
    public static func triggerControlCenter() {
        DispatchQueue.global(qos: .userInteractive).async {
            let script = """
            tell application "System Events"
                tell process "ControlCenter"
                    try
                        click menu bar item 1 of menu bar 1
                    on error
                        try
                            click (first menu bar item of menu bar 1 whose description contains "Control" or title contains "Control")
                        end try
                    end try
                end tell
            end tell
            """
            if let appleScript = NSAppleScript(source: script) {
                var error: NSDictionary?
                appleScript.executeAndReturnError(&error)
                if error == nil { return }
            }

            // Fallback hardware event: Fn + C
            let src = CGEventSource(stateID: .hidSystemState)
            if let down = CGEvent(keyboardEventSource: src, virtualKey: 8, keyDown: true),
               let up = CGEvent(keyboardEventSource: src, virtualKey: 8, keyDown: false) {
                down.flags = .maskSecondaryFn
                up.flags = .maskSecondaryFn
                down.post(tap: .cghidEventTap)
                usleep(20_000)
                up.post(tap: .cghidEventTap)
            }
        }
    }

    public static func triggerSpotlight() {
        DispatchQueue.global(qos: .userInteractive).async {
            let script = """
            tell application "System Events"
                key code 49 using {command down}
            end tell
            """
            if let appleScript = NSAppleScript(source: script) {
                var error: NSDictionary?
                appleScript.executeAndReturnError(&error)
                if error == nil { return }
            }

            // Fallback hardware event: Cmd + Space
            let src = CGEventSource(stateID: .hidSystemState)
            if let down = CGEvent(keyboardEventSource: src, virtualKey: 49, keyDown: true),
               let up = CGEvent(keyboardEventSource: src, virtualKey: 49, keyDown: false) {
                down.flags = .maskCommand
                up.flags = .maskCommand
                down.post(tap: .cghidEventTap)
                usleep(20_000)
                up.post(tap: .cghidEventTap)
            }
        }
    }
}

// MARK: - Pass-Through Hosting View for Floating Margins & Transparent Headroom
@MainActor
public final class CustomMenuBarHostingView<Content: View>: NSHostingView<Content> {
    public override func hitTest(_ point: NSPoint) -> NSView? {
        let hit = super.hitTest(point)
        // If an interactive subview (button, icon, menu item, slider) was hit, ALWAYS return it immediately!
        if let hit = hit, hit !== self {
            return hit
        }
        // If click lands in empty background below the active bar shelf (hoverBloomRoom headroom), pass through
        if point.y < 8.0 {
            return nil
        }
        return hit === self ? nil : hit
    }
}

// MARK: - Full Menu Bar Window Overlay System
@MainActor
public final class CustomMenuBarWindow: NSWindow {
    public let targetDisplayID: CGDirectDisplayID
    public weak var targetScreen: NSScreen?
    public weak var hostingView: NSView?

    public static func metrics(for screen: NSScreen) -> (barHeight: CGFloat, topInset: CGFloat, hInset: CGFloat, hoverBloomRoom: CGFloat, windowHeight: CGFloat, isFloatingDock: Bool, isDoubleHeight: Bool) {
        let spanMode = UserDefaults.standard.string(forKey: PrefKey.menuBarSpanMode) ?? "Suspended Horizon Capsule"
        let heightMode = UserDefaults.standard.string(forKey: PrefKey.menuBarHeightMode) ?? "Grand Dual-Tier Horizon (Camera Inset Cleared)"
        let isDoubleHeight = heightMode.contains("Double") || heightMode.contains("Two Bars") || heightMode.contains("Dual-Tier")
        let isFloatingDock = (spanMode.contains("Dock") || spanMode.contains("Capsule") || spanMode.contains("Pill"))

        let nativeBarHeight = max(screen.safeAreaInsets.top, screen.frame.maxY - screen.visibleFrame.maxY)
        let resolvedNativeHeight: CGFloat = nativeBarHeight > 0 ? nativeBarHeight : 24.0

        let barH: CGFloat = isDoubleHeight ? 64.0 : resolvedNativeHeight
        let topInset: CGFloat = isFloatingDock ? 6.0 : 0.0
        let hInset: CGFloat = isFloatingDock ? 12.0 : 0.0
        let hoverBloomRoom: CGFloat = 8.0 // extra space for dock magnification
        let windowH = barH + topInset + hoverBloomRoom

        return (barH, topInset, hInset, hoverBloomRoom, windowH, isFloatingDock, isDoubleHeight)
    }

    public var effectiveScreen: NSScreen {
        if let screen = NSScreen.screens.first(where: {
            let id = ($0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value
            return id == self.targetDisplayID
        }) {
            return screen
        }
        if let ts = targetScreen, NSScreen.screens.contains(ts) {
            return ts
        }
        return self.screen ?? NSScreen.main ?? NSScreen.screens.first ?? NSScreen()
    }

    public init(screen: NSScreen) {
        self.targetScreen = screen
        let displayID = (screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber)?.uint32Value ?? 0
        self.targetDisplayID = displayID

        let m = CustomMenuBarWindow.metrics(for: screen)
        let barRect = NSRect(
            x: screen.frame.minX + m.hInset,
            y: screen.frame.maxY - m.windowHeight,
            width: screen.frame.width - (m.hInset * 2),
            height: m.windowHeight
        )
        super.init(
            contentRect: barRect,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        self.isOpaque = false
        self.backgroundColor = .clear
        let bgStyle = UserDefaults.standard.string(forKey: PrefKey.menuBarBackgroundStyle) ?? "Liquid Glass (Apple Modern) 💎"
        self.hasShadow = (bgStyle != "Clear (Transparent)" && m.isFloatingDock)
        // Level: Second-to-top layer in macOS window server hierarchy.
        // Sits directly above all standard application windows, floating windows, overlays, and full-screen auxiliary canvases,
        // while remaining directly below topmost system menus/popovers (popUpMenuWindow + 5) so popovers open seamlessly on top.
        self.level = NSWindow.Level(Int(CGWindowLevelForKey(.popUpMenuWindow)) + 4)
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
        self.isExcludedFromWindowsMenu = true
        self.sharingType = .readOnly
        self.hidesOnDeactivate = false
        self.canHide = false
        self.ignoresMouseEvents = false
        self.acceptsMouseMovedEvents = true
        self.alphaValue = 1.0
    }

    public override var canBecomeKey: Bool { false }
    public override var canBecomeMain: Bool { false }

    // While the Unified Command Window hosts the strip, refuse to come on screen no matter who asks.
    public override func orderFront(_ sender: Any?) {
        if CustomMenuBarManager.shared.shouldHideBar { return }
        super.orderFront(sender)
    }
    public override func orderFrontRegardless() {
        if CustomMenuBarManager.shared.shouldHideBar { return }
        super.orderFrontRegardless()
    }
    public override func makeKeyAndOrderFront(_ sender: Any?) {
        if CustomMenuBarManager.shared.shouldHideBar { return }
        super.makeKeyAndOrderFront(sender)
    }

    /// Guaranteed Immunity: Custom Menu Bar stays permanently pinned to the top of its resolved screen
    public override func setFrame(_ frameRect: NSRect, display flag: Bool) {
        let scr = self.effectiveScreen
        let m = CustomMenuBarWindow.metrics(for: scr)
        let pinned = NSRect(
            x: scr.frame.minX + m.hInset,
            y: scr.frame.maxY - m.windowHeight,
            width: scr.frame.width - (m.hInset * 2),
            height: m.windowHeight
        )
        super.setFrame(pinned, display: flag)
    }
}

// MARK: - Safe Camera Notch Geometry Analyzer
public struct ScreenNotchInfo {
    public let hasNotch: Bool
    public let leftWidth: CGFloat
    public let rightWidth: CGFloat
    public let notchWidth: CGFloat
    public let notchRect: NSRect

    public static func forScreen(_ screen: NSScreen) -> ScreenNotchInfo {
        return inspect(screen: screen)
    }

    public static func inspect(screen: NSScreen) -> ScreenNotchInfo {
        let screenW = screen.frame.width

        // 1. Hardware auxiliary safe top areas (True Apple Silicon Notch)
        if #available(macOS 12.0, *) {
            let leftInset = screen.auxiliaryTopLeftArea?.width ?? 0
            let rightInset = screen.auxiliaryTopRightArea?.width ?? 0
            if leftInset > 0 && rightInset > 0 {
                let nWidth = max(0, screenW - leftInset - rightInset)
                let nRect = NSRect(
                    x: screen.frame.minX + leftInset,
                    y: screen.frame.maxY - screen.safeAreaInsets.top,
                    width: nWidth,
                    height: screen.safeAreaInsets.top
                )
                return ScreenNotchInfo(
                    hasNotch: true,
                    leftWidth: leftInset,
                    rightWidth: rightInset,
                    notchWidth: nWidth,
                    notchRect: nRect
                )
            }
        }

        // 2. Safe area fallback for notched MacBook Pro / MacBook Air
        if screen.safeAreaInsets.top > 0 {
            let estimatedNotchW: CGFloat = 196.0
            let leftW = max(100, (screenW - estimatedNotchW) / 2.0)
            let rightW = leftW
            let nRect = NSRect(
                x: screen.frame.minX + leftW,
                y: screen.frame.maxY - screen.safeAreaInsets.top,
                width: estimatedNotchW,
                height: screen.safeAreaInsets.top
            )
            return ScreenNotchInfo(
                hasNotch: true,
                leftWidth: leftW,
                rightWidth: rightW,
                notchWidth: estimatedNotchW,
                notchRect: nRect
            )
        }

        // 3. Screen without notch (External display or non-notched MacBook)
        let half = screenW / 2.0
        return ScreenNotchInfo(
            hasNotch: false,
            leftWidth: half,
            rightWidth: half,
            notchWidth: 0,
            notchRect: .zero
        )
    }
}

// MARK: - Custom Menu Bar View (Whole Menu Bar Experience)
public struct CustomMenuBarView: View {
    let screen: NSScreen

    @ObservedObject var batteryMonitor = BatteryMonitor.shared
    @ObservedObject var volumeManager = MultiOutputVolumeManager.shared
    @ObservedObject var menuCompiler = MenuBarCompiler.shared
    @AppStorage(PrefKey.appLanguage) var appLanguage: String = "English (US)"
    @AppStorage(PrefKey.menuBarAppleColor) var appleColor: String = "Retro Rainbow 🌈"
    @AppStorage(PrefKey.menuBarTextColor) var textColorName: String = "Pure White ⚪️"
    @AppStorage(PrefKey.menuBarActiveAppColor) var activeAppColorName: String = "Pure White ⚪️"
    @AppStorage(PrefKey.menuBarColorsEnabled) var menuBarColorsEnabled: Bool = false
    @AppStorage(PrefKey.menuBarClockShowText) var showClockText: Bool = false
    @AppStorage(PrefKey.menuBarTimeFormat) var timeFormat: String = "Date & Time (12-Hour)"
    @AppStorage(PrefKey.menuBarFontFamily) var fontFamily: String = "SF Pro (Apple Default)"
    @AppStorage(PrefKey.menuBarFontWeight) var fontWeight: String = "Regular"
    @AppStorage(PrefKey.menuBarFontSize) var fontSize: Double = 15.0
    @AppStorage(PrefKey.menuBarBackgroundStyle) var backgroundStyle: String = "Vitreous Liquid Crystal"
    @AppStorage(PrefKey.menuBarSpanMode) var spanMode: String = "Suspended Horizon Capsule"
    @AppStorage(PrefKey.menuBarHeightMode) var heightMode: String = "Grand Dual-Tier Horizon (Camera Inset Cleared)"
    @AppStorage(PrefKey.statusIconStyle) var statusIconStyle: String = "Genie Executive Crest"
    @AppStorage(PrefKey.statusIconGlyph) var statusIconGlyph: String = "Genie Executive Crest"
    @AppStorage(PrefKey.miniDockBackgroundStyle) var miniDockBackgroundStyle: String = "Clear (Transparent)"

    private var frontAppName: String {
        let name = menuCompiler.activeAppName
        if name.isEmpty || name.contains("universalAccessAuthWarn") || name.contains("universalAccessAuth") || name == "SecurityAgent" || name == "loginwindow" {
            return "Genie"
        }
        return name
    }
    @State private var timeString: String = ""
    @State private var clockTimer: Timer?
    @State private var showVolumePopover: Bool = false
    @State private var showControlCenterPopover: Bool = false
    @AppStorage(PrefKey.menuBarAppsPlacement) var appsPlacement: String = "Right Side (Classic Dock)"
    @AppStorage(PrefKey.miniDockDisplayMode) var miniDockDisplayMode: String = "Always Shown"
    @AppStorage(PrefKey.showMiniDockInMenuBar) var showMiniDockInMenuBar: Bool = false
    @AppStorage(PrefKey.standardMenusSlidIn) var standardMenusSlidIn: Bool = true
    @AppStorage(PrefKey.appleControlsSlidIn) var appleControlsSlidIn: Bool = false
    @AppStorage(PrefKey.menuBarFullScreenBehavior) var fullScreenBehavior: String = "Auto-Hide on Hover"
    @State private var isMenuZoneHovered: Bool = false
    @State private var menuZoneDismissTimer: Timer? = nil
    @State private var isClockAreaHovered: Bool = false
    @State private var isWifiHovered: Bool = false
    @State private var isVolumeHovered: Bool = false
    @State private var isControlCenterHovered: Bool = false
    @State private var isSecondaryControlHovered: Bool = false
    @State private var isTimeHovered: Bool = false
    @State private var isBarHovered: Bool = false
    @State private var cycleFeedback: String? = nil

    private var resolvedTextColor: Color {
        guard menuBarColorsEnabled else { return .white }
        return MenuBarThemeManager.resolveColor(textColorName)
    }

    private var resolvedActiveAppColor: Color {
        guard menuBarColorsEnabled else { return .white }
        if activeAppColorName == "Matching Menu Items" {
            return resolvedTextColor
        }
        return MenuBarThemeManager.resolveColor(activeAppColorName)
    }

    private var resolvedFont: Font {
        MenuBarThemeManager.resolveFont(family: fontFamily, size: CGFloat(fontSize), weightName: fontWeight)
    }

    private var boldFont: Font {
        MenuBarThemeManager.resolveFont(family: fontFamily, size: CGFloat(fontSize), weightName: "Bold")
    }

    public init(screen: NSScreen) {
        self.screen = screen
    }

    private func setAppleColor(_ opt: String) {
        appleColor = opt
        NotificationCenter.default.post(name: NSNotification.Name("NexusMenuBarAppleColorChanged"), object: opt)
    }

    private var appleLogoMenu: some View {
        Button(action: {
            HapticFeedback.selection()
            // Click Apple switches all items from dock to all off / on
            let nextMode = (miniDockDisplayMode == "Always Hidden") ? "Always Shown" : "Always Hidden"
            miniDockDisplayMode = nextMode
            UserDefaults.standard.set(nextMode, forKey: PrefKey.miniDockDisplayMode)
            UserDefaults.standard.synchronize()
            NotificationCenter.default.post(name: NSNotification.Name("NexusMiniDockModeChanged"), object: nextMode)
        }) {
            AppleLogoView(style: appleColor, size: 14)
                .frame(width: 20, height: 20)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Section(LocalizedStrings.translateText(" Apple System", lang: appLanguage)) {
                Button(LocalizedStrings.translateText("About This Mac", lang: appLanguage)) {
                    NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Utilities/System Information.app"))
                }
                Button(LocalizedStrings.translateText("System Settings...", lang: appLanguage)) {
                    NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/System Settings.app"))
                }
                Button(LocalizedStrings.translateText("App Store...", lang: appLanguage)) {
                    NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/App Store.app"))
                }
            }

            Divider()

            Section(LocalizedStrings.translateText("Genie Studio", lang: appLanguage)) {
                Button(LocalizedStrings.translateText("Open Genie Studio...", lang: appLanguage)) {
                    AppDelegate.shared?.showMenuBarPopover()
                }
                Button(LocalizedStrings.translateText("🔊 Sound & Master Volume...", lang: appLanguage)) {
                    MasterVolumePopoverManager.shared.toggle(screen: screen)
                }
                Button(LocalizedStrings.translateText("📺 Screen Share Desktop 2 (Watch Over Work)...", lang: appLanguage)) {
                    DesktopScreenShareManager.shared.showDropDown(targetSpaceIndex: 2)
                }
                Button(LocalizedStrings.translateText("Genie Settings...", lang: appLanguage)) {
                    AppDelegate.shared?.showMenuBarSettingsDropdown(targetTab: .system)
                }
            }

            Divider()

            Section(LocalizedStrings.translateText("Mini Dock Visibility", lang: appLanguage)) {
                Button(LocalizedStrings.translateText(miniDockDisplayMode == "Always Hidden" ? "Show Mini Dock (All On)" : "Hide Mini Dock (All Off)", lang: appLanguage)) {
                    let nextMode = (miniDockDisplayMode == "Always Hidden") ? "Always Shown" : "Always Hidden"
                    miniDockDisplayMode = nextMode
                    UserDefaults.standard.set(nextMode, forKey: PrefKey.miniDockDisplayMode)
                    UserDefaults.standard.synchronize()
                    NotificationCenter.default.post(name: NSNotification.Name("NexusMiniDockModeChanged"), object: nextMode)
                }
            }

            Divider()

            Section(LocalizedStrings.translateText("Apple Logo Color", lang: appLanguage)) {
                ForEach(MenuBarThemeManager.appleColorOptions, id: \.self) { opt in
                    Button(action: {
                        self.setAppleColor(opt)
                    }) {
                        if opt == appleColor {
                            Text("\(opt) ✓")
                        } else {
                            Text(opt)
                        }
                    }
                }
            }

            Divider()

            Section(LocalizedStrings.translateText("Full Screen Menu Bar", lang: appLanguage)) {
                Button("Always Hide in Full Screen (Native Spaces) \(fullScreenBehavior != "Always Visible" ? "✓" : "")") {
                    fullScreenBehavior = "Always Hidden in Full Screen"
                    UserDefaults.standard.set("Always Hidden in Full Screen", forKey: PrefKey.menuBarFullScreenBehavior)
                    CustomMenuBarManager.shared.updateFullScreenBehavior()
                }
                Button("Always Visible \(fullScreenBehavior == "Always Visible" ? "✓" : "")") {
                    fullScreenBehavior = "Always Visible"
                    UserDefaults.standard.set("Always Visible", forKey: PrefKey.menuBarFullScreenBehavior)
                    CustomMenuBarManager.shared.updateFullScreenBehavior()
                }
            }

            Divider()

            Section(LocalizedStrings.translateText("Liquid Menu Bar", lang: appLanguage)) {
                Button(LocalizedStrings.translateText("Hide Floating Menu Bar", lang: appLanguage)) {
                    CustomMenuBarManager.shared.isEnabled = false
                }
            }

            Divider()

            Button(LocalizedStrings.translateText("Lock Screen", lang: appLanguage)) {
                let script = "tell application \"System Events\" to key code 12 using {control down, command down}"
                NSAppleScript(source: script)?.executeAndReturnError(nil)
            }

            Button(LocalizedStrings.translateText("Sleep", lang: appLanguage)) {
                let script = "tell application \"System Events\" to sleep"
                NSAppleScript(source: script)?.executeAndReturnError(nil)
            }

            Divider()

            Button(LocalizedStrings.translateText("Quit Genie (⌘Q)", lang: appLanguage)) {
                NSApplication.shared.terminate(nil)
            }
        }
        .help(miniDockDisplayMode == "Always Hidden" ? "Click to Show Mini Dock (Right-click for Apple Settings)" : "Click to Hide Mini Dock (Right-click for Apple Settings)")
    }

    @ViewBuilder
    private var tuckedColorsAndFontsMenu: some View {
        Menu(LocalizedStrings.translateText("🎨 Colors & Fonts", lang: appLanguage)) {
            // Master Color Toggle
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

            // Quick Color Presets
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

            // Custom Menu Items Color
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

            // Custom Active App Color
            Menu(LocalizedStrings.translateText("Active App Color", lang: appLanguage)) {
                ForEach(MenuBarThemeManager.activeAppColorOptions, id: \.self) { colorOpt in
                    Button(action: {
                        menuBarColorsEnabled = true
                        activeAppColorName = colorOpt
                        UserDefaults.standard.set(true, forKey: PrefKey.menuBarColorsEnabled)
                        UserDefaults.standard.set(colorOpt, forKey: PrefKey.menuBarActiveAppColor)
                        UserDefaults.standard.synchronize()
                        NotificationCenter.default.post(name: NSNotification.Name("NexusMenuBarActiveAppColorChanged"), object: colorOpt)
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

            // Typography: Font Family
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

            // Typography: Font Weight
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

            // Typography: Font Size
            Menu(LocalizedStrings.translateText("Font Size", lang: appLanguage)) {
                ForEach(MenuBarThemeManager.fontSizeOptions, id: \.self) { sz in
                    Button(action: {
                        fontSize = sz
                        UserDefaults.standard.set(sz, forKey: PrefKey.menuBarFontSize)
                        UserDefaults.standard.synchronize()
                        NotificationCenter.default.post(name: NSNotification.Name("NexusMenuBarThemeChanged"), object: nil)
                    }) {
                        HStack {
                            Text("\(Int(sz)) pt" + (sz == 13.0 ? " (Default)" : ""))
                            if fontSize == sz { Text("✓") }
                        }
                    }
                }
            }
        }
    }

    private var appTitleMenu: some View {
        Menu {
            Button(LocalizedStrings.translateText("About \(frontAppName)", lang: appLanguage)) {
                if frontAppName == "Genie" {
                    AppDelegate.shared?.showMenuBarSettingsDropdown(targetTab: .system)
                } else {
                    NSWorkspace.shared.frontmostApplication?.activate(options: [.activateAllWindows])
                }
            }
            Divider()
            Button(LocalizedStrings.translateText("Genie Settings...", lang: appLanguage)) {
                AppDelegate.shared?.showMenuBarSettingsDropdown(targetTab: .system)
            }
            Divider()
            Button(LocalizedStrings.translateText((miniDockDisplayMode == "Always Hidden" || miniDockDisplayMode == "Auto-Hide") ? "Enable Always On Mini Dock" : "Always Hide Mini Dock (Pop Down)", lang: appLanguage)) {
                let nextMode = (miniDockDisplayMode == "Always Hidden" || miniDockDisplayMode == "Auto-Hide") ? "Always Shown" : "Always Hidden"
                miniDockDisplayMode = nextMode
                UserDefaults.standard.set(nextMode, forKey: PrefKey.miniDockDisplayMode)
                UserDefaults.standard.synchronize()
                NotificationCenter.default.post(name: NSNotification.Name("NexusMiniDockModeChanged"), object: nil)
            }
            Menu(LocalizedStrings.translateText("Mini Dock Mode", lang: appLanguage)) {
                Button(action: {
                    miniDockDisplayMode = "Always Shown"
                    UserDefaults.standard.set("Always Shown", forKey: PrefKey.miniDockDisplayMode)
                    UserDefaults.standard.synchronize()
                    NotificationCenter.default.post(name: NSNotification.Name("NexusMiniDockModeChanged"), object: nil)
                }) {
                    HStack {
                        Text(LocalizedStrings.translateText("Always On (Permanently Shown)", lang: appLanguage))
                        if miniDockDisplayMode == "Always Shown" { Text("✓") }
                    }
                }
                Button(action: {
                    miniDockDisplayMode = "Always Hidden"
                    UserDefaults.standard.set("Always Hidden", forKey: PrefKey.miniDockDisplayMode)
                    UserDefaults.standard.synchronize()
                    NotificationCenter.default.post(name: NSNotification.Name("NexusMiniDockModeChanged"), object: nil)
                }) {
                    HStack {
                        Text(LocalizedStrings.translateText("Always Hidden (Pops Down on Hover)", lang: appLanguage))
                        if miniDockDisplayMode == "Always Hidden" || miniDockDisplayMode == "Auto-Hide" { Text("✓") }
                    }
                }
            }
            Divider()
            Button(LocalizedStrings.translateText("Hide \(frontAppName)", lang: appLanguage)) {
                NSWorkspace.shared.frontmostApplication?.hide()
            }
            Button(LocalizedStrings.translateText("Hide Others", lang: appLanguage)) {
                NSWorkspace.shared.hideOtherApplications()
            }
            Button(LocalizedStrings.translateText("Show All", lang: appLanguage)) {
                NSWorkspace.shared.runningApplications.forEach { $0.unhide() }
            }
            Divider()
            tuckedColorsAndFontsMenu
            Divider()
            Button(LocalizedStrings.translateText("Quit \(frontAppName)", lang: appLanguage)) {
                if frontAppName == "Genie" {
                    NSApplication.shared.terminate(nil)
                } else {
                    NSWorkspace.shared.frontmostApplication?.terminate()
                }
            }
        } label: {
            Text(frontAppName)
                .font(boldFont)
                .foregroundColor(resolvedActiveAppColor)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
        .buttonStyle(.plain)
        .menuIndicator(.hidden)
        .fixedSize()
    }

    private var standardMenus: some View {
        HStack(spacing: 4) {
            if frontAppName != "Genie" && !menuCompiler.compiledMenus.isEmpty && menuCompiler.compiledMenus.contains(where: { $0.axElement != nil }) {
                ForEach(menuCompiler.compiledMenus) { item in
                    Button(action: {
                        menuCompiler.triggerMenu(item)
                    }) {
                        MenuBarItemLabel(title: item.title, font: resolvedFont, textColor: resolvedTextColor)
                    }
                    .buttonStyle(.plain)
                    .contentShape(Rectangle())
                }
            } else {
                defaultStandardMenus
            }
        }
    }

    private var defaultStandardMenus: some View {
        Group {
            // File Menu
            Menu {
                Button(LocalizedStrings.translateText("New Finder Window", lang: appLanguage)) {
                    NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Library/CoreServices/Finder.app"))
                }
                Button(LocalizedStrings.translateText("New Terminal Window", lang: appLanguage)) {
                    NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Utilities/Terminal.app"))
                }
                Divider()
                Button(LocalizedStrings.translateText("Close Window", lang: appLanguage)) {
                    let script = "tell application \"System Events\" to tell (first process whose frontmost is true) to try\nclick (first button of first window whose subrole is \"AXCloseButton\")\nend try"
                    DispatchQueue.global(qos: .userInteractive).async {
                        NSAppleScript(source: script)?.executeAndReturnError(nil)
                    }
                }
            } label: {
                MenuBarItemLabel(title: LocalizedStrings.translateText("File", lang: appLanguage), font: resolvedFont, textColor: resolvedTextColor)
            }
            .menuStyle(.borderlessButton)
            .buttonStyle(.plain)
            .menuIndicator(.hidden)
            .fixedSize()

            // Edit Menu
            Menu {
                Button(LocalizedStrings.translateText("Undo", lang: appLanguage)) {
                    NSApp.sendAction(Selector(("undo:")), to: nil, from: nil)
                }
                Button(LocalizedStrings.translateText("Redo", lang: appLanguage)) {
                    NSApp.sendAction(Selector(("redo:")), to: nil, from: nil)
                }
                Divider()
                Button(LocalizedStrings.translateText("Cut", lang: appLanguage)) {
                    NSApp.sendAction(#selector(NSText.cut(_:)), to: nil, from: nil)
                }
                Button(LocalizedStrings.translateText("Copy", lang: appLanguage)) {
                    NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: nil)
                }
                Button(LocalizedStrings.translateText("Paste", lang: appLanguage)) {
                    NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: nil)
                }
                Button(LocalizedStrings.translateText("Select All", lang: appLanguage)) {
                    NSApp.sendAction(#selector(NSText.selectAll(_:)), to: nil, from: nil)
                }
            } label: {
                MenuBarItemLabel(title: LocalizedStrings.translateText("Edit", lang: appLanguage), font: resolvedFont, textColor: resolvedTextColor)
            }
            .menuStyle(.borderlessButton)
            .buttonStyle(.plain)
            .menuIndicator(.hidden)
            .fixedSize()

            // View Menu (Fourth button over from Apple - protected from highlight latching)
            Menu {
                Button(LocalizedStrings.translateText("Toggle Desktop Grid (⌘⇧D)", lang: appLanguage)) {
                    NotificationCenter.default.post(name: NSNotification.Name("NexusToggleDesktopFiles"), object: nil)
                }
                Button(LocalizedStrings.translateText("Toggle Mini Dock", lang: appLanguage)) {
                    NotificationCenter.default.post(name: NSNotification.Name("NexusToggleMiniDock"), object: nil)
                }
                Button(LocalizedStrings.translateText((miniDockDisplayMode == "Always Hidden" || miniDockDisplayMode == "Auto-Hide") ? "Enable Always On Mini Dock" : "Always Hide Mini Dock (Pop Down)", lang: appLanguage)) {
                    let nextMode = (miniDockDisplayMode == "Always Hidden" || miniDockDisplayMode == "Auto-Hide") ? "Always Shown" : "Always Hidden"
                    miniDockDisplayMode = nextMode
                    UserDefaults.standard.set(nextMode, forKey: PrefKey.miniDockDisplayMode)
                    UserDefaults.standard.synchronize()
                    NotificationCenter.default.post(name: NSNotification.Name("NexusMiniDockModeChanged"), object: nil)
                }
                Menu(LocalizedStrings.translateText("Mini Dock Mode", lang: appLanguage)) {
                    Button(action: {
                        miniDockDisplayMode = "Always Shown"
                        UserDefaults.standard.set("Always Shown", forKey: PrefKey.miniDockDisplayMode)
                        UserDefaults.standard.synchronize()
                        NotificationCenter.default.post(name: NSNotification.Name("NexusMiniDockModeChanged"), object: nil)
                    }) {
                        HStack {
                            Text(LocalizedStrings.translateText("Always On (Permanently Shown)", lang: appLanguage))
                            if miniDockDisplayMode == "Always Shown" { Text("✓") }
                        }
                    }
                    Button(action: {
                        miniDockDisplayMode = "Always Hidden"
                        UserDefaults.standard.set("Always Hidden", forKey: PrefKey.miniDockDisplayMode)
                        UserDefaults.standard.synchronize()
                        NotificationCenter.default.post(name: NSNotification.Name("NexusMiniDockModeChanged"), object: nil)
                    }) {
                        HStack {
                            Text(LocalizedStrings.translateText("Always Hidden (Pops Down on Hover)", lang: appLanguage))
                            if miniDockDisplayMode == "Always Hidden" || miniDockDisplayMode == "Auto-Hide" { Text("✓") }
                        }
                    }
                }
                Divider()
                tuckedColorsAndFontsMenu
                Divider()
                Button(LocalizedStrings.translateText("Expand Window (^)", lang: appLanguage)) {
                    NotificationCenter.default.post(name: NSNotification.Name("NexusToggleWindowExpander"), object: nil)
                }
            } label: {
                MenuBarItemLabel(title: LocalizedStrings.translateText("View", lang: appLanguage), font: resolvedFont, textColor: resolvedTextColor)
            }
            .menuStyle(.borderlessButton)
            .buttonStyle(.plain)
            .menuIndicator(.hidden)
            .fixedSize()

            // Window Menu
            Menu {
                Button(LocalizedStrings.translateText("Minimize", lang: appLanguage)) {
                    let script = "tell application \"System Events\" to tell (first process whose frontmost is true) to try\nset value of attribute \"AXMinimized\" of (first window) to true\nend try"
                    DispatchQueue.global(qos: .userInteractive).async {
                        NSAppleScript(source: script)?.executeAndReturnError(nil)
                    }
                }
                Button(LocalizedStrings.translateText("Zoom", lang: appLanguage)) {
                    let script = "tell application \"System Events\" to tell (first process whose frontmost is true) to try\nset value of attribute \"AXZoomButton\" of (first window) to true\nend try"
                    DispatchQueue.global(qos: .userInteractive).async {
                        NSAppleScript(source: script)?.executeAndReturnError(nil)
                    }
                }
                Divider()
                Button(LocalizedStrings.translateText("Bring All to Front", lang: appLanguage)) {
                    let script = "tell application \"System Events\" to tell (first process whose frontmost is true) to set frontmost to true"
                    DispatchQueue.global(qos: .userInteractive).async {
                        NSAppleScript(source: script)?.executeAndReturnError(nil)
                    }
                }
                Divider()
                Button(LocalizedStrings.translateText("Maximize to Top of Screen (Edge-to-Edge) (⌃⌥Return)", lang: appLanguage)) {
                    SmartGridManager.shared.maximizeFrontmostWindowToTopEdge(includeMenuBarArea: true)
                }
                Button("⚡️ Move Window to Next Screen (⌃⌥→)") {
                    ScreenWarpManager.shared.moveFrontmostWindowToNextScreen()
                }
                if NSScreen.screens.count > 1 {
                    Menu("⚡️ Teleport Window to Display...") {
                        ForEach(Array(NSScreen.screens.enumerated()), id: \.offset) { index, targetScreen in
                            let name = targetScreen.localizedName
                            Button("Display \(index + 1): \(name)") {
                                ScreenWarpManager.shared.moveFrontmostWindow(to: targetScreen)
                            }
                        }
                    }
                }
            } label: {
                MenuBarItemLabel(title: LocalizedStrings.translateText("Window", lang: appLanguage), font: resolvedFont, textColor: resolvedTextColor)
            }
            .menuStyle(.borderlessButton)
            .buttonStyle(.plain)
            .menuIndicator(.hidden)
            .fixedSize()

            // Help Menu
            Menu {
                Button(LocalizedStrings.translateText("Genie Studio Help", lang: appLanguage)) {
                    AppDelegate.shared?.showMenuBarSettingsDropdown(targetTab: .system)
                }
                Button(LocalizedStrings.translateText("Antigravity Documentation", lang: appLanguage)) {
                    if let url = URL(string: "https://github.com/google/antigravity") {
                        NSWorkspace.shared.open(url)
                    }
                }
            } label: {
                MenuBarItemLabel(title: LocalizedStrings.translateText("Help", lang: appLanguage), font: resolvedFont, textColor: resolvedTextColor)
            }
            .menuStyle(.borderlessButton)
            .buttonStyle(.plain)
            .menuIndicator(.hidden)
            .fixedSize()
        }
    }

    private var volumeIconName: String {
        if volumeManager.isMasterMuted {
            return "speaker.slash.fill"
        } else if volumeManager.masterVolume > 0.60 {
            return "speaker.wave.3.fill"
        } else if volumeManager.masterVolume > 0.20 {
            return "speaker.wave.2.fill"
        } else if volumeManager.masterVolume > 0.00 {
            return "speaker.wave.1.fill"
        } else {
            return "speaker.fill"
        }
    }

    private var systemControlsGroup: some View {
        HStack(spacing: 3) {
            // ── Wi-Fi Control ──
            Button(action: {
                NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/System Settings.app"))
            }) {
                Image(systemName: "wifi")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(resolvedTextColor)
                    .frame(width: 22, height: 22)
                    .background(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(isWifiHovered ? Color.white.opacity(0.14) : Color.clear)
                    )
            }
            .buttonStyle(.plain)
            .onHover { isWifiHovered = $0 }
            .help(LocalizedStrings.translateText("Wi-Fi Settings", lang: appLanguage))

            // ── Control Center (Stock Apple Control Panel Popover) ──
            Button(action: {
                HapticFeedback.selection()
                ControlCenterPopoverManager.shared.toggle(screen: screen)
            }) {
                Image(systemName: "switch.2")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(resolvedTextColor)
                    .frame(width: 22, height: 22)
                    .background(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill((isControlCenterHovered || ControlCenterPopoverManager.shared.isVisible) ? Color.white.opacity(0.14) : Color.clear)
                    )
            }
            .buttonStyle(.plain)
            .onHover { isControlCenterHovered = $0 }
            .help(LocalizedStrings.translateText("Control Center", lang: appLanguage))
            .contextMenu {
                Button(LocalizedStrings.translateText("Open Control Panel", lang: appLanguage)) {
                    ControlCenterPopoverManager.shared.show(screen: screen)
                }
                Button(LocalizedStrings.translateText("Open macOS Control Center", lang: appLanguage)) {
                    NativeSystemMenuHelper.triggerControlCenter()
                }
                Divider()
                Button(LocalizedStrings.translateText("Genie Settings...", lang: appLanguage)) {
                    AppDelegate.shared?.showMenuBarSettingsDropdown(targetTab: .system)
                }
            }

            // ── Second Control View (Spatial Display, Aspect Ratio & Physics) ──
            Button(action: {
                HapticFeedback.selection()
                SecondaryControlCenterPopoverManager.shared.toggle(screen: screen)
            }) {
                Image(systemName: "slider.horizontal.2.square")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(resolvedTextColor)
                    .frame(width: 22, height: 22)
                    .background(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill((isSecondaryControlHovered || SecondaryControlCenterPopoverManager.shared.isVisible) ? Color.cyan.opacity(0.24) : Color.clear)
                    )
            }
            .buttonStyle(.plain)
            .onHover { isSecondaryControlHovered = $0 }
            .help("Display Control (Aspect Ratio, Multi-Display & Window Warp)")
            .contextMenu {
                Button("Open Display Control") {
                    SecondaryControlCenterPopoverManager.shared.show(screen: screen)
                }
                Divider()
                Button("Warp Window to Next Display") {
                    ScreenWarpManager.shared.moveFrontmostWindowToNextScreen()
                }
            }
        }
    }


    private var timeButton: some View {
        Button(action: {
            HapticFeedback.selection()
            if showClockText {
                MenuBarThemeManager.cycleNextTimeFormat()
                updateTime()
            } else {
                showClockText = true
                UserDefaults.standard.set(true, forKey: PrefKey.menuBarClockShowText)
                updateTime()
            }
        }) {
            if showClockText {
                Text(timeString)
                    .font(resolvedFont.monospacedDigit())
                    .foregroundColor(resolvedTextColor)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(isTimeHovered ? Color.white.opacity(0.14) : Color.clear)
                    )
            } else {
                Image(systemName: "clock")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(resolvedTextColor)
                    .frame(width: 22, height: 22)
                    .background(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(isTimeHovered ? Color.white.opacity(0.14) : Color.clear)
                    )
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isTimeHovered = hovering
            if hovering {
                MenuBarActionDispatcher.shared.popOut(from: "time")
            } else {
                MenuBarActionDispatcher.shared.requestDismiss(from: "time")
            }
        }
        .help(showClockText ? LocalizedStrings.translateText("Click to cycle time format, right-click for format options", lang: appLanguage) : "\(timeString) (Right-click for options)")
        .contextMenu {
            Toggle(LocalizedStrings.translateText("Show Clock Text", lang: appLanguage), isOn: $showClockText)
                .onChange(of: showClockText) { _, val in
                    UserDefaults.standard.set(val, forKey: PrefKey.menuBarClockShowText)
                }

            Divider()

            Section(LocalizedStrings.translateText("Date & Time Format", lang: appLanguage)) {
                ForEach(MenuBarThemeManager.timeFormatOptions, id: \.self) { fmt in
                    Button(action: {
                        timeFormat = fmt
                        UserDefaults.standard.set(fmt, forKey: PrefKey.menuBarTimeFormat)
                        NotificationCenter.default.post(name: NSNotification.Name("NexusMenuBarTimeFormatChanged"), object: fmt)
                        updateTime()
                    }) {
                        HStack {
                            Text(fmt)
                            if timeFormat == fmt { Text("✓") }
                        }
                    }
                }
            }

            Divider()

            Button(LocalizedStrings.translateText("Open Calendar", lang: appLanguage)) {
                NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Calendar.app"))
            }

            Button(LocalizedStrings.translateText("Date & Time Settings...", lang: appLanguage)) {
                if let url = URL(string: "x-apple.systempreferences:com.apple.Date-Time-Settings.extension") {
                    NSWorkspace.shared.open(url)
                } else {
                    NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/System Settings.app"))
                }
            }

            Divider()

            Button(LocalizedStrings.translateText("Genie Settings...", lang: appLanguage)) {
                AppDelegate.shared?.showMenuBarSettingsDropdown(targetTab: .system)
            }
        }
    }

    private var statusAndBatterySection: some View {
        let isClearMode = miniDockBackgroundStyle.contains("Clear") || miniDockBackgroundStyle == "Transparent"
        return HStack(spacing: 6) {
            // ── Mini Dock Strip (Genie Launcher, Running Apps, Folder, Trash, Chevron, Battery Pill) ──
            if showMiniDockInMenuBar {
                MenuBarAppStripView()
            } else {
                Button(action: {
                    HapticFeedback.selection()
                    FinderChatWindowManager.shared.toggle()
                }) {
                    Image(nsImage: StatusIconRenderer.generateGlyphImage(glyph: statusIconGlyph.isEmpty ? "Genie Lamp 🪔" : statusIconGlyph, size: 16, phase: 0))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                }
                .buttonStyle(PlainButtonStyle())
                .contextMenu {
                    menuBarContextMenu
                }
            }

            // ── Clear Transparent Holder for System Controls & Icon Clock (No text) ──
            HStack(spacing: 5) {
                systemControlsGroup
                timeButton
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isClearMode ? Color.clear : Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(isClearMode ? Color.clear : Color.white.opacity(0.12), lineWidth: 0.8)
                    )
            )
        }
    }

    @ViewBuilder
    private var menuBarContextMenu: some View {
        Button(LocalizedStrings.translateText("↩️ Return to Default macOS Menu Bar (Uncover Spotlight & Siri)", lang: appLanguage)) {
            CustomMenuBarManager.shared.isEnabled = false
        }

        Divider()

        Menu("Menu Bar Style ❯") {
            ForEach(MenuBarThemeManager.backgroundOptions, id: \.self) { opt in
                Button(opt) {
                    backgroundStyle = opt
                    UserDefaults.standard.set(opt, forKey: PrefKey.menuBarBackgroundStyle)
                    CustomMenuBarManager.shared.rebuildWindows()
                }
            }
        }

        Menu("Menu Bar Layout ❯") {
            ForEach(MenuBarThemeManager.spanModeOptions, id: \.self) { opt in
                Button("\(opt) \(spanMode == opt ? "✓" : "")") {
                    spanMode = opt
                    UserDefaults.standard.set(opt, forKey: PrefKey.menuBarSpanMode)
                    CustomMenuBarManager.shared.rebuildWindows()
                }
            }
        }

        Menu("Menu Bar Height ❯") {
            ForEach(MenuBarThemeManager.heightModeOptions, id: \.self) { opt in
                Button("\(opt) \(heightMode == opt ? "✓" : "")") {
                    heightMode = opt
                    UserDefaults.standard.set(opt, forKey: PrefKey.menuBarHeightMode)
                    CustomMenuBarManager.shared.rebuildWindows()
                }
            }
        }

        Menu("Apps Placement ❯") {
            Button("Right Side (Classic Dock) \(appsPlacement != "Next to Menus (After Help)" ? "✓" : "")") {
                appsPlacement = "Right Side (Classic Dock)"
                UserDefaults.standard.set(appsPlacement, forKey: PrefKey.menuBarAppsPlacement)
                NotificationCenter.default.post(name: NSNotification.Name("NexusMenuBarAppsPlacementChanged"), object: appsPlacement)
            }
            Button("Next to Menus (After Help) \(appsPlacement == "Next to Menus (After Help)" ? "✓" : "")") {
                appsPlacement = "Next to Menus (After Help)"
                UserDefaults.standard.set(appsPlacement, forKey: PrefKey.menuBarAppsPlacement)
                NotificationCenter.default.post(name: NSNotification.Name("NexusMenuBarAppsPlacementChanged"), object: appsPlacement)
            }
        }

        Menu("Full Screen Behavior ❯") {
            Button("Always Hide in Full Screen (Native Spaces) \(fullScreenBehavior != "Always Visible" ? "✓" : "")") {
                fullScreenBehavior = "Always Hidden in Full Screen"
                UserDefaults.standard.set("Always Hidden in Full Screen", forKey: PrefKey.menuBarFullScreenBehavior)
                CustomMenuBarManager.shared.updateFullScreenBehavior()
            }
            Button("Always Visible \(fullScreenBehavior == "Always Visible" ? "✓" : "")") {
                fullScreenBehavior = "Always Visible"
                UserDefaults.standard.set("Always Visible", forKey: PrefKey.menuBarFullScreenBehavior)
                CustomMenuBarManager.shared.updateFullScreenBehavior()
            }
        }

        Divider()

        Button(LocalizedStrings.translateText("🔊 Sound & Master Volume...", lang: appLanguage)) {
            MasterVolumePopoverManager.shared.toggle(screen: screen)
        }

        Button(LocalizedStrings.translateText("📺 Screen Share Desktop 2 (Watch Over Work)...", lang: appLanguage)) {
            DesktopScreenShareManager.shared.showDropDown(targetSpaceIndex: 2)
        }

        Button(LocalizedStrings.translateText("Genie Settings...", lang: appLanguage)) {
            AppDelegate.shared?.showMenuBarSettingsDropdown(targetTab: .menuBar)
        }
    }

    public var body: some View {
        let m = CustomMenuBarWindow.metrics(for: screen)
        let isFloatingDock = m.isFloatingDock
        let isDoubleHeight = m.isDoubleHeight
        let barHeight = m.barHeight
        let topInset = m.topInset
        let notchInfo = ScreenNotchInfo.forScreen(screen)
        let effectiveLeftWidth = isFloatingDock ? max(100, notchInfo.leftWidth - 12) : notchInfo.leftWidth
        let effectiveRightWidth = isFloatingDock ? max(100, notchInfo.rightWidth - 12) : notchInfo.rightWidth

        return VStack(spacing: 0) {
            // ── Floating Margin from Screen Top ──
            if topInset > 0 {
                Spacer().frame(height: topInset)
            }

            // ── Main Floating Dock Shelf ──
            Group {
                if isDoubleHeight {
                    doubleHeightDockBody(
                        notchInfo: notchInfo,
                        effectiveLeftWidth: effectiveLeftWidth,
                        effectiveRightWidth: effectiveRightWidth,
                        barHeight: barHeight
                    )
                } else {
                    singleHeightDockBody(
                        notchInfo: notchInfo,
                        effectiveLeftWidth: effectiveLeftWidth,
                        effectiveRightWidth: effectiveRightWidth,
                        barHeight: barHeight
                    )
                }
            }
            .frame(height: barHeight)
            .padding(.horizontal, isFloatingDock ? 8 : 0)
            .onHover { hovering in
                withAnimation(.easeInOut(duration: 0.18)) {
                    isBarHovered = hovering
                }
            }
            .background(
                dockShelfBackground(isFloatingDock: isFloatingDock)
            )

            // Transparent headroom for downward dock icon magnification bloom
            Spacer(minLength: 0)
                .frame(height: m.hoverBloomRoom)
                .allowsHitTesting(false)
        }
        .frame(height: m.windowHeight)
        .onAppear {
            updateTime()
            updateFrontApp()
            let timer = Timer(timeInterval: 1.0, repeats: true) { _ in
                Task { @MainActor in
                    self.updateTime()
                    self.updateFrontApp()
                }
            }
            RunLoop.main.add(timer, forMode: .common)
            clockTimer = timer
        }
        .onReceive(NotificationCenter.default.publisher(for: NSWorkspace.didActivateApplicationNotification, object: nil)) { _ in
            menuCompiler.refreshActiveApp()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusMenuBarTimeFormatChanged"))) { notif in
            if let fmt = notif.object as? String {
                timeFormat = fmt
                updateTime()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusMenuBarActiveAppColorChanged"))) { notif in
            if let clr = notif.object as? String {
                activeAppColorName = clr
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusMenuBarThemeChanged"))) { _ in
            menuBarColorsEnabled = UserDefaults.standard.bool(forKey: PrefKey.menuBarColorsEnabled)
            textColorName = UserDefaults.standard.string(forKey: PrefKey.menuBarTextColor) ?? textColorName
            activeAppColorName = UserDefaults.standard.string(forKey: PrefKey.menuBarActiveAppColor) ?? activeAppColorName
        }
        .onDisappear {
            clockTimer?.invalidate()
            clockTimer = nil
        }
    }

    private func updateTime() {
        timeString = MenuBarThemeManager.formatDate(Date(), format: timeFormat)
    }

    private func updateFrontApp() {
        menuCompiler.refreshActiveApp()
    }

    // MARK: - Double Height Dock Body (Two Menu Bars Tall - Notch Cleared)
    @ViewBuilder
    private func doubleHeightDockBody(
        notchInfo: ScreenNotchInfo,
        effectiveLeftWidth: CGFloat,
        effectiveRightWidth: CGFloat,
        barHeight: CGFloat
    ) -> some View {
        let topRowHeight: CGFloat = max(24.0, (barHeight - 6.0) * 0.44)
        let bottomRowHeight: CGFloat = max(28.0, (barHeight - 6.0) * 0.56)

        VStack(spacing: 3) {
            // ── TOP ROW: Apple Menu & App Menus on Left, Camera Notch in Center, System Status on Right ──
            HStack(spacing: 0) {
                // Left Wing: Apple Logo + App Title & Menus
                HStack(spacing: 6) {
                    appleLogoMenu
                        .padding(.leading, 8)
                    HStack(spacing: 6) {
                        appTitleMenu
                        standardMenus
                    }
                    Spacer(minLength: 4)
                }
                .frame(width: notchInfo.hasNotch ? effectiveLeftWidth : nil, alignment: .leading)

                // Notch Clearance
                if notchInfo.hasNotch {
                    Color.clear
                        .frame(width: notchInfo.notchWidth, height: topRowHeight)
                        .contentShape(Rectangle())
                        .contextMenu {
                            menuBarContextMenu
                        }
                } else {
                    Color.clear
                        .frame(maxWidth: .infinity, maxHeight: topRowHeight)
                        .contentShape(Rectangle())
                        .contextMenu {
                            menuBarContextMenu
                        }
                }

                // Right Wing: Volume, Battery, Control Center, Clock (Native Apple Unenclosed Spacing)
                HStack(spacing: 8) {
                    Spacer(minLength: 0)
                    systemControlsGroup
                    timeButton
                }
                .frame(width: notchInfo.hasNotch ? effectiveRightWidth : nil, alignment: .trailing)
                .padding(.trailing, 10)
            }
            .frame(height: topRowHeight)

            // Ultra-subtle Apple Hairline Separator
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.clear, Color.white.opacity(0.12), Color.white.opacity(0.12), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 0.5)
                .padding(.horizontal, 12)

            // ── BOTTOM ROW: Continuous Apple Liquid Glass Dock Shelf ──
            HStack(spacing: 8) {
                // ── ZONE 1: Desktop Spaces & Clean Canvas (Views) ──
                HStack(spacing: 6) {
                    MiniMenuBarDesktopSpacesView()

                    // Clean Desktop Files Toggle
                    Button(action: {
                        HapticFeedback.selection()
                        let cur = DesktopFilesManager.shared.areDesktopFilesVisible
                        DesktopFilesManager.shared.setDesktopFilesVisible(!cur)
                    }) {
                        Image(systemName: DesktopFilesManager.shared.areDesktopFilesVisible ? "eye.fill" : "eye.slash.fill")
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundColor(.white.opacity(DesktopFilesManager.shared.areDesktopFilesVisible ? 0.90 : 0.45))
                            .frame(width: 26, height: 26)
                            .background(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(Color.white.opacity(0.06))
                            )
                    }
                    .buttonStyle(.plain)
                    .help("Toggle Desktop Files Visibility (Clean Canvas)")

                    // Spatial Formations Toggle
                    Button(action: {
                        HapticFeedback.selection()
                        NotificationCenter.default.post(name: NSNotification.Name("NexusToggleDesktopGrid"), object: nil)
                    }) {
                        Image(systemName: "square.grid.2x2.fill")
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundColor(.white.opacity(0.85))
                            .frame(width: 26, height: 26)
                            .background(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(Color.white.opacity(0.06))
                            )
                    }
                    .buttonStyle(.plain)
                    .help("Architectural Canvas & Formations (⌘⇧D)")
                }
                .padding(.leading, 8)

                // Classic macOS Dock Hairline Divider
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.clear, Color.white.opacity(0.22), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 1, height: 18)

                // ── ZONE 2: Application Atelier (Apps Dock) ──
                MenuBarDockAppsGridView()

                Spacer(minLength: 8)

                // Classic macOS Dock Hairline Divider
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.clear, Color.white.opacity(0.22), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 1, height: 18)

                // ── ZONE 3: Executive Utilities (Chat, Console, Notes, Snapshot, Preferences) ──
                HStack(spacing: 4) {
                    // Dialogue Studio (Chat)
                    Button(action: {
                        HapticFeedback.selection()
                        FinderChatWindowManager.shared.toggle()
                    }) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.88))
                            .frame(width: 28, height: 26)
                            .background(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(Color.white.opacity(0.06))
                            )
                    }
                    .buttonStyle(.plain)
                    .help("Open Dialogue Studio (⌘⌥Space)")

                    // Precision Console (Terminal)
                    Button(action: {
                        HapticFeedback.selection()
                        FinderChatWindowManager.shared.show()
                    }) {
                        Image(systemName: "terminal.fill")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.88))
                            .frame(width: 28, height: 26)
                            .background(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(Color.white.opacity(0.06))
                            )
                    }
                    .buttonStyle(.plain)
                    .help("Launch Terminal Studio")

                    // Executive Memorandum (Notes)
                    Button(action: {
                        HapticFeedback.selection()
                        FinderChatWindowManager.shared.show()
                    }) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundColor(.white.opacity(0.88))
                            .frame(width: 28, height: 26)
                            .background(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(Color.white.opacity(0.06))
                            )
                    }
                    .buttonStyle(.plain)
                    .help("Open Notes & Creations")

                    // Chrono-Capture (Screen Camera Snapshot)
                    Button(action: {
                        HapticFeedback.selection()
                        FinderChatWindowManager.shared.show()
                    }) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundColor(.white.opacity(0.88))
                            .frame(width: 28, height: 26)
                            .background(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(Color.white.opacity(0.06))
                            )
                    }
                    .buttonStyle(.plain)
                    .help("Screen Snapshot & Multimodal Inspector")

                    // Atelier Preferences
                    Button(action: {
                        HapticFeedback.selection()
                        AppDelegate.shared?.showMenuBarSettingsDropdown(targetTab: .menuBar)
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundColor(.white.opacity(0.88))
                            .frame(width: 28, height: 26)
                            .background(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(Color.white.opacity(0.06))
                            )
                    }
                    .buttonStyle(.plain)
                    .help("Atelier Console Preferences...")
                }
                .padding(.trailing, 10)
            }
            .frame(height: bottomRowHeight)
        }
    }

    // MARK: - Single Height Dock Body (Classic Compact)
    @ViewBuilder
    private func singleHeightDockBody(
        notchInfo: ScreenNotchInfo,
        effectiveLeftWidth: CGFloat,
        effectiveRightWidth: CGFloat,
        barHeight: CGFloat
    ) -> some View {
        HStack(spacing: 0) {
            // Wing 1: Left Side of Notch
            HStack(spacing: 6) {
                appleLogoMenu
                    .padding(.leading, 8)
                HStack(spacing: 6) {
                    appTitleMenu
                    standardMenus
                }
                Capsule().fill(Color.white.opacity(0.20)).frame(width: 1, height: 13).padding(.horizontal, 3)
                MiniMenuBarDesktopSpacesView()
                if appsPlacement == "Next to Menus (After Help)" {
                    Capsule().fill(Color.white.opacity(0.18)).frame(width: 1, height: 13).padding(.horizontal, 3)
                    MenuBarDockAppsGridView()
                }
                Spacer(minLength: 4)
            }
            .frame(width: notchInfo.hasNotch ? effectiveLeftWidth : nil, alignment: .leading)

            // Zone 2: Notch Clearance
            if notchInfo.hasNotch {
                Color.clear
                    .frame(width: notchInfo.notchWidth, height: barHeight)
                    .contentShape(Rectangle())
                    .contextMenu {
                        menuBarContextMenu
                    }
            } else {
                Color.clear
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
                    .contextMenu {
                        menuBarContextMenu
                    }
            }

            // Wing 3: Right Side of Notch
            HStack(spacing: 8) {
                Spacer(minLength: 0)
                statusAndBatterySection
            }
            .frame(minWidth: notchInfo.hasNotch ? min(effectiveRightWidth, 120) : nil, maxWidth: notchInfo.hasNotch ? effectiveRightWidth : .infinity, alignment: .trailing)
            .padding(.trailing, 8)
        }
    }

    // MARK: - Dock Shelf Background (Frosted Liquid Glass with Specular Rim Highlight)
    @ViewBuilder
    private func dockShelfBackground(isFloatingDock: Bool) -> some View {
        let cornerRadius: CGFloat = isFloatingDock ? 18.0 : 0.0
        let isClearMode = backgroundStyle.contains("Clear")

        ZStack {
            if !isClearMode {
                // Frosted Liquid Glass Shelf
                MenuBarThemeManager.resolveBackground(backgroundStyle)

                // Specular top rim illumination highlight (authentic macOS Dock reflection)
                LinearGradient(
                    stops: [
                        .init(color: Color.white.opacity(0.24), location: 0.0),
                        .init(color: Color.white.opacity(0.06), location: 0.20),
                        .init(color: Color.clear, location: 0.70),
                        .init(color: Color.white.opacity(0.04), location: 1.0)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            } else {
                // Frosted shield so native menu bar items underneath do not bleed through and collide with text
                VisualEffectBlur(material: .menu, blendingMode: .behindWindow, state: .active)
                Color.black.opacity(0.85)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(isClearMode ? 0.14 : 0.38), location: 0.0),
                            .init(color: Color.white.opacity(isClearMode ? 0.04 : 0.14), location: 0.50),
                            .init(color: Color.white.opacity(isClearMode ? 0.02 : 0.22), location: 1.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: isFloatingDock ? 0.95 : 0.5
                )
        )
        .shadow(
            color: isFloatingDock ? Color.black.opacity(0.40) : Color.clear,
            radius: isFloatingDock ? 16.0 : 0.0,
            x: 0,
            y: isFloatingDock ? 6.0 : 0.0
        )
    }
}

// MARK: - Custom Menu Bar Manager Singleton
@MainActor
public final class CustomMenuBarManager: ObservableObject {
    public static let shared = CustomMenuBarManager()

    @Published public var menuBarWindows: [CustomMenuBarWindow] = []
    public private(set) var isGenieOpen: Bool = false
    public private(set) var isMissionControlActive: Bool = false
    /// True while the Unified Command Window is showing; the strip lives inside that window instead.
    public private(set) var isSuppressedByUnifiedWindow: Bool = false

    private var hoverTimer: Timer?
    private var isPointerNearBar = false
    private var lastHoverDate = Date.distantPast

    public var shouldHideBar: Bool {
        let autoHide = UserDefaults.standard.string(forKey: PrefKey.menuBarFullScreenBehavior) == "Auto-Hide on Hover"
        return !isEnabled || ((autoHide || isSuppressedByUnifiedWindow) && !isPointerNearBar)
    }

    private func refreshHover() {
        let pointer = NSEvent.mouseLocation
        let hovering = menuBarWindows.contains { window in
            let screen = window.effectiveScreen
            let height = CustomMenuBarWindow.metrics(for: screen).windowHeight
            let region = NSRect(x: screen.frame.minX, y: screen.frame.maxY - height,
                                width: screen.frame.width, height: height)
            return region.contains(pointer)
        }
        if hovering { lastHoverDate = Date() }
        let revealed = hovering || Date().timeIntervalSince(lastHoverDate) < 0.6
            || AppDelegate.shared?.menuBarPanel?.isVisible == true
        if revealed != isPointerNearBar {
            isPointerNearBar = revealed
            updateVisibility()
        }
    }

    public func setSuppressedByUnifiedWindow(_ suppressed: Bool) {
        isSuppressedByUnifiedWindow = suppressed
        updateVisibility()
    }

    public var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: PrefKey.customMenuBarEnabled) }
        set {
            UserDefaults.standard.set(newValue, forKey: PrefKey.customMenuBarEnabled)
            NotificationCenter.default.post(name: NSNotification.Name("NexusCustomMenuBarToggled"), object: nil)
            rebuildWindows()
        }
    }

    private init() {
        hoverTimer = Timer(timeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.refreshHover() }
        }
        if let hoverTimer { RunLoop.main.add(hoverTimer, forMode: .common) }
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in self?.updateVisibility() }
        }
        // 1. Screen changes
        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.rebuildWindows()
            }
        }

        // 2. Geometry changes
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NexusMenuBarGeometryChanged"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.rebuildWindows()
            }
        }

        // 3. Keep Menu Bar & Mini Dock pinned and superseding top layer UI across desktop page changes
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NexusDesktopPageChanged"),
            object: nil,
            queue: .main
        ) { [weak self] notif in
            let page = (notif.object as? Int) ?? 0
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.isGenieOpen = (page == 1)
                self.updateVisibility()
            }
        }

        // 4. Active Desktop & Space Transitions: Re-pin and synchronize menu bar with active desktop space
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.updateVisibility()
            }
        }
    }

    public func updateVisibility() {
        let shouldHide = shouldHideBar
        for win in menuBarWindows {
            if shouldHide {
                win.alphaValue = 0.0
                win.orderOut(nil)
            } else {
                win.alphaValue = 1.0
                win.orderFrontRegardless()
            }
        }
    }

    public func updateFullScreenBehavior() {
        let behavior = UserDefaults.standard.string(forKey: PrefKey.menuBarFullScreenBehavior) ?? "Always Visible"
        for win in menuBarWindows {
            if behavior == "Always Visible" {
                win.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
            } else {
                win.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
            }
        }
        updateVisibility()
    }

    public func rebuildWindows() {
        for win in menuBarWindows {
            win.orderOut(nil)
        }
        menuBarWindows.removeAll()

        if isEnabled {
            AppDelegate.shared?.statusItem?.isVisible = false
            AppDelegate.shared?.statusItem?.length = 0
            for screen in NSScreen.screens {
                let win = CustomMenuBarWindow(screen: screen)
                let hosting = CustomMenuBarHostingView(rootView: CustomMenuBarView(screen: screen))
                win.contentView = hosting
                win.hostingView = hosting
                if !shouldHideBar { win.orderFront(nil) }
                menuBarWindows.append(win)
            }
        } else {
            AppDelegate.shared?.statusItem?.isVisible = true
            AppDelegate.shared?.statusItem?.length = NSStatusItem.variableLength
            AppDelegate.shared?.setupStatusItemView()
        }
    }

    public func toggle() {
        let current = isEnabled
        isEnabled = !current
    }
}

// MARK: - Menu Bar Item Label with Active Hover Protection
public struct MenuBarItemLabel: View {
    public let title: String
    public let font: Font
    public let textColor: Color
    @State private var isHovered: Bool = false

    public init(title: String, font: Font, textColor: Color) {
        self.title = title
        self.font = font
        self.textColor = textColor
    }

    public var body: some View {
        Text(title)
            .font(font)
            .foregroundColor(isHovered ? .white : textColor.opacity(0.92))
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(isHovered ? Color.white.opacity(0.14) : Color.clear)
            )
            .contentShape(Rectangle())
            .onHover { h in
                isHovered = h
            }
    }
}

