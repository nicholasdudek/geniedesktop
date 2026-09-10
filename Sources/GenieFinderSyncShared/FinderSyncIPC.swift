import Foundation

/// Shared constants and IPC helpers for talking between the GenieFinderSync
/// Finder Sync extension (its own process) and the main Genie host app.
///
/// Both processes are sandboxed separately, so state does not pass in memory —
/// it goes through the shared App Group container's UserDefaults suite, with a
/// Distributed Notification used only as a "go read the new value" wakeup.
public enum FinderSyncIPC {
    /// Must match the "com.apple.security.application-groups" entitlement on
    /// BOTH the host app and the extension, and be registered on the Apple
    /// Developer portal for the provisioning profile used to sign them.
    public static let appGroupIdentifier = "group.com.nicholasdudek.genie"

    public static let hostBundleIdentifier = "com.nicholasdudek.genie"

    public static let notifyOpenRequest = "com.nicholasdudek.genie.findersync.openRequest"
    public static let notifyRefreshBadges = "com.nicholasdudek.genie.findersync.refreshBadges"

    static let defaultsKeyPendingRequest = "findersync.pendingRequest"
    static let defaultsKeyBadgeMap = "findersync.badgeMap"
    static let defaultsKeyWatchedFolders = "findersync.watchedFolders"

    public static var sharedDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }
}

/// What the user (or the toolbar button) asked Finder to tell Genie.
public enum GenieFinderIntent: String, Codable {
    case askAboutSelection
    case openWorkspace
    case openToolbarPanel
}

public struct GenieFinderRequest: Codable {
    public let id: UUID
    public let intent: GenieFinderIntent
    public let itemPaths: [String]
    public let containerPath: String?
    public let createdAt: Date

    public init(intent: GenieFinderIntent, itemPaths: [String], containerPath: String?) {
        self.id = UUID()
        self.intent = intent
        self.itemPaths = itemPaths
        self.containerPath = containerPath
        self.createdAt = Date()
    }
}

/// Badge overlays Genie can stamp on files/folders inside the extension's
/// observed directories. Only the extension process may call
/// FIFinderSyncController's badge APIs, so the host publishes this map and
/// the extension re-reads it whenever it's told to refresh.
public enum GenieFinderBadge: String, Codable, CaseIterable {
    case managed
    case indexed
    case flagged

    public var badgeIdentifier: String { "com.nicholasdudek.genie.badge.\(rawValue)" }

    public var label: String {
        switch self {
        case .managed: return "Managed by Genie"
        case .indexed: return "Indexed by Genie"
        case .flagged: return "Flagged by Genie"
        }
    }

    public var symbolName: String {
        switch self {
        case .managed: return "sparkles"
        case .indexed: return "text.magnifyingglass"
        case .flagged: return "star.fill"
        }
    }
}

/// Read/write helpers over the shared App Group defaults suite. Both the
/// extension and the host app link this same file, so the key names and
/// encoding can never drift between the two processes.
public enum FinderSyncStore {
    public static func writeRequest(_ request: GenieFinderRequest) {
        guard let defaults = FinderSyncIPC.sharedDefaults,
              let data = try? JSONEncoder().encode(request) else { return }
        defaults.set(data, forKey: FinderSyncIPC.defaultsKeyPendingRequest)
        DistributedNotificationCenter.default().postNotificationName(
            Notification.Name(FinderSyncIPC.notifyOpenRequest),
            object: nil, userInfo: nil, deliverImmediately: true
        )
    }

    public static func readPendingRequest() -> GenieFinderRequest? {
        guard let defaults = FinderSyncIPC.sharedDefaults,
              let data = defaults.data(forKey: FinderSyncIPC.defaultsKeyPendingRequest) else { return nil }
        return try? JSONDecoder().decode(GenieFinderRequest.self, from: data)
    }

    public static func clearPendingRequest() {
        FinderSyncIPC.sharedDefaults?.removeObject(forKey: FinderSyncIPC.defaultsKeyPendingRequest)
    }

    public static func writeBadgeMap(_ map: [String: GenieFinderBadge]) {
        guard let defaults = FinderSyncIPC.sharedDefaults,
              let data = try? JSONEncoder().encode(map) else { return }
        defaults.set(data, forKey: FinderSyncIPC.defaultsKeyBadgeMap)
        DistributedNotificationCenter.default().postNotificationName(
            Notification.Name(FinderSyncIPC.notifyRefreshBadges),
            object: nil, userInfo: nil, deliverImmediately: true
        )
    }

    public static func readBadgeMap() -> [String: GenieFinderBadge] {
        guard let defaults = FinderSyncIPC.sharedDefaults,
              let data = defaults.data(forKey: FinderSyncIPC.defaultsKeyBadgeMap),
              let map = try? JSONDecoder().decode([String: GenieFinderBadge].self, from: data) else { return [:] }
        return map
    }

    public static func writeWatchedFolders(_ paths: [String]) {
        FinderSyncIPC.sharedDefaults?.set(paths, forKey: FinderSyncIPC.defaultsKeyWatchedFolders)
    }

    public static func readWatchedFolders() -> [String] {
        FinderSyncIPC.sharedDefaults?.stringArray(forKey: FinderSyncIPC.defaultsKeyWatchedFolders) ?? []
    }
}
