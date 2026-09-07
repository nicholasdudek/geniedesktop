import SwiftUI

public enum WatchDialStyle: String, CaseIterable, Codable, Identifiable {
    case classicChronometer = "Chronometer"
    case modernBlackout = "Blackout Minimal"
    case aviationFluted = "Aviation"
    case solarLume = "Solar Lume"
    
    public var id: String { rawValue }
}

public struct AnalogClockView: View {
    public let timeZone: TimeZone
    public let date: Date
    public let accentColor: Color
    public let size: CGFloat
    public let showSeconds: Bool
    public var dialStyle: WatchDialStyle = .classicChronometer
    
    public init(
        timeZone: TimeZone,
        date: Date = Date(),
        accentColor: Color = .orange,
        size: CGFloat = 64,
        showSeconds: Bool = false,
        dialStyle: WatchDialStyle = .classicChronometer
    ) {
        self.timeZone = timeZone
        self.date = date
        self.accentColor = accentColor
        self.size = size
        self.showSeconds = showSeconds
        self.dialStyle = dialStyle
    }
    
    private var calendar: Calendar {
        var cal = Calendar.current
        cal.timeZone = timeZone
        return cal
    }
    
    private var hour: Double {
        let h = Double(calendar.component(.hour, from: date) % 12)
        let m = Double(calendar.component(.minute, from: date))
        let s = Double(calendar.component(.second, from: date))
        let nanoseconds = Double(calendar.component(.nanosecond, from: date))
        return h + (m / 60.0) + ((s + nanoseconds / 1_000_000_000.0) / 3600.0)
    }
    
    private var minute: Double {
        let m = Double(calendar.component(.minute, from: date))
        let s = Double(calendar.component(.second, from: date))
        return m + (s / 60.0)
    }
    
    private var second: Double {
        let s = Double(calendar.component(.second, from: date))
        return s
    }
    
    private var isDaytime: Bool {
        let rawHour = calendar.component(.hour, from: date)
        return rawHour >= 6 && rawHour < 18
    }
    
    public var body: some View {
        ZStack {
            // 1. Multi-layered Bezel Rim
            Circle()
                .fill(
                    RadialGradient(
                        colors: isDaytime
                            ? [Color(red: 0.12, green: 0.12, blue: 0.14), Color(red: 0.05, green: 0.05, blue: 0.06), Color.black]
                            : [Color(red: 0.06, green: 0.08, blue: 0.14), Color(red: 0.03, green: 0.04, blue: 0.07), Color.black],
                        center: .center,
                        startRadius: 0,
                        endRadius: size / 2
                    )
                )
                .overlay(
                    // Luxury Steel / Obsidian Outer Ring
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.35),
                                    Color.white.opacity(0.06),
                                    accentColor.opacity(0.4),
                                    Color.white.opacity(0.04)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: max(1.2, size * 0.03)
                        )
                )
                .overlay(
                    Circle()
                        .stroke(Color.black, lineWidth: 1)
                        .padding(max(1, size * 0.02))
                )
                .shadow(color: Color.black.opacity(0.85), radius: 8, x: 0, y: 4)
            
            // 2. 60-Second Micro Ticks
            if size >= 54 {
                ForEach(0..<60) { tick in
                    if tick % 5 != 0 {
                        Rectangle()
                            .fill(Color.white.opacity(0.2))
                            .frame(width: max(0.6, size * 0.01), height: size * 0.035)
                            .offset(y: -(size / 2) + (size * 0.065))
                            .rotationEffect(.degrees(Double(tick) * 6))
                    }
                }
            }
            
            // 3. 12 Major Hour Markers
            ForEach(0..<12) { tick in
                let isCardinal = (tick % 3 == 0)
                Capsule()
                    .fill(
                        isCardinal
                            ? LinearGradient(colors: [Color.white, Color.white.opacity(0.8)], startPoint: .top, endPoint: .bottom)
                            : LinearGradient(colors: [Color.white.opacity(0.6), Color.white.opacity(0.3)], startPoint: .top, endPoint: .bottom)
                    )
                    .frame(
                        width: isCardinal ? max(2.2, size * 0.04) : max(1.2, size * 0.022),
                        height: isCardinal ? size * 0.12 : size * 0.075
                    )
                    .offset(y: -(size / 2) + (size * 0.08))
                    .rotationEffect(.degrees(Double(tick) * 30))
            }
            
            // 4. Numerals (12, 3, 6, 9) on large dials
            if size >= 90 {
                ForEach([12, 3, 6, 9], id: \.self) { num in
                    Text("\(num)")
                        .font(.system(size: size * 0.12, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                        .offset(
                            x: num == 3 ? (size * 0.31) : (num == 9 ? -(size * 0.31) : 0),
                            y: num == 12 ? -(size * 0.31) : (num == 6 ? (size * 0.31) : 0)
                        )
                }
            }
            
            // 5. Day/Night Astronomical Sub-Indicator
            if size >= 80 {
                VStack(spacing: 1) {
                    Image(systemName: isDaytime ? "sun.max.fill" : "moon.stars.fill")
                        .font(.system(size: size * 0.09, weight: .semibold))
                        .foregroundColor(isDaytime ? .yellow.opacity(0.9) : Color(red: 0.65, green: 0.7, blue: 1.0))
                }
                .offset(y: -(size * 0.16))
            }
            
            // 6. Precision Hour Hand (Sword / Lume Style)
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            colors: [Color.white, Color(white: 0.85)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: max(2.8, size * 0.05), height: size * 0.28)
                
                // Lume center strip
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color(white: 0.15))
                    .frame(width: max(1, size * 0.016), height: size * 0.18)
                    .padding(.bottom, size * 0.04)
            }
            .offset(y: -(size * 0.14) + (size * 0.035))
            .rotationEffect(.degrees(hour * 30))
            .shadow(color: Color.black.opacity(0.7), radius: 3, x: 1, y: 2)
            
            // 7. Precision Minute Hand
            ZStack(alignment: .bottom) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        LinearGradient(
                            colors: [Color.white, Color(white: 0.9)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: max(2.0, size * 0.035), height: size * 0.39)
                
                // Lume center strip
                RoundedRectangle(cornerRadius: 1)
                    .fill(Color(white: 0.15))
                    .frame(width: max(0.8, size * 0.012), height: size * 0.26)
                    .padding(.bottom, size * 0.05)
            }
            .offset(y: -(size * 0.195) + (size * 0.035))
            .rotationEffect(.degrees(minute * 6))
            .shadow(color: Color.black.opacity(0.7), radius: 4, x: 1, y: 2)
            
            // 8. Ticking / Sweeping Second Hand with Counterweight
            if showSeconds || size >= 70 {
                ZStack {
                    // Needle & Counterweight
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(accentColor)
                            .frame(width: max(1.1, size * 0.018), height: size * 0.44)
                        
                        Circle()
                            .fill(accentColor)
                            .frame(width: max(3.5, size * 0.06), height: max(3.5, size * 0.06))
                        
                        Rectangle()
                            .fill(accentColor)
                            .frame(width: max(1.5, size * 0.024), height: size * 0.10)
                    }
                    .offset(y: -(size * 0.17))
                }
                .rotationEffect(.degrees(second * 6))
                .shadow(color: accentColor.opacity(0.4), radius: 3)
            }
            
            // 9. Precision Center Pivot Jewel
            Circle()
                .fill(accentColor)
                .frame(width: max(4.5, size * 0.08), height: max(4.5, size * 0.08))
                .overlay(
                    Circle()
                        .stroke(Color.black, lineWidth: 1.5)
                )
                .overlay(
                    Circle()
                        .fill(Color.white.opacity(0.8))
                        .frame(width: max(1.5, size * 0.025), height: max(1.5, size * 0.025))
                )
        }
        .frame(width: size, height: size)
    }
}
