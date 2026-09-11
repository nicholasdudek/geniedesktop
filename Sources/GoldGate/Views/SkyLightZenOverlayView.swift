import AppKit
import SwiftUI

// MARK: - 🧘 SkyLight Full-Screen Adjustable Zen Overlay View
@MainActor
public struct SkyLightZenOverlayView: View {
    @ObservedObject public var manager: SkyLightZenOverlayManager

    @State private var isControlsExpanded: Bool = false
    @State private var breathPhase: BreathPhase = .inhale
    @State private var breathProgress: CGFloat = 0.0
    @State private var breathTimer: Timer?
    @State private var quickPromptText: String = ""

    private enum BreathPhase: String, CaseIterable {
        case inhale = "Inhale..."
        case holdIn = "Hold..."
        case exhale = "Exhale..."
        case holdOut = "Rest..."

        var next: BreathPhase {
            switch self {
            case .inhale: return .holdIn
            case .holdIn: return .exhale
            case .exhale: return .holdOut
            case .holdOut: return .inhale
            }
        }

        var duration: Double { 4.0 }
    }

    public init() {
        self.manager = SkyLightZenOverlayManager.shared
    }

    public init(manager: SkyLightZenOverlayManager) {
        self.manager = manager
    }

    public var body: some View {
        GeometryReader { geo in
            let screenSize = geo.size

            ZStack {
                // 1. Dynamic Background & Living Atmosphere
                backgroundAtmosphereLayer

                // 2. Adjustable Darkening & Vignette Overlay
                Color.black.opacity(manager.opacity)
                    .edgesIgnoringSafeArea(.all)

                // 3. System Vibrancy Blur
                VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow, state: .active)
                    .opacity(min(1.0, manager.blurRadius / 30.0))
                    .edgesIgnoringSafeArea(.all)

                // 4. Subtle Radial Vignette Gradient
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.clear,
                        Color.black.opacity(0.45)
                    ]),
                    center: .center,
                    startRadius: min(screenSize.width, screenSize.height) * 0.25,
                    endRadius: max(screenSize.width, screenSize.height) * 0.70
                )
                .edgesIgnoringSafeArea(.all)
                .allowsHitTesting(false)

                // 5. Main Content Canvas
                VStack(spacing: 0) {
                    // Top Bar: Dismiss, Space Teleport, and Compact Status
                    topHeaderBar
                        .padding(.top, manager.paddingInset > 0 ? 14 : 20)
                        .padding(.horizontal, 24)

                    Spacer()

                    // Center Focus Stage: Breathing Circle + Clock + Focus Timer
                    centerFocusStage(screenSize: screenSize)

                    Spacer()

                    // Bottom Floating Adjustment Dock
                    bottomAdjustmentDock
                        .padding(.bottom, manager.paddingInset > 0 ? 16 : 24)
                        .padding(.horizontal, 20)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: manager.paddingInset > 0 ? (manager.cornerRadius > 0 ? manager.cornerRadius : 28) : 0, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: manager.paddingInset > 0 ? (manager.cornerRadius > 0 ? manager.cornerRadius : 28) : 0, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(manager.paddingInset > 0 ? 0.35 : 0.0),
                                Color.cyan.opacity(manager.paddingInset > 0 ? 0.20 : 0.0),
                                Color.clear
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: manager.paddingInset > 0 ? 1.0 : 0.0
                    )
            )
        }
        .environment(\.colorScheme, .dark)
        .onAppear {
            startBreathingCycle()
        }
        .onDisappear {
            stopBreathingCycle()
        }
    }

    // MARK: - 🌌 Background Atmosphere Layer
    @ViewBuilder
    private var backgroundAtmosphereLayer: some View {
        switch manager.activeTheme {
        case .neuralBloom:
            if let bloomURL = WallpaperManager.shared.resolvedNeuralBloomURL() {
                LiveHTMLWallpaperCanvasView(fileURL: bloomURL, isBackdrop: true)
                    .edgesIgnoringSafeArea(.all)
            } else {
                GenieDefaultLivingAtmosphereView(theme: .apple2028LiquidWater)
                    .edgesIgnoringSafeArea(.all)
            }
        case .liquidWater:
            GenieDefaultLivingAtmosphereView(theme: .apple2028LiquidWater)
                .edgesIgnoringSafeArea(.all)
        case .oledBlackout:
            GenieDefaultLivingAtmosphereView(theme: .apple2028OledPillow)
                .edgesIgnoringSafeArea(.all)
        case .quantumGlass:
            GenieDefaultLivingAtmosphereView(theme: .apple2028QuantumGlass)
                .edgesIgnoringSafeArea(.all)
        case .mysticalAurora:
            GenieDefaultLivingAtmosphereView(theme: .mysticalAurora)
                .edgesIgnoringSafeArea(.all)
        }
    }

    // MARK: - 🔝 Top Header Bar
    private var topHeaderBar: some View {
        HStack(spacing: 12) {
            // SkyLight 2.0 Space Pill Indicator
            HStack(spacing: 6) {
                Circle()
                    .fill(manager.secondSkyLightSpaceID != nil ? Color.green : Color.cyan)
                    .frame(width: 7, height: 7)
                    .shadow(color: manager.secondSkyLightSpaceID != nil ? Color.green : Color.cyan, radius: 4)

                Text(manager.secondSkyLightSpaceID != nil
                     ? "SkyLight Space #\(manager.secondSkyLightSpaceID!) • Isolated"
                     : "SkyLight 2.0 Zen Overlay")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Capsule().fill(Color.black.opacity(0.50)))
            .overlay(Capsule().strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5))

            Spacer()

            // 🌌 Teleport to 2nd SkyLight Space
            Button(action: {
                if manager.secondSkyLightSpaceID != nil {
                    manager.returnToOriginalSpace()
                } else {
                    manager.teleportToSecondSkyLightSpace()
                }
            }) {
                HStack(spacing: 5) {
                    Image(systemName: manager.secondSkyLightSpaceID != nil ? "arrow.uturn.backward" : "server.rack")
                        .font(.system(size: 10, weight: .bold))
                    Text(manager.secondSkyLightSpaceID != nil ? "Return to Prime" : "2nd SkyLight Space")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                }
                .foregroundColor(manager.secondSkyLightSpaceID != nil ? .orange : .cyan)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color.black.opacity(0.55)))
                .overlay(Capsule().strokeBorder(manager.secondSkyLightSpaceID != nil ? Color.orange.opacity(0.5) : Color.cyan.opacity(0.4), lineWidth: 0.6))
            }
            .buttonStyle(GenieMagneticButtonStyle(scale: 1.05))
            .help("Allocate an isolated hardware desktop via SkyLight SLS (Sub-millisecond)")

            // Framing Preset Toggle (Edge-to-Edge vs Framed)
            Button(action: {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                    if manager.paddingInset == 0 {
                        manager.paddingInset = 36.0
                        manager.cornerRadius = 28.0
                    } else {
                        manager.paddingInset = 0.0
                        manager.cornerRadius = 0.0
                    }
                }
                HapticFeedback.selection()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: manager.paddingInset == 0 ? "aspectratio" : "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 10, weight: .bold))
                    Text(manager.paddingInset == 0 ? "Framed Card" : "Full Screen")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white.opacity(0.80))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color.black.opacity(0.50)))
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5))
            }
            .buttonStyle(GenieMagneticButtonStyle(scale: 1.05))
            .help("Toggle between edge-to-edge full screen and floating framed focus card")

            // Close Button (Esc)
            Button(action: {
                manager.hide()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "xmark")
                        .font(.system(size: 9.5, weight: .bold))
                    Text("Exit (Esc)")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white.opacity(0.70))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color.black.opacity(0.50)))
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5))
            }
            .buttonStyle(GenieMagneticButtonStyle(scale: 1.05))
            .keyboardShortcut(.escape, modifiers: [])
            .help("Dismiss Zen Mode Overlay (Esc)")
        }
    }

    // MARK: - 🎯 Center Focus Stage
    private func centerFocusStage(screenSize: CGSize) -> some View {
        VStack(spacing: 20) {
            // Elegant Living Clock & Date
            TimelineView(.periodic(from: .now, by: 1.0)) { timeline in
                VStack(spacing: 4) {
                    Text(timeline.date, format: .dateTime.hour().minute().second())
                        .font(.system(size: 52, weight: .thin, design: .rounded))
                        .foregroundColor(.white.opacity(0.92))
                        .shadow(color: Color.black.opacity(0.60), radius: 12, x: 0, y: 4)

                    Text(timeline.date, format: .dateTime.weekday(.wide).month().day())
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.60))
                        .tracking(1.2)
                }
            }

            // Interactive Mindfulness Breath Circle (Box Breathing)
            if manager.isBreathingGuideActive {
                VStack(spacing: 12) {
                    ZStack {
                        // Outer subtle glow pulse
                        Circle()
                            .fill(
                                RadialGradient(
                                    colors: [Color.cyan.opacity(0.25), Color.clear],
                                    center: .center,
                                    startRadius: 20,
                                    endRadius: 90
                                )
                            )
                            .frame(width: 170, height: 170)
                            .scaleEffect(0.85 + (breathProgress * 0.35))
                            .animation(.easeInOut(duration: 4.0), value: breathProgress)

                        // Core glass sphere
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.cyan.opacity(0.40), Color.indigo.opacity(0.30)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 110, height: 110)
                            .overlay(Circle().strokeBorder(Color.white.opacity(0.40), lineWidth: 1.0))
                            .shadow(color: Color.cyan.opacity(0.50), radius: 16)
                            .scaleEffect(0.85 + (breathProgress * 0.30))
                            .animation(.easeInOut(duration: 4.0), value: breathProgress)

                        VStack(spacing: 2) {
                            Text(breathPhase.rawValue)
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text("Box Breath")
                                .font(.system(size: 9.5, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.60))
                        }
                    }
                    .frame(height: 160)
                }
            }

            // Pomodoro Focus Flow Countdown
            HStack(spacing: 12) {
                Button(action: {
                    manager.toggleFocusTimer()
                    HapticFeedback.selection()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: manager.isFocusTimerRunning ? "pause.fill" : "play.fill")
                            .font(.system(size: 11, weight: .bold))
                        Text(formatTimer(manager.focusSecondsRemaining))
                            .font(.system(size: 15, weight: .bold, design: .monospaced))
                    }
                    .foregroundColor(manager.isFocusTimerRunning ? .cyan : .white.opacity(0.85))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Capsule().fill(Color.black.opacity(0.55)))
                    .overlay(Capsule().strokeBorder(manager.isFocusTimerRunning ? Color.cyan.opacity(0.6) : Color.white.opacity(0.18), lineWidth: 0.8))
                }
                .buttonStyle(GenieMagneticButtonStyle(scale: 1.05))
                .help(manager.isFocusTimerRunning ? "Pause Timer" : "Start Focus Timer")

                if manager.focusSecondsRemaining != 25 * 60 || manager.isFocusTimerRunning {
                    Button(action: {
                        manager.resetFocusTimer(minutes: 25)
                        HapticFeedback.tick()
                    }) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.60))
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(Color.black.opacity(0.50)))
                            .overlay(Circle().strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5))
                    }
                    .buttonStyle(GenieMagneticButtonStyle(scale: 1.05))
                    .help("Reset to 25m")
                }
            }
        }
    }

    // MARK: - 🎛️ Bottom Floating Adjustment Dock
    private var bottomAdjustmentDock: some View {
        VStack(spacing: 10) {
            // Expand / Collapse Drawer Toggle
            Button(action: {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                    isControlsExpanded.toggle()
                }
                HapticFeedback.selection()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: isControlsExpanded ? "chevron.down" : "slider.horizontal.3")
                        .font(.system(size: 11, weight: .bold))
                    Text(isControlsExpanded ? "Hide Adjustments" : "Adjust Zen Atmosphere & Sliders")
                        .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white.opacity(0.85))
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Capsule().fill(Color.black.opacity(0.60)))
                .overlay(Capsule().strokeBorder(Color.white.opacity(0.20), lineWidth: 0.6))
            }
            .buttonStyle(GenieMagneticButtonStyle(scale: 1.04))

            // Expanded Controls Card
            if isControlsExpanded {
                VStack(spacing: 14) {
                    // Sliders Row: Opacity, Blur, Framing Inset, Audio Volume
                    HStack(spacing: 18) {
                        sliderControl(
                            title: "Darkness",
                            icon: "moon.fill",
                            value: $manager.opacity,
                            range: 0.15...0.98,
                            format: "%.0f%%",
                            scaleMultiplier: 100.0
                        )

                        sliderControl(
                            title: "Vibrancy Blur",
                            icon: "drop.fill",
                            value: $manager.blurRadius,
                            range: 0.0...60.0,
                            format: "%.0f pt",
                            scaleMultiplier: 1.0
                        )

                        sliderControl(
                            title: "Framing Inset",
                            icon: "aspectratio",
                            value: Binding(
                                get: { Double(manager.paddingInset) },
                                set: { manager.paddingInset = CGFloat($0) }
                            ),
                            range: 0.0...64.0,
                            format: "%.0f pt",
                            scaleMultiplier: 1.0
                        )

                        sliderControl(
                            title: "Audio Level",
                            icon: "speaker.wave.2.fill",
                            value: $manager.soundVolume,
                            range: 0.0...1.0,
                            format: "%.0f%%",
                            scaleMultiplier: 100.0
                        )
                    }

                    Divider()
                        .background(Color.white.opacity(0.12))

                    // Theme & Soundscape Pickers
                    HStack(spacing: 16) {
                        // Visual Themes
                        HStack(spacing: 6) {
                            Text("Theme:")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.60))

                            ForEach(ZenOverlayTheme.allCases) { theme in
                                Button(action: {
                                    manager.activeTheme = theme
                                    HapticFeedback.selection()
                                }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: theme.icon)
                                            .font(.system(size: 9.5))
                                        Text(theme == .neuralBloom ? "Neural Bloom" : (theme == .liquidWater ? "Liquid" : (theme == .oledBlackout ? "OLED" : (theme == .quantumGlass ? "Glass" : "Aurora"))))
                                            .font(.system(size: 10.5, weight: .medium, design: .rounded))
                                    }
                                    .foregroundColor(manager.activeTheme == theme ? .cyan : .white.opacity(0.70))
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 3.5)
                                    .background(Capsule().fill(manager.activeTheme == theme ? Color.cyan.opacity(0.20) : Color.white.opacity(0.06)))
                                    .overlay(Capsule().strokeBorder(manager.activeTheme == theme ? Color.cyan.opacity(0.55) : Color.white.opacity(0.10), lineWidth: 0.5))
                                }
                                .buttonStyle(GenieMagneticButtonStyle(scale: 1.05))
                            }
                        }

                        Spacer()

                        // Soundscapes
                        HStack(spacing: 6) {
                            Text("Sound:")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.60))

                            ForEach(ZenAmbientSound.allCases) { sound in
                                Button(action: {
                                    manager.activeSound = sound
                                    HapticFeedback.selection()
                                }) {
                                    Image(systemName: sound.icon)
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(manager.activeSound == sound ? .green : .white.opacity(0.60))
                                        .frame(width: 24, height: 24)
                                        .background(Circle().fill(manager.activeSound == sound ? Color.green.opacity(0.20) : Color.white.opacity(0.06)))
                                        .overlay(Circle().strokeBorder(manager.activeSound == sound ? Color.green.opacity(0.55) : Color.white.opacity(0.10), lineWidth: 0.5))
                                }
                                .buttonStyle(GenieMagneticButtonStyle(scale: 1.08))
                                .help(sound.rawValue)
                            }
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(red: 0.08, green: 0.09, blue: 0.12).opacity(0.85))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.7)
                )
                .shadow(color: Color.black.opacity(0.40), radius: 14)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private func sliderControl(
        title: String,
        icon: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        format: String,
        scaleMultiplier: Double
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 9.5))
                    .foregroundColor(.cyan)
                Text(title)
                    .font(.system(size: 10.5, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.70))
                Spacer()
                Text(String(format: format, value.wrappedValue * scaleMultiplier))
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
            }
            Slider(value: value, in: range)
                .accentColor(.cyan)
        }
        .frame(minWidth: 120)
    }

    // MARK: - 🌬️ Breathing Engine
    private func startBreathingCycle() {
        breathTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 4.0)) {
                    self.breathPhase = self.breathPhase.next
                    if self.breathPhase == .inhale {
                        self.breathProgress = 1.0
                    } else if self.breathPhase == .exhale {
                        self.breathProgress = 0.0
                    }
                }
            }
        }
    }

    private func stopBreathingCycle() {
        breathTimer?.invalidate()
        breathTimer = nil
    }

    private func formatTimer(_ totalSeconds: Int) -> String {
        let mins = totalSeconds / 60
        let secs = totalSeconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
