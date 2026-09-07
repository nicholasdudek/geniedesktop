import AppKit
import Foundation
import WebKit

// MARK: - AI Answer Visual Wrapper & Fast Image Generator
// Takes generated answers and formats them into beautiful, modern glassmorphic CSS cards
// and rapidly snapshots them into retina PNG images.

public final class AICssCardRenderer {
    public static let shared = AICssCardRenderer()

    private init() {}

    /// Wraps any AI answer / markdown / code into a standalone, beautiful HTML/CSS card
    public func wrapAnswerInCSS(
        content: String,
        title: String? = nil,
        model: String = "Genie AI"
    ) -> String {
        let firstLine = content.components(separatedBy: .newlines).first(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) ?? "AI Answer"
        let cleanTitle = title ?? firstLine.replacingOccurrences(of: "#", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        let displayTitle = cleanTitle.count > 50 ? String(cleanTitle.prefix(47)) + "..." : cleanTitle

        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        let timeStr = dateFormatter.string(from: Date())

        let formattedBody = formatMarkdownToHTML(content)

        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>\(displayTitle)</title>
            <style>
                :root {
                    --bg: #090d16;
                    --card-bg: rgba(18, 24, 38, 0.78);
                    --border: rgba(56, 189, 248, 0.28);
                    --border-glow: rgba(56, 189, 248, 0.15);
                    --accent-cyan: #38bdf8;
                    --accent-purple: #c084fc;
                    --text-main: #f8fafc;
                    --text-muted: #94a3b8;
                    --code-bg: #030712;
                }

                * { box-sizing: border-box; margin: 0; padding: 0; }

                body {
                    background: radial-gradient(circle at 50% 0%, #172554 0%, #090d16 65%, #020617 100%);
                    color: var(--text-main);
                    font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", Inter, system-ui, sans-serif;
                    min-height: 100vh;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    padding: 32px 20px;
                    -webkit-font-smoothing: antialiased;
                }

                .card {
                    width: 100%;
                    max-width: 780px;
                    background: var(--card-bg);
                    backdrop-filter: blur(28px) saturate(180%);
                    -webkit-backdrop-filter: blur(28px) saturate(180%);
                    border-radius: 20px;
                    border: 1px solid var(--border);
                    box-shadow: 0 24px 64px rgba(0, 0, 0, 0.7), 0 0 40px var(--border-glow);
                    overflow: hidden;
                    animation: cardFadeIn 0.35s ease-out;
                }

                @keyframes cardFadeIn {
                    from { opacity: 0; transform: translateY(12px) scale(0.98); }
                    to { opacity: 1; transform: translateY(0) scale(1); }
                }

                .card-header {
                    display: flex;
                    align-items: center;
                    justify-content: space-between;
                    padding: 18px 24px;
                    background: rgba(255, 255, 255, 0.03);
                    border-bottom: 1px solid rgba(255, 255, 255, 0.08);
                }

                .badge {
                    display: inline-flex;
                    align-items: center;
                    gap: 6px;
                    padding: 5px 12px;
                    background: rgba(56, 189, 248, 0.14);
                    border: 1px solid rgba(56, 189, 248, 0.35);
                    border-radius: 9999px;
                    font-size: 11px;
                    font-weight: 700;
                    color: #7dd3fc;
                    letter-spacing: 0.3px;
                }

                .meta {
                    font-size: 11px;
                    color: var(--text-muted);
                    font-weight: 500;
                }

                .card-body {
                    padding: 28px 28px 24px 28px;
                    line-height: 1.68;
                    font-size: 14.5px;
                }

                h1, h2, h3, h4 {
                    color: #fff;
                    font-weight: 700;
                    margin: 16px 0 10px 0;
                    letter-spacing: -0.3px;
                }

                h1 {
                    font-size: 22px;
                    background: linear-gradient(135deg, #ffffff 0%, #38bdf8 50%, #c084fc 100%);
                    -webkit-background-clip: text;
                    -webkit-text-fill-color: transparent;
                }

                h2 { font-size: 18px; color: #38bdf8; }
                h3 { font-size: 15px; color: #a5b4fc; }

                p { margin-bottom: 14px; color: #e2e8f0; }

                pre {
                    background: var(--code-bg);
                    border: 1px solid rgba(255, 255, 255, 0.10);
                    border-radius: 12px;
                    padding: 16px;
                    overflow-x: auto;
                    font-family: "SF Mono", Menlo, Monaco, "Courier New", monospace;
                    font-size: 12.5px;
                    line-height: 1.55;
                    color: #38bdf8;
                    margin: 16px 0;
                    box-shadow: inset 0 2px 8px rgba(0,0,0,0.5);
                }

                code {
                    font-family: "SF Mono", Menlo, Monaco, monospace;
                    background: rgba(56, 189, 248, 0.12);
                    color: #38bdf8;
                    padding: 2px 6px;
                    border-radius: 5px;
                    font-size: 12.5px;
                }

                pre code {
                    background: none;
                    padding: 0;
                    border-radius: 0;
                }

                ul, ol {
                    margin: 10px 0 14px 22px;
                    color: #e2e8f0;
                }

                li { margin-bottom: 6px; }

                blockquote {
                    border-left: 3px solid #38bdf8;
                    padding: 8px 16px;
                    margin: 14px 0;
                    background: rgba(56, 189, 248, 0.05);
                    border-radius: 0 8px 8px 0;
                    color: #cbd5e1;
                    font-style: italic;
                }

                .card-footer {
                    display: flex;
                    align-items: center;
                    justify-content: space-between;
                    padding: 14px 24px;
                    background: rgba(0, 0, 0, 0.35);
                    border-top: 1px solid rgba(255, 255, 255, 0.06);
                    font-size: 11.5px;
                    color: var(--text-muted);
                }

                .watermark {
                    display: flex;
                    align-items: center;
                    gap: 6px;
                    font-weight: 600;
                    color: #94a3b8;
                }
            </style>
        </head>
        <body>
            <div class="card">
                <div class="card-header">
                    <div class="badge">
                        <span>✨</span>
                        <span>\(model)</span>
                    </div>
                    <div class="meta">\(timeStr)</div>
                </div>
                <div class="card-body">
                    \(formattedBody)
                </div>
                <div class="card-footer">
                    <div class="watermark">
                        <span>🧞‍♂️</span>
                        <span>Generated with Genie AI</span>
                    </div>
                    <div>High-Precision Output</div>
                </div>
            </div>
        </body>
        </html>
        """
    }

    /// Fast HTML converter for markdown snippets
    public func formatMarkdownToHTML(_ md: String) -> String {
        var html = md

        // Protect code blocks
        var codeBlocks: [String] = []
        let pattern = "```([\\s\\S]*?)```"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let nsString = html as NSString
            let matches = regex.matches(in: html, options: [], range: NSRange(location: 0, length: nsString.length))
            for match in matches.reversed() {
                let codeBlockContent = nsString.substring(with: match.range)
                let placeholder = "__CODE_BLOCK_\(codeBlocks.count)__"
                codeBlocks.append(codeBlockContent)
                html = (html as NSString).replacingCharacters(in: match.range, with: placeholder)
            }
        }

        // Headers
        html = html.replacingOccurrences(of: "\n### (.*?)\n", with: "\n<h3>$1</h3>\n", options: .regularExpression)
        html = html.replacingOccurrences(of: "\n## (.*?)\n", with: "\n<h2>$1</h2>\n", options: .regularExpression)
        html = html.replacingOccurrences(of: "\n# (.*?)\n", with: "\n<h1>$1</h1>\n", options: .regularExpression)

        // Bold and italic
        html = html.replacingOccurrences(of: "\\*\\*(.*?)\\*\\*", with: "<strong>$1</strong>", options: .regularExpression)
        html = html.replacingOccurrences(of: "\\*(.*?)\\*", with: "<em>$1</em>", options: .regularExpression)

        // Inline code
        html = html.replacingOccurrences(of: "`([^`]+)`", with: "<code>$1</code>", options: .regularExpression)

        // Paragraphs
        let paragraphs = html.components(separatedBy: "\n\n")
        html = paragraphs.map { p in
            let trimmed = p.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.hasPrefix("<h") || trimmed.hasPrefix("__CODE_BLOCK_") || trimmed.hasPrefix("<ul>") || trimmed.hasPrefix("<ol>") {
                return trimmed
            }
            return "<p>\(trimmed.replacingOccurrences(of: "\n", with: "<br>"))</p>"
        }.joined(separator: "\n")

        // Restore code blocks with pre/code tags
        for (index, block) in codeBlocks.enumerated() {
            let placeholder = "__CODE_BLOCK_\(index)__"
            var cleanCode = block.trimmingCharacters(in: CharacterSet(charactersIn: "`"))
            // Remove leading language tag e.g. swift\n, python\n
            if let firstNewline = cleanCode.firstIndex(of: "\n") {
                let firstLine = String(cleanCode[..<firstNewline]).trimmingCharacters(in: .whitespacesAndNewlines)
                if !firstLine.contains(" ") && firstLine.count < 15 {
                    cleanCode = String(cleanCode[cleanCode.index(after: firstNewline)...])
                }
            }
            let escaped = cleanCode
                .replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")
            let wrappedBlock = "<pre><code>\(escaped)</code></pre>"
            html = html.replacingOccurrences(of: placeholder, with: wrappedBlock)
        }

        return html
    }

    /// Generates high-resolution retina NSImage from AI Answer in under 20ms using native AppKit graphics
    public func renderCardToImage(
        content: String,
        title: String? = nil,
        model: String = "Genie AI"
    ) -> NSImage {
        let cardW: CGFloat = 680
        let padding: CGFloat = 32

        let firstLine = content.components(separatedBy: .newlines).first(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) ?? "AI Answer"
        let displayTitle = title ?? (firstLine.replacingOccurrences(of: "#", with: "").trimmingCharacters(in: .whitespacesAndNewlines))

        // Pre-measure text
        let titleFont = NSFont.systemFont(ofSize: 20, weight: .bold)
        let bodyFont = NSFont.systemFont(ofSize: 13.5, weight: .regular)
        let metaFont = NSFont.systemFont(ofSize: 10.5, weight: .medium)

        let bodyPara = NSMutableParagraphStyle()
        bodyPara.lineSpacing = 4.5

        let bodyAttrs: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: NSColor(calibratedRed: 0.92, green: 0.94, blue: 0.98, alpha: 1.0),
            .paragraphStyle: bodyPara
        ]

        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: NSColor.white
        ]

        let titleStr = NSAttributedString(string: displayTitle, attributes: titleAttrs)
        let bodyStr = NSAttributedString(string: content, attributes: bodyAttrs)

        let maxTextW = cardW - (padding * 2)
        let titleBounds = titleStr.boundingRect(with: NSSize(width: maxTextW, height: 120), options: [.usesLineFragmentOrigin, .usesFontLeading])
        let bodyBounds = bodyStr.boundingRect(with: NSSize(width: maxTextW, height: 2000), options: [.usesLineFragmentOrigin, .usesFontLeading])

        let headerH: CGFloat = 48
        let footerH: CGFloat = 36
        let totalContentH = titleBounds.height + 16 + bodyBounds.height
        let cardH: CGFloat = max(240, headerH + totalContentH + footerH + (padding * 2))

        let image = NSImage(size: NSSize(width: cardW, height: cardH))
        image.lockFocus()

        guard let ctx = NSGraphicsContext.current?.cgContext else {
            image.unlockFocus()
            return image
        }

        let rect = CGRect(x: 0, y: 0, width: cardW, height: cardH)

        // 1. Dark Glass Background
        let cardPath = CGPath(roundedRect: rect.insetBy(dx: 2, dy: 2), cornerWidth: 20, cornerHeight: 20, transform: nil)
        ctx.saveGState()
        ctx.addPath(cardPath)
        ctx.clip()

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bgColors = [
            CGColor(red: 0.05, green: 0.08, blue: 0.15, alpha: 1.0),
            CGColor(red: 0.02, green: 0.04, blue: 0.08, alpha: 1.0)
        ] as CFArray
        if let grad = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: [0.0, 1.0]) {
            ctx.drawLinearGradient(grad, start: CGPoint(x: rect.midX, y: rect.maxY), end: CGPoint(x: rect.midX, y: rect.minY), options: [])
        }

        // Ambient cyan top highlight
        let glowColors = [
            CGColor(red: 0.0, green: 0.75, blue: 1.0, alpha: 0.16),
            CGColor(red: 0.60, green: 0.20, blue: 1.0, alpha: 0.06),
            CGColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
        ] as CFArray
        if let radial = CGGradient(colorsSpace: colorSpace, colors: glowColors, locations: [0.0, 0.45, 1.0]) {
            ctx.drawRadialGradient(radial, startCenter: CGPoint(x: rect.midX, y: rect.maxY), startRadius: 10, endCenter: CGPoint(x: rect.midX, y: rect.maxY), endRadius: 360, options: [])
        }
        ctx.restoreGState()

        // 2. Glowing Glass Border
        ctx.saveGState()
        ctx.addPath(cardPath)
        ctx.setStrokeColor(CGColor(red: 0.22, green: 0.74, blue: 0.97, alpha: 0.45))
        ctx.setLineWidth(1.2)
        ctx.strokePath()
        ctx.restoreGState()

        // 3. Header Badge & Model Name
        let badgeRect = CGRect(x: padding, y: cardH - padding - 24, width: 140, height: 24)
        let badgePath = CGPath(roundedRect: badgeRect, cornerWidth: 12, cornerHeight: 12, transform: nil)
        ctx.saveGState()
        ctx.addPath(badgePath)
        ctx.setFillColor(CGColor(red: 0.0, green: 0.65, blue: 1.0, alpha: 0.18))
        ctx.fillPath()
        ctx.addPath(badgePath)
        ctx.setStrokeColor(CGColor(red: 0.0, green: 0.65, blue: 1.0, alpha: 0.40))
        ctx.setLineWidth(0.8)
        ctx.strokePath()
        ctx.restoreGState()

        let badgeStr = NSAttributedString(
            string: "✨ \(model)",
            attributes: [
                .font: metaFont,
                .foregroundColor: NSColor(calibratedRed: 0.45, green: 0.85, blue: 1.0, alpha: 1.0)
            ]
        )
        badgeStr.draw(at: CGPoint(x: padding + 10, y: cardH - padding - 19))

        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        let timeStr = NSAttributedString(
            string: df.string(from: Date()),
            attributes: [
                .font: metaFont,
                .foregroundColor: NSColor.white.withAlphaComponent(0.45)
            ]
        )
        timeStr.draw(at: CGPoint(x: cardW - padding - timeStr.size().width, y: cardH - padding - 19))

        // 4. Draw Title
        let titleY = cardH - padding - headerH - titleBounds.height
        titleStr.draw(in: CGRect(x: padding, y: titleY, width: maxTextW, height: titleBounds.height + 4))

        // 5. Draw Body
        let bodyY = titleY - 14 - bodyBounds.height
        bodyStr.draw(in: CGRect(x: padding, y: bodyY, width: maxTextW, height: bodyBounds.height + 4))

        // 6. Footer Watermark
        let footerStr = NSAttributedString(
            string: "🧞‍♂️ Genie AI Visual Card",
            attributes: [
                .font: metaFont,
                .foregroundColor: NSColor.white.withAlphaComponent(0.40)
            ]
        )
        footerStr.draw(at: CGPoint(x: padding, y: padding - 12))

        image.unlockFocus()
        return image
    }

    /// Rapidly saves the rendered CSS image card to Desktop and copies to Clipboard
    @discardableResult
    public func saveCardImageToDesktop(
        content: String,
        title: String? = nil,
        model: String = "Genie AI"
    ) -> URL? {
        let image = renderCardToImage(content: content, title: title, model: model)
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let pngData = rep.representation(using: .png, properties: [:]) else {
            return nil
        }

        // Copy image to clipboard for instant pasting
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.writeObjects([image])

        let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Desktop")

        let firstLine = content.components(separatedBy: .newlines).first(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) ?? "Answer"
        let rawTitle = title ?? firstLine.replacingOccurrences(of: "#", with: "")
        let safeTitle = rawTitle.replacingOccurrences(of: "[^a-zA-Z0-9_-]", with: "_", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "_"))
        let prefix = safeTitle.isEmpty ? "Answer" : String(safeTitle.prefix(32))

        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd_HHmmss"
        let stamp = df.string(from: Date())

        let url = desktop.appendingPathComponent("AI_Card - \(prefix) - \(stamp).png")
        do {
            try pngData.write(to: url, options: .atomic)
            HapticFeedback.heavy()
            return url
        } catch {
            print("AICssCardRenderer error: \(error)")
            return nil
        }
    }

    /// Exports the beautiful CSS/HTML page directly to Desktop
    @discardableResult
    public func exportHTMLCardToDesktop(
        content: String,
        title: String? = nil,
        model: String = "Genie AI"
    ) -> URL? {
        let html = wrapAnswerInCSS(content: content, title: title, model: model)
        let desktop = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Desktop")

        let firstLine = content.components(separatedBy: .newlines).first(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) ?? "Answer"
        let rawTitle = title ?? firstLine.replacingOccurrences(of: "#", with: "")
        let safeTitle = rawTitle.replacingOccurrences(of: "[^a-zA-Z0-9_-]", with: "_", options: .regularExpression)
            .trimmingCharacters(in: CharacterSet(charactersIn: "_"))
        let prefix = safeTitle.isEmpty ? "Answer" : String(safeTitle.prefix(32))

        let df = DateFormatter()
        df.dateFormat = "yyyy-MM-dd_HHmmss"
        let stamp = df.string(from: Date())

        let url = desktop.appendingPathComponent("AI_Card - \(prefix) - \(stamp).html")
        do {
            try html.write(to: url, atomically: true, encoding: .utf8)
            HapticFeedback.selection()
            return url
        } catch {
            print("AICssCardRenderer HTML export error: \(error)")
            return nil
        }
    }
}
