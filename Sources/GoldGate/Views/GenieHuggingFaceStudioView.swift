import AppKit
import SwiftUI

// MARK: - Genie Hugging Face Studio & Spaces Hub View
public struct GenieHuggingFaceStudioView: View {
    @ObservedObject var hfEngine = GenieHuggingFaceEngine.shared
    @ObservedObject var localModels = LocalModelManager.shared

    @State private var selectedTab: HFHubSubTab = .models
    @State private var customRepoInput: String = ""
    @State private var searchFilter: String = ""
    @State private var copiedToast: String? = nil
    @State private var spaceInputPrompt: String = "Calculate (45 * 2) + sqrt(144)"
    @State private var activeRunningSpaceId: String? = nil

    enum HFHubSubTab: String, CaseIterable, Identifiable {
        case models = "Models & GGUF Hub"
        case spaces = "Spaces & Gradio Apps"
        case directAPI = "Zero-Cursor Space API"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .models: return "cube.fill"
            case .spaces: return "sparkles.tv.fill"
            case .directAPI: return "bolt.horizontal.fill"
            }
        }
    }

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // ── Top Header & Hub Summary ──
            headerBanner

            Divider().opacity(0.35)

            // ── Sub-navigation Bar ──
            subNavigationBar

            Divider().opacity(0.35)

            // ── Sub-tab View Body ──
            ZStack {
                switch selectedTab {
                case .models:
                    modelsGGUFView
                case .spaces:
                    spacesGradioView
                case .directAPI:
                    zeroCursorSpaceAPIVIEW
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Color.black.opacity(0.20))
        .overlay(alignment: .top) {
            if let toast = copiedToast {
                Text(toast)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.black.opacity(0.85)))
                    .overlay(Capsule().stroke(Color.white.opacity(0.25), lineWidth: 0.5))
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, 12)
            }
        }
    }

    // MARK: - Header Banner
    private var headerBanner: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.yellow.opacity(0.8), Color.orange.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 36, height: 36)

                Text("🤗")
                    .font(.system(size: 20))
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("Hugging Face Hub & Spaces Studio")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("Native GGUF & Gradio Bridge")
                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.yellow.opacity(0.15)))
                }

                Text("1-Click GGUF download to local Apple Silicon RAM (\(LocalModelManager.detectedRAMString)) & headless Gradio UI execution.")
                    .font(.system(size: 10.5))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Status message
            if !hfEngine.pullProgressMessage.isEmpty {
                Text(hfEngine.pullProgressMessage)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(.green)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.green.opacity(0.12)))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.28))
    }

    // MARK: - Sub Navigation Bar
    private var subNavigationBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 4) {
                ForEach(HFHubSubTab.allCases) { tab in
                    let isSel = (selectedTab == tab)
                    Button(action: {
                        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                            selectedTab = tab
                        }
                        HapticFeedback.selection()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: tab.icon)
                                .font(.system(size: 11, weight: .semibold))
                            Text(tab.rawValue)
                                .font(.system(size: 11, weight: isSel ? .bold : .medium, design: .rounded))
                        }
                        .foregroundColor(isSel ? .white : .secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 5)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(isSel ? Color.white.opacity(0.18) : Color.clear)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .strokeBorder(isSel ? Color.white.opacity(0.25) : Color.clear, lineWidth: 0.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(2)
            .background(RoundedRectangle(cornerRadius: 7).fill(Color.black.opacity(0.20)))

            Spacer()

            // Quick Pull by Custom Tag
            HStack(spacing: 6) {
                TextField("hf.co/username/repo:Q4_K_M...", text: $customRepoInput)
                    .textFieldStyle(.plain)
                    .font(.system(size: 10.5, design: .monospaced))
                    .foregroundColor(.white)
                    .frame(width: 220)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.06)))

                Button(action: {
                    let tag = customRepoInput.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !tag.isEmpty else { return }
                    let card = HFModelCard(
                        repoId: tag,
                        displayName: tag,
                        author: "Custom HF",
                        task: "text-generation",
                        parameterSize: "GGUF",
                        downloads: "-",
                        likes: "-",
                        ggufTag: tag.starts(with: "hf.co/") ? tag : "hf.co/\(tag)",
                        description: "Custom GGUF pull from Hugging Face Hub."
                    )
                    hfEngine.pullHuggingFaceModel(card: card)
                    HapticFeedback.selection()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.circle.fill")
                        Text("Pull GGUF")
                    }
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        LinearGradient(
                            colors: [Color.orange.opacity(0.8), Color.yellow.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.18))
    }

    // MARK: - 1. Models & GGUF Hub View
    private var modelsGGUFView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Popular Apple Silicon Quantized Models (Direct Pull)")
                    .font(.system(size: 12.5, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                ForEach(hfEngine.trendingModels) { model in
                    modelCardRow(model: model)
                }
            }
            .padding(16)
        }
    }

    private func modelCardRow(model: HFModelCard) -> some View {
        HStack(spacing: 14) {
            // Task Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 42, height: 42)
                Image(systemName: iconForTask(model.task))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.yellow)
            }

            // Info
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(model.displayName)
                        .font(.system(size: 12.5, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text(model.parameterSize)
                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        .foregroundColor(.cyan)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1.5)
                        .background(Capsule().fill(Color.cyan.opacity(0.12)))
                }

                Text(model.description)
                    .font(.system(size: 10.5))
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                HStack(spacing: 10) {
                    Text("By \(model.author)")
                        .font(.system(size: 9.5))
                        .foregroundColor(.secondary)
                    Text("↓ \(model.downloads)")
                        .font(.system(size: 9.5, weight: .semibold))
                        .foregroundColor(.secondary)
                    Text("♥ \(model.likes)")
                        .font(.system(size: 9.5, weight: .semibold))
                        .foregroundColor(.pink.opacity(0.8))
                }
            }

            Spacer()

            // Pull Button
            Button(action: {
                hfEngine.pullHuggingFaceModel(card: model)
                HapticFeedback.heavy()
            }) {
                HStack(spacing: 4) {
                    if hfEngine.pullingModelId == model.id {
                        ProgressView()
                            .scaleEffect(0.6)
                            .frame(width: 12, height: 12)
                    } else {
                        Image(systemName: "arrow.down.to.line.compact")
                    }
                    Text(hfEngine.pullingModelId == model.id ? "Pulling..." : "Pull to RAM")
                }
                .font(.system(size: 10.5, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    LinearGradient(
                        colors: [Color.yellow.opacity(0.8), Color.orange.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(6)
            }
            .buttonStyle(.plain)
            .disabled(hfEngine.isPullingModel)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.04)))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.white.opacity(0.08), lineWidth: 0.75))
    }

    // MARK: - 2. Spaces & Gradio Apps View
    private var spacesGradioView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Featured Hugging Face Spaces & Web Applications")
                    .font(.system(size: 12.5, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                ForEach(hfEngine.trendingSpaces) { space in
                    spaceCardRow(space: space)
                }
            }
            .padding(16)
        }
    }

    private func spaceCardRow(space: HFSpaceCard) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 42, height: 42)
                Image(systemName: "sparkles.tv.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.orange)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(space.title)
                        .font(.system(size: 12.5, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text(space.sdk.uppercased())
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.green)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1.5)
                        .background(Capsule().fill(Color.green.opacity(0.12)))
                }

                Text(space.spaceId)
                    .font(.system(size: 10.5, design: .monospaced))
                    .foregroundColor(.secondary)

                Text("♥ \(space.likes) likes • Ready for Zero-Cursor Headless Execution")
                    .font(.system(size: 9.5))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Open in Live Browser Cradle
            Button(action: {
                if let url = URL(string: space.url) {
                    MiniBrowserManager.shared.currentURL = url
                    MiniBrowserManager.shared.activeWebView?.load(URLRequest(url: url))
                    NotificationCenter.default.post(name: NSNotification.Name("NexusOpenMiniBrowser"), object: nil)
                    showToast("🌐 Opened \(space.title) in Live Browser Cradle!")
                    HapticFeedback.selection()
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "globe")
                    Text("Open Space")
                }
                .font(.system(size: 10.5, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.10)))
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.04)))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.white.opacity(0.08), lineWidth: 0.75))
    }

    // MARK: - 3. Zero-Cursor Space API Execution View
    private var zeroCursorSpaceAPIVIEW: some View {
        VStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Direct Headless Gradio Space Execution (No Cursor Needed)")
                    .font(.system(size: 12.5, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("Dispatches parameters directly to the Hugging Face Space endpoint and captures JSON/DOM output in sub-50ms.")
                    .font(.system(size: 10.5))
                    .foregroundColor(.secondary)

                HStack(spacing: 8) {
                    TextField("Enter input payload / math expression...", text: $spaceInputPrompt)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.06)))

                    Button(action: {
                        if let space = hfEngine.trendingSpaces.first(where: { $0.spaceId.contains("calculator") }) ?? hfEngine.trendingSpaces.first {
                            activeRunningSpaceId = space.spaceId
                            Task {
                                _ = await hfEngine.executeGradioSpace(space: space, inputData: spaceInputPrompt)
                                await MainActor.run {
                                    activeRunningSpaceId = nil
                                }
                            }
                        }
                    }) {
                        HStack(spacing: 4) {
                            if activeRunningSpaceId != nil {
                                ProgressView().scaleEffect(0.6).frame(width: 12, height: 12)
                            } else {
                                Image(systemName: "bolt.fill")
                            }
                            Text("Dispatch API")
                        }
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.yellow)
                        .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.04)))
            .padding(.horizontal, 16)
            .padding(.top, 12)

            // Execution Logs
            VStack(alignment: .leading, spacing: 6) {
                Text("API RESPONSE & STREAM LOGS")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.secondary)

                ScrollView {
                    Text(hfEngine.spaceExecutionLogs.isEmpty ? "Ready. Click 'Dispatch API' to test headless Gradio Space execution." : hfEngine.spaceExecutionLogs)
                        .font(.system(size: 10.5, design: .monospaced))
                        .foregroundColor(.white.opacity(0.85))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(10)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.40))
                .cornerRadius(6)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.04)))
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }

    private func iconForTask(_ task: String) -> String {
        switch task {
        case "code-generation": return "curlybraces"
        case "vision": return "eye.fill"
        case "reasoning": return "brain.head.profile"
        default: return "bubble.left.and.text.bubble.right.fill"
        }
    }

    private func showToast(_ msg: String) {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            copiedToast = msg
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation(.easeOut(duration: 0.25)) {
                if copiedToast == msg { copiedToast = nil }
            }
        }
    }
}
