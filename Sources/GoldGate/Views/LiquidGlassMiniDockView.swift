import AppKit
import SwiftUI

// MARK: - 📱 Liquid Glass Mini Dock View
/// An integrated frosted liquid-glass mini dock strip embedded directly in the slide-down ceiling dashboard
/// (Zenith / LiquidGlassTopDashboardView) alongside the digital clock and quick chat.
/// Replaces the cramped menu-bar dock with an unconstrained, glitch-free interactive dock surface.
public struct LiquidGlassMiniDockView: View {
    @Binding var isPresented: Bool
    var selectedTab: Binding<Int>?

    @ObservedObject var dockManager = DockAndDesktopManager.shared
    @ObservedObject var trashMonitor = TrashMonitor.shared

    @AppStorage(PrefKey.dockActiveAppsOnly) var dockActiveAppsOnly: Bool = false
    @AppStorage(PrefKey.dockAlwaysShowFinder) var dockAlwaysShowFinder: Bool = true
    @AppStorage(PrefKey.dockAlwaysShowTrash) var dockAlwaysShowTrash: Bool = true
    @AppStorage(PrefKey.dockShowFolderStacks) var dockShowFolderStacks: Bool = true

    @State private var hoveredItemId: String? = nil
    @State private var bouncingItemId: String? = nil

    public init(isPresented: Binding<Bool>, selectedTab: Binding<Int>? = nil) {
        self._isPresented = isPresented
        self.selectedTab = selectedTab
    }

    private var activePid: pid_t {
        dockManager.activePid
    }

    private var displayItems: [DockAppItem] {
        let baseItems = dockManager.dockItems.isEmpty ? DockAndDesktopManager.loadSystemDockApps() : dockManager.dockItems
        let nonFinder = baseItems.filter {
            $0.bundleIdentifier != "com.apple.finder" &&
            $0.id != "com.apple.finder" &&
            $0.name.lowercased() != "finder"
        }
        if dockActiveAppsOnly {
            return nonFinder.filter { $0.isRunning }
        }
        return nonFinder
    }

    public var body: some View {
        VStack(spacing: 6) {
            // Hover Label Floating Pill
            if let hoveredId = hoveredItemId, let label = labelForHoveredItem(hoveredId) {
                Text(label)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.70))
                            .overlay(Capsule().stroke(Color.white.opacity(0.18), lineWidth: 0.5))
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                    .animation(.spring(response: 0.18, dampingFraction: 0.8), value: hoveredItemId)
            } else {
                Text("")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .padding(.vertical, 3)
                    .opacity(0)
            }

            // Mini Dock Capsule Container
            HStack(spacing: 8) {
                // 0. Genie Studio (Chat & Workflows) — Consolidated under the GENIE Blocks
                genieStudioView

                // 1. Finder Icon
                if dockAlwaysShowFinder {
                    finderView
                }

                // Vertical Divider
                dockDivider

                // 2. Running & Pinned Applications Strip
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(displayItems) { item in
                            dockAppItemView(item: item)
                        }
                    }
                    .padding(.horizontal, 2)
                }
                .frame(maxWidth: .infinity)

                // Vertical Divider
                if (dockShowFolderStacks || dockAlwaysShowTrash) && !displayItems.isEmpty {
                    dockDivider
                }

                // 3. Folder Stacks (Downloads & Applications)
                if dockShowFolderStacks {
                    downloadsFolderView
                    applicationsFolderView
                }

                // 4. Trash
                if dockAlwaysShowTrash {
                    trashView
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.25),
                                    Color.white.opacity(0.08),
                                    Color.white.opacity(0.05),
                                    Color.white.opacity(0.18)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.8
                        )
                }
            )
            .shadow(color: Color.black.opacity(0.35), radius: 12, x: 0, y: 4)
        }
        .onAppear {
            dockManager.refreshDockApps()
        }
    }

    // MARK: - 0. Genie Studio View
    private var genieStudioView: some View {
        let isHovered = hoveredItemId == "com.nicholasdudek.genie.studio"
        let isChatActive = selectedTab?.wrappedValue == 0

        return Button(action: {
            HapticFeedback.selection()
            if let selectedTab = selectedTab {
                withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                    selectedTab.wrappedValue = 0
                }
            } else {
                FinderChatWindowManager.shared.show(tab: .chat)
            }
            NotificationCenter.default.post(name: NSNotification.Name("NexusSelectTopDockChat"), object: nil)
        }) {
            VStack(spacing: 2) {
                ZStack {
                    if isHovered {
                        Circle()
                            .fill(Color.cyan.opacity(0.35))
                            .frame(width: 38, height: 38)
                            .blur(radius: 5)
                    }

                    if isChatActive {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(Color.cyan.opacity(0.85), lineWidth: 1.5)
                            .frame(width: 34, height: 34)
                    }

                    if let icon = NSWorkspace.shared.icon(forFile: Bundle.main.bundlePath) as NSImage? {
                        Image(nsImage: icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 30, height: 30)
                            .scaleEffect(isHovered ? 1.15 : 1.0)
                            .shadow(color: Color.cyan.opacity(isHovered ? 0.6 : 0.2), radius: 3, y: 1.5)
                    } else {
                        Image(systemName: "sparkles")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.cyan)
                            .frame(width: 30, height: 30)
                            .scaleEffect(isHovered ? 1.15 : 1.0)
                    }
                }
                .frame(width: 34, height: 34)

                // Glowing Active Dot
                Circle()
                    .fill(Color.cyan)
                    .frame(width: 3.5, height: 3.5)
                    .shadow(color: Color.cyan.opacity(0.9), radius: 2)
            }
            .frame(width: 38, height: 42)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { h in
            withAnimation(.spring(response: 0.20, dampingFraction: 0.75)) {
                hoveredItemId = h ? "com.nicholasdudek.genie.studio" : nil
            }
        }
        .contextMenu {
            Button("Genie Studio Chat") {
                if let selectedTab = selectedTab {
                    withAnimation { selectedTab.wrappedValue = 0 }
                }
                NotificationCenter.default.post(name: NSNotification.Name("NexusSelectTopDockChat"), object: nil)
            }
            Button("New Conversation") {
                LocalModelManager.shared.startNewChat()
                if let selectedTab = selectedTab {
                    withAnimation { selectedTab.wrappedValue = 0 }
                }
            }
            Divider()
            Button("Open Fullscreen Genie Studio (⌘⌥Space)") {
                withAnimation { isPresented = false }
                FinderChatWindowManager.shared.show(tab: .chat)
            }
            Button("Code Editor & Preview") {
                withAnimation { isPresented = false }
                FinderChatWindowManager.shared.show(tab: .editor)
            }
            Button("Terminal Studio") {
                withAnimation { isPresented = false }
                FinderChatWindowManager.shared.show(tab: .terminal)
            }
            Button("Files & Finder") {
                withAnimation { isPresented = false }
                FinderChatWindowManager.shared.show(tab: .files)
            }
        }
    }

    // MARK: - 1. Finder View
    private var finderView: some View {
        let isHovered = hoveredItemId == "com.apple.finder"
        let isFrontmost = NSWorkspace.shared.frontmostApplication?.bundleIdentifier == "com.apple.finder"

        return Button(action: {
            HapticFeedback.selection()
            if let finder = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.finder").first {
                finder.activate(options: [.activateAllWindows])
            } else {
                let finderURL = URL(fileURLWithPath: "/System/Library/CoreServices/Finder.app")
                NSWorkspace.shared.openApplication(at: finderURL, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
            }
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                isPresented = false
            }
        }) {
            VStack(spacing: 2) {
                ZStack {
                    if isHovered {
                        Circle()
                            .fill(Color.cyan.opacity(0.20))
                            .frame(width: 38, height: 38)
                            .blur(radius: 4)
                    }

                    Image(nsImage: NSWorkspace.shared.icon(forFile: "/System/Library/CoreServices/Finder.app"))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 30)
                        .scaleEffect(isHovered ? 1.15 : 1.0)
                        .shadow(color: Color.black.opacity(0.3), radius: 3, y: 1.5)
                }
                .frame(width: 34, height: 34)

                // Running dot
                Circle()
                    .fill(isFrontmost ? Color.cyan : Color.white.opacity(0.85))
                    .frame(width: 3.5, height: 3.5)
            }
            .frame(width: 38, height: 42)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { h in
            withAnimation(.spring(response: 0.20, dampingFraction: 0.75)) {
                hoveredItemId = h ? "com.apple.finder" : nil
            }
        }
        .contextMenu {
            Button("New Finder Window") {
                if let finder = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.finder").first {
                    finder.activate(options: [.activateAllWindows])
                }
                let script = "tell application \"Finder\" to make new Finder window"
                if let appleScript = NSAppleScript(source: script) {
                    var error: NSDictionary?
                    appleScript.executeAndReturnError(&error)
                }
                withAnimation { isPresented = false }
            }
            Button("Go to Desktop") {
                NSWorkspace.shared.open(URL(fileURLWithPath: NSHomeDirectory() + "/Desktop"))
                withAnimation { isPresented = false }
            }
            Button("Go to Downloads") {
                NSWorkspace.shared.open(URL(fileURLWithPath: NSHomeDirectory() + "/Downloads"))
                withAnimation { isPresented = false }
            }
            Button("Go to Applications") {
                NSWorkspace.shared.open(URL(fileURLWithPath: "/Applications"))
                withAnimation { isPresented = false }
            }
        }
    }

    // MARK: - 2. Application Item View
    @ViewBuilder
    private func dockAppItemView(item: DockAppItem) -> some View {
        let isHovered = hoveredItemId == item.id
        let isBouncing = bouncingItemId == item.id
        let isFrontmost = (item.runningApp != nil && (activePid == item.processIdentifier || item.runningApp?.isActive == true))

        Button(action: {
            HapticFeedback.selection()
            withAnimation(.spring(response: 0.28, dampingFraction: 0.45)) {
                bouncingItemId = item.id
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.30) {
                if bouncingItemId == item.id { bouncingItemId = nil }
            }
            MenuBarActionDispatcher.shared.handleAppClick(item)
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                isPresented = false
            }
        }) {
            VStack(spacing: 2) {
                ZStack {
                    // Hover Glow Halo
                    if isHovered {
                        Circle()
                            .fill(Color.cyan.opacity(0.18))
                            .frame(width: 38, height: 38)
                            .blur(radius: 4)
                    }

                    // Active Process Rim
                    if isFrontmost {
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .strokeBorder(Color.cyan.opacity(0.55), lineWidth: 1.2)
                            .frame(width: 34, height: 34)
                    }

                    // App Icon
                    if let icon = item.icon {
                        Image(nsImage: icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 30, height: 30)
                    } else {
                        Image(systemName: "app.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.8))
                            .frame(width: 30, height: 30)
                    }
                }
                .frame(width: 34, height: 34)
                .scaleEffect(isHovered ? 1.15 : (isBouncing ? 1.25 : 1.0))
                .shadow(color: Color.black.opacity(isHovered ? 0.45 : 0.22), radius: isHovered ? 4 : 2, y: 1.5)

                // Running Indicator Dot
                if item.isRunning {
                    Circle()
                        .fill(isFrontmost ? Color.cyan : Color.white.opacity(0.85))
                        .frame(width: 3.5, height: 3.5)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 3.5, height: 3.5)
                }
            }
            .frame(width: 38, height: 42)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { h in
            withAnimation(.spring(response: 0.20, dampingFraction: 0.75)) {
                hoveredItemId = h ? item.id : nil
            }
        }
        .contextMenu {
            dockAppContextMenu(item: item)
        }
    }

    // MARK: - Context Menu
    @ViewBuilder
    private func dockAppContextMenu(item: DockAppItem) -> some View {
        Button("Open \(item.name)") {
            MenuBarActionDispatcher.shared.handleAppClick(item)
            withAnimation { isPresented = false }
        }

        if let app = item.runningApp, !app.isTerminated {
            Button("Bring All to Front") {
                app.unhide()
                _ = app.activate(options: [.activateAllWindows])
                withAnimation { isPresented = false }
            }
            Button("Show All Windows") {
                app.unhide()
                _ = app.activate(options: [.activateAllWindows])
                withAnimation { isPresented = false }
            }
            Divider()
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
            Button("Quit") {
                app.terminate()
            }
            Button("Force Quit") {
                app.forceTerminate()
            }
        }

        Divider()

        if let url = item.bundleURL {
            Button("Show in Finder") {
                NSWorkspace.shared.activateFileViewerSelecting([url])
            }
        }
    }

    // MARK: - 3. Folder Stacks
    private var downloadsFolderView: some View {
        let isHovered = hoveredItemId == "folder.downloads"
        let url = URL(fileURLWithPath: NSHomeDirectory() + "/Downloads")

        return Button(action: {
            HapticFeedback.selection()
            NSWorkspace.shared.open(url)
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                isPresented = false
            }
        }) {
            VStack(spacing: 2) {
                ZStack {
                    if isHovered {
                        Circle()
                            .fill(Color.blue.opacity(0.20))
                            .frame(width: 38, height: 38)
                            .blur(radius: 4)
                    }

                    Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 30)
                        .scaleEffect(isHovered ? 1.15 : 1.0)
                        .shadow(color: Color.black.opacity(0.3), radius: 3, y: 1.5)
                }
                .frame(width: 34, height: 34)

                Circle()
                    .fill(Color.clear)
                    .frame(width: 3.5, height: 3.5)
            }
            .frame(width: 38, height: 42)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { h in
            withAnimation(.spring(response: 0.20, dampingFraction: 0.75)) {
                hoveredItemId = h ? "folder.downloads" : nil
            }
        }
    }

    private var applicationsFolderView: some View {
        let isHovered = hoveredItemId == "folder.applications"
        let url = URL(fileURLWithPath: "/Applications")

        return Button(action: {
            HapticFeedback.selection()
            NSWorkspace.shared.open(url)
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                isPresented = false
            }
        }) {
            VStack(spacing: 2) {
                ZStack {
                    if isHovered {
                        Circle()
                            .fill(Color.purple.opacity(0.20))
                            .frame(width: 38, height: 38)
                            .blur(radius: 4)
                    }

                    Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 30)
                        .scaleEffect(isHovered ? 1.15 : 1.0)
                        .shadow(color: Color.black.opacity(0.3), radius: 3, y: 1.5)
                }
                .frame(width: 34, height: 34)

                Circle()
                    .fill(Color.clear)
                    .frame(width: 3.5, height: 3.5)
            }
            .frame(width: 38, height: 42)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { h in
            withAnimation(.spring(response: 0.20, dampingFraction: 0.75)) {
                hoveredItemId = h ? "folder.applications" : nil
            }
        }
    }

    // MARK: - 4. Trash View
    private var trashView: some View {
        let isHovered = hoveredItemId == "system.trash"
        let trashUrl = URL(fileURLWithPath: NSHomeDirectory() + "/.Trash")
        let trashIcon = NSWorkspace.shared.icon(forFile: trashUrl.path)

        return Button(action: {
            HapticFeedback.selection()
            NSWorkspace.shared.open(trashUrl)
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                isPresented = false
            }
        }) {
            VStack(spacing: 2) {
                ZStack(alignment: .topTrailing) {
                    if isHovered {
                        Circle()
                            .fill(Color.orange.opacity(0.20))
                            .frame(width: 38, height: 38)
                            .blur(radius: 4)
                    }

                    Image(nsImage: trashIcon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 30)
                        .scaleEffect(isHovered ? 1.15 : 1.0)
                        .shadow(color: Color.black.opacity(0.3), radius: 3, y: 1.5)

                    if trashMonitor.trashItemCount > 0 {
                        Text("\(trashMonitor.trashItemCount)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Capsule().fill(Color.red.opacity(0.90)))
                            .offset(x: 4, y: -2)
                    }
                }
                .frame(width: 34, height: 34)

                Circle()
                    .fill(Color.clear)
                    .frame(width: 3.5, height: 3.5)
            }
            .frame(width: 38, height: 42)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { h in
            withAnimation(.spring(response: 0.20, dampingFraction: 0.75)) {
                hoveredItemId = h ? "system.trash" : nil
            }
        }
        .contextMenu {
            Button("Open Trash") {
                NSWorkspace.shared.open(trashUrl)
                withAnimation { isPresented = false }
            }
            if trashMonitor.trashItemCount > 0 {
                Button("Empty Trash") {
                    let script = "tell application \"Finder\" to empty trash"
                    if let appleScript = NSAppleScript(source: script) {
                        var error: NSDictionary?
                        appleScript.executeAndReturnError(&error)
                    }
                }
            }
        }
    }

    // MARK: - Divider
    private var dockDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.18))
            .frame(width: 1, height: 26)
            .padding(.horizontal, 2)
    }

    // MARK: - Tooltip Helper
    private func labelForHoveredItem(_ id: String) -> String? {
        if id == "com.nicholasdudek.genie.studio" { return "Genie Studio (Chat & Intelligence)" }
        if id == "com.apple.finder" { return "Finder" }
        if id == "folder.downloads" { return "Downloads" }
        if id == "folder.applications" { return "Applications" }
        if id == "system.trash" {
            let count = trashMonitor.trashItemCount
            return count > 0 ? "Trash (\(count) items)" : "Trash"
        }
        if let match = displayItems.first(where: { $0.id == id }) {
            return match.name
        }
        return nil
    }
}
