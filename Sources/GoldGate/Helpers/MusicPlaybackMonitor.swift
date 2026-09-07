import Foundation
import CoreAudio
import Combine

// MARK: - Music Playback Monitor
//
// Detects whether audio is currently being rendered to the default output device using the
// public CoreAudio `kAudioDevicePropertyDeviceIsRunningSomewhere` property. No microphone,
// no private MediaRemote APIs, no network: it simply asks the audio HAL whether any process
// has an active output stream. A short debounce filters out UI clicks and notification pings
// so only sustained playback (music, video, podcasts) counts as "music playing".

@MainActor
public final class MusicPlaybackMonitor: ObservableObject {
    public static let shared = MusicPlaybackMonitor()

    /// Raw HAL state: some process is streaming to the default output right now.
    @Published public private(set) var isAudioPlaying: Bool = false
    /// Debounced state used by animations: audio has been playing for a sustained period.
    @Published public private(set) var isMusicPlaying: Bool = false
    /// Name of the output device being watched (for the settings UI).
    @Published public private(set) var outputDeviceName: String = "Default Output"

    private var pollTimer: Timer?
    private var runningSince: Date?
    private var lastRunning: Date?
    private var watchedDevice: AudioDeviceID = 0
    private var runningListener: AudioObjectPropertyListenerBlock?
    private var defaultDeviceListener: AudioObjectPropertyListenerBlock?

    private let onDelay: TimeInterval = 1.2
    private let offDelay: TimeInterval = 2.5

    private init() {
        start()
    }

    public func start() {
        guard pollTimer == nil else { return }
        installDefaultDeviceListener()
        rewatchDefaultDevice()
        poll()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.poll() }
        }
        pollTimer?.tolerance = 0.25
    }

    public func stop() {
        pollTimer?.invalidate()
        pollTimer = nil
        removeRunningListener()
    }

    // MARK: Sampling

    private func poll() {
        let running = watchedDevice != 0 && Self.isDeviceRunningSomewhere(watchedDevice)
        let now = Date()
        if running {
            if runningSince == nil { runningSince = now }
            lastRunning = now
        } else {
            runningSince = nil
        }
        if isAudioPlaying != running { isAudioPlaying = running }

        let shouldBeOn: Bool
        if let since = runningSince, now.timeIntervalSince(since) >= onDelay {
            shouldBeOn = true
        } else if isMusicPlaying, let last = lastRunning, now.timeIntervalSince(last) < offDelay {
            shouldBeOn = true
        } else {
            shouldBeOn = false
        }
        if isMusicPlaying != shouldBeOn { isMusicPlaying = shouldBeOn }
    }

    // MARK: CoreAudio plumbing

    private static func defaultOutputDevice() -> AudioDeviceID {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var deviceID = AudioDeviceID(0)
        var size = UInt32(MemoryLayout<AudioDeviceID>.size)
        let status = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &address, 0, nil, &size, &deviceID)
        return status == noErr ? deviceID : 0
    }

    private static func isDeviceRunningSomewhere(_ deviceID: AudioDeviceID) -> Bool {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var value: UInt32 = 0
        var size = UInt32(MemoryLayout<UInt32>.size)
        let status = AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, &value)
        return status == noErr && value != 0
    }

    private static func deviceName(_ deviceID: AudioDeviceID) -> String {
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioObjectPropertyName,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        var name: Unmanaged<CFString>?
        var size = UInt32(MemoryLayout<Unmanaged<CFString>?>.size)
        let status = withUnsafeMutablePointer(to: &name) { ptr in
            AudioObjectGetPropertyData(deviceID, &address, 0, nil, &size, ptr)
        }
        guard status == noErr, let cf = name?.takeRetainedValue() else { return "Default Output" }
        return cf as String
    }

    private func rewatchDefaultDevice() {
        removeRunningListener()
        watchedDevice = Self.defaultOutputDevice()
        guard watchedDevice != 0 else { return }
        outputDeviceName = Self.deviceName(watchedDevice)

        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        let block: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            Task { @MainActor in self?.poll() }
        }
        if AudioObjectAddPropertyListenerBlock(watchedDevice, &address, DispatchQueue.main, block) == noErr {
            runningListener = block
        }
    }

    private func removeRunningListener() {
        guard watchedDevice != 0, let block = runningListener else { return }
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceIsRunningSomewhere,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        AudioObjectRemovePropertyListenerBlock(watchedDevice, &address, DispatchQueue.main, block)
        runningListener = nil
    }

    private func installDefaultDeviceListener() {
        guard defaultDeviceListener == nil else { return }
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        let block: AudioObjectPropertyListenerBlock = { [weak self] _, _ in
            Task { @MainActor in
                self?.rewatchDefaultDevice()
                self?.poll()
            }
        }
        if AudioObjectAddPropertyListenerBlock(AudioObjectID(kAudioObjectSystemObject), &address, DispatchQueue.main, block) == noErr {
            defaultDeviceListener = block
        }
    }
}
