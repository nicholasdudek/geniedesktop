import AppKit
import Foundation
import SwiftUI
import ApplicationServices

// MARK: - 📱 Virtual Compact Screen Profiles for App Size Trickery
public enum VirtualScreenProfile: String, CaseIterable, Identifiable {
    case iphone16Pro = "iPhone 16 Pro (393×852 📱)"
    case ipadPro = "iPad Pro Studio (1024×1366 📱)"
    case appleWatch = "Apple Watch Ultra (410×502 ⌚)"
    case slot3x3 = "3×3 Matrix Desktop Slot (960×600 📐)"
    case leftHalf = "Left Half (50% Split Zoomed 🖥️)"
    case rightHalf = "Right Half (50% Split Zoomed 🖥️)"
    case topHalf = "Top Half (50% Horizontal Split 🖥️)"
    case bottomHalf = "Bottom Half (50% Horizontal Split 🖥️)"
    case ultraCompact = "Ultra-Compact Micro (960×600 🪟)"
    case compactLaptop = "Compact 720p HD (1280×720 💻)"
    case classicXGA = "Classic 4:3 (1024×768 📺)"
    case squareStudio = "Square Studio (800×800 🔲)"
    case nativeFull = "100% Native Full Screen (⚡)"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .iphone16Pro: return "iphone"
        case .ipadPro: return "ipad.landscape"
        case .appleWatch: return "applewatch"
        case .slot3x3: return "square.grid.3x3.fill"
        case .leftHalf: return "rectangle.lefthalf.filled"
        case .rightHalf: return "rectangle.righthalf.filled"
        case .topHalf: return "rectangle.tophalf.filled"
        case .bottomHalf: return "rectangle.bottomhalf.filled"
        case .ultraCompact: return "macmini.fill"
        case .compactLaptop: return "laptopcomputer"
        case .classicXGA: return "display"
        case .squareStudio: return "square"
        case .nativeFull: return "viewfinder"
        }
    }

    public var category: String {
        switch self {
        case .iphone16Pro, .ipadPro, .appleWatch: return "Mobile & Tablet"
        case .slot3x3, .ultraCompact, .squareStudio: return "Matrix Slots"
        case .leftHalf, .rightHalf, .topHalf, .bottomHalf: return "Split Screen"
        case .compactLaptop, .classicXGA, .nativeFull: return "Display Standards"
        }
    }

    public func targetDimensions(on screen: NSScreen = NSScreen.main ?? NSScreen.screens[0]) -> CGSize {
        let visible = screen.visibleFrame
        switch self {
        case .iphone16Pro:
            return CGSize(width: min(393, visible.width * 0.28), height: min(852, visible.height * 0.85))
        case .ipadPro:
            return CGSize(width: min(1024, visible.width * 0.65), height: min(768, visible.height * 0.70))
        case .appleWatch:
            return CGSize(width: min(410, visible.width * 0.25), height: min(502, visible.height * 0.50))
        case .slot3x3:
            return CGSize(width: visible.width / 3.0, height: visible.height / 3.0)
        case .leftHalf, .rightHalf:
            return CGSize(width: visible.width * 0.5, height: visible.height)
        case .topHalf, .bottomHalf:
            return CGSize(width: visible.width, height: visible.height * 0.5)
        case .ultraCompact:
            return CGSize(width: min(960, visible.width * 0.45), height: min(600, visible.height * 0.45))
        case .compactLaptop:
            return CGSize(width: min(1280, visible.width * 0.6), height: min(720, visible.height * 0.6))
        case .classicXGA:
            return CGSize(width: min(1024, visible.width * 0.5), height: min(768, visible.height * 0.55))
        case .squareStudio:
            let side = min(800, min(visible.width, visible.height) * 0.55)
            return CGSize(width: side, height: side)
        case .nativeFull:
            return CGSize(width: visible.width, height: visible.height)
        }
    }
}

// MARK: - 🎩 Application Screen Size Trickster Engine
/// Intercepts and tricks macOS applications into opening at compact/smallest virtual screen sizes,
/// enabling multiple apps (e.g. 9 in a 3×3 matrix) to load effortlessly on high-resolution desktops.
@MainActor
public final class AppScreenSizeTricksterEngine: ObservableObject {
    public static let shared = AppScreenSizeTricksterEngine()

    // ── Observable Telemetry ───────────────────────────────────────────────
    @Published public var isTricksterEnabled: Bool = true
    @Published public var defaultProfile: VirtualScreenProfile = .slot3x3
    @Published public var lastTrickedApp: String? = nil
    @Published public var lastTargetSize: CGSize = .zero
    @Published public var activeSlotAssignments: [Int: String] = [:] // Slot (1-9) -> App Name

    private var launchObserver: NSObjectProtocol? = nil

    private init() {
        setupLaunchInterception()
    }

    deinit {
        if let obs = launchObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(obs)
        }
    }

    // MARK: - Automatic Launch Interception Setup
    private func setupLaunchInterception() {
        launchObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didLaunchApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] note in
            Task { @MainActor in
                guard let self = self, self.isTricksterEnabled else { return }
                guard let app = note.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
                guard let bundleId = app.bundleIdentifier, bundleId != Bundle.main.bundleIdentifier else { return }

                let prof = self.defaultProfile
                // Trick newly launched application into compact screen size
                self.scheduleWindowClamping(for: app, profile: prof)
            }
        }
    }

    // MARK: - Launch App with Virtual Screen Size Trickery
    /// Opens an application with spoofed startup parameters and immediate window size clamping
    @discardableResult
    public func launchWithSpoofedScreenSize(
        appName: String,
        profile: VirtualScreenProfile = .slot3x3,
        slotIndex: Int? = nil
    ) async -> Bool {
        guard let appURL = resolveAppURL(named: appName) else {
            return false
        }

        let targetScreen = NSScreen.main ?? NSScreen.screens[0]
        let targetSize = profile.targetDimensions(on: targetScreen)
        let slot = slotIndex ?? findNextAvailableSlot()

        let origin = calculateSlotOrigin(slot: slot, size: targetSize, on: targetScreen)

        // 1. Configure Cocoa Startup Flags to prevent restoring gigantic windows
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        config.createsNewApplicationInstance = false

        // Injects macOS Cocoa frame preferences directly on launch
        let frameString = "\(Int(origin.x)) \(Int(origin.y)) \(Int(targetSize.width)) \(Int(targetSize.height)) 0 0 \(Int(targetScreen.frame.width)) \(Int(targetScreen.frame.height))"
        config.arguments = [
            "-ApplePersistenceIgnoreState", "YES",
            "-NSWindowFrame", frameString
        ]

        self.lastTrickedApp = appName
        self.lastTargetSize = targetSize
        self.activeSlotAssignments[slot] = appName

        HapticFeedback.selection()

        return await withCheckedContinuation { continuation in
            NSWorkspace.shared.openApplication(at: appURL, configuration: config) { [weak self] runningApp, error in
                guard let self = self, let app = runningApp, error == nil else {
                    continuation.resume(returning: false)
                    return
                }

                Task { @MainActor in
                    // Schedule progressive accessibility clamping to ensure window stays compact
                    self.scheduleWindowClamping(for: app, targetRect: CGRect(origin: origin, size: targetSize))
                }
                continuation.resume(returning: true)
            }
        }
    }

    // MARK: - Progressive AXUIElement Window Clamping
    /// Retries AXUIElement window sizing across startup animation frames (0ms, 150ms, 400ms, 800ms)
    public func scheduleWindowClamping(for app: NSRunningApplication, profile: VirtualScreenProfile) {
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let targetSize = profile.targetDimensions(on: screen)
        let slot = findNextAvailableSlot()
        let origin = calculateSlotOrigin(slot: slot, size: targetSize, on: screen)
        let targetRect = CGRect(origin: origin, size: targetSize)
        scheduleWindowClamping(for: app, targetRect: targetRect)
    }

    public func scheduleWindowClamping(for app: NSRunningApplication, targetRect: CGRect) {
        let pid = app.processIdentifier
        let intervals = [0.1, 0.25, 0.5, 0.9, 1.4]

        for delay in intervals {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                self?.clampWindow(pid: pid, targetRect: targetRect)
            }
        }
    }

    /// Surgically sets window frame using macOS Accessibility API
    @discardableResult
    public func clampWindow(pid: pid_t, targetRect: CGRect) -> Bool {
        let appRef = AXUIElementCreateApplication(pid)
        var windowValue: AnyObject?
        let result = AXUIElementCopyAttributeValue(appRef, kAXFocusedWindowAttribute as CFString, &windowValue)

        var targetWindow: AXUIElement?
        if result == .success, let val = windowValue, CFGetTypeID(val) == AXUIElementGetTypeID() {
            targetWindow = (val as! AXUIElement)
        } else {
            // Fallback: search windows list
            var windowsValue: AnyObject?
            if AXUIElementCopyAttributeValue(appRef, kAXWindowsAttribute as CFString, &windowsValue) == .success,
               let winList = windowsValue as? [AXUIElement], let first = winList.first {
                targetWindow = first
            }
        }

        guard let windowElement = targetWindow else { return false }

        // Convert origin to AX coordinates (top-left is (0,0))
        var origin = targetRect.origin
        if let primaryScreen = NSScreen.screens.first {
            origin.y = primaryScreen.frame.height - (targetRect.origin.y + targetRect.height)
        }

        var size = targetRect.size
        if let posVal = AXValueCreate(.cgPoint, &origin),
           let sizeVal = AXValueCreate(.cgSize, &size) {
            AXUIElementSetAttributeValue(windowElement, kAXPositionAttribute as CFString, posVal)
            AXUIElementSetAttributeValue(windowElement, kAXSizeAttribute as CFString, sizeVal)
            return true
        }

        return false
    }

    // MARK: - Slot & Grid Calculations
    public func calculateSlotOrigin(slot: Int, size: CGSize, on screen: NSScreen) -> CGPoint {
        let visible = screen.visibleFrame
        let col = (slot - 1) % 3
        let row = (slot - 1) / 3 // 0 = top, 1 = mid, 2 = bot

        let slotWidth = visible.width / 3.0
        let slotHeight = visible.height / 3.0

        let x = visible.origin.x + CGFloat(col) * slotWidth + (slotWidth - size.width) * 0.5
        let y = visible.origin.y + CGFloat(2 - row) * slotHeight + (slotHeight - size.height) * 0.5

        return CGPoint(x: max(visible.origin.x, x), y: max(visible.origin.y, y))
    }

    public func findNextAvailableSlot() -> Int {
        for slot in 1...9 {
            if activeSlotAssignments[slot] == nil {
                return slot
            }
        }
        return 1
    }

    public func clearSlotAssignments() {
        activeSlotAssignments.removeAll()
    }

    // MARK: - Clamp Frontmost Active Application to Selected Profile
    @discardableResult
    public func clampFrontmostApplication(to profile: VirtualScreenProfile) -> Bool {
        guard let frontApp = NSWorkspace.shared.runningApplications.first(where: { $0.isActive && $0.bundleIdentifier != Bundle.main.bundleIdentifier }) ?? NSWorkspace.shared.frontmostApplication,
              frontApp.bundleIdentifier != Bundle.main.bundleIdentifier else {
            return false
        }
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let targetSize = profile.targetDimensions(on: screen)
        let origin = CGPoint(
            x: screen.visibleFrame.origin.x + (screen.visibleFrame.width - targetSize.width) * 0.5,
            y: screen.visibleFrame.origin.y + (screen.visibleFrame.height - targetSize.height) * 0.5
        )
        let rect = CGRect(origin: origin, size: targetSize)
        self.lastTrickedApp = frontApp.localizedName ?? "Frontmost App"
        self.lastTargetSize = targetSize
        scheduleWindowClamping(for: frontApp, targetRect: rect)
        HapticFeedback.success()
        return true
    }

    // MARK: - Side-by-Side 50/50 Zoomed Split Workflow
    /// Launches two apps snapped side-by-side in a zoomed 50/50 split (e.g. Xcode Left + Simulator Right)
    public func launchSideBySidePair(leftApp: String, rightApp: String) async {
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let leftRect = CGRect(x: screen.visibleFrame.origin.x, y: screen.visibleFrame.origin.y, width: screen.visibleFrame.width * 0.5, height: screen.visibleFrame.height)
        let rightRect = CGRect(x: screen.visibleFrame.origin.x + screen.visibleFrame.width * 0.5, y: screen.visibleFrame.origin.y, width: screen.visibleFrame.width * 0.5, height: screen.visibleFrame.height)

        if let leftURL = resolveAppURL(named: leftApp) {
            let config = NSWorkspace.OpenConfiguration()
            config.activates = true
            NSWorkspace.shared.openApplication(at: leftURL, configuration: config) { [weak self] app, _ in
                if let app = app {
                    Task { @MainActor in
                        self?.scheduleWindowClamping(for: app, targetRect: leftRect)
                    }
                }
            }
        }

        if let rightURL = resolveAppURL(named: rightApp) {
            let config = NSWorkspace.OpenConfiguration()
            config.activates = true
            NSWorkspace.shared.openApplication(at: rightURL, configuration: config) { [weak self] app, _ in
                if let app = app {
                    Task { @MainActor in
                        self?.scheduleWindowClamping(for: app, targetRect: rightRect)
                    }
                }
            }
        }

        HapticFeedback.heavy()
    }

    // MARK: - App URL Resolution
    private func resolveAppURL(named appName: String) -> URL? {
        if let u = NSWorkspace.shared.urlForApplication(withBundleIdentifier: appName) { return u }
        let searchPaths = [
            "/Applications/\(appName).app",
            "/System/Applications/\(appName).app",
            "/System/Applications/Utilities/\(appName).app",
            "/Applications/\(appName.capitalized).app"
        ]
        for path in searchPaths {
            if FileManager.default.fileExists(atPath: path) { return URL(fileURLWithPath: path) }
        }
        return nil
    }
}
