import Foundation
import AppKit

/// Single source of truth for what this *build* of Genie is allowed to do.
///
/// Genie ships in two flavours from one codebase:
///
/// * **Developer ID** (default) — direct distribution, not sandboxed, Hardened
///   Runtime on, notarized. Every subsystem is available.
/// * **Genie Lite** (`-DGENIE_MAS`) — Mac App Store, sandboxed. The subsystems
///   with no sandbox-legal equivalent are compiled out.
///
/// Anything gated here is gated because the App Store sandbox or the
/// App Store Review Guidelines forbid it — *not* because it is merely awkward.
/// Where a sandbox-legal equivalent exists, Genie Lite keeps the feature and
/// uses the equivalent instead of losing it. See `GenieNativeSystem` below.
public enum GenieCapabilities {

    #if GENIE_MAS
    /// True when built for the Mac App Store (sandboxed "Genie Lite").
    public static let isAppStoreBuild = true
    #else
    public static let isAppStoreBuild = false
    #endif

    public static var distributionChannel: String {
        isAppStoreBuild ? "Mac App Store (Genie Lite)" : "Developer ID"
    }

    /// A literal that exists in the compiled binary for exactly one flavour, so
    /// the packaging scripts can prove which build they are about to sign
    /// (`strings Genie | grep GENIE-BUILD-FLAVOUR`). Shipping a Developer ID
    /// binary to App Store Connect — or the reverse — is otherwise invisible
    /// until review rejects it.
    #if GENIE_MAS
    public static let buildMarker = "GENIE-BUILD-FLAVOUR:MAS"
    #else
    public static let buildMarker = "GENIE-BUILD-FLAVOUR:DEVELOPER-ID"
    #endif

    // MARK: - Retained under the sandbox
    //
    // These are gated by TCC, not by the sandbox. A sandboxed App Store app can
    // hold every one of them once the user grants it in System Settings, so
    // Genie Lite keeps these features in full.

    /// Accessibility API window control (tiling, warping, the spatial grid).
    /// TCC-gated, not sandbox-gated — Magnet and Moom ship this way on the MAS.
    public static let canControlWindows = true

    /// ScreenCaptureKit capture. Sandbox-legal with the Screen Recording grant.
    public static let canRecordScreen = true

    /// Apple Events to the apps enumerated in
    /// `com.apple.security.temporary-exception.apple-events`.
    public static let canSendAppleEvents = true

    /// Camera capture. Requires `com.apple.security.device.camera`, which the
    /// App Store profile now declares.
    public static let canUseCamera = true

    // MARK: - Forbidden under the sandbox

    /// Spawning executables outside the app bundle (`/bin/zsh`, `sqlite3`,
    /// `defaults`, `git`…). Sandboxed children inherit the sandbox and system
    /// binaries are unreachable; App Store Review Guideline 2.5.1 also forbids it.
    /// Genie Lite routes these through `GenieNativeSystem` instead.
    public static let canSpawnSubprocesses = !isAppStoreBuild

    /// `do shell script … with administrator privileges`.
    /// Privilege escalation — Guideline 2.4.5(iv). No App Store equivalent.
    public static let canElevatePrivileges = !isAppStoreBuild

    /// Downloading and running executable code (the Ollama installer).
    /// Guideline 2.5.2. No App Store equivalent — Genie Lite links out instead.
    public static let canInstallExternalRuntimes = !isAppStoreBuild

    /// Full Disk Access. Not grantable to a sandboxed app; Genie Lite uses
    /// user-selected scope plus security-scoped bookmarks.
    public static let canRequestFullDiskAccess = !isAppStoreBuild

    /// Reading another app's container directly (Chrome bookmarks, Messages DB).
    public static let canReadForeignAppContainers = !isAppStoreBuild

    /// Arbitrary absolute paths outside the container (`/Users/Shared/Genie/…`).
    public static let canWriteOutsideContainer = !isAppStoreBuild

    /// Writing *another* application's preference domain — `com.apple.dock`
    /// (pinning tiles), `com.apple.finder` (desktop icon visibility),
    /// `-globalDomain` (appearance). A sandboxed app may only write its own
    /// domain, so these writes fail silently under the sandbox rather than
    /// erroring; Genie Lite hides the controls instead of showing dead ones.
    public static let canModifySystemPreferenceDomains = !isAppStoreBuild

    /// Relocating Genie's own bundle on disk. The App Store installs Genie into
    /// `/Applications` itself, so Genie Lite never needs — and is never allowed —
    /// to move itself.
    public static let canRelocateOwnBundle = !isAppStoreBuild

    // MARK: - Container-safe paths

    /// Genie's shared working directory.
    ///
    /// Developer ID keeps the historical `/Users/Shared/Genie`. Under the
    /// sandbox that path is unwritable, so Genie Lite redirects into the
    /// App Group container, which is the sanctioned equivalent.
    public static var sharedSupportDirectory: URL {
        if canWriteOutsideContainer {
            return URL(fileURLWithPath: "/Users/Shared/Genie", isDirectory: true)
        }
        let group = "group.com.nicholasdudek.genie"
        if let container = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: group) {
            return container.appendingPathComponent("Genie", isDirectory: true)
        }
        return FileManager.default
            .urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("Genie", isDirectory: true)
    }

    /// Explains, in user-facing words, why a gated feature is unavailable.
    public static func unavailableMessage(_ feature: String) -> String {
        "\(feature) is not supported under macOS App Sandbox security restrictions."
    }
}

/// Native replacements for things Genie used to shell out for.
///
/// These are not App Store workarounds only — they are faster, synchronous, and
/// don't depend on binaries existing at a fixed path, so the Developer ID build
/// uses them too. Each one replaces a `Process()` call site.
public enum GenieNativeSystem {

    /// Replaces `/usr/bin/killall <name>`.
    /// `NSRunningApplication.terminate()` is sandbox-legal and asks politely
    /// first, which `killall` never did.
    @discardableResult
    public static func quitApplication(bundleIdentifier: String, force: Bool = false) -> Bool {
        let running = NSRunningApplication
            .runningApplications(withBundleIdentifier: bundleIdentifier)
        guard !running.isEmpty else { return false }
        var allSucceeded = true
        for app in running {
            let ok = force ? app.forceTerminate() : app.terminate()
            if !ok { allSucceeded = false }
        }
        return allSucceeded
    }

    /// Replaces `/usr/bin/killall <localizedName>` where only a display name is known.
    @discardableResult
    public static func quitApplication(named name: String, force: Bool = false) -> Bool {
        let matches = NSWorkspace.shared.runningApplications.filter {
            $0.localizedName == name
        }
        guard !matches.isEmpty else { return false }
        var allSucceeded = true
        for app in matches {
            let ok = force ? app.forceTerminate() : app.terminate()
            if !ok { allSucceeded = false }
        }
        return allSucceeded
    }

    /// Replaces `/usr/bin/defaults read <domain> <key>`.
    /// Reading another app's domain still requires that domain to be readable;
    /// under the sandbox this returns nil rather than failing loudly.
    public static func readPreference(domain: String, key: String) -> Any? {
        CFPreferencesCopyAppValue(key as CFString, domain as CFString)
    }

    /// Replaces `/usr/bin/defaults write <domain> <key> <value>`.
    @discardableResult
    public static func writePreference(domain: String, key: String, value: Any?) -> Bool {
        CFPreferencesSetAppValue(key as CFString, value as CFPropertyList?, domain as CFString)
        return CFPreferencesAppSynchronize(domain as CFString)
    }

    /// Replaces `/usr/bin/open <path>` and `/usr/bin/open -a <app>`.
    @discardableResult
    public static func open(_ url: URL) -> Bool {
        NSWorkspace.shared.open(url)
    }

    /// Replaces `/usr/bin/open <https url>` for links Genie shows the user.
    @discardableResult
    public static func openExternal(_ string: String) -> Bool {
        guard let url = URL(string: string) else { return false }
        return NSWorkspace.shared.open(url)
    }

    /// Replaces `/usr/bin/open -a <name>`.
    /// Resolves a display name to a bundle URL through LaunchServices and the
    /// standard application directories, then launches it.
    @discardableResult
    public static func launchApplication(named name: String) -> Bool {
        let bare = name.hasSuffix(".app") ? String(name.dropLast(4)) : name

        // Already running: just bring it forward.
        if let running = NSWorkspace.shared.runningApplications
            .first(where: { $0.localizedName == bare }) {
            return running.activate()
        }

        let searchRoots = [
            "/Applications",
            "/Applications/Utilities",
            "/System/Applications",
            "/System/Applications/Utilities",
            NSHomeDirectory() + "/Applications"
        ]
        for root in searchRoots {
            let candidate = root + "/" + bare + ".app"
            if FileManager.default.fileExists(atPath: candidate) {
                NSWorkspace.shared.openApplication(
                    at: URL(fileURLWithPath: candidate),
                    configuration: NSWorkspace.OpenConfiguration()
                )
                return true
            }
        }
        return false
    }

    /// Replaces `/bin/cp -c -R src dst`.
    /// `FileManager.copyItem` already performs an APFS clone when both paths are
    /// on the same APFS volume, so this is the same copy without the subprocess.
    @discardableResult
    public static func cloneItem(atPath source: String, toPath destination: String) -> Bool {
        let fm = FileManager.default
        do {
            if fm.fileExists(atPath: destination) {
                try fm.removeItem(atPath: destination)
            }
            try fm.copyItem(atPath: source, toPath: destination)
            return true
        } catch {
            return false
        }
    }

    // MARK: - Dock and Finder

    /// Replaces `killall Dock`. The Dock is relaunched automatically by launchd.
    /// `forceTerminate` is used deliberately: the Dock ignores a polite quit
    /// Apple Event, so `terminate()` would silently do nothing.
    @discardableResult
    public static func restartDock() -> Bool {
        quitApplication(bundleIdentifier: "com.apple.dock", force: true)
    }

    /// Replaces `killall Finder`.
    @discardableResult
    public static func restartFinder() -> Bool {
        quitApplication(bundleIdentifier: "com.apple.finder", force: true)
    }

    private static let dockDomain = "com.apple.dock" as CFString
    private static let dockPersistentAppsKey = "persistent-apps" as CFString

    /// The Dock's pinned-app list, read without shelling out to `defaults`.
    public static func dockPersistentApps() -> [[String: Any]] {
        CFPreferencesCopyAppValue(dockPersistentAppsKey, dockDomain)
            as? [[String: Any]] ?? []
    }

    /// The file path a `persistent-apps` entry points at, if it has one.
    public static func dockEntryPath(_ entry: [String: Any]) -> String? {
        guard let tileData = entry["tile-data"] as? [String: Any],
              let fileData = tileData["file-data"] as? [String: Any],
              let raw = fileData["_CFURLString"] as? String else { return nil }
        if raw.hasPrefix("file://") {
            return URL(string: raw)?.path
        }
        return raw
    }

    @discardableResult
    private static func writeDockPersistentApps(_ apps: [[String: Any]]) -> Bool {
        CFPreferencesSetAppValue(dockPersistentAppsKey, apps as CFArray, dockDomain)
        return CFPreferencesAppSynchronize(dockDomain)
    }

    /// Replaces the whole `persistent-apps` array and restarts the Dock so the
    /// change takes effect. Returns false if the preference write was refused
    /// (which is what happens under the sandbox).
    @discardableResult
    public static func setDockPersistentApps(_ apps: [[String: Any]]) -> Bool {
        guard writeDockPersistentApps(apps) else { return false }
        return restartDock()
    }

    /// Replaces `defaults write com.apple.dock persistent-apps -array-add '<dict>…'`.
    /// Idempotent — pinning an already-pinned app is a no-op rather than a duplicate tile.
    @discardableResult
    public static func addToDock(appPath: String) -> Bool {
        let target = URL(fileURLWithPath: appPath).standardizedFileURL.path
        var apps = dockPersistentApps()
        if apps.contains(where: { dockEntryPath($0) == target }) {
            return true
        }
        let entry: [String: Any] = [
            "tile-type": "file-tile",
            "tile-data": [
                "file-data": [
                    "_CFURLString": target,
                    "_CFURLStringType": 0
                ]
            ]
        ]
        apps.append(entry)
        guard writeDockPersistentApps(apps) else { return false }
        return restartDock()
    }

    /// Replaces the inline `python3 -c "import plistlib…"` Dock surgery.
    /// `matching` is compared against each tile's path.
    @discardableResult
    public static func removeFromDock(pathContaining needle: String) -> Bool {
        let apps = dockPersistentApps()
        let kept = apps.filter { entry in
            guard let path = dockEntryPath(entry) else { return true }
            return !path.contains(needle)
        }
        guard kept.count != apps.count else { return true }
        guard writeDockPersistentApps(kept) else { return false }
        return restartDock()
    }
}
