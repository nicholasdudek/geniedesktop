import AppKit
import Foundation
import Security

// MARK: - Persistent Security-Scoped Bookmarks & Always-Allowed File Permissions Manager

@MainActor
public final class SecurityBookmarkManager: ObservableObject {
    public static let shared = SecurityBookmarkManager()

    private let bookmarkStorageKey = PrefKey.securityScopedBookmarks_v1
    private let allowedPathsStorageKey = PrefKey.allowedFilePaths_v1

    // Keyed by canonical standardized file path to prevent duplicate access tokens
    private var activeSecurityScopedURLs: [String: URL] = [:]
    private var cachedAllowedPaths: Set<String> = []
    private var cachedBookmarkPaths: Set<String> = []

    private init() {
        refreshMemoryCaches()
        resolveAndAccessAllSavedBookmarks()
    }

    deinit {
        // Stop all active security-scoped resources cleanly on deallocation
        for (_, url) in activeSecurityScopedURLs {
            url.stopAccessingSecurityScopedResource()
        }
        activeSecurityScopedURLs.removeAll()
    }

    private func refreshMemoryCaches() {
        let storedPaths = UserDefaults.standard.stringArray(forKey: allowedPathsStorageKey) ?? []
        cachedAllowedPaths = Set(storedPaths)

        let storedDict = UserDefaults.standard.dictionary(forKey: bookmarkStorageKey) as? [String: Data] ?? [:]
        cachedBookmarkPaths = Set(storedDict.keys)
    }

    // MARK: - Save Bookmark (Once Allowed -> Always Allowed)

    @discardableResult
    public func saveBookmark(for url: URL) -> Bool {
        let standardURL = url.standardizedFileURL
        let pathKey = standardURL.path

        do {
            let bookmarkData = try standardURL.bookmarkData(
                options: .withSecurityScope,
                includingResourceValuesForKeys: nil,
                relativeTo: nil
            )

            var storedDict = UserDefaults.standard.dictionary(forKey: bookmarkStorageKey) as? [String: Data] ?? [:]
            storedDict[pathKey] = bookmarkData
            UserDefaults.standard.set(storedDict, forKey: bookmarkStorageKey)

            cachedBookmarkPaths.insert(pathKey)

            // Start accessing if not already active
            if activeSecurityScopedURLs[pathKey] == nil {
                if standardURL.startAccessingSecurityScopedResource() {
                    activeSecurityScopedURLs[pathKey] = standardURL
                }
            }
            return true
        } catch {
            // Fallback for non-sandboxed or standard paths
            if !cachedAllowedPaths.contains(pathKey) {
                cachedAllowedPaths.insert(pathKey)
                var storedPaths = UserDefaults.standard.stringArray(forKey: allowedPathsStorageKey) ?? []
                if !storedPaths.contains(pathKey) {
                    storedPaths.append(pathKey)
                    UserDefaults.standard.set(storedPaths, forKey: allowedPathsStorageKey)
                }
            }
            return false
        }
    }

    // MARK: - Resolve & Access All Saved Bookmarks

    public func resolveAndAccessAllSavedBookmarks() {
        guard let storedDict = UserDefaults.standard.dictionary(forKey: bookmarkStorageKey) as? [String: Data] else {
            return
        }

        var updatedDict = storedDict
        var didUpdateStale = false

        for (path, data) in storedDict {
            var isStale = false
            do {
                let resolvedURL = try URL(
                    resolvingBookmarkData: data,
                    options: .withSecurityScope,
                    relativeTo: nil,
                    bookmarkDataIsStale: &isStale
                )

                let standardPath = resolvedURL.standardizedFileURL.path
                if activeSecurityScopedURLs[standardPath] == nil {
                    if resolvedURL.startAccessingSecurityScopedResource() {
                        activeSecurityScopedURLs[standardPath] = resolvedURL
                    }
                }

                // If stale, regenerate and persist updated bookmark data
                if isStale {
                    if let freshData = try? resolvedURL.bookmarkData(
                        options: .withSecurityScope,
                        includingResourceValuesForKeys: nil,
                        relativeTo: nil
                    ) {
                        updatedDict[path] = freshData
                        didUpdateStale = true
                    }
                }
            } catch {
                // Ignore revoked or missing path bookmarks
            }
        }

        if didUpdateStale {
            UserDefaults.standard.set(updatedDict, forKey: bookmarkStorageKey)
        }

        cachedBookmarkPaths = Set(updatedDict.keys)
    }

    public func stopAllAccess() {
        for (_, url) in activeSecurityScopedURLs {
            url.stopAccessingSecurityScopedResource()
        }
        activeSecurityScopedURLs.removeAll()
    }

    public func isPathAllowed(_ path: String) -> Bool {
        // Instantaneous O(1) in-memory check without hitting disk / UserDefaults
        if cachedAllowedPaths.contains(path) || cachedBookmarkPaths.contains(path) {
            return true
        }
        let storedPaths = UserDefaults.standard.stringArray(forKey: allowedPathsStorageKey) ?? []
        if storedPaths.contains(path) {
            cachedAllowedPaths.insert(path)
            return true
        }
        let storedDict = UserDefaults.standard.dictionary(forKey: bookmarkStorageKey) as? [String: Data] ?? [:]
        if storedDict[path] != nil {
            cachedBookmarkPaths.insert(path)
            return true
        }
        return false
    }
}
