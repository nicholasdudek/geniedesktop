import AppKit
import CoreGraphics
import Foundation
import SwiftUI

// MARK: - Desktop Agent Action Instruction
public enum DesktopAgentAction: Equatable {
    case click(x: CGFloat, y: CGFloat, count: Int = 1, isRight: Bool = false)
    case clickText(target: String)
    case move(x: CGFloat, y: CGFloat)
    case type(text: String)
    case key(name: String, modifiers: [String] = [])
    case scroll(dx: Int32, dy: Int32)
    case drag(from: CGPoint, to: CGPoint)
    case openApp(name: String)
    case wait(seconds: Double)
    case record(seconds: Double)
    case snapshot
    case openiPhone
    case tapIPhone(x: CGFloat, y: CGFloat)
    case swipeHomeIPhone
    case swipeControlCenterIPhone
    case swipeNotificationCenterIPhone
    case snapshotIPhone
    case warp(x: CGFloat, y: CGFloat)
    case setCursorMode(mode: CursorMode)
    case splitDesktop(ratio: CGFloat?)
    case setWorkspace(slot: Int)

    public var summary: String {
        switch self {
        case .click(let x, let y, let count, let isRight):
            let kind = isRight ? "Right-Click" : (count > 1 ? "Double-Click" : "Click")
            return "\(kind) at (\(Int(x)), \(Int(y)))"
        case .clickText(let target):
            return "Find & Click \"\(target)\""
        case .move(let x, let y):
            return "Move cursor to (\(Int(x)), \(Int(y)))"
        case .type(let text):
            let preview = text.count > 25 ? "\(text.prefix(22))..." : text
            return "Type \"\(preview)\""
        case .key(let name, let mods):
            let modStr = mods.isEmpty ? "" : mods.joined(separator: "+") + "+"
            return "Press \(modStr)\(name.capitalized)"
        case .scroll(let dx, let dy):
            return "Scroll (dx: \(dx), dy: \(dy))"
        case .drag(let from, let to):
            return "Drag from (\(Int(from.x)), \(Int(from.y))) to (\(Int(to.x)), \(Int(to.y)))"
        case .openApp(let name):
            return "Launch application \"\(name)\""
        case .wait(let sec):
            return "Wait \(String(format: "%.1f", sec))s"
        case .record(let sec):
            return "Record screen for \(Int(sec))s"
        case .snapshot:
            return "Capture screen polaroid"
        case .openiPhone:
            return "Activate iPhone Screen Mirroring"
        case .tapIPhone(let x, let y):
            return "Touch Tap iPhone at (\(Int(x)), \(Int(y)))"
        case .swipeHomeIPhone:
            return "Swipe iPhone Home Indicator"
        case .swipeControlCenterIPhone:
            return "Swipe iPhone Control Center"
        case .swipeNotificationCenterIPhone:
            return "Swipe iPhone Notification Center"
        case .snapshotIPhone:
            return "Capture iPhone Screen Frame"
        case .warp(let x, let y):
            return "2028 Warp Jump to (\(Int(x)), \(Int(y)))"
        case .setCursorMode(let mode):
            return "Set Cursor Mode: \(mode.badgeTitle)"
        case .splitDesktop(let ratio):
            let rStr = ratio != nil ? " at \(Int((ratio ?? 0.5) * 100))%" : ""
            return "Split Desktop into 2 Workspaces\(rStr)"
        case .setWorkspace(let slot):
            return "Target Agent Workspace \(slot == 0 ? "A" : "B")"
        }
    }
}

// MARK: - Antigravity Desktop Autonomous Agent
@MainActor
public final class AntigravityDesktopAgent: ObservableObject {
    public static let shared = AntigravityDesktopAgent()

    // ── Live Execution Telemetry ──────────────────────────────────────────
    @Published public var isExecuting: Bool = false
    @Published public var currentStepText: String = "Ready"
    @Published public var stepIndex: Int = 0
    @Published public var totalSteps: Int = 0
    @Published public var currentCursorPosition: CGPoint = .zero
    @Published public var clickRipplePosition: CGPoint? = nil
    @Published public var isCancelled: Bool = false

    private var executionTask: Task<Void, Never>?

    private init() {}

    // MARK: - Script Parser
    /// Parses high-level desktop agent commands from string blocks
    public func parseScript(from text: String) -> [DesktopAgentAction] {
        var actions: [DesktopAgentAction] = []
        let lines = text.components(separatedBy: .newlines)

        for rawLine in lines {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            if line.isEmpty || line.hasPrefix("#") || line.hasPrefix("//") || line.hasPrefix("```") || line.hasPrefix("~~~") {
                continue
            }

            let parts = line.split(separator: " ", maxSplits: 1).map(String.init)
            guard let verb = parts.first?.lowercased() else { continue }
            let args = parts.count > 1 ? parts[1].trimmingCharacters(in: .whitespacesAndNewlines) : ""

            switch verb {
            case "click":
                if args.hasPrefix("\"") && args.hasSuffix("\"") {
                    let target = String(args.dropFirst().dropLast())
                    actions.append(.clickText(target: target))
                } else {
                    let coords = parseCoordinates(args)
                    actions.append(.click(x: coords.x, y: coords.y))
                }
            case "double_click", "doubleclick":
                let coords = parseCoordinates(args)
                actions.append(.click(x: coords.x, y: coords.y, count: 2))
            case "right_click", "rightclick":
                let coords = parseCoordinates(args)
                actions.append(.click(x: coords.x, y: coords.y, count: 1, isRight: true))
            case "click_text", "clicktext", "find_click":
                let clean = args.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                actions.append(.clickText(target: clean))
            case "move":
                let coords = parseCoordinates(args)
                actions.append(.move(x: coords.x, y: coords.y))
            case "type":
                var content = args
                if content.hasPrefix("\"") && content.hasSuffix("\"") && content.count >= 2 {
                    content = String(content.dropFirst().dropLast())
                }
                actions.append(.type(text: content))
            case "key", "press":
                let keyTokens = args.components(separatedBy: "+").map { $0.trimmingCharacters(in: .whitespaces) }
                let keyName = keyTokens.last ?? "return"
                let mods = keyTokens.dropLast().map { $0.lowercased() }
                actions.append(.key(name: keyName, modifiers: mods))
            case "scroll":
                let deltas = parseScrollDeltas(args)
                actions.append(.scroll(dx: deltas.dx, dy: deltas.dy))
            case "drag":
                let (p1, p2) = parseDragPoints(args)
                actions.append(.drag(from: p1, to: p2))
            case "open", "launch", "app":
                let appName = args.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                actions.append(.openApp(name: appName))
            case "wait", "sleep":
                let sec = Double(args) ?? 1.0
                actions.append(.wait(seconds: sec))
            case "record":
                let sec = Double(args) ?? 5.0
                actions.append(.record(seconds: sec))
            case "snapshot", "polaroid":
                actions.append(.snapshot)
            case "open_iphone", "openiphone":
                actions.append(.openiPhone)
            case "tap", "touch":
                let coords = parseCoordinates(args)
                actions.append(.tapIPhone(x: coords.x, y: coords.y))
            case "swipe_home", "swipehome":
                actions.append(.swipeHomeIPhone)
            case "swipe_control_center", "control_center":
                actions.append(.swipeControlCenterIPhone)
            case "swipe_notification_center", "notification_center":
                actions.append(.swipeNotificationCenterIPhone)
            case "snapshot_iphone":
                actions.append(.snapshotIPhone)
            case "warp", "jump", "teleport":
                let coords = parseCoordinates(args)
                actions.append(.warp(x: coords.x, y: coords.y))
            case "skip_cursor", "cursor_skip":
                actions.append(.setCursorMode(mode: .skipCursor))
            case "duplicate_cursor", "multi_cursor", "phantom_cursor":
                actions.append(.setCursorMode(mode: .duplicateCursor))
            case "warp_cursor", "cursor_warp":
                actions.append(.setCursorMode(mode: .warpJump))
            case "split_desktop", "split_workspace", "dual_workspace":
                let ratio = Double(args).map { CGFloat($0) }
                actions.append(.splitDesktop(ratio: ratio))
            case "workspace", "set_workspace", "target_workspace":
                let slot = (args.lowercased().contains("b") || args.contains("1")) ? 1 : 0
                actions.append(.setWorkspace(slot: slot))
            default:
                break
            }
        }
        return actions
    }

    private func parseCoordinates(_ str: String) -> CGPoint {
        let cleaned = str.replacingOccurrences(of: "(", with: "").replacingOccurrences(of: ")", with: "")
        let parts = cleaned.components(separatedBy: CharacterSet(charactersIn: ", ")).filter { !$0.isEmpty }
        if parts.count >= 2, let x = Double(parts[0]), let y = Double(parts[1]) {
            return CGPoint(x: x, y: y)
        }
        return CGPoint(x: 500, y: 400)
    }

    private func parseScrollDeltas(_ str: String) -> (dx: Int32, dy: Int32) {
        let parts = str.components(separatedBy: CharacterSet(charactersIn: ", ")).filter { !$0.isEmpty }
        if parts.count >= 2, let dx = Int32(parts[0]), let dy = Int32(parts[1]) {
            return (dx, dy)
        } else if let first = parts.first {
            if first.lowercased() == "down" { return (0, 15) }
            if first.lowercased() == "up" { return (0, -15) }
            if let val = Int32(first) { return (0, val) }
        }
        return (0, 10)
    }

    private func parseDragPoints(_ str: String) -> (CGPoint, CGPoint) {
        let parts = str.components(separatedBy: " to ")
        if parts.count == 2 {
            return (parseCoordinates(parts[0]), parseCoordinates(parts[1]))
        }
        return (CGPoint(x: 200, y: 200), CGPoint(x: 600, y: 600))
    }

    // MARK: - Execution Engine
    public func executeScript(_ text: String) {
        let actions = parseScript(from: text)
        executeScript(actions)
    }

    public func executeScript(_ actions: [DesktopAgentAction]) {
        guard !actions.isEmpty else { return }

        // Cancel previous if active
        stopExecution()

        self.isExecuting = true
        self.isCancelled = false
        self.totalSteps = actions.count
        self.stepIndex = 0

        // Show the Antigravity Desktop Control Overlay HUD
        AntigravityDesktopControlWindow.shared.show()
        HapticFeedback.testWaterDrop()

        executionTask = Task { @MainActor in
            for (idx, action) in actions.enumerated() {
                if Task.isCancelled || self.isCancelled {
                    break
                }

                self.stepIndex = idx + 1
                self.currentStepText = "Step \(self.stepIndex)/\(self.totalSteps): \(action.summary)"

                await self.performAction(action)

                // Brief human pacing delay between operations
                try? await Task.sleep(nanoseconds: 350_000_000)
            }

            self.finishExecution()
        }
    }

    public func stopExecution() {
        self.isCancelled = true
        self.executionTask?.cancel()
        self.executionTask = nil
        self.isExecuting = false
        self.currentStepText = "Execution stopped by user."
        AntigravityDesktopControlWindow.shared.hide()
        HapticFeedback.heavy()

        NotificationCenter.default.post(
            name: NSNotification.Name("AntigravityDesktopExecutionStopped"),
            object: nil
        )
    }

    private func finishExecution() {
        self.isExecuting = false
        self.currentStepText = self.isCancelled ? "Execution stopped." : "All steps completed successfully."
        HapticFeedback.success()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            guard let self = self, !self.isExecuting else { return }
            AntigravityDesktopControlWindow.shared.hide()
        }
    }

    // MARK: - Action Dispatchers
    private func performAction(_ action: DesktopAgentAction) async {
        switch action {
        case .click(let x, let y, let count, let isRight):
            let pt = CGPoint(x: x, y: y)
            self.currentCursorPosition = pt
            self.triggerClickRipple(at: pt)
            synthesizeClick(at: pt, count: count, isRight: isRight)

        case .clickText(let target):
            await locateAndClickText(target)

        case .move(let x, let y):
            let pt = CGPoint(x: x, y: y)
            self.currentCursorPosition = pt
            synthesizeMouseMove(to: pt)

        case .type(let text):
            synthesizeType(text)

        case .key(let name, let mods):
            synthesizeKey(name: name, modifiers: mods)

        case .scroll(let dx, let dy):
            synthesizeScroll(dx: dx, dy: dy)

        case .drag(let from, let to):
            synthesizeDrag(from: from, to: to)

        case .openApp(let name):
            let ws = NSWorkspace.shared
            if let appURL = ws.urlForApplication(withBundleIdentifier: name) ?? ws.urlForApplication(withBundleIdentifier: "com.apple.\(name.lowercased())") {
                ws.openApplication(at: appURL, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
            } else {
                ws.open(URL(fileURLWithPath: "/System/Applications/\(name).app"))
            }
            try? await Task.sleep(nanoseconds: 600_000_000)

        case .wait(let seconds):
            let ns = UInt64(max(0.1, seconds) * 1_000_000_000)
            try? await Task.sleep(nanoseconds: ns)

        case .record(let seconds):
            DesktopScreenRecorder.shared.startRecording(duration: seconds)
            let ns = UInt64(seconds * 1_000_000_000)
            try? await Task.sleep(nanoseconds: ns)

        case .snapshot:
            DesktopScreenRecorder.shared.captureSnapshot()

        case .openiPhone:
            iPhoneMirrorManager.shared.launchOrActivateApp()
            try? await Task.sleep(nanoseconds: 800_000_000)

        case .tapIPhone(let x, let y):
            iPhoneMirrorManager.shared.refreshWindowInfo()
            let bounds = iPhoneMirrorManager.shared.windowBounds
            let pt: CGPoint
            if bounds.width > 50 && bounds.height > 100 {
                let screenX = bounds.origin.x + (x / 393.0) * bounds.width
                let screenY = bounds.origin.y + (y / 852.0) * bounds.height
                pt = CGPoint(x: screenX, y: screenY)
            } else {
                pt = CGPoint(x: x, y: y)
            }
            self.currentCursorPosition = pt
            self.triggerClickRipple(at: pt)
            synthesizeClick(at: pt, count: 1, isRight: false)

        case .swipeHomeIPhone:
            iPhoneMirrorManager.shared.refreshWindowInfo()
            let bounds = iPhoneMirrorManager.shared.windowBounds
            if bounds.width > 50 && bounds.height > 100 {
                let start = CGPoint(x: bounds.midX, y: bounds.maxY - 15)
                let end = CGPoint(x: bounds.midX, y: bounds.maxY - 140)
                synthesizeDrag(from: start, to: end)
            }

        case .swipeControlCenterIPhone:
            iPhoneMirrorManager.shared.refreshWindowInfo()
            let bounds = iPhoneMirrorManager.shared.windowBounds
            if bounds.width > 50 && bounds.height > 100 {
                let start = CGPoint(x: bounds.maxX - 30, y: bounds.minY + 20)
                let end = CGPoint(x: bounds.maxX - 30, y: bounds.minY + 220)
                synthesizeDrag(from: start, to: end)
            }

        case .swipeNotificationCenterIPhone:
            iPhoneMirrorManager.shared.refreshWindowInfo()
            let bounds = iPhoneMirrorManager.shared.windowBounds
            if bounds.width > 50 && bounds.height > 100 {
                let start = CGPoint(x: bounds.minX + 40, y: bounds.minY + 20)
                let end = CGPoint(x: bounds.minX + 40, y: bounds.minY + 220)
                synthesizeDrag(from: start, to: end)
            }

        case .snapshotIPhone:
            iPhoneMirrorManager.shared.saveToPolaroid()

        case .warp(let x, let y):
            let pt = CGPoint(x: x, y: y)
            self.currentCursorPosition = pt
            GenieCursorEngine2028.shared.warpCursor(to: pt)
            self.triggerClickRipple(at: pt)

        case .setCursorMode(let mode):
            GenieCursorEngine2028.shared.activeMode = mode

        case .splitDesktop(let ratio):
            DualWorkspaceSplitManager.shared.isSplitActive = true
            if let r = ratio {
                DualWorkspaceSplitManager.shared.setRatio(r)
            }

        case .setWorkspace(let slot):
            let targetName = (slot == 0) ? DualWorkspaceSplitManager.shared.slotA.agentName : DualWorkspaceSplitManager.shared.slotB.agentName
            self.currentStepText = "Active on \(targetName)"
        }
    }

    // MARK: - Computer Vision Optical Text Locator
    private func locateAndClickText(_ targetText: String) async {
        self.currentStepText = "Scanning display with Apple Vision for \"\(targetText)\"..."
        let _ = await GenieVisionEngine.shared.scanActiveScreenAndRecognize()
        let boxes = GenieVisionEngine.shared.recognizedBoxes

        let cleanTarget = targetText.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)

        // Match fuzzy or exact
        if let match = boxes.first(where: { $0.text.lowercased().contains(cleanTarget) }) {
            guard let screen = NSScreen.main else { return }
            let sWidth = screen.frame.width
            let sHeight = screen.frame.height

            // Apple Vision coordinates: (0,0) is bottom-left
            // Quartz CGEvent coordinates: (0,0) is top-left
            let normX = match.boundingBox.midX
            let normY = match.boundingBox.midY

            let screenX = screen.frame.origin.x + (normX * sWidth)
            let screenY = (screen.frame.origin.y + sHeight) - (normY * sHeight)

            let clickPt = CGPoint(x: screenX, y: screenY)
            self.currentCursorPosition = clickPt
            self.currentStepText = "Found \"\(match.text)\" at (\(Int(screenX)), \(Int(screenY)))"
            self.triggerClickRipple(at: clickPt)
            synthesizeClick(at: clickPt, count: 1, isRight: false)
        } else {
            self.currentStepText = "Warning: Could not visually find text \"\(targetText)\" on screen."
            HapticFeedback.testWaterDrop()
        }
    }

    // MARK: - Synthetic Event Generators (CGEvent & 2028 Spatial Routing)
    private func synthesizeMouseMove(to pt: CGPoint) {
        let engine = GenieCursorEngine2028.shared
        switch engine.activeMode {
        case .instantSnap:
            engine.warpCursor(to: pt)
        case .directBackgroundAction:
            // Skip moving hardware cursor pointer
            break
        case .virtualAgentCursor:
            engine.updatePhantomCursor(
                agentId: "agent-vscode-editor",
                target: pt,
                action: "Moving to (\(Int(pt.x)), \(Int(pt.y)))"
            )
        case .smoothGlide:
            guard let moveEvent = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: pt, mouseButton: .left) else { return }
            moveEvent.post(tap: .cghidEventTap)
        @unknown default:
            break
        }
    }

    private func synthesizeClick(at pt: CGPoint, count: Int = 1, isRight: Bool = false) {
        let engine = GenieCursorEngine2028.shared
        switch engine.activeMode {
        case .instantSnap:
            engine.warpCursor(to: pt)
            engine.skipCursorClick(at: pt, count: count, isRight: isRight)
        case .directBackgroundAction:
            engine.skipCursorClick(at: pt, count: count, isRight: isRight)
        case .virtualAgentCursor:
            engine.updatePhantomCursor(
                agentId: "agent-vscode-editor",
                target: pt,
                action: "Clicking (\(Int(pt.x)), \(Int(pt.y)))",
                isClicking: true
            )
            engine.skipCursorClick(at: pt, count: count, isRight: isRight)
        case .smoothGlide:
            guard let moveEvent = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: pt, mouseButton: .left) else { return }
            moveEvent.post(tap: .cghidEventTap)
            usleep(25_000)
            engine.skipCursorClick(at: pt, count: count, isRight: isRight)
        @unknown default:
            break
        }
    }

    private func synthesizeType(_ text: String) {
        for char in text {
            if isCancelled { break }
            let str = String(char)
            var utf16Chars = Array(str.utf16)

            if let down = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true),
               let up = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: false) {
                down.keyboardSetUnicodeString(stringLength: utf16Chars.count, unicodeString: &utf16Chars)
                up.keyboardSetUnicodeString(stringLength: utf16Chars.count, unicodeString: &utf16Chars)

                down.post(tap: .cghidEventTap)
                usleep(15_000)
                up.post(tap: .cghidEventTap)
                usleep(20_000)
            }
        }
    }

    private func synthesizeKey(name: String, modifiers: [String]) {
        let keyMap: [String: CGKeyCode] = [
            "a": 0, "s": 1, "d": 2, "f": 3, "h": 4, "g": 5,
            "z": 6, "x": 7, "c": 8, "v": 9, "b": 11,
            "q": 12, "w": 13, "e": 14, "r": 15, "y": 16, "t": 17,
            "1": 18, "2": 19, "3": 20, "4": 21, "6": 22, "5": 23,
            "9": 25, "7": 26, "8": 28, "0": 29,
            "o": 31, "u": 32, "i": 34, "p": 35, "l": 37,
            "j": 38, "k": 40, "n": 45, "m": 46,
            "return": 36, "enter": 36,
            "tab": 48,
            "space": 49,
            "delete": 51, "backspace": 51,
            "escape": 53, "esc": 53,
            "up": 126, "down": 125, "left": 123, "right": 124
        ]

        guard let code = keyMap[name.lowercased()] else {
            isCancelled = true
            currentStepText = "Unsupported key: \(name). No key was sent."
            return
        }

        var flags: CGEventFlags = []
        for mod in modifiers {
            switch mod {
            case "cmd", "command": flags.insert(.maskCommand)
            case "opt", "option", "alt": flags.insert(.maskAlternate)
            case "ctrl", "control": flags.insert(.maskControl)
            case "shift": flags.insert(.maskShift)
            default: break
            }
        }

        if let down = CGEvent(keyboardEventSource: nil, virtualKey: code, keyDown: true),
           let up = CGEvent(keyboardEventSource: nil, virtualKey: code, keyDown: false) {
            down.flags = flags
            up.flags = flags
            down.post(tap: .cghidEventTap)
            usleep(20_000)
            up.post(tap: .cghidEventTap)
        }
    }

    private func synthesizeScroll(dx: Int32, dy: Int32) {
        guard let scrollEvent = CGEvent(scrollWheelEvent2Source: nil, units: .line, wheelCount: 2, wheel1: dy, wheel2: dx, wheel3: 0) else { return }
        scrollEvent.post(tap: .cghidEventTap)
    }

    private func synthesizeDrag(from: CGPoint, to: CGPoint) {
        let engine = GenieCursorEngine2028.shared
        switch engine.activeMode {
        case .instantSnap:
            engine.warpCursor(to: from)
            guard let down = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: from, mouseButton: .left) else { return }
            down.post(tap: .cghidEventTap)
            usleep(15_000)
            engine.warpCursor(to: to)
            guard let up = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: to, mouseButton: .left) else { return }
            up.post(tap: .cghidEventTap)

        case .directBackgroundAction:
            guard let down = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: from, mouseButton: .left),
                  let up = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: to, mouseButton: .left) else { return }
            down.post(tap: .cghidEventTap)
            usleep(20_000)
            up.post(tap: .cghidEventTap)

        case .virtualAgentCursor:
            engine.updatePhantomCursor(agentId: "agent-vscode-editor", target: from, action: "Drag Start", isDragging: true)
            guard let down = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: from, mouseButton: .left) else { return }
            down.post(tap: .cghidEventTap)
            usleep(20_000)
            engine.updatePhantomCursor(agentId: "agent-vscode-editor", target: to, action: "Drag End", isDragging: false)
            guard let up = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: to, mouseButton: .left) else { return }
            up.post(tap: .cghidEventTap)

        case .smoothGlide:
            guard let moveEvent = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: from, mouseButton: .left) else { return }
            moveEvent.post(tap: .cghidEventTap)
            usleep(30_000)
            guard let down = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: from, mouseButton: .left) else { return }
            down.post(tap: .cghidEventTap)
            usleep(40_000)

            let steps = 12
            for s in 1...steps {
                let t = CGFloat(s) / CGFloat(steps)
                let curr = CGPoint(x: from.x + (to.x - from.x) * t, y: from.y + (to.y - from.y) * t)
                if let drag = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDragged, mouseCursorPosition: curr, mouseButton: .left) {
                    drag.post(tap: .cghidEventTap)
                }
                usleep(15_000)
            }

            guard let up = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: to, mouseButton: .left) else { return }
            up.post(tap: .cghidEventTap)
        @unknown default:
            break
        }
    }

    private func triggerClickRipple(at pt: CGPoint) {
        self.clickRipplePosition = pt
        GenieCursorEngine2028.shared.updatePhantomCursor(
            agentId: "agent-vscode-editor",
            target: pt,
            action: "Action Ripple",
            isClicking: true
        )
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            if self?.clickRipplePosition == pt {
                self?.clickRipplePosition = nil
            }
        }
    }
}
