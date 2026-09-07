import AppKit
import SwiftUI

// MARK: - 📝 Popup Code & Text Editor Canvas View
public struct PopupCodeEditorCanvasView: View {
    @ObservedObject var tabManager = WorkspaceTabManager.shared
    @ObservedObject var localModels = LocalModelManager.shared
    let tabId: UUID

    @State private var text: String = ""
    @State private var language: String = "Swift"
    @State private var statusFeedback: String? = nil
    @State private var isVSCodeMode: Bool = true

    public static let supportedLanguages: [String] = [
        "Swift", "Python", "JavaScript", "HTML / CSS", "Markdown", "JSON", "Shell (zsh)", "Plain Text"
    ]

    public init(tabId: UUID) {
        self.tabId = tabId
    }

    private var currentTab: WorkspaceTab? {
        tabManager.tabs.first(where: { $0.id == tabId })
    }

    public var body: some View {
        if isVSCodeMode {
            EmbeddedVSCodeStudioView()
        } else {
            legacyEditorBody
        }
    }

    private var legacyEditorBody: some View {
        VStack(spacing: 0) {
            // ── Top Action Ribbon ──
            HStack(spacing: 8) {
                // Language Mode Selector
                Menu {
                    ForEach(Self.supportedLanguages, id: \.self) { lang in
                        Button(action: {
                            language = lang
                            tabManager.updateEditorLanguage(id: tabId, lang: lang)
                            HapticFeedback.selection()
                        }) {
                            HStack {
                                Text(lang)
                                if language == lang {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left.forwardslash.chevron.right")
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundColor(.orange)
                        Text(language)
                            .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.92))
                        Image(systemName: "chevron.down")
                            .font(.system(size: 7.5, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3.5)
                    .background(RoundedRectangle(cornerRadius: 5).fill(Color.white.opacity(0.10)))
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()

                // Toggle VS Code Mode
                Button(action: {
                    withAnimation { isVSCodeMode = true }
                    HapticFeedback.playClickSound()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "curlybraces.square.fill")
                            .font(.system(size: 10))
                        Text("VS Code Studio")
                            .font(.system(size: 10, weight: .semibold))
                    }
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3.5)
                    .background(RoundedRectangle(cornerRadius: 5).fill(Color.cyan.opacity(0.15)))
                }
                .buttonStyle(.plain)

                Spacer()

                // AI Code Assistant Actions
                Menu {
                    Button("Explain Code ✨") {
                        let prompt = "Explain the following \(language) code clearly:\n\n\(text)"
                        localModels.generate(prompt: prompt)
                        tabManager.createTab(type: .chat, title: "Explanation 💬")
                        HapticFeedback.selection()
                    }
                    Button("Refactor & Optimize ⚡️") {
                        let prompt = "Refactor and optimize the following \(language) code with best practices:\n\n\(text)"
                        localModels.generate(prompt: prompt)
                        tabManager.createTab(type: .chat, title: "Refactor ⚡️")
                        HapticFeedback.selection()
                    }
                    Button("Add Documentation & Types 📖") {
                        let prompt = "Add complete documentation comments, docstrings, and type annotations to this \(language) code:\n\n\(text)"
                        localModels.generate(prompt: prompt)
                        tabManager.createTab(type: .chat, title: "Doc Comments 📖")
                        HapticFeedback.selection()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundColor(.cyan)
                        Text("AI Actions")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3.5)
                    .background(RoundedRectangle(cornerRadius: 5).fill(Color.cyan.opacity(0.18)))
                    .overlay(RoundedRectangle(cornerRadius: 5).stroke(Color.cyan.opacity(0.35), lineWidth: 0.5))
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .fixedSize()
                .disabled(text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                // Save to Desktop
                Button(action: saveToDesktop) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.doc.fill")
                            .font(.system(size: 9.5))
                        Text("Save File")
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(.white.opacity(0.9))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3.5)
                    .background(RoundedRectangle(cornerRadius: 5).fill(Color.white.opacity(0.10)))
                }
                .buttonStyle(.plain)
                .help("Save directly to Desktop")

                // Copy
                Button(action: copyToClipboard) {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .padding(4.5)
                        .background(RoundedRectangle(cornerRadius: 5).fill(Color.white.opacity(0.06)))
                }
                .buttonStyle(.plain)
                .help("Copy code to clipboard")

                // Clear
                Button(action: {
                    text = ""
                    tabManager.updateEditorText(id: tabId, text: "")
                    HapticFeedback.tick()
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .padding(4.5)
                        .background(RoundedRectangle(cornerRadius: 5).fill(Color.white.opacity(0.06)))
                }
                .buttonStyle(.plain)
                .help("Clear editor")
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color.black.opacity(0.45))

            Divider().opacity(0.35)

            // ── Editor Canvas Area ──
            HStack(alignment: .top, spacing: 0) {
                // Line Numbers Gutter
                lineNumbersGutter
                    .frame(width: 36)
                    .background(Color.black.opacity(0.30))

                Divider().opacity(0.2)

                // Text Editor
                TextEditor(text: $text)
                    .font(.system(size: 11.5, design: .monospaced))
                    .foregroundColor(Color(red: 0.92, green: 0.94, blue: 0.96))
                    .scrollContentBackground(.hidden)
                    .background(Color(red: 0.07, green: 0.08, blue: 0.11).opacity(0.96))
                    .padding(8)
                    .onChange(of: text) { _, newVal in
                        tabManager.updateEditorText(id: tabId, text: newVal)
                    }
            }

            Divider().opacity(0.35)

            // ── Footer Bar ──
            HStack(spacing: 8) {
                Text("\(lineCount) lines")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.secondary)

                Text("•")
                    .font(.system(size: 9))
                    .foregroundColor(.secondary.opacity(0.4))

                Text("\(wordCount) words")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.secondary)

                Spacer()

                if let fb = statusFeedback {
                    Text(fb)
                        .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                        .foregroundColor(.green)
                }

                Text("UTF-8")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.50))
        }
        .onAppear {
            if let t = currentTab {
                self.text = t.editorText
                self.language = t.editorLanguage
            }
        }
    }

    private var lineCount: Int {
        text.components(separatedBy: "\n").count
    }

    private var wordCount: Int {
        text.split { $0.isWhitespace || $0.isNewline }.count
    }

    private var lineNumbersGutter: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .trailing, spacing: 2.8) {
                ForEach(1...max(1, lineCount), id: \.self) { num in
                    Text("\(num)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.white.opacity(0.28))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .padding(.trailing, 6)
            .padding(.top, 9)
        }
    }

    private func copyToClipboard() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        HapticFeedback.selection()
        showFeedback("Copied to Clipboard! 📋")
    }

    private func saveToDesktop() {
        let ext: String = {
            switch language {
            case "Swift": return "swift"
            case "Python": return "py"
            case "JavaScript": return "js"
            case "HTML / CSS": return "html"
            case "Markdown": return "md"
            case "JSON": return "json"
            case "Shell (zsh)": return "sh"
            default: return "txt"
            }
        }()

        let filename = "Genie_Snippet_\(Int(Date().timeIntervalSince1970)).\(ext)"
        let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSHomeDirectory() + "/Desktop")
        let fileURL = desktopURL.appendingPathComponent(filename)

        do {
            try text.write(to: fileURL, atomically: true, encoding: .utf8)
            HapticFeedback.selection()
            showFeedback("Saved to ~/Desktop/\(filename) 💾")
        } catch {
            showFeedback("Failed to save: \(error.localizedDescription) ⚠️")
        }
    }

    private func showFeedback(_ msg: String) {
        withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
            statusFeedback = msg
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) {
            withAnimation(.easeOut(duration: 0.2)) {
                if statusFeedback == msg { statusFeedback = nil }
            }
        }
    }
}
