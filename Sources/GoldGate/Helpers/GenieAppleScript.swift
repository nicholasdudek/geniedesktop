import Foundation
import os

// MARK: - 🍎 Serialized AppleScript Runner
//
// `NSAppleScript.executeAndReturnError` is synchronous and, when the target app
// never answers the Apple Event, it blocks its thread indefinitely — the AE
// layer parks in `_dispatch_group_wait_slow` and never returns.
//
// Dispatching that onto `DispatchQueue.global()` therefore burns one worker
// thread from the *shared* pool per wedged script. A live 16-hour session was
// found with 70 of its 84 threads stuck this way inside one space-switch
// script, which starves every other queue and every `Task { @MainActor }` on
// the machine: ~930,000 tasks had piled up unrun, 2 GB of task stacks and
// timer sources, still climbing at 2 MB a second.
//
// So every script in the app goes through here instead:
//
//   • one dedicated serial queue, never the shared pool, so a wedge can cost
//     at most one thread no matter how many callers pile in;
//   • `with timeout of N seconds` wrapped around the source, which is what
//     actually bounds `AESendMessage` — there is no API-level timeout;
//   • backpressure: past `maximumPending` queued scripts the newest is dropped
//     rather than growing the queue without limit.
public enum GenieAppleScript {

    /// The only thread in the app allowed to block on an Apple Event.
    public static let queue = DispatchQueue(
        label: "com.nicholasdudek.genie.applescript",
        qos: .userInitiated
    )

    /// Scripts allowed to wait their turn before new ones are refused.
    public static let maximumPending = 8

    private static let logger = Logger(subsystem: "com.nicholasdudek.genie", category: "AppleScript")
    private static let pendingLock = NSLock()
    nonisolated(unsafe) private static var pending = 0

    /// Default ceiling on how long a script may wait for its target to answer.
    public static let defaultTimeout: TimeInterval = 8

    /// Builds a script whose Apple Events give up instead of hanging forever.
    /// Drop-in replacement for `NSAppleScript(source:)`.
    public static func script(source: String, timeout: TimeInterval = defaultTimeout) -> NSAppleScript? {
        NSAppleScript(source: wrap(source, timeout: timeout))
    }

    /// `with timeout` is the only thing that bounds an Apple Event send, and it
    /// has to wrap the `tell` blocks rather than sit beside them. Sources that
    /// already manage their own timeout, or that open with a `use` declaration
    /// (which must stay at the top of the script), are left alone.
    public static func wrap(_ source: String, timeout: TimeInterval = defaultTimeout) -> String {
        let trimmed = source.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              !trimmed.contains("with timeout"),
              !trimmed.hasPrefix("use "),
              !trimmed.contains("\non run"),
              !trimmed.hasPrefix("on run") else { return source }

        let seconds = max(1, Int(timeout.rounded()))
        return """
        with timeout of \(seconds) seconds
        \(trimmed)
        end timeout
        """
    }

    /// Runs a script on the serial queue. Returns false if backpressure refused
    /// it, so callers can fall back to a CGEvent path instead of assuming it ran.
    @discardableResult
    public static func run(
        _ source: String,
        timeout: TimeInterval = defaultTimeout,
        label: String = "script",
        completion: (@Sendable (NSAppleEventDescriptor?, NSDictionary?) -> Void)? = nil
    ) -> Bool {
        pendingLock.lock()
        let queued = pending
        if queued >= maximumPending {
            pendingLock.unlock()
            logger.error("dropped AppleScript \(label, privacy: .public): \(queued) already queued")
            completion?(nil, ["GenieError": "AppleScript queue saturated"] as NSDictionary)
            return false
        }
        pending += 1
        pendingLock.unlock()

        queue.async {
            defer {
                pendingLock.lock()
                pending -= 1
                pendingLock.unlock()
            }

            guard let script = script(source: source, timeout: timeout) else {
                logger.error("could not compile AppleScript \(label, privacy: .public)")
                completion?(nil, ["GenieError": "AppleScript failed to compile"] as NSDictionary)
                return
            }

            let started = ContinuousClock.now
            var error: NSDictionary?
            let descriptor = script.executeAndReturnError(&error)
            let elapsed = ContinuousClock.now - started

            if let error {
                logger.error("AppleScript \(label, privacy: .public) failed: \(error, privacy: .public)")
            } else if elapsed > .seconds(2) {
                logger.notice("AppleScript \(label, privacy: .public) took \(elapsed.description, privacy: .public)")
            }
            completion?(descriptor, error)
        }
        return true
    }

    /// How many scripts are waiting — for diagnostics and tests.
    public static var pendingCount: Int {
        pendingLock.lock()
        defer { pendingLock.unlock() }
        return pending
    }
}
