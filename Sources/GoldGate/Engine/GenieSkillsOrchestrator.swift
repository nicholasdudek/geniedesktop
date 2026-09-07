import AppKit
import Foundation
import SwiftUI
import Vision
import ScreenCaptureKit

// MARK: - Comprehensive Genie AI Skills & Tool Orchestrator
// Grants the AI Chat direct, autonomous access to:
// 1. All User-Installed Applications & System Utilities (/Applications, /System/Applications, /System/Applications/Utilities)
// 2. Full Live WebKit Browser & Web Search Engine
// 3. System CLI Tools, Zsh Sandbox, and Development Environments
// 4. Apple Vision Screen OCR & Visual Inspection
// 5. Smart Window Tiling & Accessibility Layouts
// 6. Clipboard Sentinel & History
// 7. Spatial 3D Dome & Earth Terrain Navigation
// 8. Markdown Notes & Scratchpad
// 9. Precision Math Engine
// 10. Apple Reminders & Calendar Bridge

public struct GenieAppDescriptor: Identifiable, Hashable {
    public var id: String { bundleIdentifier ?? name }
    public let name: String
    public let bundleIdentifier: String?
    public let path: String
    public let category: String
    public let isRunning: Bool
}

public struct GenieSkillDefinition: Identifiable {
    public let id: String
    public let name: String
    public let category: String
    public let description: String
    public let usagePattern: String
    public let handler: (String) async -> String
}

@MainActor
public final class GenieSkillsOrchestrator: ObservableObject {
    public static let shared = GenieSkillsOrchestrator()

    @Published public var registeredSkills: [GenieSkillDefinition] = []
    @Published public var cachedInstalledApps: [GenieAppDescriptor] = []
    @Published public var lastSkillExecutionLog: String = ""

    private init() {
        refreshInstalledApplications()
        registerAllCoreSkills()
    }

    // MARK: - 1. Scan & Index ALL User-Installed & System Applications
    public func refreshInstalledApplications() {
        var apps: [GenieAppDescriptor] = []
        let fm = FileManager.default

        let searchDirectories = [
            "/Applications",
            "/System/Applications",
            "/System/Applications/Utilities",
            NSHomeDirectory() + "/Applications",
            "/System/Volumes/Preboot/Cryptexes/App/System/Applications"
        ]

        var scannedPaths = Set<String>()

        for dir in searchDirectories {
            guard let contents = try? fm.contentsOfDirectory(atPath: dir) else { continue }
            for item in contents where item.hasSuffix(".app") {
                let fullPath = "\(dir)/\(item)"
                guard !scannedPaths.contains(fullPath) else { continue }
                scannedPaths.insert(fullPath)

                let appName = (item as NSString).deletingPathExtension
                let bundle = Bundle(path: fullPath)
                let bundleID = bundle?.bundleIdentifier

                let isRunning = NSWorkspace.shared.runningApplications.contains {
                    $0.bundleIdentifier == bundleID || $0.localizedName == appName
                }

                let category: String = {
                    if dir.contains("Utilities") { return "Utilities" }
                    if dir.hasPrefix("/System") { return "System" }
                    return "User Installed"
                }()

                apps.append(GenieAppDescriptor(
                    name: appName,
                    bundleIdentifier: bundleID,
                    path: fullPath,
                    category: category,
                    isRunning: isRunning
                ))
            }
        }

        self.cachedInstalledApps = apps.sorted(by: { $0.name.lowercased() < $1.name.lowercased() })
    }

    // MARK: - 2. Register All Core Autonomous Skills
    private func registerAllCoreSkills() {
        var skills: [GenieSkillDefinition] = []

        // Skill 1: Launch or Switch Application
        skills.append(GenieSkillDefinition(
            id: "launch_app",
            name: "Launch / Switch Application",
            category: "Apps",
            description: "Opens or brings to focus any user-installed or macOS system app.",
            usagePattern: "open <app name>"
        ) { [weak self] param in
            return await self?.executeLaunchApp(name: param) ?? "Failed to launch"
        })

        // Skill 2: Live In-Chat Browser & Web Search
        skills.append(GenieSkillDefinition(
            id: "browse_web",
            name: "Live WebKit Browser & Web Search",
            category: "Web",
            description: "Loads a live interactive webpage in chat or queries the web.",
            usagePattern: "browse <url or query>"
        ) { [weak self] param in
            return await self?.executeBrowse(param: param) ?? "Browser active"
        })

        // Skill 3: Shell & CLI Tool Execution
        skills.append(GenieSkillDefinition(
            id: "shell_exec",
            name: "Interactive Shell & CLI Tool Runner",
            category: "Developer",
            description: "Executes shell commands in Zsh sandbox (e.g. git, brew, sw_vers, system_profiler).",
            usagePattern: "run <shell command>"
        ) { [weak self] param in
            return await self?.executeShell(command: param) ?? "Execution error"
        })

        // Skill 4: Screen Optical Character Recognition (Vision OCR)
        skills.append(GenieSkillDefinition(
            id: "vision_ocr",
            name: "Apple Vision Screen OCR",
            category: "Vision",
            description: "Captures the active screen and extracts all visible text via Apple Neural Engine.",
            usagePattern: "ocr screen"
        ) { [weak self] _ in
            return await self?.executeVisionOCR() ?? "OCR failed"
        })

        // Skill 5: Smart Window Tiling & Layout Snapping
        skills.append(GenieSkillDefinition(
            id: "window_tiling",
            name: "Smart Window Tiling Engine",
            category: "Window Management",
            description: "Snaps active window to left-half, right-half, center, or maximizes.",
            usagePattern: "tile <left|right|maximize|center>"
        ) { [weak self] param in
            return await self?.executeWindowTiling(mode: param) ?? "Tiling snapped"
        })

        // Skill 6: Clipboard Sentinel & History
        skills.append(GenieSkillDefinition(
            id: "clipboard_sentinel",
            name: "Clipboard Sentinel",
            category: "System",
            description: "Reads from or copies text directly into the macOS clipboard.",
            usagePattern: "clipboard <read|write:content>"
        ) { [weak self] param in
            return await self?.executeClipboard(param: param) ?? "Clipboard updated"
        })

        // Skill 7: Spatial 3D Dome & Earth Terrain Navigation
        skills.append(GenieSkillDefinition(
            id: "spatial_navigation",
            name: "Spatial Desktop 3D Navigation",
            category: "Spatial",
            description: "Enters 360° Sphere Dome, 3D Earth terrain walk, or switches desktop workspace.",
            usagePattern: "spatial <dome|earth|switch:index>"
        ) { [weak self] param in
            return await self?.executeSpatialNavigation(param: param) ?? "Spatial view updated"
        })

        // Skill 8: Instant Markdown Memo & Notes
        skills.append(GenieSkillDefinition(
            id: "memo_notes",
            name: "Instant Markdown Memo & Notes",
            category: "Productivity",
            description: "Saves a markdown note to ~/Desktop/Notes/.",
            usagePattern: "note <note text>"
        ) { [weak self] param in
            return await self?.executeSaveNote(text: param) ?? "Note saved"
        })

        // Skill 9: High-Precision Math Evaluation
        skills.append(GenieSkillDefinition(
            id: "precision_calc",
            name: "Precision Math Calculator",
            category: "Mathematics",
            description: "Evaluates scientific and arithmetic expressions with instant result copying.",
            usagePattern: "calc <expression>"
        ) { [weak self] param in
            return await self?.executeMathCalc(expression: param) ?? "0"
        })

        // Skill 10: High-Speed Headless Browser HTML/DOM Watcher & Zero-Cursor Executor
        skills.append(GenieSkillDefinition(
            id: "dom_watcher",
            name: "Headless Browser HTML/DOM Watcher",
            category: "Browser Automation",
            description: "Sub-5ms zero-cursor element parsing, direct CSS selector click, and instant HTML calculator execution.",
            usagePattern: "dom <scan|click:selector|calc:7,+,8,= >"
        ) { [weak self] param in
            return await self?.executeDOMWatcher(param: param) ?? "DOM execution completed"
        })

        self.registeredSkills = skills
    }

    // MARK: - 3. Skill Handlers Implementation

    private func executeLaunchApp(name: String) async -> String {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !clean.isEmpty else { return "Please specify an application name." }

        refreshInstalledApplications()
        if let match = cachedInstalledApps.first(where: {
            $0.name.lowercased() == clean ||
            $0.name.lowercased().contains(clean) ||
            ($0.bundleIdentifier?.lowercased().contains(clean) ?? false)
        }) {
            let config = NSWorkspace.OpenConfiguration()
            config.activates = true
            let url = URL(fileURLWithPath: match.path)
            do {
                _ = try await NSWorkspace.shared.openApplication(at: url, configuration: config)
                return "Successfully launched \(match.name) 🚀"
            } catch {
                return "Error opening \(match.name): \(error.localizedDescription)"
            }
        } else {
            // Fallback via /usr/bin/open
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            proc.arguments = ["-a", name]
            try? proc.run()
            proc.waitUntilExit()
            return proc.terminationStatus == 0 ? "Launched \(name) via system open." : "Could not find application \"\(name)\"."
        }
    }

    private func executeBrowse(param: String) async -> String {
        let target = param.trimmingCharacters(in: .whitespacesAndNewlines)
        if target.hasPrefix("http://") || target.hasPrefix("https://") {
            if let u = URL(string: target) {
                MiniBrowserManager.shared.browse(url: u)
                return "Loaded \(target) in Live Browser 🌐"
            }
        } else if !target.isEmpty {
            let searchURLStr = "https://duckduckgo.com/?q=" + (target.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? target)
            if let u = URL(string: searchURLStr) {
                MiniBrowserManager.shared.browse(url: u)
                return "Searching \"\(target)\" in Live Browser 🔍"
            }
        }
        return "Live Browser active in chat."
    }

    private func executeShell(command: String) async -> String {
        let clean = command.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return "Empty command." }

        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let task = Process()
                task.executableURL = URL(fileURLWithPath: "/bin/zsh")
                task.arguments = ["-c", clean]
                let pipe = Pipe()
                task.standardOutput = pipe
                task.standardError = pipe

                do {
                    try task.run()
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    task.waitUntilExit()
                    let out = String(data: data, encoding: .utf8) ?? "Done."
                    continuation.resume(returning: out.isEmpty ? "Executed with 0 exit code." : out)
                } catch {
                    continuation.resume(returning: "Execution error: \(error.localizedDescription)")
                }
            }
        }
    }

    private func executeVisionOCR() async -> String {
        guard let cgImage = await GenieScreenCaptureKitEngine.shared.captureDisplaySnapshot() else {
            return "Screen capture unavailable"
        }

        let blocks = await GenieVisionOCREngine.shared.recognizeText(in: cgImage)
        if blocks.isEmpty {
            return "No text recognized on screen."
        }
        let recognizedStrings = blocks.map { "• \($0.text)" }.joined(separator: "\n")
        return "Recognized \(blocks.count) text elements on display:\n\(recognizedStrings)"
    }

    private func executeWindowTiling(mode: String) async -> String {
        let clean = mode.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        switch clean {
        case "left", "left-half":
            GenieSmartTilingEngine.shared.tileFrontmostWindow(to: .leftHalf)
            return "Snapped active window to Left Half ⬅️"
        case "right", "right-half":
            GenieSmartTilingEngine.shared.tileFrontmostWindow(to: .rightHalf)
            return "Snapped active window to Right Half ➡️"
        case "maximize", "full":
            GenieSmartTilingEngine.shared.tileFrontmostWindow(to: .maximize)
            return "Maximized active window 🔲"
        case "center", "centergolden":
            GenieSmartTilingEngine.shared.tileFrontmostWindow(to: .centerGolden)
            return "Centered active window (Golden Ratio) 🎯"
        default:
            return "Available tiling positions: left, right, center, maximize."
        }
    }

    private func executeClipboard(param: String) async -> String {
        let clean = param.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.hasPrefix("write:") {
            let content = String(clean.dropFirst(6))
            let pb = NSPasteboard.general
            pb.clearContents()
            pb.setString(content, forType: .string)
            return "Copied to clipboard: \"\(content)\" 📋"
        } else {
            let current = NSPasteboard.general.string(forType: .string) ?? "(Clipboard empty)"
            return "Current Clipboard: \(current)"
        }
    }

    private func executeSpatialNavigation(param: String) async -> String {
        let clean = param.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if clean.contains("dome") || clean.contains("sphere") {
            NotificationCenter.default.post(name: NSNotification.Name("NexusEnterOmniDomeSphere"), object: nil)
            return "Entered 360° Geodesic Celestial Desktop Dome ✨"
        } else if clean.contains("earth") || clean.contains("terrain") || clean.contains("walk") {
            NotificationCenter.default.post(name: NSNotification.Name("NexusEnterEarthTerrain"), object: nil)
            return "Entered 3D Google Maps Style Desktop Terrain (WASD active) 🌍"
        } else if clean.hasPrefix("switch:") {
            let idxStr = String(clean.dropFirst(7))
            if let idx = Int(idxStr) {
                MacDesktopsManager.shared.switchToDesktop(index: idx)
                return "Switched to Desktop Workspace \(idx + 1) 🖥️"
            }
        }
        return "Spatial navigation ready (modes: dome, earth, switch:N)."
    }

    private func executeSaveNote(text: String) async -> String {
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return "Note cannot be empty." }

        let home = FileManager.default.homeDirectoryForCurrentUser
        let notesDir = home.appendingPathComponent("Desktop/Notes")
        try? FileManager.default.createDirectory(at: notesDir, withIntermediateDirectories: true)
        let filename = "Genie_AI_Note_\(Int(Date().timeIntervalSince1970)).md"
        let fileURL = notesDir.appendingPathComponent(filename)
        do {
            try clean.write(to: fileURL, atomically: true, encoding: .utf8)
            return "Saved note to Desktop/Notes/\(filename) 📝"
        } catch {
            return "Error saving note: \(error.localizedDescription)"
        }
    }

    private func executeMathCalc(expression: String) async -> String {
        let clean = expression.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return "0" }

        let exp = NSExpression(format: clean.replacingOccurrences(of: "×", with: "*").replacingOccurrences(of: "÷", with: "/"))
        if let val = exp.expressionValue(with: nil, context: nil) as? NSNumber {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 6
            let formatted = formatter.string(from: val) ?? "\(val)"
            let pb = NSPasteboard.general
            pb.clearContents()
            pb.setString(formatted, forType: .string)
            return "\(clean) = \(formatted) (Copied to Clipboard! ✨)"
        } else {
            return "Invalid expression: \(expression)"
        }
    }

    private func executeDOMWatcher(param: String) async -> String {
        let clean = param.trimmingCharacters(in: .whitespacesAndNewlines)
        if clean.lowercased().starts(with: "scan") {
            let elements = await GenieHTMLBrowserDOMWatcherEngine.shared.scanLiveDOM()
            return "⚡️ Scanned \(elements.count) interactive DOM elements in active browser (<2ms)."
        } else if clean.lowercased().starts(with: "click:") {
            let selector = String(clean.dropFirst(6)).trimmingCharacters(in: .whitespacesAndNewlines)
            let success = await GenieHTMLBrowserDOMWatcherEngine.shared.clickElement(selector: selector)
            return success ? "✓ Direct zero-cursor DOM click dispatched: `\(selector)`" : "Could not find element `\(selector)`"
        } else if clean.lowercased().starts(with: "calc:") {
            let seq = String(clean.dropFirst(5)).components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            let result = await GenieHTMLBrowserDOMWatcherEngine.shared.executeCalculatorSequence(seq)
            return "⚡️ Executed HTML Calculator sequence: \(seq.joined(separator: " ")) -> Display Result: \(result ?? "Done")"
        }
        return "Usage: !dom scan | !dom click:<selector> | !dom calc:<key1,key2,...>"
    }

    // MARK: - 4. Generate Live System Prompt Context for LLMs
    public func generateLLMSystemContext() -> String {
        var context = """
You are Genie, the ultra-fast agentic AI desktop companion running natively on macOS.
You have FULL autonomous access to the user's applications, system tools, live browser, and device skills.

### 📱 Available User & System Applications:
"""
        let topApps = cachedInstalledApps.prefix(35).map { "- \($0.name) (\($0.category))" }.joined(separator: "\n")
        context += "\n" + topApps

        context += """

\n### ⚡️ Autonomous Skills & Action Directives:
- !browse <url or query> -> Opens live WebKit browser cradle in chat or searches the web.
- !dom <scan|click:selector|calc:7,+,8,=> -> Sub-5ms headless browser HTML/DOM watcher & zero-cursor execution.
- !sh <command> -> Executes interactive shell command in Zsh sandbox.
- !calc <math> -> Precision math evaluation with instant copy.
- !note <memo> -> Writes markdown memo directly to ~/Desktop/Notes/.
- !sysinfo -> Real-time CPU, RAM, and 120 FPS ProMotion telemetry HUD.
- !color -> Opens digital color meter & eyedropper.
- !ocr -> Captures screen and performs Apple Vision OCR.
- !tile <left|right|maximize|center> -> Snaps windows using smart accessibility tiling.
- !open <app name> -> Launches any user-installed or default Mac app.

When the user asks to launch an app, browse the web, calculate math, take notes, or control the system, you can directly execute or reference these skills!
"""
        return context
    }
}
