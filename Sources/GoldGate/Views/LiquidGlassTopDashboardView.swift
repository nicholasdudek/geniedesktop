import SwiftUI
import AppKit
import Combine

// MARK: - 🪟 Liquid Glass Top Pull-Down Dashboard View
/// A frosted, high-opacity liquid-glass dashboard sliding down from the top edge of the screen
/// on scroll-up or top-edge gesture, combining a Clock/Date widget, Quick Chat, and Mini Settings.
public struct LiquidGlassTopDashboardView: View {
    @Binding var isPresented: Bool
    let screenSize: CGSize

    @ObservedObject var localModels = LocalModelManager.shared
    @ObservedObject var sleepManager = GenieSleepPreventionManager.shared
    @AppStorage(PrefKey.liquidGlassEnabled) var liquidGlassEnabled: Bool = true
    @AppStorage(PrefKey.showInDock) var showInDock: Bool = true
    @AppStorage(PrefKey.soundEnabled) var soundEnabled: Bool = false
    @AppStorage(PrefKey.agentSandboxEnabled) var agentSandboxEnabled: Bool = true

    @State private var selectedTab: Int = 0 // 0: Quick Chat, 1: Mini Settings, 2: System Telemetry
    @State private var promptText: String = ""
    @State private var currentTime = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    public init(isPresented: Binding<Bool>, screenSize: CGSize) {
        self._isPresented = isPresented
        self.screenSize = screenSize
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Main Dashboard Container
            VStack(spacing: 16) {
                // 1. Header Clock & Dashboard Widget
                headerClockWidget

                // 2. Segmented Pill Tab Switcher
                tabSwitcher

                // 3. Tab Content Pane
                Group {
                    if selectedTab == 0 {
                        quickChatPane
                    } else if selectedTab == 1 {
                        miniSettingsPane
                    } else {
                        systemTelemetryPane
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // 4. Retract Handle & Pull Bar
                retractHandle
            }
            .padding(.horizontal, 24)
            .padding(.top, 18)
            .padding(.bottom, 12)
            .frame(width: min(860, screenSize.width - 48), height: min(540, screenSize.height * 0.72))
            // Frosted Deep Glass Background (less transparent / more frosted)
            .background(
                ZStack {
                    VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow, state: .active)
                    Color.black.opacity(0.68)
                    LinearGradient(
                        colors: [
                            Color.cyan.opacity(0.08),
                            Color.purple.opacity(0.04),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.35),
                                Color.white.opacity(0.12),
                                Color.white.opacity(0.05),
                                Color.white.opacity(0.20)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.0
                    )
            )
            .shadow(color: Color.black.opacity(0.55), radius: 36, x: 0, y: 16)

            Spacer()
        }
        .frame(width: screenSize.width, height: screenSize.height, alignment: .top)
        .padding(.top, 10)
        .onReceive(timer) { input in
            currentTime = input
        }
    }

    // MARK: - 1. Header Clock & Date Widget
    private var headerClockWidget: some View {
        HStack(alignment: .center) {
            // Left: Digital Clock & Date
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(timeString(from: currentTime))
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text(periodString(from: currentTime))
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.cyan)
                }

                Text(dateString(from: currentTime))
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundColor(.white.opacity(0.70))
            }

            Spacer()

            // Center: Telemetry Pills
            HStack(spacing: 8) {
                // Battery
                HStack(spacing: 5) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.green)
                    Text("Ready")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color.white.opacity(0.10)))

                // Sandbox Indicator
                HStack(spacing: 5) {
                    Image(systemName: agentSandboxEnabled ? "shield.lefthalf.filled" : "shield.slash")
                        .font(.system(size: 10))
                        .foregroundColor(agentSandboxEnabled ? .cyan : .orange)
                    Text(agentSandboxEnabled ? "Sandbox ON" : "Unrestricted")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color.white.opacity(0.10)))
            }

            Spacer()

            // Right: Retract Close Button
            Button(action: {
                HapticFeedback.tick()
                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                    isPresented = false
                }
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.85))
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(Color.white.opacity(0.12)))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - 2. Tab Switcher
    private var tabSwitcher: some View {
        HStack(spacing: 6) {
            tabButton(title: "Quick Chat", icon: "bubble.left.and.bubble.right.fill", index: 0)
            tabButton(title: "Mini Settings", icon: "gearshape.fill", index: 1)
            tabButton(title: "System Status", icon: "chart.bar.xaxis", index: 2)
        }
        .padding(3)
        .background(Capsule().fill(Color.white.opacity(0.08)))
    }

    private func tabButton(title: String, icon: String, index: Int) -> some View {
        Button(action: {
            HapticFeedback.tick()
            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                selectedTab = index
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 11))
                Text(title)
                    .font(.system(size: 12, weight: selectedTab == index ? .semibold : .medium))
            }
            .foregroundColor(selectedTab == index ? .black : .white.opacity(0.80))
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(selectedTab == index ? Color.white : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 3. Quick Chat Pane
    private var quickChatPane: some View {
        VStack(spacing: 12) {
            // Suggestion chips
            HStack(spacing: 8) {
                suggestionChip("Summarize Desktop") { promptText = "Summarize the active desktop windows and status." }
                suggestionChip("Open Workspace") { promptText = "Open Genie Workspace in ~/Desktop/Genie/Workspace" }
                suggestionChip("Check System") { promptText = "Report system resource health." }
                Spacer()
            }

            // Input field with send button
            HStack(spacing: 8) {
                TextField("Ask Genie anything...", text: $promptText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
                    .onSubmit {
                        submitPrompt()
                    }

                Button(action: submitPrompt) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 26))
                        .foregroundColor(promptText.isEmpty ? .white.opacity(0.3) : .cyan)
                }
                .buttonStyle(.plain)
                .disabled(promptText.isEmpty)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white.opacity(0.09))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.18), lineWidth: 0.75)
            )

            // AI Model Indicator & Response Preview
            HStack {
                Text("Model: \(localModels.selectedModelDisplayName)")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.55))

                Spacer()

                Button("Open Full Chat ↗") {
                    withAnimation {
                        isPresented = false
                    }
                    FinderChatWindowManager.shared.show(tab: .chat)
                }
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.cyan)
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 8)
    }

    private func suggestionChip(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: {
            HapticFeedback.tick()
            action()
        }) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.85))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color.white.opacity(0.10)))
                .overlay(Capsule().stroke(Color.white.opacity(0.15), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
    }

    private func submitPrompt() {
        guard !promptText.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let text = promptText
        promptText = ""
        HapticFeedback.success()
        localModels.generate(prompt: text)
    }

    // MARK: - 4. Mini Settings Pane
    private var miniSettingsPane: some View {
        VStack(spacing: 10) {
            settingToggleRow(
                title: "Apple Liquid Glass",
                subtitle: "Specular frosted materials across windows and docks",
                icon: "sparkles",
                isOn: $liquidGlassEnabled
            )

            settingToggleRow(
                title: "Agent Sandbox Protection",
                subtitle: "Confine AI agent shell commands to safe workspace folder",
                icon: "shield.checkerboard",
                isOn: $agentSandboxEnabled
            )

            settingToggleRow(
                title: "Show in macOS Dock",
                subtitle: "Keep Genie icon present on Apple's native Dock",
                icon: "dock.rectangle",
                isOn: $showInDock
            )

            settingToggleRow(
                title: "Sleep Prevention (Caffeinate)",
                subtitle: "Prevent display sleep while running background tasks",
                icon: "cup.and.saucer.fill",
                isOn: Binding(
                    get: { sleepManager.isSleepDisabled },
                    set: { _ in sleepManager.toggleSleepPrevention() }
                )
            )

            settingToggleRow(
                title: "Audio Feedback & Sound",
                subtitle: "Haptic and sound effects on desktop navigation",
                icon: "speaker.wave.2.fill",
                isOn: $soundEnabled
            )
        }
        .padding(.vertical, 6)
    }

    private func settingToggleRow(title: String, subtitle: String, icon: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.cyan)
                .frame(width: 24, height: 24)
                .background(Circle().fill(Color.white.opacity(0.08)))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.system(size: 10.5))
                    .foregroundColor(.white.opacity(0.55))
            }

            Spacer()

            Toggle("", isOn: isOn)
                .toggleStyle(SwitchToggleStyle(tint: .cyan))
                .labelsHidden()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white.opacity(0.05)))
    }

    // MARK: - 5. System Telemetry Pane
    private var systemTelemetryPane: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                telemetryCard(title: "Active Screen", value: "\(Int(screenSize.width))×\(Int(screenSize.height))", icon: "display")
                telemetryCard(title: "Workspace Mode", value: "Page 0 / Desktop", icon: "square.grid.2x2")
                telemetryCard(title: "Active Model", value: localModels.selectedModelDisplayName, icon: "cpu")
            }

            HStack(spacing: 12) {
                telemetryCard(title: "Sandbox Folder", value: "~/Desktop/Genie", icon: "folder.fill")
                telemetryCard(title: "Security State", value: agentSandboxEnabled ? "Enforced" : "Permissive", icon: "lock.shield")
                telemetryCard(title: "Sleep Inhibitor", value: sleepManager.isSleepDisabled ? "Active" : "Idle", icon: "powersleep")
            }
        }
        .padding(.vertical, 8)
    }

    private func telemetryCard(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                    .foregroundColor(.cyan)
                Text(title)
                    .font(.system(size: 10.5))
                    .foregroundColor(.white.opacity(0.60))
            }

            Text(value)
                .font(.system(size: 12.5, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.06)))
    }

    // MARK: - 6. Retract Handle
    private var retractHandle: some View {
        Button(action: {
            HapticFeedback.tick()
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                isPresented = false
            }
        }) {
            VStack(spacing: 3) {
                Capsule()
                    .fill(Color.white.opacity(0.35))
                    .frame(width: 36, height: 4)
                Image(systemName: "chevron.up")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.50))
            }
            .padding(.top, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers
    private func timeString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter.string(from: date)
    }

    private func periodString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "a"
        return formatter.string(from: date).uppercased()
    }

    private func dateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: date)
    }
}
