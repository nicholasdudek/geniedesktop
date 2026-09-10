import AppKit
import CoreImage.CIFilterBuiltins
import Foundation
import SwiftUI

public enum DockEdge: Sendable {
    case leading
    case trailing
    case floating   // hosted in its own draggable window: all corners rounded, no swipe-to-dismiss
}

// MARK: - 💬 Sliding Chat Dock (Leading or Trailing Edge)
public struct RightSideChatDockView: View {
    @ObservedObject var localModels = LocalModelManager.shared
    @ObservedObject var voiceEngine = GenieVoiceEngine.shared
    @ObservedObject var desktopsManager = MacDesktopsManager.shared
    @ObservedObject var phoneBridge = GeniePhoneBridgeManager.shared
    @ObservedObject var clockVM = WorldClockViewModel.shared
    @Binding var isRightChatDockOpen: Bool
    @Binding var isRightAppsDockOpen: Bool
    public var edge: DockEdge = .trailing
    /// True when hosted inside another panel's own glass shell (e.g. the right-sidebar
    /// unified dock's Chat tab): skips this view's outer background/shape/shadow/drag-to-dismiss
    /// and the top drag handle, since the parent already draws those.
    public var embedded: Bool = false

    @State private var inputText: String = ""
    @State private var selectedVoiceDialect: GenieVoiceDialect = .usSamantha
    @State private var copiedMessageId: UUID? = nil
    @State private var dragDismissOffset: CGFloat = 0
    @State private var attachedFileName: String? = nil
    @State private var showVoicePicker: Bool = false
    @State private var isShowingSettings: Bool = false
    @State private var showRemoteQR: Bool = false
    @State private var showAgentWorkspace: Bool = false
    @State private var settingsInitialTab: UnifiedSettingsTab = .miniDock
    @AppStorage(PrefKey.isChatLockedInPlace) private var isChatLockedInPlace: Bool = false

    public init(
        isRightChatDockOpen: Binding<Bool>,
        isRightAppsDockOpen: Binding<Bool> = .constant(false),
        edge: DockEdge = .trailing,
        embedded: Bool = false
    ) {
        self._isRightChatDockOpen = isRightChatDockOpen
        self._isRightAppsDockOpen = isRightAppsDockOpen
        self.edge = edge
        self.embedded = embedded
    }

    /// Standalone (non-embedded) panel width. Kept narrow so the dock reads as a compact
    /// sidebar utility rather than a full pane.
    public static let standaloneWidth: CGFloat = 380

    public var body: some View {
        Group {
            if embedded {
                contentStack
            } else {
                contentStack
                    .frame(width: Self.standaloneWidth)
                    .background(panelBackground)
                    .clipShape(panelShape)
                    .overlay(panelShape.strokeBorder(panelBorderGradient, lineWidth: 0.75))
                    .shadow(color: Color.black.opacity(edge == .floating ? 0 : 0.40), radius: 24, x: edge == .trailing ? -8 : (edge == .leading ? 8 : 0), y: 0)
                    .offset(x: dragDismissOffset)
                    .gesture(dismissGesture)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusOpenSettingsInChat"))) { _ in
            withAnimation(.spring(response: 0.36, dampingFraction: 0.70)) {
                isShowingSettings = true
                isRightChatDockOpen = true
            }
        }
    }

    private var contentStack: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                if !embedded { topDragHandle }
                headerView
                watchStrip
                Picker("Workspace", selection: $showAgentWorkspace) {
                    Text("Chat").tag(false)
                    Text("Agent 3.0").tag(true)
                }.pickerStyle(.segmented).padding(.horizontal, 10)
                    .onChange(of: showAgentWorkspace) { _, _ in isShowingSettings = false }
                if isShowingSettings {
                    UnifiedSettingsView(initialTab: settingsInitialTab)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if showAgentWorkspace {
                    GenieAgentWorkspaceView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    chatStreamView
                    Divider().opacity(0.15)
                    inputBarView
                }
            }

            if showRemoteQR {
                remoteQRSlideUpView
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(1)
            }

            ChatInlinePreviewTrayView()
                .padding(.bottom, 80)
                .zIndex(2)
        }
    }

    private var panelBackground: some View {
        ZStack {
            VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow, state: .active)
            Color.black.opacity(0.40)
        }
    }

    private var panelShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: edge != .leading ? 16 : 0,
            bottomLeadingRadius: edge != .leading ? 16 : 0,
            bottomTrailingRadius: edge != .trailing ? 16 : 0,
            topTrailingRadius: edge != .trailing ? 16 : 0,
            style: .continuous
        )
    }

    private var panelBorderGradient: LinearGradient {
        LinearGradient(
            colors: [Color.cyan.opacity(0.45), Color.purple.opacity(0.25), Color.white.opacity(0.08)],
            startPoint: edge == .trailing ? .topLeading : .topTrailing,
            endPoint: edge == .trailing ? .bottomTrailing : .bottomLeading
        )
    }

    private var dismissGesture: some Gesture {
        DragGesture(minimumDistance: 10)
            .onChanged { value in
                guard edge != .floating else { return }
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
                guard edge != .floating else { return }
                guard !isChatLockedInPlace else {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) { dragDismissOffset = 0 }
                    return
                }
                let shouldDismiss: Bool
                if edge == .trailing {
                    shouldDismiss = value.translation.width > 60 || value.predictedEndTranslation.width > 100
                } else {
                    shouldDismiss = value.translation.width < -60 || value.predictedEndTranslation.width < -100
                }
                if shouldDismiss {
                    withAnimation(.spring(response: 0.36, dampingFraction: 0.70)) {
                        isRightChatDockOpen = false
                        dragDismissOffset = 0
                    }
                } else {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                        dragDismissOffset = 0
                    }
                }
            }
    }

    // ── TOP DRAG HANDLE ──
    private var topDragHandle: some View {
        HStack {
            Capsule()
                .fill(Color.white.opacity(0.30))
                .frame(width: 36, height: 4)
                .padding(.top, 6)
                .padding(.bottom, 4)
        }
        .frame(maxWidth: .infinity)
    }

    // ── WORLD CLOCK WATCH STRIP ──
    // Merged in from the old free-floating Mini Watch Dock panel: the watch faces now
    // ride inside this dock, under the header, so there is one dock instead of two.
    @ViewBuilder
    private var watchStrip: some View {
        if clockVM.dockSettings.isEnabled {
            MiniWatchDockView(
                pillows: clockVM.pillows,
                date: clockVM.effectiveDate,
                localTimeZone: clockVM.localTimeZone,
                settings: clockVM.dockSettings,
                onSelectPillow: openPillowInSettings
            )
            .padding(.horizontal, -6)
            .padding(.top, 2)
            .contextMenu {
                Button("Hide Watch Strip") { clockVM.dockSettings.isEnabled = false }
            }
        }
    }

    /// Tapping a watch opens that city in the World Clock tab of this same dock,
    /// rather than kicking the user out to a separate settings window.
    private func openPillowInSettings(_ pillow: PillowClock) {
        clockVM.editingPillow = pillow
        settingsInitialTab = .worldClock
        withAnimation(.spring(response: 0.36, dampingFraction: 0.70)) {
            isShowingSettings = true
        }
        NotificationCenter.default.post(
            name: NSNotification.Name("NexusSelectSettingsTab"),
            object: UnifiedSettingsTab.worldClock
        )
    }

    // ── PROSCENIUM HEADER ──
    private var headerView: some View {
        HStack(spacing: 8) {
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: 7, height: 7)

                Text("Genie")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)

                Menu {
                    ForEach(AIModelProvider.allCases) { provider in
                        let models = LocalModelManager.cloudModels.filter { $0.provider == provider }
                        if !models.isEmpty {
                            Section(provider.rawValue) {
                                ForEach(models) { model in
                                    Button(action: {
                                        localModels.selectModel(model.id)
                                        HapticFeedback.selection()
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
                    }
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "cpu")
                            .font(.system(size: 8))
                        Text(localModels.effectiveModel.prefix(12))
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .lineLimit(1)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 6))
                    }
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2.5)
                    .genieLiquidGlass(cornerRadius: 999, tint: .cyan)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()

                if voiceEngine.isSpeaking {
                    HStack(spacing: 2) {
                        ForEach(0..<4) { idx in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(Color.cyan)
                                .frame(width: 2, height: CGFloat(4 + (idx % 3) * 5))
                        }
                    }
                }
            }

            Spacer()

            // New Chat Button
            Button(action: {
                localModels.startNewChat()
                HapticFeedback.selection()
            }) {
                Image(systemName: "square.and.pencil")
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.plain)
            .genieLiquidGlass(cornerRadius: 999, interactive: true)
            .help("New Conversation")

            // Settings Button (Loads Settings right in Chat Window)
            Button(action: {
                HapticFeedback.selection()
                withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                    isShowingSettings.toggle()
                }
            }) {
                Image(systemName: isShowingSettings ? "bubble.left.and.bubble.right.fill" : "gearshape")
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundColor(isShowingSettings ? .accentColor : .white.opacity(0.85))
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.plain)
            .genieLiquidGlass(cornerRadius: 999, tint: isShowingSettings ? .accentColor : nil, interactive: true)
            .help(isShowingSettings ? "Return to Chat" : "Settings")

            // Pop Out / Dock Back — the merged chat detaches into its own floating
            // window from here, and docks back into the right sidebar from there.
            popTransitionButton

            // Retract Button
            Button(action: {
                HapticFeedback.selection()
                withAnimation(.spring(response: 0.24, dampingFraction: 0.82)) {
                    isChatLockedInPlace.toggle()
                }
            }) {
                Image(systemName: isChatLockedInPlace ? "lock.fill" : "lock.open")
                    .font(.system(size: 9.5, weight: .semibold))
                    .foregroundColor(isChatLockedInPlace ? .yellow : .white.opacity(0.8))
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.plain)
            .genieLiquidGlass(cornerRadius: 999, tint: isChatLockedInPlace ? .yellow : nil, interactive: true)
            .help(isChatLockedInPlace ? "Unlock Chat Dock" : "Lock Chat Dock in Place")

            Button(action: {
                guard !isChatLockedInPlace else { return }
                HapticFeedback.tick()
                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                    isRightChatDockOpen = false
                }
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 9.5, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.plain)
            .genieLiquidGlass(cornerRadius: 999, interactive: true)
            .help("Close")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.20))
    }

    /// Detach the docked sidebar chat into a floating window, or dock a floating
    /// window's chat back into the right sidebar — same chat, two presentations.
    @ViewBuilder
    private var popTransitionButton: some View {
        if edge == .trailing {
            Button(action: {
                HapticFeedback.selection()
                isRightChatDockOpen = false
                PoppedOutChatWindowManager.shared.show()
            }) {
                Image(systemName: "arrow.up.forward.app")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.plain)
            .genieLiquidGlass(cornerRadius: 999, interactive: true)
            .help("Pop Out into a Floating Window")
        } else if edge == .floating {
            Button(action: {
                HapticFeedback.selection()
                isRightChatDockOpen = true
                PoppedOutChatWindowManager.shared.hide()
            }) {
                Image(systemName: "sidebar.trailing")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                    .frame(width: 22, height: 22)
            }
            .buttonStyle(.plain)
            .genieLiquidGlass(cornerRadius: 999, interactive: true)
            .help("Dock into the Right Sidebar")
        }
    }

    // ── VOICE DIALECT EXPANDED STRIP ──
    private var voicePickerStrip: some View {
        HStack(spacing: 5) {
            ForEach(GenieVoiceDialect.allCases) { dialect in
                let isSelected = (selectedVoiceDialect == dialect)
                Button(action: {
                    selectedVoiceDialect = dialect
                    voiceEngine.setDialect(dialect)
                    voiceEngine.speak(text: "Hello, I am speaking with the \(dialect.name) voice.")
                    HapticFeedback.selection()
                }) {
                    HStack(spacing: 3) {
                        Text(dialect.flag)
                        Text(dialect.name)
                            .font(.system(size: 9.5, weight: isSelected ? .bold : .medium, design: .rounded))
                    }
                    .foregroundColor(isSelected ? .white : .white.opacity(0.70))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3.5)
                    .background(
                        Capsule().fill(isSelected ? Color.cyan.opacity(0.45) : Color.white.opacity(0.08))
                    )
                    .overlay(
                        Capsule().stroke(isSelected ? Color.cyan.opacity(0.70) : Color.clear, lineWidth: 0.7)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.20))
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // ── VERTICAL CHAT STREAM ──
    private var chatStreamView: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(spacing: 9) {
                    if localModels.chatHistory.isEmpty && !localModels.isGenerating && localModels.currentResponse.isEmpty {
                        emptyChatPlaceholder
                    } else {
                        ForEach(localModels.chatHistory) { msg in
                            chatBubble(msg: msg)
                                .id(msg.id)
                        }

                        if localModels.isGenerating || !localModels.currentResponse.isEmpty {
                            streamingBubbleView
                                .id("active_streaming_response")
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 10)
            }
            .onChange(of: localModels.chatHistory.count) {
                if let lastMsg = localModels.chatHistory.last {
                    withAnimation {
                        proxy.scrollTo(lastMsg.id, anchor: .bottom)
                    }
                }
            }
            .onChange(of: localModels.currentResponse) {
                withAnimation(.easeOut(duration: 0.15)) {
                    proxy.scrollTo("active_streaming_response", anchor: .bottom)
                }
            }
        }
    }

    private var emptyChatPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 28))
                .foregroundColor(.cyan.opacity(0.80))
                .padding(.top, 40)

            Text("Genie Right-Side Command Center")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("Ask questions, generate 16:9 slides, executive PDFs, Chart.js graphs, or write notes.")
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.white.opacity(0.65))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
        }
        .frame(maxWidth: .infinity)
    }

    // ── OMNI-BAR INPUT CAPSULE AT BOTTOM ──
    private var inputBarView: some View {
        VStack(spacing: 6) {
            GenieSlashCommandsBarView(onCommandSelected: { cmd in
                handleSlashCommand(cmd)
            })

            if let file = attachedFileName {
                HStack(spacing: 4) {
                    Image(systemName: "paperclip")
                        .font(.system(size: 9))
                        .foregroundColor(.cyan)
                    Text(verbatim: file)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                    Spacer()
                    Button(action: {
                        attachedFileName = nil
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Capsule().fill(Color.white.opacity(0.10)))
                .padding(.horizontal, 12)
            }

            VStack(spacing: 6) {
                TextField("Message Genie...", text: $inputText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(.white)
                    .onSubmit {
                        submitChat()
                    }
                    .padding(.horizontal, 4)

                HStack(spacing: 7) {
                    Button(action: {
                        selectAttachmentFile()
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 15))
                            .foregroundColor(.cyan.opacity(0.90))
                    }
                    .buttonStyle(.plain)
                    .help("Attach Photo, Document, or File")

                    Button(action: {
                        toggleSpeechPlayback()
                    }) {
                        Image(systemName: voiceEngine.isSpeaking ? "waveform.badge.magnifyingglass" : "mic.fill")
                            .font(.system(size: 11))
                            .foregroundColor(voiceEngine.isSpeaking ? Color.cyan : Color.white.opacity(0.60))
                    }
                    .buttonStyle(.plain)
                    .help("Listen to response or Speak")

                    Divider()
                        .frame(height: 14)
                        .overlay(Color.white.opacity(0.18))

                    Image(systemName: "cpu")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.purple.opacity(0.85))
                        .help("Active Model Engine")

                    Button(action: {
                        HapticFeedback.selection()
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                            showRemoteQR.toggle()
                        }
                    }) {
                        Image(systemName: "qrcode")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.white.opacity(0.75))
                    }
                    .buttonStyle(.plain)
                    .help("Pair the Genie iPhone App (Remote Control)")

                    Text(localModels.selectedModelDisplayName)
                        .font(.system(size: 9.5, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.65))
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Spacer(minLength: 4)



                    Button(action: {
                        HapticFeedback.selection()
                        localModels.autoSelectEnabled.toggle()
                    }) {
                        Text("Auto")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .foregroundColor(localModels.autoSelectEnabled ? .black : .white.opacity(0.55))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule().fill(localModels.autoSelectEnabled ? Color.cyan : Color.white.opacity(0.10))
                            )
                    }
                    .buttonStyle(.plain)
                    .help("Toggle Automatic Model Selection")

                    if localModels.isGenerating {
                        Button(action: {
                            localModels.stopGeneration()
                            HapticFeedback.heavy()
                        }) {
                            Image(systemName: "stop.circle.fill")
                                .font(.system(size: 17))
                                .foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                        .help("Stop Generation ⏹️")
                    } else {
                        Button(action: {
                            submitChat()
                        }) {
                            Image(systemName: "return")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(canSubmitChat ? Color.black : Color.white.opacity(0.35))
                                .frame(width: 20, height: 20)
                                .genieLiquidGlass(cornerRadius: 999, tint: canSubmitChat ? .cyan : nil, interactive: true)
                        }
                        .buttonStyle(.plain)
                        .disabled(!canSubmitChat)
                        .help("Send (Enter)")
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .genieLiquidGlass(cornerRadius: 16)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.35))
    }

    // ── REMOTE CONTROL QR — slides up over the input bar to pair the Genie iPhone app ──
    private var remoteQRSlideUpView: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Scan to Connect Genie iPhone App")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Button(action: {
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.78)) {
                        showRemoteQR = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }
                .buttonStyle(.plain)
            }

            Image(nsImage: remoteQRImage(from: phoneBridge.mobileRemoteURL))
                .interpolation(.none)
                .resizable()
                .frame(width: 150, height: 150)
                .padding(10)
                .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Color.white))

            Text(phoneBridge.mobileRemoteURL)
                .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.55))

            Text(phoneBridge.isServerRunning ? "Remote bridge is online" : "Starting remote bridge…")
                .font(.system(size: 9, weight: .medium, design: .rounded))
                .foregroundColor(phoneBridge.isServerRunning ? .green.opacity(0.85) : .orange.opacity(0.85))
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .genieLiquidGlass(cornerRadius: 18, tint: .cyan)
        .padding(.horizontal, 10)
        .padding(.bottom, 80)
    }

    private func remoteQRImage(from string: String) -> NSImage {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"

        guard let outputImage = filter.outputImage else { return NSImage() }
        let scaled = outputImage.transformed(by: CGAffineTransform(scaleX: 8, y: 8))
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return NSImage() }
        return NSImage(cgImage: cgImage, size: NSSize(width: scaled.extent.width, height: scaled.extent.height))
    }

    // ── GENIE AVATAR (App Icon, for Assistant Dialogue) ──
    private var genieAvatar: some View {
        Image(nsImage: NSApp.applicationIconImage ?? NSImage())
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 18, height: 18)
            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
    }

    // ── STREAMING ASSISTANT BUBBLE (JUST LIKE OUR CHAT!) ──
    @ViewBuilder
    private var streamingBubbleView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                genieAvatar

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
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .genieLiquidGlass(cornerRadius: 13, tint: .cyan)
        }
    }

    // ── CHAT BUBBLE VIEW ──
    @ViewBuilder
    private func chatBubble(msg: ChatMessage) -> some View {
        if msg.role == "user" {
            HStack {
                Spacer(minLength: 40)
                Text(verbatim: msg.content)
                    .font(.system(size: 11.5, weight: .regular, design: .default))
                    .foregroundColor(.white)
                    .padding(.horizontal, 11)
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
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top, spacing: 8) {
                    genieAvatar

                    VStack(alignment: .leading, spacing: 6) {
                        if let think = msg.thinking, !think.isEmpty {
                            GenieThinkingAccordionView(thinking: think)
                        }

                        GenieMarkdownMessageView(text: msg.content)

                        if let slides = localModels.extractPresentationSlides(from: msg.content) {
                            InlineSlidePresenterCardView(title: slides.title, content: slides.content)
                                .padding(.top, 4)
                        } else if let pdf = localModels.extractPDFContent(from: msg.content) {
                            InlinePDFCardView(title: pdf.title, content: pdf.content)
                                .padding(.top, 4)
                        } else if let chart = localModels.extractChartSpec(from: msg.content) {
                            InlineChartCardView(type: chart.type, json: chart.json, title: chart.title)
                                .padding(.top, 4)
                        } else if let mermaid = localModels.extractMermaidDiagram(from: msg.content) {
                            InlineMermaidCardView(diagram: mermaid.diagram, title: mermaid.title)
                                .padding(.top, 4)
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .genieLiquidGlass(cornerRadius: 13)

                HStack(spacing: 8) {
                    Button(action: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(msg.content, forType: .string)
                        HapticFeedback.success()
                        withAnimation {
                            copiedMessageId = msg.id
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            if copiedMessageId == msg.id {
                                copiedMessageId = nil
                            }
                        }
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: copiedMessageId == msg.id ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(copiedMessageId == msg.id ? .green : .white.opacity(0.65))
                            Text(copiedMessageId == msg.id ? "Copied!" : "Copy")
                                .font(.system(size: 9, weight: .semibold, design: .rounded))
                                .foregroundColor(copiedMessageId == msg.id ? .green : .white.opacity(0.65))
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2.5)
                        .genieLiquidGlass(cornerRadius: 999)
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        HapticFeedback.selection()
                        voiceEngine.speak(text: msg.content)
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "speaker.wave.2.fill")
                                .font(.system(size: 9))
                            Text("Speak")
                                .font(.system(size: 9, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(.cyan.opacity(0.85))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2.5)
                        .genieLiquidGlass(cornerRadius: 999, tint: .cyan)
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
                .padding(.leading, 10)
            }
        }
    }

    private func submitChat() {
        let content = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }

        let fullPrompt: String
        if let file = attachedFileName {
            fullPrompt = "[Attached File: \(file)]\n\n\(content)"
        } else {
            fullPrompt = content
        }

        HapticFeedback.selection()
        localModels.generate(prompt: fullPrompt)
        withAnimation {
            inputText = ""
            attachedFileName = nil
        }
    }

    private func selectAttachmentFile() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.item]
        panel.begin { response in
            if response == .OK, let url = panel.url {
                attachedFileName = url.lastPathComponent
                HapticFeedback.success()
            }
        }
    }

    private var canSubmitChat: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func toggleSpeechPlayback() {
        HapticFeedback.selection()
        if voiceEngine.isSpeaking {
            voiceEngine.stopSpeaking()
        } else {
            let lastAssistant = localModels.chatHistory.last(where: { $0.role == "assistant" })
            if let text = lastAssistant?.content {
                voiceEngine.speak(text: text)
            }
        }
    }

    private func handleSlashCommand(_ cmd: String) {
        switch cmd {
        case "/goal":
            inputText = "Goal: "
        case "/swarm":
            inputText = "Swarm our codebase looking for errors and edge cases"
            submitChat()
        case "/canvas":
            FinderChatWindowManager.shared.toggle()
        case "/code":
            inputText = "Write Swift code for: "
        case "/spaces":
            let total = max(3, desktopsManager.spaces.count)
            let next = (desktopsManager.currentSpaceIndex % total) + 1
            MacDesktopsManager.shared.switchToDesktop(index: next)
            HapticFeedback.selection()
        case "/recent":
            ChatInlinePreviewManager.shared.showCreationsGallery()
        case "/clear":
            localModels.startNewChat()
        default:
            inputText = cmd + " "
        }
    }
}

// MARK: - 🪟 Consolidated Single Chat Window Manager
// All floating chat requests are consolidated to FinderChatWindowManager.shared.
// Only 1 master chat window exists in the entire system.
@MainActor
public final class PoppedOutChatWindowManager: NSObject, NSWindowDelegate, ObservableObject {
    public static let shared = PoppedOutChatWindowManager()

    public var isVisible: Bool {
        FinderChatWindowManager.shared.isVisible
    }

    private override init() { super.init() }

    public func toggle() {
        FinderChatWindowManager.shared.toggle()
    }

    public func show() {
        FinderChatWindowManager.shared.show()
    }

    public func hide() {
        FinderChatWindowManager.shared.hide()
    }
}
