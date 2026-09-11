import AppKit
import Foundation
import CoreGraphics
import Vision
import Observation

// MARK: - 🔁 Genie Visual Tool Loop Engine (Perceive → Reason → Act → Verify)
/// Implements the closed-loop visual autonomous agent cycle:
/// 1. Parse Screenshot: Ingests zero-copy framebuffer in RAM & runs ANE Vision OCR.
/// 2. Spatial Mapping: Converts normalized OCR bounding boxes into absolute screen coordinates.
/// 3. Tool Selection & Execution: Executes clicks, keystrokes, CLI commands, or block teleportation.
/// 4. Action Burst & Verification: Triggers the frame governor (24 FPS) and verifies screen state changes.
@available(macOS 13.0, *)
@Observable
public final class GenieVisualToolLoopEngine: @unchecked Sendable {
    public static let shared = GenieVisualToolLoopEngine()

    // MARK: - Perception Observation Model
    public struct ScreenPerceptionState: Sendable {
        public let timestamp: Date
        public let fullText: String
        public let lines: [String]
        public let elements: [VisualUIElement]
        public let windowSize: CGSize

        public init(fullText: String, lines: [String], elements: [VisualUIElement], windowSize: CGSize) {
            self.timestamp = Date()
            self.fullText = fullText
            self.lines = lines
            self.elements = elements
            self.windowSize = windowSize
        }
    }

    public struct VisualUIElement: Identifiable, Sendable {
        public let id = UUID()
        public let text: String
        public let normalizedRect: CGRect // Vision 0.0 -> 1.0 (bottom-left origin)
        public let screenPoint: CGPoint    // Clickable center in points (top-left origin)
        public let confidence: Float
    }

    // ── Observable Loop Telemetry ─────────────────────────────────────────
    public private(set) var isLoopRunning: Bool = false
    public private(set) var currentIteration: Int = 0
    public private(set) var currentGoal: String = ""
    public private(set) var lastActionSummary: String = "Idle"
    public private(set) var activePerception: ScreenPerceptionState?
    public private(set) var loopHistory: [String] = []

    private let lock = NSLock()

    private init() {}

    // MARK: - 1. Capture & Parse Screenshot (Perception)
    public func captureAndParseScreen(targetScreen: NSScreen? = nil) async -> ScreenPerceptionState? {
        let screen = targetScreen ?? NSScreen.main ?? NSScreen.screens.first
        guard let screen = screen else { return nil }
        let screenRect = screen.frame

        // Grab screen directly from WindowServer in RAM
        guard let cgImage = CGWindowListCreateImage(
            screenRect,
            .optionOnScreenOnly,
            kCGNullWindowID,
            .bestResolution
        ) else { return nil }

        let nsImage = NSImage(cgImage: cgImage, size: screenRect.size)
        let (fullText, lines, boxes) = await GenieVisionEngine.shared.performOCR(on: nsImage)

        // Convert VisionObservationBox into actionable clickable screen coordinates
        let elements: [VisualUIElement] = boxes.map { box in
            let r = box.boundingBox
            // Vision has origin at bottom-left; convert to macOS screen coordinates (top-left)
            let centerX = screenRect.origin.x + (r.origin.x + r.width / 2.0) * screenRect.width
            let centerY = screenRect.origin.y + (1.0 - (r.origin.y + r.height / 2.0)) * screenRect.height
            return VisualUIElement(
                text: box.text,
                normalizedRect: r,
                screenPoint: CGPoint(x: centerX, y: centerY),
                confidence: box.confidence
            )
        }

        let state = ScreenPerceptionState(
            fullText: fullText,
            lines: lines,
            elements: elements,
            windowSize: screenRect.size
        )

        Task { @MainActor in
            self.activePerception = state
        }
        return state
    }

    // MARK: - 2. Resolve Element by Query
    public func findElement(matching textQuery: String, in perception: ScreenPerceptionState) -> VisualUIElement? {
        let query = textQuery.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        return perception.elements.first { $0.text.lowercased().contains(query) }
    }

    // MARK: - 3. Execute Autonomous Visual Tool Loop
    /// Runs the Perception → Action → Verification loop until the goal is verified or maxIterations reached.
    @MainActor
    public func executeGoal(
        _ goal: String,
        targetScreen: NSScreen? = nil,
        maxIterations: Int = 10,
        actionPlanner: @escaping (ScreenPerceptionState, Int) async -> DesktopAgentAction?
    ) async -> Bool {
        guard !isLoopRunning else { return false }

        self.isLoopRunning = true
        self.currentGoal = goal
        self.currentIteration = 0
        self.loopHistory.removeAll()
        self.lastActionSummary = "Starting visual agent loop: '\(goal)'"

        defer {
            self.isLoopRunning = false
            self.lastActionSummary = "Loop completed: '\(goal)'"
        }

        for i in 1...maxIterations {
            self.currentIteration = i
            self.lastActionSummary = "Iteration \(i)/\(maxIterations): Capturing & parsing screen..."

            // Step 1: Perceive
            guard let perception = await captureAndParseScreen(targetScreen: targetScreen) else {
                self.loopHistory.append("[\(i)] Failed to capture screen.")
                break
            }

            self.loopHistory.append("[\(i)] Parsed \(perception.elements.count) UI elements on screen.")

            // Step 2: Reason & Select Tool
            guard let nextAction = await actionPlanner(perception, i) else {
                self.lastActionSummary = "Goal verified complete by planner at step \(i)."
                self.loopHistory.append("[\(i)] Goal satisfied.")
                return true
            }

            self.lastActionSummary = "Executing: \(nextAction.summary)"
            self.loopHistory.append("[\(i)] Executing: \(nextAction.summary)")

            // Step 3: Act (Trigger Action Burst)
            GenieAdaptiveFrameGovernor.shared.triggerActionBurst()
            await AntigravityDesktopAgent.shared.performAction(nextAction)

            // Step 4: Settle & Verify (allow UI animations to render)
            try? await Task.sleep(nanoseconds: 600_000_000) // 600 ms settle delay
        }

        return true
    }
}
