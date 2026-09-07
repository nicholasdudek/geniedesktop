import AppKit
import Foundation
import SwiftUI

// MARK: - Secondary Control Center View (Spatial Canvas, Display Geometry & Engine Controls)
// Provides dedicated secondary control matrix for Spatial Displays, Free Aspect Ratio Unlocking,
// Multi-Display Warp, Face Tracking Parallax, ProMotion 120Hz, and System Shaders.
public struct SecondaryControlCenterPopoverView: View {
    @ObservedObject var spatialManager = SpatialPlaneManager.shared
    @ObservedObject var desktopsManager = MacDesktopsManager.shared
    @ObservedObject var faceTracker = SpatialFaceTrackingManager.shared
    @ObservedObject var wallpaperManager = WallpaperManager.shared
    @AppStorage(PrefKey.appLanguage) var appLanguage: String = "English (US)"
    @AppStorage(PrefKey.displayAspectRatioMode) var displayAspectRatioMode: String = "Auto (Native Display)"
    @AppStorage(PrefKey.refreshRateMode) var refreshRateMode: String = "120Hz (ProMotion Fluid)"
    @AppStorage(PrefKey.notchClearanceMode) var notchClearanceMode: Bool = true
    @AppStorage(PrefKey.hapticsEnabled) var hapticsEnabled: Bool = true
    @AppStorage(PrefKey.faceTrackingSensitivity) var faceTrackingSensitivity: Double = 1.0

    @State private var selectedTab: Int = 0 // 0: Spatial Display, 1: Performance & Geometry

    public init() {}

    public var body: some View {
        VStack(spacing: 12) {
            // ── HEADER: Title & Mode Switcher ──
            headerSection

            // ── TAB SELECTOR ──
            tabSelector

            if selectedTab == 0 {
                // ── SECTION 1: SPATIAL DISPLAY & 9-DESKTOP FORMATION ──
                canvasAndAspectSection

                // ── SECTION 2: ASPECT RATIO UNLOCK MATRIX ──
                aspectRatioUnlockModule

                // ── SECTION 3: MULTI-MONITOR & SCREEN WARP ──
                multiDisplayWarpModule
            } else {
                // ── SECTION 4: PARALLAX & SENSORY ENGINE ──
                sensoryAndFaceTrackingModule

                // ── SECTION 5: PERFORMANCE & GPU TELEMETRY ──
                performanceTelemetryModule

                // ── SECTION 6: QUICK WORKSPACE ACTIONS ──
                quickWorkspaceActionsModule

                // ── SECTION 7: APP INSTALLATION & DOCK SETTINGS ──
                appInstallAndDockModule
            }

            // ── FOOTER: Shortcuts & Status ──
            footerSection
        }
        .padding(14)
        .frame(width: 348)
        .background(
            ZStack {
                VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow, state: .active)
                Color(red: 0.10, green: 0.11, blue: 0.16).opacity(0.88)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.cyan.opacity(0.40), Color.purple.opacity(0.25), Color.white.opacity(0.10)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.85
                )
        )
        .shadow(color: Color.black.opacity(0.40), radius: 22, y: 12)
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.cyan.opacity(0.35), Color.purple.opacity(0.25)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 28, height: 28)

                Image(systemName: "slider.horizontal.2.square")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.cyan)
            }

            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 5) {
                    Text("Spatial & Display Control")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("PRO")
                        .font(.system(size: 8.5, weight: .heavy, design: .monospaced))
                        .foregroundColor(.cyan)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(Color.cyan.opacity(0.22)))
                }

                Text("Display aspect ratios & engine tuning")
                    .font(.system(size: 9.5, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.60))
            }

            Spacer()

            // Close button
            Button(action: {
                SecondaryControlCenterPopoverManager.shared.dismiss()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.50))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: 4) {
            Button(action: {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                    selectedTab = 0
                }
                HapticFeedback.selection()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "rectangle.3.group.fill")
                    Text("Spatial Displays")
                }
                .font(.system(size: 11, weight: selectedTab == 0 ? .bold : .medium, design: .rounded))
                .foregroundColor(selectedTab == 0 ? .cyan : .white.opacity(0.65))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(selectedTab == 0 ? Color.cyan.opacity(0.18) : Color.white.opacity(0.04))
                )
            }
            .buttonStyle(.plain)

            Button(action: {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                    selectedTab = 1
                }
                HapticFeedback.selection()
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "gauge.with.dots.needle.50percent")
                    Text("Engine & Physics")
                }
                .font(.system(size: 11, weight: selectedTab == 1 ? .bold : .medium, design: .rounded))
                .foregroundColor(selectedTab == 1 ? .cyan : .white.opacity(0.65))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(selectedTab == 1 ? Color.cyan.opacity(0.18) : Color.white.opacity(0.04))
                )
            }
            .buttonStyle(.plain)
        }
        .padding(2)
        .background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(Color.black.opacity(0.35)))
    }

    // MARK: - Canvas & Multi-Desktop Layout Picker
    private var canvasAndAspectSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Spatial Layout Mode")
                    .font(.system(size: 10.5, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))

                Spacer()

                Button(action: {
                    spatialManager.toggleZoomOutPlane()
                    SecondaryControlCenterPopoverManager.shared.dismiss()
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                        Text(spatialManager.isZoomedOut ? "Zoom In" : "Canvas")
                    }
                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2.5)
                    .background(Capsule().fill(Color.cyan.opacity(0.18)))
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 5) {
                formationButton(
                    title: "1:1 Mega",
                    icon: "rectangle.split.3x3.fill",
                    mode: "1:1 Continuous Mega-Canvas"
                )

                formationButton(
                    title: "9x9 Fit",
                    icon: "circle.grid.3x3.fill",
                    mode: "9x9 Universe Overview"
                )

                formationButton(
                    title: "Ribbon",
                    icon: "scroll.fill",
                    mode: "Stacked Vertical Ribbon"
                )
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.white.opacity(0.10), lineWidth: 0.75)
        )
    }

    private func formationButton(title: String, icon: String, mode: String) -> some View {
        let isSelected = spatialManager.continuousCanvasFormation == mode
        return Button(action: {
            spatialManager.continuousCanvasFormation = mode
            HapticFeedback.selection()
        }) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(title)
                    .font(.system(size: 10, weight: isSelected ? .bold : .medium, design: .rounded))
            }
            .foregroundColor(isSelected ? .cyan : .white.opacity(0.70))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? Color.cyan.opacity(0.20) : Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(isSelected ? Color.cyan.opacity(0.45) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Aspect Ratio Unlock Module
    private var aspectRatioUnlockModule: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "aspectratio")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.cyan)
                    Text("Display Aspect Ratio")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.90))
                }

                Spacer()

                Text("UNLOCKED")
                    .font(.system(size: 8.5, weight: .heavy, design: .monospaced))
                    .foregroundColor(.green)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1.5)
                    .background(Capsule().fill(Color.green.opacity(0.18)))
            }

            let modes = [
                "Auto (Native Display)",
                "16:10 (MacBook)",
                "16:9 (Standard 4K)",
                "21:9 (UltraWide)",
                "3:2 (Creative Pro)",
                "Freeform Unlocked"
            ]

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 5) {
                ForEach(modes, id: \.self) { mode in
                    let isSel = displayAspectRatioMode == mode
                    Button(action: {
                        displayAspectRatioMode = mode
                        UserDefaults.standard.set(mode, forKey: PrefKey.displayAspectRatioMode)
                        NotificationCenter.default.post(name: NSNotification.Name("NexusDisplayAspectRatioChanged"), object: mode)
                        CustomMenuBarManager.shared.rebuildWindows()
                        HapticFeedback.selection()
                    }) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(isSel ? Color.cyan : Color.white.opacity(0.20))
                                .frame(width: 5, height: 5)
                            Text(mode)
                                .font(.system(size: 10, weight: isSel ? .bold : .medium, design: .rounded))
                                .foregroundColor(isSel ? .white : .white.opacity(0.70))
                                .lineLimit(1)
                            Spacer(minLength: 0)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .fill(isSel ? Color.cyan.opacity(0.22) : Color.white.opacity(0.04))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6, style: .continuous)
                                .strokeBorder(isSel ? Color.cyan.opacity(0.50) : Color.white.opacity(0.06), lineWidth: 0.8)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.white.opacity(0.10), lineWidth: 0.75)
        )
    }

    // MARK: - Multi-Display Warp Module
    private var multiDisplayWarpModule: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Connected Displays (\(NSScreen.screens.count))")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.90))

                Spacer()

                Button(action: {
                    ScreenWarpManager.shared.moveFrontmostWindowToNextScreen()
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "bolt.fill")
                        Text("Teleport Window")
                    }
                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2.5)
                    .background(Capsule().fill(Color.cyan.opacity(0.18)))
                }
                .buttonStyle(.plain)
            }

            ForEach(Array(NSScreen.screens.enumerated()), id: \.offset) { index, scr in
                let isMain = scr == NSScreen.main
                let ratio = scr.frame.width / max(1.0, scr.frame.height)
                HStack(spacing: 6) {
                    Image(systemName: "display")
                        .font(.system(size: 12))
                        .foregroundColor(isMain ? .cyan : .white.opacity(0.60))

                    VStack(alignment: .leading, spacing: 1) {
                        Text("Screen \(index + 1): \(scr.localizedName)")
                            .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Text("\(Int(scr.frame.width)) × \(Int(scr.frame.height)) • Aspect Ratio: \(String(format: "%.2f", ratio)):1")
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundColor(.white.opacity(0.55))
                    }

                    Spacer()

                    if isMain {
                        Text("PRIMARY")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(.cyan)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(Color.cyan.opacity(0.20)))
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.white.opacity(0.04))
                )
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.white.opacity(0.10), lineWidth: 0.75)
        )
    }

    // MARK: - Sensory & Face Tracking Module
    private var sensoryAndFaceTrackingModule: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .font(.system(size: 12))
                        .foregroundColor(faceTracker.isFaceTrackingEnabled ? .green : .cyan)
                    Text("Face Tracking & 3D Depth")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.90))
                }

                Spacer()

                Toggle("", isOn: Binding(
                    get: { faceTracker.isFaceTrackingEnabled },
                    set: { _ in faceTracker.toggleFaceTracking() }
                ))
                .toggleStyle(.switch)
                .labelsHidden()
                .scaleEffect(0.75)
            }

            HStack(spacing: 8) {
                Text("Sensitivity")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.70))

                Slider(value: $faceTrackingSensitivity, in: 0.5...3.0, step: 0.1)
                    .tint(.cyan)

                Text(String(format: "%.1fx", faceTrackingSensitivity))
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.cyan)
                    .frame(width: 32)
            }

            Text("Lean back to overview all 9 screens • Turn head to steer camera")
                .font(.system(size: 9.5, weight: .regular, design: .rounded))
                .foregroundColor(.white.opacity(0.55))
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.white.opacity(0.10), lineWidth: 0.75)
        )
    }

    // MARK: - Performance & GPU Telemetry
    private var performanceTelemetryModule: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("Engine Telemetry & Refresh Rate")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.90))

            HStack(spacing: 6) {
                telemetryBadge(title: "Compositor", value: "Metal GPU", icon: "cpu.fill", color: .purple)
                telemetryBadge(title: "Framerate", value: "120 FPS", icon: "speedometer", color: .green)
                telemetryBadge(title: "Preloaded", value: "\(desktopsManager.spaces.count) Spaces", icon: "square.stack.3d.up.fill", color: .cyan)
            }

            // Notch Clearance Toggle
            HStack {
                Text("Notch Clearance Safe Inset")
                    .font(.system(size: 10.5, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.80))
                Spacer()
                Toggle("", isOn: $notchClearanceMode)
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .scaleEffect(0.75)
                    .onChange(of: notchClearanceMode) { _, val in
                        UserDefaults.standard.set(val, forKey: PrefKey.notchClearanceMode)
                        CustomMenuBarManager.shared.rebuildWindows()
                    }
            }
            .padding(.top, 2)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.white.opacity(0.10), lineWidth: 0.75)
        )
    }

    private func telemetryBadge(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 9))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 8.5, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.60))
            }
            Text(value)
                .font(.system(size: 10.5, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(6)
        .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.04)))
    }

    // MARK: - Quick Workspace Actions
    private var quickWorkspaceActionsModule: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Workspace Directives")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.90))

            HStack(spacing: 6) {
                Button(action: {
                    HapticFeedback.selection()
                    NotificationCenter.default.post(name: NSNotification.Name("NexusToggleDesktopGrid"), object: nil)
                    SecondaryControlCenterPopoverManager.shared.dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "square.grid.2x2.fill")
                        Text("Formations")
                    }
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.cyan)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.cyan.opacity(0.18)))
                }
                .buttonStyle(.plain)

                Button(action: {
                    HapticFeedback.selection()
                    let cur = DesktopFilesManager.shared.areDesktopFilesVisible
                    DesktopFilesManager.shared.setDesktopFilesVisible(!cur)
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: DesktopFilesManager.shared.areDesktopFilesVisible ? "eye.fill" : "eye.slash.fill")
                        Text("Clean Canvas")
                    }
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.08)))
                }
                .buttonStyle(.plain)

                Button(action: {
                    HapticFeedback.selection()
                    NotificationCenter.default.post(name: NSNotification.Name("NexusFocusGenieSearchBarWithMode"), object: "chat")
                    SecondaryControlCenterPopoverManager.shared.dismiss()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                        Text("Studio")
                    }
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.purple)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.purple.opacity(0.18)))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.white.opacity(0.10), lineWidth: 0.75)
        )
    }

    // MARK: - App Installation & Dock Options
    private var appInstallAndDockModule: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.down.app.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.cyan)
                    Text("App Installation & Dock Mode")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.90))
                }
                Spacer()
                Text(AppInstallationManager.shared.isRunningFromApplications ? "INSTALLED" : "DMG / DISK")
                    .font(.system(size: 8.5, weight: .bold, design: .monospaced))
                    .foregroundColor(AppInstallationManager.shared.isRunningFromApplications ? .green : .yellow)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1.5)
                    .background(Capsule().fill(AppInstallationManager.shared.isRunningFromApplications ? Color.green.opacity(0.18) : Color.yellow.opacity(0.18)))
            }

            // Mode Selector: Menu Bar Only vs Menu Bar & Dock vs Dock Only
            HStack(spacing: 4) {
                ForEach(["Menu Bar Only (No Dock Icon)", "Menu Bar & Dock Icon"], id: \.self) { mode in
                    let isSel = AppInstallationManager.shared.appVisibilityMode == mode
                    Button(action: {
                        AppInstallationManager.shared.setVisibilityMode(mode)
                    }) {
                        Text(mode.contains("Only") ? "Menu Bar Only" : "Dock & Menu Bar")
                            .font(.system(size: 9.5, weight: isSel ? .bold : .medium, design: .rounded))
                            .foregroundColor(isSel ? .cyan : .white.opacity(0.65))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 5)
                            .background(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .fill(isSel ? Color.cyan.opacity(0.20) : Color.white.opacity(0.04))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 6, style: .continuous)
                                    .strokeBorder(isSel ? Color.cyan.opacity(0.40) : Color.clear, lineWidth: 0.8)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }

            if !AppInstallationManager.shared.isRunningFromApplications {
                HStack(spacing: 6) {
                    Button(action: {
                        AppInstallationManager.shared.showMoveAlert()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "folder.badge.plus")
                            Text("Move to Applications Folder...")
                        }
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.blue.opacity(0.45)))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 2)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.white.opacity(0.10), lineWidth: 0.75)
        )
    }

    // MARK: - Footer Section
    private var footerSection: some View {
        HStack {
            Text("Tip: 3-Finger scroll to glide continuously")
                .font(.system(size: 9.5, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.50))

            Spacer()

            Button(action: {
                AppDelegate.shared?.showMenuBarSettingsDropdown(targetTab: .system)
                SecondaryControlCenterPopoverManager.shared.dismiss()
            }) {
                HStack(spacing: 3) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 9))
                    Text("Genie Settings...")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.cyan.opacity(0.85))
            }
            .buttonStyle(.plain)
        }
        .padding(.top, -2)
    }
}
