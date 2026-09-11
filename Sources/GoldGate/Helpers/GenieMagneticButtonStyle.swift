import SwiftUI

/// A subtle Dock-like hover effect for ordinary SwiftUI buttons: the button
/// magnifies a little on hover and settles with a light spring bounce, then
/// compresses slightly on press. Apply with `.buttonStyle(GenieMagneticButtonStyle())`.
public struct GenieMagneticButtonStyle: ButtonStyle {
    public var scale: CGFloat

    public init(scale: CGFloat = 1.12) {
        self.scale = scale
    }

    public func makeBody(configuration: Configuration) -> some View {
        GenieMagneticButtonBody(scale: scale, isPressed: configuration.isPressed) {
            configuration.label
        }
    }
}

private struct GenieMagneticButtonBody<Label: View>: View {
    let scale: CGFloat
    let isPressed: Bool
    @ViewBuilder let label: () -> Label
    @State private var isHovering = false

    var body: some View {
        label()
            .scaleEffect(currentScale)
            .animation(.spring(response: 0.30, dampingFraction: 0.55), value: isHovering)
            .animation(.spring(response: 0.18, dampingFraction: 0.6), value: isPressed)
            .onHover { hovering in
                isHovering = hovering
            }
    }

    private var currentScale: CGFloat {
        if isPressed { return max(0.90, scale * 0.94) }
        return isHovering ? scale : 1.0
    }
}
