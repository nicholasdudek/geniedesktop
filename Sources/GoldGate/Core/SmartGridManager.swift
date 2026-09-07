import Cocoa
import SwiftUI
import ApplicationServices
import Carbon

// MARK: - Screen Choices & Grid Modes
public enum GridScreenChoice: String, CaseIterable, Identifiable {
    case auto = "Auto"
    case halfScreens = "Halves"
    case single = "Full Screen"
    case quadrant2x2 = "2x2"
    case matrix9x9 = "9x9 Spatial (81 Slots)"
    case matrix4x3 = "4x3"
    case toDesktops = "To Desktops"

    public var id: String { rawValue }

    public init?(rawValue: String) {
        switch rawValue {
        case "Auto": self = .auto
        case "Halves", "Half Screens", "Half": self = .halfScreens
        case "Full Screen", "1 Screen", "Single", "Full": self = .single
        case "2x2", "Quadrant 2x2": self = .quadrant2x2
        case "9x9 Spatial (81 Slots)", "9x9 Spatial", "9x9", "81 Slots", "81": self = .matrix9x9
        case "4x3", "Matrix 4x3", "4x4": self = .matrix4x3
        case "To Desktops", "Desktops", "Sort to Desktops": self = .toDesktops
        default: return nil
        }
    }

    public var columns: Int {
        switch self {
        case .auto: return 0 // Dynamically computed
        case .halfScreens: return 2
        case .single: return 1
        case .quadrant2x2: return 2
        case .matrix9x9: return 9
        case .matrix4x3: return 4
        case .toDesktops: return 0 // Distributed across spaces
        }
    }

    public var rows: Int {
        switch self {
        case .auto: return 0 // Dynamically computed
        case .halfScreens: return 1
        case .single: return 1
        case .quadrant2x2: return 2
        case .matrix9x9: return 9
        case .matrix4x3: return 3
        case .toDesktops: return 0
        }
    }

    public var totalSlots: Int { columns * rows }

    public var icon: String {
        switch self {
        case .auto: return "wand.and.stars"
        case .halfScreens: return "rectangle.split.2x1.fill"
        case .single: return "rectangle.fill"
        case .quadrant2x2: return "square.grid.2x2.fill"
        case .matrix9x9: return "circle.grid.3x3.fill"
        case .matrix4x3: return "rectangle.grid.3x2.fill"
        case .toDesktops: return "macwindow.on.rectangle"
        }
    }

    public var description: String {
        switch self {
        case .auto: return "Auto Halves & Full Screen (smartly adapts to open apps)"
        case .halfScreens: return "Half Screens (50/50 side-by-side split)"
        case .single: return "Full Screen (100% maximized work area)"
        case .quadrant2x2: return "4 Quadrants (2x2)"
        case .matrix9x9: return "81-Slot 9x9 Spatial Universe Matrix (9x9 Mega-Canvas Grid)"
        case .matrix4x3: return "12 Slots Matrix (4x3)"
        case .toDesktops: return "Sort & distribute open applications across Desktops 1–4"
        }
    }
}

// MARK: - Multi-Monitor / Connected Displays Model
public struct ConnectedMonitorInfo: Identifiable, Equatable {
    public let id: Int // 1-indexed (Screen 1, Screen 2...)
    public let name: String
    public let shortName: String
    public let resolution: String
    public let isMain: Bool
    public let isCursorOnScreen: Bool
    public let frame: CGRect
    public let visibleFrame: CGRect
}

// MARK: - Smart Grid Window Model
public struct ManagedWindowInfo: Identifiable {
    public let id: CGWindowID
    public let pid: pid_t
    public let ownerName: String
    public let title: String
    public let frame: CGRect
}

// MARK: - Smart Grid & Screen Manager
@MainActor
public final class SmartGridManager: ObservableObject {
    public static let shared = SmartGridManager()

    @AppStorage(PrefKey.selectedScreenChoice) public var activeChoiceRaw: String = GridScreenChoice.quadrant2x2.rawValue
    @Published public var selectedScreenIndex: Int = 1 // 1-indexed (Screen 1, Screen 2, Screen 3)
    @Published public var connectedScreens: [ConnectedMonitorInfo] = []
    @Published public var lastStatusMessage: String = ""

    private var globalKeyMonitor: Any?
    private var localKeyMonitor: Any?

    public var activeChoice: GridScreenChoice {
        get { GridScreenChoice(rawValue: activeChoiceRaw) ?? .quadrant2x2 }
        set { activeChoiceRaw = newValue.rawValue }
    }

    private init() {
        refreshConnectedScreens()
        loadAnchorsFromDisk()
        startListeningForHotkeys()

        NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshConnectedScreens()
                self?.restoreAllWindowAnchors()
            }
        }

        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.restoreAllWindowAnchors()
            }
        }

        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NexusToggleWindowExpander"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.maximizeFrontmostWindowToTopEdge(includeMenuBarArea: true)
            }
        }
    }

    public func refreshConnectedScreens() {
        let screens = NSScreen.screens
        let mouseLoc = NSEvent.mouseLocation
        self.connectedScreens = screens.enumerated().map { index, screen in
            let screenNum = index + 1
            let isMain = screen == NSScreen.main
            let isCursor = screen.frame.contains(mouseLoc)
            let resW = Int(screen.frame.width)
            let resH = Int(screen.frame.height)
            let res = "\(resW)×\(resH)"
            let name = screen.localizedName.isEmpty ? "Display \(screenNum)" : screen.localizedName
            return ConnectedMonitorInfo(
                id: screenNum,
                name: "\(name) (\(res))",
                shortName: "S\(screenNum)",
                resolution: res,
                isMain: isMain,
                isCursorOnScreen: isCursor,
                frame: screen.frame,
                visibleFrame: screen.visibleFrame
            )
        }
        if selectedScreenIndex > max(1, screens.count) {
            selectedScreenIndex = 1
        }
    }

    public func cycleNextMonitor() {
        refreshConnectedScreens()
        guard connectedScreens.count > 1 else { return }
        selectedScreenIndex = (selectedScreenIndex % connectedScreens.count) + 1
        HapticFeedback.selection()
        lastStatusMessage = "Switched to Screen \(selectedScreenIndex)"
    }

    // MARK: - Global Shortcuts for "Bring All to Screen"
    public func startListeningForHotkeys() {
        stopListeningForHotkeys()

        // 1. Global Monitor (Active even when dropdown is closed)
        globalKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            Task { @MainActor in
                self?.handleKeyEvent(event)
            }
        }

        // 2. Local Monitor (When Genie is active)
        localKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.handleKeyEvent(event) == true {
                return nil
            }
            return event
        }
    }

    public func stopListeningForHotkeys() {
        if let g = globalKeyMonitor {
            NSEvent.removeMonitor(g)
            globalKeyMonitor = nil
        }
        if let l = localKeyMonitor {
            NSEvent.removeMonitor(l)
            localKeyMonitor = nil
        }
    }

    @discardableResult
    private func handleKeyEvent(_ event: NSEvent) -> Bool {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)

        // 1. Global Genie Search / Note Bar Trigger (Default: Option + Space ⌥ Space)
        if event.keyCode == 49 { // Space bar
            let hotkeyChoice = UserDefaults.standard.string(forKey: PrefKey.searchHotkeyChoice) ?? "Option + Space (⌥ Space)"
            var matchesSearchHotkey = false

            if hotkeyChoice.contains("Option + Space") {
                // Exact Option + Space (without Command or Control)
                matchesSearchHotkey = flags.contains(.option) && !flags.contains(.command) && !flags.contains(.control)
            } else if hotkeyChoice.contains("Shift + Command + Space") {
                matchesSearchHotkey = flags.contains(.shift) && flags.contains(.command)
            } else if hotkeyChoice.contains("Control + Space") {
                matchesSearchHotkey = flags.contains(.control) && !flags.contains(.command) && !flags.contains(.option)
            } else if hotkeyChoice.contains("Command + Option + Space") {
                matchesSearchHotkey = flags.contains(.command) && flags.contains(.option)
            }

            if matchesSearchHotkey {
                HapticFeedback.selection()
                DispatchQueue.main.async {
                    FinderChatWindowManager.shared.toggle()
                }
                return true
            }
        }

        // 2. Global Desktop Files Toggle (Command + Shift + D)
        if event.keyCode == 2 { // 'D' key
            if flags.contains(.command) && flags.contains(.shift) {
                HapticFeedback.selection()
                DesktopFilesManager.shared.toggleDesktopFiles()
                return true
            }
        }

        // ⌘ + ⌥ shortcuts
        guard flags.contains(.command) && flags.contains(.option) else { return false }

        switch event.keyCode {
        case 123: // ⌘ + ⌥ + Left Arrow = Snap Left Edge / Left Half!
            snapFrontmostWindow(direction: .left)
            return true

        case 124: // ⌘ + ⌥ + Right Arrow = Snap Right Edge / Right Half!
            snapFrontmostWindow(direction: .right)
            return true

        case 126: // ⌘ + ⌥ + Up Arrow = Maximize / Top Edge!
            snapFrontmostWindow(direction: .maximize)
            return true

        case 125: // ⌘ + ⌥ + Down Arrow = Center / Bottom Edge!
            snapFrontmostWindow(direction: .center)
            return true

        case 8: // ⌘ + ⌥ + C = Snap Center
            snapFrontmostWindow(direction: .center)
            return true

        case 49: // ⌘ + ⌥ + Space = Bring All to Screen!
            HapticFeedback.heavy()
            bringAllToScreen()
            return true

        case 11: // ⌘ + ⌥ + B = Bring All to Screen (B = Bring)
            HapticFeedback.heavy()
            bringAllToScreen()
            return true

        case 18: // ⌘ + ⌥ + 1 = Full Screen mode
            HapticFeedback.selection()
            activeChoice = .single
            bringAllToScreen(choice: .single)
            return true

        case 19: // ⌘ + ⌥ + 2 = Halves (50/50) mode
            HapticFeedback.selection()
            activeChoice = .halfScreens
            bringAllToScreen(choice: .halfScreens)
            return true

        case 20: // ⌘ + ⌥ + 3 = 4x3 mode
            HapticFeedback.selection()
            activeChoice = .matrix4x3
            bringAllToScreen(choice: .matrix4x3)
            return true

        case 21: // ⌘ + ⌥ + 4 = 2x2 mode
            HapticFeedback.selection()
            activeChoice = .quadrant2x2
            bringAllToScreen(choice: .quadrant2x2)
            return true

        case 2: // ⌘ + ⌥ + D = Sort to Desktops!
            HapticFeedback.heavy()
            activeChoice = .toDesktops
            sortApplicationsToDesktops()
            return true

        case 46: // ⌘ + ⌥ + M = Cycle Next Monitor/Screen
            cycleNextMonitor()
            return true

        default:
            return false
        }
    }

    // MARK: - Dynamic Optimal Layout Computation (Auto: 1 App = Full Screen, 2 Apps = Halves, 3-4 = Quarters/Halves)
    public func computeOptimalSlots(for windowCount: Int, workArea: CGRect) -> [CGRect] {
        let padding: CGFloat = 6
        let gap: CGFloat = 8
        let usableW = workArea.width - (padding * 2)
        let usableH = workArea.height - (padding * 2)
        let aspect = workArea.width / max(1, workArea.height)

        if windowCount <= 1 {
            // Full Screen work area for single window
            return [workArea]
        }

        if windowCount == 2 {
            if aspect >= 1.05 {
                // Side-by-side 50/50 split (Left Half & Right Half)
                let slotW = (usableW - gap) / 2
                let left = CGRect(x: workArea.minX + padding, y: workArea.minY + padding, width: slotW, height: usableH)
                let right = CGRect(x: workArea.minX + padding + slotW + gap, y: workArea.minY + padding, width: slotW, height: usableH)
                return [left, right]
            } else {
                // Top/Bottom split for vertical monitor
                let slotH = (usableH - gap) / 2
                let top = CGRect(x: workArea.minX + padding, y: workArea.minY + padding + slotH + gap, width: usableW, height: slotH)
                let bottom = CGRect(x: workArea.minX + padding, y: workArea.minY + padding, width: usableW, height: slotH)
                return [top, bottom]
            }
        }

        if windowCount == 3 {
            if aspect >= 2.0 {
                // Ultra-wide: 3 equal vertical columns
                let slotW = (usableW - (gap * 2)) / 3
                return (0..<3).map { i in
                    CGRect(x: workArea.minX + padding + CGFloat(i) * (slotW + gap), y: workArea.minY + padding, width: slotW, height: usableH)
                }
            } else {
                // Master + 2 Stack: Left 50% dominant half, right 50% split into 2 stacked panes
                let masterW = (usableW - gap) * 0.50
                let stackW = (usableW - gap) * 0.50
                let stackH = (usableH - gap) / 2

                let master = CGRect(x: workArea.minX + padding, y: workArea.minY + padding, width: masterW, height: usableH)
                let topStack = CGRect(x: workArea.minX + padding + masterW + gap, y: workArea.minY + padding + stackH + gap, width: stackW, height: stackH)
                let btmStack = CGRect(x: workArea.minX + padding + masterW + gap, y: workArea.minY + padding, width: stackW, height: stackH)
                return [master, topStack, btmStack]
            }
        }

        // 4+ windows: calculate optimal balanced grid
        let cols: Int
        let rows: Int
        if windowCount == 4 {
            cols = 2; rows = 2
        } else if windowCount <= 6 {
            cols = aspect >= 1.3 ? 3 : 2
            rows = Int(ceil(Double(windowCount) / Double(cols)))
        } else if windowCount <= 8 {
            cols = 4; rows = 2
        } else {
            cols = 4; rows = 3
        }

        let slotW = max(160, (usableW - (gap * CGFloat(cols - 1))) / CGFloat(cols))
        let slotH = max(120, (usableH - (gap * CGFloat(rows - 1))) / CGFloat(rows))

        var slots: [CGRect] = []
        for i in 0..<min(windowCount, cols * rows) {
            let c = i % cols
            let r = i / cols
            let x = workArea.minX + padding + CGFloat(c) * (slotW + gap)
            let y = workArea.maxY - padding - CGFloat(r + 1) * slotH - CGFloat(r) * gap
            slots.append(CGRect(x: x, y: y, width: slotW, height: slotH))
        }
        return slots
    }

    // MARK: - Half Screens Computation (50/50 Side-by-Side Split)
    public func computeHalfSlots(for windowCount: Int, workArea: CGRect) -> [CGRect] {
        let padding: CGFloat = 6
        let gap: CGFloat = 8
        let usableW = workArea.width - (padding * 2)
        let usableH = workArea.height - (padding * 2)
        let halfW = (usableW - gap) / 2

        let leftHalf = CGRect(x: workArea.minX + padding, y: workArea.minY + padding, width: halfW, height: usableH)
        let rightHalf = CGRect(x: workArea.minX + padding + halfW + gap, y: workArea.minY + padding, width: halfW, height: usableH)

        if windowCount <= 1 {
            return [leftHalf]
        } else if windowCount == 2 {
            return [leftHalf, rightHalf]
        } else {
            let leftCount = (windowCount + 1) / 2
            let rightCount = windowCount - leftCount
            var slots: [CGRect] = []

            // Left side vertical stack
            let leftH = (usableH - CGFloat(leftCount - 1) * gap) / CGFloat(leftCount)
            for i in 0..<leftCount {
                let y = workArea.maxY - padding - CGFloat(i + 1) * leftH - CGFloat(i) * gap
                slots.append(CGRect(x: workArea.minX + padding, y: y, width: halfW, height: leftH))
            }

            // Right side vertical stack
            let rightH = (usableH - CGFloat(rightCount - 1) * gap) / CGFloat(rightCount)
            for i in 0..<rightCount {
                let y = workArea.maxY - padding - CGFloat(i + 1) * rightH - CGFloat(i) * gap
                slots.append(CGRect(x: workArea.minX + padding + halfW + gap, y: y, width: halfW, height: rightH))
            }
            return slots
        }
    }

    // MARK: - Ultra-Fast Instant App Switcher & Bring To Front (Dock Parity)
    public func quickSwitchApp(pid: pid_t) {
        guard let app = NSRunningApplication(processIdentifier: pid) else { return }
        bringToFront(app: app)
    }

    public func bringToFront(app: NSRunningApplication) {
        // 1. Record launch count for intelligent recents ranking
        if let name = app.localizedName {
            var counts = UserDefaults.standard.dictionary(forKey: PrefKey.launchCounts) as? [String: Int] ?? [:]
            counts[name, default: 0] += 1
            UserDefaults.standard.set(counts, forKey: PrefKey.launchCounts)
        }

        // 2. Close any open popovers so target application receives full frontmost focus
        NotificationCenter.default.post(name: NSNotification.Name("NexusClose"), object: nil)

        // 3. Resolve exact bundle URL matching AppModel
        let targetURL: URL? = {
            if let bURL = app.bundleURL { return bURL }
            if app.bundleIdentifier == "com.apple.finder" || (app.localizedName ?? "").lowercased() == "finder" {
                return URL(fileURLWithPath: "/System/Library/CoreServices/Finder.app")
            }
            if let bId = app.bundleIdentifier, let foundURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bId) {
                return foundURL
            }
            return nil
        }()

        // 4. Launch and bring to front using macOS OpenConfiguration (exact Genie dropdown mechanism)
        if let url = targetURL {
            let config = NSWorkspace.OpenConfiguration()
            config.activates = true
            config.addsToRecentItems = true
            NSWorkspace.shared.openApplication(at: url, configuration: config) { appInstance, error in
                if appInstance == nil || error != nil {
                    DispatchQueue.main.async {
                        _ = NSWorkspace.shared.open(url)
                    }
                }
            }
        } else {
            app.unhide()
            _ = app.activate(options: [.activateAllWindows])
        }

        // 5. AppleScript reopen & activate (guarantees window is created if 0 windows open or on another Space)
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
        }
    }

    // MARK: - Macro: Minimize/Hide All Windows and Open Target Application
    public func openAppCleanMacro(pid: pid_t, choice: GridScreenChoice? = nil, minimizeOthers: Bool = true) {
        HapticFeedback.heavy()
        guard let app = NSRunningApplication(processIdentifier: pid) else { return }

        // 1. Unhide target app
        app.unhide()

        // 2. Clean macro: hide/minimize all other background applications so target app owns screen
        if minimizeOthers {
            let myPid = ProcessInfo.processInfo.processIdentifier
            for other in NSWorkspace.shared.runningApplications where other.activationPolicy == .regular {
                if other.processIdentifier != pid && other.processIdentifier != myPid {
                    other.hide()
                }
            }

            DispatchQueue.global(qos: .userInteractive).async {
                let script = """
                tell application "System Events"
                    try
                        set visible of (every process whose visible is true and unix id is not \(pid) and bundle identifier is not "com.apple.finder") to false
                    end try
                end tell
                """
                if let asObj = NSAppleScript(source: script) {
                    var err: NSDictionary?
                    asObj.executeAndReturnError(&err)
                }
            }
        }

        // 3. Open & bring target application to front via NSWorkspace OpenConfiguration
        if let bundleURL = app.bundleURL {
            let config = NSWorkspace.OpenConfiguration()
            config.activates = true
            config.addsToRecentItems = false
            NSWorkspace.shared.openApplication(at: bundleURL, configuration: config, completionHandler: nil)
        }

        // 4. AppleScript reopen + activate
        if let bundleId = app.bundleIdentifier {
            let script = """
            tell application id "\(bundleId)"
                reopen
                activate
            end tell
            """
            DispatchQueue.global(qos: .userInteractive).async {
                if let asObj = NSAppleScript(source: script) {
                    var err: NSDictionary?
                    asObj.executeAndReturnError(&err)
                }
            }
        }

        // 5. Position & tile window into optimal layout
        focusAndTileApp(pid: pid, choice: choice)
    }

    // MARK: - Focus and Load Single App in Chosen Layout
    public func focusAndTileApp(pid: pid_t, choice: GridScreenChoice? = nil) {
        let selectedMode = choice ?? activeChoice
        HapticFeedback.selection()

        // 1. Activate target app and bring to front
        guard let app = NSRunningApplication(processIdentifier: pid) else { return }
        app.unhide()

        // macOS 14+ official openApplication API
        if let bundleURL = app.bundleURL {
            let config = NSWorkspace.OpenConfiguration()
            config.activates = true
            config.addsToRecentItems = false
            NSWorkspace.shared.openApplication(at: bundleURL, configuration: config, completionHandler: nil)
        }

        // AppleScript reopen & activate (guarantees window is created if 0 windows open)
        if let bundleId = app.bundleIdentifier {
            let script = """
            tell application id "\(bundleId)"
                reopen
                activate
            end tell
            """
            DispatchQueue.global(qos: .userInteractive).async {
                if let asObj = NSAppleScript(source: script) {
                    var err: NSDictionary?
                    asObj.executeAndReturnError(&err)
                }
            }
        }

        let appElem = AXUIElementCreateApplication(pid)
        AXUIElementSetAttributeValue(appElem, kAXFrontmostAttribute as CFString, kCFBooleanTrue)

        // 2. Target screen
        let screens = NSScreen.screens
        let targetScreen: NSScreen
        if selectedScreenIndex > 0 && selectedScreenIndex <= screens.count {
            targetScreen = screens[selectedScreenIndex - 1]
        } else {
            targetScreen = NSScreen.main ?? (screens.first ?? NSScreen())
        }

        let primaryHeight = screens.first?.frame.height ?? 1080
        let workArea = largestWorkArea(for: targetScreen)

        // 3. Size and position based on choice
        let targetFrameCocoa: CGRect
        switch selectedMode {
        case .auto:
            targetFrameCocoa = workArea
        case .halfScreens:
            let halfW = (workArea.width - 8) / 2
            targetFrameCocoa = CGRect(x: workArea.minX, y: workArea.minY, width: halfW, height: workArea.height)
        case .single:
            targetFrameCocoa = workArea
        case .quadrant2x2:
            let halfW = (workArea.width - 24) / 2
            let halfH = (workArea.height - 24) / 2
            targetFrameCocoa = CGRect(
                x: workArea.minX + 8,
                y: workArea.maxY - halfH - 8,
                width: halfW,
                height: halfH
            )

        case .matrix9x9:
            let slotW = max(100, (workArea.width - 80) / 9)
            let slotH = max(80, (workArea.height - 80) / 9)
            targetFrameCocoa = CGRect(
                x: workArea.minX + 8,
                y: workArea.maxY - slotH - 8,
                width: slotW,
                height: slotH
            )
        case .matrix4x3:
            let slotW = (workArea.width - 40) / 4
            let slotH = (workArea.height - 30) / 3
            targetFrameCocoa = CGRect(
                x: workArea.minX + 8,
                y: workArea.maxY - slotH - 8,
                width: slotW,
                height: slotH
            )
        case .toDesktops:
            targetFrameCocoa = workArea
        }

        let quartzY = primaryHeight - targetFrameCocoa.maxY
        let quartzFrame = CGRect(x: targetFrameCocoa.origin.x, y: quartzY, width: targetFrameCocoa.width, height: targetFrameCocoa.height)

        if let axElem = findWindowElement(pid: pid, fallbackFrame: nil) {
            setWindowFrame(element: axElem, frame: quartzFrame, pid: pid)
        } else {
            moveWindowViaSystemEvents(pid: pid, frame: quartzFrame)
        }
        lastStatusMessage = "Loaded \(app.localizedName ?? "App") in \(selectedMode.rawValue)"
    }

    // MARK: - Detect Hardware Screen Size & Set Largest Possible Work Area (14" MacBook Pro Liquid Retina XDR)
    public func largestWorkArea(for screen: NSScreen) -> CGRect {
        let fullFrame = screen.frame
        let notchHeight: CGFloat = {
            if #available(macOS 12.0, *) {
                let inset = screen.safeAreaInsets.top
                return inset > 0 ? inset : (CustomMenuBarManager.shared.isEnabled ? 44.0 : 28.0)
            }
            return CustomMenuBarManager.shared.isEnabled ? 44.0 : 28.0
        }()
        let sideMargin: CGFloat = 6.0
        let bottomMargin: CGFloat = 8.0
        return CGRect(
            x: fullFrame.origin.x + sideMargin,
            y: fullFrame.origin.y + bottomMargin,
            width: max(320, fullFrame.width - (sideMargin * 2)),
            height: max(240, fullFrame.height - notchHeight - bottomMargin)
        )
    }

    // MARK: - Group All Applications as One Block
    public func layoutAllApplicationsAsBlock(targetScreen: NSScreen? = nil) {
        _ = targetScreen ?? (NSScreen.main ?? (NSScreen.screens.first ?? NSScreen()))
        bringAllToScreen(choice: .auto)
    }

    // MARK: - Bring All to Screen (Smart Grid Tiling + Focus)
    public func bringAllToScreen(choice: GridScreenChoice? = nil) {
        let selectedMode = choice ?? activeChoice
        HapticFeedback.heavy()

        if selectedMode == .toDesktops {
            sortApplicationsToDesktops()
            return
        }

        // 1. Target Screen determination (supports Screen 1, Screen 2, Screen 3)
        let screens = NSScreen.screens
        let targetScreen: NSScreen
        if selectedScreenIndex > 0 && selectedScreenIndex <= screens.count {
            targetScreen = screens[selectedScreenIndex - 1]
        } else {
            targetScreen = NSScreen.main ?? (screens.first ?? NSScreen())
        }

        let primaryHeight = screens.first?.frame.height ?? 1080
        let workArea = largestWorkArea(for: targetScreen)

        // 2. Query all visible application windows
        let windows = getVisibleWindows(primaryHeight: primaryHeight)
        let myPid = ProcessInfo.processInfo.processIdentifier
        var filteredWindows = windows.filter { $0.pid != myPid }

        // Fallback: If Quartz on-screen query was empty (e.g. apps minimized, on another desktop space, or permission edge case),
        // query all running regular applications, unhide them, and find/create their accessibility windows!
        if filteredWindows.isEmpty {
            let runningApps = NSWorkspace.shared.runningApplications.filter {
                $0.activationPolicy == .regular &&
                $0.processIdentifier != myPid &&
                !$0.isTerminated &&
                $0.bundleIdentifier != "com.apple.dock"
            }
            for app in runningApps {
                app.unhide()
                let pid = app.processIdentifier
                let appElem = AXUIElementCreateApplication(pid)
                var windowListRef: CFTypeRef?
                if AXUIElementCopyAttributeValue(appElem, kAXWindowsAttribute as CFString, &windowListRef) == .success,
                   let windowList = windowListRef as? [AXUIElement], !windowList.isEmpty {
                    for win in windowList.prefix(2) {
                        AXUIElementSetAttributeValue(win, kAXMinimizedAttribute as CFString, kCFBooleanFalse)
                        filteredWindows.append(ManagedWindowInfo(
                            id: 0,
                            pid: pid,
                            ownerName: app.localizedName ?? "App",
                            title: app.localizedName ?? "App",
                            frame: workArea
                        ))
                    }
                } else {
                    if let bundleId = app.bundleIdentifier {
                        let script = "tell application id \"\(bundleId)\" to reopen"
                        DispatchQueue.global(qos: .userInitiated).async {
                            NSAppleScript(source: script)?.executeAndReturnError(nil)
                        }
                    }
                    filteredWindows.append(ManagedWindowInfo(
                        id: 0,
                        pid: pid,
                        ownerName: app.localizedName ?? "App",
                        title: app.localizedName ?? "App",
                        frame: workArea
                    ))
                }
            }
        }

        // If still empty, unhide & activate Finder so a window is always ready
        if filteredWindows.isEmpty {
            if let finder = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == "com.apple.finder" }) {
                finder.unhide()
                finder.activate()
                filteredWindows.append(ManagedWindowInfo(
                    id: 0,
                    pid: finder.processIdentifier,
                    ownerName: "Finder",
                    title: "Finder",
                    frame: workArea
                ))
            }
        }

        // Reorder windows logically: frontmost active app first, then MRU open apps
        if let frontPid = NSWorkspace.shared.frontmostApplication?.processIdentifier {
            filteredWindows.sort { a, b in
                if a.pid == frontPid { return true }
                if b.pid == frontPid { return false }
                return a.ownerName < b.ownerName
            }
        }

        var updatedCount = 0

        // 3. Compute slots based on Auto vs Halves vs Full vs Grid
        let targetFramesCocoa: [CGRect]
        if selectedMode == .auto {
            targetFramesCocoa = computeOptimalSlots(for: filteredWindows.count, workArea: workArea)
        } else if selectedMode == .halfScreens {
            targetFramesCocoa = computeHalfSlots(for: filteredWindows.count, workArea: workArea)
        } else if selectedMode == .single {
            targetFramesCocoa = Array(repeating: workArea, count: max(1, filteredWindows.count))
        } else {
            let cols = selectedMode.columns
            let rows = selectedMode.rows
            let padding: CGFloat = 8
            let gap: CGFloat = 8
            let usableW = workArea.width - (padding * 2) - (gap * CGFloat(cols - 1))
            let usableH = workArea.height - (padding * 2) - (gap * CGFloat(rows - 1))
            let slotW = max(180, usableW / CGFloat(cols))
            let slotH = max(140, usableH / CGFloat(rows))

            var frames: [CGRect] = []
            for index in 0..<min(filteredWindows.count, cols * rows) {
                let col = index % cols
                let row = index / cols
                let targetX = workArea.minX + padding + CGFloat(col) * (slotW + gap)
                let targetY = workArea.maxY - padding - CGFloat(row + 1) * slotH - CGFloat(row) * gap
                frames.append(CGRect(x: targetX, y: targetY, width: slotW, height: slotH))
            }
            targetFramesCocoa = frames
        }

        // 4. Position each window into its slot
        for (index, win) in filteredWindows.prefix(targetFramesCocoa.count).enumerated() {
            let targetFrameCocoa = targetFramesCocoa[index]

            // Convert to Accessibility / Quartz coords (top-left origin)
            let quartzY = primaryHeight - targetFrameCocoa.maxY
            let quartzFrame = CGRect(x: targetFrameCocoa.origin.x, y: quartzY, width: targetFrameCocoa.width, height: targetFrameCocoa.height)

            if let axElem = findWindowElement(pid: win.pid, fallbackFrame: win.frame) {
                setWindowFrame(element: axElem, frame: quartzFrame)
                updatedCount += 1
            }

            // Bring app to front
            if let app = NSRunningApplication(processIdentifier: win.pid) {
                app.unhide()
                app.activate()
            }
        }

        // Clean status update — never invoke Mission Control fallback to avoid UI conflicts!
        if updatedCount == 0 {
            lastStatusMessage = "Active applications focused and unified in block"
        } else {
            lastStatusMessage = "Unified \(updatedCount) applications into block (\(selectedMode.rawValue))"
        }

        NotificationCenter.default.post(
            name: NSNotification.Name("NexusWindowsTiledOnScreen"),
            object: ["mode": selectedMode.rawValue, "count": updatedCount]
        )
    }

    // MARK: - Sort Applications Across Desktops 1–4 ("you could sort to desktops")
    public func sortApplicationsToDesktops() {
        HapticFeedback.heavy()
        let desktopsManager = MacDesktopsManager.shared
        desktopsManager.refreshSpaces()

        let screens = NSScreen.screens
        let primaryHeight = screens.first?.frame.height ?? 1080
        let visibleWindows = getVisibleWindows(primaryHeight: primaryHeight)
        let myPid = ProcessInfo.processInfo.processIdentifier

        // 1. Collect unique running application pids
        var seenPids = Set<pid_t>()
        var targetApps: [(pid: pid_t, name: String, winId: CGWindowID)] = []
        for win in visibleWindows {
            if win.pid != myPid && !seenPids.contains(win.pid) {
                seenPids.insert(win.pid)
                targetApps.append((pid: win.pid, name: win.ownerName, winId: win.id))
            }
        }

        if targetApps.isEmpty {
            let apps = NSWorkspace.shared.runningApplications.filter {
                $0.activationPolicy == .regular &&
                $0.processIdentifier != myPid &&
                !$0.isTerminated &&
                $0.bundleIdentifier != "com.apple.dock"
            }
            targetApps = apps.map { (pid: $0.processIdentifier, name: $0.localizedName ?? "App", winId: 0) }
        }

        guard !targetApps.isEmpty else {
            lastStatusMessage = "No open applications to sort"
            return
        }

        // 2. Ensure we have sufficient desktop spaces (up to 4 max)
        let neededSpaces = min(4, max(2, targetApps.count))
        while desktopsManager.spaces.count < neededSpaces && desktopsManager.spaces.count < 4 {
            desktopsManager.createDesktop()
        }
        desktopsManager.refreshSpaces()

        let availableSpaces = desktopsManager.spaces
        guard !availableSpaces.isEmpty else { return }

        // SkyLight symbols for direct kernel space window assignment
        typealias SLSMainConnectionIDFunc = @convention(c) () -> Int32
        typealias SLSMoveWindowsToManagedSpaceFunc = @convention(c) (Int32, CFArray, UInt64) -> Int32

        var moveFunc: SLSMoveWindowsToManagedSpaceFunc? = nil
        var cid: Int32 = 0
        var slHandle: UnsafeMutableRawPointer? = nil

        if let handle = dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/Versions/A/SkyLight", RTLD_LAZY),
           let cidSym = dlsym(handle, "SLSMainConnectionID"),
           let moveSym = dlsym(handle, "SLSMoveWindowsToManagedSpace") {
            slHandle = handle
            let getCID = unsafeBitCast(cidSym, to: SLSMainConnectionIDFunc.self)
            moveFunc = unsafeBitCast(moveSym, to: SLSMoveWindowsToManagedSpaceFunc.self)
            cid = getCID()
        }

        // 3. Distribute apps evenly across spaces 1...min(4, availableSpaces.count)
        let spaceCount = min(4, availableSpaces.count)
        var distributedCount = 0

        for (index, item) in targetApps.enumerated() {
            let targetSpaceIndex = (index % spaceCount) // 0-indexed
            let space = availableSpaces[targetSpaceIndex]

            // If we have a window ID and space id64, move window via SkyLight
            if let spaceID = space.id64, item.winId > 0, let move = moveFunc {
                let winArray = [NSNumber(value: item.winId)] as CFArray
                _ = move(cid, winArray, spaceID)
            }

            if let app = NSRunningApplication(processIdentifier: item.pid) {
                app.unhide()
            }
            distributedCount += 1
        }

        if let h = slHandle {
            dlclose(h)
        }

        // 4. Tile the windows on the current desktop cleanly (Full Screen or Halves)
        let targetScreen = NSScreen.main ?? (screens.first ?? NSScreen())
        let workArea = targetScreen.visibleFrame

        for (index, item) in targetApps.enumerated() {
            let targetSpaceIndex = (index % spaceCount) + 1
            if targetSpaceIndex == desktopsManager.currentSpaceIndex {
                let frame: CGRect
                let appsOnThisSpace = targetApps.enumerated().filter { ($0.offset % spaceCount) + 1 == targetSpaceIndex }
                if appsOnThisSpace.count <= 1 {
                    frame = workArea
                } else {
                    let subIdx = appsOnThisSpace.firstIndex(where: { $0.element.pid == item.pid }) ?? 0
                    let halfW = (workArea.width - 8) / 2
                    let x = workArea.minX + CGFloat(subIdx % 2) * (halfW + 8)
                    frame = CGRect(x: x, y: workArea.minY, width: halfW, height: workArea.height)
                }

                let quartzY = primaryHeight - frame.maxY
                let quartzFrame = CGRect(x: frame.origin.x, y: quartzY, width: frame.width, height: frame.height)
                if let axElem = findWindowElement(pid: item.pid, fallbackFrame: nil) {
                    setWindowFrame(element: axElem, frame: quartzFrame, pid: item.pid)
                }
            }
        }

        lastStatusMessage = "Sorted \(distributedCount) apps across \(spaceCount) Desktops ✨"
        NotificationCenter.default.post(
            name: NSNotification.Name("NexusAppsSortedToDesktops"),
            object: ["appCount": distributedCount, "spaceCount": spaceCount]
        )
    }

    // MARK: - Move Single Application to Specific Desktop Space (1–9 or -1 Mirrored)
    public func moveAppToDesktop(pid: pid_t, targetDesktopIndex: Int) {
        guard (targetDesktopIndex >= 1 && targetDesktopIndex <= 9) || targetDesktopIndex == -1 else { return }
        HapticFeedback.heavy()

        if targetDesktopIndex == -1 {
            // Mirror coordinates of Desktop 1 to Desktop -1 (West Negative Space)
            let primaryHeight = NSScreen.screens.first?.frame.height ?? 1080
            let visibleWindows = getVisibleWindows(primaryHeight: primaryHeight)
            let appWindows = visibleWindows.filter { $0.pid == pid }

            for win in appWindows {
                let mirroredRect = SpatialPlaneManager.shared.mirrorCoordinatesToDesktopMinusOne(rect: win.frame)
                AppScreenSizeTricksterEngine.shared.clampWindow(pid: pid, targetRect: mirroredRect)
            }

            SpatialPlaneManager.shared.moveAppInSpatialRegistry(pid: pid, targetDesktopIndex: -1)
            lastStatusMessage = "Mirrored to Desktop -1 🪞"
            return
        }

        let desktopsManager = MacDesktopsManager.shared
        desktopsManager.refreshSpaces()

        while desktopsManager.spaces.count < targetDesktopIndex && desktopsManager.spaces.count < 9 {
            desktopsManager.createDesktop()
        }
        desktopsManager.refreshSpaces()

        guard let targetSpace = desktopsManager.spaces.first(where: { $0.index == targetDesktopIndex }),
              let spaceID = targetSpace.id64 else { return }

        let primaryHeight = NSScreen.screens.first?.frame.height ?? 1080
        let visibleWindows = getVisibleWindows(primaryHeight: primaryHeight)
        let appWindows = visibleWindows.filter { $0.pid == pid }

        typealias SLSMainConnectionIDFunc = @convention(c) () -> Int32
        typealias SLSMoveWindowsToManagedSpaceFunc = @convention(c) (Int32, CFArray, UInt64) -> Int32

        if let handle = dlopen("/System/Library/PrivateFrameworks/SkyLight.framework/Versions/A/SkyLight", RTLD_LAZY),
           let cidSym = dlsym(handle, "SLSMainConnectionID"),
           let moveSym = dlsym(handle, "SLSMoveWindowsToManagedSpace") {
            let getCID = unsafeBitCast(cidSym, to: SLSMainConnectionIDFunc.self)
            let moveWindows = unsafeBitCast(moveSym, to: SLSMoveWindowsToManagedSpaceFunc.self)
            let cid = getCID()

            for win in appWindows {
                let winArray = [NSNumber(value: win.id)] as CFArray
                _ = moveWindows(cid, winArray, spaceID)
            }
            dlclose(handle)
        }

        SpatialPlaneManager.shared.moveAppInSpatialRegistry(pid: pid, targetDesktopIndex: targetDesktopIndex)
        lastStatusMessage = "Moved to Desktop \(targetDesktopIndex)"
    }

    /// Carries the frontmost application to the previous or next desktop Space
    /// (direction: -1 for left/previous, +1 for right/next, including Desktop -1)
    /// Seamlessly moves the windows to that Space AND switches to the Space with the app focused!
    @discardableResult
    public func carryFrontmostAppToDesktop(direction: Int) -> Bool {
        let desktopsManager = MacDesktopsManager.shared
        desktopsManager.refreshSpaces()
        let currentIdx = desktopsManager.currentSpaceIndex
        let targetIdx: Int
        if currentIdx == 1 && direction == -1 {
            targetIdx = -1
        } else if currentIdx == -1 && direction == 1 {
            targetIdx = 1
        } else {
            targetIdx = max(1, min(9, currentIdx + direction))
        }
        guard targetIdx != currentIdx else { return false }

        // Find frontmost application (excluding Genie)
        let myPid = ProcessInfo.processInfo.processIdentifier
        var targetApp = NSWorkspace.shared.frontmostApplication
        if targetApp == nil || targetApp?.processIdentifier == myPid {
            let otherApps = NSWorkspace.shared.runningApplications
                .filter { $0.activationPolicy == .regular && $0.processIdentifier != myPid && !$0.isTerminated }
            targetApp = otherApps.first
        }
        guard let app = targetApp, app.processIdentifier != myPid else { return false }

        // Move the application's windows to the target desktop space
        moveAppToDesktop(pid: app.processIdentifier, targetDesktopIndex: targetIdx)

        // Switch to the target desktop space so the user travels WITH the application!
        if targetIdx >= 1 {
            desktopsManager.switchToDesktop(index: targetIdx)
        }

        // Re-activate the application in the new space
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            app.activate()
        }
        return true
    }

    // MARK: - Window Query via Quartz Window Services
    public func getVisibleWindows(primaryHeight: CGFloat) -> [ManagedWindowInfo] {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let infoList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else {
            return []
        }

        var results: [ManagedWindowInfo] = []
        let myPid = ProcessInfo.processInfo.processIdentifier

        for dict in infoList {
            guard let layer = dict[kCGWindowLayer as String] as? Int, layer == 0 else { continue }
            guard let pid = dict[kCGWindowOwnerPID as String] as? pid_t, pid != myPid else { continue }
            guard let winId = dict[kCGWindowNumber as String] as? CGWindowID else { continue }

            let ownerName = dict[kCGWindowOwnerName as String] as? String ?? ""
            if ownerName.isEmpty || ownerName == "Dock" || ownerName == "Window Server" || ownerName == "Genie" || ownerName == "shortArrow" {
                continue
            }

            guard let boundsDict = dict[kCGWindowBounds as String] as? [String: CGFloat],
                  let x = boundsDict["X"], let y = boundsDict["Y"],
                  let w = boundsDict["Width"], let h = boundsDict["Height"],
                  w > 120, h > 100 else { continue }

            let title = (dict[kCGWindowName as String] as? String) ?? ""
            let frame = CGRect(x: x, y: y, width: w, height: h)

            // Limit to 1-2 windows per app so all open apps get representation
            let countForPid = results.filter { $0.pid == pid }.count
            if countForPid < 2 {
                results.append(ManagedWindowInfo(id: winId, pid: pid, ownerName: ownerName, title: title, frame: frame))
            }
        }

        return results
    }

    // MARK: - Accessibility Window Frame Manipulation
    public func findWindowElement(pid: pid_t, fallbackFrame: CGRect?) -> AXUIElement? {
        let appElement = AXUIElementCreateApplication(pid)
        var windowListRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowListRef)
        guard result == .success, let windowList = windowListRef as? [AXUIElement], !windowList.isEmpty else {
            return nil
        }

        if let target = fallbackFrame {
            for window in windowList {
                var valueRef: CFTypeRef?
                if AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &valueRef) == .success,
                   let val = valueRef, CFGetTypeID(val) == AXValueGetTypeID() {
                    var pt = CGPoint.zero
                    let axVal = val as! AXValue
                    if AXValueGetValue(axVal, .cgPoint, &pt) {
                        if hypot(pt.x - target.origin.x, pt.y - target.origin.y) < 80 {
                            return window
                        }
                    }
                }
            }
        }
        return windowList.first
    }

    public func setWindowFrame(element: AXUIElement, frame: CGRect, pid: pid_t? = nil) {
        var origin = frame.origin
        var size = frame.size

        // 1. Unminimize if minimized & raise
        AXUIElementSetAttributeValue(element, kAXMinimizedAttribute as CFString, kCFBooleanFalse)
        AXUIElementPerformAction(element, kAXRaiseAction as CFString)

        var successPos = false
        var successSize = false

        if let posValue = AXValueCreate(.cgPoint, &origin) {
            let res = AXUIElementSetAttributeValue(element, kAXPositionAttribute as CFString, posValue)
            successPos = (res == .success)
        }
        if let sizeValue = AXValueCreate(.cgSize, &size) {
            let res = AXUIElementSetAttributeValue(element, kAXSizeAttribute as CFString, sizeValue)
            successSize = (res == .success)
        }

        // Second pass position
        if let posValue = AXValueCreate(.cgPoint, &origin) {
            _ = AXUIElementSetAttributeValue(element, kAXPositionAttribute as CFString, posValue)
        }
        AXUIElementPerformAction(element, kAXRaiseAction as CFString)

        // Guaranteed fallback via AppleScript System Events if AX failed
        if (!successPos || !successSize), let p = pid {
            moveWindowViaSystemEvents(pid: p, frame: frame)
        }
    }

    public func moveWindowViaSystemEvents(pid: pid_t, frame: CGRect) {
        let x = Int(frame.origin.x)
        let y = Int(frame.origin.y)
        let w = Int(frame.size.width)
        let h = Int(frame.size.height)
        DispatchQueue.global(qos: .userInteractive).async {
            let script = """
            tell application "System Events"
                try
                    set p to first process whose unix id is \(pid)
                    set frontmost of p to true
                    tell p
                        if (count of windows) > 0 then
                            set position of window 1 to {\(x), \(y)}
                            set size of window 1 to {\(w), \(h)}
                            perform action "AXRaise" of window 1
                        end if
                    end tell
                end try
            end tell
            """
            if let appleScript = NSAppleScript(source: script) {
                var error: NSDictionary?
                appleScript.executeAndReturnError(&error)
            }
        }
    }

    // MARK: - Window Snapping (Left, Right, Up / Maximize, Down / Center)
    public enum WindowSnapDirection: String, CaseIterable {
        case left = "Left Half"
        case right = "Right Half"
        case top = "Top Half"
        case bottom = "Bottom Half"
        case maximize = "Maximize"
        case center = "Center"
    }

    @discardableResult
    public func snapFrontmostWindow(direction: WindowSnapDirection) -> Bool {
        // Exclude Genie itself from being snapped; find the target app
        var targetApp = NSWorkspace.shared.frontmostApplication
        let myPid = ProcessInfo.processInfo.processIdentifier
        if targetApp == nil || targetApp?.processIdentifier == myPid {
            // Find the most recent active application that is not Genie
            let otherApps = NSWorkspace.shared.runningApplications
                .filter { $0.activationPolicy == .regular && $0.processIdentifier != myPid && !$0.isTerminated }
            targetApp = otherApps.first
        }

        guard let app = targetApp, app.processIdentifier != myPid else { return false }
        let appPid = app.processIdentifier

        let appElement = AXUIElementCreateApplication(appPid)
        var windowRef: CFTypeRef?
        var foundWindowElement: AXUIElement?

        if AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &windowRef) == .success,
           let ref = windowRef,
           CFGetTypeID(ref) == AXUIElementGetTypeID() {
            let win = ref as! AXUIElement
            foundWindowElement = win
        } else {
            var listRef: CFTypeRef?
            if AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &listRef) == .success,
               let list = listRef as? [AXUIElement], let first = list.first {
                foundWindowElement = first
            }
        }

        guard let winElem = foundWindowElement else { return false }

        // Determine screen: find the monitor actually containing the frontmost window
        let primaryHeight = NSScreen.screens.first?.frame.height ?? 1080
        var screen = NSScreen.main ?? NSScreen.screens.first ?? NSScreen()

        var posRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(winElem, kAXPositionAttribute as CFString, &posRef) == .success,
           let val = posRef, CFGetTypeID(val) == AXValueGetTypeID() {
            var pt = CGPoint.zero
            let axVal = val as! AXValue
            if AXValueGetValue(axVal, .cgPoint, &pt) {
                for s in NSScreen.screens {
                    let sQuartzY = primaryHeight - s.frame.maxY
                    let sQuartzFrame = CGRect(x: s.frame.origin.x, y: sQuartzY, width: s.frame.width, height: s.frame.height)
                    if sQuartzFrame.contains(pt) {
                        screen = s
                        break
                    }
                }
            }
        }
        let visibleFrame = screen.visibleFrame // Usable space excluding dock & menubar on target screen

        let targetFrameCocoa: CGRect
        let gap: CGFloat = 6.0

        switch direction {
        case .left:
            let w = (visibleFrame.width - gap) / 2
            targetFrameCocoa = CGRect(x: visibleFrame.minX, y: visibleFrame.minY, width: w, height: visibleFrame.height)

        case .right:
            let w = (visibleFrame.width - gap) / 2
            let x = visibleFrame.minX + w + gap
            targetFrameCocoa = CGRect(x: x, y: visibleFrame.minY, width: w, height: visibleFrame.height)

        case .top:
            let h = (visibleFrame.height - gap) / 2
            let y = visibleFrame.minY + h + gap
            targetFrameCocoa = CGRect(x: visibleFrame.minX, y: y, width: visibleFrame.width, height: h)

        case .bottom:
            let h = (visibleFrame.height - gap) / 2
            targetFrameCocoa = CGRect(x: visibleFrame.minX, y: visibleFrame.minY, width: visibleFrame.width, height: h)

        case .maximize:
            let allowThroughMenuBar = UserDefaults.standard.object(forKey: PrefKey.maximizeThroughMenuBar) as? Bool ?? false
            targetFrameCocoa = allowThroughMenuBar ? screen.frame : visibleFrame

        case .center:
            let w = min(visibleFrame.width * 0.92, 1600)
            let h = min(visibleFrame.height * 0.92, 1100)
            let x = visibleFrame.minX + (visibleFrame.width - w) / 2
            let y = visibleFrame.minY + (visibleFrame.height - h) / 2
            targetFrameCocoa = CGRect(x: x, y: y, width: w, height: h)
        }

        // Convert Cocoa coords (bottom-left) to Quartz/Accessibility coords (top-left)
        let quartzY = primaryHeight - targetFrameCocoa.maxY
        let quartzFrame = CGRect(x: targetFrameCocoa.origin.x, y: quartzY, width: targetFrameCocoa.width, height: targetFrameCocoa.height)

        HapticFeedback.heavy()
        setWindowFrame(element: winElem, frame: quartzFrame, pid: appPid)
        lastStatusMessage = "Snapped \(app.localizedName ?? "Window") \(direction.rawValue)"

        NotificationCenter.default.post(name: NSNotification.Name("NexusWindowSnapped"), object: direction.rawValue)
        return true
    }

    // MARK: - Maximize to Top Edge (Detected Usable Screen Area)
    public func maximizeFrontmostWindowToTopEdge(includeMenuBarArea: Bool = false) {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else { return }
        let pid = frontApp.processIdentifier
        let screens = NSScreen.screens
        let primaryHeight = screens.first?.frame.height ?? 1080
        guard let winElem = findWindowElement(pid: pid, fallbackFrame: nil) else { return }

        let mouseLoc = NSEvent.mouseLocation
        let screen = screens.first(where: { NSPointInRect(mouseLoc, $0.frame) }) ?? NSScreen.main ?? (screens.first ?? NSScreen())
        let targetFrameCocoa = includeMenuBarArea ? screen.frame : screen.visibleFrame

        let quartzY = primaryHeight - targetFrameCocoa.maxY
        let quartzFrame = CGRect(x: targetFrameCocoa.origin.x, y: quartzY, width: targetFrameCocoa.width, height: targetFrameCocoa.height)

        HapticFeedback.heavy()
        setWindowFrame(element: winElem, frame: quartzFrame, pid: pid)
        lastStatusMessage = "Maximized \(frontApp.localizedName ?? "Window") to Detected Screen Size"
    }

    // MARK: - Mission Control / Exposé Fallback
    public func triggerMissionControlFallback() {
        DispatchQueue.global(qos: .userInitiated).async {
            let src = CGEventSource(stateID: .combinedSessionState)
            // Control + Up Arrow (key code 126) triggers native Mission Control
            if let down = CGEvent(keyboardEventSource: src, virtualKey: 126, keyDown: true),
               let up = CGEvent(keyboardEventSource: src, virtualKey: 126, keyDown: false) {
                down.flags = .maskControl
                up.flags = .maskControl
                down.post(tap: .cghidEventTap)
                usleep(30_000)
                up.post(tap: .cghidEventTap)
            }
        }
    }

    // MARK: - Persistent Spatial Window Matrix & Self-Healing Coordinate Registry
    @Published public var savedAnchors: [String: SavedSpatialWindowAnchor] = [:]

    public func saveWindowAnchor(pid: pid_t, bundleID: String, title: String, screenIndex: Int, spaceIndex: Int, frame: CGRect, slotIndex: Int) {
        let screens = NSScreen.screens
        guard screenIndex - 1 < screens.count else { return }
        let screen = screens[screenIndex - 1]
        let vis = screen.visibleFrame
        guard vis.width > 0 && vis.height > 0 else { return }

        let normX = (frame.origin.x - vis.origin.x) / vis.width
        let normY = (frame.origin.y - vis.origin.y) / vis.height
        let normW = frame.width / vis.width
        let normH = frame.height / vis.height
        let normRect = CGRect(x: normX, y: normY, width: normW, height: normH)

        let anchor = SavedSpatialWindowAnchor(
            bundleID: bundleID,
            windowTitle: title,
            screenIndex: screenIndex,
            spaceIndex: spaceIndex,
            normalizedRect: normRect,
            gridSlotIndex: slotIndex,
            timestamp: Date()
        )
        savedAnchors[anchor.id] = anchor
        persistAnchorsToDisk()
    }

    public func persistAnchorsToDisk() {
        if let data = try? JSONEncoder().encode(savedAnchors) {
            UserDefaults.standard.set(data, forKey: PrefKey.persistentSpatialWindowAnchors)
        }
    }

    public func loadAnchorsFromDisk() {
        if let data = UserDefaults.standard.data(forKey: PrefKey.persistentSpatialWindowAnchors),
           let decoded = try? JSONDecoder().decode([String: SavedSpatialWindowAnchor].self, from: data) {
            self.savedAnchors = decoded
        }
    }

    public func restoreAllWindowAnchors() {
        loadAnchorsFromDisk()
        guard !savedAnchors.isEmpty else { return }

        let runningApps = NSWorkspace.shared.runningApplications.filter { $0.activationPolicy == .regular }
        let screens = NSScreen.screens
        let primaryHeight = screens.first?.frame.height ?? 1080

        for app in runningApps {
            guard let bid = app.bundleIdentifier else { continue }
            let pid = app.processIdentifier
            guard let winElem = findWindowElement(pid: pid, fallbackFrame: nil) else { continue }

            if let matchingAnchor = savedAnchors.values.first(where: { $0.bundleID == bid }) {
                let targetScreenIndex = min(screens.count, max(1, matchingAnchor.screenIndex)) - 1
                let screen = screens[targetScreenIndex]
                let vis = screen.visibleFrame
                let norm = matchingAnchor.normalizedRect

                let targetX = vis.origin.x + (norm.origin.x * vis.width)
                let targetY = vis.origin.y + (norm.origin.y * vis.height)
                let targetW = norm.width * vis.width
                let targetH = norm.height * vis.height
                let cocoaRect = CGRect(x: targetX, y: targetY, width: targetW, height: targetH)

                let quartzY = primaryHeight - cocoaRect.maxY
                let quartzFrame = CGRect(x: cocoaRect.origin.x, y: quartzY, width: cocoaRect.width, height: cocoaRect.height)

                setWindowFrame(element: winElem, frame: quartzFrame, pid: pid)
            }
        }
        lastStatusMessage = "Restored all windows to their exact spatial grid coordinates"
        HapticFeedback.success()
    }
}

// MARK: - Persistent Spatial Window Anchor Model
public struct SavedSpatialWindowAnchor: Codable, Identifiable {
    public var id: String { "\(bundleID):\(windowTitle):\(spaceIndex)" }
    public let bundleID: String
    public let windowTitle: String
    public let screenIndex: Int
    public let spaceIndex: Int
    public let normalizedRect: CGRect
    public let gridSlotIndex: Int
    public let timestamp: Date

    public init(bundleID: String, windowTitle: String, screenIndex: Int, spaceIndex: Int, normalizedRect: CGRect, gridSlotIndex: Int, timestamp: Date) {
        self.bundleID = bundleID
        self.windowTitle = windowTitle
        self.screenIndex = screenIndex
        self.spaceIndex = spaceIndex
        self.normalizedRect = normalizedRect
        self.gridSlotIndex = gridSlotIndex
        self.timestamp = timestamp
    }
}
