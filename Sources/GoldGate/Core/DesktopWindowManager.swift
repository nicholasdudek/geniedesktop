import AppKit
import SwiftUI

private func logDesktop(_ msg: String) {
    let line = "[GENIE_DESKTOP] \(Date()): \(msg)\n"
    fputs(line, stderr)
    fflush(stderr)
    if let data = line.data(using: .utf8),
       let stream = OutputStream(toFileAtPath: "/tmp/genie_desktop_debug.txt", append: true) {
        stream.open()
        _ = data.withUnsafeBytes { stream.write($0.bindMemory(to: UInt8.self).baseAddress!, maxLength: data.count) }
        stream.close()
    }
}

// MARK: - Desktop Plane Window

final class DesktopPlaneWindow: NSWindow {
    static func calculateUsableRect(for screen: NSScreen) -> NSRect {
        // Spans the full screen frame so wallpapers and full screen swipe gestures extend edge-to-edge under the translucent macOS menu bar without cutoff
        return screen.frame
    }

    init(screen: NSScreen) {
        let usableRect = DesktopPlaneWindow.calculateUsableRect(for: screen)
        super.init(
            contentRect: usableRect,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.level = NSWindow.Level(Int(CGWindowLevelForKey(.desktopIconWindow)) - 1)
        self.collectionBehavior = [
            .canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary
        ]
        self.isExcludedFromWindowsMenu = true
        self.sharingType = .readOnly
        self.hidesOnDeactivate = false
        self.ignoresMouseEvents = true
        self.acceptsMouseMovedEvents = true
    }

    override var canBecomeKey: Bool {
        return true
    }

    override var canBecomeMain: Bool {
        return true
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers?.lowercased() == "q" {
            NSApp.terminate(nil)
            return true
        }
        if event.keyCode == 53 { // Escape key
            NotificationCenter.default.post(name: NSNotification.Name("NexusClose"), object: nil)
            NotificationCenter.default.post(name: NSNotification.Name("NexusDismissDesktopGrid"), object: nil)
            DesktopWindowManager.shared.setPage(0)
            if SpatialPlaneManager.shared.isZoomedOut {
                SpatialPlaneManager.shared.zoomInToSelectedDesktop()
            }
            return true
        }
        if let mainMenu = NSApp.mainMenu, mainMenu.performKeyEquivalent(with: event) {
            return true
        }
        return super.performKeyEquivalent(with: event)
    }

    override func keyDown(with event: NSEvent) {
        if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers?.lowercased() == "q" {
            NSApp.terminate(nil)
            return
        }
        if event.keyCode == 53 { // Escape key
            NotificationCenter.default.post(name: NSNotification.Name("NexusClose"), object: nil)
            NotificationCenter.default.post(name: NSNotification.Name("NexusDismissDesktopGrid"), object: nil)
            DesktopWindowManager.shared.setPage(0)
            if SpatialPlaneManager.shared.isZoomedOut {
                SpatialPlaneManager.shared.zoomInToSelectedDesktop()
            }
            return
        }
        super.keyDown(with: event)
    }

    override func mouseDown(with event: NSEvent) {
        guard DesktopWindowManager.shared.currentPage == 1 else {
            super.mouseDown(with: event)
            return
        }
        NSApp.activate()
        self.makeKey()
        if !UserDefaults.standard.bool(forKey: PrefKey.isChatLockedInPlace) {
            NotificationCenter.default.post(name: NSNotification.Name("NexusClose"), object: nil)
        }
        super.mouseDown(with: event)
    }

    override func rightMouseDown(with event: NSEvent) {
        if !UserDefaults.standard.bool(forKey: PrefKey.isChatLockedInPlace) {
            NotificationCenter.default.post(name: NSNotification.Name("NexusClose"), object: nil)
        }
        super.rightMouseDown(with: event)
    }

    override func scrollWheel(with event: NSEvent) {
        // Handled centrally by localScrollMonitor to prevent duplicate notifications
        super.scrollWheel(with: event)
    }

    override func swipe(with event: NSEvent) {
        if event.deltaY != 0 {
            HapticFeedback.selection()
            NotificationCenter.default.post(name: NSNotification.Name("NexusThreeFingerDragVertical"), object: event.deltaY)
            DesktopWindowManager.shared.toggleStationBetweenDesktopAndApplications()
        } else if event.deltaX > 0 {
            NotificationCenter.default.post(name: NSNotification.Name("NexusThreeFingerDragRight"), object: nil)
        } else if event.deltaX < 0 {
            NotificationCenter.default.post(name: NSNotification.Name("NexusThreeFingerDragLeft"), object: nil)
        }
    }

    override func magnify(with event: NSEvent) {
        SpatialPlaneManager.shared.handleMagnification(delta: event.magnification)
        super.magnify(with: event)
    }
}

// MARK: - Workspace Station (Tri-State Switcher)

public enum WorkspaceStation: Int, CaseIterable {
    case desktop = 0
    case chat = 1
    case applications = 2

    public var title: String {
        switch self {
        case .desktop: return "Desktop Canvas"
        case .chat: return "Dialogue Studio (Chat)"
        case .applications: return "Application Atelier (Apps)"
        }
    }

    public var badgeLabel: String? {
        switch self {
        case .desktop: return nil
        case .chat: return "Chat"
        case .applications: return "Apps"
        }
    }

    public var systemImageName: String {
        switch self {
        case .desktop: return "macwindow"
        case .chat: return "bubble.left.and.bubble.right.fill"
        case .applications: return "square.grid.3x3.fill"
        }
    }

    public var nextStation: WorkspaceStation {
        switch self {
        case .desktop: return .chat
        case .chat: return .applications
        case .applications: return .desktop
        }
    }
}

// MARK: - Desktop Window Manager

@MainActor
final class DesktopWindowManager: ObservableObject {
    static let shared = DesktopWindowManager()

    public private(set) var desktopWindows: [DesktopPlaneWindow] = []
    private weak var appModel: AppModel?
    private var globalScrollMonitor: Any?
    private var localScrollMonitor: Any?
    private var swipeMonitor: Any?
    private var mouseClickMonitor: Any?
    private var flagsMonitor: Any?
    private var magnifyMonitor: Any?
    private var cursorPollingTimer: Timer?
    private var notificationObservers: [NSObjectProtocol] = []
    private var isAtBottomEdge: Bool = false
    private var isAtTopEdge: Bool = false
    private var isAtBottomRightCorner: Bool = false
    private var isAtTopRightCorner: Bool = false
    private var isAtBottomLeftCorner: Bool = false
    private var isAtTopLeftCorner: Bool = false
    private var isAtRightEdge: Bool = false
    private var dockHoverStartTime: TimeInterval = 0.0
    private var topHoverStartTime: TimeInterval = 0.0
    private var rightHoverStartTime: TimeInterval = 0.0
    private var hasBumpedRightEdge: Bool = false
    /// How far back from the edge the cursor is nudged when it hits the right-edge island.
    static let rightEdgeBumpDistance: CGFloat = 14.0
    @Published public var currentPage: Int = 1
    @Published public var currentStation: WorkspaceStation = .applications

    public func toggleStationBetweenDesktopAndApplications() {
        HapticFeedback.selection()
        if currentStation == .applications || (currentPage == 1 && UserDefaults.standard.integer(forKey: PrefKey.appDisplayStage) == 2) {
            switchToStation(.desktop)
        } else {
            switchToStation(.applications)
        }
    }

    public func cycleWorkspaceSwitcher() {
        let next = currentStation.nextStation
        switchToStation(next)
    }

    public func closeRightChatDock() {
        UserDefaults.standard.set(false, forKey: PrefKey.isRightChatDockOpen)
        UserDefaults.standard.set(false, forKey: PrefKey.isRightAppsDockOpen)
    }

    public func switchToStation(_ station: WorkspaceStation) {
        if station == .chat {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                UserDefaults.standard.set(true, forKey: PrefKey.isRightChatDockOpen)
                UserDefaults.standard.set(false, forKey: PrefKey.isRightAppsDockOpen)
            }
            return
        }
        closeRightChatDock()
        currentStation = station
        updateDockTile(for: station)

        switch station {
        case .desktop:
            NotificationCenter.default.post(name: NSNotification.Name("NexusSwitchToDesktopStation"), object: nil)
            setPage(0)
        case .chat:
            NotificationCenter.default.post(name: NSNotification.Name("NexusSwitchToChatStation"), object: nil)
            setPage(1)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                NotificationCenter.default.post(name: NSNotification.Name("NexusFocusGenieSearchBar"), object: nil)
            }
        case .applications:
            NotificationCenter.default.post(name: NSNotification.Name("NexusSwitchToAppsStation"), object: nil)
            setPage(1)
            UserDefaults.standard.set(2, forKey: PrefKey.appDisplayStage)
        }

        NotificationCenter.default.post(name: NSNotification.Name("NexusWorkspaceStationChanged"), object: station.rawValue)
    }

    public func syncCurrentStation(fromPage page: Int, appDisplayStage: AppDisplayStage, isTopSearchBarPoppedDown: Bool) {
        let station: WorkspaceStation
        if page == 1 && isTopSearchBarPoppedDown {
            station = .chat
        } else if page == 1 && appDisplayStage == .fullScreen {
            station = .applications
        } else {
            station = .desktop
        }
        if currentStation != station {
            currentStation = station
            updateDockTile(for: station)
            NotificationCenter.default.post(name: NSNotification.Name("NexusWorkspaceStationChanged"), object: station.rawValue)
        }
    }

    public func updateDockTile(for station: WorkspaceStation) {
        NSApp.dockTile.badgeLabel = station.badgeLabel
        NSApp.dockTile.display()
    }

    public func executeHotCornerAction(named action: String) {
        HapticFeedback.heavy()
        switch action {
        case "desktop_grid":
            break // Disabled: No applications pop up
        case "chat_bar":
            FinderChatWindowManager.shared.toggle()
        case "control_center":
            ControlCenterPopoverManager.shared.toggle()
        case "mission_control":
            MacDesktopsManager.postKeyComboDirect(keyCode: 126, flags: .maskControl)
        case "app_expose":
            MacDesktopsManager.postKeyComboDirect(keyCode: 125, flags: .maskControl)
        case "show_desktop":
            MacDesktopsManager.postKeyComboDirect(keyCode: 103, flags: [])
        case "lock_screen":
            MacDesktopsManager.postKeyComboDirect(keyCode: 12, flags: [.maskControl, .maskCommand])
        default:
            break
        }
    }

    var isEnabled: Bool {
        if UserDefaults.standard.object(forKey: PrefKey.desktopPlaneEnabled) == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: PrefKey.desktopPlaneEnabled)
    }

    func setPage(_ page: Int) {
        self.currentPage = page
        if desktopWindows.isEmpty, let model = self.appModel {
            if !isEnabled {
                UserDefaults.standard.set(true, forKey: PrefKey.desktopPlaneEnabled)
            }
            rebuildWindows(appModel: model)
        }
        updateWindowsForPage(page)
        NotificationCenter.default.post(name: NSNotification.Name("NexusDesktopPageChanged"), object: page)
    }

    func togglePage() {
        let nextPage = (currentPage == 1) ? 0 : 1
        setPage(nextPage)
    }

    public func updateWindowsForPage(_ page: Int) {
        for win in self.desktopWindows {
            if page == 1 {
                // Summoned: Elevate window above open applications and activate for note input
                win.level = .floating
                win.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
                win.isExcludedFromWindowsMenu = true
                win.sharingType = .readOnly
                win.ignoresMouseEvents = false
            } else {
                // Dismissed: Keep at desktop plane level below icons with gestures fully active and mouse events passing to macOS Desktop
                win.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
                win.isExcludedFromWindowsMenu = true
                win.sharingType = .readOnly
                win.ignoresMouseEvents = true
                win.resignKey()
                let desktopLevel = NSWindow.Level(Int(CGWindowLevelForKey(.desktopIconWindow)) - 1)
                win.level = desktopLevel
                win.orderFrontRegardless()
            }
        }
        updateDesktopClickThrough()
        if page == 1 {
            NSApp.activate()
            let mouseLoc = NSEvent.mouseLocation
            let activeScreen = NSScreen.screens.first(where: { NSMouseInRect(mouseLoc, $0.frame, false) }) ?? NSScreen.main ?? NSScreen.screens.first
            for win in self.desktopWindows {
                win.orderFront(nil)
            }
            if CustomMenuBarManager.shared.isEnabled {
                for mbWin in CustomMenuBarManager.shared.menuBarWindows {
                    mbWin.orderFrontRegardless()
                }
            }
            if let targetWin = self.desktopWindows.first(where: { $0.screen == activeScreen }) ?? self.desktopWindows.first {
                targetWin.makeKeyAndOrderFront(nil)
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
                guard let self = self, self.currentPage == 1 else { return }
                NSApplication.shared.activate(ignoringOtherApps: true)
                let currentMouseLoc = NSEvent.mouseLocation
                let curScreen = NSScreen.screens.first(where: { NSMouseInRect(currentMouseLoc, $0.frame, false) }) ?? NSScreen.main ?? NSScreen.screens.first
                for win in self.desktopWindows {
                    win.orderFront(nil)
                }
                if CustomMenuBarManager.shared.isEnabled {
                    for mbWin in CustomMenuBarManager.shared.menuBarWindows {
                        mbWin.orderFrontRegardless()
                    }
                }
                if let targetWin = self.desktopWindows.first(where: { $0.screen == curScreen }) ?? self.desktopWindows.first {
                    targetWin.makeKeyAndOrderFront(nil)
                }
                NotificationCenter.default.post(name: NSNotification.Name("NexusFocusGenieSearchBar"), object: nil)
            }
        }
    }

    func setup(appModel: AppModel) {
        logDesktop("setup(appModel:) called")
        self.appModel = appModel
        cleanup()

        rebuildWindows(appModel: appModel)
        SpatialPlaneManager.shared.setup()

        let o1 = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.rebuildWindows(appModel: appModel)
            }
        }
        notificationObservers.append(o1)

        let o2 = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self = self, self.currentPage != 0 else { return }
                let alwaysOn = UserDefaults.standard.bool(forKey: PrefKey.alwaysOnDesktop)
                let pinned = UserDefaults.standard.bool(forKey: PrefKey.pinToDesktopEnabled)
                guard !alwaysOn && !pinned else { return }
                self.setPage(0)
            }
        }
        notificationObservers.append(o2)

        let o3 = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notif in
            MainActor.assumeIsolated {
                guard let self = self else { return }
                if let activatedApp = notif.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
                   activatedApp.bundleIdentifier != Bundle.main.bundleIdentifier {
                    let alwaysOn = UserDefaults.standard.bool(forKey: PrefKey.alwaysOnDesktop)
                    let pinned = UserDefaults.standard.bool(forKey: PrefKey.pinToDesktopEnabled)
                    if !alwaysOn && !pinned && self.currentPage == 1 {
                        self.setPage(0)
                    }
                    self.closeRightChatDock()
                    FinderChatWindowManager.shared.hide()
                }
            }
        }
        notificationObservers.append(o3)

        let o4 = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NexusDesktopPlaneToggled"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.rebuildWindows(appModel: appModel)
            }
        }
        notificationObservers.append(o4)

        let o5 = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NexusToggleDesktopGrid"),
            object: nil,
            queue: .main
        ) { _ in
            MainActor.assumeIsolated {
                FinderChatWindowManager.shared.toggle()
            }
        }
        notificationObservers.append(o5)

        let o6 = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NexusDismissDesktopGrid"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self = self, self.currentPage != 0 else { return }
                let alwaysOn = UserDefaults.standard.bool(forKey: PrefKey.alwaysOnDesktop)
                let pinned = UserDefaults.standard.bool(forKey: PrefKey.pinToDesktopEnabled)
                guard !alwaysOn && !pinned else { return }
                self.setPage(0)
            }
        }
        notificationObservers.append(o6)

        let o6b = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NexusClose"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                guard let self = self, self.currentPage != 0 else { return }
                let alwaysOn = UserDefaults.standard.bool(forKey: PrefKey.alwaysOnDesktop)
                let pinned = UserDefaults.standard.bool(forKey: PrefKey.pinToDesktopEnabled)
                guard !alwaysOn && !pinned else { return }
                self.setPage(0)
            }
        }
        notificationObservers.append(o6b)

        let o7 = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NexusDesktopPageChanged"),
            object: nil,
            queue: .main
        ) { [weak self] notif in
            MainActor.assumeIsolated {
                guard let self = self, let page = notif.object as? Int else { return }
                if self.currentPage != page {
                    self.currentPage = page
                    self.updateWindowsForPage(page)
                }
            }
        }
        notificationObservers.append(o7)

        let o8 = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NexusDesktopFilesToggled"),
            object: nil,
            queue: .main
        ) { [weak self] notif in
            MainActor.assumeIsolated {
                guard let self = self else { return }
                self.updateWindowsForPage(self.currentPage)
            }
        }
        notificationObservers.append(o8)

        // Distributed notifications for automation scripts & video capture
        let o9 = DistributedNotificationCenter.default().addObserver(
            forName: NSNotification.Name("NexusSetDesktopPage"),
            object: nil,
            queue: .main
        ) { [weak self] notif in
            let pageInt: Int
            if let intVal = notif.object as? Int {
                pageInt = intVal
            } else if let strVal = notif.object as? String, let intVal = Int(strVal) {
                pageInt = intVal
            } else {
                pageInt = 1
            }
            self?.setPage(pageInt)
            NotificationCenter.default.post(name: NSNotification.Name("NexusSetDesktopPage"), object: pageInt)
        }
        notificationObservers.append(o9)

        let o10 = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NexusAlwaysOnDesktopToggled"),
            object: nil,
            queue: .main
        ) { [weak self] notif in
            MainActor.assumeIsolated {
                guard let self = self else { return }
                self.updateWindowsForPage(self.currentPage)
            }
        }
        notificationObservers.append(o10)

        // Global Bottom-Middle (Summon) & Top-Middle (Dismiss) Hardware Cursor Detection
        if cursorPollingTimer == nil {
            cursorPollingTimer = Timer.scheduledTimer(withTimeInterval: 0.04, repeats: true) { [weak self] _ in
                MainActor.assumeIsolated {
                    guard let self = self, self.isEnabled else { return }

                    let brEnabled = UserDefaults.standard.bool(forKey: PrefKey.bottomRightHotCorner)
                    let trEnabled = UserDefaults.standard.bool(forKey: PrefKey.topRightHotCorner)
                    let tlEnabled = UserDefaults.standard.bool(forKey: PrefKey.topLeftHotCorner)
                    let blEnabled = UserDefaults.standard.bool(forKey: PrefKey.bottomLeftHotCorner)
                    let bottomEdgeEnabled = UserDefaults.standard.bool(forKey: PrefKey.bottomEdgeCursorTrigger)
                    let topEdgeEnabled = UserDefaults.standard.object(forKey: PrefKey.topEdgeCursorTrigger) as? Bool ?? false
                    let rightEdgeEnabled = UserDefaults.standard.bool(forKey: PrefKey.rightEdgeCursorTrigger)

                    guard brEnabled || trEnabled || tlEnabled || blEnabled || bottomEdgeEnabled || topEdgeEnabled || rightEdgeEnabled else {
                        return
                    }

                    let mouseLoc = NSEvent.mouseLocation
                    guard let screen = NSScreen.screens.first(where: { $0.frame.contains(mouseLoc) }) ?? NSScreen.main else { return }

                    // ═══════════════════════════════════════════════════════════════════════════════════════
                    // SECTION A: 4-Corner Hardware Hot Corners (Global - Active Across All Apps & Spaces)
                    // ═══════════════════════════════════════════════════════════════════════════════════════
                    let cornerTriggerThreshold: CGFloat = 12.0
                    let cornerExitThreshold: CGFloat = 45.0

                    // 1. Bottom-Right Hot Corner
                    if brEnabled {
                        let brAction = UserDefaults.standard.string(forKey: PrefKey.hotCornerBottomRightAction) ?? "none"
                        if brAction != "none" {
                            let inBR = mouseLoc.x >= screen.frame.maxX - cornerTriggerThreshold && mouseLoc.y <= screen.frame.minY + cornerTriggerThreshold
                            if inBR {
                                if !self.isAtBottomRightCorner {
                                    self.isAtBottomRightCorner = true
                                    self.executeHotCornerAction(named: brAction)
                                }
                            } else if mouseLoc.x < screen.frame.maxX - cornerExitThreshold || mouseLoc.y > screen.frame.minY + cornerExitThreshold {
                                self.isAtBottomRightCorner = false
                            }
                        }
                    }

                    // 2. Top-Right Hot Corner
                    if trEnabled {
                        let trAction = UserDefaults.standard.string(forKey: PrefKey.hotCornerTopRightAction) ?? "chat_bar"
                        if trAction != "none" {
                            let inTR = mouseLoc.x >= screen.frame.maxX - cornerTriggerThreshold && mouseLoc.y >= screen.frame.maxY - cornerTriggerThreshold
                            if inTR {
                                if !self.isAtTopRightCorner {
                                    self.isAtTopRightCorner = true
                                    self.executeHotCornerAction(named: trAction)
                                }
                            } else if mouseLoc.x < screen.frame.maxX - cornerExitThreshold || mouseLoc.y < screen.frame.maxY - cornerExitThreshold {
                                self.isAtTopRightCorner = false
                            }
                        }
                    }

                    // 3. Top-Left Hot Corner
                    if tlEnabled {
                        let tlAction = UserDefaults.standard.string(forKey: PrefKey.hotCornerTopLeftAction) ?? "none"
                        if tlAction != "none" {
                            let inTL = mouseLoc.x <= screen.frame.minX + cornerTriggerThreshold && mouseLoc.y >= screen.frame.maxY - cornerTriggerThreshold
                            if inTL {
                                if !self.isAtTopLeftCorner {
                                    self.isAtTopLeftCorner = true
                                    self.executeHotCornerAction(named: tlAction)
                                }
                            } else if mouseLoc.x > screen.frame.minX + cornerExitThreshold || mouseLoc.y < screen.frame.maxY - cornerExitThreshold {
                                self.isAtTopLeftCorner = false
                            }
                        }
                    }

                    // 4. Bottom-Left Hot Corner
                    if blEnabled {
                        let blAction = UserDefaults.standard.string(forKey: PrefKey.hotCornerBottomLeftAction) ?? "none"
                        if blAction != "none" {
                            let inBL = mouseLoc.x <= screen.frame.minX + cornerTriggerThreshold && mouseLoc.y <= screen.frame.minY + cornerTriggerThreshold
                            if inBL {
                                if !self.isAtBottomLeftCorner {
                                    self.isAtBottomLeftCorner = true
                                    self.executeHotCornerAction(named: blAction)
                                }
                            } else if mouseLoc.x > screen.frame.minX + cornerExitThreshold || mouseLoc.y > screen.frame.minY + cornerExitThreshold {
                                self.isAtBottomLeftCorner = false
                            }
                        }
                    }

                    // ═══════════════════════════════════════════════════════════════════════════════════════
                    // SECTION B: Screen Edge Latches (Global Bottom, Top, and Right Summoning)
                    // ═══════════════════════════════════════════════════════════════════════════════════════
                    let rightEdgeBumpEnabled = UserDefaults.standard.object(forKey: PrefKey.rightEdgeBumpEnabled) as? Bool ?? true

                    guard bottomEdgeEnabled || topEdgeEnabled || rightEdgeEnabled else {
                        self.isAtBottomEdge = false
                        self.isAtTopEdge = false
                        self.isAtRightEdge = false
                        self.dockHoverStartTime = 0.0
                        self.topHoverStartTime = 0.0
                        return
                    }

                    let midX = screen.frame.midX
                    let centerHalfWidth = screen.frame.width * 0.38
                    let isHorizontallyCentered = abs(mouseLoc.x - midX) <= centerHalfWidth

                    // 1. Bottom Edge Latch (Brings Mini Dock / Applications Canvas)
                    if bottomEdgeEnabled && isHorizontallyCentered {
                        let isNearBottom = mouseLoc.y <= screen.frame.minY + 4
                        if isNearBottom {
                            if self.dockHoverStartTime == 0.0 {
                                self.dockHoverStartTime = ProcessInfo.processInfo.systemUptime
                            } else if ProcessInfo.processInfo.systemUptime - self.dockHoverStartTime >= 0.20 {
                                if !self.isAtBottomEdge {
                                    self.isAtBottomEdge = true
                                    NotificationCenter.default.post(name: NSNotification.Name("NexusBottomEdgeHit"), object: nil)
                                }
                            }
                        } else if mouseLoc.y > screen.frame.minY + 30 {
                            self.isAtBottomEdge = false
                            self.dockHoverStartTime = 0.0
                        }
                    } else {
                        self.isAtBottomEdge = false
                        self.dockHoverStartTime = 0.0
                    }

                    // 2. Top Edge Latch (Brings Chat with Wallpaper)
                    if topEdgeEnabled && isHorizontallyCentered && !CustomMenuBarManager.shared.isEnabled {
                        let isNearTop = mouseLoc.y >= screen.frame.maxY - 4
                        if isNearTop {
                            if self.topHoverStartTime == 0.0 {
                                self.topHoverStartTime = ProcessInfo.processInfo.systemUptime
                            } else if ProcessInfo.processInfo.systemUptime - self.topHoverStartTime >= 0.20 {
                                if !self.isAtTopEdge {
                                    self.isAtTopEdge = true
                                    NotificationCenter.default.post(name: NSNotification.Name("NexusTopEdgeHit"), object: nil)
                                }
                            }
                        } else if mouseLoc.y < screen.frame.maxY - 30 {
                            self.isAtTopEdge = false
                            self.topHoverStartTime = 0.0
                        }
                    } else {
                        self.isAtTopEdge = false
                        self.topHoverStartTime = 0.0
                    }

                    // 3. Right Edge Latch (Brings out the Chat Dock — cursor buoy)
                    // The edge behaves like a physical island: the first time the cursor reaches it,
                    // it gets nudged back a few points so you feel a bump and have to push through
                    // (or go around it) rather than the dock firing off an accidental brush.
                    if rightEdgeEnabled {
                        let isNearRight = mouseLoc.x >= screen.frame.maxX - 4 && mouseLoc.y >= screen.frame.minY + 50 && mouseLoc.y <= screen.frame.maxY - 50
                        if isNearRight {
                            if self.rightHoverStartTime == 0.0 {
                                self.rightHoverStartTime = ProcessInfo.processInfo.systemUptime
                                if rightEdgeBumpEnabled && !self.hasBumpedRightEdge {
                                    self.hasBumpedRightEdge = true
                                    let bumpX = screen.frame.maxX - Self.rightEdgeBumpDistance
                                    CGWarpMouseCursorPosition(
                                        CGPoint(x: bumpX, y: (NSScreen.screens.first?.frame.maxY ?? screen.frame.maxY) - mouseLoc.y)
                                    )
                                    CGAssociateMouseAndMouseCursorPosition(1)
                                    HapticFeedback.heavy()
                                }
                            } else if ProcessInfo.processInfo.systemUptime - self.rightHoverStartTime >= 0.20 {
                                if !self.isAtRightEdge {
                                    self.isAtRightEdge = true
                                    NotificationCenter.default.post(name: NSNotification.Name("NexusToggleRightChatDock"), object: nil)
                                }
                            }
                        } else if mouseLoc.x < screen.frame.maxX - 35 {
                            self.isAtRightEdge = false
                            self.rightHoverStartTime = 0.0
                            self.hasBumpedRightEdge = false
                        }
                    }
                }
            }
        }

        // Global Scroll / Two-Finger Trackpad Swipe Monitor
        if globalScrollMonitor == nil {
            globalScrollMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.scrollWheel]) { [weak self] event in
                Task { @MainActor [weak self] in
                    guard let self = self, self.isEnabled else { return }
                    let pointer = NSEvent.mouseLocation
                    let onRightDock = NSScreen.screens.contains { screen in
                        pointer.x >= screen.frame.maxX - 150 && pointer.y >= screen.frame.minY + 40 && pointer.y <= screen.frame.maxY - 40
                    }
                    if onRightDock {
                        NotificationCenter.default.post(name: NSNotification.Name("NexusRightDockScrollWheel"), object: CGFloat(event.scrollingDeltaY))
                    }
                    guard event.momentumPhase.isEmpty else { return }

                    // Strict Active Application Isolation:
                    // If another application window is directly under the cursor, never intercept or forward scroll wheel events.
                    if self.currentPage == 1 || self.isOverDesktopOrEmptySpace() {
                        NotificationCenter.default.post(name: NSNotification.Name("NexusDesktopScrollWheel"), object: event)
                    }
                }
            }
        }

        if localScrollMonitor == nil {
            localScrollMonitor = NSEvent.addLocalMonitorForEvents(matching: [.scrollWheel]) { [weak self] event in
                guard let self = self, self.isEnabled else { return event }
                let pointer = NSEvent.mouseLocation
                let onRightDock = NSScreen.screens.contains { screen in
                    pointer.x >= screen.frame.maxX - 150 && pointer.y >= screen.frame.minY + 40 && pointer.y <= screen.frame.maxY - 40
                }
                if onRightDock {
                    NotificationCenter.default.post(name: NSNotification.Name("NexusRightDockScrollWheel"), object: CGFloat(event.scrollingDeltaY))
                }
                guard event.momentumPhase.isEmpty else { return event }
                NotificationCenter.default.post(name: NSNotification.Name("NexusDesktopScrollWheel"), object: event)
                return event
            }
        }

        // Mouse middle/back buttons on empty desktop
        if mouseClickMonitor == nil {
            mouseClickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.otherMouseDown]) { [weak self] event in
                Task { @MainActor [weak self] in
                    guard let self = self, self.isEnabled else { return }

                    let frontApp = NSWorkspace.shared.frontmostApplication
                    let frontBundle = frontApp?.bundleIdentifier
                    let isFrontAppSystemOrGenie = (frontBundle == "com.apple.finder" || frontBundle == Bundle.main.bundleIdentifier || frontApp == nil)

                    guard isFrontAppSystemOrGenie && self.isOverDesktopOrEmptySpace() else { return }

                    if event.buttonNumber == 2 || event.buttonNumber == 3 || event.buttonNumber == 4 {
                        NotificationCenter.default.post(name: NSNotification.Name("NexusToggleDesktopGrid"), object: nil)
                    }
                }
            }
        }


        // Double-Tap Control or Option Key Quick Summon
        if flagsMonitor == nil {
            flagsMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { event in
                let doubleControlEnabled = UserDefaults.standard.bool(forKey: PrefKey.doubleControlTrigger)
                let doubleOptionEnabled = UserDefaults.standard.bool(forKey: PrefKey.doubleOptionTrigger)

                let isControl = doubleControlEnabled && event.modifierFlags.contains(.control)
                let isOption = doubleOptionEnabled && event.modifierFlags.contains(.option)

                if isControl || isOption {
                    let keyType = isControl ? "control" : "option"
                    let now = ProcessInfo.processInfo.systemUptime
                    let last = UserDefaults.standard.double(forKey: "nexus.last\(keyType)TapTime")
                    if now - last < 0.35 && now - last > 0.05 {
                        UserDefaults.standard.set(0.0, forKey: "nexus.last\(keyType)TapTime")
                        NotificationCenter.default.post(name: NSNotification.Name("NexusToggleDesktopGrid"), object: nil)
                    } else {
                        UserDefaults.standard.set(now, forKey: "nexus.last\(keyType)TapTime")
                    }
                }
            }
        }
        // Global Trackpad Pinch-to-Zoom / Magnification Monitor
        if magnifyMonitor == nil {
            magnifyMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.magnify]) { event in
                Task { @MainActor in
                    SpatialPlaneManager.shared.handleMagnification(delta: event.magnification)
                    NotificationCenter.default.post(name: NSNotification.Name("NexusSpatialMagnify"), object: event.magnification)
                }
            }
        }

        // 3-Finger Trackpad Swipe Monitor (Desktop <-> Applications Cycle)
        if swipeMonitor == nil {
            swipeMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.swipe]) { [weak self] event in
                Task { @MainActor [weak self] in
                    guard let self = self, self.isEnabled else { return }
                    if event.deltaY != 0 {
                        self.toggleStationBetweenDesktopAndApplications()
                    }
                }
            }
        }
    }

    public func cleanup() {
        for obs in notificationObservers {
            NotificationCenter.default.removeObserver(obs)
            NSWorkspace.shared.notificationCenter.removeObserver(obs)
            DistributedNotificationCenter.default().removeObserver(obs)
        }
        notificationObservers.removeAll()

        if let m = mouseClickMonitor { NSEvent.removeMonitor(m); mouseClickMonitor = nil }
        if let g = globalScrollMonitor { NSEvent.removeMonitor(g); globalScrollMonitor = nil }
        if let l = localScrollMonitor { NSEvent.removeMonitor(l); localScrollMonitor = nil }
        if let s = swipeMonitor { NSEvent.removeMonitor(s); swipeMonitor = nil }
        if let f = flagsMonitor { NSEvent.removeMonitor(f); flagsMonitor = nil }
        if let mag = magnifyMonitor { NSEvent.removeMonitor(mag); magnifyMonitor = nil }
        cursorPollingTimer?.invalidate()
        cursorPollingTimer = nil
    }

    /// Claims mouse events only where the plane actually has something to click.
    ///
    /// While the plane is presenting (page 1) it owns the screen. While it is dismissed the
    /// window is invisible but still covers the display, so anything the hosting view does not
    /// hit-test has to fall through to whatever is underneath, normally the Finder desktop.
    public func updateDesktopClickThrough() {
        for win in desktopWindows {
            if currentPage == 0 {
                if !win.ignoresMouseEvents { win.ignoresMouseEvents = true }
            } else {
                if win.ignoresMouseEvents { win.ignoresMouseEvents = false }
            }
        }
    }

    func isOverDesktopOrEmptySpace() -> Bool {
        if self.currentPage == 1 {
            return true
        }
        // 1. If frontmost app is Finder (Desktop) or Genie, we are on the desktop!
        let frontApp = NSWorkspace.shared.frontmostApplication
        let frontBundle = frontApp?.bundleIdentifier
        if frontBundle == "com.apple.finder" || frontBundle == Bundle.main.bundleIdentifier || frontApp == nil {
            return true
        }

        // 2. Check if mouse is directly hovering over an active visible application window
        let mouseLoc = NSEvent.mouseLocation
        guard let winList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
            return true
        }

        let mainPid = ProcessInfo.processInfo.processIdentifier
        let primaryHeight = (NSScreen.screens.first ?? NSScreen.main)?.frame.height ?? 1080
        for winInfo in winList {
            guard let layer = winInfo[kCGWindowLayer as String] as? Int, layer == 0,
                  let ownerPid = winInfo[kCGWindowOwnerPID as String] as? pid_t,
                  ownerPid != mainPid else { continue }

            if let boundsDict = winInfo[kCGWindowBounds as String] as? [String: Any],
               let winBounds = CGRect(dictionaryRepresentation: boundsDict as CFDictionary) {
                if winBounds.width > 60 && winBounds.height > 60 {
                    let cocoaY = primaryHeight - winBounds.origin.y - winBounds.height
                    let winRect = CGRect(x: winBounds.origin.x, y: cocoaY, width: winBounds.width, height: winBounds.height)
                    if winRect.contains(mouseLoc) {
                        return false // Mouse is inside an active application window
                    }
                }
            }
        }

        return true
    }

    // MARK: - ⌨️ Type-To-Activate System
    public static func isTextInputFieldActive() -> Bool {
        guard let keyWin = NSApplication.shared.keyWindow else { return false }
        if let fr = keyWin.firstResponder {
            if (fr is NSTextView) || (fr is NSTextField) || (fr is NSSearchField) {
                return true
            }
        }
        return false
    }

    public func isFinderDesktopOnly() -> Bool {
        guard let front = NSWorkspace.shared.frontmostApplication,
              front.bundleIdentifier == "com.apple.finder" else {
            return false
        }
        guard let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
            return true
        }
        for win in windowList {
            if let ownerPID = win[kCGWindowOwnerPID as String] as? pid_t,
               ownerPID == front.processIdentifier,
               let layer = win[kCGWindowLayer as String] as? Int,
               layer == 0 {
                if let bounds = win[kCGWindowBounds as String] as? [String: Any],
                   let w = bounds["Width"] as? CGFloat,
                   let h = bounds["Height"] as? CGFloat,
                   w > 100 && h > 100 {
                    return false
                }
            }
        }
        return true
    }

    public func startTypingWithInitialCharacter(_ chars: String) {
        NSApplication.shared.activate(ignoringOtherApps: true)

        if self.currentPage != 1 {
            self.setPage(1)
        } else {
            self.updateWindowsForPage(1)
        }

        NotificationCenter.default.post(name: NSNotification.Name("NexusRevealSearchBarForTyping"), object: nil)
        NotificationCenter.default.post(name: NSNotification.Name("NexusSearchBarAppendText"), object: chars)
        NotificationCenter.default.post(name: NSNotification.Name("NexusFocusGenieSearchBar"), object: nil)
        HapticFeedback.playTypingSound()
    }

    func rebuildWindows(appModel: AppModel) {
        // Close existing
        for win in desktopWindows {
            win.orderOut(nil)
        }
        desktopWindows.removeAll()

        let enabled = isEnabled
        let raw = String(describing: UserDefaults.standard.object(forKey: PrefKey.desktopPlaneEnabled))
        logDesktop("rebuildWindows called. isEnabled=\(enabled), rawObj=\(raw), screens=\(NSScreen.screens.count)")
        guard enabled else { return }

        for screen in NSScreen.screens {
            let win = DesktopPlaneWindow(screen: screen)
            let hosting = NexusHostingView(
                rootView: DesktopGridView(appModel: appModel, screen: screen)
            )
            let usableRect = DesktopPlaneWindow.calculateUsableRect(for: screen)
            win.setFrame(usableRect, display: true)
            win.contentView = hosting
            // Highest resolution Retina XDR max screen size
            win.contentView?.wantsLayer = true
            win.contentView?.layer?.contentsScale = screen.backingScaleFactor
            win.contentView?.layer?.rasterizationScale = screen.backingScaleFactor

            // Keep at desktop plane level below icons so desktop clicks hit Finder/Desktop
            let desktopLevel = NSWindow.Level(Int(CGWindowLevelForKey(.desktopIconWindow)) - 1)
            win.level = desktopLevel
            win.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle, .fullScreenAuxiliary]
            win.isExcludedFromWindowsMenu = true
            win.sharingType = .readOnly
            win.ignoresMouseEvents = true
            win.orderFrontRegardless()
            desktopWindows.append(win)
            logDesktop("window created: win=\(win.windowNumber), frame=\(win.frame), level=\(win.level.rawValue)")
        }
        updateWindowsForPage(currentPage)
    }

    func toggleVisibility() {
        let current = isEnabled
        UserDefaults.standard.set(!current, forKey: PrefKey.desktopPlaneEnabled)
        if current {
            cursorPollingTimer?.invalidate()
            cursorPollingTimer = nil
        }
        NotificationCenter.default.post(name: NSNotification.Name("NexusDesktopPlaneToggled"), object: nil)
    }

    deinit {
        for obs in notificationObservers {
            NotificationCenter.default.removeObserver(obs)
            NSWorkspace.shared.notificationCenter.removeObserver(obs)
            DistributedNotificationCenter.default().removeObserver(obs)
        }
        notificationObservers.removeAll()
        if let m = mouseClickMonitor { NSEvent.removeMonitor(m) }
        if let g = globalScrollMonitor { NSEvent.removeMonitor(g) }
        if let l = localScrollMonitor { NSEvent.removeMonitor(l) }
        if let f = flagsMonitor { NSEvent.removeMonitor(f) }
        cursorPollingTimer?.invalidate()
    }
}
