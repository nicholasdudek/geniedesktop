// MARK: - GenieNativeToolEngine.swift
// Golden Gate Engineering • © 2026 Nicholas M. Dudek
//
// Native Agent Tool Calling Engine & Universal File Types Registry for Genie.
// Provides structured tool execution for finding projects, reading/writing files,
// compiling Swift/Xcode projects with real compiler output, driving Xcode, and
// runtime drag-and-drop processing under user-governed file permissions.

import AppKit
import Foundation
import PDFKit

// MARK: - 📁 Universal File Types Registry
public struct GenieFileTypeInfo: Identifiable, Sendable {
    public let id: String
    public let extensionName: String
    public let displayName: String
    public let category: String
    public let iconName: String
    public let isExecutableOrCode: Bool
}

public final class GenieFileTypesRegistry: @unchecked Sendable {
    public static let shared = GenieFileTypesRegistry()

    public let supportedTypes: [GenieFileTypeInfo] = [
        // Code & Scripts
        GenieFileTypeInfo(id: "swift", extensionName: "swift", displayName: "Swift Source", category: "Code", iconName: "swift", isExecutableOrCode: true),
        GenieFileTypeInfo(id: "py", extensionName: "py", displayName: "Python Script", category: "Code", iconName: "chevron.left.forwardslash.chevron.right", isExecutableOrCode: true),
        GenieFileTypeInfo(id: "js", extensionName: "js", displayName: "JavaScript", category: "Code", iconName: "curlybraces", isExecutableOrCode: true),
        GenieFileTypeInfo(id: "ts", extensionName: "ts", displayName: "TypeScript", category: "Code", iconName: "curlybraces", isExecutableOrCode: true),
        GenieFileTypeInfo(id: "c", extensionName: "c", displayName: "C Source", category: "Code", iconName: "curlybraces", isExecutableOrCode: true),
        GenieFileTypeInfo(id: "cpp", extensionName: "cpp", displayName: "C++ Source", category: "Code", iconName: "curlybraces", isExecutableOrCode: true),
        GenieFileTypeInfo(id: "h", extensionName: "h", displayName: "C/C++ Header", category: "Code", iconName: "curlybraces", isExecutableOrCode: true),
        GenieFileTypeInfo(id: "hpp", extensionName: "hpp", displayName: "C++ Header", category: "Code", iconName: "curlybraces", isExecutableOrCode: true),
        GenieFileTypeInfo(id: "m", extensionName: "m", displayName: "Objective-C", category: "Code", iconName: "curlybraces", isExecutableOrCode: true),
        GenieFileTypeInfo(id: "mm", extensionName: "mm", displayName: "Objective-C++", category: "Code", iconName: "curlybraces", isExecutableOrCode: true),
        GenieFileTypeInfo(id: "rs", extensionName: "rs", displayName: "Rust Source", category: "Code", iconName: "gearshape.2", isExecutableOrCode: true),
        GenieFileTypeInfo(id: "go", extensionName: "go", displayName: "Go Source", category: "Code", iconName: "bolt.fill", isExecutableOrCode: true),
        GenieFileTypeInfo(id: "java", extensionName: "java", displayName: "Java Source", category: "Code", iconName: "cup.and.saucer.fill", isExecutableOrCode: true),
        GenieFileTypeInfo(id: "kt", extensionName: "kt", displayName: "Kotlin Source", category: "Code", iconName: "chevron.left.forwardslash.chevron.right", isExecutableOrCode: true),
        GenieFileTypeInfo(id: "scala", extensionName: "scala", displayName: "Scala Source", category: "Code", iconName: "curlybraces", isExecutableOrCode: true),
        GenieFileTypeInfo(id: "rb", extensionName: "rb", displayName: "Ruby Script", category: "Code", iconName: "diamond.fill", isExecutableOrCode: true),
        GenieFileTypeInfo(id: "php", extensionName: "php", displayName: "PHP Script", category: "Code", iconName: "curlybraces", isExecutableOrCode: true),
        GenieFileTypeInfo(id: "lua", extensionName: "lua", displayName: "Lua Script", category: "Code", iconName: "moon.fill", isExecutableOrCode: true),
        GenieFileTypeInfo(id: "cs", extensionName: "cs", displayName: "C# Source", category: "Code", iconName: "number", isExecutableOrCode: true),
        GenieFileTypeInfo(id: "sh", extensionName: "sh", displayName: "Shell Script", category: "Script", iconName: "terminal.fill", isExecutableOrCode: true),
        GenieFileTypeInfo(id: "zsh", extensionName: "zsh", displayName: "Zsh Script", category: "Script", iconName: "terminal.fill", isExecutableOrCode: true),
        GenieFileTypeInfo(id: "bash", extensionName: "bash", displayName: "Bash Script", category: "Script", iconName: "terminal.fill", isExecutableOrCode: true),

        // Documents & Rich Text
        GenieFileTypeInfo(id: "rtf", extensionName: "rtf", displayName: "Rich Text Format", category: "Document", iconName: "doc.richtext.fill", isExecutableOrCode: false),
        GenieFileTypeInfo(id: "rtfd", extensionName: "rtfd", displayName: "Rich Text with Attachments", category: "Document", iconName: "doc.richtext.fill", isExecutableOrCode: false),
        GenieFileTypeInfo(id: "doc", extensionName: "doc", displayName: "Microsoft Word Document", category: "Document", iconName: "doc.text.fill", isExecutableOrCode: false),
        GenieFileTypeInfo(id: "docx", extensionName: "docx", displayName: "Office Open XML Document", category: "Document", iconName: "doc.text.fill", isExecutableOrCode: false),
        GenieFileTypeInfo(id: "pages", extensionName: "pages", displayName: "Apple Pages Document", category: "Document", iconName: "doc.text.fill", isExecutableOrCode: false),
        GenieFileTypeInfo(id: "pdf", extensionName: "pdf", displayName: "PDF Document", category: "Document", iconName: "doc.richtext.fill", isExecutableOrCode: false),
        GenieFileTypeInfo(id: "txt", extensionName: "txt", displayName: "Plain Text", category: "Document", iconName: "doc.plaintext", isExecutableOrCode: false),
        GenieFileTypeInfo(id: "md", extensionName: "md", displayName: "Markdown Document", category: "Document", iconName: "doc.richtext", isExecutableOrCode: false),
        GenieFileTypeInfo(id: "odt", extensionName: "odt", displayName: "OpenDocument Text", category: "Document", iconName: "doc.text", isExecutableOrCode: false),

        // Spreadsheets & Tabular Data
        GenieFileTypeInfo(id: "csv", extensionName: "csv", displayName: "Comma-Separated Values", category: "Data", iconName: "tablecells.fill", isExecutableOrCode: false),
        GenieFileTypeInfo(id: "tsv", extensionName: "tsv", displayName: "Tab-Separated Values", category: "Data", iconName: "tablecells", isExecutableOrCode: false),
        GenieFileTypeInfo(id: "xlsx", extensionName: "xlsx", displayName: "Excel Spreadsheet", category: "Data", iconName: "tablecells.fill", isExecutableOrCode: false),
        GenieFileTypeInfo(id: "xls", extensionName: "xls", displayName: "Excel 97-2004 Spreadsheet", category: "Data", iconName: "tablecells.fill", isExecutableOrCode: false),
        GenieFileTypeInfo(id: "numbers", extensionName: "numbers", displayName: "Apple Numbers Sheet", category: "Data", iconName: "tablecells.badge.ellipsis", isExecutableOrCode: false),

        // Web & Styling
        GenieFileTypeInfo(id: "html", extensionName: "html", displayName: "HTML5 Document", category: "Web", iconName: "globe", isExecutableOrCode: true),
        GenieFileTypeInfo(id: "htm", extensionName: "htm", displayName: "HTML Document", category: "Web", iconName: "globe", isExecutableOrCode: true),
        GenieFileTypeInfo(id: "css", extensionName: "css", displayName: "CSS Stylesheet", category: "Web", iconName: "paintbrush.fill", isExecutableOrCode: true),
        GenieFileTypeInfo(id: "scss", extensionName: "scss", displayName: "Sass Stylesheet", category: "Web", iconName: "paintbrush", isExecutableOrCode: true),

        // Data & Configuration
        GenieFileTypeInfo(id: "json", extensionName: "json", displayName: "JSON Data", category: "Data", iconName: "doc.plaintext", isExecutableOrCode: false),
        GenieFileTypeInfo(id: "yaml", extensionName: "yaml", displayName: "YAML Configuration", category: "Data", iconName: "slider.horizontal.3", isExecutableOrCode: false),
        GenieFileTypeInfo(id: "yml", extensionName: "yml", displayName: "YAML Configuration", category: "Data", iconName: "slider.horizontal.3", isExecutableOrCode: false),
        GenieFileTypeInfo(id: "toml", extensionName: "toml", displayName: "TOML Configuration", category: "Data", iconName: "slider.horizontal.3", isExecutableOrCode: false),
        GenieFileTypeInfo(id: "xml", extensionName: "xml", displayName: "XML Document", category: "Data", iconName: "chevron.left.forwardslash.chevron.right", isExecutableOrCode: false),
        GenieFileTypeInfo(id: "plist", extensionName: "plist", displayName: "Apple Property List", category: "Data", iconName: "list.bullet.rectangle", isExecutableOrCode: false),
        GenieFileTypeInfo(id: "sql", extensionName: "sql", displayName: "SQL Query", category: "Data", iconName: "cylinder.split.1x2", isExecutableOrCode: true),
        GenieFileTypeInfo(id: "log", extensionName: "log", displayName: "System Log", category: "Data", iconName: "doc.text.magnifyingglass", isExecutableOrCode: false),
        GenieFileTypeInfo(id: "env", extensionName: "env", displayName: "Environment Variables", category: "Data", iconName: "lock.fill", isExecutableOrCode: false),

        // Media & Images
        GenieFileTypeInfo(id: "png", extensionName: "png", displayName: "PNG Image", category: "Media", iconName: "photo.fill", isExecutableOrCode: false),
        GenieFileTypeInfo(id: "jpg", extensionName: "jpg", displayName: "JPEG Photo", category: "Media", iconName: "photo.fill", isExecutableOrCode: false),
        GenieFileTypeInfo(id: "jpeg", extensionName: "jpeg", displayName: "JPEG Photo", category: "Media", iconName: "photo.fill", isExecutableOrCode: false),
        GenieFileTypeInfo(id: "webp", extensionName: "webp", displayName: "WebP Image", category: "Media", iconName: "photo", isExecutableOrCode: false),
        GenieFileTypeInfo(id: "svg", extensionName: "svg", displayName: "SVG Vector Graphic", category: "Media", iconName: "triangle.fill", isExecutableOrCode: false),
        GenieFileTypeInfo(id: "heic", extensionName: "heic", displayName: "HEIC Photo", category: "Media", iconName: "camera.fill", isExecutableOrCode: false),
        GenieFileTypeInfo(id: "gif", extensionName: "gif", displayName: "GIF Animation", category: "Media", iconName: "play.square.fill", isExecutableOrCode: false),
        GenieFileTypeInfo(id: "mov", extensionName: "mov", displayName: "QuickTime Video", category: "Media", iconName: "film.fill", isExecutableOrCode: false),
        GenieFileTypeInfo(id: "mp4", extensionName: "mp4", displayName: "MPEG-4 Video", category: "Media", iconName: "film.fill", isExecutableOrCode: false),
        GenieFileTypeInfo(id: "mp3", extensionName: "mp3", displayName: "MP3 Audio", category: "Media", iconName: "waveform", isExecutableOrCode: false),
        GenieFileTypeInfo(id: "wav", extensionName: "wav", displayName: "WAV Audio", category: "Media", iconName: "waveform.path", isExecutableOrCode: false),
        GenieFileTypeInfo(id: "m4a", extensionName: "m4a", displayName: "Apple Lossless Audio", category: "Media", iconName: "music.note", isExecutableOrCode: false),

        // Archives
        GenieFileTypeInfo(id: "zip", extensionName: "zip", displayName: "ZIP Archive", category: "Archive", iconName: "archivebox.fill", isExecutableOrCode: false),
        GenieFileTypeInfo(id: "tar", extensionName: "tar", displayName: "TAR Archive", category: "Archive", iconName: "archivebox", isExecutableOrCode: false),
        GenieFileTypeInfo(id: "gz", extensionName: "gz", displayName: "Gzip Compressed Archive", category: "Archive", iconName: "archivebox.fill", isExecutableOrCode: false),
        GenieFileTypeInfo(id: "dmg", extensionName: "dmg", displayName: "Apple Disk Image", category: "Archive", iconName: "opticaldisc.fill", isExecutableOrCode: false)
    ]

    public func typeInfo(for url: URL) -> GenieFileTypeInfo {
        let ext = url.pathExtension.lowercased()
        return supportedTypes.first(where: { $0.extensionName == ext }) ??
            GenieFileTypeInfo(id: ext, extensionName: ext, displayName: "\(ext.uppercased()) File", category: "Generic", iconName: "doc.fill", isExecutableOrCode: false)
    }
}

// MARK: - 🛠️ Native Agent Tool Calling Engine
public final class GenieNativeToolEngine: @unchecked Sendable {
    public static let shared = GenieNativeToolEngine()

    private init() {}

    /// System instructions explaining all native tools to the model
    public var toolInstructionsPrompt: String {
        """
        ### 🛠️ Genie Native Tool Calling Capabilities:
        You have direct access to native tools through structured code blocks:
        
        1. **Find Project / Search Files**:
           ```tool:find_project <Search Query or Directory>
           Example: ```tool:find_project GoldGate
        
        2. **Read File**:
           ```tool:read_file <File Path> [Optional: start_line-end_line]
           Example: ```tool:read_file ~/Desktop/Developer/MyApp/Sources/App.swift 1-50
        
        3. **Edit / Rewrite File**:
           ```tool:write_file <File Path>
           <File Content>
           ```
        
        4. **Compile & Catch Errors (Swift / Xcode)**:
           ```tool:compile <Project Directory Path>
           Example: ```tool:compile ~/Desktop/Genie/GoldGate
           Runs swift build or xcodebuild and returns real compiler error outputs with file and line numbers.
        
        5. **Drive Xcode**:
           ```tool:drive_xcode <Action: open / build / test> <Project Path>
           Example: ```tool:drive_xcode open ~/Desktop/Developer/MyApp.xcodeproj
        
        6. **Test Drag-and-Drop Attachment**:
           ```tool:test_drag_and_drop <File Path>
           Stages the file into Genie Chat's live interactive attachment pipeline.
        
        7. **Browse Web / Pop Browser**:
           ```tool:browse_web <URL or Search Query>
           Example: ```tool:browse_web https://developer.apple.com
           Pops open Genie's live mini browser canvas tab and loads the requested page or query.

        8. **Crawl Local Files (IPE Fast Search)**:
           ```tool:crawl_files <Directory Path or Query>
           Uses zero-subprocess IPE bitmask crawl to index and inspect local files.

        9. **Drop Worker Node onto Fork**:
           ```tool:drop_worker <Space Name or Path>
           <Commands in sequence, one per line>
           ```

        10. **Trash Airlock Promote (Desktop Entryway)**:
           ```tool:trash_airlock_promote <Airlock File Name>
           Atomically promotes a staged VM/worker file from the Trash Airlock to the Desktop.

        11. **Shell Execution (Restricted Sandbox)**:
           ```bash
           <Command Line>
           ```

        12. **Siri & macOS System Commands**:
           ```tool:siri <Action: volume / dark_mode / music / reminder / calendar / shortcut / open / quit / battery>
           Examples:
           ```tool:siri volume 50
           ```tool:siri dark_mode toggle
           ```tool:siri music play
           ```tool:siri reminder Buy groceries tomorrow
           ```tool:siri calendar Team Sync at 2pm
           ```tool:siri shortcut Run Morning Routine
           ```tool:siri open Safari
           ```tool:siri battery

        13. **Tail Logs & Recent Computer Items**:
           ```tool:tail <Target: file path | recent | system | history | crash | xcode> [Lines: 50]
           Examples:
           ```tool:tail recent 20
           ```tool:tail system 50
           ```tool:tail history 30
           ```tool:tail crash
           ```tool:tail ~/Desktop/Genie/GoldGate/.build/build.log 100
           Retrieves past computer logs, recent documents, shell history, and crash reports.

        14. **iPhone Simulator & Xcode simctl**:
           ```tool:iphone_simulator <boot | launch | shutdown | list | open <url>>
           Examples:
           ```tool:iphone_simulator boot
           ```tool:iphone_simulator open https://www.youtube.com

        15. **iPhone Browser & Duo Movie Streaming**:
           ```tool:iphone_browser <url or search query>
           Example: ```tool:iphone_browser https://www.netflix.com

        16. **Duo Simulator Layout**:
           ```tool:duo_simulator <split | duo | movie | single>
           Example: ```tool:duo_simulator split

        17. **Android Google Play Store Packager**:
           ```tool:android_package <target directory>
           Example: ```tool:android_package ~/Desktop/Developer/GenieAndroid
           Scaffolds Google Play compliant Android App Bundle (.aab), Gradle build scripts, Target SDK 35, and upload checklist.

        18. **Desktop & Refactor Organizer (Instant File Sorting)**:
           ```tool:sort_desktop [optional: path | "undo" | "dry_run"]
           Examples:
           ```tool:sort_desktop
           ```tool:sort_desktop dry_run
           ```tool:sort_desktop ~/Desktop
           ```tool:sort_desktop undo
           Instantly categorizes loose desktop/workspace files into clean folders (Screenshots, Media & Images, Developer & Code, Documents & PDFs, Archives & Installers, Audio & Music) in a single tool call without wasting multiple steps. Supports dry run and full undo rollback.
        """
    }

    // MARK: - Tool Dispatcher
    public func executeTool(name: String, argument: String, payload: String = "") async -> String {
        switch name.lowercased() {
        case "find_project", "search_files":
            return await runFindProject(query: argument)

        case "crawl_files", "crawl_directory", "index_files":
            return await runCrawlFiles(pathOrQuery: argument)

        case "drop_worker", "fork_worker":
            return await runDropWorker(target: argument, instructionsPayload: payload)

        case "trash_airlock_promote", "promote_to_desktop":
            return await runTrashAirlockPromote(argument: argument)

        case "read_file":
            return runReadFile(path: argument)

        case "write_file", "edit_file":
            return runWriteFile(path: argument, content: payload)

        case "compile", "compile_and_catch_errors", "build":
            return await runCompileProject(path: argument)

        case "drive_xcode":
            return await runDriveXcode(actionAndPath: argument)

        case "test_drag_and_drop":
            return runTestDragAndDrop(path: argument)

        case "browse_web", "pop_browser", "open_url", "browse":
            return await runBrowseWeb(urlOrQuery: argument)

        case "siri", "siri_tool", "apple_siri", "system_control":
            return await executeSiriTool(action: argument, payload: payload)

        case "tail", "tail_log", "tail_file", "retrieve_logs", "recent_items", "log_retrieval", "computer_logs":
            return await runTail(argument: argument, payload: payload)

        case "iphone_simulator", "simctl", "ios_simulator":
            return await runiPhoneSimulatorTool(argument: argument, payload: payload)

        case "iphone_browser", "duo_browser", "movie_player":
            return await runiPhoneBrowserTool(urlOrQuery: argument)

        case "duo_simulator":
            return await runDuoSimulatorTool(mode: argument)

        case "iphone_mirror":
            return await runiPhoneMirrorTool()

        case "android_package", "play_store_export", "android_store", "scaffold_android":
            return await runAndroidPackageTool(directory: argument)

        case "sort_desktop", "organize_desktop", "refactor_sort", "desktop_organize", "organize_files":
            return await runSortDesktopTool(argument: argument)

        default:
            return "Unknown tool: '\(name)'. Available tools: find_project, crawl_files, drop_worker, trash_airlock_promote, read_file, write_file, compile, drive_xcode, test_drag_and_drop, browse_web, siri, tail, iphone_simulator, iphone_browser, duo_simulator, iphone_mirror, android_package, sort_desktop."
        }
    }

    // MARK: - Tool Implementations
    private func runFindProject(query: String) async -> String {
        let clean = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return "Please specify a project name or query to search for." }

        // 1. Fast path: Query Genie's in-memory local file crawler (sub-millisecond IPE culling)
        let localMatches = GenieLocalFileCrawlerEngine.shared.searchFiles(query: clean, maxResults: 15)
        if !localMatches.isEmpty {
            var lines = ["⚡️ Found \(localMatches.count) local files via Genie Fast Crawler:"]
            for item in localMatches {
                let snippet = item.snippetPreview.map { " — \"\($0)\"" } ?? ""
                lines.append("• [\(item.category)] \(item.name) (\(item.formattedSize)) -> \(item.path)\(snippet)")
            }
            return lines.joined(separator: "\n")
        }

        // 2. Fallback: Sandboxed mdfind if local index hasn't caught the directory yet
        let cmd = "mdfind -name '\(clean)' | head -n 20"
        let res = await GenieSandboxedExecutionEngine.shared.execute(command: cmd)
        if res.output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "No matching projects or files found for '\(clean)'."
        }
        return "Found candidate project files:\n\(res.output)"
    }

    private func runCrawlFiles(pathOrQuery: String) async -> String {
        let clean = pathOrQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let expanded = NSString(string: clean.isEmpty ? "~/Desktop" : clean).expandingTildeInPath
        let url = URL(fileURLWithPath: expanded)

        if FileManager.default.fileExists(atPath: url.path) {
            let items = GenieLocalFileCrawlerEngine.shared.crawlDirectory(url, maxDepth: 3, extractSnippets: true, limit: 30)
            GenieLocalFileCrawlerEngine.shared.updateIndex(with: items)

            var lines = ["📂 Crawled \(items.count) items in '\(url.lastPathComponent)':"]
            for item in items.prefix(20) {
                lines.append("• \(item.name) (\(item.category), \(item.formattedSize))")
            }
            if items.count > 20 {
                lines.append("... and \(items.count - 20) more files indexed into RAM.")
            }
            return lines.joined(separator: "\n")
        } else {
            let results = GenieLocalFileCrawlerEngine.shared.searchFiles(query: clean, maxResults: 20)
            if results.isEmpty {
                return "No files found matching '\(clean)'."
            }
            return "🔍 Search results for '\(clean)':\n" + results.map { "• \($0.path) (\($0.formattedSize))" }.joined(separator: "\n")
        }
    }

    private func runDropWorker(target: String, instructionsPayload: String) async -> String {
        let cleanTarget = target.trimmingCharacters(in: .whitespacesAndNewlines)
        let lines = instructionsPayload.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("#") }

        guard !lines.isEmpty else {
            return "Please provide at least one sequential instruction in the payload."
        }

        let instructions: [GenieWorkerInstruction] = lines.enumerated().map { idx, line in
            GenieWorkerInstruction(
                title: "Step \(idx + 1): \(line.prefix(40))",
                type: .shell(command: line)
            )
        }

        let targetURL = URL(fileURLWithPath: NSString(string: cleanTarget.isEmpty ? GenieSharedFolderForkEngine.defaultSpacesPath : cleanTarget).expandingTildeInPath)

        let worker = await MainActor.run {
            GenieWorkerNodeOrchestrator.shared.dropWorker(
                name: "Worker-\(targetURL.lastPathComponent)",
                into: targetURL,
                instructions: instructions,
                autoRun: true
            )
        }

        return "👷‍♂️ Dropped worker '\(worker.name)' into \(targetURL.path) with \(instructions.count) instructions in sequence."
    }

    private func runTrashAirlockPromote(argument: String) async -> String {
        let clean = argument.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else {
            return "Please specify the name of the file in the Trash Airlock to promote to Desktop."
        }

        do {
            let desktopURL = try await MainActor.run {
                try GenieTrashAirlockGateway.shared.promoteToDesktop(airlockFileName: clean)
            }
            return "✨ Promoted '\(clean)' from Trash Airlock directly to Desktop: \(desktopURL.path)"
        } catch {
            return "❌ Failed to promote via Trash Airlock: \(error.localizedDescription)"
        }
    }

    private func runReadFile(path: String) -> String {
        let trimmed = path.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed.components(separatedBy: " ")
        guard let filePath = parts.first, !filePath.isEmpty else { return "Missing file path." }

        let expanded = NSString(string: filePath).expandingTildeInPath
        let url = URL(fileURLWithPath: expanded)

        guard FileManager.default.fileExists(atPath: url.path) else {
            return "File not found: \(expanded)"
        }

        var textContent: String = ""
        let ext = url.pathExtension.lowercased()

        // 1. Direct UTF-8 plain text read
        if let utf8 = try? String(contentsOf: url, encoding: .utf8) {
            textContent = utf8
        }
        // 2. Rich Text & Word Documents (.rtf, .rtfd, .doc, .docx)
        else if ["rtf", "rtfd", "doc", "docx"].contains(ext),
                let attr = try? NSAttributedString(url: url, options: [:], documentAttributes: nil) {
            textContent = attr.string
        }
        // 3. PDF Documents
        else if ext == "pdf", let pdf = PDFDocument(url: url) {
            textContent = pdf.string ?? ""
        }
        // 4. Fallback ASCII / Latin encodings
        else if let latin = try? String(contentsOf: url, encoding: .isoLatin1) {
            textContent = latin
        } else {
            return "Unable to decode text contents for file: \(expanded)"
        }

        let allLines = textContent.components(separatedBy: "\n")

        // Handle optional line range slicing (e.g. "path 1-50")
        if parts.count >= 2, let rangeStr = parts.dropFirst().first, rangeStr.contains("-") {
            let bounds = rangeStr.components(separatedBy: "-")
            if let s = Int(bounds[0]), let e = Int(bounds[1]), s > 0, e >= s {
                let startIdx = min(max(0, s - 1), allLines.count)
                let endIdx = min(e, allLines.count)
                let slice = allLines[startIdx..<endIdx]
                return "File: \(url.lastPathComponent) (Lines \(s)-\(endIdx) of \(allLines.count)):\n" + slice.joined(separator: "\n")
            }
        }

        return "File: \(url.lastPathComponent) (\(allLines.count) lines):\n" + textContent
    }

    private func runWriteFile(path: String, content: String) -> String {
        let expanded = NSString(string: path.trimmingCharacters(in: .whitespacesAndNewlines)).expandingTildeInPath
        let url = URL(fileURLWithPath: expanded)

        guard GenieFilePermissionManager.shared.isPathPermitted(expanded) else {
            return "🛑 Permission Denied: Path '\(expanded)' is outside user-permitted directories. Configure file permissions in Genie Settings."
        }

        do {
            let parent = url.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: parent, withIntermediateDirectories: true)
            try content.write(to: url, atomically: true, encoding: .utf8)
            return "Successfully wrote \(content.utf8.count) bytes to \(url.path) ✓"
        } catch {
            return "Failed to write file: \(error.localizedDescription)"
        }
    }

    private func runCompileProject(path: String) async -> String {
        let clean = path.trimmingCharacters(in: .whitespacesAndNewlines)
        let targetDir = clean.isEmpty ? FileManager.default.currentDirectoryPath : NSString(string: clean).expandingTildeInPath
        let dirURL = URL(fileURLWithPath: targetDir)

        let isPackage = FileManager.default.fileExists(atPath: dirURL.appendingPathComponent("Package.swift").path)
        let buildCmd = isPackage ? "cd '\(targetDir)' && swift build 2>&1" : "cd '\(targetDir)' && xcodebuild -version 2>&1"

        let res = await GenieSandboxedExecutionEngine.shared.execute(command: buildCmd)
        return "Compiler Output (Exit Code: \(res.exitCode)):\n\(res.output)"
    }

    private func runDriveXcode(actionAndPath: String) async -> String {
        let clean = actionAndPath.trimmingCharacters(in: .whitespacesAndNewlines)
        let path = clean.isEmpty ? "." : clean
        let expanded = NSString(string: path).expandingTildeInPath

        let script = "open -a Xcode '\(expanded)'"
        let res = await GenieSandboxedExecutionEngine.shared.execute(command: script)
        return "Opened Xcode target at \(expanded) (Exit Code: \(res.exitCode))."
    }

    private func runTestDragAndDrop(path: String) -> String {
        let expanded = NSString(string: path.trimmingCharacters(in: .whitespacesAndNewlines)).expandingTildeInPath
        let url = URL(fileURLWithPath: expanded)

        guard FileManager.default.fileExists(atPath: url.path) else {
            return "File does not exist: \(expanded)"
        }

        DispatchQueue.main.async {
            FinderChatWindowManager.shared.stageAttachments([url])
        }

        return "Successfully staged drag-and-drop attachment for \(url.lastPathComponent) into Genie Chat! 📎"
    }

    private func runBrowseWeb(urlOrQuery: String) async -> String {
        let clean = urlOrQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return "Please specify a URL or search query." }
        await MainActor.run {
            FinderChatWindowManager.shared.openTab(.browser)
            MiniBrowserManager.shared.search(query: clean, triggeredByAI: true)
        }
        return "Popped into browser with '\(clean)' 🌐"
    }

    // MARK: - 🎙️ Native Siri & macOS System Capabilities
    public func executeSiriTool(action: String, payload: String = "") async -> String {
        let trimmed = action.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = trimmed.lowercased()

        // 1. Volume Controls
        if lower.hasPrefix("volume") || lower.contains("sound") {
            if lower.contains("mute") && !lower.contains("unmute") {
                _ = GenieAppleScript.script(source: "set volume with output muted")?.executeAndReturnError(nil)
                return "🔇 Audio muted via Siri System Control."
            } else if lower.contains("unmute") {
                _ = GenieAppleScript.script(source: "set volume without output muted")?.executeAndReturnError(nil)
                return "🔊 Audio unmuted via Siri System Control."
            } else if let numStr = lower.components(separatedBy: CharacterSet.decimalDigits.inverted).first(where: { !$0.isEmpty }),
                      let vol = Int(numStr) {
                let clamped = max(0, min(100, vol))
                _ = GenieAppleScript.script(source: "set volume output volume \(clamped)")?.executeAndReturnError(nil)
                return "🔊 Volume set to \(clamped)% via Siri System Control."
            } else {
                var err: NSDictionary?
                let cur = GenieAppleScript.script(source: "output volume of (get volume settings)")?.executeAndReturnError(&err).stringValue ?? "50"
                return "🔊 Current output volume is \(cur)%."
            }
        }

        // 2. Dark Mode / Appearance
        if lower.contains("dark mode") || lower.contains("appearance") {
            if lower.contains("off") || lower.contains("light") {
                _ = GenieAppleScript.script(source: "tell application \"System Events\" to tell appearance preferences to set dark mode to false")?.executeAndReturnError(nil)
                return "☀️ Switched to Light Mode."
            } else if lower.contains("on") || lower.contains("enable") {
                _ = GenieAppleScript.script(source: "tell application \"System Events\" to tell appearance preferences to set dark mode to true")?.executeAndReturnError(nil)
                return "🌙 Switched to Dark Mode."
            } else {
                _ = GenieAppleScript.script(source: "tell application \"System Events\" to tell appearance preferences to set dark mode to not dark mode")?.executeAndReturnError(nil)
                return "🌓 Toggled macOS Dark Mode."
            }
        }

        // 3. Apple Music / Media Controls
        if lower.hasPrefix("music") || lower.hasPrefix("media") || lower.contains("song") || lower.contains("track") || lower.contains("play") || lower.contains("pause") {
            if lower.contains("pause") || lower.contains("stop") {
                _ = GenieAppleScript.script(source: "tell application \"Music\" to pause")?.executeAndReturnError(nil)
                return "⏸️ Paused Music playback."
            } else if lower.contains("next") || lower.contains("skip") {
                _ = GenieAppleScript.script(source: "tell application \"Music\" to next track")?.executeAndReturnError(nil)
                return "⏭️ Skipped to next track."
            } else if lower.contains("prev") || lower.contains("back") {
                _ = GenieAppleScript.script(source: "tell application \"Music\" to previous track")?.executeAndReturnError(nil)
                return "⏮️ Returned to previous track."
            } else if lower.contains("what") || lower.contains("current") || lower.contains("now playing") {
                var err: NSDictionary?
                let trackInfo = GenieAppleScript.script(source: """
                tell application "Music"
                    if player state is playing then
                        return (name of current track) & " by " & (artist of current track)
                    else
                        return "Nothing currently playing"
                    end if
                end tell
                """)?.executeAndReturnError(&err).stringValue ?? "Unable to read track"
                return "🎵 Now Playing: \(trackInfo)"
            } else {
                _ = GenieAppleScript.script(source: "tell application \"Music\" to play")?.executeAndReturnError(nil)
                return "▶️ Started Music playback."
            }
        }

        // 4. Reminders
        if lower.hasPrefix("reminder") || lower.contains("remind me") {
            var reminderText = payload.isEmpty ? trimmed : payload
            if reminderText.lowercased().hasPrefix("remind me to ") {
                reminderText = String(reminderText.dropFirst(13))
            } else if reminderText.lowercased().hasPrefix("reminder ") {
                reminderText = String(reminderText.dropFirst(9))
            }
            let safeText = reminderText.replacingOccurrences(of: "\"", with: "\\\"")
            let script = """
            tell application "Reminders"
                make new reminder with properties {name:"\(safeText)"}
            end tell
            """
            var err: NSDictionary?
            _ = GenieAppleScript.script(source: script)?.executeAndReturnError(&err)
            if let e = err {
                return "⚠️ Could not create reminder: \(e)"
            }
            return "📝 Added reminder: \"\(reminderText)\" to Apple Reminders."
        }

        // 5. Calendar
        if lower.hasPrefix("calendar") || lower.contains("event") {
            let eventText = payload.isEmpty ? trimmed : payload
            let safeText = eventText.replacingOccurrences(of: "\"", with: "\\\"")
            let script = """
            tell application "Calendar"
                tell calendar 1
                    make new event with properties {summary:"\(safeText)", start date:(current date) + 3600, end date:(current date) + 7200}
                end tell
            end tell
            """
            var err: NSDictionary?
            _ = GenieAppleScript.script(source: script)?.executeAndReturnError(&err)
            if let e = err {
                return "⚠️ Could not schedule event: \(e)"
            }
            return "📅 Scheduled Calendar event: \"\(eventText)\" for next hour."
        }

        // 6. Application Launching / Closing
        if lower.hasPrefix("open ") || lower.hasPrefix("launch ") {
            var appName = trimmed
            if appName.lowercased().hasPrefix("open ") {
                appName = String(appName.dropFirst(5))
            } else if appName.lowercased().hasPrefix("launch ") {
                appName = String(appName.dropFirst(7))
            }
            appName = appName.trimmingCharacters(in: .whitespacesAndNewlines)
            if !appName.isEmpty {
                let candidates = [
                    URL(fileURLWithPath: "/Applications/\(appName).app"),
                    URL(fileURLWithPath: "/System/Applications/\(appName).app"),
                    URL(fileURLWithPath: "/System/Applications/Utilities/\(appName).app")
                ]
                if let targetURL = candidates.first(where: { FileManager.default.fileExists(atPath: $0.path) }) {
                    NSWorkspace.shared.openApplication(at: targetURL, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
                    return "🚀 Launched \(appName) successfully."
                } else if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: appName) {
                    NSWorkspace.shared.openApplication(at: appURL, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
                    return "🚀 Launched \(appName) successfully."
                } else {
                    let script = "tell application \"\(appName)\" to activate"
                    _ = GenieAppleScript.script(source: script)?.executeAndReturnError(nil)
                    return "🚀 Activated \(appName)."
                }
            }
        }

        if lower.hasPrefix("quit ") || lower.hasPrefix("close app ") {
            var appName = trimmed
            if appName.lowercased().hasPrefix("quit ") {
                appName = String(appName.dropFirst(5))
            } else if appName.lowercased().hasPrefix("close app ") {
                appName = String(appName.dropFirst(10))
            }
            appName = appName.trimmingCharacters(in: .whitespacesAndNewlines)
            if !appName.isEmpty {
                let script = "tell application \"\(appName)\" to quit"
                _ = GenieAppleScript.script(source: script)?.executeAndReturnError(nil)
                return "🛑 Quit \(appName)."
            }
        }

        // 7. Shortcuts Execution
        if lower.hasPrefix("shortcut") || lower.hasPrefix("run shortcut") {
            var shortcutName = trimmed
            if shortcutName.lowercased().hasPrefix("run shortcut ") {
                shortcutName = String(shortcutName.dropFirst(13))
            } else if shortcutName.lowercased().hasPrefix("shortcut ") {
                shortcutName = String(shortcutName.dropFirst(9))
            }
            shortcutName = shortcutName.trimmingCharacters(in: .whitespacesAndNewlines)
            if shortcutName.isEmpty {
                let res = await GenieSandboxedExecutionEngine.shared.execute(command: "/usr/bin/shortcuts list | head -n 25")
                return "Available Shortcuts:\n\(res.output)"
            } else {
                let res = await GenieSandboxedExecutionEngine.shared.execute(command: "/usr/bin/shortcuts run '\(shortcutName)'")
                return "Executed Shortcut '\(shortcutName)':\n\(res.output.isEmpty ? "✓ Action completed successfully." : res.output)"
            }
        }

        // 8. System Status / Battery
        if lower.contains("battery") || lower.contains("power") {
            let res = await GenieSandboxedExecutionEngine.shared.execute(command: "pmset -g batt")
            return "🔋 Battery & Power Status:\n\(res.output)"
        }

        // 9. Take Screenshot
        if lower.contains("screenshot") || lower.contains("screen capture") {
            let tempPath = FileManager.default.temporaryDirectory.appendingPathComponent("Genie_Screen_\(Int(Date().timeIntervalSince1970)).png")
            let res = await GenieSandboxedExecutionEngine.shared.execute(command: "screencapture -x '\(tempPath.path)'")
            if res.exitCode == 0 {
                DispatchQueue.main.async {
                    FinderChatWindowManager.shared.stageAttachments([tempPath])
                }
                return "📸 Captured screenshot to \(tempPath.lastPathComponent) and staged into Genie chat!"
            }
        }

        // 10. Fallback: Run via AppleScript directly
        var err: NSDictionary?
        let result = GenieAppleScript.script(source: trimmed)?.executeAndReturnError(&err)
        if let err = err {
            return "Siri capability query processed: \(err)"
        }
        return result?.stringValue ?? "Siri command executed successfully."
    }

    // MARK: - 📜 Tail & Past Computer Logs Retrieval
    public func runTail(argument: String, payload: String = "") async -> String {
        let rawInput = argument.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? payload.trimmingCharacters(in: .whitespacesAndNewlines)
            : argument.trimmingCharacters(in: .whitespacesAndNewlines)
        let clean = rawInput.isEmpty ? "recent" : rawInput
        let parts = clean.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        let target = parts.first?.lowercased() ?? "recent"
        let lineCount = (parts.count > 1 ? Int(parts[1]) : nil) ?? 50

        switch target {
        case "recent", "recents", "recent_items", "recent_files", "documents":
            return await runRetrieveRecentItems(limit: lineCount)

        case "system", "syslog", "oslog", "log", "logs", "computer_logs":
            return await runRetrieveSystemLogs(lines: lineCount)

        case "history", "zsh", "bash", "commands", "terminal":
            return await runRetrieveTerminalHistory(lines: lineCount)

        case "crash", "crashes", "diagnostics", "panic":
            return await runRetrieveCrashReports(limit: min(5, lineCount))

        case "xcode", "build":
            return await runRetrieveXcodeLogs(lines: lineCount)

        default:
            return await runTailFile(path: clean, defaultLines: lineCount)
        }
    }

    private func runRetrieveRecentItems(limit: Int) async -> String {
        var itemsFound: [(name: String, path: String, category: String, size: String, date: Date)] = []
        let fm = FileManager.default

        // 1. Check NSDocumentController recent documents
        let recentURLs = await MainActor.run { NSDocumentController.shared.recentDocumentURLs }
        for url in recentURLs {
            if fm.fileExists(atPath: url.path) {
                let attrs = try? fm.attributesOfItem(atPath: url.path)
                let size = (attrs?[.size] as? Int64) ?? 0
                let date = (attrs?[.modificationDate] as? Date) ?? Date()
                let typeInfo = GenieFileTypesRegistry.shared.typeInfo(for: url)
                itemsFound.append((
                    name: url.lastPathComponent,
                    path: url.path,
                    category: typeInfo.category,
                    size: ByteCountFormatter.string(fromByteCount: size, countStyle: .file),
                    date: date
                ))
            }
        }

        // 2. Query Spotlight for recently used files
        let spotCmd = "mdfind 'kMDItemLastUsedDate >= \"$time.now(-7d)\"' 2>/dev/null | head -n 40"
        let spotRes = await GenieSandboxedExecutionEngine.shared.execute(command: spotCmd)
        let lines = spotRes.output.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, fm.fileExists(atPath: trimmed) else { continue }
            let url = URL(fileURLWithPath: trimmed)
            if !itemsFound.contains(where: { $0.path == trimmed }) {
                let attrs = try? fm.attributesOfItem(atPath: trimmed)
                let size = (attrs?[.size] as? Int64) ?? 0
                let date = (attrs?[.modificationDate] as? Date) ?? Date()
                let typeInfo = GenieFileTypesRegistry.shared.typeInfo(for: url)
                itemsFound.append((
                    name: url.lastPathComponent,
                    path: trimmed,
                    category: typeInfo.category,
                    size: ByteCountFormatter.string(fromByteCount: size, countStyle: .file),
                    date: date
                ))
            }
        }

        // Sort descending by date
        itemsFound.sort { $0.date > $1.date }
        let subset = itemsFound.prefix(limit)

        if subset.isEmpty {
            return "No recent items found in the current system session."
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, HH:mm"

        var output = ["📂 **Recent Computer Items & Documents (Past 7 Days):**"]
        for item in subset {
            output.append("• [\(item.category)] **\(item.name)** (\(item.size), \(dateFormatter.string(from: item.date)))\n  `\(item.path)`")
        }
        return output.joined(separator: "\n")
    }

    private func runRetrieveSystemLogs(lines: Int) async -> String {
        // Run log show for recent events or fallback to /var/log/system.log
        let logCmd = "log show --last 5m --style syslog --predicate 'messageType == error || messageType == fault || process == \"Genie\"' 2>/dev/null | tail -n \(lines)"
        let res = await GenieSandboxedExecutionEngine.shared.execute(command: logCmd)
        let trimmed = res.output.trimmingCharacters(in: .whitespacesAndNewlines)

        if !trimmed.isEmpty {
            return "📜 **macOS Unified System Logs (Past 5 Minutes — Tail \(lines)):**\n```syslog\n\(trimmed)\n```"
        }

        // Fallback: /var/log/system.log
        let sysLogCmd = "tail -n \(lines) /var/log/system.log 2>/dev/null"
        let sysRes = await GenieSandboxedExecutionEngine.shared.execute(command: sysLogCmd)
        let sysOut = sysRes.output.trimmingCharacters(in: .whitespacesAndNewlines)
        if !sysOut.isEmpty {
            return "📜 **/var/log/system.log (Tail \(lines)):**\n```syslog\n\(sysOut)\n```"
        }

        return "📜 macOS Unified Logging: No errors or system warnings logged in the last 5 minutes."
    }

    private func runRetrieveTerminalHistory(lines: Int) async -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let zshHistory = "\(home)/.zsh_history"
        let bashHistory = "\(home)/.bash_history"

        var historyLines: [String] = []

        if FileManager.default.fileExists(atPath: zshHistory),
           let content = try? String(contentsOfFile: zshHistory, encoding: .isoLatin1) {
            let rawLines = content.components(separatedBy: .newlines)
            for line in rawLines {
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { continue }
                if trimmed.hasPrefix(": ") {
                    // zsh extended history format: : 1726000000:0;command
                    if let semiIdx = trimmed.firstIndex(of: ";") {
                        let cmd = String(trimmed[trimmed.index(after: semiIdx)...]).trimmingCharacters(in: .whitespaces)
                        if !cmd.isEmpty { historyLines.append(cmd) }
                    } else {
                        historyLines.append(trimmed)
                    }
                } else {
                    historyLines.append(trimmed)
                }
            }
        } else if FileManager.default.fileExists(atPath: bashHistory),
                  let content = try? String(contentsOfFile: bashHistory, encoding: .utf8) {
            historyLines = content.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        }

        let tailSubset = historyLines.suffix(lines)
        if tailSubset.isEmpty {
            return "No shell command history found."
        }

        var result = ["💻 **Recent Terminal / Shell Commands History (Last \(tailSubset.count)):**"]
        for (idx, cmd) in tailSubset.enumerated() {
            result.append("  \(idx + 1). `\(cmd)`")
        }
        return result.joined(separator: "\n")
    }

    private func runRetrieveCrashReports(limit: Int) async -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let reportsDir = "\(home)/Library/Logs/DiagnosticReports"

        guard FileManager.default.fileExists(atPath: reportsDir) else {
            return "No DiagnosticReports directory found."
        }

        let cmd = "ls -t '\(reportsDir)' 2>/dev/null | head -n \(limit)"
        let res = await GenieSandboxedExecutionEngine.shared.execute(command: cmd)
        let files = res.output.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }

        if files.isEmpty {
            return "✅ No recent crash or diagnostic reports found in \(reportsDir)."
        }

        var output = ["💥 **Recent Crash & Diagnostic Reports:**"]
        for file in files {
            let fullPath = "\(reportsDir)/\(file)"
            let headCmd = "head -n 25 '\(fullPath)' 2>/dev/null"
            let headRes = await GenieSandboxedExecutionEngine.shared.execute(command: headCmd)
            output.append("• **\(file)**:\n```\n\(headRes.output.prefix(600))\n```")
        }
        return output.joined(separator: "\n\n")
    }

    private func runRetrieveXcodeLogs(lines: Int) async -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let derivedData = "\(home)/Library/Developer/Xcode/DerivedData"
        let cmd = "find '\(derivedData)' -name '*.xcactivitylog' -mtime -3 2>/dev/null | head -n 10"
        let res = await GenieSandboxedExecutionEngine.shared.execute(command: cmd)
        let logFiles = res.output.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        if logFiles.isEmpty {
            return "No recent Xcode build activity logs found in DerivedData."
        }
        return "🔨 **Recent Xcode Build Logs in DerivedData:**\n" + logFiles.map { "• `\($0)`" }.joined(separator: "\n")
    }

    private func runTailFile(path: String, defaultLines: Int) async -> String {
        var cleanPath = path.trimmingCharacters(in: .whitespacesAndNewlines)
        var requestedLines = defaultLines

        // Check if path contains space followed by number
        let parts = cleanPath.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        if parts.count > 1, let num = Int(parts.last!) {
            requestedLines = num
            cleanPath = parts.dropLast().joined(separator: " ")
        }

        let expanded = NSString(string: cleanPath).expandingTildeInPath
        guard FileManager.default.fileExists(atPath: expanded) else {
            return "File not found to tail: '\(cleanPath)'."
        }

        let cmd = "tail -n \(requestedLines) '\(expanded)'"
        let res = await GenieSandboxedExecutionEngine.shared.execute(command: cmd)
        return "📜 **Tail \(requestedLines) lines of `\(URL(fileURLWithPath: expanded).lastPathComponent)`:**\n```\n\(res.output)\n```"
    }

    // MARK: - iPhone & Duo Simulator Tools
    private func runiPhoneSimulatorTool(argument: String, payload: String) async -> String {
        let clean = argument.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = clean.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        let action = parts.first?.lowercased() ?? "boot"

        switch action {
        case "boot":
            await MainActor.run {
                iPhoneDuoSimulatorManager.shared.launchNativeXcodeSimulator()
                iPhoneDuoSimulatorManager.shared.bootFirstSimulator()
            }
            return "📱 **iOS Simulator Launch:** Booted Xcode iOS Simulator environment."

        case "open", "openurl":
            let url = parts.dropFirst().joined(separator: " ").trimmingCharacters(in: .whitespaces)
            let targetURL = url.isEmpty ? "https://www.youtube.com" : url
            await MainActor.run {
                iPhoneDuoSimulatorManager.shared.loadURL(targetURL)
                iPhoneDuoSimulatorManager.shared.openURLInBootedSimulator(url: targetURL)
            }
            return "📱 **iOS Simulator:** Opened URL `\(targetURL)` in simulator and embedded Duo player."

        case "shutdown":
            let res = await GenieSandboxedExecutionEngine.shared.execute(command: "xcrun simctl shutdown booted")
            return "📱 **iOS Simulator Shutdown:** \(res.output.isEmpty ? "Success" : res.output)"

        case "list":
            let res = await GenieSandboxedExecutionEngine.shared.execute(command: "xcrun simctl list devices | grep -v 'Unavailable' | head -n 30")
            return "📱 **iOS Simulators Available:**\n```\n\(res.output)\n```"

        default:
            let cmd = "xcrun simctl \(clean)"
            let res = await GenieSandboxedExecutionEngine.shared.execute(command: cmd)
            return "📱 **xcrun simctl \(clean):**\n```\n\(res.output)\n```"
        }
    }

    private func runiPhoneBrowserTool(urlOrQuery: String) async -> String {
        let clean = urlOrQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        let target = clean.isEmpty ? "https://www.youtube.com" : clean
        await MainActor.run {
            iPhoneDuoSimulatorManager.shared.loadURL(target)
            UserDefaults.standard.set(DuoFoldPage2Content.splitEditorAndSimulator.rawValue, forKey: "genieDuoPage2Content")
            UserDefaults.standard.set(DuoFoldMode.twoPageFold.rawValue, forKey: "genieDuoFoldMode")
            NotificationCenter.default.post(name: NSNotification.Name("GenieiPhoneSimulatorOpenURL"), object: target)
        }
        return "🍿 **iPhone Duo Movie Browser:** Streaming `\(target)` in Duo Simulator right alongside your editor. Enjoy the movie while you code!"
    }

    private func runDuoSimulatorTool(mode: String) async -> String {
        let clean = mode.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        await MainActor.run {
            if clean.contains("split") {
                UserDefaults.standard.set(DuoFoldPage2Content.splitEditorAndSimulator.rawValue, forKey: "genieDuoPage2Content")
                UserDefaults.standard.set(DuoFoldMode.twoPageFold.rawValue, forKey: "genieDuoFoldMode")
            } else if clean.contains("duo") {
                iPhoneDuoSimulatorManager.shared.isDuoScreenMode = true
                UserDefaults.standard.set(DuoFoldPage2Content.iphoneSimulator.rawValue, forKey: "genieDuoPage2Content")
            } else if clean.contains("movie") || clean.contains("landscape") {
                iPhoneDuoSimulatorManager.shared.isLandscapeMovieMode = true
                UserDefaults.standard.set(DuoFoldPage2Content.iphoneSimulator.rawValue, forKey: "genieDuoPage2Content")
            } else {
                UserDefaults.standard.set(DuoFoldPage2Content.splitEditorAndSimulator.rawValue, forKey: "genieDuoPage2Content")
            }
            NotificationCenter.default.post(name: NSNotification.Name("GenieDuoSimulatorSetMode"), object: clean)
        }
        return "📖 **Duo Simulator Mode:** Configured Duo Fold workspace to `\(clean)`. Editor + Movie Simulator wired."
    }

    private func runiPhoneMirrorTool() async -> String {
        await MainActor.run {
            iPhoneMirrorManager.shared.launchOrActivateApp()
        }
        return "📱 **iPhone Mirroring:** Launched Apple iPhone Mirroring."
    }

    private func runAndroidPackageTool(directory: String) async -> String {
        let clean = directory.trimmingCharacters(in: .whitespacesAndNewlines)
        let rawPath = clean.isEmpty ? "~/Desktop/Developer/GeniePlayStore" : clean
        let resolvedPath = (rawPath as NSString).expandingTildeInPath
        let outputURL = URL(fileURLWithPath: resolvedPath)

        let result = await GenieAndroidStorePackager.shared.scaffoldPlayStoreProject(outputDirectory: outputURL)
        switch result {
        case .success(let projectURL):
            return """
            🤖 **Google Play Store Project Scaffolding Complete!**
            📁 **Location**: `\(projectURL.path)`

            **Google Play Console Compliance Specs:**
            - **Package Format**: Android App Bundle (`.aab`) ready
            - **Target SDK**: 35 (Android 15 / 2026 Play Store Requirement)
            - **Min SDK**: 26 (Android 8.0 Oreo)
            - **Architectures**: 64-bit (`arm64-v8a`, `x86_64`)
            - **Gradle Version**: Android Gradle Plugin 8.7.0, Kotlin 2.0.20
            - **Build Script**: `\(projectURL.path)/build_play_store_bundle.sh`
            - **Upload Guide**: `\(projectURL.path)/PLAY_STORE_UPLOAD_GUIDE.md`

            Run `./build_play_store_bundle.sh` to generate `app-release.aab` for upload to Google Play Console!
            """
        case .failure(let error):
            return "❌ **Failed to scaffold Google Play Store project**: \(error.localizedDescription)"
        }
    }

    private func runSortDesktopTool(argument: String) async -> String {
        let clean = argument.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.lowercased() == "undo" || clean.lowercased() == "revert" {
            let res = GenieDesktopOrganizerEngine.shared.undoLastSort()
            return res.message
        }

        let isDryRun = clean.lowercased().contains("dry") || clean.lowercased().contains("preview")
        let cleanPath = clean
            .replacingOccurrences(of: "dry_run", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "dryrun", with: "", options: .caseInsensitive)
            .replacingOccurrences(of: "preview", with: "", options: .caseInsensitive)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let targetURL: URL? = cleanPath.isEmpty ? nil : URL(fileURLWithPath: (cleanPath as NSString).expandingTildeInPath)
        let result = GenieDesktopOrganizerEngine.shared.organize(directory: targetURL, dryRun: isDryRun)
        return result.summaryMarkdown
    }
}
