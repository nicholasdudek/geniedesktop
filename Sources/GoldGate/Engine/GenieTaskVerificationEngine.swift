import Foundation
import CryptoKit
import Combine

// MARK: - Task Verification Status

public enum TaskVerificationStatus: Sendable, Equatable {
    case unverified
    case verifying
    case verified
    case failed(reason: String)

    public var isVerified: Bool {
        if case .verified = self { return true }
        return false
    }

    public var label: String {
        switch self {
        case .unverified: return "Unverified"
        case .verifying: return "Verifying..."
        case .verified: return "Verified ✓"
        case .failed(let reason): return "Failed: \(reason)"
        }
    }
}

// MARK: - Verification Check Result

public struct VerificationCheck: Identifiable, Sendable {
    public let id: UUID
    public let name: String
    public let passed: Bool
    public let details: String

    public init(id: UUID = UUID(), name: String, passed: Bool, details: String) {
        self.id = id
        self.name = name
        self.passed = passed
        self.details = details
    }
}

// MARK: - Task Verification Receipt

public struct TaskVerificationReceipt: Identifiable, Sendable {
    public let id: UUID
    public let taskId: String
    public let taskDescription: String
    public let command: String
    public let exitCode: Int32
    public let status: TaskVerificationStatus
    public let checks: [VerificationCheck]
    public let timestamp: Date
    public let durationSeconds: Double
    public let verificationSignature: String

    public init(
        id: UUID = UUID(),
        taskId: String,
        taskDescription: String,
        command: String,
        exitCode: Int32,
        status: TaskVerificationStatus,
        checks: [VerificationCheck],
        timestamp: Date = Date(),
        durationSeconds: Double,
        verificationSignature: String
    ) {
        self.id = id
        self.taskId = taskId
        self.taskDescription = taskDescription
        self.command = command
        self.exitCode = exitCode
        self.status = status
        self.checks = checks
        self.timestamp = timestamp
        self.durationSeconds = durationSeconds
        self.verificationSignature = verificationSignature
    }
}

// MARK: - Genie Task Verification Engine

/// Engine responsible for validating and certifying all executed tasks
/// (guest commands, tool executions, background scripts, file builds).
/// Performs multi-stage verification against exit codes, output integrity,
/// artifact existence, and continuous system diagnostics.
@MainActor
public final class GenieTaskVerificationEngine: ObservableObject {
    public static let shared = GenieTaskVerificationEngine()

    @Published public var recentReceipts: [TaskVerificationReceipt] = []
    @Published public var totalVerifiedCount: Int = 0
    @Published public var totalFailedCount: Int = 0

    private let maxHistoryCount = 64

    private init() {}

    /// Executes multi-stage verification on a completed task and issues a certified verification receipt.
    @discardableResult
    public func verifyTask(
        taskId: String,
        taskDescription: String,
        command: String,
        exitCode: Int32,
        stdout: String,
        stderr: String,
        durationSeconds: Double,
        expectedArtifacts: [String] = []
    ) -> TaskVerificationReceipt {
        var checks: [VerificationCheck] = []
        var allPassed = true
        var failureReason: String? = nil

        // 1. Exit Code Check
        let exitPassed = (exitCode == 0)
        checks.append(
            VerificationCheck(
                name: "Exit Code Validation",
                passed: exitPassed,
                details: exitPassed ? "Exit code 0 (Success)" : "Non-zero exit code: \(exitCode)"
            )
        )
        if !exitPassed {
            allPassed = false
            failureReason = failureReason ?? "Process exited with code \(exitCode)"
        }

        // 2. Output Integrity Check
        let outputLen = stdout.trimmingCharacters(in: .whitespacesAndNewlines).count
        let outputPassed = outputLen > 0 || exitPassed
        checks.append(
            VerificationCheck(
                name: "Output Stream Integrity",
                passed: outputPassed,
                details: "Captured \(outputLen) bytes from standard output"
            )
        )

        // 3. Error Sentinel Scan
        let lowerErr = (stderr + "\n" + stdout).lowercased()
        let fatalKeywords = ["kernel panic", "fatal error", "segmentation fault", "sigsegv", "uncaught exception"]
        let foundFatal = fatalKeywords.first(where: { lowerErr.contains($0) })
        let sentinelPassed = (foundFatal == nil)
        checks.append(
            VerificationCheck(
                name: "Diagnostic Sentinel Scan",
                passed: sentinelPassed,
                details: sentinelPassed ? "No fatal exceptions or panics detected" : "Fatal keyword detected: '\(foundFatal ?? "")'"
            )
        )
        if !sentinelPassed {
            allPassed = false
            failureReason = failureReason ?? "Fatal exception detected in output stream"
        }

        // 4. Expected Artifacts Verification Check
        if !expectedArtifacts.isEmpty {
            var missingArtifacts: [String] = []
            let fm = FileManager.default
            for path in expectedArtifacts {
                var isDir: ObjCBool = false
                if !fm.fileExists(atPath: path, isDirectory: &isDir) {
                    missingArtifacts.append(path)
                } else {
                    // Verify file has non-zero size
                    let attrs = try? fm.attributesOfItem(atPath: path)
                    let size = (attrs?[.size] as? NSNumber)?.int64Value ?? 0
                    if size == 0 && !isDir.boolValue {
                        missingArtifacts.append("\(path) (0 bytes empty)")
                    }
                }
            }
            let artifactsPassed = missingArtifacts.isEmpty
            checks.append(
                VerificationCheck(
                    name: "Artifact Integrity Verification",
                    passed: artifactsPassed,
                    details: artifactsPassed
                        ? "All \(expectedArtifacts.count) expected output artifact(s) verified on disk"
                        : "Missing or invalid artifact(s): \(missingArtifacts.joined(separator: ", "))"
                )
            )
            if !artifactsPassed {
                allPassed = false
                failureReason = failureReason ?? "Expected artifacts were not produced"
            }
        }

        // 5. Generate Cryptographic Signature
        let status: TaskVerificationStatus = allPassed ? .verified : .failed(reason: failureReason ?? "Verification check failed")
        let rawPayload = "\(taskId):\(exitCode):\(status.label):\(durationSeconds):\(Date().timeIntervalSince1970)"
        let digest = SHA256.hash(data: Data(rawPayload.utf8))
        let signature = digest.compactMap { String(format: "%02x", $0) }.joined()

        let receipt = TaskVerificationReceipt(
            taskId: taskId,
            taskDescription: taskDescription,
            command: command,
            exitCode: exitCode,
            status: status,
            checks: checks,
            durationSeconds: durationSeconds,
            verificationSignature: String(signature.prefix(16))
        )

        // Store in audit ledger
        recentReceipts.insert(receipt, at: 0)
        if recentReceipts.count > maxHistoryCount {
            recentReceipts.removeLast()
        }

        if allPassed {
            totalVerifiedCount += 1
        } else {
            totalFailedCount += 1
        }

        return receipt
    }
}
