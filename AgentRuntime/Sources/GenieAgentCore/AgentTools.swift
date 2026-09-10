import Foundation
import Darwin

private final class AgentCancellation: @unchecked Sendable {
    private let lock = NSLock()
    private var value = false
    func cancel() { lock.lock(); value = true; lock.unlock() }
    var cancelled: Bool { lock.lock(); defer { lock.unlock() }; return value }
}

public enum AgentCommandRunner {
    /// Each command gets its own process group so Stop also kills spawned children.
    public static func run(_ command: String, directory: URL, timeout: TimeInterval = 300) async throws -> AgentToolResult {
        let cancellation = AgentCancellation()
        return try await withTaskCancellationHandler(operation: {
            try await Task.detached(priority: .utility) {
                var fds: [Int32] = [0, 0]
                guard pipe(&fds) == 0 else { throw AgentFailure("Cannot create command output pipe.") }
                defer { close(fds[0]); close(fds[1]) }
                var actions: posix_spawn_file_actions_t?
                var attributes: posix_spawnattr_t?
                posix_spawn_file_actions_init(&actions)
                posix_spawnattr_init(&attributes)
                defer { posix_spawn_file_actions_destroy(&actions); posix_spawnattr_destroy(&attributes) }
                posix_spawn_file_actions_adddup2(&actions, fds[1], STDOUT_FILENO)
                posix_spawn_file_actions_adddup2(&actions, fds[1], STDERR_FILENO)
                posix_spawn_file_actions_addclose(&actions, fds[0])
                posix_spawn_file_actions_addclose(&actions, fds[1])
                posix_spawn_file_actions_addopen(&actions, STDIN_FILENO, "/dev/null", O_RDONLY, 0)
                posix_spawn_file_actions_addchdir_np(&actions, directory.path)
                posix_spawnattr_setflags(&attributes, Int16(POSIX_SPAWN_SETPGROUP))
                posix_spawnattr_setpgroup(&attributes, 0)
                let strings = ["/bin/zsh", "-f", "-c", command].map { strdup($0) }
                defer { strings.forEach { free($0) } }
                var argv = strings + [nil]
                let environment = ProcessInfo.processInfo.environment.map { strdup("\($0.key)=\($0.value)") }
                defer { environment.forEach { free($0) } }
                var envp = environment + [nil]
                var pid: pid_t = 0
                if cancellation.cancelled { throw CancellationError() }
                let result = posix_spawn(&pid, "/bin/zsh", &actions, &attributes, &argv, &envp)
                guard result == 0 else { throw AgentFailure("Cannot start command: \(String(cString: strerror(result)))") }
                _ = fcntl(fds[0], F_SETFL, O_NONBLOCK)
                let deadline = Date().addingTimeInterval(timeout)
                var output = Data()
                var status: Int32 = 0
                var buffer = [UInt8](repeating: 0, count: 8192)
                var truncated = false
                func drain() {
                    // Bound each drain pass even when a child writes without stopping.
                    for _ in 0..<32 {
                        let n = read(fds[0], &buffer, buffer.count)
                        if n <= 0 { break }
                        let room = max(0, 524_288 - output.count)
                        output.append(contentsOf: buffer.prefix(min(n, room)))
                        if n > room { truncated = true }
                    }
                }
                while true {
                    drain()
                    if cancellation.cancelled || Date() >= deadline {
                        kill(-pid, SIGKILL)
                        while waitpid(pid, &status, 0) < 0 && errno == EINTR {}
                        if cancellation.cancelled { throw CancellationError() }
                        drain()
                        return AgentToolResult(success: false, output: String(decoding: output, as: UTF8.self) + "\nTimed out; command process group stopped.", exitCode: 124)
                    }
                    let waited = waitpid(pid, &status, WNOHANG)
                    if waited == pid {
                        // No unattended background descendants survive a completed tool call.
                        kill(-pid, SIGKILL)
                        drain()
                        let signal = status & 0x7f
                        let code = signal == 0 ? (status >> 8) & 0xff : 128 + signal
                        return AgentToolResult(success: code == 0, output: String(decoding: output, as: UTF8.self) + (truncated ? "\n[Output truncated at 512 KB]" : ""), exitCode: code)
                    }
                    if waited < 0 && errno != EINTR {
                        kill(-pid, SIGKILL)
                        throw AgentFailure("Failed to observe command completion.")
                    }
                    usleep(20_000)
                }
            }.value
        }, onCancel: { cancellation.cancel() })
    }
}

public actor AgentTools {
    public let workspace: URL
    private var desktop: AgentDesktopTools?
    public init(workspace: URL) { self.workspace = workspace.standardizedFileURL.resolvingSymlinksInPath() }

    public func resolve(_ path: String) throws -> URL {
        guard !path.hasPrefix("/"), !path.contains("\0") else { throw AgentFailure("Use a relative workspace path.") }
        // Resolve existing parents as well: Foundation may leave a symlink unresolved
        // when the final file does not exist yet (the create-file case).
        var url = workspace
        for component in path.split(separator: "/") {
            if component == "." { continue }
            guard component != ".." else { throw AgentFailure("Parent traversal is disabled.") }
            url = url.appendingPathComponent(String(component)).standardizedFileURL.resolvingSymlinksInPath()
            guard url.path == workspace.path || url.path.hasPrefix(workspace.path + "/") else {
                throw AgentFailure("Path escapes the selected workspace.")
            }
        }
        guard url.path == workspace.path || url.path.hasPrefix(workspace.path + "/") else {
            throw AgentFailure("Path escapes the selected workspace.")
        }
        guard !url.pathComponents.contains(".git") else { throw AgentFailure("Direct access to Git internals is disabled.") }
        return url
    }

    public func arguments(for call: AgentToolCall) throws -> [String: String] {
        guard AgentToolCatalog.names.contains(call.name), let data = call.arguments.data(using: .utf8),
              let args = try JSONSerialization.jsonObject(with: data) as? [String: String] else {
            throw AgentFailure("Unknown tool or invalid string arguments.")
        }
        let required: Set<String>
        switch call.name {
        case "list_files", "read_file": required = ["path"]
        case "search_files": required = ["query"]
        case "edit_file": required = ["path", "old_text", "new_text"]
        case "write_file": required = ["path", "expected_content", "content"]
        case "merge_files": required = ["path", "base_path", "incoming_path"]
        case "read_ui": required = ["app"]
        case "grab_text", "copy_text": required = ["element_id", "scope"]
        case "paste_text": required = ["element_id", "expected_value", "text"]
        default: required = ["command"]
        }
        guard Set(args.keys) == required else { throw AgentFailure("Unexpected or missing tool arguments.") }
        if let path = args["path"] { _ = try resolve(path) }
        for key in ["base_path", "incoming_path"] {
            if let path = args[key] { _ = try resolve(path) }
        }
        return args
    }

    private func files(in folder: URL) throws -> [URL] {
        guard let walker = FileManager.default.enumerator(at: folder, includingPropertiesForKeys: [.isRegularFileKey, .isSymbolicLinkKey], options: [.skipsHiddenFiles]) else {
            throw AgentFailure("Cannot list directory.")
        }
        var result: [URL] = []
        let excluded: Set<String> = ["node_modules", "build", "dist", "__pycache__", "venv"]
        var visited = 0
        for case let url as URL in walker {
            try Task.checkCancellation()
            visited += 1
            if visited > 20_000 { break }
            if excluded.contains(url.lastPathComponent) || url.pathExtension == "app" { walker.skipDescendants(); continue }
            let values = try url.resourceValues(forKeys: [.isRegularFileKey, .isSymbolicLinkKey])
            if values.isSymbolicLink == true { walker.skipDescendants(); continue }
            if values.isRegularFile == true { result.append(url) }
            if result.count >= 2000 { break }
        }
        return result.sorted { $0.path < $1.path }
    }

    private func readText(_ url: URL) throws -> String {
        let handle = try FileHandle(forReadingFrom: url)
        defer { try? handle.close() }
        let data = try handle.read(upToCount: 5_242_881) ?? Data()
        guard data.count <= 5_242_880, let text = String(data: data, encoding: .utf8), !text.contains("\0") else {
            throw AgentFailure("File must be UTF-8 text and at most 5 MB.")
        }
        return text
    }

    public func execute(_ call: AgentToolCall, approved: Bool = false) async throws -> AgentToolResult {
        try Task.checkCancellation()
        let args = try arguments(for: call)
        switch call.name {
        case "read_ui", "grab_text", "copy_text", "paste_text":
            if AgentToolCatalog.mutatingNames.contains(call.name) && !approved {
                throw AgentFailure("Clipboard changes require approval.")
            }
            if desktop == nil { desktop = await AgentDesktopTools() }
            return try await desktop!.execute(call.name, args: args)
        case "write_file":
            guard approved else { throw AgentFailure("File writes require approval.") }
            let url = try resolve(args["path"]!)
            let content = args["content"]!, expected = args["expected_content"]!
            guard content.utf8.count <= 5_242_880, !content.contains("\0") else { throw AgentFailure("Content must be UTF-8 text, at most 5 MB, without NUL bytes.") }
            if expected == "__NEW_FILE__" {
                guard !FileManager.default.fileExists(atPath: url.path) else { throw AgentFailure("File already exists; read it before replacing it.") }
            } else {
                guard try readText(url) == expected else { throw AgentFailure("File changed since it was read; reread and reconcile before writing.") }
            }
            try Task.checkCancellation()
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try content.write(to: url, atomically: true, encoding: .utf8)
            guard try readText(url) == content else { throw AgentFailure("File read-back verification failed.") }
            return AgentToolResult(success: true, output: "Saved \(args["path"]!); exact content verified by read-back.")
        case "merge_files":
            let current = try readText(resolve(args["path"]!))
            let base = try readText(resolve(args["base_path"]!))
            let incoming = try readText(resolve(args["incoming_path"]!))
            return try await AgentFileMerge.preview(current: current, base: base, incoming: incoming)
        case "list_files":
            let urls = try files(in: resolve(args["path"]!))
            return AgentToolResult(success: true, output: urls.map { String($0.path.dropFirst(workspace.path.count + 1)) }.joined(separator: "\n") + "\n[Up to 2,000 files; generated/hidden files excluded]")
        case "read_file":
            return AgentToolResult(success: true, output: try readText(resolve(args["path"]!)))
        case "search_files":
            let query = args["query"]!
            guard !query.isEmpty else { throw AgentFailure("Search text must not be empty.") }
            var matches: [String] = []
            for url in try files(in: workspace) {
                try Task.checkCancellation()
                guard let content = try? readText(url) else { continue }
                for (index, line) in content.components(separatedBy: "\n").enumerated() where line.contains(query) {
                    matches.append("\(String(url.path.dropFirst(workspace.path.count + 1))):\(index + 1): \(line.prefix(400))")
                    if matches.count >= 100 { break }
                }
                if matches.count >= 100 { break }
            }
            return AgentToolResult(success: true, output: matches.joined(separator: "\n") + "\n[Up to 100 matches in the first 2,000 files]")
        case "edit_file":
            guard approved else { throw AgentFailure("File edits require approval.") }
            let url = try resolve(args["path"]!)
            let old = args["old_text"]!, new = args["new_text"]!
            guard new.utf8.count <= 5_242_880 else { throw AgentFailure("Replacement exceeds 5 MB.") }
            let exists = FileManager.default.fileExists(atPath: url.path)
            let content: String
            if old.isEmpty {
                guard !exists else { throw AgentFailure("File exists; supply a unique old_text to edit it.") }
                content = new
            } else {
                let previous = try readText(url)
                guard previous.components(separatedBy: old).count == 2 else { throw AgentFailure("old_text must match exactly once; reread the file.") }
                content = previous.replacingOccurrences(of: old, with: new)
            }
            guard content.utf8.count <= 5_242_880 else { throw AgentFailure("Edited file exceeds 5 MB.") }
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try content.write(to: url, atomically: true, encoding: .utf8)
            guard try readText(url) == content else { throw AgentFailure("File read-back verification failed.") }
            return AgentToolResult(success: true, output: "Saved and read back \(args["path"]!). Run relevant tests to verify behavior.")
        default:
            guard approved else { throw AgentFailure("Commands require approval.") }
            guard let command = args["command"], !command.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw AgentFailure("Command is empty.") }
            return try await AgentCommandRunner.run(command, directory: workspace)
        }
    }
}
