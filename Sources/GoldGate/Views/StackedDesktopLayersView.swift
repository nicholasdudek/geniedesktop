import AppKit
import SwiftUI

// MARK: - Stacked Desktop Layers Manager Extension

extension MacDesktopsManager {
    public func workspaceName(for space: MacDesktopSpace) -> String {
        let key = "nexus.workspaceName.\(space.index)"
        let saved = UserDefaults.standard.string(forKey: key)
        if let s = saved, !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return s
        }
        if let agent = AgentVirtualSpaceManager.shared.spaceForDesktop(space.index) {
            return agent.name
        }
        switch space.index {
        case 1: return "Desktop Views Center 🛸"
        case 2: return "VS Code Editor Agent 💻"
        case 3: return "Browser Research Agent 🌐"
        case 4: return "Terminal & Build Agent ⚡️"
        case 5: return "Focus • Terminal"
        default: return "Workspace \(space.index)"
        }
    }

    public func setWorkspaceName(for space: MacDesktopSpace, name: String) {
        let key = "nexus.workspaceName.\(space.index)"
        UserDefaults.standard.set(name, forKey: key)
        objectWillChange.send()
    }

    public func isWorkspaceLocked(for space: MacDesktopSpace) -> Bool {
        let key = "nexus.workspaceLocked.\(space.index)"
        return UserDefaults.standard.bool(forKey: key)
    }

    public func toggleWorkspaceLock(for space: MacDesktopSpace) {
        let key = "nexus.workspaceLocked.\(space.index)"
        let current = isWorkspaceLocked(for: space)
        UserDefaults.standard.set(!current, forKey: key)
        objectWillChange.send()
    }

    public func unlockAndSwitch(to space: MacDesktopSpace) {
        HapticFeedback.heavy()
        if isWorkspaceLocked(for: space) {
            let key = "nexus.workspaceLocked.\(space.index)"
            UserDefaults.standard.set(false, forKey: key)
        }
        switchToDesktop(index: space.index)
    }
}

// MARK: - Stacked Desktop Layers Deck View (3D Spatial Card Deck)

public struct StackedDesktopLayersDeckView: View {
    @AppStorage(PrefKey.appLanguage) var appLanguage: String = "English (US)"
    @ObservedObject var manager: MacDesktopsManager = .shared
    @ObservedObject var agentSpaceManager: AgentVirtualSpaceManager = .shared
    @State private var isHoveringDeck: Bool = false
    @State private var editingSpaceIndex: Int? = nil
    @State private var tempName: String = ""

    public init() {}

    private var deckHeight: CGFloat {
        let count = max(manager.spaces.count, 1)
        let spacing: CGFloat = isHoveringDeck ? 44.0 : 20.0
        return 76.0 + CGFloat(count - 1) * spacing
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header: Layer Count & Add Workspace Layer Button
            HStack(alignment: .center) {
                HStack(spacing: 5) {
                    Image(systemName: "square.3.layers.3d.down.right.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.cyan)
                    Text(LocalizedStrings.translateText("Stacked Desktop Workspaces", lang: appLanguage))
                        .font(.system(size: 12.5, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Text("\(manager.spaces.count) Layers")
                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        .foregroundColor(.cyan)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1.5)
                        .background(Capsule().fill(Color.cyan.opacity(0.16)))
                }

                Spacer()

                Button(action: {
                    manager.createDesktop()
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "plus.rectangle.on.rectangle.fill")
                            .font(.system(size: 9, weight: .bold))
                        Text(LocalizedStrings.translateText("Stack Layer", lang: appLanguage))
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3.5)
                    .background(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(Color.cyan.opacity(0.14))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .strokeBorder(Color.cyan.opacity(0.35), lineWidth: 0.8)
                    )
                }
                .buttonStyle(.plain)
                .help("Create and stack a new WindowServer hardware desktop space")
            }

            // ── Desktop Views Center Observatory Hub ──
            DesktopViewsCenterObservatoryView()

            // ── 3D / Spatial Stacked Card Deck ──
            ZStack(alignment: .top) {
                ForEach(Array(manager.spaces.enumerated()), id: \.element.id) { idx, space in
                    StackedDesktopLayerCardView(
                        idx: idx,
                        space: space,
                        isHoveringDeck: isHoveringDeck,
                        editingSpaceIndex: $editingSpaceIndex,
                        tempName: $tempName
                    )
                }
            }
            .frame(height: deckHeight)
            .padding(.top, 4)
            .onHover { hovering in
                withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                    isHoveringDeck = hovering
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.primary.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.8)
        )
    }
}

// MARK: - Desktop Views Center Observatory View

public struct DesktopViewsCenterObservatoryView: View {
    @ObservedObject var manager: MacDesktopsManager = .shared
    @ObservedObject var agentSpaceManager: AgentVirtualSpaceManager = .shared
    @ObservedObject var splitManager: DualWorkspaceSplitManager = .shared
    @ObservedObject var partitionManager: DualDesktopPartitionManager = .shared

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: "viewfinder.circle.fill")
                    .foregroundColor(.cyan)
                    .font(.system(size: 11, weight: .bold))
                Text("Desktop Views Center")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Spacer()
                Text("Central Observatory")
                    .font(.system(size: 8.5, weight: .medium, design: .monospaced))
                    .foregroundColor(.secondary)
            }

            // Split Desktop Workspaces Toggle Button
            Button(action: {
                splitManager.toggleSplit()
            }) {
                HStack(spacing: 5) {
                    Image(systemName: splitManager.isSplitActive ? "rectangle.split.2x1.fill" : "rectangle.split.2x1")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(splitManager.isSplitActive ? .cyan : .secondary)
                    Text(splitManager.isSplitActive ? "Dual Workspaces Active (\(Int(splitManager.splitRatio * 100)):\(Int((1 - splitManager.splitRatio) * 100)))" : "Split Desktop (2 Workspaces)")
                        .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                        .foregroundColor(splitManager.isSplitActive ? .cyan : .primary)
                    Spacer()
                    Text(splitManager.isSplitActive ? "Exit Split" : "Split Screen")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(splitManager.isSplitActive ? .cyan : .secondary)
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(splitManager.isSplitActive ? Color.cyan.opacity(0.15) : Color.primary.opacity(0.04))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(splitManager.isSplitActive ? Color.cyan.opacity(0.4) : Color.primary.opacity(0.06), lineWidth: 0.8)
                )
            }
            .buttonStyle(.plain)

            // Dual Partition Desktops with Separate MenuBars Toggle Button
            Button(action: {
                partitionManager.togglePartition()
                if partitionManager.isPartitionActive {
                    DualDesktopPartitionWindow.shared.show()
                } else {
                    DualDesktopPartitionWindow.shared.close()
                }
            }) {
                HStack(spacing: 5) {
                    Image(systemName: partitionManager.isPartitionActive ? "menubar.rectangle" : "menubar.arrow.up.rectangle")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(partitionManager.isPartitionActive ? .yellow : .secondary)
                    Text(partitionManager.isPartitionActive ? "Dual Desktops (2 MenuBars Active)" : "Dual Desktops (Separate MenuBars)")
                        .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                        .foregroundColor(partitionManager.isPartitionActive ? .yellow : .primary)
                    Spacer()
                    Text(partitionManager.isPartitionActive ? "Exit Desktops" : "Launch 2 Bars")
                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                        .foregroundColor(partitionManager.isPartitionActive ? .yellow : .secondary)
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(partitionManager.isPartitionActive ? Color.yellow.opacity(0.15) : Color.primary.opacity(0.04))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(partitionManager.isPartitionActive ? Color.yellow.opacity(0.4) : Color.primary.opacity(0.06), lineWidth: 0.8)
                )
            }
            .buttonStyle(.plain)
            .help("Toggle Dual Split Desktop Workspaces so agents operate concurrently side-by-side")

            // Quick Agent Desktop Grid (VS Code, Browser, Terminal, Center)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                ForEach(agentSpaceManager.spaces) { agent in
                    DesktopViewsCenterAgentCard(agent: agent)
                }
            }
        }
        .padding(7)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.primary.opacity(0.03))
        )
    }
}

// MARK: - Observatory Agent Badge Card

public struct DesktopViewsCenterAgentCard: View {
    let agent: AgentVirtualSpace
    @ObservedObject var manager: MacDesktopsManager = .shared

    private var isFocused: Bool {
        manager.currentSpaceIndex == agent.assignedDesktopIndex
    }

    private var statusColor: Color {
        switch agent.status {
        case .running: return .green
        case .awaitingApproval: return .orange
        case .completed: return .cyan
        case .idle: return .gray.opacity(0.5)
        }
    }

    public var body: some View {
        Button(action: {
            HapticFeedback.selection()
            manager.switchToDesktop(index: agent.assignedDesktopIndex)
        }) {
            HStack(spacing: 6) {
                Image(systemName: agent.agentType.icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(isFocused ? .cyan : .primary)

                VStack(alignment: .leading, spacing: 1) {
                    HStack(spacing: 4) {
                        Text(agent.name)
                            .font(.system(size: 9.5, weight: isFocused ? .bold : .medium, design: .rounded))
                            .foregroundColor(isFocused ? .cyan : .primary)
                            .lineLimit(1)
                        Circle()
                            .fill(statusColor)
                            .frame(width: 4, height: 4)
                    }
                    Text("Desktop \(agent.assignedDesktopIndex)")
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(isFocused ? Color.cyan.opacity(0.16) : Color.primary.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(isFocused ? Color.cyan.opacity(0.4) : Color.clear, lineWidth: 0.8)
            )
        }
        .buttonStyle(.plain)
        .help("View \(agent.name) on Desktop \(agent.assignedDesktopIndex)")
    }
}

// MARK: - Individual Stacked Desktop Layer Card

public struct StackedDesktopLayerCardView: View {
    let idx: Int
    let space: MacDesktopSpace
    let isHoveringDeck: Bool
    @Binding var editingSpaceIndex: Int?
    @Binding var tempName: String

    @ObservedObject var manager: MacDesktopsManager = .shared
    @ObservedObject var agentSpaceManager: AgentVirtualSpaceManager = .shared

    private var isCurrent: Bool {
        space.index == manager.currentSpaceIndex
    }

    private var isLocked: Bool {
        manager.isWorkspaceLocked(for: space)
    }

    private var fanOffset: CGFloat {
        let spacing: CGFloat = isHoveringDeck ? 44.0 : 20.0
        return CGFloat(idx) * spacing
    }

    private var cardZIndex: Double {
        isCurrent ? 100 : Double(manager.spaces.count - idx)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Top Row: Indicator, Title, Lock/Unlock, Active Switch
            HStack {
                HStack(spacing: 3) {
                    Image(systemName: isLocked ? "lock.fill" : (isCurrent ? "lock.open.fill" : "square.stack.3d.up"))
                        .font(.system(size: 8.5, weight: .bold))
                        .foregroundColor(isCurrent ? .cyan : (isLocked ? .orange : .secondary))

                    Text("Layer \(space.index)")
                        .font(.system(size: 9, weight: .heavy, design: .monospaced))
                        .foregroundColor(isCurrent ? .cyan : .secondary)
                }
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(isCurrent ? Color.cyan.opacity(0.18) : Color.black.opacity(0.35))
                )

                if editingSpaceIndex == space.index {
                    TextField("Workspace Name", text: $tempName, onCommit: {
                        manager.setWorkspaceName(for: space, name: tempName)
                        editingSpaceIndex = nil
                    })
                    .textFieldStyle(.plain)
                    .font(.system(size: 11, weight: .bold))
                    .frame(width: 140)
                    .padding(2)
                    .background(RoundedRectangle(cornerRadius: 4).fill(Color.primary.opacity(0.1)))
                } else {
                    Text(manager.workspaceName(for: space))
                        .font(.system(size: 11, weight: isCurrent ? .bold : .medium, design: .rounded))
                        .foregroundColor(isCurrent ? .primary : .secondary)
                        .lineLimit(1)
                        .onTapGesture(count: 2) {
                            tempName = manager.workspaceName(for: space)
                            editingSpaceIndex = space.index
                        }
                }

                Spacer()

                Button(action: {
                    manager.toggleWorkspaceLock(for: space)
                }) {
                    Image(systemName: isLocked ? "lock.shield.fill" : "lock.open")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(isLocked ? .orange : .secondary.opacity(0.6))
                        .padding(4)
                        .background(Circle().fill(Color.primary.opacity(0.05)))
                }
                .buttonStyle(.plain)
                .help(isLocked ? "Unlock Workspace Protection" : "Lock / Protect Workspace")

                Button(action: {
                    manager.unlockAndSwitch(to: space)
                }) {
                    Text(isCurrent ? "Active" : "Unlock")
                        .font(.system(size: 8.5, weight: .bold, design: .rounded))
                        .foregroundColor(isCurrent ? .black : .white)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2.5)
                        .background(
                            Capsule()
                                .fill(isCurrent ? Color.cyan : Color.white.opacity(0.15))
                        )
                }
                .buttonStyle(.plain)
            }

            // Preview Thumbnail & Agent Meta Row
            HStack(spacing: 8) {
                StackedDesktopThumbnailView(spaceIndex: space.index, isCurrent: isCurrent)

                DesktopLayerAgentMetaView(
                    agent: agentSpaceManager.spaceForDesktop(space.index),
                    isCurrent: isCurrent,
                    isLocked: isLocked,
                    spaceIndex: space.index
                )
                Spacer()
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor).opacity(isCurrent ? 0.95 : 0.80))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(isCurrent ? Color.cyan.opacity(0.85) : Color.white.opacity(0.12), lineWidth: isCurrent ? 1.5 : 0.8)
        )
        .shadow(
            color: isCurrent ? Color.cyan.opacity(0.40) : Color.black.opacity(0.25),
            radius: isCurrent ? 8 : 4,
            y: isCurrent ? 4 : 2
        )
        .offset(y: fanOffset)
        .zIndex(cardZIndex)
        .contentShape(Rectangle())
        .onTapGesture {
            manager.unlockAndSwitch(to: space)
        }
    }
}

// MARK: - Thumbnail Preview Box

public struct StackedDesktopThumbnailView: View {
    let spaceIndex: Int
    let isCurrent: Bool

    @ObservedObject var manager: MacDesktopsManager = .shared
    @ObservedObject var wallpaperManager: WallpaperManager = .shared

    public var body: some View {
        ZStack(alignment: .bottomTrailing) {
            if let live = manager.desktopLivePreviews[spaceIndex] {
                Image(nsImage: live)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 68, height: 42)
                    .clipped()
            } else if let wp = wallpaperManager.activeWallpaperImage {
                Image(nsImage: wp)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 68, height: 42)
                    .clipped()
            } else {
                LinearGradient(
                    colors: [Color.cyan.opacity(0.6), Color.blue.opacity(0.8)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(width: 68, height: 42)
            }

            VStack {
                HStack {
                    Circle().fill(Color.white.opacity(0.7)).frame(width: 2.5, height: 2.5)
                    Circle().fill(Color.white.opacity(0.7)).frame(width: 2.5, height: 2.5)
                    Spacer()
                }
                .padding(2.5)
                Spacer()
            }
        }
        .frame(width: 68, height: 42)
        .cornerRadius(5)
        .overlay(
            RoundedRectangle(cornerRadius: 5)
                .strokeBorder(isCurrent ? Color.cyan : Color.white.opacity(0.15), lineWidth: isCurrent ? 1.5 : 0.6)
        )
    }
}

// MARK: - Layer Agent Metadata View

public struct DesktopLayerAgentMetaView: View {
    let agent: AgentVirtualSpace?
    let isCurrent: Bool
    let isLocked: Bool
    let spaceIndex: Int

    private var statusColor: Color {
        guard let agent = agent else { return .secondary }
        switch agent.status {
        case .running: return .green
        case .awaitingApproval: return .orange
        case .completed: return .cyan
        case .idle: return .secondary
        }
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let agent = agent {
                HStack(spacing: 4) {
                    Text(agent.name)
                        .font(.system(size: 9.5, weight: .bold, design: .rounded))
                        .foregroundColor(isCurrent ? .cyan : .primary)
                        .lineLimit(1)

                    Text(agent.status.rawValue)
                        .font(.system(size: 7.5, weight: .bold, design: .monospaced))
                        .foregroundColor(statusColor)
                        .padding(.horizontal, 3.5)
                        .padding(.vertical, 1)
                        .background(Capsule().fill(Color.primary.opacity(0.06)))
                }

                Text(agent.activeTask.isEmpty ? "Assigned to Desktop \(spaceIndex)" : agent.activeTask)
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
                    .lineLimit(1)

                if !agent.assignedTools.isEmpty {
                    HStack(spacing: 3) {
                        ForEach(agent.assignedTools.prefix(3), id: \.self) { tool in
                            Text(tool)
                                .font(.system(size: 7, weight: .medium, design: .monospaced))
                                .foregroundColor(.cyan.opacity(0.85))
                                .padding(.horizontal, 3)
                                .padding(.vertical, 0.5)
                                .background(RoundedRectangle(cornerRadius: 2.5).fill(Color.cyan.opacity(0.12)))
                        }
                    }
                }
            } else {
                Text(isCurrent ? "🔓 Unlocked & Focused" : (isLocked ? "🔒 Locked Layer" : "Ready to Unlock"))
                    .font(.system(size: 9.5, weight: .semibold))
                    .foregroundColor(isCurrent ? .cyan : (isLocked ? .orange : .secondary))

                Text("Switch instantly to Desktop \(spaceIndex) (Hardware WindowServer)")
                    .font(.system(size: 8.5))
                    .foregroundColor(.secondary.opacity(0.8))
                    .lineLimit(2)
            }
        }
    }
}

// MARK: - Compact Stacked Desktop Layers Pill for Bar

public struct CompactStackedDesktopLayersBarView: View {
    @AppStorage(PrefKey.appLanguage) var appLanguage: String = "English (US)"
    @ObservedObject var manager: MacDesktopsManager = .shared
    @State private var showDeckPopover: Bool = false

    public init() {}

    public var body: some View {
        HStack(spacing: 3) {
            // Previous Layer Arrow
            Button(action: {
                manager.navigatePrevious()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 7.5, weight: .bold))
                    .foregroundColor(manager.currentSpaceIndex > 1 ? .primary : .secondary.opacity(0.3))
                    .frame(width: 13, height: 21)
                    .background(RoundedRectangle(cornerRadius: 3.5).fill(Color.primary.opacity(0.04)))
            }
            .buttonStyle(.plain)
            .disabled(manager.currentSpaceIndex <= 1)
            .help("Previous Stacked Desktop Layer (⌃←)")

            // Stacked Layers Visual Deck Button
            Button(action: {
                showDeckPopover.toggle()
            }) {
                HStack(spacing: 4) {
                    // 3D Mini Layer Deck Graphics
                    ZStack {
                        // Background Layer 2
                        RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                            .fill(Color.cyan.opacity(0.25))
                            .frame(width: 14, height: 10)
                            .offset(x: 2, y: -2)

                        // Foreground Layer 1
                        RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                            .fill(Color.cyan.opacity(0.85))
                            .frame(width: 14, height: 10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 2.5)
                                    .strokeBorder(Color.white.opacity(0.6), lineWidth: 0.5)
                            )
                    }
                    .frame(width: 18, height: 14)

                    // Layer Label & Current Workspace
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 2) {
                            Text("Layer \(manager.currentSpaceIndex)")
                                .font(.system(size: 7.5, weight: .heavy, design: .monospaced))
                                .foregroundColor(.cyan)
                            Image(systemName: "lock.open.fill")
                                .font(.system(size: 5.5))
                                .foregroundColor(.cyan)
                        }
                        Text(currentWorkspaceShortName())
                            .font(.system(size: 7, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, 5)
                .frame(height: 21)
                .background(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.cyan.opacity(0.12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .strokeBorder(Color.cyan.opacity(0.35), lineWidth: 0.8)
                )
            }
            .buttonStyle(.plain)
            .help("Stacked Desktop Layers: Click to unlock & inspect all workspaces")
            .popover(isPresented: $showDeckPopover, arrowEdge: .bottom) {
                StackedDesktopLayersDeckView()
                    .frame(width: 320)
                    .padding(8)
            }

            // + Stack Layer Button
            Button(action: {
                manager.createDesktop()
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 7, weight: .black))
                    .foregroundColor(.cyan)
                    .frame(width: 15, height: 21)
                    .background(
                        RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                            .fill(Color.cyan.opacity(0.10))
                    )
            }
            .buttonStyle(.plain)
            .help("Stack New Workspace Layer (+1)")

            // Next Layer Arrow
            Button(action: {
                manager.navigateNext()
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 7.5, weight: .bold))
                    .foregroundColor(manager.currentSpaceIndex < manager.spaces.count ? .primary : .secondary.opacity(0.3))
                    .frame(width: 13, height: 21)
                    .background(RoundedRectangle(cornerRadius: 3.5).fill(Color.primary.opacity(0.04)))
            }
            .buttonStyle(.plain)
            .disabled(manager.currentSpaceIndex >= manager.spaces.count)
            .help("Next Stacked Desktop Layer (⌃→)")
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 1)
        .background(
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.20))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.8)
        )
    }

    private func currentWorkspaceShortName() -> String {
        if let cur = manager.spaces.first(where: { $0.isCurrent }) {
            let full = manager.workspaceName(for: cur)
            return full.components(separatedBy: "•").first?.trimmingCharacters(in: .whitespaces) ?? full
        }
        return "Main"
    }
}
