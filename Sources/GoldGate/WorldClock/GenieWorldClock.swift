import Foundation
import SwiftUI

// MARK: - Accent

/// Card accents for the blackout pillow cards. Raw values are persisted, so renaming
/// a case breaks saved boards — add cases, never rename them.
public enum GeniePillowAccent: String, Codable, CaseIterable, Identifiable {
    case orange, cyan, violet, mint, rose, gold

    public var id: String { rawValue }

    public var color: Color {
        switch self {
        case .orange: return Color(red: 1.0, green: 0.58, blue: 0.0)   // Apple clock orange
        case .cyan:   return Color(red: 0.29, green: 0.78, blue: 0.94)
        case .violet: return Color(red: 0.58, green: 0.44, blue: 0.96)
        case .mint:   return Color(red: 0.31, green: 0.85, blue: 0.65)
        case .rose:   return Color(red: 0.95, green: 0.38, blue: 0.52)
        case .gold:   return Color(red: 0.93, green: 0.78, blue: 0.35)
        }
    }

    public var label: String { rawValue.capitalized }
}

// MARK: - Size tiers

/// Size drives *layout*, not just scale — each tier renders a different card body.
public enum GeniePillowSize: String, Codable, CaseIterable, Identifiable {
    case compact, regular, large, hero

    public var id: String { rawValue }

    public var height: CGFloat {
        switch self {
        case .compact: return 64
        case .regular: return 104
        case .large:   return 168
        case .hero:    return 260
        }
    }

    public var cornerRadius: CGFloat {
        switch self {
        case .compact: return 16
        case .regular: return 22
        case .large:   return 28
        case .hero:    return 36
        }
    }

    /// Kept under 70pt below `.large` so the automatic second hand does not kick in.
    public var clockDialSize: CGFloat {
        switch self {
        case .compact: return 40
        case .regular: return 62
        case .large:   return 104
        case .hero:    return 168
        }
    }

    public var icon: String {
        switch self {
        case .compact: return "rectangle.compress.vertical"
        case .regular: return "rectangle.grid.1x2"
        case .large:   return "rectangle.expand.vertical"
        case .hero:    return "rectangle.portrait.arrowtriangle.2.outward"
        }
    }

    public var label: String { rawValue.capitalized }
}

// MARK: - City

/// One city on the board.
public struct GenieWorldClockCity: Identifiable, Codable, Equatable {
    public var id: UUID
    public var name: String
    public var timeZoneIdentifier: String
    public var accent: GeniePillowAccent

    public init(
        id: UUID = UUID(),
        name: String,
        timeZoneIdentifier: String,
        accent: GeniePillowAccent = .orange
    ) {
        self.id = id
        self.name = name
        self.timeZoneIdentifier = timeZoneIdentifier
        self.accent = accent
    }

    public var timeZone: TimeZone {
        TimeZone(identifier: timeZoneIdentifier) ?? .current
    }

    /// Every dial, label and alarm computes through one of these. Never the device zone.
    public var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        return cal
    }

    /// Offset from the Mac's own zone, e.g. "+9h" / "−3h30" / "same".
    public func offsetDescription(from reference: TimeZone = .current, at date: Date = Date()) -> String {
        let delta = timeZone.secondsFromGMT(for: date) - reference.secondsFromGMT(for: date)
        if delta == 0 { return "same time" }
        let sign = delta < 0 ? "−" : "+"
        let mag = abs(delta)
        let hours = mag / 3600
        let minutes = (mag % 3600) / 60
        return minutes == 0 ? "\(sign)\(hours)h" : "\(sign)\(hours)h\(minutes)"
    }

    /// True when it is night (before 06:00 or from 18:00) in this city.
    public func isNight(at date: Date = Date()) -> Bool {
        let hour = calendar.component(.hour, from: date)
        return hour < 6 || hour >= 18
    }

    /// Cities offered in the picker. Identifiers are validated against `TimeZone` at use.
    public static let presets: [(name: String, identifier: String)] = [
        ("Cupertino",   "America/Los_Angeles"),
        ("New York",    "America/New_York"),
        ("São Paulo",   "America/Sao_Paulo"),
        ("London",      "Europe/London"),
        ("Paris",       "Europe/Paris"),
        ("Berlin",      "Europe/Berlin"),
        ("Lagos",       "Africa/Lagos"),
        ("Dubai",       "Asia/Dubai"),
        ("Mumbai",      "Asia/Kolkata"),
        ("Singapore",   "Asia/Singapore"),
        ("Shanghai",    "Asia/Shanghai"),
        ("Seoul",       "Asia/Seoul"),
        ("Tokyo",       "Asia/Tokyo"),
        ("Sydney",      "Australia/Sydney"),
        ("Auckland",    "Pacific/Auckland")
    ]
}

// MARK: - Settings

/// The whole board, persisted as one JSON blob under a versioned key.
public struct GenieWorldClockSettings: Codable, Equatable {
    public var cities: [GenieWorldClockCity]
    public var size: GeniePillowSize
    public var showSeconds: Bool
    public var use24Hour: Bool
    public var alarms: [GenieAlarmClock]

    public init(
        cities: [GenieWorldClockCity],
        size: GeniePillowSize = .regular,
        showSeconds: Bool = false,
        use24Hour: Bool = true,
        alarms: [GenieAlarmClock] = []
    ) {
        self.cities = cities
        self.size = size
        self.showSeconds = showSeconds
        self.use24Hour = use24Hour
        self.alarms = alarms
    }

    public static var `default`: GenieWorldClockSettings {
        GenieWorldClockSettings(
            cities: [
                GenieWorldClockCity(name: "Seoul",    timeZoneIdentifier: "Asia/Seoul",           accent: .orange),
                GenieWorldClockCity(name: "Tokyo",    timeZoneIdentifier: "Asia/Tokyo",           accent: .rose),
                GenieWorldClockCity(name: "New York", timeZoneIdentifier: "America/New_York",     accent: .cyan),
                GenieWorldClockCity(name: "London",   timeZoneIdentifier: "Europe/London",        accent: .violet),
                GenieWorldClockCity(name: "Cupertino", timeZoneIdentifier: "America/Los_Angeles", accent: .mint)
            ]
        )
    }

    // Decoding tolerates settings written before `alarms` existed.
    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        cities      = try c.decodeIfPresent([GenieWorldClockCity].self, forKey: .cities) ?? Self.default.cities
        size        = try c.decodeIfPresent(GeniePillowSize.self, forKey: .size) ?? .regular
        showSeconds = try c.decodeIfPresent(Bool.self, forKey: .showSeconds) ?? false
        use24Hour   = try c.decodeIfPresent(Bool.self, forKey: .use24Hour) ?? true
        alarms      = try c.decodeIfPresent([GenieAlarmClock].self, forKey: .alarms) ?? []
    }
}

// MARK: - Store

/// Owns the board and writes it back to UserDefaults on every mutation.
@MainActor
public final class GenieWorldClockStore: ObservableObject {
    public static let shared = GenieWorldClockStore()

    @Published public var settings: GenieWorldClockSettings {
        didSet {
            guard settings != oldValue else { return }
            save()
        }
    }

    private init() {
        if let data = UserDefaults.standard.data(forKey: PrefKey.worldClockBoard_v1),
           let decoded = try? JSONDecoder().decode(GenieWorldClockSettings.self, from: data) {
            settings = decoded
        } else {
            settings = .default
        }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        UserDefaults.standard.set(data, forKey: PrefKey.worldClockBoard_v1)
    }

    public func addCity(name: String, identifier: String) {
        guard TimeZone(identifier: identifier) != nil else { return }
        guard !settings.cities.contains(where: { $0.timeZoneIdentifier == identifier }) else { return }
        let accent = GeniePillowAccent.allCases[settings.cities.count % GeniePillowAccent.allCases.count]
        settings.cities.append(
            GenieWorldClockCity(name: name, timeZoneIdentifier: identifier, accent: accent)
        )
    }

    public func remove(_ city: GenieWorldClockCity) {
        settings.cities.removeAll { $0.id == city.id }
    }

    public func move(from source: IndexSet, to destination: Int) {
        settings.cities.move(fromOffsets: source, toOffset: destination)
    }

    public func resizeAll(to size: GeniePillowSize) {
        settings.size = size
    }

    public func restoreDefaults() {
        let keptAlarms = settings.alarms
        settings = GenieWorldClockSettings(
            cities: GenieWorldClockSettings.default.cities,
            alarms: keptAlarms
        )
    }
}
