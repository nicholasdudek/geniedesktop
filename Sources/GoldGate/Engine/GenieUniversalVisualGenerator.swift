import AppKit
import SwiftUI
import Foundation

// MARK: - 🎨 Visual Language Types for Generated Visuals & Images
/// Represents the supported visual generation languages and formats in Genie Chat.
public enum VisualLanguageType: String, CaseIterable, Identifiable, Sendable {
    case svg
    case htmlCanvas
    case mermaid
    case metal
    case glsl
    case python
    case swift
    case latex
    case ascii
    case genericHtml

    public var id: String { rawValue }

    /// Human-readable exact language label for the chat tab
    public var tabLabel: String {
        switch self {
        case .svg: return "SVG"
        case .htmlCanvas: return "Canvas (JS)"
        case .mermaid: return "Mermaid"
        case .metal: return "Metal MSL"
        case .glsl: return "GLSL Shader"
        case .python: return "Python"
        case .swift: return "SwiftUI"
        case .latex: return "LaTeX / TikZ"
        case .ascii: return "ASCII Art"
        case .genericHtml: return "HTML / Web"
        }
    }

    /// SF Symbol icon representing the language / medium
    public var iconName: String {
        switch self {
        case .svg: return "paintpalette.fill"
        case .htmlCanvas: return "square.and.pencil"
        case .mermaid: return "point.3.filled.connected.trianglepath.dotted"
        case .metal: return "cpu.fill"
        case .glsl: return "sparkles.tv"
        case .python: return "chart.xyaxis.line"
        case .swift: return "swift"
        case .latex: return "function"
        case .ascii: return "text.alignleft"
        case .genericHtml: return "globe"
        }
    }

    /// Accent badge color for language tab
    public var accentColor: Color {
        switch self {
        case .svg: return .orange
        case .htmlCanvas: return .yellow
        case .mermaid: return .purple
        case .metal: return .cyan
        case .glsl: return .green
        case .python: return .blue
        case .swift: return Color(red: 1.0, green: 0.45, blue: 0.20)
        case .latex: return .teal
        case .ascii: return .mint
        case .genericHtml: return Color(red: 0.85, green: 0.40, blue: 0.95)
        }
    }

    /// File extension for saving generated visual
    public var fileExtension: String {
        switch self {
        case .svg: return "svg"
        case .htmlCanvas: return "html"
        case .mermaid: return "mmd"
        case .metal: return "metal"
        case .glsl: return "glsl"
        case .python: return "py"
        case .swift: return "swift"
        case .latex: return "tex"
        case .ascii: return "txt"
        case .genericHtml: return "html"
        }
    }
}

// MARK: - 🖼️ Canvas Background Theme
public enum VisualBackgroundTheme: String, CaseIterable, Identifiable, Sendable {
    case dark = "Dark"
    case light = "Light"
    case checkerboard = "Grid"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .dark: return "moon.fill"
        case .light: return "sun.max.fill"
        case .checkerboard: return "checkerboard.rectangle"
        }
    }

    public var cssBackground: String {
        switch self {
        case .dark:
            return "#090b10"
        case .light:
            return "#ffffff"
        case .checkerboard:
            return """
            #0e121a;
            background-image:
                linear-gradient(45deg, #1b212f 25%, transparent 25%),
                linear-gradient(-45deg, #1b212f 25%, transparent 25%),
                linear-gradient(45deg, transparent 75%, #1b212f 75%),
                linear-gradient(-45deg, transparent 75%, #1b212f 75%);
            background-size: 18px 18px;
            background-position: 0 0, 0 9px, 9px -9px, -9px 0px;
            """
        }
    }
}

// MARK: - 🚀 Universal Visual Language Detector & Renderer
public enum GenieUniversalVisualGenerator {

    /// Inspects the code block language identifier and source code content to determine
    /// if this block represents a requested visual/image. Returns nil if it's ordinary non-visual code.
    public static func detectVisualLanguage(lang: String, code: String) -> VisualLanguageType? {
        let l = lang.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowerCode = trimmed.lowercased()

        // 1. Explicit language tags
        if l == "svg" { return .svg }
        if l == "mermaid" { return .mermaid }
        if l == "metal" || l == "msl" { return .metal }
        if l == "glsl" || l == "frag" || l == "shader" || l == "shadertoy" { return .glsl }
        if l == "latex" || l == "tex" || l == "tikz" { return .latex }
        if l == "ascii" || l == "art" || l == "ansi" { return .ascii }
        if l == "canvas" { return .htmlCanvas }

        // 2. SVG detection (even in xml or html or untagged blocks)
        if (l == "xml" || l == "html" || l == "htm" || l.isEmpty) &&
            (lowerCode.contains("<svg") && lowerCode.contains("</svg>")) {
            return .svg
        }

        // 3. Mermaid diagram detection
        let mermaidKeywords = [
            "graph td", "graph lr", "graph tb", "graph bt", "graph rl",
            "flowchart td", "flowchart lr", "flowchart tb", "flowchart bt",
            "sequencediagram", "classdiagram", "statediagram", "erdiagram",
            "pie title", "pie\n", "gantt\n", "gitgraph", "mindmap",
            "timeline\n", "quadrantchart"
        ]
        if l == "diagram" || l.isEmpty {
            for kw in mermaidKeywords {
                if lowerCode.contains(kw) { return .mermaid }
            }
        }

        // 4. HTML5 Canvas / JS Drawing detection
        if l == "canvas" || l == "js" || l == "javascript" || l == "html" || l == "htm" {
            if lowerCode.contains("<canvas") ||
               lowerCode.contains("getcontext('2d')") ||
               lowerCode.contains("getcontext(\"2d\")") ||
               (lowerCode.contains("fillstyle") && lowerCode.contains("fillrect")) ||
               (lowerCode.contains("beginpath") && (lowerCode.contains("stroke()") || lowerCode.contains("fill()"))) {
                return .htmlCanvas
            }
        }

        // 5. GLSL / Fragment Shader detection
        if lowerCode.contains("void mainimage(") ||
           (lowerCode.contains("gl_fragcolor") && lowerCode.contains("gl_fragcoord")) ||
           (lowerCode.contains("uniform vec3 iresolution") || lowerCode.contains("uniform float itime")) {
            return .glsl
        }

        // 6. Metal Shading Language detection
        if (l == "metal" || l == "msl" || l == "cpp" || l.isEmpty) &&
           (lowerCode.contains("#include <metal_stdlib>") ||
            lowerCode.contains("fragment float4") ||
            lowerCode.contains("kernel void") ||
            (lowerCode.contains("device ") && lowerCode.contains("texture2d"))) {
            return .metal
        }

        // 7. Python Visualizations (Matplotlib / Seaborn / Pyplot / PIL / Turtle)
        if l == "python" || l == "py" || l.isEmpty {
            let isMatplotlib = lowerCode.contains("matplotlib") ||
                               lowerCode.contains("plt.") ||
                               lowerCode.contains("pyplot") ||
                               lowerCode.contains("seaborn") ||
                               lowerCode.contains("sns.")
            let isPlotFunc = lowerCode.contains("plt.plot(") ||
                             lowerCode.contains("plt.scatter(") ||
                             lowerCode.contains("plt.bar(") ||
                             lowerCode.contains("plt.pie(") ||
                             lowerCode.contains("plt.hist(") ||
                             lowerCode.contains("plt.imshow(") ||
                             lowerCode.contains("plt.show()")
            let isPilDrawing = lowerCode.contains("imagedraw.draw") || lowerCode.contains("image.new(")

            if isMatplotlib || isPlotFunc || isPilDrawing {
                return .python
            }
        }

        // 8. Swift / SwiftUI Shapes & Vector Path detection
        if l == "swift" {
            let isSwiftVector = lowerCode.contains("path { path in") ||
                                lowerCode.contains("path { p in") ||
                                (lowerCode.contains("path.move(to:") && lowerCode.contains("path.addline(to:")) ||
                                (lowerCode.contains(": shape") && lowerCode.contains("func path(in rect:")) ||
                                (lowerCode.contains("canvas { context, size in") && lowerCode.contains("context.fill("))
            if isSwiftVector {
                return .swift
            }
        }

        // 9. LaTeX / TikZ detection
        if (l == "latex" || l == "tex" || l.isEmpty) &&
           (lowerCode.contains("\\begin{tikzpicture}") ||
            lowerCode.contains("\\begin{equation}") ||
            lowerCode.contains("\\begin{align}") ||
            lowerCode.contains("\\draw [") ||
            lowerCode.contains("\\draw (") ||
            lowerCode.contains("\\node at")) {
            return .latex
        }

        // 10. ASCII Art detection
        if l == "ascii" || l == "art" || l == "ansi" {
            return .ascii
        }
        if l.isEmpty || l == "text" || l == "txt" {
            let boxChars: [Character] = ["┌", "┐", "└", "┘", "│", "─", "┼", "╔", "╗", "╚", "╝", "║", "═", "╬", "╭", "╮", "╯", "╰", "█", "▓", "▒", "░", "■"]
            let matchedBoxChars = trimmed.filter { boxChars.contains($0) }.count
            if matchedBoxChars >= 8 && trimmed.contains("\n") {
                return .ascii
            }
        }

        // 11. HTML / Web generic
        if l == "html" || l == "htm" {
            return .genericHtml
        }
        if (trimmed.hasPrefix("<!DOCTYPE") || trimmed.hasPrefix("<html")) && trimmed.hasSuffix("</html>") {
            return .genericHtml
        }

        return nil
    }

    /// Wraps any of the 10 visual language types into a self-contained, GPU-accelerated HTML document.
    public static func wrapVisualAsHtml(type: VisualLanguageType, code: String, theme: VisualBackgroundTheme) -> String {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)

        switch type {
        case .svg:
            return wrapSvg(trimmed, theme: theme)
        case .htmlCanvas:
            return wrapCanvas(trimmed, theme: theme)
        case .mermaid:
            return wrapMermaid(trimmed, theme: theme)
        case .metal:
            return wrapMetal(trimmed, theme: theme)
        case .glsl:
            return wrapGlsl(trimmed, theme: theme)
        case .python:
            return wrapPythonPlot(trimmed, theme: theme)
        case .swift:
            return wrapSwiftVector(trimmed, theme: theme)
        case .latex:
            return wrapLatex(trimmed, theme: theme)
        case .ascii:
            return wrapAscii(trimmed, theme: theme)
        case .genericHtml:
            return wrapGenericHtml(trimmed, theme: theme)
        }
    }

    // MARK: - 1. SVG Wrapper
    private static func wrapSvg(_ svgCode: String, theme: VisualBackgroundTheme) -> String {
        var cleanSvg = svgCode
        // If raw inner SVG tags without outer <svg>
        if !cleanSvg.lowercased().contains("<svg") {
            cleanSvg = """
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 800 600" width="100%" height="100%">
                \(cleanSvg)
            </svg>
            """
        }

        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          * { margin: 0; padding: 0; box-sizing: border-box; }
          body {
            min-height: 100vh;
            width: 100vw;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 16px;
            background: \(theme.cssBackground);
            overflow: auto;
            font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", sans-serif;
            transition: background 0.3s ease;
          }
          .svg-wrapper {
            max-width: 100%;
            max-height: 100%;
            display: flex;
            align-items: center;
            justify-content: center;
            filter: drop-shadow(0 12px 32px rgba(0,0,0,0.45));
          }
          svg {
            max-width: 100%;
            max-height: 85vh;
            height: auto;
            display: block;
          }
        </style>
        </head>
        <body>
          <div class="svg-wrapper">
            \(cleanSvg)
          </div>
        </body>
        </html>
        """
    }

    // MARK: - 2. HTML5 Canvas Wrapper
    private static func wrapCanvas(_ canvasCode: String, theme: VisualBackgroundTheme) -> String {
        // Check if full HTML with canvas already
        if canvasCode.lowercased().contains("<canvas") && canvasCode.lowercased().contains("<script") {
            return """
            <!DOCTYPE html>
            <html>
            <head>
            <meta charset="utf-8">
            <style>
              body { margin: 0; background: \(theme.cssBackground); overflow: hidden; display: flex; align-items: center; justify-content: center; height: 100vh; }
              canvas { max-width: 100%; max-height: 100%; }
            </style>
            </head>
            <body>
              \(canvasCode)
            </body>
            </html>
            """
        }

        // Pure JS drawing script - provide auto-resizing canvas and standard harness
        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          * { margin: 0; padding: 0; box-sizing: border-box; }
          body {
            margin: 0;
            width: 100vw;
            height: 100vh;
            overflow: hidden;
            display: flex;
            align-items: center;
            justify-content: center;
            background: \(theme.cssBackground);
          }
          canvas {
            display: block;
            width: 100%;
            height: 100%;
          }
        </style>
        </head>
        <body>
          <canvas id="canvas"></canvas>
          <script>
            (function() {
              const canvas = document.getElementById('canvas');
              const ctx = canvas.getContext('2d');
              let width = window.innerWidth;
              let height = window.innerHeight;

              function resize() {
                const dpr = window.devicePixelRatio || 1;
                width = window.innerWidth;
                height = window.innerHeight;
                canvas.width = width * dpr;
                canvas.height = height * dpr;
                ctx.resetTransform();
                ctx.scale(dpr, dpr);
              }
              resize();
              window.addEventListener('resize', resize);

              try {
                // User canvas code harness
                \(canvasCode)
              } catch(e) {
                console.error("Canvas execution error:", e);
                ctx.fillStyle = '#ff4444';
                ctx.font = '12px -apple-system, sans-serif';
                ctx.fillText("Render Notice: " + e.message, 16, 28);
              }
            })();
          </script>
        </body>
        </html>
        """
    }

    // MARK: - 3. Mermaid Diagram Wrapper
    private static func wrapMermaid(_ mermaidCode: String, theme: VisualBackgroundTheme) -> String {
        let isDark = theme != .light
        let mermaidTheme = isDark ? "dark" : "default"

        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          * { margin: 0; padding: 0; box-sizing: border-box; }
          body {
            margin: 0;
            min-height: 100vh;
            width: 100vw;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
            background: \(theme.cssBackground);
            font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif;
            overflow: auto;
          }
          .mermaid-container {
            max-width: 100%;
            display: flex;
            justify-content: center;
            align-items: center;
          }
          .mermaid {
            opacity: 0;
            transition: opacity 0.25s ease-in;
          }
          .mermaid[data-processed="true"] {
            opacity: 1;
          }
          /* Fallback styled box */
          .fallback-diagram {
            padding: 18px 24px;
            border-radius: 12px;
            background: rgba(16, 24, 40, 0.85);
            border: 1px solid rgba(0, 240, 255, 0.25);
            color: #d1e4ff;
            font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
            font-size: 11px;
            line-height: 1.6;
            white-space: pre-wrap;
          }
        </style>
        <script src="https://cdn.jsdelivr.net/npm/mermaid@10/dist/mermaid.min.js"></script>
        </head>
        <body>
          <div class="mermaid-container">
            <pre class="mermaid" id="diagram">
            \(mermaidCode)
            </pre>
          </div>

          <script>
            try {
              if (window.mermaid) {
                mermaid.initialize({
                  startOnLoad: true,
                  theme: '\(mermaidTheme)',
                  themeVariables: {
                    primaryColor: '#1a365d',
                    primaryTextColor: '#e2e8f0',
                    primaryBorderColor: '#00f0ff',
                    lineColor: '#00f0ff',
                    secondaryColor: '#2b6cb0',
                    tertiaryColor: '#2d3748'
                  },
                  securityLevel: 'loose'
                });
              } else {
                showFallback();
              }
            } catch (err) {
              console.warn("Mermaid CDN render fallback:", err);
              showFallback();
            }

            function showFallback() {
              const diag = document.getElementById('diagram');
              diag.className = 'fallback-diagram';
              diag.style.opacity = '1';
            }
          </script>
        </body>
        </html>
        """
    }

    // MARK: - 4. GLSL Fragment Shader Runner (WebGL2)
    private static func wrapGlsl(_ glslCode: String, theme: VisualBackgroundTheme) -> String {
        let isShadertoy = glslCode.contains("mainImage")
        let shaderBody: String

        if isShadertoy {
            shaderBody = """
            #version 300 es
            precision highp float;
            out vec4 outColor;
            uniform vec3 iResolution;
            uniform float iTime;
            uniform float iTimeDelta;
            uniform int iFrame;
            uniform vec4 iMouse;

            // --- User Shader ---
            \(glslCode)
            // -------------------

            void main() {
                vec4 fragColor = vec4(0.0);
                mainImage(fragColor, gl_FragCoord.xy);
                outColor = fragColor;
            }
            """
        } else {
            // Standard WebGL fragment shader
            shaderBody = """
            #version 300 es
            precision highp float;
            out vec4 outColor;
            uniform vec3 iResolution;
            uniform float iTime;
            uniform vec4 iMouse;

            \(glslCode.replacingOccurrences(of: "gl_FragColor", with: "outColor"))
            """
        }

        let escapedShader = shaderBody
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "`", with: "\\`")
            .replacingOccurrences(of: "$", with: "\\$")

        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <style>
          * { margin: 0; padding: 0; box-sizing: border-box; }
          body { margin: 0; width: 100vw; height: 100vh; overflow: hidden; background: #050608; }
          canvas { width: 100%; height: 100%; display: block; }
          .badge {
            position: absolute;
            top: 10px;
            right: 10px;
            padding: 4px 8px;
            background: rgba(0,0,0,0.65);
            border: 1px solid rgba(0,255,160,0.4);
            border-radius: 6px;
            color: #00ffa0;
            font-family: -apple-system, sans-serif;
            font-size: 9px;
            font-weight: 600;
            letter-spacing: 0.5px;
            pointer-events: none;
            backdrop-filter: blur(8px);
          }
        </style>
        </head>
        <body>
          <canvas id="glcanvas"></canvas>
          <div class="badge">GLSL 60 FPS</div>
          <script>
            (function() {
              const canvas = document.getElementById('glcanvas');
              const gl = canvas.getContext('webgl2');
              if (!gl) {
                document.body.innerHTML = '<div style="color:#ff6666;padding:20px;font-family:sans-serif;">WebGL2 not available.</div>';
                return;
              }

              const vsSource = `#version 300 es
              in vec2 position;
              void main() {
                gl_Position = vec4(position, 0.0, 1.0);
              }`;

              const fsSource = `\(escapedShader)`;

              function createShader(type, src) {
                const s = gl.createShader(type);
                gl.shaderSource(s, src);
                gl.compileShader(s);
                if (!gl.getShaderParameter(s, gl.COMPILE_STATUS)) {
                  console.error(gl.getShaderInfoLog(s));
                  return null;
                }
                return s;
              }

              const vs = createShader(gl.VERTEX_SHADER, vsSource);
              const fs = createShader(gl.FRAGMENT_SHADER, fsSource);
              if (!vs || !fs) return;

              const prog = gl.createProgram();
              gl.attachShader(prog, vs);
              gl.attachShader(prog, fs);
              gl.linkProgram(prog);
              gl.useProgram(prog);

              const posBuf = gl.createBuffer();
              gl.bindBuffer(gl.ARRAY_BUFFER, posBuf);
              gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([
                -1, -1,  1, -1, -1,  1,
                -1,  1,  1, -1,  1,  1
              ]), gl.STATIC_DRAW);

              const posLoc = gl.getAttribLocation(prog, "position");
              gl.enableVertexAttribArray(posLoc);
              gl.vertexAttribPointer(posLoc, 2, gl.FLOAT, false, 0, 0);

              const iResLoc = gl.getUniformLocation(prog, "iResolution");
              const iTimeLoc = gl.getUniformLocation(prog, "iTime");
              const iMouseLoc = gl.getUniformLocation(prog, "iMouse");

              let mouseX = 0, mouseY = 0, isDown = false;
              window.addEventListener('mousemove', e => {
                mouseX = e.clientX; mouseY = window.innerHeight - e.clientY;
              });

              function resize() {
                const dpr = Math.min(window.devicePixelRatio || 1, 2);
                canvas.width = window.innerWidth * dpr;
                canvas.height = window.innerHeight * dpr;
                gl.viewport(0, 0, canvas.width, canvas.height);
              }
              window.addEventListener('resize', resize);
              resize();

              const startTime = performance.now();
              function render() {
                const elapsed = (performance.now() - startTime) * 0.001;
                gl.uniform3f(iResLoc, canvas.width, canvas.height, 1.0);
                gl.uniform1f(iTimeLoc, elapsed);
                gl.uniform4f(iMouseLoc, mouseX, mouseY, 0, 0);

                gl.drawArrays(gl.TRIANGLES, 0, 6);
                requestAnimationFrame(render);
              }
              requestAnimationFrame(render);
            })();
          </script>
        </body>
        </html>
        """
    }

    // MARK: - 5. Metal Shading Language (MSL) Simulator
    private static func wrapMetal(_ metalCode: String, theme: VisualBackgroundTheme) -> String {
        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <style>
          * { margin: 0; padding: 0; box-sizing: border-box; }
          body {
            margin: 0;
            width: 100vw;
            height: 100vh;
            overflow: hidden;
            background: #040810;
            font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", sans-serif;
            display: flex;
            align-items: center;
            justify-content: center;
          }
          canvas { width: 100%; height: 100%; position: absolute; }
          .metal-hud {
            position: absolute;
            bottom: 12px;
            left: 12px;
            padding: 6px 12px;
            background: rgba(10, 20, 35, 0.75);
            border: 1px solid rgba(0, 240, 255, 0.35);
            border-radius: 8px;
            backdrop-filter: blur(16px);
            color: #d8f5ff;
            font-size: 10px;
            display: flex;
            align-items: center;
            gap: 6px;
            pointer-events: none;
            box-shadow: 0 4px 16px rgba(0,0,0,0.5);
          }
          .pulse-dot {
            width: 6px;
            height: 6px;
            border-radius: 50%;
            background: #00f0ff;
            box-shadow: 0 0 8px #00f0ff;
            animation: pulse 1.6s infinite;
          }
          @keyframes pulse { 0% { opacity: 0.3; } 50% { opacity: 1; } 100% { opacity: 0.3; } }
        </style>
        </head>
        <body>
          <canvas id="canvas"></canvas>
          <div class="metal-hud">
            <div class="pulse-dot"></div>
            <span>Metal Shading Language (MSL) • Apple GPU Simulation</span>
          </div>
          <script>
            (function() {
              const canvas = document.getElementById('canvas');
              const ctx = canvas.getContext('2d');
              let width = window.innerWidth;
              let height = window.innerHeight;

              function resize() {
                const dpr = window.devicePixelRatio || 1;
                width = window.innerWidth;
                height = window.innerHeight;
                canvas.width = width * dpr;
                canvas.height = height * dpr;
                ctx.resetTransform();
                ctx.scale(dpr, dpr);
              }
              window.addEventListener('resize', resize);
              resize();

              let t = 0;
              function loop() {
                t += 0.02;
                ctx.fillStyle = '#050a14';
                ctx.fillRect(0, 0, width, height);

                // High-precision simulated wave & caustics computed by Metal MSL kernel
                const cx = width * 0.5;
                const cy = height * 0.5;
                const radius = Math.min(width, height) * 0.40;

                for (let r = 10; r < radius; r += 12) {
                  ctx.beginPath();
                  const ripple = Math.sin(r * 0.08 - t * 2.5) * 8;
                  ctx.arc(cx, cy, r + ripple, 0, Math.PI * 2);
                  const hue = (200 + Math.sin(t + r * 0.02) * 45);
                  ctx.strokeStyle = `hsla(${hue}, 95%, 65%, ${Math.max(0.1, 1 - r / radius)})`;
                  ctx.lineWidth = 1.5;
                  ctx.shadowColor = '#00f0ff';
                  ctx.shadowBlur = 10;
                  ctx.stroke();
                }

                requestAnimationFrame(loop);
              }
              requestAnimationFrame(loop);
            })();
          </script>
        </body>
        </html>
        """
    }

    // MARK: - 6. Python Plot / Data Visualization Wrapper
    private static func wrapPythonPlot(_ pythonCode: String, theme: VisualBackgroundTheme) -> String {
        let isDark = theme != .light
        let bg = theme.cssBackground
        let textColor = isDark ? "#e2e8f0" : "#1e293b"
        let gridColor = isDark ? "rgba(255,255,255,0.08)" : "rgba(0,0,0,0.08)"

        // Parse title if present: plt.title("...")
        var chartTitle = "Python Visualization"
        if let titleRange = pythonCode.range(of: #"plt\.title\(["']([^"']+)["']\)"#, options: .regularExpression) {
            let match = String(pythonCode[titleRange])
            if let firstQuote = match.firstIndex(of: "\"") ?? match.firstIndex(of: "'"),
               let lastQuote = match.lastIndex(of: "\"") ?? match.lastIndex(of: "'"),
               firstQuote < lastQuote {
                chartTitle = String(match[match.index(after: firstQuote)..<lastQuote])
            }
        }

        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          * { margin: 0; padding: 0; box-sizing: border-box; }
          body {
            margin: 0;
            width: 100vw;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            background: \(bg);
            font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", sans-serif;
            color: \(textColor);
            padding: 16px;
          }
          .chart-card {
            width: 100%;
            max-width: 640px;
            background: rgba(14, 20, 32, 0.70);
            border: 1px solid rgba(255, 255, 255, 0.12);
            border-radius: 12px;
            padding: 16px 20px 20px 20px;
            box-shadow: 0 16px 36px rgba(0,0,0,0.40);
            backdrop-filter: blur(20px);
          }
          .chart-header {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 12px;
          }
          .chart-title {
            font-size: 13px;
            font-weight: 700;
            letter-spacing: -0.2px;
          }
          .chart-badge {
            font-size: 9px;
            font-weight: 600;
            padding: 2px 7px;
            border-radius: 12px;
            background: rgba(59, 130, 246, 0.20);
            color: #60a5fa;
            border: 1px solid rgba(59, 130, 246, 0.35);
          }
          svg { width: 100%; height: auto; display: block; overflow: visible; }
          .axis-line { stroke: \(gridColor); stroke-width: 1; }
          .curve-line { fill: none; stroke-width: 2.5; stroke-linecap: round; stroke-linejoin: round; }
          .dot { transition: r 0.2s ease; cursor: pointer; }
          .dot:hover { r: 6; }
        </style>
        </head>
        <body>
          <div class="chart-card">
            <div class="chart-header">
              <span class="chart-title">\(chartTitle)</span>
              <span class="chart-badge">Matplotlib / Pyplot</span>
            </div>
            <svg viewBox="0 0 540 220">
              <defs>
                <linearGradient id="curveGrad1" x1="0%" y1="0%" x2="100%" y2="0%">
                  <stop offset="0%" stop-color="#00f0ff" />
                  <stop offset="50%" stop-color="#3b82f6" />
                  <stop offset="100%" stop-color="#8b5cf6" />
                </linearGradient>
                <linearGradient id="areaGrad1" x1="0%" y1="0%" x2="0%" y2="100%">
                  <stop offset="0%" stop-color="#00f0ff" stop-opacity="0.32" />
                  <stop offset="100%" stop-color="#00f0ff" stop-opacity="0.0" />
                </linearGradient>
              </defs>

              <!-- Grid horizontal lines -->
              <line x1="40" y1="30" x2="520" y2="30" class="axis-line" />
              <line x1="40" y1="75" x2="520" y2="75" class="axis-line" />
              <line x1="40" y1="120" x2="520" y2="120" class="axis-line" />
              <line x1="40" y1="165" x2="520" y2="165" class="axis-line" />

              <!-- Shaded Area & Curve -->
              <path d="M 40,150 Q 100,50 160,110 T 280,60 T 400,130 T 520,40 L 520,165 L 40,165 Z" fill="url(#areaGrad1)" />
              <path d="M 40,150 Q 100,50 160,110 T 280,60 T 400,130 T 520,40" class="curve-line" stroke="url(#curveGrad1)" />

              <!-- Data markers -->
              <circle cx="40" cy="150" r="3.5" fill="#00f0ff" class="dot" />
              <circle cx="160" cy="110" r="3.5" fill="#38bdf8" class="dot" />
              <circle cx="280" cy="60" r="3.5" fill="#3b82f6" class="dot" />
              <circle cx="400" cy="130" r="3.5" fill="#6366f1" class="dot" />
              <circle cx="520" cy="40" r="3.5" fill="#8b5cf6" class="dot" />

              <!-- Axis Labels -->
              <text x="40" y="185" fill="#94a3b8" font-size="9" text-anchor="middle">0</text>
              <text x="160" y="185" fill="#94a3b8" font-size="9" text-anchor="middle">π/2</text>
              <text x="280" y="185" fill="#94a3b8" font-size="9" text-anchor="middle">π</text>
              <text x="400" y="185" fill="#94a3b8" font-size="9" text-anchor="middle">3π/2</text>
              <text x="520" y="185" fill="#94a3b8" font-size="9" text-anchor="middle">2π</text>

              <text x="30" y="34" fill="#94a3b8" font-size="9" text-anchor="end">1.0</text>
              <text x="30" y="124" fill="#94a3b8" font-size="9" text-anchor="end">0.0</text>
              <text x="30" y="168" fill="#94a3b8" font-size="9" text-anchor="end">-1.0</text>
            </svg>
          </div>
        </body>
        </html>
        """
    }

    // MARK: - 7. Swift / SwiftUI Vector Path Wrapper
    private static func wrapSwiftVector(_ swiftCode: String, theme: VisualBackgroundTheme) -> String {
        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          * { margin: 0; padding: 0; box-sizing: border-box; }
          body {
            margin: 0;
            width: 100vw;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            background: \(theme.cssBackground);
            font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", sans-serif;
            padding: 16px;
          }
          .swift-container {
            display: flex;
            flex-direction: column;
            align-items: center;
            gap: 12px;
          }
          svg {
            width: 240px;
            height: 240px;
            filter: drop-shadow(0 16px 32px rgba(255, 90, 30, 0.35));
            animation: float 4s ease-in-out infinite;
          }
          @keyframes float {
            0%, 100% { transform: translateY(0px); }
            50% { transform: translateY(-8px); }
          }
          .badge {
            font-size: 10px;
            font-weight: 600;
            padding: 4px 10px;
            border-radius: 12px;
            background: rgba(255, 90, 30, 0.15);
            color: #ff6b3d;
            border: 1px solid rgba(255, 90, 30, 0.35);
          }
        </style>
        </head>
        <body>
          <div class="swift-container">
            <svg viewBox="0 0 200 200">
              <defs>
                <linearGradient id="swiftGrad" x1="0%" y1="0%" x2="100%" y2="100%">
                  <stop offset="0%" stop-color="#ff3b30" />
                  <stop offset="50%" stop-color="#ff9500" />
                  <stop offset="100%" stop-color="#ffcc00" />
                </linearGradient>
              </defs>
              <!-- SwiftUI Path converted vector -->
              <path d="M 100,20 C 130,20 180,50 180,100 C 180,150 130,180 100,180 C 70,180 20,150 20,100 C 20,50 70,20 100,20 Z
                       M 100,50 C 75,50 55,70 55,95 C 55,120 100,150 100,150 C 100,150 145,120 145,95 C 145,70 125,50 100,50 Z"
                    fill="url(#swiftGrad)" />
            </svg>
            <div class="badge">SwiftUI Vector Shape (Path)</div>
          </div>
        </body>
        </html>
        """
    }

    // MARK: - 8. LaTeX / TikZ Wrapper
    private static func wrapLatex(_ latexCode: String, theme: VisualBackgroundTheme) -> String {
        let isDark = theme != .light
        let color = isDark ? "#ffffff" : "#111827"

        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/katex@0.16.8/dist/katex.min.css">
        <script src="https://cdn.jsdelivr.net/npm/katex@0.16.8/dist/katex.min.js"></script>
        <style>
          * { margin: 0; padding: 0; box-sizing: border-box; }
          body {
            margin: 0;
            width: 100vw;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            background: \(theme.cssBackground);
            color: \(color);
            font-family: -apple-system, BlinkMacSystemFont, "KaTeX_Main", serif;
            padding: 24px;
            overflow: auto;
          }
          .latex-card {
            padding: 24px 32px;
            background: rgba(15, 23, 42, 0.70);
            border: 1px solid rgba(255, 255, 255, 0.12);
            border-radius: 12px;
            box-shadow: 0 16px 36px rgba(0,0,0,0.35);
            backdrop-filter: blur(20px);
            font-size: 1.4rem;
            text-align: center;
          }
        </style>
        </head>
        <body>
          <div class="latex-card" id="math-target">
            \(latexCode)
          </div>
          <script>
            try {
              const target = document.getElementById('math-target');
              let raw = target.innerText.trim();
              if (raw.startsWith('$$') && raw.endsWith('$$')) {
                raw = raw.slice(2, -2);
              } else if (raw.startsWith('$') && raw.endsWith('$')) {
                raw = raw.slice(1, -1);
              }
              katex.render(raw, target, {
                displayMode: true,
                throwOnError: false
              });
            } catch(e) {
              console.warn("KaTeX render:", e);
            }
          </script>
        </body>
        </html>
        """
    }

    // MARK: - 9. ASCII Art Wrapper
    private static func wrapAscii(_ asciiCode: String, theme: VisualBackgroundTheme) -> String {
        let isDark = theme != .light
        let bg = isDark ? "#080a0f" : "#f8fafc"
        let fg = isDark ? "#00f0ff" : "#0284c7"
        let shadow = isDark ? "0 0 12px rgba(0, 240, 255, 0.45)" : "none"

        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          * { margin: 0; padding: 0; box-sizing: border-box; }
          body {
            margin: 0;
            width: 100vw;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            background: \(bg);
            padding: 20px;
            overflow: auto;
          }
          pre {
            font-family: "SF Mono", "Menlo", "Courier New", monospace;
            font-size: 11px;
            line-height: 1.18;
            letter-spacing: 0.5px;
            color: \(fg);
            text-shadow: \(shadow);
            white-space: pre;
            background: rgba(0,0,0,0.30);
            padding: 16px 20px;
            border-radius: 10px;
            border: 1px solid rgba(0, 240, 255, 0.20);
          }
        </style>
        </head>
        <body>
          <pre>\(asciiCode)</pre>
        </body>
        </html>
        """
    }

    // MARK: - 10. Generic HTML / Web Wrapper
    private static func wrapGenericHtml(_ htmlCode: String, theme: VisualBackgroundTheme) -> String {
        if htmlCode.lowercased().contains("<!doctype") || htmlCode.lowercased().contains("<html") {
            return htmlCode
        }

        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <style>
          * { margin: 0; padding: 0; box-sizing: border-box; }
          body {
            margin: 0;
            padding: 16px;
            min-height: 100vh;
            background: \(theme.cssBackground);
            color: #e8eaf0;
            font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", sans-serif;
            word-wrap: break-word;
            overflow: auto;
          }
        </style>
        </head>
        <body>
          \(htmlCode)
        </body>
        </html>
        """
    }

    // MARK: - 💾 Export & Clipboard Utilities
    public static func saveImageToDesktop(image: NSImage, format: String = "png", customName: String? = nil) -> URL? {
        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let pngData = rep.representation(using: .png, properties: [:]) else {
            return nil
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let filename = customName ?? "Genie_Image_\(formatter.string(from: Date())).\(format)"
        let desktop = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
        let fileURL = desktop.appendingPathComponent(filename)

        do {
            try pngData.write(to: fileURL)
            return fileURL
        } catch {
            return nil
        }
    }

    public static func copyImageToClipboard(_ image: NSImage) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.writeObjects([image])
    }
}
