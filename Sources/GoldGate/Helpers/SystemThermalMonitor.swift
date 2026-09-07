import Foundation
import Combine
import Darwin
import SwiftUI

// MARK: - System Thermal & Resource Monitor
//
// Samples whole-machine CPU load, Genie's own CPU share, memory pressure and the kernel's
// thermal state every two seconds. When the Mac reports a serious or critical thermal state
// while a local model is generating, the monitor can stop the run and eject the model from
// RAM automatically so the machine cools down. Everything here uses public Mach / Foundation
// APIs; nothing leaves the device.

@MainActor
public final class SystemThermalMonitor: ObservableObject {
    public static let shared = SystemThermalMonitor()

    public static let autoStopKey = PrefKey.thermalAutoStopEnabled
    public static let cpuAutoStopThresholdKey = PrefKey.thermalCPUAutoStopThreshold

    @Published public private(set) var systemCPUPercent: Double = 0
    @Published public private(set) var genieCPUPercent: Double = 0
    @Published public private(set) var memoryUsedGB: Double = 0
    @Published public private(set) var memoryTotalGB: Double = Double(ProcessInfo.processInfo.physicalMemory) / 1_073_741_824.0
    @Published public private(set) var thermalState: ProcessInfo.ThermalState = ProcessInfo.processInfo.thermalState
    @Published public private(set) var lastAutoStop: Date?
    @Published public private(set) var lastAutoStopReason: String = ""

    private var timer: Timer?
    private var previousCPUTicks: (busy: UInt64, idle: UInt64)?
    private var previousProcessCPU: (cpuSeconds: Double, wall: Date)?
    private var thermalObserver: NSObjectProtocol?
    private var lastAutoStopCheck: Date = .distantPast

    private init() {
        start()
    }

    // MARK: Public API

    public var autoStopEnabled: Bool {
        get {
            let d = UserDefaults.standard
            return d.object(forKey: Self.autoStopKey) == nil ? true : d.bool(forKey: Self.autoStopKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Self.autoStopKey)
            objectWillChange.send()
        }
    }

    /// Sustained Genie CPU share (percent of one machine) above which local runs are stopped.
    public var cpuAutoStopThreshold: Double {
        get {
            let v = UserDefaults.standard.double(forKey: Self.cpuAutoStopThresholdKey)
            return v > 0 ? v : 85.0
        }
        set {
            UserDefaults.standard.set(newValue, forKey: Self.cpuAutoStopThresholdKey)
            objectWillChange.send()
        }
    }

    public var thermalLabel: String {
        switch thermalState {
        case .nominal: return "Cool 🟢"
        case .fair: return "Warm 🟡"
        case .serious: return "Hot 🟠"
        case .critical: return "Overheating 🔴"
        @unknown default: return "Unknown"
        }
    }

    public var thermalColor: Color {
        switch thermalState {
        case .nominal: return .green
        case .fair: return .yellow
        case .serious: return .orange
        case .critical: return .red
        @unknown default: return .secondary
        }
    }

    public var isOverheating: Bool {
        thermalState == .serious || thermalState == .critical
    }

    public func start() {
        guard timer == nil else { return }
        sample()
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.sample() }
        }
        timer?.tolerance = 0.5
        thermalObserver = NotificationCenter.default.addObserver(
            forName: ProcessInfo.thermalStateDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.thermalState = ProcessInfo.processInfo.thermalState
                self?.evaluateAutoStop()
            }
        }
    }

    public func stop() {
        timer?.invalidate()
        timer = nil
        if let obs = thermalObserver { NotificationCenter.default.removeObserver(obs) }
        thermalObserver = nil
    }

    /// Stops the active local run and ejects models from RAM. Optionally powers the engine off.
    public func stopLocalModels(disableEngine: Bool, reason: String) {
        LocalModelManager.shared.emergencyStopLocalModels(disableEngine: disableEngine, reason: reason)
        lastAutoStop = Date()
        lastAutoStopReason = reason
    }

    // MARK: Sampling

    private func sample() {
        thermalState = ProcessInfo.processInfo.thermalState
        sampleSystemCPU()
        sampleProcessCPU()
        sampleMemory()
        evaluateAutoStop()
    }

    private func evaluateAutoStop() {
        guard autoStopEnabled else { return }
        let manager = LocalModelManager.shared
        guard manager.localModelsEnabled, manager.isGenerating else { return }
        guard Date().timeIntervalSince(lastAutoStopCheck) > 5 else { return }

        if thermalState == .critical {
            lastAutoStopCheck = Date()
            stopLocalModels(disableEngine: true, reason: "Mac reported a critical thermal state; local engine powered off to cool down.")
        } else if thermalState == .serious {
            lastAutoStopCheck = Date()
            stopLocalModels(disableEngine: false, reason: "Mac is running hot; the local model run was stopped and ejected from RAM.")
        } else if genieCPUPercent >= cpuAutoStopThreshold && systemCPUPercent >= 90 {
            lastAutoStopCheck = Date()
            stopLocalModels(disableEngine: false, reason: "Genie was using \(Int(genieCPUPercent))% CPU with the machine saturated; local run stopped.")
        }
    }

    private func sampleSystemCPU() {
        var cpuCount: natural_t = 0
        var info: processor_info_array_t?
        var infoCount: mach_msg_type_number_t = 0
        let result = host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &cpuCount, &info, &infoCount)
        guard result == KERN_SUCCESS, let info else { return }
        defer {
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: info), vm_size_t(infoCount) * vm_size_t(MemoryLayout<integer_t>.size))
        }

        var busy: UInt64 = 0
        var idle: UInt64 = 0
        let stateCount = Int(CPU_STATE_MAX)
        for cpu in 0..<Int(cpuCount) {
            let base = cpu * stateCount
            busy += UInt64(info[base + Int(CPU_STATE_USER)])
            busy += UInt64(info[base + Int(CPU_STATE_SYSTEM)])
            busy += UInt64(info[base + Int(CPU_STATE_NICE)])
            idle += UInt64(info[base + Int(CPU_STATE_IDLE)])
        }

        if let prev = previousCPUTicks {
            let dBusy = Double(busy &- prev.busy)
            let dIdle = Double(idle &- prev.idle)
            let total = dBusy + dIdle
            if total > 0 {
                systemCPUPercent = max(0, min(100, dBusy / total * 100.0))
            }
        }
        previousCPUTicks = (busy, idle)
    }

    private func sampleProcessCPU() {
        var usage = rusage()
        guard getrusage(RUSAGE_SELF, &usage) == 0 else { return }
        let cpuSeconds = Double(usage.ru_utime.tv_sec) + Double(usage.ru_utime.tv_usec) / 1_000_000.0
            + Double(usage.ru_stime.tv_sec) + Double(usage.ru_stime.tv_usec) / 1_000_000.0
        let now = Date()
        if let prev = previousProcessCPU {
            let wall = now.timeIntervalSince(prev.wall)
            if wall > 0 {
                let cores = Double(max(1, ProcessInfo.processInfo.activeProcessorCount))
                genieCPUPercent = max(0, min(100, (cpuSeconds - prev.cpuSeconds) / wall / cores * 100.0))
            }
        }
        previousProcessCPU = (cpuSeconds, now)
    }

    private func sampleMemory() {
        var stats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &stats) { ptr in
            ptr.withMemoryRebound(to: integer_t.self, capacity: Int(count)) { intPtr in
                host_statistics64(mach_host_self(), HOST_VM_INFO64, intPtr, &count)
            }
        }
        guard result == KERN_SUCCESS else { return }
        let pageSize = Double(vm_kernel_page_size)
        let used = (Double(stats.active_count) + Double(stats.wire_count) + Double(stats.compressor_page_count)) * pageSize
        memoryUsedGB = used / 1_073_741_824.0
    }
}
