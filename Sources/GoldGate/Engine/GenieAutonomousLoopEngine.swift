import Foundation
import AppKit
import CoreVideo

/// GenieBrainProvider
///
/// Dictates whether the autonomous loop's brain runs 100% locally on Apple Silicon
/// or offloads reasoning to high-capacity cloud multimodal APIs.
public enum GenieBrainProvider: String, CaseIterable, Identifiable {
    case local = "local"
    case cloudGemini = "gemini"
    case cloudClaude = "claude"
    case cloudOpenAI = "openai"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .local: return "Local Apple Silicon (Ollama / Qwen Coder)"
        case .cloudGemini: return "Google Gemini 2.0 Flash API"
        case .cloudClaude: return "Anthropic Claude 3.5 Sonnet API"
        case .cloudOpenAI: return "OpenAI GPT-4o API"
        }
    }

    public var iconName: String {
        switch self {
        case .local: return "cpu"
        case .cloudGemini: return "sparkles"
        case .cloudClaude: return "brain.head.profile"
        case .cloudOpenAI: return "cloud"
        }
    }
}

/// GenieAutonomousLoopEngine
///
/// Coordinates the closed-loop "Eye + Brain + Hands" autonomous cycle:
/// 1. EYE: Zero-copy visual ingestion from HDMI/Screen ring buffer.
/// 2. BRAIN: Local-first reasoning (Qwen 7B/30B) with Cloud API fallback (Gemini/Claude/OpenAI).
/// 3. HANDS: Sandboxed tool and terminal execution under the RAM Governor.
/// 4. FEEDBACK: Upstream stream-back fork (Channel 3) and Shared Folder Bridge sync.
@MainActor
public final class GenieAutonomousLoopEngine: ObservableObject {
    public static let shared = GenieAutonomousLoopEngine()

    @Published public var isLoopActive: Bool = false
    @Published public var brainProvider: GenieBrainProvider = .local
    @Published public var lastObservedText: String = ""
    @Published public var totalActionsExecuted: Int = 0
    @Published public var lastActionSummary: String = "Idle"
    @Published public var cycleLatencyMs: Double = 0.0
    @Published public var localModelName: String = LocalModelManager.primaryModelID

    private var loopTimer: Timer?
    private var isProcessingCycle: Bool = false

    private init() {
        let savedProvider = UserDefaults.standard.string(forKey: PrefKey.agentBrainProvider) ?? "local"
        self.brainProvider = GenieBrainProvider(rawValue: savedProvider) ?? .local
        self.localModelName = UserDefaults.standard.string(forKey: "genie.activeLocalModel") ?? LocalModelManager.primaryModelID
    }

    public func setProvider(_ provider: GenieBrainProvider) {
        self.brainProvider = provider
        UserDefaults.standard.set(provider.rawValue, forKey: PrefKey.agentBrainProvider)
    }

    public func setLocalModel(_ name: String) {
        self.localModelName = name
        UserDefaults.standard.set(name, forKey: "genie.activeLocalModel")
    }

    // MARK: - Loop Lifecycle

    public func startAutonomousLoop(interval: TimeInterval = 1.0) {
        guard !isLoopActive else { return }
        isLoopActive = true

        // Ensure stream back server is active
        GenieStreamBackEngine.shared.startStreamServer()

        loopTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.executeCycle()
            }
        }
        print("GENIE [AUTONOMOUS-LOOP]: Loop started (Provider: \(brainProvider.displayName))")
    }

    public func stopAutonomousLoop() {
        guard isLoopActive else { return }
        isLoopActive = false
        loopTimer?.invalidate()
        loopTimer = nil
        print("GENIE [AUTONOMOUS-LOOP]: Loop stopped")
    }

    // MARK: - Execution Cycle

    public func executeCycle() async {
        guard !isProcessingCycle else { return }
        guard isLoopActive else { return }

        // 1. Memory Governor Check
        if GenieMemoryGovernorEngine.isCriticalPressureActive {
            lastActionSummary = "Throttled (RAM Governor Critical)"
            return
        }

        isProcessingCycle = true
        defer { isProcessingCycle = false }

        let cycleStart = clock_gettime_nsec_np(CLOCK_MONOTONIC_RAW)

        // 2. EYE: Ingest Frame from Ring Buffer
        var observedText = ""
        if let frame = GenieHDMICaptureEngine.shared.neuralRingBuffer.peekLatest() {
            let result = await GenieVisionEngine.shared.seeForkedFrame(frame)
            observedText = result.lines.joined(separator: " ")
            self.lastObservedText = observedText

            // Stream frame to upstream Channel 3
            GenieStreamBackEngine.shared.pushPixelBuffer(frame.pixelBuffer)
        } else {
            // Push synthetic heartbeat
            GenieStreamBackEngine.shared.pushSyntheticFrame(text: "Autonomous Loop Active [Tick #\(totalActionsExecuted)]")
        }

        // 3. BRAIN: Formulate Agent Reasoning (Local or Cloud API)
        let prompt = "Visual context: \(observedText.isEmpty ? "Normal Desktop" : observedText). Determine next autonomous step."
        let action = await planAction(prompt: prompt)

        // 4. HANDS: Execute Action in Sandboxed Space
        let resultSummary = await executeAgentAction(action: action)
        self.lastActionSummary = resultSummary
        self.totalActionsExecuted += 1

        // 5. Stream Output to Bridge & Active Agent Workspace
        _ = try? GenieSharedFolderForkEngine.shared.writeArtifactToBridge(
            name: "latest_action.log",
            content: "Action #\(totalActionsExecuted)\nTime: \(Date())\nSummary: \(resultSummary)\nContext: \(observedText)"
        )
        if let agent = GenieAgentHomeDirectoryEngine.shared.activeAgent {
            let artifactPath = "\(agent.artifactsPath)/action_\(totalActionsExecuted).log"
            try? "Action #\(totalActionsExecuted)\nTime: \(Date())\nSummary: \(resultSummary)\nAction: \(action)\nContext: \(observedText)"
                .write(toFile: artifactPath, atomically: true, encoding: .utf8)
            Task { @MainActor in
                _ = await GenieAgentCloudSavingEngine.shared.syncAgentToCloud(agent: agent)
            }
        }

        let cycleEnd = clock_gettime_nsec_np(CLOCK_MONOTONIC_RAW)
        self.cycleLatencyMs = Double(cycleEnd - cycleStart) / 1_000_000.0
    }

    // MARK: - Brain Reasoning Dispatch (Local vs Cloud API)

    public func planAction(prompt: String) async -> String {
        switch brainProvider {
        case .local:
            return await queryLocalBrain(prompt: prompt)
        case .cloudGemini, .cloudClaude, .cloudOpenAI:
            return await queryCloudApiBrain(prompt: prompt)
        }
    }

    private func queryLocalBrain(prompt: String) async -> String {
        // Query Ollama local API endpoint at 127.0.0.1:11434
        guard let url = URL(string: "http://127.0.0.1:11434/api/generate") else {
            return "ls -la"
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.timeoutInterval = 8.0
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let selectedModel = localModelName.isEmpty ? LocalModelManager.primaryModelID : localModelName
        let payload: [String: Any] = [
            "model": selectedModel,
            "prompt": "You are Genie Autonomous Agent. In one concise command block (```desktop_agent, ```iphone_agent, or ```bash), output the next action for: \(prompt)",
            "stream": false
        ]

        guard let httpBody = try? JSONSerialization.data(withJSONObject: payload) else {
            return "pwd"
        }
        request.httpBody = httpBody

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpRes = response as? HTTPURLResponse, httpRes.statusCode == 200,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let resText = json["response"] as? String {
                return resText.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } catch {
            // Local fallback if Ollama model is offline
            return "echo 'Genie Local Agent Active'"
        }

        return "date"
    }

    private func queryCloudApiBrain(prompt: String) async -> String {
        let mgr = LocalModelManager.shared
        if brainProvider == .cloudGemini && mgr.hasGeminiKey {
            let key = mgr.geminiApiKey
            let modelId = mgr.effectiveModel.contains("gemini") ? mgr.effectiveModel : "gemini-2.5-flash"
            guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models/\(modelId):generateContent?key=\(key)") else {
                return "echo 'Invalid Gemini URL'"
            }
            var req = URLRequest(url: url)
            req.httpMethod = "POST"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            let body: [String: Any] = [
                "contents": [
                    ["parts": [["text": "You are Genie Autonomous Agent. Output one safe read-only bash command for: \(prompt)"]]]
                ]
            ]
            if let bodyData = try? JSONSerialization.data(withJSONObject: body) {
                req.httpBody = bodyData
                if let (data, _) = try? await URLSession.shared.data(for: req),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let candidates = json["candidates"] as? [[String: Any]],
                   let content = candidates.first?["content"] as? [String: Any],
                   let parts = content["parts"] as? [[String: Any]],
                   let text = parts.first?["text"] as? String {
                    return text.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
        return "echo 'Cloud API Provider: \(brainProvider.displayName) Ready'"
    }

    // MARK: - Sandboxed Tool Execution

    private func executeAgentAction(action: String) async -> String {
        let trimmed = action.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.contains("desktop_agent") || trimmed.contains("iphone_agent") || trimmed.hasPrefix("open_iphone") || trimmed.hasPrefix("tap ") || trimmed.hasPrefix("click ") || trimmed.hasPrefix("swipe_") {
            let actions = AntigravityDesktopAgent.shared.parseScript(from: trimmed)
            if !actions.isEmpty {
                AntigravityDesktopAgent.shared.executeScript(actions)
                return "Agent Actuator Dispatched: \(actions.count) actions (\(actions.first?.summary ?? ""))"
            }
        }
        let workingDir = URL(fileURLWithPath: GenieSharedFolderForkEngine.defaultSpacesPath)
        let result = await GenieSandboxedExecutionEngine.shared.execute(
            command: action,
            customWorkspace: workingDir
        )
        return "Executed: \(action.prefix(40)) (exit: \(result.exitCode))"
    }
}
