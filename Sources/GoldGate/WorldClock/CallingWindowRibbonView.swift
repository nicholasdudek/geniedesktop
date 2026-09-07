import SwiftUI

public struct CallingWindowRibbonView: View {
    public let timeZone: TimeZone
    public let localTimeZone: TimeZone
    public let date: Date
    public let accentColor: Color
    public var compactMode: Bool = false
    
    public init(
        timeZone: TimeZone,
        localTimeZone: TimeZone = .current,
        date: Date = Date(),
        accentColor: Color = .orange,
        compactMode: Bool = false
    ) {
        self.timeZone = timeZone
        self.localTimeZone = localTimeZone
        self.date = date
        self.accentColor = accentColor
        self.compactMode = compactMode
    }
    
    private var suitability: CallSuitability {
        CallOverlapCalculator.currentSuitability(for: timeZone, date: date)
    }
    
    private var nextWindowDescription: String {
        CallOverlapCalculator.getNextOptimalWindowDescription(targetTimeZone: timeZone, localTimeZone: localTimeZone, date: date)
    }
    
    private var mutualWindow: String {
        CallOverlapCalculator.calculateMutualWindow(targetTimeZone: timeZone, localTimeZone: localTimeZone, date: date)
    }
    
    private var timeline: [CallHourSegment] {
        CallOverlapCalculator.generate24HourTimeline(targetTimeZone: timeZone, localTimeZone: localTimeZone, baseDate: date)
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: compactMode ? 4 : 8) {
            // Status & Recommendation Banner
            HStack(spacing: 6) {
                HStack(spacing: 5) {
                    Image(systemName: suitability.iconName)
                        .font(.system(size: compactMode ? 10 : 12, weight: .bold))
                    Text(suitability.badgeText)
                        .font(.system(size: compactMode ? 11 : 12, weight: .semibold, design: .rounded))
                }
                .foregroundColor(suitability.statusColor)
                .padding(.horizontal, compactMode ? 8 : 10)
                .padding(.vertical, compactMode ? 3 : 5)
                .background(
                    Capsule()
                        .fill(suitability.statusBackgroundColor)
                        .overlay(
                            Capsule()
                                .stroke(suitability.statusBorderColor, lineWidth: 1)
                        )
                )
                
                Spacer()
                
                Text(nextWindowDescription)
                    .font(.system(size: compactMode ? 10 : 11, weight: .medium, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.65))
                    .lineLimit(1)
            }
            
            // 24-Hour Interactive Visual Ribbon
            if !compactMode {
                VStack(spacing: 4) {
                    GeometryReader { geo in
                        let blockWidth = (geo.size.width - CGFloat(timeline.count - 1) * 2) / CGFloat(timeline.count)
                        
                        HStack(spacing: 2) {
                            ForEach(timeline) { segment in
                                VStack(spacing: 2) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(
                                            segment.isCurrent
                                                ? suitability.statusColor
                                                : segment.suitability.statusColor.opacity(segment.suitability == .optimal ? 0.85 : 0.35)
                                        )
                                        .frame(width: max(2, blockWidth), height: segment.isCurrent ? 14 : 9)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 3)
                                                .stroke(Color.white.opacity(segment.isCurrent ? 0.9 : 0), lineWidth: 1.5)
                                        )
                                        .shadow(color: segment.isCurrent ? suitability.statusColor.opacity(0.8) : Color.clear, radius: 4)
                                }
                            }
                        }
                    }
                    .frame(height: 16)
                    
                    // Hour labels (Every 6 hours)
                    HStack {
                        Text("12 AM")
                        Spacer()
                        Text("6 AM")
                        Spacer()
                        Text("12 PM")
                        Spacer()
                        Text("6 PM")
                        Spacer()
                        Text("11 PM")
                    }
                    .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                    .foregroundColor(Color.white.opacity(0.4))
                }
                
                // Mutual window note
                HStack(spacing: 4) {
                    Image(systemName: "person.2.wave.2.fill")
                        .font(.system(size: 9))
                        .foregroundColor(Color.white.opacity(0.5))
                    Text("Mutual Calling Window: \(mutualWindow)")
                        .font(.system(size: 10, weight: .regular, design: .rounded))
                        .foregroundColor(Color.white.opacity(0.55))
                }
                .padding(.top, 2)
            }
        }
    }
}
