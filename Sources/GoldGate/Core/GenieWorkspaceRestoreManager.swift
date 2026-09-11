import AppKit
import SwiftUI

// MARK: - 💾 Workspace State Snapshot
public struct WorkspaceStateSnapshot: Codable, Sendable {
    public var timestamp: Date
    public var currentPage: Int
    public var activeTheme: String
    public var wallpaperFxType: String
    public var cursorFxType: String
    public var formationType: String
    public var isChatOpen: Bool
    public var isTerminalOpen: Bool

    public static var defaultState: WorkspaceStateSnapshot {
        WorkspaceStateSnapshot(
            timestamp: Date(),
            currentPage: 0,
            activeTheme: "Cyber Horizons",
            wallpaperFxType: "None",
            cursorFxType: "None",
            formationType: "Responsive Grid",
            isChatOpen: false,
            isTerminalOpen: false
        )
    }
}

// MARK: - ⚡️ Genie Workspace Restore Manager
@MainActor
public final class GenieWorkspaceRestoreManager: ObservableObject {
    public static let shared = GenieWorkspaceRestoreManager()

    @Published public private(set) var latestSnapshot: WorkspaceStateSnapshot?
    @Published public var isHUDVisible: Bool = false

    private var hudWindow: NSWindow?
    private var snapshotURL: URL {
        let dir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Genie")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("workspace_snapshot.json")
    }

    private init() {
        loadSnapshot()
    }

    // MARK: - Snapshot Management

    public func saveSnapshot() {
        let currentPage = DesktopWindowManager.shared.currentPage
        let theme = UserDefaults.standard.string(forKey: PrefKey.studioTheme) ?? "Cyber Horizons"
        let wpFx = UserDefaults.standard.string(forKey: PrefKey.wallpaperFxType) ?? "None"
        let cFx = UserDefaults.standard.string(forKey: PrefKey.cursorFxType) ?? "None"
        let formation = UserDefaults.standard.string(forKey: PrefKey.appFormation) ?? "Responsive Grid"
        let isChat = FinderChatWindowManager.shared.isVisible

        let snapshot = WorkspaceStateSnapshot(
            timestamp: Date(),
            currentPage: currentPage,
            activeTheme: theme,
            wallpaperFxType: wpFx,
            cursorFxType: cFx,
            formationType: formation,
            isChatOpen: isChat,
            isTerminalOpen: false
        )

        do {
            let data = try JSONEncoder().encode(snapshot)
            try data.write(to: snapshotURL, options: .atomic)
            self.latestSnapshot = snapshot
            print("💾 [WorkspaceRestore] Saved lightning-fast workspace snapshot.")
        } catch {
            print("❌ [WorkspaceRestore] Failed to save snapshot: \(error)")
        }
    }

    public func loadSnapshot() {
        guard FileManager.default.fileExists(atPath: snapshotURL.path) else { return }
        do {
            let data = try Data(contentsOf: snapshotURL)
            self.latestSnapshot = try JSONDecoder().decode(WorkspaceStateSnapshot.self, from: data)
        } catch {
            print("⚠️ [WorkspaceRestore] Could not decode previous snapshot: \(error)")
        }
    }

    public func restoreWorkspace() {
        guard let snapshot = latestSnapshot else { return }
        print("⚡️ [WorkspaceRestore] Restoring workspace from snapshot (\(snapshot.timestamp.formatted()))...")

        UserDefaults.standard.set(snapshot.activeTheme, forKey: PrefKey.studioTheme)
        UserDefaults.standard.set(snapshot.wallpaperFxType, forKey: PrefKey.wallpaperFxType)
        UserDefaults.standard.set(snapshot.cursorFxType, forKey: PrefKey.cursorFxType)
        UserDefaults.standard.set(snapshot.formationType, forKey: PrefKey.appFormation)

        DesktopWindowManager.shared.setPage(snapshot.currentPage)
        if snapshot.isChatOpen && !FinderChatWindowManager.shared.isVisible {
            FinderChatWindowManager.shared.show()
        }

        hideHUD()
    }

    // MARK: - Lightning Fast Self-Restart

    public func fastRestart() {
        print("🚀 [WorkspaceRestore] Fast restarting Genie with instant state preservation...")
        saveSnapshot()

        let appURL = Bundle.main.bundleURL
        let config = NSWorkspace.OpenConfiguration()
        config.createsNewApplicationInstance = true

        NSWorkspace.shared.openApplication(at: appURL, configuration: config) { _, error in
            if let err = error {
                print("❌ [WorkspaceRestore] Failed to relaunch app: \(err)")
            } else {
                DispatchQueue.main.async {
                    NSApp.terminate(nil)
                }
            }
        }
    }

    // MARK: - Restore HUD Window Presentation

    public func showHUD() {
        if hudWindow == nil {
            buildHUDWindow()
        }
        guard let window = hudWindow else { return }
        window.center()
        window.orderFrontRegardless()
        isHUDVisible = true

        // Auto dismiss after 6 seconds of inactivity
        DispatchQueue.main.asyncAfter(deadline: .now() + 6.0) { [weak self] in
            guard let self = self, self.isHUDVisible else { return }
            self.hideHUD()
        }
    }

    public func hideHUD() {
        hudWindow?.orderOut(nil)
        isHUDVisible = false
    }

    public func toggleHUD() {
        if isHUDVisible {
            hideHUD()
        } else {
            showHUD()
        }
    }

    private func buildHUDWindow() {
        let contentRect = NSRect(x: 0, y: 0, width: 440, height: 260)
        let window = NSWindow(
            contentRect: contentRect,
            styleMask: [.borderless, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.isOpaque = false
        window.backgroundColor = .clear
        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .transient]
        window.isMovableByWindowBackground = true

        window.contentView = NSHostingView(rootView: GenieWorkspaceRestoreHUDView())
        self.hudWindow = window
    }
}

// MARK: - 🎨 Restore HUD SwiftUI View

public struct GenieWorkspaceRestoreHUDView: View {
    @ObservedObject var restoreManager = GenieWorkspaceRestoreManager.shared
    @ObservedObject var governor = GenieResourceGovernor.shared
    @AppStorage(PrefKey.showWorkspaceRestoreHUDOnLaunch) private var showOnLaunch: Bool = false

    public var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack(spacing: 12) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 38, height: 38)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .shadow(color: Color.black.opacity(0.4), radius: 6, y: 3)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Genie Workspace Ready")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)
                    Text("Spatial Matrix & Lightning Restore Active")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.7))
                }
                Spacer()

                Button {
                    restoreManager.hideHUD()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(Color.white.opacity(0.5))
                }
                .buttonStyle(.plain)
            }

            Divider().background(Color.white.opacity(0.15))

            // Action Buttons
            HStack(spacing: 10) {
                Button {
                    restoreManager.restoreWorkspace()
                } label: {
                    HStack(spacing: 6) {
                        Text("⚡️")
                        Text("Restore Workspace")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.orange.opacity(0.35)))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.orange.opacity(0.6), lineWidth: 1))
                    .foregroundColor(.white)
                }
                .buttonStyle(.plain)

                Button {
                    DesktopWindowManager.shared.togglePage()
                    restoreManager.hideHUD()
                } label: {
                    HStack(spacing: 6) {
                        Text("🔮")
                        Text("Open Canvas")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.purple.opacity(0.35)))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.purple.opacity(0.6), lineWidth: 1))
                    .foregroundColor(.white)
                }
                .buttonStyle(.plain)

                Button {
                    restoreManager.fastRestart()
                } label: {
                    HStack(spacing: 6) {
                        Text("🔄")
                        Text("Restart")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.blue.opacity(0.35)))
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.blue.opacity(0.6), lineWidth: 1))
                    .foregroundColor(.white)
                }
                .buttonStyle(.plain)
            }

            // Resource Guard Telemetry & Launch Preference Footer
            HStack(spacing: 8) {
                Circle()
                    .fill(governor.isYieldingResources ? Color.green : Color.yellow)
                    .frame(width: 8, height: 8)

                if governor.isYieldingResources {
                    Text("Chrome Guard: Active")
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundColor(Color.green.opacity(0.9))
                } else {
                    Text("120 FPS ProMotion Native Engine")
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundColor(Color.white.opacity(0.6))
                }
                Spacer()

                Toggle("Show on launch", isOn: $showOnLaunch)
                    .toggleStyle(.checkbox)
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundColor(Color.white.opacity(0.75))
            }
            .padding(.top, 4)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(red: 0.08, green: 0.10, blue: 0.15).opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.25), Color.white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(color: Color.black.opacity(0.6), radius: 24, y: 12)
        )
        .frame(width: 440)
    }
}
