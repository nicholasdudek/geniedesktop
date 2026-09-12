import Foundation
import CoreGraphics
import AppKit
import ApplicationServices

// MARK: - Native macOS OS Agent Controller
// Translates the agent's Python logic into native Swift CoreGraphics for zero-latency execution.

public class GenieOSAgent {
    public static let shared = GenieOSAgent()
    
    // MARK: - 1. Screen Capture (Vision Input)
    public func captureScreen(outputPath: String = "/tmp/agent_screen.png") -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        process.arguments = ["-x", outputPath]
        
        do {
            try process.run()
            process.waitUntilExit()
            return outputPath
        } catch {
            print("Failed to capture screen: \(error)")
            return nil
        }
    }
    
    // MARK: - 2. Mouse Move (Absolute Coordinates)
    public func mouseMove(x: CGFloat, y: CGFloat) {
        let point = CGPoint(x: x, y: y)
        if let event = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: point, mouseButton: .left) {
            event.post(tap: .cghidEventTap)
        }
    }
    
    // MARK: - 3. Mouse Click
    public func mouseClick(x: CGFloat, y: CGFloat, button: String = "left") {
        let point = CGPoint(x: x, y: y)
        let downType: CGEventType = button == "left" ? .leftMouseDown : .rightMouseDown
        let upType: CGEventType = button == "left" ? .leftMouseUp : .rightMouseUp
        let mouseButton: CGMouseButton = button == "left" ? .left : .right
        
        if let downEvent = CGEvent(mouseEventSource: nil, mouseType: downType, mouseCursorPosition: point, mouseButton: mouseButton),
           let upEvent = CGEvent(mouseEventSource: nil, mouseType: upType, mouseCursorPosition: point, mouseButton: mouseButton) {
            
            downEvent.post(tap: .cghidEventTap)
            usleep(50_000) // 50ms human-like delay
            upEvent.post(tap: .cghidEventTap)
        }
    }
    
    // MARK: - 4. Mouse Double Click
    public func mouseDoubleClick(x: CGFloat, y: CGFloat, button: String = "left") {
        let point = CGPoint(x: x, y: y)
        let downType: CGEventType = button == "left" ? .leftMouseDown : .rightMouseDown
        let upType: CGEventType = button == "left" ? .leftMouseUp : .rightMouseUp
        let mouseButton: CGMouseButton = button == "left" ? .left : .right
        
        if let down1 = CGEvent(mouseEventSource: nil, mouseType: downType, mouseCursorPosition: point, mouseButton: mouseButton),
           let up1 = CGEvent(mouseEventSource: nil, mouseType: upType, mouseCursorPosition: point, mouseButton: mouseButton),
           let down2 = CGEvent(mouseEventSource: nil, mouseType: downType, mouseCursorPosition: point, mouseButton: mouseButton),
           let up2 = CGEvent(mouseEventSource: nil, mouseType: upType, mouseCursorPosition: point, mouseButton: mouseButton) {
            
            down1.setIntegerValueField(.mouseEventClickState, value: 1)
            up1.setIntegerValueField(.mouseEventClickState, value: 1)
            down1.post(tap: .cghidEventTap)
            usleep(40_000)
            up1.post(tap: .cghidEventTap)
            
            usleep(50_000)
            
            down2.setIntegerValueField(.mouseEventClickState, value: 2)
            up2.setIntegerValueField(.mouseEventClickState, value: 2)
            down2.post(tap: .cghidEventTap)
            usleep(40_000)
            up2.post(tap: .cghidEventTap)
        }
    }
    
    // MARK: - 5. Mouse Drag
    public func mouseDrag(fromX: CGFloat, fromY: CGFloat, toX: CGFloat, toY: CGFloat, steps: Int = 10) {
        let startPoint = CGPoint(x: fromX, y: fromY)
        let endPoint = CGPoint(x: toX, y: toY)
        
        if let down = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: startPoint, mouseButton: .left) {
            down.post(tap: .cghidEventTap)
        }
        usleep(30_000)
        
        let totalSteps = max(1, steps)
        for i in 1...totalSteps {
            let t = CGFloat(i) / CGFloat(totalSteps)
            let curX = fromX + (toX - fromX) * t
            let curY = fromY + (toY - fromY) * t
            let pt = CGPoint(x: curX, y: curY)
            if let drag = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDragged, mouseCursorPosition: pt, mouseButton: .left) {
                drag.post(tap: .cghidEventTap)
            }
            usleep(15_000)
        }
        
        if let up = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: endPoint, mouseButton: .left) {
            up.post(tap: .cghidEventTap)
        }
    }
    
    // MARK: - 6. Mouse Scroll
    public func mouseScroll(deltaX: Int32 = 0, deltaY: Int32 = 0) {
        if let scrollEvent = CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 2, wheel1: deltaY, wheel2: deltaX, wheel3: 0) {
            scrollEvent.post(tap: .cghidEventTap)
        }
    }
    
    // MARK: - 7. Keyboard Type
    public func typeText(_ text: String) {
        let escaped = text.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
        let script = "tell application \"System Events\" to keystroke \"\(escaped)\""
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        try? process.run()
    }
    
    // MARK: - 8. Keyboard Hotkey
    public func keyboardHotkey(key: String, modifiers: [String] = []) {
        var modStr = ""
        if !modifiers.isEmpty {
            let formatted = modifiers.map { "\($0) down" }.joined(separator: ", ")
            modStr = " using {\(formatted)}"
        }
        let script: String
        if let keyCode = Int(key) {
            script = "tell application \"System Events\" to key code \(keyCode)\(modStr)"
        } else {
            let escaped = key.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
            script = "tell application \"System Events\" to keystroke \"\(escaped)\"\(modStr)"
        }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        try? process.run()
    }
    
    // MARK: - 9. Active Window Inspection
    public func getActiveWindow() -> [String: Any] {
        guard let frontApp = NSWorkspace.shared.frontmostApplication else {
            return ["status": "error", "message": "No frontmost application found"]
        }
        var info: [String: Any] = [
            "status": "success",
            "app_name": frontApp.localizedName ?? "Unknown",
            "bundle_id": frontApp.bundleIdentifier ?? "",
            "pid": frontApp.processIdentifier
        ]
        
        if let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] {
            for win in windowList {
                if let ownerPID = win[kCGWindowOwnerPID as String] as? pid_t, ownerPID == frontApp.processIdentifier {
                    if let name = win[kCGWindowName as String] as? String, !name.isEmpty {
                        info["window_name"] = name
                    }
                    if let bounds = win[kCGWindowBounds as String] as? [String: Any] {
                        info["bounds"] = bounds
                    }
                    break
                }
            }
        }
        return info
    }
    
    // MARK: - 10. Accessibility Tree Inspection
    public func dumpAccessibilityTree(maxDepth: Int = 3) -> [String: Any] {
        let systemWide = AXUIElementCreateSystemWide()
        var focusedApp: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(systemWide, kAXFocusedApplicationAttribute as CFString, &focusedApp)
        guard result == .success, let appElement = focusedApp else {
            return ["status": "error", "message": "Accessibility permission not granted or no focused application"]
        }
        let tree = serializeAXElement(appElement as! AXUIElement, depth: 0, maxDepth: maxDepth)
        return ["status": "success", "tree": tree]
    }
    
    private func serializeAXElement(_ element: AXUIElement, depth: Int, maxDepth: Int) -> [String: Any] {
        var dict: [String: Any] = [:]
        
        var role: CFTypeRef?
        if AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &role) == .success, let roleStr = role as? String {
            dict["role"] = roleStr
        }
        
        var title: CFTypeRef?
        if AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &title) == .success, let titleStr = title as? String, !titleStr.isEmpty {
            dict["title"] = titleStr
        }
        
        var value: CFTypeRef?
        if AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &value) == .success, let valStr = value as? String, !valStr.isEmpty {
            dict["value"] = valStr
        }
        
        if depth < maxDepth {
            var children: CFTypeRef?
            if AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &children) == .success, let childArray = children as? [AXUIElement] {
                let serializedChildren = childArray.prefix(15).map { serializeAXElement($0, depth: depth + 1, maxDepth: maxDepth) }
                dict["children"] = serializedChildren
            }
        }
        return dict
    }
    
    // MARK: - 11. Find UI Elements
    public func findUIElements(query: String) -> [[String: Any]] {
        let dump = dumpAccessibilityTree(maxDepth: 4)
        guard let tree = dump["tree"] as? [String: Any] else { return [] }
        var matches: [[String: Any]] = []
        let lowerQuery = query.lowercased()
        
        func traverse(node: [String: Any]) {
            let title = (node["title"] as? String)?.lowercased() ?? ""
            let role = (node["role"] as? String)?.lowercased() ?? ""
            let value = (node["value"] as? String)?.lowercased() ?? ""
            
            if title.contains(lowerQuery) || role.contains(lowerQuery) || value.contains(lowerQuery) {
                matches.append([
                    "role": node["role"] ?? "",
                    "title": node["title"] ?? "",
                    "value": node["value"] ?? ""
                ])
            }
            if let children = node["children"] as? [[String: Any]] {
                for child in children {
                    traverse(node: child)
                }
            }
        }
        traverse(node: tree)
        return matches
    }
    
    // MARK: - 12. Dynamic Tool Introspection
    public func discoverSystemTools(category: String = "all") -> [String: Any] {
        let allTools: [String: [String]] = [
            "screen_control": [
                "capture_screen",
                "mouse_click",
                "mouse_double_click",
                "mouse_drag",
                "mouse_scroll",
                "keyboard_type",
                "keyboard_hotkey"
            ],
            "ui_inspection": [
                "dump_accessibility_tree",
                "find_ui_elements",
                "get_active_window"
            ],
            "vm_terminal": [
                "bash_execute",
                "list_directory",
                "read_file",
                "write_file"
            ],
            "creative_shadow_apis": [
                "adobe_suite_expert_injection",
                "final_cut_pro_genius_edit",
                "query_local_imessage_history",
                "semantic_local_file_search"
            ]
        ]
        
        if category == "all" {
            return ["status": "available", "categories": allTools, "platform": "macOS (Apple Silicon)"]
        } else if let tools = allTools[category] {
            return ["status": "available", "category": category, "tools": tools, "platform": "macOS (Apple Silicon)"]
        } else {
            let matches = allTools.values.flatMap { $0 }.filter { $0.contains(category) }
            return ["status": "available", "matching_tools": matches, "platform": "macOS (Apple Silicon)"]
        }
    }
    
    // MARK: - 13. System Pre-flight Check (Permissions)
    public func checkPermissions() -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        return accessEnabled
    }
}
