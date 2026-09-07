import AppKit
import SwiftUI
import ApplicationServices

// MARK: - Compiled Menu Item Model
public struct CompiledMenuItem: Identifiable, Equatable {
    public let id: String
    public let title: String
    public let isAppTitle: Bool
    public let axElement: AXUIElement?

    public static func == (lhs: CompiledMenuItem, rhs: CompiledMenuItem) -> Bool {
        lhs.id == rhs.id && lhs.title == rhs.title
    }
}

// MARK: - Menu Bar Compiler Singleton
@MainActor
public final class MenuBarCompiler: ObservableObject {
    public static let shared = MenuBarCompiler()

    @Published public var activeAppName: String = "Genie"
    @Published public var activeAppBundleId: String = Bundle.main.bundleIdentifier ?? "com.goldengate.Genie"
    @Published public var activeAppIcon: NSImage? = nil
    @Published public var compiledMenus: [CompiledMenuItem] = []
    private var activeAppObserver: NSObjectProtocol? = nil

    private init() {
        setupObservers()
        refreshActiveApp()
    }

    private func setupObservers() {
        activeAppObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshActiveApp()
            }
        }
    }

    deinit {
        if let obs = activeAppObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(obs)
        }
    }

    public func refreshActiveApp() {
        guard CustomMenuBarManager.shared.isEnabled else { return }
        guard let front = NSWorkspace.shared.frontmostApplication else {
            setFallbackGenie()
            return
        }

        let rawName = front.localizedName ?? "Finder"
        let bid = front.bundleIdentifier ?? ""

        // Filter out system security prompts, auth warnings, or daemon identifiers
        let isSystemAuthOrDaemon = rawName.isEmpty
            || rawName.contains("universalAccessAuthWarn")
            || rawName.contains("universalAccessAuth")
            || rawName == "SecurityAgent"
            || rawName == "loginwindow"
            || bid.contains("universalAccessAuthWarn")
            || bid == "com.apple.SecurityAgent"

        let name: String
        let icon: NSImage?
        if isSystemAuthOrDaemon {
            if let regularApp = NSWorkspace.shared.runningApplications.first(where: { $0.isActive && $0.activationPolicy == .regular && $0.localizedName?.contains("universalAccessAuth") == false }) {
                name = regularApp.localizedName ?? "Genie"
                icon = regularApp.icon
            } else {
                name = "Genie"
                icon = NSImage(named: NSImage.applicationIconName)
            }
        } else {
            name = rawName
            icon = front.icon
        }

        self.activeAppName = name
        self.activeAppBundleId = bid
        self.activeAppIcon = icon

        // Attempt Accessibility extraction of live menus
        let pid = front.processIdentifier
        let appElement = AXUIElementCreateApplication(pid)

        var menuBarRef: CFTypeRef?
        let status = AXUIElementCopyAttributeValue(appElement, kAXMenuBarAttribute as CFString, &menuBarRef)

        if status == .success, let ref = menuBarRef, CFGetTypeID(ref) == AXUIElementGetTypeID() {
            let menuBar = ref as! AXUIElement
            var childrenRef: CFTypeRef?
            let childStatus = AXUIElementCopyAttributeValue(menuBar, kAXChildrenAttribute as CFString, &childrenRef)

            if childStatus == .success, let children = childrenRef as? [AXUIElement], !children.isEmpty {
                var items: [CompiledMenuItem] = []

                for (idx, child) in children.enumerated() {
                    var titleRef: CFTypeRef?
                    if AXUIElementCopyAttributeValue(child, kAXTitleAttribute as CFString, &titleRef) == .success,
                       let titleStr = titleRef as? String, !titleStr.isEmpty {
                        let isFirst = (idx == 0)
                        items.append(
                            CompiledMenuItem(
                                id: "\(pid)_\(idx)_\(titleStr)",
                                title: titleStr,
                                isAppTitle: isFirst,
                                axElement: child
                            )
                        )
                    }
                }

                if !items.isEmpty {
                    let menus = items.filter { !$0.isAppTitle }
                    self.compiledMenus = menus.isEmpty ? standardFallbackMenus() : menus
                    return
                }
            }
        }

        self.compiledMenus = standardFallbackMenus()
    }

    private func setFallbackGenie() {
        self.activeAppName = "Genie"
        self.activeAppBundleId = Bundle.main.bundleIdentifier ?? "com.goldengate.Genie"
        self.activeAppIcon = NSImage(named: NSImage.applicationIconName)
        self.compiledMenus = standardFallbackMenus()
    }

    private func standardFallbackMenus() -> [CompiledMenuItem] {
        let defaults = ["File", "Edit", "View", "Window", "Help"]
        return defaults.enumerated().map { idx, name in
            CompiledMenuItem(
                id: "fallback_\(idx)_\(name)",
                title: name,
                isAppTitle: false,
                axElement: nil
            )
        }
    }

    public func triggerMenu(_ item: CompiledMenuItem) {
        if let ax = item.axElement {
            AXUIElementPerformAction(ax, kAXPressAction as CFString)
        } else {
            simulateMenuAction(item.title)
        }
    }

    private func simulateMenuAction(_ title: String) {
        switch title.lowercased() {
        case "file":
            NotificationCenter.default.post(name: NSNotification.Name("NexusOpenFileMenu"), object: nil)
        case "edit":
            NotificationCenter.default.post(name: NSNotification.Name("NexusOpenEditMenu"), object: nil)
        case "view":
            NotificationCenter.default.post(name: NSNotification.Name("NexusOpenViewMenu"), object: nil)
        case "window":
            NotificationCenter.default.post(name: NSNotification.Name("NexusOpenWindowMenu"), object: nil)
        case "help":
            NotificationCenter.default.post(name: NSNotification.Name("NexusOpenHelpMenu"), object: nil)
        default:
            break
        }
    }
}
