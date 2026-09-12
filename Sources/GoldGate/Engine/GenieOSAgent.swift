import Foundation
import CoreGraphics
import AppKit

// MARK: - Native macOS OS Agent Controller
// Translates the agent's Python logic into native Swift CoreGraphics for zero-latency execution.

public class GenieOSAgent {
    public static let shared = GenieOSAgent()
    
    /// 1. Screen Capture (Vision Input)
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
    
    /// 2. Mouse Move (Absolute Coordinates)
    public func mouseMove(x: CGFloat, y: CGFloat) {
        let point = CGPoint(x: x, y: y)
        if let event = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: point, mouseButton: .left) {
            event.post(tap: .cghidEventTap)
        }
    }
    
    /// 3. Mouse Click
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
    
    /// 4. Keyboard Type
    public func typeText(_ text: String) {
        let escaped = text.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
        let script = "tell application \"System Events\" to keystroke \"\(escaped)\""
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
        process.arguments = ["-e", script]
        try? process.run()
    }
    
    /// 5. System Pre-flight Check (Permissions)
    public func checkPermissions() -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : true]
        let accessEnabled = AXIsProcessTrustedWithOptions(options)
        return accessEnabled
    }
}
