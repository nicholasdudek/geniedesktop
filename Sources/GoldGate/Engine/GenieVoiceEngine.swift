import AppKit
import AVFoundation
import Combine
import SwiftUI

// MARK: - Curated Voice Option Model
public struct GenieVoiceOption: Identifiable, Hashable {
    public var id: String // voice identifier
    public var name: String
    public var languageCode: String
    public var regionFlag: String
    public var dialectName: String
    public var isFemale: Bool
    public var isCurated: Bool
    public var sampleGreeting: String

    public init(
        id: String,
        name: String,
        languageCode: String,
        regionFlag: String,
        dialectName: String,
        isFemale: Bool = true,
        isCurated: Bool = true,
        sampleGreeting: String = "Hello! I'm Genie, your Apple desktop companion."
    ) {
        self.id = id
        self.name = name
        self.languageCode = languageCode
        self.regionFlag = regionFlag
        self.dialectName = dialectName
        self.isFemale = isFemale
        self.isCurated = isCurated
        self.sampleGreeting = sampleGreeting
    }
}


// MARK: - Curated Voice Dialect Enum
public enum GenieVoiceDialect: String, CaseIterable, Identifiable {
    case usSamantha = "en-US-Samantha"
    case usAlex = "en-US-Alex"
    case ukDaniel = "en-GB-Daniel"
    case auKaren = "en-AU-Karen"
    case inRishi = "en-IN-Rishi"

    public var id: String { rawValue }

    public var name: String {
        switch self {
        case .usSamantha: return "Samantha"
        case .usAlex: return "Alex"
        case .ukDaniel: return "Daniel"
        case .auKaren: return "Karen"
        case .inRishi: return "Rishi"
        }
    }

    public var flag: String {
        switch self {
        case .usSamantha, .usAlex: return "🇺🇸"
        case .ukDaniel: return "🇬🇧"
        case .auKaren: return "🇦🇺"
        case .inRishi: return "🇮🇳"
        }
    }

    public var languageCode: String {
        switch self {
        case .usSamantha, .usAlex: return "en-US"
        case .ukDaniel: return "en-GB"
        case .auKaren: return "en-AU"
        case .inRishi: return "en-IN"
        }
    }
}

// MARK: - Genie Native Voice Engine
@MainActor
public final class GenieVoiceEngine: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    public static let shared = GenieVoiceEngine()

    private let synthesizer = AVSpeechSynthesizer()
    private var energyTimer: Timer?

    @Published public var isSpeaking: Bool = false
    @Published public var isPaused: Bool = false
    @Published public var currentSpokenText: String = ""
    @Published public var audioEnergy: CGFloat = 0.0 // 0.0 ... 1.0 for dynamic UI waveform animation

    // Preferences
    @AppStorage(PrefKey.voiceAutoSpeakEnabled) public var autoSpeakEnabled: Bool = false
    @AppStorage(PrefKey.selectedVoiceIdentifier) public var selectedVoiceIdentifier: String = "com.apple.voice.compact.en-US.Samantha"
    @AppStorage(PrefKey.speechRate) public var speechRate: Double = 0.50
    @AppStorage(PrefKey.speechPitch) public var speechPitch: Double = 1.02
    @AppStorage(PrefKey.speechVolume) public var speechVolume: Double = 1.0

    // Curated lovely women's voices across English dialects
    public let curatedWomenVoices: [GenieVoiceOption] = [
        // 🇺🇸 United States
        GenieVoiceOption(
            id: "com.apple.voice.compact.en-US.Samantha",
            name: "Samantha",
            languageCode: "en-US",
            regionFlag: "🇺🇸",
            dialectName: "American English",
            isFemale: true,
            isCurated: true,
            sampleGreeting: "Hello! I'm Samantha. Let's make something wonderful together."
        ),
        GenieVoiceOption(
            id: "com.apple.speech.synthesis.voice.Flo",
            name: "Flo (US)",
            languageCode: "en-US",
            regionFlag: "🇺🇸",
            dialectName: "American English",
            isFemale: true,
            isCurated: true,
            sampleGreeting: "Hi there! I'm Flo with an American accent. Ready whenever you are."
        ),
        GenieVoiceOption(
            id: "com.apple.speech.synthesis.voice.Sandy",
            name: "Sandy (US)",
            languageCode: "en-US",
            regionFlag: "🇺🇸",
            dialectName: "American English",
            isFemale: true,
            isCurated: true,
            sampleGreeting: "Hi! I'm Sandy. How can I assist you today?"
        ),
        GenieVoiceOption(
            id: "com.apple.speech.synthesis.voice.Shelley",
            name: "Shelley (US)",
            languageCode: "en-US",
            regionFlag: "🇺🇸",
            dialectName: "American English",
            isFemale: true,
            isCurated: true,
            sampleGreeting: "Greetings! I'm Shelley from the United States."
        ),

        // 🇬🇧 United Kingdom
        GenieVoiceOption(
            id: "com.apple.speech.synthesis.voice.Flo.en-GB",
            name: "Flo (UK)",
            languageCode: "en-GB",
            regionFlag: "🇬🇧",
            dialectName: "British English",
            isFemale: true,
            isCurated: true,
            sampleGreeting: "Good day! I'm Flo. Delighted to be your British voice companion."
        ),
        GenieVoiceOption(
            id: "com.apple.speech.synthesis.voice.Sandy.en-GB",
            name: "Sandy (UK)",
            languageCode: "en-GB",
            regionFlag: "🇬🇧",
            dialectName: "British English",
            isFemale: true,
            isCurated: true,
            sampleGreeting: "Hello! I'm Sandy with a classic British accent. What shall we explore?"
        ),
        GenieVoiceOption(
            id: "com.apple.speech.synthesis.voice.Shelley.en-GB",
            name: "Shelley (UK)",
            languageCode: "en-GB",
            regionFlag: "🇬🇧",
            dialectName: "British English",
            isFemale: true,
            isCurated: true,
            sampleGreeting: "Good day! I'm Shelley from the United Kingdom."
        ),

        // 🇦🇺 Australia
        GenieVoiceOption(
            id: "com.apple.voice.compact.en-AU.Karen",
            name: "Karen",
            languageCode: "en-AU",
            regionFlag: "🇦🇺",
            dialectName: "Australian English",
            isFemale: true,
            isCurated: true,
            sampleGreeting: "G'day! I'm Karen from Australia. Ready to help you get things done."
        ),

        // 🇮🇪 Ireland
        GenieVoiceOption(
            id: "com.apple.voice.compact.en-IE.Moira",
            name: "Moira",
            languageCode: "en-IE",
            regionFlag: "🇮🇪",
            dialectName: "Irish English",
            isFemale: true,
            isCurated: true,
            sampleGreeting: "Dia dhuit! I'm Moira with an Irish lilt. It's lovely to meet you."
        ),

        // 🇿🇦 South Africa
        GenieVoiceOption(
            id: "com.apple.voice.compact.en-ZA.Tessa",
            name: "Tessa",
            languageCode: "en-ZA",
            regionFlag: "🇿🇦",
            dialectName: "South African English",
            isFemale: true,
            isCurated: true,
            sampleGreeting: "Hello! I'm Tessa from South Africa. I'm here to assist you."
        ),

        // 🇮🇳 India
        GenieVoiceOption(
            id: "com.apple.voice.compact.en-IN.Tara",
            name: "Tara",
            languageCode: "en-IN",
            regionFlag: "🇮🇳",
            dialectName: "Indian English",
            isFemale: true,
            isCurated: true,
            sampleGreeting: "Namaste! I'm Tara from India. What shall we work on today?"
        )
    ]

    private override init() {
        super.init()
        synthesizer.delegate = self
    }

    // MARK: - Discovered Voices (All System Voices)
    public var allAvailableVoices: [AVSpeechSynthesisVoice] {
        AVSpeechSynthesisVoice.speechVoices().filter { $0.language.hasPrefix("en") }
    }

    public var effectiveVoice: AVSpeechSynthesisVoice? {
        if let found = AVSpeechSynthesisVoice(identifier: selectedVoiceIdentifier) {
            return found
        }
        // Fallback to Samantha or first available English voice
        if let samantha = AVSpeechSynthesisVoice.speechVoices().first(where: { $0.name.contains("Samantha") }) {
            return samantha
        }
        return AVSpeechSynthesisVoice(language: "en-US")
    }

    public var currentVoiceDisplayName: String {
        if let curated = curatedWomenVoices.first(where: { $0.id == selectedVoiceIdentifier || selectedVoiceIdentifier.contains($0.name) }) {
            return "\(curated.regionFlag) \(curated.name) (\(curated.dialectName))"
        }
        if let v = effectiveVoice {
            return "\(v.name) (\(v.language))"
        }
        return "🇺🇸 Samantha (American)"
    }

    // MARK: - Smart Clean Speech Prose
    /// Cleans raw markdown, code blocks, slide separators, JSON, and links so speech sounds completely human and fluid
    public func cleanTextForSpeech(_ raw: String) -> String {
        var text = raw

        // 1. Remove markdown code fences completely
        let codeFenceRegex = try? NSRegularExpression(pattern: "```[\\s\\S]*?```", options: [])
        text = codeFenceRegex?.stringByReplacingMatches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count), withTemplate: "") ?? text

        // 2. Remove inline code `...`
        let inlineCodeRegex = try? NSRegularExpression(pattern: "`[^`]+`", options: [])
        text = inlineCodeRegex?.stringByReplacingMatches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count), withTemplate: "") ?? text

        // 3. Remove slide tags / separators ---
        text = text.replacingOccurrences(of: "---", with: " ")
        text = text.replacingOccurrences(of: "<slide>", with: " ")
        text = text.replacingOccurrences(of: "</slide>", with: " ")

        // 4. Remove HTML tags <...>
        let htmlRegex = try? NSRegularExpression(pattern: "<[^>]+>", options: [])
        text = htmlRegex?.stringByReplacingMatches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count), withTemplate: "") ?? text

        // 5. Replace markdown links [title](url) with just title
        let linkRegex = try? NSRegularExpression(pattern: "\\[([^\\]]+)\\]\\([^\\)]+\\)", options: [])
        text = linkRegex?.stringByReplacingMatches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count), withTemplate: "$1") ?? text

        // 6. Remove raw URLs
        let urlRegex = try? NSRegularExpression(pattern: "https?://\\S+", options: [])
        text = urlRegex?.stringByReplacingMatches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count), withTemplate: "") ?? text

        // 7. Strip markdown header hashes and bullet stars
        text = text.replacingOccurrences(of: "#", with: "")
        text = text.replacingOccurrences(of: "**", with: "")
        text = text.replacingOccurrences(of: "*", with: "")
        text = text.replacingOccurrences(of: "•", with: "")
        text = text.replacingOccurrences(of: ">", with: "")

        // 8. Collapse whitespace
        let whitespaceRegex = try? NSRegularExpression(pattern: "\\s+", options: [])
        text = whitespaceRegex?.stringByReplacingMatches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count), withTemplate: " ") ?? text

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    public func setDialect(_ dialect: GenieVoiceDialect) {
        if let option = curatedWomenVoices.first(where: { $0.name.localizedCaseInsensitiveContains(dialect.name) }) {
            self.selectedVoiceIdentifier = option.id
        } else if let voice = AVSpeechSynthesisVoice.speechVoices().first(where: { $0.name.localizedCaseInsensitiveContains(dialect.name) }) {
            self.selectedVoiceIdentifier = voice.identifier
        } else if let fallback = AVSpeechSynthesisVoice(language: dialect.languageCode) {
            self.selectedVoiceIdentifier = fallback.identifier
        }
    }

    @MainActor
    public func speak(text: String) {
        speak(text)
    }

    // MARK: - Speech Actions
    @MainActor
    public func speak(_ rawText: String) {
        stop()

        let cleaned = cleanTextForSpeech(rawText)
        guard !cleaned.isEmpty else { return }

        let utterance = AVSpeechUtterance(string: cleaned)
        utterance.voice = effectiveVoice
        utterance.rate = Float(speechRate)
        utterance.pitchMultiplier = Float(speechPitch)
        utterance.volume = Float(speechVolume)

        currentSpokenText = cleaned
        isSpeaking = true
        isPaused = false
        startAudioEnergyPulse()

        synthesizer.speak(utterance)
    }

    @MainActor
    public func previewVoice(_ voice: GenieVoiceOption) {
        stop()

        let utterance = AVSpeechUtterance(string: voice.sampleGreeting)
        if let directVoice = AVSpeechSynthesisVoice(identifier: voice.id) {
            utterance.voice = directVoice
        } else if let byName = AVSpeechSynthesisVoice.speechVoices().first(where: { $0.name.contains(voice.name) }) {
            utterance.voice = byName
        } else {
            utterance.voice = AVSpeechSynthesisVoice(language: voice.languageCode)
        }

        utterance.rate = Float(speechRate)
        utterance.pitchMultiplier = Float(speechPitch)
        utterance.volume = Float(speechVolume)

        currentSpokenText = voice.sampleGreeting
        isSpeaking = true
        isPaused = false
        startAudioEnergyPulse()

        synthesizer.speak(utterance)
    }

    @MainActor
    public func toggleSpeak(_ text: String) {
        if isSpeaking {
            stop()
        } else {
            speak(text)
        }
    }

    @MainActor
    public func stopSpeaking() {
        stop()
    }

    public func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
        isPaused = false
        currentSpokenText = ""
        stopAudioEnergyPulse()
    }

    // MARK: - Audio Waveform Simulation Engine
    private func startAudioEnergyPulse() {
        energyTimer?.invalidate()
        let timer = Timer(timeInterval: 0.08, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, self.isSpeaking else { return }
                // Generate lively organic speech waveform values
                self.audioEnergy = CGFloat.random(in: 0.35...0.95)
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        energyTimer = timer
    }

    private func stopAudioEnergyPulse() {
        energyTimer?.invalidate()
        energyTimer = nil
        self.audioEnergy = 0.0
    }

    // MARK: - AVSpeechSynthesizerDelegate
    nonisolated public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didStart utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = true
            self.isPaused = false
        }
    }

    nonisolated public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.isPaused = false
            self.currentSpokenText = ""
            self.stopAudioEnergyPulse()
        }
    }

    nonisolated public func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            self.isPaused = false
            self.currentSpokenText = ""
            self.stopAudioEnergyPulse()
        }
    }
}
