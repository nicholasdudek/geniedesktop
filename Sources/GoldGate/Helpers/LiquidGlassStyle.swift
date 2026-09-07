import SwiftUI
import AppKit

// MARK: - Genie Liquid Glass
//
// One modifier gives every surface Apple's Liquid Glass look. On macOS 26+ it uses the native
// `glassEffect` (refraction, specular highlights, adaptive tint). On macOS 14/15 it falls back
// to a hand-tuned ultra-thin material with a glass rim and top highlight, so the app reads the
// same on every supported system. Users can switch it off in Settings → Appearance.

public enum LiquidGlassSettings {
    public static let preferenceKey = PrefKey.liquidGlassEnabled

    public static var isEnabled: Bool {
        let defaults = UserDefaults.standard
        return defaults.object(forKey: preferenceKey) == nil ? true : defaults.bool(forKey: preferenceKey)
    }

    /// Native Liquid Glass (`glassEffect` / `NSGlassEffectView`) is available on this system.
    public static var isNativelySupported: Bool {
        if #available(macOS 26.0, *) { return true }
        return false
    }
}

public struct GenieLiquidGlassModifier: ViewModifier {
    public var cornerRadius: CGFloat
    public var tint: Color?
    public var interactive: Bool

    @AppStorage(LiquidGlassSettings.preferenceKey) private var liquidGlassEnabled: Bool = true

    public func body(content: Content) -> some View {
        if liquidGlassEnabled, #available(macOS 26.0, *) {
            nativeGlass(content)
        } else {
            fallbackGlass(content)
        }
    }

    @available(macOS 26.0, *)
    private func nativeGlass(_ content: Content) -> some View {
        var glass: Glass = .regular
        if let tint { glass = glass.tint(tint) }
        if interactive { glass = glass.interactive() }
        return content.glassEffect(glass, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    private func fallbackGlass(_ content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        return content
            .background(.ultraThinMaterial, in: shape)
            .background(
                shape.fill(
                    LinearGradient(
                        colors: [
                            (tint ?? .white).opacity(0.16),
                            Color.white.opacity(0.03),
                            Color.black.opacity(0.10)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            )
            .overlay(
                shape.stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.45), Color.white.opacity(0.08), Color.white.opacity(0.22)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.8
                )
            )
            .shadow(color: Color.black.opacity(0.18), radius: 14, y: 6)
    }
}

public extension View {
    /// Wraps the view in Genie's Liquid Glass surface.
    func genieLiquidGlass(cornerRadius: CGFloat = 16, tint: Color? = nil, interactive: Bool = false) -> some View {
        modifier(GenieLiquidGlassModifier(cornerRadius: cornerRadius, tint: tint, interactive: interactive))
    }
}

// MARK: - AppKit Liquid Glass host

/// Builds the AppKit backing view for `VisualEffectBlur` / `LiquidGlassBlur`: an
/// `NSGlassEffectView` when Liquid Glass is available and enabled, else `NSVisualEffectView`.
enum LiquidGlassAppKitFactory {
    static func makeView(material: NSVisualEffectView.Material,
                         blendingMode: NSVisualEffectView.BlendingMode,
                         state: NSVisualEffectView.State,
                         cornerRadius: CGFloat) -> NSView {
        if LiquidGlassSettings.isEnabled, #available(macOS 26.0, *) {
            let glass = NSGlassEffectView()
            glass.cornerRadius = cornerRadius
            glass.style = .regular
            glass.wantsLayer = true
            return glass
        }
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        view.wantsLayer = true
        applyCorner(cornerRadius, to: view)
        return view
    }

    static func update(_ view: NSView,
                       material: NSVisualEffectView.Material,
                       blendingMode: NSVisualEffectView.BlendingMode,
                       state: NSVisualEffectView.State,
                       cornerRadius: CGFloat) {
        if #available(macOS 26.0, *), let glass = view as? NSGlassEffectView {
            glass.cornerRadius = cornerRadius
            return
        }
        guard let effect = view as? NSVisualEffectView else { return }
        effect.material = material
        effect.blendingMode = blendingMode
        effect.state = state
        applyCorner(cornerRadius, to: effect)
    }

    private static func applyCorner(_ radius: CGFloat, to view: NSView) {
        view.wantsLayer = true
        if radius > 0 {
            view.layer?.cornerRadius = radius
            view.layer?.cornerCurve = .continuous
            view.layer?.masksToBounds = true
        } else {
            view.layer?.cornerRadius = 0
            view.layer?.masksToBounds = false
        }
    }
}
