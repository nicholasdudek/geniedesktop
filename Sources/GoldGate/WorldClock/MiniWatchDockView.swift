import SwiftUI

/// A slim, pinned dock of mini analog watch faces, one per pillow (plus local time).
/// Configured from the Settings menu via `MiniWatchDockSettings`.
public struct MiniWatchDockView: View {
    public let pillows: [PillowClock]
    public let date: Date
    public let localTimeZone: TimeZone
    public let settings: MiniWatchDockSettings
    public let onSelectPillow: (PillowClock) -> Void
    
    public init(
        pillows: [PillowClock],
        date: Date = Date(),
        localTimeZone: TimeZone = .current,
        settings: MiniWatchDockSettings = .default,
        onSelectPillow: @escaping (PillowClock) -> Void = { _ in }
    ) {
        self.pillows = pillows
        self.date = date
        self.localTimeZone = localTimeZone
        self.settings = settings
        self.onSelectPillow = onSelectPillow
    }
    
    private var diameter: CGFloat { settings.dialSize.diameter }
    
    public var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: settings.dialSize == .small ? 14 : 18) {
                if settings.showLocalTime {
                    localWatch
                    
                    if !pillows.isEmpty {
                        Rectangle()
                            .fill(Color.white.opacity(0.12))
                            .frame(width: 1, height: diameter * 0.8)
                    }
                }
                
                ForEach(pillows) { pillow in
                    Button {
                        #if os(iOS)
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()
                        #endif
                        onSelectPillow(pillow)
                    } label: {
                        watchItem(
                            timeZone: pillow.timeZone,
                            accent: pillow.accent.color,
                            label: pillow.displayName,
                            digital: pillow.formattedDigitalTime(for: date)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
        }
        .background(dockBackground)
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }
    
    // MARK: - Local Reference Watch
    private var localWatch: some View {
        let formatter = DateFormatter()
        formatter.timeZone = localTimeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "h:mm"
        return watchItem(
            timeZone: localTimeZone,
            accent: .orange,
            label: "Local",
            digital: formatter.string(from: date)
        )
    }
    
    // MARK: - Single Watch Item
    private func watchItem(timeZone: TimeZone, accent: Color, label: String, digital: String) -> some View {
        VStack(spacing: 4) {
            AnalogClockView(
                timeZone: timeZone,
                date: date,
                accentColor: accent,
                size: diameter,
                showSeconds: settings.showSeconds
            )
            
            if settings.showCityLabels {
                Text(label)
                    .font(.system(size: settings.dialSize == .small ? 9 : 10, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.75))
                    .lineLimit(1)
                    .frame(maxWidth: max(diameter + 16, 52))
            }
            
            if settings.showDigitalTime {
                Text(digital)
                    .font(.system(size: settings.dialSize == .small ? 9 : 10, weight: .bold, design: .monospaced))
                    .monospacedDigit()
                    .foregroundColor(accent)
            }
        }
    }
    
    // MARK: - Dock Background
    private var dockBackground: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(Color(red: 0.07, green: 0.07, blue: 0.09).opacity(0.96))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.2), Color.white.opacity(0.04), Color.orange.opacity(0.25)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: Color.black.opacity(0.7), radius: 10, y: 4)
    }
}
