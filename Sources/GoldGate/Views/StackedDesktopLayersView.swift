import AppKit
import SwiftUI

// MARK: - Stacked Desktop Layers Manager Extension

extension MacDesktopsManager {
    public func workspaceName(for space: MacDesktopSpace) -> String {
        let key = "nexus.workspaceName.\(space.index)"
        let saved = UserDefaults.standard.string(forKey: key)
        if let s = saved, !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return s
        }
        switch space.index {
        case 1: return "Primary • Main"
        case 2: return "Code • Dev"
        case 3: return "Design • Creative"
        case 4: return "Research • Web"
        case 5: return "Focus • Terminal"
        default: return "Workspace \(space.index)"
        }
    }

    public func setWorkspaceName(for space: MacDesktopSpace, name: String) {
        let key = "nexus.workspaceName.\(space.index)"
        UserDefaults.standard.set(name, forKey: key)
        objectWillChange.send()
    }

    public func isWorkspaceLocked(for space: MacDesktopSpace) -> Bool {
        let key = "nexus.workspaceLocked.\(space.index)"
        return UserDefaults.standard.bool(forKey: key)
    }

    public func toggleWorkspaceLock(for space: MacDesktopSpace) {
        let key = "nexus.workspaceLocked.\(space.index)"
        let current = isWorkspaceLocked(for: space)
        UserDefaults.standard.set(!current, forKey: key)
        objectWillChange.send()
    }

    public func unlockAndSwitch(to space: MacDesktopSpace) {
        HapticFeedback.heavy()
        if isWorkspaceLocked(for: space) {
            let key = "nexus.workspaceLocked.\(space.index)"
            UserDefaults.standard.set(false, forKey: key)
        }
        switchToDesktop(index: space.index)
    }
}

// MARK: - Stacked Desktop Layers Deck View (3D Spatial Card Deck)

public struct StackedDesktopLayersDeckView: View {
    @AppStorage(PrefKey.appLanguage) var appLanguage: String = "English (US)"
@ObservedObject var manager: MacDesktopsManager = .shared
    @ObservedObject var wallpaperManager: WallpaperManager = .shared
    @State private var isHoveringDeck: Bool = false
    @State private var editingSpaceIndex: Int? = nil
    @State private var tempName: String = ""

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header: Layer Count & Add Workspace Layer Button
            HStack(alignment: .center) {
                HStack(spacing: 5) {
                    Image(systemName: "square.3.layers.3d.down.right.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.cyan)
                    Text(LocalizedStrings.translateText("Stacked Desktop Workspaces", lang: appLanguage))
                        .font(.system(size: 12.5, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Text("\(manager.spaces.count) Layers")
                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        .foregroundColor(.cyan)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1.5)
                        .background(Capsule().fill(Color.cyan.opacity(0.16)))
                }

                Spacer()

                // + Stack New Layer Button
                Button(action: {
                    manager.createDesktop()
                }) {
                    HStack(spacing: 3) {
                        Image(systemName: "plus.rectangle.on.rectangle.fill")
                            .font(.system(size: 9, weight: .bold))
                        Text(LocalizedStrings.translateText("Stack Layer", lang: appLanguage))
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3.5)
                    .background(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .fill(Color.cyan.opacity(0.14))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 5, style: .continuous)
                            .strokeBorder(Color.cyan.opacity(0.35), lineWidth: 0.8)
                    )
                }
                .buttonStyle(.plain)
                .help("Create and stack a new WindowServer hardware desktop space")
            }

            // ── 3D / Spatial Stacked Card Deck ──
            // Desktops are visually stacked on top of each other!
            // The active layer rises to the top, while inactive layers stack underneath with depth offsets.
            ZStack(alignment: .top) {
                ForEach(Array(manager.spaces.enumerated()), id: \.element.id) { idx, space in
                    let isCurrent = space.index == manager.currentSpaceIndex
                    let isLocked = manager.isWorkspaceLocked(for: space)
                    let fanMultiplier: CGFloat = isHoveringDeck ? 44.0 : 20.0

                    // Spatial Layer Card
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            // Layer Indicator Badge
                            HStack(spacing: 3) {
                                Image(systemName: isLocked ? "lock.fill" : (isCurrent ? "lock.open.fill" : "square.stack.3d.up"))
                                    .font(.system(size: 8.5, weight: .bold))
                                    .foregroundColor(isCurrent ? .cyan : (isLocked ? .orange : .secondary))

                                Text("Layer \(space.index)")
                                    .font(.system(size: 9, weight: .heavy, design: .monospaced))
                                    .foregroundColor(isCurrent ? .cyan : .secondary)
                            }
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(isCurrent ? Color.cyan.opacity(0.18) : Color.black.opacity(0.35))
                            )

                            // Workspace Name (Double click or tap to rename)
                            if editingSpaceIndex == space.index {
                                TextField("Workspace Name", text: $tempName, onCommit: {
                                    manager.setWorkspaceName(for: space, name: tempName)
                                    editingSpaceIndex = nil
                                })
                                .textFieldStyle(.plain)
                                .font(.system(size: 11, weight: .bold))
                                .frame(width: 140)
                                .padding(2)
                                .background(RoundedRectangle(cornerRadius: 4).fill(Color.primary.opacity(0.1)))
                            } else {
                                Text(manager.workspaceName(for: space))
                                    .font(.system(size: 11, weight: isCurrent ? .bold : .medium, design: .rounded))
                                    .foregroundColor(isCurrent ? .primary : .secondary)
                                    .lineLimit(1)
                                    .onTapGesture(count: 2) {
                                        tempName = manager.workspaceName(for: space)
                                        editingSpaceIndex = space.index
                                    }
                            }

                            Spacer()

                            // Lock / Unlock Button
                            Button(action: {
                                manager.toggleWorkspaceLock(for: space)
                            }) {
                                Image(systemName: isLocked ? "lock.shield.fill" : "lock.open")
                                    .font(.system(size: 9, weight: .semibold))
                                    .foregroundColor(isLocked ? .orange : .secondary.opacity(0.6))
                                    .padding(4)
                                    .background(Circle().fill(Color.primary.opacity(0.05)))
                            }
                            .buttonStyle(.plain)
                            .help(isLocked ? "Unlock Workspace Protection" : "Lock / Protect Workspace")

                            // Unlock & Switch Button
                            Button(action: {
                                manager.unlockAndSwitch(to: space)
                            }) {
                                Text(isCurrent ? "Active" : "Unlock")
                                    .font(.system(size: 8.5, weight: .bold, design: .rounded))
                                    .foregroundColor(isCurrent ? .black : .white)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 2.5)
                                    .background(
                                        Capsule()
                                            .fill(isCurrent ? Color.cyan : Color.white.opacity(0.15))
                                    )
                            }
                            .buttonStyle(.plain)
                        }

                        // Preview Thumbnail Row
                        HStack(spacing: 8) {
                            ZStack(alignment: .bottomTrailing) {
                                if let live = manager.desktopLivePreviews[space.index] {
                                    Image(nsImage: live)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 68, height: 42)
                                        .clipped()
                                } else if let wp = wallpaperManager.activeWallpaperImage {
                                    Image(nsImage: wp)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 68, height: 42)
                                        .clipped()
                                } else {
                                    LinearGradient(
                                        colors: [Color.cyan.opacity(0.6), Color.blue.opacity(0.8)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    .frame(width: 68, height: 42)
                                }

                                // Hairline top bar
                                VStack {
                                    HStack {
                                        Circle().fill(Color.white.opacity(0.7)).frame(width: 2.5, height: 2.5)
                                        Circle().fill(Color.white.opacity(0.7)).frame(width: 2.5, height: 2.5)
                                        Spacer()
                                    }
                                    .padding(2.5)
                                    Spacer()
                                }
                            }
                            .frame(width: 68, height: 42)
                            .cornerRadius(5)
                            .overlay(
                                RoundedRectangle(cornerRadius: 5)
                                    .strokeBorder(isCurrent ? Color.cyan : Color.white.opacity(0.15), lineWidth: isCurrent ? 1.5 : 0.6)
                            )

                            VStack(alignment: .leading, spacing: 2) {
                                Text(isCurrent ? "🔓 Unlocked & Focused" : (isLocked ? "🔒 Locked Layer" : "Ready to Unlock"))
                                    .font(.system(size: 9.5, weight: .semibold))
                                    .foregroundColor(isCurrent ? .cyan : (isLocked ? .orange : .secondary))

                                Text("Switch instantly to Desktop \(space.index) (Hardware WindowServer)")
                                    .font(.system(size: 8.5))
                                    .foregroundColor(.secondary.opacity(0.8))
                                    .lineLimit(2)
                            }
                            Spacer()
                        }
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color(nsColor: .windowBackgroundColor).opacity(isCurrent ? 0.95 : 0.80))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .strokeBorder(isCurrent ? Color.cyan.opacity(0.85) : Color.white.opacity(0.12), lineWidth: isCurrent ? 1.5 : 0.8)
                    )
                    .shadow(
                        color: isCurrent ? Color.cyan.opacity(0.40) : Color.black.opacity(0.25),
                        radius: isCurrent ? 8 : 4,
                        y: isCurrent ? 4 : 2
                    )
                    .offset(y: CGFloat(idx) * fanMultiplier)
                    .zIndex(isCurrent ? 100 : Double(manager.spaces.count - idx))
                    .contentShape(Rectangle())
                    .onTapGesture {
                        manager.unlockAndSwitch(to: space)
                    }
                }
            }
            .frame(height: 72 + CGFloat(manager.spaces.count - 1) * (isHoveringDeck ? 44.0 : 20.0))
            .padding(.top, 4)
            .onHover { hovering in
                withAnimation(.spring(response: 0.28, dampingFraction: 0.78)) {
                    isHoveringDeck = hovering
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.primary.opacity(0.03))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.8)
        )
    }
}

// MARK: - Compact Stacked Desktop Layers Pill for Bar

public struct CompactStackedDesktopLayersBarView: View {
    @AppStorage(PrefKey.appLanguage) var appLanguage: String = "English (US)"
@ObservedObject var manager: MacDesktopsManager = .shared
    @State private var showDeckPopover: Bool = false

    public init() {}

    public var body: some View {
        HStack(spacing: 3) {
            // Previous Layer Arrow
            Button(action: {
                manager.navigatePrevious()
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 7.5, weight: .bold))
                    .foregroundColor(manager.currentSpaceIndex > 1 ? .primary : .secondary.opacity(0.3))
                    .frame(width: 13, height: 21)
                    .background(RoundedRectangle(cornerRadius: 3.5).fill(Color.primary.opacity(0.04)))
            }
            .buttonStyle(.plain)
            .disabled(manager.currentSpaceIndex <= 1)
            .help("Previous Stacked Desktop Layer (⌃←)")

            // Stacked Layers Visual Deck Button
            Button(action: {
                showDeckPopover.toggle()
            }) {
                HStack(spacing: 4) {
                    // 3D Mini Layer Deck Graphics
                    ZStack {
                        // Background Layer 2
                        RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                            .fill(Color.cyan.opacity(0.25))
                            .frame(width: 14, height: 10)
                            .offset(x: 2, y: -2)

                        // Foreground Layer 1
                        RoundedRectangle(cornerRadius: 2.5, style: .continuous)
                            .fill(Color.cyan.opacity(0.85))
                            .frame(width: 14, height: 10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 2.5)
                                    .strokeBorder(Color.white.opacity(0.6), lineWidth: 0.5)
                            )
                    }
                    .frame(width: 18, height: 14)

                    // Layer Label & Current Workspace
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 2) {
                            Text("Layer \(manager.currentSpaceIndex)")
                                .font(.system(size: 7.5, weight: .heavy, design: .monospaced))
                                .foregroundColor(.cyan)
                            Image(systemName: "lock.open.fill")
                                .font(.system(size: 5.5))
                                .foregroundColor(.cyan)
                        }
                        Text(currentWorkspaceShortName())
                            .font(.system(size: 7, weight: .medium, design: .rounded))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
                .padding(.horizontal, 5)
                .frame(height: 21)
                .background(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(Color.cyan.opacity(0.12))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .strokeBorder(Color.cyan.opacity(0.35), lineWidth: 0.8)
                )
            }
            .buttonStyle(.plain)
            .help("Stacked Desktop Layers: Click to unlock & inspect all workspaces")
            .popover(isPresented: $showDeckPopover, arrowEdge: .bottom) {
                StackedDesktopLayersDeckView()
                    .frame(width: 320)
                    .padding(8)
            }

            // + Stack Layer Button
            Button(action: {
                manager.createDesktop()
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 7, weight: .black))
                    .foregroundColor(.cyan)
                    .frame(width: 15, height: 21)
                    .background(
                        RoundedRectangle(cornerRadius: 3.5, style: .continuous)
                            .fill(Color.cyan.opacity(0.10))
                    )
            }
            .buttonStyle(.plain)
            .help("Stack New Workspace Layer (+1)")

            // Next Layer Arrow
            Button(action: {
                manager.navigateNext()
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 7.5, weight: .bold))
                    .foregroundColor(manager.currentSpaceIndex < manager.spaces.count ? .primary : .secondary.opacity(0.3))
                    .frame(width: 13, height: 21)
                    .background(RoundedRectangle(cornerRadius: 3.5).fill(Color.primary.opacity(0.04)))
            }
            .buttonStyle(.plain)
            .disabled(manager.currentSpaceIndex >= manager.spaces.count)
            .help("Next Stacked Desktop Layer (⌃→)")
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 1)
        .background(
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.20))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 5, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 0.8)
        )
    }

    private func currentWorkspaceShortName() -> String {
        if let cur = manager.spaces.first(where: { $0.isCurrent }) {
            let full = manager.workspaceName(for: cur)
            return full.components(separatedBy: "•").first?.trimmingCharacters(in: .whitespaces) ?? full
        }
        return "Main"
    }
}
