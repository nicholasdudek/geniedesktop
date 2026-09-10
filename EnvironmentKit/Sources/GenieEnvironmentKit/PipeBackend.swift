import Foundation

/// Carries requests to the guest over a transport that can pipe stdin.
///
/// `utmctl exec` cannot be used for this: its output capture only returns what a
/// command produced by the time it first polls, so anything slower than a few
/// milliseconds comes back empty even though the guest ran it correctly. The
/// guest client already accepts `-` to read its request from stdin, which also
/// avoids ARG_MAX entirely.
///
/// Uses fixed executable/argument arrays. Model-provided shell commands never run on macOS.
public struct PipeBackend: EnvironmentTransport {
    /// The guest bridge, run as the unprivileged worker account. `sudo -n` never
    /// prompts; the guest grants exactly this one command via a sudoers rule.
    public static let guestCommand = [
        "sudo", "-n", "-u", "genie-env",
        "/usr/bin/python3", "/opt/genie-environment/client.py", "-"
    ]

    public var executable: URL
    public var leadingArguments: [String]
    public var timeout: TimeInterval

    public init(executable: URL, leadingArguments: [String], timeout: TimeInterval = 120) {
        self.executable = executable
        self.leadingArguments = leadingArguments
        self.timeout = timeout
    }

    /// Reaches a VM over SSH using a key, so no password is stored or prompted for.
    public static func ssh(host: String, user: String, identity: URL, timeout: TimeInterval = 120) -> PipeBackend {
        PipeBackend(
            executable: URL(fileURLWithPath: "/usr/bin/ssh"),
            leadingArguments: [
                "-i", identity.path,
                "-o", "BatchMode=yes",
                "-o", "StrictHostKeyChecking=accept-new",
                "-o", "ConnectTimeout=10",
                "\(user)@\(host)",
                guestCommand.joined(separator: " ")
            ],
            timeout: timeout
        )
    }

    /// Reaches an OrbStack Linux machine, which needs no key and no networking.
    public static func orbStack(machine: String, executable: URL = URL(fileURLWithPath: "/opt/homebrew/bin/orbctl"), timeout: TimeInterval = 120) -> PipeBackend {
        PipeBackend(executable: executable, leadingArguments: ["run", "-m", machine] + guestCommand, timeout: timeout)
    }

    public func request(vmID: UUID, payload: JSONValue) async throws -> JSONValue {
        let encoded = try JSONEncoder().encode(payload)
        guard encoded.count < 900_000 else { throw EnvironmentError("Request exceeds 900 KB; split the input into smaller files.") }
        let response = try await run(input: encoded)
        guard let data = response.data(using: .utf8), let value = try? JSONDecoder().decode(JSONValue.self, from: data) else {
            throw EnvironmentError("Invalid guest response. Install and start the Genie guest worker. \(response.prefix(1500))")
        }
        if let error = value["error"]?.string { throw EnvironmentError(error) }
        return value["result"] ?? value
    }

    public func run(input: Data? = nil, extraArguments: [String] = []) async throws -> String {
        guard FileManager.default.isExecutableFile(atPath: executable.path) else {
            throw EnvironmentError("\(executable.path) is not installed.")
        }
        let runner = ProcessRunner(executable: executable, arguments: leadingArguments + extraArguments, timeout: timeout, input: input)
        return try await withTaskCancellationHandler {
            try await Task.detached { try runner.run() }.value
        } onCancel: { runner.cancel() }
    }

    /// Confirms the guest worker answers before an environment is registered against it.
    public func health() async throws -> JSONValue {
        try await request(vmID: UUID(), payload: .object(["op": .string("health")]))
    }
}
