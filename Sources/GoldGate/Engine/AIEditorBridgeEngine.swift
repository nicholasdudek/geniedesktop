import AppKit
import Foundation
import SwiftUI
import Combine

// MARK: - 💻 Live AI File Creation & Editor Streaming Event
public struct AIFileCreationEvent: Identifiable, Hashable {
    public let id: UUID
    public let filename: String
    public let fullPath: String
    public let language: String
    public let timestamp: Date
    public var status: String // "Writing...", "Created & Saved", "Failed: …"
    public var lineCount: Int
    public var byteCount: Int

    public init(
        id: UUID = UUID(),
        filename: String,
        fullPath: String,
        language: String,
        timestamp: Date = Date(),
        status: String = "Writing...",
        lineCount: Int = 0,
        byteCount: Int = 0
    ) {
        self.id = id
        self.filename = filename
        self.fullPath = fullPath
        self.language = language
        self.timestamp = timestamp
        self.status = status
        self.lineCount = lineCount
        self.byteCount = byteCount
    }
}

// MARK: - 📦 Batch File Creation
//
// One request per file Genie wants on disk. A batch is written concurrently, so
// "create these five files" costs one write, not five round-trips.

public struct AIFileWriteRequest: Sendable {
    public let filename: String
    public let content: String
    public let language: String
    /// Overrides the active workspace root for this file only.
    public let directory: URL?

    public init(filename: String, content: String, language: String = "Swift", directory: URL? = nil) {
        self.filename = filename
        self.content = content
        self.language = language
        self.directory = directory
    }
}

public struct AIFileWriteOutcome: Sendable {
    public let filename: String
    public let url: URL?
    public let error: String?
    public var succeeded: Bool { url != nil && error == nil }
}

/// Set by the run watchdog and read after the process exits, so a killed run is
/// reported as a timeout rather than as an ordinary non-zero exit.
private final class TimeoutFlag: @unchecked Sendable {
    private let lock = NSLock()
    private var value = false
    func set() { lock.lock(); value = true; lock.unlock() }
    var isSet: Bool { lock.lock(); defer { lock.unlock() }; return value }
}

// MARK: - 🎨 AI Editor Bridge Engine (Watch AI Create & Edit Files Live)
@MainActor
public final class AIEditorBridgeEngine: ObservableObject {
    public static let shared = AIEditorBridgeEngine()

    // ── Live Editor State & Observables ─────────────────────────────────────
    @Published public var activeFileUrl: URL? = nil
    @Published public var activeFileName: String = "Untitled.swift"
    @Published public var activeLanguage: String = "Swift"
    @Published public var activeCodeBuffer: String = ""
    @Published public var isStreamingToEditor: Bool = false
    @Published public var streamingProgress: Double = 0.0
    @Published public var currentLineIndex: Int = 1
    @Published public var currentColumnIndex: Int = 1
    @Published public var liveTypingStatus: String = "Editor Ready"
    @Published public var recentCreatedFiles: [AIFileCreationEvent] = []
    @Published public var isEditorCanvasOpen: Bool = false
    @Published public var activeWorkspaceRoot: URL? = nil

    /// The typewriter effect only. Cancelling it can never cost the user a file,
    /// because the disk write does not run inside it.
    private var animationTask: Task<Void, Never>? = nil

    private init() {
        self.activeWorkspaceRoot = Self.defaultWorkspaceRoot
    }

    // MARK: - 0. Where files go
    //
    // Genie writes into the user's own home folder — the Desktop by default,
    // which is also the only location the agent write boundary permits.

    public nonisolated static var defaultWorkspaceRoot: URL {
        FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory() + "/Desktop", isDirectory: true)
    }

    private func resolvedDirectory(_ override: URL?) -> URL {
        override ?? activeWorkspaceRoot ?? Self.defaultWorkspaceRoot
    }

    /// The single point where content actually reaches disk. `nonisolated` so a
    /// batch can run these off the main actor, genuinely in parallel.
    private nonisolated static func persist(_ content: String, to url: URL) throws {
        let folder = url.deletingLastPathComponent()
        if !FileManager.default.fileExists(atPath: folder.path) {
            try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        try content.write(to: url, atomically: true, encoding: .utf8)
    }

    private nonisolated static func write(_ content: String, to url: URL, filename: String) async -> AIFileWriteOutcome {
        await Task.detached(priority: .userInitiated) {
            do {
                try persist(content, to: url)
                return AIFileWriteOutcome(filename: filename, url: url, error: nil)
            } catch {
                return AIFileWriteOutcome(filename: filename, url: nil, error: error.localizedDescription)
            }
        }.value
    }

    /// One rescan and one notification for a whole batch, rather than one per
    /// file — `scanDesktop()` walks the entire Desktop every time it is called.
    private func refreshFileBrowsers(for urls: [URL]) {
        guard !urls.isEmpty else { return }
        DesktopFilesManager.shared.scanDesktop()
        NotificationCenter.default.post(name: NSNotification.Name("NexusWorkspaceFilesChanged"), object: urls.first)
    }

    private func markEvent(_ id: UUID, outcome: AIFileWriteOutcome, content: String) {
        guard let index = recentCreatedFiles.firstIndex(where: { $0.id == id }) else { return }
        if outcome.succeeded {
            recentCreatedFiles[index].status = "Created & Saved"
            recentCreatedFiles[index].lineCount = content.components(separatedBy: .newlines).count
            recentCreatedFiles[index].byteCount = content.utf8.count
        } else {
            recentCreatedFiles[index].status = "Failed: \(outcome.error ?? "unknown error")"
        }
    }

    // MARK: - 1. Stream Code Into the Editor (file lands on disk immediately)
    public func streamCodeToFile(
        filename: String,
        content: String,
        language: String = "Swift",
        targetDirectory: URL? = nil,
        openEditor: Bool = true,
        typingSpeedCharsPerSec: Double = 450.0,
        completion: ((URL?) -> Void)? = nil
    ) {
        let targetFileUrl = resolvedDirectory(targetDirectory).appendingPathComponent(filename)

        animationTask?.cancel()

        self.activeFileUrl = targetFileUrl
        self.activeFileName = filename
        self.activeLanguage = language
        self.activeCodeBuffer = ""
        self.isStreamingToEditor = true
        self.streamingProgress = 0.0
        self.liveTypingStatus = "✨ Genie is creating '\(filename)'..."

        if openEditor {
            self.isEditorCanvasOpen = true
            NotificationCenter.default.post(name: NSNotification.Name("NexusOpenEmbeddedEditor"), object: targetFileUrl)
        }

        let event = AIFileCreationEvent(
            filename: filename,
            fullPath: targetFileUrl.path,
            language: language,
            status: "Writing..."
        )
        self.recentCreatedFiles.insert(event, at: 0)

        HapticFeedback.heavy()

        // Durability first. The file exists within milliseconds; the animation
        // below is cosmetic and never gates the write. Previously the write ran
        // after the typewriter finished, so a 10 KB file took ~20 seconds to
        // appear and quitting mid-animation lost it entirely.
        Task {
            let outcome = await Self.write(content, to: targetFileUrl, filename: filename)
            self.markEvent(event.id, outcome: outcome, content: content)
            if outcome.succeeded {
                self.refreshFileBrowsers(for: [targetFileUrl])
                HapticFeedback.success()
            } else {
                self.animationTask?.cancel()
                self.isStreamingToEditor = false
                self.liveTypingStatus = "❌ Error writing file: \(outcome.error ?? "unknown error")"
            }
            completion?(outcome.url)
        }

        animationTask = Task { [weak self] in
            await self?.playTypewriter(content, filename: filename, speed: typingSpeedCharsPerSec)
        }
    }

    /// Purely visual. Bounded to `maxAnimationSeconds` so a large file reveals at
    /// the same pace as a small one instead of taking minutes.
    private func playTypewriter(_ content: String, filename: String, speed: Double) async {
        let chars = Array(content)
        let total = chars.count
        guard total > 0, speed > 0 else {
            self.activeCodeBuffer = content
            self.finishTypewriter(content, filename: filename)
            return
        }

        let maxAnimationSeconds = 0.45
        let frames = max(1, Int(maxAnimationSeconds * 60))
        let chunkSize = max(max(1, Int(speed / 60.0)), Int(ceil(Double(total) / Double(frames))))

        var index = 0
        while index < total {
            if Task.isCancelled { return }
            let next = min(index + chunkSize, total)
            let chunk = String(chars[index..<next])
            index = next

            self.activeCodeBuffer.append(chunk)
            let lines = self.activeCodeBuffer.components(separatedBy: .newlines)
            self.currentLineIndex = lines.count
            self.currentColumnIndex = (lines.last?.count ?? 0) + 1
            self.streamingProgress = Double(index) / Double(total)
            self.liveTypingStatus = "✨ Genie is writing '\(filename)' (Line \(self.currentLineIndex), Col \(self.currentColumnIndex))..."

            try? await Task.sleep(nanoseconds: 16_000_000) // ~60fps
        }

        if Task.isCancelled { return }
        self.finishTypewriter(content, filename: filename)
    }

    private func finishTypewriter(_ content: String, filename: String) {
        self.activeCodeBuffer = content
        self.streamingProgress = 1.0
        self.isStreamingToEditor = false
        self.liveTypingStatus = "✅ Created '\(filename)' successfully!"
    }

    // MARK: - 2. Quick File Creation (Direct Save)

    /// Creates one file. The write happens off the main actor so a large file
    /// never stalls the UI.
    @discardableResult
    public func createFile(name: String, content: String = "", directory: URL? = nil) async -> AIFileWriteOutcome {
        let results = await createFiles([AIFileWriteRequest(filename: name, content: content, directory: directory)])
        return results[0]
    }

    /// Creates every file in the batch **concurrently** and refreshes the
    /// browsers once at the end. Failures are reported per file; one bad path
    /// no longer aborts the rest of the batch.
    @discardableResult
    public func createFiles(_ requests: [AIFileWriteRequest]) async -> [AIFileWriteOutcome] {
        guard !requests.isEmpty else { return [] }

        // Resolve destinations and register every row up front, so the whole
        // batch appears at once instead of trickling in one file at a time.
        let jobs: [(request: AIFileWriteRequest, url: URL, eventID: UUID)] = requests.map { request in
            let url = resolvedDirectory(request.directory).appendingPathComponent(request.filename)
            let event = AIFileCreationEvent(
                filename: request.filename,
                fullPath: url.path,
                language: request.language,
                status: "Writing..."
            )
            recentCreatedFiles.insert(event, at: 0)
            return (request, url, event.id)
        }

        var outcomes = [AIFileWriteOutcome?](repeating: nil, count: jobs.count)
        await withTaskGroup(of: (Int, AIFileWriteOutcome).self) { group in
            for (index, job) in jobs.enumerated() {
                let content = job.request.content
                let url = job.url
                let filename = job.request.filename
                group.addTask(priority: .userInitiated) {
                    (index, await Self.write(content, to: url, filename: filename))
                }
            }
            for await (index, outcome) in group { outcomes[index] = outcome }
        }

        let results = outcomes.compactMap { $0 }
        for (job, outcome) in zip(jobs, results) {
            markEvent(job.eventID, outcome: outcome, content: job.request.content)
        }

        let written = results.compactMap(\.url)
        refreshFileBrowsers(for: written)

        if let last = written.last {
            self.activeFileUrl = last
            self.activeFileName = last.lastPathComponent
            if requests.count == 1 { self.activeCodeBuffer = requests[0].content }
        }
        if !written.isEmpty { HapticFeedback.success() }

        let failures = results.filter { !$0.succeeded }
        liveTypingStatus = failures.isEmpty
            ? "✅ Wrote \(written.count) file\(written.count == 1 ? "" : "s")."
            : "⚠️ Wrote \(written.count) of \(results.count); failed: \(failures.map(\.filename).joined(separator: ", "))"

        return results
    }

    /// Synchronous convenience kept for call sites that cannot await.
    @discardableResult
    public func createNewFile(name: String, content: String = "") -> URL? {
        let fileUrl = resolvedDirectory(nil).appendingPathComponent(name)
        do {
            try Self.persist(content, to: fileUrl)
            self.activeFileUrl = fileUrl
            self.activeFileName = name
            self.activeCodeBuffer = content
            refreshFileBrowsers(for: [fileUrl])
            return fileUrl
        } catch {
            liveTypingStatus = "❌ Error writing file: \(error.localizedDescription)"
            return nil
        }
    }

    // MARK: - 3. Execute a File in the Terminal / Interpreter

    public func runActiveFile() async -> (output: String, success: Bool) {
        guard let url = activeFileUrl else {
            return ("No active file to execute.", false)
        }
        return await Self.run(fileAt: url)
    }

    /// Resolves an interpreter by absolute path. An app launched from Finder
    /// inherits a minimal `PATH` that excludes `/opt/homebrew/bin`, so a bare
    /// `python3` fails with a bare "command not found" and no useful context.
    private nonisolated static func interpreter(forExtension ext: String) -> (path: String, arguments: [String])? {
        func firstExecutable(_ candidates: [String]) -> String? {
            candidates.first { FileManager.default.isExecutableFile(atPath: $0) }
        }
        switch ext {
        case "swift":
            return firstExecutable(["/usr/bin/swift", "/opt/homebrew/bin/swift", "/usr/local/bin/swift"]).map { ($0, []) }
        case "py":
            // -u keeps stdout unbuffered, so prints and the traceback that
            // follows them arrive in the right order down a pipe.
            return firstExecutable(["/opt/homebrew/bin/python3", "/usr/local/bin/python3", "/usr/bin/python3"]).map { ($0, ["-u"]) }
        case "js", "mjs":
            return firstExecutable(["/opt/homebrew/bin/node", "/usr/local/bin/node"]).map { ($0, []) }
        case "rb":
            return firstExecutable(["/opt/homebrew/bin/ruby", "/usr/bin/ruby"]).map { ($0, []) }
        case "sh", "zsh", "bash":
            return ("/bin/zsh", [])
        default:
            return ("/bin/cat", [])
        }
    }

    private nonisolated static func missingInterpreterMessage(for ext: String) -> String {
        switch ext {
        case "py":    return "No python3 found. Looked in /opt/homebrew/bin, /usr/local/bin and /usr/bin.\nInstall it with: brew install python"
        case "js", "mjs": return "No node found. Looked in /opt/homebrew/bin and /usr/local/bin.\nInstall it with: brew install node"
        case "swift": return "No swift found. Install the Xcode command line tools: xcode-select --install"
        default:      return "No interpreter available for .\(ext) files."
        }
    }

    public nonisolated static func run(fileAt url: URL, timeout: TimeInterval = 120) async -> (output: String, success: Bool) {
        guard FileManager.default.fileExists(atPath: url.path) else {
            return ("File is not on disk yet: \(url.path)", false)
        }
        guard GenieCapabilities.canSpawnSubprocesses else {
            return (GenieCapabilities.unavailableMessage("Running scripts"), false)
        }

        let ext = url.pathExtension.lowercased()
        guard let tool = interpreter(forExtension: ext) else {
            return (missingInterpreterMessage(for: ext), false)
        }

        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                let pipe = Pipe()
                process.executableURL = URL(fileURLWithPath: tool.path)
                process.arguments = tool.arguments + [url.path]
                process.currentDirectoryURL = url.deletingLastPathComponent()
                process.standardOutput = pipe
                process.standardError = pipe
                process.standardInput = FileHandle.nullDevice

                var environment = ProcessInfo.processInfo.environment
                let inheritedPath = environment["PATH"] ?? "/usr/bin:/bin:/usr/sbin:/sbin"
                environment["PATH"] = "/opt/homebrew/bin:/usr/local/bin:" + inheritedPath
                environment["PYTHONUNBUFFERED"] = "1"
                process.environment = environment

                do {
                    try process.run()
                } catch {
                    continuation.resume(returning: ("Could not start \(tool.path): \(error.localizedDescription)", false))
                    return
                }

                let expired = TimeoutFlag()
                let watchdog = DispatchWorkItem {
                    guard process.isRunning else { return }
                    expired.set()
                    process.terminate()
                }
                DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + timeout, execute: watchdog)

                // Drain before waiting. `waitUntilExit()` first deadlocks as soon
                // as the script prints more than the pipe buffer holds (~64 KB):
                // the child blocks writing, the parent blocks waiting, and the
                // Run button hangs with nothing shown.
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                process.waitUntilExit()
                watchdog.cancel()

                let text = String(decoding: data, as: UTF8.self)
                let status = process.terminationStatus
                if expired.isSet {
                    continuation.resume(returning: (text + "\n[Stopped after \(Int(timeout))s]", false))
                } else if status == 0 {
                    continuation.resume(returning: (text.isEmpty ? "(exit 0 · no output)" : text, true))
                } else {
                    let suffix = "\n[exit \(status)]"
                    continuation.resume(returning: (text.isEmpty ? "(exit \(status) · no output)" : text + suffix, false))
                }
            }
        }
    }

    // MARK: - 4. Reveal File in Finder
    public func revealInFinder() {
        guard let url = activeFileUrl else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
}
