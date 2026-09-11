import AppKit
import Foundation

// MARK: - 📑 Genie Architectural Chat Template Format
public enum GenieChatTemplateFormat: String, Sendable, CaseIterable {
    case chatML = "ChatML (<|im_start|>)"
    case llama3 = "Llama-3 (<|start_header_id|>)"
    case mistral = "Mistral ([INST])"
    case standardRoleJSON = "Standard OpenAI / Anthropic Role JSON"
}

// MARK: - 🏛️ Genie Architectural Chat Template Engine
/// Refactors and compiles system instructions and chat conversation history into
/// optimized model prompts specifically tailored to Genie's unique macOS architecture:
/// - In-RAM APFS VM Hypervisor & Sovereign Local Model Server (Port 58300)
/// - APFS Zero-Copy Copy-On-Write (COW) Folder Forking
/// - Autonomous Sequential Worker Nodes ("all in sequence")
/// - Hidden Trash Can Airlock Gateway (Atomic Desktop Entryway)
/// - Inverse Probability Elimination (IPE) Fast Local File Crawler
/// - Sovereign In-RAM Local Email Server & Client
/// - Unified RAM Governor & Real-time Battery/Thermal Telemetry
/// - Really Big Sovereign Mega-Template for Smaller Local Models (1B, 2B, 3B, 7B, 8B)
@MainActor
public final class GenieArchitecturalChatTemplateEngine: ObservableObject {
    public static let shared = GenieArchitecturalChatTemplateEngine()

    @Published public var defaultFormat: GenieChatTemplateFormat = .chatML
    @Published public var forceMegaTemplateForSmallerModels: Bool = true

    private init() {}

    // MARK: - Model Size Classifier
    /// Determines whether a given model name corresponds to a smaller local or edge model
    /// that requires the expanded Mega-Template with exhaustive few-shot tool calling instructions.
    public func isSmallerModel(name: String) -> Bool {
        let n = name.lowercased()
        if n.isEmpty { return true }
        let smallTokens = [
            "1b", "1.5b", "2b", "3b", "7b", "8b", "9b", "14b",
            "mini", "small", "light", "tiny", "micro", "nano", "flash",
            "genie 1", "genie 2", "genie-master", "genie", "qwen",
            "llama-3.2", "phi", "gemma", "mistral-7b", "deepseek-r1:1.5b",
            "deepseek-r1:7b", "deepseek-r1:8b", "deepseek-r1:14b", "local"
        ]
        return smallTokens.contains { n.contains($0) }
    }

    // MARK: - Architecture Prompt Generator

    /// Generates the live architectural header reflecting current host and engine state
    public func generateArchitecturalContextBlock() -> String {
        let memGovernor = GenieMemoryGovernorEngine.shared
        let inRAMVM = GenieInRAMVMManager.shared
        let batt = BatteryMonitor.shared
        let airlock = GenieTrashAirlockGateway.shared
        let emailServer = GenieInRAMLocalEmailServer.shared
        let crawler = GenieLocalFileCrawlerEngine.shared

        let hostRAM = memGovernor.totalHostMemoryMB > 0 ? "\(memGovernor.totalHostMemoryMB / 1024) GB" : "Host"
        let residentRAM = "\(memGovernor.currentProcessResidentMB) MB"
        let vmRAM = inRAMVM.isRAMDiskMounted ? "\(inRAMVM.allocatedRAMMB) MB APFS In-RAM" : "Unmounted"
        let batteryStr = batt.batteryPct.map { "\($0)% (\(batt.powerSourceDescription))" } ?? "AC Power"
        let thermalStr = batt.thermalStateString
        let airlockCount = airlock.stagedArtifactsCount
        let unreadMail = emailServer.unreadCount
        let indexedFiles = crawler.totalIndexedCount

        return """
        ### 🏛️ Active Genie Sovereign System Architecture:
        - **Host Unified Memory**: Resident: \(residentRAM) | Total: \(hostRAM) | Bandwidth: 200-800 GB/s Unified RAM Bus
        - **In-RAM APFS VM**: Status: \(inRAMVM.isRAMDiskMounted ? "Active on /Volumes/GenieInRAMVM" : "Standby") | Allocated: \(vmRAM) | Server: Port \(inRAMVM.serverPort)
        - **Power & Thermals**: Battery: \(batteryStr) | Thermals: \(thermalStr) | Zero-Leak Sentinel: \(memGovernor.idleStatusDescription)
        - **APFS Zero-Copy Forks**: Active in `/Users/Shared/Genie/spaces` using Darwin `clonefile(2)` (0 ms, 0 bytes SSD wear)
        - **Sequential Worker Nodes**: Workers dropped into forks execute instructions strictly in sequence with atomic step validation
        - **Trash Can Desktop Airlock**: Staged: \(airlockCount) items in `~/.Trash/.genie_airlock` -> Atomic O(1) promotion to Desktop with quarantine stripped
        - **Fast Local File Crawler**: \(indexedFiles) files indexed with 64-bit IPE bitmasks (no `/usr/bin/mdfind` subprocess storms)
        - **In-RAM Sovereign Email**: Unread: \(unreadMail) messages | User: \(emailServer.activeUserAddress) | Zero internet exposure
        """
    }

    // MARK: - 📚 Really Big Sovereign Mega-Template for Smaller Models
    /// Exhaustive, rich few-shot demonstrations and step-by-step cognitive scaffolding
    /// ensuring smaller models (1B to 14B) accurately invoke tools, reason before acting,
    /// and never hallucinate syntax or file contents.
    public func generateSmallerModelComprehensiveSuperPrompt() -> String {
        return """
        ### 🌟 SOVEREIGN MEGA-PROMPT & COGNITIVE REASONING CHAMBER FOR GENIE MODELS 🌟

        [CRITICAL DIRECTIVE FOR ON-DEVICE & COMPACT MODELS]
        You are operating in High-Reasoning Sovereign Mode on macOS. As a local model, your greatest strength is precision and discipline.
        You have direct executive authority on this Mac via native tools. When the user asks you to inspect files, check logs, automate macOS, or build software, you MUST NEVER simulate, fake, or imagine results. Instead, execute the exact tool command.

        ---

        ### 🧠 1. MANDATORY STEP-BY-STEP REASONING CHAMBER: `<thought>...</thought>`
        Before you emit any native tool call or formulate a complex answer, you MUST ALWAYS think step-by-step inside `<thought>` and `</thought>` tags:
        1. **User Objective**: What is the user really asking for?
        2. **Required Information / Action**: Do I already know this, or do I need to inspect disk / system / logs / web?
        3. **Tool Selection**: Which tool from the available catalog fits this best?
        4. **Parameter Formulation**: Ensure paths are formatted correctly with no missing quotes or extra spaces.

        ---

        ### 🛠️ 2. EXACT NATIVE TOOL SYNTAX & COMPILATION RULES
        Tools MUST be enclosed in triple backticks starting with ````tool:<tool_name> <arguments>````.
        Follow this format precisely:
        ```tool:<tool_name>
        <arguments or payload>
        ```
        Or on a single line for simple commands:
        ```tool:<tool_name> <arguments>
        ```

        ---

        ### 📖 3. EXHAUSTIVE FEW-SHOT DEMONSTRATIONS ACROSS ALL TOOLS

        #### Scenario A: Tailing Past Computer Logs & Recent Items
        *User*: "What was I working on recently on this Mac?"
        *Assistant*:
        <thought>
        The user wants to know their recent work on macOS. I must use `tail recent` to query NSDocumentController and Spotlight recent items.
        </thought>
        ```tool:tail recent 20
        ```

        *User*: "Check system logs to see why the app had an issue."
        *Assistant*:
        <thought>
        The user is asking for macOS unified system logs. I will use `tail system` to inspect the last 50 log lines.
        </thought>
        ```tool:tail system 50
        ```

        *User*: "What shell commands did I run earlier in Terminal?"
        *Assistant*:
        <thought>
        The user wants their shell history from ~/.zsh_history. I will use `tail history`.
        </thought>
        ```tool:tail history 30
        ```

        *User*: "Check if any crash reports were logged today."
        *Assistant*:
        <thought>
        The user asks for diagnostic crash reports. I will call `tail crash`.
        </thought>
        ```tool:tail crash 5
        ```

        #### Scenario B: Siri System Automations & Shortcuts
        *User*: "Switch my Mac to dark mode and set the volume to 40%."
        *Assistant*:
        <thought>
        The user wants two system settings updated. First, I will toggle or set dark mode via the native `siri` tool.
        </thought>
        ```tool:siri dark_mode dark
        ```

        *User*: "Remind me to review the pull request at 3 PM today."
        *Assistant*:
        <thought>
        The user wants an Apple Reminder created. I will use the `siri reminder` tool.
        </thought>
        ```tool:siri reminder Review pull request at 3 PM
        ```

        *User*: "Play some relaxing music on Apple Music."
        *Assistant*:
        <thought>
        The user wants to start music playback. I will trigger `siri music play`.
        </thought>
        ```tool:siri music play
        ```

        #### Scenario C: Reading, Inspecting & Writing Code Files
        *User*: "Read the header lines of Package.swift in ~/Desktop/Genie/GoldGate"
        *Assistant*:
        <thought>
        The user wants to read a file with a specific line range. I will call `read_file`.
        </thought>
        ```tool:read_file ~/Desktop/Genie/GoldGate/Package.swift 1-40
        ```

        *User*: "Search my projects for GoldGate."
        *Assistant*:
        <thought>
        The user wants to locate the GoldGate directory. I will call `find_project`.
        </thought>
        ```tool:find_project GoldGate
        ```

        *User*: "Create a new Swift utility named MathHelper.swift in ~/Desktop/Developer"
        *Assistant*:
        <thought>
        The user wants to create a new file with code. I will use `write_file`. I must write complete, working code and never truncate it with comments.
        </thought>
        ```tool:write_file ~/Desktop/Developer/MathHelper.swift
        import Foundation

        public struct MathHelper {
            public static func clamp<T: Comparable>(_ val: T, min: T, max: T) -> T {
                if val < min { return min }
                if val > max { return max }
                return val
            }
        }
        ```

        #### Scenario D: Compiling & Xcode Automation
        *User*: "Compile the project in ~/Desktop/Genie/GoldGate to verify it builds cleanly."
        *Assistant*:
        <thought>
        The user wants to trigger compilation. I will call `compile`.
        </thought>
        ```tool:compile ~/Desktop/Genie/GoldGate
        ```

        *User*: "Open the project in Xcode."
        *Assistant*:
        <thought>
        The user wants Xcode to open the project. I will use `drive_xcode`.
        </thought>
        ```tool:drive_xcode open ~/Desktop/Genie/GoldGate
        ```

        #### Scenario E: Trash Airlock & Staging
        *User*: "Promote the file Summary.pdf from the trash airlock to my Desktop."
        *Assistant*:
        <thought>
        The user wants to promote a file from the hidden airlock entryway `~/.Trash/.genie_airlock` onto the Desktop. I will invoke `trash_airlock_promote`.
        </thought>
        ```tool:trash_airlock_promote Summary.pdf
        ```

        #### Scenario F: Web Browsing & Fast Local Crawling
        *User*: "Browse the Swift documentation website."
        *Assistant*:
        <thought>
        The user wants web information. I will call `browse_web`.
        </thought>
        ```tool:browse_web https://swift.org/documentation
        ```

        *User*: "Search local files for .png screenshots taken today."
        *Assistant*:
        <thought>
        The user wants to find local screenshot files using the 64-bit IPE bitmask crawler. I will call `crawl_files`.
        </thought>
        ```tool:crawl_files Screenshot
        ```

        ---

        ### 🚫 4. STRICT NEGATIVE GUARDRAILS FOR MODEL EXECUTION
        1. **NEVER Hallucinate Tools**: Only emit tools listed in the active catalog (`tail`, `siri`, `read_file`, `write_file`, `compile`, `drive_xcode`, `browse_web`, `crawl_files`, `trash_airlock_promote`, `drop_worker`, `find_project`).
        2. **NEVER Truncate Code**: When using `write_file`, always supply the complete code. Never write `// ... same as before ...`.
        3. **Only One Tool Command Per Turn**: Emit one tool call at a time, then pause and allow the native engine to execute and return the results.
        4. **Acknowledge Results Concisely**: When tool results return from the system, summarize the key findings clearly and highlight next steps for the user.
        """
    }

    /// Assembles the complete system prompt including architecture context, tool capabilities,
    /// and the expanded Mega-Template when running on smaller or local models.
    public func compileFullSystemPrompt(
        baseSystemPrompt: String,
        modelName: String? = nil,
        forceMegaTemplate: Bool = false
    ) -> String {
        let archBlock = generateArchitecturalContextBlock()
        let nativeTools = GenieNativeToolEngine.shared.toolInstructionsPrompt

        var components: [String] = [baseSystemPrompt, archBlock, nativeTools]

        let shouldIncludeMega = forceMegaTemplate || forceMegaTemplateForSmallerModels || (modelName.map { isSmallerModel(name: $0) } ?? true)
        if shouldIncludeMega {
            components.append(generateSmallerModelComprehensiveSuperPrompt())
        }

        return components.joined(separator: "\n\n")
    }

    // MARK: - Template Format Compilers

    /// Compiles a list of role/content messages into ChatML string format
    public func formatAsChatML(
        systemPrompt: String,
        messages: [(role: String, content: String)],
        modelName: String? = nil
    ) -> String {
        let compiledSystem = compileFullSystemPrompt(baseSystemPrompt: systemPrompt, modelName: modelName)
        var output = "<|im_start|>system\n\(compiledSystem)<|im_end|>\n"

        for msg in messages {
            let role = msg.role.lowercased()
            output += "<|im_start|>\(role)\n\(msg.content)<|im_end|>\n"
        }

        output += "<|im_start|>assistant\n"
        return output
    }

    /// Compiles a list of role/content messages into Llama-3 string format
    public func formatAsLlama3(
        systemPrompt: String,
        messages: [(role: String, content: String)],
        modelName: String? = nil
    ) -> String {
        let compiledSystem = compileFullSystemPrompt(baseSystemPrompt: systemPrompt, modelName: modelName)
        var output = "<|begin_of_text|><|start_header_id|>system<|end_header_id|>\n\n\(compiledSystem)<|eot_id|>"

        for msg in messages {
            let role = msg.role.lowercased()
            output += "<|start_header_id|>\(role)<|end_header_id|>\n\n\(msg.content)<|eot_id|>"
        }

        output += "<|start_header_id|>assistant<|end_header_id|>\n\n"
        return output
    }

    /// Formats as standard role/content dictionary array for JSON API consumption
    public func formatAsStandardRoleJSON(
        systemPrompt: String,
        messages: [(role: String, content: String)],
        modelName: String? = nil
    ) -> [[String: String]] {
        var result: [[String: String]] = []
        let compiledSystem = compileFullSystemPrompt(baseSystemPrompt: systemPrompt, modelName: modelName)
        result.append(["role": "system", "content": compiledSystem])

        for msg in messages {
            result.append(["role": msg.role, "content": msg.content])
        }

        return result
    }
}
