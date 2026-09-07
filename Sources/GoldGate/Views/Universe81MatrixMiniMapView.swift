import AppKit
import SwiftUI

// MARK: - 🌌 81-Screen Spatial Matrix Mini-Map & Telemetry HUD
// Renders an interactive 9x9 radar grid displaying real-time cursor tracking,
// active screen sector (1..81), macro sector (1..9), and sub-pixel alignment telemetry.

public struct Universe81MatrixMiniMapView: View {
    @ObservedObject var pixelMapper: Universe81PixelMapperEngine = .shared
    @State private var hoveredScreenIndex: Int? = nil

    public init() {}

    public var body: some View {
        VStack(spacing: 10) {
            // ── HUD Header Telemetry ─────────────────────────────────────
            HStack(spacing: 8) {
                Image(systemName: "sparkles.tv.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.cyan)

                Text("Spatial Matrix Telemetry")
                    .font(.system(size: 12.5, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Spacer()

                Text("Screen \(pixelMapper.activeScreenIndex) / 81")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.cyan.opacity(0.18)))
            }

            Divider().background(Color.white.opacity(0.12))

            // ── 9x9 Interactive Radar Grid ───────────────────────────────
            VStack(spacing: 2) {
                ForEach(0..<9, id: \.self) { row in
                    HStack(spacing: 2) {
                        ForEach(0..<9, id: \.self) { col in
                            let index = row * 9 + col + 1
                            let isActive = (index == pixelMapper.activeScreenIndex)
                            let isHome = (index == Universe81PixelMapperEngine.homeScreenIndex)
                            let isHovered = (hoveredScreenIndex == index)

                            ZStack {
                                RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                                    .fill(
                                        isActive ? Color.cyan :
                                        (isHome ? Color.purple.opacity(0.65) :
                                        (isHovered ? Color.white.opacity(0.25) : Color.white.opacity(0.08)))
                                    )

                                if isHome && !isActive {
                                    Image(systemName: "house.fill")
                                        .font(.system(size: 7))
                                        .foregroundColor(.white.opacity(0.9))
                                } else if isActive {
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 4, height: 4)
                                        .shadow(color: .white, radius: 2)
                                }
                            }
                            .frame(width: 22, height: 16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                                    .stroke(
                                        isActive ? Color.cyan.opacity(0.9) :
                                        (isHome ? Color.purple.opacity(0.8) : Color.white.opacity(0.10)),
                                        lineWidth: isActive ? 1.2 : 0.6
                                    )
                            )
                            .onHover { h in
                                hoveredScreenIndex = h ? index : nil
                            }
                        }
                    }
                }
            }
            .padding(6)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.black.opacity(0.40))
            )

            Divider().background(Color.white.opacity(0.12))

            // ── Detailed Sector Telemetry Footer ─────────────────────────
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Macro Sector:")
                        .font(.system(size: 9.5, weight: .semibold))
                        .foregroundColor(.gray)
                    Text("\(pixelMapper.activeCompassBearing)")
                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("Cursor Offset:")
                        .font(.system(size: 9.5, weight: .semibold))
                        .foregroundColor(.gray)
                    Text("(\(Int(pixelMapper.cursorPixelOffset.x)), \(Int(pixelMapper.cursorPixelOffset.y))) pt")
                        .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                        .foregroundColor(.cyan)
                }
            }
        }
        .padding(12)
        .frame(width: 240)
        .background(
            ZStack {
                VisualEffectBlur(material: .popover, blendingMode: .withinWindow, state: .active)
                Color(red: 0.10, green: 0.11, blue: 0.14).opacity(0.92)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.white.opacity(0.16), lineWidth: 0.8)
        )
        .shadow(color: Color.black.opacity(0.40), radius: 14, y: 6)
    }
}
