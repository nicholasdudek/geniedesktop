import AppKit
import Foundation
@preconcurrency import AVFoundation
import CoreMedia
import CoreVideo
import Metal
import MetalKit
import os.log
import Observation

// MARK: - Genie HDMI Capture Engine
// Zero-latency external HDMI capture via AVFoundation (UVC/Blackmagic/Elgato/AVerMedia)
// Captures directly to CVPixelBuffer → Metal texture → SwiftUI, bypassing ScreenCaptureKit

// MARK: - 🔱 Zero-Copy GPU Pixel Forking Pipeline
public struct GenieForkedFrame: @unchecked Sendable {
    public let pixelBuffer: CVPixelBuffer
    public let metalTexture: MTLTexture?
    public let timestamp: CFTimeInterval
    public let frameNumber: UInt64

    public init(pixelBuffer: CVPixelBuffer, metalTexture: MTLTexture?, timestamp: CFTimeInterval, frameNumber: UInt64) {
        self.pixelBuffer = pixelBuffer
        self.metalTexture = metalTexture
        self.timestamp = timestamp
        self.frameNumber = frameNumber
    }
}

/// Circular ring buffer holding zero-copy frames for AI neural training and inference on Apple Silicon MPS/CoreML.
public final class GenieNeuralFrameRingBuffer: @unchecked Sendable {
    private let lock = NSLock()
    private var buffer: [GenieForkedFrame] = []
    public let capacity: Int

    public init(capacity: Int = 45) {
        self.capacity = max(5, capacity)
    }

    public func push(_ frame: GenieForkedFrame) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        var dropped = false
        if buffer.count >= capacity {
            buffer.removeFirst()
            dropped = true
        }
        buffer.append(frame)
        return !dropped
    }

    public func pop() -> GenieForkedFrame? {
        lock.lock()
        defer { lock.unlock() }
        guard !buffer.isEmpty else { return nil }
        return buffer.removeFirst()
    }

    public func peekLatest() -> GenieForkedFrame? {
        lock.lock()
        defer { lock.unlock() }
        return buffer.last
    }

    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        buffer.removeAll(keepingCapacity: true)
    }

    public var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return buffer.count
    }
}

@available(macOS 13.0, *)
@Observable
public final class GenieHDMICaptureEngine: NSObject, @unchecked Sendable {
    public static let shared = GenieHDMICaptureEngine()

    private let logger = Logger(subsystem: "com.genie.hdmi", category: "capture")
    private var captureSession: AVCaptureSession?
    private var videoDataOutput: AVCaptureVideoDataOutput?
    private var currentDevice: AVCaptureDevice?
    private var metalDevice: MTLDevice?
    private var textureCache: CVMetalTextureCache?

    // Frame delivery
    public var onFrameCaptured: (@MainActor (CGImage) -> Void)?
    public var onPixelBufferCaptured: (@MainActor (CVPixelBuffer) -> Void)?
    public var onMetalTextureCaptured: (@MainActor (MTLTexture) -> Void)?

    // 🔱 Zero-Copy GPU Pixel Forking (Display Channel vs. Neural Training Channel)
    public var isPixelForkActive: Bool = true
    public var onNeuralFrameForked: (@MainActor (GenieForkedFrame) -> Void)?
    public let neuralRingBuffer = GenieNeuralFrameRingBuffer(capacity: 45)
    public private(set) var forkedDisplayFrames: UInt64 = 0
    public private(set) var forkedTrainingFrames: UInt64 = 0
    public private(set) var droppedTrainingFrames: UInt64 = 0

    // State (observed via @Observable macro)
    public private(set) var isCapturing: Bool = false
    public private(set) var currentFormat: String = "—"
    public private(set) var currentResolution: String = "—"
    public private(set) var currentFPS: Double = 0
    public private(set) var availableDevices: [CaptureDeviceInfo] = []

    private var frameCount: UInt64 = 0
    private var lastFPSTimestamp: CFTimeInterval = CACurrentMediaTime()

    public override init() {
        super.init()
        setupMetal()
        discoverDevices()

        // Empty volatile ring buffer when system reports critical memory pressure
        NotificationCenter.default.addObserver(
            forName: Notification.Name("GeniePurgeVolatileCaches"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.neuralRingBuffer.clear()
        }
    }

    // MARK: - Metal Setup (Zero-Copy GPU Path)
    private func setupMetal() {
        metalDevice = MTLCreateSystemDefaultDevice()
        guard let device = metalDevice else {
            logger.error("Metal device unavailable")
            return
        }
        var cache: CVMetalTextureCache?
        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &cache)
        textureCache = cache
        logger.info("Metal texture cache created")
    }

    // MARK: - Device Discovery
    public func discoverDevices() {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [
                .external,               // Generic USB/Thunderbolt capture devices
                .builtInWideAngleCamera, // Fallback
                .continuityCamera        // iPhone as webcam
            ],
            mediaType: .video,
            position: .unspecified
        )

        let devices = discoverySession.devices.map { device in
            CaptureDeviceInfo(
                uniqueID: device.uniqueID,
                localizedName: device.localizedName,
                manufacturer: device.manufacturer,
                modelID: device.modelID,
                transportType: "\(device.transportType)",
                formats: device.formats.map { format in
                    CaptureFormatInfo(
                        resolution: "\(CMVideoFormatDescriptionGetDimensions(format.formatDescription).width)x\(CMVideoFormatDescriptionGetDimensions(format.formatDescription).height)",
                        frameRateRange: format.videoSupportedFrameRateRanges.map { "\($0.minFrameRate)-\($0.maxFrameRate)fps" }.joined(separator: ", "),
                        pixelFormat: format.formatDescription.mediaSubTypeDescription
                    )
                }
            )
        }

        DispatchQueue.main.async { [weak self] in
            self?.availableDevices = devices
            self?.logger.info("Discovered \(devices.count) capture devices")
        }
    }

    // MARK: - Capture Session Control
    public func startCapture(deviceID: String? = nil, preferredFormat: CaptureFormatInfo? = nil) async throws {
        guard !isCapturing else { return }

        let device: AVCaptureDevice
        if let id = deviceID, availableDevices.first(where: { $0.uniqueID == id }) != nil,
           let avDevice = AVCaptureDevice(uniqueID: id) {
            device = avDevice
        } else if let firstExternal = availableDevices.first(where: { $0.transportType != "BuiltIn" }),
                  let avDevice = AVCaptureDevice(uniqueID: firstExternal.uniqueID) {
            device = avDevice
        } else if let fallback = AVCaptureDevice.default(for: .video) {
            device = fallback
        } else {
            throw CaptureError.noDeviceFound
        }

        currentDevice = device

        // Configure session
        let session = AVCaptureSession()
        session.beginConfiguration()
        // .inputPriority not available on macOS; use high preset for quality
        session.sessionPreset = .high

        // Input
        let input = try AVCaptureDeviceInput(device: device)
        guard session.canAddInput(input) else { throw CaptureError.cannotAddInput }
        session.addInput(input)

        // Output - VideoDataOutput for direct pixel buffer access
        let output = AVCaptureVideoDataOutput()
        output.alwaysDiscardsLateVideoFrames = true
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA,
            kCVPixelBufferMetalCompatibilityKey as String: true,
            kCVPixelBufferIOSurfacePropertiesKey as String: [:]
        ]
        output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "com.genie.hdmi.capture", qos: .userInitiated))

        guard session.canAddOutput(output) else { throw CaptureError.cannotAddOutput }
        session.addOutput(output)

        // Configure connection for lowest latency
        if let connection = output.connection(with: .video) {
            // preferredVideoStabilizationMode not available on macOS
            connection.isEnabled = true
        }

        // Select format if specified
        if let format = preferredFormat, let avFormat = device.formats.first(where: {
            let dims = CMVideoFormatDescriptionGetDimensions($0.formatDescription)
            return "\(dims.width)x\(dims.height)" == format.resolution
        }) {
            try device.lockForConfiguration()
            device.activeFormat = avFormat
            device.unlockForConfiguration()
        }

        // Start running
        session.commitConfiguration()
        session.startRunning()

        captureSession = session
        videoDataOutput = output

        await updateDeviceInfo(device: device)

        DispatchQueue.main.async { [weak self] in
            self?.isCapturing = true
        }

        logger.info("Started HDMI capture on \(device.localizedName)")
    }

    public func stopCapture() {
        captureSession?.stopRunning()
        captureSession = nil
        videoDataOutput = nil
        currentDevice = nil

        DispatchQueue.main.async { [weak self] in
            self?.isCapturing = false
            self?.currentFormat = "—"
            self?.currentResolution = "—"
            self?.currentFPS = 0
        }

        logger.info("Stopped HDMI capture")
    }

    // MARK: - Device Info
    private func updateDeviceInfo(device: AVCaptureDevice) async {
        let activeFormat = device.activeFormat
        let dims = CMVideoFormatDescriptionGetDimensions(activeFormat.formatDescription)
        let maxFPS = activeFormat.videoSupportedFrameRateRanges.map { $0.maxFrameRate }.max() ?? 0

        DispatchQueue.main.async { [weak self] in
            self?.currentResolution = "\(dims.width)x\(dims.height)"
            self?.currentFormat = activeFormat.formatDescription.mediaSubTypeDescription
            self?.currentFPS = maxFPS
        }
    }

    // MARK: - Pixel Buffer → CGImage (CPU Path)
    private func pixelBufferToCGImage(_ pixelBuffer: CVPixelBuffer) -> CGImage? {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        return cgImage
    }

    // MARK: - Pixel Buffer → Metal Texture (GPU Zero-Copy Path)
    private func pixelBufferToMetalTexture(_ pixelBuffer: CVPixelBuffer) -> MTLTexture? {
        guard let textureCache = textureCache,
              metalDevice != nil else { return nil }

        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)

        var cvTextureOut: CVMetalTexture?
        let status = CVMetalTextureCacheCreateTextureFromImage(
            kCFAllocatorDefault,
            textureCache,
            pixelBuffer,
            nil,
            .bgra8Unorm,
            width,
            height,
            0,
            &cvTextureOut
        )

        guard status == kCVReturnSuccess, let cvTexture = cvTextureOut,
              let texture = CVMetalTextureGetTexture(cvTexture) else {
            return nil
        }
        return texture
    }

    // MARK: - FPS Tracking
    private func updateFPS() {
        frameCount += 1
        let now = CACurrentMediaTime()
        if now - lastFPSTimestamp >= 1.0 {
            let fps = Double(frameCount) / (now - lastFPSTimestamp)
            DispatchQueue.main.async { [weak self] in
                self?.currentFPS = fps
            }
            frameCount = 0
            lastFPSTimestamp = now
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
@available(macOS 13.0, *)
extension GenieHDMICaptureEngine: AVCaptureVideoDataOutputSampleBufferDelegate {
    public func captureOutput(_ output: AVCaptureOutput,
                              didOutput sampleBuffer: CMSampleBuffer,
                              from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        updateFPS()
        forkedDisplayFrames += 1

        let metalTexture = pixelBufferToMetalTexture(pixelBuffer)

        // 🔱 Channel 1: Display Channel (HDMI / Screen Output - Zero-Latency)
        if let metalTexture = metalTexture {
            Task { @MainActor [weak self] in
                self?.onMetalTextureCaptured?(metalTexture)
            }
        }

        Task { @MainActor [weak self] in
            self?.onPixelBufferCaptured?(pixelBuffer)
        }

        if let cgImage = pixelBufferToCGImage(pixelBuffer) {
            Task { @MainActor [weak self] in
                self?.onFrameCaptured?(cgImage)
            }
        }

        // 🔱 Channel 2: Neural Training Channel (Zero-Copy Fork)
        if isPixelForkActive {
            if GenieMemoryGovernorEngine.isCriticalPressureActive {
                droppedTrainingFrames += 1
            } else {
                let frame = GenieForkedFrame(
                    pixelBuffer: pixelBuffer,
                    metalTexture: metalTexture,
                    timestamp: CACurrentMediaTime(),
                    frameNumber: forkedDisplayFrames
                )
                let admitted = neuralRingBuffer.push(frame)
                if admitted {
                    forkedTrainingFrames += 1
                    Task { @MainActor [weak self] in
                        self?.onNeuralFrameForked?(frame)
                    }
                } else {
                    droppedTrainingFrames += 1
                }
            }
        }
    }

    public func captureOutput(_ output: AVCaptureOutput,
                              didDrop sampleBuffer: CMSampleBuffer,
                              from connection: AVCaptureConnection) {
        logger.warning("Dropped frame")
    }
}

// MARK: - Supporting Types
public struct CaptureDeviceInfo: Identifiable, Hashable, Sendable {
    public let id = UUID()
    public let uniqueID: String
    public let localizedName: String
    public let manufacturer: String
    public let modelID: String
    public let transportType: String
    public let formats: [CaptureFormatInfo]
}

public struct CaptureFormatInfo: Identifiable, Hashable, Sendable {
    public let id = UUID()
    public let resolution: String
    public let frameRateRange: String
    public let pixelFormat: String
}

public enum CaptureError: LocalizedError {
    case noDeviceFound
    case cannotAddInput
    case cannotAddOutput
    case permissionDenied
    case deviceInUse
    case configurationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .noDeviceFound: return "No HDMI capture device found"
        case .cannotAddInput: return "Cannot add capture input"
        case .cannotAddOutput: return "Cannot add capture output"
        case .permissionDenied: return "Camera permission denied"
        case .deviceInUse: return "Device already in use"
        case .configurationFailed(let msg): return "Configuration failed: \(msg)"
        }
    }
}

// MARK: - Format Description Extensions
extension CMFormatDescription {
    var mediaSubTypeDescription: String {
        let subType = CMFormatDescriptionGetMediaSubType(self)
        return String(format: "%c%c%c%c",
                      (subType >> 24) & 0xFF,
                      (subType >> 16) & 0xFF,
                      (subType >> 8) & 0xFF,
                      subType & 0xFF)
    }
}

// MARK: - SwiftUI Integration View
import SwiftUI

@available(macOS 13.0, *)
public struct HDMICaptureView: View {
    @State private var engine = GenieHDMICaptureEngine.shared
    @State private var currentFrame: CGImage?
    @State private var selectedDeviceID: String?
    @State private var showDevicePicker = false

    public init() {}

    public var body: some View {
        VStack(spacing: 12) {
            // Status Bar
            HStack {
                Circle()
                    .fill(engine.isCapturing ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                Text(engine.isCapturing ? "LIVE" : "IDLE")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(engine.isCapturing ? .green : .red)

                Spacer()

                Text("\(engine.currentResolution) @ \(engine.currentFormat)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.secondary)

                Text("\(Int(engine.currentFPS)) FPS")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.cyan)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))

            // Video Preview
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.3))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )

                if let frame = currentFrame {
                    Image(frame, scale: 1.0, label: Text("HDMI Capture"))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .padding(4)
                } else if engine.isCapturing {
                    ProgressView()
                        .scaleEffect(1.5)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "tv.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.white.opacity(0.3))
                        Text("No HDMI Signal")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                        Text("Connect capture device & press Start")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.3))
                    }
                }
            }
            .frame(minHeight: 280)

            // Controls
            HStack(spacing: 12) {
                Menu {
                    ForEach(engine.availableDevices) { device in
                        Button(device.localizedName) {
                            selectedDeviceID = device.uniqueID
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "video.fill")
                        Text(selectedDeviceID.flatMap { id in
                            engine.availableDevices.first(where: { $0.uniqueID == id })?.localizedName
                        } ?? "Select Device")
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(.ultraThinMaterial, in: Capsule())
                }

                Button(engine.isCapturing ? "Stop" : "Start") {
                    Task {
                        if engine.isCapturing {
                            engine.stopCapture()
                            currentFrame = nil
                        } else {
                            try? await engine.startCapture(deviceID: selectedDeviceID)
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(engine.isCapturing ? .red : .green)
            }
        }
        .padding()
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("GenieHDMIFrame"))) { _ in
            // Frame delivered via callback
        }
        .task {
            // Set up frame callback
            let this = self
            await MainActor.run {
                engine.onFrameCaptured = { image in
                    this.currentFrame = image
                }
            }
        }
    }
}

// MARK: - Metal Texture View (For Zero-Copy GPU Rendering)
@available(macOS 13.0, *)
public struct HDMICaptureMetalView: NSViewRepresentable {
    @State private var engine = GenieHDMICaptureEngine.shared
    private let metalLayer = CAMetalLayer()

    public init() {}

    public func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        view.layer = metalLayer
        metalLayer.device = MTLCreateSystemDefaultDevice()
        metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.framebufferOnly = false
        metalLayer.isOpaque = false

        // Set up frame callback to Metal layer
        engine.onMetalTextureCaptured = { [weak metalLayer] (texture: MTLTexture) in
            guard let layer = metalLayer else { return }
            layer.drawableSize = CGSize(width: texture.width, height: texture.height)
            if let drawable = layer.nextDrawable() {
                let commandBuffer = texture.device.makeCommandQueue()?.makeCommandBuffer()
                let blitEncoder = commandBuffer?.makeBlitCommandEncoder()
                blitEncoder?.copy(from: texture, sourceSlice: 0, sourceLevel: 0,
                                  sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
                                  sourceSize: MTLSize(width: texture.width, height: texture.height, depth: 1),
                                  to: drawable.texture, destinationSlice: 0, destinationLevel: 0,
                                  destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0))
                blitEncoder?.endEncoding()
                commandBuffer?.present(drawable)
                commandBuffer?.commit()
            }
        }

        return view
    }

    public func updateNSView(_ nsView: NSView, context: Context) {}
}