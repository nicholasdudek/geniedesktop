import AppKit

@main
struct GenieAppMain {
    private static var appDelegate: AppDelegate?

    @MainActor
    static func main() {
        print("GENIE: main() started")
        let app = NSApplication.shared

        if CommandLine.arguments.contains("--smoke-test") {
            Task { @MainActor in
                await GenieSmokeTester.runAllTests()
                CFRunLoopStop(CFRunLoopGetMain())
                exit(0)
            }
            CFRunLoopRun()
            return
        }

        terminateConflictingInstances()

        let delegate = AppDelegate()
        self.appDelegate = delegate
        app.delegate = delegate
        print("GENIE: Calling app.run()")
        app.run()
        print("GENIE: app.run() returned!")
    }

    @MainActor
    private static func terminateConflictingInstances() {
        let myPid = ProcessInfo.processInfo.processIdentifier
        let runningApps = NSWorkspace.shared.runningApplications
        let duplicates = runningApps.filter { otherApp in
            guard otherApp.processIdentifier != myPid, !otherApp.isTerminated else { return false }
            if let bid = otherApp.bundleIdentifier, bid == "com.nicholasdudek.genie" || bid == "com.goldengate.Genie" {
                return true
            }
            if let name = otherApp.localizedName, name == "Genie" || name == "GoldGate" {
                return true
            }
            return false
        }

        guard !duplicates.isEmpty else { return }

        print("GENIE: Found \(duplicates.count) existing Genie instance(s). Terminating to avoid resource and port conflicts...")
        for dup in duplicates {
            print("GENIE: Terminating PID \(dup.processIdentifier) (\(dup.localizedName ?? "Genie"))...")
            dup.terminate()
        }

        // Give existing instances up to 0.8 seconds to exit and free network ports
        let deadline = Date().addingTimeInterval(0.8)
        while Date() < deadline {
            let stillRunning = duplicates.filter { !$0.isTerminated }
            if stillRunning.isEmpty { break }
            RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.05))
        }

        for dup in duplicates where !dup.isTerminated {
            print("GENIE: Force terminating PID \(dup.processIdentifier)...")
            dup.forceTerminate()
        }
    }
}
