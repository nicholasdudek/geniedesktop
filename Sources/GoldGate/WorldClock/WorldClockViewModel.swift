import SwiftUI
import Combine

public class WorldClockViewModel: ObservableObject {
    /// Single shared instance used by the Genie settings pane and the floating Mini Watch Dock panel.
    public static let shared = WorldClockViewModel()

    @Published public var pillows: [PillowClock] = [] {
        didSet {
            savePillows()
        }
    }
    
    @Published public var currentDate: Date = Date()
    @Published public var localTimeZone: TimeZone = .current
    @Published public var isEditing: Bool = false
    @Published public var isTimeTravelActive: Bool = false
    @Published public var timeTravelOffsetHours: Double = 0.0 // -12 to +12 or 0 to 24
    @Published public var globalSize: PillowSize = .regular

    // Mini Watch Dock (configured in Settings)
    @Published public var dockSettings: MiniWatchDockSettings = .default {
        didSet {
            saveDockSettings()
        }
    }

    // Sheets
    @Published public var showingAddSheet: Bool = false
    @Published public var editingPillow: PillowClock? = nil
    @Published public var showingTimeTravelSheet: Bool = false
    @Published public var showingSettingsSheet: Bool = false

    private var timerSubscription: AnyCancellable?
    private let userDefaultsKey = "SavedWorldClockPillows_v2"
    private let dockSettingsKey = "MiniWatchDockSettings_v1"

    public init() {
        loadPillows()
        loadDockSettings()
        startClockTimer()
    }
    
    public var effectiveDate: Date {
        if isTimeTravelActive {
            return currentDate.addingTimeInterval(timeTravelOffsetHours * 3600.0)
        }
        return currentDate
    }
    
    public func startClockTimer() {
        timerSubscription = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] newDate in
                guard let self = self else { return }
                self.currentDate = newDate
            }
    }
    
    public func addPillow(from city: City) {
        let newPillow = PillowClock(
            cityName: city.name,
            countryOrRegion: city.countryOrRegion,
            timeZoneIdentifier: city.timeZoneIdentifier,
            size: globalSize,
            accent: .classicOrange,
            showAnalogDial: true,
            showSeconds: false,
            showDayNightIndicator: true
        )
        pillows.append(newPillow)
    }
    
    public func removePillow(id: UUID) {
        pillows.removeAll { $0.id == id }
    }
    
    public func removePillows(at offsets: IndexSet) {
        pillows.remove(atOffsets: offsets)
    }
    
    public func movePillows(from source: IndexSet, to destination: Int) {
        pillows.move(fromOffsets: source, toOffset: destination)
    }
    
    public func updatePillow(_ updated: PillowClock) {
        if let idx = pillows.firstIndex(where: { $0.id == updated.id }) {
            pillows[idx] = updated
        }
    }
    
    public func setSizeForPillow(id: UUID, size: PillowSize) {
        if let idx = pillows.firstIndex(where: { $0.id == id }) {
            pillows[idx].size = size
        }
    }
    
    public func setAllSizes(to size: PillowSize) {
        globalSize = size
        for i in 0..<pillows.count {
            pillows[i].size = size
        }
    }
    
    public func resetToDefaults() {
        pillows = CityDatabase.defaultPillows
    }
    
    private func savePillows() {
        if let encoded = try? JSONEncoder().encode(pillows) {
            UserDefaults.standard.set(encoded, forKey: userDefaultsKey)
        }
    }
    
    private func loadPillows() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let decoded = try? JSONDecoder().decode([PillowClock].self, from: data),
           !decoded.isEmpty {
            self.pillows = decoded
        } else {
            self.pillows = CityDatabase.defaultPillows
        }
    }

    private func saveDockSettings() {
        if let encoded = try? JSONEncoder().encode(dockSettings) {
            UserDefaults.standard.set(encoded, forKey: dockSettingsKey)
        }
    }

    private func loadDockSettings() {
        if let data = UserDefaults.standard.data(forKey: dockSettingsKey),
           let decoded = try? JSONDecoder().decode(MiniWatchDockSettings.self, from: data) {
            self.dockSettings = decoded
        }
    }
}
