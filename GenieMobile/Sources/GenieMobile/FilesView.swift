import SwiftUI
import UniformTypeIdentifiers

struct FilesView: View {
    @ObservedObject private var workspace = WorkspaceStore.shared
    @State private var showPicker = false
    @State private var pickerError: String?

    var body: some View {
        NavigationStack {
            Group {
                if let root = workspace.workspaceURL {
                    FolderBrowserView(directoryURL: root)
                        .navigationTitle(workspace.workspaceName)
                } else {
                    ContentUnavailableView {
                        Label("No Workspace", systemImage: "folder.badge.questionmark")
                    } description: {
                        Text("Pick a folder to browse, edit, and let Genie's chat read and write files in it.")
                    } actions: {
                        Button("Choose Folder") { showPicker = true }
                            .buttonStyle(.borderedProminent)
                    }
                    .navigationTitle("Files")
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showPicker = true }) {
                        Image(systemName: "folder.badge.gearshape")
                    }
                    .help("Change workspace folder")
                }
            }
        }
        .fileImporter(isPresented: $showPicker, allowedContentTypes: [.folder]) { result in
            switch result {
            case .success(let url): workspace.adopt(url)
            case .failure(let error): pickerError = error.localizedDescription
            }
        }
        .alert("Couldn't open folder", isPresented: .constant(pickerError != nil), presenting: pickerError) { _ in
            Button("OK") { pickerError = nil }
        } message: { message in
            Text(message)
        }
    }
}

/// One directory level. Subfolders push another instance of this view;
/// files push EditorView. Recurses to whatever depth the workspace has.
private struct FolderBrowserView: View {
    let directoryURL: URL

    @State private var entries: [URL] = []
    @State private var errorMessage: String?

    var body: some View {
        List {
            if let errorMessage {
                Text(errorMessage).foregroundStyle(.red).font(.footnote)
            }
            ForEach(entries, id: \.self) { url in
                if url.hasDirectoryPath {
                    NavigationLink {
                        FolderBrowserView(directoryURL: url)
                            .navigationTitle(url.lastPathComponent)
                    } label: {
                        Label(url.lastPathComponent, systemImage: "folder.fill")
                    }
                } else {
                    NavigationLink(value: url) {
                        Label(url.lastPathComponent, systemImage: "doc.text")
                    }
                }
            }
        }
        .navigationDestination(for: URL.self) { EditorView(fileURL: $0) }
        .refreshable { reload() }
        .onAppear(perform: reload)
    }

    private func reload() {
        do {
            entries = try FileManager.default
                .contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: [.isDirectoryKey])
                .filter { !$0.lastPathComponent.hasPrefix(".") }
                .sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
            errorMessage = nil
        } catch {
            errorMessage = "Couldn't list this folder: \(error.localizedDescription)"
        }
    }
}
