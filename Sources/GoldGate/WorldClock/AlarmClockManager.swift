import SwiftUI
import Combine
import AppKit
import UserNotifications

/// Owns the list of alarms, persists them, and rings them on time.
/// Playback uses NSSound (system sounds), and a local notification is posted when the app
/// runs as a real bundle so the alarm surfaces even when Genie's panels are hidden.
@MainActor
public final class AlarmClockManager: ObservableObject {
    public static let shared = AlarmClockManager()

    @Published public var alarms: [AlarmClock] = [] {
        didSet { save() }
    }
    @Published public private(set) var ringingAlarm: AlarmClock? = nil
    @Published public var now: Date = Date()

    private var timer: AnyCancellable?
    private var sound: NSSound?
    private let storageKey = "GenieAlarmClocks_v1"
    private var notificationsRequested = false

    public init() {
        load()
        start()
    }

    // MARK: - Lifecycle
    public func start() {
        guard timer == nil else { return }
        timer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] date in
                guard let self else { return }
                self.now = date
                self.tick(date)
            }
    }

    private func tick(_ date: Date) {
        guard ringingAlarm == nil else { return }
        for idx in alarms.indices where alarms[idx].isDue(at: date) {
            alarms[idx].lastFiredMinuteKey = alarms[idx].minuteKey(for: date)
            alarms[idx].snoozeUntil = nil
            if !alarms[idx].isRepeating {
                alarms[idx].isEnabled = false
            }
            ring(alarms[idx])
            break
        }
    }

    // MARK: - CRUD
    public func add(_ alarm: AlarmClock) {
        alarms.append(alarm)
        alarms.sort { ($0.hour, $0.minute) < ($1.hour, $1.minute) }
        requestNotificationPermissionIfNeeded()
    }

    public func update(_ alarm: AlarmClock) {
        if let idx = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[idx] = alarm
            alarms.sort { ($0.hour, $0.minute) < ($1.hour, $1.minute) }
        }
    }

    public func remove(id: UUID) {
        alarms.removeAll { $0.id == id }
        if ringingAlarm?.id == id { stopRinging() }
    }

    public func setEnabled(id: UUID, _ enabled: Bool) {
        if let idx = alarms.firstIndex(where: { $0.id == id }) {
            alarms[idx].isEnabled = enabled
            alarms[idx].snoozeUntil = nil
        }
    }

    /// The soonest upcoming alarm, for a "Next alarm" badge.
    public var nextAlarm: (alarm: AlarmClock, date: Date)? {
        alarms.compactMap { a in a.nextFireDate(after: now).map { (a, $0) } }
            .min { $0.1 < $1.1 }
    }

    // MARK: - Ringing
    private func ring(_ alarm: AlarmClock) {
        ringingAlarm = alarm
        playSound(alarm.sound, loop: true)
        postNotification(for: alarm)
        NSApp.requestUserAttention(.criticalRequest)
    }

    public func stopRinging() {
        sound?.stop()
        sound = nil
        ringingAlarm = nil
    }

    public func snooze(minutes: Int = 9) {
        guard let ringing = ringingAlarm,
              let idx = alarms.firstIndex(where: { $0.id == ringing.id }) else {
            stopRinging()
            return
        }
        alarms[idx].snoozeUntil = Date().addingTimeInterval(TimeInterval(minutes * 60))
        alarms[idx].isEnabled = true
        stopRinging()
    }

    /// Preview a sound once (used by the alarm editor).
    public func preview(_ soundName: AlarmSound) {
        playSound(soundName, loop: false)
    }

    private func playSound(_ soundName: AlarmSound, loop: Bool) {
        sound?.stop()
        guard let s = NSSound(named: NSSound.Name(soundName.rawValue)) else {
            NSSound.beep()
            return
        }
        s.loops = loop
        s.volume = 1.0
        s.play()
        sound = s
    }

    // MARK: - Notifications
    private var canUseNotifications: Bool {
        Bundle.main.bundleIdentifier != nil && Bundle.main.bundleURL.pathExtension == "app"
    }

    private func requestNotificationPermissionIfNeeded() {
        guard canUseNotifications, !notificationsRequested else { return }
        notificationsRequested = true
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func postNotification(for alarm: AlarmClock) {
        guard canUseNotifications else { return }
        let content = UNMutableNotificationContent()
        content.title = alarm.label.isEmpty ? "Alarm" : alarm.label
        content.body = "It's \(alarm.formattedTime)" + (alarm.timeZoneIdentifier != nil ? " in \(alarm.timeZone.identifier.split(separator: "/").last.map(String.init) ?? "")" : "")
        content.sound = .default
        let request = UNNotificationRequest(identifier: "genie.alarm.\(alarm.id.uuidString)", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { _ in }
    }

    // MARK: - Persistence
    private func save() {
        if let data = try? JSONEncoder().encode(alarms) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([AlarmClock].self, from: data) {
            alarms = decoded
        }
    }
}
