// MARK: - GenieDesktopOrganizerEngine.swift
// Golden Gate Engineering • © 2026 Nicholas M. Dudek
//
// Desktop & Project Workspace Refactor Organizer Engine.
// Provides instantaneous, intelligent categorization and sorting of loose desktop and
// project files into structured folders (Screenshots, Media, Code, Documents, Archives, Audio)
// with collision safety, dry-run previews, and single-click undo history.
// Solves the problem of AI models wasting dozens of tool calls when asked to refactor or organize.

import AppKit
import Foundation

// MARK: - 📁 Desktop Organizer Category
public enum DesktopSortCategory: String, CaseIterable, Sendable, Identifiable {
    case screenshots = "Screenshots"
    case media = "Media & Images"
    case code = "Developer & Code"
    case documents = "Documents & PDFs"
    case archives = "Archives & Installers"
    case audio = "Audio & Music"
    case miscellaneous = "Organized Miscellaneous"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .screenshots: return "camera.viewfinder"
        case .media: return "photo.stack"
        case .code: return "chevron.left.forwardslash.chevron.right"
        case .documents: return "doc.text.fill"
        case .archives: return "archivebox.fill"
        case .audio: return "waveform"
        case .miscellaneous: return "folder.fill"
        }
    }
}

// MARK: - 📦 Move Record for Rollback & Audit
public struct DesktopMoveRecord: Sendable, Identifiable {
    public let id = UUID()
    public let originalURL: URL
    public let movedURL: URL
    public let category: DesktopSortCategory
    public let timestamp: Date
}

// MARK: - 📊 Organize Result Summary
public struct DesktopOrganizeResult: Sendable {
    public let totalItemsScanned: Int
    public let totalItemsMoved: Int
    public let categoryCounts: [DesktopSortCategory: Int]
    public let movedItems: [DesktopMoveRecord]
    public let skippedItems: [String]
    public let isDryRun: Bool
    public let elapsedMilliseconds: Double
    public let summaryMarkdown: String
}

// MARK: - 🧠 Desktop Organizer Engine
public final class GenieDesktopOrganizerEngine: @unchecked Sendable {
    public static let shared = GenieDesktopOrganizerEngine()

    private let lock = NSLock()
    private var moveHistory: [[DesktopMoveRecord]] = []

    private let protectedFolderNames: Set<String> = [
        "Desktop",
        "Developer",
        "Documents",
        "Downloads",
        "Screenshots",
        "Media & Images",
        "Developer & Code",
        "Documents & PDFs",
        "Archives & Installers",
        "Audio & Music",
        "Organized Miscellaneous",
        "Applications",
        "Library",
        "System",
        ".git",
        ".build",
        ".gemini",
        "node_modules"
    ]

    private init() {}

    // MARK: - Categorization Rules
    public func categorize(fileURL: URL) -> DesktopSortCategory? {
        let name = fileURL.lastPathComponent
        let ext = fileURL.pathExtension.lowercased()

        // 1. Never categorize protected items or dotfiles
        if name.hasPrefix(".") || protectedFolderNames.contains(name) {
            return nil
        }

        // 2. Screenshots priority check
        let lowerName = name.lowercased()
        if (lowerName.hasPrefix("screen shot") || lowerName.hasPrefix("screenshot") || lowerName.hasPrefix("cleanshot") || lowerName.hasPrefix("capture")) &&
           ["png", "jpg", "jpeg", "webp"].contains(ext) {
            return .screenshots
        }

        // 3. Media & Images
        let mediaExtensions: Set<String> = [
            "png", "jpg", "jpeg", "gif", "webp", "svg", "heic", "tiff", "bmp", "ico",
            "mov", "mp4", "m4v", "avi", "mkv", "webm"
        ]
        if mediaExtensions.contains(ext) {
            return .media
        }

        // 4. Developer & Code
        let codeExtensions: Set<String> = [
            "swift", "py", "js", "ts", "tsx", "jsx", "html", "htm", "css", "scss", "json",
            "yaml", "yml", "toml", "sh", "bash", "zsh", "c", "cpp", "h", "hpp", "rs",
            "go", "java", "kt", "rb", "php", "sql", "xml", "plist"
        ]
        if codeExtensions.contains(ext) {
            return .code
        }

        // 5. Documents & PDFs
        let documentExtensions: Set<String> = [
            "pdf", "doc", "docx", "pages", "key", "numbers", "txt", "rtf", "md", "markdown",
            "csv", "tsv", "xlsx", "xls", "pptx", "ppt"
        ]
        if documentExtensions.contains(ext) {
            return .documents
        }

        // 6. Archives & Installers
        let archiveExtensions: Set<String> = [
            "zip", "tar", "gz", "tgz", "bz2", "7z", "rar", "dmg", "pkg", "iso"
        ]
        if archiveExtensions.contains(ext) {
            return .archives
        }

        // 7. Audio & Music
        let audioExtensions: Set<String> = [
            "mp3", "wav", "m4a", "flac", "aac", "ogg", "aiff", "wma"
        ]
        if audioExtensions.contains(ext) {
            return .audio
        }

        // 8. Loose generic files
        if !ext.isEmpty {
            return .miscellaneous
        }

        return nil
    }

    // MARK: - Organize Directory
    public func organize(
        directory: URL? = nil,
        dryRun: Bool = false,
        customTargetCategories: [DesktopSortCategory]? = nil
    ) -> DesktopOrganizeResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        let fm = FileManager.default
        let targetDir = directory ?? fm.urls(for: .desktopDirectory, in: .userDomainMask).first!

        guard let contents = try? fm.contentsOfDirectory(at: targetDir, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) else {
            return DesktopOrganizeResult(
                totalItemsScanned: 0,
                totalItemsMoved: 0,
                categoryCounts: [:],
                movedItems: [],
                skippedItems: ["Unable to read directory at \(targetDir.path)"],
                isDryRun: dryRun,
                elapsedMilliseconds: 0,
                summaryMarkdown: "❌ **Desktop Organizer Error:** Could not access directory `\(targetDir.path)`."
            )
        }

        var categoryCounts: [DesktopSortCategory: Int] = [:]
        var movedRecords: [DesktopMoveRecord] = []
        var skippedList: [String] = []

        let activeCategories = customTargetCategories ?? DesktopSortCategory.allCases

        for itemURL in contents {
            let itemName = itemURL.lastPathComponent

            // Skip protected folders and items
            if protectedFolderNames.contains(itemName) || itemName.hasPrefix(".") {
                skippedList.append(itemName)
                continue
            }

            // Check if item is an existing directory
            var isDir: ObjCBool = false
            fm.fileExists(atPath: itemURL.path, isDirectory: &isDir)

            // If it's a directory, check if it's already a sorted bucket or developer project
            if isDir.boolValue {
                // If it contains a Package.swift, project.yml, or .git, it can stay or go to Developer & Code
                let isProject = fm.fileExists(atPath: itemURL.appendingPathComponent("Package.swift").path) ||
                                fm.fileExists(atPath: itemURL.appendingPathComponent("project.yml").path) ||
                                fm.fileExists(atPath: itemURL.appendingPathComponent("package.json").path) ||
                                fm.fileExists(atPath: itemURL.appendingPathComponent(".git").path)

                if !isProject {
                    // Skip general folders to avoid collapsing complex folder trees
                    skippedList.append("\(itemName) (folder)")
                    continue
                }
            }

            guard let category = categorize(fileURL: itemURL), activeCategories.contains(category) else {
                skippedList.append(itemName)
                continue
            }

            let categoryFolderURL = targetDir.appendingPathComponent(category.rawValue, isDirectory: true)

            if !dryRun {
                // Ensure target category folder exists
                if !fm.fileExists(atPath: categoryFolderURL.path) {
                    try? fm.createDirectory(at: categoryFolderURL, withIntermediateDirectories: true)
                }

                // Resolve safe destination without overwriting
                let destURL = resolveUniqueDestination(for: itemURL, in: categoryFolderURL)
                do {
                    try fm.moveItem(at: itemURL, to: destURL)
                    let record = DesktopMoveRecord(
                        originalURL: itemURL,
                        movedURL: destURL,
                        category: category,
                        timestamp: Date()
                    )
                    movedRecords.append(record)
                    categoryCounts[category, default: 0] += 1
                } catch {
                    skippedList.append("\(itemName) (move error: \(error.localizedDescription))")
                }
            } else {
                // Dry run preview
                let destURL = categoryFolderURL.appendingPathComponent(itemName)
                let record = DesktopMoveRecord(
                    originalURL: itemURL,
                    movedURL: destURL,
                    category: category,
                    timestamp: Date()
                )
                movedRecords.append(record)
                categoryCounts[category, default: 0] += 1
            }
        }

        // Record history for undo if not dry run
        if !dryRun && !movedRecords.isEmpty {
            lock.lock()
            moveHistory.append(movedRecords)
            lock.unlock()
        }

        let elapsedMs = (CFAbsoluteTimeGetCurrent() - startTime) * 1000.0
        let markdown = generateMarkdownSummary(
            targetDir: targetDir,
            movedRecords: movedRecords,
            categoryCounts: categoryCounts,
            skippedCount: skippedList.count,
            dryRun: dryRun,
            elapsedMs: elapsedMs
        )

        return DesktopOrganizeResult(
            totalItemsScanned: contents.count,
            totalItemsMoved: movedRecords.count,
            categoryCounts: categoryCounts,
            movedItems: movedRecords,
            skippedItems: skippedList,
            isDryRun: dryRun,
            elapsedMilliseconds: elapsedMs,
            summaryMarkdown: markdown
        )
    }

    // MARK: - Undo Last Sort Operation
    public func undoLastSort() -> (revertedCount: Int, message: String) {
        lock.lock()
        guard let lastBatch = moveHistory.popLast(), !lastBatch.isEmpty else {
            lock.unlock()
            return (0, "ℹ️ No recent desktop sort operation found to undo.")
        }
        lock.unlock()

        let fm = FileManager.default
        var revertedCount = 0
        var failedList: [String] = []

        // Reverse moves in backward order
        for record in lastBatch.reversed() {
            do {
                if fm.fileExists(atPath: record.movedURL.path) {
                    try fm.moveItem(at: record.movedURL, to: record.originalURL)
                    revertedCount += 1
                }
            } catch {
                failedList.append("\(record.movedURL.lastPathComponent): \(error.localizedDescription)")
            }
        }

        let msg = """
        ⏪ **Undo Desktop Sort Complete:**
        - **Reverted Items:** \(revertedCount) of \(lastBatch.count) restored to original desktop positions.
        \(failedList.isEmpty ? "" : "- **Failed:**\n  - " + failedList.joined(separator: "\n  - "))
        """
        return (revertedCount, msg)
    }

    // MARK: - Safe Destination Collision Resolution
    private func resolveUniqueDestination(for sourceURL: URL, in directory: URL) -> URL {
        let fm = FileManager.default
        let originalName = sourceURL.lastPathComponent
        let baseName = sourceURL.deletingPathExtension().lastPathComponent
        let ext = sourceURL.pathExtension

        var targetURL = directory.appendingPathComponent(originalName)
        var counter = 2

        while fm.fileExists(atPath: targetURL.path) {
            let newFilename = ext.isEmpty ? "\(baseName) \(counter)" : "\(baseName) \(counter).\(ext)"
            targetURL = directory.appendingPathComponent(newFilename)
            counter += 1
        }
        return targetURL
    }

    // MARK: - Markdown Summary Generation
    private func generateMarkdownSummary(
        targetDir: URL,
        movedRecords: [DesktopMoveRecord],
        categoryCounts: [DesktopSortCategory: Int],
        skippedCount: Int,
        dryRun: Bool,
        elapsedMs: Double
    ) -> String {
        let modeHeader = dryRun ? "🔍 **[DRY RUN PREVIEW] Desktop Refactor Sort**" : "🧹 **Desktop Refactor Sorting Complete!**"

        if movedRecords.isEmpty {
            return """
            \(modeHeader)
            ✨ Desktop directory `\(targetDir.path)` is already clean and organized! Zero loose files needed sorting.
            - **Scan Time:** \(String(format: "%.1f", elapsedMs)) ms
            - **Skipped Protected Folders:** \(skippedCount)
            """
        }

        var lines: [String] = [
            modeHeader,
            "📁 **Location:** `\(targetDir.path)`",
            "⚡ **Total Items \(dryRun ? "to Move" : "Moved"):** \(movedRecords.count) in \(String(format: "%.1f", elapsedMs)) ms",
            "",
            "### 📂 Category Breakdown:"
        ]

        for category in DesktopSortCategory.allCases {
            if let count = categoryCounts[category], count > 0 {
                lines.append("- **\(category.rawValue)**: `\(count)` item\(count == 1 ? "" : "s")` (\(category.rawValue)/)")
            }
        }

        lines.append("")
        lines.append("### 📝 Sorted Items Detail:")
        let displayLimit = 25
        for (idx, record) in movedRecords.prefix(displayLimit).enumerated() {
            lines.append("\(idx + 1). `\(record.originalURL.lastPathComponent)` ➔ `\(record.category.rawValue)/`")
        }

        if movedRecords.count > displayLimit {
            lines.append("... and \(movedRecords.count - displayLimit) more files.")
        }

        if !dryRun {
            lines.append("")
            lines.append("💡 *Tip: To revert this sort at any time, run:* ````tool:sort_desktop undo````")
        }

        return lines.joined(separator: "\n")
    }
}
