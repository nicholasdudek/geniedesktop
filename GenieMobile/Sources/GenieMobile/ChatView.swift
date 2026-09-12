import SwiftUI
import GenieAgentCore
#if canImport(WebKit)
import WebKit
#endif

struct ChatView: View {
    @ObservedObject private var session = AgentSessionStore.shared
    @ObservedObject private var workspace = WorkspaceStore.shared
    @ObservedObject private var settings = GenieSettings.shared
    @State private var draft = ""

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Active Model & Workspace Telemetry Bar
                HStack(spacing: 6) {
                    Circle()
                        .fill(session.isRunning ? settings.accent.color : Color.green)
                        .frame(width: 8, height: 8)
                    Text(settings.model)
                        .font(.caption2.bold().monospaced())
                    Spacer()
                    HStack(spacing: 4) {
                        Image(systemName: "folder.fill")
                            .font(.caption2)
                        Text(workspace.workspaceName.isEmpty ? "No Workspace" : workspace.workspaceName)
                            .font(.caption2.monospaced())
                    }
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.secondary.opacity(0.06))
                Divider()

                if workspace.workspaceURL == nil {
                    Text("Pick a workspace folder in the Files tab first — Genie needs somewhere to read and write.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .padding(8)
                        .frame(maxWidth: .infinity)
                        .background(Color.secondary.opacity(0.08))
                }
                if let errorMessage = session.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.red.opacity(0.08))
                }

                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 10) {
                            ForEach(Array((session.run?.messages ?? []).enumerated()), id: \.offset) { index, message in
                                if message.role == "user" || message.role == "assistant", !message.content.isEmpty {
                                    bubble(role: message.role, text: message.content)
                                        .id(index)
                                }
                            }
                            if session.isRunning {
                                HStack(spacing: 6) {
                                    ProgressView().controlSize(.small)
                                    Text("Genie is working…").font(.footnote).foregroundStyle(.secondary)
                                }
                                .padding(.horizontal, 12)
                            }
                            Color.clear.frame(height: 1).id("bottom")
                        }
                        .padding(12)
                    }
                    .onChange(of: session.run?.messages.count) { _, _ in
                        withAnimation { proxy.scrollTo("bottom", anchor: .bottom) }
                    }
                }

                HStack(spacing: 8) {
                    TextField("Ask Genie…", text: $draft, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(1...4)
                    Button(action: send) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(settings.accent.color)
                    }
                    .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || session.isRunning)
                }
                .padding(10)
            }
            .navigationTitle("Genie")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("New Chat") { session.startNewChat() }
                }
            }
            .sheet(item: $session.pendingApproval) { call in
                ApprovalSheet(call: call)
            }
        }
    }

    private func extractHTML(from text: String) -> String? {
        if text.contains("```html") {
            let parts = text.components(separatedBy: "```html")
            if parts.count > 1 {
                let codePart = parts[1].components(separatedBy: "```")[0]
                return codePart.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        } else if text.contains("<!DOCTYPE html") || text.contains("<html") {
            return text
        }
        return nil
    }

    private func bubble(role: String, text: String) -> some View {
        let isUser = role == "user"
        let html = !isUser ? extractHTML(from: text) : nil

        return VStack(alignment: isUser ? .trailing : .leading, spacing: 6) {
            HStack {
                if isUser { Spacer(minLength: 40) }
                Text(text)
                    .padding(10)
                    .background(isUser ? settings.accent.color.opacity(0.85) : Color.secondary.opacity(0.12))
                    .foregroundStyle(isUser ? .black : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                if !isUser { Spacer(minLength: 40) }
            }

            if let htmlContent = html {
                MobileInstantWebsitePreviewCard(htmlContent: htmlContent)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private func send() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        draft = ""
        if settings.enableHaptics {
            MobileHaptics.light()
        }
        session.send(text)
    }
}

// MARK: - 📱 iPhone Instant Website Preview Card
struct MobileInstantWebsitePreviewCard: View {
    let htmlContent: String
    @State private var isCopied = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 6) {
                Image(systemName: "safari.fill")
                    .font(.caption2)
                    .foregroundStyle(.cyan)
                Text("Live Interactive Website")
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
                Spacer()
                Button(action: {
                    #if os(iOS)
                    UIPasteboard.general.string = htmlContent
                    #elseif os(macOS)
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(htmlContent, forType: .string)
                    #endif
                    isCopied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { isCopied = false }
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: isCopied ? "checkmark" : "doc.on.doc")
                        Text(isCopied ? "Copied" : "Copy")
                    }
                    .font(.caption2.bold())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.secondary.opacity(0.15)))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.secondary.opacity(0.08))

            MobileWebKitHost(htmlContent: htmlContent)
                .frame(minHeight: 240, maxHeight: 340)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
        .padding(.vertical, 2)
    }
}

// MARK: - Platform WebKit Host
#if os(iOS) && canImport(WebKit)
struct MobileWebKitHost: UIViewRepresentable {
    let htmlContent: String

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = true
        webView.loadHTMLString(htmlContent, baseURL: nil)
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.loadHTMLString(htmlContent, baseURL: nil)
    }
}
#elseif os(macOS) && canImport(WebKit)
struct MobileWebKitHost: NSViewRepresentable {
    let htmlContent: String

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.loadHTMLString(htmlContent, baseURL: nil)
        return webView
    }

    func updateNSView(_ nsView: WKWebView, context: Context) {
        nsView.loadHTMLString(htmlContent, baseURL: nil)
    }
}
#else
struct MobileWebKitHost: View {
    let htmlContent: String
    var body: some View {
        ScrollView {
            Text(htmlContent)
                .font(.caption.monospaced())
                .padding(8)
        }
    }
}
#endif

private struct ApprovalSheet: View {
    let call: AgentToolCall
    @ObservedObject private var session = AgentSessionStore.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Genie wants to run:").font(.headline)
            Text(call.name).font(.system(.body, design: .monospaced)).bold()
            ScrollView {
                Text(call.arguments)
                    .font(.system(.footnote, design: .monospaced))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 160)
            .padding(8)
            .background(Color.secondary.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            HStack {
                Button("Deny", role: .destructive) { session.resolveApproval(false) }
                    .buttonStyle(.bordered)
                Spacer()
                Button("Approve") { session.resolveApproval(true) }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(20)
        .presentationDetents([.medium])
    }
}

extension AgentToolCall: @retroactive Identifiable {}
