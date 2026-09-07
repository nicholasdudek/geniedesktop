import SwiftUI
import Foundation

public enum PillowSize: String, CaseIterable, Codable, Identifiable {
    case compact = "Compact"
    case regular = "Regular"
    case large = "Large"
    case hero = "Hero"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .compact: return "rectangle.compress.vertical"
        case .regular: return "rectangle"
        case .large: return "rectangle.expand.vertical"
        case .hero: return "sparkles.rectangle.stack.fill"
        }
    }
    
    public var height: CGFloat {
        switch self {
        case .compact: return 76
        case .regular: return 115
        case .large: return 175
        case .hero: return 245
        }
    }
    
    public var cornerRadius: CGFloat {
        switch self {
        case .compact: return 22
        case .regular: return 30
        case .large: return 36
        case .hero: return 42
        }
    }
    
    public var clockDialSize: CGFloat {
        switch self {
        case .compact: return 46
        case .regular: return 68
        case .large: return 105
        case .hero: return 150
        }
    }
}

public enum PillowAccent: String, CaseIterable, Codable, Identifiable {
    case classicOrange = "Orange"
    case amberGold = "Amber"
    case electricCyan = "Cyan"
    case neonEmerald = "Emerald"
    case ultraViolet = "Purple"
    case pureMonochrome = "Monochrome"
    case crimsonRed = "Crimson"
    
    public var id: String { rawValue }
    
    public var color: Color {
        switch self {
        case .classicOrange: return Color(red: 1.0, green: 0.58, blue: 0.0) // Apple Clock Orange
        case .amberGold: return Color(red: 1.0, green: 0.8, blue: 0.2)
        case .electricCyan: return Color(red: 0.1, green: 0.85, blue: 1.0)
        case .neonEmerald: return Color(red: 0.2, green: 0.9, blue: 0.45)
        case .ultraViolet: return Color(red: 0.75, green: 0.4, blue: 1.0)
        case .pureMonochrome: return Color(white: 0.88)
        case .crimsonRed: return Color(red: 1.0, green: 0.3, blue: 0.35)
        }
    }
}

public struct PillowClock: Identifiable, Codable, Equatable {
    public var id: UUID
    public var cityName: String
    public var countryOrRegion: String
    public var timeZoneIdentifier: String
    public var customLabel: String?
    public var size: PillowSize
    public var accent: PillowAccent
    public var showAnalogDial: Bool
    public var showSeconds: Bool
    public var showDayNightIndicator: Bool
    
    public init(
        id: UUID = UUID(),
        cityName: String,
        countryOrRegion: String,
        timeZoneIdentifier: String,
        customLabel: String? = nil,
        size: PillowSize = .regular,
        accent: PillowAccent = .classicOrange,
        showAnalogDial: Bool = true,
        showSeconds: Bool = false,
        showDayNightIndicator: Bool = true
    ) {
        self.id = id
        self.cityName = cityName
        self.countryOrRegion = countryOrRegion
        self.timeZoneIdentifier = timeZoneIdentifier
        self.customLabel = customLabel
        self.size = size
        self.accent = accent
        self.showAnalogDial = showAnalogDial
        self.showSeconds = showSeconds
        self.showDayNightIndicator = showDayNightIndicator
    }
    
    public var timeZone: TimeZone {
        TimeZone(identifier: timeZoneIdentifier) ?? TimeZone.current
    }
    
    public var displayName: String {
        if let customLabel = customLabel, !customLabel.trimmingCharacters(in: .whitespaces).isEmpty {
            return customLabel
        }
        return cityName
    }
    
    public func formattedDigitalTime(for date: Date = Date(), includeSeconds: Bool = false) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = includeSeconds ? "h:mm:ss" : "h:mm"
        return formatter.string(from: date)
    }
    
    public func formattedAmPm(for date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "a"
        return formatter.string(from: date).uppercased()
    }
    
    public func formattedDateShort(for date: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.dateFormat = "EEE, MMM d"
        return formatter.string(from: date)
    }
    
    public func relativeOffsetDescription(referenceDate: Date = Date(), localTimeZone: TimeZone = .current) -> String {
        let localSeconds = localTimeZone.secondsFromGMT(for: referenceDate)
        let targetSeconds = timeZone.secondsFromGMT(for: referenceDate)
        let diffSeconds = targetSeconds - localSeconds
        let diffHours = Double(diffSeconds) / 3600.0
        
        var calendar = Calendar.current
        calendar.timeZone = timeZone
        let targetDay = calendar.component(.day, from: referenceDate)
        
        var localCalendar = Calendar.current
        localCalendar.timeZone = localTimeZone
        let localDay = localCalendar.component(.day, from: referenceDate)
        
        let dayPrefix: String
        if targetDay == localDay {
            dayPrefix = "Today"
        } else if targetDay > localDay || (localDay - targetDay > 20) {
            dayPrefix = "Tomorrow"
        } else {
            dayPrefix = "Yesterday"
        }
        
        if diffSeconds == 0 {
            return "\(dayPrefix), Same time"
        }
        
        let sign = diffHours > 0 ? "+" : ""
        let hoursFormatted: String
        if floor(diffHours) == diffHours {
            hoursFormatted = "\(sign)\(Int(diffHours))HRS"
        } else {
            let mins = abs(Int((diffHours.truncatingRemainder(dividingBy: 1.0)) * 60))
            let hrs = Int(diffHours)
            hoursFormatted = "\(sign)\(hrs)h \(mins)m"
        }
        
        return "\(dayPrefix), \(hoursFormatted)"
    }
    
    public func isDaytime(for date: Date = Date()) -> Bool {
        var calendar = Calendar.current
        calendar.timeZone = timeZone
        let hour = calendar.component(.hour, from: date)
        return hour >= 6 && hour < 18
    }
    
    public func timeZoneAbbreviation(for date: Date = Date()) -> String {
        timeZone.abbreviation(for: date) ?? "GMT"
    }
}
