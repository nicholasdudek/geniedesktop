import AppKit
import Foundation
import SwiftUI

// MARK: - Real macOS Mini Dock View (100% Mirror of Real macOS Dock)
// Reads directly from ~/Library/Preferences/com.apple.dock.plist and NSWorkspace running applications.
// Displays every single pinned, recent, and running app with authentic icons, glowing running LEDs,
// pinned folder stacks (Downloads, Documents, Applications), and authentic live Trash Can with magnification.

public struct RealMacOSMiniDockView: View {
    @ObservedObject var dockManager: DockAndDesktopManager = .shared
    @ObservedObject var trashMonitor: TrashMonitor = .shared

    @AppStorage(PrefKey.dockAlwaysShowTrash) var dockAlwaysShowTrash: Bool = true
    @AppStorage(PrefKey.dockAlwaysShowFinder) var dockAlwaysShowFinder: Bool = true
    @AppStorage(PrefKey.dockAlwaysShowSettings) var dockAlwaysShowSettings: Bool = true
    @AppStorage(PrefKey.dockAlwaysShowGenie) var dockAlwaysShowGenie: Bool = true
    @AppStorage(PrefKey.dockShowFolderStacks) var dockShowFolderStacks: Bool = true
    @AppStorage(PrefKey.dockActiveAppsOnly) var dockActiveAppsOnly: Bool = false
    @AppStorage(PrefKey.miniDockBackgroundStyle) var miniDockBackgroundStyle: String = "Clear (Transparent)"
    @AppStorage(PrefKey.smokeEffectsEnabled) var smokeEffectsEnabled: Bool = true
    @AppStorage(PrefKey.smokeStyle) var smokeStyle: String = "Mystical Cyan 🧞‍♂️"
    @AppStorage(PrefKey.appIconTintColor) var appIconTintColor: String = "Emerald"
    @AppStorage(PrefKey.iconSnuggie) var iconSnuggie: String = "None"
    @AppStorage(PrefKey.dockAnimationStyle) var dockAnimationStyleRaw: String = "Classic Magnify 🔍"
    @AppStorage(PrefKey.dockAnimationIntensity) var dockAnimationIntensity: Double = 0.7
    @AppStorage(PrefKey.danceToMusicEnabled) var danceToMusicEnabled: Bool = true
    @ObservedObject var musicMonitor: MusicPlaybackMonitor = .shared

    @State private var hoveredItemId: String? = nil
    @State private var bouncingItemId: String? = nil
    @State private var smokingItemId: String? = nil

    public var isDownwardMenuBarDock: Bool = false
    public var onAppSelected: ((DockAppItem) -> Void)? = nil

    public init(
        isDownwardMenuBarDock: Bool = false,
        onAppSelected: ((DockAppItem) -> Void)? = nil
    ) {
        self.isDownwardMenuBarDock = isDownwardMenuBarDock
        self.onAppSelected = onAppSelected
    }

    private var displayedDockItems: [DockAppItem] {
        dockActiveAppsOnly ? dockManager.dockItems.filter { $0.isRunning } : dockManager.dockItems
    }

    private var trashIcon: NSImage {
        let isFull = trashMonitor.isTrashFull
        let icnsPath = isFull
            ? "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/FullTrashIcon.icns"
            : "/System/Library/CoreServices/CoreTypes.bundle/Contents/Resources/TrashIcon.icns"
        if let img = NSImage(contentsOfFile: icnsPath) {
            img.size = NSSize(width: 36, height: 36)
            return img
        }
        let conf = NSImage.SymbolConfiguration(pointSize: 22, weight: .regular)
        return NSImage(systemSymbolName: isFull ? "trash.fill" : "trash", accessibilityDescription: "Trash")?.withSymbolConfiguration(conf) ?? NSImage()
    }

    private var genieAppIcon: NSImage? {
        let devIconURL = URL(fileURLWithPath: "/Users/nicholasdudek/Developer/GoldGate/Sources/GoldGate/Assets.xcassets/AppIcon.appiconset/icon_512x512.png")
        if FileManager.default.fileExists(atPath: devIconURL.path), let img = NSImage(contentsOf: devIconURL) {
            img.size = NSSize(width: 40, height: 40)
            return img
        }
        if let appIcon = NSApp.applicationIconImage {
            appIcon.size = NSSize(width: 40, height: 40)
            return appIcon
        }
        return NSWorkspace.shared.icon(forFile: Bundle.main.bundlePath)
    }

    @ObservedObject private var batteryMonitor: BatteryMonitor = .shared

    private var dockAnimationStyle: DockAnimationStyle {
        DockAnimationStyle(preferenceValue: dockAnimationStyleRaw)
    }

    /// The timeline only runs while something actually moves, so an idle dock costs nothing.
    private var isDockTimelineActive: Bool {
        let style = dockAnimationStyle
        if style.isContinuous { return true }
        if style.animatesWhileHovered && hoveredItemId != nil { return true }
        return danceToMusicEnabled && style != .none && musicMonitor.isMusicPlaying
    }

    private func dockOrderIndex(of itemId: String) -> Int? {
        displayedDockItems.firstIndex(where: { $0.id == itemId })
    }

    private func iconTransform(for item: DockAppItem, time: TimeInterval) -> DockIconTransform {
        guard let index = dockOrderIndex(of: item.id) else { return .identity }
        return DockAnimationEngine.transform(
            style: dockAnimationStyle,
            index: index,
            hoveredIndex: hoveredItemId.flatMap { dockOrderIndex(of: $0) },
            time: time,
            intensity: dockAnimationIntensity,
            isMusicPlaying: musicMonitor.isMusicPlaying,
            danceToMusic: danceToMusicEnabled,
            anchorDown: isDownwardMenuBarDock
        )
    }

    public var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 60.0, paused: !isDockTimelineActive)) { timeline in
            dockContent(time: timeline.date.timeIntervalSinceReferenceDate)
        }
    }

    private func dockContent(time: TimeInterval) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                // Real macOS Dock Applications in exact 100% bottom dock order
                ForEach(displayedDockItems) { item in
                    dockIconItemView(for: item, transform: iconTransform(for: item, time: time))
                }

                // 2. Vertical Divider before Folder Stacks & Trash
                if (dockShowFolderStacks && !dockManager.dockFolders.isEmpty) || dockAlwaysShowTrash {
                    Rectangle()
                        .fill(Color.white.opacity(0.20))
                        .frame(width: 1, height: 30)
                        .padding(.horizontal, 4)
                }

                // 3. Pinned Folder Stacks (Downloads, Documents, Applications)
                if dockShowFolderStacks {
                    ForEach(dockManager.dockFolders) { folder in
                        dockFolderItemView(for: folder)
                    }
                }

                // 4. Native macOS Live Trash Slot
                if dockAlwaysShowTrash {
                    trashDockItemView
                }

                // 5. Live Battery Pill
                batteryPillView
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
        }
        .background(dockBackground)
        .onAppear {
            dockManager.setup()
            dockManager.refreshDockApps()
            trashMonitor.checkTrashNow()
            batteryMonitor.refresh()
        }
    }

    // MARK: - Battery Pill View
    @ViewBuilder
    private var batteryPillView: some View {
        if let pct = batteryMonitor.batteryPct {
            let isLow = pct <= 20 && !batteryMonitor.isCharging
            let fillColor: Color = batteryMonitor.isCharging ? .green : (isLow ? .red : .white)

            VStack(spacing: 3) {
                ZStack {
                    // Battery body
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.55), lineWidth: 1.2)
                        .frame(width: 26, height: 14)

                    // Battery fill
                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                            .fill(fillColor.opacity(0.88))
                            .frame(width: max(2, geo.size.width * CGFloat(pct) / 100.0), height: geo.size.height)
                    }
                    .padding(2.5)
                    .frame(width: 26, height: 14)

                    // Bolt or percentage
                    if batteryMonitor.isCharging {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundColor(.white)
                    }

                    // Nub on right
                    HStack(spacing: 0) {
                        Spacer()
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.55))
                            .frame(width: 3, height: 6)
                            .offset(x: 3)
                    }
                    .frame(width: 26, height: 14)
                }
                .frame(width: 30, height: 14)

                // Percentage label
                Text("\(pct)%")
                    .font(.system(size: 7.5, weight: .semibold, design: .rounded))
                    .foregroundColor(isLow ? .red : .white.opacity(0.85))
                    .animation(.easeInOut(duration: 0.3), value: pct)
            }
            .padding(.leading, 4)
            .help(batteryMonitor.isCharging ? "Battery \(pct)% — Charging ⚡" : (isLow ? "Battery \(pct)% — Low 🔴" : "Battery \(pct)%"))
        }
    }



    // MARK: - Dynamic Dock Background
    @ViewBuilder
    private var dockBackground: some View {
        ZStack {
            VisualEffectBlur(material: .popover, blendingMode: .behindWindow, state: .active)
            LinearGradient(
                colors: [
                    Color.white.opacity(0.18),
                    Color.white.opacity(0.06),
                    Color.black.opacity(0.35)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: isDownwardMenuBarDock ? 0 : 18,
                bottomLeadingRadius: 18,
                bottomTrailingRadius: 18,
                topTrailingRadius: isDownwardMenuBarDock ? 0 : 18,
                style: .continuous
            )
        )
        .overlay(
            UnevenRoundedRectangle(
                topLeadingRadius: isDownwardMenuBarDock ? 0 : 18,
                bottomLeadingRadius: 18,
                bottomTrailingRadius: 18,
                topTrailingRadius: isDownwardMenuBarDock ? 0 : 18,
                style: .continuous
            )
            .strokeBorder(
                LinearGradient(
                    colors: [Color.white.opacity(0.40), Color.white.opacity(0.10)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 0.8
            )
        )
        .shadow(color: Color.black.opacity(0.45), radius: 16, y: 6)
    }

    // MARK: - Genie Anchor Item
    @ViewBuilder
    private var genieDockItemView: some View {
        let isHovered = hoveredItemId == "com.nicholasdudek.genie"
        Button(action: {
            HapticFeedback.selection()
            NotificationCenter.default.post(name: NSNotification.Name("NexusFocusGenieSearchBarWithMode"), object: "chat")
        }) {
            VStack(spacing: 3) {
                ZStack {
                    if let icon = genieAppIcon {
                        Image(nsImage: icon)
                            .resizable()
                            .interpolation(.high)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: isHovered ? 48 : 40, height: isHovered ? 48 : 40)
                            .shadow(color: isHovered ? Color.cyan.opacity(0.7) : Color.black.opacity(0.4), radius: isHovered ? 8 : 4)
                    } else {
                        Text("🪔")
                            .font(.system(size: isHovered ? 30 : 26))
                            .frame(width: isHovered ? 48 : 40, height: isHovered ? 48 : 40)
                            .background(Circle().fill(Color.white.opacity(isHovered ? 0.22 : 0.12)))
                            .shadow(color: isHovered ? Color.cyan.opacity(0.7) : Color.clear, radius: 8)
                    }
                }
                .animation(.spring(response: 0.22, dampingFraction: 0.75), value: isHovered)

                Circle()
                    .fill(Color.cyan)
                    .frame(width: 4, height: 4)
                    .shadow(color: Color.cyan.opacity(0.9), radius: 3)
            }
            .frame(width: 52, height: 54)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("Genie Dialogue Studio & Search (⌘⌥Space)")
        .onHover { h in
            withAnimation(.spring(response: 0.22, dampingFraction: 0.75)) {
                hoveredItemId = h ? "com.nicholasdudek.genie" : nil
            }
        }
        .contextMenu {
            Button("Open Dialogue Studio (⌘⌥Space)") {
                NotificationCenter.default.post(name: NSNotification.Name("NexusFocusGenieSearchBarWithMode"), object: "chat")
            }
            Button("Launch Precision Console (Terminal)") {
                NotificationCenter.default.post(name: NSNotification.Name("NexusFocusGenieSearchBarWithMode"), object: "terminal")
            }
            Button("Inscribe Memorandum (Notes)") {
                NotificationCenter.default.post(name: NSNotification.Name("NexusFocusGenieSearchBarWithMode"), object: "file")
            }
            Divider()
            Button("Genie Settings...") {
                AppDelegate.shared?.showMenuBarSettingsDropdown(targetTab: .system)
            }
        }
    }

    // MARK: - Individual Dock App Icon Item
    @ViewBuilder
    private func dockIconItemView(for item: DockAppItem, transform: DockIconTransform = .identity) -> some View {
        let isHovered = hoveredItemId == item.id
        let isRunning = item.isRunning
        let isBouncing = bouncingItemId == item.id
        let isSmoking = smokingItemId == item.id

        Button(action: {
            HapticFeedback.selection()
            withAnimation(.spring(response: 0.28, dampingFraction: 0.45)) {
                bouncingItemId = item.id
            }
            if smokeEffectsEnabled {
                smokingItemId = item.id
                GenieSmokeEngine.shared.triggerBurst(
                    origin: .dock,
                    bounds: CGSize(width: 52, height: 54),
                    style: smokeStyle,
                    count: 16
                )
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                if bouncingItemId == item.id { bouncingItemId = nil }
                if smokingItemId == item.id { smokingItemId = nil }
            }
            if let customAction = onAppSelected {
                customAction(item)
            } else {
                MenuBarActionDispatcher.shared.handleAppClick(item)
            }
        }) {
            VStack(spacing: 3) {
                // App Icon Image
                ZStack {
                    let resolvedIcon = item.icon ?? ((item.bundleIdentifier == "com.nicholasdudek.genie" || item.id == "com.nicholasdudek.genie" || item.name.lowercased() == "genie") ? genieAppIcon : nil)
                    if let icon = resolvedIcon {
                        let rawIconView = Image(nsImage: icon)
                            .resizable()
                            .interpolation(.high)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: isHovered ? 48 : 40, height: isHovered ? 48 : 40)
                            .shadow(color: isHovered ? Color.cyan.opacity(0.4) : Color.black.opacity(0.35), radius: isHovered ? 8 : 4)

                        if iconSnuggie == "Rounded Square" {
                            rawIconView.clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        } else if iconSnuggie == "Circle" {
                            rawIconView.clipShape(Circle())
                        } else if iconSnuggie == "Capsule" {
                            rawIconView.clipShape(Capsule())
                        } else {
                            rawIconView
                        }
                    } else {
                        Image(systemName: "app.fill")
                            .font(.system(size: isHovered ? 34 : 28))
                            .foregroundColor(.white.opacity(0.85))
                            .frame(width: isHovered ? 48 : 40, height: isHovered ? 48 : 40)
                    }

                    if smokeEffectsEnabled && isSmoking {
                        let (prim, _, _) = GenieSmokeEngine.colors(for: smokeStyle)
                        MiniDockSmokePuffView(color: prim)
                    }
                }
                .rotationEffect(.degrees(transform.rotation))
                .offset(x: transform.offset.width, y: transform.offset.height)
                .scaleEffect(isBouncing ? 1.25 : transform.scale, anchor: isDownwardMenuBarDock ? .top : .center)
                .animation(.spring(response: 0.22, dampingFraction: 0.75), value: isHovered)

                // Glowing Running Indicator Dot (Only shown for running apps)
                Circle()
                    .fill(isRunning ? Color.white : Color.clear)
                    .frame(width: 4.5, height: 4.5)
                    .shadow(color: isRunning ? Color.white.opacity(0.9) : Color.clear, radius: 3)
            }
            .frame(width: 52, height: 54)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(isRunning ? "\(item.name) (Running) — Click to bring to front" : "\(item.name) — Click to launch")
        .onHover { h in
            withAnimation(.spring(response: 0.22, dampingFraction: 0.75)) {
                hoveredItemId = h ? item.id : nil
            }
        }
        .contextMenu {
            if let app = item.runningApp, !app.isTerminated {
                Button("Bring All to Front") {
                    app.unhide()
                    _ = app.activate(options: [.activateAllWindows])
                    SmartGridManager.shared.bringToFront(app: app)
                }
                Button("Show All Windows") {
                    app.unhide()
                    _ = app.activate(options: [.activateAllWindows])
                    SmartGridManager.shared.bringToFront(app: app)
                }
                if TinyFolderAppPocketEngine.shared.pocketedApps.contains(where: { $0.processId == app.processIdentifier }) {
                    Button("🪟 Expand to Full Size") {
                        if let match = TinyFolderAppPocketEngine.shared.pocketedApps.first(where: { $0.processId == app.processIdentifier }) {
                            TinyFolderAppPocketEngine.shared.restoreWindow(windowId: match.id)
                        }
                    }
                } else {
                    Button("📁 Shrink to Folder Size") {
                        TinyFolderAppPocketEngine.shared.pocketApp(pid: app.processIdentifier)
                    }
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
                Button("Quit") {
                    app.terminate()
                }
                Button("Force Quit") {
                    app.forceTerminate()
                }
                Divider()
                Button("Show in Finder") {
                    let targetURL = app.bundleURL ?? app.bundleIdentifier.flatMap { NSWorkspace.shared.urlForApplication(withBundleIdentifier: $0) }
                    if let url = targetURL {
                        NSWorkspace.shared.activateFileViewerSelecting([url])
                    }
                }
            } else {
                Button("Open \(item.name)") {
                    MenuBarActionDispatcher.shared.handleAppClick(item)
                }
                if let url = item.bundleURL {
                    Button("Show in Finder") {
                        NSWorkspace.shared.activateFileViewerSelecting([url])
                    }
                }
            }
            Divider()
            Menu("Mini Dock Options") {
                Toggle("Active Applications Only", isOn: $dockActiveAppsOnly)
                Toggle("Always Show Finder", isOn: $dockAlwaysShowFinder)
                Toggle("Always Show Settings", isOn: $dockAlwaysShowSettings)
                Toggle("Always Show Trash", isOn: $dockAlwaysShowTrash)
                Toggle("Always Show Genie Hub", isOn: $dockAlwaysShowGenie)
                Toggle("Show Folder Stacks", isOn: $dockShowFolderStacks)
            }
            Divider()
            Button("Genie Settings...") {
                AppDelegate.shared?.showMenuBarSettingsDropdown(targetTab: .system)
            }
        }
    }

    // MARK: - Individual Dock Folder Stack Item
    @ViewBuilder
    private func dockFolderItemView(for folder: DockFolderItem) -> some View {
        let isHovered = hoveredItemId == folder.id

        Button(action: {
            HapticFeedback.selection()
            folder.openInFinder()
        }) {
            VStack(spacing: 3) {
                ZStack {
                    if let icon = folder.icon {
                        Image(nsImage: icon)
                            .resizable()
                            .interpolation(.high)
                            .aspectRatio(contentMode: .fit)
                            .frame(width: isHovered ? 48 : 40, height: isHovered ? 48 : 40)
                            .shadow(color: isHovered ? Color.cyan.opacity(0.35) : Color.black.opacity(0.25), radius: isHovered ? 8 : 4)
                    } else {
                        Image(systemName: "folder.fill")
                            .font(.system(size: isHovered ? 30 : 26))
                            .foregroundColor(Color(red: 0.35, green: 0.70, blue: 1.0))
                            .frame(width: isHovered ? 48 : 40, height: isHovered ? 48 : 40)
                    }
                }
                .animation(.spring(response: 0.22, dampingFraction: 0.75), value: isHovered)

                // Invisible spacer matching running dot height
                Circle()
                    .fill(Color.clear)
                    .frame(width: 4.5, height: 4.5)
            }
            .frame(width: 52, height: 54)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help("\(folder.name) Stack — Click to open in Finder")
        .onHover { h in
            withAnimation(.spring(response: 0.22, dampingFraction: 0.75)) {
                hoveredItemId = h ? folder.id : nil
            }
        }
        .contextMenu {
            Button("Open \(folder.name)") {
                folder.openInFinder()
            }
            Button("Show in Finder") {
                NSWorkspace.shared.activateFileViewerSelecting([folder.folderURL])
            }
        }
    }

    // MARK: - Native Live Trash Item View
    @ViewBuilder
    private var trashDockItemView: some View {
        let isHovered = hoveredItemId == "mac_trash"

        Button(action: {
            MenuBarActionDispatcher.shared.openNativeTrash()
        }) {
            VStack(spacing: 3) {
                ZStack(alignment: .topTrailing) {
                    Image(nsImage: trashIcon)
                        .resizable()
                        .interpolation(.high)
                        .aspectRatio(contentMode: .fit)
                        .frame(width: isHovered ? 48 : 40, height: isHovered ? 48 : 40)
                        .shadow(color: isHovered ? Color.cyan.opacity(0.35) : Color.black.opacity(0.25), radius: isHovered ? 8 : 4)

                    if trashMonitor.trashItemCount > 0 {
                        Text("\(trashMonitor.trashItemCount)")
                            .font(.system(size: 8.5, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1.5)
                            .background(Capsule().fill(Color.red.opacity(0.90)))
                            .offset(x: 4, y: -2)
                    }
                }
                .animation(.spring(response: 0.22, dampingFraction: 0.75), value: isHovered)

                Circle()
                    .fill(Color.clear)
                    .frame(width: 4.5, height: 4.5)
            }
            .frame(width: 52, height: 54)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(trashMonitor.isTrashFull ? "Trash (\(trashMonitor.trashItemCount) items) — Click to open" : "Trash (Empty) — Click to open")
        .onHover { h in
            withAnimation(.spring(response: 0.22, dampingFraction: 0.75)) {
                hoveredItemId = h ? "mac_trash" : nil
            }
        }
        .contextMenu {
            Button("Open Trash") {
                MenuBarActionDispatcher.shared.openNativeTrash()
            }
            if trashMonitor.isTrashFull {
                Button("Empty Trash") {
                    MenuBarActionDispatcher.shared.emptyNativeTrash()
                    trashMonitor.checkTrashNow()
                }
            }
        }
    }
}
