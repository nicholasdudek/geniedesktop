import SwiftUI

// MARK: - 📖 Genie Duo Dual-Screen / Split Fold Container
// Provides side-by-side (Book Fold) and dual-deck (Top/Bottom) workspace
// layouts for iPad, large screens, and multi-window productivity.

public enum DuoSplitOrientation: String, CaseIterable, Identifiable {
    case sideBySide = "Book Fold (Side by Side)"
    case topBottom = "Dual Deck (Top & Bottom)"

    public var id: String { rawValue }
}

public struct GenieDuoContainerView: View {
    @AppStorage("genie.duo.orientation") private var orientation: DuoSplitOrientation = .sideBySide
    @AppStorage("genie.duo.splitRatio") private var splitRatio: Double = 0.50
    @State private var secondaryPane: String = "CLI" // "CLI" or "Files"

    public init() {}

    public var body: some View {
        GeometryReader { geo in
            if orientation == .sideBySide {
                HStack(spacing: 0) {
                    // Left Pane: Chat
                    ChatView()
                        .frame(width: max(280, geo.size.width * splitRatio))

                    // Center Folding Hinge / Divider
                    ZStack {
                        Rectangle()
                            .fill(Color.white.opacity(0.12))
                            .frame(width: 2)

                        Circle()
                            .fill(Color.cyan)
                            .frame(width: 20, height: 20)
                            .overlay(Image(systemName: "arrow.left.and.right").font(.system(size: 9, weight: .bold)).foregroundColor(.black))
                    }
                    .frame(width: 14)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newRatio = value.location.x / geo.size.width
                                self.splitRatio = min(0.80, max(0.20, newRatio))
                            }
                    )

                    // Right Pane: CLI or Files
                    VStack(spacing: 0) {
                        HStack {
                            Picker("Secondary Tool", selection: $secondaryPane) {
                                Text("Terminal (CLI)").tag("CLI")
                                Text("Files").tag("Files")
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)

                            Spacer()

                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    orientation = .topBottom
                                }
                            }) {
                                Image(systemName: "rectangle.split.2x1")
                                    .font(.system(size: 13))
                                    .foregroundColor(.cyan)
                            }
                            .padding(.trailing, 12)
                        }
                        .background(Color(white: 0.08))

                        Divider().background(Color.white.opacity(0.12))

                        if secondaryPane == "CLI" {
                            GenieCLIView()
                        } else {
                            FilesView()
                        }
                    }
                }
            } else {
                VStack(spacing: 0) {
                    // Top Pane: Chat
                    ChatView()
                        .frame(height: max(200, geo.size.height * splitRatio))

                    // Horizontal Hinge Divider
                    ZStack {
                        Rectangle()
                            .fill(Color.white.opacity(0.12))
                            .frame(height: 2)

                        Circle()
                            .fill(Color.cyan)
                            .frame(width: 20, height: 20)
                            .overlay(Image(systemName: "arrow.up.and.down").font(.system(size: 9, weight: .bold)).foregroundColor(.black))
                    }
                    .frame(height: 14)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newRatio = value.location.y / geo.size.height
                                self.splitRatio = min(0.80, max(0.20, newRatio))
                            }
                    )

                    // Bottom Pane: CLI or Files
                    VStack(spacing: 0) {
                        HStack {
                            Picker("Secondary Tool", selection: $secondaryPane) {
                                Text("Terminal (CLI)").tag("CLI")
                                Text("Files").tag("Files")
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)

                            Spacer()

                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                    orientation = .sideBySide
                                }
                            }) {
                                Image(systemName: "rectangle.split.1x2")
                                    .font(.system(size: 13))
                                    .foregroundColor(.cyan)
                            }
                            .padding(.trailing, 12)
                        }
                        .background(Color(white: 0.08))

                        Divider().background(Color.white.opacity(0.12))

                        if secondaryPane == "CLI" {
                            GenieCLIView()
                        } else {
                            FilesView()
                        }
                    }
                }
            }
        }
    }
}
