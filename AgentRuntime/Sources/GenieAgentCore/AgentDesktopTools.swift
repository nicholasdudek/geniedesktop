import AppKit
import ApplicationServices

public enum AgentTextTransfer {
    public static func identical(_ left: String, _ right: String) -> Bool {
        left.utf8.elementsEqual(right.utf8)
    }

    public static func replacingSelection(in value: String, range: CFRange, with text: String) throws -> String {
        let source = value as NSString
        guard range.location >= 0, range.length >= 0, range.location <= source.length,
              range.length <= source.length - range.location else { throw AgentFailure("Invalid text selection; reread the field.") }
        let nsRange = NSRange(location: range.location, length: range.length)
        guard Range(nsRange, in: value) != nil else { throw AgentFailure("Selection splits a Unicode character.") }
        return source.replacingCharacters(in: nsRange, with: text)
    }
}

/// Element handles belong to a single agent run and expire whenever the UI is rescanned.
@MainActor
public final class AgentDesktopTools {
    private struct Target {
        let element: AXUIElement
        let pid: pid_t
    }
    private var targets: [String: Target] = [:]
    public init() {}

    private func attribute(_ element: AXUIElement, _ name: String) -> CFTypeRef? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
        return value
    }
    private func string(_ element: AXUIElement, _ name: String) -> String? { attribute(element, name) as? String }
    private func isSecure(_ element: AXUIElement) -> Bool {
        string(element, kAXSubroleAttribute) == kAXSecureTextFieldSubrole
    }
    private func target(_ id: String) throws -> Target {
        guard let target = targets[id], NSRunningApplication(processIdentifier: target.pid) != nil,
              attribute(target.element, kAXRoleAttribute) != nil else {
            throw AgentFailure("Element is stale or unknown; use read_ui again.")
        }
        guard !isSecure(target.element) else { throw AgentFailure("Secure text fields are excluded.") }
        return target
    }
    private func text(_ target: Target, scope: String) throws -> String {
        guard scope == "value" || scope == "selection" else { throw AgentFailure("scope must be value or selection.") }
        let key = scope == "selection" ? kAXSelectedTextAttribute : kAXValueAttribute
        guard let value = string(target.element, key) else { throw AgentFailure("This element does not expose \(scope) text through Accessibility.") }
        guard value.utf8.count <= 262_144 else { throw AgentFailure("UI text exceeds 256 KB; select a smaller region.") }
        return value
    }
    private func selection(_ element: AXUIElement) throws -> CFRange {
        guard let raw = attribute(element, kAXSelectedTextRangeAttribute), CFGetTypeID(raw) == AXValueGetTypeID() else {
            throw AgentFailure("Cannot read destination selection; paste was not attempted.")
        }
        var range = CFRange()
        guard AXValueGetValue(raw as! AXValue, .cfRange, &range) else { throw AgentFailure("Invalid destination selection.") }
        return range
    }
    private func setClipboard(_ text: String) throws {
        let board = NSPasteboard.general
        board.clearContents()
        guard board.setString(text, forType: .string), let actual = board.string(forType: .string),
              AgentTextTransfer.identical(actual, text) else { throw AgentFailure("Clipboard read-back verification failed.") }
    }

    public func execute(_ name: String, args: [String: String]) async throws -> AgentToolResult {
        try Task.checkCancellation()
        guard AXIsProcessTrusted() else { throw AgentFailure("Enable Accessibility access for Genie in System Settings, then retry.") }
        switch name {
        case "read_ui":
            targets.removeAll()
            guard let app = NSRunningApplication.runningApplications(withBundleIdentifier: args["app"]!).first else {
                throw AgentFailure("Application is not running. Open it, then read_ui again.")
            }
            let root = AXUIElementCreateApplication(app.processIdentifier)
            AXUIElementSetMessagingTimeout(root, 0.3)
            var queue = [root]
            var visited = Set<AXUIElement>()
            var rows: [[String: Any]] = []
            let snapshot = UUID().uuidString
            let deadline = Date().addingTimeInterval(5)
            var index = 0
            while index < queue.count && index < 500 && Date() < deadline {
                try Task.checkCancellation()
                let element = queue[index]; index += 1
                guard visited.insert(element).inserted, !isSecure(element) else { continue }
                let id = "\(snapshot):\(index)"
                targets[id] = Target(element: element, pid: app.processIdentifier)
                var row: [String: Any] = ["element_id": id, "role": string(element, kAXRoleAttribute) ?? "unknown"]
                for (label, key) in [("title", kAXTitleAttribute), ("description", kAXDescriptionAttribute), ("value", kAXValueAttribute)] {
                    if let value = string(element, key) {
                        row[label] = String(value.prefix(1000))
                        if value.count > 1000 { row[label + "_truncated"] = true }
                    }
                }
                rows.append(row)
                if let children = attribute(element, kAXChildrenAttribute) as? [AXUIElement] {
                    queue.append(contentsOf: children.prefix(max(0, 1000 - queue.count)))
                }
            }
            let payload: [String: Any] = ["app": args["app"]!, "elements": rows, "truncated": index < queue.count]
            return AgentToolResult(success: true, output: String(decoding: try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys]), as: UTF8.self))
        case "grab_text", "copy_text":
            let value = try text(target(args["element_id"]!), scope: args["scope"]!)
            if name == "copy_text" { try setClipboard(value) }
            return AgentToolResult(success: true, output: value)
        case "paste_text":
            let destination = try target(args["element_id"]!)
            let before = try text(destination, scope: "value")
            guard AgentTextTransfer.identical(before, args["expected_value"]!) else {
                throw AgentFailure("Destination changed; reread it before pasting.")
            }
            let insertion = args["text"]!
            guard insertion.utf8.count <= 262_144 else { throw AgentFailure("Paste exceeds 256 KB.") }
            let range = try selection(destination.element)
            let expected = try AgentTextTransfer.replacingSelection(in: before, range: range, with: insertion)
            guard let app = NSRunningApplication(processIdentifier: destination.pid), app.activate(options: []) else {
                throw AgentFailure("Cannot activate destination application; paste was not attempted.")
            }
            guard AXUIElementSetAttributeValue(destination.element, kAXFocusedAttribute as CFString, kCFBooleanTrue) == .success else {
                throw AgentFailure("Cannot focus destination; paste was not attempted.")
            }
            try await Task.sleep(nanoseconds: 150_000_000)
            let root = AXUIElementCreateApplication(destination.pid)
            guard NSWorkspace.shared.frontmostApplication?.processIdentifier == destination.pid,
                  let focused = attribute(root, kAXFocusedUIElementAttribute), CFEqual(focused, destination.element),
                  AgentTextTransfer.identical(try text(destination, scope: "value"), before) else {
                throw AgentFailure("Destination focus or content changed; paste was not attempted.")
            }
            let currentRange = try selection(destination.element)
            guard currentRange.location == range.location, currentRange.length == range.length else {
                throw AgentFailure("Selection changed; paste was not attempted.")
            }
            try Task.checkCancellation()
            guard let down = CGEvent(keyboardEventSource: nil, virtualKey: 9, keyDown: true),
                  let up = CGEvent(keyboardEventSource: nil, virtualKey: 9, keyDown: false) else { throw AgentFailure("Cannot create paste events.") }
            try setClipboard(insertion)
            down.flags = .maskCommand; up.flags = .maskCommand
            down.postToPid(destination.pid); up.postToPid(destination.pid)
            // Leave the inserted text on the clipboard; restoring it early can race the target app.
            for _ in 0..<20 {
                try await Task.sleep(nanoseconds: 100_000_000)
                if let actual = try? text(destination, scope: "value"), AgentTextTransfer.identical(actual, expected) {
                    return AgentToolResult(success: true, output: "Paste verified against the destination's exact text value.")
                }
            }
            return AgentToolResult(success: false, output: "Paste was sent but exact destination text could not be verified. Outcome unknown: reread the field before any further edit; do not blindly repeat paste.")
        default: throw AgentFailure("Unknown desktop tool.")
        }
    }
}
