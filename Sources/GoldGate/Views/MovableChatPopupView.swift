import AppKit
import SwiftUI

// MARK: - 🪟 Movable Popup Tool Item Model
public struct MovablePopupItem: Identifiable, Hashable {
    public let id: String
    public let title: String
    public let icon: String
    public let tintColor: Color
    public var offset: CGSize
    public var size: CGSize
    public var isMinimized: Bool

    public init(
        id: String,
        title: String,
        icon: String,
        tintColor: Color,
        offset: CGSize = .zero,
        size: CGSize = CGSize(width: 580, height: 420),
        isMinimized: Bool = false
    ) {
        self.id = id
        self.title = title
        self.icon = icon
        self.tintColor = tintColor
        self.offset = offset
        self.size = size
        self.isMinimized = isMinimized
    }
}

// MARK: - 🕹 Movable Popup Manager
@MainActor
public final class MovablePopupManager: ObservableObject {
    public static let shared = MovablePopupManager()

    @Published public var activePopups: [MovablePopupItem] = []
    @Published public var topPopupId: String? = nil

    private init() {}

    public func openPopup(id: String, title: String, icon: String, tint: Color, initialSize: CGSize = CGSize(width: 580, height: 420)) {
        if let idx = activePopups.firstIndex(where: { $0.id == id }) {
            activePopups[idx].isMinimized = false
            topPopupId = id
            HapticFeedback.playClickSound()
            return
        }

        // Stagger offset for new popup
        let count = activePopups.count
        let staggerOffset = CGSize(width: CGFloat(count * 24), height: CGFloat(count * 20))

        let newPopup = MovablePopupItem(
            id: id,
            title: title,
            icon: icon,
            tintColor: tint,
            offset: staggerOffset,
            size: initialSize
        )
        activePopups.append(newPopup)
        topPopupId = id
        HapticFeedback.heavy()
    }

    public func closePopup(id: String) {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
            activePopups.removeAll(where: { $0.id == id })
            if topPopupId == id {
                topPopupId = activePopups.last?.id
            }
        }
        HapticFeedback.playClickSound()
    }

    public func toggleMinimize(id: String) {
        if let idx = activePopups.firstIndex(where: { $0.id == id }) {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                activePopups[idx].isMinimized.toggle()
            }
        }
    }

    public func bringToFront(id: String) {
        topPopupId = id
    }
}

// MARK: - 🪟 Movable Chat Popup Container View
public struct MovableChatPopupView: View {
    @ObservedObject var popupManager = MovablePopupManager.shared
    @State private var dragOffsets: [String: CGSize] = [:]

    public init() {}

    public var body: some View {
        ZStack {
            ForEach(popupManager.activePopups) { popup in
                singlePopupCard(popup: popup)
                    .zIndex(popupManager.topPopupId == popup.id ? 100 : 10)
            }
        }
    }

    private func singlePopupCard(popup: MovablePopupItem) -> some View {
        let currentDrag = dragOffsets[popup.id] ?? .zero
        let totalOffset = CGSize(
            width: popup.offset.width + currentDrag.width,
            height: popup.offset.height + currentDrag.height
        )

        return VStack(spacing: 0) {
            // ── Draggable Window Title Header ───────────────────────────────
            HStack(spacing: 8) {
                // Window Traffic Lights (Close / Minimize)
                HStack(spacing: 6) {
                    Button(action: {
                        popupManager.closePopup(id: popup.id)
                    }) {
                        Circle()
                            .fill(Color.red.opacity(0.85))
                            .frame(width: 11, height: 11)
                            .overlay(
                                Image(systemName: "xmark")
                                    .font(.system(size: 6, weight: .bold))
                                    .foregroundColor(.black.opacity(0.6))
                            )
                    }
                    .buttonStyle(PlainButtonStyle())

                    Button(action: {
                        popupManager.toggleMinimize(id: popup.id)
                    }) {
                        Circle()
                            .fill(Color.yellow.opacity(0.85))
                            .frame(width: 11, height: 11)
                            .overlay(
                                Image(systemName: "minus")
                                    .font(.system(size: 6, weight: .bold))
                                    .foregroundColor(.black.opacity(0.6))
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                Divider().frame(height: 12).background(Color.white.opacity(0.15))

                // App / Tool Icon & Title
                Image(systemName: popup.icon)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(popup.tintColor)

                Text(popup.title)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.92))

                Spacer()

                Text("Drag to Move ✥")
                    .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.35))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(red: 0.12, green: 0.13, blue: 0.17).opacity(0.95))
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { gesture in
                        dragOffsets[popup.id] = gesture.translation
                        popupManager.bringToFront(id: popup.id)
                    }
                    .onEnded { gesture in
                        if let idx = popupManager.activePopups.firstIndex(where: { $0.id == popup.id }) {
                            popupManager.activePopups[idx].offset.width += gesture.translation.width
                            popupManager.activePopups[idx].offset.height += gesture.translation.height
                        }
                        dragOffsets[popup.id] = .zero
                    }
            )

            Divider().background(Color.white.opacity(0.12))

            // ── Body Content View ───────────────────────────────────────────
            if !popup.isMinimized {
                popupContentView(for: popup.id)
                    .frame(width: popup.size.width, height: popup.size.height)
            }
        }
        .frame(width: popup.size.width)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(red: 0.10, green: 0.11, blue: 0.14).opacity(0.96))
                .shadow(color: Color.black.opacity(0.6), radius: 24, x: 0, y: 12)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [popup.tintColor.opacity(0.6), Color.white.opacity(0.12)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .offset(totalOffset)
        .onTapGesture {
            popupManager.bringToFront(id: popup.id)
        }
    }

    @ViewBuilder
    private func popupContentView(for id: String) -> some View {
        switch id {
        case "vscode":
            EmbeddedVSCodeStudioView()
        case "browser":
            MiniWebBrowserCanvasView()
        case "terminal":
            GeniePremiumTerminalCookbookView()
        case "mac_trainer":
            MacSystemSettingsKnowledgeTrainerView()
        case "spaces":
            SpacesPhotoshopLayerStackView()
        case "huggingface":
            GenieHuggingFaceStudioView()
        case "evolver":
            GenieCodebaseEvolutionStudioView()
        case "github":
            GitHubDesktopCanvasView()
        case "chat_settings":
            GenieChatSettingsCardView()
        case "matrix3x3", "scaled_programs":
            ScaledProgramMatrixView()
        default:
            VStack {
                Text("Tool Window")
                    .foregroundColor(.secondary)
            }
        }
    }
}
