import SwiftUI
import WebKit

/// A transparent floating overlay view hosting an interactive WebKit canvas.
/// Instruments mouse events, clickable images, and dynamic HTML solutions directly connected to native Swift.
public struct GenieClearHTMLOverlayView: View {
    @State private var currentTemplate: HTMLOverlayTemplate = .autonomousDeck
    @State private var statusFeedback: String? = nil
    @State private var reloadToken: UUID = UUID()
    public var onClose: () -> Void = {}

    public enum HTMLOverlayTemplate: String, CaseIterable, Identifiable {
        case autonomousDeck = "Autonomous Deck 🛸"
        case solutionsHub = "Solutions Hub ⚡"
        case imageGallery = "Clickable Images 🖼️"
        case customSolution = "Custom AI HTML ✨"

        public var id: String { rawValue }
    }

    public init(onClose: @escaping () -> Void = {}) {
        self.onClose = onClose
    }

    public var body: some View {
        ZStack(alignment: .top) {
            // Transparent WebKit Canvas
            TransparentWebKitView(
                htmlContent: currentHTMLContent,
                reloadToken: reloadToken,
                onSwiftAction: { actionPayload in
                    handleSwiftAction(actionPayload)
                }
            )
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Floating Minimal Control HUD
            VStack(spacing: 8) {
                HStack(spacing: 12) {
                    HStack(spacing: 6) {
                        Image(systemName: "wand.and.stars")
                            .foregroundColor(.cyan)
                        Text("Genie Clear Web Overlay")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    // Template Picker
                    Picker("", selection: $currentTemplate) {
                        ForEach(HTMLOverlayTemplate.allCases) { template in
                            Text(template.rawValue).tag(template)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 320)
                    .onChange(of: currentTemplate) { _, _ in
                        HapticFeedback.selection()
                        reloadToken = UUID()
                    }

                    // Reload Button
                    Button(action: {
                        HapticFeedback.selection()
                        reloadToken = UUID()
                        showFeedback("🔄 Reloaded HTML canvas")
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.85))
                            .padding(6)
                            .background(Circle().fill(Color.white.opacity(0.12)))
                    }
                    .buttonStyle(.plain)
                    .help("Reload HTML Canvas")

                    // Dismiss Button
                    Button(action: {
                        HapticFeedback.selection()
                        onClose()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.90))
                            .padding(6)
                            .background(Circle().fill(Color.red.opacity(0.35)))
                    }
                    .buttonStyle(.plain)
                    .help("Close Clear Overlay")
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color(red: 0.08, green: 0.10, blue: 0.16).opacity(0.75))
                        .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 0.8))
                        .shadow(color: Color.black.opacity(0.4), radius: 12, y: 4)
                )

                // Feedback Toast
                if let status = statusFeedback {
                    Text(status)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.cyan)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 5)
                        .background(Capsule().fill(Color.black.opacity(0.65)))
                        .overlay(Capsule().stroke(Color.cyan.opacity(0.4), lineWidth: 0.6))
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.top, 16)
            .padding(.horizontal, 24)
        }
        .background(Color.clear)
    }

    private var currentHTMLContent: String {
        switch currentTemplate {
        case .autonomousDeck:
            return GenieHTMLSolutionGenerator.autonomousDeckHTML()
        case .solutionsHub:
            return GenieHTMLSolutionGenerator.solutionsHubHTML()
        case .imageGallery:
            let sampleImages = [
                (url: "https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?w=400&auto=format&fit=crop&q=60",
                 title: "Fluid Abstract", subtitle: "Click to analyze vision gradients", action: "inspectImage"),
                (url: "https://images.unsplash.com/photo-1579783902614-a3fb3927b675?w=400&auto=format&fit=crop&q=60",
                 title: "Living Canvas", subtitle: "Click to set workspace mood", action: "inspectImage"),
                (url: "https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=400&auto=format&fit=crop&q=60",
                 title: "Cyberpunk Terminal", subtitle: "Click to open Dev studio", action: "switchStation"),
                (url: "https://images.unsplash.com/photo-1518770660439-4636190af475?w=400&auto=format&fit=crop&q=60",
                 title: "Neural Engine", subtitle: "Click to inspect GPU memory", action: "runCommand")
            ]
            return GenieHTMLSolutionGenerator.imageGalleryHTML(images: sampleImages)
        case .customSolution:
            let customBody = """
            <p style="font-size: 13px; color: #94a3b8; margin-bottom: 16px;">
                Generated live from Genie AI. Mouse events on buttons, images, and solution elements trigger Swift runtime hooks.
            </p>
            <div style="display: flex; gap: 12px; flex-wrap: wrap;">
                <button class="btn-action" data-action="switchStation" data-value="zenith">🌌 Go to Zenith (Chat)</button>
                <button class="btn-action" data-action="switchStation" data-value="applications">🚀 Open App Launcher</button>
                <button class="btn-action" data-action="openFinder" data-value="Downloads">📥 Open Downloads</button>
            </div>
            """
            return GenieHTMLSolutionGenerator.wrapCustomHTML(customBody, title: "Custom Agent Solution")
        }
    }

    private func handleSwiftAction(_ payload: [String: Any]) {
        let eventType = payload["eventType"] as? String ?? "click"
        let action = payload["action"] as? String ?? ""
        let value = payload["value"] as? String ?? ""
        let title = payload["title"] as? String ?? "Item"

        guard eventType == "click" else { return }

        HapticFeedback.selection()

        switch action {
        case "openIPhone":
            iPhoneMirrorManager.shared.launchOrActivateApp()
            showFeedback("📱 Activated iPhone Mirroring")

        case "iphoneTapHome":
            AntigravityDesktopAgent.shared.executeScript([.openiPhone, .swipeHomeIPhone])
            showFeedback("🏠 Dispatched iPhone Home Gesture")

        case "iphoneControlCenter":
            AntigravityDesktopAgent.shared.executeScript([.openiPhone, .swipeControlCenterIPhone])
            showFeedback("⚙️ Dispatched Control Center Gesture")

        case "iphoneNotifications":
            AntigravityDesktopAgent.shared.executeScript([.openiPhone, .swipeNotificationCenterIPhone])
            showFeedback("🔔 Dispatched Notifications Gesture")

        case "iphoneSnapshot":
            iPhoneMirrorManager.shared.saveToPolaroid()
            showFeedback("📸 Captured iPhone Snapshot to Polaroid")

        case "setBrainModel":
            GenieAutonomousLoopEngine.shared.setLocalModel(value)
            showFeedback("🧠 Switched Local Brain to: \(value)")

        case "openReviewQueue":
            let agentId = GenieAgentHomeDirectoryEngine.shared.activeAgent?.id ?? "genie-primary"
            let reviewPath = "\(GenieAgentHomeDirectoryEngine.agentsRootDirectory)/\(agentId)/review"
            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: reviewPath)
            showFeedback("📬 Opened Agent Review Queue in Finder")

        case "syncCloud":
            Task {
                if let agent = GenieAgentHomeDirectoryEngine.shared.activeAgent {
                    _ = await GenieAgentCloudSavingEngine.shared.syncAgentToCloud(agent: agent)
                    await MainActor.run {
                        showFeedback("☁️ Synced to Cloud Vault")
                    }
                }
            }

        case "inspectAdmin":
            let user = NSUserName()
            let info = GenieAdminAccessGovernor.shared.inspectUserAccess(username: user)
            showFeedback("🛡️ Admin: \(info.isAdmin ? "ACTIVE (Admin)" : "STANDARD") | UID: \(info.uid)")

        case "switchStation":
            if value.contains("zenith") || value.contains("chat") {
                DesktopWindowManager.shared.switchToStation(.chat)
                showFeedback("⚡ Navigated to Dialogue Studio (Zenith)")
            } else if value.contains("nadir") || value.contains("app") {
                DesktopWindowManager.shared.switchToStation(.applications)
                showFeedback("⚡ Navigated to Applications Atelier (Nadir)")
            } else {
                DesktopWindowManager.shared.switchToStation(.desktop)
                showFeedback("⚡ Navigated to Desktop Canvas (Horizon)")
            }

        case "openFinder":
            let desktopPath = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(value)
            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: desktopPath.path)
            showFeedback("📁 Opened Finder: \(value)")

        case "runCommand":
            showFeedback("⚡ Executed: \(title)")
            NotificationCenter.default.post(
                name: NSNotification.Name("NexusExecuteTerminalCommand"),
                object: value
            )

        case "promptAgent":
            showFeedback("✨ Dispatched prompt to Genie Agent")
            NotificationCenter.default.post(
                name: NSNotification.Name("NexusSubmitChatPrompt"),
                object: value
            )

        case "inspectImage":
            let src = payload["src"] as? String ?? value
            showFeedback("🖼️ Connected Image Click: \(title) -> Swift Bridge")
            NotificationCenter.default.post(
                name: NSNotification.Name("NexusInspectImageSolution"),
                object: src
            )

        default:
            showFeedback("🖱️ Swift received click on: \(title)")
        }
    }

    private func showFeedback(_ text: String) {
        statusFeedback = text
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if statusFeedback == text {
                statusFeedback = nil
            }
        }
    }
}

// MARK: - AppKit WKWebView Transparent Host
private struct TransparentWebKitView: NSViewRepresentable {
    let htmlContent: String
    let reloadToken: UUID
    let onSwiftAction: ([String: Any]) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onSwiftAction: onSwiftAction)
    }

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let userController = WKUserContentController()
        userController.add(context.coordinator, name: "genieBridge")
        config.userContentController = userController

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        if #available(macOS 12.0, *) {
            webView.underPageBackgroundColor = .clear
        }
        webView.navigationDelegate = context.coordinator
        webView.loadHTMLString(htmlContent, baseURL: nil)
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        if context.coordinator.lastReloadToken != reloadToken {
            context.coordinator.lastReloadToken = reloadToken
            nsView.loadHTMLString(htmlContent, baseURL: nil)
        }
    }

    class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
        let onSwiftAction: ([String: Any]) -> Void
        var lastReloadToken: UUID?

        init(onSwiftAction: @escaping ([String: Any]) -> Void) {
            self.onSwiftAction = onSwiftAction
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "genieBridge", let body = message.body as? [String: Any] {
                DispatchQueue.main.async { [weak self] in
                    self?.onSwiftAction(body)
                }
            }
        }
    }
}
