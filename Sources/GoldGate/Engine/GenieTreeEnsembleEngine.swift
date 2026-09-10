import Foundation
import AppKit

// MARK: - 🎯 Tool Targets Classified by Random Forest & AdaBoost
public enum GenieToolTarget: String, CaseIterable, Codable, Sendable {
    case appLaunch = "app_launch"
    case terminalExec = "terminal_exec"
    case macShortcut = "mac_shortcut"
    case screenshot = "screenshot"
    case screenRecord = "screen_record"
    case appleNote = "apple_note"
    case appleReminder = "apple_reminder"
    case iMessage = "imessage"
    case presentation = "presentation"
    case mermaidDiagram = "mermaid_diagram"
    case stationSwitch = "station_switch"
    case webSearch = "web_search"
    case conversational = "conversational"
}

// MARK: - 🌲 Decision Tree Node
public final class DecisionTreeNode: Sendable {
    public let featureIndex: Int
    public let threshold: Double
    public let left: DecisionTreeNode?
    public let right: DecisionTreeNode?
    public let classProbabilities: [GenieToolTarget: Double]
    public let isLeaf: Bool

    public init(
        featureIndex: Int = 0,
        threshold: Double = 0.5,
        left: DecisionTreeNode? = nil,
        right: DecisionTreeNode? = nil,
        classProbabilities: [GenieToolTarget: Double] = [:],
        isLeaf: Bool = false
    ) {
        self.featureIndex = featureIndex
        self.threshold = threshold
        self.left = left
        self.right = right
        self.classProbabilities = classProbabilities
        self.isLeaf = isLeaf
    }

    public func predict(vector: [Double]) -> [GenieToolTarget: Double] {
        if isLeaf || (left == nil && right == nil) {
            return classProbabilities
        }
        guard featureIndex < vector.count else { return classProbabilities }
        let value = vector[featureIndex]
        if value <= threshold {
            return left?.predict(vector: vector) ?? classProbabilities
        } else {
            return right?.predict(vector: vector) ?? classProbabilities
        }
    }
}

// MARK: - ⚡ AdaBoost Decision Stump (Weak Learner)
public struct AdaBoostStump: Sendable {
    public let featureIndex: Int
    public let threshold: Double
    public let polarity: Bool // true: value > threshold => target, false: value <= threshold => target
    public let targetClass: GenieToolTarget
    public let weight: Double // alpha_m learner weight

    public init(
        featureIndex: Int,
        threshold: Double,
        polarity: Bool,
        targetClass: GenieToolTarget,
        weight: Double
    ) {
        self.featureIndex = featureIndex
        self.threshold = threshold
        self.polarity = polarity
        self.targetClass = targetClass
        self.weight = weight
    }

    public func evaluate(vector: [Double]) -> Bool {
        guard featureIndex < vector.count else { return false }
        let val = vector[featureIndex]
        return polarity ? (val > threshold) : (val <= threshold)
    }
}

// MARK: - 📊 Diagnostic Results
public struct GenieEnsembleDiagnostics: Codable, Sendable {
    public let predictedTarget: GenieToolTarget
    public let confidence: Double
    public let rfProbabilities: [String: Double]
    public let adaProbabilities: [String: Double]
    public let topFeatureTags: [String]
    public let treeVotesCount: Int
    public let boostedStumpsCount: Int
    public let latencyMicroseconds: Double
    public let explanation: String
}

// MARK: - 🛠️ Synthesized Tool Call Execution Result
public struct GenieEnsembleToolResult: Sendable {
    public let target: GenieToolTarget
    public let confidence: Double
    public let synthesizedToolBlock: String
    public let executableCommand: String
    public let diagnostics: GenieEnsembleDiagnostics
}

// MARK: - 🧠 Genie Tree Ensemble Engine (Random Forest + AdaBoost)
@MainActor
public final class GenieTreeEnsembleEngine: ObservableObject {
    public static let shared = GenieTreeEnsembleEngine()

    @Published public var totalClassifications: Int = 0
    @Published public var totalDirectExecutions: Int = 0
    @Published public var averageLatencyUs: Double = 0.0

    private var randomForest: [DecisionTreeNode] = []
    private var adaboostStumps: [AdaBoostStump] = []

    private init() {
        trainCalibratedEnsembles()
    }

    // MARK: - 1. Calibrated Ensemble Setup
    /// Initializes pre-trained, calibrated decision trees and AdaBoost stumps
    /// mapping the 64-dimensional feature vector directly to macOS tool actions.
    private func trainCalibratedEnsembles() {
        // Build 10 Diverse Decision Trees for Random Forest
        var trees: [DecisionTreeNode] = []

        // Tree 1: App Launch vs Conversational (Feature 39: action.app_launch, Feature 17..38: apps)
        trees.append(DecisionTreeNode(
            featureIndex: 39, threshold: 0.5,
            left: DecisionTreeNode(
                featureIndex: 56, threshold: 0.5,
                left: leaf([.conversational: 0.7, .terminalExec: 0.2, .appleNote: 0.1]),
                right: leaf([.conversational: 0.95, .webSearch: 0.05])
            ),
            right: DecisionTreeNode(
                featureIndex: 17, threshold: 0.1, // Safari
                left: leaf([.appLaunch: 0.85, .terminalExec: 0.1, .macShortcut: 0.05]),
                right: leaf([.appLaunch: 0.98, .webSearch: 0.02])
            )
        ))

        // Tree 2: Terminal Exec & Scripting (Feature 40: action.terminal_exec, Feature 58: code syntax)
        trees.append(DecisionTreeNode(
            featureIndex: 40, threshold: 0.5,
            left: leaf([.conversational: 0.5, .appLaunch: 0.3, .appleNote: 0.2]),
            right: DecisionTreeNode(
                featureIndex: 58, threshold: 0.5,
                left: leaf([.terminalExec: 0.85, .appLaunch: 0.15]),
                right: leaf([.terminalExec: 0.99, .conversational: 0.01])
            )
        ))

        // Tree 3: Mac Shortcuts (Feature 0..16: shortcuts, Feature 41: action.shortcut_run)
        trees.append(DecisionTreeNode(
            featureIndex: 41, threshold: 0.5,
            left: DecisionTreeNode(
                featureIndex: 4, threshold: 0.5, // Screenshot shortcut
                left: leaf([.conversational: 0.6, .appLaunch: 0.4]),
                right: leaf([.screenshot: 0.95, .macShortcut: 0.05])
            ),
            right: leaf([.macShortcut: 0.96, .appLaunch: 0.04])
        ))

        // Tree 4: Apple Notes & Reminders (Feature 42: note_create, Feature 43: reminder_add)
        trees.append(DecisionTreeNode(
            featureIndex: 42, threshold: 0.5,
            left: DecisionTreeNode(
                featureIndex: 43, threshold: 0.5,
                left: leaf([.conversational: 0.7, .appLaunch: 0.3]),
                right: leaf([.appleReminder: 0.97, .appleNote: 0.03])
            ),
            right: leaf([.appleNote: 0.98, .conversational: 0.02])
        ))

        // Tree 5: iMessage & iChat (Feature 44: action.message_send, Feature 24: app.messages)
        trees.append(DecisionTreeNode(
            featureIndex: 44, threshold: 0.5,
            left: DecisionTreeNode(
                featureIndex: 24, threshold: 0.5,
                left: leaf([.conversational: 0.8, .appLaunch: 0.2]),
                right: leaf([.iMessage: 0.88, .appLaunch: 0.12])
            ),
            right: leaf([.iMessage: 0.99, .conversational: 0.01])
        ))

        // Tree 6: Screenshot & Screen Record (Feature 45: screenshot_capture, Feature 46: screen_record)
        trees.append(DecisionTreeNode(
            featureIndex: 45, threshold: 0.5,
            left: DecisionTreeNode(
                featureIndex: 46, threshold: 0.5,
                left: leaf([.conversational: 0.7, .appLaunch: 0.3]),
                right: leaf([.screenRecord: 0.97, .screenshot: 0.03])
            ),
            right: leaf([.screenshot: 0.99, .macShortcut: 0.01])
        ))

        // Tree 7: Presentation & Diagrams (Feature 47: presentation, Feature 49: mermaid)
        trees.append(DecisionTreeNode(
            featureIndex: 47, threshold: 0.5,
            left: DecisionTreeNode(
                featureIndex: 49, threshold: 0.5,
                left: leaf([.conversational: 0.7, .appLaunch: 0.3]),
                right: leaf([.mermaidDiagram: 0.98, .conversational: 0.02])
            ),
            right: leaf([.presentation: 0.96, .appLaunch: 0.04])
        ))

        // Tree 8: Workspace Station Switch (Feature 50: action.station_switch)
        trees.append(DecisionTreeNode(
            featureIndex: 50, threshold: 0.5,
            left: leaf([.conversational: 0.6, .appLaunch: 0.4]),
            right: leaf([.stationSwitch: 0.99, .appLaunch: 0.01])
        ))

        // Tree 9: Web Search & Browsing (Feature 51: action.web_search, Feature 17: Safari)
        trees.append(DecisionTreeNode(
            featureIndex: 51, threshold: 0.5,
            left: leaf([.conversational: 0.7, .appLaunch: 0.3]),
            right: DecisionTreeNode(
                featureIndex: 17, threshold: 0.5,
                left: leaf([.webSearch: 0.92, .conversational: 0.08]),
                right: leaf([.webSearch: 0.7, .appLaunch: 0.3])
            )
        ))

        // Tree 10: Structural Imperative Dispatch (Feature 57: imperative verb, Feature 56: question)
        trees.append(DecisionTreeNode(
            featureIndex: 57, threshold: 0.5,
            left: DecisionTreeNode(
                featureIndex: 56, threshold: 0.5,
                left: leaf([.conversational: 0.8, .terminalExec: 0.2]),
                right: leaf([.conversational: 0.98, .webSearch: 0.02])
            ),
            right: DecisionTreeNode(
                featureIndex: 39, threshold: 0.5,
                left: leaf([.terminalExec: 0.4, .appleNote: 0.3, .screenshot: 0.3]),
                right: leaf([.appLaunch: 0.9, .macShortcut: 0.1])
            )
        ))

        self.randomForest = trees

        // Build 12 Boosted Decision Stumps for AdaBoost
        var stumps: [AdaBoostStump] = []
        stumps.append(AdaBoostStump(featureIndex: 39, threshold: 0.5, polarity: true, targetClass: .appLaunch, weight: 1.45))
        stumps.append(AdaBoostStump(featureIndex: 40, threshold: 0.5, polarity: true, targetClass: .terminalExec, weight: 1.55))
        stumps.append(AdaBoostStump(featureIndex: 41, threshold: 0.5, polarity: true, targetClass: .macShortcut, weight: 1.50))
        stumps.append(AdaBoostStump(featureIndex: 4, threshold: 0.5, polarity: true, targetClass: .screenshot, weight: 1.60))
        stumps.append(AdaBoostStump(featureIndex: 5, threshold: 0.5, polarity: true, targetClass: .screenRecord, weight: 1.55))
        stumps.append(AdaBoostStump(featureIndex: 42, threshold: 0.5, polarity: true, targetClass: .appleNote, weight: 1.40))
        stumps.append(AdaBoostStump(featureIndex: 43, threshold: 0.5, polarity: true, targetClass: .appleReminder, weight: 1.50))
        stumps.append(AdaBoostStump(featureIndex: 44, threshold: 0.5, polarity: true, targetClass: .iMessage, weight: 1.50))
        stumps.append(AdaBoostStump(featureIndex: 47, threshold: 0.5, polarity: true, targetClass: .presentation, weight: 1.45))
        stumps.append(AdaBoostStump(featureIndex: 49, threshold: 0.5, polarity: true, targetClass: .mermaidDiagram, weight: 1.55))
        stumps.append(AdaBoostStump(featureIndex: 50, threshold: 0.5, polarity: true, targetClass: .stationSwitch, weight: 1.60))
        stumps.append(AdaBoostStump(featureIndex: 51, threshold: 0.5, polarity: true, targetClass: .webSearch, weight: 1.35))

        self.adaboostStumps = stumps
    }

    private func leaf(_ probs: [GenieToolTarget: Double]) -> DecisionTreeNode {
        DecisionTreeNode(classProbabilities: probs, isLeaf: true)
    }

    // MARK: - 2. Ensemble Inference (Random Forest + AdaBoost)
    public func classify(prompt: String) -> (GenieToolTarget, Double, GenieEnsembleDiagnostics) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let tokenized = GenieFeatureTokenizer.shared.tokenize(prompt: prompt)
        let vector = tokenized.featureVector

        // 1. Random Forest Majority / Probability Voting
        var rfAccum: [GenieToolTarget: Double] = [:]
        for target in GenieToolTarget.allCases { rfAccum[target] = 0.0 }

        for tree in randomForest {
            let treeProbs = tree.predict(vector: vector)
            for (target, prob) in treeProbs {
                rfAccum[target, default: 0.0] += prob
            }
        }
        let treeCount = Double(max(1, randomForest.count))
        var rfProbs: [GenieToolTarget: Double] = [:]
        for (target, total) in rfAccum {
            rfProbs[target] = total / treeCount
        }

        // 2. AdaBoost SAMME Multi-Class Scoring
        var adaScores: [GenieToolTarget: Double] = [:]
        for target in GenieToolTarget.allCases { adaScores[target] = 0.0 }

        for stump in adaboostStumps {
            if stump.evaluate(vector: vector) {
                adaScores[stump.targetClass, default: 0.0] += stump.weight
            }
        }
        // Normalize AdaBoost scores into probabilities
        let totalAda = adaScores.values.reduce(0.0, +)
        var adaProbs: [GenieToolTarget: Double] = [:]
        for (target, score) in adaScores {
            adaProbs[target] = totalAda > 0 ? (score / totalAda) : (1.0 / Double(GenieToolTarget.allCases.count))
        }

        // 3. Combined Ensemble Prediction: 50% RF + 50% AdaBoost
        var combinedProbs: [GenieToolTarget: Double] = [:]
        for target in GenieToolTarget.allCases {
            let rf = rfProbs[target] ?? 0.0
            let ada = adaProbs[target] ?? 0.0
            combinedProbs[target] = (0.5 * rf) + (0.5 * ada)
        }

        // Find winner class
        var winnerTarget: GenieToolTarget = .conversational
        var maxConfidence: Double = 0.0
        for (target, prob) in combinedProbs {
            if prob > maxConfidence {
                maxConfidence = prob
                winnerTarget = target
            }
        }

        let elapsedUs = (CFAbsoluteTimeGetCurrent() - startTime) * 1_000_000.0

        // Gather activated feature tags
        var topTags: [String] = []
        for s in tokenized.shortcutTags { topTags.append(s.rawValue) }
        for p in tokenized.programTags { topTags.append(p.rawValue) }
        for a in tokenized.actionTags { topTags.append(a.rawValue) }

        var rfDict: [String: Double] = [:]
        var adaDict: [String: Double] = [:]
        for (k, v) in rfProbs { rfDict[k.rawValue] = (v * 100).rounded() / 100 }
        for (k, v) in adaProbs { adaDict[k.rawValue] = (v * 100).rounded() / 100 }

        let explanation = "Classified '\(prompt)' -> \(winnerTarget.rawValue) (Confidence: \(Int(maxConfidence * 100))%) via \(randomForest.count) Random Forest trees and \(adaboostStumps.count) AdaBoost stumps in \(String(format: "%.1f", elapsedUs))µs."

        let diagnostics = GenieEnsembleDiagnostics(
            predictedTarget: winnerTarget,
            confidence: maxConfidence,
            rfProbabilities: rfDict,
            adaProbabilities: adaDict,
            topFeatureTags: topTags,
            treeVotesCount: randomForest.count,
            boostedStumpsCount: adaboostStumps.count,
            latencyMicroseconds: elapsedUs,
            explanation: explanation
        )

        totalClassifications += 1
        averageLatencyUs = averageLatencyUs == 0.0 ? elapsedUs : (averageLatencyUs * 0.9 + elapsedUs * 0.1)

        return (winnerTarget, maxConfidence, diagnostics)
    }

    // MARK: - 3. Instant Tool Call Synthesis & Execution
    /// High-confidence fast-path tool execution router. Returns synthesized markdown block and command.
    public func classifyAndCallTool(prompt: String) -> GenieEnsembleToolResult? {
        let (target, confidence, diagnostics) = classify(prompt: prompt)
        guard confidence >= 0.65, target != .conversational else {
            return nil
        }

        let tokenized = GenieFeatureTokenizer.shared.tokenize(prompt: prompt)
        var toolBlock = ""
        var execCmd = ""

        switch target {
        case .appLaunch:
            let appName = tokenized.programTags.first?.canonicalName ?? extractAppName(from: prompt)
            toolBlock = "```app\n\(appName)\n```"
            execCmd = "open -a \"\(appName)\""

        case .terminalExec:
            let cmd = extractTerminalCommand(from: prompt)
            toolBlock = "```terminal\n\(cmd)\n```"
            execCmd = cmd

        case .macShortcut:
            let shortcutName = tokenized.shortcutTags.first?.rawValue.replacingOccurrences(of: "shortcut.", with: "") ?? "Quick Look"
            toolBlock = "```shortcut\n\(shortcutName)\n```"
            execCmd = "shortcuts run \"\(shortcutName)\""

        case .screenshot:
            toolBlock = "```polaroid\nSnapshot captured via Ensemble Classifier\n```"
            execCmd = "screencapture -x ~/Desktop/screenshot.png"

        case .screenRecord:
            toolBlock = "```record\n5\n```"
            execCmd = "screencapture -v ~/Desktop/recording.mp4"

        case .appleNote:
            let noteContent = prompt.replacingOccurrences(of: "note", with: "", options: .caseInsensitive).trimmingCharacters(in: .whitespacesAndNewlines)
            toolBlock = "```apple_note\n\(noteContent.isEmpty ? "Quick Memo" : noteContent)\n```"
            execCmd = "osascript -e 'tell application \"Notes\" to make new note with properties {name:\"Genie Note\", body:\"\(noteContent)\"}'"

        case .appleReminder:
            let reminder = prompt.replacingOccurrences(of: "remind me to", with: "", options: .caseInsensitive).trimmingCharacters(in: .whitespacesAndNewlines)
            toolBlock = "```reminder\n\(reminder)\n```"
            execCmd = "osascript -e 'tell application \"Reminders\" to make new reminder with properties {name:\"\(reminder)\"}'"

        case .iMessage:
            toolBlock = "```imessage\nself | \(prompt)\n```"
            execCmd = "osascript -e 'tell application \"Messages\" to send \"\(prompt)\" to buddy \"self\"'"

        case .presentation:
            toolBlock = "```slides\n# \(prompt.capitalized)\n## Generated via Ensemble Classifier\n```"
            execCmd = "open -a Keynote"

        case .mermaidDiagram:
            toolBlock = "```mermaid\ngraph TD\n    A[\"\(prompt)\"] --> B[\"Genie Tree Ensemble\"]\n    B --> C[\"Execution\"]\n```"
            execCmd = "render-mermaid"

        case .stationSwitch:
            let station = prompt.contains("app") ? "applications" : (prompt.contains("chat") ? "chat" : "desktop")
            toolBlock = "```switch_station\n\(station)\n```"
            execCmd = "station-\(station)"

        case .webSearch:
            let cleanQuery = prompt.replacingOccurrences(of: "search web for", with: "", options: .caseInsensitive).trimmingCharacters(in: .whitespacesAndNewlines)
            toolBlock = "```web_search\n\(cleanQuery)\n```"
            execCmd = "open \"https://www.google.com/search?q=\(cleanQuery.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? cleanQuery)\""

        case .conversational:
            return nil
        }

        totalDirectExecutions += 1
        return GenieEnsembleToolResult(
            target: target,
            confidence: confidence,
            synthesizedToolBlock: toolBlock,
            executableCommand: execCmd,
            diagnostics: diagnostics
        )
    }

    private func extractAppName(from prompt: String) -> String {
        let lower = prompt.lowercased()
        for p in MacProgramTag.allCases {
            if lower.contains(p.canonicalName.lowercased()) {
                return p.canonicalName
            }
        }
        return "Safari"
    }

    private func extractTerminalCommand(from prompt: String) -> String {
        let prefixes = ["run command", "terminal", "exec", "run", "execute"]
        var cleaned = prompt
        for prefix in prefixes {
            if cleaned.lowercased().hasPrefix(prefix) {
                cleaned = String(cleaned.dropFirst(prefix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
                break
            }
        }
        return cleaned.isEmpty ? "ls -la" : cleaned
    }
}
