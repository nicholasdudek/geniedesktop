import Foundation

@MainActor
class GenieCommandCenter: ObservableObject {
    static let shared = GenieCommandCenter()
    
    func execute(_ intent: String) async {
        let isHeavy = intent.contains("analyze") || intent.contains("spark")
        let config = RuntimeConfig(
            name: "Task-Runtime",
            description: intent,
            vcpu: isHeavy ? 8 : 2,
            ramMB: isHeavy ? 16384 : 4096
        )
        
        do {
            try await RuntimeManager.shared.provision(config)
            try await inject(intent: intent, id: config.id)
        } catch {
            print("Execution Error: \(error)")
        }
    }
    
    private func inject(intent: String, id: String) async throws {
        let path = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Genie/shared/task_\(id).sh").path
        try "#!/bin/bash\necho 'Running: \(intent)'".write(toFile: path, atomically: true, encoding: .utf8)
    }
}
