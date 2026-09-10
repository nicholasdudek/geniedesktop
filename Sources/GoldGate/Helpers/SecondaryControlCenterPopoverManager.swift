import AppKit
import SwiftUI

// MARK: - 🎛️ Secondary Control Center Popover Manager Singleton (Consolidated)
@MainActor
public final class SecondaryControlCenterPopoverManager: GenericFloatingGlassPanelManager<SecondaryControlCenterPopoverView> {
    public static let shared = SecondaryControlCenterPopoverManager()

    private init() {
        super.init(panelSize: CGSize(width: 336, height: 490), levelOffset: 6) {
            SecondaryControlCenterPopoverView()
        }
    }
}
