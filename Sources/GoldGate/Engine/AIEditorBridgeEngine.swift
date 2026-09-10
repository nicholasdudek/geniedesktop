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
    public var status: String // "Streaming...", "Created & Saved", "Failed"
    public var lineCount: Int
    public var byteCount: Int

    public init(
        id: UUID = UUID(),
        filename: String,
        fullPath: String,
        language: String,
        timestamp: Date = Date(),
        status: String = "Streaming...",
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

    private var streamTask: Task<Void, Never>? = nil

    private init() {
        self.activeWorkspaceRoot = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first
    }

    // MARK: - 1. Stream Code Directly into Editor Live
    public func streamCodeToFile(
        filename: String,
        content: String,
        language: String = "Swift",
        targetDirectory: URL? = nil,
        openEditor: Bool = true,
        typingSpeedCharsPerSec: Double = 450.0,
        completion: ((URL?) -> Void)? = nil
    ) {
        streamTask?.cancel()

        let baseDir = targetDirectory ?? activeWorkspaceRoot ?? FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        let targetFileUrl = baseDir.appendingPathComponent(filename)

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
            status: "Streaming..."
        )
        self.recentCreatedFiles.insert(event, at: 0)

        HapticFeedback.heavy()

        streamTask = Task {
            let totalLength = content.count
            var currentIndex = 0
            let chars = Array(content)
            let chunkSize = max(1, Int(typingSpeedCharsPerSec / 60.0)) // 60fps chunks

            while currentIndex < totalLength {
                if Task.isCancelled { break }

                let nextIndex = min(currentIndex + chunkSize, totalLength)
                let chunkString = String(chars[currentIndex..<nextIndex])
                currentIndex = nextIndex

                await MainActor.run {
                    self.activeCodeBuffer.append(chunkString)
                    let currentLines = self.activeCodeBuffer.components(separatedBy: .newlines)
                    self.currentLineIndex = currentLines.count
                    self.currentColumnIndex = (currentLines.last?.count ?? 0) + 1
                    self.streamingProgress = Double(currentIndex) / Double(max(1, totalLength))
                    self.liveTypingStatus = "✨ Genie is writing '\(filename)' (Line \(self.currentLineIndex), Col \(self.currentColumnIndex))..."
                }

                try? await Task.sleep(nanoseconds: 16_000_000) // ~60fps typewriter effect
            }

            // Write final content safely to disk
            do {
                try FileManager.default.createDirectory(at: targetFileUrl.deletingLastPathComponent(), withIntermediateDirectories: true)
                try content.write(to: targetFileUrl, atomically: true, encoding: .utf8)

                await MainActor.run {
                    self.isStreamingToEditor = false
                    self.streamingProgress = 1.0
                    self.liveTypingStatus = "✅ Created '\(filename)' successfully!"
                    if let idx = self.recentCreatedFiles.firstIndex(where: { $0.id == event.id }) {
                        self.recentCreatedFiles[idx].status = "Created & Saved"
                        self.recentCreatedFiles[idx].lineCount = content.components(separatedBy: .newlines).count
                        self.recentCreatedFiles[idx].byteCount = content.utf8.count
                    }

                    // Refresh Desktop Files and Synced Workspace
                    DesktopFilesManager.shared.scanDesktop()
                    NotificationCenter.default.post(name: NSNotification.Name("NexusWorkspaceFilesChanged"), object: targetFileUrl)
                    HapticFeedback.success()
                    completion?(targetFileUrl)
                }
            } catch {
                await MainActor.run {
                    self.isStreamingToEditor = false
                    self.liveTypingStatus = "❌ Error writing file: \(error.localizedDescription)"
                    if let idx = self.recentCreatedFiles.firstIndex(where: { $0.id == event.id }) {
                        self.recentCreatedFiles[idx].status = "Failed: \(error.localizedDescription)"
                    }
                    completion?(nil)
                }
            }
        }
    }

    // MARK: - 2. Quick File Creation (Direct Save)
    public func createNewFile(name: String, content: String = "") -> URL? {
        let baseDir = activeWorkspaceRoot ?? FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        let fileUrl = baseDir.appendingPathComponent(name)
        do {
            try FileManager.default.createDirectory(at: fileUrl.deletingLastPathComponent(), withIntermediateDirectories: true)
            try content.write(to: fileUrl, atomically: true, encoding: .utf8)
            self.activeFileUrl = fileUrl
            self.activeFileName = name
            self.activeCodeBuffer = content
            DesktopFilesManager.shared.scanDesktop()
            NotificationCenter.default.post(name: NSNotification.Name("NexusWorkspaceFilesChanged"), object: fileUrl)
            return fileUrl
        } catch {
            return nil
        }
    }

    // MARK: - 3. Execute Active File in Terminal / Swift Interpreter
    public func runActiveFile() async -> (output: String, success: Bool) {
        guard let url = activeFileUrl else {
            return ("No active file to execute.", false)
        }

        let ext = url.pathExtension.lowercased()
        let command: String
        switch ext {
        case "swift":
            command = "swift \"\(url.path)\""
        case "py":
            command = "python3 \"\(url.path)\""
        case "js":
            command = "node \"\(url.path)\""
        case "sh", "zsh", "bash":
            command = "chmod +x \"\(url.path)\" && \"\(url.path)\""
        default:
            command = "cat \"\(url.path)\""
        }

        guard GenieCapabilities.canSpawnSubprocesses else {
            return (GenieCapabilities.unavailableMessage("Running scripts"), false)
        }

        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                let pipe = Pipe()
                process.executableURL = URL(fileURLWithPath: "/bin/zsh")
                process.arguments = ["-c", command]
                process.standardOutput = pipe
                process.standardError = pipe

                do {
                    try process.run()
                    process.waitUntilExit()
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    let out = String(data: data, encoding: .utf8) ?? ""
                    let isOk = (process.terminationStatus == 0)
                    continuation.resume(returning: (out, isOk))
                } catch {
                    continuation.resume(returning: (error.localizedDescription, false))
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
