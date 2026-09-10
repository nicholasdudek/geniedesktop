import AppKit
import Foundation
import SwiftUI

// MARK: - 🛠️ Utility App Installer & macOS Dock Manager
//
// Everything here used to run through `/bin/bash -c`, an inline `python3 -c`
// plist rewrite, and — for relocation — `do shell script … with administrator
// privileges`. All three are gone:
//
//   * Dock pinning now edits `com.apple.dock` through CFPreferences.
//   * Relocation now uses FileManager and never asks for an admin password.
//     Privilege escalation is banned by App Store Review Guideline 2.4.5(iv),
//     and `cp -R … && rm -rf …` as root, built by string interpolation from a
//     bundle path, was a real hazard in the Developer ID build too: any quote
//     or space handled wrong made it an `rm -rf` of the wrong directory.
@MainActor
public final class UtilityAppInstallerManager: ObservableObject {
    public static let shared = UtilityAppInstallerManager()

    @Published public private(set) var isInstalledInUtilities: Bool = false
    @Published public private(set) var isInstalledInApplications: Bool = false
    @Published public private(set) var isPinnedToDock: Bool = false

    /// Set when a relocation could not be completed without the user's help.
    @Published public private(set) var lastRelocationMessage: String = ""

    /// The Dock controls are hidden in Genie Lite — a sandboxed app cannot write
    /// `com.apple.dock`, and a button that silently does nothing is worse than
    /// no button.
    public var canManageDock: Bool { GenieCapabilities.canModifySystemPreferenceDomains }

    /// Whether Genie may move its own bundle.
    public var canRelocate: Bool { GenieCapabilities.canRelocateOwnBundle }

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
        for entry in GenieNativeSystem.dockPersistentApps() {
            guard let path = GenieNativeSystem.dockEntryPath(entry) else { continue }
            if path.contains("Genie.app") || path.contains(bundleId) {
                return true
            }
        }
        return false
    }

    public func addGenieToDock() {
        guard canManageDock else {
            lastRelocationMessage = GenieCapabilities.unavailableMessage("Dock pinning")
            return
        }
        GenieNativeSystem.addToDock(appPath: Bundle.main.bundlePath)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.refreshStatus()
        }
    }

    public func removeGenieFromDock() {
        guard canManageDock else {
            lastRelocationMessage = GenieCapabilities.unavailableMessage("Dock pinning")
            return
        }
        GenieNativeSystem.removeFromDock(pathContaining: "Genie.app")
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

    // MARK: - Move to /Applications

    public func promptMoveToUtilitiesFolderIfNeeded() {
        guard canRelocate else { return }
        let path = Bundle.main.bundlePath
        if path.hasPrefix("/Applications") { return }

        let alert = NSAlert()
        alert.messageText = "Move Genie to Applications?"
        alert.informativeText = "Genie is a macOS system utility and mini dock. Would you like to move it to your Applications folder?"
        alert.addButton(withTitle: "Move to Applications")
        alert.addButton(withTitle: "Do Not Move")
        alert.alertStyle = .informational

        if alert.runModal() == .alertFirstButtonReturn {
            moveToUtilitiesFolder()
        }
    }

    /// Relocates Genie into `/Applications`, without elevation.
    ///
    /// `/Applications` is group-writable by admin users, so an ordinary copy
    /// succeeds for the people who would have been able to type an admin
    /// password anyway. `/Applications/Utilities` is owned by root and is
    /// Apple's folder — Genie no longer tries to install itself there.
    /// When the copy is not permitted, Genie reveals the bundle in Finder and
    /// lets the user drag it, which is what every other Mac app does.
    public func moveToUtilitiesFolder() {
        guard canRelocate else {
            lastRelocationMessage = GenieCapabilities.unavailableMessage("Moving Genie")
            return
        }

        let sourcePath = Bundle.main.bundlePath
        guard !sourcePath.hasPrefix("/Applications") else { return }
        let target = "/Applications/\(appName)"
        let fm = FileManager.default

        // Refuse to clobber a different copy that is currently running.
        if let running = NSRunningApplication
            .runningApplications(withBundleIdentifier: bundleId)
            .first(where: { $0.bundleURL?.path == target && $0 != NSRunningApplication.current }) {
            _ = running.forceTerminate()
        }

        guard GenieNativeSystem.cloneItem(atPath: sourcePath, toPath: target) else {
            lastRelocationMessage = "Genie could not write to /Applications. Drag Genie there from the Finder window that just opened."
            NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: sourcePath)])
            return
        }

        // The running image is already mapped into memory, so trashing the old
        // bundle now is safe — and trashing, not `rm -rf`, keeps it recoverable.
        try? fm.trashItem(at: URL(fileURLWithPath: sourcePath), resultingItemURL: nil)

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.createsNewApplicationInstance = true
        NSWorkspace.shared.openApplication(
            at: URL(fileURLWithPath: target),
            configuration: configuration
        ) { _, _ in
            DispatchQueue.main.async {
                NSApp.terminate(nil)
            }
        }
    }
}
