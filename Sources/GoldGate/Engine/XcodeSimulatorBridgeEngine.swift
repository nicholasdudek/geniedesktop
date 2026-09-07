import AppKit
import Foundation
import SwiftUI

// MARK: - 📱 Simulator Device Item
public struct SimulatorDeviceInfo: Identifiable, Hashable {
    public let id: String // UDID
    public let name: String // e.g. "iPhone 16 Pro", "iPad Pro 13-inch"
    public let runtime: String // e.g. "iOS 18.0", "macOS 15.0"
    public let state: String // "Booted", "Shutdown"
    public let isAvailable: Bool

    public var isBooted: Bool { state.lowercased() == "booted" }

    public init(id: String, name: String, runtime: String, state: String, isAvailable: Bool) {
        self.id = id
        self.name = name
        self.runtime = runtime
        self.state = state
        self.isAvailable = isAvailable
    }
}

// MARK: - 🛠️ Xcode & Mac Simulator Bridge Engine
/// Bridges native Xcode project building, simctl device management, and side-by-side half-screen split workflows.
@MainActor
public final class XcodeSimulatorBridgeEngine: ObservableObject {
    public static let shared = XcodeSimulatorBridgeEngine()

    // ── Observable Telemetry ───────────────────────────────────────────────
    @Published public var isXcodeInstalled: Bool = false
    @Published public var xcodePath: String? = nil
    @Published public var availableDevices: [SimulatorDeviceInfo] = []
    @Published public var bootedDevices: [SimulatorDeviceInfo] = []
    @Published public var isBootingSimulator: Bool = false
    @Published public var statusMessage: String? = nil

    private init() {
        checkXcodeInstallation()
        refreshAvailableSimulators()
    }

    // MARK: - Xcode Installation Discovery
    public func checkXcodeInstallation() {
        let possiblePaths = [
            "/Applications/Xcode.app",
            "/Applications/Xcode-beta.app",
            "/Applications/Xcode_16.app"
        ]
        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                self.isXcodeInstalled = true
                self.xcodePath = path
                return
            }
        }
        self.isXcodeInstalled = FileManager.default.fileExists(atPath: "/usr/bin/xcodebuild")
    }

    // MARK: - Discover Simulators via xcrun simctl
    public func refreshAvailableSimulators() {
        Task.detached(priority: .userInitiated) {
            let process = Process()
            let pipe = Pipe()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
            process.arguments = ["simctl", "list", "devices", "available", "-j"]
            process.standardOutput = pipe
            process.standardError = Pipe()

            do {
                try process.run()
                process.waitUntilExit()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()

                struct SimctlOutput: Decodable {
                    let devices: [String: [SimctlDevice]]
                    struct SimctlDevice: Decodable {
                        let udid: String
                        let name: String
                        let state: String
                        let isAvailable: Bool
                    }
                }

                if let decoded = try? JSONDecoder().decode(SimctlOutput.self, from: data) {
                    var parsedList: [SimulatorDeviceInfo] = []
                    for (runtimeKey, devList) in decoded.devices {
                        let cleanRuntime = runtimeKey
                            .replacingOccurrences(of: "com.apple.CoreSimulator.SimRuntime.", with: "")
                            .replacingOccurrences(of: "-", with: " ")

                        for d in devList {
                            parsedList.append(
                                SimulatorDeviceInfo(
                                    id: d.udid,
                                    name: d.name,
                                    runtime: cleanRuntime,
                                    state: d.state,
                                    isAvailable: d.isAvailable
                                )
                            )
                        }
                    }

                    let finalList = parsedList
                    await MainActor.run {
                        self.availableDevices = finalList
                        self.bootedDevices = finalList.filter { $0.isBooted }
                    }
                }
            } catch {
                // Fallback devices catalog if simctl is offline
                await MainActor.run {
                    self.availableDevices = [
                        SimulatorDeviceInfo(id: "iphone16pro", name: "iPhone 16 Pro", runtime: "iOS 18.0", state: "Shutdown", isAvailable: true),
                        SimulatorDeviceInfo(id: "ipadpro13", name: "iPad Pro 13-inch (M4)", runtime: "iPadOS 18.0", state: "Shutdown", isAvailable: true),
                        SimulatorDeviceInfo(id: "mac_designed_for_ipad", name: "Mac (Designed for iPad)", runtime: "macOS 15.0", state: "Booted", isAvailable: true)
                    ]
                }
            }
        }
    }

    // MARK: - Boot Simulator and Snap to Half-Screen
    /// Boots the Simulator app and snaps it to the right half of the display, while pinning Xcode to the left half
    @discardableResult
    public func bootSimulator(deviceUdid: String? = nil, snapToHalf: Bool = true) async -> Bool {
        self.isBootingSimulator = true
        self.statusMessage = "Booting Simulator in Half-Screen Zoomed Mode..."
        HapticFeedback.selection()

        // 1. Boot simulator via simctl if specific UDID requested
        if let udid = deviceUdid {
            _ = await executeCommand(executable: "/usr/bin/xcrun", args: ["simctl", "boot", udid])
        }

        // 2. Open Simulator.app
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true

        let simAppURL = URL(fileURLWithPath: "/Applications/Xcode.app/Contents/Developer/Applications/Simulator.app")
        let fallbackURL = URL(fileURLWithPath: "/System/Library/CoreServices/Simulator.app")
        let targetURL = FileManager.default.fileExists(atPath: simAppURL.path) ? simAppURL : fallbackURL

        return await withCheckedContinuation { continuation in
            NSWorkspace.shared.openApplication(at: targetURL, configuration: config) { [weak self] runningApp, error in
                guard let self = self else {
                    continuation.resume(returning: false)
                    return
                }
                Task { @MainActor in
                    self.isBootingSimulator = false

                    if let app = runningApp {
                        self.statusMessage = "Simulator Active 📱"
                        if snapToHalf {
                            // Snap Simulator to Right Half (Zoomed 50% split)
                            let targetScreen = NSScreen.main ?? NSScreen.screens[0]
                            let rightHalfRect = GenieSmartTilingEngine.shared.calculateTargetFrame(for: .rightHalf, on: targetScreen)
                            AppScreenSizeTricksterEngine.shared.scheduleWindowClamping(for: app, targetRect: rightHalfRect)

                            // If Xcode is running, snap Xcode to Left Half (50% split)
                            if let xcodeApp = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == "com.apple.dt.Xcode" }) {
                                let leftHalfRect = GenieSmartTilingEngine.shared.calculateTargetFrame(for: .leftHalf, on: targetScreen)
                                AppScreenSizeTricksterEngine.shared.scheduleWindowClamping(for: xcodeApp, targetRect: leftHalfRect)
                            }
                        }
                        continuation.resume(returning: true)
                    } else {
                        // Fallback using /usr/bin/open
                        Process.launchedProcess(launchPath: "/usr/bin/open", arguments: ["-a", "Simulator"])
                        self.statusMessage = "Simulator Launched via open"
                        continuation.resume(returning: true)
                    }
                }
            }
        }
    }

    // MARK: - Launch Side-by-Side Zoomed Split (e.g. Xcode + Simulator)
    /// Launches two apps in a perfect 50/50 zoomed half-screen split
    public func launchSideBySideSplit(leftApp: String = "Xcode", rightApp: String = "Simulator") async {
        self.statusMessage = "Snapping \(leftApp) (Left 50%) & \(rightApp) (Right 50%) Side-by-Side..."

        // 1. Launch / Clamp Left App
        await AppScreenSizeTricksterEngine.shared.launchWithSpoofedScreenSize(
            appName: leftApp,
            profile: .leftHalf,
            slotIndex: 1
        )

        // 2. Launch / Clamp Right App
        if rightApp.lowercased() == "simulator" {
            await bootSimulator(snapToHalf: true)
        } else {
            await AppScreenSizeTricksterEngine.shared.launchWithSpoofedScreenSize(
                appName: rightApp,
                profile: .rightHalf,
                slotIndex: 2
            )
        }

        HapticFeedback.heavy()
    }

    // MARK: - Execute CLI Helper
    private func executeCommand(executable: String, args: [String]) async -> String {
        return await Task.detached(priority: .userInitiated) {
            let p = Process()
            let pipe = Pipe()
            p.executableURL = URL(fileURLWithPath: executable)
            p.arguments = args
            p.standardOutput = pipe
            p.standardError = pipe
            do {
                try p.run()
                p.waitUntilExit()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                return String(data: data, encoding: .utf8) ?? ""
            } catch {
                return ""
            }
        }.value
    }
}
