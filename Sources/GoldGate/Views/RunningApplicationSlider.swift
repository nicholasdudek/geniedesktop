import AppKit
import SwiftUI

/// A stable running-app list while dragging; selection activates only on release.
struct RunningApplicationSlider: View {
    @State private var applications: [NSRunningApplication] = []
    @State private var selectedIndex = 0
    @State private var isDragging = false
    @State private var isHovered = false
    private let trackHeight: CGFloat = 112

    private var destinationCount: Int { applications.count + 5 }
    private var selectedApp: NSRunningApplication? {
        let index = selectedIndex - 2
        return applications.indices.contains(index) ? applications[index] : nil
    }
    private var selectedTitle: String {
        if selectedIndex == 0 { return "Chat" }
        if selectedIndex == 1 { return "Wallpaper" }
        if selectedIndex == destinationCount - 3 { return "Messages" }
        if selectedIndex == destinationCount - 2 { return "Trash" }
        if selectedIndex == destinationCount - 1 { return "Applications" }
        return selectedApp?.localizedName ?? "Application closed"
    }

    var body: some View {
        HStack(spacing: 8) {
            if isHovered || isDragging {
                Text(selectedTitle)
                    .font(.caption)
                    .padding(8)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
            }
            ZStack(alignment: .top) {
                Capsule().fill(.ultraThinMaterial)
                Capsule().strokeBorder(Color.white.opacity(0.35), lineWidth: 1.2)
                Capsule().fill(Color.white.opacity(0.92))
                    .frame(width: 18, height: 26)
                    .shadow(color: Color.cyan.opacity(0.5), radius: 3)
                    .offset(y: thumbOffset)
            }
            .frame(width: 26, height: trackHeight)
            .contentShape(Rectangle())
            .gesture(DragGesture(minimumDistance: 0)
                .onChanged { value in
                    if !isDragging { refreshApplications(); isDragging = true }
                    select(at: value.location.y)
                }
                .onEnded { value in
                    select(at: value.location.y)
                    isDragging = false
                    refreshApplications()
                    activateSelection()
                })
            .accessibilityElement()
            .accessibilityLabel("Running applications")
            .accessibilityValue(selectedTitle)
            .accessibilityAdjustableAction { direction in
                refreshApplications()
                switch direction {
                case .increment: selectedIndex = (selectedIndex + 1) % destinationCount
                case .decrement: selectedIndex = (selectedIndex + destinationCount - 1) % destinationCount
                @unknown default: return
                }
                activateSelection()
            }
        }
        .onHover { isHovered = $0 }
        .opacity(isHovered || isDragging ? 1.0 : 0.45)
        .animation(.easeInOut(duration: 0.18), value: isHovered || isDragging)
        .help("Running Application Slider — Drag and release to switch between apps and stations")
        .onAppear { refreshApplications() }
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didLaunchApplicationNotification)) { _ in
            if !isDragging { refreshApplications() }
        }
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didTerminateApplicationNotification)) { _ in
            if !isDragging { refreshApplications() }
        }
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didActivateApplicationNotification)) { _ in
            if !isDragging { refreshApplications() }
        }
    }

    private var thumbOffset: CGFloat {
        return CGFloat(selectedIndex) / CGFloat(destinationCount - 1) * (trackHeight - 20)
    }

    private func select(at y: CGFloat) {
        let fraction = max(0, min(1, (y - 10) / (trackHeight - 20)))
        selectedIndex = Int((fraction * CGFloat(destinationCount - 1)).rounded())
    }

    private func refreshApplications() {
        applications = NSWorkspace.shared.runningApplications
            .filter {
                $0.activationPolicy == .regular &&
                !$0.isTerminated &&
                $0.processIdentifier != ProcessInfo.processInfo.processIdentifier &&
                $0.bundleIdentifier != "com.apple.finder" &&
                $0.bundleIdentifier != "com.apple.MobileSMS"
            }
            .sorted {
                let first = $0.localizedName ?? ""
                let second = $1.localizedName ?? ""
                if first == second { return $0.processIdentifier < $1.processIdentifier }
                return first.localizedStandardCompare(second) == .orderedAscending
            }
        if let active = applications.firstIndex(where: { $0.isActive }), selectedIndex < 2 || selectedIndex >= destinationCount - 3 {
            selectedIndex = active + 2
        } else {
            selectedIndex = min(selectedIndex, destinationCount - 1)
        }
    }

    private func activateSelection() {
        HapticFeedback.selection()
        if selectedIndex == 0 {
            FinderChatWindowManager.shared.openTab(.chat)
            DesktopWindowManager.shared.setPage(0)
        } else if selectedIndex == 1 {
            DesktopWindowManager.shared.setPage(1)
        } else if selectedIndex == destinationCount - 3 {
            if let messagesApp = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == "com.apple.MobileSMS" }) {
                messagesApp.unhide()
                _ = messagesApp.activate(options: [.activateAllWindows])
            } else if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.MobileSMS") {
                NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
            }
        } else if selectedIndex == destinationCount - 2 {
            FinderChatWindowManager.shared.openTab(.files)
        } else if selectedIndex == destinationCount - 1 {
            DesktopWindowManager.shared.setPage(2)
        } else if let app = selectedApp {
            app.unhide()
            _ = app.activate(options: [.activateAllWindows])
            if let bid = app.bundleIdentifier {
                FinderChatWindowManager.shared.openProgram(bundleId: bid, name: app.localizedName ?? "App")
            }
        }
    }
}
