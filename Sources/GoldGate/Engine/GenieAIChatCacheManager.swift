import AppKit
import CommonCrypto
import Foundation
import SwiftUI

// MARK: - Cached Chat Completion Record
public struct CachedChatCompletion: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let key: String
    public let prompt: String
    public let model: String
    public let response: String
    public let thinking: String?
    public let mediaPath: String?
    public let createdAt: Date
    public var lastAccessedAt: Date
    public var hitCount: Int
    public let tokens: Int
    public let latencyMs: Double

    public init(
        id: UUID = UUID(),
        key: String,
        prompt: String,
        model: String,
        response: String,
        thinking: String? = nil,
        mediaPath: String? = nil,
        createdAt: Date = Date(),
        lastAccessedAt: Date = Date(),
        hitCount: Int = 0,
        tokens: Int = 0,
        latencyMs: Double = 0
    ) {
        self.id = id
        self.key = key
        self.prompt = prompt
        self.model = model
        self.response = response
        self.thinking = thinking
        self.mediaPath = mediaPath
        self.createdAt = createdAt
        self.lastAccessedAt = lastAccessedAt
        self.hitCount = hitCount
        self.tokens = tokens > 0 ? tokens : max(1, response.count / 4)
        self.latencyMs = latencyMs
    }

    public var isExpired: Bool {
        // 24 hour TTL by default
        Date().timeIntervalSince(createdAt) > 86400
    }
}

// MARK: - 🧠 Genie AI Chat Cache & Architectural Intelligence Manager
@MainActor
public final class GenieAIChatCacheManager: ObservableObject {
    public static let shared = GenieAIChatCacheManager()

    // ── Cache Metrics & Observability ───────────────────────────────────────
    @Published public private(set) var cacheHits: Int = 0
    @Published public private(set) var cacheMisses: Int = 0
    @Published public private(set) var cachedEntriesCount: Int = 0
    @Published public private(set) var lastHitTimestamp: Date? = nil
    @Published public private(set) var estimatedMemoryBytes: Int64 = 0

    // ── Internal In-Memory LRU Cache ────────────────────────────────────────
    private var inMemoryCache: [String: CachedChatCompletion] = [:]
    private var accessOrder: [String] = [] // Most recently used at end
    private let maxEntries: Int = 250
    private let queue = DispatchQueue(label: "com.genie.aichat.cache.io", qos: .utility)

    // ── File System Directories ─────────────────────────────────────────────
    public let cacheDirectory: URL
    public let sessionsDirectory: URL

    // ── KV Prefix Caching Tokens ────────────────────────────────────────────
    /// Estimated prompt tokens to retain in Ollama / llama.cpp KV cache across turns.
    public var systemPromptKeepTokens: Int {
        // Section 12 + tool specifications average ~2,200 tokens
        return 2200
    }

    public var hitRatio: Double {
        let total = cacheHits + cacheMisses
        guard total > 0 else { return 0.0 }
        return Double(cacheHits) / Double(total)
    }

    private init() {
        let fileManager = FileManager.default

        // 1. Setup APFS Cache Directory
        let cachesURL = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        self.cacheDirectory = cachesURL.appendingPathComponent("Genie/AIChat", isDirectory: true)

        // 2. Setup Sessions Directory
        let appSupportURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        self.sessionsDirectory = appSupportURL.appendingPathComponent("Genie/ChatSessions", isDirectory: true)

        try? fileManager.createDirectory(at: self.cacheDirectory, withIntermediateDirectories: true)
        try? fileManager.createDirectory(at: self.sessionsDirectory, withIntermediateDirectories: true)

        // 3. Listen for volatile cache purge from GenieMemoryGovernorEngine
        NotificationCenter.default.addObserver(
            forName: Notification.Name("GeniePurgeVolatileCaches"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.purgeVolatileCache()
            }
        }

        // 4. Load persisted cache metadata from disk
        loadDiskCacheIndex()
    }

    // MARK: - SHA-256 Key Derivation
    public func cacheKey(prompt: String, model: String, mediaPath: String? = nil) -> String {
        let normalized = prompt.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let cleanModel = model.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let mediaStr = mediaPath ?? ""
        let combined = "\(cleanModel)|\(mediaStr)|\(normalized)"

        guard let data = combined.data(using: .utf8) else {
            return String(combined.hashValue)
        }

        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { buffer in
            _ = CC_SHA256(buffer.baseAddress, CC_LONG(data.count), &hash)
        }

        return hash.map { String(format: "%02x", $0) }.joined()
    }

    // MARK: - Cache Resolution (Lookup)
    public func resolve(prompt: String, model: String, mediaPath: String? = nil) -> CachedChatCompletion? {
        let key = cacheKey(prompt: prompt, model: model, mediaPath: mediaPath)

        if var entry = inMemoryCache[key] {
            if entry.isExpired {
                removeEntry(key: key)
                cacheMisses += 1
                return nil
            }
            entry.hitCount += 1
            entry.lastAccessedAt = Date()
            inMemoryCache[key] = entry

            // Update LRU access order
            if let idx = accessOrder.firstIndex(of: key) {
                accessOrder.remove(at: idx)
            }
            accessOrder.append(key)

            cacheHits += 1
            lastHitTimestamp = Date()
            return entry
        }

        cacheMisses += 1
        return nil
    }

    // MARK: - Cache Insertion
    public func store(
        prompt: String,
        model: String,
        response: String,
        thinking: String? = nil,
        mediaPath: String? = nil,
        latencyMs: Double = 0
    ) {
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !response.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        // Skip ephemeral slash commands from cache
        if prompt.hasPrefix("/") { return }

        let key = cacheKey(prompt: prompt, model: model, mediaPath: mediaPath)
        let entry = CachedChatCompletion(
            key: key,
            prompt: prompt,
            model: model,
            response: response,
            thinking: thinking,
            mediaPath: mediaPath,
            createdAt: Date(),
            lastAccessedAt: Date(),
            hitCount: 0,
            tokens: max(1, response.count / 4),
            latencyMs: latencyMs
        )

        inMemoryCache[key] = entry

        if let idx = accessOrder.firstIndex(of: key) {
            accessOrder.remove(at: idx)
        }
        accessOrder.append(key)

        // Enforce LRU capacity limit
        if accessOrder.count > maxEntries {
            let oldestKey = accessOrder.removeFirst()
            inMemoryCache.removeValue(forKey: oldestKey)
        }

        cachedEntriesCount = inMemoryCache.count
        recalculateMemoryUsage()

        // Asynchronously persist to APFS disk cache
        persistEntryToDisk(entry)
    }

    // MARK: - Remove Entry
    private func removeEntry(key: String) {
        inMemoryCache.removeValue(forKey: key)
        if let idx = accessOrder.firstIndex(of: key) {
            accessOrder.remove(at: idx)
        }
        cachedEntriesCount = inMemoryCache.count
        recalculateMemoryUsage()

        let fileURL = cacheDirectory.appendingPathComponent("\(key).json")
        try? FileManager.default.removeItem(at: fileURL)
    }

    // MARK: - Purge Volatile Caches (Memory Governor Integration)
    public func purgeVolatileCache() {
        print("🧠 [Genie AIChatCache] Purging in-memory volatile response cache (\(inMemoryCache.count) entries) to release RAM.")
        inMemoryCache.removeAll()
        accessOrder.removeAll()
        cachedEntriesCount = 0
        estimatedMemoryBytes = 0
    }

    // MARK: - Clear All Cache
    public func clearCache() {
        purgeVolatileCache()
        cacheHits = 0
        cacheMisses = 0

        queue.async { [cacheDirectory] in
            let fm = FileManager.default
            if let files = try? fm.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil) {
                for file in files where file.pathExtension == "json" {
                    try? fm.removeItem(at: file)
                }
            }
        }
    }

    // MARK: - Disk Persistence
    private func persistEntryToDisk(_ entry: CachedChatCompletion) {
        let dir = self.cacheDirectory
        queue.async {
            let fileURL = dir.appendingPathComponent("\(entry.key).json")
            if let data = try? JSONEncoder().encode(entry) {
                try? data.write(to: fileURL, options: .atomic)
            }
        }
    }

    private func loadDiskCacheIndex() {
        let dir = self.cacheDirectory
        queue.async { [weak self] in
            let fm = FileManager.default
            guard let files = try? fm.contentsOfDirectory(at: dir, includingPropertiesForKeys: [.contentModificationDateKey]) else { return }

            var loaded: [String: CachedChatCompletion] = [:]
            var keysByDate: [(String, Date)] = []

            for file in files.prefix(150) where file.pathExtension == "json" {
                guard let data = try? Data(contentsOf: file),
                      let entry = try? JSONDecoder().decode(CachedChatCompletion.self, from: data),
                      !entry.isExpired else {
                    try? fm.removeItem(at: file)
                    continue
                }
                loaded[entry.key] = entry
                keysByDate.append((entry.key, entry.lastAccessedAt))
            }

            keysByDate.sort { $0.1 < $1.1 }
            let orderedKeys = keysByDate.map { $0.0 }

            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.inMemoryCache = loaded
                self.accessOrder = orderedKeys
                self.cachedEntriesCount = loaded.count
                self.recalculateMemoryUsage()
            }
        }
    }

    // MARK: - APFS Session Persistence Helper
    public func persistSessionsToDisk(_ sessions: [SavedChatSession]) {
        let dir = self.sessionsDirectory
        queue.async {
            let fileURL = dir.appendingPathComponent("sessions_manifest.json")
            if let data = try? JSONEncoder().encode(sessions) {
                try? data.write(to: fileURL, options: .atomic)
            }
        }
    }

    public func loadSessionsFromDisk() -> [SavedChatSession]? {
        let fileURL = sessionsDirectory.appendingPathComponent("sessions_manifest.json")
        guard let data = try? Data(contentsOf: fileURL),
              let decoded = try? JSONDecoder().decode([SavedChatSession].self, from: data) else {
            return nil
        }
        return decoded
    }

    private func recalculateMemoryUsage() {
        var bytes: Int64 = 0
        for entry in inMemoryCache.values {
            bytes += Int64(entry.prompt.utf8.count + entry.response.utf8.count + (entry.thinking?.utf8.count ?? 0) + 128)
        }
        self.estimatedMemoryBytes = bytes
    }

    // MARK: - Diagnostic Summary
    public func exportStatsSummary() -> String {
        let ratioPct = String(format: "%.1f%%", hitRatio * 100.0)
        let memKB = Double(estimatedMemoryBytes) / 1024.0
        return """
        ⚡ **[Genie AI Chat Cache & Architecture Diagnostics]**
        • Cached Entries: \(cachedEntriesCount) / \(maxEntries) max
        • Cache Hits: \(cacheHits) | Cache Misses: \(cacheMisses) (Hit Ratio: \(ratioPct))
        • KV Prefix Retention: \(systemPromptKeepTokens) tokens (`num_keep` active)
        • Memory Ingestion: \(String(format: "%.1f KB", memKB))
        • APFS Cache Root: `~/Library/Caches/Genie/AIChat/`
        • RAM Governor Integration: Active (Listening for `GeniePurgeVolatileCaches`)
        """
    }
}
