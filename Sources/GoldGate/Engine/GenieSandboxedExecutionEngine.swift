import Foundation
import AppKit

// MARK: - 🛡️ Genie Sandboxed Execution Engine
/// Provides an isolated runtime environment for AI agent shell tools and terminal commands,
/// enforcing safe sandbox profiles (via `sandbox-exec`), directory confinement, and command screening.
public final class GenieSandboxedExecutionEngine: @unchecked Sendable {
    public static let shared = GenieSandboxedExecutionEngine()

    private let fileManager = FileManager.default

    /// Default sandboxed workspace folder for AI file modifications.
    public var defaultWorkspaceURL: URL {
        let home = fileManager.homeDirectoryForCurrentUser
        return home.appendingPathComponent("Desktop/Genie/Workspace", isDirectory: true)
    }

    private init() {
        ensureWorkspaceDirectoryExists()
    }

    /// Verifies the sandbox workspace folder exists on disk.
    public func ensureWorkspaceDirectoryExists() {
        let ws = defaultWorkspaceURL
        if !fileManager.fileExists(atPath: ws.path) {
            try? fileManager.createDirectory(at: ws, withIntermediateDirectories: true, attributes: nil)
        }
    }

    /// Determines if sandboxing is currently enforced via preferences.
    public var isSandboxActive: Bool {
        if UserDefaults.standard.object(forKey: PrefKey.agentSandboxEnabled) == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: PrefKey.agentSandboxEnabled)
    }

    // MARK: - Safety Screening
    private let destructivePatterns: [String] = [
        "rm -rf /",
        "rm -rf /*",
        "rm -rf ~",
        "rm -rf ~/*",
        ":(){ :|:& };:",
        "mkfs",
        "dd if=/dev/zero",
        "dd if=/dev/urandom",
        "chmod -R 777 /",
        "> /dev/sda",
        "> /dev/disk",
        "nvram -c"
    ]

    public func screenCommand(command: String) -> (isSafe: Bool, reason: String?) {
        let lower = command.lowercased()
        for pattern in destructivePatterns {
            if lower.contains(pattern) {
                return (false, "Command rejected: matches destructive pattern '\(pattern)'.")
            }
        }
        return (true, nil)
    }

    // MARK: - Execution
    public struct ExecutionResult {
        public let output: String
        public let exitCode: Int32
        public let isSandboxed: Bool
        public let executionTime: TimeInterval
        public let ramPartitionMB: Int

        public init(
            output: String,
            exitCode: Int32,
            isSandboxed: Bool,
            executionTime: TimeInterval,
            ramPartitionMB: Int = 4096
        ) {
            self.output = output
            self.exitCode = exitCode
            self.isSandboxed = isSandboxed
            self.executionTime = executionTime
            self.ramPartitionMB = ramPartitionMB
        }
    }

    /// Executes a shell command with sandbox protection, RAM governor budget, and isolated toolchain.
    public func execute(
        command: String,
        customWorkspace: URL? = nil,
        timeout: TimeInterval = 30.0
    ) async -> ExecutionResult {
        let clean = command.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else {
            return ExecutionResult(output: "Empty command.", exitCode: 0, isSandboxed: false, executionTime: 0)
        }

        // Distribution gate. This is the single chokepoint every agent shell
        // command flows through. A sandboxed build can reach neither
        // /usr/bin/sandbox-exec nor /bin/zsh, and App Store Review Guideline
        // 2.5.1 forbids shipping a general shell runner in any case, so Genie
        // Lite says so plainly rather than appearing to run and returning nothing.
        guard GenieCapabilities.canSpawnSubprocesses else {
            return ExecutionResult(
                output: GenieCapabilities.unavailableMessage("Running shell commands"),
                exitCode: 126,
                isSandboxed: true,
                executionTime: 0
            )
        }

        let screening = screenCommand(command: clean)
        guard screening.isSafe else {
            return ExecutionResult(
                output: "🛑 Safety Warning: \(screening.reason ?? "Command denied.")",
                exitCode: 1,
                isSandboxed: isSandboxActive,
                executionTime: 0
            )
        }

        // 🧠 Check RAM Governor budget & queue for resources if saturated
        let (granted, queueReason) = await GenieMemoryGovernorEngine.shared.queueForResources(estimatedMB: 256, timeout: 10.0)
        guard granted else {
            let limitMB = await MainActor.run { GenieMemoryGovernorEngine.shared.maxAgentMemoryMB }
            return ExecutionResult(
                output: "🛑 Memory Governor: \(queueReason ?? "RAM partition limit reached or agent queue saturated.")",
                exitCode: 137,
                isSandboxed: isSandboxActive,
                executionTime: 0,
                ramPartitionMB: limitMB
            )
        }
        defer {
            Task { @MainActor in
                GenieMemoryGovernorEngine.shared.releaseResourceSlot()
            }
        }

        let workspace = customWorkspace ?? defaultWorkspaceURL
        ensureWorkspaceDirectoryExists()

        let sandboxed = isSandboxActive
        let startTime = Date()
        let ramLimitMB = await MainActor.run { GenieMemoryGovernorEngine.shared.maxAgentMemoryMB }
        let ulimitPrefix = await MainActor.run { GenieMemoryGovernorEngine.shared.ulimitPrefix }
        let guardedCommand = ulimitPrefix + clean

        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let task = Process()
                let pipe = Pipe()
                task.standardOutput = pipe
                task.standardError = pipe
                task.currentDirectoryURL = workspace

                if sandboxed {
                    // Use macOS sandbox-exec to restrict arbitrary file modifications
                    let sandboxProfile = self.generateSandboxProfile(allowedWorkspace: workspace.path)
                    task.executableURL = URL(fileURLWithPath: "/usr/bin/sandbox-exec")
                    task.arguments = ["-p", sandboxProfile, "/bin/zsh", "-c", guardedCommand]
                } else {
                    task.executableURL = URL(fileURLWithPath: "/bin/zsh")
                    task.arguments = ["-c", guardedCommand]
                }

                // 🛡️ Isolated Toolchain & Stripped Personal Credentials:
                // Ensure Genie only uses dedicated agent tools and does not touch user's personal keys/history
                var env = ProcessInfo.processInfo.environment

                // Strip user's personal credentials and secret tokens
                env.removeValue(forKey: "SSH_AUTH_SOCK")
                env.removeValue(forKey: "AWS_ACCESS_KEY_ID")
                env.removeValue(forKey: "AWS_SECRET_ACCESS_KEY")
                env.removeValue(forKey: "AWS_PROFILE")
                env.removeValue(forKey: "GPG_AGENT_INFO")
                env.removeValue(forKey: "GITHUB_TOKEN")
                env.removeValue(forKey: "GH_TOKEN")

                // Route shell history and temp files into isolated workspace
                env["HISTFILE"] = workspace.appendingPathComponent(".genie_zsh_history").path
                let tmpDir = workspace.appendingPathComponent("tmp")
                try? FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
                env["TMPDIR"] = tmpDir.path

                // Isolated PATH: Prioritizes agent binaries and standard system utilities
                let agentPath = "/Users/genie-agent/.local/bin:/Users/genie-agent/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
                let hostPath = env["PATH"] ?? ""
                env["PATH"] = "\(agentPath):\(hostPath)"
                env["GENIE_SANDBOX_ACTIVE"] = sandboxed ? "1" : "0"
                env["GENIE_WORKSPACE"] = workspace.path
                env["GENIE_RAM_LIMIT_MB"] = "\(ramLimitMB)"
                task.environment = env

                do {
                    try task.run()
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    task.waitUntilExit()
                    let rawOut = String(data: data, encoding: .utf8) ?? ""
                    let elapsed = Date().timeIntervalSince(startTime)
                    
                    let prefix = sandboxed ? "🛡️ [Sandbox Active - Workspace: ~/Desktop/Genie/Workspace - RAM Cap: \(ramLimitMB)MB]\n" : ""
                    let out = rawOut.isEmpty ? (prefix + "Executed with exit code \(task.terminationStatus).") : (prefix + rawOut)

                    continuation.resume(returning: ExecutionResult(
                        output: out,
                        exitCode: task.terminationStatus,
                        isSandboxed: sandboxed,
                        executionTime: elapsed,
                        ramPartitionMB: ramLimitMB
                    ))
                } catch {
                    let elapsed = Date().timeIntervalSince(startTime)
                    continuation.resume(returning: ExecutionResult(
                        output: "Failed to execute: \(error.localizedDescription)",
                        exitCode: -1,
                        isSandboxed: sandboxed,
                        executionTime: elapsed,
                        ramPartitionMB: ramLimitMB
                    ))
                }
            }
        }
    }

    /// Generates a Scheme sandbox profile isolating file write capabilities.
    private func generateSandboxProfile(allowedWorkspace: String) -> String {
        let desktop = GenieDesktopFileGuard.desktopRoot.path
        let perUserTemp = URL(fileURLWithPath: NSTemporaryDirectory())
            .resolvingSymlinksInPath().path
        return """
        (version 1)
        (allow default)
        (deny file-write*
            (subpath "/")
        )
        (allow file-write*
            (subpath "\(desktop)")
            (subpath "\(allowedWorkspace)")
            (subpath "/tmp")
            (subpath "/private/tmp")
            (subpath "\(perUserTemp)")
        )

        ;; Last match wins in SBPL, so these re-deny system locations even though the
        ;; grants above are broad. Kept in agreement with GenieDesktopFileGuard.
        (deny file-write*
            (subpath "/System")
            (subpath "/usr")
            (subpath "/bin")
            (subpath "/sbin")
            (subpath "/Applications")
            (subpath "/private/etc")
            (subpath "/Library/LaunchDaemons")
            (subpath "/Library/LaunchAgents")
        )
        (deny file-read*
            (subpath "/Library/Keychains")
            (regex #"^.*\\\\.ssh(/.*)?$")
            (regex #"^.*\\\\.aws(/.*)?$")
            (regex #"^.*\\\\.gnupg(/.*)?$")
        )
        """
    }
}
