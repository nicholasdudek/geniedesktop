// MARK: - StreamingHTMLTagBalancer.swift
// Golden Gate Engineering • © 2026 Nicholas M. Dudek
//
// Real-Time Streaming HTML & SVG End-Tag Balancer & Frame Buffer.
// Synthesizes and holds closing tags on our end during token streaming so
// WebKit / Safari renders incomplete tokens live at 60/120 FPS without
// dropping partial elements, and retains the last valid frame buffer to
// guarantee the preview never flickers or goes blank.

import Foundation

public final class StreamingHTMLTagBalancer: Sendable {
    public static let shared = StreamingHTMLTagBalancer()

    // Void / self-closing HTML5 elements that do not require closing tags
    private static let voidElements: Set<String> = [
        "area", "base", "br", "col", "embed", "hr", "img", "input",
        "link", "meta", "param", "source", "track", "wbr", "!doctype"
    ]

    private init() {}

    /// Balances an in-progress streaming HTML/SVG snippet by automatically holding
    /// and appending all missing closing tags in reverse (LIFO) order.
    public static func balance(_ partialHtml: String) -> String {
        let trimmed = partialHtml.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }

        var tagStack: [String] = []
        var i = trimmed.startIndex
        let end = trimmed.endIndex

        while i < end {
            if trimmed[i] == "<" {
                // Check for HTML comments <!-- ... -->
                if trimmed[i...].hasPrefix("<!--") {
                    if let commentEnd = trimmed.range(of: "-->", range: i..<end) {
                        i = commentEnd.upperBound
                        continue
                    } else {
                        // Unclosed comment at end of stream: close it so page can render
                        return trimmed + " -->"
                    }
                }

                // Check for closing tag </tag>
                if trimmed[i...].hasPrefix("</") {
                    let afterSlash = trimmed.index(i, offsetBy: 2)
                    if let closeBracket = trimmed.range(of: ">", range: afterSlash..<end) {
                        let tagContent = String(trimmed[afterSlash..<closeBracket.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                        let tagName = tagContent.components(separatedBy: CharacterSet.whitespacesAndNewlines).first ?? ""
                        if let lastIdx = tagStack.lastIndex(of: tagName) {
                            tagStack.removeSubrange(lastIdx..<tagStack.count)
                        }
                        i = closeBracket.upperBound
                        continue
                    } else {
                        // Truncated closing tag e.g. "</di"
                        return String(trimmed[..<i])
                    }
                }

                // Open tag <tag ...>
                let nextIdx = trimmed.index(after: i)
                if let closeBracket = trimmed.range(of: ">", range: nextIdx..<end) {
                    let tagContent = String(trimmed[nextIdx..<closeBracket.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                    let isSelfClosing = tagContent.hasSuffix("/")
                    let cleanedContent = isSelfClosing ? String(tagContent.dropLast()).trimmingCharacters(in: .whitespaces) : tagContent
                    let tagName = (cleanedContent.components(separatedBy: CharacterSet.whitespacesAndNewlines).first ?? "").lowercased()

                    if !tagName.isEmpty && !isSelfClosing && !voidElements.contains(tagName) && !tagName.hasPrefix("!") {
                        tagStack.append(tagName)
                    }
                    i = closeBracket.upperBound
                    continue
                } else {
                    // Open bracket without closing bracket e.g. "<div class=\"car"
                    // Complete the bracket and then close tags
                    let truncatedTag = String(trimmed[nextIdx...]).trimmingCharacters(in: .whitespaces)
                    let tagName = (truncatedTag.components(separatedBy: CharacterSet.whitespacesAndNewlines).first ?? "").lowercased()
                    var safeBase = String(trimmed[..<i])
                    if !tagName.isEmpty && !voidElements.contains(tagName) {
                        safeBase += ">\n"
                        tagStack.append(tagName)
                    }
                    return closeTags(on: safeBase, stack: tagStack)
                }
            } else {
                i = trimmed.index(after: i)
            }
        }

        return closeTags(on: trimmed, stack: tagStack)
    }

    private static func closeTags(on html: String, stack: [String]) -> String {
        guard !stack.isEmpty else { return html }

        var result = html
        // Synthesize closing tags in strict LIFO order
        for tag in stack.reversed() {
            if tag == "style" {
                result += "\n</style>"
            } else if tag == "script" {
                result += "\n</script>"
            } else if tag == "svg" {
                result += "\n</svg>"
            } else {
                result += "</\(tag)>\n"
            }
        }
        return result
    }
}

// MARK: - 🎞️ Live Preview Frame Retainer
/// Retains the last valid HTML/SVG frame so that during token generation pauses,
/// network stalls, or stream resets, the webview NEVER flashes or loses the last frame.
public final class LivePreviewFrameRetainer: @unchecked Sendable {
    public static let shared = LivePreviewFrameRetainer()

    private let lock = NSLock()
    private var _lastValidFrame: String = ""
    private var _lastValidTitle: String = "AI Creation"

    private init() {}

    public func update(html: String, title: String? = nil) -> String {
        lock.lock()
        defer { lock.unlock() }

        let balanced = StreamingHTMLTagBalancer.balance(html)
        if !balanced.isEmpty {
            _lastValidFrame = balanced
            if let t = title, !t.isEmpty {
                _lastValidTitle = t
            }
        }
        return _lastValidFrame.isEmpty ? balanced : _lastValidFrame
    }

    public func currentFrame() -> String {
        lock.lock()
        defer { lock.unlock() }
        return _lastValidFrame
    }

    public func currentTitle() -> String {
        lock.lock()
        defer { lock.unlock() }
        return _lastValidTitle
    }

    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        _lastValidFrame = ""
        _lastValidTitle = "AI Creation"
    }
}
