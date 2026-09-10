//
//  VirtualCursorOverlayView.swift
//  GoldGate / Genie Desktop Automation Architecture
//
//  Transparent overlay rendering virtual agent mouse pointers on screen.
//  Permits background agents to visually indicate targets, clicks, and drags
//  without interfering with the human user's physical mouse.
//

import AppKit
import Foundation
import SwiftUI

// MARK: - Virtual Agent Cursor Pointer Sprite
public struct VirtualAgentCursorSprite: View {
    public let state: VirtualCursorState
    @State private var ringPulse: Bool = false

    private var cursorColor: Color {
        Color(hex: state.colorHex) ?? .cyan
    }

    public init(state: VirtualCursorState) {
        self.state = state
    }

    public var body: some View {
        ZStack(alignment: .topLeading) {
            // Action Click Feedback Ring
            if state.isClicking {
                Circle()
                    .stroke(cursorColor.opacity(0.8), lineWidth: 2)
                    .frame(width: 48, height: 48)
                    .scaleEffect(ringPulse ? 1.4 : 0.4)
                    .opacity(ringPulse ? 0.0 : 1.0)
                    .offset(x: -24, y: -24)
                    .onAppear {
                        withAnimation(.easeOut(duration: 0.5).repeatForever(autoreverses: false)) {
                            ringPulse = true
                        }
                    }
            }

            // Virtual Arrow Pointer
            Path { path in
                path.move(to: CGPoint(x: 0, y: 0))
                path.addLine(to: CGPoint(x: 0, y: 18))
                path.addLine(to: CGPoint(x: 5, y: 14))
                path.addLine(to: CGPoint(x: 9, y: 22))
                path.addLine(to: CGPoint(x: 13, y: 20))
                path.addLine(to: CGPoint(x: 9, y: 12))
                path.addLine(to: CGPoint(x: 15, y: 12))
                path.closeSubpath()
            }
            .fill(
                LinearGradient(
                    colors: [cursorColor, cursorColor.opacity(0.7)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: 0, y: 18))
                    path.addLine(to: CGPoint(x: 5, y: 14))
                    path.addLine(to: CGPoint(x: 9, y: 22))
                    path.addLine(to: CGPoint(x: 13, y: 20))
                    path.addLine(to: CGPoint(x: 9, y: 12))
                    path.addLine(to: CGPoint(x: 15, y: 12))
                    path.closeSubpath()
                }
                .stroke(Color.white.opacity(0.9), lineWidth: 1.2)
            )
            .shadow(color: cursorColor.opacity(0.6), radius: 6, x: 0, y: 2)

            // Agent Label & Coordinate Pill
            HStack(spacing: 4) {
                Circle()
                    .fill(cursorColor)
                    .frame(width: 6, height: 6)

                Text(state.agentName)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("(\(Int(state.position.x)), \(Int(state.position.y)))")
                    .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                    .foregroundColor(Color.white.opacity(0.7))
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 3.5)
            .background(
                Capsule()
                    .fill(Color(red: 0.07, green: 0.08, blue: 0.12).opacity(0.90))
                    .overlay(Capsule().stroke(cursorColor.opacity(0.6), lineWidth: 0.8))
            )
            .shadow(color: Color.black.opacity(0.4), radius: 4, x: 0, y: 2)
            .offset(x: 18, y: 18)
        }
    }
}

// MARK: - Virtual Cursor Canvas Overlay
public struct VirtualCursorCanvasView: View {
    @ObservedObject var engine = CursorAutomationEngine.shared

    public init() {}

    public var body: some View {
        GeometryReader { _ in
            ZStack(alignment: .topLeading) {
                // Render all active virtual agent pointers
                ForEach(Array(engine.virtualCursors.values), id: \.id) { cursor in
                    VirtualAgentCursorSprite(state: cursor)
                        .position(cursor.position)
                        .animation(.interpolatingSpring(stiffness: 300, damping: 25), value: cursor.position.x)
                        .animation(.interpolatingSpring(stiffness: 300, damping: 25), value: cursor.position.y)
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

// MARK: - Transparent Fullscreen Floating Overlay Panel Manager
@MainActor
public final class VirtualCursorOverlayWindow: NSObject {
    public static let shared = VirtualCursorOverlayWindow()

    private var overlayPanel: NSPanel?
    private var dismissTask: Task<Void, Never>?

    private override init() {
        super.init()
    }

    public func show() {
        if overlayPanel == nil {
            guard let screen = NSScreen.main else { return }
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
            panel.ignoresMouseEvents = true // Zero interference with physical mouse clicks
            panel.contentView = NSHostingView(rootView: VirtualCursorCanvasView())
            self.overlayPanel = panel
        }

        guard let panel = overlayPanel, let screen = NSScreen.main else { return }
        panel.setFrame(screen.frame, display: true)
        if !panel.isVisible {
            panel.orderFrontRegardless()
        }

        scheduleAutoHide()
    }

    public func hide() {
        overlayPanel?.orderOut(nil)
        dismissTask?.cancel()
        dismissTask = nil
    }

    private func scheduleAutoHide() {
        dismissTask?.cancel()
        dismissTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 4_000_000_000) // 4 seconds after inactivity
            if !Task.isCancelled {
                self.hide()
            }
        }
    }
}

// MARK: - Backward-Compatibility Type Aliases
public typealias HolographicAgentCursorSprite = VirtualAgentCursorSprite
public typealias GeniePhantomCursorCanvasView = VirtualCursorCanvasView
public typealias GeniePhantomCursorOverlayWindow = VirtualCursorOverlayWindow
public typealias GeniePhantomCursorOverlayView = VirtualCursorCanvasView

// MARK: - Color Hex Helper
private extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
