import SwiftUI

/// A hand-built analog face — no images, no assets. Every tick, marker and hand is
/// drawn from `size`, so one view serves the 40pt dial on a compact card and the
/// 168pt dial on a hero card.
public struct GenieAnalogWatchFace: View {
    public let date: Date
    public let calendar: Calendar
    public let size: CGFloat
    public let accent: Color
    public let showSeconds: Bool

    public init(
        date: Date,
        calendar: Calendar,
        size: CGFloat,
        accent: Color,
        showSeconds: Bool = false
    ) {
        self.date = date
        self.calendar = calendar
        self.size = size
        self.accent = accent
        self.showSeconds = showSeconds
    }

    /// Fractional components so the hands sweep instead of stepping.
    private var components: (hour: Double, minute: Double, second: Double) {
        let c = calendar.dateComponents([.hour, .minute, .second, .nanosecond], from: date)
        let second = Double(c.second ?? 0) + Double(c.nanosecond ?? 0) / 1_000_000_000
        let minute = Double(c.minute ?? 0) + second / 60
        let hour = Double((c.hour ?? 0) % 12) + minute / 60
        return (hour, minute, second)
    }

    private var wantsSecondHand: Bool { showSeconds || size >= 70 }
    private var wantsNumerals: Bool { size >= 90 }
    private var wantsMicroTicks: Bool { size >= 54 }

    public var body: some View {
        let parts = components

        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color(white: 0.10), .black],
                        center: .center,
                        startRadius: 0,
                        endRadius: size / 2
                    )
                )
                .overlay(Circle().strokeBorder(Color.white.opacity(0.10), lineWidth: 0.8))

            if wantsMicroTicks {
                ForEach(0..<60, id: \.self) { tick in
                    if tick % 5 != 0 {
                        Rectangle()
                            .fill(Color.white.opacity(0.30))
                            .frame(width: 0.6, height: size * 0.035)
                            .offset(y: -(size / 2) + size * 0.065)
                            .rotationEffect(.degrees(Double(tick) * 6))
                    }
                }
            }

            ForEach(0..<12, id: \.self) { marker in
                Capsule()
                    .fill(Color.white.opacity(marker % 3 == 0 ? 0.85 : 0.45))
                    .frame(
                        width: marker % 3 == 0 ? size * 0.04 : size * 0.022,
                        height: marker % 3 == 0 ? size * 0.12 : size * 0.075
                    )
                    .offset(y: -(size / 2) + size * 0.08)
                    .rotationEffect(.degrees(Double(marker) * 30))
            }

            if wantsNumerals {
                ForEach(Array(stride(from: 3, through: 12, by: 3)), id: \.self) { numeral in
                    Text("\(numeral)")
                        .font(.system(size: size * 0.11, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                        .offset(y: -(size / 2) + size * 0.22)
                        .rotationEffect(.degrees(Double(numeral) * 30))
                        .rotationEffect(.degrees(-Double(numeral) * 30))
                }
            }

            hand(length: size * 0.28, width: size * 0.055, color: .white.opacity(0.95))
                .rotationEffect(.degrees(parts.hour * 30))

            hand(length: size * 0.40, width: size * 0.038, color: .white.opacity(0.85))
                .rotationEffect(.degrees(parts.minute * 6))

            if wantsSecondHand {
                hand(length: size * 0.43, width: max(1, size * 0.014), color: accent)
                    .rotationEffect(.degrees(parts.second * 6))
            }

            Circle()
                .fill(accent)
                .frame(width: max(3, size * 0.06), height: max(3, size * 0.06))
                .overlay(Circle().strokeBorder(Color.black.opacity(0.6), lineWidth: 0.8))
        }
        .frame(width: size, height: size)
    }

    /// A hand pinned at the dial centre and rotated about it.
    private func hand(length: CGFloat, width: CGFloat, color: Color) -> some View {
        Capsule()
            .fill(color)
            .frame(width: width, height: length)
            .offset(y: -length / 2 + length * 0.12)
    }
}
