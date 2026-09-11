import SwiftUI

/// Light/dark palette for the embedded code editor and its file browser.
///
/// The editor used to hardcode one dark palette, so it stayed near-black even
/// with the rest of the system in light appearance. `.system` follows the
/// window's appearance; `.dark` and `.light` pin it regardless.
public enum GenieEditorTheme: String, CaseIterable, Identifiable, Sendable {
    case system
    case xcode
    case dark
    case light

    public var id: String { rawValue }

    public var label: String {
        switch self {
        case .system: return "Auto"
        case .xcode:  return "Xcode Pro"
        case .dark:   return "Dark"
        case .light:  return "Light"
        }
    }

    public var symbolName: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .xcode:  return "hammer.fill"
        case .dark:   return "moon.fill"
        case .light:  return "sun.max.fill"
        }
    }

    /// Every color the editor chrome needs. Kept flat and explicit so a new
    /// surface can't quietly fall back to a hardcoded literal.
    public struct Palette: Sendable {
        public let isDark: Bool
        /// The code canvas itself.
        public let canvas: Color
        /// Panels beside the canvas — sidebar, chat dock.
        public let surface: Color
        /// Toolbars, ribbons, status bars.
        public let chrome: Color
        /// Primary code and label text.
        public let text: Color
        /// Captions, line numbers, inactive labels.
        public let secondaryText: Color
        /// Selected row background.
        public let selection: Color
        /// Terminal output text.
        public let terminalText: Color
        /// Terminal drawer background.
        public let terminalBackground: Color
        public let accent: Color

        /// Separators and control fills, at the caller's chosen weight. Flips
        /// from light-on-dark to dark-on-light so hairlines stay visible.
        public func hairline(_ opacity: Double) -> Color {
            (isDark ? Color.white : Color.black).opacity(opacity)
        }

        /// Recessed backgrounds (drawers, wells) at the caller's weight.
        public func scrim(_ opacity: Double) -> Color {
            (isDark ? Color.black : Color(red: 0.62, green: 0.64, blue: 0.70)).opacity(opacity)
        }
    }

    private static let xcodePalette = Palette(
        isDark: true,
        canvas: Color(red: 0.16, green: 0.17, blue: 0.22),
        surface: Color(red: 0.13, green: 0.14, blue: 0.18),
        chrome: Color(red: 0.11, green: 0.12, blue: 0.16),
        text: Color(red: 0.94, green: 0.95, blue: 0.98),
        secondaryText: Color(red: 0.60, green: 0.63, blue: 0.72),
        selection: Color(red: 0.22, green: 0.32, blue: 0.52),
        terminalText: Color(red: 0.88, green: 0.96, blue: 0.90),
        terminalBackground: Color(red: 0.10, green: 0.11, blue: 0.15),
        accent: Color(red: 0.98, green: 0.44, blue: 0.24) // Apple Swift Orange
    )

    private static let darkPalette = Palette(
        isDark: true,
        canvas: Color(red: 0.11, green: 0.12, blue: 0.15),
        surface: Color(red: 0.10, green: 0.11, blue: 0.14),
        chrome: Color(red: 0.09, green: 0.10, blue: 0.13),
        text: Color(red: 0.88, green: 0.90, blue: 0.95),
        secondaryText: Color(red: 0.58, green: 0.61, blue: 0.68),
        selection: Color(red: 0.14, green: 0.16, blue: 0.22),
        terminalText: Color(red: 0.85, green: 0.95, blue: 0.88),
        terminalBackground: Color(red: 0.08, green: 0.09, blue: 0.11),
        accent: Color(red: 0.36, green: 0.72, blue: 1.00)
    )

    private static let lightPalette = Palette(
        isDark: false,
        canvas: Color(red: 0.99, green: 0.99, blue: 1.00),
        surface: Color(red: 0.95, green: 0.96, blue: 0.97),
        chrome: Color(red: 0.92, green: 0.93, blue: 0.95),
        text: Color(red: 0.12, green: 0.14, blue: 0.18),
        secondaryText: Color(red: 0.42, green: 0.45, blue: 0.52),
        selection: Color(red: 0.84, green: 0.89, blue: 0.98),
        terminalText: Color(red: 0.10, green: 0.32, blue: 0.18),
        terminalBackground: Color(red: 0.90, green: 0.92, blue: 0.93),
        accent: Color(red: 0.10, green: 0.44, blue: 0.86)
    )

    /// `colorScheme` is only consulted for `.system`.
    public func palette(for colorScheme: ColorScheme) -> Palette {
        switch self {
        case .xcode:  return Self.xcodePalette
        case .dark:   return Self.darkPalette
        case .light:  return Self.lightPalette
        case .system: return colorScheme == .dark ? Self.darkPalette : Self.lightPalette
        }
    }

    /// The next theme in the Auto → Xcode → Dark → Light cycle, for a one-button toggle.
    public var next: GenieEditorTheme {
        switch self {
        case .system: return .xcode
        case .xcode:  return .dark
        case .dark:   return .light
        case .light:  return .system
        }
    }
}

/// Three-state sidebar: fully hidden, a compact icon rail, or the full pane.
///
/// The middle state is the point — hiding the file list entirely to reclaim
/// width used to mean losing the ability to switch files at all.
public enum GenieSidebarMode: String, CaseIterable, Identifiable, Sendable {
    case hidden
    case compact
    case expanded

    public var id: String { rawValue }

    public static let compactWidth: CGFloat = 52
    public static let fileWidthRange: ClosedRange<Double> = 170...420
    public static let chatWidthRange: ClosedRange<Double> = 240...520

    public var symbolName: String {
        switch self {
        case .hidden:   return "sidebar.left"
        case .compact:  return "sidebar.squares.left"
        case .expanded: return "sidebar.leading"
        }
    }

    public var label: String {
        switch self {
        case .hidden:   return "Files hidden"
        case .compact:  return "Files compact"
        case .expanded: return "Files expanded"
        }
    }

    /// Expanded → compact → hidden → expanded.
    public var next: GenieSidebarMode {
        switch self {
        case .expanded: return .compact
        case .compact:  return .hidden
        case .hidden:   return .expanded
        }
    }
}
