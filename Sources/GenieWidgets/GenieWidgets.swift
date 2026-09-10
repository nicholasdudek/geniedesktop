import WidgetKit
import SwiftUI
import AppKit

// MARK: - 🔮 Genie Widgets Timeline Provider
public struct GenieWidgetEntry: TimelineEntry {
    public let date: Date
    public let activeModel: String
    public let currentStation: String
    public let batteryLevel: Int
    public let isSandboxActive: Bool

    public init(
        date: Date = Date(),
        activeModel: String = "Gemini 2.5 Pro",
        currentStation: String = "Desktop",
        batteryLevel: Int = 100,
        isSandboxActive: Bool = true
    ) {
        self.date = date
        self.activeModel = activeModel
        self.currentStation = currentStation
        self.batteryLevel = batteryLevel
        self.isSandboxActive = isSandboxActive
    }
}

public struct GenieWidgetTimelineProvider: TimelineProvider {
    public init() {}

    public func placeholder(in context: Context) -> GenieWidgetEntry {
        GenieWidgetEntry()
    }

    public func getSnapshot(in context: Context, completion: @escaping (GenieWidgetEntry) -> Void) {
        completion(GenieWidgetEntry())
    }

    public func getTimeline(in context: Context, completion: @escaping (Timeline<GenieWidgetEntry>) -> Void) {
        let entry = GenieWidgetEntry(date: Date())
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - 💬 Genie Quick Chat Widget
public struct GenieQuickChatWidget: Widget {
    public let kind: String = "com.nicholasdudek.genie.widget.quickchat"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GenieWidgetTimelineProvider()) { entry in
            QuickChatWidgetEntryView(entry: entry)
                .containerBackground(Color.black.opacity(0.85), for: .widget)
        }
        .configurationDisplayName("Genie Quick Chat")
        .description("Instant access to Genie AI assistant and active model status.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct QuickChatWidgetEntryView: View {
    var entry: GenieWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                ZStack {
                    Circle().fill(Color.cyan).frame(width: 8, height: 8)
                    Circle().stroke(Color.cyan.opacity(0.4), lineWidth: 2).frame(width: 14, height: 14)
                }
                Text("Genie AI")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Text("Active")
                    .font(.system(size: 9.5, weight: .semibold))
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.cyan.opacity(0.2)))
            }

            Spacer()

            Text(entry.activeModel)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.65))

            HStack {
                Text("Tap to ask...")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.white.opacity(0.40))
                Spacer()
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.cyan)
            }
            .padding(8)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color.white.opacity(0.08)))
        }
        .padding(12)
    }
}

// MARK: - 📊 Genie System Status Widget
public struct GenieSystemStatusWidget: Widget {
    public let kind: String = "com.nicholasdudek.genie.widget.systemstatus"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GenieWidgetTimelineProvider()) { entry in
            SystemStatusWidgetEntryView(entry: entry)
                .containerBackground(Color.black.opacity(0.85), for: .widget)
        }
        .configurationDisplayName("Genie Telemetry")
        .description("Real-time desktop telemetry, station monitor, and sandbox security.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct SystemStatusWidgetEntryView: View {
    var entry: GenieWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Genie Station", systemImage: "sparkles")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Image(systemName: entry.isSandboxActive ? "shield.fill" : "shield.slash")
                    .font(.system(size: 11))
                    .foregroundColor(entry.isSandboxActive ? .cyan : .orange)
            }

            Spacer()

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Station:")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.55))
                    Text(entry.currentStation)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                }

                HStack {
                    Text("Sandbox:")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.55))
                    Text(entry.isSandboxActive ? "Protected" : "Unrestricted")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(entry.isSandboxActive ? .green : .orange)
                }
            }
        }
        .padding(12)
    }
}

// MARK: - 🗂️ Genie Workspace Switcher Widget
public struct GenieWorkspaceSwitcherWidget: Widget {
    public let kind: String = "com.nicholasdudek.genie.widget.switcher"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GenieWidgetTimelineProvider()) { entry in
            WorkspaceSwitcherWidgetEntryView(entry: entry)
                .containerBackground(Color.black.opacity(0.85), for: .widget)
        }
        .configurationDisplayName("Genie Stations")
        .description("Quick 1-tap switching between Desktop, Chat, and Applications stations.")
        .supportedFamilies([.systemMedium])
    }
}

struct WorkspaceSwitcherWidgetEntryView: View {
    var entry: GenieWidgetEntry

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Genie Workspaces")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Text("3 Stations")
                    .font(.system(size: 10))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            HStack(spacing: 8) {
                stationButton(title: "Desktop", icon: "desktopcomputer", active: entry.currentStation == "Desktop")
                stationButton(title: "Chat", icon: "bubble.left.and.bubble.right.fill", active: entry.currentStation == "Chat")
                stationButton(title: "Apps", icon: "square.grid.2x2.fill", active: entry.currentStation == "Applications")
            }
        }
        .padding(12)
    }

    private func stationButton(title: String, icon: String, active: Bool) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(active ? .cyan : .white.opacity(0.7))
            Text(title)
                .font(.system(size: 10, weight: active ? .bold : .medium))
                .foregroundColor(active ? .white : .white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(active ? Color.cyan.opacity(0.2) : Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(active ? Color.cyan.opacity(0.5) : Color.clear, lineWidth: 1)
        )
    }
}

// MARK: - 📦 Genie Widgets Bundle Root
@main
public struct GenieWidgetsBundle: WidgetBundle {
    public init() {}

    public var body: some Widget {
        GenieQuickChatWidget()
        GenieSystemStatusWidget()
        GenieWorkspaceSwitcherWidget()
    }
}
