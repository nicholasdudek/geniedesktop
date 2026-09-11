import SwiftUI
import GenieEnvironmentKit

struct GenieEnvironmentSettingsView: View {
    @ObservedObject private var controller = GenieEnvironmentController.shared
    @AppStorage(PrefKey.utmEnvironmentEnabled) private var enabled = false
    @AppStorage(PrefKey.environmentKind) private var kind = "orbstack"
    @AppStorage(PrefKey.environmentMachine) private var machine = "genie"
    @AppStorage(PrefKey.environmentSSHHost) private var host = ""
    @AppStorage(PrefKey.environmentSSHUser) private var user = ""
    @AppStorage(PrefKey.environmentSSHKey) private var key = ""
    @State private var newWorkspace = ""
    @State private var selectedTools: Set<String> = ["browser", "filesystem", "shell", "python"]
    static let toolFamilies = ["browser", "filesystem", "shell", "python"]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Toggle("Use a Linux environment for AI tools", isOn: $enabled)
                .disabled(!GenieCapabilities.canSpawnSubprocesses)
            Text("Browser, code, and files run inside Linux. Jobs continue if Genie closes.")
                .font(.caption).foregroundStyle(.secondary)

            Picker("Runtime Engine", selection: $kind) {
                Text("iOS Simulators (Lite)").tag("simulator")
                Text("Hypervisor").tag("orbstack")
                Text("SSH").tag("ssh")
            }
            .pickerStyle(.segmented)

            if kind == "simulator" {
                HStack(spacing: 8) {
                    Image(systemName: "iphone.gen3")
                        .foregroundStyle(Color.accentColor)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Native Apple Silicon iOS Simulator Grid")
                            .font(.caption.bold())
                        Text("Multi-chat parallel execution via simctl. Zero RAM bloat (<200MB) & sub-second execution.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(8)
                .background(Color.secondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            } else if kind == "ssh" {
                TextField("Host (for example 192.168.64.3)", text: $host).textFieldStyle(.roundedBorder)
                TextField("User", text: $user, prompt: Text(NSUserName())).textFieldStyle(.roundedBorder)
                TextField("Private key", text: $key, prompt: Text("~/.ssh/genie_env_ed25519")).textFieldStyle(.roundedBorder)
            } else {
                TextField("Machine name", text: $machine, prompt: Text("genie")).textFieldStyle(.roundedBorder)
            }

            HStack {
                Button("Connect") { Task { await controller.connect() } }
                Button("Refresh Jobs") { Task { await controller.refresh() } }
            }
            .disabled(controller.busy || !GenieCapabilities.canSpawnSubprocesses)

            Text("Set up the guest once with: sudo bash install.sh inside Linux.")
                .font(.caption2).foregroundStyle(.secondary)

            Divider()

            Text("Workspaces").font(.caption.bold())
            Text("Each keeps its own files and job history in Linux and cannot read the others.")
                .font(.caption2).foregroundStyle(.secondary)

            ForEach(controller.workspaces) { workspace in
                HStack {
                    Image(systemName: workspace.id == controller.environmentID ? "largecircle.fill.circle" : "circle")
                        .foregroundStyle(workspace.id == controller.environmentID ? Color.accentColor : .secondary)
                    VStack(alignment: .leading) {
                        Text(workspace.name).font(.caption.bold())
                        Text(workspace.tools.sorted().joined(separator: ", "))
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Use") { Task { await controller.select(workspace.id) } }
                        .disabled(workspace.id == controller.environmentID)
                    Button(role: .destructive) { Task { await controller.removeWorkspace(workspace.id) } }
                        label: { Image(systemName: "trash") }
                }
                .contentShape(Rectangle())
                .onTapGesture { Task { await controller.select(workspace.id) } }
            }

            HStack {
                TextField("New workspace name", text: $newWorkspace).textFieldStyle(.roundedBorder)
                Button("Create") {
                    Task {
                        await controller.createWorkspace(named: newWorkspace, tools: selectedTools.sorted())
                        newWorkspace = ""
                    }
                }
                .disabled(controller.busy || newWorkspace.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            HStack(spacing: 12) {
                ForEach(Self.toolFamilies, id: \.self) { family in
                    Toggle(family, isOn: Binding(
                        get: { selectedTools.contains(family) },
                        set: { on in
                            if on { selectedTools.insert(family) } else { selectedTools.remove(family) }
                        }))
                    .toggleStyle(.checkbox)
                }
            }
            .font(.caption2)

            if controller.busy { ProgressView().controlSize(.small) }
            Text(controller.status).font(.caption).textSelection(.enabled)

            ForEach(controller.jobs.prefix(10), id: \.formatted) { job in
                HStack {
                    VStack(alignment: .leading) {
                        Text(job["tool"]?.string ?? "Job").font(.caption.bold())
                        Text(job["state"]?.string ?? "Unknown").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    if ["queued", "running"].contains(job["state"]?.string ?? ""), let id = job["id"]?.string {
                        Button("Stop") { Task { await controller.cancel(jobID: id) } }
                    }
                }
                DisclosureGroup("Result") {
                    Text(job["result"]?.formatted ?? "Waiting for result")
                        .font(.system(size: 10, design: .monospaced)).textSelection(.enabled)
                }
            }
        }
        .task {
            await controller.loadWorkspaces()
            await controller.refresh()
        }
    }
}
