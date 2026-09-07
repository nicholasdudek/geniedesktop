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
            if line.isEmpty || line.hasPrefix("#") || line.hasPrefix("//") {
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

    // MARK: - Synthetic Event Generators (CGEvent)
    private func synthesizeMouseMove(to pt: CGPoint) {
        guard let moveEvent = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: pt, mouseButton: .left) else { return }
        moveEvent.post(tap: .cghidEventTap)
    }

    private func synthesizeClick(at pt: CGPoint, count: Int = 1, isRight: Bool = false) {
        synthesizeMouseMove(to: pt)
        usleep(30_000)

        let downType: CGEventType = isRight ? .rightMouseDown : .leftMouseDown
        let upType: CGEventType = isRight ? .rightMouseUp : .leftMouseUp
        let btn: CGMouseButton = isRight ? .right : .left

        for i in 1...count {
            guard let down = CGEvent(mouseEventSource: nil, mouseType: downType, mouseCursorPosition: pt, mouseButton: btn),
                  let up = CGEvent(mouseEventSource: nil, mouseType: upType, mouseCursorPosition: pt, mouseButton: btn) else { break }

            down.setIntegerValueField(.mouseEventClickState, value: Int64(i))
            up.setIntegerValueField(.mouseEventClickState, value: Int64(i))

            down.post(tap: .cghidEventTap)
            usleep(25_000)
            up.post(tap: .cghidEventTap)
            usleep(35_000)
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
            "return": 36, "enter": 36,
            "tab": 48,
            "space": 49,
            "delete": 51, "backspace": 51,
            "escape": 53, "esc": 53,
            "up": 126, "down": 125, "left": 123, "right": 124
        ]

        let code = keyMap[name.lowercased()] ?? 36 // default return

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
        synthesizeMouseMove(to: from)
        usleep(30_000)

        guard let down = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: from, mouseButton: .left) else { return }
        down.post(tap: .cghidEventTap)
        usleep(40_000)

        // Smooth intermediate interpolation steps
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
    }

    private func triggerClickRipple(at pt: CGPoint) {
        self.clickRipplePosition = pt
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            if self?.clickRipplePosition == pt {
                self?.clickRipplePosition = nil
            }
        }
    }
}
