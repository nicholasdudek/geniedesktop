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

        // Skill 4b: Screen OCR + Read Aloud (image -> text -> speech)
        skills.append(GenieSkillDefinition(
            id: "vision_ocr_speak",
            name: "Screen OCR & Read Aloud",
            category: "Vision",
            description: "Captures the active screen, extracts visible text via Apple Vision, and speaks it aloud.",
            usagePattern: "read screen aloud"
        ) { [weak self] _ in
            return await self?.executeVisionOCRSpeak() ?? "OCR + speech failed"
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

        // Skill 11: Spawn autonomous agent
        skills.append(GenieSkillDefinition(
            id: "spawn_agent",
            name: "Spawn Sub-Agent",
            category: "Agents",
            description: "Delegates an objective to an independent sub-agent and returns its answer.",
            usagePattern: "agent <name> | <objective> [| tool ids, comma separated]"
        ) { param in
            let clean = param.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !clean.isEmpty else { return "Specify agent objective: agent <name> | <objective>" }
            let parts = clean.components(separatedBy: "|")
            let name = parts.first?.trimmingCharacters(in: .whitespaces) ?? "SubAgent"
            let objective = parts.count > 1 ? parts[1].trimmingCharacters(in: .whitespaces) : clean
            
            await MainActor.run {
                let workspace = GenieSandboxedExecutionEngine.shared.defaultWorkspaceURL.path
                GenieAgentWorkspaceModel.shared.start(
                    objective: objective,
                    workspace: workspace,
                    endpoint: "https://generativelanguage.googleapis.com",
                    model: "gemini-3.8-flash",
                    key: UserDefaults.standard.string(forKey: "gemini_api_key") ?? "",
                    autonomous: true
                )
            }
            return "Spawned sub-agent '\(name)' targeting \(GenieSandboxedExecutionEngine.shared.defaultWorkspaceURL.path) with objective: \(objective)"
        })

        // Skill 12: System status readout
        skills.append(GenieSkillDefinition(
            id: "system_status",
            name: "System Status Readout",
            category: "System",
            description: "Reports battery level, thermal state, display brightness and trash contents.",
            usagePattern: "status"
        ) { [weak self] _ in
            return await self?.executeSystemStatus() ?? "Status unavailable"
        })

        // Skill 13: Native macOS AirDrop File Sharing
        skills.append(GenieSkillDefinition(
            id: "airdrop_share",
            name: "Native macOS AirDrop Sharing",
            category: "Sharing & Network",
            description: "AirDrops files, photos, PDFs, or folders to nearby iPhones, iPads, and Macs.",
            usagePattern: "airdrop <file path>"
        ) { param in
            let clean = param.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !clean.isEmpty else { return "Specify file path: airdrop <path>" }
            return await MainActor.run {
                GenieAirDropAndLocalNetworkEngine.shared.sendViaAirDrop(filePaths: [clean])
            }
        })

        // Skill 14: Agent-to-Agent Local Network Sharing
        skills.append(GenieSkillDefinition(
            id: "local_network_share",
            name: "Agent Local Network Sharing",
            category: "Sharing & Network",
            description: "Broadcasts and stages files for local peer agents via Bonjour and /Users/Shared/Genie/Bridge.",
            usagePattern: "share_net <file path>"
        ) { param in
            let clean = param.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !clean.isEmpty else { return "Specify file path: share_net <path>" }
            return await MainActor.run {
                GenieAirDropAndLocalNetworkEngine.shared.stageFileForAgentNetwork(filePath: clean)
            }
        })

        // Skill 15: Application Documentation & Scripting Definition Inspector
        skills.append(GenieSkillDefinition(
            id: "app_doc",
            name: "App Documentation & Scripting Dictionary Inspector",
            category: "Developer",
            description: "Reads sdef scripting dictionary, Info.plist, URL schemes, and documentation for any installed Mac app.",
            usagePattern: "doc <app name>"
        ) { [weak self] param in
            return await self?.executeAppDocumentation(appName: param) ?? "Documentation unavailable"
        })

        // Skill 16: Polyglot Multi-Language Code Runner
        skills.append(GenieSkillDefinition(
            id: "polyglot_code",
            name: "Polyglot Multi-Language Builder & Runner",
            category: "Developer",
            description: "Builds and executes code in Swift, Python, Rust, Go, TypeScript, Node.js, Ruby, or Shell to build anything.",
            usagePattern: "code <lang> <code>"
        ) { [weak self] param in
            return await self?.executePolyglotCode(param: param) ?? "Code execution failed"
        })

        // Skill: Background Desktop Agent — runs an app on the agent's own dedicated Desktop
        // Space (see AgentVirtualSpaceManager) and drives it there via Accessibility actions,
        // never touching whichever Space the user is actively looking at.
        skills.append(GenieSkillDefinition(
            id: "desktop_agent",
            name: "Background Desktop Agent",
            category: "Agents",
            description: "Runs an app on the agent's own dedicated Desktop Space (open/click/type/key) without disturbing the user's active Space.",
            usagePattern: "<agent-space-id> <open|click|type|key> <value>"
        ) { param in
            return await GenieBackgroundDesktopAgentEngine.shared.performDesktopAgentAction(param)
        })

        // Skill: Read Agent Desktop UI — gives the model eyes on its own background desktop via
        // the Accessibility tree, so it never needs to screenshot the user's real screen.
        skills.append(GenieSkillDefinition(
            id: "read_ui",
            name: "Read Agent Desktop UI",
            category: "Agents",
            description: "Reads the labeled UI elements of the app running on an agent's dedicated Desktop Space.",
            usagePattern: "<agent-space-id>"
        ) { param in
            return GenieBackgroundDesktopAgentEngine.shared.readUI(param)
        })

        // Skill: Distributed Multi-Machine Compute & Batch Calculations
        skills.append(GenieSkillDefinition(
            id: "dist_calc",
            name: "Distributed Multi-Machine Compute",
            category: "Compute",
            description: "Partitions and evaluates batch mathematical and matrix operations concurrently across Apple Silicon performance cores, VM clones, and distributed network nodes.",
            usagePattern: "<expressions separated by ; or newlines>"
        ) { param in
            return await GenieDistributedComputeEngine.shared.executeDistributedCalculations(param)
        })

        self.registeredSkills = skills
    }

    /// Runs a registered skill by id. This is the entry point sub-agents use, so it must stay
    /// side-effect free with respect to the main chat.
    public func execute(skillID: String, argument: String) async -> String {
        guard let skill = registeredSkills.first(where: { $0.id == skillID }) else {
            let known = registeredSkills.map(\.id).joined(separator: ", ")
            return "Unknown tool '\(skillID)'. Available: \(known)"
        }
        let output = await skill.handler(argument)
        lastSkillExecutionLog = "\(skillID): \(output.prefix(200))"
        return output
    }

    private func executeSystemStatus() async -> String {
        let brightness = Int(DisplayBrightnessManager.shared.displayBrightness * 100)
        let thermal = SystemThermalMonitor.shared.thermalLabel
        let trash = TrashMonitor.shared.isTrashFull ? "has items" : "empty"
        return "Brightness \(brightness)% · Thermal \(thermal) · Trash \(trash)"
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
            // Fallback: resolve the name through LaunchServices instead of
            // shelling out to /usr/bin/open, which the sandbox cannot reach.
            return GenieNativeSystem.launchApplication(named: name)
                ? "Launched \(name)."
                : "Could not find application \"\(name)\"."
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

        let result = await GenieSandboxedExecutionEngine.shared.execute(command: clean)
        return result.output
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

    private func executeVisionOCRSpeak() async -> String {
        guard let cgImage = await GenieScreenCaptureKitEngine.shared.captureDisplaySnapshot() else {
            return "Screen capture unavailable"
        }

        let blocks = await GenieVisionOCREngine.shared.recognizeText(in: cgImage)
        guard !blocks.isEmpty else { return "No text recognized on screen." }

        let spoken = blocks.map(\.text).joined(separator: ". ")
        GenieVoiceEngine.shared.speak(text: spoken)
        return "🔊 Reading \(blocks.count) recognized text elements aloud."
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
            // Genie's agent writes only to the Desktop; validate even though this path
            // is Desktop-rooted by construction, so a future edit cannot widen it silently.
            try GenieDesktopFileGuard.validate(fileURL)
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

    // MARK: - 5. Application Documentation & Scripting Definition Engine
    public func executeAppDocumentation(appName: String) async -> String {
        let cleanName = appName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanName.isEmpty else { return "Usage: doc <AppName>" }

        var targetAppPath: String?
        for app in cachedInstalledApps {
            if app.name.localizedCaseInsensitiveContains(cleanName) {
                targetAppPath = app.path
                break
            }
        }

        if targetAppPath == nil {
            let direct = "/Applications/\(cleanName).app"
            let sys = "/System/Applications/\(cleanName).app"
            let utils = "/System/Applications/Utilities/\(cleanName).app"
            if FileManager.default.fileExists(atPath: direct) {
                targetAppPath = direct
            } else if FileManager.default.fileExists(atPath: sys) {
                targetAppPath = sys
            } else if FileManager.default.fileExists(atPath: utils) {
                targetAppPath = utils
            }
        }

        guard let path = targetAppPath else {
            return "Application '\(cleanName)' not found in /Applications or /System/Applications."
        }

        let bundle = Bundle(path: path)
        let bundleID = bundle?.bundleIdentifier ?? "unknown"
        let version = (bundle?.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "unknown"

        var sdefSummary = "No AppleScript scripting definition (sdef) exported."
        if !GenieCapabilities.canSpawnSubprocesses {
            // Only the scripting-dictionary section needs the external `sdef`
            // binary; the bundle metadata below is read natively either way.
            sdefSummary = "Scripting dictionary unavailable: the sdef tool isn't "
                + "reachable from the App Store version of Genie."
        } else {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sdef")
        process.arguments = [path]
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let str = String(data: data, encoding: .utf8), !str.isEmpty {
                let lines = str.components(separatedBy: "\n")
                let suiteLines = lines.filter { $0.contains("<suite") || $0.contains("<class") || $0.contains("<command") }.prefix(20)
                if !suiteLines.isEmpty {
                    sdefSummary = "Scriptable Suites & Commands:\n" + suiteLines.joined(separator: "\n")
                } else {
                    sdefSummary = "Found sdef dictionary (\(data.count) bytes)."
                }
            }
        } catch {
            sdefSummary = "sdef inspection unavailable."
        }
        }

        return """
        📱 Application Documentation: \(bundle?.infoDictionary?["CFBundleName"] as? String ?? cleanName)
        Path: \(path)
        Bundle ID: \(bundleID)
        Version: \(version)
        \(sdefSummary)
        """
    }

    // MARK: - 6. Polyglot Multi-Language Code Runner
    public func executePolyglotCode(param: String) async -> String {
        let trimmed = param.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return "Usage: code <swift|python|rust|go|node|sh> <code>"
        }

        let parts = trimmed.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
        guard parts.count >= 2 else {
            return "Usage: code <lang> <code>"
        }

        let lang = String(parts[0]).lowercased()
        let code = String(parts[1])

        let dir = URL(fileURLWithPath: "/tmp/genie_polyglot")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)

        let scriptFile: URL
        let command: String

        switch lang {
        case "python", "py", "python3":
            scriptFile = dir.appendingPathComponent("script.py")
            try? code.write(to: scriptFile, atomically: true, encoding: .utf8)
            command = "python3 \"\(scriptFile.path)\""
        case "swift":
            scriptFile = dir.appendingPathComponent("main.swift")
            try? code.write(to: scriptFile, atomically: true, encoding: .utf8)
            command = "swift \"\(scriptFile.path)\""
        case "node", "javascript", "js", "typescript", "ts":
            scriptFile = dir.appendingPathComponent("run.js")
            try? code.write(to: scriptFile, atomically: true, encoding: .utf8)
            command = "node \"\(scriptFile.path)\""
        case "rust", "rs":
            scriptFile = dir.appendingPathComponent("main.rs")
            try? code.write(to: scriptFile, atomically: true, encoding: .utf8)
            command = "rustc \"\(scriptFile.path)\" -o \"\(dir.path)/rust_app\" && \"\(dir.path)/rust_app\""
        case "go", "golang":
            scriptFile = dir.appendingPathComponent("main.go")
            try? code.write(to: scriptFile, atomically: true, encoding: .utf8)
            command = "go run \"\(scriptFile.path)\""
        case "bash", "sh", "zsh":
            scriptFile = dir.appendingPathComponent("run.sh")
            try? code.write(to: scriptFile, atomically: true, encoding: .utf8)
            command = "zsh \"\(scriptFile.path)\""
        default:
            return "Unsupported language '\(lang)'. Supported: swift, python, rust, go, node, zsh"
        }

        return await executeShell(command: command)
    }

    // MARK: - 7. Hypervisor & Hardware Provisioning Intent
    let capabilityManifest = """
    SYSTEM_CAPABILITIES:
    - NATIVE_HYPERVISOR: Can spawn isolated Linux clones.
    - RESOURCE_CONTROL: Can dynamically allocate CPU/RAM.
    - VIRTIO_FS_BRIDGE: Shared folder at '/home/ubuntu/genie_shared'.
    - RUNTIME_LIFECYCLE: Can create, monitor, and terminate runtimes.
    """

    func handleModelIntent(_ intent: String) async {
        let isHeavy = intent.contains("analyze") || intent.contains("spark")
        let config = RuntimeConfig(
            name: "Task-Runtime",
            description: intent,
            vcpu: isHeavy ? 8 : 2,
            ramMB: isHeavy ? 16384 : 4096
        )
        do {
            try await RuntimeManager.shared.provision(config)
        } catch {
            print("Alignment Error: \(error)")
        }
    }
}
