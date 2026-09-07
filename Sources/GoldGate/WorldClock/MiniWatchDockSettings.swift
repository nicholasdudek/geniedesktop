import SwiftUI
import Foundation

/// Where the Mini Watch Dock is pinned on the main screen.
public enum MiniWatchDockPosition: String, CaseIterable, Codable, Identifiable {
    case top = "Top"
    case bottom = "Bottom"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .top: return "rectangle.topthird.inset.filled"
        case .bottom: return "rectangle.bottomthird.inset.filled"
        }
    }
}

/// Diameter presets for the mini watch faces in the dock.
public enum MiniWatchDockDialSize: String, CaseIterable, Codable, Identifiable {
    case small = "Small"
    case medium = "Medium"
    case large = "Large"
    
    public var id: String { rawValue }
    
    public var diameter: CGFloat {
        switch self {
        case .small: return 36
        case .medium: return 48
        case .large: return 60
        }
    }
    
    public var icon: String {
        switch self {
        case .small: return "circle"
        case .medium: return "circle.circle"
        case .large: return "circle.circle.fill"
        }
    }
}

/// User preferences for the Mini Watch Dock, edited from the Settings menu.
public struct MiniWatchDockSettings: Codable, Equatable {
    public var isEnabled: Bool
    public var position: MiniWatchDockPosition
    public var dialSize: MiniWatchDockDialSize
    public var showSeconds: Bool
    public var showCityLabels: Bool
    public var showDigitalTime: Bool
    public var showLocalTime: Bool
    
    public init(
        isEnabled: Bool = false,
        position: MiniWatchDockPosition = .bottom,
        dialSize: MiniWatchDockDialSize = .medium,
        showSeconds: Bool = false,
        showCityLabels: Bool = true,
        showDigitalTime: Bool = false,
        showLocalTime: Bool = true
    ) {
        self.isEnabled = isEnabled
        self.position = position
        self.dialSize = dialSize
        self.showSeconds = showSeconds
        self.showCityLabels = showCityLabels
        self.showDigitalTime = showDigitalTime
        self.showLocalTime = showLocalTime
    }
    
    public static let `default` = MiniWatchDockSettings()
}
