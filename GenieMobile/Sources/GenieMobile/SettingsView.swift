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
                    Button("Mac Ollama (genie-frontier)") {
                        settings.host = "http://192.168.1.2:11434/v1/chat/completions"
                        settings.model = "genie-frontier:latest"
                    }
                    Button("Mac Ollama (genie-iphone)") {
                        settings.host = "http://192.168.1.2:11434/v1/chat/completions"
                        settings.model = "genie-iphone:latest"
                    }
                    Button("Genie API Server (Port 8080)") {
                        settings.host = "http://192.168.1.2:8080/v1/chat/completions"
                        settings.model = "genie-master"
                    }
                    Button("Simulator Localhost (127.0.0.1)") {
                        settings.host = "http://127.0.0.1:11434/v1/chat/completions"
                        settings.model = "genie-frontier:latest"
                    }
                } header: {
                    Text("Quick Connect Presets")
                } footer: {
                    Text("Tap to automatically configure host URL and model name for your local Mac network.")
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
