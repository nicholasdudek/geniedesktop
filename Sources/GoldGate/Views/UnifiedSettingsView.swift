import AppKit
import SwiftUI

// MARK: - ⚙️ Unified Apple-Approved Liquid Glass Settings View
// Matches the exact same liquid glass floating window format as the Genie Chat Window.
// Features a top glass switcher ribbon, searchable translucent sidebar, and floating glass cards.

public enum UnifiedSettingsTab: String, CaseIterable, Identifiable {
    case chat = "Genie Chat 💬"
    case miniDock = "Mini Dock & Bar"
    case expansion = "Feature Packs & Add-Ons 🛍️"
    case applications = "Applications"
    case desktop = "Desktop & Files"
    case studio = "Genio Studio Editor 💻"
    case soundAndSmoke = "Sound & Effects"
    case models = "Models & Providers"
    case virtualMachines = "AI Stations & VMs"
    case livingGlass = "Living Glass & UI"
    case systemAccess = "Full Computer Access"
    case huggingface = "Hugging Face Hub"
    case ergonomics = "Vision & Ergonomics 👁️"
    case generalAndPrivacy = "General & Privacy"

    public var id: String { rawValue }

    /// Emoji-free label for the UI. `rawValue` stays as-is because it is the
    /// stable identifier: notifications route by it (UnifiedSettingsTab(rawValue:))
    /// and it is persisted in AppStorage, so renaming it would break both.
    public var displayName: String {
        switch self {
        case .studio: return "Genie Studio"
        case .expansion: return "Feature Packs & Add-Ons"
        case .ergonomics: return "Vision & Ergonomics"
        default: return rawValue.emojiFree
        }
    }

    public var icon: String {
        switch self {
        case .chat: return "bubble.left.and.bubble.right.fill"
        case .miniDock: return "menubar.rectangle"
        case .expansion: return "bag.fill"
        case .applications: return "square.grid.2x2.fill"
        case .desktop: return "desktopcomputer"
        case .studio: return "macwindow"
        case .soundAndSmoke: return "speaker.wave.2.fill"
        case .models: return "brain.head.profile"
        case .virtualMachines: return "server.rack"
        case .livingGlass: return "sparkles"
        case .systemAccess: return "bolt.shield.fill"
        case .huggingface: return "cube.fill"
        case .ergonomics: return "eye.trianglebadge.exclamationmark"
        case .generalAndPrivacy: return "lock.shield.fill"
        }
    }

    public var tintColor: Color {
        switch self {
        case .chat: return .cyan
        case .miniDock: return .blue
        case .expansion: return .orange
        case .applications: return .indigo
        case .desktop: return .teal
        case .studio: return .blue
        case .soundAndSmoke: return .orange
        case .models: return Color(red: 0.85, green: 0.47, blue: 0.36)
        case .virtualMachines: return .blue
        case .livingGlass: return .cyan
        case .systemAccess: return .green
        case .huggingface: return .yellow
        case .ergonomics: return .orange
        case .generalAndPrivacy: return .purple
        }
    }

    public var keywords: [String] {
        switch self {
        case .chat: return ["chat", "dialogue", "ai", "models", "gemini", "claude", "gpt", "ollama", "prompts", "stream", "history", "speech", "voice", "mic", "microphone", "wake word", "hey genie", "learning", "ledger", "python", "self repair"]
        case .miniDock: return ["dock", "bar", "menu bar", "status icon", "battery", "percentage", "genie", "lamp", "person", "style", "install"]
        case .expansion: return ["cart", "shopping", "shop", "store", "expansion", "packs", "addons", "add-ons", "vip", "founder", "pass", "companions", "shaders", "snuggie", "pets"]
        case .applications: return ["applications", "apps", "grid", "slide", "direction", "launcher", "overlay", "size", "spacing"]
        case .desktop: return ["desktop", "files", "hide", "clean", "matrix", "wallpaper"]
        case .studio: return ["studio", "vscode", "editor", "panels", "flip", "welcome", "iphone", "instagram", "portrait", "activity bar", "code"]
        case .soundAndSmoke: return ["sound", "effects", "audio", "haptics", "smoke", "plumes", "animation"]
        case .models: return ["ai", "models", "ollama", "lm studio", "gemini", "claude", "gpt", "mps", "metal", "ram", "48gb"]
        case .virtualMachines: return ["vm", "virtual machine", "ai station", "hypervisor", "guest", "linux", "workspaces", "cpu", "memory", "ram", "permissions"]
        case .livingGlass: return ["glass", "living", "atmosphere", "translucent", "vibrancy", "theme", "emotion", "120fps"]
        case .systemAccess: return ["system", "access", "accessibility", "cgevent", "shortcuts", "axuielement", "applescript", "screen", "arrow", "arrows", "desktop switching", "spaces"]
        case .huggingface: return ["hugging face", "hf", "gguf", "spaces", "gradio", "hub", "models", "download"]
        case .ergonomics: return ["vision", "ergonomics", "camera", "fatigue", "tiredness", "distance", "field of view", "fov", "text size", "font size", "screen size", "squint", "blink", "contrast", "ram", "render", "uma"]
        case .generalAndPrivacy: return ["general", "privacy", "permissions", "accessibility", "screen recording", "login", "language", "reset"]
        }
    }
}

public struct UnifiedSettingsView: View {
    @AppStorage(PrefKey.appLanguage) var appLanguage: String = "English (US)"
    @AppStorage(PrefKey.showShortcutHints) var showShortcutHints: Bool = true
    @AppStorage(PrefKey.appsPopUpDelaySeconds) var appsPopUpDelaySeconds: Double = 10.0
    @AppStorage(PrefKey.cursorFxType) var cursorFxType: String = "None"
    @AppStorage(PrefKey.showWorkspaceRestoreHUDOnLaunch) private var showWorkspaceRestoreHUDOnLaunch: Bool = false
    private let cursorFxOptions: [String] = [
        "None",
        "Stardust Sparkles ✨",
        "Rainbow Nebula Comet 🌈",
        "Cyber Neon Ribbon ⚡️",
        "Fire Ember Sparks 🔥",
        "Deep Ocean Bubble Wake 🫧",
        "Electric Lightning Arc ⚡",
        "Matrix Green Binary Stream 🟢",
        "Golden Gate Bridge Shimmer 🌉",
        "Hyperdrive Warp Beams 🌌",
        "Heart Petal Drift 🌸",
        "Pixel 8-Bit Arcade Blast 👾",
        "Cyber Ring & Target 🎯",
        "Quantum Vortex 🌪️",
        "Ice Cream Cone & Sprinkles 🍦",
        "Cotton Candy Clouds 🍭"
    ]
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
    @AppStorage(PrefKey.showMiniDockInTopDashboard) private var showMiniDockInTopDashboard: Bool = false
    @AppStorage("neuralBloomLightningEnabled") private var neuralBloomLightningEnabled: Bool = true
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
    @AppStorage(PrefKey.enableScrollWheelStationNavigation) private var enableScrollWheelStationNavigation: Bool = false
    @AppStorage(PrefKey.wheelSlideDownShowsTopStation) private var wheelSlideDownShowsTopStation: Bool = true
    @AppStorage(PrefKey.reverseStationScrollWheelDirection) private var reverseStationScrollWheelDirection: Bool = false
    @AppStorage(PrefKey.showThickScrollBars) private var showThickScrollBars: Bool = false
    @AppStorage(PrefKey.clearHTMLOverlayEnabled) private var clearHTMLOverlayEnabled: Bool = false

    // Desktop & Files
    @AppStorage(PrefKey.desktopPlaneEnabled) private var desktopPlaneEnabled: Bool = true
    @AppStorage(PrefKey.gridTransitionDirection) private var gridTransitionDirection: String = "Slide from Right (iPhone Mode 📱)"
    @ObservedObject private var desktopFilesManager = DesktopFilesManager.shared
    @AppStorage(PrefKey.sameWallpaperMode) private var sameWallpaperMode: Bool = true
    @AppStorage(PrefKey.wallpaperMatchingStyle) private var wallpaperMatchingStyle: String = "Exact Mirror (1:1)"
    @AppStorage(PrefKey.wallpaperMode) private var wallpaperMode: String = "Genie"
    @AppStorage(PrefKey.customWallpaperPath) private var customWallpaperPath: String = ""
    @ObservedObject private var wallpaperManager = WallpaperManager.shared
    @State private var selectedWallpaperCategory: WallpaperCategory? = nil

    // VS Code Studio & iPhone Preview
    @AppStorage(PrefKey.studioPanelsFlipped) private var studioPanelsFlipped: Bool = true
    @AppStorage(PrefKey.studioShowWelcome) private var studioShowWelcome: Bool = true
    @AppStorage(PrefKey.studioShowiPhonePreview) private var studioShowiPhonePreview: Bool = false
    @AppStorage(PrefKey.studioiPhoneAspectMode) private var studioiPhoneAspectMode: String = "9:16 Portrait (Instagram Story / Reel)"
    @AppStorage(PrefKey.studioActivityBarPosition) private var studioActivityBarPosition: String = "right"

    // Sound, Haptics & Smoke
    @AppStorage(PrefKey.soundEnabled) private var soundEnabled: Bool = true
    @AppStorage(PrefKey.hapticsEnabled) private var hapticsEnabled: Bool = true
    @AppStorage(PrefKey.smokeEffectsEnabled) private var smokeEffectsEnabled: Bool = false
    @AppStorage(PrefKey.smokeStyle) private var smokeStyle: String = "Mystical Cyan 🧞‍♂️"

    // Living Atmospheres & Glass
    @AppStorage(PrefKey.activeGenieTheme) private var activeGenieThemeRaw: String = GenieTheme.defaultTheme.rawValue
    @AppStorage(PrefKey.aiEmotion) private var selectedEmotionRaw: String = AIEmotionType.mystical.rawValue

    // Feature Packs, VIP Store & Shopping Cart
    @AppStorage(PrefKey.wallpaperFxType) private var wallpaperFxType: String = "None"
    @AppStorage(PrefKey.wallpaperFxEnabled) private var wallpaperFxEnabled: Bool = false
    @AppStorage(PrefKey.windowShaderFxEnabled) private var windowShaderFxEnabled: Bool = false
    @AppStorage(PrefKey.ambientEntity) private var ambientEntity: String = "None"
    @AppStorage(PrefKey.iconSnuggie) private var iconSnuggie: String = "None"
    @AppStorage(PrefKey.appFormation) private var appFormation: String = "Natural Grid (macOS Default)"
    @AppStorage(PrefKey.appIconTintColor) private var appIconTintColor: String = "Default"
    @AppStorage(PrefKey.studioTheme) private var studioTheme: String = "Default"
    @ObservedObject private var storeManager = ExpansionStoreManager.shared

    // System Permissions
    @ObservedObject private var loginItemManager = LoginItemManager.shared
    @ObservedObject private var installerManager = UtilityAppInstallerManager.shared
    @ObservedObject private var activityMonitor = GenieActivityMonitor.shared
    @ObservedObject private var tricksterEngine = AppScreenSizeTricksterEngine.shared
    @ObservedObject private var appearance = GenieAppearance.shared
    @ObservedObject private var appearanceDetector = GenieSystemAppearanceDetector.shared
    @AppStorage(PrefKey.agentSandboxEnabled) private var agentSandboxEnabled: Bool = true
    @AppStorage(PrefKey.agentDedicatedUserEnabled) private var agentDedicatedUserEnabled: Bool = false
    @AppStorage(PrefKey.agentMemoryLimitMB) private var agentMemoryLimitMB: Int = 4096
    @AppStorage(PrefKey.hdmiPixelForkEnabled) private var hdmiPixelForkEnabled: Bool = true
    @AppStorage(PrefKey.streamBackForkEnabled) private var streamBackForkEnabled: Bool = true
    @AppStorage(PrefKey.streamBackPort) private var streamBackPort: Int = Int(GeniePortGovernor.defaultStreamBackPort)
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
    @ObservedObject private var filePermissions = GenieFilePermissionManager.shared
    @State private var isAccessibilityGranted: Bool = AXIsProcessTrusted()
    @State private var isScreenCaptureGranted: Bool = CGPreflightScreenCaptureAccess()
    @State private var showResetAlert: Bool = false
    @AppStorage(PrefKey.voiceSpeechRecognitionEnabled) private var voiceSpeechRecognitionEnabled: Bool = false
    @AppStorage(PrefKey.voiceWakeWordEnabled) private var voiceWakeWordEnabled: Bool = false
    @AppStorage(PrefKey.voiceAutoSendOnCommand) private var voiceAutoSendOnCommand: Bool = true
    @ObservedObject private var speechEngine = GenieSpeechRecognitionEngine.shared
    @ObservedObject private var learningEngine = GenieSelfRepairLearningEngine.shared
    @ObservedObject private var languageDetector = GenieLanguageInputDetector.shared
    @State private var showLearningLedgerSheet: Bool = false

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

    // Both the floating dock and the companion status bar mini dock are fully configurable,
    // alongside feature packs and store add-ons.
    private var visibleTabs: [UnifiedSettingsTab] {
        UnifiedSettingsTab.allCases
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
        // ── Main Body: Collapsible Sidebar + High-Density Content (Matches macOS System Settings) ──
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
                        case .expansion:
                            expansionSettingsPane
                        case .applications:
                            applicationsSettingsPane
                        case .desktop:
                            desktopSettingsPane
                        case .studio:
                            studioSettingsPane
                        case .soundAndSmoke:
                            soundAndSmokePane
                        case .models:
                            modelsSettingsPane
                        case .virtualMachines:
                            VirtualMachinesDashboardView()
                        case .livingGlass:
                            livingGlassSettingsPane
                        case .systemAccess:
                            systemAccessSettingsPane
                        case .huggingface:
                            huggingfaceSettingsPane
                        case .ergonomics:
                            AdaptiveErgonomicsSettingsView()
                        case .generalAndPrivacy:
                            generalAndPrivacyPane
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
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
        .sheet(isPresented: $showLearningLedgerSheet) {
            GenieSelfLearningLedgerView()
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

    // MARK: - Navigation Sidebar (matches macOS System Settings exactly:
    // search field at the top of the sidebar, followed by categorized settings rows)
    private var settingsSidebar: some View {
        VStack(spacing: 0) {
            // macOS System Settings native search field at top of sidebar
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                TextField("Search", text: $searchText)
                    .font(.system(size: 11.5, design: .default))
                    .textFieldStyle(.plain)
                    .foregroundColor(.white)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(RoundedRectangle(cornerRadius: 7, style: .continuous).fill(Color.white.opacity(0.06)))
            .overlay(RoundedRectangle(cornerRadius: 7, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 0.5))
            .padding(.horizontal, 8)
            .padding(.top, 8)
            .padding(.bottom, 4)

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

                                Text(tab.displayName)
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

                    Divider().opacity(0.12)

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Genie Magic & Shortcut Hints (🧞‍♂️✨)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                            Text("Displays futuristic quick-action shortcut pills above the input field (/settings, /finder, /editor).")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.55))
                        }
                        Spacer()
                        Toggle("", isOn: $showShortcutHints)
                            .labelsHidden()
                            .toggleStyle(.switch)
                    }
                }
            }

            settingsGlassCard(title: "macOS Appearance & Dynamic Screen Detection", icon: "display", tint: .blue) {
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Detected Mac Display")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                            Text("\(Int(appearanceDetector.screenSize.width)) × \(Int(appearanceDetector.screenSize.height)) pt • \(Int(appearanceDetector.backingScaleFactor))× Retina (\(appearanceDetector.screenCategory.rawValue))")
                                .font(.system(size: 11, design: .monospaced))
                                .foregroundColor(.white.opacity(0.70))
                        }
                        Spacer()
                        Image(systemName: appearanceDetector.hasNotch ? "laptopcomputer.and.ipad" : "display")
                            .font(.system(size: 16))
                            .foregroundColor(.blue)
                    }

                    Divider().opacity(0.12)

                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Apple Camera Notch")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Text(appearanceDetector.hasNotch ? "Hardware Notch: \(Int(appearanceDetector.notchWidth)) pt wide × \(Int(appearanceDetector.notchTopInset)) pt safe top inset" : "No hardware notch (External display or non-notched Mac)")
                                .font(.system(size: 10.5))
                                .foregroundColor(.white.opacity(0.65))
                        }
                        Spacer()
                        Text(appearanceDetector.hasNotch ? "Active 📷" : "Standard")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(appearanceDetector.hasNotch ? .green : .secondary)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(appearanceDetector.hasNotch ? Color.green.opacity(0.15) : Color.white.opacity(0.08)))
                    }

                    Divider().opacity(0.12)

                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("System Settings Text Size")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Text("Detected body font: \(Int(appearanceDetector.systemTextPointSize)) pt (Dynamic Type ratio \(String(format: "%.0f%%", appearanceDetector.systemTextScale * 100)))")
                                .font(.system(size: 10.5))
                                .foregroundColor(.white.opacity(0.65))
                        }
                        Spacer()
                        Text(String(format: "%.0f%% Scale", appearanceDetector.effectiveTextScale * 100))
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.cyan)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.cyan.opacity(0.15)))
                    }

                    Divider().opacity(0.12)

                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Finder Folder & System Theme")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Text("Chat bubbles and accents dynamically match macOS Finder colors")
                                .font(.system(size: 10.5))
                                .foregroundColor(.white.opacity(0.65))
                        }
                        Spacer()
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(appearanceDetector.folderBubbleGradient)
                            .frame(width: 44, height: 20)
                            .overlay(RoundedRectangle(cornerRadius: 6, style: .continuous).stroke(Color.white.opacity(0.40), lineWidth: 0.8))
                    }

                    Divider().opacity(0.12)

                    HStack {
                        Spacer()
                        Button(action: {
                            appearanceDetector.refreshAll()
                            HapticFeedback.selection()
                            showBannerFeedback("Synced with macOS System Settings 🔄")
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 10, weight: .bold))
                                Text("Re-Sync with System Settings")
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(Color.white.opacity(0.12)))
                            .overlay(Capsule().stroke(Color.white.opacity(0.20), lineWidth: 0.5))
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

            // Voice Dictation & Wake Word Recognition
            settingsGlassCard(title: "Voice Recognition & Wake Word", icon: "mic.badge.waveform.fill", tint: .pink) {
                VStack(spacing: 12) {
                    Toggle(isOn: $voiceSpeechRecognitionEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Speech Recognition Engine")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                            Text("Stream real-time microphone dictation into chat")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.60))
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .pink))

                    Divider().opacity(0.12)

                    Toggle(isOn: $voiceWakeWordEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Continuous Wake Word Listening")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                            Text("Activate automatically on \"Hey Genie\", \"Genie\", or \"Listen Genie\"")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.60))
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .pink))

                    Divider().opacity(0.12)

                    Toggle(isOn: $voiceAutoSendOnCommand) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Auto-Execute Voice Commands")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                            Text("Instantly submit or relay chat when trigger phrases are recognized")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.60))
                        }
                    }
                    .toggleStyle(SwitchToggleStyle(tint: .pink))

                    Divider().opacity(0.12)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Supported Voice Action Phrases")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.pink)

                        VStack(alignment: .leading, spacing: 5) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.up.circle.fill").foregroundColor(.cyan).font(.system(size: 11))
                                Text("Send / Submit:").font(.system(size: 10.5, weight: .semibold)).foregroundColor(.white)
                                Text("\"click enter\", \"send chat\", \"send\", \"submit\"").font(.system(size: 10)).foregroundColor(.white.opacity(0.70))
                            }
                            HStack(spacing: 6) {
                                Image(systemName: "iphone").foregroundColor(.green).font(.system(size: 11))
                                Text("Send to Mobile:").font(.system(size: 10.5, weight: .semibold)).foregroundColor(.white)
                                Text("\"send chat to mobile\", \"send to iphone\", \"push to phone\"").font(.system(size: 10)).foregroundColor(.white.opacity(0.70))
                            }
                            HStack(spacing: 6) {
                                Image(systemName: "rectangle.split.2x1").foregroundColor(.yellow).font(.system(size: 11))
                                Text("iPhone Duo Layout:").font(.system(size: 10.5, weight: .semibold)).foregroundColor(.white)
                                Text("\"pick up on iphone duo same size dimense\", \"pick up on iphone\"").font(.system(size: 10)).foregroundColor(.white.opacity(0.70))
                            }
                            HStack(spacing: 6) {
                                Image(systemName: "xmark.circle.fill").foregroundColor(.red).font(.system(size: 11))
                                Text("Clear Input:").font(.system(size: 10.5, weight: .semibold)).foregroundColor(.white)
                                Text("\"clear\", \"clear chat\", \"clear input\", \"erase\"").font(.system(size: 10)).foregroundColor(.white.opacity(0.70))
                            }
                        }
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.20)))
                    }

                    HStack {
                        Button(action: {
                            HapticFeedback.selection()
                            speechEngine.toggleListening()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: speechEngine.isListening ? "stop.circle.fill" : "mic.fill")
                                    .font(.system(size: 11))
                                Text(speechEngine.isListening ? "Stop Listening" : "Test Microphone Input")
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(speechEngine.isListening ? Color.red : Color.pink.opacity(0.85)))
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        if speechEngine.isListening {
                            Text("Listening...")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.pink)
                        }
                    }
                }
            }

            // Self-Repair & Python Learning Ledger
            settingsGlassCard(title: "Autonomous Self-Repair & Learning Ledger", icon: "wrench.and.screwdriver.fill", tint: .teal) {
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("Python Script Self-Repair Engine")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                            Text("Automatic AST syntax validation, rollback archives & dry-run test execution")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.60))
                        }
                        Spacer()
                        Text("Active 🛠️")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.teal)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.teal.opacity(0.15)))
                    }

                    Divider().opacity(0.12)

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Learned & Repaired Scripts")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white)
                            Text("\(learningEngine.ledgerEntries.count) verified records in audit ledger")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.60))
                        }
                        Spacer()
                        Button(action: {
                            HapticFeedback.selection()
                            showLearningLedgerSheet = true
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: "list.bullet.rectangle.fill")
                                    .font(.system(size: 11))
                                Text("View Learning Ledger")
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(Color.teal))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    // MARK: - 1. Mini Dock & Bar Pane
    private var miniDockSettingsPane: some View {
        VStack(spacing: 14) {
            // 0. Install Mini Dock in Status Menu Bar Hero Card
            settingsGlassCard(title: "Status Bar Mini Dock Companion", icon: "menubar.dock.rectangle", tint: .cyan) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        Image(systemName: showMiniDockInMenuBar ? "menubar.dock.rectangle.fill" : "menubar.rectangle")
                            .font(.system(size: 26))
                            .foregroundColor(showMiniDockInMenuBar ? .green : .cyan)

                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 6) {
                                Text("macOS Menu Bar Mini Dock")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                                Text(showMiniDockInMenuBar ? "INSTALLED & ACTIVE" : "AVAILABLE")
                                    .font(.system(size: 8.5, weight: .heavy))
                                    .foregroundColor(showMiniDockInMenuBar ? .green : .cyan)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Capsule().fill((showMiniDockInMenuBar ? Color.green : Color.cyan).opacity(0.2)))
                            }
                            Text("Place your lightning-fast companion mini dock directly inside your macOS status bar alongside your regular Dock app.")
                                .font(.system(size: 10.5))
                                .foregroundColor(.white.opacity(0.70))
                        }

                        Spacer()

                        Button(action: {
                            HapticFeedback.success()
                            showMiniDockInMenuBar.toggle()
                            if showMiniDockInMenuBar {
                                miniDockDisplayMode = "Always Shown"
                            }
                            UserDefaults.standard.set(showMiniDockInMenuBar, forKey: PrefKey.showMiniDockInMenuBar)
                            UserDefaults.standard.set(miniDockDisplayMode, forKey: PrefKey.miniDockDisplayMode)
                            AppDelegate.shared?.setupStatusItemView()
                            NotificationCenter.default.post(name: NSNotification.Name("NexusMiniDockStyleChanged"), object: miniDockBackgroundStyle)
                            showBannerFeedback(showMiniDockInMenuBar ? "Installed Mini Dock in Menu Bar! ✨" : "Mini Dock removed from Menu Bar")
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: showMiniDockInMenuBar ? "checkmark.circle.fill" : "plus.circle.fill")
                                    .font(.system(size: 11, weight: .bold))
                                Text(showMiniDockInMenuBar ? "Mini Dock Active ✓" : "Install in Menu Bar")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                Capsule()
                                    .fill(showMiniDockInMenuBar ? Color.green.opacity(0.85) : Color.cyan.opacity(0.85))
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

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
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Show Mini Dock in Top Menu")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Text("Integrated directly in the ceiling dashboard with clock & quick chat")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.50))
                        }
                        Spacer()
                        Toggle("", isOn: $showMiniDockInTopDashboard)
                            .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.16, green: 0.80, blue: 0.98)))
                            .onChange(of: showMiniDockInTopDashboard) { _, val in
                                UserDefaults.standard.set(val, forKey: PrefKey.showMiniDockInTopDashboard)
                            }
                    }

                    Divider().opacity(0.20)

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Neural Bloom Electric Lightning")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Text("Branching plasma lightning arcs connecting cursor and particles during window movements")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.50))
                        }
                        Spacer()
                        Toggle("", isOn: $neuralBloomLightningEnabled)
                            .toggleStyle(SwitchToggleStyle(tint: Color(red: 0.16, green: 0.80, blue: 0.98)))
                            .onChange(of: neuralBloomLightningEnabled) { _, val in
                                UserDefaults.standard.set(val, forKey: "neuralBloomLightningEnabled")
                            }
                    }

                    Divider().opacity(0.20)

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Show Inactive Apps in Menu Bar")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Text("Shows background running applications in the menu bar so you can quickly find and switch to them")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.50))
                        }
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

    // MARK: - Feature Packs & Add-Ons Pane (VIP Store & Shopping Cart)
    private var expansionSettingsPane: some View {
        VStack(spacing: 14) {
            // 1. VIP Membership & Founder Passes
            settingsGlassCard(title: "Genie Membership & Founder Passes", icon: "crown.fill", tint: .orange) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("All plans include full access to the 81-Screen Spatial Canvas Matrix, Neural Bloom Metal Shaders, Local AI Routing, and all Expansion Packs.")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.65))
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
                                    showBannerFeedback("Active Plan: \(plan.name) ✨")
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

            // 2. Feature Packs Showcase
            settingsGlassCard(title: "Feature Packs & Living Companions", icon: "bag.fill", tint: .yellow) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Unlock living companions, 120 FPS atmospheric Metal shaders, 3D icon snuggies, and custom grid formations.")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.65))

                    VStack(spacing: 10) {
                        ForEach(storeManager.availablePacks) { pack in
                            let isEquipped = storeManager.isPackEquipped(pack.id)
                            let primaryColor = pack.gradient.first ?? Color.cyan

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
                                                .foregroundColor(.white)

                                            Text(pack.badge)
                                                .font(.system(size: 8, weight: .black))
                                                .padding(.horizontal, 5)
                                                .padding(.vertical, 2)
                                                .background(Capsule().fill(pack.gradient.first?.opacity(0.35) ?? Color.yellow.opacity(0.35)))
                                                .foregroundColor(pack.gradient.first ?? .yellow)
                                        }

                                        Text(pack.subtitle)
                                            .font(.system(size: 10))
                                            .foregroundColor(.white.opacity(0.65))
                                            .lineLimit(2)
                                    }

                                    Spacer()
                                }

                                // Clickable individual items
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(pack.includes, id: \.self) { inc in
                                        Button(action: {
                                            applyIncludedItem(inc)
                                        }) {
                                            HStack(spacing: 5) {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .font(.system(size: 9, weight: .bold))
                                                    .foregroundColor(primaryColor)
                                                Text(inc)
                                                    .font(.system(size: 10, weight: .medium))
                                                    .foregroundColor(.white.opacity(0.85))
                                                Spacer()
                                                Text("Equip")
                                                    .font(.system(size: 8, weight: .semibold))
                                                    .foregroundColor(primaryColor)
                                                    .padding(.horizontal, 5)
                                                    .padding(.vertical, 1.5)
                                                    .background(Capsule().fill(primaryColor.opacity(0.15)))
                                            }
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.vertical, 2)

                                // Equip full pack button
                                HStack {
                                    HStack(spacing: 4) {
                                        Image(systemName: "checkmark.seal.fill")
                                            .font(.system(size: 11, weight: .bold))
                                        Text("UNLOCKED")
                                            .font(.system(size: 9.5, weight: .bold))
                                    }
                                    .foregroundColor(.green)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(Color.green.opacity(0.14)))

                                    Spacer()

                                    Button(action: { equipPackAction(pack) }) {
                                        HStack(spacing: 5) {
                                            Image(systemName: isEquipped ? "checkmark.circle.fill" : "wand.and.stars")
                                                .font(.system(size: 11, weight: .bold))
                                            Text(isEquipped ? "EQUIPPED ✓" : "EQUIP PACK")
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
                            }
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color.white.opacity(0.04))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .stroke(isEquipped ? Color.green.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 1)
                                    )
                            )
                        }
                    }
                }
            }

            // 3. Quick Shopping Cart / Special Effects Drawer
            settingsGlassCard(title: "Active Special Effects & Add-Ons", icon: "wand.and.sparkles", tint: .cyan) {
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Living Companion on Desktop")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Text("Active: \(ambientEntity)")
                                .font(.system(size: 10))
                                .foregroundColor(.cyan)
                        }
                        Spacer()
                        Picker("", selection: $ambientEntity) {
                            Text("None").tag("None")
                            Text("Cosmic Star Whale 🐋").tag("Cosmic Star Whale 🐋")
                            Text("Cherry Blossom 9-Tail Kitsune 🦊").tag("Cherry Blossom 9-Tail Kitsune 🦊")
                            Text("Japanese Koi Sanctuary 🎏").tag("Japanese Koi Sanctuary 🎏")
                            Text("Cyber Alpha Wolf 🐺").tag("Cyber Alpha Wolf 🐺")
                            Text("Genie Portal 🌀").tag("Genie Portal 🌀")
                            Text("Deep Void Star Kraken 🦑").tag("Deep Void Star Kraken 🦑")
                            Text("8-Bit Arcade Ghost 👻").tag("8-Bit Arcade Ghost 👻")
                            Text("Pixel Yoshi Companion 🦖").tag("Pixel Yoshi Companion 🦖")
                            Text("Bioluminescent Jellyfish 🪼").tag("Bioluminescent Jellyfish 🪼")
                            Text("Monarch Butterflies 🦋").tag("Monarch Butterflies 🦋")
                            Text("Golden Fireflies 🏮").tag("Golden Fireflies 🏮")
                            Text("Pacific Ocean Dolphins 🐬").tag("Pacific Ocean Dolphins 🐬")
                        }
                        .frame(width: 200)
                        .onChange(of: ambientEntity) { _, newEntity in
                            HapticFeedback.selection()
                            UserDefaults.standard.set(newEntity, forKey: PrefKey.ambientEntity)
                            showBannerFeedback("Companion: \(newEntity)")
                        }
                    }

                    Divider().opacity(0.20)

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Atmospheric Metal Shader")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Text("Active: \(wallpaperFxType)")
                                .font(.system(size: 10))
                                .foregroundColor(.orange)
                        }
                        Spacer()
                        Picker("", selection: $wallpaperFxType) {
                            Text("None").tag("None")
                            Text("Fluid Ink Chromatography 🎨").tag("Fluid Ink Chromatography 🎨")
                            Text("4K Tokyo Neon Night Rain 🌧️").tag("4K Tokyo Neon Night Rain 🌧️")
                            Text("Supermassive Black Hole Lens 🕳️").tag("Supermassive Black Hole Lens 🕳️")
                            Text("Retro CRT Vector Scanline Grid 🕹️").tag("Retro CRT Vector Scanline Grid 🕹️")
                            Text("4K Sakura Petal Blizzard 🌸").tag("4K Sakura Petal Blizzard 🌸")
                            Text("Electric Plasma Lightning Storm ⚡️").tag("Electric Plasma Lightning Storm ⚡️")
                            Text("Matrix Digital Rain Stream 🟢").tag("Matrix Digital Rain Stream 🟢")
                            Text("Hyperdrive Warp Speed 🚀").tag("Hyperdrive Warp Speed 🚀")
                        }
                        .frame(width: 200)
                        .onChange(of: wallpaperFxType) { _, newShader in
                            HapticFeedback.selection()
                            wallpaperFxEnabled = (newShader != "None")
                            windowShaderFxEnabled = (newShader != "None")
                            UserDefaults.standard.set(newShader, forKey: PrefKey.wallpaperFxType)
                            UserDefaults.standard.set(wallpaperFxEnabled, forKey: PrefKey.wallpaperFxEnabled)
                            UserDefaults.standard.set(windowShaderFxEnabled, forKey: PrefKey.windowShaderFxEnabled)
                            showBannerFeedback("Shader: \(newShader)")
                        }
                    }

                    Divider().opacity(0.20)

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Icon Snuggie & Housing")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Text("Active: \(iconSnuggie)")
                                .font(.system(size: 10))
                                .foregroundColor(.pink)
                        }
                        Spacer()
                        Picker("", selection: $iconSnuggie) {
                            Text("None").tag("None")
                            Text("Crown Jewel 👑").tag("Crown Jewel 👑")
                            Text("Cyber Samurai Mask 🥷").tag("Cyber Samurai Mask 🥷")
                            Text("Sakura Shinto Gate ⛩️").tag("Sakura Shinto Gate ⛩️")
                            Text("Astronaut Visor 👨‍🚀").tag("Astronaut Visor 👨‍🚀")
                            Text("Pixel Heart Armor ❤️").tag("Pixel Heart Armor ❤️")
                            Text("Sleeping Kitty 🐱").tag("Sleeping Kitty 🐱")
                            Text("Fox & Tail 🦊").tag("Fox & Tail 🦊")
                            Text("Panda Hug 🐼").tag("Panda Hug 🐼")
                            Text("Winter Scarf 🧣").tag("Winter Scarf 🧣")
                            Text("Cyber Frame ⚡️").tag("Cyber Frame ⚡️")
                            Text("Living Vines 🌿").tag("Living Vines 🌿")
                            Text("Coral Reef Ring 🪸").tag("Coral Reef Ring 🪸")
                            Text("Diamond Bezel 💎").tag("Diamond Bezel 💎")
                            Text("Flame Corona 🔥").tag("Flame Corona 🔥")
                            Text("Sakura Wreath 🌸").tag("Sakura Wreath 🌸")
                            Text("Golden Halo Corona 😇").tag("Golden Halo Corona 😇")
                        }
                        .frame(width: 200)
                        .onChange(of: iconSnuggie) { _, newSnuggie in
                            HapticFeedback.selection()
                            UserDefaults.standard.set(newSnuggie, forKey: PrefKey.iconSnuggie)
                            showBannerFeedback("Snuggie: \(newSnuggie)")
                        }
                    }
                }
            }
        }
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
            batteryStyle = "Cyberpunk Matrix"
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
            batteryStyle = "Solar Core"
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
        showBannerFeedback("Equipped \(pack.title) ✨")
    }

    private func applyIncludedItem(_ inc: String) {
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
        showBannerFeedback("Equipped \(inc) ✨")
    }

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
                            Text("Pop-Up Edge Hover Delay")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Text("Delay and cooldown before hovering near the screen edge can pop applications back up.")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.55))
                        }
                        Spacer()
                        Picker("", selection: $appsPopUpDelaySeconds) {
                            Text("5 Seconds").tag(5.0)
                            Text("10 Seconds (Default)").tag(10.0)
                            Text("15 Seconds").tag(15.0)
                            Text("30 Seconds").tag(30.0)
                            Text("Manual Only (No Auto-Pop)").tag(999999.0)
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
                            Text("Enable Scroll Wheel Navigation")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Text("When enabled, rolling the mouse wheel switches between Canvas Stations. Turn off to hide and disable scroll wheel gestures.")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.55))
                        }
                        Spacer()
                        Toggle("", isOn: $enableScrollWheelStationNavigation)
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .onChange(of: enableScrollWheelStationNavigation) { _, newVal in
                                HapticFeedback.selection()
                                showBannerFeedback(newVal ? "Scroll wheel navigation enabled 🖱️" : "Scroll wheel navigation hidden & disabled 🚫")
                            }
                    }

                    if enableScrollWheelStationNavigation {
                        Divider().opacity(0.20)

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
            }

            settingsGlassCard(title: "Scroll Bars & UI Indicators", icon: "scroll.fill", tint: .teal) {
                VStack(spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Thick Permanent Scroll Bars")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Text("When off (default), scroll bars hide automatically. When on, wide high-contrast scroll bars stay visible.")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.55))
                        }
                        Spacer()
                        Toggle("", isOn: $showThickScrollBars)
                            .labelsHidden()
                            .toggleStyle(.switch)
                            .onChange(of: showThickScrollBars) { _, newVal in
                                HapticFeedback.selection()
                                showBannerFeedback(newVal ? "Thick permanent scroll bars enabled 📜" : "Scroll bars auto-hidden (Native macOS) 🕶️")
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
            settingsGlassCard(title: "Living & 4K Desktop Wallpapers", icon: "sparkles", tint: .teal) {
                VStack(alignment: .leading, spacing: 14) {
                    // Status & Mode Controls
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Living Wallpapers & 5K Presets")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Text("Realtime WebGL Living Shaders, Sonoma & Golden Gate Aerials, and 5K Studio Palettes.")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.55))
                        }
                        Spacer()

                        Menu {
                            Button(action: {
                                HapticFeedback.selection()
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                    sameWallpaperMode = true
                                    wallpaperMode = "Genie"
                                    wallpaperMatchingStyle = "Exact Mirror (1:1)"
                                    customWallpaperPath = ""
                                    wallpaperManager.activeHTMLWallpaperPath = nil
                                    wallpaperManager.refresh()
                                    NotificationCenter.default.post(name: NSNotification.Name("NexusWallpaperChanged"), object: nil)
                                }
                                showBannerFeedback("1:1 Live Camouflage Enabled")
                            }) {
                                Label("1:1 Live macOS Camouflage", systemImage: "macwindow")
                            }

                            Button(action: {
                                HapticFeedback.selection()
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                    sameWallpaperMode = false
                                    wallpaperMode = "Translucent"
                                    wallpaperManager.refresh()
                                    NotificationCenter.default.post(name: NSNotification.Name("NexusWallpaperChanged"), object: nil)
                                }
                                showBannerFeedback("Frosted Glass Mode (Wallpaper Hidden)")
                            }) {
                                Label("Frosted Glass (Hide Wallpaper)", systemImage: "eye.slash")
                            }

                            Divider()

                            Button(action: {
                                HapticFeedback.selection()
                                wallpaperManager.chooseCustomWallpaper { path in
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                        sameWallpaperMode = false
                                        customWallpaperPath = path
                                        wallpaperMatchingStyle = (path as NSString).lastPathComponent
                                        _ = wallpaperManager.setSystemWallpaper(path: path)
                                    }
                                    showBannerFeedback("Custom Wallpaper Applied")
                                }
                            }) {
                                Label("Choose Custom Image or HTML...", systemImage: "folder.badge.plus")
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(wallpaperMode == "Translucent" ? "Frosted Glass" : (sameWallpaperMode ? "1:1 Live Camouflage" : "Custom Wallpaper"))
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.9))
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 9))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(Capsule().fill(Color.white.opacity(0.12)))
                        }
                        .menuStyle(.borderlessButton)
                    }

                    // Category Filter Pills
                    HStack(spacing: 8) {
                        Button(action: {
                            HapticFeedback.selection()
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                                selectedWallpaperCategory = nil
                            }
                        }) {
                            Text("All Wallpapers")
                                .font(.system(size: 10.5, weight: selectedWallpaperCategory == nil ? .bold : .medium))
                                .foregroundColor(selectedWallpaperCategory == nil ? .white : .white.opacity(0.7))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(selectedWallpaperCategory == nil ? Color.teal.opacity(0.3) : Color.white.opacity(0.08)))
                                .overlay(Capsule().stroke(selectedWallpaperCategory == nil ? Color.teal.opacity(0.6) : Color.clear, lineWidth: 1))
                        }
                        .buttonStyle(.plain)

                        ForEach(WallpaperCategory.allCases) { cat in
                            let isSel = (selectedWallpaperCategory == cat)
                            Button(action: {
                                HapticFeedback.selection()
                                withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                                    selectedWallpaperCategory = cat
                                }
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: cat.icon)
                                        .font(.system(size: 9))
                                    Text(cat.rawValue)
                                        .font(.system(size: 10.5, weight: isSel ? .bold : .medium))
                                }
                                .foregroundColor(isSel ? .white : .white.opacity(0.7))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(isSel ? Color.teal.opacity(0.3) : Color.white.opacity(0.08)))
                                .overlay(Capsule().stroke(isSel ? Color.teal.opacity(0.6) : Color.clear, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }

                        Spacer()
                    }

                    // Wallpapers Grid
                    let filteredWallpapers = wallpaperManager.availableWallpapers.filter { item in
                        guard !item.isSystemActive else { return false }
                        if let cat = selectedWallpaperCategory {
                            return item.category == cat
                        }
                        return true
                    }

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 140, maximum: 180), spacing: 10)], spacing: 10) {
                        ForEach(filteredWallpapers.prefix(36), id: \.id) { wpItem in
                            let isSelected = !sameWallpaperMode && (wallpaperMatchingStyle == wpItem.name || wallpaperMatchingStyle == wpItem.path || customWallpaperPath == wpItem.path)
                            Button(action: {
                                HapticFeedback.selection()
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.70)) {
                                    sameWallpaperMode = false
                                    wallpaperMode = "Custom"
                                    wallpaperMatchingStyle = wpItem.name
                                    customWallpaperPath = wpItem.path
                                    _ = wallpaperManager.setSystemWallpaper(path: wpItem.path)
                                }
                                showBannerFeedback("Applied: \(wpItem.name)")
                            }) {
                                VStack(alignment: .leading, spacing: 4) {
                                    ZStack(alignment: .topTrailing) {
                                        if let thumb = wallpaperManager.thumbnail(for: wpItem) {
                                            Image(nsImage: thumb)
                                                .resizable()
                                                .aspectRatio(16/9, contentMode: .fill)
                                                .frame(height: 76)
                                                .clipped()
                                                .cornerRadius(8)
                                        } else {
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.white.opacity(0.08))
                                                .frame(height: 76)
                                                .overlay(Image(systemName: "photo").foregroundColor(.white.opacity(0.3)))
                                        }

                                        if isSelected {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(.teal)
                                                .background(Circle().fill(Color.black.opacity(0.75)))
                                                .padding(6)
                                        }

                                        if wpItem.path.hasSuffix(".html") || wpItem.id == "neural_bloom" {
                                            HStack(spacing: 2) {
                                                Image(systemName: "waveform.path.ecg")
                                                    .font(.system(size: 8))
                                                Text("LIVING")
                                                    .font(.system(size: 8, weight: .black))
                                            }
                                            .foregroundColor(.cyan)
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 2)
                                            .background(Capsule().fill(Color.black.opacity(0.75)))
                                            .padding(6)
                                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                                        }
                                    }

                                    Text(wpItem.name)
                                        .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                                        .foregroundColor(isSelected ? .teal : .white.opacity(0.85))
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                }
                                .padding(6)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(isSelected ? Color.teal.opacity(0.18) : Color.white.opacity(0.06))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(isSelected ? Color.teal : Color.white.opacity(0.08), lineWidth: isSelected ? 1.5 : 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Action buttons bar
                    HStack {
                        Button(action: {
                            HapticFeedback.selection()
                            wallpaperManager.chooseCustomWallpaper { path in
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                    sameWallpaperMode = false
                                    customWallpaperPath = path
                                    wallpaperMatchingStyle = (path as NSString).lastPathComponent
                                    _ = wallpaperManager.setSystemWallpaper(path: path)
                                }
                                showBannerFeedback("Custom Wallpaper Applied")
                            }
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 11))
                                Text("Add Custom Wallpaper...")
                                    .font(.system(size: 11, weight: .medium))
                            }
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.10)))
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Button(action: {
                            HapticFeedback.selection()
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                sameWallpaperMode = true
                                wallpaperMode = "Genie"
                                wallpaperMatchingStyle = "Exact Mirror (1:1)"
                                customWallpaperPath = ""
                                wallpaperManager.activeHTMLWallpaperPath = nil
                                wallpaperManager.refresh()
                                NotificationCenter.default.post(name: NSNotification.Name("NexusWallpaperChanged"), object: nil)
                            }
                            showBannerFeedback("Restored 1:1 Live macOS Wallpaper")
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 10))
                                Text("Restore 1:1 Camouflage")
                                    .font(.system(size: 10.5, weight: .medium))
                            }
                            .foregroundColor(.white.opacity(0.65))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 4)
                }
            }

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
                    // Local Engines Telemetry Strip
                    VStack(alignment: .leading, spacing: 6) {
                        Text("LOCAL PROVIDERS")
                            .font(.system(size: 9.5, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)

                        HStack(spacing: 6) {
                            HStack(spacing: 4) {
                                Circle().fill(Color.cyan).frame(width: 6, height: 6)
                                Text("Ollama :11434")
                                    .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.85))
                            }
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3.5)
                            .background(Capsule().fill(Color.white.opacity(0.06)))

                            HStack(spacing: 4) {
                                Circle().fill(Color.orange).frame(width: 6, height: 6)
                                Text("MLX Metal :8080")
                                    .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.85))
                            }
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3.5)
                            .background(Capsule().fill(Color.white.opacity(0.06)))

                            HStack(spacing: 4) {
                                Circle().fill(Color.purple).frame(width: 6, height: 6)
                                Text("LM Studio :1234")
                                    .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.85))
                            }
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3.5)
                            .background(Capsule().fill(Color.white.opacity(0.06)))

                            Spacer()

                            Button(action: {
                                localModels.refreshAvailableModels()
                                HapticFeedback.selection()
                                showBannerFeedback("Scanning Local Providers")
                            }) {
                                HStack(spacing: 3) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 8, weight: .bold))
                                    Text("Scan")
                                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                                }
                                .foregroundColor(.cyan)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color.cyan.opacity(0.12)))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Discovered Local Models List
                    if !localModels.availableModels.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 5) {
                                Image(systemName: "desktopcomputer")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.cyan)
                                Text("Discovered Local Models (\(localModels.availableModels.count))")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(.cyan)
                                Spacer()
                            }
                            .padding(.top, 4)

                            VStack(spacing: 6) {
                                ForEach(localModels.availableModels) { localItem in
                                    HStack(spacing: 8) {
                                        VStack(alignment: .leading, spacing: 1) {
                                            HStack(spacing: 5) {
                                                Text(localItem.displayName)
                                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                                    .foregroundColor(.white)
                                                Text(localItem.source)
                                                    .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                                                    .foregroundColor(.cyan)
                                                    .padding(.horizontal, 4.5)
                                                    .padding(.vertical, 1)
                                                    .background(Capsule().fill(Color.cyan.opacity(0.15)))
                                            }
                                            Text(localItem.displaySize)
                                                .font(.system(size: 9.5))
                                                .foregroundColor(.white.opacity(0.50))
                                        }

                                        Spacer()

                                        if localModels.selectedModelDisplayName == localItem.displayName {
                                            Text("Active")
                                                .font(.system(size: 9.5, weight: .bold))
                                                .foregroundColor(.green)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Capsule().fill(Color.green.opacity(0.18)))
                                        } else {
                                            Button("Select") {
                                                localModels.selectModel(localItem.name)
                                                HapticFeedback.selection()
                                                showBannerFeedback("Selected \(localItem.displayName)")
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

                                    if localItem.id != localModels.availableModels.last?.id {
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

                    // Flagship Architectures
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
                                                Text("Active")
                                                    .font(.system(size: 9.5, weight: .bold))
                                                    .foregroundColor(.green)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(Capsule().fill(Color.green.opacity(0.18)))
                                            } else {
                                                Button("Select") {
                                                    localModels.selectModel(model.id)
                                                    HapticFeedback.selection()
                                                    showBannerFeedback("Selected \(model.displayName)")
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
            appearanceCard

            // 1. Live Atmospheric Preview Card (120 FPS Metal)
            settingsGlassCard(title: "Active Atmosphere Preview (120 FPS)", icon: "sparkles.tv", tint: .cyan) {
                VStack(alignment: .leading, spacing: 10) {
                    let currentTheme = GenieTheme(rawValue: activeGenieThemeRaw) ?? .defaultTheme
                    ZStack(alignment: .bottomLeading) {
                        GenieDefaultLivingAtmosphereView(theme: currentTheme, isGenerating: true)
                            .frame(height: 110)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(currentTheme.accentColor.opacity(0.45), lineWidth: 1.0)
                            )

                        HStack(spacing: 8) {
                            ZStack {
                                Circle().fill(currentTheme.accentColor.opacity(0.85)).frame(width: 22, height: 22)
                                Image(systemName: currentTheme.icon)
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            VStack(alignment: .leading, spacing: 1) {
                                Text(currentTheme.rawValue)
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                Text(currentTheme.description)
                                    .font(.system(size: 9))
                                    .foregroundColor(.white.opacity(0.75))
                                    .lineLimit(1)
                            }
                            Spacer()
                            Text("120 FPS ACTIVE")
                                .font(.system(size: 8, weight: .heavy, design: .monospaced))
                                .foregroundColor(currentTheme.accentColor)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2.5)
                                .background(Capsule().fill(Color.black.opacity(0.65)))
                                .overlay(Capsule().stroke(currentTheme.accentColor.opacity(0.5), lineWidth: 0.5))
                        }
                        .padding(10)
                        .background(
                            LinearGradient(
                                colors: [Color.black.opacity(0.75), Color.black.opacity(0.35)],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
            }

            // 2. Apple 2028 Flagship Suite
            settingsGlassCard(title: "Apple 2028 Flagship Themes", icon: "sparkles", tint: .cyan) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Architected for macOS. Fluid living water caustics, OLED blackout card horology, and quantum titanium glass load by default at 120 FPS.")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.65))

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach([
                            GenieTheme.apple2028LiquidWater,
                            GenieTheme.apple2028OledPillow,
                            GenieTheme.apple2028QuantumGlass,
                            GenieTheme.apple2028FrostedLight
                        ]) { theme in
                            themeSelectorItem(theme: theme)
                        }
                    }
                }
            }

            // 3. Optional Living Atmosphere Themes
            settingsGlassCard(title: "Optional Living Atmosphere Themes", icon: "paintpalette.fill", tint: .purple) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Atmospheric environments for macOS. Ambient nebulae, oceanic swells, dynamic amber pulses, and botanical emerald gradients.")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.65))

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ForEach([
                            GenieTheme.mysticalAurora,
                            GenieTheme.contemplativeOcean,
                            GenieTheme.energeticAmber,
                            GenieTheme.playfulEmerald
                        ]) { theme in
                            themeSelectorItem(theme: theme)
                        }
                    }
                }
            }

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

            settingsGlassCard(title: "Interactive Cursor FX & Particle Trails", icon: "wand.and.stars", tint: .teal) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Real-Time GPU Cursor Trails & Particle Dynamics")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Text("16 fluid, ProMotion-synced animations rendering directly above all desktop apps at 120 FPS.")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.55))
                        }
                        Spacer()
                        if cursorFxType != "None" {
                            Button(action: {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                    cursorFxType = "None"
                                    GenieGlobalCursorFXOverlayManager.shared.setCursorFxType("None")
                                }
                                HapticFeedback.selection()
                                showBannerFeedback("Cursor FX Disabled")
                            }) {
                                Text("Disable FX")
                                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white.opacity(0.80))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3.5)
                                    .background(Capsule().fill(Color.white.opacity(0.12)))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 155), spacing: 8)], spacing: 8) {
                        ForEach(cursorFxOptions, id: \.self) { cfx in
                            let isSelected = (cursorFxType == cfx)
                            Button(action: {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                                    cursorFxType = cfx
                                    GenieGlobalCursorFXOverlayManager.shared.setCursorFxType(cfx)
                                }
                                HapticFeedback.selection()
                                showBannerFeedback("Cursor FX: \(cfx)")
                            }) {
                                HStack(spacing: 8) {
                                    Text(cfx)
                                        .font(.system(size: 10.5, weight: isSelected ? .bold : .medium, design: .rounded))
                                        .foregroundColor(isSelected ? .white : .white.opacity(0.85))
                                        .lineLimit(1)
                                    Spacer()
                                    if isSelected {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.teal)
                                    }
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(isSelected ? Color.teal.opacity(0.28) : Color.white.opacity(0.05))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .strokeBorder(isSelected ? Color.teal.opacity(0.70) : Color.white.opacity(0.08), lineWidth: isSelected ? 1.0 : 0.5)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private func themeSelectorItem(theme: GenieTheme) -> some View {
        let isSelected = (activeGenieThemeRaw == theme.rawValue)
        return Button(action: {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                activeGenieThemeRaw = theme.rawValue
            }
            HapticFeedback.selection()
        }) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(theme.accentColor.opacity(isSelected ? 0.90 : 0.25))
                        .frame(width: 26, height: 26)
                    Image(systemName: theme.icon)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(isSelected ? .white : theme.accentColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(theme.shortTitle)
                        .font(.system(size: 11, weight: isSelected ? .bold : .medium, design: .rounded))
                        .foregroundColor(isSelected ? .white : .white.opacity(0.85))

                    Text(theme.description)
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.50))
                        .lineLimit(2)
                }
                Spacer(minLength: 0)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(theme.accentColor)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? theme.accentColor.opacity(0.22) : Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(isSelected ? theme.accentColor.opacity(0.65) : Color.white.opacity(0.08), lineWidth: 0.8)
            )
        }
        .buttonStyle(.plain)
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

            filePermissionsCard

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
                    .onChange(of: streamBackForkEnabled) { _, enabled in
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

    // MARK: - 🛡️ File Permissions & Sandbox Confinement Settings Card
    private var filePermissionsCard: some View {
        settingsGlassCard(title: "File Permissions & Restricted Confinement", icon: "shield.checkered", tint: .green) {
            VStack(spacing: 12) {
                // Restricted Sandbox Mode Toggle
                Toggle(isOn: $filePermissions.isRestrictedMode) {
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("Restricted Execution Mode")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                            Text(filePermissions.isRestrictedMode ? "Restricted 🛡️" : "Custom Confinement 🔒")
                                .font(.system(size: 9.5, weight: .bold, design: .rounded))
                                .foregroundColor(.green)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.green.opacity(0.18)))
                        }
                        Text("Confines shell subprocesses and file modifications strictly to user-permitted directories.")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.55))
                    }
                }
                .toggleStyle(SwitchToggleStyle(tint: .green))

                Divider().opacity(0.20)

                // Standard macOS Directory Permissions
                VStack(alignment: .leading, spacing: 8) {
                    Text("User Directory Permissions")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white.opacity(0.85))

                    Toggle("Desktop Folder (~/Desktop)", isOn: $filePermissions.allowDesktop)
                        .font(.system(size: 11))
                        .toggleStyle(SwitchToggleStyle(tint: .green))

                    Toggle("Developer & Projects (~/Desktop/Developer)", isOn: $filePermissions.allowDeveloperProjects)
                        .font(.system(size: 11))
                        .toggleStyle(SwitchToggleStyle(tint: .green))

                    Toggle("Documents Folder (~/Documents)", isOn: $filePermissions.allowDocuments)
                        .font(.system(size: 11))
                        .toggleStyle(SwitchToggleStyle(tint: .green))

                    Toggle("Downloads Folder (~/Downloads)", isOn: $filePermissions.allowDownloads)
                        .font(.system(size: 11))
                        .toggleStyle(SwitchToggleStyle(tint: .green))
                }

                Divider().opacity(0.20)

                // Custom Allowed Folders
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Custom Allowed Folders")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.85))
                        Spacer()
                        Button(action: {
                            filePermissions.addCustomFolder()
                        }) {
                            HStack(spacing: 3) {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Folder...")
                            }
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.cyan)
                        }
                        .buttonStyle(.plain)
                    }

                    if filePermissions.customAllowedPaths.isEmpty {
                        Text("No custom folders added. Click 'Add Folder...' to grant access to external code repos.")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.40))
                    } else {
                        ForEach(Array(filePermissions.customAllowedPaths.enumerated()), id: \.offset) { idx, path in
                            HStack {
                                Image(systemName: "folder.badge.gearshape")
                                    .foregroundColor(.cyan)
                                    .font(.system(size: 10.5))
                                Text(path)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.85))
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                                Spacer()
                                Button(action: {
                                    filePermissions.removeCustomFolder(at: idx)
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 11))
                                        .foregroundColor(.white.opacity(0.4))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.vertical, 2)
                        }
                    }
                }

                Divider().opacity(0.20)

                // Always Protected System Boundaries
                HStack(spacing: 6) {
                    Image(systemName: "lock.shield.fill")
                        .foregroundColor(.green)
                        .font(.system(size: 12))
                    Text("Always Protected: /System, /usr, /bin, ~/.ssh, ~/.aws, and Keychains are strictly locked against modification.")
                        .font(.system(size: 9.5))
                        .foregroundColor(.white.opacity(0.55))
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
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Show Restore Workspace Popup on Launch")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Text("Prompt to restore previous theme, windows, and spatial layout on startup.")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.55))
                        }
                        Spacer()
                        Toggle("", isOn: $showWorkspaceRestoreHUDOnLaunch)
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
                            ForEach(AppLanguage.allCases) { lang in
                                Text("\(lang.flag)  \(lang.rawValue)").tag(lang.rawValue)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 175)
                        .onChange(of: appLanguage) { _, newLang in
                            HapticFeedback.selection()
                            UserDefaults.standard.set(newLang, forKey: PrefKey.appLanguage)
                            showBannerFeedback("Language: \(newLang)")
                        }
                    }

                    Divider().opacity(0.20)

                    // Keyboard & Input Detection Controls
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Auto-Detect from Keyboard Layout (TIS)")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white)
                                Text("Dynamically synchronizes UI language when you switch keyboard layouts (e.g., 2-Set Korean ↔ U.S.).")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.55))
                            }
                            Spacer()
                            Toggle("", isOn: $languageDetector.autoDetectFromKeyboard)
                                .labelsHidden()
                                .toggleStyle(.switch)
                        }

                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Auto-Detect Language from Typed Input")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white)
                                Text("Uses Apple NaturalLanguage & Hangul Unicode detection to automatically adapt responses.")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.55))
                            }
                            Spacer()
                            Toggle("", isOn: $languageDetector.autoDetectFromInput)
                                .labelsHidden()
                                .toggleStyle(.switch)
                        }

                        // Live detection status badges
                        HStack(spacing: 8) {
                            HStack(spacing: 5) {
                                Image(systemName: "keyboard.fill")
                                    .font(.system(size: 9.5))
                                    .foregroundColor(.purple)
                                Text("Keyboard: \(languageDetector.activeKeyboardLayoutName)")
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.85))
                            }
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3.5)
                            .background(Capsule().fill(Color.purple.opacity(0.18)))

                            if let inputLang = languageDetector.lastDetectedInputLanguage {
                                HStack(spacing: 5) {
                                    Text("\(inputLang.flag)")
                                        .font(.system(size: 10))
                                    Text("Detected: \(inputLang.rawValue)")
                                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                                        .foregroundColor(.green.opacity(0.90))
                                }
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3.5)
                                .background(Capsule().fill(Color.green.opacity(0.16)))
                            }
                            Spacer()
                        }
                        .padding(.top, 2)
                    }
                }
            }

            settingsGlassCard(title: "Activity Monitor", icon: "eye.trianglebadge.exclamationmark.fill", tint: .purple) {
                VStack(spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Log App Switches & Clipboard Changes")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Text("Off by default. Kept as a bounded local log (last 300 events) for your own review — clipboard entries are truncated to 200 characters and never sent to a model unless you ask Genie to read this log.")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.55))
                        }
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { activityMonitor.isMonitoring },
                            set: { $0 ? activityMonitor.start() : activityMonitor.stop() }
                        ))
                        .labelsHidden()
                        .toggleStyle(.switch)
                    }

                    if activityMonitor.isMonitoring {
                        Divider().opacity(0.20)

                        HStack {
                            Text("\(activityMonitor.events.count) events logged")
                                .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                                .foregroundColor(.white.opacity(0.55))
                            Spacer()
                            Button(action: { activityMonitor.clear() }) {
                                Text("Clear Log")
                                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Capsule().fill(Color.white.opacity(0.10)))
                                    .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 0.5))
                            }
                            .buttonStyle(.plain)
                        }

                        if !activityMonitor.events.isEmpty {
                            ScrollView(.vertical, showsIndicators: true) {
                                VStack(alignment: .leading, spacing: 4) {
                                    ForEach(Array(activityMonitor.events.elements.reversed().prefix(50))) { event in
                                        Text(event.summary)
                                            .font(.system(size: 9.5, design: .monospaced))
                                            .foregroundColor(.white.opacity(0.75))
                                            .lineLimit(1)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .frame(maxHeight: 140)
                        }
                    }
                }
            }

            // ℹ️ About Genie, Patent Utility Notice, Comments & Complaints, and As-Is Disclaimer
            settingsGlassCard(title: "About Genie & Patent Utility Legal Notice", icon: "shield.lefthalf.filled", tint: .purple) {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(nsImage: NSApp.applicationIconImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 44, height: 44)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            .shadow(color: Color.black.opacity(0.3), radius: 4, y: 2)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Genie")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text("Version 1.0 (Build 1.0) • macOS 14.0+")
                                .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                                .foregroundColor(.purple.opacity(0.85))
                            Text("Copyright © 2026 Nicholas M. Dudek. All rights reserved.")
                                .font(.system(size: 9.5))
                                .foregroundColor(.white.opacity(0.55))
                        }
                        Spacer()

                        Button(action: {
                            (NSApp.delegate as? AppDelegate)?.showAboutPanel(nil)
                        }) {
                            Text("About Panel ℹ️")
                                .font(.system(size: 10, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.white.opacity(0.10)))
                                .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 0.5))
                        }
                        .buttonStyle(.plain)
                    }

                    Divider().opacity(0.20)

                    // 1. Patent & Utility Notice
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 5) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.yellow)
                            Text("Patent Utility Disclosure")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        }
                        Text("Genie is an innovative proprietary patent utility for desktop spatial computing, window management, and ambient artificial intelligence. Made in the United States and South Korea by Nicholas M. Dudek 2026 United States Apple 3rd Party. United States & International Patents Pending.")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.75))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Divider().opacity(0.20)

                    // 2. Comments and Complaints Contact
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 5) {
                            Image(systemName: "envelope.badge.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.cyan)
                            Text("Comments, Complaints & Issue Inquiries")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        }
                        Text("For any comments, suggestions, complaints, or technical issues related to the utility, please contact the developer directly:")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.75))

                        HStack(spacing: 8) {
                            Button(action: {
                                if let url = URL(string: "mailto:contact@nicholasdudek.com?subject=Genie%20Utility%20Feedback%20and%20Inquiry") {
                                    NSWorkspace.shared.open(url)
                                }
                            }) {
                                HStack(spacing: 5) {
                                    Image(systemName: "envelope.fill")
                                        .font(.system(size: 9))
                                    Text("contact@nicholasdudek.com")
                                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                                }
                                .foregroundColor(.cyan)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 4.5)
                                .background(Capsule().fill(Color.cyan.opacity(0.14)))
                                .overlay(Capsule().stroke(Color.cyan.opacity(0.35), lineWidth: 0.5))
                            }
                            .buttonStyle(.plain)

                            Button(action: {
                                if let url = URL(string: "https://nicholasdudek.com") {
                                    NSWorkspace.shared.open(url)
                                }
                            }) {
                                HStack(spacing: 5) {
                                    Image(systemName: "globe")
                                        .font(.system(size: 9))
                                    Text("nicholasdudek.com")
                                        .font(.system(size: 10, weight: .medium))
                                }
                                .foregroundColor(.white.opacity(0.85))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4.5)
                                .background(Capsule().fill(Color.white.opacity(0.08)))
                                .overlay(Capsule().stroke(Color.white.opacity(0.16), lineWidth: 0.5))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Divider().opacity(0.20)

                    // 3. Special Dedication: Apple Developers Across 30 Years
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 5) {
                            Image(systemName: "apple.logo")
                                .font(.system(size: 11))
                                .foregroundColor(.white)
                            Text("Special Thanks to Apple Developers (1996 – 2026)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        }
                        Text("With deepest admiration and gratitude to thirty years of Apple engineers, designers, and system architects. From NeXTSTEP and OPENSTEP, through Mac OS X, Aqua, Quartz Extreme, Core Animation, Grand Central Dispatch, LLVM, Metal, Swift, SwiftUI, AppKit, ScreenCaptureKit, Apple Vision, and Apple Silicon Unified Memory. Your relentless commitment to taste, craft, and architectural elegance made Genie possible.")
                            .font(.system(size: 9.5))
                            .foregroundColor(.white.opacity(0.80))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    Divider().opacity(0.20)

                    // 4. As-Is & No Warranties Disclaimer
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 5) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.orange)
                            Text("Disclaimer & \"As Is\" Warranty Notice")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        }
                        Text("THE SOFTWARE AND UTILITY ARE PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, TITLE, AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS, DEVELOPERS, OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES, OR OTHER LIABILITY ARISING FROM, OUT OF, OR IN CONNECTION WITH THE SOFTWARE OR THE USE OF THIS UTILITY.")
                            .font(.system(size: 8.5, weight: .regular, design: .monospaced))
                            .foregroundColor(.white.opacity(0.60))
                            .fixedSize(horizontal: false, vertical: true)
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

            VStack(spacing: 4) {
                Text("Made in the United States and South Korea by Nicholas M. Dudek 2026 United States Apple 3rd Party")
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundColor(.white.opacity(0.60))
                Text("Genie macOS • All Rights Reserved")
                    .font(.system(size: 9.5))
                    .foregroundColor(.white.opacity(0.35))
            }
            .padding(.top, 8)
            .padding(.bottom, 4)
        }
    }

    // MARK: - Genio Studio Editor Pane
    private var studioSettingsPane: some View {
        VStack(spacing: 14) {
            settingsGlassCard(title: "Genio Studio Editor Layout & Flippable Panels", icon: "arrow.left.arrow.right", tint: .blue) {
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Flip Studio Panels (Studio Insiders Style)")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                            Text("When ON: Chat & Sessions on Left, Editor in Center, Explorer on Right. When OFF: Classic layout.")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.60))
                        }
                        Spacer()
                        Toggle("", isOn: $studioPanelsFlipped)
                            .toggleStyle(SwitchToggleStyle(tint: .cyan))
                            .labelsHidden()
                            .onChange(of: studioPanelsFlipped) { _, flipped in
                                HapticFeedback.selection()
                                showBannerFeedback(flipped ? "Layout: Chat on Left, Explorer on Right (Studio Insiders) ⚡️" : "Layout: Explorer on Left, Chat on Right (Classic) ⚡️")
                            }
                    }

                    Divider().opacity(0.12)

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Show Welcome Page on Startup")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Text("Opens Visual Studio Code - Insiders welcome canvas with quick starts & recent workspaces.")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.60))
                        }
                        Spacer()
                        Toggle("", isOn: $studioShowWelcome)
                            .toggleStyle(SwitchToggleStyle(tint: .cyan))
                            .labelsHidden()
                            .onChange(of: studioShowWelcome) { _, enabled in
                                HapticFeedback.selection()
                                showBannerFeedback(enabled ? "Welcome canvas enabled on startup ✨" : "Direct editor enabled on startup ✨")
                            }
                    }

                    Divider().opacity(0.12)

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Activity Bar Position")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Text("Vertical icon rail location for Explorer, Search, Git, and VM.")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.60))
                        }
                        Spacer()
                        Picker("", selection: $studioActivityBarPosition) {
                            Text("Right").tag("right")
                            Text("Left").tag("left")
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 140)
                    }
                }
            }

            settingsGlassCard(title: "iPhone Rendered Portrait (Instagram Method)", icon: "iphone.gen3", tint: .purple) {
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("iPhone Device Preview Dock")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.white)
                            Text("Authentic titanium iPhone chassis with dynamic island, 9:16 portrait ratio, and Instagram Story card preview.")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.60))
                        }
                        Spacer()
                        Toggle("", isOn: $studioShowiPhonePreview)
                            .toggleStyle(SwitchToggleStyle(tint: .cyan))
                            .labelsHidden()
                            .onChange(of: studioShowiPhonePreview) { _, enabled in
                                HapticFeedback.selection()
                                showBannerFeedback(enabled ? "iPhone Portrait Preview Dock enabled 📱" : "iPhone Preview hidden ⚪️")
                            }
                    }

                    Divider().opacity(0.12)

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Default Aspect Mode")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Text("Select Instagram story, reel, portrait post, or square feed aspect ratio.")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.60))
                        }
                        Spacer()
                        Picker("", selection: $studioiPhoneAspectMode) {
                            Text("9:16 Story / Reel").tag("9:16 Portrait (Instagram Story / Reel)")
                            Text("4:5 Post").tag("4:5 Portrait (Instagram Post)")
                            Text("1:1 Square").tag("1:1 Square (Feed)")
                        }
                        .pickerStyle(MenuPickerStyle())
                        .frame(width: 160)
                    }

                    Divider().opacity(0.12)

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Screen Continuity / Mirroring")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white)
                            Text("Mirror actual iOS device into the studio preview container.")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.60))
                        }
                        Spacer()
                        Button(action: {
                            iPhoneMirrorManager.shared.launchOrActivateApp()
                            HapticFeedback.selection()
                            showBannerFeedback("Launched iPhone Screen Continuity 📱")
                        }) {
                            Text("Launch Continuity")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(.cyan)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Capsule().fill(Color.cyan.opacity(0.15)))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            settingsGlassCard(title: "Agentic Code Studio Capabilities", icon: "sparkles", tint: .green) {
                VStack(spacing: 10) {
                    HStack {
                        Text("Zero Resource Overlap")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                        Text("Continuous Isolation ⚡️")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.green.opacity(0.15)))
                    }

                    Divider().opacity(0.12)

                    HStack {
                        Text("Task Verification Engine")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                        Text("Verified Tasks 🛡️")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(.cyan)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.cyan.opacity(0.15)))
                    }

                    Divider().opacity(0.12)

                    HStack {
                        Text("Continuous Diagnostics")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                        Spacer()
                        Text("Active 🔬")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(.yellow)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.yellow.opacity(0.15)))
                    }
                }
            }

            // Microsoft Apache 2.0 Open Source Attribution Card
            settingsGlassCard(title: "Microsoft Open Source Attribution (Apache 2.0)", icon: "checkmark.seal.fill", tint: .orange) {
                VStack(alignment: .leading, spacing: 7) {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(.orange)
                        Text("Visual Studio Code & Monaco Editor Attribution")
                            .font(.system(size: 11.5, weight: .bold))
                            .foregroundColor(.white)
                    }

                    Text("Genio Studio Editor incorporates open-source components and architecture patterns derived from Visual Studio Code and Monaco Editor under the Apache License, Version 2.0.\n\nCopyright © Microsoft Corporation. Licensed under the Apache License, Version 2.0 (the \"License\"); you may not use this file except in compliance with the License.")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.70))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
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
                            Text(appleAuth.displayName.isEmpty ? (NSFullUserName().isEmpty ? "Apple Account User" : NSFullUserName()) : appleAuth.displayName)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white)
                            Text(appleAuth.email.isEmpty ? "user@icloud.com" : appleAuth.email)
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

                // 2. Standard Apple Sign-In Sheet — Apple's own button widget,
                // not a hand-styled approximation. whiteOutline reads correctly
                // against this panel's dark glass background.
                OfficialSignInWithAppleButton(
                    style: .whiteOutline,
                    isEnabled: appleAuth.state != .signingIn
                ) {
                    appleAuth.signIn()
                    HapticFeedback.selection()
                }
                .frame(height: 44)

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


    // MARK: - Appearance (chat theme, text scale, accent)

    /// Presets rather than free controls: every option here has to stay legible on both
    /// grounds and inside a 460pt window, so the choices are ones that were checked.
    private var appearanceCard: some View {
        settingsGlassCard(title: "Appearance", icon: "textformat.size", tint: .purple) {
            VStack(alignment: .leading, spacing: 14) {

                // ---- Chat layout theme ----
                VStack(alignment: .leading, spacing: 6) {
                    Text("Chat layout")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)

                    // Wraps instead of scrolling, so every theme is reachable at any pane width.
                    FlowingChips(items: GenieChatTheme.allCases) { theme in
                        let on = appearance.chatTheme == theme
                        Button {
                            withAnimation(.spring(response: 0.26, dampingFraction: 0.82)) {
                                appearance.chatTheme = theme
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(theme.label)
                                    .font(.system(size: 11.5, weight: on ? .semibold : .medium,
                                                  design: theme.usesSerifHeadings ? .serif : .default))
                                Text(theme.blurb)
                                    .font(.system(size: 9.5))
                                    .foregroundColor(.white.opacity(0.55))
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .frame(width: 148, alignment: .leading)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: max(4, theme.cornerRadius * 0.55), style: .continuous)
                                    .fill(on ? Color.accentColor.opacity(0.22) : Color.white.opacity(0.06))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: max(4, theme.cornerRadius * 0.55), style: .continuous)
                                    .stroke(on ? Color.accentColor.opacity(0.85) : Color.white.opacity(0.14),
                                            lineWidth: on ? 1.4 : 0.8)
                            )
                            .shadow(color: .black.opacity(theme.shadowRadius > 0 ? 0.35 : 0),
                                    radius: theme.shadowRadius * 0.4, y: 2)
                            .foregroundColor(.white)
                        }
                        .buttonStyle(.plain)
                    }
                }

                Divider().opacity(0.18)

                // ---- Text size ----
                VStack(alignment: .leading, spacing: 6) {
                    Text("Text size")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)

                    HStack(spacing: 6) {
                        ForEach(GenieTextScale.allCases) { scale in
                            let on = appearance.textScale == scale
                            Button {
                                appearance.textScale = scale
                            } label: {
                                VStack(spacing: 2) {
                                    // Sample renders at the real size, so the choice is visible first.
                                    Text("Aa").font(.system(size: scale.previewPointSize, weight: .semibold))
                                    Text(scale.label).font(.system(size: 9))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                                .frame(maxWidth: .infinity, minHeight: 44)
                                .background(RoundedRectangle(cornerRadius: 7)
                                    .fill(on ? Color.accentColor.opacity(0.22) : Color.white.opacity(0.06)))
                                .overlay(RoundedRectangle(cornerRadius: 7)
                                    .stroke(on ? Color.accentColor.opacity(0.85) : Color.white.opacity(0.14),
                                            lineWidth: on ? 1.4 : 0.8))
                                .foregroundColor(.white)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    Text("Larger sizes step back automatically in narrow panes so the tab row keeps fitting.")
                        .font(.system(size: 9.5))
                        .foregroundColor(.white.opacity(0.5))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Divider().opacity(0.18)

                // ---- Accent ----
                VStack(alignment: .leading, spacing: 6) {
                    Text("Accent")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)

                    HStack(spacing: 8) {
                        ForEach(GenieAccent.allCases) { acc in
                            let on = appearance.accent == acc
                            Button {
                                appearance.accent = acc
                            } label: {
                                Circle()
                                    .fill(acc.swatch)
                                    .frame(width: 22, height: 22)
                                    .overlay(Circle().stroke(Color.white.opacity(on ? 0.95 : 0.20),
                                                             lineWidth: on ? 2 : 1))
                                    .overlay(
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 9, weight: .bold))
                                            .foregroundColor(.black.opacity(0.75))
                                            .opacity(on ? 1 : 0)
                                    )
                            }
                            .buttonStyle(.plain)
                            .help(acc.label)
                        }
                        Spacer()
                    }
                }
            }
        }
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
