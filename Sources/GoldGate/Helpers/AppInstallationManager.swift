import AppKit
import Foundation
import SwiftUI

// MARK: - App Installation & DMG Relocation Manager
// Ensures Genie operates smoothly as a Drop-Down Menu Bar Application, with:
// 1. One-click Dock Icon installation & toggle (Accessory vs Regular activation policy).
// 2. Automated detection of DMG / Downloads volume execution and seamless Move to Applications.
// 3. User-chosen custom Applications directory destination support.
// 4. Permanent Menu Bar Dropdown anchor synchronization.
@MainActor
public final class AppInstallationManager: ObservableObject {
    public static let shared = AppInstallationManager()

    @AppStorage(PrefKey.appVisibilityMode) public var appVisibilityMode: String = "Menu Bar & Dock Icon"
    @AppStorage(PrefKey.hasPromptedAppMove) public var hasPromptedAppMove: Bool = false
    @Published public private(set) var isRunningFromApplications: Bool = true
    @Published public private(set) var isRunningFromDMG: Bool = false

    private init() {
        checkAppLocation()
        applyActivationPolicy()
    }

    // MARK: - Location Inspection
    public func checkAppLocation() {
        let bundlePath = Bundle.main.bundlePath
        let isDMG = bundlePath.hasPrefix("/Volumes/")
        let isInSystemApps = bundlePath.hasPrefix("/Applications/")
        let isInUserApps = bundlePath.hasPrefix(NSHomeDirectory() + "/Applications/")
        
        self.isRunningFromDMG = isDMG
        self.isRunningFromApplications = isInSystemApps || isInUserApps
    }

    // MARK: - Activation Policy (Menu Bar vs Dock)
    public func applyActivationPolicy() {
        switch appVisibilityMode {
        case "Menu Bar Only (No Dock Icon)":
            NSApp.setActivationPolicy(.accessory)
        case "Dock Only":
            NSApp.setActivationPolicy(.regular)
        default: // "Menu Bar & Dock Icon"
            NSApp.setActivationPolicy(.regular)
        }
    }

    public func setVisibilityMode(_ mode: String) {
        appVisibilityMode = mode
        UserDefaults.standard.set(mode, forKey: PrefKey.appVisibilityMode)
        applyActivationPolicy()
        HapticFeedback.selection()
    }

    // MARK: - Move to Applications Prompt (DMG Drag-to-Install Helper)
    public func promptMoveToApplicationsIfNeeded() {
        checkAppLocation()
        let isDevBuild = Bundle.main.bundlePath.contains("/.build/") || Bundle.main.bundlePath.contains("/DerivedData/")
        guard !isDevBuild, !isRunningFromApplications, !hasPromptedAppMove else { return }

        // Give user time to see the app load first
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            guard let self = self else { return }
            self.showMoveAlert()
        }
    }

    public func showMoveAlert() {
        let alert = NSAlert()
        alert.messageText = LocalizedStrings.translateText("Move Genie to Applications Folder?", lang: UserDefaults.standard.string(forKey: PrefKey.appLanguage) ?? "English (US)")
        alert.informativeText = LocalizedStrings.translateText("Genie runs best when installed in your Applications folder. Would you like to move it now, or choose a custom Applications directory?", lang: UserDefaults.standard.string(forKey: PrefKey.appLanguage) ?? "English (US)")
        alert.alertStyle = .informational
        alert.addButton(withTitle: LocalizedStrings.translateText("Move to Applications", lang: UserDefaults.standard.string(forKey: PrefKey.appLanguage) ?? "English (US)"))
        alert.addButton(withTitle: LocalizedStrings.translateText("Choose Directory...", lang: UserDefaults.standard.string(forKey: PrefKey.appLanguage) ?? "English (US)"))
        alert.addButton(withTitle: LocalizedStrings.translateText("Keep in Current Location", lang: UserDefaults.standard.string(forKey: PrefKey.appLanguage) ?? "English (US)"))

        let response = alert.runModal()
        hasPromptedAppMove = true
        UserDefaults.standard.set(true, forKey: PrefKey.hasPromptedAppMove)

        if response == .alertFirstButtonReturn {
            // Move to /Applications
            moveSelf(toDirectory: URL(fileURLWithPath: "/Applications"))
        } else if response == .alertSecondButtonReturn {
            // User chooses destination folder
            chooseCustomApplicationsFolder()
        }
    }

    public func chooseCustomApplicationsFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.title = "Select Applications Directory for Genie"
        panel.prompt = "Install Here"

        if panel.runModal() == .OK, let targetDir = panel.url {
            moveSelf(toDirectory: targetDir)
        }
    }

    private func moveSelf(toDirectory destinationDir: URL) {
        let currentBundleURL = Bundle.main.bundleURL
        let appName = currentBundleURL.lastPathComponent
        let targetURL = destinationDir.appendingPathComponent(appName)

        do {
            let fm = FileManager.default
            if fm.fileExists(atPath: targetURL.path) {
                try fm.removeItem(at: targetURL)
            }
            try fm.copyItem(at: currentBundleURL, to: targetURL)

            // Launch the new copy
            let config = NSWorkspace.OpenConfiguration()
            config.activates = true
            NSWorkspace.shared.openApplication(at: targetURL, configuration: config) { _, error in
                if error == nil {
                    DispatchQueue.main.async {
                        NSApp.terminate(nil)
                    }
                }
            }
        } catch {
            print("[AppInstallationManager] Failed to copy app: \(error)")
            let errAlert = NSAlert(error: error)
            errAlert.runModal()
        }
    }
}
