import SwiftUI

// MARK: - User-Selectable Dock Animation Styles
//
// One shared engine drives icon motion for every dock surface in Genie (mini dock, menu bar
// app strip, and the spatial app matrix). Users pick a style and an intensity in Settings;
// "Dance to Music" reacts to live audio playback detected by `MusicPlaybackMonitor`.

public enum DockAnimationStyle: String, CaseIterable, Identifiable {
    case none = "None"
    case classicMagnify = "Classic Magnify 🔍"
    case bounce = "Bounce on Hover 🏀"
    case jelly = "Jelly Wobble 🍮"
    case ripple = "Wave Ripple 🌊"
    case genieLamp = "Genie Lamp Rise 🪔"
    case danceToMusic = "Dance to Music 🎵"

    public static let preferenceKey = PrefKey.dockAnimationStyle
    public static let intensityKey = PrefKey.dockAnimationIntensity
    public static let danceKey = PrefKey.danceToMusicEnabled
    public static let defaultStyle: DockAnimationStyle = .none

    public var id: String { rawValue }

    /// Styles that move continuously (not only on hover) need a running timeline.
    public var isContinuous: Bool {
        switch self {
        case .ripple, .danceToMusic: return true
        default: return false
        }
    }

    /// Styles that animate over time while an icon is hovered.
    public var animatesWhileHovered: Bool {
        switch self {
        case .bounce, .jelly, .genieLamp: return true
        default: return false
        }
    }

    public var symbolName: String {
        switch self {
        case .none: return "circle.dashed"
        case .classicMagnify: return "magnifyingglass"
        case .bounce: return "basketball.fill"
        case .jelly: return "drop.fill"
        case .ripple: return "water.waves"
        case .genieLamp: return "flame.fill"
        case .danceToMusic: return "music.note"
        }
    }

    public var subtitle: String {
        switch self {
        case .none: return "Static icons, zero motion"
        case .classicMagnify: return "Apple Dock style neighbour magnification"
        case .bounce: return "Icons spring up and down under the cursor"
        case .jelly: return "Soft wobble with a squishy rebound"
        case .ripple: return "Gentle wave rolling across the dock"
        case .genieLamp: return "Icons rise out of the lamp with a tilt"
        case .danceToMusic: return "Icons groove whenever audio is playing"
        }
    }

    public init(preferenceValue: String?) {
        self = DockAnimationStyle(rawValue: preferenceValue ?? "") ?? .defaultStyle
    }
}

/// Resolved per-icon transform for a single frame.
public struct DockIconTransform: Equatable {
    public var scale: CGFloat = 1.0
    public var offset: CGSize = .zero
    /// Degrees.
    public var rotation: Double = 0.0

    public static let identity = DockIconTransform()

    public init(scale: CGFloat = 1.0, offset: CGSize = .zero, rotation: Double = 0.0) {
        self.scale = scale
        self.offset = offset
        self.rotation = rotation
    }
}

public enum DockAnimationEngine {
    /// Tempo used for music dancing. Playback tempo is not exposed by macOS, so a
    /// club-friendly 124 BPM keeps the groove believable across most genres.
    public static let danceBPM: Double = 124.0

    /// Computes the transform for one dock icon.
    /// - Parameters:
    ///   - index: Position of the icon in the dock.
    ///   - hoveredIndex: Index of the hovered icon, if any.
    ///   - time: Monotonic time (seconds) from a `TimelineView`.
    ///   - intensity: 0...1 user intensity slider.
    ///   - isMusicPlaying: Live audio playback flag from `MusicPlaybackMonitor`.
    ///   - danceToMusic: User toggle that lets any style dance while music plays.
    ///   - anchorDown: Dock hangs from the menu bar (offsets flip downward).
    public static func transform(
        style: DockAnimationStyle,
        index: Int,
        hoveredIndex: Int?,
        time: TimeInterval,
        intensity: Double,
        isMusicPlaying: Bool,
        danceToMusic: Bool,
        anchorDown: Bool = false
    ) -> DockIconTransform {
        let k = CGFloat(0.35 + max(0.0, min(1.0, intensity)) * 0.95)
        let dir: CGFloat = anchorDown ? 1.0 : -1.0
        let i = Double(index)
        let distance = hoveredIndex.map { abs($0 - index) } ?? Int.max
        let hovered = distance == 0

        var t = DockIconTransform.identity

        switch style {
        case .none:
            break

        case .classicMagnify, .danceToMusic:
            t = magnify(distance: distance, k: k, dir: dir)

        case .bounce:
            t = magnify(distance: distance, k: k, dir: dir)
            if hovered {
                let hop = abs(sin(time * 7.5))
                t.offset.height += dir * CGFloat(hop) * 9.0 * k
                t.scale += CGFloat(hop) * 0.05 * k
            }

        case .jelly:
            t = magnify(distance: distance, k: k, dir: dir)
            if hovered {
                let wobble = sin(time * 11.0)
                t.rotation = wobble * 6.0 * Double(k)
                t.scale += CGFloat(sin(time * 13.0)) * 0.05 * k
            } else if distance == 1 {
                t.rotation = sin(time * 11.0 + .pi) * 2.0 * Double(k)
            }

        case .ripple:
            let wave = sin(time * 2.4 + i * 0.55)
            t.offset.height = dir * CGFloat(wave) * 3.5 * k
            t.scale = 1.0 + CGFloat(max(0.0, wave)) * 0.05 * k
            if hovered { t.scale += 0.22 * k }

        case .genieLamp:
            if hovered {
                let rise = 0.5 + 0.5 * sin(time * 5.0)
                t.offset.height = dir * (10.0 + CGFloat(rise) * 5.0) * k
                t.scale = 1.0 + 0.32 * k
                t.rotation = sin(time * 5.0) * 4.0 * Double(k)
            } else if distance == 1 {
                t.offset.height = dir * 3.0 * k
                t.scale = 1.0 + 0.08 * k
            }
        }

        // Music layer: the dedicated style always dances; other styles dance when the toggle is on.
        let wantsDance = style == .danceToMusic || (danceToMusic && style != .none)
        if wantsDance && isMusicPlaying {
            let d = dance(index: index, time: time, k: k, dir: dir)
            t.offset.width += d.offset.width
            t.offset.height += d.offset.height
            t.rotation += d.rotation
            t.scale *= d.scale
        }

        t.scale = max(0.6, min(2.0, t.scale))
        return t
    }

    /// Apple Dock style magnification falloff around the hovered icon. Public so any row of
    /// buttons elsewhere in the app (settings sidebar, theme swatch pills, etc.) can pick up the
    /// same "grows near the cursor" feel as the real dock, not just `RealMacOSMiniDockView`.
    public static func magnify(distance: Int, k: CGFloat, dir: CGFloat = 0) -> DockIconTransform {
        switch distance {
        case 0: return DockIconTransform(scale: 1.0 + 0.36 * k, offset: CGSize(width: 0, height: dir * 6.0 * k))
        case 1: return DockIconTransform(scale: 1.0 + 0.16 * k, offset: CGSize(width: 0, height: dir * 2.5 * k))
        case 2: return DockIconTransform(scale: 1.0 + 0.06 * k, offset: .zero)
        default: return .identity
        }
    }

    /// Beat-synchronised bob, sway, tilt and pulse with per-icon phase offsets so the
    /// dock looks like a crowd rather than a metronome.
    public static func dance(index: Int, time: TimeInterval, k: CGFloat, dir: CGFloat = -1.0) -> DockIconTransform {
        let beat = time / (60.0 / danceBPM) * 2.0 * .pi
        let i = Double(index)
        let bob = abs(sin(beat * 0.5 + i * 0.9))
        let sway = sin(beat * 0.5 + i * 0.7)
        let tilt = sin(beat + i * 1.3)
        let pulse = 0.5 + 0.5 * sin(beat + i)
        return DockIconTransform(
            scale: 1.0 + CGFloat(pulse) * 0.14 * k,
            offset: CGSize(width: CGFloat(sway) * 5.0 * k, height: dir * CGFloat(bob) * 9.0 * k),
            rotation: tilt * 8.0 * Double(k)
        )
    }
}

// MARK: - 🎨 Dock Formations (Next-Gen macOS Desktop Formations)
public enum DockFormation: String, CaseIterable, Identifiable, Sendable {
    case floatingIsland = "Floating Island (Liquid Glass)"
    case bottomShelf = "Cupertino Grounded Shelf"
    case notchWing = "Dynamic Notch Wing"
    case verticalRail = "Pro Vertical Rail"
    case compactHub = "Spatial Trigger Hub"

    public var id: String { rawValue }

    public static let preferenceKey = PrefKey.dockFormation
    public static let defaultFormation: DockFormation = .floatingIsland

    public var icon: String {
        switch self {
        case .floatingIsland: return "capsule.portrait.fill"
        case .bottomShelf: return "rectangle.bottomhalf.filled"
        case .notchWing: return "chevron.compact.down"
        case .verticalRail: return "sidebar.right"
        case .compactHub: return "circle.hexagongrid.fill"
        }
    }

    public var subtitle: String {
        switch self {
        case .floatingIsland: return "Modern translucent floating pill with liquid glass bevels"
        case .bottomShelf: return "Grounded to screen bottom with authentic macOS shelf reflection"
        case .notchWing: return "Snaps flush beneath the MacBook display notch with winglet wings"
        case .verticalRail: return "Vertical side strip for ultra-wide displays and multi-window pros"
        case .compactHub: return "Ultra-compact 44pt spatial badge that unfolds dynamically on hover"
        }
    }

    public var isVertical: Bool {
        self == .verticalRail
    }

    public init(preferenceValue: String?) {
        self = DockFormation(rawValue: preferenceValue ?? "") ?? .defaultFormation
    }
}

