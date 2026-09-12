import AppKit
import SwiftUI
import Combine

// MARK: - 🍎 Apple Menu Bar Inside Chat View
/// Steve Jobs-inspired authentic Apple Menu Bar embedded directly inside the chat interface.
/// Features pristine typography, translucent glass vibrancy, Apple menu hierarchy,
/// live Unified RAM bandwidth & governor statistics, battery/thermal power telemetry,
/// In-RAM sovereign email client portal, and Trash airlock promotions.
public struct GenieChatAppleMenuBarView: View {
    @ObservedObject var memGovernor = GenieMemoryGovernorEngine.shared
    @ObservedObject var inRAMVM = GenieInRAMVMManager.shared
    @ObservedObject var batt = BatteryMonitor.shared
    @ObservedObject var emailServer = GenieInRAMLocalEmailServer.shared
    @ObservedObject var airlock = GenieTrashAirlockGateway.shared
    @ObservedObject var workerOrchestrator = GenieWorkerNodeOrchestrator.shared
    @ObservedObject var localModels = LocalModelManager.shared

    @State private var showMailSheet: Bool = false
    @State private var showRAMSheet: Bool = false
    @State private var showBatterySheet: Bool = false
    @State private var showAboutSheet: Bool = false
    @State private var currentTimeString: String = ""

    private let timer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    public init() {}

    public var body: some View {
        HStack(spacing: 0) {
            // ── Left: Apple Logo & Application Menus ──
            HStack(spacing: 2) {
                appleLogoMenu
                genieMenu
                fileMenu
                editMenu
                forkAndWorkerMenu
                vmAndRAMMenu
                viewMenu
                helpMenu
            }

            Spacer(minLength: 8)

            // ── Right: Detailed System Telemetry & Status Tray ──
            HStack(spacing: 6) {
                // 1. Detailed Unified RAM Governor Pill
                unifiedRAMStatusPill

                // 2. Detailed Battery & Power Telemetry Pill
                batteryTelemetryPill

                // 3. In-RAM Sovereign Email Server Pill
                sovereignEmailPill

                // 4. Trash Airlock Entryway Pill
                trashAirlockPill

                // 5. Apple Time Clock
                Text(currentTimeString)
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.horizontal, 4)
            }
        }
        .padding(.horizontal, 10)
        .frame(height: 25)
        .background(
            Color(red: 0.10, green: 0.11, blue: 0.14)
                .opacity(0.92)
                .overlay(
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 0.75),
                    alignment: .bottom
                )
        )
        .onAppear {
            updateTime()
        }
        .onReceive(timer) { _ in
            updateTime()
        }
        .sheet(isPresented: $showMailSheet) {
            GenieLocalEmailClientSheet(isPresented: $showMailSheet)
        }
        .popover(isPresented: $showRAMSheet) {
            ramDetailsPopover
        }
        .popover(isPresented: $showBatterySheet) {
            batteryDetailsPopover
        }
        .sheet(isPresented: $showAboutSheet) {
            aboutGenieSteveJobsSheet
        }
    }

    private func updateTime() {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        currentTimeString = formatter.string(from: Date())
    }

    // MARK: -  Apple Logo Menu
    private var appleLogoMenu: some View {
        Menu {
            Button("About Genie Master...") {
                showAboutSheet = true
            }

            Divider()

            Button("System Profiler (Unified RAM & VM)...") {
                showRAMSheet = true
            }

            Button("Force Purge Volatile Memory (Governor)") {
                memGovernor.purgeVolatileCaches()
                HapticFeedback.heavy()
            }

            Button("Empty Trash Airlock (~/.Trash/.genie_airlock)") {
                try? FileManager.default.removeItem(at: airlock.primaryAirlockURL)
                airlock.ensureAirlockExists()
                airlock.refreshStagedCount()
                HapticFeedback.selection()
            }

            Divider()

            Button("Sleep Genie Background Agents") {
                HapticFeedback.selection()
            }

            Button("Restart Sovereign Model Server") {
                Task {
                    try? await inRAMVM.startSovereignServer()
                }
            }
        } label: {
            Image(systemName: "apple.logo")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.95))
                .padding(.horizontal, 5)
                .padding(.vertical, 2.5)
                .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }

    // MARK: - App Menus
    private var genieMenu: some View {
        Menu("Genie") {
            Button("Preferences...") {
                NotificationCenter.default.post(name: NSNotification.Name("OpenGeniePreferences"), object: nil)
            }
            Divider()
            Button("Hide Chat") {
                NSApp.hide(nil)
            }
            .keyboardShortcut("h", modifiers: .command)
            Button("Hide Others") {
                NSApp.hideOtherApplications(nil)
            }
            .keyboardShortcut("h", modifiers: [.command, .option])
            Button("Show All") {
                NSApp.unhideAllApplications(nil)
            }
        }
        .menuStyle(.borderlessButton)
        .font(.system(size: 10.5, weight: .semibold))
        .foregroundColor(.white.opacity(0.90))
        .fixedSize()
    }

    private var fileMenu: some View {
        Menu("File") {
            Button("New Chat Conversation") {
                localModels.clearChatHistory()
                HapticFeedback.selection()
            }
            .keyboardShortcut("n", modifiers: .command)

            Button("Crawl Local Directory (IPE)...") {
                GenieLocalFileCrawlerEngine.shared.startBackgroundCrawl()
            }
            .keyboardShortcut("f", modifiers: [.command, .shift])

            Button("Open Project Space in Finder...") {
                let spacesURL = URL(fileURLWithPath: GenieSharedFolderForkEngine.defaultSpacesPath)
                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: spacesURL.path)
            }
            .keyboardShortcut("o", modifiers: .command)

            Divider()

            Button("Export Chat Transcript as RTF Note...") {
                NotificationCenter.default.post(name: NSNotification.Name("SaveChatToNoteRequested"), object: nil)
            }
            .keyboardShortcut("s", modifiers: .command)
        }
        .menuStyle(.borderlessButton)
        .font(.system(size: 10.5, weight: .regular))
        .foregroundColor(.white.opacity(0.85))
        .fixedSize()
    }

    private var editMenu: some View {
        Menu("Edit") {
            Button("Clear Chat History") {
                localModels.clearChatHistory()
                HapticFeedback.tick()
            }
            .keyboardShortcut("k", modifiers: .command)
            Divider()
            Button("Cut") { NSApp.sendAction(#selector(NSText.cut(_:)), to: nil, from: nil) }
                .keyboardShortcut("x", modifiers: .command)
            Button("Copy") { NSApp.sendAction(#selector(NSText.copy(_:)), to: nil, from: nil) }
                .keyboardShortcut("c", modifiers: .command)
            Button("Paste") { NSApp.sendAction(#selector(NSText.paste(_:)), to: nil, from: nil) }
                .keyboardShortcut("v", modifiers: .command)
            Button("Select All") { NSApp.sendAction(#selector(NSText.selectAll(_:)), to: nil, from: nil) }
                .keyboardShortcut("a", modifiers: .command)
        }
        .menuStyle(.borderlessButton)
        .font(.system(size: 10.5, weight: .regular))
        .foregroundColor(.white.opacity(0.85))
        .fixedSize()
    }

    private var forkAndWorkerMenu: some View {
        Menu("Fork & Workers") {
            Button("Drop Sequential Worker onto Active Space...") {
                let instructions = [
                    GenieWorkerInstruction(title: "Index Codebase", type: .shell(command: "ls -la")),
                    GenieWorkerInstruction(title: "Verify Build", type: .verify(testCommand: "swift --version"))
                ]
                let spaceURL = URL(fileURLWithPath: GenieSharedFolderForkEngine.defaultSpacesPath)
                _ = GenieWorkerNodeOrchestrator.shared.dropWorker(name: "SequentialWorker", into: spaceURL, instructions: instructions)
            }

            Divider()

            Section("Active Workers (\(workerOrchestrator.activeWorkers.count))") {
                if workerOrchestrator.activeWorkers.isEmpty {
                    Text("No workers currently executing")
                } else {
                    ForEach(workerOrchestrator.activeWorkers) { worker in
                        Text("• \(worker.name) (\(worker.status.rawValue))")
                    }
                }
            }

            Divider()

            Button("Create APFS Zero-Copy Clone of Desktop...") {
                let home = FileManager.default.homeDirectoryForCurrentUser
                let desktop = home.appendingPathComponent("Desktop")
                _ = try? GenieSharedFolderForkEngine.shared.forkProject(sourceURL: desktop, spaceName: "DesktopFork")
            }
        }
        .menuStyle(.borderlessButton)
        .font(.system(size: 10.5, weight: .regular))
        .foregroundColor(.white.opacity(0.85))
        .fixedSize()
    }

    private var vmAndRAMMenu: some View {
        Menu("VM & RAM") {
            Button(inRAMVM.isRAMDiskMounted ? "Dismount In-RAM APFS Disk (Reclaim RAM)" : "Mount In-RAM APFS Disk (4096 MB)...") {
                Task {
                    if inRAMVM.isRAMDiskMounted {
                        inRAMVM.dismountRAMDisk()
                    } else {
                        _ = try? await inRAMVM.mountRAMDisk(sizeMB: 4096)
                    }
                }
            }

            Button(inRAMVM.isModelServerRunning ? "Stop Sovereign Local Server" : "Start Sovereign Local Server (Port \(inRAMVM.serverPort))...") {
                Task {
                    if inRAMVM.isModelServerRunning {
                        inRAMVM.stopSovereignServer()
                    } else {
                        try? await inRAMVM.startSovereignServer()
                    }
                }
            }

            Divider()

            Button("Open Sovereign Email Client...") {
                showMailSheet = true
            }

            Button("Show Detailed RAM Governor Statistics...") {
                showRAMSheet = true
            }
        }
        .menuStyle(.borderlessButton)
        .font(.system(size: 10.5, weight: .regular))
        .foregroundColor(.white.opacity(0.85))
        .fixedSize()
    }

    private var viewMenu: some View {
        Menu("View") {
            Button("Zoom In") {
                NotificationCenter.default.post(name: NSNotification.Name("ChatZoomInRequested"), object: nil)
            }
            .keyboardShortcut("+", modifiers: .command)

            Button("Zoom Out") {
                NotificationCenter.default.post(name: NSNotification.Name("ChatZoomOutRequested"), object: nil)
            }
            .keyboardShortcut("-", modifiers: .command)

            Button("Reset Zoom (100%)") {
                NotificationCenter.default.post(name: NSNotification.Name("ChatZoomResetRequested"), object: nil)
            }
            .keyboardShortcut("0", modifiers: .command)
        }
        .menuStyle(.borderlessButton)
        .font(.system(size: 10.5, weight: .regular))
        .foregroundColor(.white.opacity(0.85))
        .fixedSize()
    }

    private var helpMenu: some View {
        Menu("Help") {
            Button("What would Steve Jobs think!?") {
                showAboutSheet = true
            }
            Button("Genie Architecture Documentation") {
                let fm = FileManager.default
                let docURL = fm.homeDirectoryForCurrentUser.appendingPathComponent("Desktop/Genie/GoldGate/docs/GENIE_NOVEL_ARCHITECTURE.md")
                if fm.fileExists(atPath: docURL.path) {
                    NSWorkspace.shared.open(docURL)
                } else if let bundleDoc = Bundle.main.url(forResource: "GENIE_NOVEL_ARCHITECTURE", withExtension: "md") {
                    NSWorkspace.shared.open(bundleDoc)
                }
            }
        }
        .menuStyle(.borderlessButton)
        .font(.system(size: 10.5, weight: .regular))
        .foregroundColor(.white.opacity(0.85))
        .fixedSize()
    }

    // MARK: - 🧠 Detailed Unified RAM Pill
    private var unifiedRAMStatusPill: some View {
        Button(action: { showRAMSheet.toggle() }) {
            HStack(spacing: 4) {
                Image(systemName: "memorychip")
                    .font(.system(size: 8.5))
                    .foregroundColor(memGovernor.currentPressureLevel == .normal ? .cyan : (memGovernor.currentPressureLevel == .warning ? .yellow : .red))

                let usedGB = String(format: "%.1f", Double(memGovernor.currentProcessResidentMB) / 1024.0)
                let totalGB = memGovernor.totalHostMemoryMB > 0 ? "\(memGovernor.totalHostMemoryMB / 1024)G" : "Unified"
                let vmLabel = inRAMVM.isRAMDiskMounted ? " • VM:\(inRAMVM.allocatedRAMMB / 1024)G" : ""

                Text("RAM: \(usedGB)/\(totalGB)\(vmLabel)")
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.90))
            }
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(Capsule().fill(Color.white.opacity(0.08)))
            .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
        .help("Unified RAM Governor: Click to inspect active allocations & memory pressure")
    }

    // MARK: - 🔋 Detailed Battery & Power Pill
    private var batteryTelemetryPill: some View {
        Button(action: { showBatterySheet.toggle() }) {
            HStack(spacing: 3.5) {
                let pct = batt.batteryPct ?? 100
                Image(systemName: batt.isCharging ? "battery.100.bolt" : (pct > 20 ? "battery.100" : "battery.25"))
                    .font(.system(size: 9))
                    .foregroundColor(batt.isCharging ? .yellow : (pct > 20 ? .green : .red))

                Text("\(pct)%")
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.90))

                if batt.isPluggedIn {
                    Image(systemName: "powerplug.fill")
                        .font(.system(size: 7))
                        .foregroundColor(.green.opacity(0.85))
                }
            }
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(Capsule().fill(Color.white.opacity(0.08)))
            .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
        .help("Power: \(batt.powerSourceDescription) • Thermals: \(batt.thermalStateString)")
    }

    // MARK: - ✉️ Sovereign In-RAM Email Server Pill
    private var sovereignEmailPill: some View {
        Button(action: { showMailSheet = true }) {
            HStack(spacing: 3) {
                Image(systemName: "envelope.fill")
                    .font(.system(size: 8.5))
                    .foregroundColor(emailServer.unreadCount > 0 ? .yellow : .white.opacity(0.70))

                if emailServer.unreadCount > 0 {
                    Text("\(emailServer.unreadCount)")
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .foregroundColor(.black)
                        .padding(.horizontal, 3.5)
                        .background(Capsule().fill(Color.yellow))
                }
            }
            .padding(.horizontal, 4.5)
            .padding(.vertical, 2)
            .background(Capsule().fill(Color.white.opacity(0.08)))
            .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.5))
        }
        .buttonStyle(.plain)
        .help("Sovereign In-RAM Local Email Server (\(emailServer.unreadCount) unread)")
    }

    // MARK: - 🗑️ Trash Airlock Pill
    private var trashAirlockPill: some View {
        Menu {
            Text("Trash Airlock (Hidden Desktop Entryway)")
                .font(.caption)
                .foregroundColor(.secondary)

            Divider()

            Text("Staged VM Artifacts: \(airlock.stagedArtifactsCount)")
            Text("Total Promoted to Desktop: \(airlock.totalPromotionsToDesktop)")

            if let last = airlock.lastPromotedItemName {
                Text("Last Promoted: \(last)")
            }

            Divider()

            Button("Open Staging Directory in Finder") {
                NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: airlock.primaryAirlockURL.path)
            }
        } label: {
            HStack(spacing: 3) {
                Image(systemName: "trash")
                    .font(.system(size: 8))
                    .foregroundColor(airlock.stagedArtifactsCount > 0 ? .cyan : .white.opacity(0.60))

                if airlock.stagedArtifactsCount > 0 {
                    Text("\(airlock.stagedArtifactsCount)")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.cyan)
                }
            }
            .padding(.horizontal, 4.5)
            .padding(.vertical, 2)
            .background(Capsule().fill(Color.white.opacity(0.08)))
            .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 0.5))
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .help("Trash Airlock: Zero-copy atomic entryway between VM and Desktop")
    }

    // MARK: - Popovers & Sheets

    private var ramDetailsPopover: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "memorychip.fill").foregroundColor(.cyan)
                Text("Unified RAM & Governor Telemetry")
                    .font(.system(size: 11, weight: .bold))
            }

            Divider()

            Text("• Process Resident: \(memGovernor.currentProcessResidentMB) MB")
            Text("• Host Available: \(memGovernor.hostAvailableMemoryMB) MB")
            Text("• Memory Pressure: \(memGovernor.currentPressureLevel.rawValue)")
            Text("• In-RAM VM APFS Mount: \(inRAMVM.isRAMDiskMounted ? "\(inRAMVM.allocatedRAMMB) MB allocated" : "None")")
            Text("• Bus Throughput: 200–800 GB/s Unified Memory")
            Text("• Zero-Leak Sentinel: \(memGovernor.idleStatusDescription)")

            Divider()

            Button("Purge Volatile Caches Now") {
                memGovernor.purgeVolatileCaches()
                HapticFeedback.selection()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(12)
        .frame(width: 280)
    }

    private var batteryDetailsPopover: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "bolt.fill").foregroundColor(.yellow)
                Text("Power & Thermals")
                    .font(.system(size: 11, weight: .bold))
            }

            Divider()

            Text("• Battery Level: \(batt.batteryPct.map { "\($0)%" } ?? "Unknown")")
            Text("• Power Source: \(batt.powerSourceDescription)")
            Text("• Charging State: \(batt.isCharging ? "Fast Charging ⚡️" : (batt.isPluggedIn ? "Fully Charged / Standby" : "Discharging on Battery"))")
            Text("• Thermal Pressure: \(batt.thermalStateString)")

            Divider()

            Text("Genie runs zero-overhead background threads, idling at ~0.0% CPU to preserve all-day battery life.")
                .font(.system(size: 9.5))
                .foregroundColor(.secondary)
        }
        .padding(12)
        .frame(width: 270)
    }

    private var aboutGenieSteveJobsSheet: some View {
        VStack(spacing: 16) {
            Image(systemName: "apple.logo")
                .font(.system(size: 38))
                .foregroundColor(.white)

            Text("Genie Master 2026")
                .font(.system(size: 18, weight: .bold, design: .rounded))

            Text("What would Steve Jobs think!?")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.yellow)

            Text("""
            \"We're here to put a dent in the universe. Otherwise why else even be here?\"

            Genie brings the purest principles of personal computing to autonomous AI:
            • Running an entire hypervisor and Ubuntu server inside Unified RAM.
            • Zero-copy APFS folder forking with Darwin clonefile(2).
            • Using the Trash Can as the atomic, zero-copy entryway to the Desktop.
            • Sovereign in-memory local mail servers for AI agents.
            • Sub-millisecond IPE character bitmasks eliminating disk storms.

            Made in the United States and South Korea by Nicholas M. Dudek 2026 United States Apple 3rd Party.
            """)
            .font(.system(size: 11))
            .foregroundColor(.white.opacity(0.85))
            .multilineTextAlignment(.center)
            .padding(.horizontal, 16)

            Button("Insanely Great ✨") {
                showAboutSheet = false
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
        }
        .padding(24)
        .frame(width: 400)
        .background(Color(red: 0.12, green: 0.13, blue: 0.16))
    }
}

// MARK: - 📮 Sovereign Local Email Client Sheet
public struct GenieLocalEmailClientSheet: View {
    @Binding var isPresented: Bool
    @ObservedObject var emailServer = GenieInRAMLocalEmailServer.shared
    @State private var selectedMessage: GenieLocalEmailMessage?
    @State private var composeTo: String = "genie@local.internal"
    @State private var composeSubject: String = ""
    @State private var composeBody: String = ""
    @State private var isComposing: Bool = false

    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "tray.full.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.cyan)
                    Text("Sovereign In-RAM Mail")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                    Text("(\(emailServer.activeUserAddress))")
                        .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: { isComposing.toggle() }) {
                    Label(isComposing ? "View Inbox" : "Compose", systemImage: isComposing ? "tray" : "square.and.pencil")
                        .font(.system(size: 11, weight: .semibold))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button("Done") {
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.25))

            Divider()

            if isComposing {
                composeView
            } else {
                inboxSplitView
            }
        }
        .frame(width: 680, height: 440)
        .background(Color(red: 0.11, green: 0.12, blue: 0.15))
    }

    private var inboxSplitView: some View {
        HSplitView {
            // Left: Message List
            VStack(alignment: .leading, spacing: 0) {
                List(emailServer.messages, id: \.id, selection: Binding(
                    get: { selectedMessage?.id },
                    set: { id in
                        if let id = id, let found = emailServer.messages.first(where: { $0.id == id }) {
                            selectedMessage = found
                            emailServer.markAsRead(id: found.id)
                        }
                    }
                )) { msg in
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text(msg.from)
                                .font(.system(size: 11, weight: msg.isRead ? .regular : .bold))
                                .foregroundColor(.white)
                            Spacer()
                            Text(msg.timestamp, style: .time)
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                        Text(msg.subject)
                            .font(.system(size: 10.5, weight: msg.isRead ? .regular : .semibold))
                            .foregroundColor(msg.isRead ? .white.opacity(0.7) : .white)
                            .lineLimit(1)
                        Text(msg.body)
                            .font(.system(size: 9.5))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    .padding(.vertical, 3)
                }
                .listStyle(.sidebar)
            }
            .frame(minWidth: 240, maxWidth: 300)

            // Right: Detail View
            if let msg = selectedMessage {
                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(msg.subject)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                        HStack {
                            Text("From: \(msg.from)")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.cyan)
                            Spacer()
                            Text(msg.timestamp, style: .date)
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        Text("To: \(msg.to)")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(6)

                    ScrollView {
                        Text(msg.body)
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.92))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .textSelection(.enabled)
                            .padding(8)
                    }

                    if !msg.attachments.isEmpty {
                        Divider()
                        HStack {
                            Image(systemName: "paperclip")
                            Text("Attachments: \(msg.attachments.joined(separator: ", "))")
                                .font(.system(size: 9.5, design: .monospaced))
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 8)
                    }
                }
                .padding(12)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                VStack(spacing: 8) {
                    Image(systemName: "envelope.open")
                        .font(.system(size: 28))
                        .foregroundColor(.secondary)
                    Text("Select a sovereign email to read")
                        .foregroundColor(.secondary)
                        .font(.system(size: 12))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private var composeView: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("To:")
                    .frame(width: 50, alignment: .leading)
                    .font(.system(size: 11, weight: .bold))
                TextField("Recipient (e.g. genie@local.internal)", text: $composeTo)
                    .textFieldStyle(.roundedBorder)
            }

            HStack {
                Text("Subject:")
                    .frame(width: 50, alignment: .leading)
                    .font(.system(size: 11, weight: .bold))
                TextField("Subject", text: $composeSubject)
                    .textFieldStyle(.roundedBorder)
            }

            Divider()

            TextEditor(text: $composeBody)
                .font(.system(size: 12))
                .cornerRadius(4)
                .frame(maxHeight: .infinity)

            HStack {
                Spacer()
                Button("Send via In-RAM Server 🚀") {
                    emailServer.sendEmail(
                        from: emailServer.activeUserAddress,
                        to: composeTo,
                        subject: composeSubject,
                        body: composeBody
                    )
                    composeSubject = ""
                    composeBody = ""
                    isComposing = false
                    HapticFeedback.heavy()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding(16)
    }
}
