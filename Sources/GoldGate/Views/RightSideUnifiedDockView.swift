import AppKit
import Foundation
import SwiftUI

// MARK: - 📱 Unified Dock Tab
public enum UnifiedDockTab: String, CaseIterable, Identifiable {
    case chat = "Chat 💬"
    case apps = "Apps 🪟"
    case screenMatrix = "Screen Size 📱"
    case settings = "Settings ⚙️"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .chat: return "bubble.left.and.bubble.right.fill"
        case .apps: return "square.grid.2x2.fill"
        case .screenMatrix: return "iphone.and.arrow.forward"
        case .settings: return "gearshape.fill"
        }
    }

    public var tintColor: Color {
        switch self {
        case .chat: return .cyan
        case .apps: return .orange
        case .screenMatrix: return .green
        case .settings: return .purple
        }
    }
}

// MARK: - 🪟 Unified Sliding Right-Edge Dock
/// Combines Chat, Applications launcher, Pioneered Virtual Screen Size Trickster,
/// Stage Manager Stage Stacks, and Settings into a single cohesive, non-overlapping glass panel.
/// Powered by the same fluid magnification wave, spring physics, and specular effects as the Mini Dock.
public struct RightSideUnifiedDockView: View {
    @ObservedObject var localModels = LocalModelManager.shared
    @ObservedObject var voiceEngine = GenieVoiceEngine.shared
    @ObservedObject var desktopsManager = MacDesktopsManager.shared
    @ObservedObject var tricksterEngine = AppScreenSizeTricksterEngine.shared
    @ObservedObject var appModel: AppModel

    @Binding var isOpen: Bool
    @State public var selectedTab: UnifiedDockTab = .chat

    public var edge: DockEdge = .trailing

    // Chat State
    @State private var inputText: String = ""
    @State private var selectedVoiceDialect: GenieVoiceDialect = .usSamantha
    @State private var copiedMessageId: UUID? = nil
    @State private var attachedFileName: String? = nil
    @State private var showVoicePicker: Bool = false

    // Apps & Hover Animation State (Mini Dock Parabolic Magnification Wave)
    @State private var appSearchFilter: String = ""
    @State private var selectedAppCategory: AppCategory = .all
    @State private var hoveredAppId: String? = nil
    @State private var hoveredProfileId: String? = nil

    // Drag & Animation State
    @State private var dragDismissOffset: CGFloat = 0
    @State private var statusFeedback: String? = nil

    public init(
        isOpen: Binding<Bool>,
        initialTab: UnifiedDockTab = .chat,
        edge: DockEdge = .trailing
    ) {
        self._isOpen = isOpen
        self._selectedTab = State(initialValue: initialTab)
        self.edge = edge
        self.appModel = AppModel.shared ?? AppModel()
    }

    // MARK: - Matching Apps
    private var matchingApps: [AppInfo] {
        let cat = (selectedAppCategory == .all) ? nil : selectedAppCategory
        return appModel.filteredApps(search: appSearchFilter, category: cat)
    }

    private var runningAppsList: [NSRunningApplication] {
        NSWorkspace.shared.runningApplications.filter { app in
            app.activationPolicy == .regular && app.bundleIdentifier != Bundle.main.bundleIdentifier
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            // ── Top Drag Retractor Pill ──
            topDragHandle

            // ── Unified Proscenium Tab Switcher ──
            unifiedHeaderTabSwitcher

            Divider().opacity(0.15)

            // ── Tab Content ──
            ZStack {
                switch selectedTab {
                case .chat:
                    chatTabContent
                case .apps:
                    appsTabContent
                case .screenMatrix:
                    screenMatrixTabContent
                case .settings:
                    settingsTabContent
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(width: 480)
        .background(
            ZStack {
                VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow, state: .active)
                Color(red: 0.05, green: 0.06, blue: 0.10).opacity(0.88)
            }
        )
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: edge == .trailing ? 22 : 0,
                bottomLeadingRadius: edge == .trailing ? 22 : 0,
                bottomTrailingRadius: edge == .leading ? 22 : 0,
                topTrailingRadius: edge == .leading ? 22 : 0,
                style: .continuous
            )
        )
        .overlay(
            UnevenRoundedRectangle(
                topLeadingRadius: edge == .trailing ? 22 : 0,
                bottomLeadingRadius: edge == .trailing ? 22 : 0,
                bottomTrailingRadius: edge == .leading ? 22 : 0,
                topTrailingRadius: edge == .leading ? 22 : 0,
                style: .continuous
            )
            .strokeBorder(
                LinearGradient(
                    colors: [Color.cyan.opacity(0.50), Color.purple.opacity(0.30), Color.white.opacity(0.12)],
                    startPoint: edge == .trailing ? .topLeading : .topTrailing,
                    endPoint: edge == .trailing ? .bottomTrailing : .bottomLeading
                ),
                lineWidth: 0.85
            )
        )
        .shadow(color: Color.black.opacity(0.55), radius: 32, x: edge == .trailing ? -12 : 12, y: 0)
        .offset(x: dragDismissOffset)
        .gesture(
            DragGesture(minimumDistance: 12)
                .onChanged { value in
                    if edge == .trailing {
                        if value.translation.width > 0 {
                            dragDismissOffset = value.translation.width * 0.70
                        }
                    } else {
                        if value.translation.width < 0 {
                            dragDismissOffset = value.translation.width * 0.70
                        }
                    }
                }
                .onEnded { value in
                    if edge == .trailing {
                        if value.translation.width > 120 || value.predictedEndTranslation.width > 200 {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.80)) {
                                isOpen = false
                            }
                        }
                    } else {
                        if value.translation.width < -120 || value.predictedEndTranslation.width < -200 {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.80)) {
                                isOpen = false
                            }
                        }
                    }
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.80)) {
                        dragDismissOffset = 0
                    }
                }
        )
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusOpenRightDockTab"))) { notif in
            if let tabName = notif.object as? String,
               let tab = UnifiedDockTab.allCases.first(where: { $0.rawValue.contains(tabName) || $0.id.contains(tabName) }) {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                    selectedTab = tab
                    isOpen = true
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusOpenSettingsInChat"))) { _ in
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                selectedTab = .settings
                isOpen = true
            }
        }
    }

    // MARK: - Top Drag Handle
    private var topDragHandle: some View {
        HStack {
            Capsule()
                .fill(Color.white.opacity(0.35))
                .frame(width: 40, height: 4.5)
                .padding(.top, 6)
                .padding(.bottom, 4)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Unified Proscenium Tab Switcher
    private var unifiedHeaderTabSwitcher: some View {
        HStack(spacing: 6) {
            // Mode Switcher Segmented Capsule
            HStack(spacing: 3) {
                ForEach(UnifiedDockTab.allCases) { tab in
                    let isSelected = (selectedTab == tab)
                    Button(action: {
                        HapticFeedback.selection()
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.80)) {
                            selectedTab = tab
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 10, weight: .bold))

                            Text(tab.rawValue.components(separatedBy: " ").first ?? "")
                                .font(.system(size: 10.5, weight: isSelected ? .bold : .medium, design: .rounded))
                        }
                        .foregroundColor(isSelected ? .white : .white.opacity(0.60))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(
                            ZStack {
                                if isSelected {
                                    Capsule()
                                        .fill(tab.tintColor.opacity(0.35))
                                        .overlay(Capsule().stroke(tab.tintColor.opacity(0.70), lineWidth: 0.85))
                                } else {
                                    Capsule().fill(Color.clear)
                                }
                            }
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(3)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.06))
                    .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.5))
            )

            Spacer()

            // Close Dock Button
            Button(action: {
                HapticFeedback.tick()
                withAnimation(.spring(response: 0.28, dampingFraction: 0.80)) {
                    isOpen = false
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.55))
            }
            .buttonStyle(.plain)
            .help("Close Sidebar (Esc / Drag)")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
    }

    // MARK: - 1. 💬 Chat Tab Content
    private var chatTabContent: some View {
        VStack(spacing: 0) {
            // Desktop Space Switcher Strip
            nativeDesktopSpacePlayerView

            // Chat Stream
            chatStreamView

            Divider().opacity(0.15)

            // Multimodal Input Bar
            chatInputBarView
        }
    }

    // MARK: - Desktop Space Switcher Strip
    private var nativeDesktopSpacePlayerView: some View {
        HStack(spacing: 6) {
            Text("SPACES")
                .font(.system(size: 8.5, weight: .heavy, design: .rounded))
                .foregroundColor(.cyan.opacity(0.85))
                .padding(.leading, 12)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 5) {
                    ForEach(1...max(3, desktopsManager.spaces.count), id: \.self) { idx in
                        let isActive = (desktopsManager.currentSpaceIndex == idx)
                        Button(action: {
                            HapticFeedback.selection()
                            desktopsManager.switchToDesktop(index: idx)
                        }) {
                            Text("\(idx)")
                                .font(.system(size: 10, weight: isActive ? .bold : .medium, design: .rounded))
                                .foregroundColor(isActive ? .white : .white.opacity(0.65))
                                .frame(width: 24, height: 20)
                                .background(
                                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                                        .fill(isActive ? Color.cyan.opacity(0.35) : Color.white.opacity(0.08))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
        .padding(.vertical, 4)
        .background(Color.white.opacity(0.03))
    }

    // MARK: - Chat Stream View
    private var chatStreamView: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(spacing: 12) {
                    if localModels.chatHistory.isEmpty {
                        chatEmptyPlaceholder
                    } else {
                        ForEach(localModels.chatHistory) { message in
                            dockChatMessageBubble(message: message)
                                .id(message.id)
                        }
                    }

                    if localModels.isGenerating {
                        HStack(spacing: 8) {
                            ProgressView()
                                .scaleEffect(0.65)
                                .colorScheme(.dark)
                            Text("Genie is synthesizing...")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(.cyan.opacity(0.85))
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
            }
            .onChange(of: localModels.chatHistory.count) { _, _ in
                if let lastId = localModels.chatHistory.last?.id {
                    withAnimation {
                        proxy.scrollTo(lastId, anchor: .bottom)
                    }
                }
            }
        }
    }

    // MARK: - Chat Empty Placeholder
    private var chatEmptyPlaceholder: some View {
        VStack(spacing: 10) {
            Image(systemName: "sparkles")
                .font(.system(size: 32))
                .foregroundStyle(LinearGradient(colors: [.cyan, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                .padding(.top, 40)

            Text("How can Genie assist you?")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.white)

            Text("Ask questions, inspect your screen, or run apps in compact screen mode.")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.white.opacity(0.60))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    @ViewBuilder
    private func dockChatMessageBubble(message: ChatMessage) -> some View {
        let isUser = (message.role == "user")
        HStack(alignment: .top, spacing: 8) {
            if isUser {
                Spacer()
                Text(message.content)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.cyan.opacity(0.30))
                            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.cyan.opacity(0.50), lineWidth: 0.5))
                    )
            } else {
                Text(message.content)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white.opacity(0.92))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.white.opacity(0.08))
                            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 0.5))
                    )
                Spacer()
            }
        }
    }

    // MARK: - Chat Input Bar View
    private var chatInputBarView: some View {
        HStack(spacing: 8) {
            TextField("Ask Genie or run !trick <app>...", text: $inputText)
                .textFieldStyle(.plain)
                .font(.system(size: 12.5))
                .foregroundColor(.white)
                .onSubmit {
                    sendChatMessage()
                }

            if !inputText.isEmpty {
                Button(action: {
                    sendChatMessage()
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.cyan)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.05))
    }

    private func sendChatMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let prompt = inputText
        inputText = ""
        localModels.generate(prompt: prompt)
    }

    // MARK: - 2. 🪟 Applications Tab Content (With Stage Manager & Mini Dock Wave)
    private var appsTabContent: some View {
        VStack(spacing: 0) {
            // Search Bar & Category Filter
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.50))

                TextField("Search \(matchingApps.count) applications...", text: $appSearchFilter)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12))
                    .foregroundColor(.white)

                if !appSearchFilter.isEmpty {
                    Button(action: { appSearchFilter = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.50))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.white.opacity(0.08))
            )
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .padding(.bottom, 6)

            // Stage Manager Active Windows Carousel
            if !runningAppsList.isEmpty && appSearchFilter.isEmpty {
                stageManagerRunningStrip
                    .padding(.horizontal, 14)
                    .padding(.bottom, 8)
            }

            // App Grid with Mini Dock Parabolic Magnification Wave
            ScrollView(.vertical, showsIndicators: true) {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80), spacing: 10)], spacing: 12) {
                    ForEach(matchingApps) { app in
                        dockAppItemTile(app: app)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            }
        }
    }

    // MARK: - Stage Manager Running App Strip
    private var stageManagerRunningStrip: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("STAGE MANAGER STACKS")
                    .font(.system(size: 8.5, weight: .heavy, design: .rounded))
                    .foregroundColor(.orange.opacity(0.85))
                Spacer()
                Text("(\(runningAppsList.count) active)")
                    .font(.system(size: 8.5, weight: .bold))
                    .foregroundColor(.white.opacity(0.45))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(runningAppsList, id: \.processIdentifier) { app in
                        let isHovered = (hoveredAppId == "\(app.processIdentifier)")
                        Button(action: {
                            HapticFeedback.selection()
                            if #available(macOS 14.0, *) {
                                app.activate()
                            } else {
                                app.activate(options: [.activateIgnoringOtherApps])
                            }
                        }) {
                            HStack(spacing: 6) {
                                if let icon = app.icon {
                                    Image(nsImage: icon)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 18, height: 18)
                                }

                                Text(app.localizedName ?? "App")
                                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4.5)
                            .background(
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .fill(isHovered ? Color.orange.opacity(0.35) : Color.white.opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                                            .stroke(isHovered ? Color.orange.opacity(0.70) : Color.white.opacity(0.12), lineWidth: 0.8)
                                    )
                            )
                            .scaleEffect(isHovered ? 1.08 : 1.0)
                            .animation(.spring(response: 0.22, dampingFraction: 0.72), value: isHovered)
                        }
                        .buttonStyle(.plain)
                        .onHover { h in
                            hoveredAppId = h ? "\(app.processIdentifier)" : nil
                        }
                    }
                }
                .padding(.vertical, 3)
            }
        }
    }

    // MARK: - App Item Tile with Mini Dock Parabolic Wave
    private func dockAppItemTile(app: AppInfo) -> some View {
        let isHovered = (hoveredAppId == app.id)

        return Button(action: {
            HapticFeedback.selection()
            NSWorkspace.shared.openApplication(at: app.url, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
        }) {
            VStack(spacing: 4) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isHovered ? Color.white.opacity(0.22) : Color.white.opacity(0.06))
                        .frame(width: 54, height: 54)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(
                                    isHovered
                                        ? LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing)
                                        : LinearGradient(colors: [Color.white.opacity(0.12), Color.white.opacity(0.04)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                    lineWidth: isHovered ? 1.2 : 0.6
                                )
                        )
                        .shadow(color: isHovered ? Color.orange.opacity(0.45) : Color.clear, radius: 8, y: 3)

                    Image(nsImage: app.icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 42, height: 42)
                }
                .scaleEffect(isHovered ? 1.15 : 1.0)
                .animation(.spring(response: 0.22, dampingFraction: 0.72), value: isHovered)

                Text(app.name)
                    .font(.system(size: 9.5, weight: isHovered ? .bold : .medium, design: .rounded))
                    .foregroundColor(isHovered ? .white : .white.opacity(0.85))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: 78)
            }
        }
        .buttonStyle(.plain)
        .onHover { h in
            hoveredAppId = h ? app.id : nil
        }
    }

    // MARK: - 3. 📱 Pioneered Screen Size & Matrix Tab Content
    private var screenMatrixTabContent: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 14) {
                // Hero Pioneer Header Card
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Circle().fill(Color.green).frame(width: 7, height: 7)
                        Text("PIONEERED SCREEN SIZE TRICKSTER")
                            .font(.system(size: 10.5, weight: .heavy, design: .rounded))
                            .foregroundColor(.green)
                    }

                    Text("Trick apps on launch into compact mobile & matrix resolutions so up to 9 apps load natively on your desktop.")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.white.opacity(0.75))
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.green.opacity(0.12))
                        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.green.opacity(0.35), lineWidth: 0.8))
                )

                // Live Action: Resize Active Window Now
                Button(action: {
                    tricksterEngine.clampFrontmostApplication(to: tricksterEngine.defaultProfile)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.down.right.and.arrow.up.left")
                            .font(.system(size: 12, weight: .bold))
                        Text("⚡ Apply Selected Size to Frontmost Window")
                            .font(.system(size: 11.5, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.green)
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                }
                .buttonStyle(.plain)
                .shadow(color: Color.green.opacity(0.40), radius: 6, y: 2)

                // Category Profiles Grid with Stage Manager Magnification Wave
                Text("VIRTUAL DISPLAY PROFILES")
                    .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                    .foregroundColor(.white.opacity(0.50))
                    .padding(.top, 4)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(VirtualScreenProfile.allCases) { profile in
                        virtualProfileCard(profile: profile)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
    }

    @ViewBuilder
    private func virtualProfileCard(profile: VirtualScreenProfile) -> some View {
        let isSelected = (tricksterEngine.defaultProfile == profile)
        let isHovered = (hoveredProfileId == profile.id)

        Button(action: {
            HapticFeedback.selection()
            tricksterEngine.defaultProfile = profile
            tricksterEngine.clampFrontmostApplication(to: profile)
        }) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: profile.icon)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(isSelected ? .green : .white.opacity(0.75))
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
                    .foregroundColor(isSelected ? .green.opacity(0.9) : .white.opacity(0.45))
            }
            .padding(10)
            .background(isSelected ? Color.green.opacity(0.25) : (isHovered ? Color.white.opacity(0.12) : Color.white.opacity(0.06)))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .scaleEffect(isHovered ? 1.05 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { h in
            hoveredProfileId = h ? profile.id : nil
        }
    }

    // MARK: - 4. ⚙️ Embedded Settings Tab Content
    private var settingsTabContent: some View {
        UnifiedSettingsView(isEmbedded: true)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
