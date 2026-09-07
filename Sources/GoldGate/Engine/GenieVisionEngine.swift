import AppKit
import CoreGraphics
import Foundation
import ScreenCaptureKit
import SwiftUI
import Vision

// MARK: - Vision Observation Box (Normalized Bounding Coordinates)
public struct VisionObservationBox: Identifiable, Equatable {
    public let id = UUID()
    public let text: String
    public let boundingBox: CGRect // Normalized (0.0 ... 1.0) in standard Cartesian or flipped screen coords
    public let confidence: Float

    public init(text: String, boundingBox: CGRect, confidence: Float = 1.0) {
        self.text = text
        self.boundingBox = boundingBox
        self.confidence = confidence
    }
}

// MARK: - Genie Universal Screen Vision & Optical Intelligence Engine
@MainActor
public final class GenieVisionEngine: ObservableObject {
    public static let shared = GenieVisionEngine()

    // ── Observable Telemetry ───────────────────────────────────────────────
    @Published public var isAnalyzing: Bool = false
    @Published public var lastCapturedImage: NSImage? = nil
    @Published public var lastCapturedImagePath: String? = nil
    @Published public var recognizedText: String = ""
    @Published public var recognizedLines: [String] = []
    @Published public var recognizedBoxes: [VisionObservationBox] = []
    @Published public var recognizedWordCount: Int = 0
    @Published public var recognizedCharCount: Int = 0
    @Published public var statusFeedback: String? = nil
    @Published public var lastCaptureTime: Date = Date()
    @Published public var showVisionPreviewPopover: Bool = false

    private init() {}

    // MARK: - Screen & Window Optical Capture
    /// Captures the current active screen or frontmost window pixels instantly
    public func captureActiveScreen() -> NSImage? {
        // 1. First attempt display capture of main screen
        guard let mainScreen = NSScreen.main else { return nil }
        let screenRect = mainScreen.frame

        // Exclude Genie itself from the capture if possible, capturing on-screen content
        if let cgImage = CGWindowListCreateImage(
            screenRect,
            .optionOnScreenOnly,
            kCGNullWindowID,
            .bestResolution
        ) {
            let nsImage = NSImage(cgImage: cgImage, size: screenRect.size)
            return nsImage
        }

        return nil
    }

    // MARK: - Sub-Millisecond Apple Silicon Neural Engine OCR
    /// Executes native VNRecognizeTextRequest on background thread with accurate language correction
    public func performOCR(on image: NSImage) async -> (text: String, lines: [String], boxes: [VisionObservationBox]) {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return ("", [], [])
        }

        return await Task.detached(priority: .userInitiated) {
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            if #available(macOS 13.0, *) {
                request.automaticallyDetectsLanguage = true
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                return ("", [], [])
            }

            guard let observations = request.results else {
                return ("", [], [])
            }

            var lines: [String] = []
            var boxes: [VisionObservationBox] = []

            for obs in observations {
                guard let candidate = obs.topCandidates(1).first else { continue }
                let text = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else { continue }

                lines.append(text)
                boxes.append(VisionObservationBox(text: text, boundingBox: obs.boundingBox, confidence: candidate.confidence))
            }

            let fullText = lines.joined(separator: "\n")
            return (fullText, lines, boxes)
        }.value
    }

    // MARK: - One-Shot Screen Scan & Optical Intelligence
    /// Captures the screen, triggers camera shutter audio, runs Apple Vision OCR, and updates state
    @discardableResult
    public func scanActiveScreenAndRecognize() async -> String {
        self.isAnalyzing = true
        self.statusFeedback = "Scanning display with Apple Vision..."
        HapticFeedback.playCameraSnapshotSound()

        guard let snapshot = captureActiveScreen() else {
            self.isAnalyzing = false
            self.statusFeedback = "Unable to capture screen."
            return ""
        }

        self.lastCapturedImage = snapshot
        self.lastCaptureTime = Date()

        // Cache image to temporary disk location for multimodal AI payload ingestion
        self.lastCapturedImagePath = persistTemporarySnapshot(image: snapshot)

        // Execute Vision OCR
        let (fullText, lines, boxes) = await performOCR(on: snapshot)

        self.recognizedText = fullText
        self.recognizedLines = lines
        self.recognizedBoxes = boxes
        self.recognizedCharCount = fullText.count

        let words = fullText.split(whereSeparator: { $0.isWhitespace || $0.isNewline })
        self.recognizedWordCount = words.count

        self.isAnalyzing = false

        if fullText.isEmpty {
            self.statusFeedback = "No legible text found on screen."
            HapticFeedback.testWaterDrop()
        } else {
            self.statusFeedback = "Extracted \(self.recognizedWordCount) words (\(lines.count) lines) via Apple Vision"
            HapticFeedback.success()
        }

        return fullText
    }

    // MARK: - Persist Temporary Snapshot for Multimodal Attachment
    private func persistTemporarySnapshot(image: NSImage) -> String? {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("Genie_Screen_Vision_\(Int(Date().timeIntervalSince1970)).png")
        if let tiff = image.tiffRepresentation,
           let rep = NSBitmapImageRep(data: tiff),
           let pngData = rep.representation(using: .png, properties: [:]) {
            do {
                try pngData.write(to: fileURL)
                return fileURL.path
            } catch {
                return nil
            }
        }
        return nil
    }

    // MARK: - Atomic Visual Lookup Intent Detection
    /// Evaluates if the natural language query asks about on-screen visual content
    public func shouldTriggerAtomicLookup(for query: String) -> Bool {
        let lower = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !lower.isEmpty else { return false }

        // Explicit directives
        if lower.hasPrefix("!vision") || lower.hasPrefix("!ocr") || lower.hasPrefix("!screen") || lower.hasPrefix("!readscreen") || lower.hasPrefix("!look") || lower.hasPrefix("!inspect") {
            return true
        }

        let visualKeywords = [
            "on my screen", "on screen", "look at this", "look at my screen",
            "what's on my screen", "what is on my screen", "what am i looking at",
            "what's in front of me", "what is in front of me", "read this",
            "summarize my screen", "summarize what's on my screen", "describe my screen",
            "explain this code", "explain this error", "what error is this", "fix this error",
            "what does this error mean", "error on screen", "what app is open", "extract text",
            "read this error", "what is written here", "see this", "inspect this",
            "what is selected", "what window is this", "what does this say"
        ]

        for keyword in visualKeywords {
            if lower.contains(keyword) {
                return true
            }
        }
        return false
    }

    // MARK: - Atomic Visual Lookup & Prompt Augmentation
    /// Atomically captures screen pixels, performs OCR, updates state & inline preview, and augments the prompt
    @discardableResult
    public func performAtomicVisualLookup(for query: String, previewInTray: Bool = true) async -> (augmentedPrompt: String, snapshot: NSImage?, recognizedText: String) {
        self.isAnalyzing = true
        self.statusFeedback = "Executing Atomic Visual Lookup via Neural Vision..."
        HapticFeedback.playCameraSnapshotSound()

        guard let snapshot = captureActiveScreen() else {
            self.isAnalyzing = false
            self.statusFeedback = "Unable to capture screen."
            return (query, nil, "")
        }

        self.lastCapturedImage = snapshot
        self.lastCaptureTime = Date()
        self.lastCapturedImagePath = persistTemporarySnapshot(image: snapshot)

        // Execute Vision OCR
        let (fullText, lines, boxes) = await performOCR(on: snapshot)
        self.recognizedText = fullText
        self.recognizedLines = lines
        self.recognizedBoxes = boxes
        self.recognizedCharCount = fullText.count

        let words = fullText.split(whereSeparator: { $0.isWhitespace || $0.isNewline })
        self.recognizedWordCount = words.count
        self.isAnalyzing = false

        // Determine Frontmost Running Application
        let frontAppName = NSWorkspace.shared.frontmostApplication?.localizedName ?? "macOS Desktop"

        // Trigger Live Inline Preview Tray above the search bar
        if previewInTray {
            ChatInlinePreviewManager.shared.showVisualLookupPreview(
                image: snapshot,
                ocrText: fullText.isEmpty ? "No legible text on screen" : fullText,
                lineCount: lines.count,
                wordCount: words.count,
                notice: "Atomic Visual Grounding: \(frontAppName) (\(words.count) words) 👁️"
            )
        }

        if fullText.isEmpty {
            self.statusFeedback = "Visual Lookup complete: No legible text found."
            HapticFeedback.testWaterDrop()
        } else {
            self.statusFeedback = "Visual Lookup: \(self.recognizedWordCount) words extracted via Neural Engine"
            HapticFeedback.success()
        }

        // Formulate Grounded Augmented Prompt
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let effectiveQuery = cleanQuery.isEmpty ? "Explain and analyze what is on my screen right now." : cleanQuery

        var augmented = "\(effectiveQuery)\n\n"
        augmented += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        augmented += "👁️ [Atomic Visual Screen Grounding - Frontmost App: \(frontAppName)]\n"
        augmented += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n"
        if fullText.isEmpty {
            augmented += "(Screen captured, but no prominent text detected)\n"
        } else {
            augmented += "\(fullText)\n"
        }
        augmented += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        return (augmented, snapshot, fullText)
    }

    // MARK: - Clipboard & Note Integrations
    /// Copies recognized OCR text to macOS system clipboard with haptics
    public func copyRecognizedText() {
        guard !recognizedText.isEmpty else { return }
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(recognizedText, forType: .string)
        HapticFeedback.selection()
        self.statusFeedback = "Copied \(recognizedWordCount) words to Clipboard! 📋"
    }

    /// Inscribes the optical extraction into a clean Markdown note on Desktop
    @discardableResult
    public func saveAsMarkdownNote(title: String = "Screen Capture OCR") -> URL? {
        guard !recognizedText.isEmpty else { return nil }
        let header = "# \(title)\n*Captured via Genie Optical Vision Engine on \(Date().formatted())*\n\n---\n\n"
        let fullDoc = header + recognizedText
        let savedURL = DesktopNotePrinter.shared.saveMarkdownToDesktop(content: fullDoc)
        HapticFeedback.playPrinterSound()
        self.statusFeedback = "Saved Optical Note to Desktop 📄"
        return savedURL
    }

    /// Attaches the optical context and queries AI Assistant
    public func askAIWithVision(query: String, manager: LocalModelManager? = nil) {
        let mgr = manager ?? LocalModelManager.shared
        let cleanQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let ocr = recognizedText.trimmingCharacters(in: .whitespacesAndNewlines)

        let effectivePrompt: String
        if cleanQuery.isEmpty {
            effectivePrompt = "Summarize and explain what is visible on my screen based on this OCR extraction:\n\n\(ocr)"
        } else if ocr.isEmpty {
            effectivePrompt = cleanQuery
        } else {
            effectivePrompt = "\(cleanQuery)\n\n[Optical Screen Vision OCR Context]:\n\(ocr)"
        }

        mgr.generate(
            prompt: effectivePrompt,
            overrideModel: nil,
            mediaPath: self.lastCapturedImagePath,
            mediaType: "screen_vision"
        )
    }
}
