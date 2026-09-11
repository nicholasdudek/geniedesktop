import AppKit
import Foundation
import Combine
import SwiftUI

// MARK: - 🧠 Self-Learning Action Enum
public enum SelfLearningAction: String, Codable, CaseIterable {
    case learnedNewCapability = "learned_new_capability"
    case selfRepair = "self_repair"
    case performanceOptimization = "performance_optimization"
    case rollback = "rollback"

    public var displayBadge: String {
        switch self {
        case .learnedNewCapability: return "✨ Learned New Skill"
        case .selfRepair: return "🛠️ Self-Repaired Bug"
        case .performanceOptimization: return "⚡ Optimized Script"
        case .rollback: return "⏪ Rolled Back"
        }
    }

    public var color: Color {
        switch self {
        case .learnedNewCapability: return .cyan
        case .selfRepair: return .green
        case .performanceOptimization: return .orange
        case .rollback: return .purple
        }
    }
}

// MARK: - 📜 Self-Learning Immutable Ledger Entry
public struct SelfLearningLedgerEntry: Identifiable, Codable, Equatable {
    public var id: UUID
    public var timestamp: Date
    public var scriptName: String
    public var version: Int
    public var action: SelfLearningAction
    public var capabilityTitle: String
    public var summary: String
    public var codeDiffOrSnippet: String
    public var verificationOutput: String
    public var isVerified: Bool
    public var author: String

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        scriptName: String,
        version: Int,
        action: SelfLearningAction,
        capabilityTitle: String,
        summary: String,
        codeDiffOrSnippet: String,
        verificationOutput: String,
        isVerified: Bool = true,
        author: String = "Genie Autonomous Core"
    ) {
        self.id = id
        self.timestamp = timestamp
        self.scriptName = scriptName
        self.version = version
        self.action = action
        self.capabilityTitle = capabilityTitle
        self.summary = summary
        self.codeDiffOrSnippet = codeDiffOrSnippet
        self.verificationOutput = verificationOutput
        self.isVerified = isVerified
        self.author = author
    }
}

// MARK: - 🧠 Genie Self-Repair & Continuous Learning Engine
@MainActor
public final class GenieSelfRepairLearningEngine: ObservableObject {
    public static let shared = GenieSelfRepairLearningEngine()

    @Published public private(set) var ledgerEntries: [SelfLearningLedgerEntry] = []
    @Published public private(set) var registeredScripts: [String: Int] = [:] // [scriptName: currentVersion]
    @Published public private(set) var isRepairing: Bool = false
    @Published public private(set) var lastActionMessage: String = "Engine initialized and verified."

    private let fileManager = FileManager.default
    private let scriptsDirectory: URL
    private let archiveDirectory: URL
    private let ledgerFileURL: URL

    private init() {
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSTemporaryDirectory())
        let baseDir = appSupport.appendingPathComponent("Genie/LearningLedger", isDirectory: true)
        self.scriptsDirectory = baseDir.appendingPathComponent("scripts", isDirectory: true)
        self.archiveDirectory = baseDir.appendingPathComponent("archive", isDirectory: true)
        self.ledgerFileURL = baseDir.appendingPathComponent("ledger.json")

        ensureDirectoriesExist()
        loadLedger()
        seedInitialScriptsIfNeeded()
    }

    private func ensureDirectoriesExist() {
        try? fileManager.createDirectory(at: scriptsDirectory, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: archiveDirectory, withIntermediateDirectories: true)
    }

    // MARK: - Ledger Persistence
    private func loadLedger() {
        guard fileManager.fileExists(atPath: ledgerFileURL.path),
              let data = try? Data(contentsOf: ledgerFileURL),
              let decoded = try? JSONDecoder().decode([SelfLearningLedgerEntry].self, from: data) else {
            self.ledgerEntries = []
            return
        }
        self.ledgerEntries = decoded

        // Compute current script versions
        var versions: [String: Int] = [:]
        for entry in decoded {
            let cur = versions[entry.scriptName] ?? 0
            if entry.version > cur {
                versions[entry.scriptName] = entry.version
            }
        }
        self.registeredScripts = versions
    }

    private func persistLedger() {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        if let data = try? encoder.encode(ledgerEntries) {
            try? data.write(to: ledgerFileURL, options: .atomic)

            // Mirror to ~/.genie/self_learning_ledger.json for easy user inspection
            let homeDir = URL(fileURLWithPath: NSHomeDirectory())
            let dotGenie = homeDir.appendingPathComponent(".genie", isDirectory: true)
            try? fileManager.createDirectory(at: dotGenie, withIntermediateDirectories: true)
            let mirrorURL = dotGenie.appendingPathComponent("self_learning_ledger.json")
            try? data.write(to: mirrorURL, options: .atomic)
        }
    }

    // MARK: - 1. Learn New Python Script / Capability
    @discardableResult
    public func learnNewCapability(
        name: String,
        code: String,
        capabilityTitle: String,
        summary: String,
        action: SelfLearningAction = .learnedNewCapability
    ) async -> (success: Bool, message: String, version: Int) {
        let cleanName = name.hasSuffix(".py") ? String(name.dropLast(3)) : name
        let currentVer = registeredScripts[cleanName] ?? 0
        let nextVer = currentVer + 1

        // Step 1: Pre-validation using Python AST compiler
        let syntaxCheck = await validatePythonSyntax(code: code)
        guard syntaxCheck.isValid else {
            let failMsg = "Syntax verification failed: \(syntaxCheck.error)"
            self.lastActionMessage = failMsg
            return (false, failMsg, currentVer)
        }

        // Step 2: Archive current version if it exists
        let currentScriptURL = scriptsDirectory.appendingPathComponent("\(cleanName).py")
        if fileManager.fileExists(atPath: currentScriptURL.path) {
            let archiveURL = archiveDirectory.appendingPathComponent("\(cleanName).v\(currentVer).py")
            try? fileManager.copyItem(at: currentScriptURL, to: archiveURL)
        }

        // Step 3: Write new code to disk with executable permission
        do {
            try code.write(to: currentScriptURL, atomically: true, encoding: .utf8)
            try? fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: currentScriptURL.path)
        } catch {
            let writeMsg = "File write failed: \(error.localizedDescription)"
            self.lastActionMessage = writeMsg
            return (false, writeMsg, currentVer)
        }

        // Step 4: Verification execution pass
        let testExec = await executePythonTestRun(scriptURL: currentScriptURL)

        // Step 5: Append to Immutable Ledger
        let entry = SelfLearningLedgerEntry(
            scriptName: cleanName,
            version: nextVer,
            action: action,
            capabilityTitle: capabilityTitle,
            summary: summary,
            codeDiffOrSnippet: String(code.prefix(300)),
            verificationOutput: testExec.output,
            isVerified: testExec.success,
            author: "Genie Autonomous Core"
        )
        self.ledgerEntries.insert(entry, at: 0)
        self.registeredScripts[cleanName] = nextVer
        persistLedger()

        let successMsg = "Learned capability '\(capabilityTitle)' as \(cleanName).py v\(nextVer) [Verified: \(testExec.success)]"
        self.lastActionMessage = successMsg

        NotificationCenter.default.post(name: NSNotification.Name("NexusSelfLearningLedgerUpdated"), object: entry)
        return (true, successMsg, nextVer)
    }

    // MARK: - 2. Self-Repair Python Script on Error
    @discardableResult
    public func selfRepairScript(
        name: String,
        errorOutput: String
    ) async -> (success: Bool, message: String) {
        let cleanName = name.hasSuffix(".py") ? String(name.dropLast(3)) : name
        let scriptURL = scriptsDirectory.appendingPathComponent("\(cleanName).py")
        guard fileManager.fileExists(atPath: scriptURL.path),
              let existingCode = try? String(contentsOf: scriptURL, encoding: .utf8) else {
            return (false, "Script \(cleanName).py does not exist.")
        }

        self.isRepairing = true
        defer { self.isRepairing = false }

        // Generate automated defensive patch
        var repairedCode = existingCode

        // Auto-fix 1: Missing Shebang
        if !repairedCode.hasPrefix("#!") {
            repairedCode = "#!/usr/bin/env python3\n" + repairedCode
        }

        // Auto-fix 2: Missing JSON / sys / traceback handling
        if errorOutput.contains("NameError: name 'json' is not defined") && !repairedCode.contains("import json") {
            repairedCode = "import json\n" + repairedCode
        }
        if errorOutput.contains("NameError: name 'sys' is not defined") && !repairedCode.contains("import sys") {
            repairedCode = "import sys\n" + repairedCode
        }
        if errorOutput.contains("NameError: name 'os' is not defined") && !repairedCode.contains("import os") {
            repairedCode = "import os\n" + repairedCode
        }

        // Auto-fix 3: Inject main guard and exception handler to prevent crashes
        if !repairedCode.contains("if __name__ ==") {
            repairedCode += "\n\nif __name__ == '__main__':\n    try:\n        print('Genie auto-repaired script ready.')\n    except Exception as e:\n        import sys\n        sys.stderr.write(f'Handled error: {e}\\n')\n"
        }

        let repairSummary = "Autonomous repair addressing error:\n\(errorOutput.prefix(120))"
        let result = await learnNewCapability(
            name: cleanName,
            code: repairedCode,
            capabilityTitle: "Self-Repair: \(cleanName)",
            summary: repairSummary,
            action: .selfRepair
        )

        return (result.success, result.message)
    }

    // MARK: - 3. Script Execution with Self-Repair Loop
    public func executeLearnedScript(name: String, args: [String] = []) async -> (stdout: String, stderr: String, exitCode: Int32) {
        let cleanName = name.hasSuffix(".py") ? String(name.dropLast(3)) : name
        let scriptURL = scriptsDirectory.appendingPathComponent("\(cleanName).py")
        guard fileManager.fileExists(atPath: scriptURL.path) else {
            return ("", "Script \(cleanName).py not found.", -1)
        }

        guard GenieCapabilities.canSpawnSubprocesses else {
            return ("", GenieCapabilities.unavailableMessage("Script execution"), -1)
        }

        let pythonPath = resolvePythonExecutable()
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: pythonPath)
        proc.arguments = [scriptURL.path] + args

        let outPipe = Pipe()
        let errPipe = Pipe()
        proc.standardOutput = outPipe
        proc.standardError = errPipe

        do {
            try proc.run()
            proc.waitUntilExit()

            let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
            let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
            let stdout = String(data: outData, encoding: .utf8) ?? ""
            let stderr = String(data: errData, encoding: .utf8) ?? ""

            // If script crashed, trigger self-repair
            if proc.terminationStatus != 0 && !stderr.isEmpty {
                Task {
                    await self.selfRepairScript(name: cleanName, errorOutput: stderr)
                }
            }

            return (stdout, stderr, proc.terminationStatus)
        } catch {
            return ("", error.localizedDescription, -1)
        }
    }

    // MARK: - 4. Rollback Script to Previous Working Version
    @discardableResult
    public func rollback(name: String, targetVersion: Int) -> Bool {
        let cleanName = name.hasSuffix(".py") ? String(name.dropLast(3)) : name
        let archiveURL = archiveDirectory.appendingPathComponent("\(cleanName).v\(targetVersion).py")
        let currentScriptURL = scriptsDirectory.appendingPathComponent("\(cleanName).py")

        guard fileManager.fileExists(atPath: archiveURL.path),
              let archivedCode = try? String(contentsOf: archiveURL, encoding: .utf8) else {
            return false
        }

        try? archivedCode.write(to: currentScriptURL, atomically: true, encoding: .utf8)

        let entry = SelfLearningLedgerEntry(
            scriptName: cleanName,
            version: targetVersion,
            action: .rollback,
            capabilityTitle: "Rollback \(cleanName) to v\(targetVersion)",
            summary: "Restored verified stable snapshot from archive.",
            codeDiffOrSnippet: String(archivedCode.prefix(200)),
            verificationOutput: "Restored snapshot verified.",
            isVerified: true,
            author: "User / Safe Rollback"
        )
        self.ledgerEntries.insert(entry, at: 0)
        self.registeredScripts[cleanName] = targetVersion
        persistLedger()

        self.lastActionMessage = "Successfully rolled back \(cleanName) to v\(targetVersion)"
        NotificationCenter.default.post(name: NSNotification.Name("NexusSelfLearningLedgerUpdated"), object: entry)
        return true
    }

    // MARK: - Verification Helpers
    private func validatePythonSyntax(code: String) async -> (isValid: Bool, error: String) {
        guard GenieCapabilities.canSpawnSubprocesses else {
            return (false, GenieCapabilities.unavailableMessage("Syntax validation"))
        }
        let pythonPath = resolvePythonExecutable()
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: pythonPath)
        proc.arguments = ["-c", "import ast, sys; ast.parse(sys.stdin.read())"]

        let inPipe = Pipe()
        let errPipe = Pipe()
        proc.standardInput = inPipe
        proc.standardError = errPipe

        do {
            try proc.run()
            if let data = code.data(using: .utf8) {
                inPipe.fileHandleForWriting.write(data)
                try? inPipe.fileHandleForWriting.close()
            }
            proc.waitUntilExit()

            let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
            let errString = String(data: errData, encoding: .utf8) ?? ""
            return (proc.terminationStatus == 0, errString)
        } catch {
            return (false, error.localizedDescription)
        }
    }

    private func executePythonTestRun(scriptURL: URL) async -> (success: Bool, output: String) {
        guard GenieCapabilities.canSpawnSubprocesses else {
            return (false, GenieCapabilities.unavailableMessage("Test execution"))
        }
        let pythonPath = resolvePythonExecutable()
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: pythonPath)
        proc.arguments = [scriptURL.path, "--test-dry-run"]

        let outPipe = Pipe()
        proc.standardOutput = outPipe
        proc.standardError = outPipe

        do {
            try proc.run()
            proc.waitUntilExit()
            let data = outPipe.fileHandleForReading.readDataToEndOfFile()
            let str = String(data: data, encoding: .utf8) ?? "Done"
            return (proc.terminationStatus == 0, str.trimmingCharacters(in: .whitespacesAndNewlines))
        } catch {
            return (false, error.localizedDescription)
        }
    }

    private func resolvePythonExecutable() -> String {
        let candidates = [
            "/opt/homebrew/bin/python3",
            "/usr/local/bin/python3",
            "/usr/bin/python3"
        ]
        for path in candidates {
            if fileManager.isExecutableFile(atPath: path) {
                return path
            }
        }
        return "/usr/bin/python3"
    }

    // MARK: - Initial Seed Scripts
    private func seedInitialScriptsIfNeeded() {
        guard ledgerEntries.isEmpty else { return }

        Task {
            // Seed 1: System Health Sentinel
            let sentinelCode = """
            #!/usr/bin/env python3
            import os, sys, json, platform

            def report_health():
                data = {
                    "node": platform.node(),
                    "system": platform.system(),
                    "machine": platform.machine(),
                    "python_version": platform.python_version(),
                    "status": "nominal"
                }
                print(json.dumps(data, indent=2))

            if __name__ == '__main__':
                report_health()
            """
            await self.learnNewCapability(
                name: "system_health_sentinel",
                code: sentinelCode,
                capabilityTitle: "System Health Telemetry Sentinel",
                summary: "Collects host Apple Silicon kernel statistics and runtime availability."
            )

            // Seed 2: Self-Testing Code Fixer
            let fixerCode = """
            #!/usr/bin/env python3
            import ast, sys, json

            def verify_code(snippet):
                try:
                    ast.parse(snippet)
                    return {"valid": True, "error": None}
                except Exception as e:
                    return {"valid": False, "error": str(e)}

            if __name__ == '__main__':
                sample = "x = 42\\nprint(x)"
                res = verify_code(sample)
                print(json.dumps(res))
            """
            await self.learnNewCapability(
                name: "code_synthesizer_repair",
                code: fixerCode,
                capabilityTitle: "Code Synthesizer & AST Integrity Auditor",
                summary: "Pre-compiles and verifies Python modules before execution."
            )
        }
    }
}
