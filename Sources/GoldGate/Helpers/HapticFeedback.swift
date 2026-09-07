import AppKit
import AudioToolbox

// MARK: - Ultra-Tactile Haptic & Audio Feedback Engine

enum HapticFeedback {
    private static var lastSoundTime: TimeInterval = 0
    private static var lastHapticTime: TimeInterval = 0

    static var isSoundEnabled: Bool {
        if UserDefaults.standard.object(forKey: PrefKey.soundEnabled) == nil { return true }
        return UserDefaults.standard.bool(forKey: PrefKey.soundEnabled)
    }

    static var isHapticsEnabled: Bool {
        if UserDefaults.standard.object(forKey: PrefKey.hapticsEnabled) == nil { return true }
        return UserDefaults.standard.bool(forKey: PrefKey.hapticsEnabled)
    }

    static var soundVolume: Float {
        if UserDefaults.standard.object(forKey: PrefKey.soundVolume) == nil { return 0.85 }
        return Float(UserDefaults.standard.double(forKey: PrefKey.soundVolume))
    }

    static var soundProfile: String {
        UserDefaults.standard.string(forKey: PrefKey.soundProfile) ?? "Apple Modern"
    }

    static var isPrinterSoundEnabled: Bool {
        if UserDefaults.standard.object(forKey: PrefKey.notePrinterSoundEnabled) == nil { return true }
        return UserDefaults.standard.bool(forKey: PrefKey.notePrinterSoundEnabled)
    }

    static func togglePrinterSound() -> Bool {
        let current = isPrinterSoundEnabled
        let newVal = !current
        UserDefaults.standard.set(newVal, forKey: PrefKey.notePrinterSoundEnabled)
        return newVal
    }

    // Play crisp tactile sound effect
    static func playClickSound(soundName: String = "Tink", systemID: SystemSoundID = 1104, minInterval: TimeInterval = 0.020) {
        guard isSoundEnabled else { return }
        let now = ProcessInfo.processInfo.systemUptime
        guard now - lastSoundTime >= minInterval else { return }
        lastSoundTime = now

        if let sound = NSSound(named: NSSound.Name(soundName)) {
            sound.volume = soundVolume
            sound.play()
        } else {
            AudioServicesPlayAlertSound(systemID)
        }
    }

    // Ultra-crisp mechanical typing keystroke sound effect
    static func playTypingSound() {
        guard isSoundEnabled else { return }
        let now = ProcessInfo.processInfo.systemUptime
        guard now - lastSoundTime >= 0.015 else { return }
        lastSoundTime = now

        switch soundProfile {
        case "Mechanical Keyboard":
            AudioServicesPlaySystemSound(1104) // Sharp Cherry MX switch click
        case "Sci-Fi Cyberpunk":
            if let s = NSSound(named: "Tink") {
                s.volume = soundVolume * 0.75
                s.play()
            } else {
                AudioServicesPlaySystemSound(1104)
            }
        case "Ocean & Nature":
            if let s = NSSound(named: "Bottle") {
                s.volume = soundVolume * 0.65
                s.play()
            } else {
                AudioServicesPlaySystemSound(1104)
            }
        case "Arcade 8-Bit":
            if let s = NSSound(named: "Pop") {
                s.volume = soundVolume * 0.85
                s.play()
            } else {
                AudioServicesPlaySystemSound(1104)
            }
        default: // "Apple Modern"
            AudioServicesPlaySystemSound(1104) // Fast mechanical keystroke click
        }

        if isHapticsEnabled {
            NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
        }
    }

    // Hover tick / magnetic snapping
    static func tick() {
        guard isSoundEnabled || isHapticsEnabled else { return }
        let now = ProcessInfo.processInfo.systemUptime
        guard now - lastHapticTime >= 0.035 else { return }
        lastHapticTime = now

        if isSoundEnabled {
            switch soundProfile {
            case "Mechanical Keyboard":
                AudioServicesPlaySystemSound(1104) // Sharp switch click
            case "Sci-Fi Cyberpunk":
                if let s = NSSound(named: "Blow") {
                    s.volume = soundVolume * 0.6
                    s.play()
                } else {
                    AudioServicesPlaySystemSound(1057)
                }
            case "Ocean & Nature":
                if let s = NSSound(named: "Bottle") {
                    s.volume = soundVolume * 0.7
                    s.play()
                } else {
                    AudioServicesPlaySystemSound(1057)
                }
            default: // "Apple Modern"
                AudioServicesPlaySystemSound(1104) // Fast mechanical click
            }
        }
        if isHapticsEnabled {
            NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
        }
    }

    // Item selection / pill change
    static func selection() {
        if isSoundEnabled {
            switch soundProfile {
            case "Mechanical Keyboard":
                AudioServicesPlaySystemSound(1105)
            case "Sci-Fi Cyberpunk":
                if let morph = NSSound(named: "Morse") {
                    morph.volume = soundVolume * 0.75
                    morph.play()
                } else {
                    AudioServicesPlaySystemSound(1057)
                }
            case "Ocean & Nature":
                if let bubble = NSSound(named: "Hero") {
                    bubble.volume = soundVolume * 0.8
                    bubble.play()
                } else {
                    AudioServicesPlaySystemSound(1057)
                }
            case "Arcade 8-Bit":
                if let ping = NSSound(named: "Ping") {
                    ping.volume = soundVolume
                    ping.play()
                } else {
                    AudioServicesPlaySystemSound(1057)
                }
            default: // "Apple Modern"
                if let pop = NSSound(named: "Pop") {
                    pop.volume = soundVolume
                    pop.play()
                } else {
                    AudioServicesPlaySystemSound(1057)
                }
            }
        }
        if isHapticsEnabled {
            NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
        }
    }

    // Deep impactful launch punch
    static func heavy() {
        if isSoundEnabled {
            switch soundProfile {
            case "Mechanical Keyboard":
                AudioServicesPlayAlertSound(1104)
            case "Sci-Fi Cyberpunk":
                if let glass = NSSound(named: "Submarine") {
                    glass.volume = soundVolume
                    glass.play()
                } else {
                    AudioServicesPlayAlertSound(1104)
                }
            case "Ocean & Nature":
                if let water = NSSound(named: "Purr") {
                    water.volume = soundVolume
                    water.play()
                } else {
                    AudioServicesPlayAlertSound(1104)
                }
            default: // "Apple Modern"
                if let tink = NSSound(named: "Tink") {
                    tink.volume = soundVolume
                    tink.play()
                } else {
                    AudioServicesPlayAlertSound(1104)
                }
            }
        }
        if isHapticsEnabled {
            NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.04) {
                NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
            }
        }
    }

    // Custom preview test sounds
    static func testWaterDrop() {
        if let s = NSSound(named: "Bottle") ?? NSSound(named: "Hero") {
            s.volume = soundVolume
            s.play()
        } else {
            AudioServicesPlaySystemSound(1057)
        }
        if isHapticsEnabled {
            NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
        }
    }

    static func testOlliePop() {
        if let s = NSSound(named: "Funk") ?? NSSound(named: "Pop") {
            s.volume = soundVolume
            s.play()
        } else {
            AudioServicesPlayAlertSound(1104)
        }
        if isHapticsEnabled {
            NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
        }
    }

    static func testCyberPulse() {
        if let s = NSSound(named: "Submarine") ?? NSSound(named: "Morse") {
            s.volume = soundVolume
            s.play()
        } else {
            AudioServicesPlaySystemSound(1057)
        }
        if isHapticsEnabled {
            NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
        }
    }

    static func success() {
        if let s = NSSound(named: "Hero") ?? NSSound(named: "Glass") {
            s.volume = soundVolume
            s.play()
        } else {
            AudioServicesPlayAlertSound(1104)
        }
        if isHapticsEnabled {
            NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
        }
    }

    // MARK: - Velcro Physics (Rip & Snap-Back)
    static func playVelcroRip() {
        guard isSoundEnabled || isHapticsEnabled else { return }
        if isSoundEnabled {
            if let s = NSSound(named: "Funk") ?? NSSound(named: "Purr") ?? NSSound(named: "Pop") {
                s.volume = soundVolume * 0.95
                s.play()
            } else {
                AudioServicesPlayAlertSound(1104)
            }
        }
        if isHapticsEnabled {
            for i in 0..<4 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.035) {
                    NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
                }
            }
        }
    }

    static func playVelcroSnap() {
        guard isSoundEnabled || isHapticsEnabled else { return }
        if isSoundEnabled {
            if let s = NSSound(named: "Pop") ?? NSSound(named: "Hero") ?? NSSound(named: "Tink") {
                s.volume = soundVolume * 0.95
                s.play()
            } else {
                AudioServicesPlaySystemSound(1057)
            }
        }
        if isHapticsEnabled {
            NSHapticFeedbackManager.defaultPerformer.perform(.levelChange, performanceTime: .now)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.04) {
                NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
            }
        }
    }

    // Mechanical Printer & Typewriter Sound Sequence (On/Off Optional)
    static func playPrinterSound() {
        guard isPrinterSoundEnabled else { return }

        // Mechanical stepper motor clicks + paper feed sequence
        AudioServicesPlaySystemSound(1104) // Line 1 print advance
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.045) {
            AudioServicesPlaySystemSound(1104) // Line 2 advance
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.090) {
            AudioServicesPlaySystemSound(1105) // Micro stepper step
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.140) {
            AudioServicesPlaySystemSound(1104) // Print head pass
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.200) {
            // Paper tear / completion chime
            if let tink = NSSound(named: "Tink") {
                tink.volume = soundVolume
                tink.play()
            } else {
                AudioServicesPlaySystemSound(1054)
            }
        }

        if isHapticsEnabled {
            for i in 0..<3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.05) {
                    NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
                }
            }
        }
    }

    // Authentic Instant Camera Shutter Snapshot Sound Sequence (On/Off Optional)
    static func playCameraSnapshotSound() {
        guard isPrinterSoundEnabled else { return }

        // 1. Shutter curtain click (mirror slap)
        AudioServicesPlaySystemSound(1104)

        // 2. High-speed shutter snap (35ms later)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.035) {
            AudioServicesPlaySystemSound(1105)
            if let pop = NSSound(named: "Pop") {
                pop.volume = soundVolume * 0.65
                pop.play()
            }
        }

        // 3. Film ejection stepper motor passes
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.120) {
            AudioServicesPlaySystemSound(1104)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.180) {
            AudioServicesPlaySystemSound(1104)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.250) {
            if let purr = NSSound(named: "Purr") {
                purr.volume = soundVolume * 0.40
                purr.play()
            } else if let bottle = NSSound(named: "Bottle") {
                bottle.volume = soundVolume * 0.45
                bottle.play()
            }
        }

        if isHapticsEnabled {
            NSHapticFeedbackManager.defaultPerformer.perform(.generic, performanceTime: .now)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                NSHapticFeedbackManager.defaultPerformer.perform(.alignment, performanceTime: .now)
            }
        }
    }
}

