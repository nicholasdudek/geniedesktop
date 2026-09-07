import AppKit
import SwiftUI

public struct MasterVolumePopoverView: View {
    @ObservedObject var volumeManager = MultiOutputVolumeManager.shared
    @AppStorage(PrefKey.appLanguage) var appLanguage: String = "English (US)"

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header: Master Volume Genie
            HStack {
                Image(systemName: "wand.and.stars")
                    .foregroundColor(.yellow)
                    .font(.system(size: 13, weight: .bold))
                Text(LocalizedStrings.translateText("Master Volume Genie", lang: appLanguage))
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                Spacer()
                Text("\(Int(volumeManager.masterVolume * 100))%")
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(volumeManager.isMasterMuted ? .secondary : .primary)
            }

            // Master Slider & Mute
            HStack(spacing: 8) {
                Button(action: {
                    volumeManager.toggleMasterMute()
                }) {
                    Image(systemName: volumeManager.isMasterMuted ? "speaker.slash.fill" : "speaker.wave.3.fill")
                        .font(.system(size: 13))
                        .foregroundColor(volumeManager.isMasterMuted ? .red : .primary)
                        .frame(width: 20)
                }
                .buttonStyle(.plain)
                .help(volumeManager.isMasterMuted ? "Unmute All" : "Mute All")

                Slider(value: Binding(
                    get: { volumeManager.masterVolume },
                    set: { volumeManager.setMasterVolume($0) }
                ), in: 0.0...1.0)
                .accentColor(.blue)
            }

            // Sync all toggle
            HStack {
                Toggle(isOn: $volumeManager.syncAllSpeakers) {
                    Text(LocalizedStrings.translateText("Sync All Connected Speakers", lang: appLanguage))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .toggleStyle(.checkbox)
                .controlSize(.small)
            }

            Divider().opacity(0.4)

            // Output Devices Section
            Text(LocalizedStrings.translateText("OUTPUT SPEAKERS & DEVICES", lang: appLanguage))
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.secondary)

            VStack(spacing: 6) {
                if volumeManager.devices.isEmpty {
                    Text(LocalizedStrings.translateText("No Audio Output Devices Found", lang: appLanguage))
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                        .padding(.vertical, 4)
                } else {
                    ForEach(volumeManager.devices) { dev in
                        VStack(spacing: 4) {
                            HStack(spacing: 6) {
                                Image(systemName: dev.iconName)
                                    .font(.system(size: 11))
                                    .foregroundColor(dev.isDefault ? .blue : .primary)
                                    .frame(width: 16)

                                Text(dev.name)
                                    .font(.system(size: 11, weight: dev.isDefault ? .bold : .medium))
                                    .lineLimit(1)

                                Spacer()

                                if dev.isDefault {
                                    Text(LocalizedStrings.translateText("DEFAULT", lang: appLanguage))
                                        .font(.system(size: 8, weight: .heavy))
                                        .padding(.horizontal, 4)
                                        .padding(.vertical, 1.5)
                                        .background(Color.blue.opacity(0.18))
                                        .foregroundColor(.blue)
                                        .cornerRadius(3)
                                } else {
                                    Button(LocalizedStrings.translateText("Set Default", lang: appLanguage)) {
                                        volumeManager.setDefaultDevice(id: dev.id)
                                    }
                                    .font(.system(size: 9))
                                    .buttonStyle(.borderless)
                                }

                                if dev.canSetMute {
                                    Button(action: {
                                        volumeManager.toggleDeviceMute(id: dev.id)
                                    }) {
                                        Image(systemName: dev.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                            .font(.system(size: 10))
                                            .foregroundColor(dev.isMuted ? .red : .secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }

                            if dev.canSetVolume {
                                HStack(spacing: 6) {
                                    Slider(value: Binding(
                                        get: { dev.volume },
                                        set: { volumeManager.setDeviceVolume(id: dev.id, volume: $0) }
                                    ), in: 0.0...1.0)
                                    .accentColor(.blue)

                                    Text("\(Int(dev.volume * 100))%")
                                        .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                                        .foregroundColor(.secondary)
                                        .frame(width: 32, alignment: .trailing)
                                }
                            } else {
                                HStack {
                                    Text(LocalizedStrings.translateText(dev.channels > 0 ? "Multi-channel fixed / aggregate" : "Fixed volume", lang: appLanguage))
                                        .font(.system(size: 9))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                            }
                        }
                        .padding(6)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.primary.opacity(0.04)))
                    }
                }
            }

            Divider().opacity(0.4)

            // Sound Settings Button
            Button(action: {
                AppDelegate.shared?.showMenuBarSettingsDropdown(targetTab: .soundHaptics)
            }) {
                HStack {
                    Image(systemName: "gearshape")
                        .font(.system(size: 10))
                    Text(LocalizedStrings.translateText("Sound & Haptics Settings...", lang: appLanguage))
                        .font(.system(size: 11))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 2)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .frame(width: 290)
    }
}
