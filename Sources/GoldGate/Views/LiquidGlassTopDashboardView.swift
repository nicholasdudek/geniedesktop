import SwiftUI
import AppKit
import Combine

// MARK: - 🪟 Liquid Glass Top Pull-Down Dashboard View
/// A frosted, high-opacity liquid-glass dashboard sliding down from the top edge of the screen
/// on scroll-up or top-edge gesture, combining a Clock/Date widget, Quick Chat, and Mini Settings.
public struct LiquidGlassTopDashboardView: View {
    @Binding var isPresented: Bool
    let screenSize: CGSize

    @ObservedObject var localModels = LocalModelManager.shared
    @ObservedObject var sleepManager = GenieSleepPreventionManager.shared
    @ObservedObject var speechEngine = GenieSpeechRecognitionEngine.shared
    @AppStorage(PrefKey.liquidGlassEnabled) var liquidGlassEnabled: Bool = true
    @AppStorage(PrefKey.showInDock) var showInDock: Bool = true
    @AppStorage(PrefKey.soundEnabled) var soundEnabled: Bool = false
    @AppStorage(PrefKey.agentSandboxEnabled) var agentSandboxEnabled: Bool = true
    @AppStorage(PrefKey.showMiniDockInTopDashboard) var showMiniDockInTopDashboard: Bool = true
    @AppStorage("genieZenModeEnabled") var isZenModeEnabled: Bool = true
    @AppStorage("topDashboardUnlocked") var isUnlockedFromTopDock: Bool = true
    @AppStorage("genieTopDockPosX") var savedPosX: Double = 0.0
    @AppStorage("genieTopDockPosY") var savedPosY: Double = 0.0
    @AppStorage(PrefKey.topEdgeCursorTrigger) var topEdgeCursorTrigger: Bool = false
    @AppStorage("neuralBloomLightningEnabled") var lightningEffectsEnabled: Bool = true
    @ObservedObject private var dockManager = DockAndDesktopManager.shared

    private enum PipCompanionMode: String, CaseIterable, Identifiable {
        case browser = "PiP Browser"
        case finder = "Mini Finder"
        case hub = "Studio Hub"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .browser: return "globe"
            case .finder: return "folder.fill"
            case .hub: return "slider.horizontal.3"
            }
        }
    }

    @State private var selectedTab: Int = 0 // 0: Genie Studio, 1: PiP Browser, 2: Mini Finder, 3: Mini Settings, 4: System Status
    @State private var pipCompanionMode: PipCompanionMode = .browser
    @State private var promptText: String = ""
    @State private var previewAppPid: pid_t? = nil
    @State private var currentTime = Date()
    @State private var dragOffset: CGSize = .zero
    @State private var accumulatedOffset: CGSize = .zero
    @State private var isHovered: Bool = false
    @State private var autoHideWorkItem: DispatchWorkItem? = nil
    @State private var desktopSortFeedback: String? = nil
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    public init(isPresented: Binding<Bool>, screenSize: CGSize) {
        self._isPresented = isPresented
        self.screenSize = screenSize
    }

    /// True once the user has dragged the dashboard off the top edge.
    /// Drives the pin button's emphasis and gates auto-hide.
    private var isMovedFromTop: Bool {
        accumulatedOffset != .zero || dragOffset != .zero
    }

    private func cancelAutoHide() {
        autoHideWorkItem?.cancel()
        autoHideWorkItem = nil
    }

    private func scheduleAutoHide(delay: Double = 0.35) {
        // Disabled: Dock stays firmly down until explicitly closed by user
        cancelAutoHide()
    }

    private func dismissDashboard() {
        cancelAutoHide()
        HapticFeedback.tick()
        savedPosX = accumulatedOffset.width
        savedPosY = accumulatedOffset.height
        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            isPresented = false
            dragOffset = .zero
            DesktopWindowManager.shared.switchToStation(.desktop)
        }
        DesktopWindowManager.shared.setPage(0)
        NotificationCenter.default.post(name: NSNotification.Name("NexusDesktopPageChanged"), object: 0)
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Main Dashboard Container flanked by horizontal margin hover zones
            HStack(spacing: 0) {
                if !isZenModeEnabled {
                    Spacer()
                }

                VStack(spacing: isZenModeEnabled ? 12 : 14) {
                    // 1. Header Clock & Dashboard Widget
                    headerClockWidget

                    if isZenModeEnabled {
                        // 2. Fullscreen Merged Big Dashboard
                        unifiedBigDashboardView
                            .transition(.opacity.combined(with: .scale(scale: 0.99)))
                    } else {
                        // 2. Integrated Liquid Glass Mini Dock (Clock & Chat Suite)
                        if showMiniDockInTopDashboard {
                            LiquidGlassMiniDockView(isPresented: $isPresented, selectedTab: $selectedTab)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        // 3. Segmented Pill Tab Switcher
                        tabSwitcher

                        // 4. Tab Content Pane
                        Group {
                            if selectedTab == 0 {
                                quickChatPane
                            } else if selectedTab == 1 {
                                LiveBrowserCradleView()
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(Color.white.opacity(0.12), lineWidth: 0.8)
                                    )
                            } else if selectedTab == 2 {
                                FinderFileBrowserPaneView()
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(Color.white.opacity(0.12), lineWidth: 0.8)
                                    )
                            } else if selectedTab == 3 {
                                miniSettingsPane
                            } else {
                                systemTelemetryPane
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                        // 5. Retract Handle & Pull Bar
                        retractHandle
                    }
                }
                .padding(.horizontal, isZenModeEnabled ? 12 : 24)
                .padding(.top, isZenModeEnabled ? 10 : 18)
                .padding(.bottom, isZenModeEnabled ? 10 : 12)
                .frame(
                    width: isZenModeEnabled ? (screenSize.width - 12) : min(860, screenSize.width - 48),
                    height: isZenModeEnabled ? (screenSize.height - 12) : min(620, screenSize.height * 0.78)
                )
                // Frosted Deep Glass Background (less transparent / more frosted) + Living Neural Bloom Canvas
                .background(
                    ZStack {
                        if isZenModeEnabled && isPresented, let bloomURL = WallpaperManager.shared.resolvedNeuralBloomURL() {
                            LiveHTMLWallpaperCanvasView(
                                fileURL: bloomURL,
                                isBackdrop: true,
                                lightningEnabled: lightningEffectsEnabled,
                                windowOffset: CGSize(
                                    width: accumulatedOffset.width + dragOffset.width,
                                    height: accumulatedOffset.height + dragOffset.height
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: isZenModeEnabled ? 22 : 28, style: .continuous))
                            .opacity(0.90)
                        }
                        VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow, state: .active)
                        Color.black.opacity(isZenModeEnabled ? 0.40 : 0.62)
                        LinearGradient(
                            colors: [
                                Color.cyan.opacity(isZenModeEnabled ? 0.16 : 0.08),
                                Color.purple.opacity(0.04),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                )
                .clipShape(RoundedRectangle(cornerRadius: isZenModeEnabled ? 22 : 28, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: isZenModeEnabled ? 22 : 28, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    isZenModeEnabled ? Color.cyan.opacity(0.55) : Color.white.opacity(0.35),
                                    Color.white.opacity(0.12),
                                    Color.white.opacity(0.05),
                                    Color.white.opacity(0.20)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.0
                        )
                )
                .shadow(color: Color.black.opacity(0.55), radius: 36, x: 0, y: 16)
                .offset(x: accumulatedOffset.width + dragOffset.width,
                        y: accumulatedOffset.height + dragOffset.height)
                .gesture(
                    DragGesture()
                        .onChanged { val in
                            if isUnlockedFromTopDock {
                                dragOffset = val.translation
                            }
                        }
                        .onEnded { val in
                            if isUnlockedFromTopDock {
                                accumulatedOffset.width += val.translation.width
                                accumulatedOffset.height += val.translation.height
                                savedPosX = accumulatedOffset.width
                                savedPosY = accumulatedOffset.height
                                dragOffset = .zero
                            }
                        }
                )
                .onHover { hovering in
                    isHovered = hovering
                }

                if !isZenModeEnabled {
                    Spacer()
                }
            }

            if !isZenModeEnabled {
                Spacer()
            }
        }
        .frame(width: screenSize.width, height: screenSize.height, alignment: .top)
        .padding(.top, isZenModeEnabled ? 12 : 10)
        .onAppear {
            DesktopWindowManager.shared.elevateForTopDashboard(isPopped: true)
            dragOffset = .zero
            accumulatedOffset = CGSize(width: savedPosX, height: savedPosY)
            isUnlockedFromTopDock = true
        }
        .onDisappear {
            cancelAutoHide()
            savedPosX = accumulatedOffset.width
            savedPosY = accumulatedOffset.height
            dragOffset = .zero
            DesktopWindowManager.shared.elevateForTopDashboard(isPopped: false)
        }
        .onChange(of: isPresented) { _, presented in
            if !presented {
                cancelAutoHide()
                savedPosX = accumulatedOffset.width
                savedPosY = accumulatedOffset.height
                dragOffset = .zero
            }
        }
        .onReceive(timer) { input in
            guard isPresented else { return }
            currentTime = input
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusSpeechTranscriptUpdated"))) { notif in
            if let text = notif.object as? String {
                self.promptText = text
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusVoiceSubmitChat"))) { notif in
            if let text = notif.object as? String, !text.isEmpty {
                self.promptText = text
            }
            if !localModels.isGenerating {
                submitPrompt()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusSpeechClearChat"))) { _ in
            self.promptText = ""
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusSelectTopDockChat"))) { _ in
            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                self.selectedTab = 0
            }
        }
    }

    // MARK: - 1. Header Clock & Date Widget (Window Chrome & Controls)
    private var headerClockWidget: some View {
        HStack(alignment: .center, spacing: 14) {
            // 🔴🟡🟢 Authentic macOS Window Traffic Lights & Time
            HStack(spacing: 12) {
                HStack(spacing: 7) {
                    // Close / Slide Up to Top Edge (Red)
                    Button(action: {
                        dismissDashboard()
                    }) {
                        Circle()
                            .fill(Color(red: 1.0, green: 0.36, blue: 0.34))
                            .frame(width: 12, height: 12)
                            .overlay(
                                Image(systemName: "xmark")
                                    .font(.system(size: 7, weight: .bold))
                                    .foregroundColor(.black.opacity(0.65))
                                    .opacity(isHovered ? 1 : 0)
                            )
                    }
                    .buttonStyle(.plain)
                    .help("Close / Slide up to top ceiling")

                    // Minimize / Compact Mode (Yellow)
                    Button(action: {
                        HapticFeedback.tick()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                            isZenModeEnabled = false
                            dragOffset = .zero
                            accumulatedOffset = .zero
                            savedPosX = 0
                            savedPosY = 0
                        }
                    }) {
                        Circle()
                            .fill(Color(red: 1.0, green: 0.76, blue: 0.20))
                            .frame(width: 12, height: 12)
                            .overlay(
                                Image(systemName: "minus")
                                    .font(.system(size: 7, weight: .bold))
                                    .foregroundColor(.black.opacity(0.65))
                                    .opacity(isHovered ? 1 : 0)
                            )
                    }
                    .buttonStyle(.plain)
                    .help("Minimize / Snap to compact top dock")

                    // Zoom / Fullscreen Toggle (Green)
                    Button(action: {
                        HapticFeedback.selection()
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                            isZenModeEnabled.toggle()
                        }
                    }) {
                        Circle()
                            .fill(Color(red: 0.16, green: 0.80, blue: 0.25))
                            .frame(width: 12, height: 12)
                            .overlay(
                                Image(systemName: isZenModeEnabled ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                                    .font(.system(size: 6, weight: .bold))
                                    .foregroundColor(.black.opacity(0.65))
                                    .opacity(isHovered ? 1 : 0)
                            )
                    }
                    .buttonStyle(.plain)
                    .help(isZenModeEnabled ? "Exit Fullscreen (Windowed Mode)" : "Expand to Fullscreen")
                }
                .padding(.trailing, 4)

                // Digital Clock & Date
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text(timeString(from: currentTime))
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text(periodString(from: currentTime))
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.cyan)
                    }

                    Text(dateString(from: currentTime))
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundColor(.white.opacity(0.70))
                }
            }

            Spacer()

            // 🪟 Center: Draggable Window Handle & Window Title
            HStack(spacing: 8) {
                Image(systemName: "macwindow")
                    .font(.system(size: 11))
                    .foregroundColor(.cyan)

                Text(isZenModeEnabled ? "GENIE FULLSCREEN STUDIO" : "GENIE STUDIO WINDOW")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.90))

                Text("•")
                    .foregroundColor(.white.opacity(0.3))

                Text(isMovedFromTop ? "MOVED (CLICK 2X TO CENTER)" : "DRAGGABLE")
                    .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                    .foregroundColor(isMovedFromTop ? .yellow : .white.opacity(0.50))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(Capsule().fill(Color.white.opacity(0.08)))
            .overlay(Capsule().stroke(Color.white.opacity(0.14), lineWidth: 0.8))
            .help("Window Chrome: Drag anywhere on header to reposition • Double-click to snap back to top-center")

            Spacer()

            // Right: Quick Actions (Active Desktop, Zen Toggle, Snap to Top, Close)
            HStack(spacing: 8) {
                // Clean & Sort Desktop Button
                Button(action: {
                    HapticFeedback.selection()
                    let res = GenieDesktopOrganizerEngine.shared.organize()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        desktopSortFeedback = res.totalItemsMoved > 0 ? "Sorted \(res.totalItemsMoved) items!" : "Desktop is clean!"
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        withAnimation {
                            desktopSortFeedback = nil
                        }
                    }
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.orange)
                        Text(desktopSortFeedback ?? "Sort Desktop 🧹")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(.white.opacity(0.90))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.orange.opacity(0.18)))
                    .overlay(Capsule().stroke(Color.orange.opacity(0.35), lineWidth: 0.8))
                }
                .buttonStyle(.plain)
                .help("Instantly categorize loose desktop files into clean folders (Screenshots, Media, Code, Documents, Archives)")

                // Active Desktop Toggle
                Button(action: {
                    HapticFeedback.selection()
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                        DesktopWindowManager.shared.toggleActiveDesktopFromTopDock()
                    }
                }) {
                    let isActiveDesktop = (DesktopWindowManager.shared.currentPage == 1 && UserDefaults.standard.integer(forKey: PrefKey.appDisplayStage) == 2)
                    HStack(spacing: 5) {
                        Image(systemName: isActiveDesktop ? "sparkles.rectangle.stack.fill" : "square.grid.3x3.fill")
                            .font(.system(size: 11, weight: .bold))
                        Text(isActiveDesktop ? "Hide Apps Grid" : "Active Desktop 🖥️")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(isActiveDesktop ? .yellow : .white.opacity(0.90))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(isActiveDesktop ? Color.yellow.opacity(0.25) : Color.white.opacity(0.12)))
                    .overlay(Capsule().stroke(isActiveDesktop ? Color.yellow.opacity(0.50) : Color.white.opacity(0.18), lineWidth: 0.8))
                }
                .buttonStyle(.plain)
                .help(DesktopWindowManager.shared.currentPage == 1 ? "Hide applications grid and return to clean wallpaper" : "Expand underlying canvas into Active Desktop application matrix in same state")

                // Fullscreen Zen Dashboard Toggle
                Button(action: {
                    HapticFeedback.selection()
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                        isZenModeEnabled.toggle()
                        if isZenModeEnabled {
                            cancelAutoHide()
                        }
                    }
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: isZenModeEnabled ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 11, weight: .bold))
                        Text(isZenModeEnabled ? "Window Mode" : "Fullscreen")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(isZenModeEnabled ? .cyan : .white.opacity(0.90))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(isZenModeEnabled ? Color.cyan.opacity(0.25) : Color.white.opacity(0.12)))
                    .overlay(Capsule().stroke(isZenModeEnabled ? Color.cyan.opacity(0.50) : Color.white.opacity(0.18), lineWidth: 0.8))
                }
                .buttonStyle(.plain)
                .help(isZenModeEnabled ? "Switch to windowed floating mode" : "Expand to beautiful fullscreen unified dashboard")

                if isMovedFromTop {
                    Button(action: {
                        HapticFeedback.selection()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                            dragOffset = .zero
                            accumulatedOffset = .zero
                            savedPosX = 0
                            savedPosY = 0
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.to.line")
                                .font(.system(size: 11))
                            Text("Center Top")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(.white.opacity(0.80))
                        .padding(.horizontal, 9)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color.white.opacity(0.10)))
                        .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.8))
                    }
                    .buttonStyle(.plain)
                    .help("Snap the window back to top-center")
                }

                // Retract Close Button
                Button(action: {
                    dismissDashboard()
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.85))
                        .frame(width: 28, height: 28)
                        .background(Circle().fill(Color.white.opacity(0.12)))
                }
                .buttonStyle(.plain)
                .help("Slide window up into top ceiling")
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            HapticFeedback.tick()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                dragOffset = .zero
                accumulatedOffset = .zero
                savedPosX = 0
                savedPosY = 0
            }
        }
    }

    // MARK: - 2. Tab Switcher
    private var tabSwitcher: some View {
        HStack(spacing: 5) {
            tabButton(title: "Genie Studio", icon: "sparkles", index: 0)
            tabButton(title: "PiP Browser", icon: "globe", index: 1)
            tabButton(title: "Mini Finder", icon: "folder.fill", index: 2)
            tabButton(title: "Mini Settings", icon: "gearshape.fill", index: 3)
            tabButton(title: "System Status", icon: "chart.bar.xaxis", index: 4)
        }
        .padding(3)
        .background(Capsule().fill(Color.white.opacity(0.08)))
    }

    private func tabButton(title: String, icon: String, index: Int) -> some View {
        Button(action: {
            HapticFeedback.tick()
            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                selectedTab = index
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(title)
                    .font(.system(size: 12, weight: selectedTab == index ? .semibold : .medium))
            }
            .foregroundColor(selectedTab == index ? .black : .white.opacity(0.80))
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(selectedTab == index ? Color.white : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 3. Unified Genie Studio Pane (GENIE Blocks + Chat)
    private var genieStudioPane: some View {
        VStack(spacing: 8) {
            // ── ⚡️ Retro Terminal ASCII Box (GENIE Blocks) ──
            GenieTopDockNeuralEngineBannerView()
                .transition(.opacity.combined(with: .scale(scale: 0.98)))

            // ── 💬 Consolidated Genie Chat & Intelligence ──
            quickChatPane
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 3b. Quick Chat Pane (Genie Studio)
    private var quickChatPane: some View {
        VStack(spacing: 10) {
            // Scrollable Message Conversation View
            ScrollViewReader { scrollProxy in
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVStack(spacing: 10) {
                        if localModels.chatHistory.isEmpty && !localModels.isGenerating && localModels.currentResponse.isEmpty {
                            VStack(spacing: 12) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 26))
                                    .foregroundColor(.cyan.opacity(0.85))
                                    .padding(.top, 14)

                                Text("Genie Studio")
                                    .font(.system(size: 15, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)

                                Text("Unified Slide-Down Neural Chat, Workflows & System Intelligence")
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundColor(.white.opacity(0.65))
                                    .multilineTextAlignment(.center)

                                // Quick suggestion chips
                                HStack(spacing: 8) {
                                    suggestionChip("Summarize Desktop") { promptText = "Summarize the active desktop windows and status." }
                                    suggestionChip("Tail Recent Items") { promptText = "Show my recent computer items and documents." }
                                    suggestionChip("Check System") { promptText = "Report system resource health." }
                                }
                                .padding(.top, 4)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                        } else {
                            ForEach(localModels.chatHistory) { msg in
                                dashboardChatBubble(msg: msg)
                                    .id(msg.id)
                            }

                            if localModels.isGenerating || !localModels.currentResponse.isEmpty {
                                dashboardStreamingBubble
                                    .id("dashboard_streaming_bubble")
                            }
                        }

                        Color.clear
                            .frame(height: 8)
                            .id("dashboard_chat_bottom")
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                }
                .genieThickScrollBars()
                .onChange(of: localModels.chatHistory.count) {
                    if let lastMsg = localModels.chatHistory.last {
                        withAnimation(.easeOut(duration: 0.2)) {
                            scrollProxy.scrollTo(lastMsg.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: localModels.currentResponse) {
                    withAnimation(.easeOut(duration: 0.15)) {
                        scrollProxy.scrollTo("dashboard_streaming_bubble", anchor: .bottom)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.black.opacity(0.25))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.10), lineWidth: 0.75)
            )

            // Inactive (Background) Applications Strip inside Quick Chat
            chatInactiveAppsStrip

            // Input field with mic dictation, send / stop button
            HStack(spacing: 8) {
                // Mic dictation button
                Button(action: {
                    HapticFeedback.selection()
                    speechEngine.toggleListening()
                }) {
                    ZStack {
                        if speechEngine.isActivelyRecording {
                            Circle()
                                .fill(Color.red.opacity(0.25))
                                .frame(width: 26, height: 26)
                                .scaleEffect(1.0 + CGFloat(speechEngine.audioLevel) * 0.7)
                                .animation(.easeOut(duration: 0.1), value: speechEngine.audioLevel)
                        }
                        Image(systemName: speechEngine.isActivelyRecording ? "waveform.circle.fill" : "mic.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(speechEngine.isActivelyRecording ? .red : .white.opacity(0.65))
                    }
                }
                .buttonStyle(.plain)
                .help(speechEngine.isActivelyRecording ? "Stop voice dictation" : "Start voice dictation")

                TextField("Ask Genie anything...", text: $promptText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundColor(.white)
                    .onSubmit {
                        if !localModels.isGenerating {
                            submitPrompt()
                        }
                    }

                if localModels.isGenerating {
                    Button(action: {
                        HapticFeedback.selection()
                        localModels.stopGeneration()
                    }) {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.orange)
                    }
                    .buttonStyle(.plain)
                    .help("Stop generating")
                } else {
                    Button(action: submitPrompt) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(promptText.trimmingCharacters(in: .whitespaces).isEmpty ? .white.opacity(0.3) : .cyan)
                    }
                    .buttonStyle(.plain)
                    .disabled(promptText.trimmingCharacters(in: .whitespaces).isEmpty)
                    .help("Send prompt")
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.09))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.18), lineWidth: 0.75)
            )

            // AI Model Indicator, Clear History & Full Chat Shortcut
            HStack(spacing: 12) {
                Text("Model: \(localModels.selectedModelDisplayName)")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.55))

                Spacer()

                if !localModels.chatHistory.isEmpty {
                    Button(action: {
                        HapticFeedback.tick()
                        localModels.clearChatHistory()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "trash")
                                .font(.system(size: 10))
                            Text("Clear")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .foregroundColor(.white.opacity(0.50))
                    }
                    .buttonStyle(.plain)
                    .help("Clear slide-down chat history")
                }

                Button("Genie Studio ↗") {
                    withAnimation {
                        isPresented = false
                    }
                    FinderChatWindowManager.shared.show(tab: .chat)
                }
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.cyan)
                .buttonStyle(.plain)
                .help("Open full Genie Studio window (⌘⌥Space)")

                Button("Active Desktop 🖥️") {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                        DesktopWindowManager.shared.toggleActiveDesktopFromTopDock()
                    }
                }
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.yellow)
                .buttonStyle(.plain)
                .help("Expand to active desktop application matrix in same state")
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Inactive / Background Applications Strip inside Quick Chat
    private var chatInactiveAppsStrip: some View {
        let currentActivePid = dockManager.activePid > 0 ? dockManager.activePid : (NSWorkspace.shared.frontmostApplication?.processIdentifier ?? 0)
        let inactiveApps = dockManager.dockItems.filter { item in
            guard item.isRunning, let app = item.runningApp, !app.isTerminated else { return false }
            let isFrontmost = (item.processIdentifier == currentActivePid || app.processIdentifier == currentActivePid || app.isActive)
            return !isFrontmost && item.id != "com.nicholasdudek.genie" && item.bundleIdentifier != "com.nicholasdudek.genie"
        }

        return Group {
            if !inactiveApps.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        Label("Background Apps:", systemImage: "macwindow.on.rectangle")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white.opacity(0.55))
                            .padding(.trailing, 2)

                        ForEach(inactiveApps) { item in
                            inactiveAppPill(for: item)
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                }
                .frame(height: 26)
            }
        }
    }

    @ViewBuilder
    private func inactiveAppPill(for item: DockAppItem) -> some View {
        InactiveAppPillView(item: item, previewAppPid: $previewAppPid, isPresented: $isPresented)
            .contextMenu {
                inactiveAppContextMenu(for: item)
            }
    }

    @ViewBuilder
    private func inactiveAppContextMenu(for item: DockAppItem) -> some View {
        Button("Inspect Window & Summarize...") {
            previewAppPid = item.processIdentifier
        }
        Button("Switch to \(item.name)") {
            item.runningApp?.unhide()
            _ = item.runningApp?.activate(options: [.activateAllWindows])
            if let app = item.runningApp {
                SmartGridManager.shared.bringToFront(app: app)
            }
            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                isPresented = false
            }
        }
        Button("Open in Dialogue Studio Tab") {
            FinderChatWindowManager.shared.show(tab: .app(bundleId: item.bundleIdentifier ?? item.name, name: item.name))
            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                isPresented = false
            }
        }
        Button("Ask Genie about \(item.name)") {
            promptText = "Help me with \(item.name): "
        }
        Divider()
        Button("Show All Windows") {
            item.runningApp?.unhide()
            _ = item.runningApp?.activate(options: [.activateAllWindows])
        }
        if item.runningApp?.isHidden == true {
            Button("Unhide") {
                item.runningApp?.unhide()
                _ = item.runningApp?.activate()
            }
        } else {
            Button("Hide") {
                item.runningApp?.hide()
            }
        }
        Button("Quit \(item.name)") {
            item.runningApp?.terminate()
        }
    }

    @ViewBuilder
    private func dashboardChatBubble(msg: ChatMessage) -> some View {
        if msg.role == "user" {
            HStack {
                Spacer(minLength: 40)
                Text(verbatim: msg.content)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.white)
                    .textSelection(.enabled)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.85), Color.blue.opacity(0.70)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .shadow(color: Color.black.opacity(0.15), radius: 4, y: 2)
            }
        } else {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "sparkle")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.cyan)
                    .padding(5)
                    .background(Circle().fill(Color.cyan.opacity(0.15)))

                VStack(alignment: .leading, spacing: 6) {
                    if let think = msg.thinking, !think.isEmpty {
                        GenieThinkingAccordionView(thinking: think)
                    }
                    GenieMarkdownMessageView(text: msg.content)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .fill(Color.white.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 13, style: .continuous)
                    .stroke(Color.white.opacity(0.10), lineWidth: 0.5)
            )
        }
    }

    private var dashboardStreamingBubble: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "sparkle")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.cyan)
                .padding(5)
                .background(Circle().fill(Color.cyan.opacity(0.15)))

            VStack(alignment: .leading, spacing: 6) {
                if !localModels.currentThinking.isEmpty {
                    GenieThinkingAccordionView(
                        thinking: localModels.currentThinking,
                        isStreaming: localModels.isGenerating
                    )
                }

                if !localModels.currentResponse.isEmpty {
                    GenieMarkdownMessageView(
                        text: localModels.currentResponse,
                        isStreaming: localModels.isGenerating
                    )
                } else if localModels.isGenerating {
                    HStack(spacing: 6) {
                        ProgressView()
                            .scaleEffect(0.65)
                        Text("Genie is thinking...")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.65))
                        GenieStreamingCursorView()
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(Color.white.opacity(0.07))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .stroke(Color.cyan.opacity(0.20), lineWidth: 0.75)
        )
    }

    private func suggestionChip(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            HapticFeedback.tick()
            action()
        }) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.85))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color.white.opacity(0.10)))
                .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }

    private func submitPrompt() {
        guard !promptText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let text = promptText
        promptText = ""
        HapticFeedback.success()
        localModels.generate(prompt: text)
    }

    // MARK: - 🪟 Fullscreen Unified Big Dashboard View (Zen Mode)
    private var unifiedBigDashboardView: some View {
        HStack(spacing: 14) {
            // 1. Left Column: Saved Sessions, History & App Strip
            zenSessionsSidebarView
                .frame(width: 250)

            // 2. Center Column: Big Expansive Chat Canvas
            zenMainChatCanvasView
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // 3. Right Column: PiP Companion Watcher (Browser / Mini Finder / Studio Hub)
            zenInspectorHubView
                .frame(width: max(420, min(560, screenSize.width * 0.36)))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - 1. Left Column: Sessions & Switcher
    private var zenSessionsSidebarView: some View {
        VStack(spacing: 10) {
            // Header: "Chats" + "+ New Chat"
            HStack {
                Label("Chats", systemImage: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 12.5, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                Button(action: {
                    HapticFeedback.selection()
                    localModels.startNewChat()
                    promptText = ""
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 10, weight: .bold))
                        Text("New")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.cyan.opacity(0.18)))
                    .overlay(Capsule().stroke(Color.cyan.opacity(0.35), lineWidth: 0.7))
                }
                .buttonStyle(.plain)
                .help("Start a fresh conversation")
            }
            .padding(.horizontal, 4)
            .padding(.top, 2)

            // Model Switcher Pill Menu
            Menu {
                Section("Local Engine Models") {
                    ForEach(localModels.availableModels, id: \.id) { model in
                        Button(action: {
                            localModels.manualSelectedModel = model.name
                        }) {
                            HStack {
                                Text(model.name)
                                if localModels.effectiveModel == model.name {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                }
                if !LocalModelManager.cloudModels.isEmpty {
                    Section("Cloud AI Models") {
                        ForEach(LocalModelManager.cloudModels, id: \.id) { model in
                            Button(action: {
                                localModels.manualSelectedModel = model.id
                            }) {
                                HStack {
                                    Text(model.displayName)
                                    if localModels.effectiveModel == model.id {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "cpu.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.cyan)
                    Text(localModels.selectedModelDisplayName)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.90))
                        .lineLimit(1)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.40))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.08)))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.12), lineWidth: 0.7))
            }
            .menuStyle(.borderlessButton)

            // Saved Sessions ScrollView
            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(spacing: 5) {
                    if localModels.savedSessions.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "bubble.middle.bottom")
                                .font(.system(size: 18))
                                .foregroundColor(.white.opacity(0.30))
                                .padding(.top, 20)
                            Text("No saved sessions")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.45))
                            Text("Conversations auto-save as you chat.")
                                .font(.system(size: 9.5))
                                .foregroundColor(.white.opacity(0.35))
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    } else {
                        ForEach(localModels.savedSessions) { sess in
                            let isCurrent = (sess.id == localModels.currentSessionId)
                            Button(action: {
                                HapticFeedback.selection()
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                                    localModels.loadSession(sess)
                                }
                            }) {
                                HStack(alignment: .center, spacing: 7) {
                                    Image(systemName: isCurrent ? "bubble.left.fill" : "bubble.left")
                                        .font(.system(size: 10.5))
                                        .foregroundColor(isCurrent ? .cyan : .white.opacity(0.50))

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(sess.title.isEmpty ? "Untitled Chat" : sess.title)
                                            .font(.system(size: 11, weight: isCurrent ? .semibold : .medium))
                                            .foregroundColor(isCurrent ? .white : .white.opacity(0.85))
                                            .lineLimit(1)

                                        Text(sess.updatedAt, style: .date)
                                            .font(.system(size: 8.5))
                                            .foregroundColor(.white.opacity(0.45))
                                    }

                                    Spacer()

                                    if !sess.messages.isEmpty {
                                        Text("\(sess.messages.count)")
                                            .font(.system(size: 8.5, weight: .bold, design: .rounded))
                                            .foregroundColor(.white.opacity(0.70))
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 1.5)
                                            .background(Capsule().fill(Color.white.opacity(0.10)))
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                                        .fill(isCurrent ? Color.cyan.opacity(0.20) : Color.white.opacity(0.05))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                                        .stroke(isCurrent ? Color.cyan.opacity(0.45) : Color.white.opacity(0.08), lineWidth: 0.75)
                                )
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button("Delete Conversation", role: .destructive) {
                                    localModels.deleteSession(id: sess.id)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 2)
            }
            .genieThickScrollBars()

            // Inactive Apps Strip at Bottom of Sidebar
            chatInactiveAppsStrip
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.26))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 0.75)
                )
        )
    }

    // MARK: - 2. Center Column: Big Expansive Chat Canvas
    private var zenMainChatCanvasView: some View {
        VStack(spacing: 10) {
            // Scrollable Message Conversation View
            ScrollViewReader { scrollProxy in
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVStack(spacing: 12) {
                        if localModels.chatHistory.isEmpty && !localModels.isGenerating && localModels.currentResponse.isEmpty {
                            VStack(spacing: 16) {
                                // 🎮 Iconic 8-Bit Mario Block Letters Hero Banner
                                GenieTopDockNeuralEngineBannerView(heroMode: true)
                                    .padding(.top, 14)

                                Text("Autonomous Mac Orchestration, Coding Studio, & Neural Intelligence.")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.white.opacity(0.65))
                                    .multilineTextAlignment(.center)

                                // Quick suggestion chips grid
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                    suggestionChip("🖥️ Summarize Desktop Windows") { promptText = "Summarize the active desktop windows, running processes, and open tabs." }
                                    suggestionChip("📜 Tail Recent Computer Items") { promptText = "Show my recent computer items, opened documents, and past files." }
                                    suggestionChip("🧠 Show Trained Mac Applications") { promptText = "List all installed applications on my Mac and what automation scripts you support." }
                                    suggestionChip("⚡ Report System Vitals") { promptText = "Report real-time Apple Silicon memory pressure and system health." }
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 6)
                            }
                            .frame(maxWidth: 720)
                            .padding(.vertical, 16)
                        } else {
                            ForEach(localModels.chatHistory) { msg in
                                dashboardChatBubble(msg: msg)
                                    .id(msg.id)
                            }

                            if localModels.isGenerating || !localModels.currentResponse.isEmpty {
                                dashboardStreamingBubble
                                    .id("dashboard_streaming_bubble")
                            }
                        }

                        Color.clear
                            .frame(height: 10)
                            .id("dashboard_chat_bottom")
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                }
                .genieThickScrollBars()
                .onChange(of: localModels.chatHistory.count) {
                    if let lastMsg = localModels.chatHistory.last {
                        withAnimation(.easeOut(duration: 0.2)) {
                            scrollProxy.scrollTo(lastMsg.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: localModels.currentResponse) {
                    withAnimation(.easeOut(duration: 0.15)) {
                        scrollProxy.scrollTo("dashboard_streaming_bubble", anchor: .bottom)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.black.opacity(0.24))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.white.opacity(0.10), lineWidth: 0.75)
                    )
            )

            // Bottom Prompt Composer
            HStack(spacing: 10) {
                // Mic dictation button
                Button(action: {
                    HapticFeedback.selection()
                    speechEngine.toggleListening()
                }) {
                    ZStack {
                        if speechEngine.isActivelyRecording {
                            Circle()
                                .fill(Color.red.opacity(0.25))
                                .frame(width: 28, height: 28)
                                .scaleEffect(1.0 + CGFloat(speechEngine.audioLevel) * 0.7)
                                .animation(.easeOut(duration: 0.1), value: speechEngine.audioLevel)
                        }
                        Image(systemName: speechEngine.isActivelyRecording ? "waveform.circle.fill" : "mic.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(speechEngine.isActivelyRecording ? .red : .white.opacity(0.65))
                    }
                }
                .buttonStyle(.plain)
                .help(speechEngine.isActivelyRecording ? "Stop voice dictation" : "Start voice dictation")

                TextField("Ask Genie anything... (Press Return to send)", text: $promptText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13.5))
                    .foregroundColor(.white)
                    .onSubmit {
                        if !localModels.isGenerating {
                            submitPrompt()
                        }
                    }

                if localModels.isGenerating {
                    Button(action: {
                        HapticFeedback.selection()
                        localModels.stopGeneration()
                    }) {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.orange)
                    }
                    .buttonStyle(.plain)
                    .help("Stop generating")
                } else {
                    Button(action: submitPrompt) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(promptText.trimmingCharacters(in: .whitespaces).isEmpty ? .white.opacity(0.3) : .cyan)
                    }
                    .buttonStyle(.plain)
                    .disabled(promptText.trimmingCharacters(in: .whitespaces).isEmpty)
                    .help("Send prompt")
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(Color.white.opacity(0.09))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .stroke(Color.white.opacity(0.18), lineWidth: 0.8)
            )
        }
    }

    // MARK: - 3. Right Column: Studio Hub & PiP Companion Watcher
    private var zenInspectorHubView: some View {
        VStack(spacing: 8) {
            // Header with PiP View Switcher
            HStack(spacing: 5) {
                ForEach(PipCompanionMode.allCases) { mode in
                    Button(action: {
                        HapticFeedback.selection()
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.82)) {
                            pipCompanionMode = mode
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: mode.icon)
                                .font(.system(size: 10, weight: .semibold))
                            Text(mode.rawValue)
                                .font(.system(size: 10.5, weight: pipCompanionMode == mode ? .bold : .medium))
                        }
                        .foregroundColor(pipCompanionMode == mode ? .black : .white.opacity(0.85))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule().fill(pipCompanionMode == mode ? Color.cyan : Color.white.opacity(0.08))
                        )
                        .overlay(
                            Capsule().stroke(pipCompanionMode == mode ? Color.cyan.opacity(0.8) : Color.white.opacity(0.12), lineWidth: 0.7)
                        )
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                Button("Active Desktop 🖥️") {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                        DesktopWindowManager.shared.toggleActiveDesktopFromTopDock()
                    }
                }
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.yellow)
                .buttonStyle(.plain)
                .help("Expand to active desktop in same state")
            }
            .padding(.horizontal, 4)
            .padding(.top, 2)

            // PiP Watcher Viewport (Live Browser / Mini Finder / Studio Telemetry)
            Group {
                switch pipCompanionMode {
                case .browser:
                    VStack(spacing: 0) {
                        LiveBrowserCradleView()
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.white.opacity(0.14), lineWidth: 0.8)
                            )
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                case .finder:
                    VStack(spacing: 0) {
                        FinderFileBrowserPaneView()
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(Color.white.opacity(0.14), lineWidth: 0.8)
                            )
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                case .hub:
                    zenStudioTelemetryCards
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.26))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 0.75)
                )
        )
    }

    private var zenStudioTelemetryCards: some View {
        ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 10) {
                    // System Vitals Card
                    VStack(alignment: .leading, spacing: 7) {
                        Text("SYSTEM VITALS")
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundColor(.white.opacity(0.50))

                        HStack(spacing: 6) {
                            telemetryCard(title: "Active Model", value: localModels.selectedModelDisplayName, icon: "cpu.fill")
                            telemetryCard(title: "Sandbox", value: agentSandboxEnabled ? "Restricted 🛡️" : "Custom 🔒", icon: "lock.shield")
                        }

                        HStack(spacing: 6) {
                            telemetryCard(title: "Clamshell", value: sleepManager.isSleepDisabled ? "Awake ⚡" : "Normal 💤", icon: "display.2")
                            telemetryCard(title: "Battery", value: "Ready 🔋", icon: "bolt.fill")
                        }
                    }
                    .padding(9)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 0.75))

                    // Quick Actions
                    VStack(alignment: .leading, spacing: 7) {
                        Text("QUICK ACTIONS")
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundColor(.white.opacity(0.50))

                        Button(action: {
                            HapticFeedback.selection()
                            let wsURL = URL(fileURLWithPath: NSString(string: "~/Desktop/Genie").expandingTildeInPath)
                            NSWorkspace.shared.open(wsURL)
                        }) {
                            HStack {
                                Image(systemName: "folder.fill")
                                    .foregroundColor(.yellow)
                                Text("Open Workspace in Finder")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white.opacity(0.85))
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 9))
                                    .foregroundColor(.white.opacity(0.40))
                            }
                            .padding(.horizontal, 9)
                            .padding(.vertical, 6)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.06)))
                        }
                        .buttonStyle(.plain)

                        if !localModels.chatHistory.isEmpty {
                            Button(action: {
                                HapticFeedback.tick()
                                localModels.clearChatHistory()
                            }) {
                                HStack {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red.opacity(0.85))
                                    Text("Clear Current Chat")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.white.opacity(0.85))
                                    Spacer()
                                }
                                .padding(.horizontal, 9)
                                .padding(.vertical, 6)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.06)))
                            }
                            .buttonStyle(.plain)

                            Button(action: {
                                HapticFeedback.success()
                                let transcript = localModels.chatHistory.map { "\($0.role.uppercased()):\n\($0.content)\n" }.joined(separator: "\n---\n")
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(transcript, forType: .string)
                            }) {
                                HStack {
                                    Image(systemName: "doc.on.doc.fill")
                                        .foregroundColor(.cyan)
                                    Text("Copy Full Transcript")
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(.white.opacity(0.85))
                                    Spacer()
                                }
                                .padding(.horizontal, 9)
                                .padding(.vertical, 6)
                                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.06)))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(9)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 0.75))

                    // Atmosphere & Settings Toggles
                    VStack(alignment: .leading, spacing: 6) {
                        Text("ATMOSPHERE")
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundColor(.white.opacity(0.50))

                        settingToggleRow(
                            title: "Neural Bloom Lightning",
                            subtitle: "Interactive electric arcs",
                            icon: "bolt.fill",
                            isOn: $lightningEffectsEnabled
                        )

                        settingToggleRow(
                            title: "Apple Liquid Glass",
                            subtitle: "Specular frosted materials",
                            icon: "sparkles",
                            isOn: $liquidGlassEnabled
                        )

                        settingToggleRow(
                            title: "Clamshell Awake",
                            subtitle: "Keeps desktop active when lid closed",
                            icon: "display.2",
                            isOn: Binding(
                                get: { sleepManager.isSleepDisabled },
                                set: { _ in sleepManager.toggleSleepPrevention() }
                            )
                        )
                    }
                    .padding(9)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 0.75))
                }
            }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.26))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.10), lineWidth: 0.75)
                )
        )
    }

    // MARK: - 4. Mini Settings Pane
    private var miniSettingsPane: some View {
        VStack(spacing: 10) {
            settingToggleRow(
                title: "Unlock from Top Dock",
                subtitle: "Allow dashboard to float and move freely across the screen",
                icon: "arrow.up.and.down.and.arrow.left.and.right",
                isOn: $isUnlockedFromTopDock
            )

            settingToggleRow(
                title: "Zen Mode Neural Bloom",
                subtitle: "Living bioluminescent particle backdrop behind chat and widgets",
                icon: "leaf.fill",
                isOn: $isZenModeEnabled
            )

            settingToggleRow(
                title: "Neural Bloom Lightning",
                subtitle: "Electric plasma lightning arcs when moving cursor or dragging dashboard",
                icon: "bolt.fill",
                isOn: $lightningEffectsEnabled
            )

            settingToggleRow(
                title: "Apple Liquid Glass",
                subtitle: "Specular frosted materials across windows and docks",
                icon: "sparkles",
                isOn: $liquidGlassEnabled
            )

            settingToggleRow(
                title: "Agent Sandbox Protection",
                subtitle: "Confine AI agent shell commands to safe workspace folder",
                icon: "shield.checkerboard",
                isOn: $agentSandboxEnabled
            )

            settingToggleRow(
                title: "Top Ceiling Mini Dock",
                subtitle: "Show running and pinned macOS applications alongside the clock & chat",
                icon: "dock.rectangle",
                isOn: $showMiniDockInTopDashboard
            )

            settingToggleRow(
                title: "Show in macOS Dock",
                subtitle: "Keep Genie icon present on Apple's native Dock",
                icon: "dock.arrow.up.rectangle",
                isOn: $showInDock
            )

            settingToggleRow(
                title: "Clamshell Awake",
                subtitle: "Keeps desktop awake when closed to connect to monitor",
                icon: "display.2",
                isOn: Binding(
                    get: { sleepManager.isSleepDisabled },
                    set: { _ in sleepManager.toggleSleepPrevention() }
                )
            )

            settingToggleRow(
                title: "Audio Feedback & Sound",
                subtitle: "Haptic and sound effects on desktop navigation",
                icon: "speaker.wave.2.fill",
                isOn: $soundEnabled
            )
        }
        .padding(.vertical, 6)
    }

    private func settingToggleRow(title: String, subtitle: String, icon: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.cyan)
                .frame(width: 24, height: 24)
                .background(Circle().fill(Color.white.opacity(0.08)))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 10.5))
                    .foregroundColor(.white.opacity(0.55))
            }

            Spacer()

            Toggle("", isOn: isOn)
                .toggleStyle(SwitchToggleStyle(tint: .cyan))
                .labelsHidden()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))
    }

    // MARK: - 5. System Telemetry Pane
    private var systemTelemetryPane: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                telemetryCard(title: "Active Screen", value: "\(Int(screenSize.width))×\(Int(screenSize.height))", icon: "display")
                telemetryCard(title: "Workspace Mode", value: "Page 0 / Desktop", icon: "square.grid.2x2")
                telemetryCard(title: "Active Model", value: localModels.selectedModelDisplayName, icon: "cpu")
            }

            HStack(spacing: 12) {
                telemetryCard(title: "Sandbox Folder", value: "~/Desktop/Genie", icon: "folder.fill")
                telemetryCard(title: "Security State", value: agentSandboxEnabled ? "Restricted 🛡️" : "Custom 🔒", icon: "lock.shield")
                telemetryCard(title: "Clamshell Awake", value: sleepManager.isSleepDisabled ? "Awake" : "Normal", icon: "display.2")
            }
        }
        .padding(.vertical, 8)
    }

    private func telemetryCard(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(.cyan)
                Text(title)
                    .font(.system(size: 10.5))
                    .foregroundColor(.white.opacity(0.60))
            }

            Text(value)
                .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.06)))
    }

    // MARK: - 6. Retract Handle
    private var retractHandle: some View {
        Button(action: {
            dismissDashboard()
        }) {
            VStack(spacing: 3) {
                Capsule()
                    .fill(Color.white.opacity(0.35))
                    .frame(width: 36, height: 4)
                Image(systemName: "chevron.up")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.50))
            }
            .padding(.top, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter.string(from: date)
    }

    private func periodString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "a"
        return formatter.string(from: date).uppercased()
    }

    private func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - 💊 Inactive App Pill Subview
private struct InactiveAppPillView: View {
    let item: DockAppItem
    @Binding var previewAppPid: pid_t?
    @Binding var isPresented: Bool

    var body: some View {
        HStack(spacing: 2) {
            Button(action: {
                HapticFeedback.selection()
                item.runningApp?.unhide()
                _ = item.runningApp?.activate(options: [.activateAllWindows])
                if let app = item.runningApp {
                    SmartGridManager.shared.bringToFront(app: app)
                }
                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                    isPresented = false
                }
            }) {
                HStack(spacing: 5) {
                    if let icon = item.icon {
                        Image(nsImage: icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 15, height: 15)
                    } else {
                        Image(systemName: "app.dashed")
                            .frame(width: 15, height: 15)
                    }

                    Text(item.name)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.92))

                    Circle()
                        .fill(Color.cyan)
                        .frame(width: 3.5, height: 3.5)
                        .shadow(color: Color.cyan.opacity(0.8), radius: 2)
                }
                .padding(.leading, 7)
                .padding(.trailing, 3)
                .padding(.vertical, 3.5)
            }
            .buttonStyle(.plain)

            Button(action: {
                HapticFeedback.selection()
                previewAppPid = item.processIdentifier
            }) {
                Image(systemName: "sparkle.magnifyingglass")
                    .font(.system(size: 8.5))
                    .foregroundColor(.cyan.opacity(0.85))
                    .padding(.trailing, 6)
                    .padding(.vertical, 3.5)
            }
            .buttonStyle(.plain)
            .help("Preview window & summarize with Genie")
        }
        .background(
            Capsule()
                .fill(Color.white.opacity(0.09))
                .overlay(
                    Capsule().strokeBorder(Color.white.opacity(0.18), lineWidth: 0.7)
                )
        )
        .help("\(item.name) (Background App) — Click to switch, inspect to summarize")
        .popover(
            isPresented: Binding(
                get: { previewAppPid == item.processIdentifier },
                set: { if !$0 { previewAppPid = nil } }
            ),
            arrowEdge: .bottom
        ) {
            AppWindowHoverPreviewCard(
                pid: item.processIdentifier,
                name: item.name,
                icon: item.icon,
                bundleId: item.bundleIdentifier,
                runningApp: item.runningApp,
                onDismiss: { previewAppPid = nil }
            )
        }
    }
}
