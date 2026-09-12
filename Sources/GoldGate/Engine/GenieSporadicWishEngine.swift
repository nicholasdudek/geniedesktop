// MARK: - GenieSporadicWishEngine.swift
// Golden Gate Engineering • © 2026 Nicholas M. Dudek
//
// Mystical Genie Wish Whisperer & Sporadic Interactive Whim Engine.
// Animates the Genie icon with ethereal halos, stardust swirls, and billowing smoke,
// and sporadically surfaces playful wish prompts ("Psst... do you have a wish?"),
// interactive lamp-rubbing gestures, and one-tap wish fulfillment.

import AppKit
import Foundation
import SwiftUI

// MARK: - 🧞‍♂️ Sporadic Wish Engine
@MainActor
public final class GenieSporadicWishEngine: ObservableObject {
    public static let shared = GenieSporadicWishEngine()

    public enum WishKind: String, CaseIterable, Sendable {
        case askWish = "Ask a Wish"
        case rubLamp = "Rub the Lamp"
        case creativeInspiration = "Creative Inspiration"
        case macAura = "Mac Cosmic Aura"
        case stardustTwinkle = "Stardust Twinkle"
    }

    public enum Mood: String, Sendable {
        case quiescent      // Gentle breathing glow, subtle stardust
        case sparkling      // Orbiting stardust, celestial shimmer
        case askingWish     // Floating speech bubble visible asking for a wish
        case lampRubbed     // User rubbed the lamp! Joyous smoke burst & haptics
        case grantingWish   // Wish accepted! Cosmic explosion & execution
    }

    public struct QuickWishOption: Identifiable, Sendable {
        public let id: String
        public let icon: String
        public let label: String
        public let promptText: String
        public let targetTab: String // "chat" or "editor"

        public init(id: String, icon: String, label: String, promptText: String, targetTab: String = "chat") {
            self.id = id
            self.icon = icon
            self.label = label
            self.promptText = promptText
            self.targetTab = targetTab
        }
    }

    // MARK: - Published State
    @Published public var isBubbleVisible: Bool = false
    @Published public var mood: Mood = .quiescent
    @Published public var currentKind: WishKind = .askWish
    @Published public var bubbleTitle: String = "Psst... do you have a wish? 🧞‍♂️"
    @Published public var bubbleSubtitle: String = "Click a wish below or whisper your own ✨"
    @Published public var inlineWishText: String = ""
    @Published public var rubCount: Int = 0
    @Published public var isRubbing: Bool = false
    @Published public var totalWishesGranted: Int = 0
    @Published public var auraIntensity: Double = 1.0
    @Published public var lastGrantedWishText: String? = nil
    @Published public var sparkleBurstId: UUID = UUID()

    // Curated quick wish options for instant one-tap manifestation
    public let quickWishes: [QuickWishOption] = [
        QuickWishOption(
            id: "app",
            icon: "sparkles",
            label: "Build an App",
            promptText: "Build a sleek native macOS utility app in Genie Studio with beautiful typography and real-time preview",
            targetTab: "editor"
        ),
        QuickWishOption(
            id: "optimize",
            icon: "bolt.fill",
            label: "Optimize Mac",
            promptText: "Inspect active system memory, cache, and background processes to optimize Mac performance",
            targetTab: "chat"
        ),
        QuickWishOption(
            id: "math",
            icon: "function",
            label: "Fast Math",
            promptText: "/dist_calc 2^32; sqrt(1048576); sin(3.14159/2); 15% of 8500; log2(65536)",
            targetTab: "chat"
        ),
        QuickWishOption(
            id: "theme",
            icon: "paintpalette.fill",
            label: "Living Theme",
            promptText: "Switch desktop atmosphere to Dynamic Living Sunset with ambient lighting",
            targetTab: "chat"
        ),
        QuickWishOption(
            id: "studio",
            icon: "macwindow.on.rectangle",
            label: "Genie Studio",
            promptText: "/thirds",
            targetTab: "editor"
        )
    ]

    // Whimsical sporadic titles
    private let sporadicWhims: [(kind: WishKind, title: String, subtitle: String)] = [
        (.askWish, "Psst... do you have a wish? 🧞‍♂️", "Your wish is my command. Click to manifest it ✨"),
        (.rubLamp, "Rub the magic lamp! 🪔", "Hover and scrub your cursor to unlock 3 wishes!"),
        (.creativeInspiration, "Inspiration just struck! 💡", "I have a wild idea for an app. Want me to code it in Genie Studio?"),
        (.macAura, "Mac Cosmic Aura: Optimal 🔮", "Apple Silicon M-Series is running at 100% bliss and 0 thermal strain."),
        (.askWish, "One wish, hot and ready 🪄", "Tell me what to build, solve, or automate on your desktop."),
        (.askWish, "Got a coding wish? 📝", "Genie Studio is warmed up and ready for pair programming."),
        (.stardustTwinkle, "Celestial alignment detected ✨", "The stars whisper: great code will be written today."),
        (.askWish, "Rub the lamp for 3 wishes... 🧞‍♂️", "What shall we manifest on your screen right now?")
    ]

    private var sporadicTimer: Timer?
    private var dismissTimer: Timer?
    private var rubResetTimer: Timer?

    private init() {
        startSporadicCycle()
    }

    private var hasTriggeredOnceThisSession: Bool = false

    // MARK: - Sporadic Timer Loop
    public func startSporadicCycle() {
        sporadicTimer?.invalidate()
        let isProactiveEnabled = UserDefaults.standard.bool(forKey: PrefKey.proactiveMenuDappEnabled)
        guard isProactiveEnabled && !hasTriggeredOnceThisSession else { return }
        scheduleNextSporadicWhim(delay: 25.0)
    }

    private func scheduleNextSporadicWhim(delay: TimeInterval? = nil) {
        let interval = delay ?? 25.0
        sporadicTimer?.invalidate()
        sporadicTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.triggerSporadicWhim()
            }
        }
    }

    /// Triggers a sporadic whimsical event (asking for a wish, asking to rub lamp, celestial twinkle, etc.)
    public func triggerSporadicWhim() {
        let isProactiveEnabled = UserDefaults.standard.bool(forKey: PrefKey.proactiveMenuDappEnabled)
        guard isProactiveEnabled && !hasTriggeredOnceThisSession else { return }
        guard !isBubbleVisible else { return }

        hasTriggeredOnceThisSession = true

        let whim = sporadicWhims.randomElement() ?? sporadicWhims[0]
        currentKind = whim.kind
        bubbleTitle = whim.title
        bubbleSubtitle = whim.subtitle
        mood = (whim.kind == .rubLamp) ? .sparkling : .askingWish
        auraIntensity = 1.6
        sparkleBurstId = UUID()

        withAnimation(.spring(response: 0.45, dampingFraction: 0.72)) {
            isBubbleVisible = true
        }

        // Play gentle chime & subtle haptic
        playWhimChime()
        HapticFeedback.selection()

        // Auto-dismiss after 9.5 seconds if user is busy with other apps
        dismissTimer?.invalidate()
        dismissTimer = Timer.scheduledTimer(withTimeInterval: 9.5, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.dismissBubble()
            }
        }
    }

    // MARK: - Lamp Rubbing Gesture
    /// Called when the user hovers back-and-forth or scrubs over the Genie icon
    public func rubLamp() {
        rubCount += 1
        isRubbing = true
        auraIntensity = 2.2
        mood = .lampRubbed
        sparkleBurstId = UUID()

        HapticFeedback.selection()
        if rubCount % 2 == 0 {
            HapticFeedback.playClickSound(soundName: "Tink")
        }

        rubResetTimer?.invalidate()
        rubResetTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
            Task { @MainActor in
                self?.isRubbing = false
                if self?.mood == .lampRubbed {
                    self?.mood = .askingWish
                }
            }
        }

        // If rubbed 3 times, immediately summon the Wish prompt with celebration!
        if rubCount >= 3 {
            rubCount = 0
            currentKind = .askWish
            bubbleTitle = "You rubbed the lamp! 🪔✨"
            bubbleSubtitle = "Three wishes are yours. Speak, Nicholas! 🧞‍♂️"
            mood = .askingWish
            withAnimation(.spring(response: 0.35, dampingFraction: 0.68)) {
                isBubbleVisible = true
            }
            HapticFeedback.success()
            playMagicFanfare()

            dismissTimer?.invalidate()
            dismissTimer = Timer.scheduledTimer(withTimeInterval: 12.0, repeats: false) { [weak self] _ in
                Task { @MainActor in
                    self?.dismissBubble()
                }
            }
        }
    }

    // MARK: - Wish Granting Action
    public func grantWish(_ wishText: String, targetTab: String = "chat") {
        let clean = wishText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }

        lastGrantedWishText = clean
        totalWishesGranted += 1
        mood = .grantingWish
        auraIntensity = 2.5
        sparkleBurstId = UUID()

        // Haptics & celebration sound
        HapticFeedback.success()
        playMagicFanfare()

        // Hide bubble with celebration animation
        withAnimation(.easeOut(duration: 0.3)) {
            isBubbleVisible = false
        }
        inlineWishText = ""

        // Reset mood after burst
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            self?.mood = .quiescent
            self?.auraIntensity = 1.0
        }

        // Fulfill the wish in Genie!
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            // 1. If it's a Thirds Mode / Studio request, activate thirds mode
            if targetTab == "editor" || clean.lowercased().contains("thirds") || clean.lowercased().contains("code") {
                FinderChatWindowManager.shared.snapTo(preset: .thirdsMode)
                FinderChatWindowManager.shared.activeTab = .editor
            } else {
                FinderChatWindowManager.shared.activeTab = .chat
            }

            // 2. Reveal the Finder Chat / Genie Studio window
            FinderChatWindowManager.shared.show()

            // 3. Inject the prompt into draft or dispatch it
            LocalModelManager.shared.activeDraftPrompt = clean
        }

        scheduleNextSporadicWhim(delay: 60.0)
    }

    public func dismissBubble() {
        withAnimation(.easeOut(duration: 0.25)) {
            isBubbleVisible = false
            if mood == .askingWish || mood == .lampRubbed {
                mood = .quiescent
            }
            auraIntensity = 1.0
        }
    }

    // MARK: - Sound Utilities
    private func playWhimChime() {
        if let sound = NSSound(named: NSSound.Name("Tink")) ?? NSSound(named: NSSound.Name("Pop")) {
            sound.volume = 0.65
            sound.play()
        }
    }

    private func playMagicFanfare() {
        if let sound = NSSound(named: NSSound.Name("Hero")) ?? NSSound(named: NSSound.Name("Glass")) {
            sound.volume = 0.75
            sound.play()
        }
    }
}
