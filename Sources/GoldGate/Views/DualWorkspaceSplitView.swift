import AppKit
import Foundation
import SwiftUI

// MARK: - Dual Workspace Split Overlay View
public struct DualWorkspaceSplitOverlayView: View {
    @ObservedObject var splitManager = DualWorkspaceSplitManager.shared
    @ObservedObject var cursorEngine = GenieCursorEngine2028.shared
    @State private var isDraggingDivider: Bool = false
    @State private var dragDividerOffset: CGFloat = 0

    public init() {}

    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                // Background Tint & Workspace Panes
                if splitManager.orientation == .verticalSideBySide {
                    HStack(spacing: 0) {
                        // Slot A (Left Pane)
                        AgentWorkspacePaneView(
                            slot: splitManager.slotA,
                            width: geo.size.width * splitManager.splitRatio,
                            height: geo.size.height,
                            phantomState: cursorEngine.phantomCursors[splitManager.slotA.agentId]
                        )

                        // Draggable Vertical Divider Handle
                        VerticalSplitterDivider(
                            height: geo.size.height,
                            isDragging: isDraggingDivider,
                            ratioText: "\(Int(splitManager.splitRatio * 100))%"
                        )
                        .gesture(
                            DragGesture(minimumDistance: 1)
                                .onChanged { value in
                                    isDraggingDivider = true
                                    let newRatio = value.location.x / geo.size.width
                                    splitManager.setRatio(newRatio)
                                }
                                .onEnded { _ in
                                    isDraggingDivider = false
                                    HapticFeedback.selection()
                                }
                        )

                        // Slot B (Right Pane)
                        AgentWorkspacePaneView(
                            slot: splitManager.slotB,
                            width: geo.size.width * (1.0 - splitManager.splitRatio),
                            height: geo.size.height,
                            phantomState: cursorEngine.phantomCursors[splitManager.slotB.agentId]
                        )
                    }
                } else {
                    VStack(spacing: 0) {
                        // Slot A (Top Pane)
                        AgentWorkspacePaneView(
                            slot: splitManager.slotA,
                            width: geo.size.width,
                            height: geo.size.height * splitManager.splitRatio,
                            phantomState: cursorEngine.phantomCursors[splitManager.slotA.agentId]
                        )

                        // Draggable Horizontal Divider Handle
                        HorizontalSplitterDivider(
                            width: geo.size.width,
                            isDragging: isDraggingDivider,
                            ratioText: "\(Int(splitManager.splitRatio * 100))%"
                        )
                        .gesture(
                            DragGesture(minimumDistance: 1)
                                .onChanged { value in
                                    isDraggingDivider = true
                                    let newRatio = value.location.y / geo.size.height
                                    splitManager.setRatio(newRatio)
                                }
                                .onEnded { _ in
                                    isDraggingDivider = false
                                    HapticFeedback.selection()
                                }
                        )

                        // Slot B (Bottom Pane)
                        AgentWorkspacePaneView(
                            slot: splitManager.slotB,
                            width: geo.size.width,
                            height: geo.size.height * (1.0 - splitManager.splitRatio),
                            phantomState: cursorEngine.phantomCursors[splitManager.slotB.agentId]
                        )
                    }
                }

                // Top Floating Preset Bar & Controls HUD
                DualWorkspaceControlBarView()
                    .padding(.top, 12)
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

// MARK: - Individual Agent Workspace Pane
public struct AgentWorkspacePaneView: View {
    public let slot: SplitWorkspaceSlot
    public let width: CGFloat
    public let height: CGFloat
    public let phantomState: PhantomCursorState?

    private var accentColor: Color {
        slot.displayColor
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            // Subtle translucent background tint
            Rectangle()
                .fill(accentColor.opacity(0.03))

            // Boundary Glow Frame
            Rectangle()
                .strokeBorder(
                    LinearGradient(
                        colors: [accentColor.opacity(0.65), accentColor.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )

            // Top Header Card
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 8) {
                    // Agent Name & Space Badge
                    HStack(spacing: 6) {
                        Circle()
                            .fill(accentColor)
                            .frame(width: 8, height: 8)
                            .shadow(color: accentColor.opacity(0.8), radius: 4)

                        Text(slot.agentName)
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text("Desktop \(slot.assignedDesktopIndex)")
                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                            .foregroundColor(accentColor)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(accentColor.opacity(0.18)))
                    }

                    Spacer()

                    // Assigned Workspace Tag
                    Text(slot.slotIndex == 0 ? "WORKSPACE A" : "WORKSPACE B")
                        .font(.system(size: 8.5, weight: .black, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.white.opacity(0.10)))
                }

                // Active Task Description
                Text(slot.activeTask)
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.85))
                    .lineLimit(1)

                // Tool Capabilities
                HStack(spacing: 4) {
                    ForEach(slot.assignedTools, id: \.self) { tool in
                        Text(tool)
                            .font(.system(size: 8, weight: .medium, design: .monospaced))
                            .foregroundColor(accentColor)
                            .padding(.horizontal, 4.5)
                            .padding(.vertical, 1.5)
                            .background(RoundedRectangle(cornerRadius: 3).fill(accentColor.opacity(0.12)))
                    }
                    Spacer()

                    if let phantom = phantomState {
                        Text("Cursor: (\(Int(phantom.position.x)), \(Int(phantom.position.y)))")
                            .font(.system(size: 8, weight: .regular, design: .monospaced))
                            .foregroundColor(Color.white.opacity(0.6))
                    }
                }
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.black.opacity(0.45))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                    )
            )
            .padding(10)
        }
        .frame(width: max(80, width), height: max(80, height))
        .clipped()
    }
}

// MARK: - Draggable Vertical Splitter Divider
public struct VerticalSplitterDivider: View {
    let height: CGFloat
    let isDragging: Bool
    let ratioText: String

    public var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.white.opacity(isDragging ? 0.40 : 0.15))
                .frame(width: 3, height: height)

            // Centered Draggable Handle Pill
            VStack(spacing: 3) {
                Image(systemName: "arrow.left.and.right")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)

                Text(ratioText)
                    .font(.system(size: 8, weight: .black, design: .monospaced))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.85))
                    .overlay(Capsule().stroke(Color.cyan.opacity(isDragging ? 0.9 : 0.4), lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.5), radius: 6)
            )
            .scaleEffect(isDragging ? 1.12 : 1.0)
            .animation(.spring(response: 0.25), value: isDragging)
        }
        .frame(width: 24, height: height)
        .contentShape(Rectangle())
        .cursor(.resizeLeftRight)
    }
}

// MARK: - Draggable Horizontal Splitter Divider
public struct HorizontalSplitterDivider: View {
    let width: CGFloat
    let isDragging: Bool
    let ratioText: String

    public var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.white.opacity(isDragging ? 0.40 : 0.15))
                .frame(width: width, height: 3)

            // Centered Draggable Handle Pill
            HStack(spacing: 5) {
                Image(systemName: "arrow.up.and.down")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white)

                Text(ratioText)
                    .font(.system(size: 8, weight: .black, design: .monospaced))
                    .foregroundColor(.white.opacity(0.9))
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.85))
                    .overlay(Capsule().stroke(Color.cyan.opacity(isDragging ? 0.9 : 0.4), lineWidth: 1))
                    .shadow(color: Color.black.opacity(0.5), radius: 6)
            )
            .scaleEffect(isDragging ? 1.12 : 1.0)
            .animation(.spring(response: 0.25), value: isDragging)
        }
        .frame(width: width, height: 24)
        .contentShape(Rectangle())
        .cursor(.resizeUpDown)
    }
}

// MARK: - Floating Control Bar HUD
public struct DualWorkspaceControlBarView: View {
    @ObservedObject var splitManager = DualWorkspaceSplitManager.shared

    public var body: some View {
        HStack(spacing: 8) {
            // Mode Header Badge
            HStack(spacing: 5) {
                Image(systemName: splitManager.orientation.icon)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.cyan)
                Text("DUAL WORKSPACES")
                    .font(.system(size: 9.5, weight: .black, design: .monospaced))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4.5)
            .background(Capsule().fill(Color.cyan.opacity(0.20)))

            // Preset: 50 / 50 Split
            Button(action: {
                HapticFeedback.selection()
                splitManager.setRatio(0.50)
            }) {
                Text("50:50")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(splitManager.splitRatio == 0.50 ? .cyan : .white.opacity(0.8))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.white.opacity(splitManager.splitRatio == 0.50 ? 0.20 : 0.08)))
            }
            .buttonStyle(.plain)
            .help("Set 50:50 Split")

            // Preset: 65 / 35 Split
            Button(action: {
                HapticFeedback.selection()
                splitManager.setRatio(0.65)
            }) {
                Text("65:35")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(splitManager.splitRatio == 0.65 ? .cyan : .white.opacity(0.8))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.white.opacity(splitManager.splitRatio == 0.65 ? 0.20 : 0.08)))
            }
            .buttonStyle(.plain)
            .help("Focus Workspace A (65:35)")

            // Preset: 35 / 65 Split
            Button(action: {
                HapticFeedback.selection()
                splitManager.setRatio(0.35)
            }) {
                Text("35:65")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(splitManager.splitRatio == 0.35 ? .cyan : .white.opacity(0.8))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.white.opacity(splitManager.splitRatio == 0.35 ? 0.20 : 0.08)))
            }
            .buttonStyle(.plain)
            .help("Focus Workspace B (35:65)")

            // Swap Workspaces Button
            Button(action: {
                splitManager.swapWorkspaces()
            }) {
                HStack(spacing: 3) {
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.system(size: 8.5, weight: .bold))
                    Text("Swap")
                        .font(.system(size: 9, weight: .semibold))
                }
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.white.opacity(0.12)))
            }
            .buttonStyle(.plain)
            .help("Swap Agent Workspaces (A ⇄ B)")

            // Toggle Orientation (Vertical / Horizontal)
            Button(action: {
                splitManager.toggleOrientation()
            }) {
                HStack(spacing: 3) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 8.5, weight: .bold))
                    Text("Flip")
                        .font(.system(size: 9, weight: .semibold))
                }
                .foregroundColor(.white.opacity(0.9))
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.white.opacity(0.12)))
            }
            .buttonStyle(.plain)
            .help("Toggle Split Orientation (Vertical / Horizontal)")

            // Close / Exit Split Button
            Button(action: {
                splitManager.isSplitActive = false
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(4)
            }
            .buttonStyle(.plain)
            .help("Exit Dual Workspace Split")
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.85))
                .overlay(Capsule().stroke(Color.white.opacity(0.20), lineWidth: 0.8))
                .shadow(color: Color.black.opacity(0.6), radius: 10, y: 4)
        )
    }
}

// MARK: - Dual Workspace Split Window Manager
@MainActor
public final class DualWorkspaceSplitWindow: NSObject {
    public static let shared = DualWorkspaceSplitWindow()

    private var splitPanel: NSPanel?

    private override init() {
        super.init()
    }

    public func show() {
        guard let screen = NSScreen.main else { return }

        if splitPanel == nil {
            let panel = NSPanel(
                contentRect: screen.frame,
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = false
            panel.level = .floating
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.ignoresMouseEvents = false // Allows clicking dividers and presets
            panel.contentView = NSHostingView(rootView: DualWorkspaceSplitOverlayView())
            self.splitPanel = panel
        }

        guard let panel = splitPanel else { return }
        panel.setFrame(screen.frame, display: true)
        if !panel.isVisible {
            panel.orderFrontRegardless()
        }
    }

    public func hide() {
        splitPanel?.orderOut(nil)
    }
}

// MARK: - Cursor Modifier Helper
private extension View {
    func cursor(_ cursor: NSCursor) -> some View {
        self.onHover { inside in
            if inside {
                cursor.push()
            } else {
                NSCursor.pop()
            }
        }
    }
}
