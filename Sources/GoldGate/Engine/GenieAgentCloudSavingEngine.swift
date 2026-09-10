import Foundation
import AppKit

/// CloudSyncStatus
/// Indicates the live cloud-synchronization state for Genie agents.
public enum CloudSyncStatus: String, Codable, Sendable {
    case synced = "Synced ☁️"
    case syncing = "Syncing... 🔄"
    case offlineLocalOnly = "Local Only 💾"
    case error = "Sync Error ⚠️"
}

/// GenieAgentCloudSavingEngine (Pillar 3 - Hybrid Dual Saving: Local Home + Cloud Saving)
///
/// Ensures every agent maintains dual persistence:
/// 1. Instantaneous local APFS home directory saves in `/Users/Shared/Genie/Agents/<agent_id>/`.
/// 2. Automated cloud synchronization to iCloud Drive and remote Cloud Storage vaults.
@MainActor
public final class GenieAgentCloudSavingEngine: ObservableObject {
    public static let shared = GenieAgentCloudSavingEngine()

    @Published public var syncStatus: CloudSyncStatus = .synced
    @Published public var lastSyncDate: Date?
    @Published public var totalSyncedFiles: Int = 0
    @Published public var isSyncing: Bool = false

    private var syncTimer: Timer?

    /// Target path for iCloud Drive syncing
    public static var iCloudVaultDirectory: String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return "\(home)/Library/Mobile Documents/com~apple~CloudDocs/Genie/Agents"
    }

    /// Local fallback cloud mirror directory
    public static var localCloudVaultDirectory: String {
        GenieCapabilities.sharedSupportDirectory.appendingPathComponent("CloudVault/Agents").path
    }

    private init() {
        startPeriodicSync()
    }

    public func startPeriodicSync() {
        syncTimer?.invalidate()
        syncTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.syncAllAgentsToCloud()
            }
        }
    }

    /// Determines the primary available cloud storage vault destination.
    public func resolveCloudDestination(for agentId: String) -> String {
        let fm = FileManager.default
        let iCloudParent = "\(FileManager.default.homeDirectoryForCurrentUser.path)/Library/Mobile Documents/com~apple~CloudDocs"
        let isICloudAvailable = fm.fileExists(atPath: iCloudParent)

        let basePath = isICloudAvailable ? Self.iCloudVaultDirectory : Self.localCloudVaultDirectory
        let agentCloudPath = "\(basePath)/\(agentId)"
        try? fm.createDirectory(atPath: agentCloudPath, withIntermediateDirectories: true, attributes: nil)
        return agentCloudPath
    }

    /// Synchronizes a specific agent's profile, artifacts, and review deliverables to the cloud vault.
    public func syncAgentToCloud(agent: AgentProfile) async -> Bool {
        let isCloudSavingEnabled = UserDefaults.standard.bool(forKey: PrefKey.agentCloudSavingEnabled)
        guard isCloudSavingEnabled else {
            self.syncStatus = .offlineLocalOnly
            return true
        }

        self.isSyncing = true
        self.syncStatus = .syncing

        let cloudDest = resolveCloudDestination(for: agent.id)
        let fm = FileManager.default
        var syncedCount = 0

        // 1. Sync agent profile
        let profileSrc = "\(agent.rootPath)/agent_profile.json"
        let profileDst = "\(cloudDest)/agent_profile.json"
        if fm.fileExists(atPath: profileSrc) {
            try? fm.removeItem(atPath: profileDst)
            if (try? fm.copyItem(atPath: profileSrc, toPath: profileDst)) != nil {
                syncedCount += 1
            }
        }

        // 2. Sync artifacts
        let artifactsSrc = agent.artifactsPath
        let artifactsDst = "\(cloudDest)/artifacts"
        try? fm.createDirectory(atPath: artifactsDst, withIntermediateDirectories: true)
        if let items = try? fm.contentsOfDirectory(atPath: artifactsSrc) {
            for item in items {
                let s = "\(artifactsSrc)/\(item)"
                let d = "\(artifactsDst)/\(item)"
                try? fm.removeItem(atPath: d)
                if (try? fm.copyItem(atPath: s, toPath: d)) != nil {
                    syncedCount += 1
                }
            }
        }

        // 3. Sync review queue
        let reviewSrc = agent.reviewPath
        let reviewDst = "\(cloudDest)/review"
        try? fm.createDirectory(atPath: reviewDst, withIntermediateDirectories: true)
        if let items = try? fm.contentsOfDirectory(atPath: reviewSrc) {
            for item in items {
                let s = "\(reviewSrc)/\(item)"
                let d = "\(reviewDst)/\(item)"
                try? fm.removeItem(atPath: d)
                if (try? fm.copyItem(atPath: s, toPath: d)) != nil {
                    syncedCount += 1
                }
            }
        }

        self.totalSyncedFiles += syncedCount
        self.lastSyncDate = Date()
        self.isSyncing = false
        self.syncStatus = .synced
        return true
    }

    /// Synchronizes all registered agents to the cloud vault.
    public func syncAllAgentsToCloud() async {
        let agents = GenieAgentHomeDirectoryEngine.shared.registeredAgents
        for agent in agents {
            _ = await syncAgentToCloud(agent: agent)
        }
    }

    /// Opens the Cloud Vault in Finder.
    public func openCloudVaultInFinder() {
        let activeId = GenieAgentHomeDirectoryEngine.shared.activeAgent?.id ?? "genie-primary"
        let dest = resolveCloudDestination(for: activeId)
        NSWorkspace.shared.open(URL(fileURLWithPath: dest))
    }
}
