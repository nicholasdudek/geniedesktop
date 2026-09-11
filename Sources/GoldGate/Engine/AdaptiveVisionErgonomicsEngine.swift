import AppKit
import Foundation
import AVFoundation
import Vision
import Combine
import SwiftUI

// MARK: - 👁️ Adaptive Vision & Ergonomics Engine
/// Leverages macOS camera (FaceTime HD / Continuity Camera) and Apple Vision framework
/// to dynamically adjust text typography, UI scale, and screen sizing based on:
/// 1. Field of View (FOV) & Screen Distance: Adjusts scale based on how far you sit from the display.
/// 2. Tiredness & Eye Strain: Monitors Eye Aspect Ratio (squinting), blink intervals, and posture
///    to automatically increase font size, enhance text contrast, and apply circadian warmth.
@MainActor
public final class AdaptiveVisionErgonomicsEngine: ObservableObject, @unchecked Sendable {
    public static let shared = AdaptiveVisionErgonomicsEngine()

    // ── Published Observable Ergonomic State ──
    @Published public var isAdaptiveErgonomicsEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(isAdaptiveErgonomicsEnabled, forKey: "genie.ergonomics.enabled")
            if isAdaptiveErgonomicsEnabled {
                startCameraStreamIfNeeded()
            } else {
                stopCameraStream()
                resetToDefaultScale()
            }
        }
    }

    @Published public var isCameraActive: Bool = false
    @Published public var hasCameraPermission: Bool = false
    @Published public var cameraDeviceName: String = "No Camera"

    // Raw & Filtered Vision Metrics
    @Published public var userDistanceNormalized: Float = 0.45    // 0.0 (near/close) to 1.0 (far/wide FOV)
    @Published public var tirednessScore: Float = 0.0             // 0.0 (fully alert) to 1.0 (heavy fatigue/squinting)
    @Published public var eyeAspectRatio: Float = 0.30            // Baseline open eye EAR ~ 0.28 - 0.35
    @Published public var blinkRatePerMinute: Float = 16.0
    @Published public var faceDetected: Bool = false

    // Computed Output Adjustments
    @Published public var dynamicTextScale: CGFloat = 1.0         // 0.95x to 1.50x font scale
    @Published public var dynamicScreenScale: CGFloat = 1.0       // 0.85x to 1.25x workspace zoom
    @Published public var dynamicContrastBoost: Float = 1.0       // 1.0x to 1.45x text contrast
    @Published public var dynamicCircadianWarmth: Float = 0.0     // 0.0 to 0.35 amber relaxation tint
    @Published public var statusMessage: String = "Calibrated · Alert"

    // ── Background Camera Service ──
    private let cameraService = ErgonomicsCameraCaptureService()

    // ── Temporal Smoothing & Blink Tracking ──
    private var lastBlinkTimestamp: TimeInterval = 0.0
    private var recentBlinkIntervals: [TimeInterval] = []
    private var lowEarConsecutiveFrames: Int = 0

    private init() {
        self.isAdaptiveErgonomicsEnabled = UserDefaults.standard.object(forKey: "genie.ergonomics.enabled") as? Bool ?? true
        
        // Wire camera callback
        cameraService.onFaceObservation = { [weak self] face in
            Task { @MainActor [weak self] in
                if let face = face {
                    self?.processFaceObservation(face)
                } else {
                    self?.handleNoFaceDetected()
                }
            }
        }

        cameraService.onStatusChange = { [weak self] active, name, message in
            Task { @MainActor [weak self] in
                self?.isCameraActive = active
                if let name = name { self?.cameraDeviceName = name }
                if let message = message { self?.statusMessage = message }
            }
        }

        checkCameraAuthorization()
    }

    // MARK: - ⚙️ Setup & Permissions
    public func checkCameraAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.hasCameraPermission = true
            if isAdaptiveErgonomicsEnabled {
                startCameraStreamIfNeeded()
            }
        case .notDetermined:
            self.hasCameraPermission = false
        case .denied, .restricted:
            self.hasCameraPermission = false
            self.statusMessage = "Camera Access Restricted · Manual Mode Active"
        @unknown default:
            self.hasCameraPermission = false
        }
    }

    public func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
            Task { @MainActor [weak self] in
                self?.hasCameraPermission = granted
                if granted && self?.isAdaptiveErgonomicsEnabled == true {
                    self?.startCameraStreamIfNeeded()
                }
            }
        }
    }

    public func startCameraStreamIfNeeded() {
        guard isAdaptiveErgonomicsEnabled, hasCameraPermission, !isCameraActive else { return }
        cameraService.start()
    }

    public func stopCameraStream() {
        guard isCameraActive else { return }
        cameraService.stop()
    }

    // MARK: - 🧠 Face & Ergonomics Analysis
    public func processFaceObservation(_ face: VNFaceObservation) {
        self.faceDetected = true

        // 1. Compute Distance / Field of View (FOV)
        let faceBoxWidth = Float(face.boundingBox.width)
        let normalizedDist = 1.0 - simd_clamp((faceBoxWidth - 0.15) / (0.45 - 0.15), 0.0, 1.0)
        self.userDistanceNormalized = 0.85 * self.userDistanceNormalized + 0.15 * normalizedDist

        // 2. Compute Eye Aspect Ratio (EAR) & Squinting / Fatigue
        var currentEAR: Float = 0.30
        if let landmarks = face.landmarks,
           let leftEye = landmarks.leftEye,
           let rightEye = landmarks.rightEye {
            let leftEAR = calculateEAR(landmarks: leftEye.normalizedPoints)
            let rightEAR = calculateEAR(landmarks: rightEye.normalizedPoints)
            currentEAR = (leftEAR + rightEAR) * 0.5
        }

        self.eyeAspectRatio = 0.80 * self.eyeAspectRatio + 0.20 * currentEAR

        // 3. Squinting & Tiredness Evaluation
        if currentEAR < 0.21 {
            lowEarConsecutiveFrames += 1
        } else {
            lowEarConsecutiveFrames = max(0, lowEarConsecutiveFrames - 1)
        }

        let now = Date().timeIntervalSince1970
        if currentEAR < 0.17 && (now - lastBlinkTimestamp) > 0.25 {
            let interval = now - lastBlinkTimestamp
            lastBlinkTimestamp = now
            if interval < 10.0 {
                recentBlinkIntervals.append(interval)
                if recentBlinkIntervals.count > 10 {
                    recentBlinkIntervals.removeFirst()
                }
                let avgInterval = recentBlinkIntervals.reduce(0, +) / Double(recentBlinkIntervals.count)
                self.blinkRatePerMinute = Float(60.0 / max(0.5, avgInterval))
            }
        }

        let squintFactor = simd_clamp(Float(lowEarConsecutiveFrames) / 25.0, 0.0, 1.0)
        let blinkFatigueFactor = simd_clamp((25.0 - self.blinkRatePerMinute) / 18.0, 0.0, 1.0)
        let rawTiredness = max(squintFactor, blinkFatigueFactor * 0.6)
        
        self.tirednessScore = 0.90 * self.tirednessScore + 0.10 * rawTiredness

        // 4. Update Dynamic Output Controls
        updateDynamicScaling()
    }

    public func handleNoFaceDetected() {
        self.faceDetected = false
        self.userDistanceNormalized = 0.95 * self.userDistanceNormalized + 0.05 * 0.45
        self.tirednessScore = 0.95 * self.tirednessScore + 0.05 * 0.0
        updateDynamicScaling()
    }

    // MARK: - 📐 Compute EAR (Eye Aspect Ratio)
    private func calculateEAR(landmarks: [CGPoint]) -> Float {
        guard landmarks.count >= 6 else { return 0.30 }
        let p1 = landmarks[1], p5 = landmarks[5]
        let p2 = landmarks[2], p4 = landmarks[4]
        let p0 = landmarks[0], p3 = landmarks[3]

        let distA = hypot(p1.x - p5.x, p1.y - p5.y)
        let distB = hypot(p2.x - p4.x, p2.y - p4.y)
        let distC = hypot(p0.x - p3.x, p0.y - p3.y)

        guard distC > 0.001 else { return 0.30 }
        return Float((distA + distB) / (2.0 * distC))
    }

    // MARK: - 🎛️ Update Dynamic Scaling & Typography
    private func updateDynamicScaling() {
        let distanceTextBoost = CGFloat(self.userDistanceNormalized) * 0.35 // Up to +35% font size
        let fatigueTextBoost = CGFloat(self.tirednessScore) * 0.25         // Up to +25% font size when tired
        self.dynamicTextScale = 1.0 + distanceTextBoost + fatigueTextBoost

        let distanceScreenBoost = CGFloat(self.userDistanceNormalized) * 0.20
        self.dynamicScreenScale = 1.0 + distanceScreenBoost

        self.dynamicContrastBoost = 1.0 + (self.tirednessScore * 0.45)
        self.dynamicCircadianWarmth = self.tirednessScore * 0.35

        if self.tirednessScore > 0.65 {
            self.statusMessage = "Eye Fatigue Detected · Boosting Contrast & Font Scale"
        } else if self.userDistanceNormalized > 0.70 {
            self.statusMessage = "Wide Field of View (Distance) · Enlarging Typography"
        } else if self.userDistanceNormalized < 0.25 {
            self.statusMessage = "Close View · Compact Ergonomics"
        } else {
            self.statusMessage = "Calibrated · Normal Ergonomics"
        }

        MetalTypographySharpeningProcessor.shared.updateConfig(
            sharpnessStrength: 0.85 + (self.tirednessScore * 0.30),
            textContrastBoost: self.dynamicContrastBoost,
            antiRingingClamp: 0.15
        )

        NotificationCenter.default.post(
            name: Notification.Name("GenieAdaptiveErgonomicsChanged"),
            object: nil,
            userInfo: [
                "textScale": self.dynamicTextScale,
                "screenScale": self.dynamicScreenScale,
                "contrastBoost": self.dynamicContrastBoost,
                "warmth": self.dynamicCircadianWarmth
            ]
        )
    }

    public func resetToDefaultScale() {
        self.dynamicTextScale = 1.0
        self.dynamicScreenScale = 1.0
        self.dynamicContrastBoost = 1.0
        self.dynamicCircadianWarmth = 0.0
        self.statusMessage = "Ergonomics Reset to Default"
        MetalTypographySharpeningProcessor.shared.updateConfig(
            sharpnessStrength: 0.85,
            textContrastBoost: 1.25,
            antiRingingClamp: 0.15
        )
    }

    public func setManualSimulation(distance: Float, fatigue: Float) {
        self.userDistanceNormalized = simd_clamp(distance, 0.0, 1.0)
        self.tirednessScore = simd_clamp(fatigue, 0.0, 1.0)
        updateDynamicScaling()
    }
}

// MARK: - 🎥 Dedicated Background Camera Service
private final class ErgonomicsCameraCaptureService: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, @unchecked Sendable {
    var onFaceObservation: (@Sendable (VNFaceObservation?) -> Void)?
    var onStatusChange: (@Sendable (Bool, String?, String?) -> Void)?

    private let captureSession = AVCaptureSession()
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let videoProcessingQueue = DispatchQueue(label: "com.nicholasdudek.genie.vision.queue", qos: .userInteractive)
    private var sequenceHandler = VNSequenceRequestHandler()
    private var faceLandmarksRequest: VNDetectFaceLandmarksRequest?

    override init() {
        super.init()
        let req = VNDetectFaceLandmarksRequest { [weak self] request, error in
            guard let self = self, error == nil,
                  let results = request.results as? [VNFaceObservation],
                  let primaryFace = results.first else {
                self?.onFaceObservation?(nil)
                return
            }
            self.onFaceObservation?(primaryFace)
        }
        req.preferBackgroundProcessing = true
        self.faceLandmarksRequest = req
    }

    func start() {
        videoProcessingQueue.async { [weak self] in
            guard let self = self else { return }
            if self.captureSession.isRunning { return }

            self.captureSession.beginConfiguration()
            self.captureSession.sessionPreset = .low

            let discoverySession = AVCaptureDevice.DiscoverySession(
                deviceTypes: [.builtInWideAngleCamera, .external],
                mediaType: .video,
                position: .front
            )

            guard let camera = discoverySession.devices.first ?? AVCaptureDevice.default(for: .video),
                  let input = try? AVCaptureDeviceInput(device: camera) else {
                self.captureSession.commitConfiguration()
                self.onStatusChange?(false, nil, "No Camera Device Available")
                return
            }

            if self.captureSession.canAddInput(input) {
                self.captureSession.addInput(input)
            }

            self.videoDataOutput.alwaysDiscardsLateVideoFrames = true
            self.videoDataOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)
            ]
            self.videoDataOutput.setSampleBufferDelegate(self, queue: self.videoProcessingQueue)

            if self.captureSession.canAddOutput(self.videoDataOutput) {
                self.captureSession.addOutput(self.videoDataOutput)
            }

            self.captureSession.commitConfiguration()
            self.captureSession.startRunning()

            self.onStatusChange?(true, camera.localizedName, "Camera Active · Tracking Ergonomics")
        }
    }

    func stop() {
        videoProcessingQueue.async { [weak self] in
            guard let self = self else { return }
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
            self.onStatusChange?(false, nil, "Camera Paused")
        }
    }

    func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
              let req = self.faceLandmarksRequest else { return }

        do {
            try self.sequenceHandler.perform([req], on: pixelBuffer)
        } catch {
            // Ignore dropped frames
        }
    }
}
