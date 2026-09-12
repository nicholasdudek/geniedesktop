import AppKit
import Foundation
import Observation
import Carbon.HIToolbox

// MARK: - 📋 Genie Shared Clipboard & Auto-Paste Engine
/// Bridges the clipboard bidirectionally between Genie, macOS, and iOS Simulators:
/// 1. Copy to User: Places content onto the Mac NSPasteboard.general and syncs to iOS Simulator via simctl.
/// 2. Direct Paste to User: Injects synthetic Cmd+V (CGEvent) into the user's currently active application.
/// 3. Continuity Universal Clipboard: Prepares pasteboard payloads so physical iPhones receive them via Handoff.
/// 4. Auto-Copy Pipeline: Seamlessly hooks into code generation, file writing, and tool loop completions.
@available(macOS 13.0, *)
@Observable
public final class GenieSharedClipboardEngine: @unchecked Sendable {
    public static let shared = GenieSharedClipboardEngine()

    public enum ClipboardFormat: String, Sendable {
        case plainText
        case html
        case sourceCode
    }

    // ── Observable State ───────────────────────────────────────────────────
    public private(set) var lastCopiedContent: String = ""
    public private(set) var lastCopiedTimestamp: Date?
    public private(set) var changeCount: Int = 0
    public private(set) var isSimulatorSyncEnabled: Bool = true
    public private(set) var lastSyncStatus: String = "Ready"

    private let lock = NSLock()

    private init() {
        self.changeCount = NSPasteboard.general.changeCount
    }

    // MARK: - 1. Copy to User (Mac + iOS Simulator + Continuity)
    /// Places content on the shared system pasteboard and syncs to the booted iOS simulator.
    @discardableResult
    @MainActor
    public func copyToUser(_ text: String, format: ClipboardFormat = .plainText, syncToSimulator: Bool = true) -> Bool {
        guard !text.isEmpty else { return false }

        let pb = NSPasteboard.general
        pb.clearContents()

        var success = false
        switch format {
        case .plainText, .sourceCode:
            success = pb.setString(text, forType: .string)
        case .html:
            pb.setString(text, forType: .html)
            success = pb.setString(text, forType: .string)
        }

        if success {
            self.lastCopiedContent = text
            self.lastCopiedTimestamp = Date()
            self.changeCount = pb.changeCount
            self.lastSyncStatus = "Copied \(text.count) chars to macOS Clipboard"

            HapticFeedback.selection()

            // Synchronize with active iOS Simulator in background
            if syncToSimulator && isSimulatorSyncEnabled {
                Task.detached(priority: .utility) {
                    await self.syncWithSimulator(text: text)
                }
            }
        }

        return success
    }

    // MARK: - 2. Paste Directly into User's Active Application (Synthetic Cmd+V)
    /// Synthesizes a hardware Cmd+V key event to paste clipboard contents into the currently focused window.
    @MainActor
    public func pasteToUserActiveApp(delaySeconds: Double = 0.05) async {
        if delaySeconds > 0 {
            try? await Task.sleep(nanoseconds: UInt64(delaySeconds * 1_000_000_000))
        }

        // 1. Source the CGEvent for 'V' with Command modifier
        let vKeyCode: CGKeyCode = 0x09 // Virtual key code for 'V'
        guard let source = CGEventSource(stateID: .combinedSessionState) else {
            print("[SharedClipboard] ⚠️ Could not create CGEventSource.")
            return
        }

        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: vKeyCode, keyDown: false)

        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand

        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)

        HapticFeedback.selection()
        self.lastSyncStatus = "Injected Cmd+V Paste into active application"
    }

    // MARK: - 3. Copy AND Paste into Active App
    /// Convenience: loads content onto clipboard, then immediately pastes into user's cursor position.
    @MainActor
    public func copyAndPasteToUser(_ text: String, format: ClipboardFormat = .plainText) async {
        copyToUser(text, format: format)
        await pasteToUserActiveApp(delaySeconds: 0.08)
    }

    // MARK: - 4. Read from User Clipboard
    @MainActor
    public func readFromUser() -> String? {
        let pb = NSPasteboard.general
        return pb.string(forType: .string)
    }

    // MARK: - 5. iOS Simulator Sync via xcrun simctl
    private func syncWithSimulator(text: String) async {
        guard GenieCapabilities.canSpawnSubprocesses else { return }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        process.arguments = ["simctl", "pbcopy", "booted"]

        let pipe = Pipe()
        process.standardInput = pipe

        do {
            try process.run()
            if let data = text.data(using: .utf8) {
                pipe.fileHandleForWriting.write(data)
                try? pipe.fileHandleForWriting.close()
            }
            process.waitUntilExit()

            Task { @MainActor in
                if process.terminationStatus == 0 {
                    self.lastSyncStatus = "Synced to Mac & Booted iOS Simulator"
                }
            }
        } catch {
            // Simulator might not be booted; ignore gracefully
        }
    }
}
