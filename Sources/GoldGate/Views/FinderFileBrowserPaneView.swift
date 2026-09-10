import SwiftUI
import AppKit

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

    private let fileManager = FileManager.default
    private let onNavigate: (URL) -> Void

    public init(initialURL: URL? = nil, onNavigate: @escaping (URL) -> Void = { _ in }) {
        let defaultURL = initialURL ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
        _currentURL = State(initialValue: defaultURL)
        self.onNavigate = onNavigate
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
            if isLoading {
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
            } else if isGridView {
                iconGridView
            } else {
                listView
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
        .onChange(of: currentURL) { _, url in onNavigate(url) }
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
                        handleActivate(item: item)
                    }
                    .onTapGesture {
                        selectedItemID = item.id
                    }
                    .contextMenu {
                        Button("Open") { handleActivate(item: item) }
                        Button("Reveal in Finder") { NSWorkspace.shared.activateFileViewerSelecting([item.url]) }
                        Divider()
                        Button("Copy Path") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(item.url.path, forType: .string)
                        }
                    }
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
                        handleActivate(item: item)
                    }
                    .onTapGesture {
                        selectedItemID = item.id
                    }
                    .contextMenu {
                        Button("Open") { handleActivate(item: item) }
                        Button("Reveal in Finder") { NSWorkspace.shared.activateFileViewerSelecting([item.url]) }
                        Divider()
                        Button("Copy Path") {
                            NSPasteboard.general.clearContents()
                            NSPasteboard.general.setString(item.url.path, forType: .string)
                        }
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
          }
        }
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

    // MARK: - Actions
    private func handleActivate(item: FinderFileItem) {
        if item.isDirectory {
            navigateTo(item.url)
        } else {
            NSWorkspace.shared.open(item.url)
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
