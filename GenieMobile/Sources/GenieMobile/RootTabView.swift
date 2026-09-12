import SwiftUI

struct RootTabView: View {
    @ObservedObject private var settings = GenieSettings.shared
    @AppStorage("genie.mobile.selectedTab") private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            ChatView()
                .tabItem { Label("Chat", systemImage: "bubble.left.and.bubble.right.fill") }
                .tag(0)
            FilesView()
                .tabItem { Label("Files", systemImage: "folder.fill") }
                .tag(1)
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(2)
        }
        .tint(settings.accent.color)
        .preferredColorScheme(settings.theme.colorScheme)
    }
}
