import SwiftUI

public struct WorldClockPaneView: View {
    @ObservedObject var store = GenieWorldClockStore.shared
    @ObservedObject var alarmManager = GenieAlarmClockManager.shared

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            if let alarm = alarmManager.ringingAlarm {
                HStack {
                    Text(alarm.label)
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Button("Snooze") {
                        alarmManager.snooze()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("Dismiss") {
                        alarmManager.stopRinging()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
                .padding()
                .background(Color.red.opacity(0.8))
            }
            
            HStack {
                Text("World Clock")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                
                Spacer()
                
                Picker("", selection: $store.settings.size) {
                    ForEach(GeniePillowSize.allCases) { size in
                        Image(systemName: size.icon).tag(size)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 130)
                .controlSize(.small)
                
                Menu {
                    ForEach(GenieWorldClockCity.presets, id: \.identifier) { preset in
                        Button(preset.name) {
                            store.addCity(name: preset.name, identifier: preset.identifier)
                        }
                    }
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(.white)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
                
                Menu {
                    Toggle("Show Seconds", isOn: $store.settings.showSeconds)
                    Toggle("24-Hour Time", isOn: $store.settings.use24Hour)
                    Divider()
                    Button("Restore Defaults") {
                        store.restoreDefaults()
                    }
                } label: {
                    Image(systemName: "gearshape")
                        .foregroundColor(.white)
                }
                .menuStyle(.borderlessButton)
                .fixedSize()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            
            ScrollView {
                TimelineView(.periodic(from: .now, by: store.settings.showSeconds ? 1 : 60)) { context in
                    LazyVStack(spacing: 8) {
                        ForEach(store.settings.cities) { city in
                            cityCard(city: city, date: context.date)
                                .contextMenu {
                                    Button("Remove", role: .destructive) {
                                        store.remove(city)
                                    }
                                }
                        }
                        .onMove { indices, newOffset in
                            store.move(from: indices, to: newOffset)
                        }
                        .onDelete { indices in
                            for idx in indices {
                                store.remove(store.settings.cities[idx])
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                }
            }
            .genieThickScrollBars()
        }
        .onAppear {
            alarmManager.start()
        }
    }
    
    @ViewBuilder
    private func cityCard(city: GenieWorldClockCity, date: Date) -> some View {
        let size = store.settings.size
        
        ZStack {
            Color.black
            
            Group {
                switch size {
                case .compact:
                    compactContent(city: city, date: date)
                case .regular:
                    regularContent(city: city, date: date)
                case .large:
                    largeContent(city: city, date: date)
                case .hero:
                    heroContent(city: city, date: date)
                }
            }
            .padding(.horizontal, 12)
        }
        .frame(height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: size.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: size.cornerRadius)
                .stroke(
                    LinearGradient(
                        colors: [
                            city.accent.color.opacity(0.6),
                            city.accent.color.opacity(0.15)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        )
    }
    
    @ViewBuilder
    private func compactContent(city: GenieWorldClockCity, date: Date) -> some View {
        HStack(spacing: 12) {
            GenieAnalogWatchFace(date: date, calendar: city.calendar, size: store.settings.size.clockDialSize, accent: city.accent.color, showSeconds: store.settings.showSeconds)
            
            Text(city.name)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            timeView(city: city, date: date, font: .system(size: 13, weight: .medium, design: .rounded), color: city.accent.color)
            
            offsetBadge(city: city, date: date)
        }
    }
    
    @ViewBuilder
    private func regularContent(city: GenieWorldClockCity, date: Date) -> some View {
        VStack(spacing: 4) {
            HStack {
                Text(city.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                Spacer()
                offsetBadge(city: city, date: date)
            }
            
            HStack {
                GenieAnalogWatchFace(date: date, calendar: city.calendar, size: store.settings.size.clockDialSize, accent: city.accent.color, showSeconds: store.settings.showSeconds)
                Spacer()
                timeView(city: city, date: date, font: .system(size: 28, weight: .light, design: .rounded), color: .white)
            }
        }
        .padding(.vertical, 10)
    }
    
    @ViewBuilder
    private func largeContent(city: GenieWorldClockCity, date: Date) -> some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 6) {
                Spacer()
                GenieAnalogWatchFace(date: date, calendar: city.calendar, size: store.settings.size.clockDialSize, accent: city.accent.color, showSeconds: store.settings.showSeconds)
                
                Text(city.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                
                timeView(city: city, date: date, font: .system(size: 32, weight: .light, design: .rounded), color: .white)
                Spacer()
            }
            .frame(maxWidth: .infinity)
            
            offsetBadge(city: city, date: date)
                .padding(.top, 12)
        }
    }
    
    @ViewBuilder
    private func heroContent(city: GenieWorldClockCity, date: Date) -> some View {
        VStack(spacing: 8) {
            Spacer()
            GenieAnalogWatchFace(date: date, calendar: city.calendar, size: store.settings.size.clockDialSize, accent: city.accent.color, showSeconds: store.settings.showSeconds)
            
            Text(city.name)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.white)
            
            timeView(city: city, date: date, font: .system(size: 44, weight: .thin, design: .rounded), color: .white)
            
            Text(dateString(for: city, date: date))
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.white.opacity(0.6))
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private func timeView(city: GenieWorldClockCity, date: Date, font: Font, color: Color) -> some View {
        HStack(spacing: 4) {
            if city.isNight(at: date) {
                Image(systemName: "moon.fill")
                    .opacity(0.3)
                    .foregroundColor(color)
            } else {
                Image(systemName: "sun.max.fill")
                    .foregroundColor(color)
            }
            
            Text(timeString(for: city, date: date))
                .font(font)
                .foregroundColor(color)
        }
    }
    
    @ViewBuilder
    private func offsetBadge(city: GenieWorldClockCity, date: Date) -> some View {
        Text(city.offsetDescription(at: date))
            .font(.system(size: 10, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Capsule().fill(city.accent.color.opacity(0.15)))
    }
    
    private func timeString(for city: GenieWorldClockCity, date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = city.timeZone
        formatter.calendar = city.calendar
        
        var template = store.settings.use24Hour ? "HHmm" : "hmm"
        if store.settings.showSeconds {
            template += "ss"
        }
        formatter.setLocalizedDateFormatFromTemplate(template)
        return formatter.string(from: date)
    }
    
    private func dateString(for city: GenieWorldClockCity, date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = city.timeZone
        formatter.calendar = city.calendar
        formatter.setLocalizedDateFormatFromTemplate("EEEE MMM d")
        return formatter.string(from: date)
    }
}
