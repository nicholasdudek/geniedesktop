import AppKit
import SwiftUI
import WebKit
import AVKit
import Combine

// MARK: - AI Emotion Spectrum & Theme Presets
public enum AIEmotionType: String, CaseIterable, Identifiable {
    case mystical = "Mystical 🔮"
    case excited = "Electric Joy ⚡️"
    case creative = "Dreamer Aurora 🎨"
    case contemplative = "Deep Thought 🌌"
    case calm = "Zen Ocean 🌊"
    case warmth = "Golden Sunset 🌅"
    case matrix = "Cyber Neon 🟢"
    case empathy = "Heart Glow 💖"

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .mystical: return "Mystical Resonance"
        case .excited: return "High Voltage Excitement"
        case .creative: return "Creative Flow"
        case .contemplative: return "Deep Contemplation"
        case .calm: return "Tranquil Equilibrium"
        case .warmth: return "Radiant Warmth"
        case .matrix: return "Digital Synthesis"
        case .empathy: return "Empathetic Connection"
        }
    }

    public var gradientColors: [Color] {
        switch self {
        case .mystical:
            return [
                Color(red: 0.12, green: 0.05, blue: 0.28),
                Color(red: 0.18, green: 0.10, blue: 0.45),
                Color(red: 0.0, green: 0.65, blue: 0.85),
                Color(red: 0.05, green: 0.02, blue: 0.15)
            ]
        case .excited:
            return [
                Color(red: 0.35, green: 0.25, blue: 0.0),
                Color(red: 0.95, green: 0.70, blue: 0.05),
                Color(red: 0.0, green: 0.85, blue: 0.95),
                Color(red: 0.12, green: 0.08, blue: 0.02)
            ]
        case .creative:
            return [
                Color(red: 0.30, green: 0.04, blue: 0.25),
                Color(red: 0.75, green: 0.12, blue: 0.60),
                Color(red: 0.10, green: 0.75, blue: 0.65),
                Color(red: 0.08, green: 0.02, blue: 0.18)
            ]
        case .contemplative:
            return [
                Color(red: 0.04, green: 0.06, blue: 0.18),
                Color(red: 0.10, green: 0.15, blue: 0.38),
                Color(red: 0.28, green: 0.22, blue: 0.58),
                Color(red: 0.02, green: 0.03, blue: 0.10)
            ]
        case .calm:
            return [
                Color(red: 0.02, green: 0.14, blue: 0.22),
                Color(red: 0.05, green: 0.35, blue: 0.45),
                Color(red: 0.15, green: 0.65, blue: 0.75),
                Color(red: 0.01, green: 0.08, blue: 0.14)
            ]
        case .warmth:
            return [
                Color(red: 0.32, green: 0.08, blue: 0.04),
                Color(red: 0.85, green: 0.35, blue: 0.12),
                Color(red: 0.95, green: 0.65, blue: 0.25),
                Color(red: 0.15, green: 0.04, blue: 0.02)
            ]
        case .matrix:
            return [
                Color(red: 0.02, green: 0.16, blue: 0.06),
                Color(red: 0.05, green: 0.55, blue: 0.20),
                Color(red: 0.25, green: 0.95, blue: 0.45),
                Color(red: 0.01, green: 0.08, blue: 0.03)
            ]
        case .empathy:
            return [
                Color(red: 0.30, green: 0.05, blue: 0.15),
                Color(red: 0.85, green: 0.25, blue: 0.45),
                Color(red: 0.95, green: 0.55, blue: 0.75),
                Color(red: 0.12, green: 0.02, blue: 0.08)
            ]
        }
    }

    public var accentColor: Color {
        switch self {
        case .mystical: return .cyan
        case .excited: return .yellow
        case .creative: return .purple
        case .contemplative: return Color(red: 0.4, green: 0.5, blue: 1.0)
        case .calm: return .teal
        case .warmth: return .orange
        case .matrix: return .green
        case .empathy: return .pink
        }
    }
}

// MARK: - Supported Media Formats
public enum AIMediaMode: String, CaseIterable {
    case gradientShader = "Gradients & Shaders"
    case htmlAnimation = "HTML5 Canvas"
    case videoMovie = "Movie Loop (.mov / .mp4)"
    case imageGif = "Image & GIF (.gif / .png)"
    case webBrowser = "Live Web Browser 🌐"
    case terminal = "Interactive Terminal 💻"
}

// MARK: - Window Layout Modes: Split Screen vs Unsplit
public enum WindowLayoutMode: String, CaseIterable {
    case split = "split"
    case mediaOnly = "mediaOnly"
    case chatOnly = "chatOnly"

    public var title: String {
        switch self {
        case .split: return "Split Screen ◫"
        case .mediaOnly: return "Media Only 🎨"
        case .chatOnly: return "Chat Only 💬"
        }
    }

    public var icon: String {
        switch self {
        case .split: return "rectangle.split.2x1.fill"
        case .mediaOnly: return "paintpalette.fill"
        case .chatOnly: return "bubble.left.and.bubble.right.fill"
        }
    }
}

// MARK: - AI Emotion & Graphics Player Window View
public struct AIEmotionPlayerWindowView: View {
    @ObservedObject var localModels = LocalModelManager.shared
    @ObservedObject var miniBrowser = MiniBrowserManager.shared
    @AppStorage(PrefKey.aiEmotion) var selectedEmotionRaw: String = AIEmotionType.mystical.rawValue
    @AppStorage(PrefKey.aiMediaMode) var selectedMediaModeRaw: String = AIMediaMode.gradientShader.rawValue
    @AppStorage(PrefKey.showEmotionPlayer) var isVisible: Bool = true
    @AppStorage(PrefKey.emotionPlayerHeight) var playerHeight: Double = 160.0
    @AppStorage(PrefKey.playerWindowLayout) var windowLayoutRaw: String = WindowLayoutMode.chatOnly.rawValue

    @State private var isCollapsed: Bool = false
    @State private var customHtmlContent: String = defaultInteractiveHtml
    @State private var mediaUrl: URL? = nil
    @State private var isHovered: Bool = false
    @State private var pulsePhase: Double = 0.0

    private var currentLayout: WindowLayoutMode {
        get {
            WindowLayoutMode(rawValue: windowLayoutRaw) ?? .chatOnly
        }
        nonmutating set { windowLayoutRaw = newValue.rawValue }
    }

    private var currentEmotion: AIEmotionType {
        get {
            // Auto-detect emotion from model if active, or while generating, or user-selected
            if !localModels.activeEmotionRaw.isEmpty, let em = AIEmotionType(rawValue: localModels.activeEmotionRaw) {
                return em
            }
            if localModels.isGenerating {
                return .contemplative
            }
            return AIEmotionType(rawValue: selectedEmotionRaw) ?? .mystical
        }
    }

    private var currentMediaMode: AIMediaMode {
        get { AIMediaMode(rawValue: selectedMediaModeRaw) ?? .gradientShader }
        nonmutating set { selectedMediaModeRaw = newValue.rawValue }
    }

    public init() {}

    public var body: some View {
        if isVisible {
            VStack(spacing: 0) {
                // ── Top Navigation & Emotion Header ──
                HStack(spacing: 8) {
                    // Emotion Indicator Badge
                    HStack(spacing: 5) {
                        Circle()
                            .fill(currentEmotion.accentColor)
                            .frame(width: 8, height: 8)
                            .shadow(color: currentEmotion.accentColor, radius: 4)

                        Text(currentEmotion.rawValue)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.95))

                        if localModels.isGenerating {
                            Text("• Thinking...")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(currentEmotion.accentColor)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3.5)
                    .background(Capsule().fill(Color.white.opacity(0.12)))

                    // Live AI Browsing Telemetry (see what AI is searching & viewing)
                    if miniBrowser.isAIBrowsing {
                        HStack(spacing: 5) {
                            ProgressView().controlSize(.mini)
                            Text(miniBrowser.aiBrowsingStatus)
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(.cyan)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3.5)
                        .background(Capsule().fill(Color.cyan.opacity(0.18)))
                        .overlay(Capsule().stroke(Color.cyan.opacity(0.40), lineWidth: 0.75))
                    }

                    // Emotion Switcher Menu
                    Menu {
                        Section("AI Emotion Atmosphere") {
                            ForEach(AIEmotionType.allCases) { em in
                                let isSelected = (selectedEmotionRaw == em.rawValue)
                                Button(action: {
                                    HapticFeedback.selection()
                                    selectedEmotionRaw = em.rawValue
                                }) {
                                    Text(isSelected ? "\(em.rawValue) ✓" : em.rawValue)
                                }
                            }
                        }

                        Divider()

                        Section("Display Mode") {
                            ForEach(AIMediaMode.allCases, id: \.self) { mode in
                                let isModeSelected = (currentMediaMode == mode)
                                Button(action: {
                                    currentMediaMode = mode
                                    HapticFeedback.selection()
                                }) {
                                    Text(isModeSelected ? "\(mode.rawValue) ✓" : mode.rawValue)
                                }
                            }
                        }

                        Divider()

                        Button("Load Local Media File (.html, .mov, .gif, .png)... 📂") {
                            selectLocalMediaFile()
                        }
                    } label: {
                        HStack(spacing: 3) {
                            Text("Theme")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.70))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 8))
                                .foregroundColor(.white.opacity(0.50))
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.08)))
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()

                    Spacer()

                    // Active AI Creation Banner
                    if !localModels.activeCreationTitle.isEmpty && currentMediaMode == .htmlAnimation {
                        HStack(spacing: 5) {
                            Image(systemName: "paintpalette.fill")
                                .font(.system(size: 8.5))
                                .foregroundColor(.yellow)
                            Text(localModels.activeCreationTitle)
                                .font(.system(size: 9.5, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .lineLimit(1)

                            // Replay Creation
                            Button(action: {
                                let c = self.customHtmlContent
                                self.customHtmlContent = ""
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                    self.customHtmlContent = c
                                }
                                HapticFeedback.tick()
                            }) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 7.5))
                                    .foregroundColor(.white.opacity(0.85))
                            }
                            .buttonStyle(.plain)
                            .help("Replay AI Creation")

                            // Reset to Atmosphere
                            Button(action: {
                                self.currentMediaMode = .gradientShader
                                HapticFeedback.tick()
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 8))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .buttonStyle(.plain)
                            .help("Return to living atmosphere")
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2.5)
                        .background(Capsule().fill(Color.purple.opacity(0.35)))
                        .overlay(Capsule().stroke(Color.purple.opacity(0.55), lineWidth: 0.75))
                    }

                    quickModeSwitcherPills

                    layoutSwitcherPills

                    // Height Expand / Standard Toggle for Multi-Page Chat
                    Button(action: {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.80)) {
                            if playerHeight >= 480.0 {
                                playerHeight = 340.0
                            } else {
                                playerHeight = 520.0
                            }
                        }
                        HapticFeedback.selection()
                    }) {
                        Image(systemName: playerHeight >= 480.0 ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundColor(.white.opacity(0.65))
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(.plain)
                    .help(playerHeight >= 480.0 ? "Compact Height (340pt)" : "Expand Tall for Multi-Page Chat (520pt) 📄")

                    // Height Adjuster or Collapse
                    Button(action: {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                            isCollapsed.toggle()
                        }
                    }) {
                        Image(systemName: isCollapsed ? "chevron.down" : "chevron.up")
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundColor(.white.opacity(0.65))
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(.plain)
                    .help(isCollapsed ? "Expand Emotion Canvas" : "Collapse Emotion Canvas")

                    // Pop into Apple Finder Style Window
                    Button(action: {
                        HapticFeedback.heavy()
                        FinderChatWindowManager.shared.toggle()
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "macwindow.on.rectangle")
                                .font(.system(size: 8.5))
                            Text("Finder")
                                .font(.system(size: 9, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.cyan)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2.5)
                        .background(RoundedRectangle(cornerRadius: 4).fill(Color.cyan.opacity(0.18)))
                        .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.cyan.opacity(0.40), lineWidth: 0.5))
                    }
                    .buttonStyle(.plain)
                    .help("Open Chat & Creations in Apple Finder style window")

                    // Close Window Button
                    Button(action: {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.82)) {
                            isVisible = false
                        }
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white.opacity(0.50))
                            .frame(width: 20, height: 20)
                    }
                    .buttonStyle(.plain)
                    .help("Hide Emotion Window")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(Color.black.opacity(0.40))

                // ── Main Living Player & Chat Content Area ──
                if !isCollapsed {
                    Group {
                        switch currentLayout {
                        case .split:
                            HStack(spacing: 0) {
                                // Left: Media Canvas (Browser / Terminal / Shader / HTML5)
                                mediaCanvasContent
                                    .frame(minWidth: 260, maxWidth: .infinity, maxHeight: .infinity)
                                    .clipped()

                                // Vertical Apple Translucent Glowing Hairline
                                Rectangle()
                                    .fill(
                                        LinearGradient(
                                            stops: [
                                                .init(color: currentEmotion.accentColor.opacity(0.40), location: 0.0),
                                                .init(color: Color.white.opacity(0.18), location: 0.50),
                                                .init(color: currentEmotion.accentColor.opacity(0.40), location: 1.0)
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    .frame(width: 1)

                                // Right: Compact Chat Replies & Answers + Chat Management
                                CompactChatStreamView(emotion: currentEmotion)
                                    .frame(width: 360)
                                    .frame(maxHeight: .infinity)
                            }
                            .frame(height: max(340, CGFloat(playerHeight)))

                        case .mediaOnly:
                            mediaCanvasContent
                                .frame(height: CGFloat(playerHeight))
                                .clipped()

                        case .chatOnly:
                            CompactChatStreamView(emotion: currentEmotion)
                                .frame(height: max(320, CGFloat(playerHeight)))
                        }
                    }
                    .clipped()
                }
            }
            .frame(maxWidth: currentLayout == .split ? 860 : 660)
            .background(
                ZStack {
                    VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow, state: .active)
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.10, green: 0.11, blue: 0.16).opacity(0.92),
                                    Color(red: 0.05, green: 0.06, blue: 0.09).opacity(0.95)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            stops: [
                                .init(color: currentEmotion.accentColor.opacity(0.85), location: 0.0),
                                .init(color: Color.white.opacity(0.28), location: 0.40),
                                .init(color: currentEmotion.accentColor.opacity(0.45), location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.25
                    )
            )
            .shadow(color: currentEmotion.accentColor.opacity(0.35), radius: 28, x: 0, y: 10)
            .shadow(color: Color.black.opacity(0.70), radius: 18, x: 0, y: 6)
            .padding(.horizontal, 16)
            .padding(.bottom, 14) // Padding between emotion window and chat bar
            .transition(.scale(scale: 0.94).combined(with: .opacity))
            .onHover { h in isHovered = h }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusAIDisplayCreation"))) { notif in
                if let code = notif.object as? String, !code.isEmpty {
                    self.customHtmlContent = code
                    self.currentMediaMode = .htmlAnimation
                    if self.currentLayout == .chatOnly {
                        self.currentLayout = .split
                    }
                    self.isVisible = true
                    self.isCollapsed = false
                    self.playerHeight = max(self.playerHeight, 380.0)
                    HapticFeedback.selection()
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusAIThemeChanged"))) { notif in
                if let themeRaw = notif.object as? String, !themeRaw.isEmpty {
                    self.selectedEmotionRaw = themeRaw
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusOpenMiniBrowser"))) { _ in
                withAnimation(.spring(response: 0.30, dampingFraction: 0.75)) {
                    isVisible = true
                    isCollapsed = false
                    currentMediaMode = .webBrowser
                    if currentLayout == .chatOnly {
                        currentLayout = .split
                    }
                    playerHeight = max(playerHeight, 340.0)
                }
            }
        }
    }

    // MARK: - Header Bar Pills
    private var quickModeSwitcherPills: some View {
        HStack(spacing: 3) {
            Button(action: { currentMediaMode = .gradientShader; HapticFeedback.tick() }) {
                Image(systemName: "paintpalette.fill")
                    .font(.system(size: 9))
                    .foregroundColor(currentMediaMode == .gradientShader ? Color.white : Color.secondary)
                    .frame(width: 20, height: 20)
                    .background(RoundedRectangle(cornerRadius: 4).fill(currentMediaMode == .gradientShader ? Color.white.opacity(0.20) : Color.clear))
            }
            .buttonStyle(.plain)
            .help("Gradient & Shader Atmosphere")

            Button(action: { currentMediaMode = .htmlAnimation; HapticFeedback.tick() }) {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.system(size: 9))
                    .foregroundColor(currentMediaMode == .htmlAnimation ? Color.white : Color.secondary)
                    .frame(width: 20, height: 20)
                    .background(RoundedRectangle(cornerRadius: 4).fill(currentMediaMode == .htmlAnimation ? Color.white.opacity(0.20) : Color.clear))
            }
            .buttonStyle(.plain)
            .help("Interactive HTML5 Canvas Player")

            Button(action: { currentMediaMode = .videoMovie; HapticFeedback.tick() }) {
                Image(systemName: "play.rectangle.fill")
                    .font(.system(size: 9))
                    .foregroundColor(currentMediaMode == .videoMovie ? Color.white : Color.secondary)
                    .frame(width: 20, height: 20)
                    .background(RoundedRectangle(cornerRadius: 4).fill(currentMediaMode == .videoMovie ? Color.white.opacity(0.20) : Color.clear))
            }
            .buttonStyle(.plain)
            .help("Movie / Video Loop (.mov / .mp4)")

            Button(action: { currentMediaMode = .imageGif; HapticFeedback.tick() }) {
                Image(systemName: "photo.fill")
                    .font(.system(size: 9))
                    .foregroundColor(currentMediaMode == .imageGif ? Color.white : Color.secondary)
                    .frame(width: 20, height: 20)
                    .background(RoundedRectangle(cornerRadius: 4).fill(currentMediaMode == .imageGif ? Color.white.opacity(0.20) : Color.clear))
            }
            .buttonStyle(.plain)
            .help("Image & GIF Player")

            Button(action: {
                currentMediaMode = .webBrowser
                playerHeight = max(playerHeight, 320.0)
                HapticFeedback.tick()
            }) {
                Image(systemName: "globe")
                    .font(.system(size: 9))
                    .foregroundColor(currentMediaMode == .webBrowser ? Color.white : Color.secondary)
                    .frame(width: 20, height: 20)
                    .background(RoundedRectangle(cornerRadius: 4).fill(currentMediaMode == .webBrowser ? Color.cyan.opacity(0.40) : Color.clear))
            }
            .buttonStyle(.plain)
            .help("Live Web Browser & Internet Search 🌐")

            Button(action: {
                currentMediaMode = .terminal
                playerHeight = max(playerHeight, 260.0)
                HapticFeedback.tick()
            }) {
                Image(systemName: "terminal.fill")
                    .font(.system(size: 9))
                    .foregroundColor(currentMediaMode == .terminal ? Color.white : Color.secondary)
                    .frame(width: 20, height: 20)
                    .background(RoundedRectangle(cornerRadius: 4).fill(currentMediaMode == .terminal ? Color.green.opacity(0.40) : Color.clear))
            }
            .buttonStyle(.plain)
            .help("Interactive Terminal & Shell Runner 💻")
        }
    }

    private var layoutSwitcherPills: some View {
        HStack(spacing: 2) {
            Button(action: {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                    currentLayout = (currentLayout == .chatOnly) ? .mediaOnly : .chatOnly
                    playerHeight = max(playerHeight, 320.0)
                }
                HapticFeedback.selection()
            }) {
                let isChatOnly = (currentLayout == .chatOnly)
                HStack(spacing: 3) {
                    Image(systemName: isChatOnly ? "bubble.left.and.bubble.right.fill" : "paintpalette.fill")
                        .font(.system(size: 8))
                    Text(isChatOnly ? "Chat" : "Media")
                        .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                    if isChatOnly && !localModels.chatHistory.isEmpty {
                        Text("\(localModels.chatHistory.count)")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(Color.white)
                            .padding(.horizontal, 3.5)
                            .padding(.vertical, 0.5)
                            .background(Capsule().fill(Color.cyan.opacity(0.7)))
                    }
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 3.5)
                .background(RoundedRectangle(cornerRadius: 4).fill(isChatOnly ? Color.cyan.opacity(0.35) : Color.white.opacity(0.08)))
                .foregroundColor(Color.white)
            }
            .buttonStyle(.plain)
            .help(currentLayout == .chatOnly ? "Switch to Visual Media Canvas" : "Switch to Chat Stream")
        }
        .padding(2)
        .background(RoundedRectangle(cornerRadius: 6).fill(Color.black.opacity(0.35)))
        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.12), lineWidth: 0.5))
    }

    // MARK: - Media Canvas Content
    @ViewBuilder
    private var mediaCanvasContent: some View {
        ZStack {
            switch currentMediaMode {
            case .gradientShader:
                livingAtmosphereCanvas(emotion: currentEmotion)
            case .htmlAnimation:
                GenieCreationDualTabPreviewView(
                    title: localModels.activeCreationTitle.isEmpty ? "HTML Creation" : localModels.activeCreationTitle,
                    rawHtml: customHtmlContent,
                    emotion: currentEmotion,
                    onClose: {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                            currentMediaMode = .gradientShader
                        }
                    }
                )
            case .videoMovie:
                MovieLoopPlayerView(videoUrl: mediaUrl)
            case .imageGif:
                ImageGifPlayerView(imageUrl: mediaUrl, emotion: currentEmotion)
            case .webBrowser:
                MiniWebBrowserCanvasView()
            case .terminal:
                EmbeddedTerminalCanvasView()
            }
        }
    }

    // MARK: - Living Atmosphere Gradient & Particle Engine
    @ViewBuilder
    private func livingAtmosphereCanvas(emotion: AIEmotionType) -> some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let colors = emotion.gradientColors

            ZStack {
                // Multi-Stop Undulating Gradient Mesh
                LinearGradient(
                    colors: colors,
                    startPoint: UnitPoint(x: 0.5 + sin(time * 0.4) * 0.4, y: 0.0),
                    endPoint: UnitPoint(x: 0.5 - sin(time * 0.4) * 0.4, y: 1.0)
                )

                // Living Aurora / Radial Caustic Glow
                RadialGradient(
                    colors: [emotion.accentColor.opacity(localModels.isGenerating ? 0.65 : 0.40), Color.clear],
                    center: UnitPoint(x: 0.5 + cos(time * 0.6) * 0.35, y: 0.5 + sin(time * 0.8) * 0.25),
                    startRadius: 10,
                    endRadius: 220
                )

                RadialGradient(
                    colors: [Color.white.opacity(0.25), Color.clear],
                    center: UnitPoint(x: 0.5 - cos(time * 0.5) * 0.30, y: 0.5 - sin(time * 0.7) * 0.20),
                    startRadius: 5,
                    endRadius: 160
                )

                // Subtitle / Mood Description
                VStack(spacing: 4) {
                    Spacer()
                    HStack {
                        Text(emotion.title.uppercased())
                            .font(.system(size: 9.5, weight: .bold, design: .rounded))
                            .tracking(2.5)
                            .foregroundColor(.white.opacity(0.70))
                            .shadow(color: .black.opacity(0.6), radius: 2)

                        Spacer()

                        Text("SYNAPSE SPECTRUM")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(emotion.accentColor.opacity(0.85))
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 8)
                }
            }
        }
    }

    // MARK: - Open File Panel for Custom Media
    private func selectLocalMediaFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.html, .movie, .quickTimeMovie, .mpeg4Movie, .gif, .png, .jpeg]
        panel.title = "Select HTML, Video (.mov/.mp4), GIF or Image for AI Emotion Canvas"

        if panel.runModal() == .OK, let url = panel.url {
            self.mediaUrl = url
            let ext = url.pathExtension.lowercased()
            if ext == "html" || ext == "htm" {
                if let str = try? String(contentsOf: url, encoding: .utf8) {
                    self.customHtmlContent = str
                    self.currentMediaMode = .htmlAnimation
                }
            } else if ext == "mov" || ext == "mp4" || ext == "m4v" {
                self.currentMediaMode = .videoMovie
            } else if ext == "gif" || ext == "png" || ext == "jpg" || ext == "jpeg" || ext == "webp" {
                self.currentMediaMode = .imageGif
            }
            HapticFeedback.selection()
        }
    }

    // Default built-in interactive HTML emotion canvas
    private static var defaultInteractiveHtml: String {
        """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <style>
        body, html {
            margin: 0; padding: 0; width: 100%; height: 100%;
            overflow: hidden; background: transparent;
            display: flex; align-items: center; justify-content: center;
        }
        canvas { width: 100%; height: 100%; display: block; }
        </style>
        </head>
        <body>
        <canvas id="c"></canvas>
        <script>
        const c = document.getElementById('c');
        const ctx = c.getContext('2d');
        let W = c.width = window.innerWidth;
        let H = c.height = window.innerHeight;
        window.onresize = () => { W = c.width = window.innerWidth; H = c.height = window.innerHeight; };

        let particles = [];
        for(let i=0; i<45; i++) {
            particles.push({
                x: Math.random() * W,
                y: Math.random() * H,
                vx: (Math.random() - 0.5) * 1.5,
                vy: (Math.random() - 0.5) * 1.5,
                r: Math.random() * 3.5 + 1.5,
                hue: Math.random() * 60 + 170
            });
        }

        let t = 0;
        function draw() {
            t += 0.02;
            ctx.clearRect(0, 0, W, H);
            
            // Soft glowing links between particles
            for(let i=0; i<particles.length; i++) {
                let p = particles[i];
                p.x += p.vx; p.y += p.vy;
                if(p.x < 0) p.x = W; if(p.x > W) p.x = 0;
                if(p.y < 0) p.y = H; if(p.y > H) p.y = 0;

                ctx.beginPath();
                ctx.arc(p.x, p.y, p.r + Math.sin(t + i)*0.8, 0, Math.PI*2);
                ctx.fillStyle = `hsla(${p.hue + Math.sin(t)*30}, 85%, 65%, 0.8)`;
                ctx.fill();

                for(let j=i+1; j<particles.length; j++) {
                    let p2 = particles[j];
                    let d = Math.hypot(p.x - p2.x, p.y - p2.y);
                    if(d < 95) {
                        ctx.beginPath();
                        ctx.moveTo(p.x, p.y);
                        ctx.lineTo(p2.x, p2.y);
                        ctx.strokeStyle = `hsla(${p.hue}, 80%, 60%, ${(1 - d/95)*0.35})`;
                        ctx.lineWidth = 0.9;
                        ctx.stroke();
                    }
                }
            }
            requestAnimationFrame(draw);
        }
        draw();
        </script>
        </body>
        </html>
        """
    }
}

// MARK: - Native WebKit HTML View Representable
public struct InteractiveHtmlWebView: NSViewRepresentable {
    public let htmlString: String
    public let emotionColorHex: String
    public var customBaseURL: URL? = nil

    private var effectiveBaseURL: URL {
        GenieWebAssetResolver.effectiveBaseURL(for: customBaseURL)
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    public final class Coordinator {
        var lastLoadedHtml: String = ""
        var isInitialLoaded: Bool = false
    }

    public func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")
        config.defaultWebpagePreferences.allowsContentJavaScript = true
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground") // Transparent background

        let effectiveHtml = LivePreviewFrameRetainer.shared.update(html: htmlString)
        context.coordinator.lastLoadedHtml = effectiveHtml
        context.coordinator.isInitialLoaded = true
        let baseURL = effectiveBaseURL
        webView.loadHTMLString(effectiveHtml.isEmpty ? "<!DOCTYPE html><html><body style='background:transparent;'></body></html>" : effectiveHtml, baseURL: baseURL)
        return webView
    }

    public func updateNSView(_ nsView: WKWebView, context: Context) {
        let effectiveHtml = LivePreviewFrameRetainer.shared.update(html: htmlString)
        guard !effectiveHtml.isEmpty else { return }

        if context.coordinator.lastLoadedHtml != effectiveHtml {
            context.coordinator.lastLoadedHtml = effectiveHtml
            let baseURL = effectiveBaseURL

            if context.coordinator.isInitialLoaded {
                // In-place document write prevents flashing white / destroying scroll position
                if let data = try? JSONSerialization.data(withJSONObject: [effectiveHtml]),
                   let jsonArray = String(data: data, encoding: .utf8) {
                    let js = """
                    (() => {
                        try {
                            const html = (\(jsonArray))[0];
                            document.open();
                            document.write(html);
                            document.close();
                        } catch (e) {
                            console.error("Live HTML update failed:", e);
                            throw e;
                        }
                    })();
                    """
                    nsView.evaluateJavaScript(js) { _, err in
                        if err != nil {
                            nsView.loadHTMLString(effectiveHtml, baseURL: baseURL)
                        }
                    }
                } else {
                    nsView.loadHTMLString(effectiveHtml, baseURL: baseURL)
                }
            } else {
                context.coordinator.isInitialLoaded = true
                nsView.loadHTMLString(effectiveHtml, baseURL: baseURL)
            }
        }
    }
}

// MARK: - Movie / Video Loop Player View (.mov / .mp4)
public struct MovieLoopPlayerView: NSViewRepresentable {
    public let videoUrl: URL?

    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    public final class Coordinator: NSObject {
        var loopObserver: NSObjectProtocol?
        deinit {
            if let obs = loopObserver {
                NotificationCenter.default.removeObserver(obs)
            }
        }
    }

    public func makeNSView(context: Context) -> AVPlayerView {
        let playerView = AVPlayerView()
        playerView.controlsStyle = .none
        playerView.showsFullScreenToggleButton = false

        if let url = videoUrl {
            let player = AVPlayer(url: url)
            player.actionAtItemEnd = .none
            context.coordinator.loopObserver = NotificationCenter.default.addObserver(
                forName: AVPlayerItem.didPlayToEndTimeNotification,
                object: player.currentItem,
                queue: .main
            ) { [weak player] _ in
                player?.seek(to: .zero)
                player?.play()
            }
            playerView.player = player
            player.play()
        }
        return playerView
    }

    public func updateNSView(_ nsView: AVPlayerView, context: Context) {
        if let url = videoUrl, nsView.player?.currentItem == nil {
            let player = AVPlayer(url: url)
            player.actionAtItemEnd = .none
            if let oldObs = context.coordinator.loopObserver {
                NotificationCenter.default.removeObserver(oldObs)
            }
            context.coordinator.loopObserver = NotificationCenter.default.addObserver(
                forName: AVPlayerItem.didPlayToEndTimeNotification,
                object: player.currentItem,
                queue: .main
            ) { [weak player] _ in
                player?.seek(to: .zero)
                player?.play()
            }
            nsView.player = player
            player.play()
        }
    }

    public static func dismantleNSView(_ nsView: AVPlayerView, coordinator: Coordinator) {
        if let obs = coordinator.loopObserver {
            NotificationCenter.default.removeObserver(obs)
            coordinator.loopObserver = nil
        }
        nsView.player?.pause()
        nsView.player = nil
    }
}

// MARK: - Image / GIF Player View
public struct ImageGifPlayerView: View {
    public let imageUrl: URL?
    public let emotion: AIEmotionType

    public var body: some View {
        ZStack {
            if let url = imageUrl {
                GenieAnimatedImageView(
                    url: url,
                    scaling: .scaleProportionallyUpOrDown,
                    animates: true
                )
                .padding(8)
            } else {
                // Dynamic Emotion Emblem Placeholder
                VStack(spacing: 8) {
                    Image(systemName: "sparkles.tv")
                        .font(.system(size: 32))
                        .foregroundColor(emotion.accentColor)
                        .shadow(color: emotion.accentColor, radius: 8)

                    Text("Drop or Select any .gif, .png, .jpg, .mov or .html file")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.70))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - 🌐 Live Mini Web Browser Canvas View
public struct MiniWebBrowserCanvasView: View {
    @ObservedObject var miniBrowser = MiniBrowserManager.shared
    @ObservedObject var chromeBookmarks = ChromeBookmarksManager.shared

    public var body: some View {
        VStack(spacing: 0) {
            // Mini Browser Address & Navigation Ribbon
            HStack(spacing: 6) {
                // Back / Forward / Reload Buttons
                Button(action: { miniBrowser.goBack(); HapticFeedback.tick() }) {
                    Image(systemName: "chevron.backward")
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundColor(miniBrowser.canGoBack ? .white : .secondary.opacity(0.4))
                }
                .buttonStyle(.plain)
                .disabled(!miniBrowser.canGoBack)

                Button(action: { miniBrowser.goForward(); HapticFeedback.tick() }) {
                    Image(systemName: "chevron.forward")
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundColor(miniBrowser.canGoForward ? .white : .secondary.opacity(0.4))
                }
                .buttonStyle(.plain)
                .disabled(!miniBrowser.canGoForward)

                Button(action: { miniBrowser.reload(); HapticFeedback.tick() }) {
                    Image(systemName: miniBrowser.isLoading ? "xmark" : "arrow.clockwise")
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundColor(.white.opacity(0.85))
                }
                .buttonStyle(.plain)

                // URL / Search Display Bar
                HStack(spacing: 5) {
                    Image(systemName: "globe")
                        .font(.system(size: 8.5))
                        .foregroundColor(.cyan)

                    Text(miniBrowser.currentURL?.absoluteString ?? "https://www.google.com")
                        .font(.system(size: 9.5, design: .monospaced))
                        .foregroundColor(.white.opacity(0.90))
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Spacer()

                    if miniBrowser.isLoading {
                        ProgressView().controlSize(.mini)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule().fill(Color.black.opacity(0.55)))
                .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.5))

                // Chrome Integration Menu (Launch in Google Chrome / Chrome App Window)
                Menu {
                    Button(action: {
                        if let u = miniBrowser.currentURL {
                            chromeBookmarks.openInChrome(url: u)
                        }
                    }) {
                        Label("Open Tab in Google Chrome", systemImage: "arrow.up.forward.app")
                    }

                    Button(action: {
                        if let u = miniBrowser.currentURL {
                            chromeBookmarks.openChromeAppMode(url: u)
                        }
                    }) {
                        Label("Launch Standalone Chrome App Window", systemImage: "macwindow")
                    }

                    Divider()

                    Button(action: {
                        chromeBookmarks.loadBookmarks()
                    }) {
                        Label("Reload Chrome Bookmarks", systemImage: "arrow.clockwise")
                    }
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 9))
                        Text("Chrome")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.yellow)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Color.yellow.opacity(0.18)))
                    .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.yellow.opacity(0.40), lineWidth: 0.5))
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                .help("Google Chrome Bookmarks & Launch Options")

                // Open in Default Web Browser (Chrome / Safari)
                Button(action: {
                    miniBrowser.openInDefaultBrowser()
                    HapticFeedback.selection()
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.up.forward.app")
                        Text("Default")
                    }
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Color.cyan.opacity(0.16)))
                }
                .buttonStyle(.plain)
                .help("Open in default web browser")
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.black.opacity(0.50))

            // ── CHROME BOOKMARKS BAR (Direct from ~/Library/Application Support/Google/Chrome/Default/Bookmarks) ──
            if !chromeBookmarks.bookmarkBarItems.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 5) {
                        HStack(spacing: 3) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 7.5))
                                .foregroundColor(.yellow)
                            Text("Bookmarks:")
                                .font(.system(size: 8.5, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.55))
                        }
                        .padding(.trailing, 2)

                        ForEach(chromeBookmarks.bookmarkBarItems) { item in
                            if item.isFolder {
                                Menu {
                                    ForEach(item.children) { child in
                                        Button(action: {
                                            if let u = URL(string: child.url) {
                                                miniBrowser.browse(url: u)
                                            }
                                        }) {
                                            Label(child.name, systemImage: child.faviconIcon)
                                        }
                                    }
                                } label: {
                                    HStack(spacing: 3) {
                                        Image(systemName: "folder.fill")
                                            .font(.system(size: 8))
                                            .foregroundColor(.yellow.opacity(0.85))
                                        Text(item.name)
                                            .font(.system(size: 9, weight: .medium, design: .rounded))
                                        Image(systemName: "chevron.down")
                                            .font(.system(size: 6))
                                    }
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2.5)
                                    .background(Capsule().fill(Color.white.opacity(0.08)))
                                    .foregroundColor(.white.opacity(0.85))
                                }
                                .menuStyle(.borderlessButton)
                                .fixedSize()
                            } else {
                                Button(action: {
                                    if let u = URL(string: item.url) {
                                        miniBrowser.browse(url: u)
                                        HapticFeedback.selection()
                                    }
                                }) {
                                    HStack(spacing: 3.5) {
                                        Image(systemName: item.faviconIcon)
                                            .font(.system(size: 8))
                                            .foregroundColor(.cyan)
                                        Text(item.name)
                                            .font(.system(size: 9, weight: .medium, design: .rounded))
                                            .lineLimit(1)
                                    }
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 2.5)
                                    .background(Capsule().fill(Color.white.opacity(0.08)))
                                    .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.5))
                                    .foregroundColor(.white.opacity(0.85))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3.5)
                }
                .background(Color.black.opacity(0.35))
            }

            Divider().opacity(0.3)

            // Live Interactive WebKit View
            MiniWebKitRepresentable()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// MARK: - Native WebKit Representable for Mini Browser (With Chrome Spoof & Google Botguard Bypass)
public struct MiniWebKitRepresentable: NSViewRepresentable {
    @ObservedObject var miniBrowser = MiniBrowserManager.shared
    @AppStorage(PrefKey.browserEngineMode) var browserEngineMode: String = "Chrome (Botguard Bypass ⚡️)"

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        // Persistent Web Data Store: remembers cookies, sessions, and site storage!
        config.websiteDataStore = WKWebsiteDataStore.default()
        config.preferences.javaScriptCanOpenWindowsAutomatically = true
        config.defaultWebpagePreferences.allowsContentJavaScript = true

        // ── Google Botguard & Chrome Runtime Emulation Script ──
        let bypassScriptSource = """
        (function() {
            try {
                Object.defineProperty(navigator, 'vendor', { get: () => 'Google Inc.' });
            } catch(e) {}
            try {
                window.chrome = {
                    app: { isInstalled: false, InstallState: { DISABLED: 'disabled', INSTALLED: 'installed', NOT_INSTALLED: 'not_installed' }, RunningState: { CANNOT_RUN: 'cannot_run', READY_TO_RUN: 'ready_to_run', RUNNING: 'running' } },
                    runtime: {
                        OnInstalledReason: { CHROME_UPDATE: 'chrome_update', INSTALL: 'install', SHARED_MODULE_UPDATE: 'shared_module_update', UPDATE: 'update' },
                        OnRestartRequiredReason: { APP_UPDATE: 'app_update', OS_UPDATE: 'os_update', PERIODIC: 'periodic' },
                        PlatformArch: { ARM: 'arm', ARM64: 'arm64', MIPS: 'mips', MIPS64: 'mips64', X86_32: 'x86-32', X86_64: 'x86-64' },
                        PlatformNaclArch: { ARM: 'arm', MIPS: 'mips', MIPS64: 'mips64', X86_32: 'x86-32', X86_64: 'x86-64' },
                        PlatformOs: { ANDROID: 'android', CROS: 'cros', LINUX: 'linux', MAC: 'mac', OPENBSD: 'openbsd', WIN: 'win' },
                        RequestUpdateCheckStatus: { NO_UPDATE: 'no_update', THROTTLED: 'throttled', UPDATE_AVAILABLE: 'update_available' }
                    },
                    loadTimes: function() {
                        return {
                            requestTime: (window.performance ? window.performance.timing.navigationStart : Date.now()) / 1000,
                            startLoadTime: (window.performance ? window.performance.timing.navigationStart : Date.now()) / 1000,
                            commitLoadTime: (window.performance ? window.performance.timing.responseStart : Date.now()) / 1000,
                            finishDocumentLoadTime: (window.performance ? window.performance.timing.domContentLoadedEventEnd : Date.now()) / 1000,
                            finishLoadTime: (window.performance ? window.performance.timing.loadEventEnd : Date.now()) / 1000,
                            firstPaintTime: (window.performance ? window.performance.timing.responseStart : Date.now()) / 1000,
                            firstPaintAfterLoadTime: 0,
                            navigationType: 'Other',
                            wasFetchedViaSpdy: true,
                            wasNpnNegotiated: true,
                            npnNegotiatedProtocol: 'h2',
                            wasAlternateProtocolAvailable: false,
                            connectionInfo: 'h2'
                        };
                    },
                    csi: function() { return { startE: Date.now(), onloadT: Date.now(), pageT: 0, tran: 15 }; }
                };
            } catch(e) {}
            try {
                const brands = [
                    { brand: 'Google Chrome', version: '133' },
                    { brand: 'Chromium', version: '133' },
                    { brand: 'Not_A Brand', version: '24' }
                ];
                Object.defineProperty(navigator, 'userAgentData', {
                    get: () => ({
                        brands: brands,
                        mobile: false,
                        platform: 'macOS',
                        getHighEntropyValues: (hints) => Promise.resolve({
                            brands: brands,
                            mobile: false,
                            platform: 'macOS',
                            platformVersion: '15.3.1',
                            architecture: 'arm',
                            model: '',
                            bitness: '64'
                        })
                    })
                });
            } catch(e) {}
            try {
                Object.defineProperty(navigator, 'webdriver', { get: () => false });
            } catch(e) {}
        })();
        """
        let userScript = WKUserScript(source: bypassScriptSource, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        config.userContentController.addUserScript(userScript)

        let webView = WKWebView(frame: .zero, configuration: config)
        if browserEngineMode.contains("Safari") {
            webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.3 Safari/605.1.15"
        } else if browserEngineMode.contains("VM") || browserEngineMode.contains("Sandbox") {
            webView.customUserAgent = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36"
        } else {
            webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36"
        }
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        miniBrowser.activeWebView = webView

        let url = miniBrowser.currentURL ?? URL(string: "https://www.google.com")!
        webView.load(URLRequest(url: url))
        return webView
    }

    public func updateNSView(_ nsView: WKWebView, context: Context) {
        miniBrowser.activeWebView = nsView
    }

    public class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
        var parent: MiniWebKitRepresentable

        init(_ parent: MiniWebKitRepresentable) {
            self.parent = parent
        }

        // ── WKUIDelegate: Handle OAuth and Popup Windows in Same WebView ──
        public func webView(
            _ webView: WKWebView,
            createWebViewWith configuration: WKWebViewConfiguration,
            for navigationAction: WKNavigationAction,
            windowFeatures: WKWindowFeatures
        ) -> WKWebView? {
            if navigationAction.targetFrame == nil {
                webView.load(navigationAction.request)
            }
            return nil
        }

        public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.miniBrowser.isLoading = true
                self.parent.miniBrowser.canGoBack = webView.canGoBack
                self.parent.miniBrowser.canGoForward = webView.canGoForward
            }
        }

        public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.miniBrowser.isLoading = false
                self.parent.miniBrowser.canGoBack = webView.canGoBack
                self.parent.miniBrowser.canGoForward = webView.canGoForward
                if let url = webView.url {
                    self.parent.miniBrowser.currentURL = url
                }
                if let title = webView.title, !title.isEmpty {
                    self.parent.miniBrowser.pageTitle = title
                }
            }
        }

        public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.miniBrowser.isLoading = false
            }
        }

        public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.miniBrowser.isLoading = false
            }
        }
    }
}

// MARK: - 💻 Embedded Terminal Canvas View
public struct EmbeddedTerminalCanvasView: View {
    @State private var terminalInput: String = ""
    @State private var terminalHistory: [String] = [
        "Genie Terminal Console v2.0 (macOS zsh)",
        "Type any shell command below and press Return, or run AI terminal tool commands.",
        "--------------------------------------------------"
    ]
    @State private var isRunning: Bool = false
    @FocusState private var isFieldFocused: Bool
    @State private var cursorBlink: Bool = true
    @AppStorage(PrefKey.showCheatSheet) var showCheatSheet: Bool = false

    private let quickCommands = [
        "git status",
        "ls -la",
        "top -l 1 | head -n 15",
        "brew update",
        "python3 --version",
        "df -h",
        "ping -c 3 8.8.8.8",
        "whoami",
        "uname -a"
    ]

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header bar
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    Circle().fill(Color.red.opacity(0.85)).frame(width: 7, height: 7)
                    Circle().fill(Color.yellow.opacity(0.85)).frame(width: 7, height: 7)
                    Circle().fill(Color.green.opacity(0.85)).frame(width: 7, height: 7)
                }

                Text("zsh — login shell")
                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.85))

                Spacer()

                // Hidable Cheat Sheet Toggle
                Button(action: {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                        showCheatSheet.toggle()
                    }
                    HapticFeedback.selection()
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "lightbulb.fill")
                            .font(.system(size: 8.5))
                        Text("Cheat Sheet")
                            .font(.system(size: 8.5, weight: .semibold))
                    }
                    .foregroundColor(showCheatSheet ? .yellow : .secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2.5)
                    .background(Capsule().fill(showCheatSheet ? Color.yellow.opacity(0.18) : Color.white.opacity(0.06)))
                }
                .buttonStyle(.plain)
                .help("Toggle Terminal Quick Command Cheat Sheet (Hidable) 💡")

                Button("Clear") {
                    terminalHistory.removeAll()
                }
                .font(.system(size: 9))
                .buttonStyle(.plain)
                .foregroundColor(.secondary)

                Button("Terminal.app ↗") {
                    LocalModelManager.shared.openInTerminalApp(command: terminalInput.isEmpty ? "cd ~ && ls -la" : terminalInput)
                }
                .font(.system(size: 9, weight: .medium))
                .buttonStyle(.plain)
                .foregroundColor(.cyan)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.black.opacity(0.60))

            // Hidable Quick Commands Bar
            if showCheatSheet {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 5) {
                        ForEach(quickCommands, id: \.self) { cmd in
                            Button(action: {
                                terminalInput = cmd
                                isFieldFocused = true
                                HapticFeedback.selection()
                            }) {
                                Text(cmd)
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundColor(.green.opacity(0.95))
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(Color.green.opacity(0.12)))
                                    .overlay(Capsule().stroke(Color.green.opacity(0.25), lineWidth: 0.5))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                }
                .background(Color(red: 0.05, green: 0.07, blue: 0.10).opacity(0.95))
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            Divider().opacity(0.3)

            // Terminal log scroll
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 3) {
                        ForEach(Array(terminalHistory.enumerated()), id: \.offset) { idx, line in
                            Text(line)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(line.hasPrefix("$") ? .green : (line.hasPrefix("Execution error") ? .red : .white.opacity(0.92)))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .id(idx)
                        }
                    }
                    .padding(8)
                }
                .background(Color(red: 0.04, green: 0.05, blue: 0.08).opacity(0.95))
                .onChange(of: terminalHistory.count) { _, _ in
                    proxy.scrollTo(terminalHistory.count - 1, anchor: .bottom)
                }
            }

            Divider().opacity(0.3)

            // Command input row with active blinking cursor
            HStack(spacing: 6) {
                Text("$")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.green)

                HStack(spacing: 1) {
                    TextField("Enter command (e.g. ls -la, git status, python3)...", text: $terminalInput)
                        .font(.system(size: 10.5, design: .monospaced))
                        .textFieldStyle(.plain)
                        .foregroundColor(.white)
                        .focused($isFieldFocused)
                        .onSubmit {
                            executeCommand()
                        }

                    Text("█")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.green)
                        .opacity(cursorBlink ? 0.95 : 0.0)
                        .animation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true), value: cursorBlink)
                }

                if isRunning {
                    ProgressView().controlSize(.mini)
                } else {
                    Button(action: { executeCommand() }) {
                        Text("Run ⚡️")
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundColor(.black)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2.5)
                            .background(Capsule().fill(Color.green))
                    }
                    .buttonStyle(.plain)
                    .disabled(terminalInput.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.70))
        }
        .onAppear {
            isFieldFocused = true
            cursorBlink = true
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusTerminalCommandExecuted"))) { notif in
            if let cmdInfo = notif.object as? (command: String, output: String) {
                terminalHistory.append("$ \(cmdInfo.command)")
                terminalHistory.append(cmdInfo.output.isEmpty ? "(No output)" : cmdInfo.output)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusExecuteTerminalCommand"))) { notif in
            if let cmd = notif.object as? String {
                self.terminalInput = cmd
                self.executeCommand()
            }
        }
    }

    private func executeCommand() {
        let cmd = terminalInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cmd.isEmpty else { return }
        isRunning = true
        terminalHistory.append("$ \(cmd)")
        terminalInput = ""

        Task {
            let res = await LocalModelManager.shared.executeTerminalCommand(cmd)
            await MainActor.run {
                terminalHistory.append(res.output.isEmpty ? "(Process finished with exit code \(res.exitCode))" : res.output)
                isRunning = false
            }
        }
    }
}

// MARK: - Color Extension Helper
extension Color {
    func toHex() -> String {
        guard let components = NSColor(self).usingColorSpace(.sRGB)?.cgColor.components, components.count >= 3 else {
            return "#00E5FF"
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }
}

// MARK: - Interactive Web Search & Link Tool Card (Browser DOM Retrieval Upgraded)
public struct WebToolCardView: View {
    let queryOrUrl: String
    @ObservedObject private var retrieval = GenieBrowserDOMRetrievalManager.shared
    @State private var isHovered: Bool = false
    @State private var isExpanded: Bool = false

    private var isURL: Bool {
        queryOrUrl.hasPrefix("http://") || queryOrUrl.hasPrefix("https://")
    }

    private var item: GenieRetrievedWebItem? {
        retrieval.retrievedItems[queryOrUrl]
    }

    public init(queryOrUrl: String) {
        self.queryOrUrl = queryOrUrl
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Main clickable bar
            HStack(spacing: 8) {
                // Leading: Thumbnail Image or Site Favicon/Icon
                leadingMediaThumbnail

                // Center: Domain badge, Decoded Title, and DOM Telemetry
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 5) {
                        Text(item?.domain.isEmpty == false ? item!.domain : (isURL ? "Web Link" : "Internet Search"))
                            .font(.system(size: 8.5, weight: .bold, design: .rounded))
                            .foregroundColor(.cyan.opacity(0.90))

                        if let count = item?.domElementsCount, count > 0 {
                            Text("• \(count) DOM items")
                                .font(.system(size: 8, weight: .medium, design: .monospaced))
                                .foregroundColor(.cyan.opacity(0.70))
                        }

                        if let latency = item?.latencyMs, latency > 0 {
                            Text("• \(Int(latency))ms")
                                .font(.system(size: 8, weight: .medium, design: .monospaced))
                                .foregroundColor(.white.opacity(0.40))
                        }

                        if item?.isSearching == true {
                            ProgressView()
                                .controlSize(.mini)
                                .scaleEffect(0.6)
                        }
                    }

                    Text(item?.title.isEmpty == false ? item!.title : queryOrUrl)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.95))
                        .lineLimit(isExpanded ? 3 : 1)

                    if !isExpanded, let snippet = item?.snippet, !snippet.isEmpty {
                        Text(snippet)
                            .font(.system(size: 9.5, weight: .regular))
                            .foregroundColor(.white.opacity(0.65))
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 4)

                // Trailing actions
                HStack(spacing: 5) {
                    // Expand/collapse snippet toggle
                    if let snippet = item?.snippet, !snippet.isEmpty {
                        Button(action: {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                isExpanded.toggle()
                            }
                            HapticFeedback.tick()
                        }) {
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 8.5, weight: .bold))
                                .foregroundColor(.white.opacity(0.70))
                                .frame(width: 20, height: 20)
                                .background(Circle().fill(Color.white.opacity(0.08)))
                        }
                        .buttonStyle(.plain)
                        .help(isExpanded ? "Collapse Details" : "Expand Summary")
                    }

                    // Open Button
                    Button(action: {
                        HapticFeedback.selection()
                        if isURL, let url = URL(string: queryOrUrl) {
                            MiniBrowserManager.shared.browse(url: url)
                        } else {
                            MiniBrowserManager.shared.search(query: queryOrUrl)
                        }
                        NotificationCenter.default.post(
                            name: NSNotification.Name("NexusOpenMiniBrowser"),
                            object: queryOrUrl
                        )
                    }) {
                        HStack(spacing: 3) {
                            Text(isURL ? "Open" : "Search")
                                .font(.system(size: 9.5, weight: .semibold))
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 8, weight: .bold))
                        }
                        .foregroundColor(.cyan)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3.5)
                        .background(Capsule().fill(Color.cyan.opacity(isHovered ? 0.30 : 0.16)))
                    }
                    .buttonStyle(.plain)
                }
            }

            // Expanded Detail View: Rich Summary & DOM Inspector Controls
            if isExpanded {
                VStack(alignment: .leading, spacing: 6) {
                    Divider().opacity(0.18)

                    if let snippet = item?.snippet, !snippet.isEmpty {
                        Text(snippet)
                            .font(.system(size: 10, weight: .regular))
                            .foregroundColor(.white.opacity(0.85))
                            .lineSpacing(2)
                    }

                    HStack(spacing: 8) {
                        // DOM Inspector Button
                        Button(action: {
                            HapticFeedback.selection()
                            if isURL, let url = URL(string: queryOrUrl) {
                                MiniBrowserManager.shared.browse(url: url)
                            } else {
                                MiniBrowserManager.shared.search(query: queryOrUrl)
                            }
                            NotificationCenter.default.post(
                                name: NSNotification.Name("NexusOpenMiniBrowser"),
                                object: queryOrUrl
                            )
                            Task {
                                try? await Task.sleep(nanoseconds: 600_000_000)
                                _ = await GenieHTMLBrowserDOMWatcherEngine.shared.scanLiveDOM()
                            }
                        }) {
                            Label("Inspect DOM", systemImage: "bolt.horizontal.fill")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(.cyan)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color.cyan.opacity(0.15)))
                        }
                        .buttonStyle(.plain)

                        // Copy Link/Query
                        Button(action: {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(queryOrUrl, forType: .string)
                            HapticFeedback.tick()
                        }) {
                            Label("Copy Link", systemImage: "doc.on.doc")
                                .font(.system(size: 9, weight: .semibold))
                                .foregroundColor(.white.opacity(0.70))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color.white.opacity(0.08)))
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        // Raw URL or Query
                        Text(queryOrUrl)
                            .font(.system(size: 8.5, design: .monospaced))
                            .foregroundColor(.white.opacity(0.40))
                            .lineLimit(1)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.black.opacity(isHovered ? 0.45 : 0.35))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.cyan.opacity(isHovered ? 0.50 : 0.25), lineWidth: 0.6)
                )
        )
        .onHover { h in isHovered = h }
        .onAppear {
            retrieval.retrieve(queryOrUrl: queryOrUrl)
        }
    }

    @ViewBuilder
    private var leadingMediaThumbnail: some View {
        if let previewURL = item?.previewImageURL, let img = retrieval.cachedImage(for: previewURL) {
            Image(nsImage: img)
                .resizable()
                .scaledToFill()
                .frame(width: isExpanded ? 52 : 36, height: isExpanded ? 52 : 36)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.20), lineWidth: 0.5)
                )
        } else if let previewURL = item?.previewImageURL, let url = URL(string: previewURL) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: isExpanded ? 52 : 36, height: isExpanded ? 52 : 36)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.20), lineWidth: 0.5)
                        )
                default:
                    fallbackIconBadge
                }
            }
        } else {
            fallbackIconBadge
        }
    }

    private var fallbackIconBadge: some View {
        ZStack {
            Circle()
                .fill(Color.cyan.opacity(isHovered ? 0.35 : 0.18))
                .frame(width: 24, height: 24)
            Image(systemName: isURL ? "link" : "globe")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.cyan)
        }
    }
}

// MARK: - Compact Chat Stream & Management View (Transparent Apple Style)
public struct CompactChatStreamView: View {
    let emotion: AIEmotionType
    var showHeader: Bool
    @ObservedObject var localModels = LocalModelManager.shared
    @ObservedObject var appearanceDetector = GenieSystemAppearanceDetector.shared
    @AppStorage(PrefKey.isTerminalBannerVisible) private var isTerminalBannerVisible: Bool = true
    @AppStorage(PrefKey.chatZoomLevel) private var chatZoomLevel: Double = 1.0
    @State private var isThinkingExpanded: Bool = false
    @State private var autoScrollEnabled: Bool = true
    @State private var expandedMessageIDs: Set<UUID> = []
    @State private var statusFeedback: String? = nil
    @State private var feedbackTimer: Timer? = nil

    public init(emotion: AIEmotionType, showHeader: Bool = false) {
        self.emotion = emotion
        self.showHeader = showHeader
    }

    private func zoomIn() {
        withAnimation(.spring(response: 0.22, dampingFraction: 0.82)) {
            chatZoomLevel = min(2.0, (chatZoomLevel + 0.10))
        }
        HapticFeedback.selection()
    }

    private func zoomOut() {
        withAnimation(.spring(response: 0.22, dampingFraction: 0.82)) {
            chatZoomLevel = max(0.70, (chatZoomLevel - 0.10))
        }
        HapticFeedback.selection()
    }

    private func resetZoom() {
        withAnimation(.spring(response: 0.22, dampingFraction: 0.82)) {
            chatZoomLevel = 1.0
        }
        HapticFeedback.selection()
    }

    // MARK: - 🎛️ Terminal Slide Drawer Handle & Chat Zoom Controls Bar
    private var terminalAndZoomControlBar: some View {
        HStack(spacing: 6) {
            // Terminal Slide Toggle
            Button(action: {
                HapticFeedback.selection()
                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                    isTerminalBannerVisible.toggle()
                }
            }) {
                HStack(spacing: 5) {
                    Image(systemName: "terminal.fill")
                        .font(.system(size: 8.5))
                        .foregroundColor(.cyan)
                    Text("Terminal Shell")
                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.85))
                    Text("100% LOCAL")
                        .font(.system(size: 7.5, weight: .heavy, design: .monospaced))
                        .foregroundColor(.green.opacity(0.85))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(Color.green.opacity(0.18)))
                    Image(systemName: isTerminalBannerVisible ? "chevron.up" : "chevron.down")
                        .font(.system(size: 7.5, weight: .bold))
                        .foregroundColor(.white.opacity(0.60))
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Capsule().fill(Color.white.opacity(0.06)))
                .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.5))
            }
            .buttonStyle(.plain)
            .help(isTerminalBannerVisible ? "Slide up Terminal Shell (leaves messages in place)" : "Slide down Terminal Shell & quick actions")

            Spacer()

            // ↕️ Slide drawer grip handle
            Capsule()
                .fill(Color.white.opacity(0.26))
                .frame(width: 28, height: 3.5)
                .help("Drag up/down to slide Terminal Shell")

            Spacer()

            // 📋 Copy & Paste Whole Chat Pills
            HStack(spacing: 3) {
                Button(action: {
                    if localModels.copyWholeChat() {
                        showFeedback("Copied whole chat! 📋")
                    } else {
                        showFeedback("No messages to copy!")
                    }
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 7.5))
                        Text("Copy")
                            .font(.system(size: 8.5, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white.opacity(0.75))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2.5)
                    .background(Capsule().fill(Color.white.opacity(0.08)))
                }
                .buttonStyle(.plain)
                .help("Copy Whole Chat (⌘⇧C)")

                Button(action: {
                    let res = localModels.pasteWholeChat()
                    if res.success {
                        showFeedback("Pasted whole chat (\(res.count) msgs) 📋✨")
                    } else {
                        showFeedback("No chat transcript on clipboard ⚠️")
                    }
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "doc.on.clipboard")
                            .font(.system(size: 7.5))
                        Text("Paste")
                            .font(.system(size: 8.5, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2.5)
                    .background(Capsule().fill(Color.cyan.opacity(0.14)))
                }
                .buttonStyle(.plain)
                .help("Paste Whole Chat (⌘⇧V)")
            }
            .padding(.horizontal, 3)
            .padding(.vertical, 2)
            .background(Capsule().fill(Color.white.opacity(0.04)))
            .overlay(Capsule().stroke(Color.white.opacity(0.10), lineWidth: 0.5))

            // ⚡ Real-Time Token Generation Speed Telemetry (tkps)
            if localModels.lastTokensPerSecond > 0 || localModels.isGenerating {
                HStack(spacing: 2.5) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundColor(localModels.isGenerating ? .yellow : .cyan)
                    Text(String(format: "%.1f tkps", localModels.lastTokensPerSecond))
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(localModels.isGenerating ? .yellow : .white.opacity(0.90))
                }
                .padding(.horizontal, 5)
                .padding(.vertical, 2.5)
                .background(Capsule().fill(Color.white.opacity(0.06)))
                .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.5))
                .help("Generation Speed: \(String(format: "%.1f", localModels.lastTokensPerSecond)) tokens/second")
            }

            // 🔍 Live Chat Zoom In / Zoom Out Controls
            HStack(spacing: 3) {
                Button(action: zoomOut) {
                    Image(systemName: "minus")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white.opacity(0.70))
                        .frame(width: 17, height: 17)
                        .background(Circle().fill(Color.white.opacity(0.08)))
                }
                .buttonStyle(.plain)
                .keyboardShortcut("-", modifiers: .command)
                .help("Zoom Out (⌘-)")

                Button(action: resetZoom) {
                    Text("\(Int((chatZoomLevel * 100).rounded()))%")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(chatZoomLevel != 1.0 ? .cyan : .white.opacity(0.75))
                        .frame(minWidth: 32)
                }
                .buttonStyle(.plain)
                .keyboardShortcut("0", modifiers: .command)
                .help("Reset Zoom to 100% (⌘0)")

                Button(action: zoomIn) {
                    Image(systemName: "plus")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white.opacity(0.70))
                        .frame(width: 17, height: 17)
                        .background(Circle().fill(Color.white.opacity(0.08)))
                }
                .buttonStyle(.plain)
                .keyboardShortcut("+", modifiers: .command)
                .help("Zoom In (⌘+)")
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(Capsule().fill(Color.white.opacity(0.06)))
            .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.5))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 3)
        .background(Color.black.opacity(0.20))
        .gesture(
            DragGesture(minimumDistance: 10)
                .onEnded { value in
                    if value.translation.height < -15 && isTerminalBannerVisible {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                            isTerminalBannerVisible = false
                        }
                        HapticFeedback.selection()
                    } else if value.translation.height > 15 && !isTerminalBannerVisible {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                            isTerminalBannerVisible = true
                        }
                        HapticFeedback.selection()
                    }
                }
        )
    }

    public var body: some View {
        VStack(spacing: 0) {
            // ── 🍎 Authentic Apple Menu Bar Inside Chat ──
            GenieChatAppleMenuBarView()

            // ── Chat Management Header Bar (Optional) ──
            if showHeader {
                chatManagementHeader
            }

            // ── 📟 Slideable Terminal Shell & Quick Actions Drawer ──
            // Anchored in place above messages so scrollbar only scrolls messages below it
            if isTerminalBannerVisible {
                GenieTerminalSplashView(compact: !localModels.chatHistory.isEmpty, onDismiss: {
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        isTerminalBannerVisible = false
                    }
                })
                .gesture(
                    DragGesture(minimumDistance: 20)
                        .onEnded { value in
                            if value.translation.height < -25 {
                                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                                    isTerminalBannerVisible = false
                                }
                                HapticFeedback.selection()
                            }
                        }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }

            // ── 🎛️ Terminal Slide Drawer Handle & Chat Zoom Controls Bar ──
            terminalAndZoomControlBar

            // ── Scrollable Chat Messages Stream (Scrollbar breaks here, leaving terminal in place) ──
            GeometryReader { geo in
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: true) {
                        LazyVStack(spacing: 10) {
                            Color.clear.frame(height: 6)

                            if localModels.chatHistory.isEmpty && !localModels.isGenerating {
                                if !isTerminalBannerVisible {
                                    VStack(spacing: 10) {
                                        Image(systemName: "sparkles")
                                            .font(.system(size: 24))
                                            .foregroundColor(.cyan.opacity(0.7))
                                        Text("Ask Genie anything or tap Terminal Shell above to view quick tools")
                                            .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                                            .foregroundColor(.white.opacity(0.55))
                                            .multilineTextAlignment(.center)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.top, 40)
                                    .padding(.horizontal, 24)
                                }
                            } else {
                                ForEach(localModels.chatHistory) { msg in
                                    compactMessageBubble(for: msg)
                                        .id(msg.id.uuidString)
                                        .trackChatRenderFocus(message: msg, space: "genieChatScroll")
                                }

                                if localModels.isGenerating {
                                    compactActiveGeneratingBubble
                                        .id("active-generating-bubble")
                                } else if !localModels.currentResponse.isEmpty && localModels.chatHistory.last?.content != localModels.currentResponse {
                                    compactMessageBubble(for: ChatMessage(role: "assistant", content: localModels.currentResponse, model: localModels.selectedModelDisplayName))
                                        .id("streaming-fallback")
                                }
                            }

                            // Always render 3 lines of space in chat to fix rendering delay
                            Color.clear.frame(height: 54)
                                .id("bottom-anchor")
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .frame(width: max(100, geo.size.width / CGFloat(chatZoomLevel)))
                        .scaleEffect(CGFloat(chatZoomLevel), anchor: .top)
                        .animation(.spring(response: 0.22, dampingFraction: 0.82), value: chatZoomLevel)
                    }
                    .genieThickScrollBars()
                    .publishFocusedChatRender(space: "genieChatScroll") { localModels.chatHistory }
                    .simultaneousGesture(
                        MagnificationGesture()
                            .onChanged { value in
                                let delta = value - 1.0
                                chatZoomLevel = min(2.0, max(0.70, chatZoomLevel + Double(delta) * 0.04))
                            }
                    )
                    .overlay(alignment: .bottomTrailing) {
                        HStack(spacing: 4) {
                            if localModels.isGenerating {
                                Button(action: {
                                    autoScrollEnabled.toggle()
                                    HapticFeedback.selection()
                                }) {
                                    HStack(spacing: 3) {
                                        Image(systemName: autoScrollEnabled ? "lock.fill" : "lock.open.fill")
                                            .font(.system(size: 7.5, weight: .bold))
                                        Text(autoScrollEnabled ? "Auto-Scroll" : "Free Scroll")
                                            .font(.system(size: 8, weight: .medium, design: .rounded))
                                    }
                                    .foregroundColor(autoScrollEnabled ? .cyan : .secondary)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3.5)
                                    .background(Capsule().fill(Color.black.opacity(0.75)))
                                    .overlay(Capsule().stroke(autoScrollEnabled ? Color.cyan.opacity(0.4) : Color.white.opacity(0.20), lineWidth: 0.5))
                                }
                                .buttonStyle(.plain)
                                .help("Toggle auto-scrolling during response generation")
                            }

                            if localModels.chatHistory.count > 4 || localModels.isGenerating {
                                Button(action: {
                                    autoScrollEnabled = true
                                    withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                                        proxy.scrollTo("bottom-anchor", anchor: .bottom)
                                    }
                                    HapticFeedback.tick()
                                }) {
                                    HStack(spacing: 3) {
                                        Image(systemName: "arrow.down.to.line")
                                            .font(.system(size: 8, weight: .bold))
                                        Text("Latest")
                                            .font(.system(size: 8.5, weight: .semibold, design: .rounded))
                                    }
                                    .foregroundColor(.white.opacity(0.9))
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3.5)
                                    .background(Capsule().fill(Color.black.opacity(0.70)))
                                    .overlay(Capsule().stroke(Color.white.opacity(0.20), lineWidth: 0.5))
                                    .shadow(color: Color.black.opacity(0.35), radius: 4, y: 2)
                                }
                                .buttonStyle(.plain)
                                .help("Scroll to latest message")
                            }
                        }
                        .padding(.trailing, 10)
                        .padding(.bottom, 6)
                    }
                    .onChange(of: localModels.chatHistory.count) { _, _ in
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                            proxy.scrollTo("bottom-anchor", anchor: .bottom)
                        }
                    }
                    .onChange(of: localModels.currentResponse) { _, _ in
                        if autoScrollEnabled {
                            proxy.scrollTo("bottom-anchor", anchor: .bottom)
                        }
                    }
                    .onAppear {
                        proxy.scrollTo("bottom-anchor", anchor: .bottom)
                    }
                }
            }

            // ── Status feedback badge (if active) ──
            if let fb = statusFeedback {
                HStack(spacing: 5) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.green)
                    Text(fb)
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.black.opacity(0.85)))
                .overlay(Capsule().stroke(Color.white.opacity(0.20), lineWidth: 0.5))
                .padding(.bottom, 4)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .background(Color.clear)
        .onKeyPress { press in
            if press.modifiers.contains([.command, .shift]) && (press.characters == "C" || press.characters == "c") {
                if localModels.copyWholeChat() {
                    showFeedback("Copied whole chat! 📋")
                } else {
                    showFeedback("No messages to copy!")
                }
                return .handled
            }
            if press.modifiers.contains([.command, .shift]) && (press.characters == "V" || press.characters == "v") {
                let res = localModels.pasteWholeChat()
                if res.success {
                    showFeedback("Pasted whole chat (\(res.count) msgs) 📋✨")
                } else {
                    showFeedback("No chat transcript on clipboard ⚠️")
                }
                return .handled
            }
            return .ignored
        }
    }

    // MARK: - Chat Management Header
    private var chatManagementHeader: some View {
        HStack(spacing: 5) {
            // Chat & Count badge
            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(emotion.accentColor)

                Text("Chat")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("\(localModels.chatHistory.count)")
                    .font(.system(size: 8.5, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.horizontal, 4.5)
                    .padding(.vertical, 1)
                    .background(Capsule().fill(Color.white.opacity(0.14)))
            }

            // Model Switcher Pill Menu
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
                HStack(spacing: 3) {
                    Image(systemName: localModels.activeProvider.icon)
                        .font(.system(size: 8))
                        .foregroundColor(localModels.activeProvider.badgeColor)
                    Text(localModels.selectedModelDisplayName)
                        .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 7))
                        .foregroundColor(.white.opacity(0.50))
                }
                .padding(.horizontal, 5)
                .padding(.vertical, 2.5)
                .background(Capsule().fill(Color.white.opacity(0.08)))
                .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 0.5))
            }
            .menuStyle(.borderlessButton)
            .fixedSize()

            // Open in Finder Style Window
            Button(action: {
                HapticFeedback.heavy()
                FinderChatWindowManager.shared.toggle()
            }) {
                Image(systemName: "macwindow.on.rectangle")
                    .font(.system(size: 8.5))
                    .foregroundColor(.cyan)
                    .padding(3.5)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Color.cyan.opacity(0.18)))
            }
            .buttonStyle(.plain)
            .help("Open Chat & Creations in Apple Finder style window")

            Spacer()

            // New Chat Button
            Button(action: {
                localModels.clearChatHistory()
                HapticFeedback.selection()
                showFeedback("New Chat Started! ✨")
            }) {
                HStack(spacing: 2.5) {
                    Image(systemName: "plus.bubble.fill")
                        .font(.system(size: 8.5))
                    Text("New")
                        .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 5.5)
                .padding(.vertical, 3)
                .background(RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.12)))
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.white.opacity(0.2), lineWidth: 0.5))
            }
            .buttonStyle(.plain)
            .help("Start a fresh conversation")

            // Clear Button
            Button(action: {
                localModels.clearChatHistory()
                HapticFeedback.tick()
                showFeedback("Chat Cleared 🧹")
            }) {
                Image(systemName: "trash")
                    .font(.system(size: 8.5))
                    .foregroundColor(.white.opacity(0.65))
                    .frame(width: 19, height: 19)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.08)))
            }
            .buttonStyle(.plain)
            .help("Clear chat messages")

            // Save Note Button (Pops up saved .rtf on screen!)
            Button(action: {
                saveChatToNote()
            }) {
                HStack(spacing: 2.5) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 8.5))
                    Text("Note")
                        .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.cyan)
                .padding(.horizontal, 5.5)
                .padding(.vertical, 3)
                .background(RoundedRectangle(cornerRadius: 4).fill(Color.cyan.opacity(0.16)))
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.cyan.opacity(0.35), lineWidth: 0.5))
            }
            .buttonStyle(.plain)
            .help("Save conversation to Genie Note & open in TextEdit")

            // Name Chat Button — lets the user give the session a custom name
            Button(action: { nameChatSession() }) {
                HStack(spacing: 2.5) {
                    Image(systemName: "tag.fill")
                        .font(.system(size: 8.5))
                    Text("Name")
                        .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.yellow)
                .padding(.horizontal, 5.5)
                .padding(.vertical, 3)
                .background(RoundedRectangle(cornerRadius: 4).fill(Color.yellow.opacity(0.14)))
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.yellow.opacity(0.35), lineWidth: 0.5))
            }
            .buttonStyle(.plain)
            .help("Give this chat session a name")

            // View Chat in Browser — generate full HTML transcript & open in Safari
            Button(action: { viewChatInBrowser() }) {
                HStack(spacing: 2.5) {
                    Image(systemName: "safari.fill")
                        .font(.system(size: 8.5))
                    Text("Browser")
                        .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.orange)
                .padding(.horizontal, 5.5)
                .padding(.vertical, 3)
                .background(RoundedRectangle(cornerRadius: 4).fill(Color.orange.opacity(0.14)))
                .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.orange.opacity(0.35), lineWidth: 0.5))
            }
            .buttonStyle(.plain)
            .help("Open this chat as a formatted HTML page in Safari")

            // Copy All Button
            Button(action: {
                copyFullTranscript()
            }) {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 8.5))
                    .foregroundColor(.white.opacity(0.75))
                    .frame(width: 19, height: 19)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.08)))
            }
            .buttonStyle(.plain)
            .help("Copy whole chat transcript to clipboard (⌘⇧C)")

            // Paste All Button
            Button(action: {
                pasteFullTranscript()
            }) {
                Image(systemName: "doc.on.clipboard")
                    .font(.system(size: 8.5))
                    .foregroundColor(.cyan.opacity(0.85))
                    .frame(width: 19, height: 19)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Color.cyan.opacity(0.12)))
            }
            .buttonStyle(.plain)
            .help("Paste whole chat from clipboard (⌘⇧V)")

            // Stop Generation Button
            if localModels.isGenerating {
                Button(action: {
                    localModels.stopGeneration()
                    HapticFeedback.tick()
                }) {
                    HStack(spacing: 2) {
                        Image(systemName: "stop.fill").font(.system(size: 7.5))
                        Text("Stop").font(.system(size: 8.5, weight: .bold))
                    }
                    .foregroundColor(.orange)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2.5)
                    .background(Capsule().fill(Color.orange.opacity(0.20)))
                    .overlay(Capsule().stroke(Color.orange.opacity(0.4), lineWidth: 0.5))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 5.5)
        .background(Color.black.opacity(0.35))
    }

    // MARK: - Transparent Floating Glass Message Bubbles
    @ViewBuilder
    private func compactMessageBubble(for msg: ChatMessage) -> some View {
        let isUser = (msg.role == "user")
        let isShort = isUser && msg.content.count <= 28 && !msg.content.contains("\n")

        HStack(alignment: .bottom, spacing: 8) {
            if isUser { Spacer(minLength: 40) }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                // Header (sender avatar/sparkle, title, time, copy, note, trash)
                HStack(spacing: 5) {
                    if !isUser {
                        let isClaudeOrGemma = msg.model.lowercased().contains("claude") || msg.model.lowercased().contains("gemma") || localModels.selectedModelDisplayName.lowercased().contains("claude") || localModels.selectedModelDisplayName.lowercased().contains("gemma")
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [emotion.accentColor.opacity(0.35), Color.cyan.opacity(0.20)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 16, height: 16)
                            Image(systemName: isClaudeOrGemma ? "circle.hexagongrid.fill" : "sparkles")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(isClaudeOrGemma ? Color(red: 0.95, green: 0.70, blue: 0.60) : emotion.accentColor)
                        }

                        Text(msg.model.isEmpty ? localModels.selectedModelDisplayName : msg.model)
                            .font(.system(size: 9.5, weight: .bold, design: .rounded))
                            .foregroundColor(isClaudeOrGemma ? Color(red: 0.95, green: 0.70, blue: 0.60) : .white.opacity(0.92))
                    } else {
                        ZStack {
                            Circle()
                                .fill(LinearGradient(colors: [Color.cyan.opacity(0.35), Color.blue.opacity(0.25)], startPoint: .topLeading, endPoint: .bottomTrailing))
                                .frame(width: 16, height: 16)
                            Image(systemName: "person.fill")
                                .font(.system(size: 7.5, weight: .bold))
                                .foregroundColor(.cyan)
                        }

                        Text("You")
                            .font(.system(size: 9.5, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.92))
                    }

                    Text(formattedTime(msg.timestamp))
                        .font(.system(size: 8, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.40))

                    if !isUser && msg.id == localModels.chatHistory.last(where: { $0.role != "user" })?.id && localModels.lastTokensPerSecond > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 6))
                            Text(String(format: "%.1f tkps", localModels.lastTokensPerSecond))
                                .font(.system(size: 7.5, weight: .semibold, design: .monospaced))
                        }
                        .foregroundColor(.cyan.opacity(0.85))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(Color.cyan.opacity(0.12)))
                        .help("Generation Speed: \(String(format: "%.1f", localModels.lastTokensPerSecond)) tokens/second")
                    }

                    if !isUser {
                        Spacer()
                    }

                    // Floating Glass Message Actions
                    HStack(spacing: 3) {
                        // Copy Button
                        Button(action: {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(msg.content, forType: .string)
                            HapticFeedback.selection()
                            showFeedback("Copied")
                        }) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 8))
                                .foregroundColor(.white.opacity(0.60))
                                .padding(3)
                                .background(Circle().fill(Color.white.opacity(0.08)))
                        }
                        .buttonStyle(.plain)
                        .help("Copy message")

                        // Save Note
                        if !isUser {
                            Button(action: {
                                _ = DesktopNotePrinter.shared.printNote(content: msg.content, openInFile: true)
                                HapticFeedback.success()
                                showFeedback("Saved to Note")
                            }) {
                                Image(systemName: "doc.text.fill")
                                    .font(.system(size: 7.5))
                                    .foregroundColor(.cyan.opacity(0.80))
                                    .padding(3)
                                    .background(Circle().fill(Color.cyan.opacity(0.12)))
                            }
                            .buttonStyle(.plain)
                            .help("Save to Genie Note")
                        }

                        // Delete turn
                        Button(action: {
                            localModels.deleteMessage(id: msg.id)
                            HapticFeedback.tick()
                        }) {
                            Image(systemName: "trash")
                                .font(.system(size: 7.5))
                                .foregroundColor(.white.opacity(0.35))
                                .padding(3)
                                .background(Circle().fill(Color.white.opacity(0.06)))
                        }
                        .buttonStyle(.plain)
                        .help("Delete message")
                    }
                }

                // Bubble Content (Markdown Message View)
                if isUser {
                    VStack(alignment: .trailing, spacing: 6) {
                        if let mp = msg.mediaPath {
                            let fileURL = URL(fileURLWithPath: mp)
                            GenieImageCardView(
                                url: fileURL,
                                altText: nil,
                                maxDisplayHeight: 220
                            )
                            .frame(maxWidth: 280)
                        }

                        if !msg.content.isEmpty {
                            Text(msg.content)
                                .font(.system(size: appearanceDetector.scaledPoint(13.0, userZoom: chatZoomLevel), weight: .medium, design: .rounded))
                                .foregroundColor(.white)
                                .textSelection(.enabled)
                        }
                    }
                    .padding(.horizontal, isShort && msg.mediaPath == nil ? 14 : 16)
                    .padding(.vertical, isShort && msg.mediaPath == nil ? 7 : 10)
                        .background(
                            ZStack {
                                if isShort {
                                    Capsule()
                                        .fill(appearanceDetector.folderBubbleGradient)
                                } else {
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(appearanceDetector.folderBubbleGradient)
                                }
                            }
                        )
                        .overlay(
                            ZStack {
                                if isShort {
                                    Capsule()
                                        .strokeBorder(
                                            appearanceDetector.folderSpecularHighlight,
                                            lineWidth: 0.85
                                        )
                                } else {
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .strokeBorder(
                                            appearanceDetector.folderSpecularHighlight,
                                            lineWidth: 0.85
                                        )
                                }
                            }
                        )
                        .shadow(color: appearanceDetector.folderBlueBottom.opacity(0.38), radius: 8, y: 3)
                } else {
                    let isExpanded = expandedMessageIDs.contains(msg.id)
                    let isLongMessage = msg.content.count > 450 || msg.content.components(separatedBy: "\n").count > 10

                    VStack(alignment: .leading, spacing: 4) {
                        if isLongMessage && !isExpanded {
                            ScrollView(.vertical, showsIndicators: true) {
                                GenieMarkdownMessageView(text: msg.content)
                                    .padding(.horizontal, 13)
                                    .padding(.vertical, 10)
                            }
                            .frame(maxHeight: 240)
                        } else {
                            GenieMarkdownMessageView(text: msg.content)
                                .padding(.horizontal, 13)
                                .padding(.vertical, 10)
                        }

                        if isLongMessage {
                            HStack {
                                Spacer()
                                Button(action: {
                                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                                        if isExpanded {
                                            expandedMessageIDs.remove(msg.id)
                                        } else {
                                            expandedMessageIDs.insert(msg.id)
                                        }
                                    }
                                    HapticFeedback.selection()
                                }) {
                                    HStack(spacing: 3.5) {
                                        Image(systemName: isExpanded ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                                            .font(.system(size: 8, weight: .bold))
                                        Text(isExpanded ? "Compact" : "Expand Message")
                                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                                    }
                                    .foregroundColor(appearanceDetector.folderBlueTop)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Capsule().fill(appearanceDetector.folderBlueTop.opacity(0.14)))
                                }
                                .buttonStyle(.plain)
                                .padding(.trailing, 10)
                                .padding(.bottom, 6)
                            }
                        }
                    }
                    .background(
                        ZStack {
                            VisualEffectBlur(material: .popover, blendingMode: .withinWindow, state: .active)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            appearanceDetector.assistantBubbleGradient
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(
                                appearanceDetector.assistantSpecularHighlight,
                                lineWidth: 0.85
                            )
                    )
                    .shadow(color: Color.black.opacity(0.35), radius: 12, x: 0, y: 5)
                }

                // Interactive Claude / Local Code Artifact Card
                if !isUser, let artifact = extractCodeArtifact(from: msg.content) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "curlybraces")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.cyan)
                            Text("Artifact — \(artifact.language.capitalized)")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Spacer()
                            Button("Copy") {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(artifact.code, forType: .string)
                                showFeedback("Artifact Copied")
                            }
                            .font(.system(size: 9, weight: .semibold))
                            .buttonStyle(.plain)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2.5)
                            .background(Capsule().fill(Color.white.opacity(0.12)))

                            Button("Open in Editor") {
                                let tabMgr = WorkspaceTabManager.shared
                                if let edTab = tabMgr.tabs.first(where: { $0.type == .editor }) {
                                    tabMgr.selectTab(id: edTab.id)
                                    tabMgr.updateEditor(content: artifact.code)
                                } else {
                                    tabMgr.createTab(type: .editor, title: "\(artifact.language.capitalized) Snippet")
                                    tabMgr.updateEditor(content: artifact.code)
                                }
                                showFeedback("Opened in Code Editor")
                            }
                            .font(.system(size: 9, weight: .semibold))
                            .buttonStyle(.plain)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2.5)
                            .background(Capsule().fill(Color.orange.opacity(0.22)))
                            .foregroundColor(.orange)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color.black.opacity(0.35))

                        ScrollView(.vertical) {
                            Text(artifact.code)
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.white.opacity(0.92))
                                .padding(8)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(maxHeight: 200)
                    }
                    .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.black.opacity(0.40)))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(Color(red: 0.85, green: 0.47, blue: 0.36).opacity(0.35), lineWidth: 0.8)
                    )
                    .padding(.top, 2)
                }


                // Interactive Terminal Tools in bubble
                if !isUser && localModels.terminalAccessEnabled {
                    let terminalCommands = localModels.extractAllTerminalCommands(from: msg.content)
                    if !terminalCommands.isEmpty {
                        VStack(alignment: .leading, spacing: 5) {
                            ForEach(terminalCommands, id: \.self) { cmd in
                                TerminalToolCardView(command: cmd)
                            }
                        }
                        .padding(.top, 2)
                    }
                }

                // Interactive Web Searches / Links in bubble
                if !isUser && localModels.webAccessEnabled {
                    let searches = localModels.extractAllWebSearches(from: msg.content)
                    let urls = localModels.extractAllWebURLs(from: msg.content)
                    if !searches.isEmpty || !urls.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(searches, id: \.self) { s in
                                WebToolCardView(queryOrUrl: s)
                            }
                            ForEach(urls, id: \.self) { u in
                                WebToolCardView(queryOrUrl: u.absoluteString)
                            }
                        }
                        .padding(.top, 2)
                    }
                }

                // Interactive AI Creation Card (HTML Canvas / SVG / Interactive Demo)
                if !isUser, let creation = localModels.extractCreation(from: msg.content) {
                    let safeTitle: String = {
                        let cleaned = creation.title
                            .components(separatedBy: CharacterSet.alphanumerics.inverted)
                            .filter { !$0.isEmpty }
                            .joined(separator: " ")
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                        return cleaned.isEmpty ? "AI Creation" : cleaned
                    }()
                    let fileOnDesktop = FileManager.default.homeDirectoryForCurrentUser
                        .appendingPathComponent("Desktop")
                        .appendingPathComponent("\(safeTitle).html")

                    VStack(alignment: .leading, spacing: 4) {
                        Button(action: {
                            localModels.activeCreationCode = creation.html
                            localModels.activeCreationTitle = creation.title

                            // Auto-write to Desktop so file exists on disk
                            try? creation.html.write(to: fileOnDesktop, atomically: true, encoding: .utf8)

                            NotificationCenter.default.post(
                                name: NSNotification.Name("NexusAIDisplayCreation"),
                                object: creation.html,
                                userInfo: [
                                    "title": creation.title,
                                    "filePath": fileOnDesktop.path,
                                    "fileURL": fileOnDesktop.absoluteString
                                ]
                            )
                            HapticFeedback.heavy()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "paintpalette.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(.yellow)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("Display Creation in Preview")
                                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    Text(creation.title)
                                        .font(.system(size: 9, weight: .medium))
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                Spacer()
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.yellow)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(LinearGradient(colors: [Color.purple.opacity(0.35), Color.blue.opacity(0.25)], startPoint: .leading, endPoint: .trailing))
                            )
                            .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(Color.yellow.opacity(0.40), lineWidth: 0.75))
                        }
                        .buttonStyle(.plain)

                        HStack(spacing: 6) {
                            Button(action: {
                                try? creation.html.write(to: fileOnDesktop, atomically: true, encoding: .utf8)
                                if let safari = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Safari") {
                                    NSWorkspace.shared.open([fileOnDesktop], withApplicationAt: safari, configuration: NSWorkspace.OpenConfiguration())
                                } else {
                                    NSWorkspace.shared.open(fileOnDesktop)
                                }
                                HapticFeedback.selection()
                            }) {
                                HStack(spacing: 3) {
                                    Image(systemName: "safari")
                                        .font(.system(size: 9))
                                    Text("Run in Safari")
                                        .font(.system(size: 9, weight: .semibold))
                                }
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color.cyan.opacity(0.20)))
                                .foregroundColor(.cyan)
                            }
                            .buttonStyle(.plain)

                            Button(action: {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(creation.html, forType: .string)
                                HapticFeedback.success()
                            }) {
                                HStack(spacing: 3) {
                                    Image(systemName: "doc.on.doc")
                                        .font(.system(size: 9))
                                    Text("Copy HTML")
                                        .font(.system(size: 9, weight: .semibold))
                                }
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color.white.opacity(0.10)))
                                .foregroundColor(.white.opacity(0.85))
                            }
                            .buttonStyle(.plain)

                            Button(action: {
                                try? creation.html.write(to: fileOnDesktop, atomically: true, encoding: .utf8)
                                NSWorkspace.shared.activateFileViewerSelecting([fileOnDesktop])
                                HapticFeedback.selection()
                            }) {
                                HStack(spacing: 3) {
                                    Image(systemName: "desktopcomputer")
                                        .font(.system(size: 9))
                                    Text("Desktop File")
                                        .font(.system(size: 9, weight: .semibold))
                                }
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color.white.opacity(0.12)))
                                .foregroundColor(.white.opacity(0.85))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.leading, 2)
                    }
                    .padding(.top, 2)
                }
            }

            if !isUser { Spacer(minLength: 32) }
        }
    }

    // MARK: - Active Generating Bubble (Transparent Floating Glass)
    @ViewBuilder
    private var compactActiveGeneratingBubble: some View {
        HStack(alignment: .bottom, spacing: 8) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 5) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.cyan)
                    Text(localModels.selectedModelDisplayName)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    ProgressView().controlSize(.mini)

                    if localModels.lastTokensPerSecond > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 6.5, weight: .bold))
                            Text(String(format: "%.1f tkps", localModels.lastTokensPerSecond))
                                .font(.system(size: 8, weight: .bold, design: .monospaced))
                        }
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 4.5)
                        .padding(.vertical, 1.5)
                        .background(Capsule().fill(Color.yellow.opacity(0.18)))
                    }

                    Spacer()

                    Button(action: {
                        localModels.stopGeneration()
                        HapticFeedback.tick()
                    }) {
                        HStack(spacing: 2) {
                            Image(systemName: "stop.fill").font(.system(size: 7.5))
                            Text("Stop").font(.system(size: 9, weight: .bold))
                        }
                        .foregroundColor(.orange)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.orange.opacity(0.20)))
                        .overlay(Capsule().stroke(Color.orange.opacity(0.45), lineWidth: 0.5))
                    }
                    .buttonStyle(.plain)
                }

                if !localModels.currentThinking.isEmpty {
                    GenieThinkingAccordionView(thinking: localModels.currentThinking, isStreaming: true)
                }

                if localModels.currentResponse.isEmpty {
                    HStack(spacing: 6) {
                        GenieStreamingCursorView()
                        Text("Synthesizing response...")
                            .font(.system(size: 11.5, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.70))
                    }
                } else {
                    GenieMarkdownMessageView(text: localModels.currentResponse, isStreaming: true)
                }
            }
            .padding(.horizontal, 13)
            .padding(.vertical, 10)
            .background(
                ZStack {
                    VisualEffectBlur(material: .popover, blendingMode: .withinWindow, state: .active)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    LinearGradient(
                        colors: [
                            Color(red: 0.08, green: 0.12, blue: 0.20).opacity(0.55),
                            Color(red: 0.04, green: 0.06, blue: 0.10).opacity(0.65)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.cyan.opacity(0.60),
                                Color.purple.opacity(0.40),
                                Color.white.opacity(0.20)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.9
                    )
            )
            .shadow(color: Color.cyan.opacity(0.25), radius: 10, y: 3)

            Spacer(minLength: 32)
        }
    }

    // MARK: - Empty State with Futuristic Terminal / Mario Block Splash Animation
    private var emptyStateView: some View {
        GenieTerminalSplashView(compact: false)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
    }

    private func starterChip(_ text: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            HapticFeedback.selection()
            action()
        }) {
            HStack {
                Text(text)
                    .font(.system(size: 9.5, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 7.5))
                    .foregroundColor(Color(red: 0.85, green: 0.47, blue: 0.36))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4.5)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.07)))
            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.12), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions & Utilities
    private func extractCodeArtifact(from text: String) -> (language: String, code: String)? {
        let pattern = "```([a-zA-Z0-9_-]*)\\n([\\s\\S]*?)```"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: []) else { return nil }
        let nsString = text as NSString
        let results = regex.matches(in: text, options: [], range: NSRange(location: 0, length: nsString.length))
        if let match = results.first {
            let langRange = match.range(at: 1)
            let codeRange = match.range(at: 2)
            let lang = langRange.location != NSNotFound ? nsString.substring(with: langRange) : "code"
            let code = codeRange.location != NSNotFound ? nsString.substring(with: codeRange) : ""
            if !code.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return (lang.isEmpty ? "Code" : lang, code)
            }
        }
        return nil
    }

    private func formattedTime(_ date: Date) -> String {
        let df = DateFormatter()
        df.timeStyle = .short
        return df.string(from: date)
    }

    private func showFeedback(_ text: String) {
        statusFeedback = text
        feedbackTimer?.invalidate()
        feedbackTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: false) { _ in
            withAnimation(.easeOut(duration: 0.2)) {
                self.statusFeedback = nil
            }
        }
    }

    private func copyFullTranscript() {
        if localModels.copyWholeChat() {
            showFeedback("Copied Whole Chat! 📋")
        } else {
            showFeedback("No messages to copy!")
        }
    }

    private func pasteFullTranscript() {
        let res = localModels.pasteWholeChat()
        if res.success {
            showFeedback("Pasted whole chat (\(res.count) msgs) 📋✨")
        } else {
            showFeedback("No chat transcript on clipboard ⚠️")
        }
    }

    private func saveChatToNote() {
        guard !localModels.chatHistory.isEmpty else {
            showFeedback("No messages to save!")
            return
        }
        var transcript = "Genie AI Conversation Note\nDate: \(Date().formatted())\nModel: \(localModels.selectedModelDisplayName)\n\n"
        for msg in localModels.chatHistory {
            let role = msg.role == "user" ? "You" : (msg.model.isEmpty ? "Genie" : msg.model)
            transcript += "[\(role)]\n\(msg.content)\n\n"
        }
        if let fileURL = DesktopNotePrinter.shared.printNote(content: transcript, openInFile: true) {
            showFeedback("Saved & opened \(fileURL.lastPathComponent) 📄")
        }
    }

    // MARK: - 🏷️ Name Chat Session
    private func nameChatSession() {
        guard !localModels.chatHistory.isEmpty else {
            showFeedback("Start a chat first!")
            return
        }

        let alert = NSAlert()
        alert.messageText = "Name This Conversation"
        alert.informativeText = "Give your chat session a memorable title so you can find it later."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")

        let inputField = NSTextField(frame: NSRect(x: 0, y: 0, width: 300, height: 24))
        // Pre-fill with current session title if available
        if let current = localModels.savedSessions.first(where: { $0.id == localModels.currentSessionId }) {
            inputField.stringValue = current.hasCustomTitle ? current.title : ""
        }
        inputField.placeholderString = localModels.chatHistory.first(where: { $0.role == "user" })
            .map { String($0.content.prefix(60)) } ?? "My Chat"
        alert.accessoryView = inputField

        let response = alert.runModal()
        guard response == .alertFirstButtonReturn else { return }

        let title = inputField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !title.isEmpty else { return }

        localModels.renameCurrentSession(to: title)
        showFeedback("Saved as \"\(title)\" 🏷️")
    }


    // MARK: - 🌐 View Chat as HTML in Safari / Browser
    private func viewChatInBrowser() {
        guard !localModels.chatHistory.isEmpty else {
            showFeedback("No chat to view!")
            return
        }

        // Build a styled HTML transcript
        let sessionTitle: String = localModels.savedSessions
            .first(where: { $0.id == localModels.currentSessionId })?.title ?? "Genie Chat"
        let dateStr = Date().formatted(date: .long, time: .shortened)
        let modelName = localModels.selectedModelDisplayName

        var messagesHtml = ""
        for msg in localModels.chatHistory {
            let isUser = msg.role == "user"
            let role = isUser ? "You" : (msg.model.isEmpty ? modelName : msg.model)
            let escaped = msg.content
                .replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")
                .replacingOccurrences(of: "\n", with: "<br>")
            let bubbleClass = isUser ? "user-bubble" : "ai-bubble"
            messagesHtml += """
            <div class="message \(bubbleClass)">
              <div class="sender">\(role)</div>
              <div class="content">\(escaped)</div>
              <div class="timestamp">\(msg.timestamp.formatted(date: .omitted, time: .shortened))</div>
            </div>\n
            """
        }

        let html = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>\(sessionTitle)</title>
          <style>
            * { box-sizing: border-box; }
            body { margin: 0; background: #0b0c10; color: #e8eaf0; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; padding: 24px 16px; }
            h1 { font-size: 18px; color: #00d4ff; margin-bottom: 4px; }
            .meta { font-size: 11px; color: #666; margin-bottom: 24px; }
            .message { max-width: 760px; margin: 12px auto; padding: 12px 16px; border-radius: 14px; position: relative; }
            .user-bubble { background: linear-gradient(135deg, #0d5cbf, #00a6e8); margin-left: auto; text-align: right; }
            .ai-bubble { background: rgba(255,255,255,0.06); border: 1px solid rgba(255,255,255,0.12); }
            .sender { font-size: 10px; font-weight: 700; opacity: 0.65; margin-bottom: 5px; text-transform: uppercase; letter-spacing: 0.05em; }
            .content { font-size: 13px; line-height: 1.6; word-wrap: break-word; overflow-wrap: break-word; white-space: pre-wrap; }
            .timestamp { font-size: 9px; opacity: 0.4; margin-top: 6px; }
          </style>
        </head>
        <body>
          <h1>\(sessionTitle)</h1>
          <div class="meta">\(dateStr) · \(modelName) · \(localModels.chatHistory.count) messages</div>
          \(messagesHtml)
        </body>
        </html>
        """

        let tmpURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("GenieChatTranscript_\(Int(Date().timeIntervalSince1970)).html")
        do {
            try html.write(to: tmpURL, atomically: true, encoding: .utf8)
            if let safariURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.Safari") {
                NSWorkspace.shared.open([tmpURL], withApplicationAt: safariURL, configuration: NSWorkspace.OpenConfiguration())
            } else {
                NSWorkspace.shared.open(tmpURL)
            }
            showFeedback("Opened chat in browser 🌐")
        } catch {
            showFeedback("Failed to export chat")
        }
    }
}
