import AppKit
import SwiftUI

private func appendDebugLog(_ msg: String) {
    if let handle = try? FileHandle(forWritingTo: URL(fileURLWithPath: "/tmp/genie_click_debug.txt")) {
        handle.seekToEndOfFile()
        handle.write(msg.data(using: .utf8)!)
        handle.closeFile()
    } else {
        try? msg.write(toFile: "/tmp/genie_click_debug.txt", atomically: true, encoding: .utf8)
    }
}

// MARK: - Hosting View for Menu Bar Status Item (Direct Native SwiftUI Event Routing)
final class ClickableHostingView<Content: View>: NSHostingView<Content> {
    override var intrinsicContentSize: NSSize {
        return NSSize(width: NSView.noIntrinsicMetric, height: NSView.noIntrinsicMetric)
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return true
    }
}

// MARK: - AppDelegate (Modular Application Lifecycle Coordinator)

@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    public static weak var shared: AppDelegate?

    var statusItem: NSStatusItem!
    var menuBarPanel: MenuBarPopoverPanel!

    let appModel = AppModel()
    let batteryMonitor = BatteryMonitor.shared

    var animTimer: Timer?
    var phase: CGFloat = 0

    private var lastShownTime: TimeInterval = 0
    private var lastClosedTime: TimeInterval = 0
    private var globalDismissMonitor: Any?
    private var localDismissMonitor: Any?
    private var permanentKeyMonitor: Any?

    private var isPopoverUnlocked: Bool {
        UserDefaults.standard.bool(forKey: PrefKey.popoverFreePositionEnabled)
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        print("GENIE: applicationDidFinishLaunching entered")
        // Also keeps GenieCapabilities.buildMarker referenced so the linker
        // cannot strip it — the packaging scripts grep the binary for it to
        // confirm they are signing the flavour they think they are.
        print("GENIE: distribution = \(GenieCapabilities.distributionChannel) [\(GenieCapabilities.buildMarker)]")
        AppDelegate.shared = self

        // 0a. Initialize standardized factory defaults and register them
        AppDefaultsManager.registerDefaults()
        AppDefaultsManager.applyInitialDefaults()

        // 0b. Silently refresh permissions status on launch without intrusive popups
        PermissionsManager.shared.refreshAll()

        // 0b-2. Listen for requests handed off from the GenieFinderSync Finder extension
        FinderSyncBridge.shared.start()

        // 0c. On the very first launch after install, actually ask for the access Genie needs
        // (screen recording, accessibility, full disk) instead of silently running degraded.
        if !UserDefaults.standard.bool(forKey: PrefKey.hasPromptedForPermissions) {
            UserDefaults.standard.set(true, forKey: PrefKey.hasPromptedForPermissions)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                PermissionsManager.shared.requestAllPermissions()
            }
        }

        // 0. Ensure a valid macOS System Menu exists so the top-left menu bar is always active and responsive
        setupMainMenu()

        // 1. Initialize Menu Bar Popover Panel
        let panelSize = currentPopoverSize()
        menuBarPanel = MenuBarPopoverPanel(
            contentRect: NSRect(x: 0, y: 0, width: panelSize.width, height: panelSize.height))
        applyPopoverMobility()

        menuBarPanel.contentView = NexusHostingView(
            rootView: MenuBarDropdownView(
                appModel: appModel,
                onRefreshApps: { [weak self] in
                    Task { @MainActor [weak self] in
                        await self?.appModel.load()
                    }
                },
                onQuitApp: {
                    NSApp.terminate(nil)
                }
            )
        )

        // 2. Initialize Desktop Plane Window Manager (2-Page Scroll Grid)
        DesktopWindowManager.shared.setup(appModel: appModel)

        // 2b. Initialize Dock & Desktop Shortcuts Manager
        DockAndDesktopManager.shared.setup()

        // 2c. Initialize Smart Grid & Screen Choices Manager (Shortcuts: ⌘⌥Space / ⌘⌥B)
        _ = SmartGridManager.shared

        // 2e. Initialize Arrow App Switcher & Window Snapping Manager (⌃↑ Overlay, ⌘ Arrows Snap)
        _ = ArrowAppSwitcherManager.shared

        // 2e-2. Initialize Screen Warp Manager (Instant Multi-Screen Window Teleportation: ⌃⌥→ / ⌃⌥←)
        ScreenWarpManager.shared.setup()

        // 2e-3. Notch Dock & Alarm Clock. The World Clock watch strip is no longer its own
        // panel: it renders inside the chat dock (RightSideChatDockView.watchStrip).
        NotchDockPanelManager.shared.setup()
        _ = AlarmClockManager.shared
        _ = UnifiedCommandWindowManager.shared

        // 3. Initialize Status Item with Dynamic Animated Battery & Menu Bar App Switcher
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.isVisible = !CustomMenuBarManager.shared.isEnabled
        if CustomMenuBarManager.shared.isEnabled {
            statusItem.length = 0
        }
        setupStatusItemView()
        startAnimation()

        // 2f. Initialize Custom Floating Inset Menu Bar Window Manager
        CustomMenuBarManager.shared.rebuildWindows()

        // 4. Global Outside-Click & Permanent Key Monitors
        setupGlobalDismissMonitor()
        setupPermanentKeyMonitor()

        // 5. Notification Observers
        setupNotificationObservers()

        // 6. App Installation & DMG Drag-to-Install Manager (Menu Bar & Dock Anchor)
        _ = AppInstallationManager.shared
        AppInstallationManager.shared.promptMoveToApplicationsIfNeeded()

        // 7. Launch Initial Compact Setup Walkthrough on First Install
        if !UserDefaults.standard.bool(forKey: PrefKey.hasCompletedInitialSetup) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
                self?.showMenuBarSettingsDropdown(targetTab: .battery)
            }
        }


        // 8. Initialize Genie Phone Remote Bridge & Dedicated iMessage Extension
        GeniePhoneBridgeManager.shared.startServer(port: 8765)
        _ = GenieiMessageExtensionManager.shared

        // 8b. System & Display Sleep Prevention (Keeps Screen & Mac Permanently Awake)
        if UserDefaults.standard.object(forKey: PrefKey.preventSystemSleep) as? Bool ?? true {
            GenieSleepPreventionManager.shared.enableSleepPrevention()
        }

        // 9. Instant File IPC Watcher for Autonomous Commands & External Triggers
        setupFileIPCWatcher()

        print("GENIE: applicationDidFinishLaunching completed")
    }

    private var fileIPCSource: DispatchSourceFileSystemObject?
    private func setupFileIPCWatcher() {
        let dirPath = NSString(string: "~/.gemini").expandingTildeInPath
        let triggerPath = "\(dirPath)/genie_action.trigger"

        // Ensure directory exists
        try? FileManager.default.createDirectory(atPath: dirPath, withIntermediateDirectories: true)

        let fd = open(dirPath, O_EVTONLY)
        guard fd >= 0 else { return }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: [.write],
            queue: DispatchQueue.global(qos: .userInitiated)
        )

        source.setEventHandler { [weak self] in
            guard FileManager.default.fileExists(atPath: triggerPath) else { return }
            do {
                let content = try String(contentsOfFile: triggerPath, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)
                try FileManager.default.removeItem(atPath: triggerPath)
                Task { @MainActor in
                    print("GENIE IPC Action received: \(content)")
                    if content == "toggle-canvas" || content == "canvas" {
                        FinderChatWindowManager.shared.toggle()
                    } else if content == "show-finder-chat" || content == "finder-chat" || content == "chat" || content == "mode-settings" || content == "settings" {
                        FinderChatWindowManager.shared.show()
                        NotificationCenter.default.post(name: NSNotification.Name("NexusSetWindowMode"), object: "combined")
                    } else if content == "mode-apps" || content == "apps" {
                        FinderChatWindowManager.shared.show()
                        NotificationCenter.default.post(name: NSNotification.Name("NexusSetWindowMode"), object: "combined")
                    } else if content == "toggle-finder-chat" {
                        FinderChatWindowManager.shared.toggle()
                    } else if content == "toggle-command-window" || content == "command-window" {
                        UnifiedCommandWindowManager.shared.toggle()
                    } else if content == "toggle-watch-dock" || content == "watch-dock" {
                        WorldClockViewModel.shared.dockSettings.isEnabled.toggle()
                    } else if content == "open-world-clock-settings" {
                        NotificationCenter.default.post(name: NSNotification.Name("NexusOpenSettingsInChat"), object: nil)
                        NotificationCenter.default.post(name: NSNotification.Name("NexusSelectSettingsTab"), object: UnifiedSettingsTab.worldClock)
                    } else if content.hasPrefix("pan ") {
                        let parts = content.split(separator: " ")
                        if parts.count >= 3, let dx = Double(parts[1]), let dy = Double(parts[2]) {
                            SpatialPlaneManager.shared.handleContinuousCanvasPanDelta(dx: CGFloat(dx), dy: CGFloat(dy))
                        }
                    } else if content.hasPrefix("land ") {
                        let parts = content.split(separator: " ")
                        if parts.count >= 2, let slot = Int(parts[1]) {
                            SpatialPlaneManager.shared.zoomInToSelectedDesktop(index: slot)
                        }
                    } else if content == "follow-cursor" {
                        SpatialPlaneManager.shared.screenWebpagePanMode = "Screen Follows Cursor"
                        SpatialPlaneManager.shared.cursorFollowPanningEnabled = true
                    } else if content == "hand-grab" {
                        SpatialPlaneManager.shared.screenWebpagePanMode = "Hand Drag & Scroll"
                        SpatialPlaneManager.shared.cursorFollowPanningEnabled = false
                    }
                }
            } catch {
                try? FileManager.default.removeItem(atPath: triggerPath)
            }
        }

        source.setCancelHandler {
            close(fd)
        }

        source.resume()
        self.fileIPCSource = source
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            if url.host == "canvas" || url.absoluteString.contains("toggle-canvas") {
                FinderChatWindowManager.shared.toggle()
            }
            GenieiMessageExtensionManager.shared.handleURL(url)
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        // Dismiss any open dropdown popover
        if menuBarPanel?.isVisible == true {
            dismissMenuBarPopover()
        }

        // Dock icon click: toggle Chat window directly (no applications pop up)
        FinderChatWindowManager.shared.toggle()

        let smokeOn = UserDefaults.standard.object(forKey: PrefKey.smokeEffectsEnabled) == nil ? true : UserDefaults.standard.bool(forKey: PrefKey.smokeEffectsEnabled)
        if smokeOn {
            let targetScreen = NSScreen.main ?? (NSScreen.screens.first ?? NSScreen())
            let panelSize = targetScreen.frame.size
            GenieSmokeEngine.shared.triggerBurst(
                origin: .dock,
                bounds: panelSize,
                style: "Royal Purple 🔮",
                count: 64
            )
        }
        return true
    }

    // MARK: - Menu Bar Popover Presentation & Sizing

    private var isDismissingPopover: Bool = false
    private var dismissWorkItem: DispatchWorkItem?

    func toggleMenuBarPopover() {
        if menuBarPanel?.isVisible == true {
            dismissMenuBarPopover()
        }
        FinderChatWindowManager.shared.toggle()
    }

    func showMenuBarPopover() {
        if menuBarPanel?.isVisible == true {
            dismissMenuBarPopover()
        }
        FinderChatWindowManager.shared.show()
    }

    func removeGlobalDismissMonitor() {
        if let g = globalDismissMonitor { NSEvent.removeMonitor(g); globalDismissMonitor = nil }
        if let l = localDismissMonitor { NSEvent.removeMonitor(l); localDismissMonitor = nil }
    }

    func dismissMenuBarPopover() {
        removeGlobalDismissMonitor()
        guard menuBarPanel.isVisible else { return }
        lastClosedTime = ProcessInfo.processInfo.systemUptime
        dismissWorkItem?.cancel()

        if isDismissingPopover {
            menuBarPanel.orderOut(nil)
            menuBarPanel.alphaValue = 1.0
            isDismissingPopover = false
            return
        }

        isDismissingPopover = true
        let isAppsMode = UserDefaults.standard.string(forKey: PrefKey.dropdownMode) == MenuBarDropdownMode.applications.rawValue
        let screen = menuBarPanel.screen ?? NSScreen.main ?? (NSScreen.screens.first ?? NSScreen())

        NotificationCenter.default.post(
            name: NSNotification.Name("NexusGenieDismiss"),
            object: ["origin": isAppsMode ? "bottom" : "glyph"]
        )

        let targetEndFrame: NSRect
        if isAppsMode {
            // Applications slides back DOWN to bottom edge
            targetEndFrame = NSRect(
                x: menuBarPanel.frame.origin.x,
                y: screen.visibleFrame.minY - menuBarPanel.frame.height,
                width: menuBarPanel.frame.width,
                height: menuBarPanel.frame.height
            )
        } else {
            // Chat slides back UP to top edge
            targetEndFrame = NSRect(
                x: menuBarPanel.frame.origin.x,
                y: screen.visibleFrame.maxY + 20,
                width: menuBarPanel.frame.width,
                height: menuBarPanel.frame.height
            )
        }

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.22
            ctx.timingFunction = CAMediaTimingFunction(controlPoints: 0.25, 0.1, 0.25, 1.0)
            menuBarPanel.animator().setFrame(targetEndFrame, display: true)
            menuBarPanel.animator().alphaValue = 0.0
        } completionHandler: { [weak self] in
            guard let self = self else { return }
            Task { @MainActor in
                self.menuBarPanel.orderOut(nil)
                self.menuBarPanel.alphaValue = 1.0
                self.isDismissingPopover = false
                NotificationCenter.default.post(name: NSNotification.Name("NexusGenieReset"), object: nil)
            }
        }
    }

    // MARK: - Dedicated Applications Settings & Preferences Hub
    public enum MenuBarAnchorSource {
        case leo
        case battery
    }
    public var activeAnchorSource: MenuBarAnchorSource = .battery

    func toggleMenuBarSettingsDropdown(targetTab: DropdownSidebarTab = .system) {
        if menuBarPanel.isVisible {
            if UserDefaults.standard.string(forKey: PrefKey.selectedStudioTab) == targetTab.rawValue &&
               UserDefaults.standard.string(forKey: PrefKey.dropdownMode) == MenuBarDropdownMode.settings.rawValue {
                dismissMenuBarPopover()
            } else {
                showMenuBarSettingsDropdown(targetTab: targetTab)
            }
        } else {
            showMenuBarSettingsDropdown(targetTab: targetTab)
        }
    }

    func showMenuBarSettingsDropdown(targetTab: DropdownSidebarTab = .system, targetScreen: NSScreen? = nil) {
        activeAnchorSource = (targetTab == .battery) ? .battery : .leo
        let mode: MenuBarDropdownMode = (targetTab == .applications) ? .applications : .settings
        UserDefaults.standard.set(mode.rawValue, forKey: PrefKey.dropdownMode)
        UserDefaults.standard.set(targetTab.rawValue, forKey: PrefKey.selectedStudioTab)
        NotificationCenter.default.post(name: NSNotification.Name("NexusSelectStudioTab"), object: targetTab.rawValue)
        NotificationCenter.default.post(name: NSNotification.Name("NexusSetDropdownMode"), object: mode.rawValue)
        showLegacyMenuBarPanel(targetScreen: targetScreen)
    }

    public func openSettingsInChatWindow() {
        FinderChatWindowManager.shared.show()
        if let st = WorkspaceTabManager.shared.tabs.first(where: { $0.type == .settings }) {
            WorkspaceTabManager.shared.selectTab(id: st.id)
        } else {
            WorkspaceTabManager.shared.createTab(type: .settings)
        }
        NotificationCenter.default.post(name: NSNotification.Name("NexusOpenSettingsInChat"), object: nil)
    }

    func showMenuBarApplicationsDropdown(anchor: MenuBarAnchorSource = .leo, targetScreen: NSScreen? = nil) {
        showMenuBarSettingsDropdown(targetTab: .battery, targetScreen: targetScreen)
    }

    func toggleMenuBarApplicationsDropdown(anchor: MenuBarAnchorSource = .leo) {
        toggleMenuBarSettingsDropdown(targetTab: .battery)
    }

    var applicationsSettingsPanel: NSPanel?

    func toggleApplicationsSettings(tab: UnifiedSettingsTab = .miniDock) {
        let dropdownTab: DropdownSidebarTab
        switch tab {
        case .chat: dropdownTab = .chat
        case .applications: dropdownTab = .applications
        case .miniDock: dropdownTab = .battery
        case .desktop: dropdownTab = .workspace
        case .soundAndSmoke: dropdownTab = .soundHaptics
        case .worldClock: dropdownTab = .workspace
        case .models, .livingGlass, .systemAccess, .huggingface, .generalAndPrivacy: dropdownTab = .privacy
        }
        toggleMenuBarSettingsDropdown(targetTab: dropdownTab)
    }

    func showApplicationsSettings(tab: UnifiedSettingsTab = .miniDock) {
        let dropdownTab: DropdownSidebarTab
        switch tab {
        case .chat: dropdownTab = .chat
        case .applications: dropdownTab = .applications
        case .miniDock: dropdownTab = .battery
        case .desktop: dropdownTab = .workspace
        case .soundAndSmoke: dropdownTab = .soundHaptics
        case .worldClock: dropdownTab = .workspace
        case .models, .livingGlass, .systemAccess, .huggingface, .generalAndPrivacy: dropdownTab = .privacy
        }
        showMenuBarSettingsDropdown(targetTab: dropdownTab)
    }

    func dismissApplicationsSettings() {
        dismissMenuBarPopover()
    }


    func showLegacyMenuBarPanel(targetScreen: NSScreen? = nil) {
        dismissWorkItem?.cancel()
        dismissWorkItem = nil
        isDismissingPopover = false
        let now = ProcessInfo.processInfo.systemUptime
        lastShownTime = now

        let mouseLoc = NSEvent.mouseLocation
        let screen: NSScreen
        if let explicit = targetScreen {
            screen = explicit
        } else if let hoveredScreen = NSScreen.screens.first(where: { NSMouseInRect(mouseLoc, $0.frame, false) }) {
            screen = hoveredScreen
        } else if let btn = statusItem?.button,
           let btnWin = btn.window,
           let btnScreen = btnWin.screen {
            screen = btnScreen
        } else {
            screen = NSScreen.main ?? (NSScreen.screens.first ?? NSScreen())
        }

        let size = currentPopoverSize()
        let targetFrame = calculateSnappedPopoverFrame(size: size, targetScreen: screen)
        appendDebugLog("SHOW_MENUBAR_POPOVER: targetFrame=\(targetFrame)\n")

        let genieEnabled = UserDefaults.standard.object(forKey: PrefKey.genieAnimEnabled) == nil ? false : UserDefaults.standard.bool(forKey: PrefKey.genieAnimEnabled)
        let originSetting = UserDefaults.standard.string(forKey: PrefKey.genieAnimOrigin) ?? "Top Glyph 🪔"
        let isDock = originSetting.contains("Dock")

        // Elevate window level over virtual top level command UI, custom menu bar, and status windows
        let popoverLevel = NSWindow.Level(Int(CGWindowLevelForKey(.popUpMenuWindow)) + 5)

        menuBarPanel.setFrame(targetFrame, display: true)
        menuBarPanel.alphaValue = 1.0
        menuBarPanel.level = popoverLevel
        menuBarPanel.hidesOnDeactivate = false
        menuBarPanel.orderFrontRegardless()
        menuBarPanel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        // Post summon notification for internal SwiftUI liquid Genie stretch & smoke burst
        var glyphXPercent: CGFloat = 0.50
        if let btn = statusItem?.button,
           let btnWin = btn.window,
           let btnFrame = btnWin.convertToScreen(btn.convert(btn.bounds, to: nil)) as NSRect? {
            let anchorX: CGFloat
            if activeAnchorSource == .battery {
                let battMid = MenuBarActionDispatcher.shared.batteryFrame.midX
                anchorX = (battMid > 0) ? (btnFrame.minX + battMid) : (btnFrame.maxX - 24)
            } else {
                let leoMid = MenuBarActionDispatcher.shared.leoFrame.midX
                anchorX = (leoMid > 0) ? (btnFrame.minX + leoMid) : (btnFrame.minX + 16)
            }
            let relativeX = anchorX - targetFrame.minX
            glyphXPercent = max(0.08, min(0.92, relativeX / targetFrame.width))
        }

        let isAppsMode = UserDefaults.standard.string(forKey: PrefKey.dropdownMode) == MenuBarDropdownMode.applications.rawValue
        NotificationCenter.default.post(
            name: NSNotification.Name("NexusGenieSummon"),
            object: [
                "origin": isAppsMode ? "bottom" : (isDock ? "dock" : "glyph"),
                "glyphXPercent": glyphXPercent,
                "genieEnabled": genieEnabled
            ] as [String : Any]
        )
    }

    private func logViewHierarchy() {
        guard let contentView = menuBarPanel.contentView else {
            appendDebugLog("CONTENTVIEW IS NIL!\n")
            return
        }
        appendDebugLog("CONTENTVIEW: \(contentView.className), frame=\(contentView.frame), subviews=\(contentView.subviews.count)\n")
        func dumpView(_ v: NSView, indent: Int) {
            guard indent < 6 else { return }
            let sp = String(repeating: "  ", count: indent)
            appendDebugLog("\(sp)\(v.className): frame=\(v.frame), isHidden=\(v.isHidden), alpha=\(v.alphaValue)\n")
            for sub in v.subviews {
                dumpView(sub, indent: indent + 1)
            }
        }
        dumpView(contentView, indent: 0)
    }

    func calculateSnappedPopoverFrame(size: NSSize, targetScreen: NSScreen? = nil) -> NSRect {
        let snapMode = UserDefaults.standard.string(forKey: PrefKey.menuBarSnapMode) ?? "icon"
        let isFolded = UserDefaults.standard.bool(forKey: PrefKey.isFoldedToBar)
        let isVelcroDetached = UserDefaults.standard.bool(forKey: PrefKey.isVelcroDetached)

        // Detect target screen (supporting detached placement on external screens)
        let screen: NSScreen
        if let explicit = targetScreen {
            screen = explicit
        } else if (isVelcroDetached || snapMode == "free"), let origin = customPopoverOrigin(),
           let target = NSScreen.screens.first(where: { $0.frame.contains(origin) }) {
            screen = target
        } else {
            let mouseLoc = NSEvent.mouseLocation
            screen = NSScreen.screens.first(where: { NSMouseInRect(mouseLoc, $0.frame, false) }) ?? NSScreen.main ?? (NSScreen.screens.first ?? NSScreen())
        }

        let visFrame = screen.visibleFrame
        let panelW = size.width
        let panelH = isFolded ? 44 : size.height

        let minX = visFrame.minX + 12
        let maxX = visFrame.maxX - panelW - 12
        let targetY = visFrame.maxY - panelH - 4 // Exactly 4pt below menu bar bottom

        // 0. Folded Bar Mode
        if isFolded {
            let barX: CGFloat
            switch snapMode {
            case "cutout", "notch":
                let notchX = screen.frame.midX - (panelW / 2.0)
                let hasNotch = screen.safeAreaInsets.top > 0
                let notchY = hasNotch ? (screen.frame.maxY - screen.safeAreaInsets.top - panelH) : targetY
                return NSRect(x: notchX, y: notchY, width: panelW, height: panelH)
            case "left": barX = minX
            case "icon":
                if let button = statusItem?.button,
                   let buttonWin = button.window,
                   buttonWin.screen == screen {
                    let buttonFrame = buttonWin.convertToScreen(button.convert(button.bounds, to: nil))
                    if buttonFrame.width > 0, buttonFrame.minX > 0 {
                        let iconMidX = buttonFrame.midX - (panelW / 2.0)
                        barX = max(minX, min(maxX, iconMidX))
                    } else {
                        barX = max(minX, min(maxX, screen.frame.midX - (panelW / 2.0)))
                    }
                } else {
                    barX = max(minX, min(maxX, screen.frame.midX - (panelW / 2.0)))
                }
            default:
                barX = max(minX, min(maxX, screen.frame.midX - (panelW / 2.0)))
            }
            return NSRect(x: barX, y: targetY, width: panelW, height: panelH)
        }

        // 1. Custom Dragged Position (Free / Detached)
        if (isVelcroDetached || snapMode == "free"), let origin = customPopoverOrigin() {
            let clampedX = max(minX, min(maxX, origin.x))
            let clampedY = max(visFrame.minY + 8, min(targetY, origin.y))
            return NSRect(x: clampedX, y: clampedY, width: panelW, height: panelH)
        }

        // 2. Notch / Cutout Snap Mode
        if snapMode == "cutout" || snapMode == "notch" {
            let notchX = screen.frame.midX - (panelW / 2.0)
            let hasNotch = screen.safeAreaInsets.top > 0
            let notchY = hasNotch ? (screen.frame.maxY - screen.safeAreaInsets.top - panelH) : targetY
            return NSRect(x: notchX, y: notchY, width: panelW, height: panelH)
        } else if snapMode == "left" {
            return NSRect(x: minX, y: targetY, width: panelW, height: panelH)
        }

        let isAppsMode = UserDefaults.standard.string(forKey: PrefKey.dropdownMode) == MenuBarDropdownMode.applications.rawValue
        let centeredX = max(minX, min(maxX, screen.frame.midX - (panelW / 2.0)))
        var targetX = centeredX
        if let button = statusItem?.button,
           let buttonWin = button.window,
           buttonWin.screen == screen {
            let buttonFrame = buttonWin.convertToScreen(button.convert(button.bounds, to: nil))
            if buttonFrame.width > 0, buttonFrame.minX > 0 {
                let iconMidX = buttonFrame.midX - (panelW / 2.0)
                targetX = max(minX, min(maxX, iconMidX))
            }
        }

        if isAppsMode {
            // Applications panel slides UP from bottom, meeting in the middle
            let appY = visFrame.minY + 12
            let appHeight = min(panelH, max(360, (visFrame.height / 2) - 16))
            return NSRect(x: targetX, y: appY, width: panelW, height: appHeight)
        } else {
            // Dropdown panel sits directly below menu bar
            return NSRect(x: targetX, y: targetY, width: panelW, height: panelH)
        }
    }

    func snapPopover(to mode: String) {
        UserDefaults.standard.set(mode, forKey: PrefKey.menuBarSnapMode)
        if mode != "free" {
            clearCustomPopoverOrigin()
        }
        let size = currentPopoverSize()
        let targetFrame = calculateSnappedPopoverFrame(size: size)
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.22
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            menuBarPanel.animator().setFrame(targetFrame, display: true)
        }
    }

    func currentPopoverSize() -> NSSize {
        let isFolded = UserDefaults.standard.bool(forKey: PrefKey.isFoldedToBar)
        if isFolded {
            let savedW = UserDefaults.standard.double(forKey: PrefKey.popoverCustomWidth)
            let w: CGFloat = (savedW >= 760 && savedW <= 2200) ? CGFloat(savedW) : 880
            return NSSize(width: w, height: 44)
        }

        return NSSize(width: 880, height: 560)
    }

    private func applyPopoverMobility() {
        menuBarPanel?.isMovable = true
        menuBarPanel?.isMovableByWindowBackground = true
    }

    private func savePopoverOriginIfUnlocked() {
        guard let panel = menuBarPanel else { return }
        let origin = panel.frame.origin
        UserDefaults.standard.set(Double(origin.x), forKey: PrefKey.popoverCustomX)
        UserDefaults.standard.set(Double(origin.y), forKey: PrefKey.popoverCustomY)
    }

    private func customPopoverOrigin() -> CGPoint? {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: PrefKey.popoverCustomX) != nil,
            defaults.object(forKey: PrefKey.popoverCustomY) != nil
        else { return nil }
        let x = defaults.double(forKey: PrefKey.popoverCustomX)
        let y = defaults.double(forKey: PrefKey.popoverCustomY)
        return CGPoint(x: x, y: y)
    }

    private func clearCustomPopoverOrigin() {
        UserDefaults.standard.removeObject(forKey: PrefKey.popoverCustomX)
        UserDefaults.standard.removeObject(forKey: PrefKey.popoverCustomY)
    }

    // MARK: - Dynamic Icon Animation & Rendering

    func startAnimation() {
        animTimer?.invalidate()
        let interval: TimeInterval = 0.08 // Sane ~12-15 FPS cadence for ambient status icon shimmer
        let timer = Timer(
            timeInterval: interval, target: self, selector: #selector(handleAnimationTick),
            userInfo: nil, repeats: true)
        RunLoop.main.add(timer, forMode: .common)
        animTimer = timer
    }

    @objc private func handleAnimationTick() {
        guard (statusItem?.isVisible == true && statusItem?.button?.window != nil) || CustomMenuBarManager.shared.isEnabled else {
            return
        }
        let speed = UserDefaults.standard.double(forKey: PrefKey.animSpeed)
        let baseSpeed = speed > 0 ? speed : 0.03
        let delta = CGFloat(baseSpeed * 0.45)
        self.phase = (self.phase + delta).truncatingRemainder(dividingBy: 1.0)
        self.renderIcon()
    }

    func setupStatusItemView() {
        guard let button = statusItem.button else { return }
        button.subviews.forEach { $0.removeFromSuperview() }
        button.image = nil
        button.title = ""
        button.target = nil
        button.action = nil
        button.clipsToBounds = false

        let showMiniDock = UserDefaults.standard.bool(forKey: PrefKey.showMiniDockInMenuBar)
        if showMiniDock {
            let stripView = MenuBarAppStripView()
            let hostingView = ClickableHostingView(rootView: stripView)
            hostingView.frame = button.bounds
            hostingView.autoresizingMask = [.width, .height]
            hostingView.clipsToBounds = false
            button.addSubview(hostingView)
        } else {
            statusItem.length = NSStatusItem.squareLength
            let glyph = UserDefaults.standard.string(forKey: PrefKey.statusIconGlyph)
                ?? UserDefaults.standard.string(forKey: PrefKey.statusIconStyle)
                ?? "Genie Lamp 🪔"
            button.image = StatusIconRenderer.generateGlyphImage(glyph: glyph, size: 18, phase: self.phase)
            button.imagePosition = .imageOnly
            button.target = self
            button.action = #selector(statusBarButtonClicked)
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }

    func updateStatusItemWidth(_ width: CGFloat) {
        guard let statusItem = statusItem else { return }
        if CustomMenuBarManager.shared.isEnabled {
            statusItem.isVisible = false
            statusItem.length = 0
            return
        }
        statusItem.isVisible = true
        statusItem.button?.clipsToBounds = false

        let showMiniDock = UserDefaults.standard.bool(forKey: PrefKey.showMiniDockInMenuBar)
        guard showMiniDock else {
            if statusItem.length != NSStatusItem.squareLength {
                statusItem.length = NSStatusItem.squareLength
            }
            return
        }

        let targetW = max(50, ceil(width) + 8)
        if abs(statusItem.length - targetW) > 0.5 {
            statusItem.length = targetW
        }
    }

    func renderIcon() {
        NotificationCenter.default.post(name: NSNotification.Name("NexusAnimTick"), object: self.phase)
        let showMiniDock = UserDefaults.standard.bool(forKey: PrefKey.showMiniDockInMenuBar)
        if !showMiniDock, let button = statusItem?.button {
            let glyph = UserDefaults.standard.string(forKey: PrefKey.statusIconGlyph)
                ?? UserDefaults.standard.string(forKey: PrefKey.statusIconStyle)
                ?? "Genie Lamp 🪔"
            button.image = StatusIconRenderer.generateGlyphImage(glyph: glyph, size: 18, phase: self.phase)
        }
    }

    @objc func statusBarButtonClicked(_ sender: NSStatusBarButton? = nil) {
        guard let button = sender ?? statusItem.button else { return }
        let showMiniDock = UserDefaults.standard.bool(forKey: PrefKey.showMiniDockInMenuBar)
        if showMiniDock {
            let screenMouse = NSEvent.mouseLocation
            let winPoint = button.window?.convertPoint(fromScreen: screenMouse) ?? screenMouse
            let localPoint = button.convert(winPoint, from: nil)
            appendDebugLog("STATUS_BTN_CLICKED: mouse=\(screenMouse), localPoint=\(localPoint)\n")
            let event = NSApp.currentEvent
            let isRight = event?.type == .rightMouseDown || event?.type == .rightMouseUp || (event?.modifierFlags.contains(.control) ?? false)
            MenuBarActionDispatcher.shared.dispatchClick(at: localPoint, in: button, isRightClick: isRight, event: event ?? NSEvent())
        } else {
            let event = NSApp.currentEvent
            let isRight = event?.type == .rightMouseDown
                || event?.type == .rightMouseUp
                || (event?.modifierFlags.contains(.control) ?? false)
            if isRight {
                MenuBarActionDispatcher.shared.showStatusMenu(in: button, event: event ?? NSEvent())
            } else {
                FinderChatWindowManager.shared.toggle()
            }
        }
    }

    private var isPinnedToDesktop: Bool {
        UserDefaults.standard.bool(forKey: PrefKey.pinToDesktopEnabled)
    }

    var isVelcroDetached: Bool {
        UserDefaults.standard.bool(forKey: PrefKey.isVelcroDetached)
    }

    func toggleVelcroDetach() {
        let newDetached = !isVelcroDetached
        UserDefaults.standard.set(newDetached, forKey: PrefKey.isVelcroDetached)
        if newDetached {
            HapticFeedback.playVelcroRip()
            UserDefaults.standard.set("free", forKey: PrefKey.menuBarSnapMode)
            let curFrame = menuBarPanel.frame
            let screen = menuBarPanel.screen ?? NSScreen.main ?? (NSScreen.screens.first ?? NSScreen())
            let visFrame = screen.visibleFrame
            let targetY = max(visFrame.minY + 40, curFrame.origin.y - 70)
            let newOrigin = CGPoint(x: curFrame.origin.x, y: targetY)
            UserDefaults.standard.set(Double(newOrigin.x), forKey: PrefKey.popoverCustomX)
            UserDefaults.standard.set(Double(newOrigin.y), forKey: PrefKey.popoverCustomY)
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.25
                ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
                menuBarPanel.animator().setFrameOrigin(newOrigin)
            }
        } else {
            HapticFeedback.playVelcroSnap()
            UserDefaults.standard.removeObject(forKey: PrefKey.popoverCustomX)
            UserDefaults.standard.removeObject(forKey: PrefKey.popoverCustomY)
            snapPopover(to: "icon")
        }
        NotificationCenter.default.post(name: NSNotification.Name("NexusVelcroStateChanged"), object: newDetached)
    }

    private var isStudioAlwaysOnTop: Bool {
        UserDefaults.standard.object(forKey: PrefKey.studioAlwaysOnTop) == nil
            ? true
            : UserDefaults.standard.bool(forKey: PrefKey.studioAlwaysOnTop)
    }

    private func setupMainMenu() {
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu(title: "Genie")
        appMenu.addItem(withTitle: "About Genie", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Hide Genie", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        let hideOthersItem = NSMenuItem(title: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthersItem.keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(hideOthersItem)
        appMenu.addItem(withTitle: "Show All", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Quit Genie", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        // Standard macOS Edit Menu (Guarantees ⌘V Paste, ⌘C Copy, ⌘X Cut, ⌘A Select All across all views)
        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        let redoItem = NSMenuItem(title: "Redo", action: Selector(("redo:")), keyEquivalent: "z")
        redoItem.keyEquivalentModifierMask = [.command, .shift]
        editMenu.addItem(redoItem)
        editMenu.addItem(NSMenuItem.separator())
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)

        NSApp.mainMenu = mainMenu
    }

    private func setupGlobalDismissMonitor() {
        if let g = globalDismissMonitor { NSEvent.removeMonitor(g) }
        if let l = localDismissMonitor { NSEvent.removeMonitor(l) }

        let dismissIfOutside: (CGPoint) -> Void = { [weak self] mouseLoc in
            guard let self = self else { return }
            let isMenuBarVisible = self.menuBarPanel.isVisible
            let isAppPanelVisible = self.applicationsSettingsPanel?.isVisible == true
            let isDesktopGridActive = DesktopWindowManager.shared.currentPage != 0
            let isFinderChatVisible = FinderChatWindowManager.shared.isVisible

            guard isMenuBarVisible || isAppPanelVisible || isDesktopGridActive || isFinderChatVisible else { return }
            guard !self.isPinnedToDesktop && !self.isVelcroDetached else { return }
            guard !MacDesktopsManager.shared.isSwitchingSpace else { return }
            let now = ProcessInfo.processInfo.systemUptime
            guard now - self.lastShownTime > 0.30 else { return }

            // 1. Click inside status bar button
            if let btn = self.statusItem?.button {
                let btnRect = btn.window?.convertToScreen(btn.convert(btn.bounds, to: nil)) ?? .zero
                if btnRect.insetBy(dx: -4, dy: -4).contains(mouseLoc) {
                    return
                }
            }

            // 2. Click inside menuBarPanel: active interaction, NEVER dismiss!
            if isMenuBarVisible && self.menuBarPanel.frame.contains(mouseLoc) {
                return
            }

            // 3. Click inside applicationsSettingsPanel: active interaction, NEVER dismiss!
            if let appPanel = self.applicationsSettingsPanel, appPanel.isVisible, appPanel.frame.contains(mouseLoc) {
                return
            }

            // Truly outside: retract all active chat dropdowns & windows!
            NotificationCenter.default.post(name: NSNotification.Name("NexusClose"), object: nil)
            NotificationCenter.default.post(name: NSNotification.Name("NexusDismissDesktopGrid"), object: nil)

            if isMenuBarVisible {
                self.dismissMenuBarPopover()
            }

            if isAppPanelVisible {
                self.dismissApplicationsSettings()
            }

            if isFinderChatVisible {
                FinderChatWindowManager.shared.hide()
            }
        }

        // 1. Clicks in other apps or Finder desktop
        globalDismissMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { _ in
            Task { @MainActor in
                guard !MacDesktopsManager.shared.isSwitchingSpace else { return }
                dismissIfOutside(NSEvent.mouseLocation)
            }
        }

        // 2. Clicks inside Genie's own windows or key events (e.g. Escape key to retract)
        localDismissMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown, .keyDown]) { [weak self] event in
            guard !MacDesktopsManager.shared.isSwitchingSpace else { return event }
            if event.type == .keyDown {
                if event.keyCode == 53 { // ESC key
                    Task { @MainActor [weak self] in
                        guard let self = self else { return }
                        if self.menuBarPanel.isVisible || self.applicationsSettingsPanel?.isVisible == true || DesktopWindowManager.shared.currentPage != 0 || FinderChatWindowManager.shared.isVisible {
                            NotificationCenter.default.post(name: NSNotification.Name("NexusClose"), object: nil)
                            NotificationCenter.default.post(name: NSNotification.Name("NexusDismissDesktopGrid"), object: nil)
                            self.dismissMenuBarPopover()
                            self.dismissApplicationsSettings()
                            FinderChatWindowManager.shared.hide()
                        }
                    }
                }
                return event
            }
            dismissIfOutside(NSEvent.mouseLocation)
            return event
        }

        // Clicks inside Genie settings panel or popover are retained; clicks outside dismiss cleanly.
    }

    private func setupPermanentKeyMonitor() {
        guard permanentKeyMonitor == nil else { return }
        permanentKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
            // 1. ⌘Q: Terminate Genie immediately from any active internal window
            if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers?.lowercased() == "q" {
                NSApp.terminate(nil)
                return nil
            }
            // 2. Escape key (keyCode 53): retract overlays, panels, or return to Desktop 0
            if event.keyCode == 53 {
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    var didDismiss = false
                    if FinderChatWindowManager.shared.isVisible {
                        FinderChatWindowManager.shared.hide()
                        didDismiss = true
                    }
                    if self.menuBarPanel.isVisible {
                        self.dismissMenuBarPopover()
                        didDismiss = true
                    }
                    if let appPanel = self.applicationsSettingsPanel, appPanel.isVisible {
                        self.dismissApplicationsSettings()
                        didDismiss = true
                    }
                    if DesktopWindowManager.shared.currentPage != 0 {
                        DesktopWindowManager.shared.setPage(0)
                        didDismiss = true
                    }
                    if SpatialPlaneManager.shared.isZoomedOut {
                        SpatialPlaneManager.shared.zoomInToSelectedDesktop()
                        didDismiss = true
                    }
                    if didDismiss {
                        NotificationCenter.default.post(name: NSNotification.Name("NexusClose"), object: nil)
                        NotificationCenter.default.post(name: NSNotification.Name("NexusDismissDesktopGrid"), object: nil)
                    }
                }
                return nil
            }
            return event
        }
    }

    private func setupNotificationObservers() {
        let nc = NotificationCenter.default

        nc.addObserver(forName: NSNotification.Name("NexusClose"), object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in self?.dismissMenuBarPopover() }
        }

        nc.addObserver(forName: NSNotification.Name("NexusOpenSettings"), object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in self?.showMenuBarSettingsDropdown(targetTab: .battery) }
        }

        nc.addObserver(forName: NSNotification.Name("NexusToggleSettingsDropdown"), object: nil, queue: .main) { [weak self] notif in
            let tab = (notif.object as? String).flatMap { DropdownSidebarTab(caseInsensitive: $0) } ?? .battery
            Task { @MainActor [weak self] in self?.toggleMenuBarSettingsDropdown(targetTab: tab) }
        }

        nc.addObserver(forName: NSNotification.Name("NexusBatteryEnabledChanged"), object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in self?.renderIcon() }
        }

        nc.addObserver(forName: NSNotification.Name("NexusIconStyleChanged"), object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in self?.renderIcon() }
        }

        nc.addObserver(forName: NSNotification.Name("NexusAnimSpeedChanged"), object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in self?.startAnimation() }
        }

        nc.addObserver(forName: NSNotification.Name("NexusRefreshApps"), object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in await self?.appModel.load() }
        }

        nc.addObserver(forName: NSNotification.Name("NexusCustomMenuBarToggled"), object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in
                CustomMenuBarManager.shared.rebuildWindows()
                self?.statusItem?.isVisible = !CustomMenuBarManager.shared.isEnabled
            }
        }

        nc.addObserver(forName: NSNotification.Name("NexusCompactModeChanged"), object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, self.menuBarPanel.isVisible else { return }
                let newSize = self.currentPopoverSize()
                let newFrame = self.calculateSnappedPopoverFrame(size: newSize)
                NSAnimationContext.runAnimationGroup { ctx in
                    ctx.duration = 0.28
                    ctx.timingFunction = CAMediaTimingFunction(controlPoints: 0.16, 1.0, 0.3, 1.0)
                    self.menuBarPanel.animator().setFrame(newFrame, display: true)
                }
            }
        }

        nc.addObserver(forName: NSNotification.Name("NexusWindowSizeModeChanged"), object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, self.menuBarPanel.isVisible else { return }
                let newSize = self.currentPopoverSize()
                let newFrame = self.calculateSnappedPopoverFrame(size: newSize)
                NSAnimationContext.runAnimationGroup { ctx in
                    ctx.duration = 0.28
                    ctx.timingFunction = CAMediaTimingFunction(controlPoints: 0.16, 1.0, 0.3, 1.0)
                    self.menuBarPanel.animator().setFrame(newFrame, display: true)
                }
            }
        }

        nc.addObserver(forName: NSNotification.Name("NexusFoldedStateChanged"), object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, self.menuBarPanel.isVisible else { return }
                let newSize = self.currentPopoverSize()
                let targetFrame = self.calculateSnappedPopoverFrame(size: newSize)
                NSAnimationContext.runAnimationGroup { ctx in
                    ctx.duration = 0.28
                    ctx.timingFunction = CAMediaTimingFunction(controlPoints: 0.16, 1.0, 0.3, 1.0)
                    self.menuBarPanel.animator().setFrame(targetFrame, display: true)
                }
            }
        }

        nc.addObserver(forName: NSNotification.Name("NexusWillSwitchSpace"), object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, self.menuBarPanel.isVisible else { return }
                self.menuBarPanel.orderFrontRegardless()
            }
        }

        nc.addObserver(forName: NSNotification.Name("NexusDidSwitchSpace"), object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, self.menuBarPanel.isVisible else { return }
                self.menuBarPanel.orderFrontRegardless()
                self.menuBarPanel.makeKeyAndOrderFront(nil)
            }
        }

        nc.addObserver(forName: NSNotification.Name("NexusResetPopoverPosition"), object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.clearCustomPopoverOrigin()
                if self.menuBarPanel.isVisible {
                    self.showLegacyMenuBarPanel()
                }
            }
        }

        nc.addObserver(forName: NSNotification.Name("NexusPopoverUnlockChanged"), object: nil, queue: .main) { [weak self] notification in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if let enabled = notification.object as? Bool {
                    UserDefaults.standard.set(enabled, forKey: PrefKey.popoverFreePositionEnabled)
                }
                self.applyPopoverMobility()
                if !self.isPopoverUnlocked {
                    self.clearCustomPopoverOrigin()
                    if self.menuBarPanel.isVisible {
                        self.showLegacyMenuBarPanel()
                    }
                } else {
                    self.savePopoverOriginIfUnlocked()
                }
            }
        }

        nc.addObserver(forName: NSNotification.Name("NexusResetPopoverPosition"), object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.clearCustomPopoverOrigin()
                UserDefaults.standard.removeObject(forKey: PrefKey.popoverCustomWidth)
                UserDefaults.standard.removeObject(forKey: PrefKey.popoverCustomHeight)
                if self.menuBarPanel.isVisible {
                    self.showLegacyMenuBarPanel()
                }
            }
        }

        nc.addObserver(forName: NSNotification.Name("NexusPinToDesktopToggled"), object: nil, queue: .main) { [weak self] notif in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if let isPinned = notif.object as? Bool {
                    UserDefaults.standard.set(isPinned, forKey: PrefKey.pinToDesktopEnabled)
                }
                self.menuBarPanel.level = NSWindow.Level(Int(CGWindowLevelForKey(.popUpMenuWindow)) + 5)
            }
        }

        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if self.menuBarPanel.isVisible {
                    self.menuBarPanel.orderFrontRegardless()
                }
                CustomMenuBarManager.shared.updateVisibility()
            }
        }

        nc.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if self.menuBarPanel.isVisible {
                    let size = self.currentPopoverSize()
                    let newFrame = self.calculateSnappedPopoverFrame(size: size)
                    self.menuBarPanel.setFrame(newFrame, display: true)
                }
            }
        }

        nc.addObserver(forName: NSNotification.Name("NexusSnapPopover"), object: nil, queue: .main) { [weak self] notif in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                let mode = (notif.object as? String) ?? "right"
                self.snapPopover(to: mode)
            }
        }

        nc.addObserver(forName: NSWindow.didMoveNotification, object: menuBarPanel, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in self?.savePopoverOriginIfUnlocked() }
        }

        nc.addObserver(forName: NSNotification.Name("NexusBatteryStateChanged"), object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in self?.renderIcon() }
        }

        // Distributed Notifications (allowing CLI or script triggers with instant background delivery)
        let dnc = DistributedNotificationCenter.default()
        dnc.addObserver(self, selector: #selector(handleDistOpen(_:)), name: NSNotification.Name("com.user.nexus.open"), object: nil, suspensionBehavior: .deliverImmediately)
        dnc.addObserver(self, selector: #selector(handleDistGrid(_:)), name: NSNotification.Name("com.user.nexus.grid"), object: nil, suspensionBehavior: .deliverImmediately)
        dnc.addObserver(self, selector: #selector(handleDistSummon(_:)), name: NSNotification.Name("com.user.nexus.summon"), object: nil, suspensionBehavior: .deliverImmediately)
        dnc.addObserver(self, selector: #selector(handleDistTab(_:)), name: NSNotification.Name("com.user.nexus.tab"), object: nil, suspensionBehavior: .deliverImmediately)
        dnc.addObserver(self, selector: #selector(handleDistPopover(_:)), name: NSNotification.Name("com.user.nexus.popover"), object: nil, suspensionBehavior: .deliverImmediately)
        dnc.addObserver(self, selector: #selector(handleDistToggleSettings(_:)), name: NSNotification.Name("com.user.nexus.toggleSettings"), object: nil, suspensionBehavior: .deliverImmediately)
        dnc.addObserver(self, selector: #selector(handleDistTestClick(_:)), name: NSNotification.Name("com.user.nexus.testClickAtX"), object: nil, suspensionBehavior: .deliverImmediately)

        // Darwin System-Wide Notifications (Instant rock-solid IPC from CLI / notifyutil)
        let darwinCenter = CFNotificationCenterGetDarwinNotifyCenter()
        CFNotificationCenterAddObserver(
            darwinCenter,
            Unmanaged.passUnretained(self).toOpaque(),
            { _, observer, name, _, _ in
                guard let observer = observer else { return }
                let appDelegate = Unmanaged<AppDelegate>.fromOpaque(observer).takeUnretainedValue()
                DispatchQueue.main.async {
                    if let n = name?.rawValue as String? {
                        if n == "com.user.nexus.open" || n == "com.user.nexus.openBattery" {
                            appDelegate.showMenuBarApplicationsDropdown(anchor: .battery)
                        } else if n == "com.user.nexus.openGenie" {
                            appDelegate.showMenuBarApplicationsDropdown(anchor: .leo)
                        } else if n == "com.user.nexus.toggle" {
                            appDelegate.toggleMenuBarPopover()
                        }
                    }
                }
            },
            "com.user.nexus.open" as CFString,
            nil,
            .deliverImmediately
        )
        CFNotificationCenterAddObserver(
            darwinCenter,
            Unmanaged.passUnretained(self).toOpaque(),
            { _, observer, name, _, _ in
                guard let observer = observer else { return }
                let appDelegate = Unmanaged<AppDelegate>.fromOpaque(observer).takeUnretainedValue()
                DispatchQueue.main.async {
                    if appDelegate.menuBarPanel.isVisible {
                        appDelegate.dismissMenuBarPopover()
                    }
                    NotificationCenter.default.post(name: NSNotification.Name("NexusToggleDesktopGrid"), object: nil)
                }
            },
            "com.user.nexus.openGenie" as CFString,
            nil,
            .deliverImmediately
        )
        CFNotificationCenterAddObserver(
            darwinCenter,
            Unmanaged.passUnretained(self).toOpaque(),
            { _, observer, name, _, _ in
                guard let observer = observer else { return }
                let appDelegate = Unmanaged<AppDelegate>.fromOpaque(observer).takeUnretainedValue()
                DispatchQueue.main.async {
                    if appDelegate.menuBarPanel.isVisible {
                        appDelegate.dismissMenuBarPopover()
                    }
                    NotificationCenter.default.post(name: NSNotification.Name("NexusToggleDesktopGrid"), object: nil)
                }
            },
            "com.user.nexus.openBattery" as CFString,
            nil,
            .deliverImmediately
        )
        CFNotificationCenterAddObserver(
            darwinCenter,
            Unmanaged.passUnretained(self).toOpaque(),
            { _, observer, _, _, _ in
                guard let observer = observer else { return }
                let appDelegate = Unmanaged<AppDelegate>.fromOpaque(observer).takeUnretainedValue()
                DispatchQueue.main.async {
                    appDelegate.toggleMenuBarPopover()
                }
            },
            "com.user.nexus.toggle" as CFString,
            nil,
            .deliverImmediately
        )
    }

    @objc private func handleDistOpen(_ notification: Notification) {
        Task { @MainActor in
            appendDebugLog("HANDLE_DIST_OPEN_CALLED\n")
            self.showMenuBarPopover()
        }
    }

    @objc private func handleDistGrid(_ notification: Notification) {
        Task { @MainActor in
            NotificationCenter.default.post(name: NSNotification.Name("NexusToggleDesktopGrid"), object: nil)
        }
    }

    @objc private func handleDistSummon(_ notification: Notification) {
        Task { @MainActor in
            NotificationCenter.default.post(name: NSNotification.Name("NexusThreeFingerDragUp"), object: nil)
        }
    }

    @objc private func handleDistTab(_ notification: Notification) {
        Task { @MainActor in
            let tabName = notification.object as? String ?? (notification.userInfo?["tab"] as? String) ?? "Battery"
            let targetTab = DropdownSidebarTab(caseInsensitive: tabName)
            self.showMenuBarSettingsDropdown(targetTab: targetTab)
        }
    }

    @objc private func handleDistPopover(_ notification: Notification) {
        Task { @MainActor in
            self.statusBarButtonClicked()
        }
    }

    @objc private func handleDistToggleSettings(_ notification: Notification) {
        Task { @MainActor in
            self.toggleApplicationsSettings()
        }
    }

    @objc private func handleDistTestClick(_ notification: Notification) {
        Task { @MainActor in
            guard let btn = self.statusItem?.button else { return }
            let xStr = notification.object as? String ?? "108"
            let x = Double(xStr) ?? 108.0
            let pt = NSPoint(x: x, y: 12.0)
            MenuBarActionDispatcher.shared.dispatchClick(at: pt, in: btn, isRightClick: false, event: NSEvent())
        }
    }

    // MARK: - Application Termination Handlers (Fast, Non-Blocking, Clean Shutdown)
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        return .terminateNow
    }

    func applicationWillTerminate(_ notification: Notification) {
        print("GENIE: applicationWillTerminate entered — invalidating all timers and monitors")
        animTimer?.invalidate()
        animTimer = nil
        fileIPCSource?.cancel()
        fileIPCSource = nil
        removeGlobalDismissMonitor()
        if let p = permanentKeyMonitor {
            NSEvent.removeMonitor(p)
            permanentKeyMonitor = nil
        }
        GenieSleepPreventionManager.shared.disableSleepPrevention()
        GenieiMessageExtensionManager.shared.stopWatcher()
        GeniePhoneBridgeManager.shared.stopServer()
        DesktopWindowManager.shared.cleanup()
    }
}
