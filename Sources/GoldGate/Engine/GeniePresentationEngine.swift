import AppKit
import Foundation
import WebKit
import PDFKit
import SwiftUI

// MARK: - Presentation Slide Model
public struct PresentationSlide: Identifiable, Equatable {
    public var id = UUID()
    public var title: String
    public var content: String
    public var index: Int
    public var total: Int

    public init(title: String, content: String, index: Int, total: Int) {
        self.title = title
        self.content = content
        self.index = index
        self.total = total
    }
}

// MARK: - Slide Presentation Deck Model
public struct SlideDeckPresentation: Identifiable, Equatable {
    public var id = UUID()
    public var title: String
    public var slides: [PresentationSlide]
    public var htmlPath: String?
    public var pdfPath: String?
    public var createdAt: Date = Date()

    public init(title: String, slides: [PresentationSlide], htmlPath: String? = nil, pdfPath: String? = nil) {
        self.title = title
        self.slides = slides
        self.htmlPath = htmlPath
        self.pdfPath = pdfPath
    }
}

// MARK: - Genie Presentation & Document Engine
public final class GeniePresentationEngine {
    public static let shared = GeniePresentationEngine()

    private init() {}

    // MARK: - 1. Slide Deck Compilation & Export
    /// Parses markdown with `---` or `<slide>` separators into structured slides and generates a standalone 16:9 HTML presentation
    public func compileSlideDeck(rawContent: String, title: String? = nil, destinationFolder: URL? = nil) -> SlideDeckPresentation {
        let lines = rawContent.components(separatedBy: .newlines)
        var slideChunks: [String] = []
        var currentChunk: [String] = []

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed == "---" || trimmed.hasPrefix("<slide>") || trimmed.hasPrefix("</slide>") {
                let chunkStr = currentChunk.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
                if !chunkStr.isEmpty {
                    slideChunks.append(chunkStr)
                }
                currentChunk.removeAll()
            } else {
                currentChunk.append(line)
            }
        }
        let finalChunk = currentChunk.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
        if !finalChunk.isEmpty {
            slideChunks.append(finalChunk)
        }

        if slideChunks.isEmpty {
            slideChunks = [rawContent]
        }

        let total = slideChunks.count
        var parsedSlides: [PresentationSlide] = []

        for (i, chunk) in slideChunks.enumerated() {
            let slideLines = chunk.components(separatedBy: .newlines)
            let slideTitle = slideLines.first(where: { $0.hasPrefix("#") })?
                .replacingOccurrences(of: "#", with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
                ?? "Slide \(i + 1)"
            parsedSlides.append(PresentationSlide(title: slideTitle, content: chunk, index: i + 1, total: total))
        }

        let deckTitle = title ?? parsedSlides.first?.title ?? "Genie Presentation"
        let safeName = sanitizeFilename(deckTitle)

        // Compile to standalone 16:9 Glassmorphic HTML Deck
        let htmlDeck = generateGlassSlideDeckHTML(title: deckTitle, slides: parsedSlides)

        // Save HTML Presentation into active folder
        let folder = destinationFolder ?? GenieStandardDirectories.presentationsURL
        let htmlURL = folder.appendingPathComponent("\(safeName).html")
        try? htmlDeck.write(to: htmlURL, atomically: true, encoding: .utf8)

        var presentation = SlideDeckPresentation(
            title: deckTitle,
            slides: parsedSlides,
            htmlPath: htmlURL.path
        )

        // Generate matching PDF
        let pdfURL = folder.appendingPathComponent("\(safeName).pdf")
        if let pdfData = generateSimplePDF(title: deckTitle, slides: parsedSlides) {
            try? pdfData.write(to: pdfURL)
            presentation.pdfPath = pdfURL.path
        }

        return presentation
    }

    // MARK: - 2. Executive PDF Document Compilation
    public func compilePDFDocument(content: String, title: String, destinationFolder: URL? = nil) -> URL? {
        let safeName = sanitizeFilename(title)
        let folder = destinationFolder ?? GenieStandardDirectories.documentsURL
        let pdfURL = folder.appendingPathComponent("\(safeName).pdf")

        if let pdfData = generateStyledReportPDF(title: title, markdown: content) {
            try? pdfData.write(to: pdfURL)
            return pdfURL
        }
        return nil
    }

    // MARK: - 3. Interactive Chart.js Visualizer
    public func compileInteractiveChartHTML(type: String, dataJSON: String, title: String) -> String {
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <title>\(title)</title>
            <script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                body {
                    background: radial-gradient(circle at top, #0f172a 0%, #020617 100%);
                    color: #f8fafc;
                    font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", sans-serif;
                    display: flex;
                    flex-direction: column;
                    align-items: center;
                    justify-content: center;
                    min-height: 100vh;
                    padding: 24px;
                }
                .chart-container {
                    position: relative;
                    width: 100%;
                    max-width: 820px;
                    background: rgba(15, 23, 42, 0.75);
                    backdrop-filter: blur(24px);
                    -webkit-backdrop-filter: blur(24px);
                    border: 1px solid rgba(56, 189, 248, 0.25);
                    border-radius: 20px;
                    padding: 24px;
                    box-shadow: 0 20px 50px rgba(0,0,0,0.6), 0 0 30px rgba(56, 189, 248, 0.15);
                }
                .header {
                    display: flex;
                    align-items: center;
                    justify-content: space-between;
                    margin-bottom: 20px;
                }
                .title {
                    font-size: 16px;
                    font-weight: 700;
                    color: #38bdf8;
                    display: flex;
                    align-items: center;
                    gap: 8px;
                }
                .badge {
                    font-size: 11px;
                    padding: 3px 10px;
                    border-radius: 999px;
                    background: rgba(56, 189, 248, 0.15);
                    border: 1px solid rgba(56, 189, 248, 0.4);
                    color: #7dd3fc;
                    text-transform: uppercase;
                    letter-spacing: 0.5px;
                }
            </style>
        </head>
        <body>
            <div class="chart-container">
                <div class="header">
                    <div class="title">📊 \(title)</div>
                    <div class="badge">\(type.uppercased())</div>
                </div>
                <canvas id="genieChart"></canvas>
            </div>
            <script>
                const ctx = document.getElementById('genieChart').getContext('2d');
                try {
                    let chartConfig = \(dataJSON);
                    if (!chartConfig.type) chartConfig.type = '\(type)';
                    if (!chartConfig.options) chartConfig.options = {};
                    chartConfig.options.responsive = true;
                    chartConfig.options.plugins = chartConfig.options.plugins || {};
                    chartConfig.options.plugins.legend = {
                        labels: { color: '#e2e8f0', font: { family: '-apple-system' } }
                    };
                    new Chart(ctx, chartConfig);
                } catch(e) {
                    document.body.innerHTML += '<p style="color:#ef4444;margin-top:16px;">Chart Render Error: ' + e.message + '</p>';
                }
            </script>
        </body>
        </html>
        """
    }

    // MARK: - 4. Interactive Mermaid.js Diagram Viewer
    public func compileMermaidHTML(code: String, title: String) -> String {
        let cleanCode = code.replacingOccurrences(of: "```mermaid", with: "").replacingOccurrences(of: "```", with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <title>\(title)</title>
            <script type="module">
                import mermaid from 'https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.esm.min.mjs';
                mermaid.initialize({
                    startOnLoad: true,
                    theme: 'dark',
                    themeVariables: {
                        darkMode: true,
                        background: '#090d16',
                        primaryColor: '#0284c7',
                        primaryTextColor: '#f8fafc',
                        primaryBorderColor: '#38bdf8',
                        lineColor: '#38bdf8',
                        secondaryColor: '#9333ea',
                        tertiaryColor: '#1e293b'
                    }
                });
            </script>
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                body {
                    background: radial-gradient(circle at top, #090d16 0%, #020617 100%);
                    color: #f8fafc;
                    font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", sans-serif;
                    display: flex;
                    flex-direction: column;
                    align-items: center;
                    justify-content: center;
                    min-height: 100vh;
                    padding: 24px;
                    overflow: auto;
                }
                .diagram-card {
                    background: rgba(15, 23, 42, 0.78);
                    backdrop-filter: blur(28px);
                    -webkit-backdrop-filter: blur(28px);
                    border: 1px solid rgba(56, 189, 248, 0.28);
                    border-radius: 20px;
                    padding: 28px;
                    box-shadow: 0 24px 64px rgba(0,0,0,0.7), 0 0 40px rgba(56, 189, 248, 0.15);
                    max-width: 95vw;
                    overflow: auto;
                }
                .header {
                    font-size: 15px;
                    font-weight: 700;
                    color: #38bdf8;
                    margin-bottom: 20px;
                    display: flex;
                    align-items: center;
                    gap: 8px;
                }
            </style>
        </head>
        <body>
            <div class="diagram-card">
                <div class="header">📐 \(title)</div>
                <pre class="mermaid">
        \(cleanCode)
                </pre>
            </div>
        </body>
        </html>
        """
    }

    // MARK: - HTML5 16:9 Glassmorphic Slide Deck Template
    private func generateGlassSlideDeckHTML(title: String, slides: [PresentationSlide]) -> String {
        var slidesHTML = ""
        for (idx, slide) in slides.enumerated() {
            let formattedContent = AICssCardRenderer.shared.formatMarkdownToHTML(slide.content)
            let activeClass = (idx == 0) ? "active" : ""
            slidesHTML += """
            <div class="slide \(activeClass)" data-index="\(idx)">
                <div class="slide-proscenium">
                    <div class="slide-badge">SLIDE \(idx + 1) OF \(slides.count)</div>
                    <div class="slide-title">\(slide.title)</div>
                </div>
                <div class="slide-body">
                    \(formattedContent)
                </div>
            </div>
            """
        }

        return """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>\(title) — Genie Presentation</title>
            <style>
                :root {
                    --bg-dark: #070a12;
                    --slide-bg: rgba(15, 23, 42, 0.85);
                    --border-glass: rgba(56, 189, 248, 0.25);
                    --border-highlight: rgba(255, 255, 255, 0.15);
                    --cyan-accent: #38bdf8;
                    --purple-accent: #c084fc;
                    --text-primary: #f8fafc;
                    --text-secondary: #94a3b8;
                }

                * { box-sizing: border-box; margin: 0; padding: 0; }

                body {
                    background: radial-gradient(circle at 50% 10%, #1e1b4b 0%, #090d16 60%, #020617 100%);
                    color: var(--text-primary);
                    font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", Inter, system-ui, sans-serif;
                    height: 100vh;
                    display: flex;
                    flex-direction: column;
                    align-items: center;
                    justify-content: center;
                    overflow: hidden;
                    -webkit-font-smoothing: antialiased;
                }

                /* 16:9 Presentation Stage */
                .stage-container {
                    width: 92vw;
                    max-width: 1200px;
                    aspect-ratio: 16 / 9;
                    background: var(--slide-bg);
                    backdrop-filter: blur(32px) saturate(180%);
                    -webkit-backdrop-filter: blur(32px) saturate(180%);
                    border-radius: 28px;
                    border: 1px solid var(--border-glass);
                    box-shadow: 0 32px 80px rgba(0, 0, 0, 0.8), 0 0 45px rgba(56, 189, 248, 0.15);
                    display: flex;
                    flex-direction: column;
                    position: relative;
                    overflow: hidden;
                }

                .slide {
                    display: none;
                    flex: 1;
                    padding: 48px 64px;
                    flex-direction: column;
                    justify-content: flex-start;
                    animation: slideFadeIn 0.35s cubic-bezier(0.16, 1, 0.3, 1);
                    overflow-y: auto;
                }

                .slide.active {
                    display: flex;
                }

                @keyframes slideFadeIn {
                    from { opacity: 0; transform: scale(0.97) translateY(10px); }
                    to { opacity: 1; transform: scale(1) translateY(0); }
                }

                .slide-proscenium {
                    display: flex;
                    align-items: center;
                    justify-content: space-between;
                    margin-bottom: 28px;
                    border-bottom: 1px solid var(--border-highlight);
                    padding-bottom: 16px;
                }

                .slide-badge {
                    font-size: 11px;
                    font-weight: 700;
                    letter-spacing: 1px;
                    color: var(--cyan-accent);
                    background: rgba(56, 189, 248, 0.12);
                    border: 1px solid rgba(56, 189, 248, 0.35);
                    padding: 5px 14px;
                    border-radius: 9999px;
                }

                .slide-title {
                    font-size: 24px;
                    font-weight: 800;
                    color: #fff;
                    letter-spacing: -0.5px;
                }

                .slide-body {
                    font-size: 20px;
                    line-height: 1.6;
                    color: #e2e8f0;
                }

                .slide-body h1, .slide-body h2 { color: #fff; margin-bottom: 16px; font-size: 28px; }
                .slide-body h3 { color: var(--cyan-accent); margin-bottom: 12px; }
                .slide-body ul { margin-left: 28px; margin-bottom: 16px; }
                .slide-body li { margin-bottom: 12px; }
                .slide-body p { margin-bottom: 14px; }
                .slide-body code { background: rgba(0,0,0,0.5); padding: 3px 8px; border-radius: 6px; color: var(--cyan-accent); font-family: ui-monospace, monospace; }

                /* Bottom Presentation Controls */
                .stage-toolbar {
                    display: flex;
                    align-items: center;
                    justify-content: space-between;
                    padding: 16px 28px;
                    background: rgba(0, 0, 0, 0.35);
                    border-top: 1px solid var(--border-highlight);
                }

                .btn {
                    background: rgba(255, 255, 255, 0.08);
                    border: 1px solid rgba(255, 255, 255, 0.18);
                    color: #fff;
                    padding: 8px 18px;
                    border-radius: 12px;
                    cursor: pointer;
                    font-size: 13px;
                    font-weight: 600;
                    display: inline-flex;
                    align-items: center;
                    gap: 6px;
                    transition: all 0.15s ease;
                }

                .btn:hover {
                    background: rgba(56, 189, 248, 0.25);
                    border-color: var(--cyan-accent);
                }

                .counter {
                    font-size: 13px;
                    color: var(--text-secondary);
                    font-weight: 500;
                }

                @media print {
                    body { background: #fff; color: #000; height: auto; }
                    .stage-container { aspect-ratio: auto; width: 100%; border: none; box-shadow: none; background: #fff; }
                    .slide { display: block !important; page-break-after: always; color: #000; border-bottom: 1px solid #ddd; }
                    .stage-toolbar { display: none; }
                }
            </style>
        </head>
        <body>
            <div class="stage-container">
                \(slidesHTML)
                <div class="stage-toolbar">
                    <button class="btn" onclick="prevSlide()">◀ Previous</button>
                    <div class="counter" id="slideCounter">Slide 1 of \(slides.count)</div>
                    <button class="btn" onclick="nextSlide()">Next ▶</button>
                </div>
            </div>

            <script>
                let current = 0;
                const total = \(slides.count);
                const slides = document.querySelectorAll('.slide');
                const counter = document.getElementById('slideCounter');

                function showSlide(idx) {
                    if (idx < 0 || idx >= total) return;
                    slides[current].classList.remove('active');
                    current = idx;
                    slides[current].classList.add('active');
                    counter.innerText = `Slide ${current + 1} of ${total}`;
                }

                function nextSlide() { showSlide((current + 1) % total); }
                function prevSlide() { showSlide((current - 1 + total) % total); }

                window.addEventListener('keydown', (e) => {
                    if (e.key === 'ArrowRight' || e.key === 'Space') nextSlide();
                    if (e.key === 'ArrowLeft') prevSlide();
                });
            </script>
        </body>
        </html>
        """
    }

    // MARK: - CoreGraphics / PDFKit Vector PDF Generator
    private func generateSimplePDF(title: String, slides: [PresentationSlide]) -> Data? {
        let pdfData = NSMutableData()
        let pageSize = CGRect(x: 0, y: 0, width: 1024, height: 576) // 16:9 Landscape

        UIGraphicsBeginPDFContextToData(pdfData, pageSize)

        for (idx, slide) in slides.enumerated() {
            UIGraphicsBeginPDFPageWithInfo(pageSize, nil)
            guard let context = NSGraphicsContext.current?.cgContext else { continue }

            // Dark background
            context.setFillColor(CGColor(red: 0.05, green: 0.08, blue: 0.15, alpha: 1.0))
            context.fill(pageSize)

            // Header banner
            let titleFont = NSFont.systemFont(ofSize: 28, weight: .bold)
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: titleFont,
                .foregroundColor: NSColor.white
            ]
            let slideTitle = "\(idx + 1). \(slide.title)"
            (slideTitle as NSString).draw(at: CGPoint(x: 60, y: 480), withAttributes: titleAttrs)

            // Body text
            let bodyFont = NSFont.systemFont(ofSize: 18, weight: .regular)
            let bodyAttrs: [NSAttributedString.Key: Any] = [
                .font: bodyFont,
                .foregroundColor: NSColor(red: 0.9, green: 0.92, blue: 0.95, alpha: 1.0)
            ]
            let bodyRect = CGRect(x: 60, y: 80, width: 900, height: 380)
            (slide.content as NSString).draw(in: bodyRect, withAttributes: bodyAttrs)

            // Footer
            let footerAttrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: 12, weight: .medium),
                .foregroundColor: NSColor(red: 0.22, green: 0.74, blue: 0.97, alpha: 1.0)
            ]
            let footer = "Genie Presentation • Slide \(idx + 1) of \(slides.count)"
            (footer as NSString).draw(at: CGPoint(x: 60, y: 40), withAttributes: footerAttrs)
        }

        UIGraphicsEndPDFContext()
        return pdfData as Data
    }

    private func generateStyledReportPDF(title: String, markdown: String) -> Data? {
        let pdfData = NSMutableData()
        let letterSize = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter Portrait

        UIGraphicsBeginPDFContextToData(pdfData, letterSize)
        UIGraphicsBeginPDFPageWithInfo(letterSize, nil)

        guard let context = NSGraphicsContext.current?.cgContext else {
            UIGraphicsEndPDFContext()
            return nil
        }

        // Clean white/subtle ivory paper
        context.setFillColor(CGColor(red: 0.99, green: 0.99, blue: 0.99, alpha: 1.0))
        context.fill(letterSize)

        // Title Header
        let titleAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 24, weight: .heavy),
            .foregroundColor: NSColor(red: 0.05, green: 0.08, blue: 0.15, alpha: 1.0)
        ]
        (title as NSString).draw(at: CGPoint(x: 54, y: 720), withAttributes: titleAttrs)

        let dateStr = DateFormatter.localizedString(from: Date(), dateStyle: .long, timeStyle: .short)
        let subAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 10, weight: .medium),
            .foregroundColor: NSColor.gray
        ]
        ("Generated by Genie AI • \(dateStr)" as NSString).draw(at: CGPoint(x: 54, y: 698), withAttributes: subAttrs)

        // Divider
        context.setStrokeColor(CGColor(red: 0.8, green: 0.85, blue: 0.9, alpha: 1.0))
        context.setLineWidth(1.0)
        context.move(to: CGPoint(x: 54, y: 686))
        context.addLine(to: CGPoint(x: 558, y: 686))
        context.strokePath()

        // Content
        let bodyAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12, weight: .regular),
            .foregroundColor: NSColor(red: 0.15, green: 0.18, blue: 0.22, alpha: 1.0)
        ]
        let contentRect = CGRect(x: 54, y: 60, width: 504, height: 610)
        (markdown as NSString).draw(in: contentRect, withAttributes: bodyAttrs)

        UIGraphicsEndPDFContext()
        return pdfData as Data
    }

    private func sanitizeFilename(_ text: String) -> String {
        let cleaned = text.components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "_")
        return cleaned.isEmpty ? "Presentation" : String(cleaned.prefix(40))
    }

    // Fallback graphics context helpers for macOS PDF generation
    private func UIGraphicsBeginPDFContextToData(_ data: NSMutableData, _ bounds: CGRect) {
        var mediaBox = bounds
        guard let consumer = CGDataConsumer(data: data as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else { return }
        let nsContext = NSGraphicsContext(cgContext: context, flipped: false)
        NSGraphicsContext.current = nsContext
    }

    private func UIGraphicsBeginPDFPageWithInfo(_ bounds: CGRect, _ pageInfo: [CFString: Any]?) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        var mediaBox = bounds
        context.beginPage(mediaBox: &mediaBox)
    }

    private func UIGraphicsEndPDFContext() {
        guard let context = NSGraphicsContext.current?.cgContext else { return }
        context.endPage()
        context.closePDF()
        NSGraphicsContext.current = nil
    }
}
