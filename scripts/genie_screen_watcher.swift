import Cocoa
import ApplicationServices

let TARGET_PROCESSES: Set<String> = [
    "FaceTime",
    "NotificationCenter",
    "UserNotificationCenter",
    "CoreServicesUIAgent",
    "ControlCenter",
    "ScreenSharing",
    "screencaptureui",
    "FaceTimeNotificationExtension",
    "FaceTimeNotificationViewBridgeService"
]

let POSITIVE_KEYWORDS: [String] = [
    "share entire screen",
    "share screen",
    "share window",
    "share",
    "give control",
    "allow control",
    "grant control",
    "allow remote control",
    "allow",
    "accept",
    "join",
    "yes"
]

let NEGATIVE_KEYWORDS: [String] = [
    "don't allow",
    "dont allow",
    "not now",
    "decline",
    "cancel",
    "close",
    "mute",
    "end call",
    "leave",
    "stop sharing",
    "stop control"
]

func log(_ message: String) {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    let timestamp = formatter.string(from: Date())
    print("[\(timestamp)] [ScreenWatcher] \(message)")
    fflush(stdout)
}

func matchesTarget(text: String) -> Bool {
    let lower = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
    if lower.isEmpty { return false }
    
    // Reject negative keywords
    for neg in NEGATIVE_KEYWORDS {
        if lower == neg || lower.contains(neg) {
            return false
        }
    }
    
    // Accept positive keywords
    for pos in POSITIVE_KEYWORDS {
        if lower == pos || lower.contains(pos) {
            return true
        }
    }
    return false
}

func scanAndPress(element: AXUIElement, depth: Int = 0) -> Bool {
    if depth > 10 { return false }
    
    var roleRef: AnyObject?
    AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleRef)
    let role = (roleRef as? String) ?? ""
    
    if role == kAXButtonRole as String || role == "AXMenuItem" {
        var titleRef: AnyObject?
        AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &titleRef)
        var descRef: AnyObject?
        AXUIElementCopyAttributeValue(element, kAXDescriptionAttribute as CFString, &descRef)
        
        let title = (titleRef as? String) ?? ""
        let desc = (descRef as? String) ?? ""
        
        if matchesTarget(text: title) || matchesTarget(text: desc) {
            let matchedText = !title.isEmpty ? title : desc
            log("🎯 Target button detected: '\(matchedText)' (title='\(title)', desc='\(desc)')")
            
            let pressRes = AXUIElementPerformAction(element, kAXPressAction as CFString)
            if pressRes == .success {
                log("✅ Successfully pressed button: '\(matchedText)'")
                return true
            } else {
                log("⚠️ AXPress returned: \(pressRes.rawValue), attempting fallback click")
                var posRef: AnyObject?
                var sizeRef: AnyObject?
                if AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &posRef) == .success,
                   AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeRef) == .success {
                    var point = CGPoint.zero
                    var size = CGSize.zero
                    if let valPoint = posRef as! AXValue?, let valSize = sizeRef as! AXValue? {
                        AXValueGetValue(valPoint, .cgPoint, &point)
                        AXValueGetValue(valSize, .cgSize, &size)
                        let clickPoint = CGPoint(x: point.x + size.width / 2, y: point.y + size.height / 2)
                        let clickDown = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: clickPoint, mouseButton: .left)
                        let clickUp = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: clickPoint, mouseButton: .left)
                        clickDown?.post(tap: .cghidEventTap)
                        clickUp?.post(tap: .cghidEventTap)
                        log("🖱️ Dispatched synthetic click to (\(clickPoint.x), \(clickPoint.y))")
                        return true
                    }
                }
            }
        }
    }
    
    var childrenRef: AnyObject?
    if AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenRef) == .success,
       let children = childrenRef as? [AXUIElement] {
        for child in children {
            if scanAndPress(element: child, depth: depth + 1) {
                return true
            }
        }
    }
    
    return false
}

func checkAllTargets() -> Bool {
    let runningApps = NSWorkspace.shared.runningApplications
    for app in runningApps {
        guard let name = app.localizedName, TARGET_PROCESSES.contains(name) else {
            continue
        }
        
        let pid = app.processIdentifier
        let axApp = AXUIElementCreateApplication(pid)
        
        // 1. Check all windows
        var windowsRef: AnyObject?
        if AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &windowsRef) == .success,
           let windows = windowsRef as? [AXUIElement] {
            for win in windows {
                if scanAndPress(element: win) {
                    return true
                }
            }
        }
        
        // 2. Check menu bars
        var menuBarRef: AnyObject?
        if AXUIElementCopyAttributeValue(axApp, kAXMenuBarAttribute as CFString, &menuBarRef) == .success,
           let mb = menuBarRef {
            if scanAndPress(element: mb as! AXUIElement) {
                return true
            }
        }
        
        // 3. Check app root element
        if scanAndPress(element: axApp) {
            return true
        }
    }
    return false
}

let args = CommandLine.arguments
if args.contains("--once") {
    let found = checkAllTargets()
    exit(found ? 0 : 1)
}

log("🚀 Genie Screen Share & Remote Control Watcher ONLINE")
log("   Watching for invites, screen share requests, and remote control grants...")

while true {
    _ = checkAllTargets()
    usleep(500000) // 0.5s interval
}
