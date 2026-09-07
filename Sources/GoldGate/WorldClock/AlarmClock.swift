import SwiftUI
import Foundation

// MARK: - Alarm Sound (macOS system sounds, played via NSSound)
public enum AlarmSound: String, CaseIterable, Codable, Identifiable {
    case glass = "Glass"
    case hero = "Hero"
    case ping = "Ping"
    case submarine = "Submarine"
    case blow = "Blow"
    case bottle = "Bottle"
    case funk = "Funk"
    case purr = "Purr"
    case sosumi = "Sosumi"
    case tink = "Tink"
    case pop = "Pop"
    case morse = "Morse"
    case basso = "Basso"
    case frog = "Frog"

    public var id: String { rawValue }
}

// MARK: - Alarm Clock Model
/// A single alarm. Time is interpreted in `timeZoneIdentifier` when set (so you can set
/// "9:00 AM Tokyo"), otherwise in the Mac's local time zone.
public struct AlarmClock: Identifiable, Codable, Equatable {
    public var id: UUID
    public var hour: Int          // 0...23
    public var minute: Int        // 0...59
    public var label: String
    public var isEnabled: Bool
    public var repeatWeekdays: Set<Int>   // Calendar weekday numbers 1 (Sun) ... 7 (Sat); empty = one-shot
    public var sound: AlarmSound
    public var timeZoneIdentifier: String?
    public var snoozeUntil: Date?
    public var lastFiredMinuteKey: String?

    public init(
        id: UUID = UUID(),
        hour: Int = 7,
        minute: Int = 0,
        label: String = "Alarm",
        isEnabled: Bool = true,
        repeatWeekdays: Set<Int> = [],
        sound: AlarmSound = .glass,
        timeZoneIdentifier: String? = nil,
        snoozeUntil: Date? = nil,
        lastFiredMinuteKey: String? = nil
    ) {
        self.id = id
        self.hour = hour
        self.minute = minute
        self.label = label
        self.isEnabled = isEnabled
        self.repeatWeekdays = repeatWeekdays
        self.sound = sound
        self.timeZoneIdentifier = timeZoneIdentifier
        self.snoozeUntil = snoozeUntil
        self.lastFiredMinuteKey = lastFiredMinuteKey
    }

    public var timeZone: TimeZone {
        if let id = timeZoneIdentifier, let tz = TimeZone(identifier: id) { return tz }
        return .current
    }

    public var isRepeating: Bool { !repeatWeekdays.isEmpty }

    private var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        return cal
    }

    /// "7:30 AM" in the alarm's own time zone.
    public var formattedTime: String {
        var comps = DateComponents()
        comps.hour = hour
        comps.minute = minute
        let date = calendar.date(from: comps) ?? Date()
        let f = DateFormatter()
        f.timeZone = timeZone
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "h:mm a"
        return f.string(from: date)
    }

    /// "Weekdays", "Every day", "Mon, Wed, Fri", or "Once".
    public var repeatDescription: String {
        if repeatWeekdays.isEmpty { return "Once" }
        if repeatWeekdays.count == 7 { return "Every day" }
        if repeatWeekdays == [2, 3, 4, 5, 6] { return "Weekdays" }
        if repeatWeekdays == [1, 7] { return "Weekends" }
        let symbols = Calendar(identifier: .gregorian).shortWeekdaySymbols
        return repeatWeekdays.sorted().map { symbols[$0 - 1] }.joined(separator: ", ")
    }

    /// The next moment this alarm should ring at or after `date`, honoring snooze and repeat days.
    public func nextFireDate(after date: Date = Date()) -> Date? {
        guard isEnabled else { return nil }
        if let snooze = snoozeUntil, snooze > date { return snooze }

        let cal = calendar
        for dayOffset in 0..<8 {
            guard let day = cal.date(byAdding: .day, value: dayOffset, to: date),
                  let candidate = cal.date(bySettingHour: hour, minute: minute, second: 0, of: day) else { continue }
            if candidate <= date { continue }
            if repeatWeekdays.isEmpty { return candidate }
            let weekday = cal.component(.weekday, from: candidate)
            if repeatWeekdays.contains(weekday) { return candidate }
        }
        return nil
    }

    /// A stable key for "this alarm, this minute" so an alarm fires once per minute at most.
    public func minuteKey(for date: Date) -> String {
        let f = DateFormatter()
        f.timeZone = timeZone
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return f.string(from: date)
    }

    /// True when the alarm should ring right now.
    public func isDue(at date: Date) -> Bool {
        guard isEnabled else { return false }
        let key = minuteKey(for: date)
        if lastFiredMinuteKey == key { return false }

        if let snooze = snoozeUntil {
            return date >= snooze
        }

        let comps = calendar.dateComponents([.hour, .minute, .weekday], from: date)
        guard comps.hour == hour, comps.minute == minute else { return false }
        if repeatWeekdays.isEmpty { return true }
        return repeatWeekdays.contains(comps.weekday ?? 0)
    }

    /// Human-readable countdown like "in 6h 12m".
    public func countdownDescription(from date: Date = Date()) -> String {
        guard let next = nextFireDate(after: date) else { return "Off" }
        let seconds = Int(next.timeIntervalSince(date))
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        if h == 0 { return "in \(max(m, 1))m" }
        if h >= 24 {
            let d = h / 24
            return "in \(d)d \(h % 24)h"
        }
        return "in \(h)h \(m)m"
    }
}
