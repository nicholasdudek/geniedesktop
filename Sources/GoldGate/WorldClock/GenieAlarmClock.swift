import Foundation

// MARK: - Sound

public enum GenieAlarmSound: String, Codable, CaseIterable, Identifiable {
    case glass = "Glass"
    case hero = "Hero"
    case ping = "Ping"
    case submarine = "Submarine"
    case sosumi = "Sosumi"
    case blow = "Blow"

    public var id: String { rawValue }
    /// Matches an NSSound system name; `NSSound(named:)` returns nil if the user removed it.
    public var systemName: String { rawValue }
}

// MARK: - Alarm

public struct GenieAlarmClock: Identifiable, Codable, Equatable {
    public var id: UUID
    public var hour: Int
    public var minute: Int
    public var label: String
    public var isEnabled: Bool
    /// `Calendar` weekdays: 1 = Sunday … 7 = Saturday. Empty means a one-shot alarm.
    public var repeatWeekdays: Set<Int>
    public var sound: GenieAlarmSound
    /// nil means the Mac's own zone.
    public var timeZoneIdentifier: String?
    public var snoozeUntil: Date?
    /// "yyyy-MM-dd HH:mm" in the alarm's own zone — the dedupe key that keeps a
    /// 1-second tick from ringing the same minute more than once.
    public var lastFiredMinuteKey: String?

    public init(
        id: UUID = UUID(),
        hour: Int,
        minute: Int,
        label: String = "Alarm",
        isEnabled: Bool = true,
        repeatWeekdays: Set<Int> = [],
        sound: GenieAlarmSound = .glass,
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
        guard let timeZoneIdentifier, let zone = TimeZone(identifier: timeZoneIdentifier) else {
            return .current
        }
        return zone
    }

    public var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        return cal
    }

    /// The dedupe key for `date`, in this alarm's zone.
    public func minuteKey(for date: Date) -> String {
        let c = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        return String(
            format: "%04d-%02d-%02d %02d:%02d",
            c.year ?? 0, c.month ?? 0, c.day ?? 0, c.hour ?? 0, c.minute ?? 0
        )
    }

    /// True when this alarm should ring right now and has not already rung this minute.
    public func isDue(at now: Date) -> Bool {
        guard isEnabled else { return false }

        // A snoozed alarm rings when the snooze elapses, regardless of its hour/minute.
        if let snoozeUntil {
            return now >= snoozeUntil
        }

        let cal = calendar
        let comps = cal.dateComponents([.hour, .minute, .weekday], from: now)
        guard comps.hour == hour, comps.minute == minute else { return false }

        if !repeatWeekdays.isEmpty {
            guard let weekday = comps.weekday, repeatWeekdays.contains(weekday) else { return false }
        }

        return lastFiredMinuteKey != minuteKey(for: now)
    }

    /// Next time this alarm will ring, for the countdown label.
    public func nextFireDate(after now: Date = Date()) -> Date? {
        guard isEnabled else { return nil }
        if let snoozeUntil, snoozeUntil > now { return snoozeUntil }

        let cal = calendar
        // Scan 8 days so a weekly repeat always lands.
        for dayOffset in 0...8 {
            guard
                let day = cal.date(byAdding: .day, value: dayOffset, to: now),
                let candidate = cal.date(
                    bySettingHour: hour, minute: minute, second: 0, of: day
                )
            else { continue }

            guard candidate > now else { continue }

            if repeatWeekdays.isEmpty {
                return candidate
            }
            let weekday = cal.component(.weekday, from: candidate)
            if repeatWeekdays.contains(weekday) { return candidate }
        }
        return nil
    }

    /// "in 6h 12m", or nil when the alarm will never ring.
    public func countdownDescription(from now: Date = Date()) -> String? {
        guard let next = nextFireDate(after: now) else { return nil }
        let seconds = Int(next.timeIntervalSince(now))
        guard seconds > 0 else { return "now" }
        let days = seconds / 86_400
        let hours = (seconds % 86_400) / 3600
        let minutes = (seconds % 3600) / 60
        if days > 0 { return "in \(days)d \(hours)h" }
        if hours > 0 { return "in \(hours)h \(minutes)m" }
        return "in \(minutes)m"
    }

    /// "Every day" / "Weekdays" / "Weekends" / "Mon, Wed" / "Once".
    public var repeatDescription: String {
        if repeatWeekdays.isEmpty { return "Once" }
        if repeatWeekdays == Set(1...7) { return "Every day" }
        if repeatWeekdays == Set([2, 3, 4, 5, 6]) { return "Weekdays" }
        if repeatWeekdays == Set([1, 7]) { return "Weekends" }
        let symbols = Calendar(identifier: .gregorian).shortWeekdaySymbols
        return repeatWeekdays.sorted()
            .compactMap { symbols.indices.contains($0 - 1) ? symbols[$0 - 1] : nil }
            .joined(separator: ", ")
    }

    /// A `Date` carrying this alarm's wall-clock time, for driving the mini dial.
    public func displayDate(on day: Date = Date()) -> Date {
        calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) ?? day
    }
}
