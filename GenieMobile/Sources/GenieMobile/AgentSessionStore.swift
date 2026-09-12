import Foundation
import SwiftUI
import GenieAgentCore

// MARK: - UI Theme & Appearance Configurations
public enum MobileTheme: String, CaseIterable, Identifiable {
    case system = "System Default"
    case dark = "Dark Mode"
    case light = "Light Mode"
    case oledBlackout = "OLED Obsidian"

    public var id: String { rawValue }

    public var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .dark, .oledBlackout: return .dark
        case .light: return .light
        }
    }
}

public enum MobileAccentColor: String, CaseIterable, Identifiable {
    case cyan = "Quantum Cyan"
    case emerald = "Sovereign Emerald"
    case amber = "Solar Amber"
    case violet = "Nebula Violet"

    public var id: String { rawValue }

    public var color: Color {
        switch self {
        case .cyan: return Color(red: 0.0, green: 0.94, blue: 1.0)
        case .emerald: return Color(red: 0.0, green: 1.0, blue: 0.53)
        case .amber: return Color(red: 1.0, green: 0.72, blue: 0.0)
        case .violet: return Color(red: 0.66, green: 0.33, blue: 0.97)
        }
    }
}

/// iOS has no local Ollama runtime, so this always talks to a remote
/// OpenAI-compatible endpoint — typically the user's own Mac running Ollama
/// on the same network — via the same AgentHTTPModel the Mac app's Agent 3.0
/// workspace uses. Settings are the iOS equivalent of the Mac's "Models &
/// Providers" pane.
@MainActor
final class GenieSettings: ObservableObject {
    static let shared = GenieSettings()

    @Published var host: String {
        didSet { UserDefaults.standard.set(host, forKey: Keys.host) }
    }
    @Published var model: String {
        didSet { UserDefaults.standard.set(model, forKey: Keys.model) }
    }
    @Published var apiKey: String {
        didSet { UserDefaults.standard.set(apiKey, forKey: Keys.apiKey) }
    }
    @Published var theme: MobileTheme {
        didSet { UserDefaults.standard.set(theme.rawValue, forKey: Keys.theme) }
    }
    @Published var accent: MobileAccentColor {
        didSet { UserDefaults.standard.set(accent.rawValue, forKey: Keys.accent) }
    }
    @Published var enableHaptics: Bool {
        didSet { UserDefaults.standard.set(enableHaptics, forKey: Keys.enableHaptics) }
    }
    @Published var editorFontSize: Double {
        didSet { UserDefaults.standard.set(editorFontSize, forKey: Keys.editorFontSize) }
    }

    private enum Keys {
        static let host = "genie.mobile.host"
        static let model = "genie.mobile.model"
        static let apiKey = "genie.mobile.apiKey"
        static let theme = "genie.mobile.theme"
        static let accent = "genie.mobile.accent"
        static let enableHaptics = "genie.mobile.enableHaptics"
        static let editorFontSize = "genie.mobile.editorFontSize"
    }

    private init() {
        host = UserDefaults.standard.string(forKey: Keys.host) ?? "http://192.168.1.2:11434/v1/chat/completions"
        model = UserDefaults.standard.string(forKey: Keys.model) ?? "genie-frontier:latest"
        apiKey = UserDefaults.standard.string(forKey: Keys.apiKey) ?? ""
        
        let savedTheme = UserDefaults.standard.string(forKey: Keys.theme) ?? ""
        theme = MobileTheme(rawValue: savedTheme) ?? .oledBlackout
        
        let savedAccent = UserDefaults.standard.string(forKey: Keys.accent) ?? ""
        accent = MobileAccentColor(rawValue: savedAccent) ?? .cyan

        enableHaptics = UserDefaults.standard.object(forKey: Keys.enableHaptics) as? Bool ?? true
        
        let savedFontSize = UserDefaults.standard.double(forKey: Keys.editorFontSize)
        editorFontSize = savedFontSize > 0 ? savedFontSize : 13.0
    }

    func makeModel() throws -> AgentHTTPModel {
        guard let url = URL(string: host) else { throw AgentFailure("Invalid endpoint URL.") }
        return try AgentHTTPModel(endpoint: url, model: model, apiKey: apiKey)
    }
}

/// Drives one AgentRuntime run against the picked workspace folder — the iOS
/// counterpart of GenieAgentWorkspaceModel on the Mac. No activity_log
/// provider is wired up here; there's no app-level activity monitor on iOS.
@MainActor
final class AgentSessionStore: ObservableObject {
    static let shared = AgentSessionStore()

    @Published var run: AgentRun?
    @Published var isRunning = false
    @Published var pendingApproval: AgentToolCall?
    @Published var errorMessage: String?

    private let runtime = AgentRuntime()
    private var approvalContinuation: CheckedContinuation<Bool, Never>?
    private lazy var store = AgentRunStore(
        directory: FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Genie/AgentRuns", isDirectory: true)
    )

    private init() {}

    func send(_ objective: String) {
        guard !isRunning, let workspace = WorkspaceStore.shared.workspaceURL else {
            errorMessage = WorkspaceStore.shared.workspaceURL == nil ? "Pick a workspace folder in Files first." : nil
            return
        }
        do {
            let model = try GenieSettings.shared.makeModel()
            var next = run ?? AgentRun(objective: objective, workspace: workspace.path, model: GenieSettings.shared.model)
            if run == nil {
                next = AgentRun(objective: objective, workspace: workspace.path, model: GenieSettings.shared.model)
            } else {
                next.messages.append(AgentMessage(role: "user", content: objective))
            }
            isRunning = true
            errorMessage = nil
            Task { [weak self] in
                guard let self else { return }
                let result = await runtime.execute(
                    next, model: model, store: store, bypassApproval: false,
                    approve: { [weak self] call in await self?.requestApproval(call) ?? false },
                    observe: { [weak self] updated in await MainActor.run { self?.run = updated } }
                )
                run = result
                isRunning = false
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func requestApproval(_ call: AgentToolCall) async -> Bool {
        await withCheckedContinuation { continuation in
            pendingApproval = call
            approvalContinuation = continuation
        }
    }

    func resolveApproval(_ allowed: Bool) {
        pendingApproval = nil
        approvalContinuation?.resume(returning: allowed)
        approvalContinuation = nil
    }

    func startNewChat() {
        run = nil
        errorMessage = nil
    }
}
