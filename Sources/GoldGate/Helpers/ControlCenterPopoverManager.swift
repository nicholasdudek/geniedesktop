import AppKit
import SwiftUI

// MARK: - 🎛️ Control Center Popover Manager Singleton (Consolidated)
@MainActor
public final class ControlCenterPopoverManager: GenericFloatingGlassPanelManager<AppleControlCenterPopoverView> {
    public static let shared = ControlCenterPopoverManager()

    private init() {
        super.init(panelSize: CGSize(width: 336, height: 490), levelOffset: 5) {
            AppleControlCenterPopoverView()
        }
    }
}
