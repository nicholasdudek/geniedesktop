import Foundation

/// iOS has no ambient filesystem access — a workspace is a folder the user
/// explicitly picked via the system document picker, kept alive across
/// launches as a security-scoped bookmark. Every read/write through
/// AgentTools (during a chat run) or the Files/Editor screens goes through
/// the same access-scoped URL this hands out.
@MainActor
final class WorkspaceStore: ObservableObject {
    static let shared = WorkspaceStore()

    @Published private(set) var workspaceURL: URL?
    @Published private(set) var workspaceName: String = ""

    private static let bookmarkKey = "genie.mobile.workspaceBookmark"
    private var isAccessing = false

    private init() {
        resolveBookmark()
    }

    func adopt(_ pickedURL: URL) {
        stopAccessing()
        guard pickedURL.startAccessingSecurityScopedResource() else { return }
        isAccessing = true
        workspaceURL = pickedURL
        workspaceName = pickedURL.lastPathComponent
        if let bookmark = try? pickedURL.bookmarkData() {
            UserDefaults.standard.set(bookmark, forKey: Self.bookmarkKey)
        }
    }

    private func resolveBookmark() {
        guard let data = UserDefaults.standard.data(forKey: Self.bookmarkKey) else { return }
        var stale = false
        guard let url = try? URL(resolvingBookmarkData: data, bookmarkDataIsStale: &stale),
              url.startAccessingSecurityScopedResource() else { return }
        isAccessing = true
        workspaceURL = url
        workspaceName = url.lastPathComponent
    }

    private func stopAccessing() {
        if isAccessing { workspaceURL?.stopAccessingSecurityScopedResource() }
        isAccessing = false
    }
    // No deinit: this is a process-lifetime singleton (.shared), so it never
    // actually deallocates — a deinit here would also need to be nonisolated,
    // unable to touch the main-actor-isolated workspaceURL it would need to close.
}
