import AppKit
import Foundation
import SwiftUI

// MARK: - 🛠️ Utility App Installer & macOS Dock Manager
@MainActor
public final class UtilityAppInstallerManager: ObservableObject {
    public static let shared = UtilityAppInstallerManager()

    @Published public private(set) var isInstalledInUtilities: Bool = false
    @Published public private(set) var isInstalledInApplications: Bool = false
    @Published public private(set) var isPinnedToDock: Bool = false

    private let bundleId = Bundle.main.bundleIdentifier ?? "com.nicholasdudek.genie"
    private let appName = "Genie.app"

    private init() {
        refreshStatus()
    }

    public func refreshStatus() {
        let bundlePath = Bundle.main.bundlePath
        isInstalledInUtilities = bundlePath.hasPrefix("/Applications/Utilities")
        isInstalledInApplications = bundlePath.hasPrefix("/Applications")
        isPinnedToDock = checkIsPinnedToDock()
    }

    // MARK: - Dock Status & Automation
    public func checkIsPinnedToDock() -> Bool {
        guard let persistentApps = UserDefaults(suiteName: "com.apple.dock")?.array(forKey: "persistent-apps") as? [[String: Any]] else {
            return false
        }
        for app in persistentApps {
            if let tileData = app["tile-data"] as? [String: Any],
               let fileData = tileData["file-data"] as? [String: Any],
               let urlString = fileData["_CFURLString"] as? String {
                if urlString.contains("Genie.app") || urlString.contains(bundleId) {
                    return true
                }
            }
        }
        return false
    }

    public func addGenieToDock() {
        let appPath = Bundle.main.bundlePath
        let script = """
        defaults write com.apple.dock persistent-apps -array-add '<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>\(appPath)</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>'
        killall Dock
        """
        runShell(script)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.refreshStatus()
        }
    }

    public func removeGenieFromDock() {
        let cleanScript = """
        python3 -c "import plistlib, os, subprocess; p = os.path.expanduser('~/Library/Preferences/com.apple.dock.plist'); f = open(p, 'rb'); d = plistlib.load(f); f.close(); d['persistent-apps'] = [a for a in d.get('persistent-apps', []) if 'Genie.app' not in str(a)]; f = open(p, 'wb'); plistlib.dump(d, f); f.close(); subprocess.run(['killall', 'Dock'])"
        """
        runShell(cleanScript)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.refreshStatus()
        }
    }

    public func toggleDockPinning() {
        if isPinnedToDock {
            removeGenieFromDock()
        } else {
            addGenieToDock()
        }
    }

    // MARK: - Move to /Applications/Utilities
    public func promptMoveToUtilitiesFolderIfNeeded() {
        let path = Bundle.main.bundlePath
        if path.contains("/Applications") { return }

        let alert = NSAlert()
        alert.messageText = "Move Genie to Utilities?"
        alert.informativeText = "Genie is a macOS system utility and mini dock. Would you like to move it to your Applications / Utilities folder?"
        alert.addButton(withTitle: "Move to Applications / Utilities")
        alert.addButton(withTitle: "Do Not Move")
        alert.alertStyle = .informational

        if alert.runModal() == .alertFirstButtonReturn {
            moveToUtilitiesFolder()
        }
    }

    public func moveToUtilitiesFolder() {
        let sourcePath = Bundle.main.bundlePath
        let utilitiesTarget = "/Applications/Utilities/\(appName)"
        let appsTarget = "/Applications/\(appName)"

        let target = FileManager.default.fileExists(atPath: "/Applications/Utilities") ? utilitiesTarget : appsTarget

        let script = """
        do shell script "cp -R '\(sourcePath)' '\(target)' && rm -rf '\(sourcePath)'" with administrator privileges
        """

        if let appleScript = NSAppleScript(source: script) {
            var errorInfo: NSDictionary?
            appleScript.executeAndReturnError(&errorInfo)
            if errorInfo == nil {
                NSWorkspace.shared.open(URL(fileURLWithPath: target))
                NSApp.terminate(nil)
            }
        }
    }

    @discardableResult
    private func runShell(_ command: String) -> String {
        let process = Process()
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        process.arguments = ["-c", command]
        process.executableURL = URL(fileURLWithPath: "/bin/bash")
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            return ""
        }
    }
}
