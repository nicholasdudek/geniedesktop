import AppKit
import Combine
import Foundation
import WebKit

// MARK: - Mini Browser & AI Web Observer Manager
public final class MiniBrowserManager: ObservableObject {
    public static let shared = MiniBrowserManager()

    @Published public var currentURL: URL? = URL(string: "https://www.google.com")
    @Published public var activeQuery: String = ""
    @Published public var pageTitle: String = "Google"
    @Published public var isLoading: Bool = false
    @Published public var canGoBack: Bool = false
    @Published public var canGoForward: Bool = false

    // AI Browsing Telemetry: lets the user see what the AI model is searching & viewing!
    @Published public var isAIBrowsing: Bool = false
    @Published public var aiBrowsingStatus: String = ""

    public weak var activeWebView: WKWebView?

    private init() {}

    /// Executes an Internet Search or navigates to URL and updates the mini browser window
    public func search(query: String, triggeredByAI: Bool = false) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let targetURL: URL? = {
            if trimmed.lowercased().hasPrefix("http://") || trimmed.lowercased().hasPrefix("https://") {
                return URL(string: trimmed)
            }
            if trimmed.contains(".") && !trimmed.contains(" ") && !trimmed.hasSuffix(".") {
                return URL(string: "https://\(trimmed)")
            }
            let encoded = trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? trimmed
            return URL(string: "https://www.google.com/search?q=\(encoded)")
        }()

        guard let url = targetURL else { return }

        DispatchQueue.main.async {
            self.activeQuery = trimmed
            self.currentURL = url
            self.isAIBrowsing = triggeredByAI
            self.aiBrowsingStatus = triggeredByAI ? "AI Searching: \"\(trimmed)\"" : ""

            // Pop up the canvas window into Mini Browser mode
            NotificationCenter.default.post(
                name: NSNotification.Name("NexusOpenMiniBrowser"),
                object: url
            )

            self.load(url: url)
        }
    }

    /// Navigates the mini browser to a specific web URL (user or AI triggered)
    public func browse(url: URL, triggeredByAI: Bool = false) {
        DispatchQueue.main.async {
            self.currentURL = url
            self.activeQuery = url.absoluteString
            self.isAIBrowsing = triggeredByAI
            let host = url.host ?? url.absoluteString
            self.aiBrowsingStatus = triggeredByAI ? "AI Viewing: \(host)" : ""

            NotificationCenter.default.post(
                name: NSNotification.Name("NexusOpenMiniBrowser"),
                object: url
            )

            self.load(url: url)
        }
    }

    /// Directly loads URL into the active WKWebView
    public func load(url: URL) {
        DispatchQueue.main.async {
            self.currentURL = url
            if let webView = self.activeWebView {
                let req = URLRequest(url: url, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30)
                webView.load(req)
            }
        }
    }

    public func goBack() {
        activeWebView?.goBack()
    }

    public func goForward() {
        activeWebView?.goForward()
    }

    public func reload() {
        activeWebView?.reload()
    }

    public func openInDefaultBrowser() {
        if let url = currentURL {
            NSWorkspace.shared.open(url)
        } else {
            if let gUrl = URL(string: "https://www.google.com") {
                NSWorkspace.shared.open(gUrl)
            }
        }
    }

    /// Waits briefly for the current navigation to finish, then reads back the rendered
    /// page's text via `document.body.innerText` — closes the loop so a caller (the AI
    /// model) actually gets what rendered, instead of only a "loaded" acknowledgement.
    public func extractPageText(maxChars: Int = 6000, loadTimeout: TimeInterval = 12) async -> String {
        let deadline = Date().addingTimeInterval(loadTimeout)
        while isLoading && Date() < deadline {
            try? await Task.sleep(nanoseconds: 200_000_000)
        }

        guard let webView = activeWebView else { return "" }
        return await withCheckedContinuation { (cont: CheckedContinuation<String, Never>) in
            webView.evaluateJavaScript("document.body ? document.body.innerText : ''") { result, _ in
                let text = (result as? String) ?? ""
                cont.resume(returning: String(text.trimmingCharacters(in: .whitespacesAndNewlines).prefix(maxChars)))
            }
        }
    }

    public func finishAIBrowsing(summary: String? = nil) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.isAIBrowsing = false
            self.aiBrowsingStatus = ""
        }
    }
}
