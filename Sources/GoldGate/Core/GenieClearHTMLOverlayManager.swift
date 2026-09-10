import AppKit
import SwiftUI

/// Coordinates a clear, transparent floating overlay panel capable of loading dynamically generated HTML,
/// clickable images, and actionable solutions connected directly to native Swift.
@MainActor
public final class GenieClearHTMLOverlayManager: ObservableObject {
    public static let shared = GenieClearHTMLOverlayManager()

    @Published public private(set) var isVisible: Bool = false
    private var overlayPanel: NSPanel?

    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleToggleNotification),
            name: NSNotification.Name("GenieToggleClearHTMLOverlay"),
            object: nil
        )
    }

    @objc private func handleToggleNotification() {
        toggle()
    }

    public func toggle() {
        if isVisible {
            hide()
        } else {
            show()
        }
    }

    public func show() {
        guard let screen = NSScreen.main else { return }

        if overlayPanel == nil {
            let panel = NSPanel(
                contentRect: screen.frame,
                styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            panel.isOpaque = false
            panel.backgroundColor = .clear
            panel.hasShadow = false
            panel.level = .floating
            panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
            panel.isMovableByWindowBackground = false
            panel.ignoresMouseEvents = false

            let hostingView = NSHostingView(
                rootView: GenieClearHTMLOverlayView(onClose: { [weak self] in
                    self?.hide()
                })
            )
            hostingView.autoresizingMask = [.width, .height]
            panel.contentView = hostingView

            self.overlayPanel = panel
        }

        if let panel = overlayPanel {
            panel.setFrame(screen.frame, display: true)
            panel.makeKeyAndOrderFront(nil)
            panel.orderFrontRegardless()
            isVisible = true
            UserDefaults.standard.set(true, forKey: PrefKey.clearHTMLOverlayEnabled)
            HapticFeedback.selection()
        }
    }

    public func hide() {
        overlayPanel?.orderOut(nil)
        isVisible = false
        UserDefaults.standard.set(false, forKey: PrefKey.clearHTMLOverlayEnabled)
        HapticFeedback.selection()
    }
}
