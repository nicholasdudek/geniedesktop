import AppKit
import Foundation
import ScreenCaptureKit
import ImageIO
import UniformTypeIdentifiers

// MARK: - Native ScreenCaptureKit Delegate for macOS 15+
@available(macOS 15.0, *)
private final class DesktopScreenRecorderSCKitDelegate: NSObject, SCRecordingOutputDelegate, @unchecked Sendable {
    weak var recorder: DesktopScreenRecorder?

    init(recorder: DesktopScreenRecorder) {
        self.recorder = recorder
    }

    func recordingOutput(_ recordingOutput: SCRecordingOutput, didFailWithError error: Error) {
        Task { @MainActor [weak recorder] in
            recorder?.statusMessage = "Recording error: \(error.localizedDescription)"
            recorder?.stopRecording()
        }
    }

    func recordingOutputDidFinishRecording(_ recordingOutput: SCRecordingOutput) {
        Task { @MainActor [weak recorder] in
            recorder?.isRecording = false
        }
    }
}

// MARK: - Native macOS Desktop Screen Recorder
@MainActor
public final class DesktopScreenRecorder: ObservableObject {
    public static let shared = DesktopScreenRecorder()

    @Published public var isRecording: Bool = false
    @Published public var elapsedSeconds: Int = 0
    @Published public var lastRecordingURL: URL? = nil
    @Published public var statusMessage: String = "Ready"
    @Published public var permissionDenied: Bool = false

    private var recordProcess: Process?
    private var activeStream: Any?
    private var activeDelegate: Any?
    private var timer: Timer?
    private var outputURL: URL?

    private init() {}

    /// Begins recording the screen using native ScreenCaptureKit or native macOS screencapture
    @discardableResult
    public func startRecording(duration: TimeInterval? = nil, destinationFolder: URL? = nil) -> URL? {
        guard !isRecording else { return nil }

        // 1. Verify and request Screen Recording permission if needed
        if !CGPreflightScreenCaptureAccess() {
            self.permissionDenied = true
            self.statusMessage = "Screen Recording permission required. Enable Genie in System Settings → Privacy & Security → Screen Recording."
            CGRequestScreenCaptureAccess()
            NotificationCenter.default.post(
                name: NSNotification.Name("GenieScreenRecordingPermissionDenied"),
                object: nil
            )
            return nil
        }
        self.permissionDenied = false

        let folder = destinationFolder ?? GenieStandardDirectories.recordingsURL
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let filename = "Genie_Screen_Recording_\(formatter.string(from: Date())).mov"
        let targetURL = folder.appendingPathComponent(filename)

        // Try modern native ScreenCaptureKit recording (macOS 15+, 100% sandbox-legal)
        if #available(macOS 15.0, *) {
            self.outputURL = targetURL
            self.isRecording = true
            self.elapsedSeconds = 0
            self.statusMessage = "Recording screen (ScreenCaptureKit HD)..."
            HapticFeedback.playCameraSnapshotSound()

            NotificationCenter.default.post(
                name: NSNotification.Name("NexusScreenRecordingStarted"),
                object: targetURL
            )

            startTimer(duration: duration)

            Task {
                do {
                    let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                    guard let display = content.displays.first(where: { $0.displayID == CGMainDisplayID() }) ?? content.displays.first else {
                        throw NSError(domain: "DesktopScreenRecorder", code: 1, userInfo: [NSLocalizedDescriptionKey: "No active display found"])
                    }

                    // Exclude Genie's own overlay windows from recording
                    let ownWindows = content.windows.filter { $0.owningApplication?.processID == ProcessInfo.processInfo.processIdentifier }
                    let filter = SCContentFilter(display: display, excludingWindows: ownWindows)

                    let streamConfig = SCStreamConfiguration()
                    streamConfig.width = Int(display.width)
                    streamConfig.height = Int(display.height)
                    streamConfig.showsCursor = true
                    streamConfig.scalesToFit = true

                    let recConfig = SCRecordingOutputConfiguration()
                    recConfig.outputURL = targetURL
                    recConfig.outputFileType = .mov

                    let stream = SCStream(filter: filter, configuration: streamConfig, delegate: nil)
                    let delegate = DesktopScreenRecorderSCKitDelegate(recorder: self)
                    let recordingOutput = SCRecordingOutput(configuration: recConfig, delegate: delegate)
                    try stream.addRecordingOutput(recordingOutput)
                    try await stream.startCapture()

                    self.activeStream = stream
                    self.activeDelegate = delegate
                } catch {
                    self.statusMessage = "ScreenCaptureKit error: \(error.localizedDescription)"
                    if GenieCapabilities.canSpawnSubprocesses {
                        self.startSubprocessRecording(targetURL: targetURL, duration: duration)
                    } else {
                        self.stopRecording()
                    }
                }
            }

            return targetURL
        } else if GenieCapabilities.canSpawnSubprocesses {
            return startSubprocessRecording(targetURL: targetURL, duration: duration)
        } else {
            statusMessage = GenieCapabilities.unavailableMessage("Screen recording")
            return nil
        }
    }

    private func startTimer(duration: TimeInterval?) {
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self, self.isRecording else { return }
                self.elapsedSeconds += 1
            }
        }

        if let duration = duration, duration > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
                self?.stopRecording()
            }
        }
    }

    @discardableResult
    private func startSubprocessRecording(targetURL: URL, duration: TimeInterval?) -> URL? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        process.arguments = ["-v", targetURL.path]

        do {
            try process.run()
            self.recordProcess = process
            self.outputURL = targetURL
            self.isRecording = true
            self.elapsedSeconds = 0
            self.statusMessage = "Recording screen (screencapture)..."
            HapticFeedback.playCameraSnapshotSound()

            NotificationCenter.default.post(
                name: NSNotification.Name("NexusScreenRecordingStarted"),
                object: targetURL
            )

            startTimer(duration: duration)
            return targetURL
        } catch {
            self.statusMessage = "Failed to launch screen recorder: \(error.localizedDescription)"
            self.isRecording = false
            return nil
        }
    }

    /// Stops the active recording process and finalizes video
    @discardableResult
    public func stopRecording() -> URL? {
        guard isRecording else { return nil }

        self.timer?.invalidate()
        self.timer = nil

        let finalURL = self.outputURL

        if #available(macOS 15.0, *), let stream = self.activeStream as? SCStream {
            self.activeStream = nil
            self.activeDelegate = nil
            Task {
                try? await stream.stopCapture()
                await MainActor.run {
                    self.finalizeRecording(finalURL: finalURL)
                }
            }
        } else if let process = self.recordProcess {
            process.interrupt()
            DispatchQueue.global(qos: .userInitiated).async {
                process.waitUntilExit()
                Task { @MainActor in
                    self.finalizeRecording(finalURL: finalURL)
                }
            }
        } else {
            finalizeRecording(finalURL: finalURL)
        }

        return finalURL
    }

    private func finalizeRecording(finalURL: URL?) {
        self.isRecording = false
        self.recordProcess = nil
        self.lastRecordingURL = finalURL
        self.statusMessage = "Saved recording to \(finalURL?.lastPathComponent ?? "Recordings")"
        HapticFeedback.success()

        if let url = finalURL {
            NotificationCenter.default.post(
                name: NSNotification.Name("NexusScreenRecordingFinished"),
                object: url
            )
        }
    }

    /// Takes a one-shot screenshot and saves it to Polaroids
    @discardableResult
    public func captureSnapshot(destinationFolder: URL? = nil) -> URL? {
        let folder = destinationFolder ?? GenieStandardDirectories.polaroidsURL
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let filename = "Genie_Polaroid_\(formatter.string(from: Date())).png"
        let targetURL = folder.appendingPathComponent(filename)

        if CGPreflightScreenCaptureAccess() {
            let screenRect = NSScreen.main?.frame ?? .zero
            if let cgImage = GenieScreenCaptureKitEngine.shared.fallbackCapture(rect: screenRect),
               saveCGImageAsPNG(cgImage, to: targetURL) {
                HapticFeedback.playCameraSnapshotSound()
                self.statusMessage = "Saved Polaroid: \(filename)"
                return targetURL
            }
        }

        if GenieCapabilities.canSpawnSubprocesses {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
            process.arguments = ["-x", "-m", targetURL.path]
            do {
                try process.run()
                process.waitUntilExit()
                HapticFeedback.playCameraSnapshotSound()
                self.statusMessage = "Saved Polaroid: \(filename)"
                return targetURL
            } catch {
                self.statusMessage = "Failed snapshot: \(error.localizedDescription)"
                return nil
            }
        }

        self.statusMessage = "Screen Capture permission required"
        return nil
    }

    private func saveCGImageAsPNG(_ image: CGImage, to url: URL) -> Bool {
        guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
            return false
        }
        CGImageDestinationAddImage(destination, image, nil)
        return CGImageDestinationFinalize(destination)
    }

    /// Open macOS System Settings to Privacy & Security -> Screen Recording
    public func openScreenRecordingSettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
            NSWorkspace.shared.open(url)
        }
    }
}
