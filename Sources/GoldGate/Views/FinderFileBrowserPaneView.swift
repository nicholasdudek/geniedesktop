import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - 📁 Live Native File Browser Item Model
public struct FinderFileItem: Identifiable, Hashable {
    public let id: String
    public let url: URL
    public let name: String
    public let isDirectory: Bool
    public let sizeBytes: Int64
    public let modificationDate: Date
    public let icon: NSImage

    public var formattedSize: String {
        if isDirectory {
            return "--"
        }
        return ByteCountFormatter.string(fromByteCount: sizeBytes, countStyle: .file)
    }

    public var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: modificationDate)
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    public static func == (lhs: FinderFileItem, rhs: FinderFileItem) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - 🗂️ Live Finder File Browser Pane View
public struct FinderFileBrowserPaneView: View {
    @State private var currentURL: URL
    @State private var items: [FinderFileItem] = []
    @State private var selectedItemID: String? = nil
    @State private var isGridView: Bool = true
    @State private var freeDiskSpace: String = ""
    @State private var history: [URL] = []
    @State private var forwardHistory: [URL] = []
    @State private var searchQuery: String = ""
    @State private var isLoading = false
    @State private var loadError: String?
    @State private var requestID = UUID()
    @State private var editingFile: URL? = nil
    @State private var editingText: String = ""
    @State private var editorSaveStatus: EditorSaveStatus = .saved
    @State private var autosaveTask: Task<Void, Never>? = nil
    @State private var previewItem: FinderFileItem? = nil
    @AppStorage(PrefKey.filesPreviewPaneHeight) private var storedPreviewHeight: Double = 240
    @AppStorage(PrefKey.filesPreviewPaneCollapsed) private var isPreviewCollapsed: Bool = false
    @State private var isDraggingPreviewDivider = false
    @State private var previewDragStartHeight: CGFloat? = nil

    private enum EditorSaveStatus: Equatable {
        case saved
        case saving
        case error(String)
    }

    private let fileManager = FileManager.default
    private let onNavigate: (URL) -> Void
    public var onOpenFile: ((URL) -> Void)? = nil

    public init(
        initialURL: URL? = nil,
        onNavigate: @escaping (URL) -> Void = { _ in },
        onOpenFile: ((URL) -> Void)? = nil
    ) {
        let defaultURL = initialURL ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
        _currentURL = State(initialValue: defaultURL)
        self.onNavigate = onNavigate
        self.onOpenFile = onOpenFile
    }

    public var body: some View {
        VStack(spacing: 0) {
            // 1. Navigation Toolbar & Breadcrumbs
            navigationHeader
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.18))

            Divider()
                .background(Color.white.opacity(0.12))

            // 2. Main File Area
            if let editingFile {
                fileEditorView(url: editingFile)
            } else if isLoading {
                ProgressView("Loading folder...")
                    .controlSize(.small)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let loadError {
                VStack(spacing: 12) {
                    Image(systemName: "folder.badge.questionmark").font(.system(size: 32))
                    Text("Folder unavailable").font(.headline)
                    Text(loadError).font(.caption).multilineTextAlignment(.center)
                    Button("Try Again", systemImage: "arrow.clockwise") { refreshDirectory() }
                    Button("Choose Folder...", systemImage: "folder") { chooseFolder() }
                }
                .foregroundStyle(.white.opacity(0.8))
                .padding(20)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredItems.isEmpty {
                emptyDirectoryView
            } else {
                GeometryReader { geo in
                    VStack(spacing: 0) {
                        Group {
                            if isGridView {
                                iconGridView
                            } else {
                                listView
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)

                        if let item = previewItem {
                            previewSplitter(available: geo.size.height)

                            if !isPreviewCollapsed {
                                internalFilePreviewPane(
                                    item: item,
                                    height: clampedPreviewHeight(available: geo.size.height)
                                )
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                        }
                    }
                }
            }

            Divider()
                .background(Color.white.opacity(0.12))

            // 3. Status Bar
            statusBar
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.24))
        }
        .onAppear {
            refreshDirectory()
        }
        .onChange(of: currentURL) { _, url in
            closeEditor()
            onNavigate(url)
        }
    }

    // MARK: - Subviews
    private var navigationHeader: some View {
        VStack(spacing: 8) {
          HStack(spacing: 8) {
            // Back / Forward Buttons
            HStack(spacing: 4) {
                Button(action: goBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(history.isEmpty ? Color.white.opacity(0.25) : Color.white)
                        .frame(width: 26, height: 26)
                        .background(Color.white.opacity(history.isEmpty ? 0.05 : 0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .disabled(history.isEmpty)
                .help("Back")
                .accessibilityLabel("Back")

                Button(action: goForward) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(forwardHistory.isEmpty ? Color.white.opacity(0.25) : Color.white)
                        .frame(width: 26, height: 26)
                        .background(Color.white.opacity(forwardHistory.isEmpty ? 0.05 : 0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .disabled(forwardHistory.isEmpty)
                .help("Forward")
                .accessibilityLabel("Forward")

                Button(action: goUp) {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(currentURL.path == "/" ? Color.white.opacity(0.25) : Color.white)
                        .frame(width: 26, height: 26)
                        .background(Color.white.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .disabled(currentURL.path == "/")
                .help("Enclosing Folder")
                .accessibilityLabel("Enclosing Folder")
            }

            // Quick Shortcut Menu
            Menu {
                Button("Choose Folder...", systemImage: "folder.badge.plus") { chooseFolder() }
                Button("Reveal in Finder", systemImage: "arrow.up.forward.app") {
                    NSWorkspace.shared.activateFileViewerSelecting([currentURL])
                }
                Divider()
                Button("Desktop") { navigateTo(fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")) }
                Button("Genie Workspace") { navigateTo(fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Desktop/Genie/Workspace")) }
                Button("Documents") { navigateTo(fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Documents")) }
                Button("Downloads") { navigateTo(fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Downloads")) }
                Button("Home (~) ") { navigateTo(fileManager.homeDirectoryForCurrentUser) }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.cyan)
                    Text(currentURL.lastPathComponent.isEmpty ? "/" : currentURL.lastPathComponent)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.white.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .frame(maxWidth: .infinity, alignment: .leading)
            .help(currentURL.path)

            Button { refreshDirectory() } label: {
                Image(systemName: "arrow.clockwise")
                    .frame(width: 26, height: 26)
            }
            .buttonStyle(.plain)
            .disabled(isLoading)
            .help("Refresh Folder")
            .accessibilityLabel("Refresh Folder")
          }

          HStack(spacing: 8) {

            // Search Filter
            HStack(spacing: 4) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))
                TextField("Filter...", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11))
                    .foregroundColor(.white)
                    .frame(minWidth: 40, maxWidth: .infinity)
                    .accessibilityLabel("Filter files in current folder")
                    Button(action: { searchQuery = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.6))
                            .frame(width: 18, height: 18)
                    }
                    .buttonStyle(.plain)
                    .opacity(searchQuery.isEmpty ? 0 : 1)
                    .disabled(searchQuery.isEmpty)
                    .help("Clear Filter")
                    .accessibilityLabel("Clear Filter")
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 6))

            // Grid / List toggle
            HStack(spacing: 2) {
                Button(action: { isGridView = true; HapticFeedback.tick() }) {
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 11, weight: isGridView ? .bold : .regular))
                        .foregroundColor(isGridView ? .cyan : .white.opacity(0.6))
                        .padding(4)
                        .background(isGridView ? Color.cyan.opacity(0.2) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.plain)
                .help("Icon View")
                .accessibilityLabel("Icon View")
                .accessibilityAddTraits(isGridView ? .isSelected : [])

                Button(action: { isGridView = false; HapticFeedback.tick() }) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 11, weight: !isGridView ? .bold : .regular))
                        .foregroundColor(!isGridView ? .cyan : .white.opacity(0.6))
                        .padding(4)
                        .background(!isGridView ? Color.cyan.opacity(0.2) : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                .buttonStyle(.plain)
                .help("List View")
                .accessibilityLabel("List View")
                .accessibilityAddTraits(!isGridView ? .isSelected : [])
            }
            .padding(2)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 6))
          }
        }
    }

    private var filteredItems: [FinderFileItem] {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.isEmpty {
            return items
        }
        return items.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    private var iconGridView: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 88, maximum: 110), spacing: 12)], spacing: 12) {
                ForEach(filteredItems) { item in
                    VStack(spacing: 6) {
                        Image(nsImage: item.icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 48, height: 48)

                        Text(item.name)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white)
                            .lineLimit(2)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 4)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 88)
                    .padding(6)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(selectedItemID == item.id ? Color.cyan.opacity(0.25) : Color.white.opacity(0.04))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(selectedItemID == item.id ? Color.cyan.opacity(0.6) : Color.clear, lineWidth: 1.5)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        HapticFeedback.selection()
                        handleActivate(item: item)
                    }
                    .onTapGesture {
                        selectedItemID = item.id
                        if !item.isDirectory {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                                previewItem = item
                            }
                        } else {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                                previewItem = nil
                            }
                        }
                    }
                    .contextMenu { finderContextMenu(for: item) }
                }
            }
            .padding(14)
        }
    }

    private var listView: some View {
        GeometryReader { geometry in
          ScrollView {
            LazyVStack(spacing: 2) {
                ForEach(filteredItems) { item in
                    HStack(spacing: 10) {
                        Image(nsImage: item.icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 18, height: 18)

                        Text(item.name)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white)
                            .lineLimit(1)
                            .truncationMode(.middle)

                        Spacer()

                        if geometry.size.width >= 460 {
                          Text(item.formattedDate)
                            .font(.system(size: 10.5))
                            .foregroundColor(.white.opacity(0.5))
                            .frame(width: 110, alignment: .trailing)
                        }

                        Text(item.formattedSize)
                            .font(.system(size: 10.5, design: .monospaced))
                            .foregroundColor(.white.opacity(0.6))
                            .frame(width: 70, alignment: .trailing)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill(selectedItemID == item.id ? Color.cyan.opacity(0.25) : Color.clear)
                    )
                    .contentShape(Rectangle())
                    .onTapGesture(count: 2) {
                        HapticFeedback.selection()
                        handleActivate(item: item)
                    }
                    .onTapGesture {
                        selectedItemID = item.id
                        if !item.isDirectory {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                                previewItem = item
                            }
                        } else {
                            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                                previewItem = nil
                            }
                        }
                    }
                    .contextMenu { finderContextMenu(for: item) }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
          }
        }
    }


    // MARK: - Finder-standard context menu
    //
    // Ordered and grouped the way Finder's own menu is, so muscle memory carries over:
    // open actions, then Quick Look, then reveal, then clipboard, then destructive last
    // and separated. Quick Look uses the real QLPreviewPanel rather than a bespoke
    // sheet, which gets every file type's system renderer for free.
    @ViewBuilder
    private func finderContextMenu(for item: FinderFileItem) -> some View {
        Button("Ask Genie About File") {
            FinderChatWindowManager.shared.stageFile(url: item.url)
        }

        Button("Open") { handleActivate(item: item) }

        if item.url.isBrowserRenderable {
            Button("Open in Browser") {
                NSWorkspace.shared.open(item.url)
            }
        }

        Button("Quick Look") {
            QuickLookPresenter.shared.present(filteredItems.map(\.url), current: item.url)
        }

        Divider()

        Button("Reveal in Finder") {
            NSWorkspace.shared.activateFileViewerSelecting([item.url])
        }

        Divider()

        Button("Copy") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.writeObjects([item.url as NSURL])
        }
        Button("Copy Path") {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(item.url.path, forType: .string)
        }
        Button("Duplicate") {
            duplicate(item.url)
        }

        Divider()

        Button("Move to Trash") {
            try? FileManager.default.trashItem(at: item.url, resultingItemURL: nil)
        }
    }

    /// Finder's "copy 2" naming, so repeated duplicates do not collide.
    private func duplicate(_ url: URL) {
        let base = url.deletingPathExtension().lastPathComponent
        let ext = url.pathExtension
        let dir = url.deletingLastPathComponent()
        var candidate = dir.appendingPathComponent(ext.isEmpty ? "\(base) copy" : "\(base) copy.\(ext)")
        var n = 2
        while FileManager.default.fileExists(atPath: candidate.path) {
            let name = ext.isEmpty ? "\(base) copy \(n)" : "\(base) copy \(n).\(ext)"
            candidate = dir.appendingPathComponent(name)
            n += 1
        }
        try? FileManager.default.copyItem(at: url, to: candidate)
    }

    private var emptyDirectoryView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "folder")
                .font(.system(size: 44))
                .foregroundColor(.white.opacity(0.25))
            Text(searchQuery.isEmpty ? "This folder is empty" : "No matching items found")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
            if !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Button("Clear Filter", systemImage: "xmark.circle") { searchQuery = "" }
                    .controlSize(.small)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var statusBar: some View {
        HStack {
            Text(isLoading ? "Loading..." : (loadError == nil ? "\(filteredItems.count) items" : "Folder unavailable"))
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.7))

            Spacer()

            if !freeDiskSpace.isEmpty {
                Text(freeDiskSpace)
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }

    // MARK: - ✏️ In-Window Text Editor with Autosave
    private func isEditableAsText(_ url: URL) -> Bool {
        guard let type = UTType(filenameExtension: url.pathExtension) else { return false }
        return type.conforms(to: .text)
    }

    private func openInEditor(_ url: URL) {
        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            NSWorkspace.shared.open(url)
            return
        }
        autosaveTask?.cancel()
        editingFile = url
        editingText = text
        editorSaveStatus = .saved
    }

    private func closeEditor() {
        autosaveTask?.cancel()
        editingFile = nil
        editingText = ""
        editorSaveStatus = .saved
    }

    /// Debounced write-back to disk: waits for a pause in typing so every keystroke
    /// doesn't hit the filesystem, then saves. Cancelling on each change means only
    /// the last edit in a burst is ever written.
    private func scheduleAutosave(text: String) {
        guard let url = editingFile else { return }
        autosaveTask?.cancel()
        editorSaveStatus = .saving
        autosaveTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            do {
                try text.write(to: url, atomically: true, encoding: .utf8)
                await MainActor.run { editorSaveStatus = .saved }
            } catch {
                await MainActor.run { editorSaveStatus = .error(error.localizedDescription) }
            }
        }
    }

    @ViewBuilder
    private func internalFilePreviewPane(item: FinderFileItem, height: CGFloat) -> some View {
        GenieUniversalFileViewer(
            url: item.url,
            onClose: {
                withAnimation(.spring(response: 0.24, dampingFraction: 0.82)) {
                    previewItem = nil
                }
            },
            showHeader: true
        )
        .frame(height: height)
        .padding(.horizontal, 8)
        .padding(.bottom, 6)
    }

    // MARK: - Preview Splitter
    // The grid and the preview share the pane, so the preview owns a height the
    // user can drag rather than a fixed 240pt. Both bounds are enforced against
    // the live container height: the grid never drops below `minimumGridHeight`
    // even when the window is short, and the stored height survives relaunch.
    private static let minimumPreviewHeight: CGFloat = 120
    private static let minimumGridHeight: CGFloat = 160

    private func clampedPreviewHeight(available: CGFloat) -> CGFloat {
        let ceiling = max(Self.minimumPreviewHeight, available - Self.minimumGridHeight - splitterHeight)
        return min(max(CGFloat(storedPreviewHeight), Self.minimumPreviewHeight), ceiling)
    }

    private var splitterHeight: CGFloat { 16 }

    private func togglePreviewCollapsed() {
        withAnimation(.spring(response: 0.26, dampingFraction: 0.84)) {
            isPreviewCollapsed.toggle()
        }
        HapticFeedback.selection()
    }

    @ViewBuilder
    private func previewSplitter(available: CGFloat) -> some View {
        let height = clampedPreviewHeight(available: available)

        ZStack {
            Rectangle()
                .fill(Color.white.opacity(isDraggingPreviewDivider ? 0.34 : 0.14))
                .frame(height: isDraggingPreviewDivider ? 2 : 1)

            HStack(spacing: 8) {
                Button(action: togglePreviewCollapsed) {
                    Image(systemName: isPreviewCollapsed ? "chevron.up" : "chevron.down")
                        .font(.system(size: 7.5, weight: .bold))
                        .foregroundColor(.white.opacity(0.9))
                        .frame(width: 22, height: 12)
                        .background(Capsule().fill(Color.black.opacity(0.72)))
                        .overlay(Capsule().strokeBorder(Color.white.opacity(0.28), lineWidth: 0.5))
                }
                .buttonStyle(.plain)
                .help(isPreviewCollapsed ? "Show Preview" : "Hide Preview")
                .accessibilityLabel(isPreviewCollapsed ? "Show preview" : "Hide preview")

                Capsule()
                    .fill(Color.white.opacity(isDraggingPreviewDivider ? 0.85 : 0.34))
                    .frame(width: isDraggingPreviewDivider ? 54 : 40, height: 4)

                if isDraggingPreviewDivider {
                    Text("\(Int(height)) pt")
                        .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.85))
                        .transition(.opacity)
                }
            }
            .animation(.spring(response: 0.22, dampingFraction: 0.85), value: isDraggingPreviewDivider)
        }
        .frame(maxWidth: .infinity)
        .frame(height: splitterHeight)
        .contentShape(Rectangle())
        .onHover { inside in
            if inside { NSCursor.resizeUpDown.push() } else { NSCursor.pop() }
        }
        .gesture(
            DragGesture(minimumDistance: 1)
                .onChanged { value in
                    if previewDragStartHeight == nil {
                        previewDragStartHeight = height
                        isDraggingPreviewDivider = true
                        if isPreviewCollapsed { isPreviewCollapsed = false }
                    }
                    let start = previewDragStartHeight ?? height
                    // Dragging up grows the preview, so the translation subtracts.
                    let ceiling = max(Self.minimumPreviewHeight, available - Self.minimumGridHeight - splitterHeight)
                    let proposed = start - value.translation.height
                    storedPreviewHeight = Double(min(max(proposed, Self.minimumPreviewHeight), ceiling))
                }
                .onEnded { _ in
                    previewDragStartHeight = nil
                    isDraggingPreviewDivider = false
                    HapticFeedback.selection()
                }
        )
        .simultaneousGesture(
            TapGesture(count: 2).onEnded { togglePreviewCollapsed() }
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Preview splitter")
        .accessibilityHint("Drag to resize the preview, or double-click to collapse it")
    }

    @ViewBuilder
    private func fileEditorView(url: URL) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Button(action: closeEditor) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 26, height: 26)
                        .background(Color.white.opacity(0.10))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
                .help("Back to Files")
                .accessibilityLabel("Back to Files")

                Text(url.lastPathComponent)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer()

                Button(action: {
                    FinderChatWindowManager.shared.stageFile(url: url)
                    HapticFeedback.selection()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 10, weight: .semibold))
                        Text("Ask Genie")
                            .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.cyan.opacity(0.18)))
                    .overlay(Capsule().strokeBorder(Color.cyan.opacity(0.40), lineWidth: 0.6))
                }
                .buttonStyle(.plain)
                .help("Stage this file in Genie Chat for intelligent analysis")

                saveStatusLabel
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.18))

            Divider().background(Color.white.opacity(0.12))

            TextEditor(text: $editingText)
                .font(.system(size: 12, design: .monospaced))
                .scrollContentBackground(.hidden)
                .foregroundColor(.white)
                .padding(8)
                .background(Color.black.opacity(0.12))
                .onChange(of: editingText) { _, newValue in
                    scheduleAutosave(text: newValue)
                }
        }
    }

    @ViewBuilder
    private var saveStatusLabel: some View {
        Group {
            switch editorSaveStatus {
            case .saved:
                Label("Saved", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green.opacity(0.85))
            case .saving:
                Label("Saving…", systemImage: "ellipsis.circle")
                    .foregroundColor(.white.opacity(0.5))
            case .error(let message):
                Label("Save failed", systemImage: "exclamationmark.triangle.fill")
                    .foregroundColor(.red.opacity(0.85))
                    .help(message)
            }
        }
        .font(.system(size: 10.5, weight: .medium))
        .labelStyle(.titleAndIcon)
    }

    // MARK: - Actions
    private func handleActivate(item: FinderFileItem) {
        if item.isDirectory {
            navigateTo(item.url)
        } else if let onOpen = onOpenFile {
            onOpen(item.url)
        } else if isEditableAsText(item.url) {
            openInEditor(item.url)
        } else {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                previewItem = item
            }
        }
    }

    private func navigateTo(_ url: URL) {
        let url = url.standardizedFileURL
        guard url != currentURL.standardizedFileURL else { return }
        history.append(currentURL)
        forwardHistory.removeAll()
        currentURL = url
        selectedItemID = nil
        searchQuery = ""
        refreshDirectory()
    }

    private func goBack() {
        guard let prev = history.popLast() else { return }
        forwardHistory.append(currentURL)
        currentURL = prev
        selectedItemID = nil
        searchQuery = ""
        refreshDirectory()
    }

    private func goForward() {
        guard let next = forwardHistory.popLast() else { return }
        history.append(currentURL)
        currentURL = next
        selectedItemID = nil
        searchQuery = ""
        refreshDirectory()
    }

    private func goUp() {
        let parent = currentURL.deletingLastPathComponent()
        guard parent.path != currentURL.path else { return }
        navigateTo(parent)
    }

    private func refreshDirectory() {
        let directoryURL = currentURL
        let id = UUID()
        requestID = id
        isLoading = true
        loadError = nil
        freeDiskSpace = ""
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let resourceKeys: [URLResourceKey] = [.isDirectoryKey, .isPackageKey, .fileSizeKey, .contentModificationDateKey]
                let urls = try fileManager.contentsOfDirectory(
                    at: directoryURL,
                    includingPropertiesForKeys: resourceKeys,
                    options: [.skipsHiddenFiles]
                )

                var parsedItems: [FinderFileItem] = []
                for u in urls {
                    let values = try? u.resourceValues(forKeys: Set(resourceKeys))
                    let isDir = values?.isDirectory == true && values?.isPackage != true
                    let size = Int64(values?.fileSize ?? 0)
                    let modDate = values?.contentModificationDate ?? Date()
                    let icon = NSWorkspace.shared.icon(forFile: u.path)

                    parsedItems.append(FinderFileItem(
                        id: u.path,
                        url: u,
                        name: u.lastPathComponent,
                        isDirectory: isDir,
                        sizeBytes: size,
                        modificationDate: modDate,
                        icon: icon
                    ))
                }

                parsedItems.sort { (a, b) -> Bool in
                    if a.isDirectory != b.isDirectory {
                        return a.isDirectory && !b.isDirectory
                    }
                    return a.name.localizedStandardCompare(b.name) == .orderedAscending
                }

                DispatchQueue.main.async {
                    guard self.requestID == id else { return }
                    self.items = parsedItems
                    self.isLoading = false
                    if !parsedItems.contains(where: { $0.id == self.selectedItemID }) {
                        self.selectedItemID = nil
                    }
                    self.updateDiskSpace()
                }
            } catch {
                DispatchQueue.main.async {
                    guard self.requestID == id else { return }
                    self.items = []
                    self.isLoading = false
                    self.loadError = error.localizedDescription
                }
            }
        }
    }

    private func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = currentURL
        panel.prompt = "Open"
        if panel.runModal() == .OK, let url = panel.url { navigateTo(url) }
    }

    private func updateDiskSpace() {
        if let values = try? currentURL.resourceValues(forKeys: [.volumeAvailableCapacityKey]),
           let cap = values.volumeAvailableCapacity {
            let str = ByteCountFormatter.string(fromByteCount: Int64(cap), countStyle: .file)
            self.freeDiskSpace = "\(str) available"
        }
    }
}
