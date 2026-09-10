import AppKit
import Foundation

// MARK: - Native macOS Desktop Screen Recorder
@MainActor
public final class DesktopScreenRecorder: ObservableObject {
    public static let shared = DesktopScreenRecorder()

    @Published public var isRecording: Bool = false
    @Published public var elapsedSeconds: Int = 0
    @Published public var lastRecordingURL: URL? = nil
    @Published public var statusMessage: String = "Ready"

    private var recordProcess: Process?
    private var timer: Timer?
    private var outputURL: URL?

    private init() {}

    /// Begins recording the screen using native macOS screencapture
    @discardableResult
    public func startRecording(duration: TimeInterval? = nil, destinationFolder: URL? = nil) -> URL? {
        guard !isRecording else { return nil }
        // This records by spawning /usr/sbin/screencapture. Screen recording
        // itself is sandbox-legal via ScreenCaptureKit, but *this*
        // implementation is not — see GenieCapabilities.canRecordScreen.
        guard GenieCapabilities.canSpawnSubprocesses else {
            statusMessage = GenieCapabilities.unavailableMessage("Screen recording")
            return nil
        }

        let folder = destinationFolder ?? GenieStandardDirectories.recordingsURL
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let filename = "Genie_Screen_Recording_\(formatter.string(from: Date())).mov"
        let targetURL = folder.appendingPathComponent(filename)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
        process.arguments = ["-v", targetURL.path]

        do {
            try process.run()
            self.recordProcess = process
            self.outputURL = targetURL
            self.isRecording = true
            self.elapsedSeconds = 0
            self.statusMessage = "Recording screen..."
            HapticFeedback.playCameraSnapshotSound()

            NotificationCenter.default.post(
                name: NSNotification.Name("NexusScreenRecordingStarted"),
                object: targetURL
            )

            // Start elapsed timer
            self.timer?.invalidate()
            self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
                Task { @MainActor [weak self] in
                    guard let self = self, self.isRecording else { return }
                    self.elapsedSeconds += 1
                }
            }

            // Auto-stop if duration specified
            if let duration = duration, duration > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + duration) { [weak self] in
                    self?.stopRecording()
                }
            }

            return targetURL
        } catch {
            self.statusMessage = "Failed to launch screen recorder: \(error.localizedDescription)"
            return nil
        }
    }

    /// Stops the active recording process and finalizes video
    @discardableResult
    public func stopRecording() -> URL? {
        guard isRecording, let process = recordProcess else { return nil }

        self.timer?.invalidate()
        self.timer = nil

        // Send SIGINT / interrupt to allow screencapture to cleanly write video header
        process.interrupt()

        // Wait up to 1 second for termination
        DispatchQueue.global(qos: .userInitiated).async {
            process.waitUntilExit()
            Task { @MainActor in
                self.isRecording = false
                self.recordProcess = nil
                let finalURL = self.outputURL
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
        }

        return outputURL
    }

    /// Takes a one-shot screenshot and saves it to Polaroids
    @discardableResult
    public func captureSnapshot(destinationFolder: URL? = nil) -> URL? {
        guard GenieCapabilities.canSpawnSubprocesses else {
            statusMessage = GenieCapabilities.unavailableMessage("Screenshots")
            return nil
        }
        let folder = destinationFolder ?? GenieStandardDirectories.polaroidsURL
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let filename = "Genie_Polaroid_\(formatter.string(from: Date())).png"
        let targetURL = folder.appendingPathComponent(filename)

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
}
