import SwiftUI
import AppKit

// MARK: - 🔧 2028 Animated Wrench Tool Toggle Button
/// Provides a playful, futuristic tool switch with a mechanical ratchet spin,
/// neon torque glow, and spring physics to slide the Apple Dock in and out.
public struct GenieWrenchDockToggleButton: View {
    @Binding var isDockVisible: Bool
    var size: CGFloat = 26

    @State private var rotationDegrees: Double = 0.0
    @State private var isRatcheting: Bool = false
    @State private var glowPulse: Bool = false
    @State private var isHovered: Bool = false

    public init(isDockVisible: Binding<Bool>, size: CGFloat = 26) {
        self._isDockVisible = isDockVisible
        self.size = size
    }

    public var body: some View {
        Button(action: triggerWrenchToggle) {
            ZStack {
                // Mechanical torque glow ring when active
                if isDockVisible || glowPulse {
                    Circle()
                        .stroke(
                            LinearGradient(
                                colors: [Color.orange.opacity(0.8), Color.yellow.opacity(0.6), Color.cyan.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                        .scaleEffect(glowPulse ? 1.25 : 1.0)
                        .opacity(glowPulse ? 0.0 : 0.75)
                }

                // Background glass capsule
                Circle()
                    .fill(
                        isDockVisible
                            ? LinearGradient(
                                colors: [Color.orange.opacity(0.25), Color.yellow.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [Color.white.opacity(isHovered ? 0.14 : 0.08), Color.white.opacity(0.04)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                    )

                // Mechanical Wrench Glyphs with Ratchet Animation
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.system(size: size * 0.42, weight: .bold))
                    .foregroundColor(isDockVisible ? Color(red: 1.0, green: 0.72, blue: 0.25) : Color.white.opacity(0.80))
                    .rotationEffect(.degrees(rotationDegrees))
                    .scaleEffect(isRatcheting ? 1.28 : (isHovered ? 1.10 : 1.0))
                    .shadow(color: isDockVisible ? Color.orange.opacity(0.65) : Color.clear, radius: 4)
            }
            .frame(width: size, height: size)
            .overlay(
                Circle()
                    .strokeBorder(
                        isDockVisible ? Color.orange.opacity(0.55) : Color.white.opacity(0.16),
                        lineWidth: 0.75
                    )
            )
            .contentShape(Circle())
        }
        .buttonStyle(GenieMagneticButtonStyle(scale: 1.12))
        .onHover { h in
            withAnimation(.spring(response: 0.22, dampingFraction: 0.75)) {
                isHovered = h
            }
        }
        .help(isDockVisible ? "Hide Apple Mini Dock (⌘D / Wrench Tool)" : "Show Apple Mini Dock (⌘D / Wrench Tool)")
        .accessibilityLabel("Toggle Apple Dock")
    }

    private func triggerWrenchToggle() {
        HapticFeedback.selection()
        NSSound(named: "Pop")?.play()

        // 1. Ratchet-wrench mechanical turn animation
        withAnimation(.spring(response: 0.20, dampingFraction: 0.50)) {
            isRatcheting = true
            glowPulse = true
            rotationDegrees += isDockVisible ? -180.0 : 180.0
        }

        // 2. Toggle dock with smooth Apple liquid spring
        withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
            isDockVisible.toggle()
        }

        // 3. Reset ratchet scale & glow pulse
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.22) {
            withAnimation(.spring(response: 0.28, dampingFraction: 0.75)) {
                isRatcheting = false
                glowPulse = false
            }
        }
    }
}
