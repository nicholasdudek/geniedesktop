# Changelog — Genie for macOS

All notable changes to Genie are documented in this file.  
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [1.0.0] — Build 13 — September 2026

### Added
- **Finder-Style Chat & Multi-Tab Workspace** — Authentic macOS Finder-style floating/expandable window (`FinderChatWindowManager`, `FinderStyleChatWindowView`) with integrated Safari/Xcode-style tab bar (`WorkspaceTabManager`). Supports Claude & Gemma active chat, GitHub Studio, AI Creations, Saved Notes, Mini Browser, Terminal Shell, and Genie Settings.
- **One-Button Window Expansion (`^`)** — Custom spring-animated window toggle seamlessly expanding the Finder Chat window to fill the visible screen and restoring back to compact geometry.
- **Deep Reasoning & Chain-of-Thought Accordion (`GenieThinkingAccordionView`)** — Collapsible UI rendering model reasoning with pulsing glowing gradients, live streaming elapsed seconds counter, and monospaced syntax rendering.
- **Desktop Sticky Notes & Multi-Slide Presentation Canvas (`DesktopStickyNotesCanvas`)** — Draggable, foldable sticky notes with Polaroid photo upload support, multi-slide markdown presentations (`\n---\n`), and per-app binding.
- **22 pt Liquid Glass Mini Dock & SkyLight Hardware Spaces Engine** — World's smallest fully-featured dock with 14.5 pt Retina icons, spring magnification wave, and sub-millisecond virtual space creation and switching via private SkyLight WindowServer framework bindings (`SLSMainConnectionID`, `SLSSpaceCreate`, `SLSManagedDisplaySetCurrentSpace`).
- **StoreKit 2 Expansion Store Integration** — Standardized `ExpansionPackItem` model and unified store presentation across MenuBar dropdown views and settings.

### Fixed
- **Type Reference Alignment** — Resolved `ExpansionPack` to `ExpansionPackItem` type scoping in `MenuBarDropdownView`.
- **Python Syntax Cleanliness** — Eliminated escape warnings in automation scripts using raw string literals.

---

## [1.0.0] — Build 12 — September 2026

### Added
- **Configurable Spatial Trajectories** — 5 dynamic entrance motions: Slide from Right (iPhone Mode 📱), Pull Up from Bottom, Slide from Left (Sidebar ⬅️), Drop Down from Top (Menu Bar ⬇️), and Spatial Zoom from Center (Holographic ✨).
- **Multi-Modal Hot Corners & Edge Triggers** — Bottom-right quick note corner, top-right trigger, right screen edge bump, and double-tap `Control` / `Option` modifier shortcuts.
- **Smart App Shielding** — Intelligent frontmost window detection dropping background scroll interception whenever third-party productivity applications (Xcode, Safari, Slack, VS Code) are focused.
- **3-Way Adaptive Appearance System** — Dynamic cycling between `Auto 💻` (system appearance sync), `Light ☀️`, and `Dark 🌙` across both native application and marketing surfaces.

---

## [1.0.0] — Build 11 — September 2026

### Added
- **Sliding Edge Chat Dock (`RightSideChatDockView`)** — Edge-docked sliding drawer supporting trailing or leading screen placement, drag-to-dismiss gesture physics, and voice dialect picker.
- **Voice Engine Multi-Dialect Synthesizer (`GenieVoiceEngine`)** — Real-time speech synthesis supporting Samantha, Daniel, Flo, and localized accents.

---

## [1.0.0] — Build 10 — September 2026

### Fixed
- **Multi-Monitor Usable Rect Dynamic Reconfiguration** — Seamless canvas repositioning and usable display rect recalculation during display connect/disconnect and resolution switching.

---

## [1.0.0] — Build 9 — September 2026

### Added
- **High-Fidelity Mechanical Switch Audio Synthesis** — Low-latency PCM audio synthesis for app launches and keyboard clicks.
- **Memory Pooling & Resource Throttling** — Reduced idle footprint to <35 MB RAM with zero GPU waste when canvas is retracted.

---

## [1.0.0] — Build 8 — September 2026

### Added
- **Global Light / Dark Mode & Theme Selector** — Added quick-toggle button in the Studio Hub top bar and dedicated Studio Appearance & Theme picker in General Settings.
- **Global Language Selector** — Added multi-language selector button in the Studio Hub top bar with native flags, native greetings, checkmarks, and instant switching across 10 world languages with RTL layout support.

### Changed
- **Compact Studio Hub Geometry** — Redesigned the Studio Hub window to a sleek, compact 660×480 pt footprint. Reduced sidebar width to 138 pt and optimized row spacing and icon sizing (21×21 pt) so all 12 navigation tabs fit in ~340 pt height with zero vertical scrolling.

---

## [1.0.0] — Build 7 — September 2026

### Fixed
- **Menu bar responsiveness** — The macOS system menu bar (Apple menu, app menus, status items) was intermittently unresponsive or unclickable while Genie was running. Root cause: three compounding issues in window management.
  - `DesktopPlaneWindow` was sized to `screen.frame` (full physical display), covering the 33px menu bar strip. Fixed by constraining the frame to `screen.visibleFrame` height via `calculateUsableRect(for:)`.
  - `DesktopPlaneWindow.canBecomeKey` returned `true`, allowing the canvas to capture key focus from system menus. Fixed by returning `false`.
  - `MenuBarPopoverPanel` was assigned `NSWindow.Level(popUpMenuWindow + 20)` (level 121), above the native macOS menu bar (level 24). Fixed by using `.statusBar` (level 25).
- **System menu shortcuts** — ⌘Q, ⌘H, ⌘Tab and other system shortcuts were inoperative when Genie was the only running application, because no `NSApp.mainMenu` was provisioned. Fixed by calling `setupMainMenu()` in `applicationDidFinishLaunching`.
- **Popover dismiss-on-click** — The outside-click dismissal guard (`guard !self.isStudioAlwaysOnTop else { return }`) prevented the popover from ever dismissing via outside click when Always-On-Top was enabled (the default). Guard removed; dismissal now always works when clicking outside the panel.

### Changed
- `DesktopPlaneWindow` initialiser now calculates usable rect via `calculateUsableRect(for:)` static method.
- `rebuildWindows(appModel:)` uses `calculateUsableRect(for:)` for consistent frame sizing.
- Page navigation (`NexusDesktopPageChanged`) no longer calls `NSApp.activate(ignoringOtherApps:)` or `makeKeyAndOrderFront(_:)` on desktop windows.
- Top screen-edge cursor trigger (`NexusTopEdgeHit`) is now opt-in via `nexus.topEdgeCursorTrigger` (default: off) to prevent accidental desktop dismissal when moving the cursor toward the menu bar.

---

## [1.0.0] — Build 6 — September 2026

### Fixed
- Missing `Assets.car` in the app bundle caused visual asset loading failures. Asset catalogue compilation now runs via `actool` in `package_for_app_store.sh`.
- Provisioning profile embedding step added to build script.

### Added
- Full Retina AppIcon.icns (1024×1024 px) included in bundle.

---

## [1.0.0] — Builds 1–5 — August–September 2026

Initial development and App Store submission builds. Core feature set established:

- Desktop canvas with two-page navigation
- Menu Bar Studio with 11 configuration tabs
- 52+ icon themes
- 28+ geometric formations
- 40+ menu bar glyphs, 22+ battery styles
- Metal shader effects
- Living desktop companions
- StoreKit 2 expansion packs (4 packs + VIP All-Access)
- Launch at Login via `SMAppService`
- 10-language localisation
- App Sandbox compliance
- Universal Binary (Apple Silicon + Intel)
