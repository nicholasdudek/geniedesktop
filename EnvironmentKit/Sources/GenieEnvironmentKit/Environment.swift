import Foundation

public enum JSONValue: Codable, Sendable, Equatable {
    case object([String: JSONValue]), array([JSONValue]), string(String), number(Double), bool(Bool), null
    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        if c.decodeNil() { self = .null }
        else if let v = try? c.decode(Bool.self) { self = .bool(v) }
        else if let v = try? c.decode(String.self) { self = .string(v) }
        else if let v = try? c.decode(Double.self) { self = .number(v) }
        else if let v = try? c.decode([String: JSONValue].self) { self = .object(v) }
        else { self = .array(try c.decode([JSONValue].self)) }
    }
    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        switch self {
        case .object(let v): try c.encode(v)
        case .array(let v): try c.encode(v)
        case .string(let v): try c.encode(v)
        case .number(let v): try c.encode(v)
        case .bool(let v): try c.encode(v)
        case .null: try c.encodeNil()
        }
    }
    public subscript(_ key: String) -> JSONValue? { if case .object(let v) = self { return v[key] }; return nil }
    public var string: String? { if case .string(let v) = self { return v }; return nil }
    public var number: Double? { if case .number(let v) = self { return v }; return nil }
    public var array: [JSONValue]? { if case .array(let v) = self { return v }; return nil }
    public var formatted: String {
        let encoder = JSONEncoder(); encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        return (try? String(decoding: encoder.encode(self), as: UTF8.self)) ?? "null"
    }
}

public struct EnvironmentSpec: Codable, Sendable, Equatable, Identifiable {
    public var id: UUID
    public var name: String
    public var vmID: UUID
    public var tools: [String]
    public init(id: UUID = UUID(), name: String, vmID: UUID, tools: [String] = ["browser", "filesystem", "shell", "python"]) {
        self.id = id; self.name = name; self.vmID = vmID; self.tools = tools
    }
}

public struct EnvironmentError: LocalizedError, Sendable {
    public let message: String
    public init(_ message: String) { self.message = message }
    public var errorDescription: String? { message }
}

public protocol EnvironmentTransport: Sendable {
    func request(vmID: UUID, payload: JSONValue) async throws -> JSONValue
}

/// The guest owns durable job state. This actor can be recreated without terminating jobs.
public actor EnvironmentManager {
    private let transport: any EnvironmentTransport
    private let directory: URL
    public init(directory: URL, transport: any EnvironmentTransport = UTMBackend()) throws {
        self.directory = directory; self.transport = transport
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }
    public func environments() throws -> [EnvironmentSpec] {
        try FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "json" }
            .map { try JSONDecoder().decode(EnvironmentSpec.self, from: Data(contentsOf: $0)) }
            .sorted { $0.name < $1.name }
    }
    public func open(_ id: UUID) throws -> EnvironmentSpec {
        try JSONDecoder().decode(EnvironmentSpec.self, from: Data(contentsOf: location(id)))
    }
    @discardableResult
    public func create(_ spec: EnvironmentSpec) async throws -> EnvironmentSpec {
        let data = try JSONEncoder().encode(spec)
        let value = try JSONDecoder().decode(JSONValue.self, from: data)
        _ = try await transport.request(vmID: spec.vmID, payload: .object(["op": .string("register"), "spec": value]))
        try data.write(to: location(spec.id), options: .atomic)
        return spec
    }
    public func submit(environment id: UUID, tool: String, input: JSONValue, idempotencyKey: String = UUID().uuidString) async throws -> JSONValue {
        let spec = try open(id)
        guard spec.tools.contains(String(tool.split(separator: ".").first ?? "")) else {
            throw EnvironmentError("Tool family is not enabled for this environment.")
        }
        return try await call(spec, op: "submit", fields: ["tool": .string(tool), "input": input, "key": .string(idempotencyKey)])
    }
    public func job(environment id: UUID, jobID: String) async throws -> JSONValue {
        try await call(open(id), op: "get", fields: ["job": .string(jobID)])
    }
    public func jobs(environment id: UUID) async throws -> JSONValue { try await call(open(id), op: "jobs") }
    public func cancel(environment id: UUID, jobID: String) async throws -> JSONValue {
        try await call(open(id), op: "cancel", fields: ["job": .string(jobID)])
    }
    public func events(environment id: UUID, after cursor: Int = 0) async throws -> JSONValue {
        try await call(open(id), op: "events", fields: ["after": .number(Double(cursor))])
    }
    /// Cancellation stops waiting only. Use cancel(environment:jobID:) to stop guest work.
    public func result(environment id: UUID, jobID: String) async throws -> JSONValue {
        while true {
            try Task.checkCancellation()
            let value = try await job(environment: id, jobID: jobID)
            if let state = value["state"]?.string, !["queued", "running"].contains(state) { return value }
            try await Task.sleep(nanoseconds: 1_000_000_000)
        }
    }
    /// Forgets an environment locally. Guest job state and its workspace files
    /// are left intact, so registering the same identifier again reattaches them.
    public func remove(_ id: UUID) throws {
        try FileManager.default.removeItem(at: location(id))
    }
    private func location(_ id: UUID) -> URL { directory.appendingPathComponent(id.uuidString + ".json") }
    private func call(_ spec: EnvironmentSpec, op: String, fields: [String: JSONValue] = [:]) async throws -> JSONValue {
        var payload = fields; payload["op"] = .string(op); payload["environment"] = .string(spec.id.uuidString)
        return try await transport.request(vmID: spec.vmID, payload: .object(payload))
    }
}
