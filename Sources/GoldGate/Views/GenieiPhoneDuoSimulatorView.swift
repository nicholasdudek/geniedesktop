// MARK: - GenieiPhoneDuoSimulatorView.swift
// Golden Gate Engineering • © 2026 Nicholas M. Dudek
//
// iPhone & Duo Fold Simulator Workstation.
// Runs an interactive iPhone-style browser for streaming movies, YouTube, and media
// alongside code editing, with Duo Fold dual-screen support, landscape movie theater mode,
// and direct integration with native Xcode simctl and macOS iPhone Mirroring.

import AppKit
import Foundation
import SwiftUI
import WebKit
import Combine

// MARK: - 📱 Universal Simulated Device Type
public enum SimulatedDeviceType: String, CaseIterable, Identifiable {
    case iphone = "iPhone"
    case ipad = "iPad Pro"
    case android = "Android Play Store"
    case windows = "Windows 11"

    public var id: String { rawValue }

    public var icon: String {
        switch self {
        case .iphone: return "iphone"
        case .ipad: return "ipad"
        case .android: return "phone.badge.waveform.fill"
        case .windows: return "macwindow"
        }
    }
}

// MARK: - 📱 iPhone Duo Simulator State
@MainActor
public final class iPhoneDuoSimulatorManager: ObservableObject {
    public static let shared = iPhoneDuoSimulatorManager()

    @Published public var primaryURLString: String = "https://www.youtube.com"
    @Published public var secondaryURLString: String = "https://apple.com"
    @Published public var deviceType: SimulatedDeviceType = .iphone
    @Published public var isDuoScreenMode: Bool = false
    @Published public var isLandscapeMovieMode: Bool = false
    @Published public var isLoading: Bool = false
    @Published public var canGoBack: Bool = false
    @Published public var canGoForward: Bool = false
    @Published public var pageTitle: String = "Universal Browser"
    @Published public var simctlConsoleLog: String = "simctl: ready"

    private init() {
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("GenieiPhoneSimulatorOpenURL"),
            object: nil,
            queue: .main
        ) { [weak self] notif in
            guard let url = notif.object as? String, !url.isEmpty else { return }
            Task { @MainActor [weak self] in
                self?.loadURL(url)
            }
        }

        NotificationCenter.default.addObserver(
            forName: NSNotification.Name("GenieDuoSimulatorSetMode"),
            object: nil,
            queue: .main
        ) { [weak self] notif in
            let mode = (notif.object as? String ?? "").lowercased()
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                if mode.contains("duo") {
                    self.isDuoScreenMode = true
                } else if mode.contains("movie") || mode.contains("landscape") {
                    self.isLandscapeMovieMode = true
                } else if mode.contains("single") || mode.contains("portrait") {
                    self.isDuoScreenMode = false
                    self.isLandscapeMovieMode = false
                }
            }
        }
    }

    public func loadURL(_ string: String) {
        var clean = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if !clean.lowercased().hasPrefix("http://") && !clean.lowercased().hasPrefix("https://") {
            if clean.contains(".") && !clean.contains(" ") {
                clean = "https://" + clean
            } else {
                clean = "https://www.google.com/search?q=" + (clean.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? clean)
            }
        }
        self.primaryURLString = clean
    }

    // MARK: - Native Xcode Simctl Integration
    public func launchNativeXcodeSimulator() {
        guard GenieCapabilities.canSpawnSubprocesses else { return }
        let simAppPath = "/Applications/Xcode-beta.app/Contents/Developer/Applications/Simulator.app"
        let fallbackPath = "/Applications/Xcode.app/Contents/Developer/Applications/Simulator.app"
        let fileManager = FileManager.default

        if fileManager.fileExists(atPath: simAppPath) {
            NSWorkspace.shared.open(URL(fileURLWithPath: simAppPath))
        } else if fileManager.fileExists(atPath: fallbackPath) {
            NSWorkspace.shared.open(URL(fileURLWithPath: fallbackPath))
        } else {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            task.arguments = ["-a", "Simulator"]
            try? task.run()
        }
    }

    public func openURLInBootedSimulator(url: String) {
        guard GenieCapabilities.canSpawnSubprocesses else { return }
        Task.detached(priority: .userInitiated) {
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
            proc.arguments = ["simctl", "openurl", "booted", url]
            try? proc.run()
            proc.waitUntilExit()
            await MainActor.run {
                self.simctlConsoleLog = "simctl openurl booted: exit \(proc.terminationStatus)"
            }
        }
    }

    public func bootFirstSimulator() {
        guard GenieCapabilities.canSpawnSubprocesses else { return }
        Task.detached(priority: .userInitiated) {
            let proc = Process()
            proc.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
            proc.arguments = ["simctl", "boot", "booted"]
            try? proc.run()
            proc.waitUntilExit()
            await MainActor.run {
                self.simctlConsoleLog = "simctl boot: exit \(proc.terminationStatus)"
            }
        }
    }
}

// MARK: - 🎬 Genie iPhone Duo Simulator Workstation View
public struct GenieiPhoneDuoSimulatorView: View {
    @ObservedObject private var manager = iPhoneDuoSimulatorManager.shared
    @State private var inputURL: String = "https://www.youtube.com"
    @State private var dynamicIslandExpanded: Bool = false
    @State private var currentTime = Date()
    @State private var exportNotification: String? = nil
    @State private var lastExportedPath: String? = nil
    @State private var isExportingPlayStore: Bool = false

    private let clockTimer = Timer.publish(every: 1.0, on: .main, in: .common).autoconnect()

    public init() {}

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm"
        return formatter.string(from: currentTime)
    }

    private var fullDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE MMM d"
        return formatter.string(from: currentTime)
    }

    public var body: some View {
        VStack(spacing: 0) {
            // 1. Top Simulator Chrome Toolbar
            simulatorToolbar

            // Notification Banner for Export / Actions
            if let note = exportNotification {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                    Text(note)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                    if let path = lastExportedPath {
                        Button("Reveal in Finder") {
                            NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: path)
                        }
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.cyan)
                        .buttonStyle(.plain)
                    }
                    Button(action: { exportNotification = nil }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(Color.green.opacity(0.18))
                .overlay(Rectangle().stroke(Color.green.opacity(0.3), lineWidth: 1))
            }

            // 2. Main Simulator Device Canvas
            GeometryReader { geo in
                ZStack {
                    Color.black.opacity(0.40)

                    if manager.isDuoScreenMode {
                        // Duo Fold Dual Screen Layout (Two Foldable Phones Side-by-Side)
                        duoScreenView(size: geo.size)
                    } else {
                        // Single Multi-Device Hardware Shell
                        singleScreenView(size: geo.size)
                    }
                }
            }
        }
        .background(Color.black.opacity(0.85))
        .onAppear {
            inputURL = manager.primaryURLString
        }
        .onReceive(clockTimer) { now in
            currentTime = now
        }
    }

    // MARK: - 1. Top Simulator Chrome Toolbar
    private var simulatorToolbar: some View {
        HStack(spacing: 8) {
            // Device Type Switcher Pills
            HStack(spacing: 3) {
                ForEach(SimulatedDeviceType.allCases) { type in
                    Button(action: {
                        HapticFeedback.selection()
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                            manager.deviceType = type
                        }
                    }) {
                        HStack(spacing: 3.5) {
                            Image(systemName: type.icon)
                                .font(.system(size: 9.5))
                            Text(type.rawValue)
                                .font(.system(size: 9.5, weight: manager.deviceType == type ? .bold : .medium))
                        }
                        .foregroundColor(manager.deviceType == type ? .white : .white.opacity(0.65))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3.5)
                        .background(Capsule().fill(manager.deviceType == type ? Color.cyan.opacity(0.32) : Color.white.opacity(0.06)))
                        .overlay(Capsule().stroke(manager.deviceType == type ? Color.cyan.opacity(0.8) : Color.white.opacity(0.12), lineWidth: 0.8))
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer()

            // Quick Movie / Video Stream Bookmarks
            HStack(spacing: 5) {
                quickStreamChip(title: "YouTube", icon: "play.rectangle.fill", url: "https://www.youtube.com", color: .red)
                quickStreamChip(title: "Netflix", icon: "film.fill", url: "https://www.netflix.com", color: .red)
                quickStreamChip(title: "Twitch", icon: "tv.fill", url: "https://www.twitch.tv", color: .purple)
                quickStreamChip(title: "Apple TV+", icon: "appletv.fill", url: "https://tv.apple.com", color: .white)
                quickStreamChip(title: "Localhost", icon: "network", url: "http://localhost:3000", color: .cyan)
            }

            Spacer()

            // View Controls & Store Packager
            HStack(spacing: 6) {
                // Google Play Store Packager Button
                Button(action: {
                    HapticFeedback.tick()
                    buildPlayStoreBundle()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: isExportingPlayStore ? "hourglass" : "shippingbox.fill")
                            .font(.system(size: 10))
                        Text(isExportingPlayStore ? "Packaging..." : "Build Play Store (.aab)")
                            .font(.system(size: 9.5, weight: .bold))
                    }
                    .foregroundColor(.green)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3.5)
                    .background(Capsule().fill(Color.green.opacity(0.18)))
                    .overlay(Capsule().stroke(Color.green.opacity(0.40), lineWidth: 0.8))
                }
                .buttonStyle(.plain)
                .disabled(isExportingPlayStore)
                .help("Scaffold Android Play Store App Bundle (.aab), Gradle build script, Target SDK 35, and upload checklist")

                // Landscape / Theater Movie Mode Toggle
                Button(action: {
                    HapticFeedback.selection()
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                        manager.isLandscapeMovieMode.toggle()
                        if manager.isLandscapeMovieMode {
                            manager.isDuoScreenMode = false
                        }
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: manager.isLandscapeMovieMode ? "rectangle.landscape.rotate" : "iphone")
                            .font(.system(size: 10))
                        Text(manager.isLandscapeMovieMode ? "Portrait" : "Movie Theater 🍿")
                            .font(.system(size: 9.5, weight: .semibold))
                    }
                    .foregroundColor(manager.isLandscapeMovieMode ? .yellow : .white.opacity(0.85))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3.5)
                    .background(Capsule().fill(manager.isLandscapeMovieMode ? Color.yellow.opacity(0.25) : Color.white.opacity(0.10)))
                    .overlay(Capsule().stroke(manager.isLandscapeMovieMode ? Color.yellow.opacity(0.5) : Color.white.opacity(0.15), lineWidth: 0.8))
                }
                .buttonStyle(.plain)
                .help("Rotate between Portrait and Landscape Movie Theater mode for watching videos")

                // Duo Fold Toggle
                Button(action: {
                    HapticFeedback.selection()
                    withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                        manager.isDuoScreenMode.toggle()
                        if manager.isDuoScreenMode {
                            manager.isLandscapeMovieMode = false
                        }
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "rectangle.split.2x1")
                            .font(.system(size: 10))
                        Text(manager.isDuoScreenMode ? "Single Device" : "Duo Screens 📖")
                            .font(.system(size: 9.5, weight: .semibold))
                    }
                    .foregroundColor(manager.isDuoScreenMode ? .cyan : .white.opacity(0.85))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3.5)
                    .background(Capsule().fill(manager.isDuoScreenMode ? Color.cyan.opacity(0.25) : Color.white.opacity(0.10)))
                    .overlay(Capsule().stroke(manager.isDuoScreenMode ? Color.cyan.opacity(0.5) : Color.white.opacity(0.15), lineWidth: 0.8))
                }
                .buttonStyle(.plain)
                .help("Toggle dual-screen Surface Duo / foldable phone mode")

                // Native Xcode Simulator Launcher
                Button(action: {
                    HapticFeedback.tick()
                    manager.launchNativeXcodeSimulator()
                    if let url = URL(string: manager.primaryURLString) {
                        manager.openURLInBootedSimulator(url: url.absoluteString)
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "play.circle.fill")
                            .font(.system(size: 10))
                        Text("Xcode Sim")
                            .font(.system(size: 9.5, weight: .semibold))
                    }
                    .foregroundColor(.green)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3.5)
                    .background(Capsule().fill(Color.green.opacity(0.15)))
                    .overlay(Capsule().stroke(Color.green.opacity(0.35), lineWidth: 0.8))
                }
                .buttonStyle(.plain)
                .help("Launch native Apple Xcode iOS Simulator application")
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.70))
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1),
            alignment: .bottom
        )
    }

    private func buildPlayStoreBundle() {
        isExportingPlayStore = true
        Task {
            let dest = ("~/Desktop/Developer/GeniePlayStore" as NSString).expandingTildeInPath
            let destURL = URL(fileURLWithPath: dest)
            let result = await GenieAndroidStorePackager.shared.scaffoldPlayStoreProject(outputDirectory: destURL)
            await MainActor.run {
                isExportingPlayStore = false
                switch result {
                case .success(let projectURL):
                    self.lastExportedPath = projectURL.path
                    self.exportNotification = "Android Play Store package scaffolded at \(projectURL.path)"
                case .failure(let error):
                    self.exportNotification = "Export error: \(error.localizedDescription)"
                }
            }
        }
    }

    private func quickStreamChip(title: String, icon: String, url: String, color: Color) -> some View {
        Button(action: {
            HapticFeedback.selection()
            manager.loadURL(url)
            inputURL = url
        }) {
            HStack(spacing: 3.5) {
                Image(systemName: icon)
                    .font(.system(size: 9))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 9.5, weight: .medium))
                    .foregroundColor(.white.opacity(0.90))
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Capsule().fill(Color.white.opacity(0.08)))
        }
        .buttonStyle(.plain)
    }

    // MARK: - 2. Single Screen View Router
    @ViewBuilder
    private func singleScreenView(size: CGSize) -> some View {
        switch manager.deviceType {
        case .iphone:
            iphoneHardwareShell(size: size)
        case .ipad:
            ipadHardwareShell(size: size)
        case .android:
            androidHardwareShell(size: size)
        case .windows:
            windowsHardwareShell(size: size)
        }
    }

    // MARK: - 📱 iPhone Hardware Shell
    @ViewBuilder
    private func iphoneHardwareShell(size: CGSize) -> some View {
        let isLandscape = manager.isLandscapeMovieMode
        let phoneWidth: CGFloat = isLandscape ? min(size.width - 40, max(640, size.height * 1.77)) : min(430, size.width - 40)
        let phoneHeight: CGFloat = isLandscape ? min(size.height - 40, phoneWidth / 1.77) : min(size.height - 30, phoneWidth * 2.16)

        ZStack {
            // iPhone Outer Hardware Frame
            RoundedRectangle(cornerRadius: isLandscape ? 36 : 48, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.15), Color(white: 0.08), Color(white: 0.12)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: isLandscape ? 36 : 48, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.white.opacity(0.40), Color.white.opacity(0.10), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2.5
                        )
                )
                .shadow(color: Color.black.opacity(0.7), radius: 24, y: 12)

            // Inner Display Surface
            VStack(spacing: 0) {
                // Top iOS Status Bar & Dynamic Island
                HStack {
                    Text(timeString)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.leading, 18)

                    Spacer()

                    // Dynamic Island
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.black)
                            .frame(width: 10, height: 10)
                            .overlay(Circle().fill(Color.blue.opacity(0.6)).frame(width: 4, height: 4))

                        if manager.isLoading {
                            ProgressView()
                                .scaleEffect(0.5)
                                .frame(width: 10, height: 10)
                        } else {
                            Image(systemName: "wave.3.right")
                                .font(.system(size: 8))
                                .foregroundColor(.green)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color.black))

                    Spacer()

                    // Cellular / Wi-Fi / Battery Icons
                    HStack(spacing: 4) {
                        Image(systemName: "cellularbars")
                            .font(.system(size: 9))
                        Image(systemName: "wifi")
                            .font(.system(size: 9))
                        Image(systemName: "battery.100")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.white)
                    .padding(.trailing, 18)
                }
                .frame(height: 28)
                .background(Color.black)

                // WebKit Browser Canvas
                NativeWKWebView(
                    url: URL(string: manager.primaryURLString),
                    isLoading: $manager.isLoading,
                    canGoBack: $manager.canGoBack,
                    canGoForward: $manager.canGoForward,
                    title: $manager.pageTitle
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)

                // Bottom Floating Safari Address Bar & Home Indicator
                VStack(spacing: 4) {
                    HStack(spacing: 8) {
                        Button(action: {
                            manager.loadURL(inputURL)
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.80))
                        }
                        .buttonStyle(.plain)

                        TextField("Search or enter website name", text: $inputURL)
                            .font(.system(size: 11.5, design: .rounded))
                            .textFieldStyle(.plain)
                            .foregroundColor(.white)
                            .onSubmit {
                                manager.loadURL(inputURL)
                            }

                        if manager.isLoading {
                            ProgressView()
                                .scaleEffect(0.5)
                                .frame(width: 14, height: 14)
                        } else {
                            Button(action: {
                                manager.loadURL(inputURL)
                            }) {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 13))
                                    .foregroundColor(.cyan)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color.white.opacity(0.14)))
                    .overlay(Capsule().stroke(Color.white.opacity(0.20), lineWidth: 0.7))
                    .padding(.horizontal, 16)
                    .padding(.top, 4)

                    // iOS Home Indicator
                    Capsule()
                        .fill(Color.white.opacity(0.65))
                        .frame(width: 110, height: 4)
                        .padding(.bottom, 6)
                }
                .background(Color.black.opacity(0.85))
            }
            .clipShape(RoundedRectangle(cornerRadius: isLandscape ? 32 : 44, style: .continuous))
            .padding(4)
        }
        .frame(width: phoneWidth, height: phoneHeight)
    }

    // MARK: - 📲 iPad Pro 13" Hardware Shell with Stage Manager
    @ViewBuilder
    private func ipadHardwareShell(size: CGSize) -> some View {
        let padWidth: CGFloat = min(size.width - 90, max(560, min(860, (size.height - 40) * 1.35)))
        let padHeight: CGFloat = min(size.height - 40, padWidth / 1.35)

        HStack(spacing: 8) {
            // Stage Manager App Window Thumbnails (Left Rail)
            VStack(spacing: 10) {
                // Active App Thumbnail (Safari)
                stageManagerAppTile(icon: "safari.fill", color: .blue, title: "Safari", isActive: true)
                // Background App Thumbnail (Genie Code Editor)
                stageManagerAppTile(icon: "chevron.left.forwardslash.chevron.right", color: .purple, title: "Code", isActive: false)
                // Background App Thumbnail (Files)
                stageManagerAppTile(icon: "folder.fill", color: .cyan, title: "Files", isActive: false)
                // Background App Thumbnail (Music / Stream)
                stageManagerAppTile(icon: "music.note", color: .pink, title: "Media", isActive: false)
            }
            .padding(.vertical, 12)

            // iPad Hardware Chassis
            ZStack {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Color(white: 0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [Color.white.opacity(0.35), Color.white.opacity(0.12)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2.0
                            )
                    )
                    .shadow(color: Color.black.opacity(0.65), radius: 20, y: 8)

                VStack(spacing: 0) {
                    // iPadOS Status Bar & Stage Manager Dots
                    ZStack {
                        // Center Multitasking Dots (•••)
                        HStack(spacing: 3) {
                            Circle().fill(Color.white.opacity(0.6)).frame(width: 4, height: 4)
                            Circle().fill(Color.white.opacity(0.6)).frame(width: 4, height: 4)
                            Circle().fill(Color.white.opacity(0.6)).frame(width: 4, height: 4)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.white.opacity(0.10)))

                        HStack {
                            Text("\(fullDateString)   \(timeString)")
                                .font(.system(size: 10.5, weight: .semibold))
                                .foregroundColor(.white.opacity(0.9))
                                .padding(.leading, 16)

                            Spacer()

                            HStack(spacing: 6) {
                                Image(systemName: "wifi")
                                    .font(.system(size: 9.5))
                                HStack(spacing: 2) {
                                    Text("100%")
                                        .font(.system(size: 9.5, weight: .semibold))
                                    Image(systemName: "battery.100.bolt")
                                        .font(.system(size: 10.5))
                                }
                            }
                            .foregroundColor(.white.opacity(0.9))
                            .padding(.trailing, 16)
                        }
                    }
                    .frame(height: 24)
                    .background(Color(white: 0.08))

                    // iPadOS Safari Tab Bar & Navigation
                    VStack(spacing: 2) {
                        // Tabs Row
                        HStack(spacing: 4) {
                            // Active Tab
                            HStack(spacing: 6) {
                                Image(systemName: "globe")
                                    .font(.system(size: 10))
                                    .foregroundColor(.cyan)
                                Text(manager.pageTitle)
                                    .font(.system(size: 10.5, weight: .medium))
                                    .lineLimit(1)
                                    .foregroundColor(.white)
                                Spacer()
                                Image(systemName: "xmark")
                                    .font(.system(size: 8))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .frame(maxWidth: 220)
                            .background(RoundedRectangle(cornerRadius: 6).fill(Color(white: 0.22)))

                            // New Tab (+)
                            Button(action: { manager.loadURL("https://www.google.com") }) {
                                Image(systemName: "plus")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.7))
                                    .padding(5)
                            }
                            .buttonStyle(.plain)

                            Spacer()
                        }
                        .padding(.horizontal, 12)
                        .padding(.top, 4)

                        // Omnibox Toolbar Row
                        HStack(spacing: 8) {
                            Button(action: {
                                HapticFeedback.selection()
                                MiniBrowserManager.shared.goBack()
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(manager.canGoBack ? .white : .white.opacity(0.3))
                            }
                            .buttonStyle(.plain)
                            .disabled(!manager.canGoBack)

                            Button(action: {
                                HapticFeedback.selection()
                                MiniBrowserManager.shared.goForward()
                            }) {
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(manager.canGoForward ? .white : .white.opacity(0.3))
                            }
                            .buttonStyle(.plain)
                            .disabled(!manager.canGoForward)

                            // Omnibox
                            HStack(spacing: 6) {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 9))
                                    .foregroundColor(.white.opacity(0.5))

                                TextField("Search or enter website name", text: $inputURL)
                                    .font(.system(size: 11, design: .rounded))
                                    .textFieldStyle(.plain)
                                    .foregroundColor(.white)
                                    .onSubmit {
                                        manager.loadURL(inputURL)
                                    }

                                if manager.isLoading {
                                    ProgressView()
                                        .scaleEffect(0.45)
                                        .frame(width: 12, height: 12)
                                } else {
                                    Button(action: { manager.loadURL(inputURL) }) {
                                        Image(systemName: "arrow.clockwise")
                                            .font(.system(size: 10))
                                            .foregroundColor(.white.opacity(0.7))
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Capsule().fill(Color.white.opacity(0.12)))

                            Button(action: {
                                HapticFeedback.selection()
                                MiniBrowserManager.shared.openInDefaultBrowser()
                            }) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 12)
                        .padding(.bottom, 6)
                    }
                    .background(Color(white: 0.14))

                    // WebKit View
                    NativeWKWebView(
                        url: URL(string: manager.primaryURLString),
                        isLoading: $manager.isLoading,
                        canGoBack: $manager.canGoBack,
                        canGoForward: $manager.canGoForward,
                        title: $manager.pageTitle
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    // iPad Home Indicator
                    ZStack {
                        Capsule()
                            .fill(Color.white.opacity(0.65))
                            .frame(width: 150, height: 4)
                    }
                    .frame(height: 12)
                    .frame(maxWidth: .infinity)
                    .background(Color(white: 0.08))
                }
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                .padding(3)
            }
            .frame(width: padWidth, height: padHeight)
        }
    }

    private func stageManagerAppTile(icon: String, color: Color, title: String, isActive: Bool) -> some View {
        VStack(spacing: 3) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(white: 0.20))
                    .frame(width: 44, height: 32)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(isActive ? Color.cyan : Color.white.opacity(0.15), lineWidth: isActive ? 1.5 : 0.8)
                    )

                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(color)
            }
            Text(title)
                .font(.system(size: 8.5, weight: .medium))
                .foregroundColor(.white.opacity(0.75))
        }
    }

    // MARK: - 🤖 Android Flagship Hardware Shell (Google Play Ready)
    @ViewBuilder
    private func androidHardwareShell(size: CGSize) -> some View {
        let isLandscape = manager.isLandscapeMovieMode
        let droidWidth: CGFloat = isLandscape ? min(size.width - 40, (size.height - 40) * 1.95) : min(412, size.width - 40)
        let droidHeight: CGFloat = isLandscape ? min(size.height - 40, droidWidth / 1.95) : min(size.height - 30, droidWidth * 2.18)

        ZStack {
            // Android Outer Hardware Shell
            RoundedRectangle(cornerRadius: 32, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.08, green: 0.12, blue: 0.11), Color(red: 0.04, green: 0.06, blue: 0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 32, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.green.opacity(0.50), Color.cyan.opacity(0.30), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2.0
                        )
                )
                .shadow(color: Color.black.opacity(0.7), radius: 22, y: 10)

            VStack(spacing: 0) {
                // Android Material 3 Status Bar with Punch-Hole Camera
                ZStack {
                    // Center Punch-Hole Camera
                    Circle()
                        .fill(Color.black)
                        .frame(width: 10, height: 10)
                        .overlay(Circle().fill(Color.cyan.opacity(0.5)).frame(width: 3, height: 3))

                    HStack {
                        // Time + Notifications
                        HStack(spacing: 5) {
                            Text(timeString)
                                .font(.system(size: 10.5, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Image(systemName: "play.fill")
                                .font(.system(size: 7))
                                .foregroundColor(.green)
                            Image(systemName: "bubble.left.fill")
                                .font(.system(size: 7))
                                .foregroundColor(.cyan)
                        }
                        .padding(.leading, 16)

                        Spacer()

                        // Android Icons: 5G, Wi-Fi, Battery 98%
                        HStack(spacing: 4) {
                            Text("5G")
                                .font(.system(size: 8.5, weight: .heavy))
                                .foregroundColor(.white)
                            Image(systemName: "antenna.radiowaves.left.and.right")
                                .font(.system(size: 8))
                            Image(systemName: "wifi")
                                .font(.system(size: 8.5))
                            HStack(spacing: 1.5) {
                                Text("98%")
                                    .font(.system(size: 8.5, weight: .semibold))
                                Image(systemName: "battery.75")
                                    .font(.system(size: 9.5))
                            }
                        }
                        .foregroundColor(.white.opacity(0.9))
                        .padding(.trailing, 16)
                    }
                }
                .frame(height: 24)
                .background(Color.black)

                // Google Chrome Omnibox Bar with Google Play Store Badge
                HStack(spacing: 6) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 9))
                        .foregroundColor(.green)

                    TextField("Search or type URL", text: $inputURL)
                        .font(.system(size: 11, design: .rounded))
                        .textFieldStyle(.plain)
                        .foregroundColor(.white)
                        .onSubmit {
                            manager.loadURL(inputURL)
                        }

                    // Play Store Ready Chip
                    HStack(spacing: 2.5) {
                        Image(systemName: "play.fill")
                            .font(.system(size: 7))
                            .foregroundColor(.green)
                        Text("SDK 35")
                            .font(.system(size: 8, weight: .bold, design: .monospaced))
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.15))
                    .cornerRadius(3)

                    // Tab Count [1]
                    ZStack {
                        RoundedRectangle(cornerRadius: 3)
                            .stroke(Color.white.opacity(0.7), lineWidth: 1)
                            .frame(width: 14, height: 14)
                        Text("1")
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundColor(.white)
                    }

                    // Three Dots Overflow Menu
                    Image(systemName: "ellipsis")
                        .rotationEffect(.degrees(90))
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color(red: 0.12, green: 0.14, blue: 0.14))

                // WebKit Browser
                NativeWKWebView(
                    url: URL(string: manager.primaryURLString),
                    isLoading: $manager.isLoading,
                    canGoBack: $manager.canGoBack,
                    canGoForward: $manager.canGoForward,
                    title: $manager.pageTitle
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Android 3-Button Navigation Bar
                HStack {
                    Spacer()
                    // ◀ Back
                    Button(action: {
                        HapticFeedback.selection()
                    }) {
                        Image(systemName: "triangle.fill")
                            .rotationEffect(.degrees(-90))
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.75))
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    // ⬤ Home
                    Button(action: {
                        HapticFeedback.selection()
                        manager.loadURL("https://www.google.com")
                    }) {
                        Circle()
                            .fill(Color.white.opacity(0.75))
                            .frame(width: 12, height: 12)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    // ◼ Recents
                    Button(action: {
                        HapticFeedback.selection()
                    }) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.75))
                            .frame(width: 11, height: 11)
                    }
                    .buttonStyle(.plain)

                    Spacer()
                }
                .frame(height: 28)
                .background(Color.black)
            }
            .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
            .padding(3)
        }
        .frame(width: droidWidth, height: droidHeight)
    }

    // MARK: - 🪟 Windows 11 Fluent Hardware Shell
    @ViewBuilder
    private func windowsHardwareShell(size: CGSize) -> some View {
        let winWidth: CGFloat = min(size.width - 40, max(620, (size.height - 50) * 1.6))
        let winHeight: CGFloat = min(size.height - 40, winWidth / 1.6)

        ZStack {
            // Windows 11 Fluent Mica Window Container
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(white: 0.11))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1.2)
                )
                .shadow(color: Color.black.opacity(0.7), radius: 24, y: 12)

            VStack(spacing: 0) {
                // Windows 11 Edge Titlebar with Tab and Window Controls (_ ▢ ✕)
                HStack(spacing: 0) {
                    // Active Browser Tab
                    HStack(spacing: 6) {
                        Image(systemName: "globe.americas.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.cyan)
                        Text(manager.pageTitle)
                            .font(.system(size: 10.5, weight: .medium))
                            .lineLimit(1)
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "xmark")
                            .font(.system(size: 8))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .frame(width: 180)
                    .background(Color(white: 0.18))
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))

                    // New Tab (+)
                    Button(action: { manager.loadURL("https://www.bing.com") }) {
                        Image(systemName: "plus")
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.7))
                            .padding(6)
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    // Windows 11 Window Controls (_ ▢ ✕)
                    HStack(spacing: 12) {
                        Image(systemName: "minus")
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.75))
                        Image(systemName: "square")
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.75))
                        Image(systemName: "xmark")
                            .font(.system(size: 9))
                            .foregroundColor(.white.opacity(0.75))
                    }
                    .padding(.trailing, 12)
                }
                .frame(height: 28)
                .background(Color(white: 0.08))

                // Edge Navigation & Omnibox Bar
                HStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.left")
                            .font(.system(size: 10))
                            .foregroundColor(manager.canGoBack ? .white : .white.opacity(0.3))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10))
                            .foregroundColor(manager.canGoForward ? .white : .white.opacity(0.3))
                        Button(action: { manager.loadURL(inputURL) }) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.75))
                        }
                        .buttonStyle(.plain)
                    }

                    // Omnibox
                    HStack(spacing: 6) {
                        Image(systemName: "lock.shield.fill")
                            .font(.system(size: 9.5))
                            .foregroundColor(.cyan)

                        TextField("Search or enter web address", text: $inputURL)
                            .font(.system(size: 11))
                            .textFieldStyle(.plain)
                            .foregroundColor(.white)
                            .onSubmit {
                                manager.loadURL(inputURL)
                            }

                        // Microsoft Copilot Sparkle Icon
                        Image(systemName: "sparkles")
                            .font(.system(size: 10))
                            .foregroundColor(.blue)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(white: 0.16))
                    .cornerRadius(14)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color(white: 0.13))

                // WebKit View
                NativeWKWebView(
                    url: URL(string: manager.primaryURLString),
                    isLoading: $manager.isLoading,
                    canGoBack: $manager.canGoBack,
                    canGoForward: $manager.canGoForward,
                    title: $manager.pageTitle
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Windows 11 Centered Taskbar
                HStack {
                    // Centered Start & App Icons
                    Spacer()
                    HStack(spacing: 12) {
                        // Windows Start Logo (4 squares)
                        Image(systemName: "square.grid.2x2.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.blue)

                        // Search
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.8))

                        // Task View
                        Image(systemName: "square.on.square")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.8))

                        // Microsoft Edge
                        Image(systemName: "globe")
                            .font(.system(size: 11))
                            .foregroundColor(.cyan)

                        // File Explorer
                        Image(systemName: "folder.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.yellow)

                        // Microsoft Store
                        Image(systemName: "bag.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.cyan)
                    }
                    Spacer()

                    // System Tray (Time & Status)
                    HStack(spacing: 8) {
                        Image(systemName: "wifi")
                            .font(.system(size: 9))
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.system(size: 9))
                        Image(systemName: "battery.100")
                            .font(.system(size: 9.5))
                        VStack(alignment: .trailing, spacing: 1) {
                            Text(timeString)
                                .font(.system(size: 8.5, weight: .medium))
                            Text(fullDateString)
                                .font(.system(size: 7.5))
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.trailing, 10)
                }
                .frame(height: 32)
                .background(Color(white: 0.10))
            }
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            .padding(1)
        }
        .frame(width: winWidth, height: winHeight)
    }

    // MARK: - 3. Duo Screen View (Surface Duo Foldable Layout)
    @ViewBuilder
    private func duoScreenView(size: CGSize) -> some View {
        let totalW = min(size.width - 30, 940)
        let totalH = min(size.height - 30, totalW * 0.65)
        let singleW = (totalW - 20) / 2.0

        HStack(spacing: 0) {
            // Left Screen: Primary Movie / Video Player
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.black)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(Color.white.opacity(0.25), lineWidth: 1.5)
                    )

                VStack(spacing: 0) {
                    // Left Screen Header
                    HStack {
                        Label("Screen 1 • Movie Stream", systemImage: "play.rectangle.fill")
                            .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                            .foregroundColor(.cyan)
                        Spacer()
                        Text(timeString)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.8))

                    // Web Player
                    NativeWKWebView(
                        url: URL(string: manager.primaryURLString),
                        isLoading: $manager.isLoading,
                        canGoBack: $manager.canGoBack,
                        canGoForward: $manager.canGoForward,
                        title: $manager.pageTitle
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                .padding(2)
            }
            .frame(width: singleW, height: totalH)

            // Central Foldable Hinge / Spine
            VStack(spacing: 4) {
                ForEach(0..<12) { _ in
                    Circle()
                        .fill(Color.white.opacity(0.25))
                        .frame(width: 4, height: 4)
                }
            }
            .frame(width: 20, height: totalH)
            .background(Color(white: 0.12))

            // Right Screen: Secondary Companion Browser / Simctl Inspector
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(Color.black)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(Color.white.opacity(0.25), lineWidth: 1.5)
                    )

                VStack(spacing: 0) {
                    // Right Screen Header
                    HStack {
                        Label("Screen 2 • Duo Companion", systemImage: "macwindow.on.rectangle")
                            .font(.system(size: 10.5, weight: .bold, design: .monospaced))
                            .foregroundColor(.yellow)
                        Spacer()
                        Button("Simctl Boot") {
                            manager.bootFirstSimulator()
                        }
                        .font(.system(size: 9.5, weight: .bold))
                        .foregroundColor(.green)
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.black.opacity(0.8))

                    // Secondary Web Browser or Console
                    NativeWKWebView(
                        url: URL(string: manager.secondaryURLString),
                        isLoading: .constant(false),
                        canGoBack: .constant(false),
                        canGoForward: .constant(false),
                        title: .constant("Duo Companion")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                .padding(2)
            }
            .frame(width: singleW, height: totalH)
        }
        .frame(width: totalW, height: totalH)
        .shadow(color: Color.black.opacity(0.6), radius: 24, y: 8)
    }
}
