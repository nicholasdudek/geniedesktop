import AppKit
import Foundation
import SwiftUI

// MARK: - App Category System

enum AppCategory: String, CaseIterable, Identifiable {
    case all = "All Apps"
    case terminal = "Terminal"
    case ide = "IDE & Coding"
    case browser = "Browser"
    case design = "Design & Creative"
    case chat = "Chat & Collab"
    case notes = "Notes & Docs"
    case media = "Media & Audio"
    case utilities = "Utilities"

    var id: String { rawValue }

    var tag: String {
        switch self {
        case .all: return "ALL"
        case .terminal: return "TERM"
        case .ide: return "CODE"
        case .browser: return "WEB"
        case .design: return "DESIGN"
        case .chat: return "CHAT"
        case .notes: return "DOCS"
        case .media: return "MEDIA"
        case .utilities: return "UTIL"
        }
    }

    var tintColor: Color {
        switch self {
        case .all: return Color.orange
        case .terminal: return Color.green
        case .ide: return Color.cyan
        case .browser: return Color.blue
        case .design: return Color.pink
        case .chat: return Color.purple
        case .notes: return Color.yellow
        case .media: return Color.red
        case .utilities: return Color.mint
        }
    }

    var icon: String {
        switch self {
        case .all: return "sparkles"
        case .terminal: return "terminal.fill"
        case .ide: return "chevron.left.forwardslash.chevron.right"
        case .browser: return "safari.fill"
        case .design: return "paintbrush.fill"
        case .chat: return "bubble.left.and.bubble.right.fill"
        case .notes: return "doc.text.fill"
        case .media: return "play.rectangle.fill"
        case .utilities: return "wrench.and.screwdriver.fill"
        }
    }
}

struct AppInfo: Identifiable, @unchecked Sendable, Hashable {
    let id: String
    let name: String
    let url: URL
    let icon: NSImage

    static func == (lhs: AppInfo, rhs: AppInfo) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

@MainActor
class AppModel: ObservableObject {
    public static var shared: AppModel?

    @Published var apps: [AppInfo] = []
    @Published var runningApps: [NSRunningApplication] = []

    private var workspaceObservers: [NSObjectProtocol] = []

    init() {
        AppModel.shared = self
        setupObservers()
        Task { [weak self] in
            await self?.load()
        }
    }

    private var folderSources: [DispatchSourceFileSystemObject] = []
    private var periodicRefreshTimer: Timer?

    deinit {
        for observer in workspaceObservers {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
        for src in folderSources {
            src.cancel()
        }
        periodicRefreshTimer?.invalidate()
    }

    private func setupObservers() {
        let center = NSWorkspace.shared.notificationCenter
        let launchObserver = center.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.loadRunning()
            }
        }
        let termObserver = center.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.loadRunning()
            }
        }
        let activateObserver = center.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notif in
            Task { @MainActor in
                self?.loadRunning()
            }
        }
        workspaceObservers = [launchObserver, termObserver, activateObserver]

        // 1. Live Folder Monitoring: Automatically detects whenever an app is copied, installed, or moved
        let monitorDirs = [
            "/Applications",
            "/System/Applications",
            NSHomeDirectory() + "/Applications"
        ]

        for dir in monitorDirs {
            let fd = open(dir, O_EVTONLY)
            guard fd >= 0 else { continue }
            let source = DispatchSource.makeFileSystemObjectSource(
                fileDescriptor: fd,
                eventMask: [.write, .link, .rename, .attrib],
                queue: DispatchQueue.global(qos: .utility)
            )
            source.setEventHandler { [weak self] in
                Task { @MainActor in
                    await self?.load()
                }
            }
            source.setCancelHandler {
                close(fd)
            }
            source.resume()
            folderSources.append(source)
        }

        // 2. Periodic Safety Check: Refreshes app list every 30 seconds if any background installs occurred
        periodicRefreshTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.load()
            }
        }
    }

    func load() async {
        let loadedApps: [AppInfo] = await Task.detached(priority: .userInitiated) {
            var items: [AppInfo] = []
            var seenPaths = Set<String>()

            // 1. Direct High-Speed Directory Enumeration (Zero subprocess overhead)
            let standardDirs = [
                "/Applications",
                "/System/Applications",
                "/System/Applications/Utilities",
                "/Applications/Utilities",
                NSHomeDirectory() + "/Applications",
                NSHomeDirectory() + "/Applications/Chrome Apps.localized",
                "/System/Library/CoreServices/Applications"
            ]
            for dir in standardDirs {
                if let contents = try? FileManager.default.contentsOfDirectory(atPath: dir) {
                    for name in contents where name.hasSuffix(".app") {
                        let path = "\(dir)/\(name)"
                        if !seenPaths.contains(path) {
                            seenPaths.insert(path)
                            let url = URL(fileURLWithPath: path)
                            let bundle = Bundle(url: url)
                            let displayName =
                                bundle?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
                                ?? bundle?.object(forInfoDictionaryKey: "CFBundleName") as? String
                                ?? name.replacingOccurrences(of: ".app", with: "")
                            let icon = AppModel.highestQualityIcon(for: path)
                            items.append(AppInfo(id: path, name: displayName, url: url, icon: icon))
                        }
                    }
                }
            }

            var deduplicated: [AppInfo] = []
            var seenBundleIDs = Set<String>()
            var seenNames = Set<String>()

            for app in items {
                let bundleID = Bundle(url: app.url)?.bundleIdentifier?.lowercased() ?? ""
                let lowerName = app.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

                if !bundleID.isEmpty && seenBundleIDs.contains(bundleID) { continue }
                if seenNames.contains(lowerName) && !lowerName.isEmpty { continue }

                if !bundleID.isEmpty { seenBundleIDs.insert(bundleID) }
                seenNames.insert(lowerName)
                deduplicated.append(app)
            }

            return deduplicated.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        }.value

        let customOrder = UserDefaults.standard.stringArray(forKey: PrefKey.customAppOrder) ?? []
        if !customOrder.isEmpty {
            var orderMap = [String: Int]()
            for (i, id) in customOrder.enumerated() {
                orderMap[id] = i
            }
            self.apps = loadedApps.sorted {
                let o1 = orderMap[$0.id] ?? Int.max
                let o2 = orderMap[$1.id] ?? Int.max
                if o1 != o2 { return o1 < o2 }
                return $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        } else {
            self.apps = loadedApps
        }
        
        // Update IPE Fast Search Manifold
        InverseProbabilityEliminationEngine.shared.updateIndex(items: self.apps.map { ($0.id, $0.name) })
        loadRunning()
    }

    /// Sub-millisecond Inverse Probability Elimination Search
    public func ipeSearch(query: String) -> [AppInfo] {
        let matchingIDs = InverseProbabilityEliminationEngine.shared.filter(query: query)
        var appMap = [String: AppInfo]()
        for app in apps { appMap[app.id] = app }
        return matchingIDs.compactMap { appMap[$0] }
    }

    var visibleApps: [AppInfo] {
        let hiddenIDs = Set(UserDefaults.standard.stringArray(forKey: PrefKey.hiddenAppIDs) ?? [])
        return apps.filter { !hiddenIDs.contains($0.id) }
    }

    func hideApp(_ app: AppInfo) {
        var hiddenIDs = UserDefaults.standard.stringArray(forKey: PrefKey.hiddenAppIDs) ?? []
        if !hiddenIDs.contains(app.id) {
            hiddenIDs.append(app.id)
            UserDefaults.standard.set(hiddenIDs, forKey: PrefKey.hiddenAppIDs)
            objectWillChange.send()
        }
    }

    func unhideApp(id: String) {
        var hiddenIDs = UserDefaults.standard.stringArray(forKey: PrefKey.hiddenAppIDs) ?? []
        hiddenIDs.removeAll { $0 == id }
        UserDefaults.standard.set(hiddenIDs, forKey: PrefKey.hiddenAppIDs)
        objectWillChange.send()
    }

    func showInFinder(_ app: AppInfo) {
        NSWorkspace.shared.activateFileViewerSelecting([app.url])
    }

    func moveApp(from sourceID: String, to targetID: String) {
        guard let srcIdx = apps.firstIndex(where: { $0.id == sourceID }),
            let dstIdx = apps.firstIndex(where: { $0.id == targetID }),
            srcIdx != dstIdx
        else { return }

        let moved = apps.remove(at: srcIdx)
        apps.insert(moved, at: dstIdx)
        let order = apps.map { $0.id }
        UserDefaults.standard.set(order, forKey: PrefKey.customAppOrder)
    }

    func resetAppOrder() {
        UserDefaults.standard.removeObject(forKey: PrefKey.customAppOrder)
        apps.sort { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func loadRunning() {
        let currentPID = NSRunningApplication.current.processIdentifier
        runningApps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular && $0.processIdentifier != currentPID }
            .sorted { ($0.localizedName ?? "") < ($1.localizedName ?? "") }
    }

    func category(for app: AppInfo) -> AppCategory {
        let name = app.name.lowercased()
        let path = app.url.path.lowercased()
        let id = app.id.lowercased()

        func matches(_ terms: [String]) -> Bool {
            terms.contains { name.contains($0) || path.contains($0) || id.contains($0) }
        }

        // 1. Terminal
        if matches([
            "terminal", "iterm", "warp", "alacritty", "kitty", "hyper", "ghostty", "wezterm", "rio",
            "tabby", "zsh", "bash", "fish", "pty", "console.app",
        ]) {
            return .terminal
        }

        // 2. IDE / Coding
        if matches([
            "xcode", "code", "cursor", "intellij", "pycharm", "clion", "webstorm", "rider",
            "goland", "rustrover", "appcode", "rubymine", "phpstorm", "datagrip", "android studio",
            "sublime", "nova", "zed", "fleet", "textmate", "bbedit", "atom", "eclipse", "netbeans",
            "emacs", "macvim", "neovim", "nvim", "vscodium", "windsurf", "trae", "developer",
            "postman", "insomnia", "tableplus", "paw", "visual studio", "docker", "sourcetree",
            "fork", "gitkraken",
        ]) {
            return .ide
        }

        // 3. Browser
        if matches([
            "safari", "chrome", "arc", "firefox", "brave", "edge", "opera", "vivaldi", "orion",
            "zen", "tor browser", "duckduckgo", "chromium", "webkit", "browser", "waterfox",
        ]) {
            return .browser
        }

        // 4. Design & Creative
        if matches([
            "figma", "sketch", "photoshop", "illustrator", "indesign", "after effects", "premiere",
            "final cut", "blender", "lightroom", "principle", "framer", "pixelmator", "canva",
            "penpot", "affinity designer", "affinity photo", "affinity publisher", "da vinci",
            "davinci", "cinema 4d", "maya", "invision", "zeplin", "rive", "spline", "procreate",
            "gimp", "inkscape", "aseprite", "vectornator", "linear mouse", "cleanmymac",
        ]) {
            return .design
        }

        // 5. Chat / Collab
        if matches([
            "slack", "discord", "teams", "messages", "telegram", "whatsapp", "signal", "zoom",
            "webex", "meet", "skype", "wechat", "lark", "feishu", "line", "element", "mattermost",
            "rocketchat", "facetime", "spark", "thunderbird", "outlook", "mail",
        ]) {
            return .chat
        }

        // 6. Notes / Docs
        if matches([
            "notes", "obsidian", "notion", "bear", "craft", "word", "pages", "google docs",
            "apple books", "books", "devonthink", "logseq", "typora", "ulysses", "goodnotes",
            "textedit", "evernote", "linear", "jira", "anytype", "quiver", "scrivener",
            "notability", "roam", "onenote", "markdown", "reader", "keynote", "excel", "numbers",
            "pdf", "acrobat", "drafts", "marginnote", "freeform", "ia writer",
        ]) {
            return .notes
        }

        // 7. Media / Audio
        if matches([
            "music", "spotify", "quicktime", "vlc", "iina", "podcasts", "tv", "tidal", "youtube",
            "soundcloud", "logic pro", "ableton", "garageband", "audacity", "plex", "sonos",
            "infuse", "deezer", "foobar", "reaper", "rekordbox", "traktor", "audio",
        ]) {
            return .media
        }

        return .utilities
    }

    func searchScore(for app: AppInfo, query: String) -> Int? {
        guard !query.isEmpty else { return 0 }
        let q = query.lowercased().trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return 0 }

        let name = app.name.lowercased()
        let cat = self.category(for: app)
        let catName = cat.rawValue.lowercased()
        let catTag = cat.tag.lowercased()

        // 1. Exact match on app name
        if name == q {
            return 1000
        }

        // 2. Prefix match on full app name
        if name.hasPrefix(q) {
            return 800 + max(0, 50 - name.count)
        }

        // 3. Word boundary prefix match (e.g. "Chrome" in "Google Chrome")
        let words = name.split { !$0.isLetter && !$0.isNumber }
        if words.contains(where: { $0.hasPrefix(q) }) {
            return 650
        }

        // 4. Acronym match (e.g. "vsc" -> "Visual Studio Code", "gc" -> "Google Chrome", "as" -> "Android Studio")
        let initials = String(words.compactMap { $0.first })
        if initials.hasPrefix(q) || initials == q {
            return 550
        }

        // 5. Substring match in name
        if let range = name.range(of: q) {
            let pos = name.distance(from: name.startIndex, to: range.lowerBound)
            return 400 - min(150, pos * 10)
        }

        // 6. Match category name or tag
        if catName.contains(q) || catTag.contains(q) {
            return 250
        }

        // 7. Subsequence fuzzy match (letters in order)
        var qIdx = q.startIndex
        var nIdx = name.startIndex
        while qIdx < q.endIndex && nIdx < name.endIndex {
            if q[qIdx] == name[nIdx] {
                qIdx = q.index(after: qIdx)
            }
            nIdx = name.index(after: nIdx)
        }
        if qIdx == q.endIndex {
            return 150
        }

        return nil
    }

    func filteredApps(search: String = "", category: AppCategory? = nil) -> [AppInfo] {
        var list = apps
        if let cat = category {
            list = list.filter { self.category(for: $0) == cat }
        }
        guard !search.isEmpty else { return list }

        let launchCounts =
            UserDefaults.standard.dictionary(forKey: PrefKey.launchCounts) as? [String: Int] ?? [:]

        var scored: [(app: AppInfo, score: Int)] = []
        for app in list {
            if let baseScore = searchScore(for: app, query: search) {
                let usageBonus = min(80, (launchCounts[app.name] ?? 0) * 8)
                scored.append((app, baseScore + usageBonus))
            }
        }

        return scored.sorted {
            if $0.score != $1.score {
                return $0.score > $1.score
            }
            return $0.app.name.localizedCaseInsensitiveCompare($1.app.name) == .orderedAscending
        }.map { $0.app }
    }

    func categorizedApps(search: String, category: AppCategory? = nil) -> [(
        category: AppCategory, apps: [AppInfo]
    )] {
        let matchingApps = filteredApps(search: search, category: category)
        if let specificCat = category {
            return matchingApps.isEmpty ? [] : [(category: specificCat, apps: matchingApps)]
        }

        var results: [(category: AppCategory, apps: [AppInfo])] = []
        for cat in AppCategory.allCases {
            let catApps = matchingApps.filter { self.category(for: $0) == cat }
            if !catApps.isEmpty {
                results.append((category: cat, apps: catApps))
            }
        }
        return results
    }

    func launch(_ app: AppInfo) {
        // Record launch count for intelligent recents ranking
        var counts = UserDefaults.standard.dictionary(forKey: PrefKey.launchCounts) as? [String: Int] ?? [:]
        counts[app.name, default: 0] += 1
        UserDefaults.standard.set(counts, forKey: PrefKey.launchCounts)

        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        config.addsToRecentItems = true
        NSWorkspace.shared.openApplication(at: app.url, configuration: config) { appInstance, error in
            if appInstance == nil || error != nil {
                DispatchQueue.main.async {
                    _ = NSWorkspace.shared.open(app.url)
                }
            }
        }
    }

    func kill(_ app: NSRunningApplication, force: Bool = false) {
        if force {
            _ = app.forceTerminate()
        } else {
            if !app.terminate() {
                _ = app.forceTerminate()
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.loadRunning()
        }
    }

    func focus(_ app: NSRunningApplication) {
        app.activate()
    }

    nonisolated static func highestQualityIcon(for path: String) -> NSImage {
        if let cached = IconCacheBox.shared.get(path) {
            return cached
        }
        let raw = NSWorkspace.shared.icon(forFile: path)
        let targetSize: CGFloat = 256.0
        raw.size = NSSize(width: targetSize, height: targetSize)

        // Downsample to crisp 256x256 Retina @2x (saves >150 MB of uncompressed bitmap RAM)
        if let rep = raw.bestRepresentation(
            for: NSRect(x: 0, y: 0, width: targetSize, height: targetSize),
            context: nil,
            hints: [.interpolation: NSImageInterpolation.high.rawValue]
        ) {
            let highResImage = NSImage(size: NSSize(width: targetSize, height: targetSize))
            highResImage.addRepresentation(rep)
            IconCacheBox.shared.set(highResImage, for: path)
            return highResImage
        }
        IconCacheBox.shared.set(raw, for: path)
        return raw
    }
}

// MARK: - Thread-Safe Icon Cache

private final class IconCacheBox: @unchecked Sendable {
    static let shared = IconCacheBox()
    private let cache = NSCache<NSString, NSImage>()

    init() {
        cache.countLimit = 150
        cache.totalCostLimit = 24 * 1024 * 1024 // 24 MB Max RAM budget for app icons
    }

    func get(_ key: String) -> NSImage? {
        cache.object(forKey: key as NSString)
    }

    func set(_ image: NSImage, for key: String) {
        let cost = Int(image.size.width * image.size.height * 4)
        cache.setObject(image, forKey: key as NSString, cost: cost)
    }
}
