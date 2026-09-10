import AppKit
import SwiftUI

// MARK: - Pinned Dock Folder Stack Item (Downloads, Documents, Applications, etc.)
public struct DockFolderItem: Identifiable, Equatable {
    public let id: String
    public let name: String
    public let folderURL: URL
    public let icon: NSImage?

    public init(id: String, name: String, folderURL: URL, icon: NSImage? = nil) {
        self.id = id
        self.name = name
        self.folderURL = folderURL
        self.icon = icon ?? NSWorkspace.shared.icon(forFile: folderURL.path)
    }

    public static func == (lhs: DockFolderItem, rhs: DockFolderItem) -> Bool {
        lhs.id == rhs.id && lhs.folderURL == rhs.folderURL
    }

    @MainActor
    public func openInFinder() {
        NSWorkspace.shared.open(folderURL)
    }
}

@MainActor
public final class DockAndDesktopManager: ObservableObject {
    public static let shared = DockAndDesktopManager()

    // MARK: - Central Unified Dock State (Shared Across All Screens & Windows)
    @Published public var dockItems: [DockAppItem] = []
    @Published public var dockFolders: [DockFolderItem] = []
    @Published public var activePid: pid_t = NSWorkspace.shared.frontmostApplication?.processIdentifier ?? 0
    private var isObserversSetup: Bool = false
    private var hygieneTimer: Timer? = nil

    @Published public var isDockIconEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isDockIconEnabled, forKey: PrefKey.showInDock)
            applyDockActivationPolicy()
        }
    }

    @Published public var isDesktopIconCreated: Bool = false
    @Published public var isHomeIconCreated: Bool = false

    private init() {
        let savedDock = UserDefaults.standard.object(forKey: PrefKey.showInDock) != nil ? UserDefaults.standard.bool(forKey: PrefKey.showInDock) : true
        self.isDockIconEnabled = savedDock
        checkExistingShortcuts()
    }

    public func setup() {
        applyDockActivationPolicy()
        checkExistingShortcuts()
        setupDockObservers()
        refreshDockApps()
    }

    // MARK: - Activation Policy (Dock Show / Hide)

    public func applyDockActivationPolicy() {
        if isDockIconEnabled {
            NSApp.setActivationPolicy(.regular)
        } else {
            NSApp.setActivationPolicy(.accessory)
        }
    }

    // MARK: - Shared Dock Observers & Centralized Life Cycle

    public func setupDockObservers() {
        guard !isObserversSetup else { return }
        isObserversSetup = true

        let ws = NSWorkspace.shared.notificationCenter
        ws.addObserver(forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main) { [weak self] notif in
            Task { @MainActor in
                if let app = notif.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                    self?.activePid = app.processIdentifier
                } else {
                    self?.activePid = NSWorkspace.shared.frontmostApplication?.processIdentifier ?? 0
                }
            }
        }

        ws.addObserver(forName: NSWorkspace.didLaunchApplicationNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                self?.refreshDockApps()
            }
        }

        ws.addObserver(forName: NSWorkspace.didTerminateApplicationNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                self?.refreshDockApps()
            }
        }

        NotificationCenter.default.addObserver(forName: NSNotification.Name("NexusDockHiddenAppsChanged"), object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                self?.refreshDockApps()
            }
        }

        NotificationCenter.default.addObserver(forName: NSNotification.Name("NexusDockActiveAppsOnlyChanged"), object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                self?.refreshDockApps()
            }
        }

        NotificationCenter.default.addObserver(forName: NSNotification.Name("NexusDockTrashChanged"), object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                self?.refreshDockApps()
            }
        }

        NotificationCenter.default.addObserver(forName: NSNotification.Name("NexusDockShowFolderStacksChanged"), object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                self?.refreshDockApps()
            }
        }

        NotificationCenter.default.addObserver(forName: NSNotification.Name("NexusDockAlwaysShowFinderChanged"), object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                self?.refreshDockApps()
            }
        }

        NotificationCenter.default.addObserver(forName: NSNotification.Name("NexusDockAlwaysShowSettingsChanged"), object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor in
                self?.refreshDockApps()
            }
        }

        hygieneTimer?.invalidate()
        hygieneTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self else { return }
                let hasTerminated = self.dockItems.contains(where: { $0.runningApp?.isTerminated == true })
                if hasTerminated {
                    self.refreshDockApps()
                }
            }
        }
    }

    // MARK: - Loading & Deduplicating System Dock Apps

    public static func loadSystemDockApps() -> [DockAppItem] {
        var items: [DockAppItem] = []
        let fm = FileManager.default

        let dockDict: [[String: Any]] = {
            var all: [[String: Any]] = []
            if let suite = UserDefaults(suiteName: "com.apple.dock") {
                if let apps = suite.array(forKey: "persistent-apps") as? [[String: Any]] {
                    all.append(contentsOf: apps)
                }
                if let recents = suite.array(forKey: "recent-apps") as? [[String: Any]] {
                    all.append(contentsOf: recents)
                }
            }
            if all.isEmpty, let dict = NSDictionary(contentsOf: URL(fileURLWithPath: NSHomeDirectory() + "/Library/Preferences/com.apple.dock.plist")) {
                if let apps = dict["persistent-apps"] as? [[String: Any]] {
                    all.append(contentsOf: apps)
                }
                if let recents = dict["recent-apps"] as? [[String: Any]] {
                    all.append(contentsOf: recents)
                }
            }
            return all
        }()

        for entry in dockDict {
            guard let tileData = entry["tile-data"] as? [String: Any] else { continue }
            let bundleId = (tileData["bundle-identifier"] as? String) ?? ""
            let label = (tileData["file-label"] as? String) ?? (bundleId.isEmpty ? "App" : bundleId)

            var bundleURL: URL? = nil
            if let fileData = tileData["file-data"] as? [String: Any],
               let urlString = fileData["_CFURLString"] as? String {
                bundleURL = URL(string: urlString)
            }
            if bundleURL == nil && !bundleId.isEmpty {
                bundleURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId)
            }
            if bundleURL == nil || !fm.fileExists(atPath: bundleURL!.path) {
                if !bundleId.isEmpty, let resolved = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
                    bundleURL = resolved
                } else if !label.isEmpty {
                    let candidates = [
                        "/Applications/\(label).app",
                        "/System/Applications/\(label).app",
                        "/System/Applications/Utilities/\(label).app",
                        "/System/Volumes/Preboot/Cryptexes/App/System/Applications/\(label).app"
                    ]
                    for cand in candidates {
                        if fm.fileExists(atPath: cand) {
                            bundleURL = URL(fileURLWithPath: cand)
                            break
                        }
                    }
                }
            }

            let icon: NSImage? = {
                if let path = bundleURL?.path, fm.fileExists(atPath: path) {
                    return AppModel.highestQualityIcon(for: path)
                }
                if !bundleId.isEmpty, let u = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
                    return AppModel.highestQualityIcon(for: u.path)
                }
                return nil
            }()

            // Skip Trash entries so Trash is uniquely rendered by trashDockItemView
            let lowerLabel = label.lowercased()
            let lowerBid = bundleId.lowercased()
            if lowerLabel == "trash" || lowerLabel == "corbeille" || lowerLabel == "bin" || lowerBid.contains("trash") || (bundleURL?.path.contains(".Trash") == true) {
                continue
            }

            let id = bundleId.isEmpty ? label : bundleId
            let newItem = DockAppItem(
                id: id,
                name: label,
                bundleURL: bundleURL,
                bundleIdentifier: bundleId.isEmpty ? nil : bundleId,
                icon: icon,
                runningApp: nil
            )
            if !items.contains(where: { $0.representsSameApplication(as: newItem) }) {
                items.append(newItem)
            }
        }

        return items
    }

    // MARK: - Loading System Dock Folder Stacks (Downloads, Documents, Applications, etc.)

    public static func loadSystemDockFolders() -> [DockFolderItem] {
        var folders: [DockFolderItem] = []

        let othersDict: [[String: Any]] = {
            var all: [[String: Any]] = []
            if let suite = UserDefaults(suiteName: "com.apple.dock") {
                if let others = suite.array(forKey: "persistent-others") as? [[String: Any]] {
                    all.append(contentsOf: others)
                }
            }
            if all.isEmpty, let dict = NSDictionary(contentsOf: URL(fileURLWithPath: NSHomeDirectory() + "/Library/Preferences/com.apple.dock.plist")) {
                if let others = dict["persistent-others"] as? [[String: Any]] {
                    all.append(contentsOf: others)
                }
            }
            return all
        }()

        for entry in othersDict {
            guard let tileData = entry["tile-data"] as? [String: Any] else { continue }
            let label = (tileData["file-label"] as? String) ?? "Folder"
            let lowerLabel = label.lowercased()
            if lowerLabel == "trash" || lowerLabel == "bin" || lowerLabel == "corbeille" {
                continue
            }

            var folderURL: URL? = nil
            if let fileData = tileData["file-data"] as? [String: Any],
               let urlString = fileData["_CFURLString"] as? String {
                folderURL = URL(string: urlString)
            }
            if let u = folderURL {
                if u.path.contains(".Trash") || u.path.hasSuffix("/Trash") {
                    continue
                }
                let icon: NSImage = {
                    if FileManager.default.fileExists(atPath: u.path) {
                        return AppModel.highestQualityIcon(for: u.path)
                    }
                    let iconSymbol = label.lowercased().contains("download") ? "arrow.down.circle.fill" : (label.lowercased().contains("doc") ? "doc.fill" : "folder.fill")
                    let conf = NSImage.SymbolConfiguration(pointSize: 22, weight: .regular)
                    return NSImage(systemSymbolName: iconSymbol, accessibilityDescription: label)?.withSymbolConfiguration(conf) ?? NSImage()
                }()
                let item = DockFolderItem(id: u.path, name: label, folderURL: u, icon: icon)
                if !folders.contains(where: { $0.id == item.id }) {
                    folders.append(item)
                }
            }
        }

        // Default standard macOS folder stacks if none parsed
        if folders.isEmpty {
            let defaults: [(path: String, name: String)] = [
                (NSHomeDirectory() + "/Downloads", "Downloads"),
                (NSHomeDirectory() + "/Documents", "Documents"),
                ("/Applications", "Applications")
            ]
            for d in defaults {
                let u = URL(fileURLWithPath: d.path)
                let icon = AppModel.highestQualityIcon(for: d.path)
                folders.append(DockFolderItem(id: d.path, name: d.name, folderURL: u, icon: icon))
            }
        }

        return folders
    }

    public func refreshDockApps() {
        self.dockFolders = Self.loadSystemDockFolders()
        let myPid = ProcessInfo.processInfo.processIdentifier
        let currentApps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular && $0.processIdentifier != myPid && !$0.isTerminated }

        let dockAlwaysShowFinder = UserDefaults.standard.object(forKey: PrefKey.dockAlwaysShowFinder) as? Bool ?? true
        let dockAlwaysShowGenie = UserDefaults.standard.object(forKey: PrefKey.dockAlwaysShowGenie) as? Bool ?? true
        let dockAlwaysShowSettings = UserDefaults.standard.object(forKey: PrefKey.dockAlwaysShowSettings) as? Bool ?? true
        let hiddenBundleIDs = UserDefaults.standard.stringArray(forKey: PrefKey.hiddenDockBundleIDs) ?? []

        var result: [DockAppItem] = []

        // 1. Finder (Always #1 on macOS Dock)
        if dockAlwaysShowFinder {
            let finderApp = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.finder").first
            let finderURL = URL(fileURLWithPath: "/System/Library/CoreServices/Finder.app")
            let finderIcon = AppModel.highestQualityIcon(for: finderURL.path)
            result.append(DockAppItem(
                id: "com.apple.finder",
                name: "Finder",
                bundleURL: finderURL,
                bundleIdentifier: "com.apple.finder",
                icon: finderIcon,
                runningApp: finderApp
            ))
        }

        // 2. Sequential Dock Apps matching com.apple.dock.plist order
        let dockApps = Self.loadSystemDockApps()
        for dApp in dockApps {
            let key = dApp.bundleIdentifier ?? dApp.id
            if hiddenBundleIDs.contains(key) { continue }

            var item = dApp
            if let running = currentApps.first(where: {
                DockAppItem.isSameApplication(
                    bidA: $0.bundleIdentifier, nameA: $0.localizedName, urlA: $0.bundleURL,
                    bidB: dApp.bundleIdentifier, nameB: dApp.name, urlB: dApp.bundleURL
                )
            }) {
                item.runningApp = running
            } else {
                item.runningApp = nil
            }
            if !result.contains(where: { $0.representsSameApplication(as: item) }) {
                result.append(item)
            }
        }

        // 2b. Genie Anchor (Appended if enabled and not already pinned in Dock)
        if dockAlwaysShowGenie && !result.contains(where: { $0.bundleIdentifier == "com.nicholasdudek.genie" || $0.id == "com.nicholasdudek.genie" || $0.name.lowercased() == "genie" }) {
            let genieIcon: NSImage? = {
                // Prefer the large 512×512 PNG asset from the dev build for maximum quality
                let devIconURL = URL(fileURLWithPath: "/Users/nicholasdudek/Developer/GoldGate/Sources/GoldGate/Assets.xcassets/AppIcon.appiconset/icon_512x512.png")
                if FileManager.default.fileExists(atPath: devIconURL.path), let img = NSImage(contentsOf: devIconURL) {
                    return img  // keep at native 512×512 — SwiftUI frame will scale it
                }
                if let appIcon = NSApp.applicationIconImage {
                    return appIcon  // system-provided, already high-res
                }
                return AppModel.highestQualityIcon(for: Bundle.main.bundlePath)
            }()
            result.append(DockAppItem(
                id: "com.nicholasdudek.genie",
                name: "Genie",
                bundleURL: Bundle.main.bundleURL,
                bundleIdentifier: "com.nicholasdudek.genie",
                icon: genieIcon,
                runningApp: NSRunningApplication.current
            ))
        }

        // 3. Active running applications not already pinned in Dock
        for app in currentApps {
            let bid = app.bundleIdentifier
            let name = app.localizedName ?? "App"
            if bid == "com.apple.finder" || bid == "com.nicholasdudek.genie" { continue }
            let lowerName = name.lowercased()
            if lowerName.contains("helper") || lowerName.contains("renderer") || lowerName.contains("crashpad") || lowerName == "genie" {
                continue
            }
            if let execPath = app.bundleURL?.path.lowercased(), execPath.contains("/genie") || execPath.contains("goldgate") {
                continue
            }
            let key = bid ?? name
            if hiddenBundleIDs.contains(key) { continue }

            let exists = result.contains(where: {
                DockAppItem.isSameApplication(
                    bidA: $0.bundleIdentifier, nameA: $0.name, urlA: $0.bundleURL,
                    bidB: bid, nameB: name, urlB: app.bundleURL
                )
            })
            if !exists {
                let icon: NSImage?
                if let bundlePath = app.bundleURL?.path {
                    icon = AppModel.highestQualityIcon(for: bundlePath)
                } else {
                    icon = app.icon
                }
                result.append(DockAppItem(
                    id: bid ?? name,
                    name: name,
                    bundleURL: app.bundleURL,
                    bundleIdentifier: bid,
                    icon: icon,
                    runningApp: app
                ))
            }
        }

        // 4. Fallbacks if needed
        if result.count <= 1 {
            let fallbacks: [(id: String, name: String, path: String)] = [
                ("com.apple.Safari", "Safari", "/System/Volumes/Preboot/Cryptexes/App/System/Applications/Safari.app"),
                ("com.apple.MobileSMS", "Messages", "/System/Applications/Messages.app"),
                ("com.apple.Notes", "Notes", "/System/Applications/Notes.app"),
                ("com.apple.Terminal", "Terminal", "/System/Applications/Utilities/Terminal.app"),
                ("com.apple.systempreferences", "System Settings", "/System/Applications/System Settings.app")
            ]
            for fb in fallbacks {
                let url = URL(fileURLWithPath: fb.path)
                let icon = AppModel.highestQualityIcon(for: fb.path)
                let running = currentApps.first(where: { $0.bundleIdentifier == fb.id })
                let candidate = DockAppItem(
                    id: fb.id,
                    name: fb.name,
                    bundleURL: url,
                    bundleIdentifier: fb.id,
                    icon: icon,
                    runningApp: running
                )
                if !result.contains(where: { $0.representsSameApplication(as: candidate) }) {
                    result.append(candidate)
                }
            }
        }

        // 4b. Settings check
        if dockAlwaysShowSettings {
            let settingsURL = URL(fileURLWithPath: "/System/Applications/System Settings.app")
            let settingsApp = currentApps.first(where: { $0.bundleIdentifier == "com.apple.systempreferences" })
            let settingsItem = DockAppItem(
                id: "com.apple.systempreferences",
                name: "System Settings",
                bundleURL: settingsURL,
                bundleIdentifier: "com.apple.systempreferences",
                icon: AppModel.highestQualityIcon(for: settingsURL.path),
                runningApp: settingsApp
            )
            if !result.contains(where: { $0.representsSameApplication(as: settingsItem) }) {
                result.append(settingsItem)
            }
        }

        // Apply custom dock order if saved
        if let customOrder = UserDefaults.standard.stringArray(forKey: PrefKey.customDockAppOrder), !customOrder.isEmpty {
            var ordered: [DockAppItem] = []
            var remaining = result
            for id in customOrder {
                if let idx = remaining.firstIndex(where: { $0.id == id }) {
                    ordered.append(remaining.remove(at: idx))
                }
            }
            ordered.append(contentsOf: remaining)
            self.dockItems = ordered
        } else {
            self.dockItems = result
        }
    }

    public func reorder(fromIndex: Int, toIndex: Int) {
        guard fromIndex >= 0 && fromIndex < dockItems.count,
              toIndex >= 0 && toIndex < dockItems.count,
              fromIndex != toIndex else { return }
        let item = dockItems.remove(at: fromIndex)
        dockItems.insert(item, at: toIndex)
        saveCustomDockOrder()
    }

    public func removeDockItem(_ item: DockAppItem) {
        var hidden = UserDefaults.standard.stringArray(forKey: PrefKey.hiddenDockBundleIDs) ?? []
        let key = item.bundleIdentifier ?? item.id
        if !hidden.contains(key) {
            hidden.append(key)
        }
        UserDefaults.standard.set(hidden, forKey: PrefKey.hiddenDockBundleIDs)
        UserDefaults.standard.synchronize()
        NotificationCenter.default.post(name: NSNotification.Name("NexusDockHiddenAppsChanged"), object: nil)
        refreshDockApps()
    }

    public func restoreAllHiddenDockApps() {
        UserDefaults.standard.removeObject(forKey: PrefKey.hiddenDockBundleIDs)
        UserDefaults.standard.synchronize()
        NotificationCenter.default.post(name: NSNotification.Name("NexusDockHiddenAppsChanged"), object: nil)
        refreshDockApps()
    }

    public func saveCustomDockOrder() {
        let order = dockItems.map { $0.id }
        UserDefaults.standard.set(order, forKey: PrefKey.customDockAppOrder)
        let identifiers = dockItems.compactMap { item -> String? in
            item.bundleIdentifier ?? item.name
        }
        syncDockAppOrder(orderedIdentifiers: identifiers)
    }

    // MARK: - Persistent Dock Management ("Keep in Dock" / "Remove from Dock")

    private var primaryAppPath: String {
        let p0 = "/Applications/Genie.app"
        return p0
    }

    public func pinToMacOSDock() {
        let appPath = primaryAppPath
        guard FileManager.default.fileExists(atPath: appPath) else { return }
        guard GenieCapabilities.canModifySystemPreferenceDomains else { return }

        isDockIconEnabled = true
        GenieNativeSystem.addToDock(appPath: appPath)
    }

    public func removeFromMacOSDock() {
        guard GenieCapabilities.canModifySystemPreferenceDomains else { return }
        isDockIconEnabled = false

        // Was an inline `python3 -c` that rewrote com.apple.dock.plist behind
        // the Dock's back. CFPreferences is the supported path and needs no
        // subprocess; the name matching is unchanged.
        let needles = ["genie", "golden gate", "gold gate", "goldgate"]
        let apps = GenieNativeSystem.dockPersistentApps()
        let kept = apps.filter { entry in
            let haystack = Self.dockEntryHaystack(entry)
            return !needles.contains { haystack.contains($0) }
        }
        guard kept.count != apps.count else { return }
        GenieNativeSystem.setDockPersistentApps(kept)
    }

    /// Lowercased label + URL + bundle id of a Dock tile, for name matching.
    private static func dockEntryHaystack(_ entry: [String: Any]) -> String {
        guard let tile = entry["tile-data"] as? [String: Any] else { return "" }
        let label = (tile["file-label"] as? String) ?? ""
        let bundleID = (tile["bundle-identifier"] as? String) ?? ""
        let urlString = ((tile["file-data"] as? [String: Any])?["_CFURLString"] as? String) ?? ""
        return "\(label) \(bundleID) \(urlString)".lowercased()
    }

    // MARK: - Synchronize Mini Dock App Order to macOS System Dock
    public func syncDockAppOrder(orderedIdentifiers: [String]) {
        guard !orderedIdentifiers.isEmpty else { return }
        guard GenieCapabilities.canModifySystemPreferenceDomains else { return }

        let order = orderedIdentifiers.map { $0.lowercased() }.filter { !$0.isEmpty }
        guard !order.isEmpty else { return }

        DispatchQueue.global(qos: .userInitiated).async {
            let apps = GenieNativeSystem.dockPersistentApps()
            guard !apps.isEmpty else { return }

            // Stable sort by first matching position in `order`, unmatched last —
            // the same ranking the old Python did, without interpolating a JSON
            // blob into a single-quoted Python literal.
            let ranked = apps.enumerated().map { index, entry -> (Int, Int, [String: Any]) in
                let haystack = Self.dockEntryHaystack(entry)
                let rank = order.firstIndex(where: { haystack.contains($0) }) ?? 9999
                return (rank, index, entry)
            }
            let sorted = ranked.sorted { lhs, rhs in
                lhs.0 == rhs.0 ? lhs.1 < rhs.1 : lhs.0 < rhs.0
            }
            guard sorted.map(\.1) != Array(apps.indices) else { return }
            GenieNativeSystem.setDockPersistentApps(sorted.map(\.2))
        }
    }

    // MARK: - Desktop & Home Folder Shortcuts

    public func checkExistingShortcuts() {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let d0 = homeDir.appendingPathComponent("Desktop/Genie.app").path
        let d1 = homeDir.appendingPathComponent("Desktop/Golden Gate Studio.app").path
        let d2 = homeDir.appendingPathComponent("Desktop/Gold Gate.app").path
        let h0 = homeDir.appendingPathComponent("Genie.app").path
        let h1 = homeDir.appendingPathComponent("Golden Gate Studio.app").path
        let h2 = homeDir.appendingPathComponent("Gold Gate.app").path

        self.isDesktopIconCreated = FileManager.default.fileExists(atPath: d0) || FileManager.default.fileExists(atPath: d1) || FileManager.default.fileExists(atPath: d2)
        self.isHomeIconCreated = FileManager.default.fileExists(atPath: h0) || FileManager.default.fileExists(atPath: h1) || FileManager.default.fileExists(atPath: h2)
    }

    public func createDesktopAndHomeShortcuts() {
        let appPath = primaryAppPath
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let desktopURL = homeDir.appendingPathComponent("Desktop/Genie.app")
        let homeURL = homeDir.appendingPathComponent("Genie.app")

        let fm = FileManager.default

        try? fm.removeItem(at: desktopURL)
        try? fm.removeItem(at: homeURL)
        try? fm.removeItem(at: homeDir.appendingPathComponent("Desktop/Golden Gate Studio.app"))
        try? fm.removeItem(at: homeDir.appendingPathComponent("Golden Gate Studio.app"))
        try? fm.removeItem(at: homeDir.appendingPathComponent("Desktop/Gold Gate.app"))
        try? fm.removeItem(at: homeDir.appendingPathComponent("Gold Gate.app"))

        if fm.fileExists(atPath: appPath) {
            try? fm.createSymbolicLink(atPath: desktopURL.path, withDestinationPath: appPath)
            try? fm.createSymbolicLink(atPath: homeURL.path, withDestinationPath: appPath)
        }

        checkExistingShortcuts()
    }

    public func removeDesktopAndHomeShortcuts() {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        let fm = FileManager.default
        try? fm.removeItem(at: homeDir.appendingPathComponent("Desktop/Genie.app"))
        try? fm.removeItem(at: homeDir.appendingPathComponent("Genie.app"))
        try? fm.removeItem(at: homeDir.appendingPathComponent("Desktop/Golden Gate Studio.app"))
        try? fm.removeItem(at: homeDir.appendingPathComponent("Golden Gate Studio.app"))
        try? fm.removeItem(at: homeDir.appendingPathComponent("Desktop/Gold Gate.app"))
        try? fm.removeItem(at: homeDir.appendingPathComponent("Gold Gate.app"))

        checkExistingShortcuts()
    }
}
