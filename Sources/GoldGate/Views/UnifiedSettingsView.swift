import AppKit
import SwiftUI

// MARK: - ⚙️ Unified Apple-Approved Liquid Glass Settings View
// Matches the exact same liquid glass floating window format as the Genie Chat Window.
// Features a top glass switcher ribbon, searchable translucent sidebar, and floating glass cards.

public enum UnifiedSettingsTab: String, CaseIterable, Identifiable {
    case chat = "Genie Chat 💬"
    case miniDock = "Mini Dock & Bar"
    case virtualScreen = "Screen Size & Matrix 📱"
    case applications = "Applications"
    case desktop = "Desktop & Files"
    case soundAndSmoke = "Sound & Effects"
    case models = "AI Models & Engines"
    case livingGlass = "Living Glass & UI"
    case systemAccess = "Full Computer Access"
    case huggingface = "Hugging Face Hub"
    case worldClock = "World Clock & Alarms ⏰"
    case generalAndPrivacy = "General & Privacy"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .chat: return "bubble.left.and.bubble.right.fill"
        case .miniDock: return "menubar.rectangle"
        case .virtualScreen: return "iphone.and.arrow.forward"
        case .applications: return "square.grid.2x2.fill"
        case .desktop: return "desktopcomputer"
        case .soundAndSmoke: return "speaker.wave.2.fill"
        case .models: return "brain.head.profile"
        case .livingGlass: return "sparkles"
        case .systemAccess: return "bolt.shield.fill"
        case .huggingface: return "cube.fill"
        case .worldClock: return "alarm.fill"
        case .generalAndPrivacy: return "lock.shield.fill"
        }
    }

    public var tintColor: Color {
        switch self {
        case .chat: return .cyan
        case .miniDock: return .blue
        case .virtualScreen: return .green
        case .applications: return .indigo
        case .desktop: return .teal
        case .soundAndSmoke: return .orange
        case .models: return Color(red: 0.85, green: 0.47, blue: 0.36)
        case .livingGlass: return .cyan
        case .systemAccess: return .green
        case .huggingface: return .yellow
        case .worldClock: return Color(red: 1.0, green: 0.58, blue: 0.0)
        case .generalAndPrivacy: return .purple
        }
    }

    public var keywords: [String] {
        switch self {
        case .chat: return ["chat", "dialogue", "ai", "models", "gemini", "claude", "gpt", "ollama", "prompts", "stream", "history"]
        case .miniDock: return ["dock", "bar", "menu bar", "status icon", "battery", "percentage", "genie", "lamp", "person", "style"]
        case .virtualScreen: return ["screen", "display", "size", "iphone", "matrix", "trickster", "virtual", "compact", "720p", "ipad", "half", "split", "scale", "pioneer"]
        case .applications: return ["applications", "apps", "grid", "slide", "direction", "launcher", "overlay", "size", "spacing"]
        case .desktop: return ["desktop", "files", "hide", "clean", "matrix", "wallpaper"]
        case .soundAndSmoke: return ["sound", "effects", "audio", "haptics", "smoke", "plumes", "animation"]
        case .models: return ["ai", "models", "ollama", "lm studio", "gemini", "claude", "gpt", "mps", "metal", "ram", "48gb"]
        case .livingGlass: return ["glass", "living", "atmosphere", "translucent", "vibrancy", "theme", "emotion", "120fps"]
        case .systemAccess: return ["system", "access", "accessibility", "cgevent", "shortcuts", "axuielement", "applescript", "screen", "arrow", "arrows", "desktop switching", "spaces"]
        case .huggingface: return ["hugging face", "hf", "gguf", "spaces", "gradio", "hub", "models", "download"]
        case .worldClock: return ["world clock", "clock", "time", "timezone", "time zone", "city", "pillow", "watch", "dock", "alarm", "wake", "snooze", "call", "meeting"]
        case .generalAndPrivacy: return ["general", "privacy", "permissions", "accessibility", "screen recording", "login", "language", "reset"]
        }
    }
}

public struct UnifiedSettingsView: View {
    @AppStorage(PrefKey.appLanguage) var appLanguage: String = "English (US)"
    @ObservedObject var localModels = LocalModelManager.shared
    public var onBackToApps: () -> Void = {}
    public var onClose: () -> Void = {}

    @State private var selectedTab: UnifiedSettingsTab = .miniDock
    @State private var searchText: String = ""
    @State private var isSidebarVisible: Bool = true
    @State private var statusFeedback: String? = nil

    // Mini Dock & Bar
    @AppStorage(PrefKey.menuBarAppSwitcherEnabled) private var menuBarAppSwitcherEnabled: Bool = true
    @AppStorage(PrefKey.miniDockDisplayMode) private var miniDockDisplayMode: String = "Always Shown"
    @AppStorage(PrefKey.dockActiveAppsOnly) private var dockActiveAppsOnly: Bool = false
    @AppStorage(PrefKey.dockAlwaysShowTrash) private var dockAlwaysShowTrash: Bool = true
    @AppStorage(PrefKey.dockShowFolderStacks) private var dockShowFolderStacks: Bool = true
    @AppStorage(PrefKey.dockAlwaysShowFinder) private var dockAlwaysShowFinder: Bool = true
    @AppStorage(PrefKey.dockAlwaysShowSettings) private var dockAlwaysShowSettings: Bool = true
    @AppStorage(PrefKey.dockAlwaysShowGenie) private var dockAlwaysShowGenie: Bool = true
    @AppStorage(PrefKey.miniDockBackgroundStyle) private var miniDockBackgroundStyle: String = "Clear (Transparent)"
    @AppStorage(PrefKey.menuBarAppCount) private var menuBarAppCount: Int = 3
    @AppStorage(PrefKey.statusIconGlyph) private var statusIconGlyph: String = "Genie Person 🧞‍♂️"
    @AppStorage(PrefKey.statusIconStyle) private var statusIconStyle: String = "Genie Person 🧞‍♂️"
    @AppStorage(PrefKey.isCollapsedIntoBattery) private var isCollapsedIntoBattery: Bool = false
    @AppStorage(PrefKey.unifiedCommandWindowEnabled) private var unifiedCommandWindowEnabled: Bool = true
    @AppStorage(PrefKey.bareArrowAction) private var bareArrowAction: String = "Switch Desktops"

    // Battery Monitor
    @AppStorage(PrefKey.batteryEnabled) private var batteryEnabled: Bool = true
    @AppStorage(PrefKey.batteryStyle) private var batteryStyle: String = "Classic Apple Battery"
    @AppStorage(PrefKey.showBatteryPercentage) private var showBatteryPercentage: Bool = true
    @AppStorage(PrefKey.showChargingBolt) private var showChargingBolt: Bool = false
    @AppStorage(PrefKey.batteryColorMode) private var batteryColorMode: String = "Dynamic Level"

    // Applications Launcher
    @AppStorage(PrefKey.iconSize) private var iconSize: Double = 50.0
    @AppStorage(PrefKey.showAppNames) private var showAppNames: Bool = true
    @AppStorage(PrefKey.spacing) private var itemSpacing: Double = 12.0

    // Desktop & Files
    @AppStorage(PrefKey.desktopPlaneEnabled) private var desktopPlaneEnabled: Bool = true
    @AppStorage(PrefKey.gridTransitionDirection) private var gridTransitionDirection: String = "Slide from Right (iPhone Mode 📱)"
    @ObservedObject private var desktopFilesManager = DesktopFilesManager.shared

    // Sound, Haptics & Smoke
    @AppStorage(PrefKey.soundEnabled) private var soundEnabled: Bool = true
    @AppStorage(PrefKey.hapticsEnabled) private var hapticsEnabled: Bool = true
    @AppStorage(PrefKey.smokeEffectsEnabled) private var smokeEffectsEnabled: Bool = true
    @AppStorage(PrefKey.smokeStyle) private var smokeStyle: String = "Mystical Cyan 🧞‍♂️"

    // Living Atmospheres & Glass
    @AppStorage(PrefKey.aiEmotion) private var selectedEmotionRaw: String = AIEmotionType.mystical.rawValue
    @AppStorage(PrefKey.glassVibrancyIntensity) private var glassVibrancyIntensity: Double = 0.85

    // System Permissions
    @ObservedObject private var loginItemManager = LoginItemManager.shared
    @ObservedObject private var installerManager = UtilityAppInstallerManager.shared
    @ObservedObject private var tricksterEngine = AppScreenSizeTricksterEngine.shared
    @State private var isAccessibilityGranted: Bool = AXIsProcessTrusted()
    @State private var isScreenCaptureGranted: Bool = CGPreflightScreenCaptureAccess()
    @State private var showResetAlert: Bool = false

    public var isEmbedded: Bool = true

    public init(onBackToApps: @escaping () -> Void = {}, onClose: @escaping () -> Void = {}) {
        self.isEmbedded = true
        self.onBackToApps = onBackToApps
        self.onClose = onClose
    }

    public init(initialTab: UnifiedSettingsTab = .miniDock, isEmbedded: Bool = true, onBackToApps: @escaping () -> Void = {}, onClose: @escaping () -> Void = {}) {
        self._selectedTab = State(initialValue: initialTab)
        self.isEmbedded = isEmbedded
        self.onBackToApps = onBackToApps
        self.onClose = onClose
    }

    private var filteredTabs: [UnifiedSettingsTab] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if trimmed.isEmpty {
            return UnifiedSettingsTab.allCases
        }
        return UnifiedSettingsTab.allCases.filter { tab in
            tab.rawValue.lowercased().contains(trimmed) ||
            tab.keywords.contains { $0.contains(trimmed) }
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            // ── Top Sub-Header: Categorized Ribbon + Search Bar ──
            settingsSubHeaderRibbon

            Divider().opacity(0.12)

            // ── Main Body: Collapsible Sidebar + High-Density Content ──
            HStack(spacing: 0) {
                if isSidebarVisible {
                    settingsSidebar
                        .frame(width: 200)
                        .transition(.move(edge: .leading).combined(with: .opacity))

                    Divider().opacity(0.12)
                }

                // Content Area with optimized padding & smooth scrolling
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 16) {
                        switch selectedTab {
                        case .chat:
                            chatSettingsPane
                        case .miniDock:
                            miniDockSettingsPane
                        case .virtualScreen:
                            virtualScreenSettingsPane
                        case .applications:
                            applicationsSettingsPane
                        case .desktop:
                            desktopSettingsPane
                        case .soundAndSmoke:
                            soundAndSmokePane
                        case .models:
                            modelsSettingsPane
                        case .livingGlass:
                            livingGlassSettingsPane
                        case .systemAccess:
                            systemAccessSettingsPane
                        case .huggingface:
                            huggingfaceSettingsPane
                        case .worldClock:
                            GenieWorldClockAlarmPane()
                        case .generalAndPrivacy:
                            generalAndPrivacyPane
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                }
            }
        }
        .overlay(alignment: .top) {
            if let fb = statusFeedback {
                Text(fb)
                    .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(.regularMaterial)
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.20), lineWidth: 0.5))
                    .shadow(color: Color.black.opacity(0.25), radius: 8, y: 3)
                    .transition(.scale.combined(with: .opacity))
                    .padding(.top, 10)
            }
        }
        .alert(isPresented: $showResetAlert) {
            Alert(
                title: Text("Reset Settings to Defaults?"),
                message: Text("This will restore default settings for mini dock, battery, applications, glass, and sound effects."),
                primaryButton: .destructive(Text("Reset")) {
                    resetToDefaults()
                },
                secondaryButton: .cancel()
            )
        }
        .onAppear {
            isAccessibilityGranted = AXIsProcessTrusted()
            isScreenCaptureGranted = CGPreflightScreenCaptureAccess()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusSelectSettingsTab"))) { notif in
            if let tab = notif.object as? UnifiedSettingsTab {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.80)) {
                    selectedTab = tab
                }
            } else if let tabName = notif.object as? String, let tab = UnifiedSettingsTab(rawValue: tabName) {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.80)) {
                    selectedTab = tab
                }
            }
        }
    }

    // MARK: - Top Sub-Header Ribbon & Search Field
    private var settingsSubHeaderRibbon: some View {
        HStack(spacing: 8) {
            // Sidebar Toggle
            Button(action: {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                    isSidebarVisible.toggle()
                }
                HapticFeedback.tick()
            }) {
                Image(systemName: "sidebar.leading")
                    .font(.system(size: 11.5, weight: .medium))
                    .foregroundColor(isSidebarVisible ? .white : .secondary)
                    .padding(5)
                    .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(Color.white.opacity(isSidebarVisible ? 0.12 : 0.04)))
            }
            .buttonStyle(.plain)
            .help("Toggle Sidebar (⌘S)")

            // Glass Switcher Ribbon
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(filteredTabs) { tab in
                        let isActive = (tab == selectedTab)
                        Button(action: {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.80)) {
                                selectedTab = tab
                            }
                            HapticFeedback.selection()
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 9.5, weight: .semibold))
                                    .foregroundColor(isActive ? tab.tintColor : .secondary)

                                Text(tab.rawValue)
                                    .font(.system(size: 10.5, weight: isActive ? .semibold : .regular, design: .default))
                                    .foregroundColor(isActive ? .white : .white.opacity(0.70))
                            }
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4.5)
                            .background(
                                Capsule()
                                    .fill(isActive ? tab.tintColor.opacity(0.20) : Color.white.opacity(0.04))
                            )
                            .overlay(
                                Capsule()
                                    .strokeBorder(isActive ? tab.tintColor.opacity(0.50) : Color.white.opacity(0.08), lineWidth: 0.5)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 4)
            }

            Spacer()

            // Search Field
            HStack(spacing: 5) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                TextField("Search...", text: $searchText)
                    .font(.system(size: 11, design: .default))
                    .textFieldStyle(.plain)
                    .foregroundColor(.white)
                    .frame(width: 90)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 9.5))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color.white.opacity(0.06)))
            .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.5))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(Color.black.opacity(0.15))
    }

    // MARK: - Navigation Sidebar
    private var settingsSidebar: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 2) {
                    ForEach(filteredTabs) { tab in
                        let isSelected = (selectedTab == tab)
                        Button(action: {
                            HapticFeedback.selection()
                            withAnimation(.spring(response: 0.22, dampingFraction: 0.82)) {
                                selectedTab = tab
                            }
                        }) {
                            HStack(spacing: 9) {
                                // Squircle Badge
                                ZStack {
                                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                                        .fill(tab.tintColor.opacity(isSelected ? 0.90 : 0.20))
                                        .frame(width: 22, height: 22)

                                    Image(systemName: tab.icon)
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(isSelected ? .white : tab.tintColor)
                                }

                                Text(tab.rawValue)
                                    .font(.system(size: 11.5, weight: isSelected ? .semibold : .regular, design: .default))
                                    .foregroundColor(isSelected ? .white : .white.opacity(0.80))
                                    .lineLimit(1)

                                Spacer()

                                if isSelected {
                                    Circle()
                                        .fill(tab.tintColor)
                                        .frame(width: 5, height: 5)
                                }
                            }
                            .padding(.horizontal, 8)
                            .frame(height: 32)
                            .background(
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .fill(isSelected ? tab.tintColor.opacity(0.18) : Color.clear)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .strokeBorder(isSelected ? tab.tintColor.opacity(0.35) : Color.clear, lineWidth: 0.5)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 10)
            }

            Spacer()
        }
        .background(VisualEffectBlur(material: .sidebar, blendingMode: .withinWindow, state: .active))
    }

    // MARK: - 0. Genie Chat & Dialogue Pane
    private var chatSettingsPane: some View {
        VStack(spacing: 14) {
            settingsGlassCard(title: "Genie Intelligence & Live Dialogue", icon: "bubble.left.and.bubble.right.fill", tint: .cyan) {
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Active Model")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                            Text(localModels.selectedModelDisplayName)
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.65))
                        }
                        Spacer()
                        Image(systemName: "sparkles")
                            .font(.system(size: 15))
                            .foregroundColor(.cyan)
                    }

                    Divider().opacity(0.12)

                    HStack {
                        Text("Conversation Turns")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                        Text("\(localModels.chatHistory.count) messages")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.65))
                    }

                    Divider().opacity(0.12)

                    HStack(spacing: 10) {
                        Button(action: {
                            localModels.clearChatHistory()
                            HapticFeedback.selection()
                            showBannerFeedback("Chat history cleared 🧹")
                        }) {
                            Text("Clear History")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.85))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Capsule().fill(Color.white.opacity(0.10)))
                                .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 0.5))
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            localModels.clearChatHistory()
                            HapticFeedback.selection()
                            showBannerFeedback("Started fresh session ✨")
                        }) {
                            Text("New Session")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(.black)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Capsule().fill(Color.cyan))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            settingsGlassCard(title: "Interactive Dialogue Stream", icon: "sparkles", tint: .purple) {
                CompactChatStreamView(emotion: .mystical, showHeader: false)
                    .frame(height: 280)
            }
        }
    }

    // MARK: - 1. Mini Dock & Bar Pane
    private var miniDockSettingsPane: some View {
        VStack(spacing: 14) {
            settingsGlassCard(title: "Mini Dock Styling & Position", icon: "menubar.rectangle", tint: .blue) {
                VStack(spacing: 10) {
                    HStack {
                        Text("Mini Dock Background Theme")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                        Picker("", selection: $miniDockBackgroundStyle) {
                            Text("Apple Liquid Glass").tag("Apple Liquid Glass")
                            Text("Cosmic Aurora").tag("Cosmic Aurora")
                            Text("Dark Obsidian Glass").tag("Dark Obsidian Glass")
                            Text("Liquid Gold & Champagne").tag("Liquid Gold & Champagne")
                            Text("Emerald Rainforest").tag("Emerald Rainforest")
                            Text("Amethyst Nebula").tag("Amethyst Nebula")
                            Text("Sunset Mirage").tag("Sunset Mirage")
                            Text("Diamond Ice").tag("Diamond Ice")
                            Text("Clear (Transparent)").tag("Clear (Transparent)")
                        }
                        .pickerStyle(.menu)
                        .frame(width: 190)
                        .onChange(of: miniDockBackgroundStyle) { _, newStyle in
                            HapticFeedback.selection()
                            NotificationCenter.default.post(name: NSNotification.Name("NexusMiniDockStyleChanged"), object: newStyle)
                            AppDelegate.shared?.renderIcon()
                        }
                    }

                    // Interactive Theme Gradient Swatch Pills
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            let themes: [(name: String, icon: String, colors: [Color])] = [
                                ("Apple Liquid Glass", "sparkles", [Color.white.opacity(0.35), Color.white.opacity(0.10)]),
                                ("Cosmic Aurora", "wand.and.stars", [Color.cyan, Color.purple, Color.pink]),
                                ("Dark Obsidian Glass", "moon.fill", [Color(white: 0.25), Color.black]),
                                ("Liquid Gold & Champagne", "crown.fill", [Color(red: 1.0, green: 0.85, blue: 0.3), Color(red: 0.85, green: 0.65, blue: 0.15)]),
                                ("Emerald Rainforest", "leaf.fill", [Color(red: 0.1, green: 0.9, blue: 0.5), Color(red: 0.0, green: 0.5, blue: 0.3)]),
                                ("Amethyst Nebula", "suit.diamond.fill", [Color(red: 0.8, green: 0.4, blue: 1.0), Color(red: 0.4, green: 0.1, blue: 0.8)]),
                                ("Sunset Mirage", "sun.max.fill", [Color(red: 1.0, green: 0.5, blue: 0.3), Color(red: 0.9, green: 0.2, blue: 0.5)]),
                                ("Diamond Ice", "drop.fill", [Color.white, Color.cyan.opacity(0.5)]),
                                ("Clear (Transparent)", "circle.dashed", [Color.white.opacity(0.15), Color.clear])
                            ]

                            ForEach(themes, id: \.name) { th in
                                let isSel = (miniDockBackgroundStyle == th.name)
                                Button(action: {
                                    HapticFeedback.selection()
                                    miniDockBackgroundStyle = th.name
                                    NotificationCenter.default.post(name: NSNotification.Name("NexusMiniDockStyleChanged"), object: th.name)
                                    AppDelegate.shared?.renderIcon()
                                }) {
                                    HStack(spacing: 5) {
                                        Circle()
                                            .fill(LinearGradient(colors: th.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                                            .frame(width: 12, height: 12)
                                            .overlay(Circle().stroke(Color.white.opacity(0.4), lineWidth: 0.5))

                                        Text(th.name)
                                            .font(.system(size: 10, weight: isSel ? .bold : .medium, design: .rounded))
                                            .foregroundColor(isSel ? .white : .white.opacity(0.70))
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4.5)
                                    .background(
                                        Capsule()
                                            .fill(isSel ? Color.white.opacity(0.20) : Color.white.opacity(0.06))
                                            .overlay(Capsule().stroke(isSel ? Color.white.opacity(0.60) : Color.white.opacity(0.12), lineWidth: 0.8))
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 2)
                    }

                    Divider().opacity(0.20)

                    HStack {
                        Text("Display Mode")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                        Picker("", selection: $miniDockDisplayMode) {
                            Text("Always On").tag("Always Shown")
                            Text("Auto Pop Down").tag("Always Hidden")
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 200)
                    }

                    Divider().opacity(0.20)

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Slide into Battery (Save Space 🔋)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Text("When ON, smoothly collapses the mini dock app switcher into the battery icon capsule. Hovering or clicking unfolds the dock smoothly.")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.60))
                        }
                        Spacer()
                        Toggle("", isOn: $isCollapsedIntoBattery)
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .controlSize(.small)
                            .onChange(of: isCollapsedIntoBattery) { _, newVal in
                                HapticFeedback.selection()
                                UserDefaults.standard.set(newVal, forKey: PrefKey.isCollapsedIntoBattery)
                                NotificationCenter.default.post(name: NSNotification.Name("NexusToggleDockCollapse"), object: nil)
                            }
                    }

                    Divider().opacity(0.20)

                    HStack {
                        Text("Running App Slots in Dock")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                        Stepper("\(menuBarAppCount) apps", value: $menuBarAppCount, in: 1...6)
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    }
                }
            }

            // Real macOS Dock Elements & Application Filter Card
            settingsGlassCard(title: "Real macOS Dock Items & Visibility", icon: "dock.rectangle", tint: .indigo) {
                VStack(spacing: 11) {
                    // 1. Active vs Inactive Applications Toggle
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Active Applications Only")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Text("When OFF, shows all pinned and inactive dock apps like the macOS Dock. When ON, shows only currently running apps.")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.60))
                        }
                        Spacer()
                        Toggle("", isOn: $dockActiveAppsOnly)
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .controlSize(.small)
                            .onChange(of: dockActiveAppsOnly) { _, newVal in
                                HapticFeedback.selection()
                                UserDefaults.standard.set(newVal, forKey: PrefKey.dockActiveAppsOnly)
                                NotificationCenter.default.post(name: NSNotification.Name("NexusDockActiveAppsOnlyChanged"), object: newVal)
                                DockAndDesktopManager.shared.refreshDockApps()
                            }
                    }

                    Divider().opacity(0.20)

                    // 2. Real macOS Live Trash Can
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(.red.opacity(0.85))
                                Text("Real macOS Trash Can")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            Text("Display the authentic Trash Can with empty/full status, click to open, and right-click to empty.")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.60))
                        }
                        Spacer()
                        Toggle("", isOn: $dockAlwaysShowTrash)
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .controlSize(.small)
                            .onChange(of: dockAlwaysShowTrash) { _, newVal in
                                HapticFeedback.selection()
                                UserDefaults.standard.set(newVal, forKey: PrefKey.dockAlwaysShowTrash)
                                NotificationCenter.default.post(name: NSNotification.Name("NexusDockTrashChanged"), object: newVal)
                                DockAndDesktopManager.shared.refreshDockApps()
                            }
                    }

                    Divider().opacity(0.20)

                    // 3. Pinned Folder Stacks (Downloads, Documents, Applications)
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Image(systemName: "folder.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color.cyan)
                                Text("Folder Stacks (Downloads & Documents)")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            Text("Display pinned folder stacks from your macOS Dock with quick Finder access.")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.60))
                        }
                        Spacer()
                        Toggle("", isOn: $dockShowFolderStacks)
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .controlSize(.small)
                            .onChange(of: dockShowFolderStacks) { _, newVal in
                                HapticFeedback.selection()
                                UserDefaults.standard.set(newVal, forKey: PrefKey.dockShowFolderStacks)
                                NotificationCenter.default.post(name: NSNotification.Name("NexusDockShowFolderStacksChanged"), object: newVal)
                                DockAndDesktopManager.shared.refreshDockApps()
                            }
                    }

                    Divider().opacity(0.20)

                    // 4. Finder Anchor
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Always Show Finder")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Text("Keep Finder pinned in the dock strip.")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.60))
                        }
                        Spacer()
                        Toggle("", isOn: $dockAlwaysShowFinder)
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .controlSize(.small)
                            .onChange(of: dockAlwaysShowFinder) { _, newVal in
                                HapticFeedback.selection()
                                UserDefaults.standard.set(newVal, forKey: PrefKey.dockAlwaysShowFinder)
                                NotificationCenter.default.post(name: NSNotification.Name("NexusDockAlwaysShowFinderChanged"), object: newVal)
                                DockAndDesktopManager.shared.refreshDockApps()
                            }
                    }

                    Divider().opacity(0.20)

                    // 5. System Settings Anchor
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Always Show System Settings")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Text("Include System Settings in the dock.")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.60))
                        }
                        Spacer()
                        Toggle("", isOn: $dockAlwaysShowSettings)
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .controlSize(.small)
                            .onChange(of: dockAlwaysShowSettings) { _, newVal in
                                HapticFeedback.selection()
                                UserDefaults.standard.set(newVal, forKey: PrefKey.dockAlwaysShowSettings)
                                NotificationCenter.default.post(name: NSNotification.Name("NexusDockAlwaysShowSettingsChanged"), object: newVal)
                                DockAndDesktopManager.shared.refreshDockApps()
                            }
                    }
                }
            }

            settingsGlassCard(title: "Unified Command Window", icon: "macwindow.on.rectangle", tint: .cyan) {
                VStack(spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Strip + Chat in One Draggable Window")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Text("The dock strip becomes the title bar of the Genie chat window. Drag it anywhere; the position is remembered.")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.55))
                        }
                        Spacer()
                        Toggle("", isOn: $unifiedCommandWindowEnabled)
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .onChange(of: unifiedCommandWindowEnabled) { _, on in
                                if !on { UnifiedCommandWindowManager.shared.hide() }
                            }
                    }
                    if unifiedCommandWindowEnabled {
                        Divider().opacity(0.20)
                        HStack {
                            Text("Open the Command Window now")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Spacer()
                            Button(UnifiedCommandWindowManager.shared.isVisible ? "Hide" : "Show") {
                                HapticFeedback.selection()
                                UnifiedCommandWindowManager.shared.toggle()
                            }
                            .buttonStyle(.bordered)
                            .tint(.cyan)
                        }
                    }
                }
            }

            settingsGlassCard(title: "Status Icon & Battery Monitor", icon: "battery.100.bolt", tint: .green) {
                VStack(spacing: 10) {
                    HStack {
                        Text("Menu Bar Status Glyph")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                        Picker("", selection: $statusIconGlyph) {
                            Text("Simple Lamp ◐").tag("Simple Lamp ◐")
                            Text("Simple Spark ✳︎").tag("Simple Spark ✳︎")
                            Divider()
                            Text("Genie Person 🧞‍♂️").tag("Genie Person 🧞‍♂️")
                            Text("Genie Lamp 🪔").tag("Genie Lamp 🪔")
                            Text("Apple Modern ").tag("Apple Modern ")
                            Text("Leo Maltese 🐶").tag("Leo Maltese 🐶")
                            Text("Minimal Dot ⚪").tag("Minimal Dot ⚪")
                            Text("Star Sparkle ✨").tag("Star Sparkle ✨")
                            Text("Diamond Facet 💎").tag("Diamond Facet 💎")
                        }
                        .pickerStyle(.menu)
                        .frame(width: 175)
                        .onChange(of: statusIconGlyph) { _, newGlyph in
                            HapticFeedback.selection()
                            statusIconStyle = newGlyph
                            UserDefaults.standard.set(newGlyph, forKey: PrefKey.statusIconStyle)
                            AppDelegate.shared?.renderIcon()
                        }
                    }

                    Divider().opacity(0.20)

                    HStack {
                        Text("Battery Gauge & Voltage")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                        Toggle("", isOn: $batteryEnabled)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }

                    if batteryEnabled {
                        Divider().opacity(0.20)

                        HStack {
                            Text("Battery Rendering Style")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Spacer()
                            Picker("", selection: $batteryStyle) {
                                Text("Classic Apple").tag("Classic Apple Battery")
                                Text("VisionOS Pill").tag("VisionOS Pill")
                                Text("Apple Minimal").tag("Apple Minimal")
                                Text("Digital Clock 7-Segment").tag("Digital Clock 7-Segment")
                                Text("Text Only (% Only)").tag("Text Only (% Only)")
                            }
                            .pickerStyle(.menu)
                            .frame(width: 175)
                            .onChange(of: batteryStyle) { _, newStyle in
                                HapticFeedback.selection()
                                UserDefaults.standard.set(newStyle, forKey: PrefKey.iconStyle)
                                NotificationCenter.default.post(name: NSNotification.Name("NexusIconStyleChanged"), object: newStyle)
                                AppDelegate.shared?.renderIcon()
                            }
                        }

                        Divider().opacity(0.20)

                        HStack {
                            Text("Show Battery Percentage (%)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Spacer()
                            Toggle("", isOn: $showBatteryPercentage)
                                .labelsHidden()
                                .toggleStyle(.switch)
                        }

                        Divider().opacity(0.20)

                        HStack {
                            Text("Percentage Color Palette")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Spacer()
                            Picker("", selection: $batteryColorMode) {
                                Text("Dynamic Level").tag("Dynamic Level")
                                Text("Neon Cyan").tag("Neon Cyan")
                                Text("Pure White").tag("Pure White")
                                Text("Emerald Green").tag("Emerald Green")
                                Text("Solar Orange").tag("Solar Orange")
                            }
                            .pickerStyle(.menu)
                            .frame(width: 175)
                        }
                    }
                }
            }
        }
    }

    // MARK: - 📱 Pioneered Virtual Screen Display & Matrix Pane
    private var virtualScreenSettingsPane: some View {
        VStack(spacing: 14) {
            // Hero Pioneer Card
            settingsGlassCard(title: "Pioneered Screen Size Trickster", icon: "sparkles.rectangle.stack", tint: .green) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "lightbulb.max.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.green)

                        Text("Pioneered Virtual Resolution Architecture")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }

                    Text("Instead of shrinking your entire desktop, Genie tricks programs on launch into compact mobile & matrix resolutions (e.g. iPhone size, iPad size, 3×3 slot matrix, or 720p). Up to 9 full applications run side-by-side natively on your high-resolution desktop without scaling distortion.")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.white.opacity(0.75))
                        .lineSpacing(2.5)

                    Divider().opacity(0.15)

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Auto-Trick Apps On Launch")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Text("Intercept new application launches and clamp them to compact size.")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.55))
                        }
                        Spacer()
                        Toggle("", isOn: $tricksterEngine.isTricksterEnabled)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }
                }
            }

            // Live Resizer & Active Window Clamper
            settingsGlassCard(title: "Live Active Window Resizer", icon: "arrow.down.right.and.arrow.up.left", tint: .cyan) {
                VStack(spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Current Default Preset: \(tricksterEngine.defaultProfile.rawValue)")
                                .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                                .foregroundColor(.cyan)
                            Text("Applies immediate window clamping to whichever app is frontmost.")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.55))
                        }
                        Spacer()

                        Button(action: {
                            let didClamp = tricksterEngine.clampFrontmostApplication(to: tricksterEngine.defaultProfile)
                            if didClamp {
                                statusFeedback = "⚡ Resized \(tricksterEngine.lastTrickedApp ?? "App") to \(tricksterEngine.defaultProfile.rawValue)"
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { statusFeedback = nil }
                            }
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: "bolt.fill")
                                Text("Resize Front App Now")
                            }
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.cyan)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Virtual Screen Profiles Selector Grid
            settingsGlassCard(title: "Choose Virtual Screen Profile", icon: "display.2", tint: .green) {
                VStack(alignment: .leading, spacing: 10) {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(VirtualScreenProfile.allCases) { profile in
                            let isSelected = (tricksterEngine.defaultProfile == profile)
                            Button(action: {
                                HapticFeedback.selection()
                                tricksterEngine.defaultProfile = profile
                                tricksterEngine.clampFrontmostApplication(to: profile)
                            }) {
                                VStack(alignment: .leading, spacing: 5) {
                                    HStack {
                                        Image(systemName: profile.icon)
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(isSelected ? .green : .white.opacity(0.70))
                                        Spacer()
                                        if isSelected {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 12))
                                                .foregroundColor(.green)
                                        }
                                    }

                                    Text(profile.rawValue)
                                        .font(.system(size: 10.5, weight: isSelected ? .bold : .medium, design: .rounded))
                                        .foregroundColor(.white)
                                        .lineLimit(1)

                                    Text(profile.category)
                                        .font(.system(size: 9, weight: .regular))
                                        .foregroundColor(isSelected ? .green.opacity(0.85) : .white.opacity(0.40))
                                }
                                .padding(10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(isSelected ? Color.green.opacity(0.20) : Color.white.opacity(0.06))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .stroke(isSelected ? Color.green.opacity(0.70) : Color.white.opacity(0.10), lineWidth: 0.8)
                                        )
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            // 1-Click Test Launch Bar
            settingsGlassCard(title: "1-Click Launch At Selected Size", icon: "play.circle.fill", tint: .orange) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Launch common apps with instant compact geometry clamping:")
                        .font(.system(size: 10.5))
                        .foregroundColor(.white.opacity(0.60))

                    HStack(spacing: 8) {
                        ForEach(["Safari", "Notes", "Xcode", "Simulator", "Terminal"], id: \.self) { appName in
                            Button(action: {
                                HapticFeedback.selection()
                                Task {
                                    await tricksterEngine.launchWithSpoofedScreenSize(
                                        appName: appName,
                                        profile: tricksterEngine.defaultProfile,
                                        slotIndex: tricksterEngine.findNextAvailableSlot()
                                    )
                                }
                            }) {
                                Text("🚀 \(appName)")
                                    .font(.system(size: 10.5, weight: .medium, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(
                                        Capsule()
                                            .fill(Color.orange.opacity(0.25))
                                            .overlay(Capsule().stroke(Color.orange.opacity(0.50), lineWidth: 0.7))
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    // MARK: - 2. Applications Launcher Pane
    private var applicationsSettingsPane: some View {
        VStack(spacing: 14) {
            settingsGlassCard(title: "Applications Canvas & Visibility", icon: "macwindow.on.rectangle", tint: .indigo) {
                VStack(spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Desktop Grid Canvas (⌘⌥Space)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Text("Interactive full-screen 2-page application canvas on desktop.")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.55))
                        }
                        Spacer()
                        Toggle("", isOn: $desktopPlaneEnabled)
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .onChange(of: desktopPlaneEnabled) { _, _ in
                                NotificationCenter.default.post(name: .init("NexusDesktopPlaneToggled"), object: nil)
                                NotificationCenter.default.post(name: .init("NexusToggleDesktopGrid"), object: nil)
                            }
                    }

                    Divider().opacity(0.20)

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Slide-in Animation Direction")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Text("Direction the applications canvas animates onto screen.")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.55))
                        }
                        Spacer()
                        Picker("", selection: $gridTransitionDirection) {
                            Text("➡️ Slide from Right").tag("Slide from Right (iPhone Mode 📱)")
                            Text("⬅️ Slide from Left").tag("Slide from Left (Sidebar ⬅️)")
                            Text("⬇️ Drop Down from Top").tag("Drop Down from Top (Menu Bar ⬇️)")
                            Text("⬆️ Pull Up from Bottom").tag("Pull Up from Bottom")
                            Text("✨ Spatial Center Zoom").tag("Spatial Zoom from Center (Holographic ✨)")
                        }
                        .pickerStyle(.menu)
                        .frame(width: 180)
                    }

                    Divider().opacity(0.20)

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Running Apps in Mini Dock")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Text("Display active app switcher icons directly in the menu bar.")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.55))
                        }
                        Spacer()
                        Toggle("", isOn: $menuBarAppSwitcherEnabled)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }
                }
            }

            settingsGlassCard(title: "App Grid Dimensions & Layout", icon: "square.grid.2x2", tint: .indigo) {
                VStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Icon Scale Size")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Spacer()
                            Text("\(Int(iconSize)) pt")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(.indigo)
                        }

                        HStack(spacing: 6) {
                            ForEach([
                                (label: "Compact (44)", size: 44.0),
                                (label: "Standard (50)", size: 50.0),
                                (label: "Large (60)", size: 60.0)
                            ], id: \.label) { preset in
                                Button(action: {
                                    withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
                                        iconSize = preset.size
                                    }
                                }) {
                                    Text(preset.label)
                                        .font(.system(size: 10.5, weight: iconSize == preset.size ? .bold : .medium))
                                        .foregroundColor(iconSize == preset.size ? .white : .white.opacity(0.70))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 5)
                                        .background(
                                            Capsule()
                                                .fill(iconSize == preset.size ? Color.indigo.opacity(0.50) : Color.white.opacity(0.06))
                                        )
                                        .overlay(
                                            Capsule()
                                                .strokeBorder(iconSize == preset.size ? Color.indigo : Color.white.opacity(0.12), lineWidth: 0.6)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Divider().opacity(0.20)

                    HStack {
                        Text("Show App Names Below Icons")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                        Toggle("", isOn: $showAppNames)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }

                    Divider().opacity(0.20)

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Custom Grid Arrangement")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Text("Drag and drop icons directly in the dropdown to customize order.")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.55))
                        }
                        Spacer()
                        Button("Reset Order") {
                            HapticFeedback.selection()
                            UserDefaults.standard.removeObject(forKey: PrefKey.customAppOrder)
                            UserDefaults.standard.removeObject(forKey: PrefKey.customDockAppOrder)
                            NotificationCenter.default.post(name: NSNotification.Name("NexusResetAppOrder"), object: nil)
                            NotificationCenter.default.post(name: NSNotification.Name("NexusRefreshApps"), object: nil)
                            showBannerFeedback("App grid arrangement reset! 🧹")
                        }
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.orange.opacity(0.16)))
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - 3. Desktop & Files Pane
    private var desktopSettingsPane: some View {
        VStack(spacing: 14) {
            settingsGlassCard(title: "Desktop Clean State & Icons", icon: "folder.fill", tint: .teal) {
                VStack(spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Keep Files on Desktop")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Text(desktopFilesManager.areDesktopFilesVisible
                                ? "Files and folders stay visible on your wallpaper."
                                : "Files are hidden for an ultra-clean, distraction-free desktop.")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.55))
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
                    }
                }
            }

            settingsGlassCard(title: "Desktop Application Matrix", icon: "macwindow.on.rectangle", tint: .teal) {
                VStack(spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Desktop Grid Plane Overlay")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Text("Applications stay accessible behind active windows on your wallpaper.")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.55))
                        }
                        Spacer()
                        Toggle("", isOn: $desktopPlaneEnabled)
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .onChange(of: desktopPlaneEnabled) { _, isEnabled in
                                HapticFeedback.selection()
                                NotificationCenter.default.post(name: .init("NexusDesktopPlaneToggled"), object: isEnabled)
                            }
                    }
                }
            }
        }
    }

    // MARK: - 4. Sound & Effects Pane
    private var soundAndSmokePane: some View {
        VStack(spacing: 14) {
            settingsGlassCard(title: "Audio & Haptic Feedback", icon: "speaker.wave.2", tint: .orange) {
                VStack(spacing: 10) {
                    HStack {
                        Text("Spatial Sound Effects")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                        Toggle("", isOn: $soundEnabled)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }

                    Divider().opacity(0.20)

                    HStack {
                        Text("Trackpad Haptic Feedback")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                        Toggle("", isOn: $hapticsEnabled)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }
                }
            }

            settingsGlassCard(title: "Genie Particle & Smoke Plumes", icon: "smoke.fill", tint: .orange) {
                VStack(spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Mystical Smoke Bursts")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Text("Ethereal GPU bursts when the dropdown or chat appears.")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.55))
                        }
                        Spacer()
                        Toggle("", isOn: $smokeEffectsEnabled)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }

                    if smokeEffectsEnabled {
                        Divider().opacity(0.20)

                        HStack {
                            Text("Smoke Palette Style")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Spacer()
                            Picker("", selection: $smokeStyle) {
                                Text("Mystical Cyan 🧞‍♂️").tag("Mystical Cyan 🧞‍♂️")
                                Text("Golden Ember 🌟").tag("Golden Ember 🌟")
                                Text("Purple Haze 🔮").tag("Purple Haze 🔮")
                                Text("Pure White ⚪").tag("Pure White ⚪")
                            }
                            .pickerStyle(.menu)
                            .frame(width: 175)
                        }
                    }
                }
            }
        }
    }

    // MARK: - 5. AI Models & Engines Pane
    private var modelsSettingsPane: some View {
        VStack(spacing: 14) {
            settingsGlassCard(title: "Apple Silicon Metal Acceleration & RAM", icon: "cpu", tint: Color(red: 0.85, green: 0.47, blue: 0.36)) {
                VStack(spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Unified Memory Architecture")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                            Text("Detected: 48 GB Unified Memory • PyTorch Metal (MPS) Ready")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.green.opacity(0.90))
                        }
                        Spacer()
                        Text("48 GB RAM")
                            .font(.system(size: 10, weight: .heavy, design: .monospaced))
                            .foregroundColor(.black)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.green))
                    }

                    Divider().opacity(0.20)

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Auto-Select Best Available Engine")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Text("Automatically route prompts to local 12B/32B models when offline.")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.55))
                        }
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { localModels.autoSelectEnabled },
                            set: { if $0 { localModels.enableAutoSelect() } else { localModels.autoSelectEnabled = false } }
                        ))
                        .labelsHidden()
                        .toggleStyle(.switch)
                    }

                    Divider().opacity(0.20)

                    HStack {
                        Text("Current Default Model")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                        Text(localModels.selectedModelDisplayName)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.cyan)
                    }
                }
            }

            settingsGlassCard(title: "Available AI Engines & Providers", icon: "sparkles", tint: Color(red: 0.85, green: 0.47, blue: 0.36)) {
                VStack(spacing: 14) {
                    ForEach(AIModelProvider.allCases) { provider in
                        let models = LocalModelManager.cloudModels.filter { $0.provider == provider }
                        if !models.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 6) {
                                    Image(systemName: provider.icon)
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(provider.badgeColor)
                                    Text(provider.rawValue)
                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                        .foregroundColor(provider.badgeColor)
                                    Spacer()
                                }
                                .padding(.top, 4)

                                VStack(spacing: 6) {
                                    ForEach(models) { model in
                                        HStack(spacing: 8) {
                                            VStack(alignment: .leading, spacing: 1) {
                                                Text(model.displayName)
                                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                                    .foregroundColor(.white)
                                                Text(model.description.isEmpty ? model.id : model.description)
                                                    .font(.system(size: 9.5))
                                                    .foregroundColor(.white.opacity(0.50))
                                                    .lineLimit(1)
                                            }

                                            Spacer()

                                            if localModels.effectiveModel == model.id {
                                                Text("Active ✓")
                                                    .font(.system(size: 9.5, weight: .bold))
                                                    .foregroundColor(.green)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(Capsule().fill(Color.green.opacity(0.18)))
                                            } else {
                                                Button("Select") {
                                                    localModels.selectModel(model.id)
                                                    HapticFeedback.selection()
                                                    showBannerFeedback("Selected \(model.displayName) ✨")
                                                }
                                                .font(.system(size: 9.5, weight: .semibold))
                                                .foregroundColor(.white.opacity(0.85))
                                                .padding(.horizontal, 8)
                                                .padding(.vertical, 3)
                                                .background(Capsule().fill(Color.white.opacity(0.10)))
                                                .buttonStyle(.plain)
                                            }
                                        }
                                        .padding(.vertical, 3)

                                        if model.id != models.last?.id {
                                            Divider().opacity(0.12)
                                        }
                                    }
                                }
                                .padding(8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(Color.white.opacity(0.04))
                                )
                            }
                        }
                    }

                    if localModels.localModelsEnabled && !localModels.availableModels.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                Image(systemName: "desktopcomputer")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.cyan)
                                Text("Ollama / LM Studio (Discovered Local Models)")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(.cyan)
                                Spacer()
                            }
                            .padding(.top, 4)

                            VStack(spacing: 6) {
                                ForEach(localModels.availableModels) { model in
                                    HStack(spacing: 8) {
                                        VStack(alignment: .leading, spacing: 1) {
                                            Text(model.displayName)
                                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                                .foregroundColor(.white)
                                            Text("\(model.source) • \(model.displaySize)")
                                                .font(.system(size: 9.5))
                                                .foregroundColor(.white.opacity(0.50))
                                        }

                                        Spacer()

                                        if localModels.effectiveModel == model.name {
                                            Text("Active ✓")
                                                .font(.system(size: 9.5, weight: .bold))
                                                .foregroundColor(.green)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Capsule().fill(Color.green.opacity(0.18)))
                                        } else {
                                            Button("Select") {
                                                localModels.selectModel(model.name)
                                                HapticFeedback.selection()
                                                showBannerFeedback("Selected \(model.displayName) ✨")
                                            }
                                            .font(.system(size: 9.5, weight: .semibold))
                                            .foregroundColor(.white.opacity(0.85))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(Capsule().fill(Color.white.opacity(0.10)))
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.vertical, 3)

                                    if model.name != localModels.availableModels.last?.name {
                                        Divider().opacity(0.12)
                                    }
                                }
                            }
                            .padding(8)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color.white.opacity(0.04))
                            )
                        }
                    }
                }
            }
        }
    }

    // MARK: - 6. Living Glass & Atmospheres Pane
    private var livingGlassSettingsPane: some View {
        VStack(spacing: 14) {
            settingsGlassCard(title: "Living Glass UI & Vibrancy", icon: "sparkles", tint: .cyan) {
                VStack(spacing: 10) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Glass Blur Specular Intensity")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Spacer()
                            Text("\(Int(glassVibrancyIntensity * 100))%")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(.cyan)
                        }

                        Slider(value: $glassVibrancyIntensity, in: 0.3...1.0)
                            .accentColor(.cyan)
                    }

                    Divider().opacity(0.20)

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("ProMotion 120 FPS Native Metal Rendering")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Text("Zero frame hitches with synchronous display link synchronization.")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.55))
                        }
                        Spacer()
                        Text("120 Hz Active")
                            .font(.system(size: 9.5, weight: .heavy, design: .monospaced))
                            .foregroundColor(.cyan)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2.5)
                            .background(Capsule().fill(Color.cyan.opacity(0.16)))
                    }
                }
            }

            settingsGlassCard(title: "Living Atmosphere Themes", icon: "paintpalette.fill", tint: .cyan) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 10)], spacing: 10) {
                    ForEach(AIEmotionType.allCases) { em in
                        let isSelected = (selectedEmotionRaw == em.rawValue)
                        Button(action: {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                selectedEmotionRaw = em.rawValue
                            }
                            HapticFeedback.selection()
                        }) {
                            VStack(spacing: 6) {
                                ZStack {
                                    Circle()
                                        .fill(em.accentColor.opacity(isSelected ? 0.90 : 0.25))
                                        .frame(width: 28, height: 28)
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundColor(isSelected ? .white : em.accentColor)
                                }

                                Text(em.rawValue)
                                    .font(.system(size: 10.5, weight: isSelected ? .bold : .medium, design: .rounded))
                                    .foregroundColor(isSelected ? .white : .white.opacity(0.80))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(isSelected ? em.accentColor.opacity(0.22) : Color.white.opacity(0.04))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .strokeBorder(isSelected ? em.accentColor.opacity(0.60) : Color.white.opacity(0.08), lineWidth: 0.75)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - 7. Full Computer Access & Shortcuts Pane
    private var systemAccessSettingsPane: some View {
        VStack(spacing: 14) {
            settingsGlassCard(title: "Arrow Keys ← →", icon: "arrow.left.arrow.right", tint: .green) {
                VStack(spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Plain ← / → when you are not typing")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Text("Reserved for the cursor inside any text field. Everywhere else the bare arrows switch desktops (or apps).")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.55))
                        }
                        Spacer()
                        Picker("", selection: $bareArrowAction) {
                            Text("Switch Desktops").tag("Switch Desktops")
                            Text("Switch Apps").tag("Switch Apps")
                            Text("Off").tag("Off")
                        }
                        .pickerStyle(.menu)
                        .frame(width: 150)
                    }
                    if !AXIsProcessTrusted() {
                        Divider().opacity(0.20)
                        Text("Grant Accessibility access so Genie can keep the arrow from also reaching the front app.")
                            .font(.system(size: 10))
                            .foregroundColor(.orange.opacity(0.9))
                    }
                }
            }

            settingsGlassCard(title: "Deep Apple System Access", icon: "bolt.shield.fill", tint: .green) {
                VStack(spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Accessibility Trust (AXUIElement)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                            Text("Zero-cursor instant coordinate clicking & UI element inspection.")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.55))
                        }
                        Spacer()
                        if isAccessibilityGranted {
                            Text("Granted ✓")
                                .font(.system(size: 10, weight: .heavy))
                                .foregroundColor(.black)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color.green))
                        } else {
                            Button("Grant Access") {
                                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                                    NSWorkspace.shared.open(url)
                                }
                            }
                            .font(.system(size: 10.5, weight: .bold))
                            .foregroundColor(.orange)
                        }
                    }

                    Divider().opacity(0.20)

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Screen Capture Kit Permissions")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                            Text("Required for OCR, spatial visual grounding, and window mirroring.")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.55))
                        }
                        Spacer()
                        if isScreenCaptureGranted {
                            Text("Granted ✓")
                                .font(.system(size: 10, weight: .heavy))
                                .foregroundColor(.black)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color.green))
                        } else {
                            Button("Grant Access") {
                                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                                    NSWorkspace.shared.open(url)
                                }
                            }
                            .font(.system(size: 10.5, weight: .bold))
                            .foregroundColor(.orange)
                        }
                    }
                }
            }

            settingsGlassCard(title: "Hardware Keyboard Chords & Shortcuts", icon: "keyboard.fill", tint: .green) {
                VStack(spacing: 8) {
                    ForEach([
                        (title: "Toggle Floating Chat & Creations Window", key: "⌥Space / ⌘Space"),
                        (title: "Toggle Desktop Grid Overlay Canvas", key: "⌘⌥Space"),
                        (title: "Instant Zero-Cursor Web Search", key: "⌘K"),
                        (title: "Quick Save Conversation Note", key: "⌘N"),
                        (title: "Toggle Sidebar in Chat Window", key: "⌘S"),
                        (title: "Close Window / Dismiss", key: "Esc / ⌘W")
                    ], id: \.title) { sc in
                        HStack {
                            Text(sc.title)
                                .font(.system(size: 11.5, weight: .medium))
                                .foregroundColor(.white.opacity(0.85))
                            Spacer()
                            Text(sc.key)
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.cyan)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2.5)
                                .background(Capsule().fill(Color.white.opacity(0.08)))
                                .overlay(Capsule().stroke(Color.cyan.opacity(0.35), lineWidth: 0.5))
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
    }

    // MARK: - 8. Hugging Face Hub Pane
    private var huggingfaceSettingsPane: some View {
        VStack(spacing: 14) {
            settingsGlassCard(title: "Hugging Face Engine & GGUF Models", icon: "cube.fill", tint: .yellow) {
                VStack(spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("1-Click GGUF Local Downloader")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                            Text("Optimized for 48 GB Unified Memory with PyTorch MPS Metal backend.")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.55))
                        }
                        Spacer()
                        Text("Hub Ready")
                            .font(.system(size: 9.5, weight: .heavy, design: .monospaced))
                            .foregroundColor(.black)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.yellow))
                    }

                    Divider().opacity(0.20)

                    HStack {
                        Text("Hugging Face Hub Cache Directory")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                        Text("~/.cache/huggingface/hub")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(.yellow.opacity(0.90))
                    }

                    Divider().opacity(0.20)

                    HStack {
                        Text("Headless Gradio Spaces Execution")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                        Text("Supported (/call/predict)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(.green)
                    }
                }
            }
        }
    }

    // MARK: - 9. General & Privacy Pane
    private var generalAndPrivacyPane: some View {
        VStack(spacing: 14) {
            settingsGlassCard(title: "macOS System Utility & Dock", icon: "wrench.and.screwdriver.fill", tint: .purple) {
                VStack(spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Keep Genie Pinned to Apple Dock")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Text("Fast 1-click access from your primary macOS Dock.")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.55))
                        }
                        Spacer()
                        Button(action: {
                            installerManager.toggleDockPinning()
                            HapticFeedback.selection()
                        }) {
                            Text(installerManager.isPinnedToDock ? "Pinned in Dock ✓" : "Add to Dock +")
                                .font(.system(size: 10.5, weight: .bold, design: .rounded))
                                .foregroundColor(installerManager.isPinnedToDock ? .green : .white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(installerManager.isPinnedToDock ? Color.green.opacity(0.18) : Color.white.opacity(0.12)))
                                .overlay(Capsule().stroke(installerManager.isPinnedToDock ? Color.green.opacity(0.40) : Color.white.opacity(0.20), lineWidth: 0.5))
                        }
                        .buttonStyle(.plain)
                    }

                    Divider().opacity(0.20)

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Utility Location")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Text(installerManager.isInstalledInUtilities ? "Installed in /Applications/Utilities" : (installerManager.isInstalledInApplications ? "Installed in /Applications" : "Running from Local Path"))
                                .font(.system(size: 10, weight: .medium, design: .monospaced))
                                .foregroundColor(.purple.opacity(0.85))
                        }
                        Spacer()
                        if !installerManager.isInstalledInUtilities {
                            Button(action: {
                                installerManager.moveToUtilitiesFolder()
                            }) {
                                Text("Move to Utilities 📂")
                                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(Color.white.opacity(0.10)))
                                    .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 0.5))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            settingsGlassCard(title: "Startup & Localization", icon: "gearshape.fill", tint: .purple) {
                VStack(spacing: 10) {
                    HStack {
                        Text("Launch Genie Automatically at Login")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { loginItemManager.isEnabled },
                            set: { loginItemManager.setEnabled($0) }
                        ))
                        .labelsHidden()
                        .toggleStyle(.switch)
                    }

                    Divider().opacity(0.20)

                    HStack {
                        Text("Application Display Language")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                        Picker("", selection: $appLanguage) {
                            Text("English (US)").tag("English (US)")
                            Text("Español (Spanish)").tag("Español (Spanish)")
                            Text("Français (French)").tag("Français (French)")
                            Text("Deutsch (German)").tag("Deutsch (German)")
                            Text("日本語 (Japanese)").tag("日本語 (Japanese)")
                            Text("简体中文 (Chinese)").tag("简体中文 (Chinese)")
                        }
                        .pickerStyle(.menu)
                        .frame(width: 175)
                    }
                }
            }

            // Restore Defaults Button
            Button(action: {
                showResetAlert = true
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Restore Default Settings")
                        .font(.system(size: 11.5, weight: .semibold, design: .default))
                }
                .foregroundColor(.orange.opacity(0.90))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.orange.opacity(0.10))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.orange.opacity(0.25), lineWidth: 0.5)
                )
            }
            .buttonStyle(.plain)

            // Quit Genie Button
            Button(action: {
                NSApp.terminate(nil)
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "power")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Quit Genie (⌘Q)")
                        .font(.system(size: 11.5, weight: .semibold, design: .default))
                }
                .foregroundColor(.red.opacity(0.95))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.red.opacity(0.12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.red.opacity(0.30), lineWidth: 0.6)
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Reusable Liquid Glass Settings Card
    private func settingsGlassCard<Content: View>(title: String, icon: String, tint: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundColor(tint)
                Text(title.uppercased())
                    .font(.system(size: 10, weight: .semibold, design: .default))
                    .tracking(0.5)
                    .foregroundColor(.secondary)
            }
            .padding(.leading, 4)

            VStack(spacing: 0) {
                content()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(
                ZStack {
                    VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow, state: .active)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    Color.white.opacity(0.03)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.10), lineWidth: 0.5)
            )
        }
    }

    private func showBannerFeedback(_ text: String) {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
            statusFeedback = text
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation {
                if statusFeedback == text {
                    statusFeedback = nil
                }
            }
        }
    }

    private func resetToDefaults() {
        miniDockBackgroundStyle = "Clear (Transparent)"
        miniDockDisplayMode = "Always Shown"
        menuBarAppCount = 3
        statusIconGlyph = "Genie Person 🧞‍♂️"
        statusIconStyle = "Genie Person 🧞‍♂️"
        batteryStyle = "Classic Apple Battery"
        showBatteryPercentage = true
        batteryColorMode = "Dynamic Level"
        smokeEffectsEnabled = true
        soundEnabled = true
        hapticsEnabled = true
        desktopPlaneEnabled = true
        iconSize = 50.0
        UserDefaults.standard.removeObject(forKey: PrefKey.customAppOrder)
        NotificationCenter.default.post(name: NSNotification.Name("NexusResetAppOrder"), object: nil)
        AppDelegate.shared?.renderIcon()
        showBannerFeedback("Defaults restored successfully! 🧹")
    }
}
