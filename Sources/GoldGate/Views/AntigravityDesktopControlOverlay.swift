import AppKit
import SwiftUI

// MARK: - Antigravity Desktop Control HUD View
public struct AntigravityDesktopControlHUDView: View {
    @ObservedObject var agent = AntigravityDesktopAgent.shared
    @State private var isPulsing: Bool = false

    public init() {}

    public var body: some View {
        HStack(spacing: 16) {
            // Animated Glowing Status Beacon
            ZStack {
                Circle()
                    .fill(Color.cyan.opacity(isPulsing ? 0.35 : 0.15))
                    .frame(width: 28, height: 28)
                    .scaleEffect(isPulsing ? 1.25 : 0.9)
                Circle()
                    .fill(LinearGradient(colors: [.cyan, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 12, height: 12)
                    .shadow(color: .cyan.opacity(0.8), radius: 6, x: 0, y: 0)
            }
            .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: isPulsing)

            // Agent Status & Step Details
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text("Antigravity Desktop Control")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("ACTIVE")
                        .font(.system(size: 9, weight: .black, design: .monospaced))
                        .foregroundColor(.cyan)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1.5)
                        .background(Capsule().fill(Color.cyan.opacity(0.2)))
                }

                Text(agent.currentStepText)
                    .font(.system(size: 11, weight: .medium, design: .default))
                    .foregroundColor(Color.white.opacity(0.85))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: 320, alignment: .leading)

                if agent.totalSteps > 1 {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.15))
                                .frame(height: 3)
                            Capsule()
                                .fill(LinearGradient(colors: [.cyan, .purple], startPoint: .leading, endPoint: .trailing))
                                .frame(width: max(8, geo.size.width * CGFloat(agent.stepIndex) / CGFloat(agent.totalSteps)), height: 3)
                        }
                    }
                    .frame(height: 3)
                    .padding(.top, 1)
                }
            }

            Spacer(minLength: 8)

            // Intervene / Stop Execution Button
            Button(action: {
                agent.stopExecution()
            }) {
                HStack(spacing: 5) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12, weight: .bold))
                    Text("Stop (Esc)")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(LinearGradient(colors: [Color.red.opacity(0.85), Color.red.opacity(0.65)], startPoint: .top, endPoint: .bottom))
                        .overlay(Capsule().stroke(Color.white.opacity(0.25), lineWidth: 0.5))
                        .shadow(color: Color.red.opacity(0.4), radius: 6, x: 0, y: 2)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(red: 0.08, green: 0.09, blue: 0.14).opacity(0.92))
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.cyan.opacity(0.6), Color.purple.opacity(0.4), Color.white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: Color.black.opacity(0.55), radius: 20, x: 0, y: 10)
        )
        .frame(minWidth: 460)
        .onAppear {
            isPulsing = true
        }
    }
}

// MARK: - Floating HUD Panel Window Manager
@MainActor
public final class AntigravityDesktopControlWindow: NSObject {
    public static let shared = AntigravityDesktopControlWindow()

    private var hudWindow: NSPanel?
    private var escKeyMonitor: Any?

    private override init() {
        super.init()
    }

    public func show() {
        if hudWindow == nil {
            let panel = NSPanel(
                contentRect: NSRect(x: 0, y: 0, width: 500, height: 60),
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = false
            panel.level = .floating
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
            panel.contentView = NSHostingView(rootView: AntigravityDesktopControlHUDView())
            self.hudWindow = panel
        }

        guard let panel = hudWindow, let screen = NSScreen.main else { return }

        let screenFrame = screen.frame
        let width: CGFloat = 500
        let height: CGFloat = 64
        let x = screenFrame.midX - (width / 2)
        let y = screenFrame.maxY - height - 40 // positioned elegantly below macOS top bar

        panel.setFrame(NSRect(x: x, y: y, width: width, height: height), display: true)
        panel.alphaValue = 0
        panel.orderFrontRegardless()

        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.25
            panel.animator().alphaValue = 1.0
        }

        // Global Esc key monitor to allow instant intervention
        if escKeyMonitor == nil {
            escKeyMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { event in
                if event.keyCode == 53 { // ESC key
                    Task { @MainActor in
                        AntigravityDesktopAgent.shared.stopExecution()
                    }
                }
            }
        }
    }

    public func hide() {
        guard let panel = hudWindow, panel.isVisible else { return }

        if let monitor = escKeyMonitor {
            NSEvent.removeMonitor(monitor)
            escKeyMonitor = nil
        }

        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.2
            panel.animator().alphaValue = 0
        }, completionHandler: {
            panel.orderOut(nil)
        })
    }
}
