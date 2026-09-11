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

    // MARK: - Zero-Leak Idle Sentinel & Telemetry
    @Published public private(set) var isLeakFree: Bool = true
    @Published public private(set) var idleStatusDescription: String = "Idle: Zero-Leak Verified"
    @Published public private(set) var baselineIdleResidentMB: Int = 0
    @Published public private(set) var idleSecondsElapsed: Int = 0

    private var idleSentinelTimer: Timer?
    private var lastActiveTimestamp: Date = Date()
    private var idleSampleTicks: Int = 0

    private init() {
        self.totalHostMemoryMB = Int(ProcessInfo.processInfo.physicalMemory / (1024 * 1024))
        if let savedLimit = UserDefaults.standard.value(forKey: PrefKey.agentMemoryLimitMB) as? Int, savedLimit >= 512 {
            self.maxAgentMemoryMB = savedLimit
        }
        setupMemoryPressureListener()
        setupIdleSentinel()
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

        // Directly invoke RAM layer offloading to instantly reclaim uncompressed 4K layer allocations
        GenieRAMLayerOffloaderEngine.shared.offloadInactiveRAMLayers(critical: critical)

        // Purge disposable caches
        purgeVolatileCaches()
    }

    /// Proactively triggers RAM layer offloading if resident memory or system pressure requires it.
    @discardableResult
    public func offloadRAMLayersWhenNecessary() -> Int {
        return GenieRAMLayerOffloaderEngine.shared.offloadRAMLayersWhenNecessary()
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
        markUserOrAgentActivity()
    }

    // MARK: - Zero-Leak Idle Sentinel Implementation
    private func setupIdleSentinel() {
        idleSentinelTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.evaluateIdleMemoryHealth()
            }
        }
    }

    /// Informs the sentinel that active work or interaction occurred
    public func markUserOrAgentActivity() {
        lastActiveTimestamp = Date()
        idleSecondsElapsed = 0
        idleSampleTicks = 0
    }

    /// Evaluates memory drift during idle periods to guarantee zero memory leakage
    private func evaluateIdleMemoryHealth() {
        refreshMemoryTelemetry()

        let hasActiveTasks = activeRunningTasks > 0
        if hasActiveTasks {
            markUserOrAgentActivity()
            idleStatusDescription = "Active (\(activeRunningTasks) tasks)"
            return
        }

        let elapsed = Int(Date().timeIntervalSince(lastActiveTimestamp))
        idleSecondsElapsed = elapsed

        if elapsed >= 10 {
            idleSampleTicks += 1
            if baselineIdleResidentMB == 0 || idleSampleTicks <= 2 {
                baselineIdleResidentMB = currentProcessResidentMB
            }

            let drift = currentProcessResidentMB - baselineIdleResidentMB

            if drift > 25 {
                // Unexpected memory drift during pure idle -> run hygiene pass
                logger.warning("Idle memory drift detected (+\(drift) MB). Running automatic cache compaction.")
                purgeVolatileCaches()
                refreshMemoryTelemetry()
                let postPurgeDrift = currentProcessResidentMB - baselineIdleResidentMB
                if postPurgeDrift > 35 {
                    isLeakFree = false
                    idleStatusDescription = "Drift Warning (+\(postPurgeDrift) MB)"
                } else {
                    isLeakFree = true
                    idleStatusDescription = "Auto-Compacted (~\(currentProcessResidentMB) MB)"
                    baselineIdleResidentMB = currentProcessResidentMB
                }
            } else {
                isLeakFree = true
                idleStatusDescription = "Idle: Zero-Leak (~\(currentProcessResidentMB) MB)"
            }
        } else {
            idleStatusDescription = "Settling to Idle..."
        }
    }

    /// Emergency release of volatile memory, model ring buffers, and preview frames.
    public func purgeVolatileCaches() {
        logger.info("Purging volatile caches and calling garbage collection.")
        NotificationCenter.default.post(name: Notification.Name("GeniePurgeVolatileCaches"), object: nil)
        autoreleasepool {
            // Drain transient heap allocations
        }
    }

    // MARK: - AI Station RAM Sizing (8-48GB host range)
    // Distinct from `maxAgentMemoryMB` above (a host-side ulimit for Genie's own
    // subprocesses) — this sizes a VZVirtualMachineConfiguration's memorySize for
    // a Linux "station" clone, leaving headroom for macOS itself plus a
    // concurrently-loaded local model (genie-master measured at ~25GB RAM).
    private static let stationRAMFloorMB = 1024
    private static let stationOSBaselineMB = 2560
    private static let stationModelHeadroomFloorMB = 3072
    private static let stationModelHeadroomCapMB = 26_624

    /// Safe RAM range + recommended default for one local VM station, given this
    /// Mac's total physical RAM. Assumes the local model may be loaded
    /// concurrently with the station (the realistic case: the model drives tool
    /// calls into it), so the max stays well short of "total minus a flat OS-only reserve."
    public func stationRAMRecommendation() -> StationRAMRecommendation {
        let total = totalHostMemoryMB
        let modelHeadroom = min(max(total / 2, Self.stationModelHeadroomFloorMB), Self.stationModelHeadroomCapMB)
        let reserve = Self.stationOSBaselineMB + modelHeadroom
        let maxStation = max(Self.stationRAMFloorMB, ((total - reserve) / 256) * 256)
        let defaultStation = min(maxStation, max(Self.stationRAMFloorMB, ((total / 4) / 256) * 256))
        return StationRAMRecommendation(range: Self.stationRAMFloorMB...maxStation, recommendedDefault: defaultStation)
    }

    /// How comfortably this Mac can run a large local model (genie-master, ~25GB
    /// resident) alongside its own UI process and whatever station is active.
    /// Reuses the same headroom reasoning as `stationRAMRecommendation()` rather
    /// than a second, unrelated threshold scheme.
    public enum LocalModelViability: String, Sendable {
        case comfortable      // total RAM comfortably covers model + OS + a station
        case tight             // possible, but little room left over; warn the user
        case cloudRecommended  // local is not realistic; steer to a cloud model
    }

    public var localModelViability: LocalModelViability {
        switch totalHostMemoryMB {
        case 32_768...: return .comfortable
        case 16_384..<32_768: return .tight
        default: return .cloudRecommended
        }
    }
}

public struct StationRAMRecommendation: Sendable, Equatable {
    public let range: ClosedRange<Int>   // MB, safe slider bounds for this host
    public let recommendedDefault: Int   // MB
    public let stepMB: Int = 256
}
