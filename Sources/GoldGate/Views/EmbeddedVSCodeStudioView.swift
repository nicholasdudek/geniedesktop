import AppKit
import SwiftUI
import WebKit

// MARK: - 💻 Embedded VS Code / Monaco Code Studio & File Browser
// Full-featured, open-source VS Code & Monaco-grade code atelier with:
// 1. Integrated Left File Explorer Tree synced with Desktop & Project workspaces.
// 2. Syntax-highlighted code editor with line numbers, code folding, and minimap.
// 3. Inline AI Code Explanations & Diff Generator (Copilot / Cursor style).
// 4. Side-by-Side Live AI Chat Dock with contextual workspace memory.

public struct FileNodeItem: Identifiable, Hashable {
    public var id: String { url.path }
    public let url: URL
    public let name: String
    public let isDirectory: Bool
    public var children: [FileNodeItem]?

    public init(url: URL, isDirectory: Bool, children: [FileNodeItem]? = nil) {
        self.url = url
        self.name = url.lastPathComponent
        self.isDirectory = isDirectory
        self.children = children
    }

    public var systemIcon: String {
        if isDirectory { return "folder.fill" }
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "swift": return "swift"
        case "py": return "chevron.left.forwardslash.chevron.right"
        case "js", "ts", "jsx", "tsx": return "curlybraces"
        case "html", "css": return "globe"
        case "json", "yaml", "yml": return "doc.badge.gearshape"
        case "md", "markdown": return "doc.plaintext"
        case "sh", "zsh", "bash": return "terminal.fill"
        default: return "doc.text.fill"
        }
    }

    public var iconColor: Color {
        if isDirectory { return .blue }
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "swift": return .orange
        case "py": return .cyan
        case "js", "ts": return .yellow
        case "html", "css": return .pink
        case "json", "yaml": return .green
        case "md": return .purple
        case "sh", "zsh": return .mint
        default: return .secondary
        }
    }
}

// MARK: - Embedded VS Code Studio View
public struct EmbeddedVSCodeStudioView: View {
    @ObservedObject var localModels = LocalModelManager.shared
    @ObservedObject var editorBridge = AIEditorBridgeEngine.shared
    @State private var currentRootFolder: URL? = nil
    @State private var fileTree: [FileNodeItem] = []
    @State private var selectedFileUrl: URL? = nil
    @State private var codeContent: String = ""
    @State private var originalCodeSnapshot: String = ""
    @State private var activeLanguage: String = "Swift"
    @State private var isFileSidebarOpen: Bool = true
    @State private var isAIChatDockOpen: Bool = false
    @State private var inlineAIPrompt: String = ""
    @State private var isInlineAIOpen: Bool = false
    @State private var inlineAIResponse: String = ""
    @State private var isInlineAILoading: Bool = false
    @State private var fileSearchQuery: String = ""
    @State private var statusFeedback: String? = nil
    @State private var executionOutput: String? = nil
    @State private var isExecutingCode: Bool = false

    public init(initialUrl: URL? = nil) {
        _currentRootFolder = State(initialValue: initialUrl ?? FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first)
    }

    public var body: some View {
        HSplitView {
            // ── 1. Left File Browser Sidebar ────────────────────────────────
            if isFileSidebarOpen {
                fileBrowserSidebar
                    .frame(minWidth: 180, idealWidth: 220, maxWidth: 300)
            }

            // ── 2. Center VS Code Monaco Editor Area ────────────────────────
            mainEditorArea
                .frame(minWidth: 400)

            // ── 3. Right Contextual AI Chat Dock ────────────────────────────
            if isAIChatDockOpen {
                aiChatDockSidebar
                    .frame(minWidth: 260, idealWidth: 320, maxWidth: 450)
            }
        }
        .background(Color(red: 0.11, green: 0.12, blue: 0.15))
        .onAppear {
            loadWorkspaceFiles()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusOpenEmbeddedEditor"))) { notif in
            if let fileUrl = notif.object as? URL {
                self.selectedFileUrl = fileUrl
                self.loadWorkspaceFiles()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusWorkspaceFilesChanged"))) { _ in
            self.loadWorkspaceFiles()
        }
        .onChange(of: editorBridge.activeCodeBuffer) { _, newBuffer in
            if editorBridge.isStreamingToEditor {
                self.codeContent = newBuffer
                self.selectedFileUrl = editorBridge.activeFileUrl
                self.activeLanguage = editorBridge.activeLanguage
            }
        }
    }

    // MARK: - 1. File Browser Sidebar
    private var fileBrowserSidebar: some View {
        VStack(spacing: 0) {
            // Explorer Header
            HStack(spacing: 6) {
                Image(systemName: "sidebar.left")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)

                Text("EXPLORER")
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: openFolderPicker) {
                    Image(systemName: "folder.badge.plus")
                        .font(.system(size: 11))
                        .foregroundColor(.cyan)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Open Workspace Folder")

                Button(action: loadWorkspaceFiles) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Refresh Files")
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.3))

            // Search Bar Filter
            HStack(spacing: 5) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                TextField("Filter files...", text: $fileSearchQuery)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 11))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4.5)
            .background(RoundedRectangle(cornerRadius: 5).fill(Color.white.opacity(0.06)))
            .padding(8)

            Divider().background(Color.white.opacity(0.1))

            // File Tree List
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 1) {
                    ForEach(filteredFiles) { item in
                        fileRow(item: item)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .background(Color(red: 0.09, green: 0.10, blue: 0.13))
    }

    private var filteredFiles: [FileNodeItem] {
        if fileSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return fileTree
        }
        return fileTree.filter { $0.name.localizedCaseInsensitiveContains(fileSearchQuery) }
    }

    private func fileRow(item: FileNodeItem) -> some View {
        let isSelected = selectedFileUrl == item.url
        return HStack(spacing: 6) {
            Image(systemName: item.systemIcon)
                .font(.system(size: 11))
                .foregroundColor(item.iconColor)

            Text(item.name)
                .font(.system(size: 11.5, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .white.opacity(0.85))
                .lineLimit(1)

            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(isSelected ? Color.blue.opacity(0.28) : Color.clear)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            if !item.isDirectory {
                openFile(url: item.url)
            }
        }
    }

    // MARK: - 2. Main VS Code Monaco Editor Area
    private var mainEditorArea: some View {
        VStack(spacing: 0) {
            // ── Editor Top Ribbon ───────────────────────────────────────────
            editorTopRibbon

            // ── Live AI Code Streaming Indicator ────────────────────────────
            if editorBridge.isStreamingToEditor {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.65)
                    Image(systemName: "sparkles")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.yellow)
                    Text(editorBridge.liveTypingStatus)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    ProgressView(value: editorBridge.streamingProgress)
                        .frame(width: 120)
                        .scaleEffect(x: 1, y: 0.6)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    LinearGradient(
                        colors: [Color.purple.opacity(0.40), Color.blue.opacity(0.35)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            }

            Divider().background(Color.white.opacity(0.1))

            // ── Inline AI Explanation / Copilot Bar ─────────────────────────
            if isInlineAIOpen {
                inlineAIWidgetBar
            }

            // ── Code Text Editor Buffer ─────────────────────────────────────
            ZStack(alignment: .topLeading) {
                // Background Editor Grid
                Color(red: 0.11, green: 0.12, blue: 0.15).ignoresSafeArea()

                HStack(alignment: .top, spacing: 0) {
                    // Line Numbers Gutter
                    lineNumbersGutter
                        .padding(.vertical, 8)
                        .padding(.horizontal, 6)
                        .background(Color.black.opacity(0.18))

                    Divider().background(Color.white.opacity(0.08))

                    // Text Editor Canvas
                    TextEditor(text: $codeContent)
                        .font(.system(size: 12.5, weight: .regular, design: .monospaced))
                        .foregroundColor(Color(red: 0.88, green: 0.90, blue: 0.95))
                        .scrollContentBackground(.hidden)
                        .padding(8)
                }
            }

            // ── Terminal Execution Output Drawer ─────────────────────────────
            if let output = executionOutput {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "terminal.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.green)
                        Text("TERMINAL OUTPUT")
                            .font(.system(size: 9.5, weight: .heavy, design: .monospaced))
                            .foregroundColor(.secondary)
                        Spacer()
                        Button(action: { executionOutput = nil }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    ScrollView(.vertical, showsIndicators: true) {
                        Text(output.isEmpty ? "(Process finished with zero output)" : output)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(Color(red: 0.85, green: 0.95, blue: 0.88))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 110)
                }
                .padding(8)
                .background(Color.black.opacity(0.45))
                .overlay(Rectangle().stroke(Color.white.opacity(0.1), lineWidth: 0.5))
            }

            // ── Bottom Status Bar ───────────────────────────────────────────
            editorBottomStatusBar
        }
    }

    // MARK: - Top Ribbon
    private var editorTopRibbon: some View {
        HStack(spacing: 8) {
            // Toggle File Explorer
            Button(action: {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.80)) {
                    isFileSidebarOpen.toggle()
                }
            }) {
                Image(systemName: isFileSidebarOpen ? "sidebar.left" : "sidebar.left")
                    .font(.system(size: 11))
                    .foregroundColor(isFileSidebarOpen ? .cyan : .secondary)
            }
            .buttonStyle(PlainButtonStyle())
            .help("Toggle File Explorer")

            // Active File Breadcrumb
            HStack(spacing: 4) {
                Image(systemName: "doc.text")
                    .font(.system(size: 10))
                    .foregroundColor(.cyan)
                Text(selectedFileUrl?.lastPathComponent ?? (editorBridge.activeFileName))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3.5)
            .background(RoundedRectangle(cornerRadius: 5).fill(Color.white.opacity(0.08)))

            // Reveal in Finder Button
            Button(action: {
                if let url = selectedFileUrl {
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                } else {
                    editorBridge.revealInFinder()
                }
            }) {
                Image(systemName: "folder")
                    .font(.system(size: 10.5))
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
            .help("Reveal in Finder")

            // Run Script Button (▶️)
            Button(action: executeActiveCode) {
                HStack(spacing: 4) {
                    if isExecutingCode {
                        ProgressView().scaleEffect(0.5)
                    } else {
                        Image(systemName: "play.fill")
                            .font(.system(size: 9))
                    }
                    Text("Run")
                        .font(.system(size: 10.5, weight: .semibold))
                }
                .foregroundColor(.green)
                .padding(.horizontal, 8)
                .padding(.vertical, 3.5)
                .background(RoundedRectangle(cornerRadius: 5).fill(Color.green.opacity(0.18)))
            }
            .buttonStyle(PlainButtonStyle())
            .help("Execute file with Swift / Node / Python")

            Spacer()

            // Inline AI Trigger (⌘K)
            Button(action: {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.80)) {
                    isInlineAIOpen.toggle()
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10, weight: .bold))
                    Text("Inline AI (⌘K)")
                        .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.cyan)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.cyan.opacity(0.18)))
                .overlay(Capsule().stroke(Color.cyan.opacity(0.35), lineWidth: 0.5))
            }
            .buttonStyle(PlainButtonStyle())

            // AI Side Chat Toggle
            Button(action: {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.80)) {
                    isAIChatDockOpen.toggle()
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.system(size: 10))
                    Text("AI Chat")
                        .font(.system(size: 10.5, weight: .medium))
                }
                .foregroundColor(isAIChatDockOpen ? .white : .secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 5).fill(isAIChatDockOpen ? Color.blue.opacity(0.35) : Color.white.opacity(0.06)))
            }
            .buttonStyle(PlainButtonStyle())

            // Save File
            Button(action: saveFile) {
                HStack(spacing: 4) {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 10))
                    Text("Save")
                        .font(.system(size: 10.5, weight: .medium))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 5).fill(Color.white.opacity(0.10)))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.25))
    }

    private func executeActiveCode() {
        guard !codeContent.isEmpty else { return }
        isExecutingCode = true
        HapticFeedback.heavy()
        saveFile()

        Task {
            let (out, _) = await editorBridge.runActiveFile()
            await MainActor.run {
                self.executionOutput = out
                self.isExecutingCode = false
                HapticFeedback.playClickSound()
            }
        }
    }

    // MARK: - Inline AI Explanation & Copilot Widget
    private var inlineAIWidgetBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.cyan)

                TextField("Ask AI to explain code, fix bugs, or generate functions...", text: $inlineAIPrompt)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 12))
                    .foregroundColor(.white)
                    .onSubmit {
                        submitInlineAI()
                    }

                if isInlineAILoading {
                    ProgressView().scaleEffect(0.6)
                } else {
                    Button(action: submitInlineAI) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.cyan)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                Button(action: {
                    withAnimation { isInlineAIOpen = false }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }

            // Quick Prompt Suggestions
            HStack(spacing: 6) {
                Button("Explain Code ✨") {
                    inlineAIPrompt = "Explain this code clearly line-by-line:"
                    submitInlineAI()
                }
                .buttonStyle(BorderedButtonStyle())
                .controlSize(.mini)

                Button("Refactor & Modernize ⚡️") {
                    inlineAIPrompt = "Refactor this code to follow modern Swift best practices:"
                    submitInlineAI()
                }
                .buttonStyle(BorderedButtonStyle())
                .controlSize(.mini)

                Button("Add Doc Comments 📖") {
                    inlineAIPrompt = "Add complete documentation comments to all structs and functions:"
                    submitInlineAI()
                }
                .buttonStyle(BorderedButtonStyle())
                .controlSize(.mini)
            }

            if !inlineAIResponse.isEmpty {
                ScrollView(.vertical, showsIndicators: true) {
                    Text(inlineAIResponse)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(Color(red: 0.85, green: 0.95, blue: 0.90))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.black.opacity(0.35)))
                }
                .frame(maxHeight: 120)

                HStack {
                    Button("Apply Changes to Code") {
                        if inlineAIResponse.contains("```") {
                            let extracted = extractCodeBlock(from: inlineAIResponse)
                            codeContent = extracted
                        } else {
                            codeContent = inlineAIResponse
                        }
                        HapticFeedback.playClickSound()
                    }
                    .buttonStyle(BorderedProminentButtonStyle())
                    .controlSize(.mini)

                    Spacer()
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(red: 0.14, green: 0.16, blue: 0.22))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.cyan.opacity(0.4), lineWidth: 1))
        )
        .padding(8)
    }

    // MARK: - Line Numbers Gutter
    private var lineNumbersGutter: some View {
        let lines = max(1, codeContent.components(separatedBy: "\n").count)
        return VStack(alignment: .trailing, spacing: 3.5) {
            ForEach(1...lines, id: \.self) { lineNum in
                Text("\(lineNum)")
                    .font(.system(size: 10.5, design: .monospaced))
                    .foregroundColor(.secondary.opacity(0.6))
            }
        }
        .frame(minWidth: 26)
    }

    // MARK: - 3. Right Contextual AI Chat Dock
    private var aiChatDockSidebar: some View {
        VStack(spacing: 0) {
            // Chat Header
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.cyan)

                Text("AI Code Assistant")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Spacer()

                Text(localModels.selectedModelDisplayName)
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.cyan.opacity(0.15)))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.3))

            // Chat Messages Stream
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 10) {
                    if localModels.chatHistory.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "brain.head.profile")
                                .font(.system(size: 28))
                                .foregroundColor(.cyan.opacity(0.6))
                            Text("Ready to explain, refactor, and write code with full workspace awareness.")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(24)
                    } else {
                        ForEach(localModels.chatHistory) { msg in
                            VStack(alignment: msg.role == "user" ? .trailing : .leading, spacing: 3) {
                                Text(msg.role == "user" ? "You" : "Genie AI")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(msg.role == "user" ? .cyan : .yellow)

                                Text(msg.content)
                                    .font(.system(size: 11, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(msg.role == "user" ? Color.blue.opacity(0.25) : Color.white.opacity(0.08))
                                    )
                            }
                            .frame(maxWidth: .infinity, alignment: msg.role == "user" ? .trailing : .leading)
                        }
                    }
                }
                .padding(10)
            }

            Divider().background(Color.white.opacity(0.1))

            // Chat Input Box
            HStack(spacing: 6) {
                TextField("Ask anything about this code...", text: $inlineAIPrompt)
                    .textFieldStyle(PlainTextFieldStyle())
                    .font(.system(size: 11.5))
                    .foregroundColor(.white)
                    .onSubmit {
                        submitSideChat()
                    }

                Button(action: submitSideChat) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.cyan)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(8)
            .background(Color.black.opacity(0.25))
        }
        .background(Color(red: 0.10, green: 0.11, blue: 0.14))
    }

    // MARK: - Bottom Status Bar
    private var editorBottomStatusBar: some View {
        HStack(spacing: 12) {
            Text("UTF-8")
                .font(.system(size: 9.5, design: .monospaced))
                .foregroundColor(.secondary)

            Text(activeLanguage)
                .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                .foregroundColor(.orange)

            let lines = codeContent.components(separatedBy: "\n").count
            Text("Lines: \(lines)")
                .font(.system(size: 9.5, design: .monospaced))
                .foregroundColor(.secondary)

            Text("Chars: \(codeContent.count)")
                .font(.system(size: 9.5, design: .monospaced))
                .foregroundColor(.secondary)

            Spacer()

            if let fb = statusFeedback {
                Text(fb)
                    .font(.system(size: 9.5, weight: .medium))
                    .foregroundColor(.cyan)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color(red: 0.08, green: 0.09, blue: 0.11))
    }

    // MARK: - File Management Helpers
    private func loadWorkspaceFiles() {
        guard currentRootFolder != nil else { return }
        let (folders, files) = DesktopFilesManager.shared.fetchDesktopItems()
        var items: [FileNodeItem] = []
        for folder in folders {
            items.append(FileNodeItem(url: folder, isDirectory: true))
        }
        for file in files {
            items.append(FileNodeItem(url: file, isDirectory: false))
        }
        self.fileTree = items
    }

    private func openFile(url: URL) {
        if let str = try? String(contentsOf: url, encoding: .utf8) {
            self.selectedFileUrl = url
            self.codeContent = str
            self.originalCodeSnapshot = str
            let ext = url.pathExtension.lowercased()
            switch ext {
            case "swift": activeLanguage = "Swift"
            case "py": activeLanguage = "Python"
            case "js", "ts": activeLanguage = "JavaScript"
            case "html": activeLanguage = "HTML / CSS"
            case "json": activeLanguage = "JSON"
            case "md": activeLanguage = "Markdown"
            case "sh", "zsh": activeLanguage = "Shell (zsh)"
            default: activeLanguage = "Plain Text"
            }
            statusFeedback = "Opened \(url.lastPathComponent) ✨"
            HapticFeedback.playClickSound()
        }
    }

    private func saveFile() {
        guard let url = selectedFileUrl else {
            saveToDesktop()
            return
        }
        do {
            try codeContent.write(to: url, atomically: true, encoding: .utf8)
            statusFeedback = "Saved \(url.lastPathComponent) ✅"
            HapticFeedback.playClickSound()
        } catch {
            statusFeedback = "Error saving file ❌"
        }
    }

    private func saveToDesktop() {
        let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSHomeDirectory() + "/Desktop")
        let target = desktop.appendingPathComponent("GenieSnippet_\(Int(Date().timeIntervalSince1970)).swift")
        try? codeContent.write(to: target, atomically: true, encoding: .utf8)
        selectedFileUrl = target
        statusFeedback = "Saved to Desktop ✨"
        loadWorkspaceFiles()
        HapticFeedback.playClickSound()
    }

    private func openFolderPicker() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            currentRootFolder = url
            loadWorkspaceFiles()
        }
    }

    // MARK: - AI Action Helpers
    private func submitInlineAI() {
        guard !inlineAIPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        isInlineAILoading = true
        let prompt = "\(inlineAIPrompt)\n\nFile Context (\(activeLanguage)):\n```\(activeLanguage.lowercased())\n\(codeContent)\n```"
        localModels.generate(prompt: prompt)

        Task {
            // Await response from local model manager
            while localModels.isGenerating {
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
            await MainActor.run {
                self.inlineAIResponse = localModels.currentResponse
                self.isInlineAILoading = false
            }
        }
    }

    private func submitSideChat() {
        guard !inlineAIPrompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let prompt = "Code File Context:\n```\(activeLanguage.lowercased())\n\(codeContent)\n```\n\nQuestion: \(inlineAIPrompt)"
        localModels.generate(prompt: prompt)
        inlineAIPrompt = ""
    }

    private func extractCodeBlock(from text: String) -> String {
        let components = text.components(separatedBy: "```")
        if components.count >= 3 {
            var raw = components[1]
            if let firstNewline = raw.firstIndex(of: "\n") {
                raw = String(raw[raw.index(after: firstNewline)...])
            }
            return raw.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return text
    }
}
