import AppKit
import SwiftUI

// MARK: - Visual Effect Blur (Native AppKit Bridge)
//
// Every blurred surface in Genie flows through these two representables. They now render
// Apple Liquid Glass (`NSGlassEffectView`) on macOS 26+ when the user has it enabled, and the
// classic `NSVisualEffectView` material otherwise. See `LiquidGlassStyle.swift`.

struct VisualEffectBlur: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .popover
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    var state: NSVisualEffectView.State = .active
    var cornerRadius: CGFloat = 0

    func makeNSView(context: Context) -> NSView {
        LiquidGlassAppKitFactory.makeView(material: material, blendingMode: blendingMode, state: state, cornerRadius: cornerRadius)
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        LiquidGlassAppKitFactory.update(nsView, material: material, blendingMode: blendingMode, state: state, cornerRadius: cornerRadius)
    }
}

// MARK: - Liquid Glass Blur

public struct LiquidGlassBlur: NSViewRepresentable {
    var cornerRadius: CGFloat = 0
    var material: NSVisualEffectView.Material = .popover
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow

    public init(
        cornerRadius: CGFloat = 0,
        material: NSVisualEffectView.Material = .popover,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    ) {
        self.cornerRadius = cornerRadius
        self.material = material
        self.blendingMode = blendingMode
    }

    public func makeNSView(context: Context) -> NSView {
        LiquidGlassAppKitFactory.makeView(material: material, blendingMode: blendingMode, state: .active, cornerRadius: cornerRadius)
    }

    public func updateNSView(_ nsView: NSView, context: Context) {
        LiquidGlassAppKitFactory.update(nsView, material: material, blendingMode: blendingMode, state: .active, cornerRadius: cornerRadius)
    }
}
