import AppKit
import ApplicationServices

/// Read-only, bounded accessibility context for an explicit visual lookup.
enum GenieAccessibilityContext {
    @MainActor
    static func capture() async -> String {
        guard AXIsProcessTrusted() else {
            return "Accessibility unavailable. Enable Genie in System Settings > Privacy & Security > Accessibility."
        }
        guard let app = NSWorkspace.shared.frontmostApplication else {
            return "No frontmost application."
        }
        let pid = app.processIdentifier
        return await Task.detached(priority: .userInitiated) {
            let application = AXUIElementCreateApplication(pid)
            AXUIElementSetMessagingTimeout(application, 0.2)
            func attribute(_ element: AXUIElement, _ name: String) -> CFTypeRef? {
                var value: CFTypeRef?
                guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
                return value
            }
            guard let window = attribute(application, kAXFocusedWindowAttribute),
                  CFGetTypeID(window) == AXUIElementGetTypeID() else {
                return "Focused window does not expose accessibility information."
            }
            var queue: [(AXUIElement, Int)] = [(window as! AXUIElement, 0)]
            var visited: [AXUIElement] = []
            var lines: [String] = []
            let deadline = Date().addingTimeInterval(2)
            while !queue.isEmpty && visited.count < 100 && Date() < deadline {
                let (element, depth) = queue.removeFirst()
                guard !visited.contains(where: { CFEqual($0, element) }) else { continue }
                visited.append(element)
                let role = attribute(element, kAXRoleAttribute) as? String ?? "element"
                let subrole = attribute(element, kAXSubroleAttribute) as? String ?? ""
                // Never collect secure text values or descendants.
                if subrole == "AXSecureTextField" { continue }
                let details = [kAXTitleAttribute, kAXDescriptionAttribute, kAXValueAttribute].compactMap {
                    (attribute(element, $0) as? String).map { String($0.prefix(300)) }
                }.filter { !$0.isEmpty }
                lines.append(([role] + details).joined(separator: " | "))
                if depth < 6, let children = attribute(element, kAXChildrenAttribute) as? [AXUIElement] {
                    queue.append(contentsOf: children.prefix(max(0, 100 - visited.count - queue.count)).map { ($0, depth + 1) })
                }
            }
            return lines.isEmpty ? "No accessible controls found." : lines.joined(separator: "\n")
        }.value
    }
}
