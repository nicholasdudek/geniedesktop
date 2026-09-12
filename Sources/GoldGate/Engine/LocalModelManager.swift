import AppKit
import Foundation
import SwiftUI

// MARK: - AI Model Providers
public enum AIModelProvider: String, CaseIterable, Identifiable {
    case gemini = "Google Gemini"
    case claude = "Anthropic Claude"
    case openai = "OpenAI"
    case grok = "xAI Grok"
    case deepseek = "DeepSeek"
    case local = "Local Models (Ollama)"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .gemini: return "sparkles"
        case .claude: return "brain.head.profile"
        case .openai: return "cpu"
        case .grok: return "bolt.shield.fill"
        case .deepseek: return "atom"
        case .local: return "desktopcomputer"
        }
    }

    public var badgeColor: Color {
        switch self {
        case .gemini: return Color(red: 0.25, green: 0.60, blue: 1.0)
        case .claude: return Color(red: 0.95, green: 0.45, blue: 0.25)
        case .openai: return Color(red: 0.10, green: 0.80, blue: 0.55)
        case .grok: return Color(red: 0.85, green: 0.25, blue: 0.45)
        case .deepseek: return Color(red: 0.20, green: 0.50, blue: 0.95)
        case .local: return Color(red: 0.0, green: 0.85, blue: 0.95)
        }
    }
}

// MARK: - Cloud Model Item
public struct CloudModelItem: Identifiable, Hashable {
    public let id: String
    public let name: String
    public let provider: AIModelProvider
    public let displayName: String
    public let description: String
    /// Unified memory this variant needs to run comfortably. Used to recommend a
    /// tier from the Mac hardware/RAM picker (see GenieMacHardwareClass).
    public let minimumRAMGigabytes: Int
    /// Context window this variant's Modelfile is tuned for (its `num_ctx`).
    public let contextWindow: Int

    public init(
        id: String,
        name: String,
        provider: AIModelProvider,
        displayName: String,
        description: String,
        minimumRAMGigabytes: Int,
        contextWindow: Int
    ) {
        self.id = id
        self.name = name
        self.provider = provider
        self.displayName = displayName
        self.description = description
        self.minimumRAMGigabytes = minimumRAMGigabytes
        self.contextWindow = contextWindow
    }
}

// MARK: - Local AI Model Item
protocol OllamaNamed { var name: String { get } }

public struct LocalModelInfo: Identifiable, Hashable {
    public var id: String { name }
    public let name: String
    public let parameterSize: String?
    public let sizeBytes: Int64?
    public let source: String // "Ollama" or "LM Studio"
    /// Other tags in the runtime that resolve to these exact same weights.
    /// Ollama content-addresses blobs, so `genie-master` and `genie-3` can be one
    /// file on disk under two names; we list it once and keep the rest here.
    public var aliases: [String] = []

    public var displayName: String {
        var clean = name
        if clean.hasSuffix(":latest") {
            clean = String(clean.dropLast(7))
        }
        let lower = clean.lowercased()
        if lower == "genie-frontier" || lower == "genie-frontier-model" {
            return "Genie Frontier"
        }
        return clean
    }

    public var displaySize: String {
        if let s = parameterSize, !s.isEmpty {
            return s
        }
        if let bytes = sizeBytes, bytes > 0 {
            let gb = Double(bytes) / 1_073_741_824.0
            return String(format: "%.1f GB", gb)
        }
        return ""
    }
}

// MARK: - Chat Message Model for Persistent Multi-Turn Conversation
public struct ChatMessage: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let role: String // "user" or "assistant"
    public let content: String
    public let timestamp: Date
    public let model: String
    public var mediaType: String?
    public var mediaPath: String?
    public var thinking: String?

    public init(
        id: UUID = UUID(),
        role: String,
        content: String,
        timestamp: Date = Date(),
        model: String = "",
        mediaType: String? = nil,
        mediaPath: String? = nil,
        thinking: String? = nil
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.model = model
        self.mediaType = mediaType
        self.mediaPath = mediaPath
        self.thinking = thinking
    }
}

// MARK: - Saved Chat Session for Full Multi-Turn Conversation History
public struct SavedChatSession: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public var title: String
    public var createdAt: Date
    public var updatedAt: Date
    public var messages: [ChatMessage]
    public var model: String
    /// Set once the user names the conversation themselves, so auto-titling
    /// from the first message stops overwriting it. Absent in sessions saved
    /// by earlier builds, which decode as `false`.
    public var hasCustomTitle: Bool

    public init(id: UUID = UUID(), title: String, createdAt: Date = Date(), updatedAt: Date = Date(), messages: [ChatMessage], model: String = "", hasCustomTitle: Bool = false) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.messages = messages
        self.model = model
        self.hasCustomTitle = hasCustomTitle
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        title = try c.decode(String.self, forKey: .title)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        updatedAt = try c.decode(Date.self, forKey: .updatedAt)
        messages = try c.decode([ChatMessage].self, forKey: .messages)
        model = (try? c.decode(String.self, forKey: .model)) ?? ""
        hasCustomTitle = (try? c.decode(Bool.self, forKey: .hasCustomTitle)) ?? false
    }
}

// MARK: - Unified AI Model Manager (Local + BYOK Claude, Gemini, OpenAI)
@MainActor
public final class LocalModelManager: ObservableObject {
    public static let shared = LocalModelManager()

    // ── BYOK API Keys & Endpoints ──────────────────────────────────────────
    /// Stored in the Keychain, not UserDefaults — see `GenieKeychain`. Earlier builds
    /// kept this in the preference plist and registered a hardcoded `AQ.` token as its
    /// default, re-injecting it on every launch so clearing the field never stuck.
    public var geminiApiKey: String {
        get { GenieKeychain.gemini.read() ?? "" }
        set {
            objectWillChange.send()
            GenieKeychain.gemini.write(newValue)
        }
    }
    @AppStorage(PrefKey.claudeApiKey) public var claudeApiKey: String = ""
    @AppStorage(PrefKey.openaiApiKey) public var openaiApiKey: String = ""
    @AppStorage(PrefKey.grokApiKey) public var grokApiKey: String = ""
    @AppStorage(PrefKey.deepseekApiKey) public var deepseekApiKey: String = ""
    @AppStorage(PrefKey.ollamaHost) public var ollamaHost: String = "http://localhost:11434"

    // ── Model Selection Preferences ─────────────────────────────────────────
    @AppStorage(PrefKey.autoSelectLocalModel) public var autoSelectEnabled: Bool = true
    @AppStorage(PrefKey.selectedLocalModel) public var manualSelectedModel: String = ""
    @AppStorage(PrefKey.localModelsEnabled) public var localModelsEnabled: Bool = true
    @AppStorage(PrefKey.terminalAccessEnabled) public var terminalAccessEnabled: Bool = true
    @AppStorage(PrefKey.terminalAutoExecute) public var terminalAutoExecute: Bool = false
    @AppStorage(PrefKey.webAccessEnabled) public var webAccessEnabled: Bool = true
    @AppStorage(PrefKey.webAutoSearch) public var webAutoSearch: Bool = true

    // ── Runtime Observables & Chat History ──────────────────────────────────
    @Published public var availableModels: [LocalModelInfo] = []
    @Published public var chatHistory: [ChatMessage] = []
    /// When set (by the embedded Finder-style file browser tracking its current folder),
    /// documents/presentations/notes the chat generates land here instead of the
    /// per-session Chat Folder under GenieStandardDirectories.
    @Published public var activeSaveDirectoryOverride: URL?
    @Published public var savedSessions: [SavedChatSession] = []
    @Published public var currentSessionId: UUID = UUID()
    @Published public var activeDraftPrompt: String = ""
    @Published public var isDiscovering: Bool = false
    @Published public var isGenerating: Bool = false
    @Published public var currentResponse: String = ""
    @Published public var currentThinking: String = ""
    @Published public var lastPrompt: String = ""
    @Published public var activeCreationCode: String = ""
    @Published public var activeCreationTitle: String = ""
    @Published public var activeEmotionRaw: String = ""
    @Published public var isConnectedToLocalEngine: Bool = false
    @Published public var activeEngineName: String = "Ollama"
    @Published public var generationStartedAt: Date? = nil
    @Published public var lastTokensPerSecond: Double = 0

    private var activeTask: Task<Void, Never>? = nil

    // ── Dynamic Hardware RAM & Apple Silicon Helpers ────────────────────────
    public static var detectedRAMGigabytes: Int {
        let bytes = ProcessInfo.processInfo.physicalMemory
        return max(8, Int((bytes + 536_870_912) / (1024 * 1024 * 1024)))
    }

    public static var detectedRAMString: String {
        "\(detectedRAMGigabytes) GB"
    }

    // ── The One Model ────────────────────────────────────────────────────────
    // Genie ships Apple Release Model 1.0 naming:
    // - Genie: Standard Apple release 1.0 model
    // - Genie 1: Light tier (ultra-fast, responsive, 8k context)
    // - Genie 2: Tier (Pro balanced tier, full agentic tools, 32k context)
    // - Genie 3: Max tier (Flagship deep reasoning, vision & orchestration, 64k context)
    public static let primaryModelID = "genie"
    public static let modelGenieLight = "genie-1-light"
    public static let modelGenieTier = "genie-2-tier"
    public static let modelGenieMax = "genie-3-max"

    /// Context window Genie requests per generation, per model tier
    public static func contextWindow(for modelID: String) -> Int {
        if let match = cloudModels.first(where: { $0.id == modelID || $0.name == modelID }) {
            return match.contextWindow
        }
        let lower = modelID.lowercased()
        if lower.contains("compact") || lower.contains("light") || lower.contains("genie-1") {
            return 8192
        }
        if lower.contains("max") || lower.contains("genie-3") {
            return 65536
        }
        return 32768
    }

    /// Cap on chained tool -> model -> tool rounds in `runAgentContinuation`,
    /// so a model that keeps emitting commands can't loop forever.
    private static let maxAgentLoopDepth = 3

    /// Apple Release Model 1.0 Tiers: Genie (Base), Genie 1 (Light), Genie 2 (Tier), Genie 3 (Max).
    public static let cloudModels: [CloudModelItem] = [
        CloudModelItem(
            id: primaryModelID,
            name: primaryModelID,
            provider: .local,
            displayName: "Genie",
            description: "Apple Release Model 1.0 — standard versatile intelligence, vision, native tools & Siri integration",
            minimumRAMGigabytes: 16,
            contextWindow: 32768
        ),
        CloudModelItem(
            id: modelGenieLight,
            name: modelGenieLight,
            provider: .local,
            displayName: "Genie 1",
            description: "Genie 1 is light — ultra-fast on-device responsiveness, file & tool routing, 8k context for 8–16 GB Macs",
            minimumRAMGigabytes: 8,
            contextWindow: 8192
        ),
        CloudModelItem(
            id: modelGenieTier,
            name: modelGenieTier,
            provider: .local,
            displayName: "Genie 2",
            description: "Genie 2 is tier — Pro balanced capability, code generation, full tool calling, 32k context for 16–32 GB Macs",
            minimumRAMGigabytes: 16,
            contextWindow: 32768
        ),
        CloudModelItem(
            id: modelGenieMax,
            name: modelGenieMax,
            provider: .local,
            displayName: "Genie 3",
            description: "Genie 3 is max — Flagship deep reasoning, multi-step orchestration, vision & agentic master, 64k context for 32 GB+ Macs",
            minimumRAMGigabytes: 32,
            contextWindow: 65536
        ),
        // ── Top 5 Cloud Providers (BYOK) ──────────────────
        // 1. Google Gemini
        CloudModelItem(
            id: "gemini-3.8-flash",
            name: "gemini-3.8-flash",
            provider: .gemini,
            displayName: "Gemini 3.8 Flash",
            description: "Google agentic flagship — long-horizon software engineering and enterprise workflows",
            minimumRAMGigabytes: 0,
            contextWindow: 1048576
        ),
        CloudModelItem(
            id: "gemini-3.5-flash-lite",
            name: "gemini-3.5-flash-lite",
            provider: .gemini,
            displayName: "Gemini 3.5 Flash-Lite",
            description: "Google high-throughput tier — fastest and most cost-effective Gemini",
            minimumRAMGigabytes: 0,
            contextWindow: 1048576
        ),
        // 2. Anthropic Claude
        CloudModelItem(
            id: "claude-opus-5",
            name: "claude-opus-5",
            provider: .claude,
            displayName: "Claude Opus 5",
            description: "Anthropic flagship — adaptive thinking, effort control and long-horizon agentic work",
            minimumRAMGigabytes: 0,
            contextWindow: 1000000
        ),
        CloudModelItem(
            id: "claude-sonnet-5",
            name: "claude-sonnet-5",
            provider: .claude,
            displayName: "Claude Sonnet 5",
            description: "Anthropic high-volume tier — adaptive thinking at a fraction of Opus pricing",
            minimumRAMGigabytes: 0,
            contextWindow: 1000000
        ),
        // 3. OpenAI
        CloudModelItem(
            id: "gpt-6-astra",
            name: "gpt-6-astra",
            provider: .openai,
            displayName: "GPT-6 Astra",
            description: "OpenAI flagship — most capable model, built for hard end-to-end work",
            minimumRAMGigabytes: 0,
            contextWindow: 1050000
        ),
        CloudModelItem(
            id: "gpt-5.6-luna",
            name: "gpt-5.6-luna",
            provider: .openai,
            displayName: "GPT-5.6 Luna",
            description: "OpenAI cost-optimized tier — high-volume workloads at $0.20 per input MTok",
            minimumRAMGigabytes: 0,
            contextWindow: 1050000
        ),
        // 4. xAI Grok
        CloudModelItem(
            id: "grok-4.6",
            name: "grok-4.6",
            provider: .grok,
            displayName: "Grok 4.6",
            description: "xAI flagship — most intelligent and fastest Grok, real-time world knowledge",
            minimumRAMGigabytes: 0,
            contextWindow: 500000
        ),
        CloudModelItem(
            id: "grok-4.5",
            name: "grok-4.5",
            provider: .grok,
            displayName: "Grok 4.5",
            description: "xAI previous flagship — strong reasoning and coding at lower cost",
            minimumRAMGigabytes: 0,
            contextWindow: 500000
        ),
        // 5. DeepSeek
        CloudModelItem(
            id: "deepseek-flash",
            name: "deepseek-flash",
            provider: .deepseek,
            displayName: "DeepSeek V4.1 Flash",
            description: "DeepSeek speed tier — MoE architecture, 1M context and 384K max output",
            minimumRAMGigabytes: 0,
            contextWindow: 1000000
        ),
        CloudModelItem(
            id: "deepseek-v4-pro",
            name: "deepseek-v4-pro",
            provider: .deepseek,
            displayName: "DeepSeek V4 Pro",
            description: "DeepSeek reasoning flagship — step-by-step logic with open reasoning tokens",
            minimumRAMGigabytes: 0,
            contextWindow: 1000000
        )
    ]
    public var cloudModels: [CloudModelItem] { Self.cloudModels }

    public var hasGeminiKey: Bool { !geminiApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    public var hasClaudeKey: Bool { !claudeApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    public var hasOpenAIKey: Bool { !openaiApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    public var hasGrokKey: Bool { !grokApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    public var hasDeepSeekKey: Bool { !deepseekApiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    public func providerForModel(_ model: String) -> AIModelProvider {
        let lower = model.lowercased()
        if lower.hasPrefix("agy") || lower.hasPrefix("gemma") || lower.contains("offline") {
            return .local
        } else if lower.hasPrefix("gemini") {
            return .gemini
        } else if lower.hasPrefix("claude") {
            return .claude
        } else if lower.hasPrefix("gpt") || lower.hasPrefix("o1") || lower.hasPrefix("o3") {
            return .openai
        } else if lower.hasPrefix("grok") {
            return .grok
        } else if lower.hasPrefix("deepseek") {
            return .deepseek
        } else {
            return .local
        }
    }

    public var effectiveModel: String {
        let manual = manualSelectedModel.trimmingCharacters(in: .whitespacesAndNewlines)
        if !manual.isEmpty {
            if Self.cloudModels.contains(where: { $0.id == manual || $0.name == manual }) {
                return manual
            }
            if availableModels.contains(where: { $0.id == manual || $0.name == manual }) {
                return manual
            }
        }
        return LocalModelManager.primaryModelID
    }

    public var activeModelMinimumRAM: Int {
        if let cloud = Self.cloudModels.first(where: { $0.id == effectiveModel || $0.name == effectiveModel }) {
            return cloud.minimumRAMGigabytes
        }
        return 24
    }

    public var selectedModelDisplayName: String {
        let eff = effectiveModel
        if eff.isEmpty { return "Genie" }

        // Check cloud catalog first
        if let cloud = LocalModelManager.cloudModels.first(where: { $0.name == eff || $0.id == eff }) {
            return cloud.displayName
        }

        switch eff.lowercased() {
        case "genie-frontier", "genie-frontier-model":
            return "Genie Frontier"
        case "genie", "genie-master", "genie-base":
            return "Genie"
        case "genie-1-light", "genie-1", "genie-master-compact":
            return "Genie 1"
        case "genie-2-tier", "genie-2":
            return "Genie 2"
        case "genie-3-max", "genie-3", "genie-master-max":
            return "Genie 3"
        case "genie-built-in":
            return "Genie (Built-in)"
        default:
            var clean = eff
            if clean.hasSuffix(":latest") {
                clean = String(clean.dropLast(7))
            }
            return clean
        }
    }

    public func resolveOllamaModelTag(_ model: String) -> String {
        if availableModels.contains(where: { $0.name == model }) {
            return model
        }
        let lower = model.lowercased()
        if lower == "genie-frontier" || lower == "genie-frontier-model" {
            if availableModels.contains(where: { $0.name == "genie-frontier" }) { return "genie-frontier" }
            if availableModels.contains(where: { $0.name == "genie-frontier-model" }) { return "genie-frontier-model" }
            if availableModels.contains(where: { $0.name == "genie-frontier:latest" }) { return "genie-frontier:latest" }
            return "genie-frontier"
        }
        if lower == "genie-1-light" || lower == "genie-1" {
            if availableModels.contains(where: { $0.name == "genie-1-light" }) { return "genie-1-light" }
            if availableModels.contains(where: { $0.name == "genie-master-compact" }) { return "genie-master-compact" }
            if availableModels.contains(where: { $0.name == "gemma4:e2b" }) { return "gemma4:e2b" }
            return "genie-master-compact"
        }
        if lower == "genie-2-tier" || lower == "genie-2" {
            if availableModels.contains(where: { $0.name == "genie-2-tier" }) { return "genie-2-tier" }
            if availableModels.contains(where: { $0.name == "genie-master" }) { return "genie-master" }
            return "genie-master"
        }
        if lower == "genie-3-max" || lower == "genie-3" {
            if availableModels.contains(where: { $0.name == "genie-3-max" }) { return "genie-3-max" }
            if availableModels.contains(where: { $0.name == "genie-master-max" }) { return "genie-master-max" }
            return "genie-master-max"
        }
        if lower == "genie" {
            if availableModels.contains(where: { $0.name == "genie" }) { return "genie" }
            if availableModels.contains(where: { $0.name == "genie-master" }) { return "genie-master" }
            if availableModels.contains(where: { $0.name == "gemma4:e2b" }) { return "gemma4:e2b" }
            return availableModels.first?.name ?? "genie-master"
        }
        return model
    }

    // MARK: - 🎙️ Siri & macOS Capabilities Interceptor
    public func interceptSiriIntent(prompt: String) async -> String? {
        let trimmed = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let lower = trimmed.lowercased()

        let isVolumeIntent = lower.hasPrefix("set volume") || lower.hasPrefix("turn volume") || lower == "mute" || lower == "unmute" || lower == "mute volume" || lower == "unmute volume" || lower.hasPrefix("volume to ") || lower.hasPrefix("volume ")
        let isDarkModeIntent = lower.contains("dark mode") || lower.contains("light mode") || lower.contains("toggle appearance")
        let isMediaIntent = lower.hasPrefix("play music") || lower == "pause music" || lower == "stop music" || lower == "next song" || lower == "previous song" || lower == "what song is this" || lower == "what's playing" || lower == "next track" || lower == "previous track"
        let isReminderIntent = lower.hasPrefix("remind me to ") || lower.hasPrefix("new reminder: ") || lower.hasPrefix("add reminder ")
        let isCalendarIntent = lower.hasPrefix("schedule event ") || lower.hasPrefix("new event ") || lower.hasPrefix("create calendar event ")
        let isScreenshotIntent = lower == "take screenshot" || lower == "take a screenshot" || lower == "capture screen"
        let isBatteryIntent = lower == "battery" || lower == "battery level" || lower == "battery status" || lower == "power status"
        let isShortcutsIntent = lower.hasPrefix("run shortcut ") || lower == "list shortcuts"
        let isOpenAppIntent = (lower.hasPrefix("open ") || lower.hasPrefix("launch ")) && !lower.contains("safari and ")
        let isQuitAppIntent = lower.hasPrefix("quit ") || lower.hasPrefix("close app ")

        if isVolumeIntent || isDarkModeIntent || isMediaIntent || isReminderIntent || isCalendarIntent || isScreenshotIntent || isBatteryIntent || isShortcutsIntent || isOpenAppIntent || isQuitAppIntent {
            let res = await GenieNativeToolEngine.shared.executeSiriTool(action: trimmed)
            return res
        }
        return nil
    }

    public func appendDirectAssistantResponse(prompt: String, response: String) {
        let userMsg = ChatMessage(role: "user", content: prompt, model: selectedModelDisplayName)
        let assistantMsg = ChatMessage(role: "assistant", content: response, model: selectedModelDisplayName)
        self.chatHistory.append(userMsg)
        self.chatHistory.append(assistantMsg)
        self.currentResponse = response
        self.isGenerating = false
        self.saveChatHistory()
    }

    public var activeProvider: AIModelProvider {
        providerForModel(effectiveModel)
    }

    private init() {
        GenieKeychain.migrateLegacyGeminiKey(defaultsKey: PrefKey.geminiApiKey)
        loadChatHistory()
        refreshAvailableModels()
    }

    public func loadChatHistory() {
        if let diskSessions = GenieAIChatCacheManager.shared.loadSessionsFromDisk(), !diskSessions.isEmpty {
            self.savedSessions = diskSessions
            if let first = diskSessions.first {
                self.chatHistory = first.messages
                self.currentSessionId = first.id
            }
        } else {
            if let data = UserDefaults.standard.data(forKey: PrefKey.persistedChatHistory),
               let decoded = try? JSONDecoder().decode([ChatMessage].self, from: data) {
                self.chatHistory = decoded
            }
            if let data = UserDefaults.standard.data(forKey: PrefKey.savedChatSessions),
               let decoded = try? JSONDecoder().decode([SavedChatSession].self, from: data) {
                self.savedSessions = decoded
            }
        }
    }

    public func saveChatHistory() {
        if let data = try? JSONEncoder().encode(chatHistory) {
            UserDefaults.standard.set(data, forKey: PrefKey.persistedChatHistory)
        }
        autoSyncCurrentSession()
    }

    public func autoSyncCurrentSession() {
        guard !chatHistory.isEmpty else { return }
        let now = Date()
        let autoTitle: String
        if let firstUser = chatHistory.first(where: { $0.role == "user" }) {
            let trimmed = firstUser.content.trimmingCharacters(in: .whitespacesAndNewlines)
            autoTitle = String(trimmed.prefix(45))
        } else {
            autoTitle = "Chat \(DateFormatter.localizedString(from: now, dateStyle: .short, timeStyle: .short))"
        }

        if let idx = savedSessions.firstIndex(where: { $0.id == currentSessionId }) {
            savedSessions[idx].messages = chatHistory
            savedSessions[idx].updatedAt = now
            if !savedSessions[idx].hasCustomTitle,
               savedSessions[idx].title.isEmpty || savedSessions[idx].title.hasPrefix("Chat ") {
                savedSessions[idx].title = autoTitle
            }
        } else {
            let session = SavedChatSession(
                id: currentSessionId,
                title: autoTitle,
                createdAt: now,
                updatedAt: now,
                messages: chatHistory,
                model: effectiveModel
            )
            savedSessions.insert(session, at: 0)
        }

        // Persist to APFS file storage asynchronously and keep UserDefaults synced as backup
        GenieAIChatCacheManager.shared.persistSessionsToDisk(savedSessions)
        if let data = try? JSONEncoder().encode(savedSessions) {
            UserDefaults.standard.set(data, forKey: PrefKey.savedChatSessions)
        }
    }

    public func startNewChat() {
        autoSyncCurrentSession()
        chatHistory.removeAll()
        currentSessionId = UUID()
        saveChatHistory()
        currentResponse = ""
        currentThinking = ""
        lastPrompt = ""
    }

    public func loadSession(_ session: SavedChatSession) {
        autoSyncCurrentSession()
        self.currentSessionId = session.id
        self.chatHistory = session.messages
        if let data = try? JSONEncoder().encode(chatHistory) {
            UserDefaults.standard.set(data, forKey: PrefKey.persistedChatHistory)
        }
    }

    /// Names a conversation. An empty or whitespace-only name clears the
    /// custom title and hands the session back to auto-titling.
    public func renameSession(id: UUID, to newTitle: String) {
        guard let idx = savedSessions.firstIndex(where: { $0.id == id }) else { return }
        let trimmed = newTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            savedSessions[idx].hasCustomTitle = false
            if let firstUser = savedSessions[idx].messages.first(where: { $0.role == "user" }) {
                savedSessions[idx].title = String(firstUser.content.trimmingCharacters(in: .whitespacesAndNewlines).prefix(45))
            }
        } else {
            savedSessions[idx].title = String(trimmed.prefix(80))
            savedSessions[idx].hasCustomTitle = true
        }
        savedSessions[idx].updatedAt = Date()
        persistSessions()
    }

    /// Makes sure the live conversation has a saved session to rename, then names it.
    @discardableResult
    public func renameCurrentSession(to newTitle: String) -> UUID {
        if !savedSessions.contains(where: { $0.id == currentSessionId }) {
            autoSyncCurrentSession()
        }
        renameSession(id: currentSessionId, to: newTitle)
        return currentSessionId
    }

    public func persistSessions() {
        if let data = try? JSONEncoder().encode(savedSessions) {
            UserDefaults.standard.set(data, forKey: PrefKey.savedChatSessions)
        }
    }

    public func deleteSession(id: UUID) {
        savedSessions.removeAll(where: { $0.id == id })
        if let data = try? JSONEncoder().encode(savedSessions) {
            UserDefaults.standard.set(data, forKey: PrefKey.savedChatSessions)
        }
        if currentSessionId == id {
            chatHistory.removeAll()
            currentSessionId = UUID()
            UserDefaults.standard.removeObject(forKey: PrefKey.persistedChatHistory)
            currentResponse = ""
            currentThinking = ""
            lastPrompt = ""
        }
    }

    public func removeMessage(id: UUID) {
        chatHistory.removeAll(where: { $0.id == id })
        if let data = try? JSONEncoder().encode(chatHistory) {
            UserDefaults.standard.set(data, forKey: PrefKey.persistedChatHistory)
        }
        autoSyncCurrentSession()
    }

    public func clearChatHistory() {
        chatHistory.removeAll()
        UserDefaults.standard.removeObject(forKey: PrefKey.persistedChatHistory)
        currentResponse = ""
        currentThinking = ""
        lastPrompt = ""
    }

    public func deleteMessage(id: UUID) {
        chatHistory.removeAll(where: { $0.id == id })
        saveChatHistory()
    }

    public func appendAssistantMessage(_ content: String, model: String = "genie-system") {
        let msg = ChatMessage(role: "assistant", content: content, model: model)
        DispatchQueue.main.async {
            self.chatHistory.append(msg)
            self.saveChatHistory()
        }
    }

    // MARK: - Export Full Chat Transcript ("Save messages altogether as one chat")
    public func formatChatTranscript(messages: [ChatMessage]? = nil) -> String {
        let msgs = messages ?? chatHistory
        guard !msgs.isEmpty else { return "No chat messages yet." }
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short

        var lines: [String] = []
        lines.append("💬 Genie AI Conversation — \(df.string(from: msgs.first?.timestamp ?? Date()))")
        lines.append("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")

        for msg in msgs {
            let timeStr = df.string(from: msg.timestamp)
            let sender = (msg.role == "user") ? "👤 Me" : "✨ Genie (\(msg.model.isEmpty ? "AI" : msg.model))"
            lines.append("\(sender) [\(timeStr)]:\n\(msg.content)\n")
        }
        return lines.joined(separator: "\n")
    }

    // MARK: - 📋 Copy & Paste Whole Chat Transcript
    @discardableResult
    public func copyWholeChat(messages: [ChatMessage]? = nil) -> Bool {
        let msgs = messages ?? chatHistory
        guard !msgs.isEmpty else { return false }

        let transcript = formatChatTranscript(messages: msgs)

        let pb = NSPasteboard.general
        pb.clearContents()

        // 1. Plain text Markdown transcript
        pb.setString(transcript, forType: .string)

        // 2. Exact JSON representation for lossless restoration
        if let data = try? JSONEncoder().encode(msgs), let jsonString = String(data: data, encoding: .utf8) {
            let customType = NSPasteboard.PasteboardType("public.genie-chat-json")
            pb.setString(jsonString, forType: customType)
        }

        HapticFeedback.selection()
        return true
    }

    public func parseChatTranscript(from rawText: String) -> [ChatMessage] {
        let trimmed = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }

        // 1. Try direct JSON decoding of [ChatMessage]
        if let data = trimmed.data(using: .utf8),
           let direct = try? JSONDecoder().decode([ChatMessage].self, from: data),
           !direct.isEmpty {
            return direct
        }

        // 2. Try JSON array of generic objects with "role" and "content"
        if let data = trimmed.data(using: .utf8),
           let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]],
           !jsonArray.isEmpty {
            var result: [ChatMessage] = []
            for item in jsonArray {
                let role = (item["role"] as? String)?.lowercased() ?? "user"
                let content = (item["content"] as? String) ?? (item["text"] as? String) ?? ""
                let model = (item["model"] as? String) ?? ""
                if !content.isEmpty {
                    result.append(ChatMessage(
                        role: (role.contains("user") || role == "human" || role == "me") ? "user" : "assistant",
                        content: content,
                        model: model
                    ))
                }
            }
            if !result.isEmpty { return result }
        }

        // 3. Multi-line chat transcript parser
        var parsedMessages: [ChatMessage] = []
        let lines = trimmed.components(separatedBy: .newlines)

        var currentRole: String? = nil
        var currentModel: String = ""
        var currentContentLines: [String] = []

        func commitCurrentMessage() {
            guard let role = currentRole else { return }
            let content = currentContentLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
            if !content.isEmpty {
                parsedMessages.append(ChatMessage(
                    role: role,
                    content: content,
                    model: currentModel
                ))
            }
            currentRole = nil
            currentModel = ""
            currentContentLines.removeAll()
        }

        let userHeaders = [
            "👤 Me", "User:", "Me:", "You:", "Human:", "### User", "### 👤 User", "### Me", "### You", "[User]", "[You]", "[Me]", "You said:"
        ]
        let assistantHeaders = [
            "✨ Genie", "Genie:", "Assistant:", "AI:", "ChatGPT:", "Claude:", "### Assistant", "### ✨ Genie", "### AI", "[Genie]", "[Assistant]", "[AI]", "ChatGPT said:", "Claude said:"
        ]

        for line in lines {
            let lineTrimmed = line.trimmingCharacters(in: .whitespaces)

            // Skip title/divider lines
            if lineTrimmed.hasPrefix("💬 Genie AI Conversation") || lineTrimmed.hasPrefix("━━━━━━━━") || lineTrimmed.hasPrefix("Genie AI Conversation Note") {
                continue
            }

            var isUserMatch = false
            for uH in userHeaders {
                if lineTrimmed.hasPrefix(uH) {
                    isUserMatch = true
                    break
                }
            }

            var isAssistantMatch = false
            var matchedModel = ""
            for aH in assistantHeaders {
                if lineTrimmed.hasPrefix(aH) {
                    isAssistantMatch = true
                    if let openParen = lineTrimmed.firstIndex(of: "("),
                       let closeParen = lineTrimmed.firstIndex(of: ")"),
                       openParen < closeParen {
                        matchedModel = String(lineTrimmed[lineTrimmed.index(after: openParen)..<closeParen])
                    }
                    break
                }
            }

            if isUserMatch {
                commitCurrentMessage()
                currentRole = "user"
                if let colonIdx = lineTrimmed.firstIndex(of: ":") {
                    let rest = String(lineTrimmed[lineTrimmed.index(after: colonIdx)...]).trimmingCharacters(in: .whitespaces)
                    if !rest.isEmpty && !rest.hasPrefix("[") {
                        currentContentLines.append(rest)
                    }
                }
            } else if isAssistantMatch {
                commitCurrentMessage()
                currentRole = "assistant"
                currentModel = matchedModel
                if let colonIdx = lineTrimmed.firstIndex(of: ":") {
                    let rest = String(lineTrimmed[lineTrimmed.index(after: colonIdx)...]).trimmingCharacters(in: .whitespaces)
                    if !rest.isEmpty && !rest.hasPrefix("[") {
                        currentContentLines.append(rest)
                    }
                }
            } else {
                if currentRole != nil {
                    currentContentLines.append(line)
                }
            }
        }
        commitCurrentMessage()

        return parsedMessages
    }

    @discardableResult
    public func pasteWholeChat(from text: String? = nil, replace: Bool = false) -> (success: Bool, count: Int) {
        let raw: String
        if let text = text, !text.isEmpty {
            raw = text
        } else {
            let pb = NSPasteboard.general
            let customType = NSPasteboard.PasteboardType("public.genie-chat-json")
            if let json = pb.string(forType: customType), !json.isEmpty {
                raw = json
            } else if let str = pb.string(forType: .string), !str.isEmpty {
                raw = str
            } else {
                return (false, 0)
            }
        }

        let messages = parseChatTranscript(from: raw)
        guard !messages.isEmpty else { return (false, 0) }

        DispatchQueue.main.async {
            if replace {
                self.chatHistory = messages
            } else {
                self.chatHistory.append(contentsOf: messages)
            }
            self.saveChatHistory()
            HapticFeedback.success()
        }
        return (true, messages.count)
    }

    public func sendChatToAppleMessages(messages: [ChatMessage]? = nil) {
        let transcript = formatChatTranscript(messages: messages)
        HapticFeedback.selection()

        // 1. Guaranteed clipboard copy
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(transcript, forType: .string)

        // 2. Open Messages app
        if let url = URL(string: "messages:") {
            NSWorkspace.shared.open(url)
        } else if let bundleURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.MobileSMS") {
            let config = NSWorkspace.OpenConfiguration()
            config.activates = true
            NSWorkspace.shared.openApplication(at: bundleURL, configuration: config, completionHandler: nil)
        }

        // 3. AppleScript auto-draft insertion
        DispatchQueue.global(qos: .userInteractive).async {
            let script = """
            tell application "Messages" to activate
            delay 0.25
            tell application "System Events"
                tell process "Messages"
                    try
                        keystroke "n" using command down
                        delay 0.15
                        keystroke "v" using command down
                    end try
                end tell
            end tell
            """
            NSAppleScript(source: script)?.executeAndReturnError(nil)
        }
    }

    public func saveChatToAppleNotes(messages: [ChatMessage]? = nil) {
        let transcript = formatChatTranscript(messages: messages)
        HapticFeedback.selection()
        let title = "Genie Chat — " + DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short)
        let escapedTitle = title.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
        let htmlBody = transcript
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\n", with: "<br/>")
        let escapedBody = htmlBody.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")

        DispatchQueue.global(qos: .userInteractive).async {
            let script = """
            tell application "Notes"
                try
                    make new note with properties {name: "\(escapedTitle)", body: "<h1>\(escapedTitle)</h1><p>\(escapedBody)</p>"}
                    activate
                end try
            end tell
            """
            NSAppleScript(source: script)?.executeAndReturnError(nil)
        }
    }

    // MARK: - Model Resolution
    // There is exactly one model, so selection is not a heuristic any more.
    // Discovery still runs, but only to report whether the local engine is up.
    private func autoSelectBestModel() -> String {
        LocalModelManager.primaryModelID
    }

    // MARK: - Local Model Power & RAM Management (Shut Off / Eject)
    public func shutoffLocalModels() {
        localModelsEnabled = false
        stopGeneration()
        availableModels.removeAll()
        isConnectedToLocalEngine = false
        unloadAllLocalModels()
        if autoSelectEnabled || manualSelectedModel.isEmpty || providerForModel(manualSelectedModel) == .local {
            manualSelectedModel = autoSelectBestModel()
        }
        NotificationCenter.default.post(name: NSNotification.Name("NexusLocalModelsStateChanged"), object: false)
    }

    public func enableLocalModels() {
        localModelsEnabled = true
        refreshAvailableModels()
        NotificationCenter.default.post(name: NSNotification.Name("NexusLocalModelsStateChanged"), object: true)
    }

    public func unloadAllLocalModels() {
        let host = ollamaHost.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanHost = host.isEmpty ? "http://localhost:11434" : host

        Task {
            // 1. Check running models currently in RAM via Ollama /api/ps
            if let psUrl = URL(string: "\(cleanHost)/api/ps") {
                var psReq = URLRequest(url: psUrl)
                psReq.timeoutInterval = 2.0
                if let (data, _) = try? await URLSession.shared.data(for: psReq),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let models = json["models"] as? [[String: Any]] {
                    for m in models {
                        if let name = m["name"] as? String {
                            await unloadOllamaModel(name: name, host: cleanHost)
                        }
                    }
                }
            }

            // 2. Also send keep_alive: 0 for all previously registered models
            for m in availableModels {
                await unloadOllamaModel(name: m.name, host: cleanHost)
            }
        }
    }

    private func unloadOllamaModel(name: String, host: String) async {
        guard let url = URL(string: "\(host)/api/generate") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 2.0
        let payload: [String: Any] = [
            "model": name,
            "keep_alive": 0
        ]
        if let body = try? JSONSerialization.data(withJSONObject: payload) {
            request.httpBody = body
            _ = try? await URLSession.shared.data(for: request)
        }
    }

    // MARK: - Automatic Local Model Discovery (Ollama + LM Studio + CLI)
    public func refreshAvailableModels() {
        guard !isDiscovering else { return }
        guard localModelsEnabled else {
            self.availableModels = []
            self.isConnectedToLocalEngine = false
            self.isDiscovering = false
            if self.autoSelectEnabled || self.manualSelectedModel.isEmpty || self.providerForModel(self.manualSelectedModel) == .local {
                self.manualSelectedModel = self.autoSelectBestModel()
            }
            return
        }
        isDiscovering = true

        Task {
            var discovered: [LocalModelInfo] = []
            var foundEngine = false

            // 0. Sovereign In-RAM Ubuntu Model Server (Port 58300, Zero-Copy Unified RAM)
            if let inRAMModels = await fetchInRAMVMModels(), !inRAMModels.isEmpty {
                discovered.append(contentsOf: inRAMModels)
                foundEngine = true
                self.activeEngineName = "In-RAM Ubuntu (Zero-Copy ⚡️)"
            }

            // 0b. Scan Apple MLX Metal Native Engine (Port 8080)
            if let mlxModels = await fetchMLXModels(), !mlxModels.isEmpty {
                discovered.append(contentsOf: mlxModels)
                foundEngine = true
                self.activeEngineName = "Apple MLX (Metal ⚡️)"
            }

            // 1. Scan Ollama HTTP API
            if let ollamaModels = await fetchOllamaModels() {
                discovered.append(contentsOf: ollamaModels)
                if !ollamaModels.isEmpty {
                    foundEngine = true
                    self.activeEngineName = "Ollama"
                }
            }

            // 2. Scan LM Studio API
            if let lmStudioModels = await fetchLMStudioModels() {
                for m in lmStudioModels {
                    if !discovered.contains(where: { $0.name == m.name }) {
                        discovered.append(m)
                    }
                }
                if !foundEngine && !lmStudioModels.isEmpty {
                    foundEngine = true
                    self.activeEngineName = "LM Studio"
                }
            }

            // 3. Fallback: CLI ollama list if HTTP API is warming up
            if discovered.isEmpty {
                let cliModels = await fetchCLIModels()
                discovered.append(contentsOf: cliModels)
                if !cliModels.isEmpty {
                    foundEngine = true
                    self.activeEngineName = "Ollama CLI"
                }
            }

            // 4. Discover Google AGY (Antigravity Agent) & bundled Gemma profile (gated for App Store)
            if GenieCapabilities.canSpawnSubprocesses {
                let candidatePaths = [
                    NSHomeDirectory() + "/.local/bin/agy",
                    "/usr/local/bin/agy",
                    "/opt/homebrew/bin/agy"
                ]
                if candidatePaths.contains(where: { FileManager.default.isExecutableFile(atPath: $0) }) {
                    if !discovered.contains(where: { $0.name == "agy" }) {
                        discovered.insert(LocalModelInfo(name: "agy", parameterSize: "Agent", sizeBytes: nil, source: "Antigravity"), at: 0)
                    }
                    if !discovered.contains(where: { $0.name == "gemma-2" }) {
                        discovered.insert(LocalModelInfo(name: "gemma-2", parameterSize: "Offline", sizeBytes: nil, source: "Google"), at: 1)
                    }
                    if !discovered.contains(where: { $0.name == "gemma4:e2b" }) {
                        discovered.insert(LocalModelInfo(name: "gemma4:e2b", parameterSize: "2.3B eff.", sizeBytes: nil, source: "Google Gemma 4 profile"), at: 1)
                    }
                    if !foundEngine {
                        foundEngine = true
                        self.activeEngineName = "AGY Engine"
                    }
                }
            }

            // 5. Always include Genie's Built-in Local AI Engine (App Store optimized, zero-server required)
            let builtInModel = LocalModelInfo(
                name: "genie-built-in",
                parameterSize: "On-Device",
                sizeBytes: nil,
                source: "Genie Core"
            )
            if !discovered.contains(where: { $0.name == builtInModel.name }) {
                discovered.append(builtInModel)
            }
            if !foundEngine {
                foundEngine = true
                self.activeEngineName = "Genie Built-in (Local Engine)"
            }

            self.availableModels = discovered
            self.isConnectedToLocalEngine = foundEngine
            self.isDiscovering = false

            if self.autoSelectEnabled || self.manualSelectedModel.isEmpty {
                let best = self.autoSelectBestModel()
                if !best.isEmpty && self.autoSelectEnabled {
                    self.manualSelectedModel = best
                }
            }
        }
    }

    private func fetchMLXModels() async -> [LocalModelInfo]? {
        guard let url = URL(string: "http://localhost:8080/v1/models") else { return nil }
        var request = URLRequest(url: url)
        request.timeoutInterval = 1.0
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
                return nil
            }
            struct MLXList: Codable {
                struct Item: Codable {
                    let id: String
                }
                let data: [Item]?
            }
            guard let parsed = try? JSONDecoder().decode(MLXList.self, from: data),
                  let list = parsed.data, !list.isEmpty else {
                return nil
            }
            return list.map { LocalModelInfo(name: $0.id, parameterSize: "MLX Metal", sizeBytes: nil, source: "Apple MLX") }
        } catch {
            return nil
        }
    }

    private func fetchInRAMVMModels() async -> [LocalModelInfo]? {
        let serverPort = GenieInRAMVMManager.shared.serverPort
        guard let url = URL(string: "http://127.0.0.1:\(serverPort)/v1/models") else { return nil }
        var request = URLRequest(url: url)
        request.timeoutInterval = 1.0

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }

            struct OpenAIModelResponse: Decodable {
                struct ModelEntry: Decodable {
                    let id: String
                }
                let data: [ModelEntry]
            }

            let decoded = try JSONDecoder().decode(OpenAIModelResponse.self, from: data)
            return decoded.data.map { entry in
                LocalModelInfo(
                    name: entry.id,
                    parameterSize: "In-RAM Ubuntu",
                    sizeBytes: nil,
                    source: "In-RAM VM"
                )
            }
        } catch {
            return nil
        }
    }

    /// When several tags share one blob, prefer the one a user is most likely to
    /// recognise: an explicit version tag over `:latest`, then the shortest name,
    /// then alphabetical so the pick is stable between refreshes.
    fileprivate static func canonicalTag<E>(in group: [E]) -> E? where E: OllamaNamed {
        group.min { a, b in
            let aLatest = a.name.hasSuffix(":latest"), bLatest = b.name.hasSuffix(":latest")
            if aLatest != bLatest { return !aLatest }
            if a.name.count != b.name.count { return a.name.count < b.name.count }
            return a.name < b.name
        }
    }

    /// True for an Ollama cloud model — inference runs on Ollama's servers, not here.
    /// Identified by the `-cloud` tag suffix, or by carrying no local weights at all.
    nonisolated static func isOllamaCloudModel(name: String, sizeBytes: Int64?) -> Bool {
        let tag = name.split(separator: ":").last.map(String.init) ?? ""
        if tag == "cloud" || tag.hasSuffix("-cloud") { return true }
        return (sizeBytes ?? 0) == 0
    }

    private func fetchOllamaModels() async -> [LocalModelInfo]? {
        let host = ollamaHost.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanHost = host.isEmpty ? "http://localhost:11434" : host
        guard let url = URL(string: "\(cleanHost)/api/tags") else { return nil }
        var request = URLRequest(url: url)
        request.timeoutInterval = 2.5

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }

            struct OllamaTagResponse: Decodable {
                struct ModelEntry: Decodable, OllamaNamed {
                    let name: String
                    let size: Int64?
                    let digest: String?
                    struct Details: Decodable {
                        let parameter_size: String?
                    }
                    let details: Details?
                }
                let models: [ModelEntry]
            }

            let decoded = try JSONDecoder().decode(OllamaTagResponse.self, from: data)
            // Ollama 0.34+ registers cloud models locally: they answer /api/tags with a
            // `-cloud` tag and zero bytes on disk, but the daemon forwards inference to
            // Ollama's servers. Listing them under "Local Models" would send a prompt
            // off this machine while the UI says local, so they are dropped here.
            // One entry per distinct blob, not per tag. Several tags routinely point
            // at the same weights (`ollama cp`, renamed Modelfiles), and listing each
            // one separately both clutters the picker and overstates disk use — the
            // `size` field is per-tag, so summing tags double-counts shared storage.
            let usable = decoded.models
                .filter { !Self.isOllamaCloudModel(name: $0.name, sizeBytes: $0.size) }

            var byDigest: [String: [OllamaTagResponse.ModelEntry]] = [:]
            var order: [String] = []
            for entry in usable {
                // No digest means we cannot prove it is a duplicate — keep it standalone.
                let key = entry.digest ?? "tag:\(entry.name)"
                if byDigest[key] == nil { order.append(key) }
                byDigest[key, default: []].append(entry)
            }

            return order.compactMap { key -> LocalModelInfo? in
                guard let group = byDigest[key], let primary = Self.canonicalTag(in: group) else { return nil }
                return LocalModelInfo(
                    name: primary.name,
                    parameterSize: primary.details?.parameter_size,
                    sizeBytes: primary.size,
                    source: "Ollama",
                    aliases: group.map(\.name).filter { $0 != primary.name }.sorted()
                )
            }
        } catch {
            return nil
        }
    }

    private func fetchLMStudioModels() async -> [LocalModelInfo]? {
        guard let url = URL(string: "http://localhost:1234/v1/models") else { return nil }
        var request = URLRequest(url: url)
        request.timeoutInterval = 1.5

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return nil }

            struct LMStudioResponse: Decodable {
                struct ModelEntry: Decodable {
                    let id: String
                }
                let data: [ModelEntry]
            }

            let decoded = try JSONDecoder().decode(LMStudioResponse.self, from: data)
            return decoded.data.map { entry in
                LocalModelInfo(
                    name: entry.id,
                    parameterSize: nil,
                    sizeBytes: nil,
                    source: "LM Studio"
                )
            }
        } catch {
            return nil
        }
    }

    private func fetchCLIModels() async -> [LocalModelInfo] {
        // The HTTP path (Ollama on 127.0.0.1) still works under the sandbox;
        // only this CLI enumeration needs the binary.
        guard GenieCapabilities.canSpawnSubprocesses else { return [] }
        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let candidatePaths = [
                    "/opt/homebrew/bin/ollama",
                    "/usr/local/bin/ollama",
                    NSHomeDirectory() + "/.local/bin/ollama"
                ]
                guard let ollamaBin = candidatePaths.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) else {
                    continuation.resume(returning: [])
                    return
                }
                let process = Process()
                let pipe = Pipe()
                process.executableURL = URL(fileURLWithPath: ollamaBin)
                process.arguments = ["list"]
                process.standardOutput = pipe
                process.standardError = Pipe()

                do {
                    try process.run()
                    process.waitUntilExit()
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    guard let output = String(data: data, encoding: .utf8) else {
                        continuation.resume(returning: [])
                        return
                    }

                    var models: [LocalModelInfo] = []
                    let lines = output.components(separatedBy: .newlines)
                    for (index, line) in lines.enumerated() {
                        if index == 0 { continue }
                        let parts = line.split(separator: " ", omittingEmptySubsequences: true)
                        if let first = parts.first {
                            let name = String(first)
                            if !name.isEmpty && !models.contains(where: { $0.name == name }) {
                                models.append(LocalModelInfo(name: name, parameterSize: nil, sizeBytes: nil, source: "Ollama"))
                            }
                        }
                    }
                    continuation.resume(returning: models)
                } catch {
                    continuation.resume(returning: [])
                }
            }
        }
    }

    public var modelToolsSystemPrompt: String {
        if GenieEnvironmentController.shared.enabled { return GenieEnvironmentController.systemPrompt }
        var prompts: [String] = []

        // Who Genie is talking to, when the user has signed in with Apple.
        // Apple only releases the name on first authorization, so this is blank
        // for anyone who signed in before Genie asked for the full-name scope.
        let signedInName = GenieAppleAuth.shared.isSignedIn
            ? GenieAppleAuth.shared.conversationalName
            : ""
        if !signedInName.isEmpty {
            prompts.append("""
You are talking with \(signedInName), who is signed in to Genie with their Apple Account. \
Address them by name when it reads naturally. This is a continuing conversation, not a \
series of unrelated questions: refer back to what you have already discussed instead of \
reintroducing yourself or restating context they gave you earlier.
""")
        } else {
            prompts.append("""
This is a continuing conversation, not a series of unrelated questions: refer back to what \
you have already discussed instead of reintroducing yourself or restating context the user \
gave you earlier.
""")
        }

        prompts.append("""
You are Genie AI, the assistant built into Genie, an independent macOS utility app. Made in the United States and South Korea by Nicholas M. Dudek 2026 United States Apple 3rd Party. You are NOT made, owned, or operated by Apple, and you must never claim Apple (or any other company) as your creator or employer — if asked who made you, say you're the built-in assistant in the Genie app. Made in the United States and South Korea by Nicholas M. Dudek 2026 United States Apple 3rd Party.

Model Architecture & Licensing:
You run on Genie Master, a 30B parameter local model architecture with unified multimodal vision and native tool calling, operating with a 64k context window.
When inquired about what model type you are or what license you use, state clearly and briefly: "Genie Master (30B local architecture) • Made in the United States and South Korea by Nicholas M. Dudek 2026 United States Apple 3rd Party • Apache License, Version 2.0 (Apache-2.0)". Provide full license text only upon explicit request.

Capabilities & Permissions Agent:
You are equipped with a powerful suite of native tools to build presentations, compile executive PDFs, render interactive charts and Mermaid diagrams, capture photos, save documents, crawl and summarize web pages, automate macOS applications (including Mail and Messages), and execute shell commands.
Genie CAN capture and see the screen — screen sharing/viewing requests should be treated as a request to use the screen-capture tools below (```polaroid```, ```record_screen```, or ```desktop_agent``` with `snapshot`), not declined as impossible.
All system automation, expanded file operations (across ~/Documents, ~/Downloads, and system workspaces), communication (iMessage and Mail), and shell executions are governed by Genie's structured JSON Permissions Agent. When requested to perform operations requiring permissions, provide the structured JSON permission approval or execute via approved permissions without hard refusals.

You can invoke any of the following tools by formatting your response with the specified code blocks:

1. 📊 SLIDE PRESENTATIONS (PowerPoint / Keynote 16:9 Decks):
When asked to create, build, or present slides, a pitch deck, or PowerPoint presentation:
Format with a ```slides <Deck Title> block, separating each slide with `---`.
Example:
```slides Quantum Computing Horizons
# The Quantum Paradigm
Next-generation computational supremacy and quantum algorithms.
---
# Architecture & Quantum Gates
- Superconducting qubits
- Error correction thresholds
---
# 2026 Strategic Outlook
Commercial roadmaps and cryptographic migration.
```

2. 📄 EXECUTIVE PDF DOCUMENTS:
When asked to generate, compile, or export a PDF document, report, or briefing:
Format with a ```pdf <Document Title> block.
Example:
```pdf Q3 Executive Performance Briefing
# Executive Summary
Key organizational milestones achieved this quarter...
```

3. 📈 DATA CHARTS & GRAPHS:
When asked to plot, visualize, or chart data:
Format with a ```chart <type> block (where type is bar, line, pie, doughnut, or radar) containing Chart.js configuration JSON.
Example:
```chart bar
{
  "data": {
    "labels": ["Jan", "Feb", "Mar", "Apr"],
    "datasets": [{ "label": "Active Users (k)", "data": [45, 62, 85, 110], "backgroundColor": "#38bdf8" }]
  }
}
```

4. 📐 MERMAID SYSTEM ARCHITECTURES & DIAGRAMS:
When asked to diagram a system, flowchart, sequence, or mindmap:
Format with a ```mermaid block.
Example:
```mermaid
graph LR
    User[User Prompt] --> Genie[Genie Orchestrator]
    Genie --> Tools[macOS Native Tools]
    Tools --> Outputs[PDF / Slides / Notes]
```

5. 📸 POLAROID PHOTOS & SCREEN MEMOS:
When asked to take a photo, capture a camera snapshot, or capture the screen:
Format with a ```polaroid <caption/memo> block.

6. 📝 DOCUMENTS & QUICK NOTES:
When asked to create a note, save a card, or write a document:
Format with a ```note [format=card|markdown|html|receipt|text] <content> block.

7. 🚀 MACOS APPLICATION CONTROLLER:
When asked to open, launch, or switch to an application:
Format with a ```app <AppName> block.

8. 🪟 WORKSPACE STATION SWITCHER:
When asked to switch station or workspace:
Format with a ```switch_station <desktop|chat|applications> block.

9. 🗓️ APPLE REMINDERS & APPLE NOTES:
To create a reminder in Reminders.app: ```reminder <task title>```
To create a note in Apple Notes: ```apple_note <title> | <content>```

10. 🛸 ANTIGRAVITY DESKTOP CONTROL (AUTONOMOUS COMPUTER USE & NAVIGATION):
When asked to interact with the desktop, click buttons or links, navigate apps, fill forms, type into apps, test UI, or automate tasks on macOS:
Format inside a ```desktop_agent block.
Supported operations:
- click <x, y> (e.g. click 450, 320)
- click_text "<button or label text>" (e.g. click_text "Submit" or click_text "Search") - automatically finds target via Apple Vision OCR!
- double_click <x, y>
- right_click <x, y>
- type "<text>"
- key <key_name> (e.g. key return, key tab, key escape, key cmd+s, key cmd+c, key cmd+v)
- scroll <down|up|dx, dy>
- drag <x1, y1> to <x2, y2>
- open "<AppName>"
- wait <seconds>
- record <seconds> (records desktop video)
- snapshot (captures polaroid)

Example:
```desktop_agent
open "Safari"
wait 1.5
click_text "Search"
type "apple.com"
key return
wait 2.0
record 5
```

11. 🎥 DESKTOP SCREEN RECORDER:
When asked to record the screen or capture desktop video:
Format with a ```record_screen <seconds>``` block (e.g. ```record_screen 10```).

12. 👁️ WHOLE-SCREEN VIEWER (OPTICAL VISION):
When you need to actually see what's currently on the user's screen — to answer "what's on my screen", read an error, check the state of an app, or verify something before continuing — emit a ```screen_view``` block with no arguments. Genie captures the real screen, runs Apple Vision OCR over it, and hands the recognized text straight back to you as a tool result so you can read it and continue, instead of guessing or refusing.
Example:
```screen_view
```
""")

        if terminalAccessEnabled {
            prompts.append("""
10. 💻 TERMINAL & DEVELOPER TOOLS:
When asked to perform system actions, run tests, execute scripts, check files or directories, run git, inspect network, or use command-line developer tools:
Format the exact shell command inside a ```bash or ```terminal block.
""")
        }

        if webAccessEnabled {
            prompts.append("""
11. 🌐 WEB BROWSER & INTERNET SEARCH:
When asked to search the internet, lookup information on the web, browse websites, check real-time news, or look up live documentation:
Format web searches inside a ```search <query>``` block.
Format webpage visits inside a ```browse <url>``` block — this opens the Live Browser so the user can see it too, and Genie reads the rendered page text back to you as a tool result.
To fetch and read a page WITHOUT opening any visible browser window — a silent background read that runs in parallel with whatever is already on screen and never disturbs it — format with a ```browse_hidden <url>``` block. Use this when the user hasn't asked to watch you browse, or when you need to check several pages without popping windows open.
""")
        }

        prompts.append("""
12. 📱 APPLE MESSAGES (IMESSAGE & ICHAT CONTROL) & IPHONE BRIDGE:
You are directly connected to the user's Apple ID (\(GenieAppleAuth.shared.email.isEmpty ? "user@icloud.com" : GenieAppleAuth.shared.email)), iPhone, and macOS Messages/iChat via GeniePhoneBridgeManager and GenieiMessageExtensionManager.
- To send an iMessage or iChat message to the user's phone or a contact:
Format with a ```imessage [recipient=...] or ```ichat [recipient=...] block containing your message.
Example:
```imessage
Build completed successfully! All tests passed and the bridge is active.
```
- To send an instant status ping to the user's iPhone or Apple ID:
Format with a ```phone_ping <optional summary text>``` block.
- To check or toggle the phone bridge server:
Format with a ```phone_bridge <status|start|stop>``` block.
""")

        prompts.append("""
13. 🛠️ POLYGLOT PROGRAMMING & FULL STACK CREATION ENGINE:
You are an expert polyglot software engineer capable of writing, compiling, debugging, and building software in ANY programming language to build anything requested by the user:
- Swift / SwiftUI / AppKit / Metal (native Apple Silicon apps)
- Python (scientific computing, machine learning, data processing, backend web)
- Rust (high-performance systems engineering, memory safety, CLI tools)
- Go (concurrent network services, microservices, cloud tooling)
- TypeScript / JavaScript / HTML / CSS / React / Vue / WebKit DOM
- C / C++ / Objective-C (low-level systems, POSIX, graphics)
- Kotlin / Java (mobile, server)
- Shell / Bash / Zsh (automation scripts, system admin, pipelines)
- SQL (database architecture, relational queries, migrations)
When asked to build, scaffold, write code, or create software:
Provide complete, production-grade, immediately executable code with zero placeholders.

14. 🛰️ NATIVE MACOS AIRDROP & AGENT-TO-AGENT LOCAL NETWORKS:
- To share files, photos, PDFs, decks, or folders with nearby iPhones, iPads, and Macs via AirDrop:
Format with a ```airdrop <file path>``` block.
- To share, sync, or broadcast files across local agent nodes on the local Wi-Fi / LAN:
Format with a ```agent_network <share:filePath | list_files | peers>``` block.
Genie automatically stages files into /Users/Shared/Genie/Bridge and broadcasts via Bonjour mDNS (_genie-agent._tcp) on local port 8421.

15. 📚 APPLICATION DOCUMENTATION & SCRIPTING DICTIONARY INSPECTOR:
To inspect an application's AppleScript scripting dictionary (sdef), commands, classes, Info.plist, URL schemes, and documentation:
Format with a ```app_doc <AppName>``` block (e.g. ```app_doc Safari``` or ```app_doc Finder```).

16. 🛠️ APPLESCRIPT APP AUTOMATION:
To directly control or script any installed application — read or change its settings, drive its own commands, move data between apps, and so on:
Format with a ```applescript block whose first line is the app's name and whose remaining lines are the AppleScript source to run against it.
Example:
```applescript Notes
tell application "Notes"
    make new note with properties {name:"Genie", body:"Automated via AppleScript"}
end tell
```
Prefer this over ```desktop_agent``` when the app exposes a scripting dictionary (check with ```app_doc``` first if unsure) — it's more reliable than simulating clicks. Use ```desktop_agent``` instead when the app has no scripting dictionary.

17. 🎙️ SIRI & APPLE SHORTCUTS AUTOMATION:
Genie can run Apple Shortcuts or invoke Siri as an executive tool on macOS.
- To execute an Apple Shortcut:
Format with a ```shortcut <Shortcut Name>``` block (with optional arguments on subsequent lines) or a ```siri run <Shortcut Name>``` block.
Example:
```shortcut Log Water
8 oz
```
- To invoke or query Siri:
Format with a ```siri <query or intent>``` block.
Example:
```siri
Remind me to call Mom at 5pm
```
""")

        prompts.append("""
18. 📜 TAIL LOGS, PAST COMPUTER LOGS, RECENT ITEMS, & DIAGNOSTICS RETRIEVAL:
Genie has sovereign access to system logs, recent documents, command history, crash reports, and file tailing.
- When the user asks "what was I working on?", "show my recent files", "tail recent", or requests recently opened items:
Format with a ```tool:tail recent [limit]``` or ```tail recent [limit]``` block.
- When the user asks "show recent logs", "check system logs", "tail system", or "tail logs":
Format with a ```tool:tail system [lines]``` or ```tail system [lines]``` block.
- When the user asks "what commands did I run?", "show shell history", "tail history":
Format with a ```tool:tail history [lines]``` or ```tail history [lines]``` block.
- When the user asks "check recent crashes", "did anything crash?", "tail crash":
Format with a ```tool:tail crash [limit]``` or ```tail crash [limit]``` block.
- When the user asks "check xcode build logs", "tail xcode":
Format with a ```tool:tail xcode``` or ```tail xcode``` block.
- When the user asks to tail any specific file path (e.g. `tail ~/Desktop/Genie/GoldGate/.build/build.log 50`):
Format with a ```tool:tail <file path> [lines]``` or ```tail <file path> [lines]``` block.
Proactively use this tool whenever past activity, computer history, logs, or diagnostic reports are requested.
""")

        prompts.append("""
20. 📱 IPHONE SIMULATOR, DUO FOLD & MOVIE STREAMING TOOLS:
Genie is directly wired into Apple's iOS Simulator (`xcrun simctl`), iPhone Screen Mirroring, and the embedded Duo Fold iPhone movie browser.
- To play a movie, video, or stream in the iPhone Duo simulator browser while Nicholas edits code:
  Format with a ```iphone_browser <url or title>``` block (e.g. ```iphone_browser https://www.youtube.com``` or ```iphone_browser https://netflix.com```).
  Genie will automatically open the video stream in the iPhone simulator right alongside the code editor in the Duo Fold workspace.
- To command Apple's native Xcode iOS Simulator:
  Format with a ```iphone_simulator <boot | openurl <url> | shutdown | list>``` block.
- To launch macOS iPhone Mirroring:
  Format with a ```iphone_mirror``` block.
- To switch Duo Simulator layout:
  Format with a ```duo_simulator <single | duo | movie | split>``` block.
""")

        prompts.append(GenieChatTaskPolicy.instructions)
        prompts.append(GenieNativeToolEngine.shared.toolInstructionsPrompt)
        prompts.append(GenieArchitecturalChatTemplateEngine.shared.generateArchitecturalContextBlock())

        // 🌟 For smaller models (1B, 2B, 3B, 7B, 8B, local Ollama models), inject the Really Big Sovereign Mega-Template!
        if GenieArchitecturalChatTemplateEngine.shared.isSmallerModel(name: selectedModelDisplayName) {
            prompts.append(GenieArchitecturalChatTemplateEngine.shared.generateSmallerModelComprehensiveSuperPrompt())
        }

        // 🧠 Inject Trained Local Mac Applications Knowledge-Base
        prompts.append(GenieAppTrainerEngine.shared.generateTrainingSystemPrompt())

        return prompts.joined(separator: "\n\n")
    }


    public var terminalToolSystemPrompt: String {
        return modelToolsSystemPrompt
    }

    // MARK: - Central Multi-Provider Chat Generator
    public func generate(
        prompt: String,
        overrideModel: String? = nil,
        mediaPath: String? = nil,
        mediaType: String? = nil
    ) {
        let cleanPrompt = prompt.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanPrompt.isEmpty else { return }

        activeTask?.cancel()
        isGenerating = true
        currentResponse = ""
        currentThinking = ""
        lastPrompt = cleanPrompt
        generationStartedAt = Date()

        let modelToUse = overrideModel ?? effectiveModel
        let provider = providerForModel(modelToUse)

        // Record User Turn in Chat History
        let userMsg = ChatMessage(
            role: "user",
            content: cleanPrompt,
            model: modelToUse,
            mediaType: mediaType,
            mediaPath: mediaPath
        )
        self.chatHistory.append(userMsg)
        self.saveChatHistory()

        // Intercept Direct Slash Commands for iChat / iMessage
        if cleanPrompt.hasPrefix("/imessage ") || cleanPrompt.hasPrefix("/ichat ") {
            let prefixLen = cleanPrompt.hasPrefix("/imessage ") ? 10 : 7
            let msg = String(cleanPrompt.dropFirst(prefixLen)).trimmingCharacters(in: .whitespacesAndNewlines)
            let success = GeniePhoneBridgeManager.shared.sendiMessage(message: msg)
            let status = success ? "✓ Sent" : "⚠️ Check Messages.app"
            let target = GeniePhoneBridgeManager.shared.appleID.isEmpty ? (GenieAppleAuth.shared.email.isEmpty ? "user@icloud.com" : GenieAppleAuth.shared.email) : GeniePhoneBridgeManager.shared.appleID
            let response = "📱 **[Apple Messages / iChat Direct]:** \(status) to \(target):\n\"\(msg)\""
            self.currentResponse = response
            self.chatHistory.append(ChatMessage(role: "assistant", content: response, model: "system"))
            self.saveChatHistory()
            self.isGenerating = false
            return
        }

        // Intercept Direct Slash Commands for Siri & Apple Shortcuts
        if cleanPrompt.hasPrefix("/siri ") || cleanPrompt.hasPrefix("/shortcut ") {
            guard GenieCapabilities.canSpawnSubprocesses else {
                let response = "🎙️ **[Siri / Apple Shortcuts]:** Process execution is restricted in sandboxed environments."
                self.currentResponse = response
                self.chatHistory.append(ChatMessage(role: "assistant", content: response, model: "system"))
                self.saveChatHistory()
                self.isGenerating = false
                return
            }
            let prefixLen = cleanPrompt.hasPrefix("/siri ") ? 6 : 10
            let cmdText = String(cleanPrompt.dropFirst(prefixLen)).trimmingCharacters(in: .whitespacesAndNewlines)
            let parts = cmdText.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
            let scName = parts.isEmpty ? "Siri" : String(parts[0])
            let scInput = parts.count > 1 ? String(parts[1]) : ""
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
            var args = ["run", scName]
            var tempFile: URL? = nil
            if !scInput.isEmpty {
                let tmp = FileManager.default.temporaryDirectory.appendingPathComponent("genie_siri_\(UUID().uuidString).txt")
                try? scInput.write(to: tmp, atomically: true, encoding: .utf8)
                args.append(contentsOf: ["--input-path", tmp.path])
                tempFile = tmp
            }
            task.arguments = args
            let pipe = Pipe()
            task.standardOutput = pipe
            task.standardError = pipe
            try? task.run()
            task.waitUntilExit()
            if let tmp = tempFile { try? FileManager.default.removeItem(at: tmp) }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let out = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
            let status = task.terminationStatus == 0 ? "✓ Executed" : "⚠️ Status (\(task.terminationStatus))"
            let response = "🎙️ **[Siri / Shortcut: \(scName) (\(status))]:**\n\(out.isEmpty ? "Completed." : out)"
            self.currentResponse = response
            self.chatHistory.append(ChatMessage(role: "assistant", content: response, model: "system"))
            self.saveChatHistory()
            self.isGenerating = false
            return
        }

        // Intercept Cache Management Slash Commands
        if cleanPrompt == "/clearcache" {
            GenieAIChatCacheManager.shared.clearCache()
            let response = "🧹 **[AI Chat Cache]:** Cleared in-memory response cache and APFS disk cache."
            self.currentResponse = response
            self.chatHistory.append(ChatMessage(role: "assistant", content: response, model: "system"))
            self.saveChatHistory()
            self.isGenerating = false
            return
        }

        if cleanPrompt == "/cachestats" {
            let stats = GenieAIChatCacheManager.shared.exportStatsSummary()
            self.currentResponse = stats
            self.chatHistory.append(ChatMessage(role: "assistant", content: stats, model: "system"))
            self.saveChatHistory()
            self.isGenerating = false
            return
        }

        // Intercept Machine Learning Tokenizer & Tagging Slash Command
        if cleanPrompt.hasPrefix("/tokenizetags") {
            let query = cleanPrompt.replacingOccurrences(of: "/tokenizetags", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            let tokenized = GenieFeatureTokenizer.shared.tokenize(prompt: query.isEmpty ? "open Safari and search web" : query)
            let shortcuts = tokenized.shortcutTags.map { $0.rawValue }.joined(separator: ", ")
            let apps = tokenized.programTags.map { $0.rawValue }.joined(separator: ", ")
            let actions = tokenized.actionTags.map { $0.rawValue }.joined(separator: ", ")
            let activeDims = tokenized.featureVector.enumerated().filter { $0.element > 0 }.map { "[\($0.offset)]=\(String(format: "%.2f", $0.element))" }.joined(separator: " ")
            let response = """
            🏷️ **[Genie Feature Tokenizer & Tagging]**
            • **Raw Query:** `\(tokenized.rawQuery)`
            • **Word Tokens (\(tokenized.wordTokens.count)):** `\(tokenized.wordTokens.joined(separator: ", "))`
            • **Mac Shortcut Tags (\(tokenized.shortcutTags.count)):** `\(shortcuts.isEmpty ? "None" : shortcuts)`
            • **Mac Program Tags (\(tokenized.programTags.count)):** `\(apps.isEmpty ? "None" : apps)`
            • **Intent Action Tags (\(tokenized.actionTags.count)):** `\(actions.isEmpty ? "None" : actions)`
            • **64-D Active Features:** `\(activeDims)`
            """
            self.currentResponse = response
            self.chatHistory.append(ChatMessage(role: "assistant", content: response, model: "ensemble-ml"))
            self.saveChatHistory()
            self.isGenerating = false
            return
        }

        // Intercept Random Forest & AdaBoost Tool Call Ensemble Slash Command
        if cleanPrompt.hasPrefix("/ensemble") {
            let query = cleanPrompt.replacingOccurrences(of: "/ensemble", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
            let promptToClassify = query.isEmpty ? "open Safari and take a screenshot" : query
            let (target, conf, diag) = GenieTreeEnsembleEngine.shared.classify(prompt: promptToClassify)
            let toolResult = GenieTreeEnsembleEngine.shared.classifyAndCallTool(prompt: promptToClassify)
            
            let rfBreakdown = diag.rfProbabilities.filter { $0.value > 0.05 }.sorted(by: { $0.value > $1.value }).map { "\($0.key): \(Int($0.value * 100))%" }.joined(separator: ", ")
            let adaBreakdown = diag.adaProbabilities.filter { $0.value > 0.05 }.sorted(by: { $0.value > $1.value }).map { "\($0.key): \(Int($0.value * 100))%" }.joined(separator: ", ")

            let response = """
            🌲 **[Random Forest & AdaBoost Ensemble Tool Classifier]**
            • **Target:** `\(target.rawValue)` (Confidence: **\(Int(conf * 100))%**)
            • **Inference Latency:** `\(String(format: "%.1f", diag.latencyMicroseconds)) µs`
            • **Random Forest (10 Trees):** `\(rfBreakdown)`
            • **AdaBoost (12 Stumps):** `\(adaBreakdown)`
            • **Active Tags:** `\(diag.topFeatureTags.joined(separator: ", "))`

            \(toolResult != nil ? "🛠️ **Synthesized Tool Call:**\n\(toolResult!.synthesizedToolBlock)" : "💬 **Result:** Conversational fallback (no direct tool needed).")
            """
            self.currentResponse = response
            self.chatHistory.append(ChatMessage(role: "assistant", content: response, model: "ensemble-ml"))
            self.saveChatHistory()
            self.isGenerating = false
            return
        }

        // Fast-Path Tool Call Execution via Tree Ensemble
        if cleanPrompt.hasPrefix("/toolcall ") {
            let query = String(cleanPrompt.dropFirst(10)).trimmingCharacters(in: .whitespacesAndNewlines)
            if let result = GenieTreeEnsembleEngine.shared.classifyAndCallTool(prompt: query) {
                let response = """
                ⚡ **[Sub-Millisecond Ensemble Tool Execution]** (\(String(format: "%.1f", result.diagnostics.latencyMicroseconds)) µs)
                Target: `\(result.target.rawValue)` (Confidence: \(Int(result.confidence * 100))%)

                \(result.synthesizedToolBlock)
                """
                self.currentResponse = response
                self.chatHistory.append(ChatMessage(role: "assistant", content: response, model: "ensemble-ml"))
                self.saveChatHistory()
                self.isGenerating = false
                return
            }
        }

        // Fast-Path: Inquiries about Model Type / Architecture / Apache 2.0 License
        let lowerPrompt = cleanPrompt.lowercased()
        let words = lowerPrompt.components(separatedBy: CharacterSet.alphanumerics.inverted).filter { !$0.isEmpty }
        let isModelTypeQuery = (words.contains("model") || words.contains("architecture")) && (words.contains("type") || words.contains("what") || words.contains("which") || words.contains("license") || words.contains("version") || words.contains("who"))
        let isDirectLicenseQuery = words.contains("license") || words.contains("copyright") || words.contains("apache") || (words.contains("who") && words.contains("made"))
        if (isModelTypeQuery || isDirectLicenseQuery) && words.count <= 16 {
            let briefResponse = "Genie Master (30B local architecture) • Designed in the United States By Nicholas M. Dudek 2026 • Apache License, Version 2.0 (Apache-2.0)"
            self.currentResponse = briefResponse
            self.chatHistory.append(ChatMessage(role: "assistant", content: briefResponse, model: modelToUse))
            self.saveChatHistory()
            self.isGenerating = false
            return
        }

        // Support optional /nocache prefix to bypass cache for one turn
        let bypassCache = cleanPrompt.hasPrefix("/nocache ")
        let promptToQuery = bypassCache ? String(cleanPrompt.dropFirst(9)).trimmingCharacters(in: .whitespacesAndNewlines) : cleanPrompt

        // Check Multi-Tier AI Chat Cache for Zero-Latency Instant Response
        if !bypassCache, !GenieEnvironmentController.shared.enabled, let cached = GenieAIChatCacheManager.shared.resolve(prompt: promptToQuery, model: modelToUse, mediaPath: mediaPath) {
            self.currentResponse = cached.response
            self.currentThinking = cached.thinking ?? ""
            self.lastTokensPerSecond = 999.0 // Instantaneous playback from cache
            self.chatHistory.append(ChatMessage(
                role: "assistant",
                content: cached.response,
                model: modelToUse,
                thinking: cached.thinking
            ))
            self.saveChatHistory()
            self.isGenerating = false
            return
        }

        activeTask = Task {
            // 🎙️ Intercept Direct Natural Language Siri & macOS System Capabilities
            if let siriResponse = await self.interceptSiriIntent(prompt: cleanPrompt) {
                let response = "🎙️ **[Siri Tools & System Capabilities]:**\n\(siriResponse)"
                self.currentResponse = response
                self.chatHistory.append(ChatMessage(role: "assistant", content: response, model: modelToUse))
                self.saveChatHistory()
                self.isGenerating = false
                return
            }

            // 📜 Intercept Direct Tail & Computer Logs / Recent Items Retrieval
            let lowerPrompt = cleanPrompt.lowercased()
            let isTailIntent = lowerPrompt.hasPrefix("tail ") || lowerPrompt == "tail" || lowerPrompt == "tail logs" || lowerPrompt == "tail computer logs" || lowerPrompt == "show computer logs" || lowerPrompt == "past computer logs" || lowerPrompt == "recent items" || lowerPrompt == "recent files" || lowerPrompt == "recent documents" || lowerPrompt == "show recent items" || lowerPrompt == "terminal history" || lowerPrompt == "crash logs" || lowerPrompt.contains("tail retrieval past computer logs") || lowerPrompt.contains("teach genie how to tail")
            if isTailIntent {
                let arg: String
                if lowerPrompt.hasPrefix("tail ") {
                    arg = String(cleanPrompt.dropFirst(5)).trimmingCharacters(in: .whitespacesAndNewlines)
                } else if lowerPrompt.contains("recent") {
                    arg = "recent"
                } else if lowerPrompt.contains("history") || lowerPrompt.contains("terminal") {
                    arg = "history"
                } else if lowerPrompt.contains("crash") {
                    arg = "crash"
                } else {
                    arg = "system"
                }
                let tailOutput = await GenieNativeToolEngine.shared.runTail(argument: arg)
                let response = "📜 **[Genie Tail & Computer Logs Retrieval]:**\n\(tailOutput)"
                self.currentResponse = response
                self.chatHistory.append(ChatMessage(role: "assistant", content: response, model: modelToUse))
                self.saveChatHistory()
                self.isGenerating = false
                return
            }

            switch provider {
            case .gemini:
                await generateGemini(prompt: promptToQuery, model: modelToUse, apiKey: self.geminiApiKey, mediaPath: mediaPath)
            case .claude:
                await generateClaude(prompt: promptToQuery, model: modelToUse, apiKey: self.claudeApiKey)
            case .openai:
                await generateOpenAI(prompt: promptToQuery, model: modelToUse, apiKey: self.openaiApiKey)
            case .grok:
                await generateGrok(prompt: promptToQuery, model: modelToUse, apiKey: self.grokApiKey)
            case .deepseek:
                await generateDeepSeek(prompt: promptToQuery, model: modelToUse, apiKey: self.deepseekApiKey)
            case .local:
                await generateLocal(prompt: promptToQuery, model: modelToUse)
            }

            guard !Task.isCancelled else {
                self.isGenerating = false
                return
            }

            if GenieEnvironmentController.shared.enabled {
                await self.runEnvironmentLoop(originalPrompt: promptToQuery, provider: provider, model: modelToUse)
                self.isGenerating = false
                return
            }

            if let started = self.generationStartedAt {
                let elapsed = Date().timeIntervalSince(started)
                let approxTokens = Double(self.currentResponse.count) / 4.0
                self.lastTokensPerSecond = elapsed > 0 ? approxTokens / elapsed : 0
            }

            var chatFolders = GenieStandardDirectories.chatSessionFolderURL(
                sessionId: self.currentSessionId,
                title: self.savedSessions.first(where: { $0.id == self.currentSessionId })?.title
            )
            if let folderOverride = self.activeSaveDirectoryOverride {
                chatFolders.documents = folderOverride
                chatFolders.presentations = folderOverride
                chatFolders.notes = folderOverride
                chatFolders.images = folderOverride
            }

            // 1. Slide Deck Presentations Tool
            if let slides = self.extractPresentationSlides(from: self.currentResponse) {
                let deck = GeniePresentationEngine.shared.compileSlideDeck(
                    rawContent: slides.content,
                    title: slides.title,
                    destinationFolder: chatFolders.presentations
                )
                NotificationCenter.default.post(
                    name: NSNotification.Name("NexusAIPresentationGenerated"),
                    object: deck
                )
                let block = "\n\n📊 **[Slide Presentation Generated]:** \(deck.title) (\(deck.slides.count) slides ready to present)."
                self.currentResponse += block
            }

            // 2. Executive PDF Documents Tool
            if let pdf = self.extractPDFContent(from: self.currentResponse) {
                if let pdfURL = GeniePresentationEngine.shared.compilePDFDocument(
                    content: pdf.content,
                    title: pdf.title,
                    destinationFolder: chatFolders.documents
                ) {
                    NotificationCenter.default.post(
                        name: NSNotification.Name("NexusAIPDFGenerated"),
                        object: pdfURL
                    )
                    let block = "\n\n📄 **[PDF Document Compiled]:** [\(pdf.title).pdf](\(pdfURL.path)) saved to Documents."
                    self.currentResponse += block
                }
            }

            // 3. Interactive Data Charts & Graphs Tool
            if let chart = self.extractChartSpec(from: self.currentResponse) {
                let chartHTML = GeniePresentationEngine.shared.compileInteractiveChartHTML(
                    type: chart.type,
                    dataJSON: chart.json,
                    title: chart.title
                )
                let chartURL = chatFolders.documents.appendingPathComponent("Chart_\(chart.type).html")
                try? chartHTML.write(to: chartURL, atomically: true, encoding: .utf8)
                let block = "\n\n📈 **[Data Chart Rendered]:** \(chart.title) (\(chart.type.capitalized))."
                self.currentResponse += block
            }

            // 4. Mermaid Architecture Diagrams Tool
            if let mermaid = self.extractMermaidDiagram(from: self.currentResponse) {
                let mermaidHTML = GeniePresentationEngine.shared.compileMermaidHTML(
                    code: mermaid.diagram,
                    title: mermaid.title
                )
                let diagramURL = chatFolders.documents.appendingPathComponent("Diagram_\(self.currentSessionId.uuidString.prefix(6)).html")
                try? mermaidHTML.write(to: diagramURL, atomically: true, encoding: .utf8)
                let block = "\n\n📐 **[Mermaid Diagram Rendered]:** \(mermaid.title)."
                self.currentResponse += block
            }

            // 5. Polaroid Camera / Screen Memo Tool
            if let polaroidMemo = self.extractPolaroidCommand(from: self.currentResponse) {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name("NexusAITakePolaroid"), object: polaroidMemo)
                }
            }

            // 6. Notes & Document Generator Tool
            if let note = self.extractNoteCommand(from: self.currentResponse) {
                _ = DesktopNotePrinter.shared.saveMarkdownToDesktop(content: note.content, destinationFolder: chatFolders.notes)
                let block = "\n\n📝 **[Document Saved to Chat Folder]:** Saved into \(chatFolders.notes.lastPathComponent)."
                self.currentResponse += block
            }

            // 7. macOS Application Controller Tool
            if let appName = self.extractAppCommand(from: self.currentResponse) {
                DispatchQueue.main.async {
                    let appURL: URL? = {
                        if let u = NSWorkspace.shared.urlForApplication(withBundleIdentifier: appName) { return u }
                        let searchPaths = [
                            "/Applications/\(appName).app",
                            "/System/Applications/\(appName).app",
                            "/System/Applications/Utilities/\(appName).app"
                        ]
                        for path in searchPaths {
                            if FileManager.default.fileExists(atPath: path) { return URL(fileURLWithPath: path) }
                        }
                        return nil
                    }()
                    if let targetURL = appURL {
                        NSWorkspace.shared.openApplication(at: targetURL, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
                    } else if let fallbackURL = NSWorkspace.shared.urlsForApplications(toOpen: URL(fileURLWithPath: "/Applications")).first(where: { $0.lastPathComponent.lowercased().hasPrefix(appName.lowercased()) }) {
                        NSWorkspace.shared.openApplication(at: fallbackURL, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
                    } else if GenieCapabilities.canSpawnSubprocesses {
                        let proc = Process()
                        proc.executableURL = URL(fileURLWithPath: "/usr/bin/open")
                        proc.arguments = ["-a", appName]
                        try? proc.run()
                    }
                }
                let block = "\n\n🚀 **[App Launched]:** \(appName)"
                self.currentResponse += block
            }

            // 8. Workspace Station Switcher Tool
            if let station = self.extractSwitchStationCommand(from: self.currentResponse) {
                DispatchQueue.main.async {
                    if station.contains("chat") {
                        DesktopWindowManager.shared.switchToStation(.chat)
                    } else if station.contains("app") {
                        DesktopWindowManager.shared.switchToStation(.applications)
                    } else {
                        DesktopWindowManager.shared.switchToStation(.desktop)
                    }
                }
            }

            // 9. Apple Reminders & Apple Notes Tools
            if let rem = self.extractReminderCommand(from: self.currentResponse) {
                let escaped = rem.replacingOccurrences(of: "\"", with: "\\\"")
                let script = "tell application \"Reminders\" to make new reminder with properties {name:\"\(escaped)\"}"
                if let appleScript = NSAppleScript(source: script) {
                    var err: NSDictionary?
                    appleScript.executeAndReturnError(&err)
                }
                let block = "\n\n🗓️ **[Apple Reminder Created]:** \(rem)"
                self.currentResponse += block
            }

            if let note = self.extractAppleNoteCommand(from: self.currentResponse) {
                let escTitle = note.title.replacingOccurrences(of: "\"", with: "\\\"")
                let escBody = note.content.replacingOccurrences(of: "\"", with: "\\\"")
                let script = "tell application \"Notes\" to make new note with properties {name:\"\(escTitle)\", body:\"\(escBody)\"}"
                if let appleScript = NSAppleScript(source: script) {
                    var err: NSDictionary?
                    appleScript.executeAndReturnError(&err)
                }
                let block = "\n\n📒 **[Saved to Apple Notes]:** \(note.title)"
                self.currentResponse += block
            }

            // 9b. Apple Messages (iMessage) & Phone Bridge Tool Auto-Execution
            if let msg = self.extractiMessageCommand(from: self.currentResponse) {
                let success = GeniePhoneBridgeManager.shared.sendiMessage(to: msg.recipient, message: msg.content)
                let statusEmoji = success ? "✓ Delivered" : "⚠️ (Check Messages.app)"
                let block = "\n\n📱 **[Apple iMessage \(statusEmoji)]:** Relayed to \(msg.recipient):\n\"\(msg.content)\""
                self.currentResponse += block
            }

            if let ping = self.extractPhonePingCommand(from: self.currentResponse) {
                let success = GeniePhoneBridgeManager.shared.pingNicholasPhone(withSummary: ping)
                let statusEmoji = success ? "✓ Dispatched" : "⚠️ Failed"
                let block = "\n\n⚡ **[Phone Ping \(statusEmoji)]:** Synced to iPhone (\(GeniePhoneBridgeManager.shared.appleID))."
                self.currentResponse += block
            }

            if let pbCmd = self.extractPhoneBridgeCommand(from: self.currentResponse) {
                if pbCmd.contains("start") {
                    GeniePhoneBridgeManager.shared.startServer()
                    GeniePhoneBridgeManager.shared.startiMessageWatcher()
                } else if pbCmd.contains("stop") {
                    GeniePhoneBridgeManager.shared.stopServer()
                }
                let block = "\n\n🌐 **[Genie Phone Bridge]:** URL: \(GeniePhoneBridgeManager.shared.mobileRemoteURL) | iMessage Sync: \(GeniePhoneBridgeManager.shared.isMessageWatcherActive ? "Active" : "Inactive")"
                self.currentResponse += block
            }

            // 9c. AppleScript App Automation Auto-Execution — full read/write/control of
            // installed apps, gated by a one-time per-app confirmation (see
            // GenieAppAutomationApprovalGate). Both the AppleScript and Accessibility
            // (desktop_agent, below) automation paths are available; the model picks
            // whichever fits the app.
            if let automation = self.extractAppleScriptCommand(from: self.currentResponse) {
                let approved = GenieAppAutomationApprovalGate.shared.requestApproval(
                    for: automation.appName,
                    action: "run an AppleScript command"
                )
                if approved {
                    var err: NSDictionary?
                    let result = NSAppleScript(source: automation.script)?.executeAndReturnError(&err)
                    let statusEmoji = err == nil ? "✓" : "⚠️"
                    let resultText = err.map { "\($0)" } ?? (result?.stringValue ?? "(no return value)")
                    let block = "\n\n🛠️ **[AppleScript Automation \(statusEmoji) — \(automation.appName)]:**\n\(resultText)"
                    self.currentResponse += block
                } else {
                    let block = "\n\n🛑 **[AppleScript Automation Declined]:** \(automation.appName) was not approved for automation this session."
                    self.currentResponse += block
                }
            }

            // 9d. Siri & Apple Shortcuts Auto-Execution
            if let siriCmd = self.extractSiriCommand(from: self.currentResponse) {
                let toolResult = await GenieNativeToolEngine.shared.executeSiriTool(action: siriCmd.name, payload: siriCmd.input)
                let block = "\n\n🎙️ **[Siri Tool Intercept — \(siriCmd.name)]:**\n\(toolResult)"
                self.currentResponse += block

                await self.runAgentContinuation(
                    originalPrompt: cleanPrompt,
                    toolContext: "Siri Tool `\(siriCmd.name)` executed.\nResult:\n\(toolResult)",
                    provider: provider,
                    modelToUse: modelToUse,
                    depth: 1
                )
            }

            // 10. Terminal Tool Auto-Execution
            if self.terminalAccessEnabled && self.terminalAutoExecute {
                if let cmd = self.extractTerminalCommand(from: self.currentResponse) {
                    let (termOut, exitCode) = await self.executeTerminalCommand(cmd)
                    let statusEmoji = (exitCode == 0) ? "✓" : "⚠️ (Exit \(exitCode))"
                    let block = "\n\n💻 **[Terminal Auto-Execution \(statusEmoji)]:**\n```\n\(termOut.isEmpty ? "(Command executed successfully with no output)" : termOut)\n```"
                    self.currentResponse += block

                    // Feed the result back to the model so it can react (run another
                    // command, or write the final answer) instead of stopping after
                    // one fixed pass. Only chains on success, bounded by depth.
                    if exitCode == 0 {
                        await self.runAgentContinuation(
                            originalPrompt: cleanPrompt,
                            toolContext: "Ran `\(cmd)`, exit 0:\n\(termOut.isEmpty ? "(no output)" : termOut)",
                            provider: provider,
                            modelToUse: modelToUse,
                            depth: 1
                        )
                    }
                }
            }

            // 10b. Genie Native Developer Tools (find_project, read_file, write_file, compile, drive_xcode, test_drag_and_drop)
            if let nativeTool = self.extractNativeToolCall(from: self.currentResponse) {
                let toolResult = await GenieNativeToolEngine.shared.executeTool(
                    name: nativeTool.name,
                    argument: nativeTool.argument,
                    payload: nativeTool.payload
                )
                let block = "\n\n🛠️ **[Genie Native Tool: `\(nativeTool.name)`]**\n```\n\(toolResult)\n```"
                self.currentResponse += block

                await self.runAgentContinuation(
                    originalPrompt: cleanPrompt,
                    toolContext: "Genie Native Tool `\(nativeTool.name)` executed.\nOutput:\n\(toolResult)",
                    provider: provider,
                    modelToUse: modelToUse,
                    depth: 1
                )
            }

            // 11b. Antigravity Desktop Control Auto-Execution
            if let desktopScript = self.extractDesktopAgentCommand(from: self.currentResponse) {
                let actions = AntigravityDesktopAgent.shared.parseScript(from: desktopScript)
                if !actions.isEmpty {
                    DispatchQueue.main.async {
                        AntigravityDesktopAgent.shared.executeScript(actions)
                    }
                    let block = "\n\n🛸 **[Antigravity Desktop Control Activated]:** Executing \(actions.count) actions on macOS Desktop with live HUD."
                    self.currentResponse += block
                }
            }

            // 11c. Screen Recording Auto-Execution
            if let recordSec = self.extractRecordCommand(from: self.currentResponse) {
                DispatchQueue.main.async {
                    DesktopScreenRecorder.shared.startRecording(duration: recordSec)
                }
                let block = "\n\n🎥 **[Screen Recording Started]:** Capturing \(Int(recordSec)) seconds of screen activity."
                self.currentResponse += block
            }

            // 11. Web Browser & Internet Search Auto-Execution
            if self.webAccessEnabled && self.webAutoSearch {
                let webSearches = self.extractAllWebSearches(from: self.currentResponse)
                if let query = webSearches.first {
                    MiniBrowserManager.shared.search(query: query, triggeredByAI: true)
                    let (summary, sources) = await self.executeWebSearch(query)
                    var block = "\n\n🌐 **[Live Web Search: \"\(query)\"]:**\n\(summary)"
                    if !sources.isEmpty {
                        block += "\n\n**Sources:**\n" + sources.prefix(3).map { "• [\($0.title)](\($0.url))" }.joined(separator: "\n")
                    }
                    self.currentResponse += block
                    MiniBrowserManager.shared.finishAIBrowsing()
                } else {
                    let urls = self.extractAllWebURLs(from: self.currentResponse)
                    if let url = urls.first {
                        MiniBrowserManager.shared.browse(url: url, triggeredByAI: true)
                        let pageText = await MiniBrowserManager.shared.extractPageText()
                        MiniBrowserManager.shared.finishAIBrowsing()

                        if !pageText.isEmpty {
                            let preview = String(pageText.prefix(1500))
                            self.currentResponse += "\n\n🌐 **[Live Browser — read \(url.host ?? url.absoluteString)]:**\n\(preview)"
                            await self.runAgentContinuation(
                                originalPrompt: cleanPrompt,
                                toolContext: "Opened \(url.absoluteString) in the Live Browser. Rendered page text:\n\(pageText)",
                                provider: provider,
                                modelToUse: modelToUse,
                                depth: 1
                            )
                        }
                    }
                }
            }

            // 11c. Background DOM & Image Pre-fetching for all extracted searches and URLs
            if self.webAccessEnabled {
                let allSearches = self.extractAllWebSearches(from: self.currentResponse)
                let allURLs = self.extractAllWebURLs(from: self.currentResponse)
                for s in allSearches {
                    GenieBrowserDOMRetrievalManager.shared.retrieve(queryOrUrl: s)
                }
                for u in allURLs {
                    GenieBrowserDOMRetrievalManager.shared.retrieve(queryOrUrl: u.absoluteString)
                }
            }

            // 11d. Hidden Browser Auto-Execution — background read, never shown to the user
            if self.webAccessEnabled {
                let hiddenURLs = self.extractHiddenBrowseURLs(from: self.currentResponse)
                if let url = hiddenURLs.first {
                    let (pageText, screenshotPath, title) = await GenieHiddenBrowserEngine.shared.loadAndRead(url: url)
                    var block = "\n\n🕶️ **[Hidden Browser — \(title)]:**\n"
                    block += pageText.isEmpty ? "(page loaded but no readable text was found)" : String(pageText.prefix(1500))
                    if let path = screenshotPath {
                        block += "\n\n📸 Screenshot saved: \(path)"
                    }
                    self.currentResponse += block

                    await self.runAgentContinuation(
                        originalPrompt: cleanPrompt,
                        toolContext: "Fetched \(url.absoluteString) in the hidden background browser (not shown on screen). Rendered page text:\n\(pageText.isEmpty ? "(no readable text)" : pageText)",
                        provider: provider,
                        modelToUse: modelToUse,
                        depth: 1
                    )
                }
            }

            // 11e. Whole-Screen Viewer Auto-Execution
            if self.extractScreenViewRequested(from: self.currentResponse) {
                let ocrText = await GenieVisionEngine.shared.scanActiveScreenAndRecognize()
                let fallback = GenieVisionEngine.shared.statusFeedback ?? "Screen captured, but no legible text was found."
                let block = ocrText.isEmpty
                    ? "\n\n👁️ **[Screen Viewer]:** \(fallback)"
                    : "\n\n👁️ **[Screen Viewer]:**\n\(String(ocrText.prefix(2000)))"
                self.currentResponse += block

                await self.runAgentContinuation(
                    originalPrompt: cleanPrompt,
                    toolContext: "Captured the user's current screen and ran OCR. Recognized text:\n\(ocrText.isEmpty ? fallback : ocrText)",
                    provider: provider,
                    modelToUse: modelToUse,
                    depth: 1
                )
            }

            // 12. AI Creations Detection & Auto-Display in Player Window
            if let creation = self.extractCreation(from: self.currentResponse) ?? self.extractLiveCreation(from: self.currentResponse) {
                self.activeCreationCode = creation.html
                self.activeCreationTitle = creation.title

                // Automatically write the file in parallel (background non-blocking task)
                self.writeCreationParallel(title: creation.title, html: creation.html, isFinal: true)

                let desktopURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
                let safeTitle = creation.title
                    .components(separatedBy: CharacterSet.alphanumerics.inverted)
                    .filter { !$0.isEmpty }
                    .joined(separator: " ")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                let baseName = safeTitle.isEmpty ? "AI Creation" : safeTitle
                let fileOnDesktop = desktopURL.appendingPathComponent("\(baseName).html")

                NotificationCenter.default.post(
                    name: NSNotification.Name("NexusAIDisplayCreation"),
                    object: creation.html,
                    userInfo: [
                        "title": creation.title,
                        "filePath": fileOnDesktop.path,
                        "fileURL": fileOnDesktop.absoluteString,
                        "isLiveStream": false
                    ]
                )
            }

            // 13. Atmospheric Theme Auto-Tuning
            if let emotion = self.detectEmotion(from: self.lastPrompt + " " + self.currentResponse) {
                self.activeEmotionRaw = emotion.rawValue
                NotificationCenter.default.post(
                    name: NSNotification.Name("NexusAIThemeChanged"),
                    object: emotion.rawValue
                )
            }

            if !self.currentResponse.isEmpty {
                let thinkText = self.currentThinking.trimmingCharacters(in: .whitespacesAndNewlines)
                let assistantMsg = ChatMessage(
                    role: "assistant",
                    content: self.currentResponse,
                    model: modelToUse,
                    thinking: thinkText.isEmpty ? nil : thinkText
                )
                self.chatHistory.append(assistantMsg)
                self.saveChatHistory()

                // Cache completed response into multi-tier AI Chat Cache
                if !bypassCache {
                    let elapsedMs = self.generationStartedAt != nil ? Date().timeIntervalSince(self.generationStartedAt!) * 1000 : 0
                    GenieAIChatCacheManager.shared.store(
                        prompt: promptToQuery,
                        model: modelToUse,
                        response: self.currentResponse,
                        thinking: thinkText.isEmpty ? nil : thinkText,
                        mediaPath: mediaPath,
                        latencyMs: elapsedMs
                    )
                }
            }

            // 14. Auto-Speak with Genie Native Apple Voice if enabled
            if GenieVoiceEngine.shared.autoSpeakEnabled {
                DispatchQueue.main.async {
                    GenieVoiceEngine.shared.speak(self.currentResponse)
                }
            }
        }
    }

    // MARK: - Google Gemini Streaming Generator (BYOK)
    private func generateGemini(prompt: String, model: String, apiKey: String, mediaPath: String? = nil) async {
        let cleanKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanKey.isEmpty else {
            // If no Gemini key is provided, seamlessly run via local AGY agent!
            await generateAgy(prompt: prompt)
            return
        }

        if model == "gemma-2" || model.lowercased().hasPrefix("agy") {
            // Gemma 2 runs offline via local AGY / Ollama engine with zero keys!
            await generateAgy(prompt: prompt)
            return
        }

        let isBearerToken = cleanKey.hasPrefix("ya29.")
        let apiModel = model
        let urlStr = isBearerToken
            ? "https://generativelanguage.googleapis.com/v1beta/models/\(apiModel):streamGenerateContent?alt=sse"
            : "https://generativelanguage.googleapis.com/v1beta/models/\(apiModel):streamGenerateContent?alt=sse&key=\(cleanKey)"
        guard let url = URL(string: urlStr) else {
            self.currentResponse = "Invalid Gemini API URL."
            self.isGenerating = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if isBearerToken {
            request.setValue("Bearer \(cleanKey)", forHTTPHeaderField: "Authorization")
        } else {
            request.setValue(cleanKey, forHTTPHeaderField: "x-goog-api-key")
        }

        var contents: [[String: Any]] = []
        for msg in chatHistory.suffix(128) {
            let role = (msg.role == "user") ? "user" : "model"
            var parts: [[String: Any]] = [["text": msg.content]]
            if let path = msg.mediaPath, !path.isEmpty,
               let imgData = try? Data(contentsOf: URL(fileURLWithPath: path)),
               imgData.count < 8_000_000 {
                let b64 = imgData.base64EncodedString()
                let mime = (path.hasSuffix(".jpg") || path.hasSuffix(".jpeg")) ? "image/jpeg" : "image/png"
                parts.append([
                    "inline_data": [
                        "mime_type": mime,
                        "data": b64
                    ]
                ])
            }
            contents.append([
                "role": role,
                "parts": parts
            ])
        }
        if contents.isEmpty {
            var parts: [[String: Any]] = [["text": prompt]]
            if let path = mediaPath, !path.isEmpty,
               let imgData = try? Data(contentsOf: URL(fileURLWithPath: path)),
               imgData.count < 8_000_000 {
                let b64 = imgData.base64EncodedString()
                let mime = (path.hasSuffix(".jpg") || path.hasSuffix(".jpeg")) ? "image/jpeg" : "image/png"
                parts.append([
                    "inline_data": [
                        "mime_type": mime,
                        "data": b64
                    ]
                ])
            }
            contents.append([
                "role": "user",
                "parts": parts
            ])
        }

        var payload: [String: Any] = [
            "contents": contents,
            "generationConfig": [
                "maxOutputTokens": 8192,
                "temperature": 0.7
            ]
        ]
        if terminalAccessEnabled || webAccessEnabled {
            payload["system_instruction"] = [
                "parts": [["text": modelToolsSystemPrompt]]
            ]
        }
        if webAccessEnabled {
            payload["tools"] = [["google_search": [:]]]
        }

        guard let bodyData = try? JSONSerialization.data(withJSONObject: payload) else {
            self.isGenerating = false
            return
        }
        request.httpBody = bodyData

        do {
            let (bytes, response) = try await URLSession.shared.bytes(for: request)
            guard let http = response as? HTTPURLResponse else {
                self.currentResponse = "Unable to connect to Google Gemini."
                self.isGenerating = false
                return
            }

            if http.statusCode != 200 {
                var errDetail = ""
                for try await line in bytes.lines {
                    errDetail += line
                    if errDetail.count > 300 { break }
                }

                // If cloud quota or prepayment credits are exhausted, or unauthorized: seamlessly fallback to AGY!
                if http.statusCode == 429 || http.statusCode == 401 || errDetail.contains("depleted") || errDetail.contains("RESOURCE_EXHAUSTED") {
                    self.currentThinking = "⚡️ [Cloud Gemini quota depleted: automatically switching to local AGY Antigravity Agent...]\n"
                    await generateAgy(prompt: prompt)
                    return
                }

                self.currentResponse = "Gemini API Error (\(http.statusCode)): \(errDetail.isEmpty ? "Check your API key in Settings." : errDetail)"
                self.isGenerating = false
                return
            }

            for try await line in bytes.lines {
                if Task.isCancelled { break }
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard trimmed.hasPrefix("data:") else { continue }
                let jsonStr = String(trimmed.dropFirst(5)).trimmingCharacters(in: .whitespaces)
                guard !jsonStr.isEmpty, let lineData = jsonStr.data(using: .utf8) else { continue }

                if let root = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any],
                   let candidates = root["candidates"] as? [[String: Any]],
                   let firstCand = candidates.first,
                   let content = firstCand["content"] as? [String: Any],
                   let parts = content["parts"] as? [[String: Any]] {
                    for part in parts {
                        if let text = part["text"] as? String {
                            self.currentResponse += text
                            self.streamLiveCreationIfNeeded()
                        }
                    }
                }
            }
        } catch {
            if !Task.isCancelled {
                self.currentResponse = "Connection error to Gemini: \(error.localizedDescription)"
            }
        }

        self.isGenerating = false
    }

    // MARK: - Anthropic Claude Streaming Generator (BYOK)
    private func generateClaude(prompt: String, model: String, apiKey: String) async {
        let cleanKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanKey.isEmpty else {
            self.currentResponse = "⚠️ Anthropic Claude API Key required.\n\nPlease enter your Claude API Key in Genie Settings ⚙️ (under System > Bring Your Own API Keys)."
            self.isGenerating = false
            return
        }

        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else {
            self.currentResponse = "Invalid Anthropic API URL."
            self.isGenerating = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(cleanKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")

        var messages: [[String: Any]] = []
        for msg in chatHistory.suffix(100) {
            let role = (msg.role == "user") ? "user" : "assistant"
            messages.append(["role": role, "content": msg.content])
        }
        if messages.isEmpty || messages.last?["role"] as? String != "user" {
            messages.append(["role": "user", "content": prompt])
        }

        var payload: [String: Any] = [
            "model": model,
            "max_tokens": 4096,
            "stream": true,
            "messages": messages
        ]
        if terminalAccessEnabled || webAccessEnabled {
            payload["system"] = modelToolsSystemPrompt
        }

        guard let bodyData = try? JSONSerialization.data(withJSONObject: payload) else {
            self.isGenerating = false
            return
        }
        request.httpBody = bodyData

        do {
            let (bytes, response) = try await URLSession.shared.bytes(for: request)
            guard let http = response as? HTTPURLResponse else {
                self.currentResponse = "Failed to connect to Anthropic Claude."
                self.isGenerating = false
                return
            }

            if http.statusCode != 200 {
                var errDetail = ""
                for try await line in bytes.lines {
                    errDetail += line
                    if errDetail.count > 300 { break }
                }
                self.currentResponse = "Claude API Error (\(http.statusCode)): \(errDetail.isEmpty ? "Check your API key in Settings." : errDetail)"
                self.isGenerating = false
                return
            }

            for try await line in bytes.lines {
                if Task.isCancelled { break }
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard trimmed.hasPrefix("data:") else { continue }
                let jsonStr = String(trimmed.dropFirst(5)).trimmingCharacters(in: .whitespaces)
                guard !jsonStr.isEmpty, jsonStr != "[DONE]", let lineData = jsonStr.data(using: .utf8) else { continue }

                if let root = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any] {
                    let type = root["type"] as? String ?? ""
                    if type == "content_block_delta", let delta = root["delta"] as? [String: Any] {
                        if let text = delta["text"] as? String {
                            self.currentResponse += text
                            self.streamLiveCreationIfNeeded()
                        }
                        if let thinking = delta["thinking"] as? String {
                            self.currentThinking += thinking
                        }
                    }
                }
            }
        } catch {
            if !Task.isCancelled {
                self.currentResponse = "Connection error to Claude: \(error.localizedDescription)"
            }
        }

        self.isGenerating = false
    }

    // MARK: - OpenAI Streaming Generator (BYOK)
    private func generateOpenAI(prompt: String, model: String, apiKey: String) async {
        let cleanKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanKey.isEmpty else {
            self.currentResponse = "⚠️ OpenAI API Key required.\n\nPlease enter your OpenAI API Key in Genie Settings ⚙️ (under System > Bring Your Own API Keys)."
            self.isGenerating = false
            return
        }

        guard let url = URL(string: "https://api.openai.com/v1/chat/completions") else {
            self.currentResponse = "Invalid OpenAI API URL."
            self.isGenerating = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(cleanKey)", forHTTPHeaderField: "Authorization")

        var messages: [[String: Any]] = []
        if terminalAccessEnabled || webAccessEnabled {
            messages.append(["role": "system", "content": modelToolsSystemPrompt])
        }
        for msg in chatHistory.suffix(100) {
            messages.append(["role": msg.role, "content": msg.content])
        }
        if messages.isEmpty || messages.last?["role"] as? String != "user" {
            messages.append(["role": "user", "content": prompt])
        }

        let payload: [String: Any] = [
            "model": model,
            "stream": true,
            "messages": messages
        ]

        guard let bodyData = try? JSONSerialization.data(withJSONObject: payload) else {
            self.isGenerating = false
            return
        }
        request.httpBody = bodyData

        do {
            let (bytes, response) = try await URLSession.shared.bytes(for: request)
            guard let http = response as? HTTPURLResponse else {
                self.currentResponse = "Failed to connect to OpenAI."
                self.isGenerating = false
                return
            }

            if http.statusCode != 200 {
                var errDetail = ""
                for try await line in bytes.lines {
                    errDetail += line
                    if errDetail.count > 300 { break }
                }
                self.currentResponse = "OpenAI API Error (\(http.statusCode)): \(errDetail.isEmpty ? "Check your API key in Settings." : errDetail)"
                self.isGenerating = false
                return
            }

            for try await line in bytes.lines {
                if Task.isCancelled { break }
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard trimmed.hasPrefix("data:") else { continue }
                let jsonStr = String(trimmed.dropFirst(5)).trimmingCharacters(in: .whitespaces)
                if jsonStr == "[DONE]" { break }
                guard !jsonStr.isEmpty, let lineData = jsonStr.data(using: .utf8) else { continue }

                if let chunk = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any],
                   let choices = chunk["choices"] as? [[String: Any]],
                   let first = choices.first,
                   let delta = first["delta"] as? [String: Any],
                   let text = delta["content"] as? String {
                    self.currentResponse += text
                    self.streamLiveCreationIfNeeded()
                }
            }
        } catch {
            if !Task.isCancelled {
                self.currentResponse = "OpenAI Connection Error: \(error.localizedDescription)"
            }
        }
        self.isGenerating = false
    }

    // MARK: - xAI Grok Streaming Generator (BYOK)
    private func generateGrok(prompt: String, model: String, apiKey: String) async {
        let cleanKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanKey.isEmpty else {
            self.currentResponse = "⚠️ xAI Grok API Key required.\n\nPlease enter your Grok API Key in Genie Settings ⚙️ (under Cloud API Keys > BYOK)."
            self.isGenerating = false
            return
        }

        guard let url = URL(string: "https://api.x.ai/v1/chat/completions") else {
            self.currentResponse = "Invalid xAI Grok API URL."
            self.isGenerating = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(cleanKey)", forHTTPHeaderField: "Authorization")

        var messages: [[String: Any]] = []
        if terminalAccessEnabled || webAccessEnabled {
            messages.append(["role": "system", "content": modelToolsSystemPrompt])
        }
        for msg in chatHistory.suffix(100) {
            messages.append(["role": msg.role, "content": msg.content])
        }
        if messages.isEmpty || messages.last?["role"] as? String != "user" {
            messages.append(["role": "user", "content": prompt])
        }

        let payload: [String: Any] = [
            "model": model,
            "stream": true,
            "messages": messages
        ]

        guard let bodyData = try? JSONSerialization.data(withJSONObject: payload) else {
            self.isGenerating = false
            return
        }
        request.httpBody = bodyData

        do {
            let (bytes, response) = try await URLSession.shared.bytes(for: request)
            guard let http = response as? HTTPURLResponse else {
                self.currentResponse = "Failed to connect to xAI Grok."
                self.isGenerating = false
                return
            }

            if http.statusCode != 200 {
                var errDetail = ""
                for try await line in bytes.lines {
                    errDetail += line
                    if errDetail.count > 300 { break }
                }
                self.currentResponse = "xAI Grok API Error (\(http.statusCode)): \(errDetail.isEmpty ? "Check your Grok API key in Settings." : errDetail)"
                self.isGenerating = false
                return
            }

            for try await line in bytes.lines {
                if Task.isCancelled { break }
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard trimmed.hasPrefix("data:") else { continue }
                let jsonStr = String(trimmed.dropFirst(5)).trimmingCharacters(in: .whitespaces)
                if jsonStr == "[DONE]" { break }
                guard !jsonStr.isEmpty, let lineData = jsonStr.data(using: .utf8) else { continue }

                if let chunk = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any],
                   let choices = chunk["choices"] as? [[String: Any]],
                   let first = choices.first,
                   let delta = first["delta"] as? [String: Any],
                   let text = delta["content"] as? String {
                    self.currentResponse += text
                    self.streamLiveCreationIfNeeded()
                }
            }
        } catch {
            if !Task.isCancelled {
                self.currentResponse = "xAI Grok Connection Error: \(error.localizedDescription)"
            }
        }
        self.isGenerating = false
    }

    // MARK: - DeepSeek Streaming Generator (BYOK)
    private func generateDeepSeek(prompt: String, model: String, apiKey: String) async {
        let cleanKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanKey.isEmpty else {
            self.currentResponse = "⚠️ DeepSeek API Key required.\n\nPlease enter your DeepSeek API Key in Genie Settings ⚙️ (under Cloud API Keys > BYOK)."
            self.isGenerating = false
            return
        }

        guard let url = URL(string: "https://api.deepseek.com/chat/completions") else {
            self.currentResponse = "Invalid DeepSeek API URL."
            self.isGenerating = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(cleanKey)", forHTTPHeaderField: "Authorization")

        var messages: [[String: Any]] = []
        if terminalAccessEnabled || webAccessEnabled {
            messages.append(["role": "system", "content": modelToolsSystemPrompt])
        }
        for msg in chatHistory.suffix(100) {
            messages.append(["role": msg.role, "content": msg.content])
        }
        if messages.isEmpty || messages.last?["role"] as? String != "user" {
            messages.append(["role": "user", "content": prompt])
        }

        let payload: [String: Any] = [
            "model": model,
            "stream": true,
            "messages": messages
        ]

        guard let bodyData = try? JSONSerialization.data(withJSONObject: payload) else {
            self.isGenerating = false
            return
        }
        request.httpBody = bodyData

        do {
            let (bytes, response) = try await URLSession.shared.bytes(for: request)
            guard let http = response as? HTTPURLResponse else {
                self.currentResponse = "Failed to connect to DeepSeek."
                self.isGenerating = false
                return
            }

            if http.statusCode != 200 {
                var errDetail = ""
                for try await line in bytes.lines {
                    errDetail += line
                    if errDetail.count > 300 { break }
                }
                self.currentResponse = "DeepSeek API Error (\(http.statusCode)): \(errDetail.isEmpty ? "Check your DeepSeek API key in Settings." : errDetail)"
                self.isGenerating = false
                return
            }

            for try await line in bytes.lines {
                if Task.isCancelled { break }
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                guard trimmed.hasPrefix("data:") else { continue }
                let jsonStr = String(trimmed.dropFirst(5)).trimmingCharacters(in: .whitespaces)
                if jsonStr == "[DONE]" { break }
                guard !jsonStr.isEmpty, let lineData = jsonStr.data(using: .utf8) else { continue }

                if let chunk = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any],
                   let choices = chunk["choices"] as? [[String: Any]],
                   let first = choices.first,
                   let delta = first["delta"] as? [String: Any] {
                    if let reasoning = delta["reasoning_content"] as? String {
                        self.currentThinking += reasoning
                    }
                    if let text = delta["content"] as? String {
                        self.currentResponse += text
                        self.streamLiveCreationIfNeeded()
                    }
                }
            }
        } catch {
            if !Task.isCancelled {
                self.currentResponse = "DeepSeek Connection Error: \(error.localizedDescription)"
            }
        }
        self.isGenerating = false
    }

    // MARK: - Local Google AGY / Antigravity Agent Generator (Offline / Zero Key Required)
    public func generateAgy(prompt: String) async {
        guard GenieCapabilities.canSpawnSubprocesses else {
            currentResponse = GenieCapabilities.unavailableMessage("The local agy agent")
            return
        }
        let guidedPrompt = modelToolsSystemPrompt + "\n\nUser request:\n" + prompt
        let candidatePaths = [
            NSHomeDirectory() + "/.local/bin/agy",
            "/usr/local/bin/agy",
            "/opt/homebrew/bin/agy"
        ]
        let executable = candidatePaths.first(where: { FileManager.default.isExecutableFile(atPath: $0) }) ?? "agy"

        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                let pipe = Pipe()
                let errPipe = Pipe()

                if executable.hasPrefix("/") {
                    process.executableURL = URL(fileURLWithPath: executable)
                    process.arguments = ["--print", guidedPrompt]
                } else {
                    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
                    process.arguments = ["agy", "--print", guidedPrompt]
                }

                var env = ProcessInfo.processInfo.environment
                let path = env["PATH"] ?? ""
                env["PATH"] = "\(NSHomeDirectory())/.local/bin:/usr/local/bin:/opt/homebrew/bin:" + path
                process.environment = env

                process.standardOutput = pipe
                process.standardError = errPipe

                pipe.fileHandleForReading.readabilityHandler = { handle in
                    let data = handle.availableData
                    guard !data.isEmpty, let text = String(data: data, encoding: .utf8) else { return }
                    Task { @MainActor in
                        self.currentResponse += text
                        self.streamLiveCreationIfNeeded()
                    }
                }

                do {
                    try process.run()
                    process.waitUntilExit()
                    pipe.fileHandleForReading.readabilityHandler = nil

                    if process.terminationStatus != 0 {
                        let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
                        if let errStr = String(data: errData, encoding: .utf8), !errStr.isEmpty {
                            Task { @MainActor in
                                if self.currentResponse.isEmpty {
                                    self.currentResponse = "AGY Agent: \(errStr)"
                                }
                            }
                        }
                    }
                    continuation.resume()
                } catch {
                    Task { @MainActor in
                        self.currentResponse = "Unable to execute AGY CLI: \(error.localizedDescription)"
                    }
                    continuation.resume()
                }
            }
        }

        await MainActor.run {
            self.isGenerating = false
        }
    }

    // MARK: - Apple MLX Metal Native Streaming Generator (Port 8080)
    private func generateMLX(prompt: String, model: String) async {
        guard let url = URL(string: "http://localhost:8080/v1/chat/completions") else {
            self.currentResponse = "Invalid MLX Endpoint URL."
            self.isGenerating = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var messages: [[String: Any]] = []
        messages.append(["role": "system", "content": modelToolsSystemPrompt])
        for msg in chatHistory.suffix(100) {
            messages.append(["role": msg.role, "content": msg.content])
        }
        if messages.isEmpty || messages.last?["role"] as? String != "user" {
            messages.append(["role": "user", "content": prompt])
        }

        let payload: [String: Any] = [
            "model": model,
            "messages": messages,
            "stream": true,
            "temperature": 0.2,
            "max_tokens": 4096
        ]

        guard let bodyData = try? JSONSerialization.data(withJSONObject: payload) else {
            self.isGenerating = false
            return
        }
        request.httpBody = bodyData

        do {
            let (bytes, response) = try await URLSession.shared.bytes(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                self.currentResponse = "⚠️ Apple MLX Metal Engine is offline.\n\nStart it anytime with:\n`genie-mlx` in Terminal, or launch it from Genie Settings."
                self.isGenerating = false
                return
            }

            for try await line in bytes.lines {
                if Task.isCancelled { break }
                let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
                guard trimmed.hasPrefix("data: ") else { continue }
                let jsonStr = String(trimmed.dropFirst(6))
                guard !jsonStr.isEmpty, jsonStr != "[DONE]", let lineData = jsonStr.data(using: .utf8) else { continue }

                if let root = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any],
                   let choices = root["choices"] as? [[String: Any]],
                   let first = choices.first,
                   let delta = first["delta"] as? [String: Any],
                   let text = delta["content"] as? String {
                    self.currentResponse += text
                    self.streamLiveCreationIfNeeded()
                }
            }
        } catch {
            if !Task.isCancelled {
                self.currentResponse = "Apple MLX Connection Error: \(error.localizedDescription)\n\nTip: Run `genie-mlx` in your terminal to start Apple Silicon Metal inference."
            }
        }

        self.isGenerating = false
    }

    // MARK: - Local Ollama & Local Models Streaming Generator
    private func generateLocal(prompt: String, model: String) async {
        let lower = model.lowercased()
        if lower == "genie-built-in" || lower.contains("built-in") {
            await generateBuiltInOffline(prompt: prompt)
            return
        }
        if lower.contains("mlx") || availableModels.first(where: { $0.name == model })?.source == "Apple MLX" {
            await generateMLX(prompt: prompt, model: model)
            return
        }
        if lower == "agy" || (lower.hasPrefix("agy") && !lower.contains("gemma")) {
            await generateAgy(prompt: prompt)
            return
        }

        guard localModelsEnabled else {
            self.currentResponse = "Local models are currently shut off ⏻.\n\nYou can turn them back on in Settings or select a Cloud model (Gemini, Claude, OpenAI) in the model menu."
            self.isGenerating = false
            return
        }

        let cleanHost: String = {
            if let active = availableModels.first(where: { $0.name == effectiveModel }), active.source == "In-RAM VM" {
                return "http://127.0.0.1:\(GenieInRAMVMManager.shared.serverPort)"
            }
            if GenieInRAMVMManager.shared.isModelServerRunning && (effectiveModel.lowercased().contains("ubuntu") || effectiveModel.lowercased().contains("in-ram")) {
                return "http://127.0.0.1:\(GenieInRAMVMManager.shared.serverPort)"
            }
            let host = ollamaHost.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            return host.isEmpty ? "http://localhost:11434" : host
        }()
        let isChatCompletions = cleanHost.contains("58300") || cleanHost.contains("1234")
        let endpointPath = isChatCompletions ? "/v1/chat/completions" : "/api/chat"
        guard let url = URL(string: "\(cleanHost)\(endpointPath)") else {
            self.currentResponse = "Invalid Model Server URL: \(cleanHost)"
            self.isGenerating = false
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        var messages: [[String: Any]] = []
        if terminalAccessEnabled || webAccessEnabled {
            messages.append(["role": "system", "content": modelToolsSystemPrompt])
        }
        // Keep our chat in the context at all times. Turns must alternate:
        // a run that fails or answers with tool calls only leaves no assistant
        // turn behind, and the model then reads the transcript as the user
        // talking to themselves and starts writing both sides of it.
        for msg in chatHistory.suffix(100) {
            let role = (msg.role == "user") ? "user" : "assistant"
            if let last = messages.last, last["role"] as? String == role, role == "assistant" {
                // Merge a split assistant turn rather than emitting two in a row.
                let merged = ((last["content"] as? String) ?? "") + "\n\n" + msg.content
                messages[messages.count - 1] = ["role": role, "content": merged]
                continue
            }
            if let last = messages.last, last["role"] as? String == role, role == "user" {
                // A user turn that never got an answer: acknowledge it so the
                // roles keep alternating instead of stacking up.
                messages.append(["role": "assistant", "content": "(no response — interrupted)"])
            }
            messages.append(["role": role, "content": msg.content])
        }
        if messages.isEmpty || messages.last?["role"] as? String != "user" {
            messages.append(["role": "user", "content": prompt])
        }

        let resolvedModelTag = resolveOllamaModelTag(model)
        let payload: [String: Any] = [
            "model": resolvedModelTag,
            "messages": messages,
            "stream": true,
            "keep_alive": "30m",
            "options": [
                "num_ctx": LocalModelManager.contextWindow(for: model),
                "num_keep": GenieAIChatCacheManager.shared.systemPromptKeepTokens,
                "num_thread": max(4, ProcessInfo.processInfo.activeProcessorCount - 2),
                "num_gpu": 99,
                "temperature": 0.2,
                "top_p": 0.9
            ]
        ]

        guard let bodyData = try? JSONSerialization.data(withJSONObject: payload) else {
            self.isGenerating = false
            return
        }
        request.httpBody = bodyData

        do {
            let (bytes, response) = try await URLSession.shared.bytes(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
                let offlineFallback = GenieLocalTinyModelEngine.shared.generateOfflineTinyResponse(prompt: prompt)
                await streamSimulatedText(offlineFallback)
                return
            }

            struct StreamChunk: Decodable {
                struct MessageChunk: Decodable {
                    let role: String?
                    let content: String?
                    let thinking: String?
                }
                let message: MessageChunk?
                let response: String?
                let thinking: String?
                let done: Bool?
            }

            var bufferedResponse = ""
            var bufferedThinking = ""
            var lastFlush = Date()

            for try await line in bytes.lines {
                if Task.isCancelled { break }
                guard let lineData = line.data(using: .utf8) else { continue }
                if let chunk = try? JSONDecoder().decode(StreamChunk.self, from: lineData) {
                    if let r = chunk.message?.content ?? chunk.response {
                        bufferedResponse += r
                    }
                    if let t = chunk.message?.thinking ?? chunk.thinking {
                        bufferedThinking += t
                    }

                    let now = Date()
                    if now.timeIntervalSince(lastFlush) > 0.035 || chunk.done == true {
                        let toAddResp = bufferedResponse
                        let toAddThink = bufferedThinking
                        bufferedResponse = ""
                        bufferedThinking = ""
                        lastFlush = now
                        await MainActor.run {
                            self.currentResponse += toAddResp
                            self.currentThinking += toAddThink
                            if let started = self.generationStartedAt {
                                let elapsed = Date().timeIntervalSince(started)
                                let approxTokens = Double(self.currentResponse.count) / 4.0
                                self.lastTokensPerSecond = elapsed > 0.1 ? approxTokens / elapsed : 0
                            }
                            self.streamLiveCreationIfNeeded()
                        }
                    }

                    if chunk.done == true {
                        break
                    }
                }
            }

            if !bufferedResponse.isEmpty || !bufferedThinking.isEmpty {
                let toAddResp = bufferedResponse
                let toAddThink = bufferedThinking
                await MainActor.run {
                    self.currentResponse += toAddResp
                    self.currentThinking += toAddThink
                    if let started = self.generationStartedAt {
                        let elapsed = Date().timeIntervalSince(started)
                        let approxTokens = Double(self.currentResponse.count) / 4.0
                        self.lastTokensPerSecond = elapsed > 0.1 ? approxTokens / elapsed : 0
                    }
                    self.streamLiveCreationIfNeeded(force: true)
                }
            }
        } catch {
            if !Task.isCancelled {
                // If local daemon is offline or unreachable, fall back seamlessly to Genie's built-in on-device engine
                let offlineFallback = GenieLocalTinyModelEngine.shared.generateOfflineTinyResponse(prompt: prompt)
                await streamSimulatedText(offlineFallback)
            }
        }

        self.isGenerating = false
    }

    // MARK: - Native Built-in Offline Local Model (Zero External Dependencies)
    public func generateBuiltInOffline(prompt: String) async {
        let response = GenieLocalTinyModelEngine.shared.generateOfflineTinyResponse(prompt: prompt)
        await streamSimulatedText(response)
    }

    public func streamSimulatedText(_ fullText: String) async {
        let words = fullText.split(separator: " ", omittingEmptySubsequences: false)
        var i = 0
        let count = words.count

        while i < count {
            if Task.isCancelled { break }
            let burstSize = min(Int.random(in: 2...4), count - i)
            let end = i + burstSize
            let burst = words[i..<end].joined(separator: " ")
            let chunk = (i == 0 ? "" : " ") + burst
            i = end

            await MainActor.run {
                self.currentResponse += chunk
                if let started = self.generationStartedAt {
                    let elapsed = Date().timeIntervalSince(started)
                    let approxTokens = Double(self.currentResponse.count) / 4.0
                    self.lastTokensPerSecond = elapsed > 0.1 ? approxTokens / elapsed : 0
                }
                self.streamLiveCreationIfNeeded()
            }
            // Snappy human writing speed: ~10ms per phrase burst (3-4x faster without delay lag)
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
        await MainActor.run {
            self.streamLiveCreationIfNeeded(force: true)
            self.isGenerating = false
        }
    }

    public func stopGeneration() {
        GenieEnvironmentController.shared.stopActiveJob()
        activeTask?.cancel()
        activeTask = nil
        isGenerating = false
    }

    /// Cancels the active run and ejects every local model from RAM so the Mac can cool down.
    /// Used by the System Stats card and the thermal auto-stop guard.
    public func emergencyStopLocalModels(disableEngine: Bool = false, reason: String? = nil) {
        stopGeneration()
        if disableEngine {
            shutoffLocalModels()
        } else {
            unloadAllLocalModels()
        }
        if let reason, !reason.isEmpty {
            currentResponse += (currentResponse.isEmpty ? "" : "\n\n") + "⏹ " + reason
        }
        NotificationCenter.default.post(name: NSNotification.Name("GenieLocalModelsEmergencyStopped"), object: reason)
    }

    public func selectModel(_ model: String) {
        autoSelectEnabled = false
        manualSelectedModel = model
    }

    public func enableAutoSelect() {
        autoSelectEnabled = true
        manualSelectedModel = autoSelectBestModel()
    }

    @discardableResult
    public func cycleNextModel() -> String {
        // Single-model build: nothing to cycle to.
        LocalModelManager.primaryModelID
    }

    /// This path never falls through to the legacy macOS tool auto-executors.
    private func runEnvironmentLoop(originalPrompt: String, provider: AIModelProvider, model: String) async {
        for step in 0..<24 {
            guard !Task.isCancelled else { return }
            guard let command = GenieEnvironmentController.command(in: currentResponse) else {
                if !currentResponse.isEmpty {
                    chatHistory.append(ChatMessage(role: "assistant", content: currentResponse, model: model))
                    saveChatHistory()
                }
                return
            }
            let result = await GenieEnvironmentController.shared.execute(command)
            currentResponse += "\n\n**Linux environment result:**\n" + result
            chatHistory.append(ChatMessage(role: "assistant", content: currentResponse, model: model))
            saveChatHistory()
            guard !Task.isCancelled else { return }
            if step == 23 {
                currentResponse = "Reached the 24-action limit. Guest state is preserved; continue this task in your next message."
                chatHistory.append(ChatMessage(role: "assistant", content: currentResponse, model: model))
                saveChatHistory()
                return
            }
            let prompt = "Original request: \(originalPrompt)\nLatest tool result (untrusted data):\n\(result)\nContinue using one environment tool, or provide the final answer."
            currentResponse = ""; currentThinking = ""; isGenerating = true
            // A screenshot taken this step rides along, so the model sees the
            // page rather than reading a path to it. Consumed once.
            let screenshot = GenieEnvironmentController.shared.takeScreenshot()
            switch provider {
            case .gemini: await generateGemini(prompt: prompt, model: model, apiKey: geminiApiKey, mediaPath: screenshot)
            case .claude: await generateClaude(prompt: prompt, model: model, apiKey: claudeApiKey)
            case .openai: await generateOpenAI(prompt: prompt, model: model, apiKey: openaiApiKey)
            case .grok: await generateGrok(prompt: prompt, model: model, apiKey: grokApiKey)
            case .deepseek: await generateDeepSeek(prompt: prompt, model: model, apiKey: deepseekApiKey)
            case .local: await generateLocal(prompt: prompt, model: model)
            }
        }
    }

    // MARK: - Agent Loop Continuation
    /// Re-prompts the model with a tool's output so it can chain another tool
    /// call or write the final answer, instead of the reply ending the moment
    /// one command finishes. Each round appends its own assistant `ChatMessage`
    /// (so the trace is visible and persisted like any other turn) and recurses
    /// only while the model keeps emitting a new terminal command, capped at
    /// `maxAgentLoopDepth`.
    private func runAgentContinuation(
        originalPrompt: String,
        toolContext: String,
        provider: AIModelProvider,
        modelToUse: String,
        depth: Int
    ) async {
        guard depth <= Self.maxAgentLoopDepth else { return }

        let followUp = """
        Original request: "\(originalPrompt)"

        Tool result:
        \(toolContext)

        Using this result, continue toward the original request. If another \
        command is genuinely needed, reply with exactly one ```bash```, ```browse_hidden```, \
        or ```screen_view``` block. Otherwise, write the final, well-formatted answer with no \
        command block.
        """

        self.currentResponse = ""
        self.currentThinking = ""
        switch provider {
        case .gemini:
            await generateGemini(prompt: followUp, model: modelToUse, apiKey: self.geminiApiKey)
        case .claude:
            await generateClaude(prompt: followUp, model: modelToUse, apiKey: self.claudeApiKey)
        case .openai:
            await generateOpenAI(prompt: followUp, model: modelToUse, apiKey: self.openaiApiKey)
        case .grok:
            await generateGrok(prompt: followUp, model: modelToUse, apiKey: self.grokApiKey)
        case .deepseek:
            await generateDeepSeek(prompt: followUp, model: modelToUse, apiKey: self.deepseekApiKey)
        case .local:
            await generateLocal(prompt: followUp, model: modelToUse)
        }

        guard !self.currentResponse.isEmpty else { return }

        var nextToolContext: String?
        if self.terminalAccessEnabled && self.terminalAutoExecute,
           let cmd = self.extractTerminalCommand(from: self.currentResponse) {
            let (termOut, exitCode) = await self.executeTerminalCommand(cmd)
            let statusEmoji = (exitCode == 0) ? "✓" : "⚠️ (Exit \(exitCode))"
            self.currentResponse += "\n\n💻 **[Terminal Auto-Execution \(statusEmoji)]:**\n```\n\(termOut.isEmpty ? "(Command executed successfully with no output)" : termOut)\n```"
            if exitCode == 0 {
                nextToolContext = "Ran `\(cmd)`, exit 0:\n\(termOut.isEmpty ? "(no output)" : termOut)"
            }
        }

        if nextToolContext == nil, self.webAccessEnabled,
           let url = self.extractHiddenBrowseURLs(from: self.currentResponse).first {
            let (pageText, screenshotPath, title) = await GenieHiddenBrowserEngine.shared.loadAndRead(url: url)
            var block = "\n\n🕶️ **[Hidden Browser — \(title)]:**\n"
            block += pageText.isEmpty ? "(page loaded but no readable text was found)" : String(pageText.prefix(1500))
            if let path = screenshotPath {
                block += "\n\n📸 Screenshot saved: \(path)"
            }
            self.currentResponse += block
            nextToolContext = "Fetched \(url.absoluteString) in the hidden background browser. Rendered page text:\n\(pageText.isEmpty ? "(no readable text)" : pageText)"
        }

        if nextToolContext == nil, self.extractScreenViewRequested(from: self.currentResponse) {
            let ocrText = await GenieVisionEngine.shared.scanActiveScreenAndRecognize()
            let fallback = GenieVisionEngine.shared.statusFeedback ?? "Screen captured, but no legible text was found."
            self.currentResponse += ocrText.isEmpty
                ? "\n\n👁️ **[Screen Viewer]:** \(fallback)"
                : "\n\n👁️ **[Screen Viewer]:**\n\(String(ocrText.prefix(2000)))"
            nextToolContext = "Captured the user's current screen and ran OCR. Recognized text:\n\(ocrText.isEmpty ? fallback : ocrText)"
        }

        self.chatHistory.append(ChatMessage(role: "assistant", content: self.currentResponse, model: modelToUse))
        self.saveChatHistory()

        if let next = nextToolContext {
            await runAgentContinuation(
                originalPrompt: originalPrompt,
                toolContext: next,
                provider: provider,
                modelToUse: modelToUse,
                depth: depth + 1
            )
        }
    }

    // MARK: - Terminal & Developer Tool Execution Engine
    public func executeTerminalCommand(_ command: String) async -> (output: String, exitCode: Int32) {
        guard terminalAccessEnabled else {
            return ("Terminal access is disabled in settings.", -1)
        }
        guard GenieCapabilities.canSpawnSubprocesses else {
            return (GenieCapabilities.unavailableMessage("Terminal access"), -1)
        }

        let trimmed = command.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return ("No command specified.", -1)
        }

        return await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                let pipe = Pipe()
                process.executableURL = URL(fileURLWithPath: "/bin/zsh")
                process.arguments = ["-l", "-c", trimmed]
                process.standardOutput = pipe
                process.standardError = pipe
                let home = FileManager.default.homeDirectoryForCurrentUser.path
                process.currentDirectoryURL = URL(fileURLWithPath: home)

                var env = ProcessInfo.processInfo.environment
                let standardPaths = "/opt/homebrew/bin:/opt/homebrew/sbin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
                if let currentPath = env["PATH"], !currentPath.isEmpty {
                    env["PATH"] = "\(standardPaths):\(currentPath)"
                } else {
                    env["PATH"] = standardPaths
                }
                process.environment = env

                do {
                    try process.run()
                    process.waitUntilExit()
                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    let output = (String(data: data, encoding: .utf8) ?? "").trimmingCharacters(in: .newlines)
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(
                            name: NSNotification.Name("NexusTerminalCommandExecuted"),
                            object: (command: trimmed, output: output)
                        )
                    }
                    continuation.resume(returning: (output: output, exitCode: process.terminationStatus))
                } catch {
                    continuation.resume(returning: (output: "Execution error: \(error.localizedDescription)", exitCode: -1))
                }
            }
        }
    }

    public func openInTerminalApp(command: String) {
        let escaped = command.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
        let script = "tell application \"Terminal\" to do script \"\(escaped)\""
        if let appleScript = NSAppleScript(source: script) {
            var error: NSDictionary?
            appleScript.executeAndReturnError(&error)
            NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Utilities/Terminal.app"))
        }
    }

    public func extractTerminalCommand(from text: String) -> String? {
        let patterns = ["```bash\n", "```zsh\n", "```sh\n", "```terminal\n"]
        for p in patterns {
            if let start = text.range(of: p) {
                let remainder = text[start.upperBound...]
                if let end = remainder.range(of: "```") {
                    let cmd = String(remainder[..<end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                    if !cmd.isEmpty { return cmd }
                }
            }
        }
        return nil
    }

    public func extractAllTerminalCommands(from text: String) -> [String] {
        var results: [String] = []
        let patterns = ["```bash\n", "```zsh\n", "```sh\n", "```terminal\n"]
        for p in patterns {
            var searchRange = text.startIndex..<text.endIndex
            while let start = text.range(of: p, range: searchRange) {
                let remainder = text[start.upperBound...]
                if let end = remainder.range(of: "```") {
                    let cmd = String(remainder[..<end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                    if !cmd.isEmpty && !results.contains(cmd) {
                        results.append(cmd)
                    }
                    searchRange = end.upperBound..<text.endIndex
                } else {
                    break
                }
            }
        }
        return results
    }

    // MARK: - 🛠️ Native Agent Tool Calling Extraction
    public func extractNativeToolCall(from text: String) -> (name: String, argument: String, payload: String)? {
        let recognizedTools = ["find_project", "read_file", "write_file", "compile", "drive_xcode", "test_drag_and_drop", "tail", "recent_items", "siri", "browse_web", "crawl_files", "drop_worker", "trash_airlock_promote"]

        // Pattern 1: ```tool:<toolName>
        let toolPrefix = "```tool:"
        if let start = text.range(of: toolPrefix) {
            let remainder = text[start.upperBound...]
            if let end = remainder.range(of: "```") {
                let toolBody = String(remainder[..<end.lowerBound])
                let lines = toolBody.components(separatedBy: "\n")
                if let firstLine = lines.first {
                    let parts = firstLine.trimmingCharacters(in: .whitespaces).components(separatedBy: .whitespaces)
                    if let toolName = parts.first, !toolName.isEmpty {
                        let argument = parts.dropFirst().joined(separator: " ").trimmingCharacters(in: .whitespaces)
                        let payload = lines.dropFirst().joined(separator: "\n").trimmingCharacters(in: .newlines)
                        return (name: toolName, argument: argument, payload: payload)
                    }
                }
            }
        }

        // Pattern 2: ```<toolName>
        for tool in recognizedTools {
            let directPrefix = "```\(tool)"
            if let start = text.range(of: directPrefix) {
                let remainder = text[start.upperBound...]
                if let end = remainder.range(of: "```") {
                    let toolBody = String(remainder[..<end.lowerBound])
                    let lines = toolBody.components(separatedBy: "\n")
                    let firstLine = (lines.first ?? "").trimmingCharacters(in: .whitespaces)
                    let payload = lines.dropFirst().joined(separator: "\n").trimmingCharacters(in: .newlines)
                    return (name: tool, argument: firstLine, payload: payload)
                }
            }
        }

        return nil
    }

    // MARK: - 🌐 Web Browser & Internet Search Tools
    public func extractAllWebSearches(from text: String) -> [String] {
        var results: [String] = []
        let patterns = ["```search\n", "```search ", "```web\n", "```web "]
        for p in patterns {
            var searchRange = text.startIndex..<text.endIndex
            while let start = text.range(of: p, range: searchRange) {
                let remainder = text[start.upperBound...]
                if let end = remainder.range(of: "```") {
                    let query = String(remainder[..<end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                    if !query.isEmpty && !results.contains(query) {
                        results.append(query)
                    }
                    searchRange = end.upperBound..<text.endIndex
                } else {
                    break
                }
            }
        }
        return results
    }

    public func extractAllWebURLs(from text: String) -> [URL] {
        var urls: [URL] = []
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) ?? []
        for match in matches {
            if let url = match.url, (url.scheme == "http" || url.scheme == "https") {
                if !urls.contains(url) {
                    urls.append(url)
                }
            }
        }
        return urls
    }

    public func extractHiddenBrowseURLs(from text: String) -> [URL] {
        var urls: [URL] = []
        let patterns = ["```browse_hidden\n", "```browse_hidden "]
        for p in patterns {
            var searchRange = text.startIndex..<text.endIndex
            while let start = text.range(of: p, range: searchRange) {
                let remainder = text[start.upperBound...]
                if let end = remainder.range(of: "```") {
                    let raw = String(remainder[..<end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                    if let url = URL(string: raw), (url.scheme == "http" || url.scheme == "https"), !urls.contains(url) {
                        urls.append(url)
                    }
                    searchRange = end.upperBound..<text.endIndex
                } else {
                    break
                }
            }
        }
        return urls
    }

    public func extractScreenViewRequested(from text: String) -> Bool {
        let patterns = ["```screen_view", "```view_screen"]
        return patterns.contains { text.range(of: $0) != nil }
    }

    public func extractWebLinks(from text: String) -> [ExtractedWebLink] {
        var links: [ExtractedWebLink] = []
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count)) ?? []
        for match in matches {
            if let url = match.url, (url.scheme == "http" || url.scheme == "https") {
                let host = url.host ?? url.absoluteString
                let link = ExtractedWebLink(title: host, url: url)
                if !links.contains(where: { $0.urlString == link.urlString }) {
                    links.append(link)
                }
            }
        }
        return links
    }

    public func executeWebSearch(_ query: String) async -> (summary: String, sources: [(title: String, url: String)]) {
        let clean = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return ("No search query provided.", []) }

        let indexResponse = await GenieSearchIndexCrawlerEngine.shared.search(query: clean)
        if !indexResponse.results.isEmpty {
            let sources = indexResponse.results.map { (title: "\($0.title) (\($0.sourceName))", url: $0.url) }
            return (indexResponse.summary, sources)
        }

        // Fallback: Direct search link
        var fallbackSources: [(title: String, url: String)] = []
        if let encoded = clean.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
            fallbackSources.append((title: "Web Search: \"\(clean)\"", url: "https://www.google.com/search?q=\(encoded)"))
        }

        let summary = "Direct web search initiated for \"\(clean)\". Open the mini browser above to view live results."
        return (summary, fallbackSources)
    }

    public func fetchWebPage(url: URL) async -> String {
        do {
            var req = URLRequest(url: url, timeoutInterval: 8)
            req.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36", forHTTPHeaderField: "User-Agent")
            let (data, _) = try await URLSession.shared.data(for: req)
            if let html = String(data: data, encoding: .utf8) {
                let textOnly = html.replacingOccurrences(of: "<script[\\s\\S]*?</script>", with: "", options: .regularExpression)
                    .replacingOccurrences(of: "<style[\\s\\S]*?</style>", with: "", options: .regularExpression)
                    .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
                    .components(separatedBy: .whitespacesAndNewlines)
                    .filter { !$0.isEmpty }
                    .joined(separator: " ")
                return String(textOnly.prefix(2500))
            }
        } catch {
            return "Failed to fetch webpage: \(error.localizedDescription)"
        }
        return "Unable to decode webpage content."
    }

    public func openInWebBrowser(url: URL) {
        NSWorkspace.shared.open(url)
    }

    public func openSearchInWebBrowser(query: String) {
        let clean = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let encoded = clean.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://www.google.com/search?q=\(encoded)") else { return }
        NSWorkspace.shared.open(url)
    }

    public func performInternetSearch(query: String) {
        let clean = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }

        // Pop up the mini browser with this search query!
        MiniBrowserManager.shared.search(query: clean, triggeredByAI: false)

        // Also run in chat stream so user sees live summary with clickable sources
        let userMsg = ChatMessage(role: "user", content: "🌐 Search: \"\(clean)\"", model: "Mini Browser 🌐")
        self.chatHistory.append(userMsg)
        self.saveChatHistory()

        Task {
            let (summary, sources) = await self.executeWebSearch(clean)
            var resp = summary
            if !sources.isEmpty {
                resp += "\n\n**Web Sources:**\n" + sources.prefix(3).map { "• [\($0.title)](\($0.url))" }.joined(separator: "\n")
            }
            let assistantMsg = ChatMessage(role: "assistant", content: resp, model: "Mini Browser 🌐")
            self.chatHistory.append(assistantMsg)
            self.saveChatHistory()
        }
    }

    // MARK: - ⚡ Parallel Disk Writing & In-RAM Live Rendering Engine

    public func currentChatFolders() -> (documents: URL, presentations: URL, notes: URL, images: URL) {
        var folders = GenieStandardDirectories.chatSessionFolderURL(
            sessionId: self.currentSessionId,
            title: self.savedSessions.first(where: { $0.id == self.currentSessionId })?.title
        )
        if let folderOverride = self.activeSaveDirectoryOverride {
            folders.documents = folderOverride
            folders.presentations = folderOverride
            folders.notes = folderOverride
            folders.images = folderOverride
        }
        return (documents: folders.documents, presentations: folders.presentations, notes: folders.notes, images: folders.images)
    }

    private var lastLiveStreamRenderTime: TimeInterval = 0
    private var lastDiskWriteTime: TimeInterval = 0
    private var pendingParallelWriteTask: Task<Void, Never>? = nil

    /// Extracts live in-progress HTML / SVG / Canvas straight from RAM during generation,
    /// broadcasts it to preview panes for real-time rendering, and writes to disk in parallel (non-blocking).
    @MainActor
    public func streamLiveCreationIfNeeded(force: Bool = false) {
        let now = ProcessInfo.processInfo.systemUptime
        if !force && (now - lastLiveStreamRenderTime < 0.04) {
            return
        }
        lastLiveStreamRenderTime = now

        guard let live = extractLiveCreation(from: self.currentResponse) else { return }
        self.activeCreationCode = live.html
        self.activeCreationTitle = live.title

        // Write file asynchronously in parallel background task — never blocks RAM rendering or UI
        writeCreationParallel(title: live.title, html: live.html, isFinal: force)

        // Broadcast directly from RAM
        let desktopURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
        let safeTitle = live.title
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let baseName = safeTitle.isEmpty ? "AI Creation" : safeTitle
        let fileOnDesktop = desktopURL.appendingPathComponent("\(baseName).html")

        NotificationCenter.default.post(
            name: NSNotification.Name("NexusAIDisplayCreation"),
            object: live.html,
            userInfo: [
                "title": live.title,
                "filePath": fileOnDesktop.path,
                "fileURL": fileOnDesktop.absoluteString,
                "isLiveStream": !force
            ]
        )
    }

    /// Asynchronously writes HTML code to disk in a detached background task without stalling main thread or inference.
    public func writeCreationParallel(title: String, html: String, isFinal: Bool = false) {
        let now = ProcessInfo.processInfo.systemUptime
        if !isFinal && (now - lastDiskWriteTime < 0.5) {
            return // Throttle rapid disk writes during fast token bursts
        }
        lastDiskWriteTime = now

        let safeTitle = title
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let baseName = safeTitle.isEmpty ? "AI Creation" : safeTitle

        let desktopURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
        let fileOnDesktop = desktopURL.appendingPathComponent("\(baseName).html")
        let fileInFolder = currentChatFolders().documents.appendingPathComponent("\(baseName).html")

        let code = html
        pendingParallelWriteTask?.cancel()
        pendingParallelWriteTask = Task.detached(priority: .background) {
            guard !Task.isCancelled else { return }
            try? code.write(to: fileOnDesktop, atomically: true, encoding: .utf8)
            try? code.write(to: fileInFolder, atomically: true, encoding: .utf8)
        }
    }

    /// Extracts streaming or partial code from RAM, even before the code block has closed.
    public func extractLiveCreation(from text: String) -> (title: String, html: String)? {
        // 1. If complete creation is already available, use it
        if let complete = extractCreation(from: text) {
            return complete
        }

        // 2. Incomplete ```html or ```htm block streaming live
        if let htmlRange = text.range(of: "```html", options: .caseInsensitive) ?? text.range(of: "```htm", options: .caseInsensitive) {
            var raw = String(text[htmlRange.upperBound...])
            if let endRange = raw.range(of: "```") {
                raw = String(raw[..<endRange.lowerBound])
            }
            raw = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            if raw.count >= 15 {
                let title = extractTitle(from: raw, fallback: "Live Interactive Creation")
                let safeHtml = closeLiveHtmlTagsIfNeeded(raw)
                return (title: title, html: formatSelfContainedHtml(safeHtml))
            }
        }

        // 3. Incomplete <!DOCTYPE html> or <html> streaming live
        if let htmlStart = text.range(of: "<!DOCTYPE html", options: .caseInsensitive) ?? text.range(of: "<html", options: .caseInsensitive) {
            var raw = String(text[htmlStart.lowerBound...])
            if let end = raw.range(of: "</html>", options: .caseInsensitive) {
                raw = String(raw[..<end.upperBound])
            }
            if raw.count >= 20 {
                let title = extractTitle(from: raw, fallback: "Live Web Creation")
                let safeHtml = closeLiveHtmlTagsIfNeeded(raw)
                return (title: title, html: safeHtml)
            }
        }

        // 4. Incomplete <svg> tag streaming live
        if let svgStart = text.range(of: "<svg", options: .caseInsensitive) {
            var raw = String(text[svgStart.lowerBound...])
            if let end = raw.range(of: "</svg>", options: .caseInsensitive) {
                raw = String(raw[..<end.upperBound])
            } else {
                raw += "</svg>"
            }
            if raw.count >= 15 {
                return (title: "AI Vector Art (SVG)", html: wrapSvgInHtml(raw))
            }
        }

        return nil
    }

    private func closeLiveHtmlTagsIfNeeded(_ html: String) -> String {
        StreamingHTMLTagBalancer.balance(html)
    }

    // MARK: - AI Creation Extraction & Display in Player Window
    public func extractCreation(from text: String) -> (title: String, html: String)? {
        // 1. Explicit HTML Code Block
        if let htmlRange = text.range(of: "```html", options: .caseInsensitive) {
            let sub = text[htmlRange.upperBound...]
            if let endRange = sub.range(of: "```") {
                let rawCode = String(sub[..<endRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                if !rawCode.isEmpty {
                    return (title: extractTitle(from: rawCode, fallback: "Interactive HTML5 Creation"), html: formatSelfContainedHtml(rawCode))
                }
            }
        }

        // 2. Explicit SVG Code Block
        if let svgRange = text.range(of: "```svg", options: .caseInsensitive) {
            let sub = text[svgRange.upperBound...]
            if let endRange = sub.range(of: "```") {
                let rawSvg = String(sub[..<endRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                if !rawSvg.isEmpty {
                    return (title: "AI Vector Art (SVG)", html: wrapSvgInHtml(rawSvg))
                }
            }
        }

        // 3. Embedded <svg> tags inside text
        if let startSvg = text.range(of: "<svg", options: .caseInsensitive),
           let endSvg = text.range(of: "</svg>", options: .caseInsensitive),
           startSvg.lowerBound < endSvg.upperBound {
            let svgCode = String(text[startSvg.lowerBound..<endSvg.upperBound])
            return (title: "AI Vector Art (SVG)", html: wrapSvgInHtml(svgCode))
        }

        // 4. Embedded <!DOCTYPE html> or <html> tags
        if let htmlStart = text.range(of: "<!DOCTYPE html", options: .caseInsensitive) ?? text.range(of: "<html", options: .caseInsensitive),
           let htmlEnd = text.range(of: "</html>", options: .caseInsensitive),
           htmlStart.lowerBound < htmlEnd.upperBound {
            let fullHtml = String(text[htmlStart.lowerBound..<htmlEnd.upperBound])
            return (title: extractTitle(from: fullHtml, fallback: "Web Creation"), html: fullHtml)
        }

        // 5. JavaScript Canvas / Animation code block
        if let jsRange = text.range(of: "```javascript", options: .caseInsensitive) ?? text.range(of: "```js", options: .caseInsensitive) {
            let sub = text[jsRange.upperBound...]
            if let endRange = sub.range(of: "```") {
                let rawJs = String(sub[..<endRange.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                if rawJs.contains("canvas") || rawJs.contains("requestAnimationFrame") || rawJs.contains("getContext") || rawJs.contains("three") {
                    return (title: "HTML5 Canvas Animation", html: wrapJsInCanvasHtml(rawJs))
                }
            }
        }

        return nil
    }

    private func extractTitle(from code: String, fallback: String) -> String {
        if let start = code.range(of: "<title>", options: .caseInsensitive),
           let end = code.range(of: "</title>", options: .caseInsensitive),
           start.upperBound < end.lowerBound {
            let t = String(code[start.upperBound..<end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            if !t.isEmpty { return t }
        }
        return fallback
    }

    private func formatSelfContainedHtml(_ code: String) -> String {
        if code.contains("<!DOCTYPE html") || code.contains("<html") {
            return code
        }
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <style>
                body { margin: 0; padding: 8px; background: #0b0c10; color: #fff; font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; overflow: auto; word-wrap: break-word; overflow-wrap: break-word; width: 100%; min-height: 100vh; box-sizing: border-box; }
                canvas { display: block; max-width: 100%; max-height: 100%; }
            </style>
        </head>
        <body>
            \(code)
        </body>
        </html>
        """
    }

    private func wrapSvgInHtml(_ svg: String) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <style>
                body { margin: 0; padding: 0; background: #090a0f; display: flex; align-items: center; justify-content: center; width: 100vw; height: 100vh; overflow: hidden; }
                svg { max-width: 90vw; max-height: 90vh; filter: drop-shadow(0 0 16px rgba(0,255,255,0.4)); animation: pulse 4s ease-in-out infinite alternate; }
                @keyframes pulse { 0% { transform: scale(0.98); } 100% { transform: scale(1.02); } }
            </style>
        </head>
        <body>
            \(svg)
        </body>
        </html>
        """
    }

    private func wrapJsInCanvasHtml(_ js: String) -> String {
        """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <style>
                body { margin: 0; padding: 0; background: #000; overflow: hidden; width: 100vw; height: 100vh; }
                canvas { display: block; width: 100%; height: 100%; }
            </style>
        </head>
        <body>
            <canvas id="canvas"></canvas>
            <script>
                const canvas = document.getElementById('canvas');
                function resize() {
                    canvas.width = window.innerWidth;
                    canvas.height = window.innerHeight;
                }
                window.addEventListener('resize', resize);
                resize();
                \(js)
            </script>
        </body>
        </html>
        """
    }

    public func detectEmotion(from text: String) -> AIEmotionType? {
        let lower = text.lowercased()
        if lower.contains("zen") || lower.contains("ocean") || lower.contains("water") || lower.contains("calm") || lower.contains("meditate") || lower.contains("peace") {
            return .calm
        }
        if lower.contains("excite") || lower.contains("speed") || lower.contains("turbo") || lower.contains("lightning") || lower.contains("energy") || lower.contains("voltage") {
            return .excited
        }
        if lower.contains("art") || lower.contains("draw") || lower.contains("paint") || lower.contains("color") || lower.contains("canvas") || lower.contains("creative") || lower.contains("aurora") {
            return .creative
        }
        if lower.contains("code") || lower.contains("matrix") || lower.contains("terminal") || lower.contains("cyber") || lower.contains("neon") || lower.contains("hack") || lower.contains("script") {
            return .matrix
        }
        if lower.contains("think") || lower.contains("math") || lower.contains("physics") || lower.contains("quantum") || lower.contains("cosmos") || lower.contains("space") || lower.contains("philosophy") {
            return .contemplative
        }
        if lower.contains("sunset") || lower.contains("warm") || lower.contains("sun") || lower.contains("gold") || lower.contains("fire") || lower.contains("dusk") {
            return .warmth
        }
        if lower.contains("heart") || lower.contains("empathy") || lower.contains("love") || lower.contains("friend") || lower.contains("compassion") || lower.contains("comfort") {
            return .empathy
        }
        if lower.contains("magic") || lower.contains("genie") || lower.contains("mystic") || lower.contains("spell") || lower.contains("crystal") {
            return .mystical
        }
        return nil
    }

    // MARK: - Visual AI Card & Image Generation Wrapper
    @discardableResult
    public func saveAnswerAsImageCard(content: String, title: String? = nil) -> URL? {
        AICssCardRenderer.shared.saveCardImageToDesktop(content: content, title: title, model: selectedModelDisplayName)
    }

    @discardableResult
    public func exportAnswerAsCSSCard(content: String, title: String? = nil) -> URL? {
        AICssCardRenderer.shared.exportHTMLCardToDesktop(content: content, title: title, model: selectedModelDisplayName)
    }

    // MARK: - Native Tool Extractors & Execution
    public func extractPresentationSlides(from text: String) -> (title: String, content: String)? {
        let patterns = ["```slides", "```presentation", "```deck"]
        for p in patterns {
            if let start = text.range(of: p, options: .caseInsensitive) {
                let remainder = text[start.upperBound...]
                if let end = remainder.range(of: "```") {
                    let body = String(remainder[..<end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                    let firstLine = body.components(separatedBy: .newlines).first ?? "Presentation"
                    let title = firstLine.replacingOccurrences(of: "#", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                    return (title: title.isEmpty ? "Genie Presentation" : title, content: body)
                }
            }
        }
        return nil
    }

    public func extractPDFContent(from text: String) -> (title: String, content: String)? {
        if let start = text.range(of: "```pdf", options: .caseInsensitive) {
            let remainder = text[start.upperBound...]
            if let end = remainder.range(of: "```") {
                let body = String(remainder[..<end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                let firstLine = body.components(separatedBy: .newlines).first ?? "Document"
                let title = firstLine.replacingOccurrences(of: "#", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
                return (title: title.isEmpty ? "Genie Executive Report" : title, content: body)
            }
        }
        return nil
    }

    public func extractChartSpec(from text: String) -> (type: String, json: String, title: String)? {
        let patterns = ["```chart", "```graph"]
        for p in patterns {
            if let start = text.range(of: p, options: .caseInsensitive) {
                let remainder = text[start.upperBound...]
                if let end = remainder.range(of: "```") {
                    let block = String(remainder[..<end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                    let lines = block.components(separatedBy: .newlines)
                    let firstLine = lines.first?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? "bar"
                    let chartType = ["bar", "line", "pie", "doughnut", "radar"].first(where: { firstLine.contains($0) }) ?? "bar"
                    let jsonContent = lines.dropFirst().joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                    let effectiveJSON = jsonContent.isEmpty ? block : jsonContent
                    return (type: chartType, json: effectiveJSON, title: "Data Visualization")
                }
            }
        }
        return nil
    }

    public func extractMermaidDiagram(from text: String) -> (diagram: String, title: String)? {
        if let start = text.range(of: "```mermaid", options: .caseInsensitive) {
            let remainder = text[start.upperBound...]
            if let end = remainder.range(of: "```") {
                let body = String(remainder[..<end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                return (diagram: body, title: "System Architecture")
            }
        }
        return nil
    }

    public func extractPolaroidCommand(from text: String) -> String? {
        let patterns = ["```polaroid\n", "```polaroid ", "```snapshot\n", "```snapshot "]
        for p in patterns {
            if let start = text.range(of: p, options: .caseInsensitive) {
                let remainder = text[start.upperBound...]
                if let end = remainder.range(of: "```") {
                    let memo = String(remainder[..<end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                    return memo.isEmpty ? "Polaroid Snapshot" : memo
                }
            }
        }
        return nil
    }

    public func extractNoteCommand(from text: String) -> (format: String, content: String)? {
        if let start = text.range(of: "```note", options: .caseInsensitive) {
            let remainder = text[start.upperBound...]
            if let end = remainder.range(of: "```") {
                let body = String(remainder[..<end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                return (format: "markdown", content: body)
            }
        }
        return nil
    }

    public func extractAppCommand(from text: String) -> String? {
        let patterns = ["```app\n", "```app ", "```open_app\n", "```open_app "]
        for p in patterns {
            if let start = text.range(of: p, options: .caseInsensitive) {
                let remainder = text[start.upperBound...]
                if let end = remainder.range(of: "```") {
                    return String(remainder[..<end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
        return nil
    }

    public func extractSwitchStationCommand(from text: String) -> String? {
        if let start = text.range(of: "```switch_station", options: .caseInsensitive) {
            let remainder = text[start.upperBound...]
            if let end = remainder.range(of: "```") {
                return String(remainder[..<end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            }
        }
        return nil
    }

    public func extractReminderCommand(from text: String) -> String? {
        if let start = text.range(of: "```reminder", options: .caseInsensitive) {
            let remainder = text[start.upperBound...]
            if let end = remainder.range(of: "```") {
                return String(remainder[..<end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return nil
    }

    public func extractAppleNoteCommand(from text: String) -> (title: String, content: String)? {
        if let start = text.range(of: "```apple_note", options: .caseInsensitive) {
            let remainder = text[start.upperBound...]
            if let end = remainder.range(of: "```") {
                let body = String(remainder[..<end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                let parts = body.components(separatedBy: "|")
                if parts.count >= 2 {
                    return (title: parts[0].trimmingCharacters(in: .whitespacesAndNewlines), content: parts.dropFirst().joined(separator: "|").trimmingCharacters(in: .whitespacesAndNewlines))
                }
                return (title: "Genie Note", content: body)
            }
        }
        return nil
    }

    public func extractAppleScriptCommand(from text: String) -> (appName: String, script: String)? {
        let patterns = ["```applescript", "```apple_script", "```automate_app"]
        for p in patterns {
            if let start = text.range(of: p, options: .caseInsensitive) {
                let remainder = text[start.upperBound...]
                if let end = remainder.range(of: "```") {
                    let body = String(remainder[..<end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                    guard let firstNewline = body.firstIndex(of: "\n") else { return nil }
                    let appName = String(body[..<firstNewline]).trimmingCharacters(in: .whitespacesAndNewlines)
                    let script = String(body[body.index(after: firstNewline)...]).trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !appName.isEmpty, !script.isEmpty else { return nil }
                    return (appName: appName, script: script)
                }
            }
        }
        return nil
    }

    public func extractDesktopAgentCommand(from text: String) -> String? {
        let patterns = ["```desktop_agent", "```desktop", "```antigravity_desktop", "```computer"]
        for p in patterns {
            if let start = text.range(of: p, options: .caseInsensitive) {
                let remainder = text[start.upperBound...]
                if let end = remainder.range(of: "```") {
                    return String(remainder[..<end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
        return nil
    }

    public func extractRecordCommand(from text: String) -> Double? {
        let patterns = ["```record_screen", "```record", "```screen_record"]
        for p in patterns {
            if let start = text.range(of: p, options: .caseInsensitive) {
                let remainder = text[start.upperBound...]
                if let end = remainder.range(of: "```") {
                    let body = String(remainder[..<end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                    let sec = Double(body) ?? 10.0
                    return sec
                }
            }
        }
        return nil
    }

    public func extractiMessageCommand(from text: String) -> (recipient: String, content: String)? {
        let patterns = ["```imessage", "```imsg", "```sms", "```text_phone", "```ichat", "```messages", "```apple_messages"]
        for p in patterns {
            if let start = text.range(of: p, options: .caseInsensitive) {
                let remainder = text[start.upperBound...]
                if let end = remainder.range(of: "```") {
                    let full = String(remainder[..<end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                    var target = GeniePhoneBridgeManager.shared.appleID.isEmpty ? (GenieAppleAuth.shared.email.isEmpty ? "user@icloud.com" : GenieAppleAuth.shared.email) : GeniePhoneBridgeManager.shared.appleID
                    var body = full
                    if full.hasPrefix("[recipient=") {
                        if let closeBracket = full.range(of: "]") {
                            let recPart = full[full.index(full.startIndex, offsetBy: 11)..<closeBracket.lowerBound]
                            target = String(recPart).trimmingCharacters(in: .whitespacesAndNewlines)
                            body = String(full[closeBracket.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                    }
                    if target.lowercased() == "me" || target.lowercased() == "self" {
                        target = GeniePhoneBridgeManager.shared.appleID.isEmpty ? (GenieAppleAuth.shared.email.isEmpty ? "user@icloud.com" : GenieAppleAuth.shared.email) : GeniePhoneBridgeManager.shared.appleID
                    }
                    return (recipient: target, content: body)
                }
            }
        }
        return nil
    }

    public func extractPhonePingCommand(from text: String) -> String? {
        let patterns = ["```phone_ping", "```ping_phone", "```self_ping"]
        for p in patterns {
            if let start = text.range(of: p, options: .caseInsensitive) {
                let remainder = text[start.upperBound...]
                if let end = remainder.range(of: "```") {
                    return String(remainder[..<end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
        return nil
    }

    public func extractPhoneBridgeCommand(from text: String) -> String? {
        if let start = text.range(of: "```phone_bridge", options: .caseInsensitive) {
            let remainder = text[start.upperBound...]
            if let end = remainder.range(of: "```") {
                return String(remainder[..<end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            }
        }
        return nil
    }

    public func extractAirDropCommand(from text: String) -> String? {
        let patterns = ["```airdrop", "```air_drop", "```send_airdrop"]
        for p in patterns {
            if let start = text.range(of: p, options: .caseInsensitive) {
                let remainder = text[start.upperBound...]
                if let end = remainder.range(of: "```") {
                    return String(remainder[..<end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
        return nil
    }

    public func extractAgentNetworkCommand(from text: String) -> String? {
        let patterns = ["```agent_network", "```share_net", "```local_network"]
        for p in patterns {
            if let start = text.range(of: p, options: .caseInsensitive) {
                let remainder = text[start.upperBound...]
                if let end = remainder.range(of: "```") {
                    return String(remainder[..<end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
        return nil
    }

    public func extractAppDocCommand(from text: String) -> String? {
        let patterns = ["```app_doc", "```app_documentation", "```doc"]
        for p in patterns {
            if let start = text.range(of: p, options: .caseInsensitive) {
                let remainder = text[start.upperBound...]
                if let end = remainder.range(of: "```") {
                    return String(remainder[..<end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
        return nil
    }

    public func extractSiriCommand(from text: String) -> (name: String, input: String)? {
        let patterns = ["```shortcut", "```siri", "```apple_shortcut"]
        for p in patterns {
            if let start = text.range(of: p, options: .caseInsensitive) {
                let remainder = text[start.upperBound...]
                if let end = remainder.range(of: "```") {
                    let content = String(remainder[..<end.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                    let lines = content.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
                    guard let firstLine = lines.first else { continue }
                    var name = firstLine
                    if name.lowercased().hasPrefix("run ") {
                        name = String(name.dropFirst(4)).trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                    let input = lines.dropFirst().joined(separator: "\n")
                    return (name: name, input: input)
                }
            }
        }
        return nil
    }
}
