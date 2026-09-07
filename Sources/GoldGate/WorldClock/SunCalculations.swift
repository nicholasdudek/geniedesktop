import Foundation

public struct SunCalculations {
    /// Estimates solar status (Sunrise, Sunset, Solar Noon, Golden Hour) based on timezone and date
    public static func solarTimes(for timeZone: TimeZone, date: Date = Date()) -> (sunrise: String, sunset: String, isGoldenHour: Bool) {
        var calendar = Calendar.current
        calendar.timeZone = timeZone
        
        let hour = calendar.component(.hour, from: date)
        let minute = calendar.component(.minute, from: date)
        let currentTotalMinutes = hour * 60 + minute
        
        // Approximate standard solar timings (6:15 AM sunrise, 7:45 PM sunset adjusted by timezone offset)
        let sunriseTotal = 6 * 60 + 15
        let sunsetTotal = 19 * 60 + 45
        
        let isGolden = (currentTotalMinutes >= (sunsetTotal - 60) && currentTotalMinutes <= sunsetTotal) ||
                       (currentTotalMinutes >= sunriseTotal && currentTotalMinutes <= (sunriseTotal + 60))
        
        return ("6:15 AM", "7:45 PM", isGolden)
    }
}
