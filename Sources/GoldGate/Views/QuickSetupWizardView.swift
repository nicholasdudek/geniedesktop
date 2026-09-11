import SwiftUI
import AppKit

// MARK: - Compact First-Install Walkthrough & Quick Setup Wizard

struct QuickSetupWizardView: View {
    @AppStorage(PrefKey.appLanguage) var appLanguage: String = "English (US)"
    @Binding var isPresented: Bool

    @AppStorage(PrefKey.appFormation) var appFormation: String = "Responsive Grid"
    @AppStorage(PrefKey.gridTransitionDirection) var gridTransitionDirection: String = "Pull Up from Bottom"
    @AppStorage(PrefKey.soundEnabled) var soundEnabled: Bool = true
    @AppStorage(PrefKey.hapticsEnabled) var hapticsEnabled: Bool = true
    @AppStorage(PrefKey.hasCompletedInitialSetup) var hasCompletedInitialSetup: Bool = false
    @AppStorage(PrefKey.permissionsAskedAtLogin) var permissionsAskedAtLogin: Bool = false

    @State private var accessibilityGranted: Bool = AXIsProcessTrusted()
    @State private var screenGranted: Bool = CGPreflightScreenCaptureAccess()
    @State private var selectedFormation: String = "Responsive Grid"
    @State private var selectedTransition: String = "Pull Up from Bottom"
    @State private var soundChoice: Bool = true
    @State private var permTimer: Timer? = nil

    @ObservedObject private var tinyEngine = GenieLocalTinyModelEngine.shared
    @State private var showInstallEngineConfirm = false
    @State private var autoPullAfterOllamaLaunch = false
    /// Smallest model marked `isRecommended` in the curated catalog — see
    /// GenieLocalTinyModelEngine.swift. Picked here (not genie-master) because
    /// it's pulled by tag over HTTP in seconds-to-minutes, not a local
    /// `ollama create` build of a 27B model, which would make this step a
    /// many-GB, many-minute blocker on first launch.
    private static let recommendedModelID = "qwen3.5:2b"
    private var recommendedModel: FreeLocalModelCard? {
        tinyEngine.curatedFreeModels.first(where: { $0.id == Self.recommendedModelID })
    }

    private let formationsList: [(id: String, title: String, subtitle: String, icon: String)] = [
        ("Responsive Grid", "Responsive Grid", "Springboard matrix", "square.grid.3x3.fill"),
        ("Fibonacci Spiral Galaxy 🌀", "Fibonacci Spiral", "Golden ratio galaxy", "circle.hexagongrid.fill"),
        ("Floating Lotus Array 🪷", "Floating Lotus", "Concentric petals", "camera.macro"),
        ("Bottom Shelf 🪵", "Bottom Shelf", "Clean lower dock", "menubar.dock.rectangle")
    ]

    var body: some View {
        ZStack {
            // Ambient frosted dark backdrop
            Color.black.opacity(0.60)
                .edgesIgnoringSafeArea(.all)
                .onTapGesture {
                    // Prevent accidental dismissal until user finishes
                }

            // Compact Apple-style frosted modal card
            VStack(spacing: 12) {
                // Header Bar
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(LinearGradient(
                                colors: [Color.orange, Color.purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 32, height: 32)
                        Text("🪔")
                            .font(.system(size: 18))
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(LocalizedStrings.translateText("Welcome to Genie", lang: appLanguage))
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        Text(LocalizedStrings.translateText("Quick Setup · Tailor your spatial workspace", lang: appLanguage))
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button(action: { finishSetup() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                    .help("Skip setup")
                }
                .padding(.bottom, 2)

                Divider().opacity(0.3)

                // ── 0. Language & Region Selection (10 Languages) ──
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: "globe")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.blue)
                        Text(LocalizedStrings.translateText("Language & Region", lang: appLanguage))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.primary)
                        Spacer()
                        Picker("", selection: $appLanguage) {
                            ForEach(AppLanguage.allCases) { lang in
                                Text("\(lang.flag) \(lang.rawValue)").tag(lang.rawValue)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 175)
                        .onChange(of: appLanguage) { _, newLang in
                            HapticFeedback.selection()
                            UserDefaults.standard.set(newLang, forKey: PrefKey.appLanguage)
                            NotificationCenter.default.post(name: UserDefaults.didChangeNotification, object: nil)
                            NotificationCenter.default.post(name: NSNotification.Name("NexusLanguageChanged"), object: newLang)
                        }
                    }
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.primary.opacity(0.04)))

                // ── 1. Permissions (Only Asked Once at Login) ──
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(allPermissionsGranted ? .green : .orange)
                        Text(LocalizedStrings.translateText("System Permissions (Prompted Once)", lang: appLanguage))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.primary)
                        Spacer()
                        if allPermissionsGranted {
                            HStack(spacing: 3) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 10))
                                Text("Ready")
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .foregroundColor(.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.green.opacity(0.15)))
                        }
                    }

                    // Accessibility row
                    HStack(spacing: 8) {
                        Image(systemName: accessibilityGranted ? "checkmark.circle.fill" : "hand.raised.fill")
                            .font(.system(size: 11))
                            .foregroundColor(accessibilityGranted ? .green : .orange)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Accessibility Control")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.primary.opacity(0.9))
                            Text("Enables window snapping, app switching, and gesture tracking.")
                                .font(.system(size: 8.5))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if !accessibilityGranted {
                            Button(action: {
                                HapticFeedback.selection()
                                PermissionsManager.shared.requestAccessibility()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                    checkPermissions()
                                }
                            }) {
                                Text("Authorize")
                                    .font(.system(size: 9.5, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.blue))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    // Screen Recording row
                    HStack(spacing: 8) {
                        Image(systemName: screenGranted ? "checkmark.circle.fill" : "rectangle.dashed.badge.record")
                            .font(.system(size: 11))
                            .foregroundColor(screenGranted ? .green : .cyan)
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Screen Overlay & Atmosphere")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.primary.opacity(0.9))
                            Text("Powers liquid glass desktop reflections and shader atmosphere.")
                                .font(.system(size: 8.5))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        if !screenGranted {
                            Button(action: {
                                HapticFeedback.selection()
                                PermissionsManager.shared.requestScreenCapture()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                                    checkPermissions()
                                }
                            }) {
                                Text("Authorize")
                                    .font(.system(size: 9.5, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.cyan.opacity(0.85)))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.primary.opacity(0.04)))

                // ── 1b. AI Engine (Full Local Model Suite) ──
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(tinyEngine.isOllamaRunning ? .green : .purple)
                        Text("Genie's AI Engine")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.primary)
                        Spacer()

                        if tinyEngine.downloadingModelId == Self.recommendedModelID {
                            ProgressView(value: tinyEngine.downloadProgress)
                                .frame(width: 70)
                        } else if tinyEngine.isOllamaRunning {
                            HStack(spacing: 3) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 10))
                                Text("Ready")
                                    .font(.system(size: 10, weight: .medium))
                            }
                            .foregroundColor(.green)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.green.opacity(0.15)))
                        } else {
                            Button(action: {
                                HapticFeedback.selection()
                                showInstallEngineConfirm = true
                            }) {
                                Text(GenieCapabilities.canInstallExternalRuntimes ? "Install" : "Get Ollama")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(Color.purple))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Text("Runs fully on this Mac via Ollama — nothing leaves your machine. This pulls \(recommendedModel?.name ?? "Genie's recommended model") (\(recommendedModel?.displayDiskSize ?? "~2.7 GB")). You can skip this and set it up later from Settings > Models & Providers.")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                        .lineLimit(3)
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(Color.primary.opacity(0.04)))
                .confirmationDialog(
                    "Install Genie's AI Engine?",
                    isPresented: $showInstallEngineConfirm,
                    titleVisibility: .visible
                ) {
                    Button("Install (\(recommendedModel?.displayDiskSize ?? "~2.7 GB"))") {
                        beginEngineInstall()
                    }
                    Button("Not Now", role: .cancel) {}
                } message: {
                    Text("Downloads Ollama and \(recommendedModel?.name ?? "a local model") so Genie can run AI fully on this Mac. Uninstall or switch models anytime in Settings.")
                }

                // ── 2. Formation Style to Choose ──
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Image(systemName: "square.grid.2x2.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.cyan)
                        Text(LocalizedStrings.translateText("Choose App Formation", lang: appLanguage))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.primary)
                    }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                        ForEach(formationsList, id: \.id) { item in
                            let isSelected = (selectedFormation == item.id)
                            Button(action: {
                                HapticFeedback.selection()
                                selectedFormation = item.id
                                appFormation = item.id
                                NotificationCenter.default.post(name: NSNotification.Name("NexusFormationChanged"), object: item.id)
                            }) {
                                HStack(spacing: 7) {
                                    Image(systemName: item.icon)
                                        .font(.system(size: 13))
                                        .foregroundColor(isSelected ? .cyan : .secondary)
                                        .frame(width: 20)

                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(item.title)
                                            .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                                            .foregroundColor(isSelected ? .cyan : .primary)
                                            .lineLimit(1)
                                        Text(item.subtitle)
                                            .font(.system(size: 8))
                                            .foregroundColor(.secondary)
                                            .lineLimit(1)
                                    }

                                    Spacer(minLength: 2)

                                    if isSelected {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 10))
                                            .foregroundColor(.cyan)
                                    }
                                }
                                .padding(.horizontal, 8)
                                .padding(.vertical, 7)
                                .background(
                                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                                        .fill(isSelected ? Color.cyan.opacity(0.14) : Color.primary.opacity(0.03))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                                        .stroke(isSelected ? Color.cyan.opacity(0.7) : Color.primary.opacity(0.08), lineWidth: isSelected ? 1.2 : 0.5)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // ── 3. Summon Transition & Sound Effects ──
                HStack(spacing: 8) {
                    // Slide-Up Transition Choice
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Summon Motion")
                            .font(.system(size: 9.5, weight: .semibold))
                            .foregroundColor(.secondary)

                        HStack(spacing: 4) {
                            transitionPill(
                                title: "⬆️ Slide Up",
                                isSelected: selectedTransition == "Pull Up from Bottom"
                            ) {
                                selectedTransition = "Pull Up from Bottom"
                                gridTransitionDirection = "Pull Up from Bottom"
                            }

                            transitionPill(
                                title: "📱 From Right",
                                isSelected: selectedTransition == "Slide from Right (iPhone Mode 📱)"
                            ) {
                                selectedTransition = "Slide from Right (iPhone Mode 📱)"
                                gridTransitionDirection = "Slide from Right (iPhone Mode 📱)"
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    // Sound Toggle Choice
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Audio & Haptics")
                            .font(.system(size: 9.5, weight: .semibold))
                            .foregroundColor(.secondary)

                        HStack(spacing: 4) {
                            transitionPill(
                                title: "🔊 On",
                                isSelected: soundChoice
                            ) {
                                soundChoice = true
                                HapticFeedback.selection()
                            }

                            transitionPill(
                                title: "🔇 Mute",
                                isSelected: !soundChoice
                            ) {
                                soundChoice = false
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.top, 2)

                // ── 4. Finish Setup & Launch Button ──
                Button(action: { finishSetup() }) {
                    HStack(spacing: 6) {
                        Text(LocalizedStrings.translateText("Get Started with Genie ✨", lang: appLanguage))
                            .font(.system(size: 12, weight: .bold))
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 13))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [Color.blue, Color.purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .shadow(color: Color.blue.opacity(0.35), radius: 6, y: 3)
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            .padding(16)
            .frame(width: 440)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(nsColor: .windowBackgroundColor).opacity(0.96))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(Color.primary.opacity(0.12), lineWidth: 1.0)
                    )
            )
            .shadow(color: Color.black.opacity(0.45), radius: 28, y: 12)
        }
        .onAppear {
            selectedFormation = appFormation
            selectedTransition = gridTransitionDirection
            soundChoice = soundEnabled
            checkPermissions()
            startPermissionPolling()
        }
        .onDisappear {
            permTimer?.invalidate()
            permTimer = nil
        }
        .onChange(of: tinyEngine.isOllamaRunning) { _, isRunning in
            guard isRunning, autoPullAfterOllamaLaunch, let recommendedModel else { return }
            autoPullAfterOllamaLaunch = false
            tinyEngine.pullModel(card: recommendedModel)
        }
    }

    /// Installing Ollama (Homebrew) is async and only flips `isOllamaRunning`
    /// once it actually finishes; the pull is chained off that instead of a
    /// fixed delay so it can't fire before the binary exists. Under the Mac
    /// App Store build `canInstallExternalRuntimes` is false and
    /// `installAndLaunchOllamaEngine()` just opens ollama.com instead — there's
    /// no local install to chain a pull onto, so this deliberately no-ops.
    private func beginEngineInstall() {
        guard let recommendedModel else { return }
        if GenieCapabilities.canInstallExternalRuntimes {
            autoPullAfterOllamaLaunch = true
            tinyEngine.installAndLaunchOllamaEngine()
        } else if tinyEngine.isOllamaRunning {
            tinyEngine.pullModel(card: recommendedModel)
        } else {
            tinyEngine.installAndLaunchOllamaEngine()
        }
    }

    private var allPermissionsGranted: Bool {
        accessibilityGranted || screenGranted
    }

    private func transitionPill(title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 9.5, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? .white : .primary.opacity(0.8))
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(isSelected ? Color.blue : Color.primary.opacity(0.05))
                )
        }
        .buttonStyle(.plain)
    }

    private func checkPermissions() {
        accessibilityGranted = AXIsProcessTrusted()
        screenGranted = CGPreflightScreenCaptureAccess()
    }

    private func startPermissionPolling() {
        permTimer?.invalidate()
        permTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
            Task { @MainActor in
                checkPermissions()
            }
        }
    }

    private func requestPermissions() {
        permissionsAskedAtLogin = true
        UserDefaults.standard.set(true, forKey: PrefKey.permissionsAskedAtLogin)
        PermissionsManager.shared.requestAllPermissions()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            checkPermissions()
        }
    }

    private func finishSetup() {
        appFormation = selectedFormation
        gridTransitionDirection = selectedTransition
        soundEnabled = soundChoice
        hapticsEnabled = soundChoice
        UserDefaults.standard.set(appLanguage, forKey: PrefKey.appLanguage)
        UserDefaults.standard.set(selectedFormation, forKey: PrefKey.appFormation)
        UserDefaults.standard.set(selectedTransition, forKey: PrefKey.gridTransitionDirection)
        UserDefaults.standard.set(soundChoice, forKey: PrefKey.soundEnabled)
        UserDefaults.standard.set(soundChoice, forKey: PrefKey.hapticsEnabled)
        permissionsAskedAtLogin = true
        hasCompletedInitialSetup = true
        UserDefaults.standard.set(true, forKey: PrefKey.permissionsAskedAtLogin)
        UserDefaults.standard.set(true, forKey: PrefKey.hasCompletedInitialSetup)
        NotificationCenter.default.post(name: UserDefaults.didChangeNotification, object: nil)
        NotificationCenter.default.post(name: NSNotification.Name("NexusLanguageChanged"), object: appLanguage)
        UserDefaults.standard.synchronize()

        let screen = NSScreen.main ?? (NSScreen.screens.first ?? NSScreen())
        GenieSmokeEngine.shared.triggerBurst(
            origin: .center,
            bounds: screen.frame.size,
            style: "Mystical Cyan 🧞‍♂️",
            count: 40
        )

        HapticFeedback.heavy()

        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
            isPresented = false
        }
    }
}
