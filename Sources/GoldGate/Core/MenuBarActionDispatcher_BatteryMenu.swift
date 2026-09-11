import AppKit
import Foundation

extension MenuBarActionDispatcher {
    public func showStatusMenu(in view: NSView, event: NSEvent) {
        let menu = makeCompleteBatteryPopoutMenu()
        NSMenu.popUpContextMenu(menu, with: event, for: view)
    }

    public func makeCompleteBatteryPopoutMenu() -> NSMenu {
        let menu = NSMenu(title: "Battery & Quick Launcher")
        let lang = UserDefaults.standard.string(forKey: PrefKey.appLanguage) ?? "English (US)"
        
        // ── 1. Live Battery Hardware & Power Header ──
        let bm = BatteryMonitor.shared
        bm.refresh()
        let pct = bm.batteryPct ?? 100
        let isCharging = bm.isCharging
        let isPlugged = bm.isPluggedIn
        let isCharged = bm.isCharged
        
        let powerIcon: String
        let powerStatusText: String
        if isCharging {
            powerIcon = "battery.100.bolt"
            powerStatusText = "\(pct)% — Charging on Power Adapter ⚡"
        } else if isPlugged && isCharged {
            powerIcon = "powerplug.fill"
            powerStatusText = "\(pct)% — Fully Charged (Plugged In)"
        } else if isPlugged {
            powerIcon = "powerplug.fill"
            powerStatusText = "\(pct)% — Power Adapter Connected 🔌"
        } else {
            powerIcon = pct <= 20 ? "battery.25" : (pct <= 50 ? "battery.50" : "battery.100")
            powerStatusText = "\(pct)% — On Battery Power 🔋"
        }
        
        let headerItem = NSMenuItem(title: powerStatusText, action: nil, keyEquivalent: "")
        headerItem.image = NSImage(systemSymbolName: powerIcon, accessibilityDescription: nil)
        headerItem.isEnabled = false
        menu.addItem(headerItem)
        
        // macOS Battery Settings Link
        let macBatterySettingsItem = NSMenuItem(
            title: "macOS Battery Settings...",
            action: #selector(openMacOSBatterySettings),
            keyEquivalent: ""
        )
        macBatterySettingsItem.image = NSImage(systemSymbolName: "gearshape.2", accessibilityDescription: nil)
        macBatterySettingsItem.target = self
        menu.addItem(macBatterySettingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // ── 2. All Running Applications Submenu ──
        let runningAppsMenu = NSMenu(title: "Running Applications")
        let runningApps = NSWorkspace.shared.runningApplications.filter {
            $0.activationPolicy == .regular && !$0.isTerminated
        }
        
        for app in runningApps {
            let appName = app.localizedName ?? "Application"
            let appItem = NSMenuItem(
                title: appName,
                action: #selector(activateRunningAppFromMenu(_:)),
                keyEquivalent: ""
            )
            appItem.target = self
            appItem.representedObject = app
            if let icon = app.icon {
                let resized = NSImage(size: NSSize(width: 16, height: 16))
                resized.lockFocus()
                icon.draw(in: NSRect(x: 0, y: 0, width: 16, height: 16))
                resized.unlockFocus()
                appItem.image = resized
            } else {
                appItem.image = NSImage(systemSymbolName: "app.fill", accessibilityDescription: nil)
            }
            if app.isActive {
                appItem.state = NSControl.StateValue.on
            }
            runningAppsMenu.addItem(appItem)
        }
        
        if runningApps.isEmpty {
            let emptyItem = NSMenuItem(title: "No Active Apps", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            runningAppsMenu.addItem(emptyItem)
        }
        
        let runningAppsSubItem = NSMenuItem(title: "Running Applications (\(runningApps.count)) ❯", action: nil, keyEquivalent: "")
        runningAppsSubItem.image = NSImage(systemSymbolName: "macwindow.on.rectangle", accessibilityDescription: nil)
        runningAppsSubItem.submenu = runningAppsMenu
        menu.addItem(runningAppsSubItem)
        
        // ── 3. Mini Dock & ALL Pinned Apps Submenu ──
        let pinnedAppsMenu = NSMenu(title: "Mini Dock & Pinned Apps")
        var dockItems = DockAndDesktopManager.shared.dockItems
        if dockItems.isEmpty {
            dockItems = DockAndDesktopManager.loadSystemDockApps()
        }
        
        for item in dockItems {
            let dockMenuItem = NSMenuItem(
                title: item.name,
                action: #selector(launchDockAppFromMenu(_:)),
                keyEquivalent: ""
            )
            dockMenuItem.target = self
            dockMenuItem.representedObject = item
            if let img = item.icon {
                let resized = NSImage(size: NSSize(width: 16, height: 16))
                resized.lockFocus()
                img.draw(in: NSRect(x: 0, y: 0, width: 16, height: 16))
                resized.unlockFocus()
                dockMenuItem.image = resized
            } else {
                dockMenuItem.image = NSImage(systemSymbolName: "app.dashed", accessibilityDescription: nil)
            }
            if item.isRunning {
                dockMenuItem.state = NSControl.StateValue.on
            }
            pinnedAppsMenu.addItem(dockMenuItem)
        }
        
        if dockItems.isEmpty {
            let emptyItem = NSMenuItem(title: "No Pinned Apps", action: nil, keyEquivalent: "")
            emptyItem.isEnabled = false
            pinnedAppsMenu.addItem(emptyItem)
        }
        
        let pinnedAppsSubItem = NSMenuItem(title: "Mini Dock & Pinned Apps (\(dockItems.count)) ❯", action: nil, keyEquivalent: "")
        pinnedAppsSubItem.image = NSImage(systemSymbolName: "menubar.dock.rectangle", accessibilityDescription: nil)
        pinnedAppsSubItem.submenu = pinnedAppsMenu
        menu.addItem(pinnedAppsSubItem)
        
        // ── 4. Folders & Stacks Submenu ──
        let foldersMenu = NSMenu(title: "Folders & Stacks")
        var dockFolders = DockAndDesktopManager.shared.dockFolders
        if dockFolders.isEmpty {
            dockFolders = DockAndDesktopManager.loadSystemDockFolders()
        }
        
        for folder in dockFolders {
            let fItem = NSMenuItem(
                title: folder.name,
                action: #selector(openDockFolderFromMenu(_:)),
                keyEquivalent: ""
            )
            fItem.target = self
            fItem.representedObject = folder
            if let icon = folder.icon {
                let resized = NSImage(size: NSSize(width: 16, height: 16))
                resized.lockFocus()
                icon.draw(in: NSRect(x: 0, y: 0, width: 16, height: 16))
                resized.unlockFocus()
                fItem.image = resized
            } else {
                fItem.image = NSImage(systemSymbolName: "folder.fill", accessibilityDescription: nil)
            }
            foldersMenu.addItem(fItem)
        }
        
        let commonFolders: [(name: String, url: URL?, icon: String)] = [
            ("Downloads", FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first, "arrow.down.circle"),
            ("Documents", FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first, "doc.fill"),
            ("Desktop", FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first, "desktopcomputer"),
            ("Applications", URL(fileURLWithPath: "/Applications"), "app.badge")
        ]
        
        var addedFolderSeparator = false
        for cf in commonFolders {
            guard let url = cf.url else { continue }
            if dockFolders.contains(where: { $0.folderURL.path == url.path }) { continue }
            if !addedFolderSeparator && !dockFolders.isEmpty {
                foldersMenu.addItem(NSMenuItem.separator())
                addedFolderSeparator = true
            }
            let cItem = NSMenuItem(
                title: cf.name,
                action: #selector(openFolderURLFromMenu(_:)),
                keyEquivalent: ""
            )
            cItem.target = self
            cItem.representedObject = url
            cItem.image = NSImage(systemSymbolName: cf.icon, accessibilityDescription: nil)
            foldersMenu.addItem(cItem)
        }
        
        let foldersSubItem = NSMenuItem(title: "Folders & Stacks ❯", action: nil, keyEquivalent: "")
        foldersSubItem.image = NSImage(systemSymbolName: "folder.fill", accessibilityDescription: nil)
        foldersSubItem.submenu = foldersMenu
        menu.addItem(foldersSubItem)
        
        // ── 5. All Applications Catalog Submenu ──
        let allApps = Self.loadQuickInstalledApps()
        if !allApps.isEmpty {
            let allAppsMenu = NSMenu(title: "All Applications")
            if allApps.count <= 28 {
                for app in allApps {
                    let item = NSMenuItem(
                        title: app.name,
                        action: #selector(launchAppURLFromMenu(_:)),
                        keyEquivalent: ""
                    )
                    item.target = self
                    item.representedObject = app.url
                    let resized = NSImage(size: NSSize(width: 16, height: 16))
                    resized.lockFocus()
                    app.icon.draw(in: NSRect(x: 0, y: 0, width: 16, height: 16))
                    resized.unlockFocus()
                    item.image = resized
                    allAppsMenu.addItem(item)
                }
            } else {
                let groups: [(title: String, range: ClosedRange<Character>)] = [
                    ("A – F", "a"..."f"),
                    ("G – L", "g"..."l"),
                    ("M – R", "m"..."r"),
                    ("S – Z", "s"..."z")
                ]
                for grp in groups {
                    let groupApps = allApps.filter {
                        guard let first = $0.name.lowercased().first else { return false }
                        return grp.range.contains(first)
                    }
                    if !groupApps.isEmpty {
                        let subMenu = NSMenu(title: grp.title)
                        for app in groupApps {
                            let item = NSMenuItem(
                                title: app.name,
                                action: #selector(launchAppURLFromMenu(_:)),
                                keyEquivalent: ""
                            )
                            item.target = self
                            item.representedObject = app.url
                            let resized = NSImage(size: NSSize(width: 16, height: 16))
                            resized.lockFocus()
                            app.icon.draw(in: NSRect(x: 0, y: 0, width: 16, height: 16))
                            resized.unlockFocus()
                            item.image = resized
                            subMenu.addItem(item)
                        }
                        let grpItem = NSMenuItem(title: "\(grp.title) (\(groupApps.count)) ❯", action: nil, keyEquivalent: "")
                        grpItem.image = NSImage(systemSymbolName: "app.dashed", accessibilityDescription: nil)
                        grpItem.submenu = subMenu
                        allAppsMenu.addItem(grpItem)
                    }
                }
            }
            let allAppsSubItem = NSMenuItem(title: "All Applications (\(allApps.count)) ❯", action: nil, keyEquivalent: "")
            allAppsSubItem.image = NSImage(systemSymbolName: "square.grid.2x2", accessibilityDescription: nil)
            allAppsSubItem.submenu = allAppsMenu
            menu.addItem(allAppsSubItem)
        }
        
        menu.addItem(NSMenuItem.separator())
        
        // ── 6. Mini Dock Display Options Submenu ──
        let dockOptions = NSMenu(title: "Mini Dock Display Options")
        let activeAppsOnly = UserDefaults.standard.bool(forKey: PrefKey.dockActiveAppsOnly)
        let showFolders = UserDefaults.standard.object(forKey: PrefKey.dockShowFolderStacks) == nil ? true : UserDefaults.standard.bool(forKey: PrefKey.dockShowFolderStacks)
        let showFinder = UserDefaults.standard.object(forKey: PrefKey.dockAlwaysShowFinder) as? Bool ?? true
        let showTrash = UserDefaults.standard.object(forKey: PrefKey.dockAlwaysShowTrash) as? Bool ?? true

        let allPinnedItem = NSMenuItem(
            title: "Show All Pinned Dock Apps",
            action: #selector(toggleDockActiveAppsOnlyMenu),
            keyEquivalent: ""
        )
        allPinnedItem.target = self
        allPinnedItem.state = (!activeAppsOnly) ? NSControl.StateValue.on : NSControl.StateValue.off
        dockOptions.addItem(allPinnedItem)

        let activeAppsOnlyItem = NSMenuItem(
            title: "Active Applications Only",
            action: #selector(toggleDockActiveAppsOnlyMenu),
            keyEquivalent: ""
        )
        activeAppsOnlyItem.target = self
        activeAppsOnlyItem.state = activeAppsOnly ? NSControl.StateValue.on : NSControl.StateValue.off
        dockOptions.addItem(activeAppsOnlyItem)

        dockOptions.addItem(NSMenuItem.separator())

        let showFoldersItem = NSMenuItem(
            title: "Show Folder Stacks in Mini Dock",
            action: #selector(toggleDockFoldersMenu),
            keyEquivalent: ""
        )
        showFoldersItem.target = self
        showFoldersItem.state = showFolders ? NSControl.StateValue.on : NSControl.StateValue.off
        dockOptions.addItem(showFoldersItem)

        let showFinderItem = NSMenuItem(
            title: "Always Show Finder",
            action: #selector(toggleDockFinderMenu),
            keyEquivalent: ""
        )
        showFinderItem.target = self
        showFinderItem.state = showFinder ? NSControl.StateValue.on : NSControl.StateValue.off
        dockOptions.addItem(showFinderItem)

        let showTrashItem = NSMenuItem(
            title: "Always Show Trash",
            action: #selector(toggleDockTrashMenu),
            keyEquivalent: ""
        )
        showTrashItem.target = self
        showTrashItem.state = showTrash ? NSControl.StateValue.on : NSControl.StateValue.off
        dockOptions.addItem(showTrashItem)

        dockOptions.addItem(NSMenuItem.separator())

        let showInMenuBar = UserDefaults.standard.bool(forKey: PrefKey.showMiniDockInMenuBar)
        let showInMenuBarItem = NSMenuItem(
            title: "Show Mini Dock in Menu Bar",
            action: #selector(toggleShowMiniDockInMenuBar),
            keyEquivalent: ""
        )
        showInMenuBarItem.target = self
        showInMenuBarItem.state = showInMenuBar ? NSControl.StateValue.on : NSControl.StateValue.off
        dockOptions.addItem(showInMenuBarItem)

        let dockOptionsSubItem = NSMenuItem(title: "Mini Dock Display Options ❯", action: nil, keyEquivalent: "")
        dockOptionsSubItem.image = NSImage(systemSymbolName: "slider.horizontal.3", accessibilityDescription: nil)
        dockOptionsSubItem.submenu = dockOptions
        menu.addItem(dockOptionsSubItem)

        menu.addItem(NSMenuItem.separator())
        
        // ── 4. Battery Appearance & Cycling ──
        let cycleItem = NSMenuItem(title: "Next Battery Style ❯", action: #selector(cycleNextBatteryStyle), keyEquivalent: "")
        cycleItem.image = NSImage(systemSymbolName: "arrow.triangle.2.circlepath", accessibilityDescription: nil)
        cycleItem.target = self
        menu.addItem(cycleItem)
        
        // Complete Battery Style Categories Submenu
        let allStylesMenu = NSMenu(title: "Battery Style")
        let currentStyle = UserDefaults.standard.string(forKey: PrefKey.batteryStyle)
            ?? UserDefaults.standard.string(forKey: PrefKey.iconStyle)
            ?? "Classic Apple Battery"
            
        let categorizedStyles: [(category: String, icon: String, styles: [String])] = [
            ("Apple & Clean", "applelogo", [
                "Classic Apple Battery", "Apple Minimal", "Minimal Pill", "VisionOS Pill", "Battery Tube Fill"
            ]),
            ("Digital & Neon", "bolt.horizontal.fill", [
                "Cyber Neon Digits", "10-Bar Equalizer", "Digital Clock 7-Segment", "Bold Minimal Digital", "Glass Neon Bar", "Retro Segmented LED"
            ]),
            ("Circular & Gauge", "gauge.medium", [
                "Circular Dual Arc", "Circular Gauge", "Compact Ring Indicator", "Holographic Arc", "Speedometer Dial"
            ]),
            ("Creative & Dynamic", "sparkles", [
                "DNA Helix", "Liquid Wave", "Pixel Heart", "Matrix Terminal", "Aura Glow", "Solar Flare"
            ])
        ]
        
        for cat in categorizedStyles {
            let subCatMenu = NSMenu(title: cat.category)
            for style in cat.styles {
                let isCurrent = (currentStyle == style)
                let item = NSMenuItem(
                    title: style,
                    action: #selector(selectBatteryStyleItem(_:)),
                    keyEquivalent: ""
                )
                item.target = self
                item.representedObject = style
                item.state = isCurrent ? NSControl.StateValue.on : NSControl.StateValue.off
                subCatMenu.addItem(item)
            }
            let subCatItem = NSMenuItem(title: cat.category, action: nil, keyEquivalent: "")
            subCatItem.image = NSImage(systemSymbolName: cat.icon, accessibilityDescription: nil)
            subCatItem.submenu = subCatMenu
            allStylesMenu.addItem(subCatItem)
        }
        
        allStylesMenu.addItem(NSMenuItem.separator())
        let subCycle = NSMenuItem(title: "Cycle Next Battery Style ❯", action: #selector(cycleNextBatteryStyle), keyEquivalent: "")
        subCycle.target = self
        allStylesMenu.addItem(subCycle)
        
        let allStylesSubItem = NSMenuItem(title: "All Battery Styles ❯", action: nil, keyEquivalent: "")
        allStylesSubItem.image = NSImage(systemSymbolName: "battery.100.bolt", accessibilityDescription: nil)
        allStylesSubItem.submenu = allStylesMenu
        menu.addItem(allStylesSubItem)
        
        // Show Percentage Toggle
        let showPct = UserDefaults.standard.bool(forKey: PrefKey.showBatteryPercentage)
        let pctToggleItem = NSMenuItem(
            title: "Show Percentage (%)",
            action: #selector(toggleBatteryPercentage),
            keyEquivalent: ""
        )
        pctToggleItem.image = NSImage(systemSymbolName: "percent", accessibilityDescription: nil)
        pctToggleItem.target = self
        pctToggleItem.state = showPct ? NSControl.StateValue.on : NSControl.StateValue.off
        menu.addItem(pctToggleItem)
        
        // Show Charging Bolt Toggle
        let showBolt = UserDefaults.standard.object(forKey: PrefKey.showChargingBolt) == nil ? true : UserDefaults.standard.bool(forKey: PrefKey.showChargingBolt)
        let boltToggleItem = NSMenuItem(
            title: "Show Charging Bolt (⚡)",
            action: #selector(toggleChargingBolt),
            keyEquivalent: ""
        )
        boltToggleItem.image = NSImage(systemSymbolName: "bolt.fill", accessibilityDescription: nil)
        boltToggleItem.target = self
        boltToggleItem.state = showBolt ? NSControl.StateValue.on : NSControl.StateValue.off
        menu.addItem(boltToggleItem)
        
        // Percentage Color Submenu
        let colorMenu = NSMenu(title: "Percentage Color")
        let currentColorMode = UserDefaults.standard.string(forKey: PrefKey.batteryColorMode) ?? "Dynamic Level"
        let colorModes = [
            ("Dynamic Match (Green/Yellow/Red)", "Dynamic Level"),
            ("Neon Cyan", "Neon Cyan"),
            ("Pure White", "Monochrome White"),
            ("Emerald Green", "Emerald Green"),
            ("Solar Orange", "Solar Orange"),
            ("Cyber Pink", "Cyber Pink"),
            ("Electric Violet", "Electric Violet")
        ]
        for (label, modeKey) in colorModes {
            let isCurrent = (currentColorMode == modeKey)
            let item = NSMenuItem(
                title: label,
                action: #selector(selectColorModeItem(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = modeKey
            item.state = isCurrent ? NSControl.StateValue.on : NSControl.StateValue.off
            colorMenu.addItem(item)
        }
        let colorSubItem = NSMenuItem(title: "Percentage Color ❯", action: nil, keyEquivalent: "")
        colorSubItem.image = NSImage(systemSymbolName: "paintpalette", accessibilityDescription: nil)
        colorSubItem.submenu = colorMenu
        menu.addItem(colorSubItem)
        
        menu.addItem(NSMenuItem.separator())

        // Mini Dock Style Submenu
        let dockStyleMenu = NSMenu(title: "Mini Dock Style")
        let currentDockStyle = UserDefaults.standard.string(forKey: PrefKey.miniDockBackgroundStyle) ?? "Clear (Transparent)"
        let dockStyles = ["Clear (Transparent)", "Frosted Glass", "Dark Translucent", "Neon Tint"]
        for style in dockStyles {
            let isCurrent = (currentDockStyle == style)
            let item = NSMenuItem(
                title: style,
                action: #selector(selectMiniDockStyleItem(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = style
            item.state = isCurrent ? NSControl.StateValue.on : NSControl.StateValue.off
            dockStyleMenu.addItem(item)
        }
        let dockSubItem = NSMenuItem(title: "Mini Dock Style ❯", action: nil, keyEquivalent: "")
        dockSubItem.image = NSImage(systemSymbolName: "menubar.rectangle", accessibilityDescription: nil)
        dockSubItem.submenu = dockStyleMenu
        menu.addItem(dockSubItem)
        
        // Slide-in Direction Submenu
        let directionMenu = NSMenu(title: "Slide-in Direction")
        let currentDirection = UserDefaults.standard.string(forKey: PrefKey.gridTransitionDirection) ?? "Slide from Right (iPhone Mode 📱)"
        let directions = [
            ("➡️ Slide from Right (iPhone Mode)", "Slide from Right (iPhone Mode 📱)"),
            ("⬅️ Slide from Left (Sidebar)", "Slide from Left (Sidebar ⬅️)"),
            ("⬇️ Drop Down from Top (Menu Bar)", "Drop Down from Top (Menu Bar ⬇️)"),
            ("⬆️ Pull Up from Bottom", "Pull Up from Bottom"),
            ("✨ Spatial Zoom from Center", "Spatial Zoom from Center (Holographic ✨)")
        ]
        for (label, dirKey) in directions {
            let isCurrent = (currentDirection == dirKey)
            let item = NSMenuItem(
                title: label,
                action: #selector(selectSlideDirectionItem(_:)),
                keyEquivalent: ""
            )
            item.target = self
            item.representedObject = dirKey
            item.state = isCurrent ? NSControl.StateValue.on : NSControl.StateValue.off
            directionMenu.addItem(item)
        }
        let directionSubItem = NSMenuItem(title: "Slide-in Direction ❯", action: nil, keyEquivalent: "")
        directionSubItem.image = NSImage(systemSymbolName: "arrow.left.and.right", accessibilityDescription: nil)
        directionSubItem.submenu = directionMenu
        menu.addItem(directionSubItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // ── 6. Desktop & System Utilities ──
        let filesVisible = DesktopFilesManager.shared.areDesktopFilesVisible
        let filesTitle = filesVisible ? "Hide Desktop Files (⌘⇧D)" : "Show Desktop Files (⌘⇧D)"
        let filesItem = NSMenuItem(
            title: filesTitle,
            action: #selector(toggleDesktopFilesAction),
            keyEquivalent: "d"
        )
        filesItem.keyEquivalentModifierMask = [.command, .shift]
        filesItem.image = NSImage(systemSymbolName: filesVisible ? "eye.slash" : "eye", accessibilityDescription: nil)
        filesItem.target = self
        menu.addItem(filesItem)
        
        let activityMonitorItem = NSMenuItem(
            title: "Activity Monitor...",
            action: #selector(openActivityMonitor),
            keyEquivalent: ""
        )
        activityMonitorItem.image = NSImage(systemSymbolName: "waveform.path.ecg", accessibilityDescription: nil)
        activityMonitorItem.target = self
        menu.addItem(activityMonitorItem)
        
        let forceQuitItem = NSMenuItem(
            title: "Force Quit Applications...",
            action: #selector(openForceQuit),
            keyEquivalent: ""
        )
        forceQuitItem.image = NSImage(systemSymbolName: "xmark.octagon", accessibilityDescription: nil)
        forceQuitItem.target = self
        menu.addItem(forceQuitItem)

        // Lock Screen
        let lockScreenItem = NSMenuItem(
            title: "Lock Screen (⌃⌘Q)",
            action: #selector(lockScreenAction),
            keyEquivalent: "q"
        )
        lockScreenItem.keyEquivalentModifierMask = [.command, .control]
        lockScreenItem.image = NSImage(systemSymbolName: "lock", accessibilityDescription: nil)
        lockScreenItem.target = self
        menu.addItem(lockScreenItem)

        // Clamshell Awake / Keep Desktop Awake When Closed for Monitor
        let isSleepPrevented = GenieSleepPreventionManager.shared.isSleepDisabled
        let antiSleepTitle = isSleepPrevented ? "Clamshell Awake: Active 🖥️ (Lid Closed)" : "Clamshell Awake: Disabled 🌙"
        let antiSleepItem = NSMenuItem(
            title: antiSleepTitle,
            action: #selector(toggleAntiSleepAction),
            keyEquivalent: ""
        )
        antiSleepItem.state = isSleepPrevented ? .on : .off
        antiSleepItem.image = NSImage(systemSymbolName: "display.2", accessibilityDescription: "Clamshell Awake")
        antiSleepItem.target = self
        menu.addItem(antiSleepItem)

        // Genie iMessage Extension Submenu
        let extMenu = NSMenu(title: "Genie iMessage Extension")
        let extStatusItem = NSMenuItem(title: "Status: Active 🟢 (\(GenieiMessageExtensionManager.shared.nicholasPhone))", action: nil, keyEquivalent: "")
        extStatusItem.isEnabled = false
        extMenu.addItem(extStatusItem)
        
        let openChat = NSMenuItem(title: "Open Messages Chat...", action: #selector(openMessagesChatAction), keyEquivalent: "")
        openChat.target = self
        openChat.image = NSImage(systemSymbolName: "message.fill", accessibilityDescription: nil)
        extMenu.addItem(openChat)

        let exportVcard = NSMenuItem(title: "Export Genie Contact Card (vCard)...", action: #selector(exportContactCardAction), keyEquivalent: "")
        exportVcard.target = self
        exportVcard.image = NSImage(systemSymbolName: "person.crop.circle.badge.plus", accessibilityDescription: nil)
        extMenu.addItem(exportVcard)

        let installScripts = NSMenuItem(title: "Reinstall Messages Extension Scripts", action: #selector(installMessagesExtensionAction), keyEquivalent: "")
        installScripts.target = self
        installScripts.image = NSImage(systemSymbolName: "arrow.triangle.2.circlepath", accessibilityDescription: nil)
        extMenu.addItem(installScripts)

        let extItem = NSMenuItem(title: "Genie iMessage Extension", action: nil, keyEquivalent: "")
        extItem.image = NSImage(systemSymbolName: "message.badge.filled.fill", accessibilityDescription: nil)
        extItem.submenu = extMenu
        menu.addItem(extItem)

        // Sleep Mac
        let sleepItem = NSMenuItem(
            title: "Sleep Mac",
            action: #selector(sleepMacAction),
            keyEquivalent: ""
        )
        sleepItem.image = NSImage(systemSymbolName: "moon.fill", accessibilityDescription: nil)
        sleepItem.target = self
        menu.addItem(sleepItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // ── 7. Settings & Quit ──
        let settingsItem = NSMenuItem(title: LocalizedStrings.translateText("Genie Settings...", lang: lang), action: #selector(openGenieSettings), keyEquivalent: ",")
        settingsItem.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        let quitItem = NSMenuItem(title: LocalizedStrings.translateText("Quit Genie", lang: lang), action: #selector(quitGenie), keyEquivalent: "q")
        quitItem.image = NSImage(systemSymbolName: "power", accessibilityDescription: nil)
        quitItem.target = self
        menu.addItem(quitItem)
        
        return menu
    }
    
    private static func loadQuickInstalledApps() -> [AppInfo] {
        if let existing = AppModel.shared?.apps, !existing.isEmpty {
            return existing
        }
        var items: [AppInfo] = []
        var seen = Set<String>()
        let dirs = ["/Applications", "/System/Applications", "/System/Applications/Utilities"]
        for dir in dirs {
            if let names = try? FileManager.default.contentsOfDirectory(atPath: dir) {
                for name in names where name.hasSuffix(".app") {
                    let path = "\(dir)/\(name)"
                    if !seen.contains(path) {
                        seen.insert(path)
                        let url = URL(fileURLWithPath: path)
                        let cleanName = name.replacingOccurrences(of: ".app", with: "")
                        let icon = NSWorkspace.shared.icon(forFile: path)
                        items.append(AppInfo(id: path, name: cleanName, url: url, icon: icon))
                    }
                }
            }
        }
        return items.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    @objc public func openMacOSBatterySettings() {
        HapticFeedback.selection()
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.battery") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc public func openActivityMonitor() {
        HapticFeedback.selection()
        let path = "/System/Applications/Utilities/Activity Monitor.app"
        NSWorkspace.shared.open(URL(fileURLWithPath: path))
    }
    
    @objc public func openForceQuit() {
        HapticFeedback.selection()
        let script = """
        tell application "System Events"
            key code 53 using {command down, option down}
        end tell
        """
        if let appleScript = NSAppleScript(source: script) {
            var err: NSDictionary?
            appleScript.executeAndReturnError(&err)
        }
    }
    
    @objc public func activateRunningAppFromMenu(_ sender: NSMenuItem) {
        guard let app = sender.representedObject as? NSRunningApplication else { return }
        HapticFeedback.selection()
        activateApp(app)
    }
    
    @objc public func launchDockAppFromMenu(_ sender: NSMenuItem) {
        guard let item = sender.representedObject as? DockAppItem else { return }
        handleAppClick(item)
    }

    @objc public func openDockFolderFromMenu(_ sender: NSMenuItem) {
        guard let folder = sender.representedObject as? DockFolderItem else { return }
        HapticFeedback.selection()
        folder.openInFinder()
    }

    @objc public func openFolderURLFromMenu(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }
        HapticFeedback.selection()
        NSWorkspace.shared.open(url)
    }

    @objc public func launchAppURLFromMenu(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }
        HapticFeedback.selection()
        NSWorkspace.shared.open(url)
    }

    @objc public func toggleDockActiveAppsOnlyMenu() {
        HapticFeedback.selection()
        let current = UserDefaults.standard.bool(forKey: PrefKey.dockActiveAppsOnly)
        let next = !current
        UserDefaults.standard.set(next, forKey: PrefKey.dockActiveAppsOnly)
        NotificationCenter.default.post(name: NSNotification.Name("NexusDockActiveAppsOnlyChanged"), object: next)
        AppDelegate.shared?.renderIcon()
    }

    @objc public func toggleDockFoldersMenu() {
        HapticFeedback.selection()
        let current = UserDefaults.standard.object(forKey: PrefKey.dockShowFolderStacks) == nil ? true : UserDefaults.standard.bool(forKey: PrefKey.dockShowFolderStacks)
        let next = !current
        UserDefaults.standard.set(next, forKey: PrefKey.dockShowFolderStacks)
        NotificationCenter.default.post(name: NSNotification.Name("NexusDockShowFolderStacksChanged"), object: next)
        AppDelegate.shared?.renderIcon()
    }

    @objc public func toggleDockFinderMenu() {
        HapticFeedback.selection()
        let current = UserDefaults.standard.object(forKey: PrefKey.dockAlwaysShowFinder) as? Bool ?? true
        let next = !current
        UserDefaults.standard.set(next, forKey: PrefKey.dockAlwaysShowFinder)
        NotificationCenter.default.post(name: NSNotification.Name("NexusDockAlwaysShowFinderChanged"), object: next)
        AppDelegate.shared?.renderIcon()
    }

    @objc public func toggleDockTrashMenu() {
        HapticFeedback.selection()
        let current = UserDefaults.standard.object(forKey: PrefKey.dockAlwaysShowTrash) as? Bool ?? true
        let next = !current
        UserDefaults.standard.set(next, forKey: PrefKey.dockAlwaysShowTrash)
        NotificationCenter.default.post(name: NSNotification.Name("NexusDockTrashChanged"), object: next)
        AppDelegate.shared?.renderIcon()
    }

    @objc public func toggleShowMiniDockInMenuBar() {
        HapticFeedback.selection()
        let current = UserDefaults.standard.bool(forKey: PrefKey.showMiniDockInMenuBar)
        let next = !current
        UserDefaults.standard.set(next, forKey: PrefKey.showMiniDockInMenuBar)
        AppDelegate.shared?.setupStatusItemView()
        NotificationCenter.default.post(name: NSNotification.Name("NexusMiniDockMenuBarChanged"), object: next)
    }

    @objc public func lockScreenAction() {
        HapticFeedback.selection()
        let script = "tell application \"System Events\" to keystroke \"q\" using {command down, control down}"
        if let appleScript = NSAppleScript(source: script) {
            var err: NSDictionary?
            appleScript.executeAndReturnError(&err)
        }
    }

    @objc public func sleepMacAction() {
        HapticFeedback.selection()
        let script = "tell application \"System Events\" to sleep"
        if let appleScript = NSAppleScript(source: script) {
            var err: NSDictionary?
            appleScript.executeAndReturnError(&err)
        }
    }

    @objc public func toggleAntiSleepAction() {
        HapticFeedback.selection()
        GenieSleepPreventionManager.shared.toggleSleepPrevention()
        AppDelegate.shared?.renderIcon()
    }

    @objc public func openMessagesChatAction() {
        HapticFeedback.selection()
        if let url = URL(string: "messages:") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc public func exportContactCardAction() {
        HapticFeedback.selection()
        if let url = GenieiMessageExtensionManager.shared.exportGenieContactCard(toDesktop: true) {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        }
    }

    @objc public func installMessagesExtensionAction() {
        HapticFeedback.selection()
        GenieiMessageExtensionManager.shared.installExtensionFiles()
    }
}
