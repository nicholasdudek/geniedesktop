import AppKit
import SwiftUI

// MARK: - App Font Model

public struct AppFontItem: Identifiable, Hashable {
    public let id: String
    public let familyName: String
    public let displayName: String
    public let category: String
    public let sampleText: String
    public let isSystem: Bool
}

// MARK: - App Font Manager

@MainActor
public final class AppFontManager: ObservableObject {
    public static let shared = AppFontManager()

    @Published public var availableFonts: [AppFontItem] = []
    @Published public var currentFontFamily: String {
        didSet {
            UserDefaults.standard.set(currentFontFamily, forKey: PrefKey.appFontFamily)
            NotificationCenter.default.post(name: NSNotification.Name("NexusFontFamilyChanged"), object: currentFontFamily)
        }
    }

    private init() {
        let saved = UserDefaults.standard.string(forKey: PrefKey.appFontFamily) ?? "System (San Francisco)"
        self.currentFontFamily = saved
        self.loadAvailableFonts()
    }

    public func loadAvailableFonts() {
        var items: [AppFontItem] = []

        // 1. Default Apple System Font
        items.append(
            AppFontItem(
                id: "System (San Francisco)",
                familyName: "System (San Francisco)",
                displayName: "System (San Francisco)",
                category: "System ",
                sampleText: "San Francisco — Authentic Apple Default",
                isSystem: true
            )
        )

        // 2. All available macOS Font Families
        let systemFamilies = NSFontManager.shared.availableFontFamilies.sorted()

        for fam in systemFamilies {
            guard fam != "System (San Francisco)" else { continue }
            let cat = categorizeFont(fam)
            items.append(
                AppFontItem(
                    id: fam,
                    familyName: fam,
                    displayName: fam,
                    category: cat,
                    sampleText: "The quick brown fox jumps over the lazy dog",
                    isSystem: false
                )
            )
        }

        self.availableFonts = items
    }

    private func categorizeFont(_ name: String) -> String {
        let lower = name.lowercased()
        if lower.contains("mono") || lower.contains("code") || lower.contains("courier") || lower.contains("menlo") || lower.contains("consolas") {
            return "Monospace 💻"
        } else if lower.contains("serif") || lower.contains("times") || lower.contains("georgia") || lower.contains("palatino") || lower.contains("didot") || lower.contains("baskerville") || lower.contains("bookman") {
            return "Serif 📜"
        } else if lower.contains("script") || lower.contains("hand") || lower.contains("marker") || lower.contains("chalk") || lower.contains("comic") || lower.contains("zapfino") || lower.contains("brush") {
            return "Script & Display 🎨"
        } else {
            return "Modern Sans 🔤"
        }
    }

    public func font(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        if currentFontFamily == "System (San Francisco)" || currentFontFamily == "System" || currentFontFamily.isEmpty {
            return .system(size: size, weight: weight)
        }
        return .custom(currentFontFamily, size: size)
    }

    public static func resolveFont(family: String, size: CGFloat, weight: Font.Weight = .regular) -> Font {
        if family == "System (San Francisco)" || family == "System" || family.isEmpty {
            return .system(size: size, weight: weight)
        }
        return .custom(family, size: size)
    }

    public func resetToDefault() {
        currentFontFamily = "System (San Francisco)"
    }
}
