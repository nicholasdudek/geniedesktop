import AppKit
import SwiftUI

// MARK: - 📐 Finder Chat Window Size & Snap Presets
public enum FinderWindowSizePreset: String, CaseIterable, Identifiable {
    case topPanel = "Top Panel (Consolidated Notch ⛶)"
    case standard = "Standard (960×680)"
    case rightHalf = "Right Half (50% Split ◨)"
    case leftHalf = "Left Half (50% Split ◧)"
    case thirdsMode = "Thirds Mode (Editor | Viewer | Chat ⚏)"
    case verticalTop = "Vertical Top (Full Height ↕️)"
    case mostScreen = "Most Screen (88% ⛶)"
    case fullScreen = "Full Screen (100% ⤢)"

    public var id: String { rawValue }

    public var shortTitle: String {
        switch self {
        case .topPanel: return "Top Panel ⛶"
        case .standard: return "Standard"
        case .rightHalf: return "Right Half ◨"
        case .leftHalf: return "Left Half ◧"
        case .thirdsMode: return "Thirds ⚏"
        case .verticalTop: return "Vertical ↕️"
        case .mostScreen: return "Most Screen ⛶"
        case .fullScreen: return "Full Screen ⤢"
        }
    }

    public var icon: String {
        switch self {
        case .topPanel: return "menubar.dock.rectangle"
        case .standard: return "rectangle.center.inset.filled"
        case .rightHalf: return "rectangle.righthalf.filled"
        case .leftHalf: return "rectangle.lefthalf.filled"
        case .thirdsMode: return "rectangle.split.3x1"
        case .verticalTop: return "arrow.up.and.down.square.fill"
        case .mostScreen: return "rectangle.inset.filled"
        case .fullScreen: return "arrow.up.left.and.arrow.down.right.square.fill"
        }
    }
}

public struct FinderWindowTab: Hashable, Equatable, Identifiable {
    public enum TabKind: Hashable, Equatable {
        case chat
        case editor
        case files
        case terminal
        case browser
        case notes
        case settings
        case applications
        case soundAndEffects
        case models
        case virtualMachines
        case github
        case notchAndMenuBar
        case app(bundleId: String, name: String)
    }

    /// Legacy tab enum for backwards compatibility with external tools and regression tests
    public enum LegacyTab: String {
        case files = "Files"
    }

    public let id: String
    public var kind: TabKind
    public var title: String
    public var customURL: URL?
    public var sessionId: UUID?

    public init(
        id: String = UUID().uuidString,
        kind: TabKind,
        title: String? = nil,
        customURL: URL? = nil,
        sessionId: UUID? = nil
    ) {
        self.id = id
        self.kind = kind
        self.customURL = customURL
        self.sessionId = sessionId
        if let title = title {
            self.title = title
        } else {
            switch kind {
            case .chat: self.title = "Genie Chat"
            case .editor: self.title = "Editor & Preview"
            case .files: self.title = "Files"
            case .terminal: self.title = "Terminal"
            case .browser: self.title = "Browser"
            case .notes: self.title = "Notes"
            case .settings: self.title = "Settings"
            case .applications: self.title = "Applications"
            case .soundAndEffects: self.title = "Sound & Effects"
            case .models: self.title = "Models & Providers"
            case .virtualMachines: self.title = "AI Stations"
            case .github: self.title = "GitHub Studio 🐙"
            case .notchAndMenuBar: self.title = "Top Notch & Menu Bar"
            case .app(_, let name): self.title = (name.contains("VS Code") ? "VS Code Insiders" : name)
            }
        }
    }

    public var icon: String {
        switch kind {
        case .chat: return "bubble.left.and.bubble.right.fill"
        case .editor: return "chevron.left.forwardslash.chevron.right"
        case .files: return "folder.fill"
        case .terminal: return "terminal.fill"
        case .browser: return "globe"
        case .notes: return "doc.text.fill"
        case .settings: return "gearshape.fill"
        case .applications: return "square.grid.2x2.fill"
        case .soundAndEffects: return "speaker.wave.2.fill"
        case .models: return "brain.head.profile"
        case .virtualMachines: return "server.rack"
        case .github: return "arrow.triangle.branch"
        case .notchAndMenuBar: return "laptopcomputer.and.ipad"
        case .app: return "app.window.checkmark"
        }
    }

    public var isBuiltIn: Bool {
        switch kind {
        case .app: return false
        default: return true
        }
    }

    // Static presets for easy matching and backward compatibility
    public static let editor = FinderWindowTab(id: "editor-default", kind: .editor, title: "Editor & Preview")
    public static let applications = FinderWindowTab(id: "apps-default", kind: .applications, title: "Applications")
    public static let chat = FinderWindowTab(id: "chat-default", kind: .chat, title: "Genie Chat")
    public static let files = FinderWindowTab(id: "files-default", kind: .files, title: "Files")
    public static let terminal = FinderWindowTab(id: "terminal-default", kind: .terminal, title: "Terminal")
    public static let browser = FinderWindowTab(id: "browser-default", kind: .browser, title: "Browser")
    public static let notes = FinderWindowTab(id: "notes-default", kind: .notes, title: "Notes")
    public static let settings = FinderWindowTab(id: "settings-default", kind: .settings, title: "Settings")
    public static let soundAndEffects = FinderWindowTab(id: "sound-default", kind: .soundAndEffects, title: "Sound & Effects")
    public static let models = FinderWindowTab(id: "models-default", kind: .models, title: "Models & Providers")
    public static let virtualMachines = FinderWindowTab(id: "vms-default", kind: .virtualMachines, title: "AI Stations")
    public static let github = FinderWindowTab(id: "github-default", kind: .github, title: "GitHub Studio 🐙")
    public static let notchAndMenuBar = FinderWindowTab(id: "notch-default", kind: .notchAndMenuBar, title: "Top Notch & Menu Bar")

    public static func app(bundleId: String, name: String) -> FinderWindowTab {
        let cleanName = name.contains("VS Code") ? "VS Code Insiders" : name
        return FinderWindowTab(
            id: "app-\(bundleId)",
            kind: .app(bundleId: bundleId, name: cleanName),
            title: cleanName
        )
    }

    public static func == (lhs: FinderWindowTab, rhs: FinderWindowTab) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - 🪟 Presentation Form Archetypes
public enum FinderChatPresentationForm: String, CaseIterable, Sendable {
    case desktopForm = "Desktop Window Form"
    case slideDownFullScreen = "Slide-Down Full Screen"
}

// MARK: - 📁 Universal Finder Window Manager

@MainActor
public final class FinderChatWindowManager: ObservableObject {
    public static let shared = FinderChatWindowManager()

    @Published public var presentationForm: FinderChatPresentationForm = .desktopForm
    @Published public var isSlideDownFullScreen: Bool = false
    @Published public var isOpen: Bool = false
    @Published public private(set) var isVisible: Bool = false
    @Published public private(set) var isExpanded: Bool = false
    @Published public private(set) var currentSizePreset: FinderWindowSizePreset = .standard
    @Published public var activeTab: FinderWindowTab = .files
    @Published public var openTabs: [FinderWindowTab] = [.files, .editor, .chat]
    @Published public var stagedAttachments: [URL] = []
    @Published public var isDualHemisphereMode: Bool = {
        if UserDefaults.standard.object(forKey: PrefKey.isDualHemisphereMode) == nil {
            return true
        }
        return UserDefaults.standard.bool(forKey: PrefKey.isDualHemisphereMode)
    }()
    private var savedDesktopFrame: NSRect?

    public func newChatTab() {
        let chatCount = openTabs.filter { $0.kind == .chat }.count + 1
        let title = chatCount == 1 ? "Genie Chat" : "Genie Chat \(chatCount)"
        let tab = FinderWindowTab(
            id: "chat-\(UUID().uuidString)",
            kind: .chat,
            title: title
        )
        openTabs.append(tab)
        activeTab = tab
        show(tab: tab)
    }

    public func newFinderTab() {
        let finderCount = openTabs.filter { $0.kind == .files }.count + 1
        let title = finderCount == 1 ? "Desktop & Files" : "Finder \(finderCount)"
        let tab = FinderWindowTab(
            id: "finder-\(UUID().uuidString)",
            kind: .files,
            title: title
        )
        openTabs.append(tab)
        activeTab = tab
        show(tab: tab)
    }

    public func newEditorTab() {
        let editorCount = openTabs.filter { $0.kind == .editor }.count + 1
        let title = editorCount == 1 ? "Genio Studio" : "Genio Studio \(editorCount)"
        let tab = FinderWindowTab(
            id: "editor-\(UUID().uuidString)",
            kind: .editor,
            title: title
        )
        openTabs.append(tab)
        activeTab = tab
        show(tab: tab)
    }

    public func openProgram(bundleId: String, name: String) {
        let cleanName = name.contains("VS Code") ? "Genio Studio" : name
        let tab = FinderWindowTab.app(bundleId: bundleId, name: cleanName)
        if !openTabs.contains(tab) {
            openTabs.append(tab)
        }
        activeTab = tab
        show(tab: tab)
    }

    public func openTab(_ tab: FinderWindowTab) {
        if !openTabs.contains(tab) {
            openTabs.append(tab)
        }
        activeTab = tab
        show(tab: tab)
    }

    public func closeTab(_ tab: FinderWindowTab) {
        guard openTabs.count > 1 else { return }
        if let idx = openTabs.firstIndex(of: tab) {
            openTabs.remove(at: idx)
            if activeTab == tab {
                activeTab = openTabs.last ?? .chat
            }
        }
    }

    public var isShowingSettings: Bool {
        get { activeTab.kind == .settings }
        set { activeTab = newValue ? .settings : .chat }
    }

    public func stageFile(url: URL) {
        if !stagedAttachments.contains(url) {
            stagedAttachments.append(url)
        }
        show(tab: .chat)
    }

    public func stageAttachments(_ urls: [URL]) {
        for u in urls {
            if !stagedAttachments.contains(u) {
                stagedAttachments.append(u)
            }
        }
        show(tab: .chat)
        NotificationCenter.default.post(name: NSNotification.Name("GenieStageAttachments"), object: urls)
    }

    public func clearStagedAttachments() {
        stagedAttachments.removeAll()
    }
    private var preExpandFrame: NSRect?
    private var window: NSPanel?

    private init() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NexusToggleFinderChatWindow"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.toggle()
            }
        }

        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NexusSlideDownFullScreenChat"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.slideDownFullScreen()
            }
        }

        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NexusShowDesktopChat"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.showInDesktopForm()
            }
        }

        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NexusToggleChatPresentationForm"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.togglePresentationForm()
            }
        }

        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NexusToggleDualHemisphere"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.toggleDualHemisphere()
            }
        }

        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("NexusOpenMiniBrowser"),
            object: nil,
            queue: .main
        ) { [weak self] notif in
            MainActor.assumeIsolated {
                self?.openTab(.browser)
                if let url = notif.object as? URL {
                    MiniBrowserManager.shared.load(url: url)
                } else if let urlStr = notif.object as? String, let url = URL(string: urlStr) {
                    MiniBrowserManager.shared.load(url: url)
                }
            }
        }
    }

    public func toggle(tab: FinderWindowTab = .chat) {
        if DesktopWindowManager.shared.isTopDockPresented {
            DesktopWindowManager.shared.dismissTopDock()
            if isVisible { hide() }
        } else if isVisible {
            if activeTab == tab {
                hide()
            } else {
                activeTab = tab
                window?.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
        } else {
            // Consolidate presentations: route directly into the unified Top Dock & Active Desktop
            if tab == .applications {
                DesktopWindowManager.shared.showTopDockWithActiveDesktop()
            } else {
                DesktopWindowManager.shared.presentTopDock()
            }
        }
    }

    public func snapTo(preset: FinderWindowSizePreset) {
        guard let win = window else { return }
        let screen = win.screen ?? NSScreen.main ?? NSScreen.screens.first ?? NSScreen()
        let sFrame = screen.visibleFrame

        let targetRect: NSRect
        switch preset {
        case .topPanel:
            let targetW: CGFloat = min(1000, sFrame.width - 40)
            let targetH: CGFloat = min(720, sFrame.height - 40)
            let x = sFrame.minX + (sFrame.width - targetW) / 2
            let y = sFrame.maxY - targetH - 6
            targetRect = NSRect(x: x, y: y, width: targetW, height: targetH)
            isExpanded = false
            isSlideDownFullScreen = false
            presentationForm = .desktopForm

        case .standard:
            let targetW: CGFloat = min(980, sFrame.width - 80)
            let targetH: CGFloat = min(680, sFrame.height - 100)
            let x = sFrame.minX + (sFrame.width - targetW) / 2
            let y = sFrame.minY + (sFrame.height - targetH) / 2
            targetRect = NSRect(x: x, y: y, width: targetW, height: targetH)
            isExpanded = false
            isSlideDownFullScreen = false
            presentationForm = .desktopForm

        case .rightHalf:
            let targetW: CGFloat = sFrame.width * 0.50
            let targetH: CGFloat = sFrame.height - 4
            let x = sFrame.maxX - targetW
            let y = sFrame.minY + 2
            targetRect = NSRect(x: x, y: y, width: targetW, height: targetH)
            isExpanded = true
            isSlideDownFullScreen = false
            presentationForm = .desktopForm

            UserDefaults.standard.set(false, forKey: PrefKey.studioPanelsFlipped)
            NotificationCenter.default.post(name: NSNotification.Name("NexusRightHalfScreenModeActivated"), object: nil)
            if activeTab.kind != .chat && activeTab.kind != .editor {
                activeTab = .chat
            }

        case .leftHalf:
            let targetW: CGFloat = sFrame.width * 0.50
            let targetH: CGFloat = sFrame.height - 4
            let x = sFrame.minX
            let y = sFrame.minY + 2
            targetRect = NSRect(x: x, y: y, width: targetW, height: targetH)
            isExpanded = true
            isSlideDownFullScreen = false
            presentationForm = .desktopForm

            // Pop editor into thirds mode on the left half screen!
            if activeTab.kind != .editor {
                activeTab = .editor
            }
            NotificationCenter.default.post(name: NSNotification.Name("NexusLeftHalfScreenModeActivated"), object: nil)

        case .thirdsMode:
            let targetW: CGFloat = min(sFrame.width * 0.72, max(960, sFrame.width * 0.66))
            let targetH: CGFloat = sFrame.height - 4
            let x = sFrame.minX
            let y = sFrame.minY + 2
            targetRect = NSRect(x: x, y: y, width: targetW, height: targetH)
            isExpanded = true
            isSlideDownFullScreen = false
            presentationForm = .desktopForm

            if activeTab.kind != .editor {
                activeTab = .editor
            }
            NotificationCenter.default.post(name: NSNotification.Name("NexusThirdsScreenModeActivated"), object: nil)

        case .verticalTop:
            let targetW: CGFloat = min(720, max(600, sFrame.width * 0.52))
            let targetH: CGFloat = sFrame.height - 8
            let x = sFrame.minX + (sFrame.width - targetW) / 2
            let y = sFrame.minY + 4
            targetRect = NSRect(x: x, y: y, width: targetW, height: targetH)
            isExpanded = false
            isSlideDownFullScreen = false
            presentationForm = .desktopForm

        case .mostScreen:
            let targetW: CGFloat = sFrame.width * 0.90
            let targetH: CGFloat = sFrame.height * 0.90
            let x = sFrame.minX + (sFrame.width - targetW) / 2
            let y = sFrame.minY + (sFrame.height - targetH) / 2
            targetRect = NSRect(x: x, y: y, width: targetW, height: targetH)
            isExpanded = true
            isSlideDownFullScreen = false
            presentationForm = .desktopForm

        case .fullScreen:
            targetRect = NSRect(x: sFrame.minX + 2, y: sFrame.minY + 2, width: sFrame.width - 4, height: sFrame.height - 4)
            isExpanded = true
            isSlideDownFullScreen = true
            presentationForm = .slideDownFullScreen
        }

        currentSizePreset = preset
        HapticFeedback.selection()
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.28
            ctx.timingFunction = CAMediaTimingFunction(controlPoints: 0.16, 1.0, 0.3, 1.0)
            win.animator().setFrame(targetRect, display: true)
        }
        NotificationCenter.default.post(name: NSNotification.Name("NexusChatPresentationFormChanged"), object: presentationForm.rawValue)
    }

    public func toggleExpand() {
        togglePresentationForm()
    }

    // MARK: - 🚀 1. Uniform Slide-Down Full Screen Chat Form
    /// Fluidly slides the full-screen flagship chat down from the top edge of the screen.
    public func slideDownFullScreen(tab: FinderWindowTab = .chat) {
        self.activeTab = tab
        self.presentationForm = .slideDownFullScreen
        self.isSlideDownFullScreen = true
        self.currentSizePreset = .fullScreen
        self.isExpanded = true

        UserDefaults.standard.set(false, forKey: PrefKey.isRightChatDockOpen)
        NotificationCenter.default.post(name: NSNotification.Name("NexusCloseSecondaryChatWindows"), object: nil)
        NotificationCenter.default.post(name: NSNotification.Name("NexusCloseAllRollupsExceptChat"), object: nil)
        NotificationCenter.default.post(name: NSNotification.Name("NexusDismissTopCeilingDashboard"), object: nil)

        if window == nil {
            createWindow()
        }
        guard let win = window else { return }

        if win.isMiniaturized { win.deminiaturize(nil) }

        let screen = NSScreen.main ?? NSScreen.screens.first ?? NSScreen()
        let sFrame = screen.visibleFrame
        let targetRect = NSRect(
            x: sFrame.minX + 2,
            y: sFrame.minY + 2,
            width: sFrame.width - 4,
            height: sFrame.height - 4
        )

        if isVisible {
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.30
                ctx.timingFunction = CAMediaTimingFunction(controlPoints: 0.16, 1.0, 0.3, 1.0)
                win.animator().setFrame(targetRect, display: true)
                win.animator().alphaValue = 1.0
            }
            win.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            HapticFeedback.selection()
            NotificationCenter.default.post(name: NSNotification.Name("NexusChatPresentationFormChanged"), object: presentationForm.rawValue)
            return
        }

        // True slide-down: Starts entirely offscreen above the top edge
        let startRect = NSRect(
            x: sFrame.minX + 2,
            y: sFrame.maxY + 30,
            width: sFrame.width - 4,
            height: sFrame.height - 4
        )

        win.setFrame(startRect, display: false)
        win.alphaValue = 0.0
        win.makeKeyAndOrderFront(nil)
        win.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.34
            ctx.timingFunction = CAMediaTimingFunction(controlPoints: 0.16, 1.0, 0.3, 1.0)
            win.animator().setFrame(targetRect, display: true)
            win.animator().alphaValue = 1.0
        }

        isVisible = true
        HapticFeedback.selection()
        NotificationCenter.default.post(name: NSNotification.Name("NexusChatPresentationFormChanged"), object: presentationForm.rawValue)
    }

    // MARK: - 🖥️ 2. Desktop Floating Window Form
    /// Presents the chat in its standard movable, resizable floating desktop window format.
    public func showInDesktopForm(tab: FinderWindowTab = .chat) {
        self.activeTab = tab
        self.presentationForm = .desktopForm
        self.isSlideDownFullScreen = false
        self.currentSizePreset = .standard
        self.isExpanded = false

        UserDefaults.standard.set(false, forKey: PrefKey.isRightChatDockOpen)
        NotificationCenter.default.post(name: NSNotification.Name("NexusCloseSecondaryChatWindows"), object: nil)
        NotificationCenter.default.post(name: NSNotification.Name("NexusCloseAllRollupsExceptChat"), object: nil)
        NotificationCenter.default.post(name: NSNotification.Name("NexusDismissTopCeilingDashboard"), object: nil)

        if window == nil {
            createWindow()
        }
        guard let win = window else { return }

        if win.isMiniaturized { win.deminiaturize(nil) }

        let screen = win.screen ?? NSScreen.main ?? NSScreen.screens.first ?? NSScreen()
        let sFrame = screen.visibleFrame

        let targetRect: NSRect
        if let saved = savedDesktopFrame, sFrame.intersects(saved), saved.width >= 460, saved.height >= 400 {
            targetRect = saved
        } else {
            let targetW: CGFloat = isDualHemisphereMode ? min(1340, sFrame.width - 40) : min(980, sFrame.width - 80)
            let targetH: CGFloat = min(720, sFrame.height - 80)
            let x = sFrame.minX + (sFrame.width - targetW) / 2
            let y = sFrame.minY + (sFrame.height - targetH) / 2
            targetRect = NSRect(x: x, y: y, width: targetW, height: targetH)
        }

        if isVisible {
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.28
                ctx.timingFunction = CAMediaTimingFunction(controlPoints: 0.16, 1.0, 0.3, 1.0)
                win.animator().setFrame(targetRect, display: true)
                win.animator().alphaValue = 1.0
            }
            win.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            HapticFeedback.selection()
            NotificationCenter.default.post(name: NSNotification.Name("NexusChatPresentationFormChanged"), object: presentationForm.rawValue)
            return
        }

        let startRect = NSRect(
            x: targetRect.origin.x,
            y: targetRect.origin.y - 12,
            width: targetRect.width,
            height: targetRect.height
        )

        win.setFrame(startRect, display: false)
        win.alphaValue = 0.0
        win.makeKeyAndOrderFront(nil)
        win.orderFrontRegardless()
        NSApp.activate(ignoringOtherApps: true)

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.26
            ctx.timingFunction = CAMediaTimingFunction(controlPoints: 0.16, 1.0, 0.3, 1.0)
            win.animator().setFrame(targetRect, display: true)
            win.animator().alphaValue = 1.0
        }

        isVisible = true
        HapticFeedback.selection()
        NotificationCenter.default.post(name: NSNotification.Name("NexusChatPresentationFormChanged"), object: presentationForm.rawValue)
    }

    // MARK: - 🌓 2.5. Dual Hemisphere Unfolding Mode
    /// Flips out the second screen in the left hemisphere (Apple Finder Miller Columns + scrollable previews)
    /// while keeping Genie Chat & render stream in the right hemisphere.
    public func toggleDualHemisphere() {
        isDualHemisphereMode.toggle()
        UserDefaults.standard.set(isDualHemisphereMode, forKey: PrefKey.isDualHemisphereMode)
        if isVisible, let win = window {
            let screen = win.screen ?? NSScreen.main ?? NSScreen()
            let sFrame = screen.visibleFrame
            let cur = win.frame
            let targetW: CGFloat = isDualHemisphereMode ? min(1340, sFrame.width - 40) : min(980, sFrame.width - 80)
            let targetH: CGFloat = max(cur.height, 680)
            let newX = max(sFrame.minX + 10, min(sFrame.maxX - targetW - 10, cur.origin.x - (targetW - cur.width) / 2))
            let newFrame = NSRect(x: newX, y: cur.origin.y, width: targetW, height: targetH)
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.30
                ctx.timingFunction = CAMediaTimingFunction(controlPoints: 0.16, 1.0, 0.3, 1.0)
                win.animator().setFrame(newFrame, display: true)
            }
        }
        HapticFeedback.selection()
        NotificationCenter.default.post(name: NSNotification.Name("NexusDualHemisphereToggled"), object: isDualHemisphereMode)
    }

    // MARK: - 🔄 3. Seamless Bidirectional Form Morphing
    public func togglePresentationForm() {
        if isSlideDownFullScreen {
            showInDesktopForm(tab: activeTab)
        } else {
            if let win = window, isVisible {
                savedDesktopFrame = win.frame
            }
            slideDownFullScreen(tab: activeTab)
        }
    }

    public func show(tab: FinderWindowTab = .chat) {
        if isSlideDownFullScreen {
            slideDownFullScreen(tab: tab)
        } else {
            showInDesktopForm(tab: tab)
        }
    }

    public func show(settings: Bool) {
        show(tab: settings ? .settings : .chat)
    }

    public func minimize() {
        hide()
    }

    public func hide() {
        GenieSpeechRecognitionEngine.shared.stopListening()
        guard let win = window, isVisible else { return }

        if !isSlideDownFullScreen {
            savedDesktopFrame = win.frame
        }
        let wasSlideDown = isSlideDownFullScreen
        let screen = win.screen ?? NSScreen.main ?? NSScreen.screens.first ?? NSScreen()
        let sFrame = screen.visibleFrame

        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.22
            ctx.timingFunction = CAMediaTimingFunction(controlPoints: 0.25, 0.1, 0.25, 1.0)
            if wasSlideDown {
                // Slide smoothly back UP above the top edge
                let endRect = NSRect(
                    x: win.frame.origin.x,
                    y: sFrame.maxY + 30,
                    width: win.frame.width,
                    height: win.frame.height
                )
                win.animator().setFrame(endRect, display: true)
            }
            win.animator().alphaValue = 0.0
        }, completionHandler: {
            MainActor.assumeIsolated {
                win.orderOut(nil)
                self.isVisible = false
                NotificationCenter.default.post(name: NSNotification.Name("NexusChatWindowDidHide"), object: nil)
            }
        })
        HapticFeedback.tick()
    }

    private func createWindow() {
        let panel = FinderChatPanel(
            contentRect: NSRect(x: 0, y: 0, width: 920, height: 640),
            styleMask: [.borderless, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )

        panel.titlebarAppearsTransparent = true
        panel.titleVisibility = .hidden
        if #available(macOS 11.0, *) {
            panel.titlebarSeparatorStyle = .none
        }
        panel.standardWindowButton(.closeButton)?.isHidden = true
        panel.standardWindowButton(.miniaturizeButton)?.isHidden = true
        panel.standardWindowButton(.zoomButton)?.isHidden = true
        panel.isMovable = true
        panel.isMovableByWindowBackground = true
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        panel.isExcludedFromWindowsMenu = false
        panel.sharingType = .readOnly
        // The floor is the tall, narrow shape the chat is actually used at. Below roughly this
        // width the tab row (Genie / Chat / Files / Settings / model chip) collides with itself,
        // and below this height the transcript collapses to a couple of visible lines.
        panel.minSize = NSSize(width: 460, height: 680)

        let host = NSHostingView(rootView: FinderStyleChatWindowView().ignoresSafeArea())
        host.autoresizingMask = [.width, .height]
        panel.contentView = host
        panel.invalidateShadow()
        self.window = panel

        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: panel,
            queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.isVisible = false
            }
        }

        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, self.isVisible, let win = self.window else { return }
                win.orderFrontRegardless()
            }
        }
    }
}

// MARK: - Dedicated Finder Chat Panel Window Subclass
public final class FinderChatPanel: NSPanel {
    public override var canBecomeKey: Bool { true }
    public override var canBecomeMain: Bool { true }

    public override func performKeyEquivalent(with event: NSEvent) -> Bool {
        if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers?.lowercased() == "q" {
            NSApp.terminate(nil)
            return true
        }
        if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers?.lowercased() == "w" {
            FinderChatWindowManager.shared.hide()
            return true
        }
        if event.keyCode == 53 { // Escape key
            FinderChatWindowManager.shared.hide()
            return true
        }
        if event.modifierFlags.contains([.command, .option]) {
            if event.keyCode == 124 { // Right arrow (⌥⌘→)
                FinderChatWindowManager.shared.snapTo(preset: .rightHalf)
                return true
            }
            if event.keyCode == 123 { // Left arrow (⌥⌘←)
                FinderChatWindowManager.shared.snapTo(preset: .leftHalf)
                return true
            }
            if event.keyCode == 126 { // Up arrow (⌥⌘↑)
                FinderChatWindowManager.shared.slideDownFullScreen()
                return true
            }
            if event.keyCode == 125 { // Down arrow (⌥⌘↓)
                FinderChatWindowManager.shared.showInDesktopForm()
                return true
            }
        }
        if let mainMenu = NSApp.mainMenu, mainMenu.performKeyEquivalent(with: event) {
            return true
        }
        return super.performKeyEquivalent(with: event)
    }

    public override func keyDown(with event: NSEvent) {
        if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers?.lowercased() == "q" {
            NSApp.terminate(nil)
            return
        }
        if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers?.lowercased() == "w" {
            FinderChatWindowManager.shared.hide()
            return
        }
        if event.keyCode == 53 { // Escape key
            FinderChatWindowManager.shared.hide()
            return
        }
        super.keyDown(with: event)
    }
}

// MARK: - Native Window Dragging Background Helper
public struct WindowDragRepresentable: NSViewRepresentable {
    public init() {}
    public func makeNSView(context: Context) -> DraggingNSView {
        DraggingNSView()
    }
    public func updateNSView(_ nsView: DraggingNSView, context: Context) {}

    public final class DraggingNSView: NSView {
        public override func mouseDown(with event: NSEvent) {
            window?.performDrag(with: event)
        }
    }
}
