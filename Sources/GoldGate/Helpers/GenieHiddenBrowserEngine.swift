import AppKit
import Foundation
import WebKit

// MARK: - Genie Hidden Browser Engine
// A second WKWebView that runs in parallel with the visible Live Browser
// (MiniBrowserManager/LiveBrowserCradleView) but is hosted in a window that is created
// and never ordered front, so the model can fetch and read a page without popping open
// anything on the user's actual screen or disturbing whatever they're looking at —
// the browsing equivalent of how GenieBackgroundDesktopAgentEngine drives a real app on
// its own dedicated Space instead of the Space the user is looking at.
@MainActor
public final class GenieHiddenBrowserEngine: NSObject, ObservableObject {
    public static let shared = GenieHiddenBrowserEngine()

    @Published public var isFetching: Bool = false
    @Published public var lastURL: URL?
    @Published public var lastPageText: String = ""
    @Published public var lastScreenshotPath: String?
    @Published public var statusMessage: String = "Hidden Browser idle"

    /// Exposed so other engines (e.g. GenieHTMLBrowserDOMWatcherEngine) can target the
    /// hidden page instead of the visible one when the model wants to click into it.
    public private(set) var webView: WKWebView?

    private var hostWindow: NSWindow?
    private var navigationContinuation: CheckedContinuation<Void, Never>?

    private override init() {
        super.init()
    }

    private func ensureWebView() -> WKWebView {
        if let webView = webView {
            return webView
        }

        let config = WKWebViewConfiguration()
        config.websiteDataStore = WKWebsiteDataStore.default()
        let view = WKWebView(frame: NSRect(x: 0, y: 0, width: 1280, height: 900), configuration: config)
        view.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36"
        view.navigationDelegate = self

        // Off-screen host: real window backing so WebKit lays out and paints normally
        // (needed for a faithful screenshot), but it is never shown, activated, or
        // ordered front, so it is invisible to the user for the entire session.
        let window = NSWindow(
            contentRect: NSRect(x: -12000, y: -12000, width: 1280, height: 900),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        window.contentView = view
        window.isReleasedWhenClosed = false
        window.setIsVisible(false)

        self.hostWindow = window
        self.webView = view
        return view
    }

    /// Loads `url` off-screen, waits for the page to finish (or `timeout`), then reads back
    /// the rendered text and a screenshot — so the caller gets what actually rendered rather
    /// than a bare "loaded" acknowledgement.
    public func loadAndRead(
        url: URL,
        maxChars: Int = 6000,
        timeout: TimeInterval = 15
    ) async -> (text: String, screenshotPath: String?, title: String) {
        isFetching = true
        lastURL = url
        statusMessage = "Fetching \(url.host ?? url.absoluteString) in hidden browser..."

        let view = ensureWebView()
        view.load(URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: timeout))

        await waitForNavigation(timeout: timeout)

        let title = view.title?.isEmpty == false ? view.title! : (url.host ?? url.absoluteString)
        let text = await extractText(from: view, maxChars: maxChars)
        let screenshotPath = await captureScreenshot(of: view)

        lastPageText = text
        lastScreenshotPath = screenshotPath
        isFetching = false
        statusMessage = text.isEmpty
            ? "Hidden Browser: \(url.host ?? "page") loaded but returned no readable text."
            : "Hidden Browser read \(text.count) characters from \(url.host ?? url.absoluteString)."

        return (text, screenshotPath, title)
    }

    private func waitForNavigation(timeout: TimeInterval) async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { @MainActor in
                await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
                    self.navigationContinuation = cont
                }
            }
            group.addTask {
                try? await Task.sleep(nanoseconds: UInt64(max(1, timeout) * 1_000_000_000))
            }
            await group.next()
            group.cancelAll()
        }
        navigationContinuation = nil
    }

    private func extractText(from view: WKWebView, maxChars: Int) async -> String {
        await withCheckedContinuation { cont in
            view.evaluateJavaScript("document.body ? document.body.innerText : ''") { result, _ in
                let text = (result as? String) ?? ""
                cont.resume(returning: String(text.trimmingCharacters(in: .whitespacesAndNewlines).prefix(maxChars)))
            }
        }
    }

    private func captureScreenshot(of view: WKWebView) async -> String? {
        await withCheckedContinuation { cont in
            view.takeSnapshot(with: nil) { image, _ in
                guard let image = image,
                      let tiff = image.tiffRepresentation,
                      let rep = NSBitmapImageRep(data: tiff),
                      let pngData = rep.representation(using: .png, properties: [:]) else {
                    cont.resume(returning: nil)
                    return
                }

                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
                let fileURL = GenieStandardDirectories.polaroidsURL
                    .appendingPathComponent("Genie_HiddenBrowser_\(formatter.string(from: Date())).png")
                do {
                    try pngData.write(to: fileURL)
                    cont.resume(returning: fileURL.path)
                } catch {
                    cont.resume(returning: nil)
                }
            }
        }
    }
}

extension GenieHiddenBrowserEngine: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        navigationContinuation?.resume()
        navigationContinuation = nil
    }

    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        navigationContinuation?.resume()
        navigationContinuation = nil
    }

    public func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        navigationContinuation?.resume()
        navigationContinuation = nil
    }
}
