import AppKit
import SwiftUI

// MARK: - ▦ 3x3 Scaled Program Displayer View (Hardware-Accelerated Metal & Typography Sharpening)
public struct ScaledProgramMatrixView: View {
    @ObservedObject var engine = ScaledProgramDisplayerEngine.shared
    @State private var hoveredSlotId: Int? = nil
    @State private var showFilterSettings: Bool = false

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // ── Top HUD Control Ribbon ───────────────────────────────────────────
            HStack(spacing: 10) {
                // Title & Icon
                HStack(spacing: 6) {
                    Image(systemName: "square.grid.3x3.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.cyan)
                    Text("3×3 Program Scaler & Displayer")
                        .font(.system(size: 12.5, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                Spacer()

                // Metal GPU Telemetry & Filter Mode Badge
                Menu {
                    ForEach(TypographyFilterMode.allCases) { mode in
                        Button(action: {
                            engine.setFilterMode(mode)
                            HapticFeedback.selection()
                        }) {
                            HStack {
                                Text(mode.title)
                                if engine.typographyFilterMode == mode {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }

                    Divider()

                    Button(action: {
                        engine.isMetalEnabled.toggle()
                        engine.captureLiveThumbnails()
                        HapticFeedback.selection()
                    }) {
                        HStack {
                            Text(engine.isMetalEnabled ? "Disable Metal Acceleration" : "Enable Metal Acceleration")
                            Image(systemName: engine.isMetalEnabled ? "bolt.slash" : "bolt.fill")
                        }
                    }

                    Button(action: {
                        showFilterSettings.toggle()
                    }) {
                        HStack {
                            Text("Tune Sharpening Strength...")
                            Image(systemName: "slider.horizontal.3")
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: engine.isMetalEnabled ? "bolt.fill" : "cpu")
                            .font(.system(size: 9.5))
                            .foregroundColor(engine.isMetalEnabled ? .cyan : .yellow)
                        Text(engine.isMetalEnabled ? "Metal \(engine.typographyFilterMode.shortTitle)" : "CPU Scaler")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        if engine.gpuComputeLatencyMs > 0.01 {
                            Text(String(format: "%.1fms", engine.gpuComputeLatencyMs))
                                .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                                .foregroundColor(.cyan.opacity(0.85))
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3.5)
                    .background(Capsule().fill(Color.cyan.opacity(0.18)))
                    .overlay(Capsule().stroke(Color.cyan.opacity(0.35), lineWidth: 0.8))
                }
                .menuStyle(BorderlessButtonMenuStyle())

                // SkyLight Hardware Compositor Matrix Button
                Button(action: {
                    if engine.isCompositorTransformModeActive {
                        engine.restoreAllWindowTransforms()
                    } else {
                        engine.applyMatrixWindowTransforms()
                    }
                    HapticFeedback.selection()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: engine.isCompositorTransformModeActive ? "slider.vertical.3" : "macwindow.on.rectangle")
                            .font(.system(size: 9.5))
                            .foregroundColor(engine.isCompositorTransformModeActive ? .green : .white.opacity(0.8))
                        Text(engine.isCompositorTransformModeActive ? "SkyLight: Active" : "CGS Transform")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(engine.isCompositorTransformModeActive ? .green : .white)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3.5)
                    .background(Capsule().fill(engine.isCompositorTransformModeActive ? Color.green.opacity(0.2) : Color.white.opacity(0.08)))
                    .overlay(Capsule().stroke(engine.isCompositorTransformModeActive ? Color.green.opacity(0.5) : Color.white.opacity(0.15), lineWidth: 0.8))
                }
                .buttonStyle(PlainButtonStyle())
                .help("Apply CGSSetWindowTransform / SLSSetWindowTransform directly to WindowServer surfaces")

                // Scale Ratio Indicator
                HStack(spacing: 4) {
                    Text("0.33× Scale")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(.cyan)
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 3.5)
                .background(Capsule().fill(Color.white.opacity(0.08)))

                // Full Screen Toggle Button
                Button(action: {
                    FinderChatWindowManager.shared.snapTo(preset: .fullScreen)
                    HapticFeedback.selection()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right.square.fill")
                        Text("Full Screen ⤢")
                    }
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4.5)
                    .background(Capsule().fill(Color.cyan.opacity(0.85)))
                }
                .buttonStyle(PlainButtonStyle())
                .help("Expand 3×3 Scaled Program Displayer to Full Screen (100%)")

                // Rescan Button
                Button(action: {
                    engine.refreshRunningPrograms()
                    HapticFeedback.playClickSound()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                        Text("Rescan")
                    }
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.white.opacity(0.10)))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.40))

            // ── Optional Filter Tuning Drawer ──────────────────────────────────
            if showFilterSettings {
                HStack(spacing: 16) {
                    HStack(spacing: 6) {
                        Text("Sharpening:")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        Slider(
                            value: Binding(
                                get: { Double(engine.sharpeningStrength) },
                                set: { engine.setSharpeningStrength(Float($0)) }
                            ),
                            in: 0.0...1.5,
                            step: 0.05
                        )
                        .frame(width: 100)
                        Text(String(format: "%.2f", engine.sharpeningStrength))
                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                            .foregroundColor(.cyan)
                    }

                    HStack(spacing: 6) {
                        Text("Stem Contrast:")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))
                        Slider(
                            value: Binding(
                                get: { Double(engine.textContrastBoost) },
                                set: {
                                    engine.textContrastBoost = Float($0)
                                    engine.captureLiveThumbnails()
                                }
                            ),
                            in: 1.0...1.8,
                            step: 0.05
                        )
                        .frame(width: 80)
                        Text(String(format: "%.2f×", engine.textContrastBoost))
                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                            .foregroundColor(.cyan)
                    }

                    Toggle(isOn: Binding(
                        get: { engine.isGammaCorrected },
                        set: {
                            engine.isGammaCorrected = $0
                            engine.captureLiveThumbnails()
                        }
                    )) {
                        Text("sRGB Gamma")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .toggleStyle(SwitchToggleStyle())
                    .scaleEffect(0.75)

                    Spacer()

                    Button("Done") {
                        showFilterSettings = false
                    }
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.cyan)
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.55))
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            Divider().background(Color.white.opacity(0.12))

            // ── 3×3 Grid Canvas (9 Scaled Program Viewports) ────────────────────
            GeometryReader { geo in
                let spacing: CGFloat = 8
                let cellWidth = (geo.size.width - (spacing * 4)) / 3
                let cellHeight = (geo.size.height - (spacing * 4)) / 3

                if let focusedId = engine.focusedSlotId, let focusedSlot = engine.matrixSlots.first(where: { $0.id == focusedId }) {
                    // Zoomed-in single program view
                    zoomedProgramCard(slot: focusedSlot, size: geo.size)
                        .transition(.scale.combined(with: .opacity))
                } else {
                    // 3x3 Grid Layout
                    LazyVGrid(
                        columns: Array(repeating: GridItem(.fixed(cellWidth), spacing: spacing), count: 3),
                        spacing: spacing
                    ) {
                        ForEach(engine.matrixSlots) { slot in
                            singleProgramCell(slot: slot, width: cellWidth, height: cellHeight)
                        }
                    }
                    .padding(spacing)
                }
            }
        }
        .background(
            VisualEffectBlur(material: .popover, blendingMode: .withinWindow, state: .active)
                .overlay(Color.black.opacity(0.40))
        )
        .onAppear {
            engine.refreshRunningPrograms()
            engine.startLiveStream()
        }
        .onDisappear {
            engine.stopLiveStream()
        }
    }

    // MARK: - 🪟 Single Scaled Program Cell
    private func singleProgramCell(slot: ScaledProgramSlot, width: CGFloat, height: CGFloat) -> some View {
        let isHovered = (hoveredSlotId == slot.id)

        return VStack(spacing: 0) {
            // Mini Header Bar with App Icon & Title
            HStack(spacing: 5) {
                if let icon = slot.appIcon {
                    Image(nsImage: icon)
                        .resizable()
                        .frame(width: 14, height: 14)
                } else {
                    Image(systemName: "app.dashed")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }

                Text(slot.appName)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)

                Spacer()

                if slot.windowId != nil {
                    Text("Slot \(slot.id)")
                        .font(.system(size: 8.5, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(Color.black.opacity(0.50))

            Divider().background(Color.white.opacity(0.08))

            // Scaled Live Program Viewport (High-DPI Lanczos Sharpened)
            ZStack {
                if let preview = slot.livePreview {
                    Image(nsImage: preview)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: width, height: height - 26)
                        .clipped()
                } else {
                    VStack(spacing: 4) {
                        Image(systemName: "macwindow")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.20))
                        Text(slot.appName)
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.35))
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.25))
                }

                // Hover Action Overlay
                if isHovered && slot.windowId != nil {
                    Color.black.opacity(0.30)
                    HStack(spacing: 8) {
                        Button(action: {
                            engine.focusSlot(id: slot.id)
                        }) {
                            HStack(spacing: 3) {
                                Image(systemName: "arrow.up.left.and.arrow.down.right")
                                Text("Zoom 100%")
                            }
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.cyan.opacity(0.85)))
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .transition(.opacity)
                }
            }
        }
        .frame(width: width, height: height)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(red: 0.12, green: 0.13, blue: 0.17)))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(
                    isHovered ? Color.cyan.opacity(0.8) : Color.white.opacity(0.12),
                    lineWidth: isHovered ? 1.5 : 0.8
                )
        )
        .shadow(color: Color.black.opacity(0.35), radius: isHovered ? 8 : 4, x: 0, y: 3)
        .onHover { h in
            hoveredSlotId = h ? slot.id : nil
        }
        .onTapGesture {
            engine.focusSlot(id: slot.id)
        }
        .contextMenu {
            if slot.windowId != nil {
                Button(action: {
                    engine.focusSlot(id: slot.id)
                }) {
                    Label("Zoom Fullscreen", systemImage: "arrow.up.left.and.arrow.down.right")
                }

                Divider()

                Button(action: {
                    engine.forwardClick(to: slot, localNormalizedPoint: CGPoint(x: 0.5, y: 0.5))
                }) {
                    Label("Forward Center Click", systemImage: "cursorarrow.click")
                }

                Button(action: {
                    engine.forwardDoubleClick(to: slot, localNormalizedPoint: CGPoint(x: 0.5, y: 0.5))
                }) {
                    Label("Forward Double Click", systemImage: "cursorarrow.click.2")
                }

                Button(action: {
                    engine.forwardRightClick(to: slot, localNormalizedPoint: CGPoint(x: 0.5, y: 0.5))
                }) {
                    Label("Forward Right Click", systemImage: "contextualmenu.and.cursorarrow")
                }

                Divider()

                if let wid = slot.windowId {
                    Button(action: {
                        engine.applyWindowServerAffineScale(windowId: wid, scale: 0.333, position: slot.originalBounds.origin)
                    }) {
                        Label("Apply CGS WindowServer Scale (0.33×)", systemImage: "slider.horizontal.below.rectangle")
                    }

                    Button(action: {
                        engine.skyLightBridge.resetWindowTransform(windowId: wid)
                    }) {
                        Label("Reset CGS Window Transform (1.0×)", systemImage: "arrow.counterclockwise")
                    }
                }
            }
        }
    }

    // MARK: - 🔍 Zoomed Single Program View
    private func zoomedProgramCard(slot: ScaledProgramSlot, size: CGSize) -> some View {
        VStack(spacing: 0) {
            HStack {
                if let icon = slot.appIcon {
                    Image(nsImage: icon).resizable().frame(width: 18, height: 18)
                }
                Text(slot.appName)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Spacer()

                Button(action: {
                    engine.focusSlot(id: slot.id)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "square.grid.3x3")
                        Text("Back to 3×3 Grid")
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.cyan))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.6))

            Divider().background(Color.white.opacity(0.15))

            if let preview = slot.livePreview {
                Image(nsImage: preview)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(width: size.width, height: size.height)
        .background(Color.black)
    }
}
