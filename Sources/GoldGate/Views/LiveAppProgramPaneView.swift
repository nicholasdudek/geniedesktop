import AppKit
import Foundation
import SwiftUI
import CoreGraphics

// MARK: - 🪟 Live Application Program Pane View (Programs open as tabs inside Genie Chat)
public struct LiveAppProgramPaneView: View {
    public let bundleId: String
    public let name: String

    @State private var windowPreviewImage: NSImage? = nil
    @State private var isRefreshing: Bool = false
    @State private var lastCaptureTime: Date? = nil

    public init(bundleId: String, name: String) {
        self.bundleId = bundleId
        self.name = name
    }

    private var runningApp: NSRunningApplication? {
        NSWorkspace.shared.runningApplications.first(where: {
            $0.bundleIdentifier == bundleId || $0.localizedName?.lowercased() == name.lowercased()
        })
    }

    private var appIcon: NSImage {
        if let app = runningApp, let icon = app.icon { return icon }
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
            return NSWorkspace.shared.icon(forFile: url.path)
        }
        return NSWorkspace.shared.icon(for: .application)
    }

    private func captureWindow() {
        guard let pid = runningApp?.processIdentifier else {
            windowPreviewImage = nil
            return
        }
        guard let winList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else { return }
        for info in winList {
            if let ownerPID = info[kCGWindowOwnerPID as String] as? pid_t, ownerPID == pid,
               let wid = info[kCGWindowNumber as String] as? CGWindowID {
                if let cgImg = safeCGWindowListCreateImage(.null, .optionIncludingWindow, wid, [.bestResolution, .nominalResolution]) {
                    windowPreviewImage = NSImage(cgImage: cgImg, size: NSSize(width: cgImg.width, height: cgImg.height))
                    lastCaptureTime = Date()
                    return
                }
            }
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            // ── Top Proscenium Header Ribbon ──
            HStack(spacing: 12) {
                Image(nsImage: appIcon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                    .shadow(color: .black.opacity(0.35), radius: 3, y: 1)

                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(name)
                            .font(.system(size: 13.5, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        if let app = runningApp, !app.isTerminated {
                            HStack(spacing: 4) {
                                Circle().fill(Color.green).frame(width: 6, height: 6)
                                Text("Running (PID \(app.processIdentifier))")
                                    .font(.system(size: 9.5, weight: .medium, design: .monospaced))
                                    .foregroundColor(.green.opacity(0.95))
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.green.opacity(0.12)))
                        } else {
                            Text("Not Running")
                                .font(.system(size: 9.5, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.white.opacity(0.08)))
                        }
                    }

                    Text(bundleId)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.white.opacity(0.45))
                }

                Spacer()

                // Action Ribbon
                HStack(spacing: 6) {
                    if let app = runningApp, !app.isTerminated {
                        Button(action: {
                            HapticFeedback.selection()
                            app.unhide()
                            _ = app.activate(options: [.activateAllWindows])
                        }) {
                            Label("Bring to Front", systemImage: "macwindow.and.cursorarrow")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Capsule().fill(Color.cyan.opacity(0.35)))
                                .overlay(Capsule().strokeBorder(Color.cyan.opacity(0.6), lineWidth: 0.6))
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            HapticFeedback.selection()
                            captureWindow()
                            if let img = windowPreviewImage {
                                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(name)-window.png")
                                if let tiff = img.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff), let png = rep.representation(using: .png, properties: [:]) {
                                    try? png.write(to: tempURL)
                                    FinderChatWindowManager.shared.stageFile(url: tempURL)
                                }
                            } else {
                                FinderChatWindowManager.shared.openTab(.chat)
                            }
                        }) {
                            Label("Ask Genie About App", systemImage: "sparkles")
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Capsule().fill(Color.white.opacity(0.12)))
                                .overlay(Capsule().strokeBorder(Color.white.opacity(0.20), lineWidth: 0.6))
                        }
                        .buttonStyle(.plain)

                        Button(action: {
                            HapticFeedback.selection()
                            captureWindow()
                        }) {
                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                                .frame(width: 28, height: 28)
                                .background(Circle().fill(Color.white.opacity(0.10)))
                        }
                        .buttonStyle(.plain)
                        .help("Refresh Window Capture")
                    } else {
                        Button(action: {
                            HapticFeedback.selection()
                            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
                                NSWorkspace.shared.open(url)
                            }
                        }) {
                            Label("Launch \(name)", systemImage: "arrow.up.forward.app")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Capsule().fill(Color.cyan.opacity(0.35)))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.black.opacity(0.30))

            Divider().background(Color.white.opacity(0.12))

            // ── Live Window Surface ──
            GeometryReader { geo in
                ZStack {
                    if let img = windowPreviewImage {
                        ScrollView([.horizontal, .vertical]) {
                            Image(nsImage: img)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxWidth: geo.size.width - 32, maxHeight: geo.size.height - 32)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .strokeBorder(Color.white.opacity(0.20), lineWidth: 1)
                                )
                                .shadow(color: Color.black.opacity(0.4), radius: 12, y: 4)
                                .onTapGesture {
                                    runningApp?.unhide()
                                    _ = runningApp?.activate(options: [.activateAllWindows])
                                }
                                .padding(16)
                        }
                    } else {
                        VStack(spacing: 12) {
                            Image(nsImage: appIcon)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 64, height: 64)
                                .opacity(0.85)

                            Text(name)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.white)

                            Text(runningApp != nil ? "Click 'Bring to Front' to focus this application or capture a screenshot" : "Application is not running. Click Launch to start it.")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.6))
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: 380)

                            if let app = runningApp, !app.isTerminated {
                                Button(action: {
                                    app.unhide()
                                    _ = app.activate(options: [.activateAllWindows])
                                }) {
                                    HStack(spacing: 6) {
                                        Image(systemName: "macwindow.on.rectangle")
                                        Text("Activate Application Window")
                                    }
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .background(Capsule().fill(Color.cyan.opacity(0.35)))
                                    .overlay(Capsule().strokeBorder(Color.cyan.opacity(0.6), lineWidth: 0.8))
                                }
                                .buttonStyle(.plain)
                                .padding(.top, 6)
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
        .onAppear {
            captureWindow()
        }
    }
}
