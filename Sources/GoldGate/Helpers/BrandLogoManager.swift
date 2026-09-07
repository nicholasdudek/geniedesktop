import AppKit
import SwiftUI

// MARK: - Brand Icon Definition

struct BrandIconOption: Identifiable, Hashable {
    let id: String
    let name: String
    let subtitle: String
    let systemImage: String?
    let emoji: String
}

// MARK: - Brand Logo Manager & Mini Conversion Engine

@MainActor
final class BrandLogoManager: ObservableObject {
    static let shared = BrandLogoManager()

    @Published var customLogoImage: NSImage?
    @Published var brandIconStyle: String {
        didSet {
            UserDefaults.standard.set(brandIconStyle, forKey: PrefKey.brandIconStyle)
            UserDefaults.standard.set(brandIconStyle, forKey: PrefKey.statusIconStyle)
            NotificationCenter.default.post(name: NSNotification.Name("NexusBrandLogoChanged"), object: nil)
        }
    }
    @Published var isBrandIconVisible: Bool {
        didSet {
            UserDefaults.standard.set(isBrandIconVisible, forKey: PrefKey.brandIconEnabled)
            UserDefaults.standard.set(isBrandIconVisible, forKey: PrefKey.iconEnabled)
            NotificationCenter.default.post(name: NSNotification.Name("NexusBrandLogoChanged"), object: nil)
        }
    }

    let builtInIcons: [BrandIconOption] = [
        BrandIconOption(id: "Genie Person", name: "Genie Person", subtitle: "Mystical Wish-Granting Genie", systemImage: nil, emoji: "🧞‍♂️"),
        BrandIconOption(id: "Genie Lamp", name: "Genie Lamp", subtitle: "Mystical Wish-Granting Lamp", systemImage: nil, emoji: "🪔"),
        BrandIconOption(id: "Leo Maltese", name: "Leo 🐶", subtitle: "Fluffy Maltese Puppy", systemImage: nil, emoji: "🐶"),
        BrandIconOption(id: "Genie Portal", name: "Genie Portal", subtitle: "Spatial Portal Gateway", systemImage: "sparkle.magnifyingglass", emoji: "🌀"),
        BrandIconOption(id: "Apple Modern", name: "Apple Modern", subtitle: "Official Apple Silhouette", systemImage: "apple.logo", emoji: ""),
        BrandIconOption(id: "Diamond Facet", name: "Diamond Facet", subtitle: "Luminescent Cyan Crystal", systemImage: "suit.diamond.fill", emoji: "💎"),
        BrandIconOption(id: "Star Sparkle", name: "Star Sparkle", subtitle: "8-Point Golden Starlight", systemImage: "sparkles", emoji: "✨"),
        BrandIconOption(id: "Cyber Bolt", name: "Cyber Bolt", subtitle: "Electric Cyberpunk Energy", systemImage: "bolt.fill", emoji: "⚡️"),
        BrandIconOption(id: "Retro Mac", name: "Retro Macintosh", subtitle: "1984 Classic Mac", systemImage: "macwindow", emoji: "🖥️"),
        BrandIconOption(id: "Pixel Heart", name: "Pixel Heart", subtitle: "Retro 8-Bit Life", systemImage: "heart.fill", emoji: "💖"),
        BrandIconOption(id: "Solar Flare", name: "Solar Flare", subtitle: "Amber Solar Corona", systemImage: "sun.max.fill", emoji: "☀️"),
        BrandIconOption(id: "Infinity Orb", name: "Infinity Orb", subtitle: "Cosmic Eternal Loop", systemImage: "infinity", emoji: "♾️")
    ]

    private init() {
        let savedStyle = UserDefaults.standard.string(forKey: PrefKey.brandIconStyle)
            ?? UserDefaults.standard.string(forKey: PrefKey.statusIconStyle)
            ?? "Genie Lamp"
        if savedStyle.contains("Rocket") || savedStyle.isEmpty {
            self.brandIconStyle = "Genie Lamp"
            UserDefaults.standard.set("Genie Lamp", forKey: PrefKey.brandIconStyle)
            UserDefaults.standard.set("Genie Lamp", forKey: PrefKey.statusIconStyle)
        } else {
            self.brandIconStyle = savedStyle
        }

        let savedVisible = UserDefaults.standard.object(forKey: PrefKey.brandIconEnabled) == nil
            ? (UserDefaults.standard.object(forKey: PrefKey.iconEnabled) == nil ? true : UserDefaults.standard.bool(forKey: PrefKey.iconEnabled))
            : UserDefaults.standard.bool(forKey: PrefKey.brandIconEnabled)
        self.isBrandIconVisible = savedVisible

        loadCustomLogoFromDisk()
    }

    // MARK: - Revert & Reset Actions

    func resetToDefaultGenie() {
        customLogoImage = nil
        brandIconStyle = "Genie Lamp"
        UserDefaults.standard.set("Genie Lamp", forKey: PrefKey.brandIconStyle)
        UserDefaults.standard.set("Genie Lamp", forKey: PrefKey.statusIconStyle)
        UserDefaults.standard.removeObject(forKey: PrefKey.customBrandLogoPath)
        if let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let geniePath = appSupport.appendingPathComponent("Genie/custom_brand_logo.png").path
            let legacyPath = appSupport.appendingPathComponent("GoldGate/custom_brand_logo.png").path
            try? FileManager.default.removeItem(atPath: geniePath)
            try? FileManager.default.removeItem(atPath: legacyPath)
        }
        brandIconStyle = "Genie Lamp"
        isBrandIconVisible = true
        NotificationCenter.default.post(name: NSNotification.Name("NexusBrandLogoChanged"), object: nil)
        NotificationCenter.default.post(name: NSNotification.Name("NexusIconStyleChanged"), object: nil)
    }

    func removeCustomLogo() {
        customLogoImage = nil
        UserDefaults.standard.removeObject(forKey: PrefKey.customBrandLogoPath)
        if let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let geniePath = appSupport.appendingPathComponent("Genie/custom_brand_logo.png").path
            let legacyPath = appSupport.appendingPathComponent("GoldGate/custom_brand_logo.png").path
            try? FileManager.default.removeItem(atPath: geniePath)
            try? FileManager.default.removeItem(atPath: legacyPath)
        }
        if brandIconStyle == "Custom Upload" {
            brandIconStyle = "Genie Lamp"
        }
        NotificationCenter.default.post(name: NSNotification.Name("NexusBrandLogoChanged"), object: nil)
        NotificationCenter.default.post(name: NSNotification.Name("NexusIconStyleChanged"), object: nil)
    }

    func selectPreset(_ styleId: String) {
        brandIconStyle = styleId
        isBrandIconVisible = true
        NotificationCenter.default.post(name: NSNotification.Name("NexusBrandLogoChanged"), object: nil)
        NotificationCenter.default.post(name: NSNotification.Name("NexusIconStyleChanged"), object: nil)
    }

    func setCustomEmoji(_ emoji: String) {
        let trimmed = emoji.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        brandIconStyle = trimmed
        customLogoImage = nil
        UserDefaults.standard.removeObject(forKey: PrefKey.customBrandLogoPath)
        UserDefaults.standard.set(trimmed, forKey: PrefKey.customStatusEmoji)
        UserDefaults.standard.set(trimmed, forKey: PrefKey.statusIconStyle)
        UserDefaults.standard.set(trimmed, forKey: PrefKey.brandIconStyle)
        isBrandIconVisible = true
        NotificationCenter.default.post(name: NSNotification.Name("NexusBrandLogoChanged"), object: nil)
        NotificationCenter.default.post(name: NSNotification.Name("NexusIconStyleChanged"), object: nil)
    }

    func loadCustomLogoFromDisk() {
        if let savedPath = UserDefaults.standard.string(forKey: PrefKey.customBrandLogoPath),
           FileManager.default.fileExists(atPath: savedPath),
           let img = NSImage(contentsOfFile: savedPath) {
            self.customLogoImage = img
        } else {
            if let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
                let geniePath = appSupport.appendingPathComponent("Genie/custom_brand_logo.png").path
                let legacyPath = appSupport.appendingPathComponent("GoldGate/custom_brand_logo.png").path
                let chosenPath = FileManager.default.fileExists(atPath: geniePath) ? geniePath : legacyPath
                if FileManager.default.fileExists(atPath: chosenPath),
                   let img = NSImage(contentsOfFile: chosenPath) {
                    self.customLogoImage = img
                    UserDefaults.standard.set(chosenPath, forKey: PrefKey.customBrandLogoPath)
                }
            }
        }
    }

    // MARK: - Mini Conversion Engine
    /// Crops any user image to square, resizes to crisp 128x128 retina thumbnail, and saves as PNG
    func convertAndSaveCustomPicture(from sourceURL: URL) -> Bool {
        guard let sourceImage = NSImage(contentsOf: sourceURL) else { return false }

        let targetSize = CGSize(width: 128, height: 128)
        let convertedImage = NSImage(size: targetSize)
        convertedImage.lockFocus()

        let srcSize = sourceImage.size
        let minDimension = min(srcSize.width, srcSize.height)
        let cropRect = CGRect(
            x: (srcSize.width - minDimension) / 2.0,
            y: (srcSize.height - minDimension) / 2.0,
            width: minDimension,
            height: minDimension
        )

        sourceImage.draw(
            in: CGRect(origin: .zero, size: targetSize),
            from: cropRect,
            operation: .copy,
            fraction: 1.0
        )
        convertedImage.unlockFocus()

        // Write PNG to App Support
        guard let tiffData = convertedImage.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:]) else {
            return false
        }

        do {
            guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return false }
            let genieFolder = appSupport.appendingPathComponent("Genie", isDirectory: true)
            try FileManager.default.createDirectory(at: genieFolder, withIntermediateDirectories: true, attributes: nil)

            let destURL = genieFolder.appendingPathComponent("custom_brand_logo.png")
            try pngData.write(to: destURL, options: .atomic)

            self.customLogoImage = convertedImage
            UserDefaults.standard.set(destURL.path, forKey: PrefKey.customBrandLogoPath)
            self.brandIconStyle = "Custom Upload"
            self.isBrandIconVisible = true

            NotificationCenter.default.post(name: NSNotification.Name("NexusBrandLogoChanged"), object: nil)
            return true
        } catch {
            print("Failed to save converted brand logo: \(error)")
            return false
        }
    }

    func promptPictureUpload() {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.allowsMultipleSelection = false
        openPanel.allowedContentTypes = [.image, .jpeg, .png, .heic]
        openPanel.title = "Upload Brand Logo Image"
        openPanel.message = "Choose any picture or graphic. Genie will automatically convert it into a mini brand badge."
        openPanel.level = NSWindow.Level(rawValue: max(NSWindow.Level.statusBar.rawValue, NSApp.keyWindow?.level.rawValue ?? 0) + 10)
        NSApp.activate(ignoringOtherApps: true)
        openPanel.center()
        openPanel.orderFrontRegardless()

        if openPanel.runModal() == .OK, let url = openPanel.url {
            _ = convertAndSaveCustomPicture(from: url)
        }
    }
}
