import AppKit
import SwiftUI
import WebKit
import UniformTypeIdentifiers

// MARK: - 🚀 Quick Project / File Creation Kinds
public enum QuickCreateKind: String, CaseIterable, Sendable {
    case swift = "Swift File"
    case web = "HTML5 / Web"
    case python = "Python Script"
    case markdown = "Markdown Note"
    case shell = "Shell Script"
    case folder = "Project Folder"

    public var title: String { rawValue }

    public var icon: String {
        switch self {
        case .swift: return "swift"
        case .web: return "chevron.left.forwardslash.chevron.right"
        case .python: return "shippingbox.fill"
        case .markdown: return "doc.richtext"
        case .shell: return "terminal.fill"
        case .folder: return "folder.badge.plus"
        }
    }

    public var defaultExtension: String {
        switch self {
        case .swift: return "swift"
        case .web: return "html"
        case .python: return "py"
        case .markdown: return "md"
        case .shell: return "sh"
        case .folder: return ""
        }
    }

    public var defaultPlaceholder: String {
        switch self {
        case .swift: return "ContentView.swift"
        case .web: return "index.html"
        case .python: return "main.py"
        case .markdown: return "README.md"
        case .shell: return "run.sh"
        case .folder: return "NewProject"
        }
    }

    public var starterTemplate: String {
        switch self {
        case .swift:
            return """
            import SwiftUI

            struct ContentView: View {
                var body: some View {
                    VStack(spacing: 16) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 36))
                            .foregroundStyle(.tint)
                        Text("Hello from Genie!")
                            .font(.headline)
                    }
                    .padding()
                }
            }
            """
        case .web:
            return """
            <!DOCTYPE html>
            <html lang="en">
            <head>
              <meta charset="UTF-8">
              <meta name="viewport" content="width=device-width, initial-scale=1.0">
              <title>Genie Web Project</title>
              <style>
                body {
                  margin: 0;
                  min-height: 100vh;
                  display: grid;
                  place-content: center;
                  background: #0d0f12;
                  color: #e6edf3;
                  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
                }
                .card {
                  padding: 2rem 2.5rem;
                  background: rgba(255, 255, 255, 0.05);
                  border: 1px solid rgba(255, 255, 255, 0.1);
                  border-radius: 16px;
                  backdrop-filter: blur(20px);
                }
              </style>
            </head>
            <body>
              <div class="card">
                <h1>✨ Built with Genie</h1>
                <p>Edit this file or ask Genie to generate components.</p>
              </div>
            </body>
            </html>
            """
        case .python:
            return """
            #!/usr/bin/env python3
            \"\"\"
            Genie Python Script
            \"\"\"

            def main():
                print("✨ Hello from Genie Python Studio!")

            if __name__ == "__main__":
                main()
            """
        case .markdown:
            return """
            # Project Notes

            Created in Genie Studio on \(Date().formatted(date: .abbreviated, time: .shortened)).

            ## Objectives
            - [ ] Define project scope
            - [ ] Implement core features
            - [ ] Test and iterate
            """
        case .shell:
            return """
            #!/bin/bash
            set -euo pipefail

            echo "⚡ Running Genie automation script..."
            """
        case .folder:
            return ""
        }
    }
}

// MARK: - Finder Sidebar Selection Enum (Retained for API & notification compatibility)
public enum FinderChatSidebarItem: String, CaseIterable, Identifiable {
    case activeChat = "Claude & Gemma"
    case github = "GitHub Studio"
    case creations = "AI Creations"
    case notes = "Saved Notes"
    case webBrowser = "Mini Browser"
    case terminal = "Terminal Shell"
    case settings = "Genie Settings"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .activeChat: return "sparkles"
        case .github: return "arrow.triangle.branch"
        case .creations: return "paintpalette.fill"
        case .notes: return "doc.text.fill"
        case .webBrowser: return "globe"
        case .terminal: return "terminal.fill"
        case .settings: return "gearshape.fill"
        }
    }

    public var color: Color {
        switch self {
        case .activeChat: return Color(red: 0.85, green: 0.47, blue: 0.36)
        case .github: return Color(red: 0.58, green: 0.44, blue: 0.96)
        case .creations: return .yellow
        case .notes: return .orange
        case .webBrowser: return .blue
        case .terminal: return .green
        case .settings: return .cyan
        }
    }
}

// MARK: - 💨 Animated Mystical Smoke & Stardust Particle Canvas
public struct GenieBubblySmokeBackgroundView: View {
    let isGenerating: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(isGenerating: Bool = false) {
        self.isGenerating = isGenerating
    }

    public var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion || !isGenerating)) { timeline in
            Canvas { context, size in
                let w = size.width
                let h = size.height
                guard w > 0, h > 0 else { return }

                let t = timeline.date.timeIntervalSinceReferenceDate

                // 1. Ambient Ethereal Glow Plumes
                // Plume A: Mystical Aladdin Cyan (drifting bottom-center to top-right)
                let p1X = w * (0.50 + 0.20 * sin(t * 0.32))
                let p1Y = h * (0.65 + 0.16 * cos(t * 0.38))
                let r1 = min(w, h) * 0.58
                context.drawLayer { ctx in
                    ctx.opacity = isGenerating ? 0.40 : 0.22
                    let g1 = Gradient(colors: [
                        Color(red: 0.0, green: 0.92, blue: 0.85).opacity(0.68),
                        Color(red: 0.05, green: 0.52, blue: 0.95).opacity(0.32),
                        Color.clear
                    ])
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: p1X - r1, y: p1Y - r1, width: r1 * 2, height: r1 * 2)),
                        with: .radialGradient(g1, center: CGPoint(x: p1X, y: p1Y), startRadius: 0, endRadius: r1)
                    )
                }

                // Plume B: Royal Violet / Lamp Vapor (center-left)
                let p2X = w * (0.28 + 0.16 * cos(t * 0.26))
                let p2Y = h * (0.40 + 0.18 * sin(t * 0.30))
                let r2 = min(w, h) * 0.52
                context.drawLayer { ctx in
                    ctx.opacity = isGenerating ? 0.35 : 0.18
                    let g2 = Gradient(colors: [
                        Color(red: 0.65, green: 0.20, blue: 0.95).opacity(0.62),
                        Color(red: 0.35, green: 0.10, blue: 0.70).opacity(0.24),
                        Color.clear
                    ])
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: p2X - r2, y: p2Y - r2, width: r2 * 2, height: r2 * 2)),
                        with: .radialGradient(g2, center: CGPoint(x: p2X, y: p2Y), startRadius: 0, endRadius: r2)
                    )
                }

                // Plume C: Stardust Amber Ember Glow
                let p3X = w * (0.70 + 0.14 * sin(t * 0.40 + 1.2))
                let p3Y = h * (0.25 + 0.14 * cos(t * 0.34 + 1.8))
                let r3 = min(w, h) * 0.44
                context.drawLayer { ctx in
                    ctx.opacity = isGenerating ? 0.28 : 0.14
                    let g3 = Gradient(colors: [
                        Color(red: 1.0, green: 0.75, blue: 0.30).opacity(0.52),
                        Color(red: 0.95, green: 0.40, blue: 0.15).opacity(0.18),
                        Color.clear
                    ])
                    ctx.fill(
                        Path(ellipseIn: CGRect(x: p3X - r3, y: p3Y - r3, width: r3 * 2, height: r3 * 2)),
                        with: .radialGradient(g3, center: CGPoint(x: p3X, y: p3Y), startRadius: 0, endRadius: r3)
                    )
                }

                // 2. Billowing Smoke Plumes
                let puffCount = 8
                for i in 0..<puffCount {
                    let fi = Double(i)
                    let speed = 0.55 + fi * 0.12
                    let phase = fi * 1.25
                    let cycle = (t * speed + phase).truncatingRemainder(dividingBy: 2.0) / 2.0

                    let curY = h * (1.12 - cycle * 1.24)
                    let driftX = sin(cycle * .pi * 2.0 + fi) * (w * 0.16)
                    let curX = w * (0.18 + (fi / Double(puffCount)) * 0.64) + driftX
                    let puffSize = 70.0 + cycle * 130.0

                    let puffOpacity = sin(cycle * .pi) * (isGenerating ? 0.34 : 0.18)
                    guard puffOpacity > 0.01 else { continue }

                    let puffColor1 = (i % 2 == 0 ? Color(red: 0.0, green: 0.95, blue: 0.85) : Color(red: 0.72, green: 0.35, blue: 1.0))
                    let puffColor2 = (i % 2 == 0 ? Color(red: 0.10, green: 0.58, blue: 0.95) : Color(red: 0.45, green: 0.12, blue: 0.85))

                    let puffGrad = Gradient(colors: [
                        puffColor1.opacity(puffOpacity),
                        puffColor2.opacity(puffOpacity * 0.38),
                        Color.clear
                    ])

                    context.drawLayer { ctx in
                        ctx.fill(
                            Path(ellipseIn: CGRect(x: curX - puffSize/2, y: curY - puffSize/2, width: puffSize, height: puffSize * 0.82)),
                            with: .radialGradient(puffGrad, center: CGPoint(x: curX, y: curY), startRadius: 0, endRadius: puffSize / 2)
                        )
                    }
                }

                // 3. Floating Starlight Embers
                let emberCount = 16
                for i in 0..<emberCount {
                    let fi = Double(i)
                    let speed = 0.14 + (fi * 0.025)
                    let emberCycle = (t * speed + fi * 0.65).truncatingRemainder(dividingBy: 4.8) / 4.8
                    let curY = h * (1.06 - emberCycle * 1.12)
                    let curX = w * (0.08 + (fi / Double(emberCount)) * 0.84) + sin(t * 0.75 + fi) * 18
                    let emberAlpha = sin(emberCycle * .pi) * 0.68
                    let emberSize = 2.0 + (sin(t * 2.2 + fi) + 1.0) * 1.4

                    context.drawLayer { ctx in
                        ctx.opacity = emberAlpha
                        ctx.fill(
                            Path(ellipseIn: CGRect(x: curX, y: curY, width: emberSize, height: emberSize)),
                            with: .color(.white)
                        )
                    }
                }
            }
        }
        .allowsHitTesting(false)
        .blur(radius: 10)
    }
}

public enum ChatWindowLayoutMode: String, CaseIterable, Identifiable {
    case chatOnly = "Chat"
    case files = "Files & Chat"
    /// Editor: the focused chat render over the folder it writes into, beside the chat.
    case editor = "Editor"
    case filesOnly = "Files"
    case settingsOnly = "Settings"

    public var id: String { rawValue }

    /// Shown in the left slide-out sidebar. Files and Settings are reached from the
    /// chat input bar instead (a slide-up tray and a dedicated button), not listed here.
    public static var sidebarTabs: [ChatWindowLayoutMode] {
        [.chatOnly, .editor]
    }

    public var tabTitle: String {
        switch self {
        case .chatOnly: return "Chat"
        case .files: return "Files & Chat"
        case .editor: return "Editor"
        case .filesOnly: return "Files"
        case .settingsOnly: return "Settings"
        }
    }

    public var icon: String {
        switch self {
        case .chatOnly: return "bubble.left.and.bubble.right.fill"
        case .files: return "folder.fill.badge.plus"
        case .editor: return "chevron.left.forwardslash.chevron.right"
        case .filesOnly: return "folder.fill"
        case .settingsOnly: return "gearshape.fill"
        }
    }
}

// MARK: - 🔮 Borderless Floating Bubbly Liquid Glass Chat Window
public struct FinderStyleChatWindowView: View {
    @ObservedObject var localModels = LocalModelManager.shared
    @ObservedObject var windowManager = FinderChatWindowManager.shared
    @ObservedObject var sleepManager = GenieSleepPreventionManager.shared
    @ObservedObject var imessageManager = GenieiMessageExtensionManager.shared
    @ObservedObject var voiceEngine = GenieVoiceEngine.shared
    @ObservedObject var speechEngine = GenieSpeechRecognitionEngine.shared
    @ObservedObject var screenRecorder = DesktopScreenRecorder.shared
    @AppStorage(PrefKey.aiEmotion) var selectedEmotionRaw: String = AIEmotionType.mystical.rawValue
    @AppStorage(PrefKey.activeGenieTheme) private var activeThemeRaw: String = GenieTheme.defaultTheme.rawValue
    @AppStorage(PrefKey.isEditorCollapsed) private var isEditorCollapsed: Bool = false
    @AppStorage(PrefKey.chatZoomLevel) private var chatZoomLevel: Double = 1.0
    @AppStorage(PrefKey.isTerminalBannerVisible) private var isTerminalBannerVisible: Bool = true
    @State private var showThemePickerPopover: Bool = false
    @AppStorage(PrefKey.showShortcutHints) private var showShortcutHints: Bool = false
    @State private var isHintsHovered: Bool = false
    @State private var isHintsRowHovered: Bool = false
    @AppStorage(PrefKey.soundEnabled) private var isSoundEnabled: Bool = true
    @AppStorage(PrefKey.smokeEffectsEnabled) private var isAtmosphereEnabled: Bool = true
    @AppStorage(PrefKey.liquidGlassEnabled) private var isLiquidGlassEnabled: Bool = true
    @AppStorage(PrefKey.agentSandboxEnabled) private var isSandboxEnabled: Bool = true
    @AppStorage(PrefKey.notchClearanceMode) private var notchClearanceMode: Bool = true
    @AppStorage("genieShowInChatWidgets") private var showInChatWidgets: Bool = false

    private var isHintsActive: Bool {
        showShortcutHints || isHintsHovered || isHintsRowHovered
    }

    private var activeTheme: GenieTheme {
        get { GenieTheme(rawValue: activeThemeRaw) ?? .defaultTheme }
        nonmutating set { activeThemeRaw = newValue.rawValue }
    }

    private var activeThemeBinding: Binding<GenieTheme> {
        Binding(
            get: { GenieTheme(rawValue: activeThemeRaw) ?? .defaultTheme },
            set: { activeThemeRaw = $0.rawValue }
        )
    }

    @State private var showLearningLedger: Bool = false

    @State private var splitRatio: CGFloat = 0.54
    @State private var isDraggingDivider: Bool = false
    @State private var dragStartWidth: CGFloat?
    @State private var browserURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
    @State private var activeEditorFileURL: URL? = nil
    @State private var editorCodeContent: String = ""
    @State private var promptText: String = ""
    @FocusState private var isPromptFieldFocused: Bool
    @State private var statusFeedback: String? = nil
    @State private var previewCreation: (title: String, html: String, fileURL: URL?)? = nil
    @State private var sessionArtifacts: [(title: String, html: String, fileURL: URL?)] = []
    @State private var droppedAttachments: [URL] = []
    @State private var isChatDropTargeted: Bool = false
    @State private var isFilesTrayOpen: Bool = false
    @State private var topSearchText: String = ""
    @State private var isTopSearchPopoverPresented: Bool = false
    @State private var topSearchResultsFiles: [GenieLocalFileItem] = []
    @State private var topSearchResultsApps: [DockAppItem] = []
    @State private var animatedHintIndex: Int = 0

    private func updateTopSearch(query: String) {
        let clean = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else {
            topSearchResultsFiles = []
            topSearchResultsApps = []
            isTopSearchPopoverPresented = false
            return
        }

        // Search local files via IPE bitmask engine
        topSearchResultsFiles = GenieLocalFileCrawlerEngine.shared.searchFiles(query: clean, maxResults: 6)

        // Search dock applications
        let allApps = DockAndDesktopManager.loadSystemDockApps()
        topSearchResultsApps = allApps.filter {
            $0.name.localizedCaseInsensitiveContains(clean) ||
            ($0.bundleIdentifier?.localizedCaseInsensitiveContains(clean) ?? false)
        }.prefix(4).map { $0 }

        isTopSearchPopoverPresented = true
    }

    private func executeTopSearchSubmit() {
        let query = topSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }
        isTopSearchPopoverPresented = false

        // 1. If match is an app, open it as a tab
        if let app = topSearchResultsApps.first {
            let bid = app.bundleIdentifier ?? app.id
            windowManager.openProgram(bundleId: bid, name: app.name)
            topSearchText = ""
            return
        }

        // 2. If match is a file, open in editor
        if let file = topSearchResultsFiles.first {
            openFileInEditor(URL(fileURLWithPath: file.path))
            topSearchText = ""
            return
        }

        // 3. Otherwise send to Genie Chat and switch to chat tab
        withAnimation(.spring(response: 0.38, dampingFraction: 0.84)) {
            windowManager.openTab(.chat)
        }
        localModels.generate(prompt: query)
        topSearchText = ""
    }

    private let animatedShortcuts: [String] = [
        "Ask Genie anything... (Try /tail, /settings, /finder, /editor)",
        "🧞‍♂️✨ /tail - Retrieve past computer logs & recent items",
        "🧞‍♂️✨ 'what was I working on?' or 'tail recent'",
        "🧞‍♂️✨ /settings - Open 2028 Living Glass Settings",
        "🧞‍♂️✨ /finder - Open a new Files & Finder Tab (⌘N)",
        "🧞‍♂️✨ /editor - Open Genie Editor (⌘E)",
        "🧞‍♂️✨ /chat - Open a fresh Chat Session (⌘T)",
        "🧞‍♂️✨ 'open Safari' or 'open Notes' or 'open Xcode'",
        "🧞‍♂️✨ /terminal - Interactive Terminal Cookbooks",
        "🧞‍♂️✨ /browser - Live Web View Canvas",
        "🧞‍♂️✨ ⌘⇧C - Copy Whole Chat (or /copychat)",
        "🧞‍♂️✨ ⌘⇧V - Paste Whole Chat (or /pastechat)",
        "🧞‍♂️✨ Drop any file (.swift, .py, .html) to analyze"
    ]

    private var layoutMode: ChatWindowLayoutMode {
        get {
            switch windowManager.activeTab.kind {
            case .chat: return .chatOnly
            case .editor: return .editor
            case .files: return .filesOnly
            case .settings: return .settingsOnly
            default: return .chatOnly
            }
        }
        nonmutating set {
            switch newValue {
            case .chatOnly: windowManager.activeTab = .chat
            case .editor: windowManager.activeTab = .editor
            case .files, .filesOnly: windowManager.activeTab = .files
            case .settingsOnly: windowManager.activeTab = .settings
            }
        }
    }

    private var isShowingSettings: Bool {
        get { windowManager.activeTab.kind == .settings }
    }

    private var currentEmotion: AIEmotionType {
        if !localModels.activeEmotionRaw.isEmpty, let em = AIEmotionType(rawValue: localModels.activeEmotionRaw) {
            return em
        }
        if localModels.isGenerating {
            return .contemplative
        }
        return AIEmotionType(rawValue: selectedEmotionRaw) ?? .mystical
    }

    public var isEmbedded: Bool = false
    @AppStorage(PrefKey.showMiniDockInChatBar) private var isAppleDockVisible: Bool = true
    @AppStorage("genieChatShowTopRibbon") private var isTopRibbonVisible: Bool = false
    @AppStorage("genieZenModeEnabled") private var isZenModeEnabled: Bool = false
    @State private var isSlidingDoorsOpen: Bool = false
    @State private var showSkyLightWallpaperDrawer: Bool = false
    @State private var showDropDownCLIDrawer: Bool = false
    @State private var showQuickCreationSheet: Bool = false
    @State private var quickCreateName: String = ""
    @State private var quickCreateKind: QuickCreateKind = .swift
    @State private var quickCreateDirectory: URL = {
        let devURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop/Developer")
        if FileManager.default.fileExists(atPath: devURL.path) {
            return devURL
        }
        return FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
    }()

    public init(isEmbedded: Bool = false) {
        self.isEmbedded = isEmbedded
    }

    public var body: some View {
        ZStack {
            if !isEmbedded {
                if isZenModeEnabled, let bloomURL = WallpaperManager.shared.resolvedNeuralBloomURL() {
                    LiveHTMLWallpaperCanvasView(fileURL: bloomURL, isBackdrop: true)
                    VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow, state: .active)
                        .opacity(0.35)
                } else {
                    // Default Living Atmosphere & Visual Effects Layer (Apple 2028 Caustics / Quantum / OLED)
                    GenieDefaultLivingAtmosphereView(theme: activeTheme, isGenerating: localModels.isGenerating)
                }
            }

            // 3. Floating Content Layer
            VStack(spacing: 0) {
                // Floating Bubbly Header Bar
                floatingHeaderBar
                    .background(isEmbedded ? nil : WindowDragRepresentable())
                    .padding(.top, isEmbedded ? 6 : (GenieSystemAppearanceDetector.shared.hasNotch ? 14 : 10))
                    .padding(.horizontal, isEmbedded ? 8 : 14)
                    .padding(.bottom, 6)

                // SkyLight Wallpaper Emergence Portal (Wallpapers emerge from SkyLight)
                if showSkyLightWallpaperDrawer {
                    skyLightWallpaperEmergenceDrawer
                }

                // 📟 Quake-Style Drop-Down CLI Console (The Genie Block View)
                if showDropDownCLIDrawer {
                    GenieTerminalSplashView(compact: false, onDismiss: {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                            showDropDownCLIDrawer = false
                        }
                    })
                    .padding(.horizontal, isEmbedded ? 8 : 14)
                    .padding(.bottom, 6)
                    .transition(.asymmetric(
                        insertion: .move(edge: .top).combined(with: .opacity),
                        removal: .move(edge: .top).combined(with: .opacity)
                    ))
                    .zIndex(300)
                }

                // 🕒 In-Chat Integrated World Clock & Widgets Drawer
                if showInChatWidgets {
                    inChatWidgetBarDrawer
                }

                // Main Workspace: chat always fills the window as a single chat-only
                // container. Editor/Files becomes a hover-reveal drawer over it.
                GeometryReader { geo in
                    let totalW = geo.size.width
                    let totalH = geo.size.height

                    workspaceBaseContent(totalW: totalW, totalH: totalH)
                        .frame(width: totalW, height: totalH)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        // Borderless Floating Window Shape with Apple Glass Polymorphism Rim
        .clipShape(RoundedRectangle(cornerRadius: isEmbedded ? 16 : 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: isEmbedded ? 16 : 24, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isEmbedded ? 0.20 : 0.38),
                            Color.white.opacity(0.12),
                            Color.white.opacity(0.04),
                            Color.white.opacity(isEmbedded ? 0.10 : 0.20)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.0
                )
        )
        .overlay(alignment: .top) {
            statusFeedbackOverlay
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("NexusSetWindowMode"))) { notif in
            if let mode = notif.object as? String { handleSetWindowMode(mode) }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("NexusSwitchFinderSidebar"))) { notif in
            if let item = notif.object as? FinderChatSidebarItem { handleSwitchFinderSidebar(item) }
        }
        .onReceive(windowManager.$stagedAttachments) { newFiles in handleStagedAttachments(newFiles) }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusAIDisplayCreation"))) { notif in handleAIDisplayCreation(notif) }
        .onReceive(NotificationCenter.default.publisher(for: .genieChatRenderFocused)) { notif in handleChatRenderFocused(notif) }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusSpeechTranscriptUpdated"))) { notif in
            if let text = notif.object as? String { self.promptText = text }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusVoiceSubmitChat"))) { notif in handleVoiceSubmitChat(notif) }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusSpeechClearChat"))) { _ in self.promptText = "" }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("GenieSetChatPromptText"))) { notif in
            if let text = notif.object as? String { self.promptText = text }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusSearchBarAppendText"))) { notif in
            if let text = notif.object as? String { handleSearchBarAppendText(text) }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusFocusGenieSearchBarWithMode"))) { notif in
            if let mode = notif.object as? String { handleFocusGenieSearchBarWithMode(mode) }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("GenieOpenURLInEditor"))) { notif in
            if let url = notif.object as? URL { openFileInEditor(url) }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("GenieToggleDropDownCLI"))) { _ in
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) { showDropDownCLIDrawer.toggle() }
        }
        .background(
            Button("") {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                    showDropDownCLIDrawer.toggle()
                }
            }
            .keyboardShortcut("`", modifiers: .command)
            .opacity(0)
            .allowsHitTesting(false)
        )
        .sheet(isPresented: $showLearningLedger) {
            GenieSelfLearningLedgerView()
        }
        .onKeyPress(.escape) {
            if previewCreation != nil {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                    previewCreation = nil
                }
                HapticFeedback.selection()
                return .handled
            }
            FinderChatWindowManager.shared.hide()
            return .handled
        }
        .onKeyPress { press in
            handleKeyPress(press)
        }
        .onAppear {
            localModels.activeSaveDirectoryOverride = browserURL
            Timer.scheduledTimer(withTimeInterval: 3.5, repeats: true) { _ in
                DispatchQueue.main.async {
                    animatedHintIndex = (animatedHintIndex + 1) % animatedShortcuts.count
                }
            }
        }
        .onChange(of: browserURL) { _, newValue in
            localModels.activeSaveDirectoryOverride = newValue
        }
        .onChange(of: windowManager.activeTab) { _, _ in
            if speechEngine.isRunning {
                speechEngine.stopListening()
            }
        }
        .onDisappear {
            if speechEngine.isRunning {
                speechEngine.stopListening()
            }
        }
        .onChange(of: previewCreation?.title) { _, newTitle in
            if newTitle != nil {
                isSlidingDoorsOpen = false
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
                    withAnimation(.spring(response: 0.22, dampingFraction: 0.82)) {
                        isSlidingDoorsOpen = true
                    }
                }
                HapticFeedback.selection()
            } else {
                isSlidingDoorsOpen = false
            }
        }
    }

    // MARK: - 📁 Universal File Opener
    private func openFileInEditor(_ url: URL) {
        let filename = url.lastPathComponent
        let ext = url.pathExtension.lowercased()
        let isMedia = ["png", "jpg", "jpeg", "gif", "webp", "heic", "svg", "bmp", "tiff", "pdf", "mp4", "mov", "m4v", "mp3", "wav", "m4a", "aac"].contains(ext)
        let content = isMedia ? "" : ((try? String(contentsOf: url, encoding: .utf8)) ?? "")
        withAnimation(.spring(response: 0.38, dampingFraction: 0.84)) {
            self.previewCreation = (title: filename, html: content, fileURL: url)
            self.activeEditorFileURL = url
            self.editorCodeContent = content
            self.isEditorCollapsed = false
            self.windowManager.activeTab = .editor
        }
        NotificationCenter.default.post(
            name: NSNotification.Name("GenieStudioOpenFile"),
            object: url
        )
        NotificationCenter.default.post(
            name: NSNotification.Name("NexusOpenEmbeddedEditor"),
            object: url
        )
    }

    // MARK: - ⚙️ Settings Pane
    private var fileBrowserPane: some View {
        FinderFileBrowserPaneView(
            initialURL: browserURL,
            onNavigate: { browserURL = $0 },
            onOpenFile: { url in openFileInEditor(url) }
        )
    }

    /// Files column: the focused chat render sits above the folder, so the editor is
    /// next to the files it writes and scrolling the chat walks the previews.
    /// The split is proportional and yields entirely to the browser when the pane is
    /// too short to show both without either becoming useless.
    @ViewBuilder
    private func filesColumn(width: CGFloat, height: CGFloat) -> some View {
        if let creation = previewCreation, height >= 360 {
            let previewH = max(200, min(height * 0.58, height - 150))
            VStack(spacing: 0) {
                creationPreviewPane(creation: creation)
                    .frame(width: width, height: previewH)
                    .clipped()

                Divider().opacity(0.35)

                fileBrowserPane
                    .frame(width: width, height: height - previewH - 1)
                    .clipped()
            }
            .frame(width: width, height: height)
        } else if let creation = previewCreation {
            // Too short to split: the render is what the user just scrolled to, so it wins,
            // and the button below hands the column back to the browser.
            VStack(spacing: 0) {
                creationPreviewPane(creation: creation)
                    .frame(width: width, height: height - 30)
                    .clipped()
                Button {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                        previewCreation = nil
                    }
                } label: {
                    Label("Show files", systemImage: "folder")
                        .font(.system(size: 11, weight: .medium))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .frame(height: 30)
            }
            .frame(width: width, height: height)
        } else {
            fileBrowserPane
        }
    }

    /// Base layer of the workspace: chat (optionally split with the creation preview),
    /// or Settings when that's the active tab. Kept separate from `filesDrawerOverlay`
    /// so each is its own small, independently type-checked expression.
    // MARK: - 📑 Primary Multi-Tab Sliding Layout (Files ↔ Editor & Preview ↔ Chat ↔ Apps)
    private var activeAppTab: (bundleId: String, name: String)? {
        if case .app(let bundleId, let name) = windowManager.activeTab.kind {
            return (bundleId, name)
        }
        for tab in windowManager.openTabs.reversed() {
            if case .app(let bundleId, let name) = tab.kind {
                return (bundleId, name)
            }
        }
        return nil
    }

    private var primaryTabIndex: Int {
        switch windowManager.activeTab.kind {
        case .files:
            return 0
        case .editor:
            return 1
        case .chat:
            return 2
        case .app:
            return 3
        default:
            return 2
        }
    }

    private func cyclePrimaryTabs() {
        let nextTab: FinderWindowTab
        switch windowManager.activeTab.kind {
        case .files:
            nextTab = .editor
        case .editor:
            nextTab = .chat
        case .chat:
            if let app = activeAppTab {
                nextTab = .app(bundleId: app.bundleId, name: app.name)
            } else {
                nextTab = .files
            }
        case .app:
            nextTab = .files
        default:
            nextTab = .files
        }
        withAnimation(.spring(response: 0.38, dampingFraction: 0.84)) {
            windowManager.activeTab = nextTab
            HapticFeedback.selection()
        }
    }

    @ViewBuilder
    private func slidingPrimaryTabs(totalW: CGFloat, totalH: CGFloat) -> some View {
        let hasApp = activeAppTab != nil
        let tabCount: CGFloat = hasApp ? 4 : 3
        HStack(spacing: 0) {
            // Tab 0: Files (Apple Finder Miller Columns Browser)
            AppleFinderMillerColumnsBrowserView(
                initialURL: windowManager.activeTab.customURL ?? browserURL,
                liveCreation: previewCreation,
                onSelectFile: { url in
                    browserURL = url
                },
                onOpenFile: { url in
                    openFileInEditor(url)
                }
            )
            .frame(width: totalW, height: totalH)

            // Tab 1: Editor & Shared Previewer (Apple Colorways, Languages, Live HTML/Markdown)
            GenieNativeEditorPreviewerView(
                fileURL: activeEditorFileURL,
                initialCode: editorCodeContent.isEmpty ? nil : editorCodeContent,
                onCodeChange: { newCode in
                    editorCodeContent = newCode
                }
            )
            .frame(width: totalW, height: totalH)

            // Tab 2: Chat Workspace
            chatWorkspaceContent(totalW: totalW, totalH: totalH)
                .frame(width: totalW, height: totalH)

            // Tab 3: Active Application / Program (Slides smoothly alongside chat)
            if let app = activeAppTab {
                LiveAppProgramPaneView(bundleId: app.bundleId, name: app.name)
                    .frame(width: totalW, height: totalH)
            }
        }
        .frame(width: totalW * tabCount, height: totalH, alignment: .leading)
        .offset(x: -CGFloat(primaryTabIndex) * totalW)
        .animation(.spring(response: 0.38, dampingFraction: 0.84), value: primaryTabIndex)
    }

    @ViewBuilder
    private func workspaceBaseContent(totalW: CGFloat, totalH: CGFloat) -> some View {
        switch windowManager.activeTab.kind {
        case .files, .editor, .chat, .app:
            slidingPrimaryTabs(totalW: totalW, totalH: totalH)
        case .settings:
            settingsPane
                .frame(width: totalW, height: totalH)
        case .terminal:
            GeniePremiumTerminalCookbookView()
                .frame(width: totalW, height: totalH)
                .background(Color.black.opacity(0.35))
        case .browser:
            LiveBrowserCradleView()
                .frame(width: totalW, height: totalH)
        case .applications:
            GenieAllApplicationsGridView()
                .frame(width: totalW, height: totalH)
        case .soundAndEffects:
            UnifiedSettingsView(initialTab: .soundAndSmoke, isEmbedded: true)
                .frame(width: totalW, height: totalH)
        case .models:
            UnifiedSettingsView(initialTab: .models, isEmbedded: true)
                .frame(width: totalW, height: totalH)
        case .virtualMachines:
            VirtualMachinesDashboardView()
                .frame(width: totalW, height: totalH)
        case .github:
            GitHubDesktopCanvasView()
                .frame(width: totalW, height: totalH)
        case .notchAndMenuBar:
            UnifiedSettingsView(initialTab: .miniDock, isEmbedded: true)
                .frame(width: totalW, height: totalH)
        case .notes:
            if let creation = previewCreation {
                creationPreviewPane(creation: creation)
                    .frame(width: totalW, height: totalH)
            } else {
                filesColumn(width: totalW, height: totalH)
                    .frame(width: totalW, height: totalH)
            }
        }
    }

    @ViewBuilder
    private func chatWorkspaceContent(totalW: CGFloat, totalH: CGFloat) -> some View {
        if windowManager.isDualHemisphereMode || windowManager.currentSizePreset == .leftHalf || windowManager.currentSizePreset == .thirdsMode {
            // 🌓 Dual Hemisphere Mode: Left Hemisphere = Unfolding Apple Finder Miller Columns + scrollable previews & live rendering,
            // Right Hemisphere = Live Genie Chat Stream & Apple Dock!
            let leftW = max(340, min(totalW - 320, totalW * splitRatio))
            let rightW = max(300, totalW - leftW - 8)
            HStack(spacing: 0) {
                AppleFinderMillerColumnsBrowserView(
                    initialURL: browserURL,
                    liveCreation: previewCreation,
                    onSelectFile: { url in
                        browserURL = url
                    },
                    onOpenFile: { url in
                        openFileInEditor(url)
                    }
                )
                .frame(width: leftW, height: totalH)
                .clipped()

                dividerView(totalWidth: totalW)
                    .frame(width: 8, height: totalH)

                chatPane
                    .frame(width: rightW, height: totalH)
                    .clipped()
            }
            .frame(width: totalW, height: totalH)
        } else if let creation = previewCreation {
            if isEditorCollapsed || totalW < 750 || windowManager.currentSizePreset == .rightHalf {
                // When in right half screen mode: ALWAYS use chat and make the editor slide over to the left!
                HStack(spacing: 0) {
                    collapsedEditorDrawerHandle(title: creation.title)
                        .frame(width: 34, height: totalH)
                        .transition(.move(edge: .leading))

                    chatPane
                        .frame(width: max(280, totalW - 34), height: totalH)
                        .clipped()
                }
                .frame(width: totalW, height: totalH)
            } else {
                let cupSizeW: CGFloat = 280
                let previewW = max(320, totalW - cupSizeW - 8)
                HStack(spacing: 0) {
                    slidingDoorsPreviewPane(creation: creation, width: previewW, height: totalH)
                        .frame(width: previewW, height: totalH)
                        .clipped()
                        .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .leading)))

                    dividerView(totalWidth: totalW)
                        .frame(width: 8, height: totalH)

                    VStack(spacing: 0) {
                        cupSizeChatHeader
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)

                        chatPane
                            .frame(width: cupSizeW, height: max(100, totalH - 42))
                            .clipped()
                    }
                    .frame(width: cupSizeW, height: totalH)
                }
                .frame(width: totalW, height: totalH)
            }
        } else {
            GenieDuoFoldContainerView(editorFileURL: activeEditorFileURL) {
                chatPane
            }
            .frame(width: totalW, height: totalH)
        }
    }

    private var settingsPane: some View {
        UnifiedSettingsView(
            isEmbedded: true,
            onBackToApps: {
                withAnimation(.spring(response: 0.30, dampingFraction: 0.80)) {
                    layoutMode = .chatOnly
                }
            },
            onClose: {
                FinderChatWindowManager.shared.hide()
            }
        )
    }

    // MARK: - 🎨 Creation Interactive Preview Pane
    @ViewBuilder
    private func creationPreviewPane(creation: (title: String, html: String, fileURL: URL?)) -> some View {
        GenieCreationDualTabPreviewView(
            title: creation.title,
            rawHtml: creation.html,
            fileURL: creation.fileURL,
            emotion: currentEmotion,
            onClose: {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                    self.previewCreation = nil
                }
            },
            onCollapse: {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                    self.isEditorCollapsed = true
                }
            }
        )
    }

    // MARK: - 🚪 Sliding Doors Preview Pane & Cup Size Chat
    @ViewBuilder
    private func slidingDoorsPreviewPane(creation: (title: String, html: String, fileURL: URL?), width: CGFloat, height: CGFloat) -> some View {
        let halfW = max(10, width / 2.0)
        ZStack {
            // 1. Live Creation Preview (Inside the Chat)
            creationPreviewPane(creation: creation)
                .frame(width: width, height: height)

            // 2. Sliding Doors (Elevator / Shutter Panels that slide open real quick)
            // Left Door
            HStack(spacing: 0) {
                ZStack(alignment: .trailing) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [Color(white: 0.13).opacity(0.98), Color(white: 0.08).opacity(0.99)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)

                    Rectangle()
                        .fill(LinearGradient(colors: [.cyan, .blue], startPoint: .top, endPoint: .bottom))
                        .frame(width: 2.5)
                        .shadow(color: .cyan.opacity(0.7), radius: 4)

                    Capsule()
                        .fill(Color.white.opacity(0.35))
                        .frame(width: 4, height: 44)
                        .padding(.trailing, 8)
                }
                .frame(width: halfW, height: height)
                .offset(x: isSlidingDoorsOpen ? -halfW : 0)

                Spacer(minLength: 0)
            }

            // Right Door
            HStack(spacing: 0) {
                Spacer(minLength: 0)

                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(
                            LinearGradient(
                                colors: [Color(white: 0.08).opacity(0.99), Color(white: 0.13).opacity(0.98)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)

                    Rectangle()
                        .fill(LinearGradient(colors: [.cyan, .blue], startPoint: .top, endPoint: .bottom))
                        .frame(width: 2.5)
                        .shadow(color: .cyan.opacity(0.7), radius: 4)

                    Capsule()
                        .fill(Color.white.opacity(0.35))
                        .frame(width: 4, height: 44)
                        .padding(.leading, 8)
                }
                .frame(width: halfW, height: height)
                .offset(x: isSlidingDoorsOpen ? halfW : 0)
            }
        }
        .frame(width: width, height: height)
        .clipped()
        .onAppear {
            isSlidingDoorsOpen = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
                withAnimation(.spring(response: 0.22, dampingFraction: 0.82)) {
                    isSlidingDoorsOpen = true
                }
                HapticFeedback.selection()
            }
        }
    }

    @ViewBuilder
    private var cupSizeChatHeader: some View {
        HStack(spacing: 6) {
            Text("☕️")
                .font(.system(size: 13))
            VStack(alignment: .leading, spacing: 1) {
                Text("Cup Size Chat")
                    .font(.system(size: 10.5, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("Reactable Mode")
                    .font(.system(size: 8.5, weight: .semibold, design: .monospaced))
                    .foregroundColor(.cyan)
            }
            Spacer()

            // Reaction buttons
            ForEach(["👍", "❤️", "🚀"], id: \.self) { emoji in
                Button(action: {
                    localModels.chatHistory.append(
                        ChatMessage(role: "user", content: "\(emoji) Reacted to \(previewCreation?.title ?? "file")")
                    )
                    localModels.saveChatHistory()
                    HapticFeedback.success()
                    showStatusFeedback("Reacted \(emoji) to preview!")
                }) {
                    Text(emoji)
                        .font(.system(size: 10))
                        .padding(3)
                        .background(Circle().fill(Color.white.opacity(0.12)))
                }
                .buttonStyle(.plain)
            }

            Button(action: {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                    previewCreation = nil
                }
                HapticFeedback.selection()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.60))
            }
            .buttonStyle(.plain)
            .help("Close Preview and restore full chat (Esc)")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4.5)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.08))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.14), lineWidth: 0.6))
        )
    }

    // MARK: - 🌌 SkyLight Wallpaper Emergence Portal
    @ViewBuilder
    private var skyLightWallpaperEmergenceDrawer: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "sparkles.tv")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.cyan)
                Text("SkyLight Wallpaper Portal")
                    .font(.system(size: 11.5, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Text("Emerging from SkyLight 🌌")
                    .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                    .foregroundColor(.cyan)
                Button(action: {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        showSkyLightWallpaperDrawer = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.top, 8)

            GenieThemeQuickPickerView(selectedTheme: activeThemeBinding) { theme in
                activeThemeRaw = theme.rawValue
                HapticFeedback.selection()
                showStatusFeedback("SkyLight Wallpaper Activated: \(theme.shortTitle) ✨")
            }
            .padding(10)
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.black.opacity(0.88))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            LinearGradient(
                                colors: [Color.cyan.opacity(0.6), Color.purple.opacity(0.4), Color.clear],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.5), radius: 16, y: 8)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .transition(.asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .move(edge: .top).combined(with: .opacity)
        ))
    }

    private func collapsedEditorDrawerHandle(title: String) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                isEditorCollapsed = false
            }
            HapticFeedback.selection()
        }) {
            VStack(spacing: 10) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.cyan)

                Image(systemName: "curlybraces")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))

                Text("Editor")
                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.70))
                    .rotationEffect(.degrees(-90))
                    .fixedSize()
                    .padding(.top, 16)

                Spacer()
            }
            .padding(.top, 16)
            .frame(width: 34, height: .infinity)
            .background(Color.black.opacity(0.48))
            .overlay(
                Rectangle()
                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .help("Slide out Editor / Viewer (⌘\\)")
    }

    // MARK: - 💬 Chat Pane
    private var chatPane: some View {
        ZStack(alignment: .bottom) {
            CompactChatStreamView(emotion: currentEmotion, showHeader: false)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.bottom, sessionArtifacts.isEmpty ? 116 : 156) // Reserve space for floating bottom input, dock & artifacts

            if let creation = previewCreation {
                VStack {
                    HStack(spacing: 8) {
                        Image(systemName: "macwindow.badge.plus")
                            .foregroundColor(.cyan)
                            .font(.system(size: 11, weight: .bold))
                        Text("Preview: \(creation.title)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Spacer()
                        Button(action: {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                                previewCreation = nil
                            }
                            HapticFeedback.selection()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 11, weight: .bold))
                                Text("Close Preview (Esc)")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.red.opacity(0.85)))
                            .overlay(Capsule().strokeBorder(Color.white.opacity(0.35), lineWidth: 0.6))
                        }
                        .buttonStyle(.plain)
                        .help("Dismiss Creation Preview Pane (Esc)")
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.85))
                            .overlay(Capsule().strokeBorder(Color.cyan.opacity(0.50), lineWidth: 0.8))
                    )
                    .padding(.horizontal, 14)
                    .padding(.top, 6)
                    .shadow(color: Color.black.opacity(0.5), radius: 6, y: 2)

                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
                .zIndex(40)
            }

            ChatInlinePreviewTrayView()
                .padding(.bottom, sessionArtifacts.isEmpty ? 126 : 166)

            // Floating Liquid Glass Apple Dock + Input Bar + Dropped File Chips + Artifacts Strip
            VStack(spacing: 6) {
                // Artifacts strip if any artifacts exist
                if !sessionArtifacts.isEmpty {
                    artifactsStripRow
                }

                if !droppedAttachments.isEmpty {
                    attachmentChipsRow
                }
                
                // Mirrored Liquid Glass Mini Dock with running indicators, quick navigation, and folder stacks
                if isAppleDockVisible {
                    LiquidGlassMiniDockView(isPresented: .constant(true))
                        .zIndex(20)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                // 🧠 Live AI Model Selector & Unified Memory (RAM) Telemetry Bar
                GenieChatModelAndRAMBar()

                floatingBottomInputCapsule
            }
            .padding(.horizontal, isEmbedded ? 8 : 14)
            .padding(.bottom, 10)

            if isChatDropTargeted {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.85), style: StrokeStyle(lineWidth: 2, dash: [8, 6]))
                    .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color.white.opacity(0.08)))
                    .overlay(
                        Label("Drop to attach", systemImage: "tray.and.arrow.down.fill")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                    )
                    .padding(10)
                    .allowsHitTesting(false)
                    .transition(.opacity)
            }

            if isFilesTrayOpen {
                filesTray
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }

            if showQuickCreationSheet {
                quickCreationOverlay
            }
        }
        .onDrop(of: [.fileURL, .url, .item, .data, .image, .plainText], isTargeted: $isChatDropTargeted) { providers in
            handleChatFileDrop(providers)
        }
    }

    // MARK: - 📁 Slide-Up Files Tray (opened from the chat "+" menu)
    private var filesTray: some View {
        VStack(spacing: 0) {
            HStack {
                Capsule()
                    .fill(Color.white.opacity(0.30))
                    .frame(width: 36, height: 4)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
            .padding(.bottom, 4)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 8)
                    .onEnded { value in
                        if value.translation.height > 40 {
                            withAnimation(.spring(response: 0.30, dampingFraction: 0.85)) {
                                isFilesTrayOpen = false
                            }
                        }
                    }
            )

            HStack {
                Label("Files", systemImage: "folder.fill")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
                Spacer()
                Button {
                    withAnimation(.spring(response: 0.30, dampingFraction: 0.85)) {
                        isFilesTrayOpen = false
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 8)

            fileBrowserPane
        }
        .frame(maxWidth: .infinity)
        .frame(height: 340)
        .background(
            ZStack {
                VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow, state: .active)
                Color.black.opacity(0.55)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.4), radius: 16, x: 0, y: -4)
        .padding(.horizontal, 10)
        .padding(.bottom, 64)
    }

    // MARK: - 📎 Smart File Attachment Chips
    private var attachmentChipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(droppedAttachments, id: \.self) { url in
                    let info = GenieFileContentLoader.shared.chipIconInfo(for: url)
                    let sizeStr = GenieFileContentLoader.shared.formattedFileSize(for: url)

                    HStack(spacing: 6) {
                        let isImg = ["jpg", "jpeg", "gif", "png", "webp", "heic"].contains(url.pathExtension.lowercased())
                        if isImg, let img = NSImage(contentsOf: url) {
                            Image(nsImage: img)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 20, height: 20)
                                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.white.opacity(0.3), lineWidth: 0.5))
                        } else {
                            Image(systemName: info.icon)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(info.color)
                        }

                        VStack(alignment: .leading, spacing: 1) {
                            Text(url.lastPathComponent)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(.white)
                                .lineLimit(1)

                            if !sizeStr.isEmpty {
                                Text(sizeStr)
                                    .font(.system(size: 8.5, weight: .regular, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.50))
                            }
                        }

                        Button(action: {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                droppedAttachments.removeAll { $0 == url }
                            }
                            HapticFeedback.tick()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.60))
                        }
                        .buttonStyle(.plain)
                        .help("Remove Attachment")
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(0.12))
                            .overlay(Capsule().strokeBorder(info.color.opacity(0.35), lineWidth: 0.75))
                    )
                }
            }
            .padding(.horizontal, 2)
        }
    }

    // MARK: - 🎨 Always-Visible Session Artifacts Strip
    private var artifactsStripRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(sessionArtifacts.indices, id: \.self) { idx in
                    let artifact = sessionArtifacts[idx]
                    let isSelected = previewCreation?.title == artifact.title

                    HStack(spacing: 6) {
                        Image(systemName: artifact.fileURL != nil ? "doc.richtext.fill" : "sparkles.rectangle.stack.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(isSelected ? Color.cyan : Color.white.opacity(0.8))

                        Text(artifact.title)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .frame(maxWidth: 140, alignment: .leading)

                        // Open / Hide Preview in Split View
                        Button(action: {
                            withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                                if previewCreation?.title == artifact.title {
                                    previewCreation = nil
                                } else {
                                    previewCreation = artifact
                                }
                            }
                            HapticFeedback.selection()
                        }) {
                            Image(systemName: isSelected ? "eye.slash.fill" : "eye.fill")
                                .font(.system(size: 10))
                                .foregroundColor(isSelected ? Color.cyan : Color.white.opacity(0.60))
                        }
                        .buttonStyle(.plain)
                        .help(isSelected ? "Hide Preview" : "Preview in Split View")

                        // Enter into Chat
                        Button(action: {
                            LocalModelManager.shared.chatHistory.append(
                                ChatMessage(role: "user", content: "Rendered HTML artifact [\(artifact.title)]:\n```html\n\(artifact.html)\n```")
                            )
                            showStatusFeedback("Entered [\(artifact.title)] into Chat! 🚀")
                            HapticFeedback.success()
                        }) {
                            Image(systemName: "arrow.turn.down.left")
                                .font(.system(size: 9.5, weight: .bold))
                                .foregroundColor(.white.opacity(0.60))
                        }
                        .buttonStyle(.plain)
                        .help("Enter into Chat Stream")

                        // Dismiss Artifact
                        Button(action: {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                if previewCreation?.title == artifact.title {
                                    previewCreation = nil
                                }
                                sessionArtifacts.remove(at: idx)
                            }
                            HapticFeedback.tick()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white.opacity(0.45))
                        }
                        .buttonStyle(.plain)
                        .help("Dismiss Artifact")
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(isSelected ? Color.cyan.opacity(0.18) : Color.white.opacity(0.08))
                            .overlay(
                                Capsule().strokeBorder(
                                    isSelected ? Color.cyan.opacity(0.65) : Color.white.opacity(0.14),
                                    lineWidth: 0.75
                                )
                            )
                    )
                }
            }
            .padding(.horizontal, 2)
        }
    }

    // MARK: - 🧞‍♂️ Interactive Animated Genie Magic & Shortcuts Row
    private var shortcutHintsRow: some View {
        HStack(spacing: 4) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    HStack(spacing: 4) {
                        GenieFuturisticSmokeIconView(size: 13, isGlowing: true, showSmokeAnimation: true, isProcessing: localModels.isGenerating)
                        Text("GENIE MAGIC:")
                            .font(.system(size: 8.5, weight: .black, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.cyan, Color(red: 0.75, green: 0.50, blue: 1.0)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                    .padding(.leading, 2)

                    shortcutPill(title: "/settings", icon: "gearshape.fill", color: .purple) {
                        executeSlashCommand("/settings")
                    }

                    shortcutPill(title: "/finder", icon: "folder.fill", color: .blue) {
                        executeSlashCommand("/finder")
                    }

                    shortcutPill(title: "/editor", icon: "macwindow", color: .cyan) {
                        executeSlashCommand("/editor")
                    }

                    shortcutPill(title: "/chat", icon: "bubble.left.and.bubble.right.fill", color: .indigo) {
                        executeSlashCommand("/chat")
                    }

                    shortcutPill(title: "/terminal", icon: "terminal.fill", color: .green) {
                        executeSlashCommand("/terminal")
                    }

                    shortcutPill(title: "/tail", icon: "doc.text.magnifyingglass", color: .yellow) {
                        executeSlashCommand("/tail")
                    }

                    shortcutPill(title: "/browser", icon: "globe", color: .teal) {
                        executeSlashCommand("/browser")
                    }

                    shortcutPill(title: "/apps", icon: "square.grid.2x2.fill", color: .orange) {
                        executeSlashCommand("/apps")
                    }

                    shortcutPill(title: "/github", icon: "arrow.triangle.branch", color: .purple) {
                        executeSlashCommand("/github")
                    }

                    shortcutPill(title: "open Safari", icon: "safari.fill", color: .blue) {
                        executeSlashCommand("open Safari")
                    }

                    shortcutPill(title: "/clear", icon: "trash", color: .red) {
                        executeSlashCommand("/clear")
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 1)
            }

            // Close / Hide Hints button
            Button(action: {
                HapticFeedback.selection()
                withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                    showShortcutHints = false
                    isHintsHovered = false
                    isHintsRowHovered = false
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.35))
                    .padding(3)
            }
            .buttonStyle(.plain)
            .help("Hide Genie Magic & Shortcuts")
        }
    }

    private func shortcutPill(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 9))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 3.5)
            .background(Capsule().fill(Color.white.opacity(0.06)))
            .overlay(Capsule().strokeBorder(color.opacity(0.30), lineWidth: 0.5))
        }
        .buttonStyle(GenieMagneticButtonStyle(scale: 1.08))
    }

    private func handleChatFileDrop(_ providers: [NSItemProvider]) -> Bool {
        var didAccept = false
        let supportedTypes = [
            UTType.fileURL.identifier,
            UTType.url.identifier,
            UTType.item.identifier,
            UTType.data.identifier,
            UTType.image.identifier,
            UTType.utf8PlainText.identifier
        ]

        for provider in providers {
            for typeIdentifier in supportedTypes {
                if provider.hasItemConformingToTypeIdentifier(typeIdentifier) {
                    didAccept = true
                    provider.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { item, _ in
                        var resolvedURL: URL? = nil
                        if let url = item as? URL {
                            resolvedURL = url
                        } else if let nsurl = item as? NSURL {
                            resolvedURL = nsurl as URL
                        } else if let data = item as? Data {
                            resolvedURL = URL(dataRepresentation: data, relativeTo: nil)
                            if resolvedURL == nil, let pathStr = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), pathStr.hasPrefix("/") || pathStr.hasPrefix("file://") {
                                resolvedURL = URL(string: pathStr) ?? URL(fileURLWithPath: pathStr)
                            }
                        } else if let text = item as? String {
                            let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
                            if clean.hasPrefix("/") || clean.hasPrefix("file://") {
                                resolvedURL = URL(string: clean) ?? URL(fileURLWithPath: clean)
                            }
                        }

                        if let validURL = resolvedURL {
                            DispatchQueue.main.async {
                                if !self.droppedAttachments.contains(validURL) {
                                    self.droppedAttachments.append(validURL)
                                    HapticFeedback.success()
                                }
                            }
                        }
                    }
                    break
                }
            }
        }
        if didAccept { HapticFeedback.selection() }
        return didAccept
    }

    // MARK: - 📏 Resizable Glass Split Divider
    private func dividerView(totalWidth: CGFloat) -> some View {
        ZStack {
            Rectangle()
                .fill(LinearGradient(
                    colors: [
                        Color.white.opacity(0.18),
                        Color.white.opacity(0.06),
                        Color.white.opacity(0.18)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                ))
                .frame(width: 1)

            // Interactive Collapse Button Right on the Divider
            Button(action: {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                    isEditorCollapsed.toggle()
                }
                HapticFeedback.selection()
            }) {
                Image(systemName: isEditorCollapsed ? "chevron.right" : "chevron.left")
                    .font(.system(size: 7.5, weight: .bold))
                    .foregroundColor(.white)
                    .frame(width: 14, height: 26)
                    .background(Capsule().fill(Color.black.opacity(0.70)))
                    .overlay(Capsule().strokeBorder(Color.white.opacity(0.35), lineWidth: 0.5))
            }
            .buttonStyle(.plain)
            .help(isEditorCollapsed ? "Slide Out Editor (⌘\\)" : "Slide In / Hide Editor (⌘\\)")

            Color.clear
                .frame(width: 14)
                .contentShape(Rectangle())
                .onHover { inside in
                    if inside { NSCursor.resizeLeftRight.push() } else { NSCursor.pop() }
                }
                .gesture(
                    DragGesture(minimumDistance: 1)
                        .onChanged { val in
                            isDraggingDivider = true
                            let start = dragStartWidth ?? FinderWorkspaceLayout.browserWidth(totalWidth: totalWidth, ratio: splitRatio)
                            dragStartWidth = start
                            splitRatio = FinderWorkspaceLayout.ratio(totalWidth: totalWidth, startWidth: start, translation: val.translation.width)
                        }
                        .onEnded { _ in
                            isDraggingDivider = false
                            dragStartWidth = nil
                        }
                )
                .simultaneousGesture(
                    TapGesture(count: 2).onEnded {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                            splitRatio = 0.54
                        }
                    }
                )
        }
    }

    // MARK: - 🫧 Floating Bubbly Header Bar (Borderless & Glass Polymorphic)
    private var floatingHeaderBar: some View {
        HStack(spacing: 6) {
            // Traffic lights: strictly suppressed when embedded to prevent duplicate window controls
            if !isEmbedded {
                HStack(spacing: 4) {
                    windowControl("Close Window", color: .red, icon: "xmark") {
                        windowManager.hide()
                    }
                    .keyboardShortcut("w", modifiers: .command)

                    windowControl("Minimize Window", color: .yellow, icon: "minus") {
                        windowManager.minimize()
                    }
                    .keyboardShortcut("m", modifiers: .command)

                    windowControl("Expand / Restore Window", color: .green, icon: "arrow.up.left.and.arrow.down.right") {
                        windowManager.togglePresentationForm()
                    }
                    .contextMenu {
                        Button(action: { windowManager.slideDownFullScreen() }) {
                            Label("Slide-Down Full Screen (⌥⌘↑)", systemImage: "arrow.down.to.line.compact")
                        }
                        Button(action: { windowManager.showInDesktopForm() }) {
                            Label("Desktop Window Form (⌥⌘↓)", systemImage: "macwindow")
                        }
                        Divider()
                        ForEach(FinderWindowSizePreset.allCases) { preset in
                            Button(action: {
                                windowManager.snapTo(preset: preset)
                            }) {
                                Label(
                                    windowManager.currentSizePreset == preset ? "\(preset.rawValue) ✓" : preset.rawValue,
                                    systemImage: preset.icon
                                )
                            }
                        }
                    }
                }
                .padding(.leading, 8)
            }

            // 🧞‍♂️ Genie Cycle Switcher Button (Files ➔ Editor & Preview ➔ Chat) + Master Dropdown
            genieCycleAndMasterControl

            // 📑 3-Tab Sliding Pill [ 📁 Files | 📝 Editor & Preview | 💬 Chat ]
            threeTabSlidingPill

            // 🕒 In-Chat Widgets Toggle Button
            Button(action: {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                    showInChatWidgets.toggle()
                }
                HapticFeedback.selection()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: showInChatWidgets ? "clock.fill" : "clock")
                        .font(.system(size: 11, weight: .bold))
                    Text("Widgets")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                }
                .foregroundColor(showInChatWidgets ? .cyan : .white.opacity(0.80))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(showInChatWidgets ? Color.cyan.opacity(0.20) : Color.white.opacity(0.08)))
                .overlay(Capsule().strokeBorder(showInChatWidgets ? Color.cyan.opacity(0.45) : Color.white.opacity(0.12), lineWidth: 0.6))
            }
            .buttonStyle(.plain)
            .help("Toggle In-Chat World Clock & Widgets")

            // 🔄 Slide-Down / Desktop Presentation Switcher (only for top-level window)
            if !isEmbedded {
                presentationSwitcherControls
            }

            if isTopRibbonVisible {
                headerTabsGroup
                    .layoutPriority(1)
                    .transition(.move(edge: .leading).combined(with: .opacity))
            }

            Spacer(minLength: 2)

            // ⚡ Real-Time Token Generation Telemetry (tkps)
            if localModels.lastTokensPerSecond > 0 || localModels.isGenerating {
                HStack(spacing: 3) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 7.5, weight: .bold))
                        .foregroundColor(localModels.isGenerating ? .yellow : .cyan)
                    Text(String(format: "%.1f tkps", localModels.lastTokensPerSecond))
                        .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                        .foregroundColor(localModels.isGenerating ? .yellow : .white.opacity(0.90))
                }
                .padding(.horizontal, 5)
                .padding(.vertical, 3)
                .background(Capsule().fill(Color.white.opacity(0.08)))
                .overlay(Capsule().stroke(Color.white.opacity(0.14), lineWidth: 0.5))
                .help("Token generation speed: \(String(format: "%.1f", localModels.lastTokensPerSecond)) tokens per second")
                .fixedSize()
            }

            // Compact Search Capsule with live instant results popover
            HStack(spacing: 4) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 8.5))
                    .foregroundColor(.white.opacity(0.55))
                TextField("Search files, apps...", text: $topSearchText)
                    .font(.system(size: 9.5, design: .default))
                    .textFieldStyle(.plain)
                    .foregroundColor(.white)
                    .frame(maxWidth: topSearchText.isEmpty ? 70 : 130)
                    .animation(.easeInOut(duration: 0.18), value: topSearchText.isEmpty)
                    .onChange(of: topSearchText) { _, newVal in
                        updateTopSearch(query: newVal)
                    }
                    .onSubmit {
                        executeTopSearchSubmit()
                    }
                if !topSearchText.isEmpty {
                    Button(action: {
                        topSearchText = ""
                        isTopSearchPopoverPresented = false
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 8))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Capsule().fill(Color.white.opacity(0.06)))
            .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.5))
            .fixedSize()
            .popover(isPresented: $isTopSearchPopoverPresented, arrowEdge: .bottom) {
                topSearchDropdownContent
            }

            // 🎛️ Merged Header Settings Strip (Living Liquid Gear & Quick Controls)
            headerQuickSettingsStrip

            // Quick Model Selector
            modelQuickSwitcher
                .frame(maxWidth: 120, alignment: .trailing)
        }
        .frame(height: 32)
        .padding(.trailing, 6)
        .environment(\.colorScheme, .dark)
    }

    // MARK: - 🧞‍♂️ Genie Cycle & Master Menu Control Hub
    private var genieCycleAndMasterControl: some View {
        HStack(spacing: 0) {
            // Left button: click to cycle tabs (Files ➔ Editor & Preview ➔ Chat ➔ Files)
            Button(action: {
                cyclePrimaryTabs()
            }) {
                HStack(spacing: 4.5) {
                    GenieFuturisticSmokeIconView(
                        size: 14,
                        isGlowing: true,
                        showSmokeAnimation: true,
                        isProcessing: localModels.isGenerating
                    )

                    Text(localModels.isGenerating ? "Processing..." : "Genie")
                        .font(.system(size: 11.5, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.white, Color.white.opacity(0.90)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 7.5, weight: .bold))
                        .foregroundColor(.cyan.opacity(0.85))
                }
                .padding(.leading, 7)
                .padding(.trailing, 4)
                .padding(.vertical, 3.5)
            }
            .buttonStyle(.plain)
            .help("Genie Switcher: Click to cycle tabs (Files ➔ Editor & Preview ➔ Chat)")

            // Right button: Master Dropdown menu
            Menu {
                genieMasterDropdownMenuContent
            } label: {
                Image(systemName: "chevron.down")
                    .font(.system(size: 7.5, weight: .black))
                    .foregroundColor(.white.opacity(0.60))
                    .padding(.leading, 2)
                    .padding(.trailing, 7)
                    .padding(.vertical, 3.5)
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .help("Genie Master Menu — Tabs, Studios, File Permissions, Themes & AI")
        }
        .background(
            Capsule()
                .fill(Color.white.opacity(0.10))
        )
        .overlay(
            Capsule()
                .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.6)
        )
        .contextMenu {
            genieMasterDropdownMenuContent
        }
    }

    // MARK: - 🔍 Top Search Live Results Dropdown
    private var topSearchDropdownContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.cyan)
                    .font(.system(size: 11, weight: .bold))
                Text("Search \"\(topSearchText)\"")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Button(action: { isTopSearchPopoverPresented = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 2)

            // Applications Section
            if !topSearchResultsApps.isEmpty {
                Text("APPLICATIONS")
                    .font(.system(size: 8.5, weight: .bold))
                    .foregroundColor(.white.opacity(0.55))
                ForEach(topSearchResultsApps, id: \.id) { app in
                    Button(action: {
                        isTopSearchPopoverPresented = false
                        let bid = app.bundleIdentifier ?? app.id
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.84)) {
                            windowManager.openProgram(bundleId: bid, name: app.name)
                        }
                        topSearchText = ""
                    }) {
                        HStack(spacing: 8) {
                            if let icon = app.icon {
                                Image(nsImage: icon)
                                    .resizable()
                                    .frame(width: 18, height: 18)
                            } else {
                                Image(systemName: "app.fill")
                                    .font(.system(size: 14))
                                    .frame(width: 18, height: 18)
                            }
                            Text(app.name)
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white)
                            Spacer()
                            Text("Open Tab ➔")
                                .font(.system(size: 8.5, weight: .semibold))
                                .foregroundColor(.cyan)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 6)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.06)))
                    }
                    .buttonStyle(.plain)
                }
            }

            // Files Section
            if !topSearchResultsFiles.isEmpty {
                Text("FILES & DOCUMENTS")
                    .font(.system(size: 8.5, weight: .bold))
                    .foregroundColor(.white.opacity(0.55))
                ForEach(topSearchResultsFiles.prefix(4)) { file in
                    Button(action: {
                        isTopSearchPopoverPresented = false
                        openFileInEditor(URL(fileURLWithPath: file.path))
                        topSearchText = ""
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: file.isDirectory ? "folder.fill" : "doc.text.fill")
                                .foregroundColor(file.isDirectory ? .blue : .teal)
                                .font(.system(size: 12))
                            VStack(alignment: .leading, spacing: 1) {
                                Text(file.name)
                                    .font(.system(size: 10.5, weight: .medium))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                Text(file.path)
                                    .font(.system(size: 8))
                                    .foregroundColor(.white.opacity(0.5))
                                    .lineLimit(1)
                            }
                            Spacer()
                            Text(file.formattedSize)
                                .font(.system(size: 8.5))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 6)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.06)))
                    }
                    .buttonStyle(.plain)
                }
            }

            Divider().opacity(0.3)

            // Ask Genie in Chat Button
            Button(action: {
                executeTopSearchSubmit()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.yellow)
                        .font(.system(size: 11))
                    Text("Ask Genie \"\(topSearchText)\" in Chat")
                        .font(.system(size: 10.5, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Text("↵ Return")
                        .font(.system(size: 8.5, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.vertical, 5)
                .padding(.horizontal, 6)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.cyan.opacity(0.22)))
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .frame(width: 290)
        .background(VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow, state: .active))
    }

    // MARK: - 📑 Multi-Tab Sliding Pill
    private var threeTabSlidingPill: some View {
        HStack(spacing: 2) {
            slidingPillItem(title: "Files", icon: "folder.fill", index: 0, tab: .files)
            slidingPillItem(title: "Editor & Preview", icon: "chevron.left.forwardslash.chevron.right", index: 1, tab: .editor)
            slidingPillItem(title: "Chat", icon: "bubble.left.and.bubble.right.fill", index: 2, tab: .chat)
            if let app = activeAppTab {
                slidingPillItem(title: app.name, icon: "macwindow", index: 3, tab: .app(bundleId: app.bundleId, name: app.name))
            }
        }
        .padding(2)
        .background(Capsule().fill(Color.black.opacity(0.35)))
        .overlay(Capsule().strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5))
    }

    private func slidingPillItem(title: String, icon: String, index: Int, tab: FinderWindowTab) -> some View {
        let isSelected = primaryTabIndex == index
        return Button(action: {
            withAnimation(.spring(response: 0.38, dampingFraction: 0.84)) {
                windowManager.activeTab = tab
                HapticFeedback.selection()
            }
        }) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 9.5, weight: isSelected ? .bold : .regular))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.60))
                Text(title)
                    .font(.system(size: 10.5, weight: isSelected ? .semibold : .regular, design: .rounded))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.70))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3.5)
            .background(
                Group {
                    if isSelected {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.22), Color.white.opacity(0.12)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .overlay(Capsule().strokeBorder(Color.white.opacity(0.28), lineWidth: 0.6))
                            .shadow(color: Color.black.opacity(0.25), radius: 2, y: 1)
                    } else {
                        Color.clear
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 🧞‍♂️ Genie Master Dropdown Menu Content
    @ViewBuilder
    private var genieMasterDropdownMenuContent: some View {
        // Section 1: Workspaces & Creation Tabs
        Section("Tabs & Workspaces") {
            Button(action: { windowManager.newChatTab() }) {
                Label("New Genie Chat", systemImage: "bubble.left.and.bubble.right.fill")
            }
            .keyboardShortcut("t", modifiers: .command)

            Button(action: { windowManager.newEditorTab() }) {
                Label("New Editor & Preview", systemImage: "macwindow")
            }
            .keyboardShortcut("e", modifiers: .command)

            Button(action: { windowManager.newFinderTab() }) {
                Label("New Finder Tab", systemImage: "folder.fill")
            }
            .keyboardShortcut("n", modifiers: .command)

            Button(action: { windowManager.openTab(.terminal) }) {
                Label("Terminal Studio", systemImage: "terminal.fill")
            }

            Button(action: { windowManager.openTab(.browser) }) {
                Label("Mini Browser", systemImage: "globe")
            }

            Button(action: { windowManager.openTab(.github) }) {
                Label("GitHub Studio", systemImage: "arrow.triangle.branch")
            }
        }

        // Section 2: Window Snapping & Formations
        Section("Window Snapping & Formations") {
            ForEach(FinderWindowSizePreset.allCases) { preset in
                Button(action: {
                    windowManager.snapTo(preset: preset)
                }) {
                    Label(
                        windowManager.currentSizePreset == preset ? "\(preset.rawValue) ✓" : preset.rawValue,
                        systemImage: preset.icon
                    )
                }
            }
        }

        // Section 2b: Chat Presentation Form
        Section("Chat Presentation Form") {
            Button(action: { windowManager.slideDownFullScreen() }) {
                Label(
                    windowManager.isSlideDownFullScreen ? "Slide-Down Full Screen ✓ (⌥⌘↑)" : "Slide-Down Full Screen (⌥⌘↑)",
                    systemImage: "arrow.down.to.line.compact"
                )
            }
            Button(action: { windowManager.showInDesktopForm() }) {
                Label(
                    !windowManager.isSlideDownFullScreen ? "Desktop Window Form ✓ (⌥⌘↓)" : "Desktop Window Form (⌥⌘↓)",
                    systemImage: "macwindow"
                )
            }
        }

        // Section 3: Top Notch & Screen Clearance
        Section("Top Notch & Screen Clearance") {
            Button(action: {
                notchClearanceMode.toggle()
                UserDefaults.standard.set(notchClearanceMode, forKey: PrefKey.notchClearanceMode)
                HapticFeedback.selection()
            }) {
                Label(
                    notchClearanceMode ? "Notch Clearance: Active ✓" : "Notch Clearance: Off",
                    systemImage: "laptopcomputer.and.ipad"
                )
            }

            Button(action: {
                windowManager.openTab(.notchAndMenuBar)
            }) {
                Label(
                    GenieSystemAppearanceDetector.shared.hasNotch
                        ? "Notch Hardware (\(Int(GenieSystemAppearanceDetector.shared.notchWidth)) × \(Int(GenieSystemAppearanceDetector.shared.notchTopInset)) pt)..."
                        : "Top Notch & Menu Bar Studio...",
                    systemImage: "menubar.rectangle"
                )
            }
        }

        // Section 4: Genie Studios
        Section("Genie Studios") {
            Button(action: { windowManager.openTab(.applications) }) {
                Label("Applications Atelier", systemImage: "square.grid.2x2.fill")
            }
            Button(action: { windowManager.openTab(.soundAndEffects) }) {
                Label("Sound & Effects", systemImage: "speaker.wave.2.fill")
            }
            Button(action: { windowManager.openTab(.models) }) {
                Label("Models & Providers", systemImage: "brain.head.profile")
            }
            Button(action: { windowManager.openTab(.virtualMachines) }) {
                Label("AI Stations & VMs", systemImage: "server.rack")
            }
            Button(action: { windowManager.openTab(.settings) }) {
                Label("Settings & Preferences (⌘,)", systemImage: "gearshape.fill")
            }
            .keyboardShortcut(",", modifiers: .command)
        }

        // Section 5: Restricted File Governance
        Section("File Governance (Restricted)") {
            Button(action: {
                windowManager.openTab(.settings)
            }) {
                Label("Sandbox: Restricted 🛡️ (Folder Permissions...)", systemImage: "lock.shield.fill")
            }
        }

        // Section 6: Living Atelier Themes
        Section("Atelier Themes & Appearance") {
            ForEach(GenieTheme.allCases) { theme in
                Button(action: {
                    activeThemeRaw = theme.rawValue
                    HapticFeedback.selection()
                }) {
                    Label(
                        activeTheme == theme ? "\(theme.shortTitle) ✓" : theme.shortTitle,
                        systemImage: theme.icon
                    )
                }
            }

            Button(action: {
                SkyLightZenOverlayManager.shared.toggle()
                HapticFeedback.selection()
            }) {
                Label(
                    SkyLightZenOverlayManager.shared.isOverlayActive || isZenModeEnabled ? "Zen Mode Overlay (⌥⌘Z): Active ✓" : "Zen Mode Overlay (⌥⌘Z): Off",
                    systemImage: "leaf.fill"
                )
            }
        }

        // Section 7: AI Intelligence Model Selector
        Section("AI Intelligence Model") {
            ForEach(LocalModelManager.cloudModels) { model in
                Button(action: { localModels.selectModel(model.id) }) {
                    Label(
                        localModels.effectiveModel == model.id ? "\(model.displayName) ✓" : model.displayName,
                        systemImage: "sparkles"
                    )
                }
            }
        }

        // Section 8: macOS Applications & Running Tasks
        if !DockAndDesktopManager.shared.dockItems.isEmpty {
            Section("macOS Applications") {
                ForEach(DockAndDesktopManager.shared.dockItems) { item in
                    Button(action: {
                        if let bundleId = item.bundleIdentifier {
                            windowManager.openProgram(bundleId: bundleId, name: item.name)
                        } else {
                            windowManager.openProgram(bundleId: item.id, name: item.name)
                        }
                    }) {
                        Label(
                            item.isRunning ? "\(item.name) (Active)" : item.name,
                            systemImage: item.isRunning ? "app.window.checkmark" : "app"
                        )
                    }
                }
            }
        }
    }

    private var headerTabsGroup: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                // Open Tabs (excluding primary 3 already in pill)
                let extraTabs = windowManager.openTabs.filter { $0.kind != .files && $0.kind != .editor && $0.kind != .chat }
                ForEach(extraTabs) { tab in
                    headerTabItem(tab: tab)
                }

                // New Tab Menu (+)
                Menu {
                    Section("New Tab") {
                        Button(action: { windowManager.newChatTab() }) {
                            Label("New Chat Tab", systemImage: "bubble.left.and.bubble.right.fill")
                        }
                        .keyboardShortcut("t", modifiers: .command)

                        Button(action: { windowManager.newFinderTab() }) {
                            Label("New Finder Tab", systemImage: "folder.fill")
                        }
                        .keyboardShortcut("n", modifiers: .command)

                        Button(action: { windowManager.newEditorTab() }) {
                            Label("New Editor & Preview Tab", systemImage: "macwindow")
                        }
                        .keyboardShortcut("e", modifiers: .command)

                        Button(action: { windowManager.openTab(.terminal) }) {
                            Label("Terminal Studio", systemImage: "terminal.fill")
                        }

                        Button(action: { windowManager.openTab(.browser) }) {
                            Label("Mini Browser", systemImage: "globe")
                        }
                    }

                    Section("Genie Studios & Tools") {
                        Button(action: { windowManager.openTab(.applications) }) {
                            Label("Applications", systemImage: "square.grid.2x2.fill")
                        }
                        Button(action: { windowManager.openTab(.soundAndEffects) }) {
                            Label("Sound & Effects", systemImage: "speaker.wave.2.fill")
                        }
                        Button(action: { windowManager.openTab(.models) }) {
                            Label("Models & Providers", systemImage: "brain.head.profile")
                        }
                        Button(action: { windowManager.openTab(.virtualMachines) }) {
                            Label("AI Stations & VMs", systemImage: "server.rack")
                        }
                        Button(action: { windowManager.openTab(.notchAndMenuBar) }) {
                            Label("Top Notch & Menu Bar", systemImage: "menubar.rectangle")
                        }
                        Button(action: { windowManager.openTab(.settings) }) {
                            Label("Settings...", systemImage: "gearshape.fill")
                        }
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white.opacity(0.75))
                        .frame(width: 20, height: 20)
                        .background(Circle().fill(Color.white.opacity(0.08)))
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()
                .help("New Tab (⌘T for Chat, ⌘N for Finder, ⌘E for Editor)")
            }
            .padding(2)
        }
        .background(
            Capsule()
                .fill(Color.white.opacity(0.08))
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5))
        )
    }

    private func headerTabItem(tab: FinderWindowTab) -> some View {
        let isSelected = (windowManager.activeTab.id == tab.id)
        return HStack(spacing: 3) {
            Button {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                    windowManager.activeTab = tab
                    if let sessId = tab.sessionId {
                        if let s = LocalModelManager.shared.savedSessions.first(where: { $0.id == sessId }) {
                            LocalModelManager.shared.loadSession(s)
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: tab.icon)
                        .font(.system(size: 9.5))
                    Text(tab.title)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .frame(maxWidth: 120, alignment: .leading)
                .foregroundColor(isSelected ? .white : .white.opacity(0.65))
            }
            .buttonStyle(.plain)

            if windowManager.openTabs.count > 1 {
                Button(action: {
                    withAnimation(.spring(response: 0.24, dampingFraction: 0.82)) {
                        windowManager.closeTab(tab)
                    }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 6, weight: .bold))
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .white.opacity(0.4))
                }
                .buttonStyle(.plain)
                .help("Close Tab")
            }
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            Capsule()
                .fill(isSelected ? Color.white.opacity(0.20) : Color.clear)
        )
        .help("Switch to \(tab.title)")
    }

    /// Genie-branded Settings entry point, next to the "+" tools menu in the chat
    /// input bar — with 2028 Apple Liquid Water & ripple effects.
    private var genieSettingsButton: some View {
        Genie2028LiquidSettingsIcon(
            size: 26,
            isActive: windowManager.activeTab.kind == .settings,
            action: {
                withAnimation(.spring(response: 0.30, dampingFraction: 0.80)) {
                    if windowManager.activeTab.kind == .settings {
                        windowManager.activeTab = .chat
                    } else {
                        windowManager.openTab(.settings)
                    }
                }
            }
        )
        .fixedSize()
        .help(windowManager.activeTab.kind == .settings ? "Back to Chat" : "Genie Liquid Settings (⌘,)")
        .accessibilityLabel("Genie Settings")
    }

    private func windowControl(_ title: String, color: Color, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 7, weight: .bold))
                .foregroundStyle(.black.opacity(0.7))
                .frame(width: 13, height: 13)
                .background(color, in: Circle())
                .frame(width: 20, height: 26)
                .contentShape(Rectangle())
        }
        .buttonStyle(GenieMagneticButtonStyle(scale: 1.22))
        .help(title)
        .accessibilityLabel(title)
    }

    private var modelQuickSwitcher: some View {
            Menu {
                ForEach(LocalModelManager.cloudModels) { model in
                    Button(action: { localModels.selectModel(model.id) }) {
                        Text(localModels.effectiveModel == model.id ? "\(model.displayName) ✓" : model.displayName)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "cpu")
                        .font(.system(size: 9))
                    Text(localModels.selectedModelDisplayName)
                        .font(.system(size: 10.5, weight: .medium, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .truncationMode(.middle)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 7, weight: .bold))
                        .opacity(0.6)
                }
                .foregroundColor(.white.opacity(0.85))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.white.opacity(0.08)))
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.14), lineWidth: 0.6))
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .help("Choose Model")
            .accessibilityLabel("Choose Model")
    }

    // MARK: - 🫧 Focused Pillow White 2028 Chat Input Capsule
    private var floatingBottomInputCapsule: some View {
        HStack(spacing: 8) {
            // ➕ Consolidated Tools & Actions Menu
            Menu {
                Section("Files & Creation") {
                    Button {
                        openFilePicker()
                    } label: {
                        Label("Attach Files or Code... (⌘O)", systemImage: "paperclip")
                    }

                    Button {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                            showQuickCreationSheet.toggle()
                        }
                    } label: {
                        Label("New Project or File... (⌘N)", systemImage: "plus.square.dashed")
                    }

                    Button {
                        openDirectoryPicker()
                    } label: {
                        Label("Open Directory...", systemImage: "folder.badge.gearshape")
                    }

                    Button {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                            isFilesTrayOpen = true
                        }
                    } label: {
                        Label("Files Drawer", systemImage: "folder.fill")
                    }
                }

                Section("Tools & Views") {
                    Button {
                        withAnimation(.spring(response: 0.30, dampingFraction: 0.80)) {
                            isAppleDockVisible.toggle()
                        }
                    } label: {
                        Label(isAppleDockVisible ? "Hide Apple Mini Dock" : "Show Apple Mini Dock", systemImage: "wrench.and.screwdriver.fill")
                    }

                    Button {
                        windowManager.openTab(.terminal)
                    } label: {
                        Label("Terminal Studio", systemImage: "terminal.fill")
                    }

                    Button {
                        windowManager.openTab(.browser)
                    } label: {
                        Label("Mini Browser", systemImage: "globe")
                    }

                    Button {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                            showShortcutHints.toggle()
                        }
                    } label: {
                        Label(showShortcutHints ? "Hide Genie Magic & Shortcuts" : "Show Genie Magic & Shortcuts (🧞‍♂️✨)", systemImage: "sparkles")
                    }

                    Button {
                        withAnimation(.spring(response: 0.30, dampingFraction: 0.80)) {
                            if windowManager.activeTab.kind == .settings {
                                windowManager.activeTab = .chat
                            } else {
                                windowManager.openTab(.settings)
                            }
                        }
                    } label: {
                        Label(windowManager.activeTab.kind == .settings ? "Back to Chat" : "Genie Settings (⌘,)", systemImage: "gearshape.fill")
                    }
                }

                Section("Mac Actions") {
                    Button(action: {
                        if screenRecorder.isRecording {
                            screenRecorder.stopRecording()
                            showStatusFeedback("Screen Recording Saved! 🎥")
                        } else {
                            screenRecorder.startRecording()
                            showStatusFeedback("Recording Screen... 🔴")
                        }
                        HapticFeedback.selection()
                    }) {
                        Label(
                            screenRecorder.isRecording ? "Stop Screen Recording (\(screenRecorder.elapsedSeconds)s)" : "Record Desktop Screen (HD)",
                            systemImage: screenRecorder.isRecording ? "stop.circle.fill" : "record.circle"
                        )
                    }

                    Button(action: {
                        sleepManager.toggleSleepPrevention()
                        showStatusFeedback(sleepManager.isSleepDisabled ? "Clamshell Awake ON 🖥️" : "Normal Sleep 🌙")
                        HapticFeedback.selection()
                    }) {
                        Label(
                            sleepManager.isSleepDisabled ? "Clamshell Awake Active" : "Clamshell Awake (Lid-Closed)",
                            systemImage: "display.2"
                        )
                    }

                    Button(action: {
                        let clean = promptText.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !clean.isEmpty {
                            imessageManager.sendiMessageDirect(to: imessageManager.nicholasAppleID, message: clean)
                            promptText = ""
                            localModels.activeDraftPrompt = ""
                            showStatusFeedback("Relayed to iPhone Messages! 📱")
                        } else if let lastBotMsg = localModels.chatHistory.last(where: { $0.role == "assistant" })?.content {
                            imessageManager.sendiMessageDirect(to: imessageManager.nicholasAppleID, message: lastBotMsg)
                            showStatusFeedback("Last reply sent to iPhone! 📱")
                        } else {
                            GeniePhoneBridgeManager.shared.pingNicholasPhone()
                            showStatusFeedback("Pinged iPhone! 📱")
                        }
                        HapticFeedback.selection()
                    }) {
                        Label("Relay to iPhone (iMessage)", systemImage: "message.fill")
                    }
                }

                Section("Speech & Audio") {
                    Button(action: {
                        speechEngine.toggleListening()
                    }) {
                        Label(speechEngine.isRunning ? "Stop Voice Dictation" : "Start Voice Dictation", systemImage: "mic.fill")
                    }

                    Button(action: {
                        if voiceEngine.isSpeaking {
                            voiceEngine.stopSpeaking()
                        } else if let lastBotMsg = localModels.chatHistory.last(where: { $0.role == "assistant" })?.content {
                            voiceEngine.speak(text: lastBotMsg)
                        }
                    }) {
                        Label(voiceEngine.isSpeaking ? "Stop Speaking" : "Read Aloud Last Message", systemImage: "speaker.wave.2.fill")
                    }
                }

                Divider()

                Section("Conversation") {
                    Button(action: {
                        showLearningLedger = true
                    }) {
                        Label("Self-Learning & Script Ledger", systemImage: "brain.head.profile")
                    }

                    Button(role: .destructive, action: {
                        localModels.clearChatHistory()
                        showStatusFeedback("Chat Cleared")
                        HapticFeedback.selection()
                    }) {
                        Label("Clear Conversation", systemImage: "trash")
                    }
                }
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(0.90))
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(Color.white.opacity(0.12)))
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.20), lineWidth: 0.6))
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .frame(width: 28, height: 28)
            .fixedSize()
            .help("Actions & Tools (+)")

            // Quick paperclip file attach button
            attachFileButton

            // 💡 Hover / Tap to activate Genie Magic Hints
            hintsHoverButton

            // Spacious Text Input Field with Bold 13 Pillow White Font
            let hintPlaceholder: String = isHintsActive
                ? (animatedShortcuts.isEmpty ? "Ask Genie anything..." : animatedShortcuts[animatedHintIndex % animatedShortcuts.count])
                : "Ask Genie anything..."
            TextField(hintPlaceholder, text: $promptText)
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .shadow(color: Color.white.opacity(0.18), radius: 3, x: 0, y: 0.5)
                .padding(.vertical, 7)
                .frame(maxWidth: .infinity)
                .focused($isPromptFieldFocused)
                .onSubmit { handlePromptSubmit() }
                .onChange(of: promptText) { _, newText in
                    localModels.activeDraftPrompt = newText
                    GenieLanguageInputDetector.shared.processTypedInput(newText)
                }
                .onReceive(localModels.$activeDraftPrompt) { draft in
                    if promptText != draft {
                        promptText = draft
                    }
                }

            if !promptText.isEmpty {
                Button(action: {
                    promptText = ""
                    localModels.activeDraftPrompt = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.45))
                }
                .buttonStyle(.plain)
                .help("Clear Input")
            }

            // 🎥 Native Screen Recorder Button
            screenRecordButton

            // 🎙️ Voice Input (Speech Recognition & Command Decoder)
            voiceDictationButton

            // Send / Processing Button [↑]
            sendOrCancelButton
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            ZStack {
                VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow, state: .active)
                Capsule().fill(Color(red: 0.07, green: 0.09, blue: 0.13).opacity(0.85))
            }
        )
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.35),
                            Color.white.opacity(0.12),
                            Color.white.opacity(0.06),
                            Color.white.opacity(0.20)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.0
                )
        )
        .shadow(color: Color.black.opacity(0.40), radius: 14, x: 0, y: 5)
        .contentShape(Capsule())
        .onTapGesture { isPromptFieldFocused = true }
    }

    private var attachFileButton: some View {
        Button(action: openFilePicker) {
            Image(systemName: "paperclip")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(!droppedAttachments.isEmpty ? Color.cyan : Color.white.opacity(0.85))
                .frame(width: 26, height: 26)
                .background(Circle().fill(!droppedAttachments.isEmpty ? Color.cyan.opacity(0.25) : Color.white.opacity(0.10)))
                .overlay(Circle().strokeBorder(!droppedAttachments.isEmpty ? Color.cyan.opacity(0.60) : Color.white.opacity(0.16), lineWidth: 0.6))
        }
        .buttonStyle(GenieMagneticButtonStyle())
        .frame(width: 26, height: 26)
        .fixedSize()
        .help("Attach Files, Code, PDFs, or Images (⌘O)")
        .accessibilityLabel("Attach Files")
    }

    private func openFilePicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.prompt = "Attach"
        panel.message = "Choose code, documents, or images to analyze in chat"
        if panel.runModal() == .OK {
            for url in panel.urls {
                if !droppedAttachments.contains(url) {
                    droppedAttachments.append(url)
                }
            }
            HapticFeedback.selection()
        }
    }

    @ViewBuilder
    private var voiceDictationButton: some View {
        Button(action: {
            HapticFeedback.selection()
            speechEngine.toggleListening()
        }) {
            HStack(spacing: 3) {
                Image(systemName: speechEngine.isRunning ? "mic.fill" : "mic")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(speechEngine.isRunning ? Color.cyan : Color.white.opacity(0.70))

                if speechEngine.isRunning {
                    Circle()
                        .fill(Color.cyan)
                        .frame(width: 5, height: 5)
                        .scaleEffect(1.0 + CGFloat(speechEngine.audioLevel) * 1.6)
                        .animation(.easeInOut(duration: 0.08), value: speechEngine.audioLevel)
                }
            }
            .frame(width: speechEngine.isRunning ? 34 : 28, height: 28)
            .background(
                Capsule()
                    .fill(speechEngine.isRunning ? Color.cyan.opacity(0.25) : Color.white.opacity(0.08))
            )
            .overlay(
                Capsule()
                    .strokeBorder(speechEngine.isRunning ? Color.cyan.opacity(0.70) : Color.white.opacity(0.12), lineWidth: 0.8)
            )
        }
        .buttonStyle(GenieMagneticButtonStyle())
        .help(speechEngine.isRunning ? "Listening..." : "Voice Dictation")
    }

    @ViewBuilder
    private var screenRecordButton: some View {
        Button(action: {
            HapticFeedback.selection()
            if screenRecorder.isRecording {
                screenRecorder.stopRecording()
                showStatusFeedback("Screen Recording Saved! 🎥")
            } else {
                screenRecorder.startRecording()
                showStatusFeedback("Recording Screen... 🔴")
            }
        }) {
            HStack(spacing: 4) {
                Image(systemName: screenRecorder.isRecording ? "stop.fill" : "record.circle")
                    .font(.system(size: screenRecorder.isRecording ? 10 : 13, weight: .bold))
                    .foregroundColor(screenRecorder.isRecording ? Color.red : Color.white.opacity(0.70))

                if screenRecorder.isRecording {
                    Text("\(screenRecorder.elapsedSeconds)s")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.red)
                }
            }
            .frame(width: screenRecorder.isRecording ? 52 : 28, height: 28)
            .background(
                Capsule()
                    .fill(screenRecorder.isRecording ? Color.red.opacity(0.25) : Color.white.opacity(0.08))
            )
            .overlay(
                Capsule()
                    .strokeBorder(screenRecorder.isRecording ? Color.red.opacity(0.70) : Color.white.opacity(0.12), lineWidth: 0.8)
            )
        }
        .buttonStyle(GenieMagneticButtonStyle())
        .help(screenRecorder.isRecording ? "Stop Screen Recording (\(screenRecorder.elapsedSeconds)s)" : "Record Desktop Screen (HD)")
    }

    @ViewBuilder
    private var sendOrCancelButton: some View {
        if localModels.isGenerating {
            Button(action: {
                localModels.stopGeneration()
            }) {
                GenieFuturisticSmokeIconView(
                    size: 24,
                    isGlowing: true,
                    showSmokeAnimation: true,
                    tintColor: .cyan,
                    isProcessing: true
                )
                .frame(width: 28, height: 28)
            }
            .buttonStyle(GenieMagneticButtonStyle(scale: 1.14))
            .help("Genie Bottled (Actively Processing) — Click to Stop")
        } else {
            let hasInput = !promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !droppedAttachments.isEmpty
            Button(action: { handlePromptSubmit() }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 26))
                    .foregroundColor(!hasInput ? .white.opacity(0.25) : .cyan)
                    .shadow(color: !hasInput ? Color.clear : Color.cyan.opacity(0.60), radius: 6)
            }
            .buttonStyle(GenieMagneticButtonStyle(scale: 1.14))
            .disabled(!hasInput)
            .help("Send Message (↵)")
        }
    }

    // MARK: - 💡 Hover-to-Activate Shortcut Hints Button
    private var hintsHoverButton: some View {
        Button(action: {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.80)) {
                showShortcutHints.toggle()
            }
            HapticFeedback.selection()
        }) {
            HStack(spacing: 3.5) {
                Image(systemName: "sparkles")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(isHintsActive ? .cyan : .white.opacity(0.65))
                
                if isHintsHovered || showShortcutHints {
                    Text("Hints")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.90))
                        .transition(.opacity.combined(with: .scale(scale: 0.85)))
                }
            }
            .padding(.horizontal, (isHintsHovered || showShortcutHints) ? 7 : 5)
            .frame(height: 26)
            .background(
                Capsule()
                    .fill(isHintsActive ? Color.cyan.opacity(0.22) : Color.white.opacity(0.08))
            )
            .overlay(
                Capsule()
                    .strokeBorder(
                        isHintsActive ? Color.cyan.opacity(0.65) : Color.white.opacity(0.14),
                        lineWidth: 0.6
                    )
            )
        }
        .buttonStyle(GenieMagneticButtonStyle(scale: 1.06))
        .onHover { hovering in
            withAnimation(.spring(response: 0.22, dampingFraction: 0.82)) {
                isHintsHovered = hovering
            }
        }
        .help(showShortcutHints ? "Genie Magic Hints Pinned (Click to Unpin)" : "Hover or Click to Activate Genie Magic Hints")
        .accessibilityLabel("Genie Magic Hints")
    }

    // MARK: - 🔄 Slide-Down vs Desktop Presentation Switcher
    @ViewBuilder
    private var presentationSwitcherControls: some View {
        HStack(spacing: 5) {
            // Flip out Left Hemisphere Dual Screen Toggle
            Button(action: {
                windowManager.toggleDualHemisphere()
            }) {
                HStack(spacing: 3) {
                    Image(systemName: windowManager.isDualHemisphereMode ? "rectangle.split.2x1.fill" : "rectangle.split.2x1")
                        .font(.system(size: 9.5, weight: .bold))
                    Text(windowManager.isDualHemisphereMode ? "Dual Screen" : "Flip Out")
                        .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                }
                .foregroundColor(windowManager.isDualHemisphereMode ? .cyan : .white.opacity(0.80))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Capsule().fill(windowManager.isDualHemisphereMode ? Color.cyan.opacity(0.18) : Color.white.opacity(0.08)))
                .overlay(Capsule().strokeBorder(windowManager.isDualHemisphereMode ? Color.cyan.opacity(0.45) : Color.white.opacity(0.18), lineWidth: 0.5))
            }
            .buttonStyle(GenieMagneticButtonStyle(scale: 1.05))
            .help("Flip out Left Hemisphere with Apple Finder multi-column browser (⌘[)")
            .keyboardShortcut("[", modifiers: .command)

            if windowManager.isSlideDownFullScreen {
                Button(action: {
                    windowManager.hide()
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "chevron.compact.up")
                            .font(.system(size: 10, weight: .bold))
                        Text("Slide Up")
                            .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white.opacity(0.80))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.white.opacity(0.08)))
                    .overlay(Capsule().strokeBorder(Color.white.opacity(0.18), lineWidth: 0.5))
                }
                .buttonStyle(GenieMagneticButtonStyle(scale: 1.05))
                .help("Slide up chat into top ceiling (Esc)")

                Button(action: {
                    windowManager.showInDesktopForm()
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "macwindow")
                            .font(.system(size: 9.5, weight: .bold))
                        Text("Desktop Form")
                            .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.cyan.opacity(0.18)))
                    .overlay(Capsule().strokeBorder(Color.cyan.opacity(0.45), lineWidth: 0.6))
                }
                .buttonStyle(GenieMagneticButtonStyle(scale: 1.05))
                .help("Morph into floating desktop window (⌥⌘↓)")

                TimelineView(.periodic(from: .now, by: 1.0)) { timeline in
                    Text(timeline.date, style: .time)
                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.70))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2.5)
                        .background(Capsule().fill(Color.white.opacity(0.06)))
                }
            } else {
                Button(action: {
                    windowManager.slideDownFullScreen()
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.down.to.line.compact")
                            .font(.system(size: 9.5, weight: .bold))
                        Text("Slide Down")
                            .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white.opacity(0.70))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.white.opacity(0.06)))
                    .overlay(Capsule().strokeBorder(Color.white.opacity(0.14), lineWidth: 0.5))
                }
                .buttonStyle(GenieMagneticButtonStyle(scale: 1.05))
                .help("Expand into Top Slide-Down Full Screen (⌥⌘↑)")
            }
        }
    }

    // MARK: - 🎛️ Header Quick Settings Strip (Merged Living Liquid Gear + Quick Controls)
    private var headerQuickSettingsStrip: some View {
        HStack(spacing: 3) {
            // 💧 2028 Apple Living Liquid Water Settings Icon (Merged Primary Anchor)
            Genie2028LiquidSettingsIcon(
                size: 20,
                isActive: windowManager.activeTab.kind == .settings,
                action: {
                    withAnimation(.spring(response: 0.30, dampingFraction: 0.80)) {
                        if windowManager.activeTab.kind == .settings {
                            windowManager.activeTab = .chat
                        } else {
                            windowManager.openTab(.settings)
                        }
                    }
                }
            )
            .help(windowManager.activeTab.kind == .settings ? "Back to Chat" : "Settings & Preferences (⌘,)")

            Rectangle()
                .fill(Color.white.opacity(0.14))
                .frame(width: 1, height: 12)
                .padding(.horizontal, 1)

            // 💻 Quake Drop-Down CLI Console toggle
            headerQuickIconButton(
                icon: "terminal.fill",
                title: showDropDownCLIDrawer ? "Hide Drop-Down CLI Console (⌘~)" : "Drop-Down CLI Console (⌘~)",
                isActive: showDropDownCLIDrawer,
                activeColor: .green
            ) {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                    showDropDownCLIDrawer.toggle()
                }
                HapticFeedback.selection()
                showStatusFeedback(showDropDownCLIDrawer ? "CLI Console Dropped Down 💻 (⌘~)" : "CLI Console Closed")
            }

            // Apple Mini Dock in Chat toggle
            headerQuickIconButton(
                icon: isAppleDockVisible ? "dock.rectangle" : "rectangle.bottomthird.inset.filled",
                title: isAppleDockVisible ? "Apple Dock Visible (Click to Hide)" : "Apple Dock Hidden (Click to Show)",
                isActive: isAppleDockVisible,
                activeColor: .orange
            ) {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                    isAppleDockVisible.toggle()
                }
                HapticFeedback.selection()
                showStatusFeedback(isAppleDockVisible ? "Apple Dock Visible ⚓" : "Apple Dock Hidden")
            }

            // Consolidated Quick Atmosphere, Zen & Sound Menu
            Menu {
                // Sound Effects
                Button(action: {
                    isSoundEnabled.toggle()
                    UserDefaults.standard.set(isSoundEnabled, forKey: PrefKey.soundEnabled)
                    HapticFeedback.selection()
                    showStatusFeedback(isSoundEnabled ? "Sound Effects On 🔊" : "Sound Muted 🔇")
                }) {
                    Label(isSoundEnabled ? "Sound Effects: On ✓" : "Sound Effects: Muted", systemImage: isSoundEnabled ? "speaker.wave.2.fill" : "speaker.slash.fill")
                }

                // Zen Mode
                Button(action: {
                    SkyLightZenOverlayManager.shared.toggle()
                    HapticFeedback.selection()
                    showStatusFeedback(SkyLightZenOverlayManager.shared.isOverlayActive ? "Zen Mode Overlay On 🧘 (⌥⌘Z)" : "Zen Mode Overlay Off 🍃")
                }) {
                    Label(SkyLightZenOverlayManager.shared.isOverlayActive || isZenModeEnabled ? "Zen Mode Overlay: Active ✓ (⌥⌘Z)" : "Zen Mode Overlay: Off (⌥⌘Z)", systemImage: "leaf.fill")
                }

                // SkyLight Wallpapers
                Button(action: {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        showSkyLightWallpaperDrawer.toggle()
                    }
                    HapticFeedback.selection()
                    showStatusFeedback(showSkyLightWallpaperDrawer ? "SkyLight Wallpaper Portal Open 🌌" : "SkyLight Portal Closed")
                }) {
                    Label(showSkyLightWallpaperDrawer ? "SkyLight Wallpapers: Open ✓" : "SkyLight Wallpapers...", systemImage: "sparkles.tv")
                }

                // Atmosphere FX
                Button(action: {
                    isAtmosphereEnabled.toggle()
                    UserDefaults.standard.set(isAtmosphereEnabled, forKey: PrefKey.smokeEffectsEnabled)
                    HapticFeedback.selection()
                    showStatusFeedback(isAtmosphereEnabled ? "Atmospheric FX On 🌌" : "Atmospheric FX Off")
                }) {
                    Label(isAtmosphereEnabled ? "Atmospheric Living FX: On ✓" : "Atmospheric Living FX: Off", systemImage: "sparkles")
                }
            } label: {
                let isAnyActive = SkyLightZenOverlayManager.shared.isOverlayActive || isZenModeEnabled || showSkyLightWallpaperDrawer
                Image(systemName: isAnyActive ? "sparkles" : "ellipsis.circle")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(isAnyActive ? .cyan : .white.opacity(0.55))
                    .frame(width: 22, height: 22)
                    .background(Circle().fill(Color.white.opacity(0.06)))
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5))
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .help("Quick Atmosphere, Zen & Sound Controls")
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .background(Capsule().fill(Color.white.opacity(0.05)))
        .overlay(Capsule().stroke(Color.white.opacity(0.10), lineWidth: 0.5))
        .fixedSize()
    }

    private func headerQuickIconButton(
        icon: String,
        title: String,
        isActive: Bool,
        activeColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(isActive ? activeColor : .white.opacity(0.40))
                .frame(width: 22, height: 22)
                .background(
                    Circle()
                        .fill(isActive ? activeColor.opacity(0.18) : Color.white.opacity(0.06))
                )
                .overlay(
                    Circle()
                        .strokeBorder(isActive ? activeColor.opacity(0.45) : Color.white.opacity(0.10), lineWidth: 0.5)
                )
        }
        .buttonStyle(GenieMagneticButtonStyle(scale: 1.10))
        .help(title)
    }

    // MARK: - ⚡ Quick Project / File Creator Button
    private var quickCreateButton: some View {
        Button(action: {
            HapticFeedback.selection()
            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                showQuickCreationSheet.toggle()
            }
        }) {
            Image(systemName: "plus.square.dashed")
                .font(.system(size: 11.5, weight: .bold))
                .foregroundColor(showQuickCreationSheet ? Color.indigo : Color.white.opacity(0.85))
                .frame(width: 26, height: 26)
                .background(Circle().fill(showQuickCreationSheet ? Color.indigo.opacity(0.30) : Color.white.opacity(0.10)))
                .overlay(Circle().strokeBorder(showQuickCreationSheet ? Color.indigo.opacity(0.70) : Color.white.opacity(0.16), lineWidth: 0.6))
        }
        .buttonStyle(GenieMagneticButtonStyle())
        .frame(width: 26, height: 26)
        .fixedSize()
        .help("Quick Project or File Creator (⚡)")
        .accessibilityLabel("Quick Project or File Creator")
    }

    // MARK: - ⚡ Quick Project & File Creation Overlay (Apple 2028 Glass)
    private var quickCreationOverlay: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(LinearGradient(colors: [.indigo, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                    Text("Quick Project & File Creator")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                Spacer()

                Button(action: {
                    withAnimation(.spring(response: 0.24, dampingFraction: 0.82)) {
                        showQuickCreationSheet = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                }
                .buttonStyle(.plain)
            }

            // Kinds Pills Grid
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(QuickCreateKind.allCases, id: \.self) { kind in
                        let isSel = (quickCreateKind == kind)
                        Button(action: {
                            HapticFeedback.selection()
                            quickCreateKind = kind
                            if quickCreateName.isEmpty {
                                quickCreateName = kind.defaultPlaceholder
                            }
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: kind.icon)
                                    .font(.system(size: 10, weight: .semibold))
                                Text(kind.title)
                                    .font(.system(size: 10.5, weight: isSel ? .semibold : .regular, design: .rounded))
                            }
                            .foregroundColor(isSel ? .white : .white.opacity(0.7))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(isSel ? Color.indigo.opacity(0.65) : Color.white.opacity(0.08))
                            )
                            .overlay(
                                Capsule()
                                    .strokeBorder(isSel ? Color.white.opacity(0.5) : Color.white.opacity(0.12), lineWidth: 0.6)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // File / Project Name Input
            VStack(alignment: .leading, spacing: 4) {
                Text(quickCreateKind == .folder ? "Folder / Project Name" : "File Name")
                    .font(.system(size: 10.5, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.65))

                HStack {
                    TextField(quickCreateKind.defaultPlaceholder, text: $quickCreateName)
                        .textFieldStyle(.plain)
                        .font(.system(size: 12, weight: .regular, design: .monospaced))
                        .foregroundColor(.white)
                        .onSubmit { performQuickCreation() }

                    if !quickCreateName.isEmpty {
                        Button(action: { quickCreateName = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.08)))
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.white.opacity(0.16), lineWidth: 0.6))
            }

            // Target Location
            HStack(spacing: 6) {
                Image(systemName: "folder")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))
                Text(quickCreateDirectory.path.replacingOccurrences(of: FileManager.default.homeDirectoryForCurrentUser.path, with: "~"))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.white.opacity(0.75))
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer()

                Button(action: pickQuickCreateDirectory) {
                    Text("Browse...")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(.cyan)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.cyan.opacity(0.12)))
                }
                .buttonStyle(.plain)
            }

            // Action Buttons
            HStack(spacing: 10) {
                Button(action: {
                    withAnimation(.spring(response: 0.24, dampingFraction: 0.82)) {
                        showQuickCreationSheet = false
                    }
                }) {
                    Text("Cancel")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Capsule().fill(Color.white.opacity(0.08)))
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: performQuickCreation) {
                    HStack(spacing: 5) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 10, weight: .bold))
                        Text(quickCreateKind == .folder ? "Create Folder" : "Create & Edit")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(LinearGradient(colors: [Color.indigo, Color.purple], startPoint: .leading, endPoint: .trailing))
                    )
                    .overlay(Capsule().strokeBorder(Color.white.opacity(0.3), lineWidth: 0.6))
                    .shadow(color: Color.indigo.opacity(0.4), radius: 6, y: 2)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .background(
            ZStack {
                VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow, state: .active)
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.black.opacity(0.65))
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.3), Color.white.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
                )
        )
        .shadow(color: Color.black.opacity(0.5), radius: 20, y: 10)
        .padding(.horizontal, isEmbedded ? 12 : 24)
        .padding(.bottom, 60)
        .transition(.asymmetric(
            insertion: .scale(scale: 0.94).combined(with: .opacity).combined(with: .move(edge: .bottom)),
            removal: .scale(scale: 0.96).combined(with: .opacity)
        ))
    }

    private func pickQuickCreateDirectory() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Select Folder"
        panel.directoryURL = quickCreateDirectory
        if panel.runModal() == .OK, let chosen = panel.url {
            quickCreateDirectory = chosen
        }
    }

    private func openDirectoryPicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Open Workspace"
        panel.message = "Choose a project directory or folder to open in Genie"
        if FileManager.default.fileExists(atPath: quickCreateDirectory.path) {
            panel.directoryURL = quickCreateDirectory
        }
        if panel.runModal() == .OK, let selectedURL = panel.url {
            browserURL = selectedURL
            quickCreateDirectory = selectedURL
            let tab = FinderWindowTab(
                id: "files-\(selectedURL.path)",
                kind: .files,
                title: selectedURL.lastPathComponent,
                customURL: selectedURL
            )
            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                windowManager.openTab(tab)
            }
            showStatusFeedback("Opened \(selectedURL.lastPathComponent) 📂")
            HapticFeedback.selection()
        }
    }

    private func performQuickCreation() {
        let rawName = quickCreateName.trimmingCharacters(in: .whitespacesAndNewlines)
        let defaultName = rawName.isEmpty ? quickCreateKind.defaultPlaceholder : rawName
        let fileName: String
        if quickCreateKind == .folder {
            fileName = defaultName
        } else {
            let ext = quickCreateKind.defaultExtension
            if !ext.isEmpty && !defaultName.hasSuffix(".\(ext)") {
                fileName = "\(defaultName).\(ext)"
            } else {
                fileName = defaultName
            }
        }

        let targetDir = quickCreateDirectory
        try? FileManager.default.createDirectory(at: targetDir, withIntermediateDirectories: true)
        let fileURL = targetDir.appendingPathComponent(fileName)

        do {
            if quickCreateKind == .folder {
                try FileManager.default.createDirectory(at: fileURL, withIntermediateDirectories: true)
                showStatusFeedback("Created folder \(fileName) 📁")
                browserURL = fileURL
                let tab = FinderWindowTab(
                    id: "files-\(fileURL.path)",
                    kind: .files,
                    title: fileName,
                    customURL: fileURL
                )
                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                    windowManager.openTab(tab)
                }
            } else {
                let template = quickCreateKind.starterTemplate
                try template.write(to: fileURL, atomically: true, encoding: .utf8)
                showStatusFeedback("Created \(fileName) ⚡")
                browserURL = fileURL
                let tab = FinderWindowTab(
                    id: "editor-\(fileURL.path)",
                    kind: .editor,
                    title: fileName,
                    customURL: fileURL
                )
                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                    windowManager.openTab(tab)
                }
            }
            showQuickCreationSheet = false
            quickCreateName = ""
            HapticFeedback.selection()
        } catch {
            showStatusFeedback("Failed: \(error.localizedDescription) ⚠️")
        }
    }

    private func handlePromptSubmit() {
        let clean = promptText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard (!clean.isEmpty || !droppedAttachments.isEmpty), !localModels.isGenerating else { return }

        // Automatically release microphone and hardware audio tap immediately on submit
        if speechEngine.isRunning {
            speechEngine.stopListening()
        }

        // Intercept slash commands or "open <app>"
        if clean.hasPrefix("/") || clean.lowercased().hasPrefix("open ") {
            promptText = ""
            executeSlashCommand(clean)
            return
        }

        // Auto-detect direct URL submission to pop automatically into Mini Browser
        let lowerClean = clean.lowercased()
        let isDirectURL: Bool = {
            if (lowerClean.hasPrefix("http://") || lowerClean.hasPrefix("https://")) && !clean.contains(" ") {
                return true
            }
            if lowerClean.hasPrefix("www.") && !clean.contains(" ") {
                return true
            }
            return false
        }()

        if isDirectURL {
            promptText = ""
            let urlStr = (lowerClean.hasPrefix("http://") || lowerClean.hasPrefix("https://")) ? clean : "https://\(clean)"
            if let targetURL = URL(string: urlStr) {
                withAnimation(.spring(response: 0.30, dampingFraction: 0.80)) {
                    windowManager.openTab(.browser)
                }
                MiniBrowserManager.shared.browse(url: targetURL)
                showStatusFeedback("Popped into browser: \(targetURL.host ?? urlStr) 🌐")
                HapticFeedback.selection()
                return
            }
        }

        // Auto-detect multi-turn conversation pasted directly into the prompt box
        let parsed = localModels.parseChatTranscript(from: clean)
        if parsed.count >= 2 {
            promptText = ""
            localModels.chatHistory.append(contentsOf: parsed)
            localModels.saveChatHistory()
            showStatusFeedback("Imported whole chat (\(parsed.count) messages) 📋✨")
            HapticFeedback.success()
            return
        }

        promptText = ""
        var filesToProcess = droppedAttachments
        droppedAttachments = []

        // Auto-detect screenshot and image file paths typed or pasted directly in the prompt
        if filesToProcess.isEmpty {
            let rawPathPattern = #"((?:/(?:[^\s\n\r"'`()\[\]<>]|\\ )+|~/(?:[^\s\n\r"'`()\[\]<>]|\\ )+|file://(?:[^\s\n\r"'`()\[\]<>]|\\ )+)\.(?:png|jpg|jpeg|gif|webp|heic|tiff|bmp|svg))"#
            if let regex = try? NSRegularExpression(pattern: rawPathPattern, options: [.caseInsensitive]) {
                let ns = clean as NSString
                let matches = regex.matches(in: clean, options: [], range: NSRange(location: 0, length: ns.length))
                for match in matches {
                    let matchedStr = ns.substring(with: match.range(at: 1))
                    if let resolved = GenieMarkdownMessageView.resolveImageFilePathOrURL(matchedStr) {
                        filesToProcess.append(resolved)
                    }
                }
            }
        }

        Task { @MainActor in
            if !filesToProcess.isEmpty {
                showStatusFeedback("Attached \(filesToProcess.count) image/file(s) 🖼️")
            }
            let finalPrompt = await GenieFileContentLoader.shared.preparePromptWithAttachments(
                prompt: clean,
                files: filesToProcess
            )

            let firstImage = filesToProcess.first(where: { url in
                if case .image = GenieFileContentLoader.shared.detectCategory(for: url) { return true }
                let ext = url.pathExtension.lowercased()
                return ["png", "jpg", "jpeg", "gif", "webp", "heic", "tiff", "bmp", "svg"].contains(ext)
            })

            localModels.generate(
                prompt: finalPrompt,
                mediaPath: firstImage?.path,
                mediaType: firstImage != nil ? "image" : nil
            )
            HapticFeedback.selection()
        }
    }

    private func executeSlashCommand(_ cmd: String) {
        let trimmed = cmd.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = trimmed.lowercased()

        if lower == "/righthalf" || lower == "/right" || lower == "/split right" {
            windowManager.snapTo(preset: .rightHalf)
            showStatusFeedback("Snapped to Right Half Screen ◨")
            return
        }

        if lower == "/lefthalf" || lower == "/left" || lower == "/split left" {
            windowManager.snapTo(preset: .leftHalf)
            showStatusFeedback("Snapped to Left Half Screen (Thirds Mode) ◧")
            return
        }

        if lower == "/thirds" || lower == "/thirdsmode" || lower == "/3" {
            windowManager.snapTo(preset: .thirdsMode)
            showStatusFeedback("Snapped to Thirds Mode [ Studio | Viewer | Chat ] ⚏")
            return
        }

        if lower == "/cli" || lower == "/terminal" || lower == "/quake" || lower == "/console" {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                showDropDownCLIDrawer.toggle()
            }
            showStatusFeedback(showDropDownCLIDrawer ? "Drop-Down CLI Console Open 💻" : "CLI Console Hidden")
            return
        }

        if lower.hasPrefix("/wish ") || lower == "/wish" {
            let wishText = lower.hasPrefix("/wish ") ? String(trimmed.dropFirst(6)).trimmingCharacters(in: .whitespacesAndNewlines) : "Surprise me with a magical wish!"
            GenieSporadicWishEngine.shared.grantWish(wishText)
            showStatusFeedback("Granting your wish: \"\(wishText)\" ✨")
            return
        }

        if lower == "/rub" || lower == "/rub_lamp" || lower == "/lamp" {
            GenieSporadicWishEngine.shared.rubLamp()
            showStatusFeedback("Rubbed the magic lamp! 🪔✨")
            return
        }

        if lower.hasPrefix("/calc ") || lower.hasPrefix("/dist_calc ") || lower.hasPrefix("/parallel ") {
            let prefixLen = lower.hasPrefix("/calc ") ? 6 : (lower.hasPrefix("/dist_calc ") ? 11 : 10)
            let exprStr = String(trimmed.dropFirst(prefixLen))
            Task { @MainActor in
                showStatusFeedback("Distributing calculations across machines... ⚡")
                let summary = await GenieDistributedComputeEngine.shared.executeDistributedCalculations(exprStr)
                localModels.chatHistory.append(ChatMessage(role: "assistant", content: summary))
                localModels.saveChatHistory()
            }
            return
        }

        if lower == "/top" || lower == "/toppanel" || lower == "/notch" {
            windowManager.snapTo(preset: .topPanel)
            showStatusFeedback("Snapped to Consolidated Top Panel ⛶")
            return
        }

        if lower == "/fullscreen" || lower == "/max" {
            windowManager.snapTo(preset: .fullScreen)
            showStatusFeedback("Full Screen ⤢")
            return
        }

        if lower == "/standard" || lower == "/normal" {
            windowManager.snapTo(preset: .standard)
            showStatusFeedback("Standard Window Size")
            return
        }

        if lower == "/copy" || lower == "/copychat" || lower == "/copy all" {
            if localModels.copyWholeChat() {
                showStatusFeedback("Copied whole chat to clipboard 📋")
            } else {
                showStatusFeedback("No messages in chat to copy ⚠️")
            }
            return
        }

        if lower == "/paste" || lower == "/pastechat" || lower == "/importchat" {
            let res = localModels.pasteWholeChat()
            if res.success {
                showStatusFeedback("Pasted whole chat (\(res.count) messages) 📋✨")
            } else {
                showStatusFeedback("No chat transcript found in clipboard ⚠️")
            }
            return
        }

        if lower == "/new" || lower == "/newfile" || lower == "/newproject" {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                showQuickCreationSheet = true
            }
            showStatusFeedback("New Project or File Creator ⚡")
            HapticFeedback.selection()
            return
        }

        if lower == "/open" || lower == "/directory" || lower == "/workspace" {
            openDirectoryPicker()
            return
        }

        if lower.hasPrefix("/open ") || lower.hasPrefix("/cd ") {
            let pathArg = String(trimmed.dropFirst(lower.hasPrefix("/open ") ? 6 : 4)).trimmingCharacters(in: .whitespacesAndNewlines)
            if !pathArg.isEmpty {
                let expanded = (pathArg as NSString).expandingTildeInPath
                let url = URL(fileURLWithPath: expanded)
                var isDir: ObjCBool = false
                if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir) {
                    if isDir.boolValue {
                        browserURL = url
                        quickCreateDirectory = url
                        let tab = FinderWindowTab(id: "files-\(url.path)", kind: .files, title: url.lastPathComponent, customURL: url)
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                            windowManager.openTab(tab)
                        }
                        showStatusFeedback("Opened \(url.lastPathComponent) 📂")
                    } else {
                        browserURL = url.deletingLastPathComponent()
                        openFileInEditor(url)
                        let tab = FinderWindowTab(id: "editor-\(url.path)", kind: .editor, title: url.lastPathComponent, customURL: url)
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                            windowManager.openTab(tab)
                        }
                        showStatusFeedback("Opened \(url.lastPathComponent) in Editor 💻")
                    }
                    HapticFeedback.selection()
                    return
                } else {
                    showStatusFeedback("Path not found: \(pathArg) ⚠️")
                    return
                }
            }
        }

        if lower.hasPrefix("/mkdir ") {
            let folderName = String(trimmed.dropFirst(7)).trimmingCharacters(in: .whitespacesAndNewlines)
            if !folderName.isEmpty {
                let target = quickCreateDirectory.appendingPathComponent(folderName)
                do {
                    try FileManager.default.createDirectory(at: target, withIntermediateDirectories: true)
                    browserURL = target
                    let tab = FinderWindowTab(id: "files-\(target.path)", kind: .files, title: folderName, customURL: target)
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        windowManager.openTab(tab)
                    }
                    showStatusFeedback("Created directory \(folderName) 📁")
                    HapticFeedback.selection()
                    return
                } catch {
                    showStatusFeedback("Error: \(error.localizedDescription) ⚠️")
                    return
                }
            }
        }

        if lower == "/settings" || lower == "/preferences" {
            withAnimation(.spring(response: 0.30, dampingFraction: 0.80)) {
                windowManager.openTab(.settings)
            }
            showStatusFeedback("Opened Settings ⚙️")
            HapticFeedback.selection()
            return
        }

        if lower == "/finder" || lower == "/files" {
            withAnimation(.spring(response: 0.30, dampingFraction: 0.80)) {
                windowManager.openTab(.files)
            }
            showStatusFeedback("Opened Finder 📁")
            HapticFeedback.selection()
            return
        }

        if lower == "/editor" || lower == "/code" {
            withAnimation(.spring(response: 0.30, dampingFraction: 0.80)) {
                windowManager.openTab(.editor)
            }
            showStatusFeedback("Opened Editor & Preview 📝")
            HapticFeedback.selection()
            return
        }

        if lower == "/github" || lower == "/catalog" || lower == "/features" {
            withAnimation(.spring(response: 0.30, dampingFraction: 0.80)) {
                windowManager.openTab(.github)
            }
            showStatusFeedback("Opened GitHub Studio & Feature Catalog 🐙")
            HapticFeedback.selection()
            return
        }

        if lower == "/chat" || lower == "/newchat" {
            withAnimation(.spring(response: 0.30, dampingFraction: 0.80)) {
                windowManager.newChatTab()
            }
            showStatusFeedback("New Chat Tab 💬")
            HapticFeedback.selection()
            return
        }

        if lower == "/terminal" || lower == "/shell" {
            withAnimation(.spring(response: 0.30, dampingFraction: 0.80)) {
                windowManager.openTab(.terminal)
            }
            showStatusFeedback("Opened Terminal Studio ⚡")
            HapticFeedback.selection()
            return
        }

        if lower.hasPrefix("/browser ") || lower.hasPrefix("/browse ") || lower.hasPrefix("/web ") {
            let target = String(trimmed.dropFirst(lower.hasPrefix("/browse ") ? 8 : (lower.hasPrefix("/browser ") ? 9 : 5))).trimmingCharacters(in: .whitespacesAndNewlines)
            withAnimation(.spring(response: 0.30, dampingFraction: 0.80)) {
                windowManager.openTab(.browser)
            }
            if !target.isEmpty {
                MiniBrowserManager.shared.search(query: target)
            }
            showStatusFeedback("Browsing: \(target.isEmpty ? "Mini Browser" : target) 🌐")
            HapticFeedback.selection()
            return
        }

        if lower == "/browser" || lower == "/web" || lower == "/browse" {
            withAnimation(.spring(response: 0.30, dampingFraction: 0.80)) {
                windowManager.openTab(.browser)
            }
            showStatusFeedback("Opened Mini Browser 🌐")
            HapticFeedback.selection()
            return
        }

        if lower.hasPrefix("/tail") || lower == "/logs" || lower == "/recents" || lower == "/history" || lower == "/crashes" || lower == "/crash" {
            var target = "recent 25"
            if lower == "/logs" || lower == "/syslog" { target = "system 50" }
            else if lower == "/recents" || lower == "/recent" { target = "recent 25" }
            else if lower == "/history" { target = "history 30" }
            else if lower == "/crashes" || lower == "/crash" { target = "crash 5" }
            else if lower.hasPrefix("/tail ") {
                target = String(trimmed.dropFirst(6)).trimmingCharacters(in: .whitespacesAndNewlines)
            }
            showStatusFeedback("Retrieving \(target)... 📜")
            HapticFeedback.selection()
            Task {
                let tailResult = await GenieNativeToolEngine.shared.runTail(argument: target)
                await MainActor.run {
                    localModels.appendAssistantMessage("📜 **[Genie Tail Retrieval: `\(target)`]**\n\n\(tailResult)")
                    showStatusFeedback("Tail Retrieved 📜")
                }
            }
            return
        }

        if lower == "/apps" || lower == "/applications" {
            withAnimation(.spring(response: 0.30, dampingFraction: 0.80)) {
                windowManager.openTab(.applications)
            }
            showStatusFeedback("Opened Applications 📱")
            HapticFeedback.selection()
            return
        }

        if lower == "/clear" {
            localModels.clearChatHistory()
            showStatusFeedback("Chat Cleared 🧹")
            HapticFeedback.selection()
            return
        }

        if lower.hasPrefix("open ") {
            let appName = String(trimmed.dropFirst(5)).trimmingCharacters(in: .whitespacesAndNewlines)
            if !appName.isEmpty {
                if let matching = DockAndDesktopManager.shared.dockItems.first(where: { $0.name.localizedCaseInsensitiveContains(appName) }) {
                    if let bid = matching.bundleIdentifier {
                        windowManager.openProgram(bundleId: bid, name: matching.name)
                    } else {
                        windowManager.openProgram(bundleId: matching.id, name: matching.name)
                    }
                    showStatusFeedback("Opened \(matching.name) 🚀")
                    HapticFeedback.selection()
                    return
                }
                let candidates = [
                    URL(fileURLWithPath: "/Applications/\(appName).app"),
                    URL(fileURLWithPath: "/System/Applications/\(appName).app"),
                    URL(fileURLWithPath: "/System/Applications/Utilities/\(appName).app")
                ]
                if let targetURL = candidates.first(where: { FileManager.default.fileExists(atPath: $0.path) }) {
                    NSWorkspace.shared.openApplication(at: targetURL, configuration: NSWorkspace.OpenConfiguration()) { _, _ in }
                    showStatusFeedback("Launched \(appName) 🚀")
                    HapticFeedback.selection()
                    return
                }
            }
        }
    }

    private func showStatusFeedback(_ msg: String) {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
            statusFeedback = msg
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.4) {
            withAnimation(.easeOut(duration: 0.25)) {
                if statusFeedback == msg { statusFeedback = nil }
            }
        }
    }

    @ViewBuilder
    private var statusFeedbackOverlay: some View {
        if let fb = statusFeedback {
            Text(fb)
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.black.opacity(0.85)))
                .overlay(Capsule().stroke(Color.white.opacity(0.25), lineWidth: 0.5))
                .padding(.top, 48)
                .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    private func updateOrAppendArtifact(title: String, code: String, fileURL: URL?, animate: Bool) {
        let block = {
            self.previewCreation = (title: title, html: code, fileURL: fileURL)
            if let idx = self.sessionArtifacts.firstIndex(where: { $0.title == title }) {
                self.sessionArtifacts[idx] = (title: title, html: code, fileURL: fileURL)
            } else {
                self.sessionArtifacts.append((title: title, html: code, fileURL: fileURL))
            }
        }
        if animate {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                block()
            }
        } else {
            block()
        }
    }

    private func handleSetWindowMode(_ mode: String) {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.80)) {
            if mode == "settings" || mode == "mode-settings" || mode == "settings-only" {
                layoutMode = .settingsOnly
            } else if mode == "files" {
                layoutMode = .editor
            } else {
                layoutMode = .chatOnly
            }
        }
    }

    private func handleSwitchFinderSidebar(_ item: FinderChatSidebarItem) {
        withAnimation(.spring(response: 0.28, dampingFraction: 0.80)) {
            if item == .settings {
                layoutMode = .settingsOnly
            } else {
                layoutMode = .chatOnly
            }
        }
    }

    private func handleStagedAttachments(_ newFiles: [URL]) {
        guard !newFiles.isEmpty else { return }
        for f in newFiles {
            if !droppedAttachments.contains(f) {
                droppedAttachments.append(f)
            }
        }
        windowManager.clearStagedAttachments()
    }

    private func handleAIDisplayCreation(_ notif: Notification) {
        if let code = notif.object as? String, !code.isEmpty {
            let title = (notif.userInfo?["title"] as? String) ?? "AI Creation"
            let isLive = (notif.userInfo?["isLiveStream"] as? Bool) ?? false
            let fileURL: URL? = {
                if let uStr = notif.userInfo?["fileURL"] as? String, let u = URL(string: uStr) {
                    return u
                }
                if let path = notif.userInfo?["filePath"] as? String {
                    return URL(fileURLWithPath: path)
                }
                return nil
            }()
            let animate = !(isLive && self.previewCreation != nil)
            updateOrAppendArtifact(title: title, code: code, fileURL: fileURL, animate: animate)
        }
    }

    private func handleChatRenderFocused(_ notif: Notification) {
        guard let artifact = notif.object as? ChatRenderArtifact else { return }
        withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
            self.previewCreation = (title: artifact.title, html: artifact.body, fileURL: nil)
            if !self.sessionArtifacts.contains(where: { $0.title == artifact.title }) {
                self.sessionArtifacts.append((title: artifact.title, html: artifact.body, fileURL: nil))
            }
        }
    }

    private func handleVoiceSubmitChat(_ notif: Notification) {
        if let text = notif.object as? String, !text.isEmpty {
            self.promptText = text
        }
        handlePromptSubmit()
    }

    private func handleSearchBarAppendText(_ text: String) {
        if self.promptText.isEmpty {
            self.promptText = text
        } else if !self.promptText.hasSuffix(text) {
            self.promptText += " " + text
        }
    }

    private func handleFocusGenieSearchBarWithMode(_ mode: String) {
        if mode.hasPrefix("Help me with") || mode.hasPrefix("Summarize") || mode.contains(":") {
            self.promptText = mode
        }
    }

    private func handleKeyPress(_ press: KeyPress) -> KeyPress.Result {
        if press.characters == "\u{1b}" || press.key == .escape {
            if previewCreation != nil {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                    previewCreation = nil
                }
                HapticFeedback.selection()
                return .handled
            }
        }
        if press.modifiers.contains(.command) && (press.characters == "w" || press.characters == "W") {
            if previewCreation != nil {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                    previewCreation = nil
                }
                HapticFeedback.selection()
                return .handled
            }
        }
        if press.modifiers.contains(.command) && press.characters == "\\" {
            if previewCreation != nil {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                    isEditorCollapsed.toggle()
                }
                return .handled
            }
        }
        let isPlusOrEqual = press.characters == "+" || press.characters == "=" || press.key == KeyEquivalent("+") || press.key == KeyEquivalent("=")
        if press.modifiers.contains(.command) && isPlusOrEqual {
            withAnimation(.spring(response: 0.22, dampingFraction: 0.82)) {
                chatZoomLevel = min(2.50, chatZoomLevel + 0.10)
                let currentTS = UserDefaults.standard.double(forKey: PrefKey.textSize)
                let newTS = max(8.0, min(24.0, (currentTS > 0 ? currentTS : 11.0) + 1.0))
                UserDefaults.standard.set(newTS, forKey: PrefKey.textSize)
            }
            showStatusFeedback("Text & UI Scale: \(Int((chatZoomLevel * 100).rounded()))% (\(Int(UserDefaults.standard.double(forKey: PrefKey.textSize))) pt) 🔍+")
            HapticFeedback.selection()
            return .handled
        }
        let isMinusOrUnderscore = press.characters == "-" || press.characters == "_" || press.key == KeyEquivalent("-") || press.key == KeyEquivalent("_")
        if press.modifiers.contains(.command) && isMinusOrUnderscore {
            withAnimation(.spring(response: 0.22, dampingFraction: 0.82)) {
                chatZoomLevel = max(0.60, chatZoomLevel - 0.10)
                let currentTS = UserDefaults.standard.double(forKey: PrefKey.textSize)
                let newTS = max(8.0, min(24.0, (currentTS > 0 ? currentTS : 11.0) - 1.0))
                UserDefaults.standard.set(newTS, forKey: PrefKey.textSize)
            }
            showStatusFeedback("Text & UI Scale: \(Int((chatZoomLevel * 100).rounded()))% (\(Int(UserDefaults.standard.double(forKey: PrefKey.textSize))) pt) 🔍-")
            HapticFeedback.selection()
            return .handled
        }
        let isZero = press.characters == "0" || press.key == KeyEquivalent("0")
        if press.modifiers.contains(.command) && isZero {
            withAnimation(.spring(response: 0.22, dampingFraction: 0.82)) {
                chatZoomLevel = 1.0
                UserDefaults.standard.set(11.0, forKey: PrefKey.textSize)
            }
            showStatusFeedback("Text & UI Scale: 100% Reset (11 pt) 🔍")
            HapticFeedback.selection()
            return .handled
        }
        if press.modifiers.contains([.command, .shift]) && (press.characters == "C" || press.characters == "c") {
            if localModels.copyWholeChat() {
                showStatusFeedback("Copied whole chat to clipboard 📋")
            } else {
                showStatusFeedback("No messages in chat to copy ⚠️")
            }
            HapticFeedback.selection()
            return .handled
        }
        if press.modifiers.contains([.command, .shift]) && (press.characters == "V" || press.characters == "v") {
            let res = localModels.pasteWholeChat()
            if res.success {
                showStatusFeedback("Pasted whole chat (\(res.count) messages) 📋✨")
            } else {
                showStatusFeedback("No chat transcript in clipboard ⚠️")
            }
            return .handled
        }
        return .ignored
    }

    // MARK: - 🕒 In-Chat Integrated World Clock & Widgets Drawer
    @ViewBuilder
    private var inChatWidgetBarDrawer: some View {
        VStack(spacing: 6) {
            HStack(spacing: 12) {
                // Header Label
                HStack(spacing: 6) {
                    Image(systemName: "clock.fill")
                        .foregroundColor(.cyan)
                        .font(.system(size: 12, weight: .bold))
                    Text("In-Chat World Clock & Active Widgets")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                Spacer()

                // Hide/Close Button
                Button(action: {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        showInChatWidgets = false
                    }
                    HapticFeedback.selection()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.70))
                        .font(.system(size: 13))
                }
                .buttonStyle(.plain)
                .help("Close In-Chat Widgets Drawer")
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)

            WorldClockPaneView()
                .frame(maxHeight: 190)
                .clipped()
        }
        .padding(.bottom, 6)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(red: 0.08, green: 0.09, blue: 0.14).opacity(0.88))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.cyan.opacity(0.40), Color.white.opacity(0.12)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.8
                        )
                )
        )
        .padding(.horizontal, isEmbedded ? 8 : 14)
        .padding(.bottom, 6)
        .transition(.asymmetric(
            insertion: .move(edge: .top).combined(with: .opacity),
            removal: .move(edge: .top).combined(with: .opacity)
        ))
        .zIndex(250)
    }
}
