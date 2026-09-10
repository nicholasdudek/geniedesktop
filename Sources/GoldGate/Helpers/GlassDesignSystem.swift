import SwiftUI

// MARK: - 💎 Unified Liquid Glass Design System
public struct GlassPillModifier: ViewModifier {
    public var fillOpacity: CGFloat
    public var strokeOpacity: CGFloat
    public var horizontalPadding: CGFloat
    public var verticalPadding: CGFloat

    public init(
        fillOpacity: CGFloat = 0.08,
        strokeOpacity: CGFloat = 0.15,
        horizontalPadding: CGFloat = 10,
        verticalPadding: CGFloat = 6
    ) {
        self.fillOpacity = fillOpacity
        self.strokeOpacity = strokeOpacity
        self.horizontalPadding = horizontalPadding
        self.verticalPadding = verticalPadding
    }

    public func body(content: Content) -> some View {
        content
            .padding(.horizontal, horizontalPadding)
            .padding(.vertical, verticalPadding)
            .background(Capsule().fill(Color.white.opacity(fillOpacity)))
            .overlay(
                Capsule().strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(strokeOpacity * 1.5),
                            Color.white.opacity(strokeOpacity * 0.5)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.75
                )
            )
    }
}

public struct GlassCardModifier: ViewModifier {
    public var cornerRadius: CGFloat
    public var fillOpacity: CGFloat
    public var strokeOpacity: CGFloat

    public init(
        cornerRadius: CGFloat = 16,
        fillOpacity: CGFloat = 0.06,
        strokeOpacity: CGFloat = 0.12
    ) {
        self.cornerRadius = cornerRadius
        self.fillOpacity = fillOpacity
        self.strokeOpacity = strokeOpacity
    }

    public func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.white.opacity(fillOpacity))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(strokeOpacity * 1.5),
                                Color.white.opacity(strokeOpacity * 0.4)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 0.8
                    )
            )
    }
}

// MARK: - View Extension Shortcuts
public extension View {
    func glassPill(
        fillOpacity: CGFloat = 0.08,
        strokeOpacity: CGFloat = 0.15,
        horizontalPadding: CGFloat = 10,
        verticalPadding: CGFloat = 6
    ) -> some View {
        modifier(GlassPillModifier(
            fillOpacity: fillOpacity,
            strokeOpacity: strokeOpacity,
            horizontalPadding: horizontalPadding,
            verticalPadding: verticalPadding
        ))
    }

    func glassCard(
        cornerRadius: CGFloat = 16,
        fillOpacity: CGFloat = 0.06,
        strokeOpacity: CGFloat = 0.12
    ) -> some View {
        modifier(GlassCardModifier(
            cornerRadius: cornerRadius,
            fillOpacity: fillOpacity,
            strokeOpacity: strokeOpacity
        ))
    }
}
