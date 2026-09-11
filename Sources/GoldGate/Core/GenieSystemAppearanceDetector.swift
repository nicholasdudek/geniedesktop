// MARK: - GenieSystemAppearanceDetector.swift
// Golden Gate Engineering • © 2026 Nicholas M. Dudek
// Apache License, Version 2.0 (Apache-2.0)
//
// Centralized system detector for macOS Dynamic Text Size (Accessibility & System Settings),
// display screen geometry / hardware camera notch classification, and system appearance
// themes (Apple Finder Folder Blue, System Accent Colors, and specular glass materials).

import AppKit
import Foundation
import SwiftUI
import Combine

/// Classification of the active display hardware
public enum MacScreenCategory: String, Sendable {
    case compactLaptop     // 13" MacBook Air/Pro (< 1440 pt width)
    case standardLaptop    // 14"–16" MacBook Pro (1440 ..< 1800 pt width)
    case desktop           // 24"–27" iMac / Studio Display (1800 ..< 2600 pt width)
    case ultraWideOr4K     // 5K Pro Display XDR / 4K / Ultra-wide (>= 2600 pt width)

    public var adaptiveScale: CGFloat {
        switch self {
        case .compactLaptop:  return 0.95
        case .standardLaptop: return 1.00
        case .desktop:        return 1.06
        case .ultraWideOr4K:  return 1.14
        }
    }
}

/// Centralized ObservableObject monitoring macOS Screen Size, System Settings Text Size,
/// and System Appearance Theme (Folder Colors, Accent Colors, and Glass Highlights).
@MainActor
public final class GenieSystemAppearanceDetector: ObservableObject {
    public static let shared = GenieSystemAppearanceDetector()

    // ── Screen Geometry ──
    @Published public private(set) var screenSize: CGSize = CGSize(width: 1728, height: 1117)
    @Published public private(set) var visibleScreenSize: CGSize = CGSize(width: 1728, height: 1080)
    @Published public private(set) var backingScaleFactor: CGFloat = 2.0
    @Published public private(set) var hasNotch: Bool = false
    @Published public private(set) var notchTopInset: CGFloat = 0.0
    @Published public private(set) var notchWidth: CGFloat = 0.0
    @Published public private(set) var notchRect: NSRect = .zero
    @Published public private(set) var screenCategory: MacScreenCategory = .standardLaptop

    // ── System Text Size Scaling ──
    @Published public private(set) var systemTextPointSize: CGFloat = 13.0
    @Published public private(set) var systemTextScale: CGFloat = 1.0
    @Published public private(set) var screenScaleFactor: CGFloat = 1.0
    @Published public private(set) var effectiveTextScale: CGFloat = 1.0

    // ── System Appearance & Folder Theme ──
    @Published public private(set) var isDarkMode: Bool = true
    @Published public private(set) var systemAccentColor: Color = .blue
    @Published public private(set) var folderBlueTop: Color = Color(red: 0.16, green: 0.65, blue: 0.98)
    @Published public private(set) var folderBlueBottom: Color = Color(red: 0.0, green: 0.44, blue: 0.88)
    public var systemFolderBlueTop: Color { folderBlueTop }
    public var systemFolderBlueBottom: Color { folderBlueBottom }

    private var cancellables = Set<AnyCancellable>()

    private init() {
        refreshAll()
        setupListeners()
    }

    // MARK: - Setup Observers
    private func setupListeners() {
        // 1. Screen changes (resolution, connect/disconnect, scale change)
        NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in self?.refreshScreenGeometry() }
            }
            .store(in: &cancellables)

        // 2. System Appearance / Color changes
        NotificationCenter.default.publisher(for: NSColor.systemColorsDidChangeNotification)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in self?.refreshAppearance() }
            }
            .store(in: &cancellables)

        // 3. Accessibility text and display option changes
        NotificationCenter.default.publisher(for: NSWorkspace.accessibilityDisplayOptionsDidChangeNotification)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in self?.refreshTextScale() }
            }
            .store(in: &cancellables)

        // 4. Workspace activation
        NotificationCenter.default.publisher(for: NSWorkspace.didActivateApplicationNotification)
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in self?.refreshAll() }
            }
            .store(in: &cancellables)
    }

    public func refreshAll() {
        refreshScreenGeometry()
        refreshTextScale()
        refreshAppearance()
    }

    // MARK: - Screen Geometry
    public func refreshScreenGeometry() {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else { return }

        self.screenSize = screen.frame.size
        self.visibleScreenSize = screen.visibleFrame.size
        self.backingScaleFactor = screen.backingScaleFactor

        // Classify screen width
        let w = screen.frame.width
        if w < 1440 {
            self.screenCategory = .compactLaptop
        } else if w < 1800 {
            self.screenCategory = .standardLaptop
        } else if w < 2600 {
            self.screenCategory = .desktop
        } else {
            self.screenCategory = .ultraWideOr4K
        }
        self.screenScaleFactor = self.screenCategory.adaptiveScale

        // Analyze hardware notch geometry according to Apple's latest specs
        let notchInfo = ScreenNotchInfo.forScreen(screen)
        self.hasNotch = notchInfo.hasNotch
        self.notchTopInset = screen.safeAreaInsets.top
        self.notchWidth = notchInfo.notchWidth
        self.notchRect = notchInfo.notchRect

        recomputeEffectiveTextScale()
    }

    // MARK: - Text Scale Detection
    public func refreshTextScale() {
        // Read dynamic type body font configured in macOS System Settings -> Accessibility -> Display
        let bodyFont = NSFont.preferredFont(forTextStyle: .body)
        let pointSize = bodyFont.pointSize
        self.systemTextPointSize = pointSize

        // 13.0 pt is standard macOS system default body font size
        let rawRatio = pointSize / 13.0
        self.systemTextScale = max(0.80, min(1.75, rawRatio))

        recomputeEffectiveTextScale()
    }

    private func recomputeEffectiveTextScale() {
        self.effectiveTextScale = self.systemTextScale * self.screenScaleFactor
    }

    // MARK: - Appearance & Folder Colors
    public func refreshAppearance() {
        let app = NSApp.effectiveAppearance.name
        self.isDarkMode = (app == .darkAqua || app == .vibrantDark || app.rawValue.lowercased().contains("dark"))

        // System Accent Color from macOS System Settings -> Appearance
        let accentNS = NSColor.controlAccentColor
        self.systemAccentColor = Color(nsColor: accentNS)

        // Apple Finder Folder Colors:
        // Authentic Apple folder icon gradients with deep contrast & vibrant specular tones
        if isDarkMode {
            self.folderBlueTop = Color(red: 0.18, green: 0.64, blue: 0.98)
            self.folderBlueBottom = Color(red: 0.04, green: 0.46, blue: 0.90)
        } else {
            self.folderBlueTop = Color(red: 0.12, green: 0.60, blue: 0.96)
            self.folderBlueBottom = Color(red: 0.02, green: 0.40, blue: 0.84)
        }
    }

    // MARK: - Font & Point Sizing Helpers
    /// Returns a font dynamically scaled by macOS System Settings text scale + screen size multiplier
    public func scaledFont(
        size: CGFloat,
        weight: Font.Weight = .regular,
        design: Font.Design = .default,
        userZoom: Double = 1.0
    ) -> Font {
        let finalSize = scaledPoint(size, userZoom: userZoom)
        return Font.system(size: finalSize, weight: weight, design: design)
    }

    /// Returns a point size scaled by macOS System Settings text scale + screen size multiplier
    public func scaledPoint(_ size: CGFloat, userZoom: Double = 1.0) -> CGFloat {
        let base = size * effectiveTextScale * CGFloat(userZoom)
        return (base * 2.0).rounded() / 2.0 // Round to half-points for crisp rendering
    }

    // MARK: - Gradients & Materials for Chat Bubbles

    /// Authentic macOS Finder Folder / System Accent Gradient for User Chat Bubbles
    public var folderBubbleGradient: LinearGradient {
        LinearGradient(
            colors: [folderBlueTop, folderBlueBottom],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Specular rim highlight for Folder / User Bubbles
    public var folderSpecularHighlight: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(0.65),
                Color.cyan.opacity(0.35),
                Color.white.opacity(0.12)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Deep authentic liquid glass gradient for Assistant / Genie Chat Bubbles
    public var assistantBubbleGradient: LinearGradient {
        if isDarkMode {
            return LinearGradient(
                colors: [
                    Color(red: 0.12, green: 0.15, blue: 0.22).opacity(0.55),
                    Color(red: 0.06, green: 0.08, blue: 0.14).opacity(0.68)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [
                    Color(red: 0.94, green: 0.96, blue: 0.99).opacity(0.72),
                    Color(red: 0.88, green: 0.91, blue: 0.96).opacity(0.82)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    /// Specular rim highlight for Assistant / Genie Chat Bubbles with subtle folder-blue rim tint
    public var assistantSpecularHighlight: LinearGradient {
        LinearGradient(
            colors: [
                Color.white.opacity(isDarkMode ? 0.32 : 0.60),
                folderBlueTop.opacity(isDarkMode ? 0.24 : 0.15),
                Color.white.opacity(isDarkMode ? 0.08 : 0.20)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}
