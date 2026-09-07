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
    @Published public var customSpacesOrder: [Int] = (UserDefaults.standard.array(forKey: "nexus.customSpacesOrder") as? [Int]) ?? []

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

    public func reorderDesktops(fromIndex: Int, toIndex: Int) {
        var currentOrder = displayOrderIndices()
        guard fromIndex >= 0 && fromIndex < currentOrder.count,
              toIndex >= 0 && toIndex < currentOrder.count,
              fromIndex != toIndex else { return }

        let item = currentOrder.remove(at: fromIndex)
        currentOrder.insert(item, at: toIndex)
        self.customSpacesOrder = currentOrder
        UserDefaults.standard.set(currentOrder, forKey: "nexus.customSpacesOrder")
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
        while spaces.count < index && spaces.count < 9 {
            createDesktop()
        }
        HapticFeedback.heavy()
        let previousIndex = currentSpaceIndex
        currentSpaceIndex = index
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
                    // System Events keystroke simulation (built-in macOS space glide)
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
                        // Direct HID CGEvent post fallback
                        for _ in 0..<count {
                            Self.postKeyComboDirect(keyCode: arrowCode, flags: .maskControl)
                            usleep(60_000)
                        }
                    }
                }
            }
        }

        // 4. Transition settle: update spaces and notify without stealing focus
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.isSwitchingSpace = false
            self?.refreshSpaces()
            NotificationCenter.default.post(name: NSNotification.Name("NexusDidSwitchSpace"), object: index)
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

    public func seedInitialThumbnails() {
        let fallback = WallpaperManager.shared.activeWallpaperImage ?? WallpaperManager.shared.generateCuratedWallpaper(named: "Sequoia Dark")
        for i in 1...max(2, spaces.count) {
            if desktopLivePreviews[i] == nil {
                desktopLivePreviews[i] = fallback
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
            if let cgFallback = CGWindowListCreateImage(screenBounds, .optionOnScreenOnly, kCGNullWindowID, [.bestResolution, .nominalResolution]) {
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

// MARK: - Desktop Spaces Navigator Bar View (Sleek, Proportional & Multi-Monitor Enabled)

public struct DesktopSpacesNavigatorBar: View {
    @ObservedObject var manager: MacDesktopsManager = .shared
    @ObservedObject var wallpaperManager: WallpaperManager = .shared
    @ObservedObject var gridManager: SmartGridManager = .shared
    @AppStorage("nexus.desktopSpacesEnabled") private var desktopSpacesEnabled: Bool = true


    public init() {}

    public var body: some View {
        HStack(spacing: 6) {
            // ── 1. Desktop Spaces Strip (Sleek 16:10 Screen Thumbnails) ──
            HStack(spacing: 4) {

                // Compact Screen Preview Cards
                HStack(spacing: 4) {
                    let cur = manager.currentSpaceIndex
                    let displaySpaces = manager.displayOrderIndices()
                    ForEach(displaySpaces, id: \.self) { slotIndex in
                        let isCurrent = (slotIndex == cur)
                        Button(action: {
                            manager.switchToDesktop(index: slotIndex)
                        }) {
                            ZStack(alignment: .bottomTrailing) {
                                // 16:10 Proportional Screen Display Thumbnail
                                ZStack(alignment: .top) {
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
                                            .opacity(isCurrent ? 1.0 : 0.65)
                                    } else {
                                        LinearGradient(
                                            colors: isCurrent ? [Color.cyan.opacity(0.7), Color.blue.opacity(0.9)] : [Color.gray.opacity(0.3), Color.black.opacity(0.5)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                        .frame(width: 38, height: 24)
                                    }

                                    // Top Menu Bar Hairline
                                    HStack {
                                        Capsule().fill(Color.white.opacity(0.7)).frame(width: 5, height: 1)
                                        Spacer()
                                        Capsule().fill(Color.white.opacity(0.7)).frame(width: 7, height: 1)
                                    }
                                    .padding(.horizontal, 2)
                                    .padding(.top, 1.5)
                                }
                                .frame(width: 38, height: 24)
                                .cornerRadius(4)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .strokeBorder(isCurrent ? Color.cyan : Color.white.opacity(0.20), lineWidth: isCurrent ? 1.5 : 0.7)
                                )
                                .shadow(color: isCurrent ? Color.cyan.opacity(0.45) : Color.black.opacity(0.15), radius: isCurrent ? 3 : 1)

                                // Desktop Number Badge Overlaid in Bottom-Right
                                HStack(spacing: 1.5) {
                                    if isCurrent {
                                        Circle()
                                            .fill(Color.cyan)
                                            .frame(width: 3.5, height: 3.5)
                                    }
                                    Text("\(slotIndex)")
                                        .font(.system(size: 7, weight: .heavy, design: .rounded))
                                        .foregroundColor(isCurrent ? .cyan : .white.opacity(0.85))
                                }
                                .padding(.horizontal, 2.5)
                                .padding(.vertical, 0.8)
                                .background(
                                    Capsule()
                                        .fill(Color.black.opacity(0.65))
                                )
                                .padding(1.5)
                            }
                            .frame(width: 38, height: 24)
                        }
                        .buttonStyle(.plain)
                        .help("Switch to Desktop \(slotIndex)")
                    }
                }

                // 3x3 Continuous Canvas & Above-Level Cursor Button
                Button(action: {
                    SpatialPlaneManager.shared.toggleZoomOutPlane()
                }) {
                    HStack(spacing: 2.5) {
                        Image(systemName: "square.grid.3x3.fill")
                            .font(.system(size: 8, weight: .bold))
                        Text("Canvas")
                            .font(.system(size: 7.5, weight: .heavy, design: .rounded))
                    }
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 4.5)
                    .padding(.vertical, 3.5)
                    .background(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(Color.cyan.opacity(0.18))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .strokeBorder(Color.cyan.opacity(0.35), lineWidth: 0.6)
                    )
                }
                .buttonStyle(.plain)
                .help("Continuous 9-Desktop Canvas & Above-Level Cursor (⌘⌥9)")
            }
            .padding(.horizontal, 3)
            .padding(.vertical, 2)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.30))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.8)
            )

            // ── 2. Multi-Monitor / Other Screens Selector ──
            if gridManager.connectedScreens.count > 1 {
                HStack(spacing: 2) {
                    ForEach(gridManager.connectedScreens) { mon in
                        let isSelected = gridManager.selectedScreenIndex == mon.id
                        Button(action: {
                            HapticFeedback.selection()
                            gridManager.selectedScreenIndex = mon.id
                            gridManager.lastStatusMessage = "Targeting \(mon.name)"
                        }) {
                            HStack(spacing: 2) {
                                Image(systemName: "display")
                                    .font(.system(size: 7.5, weight: isSelected ? .bold : .regular))
                                Text(mon.shortName)
                                    .font(.system(size: 8, weight: isSelected ? .bold : .semibold, design: .rounded))
                            }
                            .foregroundColor(isSelected ? .white : .secondary)
                            .padding(.horizontal, 4.5)
                            .frame(height: 22)
                            .background(
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(isSelected ? Color.teal : Color.clear)
                            )
                        }
                        .buttonStyle(.plain)
                        .help("\(mon.name) (\(mon.resolution)) — Click to target this monitor")
                    }
                }
                .padding(2)
                .background(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(Color.primary.opacity(0.04))
                )
            }

            // ── 3. 3 Screen Choices Pill ([ 1 Screen ], [ 2x2 ], [ 4x3 ]) ──
            HStack(spacing: 2) {
                ForEach(GridScreenChoice.allCases) { choice in
                    let isSelected = gridManager.activeChoice == choice
                    Button(action: {
                        HapticFeedback.selection()
                        gridManager.activeChoice = choice
                        gridManager.bringAllToScreen(choice: choice)
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: choice.icon)
                                .font(.system(size: 7.5, weight: isSelected ? .bold : .regular))
                            Text(choice.rawValue)
                                .font(.system(size: 8.5, weight: isSelected ? .bold : .semibold, design: .rounded))
                        }
                        .foregroundColor(isSelected ? .white : .secondary)
                        .padding(.horizontal, 6)
                        .frame(height: 22)
                        .background(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .fill(isSelected ? Color.accentColor : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                    .help("\(choice.description) — Click to tile all windows")
                }
            }
            .padding(2)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.primary.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.8)
            )

            // ── 3. Bring All to Screen Shortcut Button ──
            Button(action: {
                gridManager.bringAllToScreen()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "macwindow.on.rectangle")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.cyan)

                    Text("Bring All")
                        .font(.system(size: 8.5, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Text("⌘⌥Space")
                        .font(.system(size: 7, weight: .bold, design: .monospaced))
                        .foregroundColor(.cyan)
                        .padding(.horizontal, 3.5)
                        .padding(.vertical, 1.5)
                        .background(
                            Capsule()
                                .fill(Color.cyan.opacity(0.16))
                        )
                }
                .padding(.horizontal, 7)
                .frame(height: 24)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.cyan.opacity(0.10))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(Color.cyan.opacity(0.35), lineWidth: 0.8)
                )
            }
            .buttonStyle(.plain)
            .help("Bring All to Screen: Auto-tile and raise all windows cleanly on screen (Shortcut: ⌘ + ⌥ + Space or ⌘ + ⌥ + B)")
        }
        .onAppear {
            manager.captureCurrentDesktopLivePreview()
        }
    }
}

// MARK: - Mini Desktop Icons Menu Bar Widget (16:10 Screen Thumbnails)
public struct MiniMenuBarDesktopSpacesView: View {
    @ObservedObject var manager: MacDesktopsManager = .shared
    @ObservedObject var wallpaperManager: WallpaperManager = .shared
    @AppStorage("nexus.appLanguage") var appLanguage: String = "English (US)"
    @AppStorage("nexus.menuBarTextColor") var textColorName: String = "Pure White ⚪️"
    @AppStorage("nexus.menuBarColorsEnabled") var menuBarColorsEnabled: Bool = false
    @AppStorage("nexus.showMiniDesktopsInMenuBar") var showMiniDesktopsInMenuBar: Bool = true
    @AppStorage("nexus.statusIconStyle") var statusIconStyle: String = "Genie Person 🧞‍♂️"
    @AppStorage("nexus.statusIconGlyph") var statusIconGlyph: String = "Genie Person 🧞‍♂️"
    @AppStorage("nexus.desktopPreviewStyle") var desktopPreviewStyle: String = "Live Thumbnails (Windows)"
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

    @ViewBuilder
    private var spatialPlaneZoomButton: some View {
        Button(action: {
            SpatialPlaneManager.shared.toggleZoomOutPlane()
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 4.5, style: .continuous)
                    .fill(Color.cyan.opacity(0.18))
                    .frame(width: 26, height: 20)

                Image(systemName: "square.grid.3x3.fill")
                    .font(.system(size: 9.0, weight: .bold))
                    .foregroundColor(.cyan)
            }
            .frame(width: 28, height: 22)
        }
        .buttonStyle(.plain)
        .help("9-Desktop Spatial Plane Zoom (⌘⌥9)")
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
                spatialPlaneZoomButton
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

            // 16:10 Live Screen Preview Thumbnail
            Image(nsImage: previewImg)
                .resizable()
                .aspectRatio(16/10, contentMode: .fill)
                .frame(width: 220, height: 138)
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
                UserDefaults.standard.set("Live Thumbnails (Windows)", forKey: "nexus.desktopPreviewStyle")
            }) {
                HStack {
                    Text(LocalizedStrings.translateText("Live Thumbnails (Windows)", lang: appLanguage))
                    if desktopPreviewStyle == "Live Thumbnails (Windows)" { Text("✓") }
                }
            }
            Button(action: {
                desktopPreviewStyle = "Wallpaper Previews"
                UserDefaults.standard.set("Wallpaper Previews", forKey: "nexus.desktopPreviewStyle")
            }) {
                HStack {
                    Text(LocalizedStrings.translateText("Wallpaper Previews", lang: appLanguage))
                    if desktopPreviewStyle == "Wallpaper Previews" { Text("✓") }
                }
            }
            Button(action: {
                desktopPreviewStyle = "Compact Badges"
                UserDefaults.standard.set("Compact Badges", forKey: "nexus.desktopPreviewStyle")
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

// MARK: - Genie Panoramic Spaces Bar HUD (The Revolutionary macOS Desktop Manager)
public struct GenieSpacesBarHUDView: View {
    @ObservedObject var manager: MacDesktopsManager = .shared
    @ObservedObject var wallpaperManager: WallpaperManager = .shared
    @AppStorage("nexus.appLanguage") var appLanguage: String = "English (US)"
    @State private var hoveredCardIndex: Int? = nil
    @State private var isPlusHovered: Bool = false
    @State private var draggingIndex: Int? = nil
    @State private var dragOffset: CGFloat = 0.0
    @State private var editingSpaceIndex: Int? = nil
    @State private var tempTitle: String = ""


    public init() {}

    public var body: some View {
        let displaySpaces = manager.displayOrderIndices()

        VStack(spacing: 8) {
            // Header Bar
            HStack(spacing: 10) {
                HStack(spacing: 5) {
                    Image(systemName: "macwindow.on.rectangle")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.cyan)

                    Text(LocalizedStrings.translateText("Genie Desktop Manager", lang: appLanguage))
                        .font(.system(size: 12.5, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Text("\(manager.spaces.count) Spaces")
                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        .foregroundColor(.cyan)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1.5)
                        .background(Capsule().fill(Color.cyan.opacity(0.18)))
                }

                Spacer()

                Button(action: {
                    SmartGridManager.shared.bringAllToScreen()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "rectangle.3.group")
                            .font(.system(size: 10, weight: .semibold))
                        Text("Tile All")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(RoundedRectangle(cornerRadius: 5).fill(Color.white.opacity(0.08)))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.top, 8)

            // Horizontal Panoramic Spaces Cards Strip
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(displaySpaces, id: \.self) { slotIndex in
                        let isCurrent = (slotIndex == manager.currentSpaceIndex)
                        let isHovered = (hoveredCardIndex == slotIndex)
                        let isDraggingThis = (draggingIndex == slotIndex)

                        let dragDisplacement = computeCardDragDisplacement(slotIndex: slotIndex, displaySpaces: displaySpaces)
                        let totalOffset = isDraggingThis ? dragOffset : dragDisplacement

                        hudSpaceCard(
                            slotIndex: slotIndex,
                            isCurrent: isCurrent,
                            isHovered: isHovered,
                            isDraggingThis: isDraggingThis,
                            totalOffset: totalOffset,
                            displaySpaces: displaySpaces
                        )
                    }

                    // [+] Add Desktop Card
                    Button(action: {
                        HapticFeedback.heavy()
                        manager.createDesktop()
                    }) {
                        VStack(spacing: 5) {
                            Text("New Space")
                                .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                                .foregroundColor(.cyan)

                            ZStack {
                                RoundedRectangle(cornerRadius: 7, style: .continuous)
                                    .fill(isPlusHovered ? Color.cyan.opacity(0.18) : Color.white.opacity(0.05))
                                    .frame(width: 80, height: 75)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                                            .strokeBorder(isPlusHovered ? Color.cyan : Color.white.opacity(0.20), style: StrokeStyle(lineWidth: 1.2, dash: [4, 3]))
                                    )

                                Image(systemName: "plus")
                                    .font(.system(size: 20, weight: .medium))
                                    .foregroundColor(isPlusHovered ? .cyan : .white.opacity(0.65))
                            }
                            .frame(width: 80, height: 75)
                        }
                        .scaleEffect(isPlusHovered ? 1.05 : 1.0)
                    }
                    .buttonStyle(.plain)
                    .onHover { isPlusHovered = $0 }
                    .help("Add New Desktop Space (+)")
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
            }
        }
        .padding(.vertical, 4)
        .background(
            VisualEffectBlur(material: .menu, blendingMode: .behindWindow, state: .active)
                .overlay(Color.black.opacity(0.25))
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.white.opacity(0.14), lineWidth: 0.8)
        )
        .shadow(color: Color.black.opacity(0.35), radius: 12, y: 4)
    }

    private func computeCardDragDisplacement(slotIndex: Int, displaySpaces: [Int]) -> CGFloat {
        guard let dragIdx = draggingIndex,
              let fromPos = displaySpaces.firstIndex(of: dragIdx),
              let myPos = displaySpaces.firstIndex(of: slotIndex) else { return 0 }
        let cardWidth: CGFloat = 132.0
        let offsetSlots = Int(round(dragOffset / cardWidth))
        let targetPos = max(0, min(displaySpaces.count - 1, fromPos + offsetSlots))
        if targetPos > fromPos && myPos > fromPos && myPos <= targetPos {
            return -cardWidth
        } else if targetPos < fromPos && myPos < fromPos && myPos >= targetPos {
            return cardWidth
        }
        return 0
    }

    @ViewBuilder
    private func hudSpaceCard(
        slotIndex: Int,
        isCurrent: Bool,
        isHovered: Bool,
        isDraggingThis: Bool,
        totalOffset: CGFloat,
        displaySpaces: [Int]
    ) -> some View {
        VStack(spacing: 5) {
            // Workspace Name Tag
            if editingSpaceIndex == slotIndex {
                TextField("Workspace", text: $tempTitle, onCommit: {
                    if let sp = manager.spaces.first(where: { $0.index == slotIndex }) {
                        manager.setWorkspaceName(for: sp, name: tempTitle)
                    }
                    editingSpaceIndex = nil
                })
                .textFieldStyle(.plain)
                .font(.system(size: 10.5, weight: .bold))
                .frame(width: 110)
                .padding(2)
                .background(RoundedRectangle(cornerRadius: 4).fill(Color.primary.opacity(0.12)))
            } else {
                Text(spaceTitle(for: slotIndex))
                    .font(.system(size: 10.5, weight: isCurrent ? .bold : .medium, design: .rounded))
                    .foregroundColor(isCurrent ? .cyan : .secondary)
                    .lineLimit(1)
                    .onTapGesture(count: 2) {
                        let targetSpace = manager.spaces.first(where: { $0.index == slotIndex })
                        if let sp = targetSpace {
                            tempTitle = manager.workspaceName(for: sp)
                            editingSpaceIndex = slotIndex
                        }
                    }
            }

            // 16:10 Thumbnail Card
            ZStack(alignment: .topTrailing) {
                Button(action: {
                    if draggingIndex == nil {
                        HapticFeedback.selection()
                        manager.switchToDesktop(index: slotIndex)
                    }
                }) {
                    ZStack(alignment: .bottomTrailing) {
                        hudThumbnailCard(slotIndex: slotIndex, isCurrent: isCurrent)

                        // Desktop Index Badge
                        HStack(spacing: 2) {
                            if isCurrent {
                                Circle().fill(Color.cyan).frame(width: 4, height: 4)
                            }
                            Text(String(slotIndex))
                                .font(.system(size: 8, weight: .heavy, design: .rounded))
                                .foregroundColor(isCurrent ? .cyan : .white)
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1.5)
                        .background(Capsule().fill(Color.black.opacity(0.75)))
                        .padding(3)
                    }
                    .frame(width: 120, height: 75)
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .strokeBorder(isCurrent ? Color.cyan : Color.white.opacity(isHovered ? 0.40 : 0.15), lineWidth: isCurrent ? 2.0 : 0.8)
                    )
                    .shadow(color: isCurrent ? Color.cyan.opacity(0.50) : Color.black.opacity(0.25), radius: isCurrent ? 5 : 2)
                }
                .buttonStyle(.plain)

                // Close Button on Card (shown on hover if >1 desktop)
                if isHovered && manager.spaces.count > 1 {
                    Button(action: {
                        HapticFeedback.heavy()
                        manager.closeDesktop(index: slotIndex)
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .background(Circle().fill(Color.red))
                    }
                    .buttonStyle(.plain)
                    .offset(x: 4, y: -4)
                    .transition(.scale.combined(with: .opacity))
                }
            }
        }
        .scaleEffect(isDraggingThis ? 1.12 : (isHovered ? 1.05 : 1.0))
        .offset(x: totalOffset)
        .zIndex(isDraggingThis ? 50 : 1)
        .simultaneousGesture(
            DragGesture(minimumDistance: 4)
                .onChanged { val in
                    if draggingIndex == nil {
                        draggingIndex = slotIndex
                        HapticFeedback.selection()
                    }
                    withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
                        dragOffset = val.translation.width
                    }
                }
                .onEnded { val in
                    if let dragIdx = draggingIndex,
                       let fromPos = displaySpaces.firstIndex(of: dragIdx) {
                        let cardWidth: CGFloat = 132.0
                        let offsetSlots = Int(round(val.translation.width / cardWidth))
                        let targetPos = max(0, min(displaySpaces.count - 1, fromPos + offsetSlots))
                        if targetPos != fromPos {
                            withAnimation(.spring(response: 0.25, dampingFraction: 0.78)) {
                                manager.reorderDesktops(fromIndex: fromPos, toIndex: targetPos)
                            }
                        }
                    }
                    withAnimation(.spring(response: 0.25, dampingFraction: 0.78)) {
                        draggingIndex = nil
                        dragOffset = 0
                    }
                }
        )
        .onHover { h in
            withAnimation(.spring(response: 0.20, dampingFraction: 0.72)) {
                hoveredCardIndex = h ? slotIndex : nil
            }
        }
    }

    private func spaceTitle(for slotIndex: Int) -> String {
        if let sp = manager.spaces.first(where: { $0.index == slotIndex }) {
            return manager.workspaceName(for: sp)
        }
        return "Desktop \(slotIndex)"
    }

    @ViewBuilder
    private func hudThumbnailCard(slotIndex: Int, isCurrent: Bool) -> some View {
        if let live = manager.desktopLivePreviews[slotIndex] {
            Image(nsImage: live)
                .resizable()
                .aspectRatio(16/10, contentMode: .fill)
                .frame(width: 120, height: 75)
                .clipped()
        } else if let wp = wallpaperManager.activeWallpaperImage {
            Image(nsImage: wp)
                .resizable()
                .aspectRatio(16/10, contentMode: .fill)
                .frame(width: 120, height: 75)
                .clipped()
                .opacity(isCurrent ? 1.0 : 0.65)
        } else {
            let c1 = isCurrent ? Color.cyan.opacity(0.6) : Color.black.opacity(0.6)
            let c2 = isCurrent ? Color.blue.opacity(0.8) : Color.gray.opacity(0.3)
            LinearGradient(
                colors: [c1, c2],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .frame(width: 120, height: 75)
        }
    }
}
