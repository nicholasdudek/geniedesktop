import SwiftUI
import Foundation

public enum CallSuitability: String, CaseIterable, Codable {
    case optimal = "Best Time to Call"
    case acceptable = "Fair Time to Call"
    case lateEvening = "Late Evening (Caution)"
    case sleeping = "Sleeping (Do Not Disturb)"
    
    public var badgeText: String {
        switch self {
        case .optimal: return "Optimal to Call"
        case .acceptable: return "Fair to Call"
        case .lateEvening: return "Late Evening"
        case .sleeping: return "Sleeping"
        }
    }
    
    public var iconName: String {
        switch self {
        case .optimal: return "phone.fill.arrow.up.right"
        case .acceptable: return "phone.fill"
        case .lateEvening: return "phone.badge.waveform.fill"
        case .sleeping: return "moon.zzz.fill"
        }
    }
    
    public var statusColor: Color {
        switch self {
        case .optimal: return Color(red: 0.18, green: 0.86, blue: 0.45) // Neon emerald green
        case .acceptable: return Color(red: 1.0, green: 0.8, blue: 0.2) // Amber yellow
        case .lateEvening: return Color(red: 1.0, green: 0.55, blue: 0.15) // Orange
        case .sleeping: return Color(red: 0.55, green: 0.45, blue: 0.95) // Purple/slate night
        }
    }
    
    public var statusBackgroundColor: Color {
        statusColor.opacity(0.16)
    }
    
    public var statusBorderColor: Color {
        statusColor.opacity(0.45)
    }
}

public struct CallHourSegment: Identifiable {
    public var id: Int { hour }
    public let hour: Int
    public let targetHour: Int
    public let suitability: CallSuitability
    public let isCurrent: Bool
}

public struct CallOverlapCalculator {
    public static func evaluateSuitability(targetHour: Int) -> CallSuitability {
        switch targetHour {
        case 9...17: // 9 AM to 5:59 PM (Standard Business & Prime Call Hours)
            return .optimal
        case 8, 18, 19, 20: // 8 AM or 6 PM to 8:59 PM (Waking social hours)
            return .acceptable
        case 7, 21, 22: // 7 AM or 9 PM to 10:59 PM (Early / late)
            return .lateEvening
        default: // 11 PM to 6:59 AM (Late Night / Sleep)
            return .sleeping
        }
    }
    
    public static func currentSuitability(for timeZone: TimeZone, date: Date = Date()) -> CallSuitability {
        var calendar = Calendar.current
        calendar.timeZone = timeZone
        let hour = calendar.component(.hour, from: date)
        return evaluateSuitability(targetHour: hour)
    }
    
    public static func getNextOptimalWindowDescription(targetTimeZone: TimeZone, localTimeZone: TimeZone = .current, date: Date = Date()) -> String {
        var targetCalendar = Calendar.current
        targetCalendar.timeZone = targetTimeZone
        let targetHour = targetCalendar.component(.hour, from: date)
        let targetMinute = targetCalendar.component(.minute, from: date)
        
        if targetHour >= 9 && targetHour < 17 {
            let hoursRemaining = 17 - targetHour
            let minRemaining = 60 - targetMinute
            return "\(hoursRemaining)h \(minRemaining)m left in work hours"
        } else if targetHour < 9 {
            let hoursUntil = 9 - targetHour
            return "Opens in \(hoursUntil)h (at 9:00 AM there)"
        } else {
            let hoursUntil = (24 - targetHour) + 9
            return "Next good window: tomorrow 9:00 AM (\(hoursUntil)h away)"
        }
    }
    
    public static func calculateMutualWindow(targetTimeZone: TimeZone, localTimeZone: TimeZone = .current, date: Date = Date()) -> String {
        // Calculate when BOTH local and target are between 9 AM and 6 PM
        var mutualHours: [Int] = []
        
        for localHour in 0..<24 {
            var localCal = Calendar.current
            localCal.timeZone = localTimeZone
            guard let localDate = localCal.date(bySettingHour: localHour, minute: 0, second: 0, of: date) else { continue }
            
            var targetCal = Calendar.current
            targetCal.timeZone = targetTimeZone
            let targetHour = targetCal.component(.hour, from: localDate)
            
            let localGood = (localHour >= 9 && localHour <= 19)
            let targetGood = (targetHour >= 9 && targetHour <= 19)
            
            if localGood && targetGood {
                mutualHours.append(localHour)
            }
        }
        
        guard let first = mutualHours.first, let last = mutualHours.last else {
            return "No overlapping 9-6 working hours today"
        }
        
        let startAmPm = first >= 12 ? "PM" : "AM"
        let endAmPm = (last + 1) >= 12 ? "PM" : "AM"
        let start12 = first % 12 == 0 ? 12 : first % 12
        let end12 = (last + 1) % 12 == 0 ? 12 : (last + 1) % 12
        
        return "\(start12)\(startAmPm)–\(end12)\(endAmPm) your time"
    }
    
    public static func generate24HourTimeline(targetTimeZone: TimeZone, localTimeZone: TimeZone = .current, baseDate: Date = Date()) -> [CallHourSegment] {
        var segments: [CallHourSegment] = []
        var localCalendar = Calendar.current
        localCalendar.timeZone = localTimeZone
        let currentLocalHour = localCalendar.component(.hour, from: baseDate)
        
        for localHour in 0..<24 {
            guard let stepDate = localCalendar.date(bySettingHour: localHour, minute: 0, second: 0, of: baseDate) else { continue }
            var targetCal = Calendar.current
            targetCal.timeZone = targetTimeZone
            let targetHour = targetCal.component(.hour, from: stepDate)
            let suitability = evaluateSuitability(targetHour: targetHour)
            
            segments.append(CallHourSegment(
                hour: localHour,
                targetHour: targetHour,
                suitability: suitability,
                isCurrent: localHour == currentLocalHour
            ))
        }
        return segments
    }
}
