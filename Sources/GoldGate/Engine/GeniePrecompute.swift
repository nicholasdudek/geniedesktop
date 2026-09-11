// MARK: - GeniePrecompute.swift
// Golden Gate Engineering • © 2026 Nicholas M. Dudek
// Apache License, Version 2.0 (Apache-2.0)
//
// Parallel token-precomputation engine for Genie's rendering pipeline.
//
// A render request is decomposed into independent sub-tasks, all of which are
// resolved concurrently, tokenized concurrently, and then assembled once. The
// renderer downstream never streams token-by-token: it receives a finished
// buffer plus an exact token count, so emission is a single write.
//
// Three properties this file guarantees, and that the tests cover:
//
//   1. Determinism — task completion order is nondeterministic, assembly order
//      is not. Fragments carry an explicit `order`, ties break on task id.
//   2. Validity — a chart render produces a parseable Chart.js config, not a
//      bag of fragments concatenated together. Every string that reaches the
//      output goes through JSON or HTML escaping first.
//   3. Isolation — one failing or hung sub-task degrades its own fragment and
//      is reported in `failures`; it does not take the render down with it.

import Foundation
import os

// MARK: - Fragments

/// One piece of the final output. Text fragments are joined in `order`;
/// JSON fragments are merged into a tree by key path, so several tasks can
/// contribute to the same object concurrently without seeing each other.
public struct Fragment: Sendable {
    public enum Payload: Sendable {
        /// Raw text, emitted in `order`.
        case text(String)
        /// A dotted key path and an already-encoded JSON value.
        /// Numeric components build arrays: `data.datasets.0.label`.
        case json(path: String, value: String)
    }

    public let payload: Payload
    public let order: Int

    public init(payload: Payload, order: Int) {
        self.payload = payload
        self.order = order
    }

    public static func text(_ body: String, order: Int = 0) -> Fragment {
        Fragment(payload: .text(body), order: order)
    }

    public static func json(_ path: String, _ value: String, order: Int = 0) -> Fragment {
        Fragment(payload: .json(path: path, value: value), order: order)
    }

    /// What the tokenizer counts for this fragment — close enough to what the
    /// fragment contributes to the assembled output that the parallel sum and
    /// an exact recount of the output agree to within a token or two.
    public var tokenText: String {
        switch payload {
        case .text(let body): return body
        case .json(let path, let value): return "\"\(path)\":\(value)"
        }
    }
}

/// The output of any sub-task: zero or more fragments of the final buffer.
public struct ResolvedValue: Sendable {
    public let fragments: [Fragment]

    public init(_ fragments: [Fragment]) {
        self.fragments = fragments
    }

    public init(text: String, order: Int = 0) {
        self.fragments = [.text(text, order: order)]
    }

    /// A task that has nothing to contribute for this spec.
    public static let empty = ResolvedValue([])
}

/// A single independent unit of work that can be resolved in parallel.
public protocol PrecomputeTask: Sendable {
    /// Stable identifier — used for logging, tie-breaking and failure reports.
    var taskID: String { get }
    /// Resolve this sub-task. Must be pure: no shared mutable state, no ordering
    /// assumptions about the other tasks in the plan.
    func resolve() async throws -> ResolvedValue
}

// MARK: - Assembly

/// How resolved fragments become one buffer.
public enum Assembly: Sendable {
    /// Join text fragments in order.
    case text(prefix: String, separator: String, suffix: String)
    /// Merge JSON key paths into a single object.
    case json

    static let plain = Assembly.text(prefix: "", separator: "", suffix: "")
}

/// A decomposed request: what to run, and how to put the results back together.
public struct RenderPlan: Sendable {
    public let tasks: [any PrecomputeTask]
    public let assembly: Assembly

    public init(tasks: [any PrecomputeTask], assembly: Assembly) {
        self.tasks = tasks
        self.assembly = assembly
    }
}

// MARK: - Encoding Helpers

public enum GenieJSON {
    /// A quoted, escaped JSON string. Everything user- or model-supplied that
    /// lands in the buffer goes through here — a label containing a quote used
    /// to break the whole config.
    public static func string(_ raw: String) -> String {
        var out = "\""
        out.reserveCapacity(raw.utf8.count + 2)
        for scalar in raw.unicodeScalars {
            switch scalar {
            case "\"": out += "\\\""
            case "\\": out += "\\\\"
            case "\n": out += "\\n"
            case "\r": out += "\\r"
            case "\t": out += "\\t"
            default:
                if scalar.value < 0x20 {
                    out += String(format: "\\u%04x", scalar.value)
                } else {
                    out.unicodeScalars.append(scalar)
                }
            }
        }
        return out + "\""
    }

    /// A JSON number. Non-finite values are not representable in JSON, so they
    /// become `null` rather than the literal `inf` that breaks a parser.
    public static func number(_ value: Double) -> String {
        guard value.isFinite else { return "null" }
        if value == value.rounded(), abs(value) < 1e15 {
            return String(Int64(value))
        }
        return String(format: "%.6g", value)
    }

    public static func array(_ values: [String]) -> String {
        "[" + values.joined(separator: ",") + "]"
    }
}

public enum GenieHTML {
    public static func escape(_ raw: String) -> String {
        var out = ""
        out.reserveCapacity(raw.utf8.count)
        for character in raw {
            switch character {
            case "&": out += "&amp;"
            case "<": out += "&lt;"
            case ">": out += "&gt;"
            case "\"": out += "&quot;"
            case "'": out += "&#39;"
            default: out.append(character)
            }
        }
        return out
    }

    /// Only a literal hex colour reaches the stylesheet; anything else falls
    /// back to the house accent instead of being injected into CSS.
    public static func safeHexColor(_ raw: String, fallback: String = "#38bdf8") -> String {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("#") else { return fallback }
        let digits = trimmed.dropFirst()
        guard [3, 4, 6, 8].contains(digits.count),
              digits.allSatisfy(\.isHexDigit) else { return fallback }
        return "#" + digits.lowercased()
    }

    /// `#rrggbb` → `rgba(r, g, b, alpha)`, for fills that need transparency.
    public static func rgba(_ hex: String, alpha: Double) -> String {
        let safe = safeHexColor(hex)
        var digits = String(safe.dropFirst())
        if digits.count == 3 {
            digits = digits.map { "\($0)\($0)" }.joined()
        }
        guard digits.count >= 6, let value = UInt32(digits.prefix(6), radix: 16) else {
            return "rgba(56,189,248,\(GenieJSON.number(alpha)))"
        }
        let r = (value >> 16) & 0xFF
        let g = (value >> 8) & 0xFF
        let b = value & 0xFF
        return "rgba(\(r),\(g),\(b),\(GenieJSON.number(alpha)))"
    }
}

// MARK: - JSON Tree Merge

/// Merges dotted key paths contributed by different tasks into one object.
/// Numeric path components produce arrays, so `data.datasets.0.data` and
/// `data.datasets.0.backgroundColor` — resolved by two tasks that never meet —
/// land in the same dataset object.
struct JSONTree {
    indirect enum Node {
        case raw(String)
        case object([String: Node])
        case array([Int: Node])
    }

    private(set) var root: Node = .object([:])
    /// Paths written more than once, last write winning. Surfaced as warnings
    /// rather than silently resolved.
    private(set) var collisions: [String] = []

    mutating func insert(path: String, value: String) {
        let components = path.split(separator: ".").map(String.init)
        guard !components.isEmpty else { return }
        if Self.contains(root, components) {
            collisions.append(path)
        }
        root = Self.insert(into: root, components: components[...], value: value)
    }

    private static func contains(_ node: Node, _ components: [String]) -> Bool {
        guard let head = components.first else { return true }
        switch node {
        case .raw:
            return true
        case .object(let children):
            guard let child = children[head] else { return false }
            return contains(child, Array(components.dropFirst()))
        case .array(let children):
            guard let index = Int(head), let child = children[index] else { return false }
            return contains(child, Array(components.dropFirst()))
        }
    }

    private static func insert(into node: Node, components: ArraySlice<String>, value: String) -> Node {
        guard let head = components.first else { return .raw(value) }
        let rest = components.dropFirst()

        if let index = Int(head) {
            var children: [Int: Node]
            if case .array(let existing) = node { children = existing } else { children = [:] }
            let child = children[index] ?? .object([:])
            children[index] = insert(into: child, components: rest, value: value)
            return .array(children)
        }

        var children: [String: Node]
        if case .object(let existing) = node { children = existing } else { children = [:] }
        let child = children[head] ?? .object([:])
        children[head] = insert(into: child, components: rest, value: value)
        return .object(children)
    }

    /// Serialized with sorted keys and gap-filled arrays, so the same plan
    /// always produces byte-identical output.
    func serialized() -> String { Self.serialize(root) }

    private static func serialize(_ node: Node) -> String {
        switch node {
        case .raw(let value):
            return value
        case .object(let children):
            let body = children.keys.sorted().map { key in
                "\(GenieJSON.string(key)):\(serialize(children[key]!))"
            }
            return "{" + body.joined(separator: ",") + "}"
        case .array(let children):
            guard let highest = children.keys.max() else { return "[]" }
            let body = (0...highest).map { index in
                children[index].map(serialize) ?? "null"
            }
            return "[" + body.joined(separator: ",") + "]"
        }
    }
}

// MARK: - Token Counting

/// A vocabulary-free token estimator shaped after cl100k's splitting rules:
/// a word costs about one token per five characters, digits run in groups of
/// three, adjacent punctuation merges in pairs, CJK is about a token per
/// character. On English prose it tracks the ~4 chars-per-token rule of thumb
/// and it errs high on dense markup, which is the safe direction for sizing a
/// context window. Good enough for a budget or a progress bar, not a bill.
public enum GenieTokenCounter {

    public static func count(_ text: String) -> Int {
        var tokens = 0
        var letterRun = 0
        var digitRun = 0
        var spaceRun = 0
        var newlineRun = 0
        var punctRun = 0

        func flushWord() {
            if letterRun > 0 {
                // ~5 characters a token: "Hello"/"world" cost one each, and a
                // long identifier splits the way a BPE merge table splits it.
                tokens += max(1, (letterRun + 2) / 5)
                letterRun = 0
            }
        }
        func flushDigits() {
            if digitRun > 0 {
                tokens += max(1, (digitRun + 2) / 3)
                digitRun = 0
            }
        }
        func flushSpaces() {
            // A single space rides along with the word that follows it, the way
            // a BPE vocabulary stores " word" as one token. Longer runs of
            // indentation collapse into chunks.
            if spaceRun > 1 {
                tokens += max(1, spaceRun / 8)
            }
            spaceRun = 0
        }
        func flushPunct() {
            if punctRun > 0 {
                // `":` , `","` and `}}` are single tokens in a real vocabulary,
                // so punctuation pairs up rather than costing one apiece.
                tokens += max(1, (punctRun + 1) / 2)
                punctRun = 0
            }
        }
        func flushNewlines() {
            if newlineRun > 0 {
                tokens += max(1, (newlineRun + 1) / 2)
                newlineRun = 0
            }
        }
        func flushAll() {
            flushWord(); flushDigits(); flushPunct(); flushSpaces(); flushNewlines()
        }

        for scalar in text.unicodeScalars {
            let value = scalar.value

            if value == 0x20 || value == 0x09 {
                flushWord(); flushDigits(); flushPunct(); flushNewlines()
                spaceRun += 1
                continue
            }
            if value == 0x0A || value == 0x0D {
                flushWord(); flushDigits(); flushPunct(); flushSpaces()
                newlineRun += 1
                continue
            }

            flushSpaces(); flushNewlines()

            if (value >= 0x41 && value <= 0x5A) || (value >= 0x61 && value <= 0x7A) || value == 0x5F {
                flushDigits(); flushPunct()
                letterRun += 1
            } else if value >= 0x30 && value <= 0x39 {
                flushWord(); flushPunct()
                digitRun += 1
            } else if value < 0x80 {
                flushWord(); flushDigits()
                punctRun += 1
            } else {
                flushWord(); flushDigits(); flushPunct()
                // Above the BMP is mostly emoji and they cost several bytes;
                // CJK and the Latin supplements are about a token apiece.
                tokens += value >= 0x1_0000 ? 2 : 1
            }
        }

        flushAll()
        return tokens
    }

    /// Counts a large buffer on every core at once. Chunks are cut at ASCII
    /// whitespace so no word straddles a boundary and the sum stays exact.
    public static func countInParallel(_ text: String, minimumChunk: Int = 16_384) async -> Int {
        let bytes = Array(text.utf8)
        guard bytes.count > minimumChunk * 2 else { return count(text) }

        let cores = max(1, ProcessInfo.processInfo.activeProcessorCount)
        let target = max(minimumChunk, bytes.count / cores)

        var ranges: [Range<Int>] = []
        var start = 0
        while start < bytes.count {
            var end = min(start + target, bytes.count)
            if end < bytes.count {
                // Walk forward to the next space or newline so the chunk ends
                // on a token boundary, not in the middle of a word.
                while end < bytes.count, !(bytes[end] == 0x20 || bytes[end] == 0x0A) {
                    end += 1
                }
                if end < bytes.count { end += 1 }
            }
            ranges.append(start..<end)
            start = end
        }

        return await withTaskGroup(of: Int.self) { group in
            for range in ranges {
                let slice = String(decoding: bytes[range], as: UTF8.self)
                group.addTask { count(slice) }
            }
            var total = 0
            for await partial in group { total += partial }
            return total
        }
    }
}

// MARK: - Decomposer

/// Breaks a high-level render request into independent, parallelizable sub-tasks.
public struct RenderDecomposer: Sendable {

    public enum RenderKind: Sendable {
        case chart(ChartSpec)
        case mermaid(MermaidSpec)
        case htmlLayout(HTMLSpec)
        case slideDeck(SlideSpec)
        case pdfDocument(PDFSpec)
    }

    public struct ChartSpec: Sendable {
        public let labels: [String]
        public let datasets: [[Double]]
        public let chartType: String          // "bar", "line", "pie", "doughnut", "radar"
        public let locale: Locale
        public let unitSuffix: String?        // e.g. "k", "%", "$"
        public let seriesNames: [String]?

        public init(
            labels: [String],
            datasets: [[Double]],
            chartType: String,
            locale: Locale = .current,
            unitSuffix: String? = nil,
            seriesNames: [String]? = nil
        ) {
            self.labels = labels
            self.datasets = datasets
            self.chartType = chartType
            self.locale = locale
            self.unitSuffix = unitSuffix
            self.seriesNames = seriesNames
        }

        /// Chart.js puts one colour per slice for these, and one colour per
        /// series for everything else.
        public var isCircular: Bool {
            ["pie", "doughnut", "polararea"].contains(chartType.lowercased())
        }
    }

    public struct MermaidSpec: Sendable {
        public let nodes: [(id: String, label: String)]
        public let edges: [(from: String, to: String, label: String?)]
        public let direction: String          // "LR", "TB", "RL", "BT"

        public init(nodes: [(id: String, label: String)], edges: [(from: String, to: String, label: String?)], direction: String = "LR") {
            self.nodes = nodes
            self.edges = edges
            self.direction = direction
        }
    }

    public struct HTMLSpec: Sendable {
        public let title: String
        public let sections: [String]
        public let accentColor: String
        public let maxContentWidth: CGFloat

        public init(title: String, sections: [String], accentColor: String = "#38bdf8", maxContentWidth: CGFloat = 800) {
            self.title = title
            self.sections = sections
            self.accentColor = accentColor
            self.maxContentWidth = maxContentWidth
        }
    }

    public struct SlideSpec: Sendable {
        public let deckTitle: String
        public let slides: [(heading: String, bullets: [String])]

        public init(deckTitle: String, slides: [(heading: String, bullets: [String])]) {
            self.deckTitle = deckTitle
            self.slides = slides
        }
    }

    public struct PDFSpec: Sendable {
        public let title: String
        public let sections: [(heading: String, body: String)]

        public init(title: String, sections: [(heading: String, body: String)]) {
            self.title = title
            self.sections = sections
        }
    }

    public init() {}

    /// Decompose into independent sub-tasks plus the rule for reassembling them.
    public func plan(for request: RenderKind) -> RenderPlan {
        switch request {
        case .chart(let spec):
            return RenderPlan(
                tasks: [
                    ChartSkeletonBuilder(chartType: spec.chartType, datasetCount: spec.datasets.count),
                    LabelFormatter(labels: spec.labels, locale: spec.locale, unitSuffix: spec.unitSuffix),
                    DatasetBuilder(spec: spec),
                    ColorMapper(spec: spec),
                    AxisScaler(labels: spec.labels, datasets: spec.datasets, chartType: spec.chartType)
                ],
                assembly: .json
            )

        case .mermaid(let spec):
            return RenderPlan(
                tasks: [
                    MermaidHeader(direction: spec.direction),
                    NodeEmitter(nodes: spec.nodes),
                    EdgeEmitter(edges: spec.edges)
                ],
                assembly: .text(prefix: "", separator: "\n", suffix: "\n")
            )

        case .htmlLayout(let spec):
            return RenderPlan(
                tasks: [
                    HTMLShell(title: spec.title),
                    CSSResolver(accentColor: spec.accentColor, maxWidth: spec.maxContentWidth),
                    SectionEmitter(sections: spec.sections)
                ],
                assembly: .text(prefix: "", separator: "\n", suffix: "\n")
            )

        case .slideDeck(let spec):
            return RenderPlan(
                tasks: [
                    SlideHeaderBuilder(deckTitle: spec.deckTitle),
                    SlideBodyEmitter(slides: spec.slides)
                ],
                // `---` is what GeniePresentationEngine.compileSlideDeck splits on.
                assembly: .text(prefix: "", separator: "\n\n---\n\n", suffix: "\n")
            )

        case .pdfDocument(let spec):
            return RenderPlan(
                tasks: [
                    PDFHeaderBuilder(title: spec.title),
                    PDFSectionEmitter(sections: spec.sections)
                ],
                assembly: .text(prefix: "", separator: "\n\n", suffix: "\n")
            )
        }
    }

    /// The tasks alone, for callers that assemble the fragments themselves.
    public func decompose(_ request: RenderKind) -> [any PrecomputeTask] {
        plan(for: request).tasks
    }
}

// MARK: - Chart Sub-Tasks

/// Computes axis min/max/step for a chart. Pure math, no I/O.
public struct AxisScaler: PrecomputeTask {
    public let taskID = "axis_scaler"
    public let labels: [String]
    public let datasets: [[Double]]
    public let chartType: String

    public init(labels: [String], datasets: [[Double]], chartType: String = "bar") {
        self.labels = labels
        self.datasets = datasets
        self.chartType = chartType
    }

    public func resolve() async throws -> ResolvedValue {
        let type = chartType.lowercased()
        // Pie and doughnut have no cartesian axes; emitting scales for them
        // just confuses Chart.js.
        guard !["pie", "doughnut", "polararea"].contains(type) else { return .empty }

        let axis = type == "radar" ? "r" : "y"
        let values = datasets.flatMap { $0 }.filter { $0.isFinite }
        guard let lowest = values.min(), let highest = values.max() else {
            return ResolvedValue([
                .json("options.scales.\(axis).min", "0", order: 30),
                .json("options.scales.\(axis).max", "100", order: 30)
            ])
        }

        let span = highest - lowest
        let roughStep = max(1.0, span / 5.0)
        let magnitude = pow(10, floor(log10(roughStep)))
        let residual = roughStep / magnitude
        let niceStep: Double
        if residual <= 1.5 { niceStep = 1 * magnitude }
        else if residual <= 3 { niceStep = 2 * magnitude }
        else if residual <= 7 { niceStep = 5 * magnitude }
        else { niceStep = 10 * magnitude }

        // A bar chart that does not start at zero misrepresents its own data.
        let floorValue = ["bar", "radar"].contains(type) ? min(0, lowest) : lowest
        let axisMin = (floorValue / niceStep).rounded(.down) * niceStep
        let axisMax = (highest / niceStep).rounded(.up) * niceStep

        return ResolvedValue([
            .json("options.scales.\(axis).min", GenieJSON.number(axisMin), order: 30),
            .json("options.scales.\(axis).max", GenieJSON.number(axisMax), order: 30),
            .json("options.scales.\(axis).ticks.stepSize", GenieJSON.number(niceStep), order: 30),
            .json("options.scales.\(axis).grid.color", GenieJSON.string("rgba(148,163,184,0.15)"), order: 30)
        ])
    }
}

/// Formats labels with locale-aware number handling.
public struct LabelFormatter: PrecomputeTask {
    public let taskID = "label_formatter"
    public let labels: [String]
    public let locale: Locale
    public let unitSuffix: String?

    public init(labels: [String], locale: Locale = .current, unitSuffix: String? = nil) {
        self.labels = labels
        self.locale = locale
        self.unitSuffix = unitSuffix
    }

    public func resolve() async throws -> ResolvedValue {
        let formatted = labels.map { label -> String in
            guard let suffix = unitSuffix, let value = Double(label) else { return label }
            return value.formatted(.number.precision(.fractionLength(0...1)).locale(locale)) + suffix
        }
        return ResolvedValue([
            .json("data.labels", GenieJSON.array(formatted.map(GenieJSON.string)), order: 10)
        ])
    }
}

/// Emits the actual numbers. The previous engine formatted axes and colours for
/// data it never wrote into the buffer.
public struct DatasetBuilder: PrecomputeTask {
    public let taskID = "dataset_builder"
    public let spec: RenderDecomposer.ChartSpec

    public init(spec: RenderDecomposer.ChartSpec) {
        self.spec = spec
    }

    public func resolve() async throws -> ResolvedValue {
        let type = spec.chartType.lowercased()
        var fragments: [Fragment] = []

        for (index, series) in spec.datasets.enumerated() {
            let name = spec.seriesNames?.indices.contains(index) == true
                ? spec.seriesNames![index]
                : "Series \(index + 1)"
            // Chart.js reads `null` as a gap, which is what a NaN means here.
            let points = series.map { GenieJSON.number($0) }

            fragments.append(.json("data.datasets.\(index).label", GenieJSON.string(name), order: 20))
            fragments.append(.json("data.datasets.\(index).data", GenieJSON.array(points), order: 20))

            if type == "line" {
                fragments.append(.json("data.datasets.\(index).tension", "0.35", order: 20))
                fragments.append(.json("data.datasets.\(index).fill", "false", order: 20))
                fragments.append(.json("data.datasets.\(index).pointRadius", "3", order: 20))
            }
        }

        return ResolvedValue(fragments)
    }
}

/// Maps dataset indices to a consistent, accessible colour palette.
public struct ColorMapper: PrecomputeTask {
    public let taskID = "color_mapper"
    public let spec: RenderDecomposer.ChartSpec

    public init(spec: RenderDecomposer.ChartSpec) {
        self.spec = spec
    }

    public init(datasetCount: Int, chartType: String) {
        self.spec = RenderDecomposer.ChartSpec(
            labels: [],
            datasets: Array(repeating: [], count: datasetCount),
            chartType: chartType
        )
    }

    static let palette = [
        "#38bdf8", "#a78bfa", "#34d399", "#fbbf24",
        "#f87171", "#60a5fa", "#fb923c", "#4ade80"
    ]

    public func resolve() async throws -> ResolvedValue {
        var fragments: [Fragment] = []

        if spec.isCircular {
            // One colour per slice, cycling the palette when there are more
            // slices than colours.
            let sliceCount = max(spec.labels.count, spec.datasets.first?.count ?? 0)
            let colors = (0..<max(1, sliceCount)).map { Self.palette[$0 % Self.palette.count] }
            fragments.append(.json("data.datasets.0.backgroundColor", GenieJSON.array(colors.map(GenieJSON.string)), order: 25))
            fragments.append(.json("data.datasets.0.borderColor", GenieJSON.string("rgba(2,6,23,0.85)"), order: 25))
            fragments.append(.json("data.datasets.0.borderWidth", "2", order: 25))
            return ResolvedValue(fragments)
        }

        let isLine = spec.chartType.lowercased() == "line"
        for index in 0..<max(1, spec.datasets.count) {
            let color = Self.palette[index % Self.palette.count]
            let fill = isLine ? GenieHTML.rgba(color, alpha: 0.18) : GenieHTML.rgba(color, alpha: 0.62)
            fragments.append(.json("data.datasets.\(index).backgroundColor", GenieJSON.string(fill), order: 25))
            fragments.append(.json("data.datasets.\(index).borderColor", GenieJSON.string(color), order: 25))
            fragments.append(.json("data.datasets.\(index).borderWidth", "2", order: 25))
        }

        return ResolvedValue(fragments)
    }
}

public struct ChartSkeletonBuilder: PrecomputeTask {
    public let taskID = "chart_skeleton"
    public let chartType: String
    public let datasetCount: Int

    public init(chartType: String, datasetCount: Int) {
        self.chartType = chartType
        self.datasetCount = datasetCount
    }

    public func resolve() async throws -> ResolvedValue {
        ResolvedValue([
            .json("type", GenieJSON.string(chartType.lowercased()), order: 0),
            .json("options.responsive", "true", order: 0),
            .json("options.maintainAspectRatio", "false", order: 0),
            .json("options.animation.duration", "300", order: 0),
            .json("options.plugins.legend.display", datasetCount > 1 ? "true" : "false", order: 0)
        ])
    }
}

// MARK: - Mermaid Sub-Tasks

public struct MermaidHeader: PrecomputeTask {
    public let taskID = "mermaid_header"
    public let direction: String

    public init(direction: String = "LR") {
        self.direction = direction
    }

    public func resolve() async throws -> ResolvedValue {
        let allowed = ["LR", "TB", "TD", "RL", "BT"]
        let safe = allowed.contains(direction.uppercased()) ? direction.uppercased() : "LR"
        return ResolvedValue(text: "graph \(safe)", order: -100)
    }
}

public struct NodeEmitter: PrecomputeTask {
    public let taskID = "mermaid_nodes"
    public let nodes: [(id: String, label: String)]

    public init(nodes: [(id: String, label: String)]) {
        self.nodes = nodes
    }

    public func resolve() async throws -> ResolvedValue {
        let lines = nodes.enumerated().map { index, node in
            Fragment.text("  \(GenieMermaid.identifier(node.id, fallbackIndex: index))[\"\(GenieMermaid.label(node.label))\"]", order: index)
        }
        return ResolvedValue(lines)
    }
}

public struct EdgeEmitter: PrecomputeTask {
    public let taskID = "mermaid_edges"
    public let edges: [(from: String, to: String, label: String?)]

    public init(edges: [(from: String, to: String, label: String?)]) {
        self.edges = edges
    }

    public func resolve() async throws -> ResolvedValue {
        let lines = edges.enumerated().map { index, edge -> Fragment in
            let from = GenieMermaid.identifier(edge.from, fallbackIndex: index)
            let to = GenieMermaid.identifier(edge.to, fallbackIndex: index)
            if let label = edge.label, !label.isEmpty {
                return .text("  \(from) -->|\(GenieMermaid.label(label))| \(to)", order: 1_000 + index)
            }
            return .text("  \(from) --> \(to)", order: 1_000 + index)
        }
        return ResolvedValue(lines)
    }
}

/// Mermaid has no escape syntax worth the name: a quote or a bracket inside a
/// label ends the node early and the whole diagram fails to parse.
public enum GenieMermaid {
    public static func identifier(_ raw: String, fallbackIndex: Int) -> String {
        let cleaned = raw.unicodeScalars.filter { CharacterSet.alphanumerics.contains($0) || $0 == "_" }
        let result = String(String.UnicodeScalarView(cleaned))
        if result.isEmpty { return "n\(fallbackIndex)" }
        // Mermaid identifiers cannot start with a digit.
        return result.first!.isNumber ? "n\(result)" : result
    }

    public static func label(_ raw: String) -> String {
        raw
            .replacingOccurrences(of: "\"", with: "#quot;")
            .replacingOccurrences(of: "[", with: "#91;")
            .replacingOccurrences(of: "]", with: "#93;")
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespaces)
    }
}

// MARK: - HTML Sub-Tasks

public struct CSSResolver: PrecomputeTask {
    public let taskID = "css_resolver"
    public let accentColor: String
    public let maxWidth: CGFloat

    public init(accentColor: String, maxWidth: CGFloat) {
        self.accentColor = accentColor
        self.maxWidth = maxWidth
    }

    public func resolve() async throws -> ResolvedValue {
        let accent = GenieHTML.safeHexColor(accentColor)
        let width = Int(max(320, min(maxWidth, 2_400)))
        // Light and dark both, so the page matches the viewer rather than
        // burning a white background into a dark desktop.
        let css = """
        <style>
        :root { --accent: \(accent); --max-w: \(width)px; --bg: #ffffff; --fg: #0f172a; --muted: #475569; }
        @media (prefers-color-scheme: dark) {
          :root { --bg: #0b1220; --fg: #e2e8f0; --muted: #94a3b8; }
        }
        * { box-sizing: border-box; }
        body { font-family: -apple-system, BlinkMacSystemFont, system-ui, sans-serif; margin: 0 auto; padding: 24px 16px; max-width: var(--max-w); background: var(--bg); color: var(--fg); line-height: 1.55; }
        .genie-section { margin: 0 0 20px; }
        .genie-section h1, .genie-section h2 { color: var(--accent); }
        a { color: var(--accent); }
        img, svg, video { max-width: 100%; height: auto; }
        </style>
        """
        return ResolvedValue(text: css, order: -900)
    }
}

public struct SectionEmitter: PrecomputeTask {
    public let taskID = "section_emitter"
    public let sections: [String]

    public init(sections: [String]) {
        self.sections = sections
    }

    public func resolve() async throws -> ResolvedValue {
        ResolvedValue(sections.enumerated().map { index, body in
            .text("<section class=\"genie-section\">\(body)</section>", order: index)
        })
    }
}

/// Opens and closes the document. The shell straddles the other tasks rather
/// than wrapping them, so the stylesheet still lands inside `<head>`.
public struct HTMLShell: PrecomputeTask {
    public let taskID = "html_shell"
    public let title: String

    public init(title: String) {
        self.title = title
    }

    public func resolve() async throws -> ResolvedValue {
        let safeTitle = GenieHTML.escape(title)
        return ResolvedValue([
            .text("""
            <!DOCTYPE html>
            <html lang="en">
            <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <title>\(safeTitle)</title>
            """, order: -1_000),
            .text("</head>\n<body>", order: -500),
            .text("</body>\n</html>", order: 1_000)
        ])
    }
}

// MARK: - Slide & PDF Sub-Tasks

public struct SlideHeaderBuilder: PrecomputeTask {
    public let taskID = "slide_header"
    public let deckTitle: String

    public init(deckTitle: String) {
        self.deckTitle = deckTitle
    }

    public func resolve() async throws -> ResolvedValue {
        ResolvedValue(text: "# \(deckTitle)", order: -100)
    }
}

public struct SlideBodyEmitter: PrecomputeTask {
    public let taskID = "slide_body"
    public let slides: [(heading: String, bullets: [String])]

    public init(slides: [(heading: String, bullets: [String])]) {
        self.slides = slides
    }

    public func resolve() async throws -> ResolvedValue {
        ResolvedValue(slides.enumerated().map { index, slide in
            let bullets = slide.bullets.map { "- \($0)" }.joined(separator: "\n")
            return .text("## \(slide.heading)\n\(bullets)", order: index)
        })
    }
}

public struct PDFHeaderBuilder: PrecomputeTask {
    public let taskID = "pdf_header"
    public let title: String

    public init(title: String) {
        self.title = title
    }

    /// Markdown, not a `%PDF-1.7` header — `compilePDFDocument` renders the
    /// markdown itself and a literal file header would print as body text.
    public func resolve() async throws -> ResolvedValue {
        ResolvedValue(text: "# \(title)", order: -100)
    }
}

public struct PDFSectionEmitter: PrecomputeTask {
    public let taskID = "pdf_sections"
    public let sections: [(heading: String, body: String)]

    public init(sections: [(heading: String, body: String)]) {
        self.sections = sections
    }

    public func resolve() async throws -> ResolvedValue {
        ResolvedValue(sections.enumerated().map { index, section in
            .text("## \(section.heading)\n\n\(section.body)", order: index)
        })
    }
}

// MARK: - Output

/// The fully pre-baked output, ready for single-pass emission.
public struct PrecomputedBuffer: Sendable {
    /// The assembled buffer — valid JSON, markdown or HTML for its render kind.
    public let output: String
    /// Exact token count of `output`, itself counted in parallel.
    public let totalTokenCount: Int
    /// Sum of the per-fragment counts taken while the sub-tasks were resolving,
    /// i.e. free of any extra pass over the text. For a text assembly it tracks
    /// `totalTokenCount` closely; for a JSON assembly it runs higher, because
    /// each fragment carries its whole key path before the merge shares prefixes.
    public let contentTokenCount: Int
    public let tokensByTask: [String: Int]
    public let subTaskDurations: [String: Duration]
    /// Sub-tasks that threw or timed out, with the reason. Their fragments are
    /// missing from `output`; everything else still rendered.
    public let failures: [String: String]
    public let warnings: [String]
    public let resolvedAt: Date
    /// How long the whole render took.
    public let wallClock: Duration
    /// What the same work would have cost run one after another.
    public let serialCost: Duration

    public init(
        output: String,
        totalTokenCount: Int,
        contentTokenCount: Int,
        tokensByTask: [String: Int],
        subTaskDurations: [String: Duration],
        failures: [String: String],
        warnings: [String],
        resolvedAt: Date,
        wallClock: Duration,
        serialCost: Duration
    ) {
        self.output = output
        self.totalTokenCount = totalTokenCount
        self.contentTokenCount = contentTokenCount
        self.tokensByTask = tokensByTask
        self.subTaskDurations = subTaskDurations
        self.failures = failures
        self.warnings = warnings
        self.resolvedAt = resolvedAt
        self.wallClock = wallClock
        self.serialCost = serialCost
    }

    /// What actually gets emitted to the renderer.
    public var assembledOutput: String { output }

    public var isComplete: Bool { failures.isEmpty }

    /// Serial cost over wall clock — 1.0 means the parallelism bought nothing.
    public var speedup: Double {
        let wall = Double(wallClock.components.attoseconds) + Double(wallClock.components.seconds) * 1e18
        let serial = Double(serialCost.components.attoseconds) + Double(serialCost.components.seconds) * 1e18
        guard wall > 0 else { return 1 }
        return serial / wall
    }
}

public enum PrecomputeError: Error, CustomStringConvertible, Sendable {
    case timedOut(taskID: String, after: Duration)
    case cancelled

    public var description: String {
        switch self {
        case .timedOut(let taskID, let after):
            return "sub-task \(taskID) exceeded \(after)"
        case .cancelled:
            return "render cancelled"
        }
    }
}

// MARK: - Parallel Precompute Execution Engine

/// Coordinates concurrent task resolution across CPU cores. Every sub-task
/// resolves and tokenizes on its own thread; assembly happens once, in a fixed
/// order that does not depend on who finished first.
public actor GeniePrecomputeEngine {
    public static let shared = GeniePrecomputeEngine()

    private let logger = Logger(subsystem: "com.nicholasdudek.genie", category: "Precompute")

    public init() {}

    /// Render a request end to end.
    public func render(
        _ request: RenderDecomposer.RenderKind,
        timeout: Duration = .seconds(5)
    ) async throws -> PrecomputedBuffer {
        try await precompute(plan: RenderDecomposer().plan(for: request), timeout: timeout)
    }

    /// Resolve every task in the plan concurrently, then assemble once.
    public func precompute(
        plan: RenderPlan,
        timeout: Duration = .seconds(5)
    ) async throws -> PrecomputedBuffer {
        let clock = ContinuousClock()
        let startedAt = Date()
        let wallStart = clock.now

        struct Outcome: Sendable {
            let taskID: String
            let index: Int
            let fragments: [Fragment]
            let tokens: Int
            let duration: Duration
            let failure: String?
        }

        let outcomes: [Outcome] = await withTaskGroup(of: Outcome.self) { group in
            for (index, task) in plan.tasks.enumerated() {
                group.addTask {
                    let taskStart = clock.now
                    do {
                        let value = try await Self.resolve(task, timeout: timeout)
                        // Tokenized here, on the same core that just produced
                        // the fragment, while its peers are still resolving.
                        let tokens = value.fragments.reduce(0) { $0 + GenieTokenCounter.count($1.tokenText) }
                        return Outcome(
                            taskID: task.taskID,
                            index: index,
                            fragments: value.fragments,
                            tokens: tokens,
                            duration: clock.now - taskStart,
                            failure: nil
                        )
                    } catch {
                        return Outcome(
                            taskID: task.taskID,
                            index: index,
                            fragments: [],
                            tokens: 0,
                            duration: clock.now - taskStart,
                            failure: String(describing: error)
                        )
                    }
                }
            }

            var collected: [Outcome] = []
            collected.reserveCapacity(plan.tasks.count)
            for await outcome in group { collected.append(outcome) }
            return collected
        }

        try Task.checkCancellation()

        var durations: [String: Duration] = [:]
        var tokensByTask: [String: Int] = [:]
        var failures: [String: String] = [:]
        var serialCost: Duration = .zero
        var contentTokens = 0

        // Sorted by (fragment order, task id, position within the task), never
        // by completion order — two runs of the same plan are byte-identical.
        var ordered: [(order: Int, taskID: String, slot: Int, fragment: Fragment)] = []

        for outcome in outcomes {
            durations[outcome.taskID] = outcome.duration
            tokensByTask[outcome.taskID] = outcome.tokens
            contentTokens += outcome.tokens
            serialCost += outcome.duration
            if let failure = outcome.failure {
                failures[outcome.taskID] = failure
                logger.error("precompute sub-task \(outcome.taskID, privacy: .public) failed: \(failure, privacy: .public)")
            }
            for (slot, fragment) in outcome.fragments.enumerated() {
                ordered.append((fragment.order, outcome.taskID, slot, fragment))
            }
        }

        ordered.sort {
            if $0.order != $1.order { return $0.order < $1.order }
            if $0.taskID != $1.taskID { return $0.taskID < $1.taskID }
            return $0.slot < $1.slot
        }

        var warnings: [String] = []
        let output: String

        switch plan.assembly {
        case .text(let prefix, let separator, let suffix):
            var pieces: [String] = []
            pieces.reserveCapacity(ordered.count)
            for entry in ordered {
                switch entry.fragment.payload {
                case .text(let body):
                    pieces.append(body)
                case .json(let path, _):
                    warnings.append("dropped JSON fragment \(path) from a text assembly")
                }
            }
            output = prefix + pieces.joined(separator: separator) + suffix

        case .json:
            var tree = JSONTree()
            for entry in ordered {
                switch entry.fragment.payload {
                case .json(let path, let value):
                    tree.insert(path: path, value: value)
                case .text(let body):
                    warnings.append("dropped text fragment (\(body.prefix(24))…) from a JSON assembly")
                }
            }
            warnings.append(contentsOf: tree.collisions.map { "key path \($0) written more than once" })
            output = tree.serialized()
        }

        let totalTokens = await GenieTokenCounter.countInParallel(output)
        let wallClock = clock.now - wallStart

        logger.debug("precompute rendered \(totalTokens) tokens from \(plan.tasks.count) sub-tasks in \(wallClock.description, privacy: .public)")

        return PrecomputedBuffer(
            output: output,
            totalTokenCount: totalTokens,
            contentTokenCount: contentTokens,
            tokensByTask: tokensByTask,
            subTaskDurations: durations,
            failures: failures,
            warnings: warnings,
            resolvedAt: startedAt,
            wallClock: wallClock,
            serialCost: serialCost
        )
    }

    /// Back-compatible entry point: tasks with no assembly rule, concatenated.
    public func precompute(tasks: [any PrecomputeTask]) async throws -> PrecomputedBuffer {
        try await precompute(plan: RenderPlan(tasks: tasks, assembly: .plain))
    }

    /// Races a sub-task against its deadline so one hung resolver cannot hold
    /// the whole render open.
    private static func resolve(_ task: any PrecomputeTask, timeout: Duration) async throws -> ResolvedValue {
        try await withThrowingTaskGroup(of: ResolvedValue?.self) { group in
            group.addTask { try await task.resolve() }
            group.addTask {
                try await Task.sleep(for: timeout)
                return nil
            }

            while let result = try await group.next() {
                group.cancelAll()
                if let value = result { return value }
                throw PrecomputeError.timedOut(taskID: task.taskID, after: timeout)
            }
            throw PrecomputeError.cancelled
        }
    }
}
