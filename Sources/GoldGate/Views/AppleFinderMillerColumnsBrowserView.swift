import AppKit
import Foundation
import SwiftUI
import WebKit

// MARK: - 📁 Apple Finder File Model for Miller Columns
public struct MillerColumnItem: Identifiable, Hashable {
    public let id: String
    public let url: URL
    public let name: String
    public let isDirectory: Bool
    public let sizeBytes: Int64
    public let modificationDate: Date

    public init(url: URL) {
        self.id = url.path
        self.url = url
        self.name = url.lastPathComponent
        let values = try? url.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey])
        self.isDirectory = values?.isDirectory ?? false
        self.sizeBytes = Int64(values?.fileSize ?? 0)
        self.modificationDate = values?.contentModificationDate ?? Date()
    }

    public var icon: NSImage {
        NSWorkspace.shared.icon(forFile: url.path)
    }

    public var formattedSize: String {
        if isDirectory { return "--" }
        return ByteCountFormatter.string(fromByteCount: sizeBytes, countStyle: .file)
    }

    public var formattedDate: String {
        let df = DateFormatter()
        df.dateStyle = .short
        df.timeStyle = .short
        return df.string(from: modificationDate)
    }
}

// MARK: - 🗂️ Apple Finder Miller Columns Browser View
/// Authentic Apple macOS Finder multi-column browser (Miller columns) with:
/// 1. Dynamic horizontal column unfolding as directories are explored.
/// 2. Scrollable rich preview column (code with syntax line numbers, live HTML/Web, images, media).
/// 3. Seamless preservation of live AI creations / render streams.
/// 4. Integrated Trash Airlock promote, Ask Genie, and Terminal shortcuts.
public struct AppleFinderMillerColumnsBrowserView: View {
    @ObservedObject var windowManager = FinderChatWindowManager.shared
    @State private var columnPaths: [URL] = []
    @State private var selectedFileURL: URL? = nil
    @State private var searchQuery: String = ""
    @State private var activeSidebarLocation: String = "Desktop"
    @State private var previewModeTab: PreviewTab = .filePreview

    // Live AI Creation passed down from parent or chat
    public var liveCreation: (title: String, html: String, fileURL: URL?)? = nil
    public var onSelectFile: ((URL) -> Void)? = nil
    public var onOpenFile: ((URL) -> Void)? = nil

    private enum PreviewTab: String, CaseIterable, Identifiable {
        case filePreview = "File Preview"
        case liveRender = "✨ Live Render"

        var id: String { rawValue }
    }

    public init(
        initialURL: URL? = nil,
        liveCreation: (title: String, html: String, fileURL: URL?)? = nil,
        onSelectFile: ((URL) -> Void)? = nil,
        onOpenFile: ((URL) -> Void)? = nil
    ) {
        let base = initialURL ?? FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
        _columnPaths = State(initialValue: [base])
        self.liveCreation = liveCreation
        self.onSelectFile = onSelectFile
        self.onOpenFile = onOpenFile
    }

    public var body: some View {
        VStack(spacing: 0) {
            // 1. Apple Finder Glass Toolbar
            finderGlassToolbar

            Divider()
                .background(Color.white.opacity(0.12))

            // 2. Multi-Column Miller Layout + Scrollable Preview
            HStack(spacing: 0) {
                // Left Quick-Access Sidebar (Favorites & Airlock)
                finderQuickSidebar
                    .frame(width: 140)
                    .background(Color.black.opacity(0.24))

                Rectangle()
                    .fill(Color.white.opacity(0.08))
                    .frame(width: 1)

                // Miller Columns Cascading Horizontal Scroll
                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: true) {
                        HStack(spacing: 0) {
                            ForEach(Array(columnPaths.enumerated()), id: \.element.path) { colIndex, folderURL in
                                columnView(for: folderURL, at: colIndex)
                                    .frame(width: 210)
                                    .id(folderURL.path)

                                Rectangle()
                                    .fill(Color.white.opacity(0.08))
                                    .frame(width: 1)
                            }

                            // Rightmost Scrollable Preview Column
                            if selectedFileURL != nil || liveCreation != nil {
                                scrollablePreviewColumn
                                    .frame(width: 290)
                                    .id("preview_column")
                            }
                        }
                    }
                    .onChange(of: columnPaths.count) { _, _ in
                        withAnimation(.easeOut(duration: 0.22)) {
                            if let last = columnPaths.last {
                                proxy.scrollTo(last.path, anchor: .trailing)
                            }
                        }
                    }
                    .onChange(of: selectedFileURL) { _, newURL in
                        if newURL != nil {
                            withAnimation(.easeOut(duration: 0.22)) {
                                proxy.scrollTo("preview_column", anchor: .trailing)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()
                .background(Color.white.opacity(0.12))

            // 3. Status Bar & Breadcrumb Path
            finderStatusBar
        }
        .background(
            VisualEffectBlur(material: .popover, blendingMode: .withinWindow, state: .active)
                .opacity(0.28)
        )
        .onAppear {
            if columnPaths.isEmpty {
                columnPaths = [FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")]
            }
            if liveCreation != nil {
                previewModeTab = .liveRender
            }
        }
        .onChange(of: liveCreation?.title) { _, newTitle in
            if newTitle != nil {
                previewModeTab = .liveRender
            }
        }
    }

    // MARK: - 🎛️ Finder Glass Toolbar
    private var finderGlassToolbar: some View {
        HStack(spacing: 8) {
            // Navigation Back / Forward buttons
            HStack(spacing: 2) {
                Button(action: navigateBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(columnPaths.count > 1 ? .white : .white.opacity(0.3))
                }
                .buttonStyle(.plain)
                .disabled(columnPaths.count <= 1)

                Button(action: refreshCurrent) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.75))
                }
                .buttonStyle(.plain)
                .help("Refresh Finder Columns")
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(Capsule().fill(Color.white.opacity(0.06)))

            // Breadcrumbs Bar
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(Array(columnPaths.enumerated()), id: \.element.path) { idx, url in
                        Button(action: {
                            withAnimation(.spring(response: 0.24, dampingFraction: 0.8)) {
                                columnPaths = Array(columnPaths.prefix(idx + 1))
                                selectedFileURL = nil
                            }
                        }) {
                            HStack(spacing: 3) {
                                Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width: 12, height: 12)
                                Text(url.lastPathComponent)
                                    .font(.system(size: 10.5, weight: idx == columnPaths.count - 1 ? .bold : .medium, design: .rounded))
                                    .foregroundColor(idx == columnPaths.count - 1 ? .cyan : .white.opacity(0.75))
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2.5)
                            .background(
                                Capsule()
                                    .fill(idx == columnPaths.count - 1 ? Color.cyan.opacity(0.18) : Color.white.opacity(0.05))
                            )
                        }
                        .buttonStyle(.plain)

                        if idx < columnPaths.count - 1 {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 7.5, weight: .bold))
                                .foregroundColor(.white.opacity(0.35))
                        }
                    }
                }
                .padding(.horizontal, 2)
            }

            Spacer()

            // Filter Search Bar
            HStack(spacing: 4) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 9))
                    .foregroundColor(.white.opacity(0.5))
                TextField("Filter...", text: $searchQuery)
                    .font(.system(size: 10, design: .default))
                    .textFieldStyle(.plain)
                    .foregroundColor(.white)
                    .frame(width: 80)
                if !searchQuery.isEmpty {
                    Button(action: { searchQuery = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 3.5)
            .background(Capsule().fill(Color.white.opacity(0.06)))
            .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.5))

            // Open in external Finder button
            if let targetURL = columnPaths.last {
                Button(action: {
                    NSWorkspace.shared.open(targetURL)
                }) {
                    Image(systemName: "arrow.up.right.square")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.75))
                }
                .buttonStyle(.plain)
                .help("Open in macOS Finder")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.35))
    }

    // MARK: - 📁 Quick Sidebar
    private var finderQuickSidebar: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("FAVORITES")
                .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.45))
                .padding(.horizontal, 10)
                .padding(.top, 8)

            VStack(spacing: 2) {
                let home = FileManager.default.homeDirectoryForCurrentUser
                sidebarButton(title: "Desktop", icon: "menubar.dock.rectangle", url: home.appendingPathComponent("Desktop"))
                sidebarButton(title: "Developer", icon: "hammer.fill", url: home.appendingPathComponent("Desktop/Developer"))
                sidebarButton(title: "Documents", icon: "doc.text.fill", url: home.appendingPathComponent("Documents"))
                sidebarButton(title: "Downloads", icon: "arrow.down.circle.fill", url: home.appendingPathComponent("Downloads"))
                sidebarButton(title: "Home", icon: "house.fill", url: home)
            }

            Divider()
                .background(Color.white.opacity(0.08))

            Text("AIRLOCK & RAM")
                .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                .foregroundColor(.white.opacity(0.45))
                .padding(.horizontal, 10)

            VStack(spacing: 2) {
                let trashAirlock = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".Trash/.genie_airlock")
                sidebarButton(title: "Trash Airlock", icon: "trash.circle.fill", url: trashAirlock, accentColor: .yellow)
                sidebarButton(title: "In-RAM /tmp", icon: "bolt.fill", url: URL(fileURLWithPath: "/private/tmp"), accentColor: .cyan)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func sidebarButton(title: String, icon: String, url: URL, accentColor: Color = .white) -> some View {
        let isSelected = activeSidebarLocation == title || columnPaths.first?.path == url.path
        Button(action: {
            HapticFeedback.selection()
            activeSidebarLocation = title
            withAnimation(.spring(response: 0.24, dampingFraction: 0.8)) {
                columnPaths = [url]
                selectedFileURL = nil
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(isSelected ? accentColor : accentColor.opacity(0.65))
                    .frame(width: 14)

                Text(title)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.8))
                    .lineLimit(1)

                Spacer()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isSelected ? Color.white.opacity(0.12) : Color.clear)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 4)
    }

    // MARK: - 🏛️ Column View for Miller Hierarchy
    private func columnView(for folderURL: URL, at colIndex: Int) -> some View {
        let items = loadItems(for: folderURL)
        let filteredItems = searchQuery.isEmpty ? items : items.filter { $0.name.localizedCaseInsensitiveContains(searchQuery) }

        return VStack(spacing: 0) {
            // Column Header
            HStack {
                Text(folderURL.lastPathComponent.uppercased())
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.40))
                    .lineLimit(1)
                Spacer()
                Text("\(filteredItems.count)")
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.45))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color.white.opacity(0.02))

            Divider().background(Color.white.opacity(0.06))

            if filteredItems.isEmpty {
                VStack(spacing: 6) {
                    Image(systemName: "folder")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.25))
                    Text("Empty")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.35))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVStack(spacing: 1.5) {
                        ForEach(filteredItems) { item in
                            columnItemRow(item: item, colIndex: colIndex)
                        }
                    }
                    .padding(3)
                }
            }
        }
        .background(Color(red: 0.10, green: 0.11, blue: 0.13).opacity(0.85))
    }

    // MARK: - 📄 Column Item Row
    @ViewBuilder
    private func columnItemRow(item: MillerColumnItem, colIndex: Int) -> some View {
        let isSelectedInHierarchy = (colIndex + 1 < columnPaths.count && columnPaths[colIndex + 1].path == item.url.path) || selectedFileURL?.path == item.url.path

        Button(action: {
            HapticFeedback.selection()
            if item.isDirectory {
                withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
                    columnPaths = Array(columnPaths.prefix(colIndex + 1))
                    columnPaths.append(item.url)
                    selectedFileURL = nil
                }
            } else {
                withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
                    columnPaths = Array(columnPaths.prefix(colIndex + 1))
                    selectedFileURL = item.url
                    onSelectFile?(item.url)
                }
            }
        }) {
            HStack(spacing: 6) {
                Image(nsImage: item.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 15, height: 15)

                Text(item.name)
                    .font(.system(size: 11, weight: isSelectedInHierarchy ? .semibold : .regular))
                    .foregroundColor(isSelectedInHierarchy ? .white : .white.opacity(0.88))
                    .lineLimit(1)
                    .truncationMode(.middle)

                Spacer()

                if item.isDirectory {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(isSelectedInHierarchy ? .cyan : .white.opacity(0.35))
                } else {
                    Text(item.formattedSize)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.white.opacity(0.40))
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .fill(isSelectedInHierarchy ? Color.cyan.opacity(0.24) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .stroke(isSelectedInHierarchy ? Color.cyan.opacity(0.55) : Color.clear, lineWidth: 0.6)
            )
        }
        .buttonStyle(.plain)
        .contextMenu {
            if !item.isDirectory {
                Button(action: {
                    onOpenFile?(item.url)
                }) {
                    Label("Open in Editor & Preview", systemImage: "chevron.left.forwardslash.chevron.right")
                }
                Button(action: {
                    NSWorkspace.shared.open(item.url)
                }) {
                    Label("Open with System Default", systemImage: "arrow.up.forward.app")
                }
                Divider()
            }
            Button(action: {
                NSWorkspace.shared.activateFileViewerSelecting([item.url])
            }) {
                Label("Show in Finder", systemImage: "folder")
            }
            Button(action: {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(item.url.path, forType: .string)
            }) {
                Label("Copy Path", systemImage: "doc.on.doc")
            }
        }
    }

    // MARK: - 🔍 Scrollable Preview Column
    private var scrollablePreviewColumn: some View {
        VStack(spacing: 0) {
            // Preview Header with Tab Switcher if live creation is present
            HStack {
                if liveCreation != nil {
                    Picker("", selection: $previewModeTab) {
                        ForEach(PreviewTab.allCases) { tab in
                            Text(tab.rawValue).tag(tab)
                        }
                    }
                    .pickerStyle(.segmented)
                    .controlSize(.small)
                } else {
                    Text("QUICKLOOK PREVIEW")
                        .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.45))
                    Spacer()
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.03))

            Divider().background(Color.white.opacity(0.08))

            // Body of Preview Column
            if previewModeTab == .liveRender, let creation = liveCreation {
                liveRenderPreviewPane(creation: creation)
            } else if let fileURL = selectedFileURL {
                fileContentPreviewPane(url: fileURL)
            } else if let creation = liveCreation {
                liveRenderPreviewPane(creation: creation)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.3))
                    Text("Select a file to inspect")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .background(Color(red: 0.08, green: 0.09, blue: 0.11).opacity(0.95))
    }

    // MARK: - 🎨 Live AI Creation Render Pane
    private func liveRenderPreviewPane(creation: (title: String, html: String, fileURL: URL?)) -> some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.yellow)
                    .font(.system(size: 11))
                Text(creation.title)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Spacer()
                Text("LIVE STREAM")
                    .font(.system(size: 7.5, weight: .heavy, design: .monospaced))
                    .foregroundColor(.green)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1.5)
                    .background(Capsule().fill(Color.green.opacity(0.18)))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color.black.opacity(0.3))

            // Live WebKit View
            MillerWebKitLivePreview(htmlContent: creation.html)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Bottom Actions
            HStack(spacing: 6) {
                Button(action: {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("NexusFocusGenieSearchBarWithMode"),
                        object: "Refactor this creation \(creation.title): "
                    )
                }) {
                    Label("Ask Genie", systemImage: "sparkles")
                        .font(.system(size: 10, weight: .semibold))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.cyan.opacity(0.2)))
                .overlay(Capsule().stroke(Color.cyan.opacity(0.4), lineWidth: 0.6))

                Spacer()

                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(creation.html, forType: .string)
                    HapticFeedback.selection()
                }) {
                    Label("Copy Code", systemImage: "doc.on.doc")
                        .font(.system(size: 10, weight: .medium))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.white.opacity(0.08)))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.35))
        }
    }

    // MARK: - 📜 File Content Preview Pane
    private func fileContentPreviewPane(url: URL) -> some View {
        VStack(spacing: 0) {
            // File Metadata Card
            VStack(spacing: 4) {
                Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 36, height: 36)

                Text(url.lastPathComponent)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)

                let values = try? url.resourceValues(forKeys: [.fileSizeKey, .contentModificationDateKey])
                let size = ByteCountFormatter.string(fromByteCount: Int64(values?.fileSize ?? 0), countStyle: .file)
                Text("\(size) • \(url.pathExtension.uppercased())")
                    .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.55))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(Color.white.opacity(0.03))

            Divider().background(Color.white.opacity(0.08))

            // Scrollable text/code preview
            ScrollView([.vertical, .horizontal], showsIndicators: true) {
                let content = (try? String(contentsOf: url, encoding: .utf8)) ?? "(Binary or unreadable file)"
                Text(content)
                    .font(.system(size: 10.5, design: .monospaced))
                    .foregroundColor(.white.opacity(0.85))
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider().background(Color.white.opacity(0.08))

            // Quick Actions Bar
            HStack(spacing: 6) {
                Button(action: {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("NexusFocusGenieSearchBarWithMode"),
                        object: "Analyze file \(url.lastPathComponent): "
                    )
                }) {
                    Label("Ask Genie", systemImage: "sparkles")
                        .font(.system(size: 10, weight: .semibold))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.cyan.opacity(0.20)))
                .overlay(Capsule().stroke(Color.cyan.opacity(0.45), lineWidth: 0.6))

                Button(action: {
                    onOpenFile?(url)
                }) {
                    Label("Editor", systemImage: "chevron.left.forwardslash.chevron.right")
                        .font(.system(size: 10, weight: .semibold))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.orange.opacity(0.22)))
                .overlay(Capsule().stroke(Color.orange.opacity(0.48), lineWidth: 0.6))
                .help("Open and edit in Genie Native Editor & Shared Previewer")

                // Trash Airlock Promote
                Button(action: {
                    Task {
                        _ = try? GenieTrashAirlockGateway.shared.promoteToDesktop(airlockFileName: url.lastPathComponent)
                        HapticFeedback.selection()
                    }
                }) {
                    Label("Airlock", systemImage: "arrow.up.circle.fill")
                        .font(.system(size: 10, weight: .medium))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.yellow.opacity(0.18)))
                .overlay(Capsule().stroke(Color.yellow.opacity(0.45), lineWidth: 0.6))
                .help("Atomic zero-copy promotion to ~/Desktop via Trash airlock")

                Spacer()

                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(url.path, forType: .string)
                    HapticFeedback.selection()
                }) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 10))
                }
                .buttonStyle(.plain)
                .help("Copy Path")
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.35))
        }
    }

    // MARK: - 📊 Finder Status Bar
    private var finderStatusBar: some View {
        HStack {
            if let current = columnPaths.last {
                Text(current.path)
                    .font(.system(size: 9.5, design: .monospaced))
                    .foregroundColor(.white.opacity(0.55))
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer()
            Text("\(columnPaths.count) Columns Unfolded")
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundColor(.cyan)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color.black.opacity(0.35))
    }

    // MARK: - Helper Methods
    private func loadItems(for url: URL) -> [MillerColumnItem] {
        let keys: [URLResourceKey] = [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey]
        guard let urls = try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: keys, options: [.skipsHiddenFiles]) else {
            return []
        }

        return urls.map { MillerColumnItem(url: $0) }
            .sorted { lhs, rhs in
                if lhs.isDirectory != rhs.isDirectory {
                    return lhs.isDirectory && !rhs.isDirectory
                }
                return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }
    }

    private func navigateBack() {
        if columnPaths.count > 1 {
            withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
                columnPaths.removeLast()
                selectedFileURL = nil
            }
        }
    }

    private func refreshCurrent() {
        let current = columnPaths
        columnPaths = []
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            columnPaths = current
        }
    }
}

// MARK: - 🌐 Embedded WebKit Live Preview for Miller Columns
public struct MillerWebKitLivePreview: NSViewRepresentable {
    public let htmlContent: String

    public func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let wv = WKWebView(frame: .zero, configuration: config)
        wv.setValue(false, forKey: "drawsBackground")
        return wv
    }

    public func updateNSView(_ nsView: WKWebView, context: Context) {
        nsView.loadHTMLString(htmlContent, baseURL: nil)
    }
}
