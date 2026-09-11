import AppKit
import Foundation
import SwiftUI

// MARK: - 🍎 Apple Mini Dock View inside Genie Chat Window
// Pinned right in the chat workspace with fluid horizontal scroll,
// Apple Dock magnification wave physics, running indicator LEDs, and quick navigation.
public struct ChatWindowAppleDockView: View {
    @ObservedObject var dockManager = DockAndDesktopManager.shared
    @ObservedObject var windowManager = FinderChatWindowManager.shared
    @AppStorage(PrefKey.chatSliderItemOrder) private var savedSliderOrderRaw: String = ""
    @State private var hoveredItemId: String? = nil
    @State private var previewEntryId: String? = nil
    @State private var isCommandPressed: Bool = false
    @State private var draggedItemId: String? = nil
    @State private var dragCurrentTranslationX: CGFloat = 0
    @State private var flagsMonitor: Any? = nil

    public init() {}

    private struct DockItemEntry: Identifiable {
        let id: String
        let title: String
        let iconName: String?
        let nsImage: NSImage?
        let isRunning: Bool
        let isInactiveBackground: Bool
        let runningApp: NSRunningApplication?
        let action: () -> Void

        init(
            id: String,
            title: String,
            iconName: String? = nil,
            nsImage: NSImage? = nil,
            isRunning: Bool = false,
            isInactiveBackground: Bool = false,
            runningApp: NSRunningApplication? = nil,
            action: @escaping () -> Void
        ) {
            self.id = id
            self.title = title
            self.iconName = iconName
            self.nsImage = nsImage
            self.isRunning = isRunning
            self.isInactiveBackground = isInactiveBackground
            self.runningApp = runningApp
            self.action = action
        }
    }

    private var allDockEntries: [DockItemEntry] {
        var entries: [DockItemEntry] = []

        // 1. Built-in Core Studio Programs
        entries.append(DockItemEntry(
            id: "builtin_chat",
            title: "Genie Chat",
            iconName: "bubble.left.and.bubble.right.fill",
            nsImage: nil,
            isRunning: true,
            action: { windowManager.openTab(.chat) }
        ))
        entries.append(DockItemEntry(
            id: "builtin_editor",
            title: "Editor & Preview",
            iconName: "chevron.left.forwardslash.chevron.right",
            nsImage: nil,
            isRunning: false,
            action: { windowManager.openTab(.editor) }
        ))
        entries.append(DockItemEntry(
            id: "builtin_files",
            title: "Files & Finder",
            iconName: "folder.fill",
            nsImage: nil,
            isRunning: false,
            action: { windowManager.openTab(.files) }
        ))
        entries.append(DockItemEntry(
            id: "builtin_terminal",
            title: "Terminal Studio",
            iconName: "terminal.fill",
            nsImage: nil,
            isRunning: false,
            action: { windowManager.openTab(.terminal) }
        ))
        entries.append(DockItemEntry(
            id: "builtin_browser",
            title: "Mini Browser",
            iconName: "globe",
            nsImage: nil,
            isRunning: false,
            action: { windowManager.openTab(.browser) }
        ))
        entries.append(DockItemEntry(
            id: "builtin_notes",
            title: "Notes & Creations",
            iconName: "doc.text.fill",
            nsImage: nil,
            isRunning: false,
            action: { windowManager.openTab(.notes) }
        ))
        entries.append(DockItemEntry(
            id: "builtin_settings",
            title: "Genie Settings",
            iconName: "gearshape.fill",
            nsImage: nil,
            isRunning: false,
            action: { windowManager.openTab(.settings) }
        ))
        entries.append(DockItemEntry(
            id: "builtin_apps",
            title: "Applications Atelier",
            iconName: "square.grid.3x3.fill",
            nsImage: nil,
            isRunning: false,
            action: { windowManager.openTab(.applications) }
        ))

        // 2. All macOS Dock Applications (Pinned, Running & System Applications)
        let currentActivePid = dockManager.activePid > 0 ? dockManager.activePid : (NSWorkspace.shared.frontmostApplication?.processIdentifier ?? 0)
        let rawDockItems = dockManager.dockItems.isEmpty ? DockAndDesktopManager.loadSystemDockApps() : dockManager.dockItems

        for item in rawDockItems {
            if item.id == "com.nicholasdudek.genie" || item.bundleIdentifier == "com.nicholasdudek.genie" || item.id == "com.apple.systempreferences" || item.bundleIdentifier == "com.apple.systempreferences" {
                continue
            }
            let isAppRunning = item.isRunning
            let isFrontmost = (item.processIdentifier == currentActivePid || item.runningApp?.processIdentifier == currentActivePid || item.runningApp?.isActive == true)
            let isInactive = isAppRunning && !isFrontmost

            entries.append(DockItemEntry(
                id: item.id,
                title: item.name,
                iconName: nil,
                nsImage: item.icon,
                isRunning: isAppRunning,
                isInactiveBackground: isInactive,
                runningApp: item.runningApp,
                action: {
                    let bid = item.bundleIdentifier ?? item.id
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.84)) {
                        windowManager.openProgram(bundleId: bid, name: item.name)
                    }
                    if let app = item.runningApp, !app.isTerminated {
                        app.unhide()
                    }
                }
            ))
        }

        return entries
    }

    private var orderedDockEntries: [DockItemEntry] {
        let entries = allDockEntries
        let savedIDs = savedSliderOrderRaw
            .split(separator: ",")
            .map { String($0).trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        guard !savedIDs.isEmpty else { return entries }

        var entryMap: [String: DockItemEntry] = [:]
        for entry in entries {
            entryMap[entry.id] = entry
        }

        var result: [DockItemEntry] = []
        var seenIDs = Set<String>()

        for id in savedIDs {
            if let entry = entryMap[id], !seenIDs.contains(id) {
                result.append(entry)
                seenIDs.insert(id)
            }
        }

        for entry in entries {
            if !seenIDs.contains(entry.id) {
                result.append(entry)
                seenIDs.insert(entry.id)
            }
        }

        return result
    }

    private func magnificationScale(for id: String) -> CGFloat {
        guard let hovered = hoveredItemId else { return 1.0 }
        if hovered == id { return 1.22 }
        let entries = orderedDockEntries
        if let hIdx = entries.firstIndex(where: { $0.id == hovered }),
           let myIdx = entries.firstIndex(where: { $0.id == id }) {
            let dist = abs(hIdx - myIdx)
            if dist == 1 { return 1.10 }
            if dist == 2 { return 1.04 }
        }
        return 1.0
    }

    private func elevationOffset(for id: String) -> CGFloat {
        guard let hovered = hoveredItemId else { return 0 }
        if hovered == id { return -2.5 }
        let entries = orderedDockEntries
        if let hIdx = entries.firstIndex(where: { $0.id == hovered }),
           let myIdx = entries.firstIndex(where: { $0.id == id }) {
            let dist = abs(hIdx - myIdx)
            if dist == 1 { return -1.2 }
            if dist == 2 { return -0.4 }
        }
        return 0
    }

    public var body: some View {
        HStack(spacing: 8) {
            if isCommandPressed {
                HStack(spacing: 4) {
                    Image(systemName: "command")
                        .font(.system(size: 9, weight: .black))
                    Text("DRAG TO REORDER")
                        .font(.system(size: 8, weight: .heavy, design: .monospaced))
                }
                .foregroundColor(.cyan)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.cyan.opacity(0.18)))
                .overlay(Capsule().strokeBorder(Color.cyan.opacity(0.55), lineWidth: 0.8))
                .transition(.scale.combined(with: .opacity))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .bottom, spacing: 6) {
                    ForEach(orderedDockEntries) { entry in
                        let isHovered = hoveredItemId == entry.id
                        let scale = magnificationScale(for: entry.id)
                        let yOff = elevationOffset(for: entry.id)
                        let isCurrentTab = isTabActive(entry)

                        if entry.isInactiveBackground && orderedDockEntries.first(where: { $0.isInactiveBackground })?.id == entry.id {
                            Capsule()
                                .fill(Color.white.opacity(0.20))
                                .frame(width: 1, height: 20)
                                .padding(.horizontal, 3)
                                .padding(.bottom, 7)
                                .zIndex(0)
                        }

                        dockButton(for: entry, isHovered: isHovered, scale: scale, yOff: yOff, isCurrentTab: isCurrentTab)
                            .zIndex(draggedItemId == entry.id ? 200 : (isHovered ? 100 : (scale > 1.05 ? 50 : 1)))
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
            }
            .scrollClipDisabled()
        }
        .frame(height: 48)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.42))
                .overlay(
                    VisualEffectBlur(material: .popover, blendingMode: .withinWindow, state: .active)
                        .clipShape(Capsule())
                        .opacity(0.22)
                )
                .overlay(
                    Capsule()
                        .strokeBorder(isCommandPressed ? Color.cyan.opacity(0.65) : Color.white.opacity(0.14), lineWidth: isCommandPressed ? 1.2 : 0.8)
                )
        )
        .onAppear {
            dockManager.setup()
            dockManager.refreshDockApps()
            isCommandPressed = NSEvent.modifierFlags.contains(.command)
            flagsMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [self] event in
                let cmd = event.modifierFlags.contains(.command)
                DispatchQueue.main.async {
                    if self.isCommandPressed != cmd {
                        withAnimation(.easeInOut(duration: 0.16)) {
                            self.isCommandPressed = cmd
                        }
                    }
                }
                return event
            }
        }
        .onDisappear {
            if let m = flagsMonitor {
                NSEvent.removeMonitor(m)
                flagsMonitor = nil
            }
        }
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didActivateApplicationNotification)) { notif in
            if let app = notif.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication {
                dockManager.activePid = app.processIdentifier
            } else {
                dockManager.activePid = NSWorkspace.shared.frontmostApplication?.processIdentifier ?? 0
            }
        }
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didDeactivateApplicationNotification)) { _ in
            dockManager.activePid = NSWorkspace.shared.frontmostApplication?.processIdentifier ?? 0
        }
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didLaunchApplicationNotification)) { _ in
            dockManager.refreshDockApps()
        }
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didTerminateApplicationNotification)) { _ in
            dockManager.refreshDockApps()
        }
    }

    @ViewBuilder
    private func dockButton(for entry: DockItemEntry, isHovered: Bool, scale: CGFloat, yOff: CGFloat, isCurrentTab: Bool) -> some View {
        let isBeingDragged = draggedItemId == entry.id
        Button(action: {
            if isCommandPressed || draggedItemId != nil {
                return
            }
            HapticFeedback.selection()
            entry.action()
        }) {
            VStack(spacing: 2.5) {
                dockIconContainer(for: entry, isHovered: isHovered, isCurrentTab: isCurrentTab)
                    .scaleEffect(isBeingDragged ? scale * 1.15 : scale, anchor: .bottom)
                    .offset(x: isBeingDragged ? dragCurrentTranslationX : 0, y: isBeingDragged ? yOff - 3 : yOff)
                    .shadow(color: isBeingDragged ? Color.cyan.opacity(0.85) : (isHovered ? Color.black.opacity(0.55) : Color.clear), radius: isBeingDragged ? 8 : 4, y: 2)

                dockIndicatorDot(for: entry, isCurrentTab: isCurrentTab)
            }
            .frame(width: 32, height: 36, alignment: .bottom)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 3)
                .onChanged { gesture in
                    guard isCommandPressed || NSEvent.modifierFlags.contains(.command) else { return }
                    if draggedItemId == nil {
                        draggedItemId = entry.id
                        HapticFeedback.selection()
                    }
                    guard draggedItemId == entry.id else { return }
                    dragCurrentTranslationX = gesture.translation.width

                    let threshold: CGFloat = 22.0
                    let currentList = orderedDockEntries
                    guard let currentIndex = currentList.firstIndex(where: { $0.id == entry.id }) else { return }

                    if dragCurrentTranslationX > threshold && currentIndex + 1 < currentList.count {
                        var newOrder = currentList.map { $0.id }
                        newOrder.swapAt(currentIndex, currentIndex + 1)
                        withAnimation(.spring(response: 0.24, dampingFraction: 0.76)) {
                            savedSliderOrderRaw = newOrder.joined(separator: ",")
                            dragCurrentTranslationX -= 32.0
                        }
                        HapticFeedback.selection()
                    } else if dragCurrentTranslationX < -threshold && currentIndex > 0 {
                        var newOrder = currentList.map { $0.id }
                        newOrder.swapAt(currentIndex, currentIndex - 1)
                        withAnimation(.spring(response: 0.24, dampingFraction: 0.76)) {
                            savedSliderOrderRaw = newOrder.joined(separator: ",")
                            dragCurrentTranslationX += 32.0
                        }
                        HapticFeedback.selection()
                    }
                }
                .onEnded { _ in
                    guard isCommandPressed || NSEvent.modifierFlags.contains(.command) else { return }
                    withAnimation(.spring(response: 0.24, dampingFraction: 0.76)) {
                        draggedItemId = nil
                        dragCurrentTranslationX = 0
                    }
                    HapticFeedback.selection()
                }
        )
        .onHover { hovering in
            withAnimation(.spring(response: 0.22, dampingFraction: 0.72)) {
                hoveredItemId = hovering ? entry.id : (hoveredItemId == entry.id ? nil : hoveredItemId)
            }
        }
        .help(entry.isInactiveBackground ? "\(entry.title) (Background App) — Click to bring to front, right-click to inspect or ask Genie" : entry.title)
        .popover(
            isPresented: Binding(
                get: { previewEntryId == entry.id && entry.isInactiveBackground },
                set: { if !$0 { previewEntryId = nil } }
            ),
            arrowEdge: .top
        ) {
            if let app = entry.runningApp {
                AppWindowHoverPreviewCard(
                    pid: app.processIdentifier,
                    name: entry.title,
                    icon: entry.nsImage,
                    bundleId: entry.id,
                    runningApp: app,
                    onDismiss: { previewEntryId = nil }
                )
            }
        }
        .contextMenu {
            dockContextMenu(for: entry)
        }
    }

    @ViewBuilder
    private func dockIconContainer(for entry: DockItemEntry, isHovered: Bool, isCurrentTab: Bool) -> some View {
        ZStack {
            if let img = entry.nsImage {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 22, height: 22)
            } else if let sysName = entry.iconName {
                Image(systemName: sysName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 22, height: 22)
            }
        }
        .frame(width: 26, height: 26)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor).opacity(0.96))
        )
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(buttonBackgroundColor(isCurrentTab: isCurrentTab, isHovered: isHovered))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .strokeBorder(buttonStrokeColor(isCurrentTab: isCurrentTab, isHovered: isHovered, isInactive: entry.isInactiveBackground), lineWidth: 0.8)
        )
        .shadow(color: isHovered ? Color.black.opacity(0.55) : Color.clear, radius: 4, y: 2)
    }

    private func buttonBackgroundColor(isCurrentTab: Bool, isHovered: Bool) -> Color {
        if isCurrentTab {
            return Color.white.opacity(0.24)
        } else if isHovered {
            return Color.white.opacity(0.18)
        } else {
            return Color.white.opacity(0.06)
        }
    }

    private func buttonStrokeColor(isCurrentTab: Bool, isHovered: Bool, isInactive: Bool) -> Color {
        if isCurrentTab {
            return Color.cyan.opacity(0.6)
        } else if isHovered {
            return Color.white.opacity(0.35)
        } else if isInactive {
            return Color.cyan.opacity(0.35)
        } else {
            return Color.white.opacity(0.10)
        }
    }

    @ViewBuilder
    private func dockIndicatorDot(for entry: DockItemEntry, isCurrentTab: Bool) -> some View {
        let dotColor: Color = {
            if entry.isInactiveBackground {
                return Color.cyan
            } else if isCurrentTab {
                return Color.white
            } else if entry.isRunning {
                return Color.white.opacity(0.85)
            } else {
                return Color.clear
            }
        }()

        let dotSize: CGFloat = entry.isInactiveBackground ? 3.5 : 3.0

        Circle()
            .fill(dotColor)
            .frame(width: dotSize, height: dotSize)
            .shadow(color: entry.isInactiveBackground ? Color.cyan.opacity(0.8) : Color.clear, radius: 2)
    }

    private func isTabActive(_ entry: DockItemEntry) -> Bool {
        switch windowManager.activeTab.kind {
        case .chat: return entry.id == "builtin_chat"
        case .editor: return entry.id == "builtin_editor"
        case .files: return entry.id == "builtin_files"
        case .terminal: return entry.id == "builtin_terminal"
        case .browser: return entry.id == "builtin_browser"
        case .notes: return entry.id == "builtin_notes"
        case .settings: return entry.id == "builtin_settings"
        case .applications: return entry.id == "builtin_apps"
        case .soundAndEffects, .models, .virtualMachines, .github, .notchAndMenuBar: return false
        case .app(bundleId: let bundleId, name: let name):
            return entry.id == bundleId || entry.title.lowercased() == name.lowercased()
        }
    }

    @ViewBuilder
    private func dockContextMenu(for entry: DockItemEntry) -> some View {
        if entry.isInactiveBackground, let app = entry.runningApp, !app.isTerminated {
            Text("\(entry.title) • Background App")
            Divider()
            Button("Inspect Window & Actions...") {
                previewEntryId = entry.id
            }
            Button("Bring to Front") {
                app.unhide()
                _ = app.activate(options: [.activateAllWindows])
                SmartGridManager.shared.bringToFront(app: app)
            }
            Button("Open in Dialogue Studio Tab") {
                windowManager.show(tab: .app(bundleId: entry.id, name: entry.title))
            }
            Button("Ask Genie about \(entry.title)") {
                windowManager.show(tab: .chat)
                NotificationCenter.default.post(
                    name: NSNotification.Name("NexusFocusGenieSearchBarWithMode"),
                    object: "Help me with \(entry.title): "
                )
            }
            Button("Show All Windows") {
                app.unhide()
                _ = app.activate(options: [.activateAllWindows])
            }
            if app.isHidden {
                Button("Unhide") {
                    app.unhide()
                    _ = app.activate()
                }
            } else {
                Button("Hide") {
                    app.hide()
                }
            }
            Divider()
            Button("Quit \(entry.title)") {
                app.terminate()
            }
        }
    }
}
