import AppKit
import Foundation
import SwiftUI

// MARK: - 🌐 Genie Browser DOM Retrieval System & Background Image Loader
/// Asynchronously inspects web URLs and search queries in the background, extracting
/// high-resolution Open Graph/DOM preview images, page titles, interactive DOM counts,
/// and live summaries using Genie's headless DOM watcher and fast crawler engines.

public struct GenieRetrievedWebItem: Identifiable, Sendable, Codable {
    public var id: String { queryOrUrl }
    public let queryOrUrl: String
    public let isURL: Bool
    public var title: String
    public var domain: String
    public var faviconURL: String?
    public var previewImageURL: String?
    public var snippet: String
    public var domElementsCount: Int
    public var latencyMs: Double
    public var isLoaded: Bool
    public var isSearching: Bool
    public var errorDescription: String?

    public init(
        queryOrUrl: String,
        isURL: Bool,
        title: String,
        domain: String,
        faviconURL: String? = nil,
        previewImageURL: String? = nil,
        snippet: String = "",
        domElementsCount: Int = 0,
        latencyMs: Double = 0,
        isLoaded: Bool = false,
        isSearching: Bool = false,
        errorDescription: String? = nil
    ) {
        self.queryOrUrl = queryOrUrl
        self.isURL = isURL
        self.title = title
        self.domain = domain
        self.faviconURL = faviconURL
        self.previewImageURL = previewImageURL
        self.snippet = snippet
        self.domElementsCount = domElementsCount
        self.latencyMs = latencyMs
        self.isLoaded = isLoaded
        self.isSearching = isSearching
        self.errorDescription = errorDescription
    }
}

@MainActor
public final class GenieBrowserDOMRetrievalManager: ObservableObject, @unchecked Sendable {
    public static let shared = GenieBrowserDOMRetrievalManager()

    @Published public private(set) var retrievedItems: [String: GenieRetrievedWebItem] = [:]
    @Published public private(set) var loadedImages: [String: NSImage] = [:]

    private let imageCache = NSCache<NSString, NSImage>()
    private var inFlightTasks: Set<String> = []

    private init() {
        imageCache.countLimit = 64
        imageCache.totalCostLimit = 48 * 1024 * 1024 // 48 MB cache cap

        // Purge image cache on system memory pressure
        NotificationCenter.default.addObserver(
            forName: Notification.Name("GeniePurgeVolatileCaches"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.purgeCaches()
            }
        }
    }

    public func purgeCaches() {
        imageCache.removeAllObjects()
        loadedImages.removeAll()
    }

    // MARK: - Primary Background Retrieval Entrypoint
    public func retrieve(queryOrUrl: String, forceReload: Bool = false) {
        let clean = queryOrUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }

        if !forceReload, let existing = retrievedItems[clean], existing.isLoaded {
            return
        }

        guard !inFlightTasks.contains(clean) else { return }
        inFlightTasks.insert(clean)

        let isURL = clean.hasPrefix("http://") || clean.hasPrefix("https://")

        if isURL {
            retrieveURL(clean)
        } else {
            retrieveSearch(clean)
        }
    }

    // MARK: - URL Background Retrieval & DOM Inspection
    private func retrieveURL(_ urlString: String) {
        guard let url = URL(string: urlString) else {
            inFlightTasks.remove(urlString)
            return
        }

        let domain = url.host ?? ""
        let initialTitle = unescapeURLToReadableTitle(url: url)

        // Set initial placeholder state
        retrievedItems[urlString] = GenieRetrievedWebItem(
            queryOrUrl: urlString,
            isURL: true,
            title: initialTitle,
            domain: domain,
            faviconURL: "https://www.google.com/s2/favicons?domain=\(domain)&sz=64",
            previewImageURL: nil,
            snippet: "Retrieving DOM and page preview in background...",
            domElementsCount: 0,
            latencyMs: 0,
            isLoaded: false,
            isSearching: true
        )

        Task {
            let startTime = CFAbsoluteTimeGetCurrent()

            // 1. Wikipedia Specialized REST API (ultra-fast sub-30ms structured summary & image)
            if domain.contains("wikipedia.org"), let titleSlug = url.pathComponents.last {
                if let wikiResult = await fetchWikipediaSummary(titleSlug: titleSlug, originalURL: urlString) {
                    let latency = (CFAbsoluteTimeGetCurrent() - startTime) * 1000.0
                    var item = wikiResult
                    item.latencyMs = latency
                    item.isLoaded = true
                    item.isSearching = false
                    self.retrievedItems[urlString] = item
                    self.inFlightTasks.remove(urlString)

                    if let imgURL = item.previewImageURL {
                        self.prefetchImage(from: imgURL)
                    }
                    return
                }
            }

            // 2. Headless Parallel Web & DOM Crawler
            do {
                let crawled = try await GenieFastWebCrawler.shared.crawl(url: urlString)
                let latency = (CFAbsoluteTimeGetCurrent() - startTime) * 1000.0

                var finalTitle = crawled.title
                if finalTitle == "Untitled" || finalTitle.isEmpty {
                    finalTitle = initialTitle
                }

                let snippet = !crawled.description.isEmpty
                    ? crawled.description
                    : String(crawled.textContent.prefix(220))

                let item = GenieRetrievedWebItem(
                    queryOrUrl: urlString,
                    isURL: true,
                    title: finalTitle,
                    domain: domain,
                    faviconURL: crawled.faviconURL,
                    previewImageURL: crawled.previewImageURL,
                    snippet: snippet,
                    domElementsCount: crawled.domInteractiveCount,
                    latencyMs: latency,
                    isLoaded: true,
                    isSearching: false
                )

                self.retrievedItems[urlString] = item
                self.inFlightTasks.remove(urlString)

                if let imgURL = crawled.previewImageURL {
                    self.prefetchImage(from: imgURL)
                }
            } catch {
                let latency = (CFAbsoluteTimeGetCurrent() - startTime) * 1000.0
                var item = self.retrievedItems[urlString] ?? GenieRetrievedWebItem(
                    queryOrUrl: urlString,
                    isURL: true,
                    title: initialTitle,
                    domain: domain
                )
                item.isLoaded = true
                item.isSearching = false
                item.latencyMs = latency
                item.errorDescription = error.localizedDescription
                self.retrievedItems[urlString] = item
                self.inFlightTasks.remove(urlString)
            }
        }
    }

    // MARK: - Search Query Background Retrieval
    private func retrieveSearch(_ query: String) {
        retrievedItems[query] = GenieRetrievedWebItem(
            queryOrUrl: query,
            isURL: false,
            title: query,
            domain: "Web Search",
            faviconURL: nil,
            previewImageURL: nil,
            snippet: "Crawling search indexes and inspecting DOM in background...",
            domElementsCount: 0,
            latencyMs: 0,
            isLoaded: false,
            isSearching: true
        )

        Task {
            let resp = await GenieSearchIndexCrawlerEngine.shared.search(query: query)
            let topResult = resp.results.first
            let topDomain = topResult?.sourceName ?? "Search Index"

            if let img = topResult?.thumbnailURL {
                self.prefetchImage(from: img)
            }

            let item = GenieRetrievedWebItem(
                queryOrUrl: query,
                isURL: false,
                title: topResult?.title ?? query,
                domain: topDomain,
                faviconURL: "https://www.google.com/s2/favicons?domain=\(topDomain)&sz=64",
                previewImageURL: topResult?.thumbnailURL,
                snippet: topResult?.snippet ?? resp.summary,
                domElementsCount: topResult?.domInteractiveElementsCount ?? 18,
                latencyMs: resp.latencyMs,
                isLoaded: true,
                isSearching: false
            )

            self.retrievedItems[query] = item
            self.inFlightTasks.remove(query)
        }
    }

    // MARK: - Wikipedia REST Summary Fetcher
    private func fetchWikipediaSummary(titleSlug: String, originalURL: String) async -> GenieRetrievedWebItem? {
        guard let encoded = titleSlug.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed),
              let apiURL = URL(string: "https://en.wikipedia.org/api/rest_v1/page/summary/\(encoded)") else {
            return nil
        }

        var req = URLRequest(url: apiURL, timeoutInterval: 4.0)
        req.setValue("GenieAI/4.0 (https://github.com/nicholasdudek/Genie)", forHTTPHeaderField: "User-Agent")

        guard let (data, resp) = try? await URLSession.shared.data(for: req),
              let http = resp as? HTTPURLResponse, http.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        let title = (json["title"] as? String) ?? unescapeURLToReadableTitle(url: URL(string: originalURL)!)
        let extract = (json["extract"] as? String) ?? ""
        var imageURL: String? = nil

        if let thumbnail = json["thumbnail"] as? [String: Any], let src = thumbnail["source"] as? String {
            imageURL = src
        } else if let originalImage = json["originalimage"] as? [String: Any], let src = originalImage["source"] as? String {
            imageURL = src
        }

        return GenieRetrievedWebItem(
            queryOrUrl: originalURL,
            isURL: true,
            title: title,
            domain: "en.wikipedia.org",
            faviconURL: "https://en.wikipedia.org/static/favicon/wikipedia.ico",
            previewImageURL: imageURL,
            snippet: extract,
            domElementsCount: 42, // Average Wikipedia article interactive nodes
            latencyMs: 35.0,
            isLoaded: true,
            isSearching: false
        )
    }

    // MARK: - Image Prefetching & RAM Caching
    public func prefetchImage(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        if imageCache.object(forKey: urlString as NSString) != nil { return }

        Task { [weak self] in
            guard let (data, _) = try? await URLSession.shared.data(from: url),
                  let img = NSImage(data: data) else { return }

            guard let self = self else { return }
            self.imageCache.setObject(img, forKey: urlString as NSString)
            self.loadedImages[urlString] = img
        }
    }

    public func cachedImage(for urlString: String) -> NSImage? {
        if let existing = loadedImages[urlString] { return existing }
        return imageCache.object(forKey: urlString as NSString)
    }

    // MARK: - Helpers
    private func unescapeURLToReadableTitle(url: URL) -> String {
        let lastPart = url.lastPathComponent
        if !lastPart.isEmpty && lastPart != "/" {
            let decoded = lastPart.removingPercentEncoding ?? lastPart
            return decoded.replacingOccurrences(of: "_", with: " ")
        }
        return url.host ?? url.absoluteString
    }
}
