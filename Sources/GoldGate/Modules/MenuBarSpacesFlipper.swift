import Foundation
import SwiftUI
import AppKit
import Combine

// MARK: - MenuBar Spaces & Profile Models
public struct MenubarProfilePreset: Identifiable, Hashable {
    public let id: String
    public let name: String
    public let symbol: String
    public let color: Color

    public init(id: String, name: String, symbol: String, color: Color) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.color = color
    }
}

// MARK: - Profile & Spaces Controller
public final class MenuBarSpacesController: ObservableObject {
    public static let shared = MenuBarSpacesController()

    @Published public var currentProfileIndex: Int = 0
    @Published public var isSpinning: Bool = false
    @Published public var reelOffset: CGFloat = 0
    @Published public var activeSpaceIndex: Int = 1
    public let totalSpaces: Int = 4

    public let profiles: [MenubarProfilePreset] = [
        MenubarProfilePreset(id: "developer", name: "Dev Suite", symbol: "hammer.fill", color: .blue),
        MenubarProfilePreset(id: "casino", name: "Casino Slots", symbol: "suit.spade.fill", color: .orange),
        MenubarProfilePreset(id: "creator", name: "Media Pro", symbol: "sparkles.tv.fill", color: .purple),
        MenubarProfilePreset(id: "zen", name: "Minimal Zen", symbol: "leaf.fill", color: .green)
    ]

    public var currentProfile: MenubarProfilePreset {
        profiles[currentProfileIndex % profiles.count]
    }

    private var cancellables = Set<AnyCancellable>()

    public init() {
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.activeSpaceDidChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.activeSpaceIndex = (self.activeSpaceIndex % self.totalSpaces) + 1
            }
            .store(in: &cancellables)
    }

    public func triggerCasinoSpin() {
        guard !isSpinning else { return }
        isSpinning = true
        withAnimation(.interpolatingSpring(stiffness: 140, damping: 12)) {
            reelOffset += 360 * 3
            currentProfileIndex = (currentProfileIndex + 1) % profiles.count
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            self.isSpinning = false
        }
    }

    public func switchToSpace(index: Int) {
        guard index >= 1 && index <= totalSpaces else { return }
        activeSpaceIndex = index
        let keyCodes: [Int: CGKeyCode] = [1: 18, 2: 19, 3: 20, 4: 21]
        guard let code = keyCodes[index],
              let src = CGEventSource(stateID: .combinedSessionState),
              let down = CGEvent(keyboardEventSource: src, virtualKey: code, keyDown: true),
              let up = CGEvent(keyboardEventSource: src, virtualKey: code, keyDown: false) else { return }
        down.flags = .maskControl
        up.flags = .maskControl
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
    }
}

// MARK: - Slot Reel Spin View
public struct SlotReelSpinView: View {
    @ObservedObject var controller: MenuBarSpacesController = .shared
    public var isVertical: Bool = false

    public init(isVertical: Bool = false) {
        self.isVertical = isVertical
    }

    public var body: some View {
        Button(action: {
            controller.triggerCasinoSpin()
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(LinearGradient(colors: [controller.currentProfile.color.opacity(0.85), Color.black.opacity(0.7)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.yellow.opacity(0.8), lineWidth: 1.2))
                    .shadow(color: controller.currentProfile.color.opacity(0.4), radius: 4, x: 0, y: 1)

                HStack(spacing: 6) {
                    Image(systemName: controller.currentProfile.symbol)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .rotation3DEffect(.degrees(controller.reelOffset), axis: (x: 1.0, y: 0.0, z: 0.0))

                    if !isVertical {
                        Text(controller.currentProfile.name)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        Image(systemName: "arrow.triangle.2.circlepath.circle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.yellow)
                    }
                }
                .padding(.horizontal, isVertical ? 6 : 10)
                .padding(.vertical, 5)
            }
        }
        .buttonStyle(.plain)
        .help("Click to spin Menubar Profile Reel")
    }
}
