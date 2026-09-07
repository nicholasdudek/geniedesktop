import AppKit
import SwiftUI

// MARK: - Dropdown Window Background Preset
public struct DropdownBgPreset: Identifiable, Hashable {
    public let id: String
    public let name: String
    public let category: String
    public let icon: String
    public let gradientColors: [Color]
    public let systemImagePath: String?

    public init(id: String, name: String, category: String, icon: String, gradientColors: [Color], systemImagePath: String? = nil) {
        self.id = id
        self.name = name
        self.category = category
        self.icon = icon
        self.gradientColors = gradientColors
        self.systemImagePath = systemImagePath
    }
}

// MARK: - Dropdown Background Manager
@MainActor
public final class DropdownBackgroundManager: ObservableObject {
    public static let shared = DropdownBackgroundManager()

    @Published public var customImage: NSImage? = nil

    public let presets: [DropdownBgPreset] = [
        DropdownBgPreset(
            id: "wallpaper_mirror",
            name: "Desktop Wallpaper Mirror",
            category: "Dynamic",
            icon: "sparkles.tv",
            gradientColors: [Color.blue.opacity(0.6), Color.purple.opacity(0.6)]
        ),
        DropdownBgPreset(
            id: "sequoia_sunrise",
            name: "macOS Sequoia Sunrise",
            category: "Apple macOS",
            icon: "sun.horizon.fill",
            gradientColors: [
                Color(red: 0.95, green: 0.50, blue: 0.25),
                Color(red: 0.70, green: 0.20, blue: 0.45),
                Color(red: 0.20, green: 0.10, blue: 0.35)
            ]
        ),
        DropdownBgPreset(
            id: "sonoma_horizon",
            name: "macOS Sonoma Valley",
            category: "Apple macOS",
            icon: "mountain.2.fill",
            gradientColors: [
                Color(red: 0.25, green: 0.65, blue: 0.95),
                Color(red: 0.35, green: 0.75, blue: 0.55),
                Color(red: 0.15, green: 0.35, blue: 0.25)
            ]
        ),
        DropdownBgPreset(
            id: "ventura_bloom",
            name: "macOS Ventura Bloom",
            category: "Apple macOS",
            icon: "camera.macro",
            gradientColors: [
                Color(red: 0.98, green: 0.45, blue: 0.15),
                Color(red: 0.85, green: 0.20, blue: 0.30),
                Color(red: 0.10, green: 0.30, blue: 0.60)
            ]
        ),
        DropdownBgPreset(
            id: "monterey_twilight",
            name: "macOS Monterey Twilight",
            category: "Apple macOS",
            icon: "sunset.fill",
            gradientColors: [
                Color(red: 0.55, green: 0.15, blue: 0.75),
                Color(red: 0.85, green: 0.25, blue: 0.60),
                Color(red: 0.12, green: 0.08, blue: 0.28)
            ]
        ),
        DropdownBgPreset(
            id: "cosmic_nebula",
            name: "Cosmic Deep Space",
            category: "Cosmic",
            icon: "moon.stars.fill",
            gradientColors: [
                Color(red: 0.08, green: 0.04, blue: 0.20),
                Color(red: 0.28, green: 0.08, blue: 0.45),
                Color(red: 0.04, green: 0.15, blue: 0.35),
                Color.black
            ]
        ),
        DropdownBgPreset(
            id: "tokyo_neon",
            name: "Tokyo Neon Rain",
            category: "Futuristic",
            icon: "cloud.rain.fill",
            gradientColors: [
                Color(red: 0.05, green: 0.06, blue: 0.12),
                Color(red: 0.10, green: 0.30, blue: 0.45),
                Color(red: 0.40, green: 0.05, blue: 0.35)
            ]
        ),
        DropdownBgPreset(
            id: "aero_frost_clear",
            name: "Pure Aero Frosted Glass",
            category: "Glassmorphism",
            icon: "square.fill.on.square.fill",
            gradientColors: [
                Color.white.opacity(0.12),
                Color.white.opacity(0.04)
            ]
        ),
        DropdownBgPreset(
            id: "liquid_glass",
            name: "Liquid Glass",
            category: "Glassmorphism",
            icon: "drop.fill",
            gradientColors: [
                Color.white.opacity(0.25),
                Color.blue.opacity(0.15),
                Color.white.opacity(0.10)
            ],
            systemImagePath: nil
        ),
        DropdownBgPreset(
            id: "obsidian_luxury",
            name: "24K Obsidian Gold",
            category: "Luxury",
            icon: "crown.fill",
            gradientColors: [
                Color(red: 0.12, green: 0.10, blue: 0.08),
                Color(red: 0.22, green: 0.16, blue: 0.08),
                Color(red: 0.05, green: 0.05, blue: 0.05)
            ]
        )
    ]

    private init() {
        loadCustomImageFromDisk()
    }

    public func selectPreset(_ presetId: String) {
        UserDefaults.standard.set(presetId, forKey: PrefKey.dropdownBgPreset)
        objectWillChange.send()
    }

    public func currentPreset() -> DropdownBgPreset {
        let id = UserDefaults.standard.string(forKey: PrefKey.dropdownBgPreset) ?? "wallpaper_mirror"
        return presets.first { $0.id == id } ?? presets.first ?? DropdownBgPreset(id: "fallback", name: "Default", category: "Standard", icon: "sparkles", gradientColors: [.cyan, .blue])
    }

    public func pickCustomImageFile() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Select Dropdown Window Background Image"
        openPanel.allowedContentTypes = [.image, .png, .jpeg, .heic]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false

        if openPanel.runModal() == .OK, let url = openPanel.url {
            saveCustomImage(from: url)
        }
    }

    public func saveCustomImage(from url: URL) {
        guard let img = NSImage(contentsOf: url) else { return }
        self.customImage = img
        UserDefaults.standard.set("custom", forKey: PrefKey.dropdownBgPreset)
        UserDefaults.standard.set(url.path, forKey: PrefKey.dropdownCustomBgPath)
        objectWillChange.send()
    }

    public func clearCustomImage() {
        self.customImage = nil
        UserDefaults.standard.removeObject(forKey: PrefKey.dropdownCustomBgPath)
        UserDefaults.standard.set("wallpaper_mirror", forKey: PrefKey.dropdownBgPreset)
        objectWillChange.send()
    }

    private func loadCustomImageFromDisk() {
        guard let path = UserDefaults.standard.string(forKey: PrefKey.dropdownCustomBgPath),
              FileManager.default.fileExists(atPath: path),
              let img = NSImage(contentsOfFile: path) else {
            return
        }
        self.customImage = img
    }
}
