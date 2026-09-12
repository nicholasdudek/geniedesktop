import AppKit
import SwiftUI

/// Matched to the real menu bar so the mini dock's items read as the same class of
/// control as the system's own: CustomMenuBarManager draws each status item in a
/// 22x22 box with 3 pt between them. The dock had drifted to a 30 pt icon in a
/// 38x42 tile — larger than every menu item beside it, and larger than the 22 pt
/// bar DEVELOPER_NOTES 2.8 describes as the world's smallest dock. The 4 pt gutter
/// between icon and tile edge is preserved, so only the scale changes.
private enum DockMetrics {
    static let icon: CGFloat = 28
    static let iconWell: CGFloat = 34
    static let hoverBloom: CGFloat = 40
    static let tile = CGSize(width: 40, height: 44)
    static let runningDot: CGFloat = 4
    static let itemSpacing: CGFloat = 11
}

// MARK: - 📱 Liquid Glass Mini Dock View
/// An integrated frosted liquid-glass mini dock strip embedded directly in the slide-down ceiling dashboard
/// (Zenith / LiquidGlassTopDashboardView) alongside the digital clock and quick chat.
/// Replaces the cramped menu-bar dock with an unconstrained, glitch-free interactive dock surface.
public struct LiquidGlassMiniDockView: View {
    @Binding var isPresented: Bool
    var selectedTab: Binding<Int>?

    @ObservedObject var dockManager = DockAndDesktopManager.shared
    @ObservedObject var trashMonitor = TrashMonitor.shared
    @ObservedObject var localModels = LocalModelManager.shared
    @ObservedObject var windowManager = DesktopWindowManager.shared
    @ObservedObject var batteryMonitor = BatteryMonitor.shared

    @AppStorage(PrefKey.dockActiveAppsOnly) var dockActiveAppsOnly: Bool = false
    @AppStorage(PrefKey.dockAlwaysShowFinder) var dockAlwaysShowFinder: Bool = true
    @AppStorage(PrefKey.dockAlwaysShowTrash) var dockAlwaysShowTrash: Bool = true
    @AppStorage(PrefKey.dockShowFolderStacks) var dockShowFolderStacks: Bool = true
    @AppStorage(PrefKey.batteryEnabled) var batteryEnabled: Bool = true
    @AppStorage(PrefKey.showChargingBolt) var showChargingBolt: Bool = true

    @State private var hoveredItemId: String? = nil
    @State private var bouncingItemId: String? = nil
    @State private var dockChatInput: String = ""
    @State private var isBatteryHovered: Bool = false
    @FocusState private var isDockChatFocused: Bool

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
            HStack(spacing: 12) {
                // 0. Genie Studio (Chat & Workflows) — Consolidated under the GENIE Blocks
                genieStudioView

                // 0b. Invisible / Glass Dock Chat Bar with live box updates
                dockChatBarView

                // 1. Finder Icon
                if dockAlwaysShowFinder {
                    finderView
                }

                // Vertical Divider
                dockDivider

                // 2. Running & Pinned Applications Strip
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DockMetrics.itemSpacing) {
                        ForEach(displayItems) { item in
                            dockAppItemView(item: item)
                        }
                    }
                    .padding(.horizontal, 18)
                }
                .frame(height: DockMetrics.tile.height + 6)
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

                // 5. Battery Status Indicator (Replaced screens in mini dock with battery)
                if batteryEnabled {
                    dockDivider
                    batteryPillView
                }
            }
            .padding(.horizontal, 22)
            .padding(.vertical, 10)
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
                            .frame(width: DockMetrics.hoverBloom, height: DockMetrics.hoverBloom)
                            .blur(radius: 5)
                    }

                    if isChatActive {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(Color.cyan.opacity(0.85), lineWidth: 1.5)
                            .frame(width: DockMetrics.iconWell, height: DockMetrics.iconWell)
                    }

                    GenieMysticalIconView(
                        glyphImage: StatusIconRenderer.generateGlyphImage(glyph: "Genie Person 🧞‍♂️", size: 24, phase: 0),
                        isHovered: isHovered,
                        size: DockMetrics.icon
                    )
                }
                .frame(width: DockMetrics.iconWell, height: DockMetrics.iconWell)

                // Glowing Active Dot
                Circle()
                    .fill(Color.cyan)
                    .frame(width: DockMetrics.runningDot, height: DockMetrics.runningDot)
                    .shadow(color: Color.cyan.opacity(0.9), radius: 2)
            }
            .frame(width: DockMetrics.tile.width, height: DockMetrics.tile.height)
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

    // MARK: - 0b. Dock Chat Bar & Live Updates
    private var dockChatBarView: some View {
        HStack(spacing: 6) {
            // Invisible / subtle chat prompt box
            HStack(spacing: 5) {
                Image(systemName: "sparkle")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.cyan)

                TextField("Chat to dock...", text: $dockChatInput)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
                    .focused($isDockChatFocused)
                    .frame(width: isDockChatFocused || !dockChatInput.isEmpty ? 130 : 75)
                    .animation(.spring(response: 0.25, dampingFraction: 0.82), value: isDockChatFocused)
                    .onSubmit {
                        submitDockChat()
                    }

                if !dockChatInput.isEmpty {
                    Button(action: submitDockChat) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.cyan)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 3.5)
            .background(
                Capsule()
                    .fill(Color.white.opacity(isDockChatFocused ? 0.12 : 0.04))
            )
            .overlay(
                Capsule()
                    .strokeBorder(Color.cyan.opacity(isDockChatFocused ? 0.50 : 0.18), lineWidth: 0.7)
            )

            // Live Update Box in Dock (Shows latest response or generation & pulls up full chat)
            if localModels.isGenerating || !localModels.currentResponse.isEmpty || (localModels.chatHistory.last?.role != "user" && localModels.chatHistory.last != nil) {
                Button(action: pullUpFullChat) {
                    HStack(spacing: 4) {
                        if localModels.isGenerating {
                            ProgressView()
                                .scaleEffect(0.45)
                                .frame(width: 10, height: 10)
                            Text(localModels.currentResponse.isEmpty ? "Thinking..." : localModels.currentResponse)
                                .lineLimit(1)
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundColor(.cyan)
                                .frame(maxWidth: 130, alignment: .leading)
                        } else if let last = localModels.chatHistory.last, last.role != "user" {
                            Image(systemName: "bubble.left.fill")
                                .font(.system(size: 8.5))
                                .foregroundColor(.cyan.opacity(0.85))
                            Text(last.content)
                                .lineLimit(1)
                                .font(.system(size: 10, weight: .regular, design: .rounded))
                                .foregroundColor(.white.opacity(0.90))
                                .frame(maxWidth: 130, alignment: .leading)
                        }

                        Image(systemName: "arrow.up.left.and.arrow.down.right")
                            .font(.system(size: 7.5, weight: .bold))
                            .foregroundColor(.cyan)
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3.5)
                    .background(
                        Capsule()
                            .fill(Color.cyan.opacity(0.14))
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.cyan.opacity(0.35), lineWidth: 0.6)
                    )
                }
                .buttonStyle(.plain)
                .help("Click to pull up full chat")
                .transition(.scale.combined(with: .opacity))
            }
        }
    }

    private func submitDockChat() {
        let trimmed = dockChatInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        dockChatInput = ""
        HapticFeedback.success()
        localModels.generate(prompt: trimmed)
    }

    private func pullUpFullChat() {
        HapticFeedback.selection()
        if let selectedTab = selectedTab {
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                selectedTab.wrappedValue = 0
            }
        }
        NotificationCenter.default.post(name: NSNotification.Name("GeniePullUpFullChat"), object: nil)
    }

    // MARK: - 1. Finder View
    private var finderView: some View {
        let isHovered = hoveredItemId == "com.apple.finder"
        let isFrontmost = NSWorkspace.shared.frontmostApplication?.bundleIdentifier == "com.apple.finder"

        return Button(action: {
            HapticFeedback.selection()
            if let finder = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.finder").first {
                finder.unhide()
                if #available(macOS 14.0, *) {
                    _ = finder.activate(options: [.activateAllWindows])
                    NSApp.yieldActivation(toApplicationWithBundleIdentifier: "com.apple.finder")
                } else {
                    _ = finder.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
                }
                #if !GENIE_MAS
                let script = "tell application \"Finder\" to activate"
                NSAppleScript(source: script)?.executeAndReturnError(nil)
                #endif
            } else {
                let finderURL = URL(fileURLWithPath: "/System/Library/CoreServices/Finder.app")
                let config = NSWorkspace.OpenConfiguration()
                config.activates = true
                NSWorkspace.shared.openApplication(at: finderURL, configuration: config, completionHandler: nil)
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
                            .frame(width: DockMetrics.hoverBloom, height: DockMetrics.hoverBloom)
                            .blur(radius: 4)
                    }

                    Image(nsImage: NSWorkspace.shared.icon(forFile: "/System/Library/CoreServices/Finder.app"))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: DockMetrics.icon, height: DockMetrics.icon)
                        .scaleEffect(isHovered ? 1.15 : 1.0)
                        .shadow(color: Color.black.opacity(0.3), radius: 3, y: 1.5)
                }
                .frame(width: DockMetrics.iconWell, height: DockMetrics.iconWell)

                // Running dot
                Circle()
                    .fill(isFrontmost ? Color.cyan : Color.white.opacity(0.85))
                    .frame(width: DockMetrics.runningDot, height: DockMetrics.runningDot)
            }
            .frame(width: DockMetrics.tile.width, height: DockMetrics.tile.height)
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
                            .frame(width: DockMetrics.hoverBloom, height: DockMetrics.hoverBloom)
                            .blur(radius: 4)
                    }

                    // Active Process Rim
                    if isFrontmost {
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .strokeBorder(Color.cyan.opacity(0.55), lineWidth: 1.2)
                            .frame(width: DockMetrics.iconWell, height: DockMetrics.iconWell)
                    }

                    // App Icon
                    if let icon = item.icon {
                        Image(nsImage: icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: DockMetrics.icon, height: DockMetrics.icon)
                    } else {
                        Image(systemName: "app.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.8))
                            .frame(width: DockMetrics.icon, height: DockMetrics.icon)
                    }
                }
                .frame(width: DockMetrics.iconWell, height: DockMetrics.iconWell)
                .scaleEffect(isHovered ? 1.15 : (isBouncing ? 1.25 : 1.0))
                .shadow(color: Color.black.opacity(isHovered ? 0.45 : 0.22), radius: isHovered ? 4 : 2, y: 1.5)

                // Running Indicator Dot
                if item.isRunning {
                    Circle()
                        .fill(isFrontmost ? Color.cyan : Color.white.opacity(0.85))
                        .frame(width: DockMetrics.runningDot, height: DockMetrics.runningDot)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: DockMetrics.runningDot, height: DockMetrics.runningDot)
                }
            }
            .frame(width: DockMetrics.tile.width, height: DockMetrics.tile.height)
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
            if let finder = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.finder").first {
                if #available(macOS 14.0, *) {
                    _ = finder.activate(options: [.activateAllWindows])
                    NSApp.yieldActivation(toApplicationWithBundleIdentifier: "com.apple.finder")
                } else {
                    _ = finder.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
                }
            }
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                isPresented = false
            }
        }) {
            VStack(spacing: 2) {
                ZStack {
                    if isHovered {
                        Circle()
                            .fill(Color.blue.opacity(0.20))
                            .frame(width: DockMetrics.hoverBloom, height: DockMetrics.hoverBloom)
                            .blur(radius: 4)
                    }

                    Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: DockMetrics.icon, height: DockMetrics.icon)
                        .scaleEffect(isHovered ? 1.15 : 1.0)
                        .shadow(color: Color.black.opacity(0.3), radius: 3, y: 1.5)
                }
                .frame(width: DockMetrics.iconWell, height: DockMetrics.iconWell)

                Circle()
                    .fill(Color.clear)
                    .frame(width: DockMetrics.runningDot, height: DockMetrics.runningDot)
            }
            .frame(width: DockMetrics.tile.width, height: DockMetrics.tile.height)
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
            if let finder = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.finder").first {
                if #available(macOS 14.0, *) {
                    _ = finder.activate(options: [.activateAllWindows])
                    NSApp.yieldActivation(toApplicationWithBundleIdentifier: "com.apple.finder")
                } else {
                    _ = finder.activate(options: [.activateAllWindows, .activateIgnoringOtherApps])
                }
            }
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                isPresented = false
            }
        }) {
            VStack(spacing: 2) {
                ZStack {
                    if isHovered {
                        Circle()
                            .fill(Color.purple.opacity(0.20))
                            .frame(width: DockMetrics.hoverBloom, height: DockMetrics.hoverBloom)
                            .blur(radius: 4)
                    }

                    Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: DockMetrics.icon, height: DockMetrics.icon)
                        .scaleEffect(isHovered ? 1.15 : 1.0)
                        .shadow(color: Color.black.opacity(0.3), radius: 3, y: 1.5)
                }
                .frame(width: DockMetrics.iconWell, height: DockMetrics.iconWell)

                Circle()
                    .fill(Color.clear)
                    .frame(width: DockMetrics.runningDot, height: DockMetrics.runningDot)
            }
            .frame(width: DockMetrics.tile.width, height: DockMetrics.tile.height)
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
            MenuBarActionDispatcher.shared.openNativeTrash()
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                isPresented = false
            }
        }) {
            VStack(spacing: 2) {
                ZStack(alignment: .topTrailing) {
                    if isHovered {
                        Circle()
                            .fill(Color.orange.opacity(0.20))
                            .frame(width: DockMetrics.hoverBloom, height: DockMetrics.hoverBloom)
                            .blur(radius: 4)
                    }

                    Image(nsImage: trashIcon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: DockMetrics.icon, height: DockMetrics.icon)
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
                .frame(width: DockMetrics.iconWell, height: DockMetrics.iconWell)

                Circle()
                    .fill(Color.clear)
                    .frame(width: DockMetrics.runningDot, height: DockMetrics.runningDot)
            }
            .frame(width: DockMetrics.tile.width, height: DockMetrics.tile.height)
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
                MenuBarActionDispatcher.shared.openNativeTrash()
                withAnimation { isPresented = false }
            }
            if trashMonitor.trashItemCount > 0 {
                Button("Empty Trash") {
                    MenuBarActionDispatcher.shared.emptyNativeTrash()
                }
            }
        }
    }

    // MARK: - 5. Settings Button (Page 2 of Dock)
    private var settingsButtonView: some View {
        let isHovered = hoveredItemId == "genie.dock.settings"
        let isSettingsActive = windowManager.topDockPage == 1

        return Button(action: {
            HapticFeedback.selection()
            withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                windowManager.topDockPage = (windowManager.topDockPage == 1 ? 0 : 1)
            }
        }) {
            VStack(spacing: 2) {
                ZStack {
                    if isHovered {
                        Circle()
                            .fill(Color.purple.opacity(0.35))
                            .frame(width: DockMetrics.hoverBloom, height: DockMetrics.hoverBloom)
                            .blur(radius: 4)
                    }

                    if isSettingsActive {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .strokeBorder(Color.purple.opacity(0.85), lineWidth: 1.5)
                            .frame(width: DockMetrics.iconWell, height: DockMetrics.iconWell)
                    }

                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(isSettingsActive ? .cyan : (isHovered ? .white : .white.opacity(0.85)))
                        .frame(width: DockMetrics.icon, height: DockMetrics.icon)
                        .scaleEffect(isHovered ? 1.15 : 1.0)
                        .shadow(color: Color.purple.opacity(isHovered ? 0.6 : 0.2), radius: 3, y: 1.5)
                }
                .frame(width: DockMetrics.iconWell, height: DockMetrics.iconWell)

                Circle()
                    .fill(isSettingsActive ? Color.cyan : Color.clear)
                    .frame(width: DockMetrics.runningDot, height: DockMetrics.runningDot)
            }
            .frame(width: DockMetrics.tile.width, height: DockMetrics.tile.height)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { h in
            withAnimation(.spring(response: 0.20, dampingFraction: 0.75)) {
                hoveredItemId = h ? "genie.dock.settings" : nil
            }
        }
        .help("Settings (Page 2 of Dock)")
        .contextMenu {
            Button("Genie Settings (Page 2)") {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                    windowManager.topDockPage = 1
                }
            }
            Divider()
            Button("Return to Dock (Page 1)") {
                withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                    windowManager.topDockPage = 0
                }
            }
        }
    }

    // MARK: - 5. Battery Status Pill
    private var batteryPillView: some View {
        Button(action: {
            HapticFeedback.selection()
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.battery") {
                NSWorkspace.shared.open(url)
            }
        }) {
            HStack(spacing: 5) {
                // Battery Gauge Bar Icon
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                        .stroke(Color.white.opacity(0.40), lineWidth: 1.2)
                        .frame(width: 22, height: 12)

                    let pct = CGFloat(batteryMonitor.batteryPct ?? 100) / 100.0
                    let fillW = max(2.0, min(18.0, 18.0 * pct))
                    let fillColor: Color = batteryMonitor.isCharging ? .green : (pct <= 0.20 ? .red : (pct <= 0.40 ? .yellow : .green))

                    RoundedRectangle(cornerRadius: 2.0, style: .continuous)
                        .fill(fillColor)
                        .frame(width: fillW, height: 8)
                        .padding(.leading, 2)
                }
                .overlay(
                    // Battery terminal nub
                    RoundedRectangle(cornerRadius: 1.0, style: .continuous)
                        .fill(Color.white.opacity(0.40))
                        .frame(width: 1.8, height: 4.5)
                        .offset(x: 12)
                )

                if showChargingBolt && batteryMonitor.isCharging {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 8.5, weight: .bold))
                        .foregroundColor(.yellow)
                }

                Text("\(batteryMonitor.batteryPct ?? 100)%")
                    .font(.system(size: 10.5, weight: .semibold, design: .rounded).monospacedDigit())
                    .foregroundColor(.white.opacity(0.90))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4.5)
            .background(
                Capsule()
                    .fill(isBatteryHovered ? Color.white.opacity(0.16) : Color.white.opacity(0.08))
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(isBatteryHovered ? 0.30 : 0.15), lineWidth: 0.7)
                    )
            )
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .onHover { h in
            isBatteryHovered = h
            withAnimation(.spring(response: 0.20, dampingFraction: 0.75)) {
                hoveredItemId = h ? "genie.dock.battery" : nil
            }
        }
        .help("Battery: \(batteryMonitor.batteryPct ?? 100)% \(batteryMonitor.isCharging ? "(Charging ⚡)" : "")")
        .contextMenu {
            let bm = BatteryMonitor.shared
            let pct = bm.batteryPct ?? 100
            let pwrText = bm.isCharging ? "\(pct)% — Charging on Power Adapter ⚡" : (bm.isPluggedIn ? "\(pct)% — Power Adapter Connected 🔌" : "\(pct)% — On Battery Power 🔋")
            Text(pwrText)

            Button("macOS Battery Settings...") {
                if let url = URL(string: "x-apple.systempreferences:com.apple.preference.battery") {
                    NSWorkspace.shared.open(url)
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
        if id == "genie.dock.battery" {
            let bm = BatteryMonitor.shared
            return "Battery: \(bm.batteryPct ?? 100)% \(bm.isCharging ? "(Charging ⚡)" : "")"
        }
        if id == "genie.dock.settings" { return "Settings (Page 2 of Dock)" }
        if let match = displayItems.first(where: { $0.id == id }) {
            return match.name
        }
        return nil
    }
}
