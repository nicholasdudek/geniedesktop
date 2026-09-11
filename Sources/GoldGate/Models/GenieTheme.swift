import AppKit
import Foundation
import SwiftUI

// MARK: - 🎨 Unified Genie Theme System (Apple 2028 & Living Atmospheres)
public enum GenieTheme: String, CaseIterable, Identifiable, Sendable {
    case apple2028LiquidWater = "Apple 2028 Living Liquid Water"
    case apple2028OledPillow = "Apple 2028 OLED Blackout Pillow"
    case apple2028QuantumGlass = "Apple 2028 Quantum Titanium Glass"
    case apple2028FrostedLight = "Apple 2028 Frosted Alabaster Light"
    case mysticalAurora = "Mystical Aurora"
    case contemplativeOcean = "Contemplative Ocean"
    case energeticAmber = "Energetic Amber"
    case playfulEmerald = "Playful Emerald"

    public var id: String { rawValue }

    /// The theme a fresh install opens with — the purple living atmosphere.
    /// Every `@AppStorage` default and `??` fallback points here, so changing
    /// the house theme is one edit rather than a dozen scattered literals.
    public static let defaultTheme: GenieTheme = .mysticalAurora

    public var shortTitle: String {
        switch self {
        case .apple2028LiquidWater: return "Liquid Water 💧"
        case .apple2028OledPillow: return "OLED Pillow ⏱️"
        case .apple2028QuantumGlass: return "Quantum Glass ✨"
        case .apple2028FrostedLight: return "Frosted Light ☀️"
        case .mysticalAurora: return "Mystical 🌌"
        case .contemplativeOcean: return "Ocean 🌊"
        case .energeticAmber: return "Amber ⚡"
        case .playfulEmerald: return "Emerald 🌿"
        }
    }

    public var icon: String {
        switch self {
        case .apple2028LiquidWater: return "drop.fill"
        case .apple2028OledPillow: return "clock.fill"
        case .apple2028QuantumGlass: return "sparkles"
        case .apple2028FrostedLight: return "sun.max.fill"
        case .mysticalAurora: return "wand.and.stars"
        case .contemplativeOcean: return "water.waves"
        case .energeticAmber: return "bolt.fill"
        case .playfulEmerald: return "leaf.fill"
        }
    }

    public var accentColor: Color {
        switch self {
        case .apple2028LiquidWater: return Color(red: 0.10, green: 0.85, blue: 0.95)
        case .apple2028OledPillow: return Color(white: 0.92)
        case .apple2028QuantumGlass: return Color(red: 0.70, green: 0.45, blue: 1.0)
        case .apple2028FrostedLight: return Color(red: 0.98, green: 0.55, blue: 0.15)
        case .mysticalAurora: return Color(red: 0.65, green: 0.40, blue: 1.0)
        case .contemplativeOcean: return Color(red: 0.20, green: 0.65, blue: 0.98)
        case .energeticAmber: return Color(red: 1.0, green: 0.72, blue: 0.20)
        case .playfulEmerald: return Color(red: 0.20, green: 0.85, blue: 0.55)
        }
    }

    public var secondaryAccentColor: Color {
        switch self {
        case .apple2028LiquidWater: return Color(red: 0.25, green: 0.50, blue: 1.0)
        case .apple2028OledPillow: return Color(white: 0.55)
        case .apple2028QuantumGlass: return Color(red: 0.15, green: 0.85, blue: 0.95)
        case .apple2028FrostedLight: return Color(red: 0.15, green: 0.65, blue: 0.95)
        case .mysticalAurora: return Color(red: 0.35, green: 0.75, blue: 0.95)
        case .contemplativeOcean: return Color(red: 0.45, green: 0.35, blue: 0.85)
        case .energeticAmber: return Color(red: 0.95, green: 0.35, blue: 0.20)
        case .playfulEmerald: return Color(red: 0.10, green: 0.75, blue: 0.95)
        }
    }

    public var backgroundTint: Color {
        switch self {
        case .apple2028LiquidWater: return Color(red: 0.02, green: 0.08, blue: 0.14)
        case .apple2028OledPillow: return Color.black
        case .apple2028QuantumGlass: return Color(red: 0.04, green: 0.03, blue: 0.09)
        case .apple2028FrostedLight: return Color(white: 0.96)
        case .mysticalAurora: return Color(red: 0.05, green: 0.03, blue: 0.10)
        case .contemplativeOcean: return Color(red: 0.02, green: 0.06, blue: 0.12)
        case .energeticAmber: return Color(red: 0.08, green: 0.04, blue: 0.02)
        case .playfulEmerald: return Color(red: 0.02, green: 0.07, blue: 0.05)
        }
    }

    public var isLightAppearance: Bool {
        self == .apple2028FrostedLight
    }

    public var description: String {
        switch self {
        case .apple2028LiquidWater:
            return "Living fluid caustics, wave ripples, and liquid glass refraction at 120 FPS."
        case .apple2028OledPillow:
            return "Pure #000000 blackout card, specular rim lighting, and haute horology dials."
        case .apple2028QuantumGlass:
            return "Cosmic violet and cyan titanium iridescent gradient with quantum starlight."
        case .apple2028FrostedLight:
            return "Luminous vitreous alabaster glass with sunlit warmth and azure accents."
        case .mysticalAurora:
            return "Nebula violet glow with breathing ambient smoke dynamics."
        case .contemplativeOcean:
            return "Deep oceanic blue tones with calming ambient swells."
        case .energeticAmber:
            return "High-contrast golden amber highlights with active pulse dynamics."
        case .playfulEmerald:
            return "Vibrant botanical emerald gradients with breezy animations."
        }
    }
}
