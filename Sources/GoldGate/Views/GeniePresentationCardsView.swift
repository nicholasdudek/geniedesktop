import AppKit
import SwiftUI
import WebKit
import PDFKit

// MARK: - 1. Inline 16:9 Slide Deck Presenter Card
public struct InlineSlidePresenterCardView: View {
    public let title: String
    public let content: String

    @State private var presentation: SlideDeckPresentation?
    @State private var currentSlideIndex: Int = 0

    public init(title: String, content: String) {
        self.title = title
        self.content = content
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Stage Header
            HStack(spacing: 8) {
                Image(systemName: "play.rectangle.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.cyan)

                Text(title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Spacer()

                if let pres = presentation {
                    Text("Slide \(currentSlideIndex + 1) of \(pres.slides.count)")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(.cyan.opacity(0.85))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2.5)
                        .background(Capsule().fill(Color.cyan.opacity(0.18)))
                }
            }

            // 16:9 Slide Viewport
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.black.opacity(0.65))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.cyan.opacity(0.35), lineWidth: 0.8)
                    )

                if let pres = presentation, !pres.slides.isEmpty {
                    let slide = pres.slides[min(currentSlideIndex, pres.slides.count - 1)]
                    VStack(alignment: .leading, spacing: 8) {
                        Text(slide.title)
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(2)

                        Divider().opacity(0.3)

                        ScrollView(.vertical, showsIndicators: false) {
                            Text(cleanSlideText(slide.content))
                                .font(.system(size: 12, weight: .regular))
                                .foregroundColor(.white.opacity(0.9))
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(14)
                } else {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .frame(height: 180)

            // Presentation Controls
            HStack(spacing: 8) {
                // Prev Slide
                Button(action: {
                    if currentSlideIndex > 0 {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            currentSlideIndex -= 1
                        }
                        HapticFeedback.selection()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                        Text("Prev")
                    }
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(currentSlideIndex > 0 ? .white : .white.opacity(0.3))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.white.opacity(0.10)))
                }
                .buttonStyle(.plain)
                .disabled(currentSlideIndex <= 0)

                // Next Slide
                Button(action: {
                    if let pres = presentation, currentSlideIndex < pres.slides.count - 1 {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            currentSlideIndex += 1
                        }
                        HapticFeedback.selection()
                    }
                }) {
                    HStack(spacing: 4) {
                        Text("Next")
                        Image(systemName: "chevron.right")
                    }
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor((currentSlideIndex < ((presentation?.slides.count ?? 0) - 1)) ? .white : .white.opacity(0.3))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.white.opacity(0.10)))
                }
                .buttonStyle(.plain)
                .disabled(presentation == nil || currentSlideIndex >= ((presentation?.slides.count ?? 0) - 1))

                Spacer()

                // Open 16:9 Presentation in Browser
                if let htmlPath = presentation?.htmlPath {
                    Button(action: {
                        let url = URL(fileURLWithPath: htmlPath)
                        NSWorkspace.shared.open(url)
                        HapticFeedback.selection()
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "arrow.up.right.square")
                            Text("Present Deck ↗")
                        }
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.cyan)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.cyan.opacity(0.18)))
                        .overlay(Capsule().stroke(Color.cyan.opacity(0.4), lineWidth: 0.5))
                    }
                    .buttonStyle(.plain)
                    .help("Open interactive 16:9 presentation in browser 🌐")
                }

                // Open PDF Slide Deck
                if let pdfPath = presentation?.pdfPath {
                    Button(action: {
                        let url = URL(fileURLWithPath: pdfPath)
                        NSWorkspace.shared.open(url)
                        HapticFeedback.selection()
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "doc.text.fill")
                            Text("PDF")
                        }
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.orange.opacity(0.18)))
                        .overlay(Capsule().stroke(Color.orange.opacity(0.4), lineWidth: 0.5))
                    }
                    .buttonStyle(.plain)
                    .help("Open PDF slides in Preview 📄")
                }
            }
        }
        .padding(12)
        .background(
            ZStack {
                VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow, state: .active)
                Color.black.opacity(0.65)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.6)
        )
        .onAppear {
            self.presentation = GeniePresentationEngine.shared.compileSlideDeck(
                rawContent: content,
                title: title
            )
        }
    }

    private func cleanSlideText(_ text: String) -> String {
        return text.components(separatedBy: .newlines)
            .filter { !$0.hasPrefix("#") }
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - 2. Inline Executive PDF Document Card
public struct InlinePDFCardView: View {
    public let title: String
    public let content: String

    @State private var pdfURL: URL?

    public init(title: String, content: String) {
        self.title = title
        self.content = content
    }

    public var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.red.opacity(0.20))
                    .frame(width: 44, height: 44)
                Image(systemName: "doc.richtext.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.red)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Text("Executive PDF Document Compiled")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            if let url = pdfURL {
                Button(action: {
                    NSWorkspace.shared.open(url)
                    HapticFeedback.selection()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right.square")
                        Text("Preview")
                    }
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.red.opacity(0.40)))
                    .overlay(Capsule().stroke(Color.red.opacity(0.65), lineWidth: 0.6))
                }
                .buttonStyle(.plain)
                .help("Open PDF in Apple Preview")

                Button(action: {
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                    HapticFeedback.tick()
                }) {
                    Image(systemName: "folder.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.7))
                        .padding(5)
                        .background(Circle().fill(Color.white.opacity(0.12)))
                }
                .buttonStyle(.plain)
                .help("Reveal PDF in Finder")
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.55))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color.white.opacity(0.15), lineWidth: 0.6))
        )
        .onAppear {
            self.pdfURL = GeniePresentationEngine.shared.compilePDFDocument(content: content, title: title)
        }
    }
}

// MARK: - 3. Inline Interactive Chart Card
public struct InlineChartCardView: View {
    public let type: String
    public let json: String
    public let title: String

    public init(type: String, json: String, title: String) {
        self.type = type
        self.json = json
        self.title = title
    }

    public var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.cyan.opacity(0.20))
                    .frame(width: 44, height: 44)
                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 20))
                    .foregroundColor(.cyan)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("Interactive \(type.uppercased()) Chart")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.cyan.opacity(0.8))
            }

            Spacer()

            Button(action: {
                let html = GeniePresentationEngine.shared.compileInteractiveChartHTML(type: type, dataJSON: json, title: title)
                MiniBrowserManager.shared.activeWebView?.loadHTMLString(html, baseURL: nil)
                NotificationCenter.default.post(name: NSNotification.Name("NexusShowConsolidatedBrowser"), object: nil)
                NotificationCenter.default.post(name: NSNotification.Name("NexusOpenMiniBrowser"), object: nil)
                HapticFeedback.selection()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.forward.app")
                    Text("Interactive View")
                }
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 9)
                .padding(.vertical, 4.5)
                .background(Capsule().fill(Color.cyan.opacity(0.35)))
                .overlay(Capsule().stroke(Color.cyan.opacity(0.55), lineWidth: 0.6))
            }
            .buttonStyle(.plain)
            .help("Open interactive data visualization in browser canvas")
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.55))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color.white.opacity(0.15), lineWidth: 0.6))
        )
    }
}

// MARK: - 4. Inline Mermaid Architecture Diagram Card
public struct InlineMermaidCardView: View {
    public let diagram: String
    public let title: String

    public init(diagram: String, title: String) {
        self.diagram = diagram
        self.title = title
    }

    public var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.purple.opacity(0.20))
                    .frame(width: 44, height: 44)
                Image(systemName: "point.filled.topleft.down.curvedto.point.bottomright.up")
                    .font(.system(size: 18))
                    .foregroundColor(.purple)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("Mermaid System Architecture")
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.purple.opacity(0.85))
            }

            Spacer()

            Button(action: {
                let html = GeniePresentationEngine.shared.compileMermaidHTML(code: diagram, title: title)
                MiniBrowserManager.shared.activeWebView?.loadHTMLString(html, baseURL: nil)
                NotificationCenter.default.post(name: NSNotification.Name("NexusShowConsolidatedBrowser"), object: nil)
                NotificationCenter.default.post(name: NSNotification.Name("NexusOpenMiniBrowser"), object: nil)
                HapticFeedback.selection()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.forward.app")
                    Text("View Diagram")
                }
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 9)
                .padding(.vertical, 4.5)
                .background(Capsule().fill(Color.purple.opacity(0.35)))
                .overlay(Capsule().stroke(Color.purple.opacity(0.55), lineWidth: 0.6))
            }
            .buttonStyle(.plain)
            .help("View and zoom Mermaid architecture diagram in browser canvas")

            Button(action: {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(diagram, forType: .string)
                HapticFeedback.tick()
            }) {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 10.5))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(5)
                    .background(Circle().fill(Color.white.opacity(0.12)))
            }
            .buttonStyle(.plain)
            .help("Copy Mermaid Diagram Code 📋")
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.55))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Color.white.opacity(0.15), lineWidth: 0.6))
        )
    }
}

// MARK: - 5. Interactive Web Search Citation & Link Pill
public struct ExtractedWebLink: Identifiable, Hashable, Sendable {
    public var id: String { urlString.isEmpty ? title : urlString }
    public let title: String
    public let urlString: String
    public var url: URL? { URL(string: urlString) }

    public init(title: String, url: URL?) {
        self.title = title
        self.urlString = url?.absoluteString ?? ""
    }

    public init(title: String, urlString: String) {
        self.title = title
        self.urlString = urlString
    }
}

public struct InlineWebLinkCitationView: View {
    public let link: ExtractedWebLink
    @State private var isHovered: Bool = false

    public init(link: ExtractedWebLink) {
        self.link = link
    }

    public var body: some View {
        Button(action: {
            if let url = link.url {
                HapticFeedback.selection()
                NSWorkspace.shared.open(url)
            }
        }) {
            HStack(spacing: 5) {
                Image(systemName: "safari.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(Color(red: 0.0, green: 0.85, blue: 1.0))

                Text(link.title)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Image(systemName: "arrow.up.forward.app")
                    .font(.system(size: 8.5, weight: .semibold))
                    .foregroundColor(.white.opacity(isHovered ? 0.95 : 0.50))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(isHovered ? Color.cyan.opacity(0.25) : Color.white.opacity(0.08))
                    .overlay(
                        Capsule()
                            .strokeBorder(isHovered ? Color.cyan.opacity(0.65) : Color.white.opacity(0.15), lineWidth: 0.8)
                    )
            )
        }
        .buttonStyle(.plain)
        .onHover { h in
            withAnimation(.spring(response: 0.18, dampingFraction: 0.75)) {
                isHovered = h
            }
        }
        .help("Open \(link.urlString) in browser")
    }
}
