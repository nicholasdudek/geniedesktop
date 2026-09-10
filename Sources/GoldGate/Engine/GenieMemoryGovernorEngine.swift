import Foundation
import AppKit
import os.log

// MARK: - 🧠 Genie Memory Governor Engine
/// Enforces RAM partitioning, memory ceilings, and macOS memory pressure monitoring
/// to ensure background AI agents and HDMI pipelines never exhaust host memory or impact the user.

public enum GenieMemoryPressureLevel: String, Sendable, CaseIterable {
    case normal = "Normal"
    case warning = "Warning"
    case critical = "Critical"
}

private final class CriticalPressureStore: @unchecked Sendable {
    static let shared = CriticalPressureStore()
    private let lock = NSLock()
    private var _isCritical: Bool = false

    var isCritical: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _isCritical
    }

    func setCritical(_ critical: Bool) {
        lock.lock()
        _isCritical = critical
        lock.unlock()
    }
}

@MainActor
public final class GenieMemoryGovernorEngine: ObservableObject, @unchecked Sendable {
    public static let shared = GenieMemoryGovernorEngine()

    private let logger = Logger(subsystem: "com.genie.governor", category: "memory")
    private var memoryPressureSource: DispatchSourceMemoryPressure?

    nonisolated public static var isCriticalPressureActive: Bool {
        CriticalPressureStore.shared.isCritical
    }

    nonisolated internal static func setCriticalPressure(_ active: Bool) {
        CriticalPressureStore.shared.setCritical(active)
    }

    // MARK: - Published State
    @Published public private(set) var currentPressureLevel: GenieMemoryPressureLevel = .normal
    @Published public private(set) var currentProcessResidentMB: Int = 0
    @Published public private(set) var hostAvailableMemoryMB: Int = 0
    @Published public private(set) var totalHostMemoryMB: Int = 0
    @Published public private(set) var activeRunningTasks: Int = 0
    @Published public private(set) var queuedAgentsCount: Int = 0
    public let maxConcurrentAgentSlots: Int = 4
    @Published public var maxAgentMemoryMB: Int = 4096 { // 4 GB default partition
        didSet {
            UserDefaults.standard.set(maxAgentMemoryMB, forKey: PrefKey.agentMemoryLimitMB)
            logger.info("Updated max agent memory limit to \(self.maxAgentMemoryMB) MB")
        }
    }

    /// Effective memory limit in Kilobytes for POSIX ulimit injection
    public var effectiveMemoryLimitKB: Int {
        return max(512, maxAgentMemoryMB) * 1024
    }

    /// Shell prefix to cap child process virtual & resident memory
    public var ulimitPrefix: String {
        let kb = effectiveMemoryLimitKB
        return "ulimit -v \(kb) 2>/dev/null; ulimit -m \(kb) 2>/dev/null; "
    }

    private init() {
        self.totalHostMemoryMB = Int(ProcessInfo.processInfo.physicalMemory / (1024 * 1024))
        if let savedLimit = UserDefaults.standard.value(forKey: PrefKey.agentMemoryLimitMB) as? Int, savedLimit >= 512 {
            self.maxAgentMemoryMB = savedLimit
        }
        setupMemoryPressureListener()
        refreshMemoryTelemetry()
    }

    // MARK: - Memory Pressure Monitoring
    private func setupMemoryPressureListener() {
        let source = DispatchSource.makeMemoryPressureSource(eventMask: [.warning, .critical], queue: .main)
        source.setEventHandler { [weak self] in
            guard let self = self else { return }
            let event = source.data

            if event.contains(.critical) {
                Self.setCriticalPressure(true)
                self.currentPressureLevel = .critical
                self.logger.fault("🚨 System Memory Pressure CRITICAL! Activating emergency governor.")
                self.handleHighMemoryPressure(critical: true)
            } else if event.contains(.warning) {
                Self.setCriticalPressure(false)
                self.currentPressureLevel = .warning
                self.logger.warning("⚠️ System Memory Pressure WARNING! Throttling agent pipelines.")
                self.handleHighMemoryPressure(critical: false)
            } else {
                Self.setCriticalPressure(false)
                self.currentPressureLevel = .normal
            }
        }
        source.resume()
        self.memoryPressureSource = source
    }

    private func handleHighMemoryPressure(critical: Bool) {
        // Broadcast notification for any caching subsystems to shed memory
        NotificationCenter.default.post(
            name: Notification.Name("GenieMemoryPressureHigh"),
            object: nil,
            userInfo: ["isCritical": critical]
        )

        // Purge disposable caches
        purgeVolatileCaches()
    }

    // MARK: - Memory Telemetry & Budget Checks
    public func refreshMemoryTelemetry() {
        // 1. Process resident memory
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size / 4)
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        if kerr == KERN_SUCCESS {
            self.currentProcessResidentMB = Int(info.resident_size / (1024 * 1024))
        }

        // 2. Host available memory approximation
        var stats = vm_statistics64()
        var size = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / 4)
        let hostPort = mach_host_self()
        let hostErr = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(size)) {
                host_statistics64(hostPort, HOST_VM_INFO64, $0, &size)
            }
        }
        if hostErr == KERN_SUCCESS {
            let pageSize = vm_kernel_page_size
            let freePages = UInt64(stats.free_count) + UInt64(stats.inactive_count)
            self.hostAvailableMemoryMB = Int((freePages * UInt64(pageSize)) / (1024 * 1024))
        }
    }

    /// Evaluates whether an agent task or heavy model can safely execute without causing memory starvation.
    public func canExecuteTask(estimatedMB: Int = 256) -> (allowed: Bool, reason: String?) {
        refreshMemoryTelemetry()

        if currentPressureLevel == .critical {
            return (false, "macOS system memory is critically exhausted. Pausing background tasks.")
        }

        if currentProcessResidentMB + estimatedMB > maxAgentMemoryMB {
            return (false, "Estimated memory (\(estimatedMB) MB) exceeds configured Genie RAM partition limit (\(maxAgentMemoryMB) MB).")
        }

        return (true, nil)
    }

    // MARK: - Agent Resource Queuing Engine
    /// Asynchronously waits in queue for RAM and concurrency slots to become available
    public func queueForResources(estimatedMB: Int = 256, timeout: TimeInterval = 12.0) async -> (granted: Bool, reason: String?) {
        queuedAgentsCount += 1
        defer { queuedAgentsCount = max(0, queuedAgentsCount - 1) }

        let start = Date()
        while Date().timeIntervalSince(start) < timeout {
            refreshMemoryTelemetry()
            let (allowed, _) = canExecuteTask(estimatedMB: estimatedMB)
            if allowed && activeRunningTasks < maxConcurrentAgentSlots {
                activeRunningTasks += 1
                return (true, nil)
            }
            try? await Task.sleep(nanoseconds: 150_000_000) // 150ms backoff
        }

        return (false, "Resource wait timeout: agent queue saturated or memory partition full (\(maxAgentMemoryMB) MB limit).")
    }

    /// Releases an execution slot once an agent task finishes
    public func releaseResourceSlot() {
        activeRunningTasks = max(0, activeRunningTasks - 1)
        refreshMemoryTelemetry()
    }

    /// Emergency release of volatile memory, model ring buffers, and preview frames.
    public func purgeVolatileCaches() {
        logger.info("Purging volatile caches and calling garbage collection.")
        NotificationCenter.default.post(name: Notification.Name("GeniePurgeVolatileCaches"), object: nil)
    }
}
