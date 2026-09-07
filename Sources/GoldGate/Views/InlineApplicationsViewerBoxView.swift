import AppKit
import Foundation
import SwiftUI

// MARK: - 🪟 Inline Applications Viewer Box ("put the applications in the viewer box to save space")
public struct InlineApplicationsViewerBoxView: View {
    @ObservedObject var appModel: AppModel
    @Binding var currentMode: BarMode
    @Binding var isChatFullScreen: Bool
    var chatDragGesture: AnyGesture<DragGesture.Value>?

    @State private var filterText: String = ""
    @State private var selectedCategory: AppCategory = .all
    @State private var hoveredAppId: String? = nil
    @State private var feedbackMessage: String? = nil

    public init(
        currentMode: Binding<BarMode>,
        isChatFullScreen: Binding<Bool>,
        chatDragGesture: AnyGesture<DragGesture.Value>? = nil
    ) {
        self.appModel = AppModel.shared ?? AppModel()
        self._currentMode = currentMode
        self._isChatFullScreen = isChatFullScreen
        self.chatDragGesture = chatDragGesture
    }

    private var matchingApps: [AppInfo] {
        let cat = (selectedCategory == .all) ? nil : selectedCategory
        return appModel.filteredApps(search: filterText, category: cat)
    }

    private func isRunning(_ app: AppInfo) -> Bool {
        appModel.runningApps.contains { running in
            running.bundleURL == app.url || running.localizedName == app.name
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Drag handle at top
            HStack {
                Spacer()
                Capsule()
                    .fill(Color.white.opacity(0.35))
                    .frame(width: 36, height: 4)
                    .padding(.top, 6)
                    .padding(.bottom, 2)
                Spacer()
            }
            .contentShape(Rectangle())

            // ── CONSOLIDATED PROSCENIUM HEADER & TAB BAR ──
            HStack(spacing: 8) {
                // Live Stage Beacon & Title
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 7, height: 7)
                        .shadow(color: Color.orange.opacity(0.85), radius: 3)

                    Text("🪟 APPLICATIONS")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)

                    Text("(\(matchingApps.count))")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundColor(.orange.opacity(0.90))
                }

                Spacer()

                // ── TAB SWITCHER IN THE VIEWER BOX ──
                HStack(spacing: 4) {
                    // Chat Tab
                    Button(action: {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                            currentMode = .chat
                        }
                        HapticFeedback.selection()
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "message.fill")
                            Text("Chat")
                        }
                        .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3.5)
                        .background(Capsule().fill(Color.white.opacity(0.12)))
                    }
                    .buttonStyle(.plain)
                    .help("Switch to Chat Stream 💬")

                    // Apps Tab (Active)
                    HStack(spacing: 3) {
                        Image(systemName: "square.grid.2x2.fill")
                        Text("Apps")
                    }
                    .font(.system(size: 9.5, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3.5)
                    .background(Capsule().fill(Color.orange.opacity(0.50)))
                    .overlay(Capsule().stroke(Color.orange.opacity(0.70), lineWidth: 0.6))

                    // Browser Tab
                    Button(action: {
                        withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                            currentMode = .search
                        }
                        HapticFeedback.selection()
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "globe")
                            Text("Browser")
                        }
                        .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3.5)
                        .background(Capsule().fill(Color.white.opacity(0.12)))
                    }
                    .buttonStyle(.plain)
                    .help("Switch to Web Browser 🌐")
                }

                // ── SETTINGS BUTTON MOVED TO THAT BAR ──
                Button(action: {
                    HapticFeedback.selection()
                    AppDelegate.shared?.showMenuBarSettingsDropdown(targetTab: .system)
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "gearshape.fill")
                        Text("Settings")
                    }
                    .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.90))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3.5)
                    .background(Capsule().fill(Color.purple.opacity(0.35)))
                    .overlay(Capsule().stroke(Color.purple.opacity(0.55), lineWidth: 0.6))
                }
                .buttonStyle(.plain)
                .help("Genie Preferences & Settings ⚙️")

                // Fullscreen Toggle
                Button(action: {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                        isChatFullScreen.toggle()
                    }
                    HapticFeedback.selection()
                }) {
                    Image(systemName: isChatFullScreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.85))
                        .padding(4)
                        .background(Circle().fill(Color.white.opacity(0.12)))
                }
                .buttonStyle(.plain)
                .help(isChatFullScreen ? "Exit Full Screen" : "Enter Full Screen ⛶")

                // Close Button
                Button(action: {
                    withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                        currentMode = .chat
                    }
                    HapticFeedback.tick()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.65))
                }
                .buttonStyle(.plain)
                .help("Close Applications Box")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.35))

            Divider().opacity(0.25)

            // ── CATEGORY FILTER STRIP & QUICK FILTER ──
            HStack(spacing: 6) {
                // Category Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 5) {
                        ForEach(AppCategory.allCases) { cat in
                            let isSelected = (selectedCategory == cat)
                            Button(action: {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                    selectedCategory = cat
                                }
                                HapticFeedback.selection()
                            }) {
                                HStack(spacing: 3) {
                                    Image(systemName: cat.icon)
                                        .font(.system(size: 9))
                                    Text(cat.rawValue)
                                        .font(.system(size: 9.5, weight: isSelected ? .bold : .medium))
                                }
                                .foregroundColor(isSelected ? .white : .white.opacity(0.65))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule().fill(isSelected ? cat.tintColor.opacity(0.40) : Color.white.opacity(0.08))
                                )
                                .overlay(
                                    Capsule().stroke(isSelected ? cat.tintColor.opacity(0.70) : Color.white.opacity(0.15), lineWidth: 0.6)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                }

                // Inline Filter Field
                HStack(spacing: 4) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 9.5))
                        .foregroundColor(.white.opacity(0.5))
                    TextField("Filter apps...", text: $filterText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 10.5))
                        .foregroundColor(.white)
                    if !filterText.isEmpty {
                        Button(action: { filterText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 9))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.white.opacity(0.10)))
                .frame(width: 130)
                .padding(.trailing, 12)
            }
            .background(Color.black.opacity(0.20))

            Divider().opacity(0.18)

            // ── APPLICATIONS SCROLLABLE GRID IN VIEWER BOX ──
            ScrollView(.vertical, showsIndicators: true) {
                LazyVGrid(
                    columns: [GridItem(.adaptive(minimum: 82, maximum: 105), spacing: 12)],
                    spacing: 14
                ) {
                    ForEach(matchingApps) { app in
                        let running = isRunning(app)
                        let isHovered = (hoveredAppId == app.id)

                        Button(action: {
                            HapticFeedback.selection()
                            appModel.launch(app)
                            feedbackMessage = "Launched \(app.name) 🚀"
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                                feedbackMessage = nil
                            }
                        }) {
                            VStack(spacing: 6) {
                                ZStack(alignment: .bottomTrailing) {
                                    Image(nsImage: app.icon)
                                        .resizable()
                                        .interpolation(.high)
                                        .aspectRatio(contentMode: .fit)
                                        .frame(width: 42, height: 42)
                                        .shadow(color: Color.black.opacity(0.35), radius: 4, y: 2)

                                    if running {
                                        Circle()
                                            .fill(Color(red: 0.0, green: 0.95, blue: 0.45))
                                            .frame(width: 7, height: 7)
                                            .overlay(Circle().stroke(Color.black.opacity(0.8), lineWidth: 1.2))
                                            .shadow(color: Color.green.opacity(0.8), radius: 2)
                                            .offset(x: 2, y: 2)
                                    }
                                }

                                Text(app.name)
                                    .font(.system(size: 10.5, weight: isHovered ? .bold : .medium, design: .rounded))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 6)
                            .frame(maxWidth: .infinity)
                            .background(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(isHovered ? Color.white.opacity(0.16) : Color.white.opacity(0.05))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(
                                        isHovered ? Color.orange.opacity(0.60) : Color.white.opacity(0.10),
                                        lineWidth: isHovered ? 1.0 : 0.5
                                    )
                            )
                            .scaleEffect(isHovered ? 1.05 : 1.0)
                            .animation(.spring(response: 0.22, dampingFraction: 0.75), value: isHovered)
                        }
                        .buttonStyle(.plain)
                        .onHover { h in
                            hoveredAppId = h ? app.id : nil
                        }
                        .contextMenu {
                            Button("Launch \(app.name)") {
                                appModel.launch(app)
                            }
                            Button("Reveal in Finder") {
                                NSWorkspace.shared.activateFileViewerSelecting([app.url])
                            }
                            if running {
                                Divider()
                                Button("Quit \(app.name)") {
                                    if let r = appModel.runningApps.first(where: { $0.bundleURL == app.url || $0.localizedName == app.name }) {
                                        appModel.kill(r)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(14)
            }
            .frame(height: isChatFullScreen ? (NSScreen.main?.visibleFrame.height ?? 700) - 200 : 420)

            // Feedback Toast if launched
            if let feedback = feedbackMessage {
                HStack(spacing: 5) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text(feedback)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Capsule().fill(Color.black.opacity(0.75)))
                .padding(.bottom, 6)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .frame(maxWidth: 880)
        .background(
            ZStack {
                VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow, state: .active)
                Color.black.opacity(0.65)

                RadialGradient(
                    colors: [
                        Color.orange.opacity(0.18),
                        Color.purple.opacity(0.10),
                        Color.clear
                    ],
                    center: .top,
                    startRadius: 5,
                    endRadius: 360
                )
            }
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.orange.opacity(0.45), Color.purple.opacity(0.25), Color.white.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.85
                )
        )
    }
}
