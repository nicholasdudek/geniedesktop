import AppKit
import SwiftUI

// MARK: - Consolidated iPhone Mirror View (Embedded in Genie Chat)

public struct ConsolidatediPhoneMirrorView: View {
    @ObservedObject var mirrorManager = iPhoneMirrorManager.shared
    public var onClose: () -> Void
    public var onSendToAI: (String) -> Void

    @State private var isHoveringScreen: Bool = false
    @State private var hoveredNormPoint: CGPoint? = nil
    @State private var showOcrPopover: Bool = false
    @State private var feedbackText: String? = nil

    public init(onClose: @escaping () -> Void, onSendToAI: @escaping (String) -> Void) {
        self.onClose = onClose
        self.onSendToAI = onSendToAI
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Drag handle / grab bar
            HStack {
                Spacer()
                Capsule()
                    .fill(Color.white.opacity(0.35))
                    .frame(width: 36, height: 4)
                    .padding(.top, 6)
                    .padding(.bottom, 2)
                Spacer()
            }

            // ── PROSCENIUM HEADER ──
            HStack(spacing: 10) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(mirrorManager.isRunning ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                        .shadow(color: (mirrorManager.isRunning ? Color.green : Color.orange).opacity(0.7), radius: 3)

                    Image(systemName: "iphone.gen3")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.cyan)

                    Text("IPHONE SCREEN MIRROR")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)

                    Text(mirrorManager.isRunning ? "LIVE" : "READY")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(mirrorManager.isRunning ? .green : .orange)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1.5)
                        .background(Capsule().fill((mirrorManager.isRunning ? Color.green : Color.orange).opacity(0.18)))
                }

                Spacer()

                if let fb = feedbackText {
                    Text(fb)
                        .font(.system(size: 10.5, weight: .semibold, design: .rounded))
                        .foregroundColor(.cyan)
                        .transition(.opacity)
                }

                // Default Viewer Toggle
                Button(action: {
                    mirrorManager.isDefaultViewer.toggle()
                    HapticFeedback.selection()
                    triggerFeedback(mirrorManager.isDefaultViewer ? "Default Viewer Enabled 📱" : "Default Viewer Disabled ⚪️")
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: mirrorManager.isDefaultViewer ? "checkmark.circle.fill" : "circle")
                        Text("Default Viewer")
                    }
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(mirrorManager.isDefaultViewer ? .cyan : .white.opacity(0.6))
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3.5)
                    .background(Capsule().fill(mirrorManager.isDefaultViewer ? Color.cyan.opacity(0.15) : Color.white.opacity(0.08)))
                }
                .buttonStyle(.plain)
                .help("Make Genie Chat the default viewer for iPhone Screen Mirroring")

                // Back to Chat
                Button(action: {
                    HapticFeedback.selection()
                    onClose()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "bubble.left.and.bubble.right.fill")
                        Text("Back to Chat")
                    }
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3.5)
                    .background(Capsule().fill(Color.cyan.opacity(0.35)))
                    .overlay(Capsule().stroke(Color.cyan.opacity(0.65), lineWidth: 0.6))
                }
                .buttonStyle(.plain)
                .help("Switch back to Chat in same window 💬")

                // Close Button
                Button(action: {
                    HapticFeedback.tick()
                    onClose()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.65))
                }
                .buttonStyle(.plain)
                .help("Close Screen Mirror Viewer")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.35))

            Divider().opacity(0.25)

            // ── MAIN STAGE: IPHONE HARDWARE SILHOUETTE + AI SIDEBAR ──
            HStack(alignment: .top, spacing: 20) {
                // iPhone Hardware Frame
                iphoneChassisView
                    .padding(.vertical, 14)
                    .padding(.leading, 18)

                // AI Tools & Screen Context Panel
                aiContextSidebarView
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 14)
                    .padding(.trailing, 18)
            }
            .frame(height: 480)
        }
        .background(
            ZStack {
                VisualEffectBlur(material: .hudWindow, blendingMode: .withinWindow, state: .active)
                Color.black.opacity(0.62)

                RadialGradient(
                    colors: [
                        Color(red: 0.0, green: 0.85, blue: 1.0).opacity(0.18),
                        Color(red: 0.0, green: 0.50, blue: 1.0).opacity(0.10),
                        Color.clear
                    ],
                    center: .top,
                    startRadius: 5,
                    endRadius: 400
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.cyan.opacity(0.35), Color.purple.opacity(0.20), Color.white.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.85
                )
        )
        .onAppear {
            mirrorManager.checkAppRunning()
            mirrorManager.startStreaming()
        }
        .onDisappear {
            mirrorManager.stopStreaming()
        }
    }

    // MARK: - iPhone Hardware Chassis View

    private var iphoneChassisView: some View {
        let phoneWidth: CGFloat = 220
        let phoneHeight: CGFloat = 450
        let cornerRadius: CGFloat = 38

        return ZStack {
            // Outer Titanium Bezel & Drop Shadow
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.22), Color(white: 0.08), Color(white: 0.16)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: phoneWidth, height: phoneHeight)
                .shadow(color: Color.black.opacity(0.55), radius: 14, x: 0, y: 8)
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.35), Color.white.opacity(0.08), Color.cyan.opacity(0.25)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.2
                        )
                )

            // Inner Display Screen
            ZStack {
                Color.black

                if let frame = mirrorManager.currentFrame {
                    Image(nsImage: frame)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipped()
                } else {
                    // Placeholder when iPhone Mirroring is starting or disconnected
                    VStack(spacing: 12) {
                        Image(systemName: "iphone.radiowaves.left.and.right")
                            .font(.system(size: 32))
                            .foregroundColor(.cyan)

                        Text("iPhone Mirroring")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text(mirrorManager.isRunning ? "Connecting video stream..." : "App is not running")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.6))

                        Button(action: {
                            mirrorManager.launchOrActivateApp()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "play.fill")
                                Text("Launch iPhone Mirror")
                            }
                            .font(.system(size: 10.5, weight: .bold, design: .rounded))
                            .foregroundColor(.black)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Capsule().fill(Color.cyan))
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 6)
                    }
                    .padding(16)
                }

                // Dynamic Island Pill at top
                VStack {
                    Capsule()
                        .fill(Color.black)
                        .frame(width: 62, height: 18)
                        .overlay(
                            HStack(spacing: 4) {
                                Circle().fill(Color(white: 0.15)).frame(width: 6, height: 6)
                                Spacer()
                                Circle().fill(Color(white: 0.12)).frame(width: 7, height: 7)
                            }
                            .padding(.horizontal, 6)
                        )
                        .padding(.top, 7)

                    Spacer()

                    // Home Indicator Bar at bottom
                    Capsule()
                        .fill(Color.white.opacity(0.65))
                        .frame(width: 76, height: 3.5)
                        .padding(.bottom, 6)
                }
            }
            .frame(width: phoneWidth - 8, height: phoneHeight - 8)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius - 3, style: .continuous))
            .contentShape(Rectangle())
            .onTapGesture { location in
                let normX = location.x / (phoneWidth - 8)
                let normY = location.y / (phoneHeight - 8)
                mirrorManager.forwardClick(normalizedX: normX, normalizedY: normY)
            }
        }
    }

    // MARK: - AI Context & Quick Tools Sidebar

    private var aiContextSidebarView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AI Phone Assistant & Tools")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(.white.opacity(0.85))

            // Action Buttons
            HStack(spacing: 8) {
                actionChip(title: "Ask AI About Screen", icon: "sparkles", color: .cyan) {
                    let prompt = mirrorManager.recognizedText.isEmpty
                        ? "What is currently displayed on my iPhone screen?"
                        : "Analyze what is on my iPhone screen right now:\n\n\"\"\"\n\(mirrorManager.recognizedText)\n\"\"\""
                    onSendToAI(prompt)
                }

                actionChip(title: "Copy Screen Text", icon: "doc.on.doc.fill", color: .green) {
                    mirrorManager.copyRecognizedText()
                    triggerFeedback("Text Copied to Clipboard 📋")
                }

                actionChip(title: "Save Polaroid", icon: "camera.fill", color: .orange) {
                    mirrorManager.saveToPolaroid()
                    triggerFeedback("Polaroid Note Saved 📸")
                }

                actionChip(title: "Copy Image", icon: "photo.fill", color: .purple) {
                    mirrorManager.copyFrameToClipboard()
                    triggerFeedback("Screen Image Copied 🖼️")
                }
            }

            // Live OCR Screen Text Box
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Image(systemName: "character.bubble.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.cyan)

                    Text("LIVE TEXT ON SCREEN (OCR)")
                        .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                        .foregroundColor(.white.opacity(0.7))

                    Spacer()

                    if mirrorManager.isOcrBusy {
                        ProgressView()
                            .scaleEffect(0.5)
                            .frame(width: 12, height: 12)
                    }
                }

                ScrollView {
                    Text(mirrorManager.recognizedText.isEmpty ? "No text detected on screen yet..." : mirrorManager.recognizedText)
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .foregroundColor(mirrorManager.recognizedText.isEmpty ? .white.opacity(0.35) : .white.opacity(0.9))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                }
                .frame(maxHeight: 180)
                .background(Color.black.opacity(0.40))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 10, style: .continuous).stroke(Color.white.opacity(0.12), lineWidth: 0.8))
            }

            // Quick Prompt Ideas
            VStack(alignment: .leading, spacing: 5) {
                Text("QUICK PROMPTS FOR IPHONE")
                    .font(.system(size: 9.5, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.6))

                HStack(spacing: 6) {
                    quickPromptButton("Summarize notification/message")
                    quickPromptButton("Explain app settings")
                    quickPromptButton("Proofread text")
                }
            }

            Spacer()
        }
    }

    private func actionChip(title: String, icon: String, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: {
            HapticFeedback.selection()
            action()
        }) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 10.5, weight: .medium, design: .rounded))
                    .foregroundColor(.white)
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(Color.white.opacity(0.08))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(color.opacity(0.35), lineWidth: 0.6))
        }
        .buttonStyle(.plain)
    }

    private func quickPromptButton(_ text: String) -> some View {
        Button(action: {
            HapticFeedback.selection()
            let prompt = "\(text) from this iPhone screen:\n\n\"\"\"\n\(mirrorManager.recognizedText)\n\"\"\""
            onSendToAI(prompt)
        }) {
            Text(text)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.85))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.cyan.opacity(0.12))
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.cyan.opacity(0.30), lineWidth: 0.6))
        }
        .buttonStyle(.plain)
    }

    private func triggerFeedback(_ msg: String) {
        withAnimation { feedbackText = msg }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            withAnimation { feedbackText = nil }
        }
    }
}
