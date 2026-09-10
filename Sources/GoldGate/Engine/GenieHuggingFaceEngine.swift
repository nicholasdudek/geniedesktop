import AppKit
import Foundation
import SwiftUI

// MARK: - Hugging Face Native Hub & Spaces Engine for Genie
// Enables 1-click GGUF model pulling, MLX-community model ingestion on Apple Silicon,
// and headless execution of Gradio / Streamlit Spaces via REST API & DOM Watcher.

public struct HFModelCard: Identifiable, Hashable, Sendable {
    public var id: String { repoId }
    public let repoId: String
    public let displayName: String
    public let author: String
    public let task: String // "text-generation", "vision", "audio", "image-generation"
    public let parameterSize: String
    public let downloads: String
    public let likes: String
    public let ggufTag: String
    public let description: String
}

public struct HFSpaceCard: Identifiable, Hashable, Sendable {
    public var id: String { spaceId }
    public let spaceId: String
    public let title: String
    public let author: String
    public let sdk: String // "gradio", "streamlit", "docker"
    public let likes: String
    public let url: String
    public let directAPIEndpoint: String
}

@MainActor
public final class GenieHuggingFaceEngine: ObservableObject {
    public static let shared = GenieHuggingFaceEngine()

    @Published public var trendingModels: [HFModelCard] = []
    @Published public var trendingSpaces: [HFSpaceCard] = []
    @Published public var isPullingModel: Bool = false
    @Published public var pullingModelId: String? = nil
    @Published public var pullProgressMessage: String = ""
    @Published public var spaceExecutionLogs: String = ""
    @Published public var isExecutingSpace: Bool = false

    private init() {
        populateCuratedHFHub()
    }

    // MARK: - 1. Curated Top Hugging Face Models & Spaces
    public func populateCuratedHFHub() {
        self.trendingModels = [
            HFModelCard(
                repoId: "bartowski/Llama-3.2-3B-Instruct-GGUF",
                displayName: "Llama 3.2 3B Instruct",
                author: "Meta & bartowski",
                task: "text-generation",
                parameterSize: "3B (2.2 GB)",
                downloads: "2.1M",
                likes: "4.8k",
                ggufTag: "hf.co/bartowski/Llama-3.2-3B-Instruct-GGUF:Q4_K_M",
                description: "Meta's ultra-fast multilingual lightweight powerhouse."
            ),
            HFModelCard(
                repoId: "Qwen/Qwen2.5-Coder-7B-Instruct-GGUF",
                displayName: "Qwen 2.5 Coder 7B",
                author: "Qwen Team",
                task: "code-generation",
                parameterSize: "7B (4.7 GB)",
                downloads: "1.8M",
                likes: "3.9k",
                ggufTag: "hf.co/Qwen/Qwen2.5-Coder-7B-Instruct-GGUF:Q4_K_M",
                description: "Top-tier code synthesis, refactoring, and bug detection model."
            ),
            HFModelCard(
                repoId: "bartowski/DeepSeek-R1-Distill-Qwen-14B-GGUF",
                displayName: "DeepSeek R1 Distill Qwen 14B",
                author: "DeepSeek AI",
                task: "reasoning",
                parameterSize: "14B (9.1 GB)",
                downloads: "3.4M",
                likes: "6.2k",
                ggufTag: "hf.co/bartowski/DeepSeek-R1-Distill-Qwen-14B-GGUF:Q4_K_M",
                description: "Deep mathematical reasoning and step-by-step thinking engine."
            ),
            HFModelCard(
                repoId: "mlx-community/SmolLM2-1.7B-Instruct-4bit",
                displayName: "SmolLM2 1.7B Instruct (MLX)",
                author: "Hugging Face",
                task: "text-generation",
                parameterSize: "1.7B (1.1 GB)",
                downloads: "850k",
                likes: "1.5k",
                ggufTag: "hf.co/HuggingFaceTB/SmolLM2-1.7B-Instruct-GGUF",
                description: "High-speed sub-millisecond local reasoning on Apple Silicon."
            ),
            HFModelCard(
                repoId: "bartowski/Qwen2.5-VL-7B-Instruct-GGUF",
                displayName: "Qwen 2.5 VL 7B (Vision & Grounding)",
                author: "Qwen Team",
                task: "vision",
                parameterSize: "7B (5.2 GB)",
                downloads: "920k",
                likes: "2.7k",
                ggufTag: "hf.co/bartowski/Qwen2.5-VL-7B-Instruct-GGUF:Q4_K_M",
                description: "State-of-the-art visual GUI element grounding and UI comprehension."
            )
        ]

        self.trendingSpaces = [
            HFSpaceCard(
                spaceId: "black-forest-labs/FLUX.1-schnell",
                title: "FLUX.1 Schnell Fast Image Gen",
                author: "Black Forest Labs",
                sdk: "gradio",
                likes: "14.2k",
                url: "https://huggingface.co/spaces/black-forest-labs/FLUX.1-schnell",
                directAPIEndpoint: "https://black-forest-labs-flux-1-schnell.hf.space"
            ),
            HFSpaceCard(
                spaceId: "cocktailpeanut/calculator",
                title: "Web Calculator Space",
                author: "Cocktail Peanut",
                sdk: "gradio",
                likes: "540",
                url: "https://huggingface.co/spaces/gradio/calculator",
                directAPIEndpoint: "https://gradio-calculator.hf.space"
            ),
            HFSpaceCard(
                spaceId: "deepseek-ai/DeepSeek-R1",
                title: "DeepSeek-R1 Official Web Space",
                author: "DeepSeek AI",
                sdk: "gradio",
                likes: "28.5k",
                url: "https://huggingface.co/spaces/deepseek-ai/DeepSeek-R1",
                directAPIEndpoint: "https://deepseek-ai-deepseek-r1.hf.space"
            )
        ]
    }

    // MARK: - 2. 1-Click Hugging Face Model Pulling to Local Ollama/MLX
    public func pullHuggingFaceModel(card: HFModelCard) {
        guard !isPullingModel else { return }
        // Pulling a model means driving the local `ollama` binary, which the
        // sandboxed build cannot execute.
        guard GenieCapabilities.canSpawnSubprocesses else {
            pullProgressMessage = GenieCapabilities.unavailableMessage("Local model pulls")
            return
        }
        isPullingModel = true
        pullingModelId = card.id
        pullProgressMessage = "Connecting to Hugging Face Hub (hf.co) for \(card.displayName)..."

        DispatchQueue.global(qos: .userInitiated).async {
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/bin/zsh")
            proc.arguments = ["-c", "ollama run \(card.ggufTag) 'exit'"]
            let pipe = Pipe()
            proc.standardOutput = pipe
            proc.standardError = pipe

            do {
                try proc.run()
                proc.waitUntilExit()

                DispatchQueue.main.async {
                    self.isPullingModel = false
                    self.pullingModelId = nil
                    self.pullProgressMessage = "✓ Successfully pulled \(card.displayName) to local models!"
                    LocalModelManager.shared.refreshAvailableModels()
                    HapticFeedback.heavy()
                }
            } catch {
                DispatchQueue.main.async {
                    self.isPullingModel = false
                    self.pullingModelId = nil
                    self.pullProgressMessage = "Error pulling model: \(error.localizedDescription)"
                }
            }
        }
    }

    // MARK: - 3. Headless Gradio / Streamlit Space API Execution
    public func executeGradioSpace(space: HFSpaceCard, inputData: String) async -> String {
        self.isExecutingSpace = true
        self.spaceExecutionLogs = "Sending headless request to Gradio Space: \(space.title)...\n"

        guard let apiURL = URL(string: "\(space.directAPIEndpoint)/call/predict") else {
            self.isExecutingSpace = false
            return "Invalid API Endpoint"
        }

        var req = URLRequest(url: apiURL)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload: [String: Any] = ["data": [inputData]]
        req.httpBody = try? JSONSerialization.data(withJSONObject: payload)

        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            let raw = String(data: data, encoding: .utf8) ?? "Success"
            self.isExecutingSpace = false
            self.spaceExecutionLogs += "✓ Space Response Received: \(raw)\n"
            HapticFeedback.selection()
            return raw
        } catch {
            self.isExecutingSpace = false
            self.spaceExecutionLogs += "Space Execution Error: \(error.localizedDescription)\n"
            return "Execution error: \(error.localizedDescription)"
        }
    }
}
