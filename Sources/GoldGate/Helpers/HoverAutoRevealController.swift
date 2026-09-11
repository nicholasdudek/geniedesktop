import SwiftUI

/// Drives a hover-to-reveal drawer with seamless click-to-pin support:
/// - Hovering reveals the drawer dynamically and auto-retracts on mouse exit.
/// - Clicking the sidebar button or double-clicking the drawer header pins it in place
///   without requiring an intrusive pin icon.
/// - When pinned, mouse exit and canvas interactions do not dismiss the sidebar.
@MainActor
public final class HoverAutoRevealController: ObservableObject {
    @Published public private(set) var isOpen: Bool = false
    @Published public var isPinned: Bool = false

    private var closeTask: Task<Void, Never>?
    private let closeDelay: Duration

    public init(closeDelay: Duration = .milliseconds(350)) {
        self.closeDelay = closeDelay
    }

    public func hoverEnter() {
        closeTask?.cancel()
        isOpen = true
    }

    public func hoverExit() {
        guard !isPinned else { return }
        closeTask?.cancel()
        closeTask = Task { [closeDelay] in
            try? await Task.sleep(for: closeDelay)
            guard !Task.isCancelled, !self.isPinned else { return }
            self.isOpen = false
        }
    }

    public func open(pin: Bool = false) {
        closeTask?.cancel()
        if pin { isPinned = true }
        isOpen = true
    }

    public func close(force: Bool = false) {
        if force { isPinned = false }
        guard !isPinned else { return }
        closeTask?.cancel()
        isOpen = false
    }

    public func toggle() {
        if isPinned {
            isPinned = false
            close(force: true)
        } else {
            isPinned = true
            open(pin: true)
        }
    }

    public func togglePin() {
        isPinned.toggle()
        if isPinned {
            isOpen = true
            closeTask?.cancel()
        }
    }
}
