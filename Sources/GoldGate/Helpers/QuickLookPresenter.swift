import AppKit
import QuickLookUI

/// Quick Look, the way Finder does it — the real `QLPreviewPanel`, not a bespoke
/// preview sheet. That gets the platform's own renderers for every file type,
/// the standard chrome, full-screen and share, and the shortcuts users already know.
public final class QuickLookPresenter: NSObject, QLPreviewPanelDataSource, QLPreviewPanelDelegate {
    public static let shared = QuickLookPresenter()

    private var urls: [URL] = []
    private var startIndex: Int = 0

    private override init() { super.init() }

    /// Show Quick Look for `urls`, opening on `current` if it is among them.
    /// Toggles closed if the panel is already up, matching the spacebar behaviour.
    public func present(_ urls: [URL], current: URL? = nil) {
        guard !urls.isEmpty, let panel = QLPreviewPanel.shared() else { return }

        if panel.isVisible, self.urls == urls {
            panel.orderOut(nil)
            return
        }

        self.urls = urls
        self.startIndex = current.flatMap { urls.firstIndex(of: $0) } ?? 0

        panel.dataSource = self
        panel.delegate = self
        panel.reloadData()
        panel.currentPreviewItemIndex = startIndex
        panel.makeKeyAndOrderFront(nil)
    }

    // MARK: QLPreviewPanelDataSource

    public func numberOfPreviewItems(in panel: QLPreviewPanel!) -> Int {
        urls.count
    }

    public func previewPanel(_ panel: QLPreviewPanel!, previewItemAt index: Int) -> QLPreviewItem! {
        guard urls.indices.contains(index) else { return nil }
        return urls[index] as NSURL
    }

    // MARK: QLPreviewPanelDelegate

    /// Let the panel take arrow keys and space itself, so navigation matches Finder.
    public func previewPanel(_ panel: QLPreviewPanel!, handle event: NSEvent!) -> Bool {
        false
    }
}

public extension URL {
    /// Files a browser can render directly, for the "Open in Browser" action.
    var isBrowserRenderable: Bool {
        ["html", "htm", "svg", "pdf", "xhtml", "md", "markdown", "txt", "json", "csv"]
            .contains(pathExtension.lowercased())
    }
}
