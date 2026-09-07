import AppKit
import Foundation
import SwiftUI

// MARK: - 📁 Tiny Folder App Pocket Overlay View
/// Renders floating, interactive folder-sized live windows on the desktop.
/// Enables users to keep running programs visible at folder size (84×84 pt)
/// without resizing or reflowing the original app window.
public struct TinyFolderAppPocketOverlayView: View {
    @ObservedObject var engine: TinyFolderAppPocketEngine = .shared
    @State private var dragOffsets: [CGWindowID: CGSize] = [:]

    public init() {}

    public var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(engine.pocketedApps) { item in
                pocketFolderCard(for: item)
                    .position(
                        x: item.pocketPosition.x + (dragOffsets[item.id]?.width ?? 0) + (engine.activeFolderSize.width * 0.5),
                        y: item.pocketPosition.y + (dragOffsets[item.id]?.height ?? 0) + (engine.activeFolderSize.height * 0.5)
                    )
            }
        }
        .allowsHitTesting(!engine.pocketedApps.isEmpty)
    }

    // MARK: - Individual Pocket Folder Card
    @ViewBuilder
    private func pocketFolderCard(for item: PocketedAppItem) -> some View {
        let isHovered = engine.hoveredWindowId == item.id
        let isPeeking = engine.peekWindowId == item.id
        let thumbnail = engine.liveThumbnailMap[item.id]

        VStack(spacing: 4) {
            ZStack(alignment: .topTrailing) {
                // Liquid Glass Squircle Frame (Folder Shape)
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.black.opacity(0.45))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        Color.cyan.opacity(isHovered ? 0.9 : 0.4),
                                        Color.white.opacity(isHovered ? 0.6 : 0.2),
                                        Color.cyan.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: isHovered ? 2.0 : 1.2
                            )
                    )
                    .shadow(color: isHovered ? Color.cyan.opacity(0.6) : Color.black.opacity(0.4), radius: isHovered ? 12 : 6)

                // Live Scaled Application Viewport
                if let thumb = thumbnail {
                    Image(nsImage: thumb)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: engine.activeFolderSize.width - 6, height: engine.activeFolderSize.height - 6)
                        .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                        .padding(3)
                } else {
                    ProgressView()
                        .scaleEffect(0.6)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                // Mini App Icon Stamp Badge
                if engine.showAppBadge {
                    appBadgeIcon(for: item)
                        .offset(x: 4, y: -4)
                }
            }
            .frame(width: engine.activeFolderSize.width, height: engine.activeFolderSize.height)

            // Folder-Style Text Label
            Text(item.appName)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .lineLimit(1)
                .shadow(color: .black, radius: 2)
                .frame(maxWidth: engine.activeFolderSize.width + 12)
        }
        .scaleEffect(isHovered ? 1.08 : 1.0)
        .animation(.spring(response: 0.26, dampingFraction: 0.72), value: isHovered)
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffsets[item.id] = value.translation
                }
                .onEnded { value in
                    let newX = item.pocketPosition.x + value.translation.width
                    let newY = item.pocketPosition.y + value.translation.height
                    dragOffsets.removeValue(forKey: item.id)
                    engine.movePocket(windowId: item.id, to: CGPoint(x: newX, y: newY))
                }
        )
        .onHover { h in
            engine.hoveredWindowId = h ? item.id : nil
        }
        .onTapGesture(count: 2) {
            // Double-click to expand back to native size
            engine.restoreWindow(windowId: item.id)
        }
        .onTapGesture(count: 1) {
            // Single-click to peek / peep-hole preview
            withAnimation(.spring(response: 0.22, dampingFraction: 0.78)) {
                if engine.peekWindowId == item.id {
                    engine.peekWindowId = nil
                } else {
                    engine.peekWindowId = item.id
                }
            }
        }
        .contextMenu {
            Button("Expand Window (1.0x)") {
                engine.restoreWindow(windowId: item.id)
            }
            Button("Peep-Hole Preview") {
                engine.peekWindowId = item.id
            }
            Divider()
            Button("Close Application") {
                if let app = NSWorkspace.shared.runningApplications.first(where: { $0.processIdentifier == item.processId }) {
                    app.terminate()
                }
                engine.restoreWindow(windowId: item.id)
            }
        }
        .overlay(
            // High-DPI Peep-Hole Glass Callout Preview
            Group {
                if isPeeking, let thumb = thumbnail {
                    peepHolePreview(thumb: thumb, item: item)
                }
            }
        )
    }

    // MARK: - Mini App Badge
    @ViewBuilder
    private func appBadgeIcon(for item: PocketedAppItem) -> some View {
        let appIcon: NSImage? = {
            if let bid = item.bundleIdentifier, let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bid) {
                return NSWorkspace.shared.icon(forFile: url.path)
            }
            return NSWorkspace.shared.runningApplications.first(where: { $0.processIdentifier == item.processId })?.icon
        }()

        ZStack {
            Circle()
                .fill(Color.black.opacity(0.75))
                .frame(width: 22, height: 22)
                .overlay(Circle().strokeBorder(Color.cyan.opacity(0.8), lineWidth: 1.2))

            if let img = appIcon {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 14, height: 14)
                    .clipShape(Circle())
            } else {
                Image(systemName: "app.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.cyan)
            }
        }
        .shadow(color: .black.opacity(0.5), radius: 3)
    }

    // MARK: - Peep-Hole Callout Preview
    @ViewBuilder
    private func peepHolePreview(thumb: NSImage, item: PocketedAppItem) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text("\(item.appName) — Live Peep")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Button(action: {
                    engine.restoreWindow(windowId: item.id)
                }) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.cyan)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 8)
            .padding(.top, 6)

            Image(nsImage: thumb)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 280, height: 175)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .padding(.horizontal, 6)
                .padding(.bottom, 6)
        }
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color(red: 0.08, green: 0.10, blue: 0.15).opacity(0.92))
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(Color.cyan.opacity(0.6), lineWidth: 1.5)
                )
                .shadow(color: Color.black.opacity(0.6), radius: 18)
        )
        .offset(y: -140)
        .transition(.scale.combined(with: .opacity))
    }
}
