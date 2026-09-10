import AppKit
import SwiftUI

// MARK: - 🔊 Master Volume Popover Manager Singleton (Consolidated)
@MainActor
public final class MasterVolumePopoverManager: GenericFloatingGlassPanelManager<MasterVolumePopoverView> {
    public static let shared = MasterVolumePopoverManager()

    private init() {
        super.init(panelSize: CGSize(width: 336, height: 380), levelOffset: 5) {
            MasterVolumePopoverView()
        }
    }
}
