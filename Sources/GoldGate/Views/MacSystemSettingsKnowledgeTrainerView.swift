import AppKit
import SwiftUI

// MARK: - 🧠 Mac System Settings & Shortcuts Knowledge Trainer View
public struct MacSystemSettingsKnowledgeTrainerView: View {
    @ObservedObject var trainer = MacSystemSettingsKnowledgeTrainer.shared
    @ObservedObject var editorBridge = AIEditorBridgeEngine.shared
    @ObservedObject var localModels = LocalModelManager.shared

    @State private var searchQuery: String = ""
    @State private var selectedCategory: String = "All"
    @State private var commandExecutionFeedback: String? = nil
    @State private var isExecutingCommand: Bool = false

    private let categories = ["All", "System Settings", "Keyboard Shortcut", "defaults Command", "SkyLight API"]

    public init() {}

    public var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 18) {
                // ── Top Header & Hero Card ──────────────────────────────────
                trainingHeroCard

                // ── Watch AI Create Files Live (Interactive Demo) ───────────
                watchAICreateFilesSection

                // ── Knowledge Base Search & Category Filters ────────────────
                knowledgeSearchAndFilterBar

                // ── Knowledge Cards Grid / List ─────────────────────────────
                knowledgeItemsList
            }
            .padding(18)
        }
        .background(Color(red: 0.09, green: 0.10, blue: 0.13))
    }

    // MARK: - 1. Training Hero Card
    private var trainingHeroCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Animated Brain / Chip Icon
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [Color.cyan.opacity(0.35), Color.purple.opacity(0.35)], startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 48, height: 48)

                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(colors: [Color.cyan, Color.purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text("Mac System Settings & Shortcuts Knowledge Engine")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text("100% Offline / Local")
                            .font(.system(size: 9.5, weight: .semibold, design: .monospaced))
                            .foregroundColor(.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.green.opacity(0.15)))
                    }

                    Text("Trained on all macOS System Settings panes, global shortcuts, defaults CLI commands, and SkyLight window APIs.")
                        .font(.system(size: 11.5))
                        .foregroundColor(.white.opacity(0.70))
                }

                Spacer()

                // Training Trigger Button
                Button(action: {
                    trainer.trainLocalModelOnMacKnowledge(epochs: 50)
                }) {
                    HStack(spacing: 6) {
                        if trainer.isTraining {
                            ProgressView()
                                .scaleEffect(0.65)
                        } else {
                            Image(systemName: "sparkles")
                                .font(.system(size: 11, weight: .bold))
                        }
                        Text(trainer.isTraining ? "Training Model..." : "Train / Ingest Now ⚡️")
                            .font(.system(size: 11.5, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .shadow(color: Color.purple.opacity(0.4), radius: 8, y: 2)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(trainer.isTraining)
            }

            // Training Status & Progress Bar
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(trainer.activeTrainingStepDescription)
                        .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                        .foregroundColor(.cyan)

                    Spacer()

                    Text("Loss: \(String(format: "%.4f", trainer.trainingLoss)) • Epoch \(trainer.currentEpoch)/\(trainer.totalEpochs)")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(.secondary)
                }

                ProgressView(value: trainer.trainingProgress)
                    .tint(Color.cyan)
                    .scaleEffect(x: 1, y: 0.8)
            }
            .padding(10)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.35)))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(red: 0.13, green: 0.14, blue: 0.18))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 0.8))
        )
    }

    // MARK: - 2. Watch AI Create Files Section (Interactive Demo)
    private var watchAICreateFilesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "curlybraces.square.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.orange)

                Text("Watch AI Create & Stream Files Live in VS Code Editor")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Spacer()

                if editorBridge.isStreamingToEditor {
                    HStack(spacing: 5) {
                        Circle().fill(Color.green).frame(width: 6, height: 6)
                        Text("Live Typing Active")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.green.opacity(0.15)))
                }
            }

            Text("Ask the chat model to write code or click any template below to watch Genie stream character-by-character into the live Monaco editor and save to disk.")
                .font(.system(size: 11))
                .foregroundColor(.secondary)

            // Quick Demo Buttons
            HStack(spacing: 8) {
                demoFileButton(
                    title: "SwiftUI Glass Card",
                    filename: "GlassmorphicCardView.swift",
                    icon: "swift",
                    color: .orange,
                    snippet: """
import SwiftUI

// MARK: - 🪟 Authentic Apple Liquid Glass Card Component
public struct GlassmorphicCardView: View {
    public var title: String = "Genie Neural Space"
    public var subtitle: String = "Real-time SkyLight Compositor"
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.cyan)
                Text(title)
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Text("PRO")
                    .font(.system(size: 9, weight: .heavy, design: .monospaced))
                    .foregroundColor(.yellow)
            }
            
            Text(subtitle)
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.70))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.12))
                .shadow(color: Color.black.opacity(0.35), radius: 12, y: 6)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(LinearGradient(colors: [Color.white.opacity(0.4), Color.clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
        )
        .frame(width: 280)
    }
}
"""
                )

                demoFileButton(
                    title: "Python Mac System Monitor",
                    filename: "mac_system_monitor.py",
                    icon: "chevron.left.forwardslash.chevron.right",
                    color: .cyan,
                    snippet: """
import subprocess
import json
import os

def get_mac_system_telemetry():
    \"\"\"Query macOS thermal state, battery level, and active apps.\"\"\"
    print("🧠 Ingesting macOS System Telemetry...")
    
    # 1. Query Battery percentage via pmset
    pmset_out = subprocess.check_output(["pmset", "-g", "batt"]).decode('utf-8')
    print(f"🔋 Power Status:\\n{pmset_out}")
    
    # 2. Query System Profiler Hardware Data
    try:
        hw_out = subprocess.check_output(["system_profiler", "SPHardwareDataType", "-json"]).decode('utf-8')
        hw_data = json.loads(hw_out)
        print("💻 Hardware Profile Loaded Successfully.")
    except Exception as e:
        print(f"Error querying hardware: {e}")

if __name__ == '__main__':
    get_mac_system_telemetry()
"""
                )

                demoFileButton(
                    title: "Shell Developer Setup",
                    filename: "setup_mac_developer_tweaks.sh",
                    icon: "terminal.fill",
                    color: .mint,
                    snippet: """
#!/bin/zsh
# 🚀 Instant Developer Speed Boost for macOS

echo "⚡️ Setting maximum key repeat speed..."
defaults write NSGlobalDomain KeyRepeat -int 1
defaults write NSGlobalDomain InitialKeyRepeat -int 10

echo "⚡️ Setting instant Dock auto-hide animation..."
defaults write com.apple.dock autohide-time-modifier -float 0.15
defaults write com.apple.dock autohide-delay -float 0

echo "📂 Showing hidden files in Finder..."
defaults write com.apple.finder AppleShowAllFiles -bool true

killall Dock
killall Finder
echo "✅ All macOS Developer Tweaks Applied Successfully!"
"""
                )
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(red: 0.12, green: 0.13, blue: 0.16))
                .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Color.white.opacity(0.10), lineWidth: 0.6))
        )
    }

    private func demoFileButton(title: String, filename: String, icon: String, color: Color, snippet: String) -> some View {
        Button(action: {
            HapticFeedback.heavy()
            editorBridge.streamCodeToFile(
                filename: filename,
                content: snippet,
                language: filename.hasSuffix(".swift") ? "Swift" : (filename.hasSuffix(".py") ? "Python" : "Shell"),
                openEditor: true
            )
            // Post switch to editor tab
            NotificationCenter.default.post(name: NSNotification.Name("NexusOpenEmbeddedEditor"), object: nil)
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(color)

                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    Text(filename)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Image(systemName: "arrow.right.circle.fill")
                    .font(.system(size: 12))
                    .foregroundColor(color.opacity(0.8))
            }
            .padding(8)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.06)))
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(color.opacity(0.25), lineWidth: 0.5))
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - 3. Knowledge Search & Filter Bar
    private var knowledgeSearchAndFilterBar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                    TextField("Search all Mac shortcuts, system settings, or defaults commands...", text: $searchQuery)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 12))
                        .foregroundColor(.white)

                    if !searchQuery.isEmpty {
                        Button(action: { searchQuery = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.07)))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.12), lineWidth: 0.6))

                Spacer()

                // Category Filter Pills
                HStack(spacing: 4) {
                    ForEach(categories, id: \.self) { cat in
                        let isSelected = selectedCategory == cat
                        Button(action: {
                            selectedCategory = cat
                            HapticFeedback.playClickSound()
                        }) {
                            Text(cat)
                                .font(.system(size: 10, weight: isSelected ? .bold : .medium, design: .rounded))
                                .foregroundColor(isSelected ? .white : .secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(isSelected ? Color.blue.opacity(0.35) : Color.white.opacity(0.05)))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }

    // MARK: - 4. Knowledge Items List
    private var filteredItems: [MacKnowledgeItem] {
        var items = trainer.knowledgeItems
        if selectedCategory != "All" {
            items = items.filter { $0.category == selectedCategory }
        }
        if !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let q = searchQuery.lowercased()
            items = items.filter { item in
                item.title.lowercased().contains(q) ||
                item.description.lowercased().contains(q) ||
                (item.shortcut?.lowercased().contains(q) ?? false) ||
                item.keywords.contains { $0.lowercased().contains(q) }
            }
        }
        return items
    }

    private var knowledgeItemsList: some View {
        VStack(spacing: 10) {
            ForEach(filteredItems) { item in
                knowledgeItemCard(item: item)
            }
        }
    }

    private func knowledgeItemCard(item: MacKnowledgeItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                // Category Badge
                Text(item.category)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.cyan.opacity(0.15)))

                Text(item.title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)

                Spacer()

                // Shortcut Pill (if present)
                if let sc = item.shortcut {
                    Text(sc)
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.yellow.opacity(0.15)))
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.yellow.opacity(0.3), lineWidth: 0.5))
                }

                // 1-Click Open Setting Button
                if let url = item.urlScheme {
                    Button(action: {
                        trainer.openSettingsPane(urlScheme: url)
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "arrow.up.forward.app")
                                .font(.system(size: 9, weight: .bold))
                            Text("Open Setting")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundColor(.cyan)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3.5)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.cyan.opacity(0.18)))
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                // 1-Click Run Defaults Command Button
                if let cmd = item.command, item.category == "defaults Command" {
                    Button(action: {
                        Task {
                            let (out, ok) = await trainer.executeDefaultsTweak(command: cmd)
                            await MainActor.run {
                                commandExecutionFeedback = ok ? "Applied tweak successfully! ✅" : "Error: \(out)"
                                HapticFeedback.success()
                            }
                        }
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 9, weight: .bold))
                            Text("Apply Tweak ⚡️")
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3.5)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.orange.opacity(0.18)))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }

            Text(item.description)
                .font(.system(size: 11.5))
                .foregroundColor(.white.opacity(0.75))

            if let cmd = item.command {
                HStack {
                    Text(cmd)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    Spacer()
                    Button(action: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(cmd, forType: .string)
                        HapticFeedback.playClickSound()
                    }) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("Copy command")
                }
                .padding(6)
                .background(RoundedRectangle(cornerRadius: 5).fill(Color.black.opacity(0.3)))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(red: 0.12, green: 0.13, blue: 0.16))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.white.opacity(0.08), lineWidth: 0.5))
        )
    }
}
