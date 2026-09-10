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
    case models = "Models & Providers"
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
    @ObservedObject var appleAuth = GenieAppleAuth.shared
    public var onBackToApps: () -> Void = {}
    public var onClose: () -> Void = {}

    @State private var selectedTab: UnifiedSettingsTab = .miniDock
    @State private var searchText: String = ""
    @State private var isSidebarVisible: Bool = true
    @State private var statusFeedback: String? = nil
    @State private var hoveredSidebarIndex: Int? = nil
    @State private var hoveredThemeSwatchIndex: Int? = nil

    // Conversations
    @State private var renamingSessionID: UUID? = nil
    @State private var renameDraft: String = ""
    @State private var conversationSearch: String = ""
    @State private var manualAppleIDText: String = ""

    // Mini Dock & Bar
    @AppStorage(PrefKey.menuBarAppSwitcherEnabled) private var menuBarAppSwitcherEnabled: Bool = true
    @AppStorage(PrefKey.miniDockDisplayMode) private var miniDockDisplayMode: String = "Always Shown"
    @AppStorage(PrefKey.showMiniDockInMenuBar) private var showMiniDockInMenuBar: Bool = false
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
    @AppStorage(PrefKey.dockAnimationStyle) private var dockAnimationStyleRaw: String = "None"
    @AppStorage(PrefKey.dockAnimationIntensity) private var dockAnimationIntensity: Double = 0.7
    @AppStorage(PrefKey.dockFormation) private var dockFormationRaw: String = DockFormation.defaultFormation.rawValue
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
    @AppStorage(PrefKey.wheelSlideDownShowsTopStation) private var wheelSlideDownShowsTopStation: Bool = true
    @AppStorage(PrefKey.reverseStationScrollWheelDirection) private var reverseStationScrollWheelDirection: Bool = false
    @AppStorage(PrefKey.clearHTMLOverlayEnabled) private var clearHTMLOverlayEnabled: Bool = false

    // Desktop & Files
    @AppStorage(PrefKey.desktopPlaneEnabled) private var desktopPlaneEnabled: Bool = true
    @AppStorage(PrefKey.gridTransitionDirection) private var gridTransitionDirection: String = "Slide from Right (iPhone Mode 📱)"
    @ObservedObject private var desktopFilesManager = DesktopFilesManager.shared

    // Sound, Haptics & Smoke
    @AppStorage(PrefKey.soundEnabled) private var soundEnabled: Bool = true
    @AppStorage(PrefKey.hapticsEnabled) private var hapticsEnabled: Bool = true
    @AppStorage(PrefKey.smokeEffectsEnabled) private var smokeEffectsEnabled: Bool = false
    @AppStorage(PrefKey.smokeStyle) private var smokeStyle: String = "Mystical Cyan 🧞‍♂️"

    // Living Atmospheres & Glass
    @AppStorage(PrefKey.aiEmotion) private var selectedEmotionRaw: String = AIEmotionType.mystical.rawValue

    // System Permissions
    @ObservedObject private var loginItemManager = LoginItemManager.shared
    @ObservedObject private var installerManager = UtilityAppInstallerManager.shared
    @ObservedObject private var tricksterEngine = AppScreenSizeTricksterEngine.shared
    @AppStorage(PrefKey.agentSandboxEnabled) private var agentSandboxEnabled: Bool = true
    @AppStorage(PrefKey.agentDedicatedUserEnabled) private var agentDedicatedUserEnabled: Bool = false
    @AppStorage(PrefKey.agentMemoryLimitMB) private var agentMemoryLimitMB: Int = 4096
    @AppStorage(PrefKey.hdmiPixelForkEnabled) private var hdmiPixelForkEnabled: Bool = true
    @AppStorage(PrefKey.streamBackForkEnabled) private var streamBackForkEnabled: Bool = true
    @AppStorage(PrefKey.streamBackPort) private var streamBackPort: Int = 9099
    @AppStorage(PrefKey.sharedFolderBridgeEnabled) private var sharedFolderBridgeEnabled: Bool = true
    @AppStorage(PrefKey.agentBrainProvider) private var agentBrainProvider: String = "local"
    @AppStorage(PrefKey.agentAdminPrivilegesEnabled) private var agentAdminPrivilegesEnabled: Bool = true
    @AppStorage(PrefKey.agentCloudSavingEnabled) private var agentCloudSavingEnabled: Bool = true
    @ObservedObject private var memoryGovernor = GenieMemoryGovernorEngine.shared
    @ObservedObject private var streamBackEngine = GenieStreamBackEngine.shared
    @ObservedObject private var folderForkEngine = GenieSharedFolderForkEngine.shared
    @ObservedObject private var autonomousLoop = GenieAutonomousLoopEngine.shared
    @ObservedObject private var adminGovernor = GenieAdminAccessGovernor.shared
    @ObservedObject private var agentHomeEngine = GenieAgentHomeDirectoryEngine.shared
    @ObservedObject private var cloudSavingEngine = GenieAgentCloudSavingEngine.shared
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

    // The floating right-edge dock (RightEdgeDockTabsView) is now the one dock; the separate
    // Mini Dock / menu-bar dock (RealMacOSMiniDockView) is retired from navigation but its
    // code and shared PrefKey.dockAnimation* settings stay intact for the floating dock's use.
    private var visibleTabs: [UnifiedSettingsTab] {
        UnifiedSettingsTab.allCases.filter { $0 != .miniDock }
    }

    private var filteredTabs: [UnifiedSettingsTab] {
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if trimmed.isEmpty {
            return visibleTabs
        }
        return visibleTabs.filter { tab in
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

    // MARK: - Navigation Sidebar (matches macOS System Settings exactly:
    // uniform accent-color selection fill, no border, no bold-on-select,
    // no selection dot, no Dock-style hover magnify — those are Dock/Genie
    // affordances that don't exist in a real Apple sidebar.)
    private var settingsSidebar: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 2) {
                    ForEach(Array(filteredTabs.enumerated()), id: \.element) { rowIndex, tab in
                        let isSelected = (selectedTab == tab)
                        let isHovered = (hoveredSidebarIndex == rowIndex)
                        Button(action: {
                            HapticFeedback.selection()
                            withAnimation(.spring(response: 0.22, dampingFraction: 0.82)) {
                                selectedTab = tab
                            }
                        }) {
                            HStack(spacing: 8) {
                                // Squircle Badge — each item keeps its own tint,
                                // exactly like Wi-Fi/Bluetooth/etc. in System Settings.
                                ZStack {
                                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                                        .fill(tab.tintColor)
                                        .frame(width: 26, height: 26)

                                    Image(systemName: tab.icon)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.white)
                                }

                                Text(tab.rawValue)
                                    .font(.system(size: 13, weight: .regular, design: .default))
                                    .foregroundColor(isSelected ? .white : .primary)
                                    .lineLimit(1)

                                Spacer()
                            }
                            .padding(.horizontal, 8)
                            .frame(height: 30)
                            .background(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(isSelected ? Color.accentColor : (isHovered ? Color.primary.opacity(0.06) : Color.clear))
                            )
                        }
                        .buttonStyle(.plain)
                        .animation(.easeOut(duration: 0.1), value: isHovered)
                        .onHover { isHovering in
                            hoveredSidebarIndex = isHovering ? rowIndex : (hoveredSidebarIndex == rowIndex ? nil : hoveredSidebarIndex)
                        }
                    }
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 10)
            }

            Spacer()
        }
        .background(VisualEffectBlur(material: .sidebar, blendingMode: .withinWindow, state: .active))
    }

    // MARK: - 0. Genie Chat & Dialogue Pane
    private var chatSettingsPane: some View {
        VStack(spacing: 14) {
            settingsGlassCard(title: "Account", icon: "person.crop.circle.fill", tint: .white) {
                appleAccountCardBody
            }

            settingsGlassCard(title: "Genie Chat", icon: "bubble.left.and.bubble.right.fill", tint: .cyan) {
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
                            // startNewChat() files the current conversation into
                            // savedSessions first; clearChatHistory() would drop it.
                            localModels.startNewChat()
                            HapticFeedback.selection()
                            showBannerFeedback("Saved and started a fresh session ✨")
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

            settingsGlassCard(title: "Conversations", icon: "bubble.left.and.text.bubble.right.fill", tint: .cyan) {
                conversationsCardBody
            }

            settingsGlassCard(title: "Chat Controls & Model Runtime", icon: "slider.horizontal.3", tint: .purple) {
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Dedicated Floating Window")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                            Text("Full ProMotion liquid glass conversation view")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.60))
                        }
                        Spacer()
                        Button(action: {
                            HapticFeedback.selection()
                            FinderChatWindowManager.shared.toggle()
                            showBannerFeedback("Opened Genie Chat Window ✨")
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: "arrow.up.right.square.fill")
                                    .font(.system(size: 11))
                                Text("Open Chat")
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(Color.cyan))
                        }
                        .buttonStyle(.plain)
                    }

                    Divider().opacity(0.12)

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Agentic Tool Execution")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Text("Polyglot, AirDrop, Local Net, App Docs")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.60))
                        }
                        Spacer()
                        Text("Active ⚡️")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.green.opacity(0.15)))
                    }

                    Divider().opacity(0.12)

                    HStack {
                        Text("Global Hotkey")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                        Text("⌘⌥C")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.85))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(RoundedRectangle(cornerRadius: 5).fill(Color.white.opacity(0.12)))
                    }
                }
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

                    Divider().opacity(0.20)

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Dock Formation Architecture")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Text(DockFormation(preferenceValue: dockFormationRaw).subtitle)
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.60))
                        }
                        Spacer()
                        Picker("", selection: $dockFormationRaw) {
                            ForEach(DockFormation.allCases) { formation in
                                Text(formation.rawValue).tag(formation.rawValue)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 220)
                        .onChange(of: dockFormationRaw) { _, _ in
                            HapticFeedback.selection()
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
                        Text("Show Mini Dock in Menu Bar")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                        Toggle("", isOn: $showMiniDockInMenuBar)
                            .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.16, green: 0.80, blue: 0.98)))
                            .onChange(of: showMiniDockInMenuBar) { _, val in
                                UserDefaults.standard.set(val, forKey: PrefKey.showMiniDockInMenuBar)
                                AppDelegate.shared?.setupStatusItemView()
                            }
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
                        Text("Running App Slots in Dock")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                        Stepper("\(menuBarAppCount) apps", value: $menuBarAppCount, in: 1...6)
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    }

                    Divider().opacity(0.20)

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Icon Animation")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Text(DockAnimationStyle(preferenceValue: dockAnimationStyleRaw).subtitle)
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.60))
                        }
                        Spacer()
                        Picker("", selection: $dockAnimationStyleRaw) {
                            ForEach(DockAnimationStyle.allCases, id: \.rawValue) { style in
                                Text(style.rawValue).tag(style.rawValue)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 190)
                        .onChange(of: dockAnimationStyleRaw) { _, _ in
                            HapticFeedback.selection()
                        }
                    }

                    HStack {
                        Text("Animation Intensity")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                        Slider(value: $dockAnimationIntensity, in: 0.0...1.0)
                            .frame(width: 150)
                        Text(String(format: "%.0f%%", dockAnimationIntensity * 100))
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.65))
                            .frame(width: 34, alignment: .trailing)
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

            settingsGlassCard(title: "Mouse Wheel & Station Navigation", icon: "computermouse.fill", tint: .indigo) {
                VStack(spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Slide Wheel Down Shows Top Screen")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Text("Rolling or sliding the mouse wheel downward reveals the Zenith screen (Dialogue Studio & Search).")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.55))
                        }
                        Spacer()
                        Toggle("", isOn: $wheelSlideDownShowsTopStation)
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .onChange(of: wheelSlideDownShowsTopStation) { _, newVal in
                                HapticFeedback.selection()
                                showBannerFeedback(newVal ? "Slide down opens Top Screen ⬆️" : "Standard wheel direction restored ⬇️")
                            }
                    }

                    Divider().opacity(0.20)

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Reverse Wheel Scroll Direction")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Text("Invert wheel up vs down scrolling across all canvas stations.")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.55))
                        }
                        Spacer()
                        Toggle("", isOn: $reverseStationScrollWheelDirection)
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .onChange(of: reverseStationScrollWheelDirection) { _, newVal in
                                HapticFeedback.selection()
                                showBannerFeedback(newVal ? "Scroll wheel direction reversed 🔄" : "Standard wheel direction ↕️")
                            }
                    }
                }
            }

            settingsGlassCard(title: "Clear HTML Overlay & Solutions", icon: "safari.fill", tint: .purple) {
                VStack(spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Floating Transparent HTML Overlay")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Text("Loads transparent WebKit canvas connected to Swift with clickable solutions and image actions.")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.55))
                        }
                        Spacer()
                        Button(action: {
                            HapticFeedback.selection()
                            GenieClearHTMLOverlayManager.shared.toggle()
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: "sparkles")
                                Text(GenieClearHTMLOverlayManager.shared.isVisible ? "Hide Overlay" : "Launch Overlay")
                            }
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Color.purple.opacity(0.40)))
                            .overlay(Capsule().stroke(Color.purple.opacity(0.60), lineWidth: 0.8))
                        }
                        .buttonStyle(.plain)
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
                            Text("Detected: \(LocalModelManager.detectedRAMString) Unified Memory • PyTorch Metal (MPS) Ready")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.green.opacity(0.90))
                        }
                        Spacer()
                        Text("\(LocalModelManager.detectedRAMString) RAM")
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

            settingsGlassCard(title: "Available Models & Providers", icon: "sparkles", tint: Color(red: 0.85, green: 0.47, blue: 0.36)) {
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

                }
            }
        }
    }

    // MARK: - 6. Living Glass & Atmospheres Pane
    private var livingGlassSettingsPane: some View {
        VStack(spacing: 14) {
            settingsGlassCard(title: "Living Glass UI & Vibrancy", icon: "sparkles", tint: .cyan) {
                VStack(spacing: 10) {
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

            settingsGlassCard(title: "Autonomous Agent, RAM Governor & HDMI Forking", icon: "cpu.fill", tint: .green) {
                VStack(spacing: 12) {
                    // RAM Partition Governor
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("RAM Partition Ceiling (ulimit)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                Text("Hard limit per agent process. Drops background neural training frames under critical memory pressure.")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.55))
                            }
                            Spacer()
                            Text("\(agentMemoryLimitMB) MB")
                                .font(.system(size: 11.5, weight: .bold, design: .monospaced))
                                .foregroundColor(.green)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color.green.opacity(0.15)))
                                .overlay(Capsule().stroke(Color.green.opacity(0.4), lineWidth: 0.5))
                        }
                        HStack(spacing: 8) {
                            Text("1 GB")
                                .font(.system(size: 9.5))
                                .foregroundColor(.white.opacity(0.4))
                            Slider(value: Binding(
                                get: { Double(agentMemoryLimitMB) },
                                set: { agentMemoryLimitMB = Int($0) }
                            ), in: 1024...16384, step: 512)
                            .tint(.green)
                            Text("16 GB")
                                .font(.system(size: 9.5))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        HStack(spacing: 12) {
                            Text("Resident: \(memoryGovernor.currentProcessResidentMB) MB")
                                .font(.system(size: 9.5, design: .monospaced))
                                .foregroundColor(.white.opacity(0.5))
                            Text("Host Free: \(memoryGovernor.hostAvailableMemoryMB) MB")
                                .font(.system(size: 9.5, design: .monospaced))
                                .foregroundColor(.white.opacity(0.5))
                            Text("Pressure: \(memoryGovernor.currentPressureLevel.rawValue.capitalized)")
                                .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                                .foregroundColor(memoryGovernor.currentPressureLevel == .critical ? .red : (memoryGovernor.currentPressureLevel == .warning ? .yellow : .green))
                        }
                    }

                    Divider().opacity(0.20)

                    // Zero-Copy HDMI Forking
                    Toggle(isOn: $hdmiPixelForkEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Zero-Copy GPU Pixel Forking to HDMI")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                            Text("Forks hardware HDMI/UVC pixel buffers in Unified Memory: Channel 1 to live display at zero latency, Channel 2 to AI neural ring buffer.")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.55))
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .green))

                    Divider().opacity(0.20)

                    // Agent User & Toolchain Isolation
                    Toggle(isOn: $agentDedicatedUserEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Dedicated macOS Agent User (genie-agent)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                            Text("Confines toolchain to /Users/genie-agent/.local/bin. Automatically strips SSH, AWS, and GitHub tokens from execution subshells.")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.55))
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .green))
                }
            }

            settingsGlassCard(title: "Stream-Back Fork, Zero-Copy Folder Sharing & Brain Mode", icon: "arrow.triangle.2.circlepath.circle.fill", tint: .cyan) {
                VStack(spacing: 12) {
                    // Stream-Back Fork (Channel 3)
                    Toggle(isOn: $streamBackForkEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Channel 3 Upstream Video Stream-Back")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                            Text("Streams Genie's agent display, terminal & actions live to http://127.0.0.1:\(streamBackPort)/stream or external HDMI display.")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.55))
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .cyan))
                    .onChange(of: streamBackForkEnabled) { enabled in
                        if enabled {
                            streamBackEngine.startStreamServer(port: streamBackPort)
                        } else {
                            streamBackEngine.stopStreamServer()
                        }
                    }

                    if streamBackForkEnabled {
                        HStack(spacing: 12) {
                            Text("Port: \(streamBackPort)")
                                .font(.system(size: 9.5, design: .monospaced))
                                .foregroundColor(.white.opacity(0.5))
                            Text("Clients: \(streamBackEngine.activeClientsCount)")
                                .font(.system(size: 9.5, design: .monospaced))
                                .foregroundColor(.cyan)
                            Text("FPS: \(String(format: "%.1f", streamBackEngine.averageFPS))")
                                .font(.system(size: 9.5, design: .monospaced))
                                .foregroundColor(.green)
                            Spacer()
                            Button("Test Feed") {
                                streamBackEngine.pushSyntheticFrame(text: "Live Test Feed Triggered from Settings")
                            }
                            .buttonStyle(.borderless)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.cyan)
                        }
                    }

                    Divider().opacity(0.20)

                    // Zero-Copy APFS Folder Sharing
                    Toggle(isOn: $sharedFolderBridgeEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Zero-Copy APFS Folder Forking & Live Bridge")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                            Text("Darwin clonefile(2) creates instantaneous copy-on-write forks (0 RAM & 0 extra disk). Syncs to /Users/Shared/Genie/Bridge.")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.55))
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .cyan))

                    HStack(spacing: 12) {
                        Text("Active Forks: \(folderForkEngine.totalForksCreated)")
                            .font(.system(size: 9.5, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))
                        Text("Bridge Files: \(folderForkEngine.bridgeAssetCount)")
                            .font(.system(size: 9.5, design: .monospaced))
                            .foregroundColor(.white.opacity(0.5))
                        Spacer()
                        Button("Open Bridge Folder") {
                            let url = URL(fileURLWithPath: GenieSharedFolderForkEngine.defaultBridgePath)
                            NSWorkspace.shared.open(url)
                        }
                        .buttonStyle(.borderless)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.cyan)
                    }

                    Divider().opacity(0.20)

                    // Brain Provider: Local Apple Silicon vs Cloud API
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Autonomous Brain Mode (Local + API Options)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                        Text("Select whether the autonomous actuator plans actions locally via Apple Silicon or offloads to Cloud multimodal models.")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.55))

                        Picker("", selection: Binding(
                            get: { autonomousLoop.brainProvider },
                            set: { autonomousLoop.setProvider($0) }
                        )) {
                            ForEach(GenieBrainProvider.allCases) { provider in
                                HStack {
                                    Image(systemName: provider.iconName)
                                    Text(provider.displayName)
                                }
                                .tag(provider)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())

                        HStack {
                            Text("Active Provider: \(autonomousLoop.brainProvider.displayName)")
                                .font(.system(size: 9.5, design: .monospaced))
                                .foregroundColor(.cyan)
                            Spacer()
                            Button(autonomousLoop.isLoopActive ? "Stop Loop" : "Start Auto Loop") {
                                if autonomousLoop.isLoopActive {
                                    autonomousLoop.stopAutonomousLoop()
                                } else {
                                    autonomousLoop.startAutonomousLoop()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(autonomousLoop.isLoopActive ? .red : .green)
                            .font(.system(size: 10, weight: .bold))
                        }
                    }
                }
            }

            // MARK: - The 3 Pillars Card
            settingsGlassCard(title: "The 3 Pillars: Admin Authority, Agent Homes & Cloud Vault", icon: "shield.lefthalf.filled", tint: .indigo) {
                VStack(spacing: 12) {
                    // Pillar 1: Admin Authority
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text("Pillar 1: macOS Administrator Authority")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                Text(adminGovernor.isAdminAvailable ? "ADMIN ACTIVE 🛡️" : "STANDARD 🔒")
                                    .font(.system(size: 9, weight: .bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(adminGovernor.isAdminAvailable ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                                    .foregroundColor(adminGovernor.isAdminAvailable ? .green : .orange)
                                    .cornerRadius(4)
                            }
                            Text("Enables Genie to inspect user access rights, partition agent boundaries, and run audited admin tasks.")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.55))
                        }
                        Spacer()
                        Toggle("", isOn: $agentAdminPrivilegesEnabled)
                            .toggleStyle(SwitchToggleStyle(tint: .indigo))
                    }

                    HStack {
                        Text("Audit Log: /Users/Shared/Genie/Audit/admin_audit.log (\(adminGovernor.totalPrivilegedCommandsExecuted) executed)")
                            .font(.system(size: 9.5, design: .monospaced))
                            .foregroundColor(.indigo)
                        Spacer()
                        Button("Inspect Access") {
                            _ = adminGovernor.inspectUserAccess()
                            NSSound.beep()
                        }
                        .buttonStyle(.bordered)
                        .font(.system(size: 10))
                    }

                    Divider().opacity(0.20)

                    // Pillar 2: Multi-Agent Homes & Human Review
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Pillar 2: Multi-Agent Home & Review System")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                            Spacer()
                            Text("\(agentHomeEngine.registeredAgents.count) Agents Provisioned")
                                .font(.system(size: 9.5, weight: .medium))
                                .foregroundColor(.cyan)
                        }
                        Text("Every agent has an isolated home folder at /Users/Shared/Genie/Agents/<id>/ with a dedicated review queue.")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.55))

                        HStack {
                            Picker("Active Agent", selection: Binding(
                                get: { agentHomeEngine.activeAgent?.id ?? "genie-primary" },
                                set: { agentHomeEngine.setActiveAgent(id: $0) }
                            )) {
                                ForEach(agentHomeEngine.registeredAgents) { agent in
                                    Text("\(agent.name) (\(agent.role))").tag(agent.id)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())

                            Spacer()

                            Button("Review Work (\(agentHomeEngine.pendingReviews.count))") {
                                if let active = agentHomeEngine.activeAgent {
                                    agentHomeEngine.openAgentReviewInFinder(agentId: active.id)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(.purple)
                            .font(.system(size: 10, weight: .bold))

                            Button("Open Home") {
                                if let active = agentHomeEngine.activeAgent {
                                    agentHomeEngine.openAgentHomeInFinder(agentId: active.id)
                                }
                            }
                            .buttonStyle(.bordered)
                            .font(.system(size: 10))
                        }
                    }

                    Divider().opacity(0.20)

                    // Pillar 3: Hybrid Dual Saving
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text("Pillar 3: Hybrid Dual Saving (Home + Cloud)")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                Text(cloudSavingEngine.syncStatus.rawValue)
                                    .font(.system(size: 9, weight: .bold))
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.blue.opacity(0.2))
                                    .foregroundColor(.cyan)
                                    .cornerRadius(4)
                            }
                            Text("Maintains zero-latency local APFS saving while continuously mirroring artifacts and review queues to Cloud Vault.")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.55))
                        }
                        Spacer()
                        Toggle("", isOn: $agentCloudSavingEnabled)
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                    }

                    HStack {
                        Text("Synced Files: \(cloudSavingEngine.totalSyncedFiles)")
                            .font(.system(size: 9.5, design: .monospaced))
                            .foregroundColor(.blue)
                        Spacer()
                        Button(cloudSavingEngine.isSyncing ? "Syncing..." : "Sync to Cloud Now") {
                            Task { @MainActor in
                                await cloudSavingEngine.syncAllAgentsToCloud()
                            }
                        }
                        .buttonStyle(.bordered)
                        .font(.system(size: 10))
                        .disabled(cloudSavingEngine.isSyncing)

                        Button("Open Cloud Vault") {
                            cloudSavingEngine.openCloudVaultInFinder()
                        }
                        .buttonStyle(.bordered)
                        .font(.system(size: 10))
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
    // MARK: - Account (Sign in with Apple)

    @ViewBuilder
    private var appleAccountCardBody: some View {
        VStack(alignment: .leading, spacing: 12) {
            if appleAuth.isSignedIn {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.green)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(appleAuth.displayName.isEmpty ? "Nicholas Dudek" : appleAuth.displayName)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                            Text(appleAuth.email.isEmpty ? "nicholas.dudek@icloud.com" : appleAuth.email)
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.70))
                                .lineLimit(1)
                        }
                        Spacer()
                        Button(action: {
                            appleAuth.signOut()
                            HapticFeedback.selection()
                            showBannerFeedback("Signed out of Apple Account")
                        }) {
                            Text("Sign Out")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.85))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Capsule().fill(Color.white.opacity(0.10)))
                                .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 0.5))
                        }
                        .buttonStyle(.plain)
                    }

                    // iChat & iMessage Control Banner
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("iChat & Apple Messages Control Active")
                            .font(.system(size: 10.5, weight: .medium))
                            .foregroundColor(.white.opacity(0.90))
                        Spacer()
                        Button(action: {
                            let pingText = "🧞 [Genie Mac Ping]: Apple ID iChat & iMessage control connected!"
                            let ok = GeniePhoneBridgeManager.shared.sendiMessage(message: pingText)
                            HapticFeedback.selection()
                            showBannerFeedback(ok ? "✓ Sent ping to \(appleAuth.email)" : "⚠️ Sent, check Messages.app")
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 9))
                                Text("Ping iPhone")
                                    .font(.system(size: 10, weight: .semibold))
                            }
                            .foregroundColor(.cyan)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.cyan.opacity(0.15)))
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            GenieiMessageExtensionManager.shared.openConversation()
                            HapticFeedback.selection()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "message.fill")
                                    .font(.system(size: 9))
                                Text("Open Messages")
                                    .font(.system(size: 10, weight: .semibold))
                            }
                            .foregroundColor(.white.opacity(0.85))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.10)))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.05)))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.10), lineWidth: 0.5))
                }
            } else {
                Text("Sign in with your Apple Account to enable Genie's autonomous iChat and Apple Messages control, desktop remote commands, and personalized greetings.")
                    .font(.system(size: 10.5))
                    .foregroundColor(.white.opacity(0.65))
                    .fixedSize(horizontal: false, vertical: true)

                // 1. One-Click System Discovered Apple ID Button
                if let discovered = GenieAppleAuth.discoverSystemAppleAccount() {
                    Button(action: {
                        appleAuth.signInWithAppleID(email: discovered.email, displayName: discovered.displayName, source: "system_click")
                        HapticFeedback.selection()
                        showBannerFeedback("Logged in as \(discovered.email)")
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "apple.logo")
                                .font(.system(size: 13, weight: .semibold))
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Log In as \(discovered.displayName)")
                                    .font(.system(size: 11.5, weight: .semibold))
                                Text(discovered.email + " (macOS iCloud)")
                                    .font(.system(size: 9.5))
                                    .opacity(0.7)
                            }
                            Spacer()
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 13))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.white))
                    }
                    .buttonStyle(.plain)
                }

                // 2. Standard Apple Sign-In Sheet
                Button(action: {
                    appleAuth.signIn()
                    HapticFeedback.selection()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "apple.logo")
                            .font(.system(size: 12, weight: .medium))
                        Text(appleAuth.state == .signingIn ? "Signing in…" : "Sign in with Apple (Sheet)")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white.opacity(0.90))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.white.opacity(0.12)))
                    .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Color.white.opacity(0.20), lineWidth: 0.5))
                }
                .buttonStyle(.plain)
                .disabled(appleAuth.state == .signingIn)

                // 3. Manual Apple ID Entry Option
                HStack(spacing: 6) {
                    TextField("Enter Apple ID / iCloud email…", text: $manualAppleIDText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.08)))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.15), lineWidth: 0.5))

                    Button(action: {
                        let trimmed = manualAppleIDText.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !trimmed.isEmpty {
                            appleAuth.signInWithAppleID(email: trimmed, displayName: NSFullUserName())
                            HapticFeedback.selection()
                            showBannerFeedback("Logged in as \(trimmed)")
                            manualAppleIDText = ""
                        }
                    }) {
                        Text("Connect")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.blue))
                    }
                    .buttonStyle(.plain)
                    .disabled(manualAppleIDText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }

            if case .failed(let message) = appleAuth.state {
                HStack(alignment: .top, spacing: 6) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.orange)
                    Text(message)
                        .font(.system(size: 10))
                        .foregroundColor(.orange.opacity(0.90))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    // MARK: - Conversations (name, reopen, delete)

    private var filteredSessions: [SavedChatSession] {
        let q = conversationSearch.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let all = localModels.savedSessions.sorted { $0.updatedAt > $1.updatedAt }
        guard !q.isEmpty else { return all }
        return all.filter { $0.title.lowercased().contains(q) }
    }

    @ViewBuilder
    private var conversationsCardBody: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.45))
                TextField("Search conversations", text: $conversationSearch)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11))
                    .foregroundColor(.white)
                if !conversationSearch.isEmpty {
                    Button(action: { conversationSearch = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.45))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.white.opacity(0.07)))

            if filteredSessions.isEmpty {
                HStack {
                    Spacer()
                    Text(localModels.savedSessions.isEmpty
                         ? "No saved conversations yet. Start a chat, then hit New Session to file it here."
                         : "No conversation matches “\(conversationSearch)”.")
                        .font(.system(size: 10.5))
                        .foregroundColor(.white.opacity(0.50))
                        .multilineTextAlignment(.center)
                    Spacer()
                }
                .padding(.vertical, 14)
            } else {
                VStack(spacing: 6) {
                    ForEach(filteredSessions) { session in
                        conversationRow(session)
                        if session.id != filteredSessions.last?.id {
                            Divider().opacity(0.12)
                        }
                    }
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.white.opacity(0.04)))
            }
        }
    }

    @ViewBuilder
    private func conversationRow(_ session: SavedChatSession) -> some View {
        HStack(spacing: 8) {
            if renamingSessionID == session.id {
                TextField("Conversation name", text: $renameDraft, onCommit: { commitRename(session) })
                    .textFieldStyle(.plain)
                    .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(Color.white.opacity(0.10)))

                Button("Save") { commitRename(session) }
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.cyan))
                    .buttonStyle(.plain)

                Button("Cancel") { renamingSessionID = nil }
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.75))
                    .buttonStyle(.plain)
            } else {
                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 5) {
                        Text(session.title.isEmpty ? "Untitled conversation" : session.title)
                            .font(.system(size: 11.5, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        if session.id == localModels.currentSessionId {
                            Text("Open")
                                .font(.system(size: 8.5, weight: .bold))
                                .foregroundColor(.green)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1.5)
                                .background(Capsule().fill(Color.green.opacity(0.18)))
                        }
                    }
                    Text("\(session.messages.count) messages • \(session.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(.system(size: 9.5))
                        .foregroundColor(.white.opacity(0.50))
                }

                Spacer()

                Button(action: {
                    renameDraft = session.title
                    renamingSessionID = session.id
                }) {
                    Image(systemName: "pencil")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.80))
                        .padding(5)
                        .background(Circle().fill(Color.white.opacity(0.10)))
                }
                .buttonStyle(.plain)
                .help("Rename this conversation")

                Button(action: {
                    localModels.loadSession(session)
                    HapticFeedback.selection()
                    FinderChatWindowManager.shared.show()
                    showBannerFeedback("Opened “\(session.title)” 💬")
                }) {
                    Text("Open")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.white.opacity(0.10)))
                }
                .buttonStyle(.plain)

                Button(action: {
                    localModels.deleteSession(id: session.id)
                    HapticFeedback.selection()
                    showBannerFeedback("Deleted conversation 🗑")
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.red.opacity(0.85))
                        .padding(5)
                        .background(Circle().fill(Color.red.opacity(0.12)))
                }
                .buttonStyle(.plain)
                .help("Delete this conversation")
            }
        }
        .padding(.vertical, 3)
    }

    private func commitRename(_ session: SavedChatSession) {
        localModels.renameSession(id: session.id, to: renameDraft)
        renamingSessionID = nil
        HapticFeedback.selection()
        showBannerFeedback("Renamed conversation ✏️")
    }

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
