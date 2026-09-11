import Combine
import MetalKit
import SwiftUI

// MARK: - ⚡️ Genie Metal Stats HUD
/// A live generation readout — elapsed time and token throughput — drawn over a
/// Metal-rendered energy field whose speed and brightness track the model's
/// actual token rate. Idle it is nearly black and costs almost nothing; under
/// load it streams.
///
/// The shader is compiled from source at runtime rather than shipped as a
/// `.metallib` resource, so the Genie target keeps its current (resource-free)
/// SwiftPM layout and `package_direct_distribution.sh` needs no changes.

// MARK: - Shader source

private let statsHUDShaderSource = #"""
#include <metal_stdlib>
using namespace metal;

struct VertexOut {
    float4 position [[position]];
    float2 uv;
};

// Fullscreen triangle — no vertex buffer needed.
vertex VertexOut hud_vertex(uint vid [[vertex_id]]) {
    float2 corners[3] = { float2(-1.0, -3.0), float2(-1.0, 1.0), float2(3.0, 1.0) };
    VertexOut out;
    out.position = float4(corners[vid], 0.0, 1.0);
    out.uv = corners[vid] * 0.5 + 0.5;
    return out;
}

struct HUDUniforms {
    float  time;        // seconds since the HUD appeared
    float  intensity;   // 0…1, driven by tokens/sec
    float2 resolution;
    float4 accent;      // linear RGBA
};

// Cheap value noise.
float hash21(float2 p) {
    p = fract(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float valueNoise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    float2 u = f * f * (3.0 - 2.0 * f);
    float a = hash21(i);
    float b = hash21(i + float2(1.0, 0.0));
    float c = hash21(i + float2(0.0, 1.0));
    float d = hash21(i + float2(1.0, 1.0));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

fragment float4 hud_fragment(VertexOut in [[stage_in]],
                             constant HUDUniforms &u [[buffer(0)]]) {
    float2 uv = in.uv;
    float aspect = max(u.resolution.x / max(u.resolution.y, 1.0), 0.001);
    float2 p = float2(uv.x * aspect, uv.y);

    // Token stream: bands sliding left, faster and tighter as intensity rises.
    float speed = mix(0.06, 0.85, u.intensity);
    float streams = 0.0;
    for (int i = 0; i < 3; i++) {
        float fi = float(i);
        float scale = mix(3.0, 9.0, fract(fi * 0.37));
        float offset = u.time * speed * (1.0 + fi * 0.45);
        float n = valueNoise(float2(p.x * scale - offset, p.y * 2.4 + fi * 7.3));
        // Sharpen into filaments.
        streams += pow(smoothstep(0.55, 1.0, n), 3.0) * (1.0 - fi * 0.22);
    }
    streams /= 2.2;

    // Horizontal falloff so the readout text stays legible on the right.
    float fade = smoothstep(1.0, 0.15, uv.x);
    streams *= fade;

    // Soft vertical containment — brightest through the middle band.
    float band = 1.0 - smoothstep(0.0, 0.62, abs(uv.y - 0.5));
    streams *= band;

    // A slow pulse that only really shows when the model is working.
    float pulse = 0.82 + 0.18 * sin(u.time * 2.1);
    streams *= mix(1.0, pulse, u.intensity);

    float3 glow = u.accent.rgb * streams * mix(0.35, 1.6, u.intensity);

    // Base plate: near-black, lifted very slightly by the accent.
    float3 base = float3(0.027, 0.033, 0.047) + u.accent.rgb * 0.02;
    float3 color = base + glow;

    // Leading edge highlight sweeping with the stream.
    float sweep = smoothstep(0.985, 1.0, fract(uv.x * 1.4 - u.time * speed * 0.55));
    color += u.accent.rgb * sweep * u.intensity * 0.5;

    return float4(color, 1.0);
}
"""#

// MARK: - Renderer

private struct HUDUniforms {
    var time: Float = 0
    var intensity: Float = 0
    var resolution: SIMD2<Float> = .zero
    var accent: SIMD4<Float> = .init(0.957, 0.765, 0.459, 1)
}

final class GenieStatsHUDRenderer: NSObject, MTKViewDelegate {
    private let commandQueue: MTLCommandQueue
    private let pipeline: MTLRenderPipelineState
    private var uniforms = HUDUniforms()
    private let started = CACurrentMediaTime()

    /// 0…1. Smoothed toward the target so the field eases in and out instead of
    /// snapping when generation starts or stops.
    private var intensity: Float = 0
    var targetIntensity: Float = 0
    var accent: SIMD4<Float> = .init(0.957, 0.765, 0.459, 1)

    init?(device: MTLDevice) {
        guard let queue = device.makeCommandQueue() else { return nil }

        let library: MTLLibrary
        do {
            library = try device.makeLibrary(source: statsHUDShaderSource, options: nil)
        } catch {
            // A shader that will not compile should degrade to the plain SwiftUI
            // background, never take the chat window down.
            NSLog("[GenieStatsHUD] shader compile failed: \(error.localizedDescription)")
            return nil
        }

        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = library.makeFunction(name: "hud_vertex")
        descriptor.fragmentFunction = library.makeFunction(name: "hud_fragment")
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm

        guard let state = try? device.makeRenderPipelineState(descriptor: descriptor) else {
            NSLog("[GenieStatsHUD] pipeline creation failed")
            return nil
        }

        self.commandQueue = queue
        self.pipeline = state
        super.init()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        uniforms.resolution = SIMD2(Float(size.width), Float(size.height))
    }

    func draw(in view: MTKView) {
        guard
            let drawable = view.currentDrawable,
            let descriptor = view.currentRenderPassDescriptor,
            let buffer = commandQueue.makeCommandBuffer(),
            let encoder = buffer.makeRenderCommandEncoder(descriptor: descriptor)
        else { return }

        // Ease toward the target — roughly a 0.4s time constant at 60fps.
        intensity += (targetIntensity - intensity) * 0.04

        uniforms.time = Float(CACurrentMediaTime() - started)
        uniforms.intensity = intensity
        uniforms.accent = accent

        encoder.setRenderPipelineState(pipeline)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<HUDUniforms>.stride, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()

        buffer.present(drawable)
        buffer.commit()
    }
}

// MARK: - SwiftUI bridge

private struct GenieStatsMetalBackdrop: NSViewRepresentable {
    var intensity: Double
    var accent: Color
    /// Stop the render loop entirely when there is nothing to animate.
    var isAnimating: Bool

    func makeCoordinator() -> GenieStatsHUDRenderer? {
        MTLCreateSystemDefaultDevice().flatMap(GenieStatsHUDRenderer.init(device:))
    }

    func makeNSView(context: Context) -> MTKView {
        let view = MTKView()
        view.device = MTLCreateSystemDefaultDevice()
        view.colorPixelFormat = .bgra8Unorm
        view.framebufferOnly = true
        view.layer?.isOpaque = false
        view.enableSetNeedsDisplay = false
        view.preferredFramesPerSecond = 60
        view.delegate = context.coordinator
        return view
    }

    func updateNSView(_ view: MTKView, context: Context) {
        context.coordinator?.targetIntensity = Float(max(0, min(1, intensity)))
        context.coordinator?.accent = accent.simdRGBA
        // Keep drawing briefly after generation stops so the field can ease out.
        view.isPaused = !isAnimating && intensity <= 0.001
    }
}

private extension Color {
    var simdRGBA: SIMD4<Float> {
        let ns = NSColor(self).usingColorSpace(.deviceRGB) ?? .white
        return SIMD4(Float(ns.redComponent), Float(ns.greenComponent),
                     Float(ns.blueComponent), Float(ns.alphaComponent))
    }
}

// MARK: - The HUD

/// `48s · ↓ 2.8k tokens` over a live Metal field.
public struct GenieMetalStatsHUD: View {
    @ObservedObject private var models = LocalModelManager.shared
    @AppStorage(PrefKey.activeGenieTheme) private var activeThemeRaw: String = GenieTheme.defaultTheme.rawValue
    @State private var now = Date()

    private let ticker = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    public init() {}

    /// Elapsed generation time. Freezes at the final value once generation ends.
    private var elapsed: TimeInterval {
        guard let started = models.generationStartedAt else { return 0 }
        return max(0, now.timeIntervalSince(started))
    }

    private var elapsedLabel: String {
        let s = Int(elapsed.rounded())
        if s < 60 { return "\(s)s" }
        return "\(s / 60)m \(s % 60)s"
    }

    /// Same 4-chars-per-token approximation the engine already uses for
    /// `lastTokensPerSecond`, so the two readouts agree.
    private var tokenCount: Int {
        Int((Double(models.currentResponse.count) / 4.0).rounded())
    }

    private var tokenLabel: String {
        let n = tokenCount
        if n < 1000 { return "\(n) tokens" }
        return String(format: "%.1fk tokens", Double(n) / 1000)
    }

    /// Drives the shader. 40 tok/s reads as full intensity.
    private var intensity: Double {
        guard models.isGenerating else { return 0 }
        return min(1, max(0.25, models.lastTokensPerSecond / 40.0))
    }

    private var accent: Color {
        (GenieTheme(rawValue: activeThemeRaw) ?? .defaultTheme).accentColor
    }

    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "bolt.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(accent)
                .opacity(models.isGenerating ? 1 : 0.45)

            Text(elapsedLabel)
                .monospacedDigit()

            Text("·")
                .foregroundStyle(.secondary)

            Text("↓ \(tokenLabel)")
                .monospacedDigit()

            if models.lastTokensPerSecond > 0 {
                Text("·")
                    .foregroundStyle(.secondary)
                Text(String(format: "%.1f tkps", models.lastTokensPerSecond))
                    .monospacedDigit()
                    .foregroundStyle(models.isGenerating ? accent : .secondary)
            }
        }
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(Color.white.opacity(0.92))
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background {
            GenieStatsMetalBackdrop(
                intensity: intensity,
                accent: accent,
                isAnimating: models.isGenerating
            )
        }
        .clipShape(Capsule())
        .overlay {
            Capsule()
                .strokeBorder(accent.opacity(models.isGenerating ? 0.45 : 0.18), lineWidth: 1)
        }
        .shadow(color: accent.opacity(models.isGenerating ? 0.3 : 0), radius: 10)
        .animation(.easeInOut(duration: 0.35), value: models.isGenerating)
        .onReceive(ticker) { now = $0 }
        .help("Generation time and approximate token count for the current response")
    }
}
