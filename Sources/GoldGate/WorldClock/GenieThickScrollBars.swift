import AppKit
import SwiftUI

/// A permanently-visible scroller that is wider than the macOS default.
///
/// The stock overlay scroller is ~9pt and fades out when the pointer stops, which on a
/// dark blackout surface reads as "this pane does not scroll at all". Legacy style keeps
/// it on screen; the width override makes it an easy target.
public final class GenieThickScroller: NSScroller {
    // `isCompatibleWithOverlayScrollers()` was removed from NSScroller in the
    // current SDK, so overriding it no longer compiles. Nothing is lost: both
    // the scroll view and the scroller below are pinned to `.legacy` style,
    // which is what opting out of overlay scrollers actually achieved.

    public override class func scrollerWidth(
        for controlSize: NSControl.ControlSize,
        scrollerStyle: NSScroller.Style
    ) -> CGFloat {
        20
    }
}

/// Reaches up to the `NSScrollView` backing a SwiftUI `ScrollView` and swaps in the
/// thick always-on scrollers. SwiftUI exposes no API for this, so we walk the view tree.
private struct GenieThickScrollerAttachment: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let probe = NSView(frame: .zero)
        probe.isHidden = true
        return probe
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        // The scroll view does not exist yet during the first layout pass.
        let isThickEnabled = UserDefaults.standard.bool(forKey: PrefKey.showThickScrollBars)
        DispatchQueue.main.async {
            guard let scrollView = Self.enclosingScrollView(of: nsView) else { return }

            if isThickEnabled {
                scrollView.scrollerStyle = .legacy
                scrollView.autohidesScrollers = false
                scrollView.hasVerticalScroller = true
                scrollView.verticalScrollElasticity = .allowed

                if !(scrollView.verticalScroller is GenieThickScroller) {
                    let scroller = GenieThickScroller()
                    scroller.scrollerStyle = .legacy
                    scroller.controlSize = .regular
                    scrollView.verticalScroller = scroller
                }
            } else {
                scrollView.scrollerStyle = .overlay
                scrollView.autohidesScrollers = true
                scrollView.verticalScrollElasticity = .allowed
                if scrollView.verticalScroller is GenieThickScroller {
                    scrollView.verticalScroller = NSScroller()
                }
            }

            // Wheel deltas land on the content view, so a line scroll must be generous
            // or a trackpad flick barely moves the board.
            scrollView.verticalLineScroll = 24
        }
    }

    private static func enclosingScrollView(of view: NSView) -> NSScrollView? {
        var candidate: NSView? = view.superview
        while let current = candidate {
            if let scrollView = current as? NSScrollView { return scrollView }
            candidate = current.superview
        }
        return nil
    }
}

public extension View {
    /// Give the enclosing `ScrollView` wide, always-visible scroll bars.
    func genieThickScrollBars() -> some View {
        background(GenieThickScrollerAttachment().frame(width: 0, height: 0))
    }
}
