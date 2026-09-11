// MARK: - GenieDuoFoldContainerView.swift
// Golden Gate Engineering • © 2026 Nicholas M. Dudek
//
// Duo Fold Dual-Screen / Two-Page Workspace Container for Genie.
// Supports interactive corner page-wipe from bottom-right to top-left,
// dynamic two-page book fold (Chat + Full Editor), screen rotation
// (Horizontal Book Mode ⟷ Vertical Stacked Mode), and full editor turn.

import AppKit
import Foundation
import SwiftUI

// MARK: - 📖 Duo Fold Mode & Orientation
public enum DuoFoldMode: String, CaseIterable, Identifiable {
    case singleChat = "Single Page (Chat)"
    case twoPageFold = "Two-Page (Duo Fold)"
    case fullEditor = "Full Editor"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .singleChat: return "rectangle.fill"
        case .twoPageFold: return "book.pages.fill"
        case .fullEditor: return "macwindow.on.rectangle"
        }
    }
}

public enum DuoFoldOrientation: String, CaseIterable, Identifiable {
    case bookSideBySide = "Side-by-Side (Book)"
    case stackedVertical = "Stacked (Vertical)"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .bookSideBySide: return "rectangle.split.2x1.fill"
        case .stackedVertical: return "rectangle.split.1x2.fill"
        }
    }
}

public enum DuoFoldPage2Content: String, CaseIterable, Identifiable {
    case codeEditor = "Code Editor"
    case iphoneSimulator = "iPhone Simulator"
    case splitEditorAndSimulator = "Split: Edit + Movie"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .codeEditor: return "curlybraces"
        case .iphoneSimulator: return "iphone"
        case .splitEditorAndSimulator: return "rectangle.split.2x1.fill"
        }
    }
}

// MARK: - 📐 Duo Fold Corner Curl Shape
public struct DuoFoldCornerCurlShape: Shape {
    public var curlOffset: CGFloat

    public var animatableData: CGFloat {
        get { curlOffset }
        set { curlOffset = newValue }
    }

    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let size = max(36, min(rect.width * 0.85, curlOffset))

        // Folded flap at bottom-right
        let br = CGPoint(x: rect.maxX, y: rect.maxY)
        let top = CGPoint(x: rect.maxX, y: rect.maxY - size)
        let left = CGPoint(x: rect.maxX - size, y: rect.maxY)

        path.move(to: br)
        path.addLine(to: top)
        path.addLine(to: left)
        path.closeSubpath()
        return path
    }
}

// MARK: - 📱 Duo Fold Container View
public struct GenieDuoFoldContainerView<ChatContent: View>: View {
    @AppStorage("genieDuoFoldMode") var modeRaw: String = DuoFoldMode.singleChat.rawValue
    @AppStorage("genieDuoFoldOrientation") var orientationRaw: String = DuoFoldOrientation.bookSideBySide.rawValue
    @AppStorage("genieDuoFoldSplitRatio") var splitRatio: Double = 0.50
    @AppStorage("genieDuoPage2Content") var page2ContentRaw: String = DuoFoldPage2Content.splitEditorAndSimulator.rawValue

    public var chatView: ChatContent
    public var editorFileURL: URL?
    public var onFileSelected: ((URL) -> Void)?

    @State private var dragOffset: CGSize = .zero
    @State private var isDraggingCorner: Bool = false
    @State private var isHingeHovered: Bool = false
    @State private var isCornerHovered: Bool = false

    public init(
        editorFileURL: URL? = nil,
        onFileSelected: ((URL) -> Void)? = nil,
        @ViewBuilder chatView: () -> ChatContent
    ) {
        self.editorFileURL = editorFileURL
        self.onFileSelected = onFileSelected
        self.chatView = chatView()
    }

    private var currentMode: DuoFoldMode {
        DuoFoldMode(rawValue: modeRaw) ?? .singleChat
    }

    private var currentOrientation: DuoFoldOrientation {
        DuoFoldOrientation(rawValue: orientationRaw) ?? .bookSideBySide
    }

    private var currentPage2Content: DuoFoldPage2Content {
        DuoFoldPage2Content(rawValue: page2ContentRaw) ?? .splitEditorAndSimulator
    }

    private func setMode(_ newMode: DuoFoldMode) {
        modeRaw = newMode.rawValue
    }

    private func setOrientation(_ newOrientation: DuoFoldOrientation) {
        orientationRaw = newOrientation.rawValue
    }

    private func setPage2Content(_ newContent: DuoFoldPage2Content) {
        page2ContentRaw = newContent.rawValue
    }

    public var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .bottomTrailing) {
                // Main Workspace Layout
                Group {
                    switch currentMode {
                    case .singleChat:
                        singleChatWorkspace(size: geo.size)

                    case .twoPageFold:
                        twoPageFoldWorkspace(size: geo.size)

                    case .fullEditor:
                        fullEditorWorkspace(size: geo.size)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)

                // Draggable Corner Wipe Tab (Bottom-Right Corner)
                duoFoldCornerCurlTab(size: geo.size)
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    // MARK: - 1. Single Chat Workspace
    @ViewBuilder
    private func singleChatWorkspace(size: CGSize) -> some View {
        ZStack(alignment: .topTrailing) {
            chatView
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Top-right subtle duo-fold expand button
            Button(action: {
                HapticFeedback.selection()
                withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                    setMode(.twoPageFold)
                }
            }) {
                HStack(spacing: 5) {
                    Image(systemName: "book.pages.fill")
                        .font(.system(size: 11, weight: .bold))
                    Text("Duo Fold 📖")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.cyan)
                .padding(.horizontal, 9)
                .padding(.vertical, 4.5)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.65))
                        .overlay(Capsule().stroke(Color.cyan.opacity(0.40), lineWidth: 0.8))
                )
                .shadow(color: Color.black.opacity(0.4), radius: 4, y: 2)
            }
            .buttonStyle(.plain)
            .padding(.top, 10)
            .padding(.trailing, 14)
            .help("Unfold into Two-Page Duo Studio (Chat + Full Editor)")
        }
    }

    // MARK: - 2. Two-Page Fold Workspace (Duo Fold)
    @ViewBuilder
    private func twoPageFoldWorkspace(size: CGSize) -> some View {
        let ratio = CGFloat(max(0.25, min(0.75, splitRatio)))

        if currentOrientation == .bookSideBySide {
            // Horizontal Book Mode (Chat Left, Editor Right)
            let spineW: CGFloat = 16
            let availW = max(300, size.width - spineW)
            let leftW = availW * ratio
            let rightW = availW * (1.0 - ratio)

            HStack(spacing: 0) {
                // Page 1: Genie Chat Pane
                chatView
                    .frame(width: leftW, height: size.height)
                    .clipped()

                // Duo Fold Central Spine / Hinge
                duoFoldSpineHorizontal(height: size.height, totalWidth: size.width)
                    .frame(width: spineW, height: size.height)

                // Page 2: Workspace View (Code Editor, iPhone Simulator, or Split Edit + Movie)
                page2WorkspaceView(width: rightW, height: size.height)
                    .frame(width: rightW, height: size.height)
                    .clipped()
            }
        } else {
            // Vertical Stacked Mode (Chat Top, Editor Bottom)
            let spineH: CGFloat = 20
            let availH = max(200, size.height - spineH)
            let topH = availH * ratio
            let bottomH = availH * (1.0 - ratio)

            VStack(spacing: 0) {
                // Page 1: Genie Chat Pane
                chatView
                    .frame(width: size.width, height: topH)
                    .clipped()

                // Duo Fold Central Spine / Hinge
                duoFoldSpineVertical(width: size.width, totalHeight: size.height)
                    .frame(width: size.width, height: spineH)

                // Page 2: Workspace View (Code Editor, iPhone Simulator, or Split Edit + Movie)
                page2WorkspaceView(width: size.width, height: bottomH)
                    .frame(width: size.width, height: bottomH)
                    .clipped()
            }
        }
    }

    // MARK: - 3. Full Editor Workspace
    @ViewBuilder
    private func fullEditorWorkspace(size: CGSize) -> some View {
        VStack(spacing: 0) {
            // Top Bar in Full Editor with Fold Controls
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                        .foregroundColor(.cyan)
                    Text("Genie Studio • Full Code Editor & Preview")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                Spacer()

                // Rotate Screen Button
                Button(action: {
                    HapticFeedback.selection()
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.82)) {
                        setOrientation(currentOrientation == .bookSideBySide ? .stackedVertical : .bookSideBySide)
                        setMode(.twoPageFold)
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 10))
                        Text("Rotate Screen")
                            .font(.system(size: 10.5, weight: .semibold))
                    }
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3.5)
                    .background(Capsule().fill(Color.white.opacity(0.12)))
                }
                .buttonStyle(.plain)
                .help("Rotate between horizontal and vertical book split")

                // Return to Two-Page Fold
                Button(action: {
                    HapticFeedback.selection()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                        setMode(.twoPageFold)
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "book.pages")
                            .font(.system(size: 11))
                        Text("Two-Page Fold")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.cyan.opacity(0.20)))
                    .overlay(Capsule().stroke(Color.cyan.opacity(0.45), lineWidth: 0.8))
                }
                .buttonStyle(.plain)
                .help("Fold back to Two-Page layout (Chat + Editor)")

                // Fold back to Single Chat
                Button(action: {
                    HapticFeedback.selection()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                        setMode(.singleChat)
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left.fill")
                            .font(.system(size: 10))
                        Text("Chat Only")
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(.white.opacity(0.70))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.white.opacity(0.08)))
                }
                .buttonStyle(.plain)
                .help("Fold closed to Single Page Chat")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(Color.black.opacity(0.55))
            .overlay(
                Rectangle()
                    .stroke(Color.white.opacity(0.10), lineWidth: 0.5)
            )

            // Page 2 Workspace View (Editor, iPhone Simulator, or Split Edit + Movie)
            page2WorkspaceView(width: size.width, height: size.height - 40)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Page 2 Workspace View (Code Editor / iPhone Movie Simulator / Split)
    @ViewBuilder
    private func page2WorkspaceView(width: CGFloat, height: CGFloat) -> some View {
        VStack(spacing: 0) {
            // Page 2 Sub-Toolbar (Switcher)
            HStack(spacing: 8) {
                HStack(spacing: 4) {
                    page2TabButton(.codeEditor, title: "Code Editor", icon: "curlybraces")
                    page2TabButton(.iphoneSimulator, title: "iPhone Movie Sim", icon: "iphone")
                    page2TabButton(.splitEditorAndSimulator, title: "Split (Edit + Movie)", icon: "rectangle.split.2x1.fill")
                }
                .padding(2.5)
                .background(Capsule().fill(Color.white.opacity(0.08)))

                Spacer()

                if currentPage2Content == .splitEditorAndSimulator || currentPage2Content == .iphoneSimulator {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                        Text("MOVIE SIMULATOR")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(.yellow)
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2.5)
                    .background(Capsule().fill(Color.yellow.opacity(0.18)))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.black.opacity(0.60))

            // Page 2 Active Display
            Group {
                switch currentPage2Content {
                case .codeEditor:
                    GenieNativeEditorPreviewerView(
                        fileURL: editorFileURL,
                        onCodeChange: nil
                    )

                case .iphoneSimulator:
                    GenieiPhoneDuoSimulatorView()

                case .splitEditorAndSimulator:
                    HStack(spacing: 0) {
                        // Left: Code Editor
                        GenieNativeEditorPreviewerView(
                            fileURL: editorFileURL,
                            onCodeChange: nil
                        )
                        .frame(width: max(260, width * 0.50))

                        // Divider Spine
                        Rectangle()
                            .fill(Color.white.opacity(0.12))
                            .frame(width: 1)

                        // Right: iPhone Duo Simulator (watch movie while editing!)
                        GenieiPhoneDuoSimulatorView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func page2TabButton(_ content: DuoFoldPage2Content, title: String, icon: String) -> some View {
        Button(action: {
            HapticFeedback.selection()
            withAnimation(.spring(response: 0.28, dampingFraction: 0.82)) {
                setPage2Content(content)
            }
        }) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 9.5))
                Text(title)
                    .font(.system(size: 10, weight: currentPage2Content == content ? .bold : .medium))
            }
            .foregroundColor(currentPage2Content == content ? .black : .white.opacity(0.80))
            .padding(.horizontal, 8)
            .padding(.vertical, 3.5)
            .background(
                Capsule().fill(currentPage2Content == content ? Color.cyan : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - 4. Duo Fold Central Spines (Horizontal & Vertical)
    private func duoFoldSpineHorizontal(height: CGFloat, totalWidth: CGFloat) -> some View {
        ZStack {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.70),
                            Color(white: 0.14).opacity(0.95),
                            Color.black.opacity(0.70)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .overlay(
                    Rectangle()
                        .stroke(Color.white.opacity(0.14), lineWidth: 0.6)
                )

            VStack(spacing: 12) {
                // Rotate Screen Button
                Button(action: {
                    HapticFeedback.selection()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                        setOrientation(.stackedVertical)
                    }
                }) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white.opacity(0.85))
                        .frame(width: 14, height: 14)
                        .background(Circle().fill(Color.cyan.opacity(0.35)))
                }
                .buttonStyle(.plain)
                .help("Rotate Screen to Vertical Stacked Mode")

                // Center Grip Dots
                VStack(spacing: 3) {
                    ForEach(0..<4) { _ in
                        Circle()
                            .fill(Color.white.opacity(0.40))
                            .frame(width: 2.5, height: 2.5)
                    }
                }

                // Turn to Full Editor Button
                Button(action: {
                    HapticFeedback.selection()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                        setMode(.fullEditor)
                    }
                }) {
                    Image(systemName: "arrow.right.to.line.compact")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.yellow)
                        .frame(width: 14, height: 14)
                        .background(Circle().fill(Color.yellow.opacity(0.30)))
                }
                .buttonStyle(.plain)
                .help("Turn Page completely into Full Code Editor")
            }
        }
        .gesture(
            DragGesture()
                .onChanged { val in
                    let newRatio = Double(val.location.x / totalWidth)
                    splitRatio = max(0.25, min(0.75, newRatio))
                }
                .onEnded { _ in
                    HapticFeedback.selection()
                }
        )
    }

    private func duoFoldSpineVertical(width: CGFloat, totalHeight: CGFloat) -> some View {
        ZStack {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.70),
                            Color(white: 0.14).opacity(0.95),
                            Color.black.opacity(0.70)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    Rectangle()
                        .stroke(Color.white.opacity(0.14), lineWidth: 0.6)
                )

            HStack(spacing: 14) {
                // Rotate Screen Button
                Button(action: {
                    HapticFeedback.selection()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                        setOrientation(.bookSideBySide)
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 9, weight: .bold))
                        Text("Rotate to Book")
                            .font(.system(size: 9.5, weight: .semibold))
                    }
                    .foregroundColor(.white.opacity(0.85))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.cyan.opacity(0.30)))
                }
                .buttonStyle(.plain)

                // Grip Line
                Capsule()
                    .fill(Color.white.opacity(0.35))
                    .frame(width: 32, height: 3)

                // Turn to Full Editor Button
                Button(action: {
                    HapticFeedback.selection()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.82)) {
                        setMode(.fullEditor)
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.to.line.compact")
                            .font(.system(size: 8, weight: .bold))
                        Text("Full Editor")
                            .font(.system(size: 9.5, weight: .semibold))
                    }
                    .foregroundColor(.yellow)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.yellow.opacity(0.25)))
                }
                .buttonStyle(.plain)
            }
        }
        .gesture(
            DragGesture()
                .onChanged { val in
                    let newRatio = Double(val.location.y / totalHeight)
                    splitRatio = max(0.25, min(0.75, newRatio))
                }
                .onEnded { _ in
                    HapticFeedback.selection()
                }
        )
    }

    // MARK: - 5. Draggable Corner Page-Turn Curl (Bottom-Right Corner)
    private func duoFoldCornerCurlTab(size: CGSize) -> some View {
        let activeCurlSize: CGFloat = {
            if isDraggingCorner {
                let diag = -dragOffset.width * 0.7 + -dragOffset.height * 0.5
                return max(42, min(220, 42 + diag))
            } else if isCornerHovered {
                return 48
            } else {
                return 36
            }
        }()

        return ZStack(alignment: .bottomTrailing) {
            // Folded Under-Layer Shadow
            DuoFoldCornerCurlShape(curlOffset: activeCurlSize)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.65),
                            Color.cyan.opacity(0.35),
                            Color.white.opacity(0.25)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    DuoFoldCornerCurlShape(curlOffset: activeCurlSize)
                        .stroke(
                            LinearGradient(
                                colors: [Color.cyan.opacity(0.85), Color.white.opacity(0.60), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                )
                .shadow(color: Color.black.opacity(0.55), radius: 6, x: -3, y: -3)

            // Corner Peel Glyph & Label
            VStack(alignment: .trailing, spacing: 1) {
                Image(systemName: currentMode == .fullEditor ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                    .font(.system(size: isCornerHovered ? 11 : 9, weight: .bold))
                    .foregroundColor(.cyan)

                if isCornerHovered || isDraggingCorner {
                    Text(currentMode == .singleChat ? "Peel Editor" : (currentMode == .twoPageFold ? "Turn Full" : "Fold Chat"))
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)
                }
            }
            .padding(.trailing, 6)
            .padding(.bottom, 6)
        }
        .frame(width: activeCurlSize, height: activeCurlSize)
        .contentShape(Rectangle())
        .onHover { h in
            withAnimation(.spring(response: 0.22, dampingFraction: 0.75)) {
                isCornerHovered = h
            }
        }
        .onTapGesture {
            HapticFeedback.selection()
            withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                switch currentMode {
                case .singleChat:
                    setMode(.twoPageFold)
                case .twoPageFold:
                    setMode(.fullEditor)
                case .fullEditor:
                    setMode(.singleChat)
                }
            }
        }
        .gesture(
            DragGesture()
                .onChanged { val in
                    isDraggingCorner = true
                    dragOffset = val.translation
                }
                .onEnded { val in
                    isDraggingCorner = false
                    let totalDrag = (-val.translation.width * 0.7 + -val.translation.height * 0.5)
                    dragOffset = .zero

                    withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                        if totalDrag > 160 {
                            setMode(.fullEditor)
                        } else if totalDrag > 50 {
                            setMode(.twoPageFold)
                        } else if totalDrag < -40 {
                            setMode(.singleChat)
                        }
                    }
                    HapticFeedback.selection()
                }
        )
        .help("Duo Fold • Drag up-left from bottom-right corner to peel open Two-Page Editor or click to toggle")
    }
}
