# Genie 4.0 Roadmap

Running checklist from the 2026-09-08 session. Status markers: `[ ]` not started, `[~]` in progress, `[x]` done, `[?]` needs a decision before work starts.

## Shipped this session
- [x] `GenieFinderSyncShared` + `GenieFinderSync` targets — real `FIFinderSync` extension (toolbar button, badges, right-click menu) + `Core/FinderSyncBridge.swift` host-side listener. Builds clean (`swift build`, 257/257 units). **Not yet packaged as a real `.appex`** — SwiftPM can't emit the Mach-O bundle type extensions need; that step needs an Xcode "Finder Sync Extension" target wrapping these same files, plus the `group.com.nicholasdudek.genie` App Group registered on the Apple Developer account.
- [x] Version bumped to 4.0.0 / build 400 (`Sources/GoldGate/Info.plist`).
- [x] Settings sidebar (`Views/UnifiedSettingsView.swift:362` `settingsSidebar`) restyled to match real macOS System Settings: uniform accent-color selection fill (no per-tab tint/border), no bold-on-select, no selection dot, no Dock-style hover-magnify, bigger icon badges (26pt) and label text (13pt).

## In progress / recently shipped
- [x] Right-edge dock: scrollable running-apps row, slider/scroll-wheel cycling skips Finder, Messages/Applications icons relocate next to Trash.
- [x] Liquid-glass panel that slides down from the top of the screen on scroll-up / Zenith gesture (`Views/LiquidGlassTopDashboardView.swift`), combining Quick Chat + Mini Settings + a Clock/Dashboard widget at the top. Heavy specular frosted liquid glass material with real-time system telemetry and sleep inhibitor controls.
- [x] Sidebar toggle + "hide together" behavior: sidebar and chat both dismiss when clicking the desktop or switching to another app. Genie's icon present on both the real macOS Dock and Genie's own mini dock. Full QA pass confirming every mini-dock background theme actually renders.
- [x] Apple Widgets (WidgetKit) extension architecture (`Sources/GenieWidgets/GenieWidgets.swift`) — provides `@main GenieWidgetsBundle` with Quick Chat Widget, System Status Widget, and Station Switcher Widget, plus entitlements and target registration in `Package.swift`.
- [x] Agent Tool Sandboxing Runner (`Engine/GenieSandboxedExecutionEngine.swift`) — isolated workspace directory confinement (`~/Desktop/Genie/Workspace`), safety screening of destructive shell commands, and dynamic `/usr/bin/sandbox-exec` scheme profiles wired directly into `GenieSkillsOrchestrator`.
- [x] Live Native File Browser inside FinderChat Window (`Views/FinderFileBrowserPaneView.swift`) — folder drill-down, grid/list view toggles, breadcrumbs, search filtering, open/reveal actions, item counts, and live volume available capacity status alongside chat (`ChatWindowLayoutMode.files` and `.filesOnly`).
- [x] RAM Partition Governor Engine (`Engine/GenieMemoryGovernorEngine.swift`) — 4GB default partition budget (`PrefKey.agentMemoryLimitMB`), `mach_task_basic_info` resident size tracking, `DispatchSource.makeMemoryPressureSource` real-time listening (`.normal`, `.warning`, `.critical`), thread-safe `CriticalPressureStore`, cache purge broadcasting, and POSIX `ulimit -v / ulimit -m` prefix generation.
- [x] Zero-Copy GPU Pixel Forking (`Engine/GenieHDMICaptureEngine.swift`) — Dual-channel Unified Memory GPU pixel pipeline: Channel 1 zero-latency display via `CAMetalLayer` / HDMI output, and Channel 2 neural training stream into `GenieNeuralFrameRingBuffer` with critical-pressure frame drops to guarantee zero screen lag and zero host memory burn.
- [x] Dedicated macOS Agent User & Toolchain Isolation (`Engine/GenieSandboxedExecutionEngine.swift`, `scripts/setup_genie_agent_user.sh`) — Isolated PATH precedence (`/Users/genie-agent/.local/bin`), workspace-isolated `HISTFILE` and `TMPDIR`, and automatic stripping of host credentials (`SSH_AUTH_SOCK`, `AWS_*`, `GITHUB_TOKEN`).
- [ ] Declined as literal instruction: "write Genie in the shortest amount of code possible." Not a real engineering goal for an 87k-line app — happy to target a specific area for simplification/dedup if you point at one.

## Exploratory / answered, no code yet
- 9-node spatial kernel split — recommended logical sectors under one coordinating model instead of 9 independent kernels, to avoid boundary-sync bugs. No action taken.
- In-memory virtual-DOM-style model of menu bar/dock/desktop items for smooth cross-desktop scrolling — recommended snapshot-into-structs + windowing/virtualization (materialize real views only near the viewport). No action taken; would sit on top of `SpatialPlaneManager` / `MacDesktopsManager`.
- Proportional window-content shrink (text+images scale together) — doable for Genie's own windows via render-to-layer + scale transform; **not** doable for other apps' windows without an offscreen-compositing project of its own.
