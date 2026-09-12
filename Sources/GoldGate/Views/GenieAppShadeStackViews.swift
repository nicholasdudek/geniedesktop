import AppKit
import SwiftUI

// MARK: - 🪟 App Shade Stack Rail
//
// A floating rail of the running applications, drawn as the stack of glass they are.
// The active shade sits forward at full clarity; the shades in front of it are drawn
// at the same alpha the compositor is giving their real windows, so the HUD is an
// honest readout of the screen rather than a decoration.

public struct GenieAppShadeStackRail: View {
    @ObservedObject private var engine = GenieAppShadeStackEngine.shared
    @State private var hoveredID: pid_t?

    public init() {}

    public var body: some View {
        VStack(spacing: 14) {
            shadeRail
            clarityMeter
        }
        .padding(.horizontal, 22)
        .padding(.vertical, 18)
        .background(glassBackdrop)
        .overlay(specularRim)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .shadow(color: .black.opacity(0.38), radius: 30, y: 14)
        .animation(.smooth(duration: 0.32), value: engine.activeIndex)
        .animation(.smooth(duration: 0.22), value: engine.clarity)
    }

    // MARK: Rail

    private var shadeRail: some View {
        HStack(spacing: 12) {
            ForEach(Array(engine.shades.enumerated()), id: \.element.id) { index, shade in
                shadeChip(shade: shade, index: index)
            }
        }
    }

    private func shadeChip(shade: GenieAppShade, index: Int) -> some View {
        let isActive = index == engine.activeIndex
        let alpha = engine.alphaForShade(at: index)
        let isHovered = hoveredID == shade.id

        return VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: isActive
                                        ? [.white.opacity(0.85), .white.opacity(0.15)]
                                        : [.white.opacity(0.22), .clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: isActive ? 1.6 : 1.0
                            )
                    )

                if let icon = shade.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .interpolation(.high)
                        .frame(width: 34, height: 34)
                        // Mirrors the alpha the compositor is applying to the real windows.
                        .opacity(isActive ? 1.0 : alpha)
                } else {
                    Image(systemName: "app.dashed")
                        .font(.system(size: 22, weight: .light))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 54, height: 54)
            .scaleEffect(isActive ? 1.0 : (isHovered ? 0.96 : 0.88))
            .shadow(color: isActive ? .accentColor.opacity(0.55) : .clear, radius: 12)

            Text(shade.name)
                .font(.system(size: 9, weight: isActive ? .semibold : .regular))
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: 62)
                .foregroundStyle(isActive ? .primary : .secondary)
                .opacity(isActive ? 1.0 : 0.7)
        }
        .contentShape(Rectangle())
        .onHover { hoveredID = $0 ? shade.id : nil }
        .onTapGesture {
            engine.activateShade(at: index)
            engine.bringActiveShadeForward()
        }
        .accessibilityLabel(Text("\(shade.name) shade"))
        .accessibilityAddTraits(isActive ? [.isSelected, .isButton] : .isButton)
    }

    // MARK: Clarity

    private var clarityMeter: some View {
        HStack(spacing: 10) {
            Image(systemName: "square.3.layers.3d.top.filled")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.secondary)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.primary.opacity(0.10))
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [.accentColor.opacity(0.65), .accentColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(4, geo.size.width * engine.clarity))
                }
            }
            .frame(height: 5)

            Text("\(Int(engine.clarity * 100))%")
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .frame(width: 34, alignment: .trailing)
        }
        .frame(width: 240)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Shade clarity"))
        .accessibilityValue(Text("\(Int(engine.clarity * 100)) percent"))
    }

    // MARK: Chrome

    private var glassBackdrop: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(.ultraThinMaterial)
    }

    private var specularRim: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .strokeBorder(
                LinearGradient(
                    colors: [.white.opacity(0.55), .white.opacity(0.06), .white.opacity(0.22)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
    }
}

// MARK: - 🗂 App Shade Stack Page (Duo Fold page 2)
//
// The stack lives inside the Duo Fold rather than as a floating desktop widget, so
// there is nothing scattered on the desktop: the controls sit on the second page and
// the effect happens on the real windows behind the app.

public struct GenieAppShadeStackPage: View {
    @ObservedObject private var engine = GenieAppShadeStackEngine.shared

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header

            Divider().opacity(0.18)

            if engine.shades.isEmpty {
                emptyState
            } else {
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(Array(engine.shades.enumerated()), id: \.element.id) { index, shade in
                            shadeRow(shade: shade, index: index)
                        }
                    }
                    .padding(16)
                }
            }

            Divider().opacity(0.18)

            controls
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.22))
        .onAppear { engine.refreshShades(force: true) }
        .animation(.smooth(duration: 0.28), value: engine.activeIndex)
        .animation(.smooth(duration: 0.20), value: engine.clarity)
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "square.3.layers.3d.top.filled")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(engine.isActive ? Color.accentColor : .secondary)

            VStack(alignment: .leading, spacing: 1) {
                Text("App Shades")
                    .font(.system(size: 12, weight: .semibold))
                Text(engine.isActive ? "\(engine.shades.count) layers stacked" : "Stack off")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                engine.toggle()
            } label: {
                Text(engine.isActive ? "Clear" : "Stack")
                    .font(.system(size: 10, weight: .semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(
                        Capsule().fill(engine.isActive ? Color.accentColor : Color.white.opacity(0.14))
                    )
                    .foregroundStyle(engine.isActive ? Color.black : Color.white)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: Rows

    private func shadeRow(shade: GenieAppShade, index: Int) -> some View {
        let isActive = index == engine.activeIndex
        let alpha = engine.alphaForShade(at: index)

        return HStack(spacing: 12) {
            if let icon = shade.icon {
                Image(nsImage: icon)
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 30, height: 30)
                    .opacity(isActive ? 1.0 : alpha)
            } else {
                Image(systemName: "app.dashed")
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(.secondary)
                    .frame(width: 30, height: 30)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(shade.name)
                    .font(.system(size: 11, weight: isActive ? .semibold : .regular))
                    .lineLimit(1)
                Text(isActive ? "Clear" : "\(Int(alpha * 100))% opaque")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if isActive {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(Color.accentColor)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .opacity(isActive ? 1.0 : 0.55)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: isActive
                            ? [.white.opacity(0.75), .white.opacity(0.10)]
                            : [.white.opacity(0.16), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: isActive ? 1.4 : 1.0
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            engine.activateShade(at: index)
            engine.bringActiveShadeForward()
        }
        .accessibilityLabel(Text("\(shade.name) shade"))
        .accessibilityAddTraits(isActive ? [.isSelected, .isButton] : .isButton)
    }

    // MARK: Empty

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "square.3.layers.3d")
                .font(.system(size: 26, weight: .light))
                .foregroundStyle(.secondary)
            Text("No application windows to stack")
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: Controls

    private var controls: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Text("Clarity")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.secondary)

                Slider(value: $engine.clarity, in: 0...1)
                    .controlSize(.mini)

                Text("\(Int(engine.clarity * 100))%")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .frame(width: 32, alignment: .trailing)
            }

            Text("Swipe across to walk the stack · swipe up and down to dial clarity")
                .font(.system(size: 9))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
