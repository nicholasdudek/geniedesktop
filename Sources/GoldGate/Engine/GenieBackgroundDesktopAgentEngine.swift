import AppKit
import ApplicationServices
import CoreGraphics
import Foundation

// MARK: - 🖥️ Genie Background Desktop Agent Engine
// Lets the local model (`genie-master`, routed through `GenieSkillsOrchestrator`) drive a real
// app on its own dedicated macOS Space (an `AgentVirtualSpace` from `AgentVirtualSpaceManager`)
// without ever touching the Space the user is actively looking at.
//
// Why Accessibility actions instead of `CGEvent...post(tap: .cghidEventTap)` or
// `CursorAutomationEngine.directBackgroundClick`: a global HID tap click is delivered to whatever
// is on screen in the CURRENTLY VISIBLE Space at that pixel — it cannot reach a window sitting on
// a different, inactive Space. `AXUIElementPerformAction` and `CGEvent.postToPid` are delivered
// straight to the target process instead, so they work regardless of which Space is on screen.
//
// Fills the `desktop_agent` / `read_ui` tool IDs that `AgentVirtualSpaceManager.seedDefaultAgentSpaces()`
// already lists in `assignedTools` for every seeded space, but that were never registered as skills.
@MainActor
public final class GenieBackgroundDesktopAgentEngine: ObservableObject {
    public static let shared = GenieBackgroundDesktopAgentEngine()

    @Published public var lastStatusMessage: String = "Background Desktop Agent idle"

    /// Which process each agent space is currently driving. Populated by `open`; consulted by
    /// click/type/key/read so those don't need an app name repeated on every call.
    private var trackedPIDs: [String: pid_t] = [:]

    private init() {}

    // MARK: - Space provisioning

    /// Ensures the given agent space has a real, dedicated Mission Control Space, creating one on
    /// first use. Attaching a brand-new Space to a display is a WindowServer operation that always
    /// activates it momentarily — there is no private symbol that skips this — so we snap straight
    /// back to the user's current Space afterward. Every later call for the same agent space is
    /// silent: no Space is created and no switch happens.
    @discardableResult
    private func ensureDedicatedSpace(for space: AgentVirtualSpace) -> Int {
        let desktops = MacDesktopsManager.shared
        desktops.refreshSpaces()
        if desktops.spaces.contains(where: { $0.index == space.assignedDesktopIndex }) {
            return space.assignedDesktopIndex
        }

        let originalIndex = desktops.currentSpaceIndex
        desktops.createDesktop() // attaches + switches (unavoidable one-time flash)
        let newIndex = desktops.currentSpaceIndex
        desktops.switchToDesktop(index: originalIndex) // snap back immediately

        AgentVirtualSpaceManager.shared.assignAgentToDesktop(spaceId: space.id, desktopIndex: newIndex)
        return newIndex
    }

    // MARK: - Resource-budgeted execution

    /// Routes through the existing RAM/concurrency governor so a background agent task can never
    /// compete with the user's foreground work beyond the configured partition.
    private func withResourceBudget<T>(estimatedMB: Int = 512, _ body: () async -> T) async -> T? {
        let (granted, reason) = await GenieMemoryGovernorEngine.shared.queueForResources(estimatedMB: estimatedMB, timeout: 10.0)
        guard granted else {
            lastStatusMessage = "🛑 Memory Governor: \(reason ?? "background desktop agent budget unavailable.")"
            return nil
        }
        defer { GenieMemoryGovernorEngine.shared.releaseResourceSlot() }
        return await body()
    }

    // MARK: - Skill entry point: desktop_agent

    /// `"<agent-space-id> <open|click|type|key|new_window|duplicate> <value>"`, e.g.
    /// `"agent-vscode-editor open Visual Studio Code"`, `"agent-vscode-editor click Run"`.
    public func performDesktopAgentAction(_ raw: String) async -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed.split(separator: " ", maxSplits: 2, omittingEmptySubsequences: true).map(String.init)
        guard parts.count >= 2 else {
            return "Usage: <agent-space-id> <open|click|type|key|new_window|duplicate> <value>\nKnown spaces: \(knownSpaceIDs())"
        }

        let spaceId = parts[0]
        let action = parts[1].lowercased()
        let value = parts.count >= 3 ? parts[2] : ""

        guard let space = AgentVirtualSpaceManager.shared.spaces.first(where: { $0.id == spaceId }) else {
            return "Unknown agent space '\(spaceId)'. Known: \(knownSpaceIDs())"
        }

        let outcome = await withResourceBudget(estimatedMB: 512) { () -> String in
            let desktopIndex = self.ensureDedicatedSpace(for: space)
            AgentVirtualSpaceManager.shared.updateAgentStatus(
                spaceId: space.id, status: .running,
                activeTask: "\(action) \(value)".trimmingCharacters(in: .whitespaces)
            )

            switch action {
            case "open":
                return await self.openApp(named: value, inSpace: desktopIndex, agentSpace: space)
            case "click":
                return self.clickElement(labeled: value, agentSpace: space)
            case "type":
                return self.typeText(value, agentSpace: space)
            case "key":
                return self.pressKey(named: value, agentSpace: space)
            case "new_window", "newwindow":
                return self.pressMenuAction(titled: "New Window", agentSpace: space)
            case "duplicate":
                return self.pressMenuAction(titled: "Duplicate", agentSpace: space)
            default:
                return "Unknown action '\(action)'. Use open, click, type, key, new_window, or duplicate."
            }
        }

        let result = outcome ?? lastStatusMessage
        AgentVirtualSpaceManager.shared.updateAgentStatus(spaceId: space.id, status: .completed, activeTask: result)
        lastStatusMessage = result
        return result
    }

    // MARK: - Skill entry point: read_ui

    /// `"<agent-space-id>"` — dumps the labeled Accessibility elements of the app that space is
    /// driving, so the model can "see" its own background desktop without screenshotting the
    /// user's real screen.
    public func readUI(_ raw: String) -> String {
        let spaceId = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let space = AgentVirtualSpaceManager.shared.spaces.first(where: { $0.id == spaceId }) else {
            return "Unknown agent space '\(spaceId)'. Known: \(knownSpaceIDs())"
        }
        guard let pid = trackedPIDs[space.id] else {
            return "No app is tracked for '\(space.id)' yet — use 'open <app name>' first."
        }

        let appElement = AXUIElementCreateApplication(pid)
        var windowsRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsRef) == .success,
              let windows = windowsRef as? [AXUIElement], let window = windows.first else {
            return "No visible window to read in \(space.name)."
        }

        var lines: [String] = []
        func describe(_ element: AXUIElement, depth: Int) {
            guard depth <= 6, lines.count < 200 else { return }

            var roleRef: CFTypeRef?
            var titleRef: CFTypeRef?
            AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleRef)
            AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &titleRef)
            let role = (roleRef as? String) ?? "?"
            if let title = titleRef as? String, !title.isEmpty {
                lines.append(String(repeating: "  ", count: depth) + "\(role): \(title)")
            }

            var childrenRef: CFTypeRef?
            if AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenRef) == .success,
               let children = childrenRef as? [AXUIElement] {
                for child in children { describe(child, depth: depth + 1) }
            }
        }
        describe(window, depth: 0)

        guard !lines.isEmpty else { return "\(space.name) window has no labeled elements." }
        return "🖥️ \(space.name) (Desktop \(space.assignedDesktopIndex)):\n" + lines.joined(separator: "\n")
    }

    // MARK: - Actions

    private func openApp(named name: String, inSpace desktopIndex: Int, agentSpace: AgentVirtualSpace) async -> String {
        let clean = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return "Specify an app name to open." }

        func runningMatch() -> NSRunningApplication? {
            NSWorkspace.shared.runningApplications.first {
                ($0.localizedName?.lowercased()).map { $0.contains(clean.lowercased()) } ?? false
            }
        }

        if let already = runningMatch() {
            trackedPIDs[agentSpace.id] = already.processIdentifier
            SmartGridManager.shared.moveAppToDesktop(pid: already.processIdentifier, targetDesktopIndex: desktopIndex)
            return "\(already.localizedName ?? clean) is already running — moved to its own Desktop \(desktopIndex)."
        }

        // Reuse the existing launch_app skill rather than re-implementing app discovery.
        let launchResult = await GenieSkillsOrchestrator.shared.execute(skillID: "launch_app", argument: clean)
        try? await Task.sleep(nanoseconds: 800_000_000) // let the app create its first window

        guard let launched = runningMatch() else {
            return launchResult
        }
        trackedPIDs[agentSpace.id] = launched.processIdentifier
        SmartGridManager.shared.moveAppToDesktop(pid: launched.processIdentifier, targetDesktopIndex: desktopIndex)
        return "Opened \(launched.localizedName ?? clean) on its own Desktop \(desktopIndex) — your active Space is untouched."
    }

    private func clickElement(labeled query: String, agentSpace: AgentVirtualSpace) -> String {
        guard !query.isEmpty else { return "Specify what to click." }
        guard let pid = trackedPIDs[agentSpace.id] else {
            return "No app is tracked for '\(agentSpace.id)' yet — use 'open <app name>' first."
        }
        guard let element = findElement(labeled: query, inAppWithPID: pid) else {
            return "Could not find a UI element labeled '\(query)' in \(agentSpace.name)."
        }
        let result = AXUIElementPerformAction(element, kAXPressAction as CFString)
        return result == .success
            ? "Clicked '\(query)' in \(agentSpace.name)."
            : "Found '\(query)' but the click action failed (AXError \(result.rawValue))."
    }

    private func typeText(_ text: String, agentSpace: AgentVirtualSpace) -> String {
        guard !text.isEmpty else { return "Specify text to type." }
        guard let pid = trackedPIDs[agentSpace.id] else {
            return "No app is tracked for '\(agentSpace.id)' yet — use 'open <app name>' first."
        }

        let appElement = AXUIElementCreateApplication(pid)
        var focusedRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appElement, kAXFocusedUIElementAttribute as CFString, &focusedRef) == .success,
              let focused = focusedRef else {
            return "Could not find a focused text field in \(agentSpace.name)."
        }

        let result = AXUIElementSetAttributeValue(focused as! AXUIElement, kAXValueAttribute as CFString, text as CFTypeRef)
        return result == .success
            ? "Typed into \(agentSpace.name)."
            : "Found the focused field but could not set its text (AXError \(result.rawValue))."
    }

    /// Presses a menu-bar item by exact title (e.g. "New Window", "Duplicate") via Accessibility,
    /// rather than a hardcoded key combo — the shortcut for "new window" varies by app, but the
    /// menu item's title doesn't, and `AXUIElementPerformAction` reaches it on an inactive Space.
    private func pressMenuAction(titled title: String, agentSpace: AgentVirtualSpace) -> String {
        guard let pid = trackedPIDs[agentSpace.id] else {
            return "No app is tracked for '\(agentSpace.id)' yet — use 'open <app name>' first."
        }
        guard let item = findMenuItem(titled: title, inAppWithPID: pid) else {
            return "Could not find a '\(title)' menu item in \(agentSpace.name)."
        }
        let result = AXUIElementPerformAction(item, kAXPressAction as CFString)
        return result == .success
            ? "\(title) in \(agentSpace.name)."
            : "Found '\(title)' but the action failed (AXError \(result.rawValue))."
    }

    private func findMenuItem(titled title: String, inAppWithPID pid: pid_t, maxDepth: Int = 6) -> AXUIElement? {
        let appElement = AXUIElementCreateApplication(pid)
        var menuBarRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appElement, kAXMenuBarAttribute as CFString, &menuBarRef) == .success,
              let menuBar = menuBarRef else { return nil }

        let needle = title.lowercased()

        func search(_ element: AXUIElement, depth: Int) -> AXUIElement? {
            guard depth <= maxDepth else { return nil }

            var titleRef: CFTypeRef?
            if AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &titleRef) == .success,
               let elementTitle = titleRef as? String, elementTitle.lowercased() == needle {
                return element
            }

            var childrenRef: CFTypeRef?
            guard AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenRef) == .success,
                  let children = childrenRef as? [AXUIElement] else { return nil }

            for child in children {
                if let found = search(child, depth: depth + 1) { return found }
            }
            return nil
        }

        return search(menuBar as! AXUIElement, depth: 0)
    }

    private func pressKey(named key: String, agentSpace: AgentVirtualSpace) -> String {
        guard let pid = trackedPIDs[agentSpace.id] else {
            return "No app is tracked for '\(agentSpace.id)' yet — use 'open <app name>' first."
        }
        let keyCodes: [String: CGKeyCode] = [
            "return": 36, "enter": 36, "tab": 48, "escape": 53, "esc": 53, "space": 49, "delete": 51
        ]
        guard let code = keyCodes[key.lowercased()] else {
            return "Unknown key '\(key)'. Known: \(keyCodes.keys.sorted().joined(separator: ", "))"
        }

        let source = CGEventSource(stateID: .combinedSessionState)
        CGEvent(keyboardEventSource: source, virtualKey: code, keyDown: true)?.postToPid(pid)
        CGEvent(keyboardEventSource: source, virtualKey: code, keyDown: false)?.postToPid(pid)
        return "Sent '\(key)' to \(agentSpace.name)."
    }

    // MARK: - Helpers

    private func knownSpaceIDs() -> String {
        AgentVirtualSpaceManager.shared.spaces.map(\.id).joined(separator: ", ")
    }

    private func findElement(
        labeled query: String,
        inAppWithPID pid: pid_t,
        maxNodes: Int = 2000,
        maxDepth: Int = 6
    ) -> AXUIElement? {
        let appElement = AXUIElementCreateApplication(pid)
        var windowsRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsRef) == .success,
              let windows = windowsRef as? [AXUIElement] else { return nil }

        let needle = query.lowercased()
        var visited = 0

        func search(_ element: AXUIElement, depth: Int) -> AXUIElement? {
            guard depth <= maxDepth, visited < maxNodes else { return nil }
            visited += 1

            for attr in [kAXTitleAttribute, kAXDescriptionAttribute, kAXValueAttribute] {
                var value: CFTypeRef?
                if AXUIElementCopyAttributeValue(element, attr as CFString, &value) == .success,
                   let text = value as? String, text.lowercased().contains(needle) {
                    return element
                }
            }

            var childrenRef: CFTypeRef?
            guard AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenRef) == .success,
                  let children = childrenRef as? [AXUIElement] else { return nil }

            for child in children {
                if let found = search(child, depth: depth + 1) { return found }
            }
            return nil
        }

        for window in windows {
            if let found = search(window, depth: 0) { return found }
        }
        return nil
    }
}
