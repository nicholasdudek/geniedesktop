import Foundation
import SwiftUI

@MainActor
class RuntimeManager: ObservableObject {
    static let shared = RuntimeManager()
    @Published var runtimes: [RuntimeInstance] = []

    private static let defaultsKey = "genie.runtimes"

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.defaultsKey),
           let saved = try? JSONDecoder().decode([RuntimeInstance].self, from: data) {
            runtimes = saved
        }
    }

    func provision(_ config: RuntimeConfig) async throws {
        try await GenieHypervisorEngine.shared.spawn(config)
        runtimes.append(RuntimeInstance(id: config.id, config: config, status: .active))
        save()
    }
    
    /// Creates a runtime from the full `RuntimeConfiguration` model (used by RuntimeConfiguratorView).
    func createRuntime(config: RuntimeConfiguration) async throws {
        try await provision(config.toRuntimeConfig())
    }

    func destroy(_ id: String) async {
        try? await GenieHypervisorEngine.shared.stop(id)
        runtimes.removeAll { $0.id == id }
        save()
    }
    
    private func save() {
        if let data = try? JSONEncoder().encode(runtimes) {
            UserDefaults.standard.set(data, forKey: Self.defaultsKey)
        }
    }
}
