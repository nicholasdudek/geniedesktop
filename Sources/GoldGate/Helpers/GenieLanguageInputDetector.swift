import Carbon
import Combine
import Foundation
import NaturalLanguage
import SwiftUI

// MARK: - 🌐 Genie Intelligent Language & Keyboard Input Detector
/// Detects active macOS keyboard layouts in real-time via Carbon TIS (Text Input Source)
/// and analyzes typed input using Apple's NaturalLanguage framework and high-speed Unicode script heuristics.
@MainActor
public final class GenieLanguageInputDetector: ObservableObject {
    public static let shared = GenieLanguageInputDetector()

    // Active Keyboard Layout State
    @Published public private(set) var activeKeyboardLayoutName: String = "U.S."
    @Published public private(set) var activeKeyboardLanguageCode: String = "en"
    @Published public private(set) var detectedKeyboardLanguage: AppLanguage? = .english

    // Input Text Detection State
    @Published public private(set) var lastDetectedInputLanguage: AppLanguage? = nil
    @Published public private(set) var lastDetectedInputConfidence: Double = 0.0

    // Auto-Detection Preferences
    @AppStorage(PrefKey.autoDetectLanguageFromKeyboard) public var autoDetectFromKeyboard: Bool = false
    @AppStorage(PrefKey.autoDetectLanguageFromInput) public var autoDetectFromInput: Bool = false

    private var inputSourceObserver: NSObjectProtocol?
    private let recognizer = NLLanguageRecognizer()

    private init() {
        refreshKeyboardInputSource()
        installInputSourceObserver()
    }

    deinit {
        if let observer = inputSourceObserver {
            DistributedNotificationCenter.default().removeObserver(observer)
        }
    }

    // MARK: - Keyboard Input Source Detection (Carbon TIS)

    /// Refreshes the currently active macOS keyboard input source and maps it to an AppLanguage.
    public func refreshKeyboardInputSource() {
        guard let currentSource = TISCopyCurrentKeyboardInputSource()?.takeRetainedValue() else {
            return
        }

        // 1. Get Localized Name (e.g. "2-Set Korean", "U.S.", "Pinyin - Simplified", "Romaji")
        if let namePtr = TISGetInputSourceProperty(currentSource, kTISPropertyLocalizedName) {
            let name = Unmanaged<CFString>.fromOpaque(namePtr).takeUnretainedValue() as String
            self.activeKeyboardLayoutName = name
        }

        // 2. Get Input Source Languages (e.g. ["ko"], ["en"], ["ja"], ["zh-Hans"])
        var primaryLangCode = "en"
        if let langsPtr = TISGetInputSourceProperty(currentSource, kTISPropertyInputSourceLanguages) {
            let langs = Unmanaged<CFArray>.fromOpaque(langsPtr).takeUnretainedValue() as NSArray
            if let firstCode = langs.firstObject as? String {
                primaryLangCode = firstCode.lowercased()
                self.activeKeyboardLanguageCode = primaryLangCode
            }
        }

        // 3. Map Language Code to AppLanguage
        let matchedLanguage = mapLanguageCodeToAppLanguage(primaryLangCode, layoutName: activeKeyboardLayoutName)
        self.detectedKeyboardLanguage = matchedLanguage

        // 4. Auto-Switch App Language if Enabled
        if autoDetectFromKeyboard, let lang = matchedLanguage {
            let currentAppLang = UserDefaults.standard.string(forKey: PrefKey.appLanguage) ?? "English (US)"
            if currentAppLang != lang.rawValue {
                UserDefaults.standard.set(lang.rawValue, forKey: PrefKey.appLanguage)
                NotificationCenter.default.post(name: UserDefaults.didChangeNotification, object: nil)
            }
        }
    }

    private func installInputSourceObserver() {
        let notificationName = NSNotification.Name(kTISNotifySelectedKeyboardInputSourceChanged as String)
        inputSourceObserver = DistributedNotificationCenter.default().addObserver(
            forName: notificationName,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshKeyboardInputSource()
            }
        }
    }

    // MARK: - Text Input Language Detection (NaturalLanguage + Unicode Heuristics)

    /// Analyzes a string typed by the user to detect its language and optionally adapt the app language.
    @discardableResult
    public func processTypedInput(_ text: String) -> AppLanguage? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= 2 else { return nil }

        // Fast-path: Unicode script block inspection (zero-latency, 100% accurate for Asian / non-Latin scripts)
        if containsHangul(trimmed) {
            let lang = AppLanguage.korean
            self.lastDetectedInputLanguage = lang
            self.lastDetectedInputConfidence = 1.0
            applyInputDetectionIfEnabled(lang)
            return lang
        }

        if containsKana(trimmed) {
            let lang = AppLanguage.japanese
            self.lastDetectedInputLanguage = lang
            self.lastDetectedInputConfidence = 1.0
            applyInputDetectionIfEnabled(lang)
            return lang
        }

        if containsArabic(trimmed) {
            let lang = AppLanguage.arabic
            self.lastDetectedInputLanguage = lang
            self.lastDetectedInputConfidence = 1.0
            applyInputDetectionIfEnabled(lang)
            return lang
        }

        if containsHanzi(trimmed) {
            let lang = AppLanguage.chinese
            self.lastDetectedInputLanguage = lang
            self.lastDetectedInputConfidence = 0.95
            applyInputDetectionIfEnabled(lang)
            return lang
        }

        // Apple NaturalLanguage Framework Recognizer for Latin / European languages
        recognizer.reset()
        recognizer.processString(trimmed)

        guard let dominant = recognizer.dominantLanguage else { return nil }
        let hypotheses = recognizer.languageHypotheses(withMaximum: 1)
        let confidence = hypotheses[dominant] ?? 0.0

        // Only commit if confidence threshold is met
        guard confidence >= 0.45 else { return nil }

        let matched = mapNLLanguageToAppLanguage(dominant)
        self.lastDetectedInputLanguage = matched
        self.lastDetectedInputConfidence = confidence

        if let lang = matched {
            applyInputDetectionIfEnabled(lang)
        }

        return matched
    }

    private func applyInputDetectionIfEnabled(_ lang: AppLanguage) {
        guard autoDetectFromInput else { return }
        let currentAppLang = UserDefaults.standard.string(forKey: PrefKey.appLanguage) ?? "English (US)"
        if currentAppLang != lang.rawValue {
            UserDefaults.standard.set(lang.rawValue, forKey: PrefKey.appLanguage)
            NotificationCenter.default.post(name: UserDefaults.didChangeNotification, object: nil)
        }
    }

    // MARK: - Mappings & Fast Script Parsers

    private func mapLanguageCodeToAppLanguage(_ code: String, layoutName: String) -> AppLanguage? {
        let lowerCode = code.lowercased()
        let lowerName = layoutName.lowercased()

        if lowerCode.hasPrefix("ko") || lowerName.contains("korean") || lowerName.contains("hangul") {
            return .korean
        }
        if lowerCode.hasPrefix("ja") || lowerName.contains("japanese") || lowerName.contains("romaji") || lowerName.contains("kana") {
            return .japanese
        }
        if lowerCode.hasPrefix("zh") || lowerName.contains("chinese") || lowerName.contains("pinyin") || lowerName.contains("bopomofo") || lowerName.contains("cangjie") {
            return .chinese
        }
        if lowerCode.hasPrefix("es") || lowerName.contains("spanish") || lowerName.contains("español") {
            return .spanish
        }
        if lowerCode.hasPrefix("fr") || lowerName.contains("french") || lowerName.contains("français") {
            return .french
        }
        if lowerCode.hasPrefix("de") || lowerName.contains("german") || lowerName.contains("deutsch") {
            return .german
        }
        if lowerCode.hasPrefix("it") || lowerName.contains("italian") || lowerName.contains("italiano") {
            return .italian
        }
        if lowerCode.hasPrefix("pt") || lowerName.contains("portuguese") || lowerName.contains("português") {
            return .portuguese
        }
        if lowerCode.hasPrefix("ar") || lowerName.contains("arabic") || lowerName.contains("العربية") {
            return .arabic
        }
        if lowerCode.hasPrefix("en") || lowerName.contains("u.s.") || lowerName.contains("british") || lowerName.contains("abc") {
            return .english
        }
        return nil
    }

    private func mapNLLanguageToAppLanguage(_ lang: NLLanguage) -> AppLanguage? {
        switch lang {
        case .korean: return .korean
        case .japanese: return .japanese
        case .simplifiedChinese, .traditionalChinese: return .chinese
        case .spanish: return .spanish
        case .french: return .french
        case .german: return .german
        case .italian: return .italian
        case .portuguese: return .portuguese
        case .arabic: return .arabic
        case .english: return .english
        default: return nil
        }
    }

    private func containsHangul(_ text: String) -> Bool {
        for scalar in text.unicodeScalars {
            // Hangul Syllables (AC00-D7AF), Jamo (1100-11FF), Compatibility Jamo (3130-318F)
            if (scalar.value >= 0xAC00 && scalar.value <= 0xD7AF) ||
               (scalar.value >= 0x1100 && scalar.value <= 0x11FF) ||
               (scalar.value >= 0x3130 && scalar.value <= 0x318F) {
                return true
            }
        }
        return false
    }

    private func containsKana(_ text: String) -> Bool {
        for scalar in text.unicodeScalars {
            // Hiragana (3040-309F), Katakana (30A0-30FF)
            if (scalar.value >= 0x3040 && scalar.value <= 0x309F) ||
               (scalar.value >= 0x30A0 && scalar.value <= 0x30FF) {
                return true
            }
        }
        return false
    }

    private func containsHanzi(_ text: String) -> Bool {
        for scalar in text.unicodeScalars {
            // CJK Unified Ideographs (4E00-9FFF)
            if scalar.value >= 0x4E00 && scalar.value <= 0x9FFF {
                return true
            }
        }
        return false
    }

    private func containsArabic(_ text: String) -> Bool {
        for scalar in text.unicodeScalars {
            // Arabic (0600-06FF), Arabic Supplement (0750-077F)
            if (scalar.value >= 0x0600 && scalar.value <= 0x06FF) ||
               (scalar.value >= 0x0750 && scalar.value <= 0x077F) {
                return true
            }
        }
        return false
    }
}
