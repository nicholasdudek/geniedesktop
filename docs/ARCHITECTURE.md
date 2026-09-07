# Architecture — Genie for macOS

This document provides a technical deep-dive into the engineering decisions, subsystem design, and macOS API usage that underpin Genie.

---

## Application Lifecycle

Genie is a `LSUIElement` application (no Dock icon, no standard application menu). The entry point is `GoldGateAppMain.swift`, which uses the `@main` attribute to bootstrap `AppDelegate` as the application delegate.

```swift
@main
struct GoldGateAppMain: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene { Settings {} }
}
```

`AppDelegate` is the central coordinator. On launch it:

1. Calls `setupMainMenu()` to provision `NSApp.mainMenu` — ensuring ⌘Q, ⌘H, and all system shortcuts remain responsive even when Genie is the only running application.
2. Creates `MenuBarPopoverPanel`, an `NSPanel` subclass configured with `.nonactivatingPanel`.
3. Boots `DesktopWindowManager.shared`, which spawns one `DesktopPlaneWindow` per connected display.
4. Creates the `NSStatusItem` and starts the glyph animation timer.
5. Sets up global event monitors for outside-click dismissal.

---

## Window Hierarchy & Level Strategy

macOS assigns every window a `CGWindowLevel` integer. Incorrect level choices cause the two most critical Genie failure modes: covering the system menu bar, or stealing key focus from it.

| Window | Level | Constant |
|---|---|---|
| macOS Menu Bar | 24 | `NSWindow.Level.mainMenu` |
| `MenuBarPopoverPanel` | 25 | `NSWindow.Level.statusBar` |
| `DesktopPlaneWindow` (active) | 3 | `NSWindow.Level.floating` |
| `DesktopPlaneWindow` (dismissed) | −2 | `desktopIconWindow − 1` |

**Why `.statusBar` for the popover?**  
Using `popUpMenuWindow + 20` (level 121) — the original implementation — placed the panel above every native macOS menu. Clicking any menu bar item (Terminal, Apple menu, Wi-Fi) would route mouse events to Genie's transparent window layer first, blocking system menus. `.statusBar` (level 25) places the panel above the menu bar strip cosmetically, while still allowing native menus to open on top.

**Why `canBecomeKey = false` on `DesktopPlaneWindow`?**  
When a floating window can become key, macOS may route keyboard events and first-responder focus to it in preference to the frontmost application. Setting `canBecomeKey = false` ensures the desktop canvas is purely visual — it receives mouse events but never competes for key input focus.

---

## Menu Bar Popover Panel

```
MenuBarPopoverPanel : NSPanel
├── styleMask: [.borderless, .resizable, .nonactivatingPanel]
├── level: .statusBar
├── collectionBehavior: [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
├── hidesOnDeactivate: false
├── canBecomeKey: true        ← popover can receive keyboard input
└── NexusHostingView<MenuBarDropdownView>
```

`.nonactivatingPanel` is the critical flag. It prevents the panel from triggering an application activation event when it appears. Without it, every time the popover opens, Genie would momentarily become the frontmost application, interrupting the user's active application and causing the system menu bar to switch to Genie's (empty) menu.

`windowDidMove` and `windowDidEndLiveResize` delegate methods persist the panel's position and size to `UserDefaults` so it reappears at the same location on next launch.

---

## Desktop Plane Window

```
DesktopPlaneWindow : NSWindow
├── styleMask: [.borderless, .fullSizeContentView]
├── frame: DesktopPlaneWindow.calculateUsableRect(for: screen)
│         = screen.frame minus menu bar height
├── level: .floating (active) | desktopIconWindow−1 (dismissed)
├── collectionBehavior: [.canJoinAllSpaces, .stationary, .ignoresCycle]
├── canBecomeKey: false       ← never steals system menu focus
├── canBecomeMain: false
└── NexusHostingView<DesktopGridView>
```

### Frame Calculation

```swift
static func calculateUsableRect(for screen: NSScreen) -> NSRect {
    let topBarHeight = max(24.0, screen.frame.maxY - screen.visibleFrame.maxY)
    return NSRect(
        x: screen.frame.minX,
        y: screen.frame.minY,
        width: screen.frame.width,
        height: screen.frame.height - topBarHeight
    )
}
```

`screen.frame` is the full physical pixel rectangle of the display. `screen.visibleFrame` excludes the Dock and menu bar. The difference `screen.frame.maxY − screen.visibleFrame.maxY` gives the exact height of the menu bar strip. The desktop window is constrained to this usable height, guaranteeing it never covers menu bar pixels and never intercepts cursor events in that zone.

### Page Navigation & Level Management

`DesktopGridView` posts `NexusDesktopPageChanged` with an integer page index (0 or 1). `DesktopWindowManager` observes this and adjusts window levels accordingly:

- **Page 1 (active):** `win.level = .floating`. The canvas sits above all application windows. `ignoresMouseEvents = false`.
- **Page 0 (dismissed):** `win.level = NSWindow.Level(desktopIconWindow − 1)`. The canvas sinks below Finder's desktop icon layer. `ignoresMouseEvents = true`. Finder regains full native interactivity.

---

## Event Pipeline

### Global Event Monitors

```
NSEvent.addGlobalMonitorForEvents([.leftMouseDown, .rightMouseDown])
  └── Task @MainActor
      └── if popover visible && click outside popover && click outside status button
          └── dismissMenuBarPopover()
```

Global monitors receive events from other applications. The dismiss logic checks both the panel frame and the status item button frame before dismissing, preventing a race condition where clicking the status button would dismiss and immediately re-open the panel.

### Cursor Polling Timer

A `Timer` fires every 40ms (25 Hz) to poll `NSEvent.mouseLocation` for edge-trigger zones:

- **Bottom-centre zone** — cursor held within 8pt of `screen.visibleFrame.minY` for a configurable rest period (default 400ms) triggers `NexusBottomEdgeHit`, summoning the app matrix.
- **Top-centre zone** — cursor at `screen.frame.maxY − 10` triggers `NexusTopEdgeHit` (opt-in, disabled by default via `nexus.topEdgeCursorTrigger`) to dismiss.

The horizontal guard (`isHorizontallyCentered`) restricts triggers to the central 88% of the display width, strictly excluding hot corners to prevent Genie from interfering with Mission Control, Launchpad, and other corner-bound macOS features.

### Local & Global Scroll Monitors

```
NSEvent.addGlobalMonitorForEvents([.scrollWheel])
  └── if cursor over empty desktop (not over any app window at layer 0)
      └── post NexusDesktopScrollWheel
```

`isOverDesktopOrEmptySpace()` queries `CGWindowListCopyWindowInfo` and checks whether the mouse location falls within any layer-0 application window. This prevents Genie from intercepting scroll events while the user is scrolling inside another application's window.

---

## Application Catalogue (AppModel)

`AppModel.load()` is `async` and runs off the main actor. It builds the application list from three sources:

1. **`/Applications`** and subdirectories — enumerated with `FileManager`.
2. **Spotlight** — `mdfind "kMDItemContentType == 'com.apple.application-bundle'"` for user-installed apps outside `/Applications`.
3. **Running applications** — `NSWorkspace.shared.runningApplications.filter { $0.activationPolicy == .regular }` ensures apps open from unusual locations appear.

Results are deduplicated by `bundleIdentifier`, filtered by user-configured hidden list, and sorted by the custom order stored in `UserDefaults`.

Icon resolution uses a priority chain:
1. `NSWorkspace.icon(forFile:)` at 1024×1024 for full Retina quality
2. `NSBundle.image(forResource:)` fallback
3. Generic `NSImage(named: NSImage.applicationIconName)` fallback

---

## Battery Monitor

`BatteryMonitor` uses `IOKit` to read `kIOPSCurrentCapacityKey`, `kIOPSMaxCapacityKey`, and `kIOPSPowerSourceStateKey` from `IOPSCopyPowerSourcesInfo()`. A `CFRunLoopSource` registered via `IOPSNotificationCreateRunLoopSource` triggers updates on battery state changes without polling.

---

## StoreKit 2 IAP

`ExpansionStoreManager` uses the StoreKit 2 `async/await` API:

```swift
let products = try await Product.products(for: [productID])
let result = try await product.purchase()
```

`Transaction.currentEntitlements` is iterated on restore. All transactions are finished immediately after verification. Entitlements are persisted to `UserDefaults` as a string array (`nexus.unlockedPacks`) and checked on every feature gate.

During App Review, App Store Connect creates a sandbox environment. When no product is returned by `Product.products(for:)` (e.g. products not yet approved), the manager falls back to a local unlock for development testing only.

---

## Notification Architecture

Genie uses three notification channels:

| Channel | Usage |
|---|---|
| `NotificationCenter.default` | Internal inter-module communication |
| `DistributedNotificationCenter.default()` | External triggers from Terminal scripts or CLI tools |
| `NSWorkspace.shared.notificationCenter` | macOS workspace events (app launches, screen changes) |

Key internal notifications:

| Name | Direction | Purpose |
|---|---|---|
| `NexusDesktopPageChanged` | Grid → Manager | Page transition, window level update |
| `NexusBottomEdgeHit` | Manager → Grid | Summon app matrix |
| `NexusTopEdgeHit` | Manager → Grid | Dismiss app matrix |
| `NexusToggleDesktopGrid` | Any → Grid | Dock icon click, double-click, keyboard |
| `NexusRefreshApps` | Studio → Model | Reload application catalogue |
| `NexusClose` | Studio → Delegate | Close popover |

---

## Localisation

`LocalizedStrings.swift` provides a type-safe wrapper over `NSLocalizedString`. String tables are stored in `Localizable.strings` files per locale. Runtime locale detection uses `Locale.current.language.languageCode`.

Supported: `en`, `es`, `fr`, `de`, `ja`, `zh-Hans`, `it`, `ko`, `pt-BR`, `ar`.

---

## Entitlements

```xml
<key>com.apple.security.app-sandbox</key><true/>
<key>com.apple.security.files.user-selected.read-only</key><true/>
```

No network entitlements. No file write entitlements outside the sandbox container. macOS enforces this at the kernel level.
