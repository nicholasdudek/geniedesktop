import AppKit
import SwiftUI
import Combine
import AVFoundation

// MARK: - 🧘 Zen Mode Visual Theme
public enum ZenOverlayTheme: String, CaseIterable, Identifiable, Sendable {
    case neuralBloom = "Neural Bloom (Living WebGL)"
    case liquidWater = "Apple 2028 Liquid Caustics"
    case oledBlackout = "OLED Specular Blackout"
    case quantumGlass = "Quantum Titanium Glass"
    case mysticalAurora = "Mystical Aurora Borealis"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .neuralBloom: return "sparkles"
        case .liquidWater: return "drop.fill"
        case .oledBlackout: return "moon.stars.fill"
        case .quantumGlass: return "cube.transparent.fill"
        case .mysticalAurora: return "waveform.path"
        }
    }
}

// MARK: - 🍃 Zen Ambient Soundscape
public enum ZenAmbientSound: String, CaseIterable, Identifiable, Sendable {
    case rain = "Gentle Rainfall 🌧️"
    case ocean = "Rhythmic Ocean Waves 🌊"
    case forest = "Whispering Forest Wind 🌲"
    case alphaWaves = "432Hz Alpha Focus Beats 🎧"
    case mute = "Distraction-Free Silence 🔇"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .rain: return "cloud.rain.fill"
        case .ocean: return "water.waves"
        case .forest: return "wind"
        case .alphaWaves: return "headphones"
        case .mute: return "speaker.slash.fill"
        }
    }
}

// MARK: - 🎧 On-Device Ambient Audio Synthesizer
final class ZenAmbientSoundSynthesizer: @unchecked Sendable {
    static let shared = ZenAmbientSoundSynthesizer()

    private var audioEngine: AVAudioEngine?
    private var sourceNode: AVAudioSourceNode?
    private var currentSound: ZenAmbientSound = .mute
    private var volume: Float = 0.50
    private var phase: Double = 0.0
    private var waveLFO: Double = 0.0

    private init() {}

    func setSound(_ sound: ZenAmbientSound, volume: Float) {
        self.currentSound = sound
        self.volume = max(0.0, min(1.0, volume))

        if sound == .mute || volume <= 0.01 {
            stop()
            return
        }

        startEngineIfNeeded()
    }

    func setVolume(_ volume: Float) {
        self.volume = max(0.0, min(1.0, volume))
        if self.volume <= 0.01 && currentSound != .mute {
            stop()
        } else if audioEngine == nil && currentSound != .mute {
            startEngineIfNeeded()
        }
    }

    func stop() {
        audioEngine?.stop()
        if let node = sourceNode {
            audioEngine?.detach(node)
        }
        sourceNode = nil
        audioEngine = nil
    }

    private func startEngineIfNeeded() {
        guard audioEngine == nil else { return }

        let engine = AVAudioEngine()
        let sampleRate: Double = 44100.0

        let node = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self = self else { return noErr }
            let abl = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let vol = self.volume
            let sound = self.currentSound

            for frame in 0..<Int(frameCount) {
                var sample: Float = 0.0

                switch sound {
                case .rain:
                    let white = Float.random(in: -1.0...1.0)
                    sample = white * 0.18

                case .ocean:
                    self.waveLFO += 0.00015
                    let lfo = Float((sin(self.waveLFO * 2.0 * .pi) + 1.0) * 0.5)
                    let white = Float.random(in: -1.0...1.0)
                    sample = white * (0.05 + lfo * 0.22)

                case .forest:
                    self.waveLFO += 0.00008
                    let lfo = Float((sin(self.waveLFO * 2.0 * .pi) + 1.0) * 0.5)
                    let white = Float.random(in: -1.0...1.0)
                    sample = white * (0.04 + lfo * 0.12)

                case .alphaWaves:
                    self.phase += (432.0 / sampleRate) * 2.0 * .pi
                    self.waveLFO += (8.0 / sampleRate) * 2.0 * .pi
                    let carrier = Float(sin(self.phase))
                    let beat = Float((sin(self.waveLFO) + 1.0) * 0.5)
                    sample = carrier * (0.08 + beat * 0.12)

                case .mute:
                    sample = 0.0
                }

                sample *= vol

                for buffer in abl {
                    let ptr = buffer.mData?.assumingMemoryBound(to: Float.self)
                    ptr?[frame] = sample
                }
            }
            return noErr
        }

        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 2)!
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = 1.0

        do {
            try engine.start()
            self.audioEngine = engine
            self.sourceNode = node
        } catch {
            self.audioEngine = nil
            self.sourceNode = nil
        }
    }
}

// MARK: - 🪟 Dedicated SkyLight Zen Overlay Panel
public final class SkyLightZenOverlayPanel: NSPanel {
    public override var canBecomeKey: Bool { true }
    public override var canBecomeMain: Bool { true }

    public override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.keyCode == 53 { // Escape
            SkyLightZenOverlayManager.shared.hide()
            return true
        }
        if event.modifierFlags.contains([.command, .option]) && event.charactersIgnoringModifiers?.lowercased() == "z" {
            SkyLightZenOverlayManager.shared.hide()
            return true
        }
        if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers?.lowercased() == "w" {
            SkyLightZenOverlayManager.shared.hide()
            return true
        }
        return super.performKeyEquivalent(with: event)
    }

    public override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape
            SkyLightZenOverlayManager.shared.hide()
            return
        }
        super.keyDown(with: event)
    }
}

// MARK: - 🌌 SkyLight Zen Overlay Manager
@MainActor
public final class SkyLightZenOverlayManager: ObservableObject {
    public static let shared = SkyLightZenOverlayManager()

    // ── Published Observable State ──────────────────────────────────────────
    @Published public private(set) var isOverlayActive: Bool = false
    @Published public var opacity: Double {
        didSet {
            UserDefaults.standard.set(opacity, forKey: PrefKey.zenOverlayOpacity)
            applySkyLightAlpha()
        }
    }
    @Published public var blurRadius: Double {
        didSet { UserDefaults.standard.set(blurRadius, forKey: PrefKey.zenOverlayBlurRadius) }
    }
    @Published public var paddingInset: CGFloat {
        didSet {
            UserDefaults.standard.set(Double(paddingInset), forKey: PrefKey.zenOverlayPadding)
            relayoutPanelFrame()
        }
    }
    @Published public var cornerRadius: CGFloat {
        didSet { UserDefaults.standard.set(Double(cornerRadius), forKey: PrefKey.zenOverlayCornerRadius) }
    }
    @Published public var activeTheme: ZenOverlayTheme {
        didSet { UserDefaults.standard.set(activeTheme.rawValue, forKey: PrefKey.zenOverlayTheme) }
    }
    @Published public var activeSound: ZenAmbientSound {
        didSet {
            UserDefaults.standard.set(activeSound.rawValue, forKey: PrefKey.zenOverlaySound)
            ZenAmbientSoundSynthesizer.shared.setSound(activeSound, volume: Float(soundVolume))
        }
    }
    @Published public var soundVolume: Double {
        didSet {
            UserDefaults.standard.set(soundVolume, forKey: PrefKey.zenOverlaySoundVolume)
            ZenAmbientSoundSynthesizer.shared.setVolume(Float(soundVolume))
        }
    }
    @Published public var isBreathingGuideActive: Bool {
        didSet { UserDefaults.standard.set(isBreathingGuideActive, forKey: PrefKey.zenOverlayBreathingEnabled) }
    }

    // ── Flow Timer State ────────────────────────────────────────────────────
    @Published public var isFocusTimerRunning: Bool = false
    @Published public var focusSecondsRemaining: Int = 25 * 60
    @Published public var statusMessage: String = "SkyLight Zen Overlay Ready 🧘"
    @Published public var secondSkyLightSpaceID: UInt64? = nil
    @Published public var originalSpaceID: UInt64? = nil

    private var overlayPanel: SkyLightZenOverlayPanel?
    private let skyLight = SkyLightNativeBridge.shared
    private let transformBridge = SkyLightWindowServerTransformBridge.shared
    private var timerCancellable: AnyCancellable?

    private init() {
        let savedOpacity = UserDefaults.standard.object(forKey: PrefKey.zenOverlayOpacity) != nil
            ? UserDefaults.standard.double(forKey: PrefKey.zenOverlayOpacity) : 0.90
        let savedBlur = UserDefaults.standard.object(forKey: PrefKey.zenOverlayBlurRadius) != nil
            ? UserDefaults.standard.double(forKey: PrefKey.zenOverlayBlurRadius) : 30.0
        let savedPadding = UserDefaults.standard.object(forKey: PrefKey.zenOverlayPadding) != nil
            ? CGFloat(UserDefaults.standard.double(forKey: PrefKey.zenOverlayPadding)) : 0.0
        let savedCorner = UserDefaults.standard.object(forKey: PrefKey.zenOverlayCornerRadius) != nil
            ? CGFloat(UserDefaults.standard.double(forKey: PrefKey.zenOverlayCornerRadius)) : 0.0
        let savedThemeRaw = UserDefaults.standard.string(forKey: PrefKey.zenOverlayTheme) ?? ZenOverlayTheme.neuralBloom.rawValue
        let savedSoundRaw = UserDefaults.standard.string(forKey: PrefKey.zenOverlaySound) ?? ZenAmbientSound.rain.rawValue
        let savedVolume = UserDefaults.standard.object(forKey: PrefKey.zenOverlaySoundVolume) != nil
            ? UserDefaults.standard.double(forKey: PrefKey.zenOverlaySoundVolume) : 0.50
        let savedBreathing = UserDefaults.standard.object(forKey: PrefKey.zenOverlayBreathingEnabled) != nil
            ? UserDefaults.standard.bool(forKey: PrefKey.zenOverlayBreathingEnabled) : true

        self.opacity = savedOpacity
        self.blurRadius = savedBlur
        self.paddingInset = savedPadding
        self.cornerRadius = savedCorner
        self.activeTheme = ZenOverlayTheme(rawValue: savedThemeRaw) ?? .neuralBloom
        self.activeSound = ZenAmbientSound(rawValue: savedSoundRaw) ?? .rain
        self.soundVolume = savedVolume
        self.isBreathingGuideActive = savedBreathing

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleToggleZenOverlayNotif),
            name: NSNotification.Name("GenieToggleZenOverlay"),
            object: nil
        )
    }

    @objc private func handleToggleZenOverlayNotif() {
        toggle()
    }

    // MARK: - 🚀 Presentation Lifecycle
    public func toggle() {
        if isOverlayActive {
            hide()
        } else {
            show()
        }
    }

    public func show(fullscreen: Bool = true) {
        guard let screen = NSScreen.main else { return }

        if fullscreen {
            paddingInset = 0.0
            cornerRadius = 0.0
        }

        buildPanelIfNeeded(screen: screen)

        guard let panel = overlayPanel else { return }
        relayoutPanelFrame()

        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = paddingInset > 0

        panel.alphaValue = 0.0
        panel.makeKeyAndOrderFront(nil)
        panel.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.35
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().alphaValue = 1.0
        }

        applySkyLightAlpha()

        isOverlayActive = true
        UserDefaults.standard.set(true, forKey: "genieZenModeEnabled")
        ZenAmbientSoundSynthesizer.shared.setSound(activeSound, volume: Float(soundVolume))
        HapticFeedback.selection()
        statusMessage = "Zen Mode Overlay Active 🧘"
    }

    public func hide() {
        guard let panel = overlayPanel, isOverlayActive else { return }

        if let original = originalSpaceID {
            _ = MacDesktopsManager.shared.switchSpaceViaSkyLight(targetSpaceID: original)
            originalSpaceID = nil
        }

        ZenAmbientSoundSynthesizer.shared.stop()

        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.28
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().alphaValue = 0.0
        }, completionHandler: { [weak self] in
            DispatchQueue.main.async {
                panel.orderOut(nil)
                self?.isOverlayActive = false
                UserDefaults.standard.set(false, forKey: "genieZenModeEnabled")
            }
        })

        HapticFeedback.tick()
        statusMessage = "Zen Mode Dismissed 🍃"
    }

    // MARK: - 🌌 SkyLight 2nd Space Hardware Allocation
    public func teleportToSecondSkyLightSpace() {
        let currentIdx = MacDesktopsManager.shared.currentSpaceIndex
        if let currentSpace = MacDesktopsManager.shared.spaces.first(where: { $0.index == currentIdx }) {
            originalSpaceID = currentSpace.id64 ?? UInt64(currentSpace.id)
        }

        if let newSpaceID = MacDesktopsManager.shared.executeHardwareSpaceCreation() {
            self.secondSkyLightSpaceID = newSpaceID

            if let panel = overlayPanel {
                let wid = CGWindowID(panel.windowNumber)
                _ = skyLight.moveWindowsToSpace(windowIDs: [wid], spaceID: newSpaceID)
            }

            _ = MacDesktopsManager.shared.switchSpaceViaSkyLight(targetSpaceID: newSpaceID)
            HapticFeedback.success()
            statusMessage = "Teleported to 2nd SkyLight Space #\(newSpaceID) 🌌"
        } else {
            let target = currentIdx == 1 ? 2 : 1
            MacDesktopsManager.shared.switchToDesktop(index: target)
            statusMessage = "Switched to Desktop Space \(target) 🌌"
        }
    }

    public func returnToOriginalSpace() {
        if let original = originalSpaceID {
            _ = MacDesktopsManager.shared.switchSpaceViaSkyLight(targetSpaceID: original)
            originalSpaceID = nil
            statusMessage = "Returned to Prime Workspace 🖥️"
            HapticFeedback.selection()
        } else {
            MacDesktopsManager.shared.switchToDesktop(index: 1)
        }
    }

    // MARK: - ⏱️ Focus Flow Timer Controller
    public func toggleFocusTimer() {
        if isFocusTimerRunning {
            pauseFocusTimer()
        } else {
            startFocusTimer()
        }
    }

    public func startFocusTimer() {
        isFocusTimerRunning = true
        timerCancellable = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                if self.focusSecondsRemaining > 0 {
                    self.focusSecondsRemaining -= 1
                } else {
                    self.pauseFocusTimer()
                    HapticFeedback.success()
                    NSSound(named: "Glass")?.play()
                    self.statusMessage = "Focus session completed! 🎉"
                }
            }
    }

    public func pauseFocusTimer() {
        isFocusTimerRunning = false
        timerCancellable?.cancel()
        timerCancellable = nil
    }

    public func resetFocusTimer(minutes: Int = 25) {
        pauseFocusTimer()
        focusSecondsRemaining = minutes * 60
    }

    // MARK: - 🎨 SkyLight Hardware Compositor Helpers
    private func buildPanelIfNeeded(screen: NSScreen) {
        if overlayPanel == nil {
            let panel = SkyLightZenOverlayPanel(
                contentRect: screen.frame,
                styleMask: [.borderless, .fullSizeContentView, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.isMovableByWindowBackground = true
            panel.backgroundColor = .clear

            let hostingView = NSHostingView(rootView: SkyLightZenOverlayView(manager: self))
            hostingView.autoresizingMask = [.width, .height]
            panel.contentView = hostingView

            self.overlayPanel = panel
        }
    }

    private func relayoutPanelFrame() {
        guard let panel = overlayPanel, let screen = NSScreen.main else { return }
        let full = screen.frame
        let inset = paddingInset
        let targetFrame = CGRect(
            x: full.minX + inset,
            y: full.minY + inset,
            width: max(320, full.width - (inset * 2)),
            height: max(240, full.height - (inset * 2))
        )
        panel.setFrame(targetFrame, display: true, animate: isOverlayActive)
        panel.hasShadow = inset > 0
    }

    private func applySkyLightAlpha() {
        guard let panel = overlayPanel else { return }
        let wid = CGWindowID(panel.windowNumber)
        let cid = skyLight.connectionID()
        if cid > 0 && wid > 0 {
            let slAlpha: Float = Float(opacity)
            _ = transformBridge.setWindowAlpha(windowId: wid, alpha: slAlpha)
        }
    }
}
