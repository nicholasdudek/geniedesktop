import AppKit
import SwiftUI

/// Captures wheel gestures while the pointer is over the right dock without stealing clicks.
struct RightDockScrollWheelView: NSViewRepresentable {
    let onScroll: (CGFloat) -> Void

    func makeNSView(context: Context) -> ScrollView {
        let view = ScrollView()
        view.onScroll = onScroll
        return view
    }

    func updateNSView(_ nsView: ScrollView, context: Context) {
        nsView.onScroll = onScroll
    }

    final class ScrollView: NSView {
        var onScroll: ((CGFloat) -> Void)?

        override func scrollWheel(with event: NSEvent) {
            guard abs(event.scrollingDeltaY) > 0.01 else { return }
            onScroll?(event.scrollingDeltaY)
        }

        override func hitTest(_ point: NSPoint) -> NSView? {
            // The dock's SwiftUI buttons remain responsible for clicks.
            nil
        }
    }
}
