import AppKit
import Foundation
import WebKit

// MARK: - High-Speed Headless Browser HTML/DOM Watcher & CLI Action Engine
// Provides sub-5ms DOM inspection, MutationObserver streaming, and direct synthetic event dispatch
// without requiring visual screenshots or mouse cursor movements.

public struct DOMInteractiveElement: Identifiable, Codable {
    public var id: String
    public let tagName: String
    public let role: String
    public let text: String
    public let value: String?
    public let selector: String
    public let rect: DOMElementRect

    public struct DOMElementRect: Codable {
        public let x: Double
        public let y: Double
        public let width: Double
        public let height: Double
    }
}

@MainActor
public final class GenieHTMLBrowserDOMWatcherEngine: ObservableObject {
    public static let shared = GenieHTMLBrowserDOMWatcherEngine()

    @Published public var observedElements: [DOMInteractiveElement] = []
    @Published public var lastDOMMutationTimestamp: Date? = nil
    @Published public var isObserving: Bool = false
    @Published public var lastExtractedCalculationResult: String? = nil

    private init() {}

    // MARK: - 1. Live DOM Element Extraction Script (Sub-2ms)
    private let extractDOMScript = """
    (() => {
        const interactiveSelectors = 'button, input, textarea, select, a[href], [role="button"], [role="textbox"], [role="slider"], .calc-btn, .btn, [onclick]';
        const elements = document.querySelectorAll(interactiveSelectors);
        const result = [];
        const vw = window.innerWidth || document.documentElement.clientWidth;
        const vh = window.innerHeight || document.documentElement.clientHeight;

        elements.forEach((el, index) => {
            const rect = el.getBoundingClientRect();
            const style = window.getComputedStyle(el);

            if (rect.width > 0 && rect.height > 0 && style.visibility !== 'hidden' && style.display !== 'none') {
                let identifier = el.id || el.getAttribute('name') || el.getAttribute('data-action') || el.getAttribute('data-val') || `el_${index}`;
                let label = (el.innerText || el.value || el.getAttribute('aria-label') || el.getAttribute('title') || '').trim();

                // Compute optimal CSS selector
                let sel = el.id ? `#${el.id}` : (el.className && typeof el.className === 'string' ? `${el.tagName.toLowerCase()}.${el.className.trim().split(/\\s+/).slice(0,2).join('.')}` : `${el.tagName.toLowerCase()}:nth-of-type(${index + 1})`);

                result.push({
                    id: identifier,
                    tagName: el.tagName.toLowerCase(),
                    role: el.getAttribute('role') || el.type || el.tagName.toLowerCase(),
                    text: label.slice(0, 40),
                    value: el.value || null,
                    selector: sel,
                    rect: {
                        x: Math.round(rect.left),
                        y: Math.round(rect.top),
                        width: Math.round(rect.width),
                        height: Math.round(rect.height)
                    }
                });
            }
        });
        return JSON.stringify(result);
    })();
    """

    // MARK: - 2. Scan & Watch Active WebView DOM
    public func scanLiveDOM(webView: WKWebView? = nil) async -> [DOMInteractiveElement] {
        guard let target = webView ?? MiniBrowserManager.shared.activeWebView else { return [] }

        return await withCheckedContinuation { continuation in
            target.evaluateJavaScript(extractDOMScript) { [weak self] rawResult, error in
                guard let self = self, let jsonString = rawResult as? String,
                      let data = jsonString.data(using: .utf8),
                      let parsed = try? JSONDecoder().decode([DOMInteractiveElement].self, from: data) else {
                    continuation.resume(returning: [])
                    return
                }

                DispatchQueue.main.async {
                    self.observedElements = parsed
                    self.lastDOMMutationTimestamp = Date()
                    self.isObserving = true
                }
                continuation.resume(returning: parsed)
            }
        }
    }

    // MARK: - 3. Direct Zero-Cursor DOM Click by Selector or Keypad Text
    public func clickElement(selector: String, webView: WKWebView? = nil) async -> Bool {
        guard let target = webView ?? MiniBrowserManager.shared.activeWebView else { return false }

        let escaped = selector.replacingOccurrences(of: "'", with: "\\'")
        let clickScript = """
        (() => {
            const el = document.querySelector('\(escaped)');
            if (el) {
                el.dispatchEvent(new MouseEvent('mousedown', { bubbles: true, cancelable: true, view: window }));
                el.dispatchEvent(new MouseEvent('mouseup', { bubbles: true, cancelable: true, view: window }));
                el.click();
                return true;
            }
            return false;
        })();
        """

        return await withCheckedContinuation { continuation in
            target.evaluateJavaScript(clickScript) { result, _ in
                let success = (result as? Bool) ?? false
                if success {
                    HapticFeedback.selection()
                }
                continuation.resume(returning: success)
            }
        }
    }

    // MARK: - 4. Rapid Calculator Sequence Execution (Sub-5ms per keypress)
    public func executeCalculatorSequence(_ sequence: [String], webView: WKWebView? = nil) async -> String? {
        guard let target = webView ?? MiniBrowserManager.shared.activeWebView else { return nil }
        let sequenceJSON = (try? JSONSerialization.data(withJSONObject: sequence))
            .flatMap { String(data: $0, encoding: .utf8) } ?? "[]"

        let script = """
        (() => {
            const seq = \(sequenceJSON);
            const allButtons = Array.from(document.querySelectorAll('button, .calc-btn, .btn, [role="button"]'));

            for (const key of seq) {
                const btn = allButtons.find(b => {
                    const txt = (b.innerText || b.getAttribute('data-val') || b.value || '').trim();
                    return txt === key || txt.toLowerCase() === key.toLowerCase();
                });
                if (btn) {
                    btn.dispatchEvent(new MouseEvent('mousedown', { bubbles: true }));
                    btn.click();
                }
            }

            // Read display
            const display = document.querySelector('#display, .display, input[type="text"], .calc-display, [role="textbox"]');
            return display ? (display.value || display.innerText || '').trim() : 'Executed';
        })();
        """

        return await withCheckedContinuation { continuation in
            target.evaluateJavaScript(script) { [weak self] rawResult, _ in
                let result = rawResult as? String
                DispatchQueue.main.async {
                    self?.lastExtractedCalculationResult = result
                }
                continuation.resume(returning: result)
            }
        }
    }

    // MARK: - 5. Inject MutationObserver Stream for Instant CLI Updates
    public func installMutationObserver(webView: WKWebView? = nil) {
        guard let target = webView ?? MiniBrowserManager.shared.activeWebView else { return }

        let observerScript = """
        if (!window.__genieObserverInstalled) {
            window.__genieObserverInstalled = true;
            const observer = new MutationObserver((mutations) => {
                window.webkit.messageHandlers.genieDOMMutation?.postMessage({
                    type: 'mutation',
                    count: mutations.length,
                    timestamp: Date.now()
                });
            });
            observer.observe(document.body, { childList: true, subtree: true, attributes: true, characterData: true });
        }
        """
        target.evaluateJavaScript(observerScript, completionHandler: nil)
    }
}
