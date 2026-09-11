import AppKit
import Foundation

// MARK: - 📁 Genie Local File Item
public struct GenieLocalFileItem: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let path: String
    public let url: URL
    public let fileSize: Int64
    public let formattedSize: String
    public let modifiedDate: Date
    public let isDirectory: Bool
    public let extensionName: String
    public let category: String
    public let snippetPreview: String?
    public let signature: IPESignature

    public init(url: URL, fileSize: Int64, modifiedDate: Date, isDirectory: Bool, snippetPreview: String? = nil) {
        self.id = url.path
        self.name = url.lastPathComponent
        self.path = url.path
        self.url = url
        self.fileSize = fileSize
        self.formattedSize = ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
        self.modifiedDate = modifiedDate
        self.isDirectory = isDirectory
        self.extensionName = url.pathExtension.lowercased()

        let reg = GenieFileTypesRegistry.shared.typeInfo(for: url)
        self.category = isDirectory ? "Folder" : reg.category
        self.snippetPreview = snippetPreview
        self.signature = IPESignature.create(from: url.lastPathComponent + " " + url.path)
    }
}

// MARK: - ⚡️ Genie Local File Crawler Engine
/// High-speed local file crawler and indexer with Inverse Probability Elimination (IPE).
/// Eliminates slow `/usr/bin/mdfind` subprocess storms and provides sub-millisecond
/// in-memory search over Desktop, Developer, Spaces, and VM mounts.
public final class GenieLocalFileCrawlerEngine: @unchecked Sendable {
    public static let shared = GenieLocalFileCrawlerEngine()

    private let lock = NSLock()
    private var indexedItems: [GenieLocalFileItem] = []
    private var isIndexing: Bool = false
    private var lastIndexDate: Date?

    /// Maximum items held in memory index (~2 MB footprint)
    public let maxIndexCapacity: Int = 10_000

    /// Directories ignored during recursive crawl to protect performance
    public let ignoredDirectoryNames: Set<String> = [
        ".git", "node_modules", ".build", "DerivedData", ".Trash", ".Trashes",
        ".DS_Store", "Pods", "vendor", ".svn", ".hg", "Caches", ".gradle", ".idea"
    ]

    private init() {
        // Listen for volatile cache purge notifications
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("GeniePurgeVolatileCaches"),
            object: nil,
            queue: nil
        ) { [weak self] _ in
            self?.purgeIndex()
        }
    }

    // MARK: - Public API

    public var totalIndexedCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return indexedItems.count
    }

    public var lastIndexedTimestamp: Date? {
        lock.lock()
        defer { lock.unlock() }
        return lastIndexDate
    }

    /// Purge memory index to zero when RAM governor requires pressure relief
    public func purgeIndex() {
        lock.lock()
        indexedItems.removeAll(keepingCapacity: false)
        lastIndexDate = nil
        lock.unlock()
    }

    /// Crawls a specific directory up to maxDepth and returns discovered file items
    public func crawlDirectory(
        _ rootURL: URL,
        maxDepth: Int = 4,
        extractSnippets: Bool = true,
        limit: Int = 1000
    ) -> [GenieLocalFileItem] {
        var results: [GenieLocalFileItem] = []
        let fm = FileManager.default

        guard fm.fileExists(atPath: rootURL.path) else { return [] }

        let resourceKeys: [URLResourceKey] = [
            .fileSizeKey,
            .contentModificationDateKey,
            .isDirectoryKey,
            .isRegularFileKey
        ]

        guard let enumerator = fm.enumerator(
            at: rootURL,
            includingPropertiesForKeys: resourceKeys,
            options: [.skipsHiddenFiles],
            errorHandler: { _, _ in true }
        ) else { return [] }

        let rootDepth = rootURL.pathComponents.count

        while let itemURL = enumerator.nextObject() as? URL {
            let currentDepth = itemURL.pathComponents.count - rootDepth
            if currentDepth > maxDepth {
                enumerator.skipDescendants()
                continue
            }

            let lastComponent = itemURL.lastPathComponent
            if ignoredDirectoryNames.contains(lastComponent) {
                enumerator.skipDescendants()
                continue
            }

            guard let resourceValues = try? itemURL.resourceValues(forKeys: Set(resourceKeys)) else {
                continue
            }

            let isDir = resourceValues.isDirectory ?? false
            let fileSize = Int64(resourceValues.fileSize ?? 0)
            let modDate = resourceValues.contentModificationDate ?? Date()

            var snippet: String? = nil
            if extractSnippets && !isDir && fileSize > 0 && fileSize < 512_000 {
                snippet = readSnippetPreview(from: itemURL)
            }

            let item = GenieLocalFileItem(
                url: itemURL,
                fileSize: fileSize,
                modifiedDate: modDate,
                isDirectory: isDir,
                snippetPreview: snippet
            )
            results.append(item)

            if results.count >= limit {
                break
            }
        }

        return results
    }

    /// Fast sub-millisecond search across local files using IPE 64-bit trigram bitmask
    public func searchFiles(
        query: String,
        rootFilter: URL? = nil,
        maxResults: Int = 20
    ) -> [GenieLocalFileItem] {
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !cleanQuery.isEmpty else { return [] }

        let querySig = IPESignature.create(from: cleanQuery)

        lock.lock()
        let pool = indexedItems
        lock.unlock()

        // If pool is empty, do an on-demand crawl of common user folders
        let candidates: [GenieLocalFileItem]
        if pool.isEmpty {
            candidates = crawlDefaultRoots(limitPerRoot: 250)
            updateIndex(with: candidates)
        } else {
            candidates = pool
        }

        var surviving: [(item: GenieLocalFileItem, score: Double)] = []
        surviving.reserveCapacity(min(candidates.count, 256))

        for candidate in candidates {
            // Check root filter if specified
            if let root = rootFilter, !candidate.path.hasPrefix(root.path) {
                continue
            }

            // Stage 1: Ultra-fast IPE bitmask negative elimination
            if candidate.signature.shouldEliminate(querySignature: querySig) {
                continue
            }

            // Stage 2: Prefix and Substring scoring
            let lowerName = candidate.name.lowercased()
            let lowerPath = candidate.path.lowercased()

            if lowerName == cleanQuery {
                surviving.append((candidate, 100.0))
            } else if lowerName.hasPrefix(cleanQuery) {
                surviving.append((candidate, 85.0 + Double(cleanQuery.count) / Double(lowerName.count) * 10.0))
            } else if let range = lowerName.range(of: cleanQuery) {
                let dist = lowerName.distance(from: lowerName.startIndex, to: range.lowerBound)
                surviving.append((candidate, 65.0 - Double(min(dist, 30))))
            } else if lowerPath.contains(cleanQuery) {
                surviving.append((candidate, 40.0))
            } else if let snippet = candidate.snippetPreview?.lowercased(), snippet.contains(cleanQuery) {
                surviving.append((candidate, 30.0))
            } else {
                // Character sequence fuzzy match
                var qIdx = cleanQuery.startIndex
                var matches = 0
                for c in lowerName {
                    if qIdx < cleanQuery.endIndex && c == cleanQuery[qIdx] {
                        matches += 1
                        qIdx = cleanQuery.index(after: qIdx)
                    }
                }
                if matches == cleanQuery.count {
                    surviving.append((candidate, 25.0))
                }
            }
        }

        // Sort descending by score, then by recency
        surviving.sort {
            if $0.score != $1.score {
                return $0.score > $1.score
            }
            return $0.item.modifiedDate > $1.item.modifiedDate
        }

        return surviving.prefix(maxResults).map(\.item)
    }

    /// Updates internal index with newly crawled items
    public func updateIndex(with items: [GenieLocalFileItem]) {
        lock.lock()
        defer { lock.unlock() }

        var existingMap: [String: GenieLocalFileItem] = [:]
        for item in indexedItems {
            existingMap[item.id] = item
        }
        for item in items {
            existingMap[item.id] = item
        }

        // Cap to maxIndexCapacity
        var combined = Array(existingMap.values)
        if combined.count > maxIndexCapacity {
            combined.sort(by: { $0.modifiedDate > $1.modifiedDate })
            combined = Array(combined.prefix(maxIndexCapacity))
        }

        self.indexedItems = combined
        self.lastIndexDate = Date()
    }

    /// Background crawling task for standard user work roots
    public func startBackgroundCrawl(roots: [URL]? = nil) {
        guard !isIndexing else { return }
        isIndexing = true

        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self = self else { return }
            let targetRoots = roots ?? self.defaultCrawlRoots()
            var gathered: [GenieLocalFileItem] = []

            for root in targetRoots {
                let items = self.crawlDirectory(root, maxDepth: 4, extractSnippets: true, limit: 500)
                gathered.append(contentsOf: items)
            }

            self.updateIndex(with: gathered)
            self.isIndexing = false
        }
    }

    // MARK: - Private Helpers

    public func defaultCrawlRoots() -> [URL] {
        let home = FileManager.default.homeDirectoryForCurrentUser
        var roots: [URL] = [
            home.appendingPathComponent("Desktop"),
            home.appendingPathComponent("Desktop/Developer"),
            home.appendingPathComponent("Downloads"),
            home.appendingPathComponent("Documents"),
            URL(fileURLWithPath: GenieSharedFolderForkEngine.defaultSpacesPath),
            URL(fileURLWithPath: GenieSharedFolderForkEngine.defaultBridgePath)
        ]

        // Check if RAM disk VM volume is mounted
        let ramURL = URL(fileURLWithPath: "/Volumes/GenieInRAMVM")
        if FileManager.default.fileExists(atPath: ramURL.path) {
            roots.append(ramURL)
        }

        return roots.filter { FileManager.default.fileExists(atPath: $0.path) }
    }

    private func crawlDefaultRoots(limitPerRoot: Int = 250) -> [GenieLocalFileItem] {
        var gathered: [GenieLocalFileItem] = []
        for root in defaultCrawlRoots() {
            let items = crawlDirectory(root, maxDepth: 3, extractSnippets: false, limit: limitPerRoot)
            gathered.append(contentsOf: items)
        }
        return gathered
    }

    private func readSnippetPreview(from url: URL) -> String? {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? handle.close() }

        // Read up to 512 bytes for snippet
        guard let data = try? handle.read(upToCount: 512),
              let str = String(data: data, encoding: .utf8) else {
            return nil
        }

        let lines = str.components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        let preview = lines.prefix(3).joined(separator: " ")
        return preview.count > 160 ? String(preview.prefix(157)) + "..." : preview
    }
}
