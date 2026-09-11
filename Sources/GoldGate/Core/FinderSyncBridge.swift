import AppKit
import GenieFinderSyncShared

/// Host-side half of the GenieFinderSync extension conversation. The
/// extension runs in its own process and can't call into Genie directly, so
/// it drops a GenieFinderRequest into the shared App Group defaults and pings
/// us with a distributed notification; this reads it back out and routes it
/// into the existing Finder-style chat window.
@MainActor
final class FinderSyncBridge {
    static let shared = FinderSyncBridge()

    private var requestObserver: NSObjectProtocol?

    private init() {}

    func start() {
        guard requestObserver == nil else { return }
        requestObserver = DistributedNotificationCenter.default().addObserver(
            forName: Notification.Name(FinderSyncIPC.notifyOpenRequest),
            object: nil, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.handlePendingRequest()
            }
        }
        // Pick up anything Finder queued before Genie finished launching.
        handlePendingRequest()
    }

    func stop() {
        if let requestObserver {
            DistributedNotificationCenter.default().removeObserver(requestObserver)
        }
        requestObserver = nil
    }

    private func handlePendingRequest() {
        guard let request = FinderSyncStore.readPendingRequest() else { return }
        FinderSyncStore.clearPendingRequest()
        dispatch(request)
    }

    private func dispatch(_ request: GenieFinderRequest) {
        switch request.intent {
        case .askAboutSelection:
            FinderChatWindowManager.shared.show(tab: .chat)
            NotificationCenter.default.post(
                name: .genieFinderSyncDidRequestSelection,
                object: nil,
                userInfo: ["paths": request.itemPaths]
            )
        case .openWorkspace, .openToolbarPanel:
            FinderChatWindowManager.shared.show(tab: .chat)
            if let container = request.containerPath {
                NotificationCenter.default.post(
                    name: .genieFinderSyncDidRequestContainer,
                    object: nil,
                    userInfo: ["path": container]
                )
            }
        }
    }

    // MARK: - Publishing badge state back out to the extension

    /// Stamp (or clear, with badge == nil) a Finder badge on the given paths.
    /// Writes to the shared suite and wakes the extension so it re-reads it —
    /// only the extension process can actually call FIFinderSyncController.
    func markPaths(_ paths: [String], as badge: GenieFinderBadge?) {
        var map = FinderSyncStore.readBadgeMap()
        for path in paths {
            if let badge {
                map[path] = badge
            } else {
                map.removeValue(forKey: path)
            }
        }
        FinderSyncStore.writeBadgeMap(map)
    }

    /// Extra folders (beyond Home/Desktop/Documents/Downloads) the extension
    /// should watch for badge requests. Takes effect the next time the
    /// extension process is relaunched by Finder.
    func setWatchedFolders(_ paths: [String]) {
        FinderSyncStore.writeWatchedFolders(paths)
    }
}

extension Notification.Name {
    static let genieFinderSyncDidRequestSelection = Notification.Name("genie.findersync.didRequestSelection")
    static let genieFinderSyncDidRequestContainer = Notification.Name("genie.findersync.didRequestContainer")
}
