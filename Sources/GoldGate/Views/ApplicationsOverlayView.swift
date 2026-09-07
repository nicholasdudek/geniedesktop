import AppKit
import SwiftUI

// MARK: - Applications & Window Snapping Overlay View
public struct ApplicationsOverlayView: View {
    @AppStorage(PrefKey.appLanguage) var appLanguage: String = "English (US)"
@ObservedObject var switcher: ArrowAppSwitcherManager = .shared
    @ObservedObject var gridManager: SmartGridManager = .shared

    public init() {}

    public var body: some View {
        VStack(spacing: 16) {
            // ── Top Header Strip ──
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "square.grid.3x3.fill")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.cyan)

                    Text(LocalizedStrings.translateText("Applications & Window Control", lang: appLanguage))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("(\(switcher.runningApps.count) running)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                // Form detection badge
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                        .shadow(color: Color.green.opacity(0.8), radius: 3)
                    Text(LocalizedStrings.translateText("Form Inputs: Passthrough Active", lang: appLanguage))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.75))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 3.5)
                .background(Capsule().fill(Color.white.opacity(0.08)))

                Button(action: {
                    switcher.hideOverlay()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.6))
                }
                .buttonStyle(.plain)
            }

            // ── Applications Carousel ──
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(Array(switcher.runningApps.enumerated()), id: \.element.processIdentifier) { index, app in
                        let isSelected = (index == switcher.selectedIndex)
                        let isActive = (app.processIdentifier == NSWorkspace.shared.frontmostApplication?.processIdentifier)

                        Button(action: {
                            switcher.selectedIndex = index
                            switcher.activateApp(at: index)
                            switcher.hideOverlay()
                        }) {
                            VStack(spacing: 7) {
                                ZStack(alignment: .bottomTrailing) {
                                    if let icon = app.icon {
                                        Image(nsImage: icon)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 54, height: 54)
                                            .shadow(color: Color.black.opacity(0.35), radius: 6, x: 0, y: 3)
                                    } else {
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white.opacity(0.1))
                                            .frame(width: 54, height: 54)
                                    }

                                    // Active frontmost dot
                                    if isActive {
                                        Circle()
                                            .fill(Color.cyan)
                                            .frame(width: 10, height: 10)
                                            .shadow(color: Color.cyan, radius: 4)
                                            .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                                            .offset(x: 2, y: 2)
                                    }
                                }

                                Text(app.localizedName ?? "App")
                                    .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                                    .foregroundColor(isSelected ? .white : .white.opacity(0.75))
                                    .lineLimit(1)
                                    .frame(width: 74)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(isSelected ? Color.cyan.opacity(0.24) : Color.white.opacity(0.04))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(
                                        isSelected ? Color.cyan.opacity(0.85) : Color.white.opacity(0.08),
                                        lineWidth: isSelected ? 1.5 : 0.5
                                    )
                            )
                            .scaleEffect(isSelected ? 1.06 : 1.0)
                            .animation(.spring(response: 0.22, dampingFraction: 0.78), value: isSelected)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
            }
            .frame(height: 98)

            Divider()
                .background(Color.white.opacity(0.12))

            // ── Bottom Window Snapping & Shortcut Helpers ──
            HStack(spacing: 12) {
                // Snap buttons
                HStack(spacing: 6) {
                    snapButton(title: "Left (⌘←)", icon: "arrow.left.to.line.compact", dir: .left)
                    snapButton(title: "Max (⌘↑)", icon: "arrow.up.left.and.arrow.down.right", dir: .maximize)
                    snapButton(title: "Center (⌘↓)", icon: "viewfinder", dir: .center)
                    snapButton(title: "Right (⌘→)", icon: "arrow.right.to.line.compact", dir: .right)
                }

                Spacer()

                // Keyboard shortcuts legend
                HStack(spacing: 8) {
                    keyBadge(key: "← →", desc: "Switch")
                    keyBadge(key: "↵", desc: "Open")
                    keyBadge(key: "⌘ Arrows", desc: "Snap")
                    keyBadge(key: "⎋", desc: "Close")
                }
            }
        }
        .padding(18)
        .frame(width: 740, height: 250)
        .background(
            ZStack {
                VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(nsColor: .windowBackgroundColor).opacity(0.72))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.cyan.opacity(0.45), Color.white.opacity(0.12)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.0
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.55), radius: 24, x: 0, y: 12)
    }

    private func snapButton(title: String, icon: String, dir: SmartGridManager.WindowSnapDirection) -> some View {
        Button(action: {
            gridManager.snapFrontmostWindow(direction: dir)
            switcher.hideOverlay()
        }) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 9.5, weight: .bold))
                Text(title)
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundColor(.white.opacity(0.9))
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.white.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }

    private func keyBadge(key: String, desc: String) -> some View {
        HStack(spacing: 3) {
            Text(key)
                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                .foregroundColor(.cyan)
                .padding(.horizontal, 4)
                .padding(.vertical, 1.5)
                .background(RoundedRectangle(cornerRadius: 3).fill(Color.cyan.opacity(0.18)))
            Text(desc)
                .font(.system(size: 9.5, weight: .medium))
                .foregroundColor(.white.opacity(0.55))
        }
    }
}
