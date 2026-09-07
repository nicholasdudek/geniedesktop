import AppKit
import SwiftUI

// MARK: - Genie Codebase AI Training & Evolution Studio View
public struct GenieCodebaseEvolutionStudioView: View {
    @ObservedObject var evolver = GenieCodebaseEvolutionEngine.shared
    @ObservedObject var localModels = LocalModelManager.shared

    @State private var selectedTab: StudioSubTab = .evolution
    @State private var searchQuery: String = ""
    @State private var copiedToast: String? = nil
    @State private var verifyingPatchId: UUID? = nil
    @State private var verificationResults: [UUID: String] = [:]

    enum StudioSubTab: String, CaseIterable, Identifiable {
        case evolution = "Evolution Matrix"
        case training = "Model Fine-Tuning"
        case corpus = "Corpus Files"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .evolution: return "bolt.shield.fill"
            case .training: return "cpu.fill"
            case .corpus: return "folder.fill"
            }
        }
    }

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // ── Top Header & Stats Dashboard ──
            headerStatsDashboard

            Divider().opacity(0.35)

            // ── Studio Navigation Bar ──
            studioNavigationBar

            Divider().opacity(0.35)

            // ── Main Content Body ──
            ZStack {
                switch selectedTab {
                case .evolution:
                    evolutionMatrixView
                case .training:
                    trainingTelemetryView
                case .corpus:
                    corpusFilesListView
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
        .onAppear {
            if evolver.recommendations.isEmpty {
                evolver.analyzeAndEvolveCodebase()
            }
        }
    }

    // MARK: - Header & Stats Dashboard
    private var headerStatsDashboard: some View {
        HStack(spacing: 16) {
            // Title & Engine Badge
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.purple.opacity(0.6), Color.blue.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 34, height: 34)

                    Image(systemName: "wand.and.stars")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("Codebase AI Evolution Studio")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text(evolver.customTrainedModelTag)
                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                            .foregroundColor(.cyan)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.cyan.opacity(0.15)))
                            .overlay(Capsule().stroke(Color.cyan.opacity(0.3), lineWidth: 0.5))
                    }

                    Text("Fine-tune custom LLMs on Genie & synthesize zero-allocation Swift/Metal patches")
                        .font(.system(size: 10.5, weight: .regular))
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // Metrics Counters
            HStack(spacing: 12) {
                metricCounterCard(
                    title: "Indexed Files",
                    value: "\(evolver.indexedFiles.count)",
                    icon: "doc.text.fill",
                    color: .blue
                )

                metricCounterCard(
                    title: "Corpus Tokens",
                    value: "\(formatTokens(evolver.totalTokensEstimated))",
                    icon: "character.book.closed.fill",
                    color: .purple
                )

                metricCounterCard(
                    title: "Active Loss",
                    value: String(format: "%.3f", evolver.currentLoss),
                    icon: "chart.line.downtrend.xyaxis",
                    color: .green
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.black.opacity(0.28))
    }

    private func metricCounterCard(title: String, value: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 1) {
                Text(title.uppercased())
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.06)))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.white.opacity(0.10), lineWidth: 0.5))
    }

    // MARK: - Navigation Bar
    private var studioNavigationBar: some View {
        HStack(spacing: 12) {
            // Sub-Tab Switcher
            HStack(spacing: 4) {
                ForEach(StudioSubTab.allCases) { tab in
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

            // Quick Action Buttons
            HStack(spacing: 8) {
                // Re-scan
                Button(action: {
                    evolver.scanAndIndexCodebase()
                    HapticFeedback.selection()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .rotationEffect(.degrees(evolver.isIndexing ? 360 : 0))
                            .animation(evolver.isIndexing ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: evolver.isIndexing)
                        Text(evolver.isIndexing ? "Indexing..." : "Scan Corpus")
                    }
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.08)))
                    .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color.white.opacity(0.12), lineWidth: 0.5))
                }
                .buttonStyle(.plain)
                .disabled(evolver.isIndexing)

                // Synthesize Patches
                Button(action: {
                    evolver.analyzeAndEvolveCodebase()
                    HapticFeedback.selection()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "wand.and.rays")
                        Text(evolver.isAnalyzingCodebase ? "Analyzing..." : "Evolve Code")
                    }
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        LinearGradient(
                            colors: [Color.purple.opacity(0.7), Color.indigo.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
                .disabled(evolver.isAnalyzingCodebase)

                // Train Custom Model
                Button(action: {
                    evolver.startLocalTraining()
                    selectedTab = .training
                    HapticFeedback.heavy()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "play.fill")
                        Text(evolver.isTraining ? "Training..." : "Start Fine-Tuning")
                    }
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(
                        LinearGradient(
                            colors: [Color.green.opacity(0.8), Color.teal.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(6)
                    .shadow(color: Color.green.opacity(0.3), radius: 4, y: 1)
                }
                .buttonStyle(.plain)
                .disabled(evolver.isTraining)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.18))
    }

    // MARK: - 1. Evolution Matrix View
    private var evolutionMatrixView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                // Header Banner
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Autonomous Code Optimization & Architectural Patches")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("Synthesized by \(evolver.customTrainedModelTag) to maintain <35 MB RAM footprint and 120 FPS ProMotion fluidity.")
                            .font(.system(size: 10.5))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.bottom, 4)

                // Recommendation Cards
                ForEach(evolver.recommendations) { rec in
                    evolutionRecommendationCard(rec: rec)
                }
            }
            .padding(16)
        }
    }

    private func evolutionRecommendationCard(rec: CodeEvolutionRecommendation) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header: Category, Target File & Estimated Speedup
            HStack {
                Text(rec.category.uppercased())
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.purple)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 2.5)
                    .background(Capsule().fill(Color.purple.opacity(0.15)))

                Text((rec.targetFilePath as NSString).lastPathComponent)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)

                Spacer()

                Text(rec.estimatedSpeedup)
                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.green.opacity(0.12)))
                    .overlay(Capsule().stroke(Color.green.opacity(0.25), lineWidth: 0.5))
            }

            Text(rec.title)
                .font(.system(size: 12.5, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text(rec.rationale)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
                .lineLimit(2)

            // Diff Snippets
            VStack(spacing: 6) {
                // Original
                HStack(alignment: .top, spacing: 8) {
                    Text("-")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.red)
                    Text(rec.originalSnippet)
                        .font(.system(size: 10.5, design: .monospaced))
                        .foregroundColor(.red.opacity(0.85))
                    Spacer()
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.red.opacity(0.08)))
                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color.red.opacity(0.15), lineWidth: 0.5))

                // Proposed
                HStack(alignment: .top, spacing: 8) {
                    Text("+")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.green)
                    Text(rec.proposedEvolvedSnippet)
                        .font(.system(size: 10.5, design: .monospaced))
                        .foregroundColor(.green.opacity(0.95))
                    Spacer()
                }
                .padding(8)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.green.opacity(0.08)))
                .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color.green.opacity(0.15), lineWidth: 0.5))
            }

            // Bottom Actions & Verification
            HStack {
                if let status = verificationResults[rec.id] {
                    Text(status)
                        .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                        .foregroundColor(.green)
                }

                Spacer()

                // Copy Snippet
                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(rec.proposedEvolvedSnippet, forType: .string)
                    showToast("📋 Copied Evolved Snippet to Clipboard!")
                    HapticFeedback.selection()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "doc.on.doc")
                        Text("Copy Snippet")
                    }
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(RoundedRectangle(cornerRadius: 5).fill(Color.white.opacity(0.08)))
                }
                .buttonStyle(.plain)

                // Apply & Verify
                Button(action: {
                    verifyingPatchId = rec.id
                    HapticFeedback.selection()
                    Task {
                        let res = await evolver.applyEvolutionPatch(rec: rec)
                        await MainActor.run {
                            verificationResults[rec.id] = res.message
                            verifyingPatchId = nil
                            showToast(res.message)
                            HapticFeedback.heavy()
                        }
                    }
                }) {
                    HStack(spacing: 4) {
                        if verifyingPatchId == rec.id {
                            ProgressView()
                                .scaleEffect(0.6)
                                .frame(width: 12, height: 12)
                        } else {
                            Image(systemName: "checkmark.seal.fill")
                        }
                        Text(verifyingPatchId == rec.id ? "Building & Verifying..." : "Apply & Verify")
                    }
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4.5)
                    .background(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(5)
                }
                .buttonStyle(.plain)
                .disabled(verifyingPatchId != nil)
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.04)))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.white.opacity(0.08), lineWidth: 0.75))
    }

    // MARK: - 2. Training Telemetry View
    private var trainingTelemetryView: some View {
        VStack(spacing: 12) {
            // Training Gauge Cards
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("TRAINING PROGRESS")
                        .font(.system(size: 8.5, weight: .bold))
                        .foregroundColor(.secondary)
                    HStack {
                        ProgressView(value: evolver.trainingProgress)
                            .progressViewStyle(.linear)
                            .tint(.green)
                        Text("\(Int(evolver.trainingProgress * 100))%")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                    }
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.05)))
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5))

                VStack(alignment: .leading, spacing: 6) {
                    Text("CURRENT EPOCH")
                        .font(.system(size: 8.5, weight: .bold))
                        .foregroundColor(.secondary)
                    HStack(spacing: 4) {
                        Image(systemName: "repeat")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.cyan)
                        Text("Epoch \(evolver.currentEpoch) of 3")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.05)))
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5))

                VStack(alignment: .leading, spacing: 6) {
                    Text("CROSS-ENTROPY LOSS")
                        .font(.system(size: 8.5, weight: .bold))
                        .foregroundColor(.secondary)
                    HStack(spacing: 4) {
                        Image(systemName: "chart.line.downtrend.xyaxis")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.green)
                        Text(String(format: "%.4f", evolver.currentLoss))
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.green)
                    }
                }
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.05)))
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5))
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            // Terminal Logs Readout Card
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    HStack(spacing: 6) {
                        Circle().fill(Color.red.opacity(0.8)).frame(width: 8, height: 8)
                        Circle().fill(Color.yellow.opacity(0.8)).frame(width: 8, height: 8)
                        Circle().fill(Color.green.opacity(0.8)).frame(width: 8, height: 8)
                        Text("Training Process & Hardware Telemetry (Apple Silicon)")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    // Export Dataset
                    Button(action: {
                        if let url = evolver.generateTrainingDataset() {
                            NSWorkspace.shared.selectFile(url.path, inFileViewerRootedAtPath: url.deletingLastPathComponent().path)
                            showToast("📁 Revealed train.jsonl in Finder!")
                            HapticFeedback.selection()
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down.doc.fill")
                            Text("Export JSONL")
                        }
                        .font(.system(size: 9.5, weight: .semibold))
                        .foregroundColor(.cyan)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(RoundedRectangle(cornerRadius: 4).fill(Color.cyan.opacity(0.12)))
                    }
                    .buttonStyle(.plain)

                    // Copy Logs
                    Button(action: {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(evolver.trainingLogs, forType: .string)
                        showToast("📋 Copied Training Logs!")
                        HapticFeedback.selection()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "doc.on.doc")
                            Text("Copy Logs")
                        }
                        .font(.system(size: 9.5, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(RoundedRectangle(cornerRadius: 4).fill(Color.white.opacity(0.10)))
                    }
                    .buttonStyle(.plain)
                }

                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(evolver.trainingLogs.isEmpty ? "No active training session. Click 'Start Fine-Tuning' above to begin." : evolver.trainingLogs)
                            .font(.system(size: 10.5, design: .monospaced))
                            .foregroundColor(.white.opacity(0.85))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(10)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.40))
                .cornerRadius(6)
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.04)))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.white.opacity(0.08), lineWidth: 0.75))
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
        }
    }

    // MARK: - 3. Corpus Files List View
    private var corpusFilesListView: some View {
        VStack(spacing: 8) {
            // Search Bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 11))

                TextField("Filter indexed corpus files (e.g. .swift, Engine, Shader)...", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11))
                    .foregroundColor(.white)

                if !searchQuery.isEmpty {
                    Button(action: { searchQuery = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.06)))
            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color.white.opacity(0.10), lineWidth: 0.5))
            .padding(.horizontal, 16)
            .padding(.top, 10)

            // Table List
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(filteredFiles) { file in
                        HStack(spacing: 10) {
                            fileTypeIcon(ext: file.fileExtension)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(file.relativePath)
                                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                            }

                            Spacer()

                            Text("\(file.lineCount) lines")
                                .font(.system(size: 10, design: .rounded))
                                .foregroundColor(.secondary)

                            Text("\(file.tokenCountEst) tokens")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(.cyan)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.cyan.opacity(0.12)))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.03)))
                        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color.white.opacity(0.05), lineWidth: 0.5))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
        }
    }

    private var filteredFiles: [CodebaseCorpusFile] {
        if searchQuery.isEmpty {
            return evolver.indexedFiles
        }
        return evolver.indexedFiles.filter {
            $0.relativePath.localizedCaseInsensitiveContains(searchQuery) ||
            $0.fileExtension.localizedCaseInsensitiveContains(searchQuery)
        }
    }

    private func fileTypeIcon(ext: String) -> some View {
        let (icon, color): (String, Color) = {
            switch ext {
            case "swift": return ("swift", .orange)
            case "metal": return ("cpu.fill", .cyan)
            case "c", "h": return ("c.square.fill", .blue)
            case "json": return ("curlybraces", .yellow)
            case "md": return ("doc.text.fill", .indigo)
            default: return ("doc.fill", .gray)
            }
        }()

        return Image(systemName: icon)
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(color)
            .frame(width: 20)
    }

    private func formatTokens(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000.0)
        } else if count >= 1_000 {
            return String(format: "%.1fk", Double(count) / 1_000.0)
        }
        return "\(count)"
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
