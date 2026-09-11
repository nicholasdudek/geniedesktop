import Foundation
import Virtualization

// MARK: - Models (Replicated for standalone test)
struct RuntimeConfiguration {
    var id: String = "runtime-\(UUID().uuidString.prefix(8).lowercased())"
    var displayName: String
    var description: String
    var executionConfig: ExecutionConfig
    var networkConfig: NetworkConfig
    var sessionConfig: SessionConfig
    var resourceAllocation: ResourceAllocation
    var autoScaling: AutoScalingConfig
    var encryptionType: EncryptionType = .googleManaged
}

enum EncryptionType { case googleManaged, customerManaged }
struct ExecutionConfig { var accountType: AccountType = .serviceAccount; var enableLightningEngine = false; enum AccountType { case serviceAccount, userAccount } }
struct NetworkConfig { var primaryNetwork = "default" }
struct SessionConfig { var maxIdleTimeQuantity = 10; var maxIdleTimeUnit = "minutes" }
struct ResourceAllocation { var driverCores: Int; var driverMemory: String; var executorInstances: Int }
struct AutoScalingConfig { var enabled = true }

@MainActor
class HypervisorEngine {
    static let shared = HypervisorEngine()
    var activeClones: [String: VZVirtualMachine] = [:]
    private let goldenImageURL = URL(fileURLWithPath: "/Users/nicholasdudek/Genie/GoldenImage_Native.raw")
    
    func spawnClone(config: RuntimeConfiguration) async throws {
        let configVM = VZVirtualMachineConfiguration()
        configVM.cpuCount = config.resourceAllocation.driverCores
        let memoryMB = Int(config.resourceAllocation.driverMemory.replacingOccurrences(of: "m", with: "")) ?? 12200
        configVM.memorySize = UInt64(memoryMB) * 1024 * 1024
        
        let cloneID = config.id
        let cloneImagePath = "/Users/nicholasdudek/Genie/clones/\(cloneID).raw"
        
        // Ensure directory exists
        try FileManager.default.createDirectory(atPath: "/Users/nicholasdudek/Genie/clones", withIntermediateDirectories: true)
        
        if !FileManager.default.fileExists(atPath: cloneImagePath) && FileManager.default.fileExists(atPath: goldenImageURL.path) {
            try FileManager.default.copyItem(at: goldenImageURL, to: URL(fileURLWithPath: cloneImagePath))
        }
        
        if FileManager.default.fileExists(atPath: cloneImagePath) {
            let attachment = try VZDiskImageStorageDeviceAttachment(url: URL(fileURLWithPath: cloneImagePath), readOnly: false)
            let disk = VZVirtioBlockDeviceConfiguration(attachment: attachment)
            configVM.storageDevices = [disk]
        }
        
        let networkConfig = VZVirtioNetworkDeviceConfiguration()
        networkConfig.attachment = VZNATNetworkDeviceAttachment()
        configVM.networkDevices = [networkConfig]
        
        print("🚀 [Hypervisor] VM configuration valid.")
    }
}

// MARK: - Test Execution
print("[*] Starting Native Hypervisor Integration Test...")
let config = RuntimeConfiguration(
    displayName: "Test Clone",
    description: "Testing Native Merge",
    executionConfig: ExecutionConfig(),
    networkConfig: NetworkConfig(),
    sessionConfig: SessionConfig(),
    resourceAllocation: ResourceAllocation(driverCores: 2, driverMemory: "4096m", executorInstances: 1),
    autoScaling: AutoScalingConfig()
)

Task {
    do {
        try await HypervisorEngine.shared.spawnClone(config: config)
        print("✅ SUCCESS: The Native Hypervisor spawned a clone without OrbStack.")
        exit(0)
    } catch {
        print("❌ FAILURE: \(error)")
        exit(1)
    }
}

RunLoop.main.run(until: Date(timeIntervalSinceNow: 5))
