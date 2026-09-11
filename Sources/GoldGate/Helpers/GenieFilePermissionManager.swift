// MARK: - GenieFilePermissionManager.swift
// Golden Gate Engineering • © 2026 Nicholas M. Dudek
//
// Central authority for User-Managed Granular File Permissions & Restricted Sandbox Execution.
// Enforces Restricted execution by default, replacing unrestricted execution with explicit,
// user-configurable folder grants and protected system boundaries.

import AppKit
import Foundation

// MARK: - 🛡️ User File Permission Grants
public final class GenieFilePermissionManager: ObservableObject, @unchecked Sendable {
    public static let shared = GenieFilePermissionManager()

    private let defaults = UserDefaults.standard
    private let lock = NSLock()

    // Keys
    private let kRestrictedMode = "genie.security.restrictedMode"
    private let kAllowDesktop = "genie.security.allowDesktop"
    private let kAllowDocuments = "genie.security.allowDocuments"
    private let kAllowDownloads = "genie.security.allowDownloads"
    private let kAllowDeveloper = "genie.security.allowDeveloper"
    private let kCustomAllowedPaths = "genie.security.customAllowedPaths"

    // Published Settings
    @Published public var isRestrictedMode: Bool {
        didSet { defaults.set(isRestrictedMode, forKey: kRestrictedMode) }
    }

    @Published public var allowDesktop: Bool {
        didSet { defaults.set(allowDesktop, forKey: kAllowDesktop) }
    }

    @Published public var allowDocuments: Bool {
        didSet { defaults.set(allowDocuments, forKey: kAllowDocuments) }
    }

    @Published public var allowDownloads: Bool {
        didSet { defaults.set(allowDownloads, forKey: kAllowDownloads) }
    }

    @Published public var allowDeveloperProjects: Bool {
        didSet { defaults.set(allowDeveloperProjects, forKey: kAllowDeveloper) }
    }

    @Published public var customAllowedPaths: [String] {
        didSet { defaults.set(customAllowedPaths, forKey: kCustomAllowedPaths) }
    }

    private init() {
        self.isRestrictedMode = defaults.object(forKey: kRestrictedMode) as? Bool ?? true
        self.allowDesktop = defaults.object(forKey: kAllowDesktop) as? Bool ?? true
        self.allowDocuments = defaults.object(forKey: kAllowDocuments) as? Bool ?? false
        self.allowDownloads = defaults.object(forKey: kAllowDownloads) as? Bool ?? false
        self.allowDeveloperProjects = defaults.object(forKey: kAllowDeveloper) as? Bool ?? true
        self.customAllowedPaths = defaults.stringArray(forKey: kCustomAllowedPaths) ?? []
    }

    // MARK: - Always Protected System Paths
    public let blockedSystemPaths: [String] = [
        "/System",
        "/usr",
        "/bin",
        "/sbin",
        "/Library/LaunchDaemons",
        "/Library/LaunchAgents",
        "/private/etc",
        "/Library/Keychains",
        "~/.ssh",
        "~/.aws"
    ]

    // MARK: - Path Resolution & Verification
    public var allAllowedFolderURLs: [URL] {
        lock.lock()
        defer { lock.unlock() }

        var urls: [URL] = []
        let home = FileManager.default.homeDirectoryForCurrentUser

        if allowDesktop {
            urls.append(home.appendingPathComponent("Desktop", isDirectory: true))
        }
        if allowDocuments {
            urls.append(home.appendingPathComponent("Documents", isDirectory: true))
        }
        if allowDownloads {
            urls.append(home.appendingPathComponent("Downloads", isDirectory: true))
        }
        if allowDeveloperProjects {
            let dev = home.appendingPathComponent("Desktop/Developer", isDirectory: true)
            urls.append(dev)
            let altDev = home.appendingPathComponent("Developer", isDirectory: true)
            urls.append(altDev)
        }

        // Always allow Genie's isolated workspace
        urls.append(home.appendingPathComponent("Desktop/Genie/Workspace", isDirectory: true))

        for path in customAllowedPaths {
            let standardized = NSString(string: path).expandingTildeInPath
            urls.append(URL(fileURLWithPath: standardized, isDirectory: true))
        }

        return urls
    }

    public func isPathPermitted(_ path: String) -> Bool {
        let expanded = NSString(string: path).expandingTildeInPath

        // 1. Strictly reject blocked system paths
        for blocked in blockedSystemPaths {
            let expBlocked = NSString(string: blocked).expandingTildeInPath
            if expanded == expBlocked || expanded.hasPrefix(expBlocked + "/") {
                return false
            }
        }

        // 2. If restricted mode is active, only user-approved folders are permitted
        if isRestrictedMode {
            for allowed in allAllowedFolderURLs {
                let allowedPath = allowed.standardizedFileURL.path
                if expanded == allowedPath || expanded.hasPrefix(allowedPath + "/") {
                    return true
                }
            }
            // Process temporary directories
            let tmp = URL(fileURLWithPath: "/tmp").resolvingSymlinksInPath().path
            let userTmp = URL(fileURLWithPath: NSTemporaryDirectory()).resolvingSymlinksInPath().path
            if expanded.hasPrefix(tmp) || expanded.hasPrefix(userTmp) {
                return true
            }
            return false
        }

        return true
    }

    // MARK: - Folder Management
    public func addCustomFolder() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Select Folder for Genie AI Access"
        openPanel.canChooseFiles = false
        openPanel.canChooseDirectories = true
        openPanel.allowsMultipleSelection = false
        openPanel.canCreateDirectories = true

        if openPanel.runModal() == .OK, let selectedURL = openPanel.url {
            let path = selectedURL.path
            lock.lock()
            if !customAllowedPaths.contains(path) {
                customAllowedPaths.append(path)
            }
            lock.unlock()
        }
    }

    public func removeCustomFolder(at index: Int) {
        lock.lock()
        guard index >= 0 && index < customAllowedPaths.count else {
            lock.unlock()
            return
        }
        customAllowedPaths.remove(at: index)
        lock.unlock()
    }
}
