import AppKit
import SwiftUI

// MARK: - Menu Bar Dock Apps Grid View
// Renders dock and running application icons in a spacious, gridded strip
// positioned across available room up until Help.
public struct MenuBarDockAppsGridView: View {
    @ObservedObject var gridManager = SmartGridManager.shared
    @AppStorage(PrefKey.appLanguage) var appLanguage: String = "English (US)"
    @AppStorage(PrefKey.miniDockBackgroundStyle) var miniDockBackgroundStyle: String = "Clear (Transparent)"
    @AppStorage(PrefKey.dockActiveAppsOnly) var dockActiveAppsOnly: Bool = false
    @AppStorage(PrefKey.dockAlwaysShowFinder) var dockAlwaysShowFinder: Bool = true
    @AppStorage(PrefKey.dockAlwaysShowSettings) var dockAlwaysShowSettings: Bool = true
    @AppStorage(PrefKey.dockAlwaysShowTrash) var dockAlwaysShowTrash: Bool = true
    @AppStorage(PrefKey.dockAlwaysShowGenie) var dockAlwaysShowGenie: Bool = true
    @AppStorage(PrefKey.smokeEffectsEnabled) var smokeEffectsEnabled: Bool = true
    @AppStorage(PrefKey.smokeStyle) var smokeStyle: String = "Mystical Cyan 🧞‍♂️"

    @State private var dockItems: [DockAppItem] = []
    @State private var runningApps: [NSRunningApplication] = []
    @State private var activePid: pid_t = NSWorkspace.shared.frontmostApplication?.processIdentifier ?? 0
    @State private var hoveredItemId: String? = nil
    @State private var bouncingItemId: String? = nil
    @State private var smokingItemId: String? = nil
    @State private var timer: Timer?
    @ObservedObject private var desktopWindowManager = DesktopWindowManager.shared

    public init() {}

    public var body: some View {
        HStack(alignment: .center, spacing: 5) {
            ForEach(dockItems) { item in
                let isBouncing = bouncingItemId == item.id
                let isHovered = hoveredItemId == item.id
                let isSmoking = smokingItemId == item.id
                let isCurrentActive = (item.runningApp != nil && (activePid == item.processIdentifier || item.runningApp?.isActive == true))

                Button(action: {
                    activateApp(item)
                }) {
                    ZStack(alignment: .center) {
                        // Radiant Genie Aura Glow
                        if isHovered || isBouncing {
                            Circle()
                                .fill(
                                    RadialGradient(
                                        gradient: Gradient(colors: [
                                            Color(red: 0.0, green: 0.85, blue: 1.0).opacity(isBouncing ? 0.70 : 0.38),
                                            Color(red: 1.0, green: 0.82, blue: 0.20).opacity(isBouncing ? 0.50 : 0.18),
                                            Color.clear
                                        ]),
                                        center: .center,
                                        startRadius: 2,
                                        endRadius: 18
                                    )
                                )
                                .frame(width: 34, height: 34)
                                .blur(radius: 2)
                        }

                        // Dock-style slot highlight on hover
                        RoundedRectangle(cornerRadius: 6.5, style: .continuous)
                            .fill(isHovered ? Color.white.opacity(0.18) : Color.clear)
                            .frame(width: 30, height: 30)

                        VStack(spacing: 2) {
                            ZStack(alignment: .bottomTrailing) {
                                if let icon = item.icon {
                                    Image(nsImage: icon)
                                        .resizable()
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 24, height: 24)
                                } else {
                                    Image(systemName: "app.dashed")
                                        .font(.system(size: 16))
                                        .frame(width: 24, height: 24)
                                }
                            }
                            .shadow(
                                color: Color.black.opacity(isHovered ? 0.45 : 0.22),
                                radius: isHovered ? 2.5 : 1.0,
                                y: isHovered ? 1.5 : 0.8
                            )

                            // macOS Dock Running Indicator Dot
                            if item.isRunning {
                                Circle()
                                    .fill(Color.white.opacity(isCurrentActive ? 1.0 : 0.75))
                                    .frame(width: isCurrentActive ? 3.5 : 2.5, height: isCurrentActive ? 3.5 : 2.5)
                                    .shadow(
                                        color: isCurrentActive ? Color.white.opacity(0.9) : Color.black.opacity(0.5),
                                        radius: isCurrentActive ? 1.5 : 0.5,
                                        y: isCurrentActive ? 0 : 0.5
                                    )
                            } else {
                                Spacer().frame(height: 2.5)
                            }
                        }

                        if smokeEffectsEnabled && isSmoking {
                            let (prim, _, _) = GenieSmokeEngine.colors(for: smokeStyle)
                            MiniDockSmokePuffView(color: prim)
                        }
                    }
                    .frame(width: 30, height: 30)
                    .scaleEffect(isBouncing ? 1.25 : (isHovered ? 1.12 : 1.0))
                    .contentShape(RoundedRectangle(cornerRadius: 6.5, style: .continuous))
                }
                .buttonStyle(DockIconButtonStyle())
                .onHover { hovering in
                    withAnimation(.spring(response: 0.18, dampingFraction: 0.75)) {
                        if hovering {
                            hoveredItemId = item.id
                        } else if hoveredItemId == item.id {
                            hoveredItemId = nil
                        }
                    }
                }
                .help(item.isRunning ? "\(item.name) — Click to bring to front" : "\(item.name) — Click to launch")
                .contextMenu {
                    if item.id == "com.nicholasdudek.genie" || item.bundleIdentifier == "com.nicholasdudek.genie" {
                        Button("Open Dialogue Studio (⌘⌥Space)") {
                            NotificationCenter.default.post(name: NSNotification.Name("NexusFocusGenieSearchBarWithMode"), object: "chat")
                        }
                        Button("Launch Precision Console (Terminal)") {
                            NotificationCenter.default.post(name: NSNotification.Name("NexusFocusGenieSearchBarWithMode"), object: "terminal")
                        }
                        Button("Inscribe Memorandum (Notes)") {
                            NotificationCenter.default.post(name: NSNotification.Name("NexusFocusGenieSearchBarWithMode"), object: "file")
                        }
                        Button("Toggle Architectural Canvas (⌘⇧D)") {
                            NotificationCenter.default.post(name: NSNotification.Name("NexusToggleDesktopGrid"), object: nil)
                        }
                        Divider()
                        Button(LocalizedStrings.translateText("Genie Settings...", lang: appLanguage)) {
                            AppDelegate.shared?.showMenuBarSettingsDropdown(targetTab: .system)
                        }
                        Divider()
                        Button(LocalizedStrings.translateText("Quit Genie", lang: appLanguage)) {
                            NSApp.terminate(nil)
                        }
                    } else if let app = item.runningApp, !app.isTerminated {
                        Button(LocalizedStrings.translateText("Bring All to Front", lang: appLanguage)) {
                            app.unhide()
                            _ = app.activate(options: [.activateAllWindows])
                            gridManager.bringToFront(app: app)
                        }
                        Button(LocalizedStrings.translateText("Show All Windows", lang: appLanguage)) {
                            app.unhide()
                            _ = app.activate(options: [.activateAllWindows])
                            gridManager.bringToFront(app: app)
                        }
                        if app.isHidden {
                            Button(LocalizedStrings.translateText("Unhide", lang: appLanguage)) {
                                app.unhide()
                                _ = app.activate()
                            }
                        } else {
                            Button(LocalizedStrings.translateText("Hide", lang: appLanguage)) {
                                app.hide()
                            }
                        }
                        Button(LocalizedStrings.translateText("Quit", lang: appLanguage)) {
                            app.terminate()
                        }
                        Button(LocalizedStrings.translateText("Force Quit", lang: appLanguage)) {
                            app.forceTerminate()
                        }
                        Divider()
                        Button(LocalizedStrings.translateText("Show in Finder", lang: appLanguage)) {
                            let targetURL = app.bundleURL ?? app.bundleIdentifier.flatMap { NSWorkspace.shared.urlForApplication(withBundleIdentifier: $0) }
                            if let url = targetURL {
                                NSWorkspace.shared.activateFileViewerSelecting([url])
                            }
                        }
                    } else {
                        Button("\(LocalizedStrings.translateText("Open", lang: appLanguage)) \(item.name)") {
                            activateApp(item)
                        }
                        if let url = item.bundleURL {
                            Button(LocalizedStrings.translateText("Show in Finder", lang: appLanguage)) {
                                NSWorkspace.shared.activateFileViewerSelecting([url])
                            }
                        }
                    }
                    Divider()
                    Button(LocalizedStrings.translateText("Remove from Mini Dock", lang: appLanguage)) {
                        removeDockItem(item)
                    }
                    Menu(LocalizedStrings.translateText("Mini Dock Options", lang: appLanguage)) {
                        Menu(LocalizedStrings.translateText("App Display Filter", lang: appLanguage)) {
                            Button(action: {
                                dockActiveAppsOnly = false
                                UserDefaults.standard.set(false, forKey: PrefKey.dockActiveAppsOnly)
                                NotificationCenter.default.post(name: NSNotification.Name("NexusDockActiveAppsOnlyChanged"), object: false)
                                refreshApps()
                            }) {
                                HStack {
                                    Text(LocalizedStrings.translateText("Show All (Running & Pinned)", lang: appLanguage))
                                    if !dockActiveAppsOnly { Text("✓") }
                                }
                            }
                            Button(action: {
                                dockActiveAppsOnly = true
                                UserDefaults.standard.set(true, forKey: PrefKey.dockActiveAppsOnly)
                                NotificationCenter.default.post(name: NSNotification.Name("NexusDockActiveAppsOnlyChanged"), object: true)
                                refreshApps()
                            }) {
                                HStack {
                                    Text(LocalizedStrings.translateText("Active Applications Only", lang: appLanguage))
                                    if dockActiveAppsOnly { Text("✓") }
                                }
                            }
                        }
                        Divider()
                        Toggle(LocalizedStrings.translateText("Always Show Finder", lang: appLanguage), isOn: Binding(
                            get: { dockAlwaysShowFinder },
                            set: { val in
                                dockAlwaysShowFinder = val
                                UserDefaults.standard.set(val, forKey: PrefKey.dockAlwaysShowFinder)
                                refreshApps()
                            }
                        ))
                        Toggle(LocalizedStrings.translateText("Always Show Settings", lang: appLanguage), isOn: Binding(
                            get: { dockAlwaysShowSettings },
                            set: { val in
                                dockAlwaysShowSettings = val
                                UserDefaults.standard.set(val, forKey: PrefKey.dockAlwaysShowSettings)
                                refreshApps()
                            }
                        ))
                        Toggle(LocalizedStrings.translateText("Always Show Trash", lang: appLanguage), isOn: Binding(
                            get: { dockAlwaysShowTrash },
                            set: { val in
                                dockAlwaysShowTrash = val
                                UserDefaults.standard.set(val, forKey: PrefKey.dockAlwaysShowTrash)
                                refreshApps()
                            }
                        ))
                        Toggle(LocalizedStrings.translateText("Always Show Genie Hub", lang: appLanguage), isOn: Binding(
                            get: { dockAlwaysShowGenie },
                            set: { val in
                                dockAlwaysShowGenie = val
                                UserDefaults.standard.set(val, forKey: PrefKey.dockAlwaysShowGenie)
                                refreshApps()
                            }
                        ))
                        Divider()
                        Button(LocalizedStrings.translateText("Restore Hidden Apps (Reset Mini Dock)", lang: appLanguage)) {
                            restoreAllHiddenDockApps()
                        }
                    }
                    Divider()
                    Button(LocalizedStrings.translateText("Genie Settings...", lang: appLanguage)) {
                        AppDelegate.shared?.showMenuBarSettingsDropdown(targetTab: .system)
                    }
                }
            }

            // Tri-State Workspace Switcher (Chat ➔ Applications ➔ Desktop)
            Button(action: {
                HapticFeedback.selection()
                desktopWindowManager.cycleWorkspaceSwitcher()
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6.5, style: .continuous)
                        .fill(Color.white.opacity(0.12))
                        .frame(width: 30, height: 30)

                    Image(systemName: switcherSymbol)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.95))
                }
            }
            .buttonStyle(DockIconButtonStyle())
            .help(switcherHelpText)
        }
        .onAppear {
            refreshApps()
            timer?.invalidate()
            let t = Timer(timeInterval: 2.0, repeats: true) { _ in
                Task { @MainActor in
                    self.refreshApps()
                }
            }
            RunLoop.main.add(t, forMode: .common)
            timer = t
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didLaunchApplicationNotification)) { _ in refreshApps() }
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didTerminateApplicationNotification)) { _ in refreshApps() }
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didActivateApplicationNotification)) { notif in
            if let app = notif.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                activePid = app.processIdentifier
            }
            refreshApps()
        }
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didHideApplicationNotification)) { _ in refreshApps() }
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didUnhideApplicationNotification)) { _ in refreshApps() }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusDockHiddenAppsChanged"))) { _ in refreshApps() }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusDockActiveAppsOnlyChanged"))) { _ in refreshApps() }
    }

    private var switcherSymbol: String {
        switch desktopWindowManager.currentStation {
        case .desktop:
            return "macwindow"
        case .chat:
            return "bubble.left.and.bubble.right.fill"
        case .applications:
            return "square.grid.3x3.fill"
        }
    }

    private var switcherHelpText: String {
        switch desktopWindowManager.currentStation {
        case .desktop:
            return "Desktop Canvas — Click to switch to Chat (⌘⇧D)"
        case .chat:
            return "Dialogue Studio — Click to switch to Applications (⌘⇧D)"
        case .applications:
            return "Application Atelier — Click to return to Desktop (⌘⇧D)"
        }
    }

    private func removeDockItem(_ item: DockAppItem) {
        var hidden = UserDefaults.standard.stringArray(forKey: PrefKey.hiddenDockBundleIDs) ?? []
        let key = item.bundleIdentifier ?? item.id
        if !hidden.contains(key) {
            hidden.append(key)
        }
        if !item.name.isEmpty && !hidden.contains(item.name) {
            hidden.append(item.name)
        }
        UserDefaults.standard.set(hidden, forKey: PrefKey.hiddenDockBundleIDs)
        UserDefaults.standard.synchronize()
        NotificationCenter.default.post(name: NSNotification.Name("NexusDockHiddenAppsChanged"), object: nil)
        refreshApps()
    }

    private func restoreAllHiddenDockApps() {
        UserDefaults.standard.removeObject(forKey: PrefKey.hiddenDockBundleIDs)
        UserDefaults.standard.synchronize()
        NotificationCenter.default.post(name: NSNotification.Name("NexusDockHiddenAppsChanged"), object: nil)
        refreshApps()
    }

    private func activateApp(_ item: DockAppItem) {
        if item.id == "com.nicholasdudek.genie" || item.bundleIdentifier == "com.nicholasdudek.genie" || item.name.lowercased() == "genie" {
            HapticFeedback.selection()
            withAnimation(.spring(response: 0.28, dampingFraction: 0.45)) {
                bouncingItemId = item.id
            }
            if smokeEffectsEnabled {
                smokingItemId = item.id
                GenieSmokeEngine.shared.triggerBurst(
                    origin: .dock,
                    bounds: AppDelegate.shared?.menuBarPanel?.frame.size ?? CGSize(width: 880, height: 600),
                    style: smokeStyle,
                    count: 24
                )
            }
            NotificationCenter.default.post(name: NSNotification.Name("NexusFocusGenieSearchBarWithMode"), object: "chat")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                if bouncingItemId == item.id { bouncingItemId = nil }
                if smokingItemId == item.id { smokingItemId = nil }
            }
            return
        }
        if item.id == "com.apple.Terminal" || item.name.lowercased() == "terminal" {
            let termURL = URL(fileURLWithPath: "/System/Applications/Utilities/Terminal.app")
            NSWorkspace.shared.open(termURL)
            return
        }
        if item.processIdentifier > 0 {
            activePid = item.processIdentifier
        }
        withAnimation(.spring(response: 0.28, dampingFraction: 0.45)) {
            bouncingItemId = item.id
        }
        if smokeEffectsEnabled {
            smokingItemId = item.id
            GenieSmokeEngine.shared.triggerBurst(
                origin: .dock,
                bounds: AppDelegate.shared?.menuBarPanel?.frame.size ?? CGSize(width: 880, height: 600),
                style: smokeStyle,
                count: 24
            )
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            if bouncingItemId == item.id { bouncingItemId = nil }
            if smokingItemId == item.id { smokingItemId = nil }
        }

        MenuBarActionDispatcher.shared.handleAppClick(item)
    }

    private func refreshApps() {
        let myPid = ProcessInfo.processInfo.processIdentifier
        let currentApps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular && $0.processIdentifier != myPid && !$0.isTerminated }

        let hiddenIDs = UserDefaults.standard.stringArray(forKey: PrefKey.hiddenDockBundleIDs) ?? []
        var result: [DockAppItem] = []

        // 0. Genie Premier Anchor (Executive AI & System Anchor)
        if dockAlwaysShowGenie {
            let genieIcon: NSImage? = {
                let devIconURL = URL(fileURLWithPath: "/Users/nicholasdudek/Developer/GoldGate/Sources/GoldGate/Assets.xcassets/AppIcon.appiconset/icon_512x512.png")
                if FileManager.default.fileExists(atPath: devIconURL.path), let img = NSImage(contentsOf: devIconURL) {
                    img.size = NSSize(width: 32, height: 32)
                    return img
                }
                if let appIcon = NSApp.applicationIconImage {
                    appIcon.size = NSSize(width: 32, height: 32)
                    return appIcon
                }
                let icon = NSWorkspace.shared.icon(forFile: Bundle.main.bundlePath)
                icon.size = NSSize(width: 32, height: 32)
                return icon
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

        // 1. Finder
        if dockAlwaysShowFinder {
            let finderApp = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.finder").first
            let finderURL = URL(fileURLWithPath: "/System/Library/CoreServices/Finder.app")
            let finderIcon = NSWorkspace.shared.icon(forFile: finderURL.path)
            finderIcon.size = NSSize(width: 32, height: 32)
            result.append(DockAppItem(
                id: "com.apple.finder",
                name: "Finder",
                bundleURL: finderURL,
                bundleIdentifier: "com.apple.finder",
                icon: finderIcon,
                runningApp: finderApp
            ))
        }

        // 2. Dock Apps matching com.apple.dock.plist order
        let dockApps = MenuBarAppStripView.loadSystemDockApps()
        for dApp in dockApps {
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

        // 2.5 System Settings (if requested and not already added)
        if dockAlwaysShowSettings {
            let settingsURL = URL(fileURLWithPath: "/System/Applications/System Settings.app")
            if FileManager.default.fileExists(atPath: settingsURL.path) {
                let settingsApp = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.systempreferences").first
                let settingsIcon = NSWorkspace.shared.icon(forFile: settingsURL.path)
                settingsIcon.size = NSSize(width: 32, height: 32)
                let settingsItem = DockAppItem(
                    id: "com.apple.systempreferences",
                    name: "System Settings",
                    bundleURL: settingsURL,
                    bundleIdentifier: "com.apple.systempreferences",
                    icon: settingsIcon,
                    runningApp: settingsApp
                )
                if !result.contains(where: { $0.representsSameApplication(as: settingsItem) }) {
                    result.append(settingsItem)
                }
            }
        }

        // 3. Active running applications not already pinned in Dock
        for app in currentApps {
            let bid = app.bundleIdentifier
            let name = app.localizedName ?? "App"
            if bid == "com.apple.finder" || bid == "com.nicholasdudek.genie" { continue }

            // Filter out secondary helper/renderer background processes
            let lowerName = name.lowercased()
            if lowerName.contains("helper") || lowerName.contains("renderer") || lowerName.contains("crashpad") {
                continue
            }

            let exists = result.contains(where: {
                DockAppItem.isSameApplication(
                    bidA: $0.bundleIdentifier, nameA: $0.name, urlA: $0.bundleURL,
                    bidB: bid, nameB: name, urlB: app.bundleURL
                )
            })
            if !exists {
                let icon = app.icon ?? NSWorkspace.shared.icon(forFile: app.bundleURL?.path ?? "")
                icon.size = NSSize(width: 32, height: 32)
                result.append(DockAppItem(
                    id: bid ?? "\(app.processIdentifier)",
                    name: name,
                    bundleURL: app.bundleURL,
                    bundleIdentifier: bid,
                    icon: icon,
                    runningApp: app
                ))
            }
        }

        // 4. Filter Hidden Apps
        if !hiddenIDs.isEmpty {
            result.removeAll { item in
                hiddenIDs.contains(item.id) ||
                (item.bundleIdentifier.map { hiddenIDs.contains($0) } ?? false) ||
                hiddenIDs.contains(item.name)
            }
        }

        // 5. Final Strict Deduplication Pass
        var deduplicated: [DockAppItem] = []
        var seenBundleIDs = Set<String>()
        var seenNames = Set<String>()
        var seenURLs = Set<String>()

        for item in result {
            let bid = item.bundleIdentifier?.lowercased() ?? ""
            let name = item.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let urlPath = item.bundleURL?.standardizedFileURL.path.lowercased() ?? ""

            if !bid.isEmpty && seenBundleIDs.contains(bid) { continue }
            if !name.isEmpty && seenNames.contains(name) { continue }
            if !urlPath.isEmpty && seenURLs.contains(urlPath) { continue }
            if deduplicated.contains(where: { $0.representsSameApplication(as: item) }) { continue }

            if !bid.isEmpty { seenBundleIDs.insert(bid) }
            if !name.isEmpty { seenNames.insert(name) }
            if !urlPath.isEmpty { seenURLs.insert(urlPath) }
            deduplicated.append(item)
        }

        if dockActiveAppsOnly {
            deduplicated = deduplicated.filter { $0.isRunning }
        }

        self.dockItems = deduplicated
    }
}
