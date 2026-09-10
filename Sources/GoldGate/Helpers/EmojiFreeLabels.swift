import Foundation

public extension String {
    /// The string with emoji removed, for UI labels that must read as professional
    /// (App Store screenshots, menus, settings panes).
    ///
    /// Menu and tab `rawValue`s stay as they are: they are stable identifiers that
    /// notifications route by and that AppStorage persists, so renaming them would
    /// break routing and orphan saved preferences. Strip at the display layer instead.
    var emojiFree: String {
        let kept = unicodeScalars.filter { sc in
            // Variation selectors, which turn a text glyph into an emoji one.
            if sc == "\u{FE0F}" || sc == "\u{FE0E}" { return false }
            if sc.properties.isEmojiPresentation || sc.properties.isEmojiModifier { return false }
            // Symbols that are emoji only with a selector (⚙ ⚡ ⏰ …). The value guard
            // keeps ASCII digits, '#' and '*', which report isEmoji == true.
            if sc.properties.isEmoji && sc.value > 0x2000 { return false }
            if (0x1F000...0x1FAFF).contains(sc.value) { return false }
            return true
        }
        var out = ""
        out.unicodeScalars.append(contentsOf: kept)
        return out
            .replacingOccurrences(of: #" +"#, with: " ", options: .regularExpression)
            .replacingOccurrences(of: #"\s+\)"#, with: ")", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
    }
}
