import Foundation
import AppKit

public enum AgentSpaceType: String, Codable, CaseIterable {
    case missionControl = "Mission Control"
    case vscodeEditor = "VS Code Editor Agent"
    case webBrowser = "Browser Research Agent"
    case terminalSystem = "Terminal & Build Agent"
    case reviewGating = "Human Review & Audit"
    case custom = "Custom Agent"

    public var icon: String {
        switch self {
        case .missionControl: return "shield.lefthalf.filled"
        case .vscodeEditor: return "chevron.left.forwardslash.chevron.right"
        case .webBrowser: return "safari.fill"
        case .terminalSystem: return "terminal.fill"
        case .reviewGating: return "checkmark.shield.fill"
        case .custom: return "cpu.fill"
        }
    }
}

public enum AgentWorkStatus: String, Codable, CaseIterable {
    case idle = "Idle"
    case running = "Active / Running"
    case awaitingApproval = "Awaiting Approval"
    case completed = "Completed"

    public var badgeColorName: String {
        switch self {
        case .idle: return "gray"
        case .running: return "green"
        case .awaitingApproval: return "orange"
        case .completed: return "cyan"
        }
    }
}

public struct AgentVirtualSpace: Identifiable, Codable, Hashable {
    public let id: String
    public var name: String
    public var path: String
    public var createdAt: Date
    public var userAccount: String // "Current User" or "genie-agent"
    public var notes: String
    public var assignedDesktopIndex: Int
    public var spatialSlot: Int // 1..9 on the 3x3 plane, with 5 as center
    public var agentType: AgentSpaceType
    public var status: AgentWorkStatus
    public var activeTask: String
    public var assignedTools: [String]

    enum CodingKeys: String, CodingKey {
        case id, name, path, createdAt, userAccount, notes
        case assignedDesktopIndex, spatialSlot, agentType, status, activeTask, assignedTools
    }

    public init(
        id: String = UUID().uuidString,
        name: String,
        path: String,
        createdAt: Date = Date(),
        userAccount: String = "Current User",
        notes: String = "",
        assignedDesktopIndex: Int = 1,
        spatialSlot: Int = 5,
        agentType: AgentSpaceType = .custom,
        status: AgentWorkStatus = .idle,
        activeTask: String = "",
        assignedTools: [String] = []
    ) {
        self.id = id
        self.name = name
        self.path = path
        self.createdAt = createdAt
        self.userAccount = userAccount
        self.notes = notes
        self.assignedDesktopIndex = assignedDesktopIndex
        self.spatialSlot = spatialSlot
        self.agentType = agentType
        self.status = status
        self.activeTask = activeTask
        self.assignedTools = assignedTools
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.path = try container.decode(String.self, forKey: .path)
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        self.userAccount = try container.decodeIfPresent(String.self, forKey: .userAccount) ?? NSUserName()
        self.notes = try container.decodeIfPresent(String.self, forKey: .notes) ?? ""
        self.assignedDesktopIndex = try container.decodeIfPresent(Int.self, forKey: .assignedDesktopIndex) ?? 1
        self.spatialSlot = try container.decodeIfPresent(Int.self, forKey: .spatialSlot) ?? 5
        self.agentType = try container.decodeIfPresent(AgentSpaceType.self, forKey: .agentType) ?? .custom
        self.status = try container.decodeIfPresent(AgentWorkStatus.self, forKey: .status) ?? .idle
        self.activeTask = try container.decodeIfPresent(String.self, forKey: .activeTask) ?? ""
        self.assignedTools = try container.decodeIfPresent([String].self, forKey: .assignedTools) ?? []
    }
}

@MainActor
public final class AgentVirtualSpaceManager: ObservableObject {
    public static let shared = AgentVirtualSpaceManager()

    @Published public var spaces: [AgentVirtualSpace] = []
    @Published public var activeSpaceId: String = "center-mission-control"

    private let storeKey = "genie.agent.virtualSpaces"
    private let activeKey = "genie.agent.activeVirtualSpaceId"

    public static var defaultRootDirectory: String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return "\(home)/.genie/spaces"
    }

    public static var sharedMultiUserRootDirectory: String {
        return GenieCapabilities.sharedSupportDirectory.appendingPathComponent("spaces").path
    }

    public var activeSpace: AgentVirtualSpace? {
        spaces.first(where: { $0.id == activeSpaceId }) ?? spaces.first
    }

    private init() {
        loadSpaces()
    }

    public func loadSpaces() {
        if let data = UserDefaults.standard.data(forKey: storeKey),
           let decoded = try? JSONDecoder().decode([AgentVirtualSpace].self, from: data),
           decoded.contains(where: { $0.agentType == .vscodeEditor || $0.agentType == .webBrowser }) {
            self.spaces = decoded
        } else {
            // Seed multi-agent desktop spaces
            seedDefaultAgentSpaces()
        }

        if let savedActive = UserDefaults.standard.string(forKey: activeKey),
           spaces.contains(where: { $0.id == savedActive }) {
            self.activeSpaceId = savedActive
        } else {
            self.activeSpaceId = spaces.first?.id ?? "center-mission-control"
        }
    }

    public func seedDefaultAgentSpaces() {
        var seeded: [AgentVirtualSpace] = []

        // 1. Center Desktop: Mission Control & Desktop Views Center
        let centerPath = "\(Self.defaultRootDirectory)/center"
        try? FileManager.default.createDirectory(atPath: centerPath, withIntermediateDirectories: true)
        seeded.append(AgentVirtualSpace(
            id: "center-mission-control",
            name: "Desktop Views Center 🛸",
            path: centerPath,
            userAccount: NSUserName(),
            notes: "Central observation post monitoring all agent desktops simultaneously.",
            assignedDesktopIndex: 1,
            spatialSlot: 5,
            agentType: .missionControl,
            status: .idle,
            activeTask: "Observing all agent desktops from center viewport",
            assignedTools: ["read_ui", "desktop_agent", "app_doc"]
        ))

        // 2. Desktop 2: VS Code Editor Agent
        let vscodePath = "\(Self.defaultRootDirectory)/vscode_editor"
        try? FileManager.default.createDirectory(atPath: vscodePath, withIntermediateDirectories: true)
        seeded.append(AgentVirtualSpace(
            id: "agent-vscode-editor",
            name: "VS Code Editor Agent 💻",
            path: vscodePath,
            userAccount: NSUserName(),
            notes: "Dedicated desktop workspace for autonomous code editing and IDE toolchains.",
            assignedDesktopIndex: 2,
            spatialSlot: 2,
            agentType: .vscodeEditor,
            status: .idle,
            activeTask: "Autonomous code editing, refactoring & diagnostics",
            assignedTools: ["list_files", "read_file", "search_files", "edit_file", "write_file", "merge_files", "run_command", "polyglot_code"]
        ))

        // 3. Desktop 3: Browser Research Agent
        let browserPath = "\(Self.defaultRootDirectory)/browser_research"
        try? FileManager.default.createDirectory(atPath: browserPath, withIntermediateDirectories: true)
        seeded.append(AgentVirtualSpace(
            id: "agent-web-browser",
            name: "Browser Research Agent 🌐",
            path: browserPath,
            userAccount: NSUserName(),
            notes: "Dedicated desktop workspace for WebKit/Chrome research and DOM element automation.",
            assignedDesktopIndex: 3,
            spatialSlot: 3,
            agentType: .webBrowser,
            status: .idle,
            activeTask: "Web navigation, online documentation & DOM inspection",
            assignedTools: ["desktop_agent", "spatial_dom", "read_ui", "copy_text", "paste_text", "app_doc"]
        ))

        // 4. Desktop 4: Terminal & Build Agent
        let terminalPath = "\(Self.defaultRootDirectory)/terminal_build"
        try? FileManager.default.createDirectory(atPath: terminalPath, withIntermediateDirectories: true)
        seeded.append(AgentVirtualSpace(
            id: "agent-terminal-ci",
            name: "Terminal & Build Agent ⚡️",
            path: terminalPath,
            userAccount: NSUserName(),
            notes: "Dedicated desktop workspace for compilation, process spawning and automated tests.",
            assignedDesktopIndex: 4,
            spatialSlot: 4,
            agentType: .terminalSystem,
            status: .idle,
            activeTask: "Background compilation, automated tests & process runner",
            assignedTools: ["run_command", "agent_network", "airdrop"]
        ))

        self.spaces = seeded
        self.activeSpaceId = "center-mission-control"
        saveSpaces()
    }

    public func spaceForDesktop(_ index: Int) -> AgentVirtualSpace? {
        spaces.first(where: { $0.assignedDesktopIndex == index })
    }

    public func updateAgentStatus(spaceId: String, status: AgentWorkStatus, activeTask: String? = nil) {
        if let idx = spaces.firstIndex(where: { $0.id == spaceId }) {
            spaces[idx].status = status
            if let task = activeTask {
                spaces[idx].activeTask = task
            }
            saveSpaces()
            objectWillChange.send()
        }
    }

    public func assignAgentToDesktop(spaceId: String, desktopIndex: Int) {
        if let idx = spaces.firstIndex(where: { $0.id == spaceId }) {
            spaces[idx].assignedDesktopIndex = desktopIndex
            saveSpaces()
            objectWillChange.send()
        }
    }

    public func createSpace(name: String, userAccount: String = NSUserName(), customPath: String? = nil, assignedDesktopIndex: Int = 1, agentType: AgentSpaceType = .custom) -> AgentVirtualSpace {
        let cleanSlug = name.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
        let spaceId = cleanSlug.isEmpty ? "space-\(UUID().uuidString.prefix(6))" : cleanSlug
        
        let path = customPath ?? "\(Self.defaultRootDirectory)/\(spaceId)"
        try? FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true)

        let newSpace = AgentVirtualSpace(
            id: spaceId,
            name: name,
            path: path,
            createdAt: Date(),
            userAccount: userAccount,
            notes: "Virtual environment created for \(name)",
            assignedDesktopIndex: assignedDesktopIndex,
            spatialSlot: 1,
            agentType: agentType,
            status: .idle,
            activeTask: "Ready",
            assignedTools: []
        )

        spaces.append(newSpace)
        activeSpaceId = newSpace.id
        saveSpaces()
        return newSpace
    }

    public func deleteSpace(id: String) {
        guard id != "center-mission-control" else { return } // Protect center mission control
        spaces.removeAll(where: { $0.id == id })
        if activeSpaceId == id {
            activeSpaceId = spaces.first?.id ?? "center-mission-control"
        }
        saveSpaces()
    }

    public func selectSpace(id: String) {
        if spaces.contains(where: { $0.id == id }) {
            activeSpaceId = id
            UserDefaults.standard.set(id, forKey: activeKey)
        }
    }

    private func saveSpaces() {
        if let encoded = try? JSONEncoder().encode(spaces) {
            UserDefaults.standard.set(encoded, forKey: storeKey)
        }
        UserDefaults.standard.set(activeSpaceId, forKey: activeKey)
    }

    // MARK: - 🔱 Zero-Copy GPU Frame Fork for Isolated Agent Workspaces
    @Published public var activeGPUForkedFrame: GenieForkedFrame? = nil
    @Published public var isGPUVisualStreamActive: Bool = false

    public func updateActiveGPUFrame(_ frame: GenieForkedFrame) {
        self.activeGPUForkedFrame = frame
        self.isGPUVisualStreamActive = true
    }

    public func clearActiveGPUFrame() {
        self.activeGPUForkedFrame = nil
        self.isGPUVisualStreamActive = false
    }
}
