import Foundation

// MARK: - RuntimeConfiguration
// Full model consumed by RuntimeConfiguratorView.
// Bridges to the simpler RuntimeConfig used by the Hypervisor.

struct RuntimeConfiguration: Identifiable {
    var id: String = "rt-\(UUID().uuidString.prefix(8).lowercased())"
    var displayName: String = ""
    var description: String = ""

    var resources: StationResources
    var sessionConfig: SessionConfig

    init(
        displayName: String = "",
        description: String = "",
        resources: StationResources = StationResources(),
        sessionConfig: SessionConfig = SessionConfig()
    ) {
        self.displayName = displayName
        self.description = description
        self.resources = resources
        self.sessionConfig = sessionConfig
    }

    /// Convert to the simpler `RuntimeConfig` the Hypervisor expects.
    func toRuntimeConfig() -> RuntimeConfig {
        RuntimeConfig(
            name: displayName,
            description: description,
            vcpu: resources.vcpu,
            ramMB: resources.ramMB,
            diskGB: resources.diskGB
        )
    }
}

// MARK: - StationResources
// A single local VM station's compute budget. Replaces the old GCP
// Dataproc/Spark-flavored `ResourceAllocation` (driver/executor split,
// autoscaling executor pools) — none of that applies to one local VM.

struct StationResources {
    var vcpu: Int = 2
    /// Seed from GenieMemoryGovernorEngine.shared.stationRAMRecommendation().recommendedDefault
    var ramMB: Int = 4096
    /// UI-only for v1 — not yet wired into GenieHypervisorEngine.ensureDisk(at:).
    /// TODO: wire real disk sizing (host-side sparse-truncate of the cloned .raw
    /// plus guest-side growpart/resize2fs on first boot) before trusting this value.
    var diskGB: Int = 32
}

// MARK: - TimeUnit

enum TimeUnit: String, CaseIterable {
    case seconds = "Seconds"
    case minutes = "Minutes"
    case hours = "Hours"
    case days = "Days"
}

// MARK: - SessionConfig
// Auto-suspend timers — genuinely useful for a local VM, kept as-is.

struct SessionConfig {
    var maxIdleTimeQuantity: Int = 30
    var maxIdleTimeUnit: TimeUnit = .minutes
    var maxLifetimeQuantity: Int = 24
    var maxLifetimeTimeUnit: TimeUnit = .hours
}
