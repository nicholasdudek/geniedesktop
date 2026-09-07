import SwiftUI

public struct TimeTravelScrubberView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: WorldClockViewModel
    @State private var offsetHours: Double = 0.0
    
    private var projectedDate: Date {
        Date().addingTimeInterval(offsetHours * 3600.0)
    }
    
    private var formattedLocalTime: String {
        let formatter = DateFormatter()
        formatter.timeZone = viewModel.localTimeZone
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: projectedDate)
    }
    
    private var formattedLocalDate: String {
        let formatter = DateFormatter()
        formatter.timeZone = viewModel.localTimeZone
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: projectedDate)
    }
    
    // Optimal call score for the projected time
    private var activeCallScore: (optimalCount: Int, totalCount: Int) {
        let optimal = viewModel.pillows.filter {
            CallOverlapCalculator.currentSuitability(for: $0.timeZone, date: projectedDate) == .optimal
        }.count
        return (optimal, viewModel.pillows.count)
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Top Interactive Scrubber Card
                    VStack(spacing: 14) {
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("WHEN IT'S HERE (LOCAL)")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(.orange)
                                Text(formattedLocalTime)
                                    .font(.system(size: 38, weight: .light, design: .rounded))
                                    .monospacedDigit()
                                    .foregroundColor(.white)
                                Text(formattedLocalDate)
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundColor(Color.white.opacity(0.6))
                            }
                            
                            Spacer()
                            
                            // Offset Pill & Score
                            VStack(alignment: .trailing, spacing: 6) {
                                Text(offsetHours == 0 ? "LIVE NOW" : String(format: "%+.1f hrs", offsetHours))
                                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                                    .foregroundColor(offsetHours == 0 ? .green : .orange)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(
                                        Capsule()
                                            .fill(offsetHours == 0 ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                                    )
                                
                                Text("\(activeCallScore.optimalCount)/\(activeCallScore.totalCount) In Work Hours")
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundColor(activeCallScore.optimalCount > 0 ? .green : .gray)
                            }
                        }
                        
                        // 24-Hour Slider (-12h to +12h)
                        VStack(spacing: 6) {
                            Slider(value: $offsetHours, in: -12...12, step: 0.5)
                                .tint(.orange)
                                .onChange(of: offsetHours) { _ in
                                    #if os(iOS)
                                    let generator = UIImpactFeedbackGenerator(style: .rigid)
                                    generator.impactOccurred(intensity: 0.4)
                                    #endif
                                }
                            
                            HStack {
                                Text("-12h")
                                Spacer()
                                Text("-6h")
                                Spacer()
                                Text("NOW")
                                Spacer()
                                Text("+6h")
                                Spacer()
                                Text("+12h")
                            }
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(Color.white.opacity(0.4))
                        }
                        
                        // Smart Golden Hour Shortcut
                        HStack(spacing: 8) {
                            Button {
                                findBestMutualHour()
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "sparkles")
                                    Text("Find Mutual Golden Window")
                                }
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(.black)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(Capsule().fill(Color.orange))
                            }
                            
                            Spacer()
                            
                            Button("Reset to Now") {
                                withAnimation(.spring()) {
                                    offsetHours = 0
                                }
                            }
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .padding(18)
                    .background(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .fill(Color(red: 0.09, green: 0.09, blue: 0.11))
                            .overlay(
                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    
                    // City List with Projected Times & Calling Status
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(viewModel.pillows) { pillow in
                                projectedPillowRow(pillow: pillow)
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .navigationTitle("Time Overlap & Call Advisor")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.orange)
                    .fontWeight(.bold)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func findBestMutualHour() {
        var bestOffset: Double = 0.0
        var maxScore = -1
        
        for hourStep in stride(from: -12.0, through: 12.0, by: 1.0) {
            let testDate = Date().addingTimeInterval(hourStep * 3600.0)
            let score = viewModel.pillows.filter {
                CallOverlapCalculator.currentSuitability(for: $0.timeZone, date: testDate) == .optimal
            }.count
            
            if score > maxScore {
                maxScore = score
                bestOffset = hourStep
            }
        }
        
        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
            offsetHours = bestOffset
        }
        
        #if os(iOS)
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        #endif
    }
    
    private func projectedPillowRow(pillow: PillowClock) -> some View {
        let formatter = DateFormatter()
        formatter.timeZone = pillow.timeZone
        formatter.dateFormat = "h:mm a"
        let projectedTargetTime = formatter.string(from: projectedDate)
        
        let dateDesc = pillow.relativeOffsetDescription(referenceDate: projectedDate, localTimeZone: viewModel.localTimeZone)
        let suitability = CallOverlapCalculator.currentSuitability(for: pillow.timeZone, date: projectedDate)
        
        return HStack(spacing: 14) {
            // Mini Analog Clock Dial
            AnalogClockView(
                timeZone: pillow.timeZone,
                date: projectedDate,
                accentColor: pillow.accent.color,
                size: 46,
                showSeconds: false
            )
            
            VStack(alignment: .leading, spacing: 3) {
                Text(pillow.displayName)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(dateDesc)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(Color.white.opacity(0.6))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(projectedTargetTime)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundColor(.white)
                
                HStack(spacing: 4) {
                    Image(systemName: suitability.iconName)
                        .font(.system(size: 10, weight: .bold))
                    Text(suitability.badgeText)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                }
                .foregroundColor(suitability.statusColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(suitability.statusBackgroundColor)
                        .overlay(Capsule().stroke(suitability.statusBorderColor, lineWidth: 0.8))
                )
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color(red: 0.08, green: 0.08, blue: 0.095))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }
}
