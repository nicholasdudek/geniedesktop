import AppKit
import SwiftUI
import Security
import GenieAgentCore

@MainActor
final class GenieAgentWorkspaceModel: ObservableObject {
    static let shared = GenieAgentWorkspaceModel()
    @Published var current: AgentRun?
    @Published var history: [AgentRun] = []
    @Published var isRunning = false
    @Published var approval: AgentToolCall?
    @Published var error: String?
    private var approvalContinuation: CheckedContinuation<Bool, Never>?
    private var task: Task<Void, Never>?
    private let runtime = AgentRuntime()
    let store = AgentRunStore(directory: FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("Genie/AgentRuns", isDirectory: true))

    init() { reload() }
    func reload() {
        do { history = try store.runs() }
        catch { self.error = "Could not read task history: \(error.localizedDescription)" }
    }
    func start(objective: String, workspace: String, endpoint: String, model: String, key: String, autonomous: Bool = false, resume: AgentRun? = nil) {
        guard !isRunning else { return }
        do {
            guard let url = URL(string: endpoint) else { throw AgentFailure("Invalid model endpoint.") }
            let adapter = try AgentHTTPModel(endpoint: url, model: model, apiKey: key)
            var run = resume ?? AgentRun(objective: objective, workspace: workspace, model: model)
            run.model = model
            guard !run.objective.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !run.workspace.isEmpty else {
                throw AgentFailure("Choose a workspace and enter a task.")
            }
            current = run; isRunning = true; error = nil
            task = Task {
                let result = await runtime.execute(run, model: adapter, store: store, bypassApproval: autonomous, approve: { call in
                    return await self.requestApproval(call)
                }, observe: { update in
                    await self.receive(update)
                })
                current = result; isRunning = false; task = nil
                resolveApproval(false)
                reload()
            }
        } catch { self.error = error.localizedDescription }
    }
    private func receive(_ run: AgentRun) { current = run }
    private func requestApproval(_ call: AgentToolCall) async -> Bool {
        guard !Task.isCancelled else { return false }
        return await withCheckedContinuation { continuation in
            approval = call
            approvalContinuation = continuation
        }
    }
    func resolveApproval(_ allowed: Bool) {
        let continuation = approvalContinuation
        approvalContinuation = nil; approval = nil
        continuation?.resume(returning: allowed)
    }
    func stop() { task?.cancel(); resolveApproval(false) }
}

private enum GenieAgentCredential {
    static func query(_ endpoint: String) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: "com.nicholasdudek.genie.agent",
         kSecAttrAccount as String: endpoint]
    }
    static func read(_ endpoint: String) -> String {
        var q = query(endpoint)
        q[kSecReturnData as String] = true
        var result: CFTypeRef?
        guard SecItemCopyMatching(q as CFDictionary, &result) == errSecSuccess, let data = result as? Data else { return "" }
        return String(decoding: data, as: UTF8.self)
    }
    static func save(_ key: String, endpoint: String) throws {
        let q = query(endpoint)
        if key.isEmpty { SecItemDelete(q as CFDictionary); return }
        let value = [kSecValueData as String: Data(key.utf8)]
        let updated = SecItemUpdate(q as CFDictionary, value as CFDictionary)
        if updated == errSecSuccess { return }
        guard updated == errSecItemNotFound else { throw AgentFailure("Keychain update failed (\(updated)).") }
        var item = q
        item[kSecValueData as String] = Data(key.utf8)
        item[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlocked
        let status = SecItemAdd(item as CFDictionary, nil)
        guard status == errSecSuccess else { throw AgentFailure("Keychain save failed (\(status)).") }
    }
}

struct GenieAgentWorkspaceView: View {
    @ObservedObject private var agent = GenieAgentWorkspaceModel.shared
    @ObservedObject private var spaceManager = AgentVirtualSpaceManager.shared
    @AppStorage("genie.agent.endpoint") private var endpoint = "http://localhost:11434/v1/chat/completions"
    @AppStorage("genie.agent.model") private var model = ""
    @AppStorage("genie.agent.workspace") private var workspace = ""
    @AppStorage("genie.agent.autonomous") private var autonomous = false
    @State private var key = ""
    @State private var objective = ""
    @State private var showConnection = true
    @State private var showingNewSpaceAlert = false
    @State private var newSpaceName = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Genie 3.0 Agent", systemImage: "sparkles").font(.headline)
                Spacer()
                Text(agent.current?.status ?? "Ready").font(.caption).foregroundStyle(.secondary)
            }
            DisclosureGroup("Model connection", isExpanded: $showConnection) {
                VStack(spacing: 8) {
                    TextField("Chat completions endpoint", text: $endpoint)
                    TextField("Model ID", text: $model)
                    SecureField("API key (empty for local models)", text: $key)
                    HStack {
                        Button("Local Ollama") { endpoint = "http://localhost:11434/v1/chat/completions" }
                        Button("OpenAI") { endpoint = "https://api.openai.com/v1/chat/completions" }
                        Button("Save key") {
                            do { try GenieAgentCredential.save(key, endpoint: endpoint) }
                            catch { agent.error = error.localizedDescription }
                        }
                    }.font(.caption)
                    Text("Use a model that supports tools. Task messages and tool results go to this endpoint.")
                        .font(.caption).foregroundStyle(.secondary)
                }.textFieldStyle(.roundedBorder).padding(.top, 6)
            }.disabled(agent.isRunning)

            // Agent Virtual Space Selector & Environment Isolation
            HStack(spacing: 8) {
                Menu {
                    ForEach(spaceManager.spaces) { sp in
                        Button(action: {
                            spaceManager.selectSpace(id: sp.id)
                            workspace = sp.path
                        }) {
                            HStack {
                                Text(sp.name)
                                if sp.id == spaceManager.activeSpaceId {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                    Divider()
                    Button("➕ Create New Virtual Space…") {
                        newSpaceName = ""
                        showingNewSpaceAlert = true
                    }
                    Button("Choose Custom Folder…") {
                        chooseWorkspace()
                    }
                } label: {
                    HStack(spacing: 5) {
                        Image(systemName: "cpu.fill")
                            .foregroundStyle(.cyan)
                        Text(spaceManager.activeSpace?.name ?? "Select Virtual Space")
                            .font(.caption.bold())
                    }
                }
                .disabled(agent.isRunning)

                if !workspace.isEmpty {
                    Button(action: {
                        NSWorkspace.shared.open(URL(fileURLWithPath: workspace))
                    }) {
                        Image(systemName: "folder.badge.gearshape")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("Open Space Directory in Finder")
                }

                Text(workspace.isEmpty ? "No Space Selected" : workspace)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                    .help(workspace)
            }
            Toggle(isOn: $autonomous) {
                HStack(spacing: 5) {
                    Image(systemName: autonomous ? "bolt.shield.fill" : "shield")
                        .foregroundStyle(autonomous ? .orange : .secondary)
                    Text("Autonomous Mode (Bypass safety approvals)")
                        .font(.caption)
                        .foregroundStyle(autonomous ? .primary : .secondary)
                }
            }
            .toggleStyle(.checkbox)
            .disabled(agent.isRunning)
            TextField("Describe a task and how to verify it", text: $objective, axis: .vertical)
                .lineLimit(2...5).textFieldStyle(.roundedBorder).disabled(agent.isRunning)
            HStack {
                Button("Run task") {
                    agent.start(objective: objective, workspace: workspace, endpoint: endpoint, model: model, key: key, autonomous: autonomous)
                }.disabled(agent.isRunning || workspace.isEmpty || objective.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || model.isEmpty)
                if agent.isRunning { Button("Stop", role: .destructive) { agent.stop() } }
                Spacer()
                Menu("History") {
                    ForEach(agent.history) { run in
                        Button("\(run.status): \(run.objective.prefix(50))") {
                            agent.current = run
                            workspace = run.workspace
                            objective = run.objective
                            model = run.model
                        }
                    }
                }.disabled(agent.isRunning)
                if let run = agent.current, run.status != "Finished" {
                    Button("Resume") {
                        agent.start(objective: run.objective, workspace: run.workspace, endpoint: endpoint, model: model, key: key, autonomous: autonomous, resume: run)
                    }.disabled(agent.isRunning || model.isEmpty)
                }
            }
            if let error = agent.error { Text(error).font(.caption).foregroundStyle(.red).textSelection(.enabled) }
            if let call = agent.approval {
                VStack(alignment: .leading, spacing: 8) {
                    Text(["edit_file", "write_file"].contains(call.name) ? "Review file change" : (["copy_text", "paste_text"].contains(call.name) ? "Review text transfer" : "Review command")).font(.headline)
                    Text(call.name == "run_command" ? "This command runs with your Mac user permissions in the selected workspace." : "Approve this exact replacement in the selected workspace.")
                        .font(.caption)
                    ScrollView { Text(prettyArguments(call)).font(.system(.caption, design: .monospaced)).textSelection(.enabled).frame(maxWidth: .infinity, alignment: .leading) }
                        .frame(maxHeight: 180)
                    HStack {
                        Button("Approve once") { agent.resolveApproval(true) }
                        Button("Deny", role: .cancel) { agent.resolveApproval(false) }
                    }
                }.padding(10).background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
            }
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 10) {
                        ForEach(agent.current?.events ?? []) { event in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(event.kind.uppercased()).font(.caption2.bold()).foregroundStyle(.secondary)
                                Text(event.text).font(.system(.caption, design: event.kind == "assistant" ? .default : .monospaced)).textSelection(.enabled)
                            }.frame(maxWidth: .infinity, alignment: .leading).id(event.id)
                        }
                    }
                }.onChange(of: agent.current?.events.count) { _, _ in
                    if let id = agent.current?.events.last?.id { proxy.scrollTo(id, anchor: .bottom) }
                }
            }
            if let run = agent.current {
                Text("\(run.turns) turns · \(run.tokens) reported tokens · \(run.lastVerified ? "Last command succeeded" : "No successful command since last change")")
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .onAppear {
            key = GenieAgentCredential.read(endpoint)
            agent.reload()
            if workspace.isEmpty, let active = spaceManager.activeSpace {
                workspace = active.path
            }
        }
        .onChange(of: endpoint) { _, value in key = GenieAgentCredential.read(value) }
        .alert("Create Agent Virtual Space", isPresented: $showingNewSpaceAlert) {
            TextField("Space Name (e.g. Project Jarvis)", text: $newSpaceName)
            Button("Create") {
                let name = newSpaceName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !name.isEmpty {
                    let sp = spaceManager.createSpace(name: name)
                    workspace = sp.path
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Creates an isolated virtual environment directory under ~/.genie/spaces/")
        }
    }

    private func chooseWorkspace() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true; panel.canChooseFiles = false; panel.allowsMultipleSelection = false
        panel.prompt = "Use workspace"
        if panel.runModal() == .OK, let url = panel.url { workspace = url.path }
    }
    private func prettyArguments(_ call: AgentToolCall) -> String {
        guard let data = call.arguments.data(using: .utf8), let values = try? JSONDecoder().decode([String: String].self, from: data) else { return call.arguments }
        return values.keys.sorted().map { "\($0):\n\(values[$0]!)" }.joined(separator: "\n\n")
    }
}
