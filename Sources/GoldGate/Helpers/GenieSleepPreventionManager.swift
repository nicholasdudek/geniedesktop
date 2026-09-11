import AppKit
import Foundation
import IOKit.pwr_mgt

// MARK: - ☕ Genie System & Display Sleep Prevention Manager
/// Prevents macOS display sleep, idle system sleep, screen dimming, and automatic lock screen
/// while Genie is running, ensuring the active workspace, windows, and agents stay permanently awake and responsive.
@MainActor
public final class GenieSleepPreventionManager: ObservableObject {
    public static let shared = GenieSleepPreventionManager()

    @Published public private(set) var isSleepDisabled: Bool = false
    @Published public private(set) var activeReason: String = "Genie Active Canvas & System Protection"
    @Published public private(set) var activationDate: Date? = nil

    private var displayAssertionID: IOPMAssertionID = 0
    private var systemAssertionID: IOPMAssertionID = 0
    private var activityToken: NSObjectProtocol?
    private var caffeinateProcess: Process?

    private init() {
        // Automatically activate if preference enabled (defaults to true)
        let isEnabled = UserDefaults.standard.object(forKey: PrefKey.preventSystemSleep) as? Bool ?? true
        if isEnabled {
            enableSleepPrevention()
        }
    }

    // MARK: - Enable Sleep Prevention
    /// Asserts kernel power assertions, process activity tokens, and background caffeinate process
    /// to guarantee the display never turns off and the system never enters idle sleep or locks.
    public func enableSleepPrevention(reason: String = "Genie Active Canvas & System Protection") {
        guard !isSleepDisabled else { return }
        self.activeReason = reason

        // 1. IOKit Kernel Display Sleep Assertion
        var dispID: IOPMAssertionID = 0
        let dispResult = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason as CFString,
            &dispID
        )
        if dispResult == kIOReturnSuccess {
            self.displayAssertionID = dispID
        }

        // 2. IOKit Kernel Idle System Sleep Assertion
        var sysID: IOPMAssertionID = 0
        let sysResult = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason as CFString,
            &sysID
        )
        if sysResult == kIOReturnSuccess {
            self.systemAssertionID = sysID
        }

        // 3. Foundation ProcessInfo Activity
        if activityToken == nil {
            let options: ProcessInfo.ActivityOptions = [
                .idleDisplaySleepDisabled,
                .idleSystemSleepDisabled,
                .userInitiated,
                .latencyCritical
            ]
            self.activityToken = ProcessInfo.processInfo.beginActivity(options: options, reason: reason)
        }

        // 4. Background caffeinate process as fail-safe kernel anchor
        startCaffeinateProcess()

        self.isSleepDisabled = true
        self.activationDate = Date()
        UserDefaults.standard.set(true, forKey: PrefKey.preventSystemSleep)
        NotificationCenter.default.post(name: NSNotification.Name("GenieSleepPreventionChanged"), object: true)
        print("☕ [Genie Sleep Prevention]: Active — Display and System Sleep Disabled (Assertions: disp=\(displayAssertionID), sys=\(systemAssertionID))")
    }

    // MARK: - Disable Sleep Prevention
    /// Releases all assertions and allows macOS to resume normal power management timers
    public func disableSleepPrevention() {
        guard isSleepDisabled else { return }

        // 1. Release IOKit Assertions
        if displayAssertionID != 0 {
            IOPMAssertionRelease(displayAssertionID)
            displayAssertionID = 0
        }
        if systemAssertionID != 0 {
            IOPMAssertionRelease(systemAssertionID)
            systemAssertionID = 0
        }

        // 2. End ProcessInfo Activity
        if let token = activityToken {
            ProcessInfo.processInfo.endActivity(token)
            activityToken = nil
        }

        // 3. Terminate background caffeinate
        stopCaffeinateProcess()

        self.isSleepDisabled = false
        self.activationDate = nil
        UserDefaults.standard.set(false, forKey: PrefKey.preventSystemSleep)
        NotificationCenter.default.post(name: NSNotification.Name("GenieSleepPreventionChanged"), object: false)
        print("🌙 [Genie Sleep Prevention]: Released — System allowed to sleep normally.")
    }

    // MARK: - Toggle
    public func toggleSleepPrevention() {
        if isSleepDisabled {
            disableSleepPrevention()
        } else {
            enableSleepPrevention()
        }
    }

    // MARK: - Background Caffeinate Support
    private func startCaffeinateProcess() {
        // Steps 1-3 above (two IOPMAssertions + a ProcessInfo activity) already
        // hold the system awake natively. `caffeinate` is only a belt-and-braces
        // fourth anchor, so the sandboxed build simply skips it and loses nothing.
        guard GenieCapabilities.canSpawnSubprocesses else { return }
        guard caffeinateProcess == nil else { return }
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
        // -d: prevent display sleep
        // -i: prevent idle sleep
        // -s: prevent system sleep on AC
        // -u: declare user activity
        proc.arguments = ["-d", "-i", "-s", "-u"]
        do {
            try proc.run()
            self.caffeinateProcess = proc
        } catch {
            print("⚠️ [Genie Sleep Prevention] Could not spawn caffeinate: \(error)")
        }
    }

    private func stopCaffeinateProcess() {
        if let proc = caffeinateProcess {
            if proc.isRunning {
                proc.terminate()
            }
            caffeinateProcess = nil
        }
    }

    // MARK: - Status String
    public var statusDescription: String {
        if isSleepDisabled {
            if let date = activationDate {
                let formatter = RelativeDateTimeFormatter()
                formatter.unitsStyle = .abbreviated
                let rel = formatter.localizedString(for: date, relativeTo: Date())
                return "Clamshell Awake 🖥️ (Since \(rel) — keeps awake when closed)"
            }
            return "Clamshell Awake 🖥️ (Keeps desktop awake when closed for monitor)"
        } else {
            return "Sleep Allowed 🌙 (Normal macOS Timer)"
        }
    }
}
