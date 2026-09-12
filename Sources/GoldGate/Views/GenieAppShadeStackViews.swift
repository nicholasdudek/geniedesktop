import AppKit
import SwiftUI

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
