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
    @AppStorage(PrefKey.showMiniDockInTopDashboard) var showMiniDockInTopDashboard: Bool = false
    @AppStorage("genieZenModeEnabled") var isZenModeEnabled: Bool = false
    @AppStorage("topDashboardUnlocked") var isUnlockedFromTopDock: Bool = false
    @AppStorage("neuralBloomLightningEnabled") var lightningEffectsEnabled: Bool = true
    @ObservedObject private var dockManager = DockAndDesktopManager.shared

    @State private var selectedTab: Int = 0 // 0: Quick Chat, 1: Mini Settings, 2: System Telemetry
    @State private var promptText: String = ""
    @State private var previewAppPid: pid_t? = nil
    @State private var currentTime = Date()
    @State private var dragOffset: CGSize = .zero
    @State private var accumulatedOffset: CGSize = .zero
    @State private var isHovered: Bool = false
    @State private var autoHideWorkItem: DispatchWorkItem? = nil
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
        // Don't auto-hide a dock the user has dragged away from the top edge.
        // This used to key off isUnlockedFromTopDock, but pinning now leaves the
        // dock unlocked-but-parked, so that flag no longer means "floating" —
        // the offset does.
        guard !isZenModeEnabled && accumulatedOffset == .zero else { return }
        guard promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        guard !LocalModelManager.shared.isGenerating else { return }

        cancelAutoHide()
        let binding = _isPresented
        let work = DispatchWorkItem {
            guard !LocalModelManager.shared.isGenerating else { return }
            withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                binding.wrappedValue = false
                DesktopWindowManager.shared.switchToStation(.desktop)
            }
            DesktopWindowManager.shared.setPage(0)
            NotificationCenter.default.post(name: NSNotification.Name("NexusDesktopPageChanged"), object: 0)
        }
        autoHideWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    private func dismissDashboard() {
        cancelAutoHide()
        HapticFeedback.tick()
        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
            isPresented = false
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
                        .contentShape(Rectangle())
                        .onHover { isOver in
                            if isOver {
                                scheduleAutoHide(delay: 0.15)
                            }
                        }
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
                            LiquidGlassMiniDockView(isPresented: $isPresented)
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        // 3. Segmented Pill Tab Switcher
                        tabSwitcher

                        // 4. Tab Content Pane
                        Group {
                            if selectedTab == 0 {
                                quickChatPane
                            } else if selectedTab == 1 {
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
                .padding(.horizontal, isZenModeEnabled ? 20 : 24)
                .padding(.top, isZenModeEnabled ? 14 : 18)
                .padding(.bottom, isZenModeEnabled ? 14 : 12)
                .frame(
                    width: isZenModeEnabled ? (screenSize.width - 24) : min(860, screenSize.width - 48),
                    height: isZenModeEnabled ? (screenSize.height - 24) : min(620, screenSize.height * 0.78)
                )
                // Frosted Deep Glass Background (less transparent / more frosted) + Living Neural Bloom Canvas
                .background(
                    ZStack {
                        if let bloomURL = WallpaperManager.shared.resolvedNeuralBloomURL() {
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
                            .opacity(isZenModeEnabled ? 0.90 : 0.65)
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
                                dragOffset = .zero
                            }
                        }
                )
                .onHover { hovering in
                    isHovered = hovering
                    if hovering {
                        cancelAutoHide()
                    } else if !isZenModeEnabled {
                        scheduleAutoHide(delay: 0.35)
                    }
                }

                if !isZenModeEnabled {
                    Spacer()
                        .contentShape(Rectangle())
                        .onHover { isOver in
                            if isOver {
                                scheduleAutoHide(delay: 0.15)
                            }
                        }
                }
            }

            if !isZenModeEnabled {
                Spacer()
                    .contentShape(Rectangle())
                    .onHover { isOver in
                        if isOver {
                            scheduleAutoHide(delay: 0.15)
                        }
                    }
                    .onTapGesture {
                        dismissDashboard()
                    }
            }
        }
        .frame(width: screenSize.width, height: screenSize.height, alignment: .top)
        .padding(.top, isZenModeEnabled ? 12 : 10)
        .onAppear {
            DesktopWindowManager.shared.elevateForTopDashboard(isPopped: true)
            // Come up pinned to the top edge, then release after a beat so the
            // dock is draggable from there. Without this the persisted
            // "topDashboardUnlocked" (false by default) would leave it stuck.
            dragOffset = .zero
            accumulatedOffset = .zero
            isUnlockedFromTopDock = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                isUnlockedFromTopDock = true
            }
        }
        .onDisappear {
            cancelAutoHide()
            DesktopWindowManager.shared.elevateForTopDashboard(isPopped: false)
        }
        .onChange(of: isPresented) { _, presented in
            if !presented {
                cancelAutoHide()
            }
        }
        .onReceive(timer) { input in
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
    }

    // MARK: - 1. Header Clock & Date Widget
    private var headerClockWidget: some View {
        HStack(alignment: .center) {
            // Left: Digital Clock & Date
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(timeString(from: currentTime))
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text(periodString(from: currentTime))
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.cyan)
                }

                Text(dateString(from: currentTime))
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundColor(.white.opacity(0.70))
            }

            Spacer()

            // Center: Telemetry Pills
            HStack(spacing: 8) {
                // Battery
                HStack(spacing: 5) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.green)
                    Text("Ready")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color.white.opacity(0.10)))

                // Sandbox & Confinement Indicator (Restricted by default)
                HStack(spacing: 5) {
                    Image(systemName: agentSandboxEnabled ? "shield.lefthalf.filled" : "lock.shield.fill")
                        .font(.system(size: 10))
                        .foregroundColor(agentSandboxEnabled ? .cyan : .green)
                    Text(agentSandboxEnabled ? "Restricted 🛡️" : "Custom Confinement 🔒")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color.white.opacity(0.10)))
            }

            Spacer()

            // Right: Quick Actions (Zen, Dock/Unlock, Close)
            HStack(spacing: 8) {
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
                        Text(isZenModeEnabled ? "Compact Dock" : "Fullscreen Dashboard")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(isZenModeEnabled ? .cyan : .white.opacity(0.90))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(isZenModeEnabled ? Color.cyan.opacity(0.25) : Color.white.opacity(0.12)))
                    .overlay(Capsule().stroke(isZenModeEnabled ? Color.cyan.opacity(0.50) : Color.white.opacity(0.18), lineWidth: 0.8))
                }
                .buttonStyle(.plain)
                .help(isZenModeEnabled ? "Switch to compact slide-down top dock" : "Expand to beautiful fullscreen unified dashboard")

                // Dock / Unlock Toggle
                //
                // Pinning is a snap-to-top, not a lock: the dock springs back to
                // the top edge and then hands control straight back, so it stays
                // draggable from wherever it lands.
                Button(action: {
                    HapticFeedback.selection()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                        isUnlockedFromTopDock = false
                        dragOffset = .zero
                        accumulatedOffset = .zero
                    }
                    // One beat after the snap starts, re-enable dragging. The
                    // spring keeps running — only the gate on DragGesture moves.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                        isUnlockedFromTopDock = true
                    }
                }) {
                    // The dock is always draggable now, so this reads as the
                    // action it performs rather than a lock state that no
                    // longer has an "off" position.
                    HStack(spacing: 4) {
                        Image(systemName: isMovedFromTop ? "pin.fill" : "pin")
                            .font(.system(size: 11))
                        Text("Pin to Top")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(isMovedFromTop ? .cyan : .white.opacity(0.80))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(isMovedFromTop ? Color.cyan.opacity(0.22) : Color.white.opacity(0.10)))
                    .overlay(Capsule().stroke(isMovedFromTop ? Color.cyan.opacity(0.45) : Color.white.opacity(0.12), lineWidth: 0.8))
                }
                .buttonStyle(.plain)
                .help(isMovedFromTop ? "Snap the dashboard back to the top edge. It stays draggable." : "Already at the top edge. Drag it anywhere.")

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
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(count: 2) {
            if isUnlockedFromTopDock {
                HapticFeedback.tick()
                withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                    dragOffset = .zero
                    accumulatedOffset = .zero
                }
            }
        }
    }

    // MARK: - 2. Tab Switcher
    private var tabSwitcher: some View {
        HStack(spacing: 6) {
            tabButton(title: "Quick Chat", icon: "bubble.left.and.bubble.right.fill", index: 0)
            tabButton(title: "Mini Settings", icon: "gearshape.fill", index: 1)
            tabButton(title: "System Status", icon: "chart.bar.xaxis", index: 2)
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

    // MARK: - 3. Quick Chat Pane
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

                                Text("Genie Slide-Down Intelligence")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)

                                Text("Ask questions, execute workflows, manage systems, or inspect status.")
                                    .font(.system(size: 11, weight: .regular))
                                    .foregroundColor(.white.opacity(0.60))
                                    .multilineTextAlignment(.center)

                                // Quick suggestion chips
                                HStack(spacing: 8) {
                                    suggestionChip("Summarize Desktop") { promptText = "Summarize the active desktop windows and status." }
                                    suggestionChip("Open Workspace") { promptText = "Open Genie Workspace in ~/Desktop/Genie/Workspace" }
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

                Button("Open Full Chat ↗") {
                    withAnimation {
                        isPresented = false
                    }
                    FinderChatWindowManager.shared.show(tab: .chat)
                }
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.cyan)
                .buttonStyle(.plain)
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
                .frame(width: 260)

            // 2. Center Column: Big Expansive Chat Canvas
            zenMainChatCanvasView
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // 3. Right Column: System Telemetry & Studio Intelligence Hub
            zenInspectorHubView
                .frame(width: 270)
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
                                ZStack {
                                    Circle()
                                        .fill(
                                            RadialGradient(
                                                colors: [Color.cyan.opacity(0.25), Color.purple.opacity(0.12), Color.clear],
                                                center: .center,
                                                startRadius: 4,
                                                endRadius: 36
                                            )
                                        )
                                        .frame(width: 72, height: 72)

                                    Image(systemName: "sparkles")
                                        .font(.system(size: 32, weight: .medium))
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.cyan, .mint, .white],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                }
                                .padding(.top, 24)

                                Text("Genie Fullscreen Workspace")
                                    .font(.system(size: 18, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)

                                Text("Autonomous Mac Orchestration, Coding Studio, & Neural Intelligence.")
                                    .font(.system(size: 12, weight: .regular))
                                    .foregroundColor(.white.opacity(0.65))
                                    .multilineTextAlignment(.center)

                                // Quick suggestion chips grid
                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                                    suggestionChip("🖥️ Summarize Desktop Windows") { promptText = "Summarize the active desktop windows, running processes, and open tabs." }
                                    suggestionChip("📁 Inspect Workspace Project") { promptText = "Inspect files and repositories in ~/Desktop/Genie/Workspace" }
                                    suggestionChip("⚡ Report System Vitals") { promptText = "Report real-time Apple Silicon memory pressure and system health." }
                                    suggestionChip("🛠️ Develop Swift Script") { promptText = "Create a modern Swift utility to automate system actions." }
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 6)
                            }
                            .frame(maxWidth: 680)
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

    // MARK: - 3. Right Column: Studio Hub & Telemetry
    private var zenInspectorHubView: some View {
        VStack(spacing: 10) {
            // Header
            HStack {
                Label("Studio Hub", systemImage: "slider.horizontal.3")
                    .font(.system(size: 12.5, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Button("Open Window ↗") {
                    withAnimation {
                        isPresented = false
                    }
                    FinderChatWindowManager.shared.show(tab: .chat)
                }
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.cyan)
                .buttonStyle(.plain)
                .help("Open chat in floating window")
            }
            .padding(.horizontal, 4)
            .padding(.top, 2)

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
