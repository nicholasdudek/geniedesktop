import ServiceManagement
import SwiftUI

/// Manages Launch at Login using SMAppService (macOS 13+)
final class LoginItemManager: ObservableObject {
    static let shared = LoginItemManager()

    @Published var isEnabled: Bool = false

    init() {
        refreshStatus()
    }

    func refreshStatus() {
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
