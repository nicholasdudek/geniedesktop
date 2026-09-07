import Foundation

public struct City: Identifiable, Hashable, Codable {
    public var id: String { "\(name)_\(timeZoneIdentifier)" }
    public let name: String
    public let countryOrRegion: String
    public let continent: String
    public let timeZoneIdentifier: String
    public let flag: String
    
    public init(name: String, countryOrRegion: String, continent: String, timeZoneIdentifier: String, flag: String) {
        self.name = name
        self.countryOrRegion = countryOrRegion
        self.continent = continent
        self.timeZoneIdentifier = timeZoneIdentifier
        self.flag = flag
    }
}

public struct CityDatabase {
    public static let defaultPillows: [PillowClock] = [
        PillowClock(
            cityName: "Cupertino",
            countryOrRegion: "United States",
            timeZoneIdentifier: "America/Los_Angeles",
            customLabel: "Apple Park HQ",
            size: .large,
            accent: .classicOrange,
            showAnalogDial: true,
            showSeconds: true,
            showDayNightIndicator: true
        ),
        PillowClock(
            cityName: "New York",
            countryOrRegion: "United States",
            timeZoneIdentifier: "America/New_York",
            customLabel: nil,
            size: .regular,
            accent: .amberGold,
            showAnalogDial: true,
            showSeconds: false,
            showDayNightIndicator: true
        ),
        PillowClock(
            cityName: "London",
            countryOrRegion: "United Kingdom",
            timeZoneIdentifier: "Europe/London",
            customLabel: nil,
            size: .regular,
            accent: .electricCyan,
            showAnalogDial: true,
            showSeconds: false,
            showDayNightIndicator: true
        ),
        PillowClock(
            cityName: "Tokyo",
            countryOrRegion: "Japan",
            timeZoneIdentifier: "Asia/Tokyo",
            customLabel: nil,
            size: .regular,
            accent: .crimsonRed,
            showAnalogDial: true,
            showSeconds: false,
            showDayNightIndicator: true
        ),
        PillowClock(
            cityName: "Sydney",
            countryOrRegion: "Australia",
            timeZoneIdentifier: "Australia/Sydney",
            customLabel: nil,
            size: .regular,
            accent: .neonEmerald,
            showAnalogDial: true,
            showSeconds: false,
            showDayNightIndicator: true
        )
    ]
    
    public static let curatedCities: [City] = [
        // Americas
        City(name: "Cupertino", countryOrRegion: "United States", continent: "North America", timeZoneIdentifier: "America/Los_Angeles", flag: "🇺🇸"),
        City(name: "San Francisco", countryOrRegion: "United States", continent: "North America", timeZoneIdentifier: "America/Los_Angeles", flag: "🇺🇸"),
        City(name: "Los Angeles", countryOrRegion: "United States", continent: "North America", timeZoneIdentifier: "America/Los_Angeles", flag: "🇺🇸"),
        City(name: "Seattle", countryOrRegion: "United States", continent: "North America", timeZoneIdentifier: "America/Los_Angeles", flag: "🇺🇸"),
        City(name: "Denver", countryOrRegion: "United States", continent: "North America", timeZoneIdentifier: "America/Denver", flag: "🇺🇸"),
        City(name: "Chicago", countryOrRegion: "United States", continent: "North America", timeZoneIdentifier: "America/Chicago", flag: "🇺🇸"),
        City(name: "Austin", countryOrRegion: "United States", continent: "North America", timeZoneIdentifier: "America/Chicago", flag: "🇺🇸"),
        City(name: "New York", countryOrRegion: "United States", continent: "North America", timeZoneIdentifier: "America/New_York", flag: "🇺🇸"),
        City(name: "Boston", countryOrRegion: "United States", continent: "North America", timeZoneIdentifier: "America/New_York", flag: "🇺🇸"),
        City(name: "Miami", countryOrRegion: "United States", continent: "North America", timeZoneIdentifier: "America/New_York", flag: "🇺🇸"),
        City(name: "Toronto", countryOrRegion: "Canada", continent: "North America", timeZoneIdentifier: "America/Toronto", flag: "🇨🇦"),
        City(name: "Vancouver", countryOrRegion: "Canada", continent: "North America", timeZoneIdentifier: "America/Vancouver", flag: "🇨🇦"),
        City(name: "Montreal", countryOrRegion: "Canada", continent: "North America", timeZoneIdentifier: "America/Montreal", flag: "🇨🇦"),
        City(name: "Mexico City", countryOrRegion: "Mexico", continent: "North America", timeZoneIdentifier: "America/Mexico_City", flag: "🇲🇽"),
        City(name: "Honolulu", countryOrRegion: "United States", continent: "North America", timeZoneIdentifier: "Pacific/Honolulu", flag: "🇺🇸"),
        City(name: "São Paulo", countryOrRegion: "Brazil", continent: "South America", timeZoneIdentifier: "America/Sao_Paulo", flag: "🇧🇷"),
        City(name: "Rio de Janeiro", countryOrRegion: "Brazil", continent: "South America", timeZoneIdentifier: "America/Sao_Paulo", flag: "🇧🇷"),
        City(name: "Buenos Aires", countryOrRegion: "Argentina", continent: "South America", timeZoneIdentifier: "America/Argentina/Buenos_Aires", flag: "🇦🇷"),
        City(name: "Santiago", countryOrRegion: "Chile", continent: "South America", timeZoneIdentifier: "America/Santiago", flag: "🇨🇱"),
        City(name: "Bogotá", countryOrRegion: "Colombia", continent: "South America", timeZoneIdentifier: "America/Bogota", flag: "🇨🇴"),
        City(name: "Lima", countryOrRegion: "Peru", continent: "South America", timeZoneIdentifier: "America/Lima", flag: "🇵🇪"),

        // Europe
        City(name: "London", countryOrRegion: "United Kingdom", continent: "Europe", timeZoneIdentifier: "Europe/London", flag: "🇬🇧"),
        City(name: "Dublin", countryOrRegion: "Ireland", continent: "Europe", timeZoneIdentifier: "Europe/Dublin", flag: "🇮🇪"),
        City(name: "Paris", countryOrRegion: "France", continent: "Europe", timeZoneIdentifier: "Europe/Paris", flag: "🇫🇷"),
        City(name: "Berlin", countryOrRegion: "Germany", continent: "Europe", timeZoneIdentifier: "Europe/Berlin", flag: "🇩🇪"),
        City(name: "Frankfurt", countryOrRegion: "Germany", continent: "Europe", timeZoneIdentifier: "Europe/Berlin", flag: "🇩🇪"),
        City(name: "Amsterdam", countryOrRegion: "Netherlands", continent: "Europe", timeZoneIdentifier: "Europe/Amsterdam", flag: "🇳🇱"),
        City(name: "Madrid", countryOrRegion: "Spain", continent: "Europe", timeZoneIdentifier: "Europe/Madrid", flag: "🇪🇸"),
        City(name: "Barcelona", countryOrRegion: "Spain", continent: "Europe", timeZoneIdentifier: "Europe/Madrid", flag: "🇪🇸"),
        City(name: "Rome", countryOrRegion: "Italy", continent: "Europe", timeZoneIdentifier: "Europe/Rome", flag: "🇮🇹"),
        City(name: "Milan", countryOrRegion: "Italy", continent: "Europe", timeZoneIdentifier: "Europe/Rome", flag: "🇮🇹"),
        City(name: "Zurich", countryOrRegion: "Switzerland", continent: "Europe", timeZoneIdentifier: "Europe/Zurich", flag: "🇨🇭"),
        City(name: "Geneva", countryOrRegion: "Switzerland", continent: "Europe", timeZoneIdentifier: "Europe/Zurich", flag: "🇨🇭"),
        City(name: "Vienna", countryOrRegion: "Austria", continent: "Europe", timeZoneIdentifier: "Europe/Vienna", flag: "🇦🇹"),
        City(name: "Stockholm", countryOrRegion: "Sweden", continent: "Europe", timeZoneIdentifier: "Europe/Stockholm", flag: "🇸🇪"),
        City(name: "Oslo", countryOrRegion: "Norway", continent: "Europe", timeZoneIdentifier: "Europe/Oslo", flag: "🇳🇴"),
        City(name: "Copenhagen", countryOrRegion: "Denmark", continent: "Europe", timeZoneIdentifier: "Europe/Copenhagen", flag: "🇩🇰"),
        City(name: "Helsinki", countryOrRegion: "Finland", continent: "Europe", timeZoneIdentifier: "Europe/Helsinki", flag: "🇫🇮"),
        City(name: "Athens", countryOrRegion: "Greece", continent: "Europe", timeZoneIdentifier: "Europe/Athens", flag: "🇬🇷"),
        City(name: "Warsaw", countryOrRegion: "Poland", continent: "Europe", timeZoneIdentifier: "Europe/Warsaw", flag: "🇵🇱"),
        City(name: "Prague", countryOrRegion: "Czech Republic", continent: "Europe", timeZoneIdentifier: "Europe/Prague", flag: "🇨🇿"),
        City(name: "Lisbon", countryOrRegion: "Portugal", continent: "Europe", timeZoneIdentifier: "Europe/Lisbon", flag: "🇵🇹"),
        City(name: "Istanbul", countryOrRegion: "Turkey", continent: "Europe", timeZoneIdentifier: "Europe/Istanbul", flag: "🇹🇷"),

        // Asia & Middle East
        City(name: "Tokyo", countryOrRegion: "Japan", continent: "Asia", timeZoneIdentifier: "Asia/Tokyo", flag: "🇯🇵"),
        City(name: "Osaka", countryOrRegion: "Japan", continent: "Asia", timeZoneIdentifier: "Asia/Tokyo", flag: "🇯🇵"),
        City(name: "Kyoto", countryOrRegion: "Japan", continent: "Asia", timeZoneIdentifier: "Asia/Tokyo", flag: "🇯🇵"),
        City(name: "Seoul", countryOrRegion: "South Korea", continent: "Asia", timeZoneIdentifier: "Asia/Seoul", flag: "🇰🇷"),
        City(name: "Singapore", countryOrRegion: "Singapore", continent: "Asia", timeZoneIdentifier: "Asia/Singapore", flag: "🇸🇬"),
        City(name: "Hong Kong", countryOrRegion: "Hong Kong", continent: "Asia", timeZoneIdentifier: "Asia/Hong_Kong", flag: "🇭🇰"),
        City(name: "Taipei", countryOrRegion: "Taiwan", continent: "Asia", timeZoneIdentifier: "Asia/Taipei", flag: "🇹🇼"),
        City(name: "Beijing", countryOrRegion: "China", continent: "Asia", timeZoneIdentifier: "Asia/Shanghai", flag: "🇨🇳"),
        City(name: "Shanghai", countryOrRegion: "China", continent: "Asia", timeZoneIdentifier: "Asia/Shanghai", flag: "🇨🇳"),
        City(name: "Shenzhen", countryOrRegion: "China", continent: "Asia", timeZoneIdentifier: "Asia/Shanghai", flag: "🇨🇳"),
        City(name: "Bangkok", countryOrRegion: "Thailand", continent: "Asia", timeZoneIdentifier: "Asia/Bangkok", flag: "🇹🇭"),
        City(name: "Kuala Lumpur", countryOrRegion: "Malaysia", continent: "Asia", timeZoneIdentifier: "Asia/Kuala_Lumpur", flag: "🇲🇾"),
        City(name: "Jakarta", countryOrRegion: "Indonesia", continent: "Asia", timeZoneIdentifier: "Asia/Jakarta", flag: "🇮🇩"),
        City(name: "Manila", countryOrRegion: "Philippines", continent: "Asia", timeZoneIdentifier: "Asia/Manila", flag: "🇵🇭"),
        City(name: "Ho Chi Minh City", countryOrRegion: "Vietnam", continent: "Asia", timeZoneIdentifier: "Asia/Ho_Chi_Minh", flag: "🇻🇳"),
        City(name: "Mumbai", countryOrRegion: "India", continent: "Asia", timeZoneIdentifier: "Asia/Kolkata", flag: "🇮🇳"),
        City(name: "New Delhi", countryOrRegion: "India", continent: "Asia", timeZoneIdentifier: "Asia/Kolkata", flag: "🇮🇳"),
        City(name: "Bengaluru", countryOrRegion: "India", continent: "Asia", timeZoneIdentifier: "Asia/Kolkata", flag: "🇮🇳"),
        City(name: "Dubai", countryOrRegion: "United Arab Emirates", continent: "Middle East", timeZoneIdentifier: "Asia/Dubai", flag: "🇦🇪"),
        City(name: "Abu Dhabi", countryOrRegion: "United Arab Emirates", continent: "Middle East", timeZoneIdentifier: "Asia/Dubai", flag: "🇦🇪"),
        City(name: "Doha", countryOrRegion: "Qatar", continent: "Middle East", timeZoneIdentifier: "Asia/Qatar", flag: "🇶🇦"),
        City(name: "Riyadh", countryOrRegion: "Saudi Arabia", continent: "Middle East", timeZoneIdentifier: "Asia/Riyadh", flag: "🇸🇦"),
        City(name: "Tel Aviv", countryOrRegion: "Israel", continent: "Middle East", timeZoneIdentifier: "Asia/Jerusalem", flag: "🇮🇱"),

        // Oceania
        City(name: "Sydney", countryOrRegion: "Australia", continent: "Oceania", timeZoneIdentifier: "Australia/Sydney", flag: "🇦🇺"),
        City(name: "Melbourne", countryOrRegion: "Australia", continent: "Oceania", timeZoneIdentifier: "Australia/Melbourne", flag: "🇦🇺"),
        City(name: "Brisbane", countryOrRegion: "Australia", continent: "Oceania", timeZoneIdentifier: "Australia/Brisbane", flag: "🇦🇺"),
        City(name: "Perth", countryOrRegion: "Australia", continent: "Oceania", timeZoneIdentifier: "Australia/Perth", flag: "🇦🇺"),
        City(name: "Auckland", countryOrRegion: "New Zealand", continent: "Oceania", timeZoneIdentifier: "Pacific/Auckland", flag: "🇳🇿"),
        City(name: "Wellington", countryOrRegion: "New Zealand", continent: "Oceania", timeZoneIdentifier: "Pacific/Auckland", flag: "🇳🇿"),

        // Africa
        City(name: "Cairo", countryOrRegion: "Egypt", continent: "Africa", timeZoneIdentifier: "Africa/Cairo", flag: "🇪🇬"),
        City(name: "Johannesburg", countryOrRegion: "South Africa", continent: "Africa", timeZoneIdentifier: "Africa/Johannesburg", flag: "🇿🇦"),
        City(name: "Cape Town", countryOrRegion: "South Africa", continent: "Africa", timeZoneIdentifier: "Africa/Johannesburg", flag: "🇿🇦"),
        City(name: "Nairobi", countryOrRegion: "Kenya", continent: "Africa", timeZoneIdentifier: "Africa/Nairobi", flag: "🇰🇪"),
        City(name: "Lagos", countryOrRegion: "Nigeria", continent: "Africa", timeZoneIdentifier: "Africa/Lagos", flag: "🇳🇬"),
        City(name: "Casablanca", countryOrRegion: "Morocco", continent: "Africa", timeZoneIdentifier: "Africa/Casablanca", flag: "🇲🇦")
    ]
    
    public static func allAvailableCities() -> [City] {
        var results = curatedCities
        let existingIds = Set(results.map { $0.timeZoneIdentifier })
        
        for identifier in TimeZone.knownTimeZoneIdentifiers.sorted() {
            if !existingIds.contains(identifier) {
                let parts = identifier.split(separator: "/")
                if parts.count >= 2 {
                    let continent = String(parts[0]).replacingOccurrences(of: "_", with: " ")
                    let cityName = String(parts.last!).replacingOccurrences(of: "_", with: " ")
                    results.append(City(
                        name: cityName,
                        countryOrRegion: continent,
                        continent: continent,
                        timeZoneIdentifier: identifier,
                        flag: "🌐"
                    ))
                }
            }
        }
        return results
    }
    
    public static func search(query: String) -> [City] {
        let clean = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !clean.isEmpty else { return curatedCities }
        return allAvailableCities().filter {
            $0.name.lowercased().contains(clean) ||
            $0.countryOrRegion.lowercased().contains(clean) ||
            $0.continent.lowercased().contains(clean) ||
            $0.timeZoneIdentifier.lowercased().contains(clean)
        }
    }
}
