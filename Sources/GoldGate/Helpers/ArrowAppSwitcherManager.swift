import Cocoa
import SwiftUI
import ApplicationServices

// MARK: - Arrow App Switcher & Applications Overlay Manager
@MainActor
public final class ArrowAppSwitcherManager: ObservableObject {
    public static let shared = ArrowAppSwitcherManager()

    @AppStorage(PrefKey.arrowAppSwitcherEnabled) public var isEnabled: Bool = true
    @AppStorage(PrefKey.directArrowSwitchingEnabled) public var directArrowSwitching: Bool = true
    @AppStorage(PrefKey.arrowAutoDeactivateInForms) public var autoDeactivateInForms: Bool = true
    /// "Switch Desktops" (default), "Switch Apps", or "Off". Applies to bare ← / → outside text inputs.
    @AppStorage(PrefKey.bareArrowAction) public var bareArrowAction: String = "Switch Desktops"

    @Published public private(set) var isOverlayVisible: Bool = false
    @Published public private(set) var runningApps: [NSRunningApplication] = []
    @Published public var selectedIndex: Int = 0
    @Published public private(set) var lastFocusedWasInput: Bool = false
    @Published public var isTemporarilyPaused: Bool = false

    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var eventTap: CFMachPort?
    private var eventTapSource: CFRunLoopSource?
    private var lastBareArrowFire: TimeInterval = 0
    /// True when the CGEvent tap is live, so bare arrows are consumed there and not by the NSEvent monitors.
    public private(set) var isEventTapActive: Bool = false
    private var overlayWindow: NSPanel?
    private var refreshTimer: Timer?

    private init() {
        refreshRunningApps()
        startListening()
    }

    // MARK: - Smart Form Input Detection via Accessibility
    /// Returns true if the frontmost app currently has keyboard focus on a text field, text area,
    /// search bar, combo box, web input, or editable text content where arrow keys are required for cursor navigation.
    public static func isTextInputFocused() -> Bool {
        guard let front = NSWorkspace.shared.frontmostApplication else { return false }
        let myPid = ProcessInfo.processInfo.processIdentifier
        if front.processIdentifier == myPid {
            if let firstResponder = NSApp.keyWindow?.firstResponder,
               firstResponder is NSText || firstResponder is NSTextView || firstResponder is NSTextField {
                return true
            }
            return false
        }

        let appEl = AXUIElementCreateApplication(front.processIdentifier)
        var focusedElemRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(appEl, kAXFocusedUIElementAttribute as CFString, &focusedElemRef) == .success,
              let ref = focusedElemRef,
              CFGetTypeID(ref) == AXUIElementGetTypeID() else {
            return false
        }
        let el = ref as! AXUIElement

        // 1. Role verification
        var roleRef: CFTypeRef?
        AXUIElementCopyAttributeValue(el, kAXRoleAttribute as CFString, &roleRef)
        let role = (roleRef as? String) ?? ""

        if role == "AXTextField" || role == "AXTextArea" || role == "AXComboBox" || role == "AXSearchField" {
            return true
        }

        // 2. Selected Text Range check (active in editors, web inputs, chat boxes)
        var rangeRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(el, "AXSelectedTextRange" as CFString, &rangeRef) == .success {
            return true
        }

        // 3. Settable Value check
        var isSettable: DarwinBoolean = false
        if AXUIElementIsAttributeSettable(el, kAXValueAttribute as CFString, &isSettable) == .success && isSettable.boolValue {
            return true
        }

        return false
    }

    // MARK: - Running Applications List
    public func refreshRunningApps() {
        let myPid = ProcessInfo.processInfo.processIdentifier
        let apps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .regular && $0.processIdentifier != myPid && !$0.isTerminated }

        // Finder permanently anchored at index 0 matching Apple macOS dock
        var result: [NSRunningApplication] = []
        if let finder = apps.first(where: { $0.bundleIdentifier == "com.apple.finder" }) {
            result.append(finder)
        } else if let finderDirect = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.finder").first {
            result.append(finderDirect)
        }

        for app in apps {
            if app.bundleIdentifier != "com.apple.finder" && !result.contains(where: { $0.processIdentifier == app.processIdentifier }) {
                result.append(app)
            }
        }

        self.runningApps = result

        // Update selectedIndex to match frontmost app
        if let front = NSWorkspace.shared.frontmostApplication,
           let idx = result.firstIndex(where: { $0.processIdentifier == front.processIdentifier }) {
            self.selectedIndex = idx
        }
    }

    public func selectNextApp() {
        refreshRunningApps()
        guard !runningApps.isEmpty else { return }
        selectedIndex = (selectedIndex + 1) % runningApps.count
        HapticFeedback.selection()
        if !isOverlayVisible {
            activateApp(at: selectedIndex)
        }
    }

    public func selectPreviousApp() {
        refreshRunningApps()
        guard !runningApps.isEmpty else { return }
        selectedIndex = (selectedIndex - 1 + runningApps.count) % runningApps.count
        HapticFeedback.selection()
        if !isOverlayVisible {
            activateApp(at: selectedIndex)
        }
    }

    public func activateApp(at index: Int) {
        guard index >= 0 && index < runningApps.count else { return }
        let app = runningApps[index]
        SmartGridManager.shared.quickSwitchApp(pid: app.processIdentifier)
    }

    // MARK: - Applications Overlay Window Management (Disabled: No applications pop up)
    public func toggleOverlay() {
        // No applications pop up
    }

    public func showOverlay() {
        // No applications pop up
    }

    public func hideOverlay() {
        guard let panel = overlayWindow, isOverlayVisible else { return }
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.24
            ctx.timingFunction = CAMediaTimingFunction(controlPoints: 0.16, 1.0, 0.3, 1.0)
            panel.animator().alphaValue = 0.0
        }, completionHandler: { [weak self] in
            Task { @MainActor in
                panel.orderOut(nil)
                self?.isOverlayVisible = false
            }
        })
    }

    // MARK: - Global Keyboard Event Monitor
    public func startListening() {
        stopListening()

        // 1. Global Monitor (for background intercept)
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            Task { @MainActor in
                self?.handleKey(event)
            }
        }

        // 2. Local Monitor (when Genie is frontmost)
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if self?.handleKey(event) == true {
                return nil
            }
            return event
        }

        // 3. CGEvent tap: lets bare ← / → be *reserved* for desktop switching by swallowing the key
        //    before the frontmost app sees it, whenever no text field has keyboard focus.
        startEventTap()
    }

    // MARK: - Bare Arrow Event Tap (consumes ← / → outside text inputs)
    private func startEventTap() {
        stopEventTap()
        guard AXIsProcessTrusted() else { return }   // needs Accessibility; NSEvent monitors remain as fallback

        let mask = CGEventMask(1 << CGEventType.keyDown.rawValue)
        let callback: CGEventTapCallBack = { _, type, event, _ in
            if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
                Task { @MainActor in ArrowAppSwitcherManager.shared.reenableEventTap() }
                return Unmanaged.passUnretained(event)
            }
            guard type == .keyDown else { return Unmanaged.passUnretained(event) }
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            guard keyCode == 123 || keyCode == 124 else { return Unmanaged.passUnretained(event) }
            let mods: CGEventFlags = [.maskCommand, .maskControl, .maskAlternate, .maskShift, .maskSecondaryFn]
            guard event.flags.intersection(mods).isEmpty else { return Unmanaged.passUnretained(event) }

            // The tap source lives on the main run loop, so we are on the main thread here.
            let swallow = MainActor.assumeIsolated {
                ArrowAppSwitcherManager.shared.handleBareArrowFromTap(keyCode: Int(keyCode))
            }
            return swallow ? nil : Unmanaged.passUnretained(event)
        }

        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: mask,
            callback: callback,
            userInfo: nil
        ) else { return }

        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        eventTap = tap
        eventTapSource = source
        isEventTapActive = true
    }

    private func stopEventTap() {
        if let tap = eventTap { CGEvent.tapEnable(tap: tap, enable: false) }
        if let source = eventTapSource { CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .commonModes) }
        eventTap = nil
        eventTapSource = nil
        isEventTapActive = false
    }

    fileprivate func reenableEventTap() {
        if let tap = eventTap { CGEvent.tapEnable(tap: tap, enable: true) }
    }

    /// Returns true when the key was consumed (desktop or app switched).
    fileprivate func handleBareArrowFromTap(keyCode: Int) -> Bool {
        guard isEnabled, !isTemporarilyPaused, bareArrowAction != "Off" else { return false }
        if isOverlayVisible { return false }                       // overlay has its own handling in handleKey
        if UnifiedCommandWindowManager.shared.isVisible,
           NSApp.keyWindow != nil, DesktopWindowManager.isTextInputFieldActive() { return false }
        let inInput = ArrowAppSwitcherManager.isTextInputFocused()
        lastFocusedWasInput = inInput
        if inInput && autoDeactivateInForms { return false }

        // Throttle key repeat so holding the key steps through spaces at a readable pace.
        let now = CFAbsoluteTimeGetCurrent()
        guard now - lastBareArrowFire > 0.18 else { return true }
        lastBareArrowFire = now

        performBareArrow(keyCode: keyCode)
        return true
    }

    private func performBareArrow(keyCode: Int) {
        switch bareArrowAction {
        case "Switch Apps":
            keyCode == 123 ? selectPreviousApp() : selectNextApp()
        default: // "Switch Desktops"
            keyCode == 123 ? MacDesktopsManager.shared.navigatePrevious() : MacDesktopsManager.shared.navigateNext()
        }
    }

    public func stopListening() {
        if let g = globalMonitor {
            NSEvent.removeMonitor(g)
            globalMonitor = nil
        }
        if let l = localMonitor {
            NSEvent.removeMonitor(l)
            localMonitor = nil
        }
    }

    @discardableResult
    private func handleKey(_ event: NSEvent) -> Bool {
        let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        let keyCode = event.keyCode

        // ── 1. Option + Backslash (keyCode 42): Quick Deactivate / Activate Toggle ──
        if flags.contains(.option) && keyCode == 42 {
            isTemporarilyPaused.toggle()
            HapticFeedback.selection()
            return true
        }

        // ── 3. Overlay Active Handling ──
        if isOverlayVisible {
            switch keyCode {
            case 123: // Left Arrow
                selectPreviousApp()
                return true
            case 124: // Right Arrow
                selectNextApp()
                return true
            case 36, 49: // Return or Space: Activate and Close
                activateApp(at: selectedIndex)
                hideOverlay()
                return true
            case 53: // Escape: Close
                hideOverlay()
                return true
            default:
                break
            }
        }

        // ── 4. Smart Input Check for Arrow Keys & Window Snapping ──
        let inInput = ArrowAppSwitcherManager.isTextInputFocused()
        self.lastFocusedWasInput = inInput

        // If user is inside a form input / text area, NEVER intercept arrow keys or Cmd+Arrow!
        if inInput && autoDeactivateInForms {
            return false
        }

        // If temporarily paused, do not intercept
        if isTemporarilyPaused {
            return false
        }

        // ── 5. Command + Left / Right: Carry Application to Previous / Next Desktop Space ──
        if flags == .command {
            switch keyCode {
            case 123: // ⌘ + ← (Left Arrow) -> Carry App to Previous Desktop
                return SmartGridManager.shared.carryFrontmostAppToDesktop(direction: -1)
            case 124: // ⌘ + → (Right Arrow) -> Carry App to Next Desktop
                return SmartGridManager.shared.carryFrontmostAppToDesktop(direction: 1)
            default:
                break
            }
        }

        // ── 6. Control + Option + Arrows: Window Snapping (Magnet / Rectangle Standard) ──
        if flags == [.control, .option] {
            switch keyCode {
            case 123: // ⌃ + ⌥ + ← (Left Half)
                return SmartGridManager.shared.snapFrontmostWindow(direction: .left)
            case 124: // ⌃ + ⌥ + → (Right Half)
                return SmartGridManager.shared.snapFrontmostWindow(direction: .right)
            case 126: // ⌃ + ⌥ + ↑ (Maximize)
                return SmartGridManager.shared.snapFrontmostWindow(direction: .maximize)
            case 125: // ⌃ + ⌥ + ↓ (Center)
                return SmartGridManager.shared.snapFrontmostWindow(direction: .center)
            default:
                break
            }
        }

        // ── 6. Bare Arrow Keys: Switch Desktops (default) or Running Apps, when outside form inputs ──
        // When the CGEvent tap is live it already consumed these; avoid double-firing here.
        if !isEventTapActive && isEnabled && flags.isEmpty && bareArrowAction != "Off" && (keyCode == 123 || keyCode == 124) {
            performBareArrow(keyCode: Int(keyCode))
            return true
        }

        return false
    }
}
