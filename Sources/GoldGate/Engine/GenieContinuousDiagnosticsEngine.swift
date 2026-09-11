import AppKit
import Foundation
import os.log

// MARK: - 🩺 Genie Continuous Diagnostics & Parallel Thread Sentinel
/// Continuously monitors system diagnostics, serial logs, memory pressure, and every
/// parallel thread/task coming through the Genie runtime in real time.
///
/// Mandate: "Genie should never have to investigate because it is always running diagnostics,
/// log checks, and checking every parallel thread coming through."
///
/// Instead of pausing to run retrospective investigations, Genie maintains a live, bounded
/// diagnostic state graph ready for instantaneous sub-millisecond retrieval.

public struct ParallelThreadEvent: Identifiable, Sendable, Equatable {
    public let id: String
    public let name: String
    public let threadID: UInt64
    public let startedAt: Date
    public var completedAt: Date?
    public var status: ThreadStatus
    public var message: String?

    public enum ThreadStatus: String, Sendable, Codable {
        case running = "RUNNING"
        case completed = "COMPLETED"
        case failed = "FAILED"
        case stalled = "STALLED"
    }

    public init(
        id: String = UUID().uuidString.prefix(8).lowercased(),
        name: String,
        threadID: UInt64 = UInt64(pthread_mach_thread_np(pthread_self())),
        startedAt: Date = Date(),
        status: ThreadStatus = .running,
        message: String? = nil
    ) {
        self.id = id
        self.name = name
        self.threadID = threadID
        self.startedAt = startedAt
        self.status = status
        self.message = message
    }
}

public struct DiagnosticAnomaly: Identifiable, Sendable, Equatable {
    public let id = UUID()
    public let timestamp: Date
    public let subsystem: String
    public let severity: Severity
    public let detail: String

    public enum Severity: String, Sendable {
        case warning = "WARNING"
        case error = "ERROR"
        case critical = "CRITICAL"
    }

    public init(subsystem: String, severity: Severity, detail: String, timestamp: Date = Date()) {
        self.timestamp = timestamp
        self.subsystem = subsystem
        self.severity = severity
        self.detail = detail
    }
}

public struct DiagnosticSnapshot: Sendable {
    public let timestamp: Date
    public let systemHealth: String
    public let memoryPressure: String
    public let processResidentMB: Int
    public let hostAvailableMB: Int
    public let activeParallelThreads: Int
    public let activeVMClones: Int
    public let recentAnomalies: [DiagnosticAnomaly]
    public let serialLogTails: [String: String]

    public var summary: String {
        """
        [Genie Instant Telemetry @ \(timestamp.formatted(date: .omitted, time: .standard))]
        • System Health: \(systemHealth) (RAM Pressure: \(memoryPressure))
        • Host Memory: \(processResidentMB)MB process / \(hostAvailableMB)MB available
        • Active Parallel Threads: \(activeParallelThreads)
        • Active Hypervisor VMs: \(activeVMClones)
        • Recent Anomalies: \(recentAnomalies.isEmpty ? "None (Nominal)" : "\(recentAnomalies.count) detected")
        """
    }
}

@MainActor
public final class GenieContinuousDiagnosticsEngine: ObservableObject, @unchecked Sendable {
    public static let shared = GenieContinuousDiagnosticsEngine()

    private let logger = Logger(subsystem: "com.genie.diagnostics", category: "sentinel")
    private let lock = NSLock()

    // Bounded attention sink ring buffers (bounded under 1.5MB resident footprint)
    private var threadRegistry: [String: ParallelThreadEvent] = [:]
    private var anomalyBuffer = AttentionSinkBuffer<DiagnosticAnomaly>(capacity: 128, anchorCount: 4)
    private var serialLogSnapshots: [String: String] = [:]

    @Published public private(set) var isRunning: Bool = false
    @Published public private(set) var activeThreadCount: Int = 0
    @Published public private(set) var latestSnapshot: DiagnosticSnapshot?

    private var diagnosticsTimer: Timer?
    private var rootDir: URL {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Genie")
    }

    private init() {
        start()
    }

    // MARK: - Lifecycle

    public func start() {
        guard !isRunning else { return }
        isRunning = true

        diagnosticsTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.runDiagnosticTick()
            }
        }
        logger.info("🩺 [GenieDiagnostics] Continuous diagnostics sentinel started.")
    }

    public func stop() {
        isRunning = false
        diagnosticsTimer?.invalidate()
        diagnosticsTimer = nil
    }

    // MARK: - Parallel Thread Tracking

    /// Call when spawning an asynchronous worker or parallel background task
    @discardableResult
    public func registerThread(name: String) -> String {
        let taskID = "th-\(UUID().uuidString.prefix(8).lowercased())"
        let event = ParallelThreadEvent(id: taskID, name: name)

        lock.lock()
        threadRegistry[taskID] = event
        lock.unlock()

        activeThreadCount = threadRegistry.values.filter { $0.status == .running }.count
        return taskID
    }

    /// Mark a parallel thread task completed
    public func completeThread(id: String, success: Bool, message: String? = nil) {
        lock.lock()
        if var event = threadRegistry[id] {
            event.completedAt = Date()
            event.status = success ? .completed : .failed
            event.message = message
            threadRegistry[id] = event

            if !success {
                anomalyBuffer.append(
                    DiagnosticAnomaly(
                        subsystem: "Thread:\(event.name)",
                        severity: .error,
                        detail: message ?? "Parallel thread failed"
                    )
                )
            }
        }
        lock.unlock()

        activeThreadCount = threadRegistry.values.filter { $0.status == .running }.count
    }

    // MARK: - Continuous Diagnostics Tick

    private func runDiagnosticTick() {
        // 1. Thread health & stall check
        let now = Date()
        lock.lock()
        for (id, var thread) in threadRegistry where thread.status == .running {
            if now.timeIntervalSince(thread.startedAt) > 45.0 {
                thread.status = .stalled
                threadRegistry[id] = thread
                anomalyBuffer.append(
                    DiagnosticAnomaly(
                        subsystem: "Thread:\(thread.name)",
                        severity: .warning,
                        detail: "Task exceeded 45s execution threshold (possible deadlock or long network poll)"
                    )
                )
            }
        }
        lock.unlock()

        // 2. Memory & Host Governor Check
        GenieMemoryGovernorEngine.shared.refreshMemoryTelemetry()
        let pressure = GenieMemoryGovernorEngine.shared.currentPressureLevel
        let residentMB = GenieMemoryGovernorEngine.shared.currentProcessResidentMB
        let availMB = GenieMemoryGovernorEngine.shared.hostAvailableMemoryMB

        if pressure == .critical {
            lock.lock()
            anomalyBuffer.append(
                DiagnosticAnomaly(
                    subsystem: "HostRAM",
                    severity: .critical,
                    detail: "macOS system memory pressure is CRITICAL. Active caches shed."
                )
            )
            lock.unlock()
        }

        // 3. Serial Log Scanning for Hypervisor Clones
        #if !GENIE_MAS
        scanHypervisorLogs()
        let activeVMCount = GenieHypervisorEngine.shared.clones.count
        #else
        let activeVMCount = 0
        #endif

        // 4. Synthesize Instant Snapshot
        lock.lock()
        let anomalies = Array(anomalyBuffer.elements.suffix(10))
        let logTails = serialLogSnapshots
        let activeRunning = threadRegistry.values.filter { $0.status == .running }.count
        lock.unlock()

        let health = (pressure == .critical || anomalies.contains { $0.severity == .critical }) ? "DEGRADED" : "NOMINAL"

        let snapshot = DiagnosticSnapshot(
            timestamp: now,
            systemHealth: health,
            memoryPressure: pressure.rawValue,
            processResidentMB: residentMB,
            hostAvailableMB: availMB,
            activeParallelThreads: activeRunning,
            activeVMClones: activeVMCount,
            recentAnomalies: anomalies,
            serialLogTails: logTails
        )

        self.latestSnapshot = snapshot
    }

    #if !GENIE_MAS
    private func scanHypervisorLogs() {
        let clonesDir = rootDir.appendingPathComponent("clones")
        guard let cloneFolders = try? FileManager.default.contentsOfDirectory(at: clonesDir, includingPropertiesForKeys: nil) else { return }

        for folder in cloneFolders where folder.hasDirectoryPath {
            let cloneID = folder.lastPathComponent
            let logURL = folder.appendingPathComponent("console.log")
            guard FileManager.default.fileExists(atPath: logURL.path),
                  let content = try? String(contentsOf: logURL, encoding: .utf8) else { continue }

            let lines = content.components(separatedBy: .newlines)
            let tail = lines.suffix(15).joined(separator: "\n")
            lock.lock()
            serialLogSnapshots[cloneID] = tail

            // Continuous log checks for kernel panics and OOM
            let lowerTail = tail.lowercased()
            if lowerTail.contains("kernel panic") || lowerTail.contains("out of memory") || lowerTail.contains("oom-killer") {
                anomalyBuffer.append(
                    DiagnosticAnomaly(
                        subsystem: "VM:\(cloneID)",
                        severity: .critical,
                        detail: "Guest kernel warning/panic detected in serial console log"
                    )
                )
            }
            lock.unlock()
        }
    }
    #endif

    // MARK: - Zero-Investigation Instant Query API

    /// Returns the pre-computed diagnostics without initiating any probing or investigation.
    public func getInstantDiagnostics() -> DiagnosticSnapshot {
        if let snap = latestSnapshot {
            return snap
        }
        // Fallback immediate computation
        return DiagnosticSnapshot(
            timestamp: Date(),
            systemHealth: "NOMINAL",
            memoryPressure: GenieMemoryGovernorEngine.shared.currentPressureLevel.rawValue,
            processResidentMB: GenieMemoryGovernorEngine.shared.currentProcessResidentMB,
            hostAvailableMB: GenieMemoryGovernorEngine.shared.hostAvailableMemoryMB,
            activeParallelThreads: activeThreadCount,
            activeVMClones: 0,
            recentAnomalies: [],
            serialLogTails: [:]
        )
    }
}
