import AppKit
import SwiftUI
import Combine

// MARK: - ⌚️ Floating Mini Watch Dock Panel
// The Mini Watch Dock is not crammed into the 22pt menu bar. It lives in its own borderless,
// non-activating floating panel that snaps just beneath the menu bar (or just above the Dock)
// and can be dragged anywhere. Its last position is remembered across launches.
@MainActor
public final class MiniWatchDockPanelManager: NSObject, NSWindowDelegate {
    public static let shared = MiniWatchDockPanelManager()

    private var panel: NSPanel?
    private var hosting: NSHostingView<MiniWatchDockFloatingContent>?
    private var cancellables = Set<AnyCancellable>()
    private let originKey = "GenieMiniWatchDockOrigin_v1"
    private let hasCustomOriginKey = "GenieMiniWatchDockHasCustomOrigin_v1"

    private var clockVM: WorldClockViewModel { WorldClockViewModel.shared }

    // MARK: Lifecycle
    public func setup() {
        // Rebuild whenever settings or the pillow list change.
        clockVM.$dockSettings
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.refresh() }
            .store(in: &cancellables)

        clockVM.$pillows
            .map { $0.count }
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.refresh() }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.refresh() }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: NSNotification.Name("NexusCustomMenuBarToggled"))
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.refresh() }
            .store(in: &cancellables)

        refresh()
    }

    public func refresh() {
        guard clockVM.dockSettings.isEnabled else {
            hide()
            return
        }
        show()
    }

    private func show() {
        if panel == nil { buildPanel() }
        guard let panel else { return }
        hosting?.rootView = MiniWatchDockFloatingContent()
        let size = preferredSize()
        panel.setContentSize(size)
        panel.setFrameOrigin(resolvedOrigin(for: size))
        if !panel.isVisible {
            panel.alphaValue = 0
            panel.orderFrontRegardless()
            NSAnimationContext.runAnimationGroup { ctx in
                ctx.duration = 0.25
                panel.animator().alphaValue = 1
            }
        }
    }

    public func hide() {
        guard let panel, panel.isVisible else { return }
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.18
            panel.animator().alphaValue = 0
        }, completionHandler: {
            panel.orderOut(nil)
        })
    }

    private func buildPanel() {
        let p = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 320, height: 90),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        p.isOpaque = false
        p.backgroundColor = .clear
        p.hasShadow = false // the SwiftUI card draws its own shadow
        p.level = .floating
        p.isMovable = true
        p.isMovableByWindowBackground = true
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        p.hidesOnDeactivate = false
        p.isReleasedWhenClosed = false
        p.isExcludedFromWindowsMenu = true
        p.delegate = self

        let host = NSHostingView(rootView: MiniWatchDockFloatingContent())
        host.autoresizingMask = [.width, .height]
        p.contentView = host

        panel = p
        hosting = host
    }

    // MARK: Geometry
    /// Menu-bar format: a fixed 24pt-tall floating strip, regardless of the dock's watch-size setting.
    public static let menuBarStripHeight: CGFloat = 24
    public static let menuBarStripDial: CGFloat = 16

    private func preferredSize() -> NSSize {
        let s = clockVM.dockSettings
        if s.position == .top {
            // Fixed menu-bar strip: [grip][dial + "City 9:41"] per item, always the same height.
            let items = clockVM.pillows.count + (s.showLocalTime ? 1 : 0)
            let itemW: CGFloat = Self.menuBarStripDial + 6 + (s.showCityLabels ? 60 : 0) + (s.showDigitalTime ? 44 : 0) + 10
            let w = 26 + CGFloat(items) * itemW + CGFloat(max(items - 1, 0)) * 8 + 24
            let maxW = (NSScreen.main?.visibleFrame.width ?? 1440) * 0.9
            return NSSize(width: min(w, maxW), height: Self.menuBarStripHeight + 8)
        }
        let d = s.dialSize.diameter
        let itemW = max(d + 16, 52)
        let spacing: CGFloat = s.dialSize == .small ? 14 : 18
        let items = clockVM.pillows.count + (s.showLocalTime ? 1 : 0)
        let dividers: CGFloat = (s.showLocalTime && !clockVM.pillows.isEmpty) ? (1 + spacing) : 0
        let gripW: CGFloat = 26
        let contentW = CGFloat(items) * itemW + CGFloat(max(items - 1, 0)) * spacing + dividers + 36 + gripW
        let maxW = (NSScreen.main?.visibleFrame.width ?? 1440) * 0.85
        var h = d + 20 + 12 // dial + vertical padding + outer padding
        if s.showCityLabels { h += 16 }
        if s.showDigitalTime { h += 16 }
        return NSSize(width: min(contentW + 32, maxW), height: h + 12)
    }

    private func resolvedOrigin(for size: NSSize) -> NSPoint {
        let screen = NSScreen.main ?? NSScreen.screens.first
        let vf = screen?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)

        if UserDefaults.standard.bool(forKey: hasCustomOriginKey),
           let dict = UserDefaults.standard.dictionary(forKey: originKey),
           let x = dict["x"] as? CGFloat, let y = dict["y"] as? CGFloat {
            // Keep it on screen after display changes.
            let clampedX = min(max(x, vf.minX), vf.maxX - size.width)
            let clampedY = min(max(y, vf.minY), vf.maxY - size.height)
            return NSPoint(x: clampedX, y: clampedY)
        }
        return snapOrigin(for: clockVM.dockSettings.position, size: size, visibleFrame: vf)
    }

    private func snapOrigin(for position: MiniWatchDockPosition, size: NSSize, visibleFrame vf: NSRect) -> NSPoint {
        let x = vf.midX - size.width / 2
        switch position {
        case .top:
            // Just beneath the menu bar (visibleFrame already excludes the menu bar).
            // When Genie's own custom menu bar is on, sit beneath that bar instead of under it.
            var clearance: CGFloat = 6
            if CustomMenuBarManager.shared.isEnabled, let screen = NSScreen.main {
                clearance += CustomMenuBarWindow.metrics(for: screen).windowHeight - (screen.frame.maxY - vf.maxY)
                clearance = max(clearance, 6)
            }
            return NSPoint(x: x, y: vf.maxY - size.height - clearance)
        case .bottom:
            // Just above the Dock.
            return NSPoint(x: x, y: vf.minY + 6)
        }
    }

    /// Forget any dragged position and snap back to the configured edge.
    public func snapToConfiguredEdge() {
        UserDefaults.standard.set(false, forKey: hasCustomOriginKey)
        UserDefaults.standard.removeObject(forKey: originKey)
        refresh()
    }

    /// Move the panel by a drag delta (called from the grip handle).
    public func move(by delta: CGSize) {
        guard let panel else { return }
        var origin = panel.frame.origin
        origin.x += delta.width
        origin.y -= delta.height // SwiftUI y grows downward, AppKit upward
        panel.setFrameOrigin(origin)
    }

    public func commitPosition() {
        guard let panel else { return }
        let o = panel.frame.origin
        UserDefaults.standard.set(["x": o.x, "y": o.y], forKey: originKey)
        UserDefaults.standard.set(true, forKey: hasCustomOriginKey)
    }

    // MARK: NSWindowDelegate
    public func windowDidMove(_ notification: Notification) {
        commitPosition()
    }
}

// MARK: - Floating content: grip handle + the shared MiniWatchDockView
public struct MiniWatchDockFloatingContent: View {
    @ObservedObject private var vm = WorldClockViewModel.shared
    @State private var isDragging = false

    public init() {}

    public var body: some View {
        HStack(spacing: 0) {
            // Grip: drag here to move the dock anywhere on screen.
            VStack(spacing: 3) {
                ForEach(0..<3, id: \.self) { _ in
                    Capsule().fill(Color.white.opacity(isDragging ? 0.9 : 0.35)).frame(width: 14, height: 2)
                }
            }
            .frame(width: 26)
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 1, coordinateSpace: .global)
                    .onChanged { value in
                        isDragging = true
                        MiniWatchDockPanelManager.shared.move(by: CGSize(
                            width: value.translation.width - lastTranslation.width,
                            height: value.translation.height - lastTranslation.height
                        ))
                        lastTranslation = value.translation
                    }
                    .onEnded { _ in
                        isDragging = false
                        lastTranslation = .zero
                        MiniWatchDockPanelManager.shared.commitPosition()
                    }
            )
            .help("Drag to move the Mini Watch Dock")

            if vm.dockSettings.position == .top {
                MiniWatchDockMenuBarStrip(
                    pillows: vm.pillows,
                    date: vm.effectiveDate,
                    localTimeZone: vm.localTimeZone,
                    settings: vm.dockSettings,
                    onSelectPillow: openPillow
                )
            } else {
                MiniWatchDockView(
                    pillows: vm.pillows,
                    date: vm.effectiveDate,
                    localTimeZone: vm.localTimeZone,
                    settings: vm.dockSettings,
                    onSelectPillow: openPillow
                )
                .padding(.leading, -12)
            }
        }
        .padding(.leading, 6)
        .contextMenu {
            Button("Snap Below Menu Bar") {
                vm.dockSettings.position = .top
                MiniWatchDockPanelManager.shared.snapToConfiguredEdge()
            }
            Button("Snap Above Dock") {
                vm.dockSettings.position = .bottom
                MiniWatchDockPanelManager.shared.snapToConfiguredEdge()
            }
            Divider()
            Button("Hide Mini Watch Dock") { vm.dockSettings.isEnabled = false }
        }
    }

    @State private var lastTranslation: CGSize = .zero

    private func openPillow(_ pillow: PillowClock) {
        vm.editingPillow = pillow
        NotificationCenter.default.post(name: NSNotification.Name("NexusSelectSettingsTab"), object: UnifiedSettingsTab.worldClock)
    }
}

// MARK: - Menu-bar-format strip (top position): always 24pt tall, floating, glass like the real menu bar
public struct MiniWatchDockMenuBarStrip: View {
    public let pillows: [PillowClock]
    public let date: Date
    public let localTimeZone: TimeZone
    public let settings: MiniWatchDockSettings
    public let onSelectPillow: (PillowClock) -> Void

    private let dial = MiniWatchDockPanelManager.menuBarStripDial

    public var body: some View {
        HStack(spacing: 8) {
            if settings.showLocalTime {
                stripItem(timeZone: localTimeZone, accent: Color(red: 1.0, green: 0.58, blue: 0.0), label: "Local", digital: digitalString(localTimeZone))
                if !pillows.isEmpty {
                    Rectangle().fill(Color.primary.opacity(0.18)).frame(width: 1, height: 12)
                }
            }
            ForEach(pillows) { pillow in
                Button { onSelectPillow(pillow) } label: {
                    stripItem(timeZone: pillow.timeZone, accent: pillow.accent.color, label: pillow.displayName, digital: pillow.formattedDigitalTime(for: date))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .frame(height: MiniWatchDockPanelManager.menuBarStripHeight)
        .background(
            ZStack {
                VisualEffectBlur(material: .menu, blendingMode: .behindWindow, state: .active)
                Color.black.opacity(0.10)
            }
            .clipShape(Capsule())
        )
        .overlay(Capsule().strokeBorder(Color.white.opacity(0.14), lineWidth: 0.5))
        .shadow(color: Color.black.opacity(0.35), radius: 8, y: 3)
        .padding(4)
    }

    private func stripItem(timeZone: TimeZone, accent: Color, label: String, digital: String) -> some View {
        HStack(spacing: 5) {
            AnalogClockView(timeZone: timeZone, date: date, accentColor: accent, size: dial, showSeconds: false)
            if settings.showCityLabels {
                Text(label)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary.opacity(0.9))
                    .lineLimit(1)
                    .frame(maxWidth: 60, alignment: .leading)
            }
            if settings.showDigitalTime {
                Text(digital)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .monospacedDigit()
                    .foregroundColor(accent)
                    .frame(width: 42, alignment: .leading)
            }
        }
    }

    private func digitalString(_ tz: TimeZone) -> String {
        let f = DateFormatter()
        f.timeZone = tz
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "h:mm"
        return f.string(from: date)
    }
}
