import AppKit
import SwiftUI
import WebKit

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

    public init(isGenerating: Bool = false) {
        self.isGenerating = isGenerating
    }

    public var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
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
                    let speed = 0.20 + fi * 0.04
                    let phase = fi * 1.25
                    let cycle = (t * speed + phase).truncatingRemainder(dividingBy: 5.5) / 5.5

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
    case combined = "Combined"
    case chatOnly = "Chat Only"
    case settingsOnly = "Settings Only"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .combined: return "rectangle.split.2x1.fill"
        case .chatOnly: return "bubble.left.and.bubble.right.fill"
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
    @AppStorage(PrefKey.aiEmotion) var selectedEmotionRaw: String = AIEmotionType.mystical.rawValue

    @State private var layoutMode: ChatWindowLayoutMode = .combined
    @State private var splitRatio: CGFloat = 0.54
    @State private var isDraggingDivider: Bool = false
    @State private var promptText: String = ""
    @State private var statusFeedback: String? = nil

    private var isShowingSettings: Bool {
        get { layoutMode == .settingsOnly || layoutMode == .combined }
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

    public init() {}

    public var body: some View {
        ZStack {
            // 1. Apple Liquid Glass Frosted Material
            VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow, state: .active)

            // 2. Animated Smoke & Mystical Atmosphere Layer
            GenieBubblySmokeBackgroundView(isGenerating: localModels.isGenerating)

            // 3. Floating Content Layer
            VStack(spacing: 0) {
                // Floating Bubbly Header Bar
                floatingHeaderBar
                    .background(WindowDragRepresentable())
                    .padding(.top, 10)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 6)

                // Main Workspace: Combined Split or Focused Pane
                GeometryReader { geo in
                    let totalW = geo.size.width
                    let totalH = geo.size.height

                    if layoutMode == .combined {
                        if totalW < 660 {
                            chatPane
                                .frame(width: totalW, height: totalH)
                        } else {
                            let settingsW = max(300, min(totalW - 280, totalW * splitRatio))
                            let chatW = max(260, totalW - settingsW - 8)

                            HStack(spacing: 0) {
                                settingsPane
                                    .frame(width: settingsW, height: totalH)
                                    .clipped()

                                dividerView(totalWidth: totalW)
                                    .frame(width: 8, height: totalH)

                                chatPane
                                    .frame(width: chatW, height: totalH)
                                    .clipped()
                            }
                            .frame(width: totalW, height: totalH)
                        }
                    } else if layoutMode == .settingsOnly {
                        settingsPane
                            .frame(width: totalW, height: totalH)
                    } else {
                        chatPane
                            .frame(width: totalW, height: totalH)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        // Borderless Floating Window Shape with Apple Glass Polymorphism Rim
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.38),
                            Color.white.opacity(0.12),
                            Color.white.opacity(0.04),
                            Color.white.opacity(0.20)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.0
                )
        )
        .shadow(color: Color.black.opacity(0.40), radius: 24, x: 0, y: 10)
        .overlay(alignment: .top) {
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
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusSetWindowMode"))) { notif in
            if let mode = notif.object as? String {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.80)) {
                    if mode == "settings" || mode == "mode-settings" {
                        layoutMode = .combined
                    } else if mode == "chat-only" {
                        layoutMode = .chatOnly
                    } else if mode == "settings-only" {
                        layoutMode = .settingsOnly
                    } else {
                        layoutMode = .combined
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusSwitchFinderSidebar"))) { notif in
            if let item = notif.object as? FinderChatSidebarItem {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.80)) {
                    if item == .settings {
                        layoutMode = .combined
                    } else {
                        layoutMode = .combined
                    }
                }
            }
        }
        .onKeyPress(.escape) {
            FinderChatWindowManager.shared.hide()
            return .handled
        }
    }

    // MARK: - ⚙️ Settings Pane
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

    // MARK: - 💬 Chat Pane
    private var chatPane: some View {
        ZStack(alignment: .bottom) {
            CompactChatStreamView(emotion: currentEmotion, showHeader: false)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.bottom, 64) // Reserve space for floating bottom input

            // Floating Liquid Glass Input Bar
            floatingBottomInputCapsule
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
        }
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

            Capsule()
                .fill(Color.white.opacity(isDraggingDivider ? 0.65 : 0.25))
                .frame(width: 4, height: 32)

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
                            let newRatio = (totalWidth * splitRatio + val.translation.width) / totalWidth
                            splitRatio = max(0.35, min(0.70, newRatio))
                        }
                        .onEnded { _ in
                            isDraggingDivider = false
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
        HStack(spacing: 10) {
            // Traffic Lights Capsule (Floating Island)
            HStack(spacing: 7) {
                Circle().fill(Color.red.opacity(0.85)).frame(width: 12, height: 12)
                    .onTapGesture { FinderChatWindowManager.shared.hide() }
                    .help("Close Window (⌘W / Esc)")
                Circle().fill(Color.yellow.opacity(0.85)).frame(width: 12, height: 12)
                    .onTapGesture { FinderChatWindowManager.shared.hide() }
                    .help("Minimize Window (⌘M)")
                Circle().fill(Color.green.opacity(0.85)).frame(width: 12, height: 12)
                    .onTapGesture { FinderChatWindowManager.shared.toggleExpand() }
                    .help("Toggle Zoom / Expand")
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.08))
            )
            .overlay(
                Capsule()
                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.75)
            )

            // Genie Brand Glass Bubble with Pulsing Cyan Jewel
            HStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(Color.cyan)
                        .frame(width: 7, height: 7)
                        .shadow(color: Color.cyan, radius: 4)
                    Circle()
                        .stroke(Color.cyan.opacity(0.50), lineWidth: 1.5)
                        .frame(width: 12, height: 12)
                }

                Text("Genie")
                    .font(.system(size: 12.5, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("•")
                    .foregroundColor(.white.opacity(0.30))

                Text(layoutMode == .combined ? "Chat & Settings" : (layoutMode == .settingsOnly ? "Settings" : localModels.selectedModelDisplayName))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.cyan.opacity(0.90))
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.07))
            )
            .overlay(
                Capsule()
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.white.opacity(0.28), Color.white.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.75
                    )
            )

            // Model quick switch badge
            Menu {
                Menu("💎 Google Gemini") {
                    ForEach(LocalModelManager.cloudModels.filter { $0.provider == .gemini }) { model in
                        Button(action: { localModels.selectModel(model.id) }) {
                            Text(localModels.effectiveModel == model.id ? "\(model.displayName) ✓" : model.displayName)
                        }
                    }
                }
                Menu("🧠 Anthropic Claude") {
                    ForEach(LocalModelManager.cloudModels.filter { $0.provider == .claude }) { model in
                        Button(action: { localModels.selectModel(model.id) }) {
                            Text(localModels.effectiveModel == model.id ? "\(model.displayName) ✓" : model.displayName)
                        }
                    }
                }
                Menu("❇️ OpenAI") {
                    ForEach(LocalModelManager.cloudModels.filter { $0.provider == .openai }) { model in
                        Button(action: { localModels.selectModel(model.id) }) {
                            Text(localModels.effectiveModel == model.id ? "\(model.displayName) ✓" : model.displayName)
                        }
                    }
                }
                Menu("💻 Local Models (Ollama / Offline)") {
                    ForEach(LocalModelManager.cloudModels.filter { $0.provider == .local }) { model in
                        Button(action: { localModels.selectModel(model.id) }) {
                            Text(localModels.effectiveModel == model.id ? "\(model.displayName) ✓" : model.displayName)
                        }
                    }
                    if localModels.localModelsEnabled && !localModels.availableModels.isEmpty {
                        Divider()
                        ForEach(localModels.availableModels) { model in
                            Button(action: { localModels.selectModel(model.name) }) {
                                Text(localModels.effectiveModel == model.name ? "\(model.displayName) ✓" : model.displayName)
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "cpu")
                        .font(.system(size: 9))
                    Text(localModels.selectedModelDisplayName)
                        .font(.system(size: 10.5, weight: .medium, design: .rounded))
                        .lineLimit(1)
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

            Spacer()
                .overlay(WindowDragRepresentable())

            // Mode Toggle Capsule: [◨ Combined] & [💬 Chat] & [⚙️ Settings]
            HStack(spacing: 3) {
                ForEach(ChatWindowLayoutMode.allCases) { mode in
                    Button(action: {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.80)) {
                            layoutMode = mode
                        }
                        HapticFeedback.selection()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: mode.icon)
                                .font(.system(size: 9.5))
                            Text(mode.rawValue)
                                .font(.system(size: 10.5, weight: layoutMode == mode ? .bold : .medium, design: .rounded))
                        }
                        .foregroundColor(layoutMode == mode ? .white : .secondary)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4.5)
                        .background(
                            Capsule()
                                .fill(layoutMode == mode ? (mode == .combined ? Color.cyan.opacity(0.32) : Color.white.opacity(0.20)) : Color.clear)
                        )
                        .overlay(
                            Capsule()
                                .strokeBorder(layoutMode == mode ? Color.cyan.opacity(0.55) : Color.clear, lineWidth: 0.75)
                        )
                    }
                    .buttonStyle(.plain)
                    .help(mode == .combined ? "Combined View (Chat + Settings Side by Side)" : mode.rawValue)
                }
            }
            .padding(3)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.25))
            )
            .overlay(
                Capsule()
                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.6)
            )

            // Window Action Buttons: Expand ^ & Close ✕
            HStack(spacing: 4) {
                Button(action: {
                    windowManager.toggleExpand()
                    HapticFeedback.selection()
                }) {
                    Image(systemName: windowManager.isExpanded ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.85))
                        .frame(width: 26, height: 26)
                        .background(Circle().fill(Color.white.opacity(0.08)))
                        .overlay(Circle().strokeBorder(Color.white.opacity(0.15), lineWidth: 0.6))
                }
                .buttonStyle(.plain)
                .help("Expand / Restore Window")

                Button(action: {
                    FinderChatWindowManager.shared.hide()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                        .frame(width: 26, height: 26)
                        .background(Circle().fill(Color.white.opacity(0.08)))
                        .overlay(Circle().strokeBorder(Color.white.opacity(0.15), lineWidth: 0.6))
                }
                .buttonStyle(.plain)
                .help("Close Window (Esc)")
            }
        }
    }

    // MARK: - 🫧 Floating Liquid Glass Bottom Input Capsule
    private var floatingBottomInputCapsule: some View {
        HStack(spacing: 8) {
            // Dialogue Pill Badge
            HStack(spacing: 4) {
                Image(systemName: "bubble.left.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.cyan)
                Text("Dialogue")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(Capsule().fill(Color.cyan.opacity(0.18)))
            .overlay(Capsule().stroke(Color.cyan.opacity(0.40), lineWidth: 0.6))

            // Text Input Field
            TextField("Ask Genie anything...", text: $promptText)
                .textFieldStyle(.plain)
                .font(.system(size: 12.5, weight: .medium, design: .rounded))
                .foregroundColor(.white)
                .padding(.vertical, 6)
                .onSubmit { handlePromptSubmit() }

            if !promptText.isEmpty {
                Button(action: { promptText = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.40))
                }
                .buttonStyle(.plain)
            }

            // Send Button [↑]
            Button(action: { handlePromptSubmit() }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .white.opacity(0.25) : .cyan)
                    .shadow(color: promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.clear : Color.cyan.opacity(0.60), radius: 6)
            }
            .buttonStyle(.plain)
            .disabled(promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

            // ☕ Anti-Sleep Toggle
            Button(action: {
                sleepManager.toggleSleepPrevention()
                showStatusFeedback(sleepManager.isSleepDisabled ? "Anti-Sleep ON ☕" : "Sleep OK 🌙")
                HapticFeedback.selection()
            }) {
                Image(systemName: sleepManager.isSleepDisabled ? "cup.and.saucer.fill" : "cup.and.saucer")
                    .font(.system(size: 13))
                    .foregroundColor(sleepManager.isSleepDisabled ? .orange : .white.opacity(0.45))
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(sleepManager.isSleepDisabled ? Color.orange.opacity(0.20) : Color.white.opacity(0.06)))
            }
            .buttonStyle(.plain)
            .help("Toggle Anti-Sleep (Keep Screen Awake)")

            // 📱 Apple Messages (iMessage) Relay
            Button(action: {
                let clean = promptText.trimmingCharacters(in: .whitespacesAndNewlines)
                if !clean.isEmpty {
                    imessageManager.sendiMessageDirect(to: imessageManager.nicholasAppleID, message: clean)
                    promptText = ""
                    showStatusFeedback("Relayed to iPhone Messages! 📱")
                } else if let lastBotMsg = localModels.chatHistory.last(where: { $0.role == "assistant" })?.content {
                    imessageManager.sendiMessageDirect(to: imessageManager.nicholasAppleID, message: lastBotMsg)
                    showStatusFeedback("Last reply sent to iPhone! 📱")
                } else {
                    GeniePhoneBridgeManager.shared.pingNicholasPhone()
                    showStatusFeedback("Pinged Nicholas's iPhone! 📱")
                }
                HapticFeedback.selection()
            }) {
                Image(systemName: "message.fill")
                    .font(.system(size: 13))
                    .foregroundColor(Color(red: 0.0, green: 0.85, blue: 0.45))
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(Color.green.opacity(0.15)))
            }
            .buttonStyle(.plain)
            .help("Relay to iPhone via iMessage")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            ZStack {
                VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow, state: .active)
                Capsule().fill(Color.black.opacity(0.40))
            }
        )
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.38),
                            Color.white.opacity(0.12),
                            Color.white.opacity(0.05),
                            Color.white.opacity(0.18)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.0
                )
        )
        .shadow(color: Color.black.opacity(0.35), radius: 12, x: 0, y: 5)
    }

    private func handlePromptSubmit() {
        let clean = promptText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }
        promptText = ""

        localModels.generate(prompt: clean)
        HapticFeedback.selection()
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
}
