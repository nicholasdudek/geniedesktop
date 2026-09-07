# ▦ 3×3 Scaled Program Displayer & GPU Viewport Filter Pipeline
## High-Performance Multi-App Matrix Architecture for macOS (Apple Silicon)

**Document Version:** 1.0.0  
**Author:** Nicholas M. Dudek & GoldGate Engineering Team  
**Target Systems:** macOS 14 Sonoma, macOS 15 Sequoia, macOS 16+ (Apple Silicon M1–M4 / Ultra)  
**Modules:** [`ScaledProgramDisplayerEngine.swift`](file:///Users/nicholasdudek/Developer/GoldGate/Sources/GoldGate/Engine/ScaledProgramDisplayerEngine.swift), [`ScaledProgramMatrixView.swift`](file:///Users/nicholasdudek/Developer/GoldGate/Sources/GoldGate/Views/ScaledProgramMatrixView.swift), [`FinderChatWindowManager.swift`](file:///Users/nicholasdudek/Developer/GoldGate/Sources/GoldGate/Core/FinderChatWindowManager.swift), [`FinderStyleChatWindowView.swift`](file:///Users/nicholasdudek/Developer/GoldGate/Sources/GoldGate/Views/FinderStyleChatWindowView.swift)

---

## 1. Executive Summary & Core Breakthrough

Traditional macOS window tiling and virtual space managers attempt to fit multiple applications on screen by physically resizing their `NSWindow` frames. This approach fails because macOS applications (e.g., Xcode, Safari, VS Code, Slack, Figma, Terminal) enforce hardcoded minimum window sizes (`minSize: 600–900px`). When compressed below these thresholds, toolbars truncate, sidebars collapse into hamburger menus, and web canvases reflow into broken mobile viewports.

### The Viewport Filter Paradigm
Instead of shrinking window frames, **Genie leaves all applications running at their full native resolution (1440×900 / 1080p / 4K)** in their respective WindowServer buffers. We then apply an **Accelerated GPU Viewport & Compositing Filter Pipeline** to scale the output surfaces into an interactive **3×3 Matrix (33.3% Scale Factor / 0.333×)**.

```
┌────────────────────────────────────────────────────────────────────────┐
│                        3×3 PROGRAM DISPLAYER                           │
├───────────────────┬───────────────────┬────────────────────────────────┤
│ [1] Xcode (0.33×) │ [2] Safari (0.33×)│ [3] VS Code (0.33×)            │
│  Live 120 FPS     │  Live 120 FPS     │  Live 120 FPS                  │
├───────────────────┼───────────────────┼────────────────────────────────┤
│ [4] Terminal (33%)│ [5] Slack (0.33×) │ [6] Figma (0.33×)              │
│  Live 120 FPS     │  Live 120 FPS     │  Live 120 FPS                  │
├───────────────────┼───────────────────┼────────────────────────────────┤
│ [7] Music (0.33×) │ [8] Notes (0.33×) │ [9] Genie Chat (0.33×)         │
│  Live 120 FPS     │  Live 120 FPS     │  Live 120 FPS                  │
└───────────────────┴───────────────────┴────────────────────────────────┘
```

---

## 2. Technical Architecture & Subsystems

### 2.1. Multi-Stage GPU Filter Pipeline
1. **Affine Scale Filter (`CGAffineTransformMakeScale(0.333, 0.333)`):**
   - Scales the full frame buffer into a discrete 3×3 grid slot.
2. **Lanczos / Sub-Pixel Anti-Aliasing Pass:**
   - Mitigates moiré patterns and line aliasing during 3:1 downsampling.
3. **Micro-Typography Contrast Unsharp Masking:**
   - Sharpens high-frequency vector text contours so IDE code, browser URLs, and terminal output remain legible at 33% scale.
4. **Liquid Glass Specular Tile Geometry:**
   - Renders 1px dynamic specular rim lighting, subtle drop shadows, and continuous corner curves over the desktop wallpaper.

### 2.2. Zero-Hitch Input Forwarding
- Clicks, double clicks, scrolls, and drag gestures inside each 3×3 cell are normalized:
  $$\vec{P}_{\text{native}} = \frac{\vec{P}_{\text{cell}} - \vec{O}_{\text{cell}}}{s} + \vec{O}_{\text{window}}$$
- Synthetic `CGEvent` instances are posted via `cghidEventTap` directly to the target `CGWindowID`.

### 2.3. Full-Screen Spatial Integration
- **Full-Screen 3×3 Overview:** Expands the matrix to 100% of the visible display ([`FinderChatWindowManager.shared.snapTo(preset: .fullScreen)`](file:///Users/nicholasdudek/Developer/GoldGate/Sources/GoldGate/Core/FinderChatWindowManager.swift)).
- **1-Click Spring Zoom:** Clicking any cell instantly springs that app into 100% full screen (`focusedSlotId`).
- **1-Click Spring Collapse:** Clicking `"Back to 3×3 Grid"` or pressing `Esc` glides back to the 9-app overview.

---

## 3. User Interaction & Directives

| Trigger Method | Action |
| :--- | :--- |
| **Chat / Search Bar** | Type `!3x3`, `!fullscreen 3x3`, `"fit 9 programs"`, or `"3x3 matrix"` and press Enter. |
| **Top Glass Ribbon** | Click `Popups ✥` → `[▦ 3×3 Program Matrix Displayer]`. |
| **Workspace Tabs** | Click `+` → `[3×3 Program Matrix]`. |
| **Window Sizing Menu** | Choose `Full Screen ⤢`, `Vertical Top ↕️`, or `Most Screen ⛶`. |
| **Cell Click** | Zoom program from 33.3% to 100% Full Screen. |
| **Escape Key / Back Button** | Return from 100% zoomed view back to 3×3 grid. |

---

## 4. Engineering Team Task Assignments

1. **`metal_gpu_compositing_specialist`:**
   - Optimize real-time Metal 3/4 compute shaders for zero-copy 120 FPS texture sampling and high-DPI font sharpening.
2. **`skylight_windowserver_architect`:**
   - Integrate low-level SkyLight CGS/SLS window transform hooks and zero-latency sub-pixel event translation.
3. **`multi_app_matrix_qa_engineer`:**
   - Run end-to-end stress tests with 9 concurrent running macOS apps, memory profiling (<35MB RAM overhead), and fluid ProMotion frame rate verification.
