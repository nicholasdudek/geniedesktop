import Foundation
import AppKit
import GenieFinderSyncShared

// MARK: - JSON Permissions Authority for Autonomous Capabilities

public enum GeniePermissionCategory: String, Codable, CaseIterable, Sendable {
    case filesystem = "filesystem"
    case systemCommand = "system_command"
    case communication = "communication"
    case automation = "automation"
    case network = "network"
}

public enum GeniePermissionRiskLevel: String, Codable, CaseIterable, Sendable {
    case low = "low"
    case medium = "medium"
    case high = "high"
}

public enum GeniePermissionStatus: String, Codable, CaseIterable, Sendable {
    case pending = "pending"
    case approved = "approved"
    case denied = "denied"
}

public struct GeniePermissionRequest: Identifiable, Codable, Sendable {
    public let id: String
    public let timestamp: Date
    public let category: GeniePermissionCategory
    public let action: String
    public let target: String
    public let description: String
    public let riskLevel: GeniePermissionRiskLevel
    public var status: GeniePermissionStatus
    public var autoApproved: Bool

    public init(
        id: String = UUID().uuidString,
        timestamp: Date = Date(),
        category: GeniePermissionCategory,
        action: String,
        target: String,
        description: String,
        riskLevel: GeniePermissionRiskLevel = .medium,
        status: GeniePermissionStatus = .approved,
        autoApproved: Bool = true
    ) {
        self.id = id
        self.timestamp = timestamp
        self.category = category
        self.action = action
        self.target = target
        self.description = description
        self.riskLevel = riskLevel
        self.status = status
        self.autoApproved = autoApproved
    }

    public func toJSON() -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(self) else { return "{}" }
        return String(decoding: data, as: UTF8.self)
    }

    public static func fromJSON(_ jsonString: String) -> GeniePermissionRequest? {
        guard let data = jsonString.data(using: .utf8) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(GeniePermissionRequest.self, from: data)
    }
}

public final class GeniePermissionsAgent: ObservableObject, @unchecked Sendable {
    public static let shared = GeniePermissionsAgent()
    private let lock = NSLock()

    @Published public private(set) var auditLog: [GeniePermissionRequest] = []
    @Published public var autoApproveAll: Bool {
        didSet {
            UserDefaults.standard.set(autoApproveAll, forKey: "genie.permissions.autoApprove")
            FinderSyncIPC.sharedDefaults?.set(autoApproveAll, forKey: "genie.permissions.autoApprove")
        }
    }

    private var approvedPaths: Set<String> = []
    private var approvedActions: Set<String> = []

    private init() {
        let savedAuto = UserDefaults.standard.object(forKey: "genie.permissions.autoApprove") as? Bool ?? true
        self.autoApproveAll = savedAuto
    }

    /// Primary permission evaluation using structured JSON contract
    @discardableResult
    public func evaluateRequest(
        category: GeniePermissionCategory,
        action: String,
        target: String,
        description: String,
        riskLevel: GeniePermissionRiskLevel = .medium
    ) -> GeniePermissionRequest {
        lock.lock()
        let shouldApprove = autoApproveAll || approvedActions.contains("\(category.rawValue):\(action)") || approvedPaths.contains(target)

        let request = GeniePermissionRequest(
            category: category,
            action: action,
            target: target,
            description: description,
            riskLevel: riskLevel,
            status: shouldApprove ? .approved : .pending,
            autoApproved: autoApproveAll
        )

        if shouldApprove {
            approvedPaths.insert(target)
            approvedActions.insert("\(category.rawValue):\(action)")
        }
        lock.unlock()

        let reqCopy = request
        if Thread.isMainThread {
            self.auditLog.append(reqCopy)
            if self.auditLog.count > 100 { self.auditLog.removeFirst(self.auditLog.count - 100) }
            self.persistAuditLog()
        } else {
            DispatchQueue.main.async {
                self.auditLog.append(reqCopy)
                if self.auditLog.count > 100 { self.auditLog.removeFirst(self.auditLog.count - 100) }
                self.persistAuditLog()
            }
        }
        return request
    }

    /// Convenience evaluation returning whether action is approved
    public func evaluate(
        category: GeniePermissionCategory,
        action: String,
        target: String = "",
        description: String = "",
        riskLevel: GeniePermissionRiskLevel = .medium
    ) -> Bool {
        let req = evaluateRequest(category: category, action: action, target: target, description: description.isEmpty ? action : description, riskLevel: riskLevel)
        return req.status == .approved
    }

    /// Evaluates whether a file write target outside Desktop is permitted
    public func isFileWritePermitted(to url: URL) -> Bool {
        let path = url.standardizedFileURL.path
        let home = FileManager.default.homeDirectoryForCurrentUser.standardizedFileURL.path

        // Always allow Desktop
        if path.hasPrefix("\(home)/Desktop") { return true }

        // System binaries protection
        let forbidden = ["/System", "/usr", "/bin", "/sbin", "/Library/LaunchDaemons"]
        for prefix in forbidden where path == prefix || path.hasPrefix("\(prefix)/") {
            return false
        }

        // Check JSON permissions
        lock.lock()
        let isApproved = autoApproveAll || approvedPaths.contains(path)
        lock.unlock()
        if isApproved {
            return true
        }

        // Check if inside user's home directory (Documents, Downloads, Projects, etc.)
        if path.hasPrefix(home) {
            let request = evaluateRequest(
                category: .filesystem,
                action: "write_file",
                target: path,
                description: "Write file to user directory: \(url.lastPathComponent)",
                riskLevel: .medium
            )
            return request.status == .approved
        }

        return false
    }

    /// Approve an action or path explicitly via JSON policy string
    @discardableResult
    public func approveFromJSONPolicy(_ jsonString: String) -> Bool {
        guard let request = GeniePermissionRequest.fromJSON(jsonString) else { return false }
        lock.lock()
        approvedPaths.insert(request.target)
        approvedActions.insert("\(request.category.rawValue):\(request.action)")
        lock.unlock()

        var approvedReq = request
        approvedReq.status = .approved
        if Thread.isMainThread {
            self.auditLog.append(approvedReq)
            self.persistAuditLog()
        } else {
            DispatchQueue.main.async {
                self.auditLog.append(approvedReq)
                self.persistAuditLog()
            }
        }
        return true
    }

    private func persistAuditLog() {
        guard let defaults = FinderSyncIPC.sharedDefaults ?? Optional(UserDefaults.standard) else { return }
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(Array(auditLog.suffix(30))) {
            defaults.set(data, forKey: "genie.permissions.auditLog")
        }
    }
}
