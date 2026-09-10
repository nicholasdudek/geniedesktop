import SwiftUI
import AppKit

// MARK: - Chat Render Focus
//
// The Files pane doubles as the shared preview surface: whichever rendered item is
// nearest the top of the chat scroll shows there, so scrolling back through the
// conversation walks the previews with it. The chat list and the preview pane live
// in different view trees, so they talk through a notification rather than a binding.

/// A renderable artifact pulled out of one chat message.
public struct ChatRenderArtifact: Equatable, Identifiable {
    public let id: UUID          // the message it came from
    public let title: String
    public let body: String
    public let language: String

    public init(id: UUID, title: String, body: String, language: String) {
        self.id = id
        self.title = title
        self.body = body
        self.language = language
    }
}

public enum ChatRenderExtractor {
    /// Languages worth opening in the preview pane. Prose and shell transcripts are
    /// not previewable, and promoting them would blank the pane on every scroll.
    private static let renderable: Set<String> = [
        "html", "svg", "mermaid", "markdown", "md", "css", "json", "xml"
    ]

    /// First fenced block in `content` that is worth previewing, else nil.
    public static func artifact(in message: ChatMessage) -> ChatRenderArtifact? {
        let content = message.content
        guard content.contains("```") || content.contains("<!DOCTYPE") || content.contains("<svg") else {
            return nil
        }

        // Raw HTML/SVG with no fence — the creation pipeline emits this shape.
        if let range = content.range(of: "<!DOCTYPE html", options: .caseInsensitive)
            ?? content.range(of: "<svg", options: .caseInsensitive) {
            let body = String(content[range.lowerBound...])
            return ChatRenderArtifact(
                id: message.id,
                title: heading(in: body) ?? "Rendered output",
                body: body,
                language: body.lowercased().hasPrefix("<svg") ? "svg" : "html"
            )
        }

        // Fenced blocks: ```lang\n…\n```
        let parts = content.components(separatedBy: "```")
        // parts alternates prose, code, prose, code… so every odd index is a block.
        var index = 1
        while index < parts.count {
            let block = parts[index]
            guard let newline = block.firstIndex(of: "\n") else { index += 2; continue }
            let lang = block[block.startIndex..<newline]
                .trimmingCharacters(in: .whitespaces)
                .lowercased()
            let body = String(block[block.index(after: newline)...])
            if renderable.contains(lang), !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return ChatRenderArtifact(
                    id: message.id,
                    title: heading(in: body) ?? "\(lang.uppercased()) preview",
                    body: body,
                    language: lang
                )
            }
            index += 2
        }
        return nil
    }

    /// A <title>, an <h1>, or a leading markdown heading — whichever the body offers.
    private static func heading(in body: String) -> String? {
        for (open, close) in [("<title>", "</title>"), ("<h1>", "</h1>")] {
            if let a = body.range(of: open, options: .caseInsensitive),
               let b = body.range(of: close, options: .caseInsensitive, range: a.upperBound..<body.endIndex) {
                let t = String(body[a.upperBound..<b.lowerBound])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !t.isEmpty { return t }
            }
        }
        for line in body.split(separator: "\n", maxSplits: 8, omittingEmptySubsequences: true) {
            let t = line.trimmingCharacters(in: .whitespaces)
            if t.hasPrefix("# ") { return String(t.dropFirst(2)) }
        }
        return nil
    }
}

// MARK: - Which render is on screen

public extension Notification.Name {
    /// Posted with a `ChatRenderArtifact` when the focused render changes.
    static let genieChatRenderFocused = Notification.Name("GenieChatRenderFocused")
}

/// Distance of each renderable message from the top of the scroll viewport.
struct ChatRenderFocusKey: PreferenceKey {
    static let defaultValue: [UUID: CGFloat] = [:]
    static func reduce(value: inout [UUID: CGFloat], nextValue: () -> [UUID: CGFloat]) {
        value.merge(nextValue(), uniquingKeysWith: min)
    }
}

public extension View {
    /// Report this row's offset so the nearest render can win focus.
    /// Rows with nothing renderable report nothing and cost a bounds read only.
    func trackChatRenderFocus(message: ChatMessage, space: String) -> some View {
        background {
            if ChatRenderExtractor.artifact(in: message) != nil {
                GeometryReader { geo in
                    Color.clear.preference(
                        key: ChatRenderFocusKey.self,
                        value: [message.id: abs(geo.frame(in: .named(space)).minY)]
                    )
                }
            }
        }
    }

    /// Watch the reported offsets and publish whichever render sits nearest the top.
    func publishFocusedChatRender(space: String, messages: @escaping () -> [ChatMessage]) -> some View {
        coordinateSpace(name: space)
            .onPreferenceChange(ChatRenderFocusKey.self) { offsets in
                guard let winner = offsets.min(by: { $0.value < $1.value })?.key else { return }
                guard let message = messages().first(where: { $0.id == winner }),
                      let artifact = ChatRenderExtractor.artifact(in: message) else { return }
                ChatRenderFocusBroadcaster.shared.publish(artifact)
            }
    }
}

/// Collapses repeat reports — the preference fires continuously while scrolling, and
/// re-posting the same artifact would reload the preview web view on every frame.
final class ChatRenderFocusBroadcaster {
    static let shared = ChatRenderFocusBroadcaster()
    private var lastID: UUID?

    func publish(_ artifact: ChatRenderArtifact) {
        guard artifact.id != lastID else { return }
        lastID = artifact.id
        NotificationCenter.default.post(
            name: .genieChatRenderFocused,
            object: artifact
        )
    }
}
