// AXUIElement accessibility automation and NSApplication-level UI control have no
// iOS equivalent (no cross-app UI tree, no CGEvent injection) — this entire file
// is macOS-only. See AgentToolCatalog.platformUnavailable in AgentTypes.swift for
// the catalog-side half of this gate.
#if os(macOS)
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
        guard let swiftRange = Range(nsRange, in: value),
              swiftRange.lowerBound.samePosition(in: value) != nil,
              swiftRange.upperBound.samePosition(in: value) != nil else {
            throw AgentFailure("Selection splits a Unicode character.")
        }
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
        case "desktop_agent":
            return try await performDesktop(args)
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

    // MARK: - desktop_agent
    //
    // Separate from the read_ui/copy_text/paste_text family above: those act on one
    // Accessibility element the model already identified, these post raw HID events at
    // screen coordinates, so they work even on apps with no usable accessibility tree.

    private static let keyCodes: [String: CGKeyCode] = [
        "a": 0x00, "s": 0x01, "d": 0x02, "f": 0x03, "h": 0x04, "g": 0x05, "z": 0x06, "x": 0x07,
        "c": 0x08, "v": 0x09, "b": 0x0B, "q": 0x0C, "w": 0x0D, "e": 0x0E, "r": 0x0F, "y": 0x10,
        "t": 0x11, "1": 0x12, "2": 0x13, "3": 0x14, "4": 0x15, "6": 0x16, "5": 0x17, "9": 0x19,
        "7": 0x1A, "8": 0x1C, "0": 0x1D, "o": 0x1F, "u": 0x20, "i": 0x22, "p": 0x23, "l": 0x25,
        "j": 0x26, "k": 0x28, "n": 0x2D, "m": 0x2E, "return": 0x24, "tab": 0x30, "space": 0x31,
        "delete": 0x33, "escape": 0x35, "up": 0x7E, "down": 0x7D, "left": 0x7B, "right": 0x7C,
    ]

    /// Resolves a bundle ID or display name through LaunchServices and launches it.
    /// Mirrors `GenieNativeSystem.launchApplication(named:)` on the host side.
    private func launchApplication(named name: String) async throws -> Bool {
        let bare = name.hasSuffix(".app") ? String(name.dropLast(4)) : name
        if let running = NSWorkspace.shared.runningApplications
            .first(where: { $0.bundleIdentifier == name || $0.localizedName == bare }) {
            return running.activate()
        }
        var appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: name)
        if appURL == nil {
            let roots = ["/Applications", "/Applications/Utilities",
                         "/System/Applications", "/System/Applications/Utilities",
                         NSHomeDirectory() + "/Applications"]
            appURL = roots.lazy
                .map { URL(fileURLWithPath: $0 + "/" + bare + ".app") }
                .first { FileManager.default.fileExists(atPath: $0.path) }
        }
        guard let appURL else { return false }
        _ = try await NSWorkspace.shared.openApplication(
            at: appURL, configuration: NSWorkspace.OpenConfiguration())
        return true
    }

    private func point(_ args: [String: String], _ xKey: String = "x", _ yKey: String = "y") throws -> CGPoint {
        guard let x = Double(args[xKey] ?? ""), let y = Double(args[yKey] ?? "") else {
            throw AgentFailure("\(xKey)/\(yKey) must be numbers.")
        }
        return CGPoint(x: x, y: y)
    }

    private func postClick(at location: CGPoint, button: CGMouseButton, downType: CGEventType, upType: CGEventType) throws {
        guard let down = CGEvent(mouseEventSource: nil, mouseType: downType, mouseCursorPosition: location, mouseButton: button),
              let up = CGEvent(mouseEventSource: nil, mouseType: upType, mouseCursorPosition: location, mouseButton: button) else {
            throw AgentFailure("Cannot create mouse events.")
        }
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
    }

    private func performDesktop(_ args: [String: String]) async throws -> AgentToolResult {
        guard let action = args["action"] else { throw AgentFailure("action is required.") }
        switch action {
        case "open":
            guard let name = args["app"] else { throw AgentFailure("app is required.") }
            // LaunchServices rather than /usr/bin/open: same result, no subprocess,
            // and it still works under the App Store sandbox, where spawning a
            // binary outside the app bundle does not.
            guard try await launchApplication(named: name) else {
                throw AgentFailure("Could not open \(name); check the app name.")
            }
            return AgentToolResult(success: true, output: "Opened \(name).")
        case "move":
            let location = try point(args)
            guard let event = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: location, mouseButton: .left) else {
                throw AgentFailure("Cannot create move event.")
            }
            event.post(tap: .cghidEventTap)
            return AgentToolResult(success: true, output: "Moved to \(location).")
        case "click", "double_click", "right_click":
            let location = try point(args)
            let button: CGMouseButton = action == "right_click" ? .right : .left
            let (downType, upType): (CGEventType, CGEventType) = action == "right_click" ? (.rightMouseDown, .rightMouseUp) : (.leftMouseDown, .leftMouseUp)
            try postClick(at: location, button: button, downType: downType, upType: upType)
            if action == "double_click" { try postClick(at: location, button: button, downType: downType, upType: upType) }
            return AgentToolResult(success: true, output: "\(action) at \(location).")
        case "drag":
            let from = try point(args, "x", "y")
            let to = try point(args, "x2", "y2")
            guard let down = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: from, mouseButton: .left),
                  let drag = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDragged, mouseCursorPosition: to, mouseButton: .left),
                  let up = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: to, mouseButton: .left) else {
                throw AgentFailure("Cannot create drag events.")
            }
            down.post(tap: .cghidEventTap)
            try await Task.sleep(nanoseconds: 30_000_000)
            drag.post(tap: .cghidEventTap)
            try await Task.sleep(nanoseconds: 30_000_000)
            up.post(tap: .cghidEventTap)
            return AgentToolResult(success: true, output: "Dragged from \(from) to \(to).")
        case "scroll":
            let dx = Int32(Double(args["dx"] ?? "0") ?? 0), dy = Int32(Double(args["dy"] ?? "0") ?? 0)
            guard let event = CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 2, wheel1: dy, wheel2: dx, wheel3: 0) else {
                throw AgentFailure("Cannot create scroll event.")
            }
            event.post(tap: .cghidEventTap)
            return AgentToolResult(success: true, output: "Scrolled dx=\(dx) dy=\(dy).")
        case "type":
            guard let text = args["text"] else { throw AgentFailure("text is required.") }
            guard let down = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true),
                  let up = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: false) else {
                throw AgentFailure("Cannot create keyboard events.")
            }
            let units = Array(text.utf16)
            down.keyboardSetUnicodeString(stringLength: units.count, unicodeString: units)
            up.keyboardSetUnicodeString(stringLength: units.count, unicodeString: units)
            down.post(tap: .cghidEventTap)
            up.post(tap: .cghidEventTap)
            return AgentToolResult(success: true, output: "Typed \(units.count) characters.")
        case "key":
            guard let combo = args["combo"]?.lowercased() else { throw AgentFailure("combo is required, e.g. cmd+s.") }
            var parts = combo.split(separator: "+").map(String.init)
            guard let keyName = parts.popLast(), let code = Self.keyCodes[keyName] else {
                throw AgentFailure("Unknown key in combo: \(combo).")
            }
            var flags: CGEventFlags = []
            for modifier in parts {
                switch modifier {
                case "cmd", "command": flags.insert(.maskCommand)
                case "shift": flags.insert(.maskShift)
                case "opt", "option", "alt": flags.insert(.maskAlternate)
                case "ctrl", "control": flags.insert(.maskControl)
                default: throw AgentFailure("Unknown modifier in combo: \(modifier).")
                }
            }
            guard let down = CGEvent(keyboardEventSource: nil, virtualKey: code, keyDown: true),
                  let up = CGEvent(keyboardEventSource: nil, virtualKey: code, keyDown: false) else {
                throw AgentFailure("Cannot create key events.")
            }
            down.flags = flags; up.flags = flags
            down.post(tap: .cghidEventTap)
            up.post(tap: .cghidEventTap)
            return AgentToolResult(success: true, output: "Sent \(combo).")
        case "snapshot":
            guard CGPreflightScreenCaptureAccess() else {
                throw AgentFailure("Enable Screen Recording access for Genie in System Settings, then retry.")
            }
            guard let image = CGWindowListCreateImage(.infinite, .optionOnScreenOnly, kCGNullWindowID, .bestResolution) else {
                throw AgentFailure("Screen capture returned no image.")
            }
            let bitmap = NSBitmapImageRep(cgImage: image)
            guard let jpeg = bitmap.representation(using: .jpeg, properties: [.compressionFactor: 0.6]) else {
                throw AgentFailure("Could not encode screenshot.")
            }
            guard jpeg.count <= 900_000 else {
                throw AgentFailure("Screenshot exceeds the inline size limit at full screen resolution.")
            }
            return AgentToolResult(success: true, output: jpeg.base64EncodedString())
        default:
            throw AgentFailure("Unknown desktop_agent action: \(action)")
        }
    }
}
#endif
