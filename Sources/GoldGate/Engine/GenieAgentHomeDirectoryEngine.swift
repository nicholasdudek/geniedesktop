import Foundation
import AppKit

/// AgentProfile
/// Metadata defining a registered Genie autonomous agent.
public struct AgentProfile: Codable, Identifiable, Hashable, Sendable {
    public let id: String
    public var name: String
    public var role: String
    public var rootPath: String
    public var homePath: String
    public var workspacePath: String
    public var artifactsPath: String
    public var logsPath: String
    public var reviewPath: String
    public var memoryLimitMB: Int
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: String,
        name: String,
        role: String,
        rootPath: String,
        memoryLimitMB: Int = 4096,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.role = role
        self.rootPath = rootPath
        self.homePath = "\(rootPath)/home"
        self.workspacePath = "\(rootPath)/workspace"
        self.artifactsPath = "\(rootPath)/artifacts"
        self.logsPath = "\(rootPath)/logs"
        self.reviewPath = "\(rootPath)/review"
        self.memoryLimitMB = memoryLimitMB
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

/// AgentReviewItem
/// Represents a pending code change, report, or deliverable awaiting human inspection.
public struct AgentReviewItem: Codable, Identifiable, Hashable, Sendable {
    public enum Status: String, Codable, Sendable {
        case pending = "pending"
        case approved = "approved"
        case rejected = "rejected"
    }

    public let id: String
    public let agentId: String
    public let title: String
    public let filename: String
    public let filePath: String
    public let summary: String
    public var status: Status
    public let timestamp: Date

    public init(
        id: String = UUID().uuidString,
        agentId: String,
        title: String,
        filename: String,
        filePath: String,
        summary: String,
        status: Status = .pending,
        timestamp: Date = Date()
    ) {
        self.id = id
        self.agentId = agentId
        self.title = title
        self.filename = filename
        self.filePath = filePath
        self.summary = summary
        self.status = status
        self.timestamp = timestamp
    }
}

/// GenieAgentHomeDirectoryEngine (Pillar 2 - Multi-Agent Home Directory & Review System)
///
/// Provisions and manages dedicated, isolated POSIX home directories for every agent
/// under `/Users/Shared/Genie/Agents/<agent_id>/` and runs the human review queue.
@MainActor
public final class GenieAgentHomeDirectoryEngine: ObservableObject {
    public static let shared = GenieAgentHomeDirectoryEngine()

    @Published public var registeredAgents: [AgentProfile] = []
    @Published public var activeAgent: AgentProfile?
    @Published public var pendingReviews: [AgentReviewItem] = []

    public static var agentsRootDirectory: String {
        GenieCapabilities.sharedSupportDirectory.appendingPathComponent("Agents").path
    }

    private var isSeeding = false

    private init() {
        ensureAgentsRootExists()
        loadRegisteredAgents()
    }

    public func ensureAgentsRootExists() {
        let fm = FileManager.default
        let path = Self.agentsRootDirectory
        if !fm.fileExists(atPath: path) {
            try? fm.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: [
                .posixPermissions: 0o777 // Read/write for user and agent processes
            ])
        }
    }

    // MARK: - Provisioning

    /// Provisions the complete 5-part home directory structure for an agent:
    /// `<Agents>/<agent_id>/{home, workspace, artifacts, logs, review}`
    public func provisionAgentHome(
        id: String,
        name: String,
        role: String = "Autonomous Operator",
        memoryLimitMB: Int = 4096
    ) throws -> AgentProfile {
        ensureAgentsRootExists()
        let fm = FileManager.default
        let root = "\(Self.agentsRootDirectory)/\(id)"

        let subdirs = ["home", "workspace", "artifacts", "logs", "review"]
        for sub in subdirs {
            let path = "\(root)/\(sub)"
            if !fm.fileExists(atPath: path) {
                try fm.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: [
                    .posixPermissions: 0o750
                ])
            }
        }

        // Initialize agent home dotfiles
        let profileScript = """
        # Genie Agent Environment: \(id)
        export AGENT_ID="\(id)"
        export AGENT_NAME="\(name)"
        export HOME="\(root)/home"
        export PATH="\(root)/home/.local/bin:/usr/local/bin:/usr/bin:/bin"
        alias ll="ls -la"
        """
        try? profileScript.write(toFile: "\(root)/home/.zprofile", atomically: true, encoding: .utf8)
        try? profileScript.write(toFile: "\(root)/home/.zshrc", atomically: true, encoding: .utf8)

        let profile = AgentProfile(
            id: id,
            name: name,
            role: role,
            rootPath: root,
            memoryLimitMB: memoryLimitMB
        )

        // Save agent_profile.json
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted
        if let data = try? jsonEncoder.encode(profile) {
            try? data.write(to: URL(fileURLWithPath: "\(root)/agent_profile.json"))
        }

        if !isSeeding {
            loadRegisteredAgents()
        }
        return profile
    }

    public func loadRegisteredAgents() {
        ensureAgentsRootExists()
        let fm = FileManager.default
        var loaded: [AgentProfile] = []

        if let contents = try? fm.contentsOfDirectory(atPath: Self.agentsRootDirectory) {
            for dir in contents {
                let profilePath = "\(Self.agentsRootDirectory)/\(dir)/agent_profile.json"
                if fm.fileExists(atPath: profilePath),
                   let data = try? Data(contentsOf: URL(fileURLWithPath: profilePath)),
                   let profile = try? JSONDecoder().decode(AgentProfile.self, from: data) {
                    loaded.append(profile)
                }
            }
        }

        if loaded.isEmpty && !isSeeding {
            isSeeding = true
            defer { isSeeding = false }
            // Seed primary agent
            if let primary = try? provisionAgentHome(
                id: "genie-primary",
                name: "Genie Primary Orchestrator",
                role: "Lead Multimodal Reasoning & System Supervisor"
            ) {
                loaded = [primary]
            }
        }

        self.registeredAgents = loaded.sorted(by: { $0.createdAt < $1.createdAt })

        let activeId = UserDefaults.standard.string(forKey: PrefKey.activeAgentId) ?? "genie-primary"
        self.activeAgent = self.registeredAgents.first(where: { $0.id == activeId }) ?? self.registeredAgents.first

        refreshPendingReviews()
    }

    public func setActiveAgent(id: String) {
        if let found = registeredAgents.first(where: { $0.id == id }) {
            self.activeAgent = found
            UserDefaults.standard.set(id, forKey: PrefKey.activeAgentId)
            refreshPendingReviews()
        }
    }

    // MARK: - Human Review Bridge

    /// Deposits a deliverable or proposed file change into the agent's review folder.
    public func depositForReview(
        agentId: String,
        title: String,
        content: String,
        filename: String,
        summary: String
    ) throws -> AgentReviewItem {
        guard let agent = registeredAgents.first(where: { $0.id == agentId }) ?? activeAgent else {
            throw NSError(domain: "GenieAgentHomeDirectoryEngine", code: 404, userInfo: [NSLocalizedDescriptionKey: "Agent not found"])
        }

        let filePath = "\(agent.reviewPath)/\(filename)"
        try content.write(toFile: filePath, atomically: true, encoding: .utf8)

        let item = AgentReviewItem(
            agentId: agent.id,
            title: title,
            filename: filename,
            filePath: filePath,
            summary: summary,
            status: .pending
        )

        // Save review manifest item
        let metaPath = "\(agent.reviewPath)/\(filename).meta.json"
        if let data = try? JSONEncoder().encode(item) {
            try? data.write(to: URL(fileURLWithPath: metaPath))
        }

        refreshPendingReviews()
        return item
    }

    public func refreshPendingReviews() {
        var items: [AgentReviewItem] = []
        let fm = FileManager.default

        for agent in registeredAgents {
            let path = agent.reviewPath
            if let files = try? fm.contentsOfDirectory(atPath: path) {
                for file in files where file.hasSuffix(".meta.json") {
                    let fullPath = "\(path)/\(file)"
                    if let data = try? Data(contentsOf: URL(fileURLWithPath: fullPath)),
                       let item = try? JSONDecoder().decode(AgentReviewItem.self, from: data) {
                        items.append(item)
                    }
                }
            }
        }
        self.pendingReviews = items.sorted(by: { $0.timestamp > $1.timestamp })
    }

    public func updateReviewStatus(item: AgentReviewItem, newStatus: AgentReviewItem.Status) {
        var updated = item
        updated.status = newStatus
        let metaPath = "\(item.filePath).meta.json"
        if let data = try? JSONEncoder().encode(updated) {
            try? data.write(to: URL(fileURLWithPath: metaPath))
        }
        refreshPendingReviews()
    }

    // MARK: - Finder Integration

    public func openAgentHomeInFinder(agentId: String) {
        if let agent = registeredAgents.first(where: { $0.id == agentId }) {
            NSWorkspace.shared.open(URL(fileURLWithPath: agent.rootPath))
        }
    }

    public func openAgentReviewInFinder(agentId: String) {
        if let agent = registeredAgents.first(where: { $0.id == agentId }) {
            NSWorkspace.shared.open(URL(fileURLWithPath: agent.reviewPath))
        }
    }
}
