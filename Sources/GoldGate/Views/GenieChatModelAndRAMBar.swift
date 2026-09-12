import AppKit
import Combine
import Foundation
import SwiftUI

// MARK: - 🧠 Genie 2028 Model Selector & RAM Telemetry Bar
/// Provides instantaneous model switching across Apple Silicon unified memory tiers (8GB, 24GB, 96GB),
/// live real-time process & host RAM monitoring, cache purging, and window unification directly within
/// the chat canvas.
public struct GenieChatModelAndRAMBar: View {
    @ObservedObject var localModels = LocalModelManager.shared
    @ObservedObject var governor = GenieMemoryGovernorEngine.shared
    @AppStorage(PrefKey.unifyChatWindow) private var unifyChatWindow: Bool = true
    @State private var isMemoryPopoverPresented: Bool = false
    @State private var copyFeedback: String? = nil
    @State private var timer = Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()

    public init() {}

    private var processResidentGBString: String {
        let gb = Double(governor.currentProcessResidentMB) / 1024.0
        if gb < 0.1 {
            return "\(governor.currentProcessResidentMB) MB"
        }
        return String(format: "%.1f GB", gb)
    }

    private var hostUsedGBString: String {
        let gb = Double(governor.hostUsedMemoryMB) / 1024.0
        return String(format: "%.1f GB", gb)
    }

    private var availableHostGBString: String {
        let gb = Double(governor.hostAvailableMemoryMB) / 1024.0
        return String(format: "%.1f GB", gb)
    }

    public var body: some View {
        HStack(spacing: 8) {
            // 1. 🧠 Instant Model Picker
            modelSelectionMenu

            // 2. ⚡ Live RAM Usage Pill
            ramUsagePill

            // 3. ⏱️ Generation stats over a live Metal field
            GenieMetalStatsHUD()

            Spacer()

            // 4. 📋 Copy & Paste Whole Chat Pills
            chatCopyPastePills

            // 5. 🪟 Unified Window Quick Sync / Popout Button
            unifyWindowButton
        }
        .padding(.horizontal, 4)
        .padding(.vertical, 2)
        .onAppear {
            governor.refreshMemoryTelemetry()
        }
        .onReceive(timer) { _ in
            governor.refreshMemoryTelemetry()
        }
    }

    // MARK: - Model Selection Menu
    private var modelSelectionMenu: some View {
        Menu {
            Section("Apple Silicon Unified Memory Models") {
                ForEach(LocalModelManager.cloudModels) { model in
                    Button(action: {
                        HapticFeedback.selection()
                        localModels.selectModel(model.id)
                    }) {
                        HStack {
                            Text(model.displayName)
                            Text("(\(model.minimumRAMGigabytes) GB RAM • \(model.contextWindow / 1024)k context)")
                            if localModels.effectiveModel == model.id || localModels.effectiveModel == model.name {
                                Text("✓")
                            }
                        }
                    }
                }
            }

            if !localModels.availableModels.isEmpty {
                Section("Local Ollama Engines") {
                    ForEach(localModels.availableModels) { model in
                        Button(action: {
                            HapticFeedback.selection()
                            localModels.selectModel(model.name)
                        }) {
                            HStack {
                                Text(model.displayName)
                                if !model.displaySize.isEmpty {
                                    Text("(\(model.displaySize))")
                                }
                                if localModels.effectiveModel == model.name {
                                    Text("✓")
                                }
                            }
                        }
                    }
                }
            }

            Divider()

            Button(action: {
                FinderChatWindowManager.shared.openTab(.settings)
            }) {
                Label("Configure Models in Settings...", systemImage: "gearshape")
            }
        } label: {
            HStack(spacing: 5) {
                Image(systemName: "cpu")
                    .font(.system(size: 9.5, weight: .bold))
                    .foregroundColor(.cyan)

                Text(localModels.selectedModelDisplayName)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text("\(localModels.activeModelMinimumRAM)GB")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Capsule().fill(Color.cyan.opacity(0.18)))

                Image(systemName: "chevron.down")
                    .font(.system(size: 7, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.08))
            )
            .overlay(
                Capsule()
                    .strokeBorder(Color.white.opacity(0.16), lineWidth: 0.6)
            )
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
        .help("Switch AI Model & RAM Tier")
        .accessibilityLabel("Switch AI Model")
    }

    private var memoryPressureColor: Color {
        switch governor.currentPressureLevel {
        case .critical:
            return .red
        case .warning:
            return .orange
        case .normal:
            return .green
        }
    }

    private var memoryPressureText: String {
        switch governor.currentPressureLevel {
        case .critical:
            return "Critical ⚠️"
        case .warning:
            return "Warning ⚠️"
        case .normal:
            return "Nominal 🟢"
        }
    }

    // MARK: - Live RAM Usage Pill
    private var ramUsagePill: some View {
        Button(action: {
            governor.refreshMemoryTelemetry()
            isMemoryPopoverPresented.toggle()
        }) {
            HStack(spacing: 5) {
                Image(systemName: "memorychip")
                    .font(.system(size: 9.5, weight: .bold))
                    .foregroundColor(memoryPressureColor)

                Text("RAM: \(processResidentGBString) / \(LocalModelManager.detectedRAMString)")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.85))

                Circle()
                    .fill(memoryPressureColor)
                    .frame(width: 5, height: 5)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color.white.opacity(0.06))
            )
            .overlay(
                Capsule()
                    .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.6)
            )
        }
        .buttonStyle(.plain)
        .fixedSize()
        .help("View Memory Telemetry & Purge Caches")
        .popover(isPresented: $isMemoryPopoverPresented, arrowEdge: .top) {
            memoryDetailPopover
        }
    }

    // MARK: - Memory Detail Popover
    private var memoryDetailPopover: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "memorychip.fill")
                    .foregroundColor(.cyan)
                Text("Apple Silicon Memory Telemetry")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }

            Divider().opacity(0.2)

            VStack(alignment: .leading, spacing: 6) {
                memoryRow(title: "Hardware Unified RAM", value: LocalModelManager.detectedRAMString, highlight: true)
                memoryRow(title: "System RAM In-Use", value: "\(hostUsedGBString) / \(LocalModelManager.detectedRAMString)", highlight: false)
                memoryRow(title: "System Available RAM", value: availableHostGBString, highlight: false)
                memoryRow(title: "Genie App Resident", value: processResidentGBString, highlight: false)
                memoryRow(title: "Active Model Target", value: "\(localModels.activeModelMinimumRAM) GB recommended", highlight: false)
                memoryRow(title: "Memory Pressure", value: memoryPressureText, highlight: false)
                memoryRow(title: "Idle Leak Health", value: governor.idleStatusDescription, highlight: false)
            }

            Divider().opacity(0.2)

            HStack {
                Button(action: {
                    governor.purgeVolatileCaches()
                    governor.refreshMemoryTelemetry()
                    HapticFeedback.selection()
                }) {
                    Label("Purge Caches & Free RAM", systemImage: "arrow.triangle.2.circlepath")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.cyan)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.cyan.opacity(0.16)))
                }
                .buttonStyle(.plain)

                Spacer()

                Button("Done") {
                    isMemoryPopoverPresented = false
                }
                .buttonStyle(.plain)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(14)
        .frame(width: 280)
        .background(Color(red: 0.08, green: 0.10, blue: 0.14).opacity(0.96))
    }

    private func memoryRow(title: String, value: String, highlight: Bool) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 10.5, weight: .regular))
                .foregroundColor(.white.opacity(0.65))
            Spacer()
            Text(value)
                .font(.system(size: 10.5, weight: highlight ? .bold : .semibold, design: .monospaced))
                .foregroundColor(highlight ? .cyan : .white)
        }
    }

    // MARK: - 📋 Copy & Paste Whole Chat Pills
    private var chatCopyPastePills: some View {
        HStack(spacing: 4) {
            Button(action: {
                if localModels.copyWholeChat() {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        copyFeedback = "Copied!"
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                        withAnimation { copyFeedback = nil }
                    }
                }
            }) {
                HStack(spacing: 3) {
                    Image(systemName: copyFeedback != nil ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(copyFeedback != nil ? .green : .white.opacity(0.8))
                    Text(copyFeedback ?? "Copy")
                        .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                        .foregroundColor(copyFeedback != nil ? .green : .white.opacity(0.85))
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3.5)
                .background(Capsule().fill(Color.white.opacity(0.06)))
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5))
            }
            .buttonStyle(.plain)
            .help("Copy Whole Chat to Clipboard (⌘⇧C)")

            Button(action: {
                let res = localModels.pasteWholeChat()
                if res.success {
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                        copyFeedback = "Pasted \(res.count)!"
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                        withAnimation { copyFeedback = nil }
                    }
                }
            }) {
                HStack(spacing: 3) {
                    Image(systemName: "doc.on.clipboard")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.cyan)
                    Text("Paste")
                        .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                        .foregroundColor(.cyan)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 3.5)
                .background(Capsule().fill(Color.cyan.opacity(0.12)))
                .overlay(Capsule().strokeBorder(Color.cyan.opacity(0.28), lineWidth: 0.5))
            }
            .buttonStyle(.plain)
            .help("Paste Whole Chat from Clipboard (⌘⇧V)")
        }
    }

    // MARK: - Unified Window Button
    private var unifyWindowButton: some View {
        Button(action: {
            HapticFeedback.selection()
            FinderChatWindowManager.shared.show(tab: .chat)
            (NSApp.delegate as? AppDelegate)?.dismissMenuBarPopover()
        }) {
            HStack(spacing: 4) {
                Image(systemName: "arrow.up.forward.and.arrow.down.backward")
                    .font(.system(size: 8.5, weight: .bold))
                Text("Unified Window")
                    .font(.system(size: 9.5, weight: .semibold, design: .rounded))
            }
            .foregroundColor(.white.opacity(0.70))
            .padding(.horizontal, 7)
            .padding(.vertical, 3.5)
            .background(Capsule().fill(Color.white.opacity(0.06)))
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
        .help("Focus Single Unified Genie Chat Window")
    }
}
