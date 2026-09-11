import AppKit
import SwiftUI
import Combine

// MARK: - ⚡️ Top Dock Neural Engine Banner View
/// Renders the retro-futuristic ASCII / block-art Neural Engine terminal banner
/// directly in the Top Dock (LiquidGlassTopDashboardView / LiquidGlassMiniDockView).
/// Faithfully reproduces the Apple Silicon Metal-accelerated block typography.
@MainActor
public struct GenieTopDockNeuralEngineBannerView: View {
    public var heroMode: Bool = false

    @ObservedObject private var appTrainer = GenieAppTrainerEngine.shared
    @State private var isGlowActive: Bool = false
    @State private var caretVisible: Bool = true
    @State private var timeMode: String = "MORNING"
    @State private var blockGlowPulse: Double = 0.0
    @State private var starFloat: CGFloat = 0.0

    private let timer = Timer.publish(every: 0.6, on: .main, in: .common).autoconnect()

    public init(heroMode: Bool = false) {
        self.heroMode = heroMode
    }

    private var currentTimeMode: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<5: return "LATE NIGHT"
        case 5..<12: return "MORNING"
        case 12..<17: return "AFTERNOON"
        case 17..<22: return "EVENING"
        default: return "NIGHT"
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: heroMode ? 8 : 5) {
            // ── The Retro Terminal ASCII Border Box ──
            HStack(alignment: .center, spacing: heroMode ? 32 : 24) {
                // Left: 8-Bit Mario Block "G E N I E"
                HStack(spacing: 8) {
                    if heroMode {
                        Text("★")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(Color(red: 1.0, green: 0.90, blue: 0.0))
                            .offset(y: starFloat)
                    }

                    VStack(alignment: .leading, spacing: heroMode ? 3 : 2) {
                        Text("████   █████  ██   ██  ██  █████")
                        Text("█      █      ███  ██  ██  █    ")
                        Text("█  ██  ████   ██ █ ██  ██  ████ ")
                        Text("█   █  █      ██  ███  ██  █    ")
                        Text("█████  █████  ██   ██  ██  █████")
                    }
                    .font(.system(size: heroMode ? 13.5 : 10, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
                    .shadow(color: Color.white.opacity(heroMode ? 0.85 : 0.45), radius: heroMode ? 8 : 4)
                    .shadow(color: Color.cyan.opacity(heroMode ? 0.60 : 0.20), radius: heroMode ? 12 : 6)

                    if heroMode {
                        Text("✦")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color(red: 0.0, green: 0.95, blue: 1.0))
                            .offset(y: -starFloat)
                    }
                }

                // Right: System Capabilities Badges & Mac App Training Status
                VStack(alignment: .leading, spacing: heroMode ? 4.5 : 3.5) {
                    HStack(spacing: 6) {
                        Text("⚡")
                            .foregroundColor(.yellow)
                        Text(heroMode ? "GENIE MARIO 8-BIT STUDIO" : "GENIE STUDIO")
                            .foregroundColor(.white)

                        if heroMode {
                            Text("PRO")
                                .font(.system(size: 8, weight: .black, design: .monospaced))
                                .padding(.horizontal, 4)
                                .padding(.vertical, 1)
                                .background(Capsule().fill(Color.yellow.opacity(0.3)))
                                .foregroundColor(.yellow)
                        }
                    }

                    // 🧠 Trained Mac Apps Live Badge
                    Button(action: {
                        HapticFeedback.selection()
                        Task {
                            await appTrainer.trainOnInstalledMacApps()
                        }
                    }) {
                        HStack(spacing: 5) {
                            if appTrainer.isTraining {
                                ProgressView()
                                    .scaleEffect(0.6)
                                    .frame(width: 10, height: 10)
                            } else {
                                Text("◈")
                                    .foregroundColor(.cyan)
                            }
                            Text(appTrainer.isTraining ? "TRAINING APPS..." : "TRAINED ON \(appTrainer.trainedApps.count) MAC APPS")
                                .foregroundColor(.cyan)
                                .underline(heroMode)
                        }
                    }
                    .buttonStyle(.plain)
                    .help("Genie is trained on every local application on this Mac. Click to refresh & re-train.")

                    HStack(spacing: 5) {
                        Text("✦")
                            .foregroundColor(.green)
                        Text("APPLE SILICON • ZERO LATENCY")
                            .foregroundColor(.white.opacity(0.95))
                    }
                }
                .font(.system(size: heroMode ? 10.5 : 9.5, weight: .bold, design: .monospaced))
            }
            .padding(.horizontal, heroMode ? 18 : 14)
            .padding(.vertical, heroMode ? 12 : 8)
            .background(
                ZStack {
                    Color.black.opacity(heroMode ? 0.50 : 0.35)
                    if heroMode {
                        LinearGradient(
                            colors: [Color.cyan.opacity(0.08), Color.purple.opacity(0.05), Color.clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                }
            )
            .overlay(
                Rectangle()
                    .stroke(
                        heroMode ? Color.cyan.opacity(0.60) : Color.white.opacity(0.40),
                        lineWidth: heroMode ? 1.5 : 1.0
                    )
            )

            // ── Sub-Banner: Neural Engine Hardware Acceleration Line ──
            HStack(spacing: 4) {
                Text(">>> GENIE STUDIO // ARM64 // METAL ACCELERATED // \(timeMode) // APPS: \(appTrainer.trainedApps.count) TRAINED")
                    .font(.system(size: heroMode ? 10.5 : 9.5, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.90))

                Text(caretVisible ? "█" : " ")
                    .font(.system(size: heroMode ? 10.5 : 9.5, weight: .bold, design: .monospaced))
                    .foregroundColor(.green)
            }
            .padding(.leading, 2)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .onTapGesture {
            HapticFeedback.selection()
            NotificationCenter.default.post(name: NSNotification.Name("NexusSelectTopDockChat"), object: nil)
        }
        .help("Genie Studio • Click to focus Chat & Intelligence")
        .onAppear {
            timeMode = currentTimeMode
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                starFloat = 3.0
            }
        }
        .onReceive(timer) { _ in
            caretVisible.toggle()
            timeMode = currentTimeMode
        }
    }
}
