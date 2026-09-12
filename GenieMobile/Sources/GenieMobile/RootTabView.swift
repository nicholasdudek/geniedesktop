import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - 📱 Adaptive Root Navigation
// On iPhone: Streamlined strictly to CLI and Chat only (fast, focused, minimal footprint).
// On iPad: Full workspace navigation including Duo Fold dual-screen, Files, and Settings.

struct RootTabView: View {
    @ObservedObject private var settings = GenieSettings.shared
    @AppStorage("genie.mobile.selectedTab") private var selectedTab: Int = 0
    @State private var showSettingsSheet: Bool = false

    private var isiPhone: Bool {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .phone
        #else
        return false
        #endif
    }

    var body: some View {
        Group {
            if isiPhone {
                // 📱 iPhone Version: CLI and Chat ONLY
                TabView(selection: $selectedTab) {
                    ChatView()
                        .tabItem {
                            Label("Chat", systemImage: "bubble.left.and.bubble.right.fill")
                        }
                        .tag(0)

                    GenieCLIView()
                        .tabItem {
                            Label("CLI", systemImage: "terminal.fill")
                        }
                        .tag(1)
                }
            } else {
                // 💻 iPad & Mac Version: Full Workspace + Duo Fold
                TabView(selection: $selectedTab) {
                    ChatView()
                        .tabItem {
                            Label("Chat", systemImage: "bubble.left.and.bubble.right.fill")
                        }
                        .tag(0)

                    GenieCLIView()
                        .tabItem {
                            Label("CLI", systemImage: "terminal.fill")
                        }
                        .tag(1)

                    GenieDuoContainerView()
                        .tabItem {
                            Label("Duo Fold", systemImage: "rectangle.split.2x1.fill")
                        }
                        .tag(2)

                    FilesView()
                        .tabItem {
                            Label("Files", systemImage: "folder.fill")
                        }
                        .tag(3)

                    SettingsView()
                        .tabItem {
                            Label("Settings", systemImage: "gearshape.fill")
                        }
                        .tag(4)
                }
            }
        }
        .tint(settings.accent.color)
        .preferredColorScheme(settings.theme.colorScheme)
        .sheet(isPresented: $showSettingsSheet) {
            SettingsView()
        }
    }
}
