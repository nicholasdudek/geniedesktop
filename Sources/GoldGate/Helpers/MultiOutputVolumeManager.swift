import AppKit
import AudioToolbox
import CoreAudio
import SwiftUI

// MARK: - Audio Output Speaker Model
public struct AudioOutputSpeaker: Identifiable, Equatable {
    public let id: AudioDeviceID
    public let uid: String
    public let name: String
    public let channels: Int
    public var volume: Double        // 0.0 ... 1.0
    public var isMuted: Bool
    public var isDefault: Bool
    public var canSetVolume: Bool
    public var canSetMute: Bool
    public var iconName: String

    public init(
        id: AudioDeviceID,
        uid: String,
        name: String,
        channels: Int,
        volume: Double,
        isMuted: Bool,
        isDefault: Bool,
        canSetVolume: Bool,
        canSetMute: Bool,
        iconName: String
    ) {
        self.id = id
        self.uid = uid
        self.name = name
        self.channels = channels
        self.volume = volume
        self.isMuted = isMuted
        self.isDefault = isDefault
        self.canSetVolume = canSetVolume
        self.canSetMute = canSetMute
        self.iconName = iconName
    }
}

// MARK: - Multi-Output Volume Manager
@MainActor
public final class MultiOutputVolumeManager: ObservableObject {
    public static let shared = MultiOutputVolumeManager()

    @Published public var devices: [AudioOutputSpeaker] = []
    @Published public var masterVolume: Double = 0.50
    @Published public var isMasterMuted: Bool = false
    @Published public var syncAllSpeakers: Bool = true

    private var refreshTimer: Timer?
    private var isUpdatingInternally: Bool = false
    private var globalMediaMonitor: Any?
    private var localMediaMonitor: Any?

    public init() {
        refreshDevices()
        setupTimer()
        setupKeyboardVolumeMonitor()
    }

    deinit {
        refreshTimer?.invalidate()
        if let g = globalMediaMonitor { NSEvent.removeMonitor(g) }
        if let l = localMediaMonitor { NSEvent.removeMonitor(l) }
    }

    private func setupTimer() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, !self.isUpdatingInternally else { return }
                self.refreshDevices()
            }
        }
    }

    // MARK: - Discover & Query Devices
    public func refreshDevices() {
        var prop = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0
        let sizeStatus = AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &prop,
            0,
            nil,
            &dataSize
        )
        guard sizeStatus == noErr else { return }

        let deviceCount = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        var deviceIDs = [AudioDeviceID](repeating: 0, count: deviceCount)
        let getStatus = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &prop,
            0,
            nil,
            &dataSize,
            &deviceIDs
        )
        guard getStatus == noErr else { return }

        // Get default device ID
        let defaultId = getDefaultOutputDeviceID()

        var discovered: [AudioOutputSpeaker] = []

        for id in deviceIDs {
            // Check if device has output streams
            guard let channels = getOutputChannelCount(id: id), channels > 0 else {
                continue
            }

            let name = getDeviceName(id: id)
            let uid = getDeviceUID(id: id)
            let (vol, canVol) = getDeviceVolume(id: id)
            let (muted, canMute) = getDeviceMute(id: id)
            let isDef = (id == defaultId)
            let icon = resolveDeviceIcon(name: name, id: id)

            discovered.append(AudioOutputSpeaker(
                id: id,
                uid: uid,
                name: name,
                channels: channels,
                volume: Double(vol),
                isMuted: muted,
                isDefault: isDef,
                canSetVolume: canVol,
                canSetMute: canMute,
                iconName: icon
            ))
        }

        self.devices = discovered

        // Sync master volume with default device
        if let def = discovered.first(where: { $0.isDefault && $0.canSetVolume }) {
            self.masterVolume = def.volume
            self.isMasterMuted = def.isMuted
        } else if let firstControllable = discovered.first(where: { $0.canSetVolume }) {
            self.masterVolume = firstControllable.volume
            self.isMasterMuted = firstControllable.isMuted
        }
    }

    // MARK: - Master Volume Controls
    public func setMasterVolume(_ newVolume: Double) {
        let clamped = max(0.0, min(1.0, newVolume))
        self.masterVolume = clamped
        self.isUpdatingInternally = true
        defer { self.isUpdatingInternally = false }

        if syncAllSpeakers {
            // Apply master volume to all controllable speakers
            for i in 0..<devices.count {
                if devices[i].canSetVolume {
                    devices[i].volume = clamped
                    _ = writeDeviceVolume(id: devices[i].id, volume: Float32(clamped))
                }
            }
        } else {
            // Apply only to default device
            if let defIdx = devices.firstIndex(where: { $0.isDefault && $0.canSetVolume }) {
                devices[defIdx].volume = clamped
                _ = writeDeviceVolume(id: devices[defIdx].id, volume: Float32(clamped))
            }
        }
    }

    public func toggleMasterMute() {
        let newMuted = !isMasterMuted
        self.isMasterMuted = newMuted
        self.isUpdatingInternally = true
        defer { self.isUpdatingInternally = false }

        if syncAllSpeakers {
            for i in 0..<devices.count {
                if devices[i].canSetMute {
                    devices[i].isMuted = newMuted
                    _ = writeDeviceMute(id: devices[i].id, muted: newMuted)
                }
            }
        } else {
            if let defIdx = devices.firstIndex(where: { $0.isDefault && $0.canSetMute }) {
                devices[defIdx].isMuted = newMuted
                _ = writeDeviceMute(id: devices[defIdx].id, muted: newMuted)
            }
        }
    }

    // MARK: - Keyboard Volume Control
    public func stepVolumeUp(by delta: Double = 0.0625) {
        if isMasterMuted {
            toggleMasterMute()
        }
        setMasterVolume(masterVolume + delta)
    }

    public func stepVolumeDown(by delta: Double = 0.0625) {
        setMasterVolume(masterVolume - delta)
    }

    private func setupKeyboardVolumeMonitor() {
        // Intercept macOS media keys:
        // NX_KEYTYPE_SOUND_UP = 0
        // NX_KEYTYPE_SOUND_DOWN = 1
        // NX_KEYTYPE_MUTE = 7
        let handler: (NSEvent) -> Void = { [weak self] event in
            guard event.type == .systemDefined, event.subtype.rawValue == 8 else { return }
            let data1 = event.data1
            let keyCode = (data1 & 0xFFFF0000) >> 16
            let keyFlags = (data1 & 0x0000FFFF)
            let isKeyDown = (((keyFlags & 0xFF00) >> 8)) == 0xA
            guard isKeyDown else { return }

            Task { @MainActor [weak self] in
                guard let self = self else { return }
                switch Int32(keyCode) {
                case 0: // Sound Up
                    self.stepVolumeUp()
                case 1: // Sound Down
                    self.stepVolumeDown()
                case 7: // Mute
                    self.toggleMasterMute()
                default:
                    break
                }
            }
        }

        globalMediaMonitor = NSEvent.addGlobalMonitorForEvents(matching: .systemDefined, handler: handler)
        localMediaMonitor = NSEvent.addLocalMonitorForEvents(matching: .systemDefined) { event in
            handler(event)
            return event
        }
    }

    // MARK: - Individual Speaker Controls
    public func setDeviceVolume(id: AudioDeviceID, volume: Double) {
        let clamped = max(0.0, min(1.0, volume))
        guard let idx = devices.firstIndex(where: { $0.id == id }) else { return }
        devices[idx].volume = clamped

        self.isUpdatingInternally = true
        defer { self.isUpdatingInternally = false }

        _ = writeDeviceVolume(id: id, volume: Float32(clamped))

        if devices[idx].isDefault {
            self.masterVolume = clamped
        }
    }

    public func toggleDeviceMute(id: AudioDeviceID) {
        guard let idx = devices.firstIndex(where: { $0.id == id }) else { return }
        let newMuted = !devices[idx].isMuted
        devices[idx].isMuted = newMuted

        self.isUpdatingInternally = true
        defer { self.isUpdatingInternally = false }

        _ = writeDeviceMute(id: id, muted: newMuted)

        if devices[idx].isDefault {
            self.isMasterMuted = newMuted
        }
    }

    public func setDefaultDevice(id: AudioDeviceID) {
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var devId = id
        let size = UInt32(MemoryLayout<AudioDeviceID>.size)
        let status = AudioObjectSetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &addr,
            0,
            nil,
            size,
            &devId
        )
        if status == noErr {
            refreshDevices()
        }
    }

    // MARK: - CoreAudio Internal Helpers
    private func getDefaultOutputDeviceID() -> AudioDeviceID {
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var devId: AudioDeviceID = 0
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &addr,
            0,
            nil,
            &size,
            &devId
        )
        return devId
    }

    private func getOutputChannelCount(id: AudioDeviceID) -> Int? {
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyStreamConfiguration,
            mScope: kAudioObjectPropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        var size: UInt32 = 0
        let status = AudioObjectGetPropertyDataSize(id, &addr, 0, nil, &size)
        guard status == noErr, size > 0 else { return nil }

        let bufferListPtr = UnsafeMutablePointer<AudioBufferList>.allocate(capacity: Int(size))
        defer { bufferListPtr.deallocate() }
        guard AudioObjectGetPropertyData(id, &addr, 0, nil, &size, bufferListPtr) == noErr else { return nil }

        let buffers = UnsafeMutableAudioBufferListPointer(bufferListPtr)
        var channels = 0
        for buf in buffers {
            channels += Int(buf.mNumberChannels)
        }
        return channels
    }

    private func getDeviceName(id: AudioDeviceID) -> String {
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var cfName: Unmanaged<CFString>?
        var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        if AudioObjectGetPropertyData(id, &addr, 0, nil, &size, &cfName) == noErr,
           let cf = cfName {
            return cf.takeRetainedValue() as String
        }
        return "Audio Output \(id)"
    }

    private func getDeviceUID(id: AudioDeviceID) -> String {
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceUID,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var cfUID: Unmanaged<CFString>?
        var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        if AudioObjectGetPropertyData(id, &addr, 0, nil, &size, &cfUID) == noErr,
           let cf = cfUID {
            return cf.takeRetainedValue() as String
        }
        return "\(id)"
    }

    private func getDeviceVolume(id: AudioDeviceID) -> (Float32, Bool) {
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        var vol: Float32 = 0.0
        var size = UInt32(MemoryLayout<Float32>.size)
        if AudioObjectGetPropertyData(id, &addr, 0, nil, &size, &vol) == noErr {
            return (vol, true)
        }

        // Try channel 1
        addr.mElement = 1
        if AudioObjectGetPropertyData(id, &addr, 0, nil, &size, &vol) == noErr {
            return (vol, true)
        }

        return (0.0, false)
    }

    private func writeDeviceVolume(id: AudioDeviceID, volume: Float32) -> Bool {
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        var vol = max(0.0, min(1.0, volume))
        let size = UInt32(MemoryLayout<Float32>.size)

        var isSettable: DarwinBoolean = false
        if AudioObjectIsPropertySettable(id, &addr, &isSettable) == noErr && isSettable.boolValue {
            return AudioObjectSetPropertyData(id, &addr, 0, nil, size, &vol) == noErr
        }

        // Try channels 1 and 2
        var success = false
        for ch: UInt32 in [1, 2] {
            addr.mElement = ch
            if AudioObjectIsPropertySettable(id, &addr, &isSettable) == noErr && isSettable.boolValue {
                if AudioObjectSetPropertyData(id, &addr, 0, nil, size, &vol) == noErr {
                    success = true
                }
            }
        }
        return success
    }

    private func getDeviceMute(id: AudioDeviceID) -> (Bool, Bool) {
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioObjectPropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        var muted: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        if AudioObjectGetPropertyData(id, &addr, 0, nil, &size, &muted) == noErr {
            return (muted == 1, true)
        }

        addr.mElement = 1
        if AudioObjectGetPropertyData(id, &addr, 0, nil, &size, &muted) == noErr {
            return (muted == 1, true)
        }

        return (false, false)
    }

    private func writeDeviceMute(id: AudioDeviceID, muted: Bool) -> Bool {
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyMute,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: kAudioObjectPropertyElementMain
        )
        var val: UInt32 = muted ? 1 : 0
        let size = UInt32(MemoryLayout<UInt32>.size)

        var isSettable: DarwinBoolean = false
        if AudioObjectIsPropertySettable(id, &addr, &isSettable) == noErr && isSettable.boolValue {
            return AudioObjectSetPropertyData(id, &addr, 0, nil, size, &val) == noErr
        }

        var success = false
        for ch: UInt32 in [1, 2] {
            addr.mElement = ch
            if AudioObjectIsPropertySettable(id, &addr, &isSettable) == noErr && isSettable.boolValue {
                if AudioObjectSetPropertyData(id, &addr, 0, nil, size, &val) == noErr {
                    success = true
                }
            }
        }
        return success
    }

    private func getDeviceTransportType(id: AudioDeviceID) -> UInt32 {
        var addr = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyTransportType,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var transport: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        if AudioObjectGetPropertyData(id, &addr, 0, nil, &size, &transport) == noErr {
            return transport
        }
        return 0
    }

    private func resolveDeviceIcon(name: String, id: AudioDeviceID) -> String {
        let lower = name.lowercased()
        if lower.contains("studio display") {
            return "display"
        } else if lower.contains("pro display") || lower.contains("xdr") {
            return "display"
        } else if lower.contains("airpod") {
            return lower.contains("max") ? "airpodsmax" : "airpodspro"
        } else if lower.contains("beats") {
            return "headphones"
        } else if lower.contains("headphone") || lower.contains("earphone") {
            return "headphones"
        } else if lower.contains("display") || lower.contains("monitor") || lower.contains("screen") || lower.contains("tv") || lower.contains("hdmi") || lower.contains("lg ultra") {
            return "display"
        } else if lower.contains("multi-output") || lower.contains("aggregate") {
            return "hifispeaker.2.fill"
        } else if lower.contains("macbook") || lower.contains("internal") || lower.contains("built-in") {
            return "laptopcomputer"
        } else if lower.contains("imac") || lower.contains("mac mini") || lower.contains("mac studio") || lower.contains("mac pro") {
            return "desktopcomputer"
        } else {
            let transport = getDeviceTransportType(id: id)
            if transport == kAudioDeviceTransportTypeDisplayPort || transport == kAudioDeviceTransportTypeHDMI || transport == kAudioDeviceTransportTypeThunderbolt {
                return "display"
            } else if transport == kAudioDeviceTransportTypeBluetooth || transport == kAudioDeviceTransportTypeBluetoothLE {
                return "headphones"
            } else if transport == kAudioDeviceTransportTypeUSB {
                return "hifispeaker.fill"
            }
            return "speaker.wave.2.fill"
        }
    }
}
