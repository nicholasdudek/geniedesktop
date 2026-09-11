import AppKit
import Foundation
import UserNotifications

/// Drives every alarm on the board from a single 1-second tick.
///
/// The tick is deliberately coarse: `isDue` matches on hour *and* minute, and
/// `lastFiredMinuteKey` guarantees one ring per minute even when the timer jitters
/// across a second boundary or the Mac wakes mid-minute.
@MainActor
public final class GenieAlarmClockManager: ObservableObject {
    public static let shared = GenieAlarmClockManager()

    /// The alarm currently ringing, if any — drives the red banner in the pane.
    @Published public private(set) var ringingAlarm: GenieAlarmClock?

    private var tickTimer: Timer?
    private var ringingSound: NSSound?
    private var hasRequestedNotificationPermission = false

    private var store: GenieWorldClockStore { GenieWorldClockStore.shared }

    private init() {}

    // MARK: - Lifecycle

    public func start() {
        guard tickTimer == nil else { return }
        let timer = Timer(timeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        // .common so the loop keeps firing while a menu is open or a window is being dragged.
        RunLoop.main.add(timer, forMode: .common)
        tickTimer = timer
    }

    public func stop() {
        tickTimer?.invalidate()
        tickTimer = nil
        stopRinging()
    }

    // MARK: - Tick

    private func tick() {
        let now = Date()
        for index in store.settings.alarms.indices {
            let alarm = store.settings.alarms[index]
            guard alarm.isDue(at: now) else { continue }

            // Stamp the dedupe key *before* ringing so a slow ring cannot double-fire.
            store.settings.alarms[index].lastFiredMinuteKey = alarm.minuteKey(for: now)
            store.settings.alarms[index].snoozeUntil = nil

            // A one-shot alarm retires itself; a repeating one stays armed.
            if alarm.repeatWeekdays.isEmpty {
                store.settings.alarms[index].isEnabled = false
            }

            ring(store.settings.alarms[index])
        }
    }

    // MARK: - Ringing

    private func ring(_ alarm: GenieAlarmClock) {
        ringingAlarm = alarm

        if let sound = NSSound(named: alarm.sound.systemName) {
            sound.loops = true
            ringingSound = sound
            sound.play()
        } else {
            NSSound.beep()
        }

        NSApp.requestUserAttention(.criticalRequest)
        postNotification(for: alarm)
    }

    public func stopRinging() {
        ringingSound?.stop()
        ringingSound = nil
        ringingAlarm = nil
    }

    public func snooze(minutes: Int = 9) {
        guard let ringing = ringingAlarm else { return }
        stopRinging()
        guard let index = store.settings.alarms.firstIndex(where: { $0.id == ringing.id }) else { return }
        store.settings.alarms[index].snoozeUntil = Date().addingTimeInterval(Double(minutes) * 60)
        store.settings.alarms[index].isEnabled = true
    }

    // MARK: - Alarms

    public func add(_ alarm: GenieAlarmClock) {
        store.settings.alarms.append(alarm)
        requestNotificationPermissionIfNeeded()
    }

    public func update(_ alarm: GenieAlarmClock) {
        guard let index = store.settings.alarms.firstIndex(where: { $0.id == alarm.id }) else { return }
        var updated = alarm
        // Editing an alarm clears the dedupe key so a corrected time can ring this same minute.
        updated.lastFiredMinuteKey = nil
        store.settings.alarms[index] = updated
    }

    public func remove(_ alarm: GenieAlarmClock) {
        store.settings.alarms.removeAll { $0.id == alarm.id }
        if ringingAlarm?.id == alarm.id { stopRinging() }
    }

    public func setEnabled(_ isEnabled: Bool, for alarm: GenieAlarmClock) {
        guard let index = store.settings.alarms.firstIndex(where: { $0.id == alarm.id }) else { return }
        store.settings.alarms[index].isEnabled = isEnabled
        store.settings.alarms[index].snoozeUntil = nil
        if isEnabled { requestNotificationPermissionIfNeeded() }
    }

    // MARK: - Notifications
    //
    // UNUserNotificationCenter traps when the executable is not inside a .app bundle,
    // which is exactly how Genie runs under `swift run`. Every call is gated on that.

    private var isRunningAsBundle: Bool {
        Bundle.main.bundleURL.pathExtension == "app"
    }

    private func requestNotificationPermissionIfNeeded() {
        guard isRunningAsBundle, !hasRequestedNotificationPermission else { return }
        hasRequestedNotificationPermission = true
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func postNotification(for alarm: GenieAlarmClock) {
        guard isRunningAsBundle else { return }
        let content = UNMutableNotificationContent()
        content.title = alarm.label
        content.body = {
            let zone = alarm.timeZoneIdentifier.map { $0.split(separator: "/").last.map(String.init) ?? $0 }
            let time = String(format: "%02d:%02d", alarm.hour, alarm.minute)
            return zone.map { "\(time) in \($0.replacingOccurrences(of: "_", with: " "))" } ?? time
        }()
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: alarm.id.uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
}
