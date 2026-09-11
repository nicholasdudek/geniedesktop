import SwiftUI
import AppKit

// MARK: - 👁️ Adaptive Vision Ergonomics & RAM-to-Render Settings View
public struct AdaptiveErgonomicsSettingsView: View {
    @ObservedObject var engine = AdaptiveVisionErgonomicsEngine.shared
    @State private var manualDistance: Float = 0.45
    @State private var manualFatigue: Float = 0.0

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Banner
                headerBanner

                // Camera & Vision Status
                cameraStatusCard

                // Ergonomic Metrics Grid
                metricsGrid

                // Live Dynamic Typography Preview
                typographyPreviewCard

                // Zero-Copy RAM-Straight-To-Render Telemetry
                ramToRenderCard

                // Manual Ergonomics Overrides
                manualControlCard
            }
            .padding(24)
        }
        .frame(minWidth: 520, minHeight: 600)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    // MARK: - 1. Header Banner
    private var headerBanner: some View {
        HStack(spacing: 16) {
            Image(systemName: "eye.trianglebadge.exclamationmark")
                .font(.system(size: 32))
                .foregroundStyle(LinearGradient(colors: [.orange, .yellow], startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 3)

            VStack(alignment: .leading, spacing: 4) {
                Text("Adaptive Vision & Ergonomics")
                    .font(.title2.bold())
                Text("Camera field of view & eye fatigue tracking adjusts text and screen size dynamically.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Toggle("", isOn: $engine.isAdaptiveErgonomicsEnabled)
                .toggleStyle(.switch)
        }
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.6))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.primary.opacity(0.06), lineWidth: 1))
    }

    // MARK: - 2. Camera Status Card
    private var cameraStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(engine.isCameraActive ? Color.green : (engine.hasCameraPermission ? Color.orange : Color.red))
                    .frame(width: 10, height: 10)
                Text(engine.statusMessage)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                if !engine.hasCameraPermission {
                    Button("Grant Camera Access") {
                        engine.requestCameraPermission()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                } else if engine.isCameraActive {
                    Button("Pause Camera") {
                        engine.stopCameraStream()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                } else {
                    Button("Start Camera") {
                        engine.startCameraStreamIfNeeded()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
            }

            if engine.isCameraActive {
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "camera.fill")
                        Text(engine.cameraDeviceName)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)

                    HStack(spacing: 4) {
                        Image(systemName: engine.faceDetected ? "face.dashed" : "person.crop.circle.badge.questionmark")
                        Text(engine.faceDetected ? "Face Tracked" : "Searching for Face...")
                    }
                    .font(.caption)
                    .foregroundColor(engine.faceDetected ? .green : .secondary)
                }
            }
        }
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.05), lineWidth: 1))
    }

    // MARK: - 3. Metrics Grid
    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            metricBox(
                title: "Field of View / Distance",
                value: String(format: "%.0f%%", engine.userDistanceNormalized * 100),
                sub: engine.userDistanceNormalized > 0.6 ? "Leaning Back (Far)" : (engine.userDistanceNormalized < 0.3 ? "Close (Near)" : "Optimal"),
                icon: "arrow.up.left.and.arrow.down.right",
                color: .blue
            )

            metricBox(
                title: "Fatigue & Tiredness",
                value: String(format: "%.0f%%", engine.tirednessScore * 100),
                sub: engine.tirednessScore > 0.5 ? "Eyestrain Detected" : "Rested & Alert",
                icon: "bed.double.fill",
                color: engine.tirednessScore > 0.5 ? .red : .green
            )

            metricBox(
                title: "Eye Aspect Ratio (EAR)",
                value: String(format: "%.2f", engine.eyeAspectRatio),
                sub: engine.eyeAspectRatio < 0.22 ? "Squinting / Heavy Eyelids" : "Open & Focused",
                icon: "eye.fill",
                color: .orange
            )

            metricBox(
                title: "Blink Rate",
                value: String(format: "%.0f / min", engine.blinkRatePerMinute),
                sub: "Normal: 14–20 / min",
                icon: "waveform.path.ecg",
                color: .purple
            )
        }
    }

    private func metricBox(title: String, value: String, sub: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.title2.bold())
            Text(sub)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.primary.opacity(0.04), lineWidth: 1))
    }

    // MARK: - 4. Live Dynamic Typography Preview
    private var typographyPreviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Dynamic Scaling Output")
                    .font(.subheadline.bold())
                Spacer()
                Text("Text Scale: \(String(format: "%.2fx", engine.dynamicTextScale))")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.accentColor.opacity(0.15))
                    .clipShape(Capsule())
                Text("Contrast: \(String(format: "%.2fx", engine.dynamicContrastBoost))")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.15))
                    .clipShape(Capsule())
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Real-Time Typography Preview")
                    .font(.system(size: 15 * engine.dynamicTextScale, weight: .semibold, design: .default))
                    .foregroundColor(Color.primary.opacity(Double(min(1.0, 0.85 * engine.dynamicContrastBoost))))

                Text("The quick brown fox jumps over the lazy dog. Code editor fonts and UI coordinates dynamically adjust based on your posture and alertness.")
                    .font(.system(size: 12 * engine.dynamicTextScale, weight: .regular, design: .monospaced))
                    .foregroundColor(Color.secondary.opacity(Double(min(1.0, 0.85 * engine.dynamicContrastBoost))))
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(nsColor: .textBackgroundColor).opacity(0.6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.orange.opacity(Double(engine.dynamicCircadianWarmth * 0.15)))
                    )
            )
        }
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.05), lineWidth: 1))
    }

    // MARK: - 5. RAM-Straight-To-Render Telemetry
    private var ramToRenderCard: some View {
        let telemetry = RAMStraightToRenderEngine.shared.telemetry
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "memorychip.fill")
                    .foregroundColor(.cyan)
                Text("Apple Silicon RAM-Straight-To-Render UMA")
                    .font(.subheadline.bold())
                Spacer()
                Text("Storage Mode: Shared")
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("RAM-to-Render Latency")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.2f µs", telemetry.ramToRenderLatencyMicroseconds))
                        .font(.headline.bold())
                        .foregroundColor(.green)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Mapped RAM Buffers")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text("\(telemetry.activeZeroCopyBuffers) Active")
                        .font(.headline.bold())
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Zero-Copy Memory Pool")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f MB", Double(telemetry.totalRAMMappedBytes) / (1024.0 * 1024.0)))
                        .font(.headline.bold())
                }
            }
        }
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.05), lineWidth: 1))
    }

    // MARK: - 6. Manual Control Simulation
    private var manualControlCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Manual Ergonomic Calibration (Simulation Mode)")
                .font(.subheadline.bold())

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Simulate Field of View Distance:")
                        .font(.caption)
                    Spacer()
                    Text(String(format: "%.0f%%", manualDistance * 100))
                        .font(.caption.bold())
                }
                Slider(value: $manualDistance, in: 0.0...1.0) { _ in
                    engine.setManualSimulation(distance: manualDistance, fatigue: manualFatigue)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Simulate Eye Tiredness / Squinting:")
                        .font(.caption)
                    Spacer()
                    Text(String(format: "%.0f%%", manualFatigue * 100))
                        .font(.caption.bold())
                }
                Slider(value: $manualFatigue, in: 0.0...1.0) { _ in
                    engine.setManualSimulation(distance: manualDistance, fatigue: manualFatigue)
                }
            }

            HStack {
                Button("Reset to Defaults") {
                    manualDistance = 0.45
                    manualFatigue = 0.0
                    engine.resetToDefaultScale()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Spacer()

                Button("Test Night Fatigue (+35% Font, +40% Contrast)") {
                    manualDistance = 0.70
                    manualFatigue = 0.85
                    engine.setManualSimulation(distance: manualDistance, fatigue: manualFatigue)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor).opacity(0.4))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.05), lineWidth: 1))
    }
}
