import AppKit
import Foundation
import SwiftUI
import WebKit
import UniformTypeIdentifiers

// MARK: - Native WKWebView SwiftUI Wrapper
public struct NativeWKWebView: NSViewRepresentable {
    public let url: URL?
    @Binding public var isLoading: Bool
    @Binding public var canGoBack: Bool
    @Binding public var canGoForward: Bool
    @Binding public var title: String

    public init(
        url: URL?,
        isLoading: Binding<Bool>,
        canGoBack: Binding<Bool>,
        canGoForward: Binding<Bool>,
        title: Binding<String>
    ) {
        self.url = url
        self._isLoading = isLoading
        self._canGoBack = canGoBack
        self._canGoForward = canGoForward
        self._title = title
    }

    public func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.websiteDataStore = WKWebsiteDataStore.default()
        config.preferences.javaScriptCanOpenWindowsAutomatically = true

        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs
        config.preferences.setValue(true, forKey: "developerExtrasEnabled")

        // ── Google Botguard & Desktop Chrome Emulation Script ──
        let bypassScriptSource = """
        (function() {
            try {
                Object.defineProperty(navigator, 'vendor', { get: () => 'Google Inc.' });
            } catch(e) {}
            try {
                window.chrome = {
                    app: { isInstalled: false, InstallState: { DISABLED: 'disabled', INSTALLED: 'installed', NOT_INSTALLED: 'not_installed' }, RunningState: { CANNOT_RUN: 'cannot_run', READY_TO_RUN: 'ready_to_run', RUNNING: 'running' } },
                    runtime: {
                        OnInstalledReason: { CHROME_UPDATE: 'chrome_update', INSTALL: 'install', SHARED_MODULE_UPDATE: 'shared_module_update', UPDATE: 'update' },
                        OnRestartRequiredReason: { APP_UPDATE: 'app_update', OS_UPDATE: 'os_update', PERIODIC: 'periodic' },
                        PlatformArch: { ARM: 'arm', ARM64: 'arm64', MIPS: 'mips', MIPS64: 'mips64', X86_32: 'x86-32', X86_64: 'x86-64' },
                        PlatformNaclArch: { ARM: 'arm', MIPS: 'mips', MIPS64: 'mips64', X86_32: 'x86-32', X86_64: 'x86-64' },
                        PlatformOs: { ANDROID: 'android', CROS: 'cros', LINUX: 'linux', MAC: 'mac', OPENBSD: 'openbsd', WIN: 'win' },
                        RequestUpdateCheckStatus: { NO_UPDATE: 'no_update', THROTTLED: 'throttled', UPDATE_AVAILABLE: 'update_available' }
                    },
                    loadTimes: function() {
                        return {
                            requestTime: (window.performance ? window.performance.timing.navigationStart : Date.now()) / 1000,
                            startLoadTime: (window.performance ? window.performance.timing.navigationStart : Date.now()) / 1000,
                            commitLoadTime: (window.performance ? window.performance.timing.responseStart : Date.now()) / 1000,
                            finishDocumentLoadTime: (window.performance ? window.performance.timing.domContentLoadedEventEnd : Date.now()) / 1000,
                            finishLoadTime: (window.performance ? window.performance.timing.loadEventEnd : Date.now()) / 1000,
                            firstPaintTime: (window.performance ? window.performance.timing.responseStart : Date.now()) / 1000,
                            firstPaintAfterLoadTime: 0,
                            navigationType: 'Other',
                            wasFetchedViaSpdy: true,
                            wasNpnNegotiated: true,
                            npnNegotiatedProtocol: 'h2',
                            wasAlternateProtocolAvailable: false,
                            connectionInfo: 'h2'
                        };
                    },
                    csi: function() { return { startE: Date.now(), onloadT: Date.now(), pageT: 0, tran: 15 }; }
                };
            } catch(e) {}
            try {
                const brands = [
                    { brand: 'Google Chrome', version: '133' },
                    { brand: 'Chromium', version: '133' },
                    { brand: 'Not_A Brand', version: '24' }
                ];
                Object.defineProperty(navigator, 'userAgentData', {
                    get: () => ({
                        brands: brands,
                        mobile: false,
                        platform: 'macOS',
                        getHighEntropyValues: (hints) => Promise.resolve({
                            brands: brands,
                            mobile: false,
                            platform: 'macOS',
                            platformVersion: '15.3.1',
                            architecture: 'arm',
                            model: '',
                            bitness: '64'
                        })
                    })
                });
            } catch(e) {}
            try {
                Object.defineProperty(navigator, 'webdriver', { get: () => false });
            } catch(e) {}
        })();
        """
        let userScript = WKUserScript(source: bypassScriptSource, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        config.userContentController.addUserScript(userScript)

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36"
        webView.navigationDelegate = context.coordinator
        MiniBrowserManager.shared.activeWebView = webView

        if let initialURL = url {
            let req = URLRequest(url: initialURL, cachePolicy: .useProtocolCachePolicy, timeoutInterval: 30)
            webView.load(req)
        }
        return webView
    }

    public func updateNSView(_ nsView: WKWebView, context: Context) {
        MiniBrowserManager.shared.activeWebView = nsView
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public class Coordinator: NSObject, WKNavigationDelegate {
        var parent: NativeWKWebView

        init(_ parent: NativeWKWebView) {
            self.parent = parent
        }

        public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = true
                MiniBrowserManager.shared.isLoading = true
            }
        }

        public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.canGoBack = webView.canGoBack
                self.parent.canGoForward = webView.canGoForward
                self.parent.title = webView.title ?? ""
                MiniBrowserManager.shared.isLoading = false
                MiniBrowserManager.shared.canGoBack = webView.canGoBack
                MiniBrowserManager.shared.canGoForward = webView.canGoForward
                MiniBrowserManager.shared.pageTitle = webView.title ?? ""
                MiniBrowserManager.shared.currentURL = webView.url
            }
        }
    }
}

// MARK: - Live Browser Cradle & Dock View
// A persistent, dedicated live browser viewport supporting real-time web browsing,
// drag-and-drop URL ingress, and 1-click docking for Chrome, Firefox, Safari, and Brave.

public struct LiveBrowserCradleView: View {
    @ObservedObject var browserManager: MiniBrowserManager = .shared
    @State private var inputURLText: String = "https://www.google.com"
    @State private var isTargetHovered: Bool = false
    @State private var activeTabTitle: String = "Live Browser"
    @State private var selectedBrowserEngine: String = "Embedded Live WebKit" // or Chrome, Firefox

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // ── 1. Top Browser Navigation Bar & Engine Switcher ──
            browserHeaderToolbar

            // ── 2. The Real Live Interactive Browser Viewport ──
            ZStack {
                NativeWKWebView(
                    url: browserManager.currentURL,
                    isLoading: $browserManager.isLoading,
                    canGoBack: $browserManager.canGoBack,
                    canGoForward: $browserManager.canGoForward,
                    title: $activeTabTitle
                )
                .cornerRadius(12)

                // Drag-and-Drop Drop Zone Overlay
                if isTargetHovered {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.cyan, lineWidth: 3)
                        .background(Color.cyan.opacity(0.15))
                        .overlay(
                            VStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(.cyan)
                                Text("Drop URL or Link to Load")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        )
                }
            }
            .padding(8)
            .onDrop(of: [.url, .utf8PlainText], isTargeted: $isTargetHovered) { providers in
                for provider in providers {
                    if provider.canLoadObject(ofClass: URL.self) {
                        _ = provider.loadObject(ofClass: URL.self) { url, _ in
                            if let url = url {
                                DispatchQueue.main.async {
                                    browserManager.browse(url: url)
                                    inputURLText = url.absoluteString
                                }
                            }
                        }
                        return true
                    } else if provider.canLoadObject(ofClass: String.self) {
                        _ = provider.loadObject(ofClass: String.self) { text, _ in
                            if let text = text {
                                DispatchQueue.main.async {
                                    browserManager.search(query: text)
                                    inputURLText = text
                                }
                            }
                        }
                        return true
                    }
                }
                return false
            }

            // ── 3. Bottom Dock Handover Quick Bar (Chrome, Firefox, Safari, Brave) ──
            externalBrowserHandoverBar
        }
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(red: 0.08, green: 0.10, blue: 0.16).opacity(0.95))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.5), radius: 20)
        )
        .onAppear {
            if let u = browserManager.currentURL {
                inputURLText = u.absoluteString
            }
        }
    }

    // MARK: - Browser Header Toolbar
    @ViewBuilder
    private var browserHeaderToolbar: some View {
        HStack(spacing: 8) {
            // Window Traffic Lights / Navigation Buttons
            HStack(spacing: 6) {
                Button(action: { browserManager.goBack() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(browserManager.canGoBack ? .white : .white.opacity(0.3))
                }
                .buttonStyle(.plain)
                .disabled(!browserManager.canGoBack)

                Button(action: { browserManager.goForward() }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(browserManager.canGoForward ? .white : .white.opacity(0.3))
                }
                .buttonStyle(.plain)
                .disabled(!browserManager.canGoForward)

                Button(action: { browserManager.reload() }) {
                    Image(systemName: browserManager.isLoading ? "xmark" : "arrow.clockwise")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white.opacity(0.8))
                }
                .buttonStyle(.plain)
            }
            .padding(.leading, 12)

            // URL Search / Address Omnibar
            HStack(spacing: 6) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 9))
                    .foregroundColor(.green.opacity(0.8))

                TextField("Search or enter web address...", text: $inputURLText, onCommit: {
                    browserManager.search(query: inputURLText)
                })
                .textFieldStyle(.plain)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white)

                if browserManager.isLoading {
                    ProgressView()
                        .scaleEffect(0.6)
                        .frame(width: 14, height: 14)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.45)))

            // 1-Click Launch in Default External Browser
            Button(action: {
                browserManager.openInDefaultBrowser()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.right.square")
                    Text("Pop Out")
                }
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.cyan)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color.cyan.opacity(0.18)))
            }
            .buttonStyle(.plain)
            .padding(.trailing, 12)
        }
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.04))
    }

    // MARK: - External Browser Handover Quick Bar
    @ViewBuilder
    private var externalBrowserHandoverBar: some View {
        HStack(spacing: 12) {
            Text("Launch & Dock External:")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.5))

            // Chrome Button
            Button(action: { launchExternalBrowser(bundleID: "com.google.Chrome", appName: "Google Chrome") }) {
                HStack(spacing: 4) {
                    Image(systemName: "globe")
                        .foregroundColor(.yellow)
                    Text("Chrome")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.08)))
            }
            .buttonStyle(.plain)

            // Firefox Button
            Button(action: { launchExternalBrowser(bundleID: "org.mozilla.firefox", appName: "Firefox") }) {
                HStack(spacing: 4) {
                    Image(systemName: "flame.fill")
                        .foregroundColor(.orange)
                    Text("Firefox")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.08)))
            }
            .buttonStyle(.plain)

            // Safari Button
            Button(action: { launchExternalBrowser(bundleID: "com.apple.Safari", appName: "Safari") }) {
                HStack(spacing: 4) {
                    Image(systemName: "safari.fill")
                        .foregroundColor(.blue)
                    Text("Safari")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.08)))
            }
            .buttonStyle(.plain)

            // Brave Button
            Button(action: { launchExternalBrowser(bundleID: "com.brave.Browser", appName: "Brave") }) {
                HStack(spacing: 4) {
                    Image(systemName: "shield.fill")
                        .foregroundColor(.orange)
                    Text("Brave")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.08)))
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.35))
    }

    private func launchExternalBrowser(bundleID: String, appName: String) {
        HapticFeedback.selection()
        guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else { return }
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        if let targetURL = browserManager.currentURL {
            NSWorkspace.shared.open([targetURL], withApplicationAt: appURL, configuration: config, completionHandler: nil)
        } else {
            NSWorkspace.shared.openApplication(at: appURL, configuration: config, completionHandler: nil)
        }
    }
}
