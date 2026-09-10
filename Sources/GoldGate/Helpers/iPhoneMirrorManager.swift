import AppKit
import CoreGraphics
import Foundation
import SwiftUI
import Vision

// MARK: - iPhone Screen Mirror Manager (Chat Default Viewer Engine)

@MainActor
public final class iPhoneMirrorManager: ObservableObject {
    public static let shared = iPhoneMirrorManager()

    nonisolated public static let bundleID = "com.apple.ScreenContinuity"
    nonisolated public static let appName = "iPhone Mirroring"

    @Published public private(set) var isRunning: Bool = false
    @Published public private(set) var isStreaming: Bool = false
    @Published public private(set) var currentFrame: NSImage? = nil
    @Published public private(set) var windowBounds: CGRect = .zero
    @Published public private(set) var windowID: CGWindowID? = nil
    @Published public private(set) var recognizedText: String = ""
    @Published public private(set) var isOcrBusy: Bool = false
    @Published public var isAudioSynced: Bool = true
    @Published public var mirrorScale: CGFloat = 1.0

    @AppStorage(PrefKey.chatIsDefaultiPhoneMirrorViewer) public var isDefaultViewer: Bool = true

    private var streamTimer: Timer?
    private var isCapturing: Bool = false
    private var lastOcrTime: TimeInterval = 0.0

    private init() {
        checkAppRunning()
        setupLifecycleObservers()
    }

    // MARK: - Process Lifecycle Observers

    private func setupLifecycleObservers() {
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notif in
            guard let app = notif.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
            if app.bundleIdentifier == Self.bundleID || app.localizedName == Self.appName {
                Task { @MainActor [weak self] in
                    self?.isRunning = true
                    self?.refreshWindowInfo()
                    if self?.isDefaultViewer == true {
                        self?.startStreaming()
                        NotificationCenter.default.post(name: NSNotification.Name("NexusSummoniPhoneMirrorViewer"), object: nil)
                    }
                }
            }
        }

        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didTerminateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notif in
            guard let app = notif.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
            if app.bundleIdentifier == Self.bundleID || app.localizedName == Self.appName {
                Task { @MainActor [weak self] in
                    self?.isRunning = false
                    self?.stopStreaming()
                    self?.currentFrame = nil
                }
            }
        }
    }

    public func checkAppRunning() {
        let runningApps = NSRunningApplication.runningApplications(withBundleIdentifier: Self.bundleID)
        if let app = runningApps.first, !app.isTerminated {
            self.isRunning = true
            refreshWindowInfo()
        } else {
            let byName = NSWorkspace.shared.runningApplications.filter { $0.localizedName == Self.appName }
            self.isRunning = !byName.isEmpty
            if self.isRunning {
                refreshWindowInfo()
            }
        }
    }

    // MARK: - Window Discovery

    public func refreshWindowInfo() {
        guard let list = CGWindowListCopyWindowInfo([.optionAll, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
            return
        }

        for entry in list {
            let ownerName = entry[kCGWindowOwnerName as String] as? String ?? ""
            let wid = entry[kCGWindowNumber as String] as? CGWindowID ?? 0
            let boundsDict = entry[kCGWindowBounds as String] as? [String: CGFloat] ?? [:]
            let w = boundsDict["Width"] ?? 0
            let h = boundsDict["Height"] ?? 0

            if (ownerName == Self.appName || ownerName.contains("ScreenContinuity")) && w > 120 && h > 200 {
                self.windowID = wid
                self.windowBounds = CGRect(
                    x: boundsDict["X"] ?? 0,
                    y: boundsDict["Y"] ?? 0,
                    width: w,
                    height: h
                )
                self.isRunning = true
                return
            }
        }
    }

    // MARK: - Launch & Control

    public func launchOrActivateApp() {
        HapticFeedback.selection()
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: Self.bundleID) {
            let config = NSWorkspace.OpenConfiguration()
            config.activates = false
            NSWorkspace.shared.openApplication(at: appURL, configuration: config) { [weak self] _, _ in
                Task { @MainActor [weak self] in
                    self?.isRunning = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        self?.refreshWindowInfo()
                        self?.startStreaming()
                    }
                }
            }
        } else {
            let defaultPath = "/System/Applications/iPhone Mirroring.app"
            if FileManager.default.fileExists(atPath: defaultPath) {
                let url = URL(fileURLWithPath: defaultPath)
                let config = NSWorkspace.OpenConfiguration()
                config.activates = false
                NSWorkspace.shared.openApplication(at: url, configuration: config) { [weak self] _, _ in
                    Task { @MainActor [weak self] in
                        self?.isRunning = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                            self?.refreshWindowInfo()
                            self?.startStreaming()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Frame Streaming

    public func startStreaming(fps: Double = 30.0) {
        guard streamTimer == nil else { return }
        checkAppRunning()
        isStreaming = true

        let interval = 1.0 / max(10.0, min(60.0, fps))
        let timer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.captureFrame()
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        streamTimer = timer
        captureFrame()
    }

    public func stopStreaming() {
        streamTimer?.invalidate()
        streamTimer = nil
        isStreaming = false
        isCapturing = false
    }

    public func toggleStreaming() {
        if isStreaming {
            stopStreaming()
        } else {
            startStreaming()
        }
    }

    private func captureFrame() {
        guard !isCapturing else { return }
        if windowID == nil {
            refreshWindowInfo()
        }
        guard let wid = windowID else { return }

        isCapturing = true

        Task.detached(priority: .userInitiated) { [weak self, wid] in
            defer {
                Task { @MainActor [weak self] in
                    self?.isCapturing = false
                }
            }

            guard let cgImg = safeCGWindowListCreateImage(.null, .optionIncludingWindow, wid, [.bestResolution, .nominalResolution]) else {
                return
            }

            let nsImg = NSImage(cgImage: cgImg, size: NSSize(width: cgImg.width, height: cgImg.height))

            Task { @MainActor [weak self] in
                guard let self = self else { return }
                self.currentFrame = nsImg

                // Periodic live OCR (once every 1.5 seconds)
                let now = ProcessInfo.processInfo.systemUptime
                if now - self.lastOcrTime >= 1.5 && !self.isOcrBusy {
                    self.lastOcrTime = now
                    self.performOCR(on: cgImg)
                }
            }
        }
    }

    // MARK: - Live Vision OCR

    private func performOCR(on cgImage: CGImage) {
        isOcrBusy = true
        Task.detached(priority: .utility) { [weak self] in
            defer {
                Task { @MainActor [weak self] in
                    self?.isOcrBusy = false
                }
            }

            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            try? handler.perform([request])

            guard let observations = request.results else { return }
            let text = observations.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")

            Task { @MainActor [weak self] in
                self?.recognizedText = text
            }
        }
    }

    // MARK: - Interactive Click Forwarding

    public func forwardClick(normalizedX: CGFloat, normalizedY: CGFloat) {
        guard windowBounds.width > 0, windowBounds.height > 0 else { return }

        let clickScreenX = windowBounds.origin.x + (normalizedX * windowBounds.width)
        let clickScreenY = windowBounds.origin.y + (normalizedY * windowBounds.height)
        let clickPoint = CGPoint(x: clickScreenX, y: clickScreenY)

        HapticFeedback.tick()

        let source = CGEventSource(stateID: .hidSystemState)
        if let mouseDown = CGEvent(mouseEventSource: source, mouseType: .leftMouseDown, mouseCursorPosition: clickPoint, mouseButton: .left),
           let mouseUp = CGEvent(mouseEventSource: source, mouseType: .leftMouseUp, mouseCursorPosition: clickPoint, mouseButton: .left) {
            mouseDown.post(tap: .cghidEventTap)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                mouseUp.post(tap: .cghidEventTap)
            }
        }
    }

    // MARK: - Exports & Shortcuts

    public func copyFrameToClipboard() {
        guard let img = currentFrame else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([img])
        HapticFeedback.selection()
    }

    public func copyRecognizedText() {
        guard !recognizedText.isEmpty else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(recognizedText, forType: .string)
        HapticFeedback.selection()
    }

    public func saveToPolaroid() {
        guard let img = currentFrame else { return }
        HapticFeedback.heavy()
        let filename = "iPhone_Mirror_\(Int(Date().timeIntervalSince1970)).png"
        let desktopURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop/\(filename)")
        if let tiff = img.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff), let png = rep.representation(using: .png, properties: [:]) {
            try? png.write(to: desktopURL)
        }
        DesktopStickyManager.shared.addNote(
            content: "iPhone Screen Capture 📱\n\(recognizedText.prefix(120))",
            colorName: "Blue",
            isPolaroid: true,
            photoPath: desktopURL.path
        )
    }
}
