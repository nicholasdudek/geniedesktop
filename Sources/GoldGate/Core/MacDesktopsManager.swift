import AppKit
import SwiftUI
import ScreenCaptureKit

// MARK: - Mac Desktop Space Model

public struct MacDesktopSpace: Identifiable, Equatable {
    public let id: String
    public var index: Int
    public var name: String
    public var isCurrent: Bool
    public let id64: UInt64?
    public let displayIdentifier: String?

    public init(id: String, index: Int, name: String, isCurrent: Bool, id64: UInt64? = nil, displayIdentifier: String? = nil) {
        self.id = id
        self.index = index
        self.name = name
        self.isCurrent = isCurrent
        self.id64 = id64
        self.displayIdentifier = displayIdentifier
    }
}

// MARK: - Mac Desktops & Spaces Manager

@MainActor
public final class MacDesktopsManager: ObservableObject {
    public static let shared = MacDesktopsManager()

    @Published public private(set) var spaces: [MacDesktopSpace] = []
    @Published public private(set) var currentSpaceIndex: Int = 1
    @Published public var previewWallpaper: NSImage? = nil
    @Published public var isSwitchingSpace: Bool = false
    @Published public var customSpacesOrder: [Int] = (UserDefaults.standard.array(forKey: PrefKey.customSpacesOrder) as? [Int]) ?? []

    private var workspaceObserver: Any?
    private var activeCaptureTask: Task<Void, Never>?
    private var notificationObservers: [NSObjectProtocol] = []

    public func displayOrderIndices() -> [Int] {
        let natural = spaces.count < 3 ? [1, 2, 3] : spaces.map { $0.index }
        if customSpacesOrder.isEmpty {
            return natural
        }
        var result = customSpacesOrder.filter { natural.contains($0) }
        for n in natural {
            if !result.contains(n) {
                result.append(n)
            }
        }
        return result
    }

    public static func resolvedAspectRatio() -> CGFloat {
        let mode = UserDefaults.standard.string(forKey: PrefKey.displayAspectRatioMode) ?? "Auto (Native Display)"
        switch mode {
        case "16:10 (MacBook)":
            return 16.0 / 10.0
        case "16:9 (Standard 4K)":
            return 16.0 / 9.0
        case "21:9 (UltraWide)":
            return 21.0 / 9.0
        case "3:2 (Creative Pro)":
            return 3.0 / 2.0
        default:
            guard let screen = NSScreen.main ?? NSScreen.screens.first else { return 16.0 / 10.0 }
            let w = screen.frame.width
            let h = max(1.0, screen.frame.height)
            return max(0.5, min(4.0, w / h))
        }
    }

    public func reorderDesktops(fromIndex: Int, toIndex: Int) {
        var currentOrder = displayOrderIndices()
        guard fromIndex >= 0 && fromIndex < currentOrder.count,
              toIndex >= 0 && toIndex < currentOrder.count,
              fromIndex != toIndex else { return }

        let item = currentOrder.remove(at: fromIndex)
        currentOrder.insert(item, at: toIndex)
        self.customSpacesOrder = currentOrder
        UserDefaults.standard.set(currentOrder, forKey: PrefKey.customSpacesOrder)
        HapticFeedback.selection()
        objectWillChange.send()
    }

    private init() {
        refreshSpaces()
        setupObserver()
    }

    deinit {
        if let obs = workspaceObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(obs)
        }
        for obs in notificationObservers {
            NotificationCenter.default.removeObserver(obs)
        }
        notificationObservers.removeAll()
        activeCaptureTask?.cancel()
    }

    private func setupObserver() {
        workspaceObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refreshSpaces()
                self?.captureCurrentDesktopLivePreview()
                NotificationCenter.default.post(name: NSNotification.Name("NexusDesktopSpaceDidChange"), object: self?.currentSpaceIndex)
                NotificationCenter.default.post(name: NSNotification.Name("NexusActiveSpaceDidChange"), object: self?.currentSpaceIndex)
            }
            // Multi-phase retries to catch asynchronous WindowServer disk flushes
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                Task { @MainActor in
                    self?.refreshSpaces()
                    self?.captureCurrentDesktopLivePreview()
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.40) {
                Task { @MainActor in
                    self?.refreshSpaces()
                }
            }
        }

        // Direct command listener: Switch to desktop by index
        let o1 = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NexusSwitchToDesktop"),
            object: nil,
            queue: .main
        ) { [weak self] notif in
            if let index = notif.object as? Int {
                Task { @MainActor in
                    self?.switchToDesktop(index: index)
                }
            }
        }
        notificationObservers.append(o1)

        // Direct command listener: Next desktop
        let o2 = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NexusNextDesktop"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.navigateNext()
            }
        }
        notificationObservers.append(o2)

        // Direct command listener: Previous desktop
        let o3 = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NexusPreviousDesktop"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.navigatePrevious()
            }
        }
        notificationObservers.append(o3)
    }

    public func refreshSpaces() {
        self.previewWallpaper = WallpaperManager.shared.activeWallpaperImage

        // Force CoreFoundation to synchronize com.apple.spaces from disk in real-time
        CFPreferencesSynchronize("com.apple.spaces" as CFString, kCFPreferencesCurrentUser, kCFPreferencesAnyHost)

        if let dict = CFPreferencesCopyAppValue("SpacesDisplayConfiguration" as CFString, "com.apple.spaces" as CFString) as? [String: Any],
           let mgmt = dict["Management Data"] as? [String: Any],
           let monitors = mgmt["Monitors"] as? [[String: Any]] {

            let targetMonitor = monitors.first(where: {
                let spaces = $0["Spaces"] as? [[String: Any]]
                return !(spaces?.isEmpty ?? true)
            }) ?? monitors.first

            if let mainMonitor = targetMonitor {
                var foundSpaces: [MacDesktopSpace] = []
                let liveSpaceID = getLiveActiveSpaceID()
                let currentSpaceID = (mainMonitor["Current Space"] as? [String: Any])?["ManagedSpaceID"] as? Int
                let fallbackDisplayID = (mainMonitor["Current Space"] as? [String: Any])?["Display Identifier"] as? String
                    ?? mainMonitor["Display Identifier"] as? String

                if let spaceList = mainMonitor["Spaces"] as? [[String: Any]], !spaceList.isEmpty {
                    for (idx, sDict) in spaceList.enumerated() {
                        let spaceID = sDict["ManagedSpaceID"] as? Int ?? (idx + 1)
                        let id64Val = (sDict["id64"] as? NSNumber)?.uint64Value ?? UInt64(spaceID)
                        let dispID = (sDict["Display Identifier"] as? String) ?? fallbackDisplayID
                        let uuid = sDict["uuid"] as? String ?? "\(idx + 1)"
                        let isCur: Bool = {
                            if let live = liveSpaceID {
                                return id64Val == live || UInt64(spaceID) == live
                            }
                            return (spaceID == currentSpaceID) || (currentSpaceID == nil && idx == 0)
                        }()
                        let space = MacDesktopSpace(
                            id: uuid,
                            index: idx + 1,
                            name: "Desktop \(idx + 1)",
                            isCurrent: isCur,
                            id64: id64Val,
                            displayIdentifier: dispID
                        )
                        foundSpaces.append(space)
                        if isCur {
                            self.currentSpaceIndex = idx + 1
                        }
                    }
                }

                if !foundSpaces.isEmpty {
                    // Fallback: If no space was matched as current, preserve currentSpaceIndex
                    if !foundSpaces.contains(where: { $0.isCurrent }) && self.currentSpaceIndex <= foundSpaces.count {
                        let curIdx = max(1, min(foundSpaces.count, self.currentSpaceIndex))
                        foundSpaces[curIdx - 1].isCurrent = true
                    }
                    self.spaces = foundSpaces
                    self.seedInitialThumbnails()
                    return
                }
            }
        }

        // Fallback: Populate with active screens or at least 2 spaces
        let count = max(2, NSScreen.screens.count)
        var fallbackSpaces: [MacDesktopSpace] = []
        for i in 1...count {
            fallbackSpaces.append(MacDesktopSpace(
                id: "space-\(i)",
                index: i,
                name: "Desktop \(i)",
                isCurrent: i == currentSpaceIndex
            ))
        }
        self.spaces = fallbackSpaces
        self.seedInitialThumbnails()
    }

    // MARK: - Navigation (Short Arrows & Direct Switch)

    public func navigatePrevious() {
        HapticFeedback.selection()
        if currentSpaceIndex > 1 {
            switchToDesktop(index: currentSpaceIndex - 1)
        } else {
            postKeyCombo(keyCode: 123, flags: .maskControl)
        }
    }

    public func navigateNext() {
        HapticFeedback.selection()
        if currentSpaceIndex < spaces.count {
            switchToDesktop(index: currentSpaceIndex + 1)
        } else {
            postKeyCombo(keyCode: 124, flags: .maskControl)
        }
    }

    // SkyLight private function pointer types for direct instant Space switching
    private typealias SLSMainConnectionIDFunc = @convention(c) () -> Int32
    private typealias SLSManagedDisplaySetCurrentSpaceFunc = @convention(c) (Int32, CFString, UInt64) -> Int32
    private typealias SLSCopyManagedDisplaysFunc = @convention(c) (Int32) -> CFArray?
    private typealias CGSGetActiveSpaceFunc = @convention(c) (Int32) -> UInt64

    public func getLiveActiveSpaceID() -> UInt64? {
        guard let handle = dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight", RTLD_LAZY) ?? dlopen(nil, RTLD_LAZY),
              let cidSym = dlsym(handle, "SLSMainConnectionID"),
              let getActiveSpaceSym = dlsym(handle, "CGSGetActiveSpace") else {
            return nil
        }
        let getCID = unsafeBitCast(cidSym, to: SLSMainConnectionIDFunc.self)
        let getActiveSpace = unsafeBitCast(getActiveSpaceSym, to: CGSGetActiveSpaceFunc.self)
        let cid = getCID()
        let activeID = getActiveSpace(cid)
        return activeID > 0 ? activeID : nil
    }

    public func switchSpaceViaSkyLight(targetSpaceID: UInt64, displayID: String? = nil) -> Bool {
        guard let handle = dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight", RTLD_LAZY) ?? dlopen(nil, RTLD_LAZY),
              let cidSym = dlsym(handle, "SLSMainConnectionID"),
              let setSpaceSym = dlsym(handle, "SLSManagedDisplaySetCurrentSpace") else {
            return false
        }

        let getCID = unsafeBitCast(cidSym, to: SLSMainConnectionIDFunc.self)
        let setSpace = unsafeBitCast(setSpaceSym, to: SLSManagedDisplaySetCurrentSpaceFunc.self)
        let cid = getCID()

        // 1. Query all active hardware managed displays via SkyLight FIRST (uses real UUIDs like 37D8832A-...)
        if let copyDisplaysSym = dlsym(handle, "SLSCopyManagedDisplays") {
            let copyDisplays = unsafeBitCast(copyDisplaysSym, to: SLSCopyManagedDisplaysFunc.self)
            if let displays = copyDisplays(cid) as? [CFString], !displays.isEmpty {
                var anySucceeded = false
                for d in displays {
                    if setSpace(cid, d, targetSpaceID) == 0 {
                        anySucceeded = true
                    }
                }
                if anySucceeded { return true }
            }
        }

        // 2. Try explicit display ID if it is a valid UUID (not "Main")
        if let dID = displayID, !dID.isEmpty && dID != "Main" {
            if setSpace(cid, dID as CFString, targetSpaceID) == 0 {
                return true
            }
        }

        // 3. Last fallback to "Main"
        return setSpace(cid, "Main" as CFString, targetSpaceID) == 0
    }

    public func switchToDesktop(index: Int) {
        guard index >= 1 && index <= 9 else { return }
        refreshSpaces()

        // Clamp to existing active spaces so we never jump erratically to unused screens
        let availableCount = max(1, spaces.count)
        let safeIndex = min(index, availableCount)

        HapticFeedback.heavy()
        let previousIndex = currentSpaceIndex
        currentSpaceIndex = safeIndex
        updateCurrentFlag()

        // 1. Lock popover in place: tell AppDelegate not to dismiss during the desktop transition
        isSwitchingSpace = true
        NotificationCenter.default.post(name: NSNotification.Name("NexusWillSwitchSpace"), object: index)

        // 2. Instant hardware space transition via SkyLight (sub-millisecond hardware transition)
        var skyLightSucceeded = false
        if let targetSpace = spaces.first(where: { $0.index == index }), let id64 = targetSpace.id64 {
            skyLightSucceeded = switchSpaceViaSkyLight(targetSpaceID: id64, displayID: targetSpace.displayIdentifier)
        } else {
            refreshSpaces()
            if let targetSpace = spaces.first(where: { $0.index == index }), let id64 = targetSpace.id64 {
                skyLightSucceeded = switchSpaceViaSkyLight(targetSpaceID: id64, displayID: targetSpace.displayIdentifier)
            }
        }

        // 3. Fallback Space Navigation: ONLY if SkyLight hardware transition did not succeed
        if !skyLightSucceeded {
            let delta = index - previousIndex
            if delta != 0 {
                let arrowCode: CGKeyCode = (delta > 0) ? 124 : 123
                let count = abs(delta)
                DispatchQueue.global(qos: .userInteractive).async {
                    let script = """
                    tell application "System Events"
                        repeat \(count) times
                            key code \(arrowCode) using control down
                            delay 0.06
                        end repeat
                    end tell
                    """
                    if let appleScript = NSAppleScript(source: script) {
                        var error: NSDictionary?
                        appleScript.executeAndReturnError(&error)
                    } else {
                        for _ in 0..<count {
                            Self.postKeyComboDirect(keyCode: arrowCode, flags: .maskControl)
                            usleep(60_000)
                        }
                    }
                }
            }
        }

        // 4. Transition settle: verify the switch actually happened and notify
        verifySpaceSwitch(targetIndex: safeIndex, attempts: 5)
    }

    private func verifySpaceSwitch(targetIndex: Int, attempts: Int) {
        Task { @MainActor in
            for i in 0..<attempts {
                refreshSpaces()
                if self.currentSpaceIndex == targetIndex {
                    break
                }
                try? await Task.sleep(nanoseconds: 100_000_000) // 0.1s
            }
            self.isSwitchingSpace = false
            NotificationCenter.default.post(name: NSNotification.Name("NexusDidSwitchSpace"), object: targetIndex)
        }
    }

    // MARK: - Clone Desktop Feature ("why is it so hard to clone the desktop with a new desktop")
    public func cloneDesktop(from sourceIndex: Int? = nil) {
        _ = sourceIndex ?? currentSpaceIndex
        guard spaces.count < 9 else {
            NSSound.beep()
            return
        }
        HapticFeedback.heavy()

        // 1. Snapshot running applications
        let runningApps = NSWorkspace.shared.runningApplications.filter {
            $0.activationPolicy == .regular && !$0.isHidden && $0.bundleIdentifier != "com.nicholasdudek.genie"
        }
        let appURLs = runningApps.compactMap { $0.bundleURL }

        // 2. Create new desktop space
        createDesktop()
        let newIndex = min(spaces.count, 9)

        // 3. Glide smoothly to new space with exact state
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.switchToDesktop(index: newIndex)

            // 4. In new space, launch/activate cloned apps
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
                for url in appURLs {
                    let config = NSWorkspace.OpenConfiguration()
                    config.createsNewApplicationInstance = false
                    config.activates = true
                    NSWorkspace.shared.openApplication(at: url, configuration: config, completionHandler: nil)
                }
            }
        }
    }

    // MARK: - Close / Delete Desktop Feature ("i cant close desktops")
    public func closeDesktop(index: Int) {
        guard spaces.count > 1 && index > 1 else {
            NSSound.beep()
            return
        }
        HapticFeedback.heavy()

        // 1. If we are currently on this space, switch to Desktop 1 (or index - 1)
        if currentSpaceIndex == index {
            switchToDesktop(index: max(1, index - 1))
        }

        // 2. Close all windows on that desktop
        closeAllWindowsOnActiveDesktop()

        // 3. Hardware destruction attempt via SkyLight
        if let targetSpace = spaces.first(where: { $0.index == index }),
           let id64 = targetSpace.id64 {
            typealias SLSMainConnectionIDFunc = @convention(c) () -> Int32
            typealias SLSSpaceDestroyFunc = @convention(c) (Int32, UInt64) -> Int32

            if let handle = dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/Versions/A/SkyLight", RTLD_LAZY),
               let cidSym = dlsym(handle, "SLSMainConnectionID"),
               let destroySym = dlsym(handle, "SLSSpaceDestroy") {
                let getCID = unsafeBitCast(cidSym, to: SLSMainConnectionIDFunc.self)
                let destroy = unsafeBitCast(destroySym, to: SLSSpaceDestroyFunc.self)
                _ = destroy(getCID(), id64)
                dlclose(handle)
            }
        }

        // 4. Remove space locally with animation
        withAnimation(.spring(response: 0.25, dampingFraction: 0.78)) {
            spaces.removeAll(where: { $0.index == index })
            for i in 0..<spaces.count {
                spaces[i].index = i + 1
                spaces[i].name = "Desktop \(i + 1)"
            }
            if currentSpaceIndex >= index {
                currentSpaceIndex = max(1, currentSpaceIndex - 1)
            }
        }
    }

    public func hideAllWindowsAndJump(to index: Int) {
        HapticFeedback.heavy()
        let myPid = ProcessInfo.processInfo.processIdentifier
        for app in NSWorkspace.shared.runningApplications {
            if app.processIdentifier != myPid && app.activationPolicy == .regular {
                app.hide()
            }
        }
        switchToDesktop(index: index)
    }

    public func showDesktopWallpaper() {
        HapticFeedback.selection()
        let script = """
        tell application "System Events"
            key code 103 using {}
        end tell
        """
        DispatchQueue.global(qos: .userInteractive).async {
            NSAppleScript(source: script)?.executeAndReturnError(nil)
        }
    }

    public func maximizeAllWindowsOnActiveScreen() {
        HapticFeedback.selection()
        let script = """
        tell application "System Events"
            set appList to every process whose visible is true and background only is false
            repeat with proc in appList
                try
                    tell proc
                        repeat with win in windows
                            try
                                set value of attribute "AXZoomButton" of win to true
                            end try
                        end repeat
                    end tell
                end try
            end repeat
        end tell
        """
        DispatchQueue.global(qos: .userInteractive).async {
            NSAppleScript(source: script)?.executeAndReturnError(nil)
        }
    }

    public func closeAllWindowsOnActiveDesktop() {
        HapticFeedback.heavy()
        let script = """
        tell application "System Events"
            set appList to every process whose visible is true and background only is false
            repeat with proc in appList
                try
                    tell proc
                        repeat with win in windows
                            try
                                perform action "AXCancel" of win
                            end try
                            try
                                click (first button of win whose subrole is "AXCloseButton")
                            end try
                        end repeat
                    end tell
                end try
            end repeat
        end tell
        """
        DispatchQueue.global(qos: .userInteractive).async {
            NSAppleScript(source: script)?.executeAndReturnError(nil)
        }
    }

    public func deleteDesktop(index: Int) {
        guard spaces.count > 1 && index > 1 else {
            NSSound.beep()
            return
        }
        HapticFeedback.heavy()

        // 1. Hardware destruction via SkyLight
        if let targetSpace = spaces.first(where: { $0.index == index }),
           let id64 = targetSpace.id64 {
            typealias SLSMainConnectionIDFunc = @convention(c) () -> Int32
            typealias SLSSpaceDestroyFunc = @convention(c) (Int32, UInt64) -> Int32

            if let handle = dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/Versions/A/SkyLight", RTLD_LAZY),
               let cidSym = dlsym(handle, "SLSMainConnectionID"),
               let destroySym = dlsym(handle, "SLSSpaceDestroy") {
                let getCID = unsafeBitCast(cidSym, to: SLSMainConnectionIDFunc.self)
                let destroy = unsafeBitCast(destroySym, to: SLSSpaceDestroyFunc.self)
                _ = destroy(getCID(), id64)
                dlclose(handle)
            }
        }

        // 2. Remove space from state with animation
        withAnimation(.spring(response: 0.25, dampingFraction: 0.78)) {
            spaces.removeAll(where: { $0.index == index })
            for i in 0..<spaces.count {
                spaces[i].index = i + 1
                spaces[i].name = "Desktop \(i + 1)"
            }
            if currentSpaceIndex >= index {
                currentSpaceIndex = max(1, currentSpaceIndex - 1)
            }
        }

        // 3. Switch to remaining desktop
        switchToDesktop(index: currentSpaceIndex)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.refreshSpaces()
        }
    }

    private func updateCurrentFlag() {
        for i in 0..<spaces.count {
            spaces[i].isCurrent = (spaces[i].index == currentSpaceIndex)
        }
    }

    nonisolated public static func postKeyComboDirect(keyCode: CGKeyCode, flags: CGEventFlags) {
        let src = CGEventSource(stateID: .hidSystemState)
        if let down = CGEvent(keyboardEventSource: src, virtualKey: keyCode, keyDown: true),
           let up = CGEvent(keyboardEventSource: src, virtualKey: keyCode, keyDown: false) {
            down.flags = flags
            up.flags = flags
            down.post(tap: .cghidEventTap)
            usleep(30_000)
            up.post(tap: .cghidEventTap)
        }
    }

    nonisolated private func postKeyCombo(keyCode: CGKeyCode, flags: CGEventFlags) {
        Self.postKeyComboDirect(keyCode: keyCode, flags: flags)
    }

    @Published public var desktopLivePreviews: [Int: NSImage] = [:]

    public static func curatedThemeForSlot(_ slot: Int) -> String {
        switch slot {
        case 1: return "Sequoia Dark"
        case 2: return "Sonoma Horizon"
        case 3: return "Ventura Aurora"
        case 4: return "Monterey Sunset"
        case 5: return "Deep Space"
        case 6: return "Emerald Forest"
        case 7: return "Midnight Indigo"
        case 8: return "Obsidian Titanium"
        case 9: return "Cyberpunk Matrix"
        default: return "Sequoia Dark"
        }
    }

    public func seedInitialThumbnails() {
        for i in 1...max(2, spaces.count) {
            if desktopLivePreviews[i] == nil {
                if i == currentSpaceIndex {
                    desktopLivePreviews[i] = WallpaperManager.shared.activeWallpaperImage ?? WallpaperManager.shared.generateCuratedWallpaper(named: "Sequoia Dark")
                } else {
                    desktopLivePreviews[i] = WallpaperManager.shared.generateCuratedWallpaper(named: Self.curatedThemeForSlot(i))
                }
            }
        }
    }

    public func captureCurrentDesktopLivePreview() {
        let activeIndex = currentSpaceIndex
        activeCaptureTask?.cancel()
        activeCaptureTask = Task { @MainActor [weak self] in
            guard let self = self, !Task.isCancelled else { return }

            // Check screen capture permission WITHOUT triggering unsolicited system prompts
            guard CGPreflightScreenCaptureAccess() else {
                // Fallback gracefully to active wallpaper or curated Sequoia Dark wallpaper
                if let wp = WallpaperManager.shared.activeWallpaperImage {
                    self.desktopLivePreviews[activeIndex] = wp
                } else {
                    self.desktopLivePreviews[activeIndex] = WallpaperManager.shared.generateCuratedWallpaper(named: "Sequoia Dark")
                }
                return
            }

            // 1. Resolve active display corresponding to cursor or main screen
            let mouseLoc = NSEvent.mouseLocation
            let activeScreen = NSScreen.screens.first(where: { NSMouseInRect(mouseLoc, $0.frame, false) })
                ?? (NSScreen.main ?? (NSScreen.screens.first ?? NSScreen()))
            let activeDisplayID = (activeScreen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID)
                ?? CGMainDisplayID()

            do {
                let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                let targetDisplay = content.displays.first(where: { $0.displayID == activeDisplayID }) ?? content.displays.first
                if let display = targetDisplay {
                    let filter = SCContentFilter(display: display, excludingWindows: [])
                    let config = SCStreamConfiguration()
                    config.width = 320
                    config.height = 200
                    config.showsCursor = false
                    let cgImg = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
                    let nsImg = NSImage(cgImage: cgImg, size: NSSize(width: 160, height: 100))
                    self.desktopLivePreviews[activeIndex] = nsImg
                    return
                }
            } catch {
                // Fallback to Quartz or active wallpaper if ScreenCaptureKit throws
            }

            // Fallback 1: CGWindowListCreateImage on active screen bounds
            let screenBounds = activeScreen.frame
            if let cgFallback = safeCGWindowListCreateImage(screenBounds, .optionOnScreenOnly, kCGNullWindowID, [.bestResolution, .nominalResolution]) {
                let nsImg = NSImage(cgImage: cgFallback, size: NSSize(width: 160, height: 100))
                self.desktopLivePreviews[activeIndex] = nsImg
                return
            }

            // Fallback 2: Active wallpaper or curated Sequoia Dark wallpaper
            if let wp = WallpaperManager.shared.activeWallpaperImage {
                self.desktopLivePreviews[activeIndex] = wp
            } else {
                self.desktopLivePreviews[activeIndex] = WallpaperManager.shared.generateCuratedWallpaper(named: "Sequoia Dark")
            }
        }
    }

    // MARK: - Hardware-Level WindowServer & Mission Control Space Creation
    public func executeHardwareSpaceCreation() -> UInt64? {
        typealias SLSMainConnectionIDFunc = @convention(c) () -> Int32
        typealias SLSSpaceCreateFunc = @convention(c) (Int32, UInt32, CFDictionary?) -> UInt64
        typealias SLSManagedDisplaySetCurrentSpaceFunc = @convention(c) (Int32, CFString, UInt64) -> Int32
        typealias SLSCopyManagedDisplaysFunc = @convention(c) (Int32) -> CFArray?

        guard let handle = dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/SkyLight", RTLD_LAZY),
              let cidSym = dlsym(handle, "SLSMainConnectionID"),
              let createSym = dlsym(handle, "SLSSpaceCreate") else {
            return nil
        }

        let getCID = unsafeBitCast(cidSym, to: SLSMainConnectionIDFunc.self)
        let createSpace = unsafeBitCast(createSym, to: SLSSpaceCreateFunc.self)
        let cid = getCID()

        // 1. Hardware WindowServer allocation (instantaneous kernel/server space ID)
        let newSpaceID = createSpace(cid, 1, nil)
        guard newSpaceID > 0 else { return nil }

        // 2. Attach and activate on target managed display
        if let setSpaceSym = dlsym(handle, "SLSManagedDisplaySetCurrentSpace"),
           let displaysSym = dlsym(handle, "SLSCopyManagedDisplays") {
            let setSpace = unsafeBitCast(setSpaceSym, to: SLSManagedDisplaySetCurrentSpaceFunc.self)
            let copyDisplays = unsafeBitCast(displaysSym, to: SLSCopyManagedDisplaysFunc.self)
            if let displays = copyDisplays(cid) as? [CFString], let firstDisplay = displays.first {
                _ = setSpace(cid, firstDisplay, newSpaceID)
            }
        }

        return newSpaceID
    }

    // MARK: - Create Desktop Feature

    public func createDesktop() {
        guard spaces.count < 16 else {
            NSSound.beep()
            return
        }
        HapticFeedback.heavy()

        // 1. Instant hardware-level WindowServer Space creation
        let newSpaceID = executeHardwareSpaceCreation()

        // 2. Compute next index
        let nextIndex = (spaces.map { $0.index }.max() ?? spaces.count) + 1
        let newSpace = MacDesktopSpace(
            id: UUID().uuidString,
            index: nextIndex,
            name: "Desktop \(nextIndex)",
            isCurrent: true,
            id64: newSpaceID
        )

        // 3. Update spaces list with animated visual insertion
        withAnimation(.spring(response: 0.22, dampingFraction: 0.80)) {
            for i in 0..<self.spaces.count {
                self.spaces[i].isCurrent = false
            }
            self.spaces.append(newSpace)
            self.currentSpaceIndex = nextIndex
        }

        // 4. Switch immediately to the new desktop
        switchToDesktop(index: nextIndex)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
            self?.refreshSpaces()
            self?.captureCurrentDesktopLivePreview()
        }
    }
}


// MARK: - Mini Desktop Icons Menu Bar Widget (16:10 Screen Thumbnails)
public struct MiniMenuBarDesktopSpacesView: View {
    @ObservedObject var manager: MacDesktopsManager = .shared
    @ObservedObject var wallpaperManager: WallpaperManager = .shared
    @AppStorage(PrefKey.appLanguage) var appLanguage: String = "English (US)"
    @AppStorage(PrefKey.menuBarTextColor) var textColorName: String = "Pure White ⚪️"
    @AppStorage(PrefKey.menuBarColorsEnabled) var menuBarColorsEnabled: Bool = false
    @AppStorage(PrefKey.showMiniDesktopsInMenuBar) var showMiniDesktopsInMenuBar: Bool = true
    @AppStorage(PrefKey.statusIconStyle) var statusIconStyle: String = "Genie Person 🧞‍♂️"
    @AppStorage(PrefKey.statusIconGlyph) var statusIconGlyph: String = "Genie Person 🧞‍♂️"
    @AppStorage(PrefKey.desktopPreviewStyle) var desktopPreviewStyle: String = "Live Thumbnails (Windows)"
    @State private var hoveredSpaceIndex: Int? = nil
    @State private var isGenieHovered: Bool = false
    @State private var draggingSlotIndex: Int? = nil
    @State private var dragOffset: CGFloat = 0.0
    @State private var dragYOffset: CGFloat = 0.0
    @State private var isDragOffThreshold: Bool = false
    @State private var isPlusHovered: Bool = false

    private func desktopNumberColor(isCurrent: Bool, hasSpace: Bool) -> Color {
        if isCurrent { return activeGlowColor }
        return hasSpace ? Color.white.opacity(0.90) : Color.white.opacity(0.50)
    }

    private func desktopBorderColor(isCurrent: Bool, isHovered: Bool, hasSpace: Bool) -> Color {
        if isCurrent { return activeGlowColor }
        if isHovered { return Color.white.opacity(0.40) }
        return hasSpace ? Color.white.opacity(0.20) : Color.white.opacity(0.10)
    }

    private var activeGlyph: String {
        let style = statusIconGlyph.isEmpty ? statusIconStyle : statusIconGlyph
        return style.isEmpty ? "Genie Person 🧞‍♂️" : style
    }

    private var glyphImage: NSImage {
        StatusIconRenderer.generateGlyphImage(glyph: activeGlyph, size: 17, phase: 0)
    }

    private var activeGlowColor: Color {
        guard menuBarColorsEnabled else {
            return Color.white.opacity(0.85)
        }
        if textColorName.contains("Pink") || textColorName.contains("Cyan") || textColorName.contains("Blue") {
            return Color.white.opacity(0.85)
        }
        return Color.white.opacity(0.85)
    }

    @ViewBuilder
    private var addDesktopButton: some View {
        Button(action: {
            HapticFeedback.heavy()
            manager.createDesktop()
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 4.5, style: .continuous)
                    .strokeBorder(isPlusHovered ? Color.white.opacity(0.85) : Color.white.opacity(0.35), style: StrokeStyle(lineWidth: 0.9, dash: [3, 2]))
                    .frame(width: 26, height: 20)
                    .background(
                        RoundedRectangle(cornerRadius: 4.5, style: .continuous)
                            .fill(isPlusHovered ? Color.white.opacity(0.14) : Color.white.opacity(0.04))
                    )

                Image(systemName: "plus")
                    .font(.system(size: 9.0, weight: .bold))
                    .foregroundColor(isPlusHovered ? .white : Color.white.opacity(0.75))
            }
            .frame(width: 28, height: 22)
            .scaleEffect(isPlusHovered ? 1.08 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { isPlusHovered = $0 }
        .help("Add New Desktop Space (+)")
    }



    private func computeDragXDisplacement(slotIndex: Int, displaySpaces: [Int]) -> CGFloat {
        guard let draggingIdx = draggingSlotIndex,
              let fromPos = displaySpaces.firstIndex(of: draggingIdx),
              let myPos = displaySpaces.firstIndex(of: slotIndex) else { return 0 }
        let slotWidth: CGFloat = 44.0
        let offsetSlots = Int(round(dragOffset / slotWidth))
        let targetPos = max(0, min(displaySpaces.count - 1, fromPos + offsetSlots))
        if targetPos > fromPos && myPos > fromPos && myPos <= targetPos {
            return -slotWidth
        } else if targetPos < fromPos && myPos < fromPos && myPos >= targetPos {
            return slotWidth
        }
        return 0
    }

    public init() {}

    public var body: some View {
        if showMiniDesktopsInMenuBar {
            HStack(spacing: 6) {
                // All Desktop Spaces (Stable, persistent order with active neon highlight on current space)
                let cur = manager.currentSpaceIndex
                let displaySpaces = manager.displayOrderIndices()
                ForEach(displaySpaces, id: \.self) { slotIndex in
                    miniSpaceSlotView(slotIndex: slotIndex, cur: cur, displaySpaces: displaySpaces)
                }

                addDesktopButton
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3.5)
            .background(
                RoundedRectangle(cornerRadius: 7.0, style: .continuous)
                    .fill(Color.black.opacity(0.22))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 7.0, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.14), lineWidth: 0.6)
            )
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 8)
                    .onEnded { value in
                        let cur = manager.currentSpaceIndex
                        let displaySpaces = manager.displayOrderIndices()
                        if value.translation.width < -12 {
                            let next = min(displaySpaces.count, cur + 1)
                            if next != cur {
                                HapticFeedback.selection()
                                manager.switchToDesktop(index: next)
                            }
                        } else if value.translation.width > 12 {
                            let prev = max(1, cur - 1)
                            if prev != cur {
                                HapticFeedback.selection()
                                manager.switchToDesktop(index: prev)
                            }
                        }
                    }
            )
            .onAppear {
                manager.refreshSpaces()
                manager.captureCurrentDesktopLivePreview()
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusDesktopSpaceDidChange"))) { _ in
                manager.refreshSpaces()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
                    manager.captureCurrentDesktopLivePreview()
                }
            }
        }
    }

    @ViewBuilder
    private func miniDesktopThumbnail(slotIndex: Int, isCurrent: Bool, space: MacDesktopSpace?) -> some View {
        if desktopPreviewStyle == "Compact Badges" {
            let c1 = isCurrent ? Color(red: 0.15, green: 0.25, blue: 0.50) : Color.black.opacity(0.4)
            let c2 = isCurrent ? Color(red: 0.25, green: 0.10, blue: 0.40) : Color.gray.opacity(0.2)
            LinearGradient(
                colors: [c1, c2],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(width: 38, height: 24)
        } else if desktopPreviewStyle == "Wallpaper Previews" {
            if let wp = wallpaperManager.activeWallpaperImage {
                Image(nsImage: wp)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 38, height: 24)
                    .clipped()
                    .opacity(isCurrent ? 1.0 : (space != nil ? 0.65 : 0.35))
            } else {
                Color.black.opacity(0.5)
                    .frame(width: 38, height: 24)
            }
        } else {
            if let live = manager.desktopLivePreviews[slotIndex] {
                Image(nsImage: live)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 38, height: 24)
                    .clipped()
            } else if let wp = wallpaperManager.activeWallpaperImage {
                Image(nsImage: wp)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 38, height: 24)
                    .clipped()
                    .opacity(isCurrent ? 1.0 : (space != nil ? 0.65 : 0.35))
            } else {
                let gradColors: [Color] = isCurrent
                    ? [Color(red: 0.1, green: 0.15, blue: 0.3), Color(red: 0.2, green: 0.05, blue: 0.25)]
                    : [Color.black.opacity(space != nil ? 0.6 : 0.3), Color.gray.opacity(space != nil ? 0.3 : 0.15)]
                LinearGradient(
                    colors: gradColors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: 38, height: 24)
            }
        }
    }

    @ViewBuilder
    private func miniSpaceSlotView(
        slotIndex: Int,
        cur: Int,
        displaySpaces: [Int]
    ) -> some View {
        let isCurrent = (slotIndex == cur)
        let isHovered = (hoveredSpaceIndex == slotIndex)
        let space = manager.spaces.first(where: { $0.index == slotIndex })
        let isDraggingThis = (draggingSlotIndex == slotIndex)
        let dragXDisplacement = computeDragXDisplacement(slotIndex: slotIndex, displaySpaces: displaySpaces)
        let totalX = isDraggingThis ? dragOffset : dragXDisplacement

        ZStack(alignment: .topTrailing) {
            Button(action: {
                if draggingSlotIndex == nil {
                    HapticFeedback.selection()
                    manager.switchToDesktop(index: slotIndex)
                }
            }) {
                ZStack(alignment: .bottomTrailing) {
                    // 16:10 Proportional Mini Desktop Screen Display
                    ZStack(alignment: .top) {
                        miniDesktopThumbnail(slotIndex: slotIndex, isCurrent: isCurrent, space: space)

                        // Miniature Menu Bar Line
                        HStack {
                            Capsule().fill(Color.white.opacity(space != nil ? 0.75 : 0.40)).frame(width: 6, height: 1.0)
                            Spacer()
                            Capsule().fill(Color.white.opacity(space != nil ? 0.75 : 0.40)).frame(width: 7, height: 1.0)
                        }
                        .padding(.horizontal, 2.0)
                        .padding(.top, 1.5)
                    }
                    .frame(width: 38, height: 24)
                    .clipShape(RoundedRectangle(cornerRadius: 5.0, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 5.0, style: .continuous)
                            .strokeBorder(
                                desktopBorderColor(isCurrent: isCurrent, isHovered: isHovered, hasSpace: space != nil),
                                lineWidth: isCurrent ? 1.6 : 0.8
                            )
                    )
                    .shadow(color: isCurrent ? activeGlowColor.opacity(0.60) : Color.black.opacity(0.25), radius: isCurrent ? 3.5 : 1.5, y: 1.0)

                    // Desktop Number Overlay Pill
                    Text("\(slotIndex)")
                        .font(.system(size: 8.5, weight: .heavy, design: .rounded))
                        .foregroundColor(desktopNumberColor(isCurrent: isCurrent, hasSpace: space != nil))
                        .padding(.horizontal, 3.5)
                        .padding(.vertical, 1.0)
                        .background(Capsule().fill(Color.black.opacity(0.75)))
                        .padding(2)
                }
                .frame(width: 38, height: 24)
                .scaleEffect(isDraggingThis ? 1.18 : (isHovered ? 1.14 : 1.0))
                .offset(x: totalX, y: isDraggingThis ? dragYOffset : (isHovered ? 2.5 : 0.0))
                .opacity(isDraggingThis && isDragOffThreshold ? 0.45 : 1.0)
                .zIndex(isDraggingThis ? 50 : 1)
            }
            .buttonStyle(.plain)
            .simultaneousGesture(
                DragGesture(minimumDistance: 3)
                    .onChanged { val in
                        if draggingSlotIndex == nil {
                            draggingSlotIndex = slotIndex
                            HapticFeedback.selection()
                        }
                        withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
                            dragOffset = val.translation.width
                            dragYOffset = val.translation.height
                            isDragOffThreshold = abs(val.translation.height) > 28.0
                        }
                    }
                    .onEnded { val in
                        let isOff = abs(val.translation.height) > 28.0
                        if isOff && manager.spaces.count > 1 {
                            // Dragged off the menu bar downwards -> Close / Delete Space!
                            HapticFeedback.heavy()
                            NSSound(named: "Basso")?.play()
                            manager.closeDesktop(index: slotIndex)
                        } else if let draggingIdx = draggingSlotIndex,
                                  let fromPos = displaySpaces.firstIndex(of: draggingIdx) {
                            let slotWidth: CGFloat = 44.0
                            let offsetSlots = Int(round(val.translation.width / slotWidth))
                            let toPos = max(0, min(displaySpaces.count - 1, fromPos + offsetSlots))
                            if fromPos != toPos {
                                manager.reorderDesktops(fromIndex: fromPos, toIndex: toPos)
                            }
                        }
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.78)) {
                            draggingSlotIndex = nil
                            dragOffset = 0
                            dragYOffset = 0
                            isDragOffThreshold = false
                        }
                    }
            )
            .onHover { h in
                withAnimation(.spring(response: 0.20, dampingFraction: 0.72)) {
                    hoveredSpaceIndex = h ? slotIndex : nil
                }
            }
            .help("Desktop \(slotIndex) — Click to switch, hold & drag to rearrange or drag off to remove")
            .contextMenu {
                desktopCardContextMenu(slotIndex: slotIndex, space: space)
            }
            .popover(
                isPresented: Binding(
                    get: { hoveredSpaceIndex == slotIndex && draggingSlotIndex == nil },
                    set: { if !$0 && hoveredSpaceIndex == slotIndex { hoveredSpaceIndex = nil } }
                ),
                arrowEdge: .bottom
            ) {
                desktopHoverPreview(slotIndex: slotIndex, isCurrent: isCurrent)
            }

            // Hover [-] Close Button inside Pill Thumbnail
            if isHovered && manager.spaces.count > 1 {
                Button(action: {
                    HapticFeedback.heavy()
                    manager.closeDesktop(index: slotIndex)
                }) {
                    Image(systemName: "minus.circle.fill")
                        .font(.system(size: 9.0, weight: .bold))
                        .foregroundColor(Color.red.opacity(0.95))
                        .background(Circle().fill(Color.black.opacity(0.75)))
                }
                .buttonStyle(.plain)
                .offset(x: 2, y: -2)
                .transition(.scale.combined(with: .opacity))
                .help("Close Desktop \(slotIndex)")
            }
        }
    }

    @ViewBuilder
    private func desktopHoverPreview(slotIndex: Int, isCurrent: Bool) -> some View {
        let previewImg = manager.desktopLivePreviews[slotIndex]
            ?? wallpaperManager.activeWallpaperImage
            ?? WallpaperManager.shared.generateCuratedWallpaper(named: "Sequoia Dark")

        VStack(alignment: .leading, spacing: 6) {
            // Header Bar
            HStack(spacing: 5) {
                Circle()
                    .fill(isCurrent ? Color.green : Color.white.opacity(0.65))
                    .frame(width: 6, height: 6)
                Text(LocalizedStrings.translateText("Desktop \(slotIndex)", lang: appLanguage))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                if isCurrent {
                    Text(LocalizedStrings.translateText("Active Space", lang: appLanguage))
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(Color.white.opacity(0.90))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1.5)
                        .background(Capsule().fill(Color.white.opacity(0.18)))
                }
            }
            .padding(.horizontal, 2)

            // Dynamic Live Screen Preview Thumbnail (Unlocked Aspect Ratio)
            let ratio = MacDesktopsManager.resolvedAspectRatio()
            let thumbW: CGFloat = 220
            let thumbH: CGFloat = max(80, thumbW / ratio)
            Image(nsImage: previewImg)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: thumbW, height: thumbH)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(isCurrent ? Color.white.opacity(0.85) : Color.white.opacity(0.25), lineWidth: isCurrent ? 1.5 : 0.8)
                )
                .shadow(color: Color.black.opacity(0.40), radius: 8, y: 3)

            // Quick Actions: Go to Desktop & Duplicate View
            HStack(spacing: 6) {
                Button(action: {
                    hoveredSpaceIndex = nil
                    HapticFeedback.selection()
                    manager.switchToDesktop(index: slotIndex)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 9.5))
                        Text(isCurrent ? LocalizedStrings.translateText("Current", lang: appLanguage) : LocalizedStrings.translateText("Switch", lang: appLanguage))
                            .font(.system(size: 9.5, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(Color.white.opacity(0.18))
                    )
                }
                .buttonStyle(.plain)

                Button(action: {
                    hoveredSpaceIndex = nil
                    HapticFeedback.heavy()
                    manager.cloneDesktop(from: slotIndex)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.rectangle.on.rectangle")
                            .font(.system(size: 9.5))
                        Text(LocalizedStrings.translateText("Duplicate View", lang: appLanguage))
                            .font(.system(size: 9.5, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(Color.white.opacity(0.18))
                    )
                }
                .buttonStyle(.plain)
                .help(LocalizedStrings.translateText("Duplicate this desktop view with all its open windows", lang: appLanguage))

                Button(action: {
                    hoveredSpaceIndex = nil
                    HapticFeedback.heavy()
                    DesktopScreenShareManager.shared.showDropDown(targetSpaceIndex: slotIndex)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "tv.fill")
                            .font(.system(size: 9.5))
                        Text(LocalizedStrings.translateText("Watch Stream", lang: appLanguage))
                            .font(.system(size: 9.5, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(Color.blue.opacity(0.45))
                    )
                }
                .buttonStyle(.plain)
                .help(LocalizedStrings.translateText("Drop down live screenshare of Desktop \(slotIndex) to watch videos overtop of work", lang: appLanguage))
            }
            .padding(.top, 2)
        }
        .padding(8)
        .frame(width: 236)
        .background(
            VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow, state: .active)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.8)
                )
        )
    }

    @ViewBuilder
    private var genieContextMenu: some View {
        Button(LocalizedStrings.translateText("💬 Open Genie AI Chat", lang: appLanguage)) {
            MenuBarActionDispatcher.shared.handleLeoClick()
        }
        Button(LocalizedStrings.translateText("⚙️ Genie Settings...", lang: appLanguage)) {
            MenuBarActionDispatcher.shared.openGenieSettings()
        }
        Divider()
        Button(LocalizedStrings.translateText("🌓 Auto Sort Apps to Halves (50/50)", lang: appLanguage)) {
            SmartGridManager.shared.bringAllToScreen(choice: .halfScreens)
        }
        Button(LocalizedStrings.translateText("🔲 Auto Sort Apps to Full Screen", lang: appLanguage)) {
            SmartGridManager.shared.bringAllToScreen(choice: .single)
        }
        Button(LocalizedStrings.translateText("🖥️ Sort Apps Across Desktops (1–4)", lang: appLanguage)) {
            SmartGridManager.shared.sortApplicationsToDesktops()
        }
        Divider()
        Button(LocalizedStrings.translateText("👯‍♂️ Clone Active Desktop (Duplicate with Windows)", lang: appLanguage)) {
            manager.cloneDesktop(from: manager.currentSpaceIndex)
        }
        Button(LocalizedStrings.translateText("🖥️ Show Desktop (Hide All Windows)", lang: appLanguage)) {
            manager.showDesktopWallpaper()
        }
    }

    @ViewBuilder
    private func desktopCardContextMenu(slotIndex: Int, space: MacDesktopSpace?) -> some View {
        Button(LocalizedStrings.translateText("Go to Desktop \(slotIndex) (Preserve State)", lang: appLanguage)) {
            manager.switchToDesktop(index: slotIndex)
        }
        Button(LocalizedStrings.translateText("📺 Drop Down Screen Share (Watch Over Work)", lang: appLanguage)) {
            DesktopScreenShareManager.shared.showDropDown(targetSpaceIndex: slotIndex)
        }
        Button(LocalizedStrings.translateText("🪟 Floating Picture-in-Picture (PiP)", lang: appLanguage)) {
            DesktopScreenShareManager.shared.showFloatingPiP(targetSpaceIndex: slotIndex)
        }
        Button(LocalizedStrings.translateText("🖥️ Sort All Apps Across Desktops (1–4)", lang: appLanguage)) {
            SmartGridManager.shared.sortApplicationsToDesktops()
        }
        Button(LocalizedStrings.translateText("✨ Auto Snap Windows to Grid", lang: appLanguage)) {
            SmartGridManager.shared.bringAllToScreen(choice: .auto)
        }
        Button(LocalizedStrings.translateText("🌓 Tile Windows to Halves (50/50)", lang: appLanguage)) {
            SmartGridManager.shared.bringAllToScreen(choice: .halfScreens)
        }
        Button(LocalizedStrings.translateText("🔲 Tile Windows to Full Screen", lang: appLanguage)) {
            SmartGridManager.shared.bringAllToScreen(choice: .single)
        }
        Button(LocalizedStrings.translateText("⊞ Snap Windows to 2x2 Grid", lang: appLanguage)) {
            SmartGridManager.shared.bringAllToScreen(choice: .quadrant2x2)
        }
        Button(LocalizedStrings.translateText("▦ Snap Windows to 4x3 Grid", lang: appLanguage)) {
            SmartGridManager.shared.bringAllToScreen(choice: .matrix4x3)
        }
        Divider()
        Button(LocalizedStrings.translateText("👯‍♂️ Clone Desktop \(slotIndex) (Duplicate with Windows)", lang: appLanguage)) {
            manager.cloneDesktop(from: slotIndex)
        }
        Button(LocalizedStrings.translateText("🖥️ Show Desktop (Hide Windows)", lang: appLanguage)) {
            manager.showDesktopWallpaper()
        }
        Button(LocalizedStrings.translateText("⤢ Maximize All Windows on Desktop", lang: appLanguage)) {
            manager.maximizeAllWindowsOnActiveScreen()
        }
        Button(LocalizedStrings.translateText("✕ Close All Windows on Desktop", lang: appLanguage)) {
            manager.closeAllWindowsOnActiveDesktop()
        }
        Divider()
        Menu(LocalizedStrings.translateText("🖼️ Desktop Preview Style", lang: appLanguage)) {
            Button(action: {
                desktopPreviewStyle = "Live Thumbnails (Windows)"
                UserDefaults.standard.set("Live Thumbnails (Windows)", forKey: PrefKey.desktopPreviewStyle)
            }) {
                HStack {
                    Text(LocalizedStrings.translateText("Live Thumbnails (Windows)", lang: appLanguage))
                    if desktopPreviewStyle == "Live Thumbnails (Windows)" { Text("✓") }
                }
            }
            Button(action: {
                desktopPreviewStyle = "Wallpaper Previews"
                UserDefaults.standard.set("Wallpaper Previews", forKey: PrefKey.desktopPreviewStyle)
            }) {
                HStack {
                    Text(LocalizedStrings.translateText("Wallpaper Previews", lang: appLanguage))
                    if desktopPreviewStyle == "Wallpaper Previews" { Text("✓") }
                }
            }
            Button(action: {
                desktopPreviewStyle = "Compact Badges"
                UserDefaults.standard.set("Compact Badges", forKey: PrefKey.desktopPreviewStyle)
            }) {
                HStack {
                    Text(LocalizedStrings.translateText("Compact Badges", lang: appLanguage))
                    if desktopPreviewStyle == "Compact Badges" { Text("✓") }
                }
            }
        }
        if slotIndex > 1 && space != nil {
            Divider()
            Button(LocalizedStrings.translateText("🗑️ Delete Desktop \(slotIndex) (-)", lang: appLanguage)) {
                manager.closeDesktop(index: slotIndex)
            }
        }
    }
}

