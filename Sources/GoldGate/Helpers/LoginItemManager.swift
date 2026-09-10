import ServiceManagement
import SwiftUI

/// Manages Launch at Login using SMAppService (macOS 13+)
final class LoginItemManager: ObservableObject {
    static let shared = LoginItemManager()

    @Published var isEnabled: Bool = false

    /// Guard to ensure we only register packaged macOS application bundles (.app)
    /// Raw terminal/debug binaries (e.g. .build/out/Products/Debug/Genie) must NEVER be registered,
    /// because macOS will open Terminal windows upon login to execute them.
    public var isEligibleForSystemRegistration: Bool {
        let bundleURL = Bundle.main.bundleURL
        let path = bundleURL.path
        guard bundleURL.pathExtension == "app" else { return false }
        guard !path.contains("/.build/") && !path.contains("/DerivedData/") else { return false }
        return true
    }

    init() {
        cleanupRogueLoginItems()
        refreshStatus()
    }

    /// Automatically cleans up any lingering debug or unbundled binaries from macOS Login Items
    public func cleanupRogueLoginItems() {
        let script = """
        tell application "System Events"
            try
                repeat with i from (count of login items) to 1 by -1
                    set anItem to login item i
                    set itemName to ""
                    set itemPath to ""
                    try
                        set itemName to name of anItem
                    end try
                    try
                        set itemPath to (path of anItem as string)
                    end try
                    if itemName is "GoldGate" or itemPath contains ".build" or itemPath contains "DerivedData" or itemPath is "missing value" or itemPath is "" then
                        delete anItem
                    else if itemName is "Genie" and (not (itemPath ends with ".app")) then
                        delete anItem
                    end if
                end repeat
            end try
        end tell
        """
        DispatchQueue.global(qos: .utility).async {
            var error: NSDictionary?
            if let appleScript = NSAppleScript(source: script) {
                appleScript.executeAndReturnError(&error)
            }
        }
    }

    func refreshStatus() {
        guard isEligibleForSystemRegistration else {
            isEnabled = false
            return
        }

        if #available(macOS 13.0, *) {
            let status = SMAppService.mainApp.status
            if status == .enabled {
                isEnabled = true
            } else {
                isEnabled = UserDefaults.standard.bool(forKey: PrefKey.launchAtLogin)
            }
        } else {
            isEnabled = UserDefaults.standard.bool(forKey: PrefKey.launchAtLogin)
        }
    }

    func setEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: PrefKey.launchAtLogin)
        UserDefaults.standard.synchronize()

        guard isEligibleForSystemRegistration else {
            print("[LoginItemManager] Skipping system login item registration: app is running unbundled or in debug mode (\(Bundle.main.bundlePath)).")
            isEnabled = enabled
            return
        }

        if #available(macOS 13.0, *) {
            do {
                if enabled {
                    if SMAppService.mainApp.status != .enabled {
                        try SMAppService.mainApp.register()
                    }
                } else {
                    if SMAppService.mainApp.status == .enabled {
                        try SMAppService.mainApp.unregister()
                    }
                }
                isEnabled = (SMAppService.mainApp.status == .enabled)
            } catch {
                // Graceful fallback: "if its not possible skip it"
                print("[LoginItemManager] SMAppService registration notice: \(error.localizedDescription) — skipped registering system login item (running unbundled/dev mode or restricted).")
                isEnabled = enabled
            }
        } else {
            isEnabled = enabled
        }
    }

    func toggle() {
        setEnabled(!isEnabled)
    }
}
