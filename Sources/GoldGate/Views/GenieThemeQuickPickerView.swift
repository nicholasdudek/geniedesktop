import AppKit
import Foundation
import SwiftUI

// MARK: - 🎨 Genie Apple 2028 & Living Themes Quick Picker Popover
public struct GenieThemeQuickPickerView: View {
    @Binding var selectedTheme: GenieTheme
    public var onSelect: ((GenieTheme) -> Void)? = nil

    public init(selectedTheme: Binding<GenieTheme>, onSelect: ((GenieTheme) -> Void)? = nil) {
        self._selectedTheme = selectedTheme
        self.onSelect = onSelect
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: "paintpalette.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.cyan)

                Text("Apple 2028 & Living Themes")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Spacer()

                Text("120 FPS Metal")
                    .font(.system(size: 9.5, weight: .heavy, design: .monospaced))
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.cyan.opacity(0.18)))
            }

            Text("Select an Apple 2028 or living atmosphere theme. Visual effects load actively by default.")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.65))

            Divider().background(Color.white.opacity(0.10))

            // 1. Apple 2028 Flagship Suite
            Text("APPLE 2028 FLAGSHIP THEMES")
                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                .foregroundColor(.cyan.opacity(0.85))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach([
                    GenieTheme.apple2028LiquidWater,
                    GenieTheme.apple2028OledPillow,
                    GenieTheme.apple2028QuantumGlass,
                    GenieTheme.apple2028FrostedLight
                ]) { theme in
                    themeCard(theme)
                }
            }

            Divider().background(Color.white.opacity(0.10))

            // 2. Living Atmospheres
            Text("LIVING ATMOSPHERES")
                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                .foregroundColor(.purple.opacity(0.85))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach([
                    GenieTheme.mysticalAurora,
                    GenieTheme.contemplativeOcean,
                    GenieTheme.energeticAmber,
                    GenieTheme.playfulEmerald
                ]) { theme in
                    themeCard(theme)
                }
            }
        }
        .padding(16)
        .frame(width: 380)
        .background(
            ZStack {
                VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow, state: .active)
                Color(red: 0.06, green: 0.07, blue: 0.10).opacity(0.92)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.85)
        )
        .shadow(color: Color.black.opacity(0.6), radius: 24, y: 10)
    }

    private func themeCard(_ theme: GenieTheme) -> some View {
        let isSelected = selectedTheme == theme
        return Button(action: {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.8)) {
                selectedTheme = theme
                onSelect?(theme)
            }
            HapticFeedback.selection()
        }) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(theme.accentColor.opacity(isSelected ? 0.90 : 0.25))
                        .frame(width: 24, height: 24)

                    Image(systemName: theme.icon)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(isSelected ? .white : theme.accentColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(theme.shortTitle)
                        .font(.system(size: 11, weight: isSelected ? .bold : .medium, design: .rounded))
                        .foregroundColor(isSelected ? .white : .white.opacity(0.85))
                        .lineLimit(1)

                    Text(theme.description)
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.50))
                        .lineLimit(2)
                }

                Spacer(minLength: 0)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(theme.accentColor)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? theme.accentColor.opacity(0.20) : Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(isSelected ? theme.accentColor.opacity(0.70) : Color.white.opacity(0.08), lineWidth: 0.75)
            )
        }
        .buttonStyle(.plain)
    }
}
