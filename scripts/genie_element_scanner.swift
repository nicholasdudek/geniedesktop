import Cocoa
import ApplicationServices

let screen = NSScreen.main?.frame ?? CGRect(x: 0, y: 0, width: 1800, height: 1169)
let screenWidth = Double(screen.width)
let screenHeight = Double(screen.height)

guard let windowListInfo = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
    print("[]")
    exit(0)
}

var pidsSeen = Set<pid_t>()
var targetPids: [pid_t] = []

// Frontmost app first
if let frontApp = NSWorkspace.shared.frontmostApplication {
    let pid = frontApp.processIdentifier
    pidsSeen.insert(pid)
    targetPids.append(pid)
}

// On-screen visible apps
for win in windowListInfo {
    let layer = win[kCGWindowLayer as String] as? Int ?? 0
    let alpha = win[kCGWindowAlpha as String] as? Double ?? 1.0
    guard layer == 0, alpha > 0.1 else { continue }
    if let pid = win[kCGWindowOwnerPID as String] as? pid_t {
        if !pidsSeen.contains(pid) {
            pidsSeen.insert(pid)
            targetPids.append(pid)
            if targetPids.count >= 4 { break }
        }
    }
}

var elements: [[String: Any]] = []

func scan(element: AXUIElement, depth: Int = 0) {
    if depth > 10 || elements.count >= 65 { return }
    var roleRef: AnyObject?
    AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleRef)
    let role = (roleRef as? String) ?? ""
    
    var subroleRef: AnyObject?
    AXUIElementCopyAttributeValue(element, kAXSubroleAttribute as CFString, &subroleRef)
    let subrole = (subroleRef as? String) ?? ""
    
    // Determine if element is an enterable text field
    var isTextInput = false
    if ["AXTextField", "AXSearchField", "AXComboBox", "AXSecureTextField"].contains(role) || subrole.contains("Search") {
        isTextInput = true
    } else if role == "AXTextArea" {
        var isSettable: DarwinBoolean = false
        if AXUIElementIsAttributeSettable(element, kAXValueAttribute as CFString, &isSettable) == .success && isSettable.boolValue {
            isTextInput = true
        } else if subrole.contains("Text") || subrole.contains("Shell") {
            isTextInput = true
        }
    }
    
    let isClickable = [
        "AXButton",
        "AXPopUpButton",
        "AXLink",
        "AXRadioButton",
        "AXCheckBox",
        "AXTabButton",
        "AXMenuButton"
    ].contains(role)
    
    if isTextInput || isClickable {
        var posRef: AnyObject?
        var sizeRef: AnyObject?
        if AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &posRef) == .success,
           AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeRef) == .success {
            var point = CGPoint.zero
            var size = CGSize.zero
            if let pVal = posRef as! AXValue?, let sVal = sizeRef as! AXValue? {
                AXValueGetValue(pVal, .cgPoint, &point)
                AXValueGetValue(sVal, .cgSize, &size)
                
                let px = Double(point.x)
                let py = Double(point.y)
                let pw = Double(size.width)
                let ph = Double(size.height)
                
                // Exclude full-height scrollbars and offscreen items
                let isScrollbar = (pw <= 18 && ph > 200) || (ph <= 18 && pw > 400)
                
                if !isScrollbar && pw >= 12 && ph >= 12 &&
                   px + pw > 10 && py + ph > 10 &&
                   px < screenWidth - 10 && py < screenHeight - 10 &&
                   pw <= screenWidth && ph <= screenHeight {
                    
                    var titleRef: AnyObject?
                    AXUIElementCopyAttributeValue(element, kAXTitleAttribute as CFString, &titleRef)
                    var descRef: AnyObject?
                    AXUIElementCopyAttributeValue(element, kAXDescriptionAttribute as CFString, &descRef)
                    var valRef: AnyObject?
                    AXUIElementCopyAttributeValue(element, kAXValueAttribute as CFString, &valRef)
                    var helpRef: AnyObject?
                    AXUIElementCopyAttributeValue(element, kAXHelpAttribute as CFString, &helpRef)
                    var placeholderRef: AnyObject?
                    AXUIElementCopyAttributeValue(element, "AXPlaceholderValue" as CFString, &placeholderRef)
                    
                    let title = (titleRef as? String) ?? ""
                    let desc = (descRef as? String) ?? ""
                    let val = (valRef as? String) ?? ""
                    let help = (helpRef as? String) ?? ""
                    let placeholder = (placeholderRef as? String) ?? ""
                    
                    var label = ""
                    if !title.isEmpty { label = title }
                    else if !placeholder.isEmpty { label = placeholder }
                    else if !desc.isEmpty { label = desc }
                    else if !help.isEmpty { label = help }
                    else if isTextInput && !val.isEmpty && val.count < 30 { label = val }
                    else if isTextInput { label = "Text Field" }
                    
                    let clampX = max(0, min(screenWidth, px))
                    let clampY = max(0, min(screenHeight, py))
                    let clampW = min(screenWidth - clampX, pw)
                    let clampH = min(screenHeight - clampY, ph)
                    
                    let cx = clampX + clampW / 2.0
                    let cy = clampY + clampH / 2.0
                    
                    elements.append([
                        "id": elements.count,
                        "type": isTextInput ? "text_input" : "button",
                        "role": role,
                        "x": round(clampX * 10) / 10,
                        "y": round(clampY * 10) / 10,
                        "w": round(clampW * 10) / 10,
                        "h": round(clampH * 10) / 10,
                        "cx": round(cx * 10) / 10,
                        "cy": round(cy * 10) / 10,
                        "rx": round((clampX / screenWidth) * 10000) / 10000,
                        "ry": round((clampY / screenHeight) * 10000) / 10000,
                        "rw": round((clampW / screenWidth) * 10000) / 10000,
                        "rh": round((clampH / screenHeight) * 10000) / 10000,
                        "label": String(label.trimmingCharacters(in: .whitespacesAndNewlines).prefix(28))
                    ])
                }
            }
        }
    }
    
    var childrenRef: AnyObject?
    if AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenRef) == .success,
       let children = childrenRef as? [AXUIElement] {
        for child in children {
            scan(element: child, depth: depth + 1)
        }
    }
}

for pid in targetPids {
    let axApp = AXUIElementCreateApplication(pid)
    scan(element: axApp)
    if elements.count >= 65 { break }
}

// Sort so text inputs come first, then buttons with labels, then other buttons
elements.sort { a, b in
    let typeA = a["type"] as? String ?? ""
    let typeB = b["type"] as? String ?? ""
    if typeA != typeB {
        return typeA == "text_input"
    }
    let labelA = a["label"] as? String ?? ""
    let labelB = b["label"] as? String ?? ""
    return !labelA.isEmpty && labelB.isEmpty
}

for i in 0..<elements.count {
    elements[i]["id"] = i
}

if let data = try? JSONSerialization.data(withJSONObject: elements, options: []) {
    let json = String(data: data, encoding: .utf8) ?? "[]"
    print(json)
}
