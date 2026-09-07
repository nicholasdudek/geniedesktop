import AppKit
import Foundation
import SwiftUI

// MARK: - 📱 Right-Edge Vertical Magnification Dock
// Emulates macOS Dock when positioned on the Right side of the display:
// Sleek liquid glass shelf, fluid vertical magnification wave expanding to the left into the workspace,
// active running indicators, dynamic tooltips, and quick slide-over summoning.
public struct RightEdgeDockTabsView: View {
    @Binding var isRightChatDockOpen: Bool
    @Binding var isRightAppsDockOpen: Bool
    var coexistMode: String = "Side-by-Side 📐"

    @ObservedObject private var finderChatManager = FinderChatWindowManager.shared
    @ObservedObject private var dockManager = DockAndDesktopManager.shared
    @ObservedObject private var desktopWindowManager = DesktopWindowManager.shared
    @ObservedObject private var trashMonitor = TrashMonitor.shared

    @AppStorage(PrefKey.dockAlwaysShowTrash) var dockAlwaysShowTrash: Bool = true
    @AppStorage(PrefKey.dockShowFolderStacks) var dockShowFolderStacks: Bool = true
    @AppStorage(PrefKey.dockActiveAppsOnly) var dockActiveAppsOnly: Bool = false

    @State private var hoveredItemId: String? = nil
    @State private var isDockHovered: Bool = false
    @State private var hoverDebounceTimer: Timer? = nil

    public init(
        isRightChatDockOpen: Binding<Bool>,
        isRightAppsDockOpen: Binding<Bool>,
        coexistMode: String = "Side-by-Side 📐"
    ) {
        self._isRightChatDockOpen = isRightChatDockOpen
        self._isRightAppsDockOpen = isRightAppsDockOpen
        self.coexistMode = coexistMode
    }

    // MARK: - Displayed Dock Apps
    private var displayedDockApps: [DockAppItem] {
        dockManager.dockItems.filter { item in
            item.bundleIdentifier != "com.nicholasdudek.genie" &&
            item.id != "com.nicholasdudek.genie" &&
            item.name.lowercased() != "genie" &&
            (!dockActiveAppsOnly || item.isRunning)
        }
    }

    // Dynamic item list for continuous parabolic magnification curve
    private var allItemIds: [String] {
        var ids = ["chat", "apps"]
        ids.append(contentsOf: displayedDockApps.prefix(10).map { $0.id })
        if dockShowFolderStacks {
            ids.append(contentsOf: dockManager.dockFolders.prefix(3).map { $0.id })
        }
        ids.append("settings")
        if dockAlwaysShowTrash {
            ids.append("trash")
        }
        return ids
    }

    // MARK: - Vertical Parabolic Magnification Wave
    private func magnificationWave(for itemId: String) -> (scale: CGFloat, xOffset: CGFloat, yOffset: CGFloat, zIndex: Double) {
        guard let hoveredId = hoveredItemId,
              let hoveredIdx = allItemIds.firstIndex(of: hoveredId),
              let myIdx = allItemIds.firstIndex(of: itemId) else {
            return (1.0, 0.0, 0.0, 1.0)
        }

        let dist = abs(hoveredIdx - myIdx)
        let diff = myIdx - hoveredIdx
        let ySign: CGFloat = diff > 0 ? 1.0 : -1.0

        switch dist {
        case 0:
            // Hovered icon: blossoms outwards to the left away from the right screen bezel
            return (1.55, -16.0, 0.0, 40.0)
        case 1:
            // Immediate neighbors: scale up and spread gently vertically
            return (1.28, -8.0, ySign * 4.0, 20.0)
        case 2:
            // Secondary neighbors
            return (1.12, -3.0, ySign * 1.5, 10.0)
        default:
            return (1.0, 0.0, 0.0, 1.0)
        }
    }

    private func handleItemHover(id: String, hovering: Bool) {
        if hovering {
            hoverDebounceTimer?.invalidate()
            hoverDebounceTimer = nil
            withAnimation(.spring(response: 0.20, dampingFraction: 0.74)) {
                hoveredItemId = id
            }
        } else if hoveredItemId == id {
            hoverDebounceTimer?.invalidate()
            hoverDebounceTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: false) { _ in
                Task { @MainActor in
                    withAnimation(.spring(response: 0.24, dampingFraction: 0.76)) {
                        if hoveredItemId == id {
                            hoveredItemId = nil
                        }
                    }
                }
            }
        }
    }

    // MARK: - Body
    public var body: some View {
        let isAppsActive = (desktopWindowManager.currentStation == .applications || isRightAppsDockOpen)

        VStack(alignment: .trailing, spacing: 5) {
            // ── 1. PRIMARY GENIE SHORTCUTS (Chat & Applications) ──
            dockShortcutButton(
                id: "chat",
                title: "Genie Chat",
                iconName: finderChatManager.isVisible ? "bubble.left.and.bubble.right.fill" : "bubble.left.and.bubble.right",
                tintColor: Color.cyan,
                isActive: finderChatManager.isVisible
            ) {
                toggleChatDock()
            }

            dockShortcutButton(
                id: "apps",
                title: "Applications",
                iconName: isAppsActive ? "square.grid.2x2.fill" : "square.grid.2x2",
                tintColor: Color.orange,
                isActive: isAppsActive
            ) {
                toggleAppsDock()
            }

            // ── 2. SEPARATOR PILL ──
            Capsule()
                .fill(Color.white.opacity(0.22))
                .frame(width: 22, height: 1.5)
                .padding(.vertical, 3)
                .padding(.trailing, 8)

            // ── 3. SYSTEM DOCK APPLICATIONS (With Live Magnification & Running Dots) ──
            ForEach(Array(displayedDockApps.prefix(10))) { item in
                dockAppItemButton(item: item)
            }

            // ── 4. PINNED FOLDER STACKS (Downloads, Documents, Applications) ──
            if dockShowFolderStacks && !dockManager.dockFolders.isEmpty {
                Capsule()
                    .fill(Color.white.opacity(0.22))
                    .frame(width: 22, height: 1.5)
                    .padding(.vertical, 3)
                    .padding(.trailing, 8)

                ForEach(Array(dockManager.dockFolders.prefix(3))) { folder in
                    dockFolderButton(folder: folder)
                }
            }

            // ── 5. UTILITIES (Settings & Trash) ──
            Capsule()
                .fill(Color.white.opacity(0.22))
                .frame(width: 22, height: 1.5)
                .padding(.vertical, 3)
                .padding(.trailing, 8)

            dockShortcutButton(
                id: "settings",
                title: "Settings",
                iconName: "gearshape.fill",
                tintColor: Color.white.opacity(0.85),
                isActive: false
            ) {
                HapticFeedback.selection()
                AppDelegate.shared?.showMenuBarSettingsDropdown(targetTab: .system)
            }

            if dockAlwaysShowTrash {
                dockShortcutButton(
                    id: "trash",
                    title: trashMonitor.isTrashFull ? "Trash (\(trashMonitor.trashItemCount))" : "Trash",
                    iconName: trashMonitor.isTrashFull ? "trash.fill" : "trash",
                    tintColor: trashMonitor.isTrashFull ? Color.red.opacity(0.9) : Color.white.opacity(0.75),
                    isActive: false
                ) {
                    HapticFeedback.selection()
                    let trashURL = URL(fileURLWithPath: NSHomeDirectory() + "/.Trash")
                    NSWorkspace.shared.open(trashURL)
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.leading, 8)
        .padding(.trailing, 6)
        .background(
            ZStack {
                VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow, state: .active)
                Color(red: 0.07, green: 0.07, blue: 0.11).opacity(0.70)
            }
        )
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 18,
                bottomLeadingRadius: 18,
                bottomTrailingRadius: 0,
                topTrailingRadius: 0,
                style: .continuous
            )
        )
        .overlay(
            UnevenRoundedRectangle(
                topLeadingRadius: 18,
                bottomLeadingRadius: 18,
                bottomTrailingRadius: 0,
                topTrailingRadius: 0,
                style: .continuous
            )
            .strokeBorder(
                LinearGradient(
                    colors: [Color.white.opacity(0.35), Color.white.opacity(0.12), Color.white.opacity(0.04)],
                    startPoint: .topLeading,
                    endPoint: .bottomLeading
                ),
                lineWidth: 0.85
            )
        )
        .shadow(color: Color.black.opacity(0.50), radius: 16, x: -6, y: 0)
        .offset(x: (isDockHovered || hoveredItemId != nil) ? -2 : 0)
        .animation(.spring(response: 0.28, dampingFraction: 0.78), value: isDockHovered)
        .animation(.spring(response: 0.28, dampingFraction: 0.78), value: isRightChatDockOpen)
        .animation(.spring(response: 0.28, dampingFraction: 0.78), value: isRightAppsDockOpen)
        .onHover { hovering in
            withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                isDockHovered = hovering
            }
        }
    }

    // MARK: - Dock Shortcut Button (Chat, Apps, Settings, Trash)
    @ViewBuilder
    private func dockShortcutButton(
        id: String,
        title: String,
        iconName: String,
        tintColor: Color,
        isActive: Bool,
        action: @escaping () -> Void
    ) -> some View {
        let wave = magnificationWave(for: id)
        let isHovered = (hoveredItemId == id)

        HStack(spacing: 8) {
            // Live Tooltip Badge sliding to the left
            if isHovered {
                Text(title)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(
                        ZStack {
                            VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow, state: .active)
                            Color.black.opacity(0.70)
                        }
                    )
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.25), lineWidth: 0.75))
                    .shadow(color: Color.black.opacity(0.40), radius: 6, x: -2, y: 1)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.85).combined(with: .opacity).combined(with: .move(edge: .trailing)),
                        removal: .opacity
                    ))
            }

            Button(action: action) {
                ZStack(alignment: .leading) {
                    // Running / Active glow dot
                    if isActive {
                        Circle()
                            .fill(tintColor)
                            .frame(width: 4, height: 4)
                            .shadow(color: tintColor.opacity(0.9), radius: 3)
                            .offset(x: -5)
                    }

                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(
                                isActive ? tintColor.opacity(0.35) :
                                (isHovered ? Color.white.opacity(0.18) : Color.white.opacity(0.06))
                            )
                            .frame(width: 28, height: 28)

                        Image(systemName: iconName)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(isActive ? tintColor : (isHovered ? .white : .white.opacity(0.85)))
                    }
                    .frame(width: 28, height: 28)
                }
                .frame(width: 28, height: 28)
                .scaleEffect(wave.scale, anchor: .trailing)
                .offset(x: wave.xOffset, y: wave.yOffset)
                .zIndex(wave.zIndex)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .onHover { h in
                handleItemHover(id: id, hovering: h)
            }
        }
    }

    // MARK: - System Dock App Button (With Icon & Running Dot)
    @ViewBuilder
    private func dockAppItemButton(item: DockAppItem) -> some View {
        let wave = magnificationWave(for: item.id)
        let isHovered = (hoveredItemId == item.id)
        let isRunning = item.isRunning

        HStack(spacing: 8) {
            // Live Tooltip Badge sliding to the left
            if isHovered {
                Text(item.name)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(
                        ZStack {
                            VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow, state: .active)
                            Color.black.opacity(0.70)
                        }
                    )
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.25), lineWidth: 0.75))
                    .shadow(color: Color.black.opacity(0.40), radius: 6, x: -2, y: 1)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.85).combined(with: .opacity).combined(with: .move(edge: .trailing)),
                        removal: .opacity
                    ))
            }

            Button(action: {
                activateApp(item)
            }) {
                ZStack(alignment: .leading) {
                    // Running application dot
                    if isRunning {
                        Circle()
                            .fill(Color(red: 0.0, green: 0.95, blue: 0.55))
                            .frame(width: 3.5, height: 3.5)
                            .shadow(color: Color.green.opacity(0.8), radius: 2.5)
                            .offset(x: -5)
                    }

                    ZStack {
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .fill(isHovered ? Color.white.opacity(0.18) : Color.clear)
                            .frame(width: 28, height: 28)

                        if let icon = item.icon {
                            Image(nsImage: icon)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 22, height: 22)
                                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                                .shadow(color: Color.black.opacity(isHovered ? 0.35 : 0.15), radius: 2, y: 1)
                        } else {
                            Image(systemName: "app.fill")
                                .font(.system(size: 15))
                                .foregroundColor(.white.opacity(0.75))
                        }
                    }
                    .frame(width: 28, height: 28)
                }
                .frame(width: 28, height: 28)
                .scaleEffect(wave.scale, anchor: .trailing)
                .offset(x: wave.xOffset, y: wave.yOffset)
                .zIndex(wave.zIndex)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .onHover { h in
                handleItemHover(id: item.id, hovering: h)
            }
        }
    }

    // MARK: - Pinned Folder Stack Button
    @ViewBuilder
    private func dockFolderButton(folder: DockFolderItem) -> some View {
        let wave = magnificationWave(for: folder.id)
        let isHovered = (hoveredItemId == folder.id)

        HStack(spacing: 8) {
            if isHovered {
                Text(folder.name)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(
                        ZStack {
                            VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow, state: .active)
                            Color.black.opacity(0.70)
                        }
                    )
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.25), lineWidth: 0.75))
                    .shadow(color: Color.black.opacity(0.40), radius: 6, x: -2, y: 1)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.85).combined(with: .opacity).combined(with: .move(edge: .trailing)),
                        removal: .opacity
                    ))
            }

            Button(action: {
                HapticFeedback.selection()
                folder.openInFinder()
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(isHovered ? Color.white.opacity(0.18) : Color.clear)
                        .frame(width: 28, height: 28)

                    if let icon = folder.icon {
                        Image(nsImage: icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 22, height: 22)
                            .shadow(color: Color.black.opacity(isHovered ? 0.35 : 0.15), radius: 2, y: 1)
                    } else {
                        Image(systemName: "folder.fill")
                            .font(.system(size: 15))
                            .foregroundColor(.cyan)
                    }
                }
                .frame(width: 28, height: 28)
                .scaleEffect(wave.scale, anchor: .trailing)
                .offset(x: wave.xOffset, y: wave.yOffset)
                .zIndex(wave.zIndex)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .onHover { h in
                handleItemHover(id: folder.id, hovering: h)
            }
        }
    }

    // MARK: - Actions
    private func toggleChatDock() {
        HapticFeedback.selection()
        FinderChatWindowManager.shared.toggle()
        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
            isRightChatDockOpen = FinderChatWindowManager.shared.isVisible
            if isRightChatDockOpen {
                isRightAppsDockOpen = false
                NotificationCenter.default.post(name: NSNotification.Name("NexusCloseAllRollupsExceptChat"), object: nil)
            }
        }
    }

    private func toggleAppsDock() {
        HapticFeedback.selection()
        withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
            if desktopWindowManager.currentStation == .applications {
                desktopWindowManager.switchToStation(.desktop)
                isRightAppsDockOpen = false
            } else {
                desktopWindowManager.switchToStation(.applications)
                isRightAppsDockOpen = false
                isRightChatDockOpen = false
            }
        }
    }

    private func activateApp(_ item: DockAppItem) {
        HapticFeedback.selection()
        if let app = item.runningApp {
            if #available(macOS 14.0, *) {
                app.activate()
            } else {
                app.activate(options: [.activateIgnoringOtherApps])
            }
        } else if let url = item.bundleURL {
            NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
        } else if let bid = item.bundleIdentifier, let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bid) {
            NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
        }
    }
}
