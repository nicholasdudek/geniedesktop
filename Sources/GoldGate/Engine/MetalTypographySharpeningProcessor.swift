import AppKit
import Foundation
import Metal
import CoreGraphics
import simd

// MARK: - 🔤 Typography Filter Modes for 0.33x Scaled Displayer
public enum TypographyFilterMode: UInt32, CaseIterable, Identifiable, Sendable {
    case lanczos3 = 0
    case bicubicCatmullRom = 1
    case subpixelStemPreserving = 2

    public var id: UInt32 { rawValue }

    public var title: String {
        switch self {
        case .lanczos3: return "Lanczos-3 Sinc (High-DPI)"
        case .bicubicCatmullRom: return "Bicubic Catmull-Rom"
        case .subpixelStemPreserving: return "Sub-Pixel Font Stem"
        }
    }

    public var shortTitle: String {
        switch self {
        case .lanczos3: return "Lanczos-3"
        case .bicubicCatmullRom: return "Bicubic"
        case .subpixelStemPreserving: return "Stem Boost"
        }
    }

    public var iconName: String {
        switch self {
        case .lanczos3: return "sparkles"
        case .bicubicCatmullRom: return "waveform.path"
        case .subpixelStemPreserving: return "textformat.size"
        }
    }
}

// MARK: - ⚙️ Typography Sharpening Configuration
public struct TypographySharpeningConfig: Sendable {
    public var targetScale: Float
    public var sharpnessStrength: Float
    public var textContrastBoost: Float
    public var antiRingingClamp: Float
    public var filterMode: TypographyFilterMode
    public var gammaCorrection: Bool
    public var subpixelOffset: Float

    public init(
        targetScale: Float = 0.33,
        sharpnessStrength: Float = 0.85,
        textContrastBoost: Float = 1.25,
        antiRingingClamp: Float = 0.15,
        filterMode: TypographyFilterMode = .lanczos3,
        gammaCorrection: Bool = true,
        subpixelOffset: Float = 0.333
    ) {
        self.targetScale = targetScale
        self.sharpnessStrength = sharpnessStrength
        self.textContrastBoost = textContrastBoost
        self.antiRingingClamp = antiRingingClamp
        self.filterMode = filterMode
        self.gammaCorrection = gammaCorrection
        self.subpixelOffset = subpixelOffset
    }
}

// MARK: - ⚡ Metal Uniforms Struct Matching Shader Layout
private struct MetalTypographyUniforms {
    var targetScale: Float
    var sharpnessStrength: Float
    var textContrastBoost: Float
    var antiRingingClamp: Float
    var filterMode: UInt32
    var gammaCorrection: UInt32
    var subpixelOffset: Float
    var padding: Float = 0.0
}

// MARK: - 🔬 Metal High-DPI Typography Sharpening Processor
/// High-performance Apple Silicon Metal compute pipeline with zero-allocation texture pooling
/// for real-time 30/60 FPS micro-code typography and window framebuffer downscaling at 0.33x.
public final class MetalTypographySharpeningProcessor: @unchecked Sendable {
    public static let shared = MetalTypographySharpeningProcessor()

    public private(set) var isMetalAvailable: Bool = false
    public private(set) var deviceName: String = "CPU Fallback"

    private let device: MTLDevice?
    private let commandQueue: MTLCommandQueue?
    private var computePipelineState: MTLComputePipelineState?
    private var samplerState: MTLSamplerState?
    private let colorSpace = CGColorSpaceCreateDeviceRGB()

    // ── Zero-Allocation Slot Texture & Buffer Pool ──
    private let lock = NSLock()
    private var sourceTexturePool: [Int: (texture: MTLTexture, width: Int, height: Int)] = [:]
    private var outputTexturePool: [Int: (texture: MTLTexture, width: Int, height: Int)] = [:]
    private var outputPixelBuffers: [Int: (pointer: UnsafeMutableRawPointer, capacity: Int)] = [:]
    private var reusableSrcBitmaps: [Int: (pointer: UnsafeMutableRawPointer, capacity: Int)] = [:]

    // Telemetry
    public private(set) var lastExecutionTimeMs: Double = 0.0
    public private(set) var totalFramesProcessed: Int = 0

    // Metal Shader Source Code (MSL)
    private static let metalShaderSource = """
    #include <metal_stdlib>
    using namespace metal;


    struct TypographyParams {
        float targetScale;
        float sharpnessStrength;
        float textContrastBoost;
        float antiRingingClamp;
        uint32_t filterMode;
        uint32_t gammaCorrection;
        float subpixelOffset;
        float padding;
    };

    inline float3 srgb_to_linear(float3 c) {
        return select(c / 12.92, pow((c + 0.055) / 1.055, float3(2.4)), c > 0.04045);
    }

    inline float3 linear_to_srgb(float3 c) {
        return select(c * 12.92, 1.055 * pow(max(c, 0.0), float3(1.0 / 2.4)) - 0.055, c > 0.0031308);
    }

    inline float sinc(float x) {
        if (abs(x) < 1e-5) return 1.0;
        float pix = M_PI_F * x;
        return sin(pix) / pix;
    }

    inline float lanczos_weight(float x, float a) {
        float ax = abs(x);
        if (ax < 1e-5) return 1.0;
        if (ax >= a) return 0.0;
        return sinc(x) * sinc(x / a);
    }

    inline float catmull_rom(float x) {
        float ax = abs(x);
        if (ax <= 1.0) {
            return 1.5 * ax * ax * ax - 2.5 * ax * ax + 1.0;
        } else if (ax < 2.0) {
            return -0.5 * ax * ax * ax + 2.5 * ax * ax - 4.0 * ax + 2.0;
        }
        return 0.0;
    }

    inline float get_luminance(float3 c) {
        return dot(c, float3(0.2126, 0.7152, 0.0722));
    }

    kernel void lanczosTypographySharpenKernel(
        texture2d<float, access::sample> inTexture [[texture(0)]],
        texture2d<float, access::write> outTexture [[texture(1)]],
        sampler smp [[sampler(0)]],
        constant TypographyParams &params [[buffer(0)]],
        uint2 gid [[thread_position_in_grid]]
    ) {
        if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) {
            return;
        }

        float2 outDim = float2(outTexture.get_width(), outTexture.get_height());
        float2 inDim = float2(inTexture.get_width(), inTexture.get_height());

        float2 uv = (float2(gid) + 0.5) / outDim;
        float2 srcCenter = uv * inDim;

        float4 resColor = float4(0.0);
        float totalWeight = 0.0;

        float scaleX = outDim.x / inDim.x;
        float scaleY = outDim.y / inDim.y;

        float radiusX = (params.filterMode == FilterModeLanczos3) ? (3.0 / scaleX) : (2.0 / scaleX);
        float radiusY = (params.filterMode == FilterModeLanczos3) ? (3.0 / scaleY) : (2.0 / scaleY);

        int sampleRadiusX = min(int(ceil(radiusX * 0.45)), 3);
        int sampleRadiusY = min(int(ceil(radiusY * 0.45)), 3);

        float3 minColor = float3(1.0);
        float3 maxColor = float3(0.0);

        for (int dy = -sampleRadiusY; dy <= sampleRadiusY; dy++) {
            for (int dx = -sampleRadiusX; dx <= sampleRadiusX; dx++) {
                float2 sampleCoord = srcCenter + float2(float(dx) / scaleX * 0.5, float(dy) / scaleY * 0.5);
                float2 sampleUV = clamp(sampleCoord / inDim, float2(0.0), float2(1.0));

                float4 sampleColor = inTexture.sample(smp, sampleUV);
                float3 rgb = sampleColor.rgb;
                if (params.gammaCorrection != 0) {
                    rgb = srgb_to_linear(rgb);
                }

                float distNormX = (float(dx) / float(max(sampleRadiusX, 1)));
                float distNormY = (float(dy) / float(max(sampleRadiusY, 1)));
                float weight = 1.0;

                if (params.filterMode == FilterModeLanczos3) {
                    weight = lanczos_weight(distNormX * 3.0, 3.0) * lanczos_weight(distNormY * 3.0, 3.0);
                } else if (params.filterMode == FilterModeBicubicCatmullRom) {
                    weight = catmull_rom(distNormX * 2.0) * catmull_rom(distNormY * 2.0);
                } else {
                    weight = lanczos_weight(distNormX * 2.5, 3.0) * catmull_rom(distNormY * 2.0);
                }

                resColor.rgb += rgb * weight;
                resColor.a += sampleColor.a * weight;
                totalWeight += weight;

                minColor = min(minColor, rgb);
                maxColor = max(maxColor, rgb);
            }
        }

        if (totalWeight > 1e-4) {
            resColor /= totalWeight;
        }

        // ── Contrast Adaptive Sharpening & Sub-pixel Typography Edge Boost ──
        if (params.sharpnessStrength > 0.01) {
            float2 px = 1.0 / inDim;
            float3 cN = inTexture.sample(smp, clamp(uv + float2(0.0, -px.y * 1.5), 0.0, 1.0)).rgb;
            float3 cS = inTexture.sample(smp, clamp(uv + float2(0.0,  px.y * 1.5), 0.0, 1.0)).rgb;
            float3 cW = inTexture.sample(smp, clamp(uv + float2(-px.x * 1.5, 0.0), 0.0, 1.0)).rgb;
            float3 cE = inTexture.sample(smp, clamp(uv + float2( px.x * 1.5, 0.0), 0.0, 1.0)).rgb;

            if (params.gammaCorrection != 0) {
                cN = srgb_to_linear(cN);
                cS = srgb_to_linear(cS);
                cW = srgb_to_linear(cW);
                cE = srgb_to_linear(cE);
            }

            float3 minNeigh = min(min(cN, cS), min(cW, cE));
            float3 maxNeigh = max(max(cN, cS), max(cW, cE));

            float3 amp = clamp(min(minNeigh, 1.0 - maxNeigh) / max(maxNeigh, 0.01), 0.0, 1.0);
            float3 w = -sqrt(amp) * (params.sharpnessStrength * 0.35);

            float lumC = get_luminance(resColor.rgb);
            float lumMin = get_luminance(minNeigh);
            float lumMax = get_luminance(maxNeigh);
            float contrast = lumMax - lumMin;

            if (contrast > 0.15) {
                float textBoost = (params.textContrastBoost - 1.0) * smoothstep(0.15, 0.60, contrast);
                if (lumC < 0.5) {
                    resColor.rgb = max(float3(0.0), resColor.rgb * (1.0 - textBoost * 0.28));
                } else {
                    resColor.rgb = min(float3(1.0), resColor.rgb * (1.0 + textBoost * 0.22));
                }
            }

            float3 sharpened = (resColor.rgb + (cN + cS + cW + cE) * w) / (1.0 + 4.0 * w);
            float3 clampMin = max(float3(0.0), minColor - float3(params.antiRingingClamp));
            float3 clampMax = min(float3(1.0), maxColor + float3(params.antiRingingClamp));
            resColor.rgb = clamp(sharpened, clampMin, clampMax);
        }

        if (params.gammaCorrection != 0) {
            resColor.rgb = linear_to_srgb(resColor.rgb);
        }

        outTexture.write(clamp(resColor, 0.0, 1.0), gid);
    }
    """

    public init() {
        guard let mtlDevice = MTLCreateSystemDefaultDevice() else {
            self.device = nil
            self.commandQueue = nil
            self.isMetalAvailable = false
            return
        }

        self.device = mtlDevice
        self.commandQueue = mtlDevice.makeCommandQueue()
        self.deviceName = mtlDevice.name

        do {
            let library = try mtlDevice.makeLibrary(source: Self.metalShaderSource, options: nil)
            guard let function = library.makeFunction(name: "lanczosTypographySharpenKernel") else {
                self.isMetalAvailable = false
                return
            }
            self.computePipelineState = try mtlDevice.makeComputePipelineState(function: function)

            // Linear clamp sampler for sub-pixel anti-aliasing
            let samplerDesc = MTLSamplerDescriptor()
            samplerDesc.minFilter = .linear
            samplerDesc.magFilter = .linear
            samplerDesc.sAddressMode = .clampToEdge
            samplerDesc.tAddressMode = .clampToEdge
            self.samplerState = mtlDevice.makeSamplerState(descriptor: samplerDesc)

            self.isMetalAvailable = true
        } catch {
            print("⚠️ [MetalTypographySharpeningProcessor] Shader compilation failed: \(error)")
            self.isMetalAvailable = false
        }
    }

    deinit {
        lock.lock()
        for (_, entry) in outputPixelBuffers {
            entry.pointer.deallocate()
        }
        for (_, entry) in reusableSrcBitmaps {
            entry.pointer.deallocate()
        }
        outputPixelBuffers.removeAll()
        reusableSrcBitmaps.removeAll()
        sourceTexturePool.removeAll()
        outputTexturePool.removeAll()
        lock.unlock()
    }

    public var currentConfig: TypographySharpeningConfig = TypographySharpeningConfig()

    public func updateConfig(
        sharpnessStrength: Float,
        textContrastBoost: Float,
        antiRingingClamp: Float
    ) {
        lock.lock()
        currentConfig.sharpnessStrength = sharpnessStrength
        currentConfig.textContrastBoost = textContrastBoost
        currentConfig.antiRingingClamp = antiRingingClamp
        lock.unlock()
    }

    // MARK: - 🚀 Zero-Allocation Processing Pass
    /// Scales and sharpens a window framebuffer CGImage using the Metal compute pipeline with zero runtime allocations.
    public func process(
        slotId: Int,
        sourceCGImage: CGImage,
        targetSize: CGSize,
        config: TypographySharpeningConfig
    ) -> NSImage {
        let startTime = CFAbsoluteTimeGetCurrent()
        defer {
            let elapsedMs = (CFAbsoluteTimeGetCurrent() - startTime) * 1000.0
            self.lastExecutionTimeMs = elapsedMs
            self.totalFramesProcessed += 1
        }

        let srcW = sourceCGImage.width
        let srcH = sourceCGImage.height
        let outW = max(16, Int(targetSize.width))
        let outH = max(16, Int(targetSize.height))

        guard srcW > 0, srcH > 0 else {
            return NSImage(cgImage: sourceCGImage, size: targetSize)
        }

        // Check if Metal hardware acceleration is available
        guard isMetalAvailable,
              let device = self.device,
              let queue = self.commandQueue,
              let pipeline = self.computePipelineState,
              let sampler = self.samplerState else {
            return fallbackCoreGraphicsResample(sourceCGImage: sourceCGImage, targetSize: targetSize, config: config)
        }

        lock.lock()
        defer { lock.unlock() }

        // 1. Get or Create Reusable Source Texture
        let srcTexture: MTLTexture
        if let existingSrc = sourceTexturePool[slotId], existingSrc.width == srcW, existingSrc.height == srcH {
            srcTexture = existingSrc.texture
        } else {
            let desc = MTLTextureDescriptor.texture2DDescriptor(
                pixelFormat: .bgra8Unorm,
                width: srcW,
                height: srcH,
                mipmapped: false
            )
            desc.usage = [.shaderRead]
            desc.storageMode = .shared
            guard let newTex = device.makeTexture(descriptor: desc) else {
                return fallbackCoreGraphicsResample(sourceCGImage: sourceCGImage, targetSize: targetSize, config: config)
            }
            sourceTexturePool[slotId] = (texture: newTex, width: srcW, height: srcH)
            srcTexture = newTex
        }

        // 2. Upload CGImage data into Source Texture using Pooled Buffer
        let srcBytesPerRow = srcW * 4
        let srcByteCount = srcBytesPerRow * srcH

        let srcBufferPtr: UnsafeMutableRawPointer
        if let cachedBuf = reusableSrcBitmaps[slotId], cachedBuf.capacity >= srcByteCount {
            srcBufferPtr = cachedBuf.pointer
        } else {
            if let oldBuf = reusableSrcBitmaps[slotId] {
                oldBuf.pointer.deallocate()
            }
            let newPtr = UnsafeMutableRawPointer.allocate(byteCount: srcByteCount, alignment: 64)
            reusableSrcBitmaps[slotId] = (pointer: newPtr, capacity: srcByteCount)
            srcBufferPtr = newPtr
        }

        guard let srcContext = CGContext(
            data: srcBufferPtr,
            width: srcW,
            height: srcH,
            bitsPerComponent: 8,
            bytesPerRow: srcBytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        ) else {
            return fallbackCoreGraphicsResample(sourceCGImage: sourceCGImage, targetSize: targetSize, config: config)
        }

        srcContext.draw(sourceCGImage, in: CGRect(x: 0, y: 0, width: srcW, height: srcH))
        srcTexture.replace(
            region: MTLRegionMake2D(0, 0, srcW, srcH),
            mipmapLevel: 0,
            withBytes: srcBufferPtr,
            bytesPerRow: srcBytesPerRow
        )

        // 3. Get or Create Reusable Output Texture
        let outTexture: MTLTexture
        if let existingOut = outputTexturePool[slotId], existingOut.width == outW, existingOut.height == outH {
            outTexture = existingOut.texture
        } else {
            let desc = MTLTextureDescriptor.texture2DDescriptor(
                pixelFormat: .bgra8Unorm,
                width: outW,
                height: outH,
                mipmapped: false
            )
            desc.usage = [.shaderWrite, .shaderRead]
            desc.storageMode = .shared
            guard let newTex = device.makeTexture(descriptor: desc) else {
                return fallbackCoreGraphicsResample(sourceCGImage: sourceCGImage, targetSize: targetSize, config: config)
            }
            outputTexturePool[slotId] = (texture: newTex, width: outW, height: outH)
            outTexture = newTex
        }

        // 4. Encode & Dispatch Metal Compute Workload
        guard let commandBuffer = queue.makeCommandBuffer(),
              let encoder = commandBuffer.makeComputeCommandEncoder() else {
            return fallbackCoreGraphicsResample(sourceCGImage: sourceCGImage, targetSize: targetSize, config: config)
        }

        var uniforms = MetalTypographyUniforms(
            targetScale: config.targetScale,
            sharpnessStrength: config.sharpnessStrength,
            textContrastBoost: config.textContrastBoost,
            antiRingingClamp: config.antiRingingClamp,
            filterMode: config.filterMode.rawValue,
            gammaCorrection: config.gammaCorrection ? 1 : 0,
            subpixelOffset: config.subpixelOffset
        )

        encoder.setComputePipelineState(pipeline)
        encoder.setTexture(srcTexture, index: 0)
        encoder.setTexture(outTexture, index: 1)
        encoder.setSamplerState(sampler, index: 0)
        encoder.setBytes(&uniforms, length: MemoryLayout<MetalTypographyUniforms>.stride, index: 0)

        let threadgroupSize = MTLSize(width: 16, height: 16, depth: 1)
        let threadgroupCount = MTLSize(
            width: (outW + threadgroupSize.width - 1) / threadgroupSize.width,
            height: (outH + threadgroupSize.height - 1) / threadgroupSize.height,
            depth: 1
        )

        encoder.dispatchThreadgroups(threadgroupCount, threadsPerThreadgroup: threadgroupSize)
        encoder.endEncoding()

        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        // 5. Read Back from Shared Memory Texture into Pooled CGImage Output
        let outBytesPerRow = outW * 4
        let outByteCount = outBytesPerRow * outH

        let outBufferPtr: UnsafeMutableRawPointer
        if let cachedBuf = outputPixelBuffers[slotId], cachedBuf.capacity >= outByteCount {
            outBufferPtr = cachedBuf.pointer
        } else {
            if let oldBuf = outputPixelBuffers[slotId] {
                oldBuf.pointer.deallocate()
            }
            let newPtr = UnsafeMutableRawPointer.allocate(byteCount: outByteCount, alignment: 64)
            outputPixelBuffers[slotId] = (pointer: newPtr, capacity: outByteCount)
            outBufferPtr = newPtr
        }

        outTexture.getBytes(
            outBufferPtr,
            bytesPerRow: outBytesPerRow,
            from: MTLRegionMake2D(0, 0, outW, outH),
            mipmapLevel: 0
        )

        guard let provider = CGDataProvider(
            dataInfo: nil,
            data: outBufferPtr,
            size: outByteCount,
            releaseData: { _, _, _ in }
        ), let finalCGImage = CGImage(
            width: outW,
            height: outH,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: outBytesPerRow,
            space: colorSpace,
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue),
            provider: provider,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        ) else {
            return fallbackCoreGraphicsResample(sourceCGImage: sourceCGImage, targetSize: targetSize, config: config)
        }

        return NSImage(cgImage: finalCGImage, size: targetSize)
    }

    // MARK: - 🖥️ CPU Fallback Pass (High-DPI Bicubic + Unsharp Mask)
    private func fallbackCoreGraphicsResample(
        sourceCGImage: CGImage,
        targetSize: CGSize,
        config: TypographySharpeningConfig
    ) -> NSImage {
        let targetW = max(16, Int(targetSize.width))
        let targetH = max(16, Int(targetSize.height))
        let bytesPerRow = targetW * 4

        guard let ctx = CGContext(
            data: nil,
            width: targetW,
            height: targetH,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        ) else {
            return NSImage(cgImage: sourceCGImage, size: targetSize)
        }

        ctx.interpolationQuality = .high
        ctx.setAllowsAntialiasing(true)
        ctx.setShouldAntialias(true)

        ctx.draw(sourceCGImage, in: CGRect(x: 0, y: 0, width: targetW, height: targetH))

        // Contrast-adaptive unsharp pass on CPU
        if let data = ctx.data, config.sharpnessStrength > 0.05 {
            let ptr = data.bindMemory(to: UInt8.self, capacity: targetW * targetH * 4)
            let boost = Float(config.sharpnessStrength) * 0.40

            for y in 1..<(targetH - 1) {
                let rowOffset = y * bytesPerRow
                for x in 1..<(targetW - 1) {
                    let idx = rowOffset + x * 4

                    let cR = Float(ptr[idx])
                    let cG = Float(ptr[idx + 1])
                    let cB = Float(ptr[idx + 2])

                    let nR = Float(ptr[idx - 4]) + Float(ptr[idx + 4]) + Float(ptr[idx - bytesPerRow]) + Float(ptr[idx + bytesPerRow])
                    let nG = Float(ptr[idx - 3]) + Float(ptr[idx + 5]) + Float(ptr[idx - bytesPerRow + 1]) + Float(ptr[idx + bytesPerRow + 1])
                    let nB = Float(ptr[idx - 2]) + Float(ptr[idx + 6]) + Float(ptr[idx - bytesPerRow + 2]) + Float(ptr[idx + bytesPerRow + 2])

                    let lapR = cR * 4.0 - nR
                    let lapG = cG * 4.0 - nG
                    let lapB = cB * 4.0 - nB

                    ptr[idx] = UInt8(min(255, max(0, cR + lapR * boost)))
                    ptr[idx + 1] = UInt8(min(255, max(0, cG + lapG * boost)))
                    ptr[idx + 2] = UInt8(min(255, max(0, cB + lapB * boost)))
                }
            }
        }

        guard let outCg = ctx.makeImage() else {
            return NSImage(cgImage: sourceCGImage, size: targetSize)
        }
        return NSImage(cgImage: outCg, size: targetSize)
    }

    /// Clears any cached textures and buffers
    public func purgePools() {
        lock.lock()
        for (_, entry) in outputPixelBuffers {
            entry.pointer.deallocate()
        }
        for (_, entry) in reusableSrcBitmaps {
            entry.pointer.deallocate()
        }
        outputPixelBuffers.removeAll()
        reusableSrcBitmaps.removeAll()
        sourceTexturePool.removeAll()
        outputTexturePool.removeAll()
        lock.unlock()
    }
}
