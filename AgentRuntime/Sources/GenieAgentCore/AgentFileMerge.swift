import Foundation

public enum AgentFileMerge {
    /// diff3 performs a real ancestor-based merge. Originals are never modified.
    public static func preview(current: String, base: String, incoming: String) async throws -> AgentToolResult {
        let result = try await Task.detached(priority: .utility) {
            let directory = FileManager.default.temporaryDirectory.appendingPathComponent("genie-merge-" + UUID().uuidString)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
            defer { try? FileManager.default.removeItem(at: directory) }
            for (name, text) in [("current", current), ("base", base), ("incoming", incoming)] {
                try text.write(to: directory.appendingPathComponent(name), atomically: true, encoding: .utf8)
            }
            let output = directory.appendingPathComponent("output")
            FileManager.default.createFile(atPath: output.path, contents: nil)
            let handle = try FileHandle(forWritingTo: output)
            defer { try? handle.close() }
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/diff3")
            process.currentDirectoryURL = directory
            process.arguments = ["-m", "current", "base", "incoming"]
            process.standardInput = FileHandle.nullDevice
            process.standardOutput = handle
            process.standardError = handle
            try process.run()
            process.waitUntilExit()
            guard process.terminationReason == .exit, process.terminationStatus <= 1 else {
                throw AgentFailure("Merge preview failed; original files are unchanged.")
            }
            let merged = try String(contentsOf: output, encoding: .utf8)
            let payload: [String: Any] = ["conflicts": process.terminationStatus == 1,
                                          "content": merged, "files_changed": false]
            return AgentToolResult(success: process.terminationStatus == 0,
                                   output: String(decoding: try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys]), as: UTF8.self),
                                   exitCode: process.terminationStatus)
        }.value
        try Task.checkCancellation()
        return result
    }
}
