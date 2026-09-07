import AppKit
import Combine
import Foundation

// MARK: - Chrome Bookmark Data Model
public struct ChromeBookmarkItem: Identifiable, Hashable {
    public let id: String
    public let name: String
    public let url: String
    public let isFolder: Bool
    public let children: [ChromeBookmarkItem]

    public var faviconIcon: String {
        let lower = url.lowercased()
        if lower.contains("github") { return "chevron.left.forwardslash.chevron.right" }
        if lower.contains("google") || lower.contains("gmail") { return "g.circle.fill" }
        if lower.contains("linkedin") { return "person.crop.rectangle.fill" }
        if lower.contains("news") { return "newspaper.fill" }
        if lower.contains("netflix") || lower.contains("youtube") { return "play.rectangle.fill" }
        if lower.contains("apple") { return "applelogo" }
        if lower.contains("chat") || lower.contains("gemini") || lower.contains("openai") { return "sparkles" }
        return isFolder ? "folder.fill" : "globe"
    }
}

// MARK: - Chrome Bookmarks & Integration Manager
public final class ChromeBookmarksManager: ObservableObject {
    public static let shared = ChromeBookmarksManager()

    @Published public var bookmarkBarItems: [ChromeBookmarkItem] = []
    @Published public var otherBookmarks: [ChromeBookmarkItem] = []
    @Published public var isChromeInstalled: Bool = false
    @Published public var lastLoadedDate: Date? = nil

    private init() {
        checkChromeInstallation()
        loadBookmarks()
    }

    public func checkChromeInstallation() {
        let chromeURL = URL(fileURLWithPath: "/Applications/Google Chrome.app")
        let userChromeURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications/Google Chrome.app")
        isChromeInstalled = FileManager.default.fileExists(atPath: chromeURL.path) || FileManager.default.fileExists(atPath: userChromeURL.path)
    }

    /// Primary bookmarks file location for default profile
    public static var defaultBookmarksURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/Google/Chrome/Default/Bookmarks")
    }

    /// Loads and parses the Chrome Bookmarks JSON tree
    public func loadBookmarks() {
        let fileURL = Self.defaultBookmarksURL
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let data = try? Data(contentsOf: fileURL),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let roots = json["roots"] as? [String: Any] else {
                return
            }

            var barItems: [ChromeBookmarkItem] = []
            if let barDict = roots["bookmark_bar"] as? [String: Any],
               let children = barDict["children"] as? [[String: Any]] {
                barItems = children.compactMap { Self.parseNode($0) }
            }

            var otherItems: [ChromeBookmarkItem] = []
            if let otherDict = roots["other"] as? [String: Any],
               let children = otherDict["children"] as? [[String: Any]] {
                otherItems = children.compactMap { Self.parseNode($0) }
            }

            DispatchQueue.main.async {
                self?.bookmarkBarItems = barItems
                self?.otherBookmarks = otherItems
                self?.lastLoadedDate = Date()
            }
        }
    }

    private static func parseNode(_ dict: [String: Any]) -> ChromeBookmarkItem? {
        let name = dict["name"] as? String ?? "Bookmark"
        let id = dict["id"] as? String ?? UUID().uuidString
        let type = dict["type"] as? String ?? "url"

        if type == "folder" {
            let childDicts = dict["children"] as? [[String: Any]] ?? []
            let parsedChildren = childDicts.compactMap { parseNode($0) }
            return ChromeBookmarkItem(
                id: id,
                name: name,
                url: "",
                isFolder: true,
                children: parsedChildren
            )
        } else {
            let url = dict["url"] as? String ?? ""
            return ChromeBookmarkItem(
                id: id,
                name: name,
                url: url,
                isFolder: false,
                children: []
            )
        }
    }

    /// Opens a URL directly in Google Chrome
    public func openInChrome(url: URL) {
        if isChromeInstalled,
           let chromeURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.google.Chrome") {
            NSWorkspace.shared.open([url], withApplicationAt: chromeURL, configuration: NSWorkspace.OpenConfiguration())
        } else {
            NSWorkspace.shared.open(url)
        }
    }

    /// Launches Chrome in standalone borderless application mode (--app)
    public func openChromeAppMode(url: URL) {
        let script = """
        do shell script "open -a '/Applications/Google Chrome.app' --args --app='\(url.absoluteString)'"
        """
        DispatchQueue.global(qos: .userInteractive).async {
            NSAppleScript(source: script)?.executeAndReturnError(nil)
        }
    }
}
