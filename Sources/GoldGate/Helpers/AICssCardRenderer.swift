import AppKit
import Foundation
import WebKit

// MARK: - AI Answer Visual Wrapper & Fast Image Generator
// Takes generated answers and formats them into beautiful, modern glassmorphic CSS cards
// and rapidly snapshots them into retina PNG images.

public final class AICssCardRenderer {
    public static let shared = AICssCardRenderer()

    /// Supported Apple 2028 and Classic Themes
    public enum CardTheme: String, CaseIterable, Identifiable, Sendable {
        case apple2028LiquidWater = "Apple 2028 Living Water 💧"
        case apple2028OledPillow  = "Apple 2028 OLED Pillow ⏱️"
        case apple2028QuantumGlass = "Apple 2028 Quantum Glass ✨"
        case apple2028FrostedLight = "Apple 2028 Frosted Light ☀️"
        case classicDarkGlass     = "Classic Dark Glass 🌌"
        case mysticalAurora       = "Mystical Aurora 🌌"
        case contemplativeOcean   = "Contemplative Ocean 🌊"
        case energeticAmber       = "Energetic Amber ⚡"
        case playfulEmerald       = "Playful Emerald 🌿"

        public var id: String { rawValue }

        public var themeAttr: String {
            switch self {
            case .apple2028LiquidWater: return "apple-2028-liquid"
            case .apple2028OledPillow:  return "apple-2028-oled-pillow"
            case .apple2028QuantumGlass: return "apple-2028-quantum"
            case .apple2028FrostedLight: return "apple-2028-frosted-light"
            case .classicDarkGlass:     return "classic-dark"
            case .mysticalAurora:       return "mystical-aurora"
            case .contemplativeOcean:   return "contemplative-ocean"
            case .energeticAmber:       return "energetic-amber"
            case .playfulEmerald:       return "playful-emerald"
            }
        }

        public var cssVariables: String {
            switch self {
            case .apple2028LiquidWater:
                return """
                    --bg: #050a14;
                    --bg-gradient: radial-gradient(circle at 50% -10%, #0d2847 0%, #061122 45%, #02060d 100%);
                    --card-bg: rgba(10, 20, 38, 0.76);
                    --border: rgba(0, 240, 255, 0.35);
                    --border-glow: rgba(0, 240, 255, 0.22);
                    --accent-cyan: #00f0ff;
                    --accent-purple: #0080ff;
                    --badge-bg: rgba(0, 240, 255, 0.16);
                    --badge-color: #38bdf8;
                    --text-main: #f0f9ff;
                    --text-muted: #93c5fd;
                    --code-bg: rgba(3, 7, 18, 0.90);
                    --glass-blur: blur(32px) saturate(210%);
                    --card-shadow: 0 30px 70px rgba(0, 0, 0, 0.7), 0 0 45px rgba(0, 240, 255, 0.16);
                """
            case .apple2028OledPillow:
                return """
                    --bg: #000000;
                    --bg-gradient: radial-gradient(circle at 50% 0%, #0e1017 0%, #050608 55%, #000000 100%);
                    --card-bg: rgba(12, 14, 20, 0.90);
                    --border: rgba(255, 255, 255, 0.18);
                    --border-glow: rgba(244, 195, 117, 0.20);
                    --accent-cyan: #f4c375;
                    --accent-purple: #38bdf8;
                    --badge-bg: rgba(255, 255, 255, 0.08);
                    --badge-color: #f4c375;
                    --text-main: #ffffff;
                    --text-muted: #94a3b8;
                    --code-bg: #040507;
                    --glass-blur: blur(36px) saturate(180%);
                    --card-shadow: 0 28px 65px rgba(0, 0, 0, 0.9), inset 0 1px 0 rgba(255, 255, 255, 0.22);
                """
            case .apple2028QuantumGlass:
                return """
                    --bg: #030712;
                    --bg-gradient: radial-gradient(circle at 50% -10%, #1e1b4b 0%, #09090b 65%, #020204 100%);
                    --card-bg: rgba(15, 17, 28, 0.82);
                    --border: rgba(192, 132, 252, 0.35);
                    --border-glow: rgba(192, 132, 252, 0.20);
                    --accent-cyan: #38bdf8;
                    --accent-purple: #c084fc;
                    --badge-bg: rgba(192, 132, 252, 0.16);
                    --badge-color: #e9d5ff;
                    --text-main: #f8fafc;
                    --text-muted: #cbd5e1;
                    --code-bg: #02040a;
                    --glass-blur: blur(30px) saturate(200%);
                    --card-shadow: 0 24px 64px rgba(0, 0, 0, 0.8), 0 0 45px rgba(192, 132, 252, 0.18);
                """
            case .apple2028FrostedLight:
                return """
                    --bg: #f8fafc;
                    --bg-gradient: radial-gradient(circle at 50% 0%, #ffffff 0%, #f1f5f9 60%, #e2e8f0 100%);
                    --card-bg: rgba(255, 255, 255, 0.86);
                    --border: rgba(0, 0, 0, 0.10);
                    --border-glow: rgba(2, 132, 199, 0.12);
                    --accent-cyan: #0284c7;
                    --accent-purple: #f97316;
                    --badge-bg: rgba(249, 115, 22, 0.12);
                    --badge-color: #ea580c;
                    --text-main: #0f172a;
                    --text-muted: #64748b;
                    --code-bg: #f1f5f9;
                    --glass-blur: blur(28px) saturate(160%);
                    --card-shadow: 0 20px 45px rgba(15, 23, 42, 0.10), 0 0 1px rgba(0, 0, 0, 0.1);
                """
            case .classicDarkGlass:
                return """
                    --bg: #090d16;
                    --bg-gradient: radial-gradient(circle at 50% 0%, #172554 0%, #090d16 65%, #020617 100%);
                    --card-bg: rgba(18, 24, 38, 0.78);
                    --border: rgba(56, 189, 248, 0.28);
                    --border-glow: rgba(56, 189, 248, 0.15);
                    --accent-cyan: #38bdf8;
                    --accent-purple: #c084fc;
                    --badge-bg: rgba(56, 189, 248, 0.14);
                    --badge-color: #7dd3fc;
                    --text-main: #f8fafc;
                    --text-muted: #94a3b8;
                    --code-bg: #030712;
                    --glass-blur: blur(28px) saturate(180%);
                    --card-shadow: 0 24px 64px rgba(0, 0, 0, 0.7), 0 0 40px var(--border-glow);
                """
            case .mysticalAurora:
                return """
                    --bg: #070314;
                    --bg-gradient: radial-gradient(circle at 50% 0%, #2e1065 0%, #0d0722 55%, #03010a 100%);
                    --card-bg: rgba(22, 13, 46, 0.82);
                    --border: rgba(168, 85, 247, 0.35);
                    --border-glow: rgba(192, 132, 252, 0.25);
                    --accent-cyan: #38bdf8;
                    --accent-purple: #a855f7;
                    --badge-bg: rgba(168, 85, 247, 0.16);
                    --badge-color: #e9d5ff;
                    --text-main: #faf5ff;
                    --text-muted: #d8b4fe;
                    --code-bg: #090317;
                    --glass-blur: blur(32px) saturate(200%);
                    --card-shadow: 0 26px 68px rgba(0, 0, 0, 0.85), 0 0 50px rgba(168, 85, 247, 0.20);
                """
            case .contemplativeOcean:
                return """
                    --bg: #020814;
                    --bg-gradient: radial-gradient(circle at 50% -10%, #0c4a6e 0%, #041d33 50%, #010811 100%);
                    --card-bg: rgba(8, 28, 48, 0.80);
                    --border: rgba(56, 189, 248, 0.35);
                    --border-glow: rgba(14, 165, 233, 0.22);
                    --accent-cyan: #0284c7;
                    --accent-purple: #38bdf8;
                    --badge-bg: rgba(56, 189, 248, 0.16);
                    --badge-color: #bae6fd;
                    --text-main: #f0f9ff;
                    --text-muted: #7dd3fc;
                    --code-bg: #020d1a;
                    --glass-blur: blur(30px) saturate(210%);
                    --card-shadow: 0 26px 65px rgba(0, 0, 0, 0.8), 0 0 45px rgba(14, 165, 233, 0.18);
                """
            case .energeticAmber:
                return """
                    --bg: #140902;
                    --bg-gradient: radial-gradient(circle at 50% 0%, #78350f 0%, #2e1005 55%, #0a0301 100%);
                    --card-bg: rgba(38, 18, 8, 0.85);
                    --border: rgba(245, 158, 11, 0.38);
                    --border-glow: rgba(251, 191, 36, 0.25);
                    --accent-cyan: #fbbf24;
                    --accent-purple: #f97316;
                    --badge-bg: rgba(245, 158, 11, 0.18);
                    --badge-color: #fde68a;
                    --text-main: #fffbeb;
                    --text-muted: #fcd34d;
                    --code-bg: #1a0802;
                    --glass-blur: blur(30px) saturate(190%);
                    --card-shadow: 0 28px 68px rgba(0, 0, 0, 0.85), 0 0 45px rgba(245, 158, 11, 0.22);
                """
            case .playfulEmerald:
                return """
                    --bg: #02140a;
                    --bg-gradient: radial-gradient(circle at 50% 0%, #064e3b 0%, #032415 55%, #010a05 100%);
                    --card-bg: rgba(6, 36, 22, 0.82);
                    --border: rgba(52, 211, 153, 0.35);
                    --border-glow: rgba(16, 185, 129, 0.22);
                    --accent-cyan: #34d399;
                    --accent-purple: #10b981;
                    --badge-bg: rgba(52, 211, 153, 0.16);
                    --badge-color: #a7f3d0;
                    --text-main: #ecfdf5;
                    --text-muted: #6ee7b7;
                    --code-bg: #011409;
                    --glass-blur: blur(32px) saturate(200%);
                    --card-shadow: 0 26px 65px rgba(0, 0, 0, 0.8), 0 0 45px rgba(16, 185, 129, 0.20);
                """
            }
        }
    }

    private init() {}

    /// Wraps any AI answer / markdown / code into a standalone, beautiful HTML/CSS card
    public func wrapAnswerInCSS(
        content: String,
        title: String? = nil,
        model: String = "Genie AI",
        theme: CardTheme = .apple2028LiquidWater
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
        <html lang="en" data-theme="\(theme.themeAttr)">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>\(displayTitle)</title>
            <link rel="stylesheet" href="assets/css/genie-apple-2028-themes.css">
            <style>
                \(GenieWebAssetResolver.embeddedThemeCSS)

                :root {
                    \(theme.cssVariables)
                }

                * { box-sizing: border-box; margin: 0; padding: 0; }

                body {
                    background: var(--bg);
                    background-image: var(--bg-gradient);
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
                    backdrop-filter: var(--glass-blur);
                    -webkit-backdrop-filter: var(--glass-blur);
                    border-radius: 22px;
                    border: 1px solid var(--border);
                    box-shadow: var(--card-shadow);
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
                    background: var(--badge-bg);
                    border: 1px solid var(--border);
                    border-radius: 9999px;
                    font-size: 11px;
                    font-weight: 700;
                    color: var(--badge-color);
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
        model: String = "Genie AI",
        theme: CardTheme = .apple2028LiquidWater
    ) -> NSImage {
        let cardW: CGFloat = 680
        let padding: CGFloat = 32

        let firstLine = content.components(separatedBy: .newlines).first(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) ?? "AI Answer"
        let displayTitle = title ?? (firstLine.replacingOccurrences(of: "#", with: "").trimmingCharacters(in: .whitespacesAndNewlines))

        // Pre-measure text
        let titleFont = NSFont.systemFont(ofSize: 20, weight: .bold)
        let bodyFont = NSFont.systemFont(ofSize: 13.5, weight: .regular)
        let metaFont = NSFont.systemFont(ofSize: 10.5, weight: .medium)

        let isLight = (theme == .apple2028FrostedLight)

        let bodyPara = NSMutableParagraphStyle()
        bodyPara.lineSpacing = 4.5

        let bodyTextColor = isLight
            ? NSColor(calibratedRed: 0.12, green: 0.15, blue: 0.20, alpha: 1.0)
            : NSColor(calibratedRed: 0.92, green: 0.94, blue: 0.98, alpha: 1.0)

        let bodyAttrs: [NSAttributedString.Key: Any] = [
            .font: bodyFont,
            .foregroundColor: bodyTextColor,
            .paragraphStyle: bodyPara
        ]

        let titleTextColor = isLight ? NSColor(calibratedRed: 0.06, green: 0.08, blue: 0.12, alpha: 1.0) : NSColor.white

        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: titleFont,
            .foregroundColor: titleTextColor
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

        // 1. Background Gradient by Theme
        let cardPath = CGPath(roundedRect: rect.insetBy(dx: 2, dy: 2), cornerWidth: 22, cornerHeight: 22, transform: nil)
        ctx.saveGState()
        ctx.addPath(cardPath)
        ctx.clip()

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bgColors: CFArray
        let glowColors: CFArray
        let borderColor: CGColor
        let badgeBgColor: CGColor
        let badgeStrokeColor: CGColor
        let badgeTextColor: NSColor

        switch theme {
        case .apple2028LiquidWater:
            bgColors = [
                CGColor(red: 0.04, green: 0.08, blue: 0.18, alpha: 1.0),
                CGColor(red: 0.01, green: 0.03, blue: 0.07, alpha: 1.0)
            ] as CFArray
            glowColors = [
                CGColor(red: 0.0, green: 0.94, blue: 1.0, alpha: 0.22),
                CGColor(red: 0.0, green: 0.50, blue: 1.0, alpha: 0.08),
                CGColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
            ] as CFArray
            borderColor = CGColor(red: 0.0, green: 0.94, blue: 1.0, alpha: 0.50)
            badgeBgColor = CGColor(red: 0.0, green: 0.94, blue: 1.0, alpha: 0.18)
            badgeStrokeColor = CGColor(red: 0.0, green: 0.94, blue: 1.0, alpha: 0.45)
            badgeTextColor = NSColor(calibratedRed: 0.22, green: 0.85, blue: 1.0, alpha: 1.0)

        case .apple2028OledPillow:
            bgColors = [
                CGColor(red: 0.04, green: 0.04, blue: 0.06, alpha: 1.0),
                CGColor(red: 0.00, green: 0.00, blue: 0.00, alpha: 1.0)
            ] as CFArray
            glowColors = [
                CGColor(red: 0.96, green: 0.76, blue: 0.46, alpha: 0.16),
                CGColor(red: 0.22, green: 0.74, blue: 0.97, alpha: 0.06),
                CGColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
            ] as CFArray
            borderColor = CGColor(red: 0.96, green: 0.76, blue: 0.46, alpha: 0.45)
            badgeBgColor = CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.08)
            badgeStrokeColor = CGColor(red: 0.96, green: 0.76, blue: 0.46, alpha: 0.40)
            badgeTextColor = NSColor(calibratedRed: 0.96, green: 0.76, blue: 0.46, alpha: 1.0)

        case .apple2028QuantumGlass:
            bgColors = [
                CGColor(red: 0.08, green: 0.05, blue: 0.16, alpha: 1.0),
                CGColor(red: 0.01, green: 0.01, blue: 0.04, alpha: 1.0)
            ] as CFArray
            glowColors = [
                CGColor(red: 0.75, green: 0.52, blue: 0.99, alpha: 0.20),
                CGColor(red: 0.22, green: 0.74, blue: 0.97, alpha: 0.08),
                CGColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
            ] as CFArray
            borderColor = CGColor(red: 0.75, green: 0.52, blue: 0.99, alpha: 0.48)
            badgeBgColor = CGColor(red: 0.75, green: 0.52, blue: 0.99, alpha: 0.18)
            badgeStrokeColor = CGColor(red: 0.75, green: 0.52, blue: 0.99, alpha: 0.45)
            badgeTextColor = NSColor(calibratedRed: 0.85, green: 0.65, blue: 1.0, alpha: 1.0)

        case .apple2028FrostedLight:
            bgColors = [
                CGColor(red: 0.99, green: 0.99, blue: 1.00, alpha: 1.0),
                CGColor(red: 0.93, green: 0.95, blue: 0.98, alpha: 1.0)
            ] as CFArray
            glowColors = [
                CGColor(red: 0.01, green: 0.52, blue: 0.78, alpha: 0.10),
                CGColor(red: 0.98, green: 0.45, blue: 0.09, alpha: 0.05),
                CGColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.0)
            ] as CFArray
            borderColor = CGColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.12)
            badgeBgColor = CGColor(red: 0.98, green: 0.45, blue: 0.09, alpha: 0.12)
            badgeStrokeColor = CGColor(red: 0.98, green: 0.45, blue: 0.09, alpha: 0.35)
            badgeTextColor = NSColor(calibratedRed: 0.92, green: 0.35, blue: 0.05, alpha: 1.0)

        case .classicDarkGlass:
            bgColors = [
                CGColor(red: 0.05, green: 0.08, blue: 0.15, alpha: 1.0),
                CGColor(red: 0.02, green: 0.04, blue: 0.08, alpha: 1.0)
            ] as CFArray
            glowColors = [
                CGColor(red: 0.0, green: 0.75, blue: 1.0, alpha: 0.16),
                CGColor(red: 0.60, green: 0.20, blue: 1.0, alpha: 0.06),
                CGColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
            ] as CFArray
            borderColor = CGColor(red: 0.22, green: 0.74, blue: 0.97, alpha: 0.45)
            badgeBgColor = CGColor(red: 0.0, green: 0.65, blue: 1.0, alpha: 0.18)
            badgeStrokeColor = CGColor(red: 0.0, green: 0.65, blue: 1.0, alpha: 0.40)
            badgeTextColor = NSColor(calibratedRed: 0.45, green: 0.85, blue: 1.0, alpha: 1.0)

        case .mysticalAurora:
            bgColors = [
                CGColor(red: 0.05, green: 0.03, blue: 0.10, alpha: 1.0),
                CGColor(red: 0.01, green: 0.01, blue: 0.04, alpha: 1.0)
            ] as CFArray
            glowColors = [
                CGColor(red: 0.65, green: 0.40, blue: 1.0, alpha: 0.20),
                CGColor(red: 0.20, green: 0.85, blue: 0.60, alpha: 0.08),
                CGColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
            ] as CFArray
            borderColor = CGColor(red: 0.65, green: 0.40, blue: 1.0, alpha: 0.45)
            badgeBgColor = CGColor(red: 0.65, green: 0.40, blue: 1.0, alpha: 0.18)
            badgeStrokeColor = CGColor(red: 0.65, green: 0.40, blue: 1.0, alpha: 0.40)
            badgeTextColor = NSColor(calibratedRed: 0.75, green: 0.55, blue: 1.0, alpha: 1.0)

        case .contemplativeOcean:
            bgColors = [
                CGColor(red: 0.02, green: 0.06, blue: 0.14, alpha: 1.0),
                CGColor(red: 0.01, green: 0.02, blue: 0.06, alpha: 1.0)
            ] as CFArray
            glowColors = [
                CGColor(red: 0.20, green: 0.65, blue: 0.98, alpha: 0.20),
                CGColor(red: 0.45, green: 0.35, blue: 0.85, alpha: 0.08),
                CGColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
            ] as CFArray
            borderColor = CGColor(red: 0.20, green: 0.65, blue: 0.98, alpha: 0.45)
            badgeBgColor = CGColor(red: 0.20, green: 0.65, blue: 0.98, alpha: 0.18)
            badgeStrokeColor = CGColor(red: 0.20, green: 0.65, blue: 0.98, alpha: 0.40)
            badgeTextColor = NSColor(calibratedRed: 0.40, green: 0.75, blue: 1.0, alpha: 1.0)

        case .energeticAmber:
            bgColors = [
                CGColor(red: 0.09, green: 0.05, blue: 0.02, alpha: 1.0),
                CGColor(red: 0.03, green: 0.01, blue: 0.00, alpha: 1.0)
            ] as CFArray
            glowColors = [
                CGColor(red: 1.0, green: 0.72, blue: 0.20, alpha: 0.22),
                CGColor(red: 0.95, green: 0.35, blue: 0.20, alpha: 0.08),
                CGColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
            ] as CFArray
            borderColor = CGColor(red: 1.0, green: 0.72, blue: 0.20, alpha: 0.45)
            badgeBgColor = CGColor(red: 1.0, green: 0.72, blue: 0.20, alpha: 0.18)
            badgeStrokeColor = CGColor(red: 1.0, green: 0.72, blue: 0.20, alpha: 0.40)
            badgeTextColor = NSColor(calibratedRed: 1.0, green: 0.80, blue: 0.30, alpha: 1.0)

        case .playfulEmerald:
            bgColors = [
                CGColor(red: 0.02, green: 0.08, blue: 0.05, alpha: 1.0),
                CGColor(red: 0.01, green: 0.03, blue: 0.02, alpha: 1.0)
            ] as CFArray
            glowColors = [
                CGColor(red: 0.20, green: 0.85, blue: 0.55, alpha: 0.20),
                CGColor(red: 0.10, green: 0.75, blue: 0.95, alpha: 0.08),
                CGColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
            ] as CFArray
            borderColor = CGColor(red: 0.20, green: 0.85, blue: 0.55, alpha: 0.45)
            badgeBgColor = CGColor(red: 0.20, green: 0.85, blue: 0.55, alpha: 0.18)
            badgeStrokeColor = CGColor(red: 0.20, green: 0.85, blue: 0.55, alpha: 0.40)
            badgeTextColor = NSColor(calibratedRed: 0.35, green: 0.92, blue: 0.65, alpha: 1.0)
        }

        if let grad = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: [0.0, 1.0]) {
            ctx.drawLinearGradient(grad, start: CGPoint(x: rect.midX, y: rect.maxY), end: CGPoint(x: rect.midX, y: rect.minY), options: [])
        }

        if let radial = CGGradient(colorsSpace: colorSpace, colors: glowColors, locations: [0.0, 0.45, 1.0]) {
            ctx.drawRadialGradient(radial, startCenter: CGPoint(x: rect.midX, y: rect.maxY), startRadius: 10, endCenter: CGPoint(x: rect.midX, y: rect.maxY), endRadius: 360, options: [])
        }
        ctx.restoreGState()

        // 2. Glowing Glass Border
        ctx.saveGState()
        ctx.addPath(cardPath)
        ctx.setStrokeColor(borderColor)
        ctx.setLineWidth(1.2)
        ctx.strokePath()
        ctx.restoreGState()

        // 3. Header Badge & Model Name
        let badgeRect = CGRect(x: padding, y: cardH - padding - 24, width: 140, height: 24)
        let badgePath = CGPath(roundedRect: badgeRect, cornerWidth: 12, cornerHeight: 12, transform: nil)
        ctx.saveGState()
        ctx.addPath(badgePath)
        ctx.setFillColor(badgeBgColor)
        ctx.fillPath()
        ctx.addPath(badgePath)
        ctx.setStrokeColor(badgeStrokeColor)
        ctx.setLineWidth(0.8)
        ctx.strokePath()
        ctx.restoreGState()

        let badgeStr = NSAttributedString(
            string: "✨ \(model)",
            attributes: [
                .font: metaFont,
                .foregroundColor: badgeTextColor
            ]
        )
        badgeStr.draw(at: CGPoint(x: padding + 10, y: cardH - padding - 19))

        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        let metaTextColor = isLight ? NSColor.black.withAlphaComponent(0.45) : NSColor.white.withAlphaComponent(0.45)
        let timeStr = NSAttributedString(
            string: df.string(from: Date()),
            attributes: [
                .font: metaFont,
                .foregroundColor: metaTextColor
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
            string: "🧞‍♂️ Genie AI Visual Card • \(theme.rawValue)",
            attributes: [
                .font: metaFont,
                .foregroundColor: metaTextColor
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
        model: String = "Genie AI",
        theme: CardTheme = .apple2028LiquidWater
    ) -> URL? {
        let image = renderCardToImage(content: content, title: title, model: model, theme: theme)
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
        model: String = "Genie AI",
        theme: CardTheme = .apple2028LiquidWater
    ) -> URL? {
        let html = wrapAnswerInCSS(content: content, title: title, model: model, theme: theme)
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
