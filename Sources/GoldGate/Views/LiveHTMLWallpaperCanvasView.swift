import AppKit
import Foundation
import SwiftUI
import WebKit

/// Dedicated high-performance WKWebView representable for rendering interactive HTML5/Canvas
/// wallpapers (such as Neural Bloom) within Genie's desktop, top dashboard, and spatial grid layers.
public struct LiveHTMLWallpaperCanvasView: NSViewRepresentable {
    public let fileURL: URL
    public var isBackdrop: Bool
    public var lightningEnabled: Bool
    public var windowOffset: CGSize

    public init(
        fileURL: URL,
        isBackdrop: Bool = false,
        lightningEnabled: Bool = true,
        windowOffset: CGSize = .zero
    ) {
        self.fileURL = fileURL
        self.isBackdrop = isBackdrop
        self.lightningEnabled = lightningEnabled
        self.windowOffset = windowOffset
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    public final class Coordinator {
        var parent: LiveHTMLWallpaperCanvasView
        var lastOffset: CGSize = .zero
        var eventMonitor: Any?
        var lastMouseTime: TimeInterval = 0

        init(parent: LiveHTMLWallpaperCanvasView) {
            self.parent = parent
            self.lastOffset = parent.windowOffset
        }

        func setupEventMonitor(for webView: WKWebView) {
            guard eventMonitor == nil else { return }
            eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved, .leftMouseDown]) { [weak self, weak webView] event in
                guard let self = self, let webView = webView, webView.window != nil else { return event }
                let locInWindow = event.locationInWindow
                let pt = webView.convert(locInWindow, from: nil)
                if webView.bounds.contains(pt) {
                    let h = webView.bounds.height
                    let webY = h - pt.y // convert to web coordinate system where (0,0) is top-left
                    if event.type == .leftMouseDown {
                        webView.evaluateJavaScript("if (window.triggerBurst) { window.triggerBurst(\(pt.x), \(webY)); }", completionHandler: nil)
                    } else {
                        let now = ProcessInfo.processInfo.systemUptime
                        if now - self.lastMouseTime > 0.016 { // throttle to ~60fps
                            self.lastMouseTime = now
                            webView.evaluateJavaScript("if (window.updateCursorPosition) { window.updateCursorPosition(\(pt.x), \(webY)); }", completionHandler: nil)
                        }
                    }
                }
                return event
            }
        }

        func cleanup() {
            if let monitor = eventMonitor {
                NSEvent.removeMonitor(monitor)
                eventMonitor = nil
            }
        }

        deinit {
            cleanup()
        }
    }

    public func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs
        config.preferences.setValue(true, forKey: "allowFileAccessFromFileURLs")

        if isBackdrop {
            let scriptSource = """
            document.addEventListener('DOMContentLoaded', () => {
                const elements = document.querySelectorAll('.title, .hud, #title, #hud, h1, h2, h3, p');
                elements.forEach(el => { el.style.display = 'none'; el.style.visibility = 'hidden'; });
                document.body.style.background = 'transparent';
                document.body.classList.add('transparent-mode');
                window.lightningEnabled = \(lightningEnabled ? "true" : "false");
            });
            """
            let userScript = WKUserScript(source: scriptSource, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
            config.userContentController.addUserScript(userScript)
        }

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        webView.allowsMagnification = false
        webView.loadFileURL(fileURL, allowingReadAccessTo: fileURL.deletingLastPathComponent())
        context.coordinator.setupEventMonitor(for: webView)
        return webView
    }

    public func updateNSView(_ nsView: WKWebView, context: Context) {
        if nsView.url != fileURL {
            nsView.loadFileURL(fileURL, allowingReadAccessTo: fileURL.deletingLastPathComponent())
        }

        if isBackdrop {
            // Guarantee no text is rendered
            let cleanScript = """
            document.querySelectorAll('.title, .hud, #title, #hud, h1, h2, h3, p').forEach(el => {
                el.style.display = 'none';
                el.style.visibility = 'hidden';
            });
            document.body.style.background = 'transparent';
            window.lightningEnabled = \(lightningEnabled ? "true" : "false");
            """
            nsView.evaluateJavaScript(cleanScript, completionHandler: nil)
        }

        // Check if window movement offset changed
        let dx = windowOffset.width - context.coordinator.lastOffset.width
        let dy = windowOffset.height - context.coordinator.lastOffset.height
        if abs(dx) > 0.5 || abs(dy) > 0.5 {
            context.coordinator.lastOffset = windowOffset
            let dragScript = "if (window.onWindowDrag) { window.onWindowDrag(\(dx), \(dy)); }"
            nsView.evaluateJavaScript(dragScript, completionHandler: nil)
        }
    }

    public static func dismantleNSView(_ nsView: WKWebView, coordinator: Coordinator) {
        coordinator.cleanup()
        nsView.stopLoading()
        nsView.navigationDelegate = nil
        nsView.uiDelegate = nil
        nsView.loadHTMLString("", baseURL: nil)
    }
}
