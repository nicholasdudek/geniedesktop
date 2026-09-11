import SwiftUI

struct RuntimeConfiguratorView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var manager = RuntimeManager.shared
    @ObservedObject private var memoryGovernor = GenieMemoryGovernorEngine.shared
    @State private var config: RuntimeConfiguration

    init() {
        let recommendation = GenieMemoryGovernorEngine.shared.stationRAMRecommendation()
        _config = State(initialValue: RuntimeConfiguration(
            resources: StationResources(ramMB: recommendation.recommendedDefault)
        ))
    }

    private var ramRange: ClosedRange<Int> { memoryGovernor.stationRAMRecommendation().range }
    private var ramStep: Int { memoryGovernor.stationRAMRecommendation().stepMB }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    Text("New AI Station")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                    Spacer()
                    HStack {
                        Button("Cancel") { dismiss() }
                            .buttonStyle(.bordered)

                        Button("Create") {
                            Task {
                                try? await manager.createRuntime(config: config)
                                dismiss()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(config.displayName.isEmpty)
                    }
                }
                .padding(.bottom)

                Divider()

                // Basic Identity
                Group {
                    RuntimeField(label: "Station ID", value: .constant(config.id), isEditable: false)
                    RuntimeField(label: "Display Name", value: $config.displayName)
                    RuntimeField(label: "Description", value: $config.description)
                }

                SectionHeader(title: "Station Resources")
                Text("This Mac has \(memoryGovernor.totalHostMemoryMB / 1024) GB of RAM. The slider below stays within what's safe to hand a station while leaving room for macOS and a local model.")
                    .font(.caption)
                    .foregroundColor(.secondary)

                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("CPU Cores").font(.system(size: 13, weight: .medium)).foregroundColor(.secondary)
                        Spacer()
                        Stepper("\(config.resources.vcpu)", value: $config.resources.vcpu, in: 1...max(1, ProcessInfo.processInfo.activeProcessorCount))
                            .fixedSize()
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Dedicated RAM").font(.system(size: 13, weight: .medium)).foregroundColor(.secondary)
                            Spacer()
                            Text("\(config.resources.ramMB) MB (\(String(format: "%.1f", Double(config.resources.ramMB) / 1024)) GB)")
                                .font(.system(size: 13, weight: .semibold, design: .rounded))
                        }
                        Slider(
                            value: Binding(
                                get: { Double(config.resources.ramMB) },
                                set: { config.resources.ramMB = (Int($0) / ramStep) * ramStep }
                            ),
                            in: Double(ramRange.lowerBound)...Double(ramRange.upperBound),
                            step: Double(ramStep)
                        )
                    }

                    HStack {
                        Text("Disk").font(.system(size: 13, weight: .medium)).foregroundColor(.secondary)
                        Spacer()
                        Stepper("\(config.resources.diskGB) GB", value: $config.resources.diskGB, in: 8...256, step: 8)
                            .fixedSize()
                    }
                    Text("Disk size is informational for now and isn't yet wired to the station's actual storage.")
                        .font(.caption2).foregroundColor(.secondary)
                }

                SectionHeader(title: "Session")
                HStack {
                    VStack(alignment: .leading) {
                        Text("Max idle time").font(.caption).foregroundColor(.secondary)
                        HStack {
                            TextField("Quantity", value: $config.sessionConfig.maxIdleTimeQuantity, formatter: NumberFormatter())
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                            Picker("Unit", selection: $config.sessionConfig.maxIdleTimeUnit) {
                                ForEach(TimeUnit.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                            }
                            .fixedSize()
                        }
                    }
                    Spacer()
                    VStack(alignment: .leading) {
                        Text("Max lifetime").font(.caption).foregroundColor(.secondary)
                        HStack {
                            TextField("Quantity", value: $config.sessionConfig.maxLifetimeQuantity, formatter: NumberFormatter())
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                            Picker("Unit", selection: $config.sessionConfig.maxLifetimeTimeUnit) {
                                ForEach(TimeUnit.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                            }
                            .fixedSize()
                        }
                    }
                }

                Spacer(minLength: 40)
            }
            .padding()
        }
        .frame(maxWidth: 800)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Supporting UI Components

struct SectionHeader: View {
    let title: String
    var body: some View {
        Text(title)
            .font(.system(size: 18, weight: .semibold, design: .rounded))
            .foregroundColor(.accentColor)
            .padding(.top, 16)
            .padding(.bottom, 8)
    }
}

struct RuntimeField: View {
    let label: String
    var value: Binding<String>
    var isEditable: Bool = true
    var hint: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(.system(size: 13, weight: .medium)).foregroundColor(.secondary)
            TextField(hint ?? "", text: value)
                .textFieldStyle(.roundedBorder)
                .disabled(!isEditable)
                .opacity(isEditable ? 1.0 : 0.6)
        }
        .padding(.vertical, 4)
    }
}
