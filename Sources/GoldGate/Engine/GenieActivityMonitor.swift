import AppKit
import Foundation

// MARK: - Bounded process + clipboard activity log
//
// Off by default: this watches which apps launch/activate/quit and takes a short,
// truncated preview whenever the clipboard changes. Both feeds are unbounded by
// nature (a long session launches hundreds of apps and copies thousands of times),
// so they're kept in an `AttentionSinkBuffer` rather than a plain array — see
// CompactParticleBuffer.swift. Not wired into the agent's tool-calling context yet:
// piping raw clipboard contents into an LLM prompt is a separate decision with real
// privacy stakes (clipboards routinely hold passwords, tokens, addresses) and should
// be opted into explicitly rather than happening as a side effect of turning this on.

public struct ActivityEvent: Identifiable, Equatable {
    public let id = UUID()
    public let date: Date
    public let kind: Kind

    public enum Kind: Equatable {
        case processLaunched(String)
        case processActivated(String)
        case processTerminated(String)
        case clipboardChanged(preview: String)
    }

    public var summary: String {
        switch kind {
        case .processLaunched(let name): return "Launched \(name)"
        case .processActivated(let name): return "Switched to \(name)"
        case .processTerminated(let name): return "Quit \(name)"
        case .clipboardChanged(let preview): return "Clipboard: \(preview)"
        }
    }
}

@MainActor
public final class GenieActivityMonitor: ObservableObject {
    public static let shared = GenieActivityMonitor()

    /// Newest last. 300 events covers a long session without holding it all: at a
    /// worst case of ~250 bytes per clipboard preview that's under 100 KB resident.
    @Published public private(set) var events = AttentionSinkBuffer<ActivityEvent>(capacity: 300, anchorCount: 0)
    @Published public private(set) var isMonitoring = false

    /// Clipboard text longer than this is truncated before it's ever stored, so a
    /// single large copy (a file's contents, a long document) can't dominate the log.
    private static let clipboardPreviewLimit = 200

    private var launchObserver: NSObjectProtocol?
    private var activateObserver: NSObjectProtocol?
    private var terminateObserver: NSObjectProtocol?
    private var clipboardTimer: Timer?
    private var lastClipboardChangeCount = NSPasteboard.general.changeCount

    private init() {}

    public func start() {
        guard !isMonitoring else { return }
        isMonitoring = true

        let center = NSWorkspace.shared.notificationCenter
        launchObserver = center.addObserver(forName: NSWorkspace.didLaunchApplicationNotification, object: nil, queue: .main) { note in
            guard let name = Self.appName(from: note) else { return }
            Task { @MainActor in GenieActivityMonitor.shared.record(.processLaunched(name)) }
        }
        activateObserver = center.addObserver(forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main) { note in
            guard let name = Self.appName(from: note) else { return }
            Task { @MainActor in GenieActivityMonitor.shared.record(.processActivated(name)) }
        }
        terminateObserver = center.addObserver(forName: NSWorkspace.didTerminateApplicationNotification, object: nil, queue: .main) { note in
            guard let name = Self.appName(from: note) else { return }
            Task { @MainActor in GenieActivityMonitor.shared.record(.processTerminated(name)) }
        }

        // NSPasteboard has no change notification; polling changeCount is the
        // standard, documented way to detect a copy without reading its contents
        // on every tick.
        lastClipboardChangeCount = NSPasteboard.general.changeCount
        clipboardTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.pollClipboard() }
        }
    }

    public func stop() {
        isMonitoring = false
        let center = NSWorkspace.shared.notificationCenter
        for observer in [launchObserver, activateObserver, terminateObserver].compactMap({ $0 }) {
            center.removeObserver(observer)
        }
        launchObserver = nil; activateObserver = nil; terminateObserver = nil
        clipboardTimer?.invalidate()
        clipboardTimer = nil
    }

    public func clear() {
        events.removeAll()
    }

    private func pollClipboard() {
        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount != lastClipboardChangeCount else { return }
        lastClipboardChangeCount = pasteboard.changeCount
        guard let text = pasteboard.string(forType: .string), !text.isEmpty else { return }
        let preview = text.count > Self.clipboardPreviewLimit
            ? String(text.prefix(Self.clipboardPreviewLimit)) + "…"
            : text
        record(.clipboardChanged(preview: preview))
    }

    private func record(_ kind: ActivityEvent.Kind) {
        events.append(ActivityEvent(date: Date(), kind: kind))
    }

    nonisolated private static func appName(from note: Notification) -> String? {
        guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return nil }
        return app.localizedName ?? app.bundleIdentifier
    }
}
