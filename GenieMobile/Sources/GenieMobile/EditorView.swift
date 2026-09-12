import SwiftUI

struct EditorView: View {
    @ObservedObject private var settings = GenieSettings.shared
    @ObservedObject private var tabStore = DocumentTabStore.shared
    @State var fileURL: URL

    @State private var text: String = ""
    @State private var loadedText: String = ""
    @State private var errorMessage: String?
    @State private var isSaving = false

    private var hasChanges: Bool { text != loadedText }
    private var lineCount: Int { text.components(separatedBy: "\n").count }

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Document Tab Bar (Genie 30B Multi-Window Feature)
            if tabStore.openFiles.count > 1 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(tabStore.openFiles, id: \.self) { url in
                            let isActive = (url == fileURL)
                            HStack(spacing: 6) {
                                Image(systemName: "doc.text.fill")
                                    .font(.caption2)
                                    .foregroundStyle(isActive ? settings.accent.color : .secondary)
                                Text(url.lastPathComponent)
                                    .font(.caption.monospaced())
                                    .foregroundStyle(isActive ? Color.primary : Color.secondary)

                                Button(action: {
                                    tabStore.closeFile(url)
                                    if let next = tabStore.activeFileURL {
                                        fileURL = next
                                        load()
                                    }
                                }) {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.caption2)
                                        .foregroundStyle(Color.secondary.opacity(0.7))
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(isActive ? settings.accent.color.opacity(0.15) : Color.secondary.opacity(0.08))
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(isActive ? settings.accent.color.opacity(0.4) : Color.clear, lineWidth: 1)
                            )
                            .onTapGesture {
                                fileURL = url
                                tabStore.activeFileURL = url
                                load()
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                }
                .background(Color.secondary.opacity(0.04))
                Divider()
            }

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .padding(8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.08))
            }

            TextEditor(text: $text)
                .font(.system(size: settings.editorFontSize, weight: .regular, design: .monospaced))
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .padding(.horizontal, 8)

            Divider()

            // MARK: - Editor Telemetry Status HUD
            HStack(spacing: 12) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(hasChanges ? Color.orange : Color.green)
                        .frame(width: 7, height: 7)
                    Text(hasChanges ? "Modified" : "Saved")
                        .font(.caption2.bold())
                        .foregroundStyle(hasChanges ? .orange : .secondary)
                }

                Text("Lines: \(lineCount) • Chars: \(text.count)")
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)

                Spacer()

                Text("UTF-8")
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.secondary.opacity(0.05))
        }
        .navigationTitle(fileURL.lastPathComponent)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button(isSaving ? "Saving…" : "Save") { save() }
                    .disabled(!hasChanges || isSaving)
                    .bold()
            }
        }
        .onAppear {
            tabStore.openFile(fileURL)
            load()
        }
    }

    private func load() {
        do {
            let content = try String(contentsOf: fileURL, encoding: .utf8)
            text = content
            loadedText = content
            errorMessage = nil
        } catch {
            errorMessage = "Couldn't read this file: \(error.localizedDescription)"
        }
    }

    private func save() {
        isSaving = true
        do {
            try text.write(to: fileURL, atomically: true, encoding: .utf8)
            loadedText = text
            errorMessage = nil
            if settings.enableHaptics {
                MobileHaptics.medium()
            }
        } catch {
            errorMessage = "Couldn't save: \(error.localizedDescription)"
        }
        isSaving = false
    }
}
