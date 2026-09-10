import AppKit
import SwiftUI

final class DesktopFilesManager: ObservableObject {
    static let shared = DesktopFilesManager()

    @Published var areDesktopFilesVisible: Bool = true

    init() {
        checkCurrentStatus()
    }

    func checkCurrentStatus() {
        if let finderDefaults = UserDefaults(suiteName: "com.apple.finder") {
            let val = finderDefaults.object(forKey: "CreateDesktop")
            if let boolVal = val as? Bool {
                self.areDesktopFilesVisible = boolVal
                UserDefaults.standard.set(boolVal, forKey: PrefKey.areDesktopFilesVisible)
                return
            } else if let numVal = val as? NSNumber {
                self.areDesktopFilesVisible = numVal.boolValue
                UserDefaults.standard.set(numVal.boolValue, forKey: PrefKey.areDesktopFilesVisible)
                return
            }
        }
        if let val = UserDefaults.standard.object(forKey: PrefKey.areDesktopFilesVisible) as? Bool {
            self.areDesktopFilesVisible = val
        } else {
            self.areDesktopFilesVisible = true
        }
    }

    func setDesktopFilesVisible(_ visible: Bool) {
        // 1. Instant UI update (0 ms)
        self.areDesktopFilesVisible = visible
        UserDefaults.standard.set(visible, forKey: PrefKey.areDesktopFilesVisible)
        NotificationCenter.default.post(name: NSNotification.Name("NexusDesktopFilesToggled"), object: visible)

        // 2. Write CFPreferences for Finder
        CFPreferencesSetAppValue("CreateDesktop" as CFString, (visible ? kCFBooleanTrue : kCFBooleanFalse), "com.apple.finder" as CFString)
        CFPreferencesAppSynchronize("com.apple.finder" as CFString)

        // 3. Refresh Finder so the change takes effect.
        // The `defaults write` that used to run here was a duplicate of the
        // CFPreferences write in step 2, and `killall Finder` is just a
        // forced terminate — Finder is relaunched by launchd either way.
        DispatchQueue.global(qos: .userInitiated).async {
            GenieNativeSystem.restartFinder()
        }
    }

    func toggleDesktopFiles() {
        setDesktopFilesVisible(!areDesktopFilesVisible)
    }

    // MARK: - Desktop Files & Folders Retrieval
    func fetchDesktopItems() -> (folders: [URL], files: [URL]) {
        let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first ?? URL(fileURLWithPath: NSHomeDirectory() + "/Desktop")
        Task { @MainActor in
            _ = SecurityBookmarkManager.shared.saveBookmark(for: desktopURL)
        }
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: desktopURL,
            includingPropertiesForKeys: [.isDirectoryKey, .isPackageKey],
            options: [.skipsHiddenFiles]
        ) else {
            return ([], [])
        }

        var folders: [URL] = []
        var files: [URL] = []

        for url in contents {
            let name = url.lastPathComponent
            if name.hasPrefix(".") { continue }
            let vals = try? url.resourceValues(forKeys: [.isDirectoryKey, .isPackageKey])
            let isDir = vals?.isDirectory ?? false
            let isPkg = vals?.isPackage ?? false
            if isDir && !isPkg {
                folders.append(url)
            } else {
                files.append(url)
            }
        }

        folders.sort { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
        files.sort { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
        return (folders, files)
    }

    func scanDesktop() {
        _ = fetchDesktopItems()
    }
}

