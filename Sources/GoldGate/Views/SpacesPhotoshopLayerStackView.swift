import AppKit
import SwiftUI

// MARK: - 🎨 Spaces Photoshop Layer Stack Palette View
// An interactive, professional Photoshop-style Layer Stack Palette for macOS Spaces.
// Lets users tweak Blend Modes, Opacity, Fill, Eyeball Visibility, Lock, Solo,
// and Live Multi-Space Composited Blending.

public struct SpacesPhotoshopLayerStackView: View {
    @ObservedObject var manager: SpacesLayerManager = .shared
    @ObservedObject var desktopsManager: MacDesktopsManager = .shared
    @State private var hoveredSpaceIndex: Int? = nil

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // ── Top Photoshop Palette Header ────────────────────────────────
            paletteHeaderView

            Divider().background(Color.white.opacity(0.12))

            // ── Top Blend Mode & Opacity Controls Bar ───────────────────────
            topBlendAndOpacityBar

            Divider().background(Color.white.opacity(0.12))

            // ── Interactive Layer Stack Table ───────────────────────────────
            layerStackListView

            Divider().background(Color.white.opacity(0.12))

            // ── Bottom Palette Action Bar ───────────────────────────────────
            bottomActionBar
        }
        .frame(width: 320, height: 440)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(red: 0.12, green: 0.13, blue: 0.16).opacity(0.96))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.15), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.45), radius: 18, x: 0, y: 8)
    }

    // MARK: - 1. Palette Header
    private var paletteHeaderView: some View {
        HStack(spacing: 6) {
            Image(systemName: "square.3.layers.3d.down.right.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.cyan)

            Text("Spaces Layers")
                .font(.system(size: 12.5, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Spacer()

            Text("\(manager.layers.count) Spaces")
                .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                .foregroundColor(.cyan)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color.cyan.opacity(0.16)))

            Button(action: {
                manager.createNewSpaceLayer()
            }) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(0.85))
                    .padding(4)
                    .background(Circle().fill(Color.white.opacity(0.12)))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
    }

    // MARK: - 2. Top Blend Mode & Opacity Controls
    private var selectedLayer: SpaceGraphicLayer? {
        manager.layers.first(where: { $0.spaceIndex == manager.selectedLayerIndex }) ?? manager.layers.first
    }

    private var topBlendAndOpacityBar: some View {
        HStack(spacing: 8) {
            // Blend Mode Dropdown
            Menu {
                ForEach(SpaceBlendMode.allCases) { mode in
                    Button(action: {
                        if let layer = selectedLayer {
                            manager.setLayerBlendMode(spaceIndex: layer.spaceIndex, blendMode: mode)
                        }
                    }) {
                        Label(mode.rawValue, systemImage: mode.icon)
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(selectedLayer?.blendMode.rawValue ?? "Normal")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4.5)
                .frame(width: 120)
                .background(RoundedRectangle(cornerRadius: 6).fill(Color.white.opacity(0.08)))
            }
            .menuStyle(BorderlessButtonMenuStyle())

            Spacer()

            // Opacity Label & Scrubbing Slider
            HStack(spacing: 4) {
                Text("Opacity:")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))

                Text("\(Int((selectedLayer?.opacity ?? 1.0) * 100))%")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.cyan)
                    .frame(width: 34, alignment: .trailing)

                Slider(
                    value: Binding(
                        get: { selectedLayer?.opacity ?? 1.0 },
                        set: { if let l = selectedLayer { manager.setLayerOpacity(spaceIndex: l.spaceIndex, opacity: $0) } }
                    ),
                    in: 0.1...1.0
                )
                .frame(width: 60)
                .accentColor(.cyan)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.2))
    }

    // MARK: - 3. Layer Stack List
    private var layerStackListView: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(spacing: 2) {
                // Render from Top Layer (Highest Space Index) down to Bottom Layer (Space 1)
                ForEach(manager.layers.reversed()) { layer in
                    layerRow(layer: layer)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private func layerRow(layer: SpaceGraphicLayer) -> some View {
        let isSelected = layer.spaceIndex == manager.selectedLayerIndex
        let isCurrentMacOS = layer.spaceIndex == desktopsManager.currentSpaceIndex

        return HStack(spacing: 8) {
            // Eyeball Visibility Toggle
            Button(action: {
                manager.toggleLayerVisibility(spaceIndex: layer.spaceIndex)
            }) {
                Image(systemName: layer.isVisible ? "eye.fill" : "eye.slash")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(layer.isVisible ? .white.opacity(0.85) : .white.opacity(0.25))
                    .frame(width: 18)
            }
            .buttonStyle(PlainButtonStyle())

            // Solo Focus Button
            Button(action: {
                manager.toggleSoloLayer(spaceIndex: layer.spaceIndex)
            }) {
                Text("S")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundColor(layer.isSolo ? .yellow : .white.opacity(0.2))
                    .padding(.horizontal, 3.5)
                    .padding(.vertical, 1.5)
                    .background(
                        RoundedRectangle(cornerRadius: 3)
                            .fill(layer.isSolo ? Color.yellow.opacity(0.25) : Color.clear)
                    )
            }
            .buttonStyle(PlainButtonStyle())

            // Space Thumbnail Preview Box
            ZStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.black.opacity(0.5))

                if let thumb = layer.liveThumbnail {
                    Image(nsImage: thumb)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 38, height: 24)
                        .clipped()
                        .cornerRadius(3)
                } else {
                    Image(systemName: "macwindow")
                        .font(.system(size: 11))
                        .foregroundColor(.cyan.opacity(0.6))
                }
            }
            .frame(width: 38, height: 24)

            // Layer Name & Running Apps Info
            VStack(alignment: .leading, spacing: 1.5) {
                HStack(spacing: 4) {
                    Text(layer.name)
                        .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                        .foregroundColor(isSelected ? .white : .white.opacity(0.8))
                        .lineLimit(1)

                    if isCurrentMacOS {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 5, height: 5)
                    }
                }

                HStack(spacing: 3) {
                    Text(layer.blendMode.rawValue)
                        .font(.system(size: 9, weight: .regular))
                        .foregroundColor(.white.opacity(0.5))

                    Text("•")
                        .font(.system(size: 8))
                        .foregroundColor(.white.opacity(0.3))

                    Text("\(Int(layer.opacity * 100))%")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(.cyan.opacity(0.8))
                }
            }

            Spacer()

            // Lock Toggle
            Button(action: {
                manager.toggleLayerLock(spaceIndex: layer.spaceIndex)
            }) {
                Image(systemName: layer.isLocked ? "lock.fill" : "lock.open")
                    .font(.system(size: 10))
                    .foregroundColor(layer.isLocked ? .orange : .white.opacity(0.2))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(isSelected ? Color.cyan.opacity(0.22) : (hoveredSpaceIndex == layer.spaceIndex ? Color.white.opacity(0.06) : Color.clear))
        )
        .contentShape(Rectangle())
        .onTapGesture {
            manager.selectAndSwitchToLayer(spaceIndex: layer.spaceIndex)
        }
        .onHover { isHover in
            hoveredSpaceIndex = isHover ? layer.spaceIndex : nil
        }
    }

    // MARK: - 4. Bottom Action Bar
    private var bottomActionBar: some View {
        HStack(spacing: 12) {
            // Merge Layer Down Button
            Button(action: {
                if let sel = selectedLayer {
                    manager.mergeLayerDown(sourceSpaceIndex: sel.spaceIndex)
                }
            }) {
                Image(systemName: "arrow.down.to.line.compact")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
            }
            .buttonStyle(PlainButtonStyle())
            .help("Merge Space Layer Down")

            // New Layer Button
            Button(action: {
                manager.createNewSpaceLayer()
            }) {
                Image(systemName: "plus.rectangle.on.rectangle")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white.opacity(0.7))
            }
            .buttonStyle(PlainButtonStyle())
            .help("New Space Layer")

            Spacer()

            // Status message
            Text(manager.statusMessage)
                .font(.system(size: 9.5, weight: .medium))
                .foregroundColor(.cyan.opacity(0.85))
                .lineLimit(1)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.25))
    }
}
