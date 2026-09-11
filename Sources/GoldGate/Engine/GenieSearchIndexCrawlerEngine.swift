import AppKit
import Foundation

// MARK: - 🚀 Genie Resilient Multi-Tier Search Index & Deep Crawler Engine
/// Solves the "Google / Search Engine bot-blocking & CAPTCHA" problem by combining:
/// 1. Unblocked Google News & Syndicate Index (RSS / XML API) for live events, breaking news, articles & sources.
/// 2. OpenSearch & MediaWiki Encyclopedic Index (REST API) for structured knowledge, facts, definitions & deep links.
/// 3. Headless Parallel Deep Crawler (GenieFastWebCrawler) for extracting real page Open Graph images, lead photos, meta descriptions, and clean content.
/// 4. Authentic WebKit Engine (GenieHiddenBrowserEngine) with real macOS Safari headers & zero-cursor DOM inspection for protected indices.

public struct GenieSearchIndexResult: Identifiable, Sendable, Codable {
    public var id: String { url }
    public let title: String
    public let snippet: String
    public let url: String
    public let sourceName: String
    public let publishDate: String?
    public var thumbnailURL: String?
    public var domInteractiveElementsCount: Int
    public var latencyMs: Double

    public init(
        title: String,
        snippet: String,
        url: String,
        sourceName: String,
        publishDate: String? = nil,
        thumbnailURL: String? = nil,
        domInteractiveElementsCount: Int = 0,
        latencyMs: Double = 0
    ) {
        self.title = title
        self.snippet = snippet
        self.url = url
        self.sourceName = sourceName
        self.publishDate = publishDate
        self.thumbnailURL = thumbnailURL
        self.domInteractiveElementsCount = domInteractiveElementsCount
        self.latencyMs = latencyMs
    }
}

public struct GenieSearchIndexResponse: Sendable {
    public let query: String
    public let summary: String
    public let results: [GenieSearchIndexResult]
    public let latencyMs: Double
    public let engineTierUsed: String
}

@MainActor
public final class GenieSearchIndexCrawlerEngine: ObservableObject, @unchecked Sendable {
    public static let shared = GenieSearchIndexCrawlerEngine()

    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 6.0
        config.timeoutIntervalForResource = 12.0
        config.httpAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Safari/605.1.15",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "en-US,en;q=0.9"
        ]
        self.session = URLSession(configuration: config)
    }

    /// Resilient multi-tier search index crawl: tries Tier 1 (Google Syndication), Tier 2 (OpenSearch/Wiki), Tier 3 (Parallel Crawler), and Tier 4 (Hidden WebKit)
    public func search(query: String) async -> GenieSearchIndexResponse {
        let startTime = CFAbsoluteTimeGetCurrent()
        let clean = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else {
            return GenieSearchIndexResponse(
                query: query,
                summary: "Empty search query provided.",
                results: [],
                latencyMs: 0,
                engineTierUsed: "None"
            )
        }

        // Tier 1: Google News & Live Syndication Index (RSS / XML API — zero CAPTCHA, real indexed events)
        let tier1Results = await queryGoogleSyndicationIndex(query: clean)
        if !tier1Results.isEmpty {
            let enriched = await enrichResultsWithDeepCrawler(results: tier1Results)
            let latency = (CFAbsoluteTimeGetCurrent() - startTime) * 1000.0
            let summary = buildSummary(from: enriched, query: clean)
            return GenieSearchIndexResponse(
                query: clean,
                summary: summary,
                results: enriched,
                latencyMs: latency,
                engineTierUsed: "Google Syndication Index"
            )
        }

        // Tier 2: OpenSearch & Wikimedia Knowledge Index
        let tier2Results = await queryOpenSearchIndex(query: clean)
        if !tier2Results.isEmpty {
            let enriched = await enrichResultsWithDeepCrawler(results: tier2Results)
            let latency = (CFAbsoluteTimeGetCurrent() - startTime) * 1000.0
            let summary = buildSummary(from: enriched, query: clean)
            return GenieSearchIndexResponse(
                query: clean,
                summary: summary,
                results: enriched,
                latencyMs: latency,
                engineTierUsed: "OpenSearch Knowledge Index"
            )
        }

        // Tier 3: DuckDuckGo Instant Answer / Abstract Index
        let tier3Results = await queryDuckDuckGoAbstract(query: clean)
        if !tier3Results.isEmpty {
            let latency = (CFAbsoluteTimeGetCurrent() - startTime) * 1000.0
            let summary = buildSummary(from: tier3Results, query: clean)
            return GenieSearchIndexResponse(
                query: clean,
                summary: summary,
                results: tier3Results,
                latencyMs: latency,
                engineTierUsed: "Instant Answer Index"
            )
        }

        // Tier 4: Fallback to Authentic WebKit Engine (GenieHiddenBrowserEngine)
        if let encoded = clean.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let searchURL = URL(string: "https://html.duckduckgo.com/html/?q=\(encoded)") {
            let (pageText, _, title) = await GenieHiddenBrowserEngine.shared.loadAndRead(url: searchURL, maxChars: 2500, timeout: 8)
            let latency = (CFAbsoluteTimeGetCurrent() - startTime) * 1000.0
            let summary = pageText.isEmpty
                ? "Search initiated for \"\(clean)\". Real-time indexes returned no direct text."
                : String(pageText.prefix(800))

            let result = GenieSearchIndexResult(
                title: title.isEmpty ? clean : title,
                snippet: summary,
                url: searchURL.absoluteString,
                sourceName: "WebKit Headless Index",
                publishDate: nil,
                thumbnailURL: nil,
                domInteractiveElementsCount: 12,
                latencyMs: latency
            )

            return GenieSearchIndexResponse(
                query: clean,
                summary: summary,
                results: [result],
                latencyMs: latency,
                engineTierUsed: "WebKit Headless Engine"
            )
        }

        let latency = (CFAbsoluteTimeGetCurrent() - startTime) * 1000.0
        return GenieSearchIndexResponse(
            query: clean,
            summary: "No index results could be retrieved for \"\(clean)\".",
            results: [],
            latencyMs: latency,
            engineTierUsed: "Exhausted"
        )
    }

    // MARK: - Tier 1: Google Syndication & Live Events RSS Index
    private func queryGoogleSyndicationIndex(query: String) async -> [GenieSearchIndexResult] {
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://news.google.com/rss/search?q=\(encoded)&hl=en-US&gl=US&ceid=US:en") else {
            return []
        }

        var req = URLRequest(url: url, timeoutInterval: 5.0)
        req.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")

        guard let (data, resp) = try? await session.data(for: req),
              let http = resp as? HTTPURLResponse, http.statusCode == 200,
              let xml = String(data: data, encoding: .utf8) else {
            return []
        }

        return parseGoogleNewsRSS(xml: xml)
    }

    private func parseGoogleNewsRSS(xml: String) -> [GenieSearchIndexResult] {
        var results: [GenieSearchIndexResult] = []
        let itemPattern = "(?is)<item>(.*?)</item>"
        guard let itemRegex = try? NSRegularExpression(pattern: itemPattern) else { return [] }

        let nsString = xml as NSString
        let matches = itemRegex.matches(in: xml, range: NSRange(location: 0, length: nsString.length))

        for match in matches.prefix(5) {
            let itemContent = nsString.substring(with: match.range(at: 1))
            let title = extractXMLTag(tag: "title", from: itemContent)
            let link = extractXMLTag(tag: "link", from: itemContent)
            let pubDate = extractXMLTag(tag: "pubDate", from: itemContent)
            let source = extractXMLTag(tag: "source", from: itemContent)
            let description = extractXMLTag(tag: "description", from: itemContent)
                .replacingOccurrences(of: "(?is)<[^>]+>", with: " ", options: .regularExpression)
                .replacingOccurrences(of: "&nbsp;", with: " ")
                .replacingOccurrences(of: "&amp;", with: "&")
                .replacingOccurrences(of: "&quot;", with: "\"")
                .replacingOccurrences(of: "&#39;", with: "'")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if !title.isEmpty && !link.isEmpty {
                results.append(
                    GenieSearchIndexResult(
                        title: cleanHTMLTitle(title),
                        snippet: description.isEmpty ? title : description,
                        url: link,
                        sourceName: source.isEmpty ? "Google News" : source,
                        publishDate: pubDate.isEmpty ? nil : pubDate,
                        thumbnailURL: nil,
                        domInteractiveElementsCount: 0,
                        latencyMs: 0
                    )
                )
            }
        }
        return results
    }

    // MARK: - Tier 2: OpenSearch & Wikimedia Knowledge Index
    private func queryOpenSearchIndex(query: String) async -> [GenieSearchIndexResult] {
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://en.wikipedia.org/w/api.php?action=opensearch&search=\(encoded)&limit=4&namespace=0&format=json") else {
            return []
        }

        var req = URLRequest(url: url, timeoutInterval: 4.0)
        req.setValue("GenieAI/4.0 (https://github.com/nicholasdudek/Genie)", forHTTPHeaderField: "User-Agent")

        guard let (data, resp) = try? await session.data(for: req),
              let http = resp as? HTTPURLResponse, http.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [Any],
              json.count >= 4,
              let titles = json[1] as? [String],
              let snippets = json[2] as? [String],
              let urls = json[3] as? [String] else {
            return []
        }

        var results: [GenieSearchIndexResult] = []
        for i in 0..<min(titles.count, urls.count) {
            let t = titles[i]
            let u = urls[i]
            let s = i < snippets.count ? snippets[i] : ""
            if !t.isEmpty && !u.isEmpty {
                results.append(
                    GenieSearchIndexResult(
                        title: t,
                        snippet: s.isEmpty ? "Encyclopedia entry for \(t)" : s,
                        url: u,
                        sourceName: "Wikipedia",
                        publishDate: nil,
                        thumbnailURL: nil,
                        domInteractiveElementsCount: 25,
                        latencyMs: 0
                    )
                )
            }
        }
        return results
    }

    // MARK: - Tier 3: DuckDuckGo Instant Answer / Abstract Index
    private func queryDuckDuckGoAbstract(query: String) async -> [GenieSearchIndexResult] {
        guard let encoded = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "https://api.duckduckgo.com/?q=\(encoded)&format=json&no_html=1") else {
            return []
        }

        var req = URLRequest(url: url, timeoutInterval: 4.0)
        req.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)", forHTTPHeaderField: "User-Agent")

        guard let (data, resp) = try? await session.data(for: req),
              let http = resp as? HTTPURLResponse, http.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return []
        }

        var results: [GenieSearchIndexResult] = []
        if let abstract = json["AbstractText"] as? String, !abstract.isEmpty {
            let src = (json["AbstractSource"] as? String) ?? "DuckDuckGo"
            let u = (json["AbstractURL"] as? String) ?? "https://duckduckgo.com/?q=\(encoded)"
            let img = json["Image"] as? String
            results.append(
                GenieSearchIndexResult(
                    title: (json["Heading"] as? String) ?? query,
                    snippet: abstract,
                    url: u,
                    sourceName: src,
                    publishDate: nil,
                    thumbnailURL: img?.isEmpty == false ? img : nil,
                    domInteractiveElementsCount: 15,
                    latencyMs: 0
                )
            )
        }

        if let related = json["RelatedTopics"] as? [[String: Any]] {
            for item in related.prefix(3) {
                if let text = item["Text"] as? String, !text.isEmpty, let firstURL = item["FirstURL"] as? String {
                    let icon = (item["Icon"] as? [String: Any])?["URL"] as? String
                    results.append(
                        GenieSearchIndexResult(
                            title: text.components(separatedBy: " - ").first ?? "Result",
                            snippet: text,
                            url: firstURL,
                            sourceName: "Web Index",
                            publishDate: nil,
                            thumbnailURL: icon?.isEmpty == false ? icon : nil,
                            domInteractiveElementsCount: 10,
                            latencyMs: 0
                        )
                    )
                }
            }
        }
        return results
    }

    // MARK: - Parallel Deep Page & Image Enrichment
    private func enrichResultsWithDeepCrawler(results: [GenieSearchIndexResult]) async -> [GenieSearchIndexResult] {
        var enriched = results

        // Crawl the top 2 results in parallel to resolve lead images & DOM elements
        await withTaskGroup(of: (Int, String?, Int).self) { group in
            for i in 0..<min(2, enriched.count) {
                let targetURL = enriched[i].url
                group.addTask {
                    if let crawled = try? await GenieFastWebCrawler.shared.crawl(url: targetURL) {
                        return (i, crawled.previewImageURL, crawled.domInteractiveCount)
                    }
                    return (i, nil, 0)
                }
            }

            for await (idx, imgURL, domCount) in group {
                if idx < enriched.count {
                    if let img = imgURL {
                        enriched[idx].thumbnailURL = img
                    }
                    if domCount > 0 {
                        enriched[idx].domInteractiveElementsCount = domCount
                    }
                }
            }
        }

        return enriched
    }

    // MARK: - XML & String Parsing Helpers
    private func extractXMLTag(tag: String, from xml: String) -> String {
        let pattern = "(?is)<\(tag)[^>]*>(.*?)</\(tag)>"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return "" }
        let nsString = xml as NSString
        if let match = regex.firstMatch(in: xml, range: NSRange(location: 0, length: nsString.length)),
           match.numberOfRanges > 1 {
            let val = nsString.substring(with: match.range(at: 1))
            return val
                .replacingOccurrences(of: "<!\\[CDATA\\[(.*?)\\]\\]>", with: "$1", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return ""
    }

    private func cleanHTMLTitle(_ title: String) -> String {
        title
            .replacingOccurrences(of: "(?is)<[^>]+>", with: "", options: .regularExpression)
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&nbsp;", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func buildSummary(from results: [GenieSearchIndexResult], query: String) -> String {
        guard !results.isEmpty else { return "No index results found for \"\(query)\"." }
        var parts: [String] = []
        for r in results.prefix(4) {
            parts.append("**\(r.title)** (\(r.sourceName)):\n\(r.snippet)")
        }
        return parts.joined(separator: "\n\n")
    }
}
