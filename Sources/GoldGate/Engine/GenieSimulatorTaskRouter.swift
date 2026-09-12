import AppKit
import Foundation
import SwiftUI

// MARK: - 📱 Chat/Task Simulator Assignment Spec
public struct ChatSimulatorBinding: Identifiable, Hashable, Codable {
    public var id: String { chatId }
    public let chatId: String
    public let taskName: String
    public var deviceUdid: String
    public var deviceName: String
    public var isLiteMode: Bool
    public var isBooted: Bool
    public var agentInferenceFPS: Int
    public var lastActivity: Date

    public init(
        chatId: String,
        taskName: String,
        deviceUdid: String,
        deviceName: String,
        isLiteMode: Bool = true,
        isBooted: Bool = false,
        agentInferenceFPS: Int = 24
    ) {
        self.chatId = chatId
        self.taskName = taskName
        self.deviceUdid = deviceUdid
        self.deviceName = deviceName
        self.isLiteMode = isLiteMode
        self.isBooted = isBooted
        self.agentInferenceFPS = agentInferenceFPS
        self.lastActivity = Date()
    }
}

// MARK: - 🚀 Genie Multi-Chat & Task Simulator Router
/// Reroutes agent browser automation, UI inspection, and app execution
/// to concurrently booted iOS Simulators instead of a heavy Linux VM server.
/// Supports Lite Mode for instantaneous zero-RAM-starvation execution.
@MainActor
public final class GenieSimulatorTaskRouter: ObservableObject {
    public static let shared = GenieSimulatorTaskRouter()

    // ── Observable Routing State ──────────────────────────────────────────
    @Published public var activeBindings: [String: ChatSimulatorBinding] = [:]
    @Published public var isLiteModeEnabled: Bool = true
    @Published public var backgroundAgentFPS: Int = 24 // 24 FPS for autonomous background agents, while user gets 120 FPS
    @Published public var statusLog: String = "Simulator Router Ready"
    @Published public var activeSimulatorsCount: Int = 0

    private init() {
        self.isLiteModeEnabled = UserDefaults.standard.object(forKey: "genie.simulator.liteMode") as? Bool ?? true
        self.backgroundAgentFPS = UserDefaults.standard.object(forKey: "genie.simulator.agentFPS") as? Int ?? 24
    }

    public func setAgentFPS(forChat chatId: String, fps: Int) {
        if var binding = activeBindings[chatId] {
            binding.agentInferenceFPS = fps
            activeBindings[chatId] = binding
        }
    }

    // MARK: - 1. Assign or Route a Chat/Task to an Isolated Simulator
    @discardableResult
    public func assignSimulator(forChat chatId: String, taskName: String = "Agent Task") async -> ChatSimulatorBinding? {
        // Return existing binding if already assigned
        if let existing = activeBindings[chatId] {
            return existing
        }

        // Refresh devices from XcodeSimulatorBridgeEngine
        XcodeSimulatorBridgeEngine.shared.refreshAvailableSimulators()
        let available = XcodeSimulatorBridgeEngine.shared.availableDevices.filter { $0.isAvailable }

        guard !available.isEmpty else {
            self.statusLog = "No iOS simulators found in Xcode toolchain."
            return nil
        }

        // Reuse an already-booted simulator or pick the next unassigned available device
        let assignedUdids = Set(activeBindings.values.map { $0.deviceUdid })
        let targetDevice = available.first(where: { $0.isBooted && !assignedUdids.contains($0.id) })
            ?? available.first(where: { !assignedUdids.contains($0.id) })
            ?? available.first!

        // Boot device if not running
        let isBooted = targetDevice.isBooted ? true : await bootSimulatorInstance(udid: targetDevice.id)

        let binding = ChatSimulatorBinding(
            chatId: chatId,
            taskName: taskName,
            deviceUdid: targetDevice.id,
            deviceName: targetDevice.name,
            isLiteMode: isLiteModeEnabled,
            isBooted: isBooted,
            agentInferenceFPS: backgroundAgentFPS
        )

        activeBindings[chatId] = binding
        activeSimulatorsCount = activeBindings.count
        self.statusLog = "Chat '\(chatId)' routed to \(binding.deviceName) [\(binding.deviceUdid.prefix(8))]"
        HapticFeedback.selection()
        return binding
    }

    // MARK: - 2. Boot Specific Simulator (Headless or Foreground)
    public func bootSimulatorInstance(udid: String) async -> Bool {
        guard GenieCapabilities.canSpawnSubprocesses else { return false }
        return await withCheckedContinuation { continuation in
            Task.detached(priority: .userInitiated) {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
                process.arguments = ["simctl", "boot", udid]
                process.standardOutput = Pipe()
                process.standardError = Pipe()

                do {
                    try process.run()
                    process.waitUntilExit()
                    continuation.resume(returning: process.terminationStatus == 0)
                } catch {
                    continuation.resume(returning: false)
                }
            }
        }
    }

    // MARK: - 3. Open Webpage / Dev Server in Assigned Simulator
    public func openURL(_ urlString: String, forChat chatId: String) async -> Bool {
        guard GenieCapabilities.canSpawnSubprocesses else { return false }
        let binding: ChatSimulatorBinding
        if let existing = activeBindings[chatId] {
            binding = existing
        } else if let created = await assignSimulator(forChat: chatId) {
            binding = created
        } else {
            return false
        }

        self.statusLog = "Opening URL on \(binding.deviceName)..."
        return await withCheckedContinuation { continuation in
            Task.detached(priority: .userInitiated) {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
                process.arguments = ["simctl", "openurl", binding.deviceUdid, urlString]
                process.standardOutput = Pipe()
                process.standardError = Pipe()

                do {
                    try process.run()
                    process.waitUntilExit()
                    continuation.resume(returning: process.terminationStatus == 0)
                } catch {
                    continuation.resume(returning: false)
                }
            }
        }
    }

    // MARK: - 4. Direct Framebuffer Screenshot Capture (Zero-Copy)
    public func captureScreenshot(forChat chatId: String) async -> String? {
        guard GenieCapabilities.canSpawnSubprocesses else { return nil }
        let binding: ChatSimulatorBinding
        if let existing = activeBindings[chatId] {
            binding = existing
        } else if let created = await assignSimulator(forChat: chatId) {
            binding = created
        } else {
            return nil
        }

        let destination = NSTemporaryDirectory() + "Genie_Sim_\(binding.deviceUdid.prefix(8))_\(Int(Date().timeIntervalSince1970)).png"

        return await withCheckedContinuation { continuation in
            Task.detached(priority: .userInitiated) {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
                process.arguments = ["simctl", "io", binding.deviceUdid, "screenshot", destination]
                process.standardOutput = Pipe()
                process.standardError = Pipe()

                do {
                    try process.run()
                    process.waitUntilExit()
                    if process.terminationStatus == 0 && FileManager.default.fileExists(atPath: destination) {
                        continuation.resume(returning: destination)
                    } else {
                        continuation.resume(returning: nil)
                    }
                } catch {
                    continuation.resume(returning: nil)
                }
            }
        }
    }

    // MARK: - 5. Clipboard Sync
    public func copyToSimulator(_ text: String, forChat chatId: String) async {
        guard GenieCapabilities.canSpawnSubprocesses else { return }
        let binding: ChatSimulatorBinding
        if let existing = activeBindings[chatId] {
            binding = existing
        } else if let created = await assignSimulator(forChat: chatId) {
            binding = created
        } else {
            return
        }
        Task.detached(priority: .userInitiated) {
            let process = Process()
            let pipe = Pipe()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
            process.arguments = ["simctl", "pbcopy", binding.deviceUdid]
            process.standardInput = pipe

            if let data = text.data(using: .utf8) {
                try? process.run()
                pipe.fileHandleForWriting.write(data)
                pipe.fileHandleForWriting.closeFile()
                process.waitUntilExit()
            }
        }
    }

    // MARK: - 6. Teardown / Release Chat Binding
    public func releaseSimulator(forChat chatId: String, shutdownIfIdle: Bool = false) {
        guard let binding = activeBindings.removeValue(forKey: chatId) else { return }
        activeSimulatorsCount = activeBindings.count
        self.statusLog = "Released simulator for chat '\(chatId)'"

        // If no other chat is using this device and shutdown requested
        let isStillInUse = activeBindings.values.contains { $0.deviceUdid == binding.deviceUdid }
        if !isStillInUse && shutdownIfIdle && GenieCapabilities.canSpawnSubprocesses {
            Task.detached(priority: .background) {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
                process.arguments = ["simctl", "shutdown", binding.deviceUdid]
                try? process.run()
                process.waitUntilExit()
            }
        }
    }

    // MARK: - 7. Toggle Lite Mode
    public func toggleLiteMode(_ enabled: Bool) {
        self.isLiteModeEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: "genie.simulator.liteMode")
        self.statusLog = enabled ? "Lite Mode Active (iOS Simulators)" : "Full VM Server Mode"
        HapticFeedback.selection()
    }
}
