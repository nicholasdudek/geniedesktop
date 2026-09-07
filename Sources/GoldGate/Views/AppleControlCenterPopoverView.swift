import AppKit
import SwiftUI

// MARK: - Stock Apple Control Center Popover View
// Pixel-perfect parity with macOS Monterey / Ventura / Sonoma / Sequoia Control Center
public struct AppleControlCenterPopoverView: View {
    @ObservedObject var volumeManager = MultiOutputVolumeManager.shared
    @ObservedObject var brightnessManager = DisplayBrightnessManager.shared
    @ObservedObject var batteryMonitor = BatteryMonitor.shared
    @AppStorage(PrefKey.appLanguage) var appLanguage: String = "English (US)"

    // Wi-Fi State
    @State private var isWifiEnabled: Bool = true
    @State private var wifiNetworkName: String = "Wi-Fi Network"

    // Bluetooth State
    @State private var isBluetoothEnabled: Bool = true

    // AirDrop State
    @State private var airDropStatus: String = "Contacts Only"

    // Focus / Do Not Disturb State
    @State private var isFocusEnabled: Bool = false

    // Screen Mirroring State
    @State private var isMirroringEnabled: Bool = false

    // Display Brightness State
    @State private var isDarkMode: Bool = NSApp.effectiveAppearance.name.rawValue.lowercased().contains("dark")

    // Now Playing State
    @State private var currentTrackTitle: String = "Music"
    @State private var currentTrackArtist: String = "Not Playing"
    @State private var isPlaying: Bool = false

    public init() {}

    public var body: some View {
        VStack(spacing: 12) {
            // ── TOP CONTROL SWITCHER ──
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "switch.2")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)
                    Text("Control Center")
                        .font(.system(size: 11.5, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                Spacer()

                Button(action: {
                    ControlCenterPopoverManager.shared.dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        SecondaryControlCenterPopoverManager.shared.show()
                    }
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "slider.horizontal.2.square")
                        Text("Spatial Controls ❯")
                    }
                    .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2.5)
                    .background(Capsule().fill(Color.cyan.opacity(0.18)))
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, -2)

            // ── TOP SECTION: 2-Column Connectivity & Focus Modules ──
            HStack(spacing: 10) {
                // Left Column: Connectivity (Wi-Fi, Bluetooth, AirDrop)
                connectivityBox
                    .frame(maxWidth: .infinity)

                // Right Column: Focus & Screen Mirroring
                VStack(spacing: 10) {
                    focusModule
                    screenMirroringModule
                }
                .frame(maxWidth: .infinity)
            }

            // ── DISPLAY BRIGHTNESS MODULE ──
            displayModule

            // ── KEYBOARD BACKLIGHT MODULE ──
            keyboardBacklightModule

            // ── SOUND & VOLUME MODULE ──
            soundModule

            // ── BATTERY MODULE ──
            batteryModule

            // ── NOW PLAYING MODULE ──
            nowPlayingModule

            // ── FOOTER: System Settings Shortcut ──
            HStack {
                Spacer()
                Button(action: {
                    NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/System Settings.app"))
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 10))
                        Text(LocalizedStrings.translateText("System Settings...", lang: appLanguage))
                            .font(.system(size: 10.5, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(.white.opacity(0.55))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, -2)
        }
        .padding(14)
        .frame(width: 324)
        .background(
            ZStack {
                VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow, state: .active)
                Color(red: 0.12, green: 0.13, blue: 0.16).opacity(0.85)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.white.opacity(0.18), lineWidth: 0.75)
        )
        .shadow(color: Color.black.opacity(0.35), radius: 20, y: 10)
        .onAppear {
            loadInitialStates()
        }
    }

    // MARK: - Connectivity Module (Wi-Fi, Bluetooth, AirDrop)
    private var connectivityBox: some View {
        VStack(spacing: 8) {
            // Wi-Fi
            Button(action: {
                toggleWifi()
            }) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(isWifiEnabled ? Color.blue : Color.white.opacity(0.14))
                            .frame(width: 28, height: 28)
                        Image(systemName: "wifi")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(isWifiEnabled ? .white : .white.opacity(0.60))
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text(LocalizedStrings.translateText("Wi-Fi", lang: appLanguage))
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        Text(isWifiEnabled ? wifiNetworkName : LocalizedStrings.translateText("Off", lang: appLanguage))
                            .font(.system(size: 10, weight: .regular))
                            .foregroundColor(.white.opacity(0.60))
                            .lineLimit(1)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white.opacity(0.35))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .contextMenu {
                Button(LocalizedStrings.translateText("Wi-Fi Settings...", lang: appLanguage)) {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.wifi-settings-extension") {
                        NSWorkspace.shared.open(url)
                    } else {
                        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/System Settings.app"))
                    }
                }
            }

            Divider().opacity(0.15)

            // Bluetooth
            Button(action: {
                toggleBluetooth()
            }) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(isBluetoothEnabled ? Color.blue : Color.white.opacity(0.14))
                            .frame(width: 28, height: 28)
                        Image(systemName: "wave.3.forward")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(isBluetoothEnabled ? .white : .white.opacity(0.60))
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text(LocalizedStrings.translateText("Bluetooth", lang: appLanguage))
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        Text(isBluetoothEnabled ? LocalizedStrings.translateText("On", lang: appLanguage) : LocalizedStrings.translateText("Off", lang: appLanguage))
                            .font(.system(size: 10, weight: .regular))
                            .foregroundColor(.white.opacity(0.60))
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white.opacity(0.35))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .contextMenu {
                Button(LocalizedStrings.translateText("Bluetooth Settings...", lang: appLanguage)) {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.BluetoothSettings") {
                        NSWorkspace.shared.open(url)
                    } else {
                        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/System Settings.app"))
                    }
                }
            }

            Divider().opacity(0.15)

            // AirDrop
            Button(action: {
                cycleAirDrop()
            }) {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 28, height: 28)
                        Image(systemName: "airdrop")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 1) {
                        Text(LocalizedStrings.translateText("AirDrop", lang: appLanguage))
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        Text(airDropStatus)
                            .font(.system(size: 10, weight: .regular))
                            .foregroundColor(.white.opacity(0.60))
                    }

                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Focus / Do Not Disturb Module
    private var focusModule: some View {
        Button(action: {
            isFocusEnabled.toggle()
            HapticFeedback.selection()
        }) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(isFocusEnabled ? Color.purple : Color.white.opacity(0.14))
                        .frame(width: 28, height: 28)
                    Image(systemName: "moon.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(isFocusEnabled ? .white : .white.opacity(0.60))
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(LocalizedStrings.translateText("Focus", lang: appLanguage))
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                    Text(isFocusEnabled ? LocalizedStrings.translateText("Do Not Disturb", lang: appLanguage) : LocalizedStrings.translateText("Off", lang: appLanguage))
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(.white.opacity(0.60))
                }

                Spacer()
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Screen Mirroring Module
    private var screenMirroringModule: some View {
        Button(action: {
            isMirroringEnabled.toggle()
            HapticFeedback.selection()
            if let url = URL(string: "x-apple.systempreferences:com.apple.Displays-Settings.extension") {
                NSWorkspace.shared.open(url)
            }
        }) {
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(isMirroringEnabled ? Color.blue : Color.white.opacity(0.14))
                        .frame(width: 28, height: 28)
                    Image(systemName: "rectangle.on.rectangle")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(isMirroringEnabled ? .white : .white.opacity(0.60))
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(LocalizedStrings.translateText("Screen Mirroring", lang: appLanguage))
                        .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }

                Spacer()
            }
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.08))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Display Brightness Module
    private var displayModule: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(LocalizedStrings.translateText("Display", lang: appLanguage))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Text("\(Int(brightnessManager.displayBrightness * 100))%")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.60))
            }

            ZStack(alignment: .leading) {
                // Background Track
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.12))
                    .frame(height: 32)

                // Active Fill
                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.95), Color.white.opacity(0.85)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(32, geo.size.width * CGFloat(brightnessManager.displayBrightness)), height: 32)
                }
                .frame(height: 32)

                // Sun Icon
                HStack {
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(brightnessManager.displayBrightness > 0.15 ? .black.opacity(0.75) : .white)
                        .padding(.leading, 10)
                    Spacer()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
            )
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { val in
                        let w: CGFloat = 296
                        let pct = max(0.05, min(1.0, Double(val.location.x / w)))
                        brightnessManager.setDisplayBrightness(pct)
                    }
            )

            // Dark Mode & Night Shift Toggles
            HStack(spacing: 8) {
                Button(action: {
                    toggleDarkMode()
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: isDarkMode ? "moon.stars.fill" : "sun.max.fill")
                            .font(.system(size: 10))
                        Text(isDarkMode ? "Dark Mode: On" : "Dark Mode: Off")
                            .font(.system(size: 10.5, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.white.opacity(isDarkMode ? 0.18 : 0.08)))
                    .overlay(Capsule().strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5))
                }
                .buttonStyle(.plain)

                Spacer()

                Button(action: {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.Displays-Settings.extension") {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    HStack(spacing: 3) {
                        Text(LocalizedStrings.translateText("Display Settings...", lang: appLanguage))
                            .font(.system(size: 10, weight: .regular))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 7.5, weight: .bold))
                    }
                    .foregroundColor(.white.opacity(0.50))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 2)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Keyboard Backlight Module
    private var keyboardBacklightModule: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(LocalizedStrings.translateText("Keyboard Brightness", lang: appLanguage))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Text("\(Int(brightnessManager.keyboardBrightness * 100))%")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.60))
            }

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white.opacity(0.12))
                    .frame(height: 30)

                GeometryReader { geo in
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.95), Color.white.opacity(0.85)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(30, geo.size.width * CGFloat(brightnessManager.keyboardBrightness)), height: 30)
                }
                .frame(height: 30)

                HStack {
                    Image(systemName: "keyboard")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(brightnessManager.keyboardBrightness > 0.15 ? .black.opacity(0.75) : .white)
                        .padding(.leading, 10)
                    Spacer()
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
            )
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { val in
                        let w: CGFloat = 296
                        let pct = max(0.0, min(1.0, Double(val.location.x / w)))
                        brightnessManager.setKeyboardBrightness(pct)
                    }
            )
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Battery Module
    private var batteryModule: some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(batteryMonitor.isCharging ? Color.green.opacity(0.25) : Color.white.opacity(0.14))
                    .frame(width: 28, height: 28)
                Image(systemName: batteryMonitor.isCharging ? "bolt.fill" : (batteryMonitor.isPluggedIn ? "powerplug.fill" : "battery.100"))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(batteryMonitor.isCharging ? .green : .white)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(LocalizedStrings.translateText("Battery", lang: appLanguage))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                Text(batteryMonitor.isCharging ? "Charging (\(batteryMonitor.batteryPct ?? 100)%)" : (batteryMonitor.isPluggedIn ? "Power Adapter (\(batteryMonitor.batteryPct ?? 100)%)" : "Battery: \(batteryMonitor.batteryPct ?? 100)%"))
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.white.opacity(0.60))
            }

            Spacer()

            Button(action: {
                if let url = URL(string: "x-apple.systempreferences:com.apple.Battery-Settings.extension") {
                    NSWorkspace.shared.open(url)
                } else {
                    NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/System Settings.app"))
                }
            }) {
                HStack(spacing: 3) {
                    Text("\(batteryMonitor.batteryPct ?? 100)%")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 7.5, weight: .bold))
                }
                .foregroundColor(.white.opacity(0.65))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.white.opacity(0.08)))
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5)
                )
        )
    }

    private var soundSpeakerIconName: String {
        if volumeManager.isMasterMuted {
            return "speaker.slash.fill"
        } else if volumeManager.masterVolume > 0.5 {
            return "speaker.wave.3.fill"
        } else {
            return "speaker.wave.1.fill"
        }
    }

    private var soundVolumeText: String {
        let percent = Int((volumeManager.masterVolume * 100).rounded())
        return "\(percent)%"
    }

    private var soundIconColor: Color {
        volumeManager.masterVolume > 0.15 ? Color.black.opacity(0.75) : Color.white
    }

    @ViewBuilder
    private var soundSliderTrack: some View {
        ZStack(alignment: .leading) {
            // Background Track
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.12))
                .frame(height: 32)

            // Active Fill
            GeometryReader { geo in
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.95), Color.white.opacity(0.85)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(32, geo.size.width * CGFloat(volumeManager.masterVolume)), height: 32)
            }
            .frame(height: 32)

            // Speaker Icon (Tap to Mute/Unmute)
            HStack {
                Image(systemName: soundSpeakerIconName)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(soundIconColor)
                    .padding(.leading, 10)
                    .onTapGesture {
                        volumeManager.toggleMasterMute()
                        HapticFeedback.selection()
                    }
                    .help("Click to Mute / Unmute 🔇")
                Spacer()
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5)
        )
    }

    // MARK: - Sound Module
    private var soundModule: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(LocalizedStrings.translateText("Sound", lang: appLanguage))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Text(soundVolumeText)
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.60))
            }

            soundSliderTrack
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { val in
                        let w: CGFloat = 296
                        let pct = max(0.0, min(1.0, Double(val.location.x / w)))
                        volumeManager.setMasterVolume(pct)
                    }
            )

            // Active Output Device Info
            HStack(spacing: 5) {
                let defaultDev = volumeManager.devices.first(where: { $0.isDefault })
                Image(systemName: defaultDev?.iconName ?? "speaker.wave.2.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.70))
                Text(defaultDev?.name ?? "MacBook Speakers")
                    .font(.system(size: 10.5, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.80))
                    .lineLimit(1)

                Spacer()

                Button(action: {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.Sound-Settings.extension") {
                        NSWorkspace.shared.open(url)
                    }
                }) {
                    HStack(spacing: 3) {
                        Text(LocalizedStrings.translateText("Sound Settings...", lang: appLanguage))
                            .font(.system(size: 10, weight: .regular))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 7.5, weight: .bold))
                    }
                    .foregroundColor(.white.opacity(0.50))
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 2)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Now Playing / Media Module
    private var nowPlayingModule: some View {
        HStack(spacing: 10) {
            // Album Artwork Placeholder / Music Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [Color.pink.opacity(0.85), Color.purple.opacity(0.85)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 38, height: 38)
                Image(systemName: "music.note")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(currentTrackTitle)
                    .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                Text(currentTrackArtist)
                    .font(.system(size: 10, weight: .regular))
                    .foregroundColor(.white.opacity(0.60))
                    .lineLimit(1)
            }

            Spacer()

            // Media Playback Controls
            HStack(spacing: 12) {
                Button(action: {
                    sendMediaKey(code: 20) // NX_KEYTYPE_PREVIOUS
                }) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.75))
                }
                .buttonStyle(.plain)

                Button(action: {
                    isPlaying.toggle()
                    sendMediaKey(code: 16) // NX_KEYTYPE_PLAY
                }) {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)

                Button(action: {
                    sendMediaKey(code: 19) // NX_KEYTYPE_NEXT
                }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.75))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5)
                )
        )
    }

    // MARK: - Actions & Helpers
    private func loadInitialStates() {
        // Query active Wi-Fi SSID
        let script = "do shell script \"networksetup -getairportnetwork en0 | awk -F': ' '{print $2}'\""
        if let res = NSAppleScript(source: script)?.executeAndReturnError(nil).stringValue, !res.isEmpty, !res.contains("error") {
            wifiNetworkName = res.trimmingCharacters(in: .whitespacesAndNewlines)
        } else {
            wifiNetworkName = "Wi-Fi Connected"
        }
    }

    private func toggleWifi() {
        isWifiEnabled.toggle()
        let newState = isWifiEnabled ? "on" : "off"
        HapticFeedback.selection()
        DispatchQueue.global(qos: .userInitiated).async {
            _ = try? Process.run(URL(fileURLWithPath: "/usr/sbin/networksetup"), arguments: ["-setairportpower", "en0", newState])
        }
    }

    private func toggleBluetooth() {
        isBluetoothEnabled.toggle()
        HapticFeedback.selection()
        if let url = URL(string: "x-apple.systempreferences:com.apple.BluetoothSettings") {
            NSWorkspace.shared.open(url)
        }
    }

    private func cycleAirDrop() {
        HapticFeedback.selection()
        if airDropStatus == "Contacts Only" {
            airDropStatus = "Everyone"
        } else if airDropStatus == "Everyone" {
            airDropStatus = "Off"
        } else {
            airDropStatus = "Contacts Only"
        }
    }

    private func toggleDarkMode() {
        isDarkMode.toggle()
        HapticFeedback.selection()
        let script = "tell application \"System Events\" to tell appearance preferences to set dark mode to not dark mode"
        NSAppleScript(source: script)?.executeAndReturnError(nil)
    }

    private func sendMediaKey(code: Int32) {
        HapticFeedback.tick()
        let musicScript = """
        if application "Music" is running then
            tell application "Music" to playpause
        else if application "Spotify" is running then
            tell application "Spotify" to playpause
        end if
        """
        NSAppleScript(source: musicScript)?.executeAndReturnError(nil)
    }
}
