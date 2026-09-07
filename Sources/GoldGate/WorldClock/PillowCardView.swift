import SwiftUI

public struct PillowCardView: View {
    public let pillow: PillowClock
    public let date: Date
    public let localTimeZone: TimeZone
    public let isEditing: Bool
    public let onSizeToggle: (PillowSize) -> Void
    public let onEdit: () -> Void
    public let onDelete: () -> Void
    
    public init(
        pillow: PillowClock,
        date: Date = Date(),
        localTimeZone: TimeZone = .current,
        isEditing: Bool = false,
        onSizeToggle: @escaping (PillowSize) -> Void = { _ in },
        onEdit: @escaping () -> Void = {},
        onDelete: @escaping () -> Void = {}
    ) {
        self.pillow = pillow
        self.date = date
        self.localTimeZone = localTimeZone
        self.isEditing = isEditing
        self.onSizeToggle = onSizeToggle
        self.onEdit = onEdit
        self.onDelete = onDelete
    }
    
    private var isDaytime: Bool {
        pillow.isDaytime(for: date)
    }
    
    private var relativeOffset: String {
        pillow.relativeOffsetDescription(referenceDate: date, localTimeZone: localTimeZone)
    }
    
    private var formattedLocalTime: String {
        let formatter = DateFormatter()
        formatter.timeZone = localTimeZone
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: date)
    }
    
    private var formattedTargetTime: String {
        pillow.formattedDigitalTime(for: date, includeSeconds: pillow.showSeconds)
    }
    
    private var formattedAmPm: String {
        pillow.formattedAmPm(for: date)
    }
    
    private var suitability: CallSuitability {
        CallOverlapCalculator.currentSuitability(for: pillow.timeZone, date: date)
    }
    
    private var solarInfo: (sunrise: String, sunset: String, isGoldenHour: Bool) {
        SunCalculations.solarTimes(for: pillow.timeZone, date: date)
    }
    
    public var body: some View {
        ZStack {
            // Main Blackout Pillow Body
            pillowBackground
            
            // Content Layer based on Size
            Group {
                switch pillow.size {
                case .compact:
                    compactLayout
                case .regular:
                    regularLayout
                case .large:
                    largeLayout
                case .hero:
                    heroLayout
                }
            }
            .padding(.horizontal, pillow.size == .compact ? 16 : (pillow.size == .hero ? 22 : 18))
            .padding(.vertical, pillow.size == .compact ? 12 : 16)
            
            // Delete badge in edit mode
            if isEditing {
                VStack {
                    HStack {
                        Button(action: {
                            #if os(iOS)
                            let generator = UIImpactFeedbackGenerator(style: .medium)
                            generator.impactOccurred()
                            #endif
                            onDelete()
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.red)
                                .background(Circle().fill(Color.white).padding(2))
                        }
                        .offset(x: -6, y: -6)
                        
                        Spacer()
                        
                        Button(action: {
                            #if os(iOS)
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            #endif
                            onEdit()
                        }) {
                            Image(systemName: "slider.horizontal.3")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                                .padding(7)
                                .background(Circle().fill(Color.white.opacity(0.2)))
                        }
                        .offset(x: 6, y: -6)
                    }
                    Spacer()
                }
            }
        }
        .frame(minHeight: pillow.size.height)
        .contextMenu {
            Menu {
                ForEach(PillowSize.allCases) { sz in
                    Button {
                        #if os(iOS)
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        #endif
                        onSizeToggle(sz)
                    } label: {
                        Label(sz.rawValue, systemImage: sz.icon)
                    }
                }
            } label: {
                Label("Change Pillow Size", systemImage: "arrow.up.left.and.down.right.and.arrow.up.right.and.down.left")
            }
            
            Button(action: onEdit) {
                Label("Customize Pillow & Accents", systemImage: "pencil.circle")
            }
            
            Button(role: .destructive, action: onDelete) {
                Label("Remove Pillow", systemImage: "trash")
            }
        }
    }
    
    // MARK: - Blackout Pillow Background
    private var pillowBackground: some View {
        RoundedRectangle(cornerRadius: pillow.size.cornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color(red: 0.08, green: 0.08, blue: 0.095),
                        Color(red: 0.035, green: 0.035, blue: 0.045),
                        Color.black
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                // Multi-stop specular rim border
                RoundedRectangle(cornerRadius: pillow.size.cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            stops: [
                                .init(color: Color.white.opacity(0.22), location: 0.0),
                                .init(color: Color.white.opacity(0.04), location: 0.35),
                                .init(color: pillow.accent.color.opacity(0.28), location: 0.75),
                                .init(color: Color.white.opacity(0.02), location: 1.0)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )
            )
            .shadow(color: Color.black.opacity(0.85), radius: 12, x: 0, y: 5)
            .overlay(
                // Ambient backlight glow
                RoundedRectangle(cornerRadius: pillow.size.cornerRadius, style: .continuous)
                    .fill(
                        RadialGradient(
                            colors: [pillow.accent.color.opacity(0.05), Color.clear],
                            center: .bottomTrailing,
                            startRadius: 0,
                            endRadius: 160
                        )
                    )
                    .allowsHitTesting(false)
            )
    }
    
    // MARK: - 1. Compact Layout (Slim Pill)
    private var compactLayout: some View {
        HStack(spacing: 12) {
            if pillow.showAnalogDial {
                AnalogClockView(
                    timeZone: pillow.timeZone,
                    date: date,
                    accentColor: pillow.accent.color,
                    size: 42,
                    showSeconds: false
                )
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(pillow.displayName)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    if pillow.showDayNightIndicator {
                        Image(systemName: isDaytime ? "sun.max.fill" : "moon.stars.fill")
                            .font(.system(size: 11))
                            .foregroundColor(isDaytime ? .yellow : .indigo)
                    }
                }
                
                Text(relativeOffset)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.55))
            }
            
            Spacer()
            
            // Calling indicator & Digital Time
            VStack(alignment: .trailing, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(formattedTargetTime)
                        .font(.system(size: 26, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(.white)
                    Text(formattedAmPm)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(pillow.accent.color)
                }
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(suitability.statusColor)
                        .frame(width: 6, height: 6)
                    Text(suitability.badgeText)
                        .font(.system(size: 10, weight: .medium, design: .rounded))
                        .foregroundColor(suitability.statusColor)
                }
            }
        }
    }
    
    // MARK: - 2. Regular Layout (Standard Pillow Card)
    private var regularLayout: some View {
        VStack(spacing: 10) {
            HStack(alignment: .center, spacing: 14) {
                // Left: Analog Dial
                if pillow.showAnalogDial {
                    AnalogClockView(
                        timeZone: pillow.timeZone,
                        date: date,
                        accentColor: pillow.accent.color,
                        size: 58,
                        showSeconds: pillow.showSeconds
                    )
                }
                
                // Center: City & Offset Info
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(pillow.displayName)
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        if pillow.showDayNightIndicator {
                            Image(systemName: isDaytime ? "sun.max.fill" : "moon.stars.fill")
                                .font(.system(size: 12))
                                .foregroundColor(isDaytime ? .yellow : Color(red: 0.6, green: 0.65, blue: 1.0))
                        }
                    }
                    
                    Text(relativeOffset)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.6))
                    
                    // Time difference comparison line
                    HStack(spacing: 4) {
                        Image(systemName: "clock.arrow.2.circlepath")
                            .font(.system(size: 9))
                        Text("Here: \(formattedLocalTime)")
                    }
                    .font(.system(size: 11, weight: .regular, design: .monospaced))
                    .foregroundColor(Color.white.opacity(0.42))
                }
                
                Spacer()
                
                // Right: Big Digital Display
                VStack(alignment: .trailing, spacing: 1) {
                    HStack(alignment: .firstTextBaseline, spacing: 3) {
                        Text(formattedTargetTime)
                            .font(.system(size: 34, weight: .light, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(.white)
                        Text(formattedAmPm)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(pillow.accent.color)
                    }
                    
                    Text(pillow.timeZoneAbbreviation(for: date))
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(Color.white.opacity(0.45))
                }
            }
            
            // Call Availability Mini Ribbon
            CallingWindowRibbonView(
                timeZone: pillow.timeZone,
                localTimeZone: localTimeZone,
                date: date,
                accentColor: pillow.accent.color,
                compactMode: true
            )
        }
    }
    
    // MARK: - 3. Large Layout (Expanded Pro Pillow)
    private var largeLayout: some View {
        VStack(spacing: 12) {
            HStack(alignment: .center, spacing: 16) {
                // Large Analog Dial
                if pillow.showAnalogDial {
                    AnalogClockView(
                        timeZone: pillow.timeZone,
                        date: date,
                        accentColor: pillow.accent.color,
                        size: 78,
                        showSeconds: true
                    )
                }
                
                // Details
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(pillow.displayName)
                            .font(.system(size: 24, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text(pillow.countryOrRegion)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(Color.white.opacity(0.5))
                    }
                    
                    Text(relativeOffset)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(pillow.accent.color)
                    
                    // Dual Time comparison line
                    HStack(spacing: 5) {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 10))
                        Text("When \(formattedLocalTime) here ➔ \(formattedTargetTime) \(formattedAmPm) there")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(Color.white.opacity(0.75))
                    .padding(.vertical, 2)
                    
                    // Solar details
                    HStack(spacing: 8) {
                        Label(solarInfo.sunrise, systemImage: "sunrise.fill")
                        Label(solarInfo.sunset, systemImage: "sunset.fill")
                    }
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(Color.white.opacity(0.45))
                }
                
                Spacer()
                
                // Big Digital Clock
                VStack(alignment: .trailing, spacing: 0) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(formattedTargetTime)
                            .font(.system(size: 40, weight: .light, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(.white)
                        Text(formattedAmPm)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(pillow.accent.color)
                    }
                    
                    Text(pillow.formattedDateShort(for: date))
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.5))
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.12))
            
            // Full 24-Hour Calling Timeline
            CallingWindowRibbonView(
                timeZone: pillow.timeZone,
                localTimeZone: localTimeZone,
                date: date,
                accentColor: pillow.accent.color,
                compactMode: false
            )
        }
    }
    
    // MARK: - 4. Hero Layout (Giant StandBy / Bedside Pillow)
    private var heroLayout: some View {
        VStack(spacing: 16) {
            // Header: City, Country, Badges
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 8) {
                        Text(pillow.displayName)
                            .font(.system(size: 28, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text(pillow.countryOrRegion.uppercased())
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(Color.white.opacity(0.45))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.white.opacity(0.08)))
                    }
                    
                    Text(pillow.formattedDateShort(for: date))
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.6))
                }
                
                Spacer()
                
                // Offset Pill
                Text(relativeOffset)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(pillow.accent.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(pillow.accent.color.opacity(0.12))
                            .overlay(Capsule().stroke(pillow.accent.color.opacity(0.3), lineWidth: 1))
                    )
            }
            
            // Main Hero Row: Massive Dial + Massive Digital
            HStack(spacing: 20) {
                AnalogClockView(
                    timeZone: pillow.timeZone,
                    date: date,
                    accentColor: pillow.accent.color,
                    size: 100,
                    showSeconds: true
                )
                
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        Text(formattedTargetTime)
                            .font(.system(size: 52, weight: .thin, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(.white)
                        Text(formattedAmPm)
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(pillow.accent.color)
                    }
                    
                    // Dual comparison callout
                    HStack(spacing: 6) {
                        Image(systemName: "globe.americas.fill")
                            .font(.system(size: 12))
                            .foregroundColor(pillow.accent.color)
                        Text("When here is \(formattedLocalTime) ➔ There is \(formattedTargetTime) \(formattedAmPm)")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(.white.opacity(0.85))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.06)))
                    
                    // Solar & Timezone Badges
                    HStack(spacing: 12) {
                        HStack(spacing: 4) {
                            Image(systemName: "sunrise.fill")
                                .foregroundColor(.yellow)
                            Text(solarInfo.sunrise)
                        }
                        HStack(spacing: 4) {
                            Image(systemName: "sunset.fill")
                                .foregroundColor(.orange)
                            Text(solarInfo.sunset)
                        }
                        Text(pillow.timeZoneIdentifier)
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(Color.white.opacity(0.6))
                }
                
                Spacer()
            }
            
            // Full Calling Overlap Banner & Timeline
            CallingWindowRibbonView(
                timeZone: pillow.timeZone,
                localTimeZone: localTimeZone,
                date: date,
                accentColor: pillow.accent.color,
                compactMode: false
            )
        }
    }
}
