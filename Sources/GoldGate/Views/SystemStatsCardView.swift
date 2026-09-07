import SwiftUI

// MARK: - System Stats & Local Model Safety Card
//
// Live CPU / memory / thermal telemetry with one-tap controls to stop a running local model
// or power the local engine off entirely, so Genie never cooks the Mac during long inference.

public struct SystemStatsCardView: View {
    @ObservedObject private var monitor = SystemThermalMonitor.shared
    @ObservedObject private var models = LocalModelManager.shared
    @AppStorage(PrefKey.appLanguage) private var appLanguage: String = "English (US)"
    @AppStorage(SystemThermalMonitor.autoStopKey) private var autoStopEnabled: Bool = true

    public var compact: Bool = false

    public init(compact: Bool = false) {
        self.compact = compact
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            statRow(icon: "cpu", label: "Mac CPU", value: monitor.systemCPUPercent, unit: "%", tint: tint(for: monitor.systemCPUPercent))
            statRow(icon: "sparkles", label: "Genie CPU", value: monitor.genieCPUPercent, unit: "%", tint: tint(for: monitor.genieCPUPercent))
            memoryRow

            if !compact {
                Divider().opacity(0.35)
                controls
                autoStopRow
                if let stop = monitor.lastAutoStop {
                    Text("⏹ \(monitor.lastAutoStopReason)  ·  \(stop.formatted(date: .omitted, time: .shortened))")
                        .font(.system(size: 9.5))
                        .foregroundColor(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(12)
        .genieLiquidGlass(cornerRadius: 12, tint: (monitor.isOverheating ? Color.red : Color.cyan).opacity(0.22))
    }

    private var header: some View {
        HStack(spacing: 6) {
            Image(systemName: "thermometer.medium")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(monitor.thermalColor)
            Text(LocalizedStrings.translateText("SYSTEM STATS & OVERHEAT GUARD", lang: appLanguage))
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.secondary)
            Spacer()
            Text(monitor.thermalLabel)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(monitor.thermalColor)
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Capsule().fill(monitor.thermalColor.opacity(0.14)))
        }
    }

    private func statRow(icon: String, label: String, value: Double, unit: String, tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Image(systemName: icon).font(.system(size: 10)).foregroundColor(tint)
                Text(LocalizedStrings.translateText(label, lang: appLanguage)).font(.system(size: 11))
                Spacer()
                Text(String(format: "%.0f%@", value, unit))
                    .font(.system(size: 11, weight: .semibold).monospacedDigit())
                    .foregroundColor(tint)
            }
            ProgressView(value: min(100, max(0, value)), total: 100)
                .progressViewStyle(.linear)
                .tint(tint)
                .controlSize(.small)
        }
    }

    private var memoryRow: some View {
        let used = monitor.memoryUsedGB
        let total = max(1, monitor.memoryTotalGB)
        let pct = used / total * 100
        return VStack(alignment: .leading, spacing: 3) {
            HStack {
                Image(systemName: "memorychip").font(.system(size: 10)).foregroundColor(tint(for: pct))
                Text(LocalizedStrings.translateText("Memory", lang: appLanguage)).font(.system(size: 11))
                Spacer()
                Text(String(format: "%.1f / %.0f GB", used, total))
                    .font(.system(size: 11, weight: .semibold).monospacedDigit())
                    .foregroundColor(tint(for: pct))
            }
            ProgressView(value: min(100, max(0, pct)), total: 100)
                .progressViewStyle(.linear)
                .tint(tint(for: pct))
                .controlSize(.small)
        }
    }

    private var controls: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(models.isGenerating ? "Local model running 🔥" : (models.localModelsEnabled ? "Local engine idle 🟢" : "Local engine off ⏻"))
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundColor(models.isGenerating ? .orange : .secondary)
                if models.isGenerating {
                    Text(models.effectiveModel)
                        .font(.system(size: 9.5, design: .monospaced))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            Spacer()
            Button(action: {
                HapticFeedback.heavy()
                monitor.stopLocalModels(disableEngine: false, reason: "Stopped manually from System Stats.")
            }) {
                Label("Stop Model", systemImage: "stop.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(models.isGenerating ? Color.red : Color.red.opacity(0.45)))
            }
            .buttonStyle(.plain)
            .help("Cancel the current local generation and eject models from RAM")

            Button(action: {
                HapticFeedback.heavy()
                monitor.stopLocalModels(disableEngine: true, reason: "Local engine powered off from System Stats.")
            }) {
                Label("Power Off", systemImage: "power")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.red)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 5)
                    .background(Capsule().stroke(Color.red.opacity(0.7), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .help("Stop everything and disable local models until you turn them back on")
            .disabled(!models.localModelsEnabled)
        }
    }

    private var autoStopRow: some View {
        HStack {
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 10))
                .foregroundColor(.cyan)
            Text(LocalizedStrings.translateText("Auto-stop local models when the Mac overheats", lang: appLanguage))
                .font(.system(size: 11))
            Spacer()
            Toggle("", isOn: $autoStopEnabled)
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.mini)
        }
    }

    private func tint(for percent: Double) -> Color {
        switch percent {
        case ..<50: return .green
        case ..<80: return .yellow
        default: return .red
        }
    }
}
