import Foundation
import Darwin

/// Uses fixed executable/argument arrays. Model-provided shell commands never run on macOS.
public struct UTMBackend: EnvironmentTransport {
    public var executable: URL
    public init(executable: URL = URL(fileURLWithPath: "/Applications/UTM.app/Contents/MacOS/utmctl")) { self.executable = executable }
    /// Resolved without `Bundle.module`, which traps when the resource bundle is
    /// missing from a packaged app instead of reporting a fixable error.
    public static func guestFiles() throws -> URL {
        let candidates = [Bundle.main.resourceURL, Bundle(for: BundleToken.self).resourceURL,
                          Bundle(for: BundleToken.self).bundleURL, Bundle.main.bundleURL]
        for base in candidates.compactMap({ $0 }) {
            let url = base.appendingPathComponent("GenieEnvironmentKit_GenieEnvironmentKit.bundle")
            if let bundle = Bundle(url: url), let guest = bundle.url(forResource: "Guest", withExtension: nil) {
                return guest
            }
        }
        throw EnvironmentError("This build of Genie is missing the Linux guest files. Reinstall Genie, or copy them from the source checkout.")
    }
    public func list() async throws -> String { try await run(["list"]) }
    public func start(vmID: UUID) async throws { _ = try await run(["start", vmID.uuidString], timeout: 60) }
    public func status(vmID: UUID) async throws -> String { try await run(["status", vmID.uuidString]) }
    public func checkGuest(vmID: UUID) async throws -> String {
        try await run(["exec", vmID.uuidString, "--cmd", "/usr/bin/true"])
    }
    public func clone(templateID: UUID, name: String) async throws -> UUID {
        let output = try await run(["clone", templateID.uuidString, "--name", name], timeout: 600)
        for token in output.components(separatedBy: .whitespacesAndNewlines) {
            if let id = UUID(uuidString: token.trimmingCharacters(in: .punctuationCharacters)) { return id }
        }
        throw EnvironmentError("UTM cloned the VM but did not return an identifiable UUID. Use list to find it before retrying. " + output)
    }
    /// Guest-agent execution runs as root; tool jobs subsequently run as genie-env.
    public func installGuest(vmID: UUID) async throws -> String {
        _ = try await checkGuest(vmID: vmID)
        let destination = "/tmp/genie-install-" + UUID().uuidString
        let guest = try Self.guestFiles()
        let files = try ["worker.py", "client.py", "install.sh"].reduce(into: [String: String]()) { result, name in
            result[name] = try Data(contentsOf: guest.appendingPathComponent(name)).base64EncodedString()
        }
        let payload = try JSONEncoder().encode(files).base64EncodedString()
        let script = "import base64,json,pathlib,sys; p=pathlib.Path(sys.argv[1]); p.mkdir(mode=0o700); files=json.loads(base64.b64decode(sys.argv[2])); [(p/n).write_bytes(base64.b64decode(v)) for n,v in files.items()]"
        _ = try await run(["exec", vmID.uuidString, "--cmd", "/usr/bin/python3", "-c", script, destination, payload])
        return try await run(["exec", vmID.uuidString, "--cmd", "/bin/bash", destination + "/install.sh"], timeout: 600)
    }
    public func request(vmID: UUID, payload: JSONValue) async throws -> JSONValue {
        let encoded = try JSONEncoder().encode(payload).base64EncodedString()
        guard encoded.count < 180_000 else { throw EnvironmentError("Request exceeds 128 KiB; split the input into smaller files.") }
        let response = try await run(["exec", vmID.uuidString, "--cmd", "/usr/sbin/runuser", "-u", "genie-env", "--", "/usr/bin/python3", "/opt/genie-environment/client.py", encoded])
        guard let data = response.data(using: .utf8), let value = try? JSONDecoder().decode(JSONValue.self, from: data) else {
            throw EnvironmentError("Invalid guest response. Install and start the Genie guest worker. \(response.prefix(1500))")
        }
        if let error = value["error"]?.string { throw EnvironmentError(error) }
        return value["result"] ?? value
    }
    public func run(_ arguments: [String], timeout: TimeInterval = 20) async throws -> String {
        #if GENIE_MAS
        // utmctl lives outside the app bundle. Under the App Store sandbox the
        // spawn cannot succeed, and the `isExecutableFile` probe below would
        // report "UTM is not installed" even on a Mac where it is — misleading.
        // Say what is actually true instead. `GenieCapabilities.canSpawnSubprocesses`
        // already keeps the host-side UI from offering this.
        throw EnvironmentError("Linux environments are not supported under macOS App Sandbox security restrictions. Use the direct download of Genie for UTM-backed environments.")
        #else
        guard FileManager.default.isExecutableFile(atPath: executable.path) else { throw EnvironmentError("UTM is not installed at \(executable.path).") }
        let runner = ProcessRunner(executable: executable, arguments: arguments, timeout: timeout)
        return try await withTaskCancellationHandler {
            try await Task.detached { try runner.run() }.value
        } onCancel: { runner.cancel() }
        #endif
    }
}

final class ProcessRunner: @unchecked Sendable {
    let executable: URL; let arguments: [String]; let timeout: TimeInterval; let input: Data?
    private let lock = NSLock()
    private var cancelled = false
    init(executable: URL, arguments: [String], timeout: TimeInterval, input: Data? = nil) {
        self.executable = executable; self.arguments = arguments; self.timeout = timeout; self.input = input
    }
    func cancel() { lock.lock(); cancelled = true; lock.unlock() }
    private var isCancelled: Bool { lock.lock(); defer { lock.unlock() }; return cancelled }
    func run() throws -> String {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let outputURL = directory.appendingPathComponent("output")
        let errorURL = directory.appendingPathComponent("error")
        FileManager.default.createFile(atPath: outputURL.path, contents: nil)
        FileManager.default.createFile(atPath: errorURL.path, contents: nil)
        let output = try FileHandle(forWritingTo: outputURL), error = try FileHandle(forWritingTo: errorURL)
        defer { try? output.close(); try? error.close() }
        let process = Process(); process.executableURL = executable; process.arguments = arguments
        process.standardOutput = output; process.standardError = error
        if let input {
            let inputURL = directory.appendingPathComponent("input")
            try input.write(to: inputURL, options: .atomic)
            process.standardInput = try FileHandle(forReadingFrom: inputURL)
        } else {
            process.standardInput = FileHandle.nullDevice
        }
        if isCancelled { throw CancellationError() }
        try process.run()
        let deadline = Date().addingTimeInterval(timeout)
        while process.isRunning {
            let size = ((try? output.offset()) ?? 0) + ((try? error.offset()) ?? 0)
            if isCancelled || Date() >= deadline || size > 2_000_000 {
                process.terminate()
                Thread.sleep(forTimeInterval: 0.1)
                if process.isRunning { kill(process.processIdentifier, SIGKILL) }
                process.waitUntilExit()
                if isCancelled { throw CancellationError() }
                throw EnvironmentError("\(executable.lastPathComponent) exceeded its time or output limit. Guest jobs may still be running; reconnect to inspect them.")
            }
            Thread.sleep(forTimeInterval: 0.05)
        }
        process.waitUntilExit()
        let out = String(decoding: try Data(contentsOf: outputURL), as: UTF8.self)
        let err = String(decoding: try Data(contentsOf: errorURL), as: UTF8.self)
        // utmctl can report Apple Event errors on stderr while returning exit 0.
        guard process.terminationStatus == 0, !err.contains("Error from event:") else {
            throw EnvironmentError("UTM: \((err + out).prefix(3000))")
        }
        return out.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private final class BundleToken {}
