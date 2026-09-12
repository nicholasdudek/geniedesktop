import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settings = GenieSettings.shared
    @ObservedObject private var workspace = WorkspaceStore.shared

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Workspace") {
                        Text(workspace.workspaceName.isEmpty ? "None" : workspace.workspaceName)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Workspace")
                } footer: {
                    Text("Change it from the Files tab.")
                }

                Section {
                    Picker("Theme", selection: $settings.theme) {
                        ForEach(MobileTheme.allCases) { theme in
                            Text(theme.rawValue).tag(theme)
                        }
                    }
                    .pickerStyle(.menu)

                    Picker("Accent Color", selection: $settings.accent) {
                        ForEach(MobileAccentColor.allCases) { accent in
                            HStack {
                                Circle().fill(accent.color).frame(width: 12, height: 12)
                                Text(accent.rawValue)
                            }
                            .tag(accent)
                        }
                    }
                    .pickerStyle(.menu)

                    Toggle("Haptic Feedback", isOn: $settings.enableHaptics)

                    Stepper(value: $settings.editorFontSize, in: 10...22, step: 1) {
                        HStack {
                            Text("Editor Font Size")
                            Spacer()
                            Text("\(Int(settings.editorFontSize)) pt")
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("UI & Appearance")
                } footer: {
                    Text("Configures OLED Obsidian dark styling, dynamic accent glows, and code editor typography.")
                }

                Section {
                    Button("8B Llama 3.1 Instruct (8GB Mac Host)") {
                        settings.host = "http://192.168.1.2:11434/v1/chat/completions"
                        settings.model = "llama3.1:8b"
                    }
                    Button("7B Qwen 2.5 Coder (8GB Mac Host)") {
                        settings.host = "http://192.168.1.2:11434/v1/chat/completions"
                        settings.model = "qwen2.5-coder:7b"
                    }
                    Button("8B DeepSeek R1 Reasoning (8GB Mac Host)") {
                        settings.host = "http://192.168.1.2:11434/v1/chat/completions"
                        settings.model = "deepseek-r1:8b"
                    }
                    Button("3B Llama 3.2 (iPhone / Low RAM Optimal)") {
                        settings.host = "http://192.168.1.2:11434/v1/chat/completions"
                        settings.model = "llama3.2:3b"
                    }
                    Button("Simulator Localhost (127.0.0.1:11434)") {
                        settings.host = "http://127.0.0.1:11434/v1/chat/completions"
                        settings.model = "llama3.1:8b"
                    }
                } header: {
                    Text("8B & Hardware Presets (8GB Machines)")
                } footer: {
                    Text("Optimized for 8GB unified memory Macs running 4-bit quantized 8B models (Llama 3.1, Qwen 2.5 Coder, DeepSeek R1), and compact 3B models for iPhone.")
                }

                Section {
                    TextField("http://192.168.1.2:11434/v1/chat/completions", text: $settings.host)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Model, e.g. genie-frontier:latest", text: $settings.model)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    SecureField("API key (leave blank for local Ollama)", text: $settings.apiKey)
                } header: {
                    Text("Custom AI Endpoint")
                } footer: {
                    Text("iOS talks to a remote OpenAI-compatible endpoint — typically your Mac running Ollama on the same network.")
                }
            }
            .navigationTitle("Settings")
        }
    }
}
