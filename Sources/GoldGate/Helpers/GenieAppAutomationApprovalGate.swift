import AppKit

/// Gate in front of Genie's app-automation tools (AppleScript and the Antigravity
/// desktop-control script). The user approves a given app once per session; after
/// that, Genie may automate it again without re-prompting.
@MainActor
public final class GenieAppAutomationApprovalGate {
    public static let shared = GenieAppAutomationApprovalGate()

    private var approvedApps: Set<String> = []

    private init() {}

    /// Shows a confirmation alert the first time Genie automates `appName` in this
    /// session. Returns whether Genie may proceed.
    public func requestApproval(for appName: String, action: String) -> Bool {
        if approvedApps.contains(appName) { return true }

        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "Let Genie automate \(appName)?"
        alert.informativeText = "Genie wants to \(action) in \(appName). Allowing this lets Genie read, write, and control \(appName) for the rest of this session."
        alert.addButton(withTitle: "Allow")
        alert.addButton(withTitle: "Deny")

        let approved = alert.runModal() == .alertFirstButtonReturn
        if approved { approvedApps.insert(appName) }
        return approved
    }
}
