import SwiftUI
import AppKit

// MARK: - Fonts Tab View with Live Previews of All Available System Fonts

public struct FontsTabContentView: View {
    @AppStorage(PrefKey.appLanguage) var appLanguage: String = "English (US)"
@ObservedObject private var fontManager = AppFontManager.shared
    @State private var searchQuery: String = ""
    @State private var selectedCategory: String = "All"
    @State private var previewSize: Double = 14.0
    @State private var customSampleText: String = "The quick brown fox jumps over the lazy dog 1234567890 "

    private let categories = [
        "All", "Modern Sans 🔤", "Monospace 💻", "Serif 📜", "Script & Display 🎨", "System "
    ]

    private var filteredFonts: [AppFontItem] {
        var list = fontManager.availableFonts
        if selectedCategory != "All" {
            list = list.filter { $0.category == selectedCategory }
        }
        if !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty {
            let q = searchQuery.lowercased()
            list = list.filter { $0.familyName.lowercased().contains(q) || $0.category.lowercased().contains(q) }
        }
        return list
    }

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // MARK: - Header & Active Font Banner
            activeFontHeaderCard

            // MARK: - Search & Category Filter Bar
            filterAndSearchBar

            // MARK: - Live Preview Font Cards
            ScrollView(.vertical, showsIndicators: true) {
                LazyVStack(spacing: 8) {
                    ForEach(filteredFonts) { item in
                        FontPreviewCard(
                            item: item,
                            isActive: fontManager.currentFontFamily == item.familyName,
                            previewSize: CGFloat(previewSize),
                            sampleText: customSampleText,
                            onSelect: {
                                HapticFeedback.selection()
                                fontManager.currentFontFamily = item.familyName
                            }
                        )
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(maxHeight: .infinity)
        }
        .padding(12)
    }

    // MARK: - Active Font Header Card
    private var activeFontHeaderCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(LocalizedStrings.translateText("CURRENT SYSTEM FONT", lang: appLanguage))
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundColor(.secondary)

                    Text(fontManager.currentFontFamily)
                        .font(fontManager.font(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                }

                Spacer()

                if fontManager.currentFontFamily != "System (San Francisco)" {
                    Button(action: {
                        HapticFeedback.selection()
                        fontManager.resetToDefault()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 9.5, weight: .bold))
                            Text(LocalizedStrings.translateText("Reset to Apple System", lang: appLanguage))
                                .font(.system(size: 10, weight: .semibold))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.orange.opacity(0.15)))
                        .overlay(Capsule().strokeBorder(Color.orange.opacity(0.4), lineWidth: 1))
                        .foregroundColor(.orange)
                    }
                    .buttonStyle(.plain)
                    .help("Reset back to default Apple San Francisco font")
                }
            }

            // Live Preview of Current Font
            Text(customSampleText)
                .font(fontManager.font(size: CGFloat(previewSize), weight: .regular))
                .foregroundColor(.primary)
                .lineLimit(2)
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.primary.opacity(0.04)))
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.accentColor.opacity(0.35), lineWidth: 1))

            // Preview Font Size Slider
            HStack(spacing: 8) {
                Text(LocalizedStrings.translateText("Preview Size:", lang: appLanguage))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)

                Slider(value: $previewSize, in: 10...24, step: 1)
                    .controlSize(.small)

                Text("\(Int(previewSize)) pt")
                    .font(.system(size: 10, weight: .bold).monospacedDigit())
                    .foregroundColor(.accentColor)
                    .frame(width: 34)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - Search & Category Filter Bar
    private var filterAndSearchBar: some View {
        VStack(spacing: 6) {
            // Search field
            HStack(spacing: 6) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)

                TextField("Search fonts (e.g. Helvetica, Monaco, Futura, Avenir...)", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11))

                if !searchQuery.isEmpty {
                    Button(action: { searchQuery = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                Text("\(filteredFonts.count) fonts")
                    .font(.system(size: 9.5, weight: .bold).monospacedDigit())
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.primary.opacity(0.06)))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(RoundedRectangle(cornerRadius: 7).fill(Color.primary.opacity(0.05)))
            .overlay(RoundedRectangle(cornerRadius: 7).strokeBorder(Color.white.opacity(0.10), lineWidth: 0.8))

            // Category Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 5) {
                    ForEach(categories, id: \.self) { cat in
                        let isSel = selectedCategory == cat
                        Button(action: {
                            HapticFeedback.selection()
                            withAnimation(.spring(response: 0.20, dampingFraction: 0.80)) {
                                selectedCategory = cat
                            }
                        }) {
                            Text(cat)
                                .font(.system(size: 9.5, weight: isSel ? .bold : .medium))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(isSel ? Color.accentColor.opacity(0.20) : Color.primary.opacity(0.04)))
                                .overlay(Capsule().strokeBorder(isSel ? Color.accentColor.opacity(0.60) : Color.clear, lineWidth: 1))
                                .foregroundColor(isSel ? .accentColor : .secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

// MARK: - Individual Font Preview Card

struct FontPreviewCard: View {
    @AppStorage(PrefKey.appLanguage) var appLanguage: String = "English (US)"
let item: AppFontItem
    let isActive: Bool
    let previewSize: CGFloat
    let sampleText: String
    let onSelect: () -> Void

    @State private var isHovered: Bool = false

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    // Font Family Name
                    Text(item.displayName)
                        .font(AppFontManager.resolveFont(family: item.familyName, size: 13, weight: .bold))
                        .foregroundColor(isActive ? .accentColor : .primary)

                    // Category Pill
                    Text(item.category)
                        .font(.system(size: 8.5, weight: .semibold))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1.5)
                        .background(Capsule().fill(Color.primary.opacity(0.06)))

                    Spacer()

                    if isActive {
                        HStack(spacing: 3) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 11, weight: .bold))
                            Text(LocalizedStrings.translateText("ACTIVE", lang: appLanguage))
                                .font(.system(size: 8.5, weight: .heavy, design: .rounded))
                        }
                        .foregroundColor(.accentColor)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.accentColor.opacity(0.18)))
                    } else {
                        Text(LocalizedStrings.translateText("Apply", lang: appLanguage))
                            .font(.system(size: 9.5, weight: .semibold))
                            .foregroundColor(isHovered ? .primary : .secondary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(RoundedRectangle(cornerRadius: 4).fill(isHovered ? Color.primary.opacity(0.10) : Color.clear))
                    }
                }

                // Live Preview in this exact Font Family
                Text(sampleText)
                    .font(AppFontManager.resolveFont(family: item.familyName, size: previewSize, weight: .regular))
                    .foregroundColor(isActive ? .primary : .primary.opacity(0.85))
                    .lineLimit(1)

                // Alphabet & Numbers specimen
                Text(LocalizedStrings.translateText("ABCDEFGHIJKLMNOPQRSTUVWXYZ  abcdefghijklmnopqrstuvwxyz  0123456789", lang: appLanguage))
                    .font(AppFontManager.resolveFont(family: item.familyName, size: 10, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(isActive ? Color.accentColor.opacity(0.12) : (isHovered ? Color.primary.opacity(0.06) : Color(nsColor: .controlBackgroundColor).opacity(0.35)))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .strokeBorder(isActive ? Color.accentColor : (isHovered ? Color.white.opacity(0.20) : Color.primary.opacity(0.06)), lineWidth: isActive ? 1.4 : 0.8)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
