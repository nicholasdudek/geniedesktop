import AppKit
import Foundation

// MARK: - 👷‍♂️ Worker Node Instruction Types
public enum GenieWorkerInstructionType: Sendable {
    case shell(command: String)
    case patch(filePath: String, replacement: String, target: String?)
    case write(filePath: String, content: String)
    case verify(testCommand: String)
    case stageArtifact(sourceRelPath: String, artifactName: String)
    case promoteViaTrashAirlock(artifactName: String, desktopName: String?)
}

public struct GenieWorkerInstruction: Identifiable, Sendable {
    public let id: UUID
    public let title: String
    public let type: GenieWorkerInstructionType
    public let allowFailure: Bool
    public let timeoutSeconds: Double

    public init(
        id: UUID = UUID(),
        title: String,
        type: GenieWorkerInstructionType,
        allowFailure: Bool = false,
        timeoutSeconds: Double = 60.0
    ) {
        self.id = id
        self.title = title
        self.type = type
        self.allowFailure = allowFailure
        self.timeoutSeconds = timeoutSeconds
    }
}

public struct GenieInstructionResult: Identifiable, Sendable {
    public let id: UUID
    public let instructionId: UUID
    public let title: String
    public let succeeded: Bool
    public let exitCode: Int32
    public let output: String
    public let error: String?
    public let durationMs: Double
    public let timestamp: Date

    public init(
        instructionId: UUID,
        title: String,
        succeeded: Bool,
        exitCode: Int32,
        output: String,
        error: String? = nil,
        durationMs: Double,
        timestamp: Date = Date()
    ) {
        self.id = UUID()
        self.instructionId = instructionId
        self.title = title
        self.succeeded = succeeded
        self.exitCode = exitCode
        self.output = output
        self.error = error
        self.durationMs = durationMs
        self.timestamp = timestamp
    }
}

public enum GenieWorkerStatus: String, Sendable {
    case idle = "Idle"
    case dropped = "Dropped into Fork"
    case executing = "Executing Instructions"
    case succeeded = "Fork Completed Succeeded"
    case failed = "Fork Failed"
    case cancelled = "Cancelled"
}

// MARK: - 🔱 Autonomous Fork Worker Node
/// Autonomous worker node dropped into an APFS zero-copy fork or RAMDisk space.
/// Executes an ordered sequence of instructions strictly in sequence,
/// reports real-time step progress, and finalizes output artifacts.
@MainActor
public final class GenieForkWorkerNode: ObservableObject, Identifiable {
    public let id: UUID
    public let name: String
    public let forkURL: URL
    public let instructions: [GenieWorkerInstruction]

    @Published public private(set) var status: GenieWorkerStatus = .idle
    @Published public private(set) var currentStepIndex: Int = 0
    @Published public private(set) var currentStepTitle: String = ""
    @Published public private(set) var progress: Double = 0.0
    @Published public private(set) var stepResults: [GenieInstructionResult] = []
    @Published public private(set) var statusMessage: String = "Ready"
    @Published public private(set) var completedTimestamp: Date?

    private var isCancelled: Bool = false

    public init(id: UUID = UUID(), name: String, forkURL: URL, instructions: [GenieWorkerInstruction]) {
        self.id = id
        self.name = name
        self.forkURL = forkURL
        self.instructions = instructions
        self.status = .dropped
        self.statusMessage = "Worker '\(name)' dropped into fork at \(forkURL.lastPathComponent)"
    }

    public func cancel() {
        self.isCancelled = true
        self.status = .cancelled
        self.statusMessage = "Worker cancelled by user"
    }

    /// Executes all instructions strictly in sequence ("all in sequence")
    public func executeSequence() async -> Bool {
        guard !instructions.isEmpty else {
            self.status = .succeeded
            self.progress = 1.0
            self.statusMessage = "No instructions specified; completed immediately."
            return true
        }

        self.status = .executing
        self.progress = 0.0
        self.stepResults.removeAll()

        for (index, instruction) in instructions.enumerated() {
            if isCancelled {
                self.status = .cancelled
                return false
            }

            self.currentStepIndex = index
            self.currentStepTitle = instruction.title
            self.statusMessage = "[\(index + 1)/\(instructions.count)] \(instruction.title)..."
            self.progress = Double(index) / Double(instructions.count)

            let startTime = Date()
            let result = await executeSingleInstruction(instruction)
            let elapsed = Date().timeIntervalSince(startTime) * 1000.0

            let finalResult = GenieInstructionResult(
                instructionId: instruction.id,
                title: instruction.title,
                succeeded: result.succeeded,
                exitCode: result.exitCode,
                output: result.output,
                error: result.error,
                durationMs: elapsed
            )
            self.stepResults.append(finalResult)

            if !result.succeeded && !instruction.allowFailure {
                self.status = .failed
                self.statusMessage = "Failed at step \(index + 1): '\(instruction.title)' (Exit \(result.exitCode))"
                self.completedTimestamp = Date()
                return false
            }
        }

        self.progress = 1.0
        self.currentStepIndex = instructions.count
        self.status = .succeeded
        self.statusMessage = "All \(instructions.count) fork instructions completed successfully."
        self.completedTimestamp = Date()
        return true
    }

    // MARK: - Instruction Execution

    private func executeSingleInstruction(_ instruction: GenieWorkerInstruction) async -> (succeeded: Bool, exitCode: Int32, output: String, error: String?) {
        switch instruction.type {
        case .shell(let command):
            let res = await GenieSandboxedExecutionEngine.shared.execute(
                command: command,
                customWorkspace: self.forkURL,
                timeout: instruction.timeoutSeconds
            )
            return (res.exitCode == 0, res.exitCode, res.output, res.exitCode == 0 ? nil : res.output)

        case .verify(let testCommand):
            let res = await GenieSandboxedExecutionEngine.shared.execute(
                command: testCommand,
                customWorkspace: self.forkURL,
                timeout: instruction.timeoutSeconds
            )
            let success = (res.exitCode == 0)
            return (success, res.exitCode, res.output, success ? nil : "Verification failed: \(res.output)")

        case .write(let filePath, let content):
            let targetURL = forkURL.appendingPathComponent(filePath)
            do {
                try FileManager.default.createDirectory(at: targetURL.deletingLastPathComponent(), withIntermediateDirectories: true)
                try content.write(to: targetURL, atomically: true, encoding: .utf8)
                return (true, 0, "Successfully wrote \(content.count) bytes to \(filePath)", nil)
            } catch {
                return (false, 1, "", error.localizedDescription)
            }

        case .patch(let filePath, let replacement, let target):
            let targetURL = forkURL.appendingPathComponent(filePath)
            guard let existing = try? String(contentsOf: targetURL, encoding: .utf8) else {
                return (false, 1, "", "File not found for patching: \(filePath)")
            }

            var patched: String
            if let targetText = target, !targetText.isEmpty {
                guard existing.contains(targetText) else {
                    return (false, 2, "", "Target patch string not found in \(filePath)")
                }
                patched = existing.replacingOccurrences(of: targetText, with: replacement)
            } else {
                patched = replacement
            }

            do {
                try patched.write(to: targetURL, atomically: true, encoding: .utf8)
                return (true, 0, "Successfully patched \(filePath)", nil)
            } catch {
                return (false, 3, "", error.localizedDescription)
            }

        case .stageArtifact(let sourceRelPath, let artifactName):
            let sourceURL = forkURL.appendingPathComponent(sourceRelPath)
            guard FileManager.default.fileExists(atPath: sourceURL.path) else {
                return (false, 1, "", "Artifact source not found: \(sourceRelPath)")
            }

            do {
                let stagedURL = try GenieTrashAirlockGateway.shared.stageFile(sourceURL: sourceURL, targetName: artifactName)
                return (true, 0, "Staged artifact '\(artifactName)' into Trash Airlock at \(stagedURL.path)", nil)
            } catch {
                return (false, 2, "", "Failed to stage artifact: \(error.localizedDescription)")
            }

        case .promoteViaTrashAirlock(let artifactName, let desktopName):
            do {
                let desktopURL = try GenieTrashAirlockGateway.shared.promoteToDesktop(
                    airlockFileName: artifactName,
                    finalDesktopName: desktopName
                )
                return (true, 0, "Promoted '\(artifactName)' to Desktop via Trash Airlock at \(desktopURL.path)", nil)
            } catch {
                return (false, 1, "", "Failed to promote via Trash Airlock: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - 🎛️ Genie Worker Node Orchestrator
/// Drop-off manager that provisions APFS/RAM forks and dispatches worker nodes
/// with sequential instructions to finish builds, tests, or migrations.
@MainActor
public final class GenieWorkerNodeOrchestrator: ObservableObject {
    public static let shared = GenieWorkerNodeOrchestrator()

    @Published public private(set) var activeWorkers: [GenieForkWorkerNode] = []
    @Published public private(set) var completedWorkers: [GenieForkWorkerNode] = []

    private init() {}

    /// Drops an autonomous worker node directly into an existing fork directory
    @discardableResult
    public func dropWorker(
        name: String,
        into forkURL: URL,
        instructions: [GenieWorkerInstruction],
        autoRun: Bool = true
    ) -> GenieForkWorkerNode {
        let worker = GenieForkWorkerNode(name: name, forkURL: forkURL, instructions: instructions)
        activeWorkers.append(worker)

        if autoRun {
            Task { [weak self, weak worker] in
                guard let worker = worker else { return }
                _ = await worker.executeSequence()
                self?.handleWorkerCompletion(worker)
            }
        }

        return worker
    }

    /// Creates a zero-copy APFS folder fork of a project and drops a sequential worker node onto it
    public func dropWorkerOnSharedFork(
        sourceURL: URL,
        spaceName: String? = nil,
        workerName: String? = nil,
        instructions: [GenieWorkerInstruction],
        autoRun: Bool = true
    ) throws -> GenieForkWorkerNode {
        let forkURL = try GenieSharedFolderForkEngine.shared.forkProject(sourceURL: sourceURL, spaceName: spaceName)
        let name = workerName ?? "Worker-\(forkURL.lastPathComponent)"
        return dropWorker(name: name, into: forkURL, instructions: instructions, autoRun: autoRun)
    }

    /// Drops a worker onto the In-RAM VM APFS volume (200-800 GB/s bus speed)
    public func dropWorkerInRAM(
        subfolderName: String,
        instructions: [GenieWorkerInstruction],
        autoRun: Bool = true
    ) async throws -> GenieForkWorkerNode {
        let ramURL = try await GenieInRAMVMManager.shared.mountRAMDisk()
        let targetURL = ramURL.appendingPathComponent(subfolderName)
        try FileManager.default.createDirectory(at: targetURL, withIntermediateDirectories: true)

        let name = "RAM-Worker-\(subfolderName)"
        return dropWorker(name: name, into: targetURL, instructions: instructions, autoRun: autoRun)
    }

    public func cancelWorker(id: UUID) {
        if let worker = activeWorkers.first(where: { $0.id == id }) {
            worker.cancel()
            handleWorkerCompletion(worker)
        }
    }

    private func handleWorkerCompletion(_ worker: GenieForkWorkerNode) {
        activeWorkers.removeAll(where: { $0.id == worker.id })
        completedWorkers.insert(worker, at: 0)
        if completedWorkers.count > 20 {
            completedWorkers.removeLast()
        }
    }
}
