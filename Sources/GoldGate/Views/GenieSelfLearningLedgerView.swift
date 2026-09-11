import SwiftUI

// MARK: - 🧠 Self-Learning & Script Repair Ledger Interactive HUD
public struct GenieSelfLearningLedgerView: View {
    @ObservedObject var engine = GenieSelfRepairLearningEngine.shared
    @State private var filterAction: SelfLearningAction? = nil
    @State private var selectedEntry: SelfLearningLedgerEntry? = nil
    @State private var isExecutingTest: Bool = false
    @State private var testExecutionLog: String = ""

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            headerBar

            Divider().background(Color.white.opacity(0.12))

            // Main Content: Split Master-Detail or List
            HStack(spacing: 0) {
                // Left: Ledger Entries List
                ledgerEntriesList
                    .frame(minWidth: 340, maxWidth: 420)

                Divider().background(Color.white.opacity(0.12))

                // Right: Detail & Verification Pane
                if let entry = selectedEntry ?? engine.ledgerEntries.first {
                    entryDetailPane(entry)
                } else {
                    emptyStateView
                }
            }
        }
        .frame(minWidth: 780, minHeight: 520)
        .background(
            ZStack {
                VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow, state: .active)
                Color.black.opacity(0.72)
            }
        )
    }

    // MARK: - 1. Header Bar
    private var headerBar: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Color.purple, Color.cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 34, height: 34)
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text("Genie Autonomous Self-Learning Ledger")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("\(engine.ledgerEntries.count) events")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(.cyan)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.cyan.opacity(0.15)))
                }

                Text("Tracks all autonomous Python script updates, bug self-repairs, and learned capabilities with verified rollback history.")
                    .font(.system(size: 11))
                    .foregroundColor(.white.opacity(0.60))
            }

            Spacer()

            // Filter picker
            Picker("Filter", selection: $filterAction) {
                Text("All Events").tag(SelfLearningAction?.none)
                ForEach(SelfLearningAction.allCases, id: \.self) { act in
                    Text(act.displayBadge).tag(SelfLearningAction?.some(act))
                }
            }
            .pickerStyle(.menu)
            .frame(width: 170)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    // MARK: - 2. Ledger Entries List
    private var ledgerEntriesList: some View {
        let filtered = engine.ledgerEntries.filter { entry in
            if let f = filterAction { return entry.action == f }
            return true
        }

        return ScrollView {
            LazyVStack(spacing: 8) {
                if filtered.isEmpty {
                    Text("No ledger entries matching filter.")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.45))
                        .padding(.top, 40)
                } else {
                    ForEach(filtered) { entry in
                        ledgerCard(entry: entry, isSelected: (selectedEntry?.id ?? engine.ledgerEntries.first?.id) == entry.id)
                            .onTapGesture {
                                selectedEntry = entry
                            }
                    }
                }
            }
            .padding(12)
        }
    }

    private func ledgerCard(entry: SelfLearningLedgerEntry, isSelected: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(entry.action.displayBadge)
                    .font(.system(size: 10.5, weight: .bold))
                    .foregroundColor(entry.action.color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(entry.action.color.opacity(0.18)))

                Spacer()

                Text("v\(entry.version)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.85))

                if entry.isVerified {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.green)
                }
            }

            Text(entry.capabilityTitle)
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundColor(.white)
                .lineLimit(1)

            Text(entry.scriptName + ".py")
                .font(.system(size: 11, weight: .medium, design: .monospaced))
                .foregroundColor(.white.opacity(0.55))

            HStack {
                Text(DateFormatter.localizedString(from: entry.timestamp, dateStyle: .short, timeStyle: .short))
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.40))

                Spacer()

                Text(entry.author)
                    .font(.system(size: 9.5))
                    .foregroundColor(.white.opacity(0.35))
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? Color.white.opacity(0.12) : Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(isSelected ? Color.cyan.opacity(0.60) : Color.white.opacity(0.08), lineWidth: 1.0)
        )
    }

    // MARK: - 3. Entry Detail & Verification Pane
    private func entryDetailPane(_ entry: SelfLearningLedgerEntry) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                // Header Info
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(entry.capabilityTitle)
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text("Script: \(entry.scriptName).py • Version: v\(entry.version) • Author: \(entry.author)")
                            .font(.system(size: 11.5, design: .monospaced))
                            .foregroundColor(.cyan)
                    }

                    Spacer()

                    // Action buttons: Test Script / Rollback
                    HStack(spacing: 8) {
                        Button(action: {
                            Task {
                                isExecutingTest = true
                                let res = await engine.executeLearnedScript(name: entry.scriptName)
                                testExecutionLog = res.stdout.isEmpty ? res.stderr : res.stdout
                                isExecutingTest = false
                            }
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "play.fill")
                                Text(isExecutingTest ? "Running..." : "Test Script")
                            }
                            .font(.system(size: 11, weight: .semibold))
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.cyan)

                        if entry.version > 1 {
                            Button(action: {
                                engine.rollback(name: entry.scriptName, targetVersion: entry.version - 1)
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.uturn.backward")
                                    Text("Rollback to v\(entry.version - 1)")
                                }
                                .font(.system(size: 11, weight: .semibold))
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }

                // Summary Box
                VStack(alignment: .leading, spacing: 4) {
                    Text("AUTONOMOUS SUMMARY & RATIONALE")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.50))

                    Text(entry.summary)
                        .font(.system(size: 12.5))
                        .foregroundColor(.white.opacity(0.90))
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.05)))

                // Verification Output Box
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("VERIFICATION TEST EXECUTION")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.50))

                        Spacer()

                        Text(entry.isVerified ? "PASSED VERIFICATION" : "UNVERIFIED")
                            .font(.system(size: 9.5, weight: .bold))
                            .foregroundColor(entry.isVerified ? .green : .orange)
                    }

                    Text(entry.verificationOutput.isEmpty ? "No runtime warnings." : entry.verificationOutput)
                        .font(.system(size: 11.5, design: .monospaced))
                        .foregroundColor(.green.opacity(0.90))
                        .textSelection(.enabled)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.40)))

                // Code Snippet Box
                VStack(alignment: .leading, spacing: 4) {
                    Text("PYTHON SOURCE CODE SNIPPET")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.50))

                    ScrollView(.horizontal, showsIndicators: true) {
                        Text(entry.codeDiffOrSnippet)
                            .font(.system(size: 11.5, design: .monospaced))
                            .foregroundColor(.white.opacity(0.85))
                            .textSelection(.enabled)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.40)))

                // Live Test Output if executed
                if !testExecutionLog.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("LIVE SUBPROCESS OUTPUT")
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.cyan)

                        Text(testExecutionLog)
                            .font(.system(size: 11.5, design: .monospaced))
                            .foregroundColor(.cyan.opacity(0.90))
                            .textSelection(.enabled)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.cyan.opacity(0.08)))
                }
            }
            .padding(16)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 40))
                .foregroundColor(.white.opacity(0.20))
            Text("No Ledger Entry Selected")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.40))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
