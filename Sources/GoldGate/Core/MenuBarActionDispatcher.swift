import AppKit
import Foundation
import SwiftUI

// MARK: - Preference Keys for Menu Bar Strip Item Rects

public struct LeoFrameKey: PreferenceKey {
    public static var defaultValue: NSRect = .zero
    public static func reduce(value: inout NSRect, nextValue: () -> NSRect) {
        let next = nextValue()
        if next != .zero { value = next }
    }
}

public struct DockAppItem: Identifiable, Equatable {
    public let id: String
    public let name: String
    public let bundleURL: URL?
    public let bundleIdentifier: String?
    public let icon: NSImage?
    public var runningApp: NSRunningApplication?
    public var isRunning: Bool { runningApp != nil && runningApp?.isTerminated == false }
    public var processIdentifier: pid_t { runningApp?.processIdentifier ?? 0 }

    public init(
        id: String,
        name: String,
        bundleURL: URL? = nil,
        bundleIdentifier: String? = nil,
        icon: NSImage? = nil,
        runningApp: NSRunningApplication? = nil
    ) {
        self.id = id
        self.name = name
        self.bundleURL = bundleURL
        self.bundleIdentifier = bundleIdentifier
        self.icon = icon
        self.runningApp = runningApp
    }

    public static func == (lhs: DockAppItem, rhs: DockAppItem) -> Bool {
        lhs.id == rhs.id && lhs.isRunning == rhs.isRunning && lhs.processIdentifier == rhs.processIdentifier
    }

    /// Determines if two application descriptors represent the exact same application (eliminating duplicate icons)
    public static func isSameApplication(bidA: String?, nameA: String?, urlA: URL?, bidB: String?, nameB: String?, urlB: URL?) -> Bool {
        let bA = bidA?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        let bB = bidB?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        let nA = nameA?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        let nB = nameB?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""

        // 1. Exact bundle identifier match
        if !bA.isEmpty && !bB.isEmpty && bA == bB { return true }

        // 2. Antigravity Suite & IDE deduplication
        let isAntiA = bA.contains("antigravity") || nA.contains("antigravity")
        let isAntiB = bB.contains("antigravity") || nB.contains("antigravity")
        if isAntiA && isAntiB { return true }

        // 3. System Settings / Preferences deduplication
        let isSettingsA = bA.contains("systempreferences") || nA == "system settings" || nA == "system preferences" || nA == "settings"
        let isSettingsB = bB.contains("systempreferences") || nB == "system settings" || nB == "system preferences" || nB == "settings"
        if isSettingsA && isSettingsB { return true }

        // 4. Finder deduplication
        let isFinderA = bA == "com.apple.finder" || nA == "finder"
        let isFinderB = bB == "com.apple.finder" || nB == "finder"
        if isFinderA && isFinderB { return true }

        // 5. Terminal deduplication
        let isTermA = bA.contains("terminal") || nA == "terminal"
        let isTermB = bB.contains("terminal") || nB == "terminal"
        if isTermA && isTermB { return true }

        // 6. Chrome deduplication
        let isChromeA = bA.contains("chrome") || nA.contains("chrome")
        let isChromeB = bB.contains("chrome") || nB.contains("chrome")
        if isChromeA && isChromeB { return true }

        // 7. Visual Studio Code / Code Insiders deduplication
        let isVSCodeA = bA.contains("vscode") || bA.contains("visualstudio") || nA.hasPrefix("code")
        let isVSCodeB = bB.contains("vscode") || bB.contains("visualstudio") || nB.hasPrefix("code")
        if isVSCodeA && isVSCodeB { return true }

        // 8. Exact file path or bundle URL match
        if let uA = urlA?.standardizedFileURL.path, let uB = urlB?.standardizedFileURL.path, !uA.isEmpty, !uB.isEmpty {
            if uA == uB { return true }
            // Match bundle names (e.g. /System/Applications/Safari.app vs /Applications/Safari.app)
            let baseA = URL(fileURLWithPath: uA).deletingPathExtension().lastPathComponent.lowercased()
            let baseB = URL(fileURLWithPath: uB).deletingPathExtension().lastPathComponent.lowercased()
            if !baseA.isEmpty && baseA == baseB { return true }
        }

        // 9. Exact localized name match
        if !nA.isEmpty && !nB.isEmpty && nA == nB { return true }

        // 10. Sub-bundle or helper process match (e.g. com.google.Chrome.helper)
        if !bA.isEmpty && !bB.isEmpty && (bA.hasPrefix(bB + ".") || bB.hasPrefix(bA + ".")) { return true }

        return false
    }

    public func representsSameApplication(as other: DockAppItem) -> Bool {
        DockAppItem.isSameApplication(
            bidA: self.bundleIdentifier,
            nameA: self.name,
            urlA: self.bundleURL,
            bidB: other.bundleIdentifier,
            nameB: other.name,
            urlB: other.bundleURL
        )
    }

    @MainActor
    public func activate() {
        MenuBarActionDispatcher.shared.handleAppClick(self)
    }
}

public struct AppFrameItem: Equatable {
    public let id: String
    public let pid: pid_t
    public let frame: NSRect

    public init(id: String = "", pid: pid_t = 0, frame: NSRect) {
        self.id = id.isEmpty ? "\(pid)" : id
        self.pid = pid
        self.frame = frame
    }
}

public struct AppFramesKey: PreferenceKey {
    public static var defaultValue: [AppFrameItem] = []
    public static func reduce(value: inout [AppFrameItem], nextValue: () -> [AppFrameItem]) {
        value.append(contentsOf: nextValue())
    }
}

public struct FinderFrameKey: PreferenceKey {
    public static var defaultValue: NSRect = .zero
    public static func reduce(value: inout NSRect, nextValue: () -> NSRect) {
        let next = nextValue()
        if next != .zero { value = next }
    }
}

public struct TrashFrameKey: PreferenceKey {
    public static var defaultValue: NSRect = .zero
    public static func reduce(value: inout NSRect, nextValue: () -> NSRect) {
        let next = nextValue()
        if next != .zero { value = next }
    }
}


public struct BatteryFrameKey: PreferenceKey {
    public static var defaultValue: NSRect = .zero
    public static func reduce(value: inout NSRect, nextValue: () -> NSRect) {
        let next = nextValue()
        if next != .zero { value = next }
    }
}

// MARK: - Menu Bar Action Dispatcher (Rock-Solid macOS Click & Context Menu Engine)

@MainActor
public final class MenuBarActionDispatcher: NSObject, ObservableObject {
    public static let shared = MenuBarActionDispatcher()

    @Published public var isPoppedOut: Bool = false
    @Published public var isBatteryHovered: Bool = false
    @Published public var isTimeHovered: Bool = false
    @Published public var isStripHovered: Bool = false

    private var dismissTimer: Timer?

    public func popOut(from source: String) {
        dismissTimer?.invalidate()
        dismissTimer = nil
        switch source {
        case "time": isTimeHovered = true
        case "battery": isBatteryHovered = true
        case "strip": isStripHovered = true
        default: break
        }
        withAnimation(.spring(response: 0.28, dampingFraction: 0.76)) {
            isPoppedOut = true
        }
    }

    public func requestDismiss(from source: String) {
        switch source {
        case "time": isTimeHovered = false
        case "battery": isBatteryHovered = false
        case "strip": isStripHovered = false
        default: break
        }
        if !isBatteryHovered && !isTimeHovered && !isStripHovered {
            dismissTimer?.invalidate()
            dismissTimer = Timer.scheduledTimer(withTimeInterval: 0.40, repeats: false) { [weak self] _ in
                Task { @MainActor in
                    guard let self = self else { return }
                    if !self.isBatteryHovered && !self.isTimeHovered && !self.isStripHovered {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.76)) {
                            self.isPoppedOut = false
                        }
                    }
                }
            }
        }
    }

    public var dockItems: [DockAppItem] = []
    public var displayApps: [NSRunningApplication] = []
    public var stripWidth: CGFloat = 0

    // Geometry frames measured by SwiftUI
    public var leoFrame: NSRect = .zero
    public var appFrames: [AppFrameItem] = []
    public var finderFrame: NSRect = .zero
    public var trashFrame: NSRect = .zero
    public var batteryFrame: NSRect = .zero

    private var lastHandledEventNumber: Int = -1
    private var lastHandledTime: TimeInterval = 0

    private override init() {
        super.init()
    }

    // MARK: - Smart Edge Reveal
    // Replaces the old manual "plug" click handle: when the mini dock is set to auto-hide, it now
    // simply appears on its own once the cursor nears the top-right corner where the status item
    // lives, the same way the real macOS Dock reveals when you push the cursor to the screen edge.

    private var edgeProximityTimer: Timer?
    private var isNearEdgeState = false
    private var isOverDockArea = false
    private var dockSwipeMonitor: Any?

    public func startEdgeProximityMonitoring() {
        if edgeProximityTimer == nil {
            edgeProximityTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.checkEdgeProximity()
                }
            }
        }
        startDockSwipeMonitoring()
    }

    public func stopEdgeProximityMonitoring() {
        edgeProximityTimer?.invalidate()
        edgeProximityTimer = nil
        stopDockSwipeMonitoring()
    }

    // Dock swipe monitoring (disabled 3x3 spatial plane jumps to keep dock focused and stable)
    private func startDockSwipeMonitoring() {
        // Spatial grid navigation disabled in favor of core AI chat & mini dock stability
    }

    private func stopDockSwipeMonitoring() {
        if let monitor = dockSwipeMonitor {
            NSEvent.removeMonitor(monitor)
        }
        dockSwipeMonitor = nil
    }

    private func checkEdgeProximity() {
        guard let screen = NSScreen.main else { return }
        let mouseLoc = NSEvent.mouseLocation
        let distanceFromTop = screen.frame.maxY - mouseLoc.y
        // Reveal zone: the top few points of the screen, on the right-hand side where the
        // status item's strip lives (roughly stripWidth + some slack, or a sensible default
        // before the strip has reported its real measured width).
        let revealZoneWidth = max(220, stripWidth + 80)
        let isNear = distanceFromTop <= 4 && mouseLoc.x >= (screen.frame.maxX - revealZoneWidth)
        isOverDockArea = distanceFromTop <= 30 && mouseLoc.x >= (screen.frame.maxX - revealZoneWidth)
        guard isNear != isNearEdgeState else { return }
        isNearEdgeState = isNear
        NotificationCenter.default.post(name: NSNotification.Name("NexusMenuBarEdgeProximity"), object: isNear)
    }

    // MARK: - Central Click Dispatcher (Called by ClickableHostingView & statusItem.button)

    public func dispatchClick(at point: NSPoint, in view: NSView, isRightClick: Bool, event: NSEvent) {
        // De-duplicate if both ClickableHostingView and statusItem.button report the same event
        let now = ProcessInfo.processInfo.systemUptime
        if event.eventNumber > 0 && event.eventNumber == lastHandledEventNumber && (now - lastHandledTime) < 0.15 {
            return
        }
        if event.eventNumber > 0 {
            lastHandledEventNumber = event.eventNumber
        }
        lastHandledTime = now

        let target = identifyTarget(at: point)
        let logMsg = "DISPATCH_CLICK: pt=\(point), isRight=\(isRightClick), target=\(target)\n"
        if let h = try? FileHandle(forWritingTo: URL(fileURLWithPath: "/tmp/genie_click_debug.txt")) {
            h.seekToEndOfFile()
            h.write(logMsg.data(using: .utf8)!)
            h.closeFile()
        } else {
            try? logMsg.write(toFile: "/tmp/genie_click_debug.txt", atomically: true, encoding: .utf8)
        }

        if isRightClick {
            handleRightClick(target: target, in: view, event: event)
        } else {
            handleLeftClick(target: target, in: view, event: event)
        }
    }

    // MARK: - Target Identification (Exact SwiftUI Frames + Robust Geometric Fallback)

    public enum StripTarget {
        case leo
        case app(DockAppItem)
        case finder
        case trash
        case battery
    }

    private func identifyTarget(at point: NSPoint) -> StripTarget {
        // 1. Check exact SwiftUI-measured horizontal spans if available
        if leoFrame != .zero && (leoFrame.minX...leoFrame.maxX).contains(point.x) {
            return .leo
        }

        for item in appFrames {
            if item.frame != .zero && (item.frame.minX...item.frame.maxX).contains(point.x) {
                if let dItem = dockItems.first(where: { $0.id == item.id || ($0.processIdentifier > 0 && $0.processIdentifier == item.pid) }) {
                    return .app(dItem)
                }
            }
        }

        if finderFrame != .zero && (finderFrame.minX...finderFrame.maxX).contains(point.x) {
            return .finder
        }

        if trashFrame != .zero && (trashFrame.minX...trashFrame.maxX).contains(point.x) {
            return .trash
        }

        if batteryFrame != .zero && (batteryFrame.minX...batteryFrame.maxX).contains(point.x) {
            return .battery
        }

        // 2. Nearest horizontal center check (continuous Voronoi targeting across all gaps)
        var targets: [(target: StripTarget, midX: CGFloat)] = []
        if leoFrame != .zero {
            targets.append((.leo, leoFrame.midX))
        }
        for item in appFrames {
            if item.frame != .zero, let dItem = dockItems.first(where: { $0.id == item.id || ($0.processIdentifier > 0 && $0.processIdentifier == item.pid) }) {
                targets.append((.app(dItem), item.frame.midX))
            }
        }
        if finderFrame != .zero {
            targets.append((.finder, finderFrame.midX))
        }
        if trashFrame != .zero {
            targets.append((.trash, trashFrame.midX))
        }
        if batteryFrame != .zero {
            targets.append((.battery, batteryFrame.midX))
        }

        if !targets.isEmpty {
            let closest = targets.min(by: { abs($0.midX - point.x) < abs($1.midX - point.x) })
            if let c = closest {
                return c.target
            }
        }

        // 3. Fallback if frames not yet measured:
        let dockAlwaysShowFinder = UserDefaults.standard.object(forKey: PrefKey.dockAlwaysShowFinder) as? Bool ?? true
        let dockAlwaysShowTrash = UserDefaults.standard.object(forKey: PrefKey.dockAlwaysShowTrash) as? Bool ?? true
        let menuBarAppSwitcherEnabled = UserDefaults.standard.object(forKey: PrefKey.menuBarAppSwitcherEnabled) as? Bool ?? false

        let dockStartX: CGFloat = 4
        let appSlotWidth: CGFloat = 26
        let totalApps = dockItems.count
        let appsEndX = dockStartX + CGFloat(totalApps) * appSlotWidth
        if point.x >= dockStartX && point.x < appsEndX {
            let index = min(totalApps - 1, max(0, Int((point.x - dockStartX) / appSlotWidth)))
            if index < totalApps { return .app(dockItems[index]) }
        }
        var curX = appsEndX
        if dockAlwaysShowFinder {
            if point.x >= curX && point.x < curX + 26 { return .finder }
            curX += 26
        }
        if dockAlwaysShowTrash {
            if point.x >= curX && point.x < curX + 26 { return .trash }
            curX += 26
        }
        if menuBarAppSwitcherEnabled {
            if point.x >= curX && point.x < curX + 26 { return .app(dockItems.first ?? DockAppItem(id: "switcher", name: "Switcher")) }
            curX += 26
        }
        if point.x >= curX && point.x < curX + 50 { return .battery }
        return .leo
    }

    // MARK: - Left Click Handlers

    public func handleLeftClick(target: StripTarget, in view: NSView, event: NSEvent) {
        switch target {
        case .leo:
            handleLeoClick()
        case .app(let item):
            handleAppClick(item)
        case .finder:
            openNativeFinder()
        case .trash:
            openNativeTrash()
        case .battery:
            handleBatteryClick()
        }
    }

    public func handleLeoClick(in view: NSView? = nil, event: NSEvent? = nil) {
        HapticFeedback.selection()

        let smokeOn = UserDefaults.standard.object(forKey: PrefKey.smokeEffectsEnabled) == nil ? true : UserDefaults.standard.bool(forKey: PrefKey.smokeEffectsEnabled)
        if smokeOn {
            let targetScreen = NSScreen.main ?? (NSScreen.screens.first ?? NSScreen())
            let currentSmokeStyle = UserDefaults.standard.string(forKey: PrefKey.smokeStyle) ?? "Electric Neon"
            GenieSmokeEngine.shared.triggerBurst(
                origin: .topGlyph(xPercent: 0.88),
                bounds: targetScreen.frame.size,
                style: currentSmokeStyle,
                count: 24
            )
        }

        // Left-click Genie activates the Chat Bubbles & Dialogue Studio!
        FinderChatWindowManager.shared.toggle(tab: .chat)
    }


    public func duplicateAppView(app: NSRunningApplication) {
        HapticFeedback.heavy()
        app.unhide()
        _ = app.activate(options: [.activateAllWindows])

        guard let bundleId = app.bundleIdentifier, !bundleId.isEmpty else { return }

        let script = """
        tell application id "\(bundleId)"
            reopen
            activate
            try
                make new window
            on error
                try
                    tell application "System Events" to tell process id "\(bundleId)" to keystroke "n" using command down
                end try
            end try
        end tell
        """
        DispatchQueue.global(qos: .userInteractive).async {
            NSAppleScript(source: script)?.executeAndReturnError(nil)
        }
    }

    public func activateApp(_ app: NSRunningApplication) {
        HapticFeedback.selection()

        // 1. Direct unhide and activate with full frontmost override
        app.unhide()
        if #available(macOS 14.0, *) {
            _ = app.activate(options: [.activateAllWindows])
            if let bid = app.bundleIdentifier {
                NSApp.yieldActivation(toApplicationWithBundleIdentifier: bid)
            }
        } else {
            _ = app.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
        }

        // 2. Guaranteed AppleScript reopen and activate via bundle ID or app name.
        //
        // Genie Lite skips this. The target here is whatever app the user
        // clicked, so it cannot be covered by the enumerated
        // com.apple.security.temporary-exception.apple-events list — a sandbox
        // exception has to name its targets up front, and "any application the
        // user picks" is not something App Review grants. Under the sandbox
        // every one of these events is refused anyway, so this is dead weight
        // that also invites a 2.5.1 question. Steps 1 and 3 (NSRunningApplication
        // .activate and NSWorkspace.openApplication) are public API, are not
        // sandbox-gated, and already do the job.
        #if !GENIE_MAS
        if let bundleId = app.bundleIdentifier, !bundleId.isEmpty {
            let script = """
            tell application id "\(bundleId)"
                reopen
                activate
            end tell
            """
            DispatchQueue.global(qos: .userInteractive).async {
                NSAppleScript(source: script)?.executeAndReturnError(nil)
            }
        } else if let name = app.localizedName, !name.isEmpty {
            let cleanName = name.replacingOccurrences(of: "\"", with: "\\\"")
            let script = """
            tell application "\(cleanName)"
                reopen
                activate
            end tell
            """
            DispatchQueue.global(qos: .userInteractive).async {
                NSAppleScript(source: script)?.executeAndReturnError(nil)
            }
        }
        #endif

        // 3. Activate via workspace openApplication
        if let bundleURL = app.bundleURL {
            let config = NSWorkspace.OpenConfiguration()
            config.activates = true
            config.promptsUserIfNeeded = false
            config.createsNewApplicationInstance = false
            NSWorkspace.shared.openApplication(at: bundleURL, configuration: config, completionHandler: nil)
        }

        // 4. Update SmartGrid and window layering
        SmartGridManager.shared.bringToFront(app: app)

        // 5. Special Finder desktop path open
        if app.bundleIdentifier == "com.apple.finder" || (app.localizedName ?? "").lowercased() == "finder" {
            let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSHomeDirectory() + "/Desktop")
            let finderBundleURL = URL(fileURLWithPath: "/System/Library/CoreServices/Finder.app")
            let config = NSWorkspace.OpenConfiguration()
            config.activates = true
            NSWorkspace.shared.open([desktopURL], withApplicationAt: finderBundleURL, configuration: config, completionHandler: nil)
        }

        NotificationCenter.default.post(name: NSNotification.Name("NexusMiniDockAppActivated"), object: app.processIdentifier)
    }

    public func openNativeFinder() {
        let configuredPath = UserDefaults.standard.string(forKey: PrefKey.barFolderPath) ?? AppDefaultsManager.defaultBarFolderPath
        let expandedPath = (configuredPath as NSString).expandingTildeInPath
        let folderURL = URL(fileURLWithPath: expandedPath)
        let targetURL = FileManager.default.fileExists(atPath: folderURL.path) ? folderURL : FileManager.default.homeDirectoryForCurrentUser
        let finderBundleURL = URL(fileURLWithPath: "/System/Library/CoreServices/Finder.app")

        if let finderApp = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.finder").first {
            finderApp.unhide()
            finderApp.activate(options: [.activateAllWindows])
        }

        let script = "tell application id \"com.apple.finder\" to activate"
        NSAppleScript(source: script)?.executeAndReturnError(nil)

        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        config.addsToRecentItems = false
        NSWorkspace.shared.open([targetURL], withApplicationAt: finderBundleURL, configuration: config) { _, error in
            if error != nil {
                DispatchQueue.main.async {
                    let fallbackConfig = NSWorkspace.OpenConfiguration()
                    fallbackConfig.activates = true
                    NSWorkspace.shared.openApplication(at: finderBundleURL, configuration: fallbackConfig, completionHandler: nil)
                    _ = NSWorkspace.shared.open(targetURL)
                }
            }
        }
    }

    public func handleBatteryClick(in view: NSView? = nil, event: NSEvent? = nil) {
        HapticFeedback.selection()
        cycleNextBatteryStyle()
    }

    // MARK: - Right Click (Native macOS Cocoa Context Menus)

    private func handleRightClick(target: StripTarget, in view: NSView, event: NSEvent) {
        let menu: NSMenu
        switch target {
        case .leo:
            HapticFeedback.selection()
            openGenieSettings()
            return
        case .app(let item):
            menu = makeDockItemContextMenu(for: item)
        case .finder:
            menu = makeFinderContextMenu()
        case .trash:
            menu = makeTrashContextMenu()
        case .battery:
            menu = makeBatteryContextMenu()
        }
        NSMenu.popUpContextMenu(menu, with: event, for: view)
    }

    public func handleAppClick(_ item: DockAppItem) {
        HapticFeedback.selection()
        if item.bundleIdentifier == "com.nicholasdudek.genie" || item.id == "com.nicholasdudek.genie" || item.name.lowercased() == "genie" {
            if NSEvent.modifierFlags.contains(.option) {
                AppDelegate.shared?.toggleMenuBarSettingsDropdown(targetTab: .system)
            } else {
                FinderChatWindowManager.shared.toggle()
            }
            return
        }
        if item.id == "com.apple.Terminal" || item.name.lowercased() == "terminal" {
            let termURL = URL(fileURLWithPath: "/System/Applications/Utilities/Terminal.app")
            NSWorkspace.shared.open(termURL)
            return
        }
        if NSEvent.modifierFlags.contains(.option) {
            if let running = item.runningApp, !running.isTerminated {
                duplicateAppView(app: running)
                return
            }
        }

        // Dynamically locate existing running instance across PID, bundle identifier, and name
        let existingRunningApp: NSRunningApplication? = {
            if let running = item.runningApp, !running.isTerminated {
                return running
            }
            if item.processIdentifier > 0, let app = NSRunningApplication(processIdentifier: item.processIdentifier), !app.isTerminated {
                return app
            }
            if let bundleId = item.bundleIdentifier, !bundleId.isEmpty,
               let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleId).first(where: { !$0.isTerminated }) {
                return app
            }
            let name = item.name.lowercased()
            return NSWorkspace.shared.runningApplications.first(where: {
                !$0.isTerminated && ($0.localizedName?.lowercased() == name || $0.bundleURL?.lastPathComponent.lowercased().replacingOccurrences(of: ".app", with: "") == name)
            })
        }()

        if let running = existingRunningApp {
            activateApp(running)
            // Also invoke workspace activation to guarantee WindowServer focus
            if let u = running.bundleURL ?? item.bundleURL {
                let cfg = NSWorkspace.OpenConfiguration()
                cfg.activates = true
                cfg.createsNewApplicationInstance = false
                NSWorkspace.shared.openApplication(at: u, configuration: cfg, completionHandler: nil)
            }
        } else if let url = item.bundleURL {
            let config = NSWorkspace.OpenConfiguration()
            config.activates = true
            NSWorkspace.shared.openApplication(at: url, configuration: config) { app, _ in
                if let a = app {
                    DispatchQueue.main.async {
                        self.activateApp(a)
                    }
                } else {
                    DispatchQueue.main.async {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
            NotificationCenter.default.post(name: NSNotification.Name("NexusMiniDockAppLaunched"), object: item.id)
        } else if let bundleId = item.bundleIdentifier, let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
            let config = NSWorkspace.OpenConfiguration()
            config.activates = true
            NSWorkspace.shared.openApplication(at: url, configuration: config) { app, _ in
                if let a = app {
                    DispatchQueue.main.async {
                        self.activateApp(a)
                    }
                } else {
                    DispatchQueue.main.async {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
            NotificationCenter.default.post(name: NSNotification.Name("NexusMiniDockAppLaunched"), object: item.id)
        } else {
            let candidateURL: URL? = {
                if item.id.hasPrefix("/") && FileManager.default.fileExists(atPath: item.id) {
                    return URL(fileURLWithPath: item.id)
                }
                if let u = NSWorkspace.shared.urlForApplication(withBundleIdentifier: item.id) {
                    return u
                }
                let cand1 = "/Applications/\(item.name).app"
                if FileManager.default.fileExists(atPath: cand1) { return URL(fileURLWithPath: cand1) }
                let cand2 = "/System/Applications/\(item.name).app"
                if FileManager.default.fileExists(atPath: cand2) { return URL(fileURLWithPath: cand2) }
                let cand3 = "/System/Applications/Utilities/\(item.name).app"
                if FileManager.default.fileExists(atPath: cand3) { return URL(fileURLWithPath: cand3) }
                return nil
            }()
            if let url = candidateURL {
                let config = NSWorkspace.OpenConfiguration()
                config.activates = true
                NSWorkspace.shared.openApplication(at: url, configuration: config) { app, _ in
                    if let a = app {
                        DispatchQueue.main.async {
                            self.activateApp(a)
                        }
                    } else {
                        DispatchQueue.main.async {
                            NSWorkspace.shared.open(url)
                        }
                    }
                }
                NotificationCenter.default.post(name: NSNotification.Name("NexusMiniDockAppLaunched"), object: item.id)
            }
        }
    }

    public func makeDockItemContextMenu(for item: DockAppItem) -> NSMenu {
        if let running = item.runningApp, !running.isTerminated {
            return makeAppContextMenu(for: running)
        }
        let menu = NSMenu(title: item.name)
        let lang = UserDefaults.standard.string(forKey: PrefKey.appLanguage) ?? "English (US)"
        let openTitle = "\(LocalizedStrings.translateText("Open", lang: lang)) \(item.name)"
        let openItem = NSMenuItem(title: openTitle, action: #selector(launchDockItemAction(_:)), keyEquivalent: "")
        openItem.target = self
        openItem.representedObject = item
        openItem.image = NSImage(systemSymbolName: "arrow.up.forward.app.fill", accessibilityDescription: nil)
        menu.addItem(openItem)

        if let url = item.bundleURL {
            let showTitle = LocalizedStrings.translateText("Show in Finder", lang: lang)
            let showItem = NSMenuItem(title: showTitle, action: #selector(showDockItemInFinderAction(_:)), keyEquivalent: "")
            showItem.target = self
            showItem.representedObject = url
            showItem.image = NSImage(systemSymbolName: "folder.fill", accessibilityDescription: nil)
            menu.addItem(showItem)
        }

        menu.addItem(NSMenuItem.separator())
        let settingsItem = NSMenuItem(title: LocalizedStrings.translateText("Genie Settings...", lang: lang), action: #selector(openGenieSettings), keyEquivalent: "")
        settingsItem.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)
        settingsItem.target = self
        menu.addItem(settingsItem)
        return menu
    }

    @objc private func launchDockItemAction(_ sender: NSMenuItem) {
        guard let item = sender.representedObject as? DockAppItem else { return }
        handleAppClick(item)
    }

    @objc private func showDockItemInFinderAction(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }

    private func makeLeoContextMenu() -> NSMenu {
        return makeLeoQuickSwitcherMenu()
    }

    public func showLeoQuickSwitcher(in view: NSView? = nil, event: NSEvent? = nil) {
        HapticFeedback.selection()
        let menu = makeLeoQuickSwitcherMenu()
        let targetView = view ?? AppDelegate.shared?.statusItem?.button
        guard let v = targetView else { return }

        let targetEvent: NSEvent
        if let ev = event, (ev.type == .leftMouseDown || ev.type == .rightMouseDown) {
            targetEvent = ev
        } else {
            let clickPt = leoFrame != .zero ? CGPoint(x: leoFrame.midX, y: leoFrame.midY) : CGPoint(x: 12, y: v.bounds.midY)
            let winPt = v.convert(clickPt, to: nil)
            targetEvent = NSEvent.mouseEvent(
                with: .leftMouseDown,
                location: winPt,
                modifierFlags: [],
                timestamp: ProcessInfo.processInfo.systemUptime,
                windowNumber: v.window?.windowNumber ?? 0,
                context: nil,
                eventNumber: 0,
                clickCount: 1,
                pressure: 1.0
            ) ?? (NSApp.currentEvent ?? NSEvent())
        }

        NSMenu.popUpContextMenu(menu, with: targetEvent, for: v)
    }

    public func makeLeoQuickSwitcherMenu() -> NSMenu {
        let menu = NSMenu(title: "Genie Quick Hub")
        let lang = UserDefaults.standard.string(forKey: PrefKey.appLanguage) ?? "English (US)"

        // 1. Header (disabled, matches battery header styling)
        let headerItem = NSMenuItem(title: "Genie Desktop", action: nil, keyEquivalent: "")
        headerItem.image = NSImage(systemSymbolName: "sparkles", accessibilityDescription: nil)
        headerItem.isEnabled = false
        menu.addItem(headerItem)

        // 2. Open Notes Folder
        let openNotesItem = NSMenuItem(title: LocalizedStrings.translateText("Open Notes Folder", lang: lang), action: #selector(openNotesDirectory), keyEquivalent: "")
        openNotesItem.image = NSImage(systemSymbolName: "folder.fill", accessibilityDescription: nil)
        openNotesItem.target = self
        menu.addItem(openNotesItem)

        menu.addItem(NSMenuItem.separator())

        // 3. Consolidated Preferences & Styles Submenu
        let quickPrefMenu = NSMenu(title: "Preferences & Styles")

        // Apple Logo Color
        let appleColorMenu = NSMenu(title: "Apple Logo Color")
        let currentAppleColor = UserDefaults.standard.string(forKey: PrefKey.menuBarAppleColor) ?? "Retro Rainbow 🌈"
        let appleColors = [
            "Retro Rainbow 🌈",
            "Neon Cyan ⚡️",
            "Liquid Gold 👑",
            "Emerald Green 🟢",
            "Ruby Red 🔴",
            "Amethyst Purple 💜",
            "Hot Pink 💖",
            "Tangerine Orange 🍊",
            "Classic White ⚪️"
        ]
        for color in appleColors {
            let item = NSMenuItem(title: color, action: #selector(selectAppleLogoColorItem(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = color
            item.state = (currentAppleColor == color) ? .on : .off
            appleColorMenu.addItem(item)
        }
        let appleColorSubItem = NSMenuItem(title: "Apple Logo Color ❯", action: nil, keyEquivalent: "")
        appleColorSubItem.image = NSImage(systemSymbolName: "apple.logo", accessibilityDescription: nil)
        appleColorSubItem.submenu = appleColorMenu
        quickPrefMenu.addItem(appleColorSubItem)

        // Slide-in Direction
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
            item.state = isCurrent ? .on : .off
            directionMenu.addItem(item)
        }
        let directionSubItem = NSMenuItem(title: "Slide-in Direction ❯", action: nil, keyEquivalent: "")
        directionSubItem.image = NSImage(systemSymbolName: "arrow.left.and.right", accessibilityDescription: nil)
        directionSubItem.submenu = directionMenu
        quickPrefMenu.addItem(directionSubItem)

        // Mini Dock Style
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
            item.state = isCurrent ? .on : .off
            dockStyleMenu.addItem(item)
        }
        let dockStyleSubItem = NSMenuItem(title: "Mini Dock Style ❯", action: nil, keyEquivalent: "")
        dockStyleSubItem.image = NSImage(systemSymbolName: "macwindow.on.rectangle", accessibilityDescription: nil)
        dockStyleSubItem.submenu = dockStyleMenu
        quickPrefMenu.addItem(dockStyleSubItem)

        quickPrefMenu.addItem(NSMenuItem.separator())

        // Printer Sounds Toggle
        let soundOn = UserDefaults.standard.bool(forKey: PrefKey.notePrinterSoundEnabled)
        let soundItem = NSMenuItem(
            title: soundOn ? "✓ Mechanical Printer Sounds" : "Mechanical Printer Sounds",
            action: #selector(togglePrinterSoundMenu),
            keyEquivalent: ""
        )
        soundItem.image = NSImage(systemSymbolName: soundOn ? "speaker.wave.2.fill" : "speaker.slash.fill", accessibilityDescription: nil)
        soundItem.target = self
        soundItem.state = soundOn ? .on : .off
        quickPrefMenu.addItem(soundItem)

        let quickPrefSubItem = NSMenuItem(title: LocalizedStrings.translateText("Preferences & Styles ❯", lang: lang), action: nil, keyEquivalent: "")
        quickPrefSubItem.image = NSImage(systemSymbolName: "slider.horizontal.3", accessibilityDescription: nil)
        quickPrefSubItem.submenu = quickPrefMenu
        menu.addItem(quickPrefSubItem)

        menu.addItem(NSMenuItem.separator())

        // 4. Genie Settings... ⌘,
        let settingsItem = NSMenuItem(title: LocalizedStrings.translateText("Genie Settings...", lang: lang), action: #selector(openGenieSettings), keyEquivalent: ",")
        settingsItem.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        // 5. Quit Genie ⌘Q
        let quitItem = NSMenuItem(title: LocalizedStrings.translateText("Quit Genie", lang: lang), action: #selector(quitGenie), keyEquivalent: "q")
        quitItem.image = NSImage(systemSymbolName: "power", accessibilityDescription: nil)
        quitItem.target = self
        menu.addItem(quitItem)

        return menu
    }

    @objc private func openNotesDirectory() {
        let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Desktop")
        let notesURL = desktopURL.appendingPathComponent("Notes")
        try? FileManager.default.createDirectory(at: notesURL, withIntermediateDirectories: true)
        NSWorkspace.shared.open(notesURL)
    }

    @objc private func togglePrinterSoundMenu() {
        let cur = UserDefaults.standard.bool(forKey: PrefKey.notePrinterSoundEnabled)
        UserDefaults.standard.set(!cur, forKey: PrefKey.notePrinterSoundEnabled)
        HapticFeedback.selection()
    }

    @objc public func openGenieSettings() {
        FinderChatWindowManager.shared.show(tab: .settings)
    }

    @objc public func openBatterySettings() {
        AppDelegate.shared?.toggleMenuBarSettingsDropdown(targetTab: .battery)
    }

    public func openApplicationsDropdown() {
        FinderChatWindowManager.shared.toggle()
    }

    public func openApplicationsDropdownFromBattery() {
        AppDelegate.shared?.toggleMenuBarSettingsDropdown(targetTab: .battery)
    }

    @objc public func toggleApplicationsOverlay() {
        // No applications pop up: toggle Chat window directly
        FinderChatWindowManager.shared.toggle()
    }

    @objc private func leoOpenSettings() {
        openGenieSettings()
    }

    @objc private func leoOpenPreferences() {
        openGenieSettings()
    }

    @objc private func selectAppleLogoColorItem(_ sender: NSMenuItem) {
        guard let color = sender.representedObject as? String else { return }
        HapticFeedback.selection()
        UserDefaults.standard.set(color, forKey: PrefKey.menuBarAppleColor)
        UserDefaults.standard.set(" Apple Logo", forKey: PrefKey.statusIconStyle)
        UserDefaults.standard.set("", forKey: PrefKey.statusIconGlyph)
        NotificationCenter.default.post(name: NSNotification.Name("NexusMenuBarAppleColorChanged"), object: color)
        NotificationCenter.default.post(name: NSNotification.Name("NexusIconStyleChanged"), object: nil)
        AppDelegate.shared?.renderIcon()
    }

    @objc public func quitGenie() {
        NSApplication.shared.terminate(nil)
    }

    private func makeAppContextMenu(for app: NSRunningApplication) -> NSMenu {
        let menu = NSMenu(title: app.localizedName ?? "App")
        let lang = UserDefaults.standard.string(forKey: PrefKey.appLanguage) ?? "English (US)"

        let bringFront = NSMenuItem(title: LocalizedStrings.translateText("Bring All to Front", lang: lang), action: #selector(appBringToFront(_:)), keyEquivalent: "")
        bringFront.target = self
        bringFront.representedObject = app
        menu.addItem(bringFront)

        let duplicateItem = NSMenuItem(title: LocalizedStrings.translateText("Duplicate View (New Window on This Desktop)", lang: lang), action: #selector(appDuplicateView(_:)), keyEquivalent: "n")
        duplicateItem.keyEquivalentModifierMask = [.command]
        duplicateItem.target = self
        duplicateItem.representedObject = app
        duplicateItem.image = NSImage(systemSymbolName: "plus.rectangle.on.rectangle", accessibilityDescription: nil)
        menu.addItem(duplicateItem)

        let showAll = NSMenuItem(title: LocalizedStrings.translateText("Show All Windows", lang: lang), action: #selector(appBringToFront(_:)), keyEquivalent: "")
        showAll.target = self
        showAll.representedObject = app
        menu.addItem(showAll)

        if app.isHidden {
            let unhide = NSMenuItem(title: LocalizedStrings.translateText("Unhide", lang: lang), action: #selector(appUnhide(_:)), keyEquivalent: "")
            unhide.target = self
            unhide.representedObject = app
            menu.addItem(unhide)
        } else {
            let hide = NSMenuItem(title: LocalizedStrings.translateText("Hide", lang: lang), action: #selector(appHide(_:)), keyEquivalent: "")
            hide.target = self
            hide.representedObject = app
            menu.addItem(hide)
        }

        menu.addItem(NSMenuItem.separator())

        let quit = NSMenuItem(title: LocalizedStrings.translateText("Quit", lang: lang), action: #selector(appQuit(_:)), keyEquivalent: "")
        quit.target = self
        quit.representedObject = app
        menu.addItem(quit)

        let forceQuit = NSMenuItem(title: LocalizedStrings.translateText("Force Quit", lang: lang), action: #selector(appForceQuit(_:)), keyEquivalent: "")
        forceQuit.target = self
        forceQuit.representedObject = app
        menu.addItem(forceQuit)

        menu.addItem(NSMenuItem.separator())

        let showFinder = NSMenuItem(title: LocalizedStrings.translateText("Show in Finder", lang: lang), action: #selector(appShowInFinder(_:)), keyEquivalent: "")
        showFinder.target = self
        showFinder.representedObject = app
        menu.addItem(showFinder)

        menu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(title: LocalizedStrings.translateText("Genie Settings...", lang: lang), action: #selector(openGenieSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        return menu
    }

    @objc private func appDuplicateView(_ sender: NSMenuItem) {
        guard let app = sender.representedObject as? NSRunningApplication else { return }
        duplicateAppView(app: app)
    }

    @objc private func appBringToFront(_ sender: NSMenuItem) {
        guard let app = sender.representedObject as? NSRunningApplication else { return }
        app.unhide()
        _ = app.activate(options: [.activateAllWindows])
        SmartGridManager.shared.bringToFront(app: app)
    }

    @objc private func appUnhide(_ sender: NSMenuItem) {
        guard let app = sender.representedObject as? NSRunningApplication else { return }
        app.unhide()
        _ = app.activate()
    }

    @objc private func appHide(_ sender: NSMenuItem) {
        guard let app = sender.representedObject as? NSRunningApplication else { return }
        app.hide()
    }

    @objc private func appQuit(_ sender: NSMenuItem) {
        guard let app = sender.representedObject as? NSRunningApplication else { return }
        app.terminate()
    }

    @objc private func appForceQuit(_ sender: NSMenuItem) {
        guard let app = sender.representedObject as? NSRunningApplication else { return }
        app.forceTerminate()
    }

    @objc private func appShowInFinder(_ sender: NSMenuItem) {
        guard let app = sender.representedObject as? NSRunningApplication else { return }
        let targetURL = app.bundleURL ?? (app.bundleIdentifier != nil ? NSWorkspace.shared.urlForApplication(withBundleIdentifier: app.bundleIdentifier!) : nil)
        if let url = targetURL {
            NSWorkspace.shared.activateFileViewerSelecting([url])
        }
    }

    private func makeFinderContextMenu() -> NSMenu {
        let menu = NSMenu(title: "Finder")
        let lang = UserDefaults.standard.string(forKey: PrefKey.appLanguage) ?? "English (US)"

        let newWin = NSMenuItem(title: LocalizedStrings.translateText("New Finder Window", lang: lang), action: #selector(finderNewWindow), keyEquivalent: "")
        newWin.image = NSImage(systemSymbolName: "macwindow.badge.plus", accessibilityDescription: nil)
        newWin.target = self
        menu.addItem(newWin)

        let apps = NSMenuItem(title: LocalizedStrings.translateText("Go to Applications", lang: lang), action: #selector(finderGoApplications), keyEquivalent: "")
        apps.image = NSImage(systemSymbolName: "square.grid.2x2", accessibilityDescription: nil)
        apps.target = self
        menu.addItem(apps)

        let desktop = NSMenuItem(title: LocalizedStrings.translateText("Go to Desktop", lang: lang), action: #selector(finderGoDesktop), keyEquivalent: "")
        desktop.image = NSImage(systemSymbolName: "desktopcomputer", accessibilityDescription: nil)
        desktop.target = self
        menu.addItem(desktop)

        let downloads = NSMenuItem(title: LocalizedStrings.translateText("Go to Downloads", lang: lang), action: #selector(finderGoDownloads), keyEquivalent: "")
        downloads.image = NSImage(systemSymbolName: "arrow.down.circle", accessibilityDescription: nil)
        downloads.target = self
        menu.addItem(downloads)

        menu.addItem(NSMenuItem.separator())

        // Finder Color Submenu
        let finderColorMenu = NSMenu(title: "Finder Color")
        let currentFinderColor = UserDefaults.standard.string(forKey: PrefKey.finderColor) ?? "Classic Blue 🔵"
        let finderColors = [
            ("Classic Blue 🔵", "Classic Blue 🔵"),
            ("Neon Cyan ⚡️", "Neon Cyan ⚡️"),
            ("Liquid Gold 👑", "Liquid Gold 👑"),
            ("Emerald Green 🟢", "Emerald Green 🟢"),
            ("Ruby Red 🔴", "Ruby Red 🔴"),
            ("Amethyst Purple 💜", "Amethyst Purple 💜"),
            ("Hot Pink 💖", "Hot Pink 💖"),
            ("Tangerine Orange 🍊", "Tangerine Orange 🍊"),
            ("Silver / Monochrome ⚪️", "Silver / Monochrome ⚪️")
        ]
        for (label, key) in finderColors {
            let item = NSMenuItem(title: label, action: #selector(selectFinderColorItem(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = key
            item.state = (currentFinderColor == key) ? .on : .off
            finderColorMenu.addItem(item)
        }
        let finderColorSubItem = NSMenuItem(title: "Finder Color ❯", action: nil, keyEquivalent: "")
        finderColorSubItem.image = NSImage(systemSymbolName: "paintpalette", accessibilityDescription: nil)
        finderColorSubItem.submenu = finderColorMenu
        menu.addItem(finderColorSubItem)

        // Finder Style Submenu
        let styleMenu = NSMenu(title: "Finder Icon Style")
        let currentStyle = UserDefaults.standard.string(forKey: PrefKey.finderIconStyle) ?? "Finder Face (Default)"
        let styles = [("Finder Face (Default) ", "Finder Face (Default)"), ("Folder 📁", "Folder")]
        for (label, key) in styles {
            let item = NSMenuItem(title: label, action: #selector(selectFinderIconStyleItem(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = key
            item.state = (currentStyle == key) ? .on : .off
            styleMenu.addItem(item)
        }
        let styleSubItem = NSMenuItem(title: "Finder Style ❯", action: nil, keyEquivalent: "")
        styleSubItem.image = NSImage(systemSymbolName: "macwindow", accessibilityDescription: nil)
        styleSubItem.submenu = styleMenu
        menu.addItem(styleSubItem)

        menu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(title: LocalizedStrings.translateText("Genie Settings...", lang: lang), action: #selector(openGenieSettings), keyEquivalent: ",")
        settingsItem.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)
        settingsItem.target = self
        menu.addItem(settingsItem)

        return menu
    }

    @objc private func selectFinderColorItem(_ sender: NSMenuItem) {
        guard let color = sender.representedObject as? String else { return }
        HapticFeedback.selection()
        UserDefaults.standard.set(color, forKey: PrefKey.finderColor)
        NotificationCenter.default.post(name: NSNotification.Name("NexusFinderColorChanged"), object: color)
        AppDelegate.shared?.renderIcon()
    }

    @objc private func selectFinderIconStyleItem(_ sender: NSMenuItem) {
        guard let style = sender.representedObject as? String else { return }
        HapticFeedback.selection()
        UserDefaults.standard.set(style, forKey: PrefKey.finderIconStyle)
        NotificationCenter.default.post(name: NSNotification.Name("NexusFinderIconStyleChanged"), object: style)
        AppDelegate.shared?.renderIcon()
    }

    @objc private func finderNewWindow() {
        openNativeFinder()
    }

    @objc private func finderGoApplications() {
        let url = URL(fileURLWithPath: "/Applications")
        NSWorkspace.shared.open(url)
        if let f = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.finder").first {
            f.unhide()
            f.activate(options: [.activateAllWindows])
        }
    }

    @objc private func finderGoDesktop() {
        let url = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSHomeDirectory() + "/Desktop")
        NSWorkspace.shared.open(url)
        if let f = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.finder").first {
            f.unhide()
            f.activate(options: [.activateAllWindows])
        }
    }

    @objc private func finderGoDownloads() {
        let url = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSHomeDirectory() + "/Downloads")
        NSWorkspace.shared.open(url)
        if let f = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.finder").first {
            f.unhide()
            f.activate(options: [.activateAllWindows])
        }
    }

    private func makeTrashContextMenu() -> NSMenu {
        let menu = NSMenu(title: "Trash")
        let lang = UserDefaults.standard.string(forKey: PrefKey.appLanguage) ?? "English (US)"

        let openItem = NSMenuItem(title: LocalizedStrings.translateText("Open Trash", lang: lang), action: #selector(openTrashAction), keyEquivalent: "")
        openItem.image = NSImage(systemSymbolName: "trash", accessibilityDescription: nil)
        openItem.target = self
        menu.addItem(openItem)

        let emptyItem = NSMenuItem(title: LocalizedStrings.translateText("Empty Trash", lang: lang), action: #selector(emptyTrashAction), keyEquivalent: "")
        emptyItem.image = NSImage(systemSymbolName: "trash.slash", accessibilityDescription: nil)
        emptyItem.target = self
        menu.addItem(emptyItem)

        menu.addItem(NSMenuItem.separator())

        let settingsItem = NSMenuItem(title: LocalizedStrings.translateText("Genie Settings...", lang: lang), action: #selector(openGenieSettings), keyEquivalent: ",")
        settingsItem.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)
        settingsItem.target = self
        menu.addItem(settingsItem)

        return menu
    }

    @objc public func openTrashAction() {
        openNativeTrash()
    }

    @objc public func emptyTrashAction() {
        emptyNativeTrash()
    }

    public func openNativeTrash() {
        HapticFeedback.selection()
        let script = "tell application \"Finder\"\nopen trash\nactivate\nend tell"
        NSAppleScript(source: script)?.executeAndReturnError(nil)
    }

    public func emptyNativeTrash() {
        HapticFeedback.selection()
        let script = "tell application \"Finder\"\nempty trash\nend tell"
        NSAppleScript(source: script)?.executeAndReturnError(nil)
    }


    // MARK: - Battery Quick Switcher (Simple Choices for Battery Bar & Percentages)

    public func showBatteryQuickSwitcher(in view: NSView? = nil, event: NSEvent? = nil) {
        HapticFeedback.selection()
        let menu = makeBatteryQuickSwitcherMenu()
        let targetView = view ?? AppDelegate.shared?.statusItem?.button
        guard let v = targetView else { return }

        let targetEvent: NSEvent
        if let ev = event, (ev.type == .leftMouseDown || ev.type == .rightMouseDown) {
            targetEvent = ev
        } else {
            let clickPt = batteryFrame != .zero ? CGPoint(x: batteryFrame.midX, y: batteryFrame.midY) : CGPoint(x: v.bounds.maxX - 20, y: v.bounds.midY)
            let winPt = v.convert(clickPt, to: nil)
            targetEvent = NSEvent.mouseEvent(
                with: .leftMouseDown,
                location: winPt,
                modifierFlags: [],
                timestamp: ProcessInfo.processInfo.systemUptime,
                windowNumber: v.window?.windowNumber ?? 0,
                context: nil,
                eventNumber: 0,
                clickCount: 1,
                pressure: 1.0
            ) ?? (NSApp.currentEvent ?? NSEvent())
        }

        NSMenu.popUpContextMenu(menu, with: targetEvent, for: v)
    }

    private func makeBatteryContextMenu() -> NSMenu {
        return makeCompleteBatteryPopoutMenu()
    }

    public func makeBatteryQuickSwitcherMenu() -> NSMenu {
        return makeCompleteBatteryPopoutMenu()
    }

    @objc public func selectSlideDirectionItem(_ sender: NSMenuItem) {
        guard let dir = sender.representedObject as? String else { return }
        HapticFeedback.selection()
        UserDefaults.standard.set(dir, forKey: PrefKey.gridTransitionDirection)
    }

    @objc public func selectBatteryStyleItem(_ sender: NSMenuItem) {
        guard let style = sender.representedObject as? String else { return }
        HapticFeedback.selection()
        UserDefaults.standard.set(style, forKey: PrefKey.batteryStyle)
        UserDefaults.standard.set(style, forKey: PrefKey.iconStyle)
        NotificationCenter.default.post(name: NSNotification.Name("NexusIconStyleChanged"), object: style)
        NotificationCenter.default.post(name: NSNotification.Name("NexusBatteryEnabledChanged"), object: nil)
        AppDelegate.shared?.renderIcon()
    }

    @objc public func toggleBatteryPercentage() {
        HapticFeedback.selection()
        let current = UserDefaults.standard.bool(forKey: PrefKey.showBatteryPercentage)
        let next = !current
        UserDefaults.standard.set(next, forKey: PrefKey.showBatteryPercentage)
        NotificationCenter.default.post(name: NSNotification.Name("NexusBatteryPercentageChanged"), object: next)
        NotificationCenter.default.post(name: NSNotification.Name("NexusBatteryEnabledChanged"), object: nil)
        AppDelegate.shared?.renderIcon()
    }

    @objc public func toggleChargingBolt() {
        HapticFeedback.selection()
        let current = UserDefaults.standard.object(forKey: PrefKey.showChargingBolt) == nil ? true : UserDefaults.standard.bool(forKey: PrefKey.showChargingBolt)
        let next = !current
        UserDefaults.standard.set(next, forKey: PrefKey.showChargingBolt)
        NotificationCenter.default.post(name: NSNotification.Name("NexusShowChargingBoltChanged"), object: next)
        NotificationCenter.default.post(name: NSNotification.Name("NexusBatteryEnabledChanged"), object: nil)
        AppDelegate.shared?.renderIcon()
    }

    @objc public func toggleDesktopFilesAction() {
        HapticFeedback.selection()
        DesktopFilesManager.shared.toggleDesktopFiles()
    }

    @objc public func selectColorModeItem(_ sender: NSMenuItem) {
        guard let mode = sender.representedObject as? String else { return }
        HapticFeedback.selection()
        UserDefaults.standard.set(mode, forKey: PrefKey.batteryColorMode)
        NotificationCenter.default.post(name: NSNotification.Name("NexusBatteryColorModeChanged"), object: mode)
        NotificationCenter.default.post(name: NSNotification.Name("NexusBatteryEnabledChanged"), object: nil)
        AppDelegate.shared?.renderIcon()
    }

    @objc public func cycleNextBatteryStyle() {
        HapticFeedback.selection()
        let simpleStyles = [
            "DNA Helix",
            "10-Bar Equalizer",
            "Classic Apple Battery",
            "Liquid Wave",
            "Cyber Neon Digits",
            "Apple Minimal",
            "Circular Dual Arc",
            "Pixel Heart"
        ]
        let current = UserDefaults.standard.string(forKey: PrefKey.batteryStyle)
            ?? UserDefaults.standard.string(forKey: PrefKey.iconStyle)
            ?? "DNA Helix"
        let idx = simpleStyles.firstIndex(of: current) ?? 0
        let nextStyle = simpleStyles[(idx + 1) % simpleStyles.count]
        UserDefaults.standard.set(nextStyle, forKey: PrefKey.batteryStyle)
        UserDefaults.standard.set(nextStyle, forKey: PrefKey.iconStyle)
        NotificationCenter.default.post(name: NSNotification.Name("NexusIconStyleChanged"), object: nextStyle)
        NotificationCenter.default.post(name: NSNotification.Name("NexusBatteryEnabledChanged"), object: nil)
        AppDelegate.shared?.renderIcon()
    }

    @objc public func selectMiniDockStyleItem(_ sender: NSMenuItem) {
        guard let style = sender.representedObject as? String else { return }
        HapticFeedback.selection()
        UserDefaults.standard.set(style, forKey: PrefKey.miniDockBackgroundStyle)
        NotificationCenter.default.post(name: NSNotification.Name("NexusMiniDockStyleChanged"), object: style)
        AppDelegate.shared?.renderIcon()
    }
}
