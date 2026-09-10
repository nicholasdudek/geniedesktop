import AppKit
import SwiftUI
import WebKit
import UniformTypeIdentifiers

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
    /// Editor: the focused chat render over the folder it writes into, beside the chat.
    case editor = "Editor"
    case filesOnly = "Files"
    case worldClock = "World Clock"
    case settingsOnly = "Settings"

    public var id: String { rawValue }

    public static var consolidatedTabs: [ChatWindowLayoutMode] {
        [.chatOnly, .editor, .filesOnly, .worldClock, .settingsOnly]
    }

    public var tabTitle: String {
        switch self {
        case .chatOnly: return "Chat"
        case .editor: return "Editor"
        case .filesOnly: return "Files"
        case .worldClock: return "World Clock"
        case .settingsOnly: return "Settings"
        }
    }

    public var icon: String {
        switch self {
        case .chatOnly: return "bubble.left.and.bubble.right.fill"
        case .editor: return "chevron.left.forwardslash.chevron.right"
        case .filesOnly: return "folder.fill"
        case .worldClock: return "globe"
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
    @AppStorage(PrefKey.aiEmotion) var selectedEmotionRaw: String = AIEmotionType.mystical.rawValue

    @State private var splitRatio: CGFloat = 0.54
    @State private var isDraggingDivider: Bool = false
    @State private var dragStartWidth: CGFloat?
    @State private var browserURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
    @State private var promptText: String = ""
    @State private var statusFeedback: String? = nil
    @State private var previewCreation: (title: String, html: String, fileURL: URL?)? = nil
    @State private var droppedAttachments: [URL] = []
    @State private var isChatDropTargeted: Bool = false

    private var layoutMode: ChatWindowLayoutMode {
        get {
            switch windowManager.activeTab {
            case .chat: return .chatOnly
            case .editor: return .editor
            case .files: return .filesOnly
            case .worldClock: return .worldClock
            case .settings: return .settingsOnly
            }
        }
        nonmutating set {
            switch newValue {
            case .chatOnly: windowManager.activeTab = .chat
            case .editor: windowManager.activeTab = .editor
            case .filesOnly: windowManager.activeTab = .files
            case .worldClock: windowManager.activeTab = .worldClock
            case .settingsOnly: windowManager.activeTab = .settings
            }
        }
    }

    private var isShowingSettings: Bool {
        get { layoutMode == .settingsOnly }
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

                    if layoutMode == .editor {
                        if totalW < 660 {
                            filesColumn(width: totalW, height: totalH)
                                .frame(width: totalW, height: totalH)
                        } else {
                            let browserW = FinderWorkspaceLayout.browserWidth(totalWidth: totalW, ratio: splitRatio)
                            let chatW = totalW - browserW - 8

                            HStack(spacing: 0) {
                                filesColumn(width: browserW, height: totalH)
                                    .frame(width: browserW, height: totalH)
                                    .clipped()

                                dividerView(totalWidth: totalW)
                                    .frame(width: 8, height: totalH)

                                chatPane
                                    .frame(width: chatW, height: totalH)
                                    .clipped()
                            }
                            .frame(width: totalW, height: totalH)
                        }
                    } else if layoutMode == .filesOnly {
                        fileBrowserPane
                            .frame(width: totalW, height: totalH)
                    } else if layoutMode == .worldClock {
                        GenieWorldClockAlarmPane()
                            .frame(width: totalW, height: totalH)
                    } else if layoutMode == .settingsOnly {
                        settingsPane
                            .frame(width: totalW, height: totalH)
                    } else {
                        if let creation = previewCreation {
                            if totalW < 660 {
                                creationPreviewPane(creation: creation)
                                    .frame(width: totalW, height: totalH)
                            } else {
                                HStack(spacing: 0) {
                                    creationPreviewPane(creation: creation)
                                        .frame(width: max(320, totalW * 0.48), height: totalH)
                                        .clipped()

                                    dividerView(totalWidth: totalW)
                                        .frame(width: 8, height: totalH)

                                    chatPane
                                        .frame(width: max(280, totalW - max(320, totalW * 0.48) - 8), height: totalH)
                                        .clipped()
                                }
                                .frame(width: totalW, height: totalH)
                            }
                        } else {
                            chatPane
                                .frame(width: totalW, height: totalH)
                        }
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
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("NexusSetWindowMode"))) { notif in
            if let mode = notif.object as? String {
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
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("NexusSwitchFinderSidebar"))) { notif in
            if let item = notif.object as? FinderChatSidebarItem {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.80)) {
                    if item == .settings {
                        layoutMode = .settingsOnly
                    } else {
                        layoutMode = .chatOnly
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusAIDisplayCreation"))) { notif in
            if let code = notif.object as? String, !code.isEmpty {
                let title = (notif.userInfo?["title"] as? String) ?? "AI Creation"
                let fileURL: URL? = {
                    if let uStr = notif.userInfo?["fileURL"] as? String, let u = URL(string: uStr) {
                        return u
                    }
                    if let path = notif.userInfo?["filePath"] as? String {
                        return URL(fileURLWithPath: path)
                    }
                    return nil
                }()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    self.previewCreation = (title: title, html: code, fileURL: fileURL)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .genieChatRenderFocused)) { notif in
            guard let artifact = notif.object as? ChatRenderArtifact else { return }
            withAnimation(.spring(response: 0.32, dampingFraction: 0.85)) {
                self.previewCreation = (title: artifact.title, html: artifact.body, fileURL: nil)
            }
        }
        .onKeyPress(.escape) {
            FinderChatWindowManager.shared.hide()
            return .handled
        }
        .onAppear {
            localModels.activeSaveDirectoryOverride = browserURL
        }
        .onChange(of: browserURL) { _, newValue in
            localModels.activeSaveDirectoryOverride = newValue
        }
    }

    // MARK: - ⚙️ Settings Pane
    private var fileBrowserPane: some View {
        FinderFileBrowserPaneView(initialURL: browserURL, onNavigate: { browserURL = $0 })
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
                withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                    self.previewCreation = nil
                }
            }
        )
    }

    // MARK: - 💬 Chat Pane
    private var chatPane: some View {
        ZStack(alignment: .bottom) {
            CompactChatStreamView(emotion: currentEmotion, showHeader: false)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.bottom, 64) // Reserve space for floating bottom input

            ChatInlinePreviewTrayView()
                .padding(.bottom, 76)

            // Floating Liquid Glass Input Bar + Dropped File Chips
            VStack(spacing: 6) {
                if !droppedAttachments.isEmpty {
                    attachmentChipsRow
                }
                floatingBottomInputCapsule
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 12)

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
        }
        .onDrop(of: [.fileURL], isTargeted: $isChatDropTargeted) { providers in
            handleChatFileDrop(providers)
        }
    }

    // MARK: - 📎 Dropped File Attachment Chips
    private var attachmentChipsRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(droppedAttachments, id: \.self) { url in
                    HStack(spacing: 4) {
                        Image(systemName: "doc.fill")
                            .font(.system(size: 10))
                        Text(url.lastPathComponent)
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .lineLimit(1)
                        Button(action: { droppedAttachments.removeAll { $0 == url } }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 11))
                        }
                        .buttonStyle(.plain)
                    }
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.white.opacity(0.12)))
                    .overlay(Capsule().strokeBorder(Color.white.opacity(0.18), lineWidth: 0.6))
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private func handleChatFileDrop(_ providers: [NSItemProvider]) -> Bool {
        var didAccept = false
        for provider in providers where provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
            didAccept = true
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                guard let data = item as? Data,
                      let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
                DispatchQueue.main.async {
                    if !droppedAttachments.contains(url) {
                        droppedAttachments.append(url)
                    }
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
        HStack(spacing: 10) {
            HStack(spacing: 4) {
                windowControl("Close Window", color: .red, icon: "xmark") { windowManager.hide() }
                    .keyboardShortcut("w", modifiers: .command)
                windowControl("Minimize Window", color: .yellow, icon: "minus") { windowManager.minimize() }
                    .keyboardShortcut("m", modifiers: .command)
                windowControl("Expand / Restore Window", color: .green, icon: "arrow.up.left.and.arrow.down.right") {
                    windowManager.toggleExpand()
                }
            }

            Text("Genie")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)

            Spacer(minLength: 0)

            Picker("Workspace", selection: Binding(get: { layoutMode }, set: { layoutMode = $0 })) {
                ForEach(ChatWindowLayoutMode.consolidatedTabs) { mode in
                    Text(mode.tabTitle).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 204)
            .accessibilityLabel("Workspace")

            modelQuickSwitcher
                .frame(minWidth: 90, maxWidth: 230)
        }
        .frame(height: 32)
        .environment(\.colorScheme, .dark)
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
        .buttonStyle(.plain)
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
            .help("Choose Model")
            .accessibilityLabel("Choose Model")
    }

    // MARK: - 🫧 Floating Liquid Glass Bottom Input Capsule
    private var floatingBottomInputCapsule: some View {
        HStack(spacing: 8) {
            // ➕ Consolidated Tools & Actions Menu
            Menu {
                Section("Mac Actions") {
                    Button(action: {
                        sleepManager.toggleSleepPrevention()
                        showStatusFeedback(sleepManager.isSleepDisabled ? "Anti-Sleep ON ☕" : "Sleep OK 🌙")
                        HapticFeedback.selection()
                    }) {
                        Label(
                            sleepManager.isSleepDisabled ? "Anti-Sleep Active" : "Keep Mac Awake (Anti-Sleep)",
                            systemImage: sleepManager.isSleepDisabled ? "cup.and.saucer.fill" : "cup.and.saucer"
                        )
                    }

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
                        Label("Relay to iPhone (iMessage)", systemImage: "message.fill")
                    }
                }

                Divider()

                Section("Conversation") {
                    Button(action: {
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
                    .foregroundColor(.white.opacity(0.85))
                    .frame(width: 26, height: 26)
                    .background(Circle().fill(Color.white.opacity(0.10)))
                    .overlay(Circle().strokeBorder(Color.white.opacity(0.16), lineWidth: 0.6))
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .help("Actions & Tools")

            // Text Input Field
            TextField("Ask Genie anything...", text: $promptText)
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .regular, design: .rounded))
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
                .help("Clear Input")
            }

            // 🎙️ Voice Input / Speech Synthesis
            Button(action: {
                HapticFeedback.selection()
                if voiceEngine.isSpeaking {
                    voiceEngine.stopSpeaking()
                } else if let lastBotMsg = localModels.chatHistory.last(where: { $0.role == "assistant" })?.content {
                    voiceEngine.speak(text: lastBotMsg)
                }
            }) {
                Image(systemName: voiceEngine.isSpeaking ? "waveform.badge.magnifyingglass" : "mic.fill")
                    .font(.system(size: 13))
                    .foregroundColor(voiceEngine.isSpeaking ? Color.cyan : Color.white.opacity(0.55))
                    .frame(width: 26, height: 26)
                    .background(Circle().fill(voiceEngine.isSpeaking ? Color.cyan.opacity(0.20) : Color.white.opacity(0.08)))
            }
            .buttonStyle(.plain)
            .help(voiceEngine.isSpeaking ? "Stop Speaking" : "Read Aloud")

            // Send Button [↑]
            Button(action: { handlePromptSubmit() }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .white.opacity(0.25) : .cyan)
                    .shadow(color: promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? Color.clear : Color.cyan.opacity(0.60), radius: 6)
            }
            .buttonStyle(.plain)
            .disabled(promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .help("Send Message")
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
        guard (!clean.isEmpty || !droppedAttachments.isEmpty), !localModels.isGenerating else { return }
        promptText = ""

        var finalPrompt = clean
        if !droppedAttachments.isEmpty {
            let fileList = droppedAttachments.map { "- \($0.path)" }.joined(separator: "\n")
            finalPrompt += "\n\n📎 Attached file(s):\n\(fileList)"
            droppedAttachments = []
        }

        localModels.generate(prompt: finalPrompt)
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
