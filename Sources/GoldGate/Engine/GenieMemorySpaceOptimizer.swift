import Foundation
import Combine

// MARK: - Fleet Worker Model

public struct GenieFleetWorker: Identifiable, Sendable, Codable {
    public let id: String
    public let workerIndex: Int
    public let modelTag: String
    public let modelDisplayName: String
    public let memoryAllocationMB: Int
    public let vcpuAllocation: Int
    public let role: String

    public init(
        id: String,
        workerIndex: Int,
        modelTag: String,
        modelDisplayName: String,
        memoryAllocationMB: Int,
        vcpuAllocation: Int,
        role: String
    ) {
        self.id = id
        self.workerIndex = workerIndex
        self.modelTag = modelTag
        self.modelDisplayName = modelDisplayName
        self.memoryAllocationMB = memoryAllocationMB
        self.vcpuAllocation = vcpuAllocation
        self.role = role
    }
}

// MARK: - Fleet Strategy Mode

public enum GenieFleetStrategy: String, CaseIterable, Sendable {
    case parallelSwarm = "Parallel Swarm (Up to 4 Fast Workers)"
    case singleFlagship = "Single Flagship (Deep Reasoning)"
    case hybridTeam = "Hybrid Team (Vision Lead + Fast Workers)"
    case adaptive = "Adaptive Auto-Packing"
}

// MARK: - Genie Memory Space Optimizer

/// Optimizes the user's preferred allotted memory space and calculates the best
/// model and multi-instance fleet configuration (e.g. spinning up 4 parallel
/// Genie Fast Lite workers to maximize parallel throughput without oversubscribing RAM).
@MainActor
public final class GenieMemorySpaceOptimizer: ObservableObject {
    public static let shared = GenieMemorySpaceOptimizer()

    /// User's preferred memory budget for local models / guest instances (in MB)
    @Published public var preferredMemoryBudgetMB: Int = 12288 // 12 GB default

    /// Current active strategy
    @Published public var activeStrategy: GenieFleetStrategy = .adaptive

    /// Active workers currently planned or provisioned
    @Published public var plannedWorkers: [GenieFleetWorker] = []

    private init() {
        let savedBudget = UserDefaults.standard.integer(forKey: "genie.preferredMemoryBudgetMB")
        if savedBudget >= 4096 {
            self.preferredMemoryBudgetMB = savedBudget
        }
        recomputeFleet()
    }

    public func setPreferredBudget(megabytes: Int) {
        guard megabytes >= 2048 else { return }
        self.preferredMemoryBudgetMB = megabytes
        UserDefaults.standard.set(megabytes, forKey: "genie.preferredMemoryBudgetMB")
        recomputeFleet()
    }

    public func setStrategy(_ strategy: GenieFleetStrategy) {
        self.activeStrategy = strategy
        UserDefaults.standard.set(strategy.rawValue, forKey: "genie.fleetStrategy")
        recomputeFleet()
    }

    public func recomputeFleet() {
        self.plannedWorkers = planOptimalFleet(
            budgetMB: preferredMemoryBudgetMB,
            strategy: activeStrategy
        )
    }

    /// Computes the exact non-overlapping partition fleet for the given memory budget.
    public func planOptimalFleet(budgetMB: Int, strategy: GenieFleetStrategy) -> [GenieFleetWorker] {
        var workers: [GenieFleetWorker] = []

        switch strategy {
        case .parallelSwarm:
            // Spin up up to 4 parallel Genie Fast Lite (1.0 GB) instances
            let workerCount = min(4, max(1, budgetMB / 1000))
            for i in 0..<workerCount {
                workers.append(
                    GenieFleetWorker(
                        id: "worker-\(i)",
                        workerIndex: i,
                        modelTag: "qwen3.5:0.8b",
                        modelDisplayName: "Genie Fast Lite (1.0 GB)",
                        memoryAllocationMB: 950,
                        vcpuAllocation: 1,
                        role: "Parallel Task Worker \(i + 1)"
                    )
                )
            }

        case .singleFlagship:
            // Single high-capacity model
            if budgetMB >= 7200 {
                workers.append(
                    GenieFleetWorker(
                        id: "flagship-0",
                        workerIndex: 0,
                        modelTag: "gemma4:e2b",
                        modelDisplayName: "Genie Pro (7.2 GB)",
                        memoryAllocationMB: 7000,
                        vcpuAllocation: 4,
                        role: "Primary Multimodal Flagship"
                    )
                )
            } else if budgetMB >= 3600 {
                workers.append(
                    GenieFleetWorker(
                        id: "flagship-0",
                        workerIndex: 0,
                        modelTag: "qwen3.5:4b",
                        modelDisplayName: "Genie Balanced (3.4 GB)",
                        memoryAllocationMB: 3800,
                        vcpuAllocation: 2,
                        role: "Primary Balanced Flagship"
                    )
                )
            } else {
                workers.append(
                    GenieFleetWorker(
                        id: "flagship-0",
                        workerIndex: 0,
                        modelTag: "qwen3.5:2b",
                        modelDisplayName: "Genie Fast (2.7 GB)",
                        memoryAllocationMB: 2600,
                        vcpuAllocation: 2,
                        role: "Primary Fast Flagship"
                    )
                )
            }

        case .hybridTeam:
            // 1x Vision Lead + 2 to 3 Fast Lite Workers
            var remaining = budgetMB
            if remaining >= 4000 {
                workers.append(
                    GenieFleetWorker(
                        id: "lead-vision",
                        workerIndex: 0,
                        modelTag: "qwen3-vl:4b",
                        modelDisplayName: "Genie Vision (3.3 GB)",
                        memoryAllocationMB: 4000,
                        vcpuAllocation: 2,
                        role: "Eye / Screen Vision Orchestrator"
                    )
                )
                remaining -= 4000
            }

            let subWorkers = min(3, max(1, remaining / 1000))
            for i in 0..<subWorkers {
                workers.append(
                    GenieFleetWorker(
                        id: "worker-\(i)",
                        workerIndex: i + 1,
                        modelTag: "qwen3.5:0.8b",
                        modelDisplayName: "Genie Fast Lite (1.0 GB)",
                        memoryAllocationMB: 950,
                        vcpuAllocation: 1,
                        role: "Hands / Fast Execution Worker \(i + 1)"
                    )
                )
            }

        case .adaptive:
            // Automatically optimize: if budget >= 10GB, provision 1x Pro or 4x Fast Lite depending on need
            if budgetMB >= 10000 {
                // 4x Parallel Fast Lite Workers for high-throughput multi-tasking
                for i in 0..<4 {
                    workers.append(
                        GenieFleetWorker(
                            id: "worker-\(i)",
                            workerIndex: i,
                            modelTag: "qwen3.5:0.8b",
                            modelDisplayName: "Genie Fast Lite (1.0 GB)",
                            memoryAllocationMB: 950,
                            vcpuAllocation: 1,
                            role: "Parallel Swarm Worker \(i + 1)"
                        )
                    )
                }
            } else if budgetMB >= 6000 {
                // 2x Genie Fast (2.7 GB)
                for i in 0..<2 {
                    workers.append(
                        GenieFleetWorker(
                            id: "worker-\(i)",
                            workerIndex: i,
                            modelTag: "qwen3.5:2b",
                            modelDisplayName: "Genie Fast (2.7 GB)",
                            memoryAllocationMB: 2600,
                            vcpuAllocation: 2,
                            role: "Dual Agent Worker \(i + 1)"
                        )
                    )
                }
            } else {
                // Single Fast Worker
                workers.append(
                    GenieFleetWorker(
                        id: "worker-0",
                        workerIndex: 0,
                        modelTag: "qwen3.5:2b",
                        modelDisplayName: "Genie Fast (2.7 GB)",
                        memoryAllocationMB: min(budgetMB, 2600),
                        vcpuAllocation: 2,
                        role: "Single Worker"
                    )
                )
            }
        }

        return workers
    }
}
