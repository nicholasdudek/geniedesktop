import AppKit
import AVFoundation
import Combine
import Foundation
import Speech
import SwiftUI

// MARK: - 🎙️ Voice Command Enum
public enum GenieVoiceAction: String, CaseIterable, Identifiable {
    case sendChat = "send_chat"
    case sendToMobile = "send_to_mobile"
    case pickUpOniPhoneDuo = "pickup_iphone_duo"
    case clear = "clear"

    public var id: String { rawValue }

    public var displayTitle: String {
        switch self {
        case .sendChat: return "Send / Click Enter"
        case .sendToMobile: return "Send Chat to Mobile"
        case .pickUpOniPhoneDuo: return "Pick up on iPhone Duo"
        case .clear: return "Clear Input"
        }
    }

    public var triggerPhrases: [String] {
        switch self {
        case .sendChat:
            return ["click enter", "send chat", "send message", "send it", "hit enter", "submit", "send"]
        case .sendToMobile:
            return ["send to mobile", "send chat to mobile", "send to iphone", "push to phone", "send message to phone", "ping my phone"]
        case .pickUpOniPhoneDuo:
            return [
                "pick up on iphone duo same size dimense",
                "pick up on iphone duo",
                "pick up on iphone",
                "pick up on phone",
                "iphone duo same size dimense",
                "iphone duo",
                "switch to iphone duo",
                "handoff to iphone"
            ]
        case .clear:
            return ["clear chat", "clear input", "cancel message", "erase text", "clear"]
        }
    }
}

// MARK: - 🎙️ Native Speech Recognition & Voice Command Engine
@MainActor
public final class GenieSpeechRecognitionEngine: NSObject, ObservableObject {
    public static let shared = GenieSpeechRecognitionEngine()

    // Published State
    @Published public private(set) var isAuthorized: Bool = false
    @Published public private(set) var isRunning: Bool = false
    @Published public private(set) var isWakeWordArmed: Bool = true
    @Published public private(set) var isActivelyRecording: Bool = false
    @Published public private(set) var liveTranscript: String = ""
    @Published public private(set) var lastDetectedCommand: GenieVoiceAction? = nil
    @Published public private(set) var audioLevel: Float = 0.0 // 0.0 ... 1.0 for dynamic UI waveform
    @Published public var errorMessage: String? = nil

    public var isListening: Bool { isRunning }
    public var activeTranscript: String { liveTranscript }

    // Preferences
    @AppStorage(PrefKey.voiceSpeechRecognitionEnabled) public var speechRecognitionEnabled: Bool = false
    @AppStorage(PrefKey.voiceWakeWordEnabled) public var wakeWordEnabled: Bool = false
    @AppStorage(PrefKey.voiceWakeWordTrigger) public var wakeWordTrigger: String = "hey genie"
    @AppStorage(PrefKey.voiceAutoSendOnCommand) public var autoSendOnCommand: Bool = true

    // Audio & Speech Pipeline
    private var audioEngine: AVAudioEngine?
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var silenceTimer: Timer?
    private var levelMeterTimer: Timer?
    private var lastSpokenTimestamp: Date = Date()

    // Supported Wake Words
    private let recognizedWakeWords = ["hey genie", "genie", "listen genie", "ok genie"]

    override private init() {
        super.init()
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
        checkAuthorization()
    }

    // MARK: - Authorization
    public func checkAuthorization() {
        guard Bundle.main.object(forInfoDictionaryKey: "NSSpeechRecognitionUsageDescription") != nil else {
            self.isAuthorized = false
            return
        }
        let status = SFSpeechRecognizer.authorizationStatus()
        switch status {
        case .authorized:
            self.isAuthorized = true
        case .notDetermined:
            SFSpeechRecognizer.requestAuthorization { [weak self] newStatus in
                Task { @MainActor [weak self] in
                    self?.isAuthorized = (newStatus == .authorized)
                    if newStatus == .authorized && (self?.speechRecognitionEnabled ?? false) && (self?.wakeWordEnabled ?? false) {
                        self?.startListening()
                    }
                }
            }
        default:
            self.isAuthorized = false
        }
    }

    // MARK: - Lifecycle Controls
    public func toggleListening() {
        if isRunning {
            stopListening()
        } else {
            startListening()
        }
    }

    public func startListening() {
        guard !isRunning else { return }
        guard isAuthorized else {
            checkAuthorization()
            return
        }

        do {
            try startAudioPipeline()
            self.isRunning = true
            self.errorMessage = nil
            self.lastSpokenTimestamp = Date()
        } catch {
            self.errorMessage = "Failed to initialize microphone stream: \(error.localizedDescription)"
            self.isRunning = false
        }
    }

    public func stopListening() {
        tearDownAudioPipeline()
        self.isRunning = false
        self.isActivelyRecording = false
        self.audioLevel = 0.0
    }

    // MARK: - Audio & Recognition Pipeline
    private func startAudioPipeline() throws {
        tearDownAudioPipeline()

        let engine = AVAudioEngine()
        self.audioEngine = engine

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = false
        self.recognitionRequest = request

        guard let recognizer = speechRecognizer, recognizer.isAvailable else {
            throw NSError(domain: "GenieSpeech", code: -1, userInfo: [NSLocalizedDescriptionKey: "Speech recognizer is currently unavailable."])
        }

        let inputNode = engine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)

        // Install Audio Tap to capture live speech buffers & calculate audio energy levels
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { [weak self] (buffer: AVAudioPCMBuffer, _: AVAudioTime) in
            self?.recognitionRequest?.append(buffer)

            // Calculate instantaneous RMS energy
            guard let channelData = buffer.floatChannelData?[0] else { return }
            let frameLength = UInt(buffer.frameLength)
            var sum: Float = 0.0
            for i in 0..<Int(frameLength) {
                let sample = channelData[i]
                sum += sample * sample
            }
            let rms = sqrt(sum / Float(frameLength))
            let normalized = min(1.0, max(0.0, rms * 14.0))

            Task { @MainActor [weak self] in
                self?.audioLevel = normalized
            }
        }

        engine.prepare()
        try engine.start()

        // Silence watchdog: if user stops speaking for 2.0s in dictation mode, auto-release the microphone immediately
        self.silenceTimer?.invalidate()
        self.silenceTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, self.isRunning else { return }
                if !self.wakeWordEnabled {
                    let elapsed = Date().timeIntervalSince(self.lastSpokenTimestamp)
                    if elapsed > 2.0 {
                        self.stopListening()
                    }
                }
            }
        }

        // Recognition Task
        self.recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor [weak self] in
                guard let self = self else { return }

                if let result = result {
                    let rawString = result.bestTranscription.formattedString
                    self.processTranscribedText(rawString)
                }

                if error != nil || (result?.isFinal ?? false) {
                    if self.isRunning && self.wakeWordEnabled && self.speechRecognitionEnabled {
                        self.restartSession()
                    } else {
                        self.stopListening()
                    }
                }
            }
        }
    }

    private func tearDownAudioPipeline() {
        recognitionTask?.cancel()
        recognitionTask = nil

        recognitionRequest?.endAudio()
        recognitionRequest = nil

        if let engine = audioEngine {
            if engine.isRunning {
                engine.stop()
            }
            engine.inputNode.removeTap(onBus: 0)
        }
        audioEngine = nil
        silenceTimer?.invalidate()
        silenceTimer = nil
    }

    private func restartSession() {
        tearDownAudioPipeline()
        try? startAudioPipeline()
    }

    // MARK: - Speech Stream & Intent Parsing
    private func processTranscribedText(_ text: String) {
        let lower = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !lower.isEmpty else { return }
        lastSpokenTimestamp = Date()

        // 1. Wake-Word Detection ("Hey Genie", "Genie", etc.)
        if !isActivelyRecording && wakeWordEnabled {
            for trigger in recognizedWakeWords {
                if lower.contains(trigger) {
                    triggerWakeWordActivation()
                    // Extract remainder of sentence after the trigger
                    if let range = lower.range(of: trigger) {
                        let remainder = String(text[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
                        if !remainder.isEmpty {
                            updateTranscript(remainder)
                        }
                    }
                    return
                }
            }
        }

        // 2. Action Phrase Classifier (Check from selection of command phrases)
        if let action = matchActionPhrase(in: lower) {
            self.lastDetectedCommand = action
            executeVoiceAction(action, rawTranscript: self.liveTranscript)
            return
        }

        // 3. Live Transcription to Chat
        updateTranscript(text)
    }

    private func triggerWakeWordActivation() {
        self.isActivelyRecording = true
        HapticFeedback.selection()

        // Play feedback tone
        NSSound(named: "Tink")?.play()

        // Ensure Chat Window is brought front or presented
        FinderChatWindowManager.shared.show()

        NotificationCenter.default.post(name: NSNotification.Name("NexusVoiceWakeWordDetected"), object: nil)
    }

    private func updateTranscript(_ text: String) {
        var clean = text
        // Strip wake-words if leading
        for trigger in recognizedWakeWords {
            if clean.lowercased().hasPrefix(trigger) {
                clean = String(clean.dropFirst(trigger.count)).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        self.liveTranscript = clean

        // Broadcast live transcript update so chat text fields update in real time
        NotificationCenter.default.post(name: NSNotification.Name("NexusSpeechTranscriptUpdated"), object: clean)
    }

    // MARK: - Action Phrase Matching
    private func matchActionPhrase(in lower: String) -> GenieVoiceAction? {
        for action in GenieVoiceAction.allCases {
            for phrase in action.triggerPhrases {
                if lower.hasSuffix(phrase) || lower == phrase {
                    return action
                }
            }
        }
        return nil
    }

    // MARK: - Action Dispatcher
    public func executeVoiceAction(_ action: GenieVoiceAction, rawTranscript: String) {
        HapticFeedback.heavy()
        let cleanPrompt = rawTranscript.trimmingCharacters(in: .whitespacesAndNewlines)

        switch action {
        case .sendChat:
            // "click enter", "send chat", "send"
            NotificationCenter.default.post(name: NSNotification.Name("NexusSpeechCommandTriggered"), object: action)
            NotificationCenter.default.post(name: NSNotification.Name("NexusVoiceSubmitChat"), object: cleanPrompt)
            self.liveTranscript = ""

        case .sendToMobile:
            // "send to mobile", "send to iphone", "send chat to mobile"
            let targetText = cleanPrompt.isEmpty ? "Hello from Genie Desktop Voice!" : cleanPrompt
            let success = GeniePhoneBridgeManager.shared.sendiMessage(message: targetText)
            GeniePhoneBridgeManager.shared.pingNicholasPhone(withSummary: targetText)

            GenieVoiceEngine.shared.speak(text: success ? "Chat relayed directly to your iPhone." : "Message queued to your Apple ID.")
            NotificationCenter.default.post(name: NSNotification.Name("NexusSpeechCommandTriggered"), object: action)
            self.liveTranscript = ""

        case .pickUpOniPhoneDuo:
            // "pick up on iphone duo same size dimense", "pick up on iphone", "iphone duo"
            launchiPhoneDuoCompanionHandoff(prompt: cleanPrompt)
            NotificationCenter.default.post(name: NSNotification.Name("NexusSpeechCommandTriggered"), object: action)

        case .clear:
            // "clear chat", "clear input", "cancel"
            self.liveTranscript = ""
            NotificationCenter.default.post(name: NSNotification.Name("NexusSpeechCommandTriggered"), object: action)
            NotificationCenter.default.post(name: NSNotification.Name("NexusSpeechClearChat"), object: nil)
        }
    }

    // MARK: - iPhone Duo Continuity & Cross-Device Handoff
    public func launchiPhoneDuoCompanionHandoff(prompt: String) {
        let bridge = GeniePhoneBridgeManager.shared
        if !bridge.isServerRunning {
            bridge.startServer()
        }

        // iPhone Duo standard dimension payload: 393 x 852 pt (or 786 x 852 dual-screen split mode)
        let companionURL = "\(bridge.mobileRemoteURL)/duo"

        // Copy to system clipboard for instant Paste on iPhone (Universal Clipboard)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(companionURL, forType: .string)

        // Send via iMessage link if text is present
        let msg = "📱 [Genie iPhone Duo Companion Ready]\nPick up your active desktop workspace in matched iPhone Duo dimensions:\n\(companionURL)"
        bridge.sendiMessage(to: "me", message: msg)

        GenieVoiceEngine.shared.speak(text: "Session transferred to iPhone Duo dimensions. Universal link copied to clipboard.")
    }
}
