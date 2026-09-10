import SwiftUI
import AppKit

/// Unified left-edge or right-edge vertical stage manager shelf for Genie SmartGrid.
public struct SmartGridShelfView: View {
    @ObservedObject var gridManager = SmartGridManager.shared
    @State private var hoveredSlotIndex: Int? = nil

    public init() {}

    public var body: some View {
        VStack(spacing: 8) {
            // Header: Apple Logo + SmartGrid Tile Action
            HStack(spacing: 6) {
                Button(action: {
                    gridManager.layoutAllApplicationsAsBlock()
                }) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(LinearGradient(colors: [Color.cyan.opacity(0.8), Color.blue.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 32, height: 32)
                        Image(systemName: "rectangle.3.group.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .buttonStyle(.plain)
                .help("Auto-Tile Open Windows (⌘⌥Space)")

                Text("STAGE")
                    .font(.system(size: 9, weight: .black, design: .monospaced))
                    .foregroundColor(.cyan)

                Spacer()
            }
            .padding(.top, 8)
            .padding(.horizontal, 6)

            Divider()
                .background(Color.white.opacity(0.15))

            // 6-Space Preview Stack
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 6) {
                    ForEach(0..<6, id: \.self) { slotIndex in
                        let isHovered = hoveredSlotIndex == slotIndex
                        Button(action: {
                            MenuBarSpacesController.shared.switchToSpace(index: (slotIndex % 4) + 1)
                        }) {
                            VStack(spacing: 2) {
                                HStack {
                                    Text("SPACE \(slotIndex + 1)")
                                        .font(.system(size: 8, weight: .bold, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.85))
                                    Spacer()
                                }
                                .padding(.horizontal, 4)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color(white: 0.12))
                                    .frame(width: 90, height: 50)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 4)
                                            .stroke(isHovered ? Color.cyan : Color.white.opacity(0.15), lineWidth: 1)
                                    )
                            }
                            .padding(4)
                            .background(RoundedRectangle(cornerRadius: 6).fill(isHovered ? Color.white.opacity(0.08) : Color.clear))
                        }
                        .buttonStyle(.plain)
                        .onHover { inside in
                            hoveredSlotIndex = inside ? slotIndex : nil
                        }
                    }
                }
                .padding(.horizontal, 6)
            }
        }
        .frame(width: 110)
        .frame(maxHeight: .infinity)
        .background(Color.black.opacity(0.85))
    }
}
