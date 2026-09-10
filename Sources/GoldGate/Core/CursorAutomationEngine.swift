//
//  CursorAutomationEngine.swift
//  GoldGate / Ultra-Compact Cursor Automation Engine
//

import AppKit
import CoreGraphics
import SwiftUI

public enum CursorMoveMode: String, CaseIterable, Codable, Sendable {
    case instantSnap = "SNAP", directBackgroundAction = "BACKGROUND", virtualAgentCursor = "VIRTUAL-POINTER", smoothGlide = "SMOOTH"
    public var systemIcon: String {
        switch self {
        case .instantSnap: return "bolt.horizontal.fill"
        case .directBackgroundAction: return "cursorarrow.slash"
        case .virtualAgentCursor: return "cursorarrow.rays"
        case .smoothGlide: return "cursorarrow.motionlines"
        }
    }
    public var badgeTitle: String { rawValue }
}

public struct VirtualCursorState: Identifiable, Sendable {
    public let id: String
    public var agentName: String
    public var position: CGPoint
    public var colorHex = "#00F0FF", actionDescription = "Idle"
    public var isClicking = false, isDragging = false, lastActivity = Date()
    public init(id: String, agentName: String, position: CGPoint, colorHex: String = "#00F0FF") {
        self.id = id; self.agentName = agentName; self.position = position; self.colorHex = colorHex
    }
}

@MainActor
public final class CursorAutomationEngine: ObservableObject {
    public static let shared = CursorAutomationEngine()
    @Published public var activeMode: CursorMoveMode = .instantSnap
    @Published public var virtualCursors: [String: VirtualCursorState] = [
        "center-mission-control": .init(id: "center-mission-control", agentName: "🛸 Mission Control", position: .init(x: 400, y: 300), colorHex: "#BF00FF"),
        "agent-vscode-editor": .init(id: "agent-vscode-editor", agentName: "💻 VS Code Agent", position: .init(x: 400, y: 300), colorHex: "#00F0FF")
    ]
    @Published public var lastSnapPoint: CGPoint?
    @Published public var lastBackgroundPoint: CGPoint?
    @Published public var hardwareCursorDecoupled = false

    public func snapCursor(to target: CGPoint) {
        CGWarpMouseCursorPosition(target)
        CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: target, mouseButton: .left)?.post(tap: .cghidEventTap)
        lastSnapPoint = target
    }

    public func directBackgroundClick(at target: CGPoint, count: Int = 1, isRight: Bool = false) {
        let (downType, upType, btn): (CGEventType, CGEventType, CGMouseButton) = isRight ? (.rightMouseDown, .rightMouseUp, .right) : (.leftMouseDown, .leftMouseUp, .left)
        for i in 1...count {
            guard let d = CGEvent(mouseEventSource: nil, mouseType: downType, mouseCursorPosition: target, mouseButton: btn),
                  let u = CGEvent(mouseEventSource: nil, mouseType: upType, mouseCursorPosition: target, mouseButton: btn) else { break }
            d.setIntegerValueField(.mouseEventClickState, value: Int64(i)); d.post(tap: .cghidEventTap); usleep(15_000)
            u.setIntegerValueField(.mouseEventClickState, value: Int64(i)); u.post(tap: .cghidEventTap); usleep(20_000)
        }
        lastBackgroundPoint = target
    }

    public func updateVirtualCursor(agentId: String, target: CGPoint, action: String, isClicking: Bool = false, isDragging: Bool = false) {
        guard var c = virtualCursors[agentId] else { return }
        c.position = target; c.actionDescription = action; c.isClicking = isClicking; c.isDragging = isDragging; c.lastActivity = Date()
        virtualCursors[agentId] = c
        VirtualCursorOverlayWindow.shared.show()
    }

    public func calculateCentroid(from bounds: CGRect) -> CGPoint { .init(x: bounds.midX, y: bounds.midY) }

    public func calculateScreenCoordinates(normRect: CGRect, on screen: NSScreen? = NSScreen.main) -> CGPoint {
        guard let s = screen else { return .init(x: 500, y: 400) }
        return .init(x: s.frame.origin.x + (normRect.midX * s.frame.width), y: (s.frame.origin.y + s.frame.height) - (normRect.midY * s.frame.height))
    }

    public func executeDispatch(to target: CGPoint, agentId: String = "agent-vscode-editor", agentName: String = "AI Agent", isClick: Bool = true, count: Int = 1, isRight: Bool = false) {
        switch activeMode {
        case .instantSnap, .smoothGlide:
            snapCursor(to: target)
            if isClick { directBackgroundClick(at: target, count: count, isRight: isRight) }
        case .directBackgroundAction:
            if isClick { directBackgroundClick(at: target, count: count, isRight: isRight) }
        case .virtualAgentCursor:
            updateVirtualCursor(agentId: agentId, target: target, action: isClick ? "Clicking" : "Hovering", isClicking: isClick)
            if isClick { directBackgroundClick(at: target, count: count, isRight: isRight) }
        }
    }
}

// MARK: - Compatibility Aliases
public typealias CursorMode = CursorMoveMode
public typealias PhantomCursorState = VirtualCursorState
public typealias GenieCursorEngine2028 = CursorAutomationEngine
extension CursorMoveMode {
    public static var warpJump: Self { .instantSnap }; public static var skipCursor: Self { .directBackgroundAction }
    public static var duplicateCursor: Self { .virtualAgentCursor }; public static var standardSmooth: Self { .smoothGlide }
}
extension CursorAutomationEngine {
    public var phantomCursors: [String: VirtualCursorState] { get { virtualCursors } set { virtualCursors = newValue } }
    public var lastWarpPoint: CGPoint? { get { lastSnapPoint } set { lastSnapPoint = newValue } }
    public var lastSkipPoint: CGPoint? { get { lastBackgroundPoint } set { lastBackgroundPoint = newValue } }
    public func warpCursor(to p: CGPoint) { snapCursor(to: p) }
    public func skipCursorClick(at p: CGPoint, count: Int = 1, isRight: Bool = false) { directBackgroundClick(at: p, count: count, isRight: isRight) }
    public func updatePhantomCursor(agentId: String, target: CGPoint, action: String, isClicking: Bool = false, isDragging: Bool = false) {
        updateVirtualCursor(agentId: agentId, target: target, action: action, isClicking: isClicking, isDragging: isDragging)
    }
}
