import Foundation
import CryptoKit

// MARK: - 🔀 Genie Dual-Stream Writer (print(wrapper(x2)))
/// Implements the Dual-Stream Architecture:
/// Emits LLM generation into two isolated output streams:
/// 1. File A: Clean User Stream (HTML / Markdown) - renders one complete <div> or statement at a time.
/// 2. File B: Agent Journal (JSONL) - raw fragments, microsecond telemetry, sha256 checksums, and self-reflection.
@available(macOS 13.0, *)
public final class GenieDualStreamWriter: @unchecked Sendable {
    public static let shared = GenieDualStreamWriter()

    public struct BlockJournalEntry: Codable, Sendable {
        public let blockId: Int
        public let timestamp: Double
        public let durationMs: Double
        public let tokenCount: Int
        public let sha256Hash: String
        public let rawFragmentChunks: [String]
        public let selfReflection: ReflectionMetadata

        public struct ReflectionMetadata: Codable, Sendable {
            public let isSyntaxBalanced: Bool
            public let targetContainer: String
            public let characterLength: Int
            public let purpose: String
        }
    }

    private let lock = NSLock()
    private var blockCounter: Int = 0
    private var tokenBuffer: [String] = []
    private var currentAccumulator: String = ""
    private var blockStartTime: Date = Date()

    // File destinations
    public var userFacingFileURL: URL?
    public var agentJournalFileURL: URL?

    public init(
        userFacingFileURL: URL? = nil,
        agentJournalFileURL: URL? = nil
    ) {
        let docsDir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop/Genie/GoldGate/docs")
        self.userFacingFileURL = userFacingFileURL ?? docsDir.appendingPathComponent("user_output.html")
        self.agentJournalFileURL = agentJournalFileURL ?? docsDir.appendingPathComponent("agent_internal_journal.jsonl")
    }

    // MARK: - Configuration & Setup
    public func resetStreams() {
        lock.lock()
        defer { lock.unlock() }

        blockCounter = 0
        tokenBuffer.removeAll()
        currentAccumulator = ""
        blockStartTime = Date()

        if let userURL = userFacingFileURL {
            try? FileManager.default.createDirectory(at: userURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let header = "<!-- 🧞 Genie Clean User Stream: Rendered Block-by-Block -->\n"
            try? header.write(to: userURL, atomically: true, encoding: .utf8)
        }

        if let journalURL = agentJournalFileURL {
            try? FileManager.default.createDirectory(at: journalURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try? "".write(to: journalURL, atomically: true, encoding: .utf8)
        }
    }

    // MARK: - Stream Ingestion: print(wrapper(x2))
    /// Ingests a raw streaming token fragment x2, accumulating until an atomic block boundary is detected.
    public func ingestTokenFragment(_ x2: String, mode: String = "div") {
        lock.lock()
        defer { lock.unlock() }

        tokenBuffer.append(x2)
        currentAccumulator += x2

        // Check if currentAccumulator contains a complete, balanced atomic block
        if isBlockComplete(currentAccumulator, mode: mode) {
            emitCurrentBlock(mode: mode)
        }
    }

    /// Manually flushes any remaining tokens in the buffer at stream completion
    public func flushRemaining(mode: String = "div") {
        lock.lock()
        defer { lock.unlock() }

        if !currentAccumulator.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            emitCurrentBlock(mode: mode, force: true)
        }
    }

    // MARK: - Atomic Block Detection (wrapper(x2) logic)
    private func isBlockComplete(_ text: String, mode: String) -> Bool {
        if mode == "div" {
            let openCount = text.components(separatedBy: "<div").count - 1
            let closeCount = text.components(separatedBy: "</div>").count - 1
            return openCount > 0 && openCount == closeCount
        } else if mode == "statement" {
            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
            return trimmed.hasSuffix(";") || trimmed.hasSuffix("}") || (trimmed.hasSuffix(".") && text.contains("\n"))
        }
        return false
    }

    // MARK: - Dual Dispatch
    private func emitCurrentBlock(mode: String, force: Bool = false) {
        let completeBlock = currentAccumulator.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !completeBlock.isEmpty else { return }

        blockCounter += 1
        let now = Date()
        let duration = max(0.01, (now.timeIntervalSince(blockStartTime)) * 1000.0)

        // Compute SHA-256 Checkpoint
        let inputData = Data(completeBlock.utf8)
        let hashBytes = SHA256.hash(data: inputData)
        let sha256String = hashBytes.map { String(format: "%02x", $0) }.joined()
        let shortHash = String(sha256String.prefix(12))

        // ── 1. WRITE TO USER FILE: Clean Atomic <div> ───────────────────────
        if let userURL = userFacingFileURL {
            let blockOutput = completeBlock + "\n\n"
            if let fileHandle = try? FileHandle(forWritingTo: userURL) {
                fileHandle.seekToEndOfFile()
                if let data = blockOutput.data(using: .utf8) {
                    fileHandle.write(data)
                }
                fileHandle.closeFile()
            }
        }

        // ── 2. WRITE TO AGENT JOURNAL: Internal Structured Telemetry ─────────
        let journalEntry = BlockJournalEntry(
            blockId: blockCounter,
            timestamp: now.timeIntervalSince1970,
            durationMs: (duration * 100).rounded() / 100,
            tokenCount: tokenBuffer.count,
            sha256Hash: shortHash,
            rawFragmentChunks: tokenBuffer,
            selfReflection: .init(
                isSyntaxBalanced: !force,
                targetContainer: mode,
                characterLength: completeBlock.count,
                purpose: "atomic_ui_statement_render"
            )
        )

        if let journalURL = agentJournalFileURL,
           let jsonData = try? JSONEncoder().encode(journalEntry),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            let lineOutput = jsonString + "\n"
            if let fileHandle = try? FileHandle(forWritingTo: journalURL) {
                fileHandle.seekToEndOfFile()
                if let data = lineOutput.data(using: .utf8) {
                    fileHandle.write(data)
                }
                fileHandle.closeFile()
            }
        }

        // Reset state for next atomic block
        tokenBuffer.removeAll()
        currentAccumulator = ""
        blockStartTime = Date()
    }
}
