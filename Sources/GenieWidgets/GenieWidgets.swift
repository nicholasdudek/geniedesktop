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

// MARK: - ⏱️ Genie World Clock Widget

public struct GenieWidgetCity: Identifiable {
    public var id: String { name }
    public let name: String
    public let timeZoneIdentifier: String
    public let accent: Color

    public init(name: String, timeZoneIdentifier: String, accent: Color) {
        self.name = name
        self.timeZoneIdentifier = timeZoneIdentifier
        self.accent = accent
    }

    public var timeZone: TimeZone {
        TimeZone(identifier: timeZoneIdentifier) ?? .current
    }

    public func timeString(at date: Date, use24Hour: Bool = false) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.dateFormat = use24Hour ? "HH:mm" : "h:mm"
        return formatter.string(from: date)
    }

    public func periodString(at date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.dateFormat = "a"
        return formatter.string(from: date)
    }

    public func offsetString(at date: Date) -> String {
        let delta = timeZone.secondsFromGMT(for: date) - TimeZone.current.secondsFromGMT(for: date)
        if delta == 0 { return "same" }
        let sign = delta < 0 ? "−" : "+"
        let hours = abs(delta) / 3600
        let minutes = (abs(delta) % 3600) / 60
        return minutes == 0 ? "\(sign)\(hours)h" : "\(sign)\(hours)h\(minutes)m"
    }

    public func isNight(at date: Date) -> Bool {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let hour = cal.component(.hour, from: date)
        return hour < 6 || hour >= 18
    }

    public static let defaultCities: [GenieWidgetCity] = [
        GenieWidgetCity(name: "Cupertino", timeZoneIdentifier: "America/Los_Angeles", accent: Color(red: 1.0, green: 0.58, blue: 0.0)),
        GenieWidgetCity(name: "New York",  timeZoneIdentifier: "America/New_York",     accent: Color(red: 0.29, green: 0.78, blue: 0.94)),
        GenieWidgetCity(name: "London",    timeZoneIdentifier: "Europe/London",        accent: Color(red: 0.58, green: 0.44, blue: 0.96)),
        GenieWidgetCity(name: "Tokyo",     timeZoneIdentifier: "Asia/Tokyo",           accent: Color(red: 0.95, green: 0.38, blue: 0.52))
    ]
}

public struct GenieWorldClockEntry: TimelineEntry {
    public let date: Date
    public let cities: [GenieWidgetCity]

    public init(date: Date = Date(), cities: [GenieWidgetCity] = GenieWidgetCity.defaultCities) {
        self.date = date
        self.cities = cities
    }
}

public struct GenieWorldClockTimelineProvider: TimelineProvider {
    public init() {}

    public func placeholder(in context: Context) -> GenieWorldClockEntry {
        GenieWorldClockEntry()
    }

    public func getSnapshot(in context: Context, completion: @escaping (GenieWorldClockEntry) -> Void) {
        completion(GenieWorldClockEntry())
    }

    public func getTimeline(in context: Context, completion: @escaping (Timeline<GenieWorldClockEntry>) -> Void) {
        let entry = GenieWorldClockEntry(date: Date())
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 1, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

struct WidgetAnalogDialView: View {
    let date: Date
    let timeZone: TimeZone
    let accent: Color
    let size: CGFloat

    private var angles: (hour: Double, minute: Double) {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let hour = Double(cal.component(.hour, from: date) % 12)
        let minute = Double(cal.component(.minute, from: date))
        let second = Double(cal.component(.second, from: date))

        let minuteAngle = (minute + second / 60.0) * 6.0
        let hourAngle = (hour + minute / 60.0) * 30.0
        return (hourAngle, minuteAngle)
    }

    var body: some View {
        let currentAngles = angles

        ZStack {
            Circle()
                .fill(Color(white: 0.07))
                .overlay(
                    Circle().stroke(Color.white.opacity(0.18), lineWidth: 1)
                )

            ForEach(0..<12) { tick in
                Rectangle()
                    .fill(tick % 3 == 0 ? Color.white.opacity(0.8) : Color.white.opacity(0.3))
                    .frame(width: tick % 3 == 0 ? 1.5 : 1, height: tick % 3 == 0 ? size * 0.12 : size * 0.07)
                    .offset(y: -size * 0.40)
                    .rotationEffect(.degrees(Double(tick) * 30.0))
            }

            // Hour Hand
            RoundedRectangle(cornerRadius: 1.5)
                .fill(Color.white)
                .frame(width: max(2, size * 0.04), height: size * 0.28)
                .offset(y: -size * 0.14)
                .rotationEffect(.degrees(currentAngles.hour))

            // Minute Hand
            RoundedRectangle(cornerRadius: 1)
                .fill(Color.white.opacity(0.92))
                .frame(width: max(1.5, size * 0.03), height: size * 0.38)
                .offset(y: -size * 0.19)
                .rotationEffect(.degrees(currentAngles.minute))

            // Center Pin
            Circle()
                .fill(accent)
                .frame(width: max(3.5, size * 0.08), height: max(3.5, size * 0.08))
        }
        .frame(width: size, height: size)
    }
}

public struct GenieWorldClockWidget: Widget {
    public let kind: String = "com.nicholasdudek.genie.widget.worldclock"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GenieWorldClockTimelineProvider()) { entry in
            WorldClockWidgetEntryView(entry: entry)
                .containerBackground(Color.black.opacity(0.92), for: .widget)
        }
        .configurationDisplayName("Genie World Clock")
        .description("OLED blackout world clocks with analog watch faces and timezone offsets.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct WorldClockWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: GenieWorldClockEntry

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        default:
            largeView
        }
    }

    private var smallView: some View {
        let city = entry.cities.first ?? GenieWidgetCity.defaultCities[0]
        return VStack(alignment: .leading, spacing: 6) {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text(city.name)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text(city.offsetString(at: entry.date))
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.55))
                }
                Spacer()
                Image(systemName: city.isNight(at: entry.date) ? "moon.stars.fill" : "sun.max.fill")
                    .font(.system(size: 13))
                    .foregroundColor(city.isNight(at: entry.date) ? .indigo : city.accent)
            }

            Spacer()

            HStack {
                Spacer()
                WidgetAnalogDialView(
                    date: entry.date,
                    timeZone: city.timeZone,
                    accent: city.accent,
                    size: 64
                )
                Spacer()
            }

            Spacer()

            HStack {
                Text(city.timeString(at: entry.date))
                    .font(.system(size: 18, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundColor(.white)
                Text(city.periodString(at: entry.date))
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(city.accent)
                Spacer()
            }
        }
        .padding(12)
    }

    private var mediumView: some View {
        let displayCities = Array(entry.cities.prefix(3))
        return HStack(spacing: 8) {
            ForEach(displayCities) { city in
                VStack(spacing: 6) {
                    HStack(spacing: 4) {
                        Text(city.name)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Spacer()
                        Image(systemName: city.isNight(at: entry.date) ? "moon.fill" : "sun.max.fill")
                            .font(.system(size: 9))
                            .foregroundColor(city.isNight(at: entry.date) ? .indigo : city.accent)
                    }

                    Text(city.offsetString(at: entry.date))
                        .font(.system(size: 9, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.5))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Spacer()

                    WidgetAnalogDialView(
                        date: entry.date,
                        timeZone: city.timeZone,
                        accent: city.accent,
                        size: 44
                    )

                    Spacer()

                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(city.timeString(at: entry.date))
                            .font(.system(size: 13, weight: .bold, design: .rounded).monospacedDigit())
                            .foregroundColor(.white)
                        Text(city.periodString(at: entry.date))
                            .font(.system(size: 8, weight: .semibold))
                            .foregroundColor(city.accent)
                    }
                }
                .padding(8)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(white: 0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.10), lineWidth: 0.8)
                        )
                )
            }
        }
        .padding(10)
    }

    private var largeView: some View {
        let displayCities = Array(entry.cities.prefix(4))
        return VStack(spacing: 8) {
            HStack {
                Label("World Clock", systemImage: "globe.americas.fill")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Text("OLED Blackout Pillows")
                    .font(.system(size: 9.5, weight: .medium))
                    .foregroundColor(.white.opacity(0.45))
            }
            .padding(.horizontal, 4)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(displayCities) { city in
                    HStack(spacing: 8) {
                        WidgetAnalogDialView(
                            date: entry.date,
                            timeZone: city.timeZone,
                            accent: city.accent,
                            size: 46
                        )

                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(city.name)
                                    .font(.system(size: 11.5, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                Spacer()
                                Image(systemName: city.isNight(at: entry.date) ? "moon.fill" : "sun.max.fill")
                                    .font(.system(size: 9))
                                    .foregroundColor(city.isNight(at: entry.date) ? .indigo : city.accent)
                            }

                            Text(city.offsetString(at: entry.date))
                                .font(.system(size: 9, design: .monospaced))
                                .foregroundColor(.white.opacity(0.55))

                            HStack(alignment: .firstTextBaseline, spacing: 2) {
                                Text(city.timeString(at: entry.date))
                                    .font(.system(size: 13.5, weight: .bold, design: .rounded).monospacedDigit())
                                    .foregroundColor(.white)
                                Text(city.periodString(at: entry.date))
                                    .font(.system(size: 8.5, weight: .semibold))
                                    .foregroundColor(city.accent)
                            }
                        }
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(white: 0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.12), lineWidth: 0.8)
                            )
                    )
                }
            }
        }
        .padding(12)
    }
}

// MARK: - 💬✨ First-Ever Genie Animated Living Chat Widget

public struct GenieAnimatedChatEntry: TimelineEntry {
    public let date: Date
    public let promptSuggestion: String
    public let modelName: String
    public let pulsePhase: Int

    public init(
        date: Date = Date(),
        promptSuggestion: String = "✨ Ask Genie anything...",
        modelName: String = "Gemini 2.5 Pro",
        pulsePhase: Int = 0
    ) {
        self.date = date
        self.promptSuggestion = promptSuggestion
        self.modelName = modelName
        self.pulsePhase = pulsePhase
    }
}

public struct GenieAnimatedChatTimelineProvider: TimelineProvider {
    private let suggestions = [
        "✨ Ask Genie anything...",
        "💻 Refactor & build Swift code",
        "🧠 Analyze project architecture",
        "⚡️ Summon Copilot with ⌥Space",
        "🔮 Explore Living Companions",
        "🌸 Switch to Neural Bloom backdrop"
    ]

    public init() {}

    public func placeholder(in context: Context) -> GenieAnimatedChatEntry {
        GenieAnimatedChatEntry()
    }

    public func getSnapshot(in context: Context, completion: @escaping (GenieAnimatedChatEntry) -> Void) {
        completion(GenieAnimatedChatEntry())
    }

    public func getTimeline(in context: Context, completion: @escaping (Timeline<GenieAnimatedChatEntry>) -> Void) {
        var entries: [GenieAnimatedChatEntry] = []
        let currentDate = Date()
        for minuteOffset in 0..<12 {
            let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: currentDate) ?? currentDate
            let suggestion = suggestions[minuteOffset % suggestions.count]
            entries.append(GenieAnimatedChatEntry(
                date: entryDate,
                promptSuggestion: suggestion,
                modelName: "Gemini 2.5 Pro",
                pulsePhase: minuteOffset
            ))
        }
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

public struct GenieAnimatedChatWidget: Widget {
    public let kind: String = "com.nicholasdudek.genie.widget.animatedchat"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: GenieAnimatedChatTimelineProvider()) { entry in
            AnimatedChatWidgetEntryView(entry: entry)
                .containerBackground(Color.black.opacity(0.92), for: .widget)
        }
        .configurationDisplayName("Genie Animated AI Chat")
        .description("World's first animated living AI assistant widget with typing waves and ambient aura.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct AnimatedChatWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: GenieAnimatedChatEntry

    var body: some View {
        switch family {
        case .systemSmall:
            smallAnimatedView
        default:
            mediumAnimatedView
        }
    }

    private var smallAnimatedView: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Header with glowing core
            HStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.cyan, Color.purple, Color.clear],
                                center: .center,
                                startRadius: 2,
                                endRadius: 10
                            )
                        )
                        .frame(width: 14, height: 14)
                    Circle()
                        .fill(Color.cyan)
                        .frame(width: 6, height: 6)
                }

                Text("Genie AI")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Spacer()

                Text("ACTIVE")
                    .font(.system(size: 8, weight: .black, design: .monospaced))
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.cyan.opacity(0.2)))
            }

            Spacer()

            // Living Orb in Center
            HStack {
                Spacer()
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.cyan.opacity(0.35), Color.purple.opacity(0.35), Color.orange.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 48, height: 48)
                        .overlay(
                            Circle().stroke(Color.cyan.opacity(0.5), lineWidth: 1)
                        )

                    // Dancing Wave Bars
                    HStack(spacing: 3) {
                        ForEach(0..<4) { idx in
                            RoundedRectangle(cornerRadius: 1.5)
                                .fill(LinearGradient(colors: [Color.cyan, Color.white], startPoint: .bottom, endPoint: .top))
                                .frame(width: 3, height: CGFloat(12 + ((entry.pulsePhase + idx) % 4) * 6))
                        }
                    }
                }
                Spacer()
            }

            Spacer()

            // Prompt Bubble
            HStack(spacing: 4) {
                Text(entry.promptSuggestion)
                    .font(.system(size: 9.5, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                    .lineLimit(1)
                Spacer()
                Image(systemName: "sparkle")
                    .font(.system(size: 9))
                    .foregroundColor(.cyan)
            }
            .padding(6)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.08)))
        }
        .padding(10)
    }

    private var mediumAnimatedView: some View {
        HStack(spacing: 12) {
            // Living Aura Orb & Waveform Column
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.cyan.opacity(0.6), Color.purple.opacity(0.3), Color.clear],
                                center: .center,
                                startRadius: 4,
                                endRadius: 28
                            )
                        )
                        .frame(width: 56, height: 56)

                    Circle()
                        .fill(Color(white: 0.08))
                        .frame(width: 44, height: 44)
                        .overlay(Circle().stroke(Color.cyan.opacity(0.6), lineWidth: 1.2))

                    // Equalizer Waveform Bars
                    HStack(spacing: 2.5) {
                        ForEach(0..<5) { bar in
                            RoundedRectangle(cornerRadius: 1.5)
                                .fill(LinearGradient(colors: [Color.cyan, Color.white], startPoint: .bottom, endPoint: .top))
                                .frame(width: 2.5, height: CGFloat(8 + ((entry.pulsePhase + bar * 2) % 5) * 4))
                        }
                    }
                }

                Text(entry.modelName)
                    .font(.system(size: 8.5, weight: .bold, design: .rounded))
                    .foregroundColor(.cyan)
            }
            .frame(width: 72)

            // Dynamic Speech Bubble & Quick Action Column
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Genie Intelligent Agent")
                        .font(.system(size: 11.5, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Spacer()
                    HStack(spacing: 3) {
                        Circle().fill(Color.green).frame(width: 4.5, height: 4.5)
                        Text("Online")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.green)
                    }
                }

                // Animated Speech Prompt Box
                HStack(spacing: 6) {
                    Text(entry.promptSuggestion)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.92))
                        .lineLimit(1)
                    Spacer()
                    // Animated typing dots
                    HStack(spacing: 2) {
                        ForEach(0..<3) { dot in
                            Circle()
                                .fill(Color.cyan.opacity(Double(dot + 1) * 0.33))
                                .frame(width: 3.5, height: 3.5)
                        }
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 7)
                .background(
                    RoundedRectangle(cornerRadius: 9)
                        .fill(Color.white.opacity(0.08))
                        .overlay(RoundedRectangle(cornerRadius: 9).stroke(Color.white.opacity(0.12), lineWidth: 0.8))
                )

                // Quick Action Chips
                HStack(spacing: 6) {
                    actionChip(title: "💻 Code", icon: "terminal.fill")
                    actionChip(title: "💬 Chat", icon: "bubble.left.fill")
                    actionChip(title: "⚡️ Summon", icon: "bolt.fill")
                }
            }
        }
        .padding(12)
    }

    private func actionChip(title: String, icon: String) -> some View {
        HStack(spacing: 3.5) {
            Image(systemName: icon)
                .font(.system(size: 8.5))
                .foregroundColor(.cyan)
            Text(title)
                .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                .foregroundColor(.white.opacity(0.85))
        }
        .padding(.horizontal, 7)
        .padding(.vertical, 4)
        .background(Capsule().fill(Color.white.opacity(0.06)))
        .overlay(Capsule().stroke(Color.white.opacity(0.10), lineWidth: 0.6))
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
        GenieWorldClockWidget()
        GenieAnimatedChatWidget()
    }
}
