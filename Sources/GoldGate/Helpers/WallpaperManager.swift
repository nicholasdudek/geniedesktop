import AppKit
import SwiftUI

// MARK: - Wallpaper Categories & Models

public enum WallpaperCategory: String, CaseIterable, Identifiable {
    case dynamic = "Dynamic"
    case landscape = "Landscape"
    case studio = "Studio"
    case solid = "Solid Colors"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .dynamic: return "sparkles"
        case .landscape: return "mountain.2.fill"
        case .studio: return "circle.hexagongrid.fill"
        case .solid: return "paintpalette.fill"
        }
    }
}

public struct WallpaperItem: Identifiable, Hashable {
    public let id: String
    public let name: String
    public let category: WallpaperCategory
    public let path: String
    public var isSystemActive: Bool = false

    public init(id: String, name: String, category: WallpaperCategory, path: String, isSystemActive: Bool = false) {
        self.id = id
        self.name = name
        self.category = category
        self.path = path
        self.isSystemActive = isSystemActive
    }
}

// MARK: - Flagship Wallpaper Manager & Dynamic Thumbnail Engine

public final class WallpaperManager: ObservableObject {
    public static let shared = WallpaperManager()

    @Published public var activeWallpaperImage: NSImage?
    @Published public var availableWallpapers: [WallpaperItem] = []

    private let thumbnailCache = NSCache<NSString, NSImage>()
    private var lastLoadedPath: String?
    private var lastModDate: Date?
    private var refreshTimer: Timer?

    private init() {
        thumbnailCache.countLimit = 30
        loadAvailableWallpapers()
        refresh()
        setupLiveMonitoring()
    }

    private func setupLiveMonitoring() {
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refresh()
        }

        refreshTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { [weak self] _ in
            self?.checkForSystemWallpaperChanges()
        }
    }

    private func checkForSystemWallpaperChanges() {
        let storePath = ("~/Library/Application Support/com.apple.wallpaper/Store/Index.plist" as NSString).expandingTildeInPath
        if let attrs = try? FileManager.default.attributesOfItem(atPath: storePath),
           let modDate = attrs[.modificationDate] as? Date {
            if modDate != lastModDate {
                lastModDate = modDate
                refresh()
            }
        }
    }

    // MARK: - 🌉 Golden Gate & Bundled 4K Asset Resolvers
    public func findBundledWallpaperPath(named name: String) -> String? {
        let clean = name.replacingOccurrences(of: " ", with: "")
        let extensions = ["jpg", "jpeg", "png", "heic"]
        
        var baseDirs: [String] = []
        if let bundleWallpapers = Bundle.main.resourceURL?.appendingPathComponent("Wallpapers").path {
            baseDirs.append(bundleWallpapers)
        }
        if let res = Bundle.main.resourcePath {
            baseDirs.append(res)
            baseDirs.append("\(res)/Wallpapers")
        }
        baseDirs.append("/Applications/Genie.app/Contents/Resources/Wallpapers")
        baseDirs.append("/Users/nicholasdudek/Developer/GoldGate/Wallpapers")
        let userHome = FileManager.default.homeDirectoryForCurrentUser.path
        baseDirs.append("\(userHome)/Developer/GoldGate/Wallpapers")
        baseDirs.append("\(userHome)/Pictures")

        for dir in baseDirs {
            for ext in extensions {
                let p1 = "\(dir)/\(name).\(ext)"
                if FileManager.default.fileExists(atPath: p1) { return p1 }
                let p2 = "\(dir)/\(clean).\(ext)"
                if FileManager.default.fileExists(atPath: p2) { return p2 }
            }
        }
        return nil
    }

    public func loadBundledWallpaper(named name: String) -> NSImage? {
        if let path = findBundledWallpaperPath(named: name), let img = NSImage(contentsOfFile: path) {
            return img
        }
        return nil
    }

    public func resolveLiveSystemWallpaper() -> NSImage? {
        // 1. Inspect macOS Sonoma / Sequoia / Golden Gate Index.plist
        let storePath = ("~/Library/Application Support/com.apple.wallpaper/Store/Index.plist" as NSString).expandingTildeInPath
        if let plistData = try? Data(contentsOf: URL(fileURLWithPath: storePath)),
           let plist = try? PropertyListSerialization.propertyList(from: plistData, format: nil) as? [String: Any] {
            
            if let displays = plist["Displays"] as? [String: Any] {
                for (_, dispObj) in displays {
                    if let dispDict = dispObj as? [String: Any],
                       let desktop = dispDict["Desktop"] as? [String: Any],
                       let content = desktop["Content"] as? [String: Any],
                       let choices = content["Choices"] as? [[String: Any]] {
                        for choice in choices {
                            if let provider = choice["Provider"] as? String, provider.contains("aerial") {
                                if let configData = choice["Configuration"] as? Data,
                                   let config = try? PropertyListSerialization.propertyList(from: configData, format: nil) as? [String: Any],
                                   let assetID = config["assetID"] as? String {
                                    // Golden Gate aerial ID: 17647EAB-8357-48B0-BCD6-B892194267C5 or known Golden Gate IDs
                                    if assetID.contains("17647EAB") || assetID.contains("4207734D") || assetID.contains("6511D2B5") || assetID.contains("3FD9FD5C") || assetID.contains("86E89C23") {
                                        if let gg = loadBundledWallpaper(named: "GoldenGateDynamic") ?? loadBundledWallpaper(named: "GoldenGateSunset") ?? loadBundledWallpaper(named: "GoldenGateAerial4K") {
                                            lastLoadedPath = findBundledWallpaperPath(named: "GoldenGateDynamic")
                                            return gg
                                        }
                                    }
                                    let thumbPath = ("~/Library/Application Support/com.apple.wallpaper/aerials/thumbnails/\(assetID).png" as NSString).expandingTildeInPath
                                    if let img = NSImage(contentsOfFile: thumbPath) {
                                        lastLoadedPath = thumbPath
                                        return img
                                    }
                                }
                            }
                            if let files = choice["Files"] as? [[String: Any]] {
                                for file in files {
                                    if let path = file["path"] as? String, let img = NSImage(contentsOfFile: path) {
                                        lastLoadedPath = path
                                        return img
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // 2. Query NSWorkspace desktopImageURL
        if let screen = NSScreen.main ?? NSScreen.screens.first,
           let url = NSWorkspace.shared.desktopImageURL(for: screen),
           FileManager.default.fileExists(atPath: url.path) {
            let path = url.path
            // If macOS returned generic DefaultDesktop.heic, but user has Golden Gate, prefer Golden Gate!
            if path.contains("DefaultDesktop.heic") {
                if let gg = loadBundledWallpaper(named: "GoldenGateDynamic") ?? loadBundledWallpaper(named: "GoldenGateSunset") ?? loadBundledWallpaper(named: "GoldenGateAerial4K") {
                    lastLoadedPath = findBundledWallpaperPath(named: "GoldenGateDynamic")
                    return gg
                }
            }
            if let img = NSImage(contentsOf: url) {
                lastLoadedPath = path
                return img
            }
        }

        // 3. Fallback to 4K Golden Gate Dynamic
        if let gg = loadBundledWallpaper(named: "GoldenGateDynamic") ?? loadBundledWallpaper(named: "GoldenGateSunset") ?? loadBundledWallpaper(named: "GoldenGateAerial4K") {
            lastLoadedPath = findBundledWallpaperPath(named: "GoldenGateDynamic")
            return gg
        }

        return nil
    }

    func loadAvailableWallpapers() {
        var items: [WallpaperItem] = [
            WallpaperItem(
                id: "system_current",
                name: "1:1 Live macOS Desktop (Camouflage)",
                category: .dynamic,
                path: "",
                isSystemActive: true
            )
        ]

        var seenPaths = Set<String>()

        // 1. Prominently feature the 4K Genie wallpapers at the very top
        let geniePresets: [(id: String, name: String, file: String, fallback: String)] = [
            ("genie_dynamic", "Genie Dynamic 4K (Day / Sunset)", "GenieDynamic", "GoldenGateDynamic"),
            ("genie_sunset", "Genie Sunset 4K (California Dusk)", "GenieSunset", "GoldenGateSunset"),
            ("genie_aerial", "Genie Aerial 4K (San Francisco Bay)", "GenieAerial4K", "GoldenGateAerial4K")
        ]
        for preset in geniePresets {
            if let path = findBundledWallpaperPath(named: preset.file) ?? findBundledWallpaperPath(named: preset.fallback) {
                if !seenPaths.contains(path) {
                    seenPaths.insert(path)
                    items.append(WallpaperItem(
                        id: preset.id,
                        name: preset.name,
                        category: .dynamic,
                        path: path
                    ))
                }
            }
        }

        // 2. Search local Wallpapers directories and all Apple macOS system wallpaper folders
        var searchDirectories: [String] = []
        if let bundleWallpapers = Bundle.main.resourceURL?.appendingPathComponent("Wallpapers").path {
            searchDirectories.append(bundleWallpapers)
        }
        searchDirectories.append("/Applications/Genie.app/Contents/Resources/Wallpapers")
        searchDirectories.append("/Users/nicholasdudek/Developer/GoldGate/Wallpapers")
        let homePath = FileManager.default.homeDirectoryForCurrentUser.path
        searchDirectories.append("\(homePath)/Developer/GoldGate/Wallpapers")
        searchDirectories.append("\(homePath)/Library/Application Support/com.apple.wallpaper/aerials/thumbnails")
        if let picturesDir = FileManager.default.urls(for: .picturesDirectory, in: .userDomainMask).first?.path {
            searchDirectories.append(picturesDir)
        }
        searchDirectories.append("/Library/Desktop Pictures")
        searchDirectories.append("/System/Library/Desktop Pictures")
        searchDirectories.append("/System/Library/Desktop Pictures/Solid Colors")
        searchDirectories.append("/System/Library/Desktop Pictures/.thumbnails")

        for dir in searchDirectories {
            let url = URL(fileURLWithPath: dir)
            guard let enumerator = FileManager.default.enumerator(
                at: url,
                includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey],
                options: [.skipsPackageDescendants]
            ) else { continue }

            for case let fileURL as URL in enumerator {
                let ext = fileURL.pathExtension.lowercased()
                if ["heic", "jpg", "jpeg", "png"].contains(ext) {
                    let path = fileURL.path
                    let isSolidColor = path.contains("Solid Colors")
                    let isAppleSystemThumbnail = path.contains("/System/Library/Desktop Pictures/.thumbnails") || path.contains("aerials/thumbnails")

                    // Discard unwanted app caches (except Apple system wallpaper assets)
                    if !isAppleSystemThumbnail && (path.contains("/.thumbnails") || path.contains(".thumbnails") || path.lowercased().contains("thumb")) {
                        continue
                    }

                    // Check file size (Solid Colors are ~300 bytes, official wallpapers >= 5 KB)
                    if let attrs = try? FileManager.default.attributesOfItem(atPath: path),
                       let fileSize = attrs[.size] as? Int {
                        if isSolidColor {
                            if fileSize < 50 { continue }
                        } else if isAppleSystemThumbnail {
                            if fileSize < 5_000 { continue }
                        } else if fileSize < 10_000 {
                            continue
                        }
                    }

                    if !seenPaths.contains(path) {
                        seenPaths.insert(path)
                        let cleanName = fileURL.deletingPathExtension().lastPathComponent
                            .replacingOccurrences(of: "_", with: " ")
                            .replacingOccurrences(of: "-", with: " ")
                        
                        let category: WallpaperCategory
                        if isSolidColor {
                            category = .studio
                        } else if cleanName.lowercased().contains("dark") || cleanName.lowercased().contains("dynamic") || cleanName.lowercased().contains("light") || cleanName.lowercased().contains("golden") {
                            category = .dynamic
                        } else if cleanName.lowercased().contains("sunset") || cleanName.lowercased().contains("cliff") || cleanName.lowercased().contains("beach") || cleanName.lowercased().contains("coast") || cleanName.lowercased().contains("valley") || cleanName.lowercased().contains("horizon") || cleanName.lowercased().contains("sur") || cleanName.lowercased().contains("catalina") || cleanName.lowercased().contains("sonoma") {
                            category = .landscape
                        } else if cleanName.lowercased().contains("grid") || cleanName.lowercased().contains("chroma") || cleanName.lowercased().contains("iridescence") || cleanName.lowercased().contains("dome") || cleanName.lowercased().contains("radial") {
                            category = .studio
                        } else {
                            category = .dynamic
                        }

                        items.append(WallpaperItem(
                            id: path,
                            name: cleanName,
                            category: category,
                            path: path
                        ))
                    }
                }
            }
        }

        self.availableWallpapers = items
    }

    func thumbnail(for item: WallpaperItem) -> NSImage? {
        if item.path.isEmpty {
            return activeWallpaperImage
        }

        let key = item.path as NSString
        if let cached = thumbnailCache.object(forKey: key) {
            return cached
        }

        if let image = NSImage(contentsOfFile: item.path) {
            thumbnailCache.setObject(image, forKey: key)
            return image
        }

        return nil
    }

    func refresh() {
        let wallpaperMode = UserDefaults.standard.string(forKey: PrefKey.wallpaperMode) ?? "Genie"
        let sameWallpaper = UserDefaults.standard.object(forKey: PrefKey.sameWallpaperMode) == nil
            ? true
            : UserDefaults.standard.bool(forKey: PrefKey.sameWallpaperMode)
        let customPath = UserDefaults.standard.string(forKey: PrefKey.customWallpaperPath) ?? ""
        let matchingStyle = UserDefaults.standard.string(forKey: PrefKey.wallpaperMatchingStyle) ?? "Exact Mirror (1:1)"

        // 0. Translucent Mode: Pure frosted glass
        if wallpaperMode == "Translucent" {
            self.activeWallpaperImage = nil
            return
        }

        // 1. "Genie" / "1:1 Camouflage" Mode: ALWAYS load active macOS desktop wallpaper
        if wallpaperMode == "Genie" || wallpaperMode == "1:1 Camouflage" || sameWallpaper || matchingStyle == "Exact Mirror (1:1)" {
            if let img = resolveLiveSystemWallpaper() {
                self.activeWallpaperImage = img
                return
            }
        }

        // 2. Explicit User Chosen Custom Wallpaper (when not in sameWallpaperMode)
        if !customPath.isEmpty, FileManager.default.fileExists(atPath: customPath) {
            lastLoadedPath = customPath
            if let img = NSImage(contentsOfFile: customPath) {
                self.activeWallpaperImage = img
                return
            }
        }

        // 3. Curated 4K Wallpaper (when not in sameWallpaperMode)
        if !sameWallpaper && matchingStyle != "Exact Mirror (1:1)" {
            let img = generateCuratedWallpaper(named: matchingStyle, targetSize: CGSize(width: 3840, height: 2160))
            self.activeWallpaperImage = img
            return
        }

        // 4. Live System Desktop Wallpaper Fallback
        if let img = resolveLiveSystemWallpaper() {
            self.activeWallpaperImage = img
            return
        }
    }

    func chooseCustomWallpaper(completion: @escaping (String) -> Void) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedContentTypes = [.image, .jpeg, .png, .heic]
        panel.title = "Select Desktop Wallpaper"
        panel.message = "Choose an ultra-high resolution image for your desktop wallpaper."
        panel.level = NSWindow.Level(rawValue: max(NSWindow.Level.statusBar.rawValue, NSApp.keyWindow?.level.rawValue ?? 0) + 10)
        NSApp.activate(ignoringOtherApps: true)
        panel.center()
        panel.orderFrontRegardless()

        if panel.runModal() == .OK, let url = panel.url {
            completion(url.path)
            setSystemWallpaper(path: url.path)
        }
    }

    // MARK: - 🖼️ Desktop Wallpaper Mutator & Setter
    @discardableResult
    public func setSystemWallpaper(path: String) -> Bool {
        let fileURL = URL(fileURLWithPath: path)
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return false }

        let screens = NSScreen.screens
        var success = false
        for screen in screens {
            do {
                try NSWorkspace.shared.setDesktopImageURL(fileURL, for: screen, options: [:])
                success = true
            } catch {
                print("Failed to set desktop image for screen: \(error)")
            }
        }

        UserDefaults.standard.set(path, forKey: PrefKey.customWallpaperPath)
        UserDefaults.standard.set(false, forKey: PrefKey.sameWallpaperMode)
        UserDefaults.standard.set("Custom", forKey: PrefKey.wallpaperMode)

        self.refresh()
        NotificationCenter.default.post(name: NSNotification.Name("NexusWallpaperChanged"), object: path)
        HapticFeedback.playClickSound()
        return success
    }

    @discardableResult
    public func setSystemWallpaper(named name: String) -> Bool {
        if let match = availableWallpapers.first(where: {
            $0.name.lowercased().contains(name.lowercased()) ||
            $0.id.lowercased().contains(name.lowercased())
        }) {
            return setSystemWallpaper(path: match.path)
        }
        if let bundled = findBundledWallpaperPath(named: name) {
            return setSystemWallpaper(path: bundled)
        }
        return false
    }

    func generateCuratedWallpaper(named name: String, targetSize: CGSize = CGSize(width: 480, height: 270)) -> NSImage {
        let key = "curated_\(name)_\(Int(targetSize.width))x\(Int(targetSize.height))" as NSString
        if let cached = thumbnailCache.object(forKey: key) {
            return cached
        }

        // Return real photo asset if matching Golden Gate or Apple names
        if name.contains("Golden") || name.contains("Gate") {
            if let img = loadBundledWallpaper(named: "GoldenGateSunset") ?? loadBundledWallpaper(named: "GoldenGateDynamic") ?? loadBundledWallpaper(named: "GoldenGateAerial4K") {
                thumbnailCache.setObject(img, forKey: key)
                return img
            }
        }
        if name.contains("Sequoia") || name.contains("Sonoma") {
            if let img = loadBundledWallpaper(named: "SonomaHorizon") ?? loadBundledWallpaper(named: "Sonoma") {
                thumbnailCache.setObject(img, forKey: key)
                return img
            }
        }

        let size = targetSize
        let img = NSImage(size: size)
        img.lockFocus()

        let bounds = CGRect(origin: .zero, size: size)
        let ctx = NSGraphicsContext.current?.cgContext
        ctx?.setAllowsAntialiasing(true)
        ctx?.setShouldAntialias(true)
        ctx?.interpolationQuality = .high

        switch name {
        case "Genie", "Genie Cosmic Spirit", "Genie Lamp":
            let colors = [
                NSColor(red: 0.02, green: 0.04, blue: 0.12, alpha: 1.0).cgColor,
                NSColor(red: 0.08, green: 0.18, blue: 0.45, alpha: 1.0).cgColor,
                NSColor(red: 0.0, green: 0.85, blue: 0.95, alpha: 1.0).cgColor,
                NSColor(red: 1.0, green: 0.72, blue: 0.20, alpha: 1.0).cgColor
            ]
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0.0, 0.45, 0.82, 1.0]) {
                ctx?.drawRadialGradient(gradient, startCenter: CGPoint(x: size.width * 0.5, y: size.height * 0.35), startRadius: 100, endCenter: CGPoint(x: size.width * 0.5, y: size.height * 0.5), endRadius: size.width * 0.75, options: [])
            }

        case "Sequoia Dark", "Sequoia Dark Horizon":
            let colors = [NSColor(red: 0.05, green: 0.08, blue: 0.15, alpha: 1.0).cgColor, NSColor(red: 0.12, green: 0.18, blue: 0.28, alpha: 1.0).cgColor]
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0.0, 1.0]) {
                ctx?.drawLinearGradient(gradient, start: CGPoint(x: 0, y: size.height), end: CGPoint(x: 0, y: 0), options: [])
            }

        case "Genie Sunset", "Golden Sunset", "Golden Gate Sunset":
            let colors = [
                NSColor(red: 0.15, green: 0.05, blue: 0.20, alpha: 1.0).cgColor,
                NSColor(red: 0.85, green: 0.25, blue: 0.35, alpha: 1.0).cgColor,
                NSColor(red: 1.0, green: 0.65, blue: 0.15, alpha: 1.0).cgColor
            ]
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0.0, 0.5, 1.0]) {
                ctx?.drawLinearGradient(gradient, start: CGPoint(x: 0, y: size.height), end: CGPoint(x: 0, y: 0), options: [])
            }

        case "Cosmic Nebula", "Deep Space Nebula":
            let colors = [
                NSColor(red: 0.02, green: 0.01, blue: 0.08, alpha: 1.0).cgColor,
                NSColor(red: 0.25, green: 0.05, blue: 0.45, alpha: 1.0).cgColor,
                NSColor(red: 0.05, green: 0.15, blue: 0.35, alpha: 1.0).cgColor
            ]
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0.0, 0.6, 1.0]) {
                ctx?.drawRadialGradient(gradient, startCenter: CGPoint(x: size.width * 0.5, y: size.height * 0.5), startRadius: 50, endCenter: CGPoint(x: size.width * 0.5, y: size.height * 0.5), endRadius: size.width * 0.7, options: [])
            }

        case "Cyber Grid", "Cyberpunk Neon Grid":
            NSColor(red: 0.03, green: 0.02, blue: 0.08, alpha: 1.0).setFill()
            bounds.fill()
            let gridCol = NSColor(red: 0.0, green: 0.85, blue: 0.95, alpha: 0.35)
            gridCol.setStroke()
            let gridStep = max(15.0, 60.0 * (size.width / 1920.0))
            for x in stride(from: 0, to: size.width, by: gridStep) {
                let p = NSBezierPath()
                p.move(to: CGPoint(x: x, y: 0))
                p.line(to: CGPoint(x: x, y: size.height))
                p.lineWidth = 1.0
                p.stroke()
            }
            for y in stride(from: 0, to: size.height, by: gridStep) {
                let p = NSBezierPath()
                p.move(to: CGPoint(x: 0, y: y))
                p.line(to: CGPoint(x: size.width, y: y))
                p.lineWidth = 1.0
                p.stroke()
            }

        case "Ocean Caustics", "4K Blue Ocean Wave":
            let colors = [
                NSColor(red: 0.01, green: 0.15, blue: 0.35, alpha: 1.0).cgColor,
                NSColor(red: 0.02, green: 0.45, blue: 0.65, alpha: 1.0).cgColor,
                NSColor(red: 0.10, green: 0.75, blue: 0.85, alpha: 1.0).cgColor
            ]
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0.0, 0.6, 1.0]) {
                ctx?.drawLinearGradient(gradient, start: CGPoint(x: 0, y: size.height), end: CGPoint(x: size.width, y: 0), options: [])
            }

        case "Tokyo Neon", "Midnight Cyber Tokyo":
            let colors = [
                NSColor(red: 0.05, green: 0.02, blue: 0.12, alpha: 1.0).cgColor,
                NSColor(red: 0.75, green: 0.05, blue: 0.45, alpha: 1.0).cgColor,
                NSColor(red: 0.05, green: 0.70, blue: 0.90, alpha: 1.0).cgColor
            ]
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0.0, 0.5, 1.0]) {
                ctx?.drawLinearGradient(gradient, start: CGPoint(x: 0, y: 0), end: CGPoint(x: size.width, y: size.height), options: [])
            }

        case "Emerald Forest", "Deep Redwood Canopy":
            let colors = [
                NSColor(red: 0.02, green: 0.08, blue: 0.04, alpha: 1.0).cgColor,
                NSColor(red: 0.08, green: 0.32, blue: 0.16, alpha: 1.0).cgColor,
                NSColor(red: 0.18, green: 0.55, blue: 0.28, alpha: 1.0).cgColor
            ]
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0.0, 0.5, 1.0]) {
                ctx?.drawLinearGradient(gradient, start: CGPoint(x: 0, y: size.height), end: CGPoint(x: 0, y: 0), options: [])
            }

        case "Matrix Digital", "Phosphor Digital Stream":
            NSColor(red: 0.01, green: 0.04, blue: 0.02, alpha: 1.0).setFill()
            bounds.fill()
            let greenCol = NSColor(red: 0.0, green: 0.95, blue: 0.35, alpha: 0.40)
            greenCol.setStroke()
            for x in stride(from: 20, to: size.width, by: 40) {
                let p = NSBezierPath()
                p.move(to: CGPoint(x: x, y: 0))
                p.line(to: CGPoint(x: x, y: size.height))
                p.lineWidth = 1.5
                p.stroke()
            }

        default:
            let colors = [NSColor(red: 0.08, green: 0.10, blue: 0.18, alpha: 1.0).cgColor, NSColor(red: 0.02, green: 0.04, blue: 0.08, alpha: 1.0).cgColor]
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors as CFArray, locations: [0.0, 1.0]) {
                ctx?.drawLinearGradient(gradient, start: CGPoint(x: 0, y: size.height), end: CGPoint(x: 0, y: 0), options: [])
            }
        }

        img.unlockFocus()
        thumbnailCache.setObject(img, forKey: key)
        return img
    }

    deinit {
        refreshTimer?.invalidate()
    }
}
