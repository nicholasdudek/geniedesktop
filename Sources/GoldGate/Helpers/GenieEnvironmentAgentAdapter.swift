import Foundation
import GenieAgentCore
import GenieEnvironmentKit

/// Bridges the agent's `vm_*` tools to the real hypervisor in GenieEnvironmentKit.
///
/// GenieAgentCore is a standalone package that still builds for iOS and carries no
/// dependencies, while GenieEnvironmentKit is macOS-only — so, exactly like
/// `GenieActivityLogAdapter`, this is the one place the two are connected, and it
/// lives in the app rather than in either package.
///
/// The agent reaches VMs through these typed tools instead of shelling `genie-env`
/// through `run_command`. That keeps VM work out of the shell's blast radius:
/// `run_command` is withheld entirely from Genie Lite and carries a blanket approval
/// gate, so routing VM calls through it would make "boot a VM" indistinguishable
/// from any other command at the policy layer.
struct GenieEnvironmentAgentAdapter: AgentEnvironmentProvider {
    private let backend = UTMBackend()

    private func uuid(_ raw: String) throws -> UUID {
        guard let id = UUID(uuidString: raw.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw AgentFailure("Not a VM identifier: \(raw). Call vm_list for the available IDs.")
        }
        return id
    }

    func listEnvironments() async throws -> String {
        let output = try await backend.list()
        return output.isEmpty ? "No virtual machines are registered." : output
    }

    func environmentStatus(id: String) async throws -> String {
        try await backend.status(vmID: uuid(id))
    }

    func startEnvironment(id: String) async throws -> String {
        let vmID = try uuid(id)
        try await backend.start(vmID: vmID)
        return "Virtual machine \(vmID.uuidString) started."
    }

    func cloneEnvironment(templateID: String, name: String) async throws -> String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw AgentFailure("Give the new virtual machine a name.") }
        let created = try await backend.clone(templateID: uuid(templateID), name: trimmed)
        return "Cloned to \(trimmed) — \(created.uuidString). It is not running; call vm_start to boot it."
    }
}
