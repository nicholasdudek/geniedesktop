import AppKit
import SwiftUI
import UserNotifications

// MARK: - Centralized macOS Permissions & Security Manager

@MainActor
public final class PermissionsManager: ObservableObject {
    public static let shared = PermissionsManager()

    @Published public var isAccessibilityGranted: Bool = false
    @Published public var isScreenCaptureGranted: Bool = false
    @Published public var isFullDiskGranted: Bool = false
    @Published public var isNotificationsGranted: Bool = false

    private init() {
        refreshAll()
    }

    public func refreshAll() {
        // 1. Accessibility
        isAccessibilityGranted = AXIsProcessTrusted()

        // 2. Screen Recording (Window Mirroring & Atmosphere)
        isScreenCaptureGranted = CGPreflightScreenCaptureAccess()

        // 3. Files & Folders (Test read permission to Desktop/Home)
        let desktopPath = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first?.path ?? (NSHomeDirectory() + "/Desktop")
        isFullDiskGranted = FileManager.default.isReadableFile(atPath: desktopPath)

        // 4. Notifications (Safely check bundleIdentifier to prevent crash in unbundled CLI execution)
        if Bundle.main.bundleIdentifier != nil {
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                Task { @MainActor in
                    self.isNotificationsGranted = (settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional)
                }
            }
        } else {
            self.isNotificationsGranted = true
        }

        // Once core permissions are granted, permanently remember initial setup is done
        if isAccessibilityGranted && isScreenCaptureGranted {
            UserDefaults.standard.set(true, forKey: PrefKey.hasCompletedInitialSetup)
            UserDefaults.standard.set(true, forKey: PrefKey.permissionsAskedAtLogin)
        }
    }

    // MARK: - Permission Request Actions

    public func requestAccessibility() {
        if AXIsProcessTrusted() {
            isAccessibilityGranted = true
            return
        }

        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)

        // If still not granted, open macOS System Settings directly
        if !AXIsProcessTrusted() {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
                NSWorkspace.shared.open(url)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.refreshAll()
        }
    }

    public func requestScreenCapture() {
        if CGPreflightScreenCaptureAccess() {
            isScreenCaptureGranted = true
            return
        }

        _ = CGRequestScreenCaptureAccess()
        if !CGPreflightScreenCaptureAccess() {
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture") {
                NSWorkspace.shared.open(url)
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.refreshAll()
        }
    }

    public func requestFullDiskAccess() {
        if isFullDiskGranted { return }
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
            NSWorkspace.shared.open(url)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.refreshAll()
        }
    }

    public func requestNotifications() {
        guard Bundle.main.bundleIdentifier != nil else {
            self.isNotificationsGranted = true
            return
        }
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            Task { @MainActor in
                self.isNotificationsGranted = granted
                if !granted {
                    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
    }

    /// Request all critical permissions sequentially
    public func requestAllPermissions() {
        if !isAccessibilityGranted {
            requestAccessibility()
        }
        if !isScreenCaptureGranted {
            requestScreenCapture()
        }
        if !isNotificationsGranted {
            requestNotifications()
        }
        if !isFullDiskGranted {
            requestFullDiskAccess()
        }
        if isAccessibilityGranted && isScreenCaptureGranted {
            UserDefaults.standard.set(true, forKey: PrefKey.hasCompletedInitialSetup)
            UserDefaults.standard.set(true, forKey: PrefKey.permissionsAskedAtLogin)
        }
    }

    /// Silently refreshes permission status without prompting or opening System Settings
    public func checkAndPromptAllOnLaunch() {
        refreshAll()
    }
}
