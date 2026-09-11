import Foundation

public struct RuntimeConfig: Codable, Equatable, Sendable {
    public var id: String
    public var name: String
    public var description: String
    public var vcpu: Int
    public var ramMB: Int
    /// UI-only for v1 — see StationResources.diskGB.
    public var diskGB: Int
    public var imagePath: String

    public init(
        id: String = "rt-\(UUID().uuidString.prefix(8).lowercased())",
        name: String,
        description: String,
        vcpu: Int = 2,
        ramMB: Int = 4096,
        diskGB: Int = 32,
        imagePath: String = "GoldenImage_Native.raw"
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.vcpu = vcpu
        self.ramMB = ramMB
        self.diskGB = diskGB
        self.imagePath = imagePath
    }
}

public struct RuntimeInstance: Identifiable, Codable, Sendable {
    public let id: String
    public let config: RuntimeConfig
    public var status: Status
    public var createdAt: Date

    public init(
        id: String,
        config: RuntimeConfig,
        status: Status,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.config = config
        self.status = status
        self.createdAt = createdAt
    }
    
    public enum Status: String, Codable, Sendable {
        case provisioning, active, terminated, failed
    }
}

