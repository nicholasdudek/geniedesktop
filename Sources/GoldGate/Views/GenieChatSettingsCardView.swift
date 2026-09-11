import AppKit
import SwiftUI

// MARK: - ⚙️ Clean Genie Chat Settings Card
public struct GenieChatSettingsCardView: View {
    @ObservedObject var localModels = LocalModelManager.shared
    @AppStorage(PrefKey.claudeApiKey) var claudeApiKey: String = ""
    @AppStorage(PrefKey.openaiApiKey) var openaiApiKey: String = ""
    @AppStorage(PrefKey.grokApiKey) var grokApiKey: String = ""
    @AppStorage(PrefKey.deepseekApiKey) var deepseekApiKey: String = ""
    @AppStorage(PrefKey.ollamaHost) var ollamaHost: String = "http://localhost:11434"
    @AppStorage(PrefKey.terminalAccessEnabled) var terminalAccessEnabled: Bool = true
    @AppStorage(PrefKey.terminalAutoExecute) var terminalAutoExecute: Bool = false
    @AppStorage(PrefKey.webAccessEnabled) var webAccessEnabled: Bool = true
    @AppStorage(PrefKey.webAutoSearch) var webAutoSearch: Bool = true
    @AppStorage(PrefKey.useOllamaModels) var useOllamaModels: Bool = true
    @AppStorage(PrefKey.unifyChatWindow) var unifyChatWindow: Bool = true
    @AppStorage(PrefKey.aiEmotion) var selectedEmotionRaw: String = AIEmotionType.mystical.rawValue

    @State private var statusFeedback: String? = nil

    /// The key is Keychain-backed on `LocalModelManager`, so bind through it rather
    /// than `@AppStorage`.
    private var geminiApiKeyBinding: Binding<String> {
        Binding(get: { localModels.geminiApiKey },
                set: { localModels.geminiApiKey = $0 })
    }

    public init() {}

    public var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 14) {
                // ── 1. Model Engine & Ollama Host ───────────────────────────
                settingsSection(title: "AI ENGINE & MODELS", icon: "brain.head.profile") {
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle("Use Local Ollama Models (Offline)", isOn: $useOllamaModels)
                            .toggleStyle(SwitchToggleStyle(tint: .cyan))
                            .onChange(of: useOllamaModels) { _, newVal in
                                localModels.localModelsEnabled = newVal
                                HapticFeedback.playClickSound()
                            }

                        if useOllamaModels {
                            HStack {
                                Text("Ollama Host:")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.secondary)
                                TextField("http://localhost:11434", text: $ollamaHost)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .font(.system(size: 11, design: .monospaced))
                                    .padding(5)
                                    .background(RoundedRectangle(cornerRadius: 5).fill(Color.white.opacity(0.06)))
                            }
                        }
                    }
                }

                // ── 2. Cloud API Keys (BYOK) ────────────────────────────────
                settingsSection(title: "CLOUD API KEYS (BYOK)", icon: "key.fill") {
                    VStack(alignment: .leading, spacing: 8) {
                        apiKeyRow(title: "Google Gemini Key", placeholder: "AIzaSy...", text: geminiApiKeyBinding, color: .blue)
                        apiKeyRow(title: "Anthropic Claude Key", placeholder: "sk-ant-api03...", text: $claudeApiKey, color: .orange)
                        apiKeyRow(title: "OpenAI GPT Key", placeholder: "sk-proj-...", text: $openaiApiKey, color: .green)
                        apiKeyRow(title: "xAI Grok Key", placeholder: "xai-...", text: $grokApiKey, color: .purple)
                        apiKeyRow(title: "DeepSeek Key", placeholder: "sk-...", text: $deepseekApiKey, color: .cyan)
                    }
                }

                // ── 3. Atmospheric Theme & Emotion ──────────────────────────
                settingsSection(title: "LIVING ATMOSPHERE & THEME", icon: "sparkles") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 90), spacing: 6)], spacing: 6) {
                        ForEach(AIEmotionType.allCases) { em in
                            let isSelected = selectedEmotionRaw == em.rawValue
                            Button(action: {
                                selectedEmotionRaw = em.rawValue
                                HapticFeedback.playClickSound()
                            }) {
                                HStack(spacing: 4) {
                                    Circle().fill(em.accentColor).frame(width: 7, height: 7)
                                    Text(em.rawValue)
                                        .font(.system(size: 10.5, weight: isSelected ? .bold : .medium, design: .rounded))
                                        .foregroundColor(isSelected ? .white : .secondary)
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(isSelected ? em.accentColor.opacity(0.28) : Color.white.opacity(0.04))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(isSelected ? em.accentColor : Color.clear, lineWidth: 0.8)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }

                // ── 4. Autonomous Agent Tools ───────────────────────────────
                settingsSection(title: "DEVELOPER TOOL EXECUTION", icon: "terminal.fill") {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Allow AI Terminal Execution", isOn: $terminalAccessEnabled)
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                        if terminalAccessEnabled {
                            Toggle("Auto-Execute Terminal Commands", isOn: $terminalAutoExecute)
                                .toggleStyle(SwitchToggleStyle(tint: .orange))
                                .padding(.leading, 12)
                        }

                        Divider().background(Color.white.opacity(0.08))

                        Toggle("Allow Live Internet Search & Browsing", isOn: $webAccessEnabled)
                            .toggleStyle(SwitchToggleStyle(tint: .blue))
                        if webAccessEnabled {
                            Toggle("Auto-Trigger Web Search on Questions", isOn: $webAutoSearch)
                                .toggleStyle(SwitchToggleStyle(tint: .cyan))
                                .padding(.leading, 12)
                        }
                    }
                }

                settingsSection(title: "AI LINUX ENVIRONMENT", icon: "desktopcomputer") {
                    GenieEnvironmentSettingsView()
                }

                // ── 5. Unified Chat Window ─────────────────────────────────
                settingsSection(title: "UNIFIED CHAT WINDOW", icon: "arrow.up.forward.and.arrow.down.backward") {
                    VStack(alignment: .leading, spacing: 6) {
                        Toggle("Merge Top & Program Chat Windows into One", isOn: $unifyChatWindow)
                            .toggleStyle(SwitchToggleStyle(tint: .cyan))
                        Text("When enabled, opening chat from the top menu bar automatically routes to the single unified program chat window so sessions and interactions stay in the same window.")
                            .font(.system(size: 10.5))
                            .foregroundColor(.secondary)
                    }
                }

                // ── 6. Chat History & Exports ───────────────────────────────
                settingsSection(title: "CHAT MANAGEMENT & EXPORTS", icon: "arrow.up.doc.fill") {
                    HStack(spacing: 8) {
                        Button(action: {
                            localModels.sendChatToAppleMessages()
                            statusFeedback = "Sent to Messages 💬"
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "message.fill")
                                Text("Send to Messages")
                            }
                            .font(.system(size: 10.5, weight: .medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.green.opacity(0.20)))
                        }
                        .buttonStyle(PlainButtonStyle())

                        Button(action: {
                            localModels.saveChatToAppleNotes()
                            statusFeedback = "Saved to Notes 📝"
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "note.text")
                                Text("Save to Notes")
                            }
                            .font(.system(size: 10.5, weight: .medium))
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.yellow.opacity(0.20)))
                        }
                        .buttonStyle(PlainButtonStyle())

                        Spacer()

                        Button(action: {
                            localModels.clearChatHistory()
                            statusFeedback = "Chat Cleared 🧹"
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "trash")
                                Text("Clear Chat")
                            }
                            .font(.system(size: 10.5, weight: .medium))
                            .foregroundColor(.red.opacity(0.9))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color.red.opacity(0.12)))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }

                if let fb = statusFeedback {
                    Text(fb)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.cyan)
                        .padding(.top, 4)
                }
            }
            .padding(14)
        }
    }

    private func settingsSection<Content: View>(title: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.cyan)
                Text(title)
                    .font(.system(size: 10, weight: .heavy, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            content()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(0.04))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 0.5))
        )
    }

    private func apiKeyRow(title: String, placeholder: String, text: Binding<String>, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 10.5, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            SecureField(placeholder, text: text)
                .textFieldStyle(PlainTextFieldStyle())
                .font(.system(size: 11, design: .monospaced))
                .padding(6)
                .background(RoundedRectangle(cornerRadius: 5).fill(Color.black.opacity(0.35)))
                .overlay(RoundedRectangle(cornerRadius: 5).stroke(color.opacity(0.3), lineWidth: 0.5))
        }
    }
}
