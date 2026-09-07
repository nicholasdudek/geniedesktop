# 🎩 Application Screen Size Trickster & Virtual Compact Screen Engine

## Overview
The **Application Screen Size Trickster Engine** (`AppScreenSizeTricksterEngine.swift`) tricks newly launched macOS applications into believing they are opening onto a compact or smallest virtual screen size (e.g. 1/3 display slot, 960×600 micro, 1280×720 compact laptop, or 390×844 mobile).

On large, high-resolution desktops (4K, 5K, Retina displays), this enables up to 9 native running programs to load and tile effortlessly into a 3×3 matrix without spawning oversized default windows or sprawling across screens.

---

## 🛠️ Key Architectural Components

### 1. Virtual Screen Profiles (`VirtualScreenProfile`)
- **`slot3x3`**: 1/3 of the display dimensions ($\approx 853 \times 480$ pt on 1440p).
- **`ultraCompact`**: Micro canvas ($960 \times 600$ pt).
- **`compactLaptop`**: Streamlined 720p ($1280 \times 720$ pt).
- **`classicXGA`**: Classic single-column ($1024 \times 768$ pt).
- **`squareStudio`**: Equal aspect ratio ($800 \times 800$ pt).
- **`mobilePortrait`**: Phone layout ($390 \times 844$ pt).

### 2. Startup Frame & State Spoofing
- Injects Cocoa launch arguments into `NSWorkspace.OpenConfiguration`:
  - `-ApplePersistenceIgnoreState YES` — Prevents apps from restoring previous oversized window geometries.
  - `-NSWindowFrame "<x> <y> <w> <h> 0 0 <screen_w> <screen_h>"` — Injects the initial window position and dimensions directly into the app initialization sequence.

### 3. Progressive Accessibility Clamping (`AXUIElement`)
- Retries window dimension clamping at multiple intervals (`0.1s`, `0.25s`, `0.5s`, `0.9s`, `1.4s`) to counter internal app resize handlers during post-launch initialization.
- Sets `kAXPositionAttribute` and `kAXSizeAttribute` surgically.

### 4. Directives & Natural Language
- `!trick <app>` or `!compact <app>` or `!small <app>`: Launches app in the next available 3×3 slot (1 to 9).
- Natural language: "open <app>" or "launch <app>" automatically routes through the trickster engine when enabled.

### 5. Live Inline Preview Tray Integration
- Triggers floating preview in `ChatInlinePreviewTrayView` (`.tricksterApp(...)`) above the search bar with instant re-launch and matrix viewer actions.
