import AppKit
import SwiftUI
import ScreenCaptureKit

// MARK: - Bar Modes: Chat 💬, Search 🌐, Note 📄, Terminal 💻 & Polaroid 📸
public enum BarMode: String, CaseIterable {
    case chat = "chat"
    case search = "search"
    case apps = "apps"
    case file = "file"
    case terminal = "terminal"
    case polaroid = "polaroid"
    case screenMirror = "screenMirror"
    case vision = "vision"
    case settings = "settings"

    public var icon: String {
        switch self {
        case .chat: return "bubble.left.and.bubble.right.fill"
        case .search: return "globe"
        case .apps: return "square.grid.2x2.fill"
        case .file: return "doc.text.fill"
        case .terminal: return "terminal.fill"
        case .polaroid: return "camera.fill"
        case .screenMirror: return "iphone.gen3"
        case .vision: return "viewfinder.circle.fill"
        case .settings: return "slider.horizontal.3"
        }
    }

    public var iconColor: Color {
        switch self {
        case .chat: return Color(red: 0.0, green: 0.88, blue: 1.0)
        case .search: return Color(red: 0.15, green: 0.75, blue: 1.0)
        case .apps: return Color(red: 1.0, green: 0.60, blue: 0.20)
        case .file: return Color(red: 0.40, green: 0.90, blue: 0.65)
        case .terminal: return Color(red: 0.35, green: 0.90, blue: 0.45)
        case .polaroid: return Color(red: 1.0, green: 0.65, blue: 0.30)
        case .screenMirror: return Color(red: 0.20, green: 0.75, blue: 1.0)
        case .vision: return Color(red: 0.72, green: 0.45, blue: 1.0)
        case .settings: return Color(red: 0.95, green: 0.75, blue: 0.20)
        }
    }

    public var placeholder: String {
        switch self {
        case .chat: return "Converse with Executive Intelligence..."
        case .search: return "Query Global Knowledge & Web Index..."
        case .apps: return "Filter or launch installed applications..."
        case .file: return "Inscribe executive memorandum or draught..."
        case .terminal: return "Dispatch system shell directive (zsh)..."
        case .polaroid: return "Annotate visual capture & commit to Chrono-Record..."
        case .screenMirror: return "Query device telemetry or orchestrate Continuity Mirror..."
        case .vision: return "Extract screen text (OCR), or query visual AI..."
        case .settings: return "Search Genie preferences, intelligence, or appearance..."
        }
    }

    public var helpText: String {
        switch self {
        case .chat: return "Dialogue Studio — Neural Executive Assistant"
        case .search: return "Global Knowledge & Web Index Ingress"
        case .apps: return "Applications Viewer Box — Quick Launch 🪟"
        case .file: return "Executive Memorandum Portfolio"
        case .terminal: return "Precision System Directive Console"
        case .polaroid: return "High-Fidelity Optical Screen Record"
        case .screenMirror: return "Continuity Mirror — Device Synchronicity"
        case .vision: return "Optical Screen Vision & Neural OCR Engine"
        case .settings: return "Genie Consolidated Settings & Studio Inspector ⚙️"
        }
    }

    public var title: String {
        switch self {
        case .chat: return "Dialogue"
        case .search: return "Omni-Search"
        case .apps: return "Applications"
        case .file: return "Memorandum"
        case .terminal: return "Console"
        case .polaroid: return "Chrono-Capture"
        case .screenMirror: return "Continuity"
        case .vision: return "Vision OCR"
        case .settings: return "Settings"
        }
    }

    public func next() -> BarMode {
        switch self {
        case .chat: return .search
        case .search: return .apps
        case .apps: return .file
        case .file: return .terminal
        case .terminal: return .polaroid
        case .polaroid: return .screenMirror
        case .screenMirror: return .vision
        case .vision: return .settings
        case .settings: return .chat
        }
    }
}

// MARK: - Native Search & Note Text Field (Guaranteed Blinking Cursor & Key Handling)

final class FocusableSearchNSTextField: NSTextField {
    var onSubmit: (() -> Void)?
    var onEscape: (() -> Void)?
    var onFocusChanged: ((Bool) -> Void)?

    static func roundedFont(size: CGFloat, weight: NSFont.Weight = .regular) -> NSFont {
        let base = NSFont.systemFont(ofSize: size, weight: weight)
        if let desc = base.fontDescriptor.withDesign(.rounded) {
            return NSFont(descriptor: desc, size: size) ?? base
        }
        return base
    }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard let win = window else { return }
        NotificationCenter.default.removeObserver(self, name: NSWindow.didBecomeKeyNotification, object: nil)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(windowDidBecomeKey),
            name: NSWindow.didBecomeKeyNotification,
            object: win
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) { [weak self] in
            self?.forceBlinkingCursorFocus()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) { [weak self] in
            self?.forceBlinkingCursorFocus()
        }
    }

    @objc private func windowDidBecomeKey() {
        forceBlinkingCursorFocus()
    }

    func forceBlinkingCursorFocus() {
        guard let win = self.window else { return }
        NSApp.activate(ignoringOtherApps: true)
        win.makeKey()
        win.makeFirstResponder(self)
        if let editor = win.fieldEditor(true, for: self) as? NSTextView {
            editor.insertionPointColor = .white
            let len = self.stringValue.utf16.count
            editor.setSelectedRange(NSRange(location: len, length: 0))
        }
        onFocusChanged?(true)
        NotificationCenter.default.post(name: NSNotification.Name("NexusSearchBarFocusChanged"), object: true)
    }

    override func becomeFirstResponder() -> Bool {
        let result = super.becomeFirstResponder()
        if result {
            if let win = self.window, let editor = win.fieldEditor(true, for: self) as? NSTextView {
                editor.insertionPointColor = .white
            }
            onFocusChanged?(true)
            NotificationCenter.default.post(name: NSNotification.Name("NexusSearchBarFocusChanged"), object: true)
        }
        return result
    }

    override func resignFirstResponder() -> Bool {
        let result = super.resignFirstResponder()
        if result {
            onFocusChanged?(false)
            NotificationCenter.default.post(name: NSNotification.Name("NexusSearchBarFocusChanged"), object: false)
        }
        return result
    }

    override func textDidChange(_ notification: Notification) {
        super.textDidChange(notification)
        if let editor = self.window?.fieldEditor(false, for: self) as? NSTextView {
            editor.insertionPointColor = .white
        }
    }
}

struct NativeSearchTextField: NSViewRepresentable {
    @Binding var text: String
    var placeholder: String
    var onSubmit: () -> Void
    var onCommandSubmit: (() -> Void)? = nil
    var onEscape: () -> Void
    var onFocusChanged: (Bool) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> FocusableSearchNSTextField {
        let tf = FocusableSearchNSTextField()
        tf.isBordered = false
        tf.drawsBackground = false
        tf.backgroundColor = .clear
        tf.textColor = .white
        tf.font = FocusableSearchNSTextField.roundedFont(size: 16.5, weight: .regular)
        tf.focusRingType = .none
        tf.isBezeled = false
        tf.delegate = context.coordinator
        tf.lineBreakMode = .byTruncatingTail
        tf.maximumNumberOfLines = 1
        tf.cell?.wraps = false
        tf.cell?.isScrollable = true

        let attrString = NSAttributedString(
            string: placeholder,
            attributes: [
                .foregroundColor: NSColor.white.withAlphaComponent(0.40),
                .font: FocusableSearchNSTextField.roundedFont(size: 16.5, weight: .medium)
            ]
        )
        tf.placeholderAttributedString = attrString
        context.coordinator.textField = tf

        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.handleFocusNotification),
            name: NSNotification.Name("NexusFocusGenieSearchBar"),
            object: nil
        )

        NotificationCenter.default.addObserver(
            context.coordinator,
            selector: #selector(Coordinator.handleAppendNotification(_:)),
            name: NSNotification.Name("NexusSearchBarAppendText"),
            object: nil
        )

        return tf
    }

    func updateNSView(_ nsView: FocusableSearchNSTextField, context: Context) {
        if nsView.stringValue != text {
            nsView.stringValue = text
            NotificationCenter.default.post(
                name: NSNotification.Name("NexusSearchBarTextDidChange"),
                object: text
            )
        }
        let attrString = NSAttributedString(
            string: placeholder,
            attributes: [
                .foregroundColor: NSColor.white.withAlphaComponent(0.40),
                .font: FocusableSearchNSTextField.roundedFont(size: 16.5, weight: .medium)
            ]
        )
        nsView.placeholderAttributedString = attrString
        nsView.onSubmit = onSubmit
        nsView.onEscape = onEscape
        nsView.onFocusChanged = onFocusChanged
    }

    class Coordinator: NSObject, NSTextFieldDelegate {
        var parent: NativeSearchTextField
        weak var textField: FocusableSearchNSTextField?

        init(_ parent: NativeSearchTextField) {
            self.parent = parent
        }

        @objc func handleFocusNotification() {
            DispatchQueue.main.async { [weak self] in
                self?.textField?.forceBlinkingCursorFocus()
            }
        }

        @objc func handleAppendNotification(_ notif: Notification) {
            guard let str = notif.object as? String, self.textField != nil else { return }
            DispatchQueue.main.async { [weak self] in
                guard let self = self, let tf = self.textField else { return }
                if tf.stringValue.isEmpty {
                    tf.stringValue = str
                } else if !tf.stringValue.hasSuffix(str) {
                    tf.stringValue += str
                }
                self.parent.text = tf.stringValue
                tf.forceBlinkingCursorFocus()
            }
        }

        func controlTextDidChange(_ obj: Notification) {
            guard let tf = obj.object as? NSTextField else { return }
            parent.text = tf.stringValue
            HapticFeedback.playTypingSound()
            NotificationCenter.default.post(
                name: NSNotification.Name("NexusSearchBarTextDidChange"),
                object: tf.stringValue
            )
        }

        func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            let currentEvent = NSApp.currentEvent
            let hasCommand = currentEvent?.modifierFlags.contains(.command) ?? false
            let hasShift = currentEvent?.modifierFlags.contains(.shift) ?? false

            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                if hasCommand {
                    HapticFeedback.heavy()
                    parent.onCommandSubmit?() ?? parent.onSubmit()
                    return true
                } else if hasShift {
                    textView.insertNewlineIgnoringFieldEditor(nil)
                    return true
                } else {
                    parent.onSubmit()
                    return true
                }
            } else if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
                parent.onEscape()
                return true
            }
            return false
        }
    }
}

// MARK: - Apple Search Bar & Note View (Pure Apple Dropdown Parity)

public struct AppleSearchBarNoteView: View {
    @AppStorage("nexus.appLanguage") var appLanguage: String = "English (US)"
    @AppStorage("nexus.notePrinterSoundEnabled") var notePrinterSoundEnabled: Bool = true
    @AppStorage("nexus.barModeRaw") var barModeRaw: String = "chat"

    @ObservedObject var localModels = LocalModelManager.shared

    @State private var noteText: String = ""
    @State private var isIconHovered: Bool = false
    @State private var isHovered: Bool = false
    @State private var isFocused: Bool = true
    @State private var isThinkingExpanded: Bool = false
    @State private var showNoteEditorPopover: Bool = false
    @State private var showTerminalPopover: Bool = false
    @State private var noteSelectedColor: String = "Yellow"
    @State private var showCheatSheet: Bool = false

    // Reverse Genie Dropping Animation
    @State private var isDroppingNote: Bool = false
    @State private var dropOffsetY: CGFloat = 0.0
    @State private var dropScale: CGFloat = 0.4
    @State private var dropOpacity: Double = 0.0
    @State private var dropRotation: Double = -8.0
    @State private var flashPulse: Bool = false
    @State private var statusFeedback: String? = nil
    @State private var showChatSettingsPopover: Bool = false
    @State private var showChatManagerDrawer: Bool = false
    @State private var showSavedChatsDrawer: Bool = false
    @State private var showPolaroidPreviewPopover: Bool = false
    @State private var polaroidPreviewImage: NSImage? = nil
    @State private var polaroidSavedURL: URL? = nil
    @ObservedObject var visionEngine = GenieVisionEngine.shared
    @State private var showVisionPreviewPopover: Bool = false
    @AppStorage("nexus.searchBarPlacement") var searchBarPlacement: String = "Meet in Middle (Top Chat, Bottom Apps) ⚖️"
    @AppStorage("nexus.middleSplitRatio") var middleSplitRatio: Double = 0.44
    @AppStorage("nexus.showEmotionPlayer") var showEmotionPlayer: Bool = false
    @AppStorage("nexus.isChatLockedInPlace") var isChatLockedInPlace: Bool = false
    @AppStorage("nexus.isChatDockedToMenuBar") var isChatDockedToMenuBar: Bool = false
    @State private var showQuickNoteDrawer: Bool = false
    @State private var quickNoteContent: String = ""

    @AppStorage("nexus.isChatDetached") var isChatDetached: Bool = false
    @AppStorage("nexus.chatOffsetX") var chatOffsetX: Double = 0.0
    @AppStorage("nexus.chatOffsetY") var chatOffsetY: Double = 0.0
    @State private var dragCurrentTranslation: CGSize = .zero
    @AppStorage("nexus.selectedNoteOutputDestination") var selectedOutputDestinationRaw: String = NoteOutputDestination.polaroidPng.rawValue
    @AppStorage("nexus.customNotesDestinationPath") var customNotesDestinationPath: String = ""

    private var selectedOutputDestination: NoteOutputDestination {
        get { NoteOutputDestination(rawValue: selectedOutputDestinationRaw) ?? .polaroidPng }
        nonmutating set { selectedOutputDestinationRaw = newValue.rawValue }
    }

    @ObservedObject var voiceEngine = GenieVoiceEngine.shared
    @ObservedObject private var dockManager = DockAndDesktopManager.shared
    @ObservedObject private var batteryMonitor = BatteryMonitor.shared
    @AppStorage("nexus.showMiniDockInChatBar") var showMiniDockInChatBar: Bool = true
    @AppStorage("nexus.chatSmartCleanMode") var chatSmartCleanMode: Bool = true
    @AppStorage("nexus.isChatFullScreen") var isChatFullScreen: Bool = false
    @State private var attachedFileURL: URL? = nil
    @State private var isDropTargeted: Bool = false
    @State private var copiedMessageId: UUID? = nil
    @State private var isBrowserRecalledToFront: Bool = false

    private var currentChatFolders: (root: URL, documents: URL, presentations: URL, images: URL, notes: URL) {
        let activeTitle = localModels.savedSessions.first(where: { $0.id == localModels.currentSessionId })?.title
        return GenieStandardDirectories.chatSessionFolderURL(
            sessionId: localModels.currentSessionId,
            title: activeTitle
        )
    }

    private var currentDestinationFolderURL: URL {
        if !customNotesDestinationPath.isEmpty {
            let u = URL(fileURLWithPath: customNotesDestinationPath)
            var isDir: ObjCBool = false
            if FileManager.default.fileExists(atPath: u.path, isDirectory: &isDir), isDir.boolValue {
                return u
            }
        }
        return currentChatFolders.notes
    }

    private func pickAttachment() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.title = "Attach Photo, Document, or File to Chat"
        openPanel.prompt = "Attach"
        NSApp.activate(ignoringOtherApps: true)
        openPanel.begin { resp in
            if resp == .OK, let url = openPanel.url {
                self.attachedFileURL = url
                showFeedback("Attached \(url.lastPathComponent) 📎")
            }
        }
    }

    private func chooseCustomDestinationFolder() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.canCreateDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.title = "Choose Destination Folder for Notes & Cards"
        openPanel.prompt = "Select Folder"
        NSApp.activate(ignoringOtherApps: true)
        openPanel.begin { resp in
            if resp == .OK, let chosenURL = openPanel.url {
                customNotesDestinationPath = chosenURL.path
                showFeedback("Destination: \(chosenURL.lastPathComponent) 📁")
            }
        }
    }

    public var customWidth: CGFloat? = nil
    public var effectiveWidth: CGFloat {
        if isChatFullScreen, let screen = NSScreen.main {
            return screen.visibleFrame.width - 60
        }
        return customWidth ?? 880.0
    }

    private var currentMode: BarMode {
        get { BarMode(rawValue: barModeRaw) ?? .chat }
        nonmutating set { barModeRaw = newValue.rawValue }
    }

    public init(customWidth: CGFloat? = nil) {
        self.customWidth = customWidth
    }

    public var body: some View {
        if isChatDockedToMenuBar {
            menuBarDockedPillView
                .padding(.top, 4)
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.85).combined(with: .opacity),
                    removal: .scale(scale: 0.85).combined(with: .opacity)
                ))
        } else {
            HStack(alignment: .top, spacing: 14) {
                VStack(spacing: 10) {
                    // ── Vertical Fading iMessage Chat Stream ("keep it all in the chat vertical...") ──
                    if currentMode == .chat && shouldShowChatStream {
                        verticalFadingChatStreamView
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else if currentMode == .search {
                        consolidatedBrowserView
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else if currentMode == .apps {
                        InlineApplicationsViewerBoxView(
                            currentMode: Binding(get: { currentMode }, set: { currentMode = $0 }),
                            isChatFullScreen: $isChatFullScreen
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else if currentMode == .terminal {
                        EmbeddedTerminalCanvasView()
                            .frame(width: 660, height: 400)
                            .background(
                                ZStack {
                                    VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow, state: .active)
                                    Color.black.opacity(0.85)
                                }
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.75)
                            )
                            .shadow(color: Color.black.opacity(0.50), radius: 24, y: 12)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    } else if currentMode == .chat && showEmotionPlayer && localModels.chatHistory.isEmpty {
                        AIEmotionPlayerWindowView()
                    } else if currentMode == .screenMirror {
                        ConsolidatediPhoneMirrorView(onClose: {
                            withAnimation { barModeRaw = BarMode.chat.rawValue }
                        }, onSendToAI: { prompt in
                            withAnimation { barModeRaw = BarMode.chat.rawValue }
                            self.noteText = prompt
                            self.handleSubmit()
                        })
                        .frame(height: 520)
                    } else if currentMode == .settings {
                        GenieSettingsLayerView(currentMode: Binding(get: { currentMode }, set: { currentMode = $0 }))
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    // ── Mini Dock & Battery Strip in Chat Bar ("wheres the mini dock i want it in the menu bar and the chat bar", "we missing the battery") ──
                    if showMiniDockInChatBar {
                        chatBarMiniDockStrip
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    // ── Live App Search & Toggle Strip (when typing app query) ──
                    if !appSearchResults.isEmpty {
                        appSearchToggleStripView
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                    }

                    // Main Apple Frosted Floating Capsule
                    HStack(spacing: 8) {
                        // ── Drag Handle & Detach Indicator ──
                        HStack(spacing: 3) {
                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(isChatDetached ? .cyan : .white.opacity(0.35))
                        }
                        .contentShape(Rectangle())
                        .gesture(chatDragGesture)
                        .help("Drag to Move Chat Window Anywhere 🪟")

                        // ── + Attachment Button (Files / Photos / Docs) ──
                        Button(action: {
                            pickAttachment()
                        }) {
                            Image(systemName: attachedFileURL != nil ? "paperclip.circle.fill" : "plus.circle.fill")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(attachedFileURL != nil ? .cyan : .white.opacity(0.65))
                        }
                        .buttonStyle(.plain)
                        .help("Attach Photo, Document, or File 📎")

                        // Attached File Chip
                        if let attached = attachedFileURL {
                            HStack(spacing: 4) {
                                Image(systemName: "doc.fill")
                                    .font(.system(size: 9.5))
                                Text(attached.lastPathComponent)
                                    .font(.system(size: 10, weight: .medium))
                                    .lineLimit(1)
                                Button(action: {
                                    attachedFileURL = nil
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.system(size: 10))
                                }
                                .buttonStyle(.plain)
                            }
                            .foregroundColor(.cyan)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.cyan.opacity(0.18)))
                            .overlay(Capsule().stroke(Color.cyan.opacity(0.35), lineWidth: 0.5))
                        }

                        // ── 4 Discrete Mode Pills: Chat 💬 | Search 🌐 | Note 📄 | Terminal 💻 (Hidden in Smart Mode) ──
                        if !chatSmartCleanMode {
                            modeCapsuleButtons
                        }

                // ── Clean Text Input Field ──
                NativeSearchTextField(
                    text: $noteText,
                    placeholder: currentMode == .chat ? "Ask \(localModels.selectedModelDisplayName)..." : LocalizedStrings.translateText(currentMode.placeholder, lang: appLanguage),
                    onSubmit: {
                        handleSubmit()
                    },
                    onCommandSubmit: {
                        handleCommandSubmit()
                    },
                    onEscape: {
                        handleEscape()
                    },
                    onFocusChanged: { focused in
                        isFocused = focused
                    }
                )
                .frame(height: 32)

                // ── Multi-Provider AI Model Selector Pill (Local + Gemini + Claude + OpenAI) ──
                if currentMode == .chat {
                    Menu {
                        Toggle(isOn: Binding(
                            get: { localModels.autoSelectEnabled },
                            set: { if $0 { localModels.enableAutoSelect() } else { localModels.autoSelectEnabled = false } }
                        )) {
                            Text("Auto-Select Available Local Models")
                        }

                        Divider()

                        // Google Gemini Section
                        Menu("⚡️ Google Gemini (BYOK)") {
                            ForEach(LocalModelManager.cloudModels.filter { $0.provider == .gemini }) { model in
                                Button(action: {
                                    localModels.selectModel(model.id)
                                }) {
                                    HStack {
                                        Text(model.displayName)
                                        if !localModels.hasGeminiKey {
                                            Text("(Key needed)")
                                        }
                                        if localModels.effectiveModel == model.id {
                                            Text("✓")
                                        }
                                    }
                                }
                            }
                        }

                        // Anthropic Claude Section
                        Menu("🧠 Anthropic Claude (BYOK)") {
                            ForEach(LocalModelManager.cloudModels.filter { $0.provider == .claude }) { model in
                                Button(action: {
                                    localModels.selectModel(model.id)
                                }) {
                                    HStack {
                                        Text(model.displayName)
                                        if !localModels.hasClaudeKey {
                                            Text("(Key needed)")
                                        }
                                        if localModels.effectiveModel == model.id {
                                            Text("✓")
                                        }
                                    }
                                }
                            }
                        }

                        // OpenAI Section
                        Menu("❇️ OpenAI (BYOK)") {
                            ForEach(LocalModelManager.cloudModels.filter { $0.provider == .openai }) { model in
                                Button(action: {
                                    localModels.selectModel(model.id)
                                }) {
                                    HStack {
                                        Text(model.displayName)
                                        if !localModels.hasOpenAIKey {
                                            Text("(Key needed)")
                                        }
                                        if localModels.effectiveModel == model.id {
                                            Text("✓")
                                        }
                                    }
                                }
                            }
                        }

                        // Local Models Section
                        Menu(localModels.localModelsEnabled ? "💻 Local Models (Ollama / LM Studio)" : "💻 Local Models (Shut Off ⏻)") {
                            if !localModels.localModelsEnabled {
                                Text("Local models are shut off ⏻")
                                Button("Turn On Local Models ⚡️") {
                                    localModels.enableLocalModels()
                                    HapticFeedback.selection()
                                    showFeedback("Local Models Enabled ⚡️")
                                }
                            } else if localModels.availableModels.isEmpty {
                                Text("No local models found on localhost")
                                Button("Scan & Refresh Local Models 🔄") {
                                    localModels.refreshAvailableModels()
                                }
                            } else {
                                ForEach(localModels.availableModels) { model in
                                    Button(action: {
                                        localModels.selectModel(model.name)
                                    }) {
                                        HStack {
                                            Text(model.displayName)
                                            if !model.displaySize.isEmpty {
                                                Text("(\(model.displaySize))")
                                            }
                                            if localModels.effectiveModel == model.name {
                                                Text("✓")
                                            }
                                        }
                                    }
                                }

                                Divider()

                                Button("⏻ Shut Off Local Models") {
                                    localModels.shutoffLocalModels()
                                    HapticFeedback.heavy()
                                    showFeedback("Local Models Shut Off ⏻")
                                }

                                Button("🧹 Eject Models from RAM (keep_alive: 0)") {
                                    localModels.unloadAllLocalModels()
                                    HapticFeedback.selection()
                                    showFeedback("Models Ejected from RAM 🧹")
                                }
                            }
                        }

                        // Terminal & Developer Tools Menu
                        Menu("💻 Terminal & Developer Tools") {
                            Toggle("Terminal Tool Access", isOn: Binding(
                                get: { localModels.terminalAccessEnabled },
                                set: { localModels.terminalAccessEnabled = $0 }
                            ))

                            Toggle("Auto-Execute Terminal Commands", isOn: Binding(
                                get: { localModels.terminalAutoExecute },
                                set: { localModels.terminalAutoExecute = $0 }
                            ))
                        }

                        Divider()

                        if localModels.localModelsEnabled {
                            Button("⏻ Shut Off Local Models") {
                                localModels.shutoffLocalModels()
                                HapticFeedback.heavy()
                                showFeedback("Local Models Shut Off ⏻")
                            }
                        } else {
                            Button("⚡️ Turn On Local Models (Currently Shut Off ⏻)") {
                                localModels.enableLocalModels()
                                HapticFeedback.selection()
                                showFeedback("Local Models Enabled ⚡️")
                            }
                        }

                        Button("Chat Settings & API Keys... 🔑") {
                            showChatSettingsPopover = true
                        }

                        Button("Configure API Keys in Settings... ⚙️") {
                            AppDelegate.shared?.showMenuBarSettingsDropdown(targetTab: .system)
                        }

                        Button("Scan & Refresh Local Models 🔄") {
                            localModels.refreshAvailableModels()
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: localModels.activeProvider.icon)
                                .font(.system(size: 9.5, weight: .bold))
                                .foregroundColor(localModels.activeProvider.badgeColor)
                            Text(localModels.autoSelectEnabled ? "Auto: \(localModels.selectedModelDisplayName)" : localModels.selectedModelDisplayName)
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(.white.opacity(0.92))
                                .lineLimit(1)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 7.5, weight: .bold))
                                .foregroundColor(.white.opacity(0.55))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.white.opacity(0.12)))
                        .overlay(Capsule().stroke(localModels.activeProvider.badgeColor.opacity(0.40), lineWidth: 0.75))
                    }
                    .menuStyle(.borderlessButton)
                    .fixedSize()

                    // Quick Settings / API Key Button right on chat bar
                    Button(action: {
                        showChatSettingsPopover.toggle()
                        HapticFeedback.selection()
                    }) {
                        Image(systemName: "key.fill")
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundColor(localModels.hasGeminiKey ? .green : .cyan)
                            .frame(width: 22, height: 22)
                            .background(Circle().fill(Color.white.opacity(0.12)))
                    }
                    .buttonStyle(.plain)
                    .help("Input API Keys & Chat Settings")
                    .popover(isPresented: $showChatSettingsPopover, arrowEdge: .bottom) {
                        chatSettingsPopoverContent
                    }
                }

                // ── Clear Button ──
                if !noteText.isEmpty {
                    Button(action: {
                        HapticFeedback.tick()
                        withAnimation(.easeOut(duration: 0.15)) {
                            noteText = ""
                        }
                        NotificationCenter.default.post(name: NSNotification.Name("NexusFocusGenieSearchBar"), object: nil)
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 15))
                            .foregroundColor(Color.white.opacity(0.45))
                    }
                    .buttonStyle(.plain)
                    .transition(.opacity)
                }

                // ── Apple-style Return Key Badge ──
                Button(action: {
                    handleSubmit()
                }) {
                    HStack(spacing: 3.5) {
                        Text("return")
                            .font(.system(size: 10.5, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(noteText.isEmpty ? 0.40 : 0.85))
                        Image(systemName: "return")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white.opacity(noteText.isEmpty ? 0.50 : 0.95))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.white.opacity(noteText.isEmpty ? 0.08 : 0.18))
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.white.opacity(noteText.isEmpty ? 0.12 : 0.32), lineWidth: 0.5)
                    )
                }
                .buttonStyle(.plain)

                // ── Right Side Control Group: Note 📄 | Lock 📌 | Apps 📱 | Dock ⬆️ | Cheat 💡 ──
                rightSideControlsGroup
            }
            .padding(.horizontal, 14)
            .frame(height: 48)
            .background(
                ZStack {
                    VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow, state: .active)
                        .clipShape(Capsule())

                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.12, green: 0.13, blue: 0.18).opacity(0.78),
                                    Color(red: 0.06, green: 0.07, blue: 0.10).opacity(0.88)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    LinearGradient(
                        stops: [
                            .init(color: Color.white.opacity(0.32), location: 0.0),
                            .init(color: Color.white.opacity(0.10), location: 0.30),
                            .init(color: Color.clear, location: 0.80)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .clipShape(Capsule())

                    Capsule()
                        .strokeBorder(Color.white.opacity(0.06), lineWidth: 0.5)
                }
            )
            .overlay(
                Capsule()
                    .strokeBorder(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(flashPulse ? 0.95 : (isFocused ? 0.45 : 0.24)), location: 0.0),
                                .init(color: Color.white.opacity(flashPulse ? 0.85 : (isFocused ? 0.20 : 0.10)), location: 0.45),
                                .init(color: Color.white.opacity(flashPulse ? 0.70 : (isFocused ? 0.10 : 0.04)), location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        ),
                        lineWidth: flashPulse ? 1.4 : 0.75
                    )
                    .animation(.easeInOut(duration: 0.20), value: flashPulse)
                    .animation(.easeInOut(duration: 0.20), value: isFocused)
            )
            .compositingGroup()
            .frame(maxWidth: min(effectiveWidth, 880))
            .contentShape(Capsule())
            .gesture(chatDragGesture)
            .onHover { h in isHovered = h }
            .onTapGesture {
                NotificationCenter.default.post(name: NSNotification.Name("NexusFocusGenieSearchBar"), object: nil)
            }
            .onAppear {
                barModeRaw = "chat"
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                    NotificationCenter.default.post(name: NSNotification.Name("NexusFocusGenieSearchBar"), object: nil)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusFocusGenieSearchBarWithMode"))) { notif in
                let targetMode = (notif.object as? String) ?? "chat"
                withAnimation(.spring(response: 0.44, dampingFraction: 0.88)) {
                    barModeRaw = targetMode
                    if isChatDockedToMenuBar {
                        isChatDockedToMenuBar = false
                    }
                }
                DesktopWindowManager.shared.setPage(1)
                NotificationCenter.default.post(name: NSNotification.Name("NexusFocusGenieSearchBar"), object: nil)
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusSearchBarAppendText"))) { notif in
                if let str = notif.object as? String {
                    if isChatDockedToMenuBar {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.80)) {
                            isChatDockedToMenuBar = false
                        }
                    }
                    if noteText.isEmpty {
                        noteText = str
                    } else if !noteText.hasSuffix(str) {
                        noteText += str
                    }
                    isFocused = true
                    NotificationCenter.default.post(name: NSNotification.Name("NexusFocusGenieSearchBar"), object: nil)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusFocusGenieSearchBar"))) { _ in
                if isChatDockedToMenuBar {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.80)) {
                        isChatDockedToMenuBar = false
                    }
                }
                isFocused = true
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusToggleSearchBar"))) { _ in
                if isChatDockedToMenuBar {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.80)) {
                        isChatDockedToMenuBar = false
                    }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusSummoniPhoneMirrorViewer"))) { _ in
                if isChatDockedToMenuBar {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.80)) {
                        isChatDockedToMenuBar = false
                    }
                }
                withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                    barModeRaw = BarMode.screenMirror.rawValue
                }
                iPhoneMirrorManager.shared.startStreaming()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusAITakePolaroid"))) { notif in
                if let memo = notif.object as? String, !memo.isEmpty {
                    self.noteText = memo
                }
                self.executePolaroidCapture()
            }

            // ── Status feedback badge ──
            if let fb = statusFeedback {
                HStack(spacing: 5) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(fb)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.85))
                        .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 0.75))
                )
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            // ── Reverse Genie Document Dispense Animation ──
            if isDroppingNote {
                HStack(spacing: 7) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.cyan)
                    Text("Genie Doc ✨")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 13)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [Color(red: 0.12, green: 0.18, blue: 0.32).opacity(0.95), Color(red: 0.04, green: 0.06, blue: 0.14).opacity(0.95)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(Capsule().stroke(LinearGradient(colors: [.cyan, .indigo, .purple], startPoint: .leading, endPoint: .trailing), lineWidth: 1.0))
                        .shadow(color: Color.cyan.opacity(0.45), radius: 10, y: 4)
                )
                .offset(y: dropOffsetY)
                .scaleEffect(dropScale)
                .rotationEffect(.degrees(dropRotation))
                .opacity(dropOpacity)
                .allowsHitTesting(false)
            }
            // ── Hidable Cheat Sheet View (Below Capsule) ──
            if showCheatSheet {
                cheatSheetView
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        } // closes inner VStack

        // ── Compact Inline Quick Note Drawer ──
        if showQuickNoteDrawer {
            compactRightSideQuickNoteView
                .transition(.asymmetric(
                    insertion: .scale(scale: 0.92).combined(with: .opacity).combined(with: .move(edge: .trailing)),
                    removal: .scale(scale: 0.92).combined(with: .opacity).combined(with: .move(edge: .trailing))
                ))
        }
    } // closes HStack
    .offset(
        x: isChatFullScreen ? 0 : (CGFloat(chatOffsetX) + dragCurrentTranslation.width),
        y: isChatFullScreen ? 0 : (CGFloat(chatOffsetY) + dragCurrentTranslation.height)
    )
    .animation(.spring(response: 0.32, dampingFraction: 0.82), value: isChatDetached)
} // closes else
    }

    // MARK: - Submission Handler
    private func handleSubmit() {
        switch currentMode {
        case .chat:
            executeChat()
        case .search:
            executeSearch()
        case .apps:
            let query = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !query.isEmpty {
                if let app = AppModel.shared?.filteredApps(search: query, category: nil).first {
                    NSWorkspace.shared.openApplication(at: app.url, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
                    showFeedback("Launching \(app.name) 🚀")
                    noteText = ""
                } else {
                    Process.launchedProcess(launchPath: "/usr/bin/open", arguments: ["-a", query])
                    showFeedback("Opening \(query)...")
                    noteText = ""
                }
            }
        case .file:
            let lower = noteText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            if lower.hasPrefix("what") || lower.hasPrefix("how") || lower.hasPrefix("why") || lower.hasPrefix("who") ||
               lower.hasPrefix("can") || lower.hasPrefix("tell") || lower.hasPrefix("explain") || lower.hasPrefix("write") ||
               lower.hasPrefix("hi") || lower.hasPrefix("hello") || lower.contains("?") || lower == "whats up" {
                barModeRaw = "chat"
                executeChat()
            } else {
                executeFileNoteAndExit()
            }
        case .terminal:
            executeTerminal()
        case .polaroid:
            executePolaroidCapture()
        case .screenMirror:
            let ocr = iPhoneMirrorManager.shared.recognizedText
            let query = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
            let fullPrompt = ocr.isEmpty ? query : "\(query)\n\n[iPhone Screen OCR Context]:\n\(ocr)"
            barModeRaw = "chat"
            noteText = fullPrompt
            executeChat()
        case .vision:
            executeVisionCapture()
        case .settings:
            executeChat()
        }
    }

    // MARK: - Command + Return: Deep Reasoning Mode
    private func handleCommandSubmit() {
        if currentMode == .chat {
            let content = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !content.isEmpty else { return }

            pulseBorder()
            HapticFeedback.heavy()
            showFeedback("Deep Reasoning Mode ✨ (⌘↵)")

            let proModel: String = {
                if localModels.hasGeminiKey { return "gemini-2.5-pro" }
                if localModels.hasClaudeKey { return "claude-3-7-sonnet-20250219" }
                if localModels.hasOpenAIKey { return "o3-mini" }
                return localModels.effectiveModel
            }()

            localModels.generate(prompt: content, overrideModel: proModel)
            withAnimation(.easeOut(duration: 0.15)) {
                noteText = ""
            }
        } else {
            handleSubmit()
        }
    }

    // MARK: - Chat Drag Gesture (Fluid Free Movement)
    private var chatDragGesture: some Gesture {
        DragGesture(minimumDistance: 1)
            .onChanged { val in
                if !isChatLockedInPlace {
                    dragCurrentTranslation = val.translation
                    if !isChatDetached {
                        isChatDetached = true
                    }
                }
            }
            .onEnded { val in
                if !isChatLockedInPlace {
                    chatOffsetX += Double(val.translation.width)
                    chatOffsetY += Double(val.translation.height)
                    dragCurrentTranslation = .zero
                    UserDefaults.standard.set(chatOffsetX, forKey: "nexus.chatOffsetX")
                    UserDefaults.standard.set(chatOffsetY, forKey: "nexus.chatOffsetY")
                    UserDefaults.standard.set(true, forKey: "nexus.isChatDetached")
                }
            }
    }

    // MARK: - Consolidated Chat Bar Control Hub (Layer Switcher, Voice, Model & Pin)
    @ViewBuilder
    private var rightSideControlsGroup: some View {
        HStack(spacing: 5) {
            // ── Integrated Voice Speech Button ──
            Button(action: {
                HapticFeedback.selection()
                if voiceEngine.isSpeaking {
                    voiceEngine.stop()
                } else if !noteText.isEmpty {
                    voiceEngine.speak(noteText)
                } else {
                    voiceEngine.speak("Genie ready. How can I help you today?")
                }
            }) {
                Image(systemName: voiceEngine.isSpeaking ? "waveform" : "speaker.wave.2.fill")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(voiceEngine.isSpeaking ? .cyan : .white.opacity(0.55))
                    .padding(4.5)
                    .background(Circle().fill(voiceEngine.isSpeaking ? Color.cyan.opacity(0.25) : Color.white.opacity(0.08)))
            }
            .buttonStyle(.plain)
            .help(voiceEngine.isSpeaking ? "Stop Speaking" : "Read Text Aloud 🗣️")

            // ── Compact Layer Switcher Pills ──
            HStack(spacing: 2) {
                // 💬 Chat Layer
                Button(action: {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) { currentMode = .chat }
                    HapticFeedback.selection()
                }) {
                    Image(systemName: "message.fill")
                        .font(.system(size: 10))
                        .foregroundColor(currentMode == .chat ? .cyan : .white.opacity(0.40))
                        .padding(4)
                        .background(currentMode == .chat ? Capsule().fill(Color.cyan.opacity(0.20)) : Capsule().fill(Color.clear))
                }
                .buttonStyle(.plain)
                .help("Chat Studio Layer 💬")

                // 📱 Apps Layer
                Button(action: {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) { currentMode = .apps }
                    HapticFeedback.selection()
                }) {
                    Image(systemName: "square.grid.2x2.fill")
                        .font(.system(size: 10))
                        .foregroundColor(currentMode == .apps ? .orange : .white.opacity(0.40))
                        .padding(4)
                        .background(currentMode == .apps ? Capsule().fill(Color.orange.opacity(0.20)) : Capsule().fill(Color.clear))
                }
                .buttonStyle(.plain)
                .help("Applications Box Layer 📱")

                // 💻 Terminal Console Layer
                Button(action: {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) { currentMode = .terminal }
                    HapticFeedback.selection()
                }) {
                    Image(systemName: "terminal.fill")
                        .font(.system(size: 10))
                        .foregroundColor(currentMode == .terminal ? .green : .white.opacity(0.40))
                        .padding(4)
                        .background(currentMode == .terminal ? Capsule().fill(Color.green.opacity(0.20)) : Capsule().fill(Color.clear))
                }
                .buttonStyle(.plain)
                .help("Terminal Directive Console 💻")

                // 📄 Note Layer
                Button(action: {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) { currentMode = .file }
                    HapticFeedback.selection()
                }) {
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 10))
                        .foregroundColor(currentMode == .file ? .mint : .white.opacity(0.40))
                        .padding(4)
                        .background(currentMode == .file ? Capsule().fill(Color.mint.opacity(0.20)) : Capsule().fill(Color.clear))
                }
                .buttonStyle(.plain)
                .help("Executive Memorandum Layer 📄")

                // ⚙️ Genie Settings Hub Layer
                Button(action: {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) { currentMode = (currentMode == .settings) ? .chat : .settings }
                    HapticFeedback.selection()
                }) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 10.5, weight: .bold))
                        .foregroundColor(currentMode == .settings ? .yellow : .white.opacity(0.50))
                        .padding(4)
                        .background(currentMode == .settings ? Capsule().fill(Color.yellow.opacity(0.25)) : Capsule().fill(Color.clear))
                }
                .buttonStyle(.plain)
                .help("Genie Settings Hub ⚙️")
            }
            .padding(2)
            .background(Capsule().fill(Color.white.opacity(0.06)))

            // ── Compact AI Model Pill ──
            Menu {
                ForEach(LocalModelManager.cloudModels) { model in
                    Button(action: {
                        localModels.manualSelectedModel = model.id
                        HapticFeedback.selection()
                    }) {
                        HStack {
                            Text(model.displayName)
                            if localModels.manualSelectedModel == model.id {
                                Text("✓")
                            }
                        }
                    }
                }
            } label: {
                HStack(spacing: 3) {
                    Circle()
                        .fill(Color.cyan)
                        .frame(width: 4, height: 4)
                    Text(localModels.selectedModelDisplayName)
                        .font(.system(size: 9, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.80))
                        .lineLimit(1)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3.5)
                .background(Capsule().fill(Color.white.opacity(0.10)))
            }
            .menuStyle(.borderlessButton)
            .fixedSize()

            // ── Lock / Pin Chat ──
            Button(action: {
                HapticFeedback.selection()
                isChatLockedInPlace.toggle()
                showFeedback(isChatLockedInPlace ? "Chat Locked in Place 📌" : "Chat Floating Freely 🕊️")
            }) {
                Image(systemName: isChatLockedInPlace ? "pin.fill" : "pin")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(isChatLockedInPlace ? .yellow : .white.opacity(0.35))
            }
            .buttonStyle(.plain)
            .help(isChatLockedInPlace ? "Unlock Chat position" : "Lock Chat in place")
        }
    }

    // MARK: - 🛸 Mini Dock & Battery Strip in Chat Bar ("wheres the mini dock i want it in the menu bar and the chat bar", "we missing the battery")
    @ViewBuilder
    private func chatBarSpacePill(space: MacDesktopSpace) -> some View {
        let isCurr = space.isCurrent
        let textColor = isCurr ? Color.cyan : Color.white.opacity(0.65)
        let pillBg = isCurr ? Color.cyan.opacity(0.30) : Color.white.opacity(0.08)
        let strokeColor = isCurr ? Color.cyan.opacity(0.65) : Color.white.opacity(0.12)

        Button {
            HapticFeedback.selection()
            MacDesktopsManager.shared.switchToDesktop(index: space.index)
        } label: {
            HStack(spacing: 2) {
                Image(systemName: "display")
                    .font(.system(size: 8.5, weight: .bold))
                Text("\(space.index)")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
            }
            .foregroundColor(textColor)
            .padding(.horizontal, 4.5)
            .padding(.vertical, 2)
            .background(Capsule().fill(pillBg))
            .overlay(Capsule().strokeBorder(strokeColor, lineWidth: 0.5))
        }
        .buttonStyle(.plain)
        .help("Switch to Desktop Space \(space.index)")
    }

    @ViewBuilder
    private var chatBarSpacesSegment: some View {
        HStack(spacing: 3) {
            ForEach(MacDesktopsManager.shared.spaces) { space in
                chatBarSpacePill(space: space)
            }
        }
    }

    @ViewBuilder
    private func chatBarDockAppIcon(item: DockAppItem) -> some View {
        let isAppActive = item.runningApp?.isActive == true
        Button {
            HapticFeedback.selection()
            if let app = item.runningApp {
                SmartGridManager.shared.bringToFront(app: app)
            } else if let bundleId = item.bundleIdentifier {
                if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
                    NSWorkspace.shared.open(url)
                }
            }
        } label: {
            ZStack(alignment: .bottom) {
                if let icon = item.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 19, height: 19)
                        .shadow(color: Color.black.opacity(0.3), radius: 1.5, y: 1)
                } else {
                    Image(systemName: "app.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.75))
                        .frame(width: 19, height: 19)
                }

                if item.isRunning {
                    Circle()
                        .fill(isAppActive ? Color.cyan : Color.white.opacity(0.85))
                        .frame(width: 3, height: 3)
                        .offset(y: 2.5)
                }
            }
            .frame(width: 24, height: 24)
            .background(RoundedRectangle(cornerRadius: 5, style: .continuous).fill(Color.white.opacity(0.06)))
        }
        .buttonStyle(.plain)
        .help(item.name)
    }

    @ViewBuilder
    private var chatBarAppsSegment: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 4) {
                ForEach(dockManager.dockItems) { item in
                    chatBarDockAppIcon(item: item)
                }
            }
        }
        .frame(maxWidth: 320)
    }

    @ViewBuilder
    private var chatBarBatterySegment: some View {
        Button(action: {
            HapticFeedback.selection()
            MenuBarActionDispatcher.shared.cycleNextBatteryStyle()
        }) {
            HStack(spacing: 3.5) {
                Image(systemName: batteryMonitor.isCharging ? "battery.100.bolt" : ((batteryMonitor.batteryPct ?? 50) > 20 ? "battery.75" : "battery.25"))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor((batteryMonitor.batteryPct ?? 50) <= 20 ? .red : (batteryMonitor.isCharging ? .green : .cyan))

                Text("\(batteryMonitor.batteryPct ?? 47)%")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Capsule().fill(Color.white.opacity(0.12)))
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.20), lineWidth: 0.6))
        }
        .buttonStyle(.plain)
        .help("Battery: \(batteryMonitor.batteryPct ?? 47)% — Click to cycle style")
    }

    @ViewBuilder
    private var chatBarMiniDockStrip: some View {
        HStack(spacing: 6) {
            // Genie Glyph
            Button(action: {
                HapticFeedback.selection()
                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                    currentMode = (currentMode == .chat) ? .apps : .chat
                }
            }) {
                Text("🪔")
                    .font(.system(size: 12))
                    .padding(3)
                    .background(Circle().fill(Color.white.opacity(0.12)))
            }
            .buttonStyle(.plain)
            .help("Genie Dialogue Studio")

            chatBarSpacesSegment

            Capsule()
                .fill(Color.white.opacity(0.18))
                .frame(width: 1, height: 13)
                .padding(.horizontal, 1)

            chatBarAppsSegment

            // Pinned Folder Stack
            Button(action: {
                HapticFeedback.selection()
                let path = (UserDefaults.standard.string(forKey: "nexus.barFolderPath") ?? NSHomeDirectory() + "/Downloads") as NSString
                NSWorkspace.shared.open(URL(fileURLWithPath: path.expandingTildeInPath))
            }) {
                Image(systemName: "folder.fill")
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundColor(.blue.opacity(0.9))
                    .frame(width: 20, height: 20)
                    .background(Circle().fill(Color.white.opacity(0.08)))
            }
            .buttonStyle(.plain)
            .help("Open Pinned Folder Stack")

            // Trash Can
            Button(action: {
                HapticFeedback.selection()
                NSWorkspace.shared.open(URL(fileURLWithPath: NSHomeDirectory() + "/.Trash"))
            }) {
                Image(systemName: "trash.fill")
                    .font(.system(size: 9.5, weight: .medium))
                    .foregroundColor(.white.opacity(0.65))
                    .frame(width: 20, height: 20)
                    .background(Circle().fill(Color.white.opacity(0.08)))
            }
            .buttonStyle(.plain)
            .help("Open Trash")

            Spacer()

            chatBarBatterySegment
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow, state: .active)
                .clipShape(Capsule())
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.15), lineWidth: 0.6))
                .shadow(color: Color.black.opacity(0.30), radius: 8, y: 2)
        )
    }

    // MARK: - Compact Right-Side Quick Note Drawer
    @ViewBuilder
    private var compactRightSideQuickNoteView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Quick Note 📝")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Button(action: {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        showQuickNoteDrawer = false
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.5))
                }
                .buttonStyle(.plain)
            }

            TextEditor(text: $quickNoteContent)
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.white)
                .frame(minWidth: 260, maxWidth: 300, minHeight: 180, maxHeight: 300)
                .scrollContentBackground(.hidden)
                .padding(6)
                .background(Color.black.opacity(0.35))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

            HStack {
                Button("Save to Notes") {
                    HapticFeedback.selection()
                    if !quickNoteContent.isEmpty {
                        DesktopStickyManager.shared.addNote(content: quickNoteContent)
                        showFeedback("Note Saved 📝")
                    }
                }
                .buttonStyle(.plain)
                .font(.system(size: 10, weight: .semibold))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.blue.opacity(0.6))
                .clipShape(Capsule())

                Spacer()

                Button("Clear") {
                    quickNoteContent = ""
                }
                .buttonStyle(.plain)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.6))
            }
        }
        .padding(12)
        .background(
            VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow, state: .active)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.8)
                )
                .shadow(color: Color.black.opacity(0.4), radius: 12, y: 4)
        )
    }

    // MARK: - Menu Bar Docked Dynamic Island Pill
    @ViewBuilder
    private var menuBarDockedPillView: some View {
        Button(action: {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.80)) {
                isChatDockedToMenuBar = false
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.cyan)
                Text(localModels.selectedModelDisplayName)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.82))
                    .overlay(
                        Capsule().stroke(
                            LinearGradient(colors: [.cyan.opacity(0.8), .indigo.opacity(0.6)], startPoint: .leading, endPoint: .trailing),
                            lineWidth: 1.0
                        )
                    )
                    .shadow(color: Color.cyan.opacity(0.35), radius: 8, y: 2)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Live App Search & Toggle Data Structure
    private struct AppSearchItem: Identifiable {
        let id: String
        let name: String
        let icon: NSImage?
        let isRunning: Bool
        let isFront: Bool
        let app: NSRunningApplication?
        let bundleURL: URL?
    }

    private var appSearchResults: [AppSearchItem] {
        let query = noteText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty && query.count >= 2 && currentMode == .search else { return [] }
        let runningApps = NSWorkspace.shared.runningApplications.filter { $0.activationPolicy == .regular }
        let frontPid = NSWorkspace.shared.frontmostApplication?.processIdentifier

        var items: [AppSearchItem] = []
        for app in runningApps {
            let name = app.localizedName ?? ""
            if name.lowercased().contains(query) {
                items.append(AppSearchItem(
                    id: "\(app.processIdentifier)",
                    name: name,
                    icon: app.icon,
                    isRunning: true,
                    isFront: app.processIdentifier == frontPid,
                    app: app,
                    bundleURL: app.bundleURL
                ))
            }
        }
        return Array(items.prefix(5))
    }

    @ViewBuilder
    private var appSearchToggleStripView: some View {
        HStack(spacing: 8) {
            ForEach(appSearchResults) { item in
                Button(action: {
                    toggleApp(item)
                }) {
                    HStack(spacing: 6) {
                        if let icon = item.icon {
                            Image(nsImage: icon)
                                .resizable()
                                .frame(width: 16, height: 16)
                                .clipShape(RoundedRectangle(cornerRadius: 3.5, style: .continuous))
                        }
                        Text(item.name)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white)
                        Circle()
                            .fill(item.isFront ? Color.green : (item.isRunning ? Color.yellow : Color.gray))
                            .frame(width: 6, height: 6)
                        Text(item.isFront ? "Hide" : (item.isRunning ? "Bring Front" : "Open"))
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.cyan)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.12))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.75))
                .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 0.6))
        )
    }

    private func toggleApp(_ item: AppSearchItem) {
        HapticFeedback.selection()
        if let app = item.app {
            if item.isFront {
                app.hide()
                showFeedback("Hidden \(item.name) 🙈")
            } else {
                app.unhide()
                app.activate()
                showFeedback("Activated \(item.name) ✨")
            }
        } else if let url = item.bundleURL {
            NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
            showFeedback("Opening \(item.name) ✨")
        }
    }

    // MARK: - Mode 1: AI Chat Execution
    private func executeChat() {
        let content = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty || attachedFileURL != nil else { return }

        pulseBorder()
        HapticFeedback.selection()

        var prompt = content
        if let fileURL = attachedFileURL {
            let notePrefix = content.isEmpty ? "Please review and analyze this attached file:" : content
            prompt = "\(notePrefix)\n\n[Attached File: \(fileURL.lastPathComponent)]\nPath: \(fileURL.path)"
            if let fileContent = try? String(contentsOf: fileURL, encoding: .utf8), !fileContent.isEmpty {
                let snippet = fileContent.prefix(2500)
                prompt += "\n```\n\(snippet)\n```"
            }
            attachedFileURL = nil
        }

        localModels.generate(prompt: prompt)
        withAnimation(.easeOut(duration: 0.15)) {
            noteText = ""
        }
    }

    // MARK: - Mode 2: Genie Document & Multi-Format Note (Save to Destination & Exit)
    private func executeFileNoteAndExit() {
        let content = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else {
            showFeedback("Type a note or memo in the unified command center 📄")
            return
        }

        pulseBorder()
        if notePrinterSoundEnabled {
            HapticFeedback.playPrinterSound()
        }

        let targetFolder = currentDestinationFolderURL
        let savedURLs = DesktopNotePrinter.shared.saveToDestination(
            destination: selectedOutputDestination,
            content: content,
            destinationFolder: targetFolder
        )

        var feedback = "Saved \(selectedOutputDestination.shortLabel) ✨"
        if let fileURL = savedURLs.first {
            feedback = "Saved \(selectedOutputDestination.shortLabel) to \(targetFolder.lastPathComponent)"
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(fileURL.path, forType: .string)
            NotificationCenter.default.post(
                name: NSNotification.Name("NexusDesktopNotePrinted"),
                object: fileURL
            )
            self.localModels.chatHistory.append(
                ChatMessage(
                    role: "user",
                    content: content,
                    model: "Quick Note (\(selectedOutputDestination.shortLabel))",
                    mediaType: "cue_note",
                    mediaPath: fileURL.path
                )
            )
            self.localModels.saveChatHistory()
        }

        self.triggerDropAnimation()
        withAnimation(.easeOut(duration: 0.15)) {
            self.noteText = ""
        }
        self.showFeedback(feedback)
        self.dismissOverlay()
    }

    // MARK: - Mode 3: Internet Web Search (Consolidated Genie Viewer)
    private func executeSearch() {
        let query = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return }

        pulseBorder()
        HapticFeedback.selection()

        // 1. Dispatch search / URL navigation to internal Genie Viewer
        MiniBrowserManager.shared.search(query: query)

        // 2. Open consolidated browser directly in this window
        withAnimation(.spring(response: 0.30, dampingFraction: 0.82)) {
            currentMode = .search
        }

        withAnimation(.easeOut(duration: 0.15)) {
            noteText = ""
        }
        showFeedback("Searching in Genie Browser 🌐")
    }

    // MARK: - Mode 4: Terminal Command Execution
    private func executeTerminal() {
        let cmd = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        showTerminalPopover = true
        guard !cmd.isEmpty else { return }

        pulseBorder()
        HapticFeedback.selection()
        localModels.terminalAccessEnabled = true

        NotificationCenter.default.post(name: NSNotification.Name("NexusExecuteTerminalCommand"), object: cmd)
        withAnimation(.easeOut(duration: 0.15)) {
            noteText = ""
        }
        showFeedback("Running: \(cmd) 💻")

        Task {
            let res = await LocalModelManager.shared.executeTerminalCommand(cmd)
            await MainActor.run {
                NotificationCenter.default.post(
                    name: NSNotification.Name("NexusTerminalCommandExecuted"),
                    object: (command: cmd, output: res.output)
                )
            }
        }
    }

    // MARK: - Apple Messages Integration ("Goes to My Messages")
    public func sendToAppleMessages(text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        HapticFeedback.selection()

        // 1. Guaranteed clipboard backup: text is ready to paste anywhere
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(trimmed, forType: .string)

        // 2. Open Messages app
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.MobileSMS") {
            NSWorkspace.shared.openApplication(at: appURL, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
        } else if let url = URL(string: "messages:") {
            NSWorkspace.shared.open(url)
        }

        // 3. AppleScript automated compose draft
        DispatchQueue.global(qos: .userInteractive).async {
            let script = """
            tell application "Messages" to activate
            delay 0.25
            tell application "System Events"
                tell process "Messages"
                    try
                        keystroke "n" using command down
                        delay 0.15
                        keystroke "v" using command down
                    end try
                end tell
            end tell
            """
            NSAppleScript(source: script)?.executeAndReturnError(nil)
        }

        showFeedback("Copied & Opened in Messages 💬")
    }

    public func sendFullChatToAppleMessages() {
        guard !localModels.chatHistory.isEmpty else {
            showFeedback("Chat history is empty! 💬")
            return
        }
        HapticFeedback.selection()
        showFeedback("Sending to Apple Messages 💬...")
        localModels.sendChatToAppleMessages()
    }

    private func invokeAppleSpotlight(query: String) {
        if !query.isEmpty {
            let pb = NSPasteboard.general
            pb.clearContents()
            pb.setString(query, forType: .string)
        }

        let src = CGEventSource(stateID: .combinedSessionState)
        let spaceKey: CGKeyCode = 49

        if let down = CGEvent(keyboardEventSource: src, virtualKey: spaceKey, keyDown: true),
           let up = CGEvent(keyboardEventSource: src, virtualKey: spaceKey, keyDown: false) {
            down.flags = .maskCommand
            up.flags = []
            down.post(tap: .cghidEventTap)
            up.post(tap: .cghidEventTap)
        }

        let script = "tell application \"System Events\" to key code 49 using command down"
        NSAppleScript(source: script)?.executeAndReturnError(nil)

        if !query.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
                let vKey: CGKeyCode = 9
                if let vDown = CGEvent(keyboardEventSource: src, virtualKey: vKey, keyDown: true),
                   let vUp = CGEvent(keyboardEventSource: src, virtualKey: vKey, keyDown: false) {
                    vDown.flags = .maskCommand
                    vUp.flags = []
                    vDown.post(tap: .cghidEventTap)
                    vUp.post(tap: .cghidEventTap)
                }
            }
        }
    }

    // MARK: - Escape & Dismiss Handlers
    private func handleEscape() {
        if !noteText.isEmpty {
            withAnimation(.easeOut(duration: 0.15)) {
                noteText = ""
            }
        } else if !localModels.currentResponse.isEmpty {
            withAnimation(.easeOut(duration: 0.15)) {
                localModels.currentResponse = ""
                localModels.currentThinking = ""
            }
        } else {
            dismissImmediately()
        }
    }

    private func dismissImmediately() {
        DesktopWindowManager.shared.setPage(0)
        NotificationCenter.default.post(name: NSNotification.Name("NexusDismissDesktopGrid"), object: nil)
    }

    private func dismissOverlay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.32) {
            DesktopWindowManager.shared.setPage(0)
            NotificationCenter.default.post(name: NSNotification.Name("NexusDismissDesktopGrid"), object: nil)
        }
    }

    private func pulseBorder() {
        withAnimation(.easeIn(duration: 0.08)) { flashPulse = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
            withAnimation(.easeOut(duration: 0.18)) { flashPulse = false }
        }
    }

    private func triggerDropAnimation() {
        dropOffsetY = 4
        dropScale = 0.08
        dropOpacity = 0.4
        dropRotation = -10.0
        isDroppingNote = true

        withAnimation(.spring(response: 0.36, dampingFraction: 0.65)) {
            dropOffsetY = 60
            dropScale = 1.10
            dropRotation = 2.0
            dropOpacity = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.28) {
            withAnimation(.spring(response: 0.26, dampingFraction: 0.8)) {
                dropOffsetY = 68
                dropScale = 1.0
                dropRotation = 0.0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.85) {
            withAnimation(.easeOut(duration: 0.30)) {
                dropOpacity = 0.0
                dropOffsetY = 85
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.20) {
            isDroppingNote = false
        }
    }

    private func showFeedback(_ msg: String) {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            statusFeedback = msg
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeOut(duration: 0.25)) {
                statusFeedback = nil
            }
        }
    }

    // MARK: - Dedicated Chat Settings & Direct API Key Input Menu Popover
    private var chatSettingsPopoverContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "key.fill")
                    .foregroundColor(.cyan)
                Text("Chat Settings & API Keys")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                Spacer()
                Button(action: { showChatSettingsPopover = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            Divider().opacity(0.35)

            // 1. Google Gemini Key Input Box
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .foregroundColor(.blue)
                        Text("Google Gemini Key / Token")
                            .font(.system(size: 11.5, weight: .semibold))
                    }
                    Spacer()
                    if localModels.hasGeminiKey {
                        Text("Active ✓")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.green)
                    } else {
                        Text("Key Required")
                            .font(.system(size: 9.5))
                            .foregroundColor(.orange)
                    }
                }

                HStack(spacing: 6) {
                    TextField("AQ.... or AIzaSy...", text: Binding(
                        get: { localModels.geminiApiKey },
                        set: { localModels.geminiApiKey = $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 10.5, design: .monospaced))

                    Button(action: {
                        if let clip = NSPasteboard.general.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines), !clip.isEmpty {
                            localModels.geminiApiKey = clip
                            HapticFeedback.selection()
                            showFeedback("Key Pasted! 📋")
                        }
                    }) {
                        Text("Paste")
                            .font(.system(size: 10, weight: .medium))
                    }
                }

                // 1-Click Button to directly insert AQ.Ab8RN6KQdZll5kIJEFdF5jHHFDp8s5NxF8kZTRItnCRHb84ltw
                Button(action: {
                    localModels.geminiApiKey = "AQ.Ab8RN6KQdZll5kIJEFdF5jHHFDp8s5NxF8kZTRItnCRHb84ltw"
                    HapticFeedback.selection()
                    showFeedback("Gemini Key Inserted! ⚡️")
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 9))
                        Text("Insert AQ.Ab8RN... Key")
                            .font(.system(size: 10, weight: .medium))
                    }
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Color.cyan.opacity(0.12)))
                }
                .buttonStyle(.plain)
            }

            Divider().opacity(0.25)

            // 2. Anthropic Claude Key
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "brain.head.profile")
                            .foregroundColor(.orange)
                        Text("Anthropic Claude Key")
                            .font(.system(size: 11.5, weight: .semibold))
                    }
                    Spacer()
                    if localModels.hasClaudeKey {
                        Text("Active ✓")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.green)
                    }
                }
                HStack(spacing: 6) {
                    TextField("sk-ant-...", text: Binding(
                        get: { localModels.claudeApiKey },
                        set: { localModels.claudeApiKey = $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 10.5, design: .monospaced))

                    Button(action: {
                        if let clip = NSPasteboard.general.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines), !clip.isEmpty {
                            localModels.claudeApiKey = clip
                            HapticFeedback.selection()
                            showFeedback("Claude Key Pasted! 📋")
                        }
                    }) {
                        Text("Paste")
                            .font(.system(size: 10, weight: .medium))
                    }
                }
            }

            Divider().opacity(0.25)

            // 3. OpenAI Key
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "cpu")
                            .foregroundColor(.green)
                        Text("OpenAI Key")
                            .font(.system(size: 11.5, weight: .semibold))
                    }
                    Spacer()
                    if localModels.hasOpenAIKey {
                        Text("Active ✓")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.green)
                    }
                }
                HStack(spacing: 6) {
                    TextField("sk-...", text: Binding(
                        get: { localModels.openaiApiKey },
                        set: { localModels.openaiApiKey = $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .font(.system(size: 10.5, design: .monospaced))

                    Button(action: {
                        if let clip = NSPasteboard.general.string(forType: .string)?.trimmingCharacters(in: .whitespacesAndNewlines), !clip.isEmpty {
                            localModels.openaiApiKey = clip
                            HapticFeedback.selection()
                            showFeedback("OpenAI Key Pasted! 📋")
                        }
                    }) {
                        Text("Paste")
                            .font(.system(size: 10, weight: .medium))
                    }
                }
            }

            Divider().opacity(0.35)

            // 4. Local Models Engine & Shutoff
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "desktopcomputer")
                            .foregroundColor(.teal)
                        Text("Local Models Engine (Ollama)")
                            .font(.system(size: 11.5, weight: .semibold))
                    }
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { localModels.localModelsEnabled },
                        set: { enabled in
                            if enabled {
                                localModels.enableLocalModels()
                            } else {
                                localModels.shutoffLocalModels()
                            }
                        }
                    ))
                    .toggleStyle(.switch)
                    .labelsHidden()
                }

                HStack {
                    Text(localModels.localModelsEnabled ? (localModels.isConnectedToLocalEngine ? "Connected 🟢" : "Enabled 🟡") : "Shut Off ⏻")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(localModels.localModelsEnabled ? .green : .secondary)
                    Spacer()
                    if localModels.localModelsEnabled {
                        Button("Shut Off & Eject ⏻") {
                            localModels.shutoffLocalModels()
                            HapticFeedback.heavy()
                            showFeedback("Local Models Shut Off ⏻")
                        }
                        .font(.system(size: 9.5, weight: .semibold))
                        .foregroundColor(.red.opacity(0.9))
                        .buttonStyle(.plain)
                    }
                }
            }

            Divider().opacity(0.35)

            // 5. Terminal Tool Access & Developer Execution
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    HStack(spacing: 4) {
                        Image(systemName: "terminal.fill")
                            .foregroundColor(.green)
                        Text("Terminal Tool Access")
                            .font(.system(size: 11.5, weight: .semibold))
                    }
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { localModels.terminalAccessEnabled },
                        set: { localModels.terminalAccessEnabled = $0 }
                    ))
                    .toggleStyle(.switch)
                    .labelsHidden()
                }

                if localModels.terminalAccessEnabled {
                    HStack {
                        Text("Auto-Execute Terminal Commands")
                            .font(.system(size: 10.5))
                            .foregroundColor(.secondary)
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { localModels.terminalAutoExecute },
                            set: { localModels.terminalAutoExecute = $0 }
                        ))
                        .toggleStyle(.switch)
                        .labelsHidden()
                    }
                }
            }

            Divider().opacity(0.35)

            // 6. AI Emotion & Graphics Window Toggle
            HStack {
                Image(systemName: "sparkles.tv")
                    .foregroundColor(.purple)
                Text("AI Emotion & Media Window Above Chat")
                    .font(.system(size: 11, weight: .medium))
                Spacer()
                Toggle("", isOn: $showEmotionPlayer)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }
        }
        .padding(14)
        .frame(width: 350)
    }

    // MARK: - Endless Upward Fading Chat Stream Logic & Views
    private var shouldShowChatStream: Bool {
        !localModels.chatHistory.isEmpty || localModels.isGenerating || !localModels.currentResponse.isEmpty
    }

    // MARK: - Vertical Upward Fading iMessage Chat Stream
    private var verticalFadingChatStreamView: some View {
        VStack(spacing: 0) {
            // Drag handle at top of chat stream
            HStack {
                Spacer()
                Capsule()
                    .fill(Color.white.opacity(0.35))
                    .frame(width: 48, height: 5)
                    .padding(.top, 6)
                    .padding(.bottom, 4)
                Spacer()
            }
            .contentShape(Rectangle())
            .gesture(chatDragGesture)

            // ── AI THEATRE MARQUEE PROSCENIUM HEADER ──
            HStack(spacing: 8) {
                // Live Stage Beacon & Marquee Title (Draggable Area)
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color(red: 0.0, green: 0.95, blue: 0.45))
                        .frame(width: 7, height: 7)
                        .shadow(color: Color(red: 0.0, green: 0.95, blue: 0.45).opacity(0.85), radius: 3)

                    Text("🎭 AI THEATRE")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)

                    Text("(\(localModels.selectedModelDisplayName))")
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(.cyan.opacity(0.85))

                    // Fullscreen Toggle Button
                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                            isChatFullScreen.toggle()
                            if isChatFullScreen {
                                chatOffsetX = 0
                                chatOffsetY = 0
                            }
                        }
                        HapticFeedback.selection()
                        showFeedback(isChatFullScreen ? "Full Screen AI Theatre ⛶" : "Restored Window Size")
                    }) {
                        Image(systemName: isChatFullScreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.white.opacity(0.85))
                            .padding(4)
                            .background(Circle().fill(Color.white.opacity(0.12)))
                    }
                    .buttonStyle(.plain)
                    .help(isChatFullScreen ? "Exit Full Screen" : "Enter Full Screen ⛶")
                }
                .contentShape(Rectangle())
                .gesture(chatDragGesture)

                Spacer()

                // 1. Recall to Front
                Button(action: {
                    NSApp.activate(ignoringOtherApps: true)
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        currentMode = .chat
                        isBrowserRecalledToFront = false
                    }
                    showFeedback("Recalled Chat to Front 🎭")
                    HapticFeedback.selection()
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.up.forward.app")
                        Text("Recall Front")
                    }
                    .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3.5)
                    .background(Capsule().fill(Color.cyan.opacity(0.35)))
                    .overlay(Capsule().stroke(Color.cyan.opacity(0.55), lineWidth: 0.6))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("genie.chat.recall_front")
                .help("Elevate Chat to Frontmost & Focus")

                // 2. Genie Voice & Curated Women's Dialect Menu
                Menu {
                    Toggle(isOn: $voiceEngine.autoSpeakEnabled) {
                        Label("Auto-Speak AI Responses", systemImage: "sparkles")
                    }

                    if voiceEngine.isSpeaking {
                        Button("Stop Speaking", action: { voiceEngine.stop() })
                    }

                    Divider()

                    Text("Curated Women's Voices by Dialect:")
                        .font(.caption)

                    ForEach(voiceEngine.curatedWomenVoices) { voice in
                        Button(action: {
                            voiceEngine.selectedVoiceIdentifier = voice.id
                            voiceEngine.previewVoice(voice)
                        }) {
                            HStack {
                                Text("\(voice.regionFlag) \(voice.name) (\(voice.dialectName))")
                                if voiceEngine.selectedVoiceIdentifier == voice.id {
                                    Text("✓")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 3.5) {
                        if voiceEngine.isSpeaking {
                            HStack(spacing: 1.5) {
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(Color.purple)
                                    .frame(width: 2, height: max(4, 13 * voiceEngine.audioEnergy))
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(Color.cyan)
                                    .frame(width: 2, height: max(6, 15 * (1.1 - voiceEngine.audioEnergy)))
                                RoundedRectangle(cornerRadius: 1)
                                    .fill(Color.purple)
                                    .frame(width: 2, height: max(4, 11 * voiceEngine.audioEnergy))
                            }
                            .frame(height: 13)
                        } else {
                            Image(systemName: voiceEngine.autoSpeakEnabled ? "speaker.wave.2.fill" : "speaker.fill")
                                .font(.system(size: 9.5))
                        }
                        Text("Voice")
                            .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3.5)
                    .background(Capsule().fill(Color.purple.opacity(0.35)))
                    .overlay(Capsule().stroke(Color.purple.opacity(0.55), lineWidth: 0.6))
                }
                .menuStyle(.borderlessButton)
                .help("Genie Apple Voice & Curated Dialects")

                // 3. Smart Clean Mode Toggle (Hide / Show Buttons)
                Button(action: {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        chatSmartCleanMode.toggle()
                    }
                    HapticFeedback.selection()
                    showFeedback(chatSmartCleanMode ? "Smart Clean Mode: Buttons Hidden ✨" : "Full Control Mode 🛠️")
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: chatSmartCleanMode ? "sparkles" : "slider.horizontal.3")
                        Text(chatSmartCleanMode ? "Smart" : "Controls")
                    }
                    .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3.5)
                    .background(Capsule().fill(Color.white.opacity(0.15)))
                    .overlay(Capsule().stroke(Color.white.opacity(0.25), lineWidth: 0.6))
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("genie.chat.smart_mode")
                .help("Toggle Smart Clean Minimal Mode")

                // Optional Action Buttons (Hidden when in Smart Clean Mode)
                if !chatSmartCleanMode {
                    // Polaroid
                    Button(action: {
                        executePolaroidCapture()
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "camera.fill")
                            Text("Polaroid")
                        }
                        .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3.5)
                        .background(Capsule().fill(Color.orange.opacity(0.40)))
                        .overlay(Capsule().stroke(Color.orange.opacity(0.60), lineWidth: 0.6))
                    }
                    .buttonStyle(.plain)
                    .help("Capture Photo & Print Polaroid 📸")

                    // Note (Unified Command Center)
                    Button(action: {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                            currentMode = .file
                        }
                        showFeedback("Command Center: Note Mode 📄")
                        NotificationCenter.default.post(name: NSNotification.Name("NexusFocusGenieSearchBar"), object: nil)
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "doc.text.fill")
                            Text("Note")
                        }
                        .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3.5)
                        .background(Capsule().fill(Color.green.opacity(0.35)))
                        .overlay(Capsule().stroke(Color.green.opacity(0.55), lineWidth: 0.6))
                    }
                    .buttonStyle(.plain)
                    .help("Quick Note in Command Center 📄")

                    // Terminal
                    Button(action: {
                        showTerminalPopover = true
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "terminal.fill")
                            Text(">_")
                        }
                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3.5)
                        .background(Capsule().fill(Color.purple.opacity(0.40)))
                        .overlay(Capsule().stroke(Color.purple.opacity(0.60), lineWidth: 0.6))
                    }
                    .buttonStyle(.plain)
                    .help("Developer Terminal 💻")

                    // Browser
                    Button(action: {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                            currentMode = .search
                            isBrowserRecalledToFront = true
                        }
                        HapticFeedback.selection()
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "globe")
                            Text("Browser")
                        }
                        .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3.5)
                        .background(Capsule().fill(Color.blue.opacity(0.40)))
                        .overlay(Capsule().stroke(Color.blue.opacity(0.60), lineWidth: 0.6))
                    }
                    .buttonStyle(.plain)
                    .help("Switch to Web Browser 🌐")

                    // Apps (Viewer Box)
                    Button(action: {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                            currentMode = .apps
                        }
                        HapticFeedback.selection()
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "square.grid.2x2.fill")
                            Text("Apps")
                        }
                        .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3.5)
                        .background(Capsule().fill(Color.orange.opacity(0.40)))
                        .overlay(Capsule().stroke(Color.orange.opacity(0.60), lineWidth: 0.6))
                    }
                    .buttonStyle(.plain)
                    .help("View Applications in Viewer Box 🪟")
                }

                // Settings Button moved directly to this bar
                Button(action: {
                    HapticFeedback.selection()
                    AppDelegate.shared?.showMenuBarSettingsDropdown(targetTab: .system)
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "gearshape.fill")
                        Text("Settings")
                    }
                    .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.90))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3.5)
                    .background(Capsule().fill(Color.purple.opacity(0.35)))
                    .overlay(Capsule().stroke(Color.purple.opacity(0.55), lineWidth: 0.6))
                }
                .buttonStyle(.plain)
                .help("Genie Preferences & Settings ⚙️")

                // Backstage Options Menu
                Menu {
                    Button(LocalizedStrings.translateText("New Chat", lang: appLanguage)) {
                        localModels.startNewChat()
                        HapticFeedback.selection()
                        showFeedback("New Chat Started! ✨")
                    }

                    Button(LocalizedStrings.translateText("Saved Chat Sessions...", lang: appLanguage)) {
                        showSavedChatsDrawer.toggle()
                    }

                    Divider()

                    Button(LocalizedStrings.translateText("Save Full Chat to Apple Notes", lang: appLanguage)) {
                        saveFullChatToAppleNotes()
                    }

                    Button(LocalizedStrings.translateText("Send Full Chat to Apple Messages", lang: appLanguage)) {
                        sendFullChatToAppleMessages()
                    }

                    Divider()

                    Button(LocalizedStrings.translateText("Clear History", lang: appLanguage)) {
                        localModels.clearChatHistory()
                        HapticFeedback.tick()
                        showFeedback("Chat Cleared 🧹")
                    }

                    Button(LocalizedStrings.translateText("Genie Settings...", lang: appLanguage)) {
                        AppDelegate.shared?.showMenuBarSettingsDropdown(targetTab: .system)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.75))
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.40))

            Divider().opacity(0.20)

            // ── 🖥️ CLONED SCREENS SWITCHER & MINI DOCK IN CHAT ("clone the mini dock to the chat so its perfect and move the screens to the chat too") ──
            HStack(spacing: 8) {
                // Desktop Screens Switcher
                DesktopSpacesNavigatorBar()
                    .scaleEffect(0.92)

                Spacer(minLength: 6)

                // Cloned Mini Dock Apps Strip
                ScrollView(.horizontal, showsIndicators: false) {
                    MenuBarDockAppsGridView()
                        .scaleEffect(0.92)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.28))

            Divider().opacity(0.18)

            ScrollViewReader { proxy in
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 12) {
                        Color.clear.frame(height: 12)

                        ForEach(localModels.chatHistory) { msg in
                            imessageBubble(for: msg)
                                .id(msg.id.uuidString)
                        }

                        if localModels.isGenerating {
                            activeGeneratingBubble
                                .id("active-generating-bubble")
                        } else if !localModels.currentResponse.isEmpty && localModels.chatHistory.last?.content != localModels.currentResponse {
                            imessageBubble(for: ChatMessage(role: "assistant", content: localModels.currentResponse, model: localModels.selectedModelDisplayName))
                                .id("streaming-fallback")
                        }

                        Color.clear.frame(height: 6)
                            .id("bottom-anchor")
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                }
                .frame(maxHeight: isChatFullScreen ? (NSScreen.main?.visibleFrame.height ?? 700) - 200 : 440)
                .compositingGroup()
                .mask(
                    LinearGradient(
                        stops: [
                            .init(color: .clear, location: 0.0),
                            .init(color: .black.opacity(0.15), location: 0.08),
                            .init(color: .black.opacity(0.70), location: 0.20),
                            .init(color: .black, location: 0.35)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .onChange(of: localModels.chatHistory.count) { _, _ in
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                        proxy.scrollTo("bottom-anchor", anchor: .bottom)
                    }
                }
                .onChange(of: localModels.currentResponse) { _, _ in
                    proxy.scrollTo("bottom-anchor", anchor: .bottom)
                }
                .onAppear {
                    proxy.scrollTo("bottom-anchor", anchor: .bottom)
                }
            }
        }
        .frame(maxWidth: effectiveWidth)
        .background(
            ZStack {
                VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow, state: .active)
                Color.black.opacity(0.62)

                // Top Ambient Spotlight Wash
                RadialGradient(
                    colors: [
                        Color(red: 0.0, green: 0.85, blue: 1.0).opacity(0.18),
                        Color(red: 0.85, green: 0.40, blue: 1.0).opacity(0.10),
                        Color.clear
                    ],
                    center: .top,
                    startRadius: 5,
                    endRadius: 360
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.cyan.opacity(0.35), Color.purple.opacity(0.20), Color.white.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.85
                )
        )
    }

    // MARK: - Consolidated Web Browser Canvas ("switch from browser to chat in same window")
    private var consolidatedBrowserView: some View {
        VStack(spacing: 0) {
            // Drag handle at top
            HStack {
                Spacer()
                Capsule()
                    .fill(Color.white.opacity(0.35))
                    .frame(width: 36, height: 4)
                    .padding(.top, 6)
                    .padding(.bottom, 2)
                Spacer()
            }
            .contentShape(Rectangle())

            // ── CONSOLIDATED BROWSER PROSCENIUM HEADER ──
            HStack(spacing: 8) {
                // Live Stage Beacon & Title
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.cyan)
                        .frame(width: 7, height: 7)
                        .shadow(color: Color.cyan.opacity(0.85), radius: 3)

                    Text("🌐 GENIE WEB BROWSER")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                }

                Spacer()

                // Apps Tab (Viewer Box)
                Button(action: {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        currentMode = .apps
                    }
                    HapticFeedback.selection()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "square.grid.2x2.fill")
                        Text("Apps")
                    }
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3.5)
                    .background(Capsule().fill(Color.orange.opacity(0.40)))
                    .overlay(Capsule().stroke(Color.orange.opacity(0.65), lineWidth: 0.6))
                }
                .buttonStyle(.plain)
                .help("Switch to Applications in Viewer Box 🪟")

                // Settings Button moved to that bar
                Button(action: {
                    HapticFeedback.selection()
                    AppDelegate.shared?.showMenuBarSettingsDropdown(targetTab: .system)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "gearshape.fill")
                        Text("Settings")
                    }
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.90))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3.5)
                    .background(Capsule().fill(Color.purple.opacity(0.35)))
                    .overlay(Capsule().stroke(Color.purple.opacity(0.55), lineWidth: 0.6))
                }
                .buttonStyle(.plain)
                .help("Genie Preferences & Settings ⚙️")

                // Switch back down to Chat in same window
                Button(action: {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        currentMode = .chat
                    }
                    HapticFeedback.selection()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "message.fill")
                        Text("Back to Chat")
                    }
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3.5)
                    .background(Capsule().fill(Color.cyan.opacity(0.40)))
                    .overlay(Capsule().stroke(Color.cyan.opacity(0.65), lineWidth: 0.6))
                }
                .buttonStyle(.plain)
                .help("Switch down to Chat in same window 💬")

                // Close / Dismiss Browser (collapses to capsule)
                Button(action: {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        currentMode = .chat
                    }
                    HapticFeedback.tick()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.65))
                }
                .buttonStyle(.plain)
                .help("Close Browser Canvas")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.35))

            Divider().opacity(0.25)

            // Live WebKit Browser Canvas with Fading until Recalled to Front
            ZStack {
                MiniWebBrowserCanvasView()
                    .frame(height: isChatFullScreen ? (NSScreen.main?.visibleFrame.height ?? 700) - 180 : 440)
                    .opacity(isBrowserRecalledToFront ? 1.0 : 0.20)
                    .animation(.easeInOut(duration: 0.25), value: isBrowserRecalledToFront)

                if !isBrowserRecalledToFront {
                    Button(action: {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                            isBrowserRecalledToFront = true
                        }
                        showFeedback("Browser Recalled to Front 🌐")
                        HapticFeedback.selection()
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: "arrow.up.forward.app")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.cyan)
                            Text("Browser in Background")
                                .font(.system(size: 12.5, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text("Click to Recall to Front")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.cyan.opacity(0.90))
                        }
                        .padding(.horizontal, 22)
                        .padding(.vertical, 14)
                        .background(
                            VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow, state: .active)
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(Color.cyan.opacity(0.55), lineWidth: 1.0)
                        )
                        .shadow(color: Color.cyan.opacity(0.40), radius: 16)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: effectiveWidth)
        .background(
            ZStack {
                VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow, state: .active)
                Color.black.opacity(0.62)

                RadialGradient(
                    colors: [
                        Color(red: 0.0, green: 0.85, blue: 1.0).opacity(0.18),
                        Color(red: 0.0, green: 0.50, blue: 1.0).opacity(0.10),
                        Color.clear
                    ],
                    center: .top,
                    startRadius: 5,
                    endRadius: 360
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.cyan.opacity(0.45), Color.blue.opacity(0.25), Color.white.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.85
                )
        )
    }

    // MARK: - Active Generating Bubble
    private var activeGeneratingBubble: some View {
        HStack(alignment: .bottom, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 5) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(red: 0.0, green: 0.88, blue: 1.0))
                    Text(localModels.selectedModelDisplayName)
                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                    ProgressView().controlSize(.mini)
                }

                VStack(alignment: .leading, spacing: 6) {
                    if localModels.currentResponse.isEmpty {
                        HStack(spacing: 4) {
                            Text("Thinking...")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.7))
                            ProgressView().controlSize(.mini)
                        }
                    } else {
                        Text(localModels.currentResponse)
                            .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.white)
                            .textSelection(.enabled)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(
                    ZStack {
                        VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow, state: .active)
                        Color(red: 0.20, green: 0.21, blue: 0.25).opacity(0.88)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5)
                )
            }
            Spacer(minLength: 50)
        }
    }

    // MARK: - Authentic Apple iMessage Bubbles
    // MARK: - Authentic Apple iMessage Bubbles & Inline Theatre Cards
    @ViewBuilder
    private func imessageBubble(for msg: ChatMessage) -> some View {
        let isUser = (msg.role == "user")
        if msg.mediaType == "polaroid" {
            HStack {
                if isUser { Spacer(minLength: 40) }
                inlinePolaroidCard(for: msg)
                if !isUser { Spacer(minLength: 40) }
            }
        } else if msg.mediaType == "cue_note" {
            HStack {
                if isUser { Spacer(minLength: 40) }
                inlineCueNoteCard(for: msg)
                if !isUser { Spacer(minLength: 40) }
            }
        } else if msg.mediaType == "terminal" {
            HStack {
                if isUser { Spacer(minLength: 40) }
                inlineTerminalCard(for: msg)
                if !isUser { Spacer(minLength: 40) }
            }
        } else {
            standardBubble(for: msg, isUser: isUser)
        }
    }

    @ViewBuilder
    private func standardBubble(for msg: ChatMessage, isUser: Bool) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isUser { Spacer(minLength: 50) }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                // Header (for assistant)
                if !isUser {
                    HStack(spacing: 5) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color(red: 0.0, green: 0.88, blue: 1.0))
                        Text(msg.model.isEmpty ? localModels.selectedModelDisplayName : msg.model)
                            .font(.system(size: 10.5, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.85))
                        Text(formattedTime(msg.timestamp))
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.40))
                    }
                }

                // Bubble Body
                VStack(alignment: .leading, spacing: 6) {
                    Text(msg.content)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(.white)
                        .textSelection(.enabled)

                    // 1. Inline Slide Deck Presentation Card
                    if !isUser, let slides = localModels.extractPresentationSlides(from: msg.content) {
                        InlineSlidePresenterCardView(title: slides.title, content: slides.content)
                            .padding(.top, 4)
                    }

                    // 2. Inline Executive PDF Card
                    if !isUser, let pdf = localModels.extractPDFContent(from: msg.content) {
                        InlinePDFCardView(title: pdf.title, content: pdf.content)
                            .padding(.top, 4)
                    }

                    // 3. Inline Interactive Chart Card
                    if !isUser, let chart = localModels.extractChartSpec(from: msg.content) {
                        InlineChartCardView(type: chart.type, json: chart.json, title: chart.title)
                            .padding(.top, 4)
                    }

                    // 4. Inline Mermaid Diagram Card
                    if !isUser, let mermaid = localModels.extractMermaidDiagram(from: msg.content) {
                        InlineMermaidCardView(diagram: mermaid.diagram, title: mermaid.title)
                            .padding(.top, 4)
                    }

                    // Terminal commands if present
                    if !isUser && localModels.terminalAccessEnabled {
                        let terminalCommands = localModels.extractAllTerminalCommands(from: msg.content)
                        if !terminalCommands.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(terminalCommands, id: \.self) { cmd in
                                    TerminalToolCardView(command: cmd)
                                }
                            }
                            .padding(.top, 4)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 9)
                .background(
                    ZStack {
                        if isUser {
                            LinearGradient(
                                colors: [
                                    Color(red: 0.0, green: 0.52, blue: 1.0),
                                    Color(red: 0.04, green: 0.46, blue: 0.98)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        } else {
                            VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow, state: .active)
                            Color(red: 0.20, green: 0.21, blue: 0.25).opacity(0.88)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(
                            isUser ? Color.white.opacity(0.20) : Color.white.opacity(0.12),
                            lineWidth: 0.5
                        )
                )

                // Footer Actions & Timestamp
                HStack(spacing: 8) {
                    if isUser {
                        Text("Delivered • \(formattedTime(msg.timestamp))")
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.40))
                    }

                    // Send single message to Apple Messages
                    Button(action: {
                        sendToAppleMessages(text: msg.content)
                    }) {
                        HStack(spacing: 2) {
                            Image(systemName: "message.fill")
                            Text("Messages")
                        }
                        .font(.system(size: 8.5, weight: .medium))
                        .foregroundColor(.cyan.opacity(0.85))
                    }
                    .buttonStyle(.plain)
                    .help("Send to Apple Messages 💬")

                    if !isUser {
                        // 🖼️ Generate CSS Image Card
                        Button(action: {
                            HapticFeedback.selection()
                            if let url = AICssCardRenderer.shared.saveCardImageToDesktop(content: msg.content, model: msg.model.isEmpty ? localModels.selectedModelDisplayName : msg.model) {
                                showFeedback("Card Image Saved to Desktop & Clipboard! 🖼️")
                                NSWorkspace.shared.activateFileViewerSelecting([url])
                            }
                        }) {
                            HStack(spacing: 2.5) {
                                Image(systemName: "photo.on.rectangle.angled")
                                Text("Card Image")
                            }
                            .font(.system(size: 8.5, weight: .medium))
                            .foregroundColor(.orange.opacity(0.90))
                        }
                        .buttonStyle(.plain)
                        .help("Render AI Answer into Beautiful CSS Image Card (.png) & Copy to Clipboard 🖼️")

                        // 🌐 View Interactive CSS Card in Consolidated Browser
                        Button(action: {
                            HapticFeedback.selection()
                            let html = AICssCardRenderer.shared.wrapAnswerInCSS(content: msg.content, model: msg.model.isEmpty ? localModels.selectedModelDisplayName : msg.model)
                            MiniBrowserManager.shared.activeWebView?.loadHTMLString(html, baseURL: nil)
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                                currentMode = .search
                            }
                            showFeedback("Viewing in CSS Canvas 🌐")
                        }) {
                            HStack(spacing: 2.5) {
                                Image(systemName: "curlybraces")
                                Text("CSS")
                            }
                            .font(.system(size: 8.5, weight: .medium))
                            .foregroundColor(.cyan.opacity(0.90))
                        }
                        .buttonStyle(.plain)
                        .help("View formatted with modern glassmorphic CSS 🌐")
                    }

                    if !isUser {
                        // 1-Click Clipboard Copy with Checkmark Feedback
                        Button(action: {
                            let pb = NSPasteboard.general
                            pb.clearContents()
                            pb.setString(msg.content, forType: .string)
                            HapticFeedback.selection()
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                                copiedMessageId = msg.id
                            }
                            showFeedback("Answer Copied to Clipboard! 📋")
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                if copiedMessageId == msg.id {
                                    withAnimation { copiedMessageId = nil }
                                }
                            }
                        }) {
                            HStack(spacing: 3) {
                                Image(systemName: copiedMessageId == msg.id ? "checkmark.circle.fill" : "doc.on.doc")
                                    .font(.system(size: 8.5))
                                    .foregroundColor(copiedMessageId == msg.id ? .green : .white.opacity(0.85))
                                Text(copiedMessageId == msg.id ? "Copied!" : "Copy")
                                    .font(.system(size: 8.5, weight: .semibold))
                                    .foregroundColor(copiedMessageId == msg.id ? .green : .white.opacity(0.85))
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2.5)
                            .background(Capsule().fill(copiedMessageId == msg.id ? Color.green.opacity(0.25) : Color.white.opacity(0.12)))
                            .overlay(Capsule().stroke(copiedMessageId == msg.id ? Color.green.opacity(0.55) : Color.white.opacity(0.20), lineWidth: 0.5))
                        }
                        .buttonStyle(.plain)
                        .help("Copy AI answer directly to clipboard 📋")

                        // Speak Aloud Button
                        Button(action: {
                            if voiceEngine.isSpeaking {
                                voiceEngine.stop()
                            } else {
                                voiceEngine.speak(msg.content)
                            }
                            HapticFeedback.selection()
                        }) {
                            HStack(spacing: 3) {
                                Image(systemName: voiceEngine.isSpeaking ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                    .font(.system(size: 8.5))
                                    .foregroundColor(.purple.opacity(0.95))
                                Text("Speak")
                                    .font(.system(size: 8.5, weight: .semibold))
                                    .foregroundColor(.purple.opacity(0.95))
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2.5)
                            .background(Capsule().fill(Color.purple.opacity(0.20)))
                            .overlay(Capsule().stroke(Color.purple.opacity(0.45), lineWidth: 0.5))
                        }
                        .buttonStyle(.plain)
                        .help("Speak this response aloud using Genie's voice 🗣️")
                    } else {
                        // User message copy
                        Button(action: {
                            let pb = NSPasteboard.general
                            pb.clearContents()
                            pb.setString(msg.content, forType: .string)
                            HapticFeedback.selection()
                            showFeedback("Copied! 📋")
                        }) {
                            Image(systemName: "doc.on.doc")
                                .font(.system(size: 9))
                                .foregroundColor(.white.opacity(0.40))
                        }
                        .buttonStyle(.plain)
                        .help("Copy message")
                    }

                    // Delete
                    Button(action: {
                        localModels.deleteMessage(id: msg.id)
                        HapticFeedback.tick()
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 8.5))
                            .foregroundColor(.white.opacity(0.30))
                    }
                    .buttonStyle(.plain)
                    .help("Delete message")
                }
                .padding(.top, 1)
            }

            if !isUser { Spacer(minLength: 50) }
        }
    }

    // MARK: - 📸 Inline Polaroid Card in AI Theatre
    @ViewBuilder
    private func inlinePolaroidCard(for msg: ChatMessage) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Color.black.opacity(0.85)
                if let path = msg.mediaPath, let img = NSImage(contentsOfFile: path) {
                    Image(nsImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 220, height: 180)
                        .clipped()
                } else {
                    VStack(spacing: 6) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.orange)
                        Text("Polaroid Snapshot")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .frame(width: 220, height: 180)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

            Text(msg.content.isEmpty ? "Genie Snapshot 📸" : msg.content)
                .font(.custom("Bradley Hand", size: 14))
                .foregroundColor(.black.opacity(0.85))
                .frame(maxWidth: 220, alignment: .leading)
                .padding(.horizontal, 4)
                .padding(.bottom, 2)

            HStack {
                if let path = msg.mediaPath {
                    Button(action: {
                        NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
                    }) {
                        Label("Reveal", systemImage: "magnifyingglass")
                            .font(.system(size: 9.5, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                Spacer()
                Button(action: {
                    if let path = msg.mediaPath, let img = NSImage(contentsOfFile: path), let tiff = img.tiffRepresentation {
                        let pb = NSPasteboard.general
                        pb.clearContents()
                        pb.setData(tiff, forType: .tiff)
                        HapticFeedback.selection()
                        showFeedback("Copied Polaroid! 📋")
                    }
                }) {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.system(size: 9.5, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 4)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(white: 0.96))
                .shadow(color: Color.black.opacity(0.35), radius: 10, y: 5)
        )
    }

    // MARK: - 📝 Inline Cue Note Card
    @ViewBuilder
    private func inlineCueNoteCard(for msg: ChatMessage) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Circle().fill(Color.orange).frame(width: 7, height: 7)
                Text("QUICK NOTE")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.orange)
                Spacer()
                Text(formattedTime(msg.timestamp))
                    .font(.system(size: 8.5))
                    .foregroundColor(.secondary)
            }

            Text(msg.content)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(Color(red: 0.15, green: 0.15, blue: 0.15))
                .textSelection(.enabled)

            HStack {
                Spacer()
                Button(action: {
                    let pb = NSPasteboard.general
                    pb.clearContents()
                    pb.setString(msg.content, forType: .string)
                    HapticFeedback.selection()
                    showFeedback("Copied Note! 📋")
                }) {
                    Label("Copy Note", systemImage: "doc.on.doc")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(Color.black.opacity(0.6))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .frame(maxWidth: 360)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(red: 1.0, green: 0.98, blue: 0.88))
                .shadow(color: Color.black.opacity(0.20), radius: 6, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.orange.opacity(0.35), lineWidth: 1)
        )
    }

    // MARK: - 💻 Inline Terminal Tool Card
    @ViewBuilder
    private func inlineTerminalCard(for msg: ChatMessage) -> some View {
        TerminalToolCardView(command: msg.content)
            .frame(maxWidth: 420)
    }

    // MARK: - 6 Discrete Mode Buttons: Chat 💬 | Search 🌐 | Note 📄 | Terminal 💻 | Polaroid 📸 | Mirror 📱
    private var modeCapsuleButtons: some View {
        HStack(spacing: 6) {
            modeCapsulePill(mode: .chat)
            modeCapsulePill(mode: .search)
            modeCapsulePill(mode: .file)
            modeCapsulePill(mode: .terminal)
            modeCapsulePill(mode: .polaroid)
            modeCapsulePill(mode: .screenMirror)
            modeCapsulePill(mode: .vision)
        }
    }

    @ViewBuilder
    private func modeCapsulePill(mode: BarMode) -> some View {
        let isSelected = (currentMode == mode)
        Button(action: {
            HapticFeedback.selection()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                barModeRaw = mode.rawValue
            }
            if mode == .file {
                showFeedback("Command Center: Note Mode 📄")
                NotificationCenter.default.post(name: NSNotification.Name("NexusFocusGenieSearchBar"), object: nil)
            } else if mode == .terminal {
                NotificationCenter.default.post(name: NSNotification.Name("NexusFocusGenieSearchBar"), object: nil)
            } else if mode == .polaroid {
                executePolaroidCapture()
            } else if mode == .screenMirror {
                iPhoneMirrorManager.shared.startStreaming()
            } else if mode == .vision {
                executeVisionCapture()
            } else if mode == .chat {
                NotificationCenter.default.post(name: NSNotification.Name("NexusFocusGenieSearchBar"), object: nil)
            } else if mode == .search {
                NotificationCenter.default.post(name: NSNotification.Name("NexusFocusGenieSearchBar"), object: nil)
            }
        }) {
            ZStack {
                Circle()
                    .fill(isSelected ? mode.iconColor.opacity(0.24) : Color.white.opacity(0.06))
                    .frame(width: 28, height: 28)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                isSelected ? mode.iconColor.opacity(0.85) : Color.white.opacity(0.12),
                                lineWidth: isSelected ? 1.2 : 0.6
                            )
                    )

                Image(systemName: mode.icon)
                    .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? mode.iconColor : Color.white.opacity(0.55))
                    .scaleEffect(isSelected ? 1.08 : 1.0)
            }
        }
        .buttonStyle(.plain)
        .help(mode.helpText)
        .popover(isPresented: Binding(
            get: { mode == .chat && showSavedChatsDrawer },
            set: { if !$0 { showSavedChatsDrawer = false } }
        ), arrowEdge: .top) {
            savedChatsDrawerContent
        }
        .popover(isPresented: Binding(
            get: { mode == .polaroid && showPolaroidPreviewPopover },
            set: { if !$0 { showPolaroidPreviewPopover = false } }
        ), arrowEdge: .top) {
            polaroidPreviewPopoverContent
        }
        .popover(isPresented: Binding(
            get: { mode == .chat && showChatManagerDrawer },
            set: { if !$0 { showChatManagerDrawer = false } }
        ), arrowEdge: .top) {
            chatManagerDrawerContent
        }
        .popover(isPresented: Binding(
            get: { mode == .vision && showVisionPreviewPopover },
            set: { if !$0 { showVisionPreviewPopover = false } }
        ), arrowEdge: .top) {
            visionPreviewPopoverContent
        }
    }

    // MARK: - Editable Pop-up Note View ("Make note feel like a pop-up so it's editable")
    private var noteEditorPopoverContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "doc.text.fill")
                        .foregroundColor(Color(red: 0.40, green: 0.90, blue: 0.65))
                    Text("Quick Note")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                Spacer()

                HStack(spacing: 6) {
                    ForEach(["Yellow", "Mint", "Sky", "Lavender", "Coral", "Dark"], id: \.self) { cName in
                        Circle()
                            .fill(stickyColor(for: cName))
                            .frame(width: 14, height: 14)
                            .overlay(
                                Circle()
                                    .strokeBorder(Color.white, lineWidth: noteSelectedColor == cName ? 2 : 0)
                            )
                            .onTapGesture {
                                noteSelectedColor = cName
                                HapticFeedback.selection()
                            }
                    }
                }

                Button(action: {
                    showNoteEditorPopover = false
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.white.opacity(0.5))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.top, 10)

            Divider().opacity(0.2)

            TextEditor(text: $noteText)
                .font(.system(size: 13, weight: .regular, design: .rounded))
                .foregroundColor(.white)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5)
                        )
                )
                .frame(minHeight: 120, maxHeight: 180)
                .padding(.horizontal, 12)

            // ── Output Format Selection Boxes ──
            VStack(alignment: .leading, spacing: 6) {
                Text("OUTPUT FORMAT")
                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(NoteOutputDestination.allCases) { dest in
                            let isSelected = (selectedOutputDestination == dest)
                            Button(action: {
                                selectedOutputDestination = dest
                                HapticFeedback.selection()
                            }) {
                                HStack(spacing: 4.5) {
                                    Image(systemName: dest.icon)
                                        .font(.system(size: 10.5))
                                    Text(dest.shortLabel)
                                        .font(.system(size: 11, weight: isSelected ? .bold : .medium, design: .rounded))
                                }
                                .padding(.horizontal, 9)
                                .padding(.vertical, 5)
                                .background(
                                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                                        .fill(isSelected ? Color.cyan.opacity(0.25) : Color.white.opacity(0.06))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                                        .strokeBorder(isSelected ? Color.cyan.opacity(0.85) : Color.white.opacity(0.12), lineWidth: isSelected ? 1.2 : 0.6)
                                )
                                .foregroundColor(isSelected ? .white : .white.opacity(0.75))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Destination Folder Path Display & Picker
                HStack(spacing: 6) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.yellow.opacity(0.85))

                    Text(currentDestinationFolderURL.path)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.white.opacity(0.65))
                        .lineLimit(1)
                        .truncationMode(.middle)

                    Spacer()

                    Button("Choose Folder...") {
                        chooseCustomDestinationFolder()
                    }
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(.cyan)
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.black.opacity(0.25))
                )
            }
            .padding(.horizontal, 12)

            HStack(spacing: 8) {
                let words = noteText.split { $0.isWhitespace || $0.isNewline }.count
                Text("\(words) words • \(noteText.count) chars")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))

                Spacer()

                Button(action: {
                    let content = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
                    DesktopNotePrinter.shared.openStickiesApp(content: content.isEmpty ? nil : content)
                    HapticFeedback.selection()
                    showFeedback("Opened in Apple Stickies 📝")
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "note.text")
                        Text("Stickies App")
                    }
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.orange.opacity(0.85)))
                }
                .buttonStyle(.plain)
                .help("Create Note in macOS Native Stickies.app 📝")

                Button(action: {
                    guard !noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
                    sendToAppleMessages(text: noteText)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "message.fill")
                        Text("Messages")
                    }
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color(red: 0.0, green: 0.48, blue: 1.0).opacity(0.85)))
                }
                .buttonStyle(.plain)
                .help("Send Note to Apple Messages 💬")

                Button(action: {
                    executeFileNoteAndExit()
                    showNoteEditorPopover = false
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.doc.fill")
                        Text("Save")
                    }
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.black)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color(red: 0.40, green: 0.90, blue: 0.65)))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 10)
        }
        .frame(width: 420)
        .background(
            ZStack {
                VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow, state: .active)
                Color.black.opacity(0.78)
            }
        )
    }

    private func stickyColor(for name: String) -> Color {
        switch name {
        case "Yellow": return Color(red: 1.0, green: 0.85, blue: 0.35)
        case "Mint": return Color(red: 0.40, green: 0.90, blue: 0.65)
        case "Sky": return Color(red: 0.35, green: 0.75, blue: 1.0)
        case "Lavender": return Color(red: 0.75, green: 0.55, blue: 0.95)
        case "Coral": return Color(red: 1.0, green: 0.50, blue: 0.45)
        default: return Color(red: 0.25, green: 0.26, blue: 0.30)
        }
    }

    // MARK: - Pop-up Terminal Console
    private var terminalPopoverContent: some View {
        VStack(spacing: 0) {
            EmbeddedTerminalCanvasView()
        }
        .frame(width: 620, height: 360)
        .background(
            ZStack {
                VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow, state: .active)
                Color.black.opacity(0.85)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.75)
        )
    }

    private var chatManagerDrawerContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.cyan)

                VStack(alignment: .leading, spacing: 1) {
                    Text("Genie Chat Manager")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("\(localModels.chatHistory.count) Messages in Session")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: { showChatManagerDrawer = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            Divider().opacity(0.3)

            // Top Quick Action Buttons
            HStack(spacing: 8) {
                // New Chat
                Button(action: {
                    localModels.clearChatHistory()
                    HapticFeedback.selection()
                    showFeedback("New Chat Started! ✨")
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.bubble.fill")
                        Text("New Chat")
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.cyan.opacity(0.25)))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.cyan.opacity(0.45), lineWidth: 0.75))
                }
                .buttonStyle(.plain)

                // Clear All
                Button(action: {
                    localModels.clearChatHistory()
                    HapticFeedback.tick()
                    showFeedback("Chat History Cleared 🗑️")
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "trash.fill")
                        Text("Clear")
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.red.opacity(0.9))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.red.opacity(0.12)))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.red.opacity(0.3), lineWidth: 0.75))
                }
                .buttonStyle(.plain)

                // Copy Full Transcript
                Button(action: {
                    copyFullTranscript()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.doc.fill")
                        Text("Copy All")
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.10)))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.2), lineWidth: 0.75))
                }
                .buttonStyle(.plain)

                // Export to Desktop (.md)
                Button(action: {
                    exportChatTranscript()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.up.fill")
                        Text("Export")
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.10)))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.2), lineWidth: 0.75))
                }
                .buttonStyle(.plain)
            }

            Divider().opacity(0.2)

            // Scrollable Timeline of Past Turns
            Text("Conversation History")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.7))

            if localModels.chatHistory.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No messages in current session.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 80)
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(localModels.chatHistory) { msg in
                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: msg.role == "user" ? "person.circle.fill" : "sparkles")
                                    .font(.system(size: 11))
                                    .foregroundColor(msg.role == "user" ? .cyan : .purple)
                                    .padding(.top, 2)

                                VStack(alignment: .leading, spacing: 2) {
                                    HStack {
                                        Text(msg.role == "user" ? "You" : (msg.model.isEmpty ? "Genie" : msg.model))
                                            .font(.system(size: 10.5, weight: .bold))
                                            .foregroundColor(.white)
                                        Spacer()
                                        Text(formattedTime(msg.timestamp))
                                            .font(.system(size: 9))
                                            .foregroundColor(.secondary)
                                    }

                                    Text(msg.content)
                                        .font(.system(size: 11))
                                        .foregroundColor(.white.opacity(0.85))
                                        .lineLimit(2)
                                }

                                Button(action: {
                                    localModels.deleteMessage(id: msg.id)
                                    HapticFeedback.tick()
                                }) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 9))
                                        .foregroundColor(.secondary.opacity(0.6))
                                }
                                .buttonStyle(.plain)
                                .help("Delete this message")
                            }
                            .padding(8)
                            .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.06)))
                        }
                    }
                    .padding(.trailing, 2)
                }
                .frame(maxHeight: 180)
            }

            Divider().opacity(0.2)

            // Bottom Settings Controls
            VStack(alignment: .leading, spacing: 6) {
                // Search Bar Placement
                HStack {
                    Image(systemName: "dock.rectangle")
                        .foregroundColor(.cyan)
                    Text("Search Bar Placement")
                        .font(.system(size: 11, weight: .medium))
                    Spacer()
                    Picker("", selection: $searchBarPlacement) {
                        Text("Meet in Middle ⚖️").tag("Meet in Middle (Top Chat, Bottom Apps) ⚖️")
                        Text("Bottom Above Dock ⬇️").tag("Bottom Above Dock ⬇️")
                        Text("Top Middle Pop-Down ⬆️").tag("Top Middle Pop-Down ⬆️")
                        Text("Centered Dynamic 🎯").tag("Centered Dynamic 🎯")
                    }
                    .pickerStyle(.menu)
                    .frame(width: 170)
                }

                if searchBarPlacement == "Meet in Middle (Top Chat, Bottom Apps) ⚖️" {
                    HStack {
                        Image(systemName: "slider.horizontal.below.rectangle")
                            .foregroundColor(.cyan)
                        Text("Middle Split Ratio")
                            .font(.system(size: 11, weight: .medium))
                        Spacer()
                        Text("\(Int(middleSplitRatio * 100))% / \(100 - Int(middleSplitRatio * 100))%")
                            .font(.system(size: 10, weight: .bold).monospacedDigit())
                            .foregroundColor(.white.opacity(0.8))
                        Slider(value: $middleSplitRatio, in: 0.30...0.70, step: 0.02)
                            .frame(width: 90)
                    }
                }

                // Emotion Window Toggle
                HStack {
                    Image(systemName: "sparkles.tv")
                        .foregroundColor(.purple)
                    Text("Emotion & Graphics Window")
                        .font(.system(size: 11, weight: .medium))
                    Spacer()
                    Toggle("", isOn: $showEmotionPlayer)
                        .toggleStyle(.switch)
                        .labelsHidden()
                }

                // Local Models Engine & Shutoff Control
                HStack {
                    Image(systemName: "desktopcomputer")
                        .foregroundColor(localModels.localModelsEnabled ? .teal : .secondary)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Local Models Engine")
                            .font(.system(size: 11, weight: .medium))
                        Text(localModels.localModelsEnabled ? (localModels.isConnectedToLocalEngine ? "Running 🟢" : "Enabled 🟡") : "Shut Off ⏻")
                            .font(.system(size: 9))
                            .foregroundColor(localModels.localModelsEnabled ? .green : .secondary)
                    }
                    Spacer()
                    if localModels.localModelsEnabled {
                        Button(action: {
                            localModels.shutoffLocalModels()
                            HapticFeedback.heavy()
                            showFeedback("Local Models Shut Off ⏻")
                        }) {
                            Text("Shut Off ⏻")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.red.opacity(0.9))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color.red.opacity(0.15)))
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button(action: {
                            localModels.enableLocalModels()
                            HapticFeedback.selection()
                            showFeedback("Local Models Enabled ⚡️")
                        }) {
                            Text("Turn On ⚡️")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.cyan)
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color.cyan.opacity(0.18)))
                        }
                        .buttonStyle(.plain)
                    }
                }

                // Terminal Tool Execution Controls
                HStack {
                    Image(systemName: "terminal.fill")
                        .foregroundColor(localModels.terminalAccessEnabled ? .green : .secondary)
                    VStack(alignment: .leading, spacing: 1) {
                        Text("Terminal Tool Access")
                            .font(.system(size: 11, weight: .medium))
                        Text("Allows AI to run commands & inspect system")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Toggle("", isOn: Binding(
                        get: { localModels.terminalAccessEnabled },
                        set: { localModels.terminalAccessEnabled = $0 }
                    ))
                    .toggleStyle(.switch)
                    .labelsHidden()
                }

                if localModels.terminalAccessEnabled {
                    HStack {
                        Image(systemName: "bolt.badge.automatic.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.yellow)
                        Text("Auto-Execute Terminal Tools")
                            .font(.system(size: 10.5))
                            .foregroundColor(.white.opacity(0.85))
                        Spacer()
                        Toggle("", isOn: Binding(
                            get: { localModels.terminalAutoExecute },
                            set: { localModels.terminalAutoExecute = $0 }
                        ))
                        .toggleStyle(.switch)
                        .labelsHidden()
                    }
                    .padding(.leading, 8)
                }

                // Active Key Indicator
                HStack {
                    Image(systemName: "key.fill")
                        .foregroundColor(localModels.hasGeminiKey ? .green : .orange)
                    Text("Gemini Key: \(localModels.hasGeminiKey ? "Active (AQ...)" : "Missing")")
                        .font(.system(size: 10.5))
                        .foregroundColor(.secondary)
                    Spacer()
                    Button("Manage Keys...") {
                        showChatSettingsPopover = true
                    }
                    .font(.system(size: 10, weight: .medium))
                }
            }
        }
        .padding(14)
        .frame(width: 370)
    }

    // MARK: - Utility Functions
    private func formattedTime(_ date: Date) -> String {
        let df = DateFormatter()
        df.timeStyle = .short
        return df.string(from: date)
    }

    private func copyFullTranscript() {
        var transcript = ""
        for msg in localModels.chatHistory {
            let sender = (msg.role == "user") ? "User" : "Genie (\(msg.model))"
            transcript += "[\(sender) - \(formattedTime(msg.timestamp))]:\n\(msg.content)\n\n"
        }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(transcript, forType: .string)
        HapticFeedback.selection()
        showFeedback("Full Transcript Copied! 📋")
    }

    private func exportChatTranscript() {
        var md = "# Genie AI Chat Transcript\n\n"
        md += "**Exported**: \(Date().formatted())\n"
        md += "**Active Model**: \(localModels.selectedModelDisplayName)\n\n---\n\n"
        for msg in localModels.chatHistory {
            let sender = (msg.role == "user") ? "👤 User" : "🧞‍♂️ Genie (\(msg.model))"
            let time = formattedTime(msg.timestamp)
            md += "### \(sender) — *\(time)*\n\n\(msg.content)\n\n---\n\n"
        }
        let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSHomeDirectory() + "/Desktop")
        let filename = "GenieChat_\(Int(Date().timeIntervalSince1970)).md"
        let fileURL = desktopURL.appendingPathComponent(filename)
        do {
            try md.write(to: fileURL, atomically: true, encoding: .utf8)
            showFeedback("Exported to Desktop: \(filename) 📄")
        } catch {
            showFeedback("Export failed: \(error.localizedDescription)")
        }
    }

    private func exportChatToNote() {
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
            showFeedback("Saved & opened note: \(fileURL.lastPathComponent) 📄")
        }
    }

    // MARK: - 👁️ Optical Screen Vision Execution
    private func executeVisionCapture() {
        let query = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        pulseBorder()
        HapticFeedback.selection()

        Task {
            let _ = await visionEngine.scanActiveScreenAndRecognize()

            await MainActor.run {
                if !query.isEmpty {
                    showFeedback("Querying AI with Screen Vision... 👁️")
                    visionEngine.askAIWithVision(query: query)
                    barModeRaw = "chat"
                    withAnimation(.easeOut(duration: 0.15)) {
                        noteText = ""
                    }
                } else {
                    showFeedback("Screen Scanned! 👁️ (\(visionEngine.recognizedWordCount) words)")
                    self.showVisionPreviewPopover = true
                }
            }
        }
    }

    // MARK: - 👁️ Optical Vision Preview Popover Content
    private var visionPreviewPopoverContent: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "viewfinder.circle.fill")
                        .foregroundColor(Color(red: 0.72, green: 0.45, blue: 1.0))
                    Text("Genie Optical Screen Vision")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                Spacer()

                if visionEngine.isAnalyzing {
                    ProgressView().controlSize(.small)
                } else {
                    HStack(spacing: 4) {
                        Text("\(visionEngine.recognizedWordCount) words")
                            .font(.system(size: 10, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.65))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.white.opacity(0.1)))
                    }
                }

                Button(action: { showVisionPreviewPopover = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            if let img = visionEngine.lastCapturedImage {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 340, maxHeight: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.8)
                    )
            }

            // Extracted OCR Text Box
            ScrollView(.vertical, showsIndicators: true) {
                if visionEngine.recognizedText.isEmpty {
                    Text(visionEngine.isAnalyzing ? "Analyzing display via Apple Silicon Neural Engine..." : "No legible text detected on screen.")
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                } else {
                    Text(visionEngine.recognizedText)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.white.opacity(0.92))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                }
            }
            .frame(width: 340, height: 130)
            .background(Color.black.opacity(0.45))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.8)
            )

            // Action Buttons
            HStack(spacing: 8) {
                Button(action: {
                    visionEngine.copyRecognizedText()
                    showFeedback("Copied Text to Clipboard! 📋")
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.doc.fill")
                        Text("Copy Text")
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color(red: 0.72, green: 0.45, blue: 1.0)))
                }
                .buttonStyle(.plain)
                .disabled(visionEngine.recognizedText.isEmpty)

                Button(action: {
                    visionEngine.saveAsMarkdownNote()
                    showFeedback("Saved as Note! 📄")
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.text.fill")
                        Text("Save Note")
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.white.opacity(0.12)))
                }
                .buttonStyle(.plain)
                .disabled(visionEngine.recognizedText.isEmpty)

                Button(action: {
                    showVisionPreviewPopover = false
                    barModeRaw = "chat"
                    visionEngine.askAIWithVision(query: "Analyze this screen content and explain what is important.")
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                        Text("Ask AI")
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.white.opacity(0.12)))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .frame(width: 368)
        .background(
            ZStack {
                VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow, state: .active)
                Color.black.opacity(0.55)
            }
        )
    }

    // MARK: - 📸 Polaroid Capture & Generation
    private func executePolaroidCapture() {
        HapticFeedback.selection()
        showFeedback("Capturing Polaroid Photo 📸...")

        Task {
            // Attempt camera photo capture, falling back gracefully to screen capture if camera denied
            var photo = await CameraCaptureService.shared.captureCameraPhoto()
            if photo == nil {
                photo = await CameraCaptureService.shared.captureScreenFallback()
            }

            let memo = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
            let effectiveText = memo.isEmpty ? "Polaroid Snapshot" : memo

            // Generate authentic Polaroid 600 card & save to Desktop
            if let savedURL = DesktopNotePrinter.shared.savePolaroidToDesktop(
                content: effectiveText,
                photoImage: photo,
                fontName: "Bradley Hand",
                themeName: "Apple Glass"
            ) {
                let cardImage = DesktopNotePrinter.shared.generatePolaroidImage(
                    content: effectiveText,
                    photoImage: photo,
                    fontName: "Bradley Hand",
                    themeName: "Apple Glass"
                )

                await MainActor.run {
                    self.polaroidSavedURL = savedURL
                    self.polaroidPreviewImage = cardImage
                    self.showPolaroidPreviewPopover = true

                    // Copy card to clipboard for immediate pasting into Messages / Discord / Slack
                    let pasteboard = NSPasteboard.general
                    pasteboard.clearContents()
                    if let tiff = cardImage.tiffRepresentation {
                        pasteboard.setData(tiff, forType: .tiff)
                    }

                    // Append inline Polaroid Card to AI Theatre chat stream
                    self.localModels.chatHistory.append(
                        ChatMessage(
                            role: "user",
                            content: effectiveText,
                            model: "Polaroid 600",
                            mediaType: "polaroid",
                            mediaPath: savedURL.path
                        )
                    )
                    self.localModels.saveChatHistory()

                    HapticFeedback.heavy()
                    showFeedback("Polaroid Saved & Copied! 📸")
                    noteText = ""
                }
            } else {
                await MainActor.run {
                    showFeedback("Capture failed — check permissions")
                }
            }
        }
    }

    // MARK: - 📸 Polaroid Preview Popover Content
    private var polaroidPreviewPopoverContent: some View {
        VStack(spacing: 12) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "camera.fill")
                        .foregroundColor(.orange)
                    Text("GENIE POLAROID 600 • HIGH FIDELITY")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
                Spacer()
                Button(action: { showPolaroidPreviewPopover = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            if let img = polaroidPreviewImage {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 320, maxHeight: 380)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .shadow(color: Color.black.opacity(0.4), radius: 10, y: 5)
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.black.opacity(0.5))
                    .frame(width: 280, height: 340)
                    .overlay(ProgressView())
            }

            HStack(spacing: 8) {
                Button(action: {
                    if let img = polaroidPreviewImage, let tiff = img.tiffRepresentation {
                        let pb = NSPasteboard.general
                        pb.clearContents()
                        pb.setData(tiff, forType: .tiff)
                        HapticFeedback.selection()
                        showFeedback("Copied to Clipboard! 📋")
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.doc.fill")
                        Text("Copy Card")
                    }
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.orange))
                }
                .buttonStyle(.plain)

                if let url = polaroidSavedURL {
                    Button(action: {
                        NSWorkspace.shared.activateFileViewerSelecting([url])
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.right.square")
                            Text("Reveal File")
                        }
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color.white.opacity(0.12)))
                    }
                    .buttonStyle(.plain)
                }

                Button(action: {
                    executePolaroidCapture()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "camera")
                        Text("Retake")
                    }
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.white.opacity(0.08)))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(14)
        .frame(width: 350)
        .background(
            ZStack {
                VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow, state: .active)
                Color(red: 0.10, green: 0.10, blue: 0.13).opacity(0.92)
            }
        )
    }

    // MARK: - 📚 Saved Chats Drawer Content
    private var savedChatsDrawerContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "books.vertical.fill")
                        .foregroundColor(.cyan)
                    Text("Saved Chats (\(localModels.savedSessions.count))")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                Spacer()
                Button(action: {
                    localModels.startNewChat()
                    showSavedChatsDrawer = false
                    HapticFeedback.selection()
                    showFeedback("New Chat Started! ✨")
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "plus.circle.fill")
                        Text("New Chat")
                    }
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundColor(.cyan)
                }
                .buttonStyle(.plain)
            }

            Divider().opacity(0.25)

            if localModels.savedSessions.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 24))
                        .foregroundColor(.secondary)
                    Text("No past chats saved yet")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                ScrollView {
                    VStack(spacing: 6) {
                        ForEach(localModels.savedSessions) { session in
                            let isCurrent = (session.id == localModels.currentSessionId)
                            HStack(spacing: 8) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(session.title)
                                        .font(.system(size: 11, weight: isCurrent ? .bold : .medium))
                                        .foregroundColor(isCurrent ? .cyan : .white)
                                        .lineLimit(1)
                                    HStack(spacing: 4) {
                                        Text(session.model)
                                            .font(.system(size: 9, design: .monospaced))
                                            .foregroundColor(.white.opacity(0.55))
                                        Text("•")
                                            .foregroundColor(.white.opacity(0.3))
                                        Text("\(session.messages.count) msgs")
                                            .font(.system(size: 9))
                                            .foregroundColor(.white.opacity(0.45))
                                    }
                                }
                                Spacer()

                                Button(action: {
                                    localModels.loadSession(session)
                                    showSavedChatsDrawer = false
                                    HapticFeedback.selection()
                                    showFeedback("Loaded: \(session.title)")
                                }) {
                                    Text(isCurrent ? "Active" : "Open")
                                        .font(.system(size: 9.5, weight: .semibold))
                                        .foregroundColor(isCurrent ? .black : .white)
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 3)
                                        .background(Capsule().fill(isCurrent ? Color.cyan : Color.white.opacity(0.12)))
                                }
                                .buttonStyle(.plain)

                                Button(action: {
                                    localModels.deleteSession(id: session.id)
                                    HapticFeedback.tick()
                                }) {
                                    Image(systemName: "trash")
                                        .font(.system(size: 9.5))
                                        .foregroundColor(.red.opacity(0.75))
                                        .padding(4)
                                }
                                .buttonStyle(.plain)
                                .help("Delete Chat Session")
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 7)
                            .background(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .fill(isCurrent ? Color.cyan.opacity(0.12) : Color.white.opacity(0.05))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .stroke(isCurrent ? Color.cyan.opacity(0.4) : Color.clear, lineWidth: 0.75)
                            )
                        }
                    }
                    .padding(.vertical, 2)
                }
                .frame(maxHeight: 280)
            }
        }
        .padding(14)
        .frame(width: 330)
        .background(
            ZStack {
                VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow, state: .active)
                Color(red: 0.10, green: 0.11, blue: 0.14).opacity(0.92)
            }
        )
    }

    // MARK: - 💡 Hidable Cheat Sheet View
    private var cheatSheetView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: "sparkles")
                    .font(.system(size: 9.5, weight: .bold))
                    .foregroundColor(.yellow)
                Text(cheatSheetTitle)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
                Spacer()
                Text("Click any chip to autofill")
                    .font(.system(size: 8.5))
                    .foregroundColor(.white.opacity(0.45))
            }
            .padding(.horizontal, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(currentCheatSheetItems, id: \.self) { item in
                        Button(action: {
                            noteText = item
                            HapticFeedback.selection()
                            NotificationCenter.default.post(name: NSNotification.Name("NexusFocusGenieSearchBar"), object: nil)
                        }) {
                            Text(item)
                                .font(.system(size: 10, weight: .medium, design: currentMode == .terminal ? .monospaced : .default))
                                .foregroundColor(.white.opacity(0.90))
                                .padding(.horizontal, 9)
                                .padding(.vertical, 5)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(0.08))
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.18), lineWidth: 0.5)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 2)
            }
        }
        .padding(8)
        .frame(maxWidth: 640)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(red: 0.08, green: 0.09, blue: 0.12).opacity(0.85))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.10), lineWidth: 0.5)
        )
    }

    private var cheatSheetTitle: String {
        switch currentMode {
        case .chat: return "AI Prompts & Queries"
        case .search: return "Instant Search Shortcuts"
        case .apps: return "Quick Application Commands 🪟"
        case .file: return "Note Starters & Templates"
        case .terminal: return "Common Terminal Commands"
        case .polaroid: return "Polaroid Snapshot Captions"
        case .screenMirror: return "iPhone Screen Actions 📱"
        case .vision: return "Optical Vision & Screen Actions 👁️"
        case .settings: return "Genie Settings & Preferences ⚙️"
        }
    }

    private var currentCheatSheetItems: [String] {
        switch currentMode {
        case .chat:
            return [
                "Explain how this code works step-by-step",
                "Write a zsh shell script for macOS",
                "Summarize key differences between Gemini and Claude",
                "Help me debug an error in my project",
                "Give me a quick productivity tip for macOS"
            ]
        case .search:
            return [
                "!g Golden Gate Bridge weather",
                "!yt Swift programming tutorial",
                "!gh apple swift-syntax",
                "!w Golden Gate National Recreation Area",
                "latest tech news today",
                "macOS Sequoia features"
            ]
        case .apps:
            return [
                "Safari",
                "Xcode",
                "Terminal",
                "Finder",
                "System Settings"
            ]
        case .file:
            return [
                "# Meeting Notes\n- Attendees:\n- Agenda:\n- Action items:",
                "# Daily Standup\n- Yesterday:\n- Today:\n- Blockers:",
                "# Ideas & Sketches\n- Concept 1:\n- Concept 2:",
                "# Quick Reference\n- Server:\n- Port:\n- Token:"
            ]
        case .terminal:
            return [
                "git status",
                "ls -la",
                "top -l 1 | head -n 15",
                "brew update && brew outdated",
                "python3 --version",
                "df -h",
                "ping -c 3 8.8.8.8"
            ]
        case .polaroid:
            return [
                "San Francisco Desk Setup ✨",
                "Golden Gate Studio • Working Session",
                "Genie Polaroid Memory 📸",
                "Deep Focus Work Mode 💻",
                "California Sunset Glow 🌅"
            ]
        case .screenMirror:
            return [
                "Summarize what is on my iPhone screen",
                "Extract all phone numbers and text from screen",
                "Translate any foreign text on my iPhone screen",
                "Copy this entire iPhone screen text to clipboard",
                "Save high-resolution snapshot to Polaroid memo"
            ]
        case .vision:
            return [
                "Summarize and explain what is on my screen ✨",
                "Extract code snippet and suggest optimizations 🚀",
                "Explain the error message currently visible 🐞",
                "Translate visible text into English 🌐",
                "Copy all recognized screen text to clipboard 📋"
            ]
        case .settings:
            return [
                "Open Intelligence & Models Settings",
                "Customize Menu Bar & Liquid Glass",
                "Configure Mini Dock & Live Battery",
                "Select Voice & Dialect Preferences",
                "Adjust Window Pinning & Physics"
            ]
        }
    }

    // MARK: - 💬 Export Full Chat to Apple Notes

    private func saveFullChatToAppleNotes() {
        guard !localModels.chatHistory.isEmpty else {
            showFeedback("Chat history is empty!")
            return
        }
        HapticFeedback.selection()
        showFeedback("Saving to Apple Notes 📝...")
        localModels.saveChatToAppleNotes()
    }
}

// MARK: - Interactive Terminal Tool Runner Card
struct TerminalToolCardView: View {
    let command: String
    @State private var isExecuting: Bool = false
    @State private var output: String? = nil
    @State private var exitCode: Int32? = nil
    @State private var showCopied: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header bar
            HStack(spacing: 6) {
                HStack(spacing: 4) {
                    Circle().fill(Color.red.opacity(0.85)).frame(width: 7, height: 7)
                    Circle().fill(Color.yellow.opacity(0.85)).frame(width: 7, height: 7)
                    Circle().fill(Color.green.opacity(0.85)).frame(width: 7, height: 7)
                }

                Image(systemName: "terminal.fill")
                    .font(.system(size: 9.5, weight: .bold))
                    .foregroundColor(.green)

                Text("Terminal Tool")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.9))

                Spacer()

                if let code = exitCode {
                    Text(code == 0 ? "Exit 0 ✓" : "Exit \(code) ⚠️")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(code == 0 ? .green : .red)
                }

                // Copy Command
                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(command, forType: .string)
                    HapticFeedback.selection()
                    showCopied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        showCopied = false
                    }
                }) {
                    Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 9))
                        .foregroundColor(showCopied ? .green : .white.opacity(0.6))
                }
                .buttonStyle(.plain)
                .help("Copy command")

                // Open in Terminal.app
                Button(action: {
                    LocalModelManager.shared.openInTerminalApp(command: command)
                    HapticFeedback.selection()
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.up.forward.app")
                        Text("Terminal.app")
                    }
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Color.cyan.opacity(0.12)))
                }
                .buttonStyle(.plain)
                .help("Open and run in macOS Terminal.app")

                // Run Live Button
                Button(action: {
                    runCommand()
                }) {
                    HStack(spacing: 3) {
                        if isExecuting {
                            ProgressView()
                                .controlSize(.mini)
                        } else {
                            Image(systemName: "play.fill")
                        }
                        Text(isExecuting ? "Running..." : "Run ⚡️")
                    }
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.green))
                }
                .buttonStyle(.plain)
                .disabled(isExecuting)
            }

            // Command display
            Text("$ \(command)")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(.green.opacity(0.95))
                .textSelection(.enabled)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.black.opacity(0.55)))

            // Live execution output (if run)
            if let out = output {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Execution Output:")
                        .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                        .foregroundColor(.secondary)
                    ScrollView {
                        Text(out.isEmpty ? "(Process finished with no output)" : out)
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.white.opacity(0.9))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 120)
                }
                .padding(6)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.black.opacity(0.70)))
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(red: 0.08, green: 0.09, blue: 0.12).opacity(0.92))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.green.opacity(0.35), lineWidth: 0.75)
        )
    }

    private func runCommand() {
        isExecuting = true
        HapticFeedback.selection()
        Task {
            let res = await LocalModelManager.shared.executeTerminalCommand(command)
            await MainActor.run {
                self.output = res.output
                self.exitCode = res.exitCode
                self.isExecuting = false
                if res.exitCode == 0 {
                    HapticFeedback.selection()
                } else {
                    HapticFeedback.heavy()
                }
            }
        }
    }
}
