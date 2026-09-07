import AppKit
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
    @Binding var isRightChatDockOpen: Bool
    @Binding var isRightAppsDockOpen: Bool
    public var edge: DockEdge = .trailing

    @State private var inputText: String = ""
    @State private var selectedVoiceDialect: GenieVoiceDialect = .usSamantha
    @State private var copiedMessageId: UUID? = nil
    @State private var dragDismissOffset: CGFloat = 0
    @State private var attachedFileName: String? = nil
    @State private var showVoicePicker: Bool = false
    @State private var isShowingSettings: Bool = false

    public init(
        isRightChatDockOpen: Binding<Bool>,
        isRightAppsDockOpen: Binding<Bool> = .constant(false),
        edge: DockEdge = .trailing
    ) {
        self._isRightChatDockOpen = isRightChatDockOpen
        self._isRightAppsDockOpen = isRightAppsDockOpen
        self.edge = edge
    }

    public var body: some View {
        VStack(spacing: 0) {
            topDragHandle
            headerView
            if isShowingSettings {
                UnifiedSettingsView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                nativeDesktopSpacePlayerView
                chatStreamView
                Divider().opacity(0.15)
                inputBarView
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusOpenSettingsInChat"))) { _ in
            withAnimation(.spring(response: 0.36, dampingFraction: 0.70)) {
                isShowingSettings = true
                isRightChatDockOpen = true
            }
        }
        .frame(width: 460)
        .background(
            ZStack {
                VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow, state: .active)
                Color.black.opacity(0.40)
            }
        )
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: edge != .leading ? 18 : 0,
                bottomLeadingRadius: edge != .leading ? 18 : 0,
                bottomTrailingRadius: edge != .trailing ? 18 : 0,
                topTrailingRadius: edge != .trailing ? 18 : 0,
                style: .continuous
            )
        )
        .overlay(
            UnevenRoundedRectangle(
                topLeadingRadius: edge != .leading ? 18 : 0,
                bottomLeadingRadius: edge != .leading ? 18 : 0,
                bottomTrailingRadius: edge != .trailing ? 18 : 0,
                topTrailingRadius: edge != .trailing ? 18 : 0,
                style: .continuous
            )
            .strokeBorder(
                LinearGradient(
                    colors: [Color.cyan.opacity(0.45), Color.purple.opacity(0.25), Color.white.opacity(0.08)],
                    startPoint: edge == .trailing ? .topLeading : .topTrailing,
                    endPoint: edge == .trailing ? .bottomTrailing : .bottomLeading
                ),
                lineWidth: 0.75
            )
        )
        .shadow(color: Color.black.opacity(edge == .floating ? 0 : 0.40), radius: 24, x: edge == .trailing ? -8 : (edge == .leading ? 8 : 0), y: 0)
        .offset(x: dragDismissOffset)
        .gesture(
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
        )
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
                    if localModels.localModelsEnabled && !localModels.availableModels.isEmpty {
                        Section("Ollama / LM Studio") {
                            ForEach(localModels.availableModels) { model in
                                Button(action: {
                                    localModels.selectModel(model.name)
                                    HapticFeedback.selection()
                                }) {
                                    HStack {
                                        Text(model.displayName)
                                        if localModels.effectiveModel == model.name {
                                            Image(systemName: "checkmark")
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
                    .background(Capsule().fill(Color.cyan.opacity(0.15)))
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
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                    .padding(5)
                    .background(Circle().fill(Color.white.opacity(0.08)))
            }
            .buttonStyle(.plain)
            .help("New Conversation")

            // Settings Button (Loads Settings right in Chat Window)
            Button(action: {
                HapticFeedback.selection()
                withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                    isShowingSettings.toggle()
                }
            }) {
                Image(systemName: isShowingSettings ? "bubble.left.and.bubble.right.fill" : "gearshape")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(isShowingSettings ? .accentColor : .white.opacity(0.85))
                    .padding(5)
                    .background(Circle().fill(isShowingSettings ? Color.accentColor.opacity(0.25) : Color.white.opacity(0.08)))
            }
            .buttonStyle(.plain)
            .help(isShowingSettings ? "Return to Chat" : "Settings")

            // Retract Button
            Button(action: {
                HapticFeedback.tick()
                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                    isRightChatDockOpen = false
                }
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(5)
                    .background(Circle().fill(Color.white.opacity(0.08)))
            }
            .buttonStyle(.plain)
            .help("Close")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.20))
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

    // ── NATIVE EMBEDDED DESKTOP SPACE PLAYER (SkyLight Hardware Engine) ──
    private var nativeDesktopSpacePlayerView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "square.3.layers.3d.down.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.cyan)
                Text("NATIVE DESKTOP SPACES PLAYER")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Button(action: {
                    HapticFeedback.selection()
                    let chromePath = "/Applications/Google Chrome.app"
                    if FileManager.default.fileExists(atPath: chromePath) {
                        NSWorkspace.shared.open(URL(fileURLWithPath: chromePath))
                    } else if let url = URL(string: "https://google.com") {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "globe")
                            .font(.system(size: 9.5, weight: .bold))
                        Text("Open Native Chrome")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3.5)
                    .background(Capsule().fill(Color.cyan.opacity(0.35)))
                    .overlay(Capsule().stroke(Color.cyan.opacity(0.60), lineWidth: 0.6))
                }
                .buttonStyle(.plain)
                .help("Launch & Focus Native Chrome in Desktop Space 🌐")
            }

            // Native Desktop Spaces Hardware Player Tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(1...max(3, desktopsManager.spaces.count), id: \.self) { idx in
                        let isCurrent = (desktopsManager.currentSpaceIndex == idx)
                        Button(action: {
                            HapticFeedback.selection()
                            MacDesktopsManager.shared.switchToDesktop(index: idx)
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: isCurrent ? "desktopcomputer" : "square.on.square")
                                    .font(.system(size: 9))
                                Text("Space \(idx)")
                                    .font(.system(size: 9.5, weight: isCurrent ? .bold : .medium, design: .rounded))
                            }
                            .foregroundColor(isCurrent ? .white : .white.opacity(0.70))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(isCurrent ? Color.cyan.opacity(0.40) : Color.white.opacity(0.08))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .stroke(isCurrent ? Color.cyan.opacity(0.75) : Color.clear, lineWidth: 0.7)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.black.opacity(0.35))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.10), lineWidth: 0.7)
                )
        )
        .padding(.horizontal, 10)
        .padding(.top, 4)
    }

    // ── VERTICAL CHAT STREAM ──
    private var chatStreamView: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(spacing: 12) {
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
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
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

            HStack(spacing: 8) {
                Button(action: {
                    selectAttachmentFile()
                }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 15))
                        .foregroundColor(.cyan.opacity(0.90))
                }
                .buttonStyle(.plain)
                .help("Attach Photo, Document, or File")

                TextField("Message Genie...", text: $inputText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 12, weight: .regular, design: .rounded))
                    .foregroundColor(.white)
                    .onSubmit {
                        submitChat()
                    }

                Button(action: {
                    toggleSpeechPlayback()
                }) {
                    Image(systemName: voiceEngine.isSpeaking ? "waveform.badge.magnifyingglass" : "mic.fill")
                        .font(.system(size: 12))
                        .foregroundColor(voiceEngine.isSpeaking ? Color.cyan : Color.white.opacity(0.70))
                        .padding(4)
                        .background(Circle().fill(Color.white.opacity(0.08)))
                }
                .buttonStyle(.plain)
                .help("Listen to response or Speak")

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
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 17))
                            .foregroundColor(canSubmitChat ? Color.cyan : Color.white.opacity(0.35))
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSubmitChat)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.75)
            )
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.35))
    }

    // ── STREAMING ASSISTANT BUBBLE (JUST LIKE OUR CHAT!) ──
    @ViewBuilder
    private var streamingBubbleView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                Circle()
                    .fill(Color.cyan)
                    .frame(width: 7, height: 7)
                    .padding(.top, 4)

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
                            Text("Genie is reasoning...")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.65))
                            GenieStreamingCursorView()
                        }
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.cyan.opacity(0.35), lineWidth: 0.75)
            )
        }
    }

    // ── CHAT BUBBLE VIEW ──
    @ViewBuilder
    private func chatBubble(msg: ChatMessage) -> some View {
        if msg.role == "user" {
            HStack {
                Spacer(minLength: 40)
                Text(verbatim: msg.content)
                    .font(.system(size: 12, weight: .regular, design: .default))
                    .foregroundColor(.white)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 8)
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
                    Circle()
                        .fill(Color.purple.opacity(0.90))
                        .frame(width: 6, height: 6)
                        .padding(.top, 4)

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
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.10), lineWidth: 0.5)
                )

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
                        .background(Capsule().fill(Color.white.opacity(0.06)))
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
                        .background(Capsule().fill(Color.cyan.opacity(0.12)))
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
                .padding(.leading, 12)
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
            SpatialPlaneManager.shared.toggleZoomOutPlane()
        case "/code":
            inputText = "Write Swift code for: "
        case "/clear":
            localModels.startNewChat()
        default:
            inputText = cmd + " "
        }
    }
}
