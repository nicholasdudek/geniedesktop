import Foundation

// MARK: - Sub-100ms Headless High-Speed Parallel Web & Image Crawler
// Completely bypasses heavy WebKit rendering and viewport compositing, directly
// extracting readable text, metadata, and high-resolution images via parallel streaming.

public struct CrawledImageInfo: Identifiable, Codable, Sendable {
    public var id: String { url }
    public let url: String
    public let altText: String
}

public struct CrawledPageResult: Identifiable, Codable, Sendable {
    public var id: String { url }
    public let url: String
    public let title: String
    public let textContent: String
    public let images: [CrawledImageInfo]
    public let latencyMs: Double
    public let previewImageURL: String?
    public let faviconURL: String?
    public let description: String
    public let domInteractiveCount: Int

    public init(
        url: String,
        title: String,
        textContent: String,
        images: [CrawledImageInfo],
        latencyMs: Double,
        previewImageURL: String? = nil,
        faviconURL: String? = nil,
        description: String = "",
        domInteractiveCount: Int = 0
    ) {
        self.url = url
        self.title = title
        self.textContent = textContent
        self.images = images
        self.latencyMs = latencyMs
        self.previewImageURL = previewImageURL
        self.faviconURL = faviconURL
        self.description = description
        self.domInteractiveCount = domInteractiveCount
    }
}

public actor GenieFastWebCrawler {
    public static let shared = GenieFastWebCrawler()

    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 4.0
        config.timeoutIntervalForResource = 8.0
        config.httpAdditionalHeaders = [
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.4 Safari/605.1.15",
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "en-US,en;q=0.9"
        ]
        self.session = URLSession(configuration: config)
    }

    /// Crawls a web page URL directly, extracting title, main clean text, and images in milliseconds
    public func crawl(url urlString: String) async throws -> CrawledPageResult {
        let startTime = CFAbsoluteTimeGetCurrent()
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "GenieFastWebCrawler", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL format"])
        }

        let (data, _) = try await session.data(from: url)
        guard let html = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) else {
            throw NSError(domain: "GenieFastWebCrawler", code: 422, userInfo: [NSLocalizedDescriptionKey: "Unable to decode HTML content"])
        }

        let title = extractTitle(from: html)
        let text = extractCleanText(from: html)
        let images = extractImages(from: html, baseURL: url)
        let previewImage = extractMetaImage(from: html, baseURL: url) ?? images.first?.url
        let description = extractMetaDescription(from: html)
        let favicon = extractFavicon(from: html, baseURL: url)
        let domCount = countDOMInteractiveElements(from: html)
        let latency = (CFAbsoluteTimeGetCurrent() - startTime) * 1000.0

        return CrawledPageResult(
            url: urlString,
            title: title,
            textContent: text,
            images: images,
            latencyMs: latency,
            previewImageURL: previewImage,
            faviconURL: favicon,
            description: description,
            domInteractiveCount: domCount
        )
    }

    /// Crawls multiple URLs in parallel using Swift concurrency
    public func crawlParallel(urls: [String]) async -> [CrawledPageResult] {
        await withTaskGroup(of: CrawledPageResult?.self) { group in
            for u in urls.prefix(6) {
                group.addTask {
                    try? await self.crawl(url: u)
                }
            }
            var results: [CrawledPageResult] = []
            for await res in group {
                if let r = res { results.append(r) }
            }
            return results
        }
    }

    private func extractTitle(from html: String) -> String {
        if let range = html.range(of: "(?i)<title[^>]*>(.*?)</title>", options: .regularExpression) {
            let matched = String(html[range])
            return matched
                .replacingOccurrences(of: "(?i)<[^>]+>", with: "", options: .regularExpression)
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return "Untitled"
    }

    private func extractCleanText(from html: String) -> String {
        var clean = html
        // Remove script, style, svg, and nav elements
        let removals = [
            "(?is)<script[^>]*>.*?</script>",
            "(?is)<style[^>]*>.*?</style>",
            "(?is)<svg[^>]*>.*?</svg>",
            "(?is)<nav[^>]*>.*?</nav>",
            "(?is)<footer[^>]*>.*?</footer>",
            "(?is)<header[^>]*>.*?</header>"
        ]
        for pattern in removals {
            clean = clean.replacingOccurrences(of: pattern, with: " ", options: .regularExpression)
        }
        // Remove remaining HTML tags
        clean = clean.replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
        // Normalize whitespace
        clean = clean.replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        let trimmed = clean.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count > 12_000 ? String(trimmed.prefix(12_000)) + "..." : trimmed
    }

    private func extractImages(from html: String, baseURL: URL) -> [CrawledImageInfo] {
        var images: [CrawledImageInfo] = []
        let pattern = "(?i)<img[^>]+src=[\"']([^\"']+)[\"'][^>]*>"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }

        let nsString = html as NSString
        let matches = regex.matches(in: html, range: NSRange(location: 0, length: nsString.length))

        for match in matches.prefix(12) {
            guard match.numberOfRanges > 1 else { continue }
            let rawSrc = nsString.substring(with: match.range(at: 1))
            let fullURLString: String
            if rawSrc.hasPrefix("http://") || rawSrc.hasPrefix("https://") {
                fullURLString = rawSrc
            } else if let resolved = URL(string: rawSrc, relativeTo: baseURL)?.absoluteString {
                fullURLString = resolved
            } else {
                continue
            }

            // Exclude tracker pixels and icons
            if fullURLString.contains("favicon") || fullURLString.contains(".svg") || fullURLString.contains("1x1") {
                continue
            }

            var alt = ""
            let tagString = nsString.substring(with: match.range(at: 0))
            if let altRange = tagString.range(of: "(?i)alt=[\"']([^\"']*)[\"']", options: .regularExpression) {
                alt = String(tagString[altRange])
                    .replacingOccurrences(of: "(?i)alt=[\"']|[\"']$", with: "", options: .regularExpression)
            }

            images.append(CrawledImageInfo(url: fullURLString, altText: alt))
        }
        return images
    }

    private func extractMetaImage(from html: String, baseURL: URL) -> String? {
        let patterns = [
            "(?i)<meta[^>]+property=[\"']og:image[\"'][^>]+content=[\"']([^\"']+)[\"']",
            "(?i)<meta[^>]+content=[\"']([^\"']+)[\"'][^>]+property=[\"']og:image[\"']",
            "(?i)<meta[^>]+name=[\"']twitter:image[\"'][^>]+content=[\"']([^\"']+)[\"']",
            "(?i)<meta[^>]+content=[\"']([^\"']+)[\"'][^>]+name=[\"']twitter:image[\"']"
        ]
        for p in patterns {
            if let regex = try? NSRegularExpression(pattern: p),
               let match = regex.firstMatch(in: html, range: NSRange(location: 0, length: (html as NSString).length)),
               match.numberOfRanges > 1 {
                let raw = (html as NSString).substring(with: match.range(at: 1))
                if raw.hasPrefix("http://") || raw.hasPrefix("https://") {
                    return raw
                } else if let resolved = URL(string: raw, relativeTo: baseURL)?.absoluteString {
                    return resolved
                }
            }
        }
        return nil
    }

    private func extractMetaDescription(from html: String) -> String {
        let patterns = [
            "(?i)<meta[^>]+property=[\"']og:description[\"'][^>]+content=[\"']([^\"']+)[\"']",
            "(?i)<meta[^>]+content=[\"']([^\"']+)[\"'][^>]+property=[\"']og:description[\"']",
            "(?i)<meta[^>]+name=[\"']description[\"'][^>]+content=[\"']([^\"']+)[\"']",
            "(?i)<meta[^>]+content=[\"']([^\"']+)[\"'][^>]+name=[\"']description[\"']"
        ]
        for p in patterns {
            if let regex = try? NSRegularExpression(pattern: p),
               let match = regex.firstMatch(in: html, range: NSRange(location: 0, length: (html as NSString).length)),
               match.numberOfRanges > 1 {
                let desc = (html as NSString).substring(with: match.range(at: 1))
                return desc.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return ""
    }

    private func extractFavicon(from html: String, baseURL: URL) -> String {
        let patterns = [
            "(?i)<link[^>]+rel=[\"'](?:shortcut icon|icon)[\"'][^>]+href=[\"']([^\"']+)[\"']",
            "(?i)<link[^>]+href=[\"']([^\"']+)[\"'][^>]+rel=[\"'](?:shortcut icon|icon)[\"']"
        ]
        for p in patterns {
            if let regex = try? NSRegularExpression(pattern: p),
               let match = regex.firstMatch(in: html, range: NSRange(location: 0, length: (html as NSString).length)),
               match.numberOfRanges > 1 {
                let raw = (html as NSString).substring(with: match.range(at: 1))
                if raw.hasPrefix("http://") || raw.hasPrefix("https://") {
                    return raw
                } else if let resolved = URL(string: raw, relativeTo: baseURL)?.absoluteString {
                    return resolved
                }
            }
        }
        if let host = baseURL.host {
            return "https://www.google.com/s2/favicons?domain=\(host)&sz=64"
        }
        return ""
    }

    private func countDOMInteractiveElements(from html: String) -> Int {
        let pattern = "(?i)<(?:a\\b|button\\b|input\\b|select\\b|textarea\\b)"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return 0 }
        return regex.numberOfMatches(in: html, range: NSRange(location: 0, length: (html as NSString).length))
    }
}
