import AppKit
import SwiftUI
import WebKit

// MARK: - 🌐 Genie Instant Website Chat Renderer
/// Renders full, rich, interactive websites directly inside the chat interface using atomic copy-and-paste ingestion.
/// Instead of streaming character-by-character code blocks, the entire website mounts instantaneously
/// inside a hardware-accelerated WebKit view with interactive touch, clicks, and animations.
public struct GenieInstantWebsiteChatView: View {
    public let htmlContent: String
    public let title: String
    @State private var isHovering: Bool = false
    @State private var isCopied: Bool = false

    public init(htmlContent: String, title: String = "Interactive Web App") {
        self.htmlContent = htmlContent
        self.title = title
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // ── Top Action & Title Bar ──
            HStack(spacing: 8) {
                HStack(spacing: 6) {
                    Circle().fill(Color.red.opacity(0.85)).frame(width: 9, height: 9)
                    Circle().fill(Color.yellow.opacity(0.85)).frame(width: 9, height: 9)
                    Circle().fill(Color.green.opacity(0.85)).frame(width: 9, height: 9)
                }
                .padding(.leading, 6)

                Text(title)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.90))
                    .lineLimit(1)

                Spacer()

                // Action Buttons
                Button(action: {
                    GenieSharedClipboardEngine.shared.copyToUser(htmlContent, format: .html)
                    isCopied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { isCopied = false }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                        Text(isCopied ? "Copied!" : "Copy Code")
                    }
                    .font(.system(size: 9.5, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.80))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.white.opacity(0.12)))
                }
                .buttonStyle(.plain)

                Button(action: {
                    openInDefaultBrowser()
                }) {
                    Image(systemName: "arrow.up.right.square")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.80))
                        .padding(4)
                        .background(Circle().fill(Color.white.opacity(0.12)))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.92))

            // ── Live Interactive WKWebView ──
            InlineWebKitRepresentable(htmlContent: htmlContent)
                .frame(minHeight: 280, maxHeight: 420)
        }
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.16), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.28), radius: 12, x: 0, y: 6)
        .padding(.vertical, 4)
    }

    private func openInDefaultBrowser() {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("genie_chat_website_\(UUID().uuidString.prefix(8)).html")
        try? htmlContent.write(to: tempURL, atomically: true, encoding: .utf8)
        NSWorkspace.shared.open(tempURL)
    }
}

// MARK: - Native WebKit Host
public struct InlineWebKitRepresentable: NSViewRepresentable {
    public let htmlContent: String

    public func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    public func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let prefs = WKWebpagePreferences()
        prefs.allowsContentJavaScript = true
        config.defaultWebpagePreferences = prefs

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        if #available(macOS 12.0, *) {
            webView.underPageBackgroundColor = .clear
        }
        webView.navigationDelegate = context.coordinator
        webView.loadHTMLString(htmlContent, baseURL: nil)
        return webView
    }

    public func updateNSView(_ nsView: WKWebView, context: Context) {
        if context.coordinator.lastHTML != htmlContent {
            context.coordinator.lastHTML = htmlContent
            nsView.loadHTMLString(htmlContent, baseURL: nil)
        }
    }

    public class Coordinator: NSObject, WKNavigationDelegate {
        var lastHTML: String?
    }
}
