import Cocoa
import FinderSync
import GenieFinderSyncShared

/// Principal class for the com.apple.FinderSync extension point. Runs in its
/// own extension process — it never touches Genie's app state directly, only
/// through FinderSyncStore (shared App Group defaults + a distributed
/// notification to wake whichever side needs to react).
final class GenieFinderSync: FIFinderSync {
    private let controller = FIFinderSyncController.default()
    private var badgeMap: [String: GenieFinderBadge] = [:]
    private var refreshObserver: NSObjectProtocol?

    override init() {
        super.init()
        NSLog("GenieFinderSync() launched from %@", Bundle.main.bundlePath as NSString)

        controller.directoryURLs = Set(watchedDirectoryURLs())
        registerBadgeImages()
        badgeMap = FinderSyncStore.readBadgeMap()

        refreshObserver = DistributedNotificationCenter.default().addObserver(
            forName: Notification.Name(FinderSyncIPC.notifyRefreshBadges),
            object: nil, queue: .main
        ) { [weak self] _ in
            self?.reloadBadgeMap()
        }
    }

    deinit {
        if let refreshObserver {
            DistributedNotificationCenter.default().removeObserver(refreshObserver)
        }
    }

    // MARK: - Setup

    private func watchedDirectoryURLs() -> [URL] {
        var urls: [URL] = [FileManager.default.homeDirectoryForCurrentUser]
        let extra: [FileManager.SearchPathDirectory] = [.desktopDirectory, .documentDirectory, .downloadsDirectory]
        for dir in extra {
            if let url = FileManager.default.urls(for: dir, in: .userDomainMask).first {
                urls.append(url)
            }
        }
        urls.append(contentsOf: FinderSyncStore.readWatchedFolders().map(URL.init(fileURLWithPath:)))
        return urls
    }

    private func registerBadgeImages() {
        for badge in GenieFinderBadge.allCases {
            let image = NSImage(systemSymbolName: badge.symbolName, accessibilityDescription: badge.label) ?? NSImage()
            controller.setBadgeImage(image, label: badge.label, forBadgeIdentifier: badge.badgeIdentifier)
        }
    }

    private func reloadBadgeMap() {
        badgeMap = FinderSyncStore.readBadgeMap()
        for (path, badge) in badgeMap {
            controller.setBadgeIdentifier(badge.badgeIdentifier, for: URL(fileURLWithPath: path))
        }
    }

    // MARK: - FIFinderSync

    override func beginObservingDirectory(at url: URL) {
        NSLog("GenieFinderSync: beginObservingDirectory %@", url.path)
    }

    override func endObservingDirectory(at url: URL) {
        NSLog("GenieFinderSync: endObservingDirectory %@", url.path)
    }

    override func requestBadgeIdentifier(for url: URL) {
        controller.setBadgeIdentifier(badgeMap[url.path]?.badgeIdentifier ?? "", for: url)
    }

    // MARK: - Toolbar item (appears in every Finder window's toolbar)

    override var toolbarItemName: String { "Genie" }

    override var toolbarItemImage: NSImage {
        NSImage(systemSymbolName: "sparkles", accessibilityDescription: "Genie") ?? NSImage()
    }

    override var toolbarItemToolTip: String { "Open Genie for this Finder window" }

    // MARK: - Menus (FinderSync has no plain "toolbar button clicked" callback —
    // clicking the toolbar button always requests .toolbarItemMenu here instead)

    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        let menu = NSMenu(title: "")

        if menuKind == .toolbarItemMenu {
            let openItem = NSMenuItem(title: "Open Genie", action: #selector(openToolbarPanel(_:)), keyEquivalent: "")
            openItem.image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: nil)
            openItem.target = self
            menu.addItem(openItem)
            return menu
        }

        guard menuKind == .contextualMenuForItems || menuKind == .contextualMenuForContainer else {
            return menu
        }

        let selection = controller.selectedItemURLs() ?? []
        if !selection.isEmpty {
            let title = selection.count == 1 ? "Ask Genie About This Item" : "Ask Genie About \(selection.count) Items"
            let askItem = NSMenuItem(title: title, action: #selector(askGenieAboutSelection(_:)), keyEquivalent: "")
            askItem.image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: nil)
            askItem.target = self
            menu.addItem(askItem)
        }

        let openWorkspace = NSMenuItem(
            title: "Open Genie Workspace Here",
            action: #selector(openWorkspaceHere(_:)), keyEquivalent: ""
        )
        openWorkspace.image = NSImage(systemSymbolName: "sparkle.magnifyingglass", accessibilityDescription: nil)
        openWorkspace.target = self
        menu.addItem(openWorkspace)

        return menu
    }

    @objc private func askGenieAboutSelection(_ sender: AnyObject?) {
        let selection = controller.selectedItemURLs() ?? []
        let request = GenieFinderRequest(
            intent: .askAboutSelection,
            itemPaths: selection.map(\.path),
            containerPath: controller.targetedURL()?.path
        )
        FinderSyncStore.writeRequest(request)
        launchOrActivateHostApp()
    }

    @objc private func openToolbarPanel(_ sender: AnyObject?) {
        let request = GenieFinderRequest(
            intent: .openToolbarPanel,
            itemPaths: [],
            containerPath: controller.targetedURL()?.path
        )
        FinderSyncStore.writeRequest(request)
        launchOrActivateHostApp()
    }

    @objc private func openWorkspaceHere(_ sender: AnyObject?) {
        let request = GenieFinderRequest(
            intent: .openWorkspace,
            itemPaths: [],
            containerPath: controller.targetedURL()?.path
        )
        FinderSyncStore.writeRequest(request)
        launchOrActivateHostApp()
    }

    private func launchOrActivateHostApp() {
        guard let hostURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: FinderSyncIPC.hostBundleIdentifier) else {
            NSLog("GenieFinderSync: could not locate host app bundle %@", FinderSyncIPC.hostBundleIdentifier)
            return
        }
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        NSWorkspace.shared.openApplication(at: hostURL, configuration: config) { _, error in
            if let error {
                NSLog("GenieFinderSync: failed to launch host app: %@", error.localizedDescription)
            }
        }
    }
}
