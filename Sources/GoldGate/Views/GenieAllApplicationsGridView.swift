// MARK: - GenieAllApplicationsGridView.swift
// Golden Gate Engineering • © 2026 Nicholas M. Dudek
//
// Full-fidelity macOS Application Atelier & Launcher for Genie Chat.
// Displays all installed applications across the system (/Applications,
// /System/Applications, /System/Applications/Utilities) alongside active running
// tasks with real-time fuzzy search, category filtering, and status badges.

import AppKit
import Foundation
import SwiftUI

public struct GenieAllApplicationsGridView: View {
    @ObservedObject private var appModel: AppModel
    @ObservedObject private var dockManager = DockAndDesktopManager.shared
    @ObservedObject private var windowManager = FinderChatWindowManager.shared

    @State private var searchText: String = ""
    @State private var selectedCategory: AppCategory = .all
    @State private var showOnlyRunning: Bool = false
    @State private var hoveredAppId: String? = nil
    @State private var feedbackText: String? = nil

    public init() {
        self.appModel = AppModel.shared ?? AppModel()
    }

    private var runningIdentifiers: Set<String> {
        var set = Set<String>()
        for r in appModel.runningApps {
            if let bid = r.bundleIdentifier?.lowercased() { set.insert(bid) }
            if let name = r.localizedName?.lowercased() { set.insert(name) }
            if let path = r.bundleURL?.path.lowercased() { set.insert(path) }
        }
        for d in dockManager.dockItems where d.isRunning {
            if let bid = d.bundleIdentifier?.lowercased() { set.insert(bid) }
            set.insert(d.name.lowercased())
            if let path = d.bundleURL?.path.lowercased() { set.insert(path) }
        }
        return set
    }

    private func isAppRunning(_ app: AppInfo) -> Bool {
        let bundleId = Bundle(url: app.url)?.bundleIdentifier?.lowercased() ?? ""
        let lowerName = app.name.lowercased()
        let lowerPath = app.url.path.lowercased()

        if !bundleId.isEmpty && runningIdentifiers.contains(bundleId) { return true }
        if runningIdentifiers.contains(lowerName) { return true }
        if runningIdentifiers.contains(lowerPath) { return true }
        return false
    }

    private var displayedApps: [AppInfo] {
        var list = appModel.apps
        if list.isEmpty {
            // Fallback to dockManager items if appModel is still scanning
            list = dockManager.dockItems.compactMap { item in
                guard let url = item.bundleURL else { return nil }
                return AppInfo(
                    id: item.id,
                    name: item.name,
                    url: url,
                    icon: item.icon ?? NSWorkspace.shared.icon(forFile: url.path)
                )
            }
        }

        if showOnlyRunning {
            list = list.filter { isAppRunning($0) }
        }

        if selectedCategory != .all {
            list = list.filter { appModel.category(for: $0) == selectedCategory }
        }

        let cleanSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleanSearch.isEmpty {
            list = list.filter {
                $0.name.localizedCaseInsensitiveContains(cleanSearch) ||
                $0.url.lastPathComponent.localizedCaseInsensitiveContains(cleanSearch)
            }
        }

        return list.sorted { lhs, rhs in
            let lRunning = isAppRunning(lhs)
            let rRunning = isAppRunning(rhs)
            if lRunning != rRunning {
                return lRunning && !rRunning
            }
            return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            // ── Top Control & Search Bar ──
            HStack(spacing: 10) {
                // Header Title & App Counter
                HStack(spacing: 6) {
                    Image(systemName: "square.grid.2x2.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.orange)

                    Text("Applications")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("(\(displayedApps.count))")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.60))
                }

                Spacer()

                // Filter Pill: Show Running Only vs All
                HStack(spacing: 2) {
                    Button(action: {
                        withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
                            showOnlyRunning = false
                        }
                        HapticFeedback.selection()
                    }) {
                        Text("All Apps")
                            .font(.system(size: 10.5, weight: !showOnlyRunning ? .bold : .medium, design: .rounded))
                            .foregroundColor(!showOnlyRunning ? .white : .white.opacity(0.60))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3.5)
                            .background(RoundedRectangle(cornerRadius: 6).fill(!showOnlyRunning ? Color.white.opacity(0.18) : Color.clear))
                    }
                    .buttonStyle(.plain)

                    Button(action: {
                        withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
                            showOnlyRunning = true
                        }
                        HapticFeedback.selection()
                    }) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                            Text("Active Only")
                                .font(.system(size: 10.5, weight: showOnlyRunning ? .bold : .medium, design: .rounded))
                                .foregroundColor(showOnlyRunning ? .white : .white.opacity(0.60))
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3.5)
                        .background(RoundedRectangle(cornerRadius: 6).fill(showOnlyRunning ? Color.white.opacity(0.18) : Color.clear))
                    }
                    .buttonStyle(.plain)
                }
                .padding(2)
                .background(RoundedRectangle(cornerRadius: 7).fill(Color.white.opacity(0.06)))

                // Search Field
                HStack(spacing: 5) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.50))

                    TextField("Search applications...", text: $searchText)
                        .textFieldStyle(.plain)
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(.white)

                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 10))
                                .foregroundColor(.white.opacity(0.50))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .frame(width: 170)
                .background(RoundedRectangle(cornerRadius: 7).fill(Color.white.opacity(0.08)))
                .overlay(RoundedRectangle(cornerRadius: 7).strokeBorder(Color.white.opacity(0.14), lineWidth: 0.5))

                // Refresh Button
                Button(action: {
                    HapticFeedback.selection()
                    Task {
                        await appModel.load()
                        dockManager.refreshDockApps()
                    }
                    feedbackText = "Refreshed applications ⚡"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                        feedbackText = nil
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.75))
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(Color.white.opacity(0.08)))
                }
                .buttonStyle(.plain)
                .help("Rescan macOS /Applications directories")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.30))

            // ── Category Pills Bar ──
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(AppCategory.allCases) { cat in
                        let isSelected = (selectedCategory == cat)
                        Button(action: {
                            withAnimation(.spring(response: 0.22, dampingFraction: 0.8)) {
                                selectedCategory = cat
                            }
                            HapticFeedback.selection()
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: cat.icon)
                                    .font(.system(size: 9))
                                Text(cat.rawValue)
                                    .font(.system(size: 10, weight: isSelected ? .bold : .medium, design: .rounded))
                            }
                            .foregroundColor(isSelected ? .white : .white.opacity(0.65))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3.5)
                            .background(
                                Capsule().fill(isSelected ? cat.tintColor.opacity(0.35) : Color.white.opacity(0.06))
                            )
                            .overlay(
                                Capsule().stroke(isSelected ? cat.tintColor.opacity(0.65) : Color.white.opacity(0.12), lineWidth: 0.6)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
            }
            .background(Color.black.opacity(0.18))

            Divider().opacity(0.20)

            // Feedback Banner (if any)
            if let feedback = feedbackText {
                HStack {
                    Spacer()
                    Text(feedback)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(.green)
                    Spacer()
                }
                .padding(.vertical, 3)
                .background(Color.green.opacity(0.12))
            }

            // ── Grid of All Applications ──
            if displayedApps.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.30))
                    Text(searchText.isEmpty ? "No applications found." : "No applications matching '\(searchText)'")
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.60))
                    if !searchText.isEmpty {
                        Button("Clear Search") {
                            searchText = ""
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.orange)
                    }
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(.vertical, showsIndicators: true) {
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 88, maximum: 110), spacing: 14)],
                        spacing: 14
                    ) {
                        ForEach(displayedApps) { app in
                            let running = isAppRunning(app)
                            let isHovered = (hoveredAppId == app.id)

                            Button(action: {
                                HapticFeedback.selection()
                                appModel.launch(app)
                                feedbackText = "Launched \(app.name) 🚀"
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                                    feedbackText = nil
                                }
                            }) {
                                VStack(spacing: 6) {
                                    ZStack(alignment: .bottomTrailing) {
                                        Image(nsImage: app.icon)
                                            .resizable()
                                            .interpolation(.high)
                                            .aspectRatio(contentMode: .fit)
                                            .frame(width: 44, height: 44)
                                            .shadow(color: Color.black.opacity(0.40), radius: 4, y: 2)

                                        if running {
                                            Circle()
                                                .fill(Color(red: 0.0, green: 0.95, blue: 0.45))
                                                .frame(width: 8, height: 8)
                                                .overlay(Circle().stroke(Color.black, lineWidth: 1.2))
                                                .shadow(color: Color.green.opacity(0.9), radius: 2)
                                                .offset(x: 2, y: 2)
                                        }
                                    }

                                    Text(app.name)
                                        .font(.system(size: 10.5, weight: isHovered ? .bold : .medium, design: .rounded))
                                        .foregroundColor(running ? .white : .white.opacity(0.85))
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                        .multilineTextAlignment(.center)

                                    if running {
                                        Text("Active")
                                            .font(.system(size: 8.5, weight: .bold, design: .rounded))
                                            .foregroundColor(.green.opacity(0.90))
                                            .padding(.horizontal, 5)
                                            .padding(.vertical, 1)
                                            .background(Capsule().fill(Color.green.opacity(0.18)))
                                    } else {
                                        Text(appModel.category(for: app).tag)
                                            .font(.system(size: 8, weight: .medium, design: .monospaced))
                                            .foregroundColor(.white.opacity(0.35))
                                            .padding(.horizontal, 4)
                                            .padding(.vertical, 1)
                                    }
                                }
                                .padding(.vertical, 10)
                                .padding(.horizontal, 6)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(isHovered ? Color.white.opacity(0.14) : Color.white.opacity(0.04))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .strokeBorder(
                                            running ? Color.green.opacity(0.45) : (isHovered ? Color.white.opacity(0.25) : Color.white.opacity(0.08)),
                                            lineWidth: isHovered ? 1.0 : 0.5
                                        )
                                )
                                .scaleEffect(isHovered ? 1.04 : 1.0)
                            }
                            .buttonStyle(.plain)
                            .onHover { hovering in
                                withAnimation(.spring(response: 0.18, dampingFraction: 0.75)) {
                                    hoveredAppId = hovering ? app.id : (hoveredAppId == app.id ? nil : hoveredAppId)
                                }
                            }
                            .contextMenu {
                                Button("Open \(app.name)") {
                                    appModel.launch(app)
                                }
                                Button("Show in Finder") {
                                    NSWorkspace.shared.activateFileViewerSelecting([app.url])
                                }
                                Divider()
                                Button("Embed in New Tab") {
                                    let bundleId = Bundle(url: app.url)?.bundleIdentifier ?? app.id
                                    windowManager.openProgram(bundleId: bundleId, name: app.name)
                                }
                            }
                        }
                    }
                    .padding(16)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.20))
        .onAppear {
            if appModel.apps.isEmpty {
                Task {
                    await appModel.load()
                }
            }
        }
    }
}
