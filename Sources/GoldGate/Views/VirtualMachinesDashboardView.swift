import SwiftUI
import AppKit
import GenieEnvironmentKit

// MARK: - 🖥️ Virtual Machines, AI Stations & Hypervisor Control Dashboard
public struct VirtualMachinesDashboardView: View {
    @ObservedObject private var runtimeManager = RuntimeManager.shared
    @ObservedObject private var envController = GenieEnvironmentController.shared
    @ObservedObject private var memoryGovernor = GenieMemoryGovernorEngine.shared
    @ObservedObject private var permissionsAgent = GeniePermissionsAgent.shared
    @ObservedObject private var computeEngine = GenieDistributedComputeEngine.shared
    @ObservedObject private var inRAMVM = GenieInRAMVMManager.shared
    @ObservedObject private var localModels = LocalModelManager.shared
    @State private var showingCreateStationSheet: Bool = false
    @State private var showingLogsForStation: RuntimeInstance? = nil
    @State private var statusFeedback: String? = nil

    public init() {}

    public var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 18) {
                // 1. Telemetry & Hardware Headroom Strip
                systemOverviewStrip

                // 2. Sovereign In-RAM Ubuntu VM & Model Server (Port 58300)
                inRAMVMSection

                // 3. Active Virtual Machines & AI Stations
                stationsSection

                // 3. Quick Provisioning Templates
                templatesSection

                // 4. Linux Tool Environment & Workspaces
                environmentSection

                // 5. Distributed Multi-Machine Compute & Calculations Engine
                distributedComputeSection

                // 6. Executive Permissions & Security Guardrails
                securityAuditSection
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .sheet(isPresented: $showingCreateStationSheet) {
            RuntimeConfiguratorView()
                .frame(minWidth: 520, minHeight: 620)
        }
        .sheet(item: $showingLogsForStation) { station in
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Live Console: \(station.config.name)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                        Text("Station ID: \(station.id)")
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    Spacer()
                    Button("Done") {
                        showingLogsForStation = nil
                    }
                    .buttonStyle(.bordered)
                }
                .padding(.horizontal, 16)
                .padding(.top, 14)

                RuntimeLogView()
            }
            .frame(minWidth: 540, minHeight: 420)
            .background(Color(white: 0.12))
        }
    }

    // MARK: - 1. System Overview & Hardware Headroom Strip
    private var systemOverviewStrip: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Virtual Machines & AI Stations", systemImage: "server.rack")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Spacer()

                Button(action: {
                    showingCreateStationSheet = true
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "plus.circle.fill")
                        Text("New Station")
                    }
                    .font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(.borderedProminent)
                .tint(.blue)
            }

            Text("Native Apple Silicon virtualization engine for isolated Linux clones, Apache Spark clusters, and tool sandboxes.")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.6))

            // Hardware telemetry pills
            HStack(spacing: 10) {
                telemetryPill(
                    icon: "cpu",
                    title: "Active Stations",
                    value: "\(runtimeManager.runtimes.count)",
                    tint: runtimeManager.runtimes.isEmpty ? .secondary : .green
                )

                let totalHostRAMGB = memoryGovernor.totalHostMemoryMB / 1024
                telemetryPill(
                    icon: "memorychip",
                    title: "Host Memory",
                    value: "\(totalHostRAMGB) GB",
                    tint: .blue
                )

                let rec = memoryGovernor.stationRAMRecommendation()
                let safeGB: Double = Double(rec.recommendedDefault) / 1024.0
                telemetryPill(
                    icon: "shield.lefthalf.filled",
                    title: "Safe Allocation",
                    value: String(format: "%.1f GB", safeGB),
                    tint: .teal
                )

                let isConnected = envController.status.contains("Connected")
                telemetryPill(
                    icon: "network",
                    title: "Environment",
                    value: isConnected ? "Connected" : "Standby",
                    tint: isConnected ? .green : .orange
                )
            }
            .padding(.top, 4)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.04))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1))
        )
    }

    private func telemetryPill(icon: String, title: String, value: String, tint: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundColor(tint)
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 9.5))
                    .foregroundColor(.white.opacity(0.55))
                Text(value)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.white.opacity(0.04))
        .cornerRadius(8)
    }

    // MARK: - 2. Sovereign In-RAM Ubuntu VM & Model Server (Port 58300)
    private var inRAMVMSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Sovereign In-RAM Ubuntu Model Server", systemImage: "memorychip.fill")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Spacer()

                HStack(spacing: 4) {
                    Circle()
                        .fill(inRAMVM.isModelServerRunning ? Color.green : (inRAMVM.isRAMDiskMounted ? Color.yellow : Color.secondary))
                        .frame(width: 7, height: 7)
                    Text(inRAMVM.isModelServerRunning ? "Online (Port \(inRAMVM.serverPort))" : (inRAMVM.isRAMDiskMounted ? "RAM Disk Ready" : "Standby"))
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(inRAMVM.isModelServerRunning ? .green : .white.opacity(0.7))
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(Capsule().fill(Color.white.opacity(0.06)))
            }

            Text("Eliminates host SSD write wear by booting an Ubuntu rootfs directly inside Apple Silicon Unified RAM (200-800 GB/s bus throughput). Slices dedicated port \(inRAMVM.serverPort) so you can run local models with zero Ollama dependency.")
                .font(.system(size: 11))
                .foregroundColor(.white.opacity(0.65))

            // Status and diagnostic row
            HStack(spacing: 8) {
                HStack(spacing: 5) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.yellow)
                    Text(inRAMVM.statusMessage)
                        .font(.system(size: 10.5, design: .monospaced))
                        .foregroundColor(.white.opacity(0.85))
                }

                Spacer()

                if let mountPath = inRAMVM.ramDiskMountPath {
                    Text(mountPath)
                        .font(.system(size: 9.5, design: .monospaced))
                        .foregroundColor(.cyan.opacity(0.8))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.3))
            .cornerRadius(8)

            // Action Buttons
            HStack(spacing: 8) {
                if !inRAMVM.isRAMDiskMounted {
                    Button(action: {
                        Task {
                            _ = try? await inRAMVM.mountRAMDisk(sizeMB: 4096)
                            HapticFeedback.selection()
                        }
                    }) {
                        Label("Mount 4GB RAMDisk", systemImage: "plus.circle")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                } else {
                    Button(action: {
                        inRAMVM.dismountRAMDisk()
                        HapticFeedback.selection()
                    }) {
                        Label("Dismount RAMDisk", systemImage: "eject.fill")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }

                if !inRAMVM.isModelServerRunning {
                    Button(action: {
                        Task {
                            try? await inRAMVM.startSovereignServer()
                            localModels.ollamaHost = "http://127.0.0.1:\(inRAMVM.serverPort)"
                            localModels.refreshAvailableModels()
                            HapticFeedback.success()
                        }
                    }) {
                        Label("Start In-RAM Server (Port \(inRAMVM.serverPort))", systemImage: "play.fill")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                } else {
                    Button(action: {
                        inRAMVM.stopSovereignServer()
                        HapticFeedback.selection()
                    }) {
                        Label("Stop Server", systemImage: "stop.fill")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .buttonStyle(.bordered)
                }

                Button(action: {
                    let panel = NSOpenPanel()
                    panel.title = "Select Ubuntu Rootfs or Model Zip"
                    panel.allowedContentTypes = [.zip, .gzip]
                    panel.allowsMultipleSelection = false
                    if panel.runModal() == .OK, let url = panel.url {
                        Task {
                            if !inRAMVM.isRAMDiskMounted {
                                _ = try? await inRAMVM.mountRAMDisk(sizeMB: 4096)
                            }
                            try? await inRAMVM.extractRootfsFromZip(zipURL: url, to: GenieInRAMVMManager.ramDiskDefaultMountURL)
                            HapticFeedback.success()
                        }
                    }
                }) {
                    Label("Unzip Rootfs into RAM...", systemImage: "arrow.down.doc")
                        .font(.system(size: 11))
                }
                .buttonStyle(.bordered)

                Spacer()

                Button(action: {
                    localModels.ollamaHost = "http://127.0.0.1:\(inRAMVM.serverPort)"
                    localModels.refreshAvailableModels()
                    HapticFeedback.selection()
                }) {
                    Text("Route to Port \(inRAMVM.serverPort)")
                        .font(.system(size: 10, weight: .medium))
                }
                .buttonStyle(.plain)
                .foregroundColor(.cyan)
                .help("Sets Genie model engine host to http://127.0.0.1:\(inRAMVM.serverPort), bypassing Ollama")
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.04))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.cyan.opacity(0.20), lineWidth: 1))
        )
    }

    // MARK: - 3. Active Virtual Machines Section
    private var stationsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Configured AI Stations")
                    .font(.system(size: 12.5, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                Text("\(runtimeManager.runtimes.count) Total")
                    .font(.system(size: 10.5))
                    .foregroundColor(.white.opacity(0.5))
            }

            if runtimeManager.runtimes.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "cube.transparent")
                        .font(.system(size: 28))
                        .foregroundColor(.white.opacity(0.3))
                    Text("No AI Stations Created")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                    Text("Launch an isolated Linux environment below with one click or create a custom station.")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.02))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.06), lineWidth: 1))
                )
            } else {
                VStack(spacing: 8) {
                    ForEach(runtimeManager.runtimes) { runtime in
                        stationRow(runtime)
                    }
                }
            }
        }
    }

    private func stationRow(_ runtime: RuntimeInstance) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(statusColor(runtime.status))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(runtime.config.name)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                    Text(runtime.status.rawValue.uppercased())
                        .font(.system(size: 8.5, weight: .bold))
                        .foregroundColor(statusColor(runtime.status))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1.5)
                        .background(statusColor(runtime.status).opacity(0.15))
                        .cornerRadius(4)
                }

                HStack(spacing: 8) {
                    Text("\(runtime.config.vcpu) vCPU")
                    Text("•")
                    Text("\(runtime.config.ramMB) MB RAM")
                    Text("•")
                    Text("\(runtime.config.diskGB) GB Disk")
                    Text("•")
                    Text("ID: \(runtime.id)")
                }
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.white.opacity(0.55))
            }

            Spacer()

            HStack(spacing: 6) {
                Button(action: {
                    showingLogsForStation = runtime
                }) {
                    Image(systemName: "terminal")
                        .font(.system(size: 11))
                }
                .buttonStyle(.bordered)
                .help("View Live Station Console")

                Button(role: .destructive, action: {
                    Task {
                        await runtimeManager.destroy(runtime.id)
                    }
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 11))
                }
                .buttonStyle(.bordered)
                .help("Destroy Station")
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.03))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.06), lineWidth: 1))
        )
    }

    private func statusColor(_ status: RuntimeInstance.Status) -> Color {
        switch status {
        case .active: return .green
        case .provisioning: return .yellow
        case .terminated: return .secondary
        case .failed: return .red
        }
    }

    // MARK: - 3. Quick Provisioning Templates
    private var templatesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quick Launch Presets")
                .font(.system(size: 12.5, weight: .bold))
                .foregroundColor(.white)

            HStack(spacing: 10) {
                templateCard(
                    title: "Data Science & Spark",
                    specs: "8 vCPU • 16 GB RAM • PySpark",
                    icon: "sparkles",
                    tint: .orange,
                    vcpu: 8,
                    ramMB: 16384
                )

                templateCard(
                    title: "Polyglot Sandbox",
                    specs: "4 vCPU • 8 GB RAM • Compilers",
                    icon: "hammer.fill",
                    tint: .teal,
                    vcpu: 4,
                    ramMB: 8192
                )

                templateCard(
                    title: "Micro Agent Worker",
                    specs: "2 vCPU • 2 GB RAM • Shell/Web",
                    icon: "bolt.fill",
                    tint: .blue,
                    vcpu: 2,
                    ramMB: 2048
                )
            }
        }
    }

    private func templateCard(
        title: String,
        specs: String,
        icon: String,
        tint: Color,
        vcpu: Int,
        ramMB: Int
    ) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(tint)
                Spacer()
                Button("Launch") {
                    let config = RuntimeConfig(
                        name: title,
                        description: "Template: \(specs)",
                        vcpu: vcpu,
                        ramMB: ramMB
                    )
                    Task {
                        try? await runtimeManager.provision(config)
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .font(.system(size: 10, weight: .semibold))
            }

            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)

            Text(specs)
                .font(.system(size: 9.5))
                .foregroundColor(.white.opacity(0.55))
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.03))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(tint.opacity(0.25), lineWidth: 1))
        )
    }

    // MARK: - 4. Linux Tool Environment & Workspaces
    private var environmentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Linux Environment & Guest Isolation", systemImage: "macwindow")
                    .font(.system(size: 12.5, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Text(envController.status)
                    .font(.system(size: 10))
                    .foregroundColor(envController.status.contains("Connected") ? .green : .secondary)
            }

            GenieEnvironmentSettingsView()
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.02))
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.06), lineWidth: 1))
                )
        }
    }

    // MARK: - 5. Distributed Multi-Machine Compute & Calculations Engine
    private var distributedComputeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Distributed Multi-Machine Calculations", systemImage: "bolt.horizontal.circle.fill")
                    .font(.system(size: 12.5, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                if computeEngine.isComputing {
                    ProgressView()
                        .controlSize(.mini)
                    Text("Calculating...")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.cyan)
                } else {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                        Text("\(computeEngine.nodes.count) Compute Nodes")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.green)
                    }
                }
            }

            Text("Splits parallel math expressions, numerical simulations, and tensor batches across Apple Silicon performance cores, VM clones, and OrbStack/SSH nodes.")
                .font(.system(size: 10.5))
                .foregroundColor(.white.opacity(0.55))

            // Cluster node inventory strip
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(computeEngine.nodes) { node in
                    HStack(spacing: 8) {
                        Image(systemName: node.kind == .hypervisorVM ? "server.rack" : (node.kind == .linuxEnvironment ? "terminal" : "cpu"))
                            .font(.system(size: 11))
                            .foregroundColor(node.status == "Computing" ? .orange : .cyan)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(node.name)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.white)
                                .lineLimit(1)
                            Text("\(node.vcpuCount) vCPU • \(node.memoryMB) MB • \(node.tasksCompleted) done")
                                .font(.system(size: 9))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        Spacer()
                    }
                    .padding(8)
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.white.opacity(0.06), lineWidth: 1))
                }
            }

            // Action & test button
            HStack {
                Text("Total completed: \(computeEngine.totalCalculationsCompleted) calculations")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))
                Spacer()
                Button(action: {
                    Task {
                        _ = await computeEngine.executeDistributedCalculations("2^32; sqrt(1048576); sin(3.14159/2); 15% of 8500; (450 * 12) + (1800 / 4); log2(65536)")
                    }
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: "play.fill")
                        Text("Run Distributed Test Batch")
                    }
                    .font(.system(size: 10.5, weight: .medium))
                }
                .buttonStyle(.bordered)
                .disabled(computeEngine.isComputing)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.02))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.06), lineWidth: 1))
        )
    }

    // MARK: - 6. Permissions & Security Oversight
    private var securityAuditSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label("Executive Permissions Authority", systemImage: "shield.lefthalf.filled")
                    .font(.system(size: 12.5, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Toggle("Auto-Approve Safe Ops", isOn: Binding(
                    get: { permissionsAgent.autoApproveAll },
                    set: { permissionsAgent.autoApproveAll = $0 }
                ))
                .toggleStyle(.switch)
                .controlSize(.mini)
            }

            Text("All filesystem operations outside ~/Desktop, shell commands, iMessage dispatch, and system automation are audited in real time.")
                .font(.system(size: 10.5))
                .foregroundColor(.white.opacity(0.55))

            if !permissionsAgent.auditLog.isEmpty {
                VStack(spacing: 4) {
                    ForEach(permissionsAgent.auditLog.suffix(5).reversed()) { entry in
                        HStack {
                            Image(systemName: entry.status == .approved ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(entry.status == .approved ? .green : .yellow)

                            Text(entry.description)
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.85))
                                .lineLimit(1)

                            Spacer()

                            Text(entry.category.rawValue)
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(.white.opacity(0.45))
                        }
                        .padding(.vertical, 2)
                    }
                }
                .padding(8)
                .background(Color.black.opacity(0.2))
                .cornerRadius(6)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.02))
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.white.opacity(0.06), lineWidth: 1))
        )
    }
}
