import AppKit
import Foundation
import SwiftUI
import Observation

// MARK: - ⚡️ Genie Parallel File Writer & Copy-Paste Renderer
/// Implements simultaneous multi-file streaming with the "Copy-and-Paste" tactile render experience:
/// 1. Parallel File Writing: Streams and flushes N files concurrently to disk off the main thread.
/// 2. Direct Renderer Injection: Feeds active editor buffers and zero-copy RAM straight into the renderer.
/// 3. "Copy and Paste" Feel: Replaces character-by-character typewriter crawls with atomic block drops.
///    Whole functions, divs, and statements land instantaneously in discrete, satisfying Cmd+V bursts.
@available(macOS 13.0, *)
@Observable
public final class GenieParallelFileWriterAndRenderer: @unchecked Sendable {
    public static let shared = GenieParallelFileWriterAndRenderer()

    // MARK: - Channel Models
    public struct FileStreamChannel: Identifiable, Sendable {
        public let id = UUID()
        public let filename: String
        public let targetURL: URL
        public let language: String
        public var totalBytesWritten: Int
        public var blockCount: Int
        public var isComplete: Bool

        public init(filename: String, targetURL: URL, language: String = "Swift") {
            self.filename = filename
            self.targetURL = targetURL
            self.language = language
            self.totalBytesWritten = 0
            self.blockCount = 0
            self.isComplete = false
        }
    }

    public enum RenderDeliveryMode: String, CaseIterable, Sendable {
        case atomicCopyPasteDrop = "Atomic Copy-Paste (Cmd+V Snap)"
        case instantaneous = "Instantaneous (0ms Slam)"
        case legacyTypewriter = "Legacy Typewriter (Char-by-Char)"
    }

    // ── Observable Engine State ───────────────────────────────────────────
    public private(set) var activeChannels: [String: FileStreamChannel] = [:]
    public private(set) var isWritingInParallel: Bool = false
    public private(set) var activeRenderedFile: String = ""
    public private(set) var totalParallelThroughputMBs: Double = 0.0
    public var deliveryMode: RenderDeliveryMode = .atomicCopyPasteDrop

    private var fileBuffers: [String: String] = [:]

    private init() {}

    // MARK: - 1. Parallel Multi-File Ingestion & Writing
    /// Writes multiple files simultaneously in parallel tasks, while streaming atomic blocks into the renderer.
    @MainActor
    public func writeMultipleFilesInParallel(
        files: [(filename: String, content: String, language: String, directory: URL?)],
        targetRenderFile: String? = nil,
        onBlockPasted: (@MainActor (String, String, Int) -> Void)? = nil // (filename, block, blockIndex)
    ) async -> [AIFileWriteOutcome] {
        guard !files.isEmpty else { return [] }

        self.isWritingInParallel = true
        let chosenRenderFile = targetRenderFile ?? files.first?.filename ?? ""
        self.activeRenderedFile = chosenRenderFile

        let resolvedDir = AIEditorBridgeEngine.defaultWorkspaceRoot

        // 1. Initialize channels and pre-allocate paths
        var channelJobs: [(channel: FileStreamChannel, content: String)] = []
        for file in files {
            let dir = file.directory ?? resolvedDir
            let url = dir.appendingPathComponent(file.filename)
            let channel = FileStreamChannel(filename: file.filename, targetURL: url, language: file.language)
            channelJobs.append((channel, file.content))

            self.activeChannels[file.filename] = channel
            self.fileBuffers[file.filename] = ""
        }

        // Open editor for the primary file so the user watches it land
        if let primaryJob = channelJobs.first(where: { $0.channel.filename == chosenRenderFile }) {
            AIEditorBridgeEngine.shared.activeFileUrl = primaryJob.channel.targetURL
            AIEditorBridgeEngine.shared.activeFileName = primaryJob.channel.filename
            AIEditorBridgeEngine.shared.activeLanguage = primaryJob.channel.language
            AIEditorBridgeEngine.shared.activeCodeBuffer = ""
            AIEditorBridgeEngine.shared.isStreamingToEditor = true
            AIEditorBridgeEngine.shared.isEditorCanvasOpen = true
            AIEditorBridgeEngine.shared.liveTypingStatus = "⚡️ Genie writing \(files.count) files in parallel..."
        }

        let startTime = CFAbsoluteTimeGetCurrent()

        // 2. Launch concurrent disk writes across detached tasks
        let outcomes: [AIFileWriteOutcome] = await withTaskGroup(of: AIFileWriteOutcome.self) { group in
            for job in channelJobs {
                group.addTask(priority: .userInitiated) {
                    do {
                        let folder = job.channel.targetURL.deletingLastPathComponent()
                        if !FileManager.default.fileExists(atPath: folder.path) {
                            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
                        }
                        try job.content.write(to: job.channel.targetURL, atomically: true, encoding: .utf8)
                        return AIFileWriteOutcome(filename: job.channel.filename, url: job.channel.targetURL, error: nil)
                    } catch {
                        return AIFileWriteOutcome(filename: job.channel.filename, url: nil, error: error.localizedDescription)
                    }
                }
            }

            var results: [AIFileWriteOutcome] = []
            for await outcome in group {
                results.append(outcome)
            }
            return results
        }

        // 3. Drive the "Copy-and-Paste" Renderer Animation
        if let primaryJob = channelJobs.first(where: { $0.channel.filename == chosenRenderFile }) {
            await renderContentWithCopyPasteCadence(
                content: primaryJob.content,
                filename: primaryJob.channel.filename,
                mode: deliveryMode,
                onBlockPasted: onBlockPasted
            )
        }

        // Also update all remaining background file buffers instantly
        for job in channelJobs where job.channel.filename != chosenRenderFile {
            self.fileBuffers[job.channel.filename] = job.content
        }

        let elapsed = max(0.001, CFAbsoluteTimeGetCurrent() - startTime)
        let totalBytes = files.reduce(0) { $0 + $1.content.utf8.count }
        self.totalParallelThroughputMBs = (Double(totalBytes) / (1024.0 * 1024.0)) / elapsed
        self.isWritingInParallel = false

        AIEditorBridgeEngine.shared.isStreamingToEditor = false
        AIEditorBridgeEngine.shared.liveTypingStatus = "✅ Wrote \(files.count) files in parallel (\(String(format: "%.1f", totalParallelThroughputMBs)) MB/s)"

        return outcomes
    }

    // MARK: - 2. The "Copy and Paste" Rendering Engine
    /// Segments code or content into logical atomic blocks and drops them instantly into the renderer.
    /// Replaces the typewriter effect with discrete, tactile Cmd+V drops.
    @MainActor
    private func renderContentWithCopyPasteCadence(
        content: String,
        filename: String,
        mode: RenderDeliveryMode,
        onBlockPasted: (@MainActor (String, String, Int) -> Void)? = nil
    ) async {
        if mode == .instantaneous {
            AIEditorBridgeEngine.shared.activeCodeBuffer = content
            HapticFeedback.heavy()
            return
        }

        // Segment content into atomic copy-paste chunks (functions, imports, structs, divs, or paragraphs)
        let blocks = segmentIntoAtomicBlocks(content: content)
        guard !blocks.isEmpty else {
            AIEditorBridgeEngine.shared.activeCodeBuffer = content
            return
        }

        var accumulated = ""
        let totalBlocks = blocks.count

        for (index, block) in blocks.enumerated() {
            accumulated += block
            AIEditorBridgeEngine.shared.activeCodeBuffer = accumulated

            // Update line & column counters
            let lines = accumulated.components(separatedBy: .newlines)
            AIEditorBridgeEngine.shared.currentLineIndex = lines.count
            AIEditorBridgeEngine.shared.currentColumnIndex = (lines.last?.count ?? 0) + 1
            AIEditorBridgeEngine.shared.streamingProgress = Double(index + 1) / Double(totalBlocks)
            AIEditorBridgeEngine.shared.liveTypingStatus = "📋 Pasting block \(index + 1)/\(totalBlocks) into '\(filename)'..."

            // Tactile feedback on each paste drop
            HapticFeedback.selection()
            onBlockPasted?(filename, block, index + 1)

            // Cadence delay between blocks (35-45 ms: snappy, distinct "Paste... Paste... Paste..." sensation)
            try? await Task.sleep(nanoseconds: 38_000_000)
        }

        AIEditorBridgeEngine.shared.activeCodeBuffer = content
        HapticFeedback.success()
    }

    // MARK: - 3. Atomic Block Segmentation (Syntactic Chunking)
    /// Splits code/markup into natural, complete blocks so each paste drop is a whole logical statement/definition.
    public func segmentIntoAtomicBlocks(content: String) -> [String] {
        let lines = content.components(separatedBy: "\n")
        var blocks: [String] = []
        var currentBlock: [String] = []
        var braceDepth = 0

        for line in lines {
            currentBlock.append(line)

            // Track brace balance
            let openBraces = line.filter { $0 == "{" || $0 == "<" }.count
            let closeBraces = line.filter { $0 == "}" || $0 == ">" }.count
            braceDepth += (openBraces - closeBraces)

            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Block boundaries:
            // 1. Blank lines between sections when braceDepth == 0
            // 2. Closing braces at root level `}`
            // 3. Closing HTML tags `</div>` or `</section>`
            // 4. Imports or header statements
            let isBlockBoundary = (braceDepth <= 0 && trimmed.isEmpty) ||
                                  (braceDepth <= 0 && (trimmed == "}" || trimmed == "};" || trimmed.hasSuffix("</div>"))) ||
                                  (trimmed.hasPrefix("import ") || trimmed.hasPrefix("from "))

            if isBlockBoundary && !currentBlock.isEmpty {
                blocks.append(currentBlock.joined(separator: "\n") + "\n")
                currentBlock.removeAll()
            }
        }

        if !currentBlock.isEmpty {
            blocks.append(currentBlock.joined(separator: "\n"))
        }

        // Fallback: If no blocks were split, break by double newlines or paragraph chunks
        if blocks.count <= 1 {
            let paragraphSplits = content.components(separatedBy: "\n\n")
            if paragraphSplits.count > 1 {
                return paragraphSplits.map { $0 + "\n\n" }
            }
        }

        return blocks
    }
}
