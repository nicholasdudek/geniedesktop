import SwiftUI
import AppKit

// MARK: - Minimal Mode Dropdown View (Direct Menu Bar Dropdown Launcher)
// Matching user screenshot: Search + Category Pills + 7-Column Drag-to-Rearrange Grid

struct MinimalModeDropdownView: View {
    @AppStorage(PrefKey.appLanguage) var appLanguage: String = "English (US)"
    @ObservedObject var appModel: AppModel
    @Binding var menuCompactMode: Bool
    var isEmbedded: Bool = false
    var onRefreshApps: () -> Void
    var onQuitApp: () -> Void
    var onSwitchToSettings: (() -> Void)? = nil

    @State private var searchText: String = ""
    @State private var selectedCategory: AppCategory = .all
    @State private var draggedAppID: String? = nil
    @State private var dropTargetID: String? = nil
    @State private var genieScale: CGFloat = 1.0
    @State private var genieOpacity: Double = 1.0
    @State private var genieOffsetY: CGFloat = 0.0

    @AppStorage(PrefKey.smokeEffectsEnabled) private var smokeEffectsEnabled: Bool = false
    @AppStorage(PrefKey.smokeStyle) private var smokeStyle: String = "Mystical Cyan 🧞‍♂️"
    @AppStorage(PrefKey.genieAnimOrigin) private var genieAnimOrigin: String = "Top Glyph 🪔"

    private var filteredApps: [AppInfo] {
        let base = appModel.visibleApps.filter { app in
            if selectedCategory != .all && appModel.category(for: app) != selectedCategory {
                return false
            }
            if !searchText.isEmpty {
                return app.name.localizedCaseInsensitiveContains(searchText)
            }
            return true
        }
        return base
    }

    private var columns: [GridItem] {
        if isEmbedded {
            return [GridItem(.adaptive(minimum: 70, maximum: 90), spacing: 8)]
        } else {
            return Array(repeating: GridItem(.flexible(minimum: 78, maximum: 92), spacing: 8), count: 7)
        }
    }

    var body: some View {
        if isEmbedded {
            embeddedContent
        } else {
            standaloneContent
        }
    }

    private var embeddedContent: some View {
        VStack(spacing: 0) {
            // Apple Menu Header Sub-bar: Clean Quick Info
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "square.grid.2x2.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.indigo)
                    Text(LocalizedStrings.translateText("All Applications", lang: appLanguage))
                        .font(.system(size: 11.5, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                }

                Spacer()

                Text("\(appModel.visibleApps.count) apps")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 7)
            .background(Color.primary.opacity(0.02))

            Divider().opacity(0.18)

            // Rearrangeable Application Grid (Direct Apple Menu Access)
            ScrollView(.vertical, showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(appModel.visibleApps) { app in
                        MinimalAppGridItem(
                            app: app,
                            isRunning: appModel.runningApps.contains { $0.bundleURL == app.url },
                            isDragging: draggedAppID == app.id,
                            isDropTarget: dropTargetID == app.id,
                            onLaunch: {
                                launch(app)
                            },
                            onDragStarted: {
                                draggedAppID = app.id
                            },
                            onDropApp: { sourceID in
                                withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                                    appModel.moveApp(from: sourceID, to: app.id)
                                }
                                draggedAppID = nil
                                dropTargetID = nil
                                HapticFeedback.selection()
                            },
                            onHide: {
                                appModel.hideApp(app)
                            },
                            onOpenSettings: {
                                if let onSwitch = onSwitchToSettings {
                                    onSwitch()
                                } else {
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                                        menuCompactMode = false
                                    }
                                    NotificationCenter.default.post(name: NSNotification.Name("NexusCompactModeChanged"), object: false)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 12)
            }
            .frame(maxHeight: .infinity)
        }
    }

    private var standaloneContent: some View {
        ZStack {
            // Dark frosted glass background
            VisualEffectBlur(material: .popover, blendingMode: .behindWindow)
                .overlay(Color.black.opacity(0.40))
                .cornerRadius(18)

            VStack(spacing: 0) {
                // 1. Top Bar with Window Controls, Status, and Studio Mode Toggle
                headerBar
                    .padding(.horizontal, 14)
                    .padding(.top, 8)
                    .padding(.bottom, 6)

                Divider().opacity(0.25)

                // 2. Search Applications Bar
                searchBarView
                    .padding(.horizontal, 14)
                    .padding(.top, 8)
                    .padding(.bottom, 6)

                // 3. Category Filter Chips (Horizontal Scroll)
                categoryFilterRow
                    .padding(.horizontal, 14)
                    .padding(.bottom, 8)

                Divider().opacity(0.20)

                // 4. Rearrangeable Application Grid
                ScrollView(.vertical, showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(filteredApps) { app in
                            MinimalAppGridItem(
                                app: app,
                                isRunning: appModel.runningApps.contains { $0.bundleURL == app.url },
                                isDragging: draggedAppID == app.id,
                                isDropTarget: dropTargetID == app.id,
                                onLaunch: {
                                    launch(app)
                                },
                                onDragStarted: {
                                    draggedAppID = app.id
                                },
                                onDropApp: { sourceID in
                                    withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                                        appModel.moveApp(from: sourceID, to: app.id)
                                    }
                                    draggedAppID = nil
                                    dropTargetID = nil
                                    HapticFeedback.selection()
                                },
                                onHide: {
                                    appModel.hideApp(app)
                                },
                                onOpenSettings: {
                                    withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
                                        menuCompactMode = false
                                    }
                                    NotificationCenter.default.post(name: NSNotification.Name("NexusCompactModeChanged"), object: false)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                }
                .frame(maxHeight: .infinity)

                Divider().opacity(0.20)

                // 5. Minimal Footer Bar
                footerBar
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
            }

            // Mystical Genie Smoke Plumes
            if smokeEffectsEnabled {
                GenieSmokeOverlayView(
                    style: smokeStyle,
                    bounds: CGSize(width: 680, height: 540)
                )
                .allowsHitTesting(false)
            }
        }
        .frame(width: 680, height: 540)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 1)
        )
        .scaleEffect(genieScale, anchor: .top)
        .opacity(genieOpacity)
        .offset(y: genieOffsetY)
        .onAppear {
            genieScale = 0.94
            genieOpacity = 0.85
            genieOffsetY = -10
            withAnimation(.spring(response: 0.28, dampingFraction: 0.80)) {
                genieScale = 1.0
                genieOpacity = 1.0
                genieOffsetY = 0.0
            }
            if smokeEffectsEnabled {
                GenieSmokeEngine.shared.triggerBurst(
                    origin: .topGlyph(xPercent: 0.5),
                    bounds: CGSize(width: 680, height: 540),
                    style: smokeStyle,
                    count: 36
                )
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("NexusGenieSummon"))) { notif in
            genieScale = 0.94
            genieOpacity = 0.85
            genieOffsetY = -10
            withAnimation(.spring(response: 0.28, dampingFraction: 0.80)) {
                genieScale = 1.0
                genieOpacity = 1.0
                genieOffsetY = 0.0
            }
            var glyphPct: CGFloat = 0.5
            if let dict = notif.object as? [String: Any] {
                glyphPct = (dict["glyphXPercent"] as? CGFloat) ?? 0.5
            }
            if smokeEffectsEnabled {
                GenieSmokeEngine.shared.triggerBurst(
                    origin: .topGlyph(xPercent: glyphPct),
                    bounds: CGSize(width: 680, height: 540),
                    style: smokeStyle,
                    count: 36
                )
            }
        }
    }

    // MARK: - Header Bar
    private var headerBar: some View {
        HStack(alignment: .center, spacing: 8) {
            AppleTrafficLightsControl {
                NotificationCenter.default.post(name: NSNotification.Name("NexusClose"), object: nil)
            }
            .padding(.trailing, 2)

            BrandLogoHeaderBadgeView()
                .fixedSize()

            HStack(spacing: 5) {
                Text(LocalizedStrings.translateText("Applications", lang: appLanguage))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                Text("\(appModel.visibleApps.count)")
                    .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1.5)
                    .background(Capsule().fill(Color.primary.opacity(0.08)))
            }

            Spacer()

            // Native Genie Settings Button
            Button(action: {
                HapticFeedback.selection()
                if let onSwitch = onSwitchToSettings {
                    onSwitch()
                } else {
                    AppDelegate.shared?.showApplicationsSettings(tab: .miniDock)
                }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 11, weight: .medium))
                    Text(LocalizedStrings.translateText("Settings", lang: appLanguage))
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .frame(height: 23)
                .background(RoundedRectangle(cornerRadius: 6, style: .continuous).fill(Color.primary.opacity(0.06)))
            }
            .buttonStyle(.plain)
            .help("Genie Settings (⌘,)")
        }
    }

    // MARK: - Search Bar
    private var searchBarView: some View {
        HStack(spacing: 7) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.secondary)

            TextField("Search applications (↵ to launch, ⎋ to dismiss)", text: $searchText)
                .textFieldStyle(.plain)
                .font(.system(size: 11))
                .onSubmit {
                    if let first = filteredApps.first {
                        launch(first)
                    }
                }

            if !searchText.isEmpty {
                Button(action: {
                    searchText = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.primary.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color.white.opacity(0.12), lineWidth: 0.8)
        )
    }

    // MARK: - Category Filter Chips Row
    private var categoryFilterRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(AppCategory.allCases) { cat in
                    let isSel = selectedCategory == cat
                    Button(action: {
                        HapticFeedback.selection()
                        withAnimation(.spring(response: 0.20, dampingFraction: 0.80)) {
                            selectedCategory = cat
                        }
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: cat.icon)
                                .font(.system(size: 9))
                            Text(cat.rawValue)
                                .font(.system(size: 10, weight: isSel ? .bold : .medium))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(isSel ? cat.tintColor.opacity(0.25) : Color.primary.opacity(0.05))
                        )
                        .overlay(
                            Capsule()
                                .strokeBorder(isSel ? cat.tintColor.opacity(0.70) : Color.clear, lineWidth: 1)
                        )
                        .foregroundColor(isSel ? cat.tintColor : .secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Footer Bar
    private var footerBar: some View {
        HStack {
            Image(systemName: "hand.tap")
                .font(.system(size: 9.5))
                .foregroundColor(.secondary)
            Text(LocalizedStrings.translateText("Drag & drop to rearrange apps", lang: appLanguage))
                .font(.system(size: 9.5))
                .foregroundColor(.secondary)

            Spacer()

            if UserDefaults.standard.object(forKey: PrefKey.customAppOrder) != nil {
                Button(action: {
                    HapticFeedback.selection()
                    withAnimation {
                        appModel.resetAppOrder()
                    }
                }) {
                    Text(LocalizedStrings.translateText("Reset Order", lang: appLanguage))
                        .font(.system(size: 9.5, weight: .semibold))
                        .foregroundColor(.orange)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 6)
            }
        }
    }

    private func launch(_ app: AppInfo) {
        HapticFeedback.heavy()
        let config = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.openApplication(at: app.url, configuration: config, completionHandler: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            NotificationCenter.default.post(name: NSNotification.Name("NexusClose"), object: nil)
        }
    }
}

// MARK: - Minimal App Grid Item with Live Drag & Drop Reordering

struct MinimalAppGridItem: View {
    @AppStorage(PrefKey.appLanguage) var appLanguage: String = "English (US)"
    let app: AppInfo
    let isRunning: Bool
    let isDragging: Bool
    let isDropTarget: Bool
    let onLaunch: () -> Void
    let onDragStarted: () -> Void
    let onDropApp: (String) -> Void
    let onHide: () -> Void
    let onOpenSettings: () -> Void

    @State private var isHovered: Bool = false

    var body: some View {
        Button(action: onLaunch) {
            VStack(spacing: 5) {
                ZStack(alignment: .bottom) {
                    Image(nsImage: app.icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 50, height: 50)
                        .cornerRadius(11)
                        .shadow(color: Color.black.opacity(isHovered ? 0.45 : 0.22), radius: isHovered ? 6 : 2.5, y: 2.5)
                        .scaleEffect(isHovered ? 1.06 : 1.0)
                        .animation(.spring(response: 0.20, dampingFraction: 0.75), value: isHovered)

                    // Running active indicator dot
                    if isRunning {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 4.5, height: 4.5)
                            .shadow(color: .black, radius: 1.5)
                            .offset(y: 5)
                    }
                }
                .frame(width: 56, height: 54)

                Text(app.name)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isHovered ? .white : .white.opacity(0.85))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: 82, height: 26, alignment: .top)
            }
            .padding(.vertical, 5)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isHovered ? Color.white.opacity(0.12) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(isDropTarget ? Color.cyan : (isHovered ? Color.white.opacity(0.25) : Color.clear), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .opacity(isDragging ? 0.35 : 1.0)
        .onHover { isHovered = $0 }
        .help(app.name)
        .contextMenu {
            Button("Open \(app.name)") { onLaunch() }
            Button(LocalizedStrings.translateText("Show in Finder", lang: appLanguage)) { NSWorkspace.shared.activateFileViewerSelecting([app.url]) }
            Divider()
            Button(LocalizedStrings.translateText("Hide from Grid", lang: appLanguage)) { onHide() }
        }
        .onDrag {
            onDragStarted()
            return NSItemProvider(object: app.id as NSString)
        }
        .onDrop(of: [.plainText, .text], isTargeted: nil) { providers in
            guard let provider = providers.first else { return false }
            _ = provider.loadObject(ofClass: NSString.self) { string, _ in
                guard let sourceID = string as? String else { return }
                DispatchQueue.main.async {
                    onDropApp(sourceID)
                }
            }
            return true
        }
    }
}
