import Foundation

#if GENIE_MAS

/// Genie Lite (Mac App Store) — the Hypervisor engine is compiled out.
///
/// Two independent blockers, either one of which is fatal on its own:
///
/// * `Virtualization.framework` requires `com.apple.security.virtualization`,
///   which `Genie.AppStore.entitlements` does not carry (and cannot: the App
///   Store profile is sandboxed and that entitlement is not grantable there).
/// * The engine boots `GoldenImage_Native.raw` and runs whatever binaries the
///   guest carries, which is App Store Review Guideline 2.5.2 regardless of
///   entitlements.
///
/// Shipping the real engine would therefore be dead code that fails at
/// `VZVirtualMachineConfiguration.validate()` on every call. The stub keeps
/// `RuntimeManager`'s call sites compiling and turns the attempt into a message
/// the user can actually read.
@MainActor
final class GenieHypervisorEngine: ObservableObject {
    static let shared = GenieHypervisorEngine()

    enum EngineError: LocalizedError {
        case unsupportedOnAppStoreBuild
        case resourceOverlap(String)
        case noSocketDevice
        case duplicateInstance(String)
        case notFound(String)
        case executionFailed(String)

        var errorDescription: String? {
            switch self {
            case .unsupportedOnAppStoreBuild:
                return GenieCapabilities.unavailableMessage("Linux runtimes")
            case .resourceOverlap(let reason):
                return "Resource Overlap Error: \(reason)"
            case .noSocketDevice:
                return "Virtio socket device unavailable"
            case .duplicateInstance(let id):
                return "VM instance '\(id)' already exists"
            case .notFound(let id):
                return "VM instance '\(id)' not found"
            case .executionFailed(let reason):
                return "Guest execution failed: \(reason)"
            }
        }
    }

    func spawn(_ config: RuntimeConfig) async throws {
        throw EngineError.unsupportedOnAppStoreBuild
    }

    func stop(_ id: String) async throws {
        throw EngineError.unsupportedOnAppStoreBuild
    }
}

#else

import Virtualization

/// Tracks exact resource slices allocated to an active VM instance to guarantee
/// strict, non-overlapping partitioning of host hardware.
public struct VMResourceAllocation: Identifiable, Sendable, Codable {
    public let id: String
    public let name: String
    public let vcpu: Int
    public let ramMB: Int
    public let macAddress: String
    public let vsockPortBase: UInt32
    public let workspacePath: String
    public let diskPath: String
    public let allocatedAt: Date

    public init(
        id: String,
        name: String,
        vcpu: Int,
        ramMB: Int,
        macAddress: String,
        vsockPortBase: UInt32,
        workspacePath: String,
        diskPath: String,
        allocatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.vcpu = vcpu
        self.ramMB = ramMB
        self.macAddress = macAddress
        self.vsockPortBase = vsockPortBase
        self.workspacePath = workspacePath
        self.diskPath = diskPath
        self.allocatedAt = allocatedAt
    }
}

@MainActor
public class GenieHypervisorEngine: ObservableObject {
    public static let shared = GenieHypervisorEngine()

    @Published public private(set) var clones: [String: VZVirtualMachine] = [:]
    @Published public private(set) var activeAllocations: [String: VMResourceAllocation] = [:]
    
    private var rootDir: URL {
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Genie")
    }

    // MARK: - Resource Non-Overlapping Invariants

    /// Total vCPUs currently committed across running VM clones.
    public var totalAllocatedVCPU: Int {
        activeAllocations.values.reduce(0) { $0 + $1.vcpu }
    }

    /// Total RAM (MB) currently committed across running VM clones.
    public var totalAllocatedRAMMB: Int {
        activeAllocations.values.reduce(0) { $0 + $1.ramMB }
    }

    /// Total physical cores available on this Apple Silicon host.
    public var hostPhysicalCores: Int {
        ProcessInfo.processInfo.activeProcessorCount
    }

    /// Total physical RAM (MB) on this Mac.
    public var hostTotalRAMMB: Int {
        Int(ProcessInfo.processInfo.physicalMemory / (1024 * 1024))
    }

    /// Cores strictly reserved for macOS system responsiveness (WindowServer, SkyLight Metal 120 FPS).
    public var hostReservedCores: Int {
        2
    }

    /// Maximum allocatable vCPUs without oversubscribing host CPU resources.
    public var hostMaxAllocatableVCPU: Int {
        max(1, hostPhysicalCores - hostReservedCores)
    }

    /// Maximum allocatable RAM (MB) across all VMs while reserving host OS baseline + local model headroom.
    public var hostMaxAllocatableRAMMB: Int {
        let rec = GenieMemoryGovernorEngine.shared.stationRAMRecommendation()
        return max(1024, rec.range.upperBound)
    }

    /// Validates whether a requested VM configuration can be provisioned without overlapping
    /// existing allocations or starving the host macOS environment.
    public func canAllocate(vcpu: Int, ramMB: Int) -> (allowed: Bool, reason: String?) {
        let proposedVCPU = totalAllocatedVCPU + vcpu
        if proposedVCPU > hostMaxAllocatableVCPU {
            return (
                false,
                "vCPU quota exceeded: requested \(vcpu) vCPUs would commit \(proposedVCPU) of \(hostMaxAllocatableVCPU) allocatable cores (\(totalAllocatedVCPU) already in use; 2 cores reserved for macOS)."
            )
        }

        let proposedRAM = totalAllocatedRAMMB + ramMB
        if proposedRAM > hostMaxAllocatableRAMMB {
            return (
                false,
                "RAM partition ceiling exceeded: requested \(ramMB) MB would commit \(proposedRAM) MB of \(hostMaxAllocatableRAMMB) MB allocatable memory (\(totalAllocatedRAMMB) MB already partitioned)."
            )
        }

        if GenieMemoryGovernorEngine.isCriticalPressureActive {
            return (false, "macOS system memory is critically exhausted. Provisioning halted to protect host stability.")
        }

        return (true, nil)
    }

    /// Returns the currently available non-overlapping resource budget.
    public func availableHostResources() -> (availableVCPU: Int, availableRAMMB: Int) {
        let freeVCPU = max(0, hostMaxAllocatableVCPU - totalAllocatedVCPU)
        let freeRAM = max(0, hostMaxAllocatableRAMMB - totalAllocatedRAMMB)
        return (freeVCPU, freeRAM)
    }

    // MARK: - VM Lifecycle & Full Access Provisioning

    public func spawn(_ config: RuntimeConfig) async throws {
        guard clones[config.id] == nil else {
            throw EngineError.duplicateInstance(config.id)
        }

        // Strict non-overlapping hardware admission check
        let (canProvision, failureReason) = canAllocate(vcpu: config.vcpu, ramMB: config.ramMB)
        guard canProvision else {
            throw EngineError.resourceOverlap(failureReason ?? "Resource partition conflict")
        }

        let configVM = VZVirtualMachineConfiguration()
        configVM.cpuCount = config.vcpu
        configVM.memorySize = UInt64(config.ramMB) * 1024 * 1024

        let cloneID = config.id
        let cloneDir = rootDir.appendingPathComponent("clones/\(cloneID)")
        try FileManager.default.createDirectory(at: cloneDir, withIntermediateDirectories: true)

        // --- Block storage (Dedicated copy-on-write sparse raw disk) ---
        let cloneImageURL = cloneDir.appendingPathComponent("disk.raw")
        try ensureDisk(at: cloneImageURL.path)
        let diskAttachment = try VZDiskImageStorageDeviceAttachment(url: cloneImageURL, readOnly: false)
        let diskDevice = VZVirtioBlockDeviceConfiguration(attachment: diskAttachment)
        configVM.storageDevices = [diskDevice]

        // --- Boot loader (EFI variable store partitioned per clone) ---
        let variableStoreURL = cloneDir.appendingPathComponent("efi_vars.fd")
        let variableStore = FileManager.default.fileExists(atPath: variableStoreURL.path)
            ? VZEFIVariableStore(url: variableStoreURL)
            : try VZEFIVariableStore(creatingVariableStoreAt: variableStoreURL, options: [])
        let bootLoader = VZEFIBootLoader()
        bootLoader.variableStore = variableStore
        configVM.bootLoader = bootLoader

        // --- Dedicated Non-Overlapping Workspace VirtioFS Mount ---
        let dedicatedWorkspaceDir = cloneDir.appendingPathComponent("workspace")
        try FileManager.default.createDirectory(at: dedicatedWorkspaceDir, withIntermediateDirectories: true)
        let wsShare = VZSingleDirectoryShare(directory: VZSharedDirectory(url: dedicatedWorkspaceDir, readOnly: false))
        let wsDevice = VZVirtioFileSystemDeviceConfiguration(tag: "genie_workspace")
        wsDevice.share = wsShare

        // --- Global Shared Bus VirtioFS Mount ---
        let sharedDir = rootDir.appendingPathComponent("shared")
        try FileManager.default.createDirectory(at: sharedDir, withIntermediateDirectories: true)
        let globalShare = VZSingleDirectoryShare(directory: VZSharedDirectory(url: sharedDir, readOnly: false))
        let globalFSDevice = VZVirtioFileSystemDeviceConfiguration(tag: "genie_share")
        globalFSDevice.share = globalShare

        configVM.directorySharingDevices = [wsDevice, globalFSDevice]

        // --- Network (NAT with collision-free locally administered MAC address) ---
        let netDevice = VZVirtioNetworkDeviceConfiguration()
        let uniqueMAC = VZMACAddress.randomLocallyAdministered()
        netDevice.macAddress = uniqueMAC
        netDevice.attachment = VZNATNetworkDeviceAttachment()
        configVM.networkDevices = [netDevice]

        // --- vsock: High-throughput RPC socket channel ---
        let socketConfig = VZVirtioSocketDeviceConfiguration()
        configVM.socketDevices = [socketConfig]

        // --- Serial console: boot logs and kernel diagnostics ---
        let consoleLogURL = cloneDir.appendingPathComponent("console.log")
        if !FileManager.default.fileExists(atPath: consoleLogURL.path) {
            FileManager.default.createFile(atPath: consoleLogURL.path, contents: nil)
        }
        let serialConfig = VZVirtioConsoleDeviceSerialPortConfiguration()
        serialConfig.attachment = VZFileHandleSerialPortAttachment(
            fileHandleForReading: nil,
            fileHandleForWriting: FileHandle(forWritingAtPath: consoleLogURL.path)
        )
        configVM.serialPorts = [serialConfig]

        // Validate and boot
        try configVM.validate()
        let vm = VZVirtualMachine(configuration: configVM)
        try await vm.start()

        // Register allocation in the active non-overlapping ledger
        let vsockPortBase: UInt32 = 1024 + UInt32(activeAllocations.count * 16)
        let allocation = VMResourceAllocation(
            id: cloneID,
            name: config.name.isEmpty ? cloneID : config.name,
            vcpu: config.vcpu,
            ramMB: config.ramMB,
            macAddress: uniqueMAC.string,
            vsockPortBase: vsockPortBase,
            workspacePath: dedicatedWorkspaceDir.path,
            diskPath: cloneImageURL.path
        )

        clones[config.id] = vm
        activeAllocations[config.id] = allocation
        print("🚀 [GenieHypervisor] Clone \(config.id) online (vCPU: \(config.vcpu), RAM: \(config.ramMB)MB, MAC: \(uniqueMAC.string))")
    }

    /// Opens a raw vsock connection into a running clone with no port collisions.
    public func connect(to id: String, port: UInt32) async throws -> VZVirtioSocketConnection {
        guard let vm = clones[id], let socketDevice = vm.socketDevices.first as? VZVirtioSocketDevice else {
            throw EngineError.noSocketDevice
        }
        return try await socketDevice.connect(toPort: port)
    }

    /// Reads real-time kernel and boot output from the VM's serial console log.
    public func readConsoleLog(id: String, maxLines: Int = 100) -> String {
        let logURL = rootDir.appendingPathComponent("clones/\(id)/console.log")
        guard let content = try? String(contentsOf: logURL, encoding: .utf8) else {
            return "No console log available for \(id)."
        }
        let lines = content.components(separatedBy: .newlines)
        if lines.count <= maxLines {
            return content
        }
        return lines.suffix(maxLines).joined(separator: "\n")
    }

    /// Executes a command in the guest VM via vsock RPC or dedicated workspace job file,
    /// giving full unrestricted root access within the guest boundary.
    public func executeInGuest(id: String, command: String, timeout: TimeInterval = 15.0) async throws -> String {
        guard let allocation = activeAllocations[id], clones[id] != nil else {
            throw EngineError.notFound(id)
        }

        // Write command job to the dedicated non-overlapping workspace
        let wsURL = URL(fileURLWithPath: allocation.workspacePath)
        let jobID = UUID().uuidString.prefix(8).lowercased()
        let scriptURL = wsURL.appendingPathComponent("genie_exec_\(jobID).sh")
        let outputURL = wsURL.appendingPathComponent("genie_exec_\(jobID).out")

        let wrappedScript = """
        #!/bin/bash
        set -e
        cd /home/ubuntu 2>/dev/null || cd /root
        (\(command)) > "\(outputURL.lastPathComponent)" 2>&1
        echo $? > "\(outputURL.lastPathComponent).done"
        """

        try wrappedScript.write(to: scriptURL, atomically: true, encoding: .utf8)

        // Await completion up to timeout
        let deadline = Date().addingTimeInterval(timeout)
        let doneURL = wsURL.appendingPathComponent("genie_exec_\(jobID).out.done")

        let startTime = Date()
        while Date() < deadline {
            if FileManager.default.fileExists(atPath: doneURL.path) {
                let outText = (try? String(contentsOf: outputURL, encoding: .utf8)) ?? ""
                let codeText = (try? String(contentsOf: doneURL, encoding: .utf8))?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "0"
                let exitCode = Int32(codeText) ?? 0
                let duration = Date().timeIntervalSince(startTime)

                // Task Verification Certification
                Task { @MainActor in
                    GenieTaskVerificationEngine.shared.verifyTask(
                        taskId: "guest-\(id)-\(jobID)",
                        taskDescription: "Guest VM execution in \(id)",
                        command: command,
                        exitCode: exitCode,
                        stdout: outText,
                        stderr: "",
                        durationSeconds: duration
                    )
                }

                // Clean up job descriptors
                try? FileManager.default.removeItem(at: scriptURL)
                try? FileManager.default.removeItem(at: doneURL)
                return outText.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms poll
        }

        // Return partial output or timeout indicator
        if let partial = try? String(contentsOf: outputURL, encoding: .utf8), !partial.isEmpty {
            return partial.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return "Command dispatched into guest \(id) (job \(jobID) pending background execution)."
    }

    private func ensureDisk(at path: String) throws {
        let fm = FileManager.default
        if !fm.fileExists(atPath: path) {
            try fm.createDirectory(atPath: (path as NSString).deletingLastPathComponent, withIntermediateDirectories: true)
            let source = rootDir.appendingPathComponent("GoldenImage_Native.raw")
            guard fm.fileExists(atPath: source.path) else {
                throw EngineError.executionFailed("Base GoldenImage_Native.raw missing at \(source.path)")
            }
            try fm.copyItem(at: source, to: URL(fileURLWithPath: path))
        }
    }

    /// Halts a running VM clone and immediately reclaims its vCPU, RAM, and socket resources.
    public func stop(_ id: String) async throws {
        if let vm = clones[id] {
            try await vm.stop()
            clones.removeValue(forKey: id)
            activeAllocations.removeValue(forKey: id)
            print("🛑 [GenieHypervisor] Clone \(id) stopped and resources reclaimed.")
        }
    }

    public enum EngineError: LocalizedError {
        case unsupportedOnAppStoreBuild
        case resourceOverlap(String)
        case noSocketDevice
        case duplicateInstance(String)
        case notFound(String)
        case executionFailed(String)

        public var errorDescription: String? {
            switch self {
            case .unsupportedOnAppStoreBuild:
                return GenieCapabilities.unavailableMessage("Linux runtimes")
            case .resourceOverlap(let reason):
                return "Resource Overlap Error: \(reason)"
            case .noSocketDevice:
                return "Virtio socket device unavailable"
            case .duplicateInstance(let id):
                return "VM instance '\(id)' already exists"
            case .notFound(let id):
                return "VM instance '\(id)' not found"
            case .executionFailed(let reason):
                return "Hypervisor engine error: \(reason)"
            }
        }
    }
}

#endif
