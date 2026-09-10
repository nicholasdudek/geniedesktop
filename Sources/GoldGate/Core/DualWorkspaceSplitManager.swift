import Foundation
import AppKit
import SwiftUI

// MARK: - Workspace Split Orientation
public enum SplitOrientation: String, CaseIterable, Codable {
    case verticalSideBySide = "Vertical (Side-by-Side)"
    case horizontalTopBottom = "Horizontal (Top/Bottom)"

    public var icon: String {
        switch self {
        case .verticalSideBySide: return "rectangle.split.2x1"
        case .horizontalTopBottom: return "rectangle.split.1x2"
        }
    }
}

// MARK: - Split Workspace Slot
public struct SplitWorkspaceSlot: Identifiable, Codable, Equatable {
    public let id: String
    public var slotIndex: Int // 0 = Slot A (Left/Top), 1 = Slot B (Right/Bottom)
    public var agentId: String
    public var agentName: String
    public var assignedDesktopIndex: Int
    public var colorHex: String
    public var activeTask: String
    public var assignedTools: [String]
    public var boundingFrame: CGRect

    public init(
        id: String = UUID().uuidString,
        slotIndex: Int,
        agentId: String,
        agentName: String,
        assignedDesktopIndex: Int,
        colorHex: String,
        activeTask: String,
        assignedTools: [String],
        boundingFrame: CGRect = .zero
    ) {
        self.id = id
        self.slotIndex = slotIndex
        self.agentId = agentId
        self.agentName = agentName
        self.assignedDesktopIndex = assignedDesktopIndex
        self.colorHex = colorHex
        self.activeTask = activeTask
        self.assignedTools = assignedTools
        self.boundingFrame = boundingFrame
    }

    public var displayColor: Color {
        Color(hex: colorHex)
    }
}

// MARK: - Dual Workspace Split Manager
@MainActor
public final class DualWorkspaceSplitManager: ObservableObject {
    public static let shared = DualWorkspaceSplitManager()

    @Published public var isSplitActive: Bool = false {
        didSet {
            recalculateFrames()
            if isSplitActive {
                DualWorkspaceSplitWindow.shared.show()
            } else {
                DualWorkspaceSplitWindow.shared.hide()
            }
        }
    }

    @Published public var orientation: SplitOrientation = .verticalSideBySide {
        didSet {
            recalculateFrames()
        }
    }

    /// Split ratio from 0.20 to 0.80 (representing Slot A's fraction of width or height)
    @Published public var splitRatio: CGFloat = 0.50 {
        didSet {
            let clamped = min(max(splitRatio, 0.20), 0.80)
            if clamped != splitRatio {
                splitRatio = clamped
            } else {
                recalculateFrames()
            }
        }
    }

    @Published public var slotA: SplitWorkspaceSlot
    @Published public var slotB: SplitWorkspaceSlot

    private init() {
        // Pre-seed Slot A: VS Code Editor Agent (Desktop 2)
        self.slotA = SplitWorkspaceSlot(
            slotIndex: 0,
            agentId: "agent-vscode-editor",
            agentName: "💻 VS Code Editor Agent",
            assignedDesktopIndex: 2,
            colorHex: "#00F0FF",
            activeTask: "Autonomous Code Refactoring & Build Pipeline",
            assignedTools: ["edit_file", "search_files", "run_command", "polyglot_code"]
        )

        // Pre-seed Slot B: Browser Research Agent (Desktop 3)
        self.slotB = SplitWorkspaceSlot(
            slotIndex: 1,
            agentId: "agent-web-browser",
            agentName: "🌐 Browser Research Agent",
            assignedDesktopIndex: 3,
            colorHex: "#00FF88",
            activeTask: "Autonomous Web Research & Spatial DOM Grounding",
            assignedTools: ["desktop_agent", "spatial_dom", "read_ui", "copy_text"]
        )

        recalculateFrames()
    }

    // MARK: - Split Actions
    public func toggleSplit() {
        HapticFeedback.selection()
        isSplitActive.toggle()
    }

    public func setRatio(_ ratio: CGFloat) {
        self.splitRatio = min(max(ratio, 0.20), 0.80)
    }

    public func toggleOrientation() {
        HapticFeedback.selection()
        orientation = (orientation == .verticalSideBySide) ? .horizontalTopBottom : .verticalSideBySide
    }

    public func swapWorkspaces() {
        HapticFeedback.selection()
        let temp = slotA
        slotA = SplitWorkspaceSlot(
            id: temp.id,
            slotIndex: 0,
            agentId: slotB.agentId,
            agentName: slotB.agentName,
            assignedDesktopIndex: slotB.assignedDesktopIndex,
            colorHex: slotB.colorHex,
            activeTask: slotB.activeTask,
            assignedTools: slotB.assignedTools,
            boundingFrame: slotA.boundingFrame
        )
        slotB = SplitWorkspaceSlot(
            id: slotB.id,
            slotIndex: 1,
            agentId: temp.agentId,
            agentName: temp.agentName,
            assignedDesktopIndex: temp.assignedDesktopIndex,
            colorHex: temp.colorHex,
            activeTask: temp.activeTask,
            assignedTools: temp.assignedTools,
            boundingFrame: slotB.boundingFrame
        )
    }

    public func assignAgent(agentId: String, name: String, colorHex: String, desktopIndex: Int, tools: [String], toSlot slotIndex: Int) {
        if slotIndex == 0 {
            slotA.agentId = agentId
            slotA.agentName = name
            slotA.colorHex = colorHex
            slotA.assignedDesktopIndex = desktopIndex
            slotA.assignedTools = tools
        } else {
            slotB.agentId = agentId
            slotB.agentName = name
            slotB.colorHex = colorHex
            slotB.assignedDesktopIndex = desktopIndex
            slotB.assignedTools = tools
        }
    }

    // MARK: - Frame Recalculation
    public func recalculateFrames() {
        guard let screen = NSScreen.main else { return }
        let screenRect = screen.frame
        let totalW = screenRect.width
        let totalH = screenRect.height
        let ox = screenRect.origin.x
        let oy = screenRect.origin.y

        switch orientation {
        case .verticalSideBySide:
            let widthA = totalW * splitRatio
            let widthB = totalW - widthA
            slotA.boundingFrame = CGRect(x: ox, y: oy, width: widthA, height: totalH)
            slotB.boundingFrame = CGRect(x: ox + widthA, y: oy, width: widthB, height: totalH)

        case .horizontalTopBottom:
            let heightB = totalH * (1.0 - splitRatio)
            let heightA = totalH - heightB
            // In macOS Quartz coordinates, Y=0 is bottom
            slotB.boundingFrame = CGRect(x: ox, y: oy, width: totalW, height: heightB)
            slotA.boundingFrame = CGRect(x: ox, y: oy + heightB, width: totalW, height: heightA)
        }
    }

    // MARK: - Coordinate Clamping & Bounding
    /// Clamps an on-screen coordinate into the designated agent's workspace boundary
    public func clampPointToSlot(_ pt: CGPoint, slotIndex: Int) -> CGPoint {
        let frame = (slotIndex == 0) ? slotA.boundingFrame : slotB.boundingFrame
        guard frame.width > 0 && frame.height > 0 else { return pt }

        let clampedX = min(max(pt.x, frame.minX), frame.maxX)
        let clampedY = min(max(pt.y, frame.minY), frame.maxY)
        return CGPoint(x: clampedX, y: clampedY)
    }

    /// Computes absolute screen coordinates from a normalized (0.0...1.0) position inside an agent's workspace
    public func screenPoint(normalizedX nx: CGFloat, normalizedY ny: CGFloat, slotIndex: Int) -> CGPoint {
        let frame = (slotIndex == 0) ? slotA.boundingFrame : slotB.boundingFrame
        let targetX = frame.minX + (nx * frame.width)
        let targetY = frame.minY + (ny * frame.height)
        return CGPoint(x: targetX, y: targetY)
    }
}

// MARK: - Color Hex Helper
extension Color {
    init(hex: String, defaultColor: Color = .cyan) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else {
            self = defaultColor
            return
        }

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}

