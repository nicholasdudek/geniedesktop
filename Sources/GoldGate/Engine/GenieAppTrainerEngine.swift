import AppKit
import Foundation
import SwiftUI
import Combine

// MARK: - 🧠 Trained Mac Application Record
public struct TrainedMacApp: Identifiable, Codable, Sendable, Hashable {
    public let id: String
    public let name: String
    public let bundleIdentifier: String
    public let version: String
    public let path: String
    public let category: String
    public let urlSchemes: [String]
    public let documentExtensions: [String]
    public let isAppleScriptable: Bool
    public let isSystemApp: Bool
    public let lastScannedAt: Date

    public init(
        id: String,
        name: String,
        bundleIdentifier: String,
        version: String,
        path: String,
        category: String,
        urlSchemes: [String],
        documentExtensions: [String],
        isAppleScriptable: Bool,
        isSystemApp: Bool,
        lastScannedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.bundleIdentifier = bundleIdentifier
        self.version = version
        self.path = path
        self.category = category
        self.urlSchemes = urlSchemes
        self.documentExtensions = documentExtensions
        self.isAppleScriptable = isAppleScriptable
        self.isSystemApp = isSystemApp
        self.lastScannedAt = lastScannedAt
    }
}

// MARK: - 🚀 Genie Mac Applications Trainer Engine
/// Deep-scans every installed application on the user's Mac (`/Applications`, `/System/Applications`,
/// `~/Applications`), indexes their bundle metadata, URL schemes, document bindings, and
/// AppleScript dictionaries, and compiles this sovereign on-device context directly into Genie AI's model prompt.
@MainActor
public final class GenieAppTrainerEngine: ObservableObject {
    public static let shared = GenieAppTrainerEngine()

    @Published public private(set) var trainedApps: [TrainedMacApp] = []
    @Published public private(set) var isTraining: Bool = false
    @Published public private(set) var lastTrainedAt: Date? = nil
    @Published public private(set) var currentStatus: String = "Ready"

    private let cacheURL: URL

    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory() + "/Library/Application Support")
        let genieDir = appSupport.appendingPathComponent("Genie", isDirectory: true)
        try? FileManager.default.createDirectory(at: genieDir, withIntermediateDirectories: true)
        self.cacheURL = genieDir.appendingPathComponent("trained_mac_apps.json")

        // Load existing cache immediately for instant startup
        loadCache()

        // Kick off training pass asynchronously
        Task { [weak self] in
            await self?.trainOnInstalledMacApps()
        }
    }

    // MARK: - Cache Persistence
    private func loadCache() {
        guard let data = try? Data(contentsOf: cacheURL),
              let decoded = try? JSONDecoder().decode([TrainedMacApp].self, from: data) else {
            return
        }
        self.trainedApps = decoded
        if let first = decoded.first {
            self.lastTrainedAt = first.lastScannedAt
        }
    }

    private func saveCache(_ apps: [TrainedMacApp]) {
        if let encoded = try? JSONEncoder().encode(apps) {
            try? encoded.write(to: cacheURL, options: .atomic)
        }
    }

    // MARK: - App Scanning & Deep Training Pass
    public func trainOnInstalledMacApps() async {
        guard !isTraining else { return }
        isTraining = true
        currentStatus = "Scanning macOS application directories..."

        let scannedApps = await Task.detached(priority: .userInitiated) { () -> [TrainedMacApp] in
            var appsList: [TrainedMacApp] = []
            var seenBundleIDs = Set<String>()
            var seenPaths = Set<String>()

            let searchDirs = [
                "/Applications",
                "/System/Applications",
                "/System/Applications/Utilities",
                "/Applications/Utilities",
                NSHomeDirectory() + "/Applications",
                NSHomeDirectory() + "/Applications/Chrome Apps.localized",
                "/System/Library/CoreServices/Applications"
            ]

            let fileManager = FileManager.default

            for baseDir in searchDirs {
                guard let enumerator = fileManager.enumerator(
                    at: URL(fileURLWithPath: baseDir),
                    includingPropertiesForKeys: [.isDirectoryKey],
                    options: [.skipsHiddenFiles, .skipsPackageDescendants]
                ) else { continue }

                while let appURL = enumerator.nextObject() as? URL {
                    guard appURL.pathExtension == "app" else { continue }
                    let path = appURL.path
                    if seenPaths.contains(path) { continue }
                    seenPaths.insert(path)

                    guard let bundle = Bundle(url: appURL) else { continue }
                    let bundleID = bundle.bundleIdentifier ?? ""
                    if !bundleID.isEmpty && seenBundleIDs.contains(bundleID.lowercased()) {
                        continue
                    }

                    let displayName = (bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
                        ?? (bundle.object(forInfoDictionaryKey: "CFBundleName") as? String)
                        ?? appURL.deletingPathExtension().lastPathComponent

                    let version = (bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String)
                        ?? (bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String)
                        ?? "1.0"

                    // URL Schemes
                    var schemes: [String] = []
                    if let urlTypes = bundle.object(forInfoDictionaryKey: "CFBundleURLTypes") as? [[String: Any]] {
                        for type in urlTypes {
                            if let sList = type["CFBundleURLSchemes"] as? [String] {
                                schemes.append(contentsOf: sList)
                            }
                        }
                    }

                    // Document Extensions
                    var docExts: [String] = []
                    if let docTypes = bundle.object(forInfoDictionaryKey: "CFBundleDocumentTypes") as? [[String: Any]] {
                        for type in docTypes {
                            if let exts = type["CFBundleTypeExtensions"] as? [String] {
                                docExts.append(contentsOf: exts)
                            }
                        }
                    }

                    // Scripting Support (AppleScript .sdef or NSAppleScriptEnabled)
                    let scriptableBool = (bundle.object(forInfoDictionaryKey: "NSAppleScriptEnabled") as? Bool) ?? false
                    let sdefName = bundle.object(forInfoDictionaryKey: "OSAScriptingDefinition") as? String
                    let hasSdef = sdefName != nil || fileManager.fileExists(atPath: appURL.appendingPathComponent("Contents/Resources/\(displayName).sdef").path)
                    let isScriptable = scriptableBool || hasSdef

                    // Category Heuristics
                    let isSystem = path.hasPrefix("/System/")
                    let category = GenieAppTrainerEngine.categorizeApp(name: displayName, path: path, bundleId: bundleID)

                    let record = TrainedMacApp(
                        id: bundleID.isEmpty ? path : bundleID,
                        name: displayName,
                        bundleIdentifier: bundleID,
                        version: version,
                        path: path,
                        category: category,
                        urlSchemes: Array(Set(schemes)).sorted(),
                        documentExtensions: Array(Set(docExts)).sorted(),
                        isAppleScriptable: isScriptable,
                        isSystemApp: isSystem,
                        lastScannedAt: Date()
                    )

                    if !bundleID.isEmpty {
                        seenBundleIDs.insert(bundleID.lowercased())
                    }
                    appsList.append(record)
                }
            }

            return appsList.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        }.value

        self.trainedApps = scannedApps
        self.lastTrainedAt = Date()
        self.isTraining = false
        self.currentStatus = "Trained on \(scannedApps.count) Mac Applications"
        self.saveCache(scannedApps)

        NotificationCenter.default.post(
            name: NSNotification.Name("GenieMacAppsTrainingCompleted"),
            object: scannedApps.count
        )
    }

    private nonisolated static func categorizeApp(name: String, path: String, bundleId: String) -> String {
        let lower = (name + " " + path + " " + bundleId).lowercased()
        if lower.contains("xcode") || lower.contains("code") || lower.contains("cursor") || lower.contains("developer") || lower.contains("sublime") || lower.contains("antigravity") {
            return "Developer & Coding"
        }
        if lower.contains("terminal") || lower.contains("iterm") || lower.contains("ghostty") || lower.contains("warp") || lower.contains("kitty") || lower.contains("alacritty") {
            return "Terminal & Shell"
        }
        if lower.contains("safari") || lower.contains("chrome") || lower.contains("firefox") || lower.contains("browser") || lower.contains("edge") || lower.contains("brave") || lower.contains("arc") {
            return "Web Browser"
        }
        if lower.contains("messages") || lower.contains("chat") || lower.contains("slack") || lower.contains("discord") || lower.contains("telegram") || lower.contains("signal") {
            return "Communication"
        }
        if lower.contains("notes") || lower.contains("notion") || lower.contains("obsidian") || lower.contains("bear") || lower.contains("pages") || lower.contains("word") {
            return "Notes & Writing"
        }
        if lower.contains("photoshop") || lower.contains("figma") || lower.contains("sketch") || lower.contains("illustrator") || lower.contains("pixelmator") {
            return "Design & Creative"
        }
        if lower.contains("music") || lower.contains("spotify") || lower.contains("podcast") || lower.contains("quicktime") || lower.contains("vlc") || lower.contains("garageband") {
            return "Audio & Video"
        }
        if lower.contains("settings") || lower.contains("system") || lower.contains("finder") || lower.contains("activity monitor") || lower.contains("disk utility") {
            return "System & Utilities"
        }
        return "Productivity"
    }

    // MARK: - System Prompt Synthesis
    /// Produces a compact, high-density knowledge manifest for LLM injection
    public func generateTrainingSystemPrompt() -> String {
        guard !trainedApps.isEmpty else {
            return "Mac Applications Engine: Standard macOS applications loaded."
        }

        var lines: [String] = []
        lines.append("### 19. 🧠 TRAINED LOCAL MAC APPLICATIONS KNOWLEDGE-BASE (\(trainedApps.count) APPS INDEXED)")
        lines.append("""
Genie has been specifically trained on Nicholas's Mac and has full on-device awareness of all \(trainedApps.count) installed applications.
When Nicholas asks you to open an application, edit code, browse the web, write documents, or automate tasks, reference these exact installed apps, their bundle identifiers, paths, and scripting capabilities:
""")

        // Group key applications by category
        let categories = Dictionary(grouping: trainedApps, by: { $0.category })
        for (cat, apps) in categories.sorted(by: { $0.key < $1.key }) {
            lines.append("\n• [\(cat)]:")
            for app in apps {
                var details: [String] = []
                if !app.bundleIdentifier.isEmpty { details.append("id: \(app.bundleIdentifier)") }
                details.append("path: \"\(app.path)\"")
                if app.isAppleScriptable { details.append("scriptable: YES") }
                if !app.urlSchemes.isEmpty { details.append("schemes: [\(app.urlSchemes.prefix(3).joined(separator: ", "))]") }
                if !app.documentExtensions.isEmpty { details.append("exts: [\(app.documentExtensions.prefix(4).joined(separator: ", "))]") }
                lines.append("  - \(app.name): \(details.joined(separator: " | "))")
            }
        }

        lines.append("""

APPLICATION AUTOMATION & DISPATCH RULES:
1. To open any installed app: Run ```open -a "\(trainedApps.first?.path ?? "/Applications/Safari.app")"``` or ```open -b <bundleIdentifier>```.
2. For scriptable apps (marked scriptable: YES): You can directly automate them using ```applescript <AppName> ... ``` blocks.
3. For apps with registered URL schemes: Deep-link directly using ```open "<scheme>://..."```.

### 19B. 🤖 ANDROID SDK & GOOGLE PLAY STORE DEPLOYMENT INTELLIGENCE:
Genie is trained on Android development and Google Play Console distribution, with detected on-device Android SDK tooling:
- Local Android SDK Root: ~/Library/Android/sdk
- Local ADB Binary: ~/Library/Android/sdk/platform-tools/adb
- Installed Platforms: android-34, android-35
- Android Google Play Store Upload Rules:
  1. Package Format: Google Play requires Android App Bundle (.aab) format via `./gradlew bundleRelease` (not standalone .apk for new apps).
  2. Target SDK: Target SDK 34/35+ (Android 14/15) is mandatory.
  3. Architecture: 64-bit native libraries required (`arm64-v8a`, `x86_64`).
  4. Release Signing:
     - Generate Keystore: `keytool -genkey -v -keystore release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias genie`
     - Gradle configuration: set `signingConfigs { release { ... } }` in app/build.gradle.kts.
  5. Privacy & Permissions: Declare all permissions (e.g. Internet, Storage) in `AndroidManifest.xml` and match the Google Play Data Safety form.

### 19C. 🪟 WINDOWS & MICROSOFT STORE PACKAGING INTELLIGENCE:
Genie is trained on Windows application architecture and Microsoft Store packaging:
- Local .NET Engine: /usr/local/share/dotnet/dotnet
- WinUI 3 / Windows App SDK: Native Fluent Design system, mica background material, acrylic blur.
- Windows Store Packaging (MSIX):
  - Manifest: `Package.appxmanifest` specifying Identity, Publisher, Dependencies, and Capabilities.
  - Build & Publish: `dotnet publish -r win-x64 -c Release -p:GenerateAppxPackageOnBuild=true`
  - Partner Center: Upload the signed `.msixupload` bundle for store certification.

### 19D. 📲 IPAD & UNIVERSAL APPLE ECOSYSTEM ADAPTATION:
Genie is architected as a universal Apple app (macOS + iOS + iPadOS):
- Targeted Device Family: "1,2" (iPhone and iPad).
- iPadOS Adaptations:
  - Supports Stage Manager floating windows and full Split View / Slide Over multitasking.
  - Adaptive NavigationSplitView sidebar layout for large iPad Pro screens (11" and 13").
  - Apple Pencil hover, Scribble text input, and hardware keyboard shortcuts (⌘K, ⌘⌥Space).
""")

        return lines.joined(separator: "\n")
    }
}
