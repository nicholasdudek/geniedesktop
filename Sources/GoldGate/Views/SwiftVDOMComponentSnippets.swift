//
//  SwiftVDOMComponentSnippets.swift
//  GoldGate
//
//  Modular, reusable React-like Virtual DOM Component Snippets for GoldGate:
//  1. VDOMGlassPanel: Reusable liquid frosted glass card container with specular highlight & blur.
//  2. VDOMStationFilmstrip: 3-station continuous vertical filmstrip snippet (Zenith, Horizon, Nadir).
//  3. VDOMGalaxyOrbitMatrix: 3x3 / 9x9 cosmic grid preview card with coordinate HUD & LOD indicators.
//  4. VDOMPromptBar: Ultra-sleek multimodal prompt bar with model badge, voice pulse, & action buttons.
//  5. VDOMLayerCard: Photoshop layer inspector card snippet with blend modes, opacity, & layer hierarchy.
//  6. VDOMSmartWindowAnchor: Snap-to-grid window card with coordinate HUD, live preview, & anchors.
//
//  Bridges to SwiftVDOMCore and PhotoshopLayerCompositorEngine.
//

import AppKit
import Combine
import Foundation
import QuartzCore
import SwiftUI

// MARK: - SwiftVDOMCore (Reactive Component State & Virtual Node Architecture)

/// High-performance reactive Virtual DOM core engine powering modular UI snippets.
@MainActor
public final class SwiftVDOMCore: ObservableObject {
    public static let shared = SwiftVDOMCore()

    @Published public var registeredSnippets: [String: VDOMSnippetMetadata] = [:]
    @Published public var activeRenderPassCount: Int = 0
    @Published public var lastDiffTimeMs: Double = 0.0
    @Published public var globalThemeMode: VDOMThemeMode = .cyberGlass

    private init() {
        registerDefaultSnippets()
    }

    private func registerDefaultSnippets() {
        register(metadata: VDOMSnippetMetadata(
            id: "vdom.glass.panel",
            name: "VDOMGlassPanel",
            category: "Containers",
            description: "Liquid frosted glass card container with specular highlight sheen."
        ))
        register(metadata: VDOMSnippetMetadata(
            id: "vdom.station.filmstrip",
            name: "VDOMStationFilmstrip",
            category: "Navigation",
            description: "3-station continuous vertical filmstrip (Zenith, Horizon, Nadir)."
        ))
        register(metadata: VDOMSnippetMetadata(
            id: "vdom.galaxy.matrix",
            name: "VDOMGalaxyOrbitMatrix",
            category: "Spatial Grid",
            description: "3x3 / 9x9 cosmic grid overview preview card."
        ))
        register(metadata: VDOMSnippetMetadata(
            id: "vdom.prompt.bar",
            name: "VDOMPromptBar",
            category: "Input & AI",
            description: "Multimodal prompt bar with model selector and voice visualizer."
        ))
        register(metadata: VDOMSnippetMetadata(
            id: "vdom.layer.card",
            name: "VDOMLayerCard",
            category: "Photoshop Compositor",
            description: "Layer inspector row with blend modes, opacity slider, and lock toggles."
        ))
        register(metadata: VDOMSnippetMetadata(
            id: "vdom.window.anchor",
            name: "VDOMSmartWindowAnchor",
            category: "Window Management",
            description: "Snap-to-grid window card with coordinate HUD and live anchors."
        ))
    }

    public func register(metadata: VDOMSnippetMetadata) {
        registeredSnippets[metadata.id] = metadata
    }

    public func markRenderPass(durationMs: Double) {
        activeRenderPassCount += 1
        lastDiffTimeMs = durationMs
    }
}

public struct VDOMSnippetMetadata: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let category: String
    public let description: String

    public init(id: String, name: String, category: String, description: String) {
        self.id = id
        self.name = name
        self.category = category
        self.description = description
    }
}

public enum VDOMThemeMode: String, CaseIterable, Sendable {
    case cyberGlass = "Cyber Glass"
    case obsidianDeep = "Obsidian Deep"
    case titaniumFrost = "Titanium Frost"
    case hauteGold = "Haute Gold"
}

// MARK: - 1. VDOMGlassPanel (Liquid Frosted Glass Container)

/// Reusable liquid frosted glass card container with specular highlight sheen,
/// customizable elevation blur, gradient border sheen, and responsive hover highlights.
public struct VDOMGlassPanel<Content: View>: View {
    public let cornerRadius: CGFloat
    public let borderWidth: CGFloat
    public let borderOpacity: Double
    public let tintColor: Color
    public let specularSheen: Bool
    public let elevation: CGFloat
    @ViewBuilder public let content: () -> Content

    @State private var isHovered: Bool = false

    public init(
        cornerRadius: CGFloat = 16.0,
        borderWidth: CGFloat = 1.0,
        borderOpacity: Double = 0.25,
        tintColor: Color = Color(red: 0.08, green: 0.10, blue: 0.18),
        specularSheen: Bool = true,
        elevation: CGFloat = 16.0,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.borderWidth = borderWidth
        self.borderOpacity = borderOpacity
        self.tintColor = tintColor
        self.specularSheen = specularSheen
        self.elevation = elevation
        self.content = content
    }

    public var body: some View {
        ZStack {
            // 1. Frosted Backing Material Layer
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(tintColor.opacity(0.82))
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Material.ultraThinMaterial)
                )

            // 2. Specular Sheen Gradient Overlay (Diagonal Light Catch)
            if specularSheen {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(isHovered ? 0.18 : 0.10),
                                Color.cyan.opacity(isHovered ? 0.08 : 0.03),
                                Color.clear,
                                Color.purple.opacity(isHovered ? 0.06 : 0.02)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            // 3. User Content
            content()
                .padding(specularSheen ? 1 : 0)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
        .overlay(
            // 4. Specular Bezel Border with Dual Highlight
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(isHovered ? borderOpacity * 1.5 : borderOpacity),
                            Color.cyan.opacity(isHovered ? borderOpacity * 1.2 : borderOpacity * 0.7),
                            Color.white.opacity(borderOpacity * 0.3),
                            Color.purple.opacity(isHovered ? borderOpacity * 0.9 : borderOpacity * 0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: borderWidth
                )
        )
        .shadow(
            color: Color.black.opacity(isHovered ? 0.55 : 0.40),
            radius: elevation,
            x: 0,
            y: elevation * 0.45
        )
        .shadow(
            color: Color.cyan.opacity(isHovered ? 0.22 : 0.0),
            radius: 12,
            x: 0,
            y: 0
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.20)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - 2. VDOMStationFilmstrip (3-Station Continuous Vertical Filmstrip)

/// 3-Station vertical continuous filmstrip snippet (Zenith, Horizon, Nadir)
/// with live snap points, status badges, and real-time interactive switching.
public struct VDOMStationFilmstrip: View {
    @ObservedObject var stationEngine: ContinuousStationScrollEngine = .shared
    public var selectedStation: CanvasStation
    public var onSelectStation: (CanvasStation) -> Void

    public init(
        selectedStation: CanvasStation = .horizon,
        onSelectStation: @escaping (CanvasStation) -> Void = { _ in }
    ) {
        self.selectedStation = selectedStation
        self.onSelectStation = onSelectStation
    }

    public var body: some View {
        VDOMGlassPanel(cornerRadius: 18, borderWidth: 1.2, tintColor: Color(red: 0.06, green: 0.07, blue: 0.12)) {
            VStack(spacing: 12) {
                // Header HUD
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.cyan)
                        .frame(width: 8, height: 8)
                        .shadow(color: Color.cyan, radius: 4)

                    Text("CONTINUOUS 3-STATION FILMSTRIP")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.cyan)

                    Spacer()

                    Text("PHYSICS: CRITICALLY DAMPED")
                        .font(.system(size: 8.5, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.55))
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)

                Divider().background(Color.white.opacity(0.10))

                // 3 Vertical Station Thumbnails
                VStack(spacing: 10) {
                    ForEach(CanvasStation.allCases) { station in
                        stationRow(station: station)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
        }
        .frame(width: 320)
    }

    @ViewBuilder
    private func stationRow(station: CanvasStation) -> some View {
        let isSelected = selectedStation == station
        Button(action: {
            onSelectStation(station)
            stationEngine.snapTo(station: station)
            HapticFeedback.selection()
        }) {
            HStack(spacing: 12) {
                // Station Icon Frame
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(station.themeColor.opacity(isSelected ? 0.28 : 0.12))
                        .frame(width: 42, height: 42)

                    Image(systemName: station.systemImageName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(station.themeColor)
                }

                // Station Info
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(station.shortTitle)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        if let badge = station.badgeLabel {
                            Text(badge)
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(station.themeColor)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1.5)
                                .background(Capsule().fill(station.themeColor.opacity(0.18)))
                        }
                    }

                    Text("Anchor Y: \(String(format: "%+.0f", station.normalizedPosition))H • \(stationCoordinateLabel(station))")
                        .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.60))
                }

                Spacer()

                // Status Reticle Pill
                if isSelected {
                    HStack(spacing: 4) {
                        Circle().fill(Color.green).frame(width: 5, height: 5)
                        Text("ACTIVE")
                            .font(.system(size: 9, weight: .heavy, design: .monospaced))
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3.5)
                    .background(Capsule().fill(Color.green.opacity(0.16)))
                    .overlay(Capsule().strokeBorder(Color.green.opacity(0.4), lineWidth: 0.8))
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white.opacity(0.35))
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? Color.white.opacity(0.12) : Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(isSelected ? station.themeColor.opacity(0.7) : Color.white.opacity(0.08), lineWidth: isSelected ? 1.5 : 0.8)
            )
        }
        .buttonStyle(.plain)
    }

    private func stationCoordinateLabel(_ station: CanvasStation) -> String {
        switch station {
        case .zenith: return "Zenith Top"
        case .horizon: return "Horizon Center"
        case .nadir: return "Nadir Bottom"
        }
    }
}

// MARK: - 3. VDOMGalaxyOrbitMatrix (3x3 / 9x9 Cosmic Grid Preview Card)

/// 3x3 / 9x9 cosmic grid overview preview card with coordinate HUD,
/// interactive slot selection, LOD indicators, and bearing compass badge.
public struct VDOMGalaxyOrbitMatrix: View {
    @ObservedObject var spatialManager: SpatialPlaneManager = .shared
    public var isUniverse81: Bool
    public var onSelectSlot: (Int) -> Void

    @State private var hoveredSlot: Int? = nil

    public init(
        isUniverse81: Bool = false,
        onSelectSlot: @escaping (Int) -> Void = { _ in }
    ) {
        self.isUniverse81 = isUniverse81
        self.onSelectSlot = onSelectSlot
    }

    public var body: some View {
        let dim = isUniverse81 ? 9 : 3

        VDOMGlassPanel(cornerRadius: 20, borderWidth: 1.2, tintColor: Color(red: 0.05, green: 0.06, blue: 0.11)) {
            VStack(spacing: 12) {
                // Top Matrix HUD Bar
                HStack {
                    HStack(spacing: 6) {
                        Image(systemName: "square.grid.3x3.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.cyan)

                        Text(isUniverse81 ? "9×9 = 81 UNIVERSE MATRIX" : "3×3 SPATIAL GRID")
                            .font(.system(size: 11, weight: .heavy, design: .monospaced))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    let compass = SpatialPlaneManager.compassBearing(for: spatialManager.focusedPlaneIndex)
                    Text("SLOT \(spatialManager.focusedPlaneIndex) • \(compass)")
                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        .foregroundColor(.cyan)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.cyan.opacity(0.18)))
                }
                .padding(.horizontal, 14)
                .padding(.top, 12)

                Divider().background(Color.white.opacity(0.10))

                // Cosmic Grid Tiles
                VStack(spacing: isUniverse81 ? 2.5 : 5.0) {
                    ForEach(0..<dim, id: \.self) { row in
                        HStack(spacing: isUniverse81 ? 2.5 : 5.0) {
                            ForEach(0..<dim, id: \.self) { col in
                                let slot = isUniverse81 ?
                                    SpatialPlaneManager.indexForUniverse(col: col, row: row) :
                                    SpatialPlaneManager.indexForGrid(col: col, row: row)
                                matrixTile(slot: slot, col: col, row: row)
                            }
                        }
                    }
                }
                .padding(.horizontal, 12)

                Divider().background(Color.white.opacity(0.10))

                // Footer Metadata HUD
                HStack {
                    HStack(spacing: 4) {
                        Circle().fill(Color.green).frame(width: 5, height: 5)
                        Text("Hardware Active")
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.65))
                    }

                    Spacer()

                    HStack(spacing: 4) {
                        Circle().fill(Color.cyan).frame(width: 5, height: 5)
                        Text("Focused Slot")
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.65))
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 12)
            }
        }
        .frame(width: isUniverse81 ? 340 : 280)
    }

    @ViewBuilder
    private func matrixTile(slot: Int, col: Int, row: Int) -> some View {
        let isFocused = spatialManager.focusedPlaneIndex == slot
        let isCurrent = slot == MacDesktopsManager.shared.currentSpaceIndex
        let isHover = hoveredSlot == slot

        Button(action: {
            spatialManager.focusedPlaneIndex = slot
            onSelectSlot(slot)
            HapticFeedback.selection()
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: isUniverse81 ? 3.0 : 6.0, style: .continuous)
                    .fill(
                        isCurrent ? Color.green.opacity(0.35) :
                        (isFocused ? Color.cyan.opacity(0.40) :
                         (isHover ? Color.white.opacity(0.20) : Color.white.opacity(0.08)))
                    )

                if !isUniverse81 {
                    VStack(spacing: 2) {
                        Text("\(slot)")
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundColor(isFocused ? .cyan : (isCurrent ? .green : .white))

                        Text("[\(col),\(row)]")
                            .font(.system(size: 8, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.55))
                    }
                }
            }
            .frame(
                width: isUniverse81 ? 26 : 72,
                height: isUniverse81 ? 20 : 54
            )
            .overlay(
                RoundedRectangle(cornerRadius: isUniverse81 ? 3.0 : 6.0, style: .continuous)
                    .strokeBorder(
                        isFocused ? Color.cyan : (isCurrent ? Color.green : Color.white.opacity(0.12)),
                        lineWidth: isFocused ? 1.5 : 0.8
                    )
            )
            .shadow(color: isFocused ? Color.cyan.opacity(0.6) : .clear, radius: 4)
        }
        .buttonStyle(.plain)
        .onHover { h in
            if h { hoveredSlot = slot } else if hoveredSlot == slot { hoveredSlot = nil }
        }
    }
}

// MARK: - 4. VDOMPromptBar (Multimodal Omni-Prompt Bar)

/// Ultra-sleek multimodal prompt bar with model badge selector,
/// real-time voice pulse visualizer, attachment triggers, and responsive action buttons.
public struct VDOMPromptBar: View {
    @Binding public var promptText: String
    public var selectedModel: String
    public var availableModels: [String]
    public var isListening: Bool
    public var onSelectModel: (String) -> Void
    public var onToggleVoice: () -> Void
    public var onAttachMedia: () -> Void
    public var onSubmit: (String) -> Void
    public var onClear: () -> Void

    @State private var voicePulsePhase: CGFloat = 0.0

    public init(
        promptText: Binding<String>,
        selectedModel: String = "Claude 3.5 Sonnet",
        availableModels: [String] = ["Claude 3.5 Sonnet", "GPT-4o Omnimodal", "DeepSeek-R1 Cosmic", "Local Qwen 2.5 (32B)"],
        isListening: Bool = false,
        onSelectModel: @escaping (String) -> Void = { _ in },
        onToggleVoice: @escaping () -> Void = {},
        onAttachMedia: @escaping () -> Void = {},
        onSubmit: @escaping (String) -> Void = { _ in },
        onClear: @escaping () -> Void = {}
    ) {
        self._promptText = promptText
        self.selectedModel = selectedModel
        self.availableModels = availableModels
        self.isListening = isListening
        self.onSelectModel = onSelectModel
        self.onToggleVoice = onToggleVoice
        self.onAttachMedia = onAttachMedia
        self.onSubmit = onSubmit
        self.onClear = onClear
    }

    public var body: some View {
        VDOMGlassPanel(cornerRadius: 22, borderWidth: 1.2, tintColor: Color(red: 0.07, green: 0.09, blue: 0.16)) {
            VStack(spacing: 8) {
                // Top Accessory Bar (Model Selector & Voice Wave)
                HStack(spacing: 10) {
                    // Model Dropdown Badge
                    Menu {
                        ForEach(availableModels, id: \.self) { model in
                            Button(action: {
                                onSelectModel(model)
                                HapticFeedback.selection()
                            }) {
                                HStack {
                                    Text(model)
                                    if model == selectedModel {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Circle().fill(Color.purple).frame(width: 6, height: 6)
                            Text(selectedModel)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4.5)
                        .background(Capsule().fill(Color.purple.opacity(0.22)))
                        .overlay(Capsule().strokeBorder(Color.purple.opacity(0.45), lineWidth: 0.8))
                    }
                    .menuStyle(.borderlessButton)

                    // Voice Pulse Indicator (When active)
                    if isListening {
                        HStack(spacing: 3) {
                            ForEach(0..<5) { index in
                                RoundedRectangle(cornerRadius: 1.5)
                                    .fill(Color.cyan)
                                    .frame(width: 3, height: 6 + 10 * abs(sin(voicePulsePhase + Double(index) * 0.6)))
                            }
                            Text("LISTENING...")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(.cyan)
                                .padding(.leading, 2)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3.5)
                        .background(Capsule().fill(Color.cyan.opacity(0.18)))
                    }

                    Spacer()

                    // Multimodal Indicator
                    HStack(spacing: 4) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.yellow)
                        Text("MULTIMODAL VDOM")
                            .font(.system(size: 9, weight: .heavy, design: .monospaced))
                            .foregroundColor(.yellow.opacity(0.9))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.yellow.opacity(0.14)))
                }
                .padding(.horizontal, 14)
                .padding(.top, 10)

                // Main Prompt Text Input Row
                HStack(spacing: 10) {
                    // Media / Attachment Trigger
                    Button(action: {
                        onAttachMedia()
                        HapticFeedback.tick()
                    }) {
                        Image(systemName: "paperclip.circle.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.cyan.opacity(0.85))
                    }
                    .buttonStyle(.plain)
                    .help("Attach screenshots, files, or imagery")

                    // Live Text Input Field
                    TextField("Ask Genie AI, summon apps, or script virtual DOM components...", text: $promptText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 13.5, weight: .medium, design: .rounded))
                        .foregroundColor(.white)
                        .onSubmit {
                            if !promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                onSubmit(promptText)
                            }
                        }

                    // Clear Button
                    if !promptText.isEmpty {
                        Button(action: {
                            promptText = ""
                            onClear()
                            HapticFeedback.tick()
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .buttonStyle(.plain)
                    }

                    // Voice Dictation Button
                    Button(action: {
                        onToggleVoice()
                        HapticFeedback.selection()
                    }) {
                        ZStack {
                            Circle()
                                .fill(isListening ? Color.cyan : Color.white.opacity(0.10))
                                .frame(width: 28, height: 28)

                            Image(systemName: isListening ? "mic.fill" : "mic")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(isListening ? .black : .white)
                        }
                    }
                    .buttonStyle(.plain)
                    .help("Toggle Voice Prompt")

                    // Submit Action Button
                    Button(action: {
                        if !promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            onSubmit(promptText)
                            HapticFeedback.success()
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(
                                    promptText.isEmpty ?
                                    Color.white.opacity(0.12) :
                                    Color.cyan
                                )
                                .frame(width: 28, height: 28)

                            Image(systemName: "arrow.up")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(promptText.isEmpty ? .white.opacity(0.4) : .black)
                        }
                    }
                    .buttonStyle(.plain)
                    .disabled(promptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 10)
            }
        }
        .frame(maxWidth: 680)
        .onAppear {
            withAnimation(.linear(duration: 1.0).repeatForever(autoreverses: false)) {
                voicePulsePhase = .pi * 2
            }
        }
    }
}

// MARK: - 5. VDOMLayerCard (Photoshop Layer Inspector Item & Stack)

/// Photoshop layer inspector card snippet with blend mode selector,
/// opacity slider, lock toggle, eye visibility toggle, and layer type badge.
public struct VDOMLayerCard: View {
    public let layerItem: GraphicLayerItem
    public let isSelected: Bool
    public var onSelect: () -> Void
    public var onToggleVisibility: () -> Void
    public var onToggleLock: () -> Void
    public var onOpacityChange: (Double) -> Void
    public var onBlendModeChange: (PhotoshopBlendMode) -> Void
    public var onDelete: () -> Void

    public init(
        layerItem: GraphicLayerItem,
        isSelected: Bool = false,
        onSelect: @escaping () -> Void = {},
        onToggleVisibility: @escaping () -> Void = {},
        onToggleLock: @escaping () -> Void = {},
        onOpacityChange: @escaping (Double) -> Void = { _ in },
        onBlendModeChange: @escaping (PhotoshopBlendMode) -> Void = { _ in },
        onDelete: @escaping () -> Void = {}
    ) {
        self.layerItem = layerItem
        self.isSelected = isSelected
        self.onSelect = onSelect
        self.onToggleVisibility = onToggleVisibility
        self.onToggleLock = onToggleLock
        self.onOpacityChange = onOpacityChange
        self.onBlendModeChange = onBlendModeChange
        self.onDelete = onDelete
    }

    public var body: some View {
        HStack(spacing: 8) {
            // Eye Visibility Toggle
            Button(action: {
                onToggleVisibility()
            }) {
                Image(systemName: layerItem.isVisible ? "eye.fill" : "eye.slash")
                    .font(.system(size: 12))
                    .foregroundColor(layerItem.isVisible ? .white.opacity(0.85) : .white.opacity(0.25))
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)

            // Layer Color Badge / Thumbnail Icon
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(layerItem.type.accentColor.opacity(0.25))
                    .frame(width: 28, height: 28)

                Image(systemName: layerItem.type.iconName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(layerItem.type.accentColor)
            }

            // Layer Name & Type Label
            VStack(alignment: .leading, spacing: 2) {
                Text(layerItem.name)
                    .font(.system(size: 12.5, weight: isSelected ? .bold : .medium, design: .rounded))
                    .foregroundColor(layerItem.isVisible ? .white : .white.opacity(0.4))
                    .lineLimit(1)

                HStack(spacing: 4) {
                    Text(layerItem.type.rawValue.components(separatedBy: " ").first ?? "Layer")
                        .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.50))

                    Text("•")
                        .font(.system(size: 8))
                        .foregroundColor(.white.opacity(0.30))

                    Text("\(Int(layerItem.opacity * 100))%")
                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        .foregroundColor(.cyan)
                }
            }

            Spacer()

            Menu {
                ForEach(PhotoshopBlendMode.allCases) { mode in
                    Button(action: {
                        onBlendModeChange(mode)
                    }) {
                        Text(mode.rawValue)
                    }
                }
            } label: {
                Text(layerItem.blendMode.rawValue)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.80))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.white.opacity(0.10)))
            }
            .menuStyle(.borderlessButton)

            // Lock Toggle Button
            Button(action: {
                onToggleLock()
            }) {
                Image(systemName: layerItem.isLocked ? "lock.fill" : "lock.open")
                    .font(.system(size: 10))
                    .foregroundColor(layerItem.isLocked ? .yellow : .white.opacity(0.3))
                    .frame(width: 18, height: 18)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(isSelected ? Color.cyan.opacity(0.18) : Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(isSelected ? Color.cyan.opacity(0.60) : Color.white.opacity(0.08), lineWidth: isSelected ? 1.2 : 0.8)
        )
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
    }
}

// MARK: - 6. VDOMSmartWindowAnchor (Snap-To-Grid Window Anchor Card)

/// Snap-to-grid window card with coordinate HUD, live preview,
/// anchor pin buttons (Top, Bottom, Full, Split), and target desktop sector selector.
public struct VDOMSmartWindowAnchor: View {
    public var windowTitle: String
    public var ownerName: String
    public var currentSector: Int
    public var currentCoordinates: CGPoint
    public var onSnapAnchor: (SmartWindowAnchorPosition) -> Void
    public var onMoveToSector: (Int) -> Void

    @State private var activeAnchor: SmartWindowAnchorPosition = .center

    public init(
        windowTitle: String = "Xcode — SpatialVirtualDOMEngine.swift",
        ownerName: String = "Xcode",
        currentSector: Int = 5,
        currentCoordinates: CGPoint = CGPoint(x: 1440, y: 900),
        onSnapAnchor: @escaping (SmartWindowAnchorPosition) -> Void = { _ in },
        onMoveToSector: @escaping (Int) -> Void = { _ in }
    ) {
        self.windowTitle = windowTitle
        self.ownerName = ownerName
        self.currentSector = currentSector
        self.currentCoordinates = currentCoordinates
        self.onSnapAnchor = onSnapAnchor
        self.onMoveToSector = onMoveToSector
    }

    public var body: some View {
        VDOMGlassPanel(cornerRadius: 18, borderWidth: 1.2, tintColor: Color(red: 0.08, green: 0.10, blue: 0.17)) {
            VStack(spacing: 10) {
                // Header Bar
                HStack(spacing: 8) {
                    HStack(spacing: 5) {
                        Circle().fill(Color.red.opacity(0.9)).frame(width: 9, height: 9)
                        Circle().fill(Color.yellow.opacity(0.9)).frame(width: 9, height: 9)
                        Circle().fill(Color.green.opacity(0.9)).frame(width: 9, height: 9)
                    }

                    Text(windowTitle)
                        .font(.system(size: 11.5, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(1)

                    Spacer()

                    // Sector Badge
                    Menu {
                        ForEach(1...9, id: \.self) { sector in
                            Button("Move to Sector \(sector) • \(SpatialPlaneManager.compassBearing(for: sector))") {
                                onMoveToSector(sector)
                                HapticFeedback.selection()
                            }
                        }
                    } label: {
                        Text("Sector \(currentSector)")
                            .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                            .foregroundColor(.cyan)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.cyan.opacity(0.18)))
                    }
                    .menuStyle(.borderlessButton)
                }
                .padding(.horizontal, 12)
                .padding(.top, 10)

                Divider().background(Color.white.opacity(0.10))

                // Coordinate HUD & Mini Anchor Map
                HStack(spacing: 16) {
                    // Coordinate Telemetry
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 4) {
                            Text("APP:")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.5))
                            Text(ownerName)
                                .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                        }

                        HStack(spacing: 4) {
                            Text("CANVAS:")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.5))
                            Text("[\(Int(currentCoordinates.x)), \(Int(currentCoordinates.y))]")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(.cyan)
                        }

                        HStack(spacing: 4) {
                            Text("ANCHOR:")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.5))
                            Text(activeAnchor.rawValue.uppercased())
                                .font(.system(size: 9.5, weight: .heavy, design: .monospaced))
                                .foregroundColor(.yellow)
                        }
                    }

                    Spacer()

                    // 3x3 Interactive Anchor Grid Selector
                    VStack(spacing: 3) {
                        HStack(spacing: 3) {
                            anchorButton(.topLeft, icon: "arrow.up.left")
                            anchorButton(.topCenter, icon: "arrow.up")
                            anchorButton(.topRight, icon: "arrow.up.right")
                        }
                        HStack(spacing: 3) {
                            anchorButton(.leftSplit, icon: "rectangle.righthalf.inset.filled")
                            anchorButton(.center, icon: "viewfinder")
                            anchorButton(.rightSplit, icon: "rectangle.leadinghalf.inset.filled")
                        }
                        HStack(spacing: 3) {
                            anchorButton(.bottomLeft, icon: "arrow.down.left")
                            anchorButton(.bottomCenter, icon: "arrow.down")
                            anchorButton(.bottomRight, icon: "arrow.down.right")
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 10)
            }
        }
        .frame(width: 320)
    }

    @ViewBuilder
    private func anchorButton(_ position: SmartWindowAnchorPosition, icon: String) -> some View {
        let isSelected = activeAnchor == position
        Button(action: {
            activeAnchor = position
            onSnapAnchor(position)
            HapticFeedback.tick()
        }) {
            ZStack {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(isSelected ? Color.cyan : Color.white.opacity(0.08))
                    .frame(width: 26, height: 22)

                Image(systemName: icon)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(isSelected ? .black : .white.opacity(0.8))
            }
        }
        .buttonStyle(.plain)
        .help("Snap to \(position.rawValue)")
    }
}

public enum SmartWindowAnchorPosition: String, CaseIterable, Sendable {
    case topLeft = "Top Left"
    case topCenter = "Top Center"
    case topRight = "Top Right"
    case leftSplit = "Left Half"
    case center = "Center Full"
    case rightSplit = "Right Half"
    case bottomLeft = "Bottom Left"
    case bottomCenter = "Bottom Center"
    case bottomRight = "Bottom Right"
}

// MARK: - Unified Component Snippets Showcase Canvas View

/// Standalone interactive canvas demonstrating all 6 modular VDOM Component Snippets.
public struct SwiftVDOMComponentSnippetsShowcase: View {
    @ObservedObject var vdomCore: SwiftVDOMCore = .shared
    @ObservedObject var compositor: PhotoshopLayerCompositorEngine = .shared
    @ObservedObject var spatialManager: SpatialPlaneManager = .shared
    @ObservedObject var stationEngine: ContinuousStationScrollEngine = .shared

    @State private var promptText: String = ""
    @State private var selectedModel: String = "Claude 3.5 Sonnet"
    @State private var isListeningVoice: Bool = false
    @State private var isUniverse81Active: Bool = false
    @State private var activeStation: CanvasStation = .horizon

    public init() {}

    public var body: some View {
        ZStack {
            // Cosmic Deep Space Backdrop
            Color(red: 0.03, green: 0.04, blue: 0.08)
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: true) {
                VStack(spacing: 24) {
                    // Title & Architecture Header
                    VStack(spacing: 6) {
                        HStack(spacing: 8) {
                            Image(systemName: "square.stack.3d.up.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.cyan)

                            Text("SWIFT VDOM MODULAR COMPONENT SUITE")
                                .font(.system(size: 18, weight: .black, design: .monospaced))
                                .foregroundColor(.white)
                        }

                        Text("React-like composable component snippets connected to SwiftVDOMCore & PhotoshopLayerCompositorEngine")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.65))
                    }
                    .padding(.top, 24)

                    // 1. Omni-Prompt Bar Snippet
                    VStack(alignment: .leading, spacing: 8) {
                        snippetHeader(title: "4. VDOMPromptBar (Multimodal AI Input)", tag: "Input / AI")
                        VDOMPromptBar(
                            promptText: $promptText,
                            selectedModel: selectedModel,
                            isListening: isListeningVoice,
                            onSelectModel: { selectedModel = $0 },
                            onToggleVoice: { isListeningVoice.toggle() },
                            onAttachMedia: {},
                            onSubmit: { text in
                                promptText = ""
                            }
                        )
                    }

                    // 2. Dual Column: Station Filmstrip & Galaxy Matrix
                    HStack(alignment: .top, spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            snippetHeader(title: "2. VDOMStationFilmstrip", tag: "3-Station Scroll")
                            VDOMStationFilmstrip(selectedStation: activeStation) { st in
                                activeStation = st
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                snippetHeader(title: "3. VDOMGalaxyOrbitMatrix", tag: isUniverse81Active ? "9x9 Universe" : "3x3 Grid")
                                Spacer()
                                Toggle("81 Universe", isOn: $isUniverse81Active)
                                    .toggleStyle(.switch)
                                    .font(.caption)
                            }
                            VDOMGalaxyOrbitMatrix(isUniverse81: isUniverse81Active) { slot in
                                spatialManager.focusedPlaneIndex = slot
                            }
                        }
                    }

                    // 3. Dual Column: Layer Inspector & Window Anchor
                    HStack(alignment: .top, spacing: 20) {
                        // Photoshop Layer Stack
                        VStack(alignment: .leading, spacing: 8) {
                            snippetHeader(title: "5. VDOMLayerCard (Photoshop Layer Stack)", tag: "Compositor")
                            VDOMGlassPanel(cornerRadius: 18, tintColor: Color(red: 0.06, green: 0.08, blue: 0.14)) {
                                VStack(spacing: 8) {
                                    HStack {
                                        Text("LAYERS (\(compositor.stack.layers.count))")
                                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                                            .foregroundColor(.white)
                                        Spacer()
                                        Button(action: {
                                            compositor.addNewLayer(type: .vectorGraphic, name: "New Vector Layer")
                                        }) {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.system(size: 14))
                                                .foregroundColor(.cyan)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.top, 10)

                                    Divider().background(Color.white.opacity(0.10))

                                    VStack(spacing: 6) {
                                        ForEach(compositor.stack.inspectorLayersTopToBottom) { layer in
                                            VDOMLayerCard(
                                                layerItem: layer,
                                                isSelected: compositor.selectedLayerId == layer.id,
                                                onSelect: { compositor.selectLayer(id: layer.id) },
                                                onToggleVisibility: { compositor.toggleVisibility(for: layer.id) },
                                                onToggleLock: { compositor.toggleLock(for: layer.id) },
                                                onOpacityChange: { compositor.updateOpacity($0, for: layer.id) },
                                                onBlendModeChange: { compositor.updateBlendMode($0, for: layer.id) },
                                                onDelete: { compositor.deleteLayer(id: layer.id) }
                                            )
                                        }
                                    }
                                    .padding(.horizontal, 10)
                                    .padding(.bottom, 10)
                                }
                            }
                            .frame(width: 380)
                        }

                        // Smart Window Anchor
                        VStack(alignment: .leading, spacing: 8) {
                            snippetHeader(title: "6. VDOMSmartWindowAnchor", tag: "Spatial HUD")
                            VDOMSmartWindowAnchor(
                                windowTitle: "GenieStudio — VirtualDOM.swift",
                                ownerName: "GenieStudio",
                                currentSector: spatialManager.focusedPlaneIndex,
                                currentCoordinates: CGPoint(x: 1440, y: 900),
                                onSnapAnchor: { _ in },
                                onMoveToSector: { sector in
                                    spatialManager.focusedPlaneIndex = sector
                                }
                            )
                        }
                    }
                }
                .padding(24)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func snippetHeader(title: String, tag: String) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.system(size: 12.5, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text(tag)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(.cyan)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Capsule().fill(Color.cyan.opacity(0.18)))
        }
    }
}
