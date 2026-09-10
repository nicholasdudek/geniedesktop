import SwiftUI
import AppKit

// MARK: - Appearance
//
// Text scale and accent are offered as a short list of vetted choices rather than a
// slider and a colour well. Two reasons: every value here has to stay legible against
// both the light and dark grounds, and the chat window is resizable down to 460pt, so
// an unbounded scale silently breaks the tab row and the message layout.

/// Bounded text scale. The multipliers stop at 1.32 because beyond that the chat
/// tab row wraps at the window's minimum width.
public enum GenieTextScale: String, CaseIterable, Identifiable, Sendable {
    case compact
    case standard
    case large
    case larger

    public var id: String { rawValue }

    public var multiplier: CGFloat {
        switch self {
        case .compact:  return 0.90
        case .standard: return 1.00
        case .large:    return 1.15
        case .larger:   return 1.32
        }
    }

    public var label: String {
        switch self {
        case .compact:  return "Compact"
        case .standard: return "Standard"
        case .large:    return "Large"
        case .larger:   return "Larger"
        }
    }

    /// Sample size shown next to each option so the choice is visible before it is made.
    public var previewPointSize: CGFloat { 13 * multiplier }
}

/// Curated accent palette. Each colour is given a separate light and dark variant so
/// it keeps roughly the same perceived contrast on either ground — a single hex that
/// reads well on dark almost never reads well on white.
public enum GenieAccent: String, CaseIterable, Identifiable, Sendable {
    case genieCyan
    case lampGold
    case seaTeal
    case violet
    case graphite

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .genieCyan: return "Genie Cyan"
        case .lampGold:  return "Lamp Gold"
        case .seaTeal:   return "Sea Teal"
        case .violet:    return "Violet"
        case .graphite:  return "Graphite"
        }
    }

    /// (light-ground variant, dark-ground variant)
    private var pair: (light: (Double, Double, Double), dark: (Double, Double, Double)) {
        switch self {
        case .genieCyan: return ((0.04, 0.49, 0.56), (0.24, 0.84, 0.93))
        case .lampGold:  return ((0.60, 0.42, 0.02), (0.94, 0.71, 0.16))
        case .seaTeal:   return ((0.05, 0.45, 0.40), (0.32, 0.82, 0.71))
        case .violet:    return ((0.42, 0.29, 0.72), (0.71, 0.60, 0.98))
        case .graphite:  return ((0.24, 0.27, 0.34), (0.72, 0.76, 0.84))
        }
    }

    public func color(dark: Bool) -> Color {
        let c = dark ? pair.dark : pair.light
        return Color(red: c.0, green: c.1, blue: c.2)
    }

    /// For swatches, where both variants should be visible at once.
    public var swatch: Color { color(dark: true) }
}


// MARK: - Chat layout themes
//
// Five presets, each a complete set of layout decisions rather than a colour swap:
// bubble treatment, corner radius, rhythm, and whether the sender is named. They are
// presets precisely so the combinations stay ones that were actually looked at.

public enum GenieChatTheme: String, CaseIterable, Identifiable, Sendable {
    /// Generous leading, hairline separators, no bubbles — reads like a printed page.
    case elegant
    /// Deep ground, gold hairline, high contrast. Restrained rather than loud.
    case atelier
    /// No ornament at all: flat rows, tight rhythm, maximum text per screen.
    case minimal
    /// Tinted bubbles with a soft gradient and a little motion on arrival.
    case dynamic
    /// Cards that float clear of the ground on a soft shadow, scrolling as sheets.
    case floatingScrolls
    /// Loud and close: heavy type, flat saturated fills, square-ish corners, snappy.
    case popPunk

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .elegant:        return "Elegant"
        case .atelier:        return "Atelier"
        case .minimal:        return "Minimal"
        case .dynamic:        return "Dynamic"
        case .floatingScrolls: return "Floating Scrolls"
        case .popPunk:        return "Pop Punk"
        }
    }

    public var blurb: String {
        switch self {
        case .elegant:        return "Serif headings, wide leading, hairline rules"
        case .atelier:        return "Deep ground, gold hairline, high contrast"
        case .minimal:        return "No bubbles, tight rhythm, most text per screen"
        case .dynamic:        return "Tinted gradient bubbles that animate in"
        case .floatingScrolls: return "Sheets that float clear on a soft shadow"
        case .popPunk:        return "Heavy type, flat colour, snappy and loud"
        }
    }

    /// Corner radius for a message container. Zero means the theme draws no container.
    public var cornerRadius: CGFloat {
        switch self {
        case .elegant:        return 0
        case .atelier:        return 4
        case .minimal:        return 0
        case .dynamic:        return 18
        case .floatingScrolls: return 14
        case .popPunk:        return 6
        }
    }

    public var rowSpacing: CGFloat {
        switch self {
        case .elegant:        return 22
        case .atelier:        return 18
        case .minimal:        return 8
        case .dynamic:        return 12
        case .floatingScrolls: return 16
        case .popPunk:        return 10
        }
    }

    public var innerPadding: CGFloat {
        switch self {
        case .elegant:        return 4
        case .atelier:        return 12
        case .minimal:        return 2
        case .dynamic:        return 13
        case .floatingScrolls: return 15
        case .popPunk:        return 12
        }
    }

    public var lineSpacing: CGFloat {
        switch self {
        case .elegant:        return 6
        case .atelier:        return 4
        case .minimal:        return 1.5
        case .dynamic:        return 3
        case .floatingScrolls: return 4
        case .popPunk:        return 2
        }
    }

    /// Whether the theme fills a container behind the message at all.
    public var drawsContainer: Bool {
        switch self {
        case .elegant, .minimal: return false
        case .atelier, .dynamic, .floatingScrolls, .popPunk: return true
        }
    }

    /// A hairline under each row, for the themes that separate by rule instead of fill.
    public var drawsSeparator: Bool {
        switch self {
        case .elegant, .atelier: return true
        case .minimal, .dynamic, .floatingScrolls, .popPunk: return false
        }
    }

    public var shadowRadius: CGFloat {
        switch self {
        case .floatingScrolls: return 14
        case .dynamic:         return 5
        default:               return 0
        }
    }

    public var usesSerifHeadings: Bool { self == .elegant || self == .atelier }

    /// Arrival animation. Nil where the theme is deliberately still.
    public var arrival: Animation? {
        switch self {
        case .popPunk:         return .spring(response: 0.22, dampingFraction: 0.58)
        case .dynamic:         return .spring(response: 0.34, dampingFraction: 0.72)
        case .floatingScrolls: return .spring(response: 0.42, dampingFraction: 0.85)
        default:               return nil
        }
    }
}

@MainActor
public final class GenieAppearance: ObservableObject {
    public static let shared = GenieAppearance()

    @AppStorage(PrefKey.genieTextScale) private var scaleRaw: String = GenieTextScale.standard.rawValue
    @AppStorage(PrefKey.genieAccent) private var accentRaw: String = GenieAccent.genieCyan.rawValue
    @AppStorage(PrefKey.genieChatTheme) private var chatThemeRaw: String = GenieChatTheme.elegant.rawValue

    private init() {}

    public var textScale: GenieTextScale {
        get { GenieTextScale(rawValue: scaleRaw) ?? .standard }
        set { objectWillChange.send(); scaleRaw = newValue.rawValue }
    }

    public var accent: GenieAccent {
        get { GenieAccent(rawValue: accentRaw) ?? .genieCyan }
        set { objectWillChange.send(); accentRaw = newValue.rawValue }
    }

    public var chatTheme: GenieChatTheme {
        get { GenieChatTheme(rawValue: chatThemeRaw) ?? .elegant }
        set { objectWillChange.send(); chatThemeRaw = newValue.rawValue }
    }

    /// Scale for a pane of the given width. A narrow pane walks the scale back a step
    /// rather than letting a Larger setting overflow a 460pt window — the setting is
    /// still honoured wherever there is room for it.
    public func effectiveMultiplier(paneWidth: CGFloat) -> CGFloat {
        let m = textScale.multiplier
        guard paneWidth > 0 else { return m }
        if paneWidth < 520 { return min(m, 1.15) }
        if paneWidth < 420 { return min(m, 1.00) }
        return m
    }

    public func scaled(_ size: CGFloat, paneWidth: CGFloat = .greatestFiniteMagnitude) -> CGFloat {
        (size * effectiveMultiplier(paneWidth: paneWidth)).rounded()
    }
}

// MARK: - Applying it

private struct GenieTypographyModifier: ViewModifier {
    @ObservedObject private var appearance = GenieAppearance.shared
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        GeometryReader { geo in
            content
                // Bounded, so a Larger setting cannot push text past what the pane holds.
                .environment(\.genieTextMultiplier, appearance.effectiveMultiplier(paneWidth: geo.size.width))
                .tint(appearance.accent.color(dark: colorScheme == .dark))
                .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

private struct GenieTextMultiplierKey: EnvironmentKey {
    static let defaultValue: CGFloat = 1.0
}

public extension EnvironmentValues {
    var genieTextMultiplier: CGFloat {
        get { self[GenieTextMultiplierKey.self] }
        set { self[GenieTextMultiplierKey.self] = newValue }
    }
}

public extension View {
    /// Apply the user's text scale and accent to a pane, bounded by the pane's own width.
    func genieAppearance() -> some View {
        modifier(GenieTypographyModifier())
    }

    /// A system font that follows the user's text scale.
    func genieScaledFont(_ size: CGFloat, weight: Font.Weight = .regular, design: Font.Design = .default) -> some View {
        modifier(GenieScaledFont(size: size, weight: weight, design: design))
    }
}

private struct GenieScaledFont: ViewModifier {
    let size: CGFloat
    let weight: Font.Weight
    let design: Font.Design
    @Environment(\.genieTextMultiplier) private var multiplier

    func body(content: Content) -> some View {
        content.font(.system(size: (size * multiplier).rounded(), weight: weight, design: design))
    }
}
