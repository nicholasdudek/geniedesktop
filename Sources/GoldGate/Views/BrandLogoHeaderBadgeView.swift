import SwiftUI
import AppKit

struct BrandLogoHeaderBadgeView: View {
    @AppStorage(PrefKey.appLanguage) var appLanguage: String = "English (US)"
@ObservedObject private var brandManager = BrandLogoManager.shared
    @AppStorage(PrefKey.desktopPlaneEnabled) private var desktopPlaneEnabled: Bool = true
    @AppStorage(PrefKey.genieAnimEnabled) private var genieAnimEnabled: Bool = false
    @AppStorage(PrefKey.smokeEffectsEnabled) private var smokeEffectsEnabled: Bool = false
    @State private var showingPickerPopover: Bool = false
    @State private var isHovered: Bool = false
    @State private var isPressed: Bool = false

    var body: some View {
        Button(action: {
            if NSEvent.modifierFlags.contains(.option) {
                showingPickerPopover = true
            } else {
                HapticFeedback.selection()
                AppDelegate.shared?.showApplicationsSettings(tab: .applications)
            }
        }) {
            ZStack {
                if brandManager.brandIconStyle == "Custom Upload", let img = brandManager.customLogoImage {
                    Image(nsImage: img)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 25, height: 25)
                        .clipShape(RoundedRectangle(cornerRadius: 6.5, style: .continuous))
                } else {
                    builtInGlyphView(style: brandManager.brandIconStyle)
                        .frame(width: 25, height: 25)
                }
            }
            .padding(2)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isHovered ? Color.white.opacity(0.14) : Color.white.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(
                        isHovered
                            ? LinearGradient(colors: [Color(red: 1.0, green: 0.85, blue: 0.3), Color(red: 0.95, green: 0.6, blue: 0.2)], startPoint: .topLeading, endPoint: .bottomTrailing)
                            : LinearGradient(colors: [Color.primary.opacity(0.15), Color.primary.opacity(0.08)], startPoint: .top, endPoint: .bottom),
                        lineWidth: 1.0
                    )
            )
            .shadow(color: Color.black.opacity(isHovered ? 0.25 : 0.10), radius: 2.5, y: 1)
            .scaleEffect(isPressed ? 0.90 : (isHovered ? 1.05 : 1.0))
            .animation(.spring(response: 0.25, dampingFraction: 0.72), value: isHovered)
            .animation(.spring(response: 0.2, dampingFraction: 0.65), value: isPressed)
        }
        .buttonStyle(.plain)
        .onHover { h in isHovered = h }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .contextMenu {
            Button {
                AppDelegate.shared?.showApplicationsSettings(tab: .miniDock)
            } label: {
                Label("Genie Settings...", systemImage: "gearshape")
            }
            Button {
                AppDelegate.shared?.showApplicationsSettings(tab: .miniDock)
            } label: {
                Label("Mini Dock Settings...", systemImage: "menubar.rectangle")
            }
            Button {
                AppDelegate.shared?.showApplicationsSettings(tab: .desktop)
            } label: {
                Label("Desktop & Files Settings...", systemImage: "desktopcomputer")
            }
            Divider()
            Button {
                showingPickerPopover = true
            } label: {
                Label("Customize Brand Logo & Upload...", systemImage: "paintbrush")
            }
            Button {
                brandManager.resetToDefaultGenie()
            } label: {
                Label("Reset to Default Genie", systemImage: "arrow.counterclockwise")
            }
        }
        .popover(isPresented: $showingPickerPopover, arrowEdge: .bottom) {
            BrandLogoPickerPopoverView(isPresented: $showingPickerPopover)
        }
        .help("Genie Settings — Applications (Click to open)")
    }



    @ViewBuilder
    private func builtInGlyphView(style: String) -> some View {
        switch style {
        case "Genie Person", "Genie Person 🧞‍♂️", "Genie 🧞":
            Image(nsImage: StatusIconRenderer.generateGlyphImage(glyph: "Genie Person 🧞‍♂️", size: 22, phase: 0))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 22, height: 22)

        case "Genie Lamp", "Genie Lamp 🪔":
            Image(nsImage: StatusIconRenderer.generateGlyphImage(glyph: "Genie Lamp 🪔", size: 22, phase: 0))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 22, height: 22)

        case "Leo Maltese", "Leo 🐶", "Leo Maltese 🐶":
            Image(nsImage: StatusIconRenderer.generateGlyphImage(glyph: "Leo Maltese 🐶", size: 22, phase: 0))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 22, height: 22)

        case "Apple Modern", "Apple Logo":
            Image(systemName: "apple.logo")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.primary)
                .frame(width: 24, height: 24)

        case "Diamond Facet":
            Image(systemName: "suit.diamond.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.cyan)
                .frame(width: 24, height: 24)

        case "Star Sparkle":
            Image(systemName: "sparkles")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.yellow)
                .frame(width: 24, height: 24)

        case "Cyber Bolt":
            Image(systemName: "bolt.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.yellow)
                .frame(width: 24, height: 24)

        case "Retro Mac":
            Image(systemName: "macwindow")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.orange)
                .frame(width: 24, height: 24)

        case "Pixel Heart":
            Image(systemName: "heart.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.pink)
                .frame(width: 24, height: 24)

        case "Solar Flare":
            Image(systemName: "sun.max.fill")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.orange)
                .frame(width: 24, height: 24)

        case "Infinity Orb":
            Image(systemName: "infinity")
                .font(.system(size: 14, weight: .heavy))
                .foregroundColor(.purple)
                .frame(width: 24, height: 24)

        default:
            if style.unicodeScalars.contains(where: { $0.properties.isEmoji }) {
                Text(style)
                    .font(.system(size: 16))
                    .frame(width: 24, height: 24)
            } else {
                Text("🪔")
                    .font(.system(size: 15))
                    .frame(width: 24, height: 24)
            }
        }
    }
}

// MARK: - Interactive Popover Picker

struct BrandLogoPickerPopoverView: View {
    @AppStorage(PrefKey.appLanguage) var appLanguage: String = "English (US)"
@Binding var isPresented: Bool
    @ObservedObject private var brandManager = BrandLogoManager.shared

    var isDefaultGenie: Bool {
        brandManager.brandIconStyle == "Genie Lamp" && brandManager.customLogoImage == nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header with On/Off Toggle
            HStack {
                Text(LocalizedStrings.translateText("BRAND ICON & LOGO", lang: appLanguage))
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary)

                Spacer()

                HStack(spacing: 4) {
                    Text(brandManager.isBrandIconVisible ? "ON" : "OFF")
                        .font(.system(size: 9, weight: .bold, design: .rounded))
                        .foregroundColor(brandManager.isBrandIconVisible ? .teal : .secondary)

                    Toggle("", isOn: $brandManager.isBrandIconVisible)
                        .labelsHidden()
                        .toggleStyle(.switch)
                        .controlSize(.mini)
                }
            }

            Divider().opacity(0.3)

            // Primary Quick Action: Reset to Default Genie Lamp 🪔
            Button(action: {
                HapticFeedback.selection()
                brandManager.resetToDefaultGenie()
            }) {
                HStack(spacing: 8) {
                    Text(LocalizedStrings.translateText("🪔", lang: appLanguage))
                        .font(.system(size: 15))

                    VStack(alignment: .leading, spacing: 1) {
                        Text(LocalizedStrings.translateText("Reset to Default Genie Logo", lang: appLanguage))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(isDefaultGenie ? .teal : .primary)
                        Text(LocalizedStrings.translateText("Restores default 🪔 lamp & clears custom logo", lang: appLanguage))
                            .font(.system(size: 8.5))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    if isDefaultGenie {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.teal)
                    } else {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 10.5, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(isDefaultGenie ? Color.teal.opacity(0.16) : Color(nsColor: .controlBackgroundColor).opacity(0.6))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .stroke(isDefaultGenie ? Color.teal : Color.primary.opacity(0.08), lineWidth: isDefaultGenie ? 1.2 : 0.8)
                )
            }
            .buttonStyle(.plain)
            .help("Revert changes back to default Genie Lamp 🪔")

            // Custom Photo Upload Button with Mini Conversion & Delete
            HStack(spacing: 5) {
                Button(action: {
                    brandManager.promptPictureUpload()
                }) {
                    HStack(spacing: 8) {
                        if let customImg = brandManager.customLogoImage {
                            Image(nsImage: customImg)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width: 24, height: 24)
                                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                        } else {
                            ZStack {
                                RoundedRectangle(cornerRadius: 5, style: .continuous)
                                    .fill(Color.teal.opacity(0.18))
                                    .frame(width: 24, height: 24)
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.teal)
                            }
                        }

                        VStack(alignment: .leading, spacing: 1) {
                            Text(brandManager.customLogoImage != nil ? "Replace Custom Logo..." : "Upload Custom Picture...")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.primary)
                            Text(LocalizedStrings.translateText("Auto-crops & converts to mini badge", lang: appLanguage))
                                .font(.system(size: 8.5))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if brandManager.brandIconStyle == "Custom Upload" && brandManager.customLogoImage != nil {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 11))
                                .foregroundColor(.teal)
                        } else {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(brandManager.brandIconStyle == "Custom Upload" ? Color.teal.opacity(0.15) : Color(nsColor: .controlBackgroundColor).opacity(0.6))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .stroke(brandManager.brandIconStyle == "Custom Upload" ? Color.teal : Color.primary.opacity(0.08), lineWidth: 1.0)
                    )
                }
                .buttonStyle(.plain)

                if brandManager.customLogoImage != nil {
                    Button(action: {
                        HapticFeedback.selection()
                        brandManager.removeCustomLogo()
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 10.5, weight: .semibold))
                            .foregroundColor(.red.opacity(0.85))
                            .frame(width: 26, height: 36)
                            .background(
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .fill(Color.red.opacity(0.12))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .stroke(Color.red.opacity(0.25), lineWidth: 0.8)
                            )
                    }
                    .buttonStyle(.plain)
                    .help("Delete custom uploaded logo and revert to Genie")
                }
            }

            // Built-in Brand Icons Grid
            Text(LocalizedStrings.translateText("BRAND ICON PRESETS", lang: appLanguage))
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.secondary)
                .padding(.top, 2)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                ForEach(brandManager.builtInIcons) { option in
                    let isSel = brandManager.brandIconStyle == option.id && (option.id != "Genie Lamp" || brandManager.customLogoImage == nil)
                    Button(action: {
                        HapticFeedback.selection()
                        if option.id == "Genie Lamp" {
                            brandManager.resetToDefaultGenie()
                        } else {
                            brandManager.selectPreset(option.id)
                        }
                    }) {
                        HStack(spacing: 6) {
                            Text(option.emoji)
                                .font(.system(size: 12))

                            VStack(alignment: .leading, spacing: 0.5) {
                                Text(option.name)
                                    .font(.system(size: 10.5, weight: isSel ? .bold : .medium))
                                    .foregroundColor(isSel ? .teal : .primary)
                                    .lineLimit(1)
                            }

                            Spacer()

                            if isSel {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(.teal)
                            }
                        }
                        .padding(.horizontal, 7)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(isSel ? Color.teal.opacity(0.14) : Color(nsColor: .controlBackgroundColor).opacity(0.5))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .stroke(isSel ? Color.teal : Color.primary.opacity(0.06), lineWidth: isSel ? 1.2 : 0.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(12)
        .frame(width: 280)
    }
}
