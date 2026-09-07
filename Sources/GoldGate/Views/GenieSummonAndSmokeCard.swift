import SwiftUI

struct GenieSummonAndSmokeCard: View {
    @AppStorage(PrefKey.appLanguage) var appLanguage: String = "English (US)"
@Binding var genieAnimEnabled: Bool
    @Binding var genieAnimOrigin: String
    @Binding var smokeEffectsEnabled: Bool
    @Binding var smokeStyle: String
    var popoverBounds: CGSize

    private let smokeStyles: [String] = [
        "Mystical Cyan 🧞‍♂️", "Golden Vapor 🪔",
        "Cosmic Purple 🔮", "Pure Ethereal 💨", "Rainbow Magic 🌈"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            headerRow

            VStack(spacing: 10) {
                genieToggleRow

                if genieAnimEnabled {
                    Divider().opacity(0.3)
                    originSelectorRow
                    Divider().opacity(0.3)
                    smokeToggleRow

                    if smokeEffectsEnabled {
                        smokeStylesRow
                        testButtonsRow
                    }
                }
            }
            .padding(11)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.50))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.cyan.opacity(0.25), lineWidth: 1)
            )
        }
    }

    private var headerRow: some View {
        HStack {
            Image(systemName: "wand.and.stars")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.cyan)
            Text(LocalizedStrings.translateText("GENIE SUMMON ANIMATION & SMOKE EFFECTS 🧞‍♂️💨", lang: appLanguage))
                .font(.system(size: 10.5, weight: .bold))
                .foregroundColor(.secondary)
            Spacer()
        }
    }

    private var genieToggleRow: some View {
        HStack {
            Image(systemName: "sparkles")
                .font(.system(size: 13))
                .foregroundColor(.cyan)
            VStack(alignment: .leading, spacing: 1.5) {
                Text(LocalizedStrings.translateText("Genie Summon Animation", lang: appLanguage))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)
                Text(LocalizedStrings.translateText("Swooshes fluidly into view from your chosen origin point.", lang: appLanguage))
                    .font(.system(size: 9.5))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Toggle("", isOn: $genieAnimEnabled)
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
        }
    }

    private var originSelectorRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(LocalizedStrings.translateText("Summon Origin", lang: appLanguage))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
                Text(genieAnimOrigin)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.cyan)
            }

            HStack(spacing: 8) {
                Button(action: {
                    HapticFeedback.selection()
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                        genieAnimOrigin = "Top Glyph 🪔"
                    }
                }) {
                    HStack(spacing: 5) {
                        Text(LocalizedStrings.translateText("🪔", lang: appLanguage)).font(.system(size: 12))
                        Text(LocalizedStrings.translateText("Top Glyph", lang: appLanguage))
                            .font(.system(size: 11, weight: genieAnimOrigin.contains("Glyph") ? .bold : .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(genieAnimOrigin.contains("Glyph") ? Color.cyan.opacity(0.18) : Color.primary.opacity(0.04))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .stroke(genieAnimOrigin.contains("Glyph") ? Color.cyan.opacity(0.7) : Color.clear, lineWidth: 1.2)
                    )
                }
                .buttonStyle(.plain)
                .help("Window emerges and swooshes out from the Genie menu bar status lamp")

                Button(action: {
                    HapticFeedback.selection()
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                        genieAnimOrigin = "Dock 📥"
                    }
                }) {
                    HStack(spacing: 5) {
                        Text(LocalizedStrings.translateText("📥", lang: appLanguage)).font(.system(size: 12))
                        Text(LocalizedStrings.translateText("Bottom Dock", lang: appLanguage))
                            .font(.system(size: 11, weight: genieAnimOrigin.contains("Dock") ? .bold : .medium))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(genieAnimOrigin.contains("Dock") ? Color.cyan.opacity(0.18) : Color.primary.opacity(0.04))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .stroke(genieAnimOrigin.contains("Dock") ? Color.cyan.opacity(0.7) : Color.clear, lineWidth: 1.2)
                    )
                }
                .buttonStyle(.plain)
                .help("Window rises and sweeps upwards directly from the macOS Dock")
            }
        }
    }

    private var smokeToggleRow: some View {
        HStack {
            Image(systemName: "smoke.fill")
                .font(.system(size: 13))
                .foregroundColor(.teal)
            VStack(alignment: .leading, spacing: 1.5) {
                Text(LocalizedStrings.translateText("Mystical Smoke Effects", lang: appLanguage))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)
                Text(LocalizedStrings.translateText("Billowing clouds and stardust embers puff from the origin.", lang: appLanguage))
                    .font(.system(size: 9.5))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Toggle("", isOn: $smokeEffectsEnabled)
                .labelsHidden()
                .toggleStyle(.switch)
                .controlSize(.small)
        }
    }

    private var smokeStylesRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(LocalizedStrings.translateText("Smoke Aura Style", lang: appLanguage))
                .font(.system(size: 10.5, weight: .medium))
                .foregroundColor(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(smokeStyles, id: \.self) { sStyle in
                        let isSel = smokeStyle == sStyle
                        Button(action: {
                            HapticFeedback.selection()
                            smokeStyle = sStyle
                            GenieSmokeEngine.shared.triggerBurst(
                                origin: genieAnimOrigin.contains("Dock") ? .dock : .topGlyph(xPercent: 0.5),
                                bounds: popoverBounds,
                                style: sStyle,
                                count: 24
                            )
                        }) {
                            Text(sStyle)
                                .font(.system(size: 10.5, weight: isSel ? .bold : .medium))
                                .foregroundColor(isSel ? .cyan : .primary)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 4.5)
                                .background(
                                    Capsule()
                                        .fill(isSel ? Color.cyan.opacity(0.18) : Color.primary.opacity(0.04))
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(isSel ? Color.cyan : Color.clear, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var testButtonsRow: some View {
        HStack(spacing: 8) {
            Button(action: {
                HapticFeedback.heavy()
                NotificationCenter.default.post(
                    name: NSNotification.Name("NexusGenieSummon"),
                    object: [
                        "origin": genieAnimOrigin.contains("Dock") ? "dock" : "glyph",
                        "glyphXPercent": 0.85,
                        "genieEnabled": true
                    ] as [String: Any]
                )
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10))
                    Text(LocalizedStrings.translateText("Test Genie Summon ⚡️", lang: appLanguage))
                        .font(.system(size: 10.5, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.cyan.opacity(0.16)))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.cyan.opacity(0.5), lineWidth: 1))
                .foregroundColor(.cyan)
            }
            .buttonStyle(.plain)

            Button(action: {
                HapticFeedback.selection()
                GenieSmokeEngine.shared.triggerBurst(
                    origin: genieAnimOrigin.contains("Dock") ? .dock : .topGlyph(xPercent: 0.5),
                    bounds: popoverBounds,
                    style: smokeStyle,
                    count: 38
                )
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "smoke.fill")
                        .font(.system(size: 10))
                    Text(LocalizedStrings.translateText("Puff Smoke 💨", lang: appLanguage))
                        .font(.system(size: 10.5, weight: .bold))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.teal.opacity(0.16)))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.teal.opacity(0.5), lineWidth: 1))
                .foregroundColor(.teal)
            }
            .buttonStyle(.plain)
        }
    }
}
