import SwiftUI
import AppKit

// MARK: - 🌍 World Clock & Alarms Pane (hosted inside UnifiedSettingsView)
/// Brings the World Clock Pillows experience into Genie: a pinned Mini Watch Dock,
/// the city pillow stack, the best-time-to-call planner, and a macOS alarm clock.
public struct GenieWorldClockAlarmPane: View {
    @ObservedObject private var clockVM = WorldClockViewModel.shared
    @ObservedObject private var alarms = AlarmClockManager.shared

    @State private var editingAlarm: AlarmClock? = nil
    @State private var showingAddAlarm: Bool = false

    private let orange = Color(red: 1.0, green: 0.58, blue: 0.0)

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if let ringing = alarms.ringingAlarm {
                ringingBanner(ringing)
            }

            // 1. Mini Watch Dock
            glassCard(title: "Mini Watch Dock", icon: "watchface.applewatch.case", tint: orange) {
                VStack(spacing: 10) {
                    toggleRow("Show Watch Strip in Chat", subtitle: "A row of tiny watch faces, one per city, pinned under the header of the Genie chat dock. Tap any watch to open that city here.", isOn: $clockVM.dockSettings.isEnabled)

                    if clockVM.dockSettings.isEnabled {
                        MiniWatchDockView(
                            pillows: clockVM.pillows,
                            date: clockVM.effectiveDate,
                            localTimeZone: clockVM.localTimeZone,
                            settings: clockVM.dockSettings,
                            onSelectPillow: { clockVM.editingPillow = $0 }
                        )
                        .padding(.horizontal, -16)

                        Divider().opacity(0.2)

                        HStack {
                            Text("Watch Size").font(.system(size: 12, weight: .medium)).foregroundColor(.white)
                            Spacer()
                            Picker("", selection: $clockVM.dockSettings.dialSize) {
                                ForEach(MiniWatchDockDialSize.allCases) { Text($0.rawValue).tag($0) }
                            }
                            .pickerStyle(.segmented)
                            .frame(width: 220)
                        }

                        toggleRow("Show Local Time First", isOn: $clockVM.dockSettings.showLocalTime)
                        toggleRow("Show City Labels", isOn: $clockVM.dockSettings.showCityLabels)
                        toggleRow("Show Digital Time", isOn: $clockVM.dockSettings.showDigitalTime)
                        toggleRow("Sweeping Seconds Hand", isOn: $clockVM.dockSettings.showSeconds)
                    }
                }
            }

            // 2. World Clock Pillows
            glassCard(title: "World Clock Pillows", icon: "globe.desk.fill", tint: .cyan) {
                VStack(spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("LOCAL TIME (\(clockVM.localTimeZone.abbreviation() ?? "GMT"))")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(orange)
                            Text(clockVM.effectiveDate, format: .dateTime.hour().minute().second())
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundColor(.white)
                        }
                        Spacer()
                        Picker("", selection: Binding(
                            get: { clockVM.globalSize },
                            set: { clockVM.setAllSizes(to: $0) }
                        )) {
                            ForEach(PillowSize.allCases) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 260)
                    }

                    if clockVM.pillows.isEmpty {
                        Button("Restore 5 Default World Cities") { clockVM.resetToDefaults() }
                            .buttonStyle(.plain)
                            .foregroundColor(orange)
                            .padding(.vertical, 8)
                    } else {
                        VStack(spacing: 10) {
                            ForEach(clockVM.pillows) { pillow in
                                PillowCardView(
                                    pillow: pillow,
                                    date: clockVM.effectiveDate,
                                    localTimeZone: clockVM.localTimeZone,
                                    isEditing: clockVM.isEditing,
                                    onSizeToggle: { clockVM.setSizeForPillow(id: pillow.id, size: $0) },
                                    onEdit: { clockVM.editingPillow = pillow },
                                    onDelete: { withAnimation { clockVM.removePillow(id: pillow.id) } }
                                )
                                .onTapGesture { if !clockVM.isEditing { clockVM.editingPillow = pillow } }
                            }
                        }
                    }

                    HStack(spacing: 10) {
                        pillButton("Add City", icon: "plus.circle.fill", tint: orange) { clockVM.showingAddSheet = true }
                        pillButton("Best Time to Call", icon: "phone.badge.waveform", tint: .green) { clockVM.showingTimeTravelSheet = true }
                        pillButton(clockVM.isEditing ? "Done" : "Edit", icon: "slider.horizontal.3", tint: .white.opacity(0.8)) {
                            withAnimation(.spring()) { clockVM.isEditing.toggle() }
                        }
                        Spacer()
                    }
                }
            }

            // 3. Alarm Clock
            glassCard(title: "Alarm Clock", icon: "alarm.fill", tint: .red) {
                VStack(spacing: 10) {
                    HStack {
                        if let next = alarms.nextAlarm {
                            Label {
                                Text("Next: \(next.alarm.label.isEmpty ? "Alarm" : next.alarm.label) · \(next.alarm.formattedTime) \(next.alarm.countdownDescription(from: alarms.now))")
                            } icon: {
                                Image(systemName: "bell.badge.fill").foregroundColor(.red)
                            }
                            .font(.system(size: 11.5, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.85))
                        } else {
                            Text("No alarms scheduled")
                                .font(.system(size: 11.5, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.55))
                        }
                        Spacer()
                        pillButton("New Alarm", icon: "plus.circle.fill", tint: .red) { showingAddAlarm = true }
                    }

                    if !alarms.alarms.isEmpty {
                        Divider().opacity(0.2)
                        VStack(spacing: 6) {
                            ForEach(alarms.alarms) { alarm in
                                alarmRow(alarm)
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $clockVM.showingAddSheet) { CityPickerSheet(viewModel: clockVM).frame(minWidth: 460, minHeight: 520) }
        .sheet(item: $clockVM.editingPillow) { PillowEditSheet(viewModel: clockVM, pillow: $0).frame(minWidth: 480, minHeight: 620) }
        .sheet(isPresented: $clockVM.showingTimeTravelSheet) { TimeTravelScrubberView(viewModel: clockVM).frame(minWidth: 520, minHeight: 640) }
        .sheet(isPresented: $showingAddAlarm) { AlarmEditorSheet(alarm: AlarmClock(), isNew: true, cities: clockVM.pillows) }
        .sheet(item: $editingAlarm) { AlarmEditorSheet(alarm: $0, isNew: false, cities: clockVM.pillows) }
    }

    // MARK: - Alarm Row
    private func alarmRow(_ alarm: AlarmClock) -> some View {
        HStack(spacing: 12) {
            AnalogClockView(
                timeZone: alarm.timeZone,
                date: alarmFaceDate(alarm),
                accentColor: alarm.isEnabled ? .red : .gray,
                size: 34,
                showSeconds: false
            )

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(alarm.formattedTime)
                        .font(.system(size: 20, weight: .light, design: .rounded))
                        .monospacedDigit()
                        .foregroundColor(alarm.isEnabled ? .white : .white.opacity(0.45))
                    if let tz = alarm.timeZoneIdentifier {
                        Text(tz.split(separator: "/").last.map(String.init)?.replacingOccurrences(of: "_", with: " ") ?? tz)
                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                            .foregroundColor(.cyan.opacity(0.8))
                    }
                }
                Text("\(alarm.label.isEmpty ? "Alarm" : alarm.label) · \(alarm.repeatDescription)" + (alarm.snoozeUntil != nil ? " · Snoozed" : ""))
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.55))
            }

            Spacer()

            Text(alarm.countdownDescription(from: alarms.now))
                .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
                .foregroundColor(alarm.isEnabled ? .red.opacity(0.9) : .white.opacity(0.3))

            Toggle("", isOn: Binding(
                get: { alarm.isEnabled },
                set: { alarms.setEnabled(id: alarm.id, $0) }
            ))
            .labelsHidden()
            .toggleStyle(.switch)
            .tint(.red)

            Button { editingAlarm = alarm } label: {
                Image(systemName: "slider.horizontal.3").foregroundColor(.white.opacity(0.7))
            }
            .buttonStyle(.plain)

            Button { withAnimation { alarms.remove(id: alarm.id) } } label: {
                Image(systemName: "trash").foregroundColor(.red.opacity(0.8))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(alarm.isEnabled ? 0.06 : 0.03))
        )
    }

    /// A date whose wall-clock time in the alarm's zone equals the alarm time, so the mini face shows the alarm.
    private func alarmFaceDate(_ alarm: AlarmClock) -> Date {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = alarm.timeZone
        return cal.date(bySettingHour: alarm.hour, minute: alarm.minute, second: 0, of: Date()) ?? Date()
    }

    // MARK: - Ringing Banner
    private func ringingBanner(_ alarm: AlarmClock) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "alarm.waves.left.and.right.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
                .symbolEffect(.pulse)
            VStack(alignment: .leading, spacing: 2) {
                Text(alarm.label.isEmpty ? "Alarm" : alarm.label)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("\(alarm.formattedTime) · \(alarm.repeatDescription)")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.85))
            }
            Spacer()
            Button("Snooze 9m") { alarms.snooze(minutes: 9) }
                .buttonStyle(.bordered)
                .tint(.white)
            Button("Stop") { alarms.stopRinging() }
                .buttonStyle(.borderedProminent)
                .tint(.white)
                .foregroundColor(.red)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(LinearGradient(colors: [Color.red, Color(red: 0.8, green: 0.1, blue: 0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                .shadow(color: .red.opacity(0.5), radius: 12, y: 4)
        )
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Small UI helpers
    private func toggleRow(_ title: String, subtitle: String? = nil, isOn: Binding<Bool>) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.system(size: 12, weight: .medium)).foregroundColor(.white)
                if let subtitle {
                    Text(subtitle).font(.system(size: 10)).foregroundColor(.white.opacity(0.55))
                }
            }
            Spacer()
            Toggle("", isOn: isOn.animation(.spring(response: 0.3, dampingFraction: 0.8)))
                .labelsHidden()
                .toggleStyle(.switch)
                .tint(orange)
        }
    }

    private func pillButton(_ title: String, icon: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 11, weight: .bold))
                Text(title).font(.system(size: 11.5, weight: .semibold, design: .rounded))
            }
            .foregroundColor(tint)
            .padding(.horizontal, 11)
            .padding(.vertical, 6)
            .background(Capsule().fill(tint.opacity(0.14)).overlay(Capsule().stroke(tint.opacity(0.3), lineWidth: 0.8)))
        }
        .buttonStyle(.plain)
    }

    private func glassCard<Content: View>(title: String, icon: String, tint: Color, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: icon).font(.system(size: 10.5, weight: .semibold)).foregroundColor(tint)
                Text(title.uppercased()).font(.system(size: 10, weight: .semibold)).tracking(0.5).foregroundColor(.secondary)
            }
            .padding(.leading, 4)

            VStack(spacing: 0) { content() }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(
                    ZStack {
                        VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow, state: .active)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        Color.black.opacity(0.35)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                )
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).strokeBorder(Color.white.opacity(0.10), lineWidth: 0.5))
        }
    }
}

// MARK: - ⏰ Alarm Editor Sheet
public struct AlarmEditorSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var manager = AlarmClockManager.shared
    @State private var alarm: AlarmClock
    @State private var time: Date
    let isNew: Bool
    let cities: [PillowClock]

    public init(alarm: AlarmClock, isNew: Bool, cities: [PillowClock]) {
        self._alarm = State(initialValue: alarm)
        self.isNew = isNew
        self.cities = cities
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = alarm.timeZone
        self._time = State(initialValue: cal.date(bySettingHour: alarm.hour, minute: alarm.minute, second: 0, of: Date()) ?? Date())
    }

    private let weekdaySymbols = Calendar(identifier: .gregorian).veryShortWeekdaySymbols

    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(isNew ? "New Alarm" : "Edit Alarm")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                Spacer()
                Button("Cancel") { dismiss() }.buttonStyle(.plain).foregroundColor(.gray)
                Button("Save") {
                    syncTimeIntoAlarm()
                    if isNew { manager.add(alarm) } else { manager.update(alarm) }
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
            }
            .padding(16)

            Divider().opacity(0.2)

            Form {
                Section {
                    HStack {
                        AnalogClockView(timeZone: alarm.timeZone, date: time, accentColor: .red, size: 88, showSeconds: false)
                        Spacer()
                        DatePicker("", selection: $time, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.stepperField)
                            .labelsHidden()
                            .environment(\.timeZone, alarm.timeZone)
                            .font(.system(size: 28, weight: .light, design: .rounded))
                    }
                    .padding(.vertical, 4)

                    TextField("Label (e.g. Stand-up with Tokyo)", text: $alarm.label)
                }

                Section("Repeat") {
                    HStack(spacing: 6) {
                        ForEach(1...7, id: \.self) { day in
                            let on = alarm.repeatWeekdays.contains(day)
                            Button {
                                if on { alarm.repeatWeekdays.remove(day) } else { alarm.repeatWeekdays.insert(day) }
                            } label: {
                                Text(weekdaySymbols[day - 1])
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .frame(width: 30, height: 30)
                                    .background(Circle().fill(on ? Color.red : Color.white.opacity(0.08)))
                                    .foregroundColor(on ? .white : .white.opacity(0.7))
                            }
                            .buttonStyle(.plain)
                        }
                        Spacer()
                        Text(alarm.repeatDescription).font(.system(size: 11, design: .rounded)).foregroundColor(.secondary)
                    }
                }

                Section("Time Zone") {
                    Picker("Ring at this time in", selection: $alarm.timeZoneIdentifier) {
                        Text("My Mac (\(TimeZone.current.abbreviation() ?? "Local"))").tag(String?.none)
                        ForEach(cities) { city in
                            Text("\(city.displayName) (\(city.timeZoneAbbreviation()))").tag(String?.some(city.timeZoneIdentifier))
                        }
                    }
                    .onChange(of: alarm.timeZoneIdentifier) { _, _ in
                        // Keep the same wall-clock hour/minute when the zone changes.
                        var cal = Calendar(identifier: .gregorian)
                        cal.timeZone = alarm.timeZone
                        time = cal.date(bySettingHour: alarm.hour, minute: alarm.minute, second: 0, of: Date()) ?? time
                    }
                }

                Section("Sound") {
                    HStack {
                        Picker("Sound", selection: $alarm.sound) {
                            ForEach(AlarmSound.allCases) { Text($0.rawValue).tag($0) }
                        }
                        Button { manager.preview(alarm.sound) } label: {
                            Image(systemName: "play.circle.fill").font(.system(size: 18)).foregroundColor(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }

                if !isNew {
                    Section {
                        Button(role: .destructive) {
                            manager.remove(id: alarm.id)
                            dismiss()
                        } label: {
                            Label("Delete Alarm", systemImage: "trash.fill").foregroundColor(.red)
                        }
                    }
                }
            }
            .formStyle(.grouped)
            .onChange(of: time) { _, _ in syncTimeIntoAlarm() }
        }
        .frame(minWidth: 440, minHeight: 520)
        .preferredColorScheme(.dark)
    }

    private func syncTimeIntoAlarm() {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = alarm.timeZone
        alarm.hour = cal.component(.hour, from: time)
        alarm.minute = cal.component(.minute, from: time)
    }
}
