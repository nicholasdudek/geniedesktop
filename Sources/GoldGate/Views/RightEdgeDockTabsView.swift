import AppKit
import ApplicationServices
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
    @AppStorage(PrefKey.isChatLockedInPlace) private var isChatLockedInPlace: Bool = false
    @AppStorage(PrefKey.dockBackgroundOpacity) private var dockBackgroundOpacity: Double = 0.70

    @State private var hoveredItemId: String? = nil
    @State private var isDockHovered: Bool = false
    @State private var hoverDebounceTimer: Timer? = nil
    @State private var scrollSelectionId: String? = nil
    @State private var floatingOffset: CGSize = .zero
    @State private var dragStartOffset: CGSize = .zero

    // Auto-hide: dock slides off the right edge when idle, and slides back in when the
    // cursor approaches the screen's right edge. Independent of the desktop summon/dismiss
    // system, which controls a different full-screen overlay.
    @State private var isRevealed: Bool = true
    @State private var edgeRevealTimer: Timer? = nil
    @State private var autoHideTimer: Timer? = nil

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
            item.bundleIdentifier != "com.apple.MobileSMS" &&
            item.id != "com.apple.MobileSMS" &&
            item.name.lowercased() != "messages" &&
            (!dockActiveAppsOnly || item.isRunning)
        }
    }

    // Dynamic item list for continuous parabolic magnification curve
    private var allItemIds: [String] {
        var ids = ["genie", "chat"]
        ids.append(contentsOf: displayedDockApps.map { $0.id })
        if dockShowFolderStacks {
            ids.append(contentsOf: dockManager.dockFolders.prefix(3).map { $0.id })
        }
        ids.append("settings")
        ids.append("messages")
        if dockAlwaysShowTrash {
            ids.append("trash")
        }
        // Applications is the final destination in the vertical switcher.
        ids.append("apps")
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

    // MARK: - Auto-Hide / Edge Reveal
    private func scheduleAutoHide() {
        autoHideTimer?.invalidate()
        autoHideTimer = Timer.scheduledTimer(withTimeInterval: 1.4, repeats: false) { _ in
            Task { @MainActor in
                guard !isDockHovered, hoveredItemId == nil,
                      !isRightChatDockOpen, !isRightAppsDockOpen else { return }
                withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                    isRevealed = false
                }
            }
        }
    }

    /// Polls the hardware cursor position (rather than SwiftUI .onHover, which can't fire once the
    /// dock is off-screen) so the dock can slide back in as soon as the cursor nears the right edge.
    private func startEdgeRevealPolling() {
        edgeRevealTimer?.invalidate()
        edgeRevealTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            Task { @MainActor in
                let mouseLoc = NSEvent.mouseLocation
                guard let screen = NSScreen.screens.first(where: { $0.frame.contains(mouseLoc) }) ?? NSScreen.main else { return }
                let distanceFromRightEdge = screen.frame.maxX - mouseLoc.x
                if distanceFromRightEdge <= 24, !isRevealed {
                    autoHideTimer?.invalidate()
                    autoHideTimer = nil
                    withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                        isRevealed = true
                    }
                }
            }
        }
    }

    // MARK: - Body
    public var body: some View {
        let isAppsActive = (desktopWindowManager.currentStation == .applications || isRightAppsDockOpen)

        VStack(alignment: .trailing, spacing: 5) {
            // ── 1. GENIE LAUNCHER (reveals this dock) ──
            dockShortcutButton(
                id: "genie",
                title: "Genie Dock",
                iconName: "sparkles",
                tintColor: .cyan,
                isActive: isRightChatDockOpen || isRightAppsDockOpen
            ) {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                    isRightChatDockOpen = true
                    isRightAppsDockOpen = false
                }
            }

            // ── 2. PRIMARY CHAT SHORTCUT (Consolidated Single Chat Window) ──
            dockShortcutButton(
                id: "chat",
                title: "Genie Chat",
                iconName: finderChatManager.isVisible ? "bubble.left.and.bubble.right.fill" : "bubble.left.and.bubble.right",
                tintColor: Color.cyan,
                isActive: finderChatManager.isVisible
            ) {
                HapticFeedback.selection()
                toggleChatDock()
            }

            // ── 2. SEPARATOR PILL ──
            Capsule()
                .fill(Color.white.opacity(0.22))
                .frame(width: 22, height: 1.5)
                .padding(.vertical, 3)
                .padding(.trailing, 8)

            // ── 3. SYSTEM DOCK APPLICATIONS (Scrollable with Live Magnification & Running Dots) ──
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 5) {
                    ForEach(displayedDockApps) { item in
                        dockAppItemButton(item: item)
                    }
                }
                .padding(.vertical, 2)
            }
            .frame(maxHeight: min(CGFloat(max(displayedDockApps.count, 1) * 44), 380))

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

            // ── 5. UTILITIES (Settings, Messages, Trash & Applications) ──
            Capsule()
                .fill(Color.white.opacity(0.22))
                .frame(width: 22, height: 1.5)
                .padding(.vertical, 3)
                .padding(.trailing, 8)

            dockShortcutButton(
                id: "settings",
                title: "Settings",
                iconName: "gearshape.fill",
                tintColor: Color.purple.opacity(0.95),
                isActive: isRightChatDockOpen
            ) {
                HapticFeedback.selection()
                NotificationCenter.default.post(name: NSNotification.Name("NexusOpenRightDockTab"), object: "Settings")
                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                    isRightChatDockOpen = true
                    isRightAppsDockOpen = false
                }
            }

            dockShortcutButton(
                id: "messages",
                title: "Messages",
                iconName: "message.fill",
                tintColor: Color.green,
                isActive: false
            ) {
                HapticFeedback.selection()
                if let messagesURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.MobileSMS") {
                    NSWorkspace.shared.openApplication(at: messagesURL, configuration: NSWorkspace.OpenConfiguration())
                }
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

            // Applications stays at the bottom of the switcher, after Trash.
            dockShortcutButton(
                id: "apps",
                title: "Applications",
                iconName: isAppsActive ? "square.grid.2x2.fill" : "square.grid.2x2",
                tintColor: Color.orange,
                isActive: isAppsActive
            ) {
                toggleAppsDock()
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
        .background(
            ZStack {
                VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow, state: .active)
                Color(red: 0.07, green: 0.07, blue: 0.11).opacity(dockBackgroundOpacity)
            }
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.35), Color.white.opacity(0.12), Color.white.opacity(0.04)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.85
                )
        )
        .shadow(color: Color.black.opacity(0.50), radius: 16, x: -6, y: 0)
        .padding(.trailing, 4)
        .offset(x: (isDockHovered || hoveredItemId != nil) ? -2 : 0)
        .offset(x: isRevealed ? 0 : 110)
        .opacity(isRevealed ? 1 : 0)
        .allowsHitTesting(isRevealed)
        .animation(.spring(response: 0.28, dampingFraction: 0.78), value: isDockHovered)
        .animation(.spring(response: 0.28, dampingFraction: 0.78), value: isRightChatDockOpen)
        .animation(.spring(response: 0.28, dampingFraction: 0.78), value: isRightAppsDockOpen)
        .animation(.spring(response: 0.34, dampingFraction: 0.82), value: isRevealed)
        .onHover { hovering in
            withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                isDockHovered = hovering
            }
            if hovering {
                autoHideTimer?.invalidate()
                autoHideTimer = nil
                withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) { isRevealed = true }
            } else {
                scheduleAutoHide()
            }
        }
        .onAppear {
            startEdgeRevealPolling()
            // .onHover never fires "false" if the cursor starts outside the dock's bounds
            // (e.g. right after launch), so the idle countdown needs its own kickoff here too.
            scheduleAutoHide()
        }
        .onDisappear {
            edgeRevealTimer?.invalidate()
            edgeRevealTimer = nil
            autoHideTimer?.invalidate()
            autoHideTimer = nil
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusRightDockScrollWheel"))) { notification in
            if let delta = notification.object as? CGFloat {
                cycleDockItem(delta: delta)
            }
        }
        .offset(floatingOffset)
        .simultaneousGesture(
            DragGesture(minimumDistance: 12)
                .onChanged { value in
                    if dragStartOffset == .zero {
                        dragStartOffset = floatingOffset
                    }
                    let frame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
                    let maxX = max(0, frame.width - 96)
                    let maxY = max(0, frame.height - 150)
                    floatingOffset = CGSize(
                        width: min(max(dragStartOffset.width + value.translation.width, -maxX), maxX),
                        height: min(max(dragStartOffset.height - value.translation.height, -maxY), maxY)
                    )
                }
                .onEnded { _ in
                    dragStartOffset = .zero
                }
        )
        .help("Drag the dock to reposition it")
    }

    private func cycleDockItem(delta: CGFloat) {
        let ids = allItemIds
        guard !ids.isEmpty else { return }
        let current = scrollSelectionId.flatMap { ids.firstIndex(of: $0) } ?? (hoveredItemId.flatMap { ids.firstIndex(of: $0) } ?? 0)
        let step = delta < 0 ? 1 : -1
        let next = (current + step + ids.count) % ids.count
        let id = ids[next]
        scrollSelectionId = id
        withAnimation(.spring(response: 0.22, dampingFraction: 0.76)) {
            hoveredItemId = id
        }
        activateDockItem(id: id)
    }

    private func activateDockItem(id: String) {
        HapticFeedback.selection()
        switch id {
        case "chat":
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                isRightChatDockOpen = true
                isRightAppsDockOpen = false
            }
        case "genie":
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                isRightChatDockOpen = true
                isRightAppsDockOpen = false
            }
        case "apps":
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                isRightAppsDockOpen = true
                isRightChatDockOpen = false
            }
        case "settings":
            AppDelegate.shared?.showMenuBarSettingsDropdown(targetTab: .system)
        case "trash":
            NSWorkspace.shared.open(URL(fileURLWithPath: NSHomeDirectory() + "/.Trash"))
        default:
            if let item = displayedDockApps.first(where: { $0.id == id }) {
                activateApp(item)
            } else if let folder = dockManager.dockFolders.first(where: { $0.id == id }) {
                folder.openInFinder()
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
        let cornerRadius: CGFloat = isHovered ? 10 : (isActive ? 9 : 8)

        Button(action: action) {
            ZStack(alignment: .leading) {
                // Running / Active glow dot
                if isActive {
                    Circle()
                        .fill(tintColor)
                        .frame(width: 4, height: 4)
                        .shadow(color: tintColor.opacity(0.9), radius: 3)
                        .offset(x: -5)
                        .animation(.spring(response: 0.24, dampingFraction: 0.74), value: isActive)
                }

                ZStack {
                    // Fluidly morphing button shape
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            isActive ? tintColor.opacity(0.35) :
                            (isHovered ? Color.white.opacity(0.20) : Color.white.opacity(0.07))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .strokeBorder(
                                    isActive ? tintColor.opacity(0.60) :
                                    (isHovered ? Color.white.opacity(0.35) : Color.white.opacity(0.10)),
                                    lineWidth: isHovered ? 1.0 : 0.6
                                )
                        )
                        .shadow(color: isHovered ? tintColor.opacity(0.35) : Color.clear, radius: 6, y: 1)
                        .frame(width: 28, height: 28)

                    Image(systemName: iconName)
                        .font(.system(size: isHovered ? 14 : 13, weight: .bold))
                        .foregroundColor(isActive ? tintColor : (isHovered ? .white : .white.opacity(0.85)))
                }
                .frame(width: 28, height: 28)
            }
            .frame(width: 28, height: 28)
            .scaleEffect(wave.scale, anchor: .trailing)
            .offset(x: wave.xOffset, y: wave.yOffset)
            .zIndex(wave.zIndex)
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .animation(.spring(response: 0.20, dampingFraction: 0.74), value: hoveredItemId)
            .animation(.spring(response: 0.24, dampingFraction: 0.74), value: isActive)
        }
        .buttonStyle(.plain)
        .overlay(alignment: .leading) {
            if isHovered {
                Text(title)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(
                        ZStack {
                            VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow, state: .active)
                            Color.black.opacity(0.75)
                        }
                    )
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.25), lineWidth: 0.75))
                    .shadow(color: Color.black.opacity(0.40), radius: 6, x: -2, y: 1)
                    .fixedSize()
                    .alignmentGuide(.leading) { d in d[.trailing] }
                    .offset(x: -8)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.85).combined(with: .opacity),
                        removal: .opacity
                    ))
                    .zIndex(200)
            }
        }
        .onHover { h in
            handleItemHover(id: id, hovering: h)
        }
    }

    // MARK: - System Dock App Button (With Icon & Running Dot)
    @ViewBuilder
    private func dockAppItemButton(item: DockAppItem) -> some View {
        let wave = magnificationWave(for: item.id)
        let isHovered = (hoveredItemId == item.id)
        let isRunning = item.isRunning
        let cornerRadius: CGFloat = isHovered ? 9 : 7

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
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(isHovered ? Color.white.opacity(0.20) : Color.clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .strokeBorder(isHovered ? Color.white.opacity(0.28) : Color.clear, lineWidth: 0.6)
                        )
                        .frame(width: 28, height: 28)

                    if let icon = item.icon {
                        Image(nsImage: icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: isHovered ? 24 : 22, height: isHovered ? 24 : 22)
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
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .animation(.spring(response: 0.20, dampingFraction: 0.74), value: hoveredItemId)
        }
        .buttonStyle(.plain)
        .overlay(alignment: .leading) {
            if isHovered {
                Text(item.name)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(
                        ZStack {
                            VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow, state: .active)
                            Color.black.opacity(0.75)
                        }
                    )
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.25), lineWidth: 0.75))
                    .shadow(color: Color.black.opacity(0.40), radius: 6, x: -2, y: 1)
                    .fixedSize()
                    .alignmentGuide(.leading) { d in d[.trailing] }
                    .offset(x: -8)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.85).combined(with: .opacity),
                        removal: .opacity
                    ))
                    .zIndex(200)
            }
        }
        .onHover { h in
            handleItemHover(id: item.id, hovering: h)
        }
    }

    // MARK: - Pinned Folder Stack Button
    @ViewBuilder
    private func dockFolderButton(folder: DockFolderItem) -> some View {
        let wave = magnificationWave(for: folder.id)
        let isHovered = (hoveredItemId == folder.id)
        let cornerRadius: CGFloat = isHovered ? 9 : 7

        Button(action: {
            HapticFeedback.selection()
            folder.openInFinder()
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(isHovered ? Color.white.opacity(0.20) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(isHovered ? Color.white.opacity(0.28) : Color.clear, lineWidth: 0.6)
                    )
                    .frame(width: 28, height: 28)

                if let icon = folder.icon {
                    Image(nsImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: isHovered ? 24 : 22, height: isHovered ? 24 : 22)
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
            .contentShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .animation(.spring(response: 0.20, dampingFraction: 0.74), value: hoveredItemId)
        }
        .buttonStyle(.plain)
        .overlay(alignment: .leading) {
            if isHovered {
                Text(folder.name)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(
                        ZStack {
                            VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow, state: .active)
                            Color.black.opacity(0.75)
                        }
                    )
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(Color.white.opacity(0.25), lineWidth: 0.75))
                    .shadow(color: Color.black.opacity(0.40), radius: 6, x: -2, y: 1)
                    .fixedSize()
                    .alignmentGuide(.leading) { d in d[.trailing] }
                    .offset(x: -8)
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.85).combined(with: .opacity),
                        removal: .opacity
                    ))
                    .zIndex(200)
            }
        }
        .onHover { h in
            handleItemHover(id: folder.id, hovering: h)
        }
    }

    // MARK: - Actions
    private func toggleChatDock() {
        HapticFeedback.selection()
        // Single Chat Window: Route exclusively to FinderChatWindowManager
        isRightChatDockOpen = false
        finderChatManager.toggle()
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
        if let app = item.runningApp, !app.isTerminated {
            // Match the native macOS Dock: clicking the already-frontmost app hides it;
            // clicking any other running app brings its window forward (even on another desktop).
            if app.isActive {
                app.hide()
            } else {
                raiseAndActivate(app)
            }
        } else if let url = item.bundleURL {
            NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
        } else if let bid = item.bundleIdentifier, let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bid) {
            NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
        }
    }

    /// `NSRunningApplication.activate()` alone is unreliable when the app's window lives on a
    /// different Space — it often just silently no-ops instead of switching desktops. Explicitly
    /// un-minimizing and raising the window via Accessibility is what actually makes macOS switch.
    private func raiseAndActivate(_ app: NSRunningApplication) {
        if #available(macOS 14.0, *) {
            app.activate()
        } else {
            app.activate(options: [.activateIgnoringOtherApps])
        }
        if let window = SmartGridManager.shared.findWindowElement(pid: app.processIdentifier, fallbackFrame: nil) {
            AXUIElementSetAttributeValue(window, kAXMinimizedAttribute as CFString, kCFBooleanFalse)
            AXUIElementPerformAction(window, kAXRaiseAction as CFString)
        }
    }
}
