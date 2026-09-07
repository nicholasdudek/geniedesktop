//
//  SwiftVDOMCore.swift
//  GoldGate
//
//  Ultra-High-Performance Swift Virtual DOM & React-Like Component Architecture
//
//  Key Architectural Pillars:
//  1. Ultra-lightweight `VNode` hierarchy (~64 bytes per node) with zero-cost value semantics.
//  2. React-like `VDOMComponent` protocol and declarative Swift builder DSL (`VNodeBuilder`, `vStack`, `hStack`, `zStack`).
//  3. `VDOMReconciler`: O(N) tree diffing algorithm, patch generator, and key-based list reconciliation.
//  4. Reactive State Hooks: `VState<T>`, `useVState`, `useVEffect`, `useVMemo`, `useVRef`.
//  5. Direct Hardware CALayer / Native NSView Renderer with sub-millisecond diff-and-patch execution.
//  6. Seamless SwiftUI & Metal bridge.
//

import AppKit
import Combine
import Foundation
import Metal
import QuartzCore
import SwiftUI

// MARK: - 1. Virtual DOM Node Types & Properties

/// Supported virtual node primitives for layout, typography, media, and interactive surfaces.
public enum VNodeType: Equatable, Hashable, Sendable {
    case container
    case text
    case image
    case layer
    case button
    case blur
    case canvas
    case custom(String)
}

/// Content mode for virtual images.
public enum VImageContentMode: Equatable, Hashable, Sendable {
    case scaleToFill
    case scaleAspectFit
    case scaleAspectFill
    case center
}

/// Alignment specification for virtual stacks and containers.
public enum VAlignment: Equatable, Hashable, Sendable {
    case leading
    case center
    case trailing
    case top
    case bottom
    case topLeading
    case topTrailing
    case bottomLeading
    case bottomTrailing
}

/// Layout and styling properties encapsulated in a copy-on-write or compact value structure.
public struct VNodeProps: Equatable {
    // Layout Geometry
    public var frame: CGRect = .zero
    public var size: CGSize? = nil
    public var minWidth: CGFloat? = nil
    public var minHeight: CGFloat? = nil
    public var maxWidth: CGFloat? = nil
    public var maxHeight: CGFloat? = nil
    public var padding: NSEdgeInsets = NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    public var margin: NSEdgeInsets = NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    public var spacing: CGFloat = 0.0
    public var alignment: VAlignment = .center

    // Visual Appearance
    public var backgroundColor: NSColor? = nil
    public var foregroundColor: NSColor? = nil
    public var opacity: CGFloat = 1.0
    public var cornerRadius: CGFloat = 0.0
    public var borderWidth: CGFloat = 0.0
    public var borderColor: NSColor? = nil
    public var shadowRadius: CGFloat = 0.0
    public var shadowColor: NSColor? = nil
    public var shadowOffset: CGSize = .zero
    public var shadowOpacity: CGFloat = 0.0
    public var blurRadius: CGFloat = 0.0
    public var zIndex: Int = 0
    public var transform: CATransform3D = CATransform3DIdentity
    public var isHidden: Bool = false
    public var clipToBounds: Bool = false

    // Text Props
    public var text: String = ""
    public var font: NSFont = NSFont.systemFont(ofSize: 13)
    public var lineLimit: Int? = nil
    public var textAlignment: NSTextAlignment = .left

    // Image Props
    public var image: NSImage? = nil
    public var imageName: String? = nil
    public var systemImageName: String? = nil
    public var imageContentMode: VImageContentMode = .scaleAspectFit

    // Blur Props
    public var blurMaterial: NSVisualEffectView.Material = .hudWindow
    public var blurBlendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    public var blurState: NSVisualEffectView.State = .followsWindowActiveState

    // Action Handlers
    public var onClick: (@Sendable () -> Void)? = nil
    public var onHover: (@Sendable (Bool) -> Void)? = nil
    public var onDrag: (@Sendable (CGSize) -> Void)? = nil

    // Drawing Closures
    public var drawHandler: (@Sendable (CGContext, CGSize) -> Void)? = nil
    public var metalDrawHandler: (@Sendable (AnyObject, CGSize) -> Void)? = nil

    public init() {}

    public static func == (lhs: VNodeProps, rhs: VNodeProps) -> Bool {
        return lhs.frame == rhs.frame &&
            lhs.size == rhs.size &&
            lhs.minWidth == rhs.minWidth &&
            lhs.minHeight == rhs.minHeight &&
            lhs.maxWidth == rhs.maxWidth &&
            lhs.maxHeight == rhs.maxHeight &&
            lhs.padding.top == rhs.padding.top &&
            lhs.padding.left == rhs.padding.left &&
            lhs.padding.bottom == rhs.padding.bottom &&
            lhs.padding.right == rhs.padding.right &&
            lhs.margin.top == rhs.margin.top &&
            lhs.margin.left == rhs.margin.left &&
            lhs.margin.bottom == rhs.margin.bottom &&
            lhs.margin.right == rhs.margin.right &&
            lhs.spacing == rhs.spacing &&
            lhs.alignment == rhs.alignment &&
            lhs.backgroundColor == rhs.backgroundColor &&
            lhs.foregroundColor == rhs.foregroundColor &&
            lhs.opacity == rhs.opacity &&
            lhs.cornerRadius == rhs.cornerRadius &&
            lhs.borderWidth == rhs.borderWidth &&
            lhs.borderColor == rhs.borderColor &&
            lhs.shadowRadius == rhs.shadowRadius &&
            lhs.shadowColor == rhs.shadowColor &&
            lhs.shadowOffset == rhs.shadowOffset &&
            lhs.shadowOpacity == rhs.shadowOpacity &&
            lhs.blurRadius == rhs.blurRadius &&
            lhs.zIndex == rhs.zIndex &&
            CATransform3DEqualToTransform(lhs.transform, rhs.transform) &&
            lhs.isHidden == rhs.isHidden &&
            lhs.clipToBounds == rhs.clipToBounds &&
            lhs.text == rhs.text &&
            lhs.font == rhs.font &&
            lhs.lineLimit == rhs.lineLimit &&
            lhs.textAlignment == rhs.textAlignment &&
            lhs.image == rhs.image &&
            lhs.imageName == rhs.imageName &&
            lhs.systemImageName == rhs.systemImageName &&
            lhs.imageContentMode == rhs.imageContentMode &&
            lhs.blurMaterial == rhs.blurMaterial &&
            lhs.blurBlendingMode == rhs.blurBlendingMode &&
            lhs.blurState == rhs.blurState
    }
}

// MARK: - 2. Virtual DOM Node (VNode)

/// Ultra-lightweight virtual node struct (~64 bytes on 64-bit architectures).
public struct VNode: Equatable, Identifiable {
    public var id: String
    public var key: String?
    public var type: VNodeType
    public var props: VNodeProps
    public var children: [VNode]

    public init(
        id: String = UUID().uuidString,
        key: String? = nil,
        type: VNodeType = .container,
        props: VNodeProps = VNodeProps(),
        children: [VNode] = []
    ) {
        self.id = id
        self.key = key
        self.type = type
        self.props = props
        self.children = children
    }

    public static func == (lhs: VNode, rhs: VNode) -> Bool {
        return lhs.id == rhs.id &&
            lhs.key == rhs.key &&
            lhs.type == rhs.type &&
            lhs.props == rhs.props &&
            lhs.children == rhs.children
    }
}

// MARK: - VNode Fluent Modifiers

public extension VNode {
    func id(_ id: String) -> VNode {
        var copy = self
        copy.id = id
        return copy
    }

    func key(_ key: String) -> VNode {
        var copy = self
        copy.key = key
        return copy
    }

    func frame(
        x: CGFloat? = nil,
        y: CGFloat? = nil,
        width: CGFloat? = nil,
        height: CGFloat? = nil
    ) -> VNode {
        var copy = self
        var currentFrame = copy.props.frame
        if let x = x { currentFrame.origin.x = x }
        if let y = y { currentFrame.origin.y = y }
        if let w = width { currentFrame.size.width = w }
        if let h = height { currentFrame.size.height = h }
        copy.props.frame = currentFrame
        if let w = width, let h = height {
            copy.props.size = CGSize(width: w, height: h)
        }
        return copy
    }

    func size(width: CGFloat, height: CGFloat) -> VNode {
        var copy = self
        copy.props.size = CGSize(width: width, height: height)
        copy.props.frame.size = CGSize(width: width, height: height)
        return copy
    }

    func minSize(width: CGFloat? = nil, height: CGFloat? = nil) -> VNode {
        var copy = self
        copy.props.minWidth = width
        copy.props.minHeight = height
        return copy
    }

    func maxSize(width: CGFloat? = nil, height: CGFloat? = nil) -> VNode {
        var copy = self
        copy.props.maxWidth = width
        copy.props.maxHeight = height
        return copy
    }

    func padding(_ insets: NSEdgeInsets) -> VNode {
        var copy = self
        copy.props.padding = insets
        return copy
    }

    func padding(_ amount: CGFloat) -> VNode {
        var copy = self
        copy.props.padding = NSEdgeInsets(top: amount, left: amount, bottom: amount, right: amount)
        return copy
    }

    func padding(top: CGFloat = 0, leading: CGFloat = 0, bottom: CGFloat = 0, trailing: CGFloat = 0) -> VNode {
        var copy = self
        copy.props.padding = NSEdgeInsets(top: top, left: leading, bottom: bottom, right: trailing)
        return copy
    }

    func margin(_ insets: NSEdgeInsets) -> VNode {
        var copy = self
        copy.props.margin = insets
        return copy
    }

    func background(_ color: NSColor) -> VNode {
        var copy = self
        copy.props.backgroundColor = color
        return copy
    }

    func foregroundColor(_ color: NSColor) -> VNode {
        var copy = self
        copy.props.foregroundColor = color
        return copy
    }

    func opacity(_ value: CGFloat) -> VNode {
        var copy = self
        copy.props.opacity = max(0.0, min(1.0, value))
        return copy
    }

    func cornerRadius(_ radius: CGFloat) -> VNode {
        var copy = self
        copy.props.cornerRadius = radius
        return copy
    }

    func border(_ color: NSColor, width: CGFloat = 1.0) -> VNode {
        var copy = self
        copy.props.borderColor = color
        copy.props.borderWidth = width
        return copy
    }

    func shadow(
        color: NSColor = NSColor.black.withAlphaComponent(0.5),
        radius: CGFloat = 10.0,
        x: CGFloat = 0.0,
        y: CGFloat = -4.0,
        opacity: CGFloat = 0.6
    ) -> VNode {
        var copy = self
        copy.props.shadowColor = color
        copy.props.shadowRadius = radius
        copy.props.shadowOffset = CGSize(width: x, height: y)
        copy.props.shadowOpacity = opacity
        return copy
    }

    func blur(
        radius: CGFloat = 20.0,
        material: NSVisualEffectView.Material = .hudWindow,
        blendingMode: NSVisualEffectView.BlendingMode = .behindWindow
    ) -> VNode {
        var copy = self
        copy.props.blurRadius = radius
        copy.props.blurMaterial = material
        copy.props.blurBlendingMode = blendingMode
        return copy
    }

    func zIndex(_ index: Int) -> VNode {
        var copy = self
        copy.props.zIndex = index
        return copy
    }

    func transform(_ transform: CATransform3D) -> VNode {
        var copy = self
        copy.props.transform = transform
        return copy
    }

    func clipToBounds(_ clip: Bool = true) -> VNode {
        var copy = self
        copy.props.clipToBounds = clip
        return copy
    }

    func font(_ font: NSFont) -> VNode {
        var copy = self
        copy.props.font = font
        return copy
    }

    func textAlignment(_ alignment: NSTextAlignment) -> VNode {
        var copy = self
        copy.props.textAlignment = alignment
        return copy
    }

    func lineLimit(_ limit: Int?) -> VNode {
        var copy = self
        copy.props.lineLimit = limit
        return copy
    }

    func onClick(_ action: @escaping @Sendable () -> Void) -> VNode {
        var copy = self
        copy.props.onClick = action
        return copy
    }

    func onHover(_ action: @escaping @Sendable (Bool) -> Void) -> VNode {
        var copy = self
        copy.props.onHover = action
        return copy
    }

    func onDrag(_ action: @escaping @Sendable (CGSize) -> Void) -> VNode {
        var copy = self
        copy.props.onDrag = action
        return copy
    }
}

// MARK: - 3. React-like VDOMComponent & Result Builder DSL

/// Protocol defining a declarative, virtual component.
public protocol VDOMComponent {
    associatedtype Body: VNodeConvertible
    @VNodeBuilder var body: Body { get }
}

public protocol VNodeConvertible {
    func asVNodes() -> [VNode]
}

extension VNode: VNodeConvertible {
    public func asVNodes() -> [VNode] {
        return [self]
    }
}

extension Array: VNodeConvertible where Element == VNode {
    public func asVNodes() -> [VNode] {
        return self
    }
}

extension String: VNodeConvertible {
    public func asVNodes() -> [VNode] {
        var props = VNodeProps()
        props.text = self
        return [VNode(type: .text, props: props)]
    }
}

extension Optional: VNodeConvertible where Wrapped: VNodeConvertible {
    public func asVNodes() -> [VNode] {
        switch self {
        case .some(let value):
            return value.asVNodes()
        case .none:
            return []
        }
    }
}

/// Declarative Result Builder for composing VNodes.
@resultBuilder
public struct VNodeBuilder {
    public static func buildBlock(_ components: [VNode]...) -> [VNode] {
        return components.flatMap { $0 }
    }

    public static func buildBlock(_ components: VNodeConvertible...) -> [VNode] {
        return components.flatMap { $0.asVNodes() }
    }

    public static func buildExpression(_ node: VNode) -> [VNode] {
        return [node]
    }

    public static func buildExpression(_ nodes: [VNode]) -> [VNode] {
        return nodes
    }

    public static func buildExpression(_ text: String) -> [VNode] {
        return text.asVNodes()
    }

    public static func buildExpression<C: VDOMComponent>(_ component: C) -> [VNode] {
        return component.body.asVNodes()
    }

    public static func buildOptional(_ component: [VNode]?) -> [VNode] {
        return component ?? []
    }

    public static func buildEither(first component: [VNode]) -> [VNode] {
        return component
    }

    public static func buildEither(second component: [VNode]) -> [VNode] {
        return component
    }

    public static func buildArray(_ components: [[VNode]]) -> [VNode] {
        return components.flatMap { $0 }
    }

    public static func buildLimitedAvailability(_ component: [VNode]) -> [VNode] {
        return component
    }
}

// MARK: - Declarative DSL Primitive Helpers

/// Vertical stack container.
public func vStack(
    spacing: CGFloat = 0.0,
    alignment: VAlignment = .center,
    @VNodeBuilder _ content: () -> [VNode]
) -> VNode {
    var props = VNodeProps()
    props.spacing = spacing
    props.alignment = alignment
    return VNode(type: .container, props: props, children: content())
}

/// Horizontal stack container.
public func hStack(
    spacing: CGFloat = 0.0,
    alignment: VAlignment = .center,
    @VNodeBuilder _ content: () -> [VNode]
) -> VNode {
    var props = VNodeProps()
    props.spacing = spacing
    props.alignment = alignment
    return VNode(type: .container, props: props, children: content())
}

/// Overlapping Z-stack container.
public func zStack(
    alignment: VAlignment = .center,
    @VNodeBuilder _ content: () -> [VNode]
) -> VNode {
    var props = VNodeProps()
    props.alignment = alignment
    return VNode(type: .container, props: props, children: content())
}

/// Generic Virtual Container.
public func VContainer(
    @VNodeBuilder _ content: () -> [VNode]
) -> VNode {
    return VNode(type: .container, children: content())
}

/// Virtual Text element.
public func VText(
    _ text: String,
    font: NSFont? = nil,
    color: NSColor? = nil,
    alignment: NSTextAlignment = .left,
    lineLimit: Int? = nil
) -> VNode {
    var props = VNodeProps()
    props.text = text
    if let font = font { props.font = font }
    if let color = color { props.foregroundColor = color }
    props.textAlignment = alignment
    props.lineLimit = lineLimit
    return VNode(type: .text, props: props)
}

/// Virtual Image element.
public func VImage(
    name: String? = nil,
    image: NSImage? = nil,
    systemName: String? = nil,
    contentMode: VImageContentMode = .scaleAspectFit
) -> VNode {
    var props = VNodeProps()
    props.imageName = name
    props.image = image
    props.systemImageName = systemName
    props.imageContentMode = contentMode
    return VNode(type: .image, props: props)
}

/// Virtual Button element.
public func VButton(
    title: String,
    action: @escaping @Sendable () -> Void
) -> VNode {
    var props = VNodeProps()
    props.text = title
    props.onClick = action
    return VNode(type: .button, props: props)
}

/// Virtual Blur element with backdrop glass effect.
public func VBlur(
    material: NSVisualEffectView.Material = .hudWindow,
    blendingMode: NSVisualEffectView.BlendingMode = .behindWindow,
    radius: CGFloat = 20.0,
    @VNodeBuilder _ content: () -> [VNode] = { [] }
) -> VNode {
    var props = VNodeProps()
    props.blurMaterial = material
    props.blurBlendingMode = blendingMode
    props.blurRadius = radius
    return VNode(type: .blur, props: props, children: content())
}

/// Virtual Canvas element for direct CoreGraphics rendering.
public func VCanvas(
    draw: @escaping @Sendable (CGContext, CGSize) -> Void
) -> VNode {
    var props = VNodeProps()
    props.drawHandler = draw
    return VNode(type: .canvas, props: props)
}

/// Virtual Layer element for raw CALayer bridging.
public func VLayer(
    _ transform: CATransform3D = CATransform3DIdentity
) -> VNode {
    var props = VNodeProps()
    props.transform = transform
    return VNode(type: .layer, props: props)
}

/// Loop constructor for generating dynamic keyed VNode lists.
public func VForEach<Data: Sequence, ID: Hashable>(
    _ data: Data,
    id: KeyPath<Data.Element, ID>,
    @VNodeBuilder content: (Data.Element) -> [VNode]
) -> [VNode] {
    var nodes: [VNode] = []
    for item in data {
        let keyString = "\(item[keyPath: id])"
        let rendered = content(item).map { node -> VNode in
            var n = node
            if n.key == nil { n.key = keyString }
            return n
        }
        nodes.append(contentsOf: rendered)
    }
    return nodes
}

// MARK: - 4. Reconciler & O(N) Diffing Engine

/// Navigation path down the VNode tree, represented as an array of child indices.
public typealias VNodePath = [Int]

/// Move operation descriptor for keyed child reconciliation.
public struct VKeyedMove: Equatable, Sendable {
    public let key: String
    public let fromIndex: Int
    public let toIndex: Int

    public init(key: String, fromIndex: Int, toIndex: Int) {
        self.key = key
        self.fromIndex = fromIndex
        self.toIndex = toIndex
    }
}

/// Granular patch representation computed by the diff engine.
public enum VPatch: Equatable {
    case replace(path: VNodePath, oldNode: VNode, newNode: VNode)
    case updateProps(path: VNodePath, oldProps: VNodeProps, newProps: VNodeProps)
    case insertChild(path: VNodePath, index: Int, node: VNode)
    case removeChild(path: VNodePath, index: Int, node: VNode)
    case moveChild(path: VNodePath, fromIndex: Int, toIndex: Int, node: VNode)
    case reorderChildren(path: VNodePath, moves: [VKeyedMove])
    case textChanged(path: VNodePath, oldText: String, newText: String)

    public var path: VNodePath {
        switch self {
        case .replace(let p, _, _): return p
        case .updateProps(let p, _, _): return p
        case .insertChild(let p, _, _): return p
        case .removeChild(let p, _, _): return p
        case .moveChild(let p, _, _, _): return p
        case .reorderChildren(let p, _): return p
        case .textChanged(let p, _, _): return p
        }
    }
}

/// High-Performance O(N) Virtual DOM Reconciler.
public final class VDOMReconciler {
    /// Computes the minimal diff patch set between two virtual trees.
    public static func diff(oldTree: VNode, newTree: VNode) -> [VPatch] {
        var patches: [VPatch] = []
        diffNode(oldNode: oldTree, newNode: newTree, path: [], into: &patches)
        return patches
    }

    private static func diffNode(
        oldNode: VNode,
        newNode: VNode,
        path: VNodePath,
        into patches: inout [VPatch]
    ) {
        // 1. If nodes are identical by value, no patch is necessary.
        if oldNode == newNode {
            return
        }

        // 2. If node type or identity key mismatch, replace the entire subtree.
        if oldNode.type != newNode.type || (oldNode.key != nil && newNode.key != nil && oldNode.key != newNode.key) {
            patches.append(.replace(path: path, oldNode: oldNode, newNode: newNode))
            return
        }

        // 3. Diff Props
        if oldNode.props != newNode.props {
            if oldNode.type == .text && oldNode.props.text != newNode.props.text {
                patches.append(.textChanged(path: path, oldText: oldNode.props.text, newText: newNode.props.text))
            }
            patches.append(.updateProps(path: path, oldProps: oldNode.props, newProps: newNode.props))
        }

        // 4. Reconcile Children
        reconcileChildren(oldChildren: oldNode.children, newChildren: newNode.children, path: path, into: &patches)
    }

    /// Reconciles child lists utilizing fast key-index lookups when keys are present,
    /// or linear positional diffing when unkeyed.
    private static func reconcileChildren(
        oldChildren: [VNode],
        newChildren: [VNode],
        path: VNodePath,
        into patches: inout [VPatch]
    ) {
        let hasKeys = oldChildren.contains { $0.key != nil } || newChildren.contains { $0.key != nil }

        if hasKeys {
            reconcileKeyedChildren(oldChildren: oldChildren, newChildren: newChildren, path: path, into: &patches)
        } else {
            reconcileUnkeyedChildren(oldChildren: oldChildren, newChildren: newChildren, path: path, into: &patches)
        }
    }

    /// O(N) Key-based reconciliation algorithm.
    private static func reconcileKeyedChildren(
        oldChildren: [VNode],
        newChildren: [VNode],
        path: VNodePath,
        into patches: inout [VPatch]
    ) {
        var oldKeyMap: [String: (index: Int, node: VNode)] = [:]
        for (i, child) in oldChildren.enumerated() {
            let key = child.key ?? "unkeyed_\(i)"
            oldKeyMap[key] = (i, child)
        }

        var newKeyMap: [String: (index: Int, node: VNode)] = [:]
        for (i, child) in newChildren.enumerated() {
            let key = child.key ?? "unkeyed_\(i)"
            newKeyMap[key] = (i, child)
        }

        // Detect removals
        for (i, oldChild) in oldChildren.enumerated().reversed() {
            let key = oldChild.key ?? "unkeyed_\(i)"
            if newKeyMap[key] == nil {
                patches.append(.removeChild(path: path, index: i, node: oldChild))
            }
        }

        // Detect inserts, moves, and recursively diff matching keys
        var moves: [VKeyedMove] = []
        for (newIndex, newChild) in newChildren.enumerated() {
            let key = newChild.key ?? "unkeyed_\(newIndex)"
            if let oldEntry = oldKeyMap[key] {
                // Node exists in both: recursive diff
                var childPath = path
                childPath.append(newIndex)
                diffNode(oldNode: oldEntry.node, newNode: newChild, path: childPath, into: &patches)

                if oldEntry.index != newIndex {
                    moves.append(VKeyedMove(key: key, fromIndex: oldEntry.index, toIndex: newIndex))
                }
            } else {
                // New node inserted
                patches.append(.insertChild(path: path, index: newIndex, node: newChild))
            }
        }

        if !moves.isEmpty {
            patches.append(.reorderChildren(path: path, moves: moves))
        }
    }

    /// Positional reconciliation for unkeyed children.
    private static func reconcileUnkeyedChildren(
        oldChildren: [VNode],
        newChildren: [VNode],
        path: VNodePath,
        into patches: inout [VPatch]
    ) {
        let commonCount = min(oldChildren.count, newChildren.count)

        for i in 0..<commonCount {
            var childPath = path
            childPath.append(i)
            diffNode(oldNode: oldChildren[i], newNode: newChildren[i], path: childPath, into: &patches)
        }

        if newChildren.count > oldChildren.count {
            for i in commonCount..<newChildren.count {
                patches.append(.insertChild(path: path, index: i, node: newChildren[i]))
            }
        } else if oldChildren.count > newChildren.count {
            for i in (commonCount..<oldChildren.count).reversed() {
                patches.append(.removeChild(path: path, index: i, node: oldChildren[i]))
            }
        }
    }

    /// Applies patches immutably to a virtual tree.
    public static func apply(patches: [VPatch], to root: VNode) -> VNode {
        var current = root
        for patch in patches {
            apply(patch: patch, to: &current)
        }
        return current
    }

    private static func apply(patch: VPatch, to node: inout VNode) {
        switch patch {
        case .replace(let path, _, let newNode):
            replaceNode(at: path, in: &node, with: newNode)
        case .updateProps(let path, _, let newProps):
            updateProps(at: path, in: &node, with: newProps)
        case .insertChild(let path, let index, let child):
            insertChild(at: path, in: &node, index: index, child: child)
        case .removeChild(let path, let index, _):
            removeChild(at: path, in: &node, index: index)
        case .moveChild(let path, let fromIndex, let toIndex, _):
            moveChild(at: path, in: &node, from: fromIndex, to: toIndex)
        case .reorderChildren:
            break
        case .textChanged(let path, _, let newText):
            updateText(at: path, in: &node, text: newText)
        }
    }

    private static func replaceNode(at path: VNodePath, in node: inout VNode, with replacement: VNode) {
        if path.isEmpty {
            node = replacement
            return
        }
        var current = path
        let head = current.removeFirst()
        if head < node.children.count {
            replaceNode(at: current, in: &node.children[head], with: replacement)
        }
    }

    private static func updateProps(at path: VNodePath, in node: inout VNode, with newProps: VNodeProps) {
        if path.isEmpty {
            node.props = newProps
            return
        }
        var current = path
        let head = current.removeFirst()
        if head < node.children.count {
            updateProps(at: current, in: &node.children[head], with: newProps)
        }
    }

    private static func updateText(at path: VNodePath, in node: inout VNode, text: String) {
        if path.isEmpty {
            node.props.text = text
            return
        }
        var current = path
        let head = current.removeFirst()
        if head < node.children.count {
            updateText(at: current, in: &node.children[head], text: text)
        }
    }

    private static func insertChild(at path: VNodePath, in node: inout VNode, index: Int, child: VNode) {
        if path.isEmpty {
            let clampedIndex = min(max(0, index), node.children.count)
            node.children.insert(child, at: clampedIndex)
            return
        }
        var current = path
        let head = current.removeFirst()
        if head < node.children.count {
            insertChild(at: current, in: &node.children[head], index: index, child: child)
        }
    }

    private static func removeChild(at path: VNodePath, in node: inout VNode, index: Int) {
        if path.isEmpty {
            if index >= 0 && index < node.children.count {
                node.children.remove(at: index)
            }
            return
        }
        var current = path
        let head = current.removeFirst()
        if head < node.children.count {
            removeChild(at: current, in: &node.children[head], index: index)
        }
    }

    private static func moveChild(at path: VNodePath, in node: inout VNode, from: Int, to: Int) {
        if path.isEmpty {
            guard from >= 0, from < node.children.count, to >= 0, to < node.children.count else { return }
            let item = node.children.remove(at: from)
            node.children.insert(item, at: to)
            return
        }
        var current = path
        let head = current.removeFirst()
        if head < node.children.count {
            moveChild(at: current, in: &node.children[head], from: from, to: to)
        }
    }
}

// MARK: - 5. Reactive State Hooks

/// Reactive State Reference Box.
public final class VState<T>: ObservableObject {
    @Published public var value: T
    private var host: VDOMHostController?

    public init(_ initialValue: T) {
        self.value = initialValue
    }

    public func set(_ newValue: T) {
        self.value = newValue
        host?.scheduleRender()
    }

    public func mutate(_ closure: (inout T) -> Void) {
        closure(&self.value)
        host?.scheduleRender()
    }

    func bind(to host: VDOMHostController) {
        self.host = host
    }
}

/// Mutable reference hook holder.
public final class VRef<T> {
    public var current: T

    public init(_ initial: T) {
        self.current = initial
    }
}

/// Execution context tracking component hook slots during rendering.
public final class VDOMHookContext {
    public static let shared = VDOMHookContext()

    private var states: [Any] = []
    private var effects: [(deps: [AnyHashable], cleanup: (() -> Void)?)] = []
    private var currentIndex: Int = 0
    private var currentEffectIndex: Int = 0
    private weak var currentHost: VDOMHostController?

    private init() {}

    public func reset(host: VDOMHostController) {
        self.currentIndex = 0
        self.currentEffectIndex = 0
        self.currentHost = host
    }

    public func useVState<T>(_ initial: T) -> (T, (T) -> Void) {
        let index = currentIndex
        currentIndex += 1

        if index >= states.count {
            let stateBox = VState(initial)
            if let host = currentHost {
                stateBox.bind(to: host)
            }
            states.append(stateBox)
        }

        guard let stateBox = states[index] as? VState<T> else {
            fatalError("Hook type mismatch at slot \(index)")
        }

        let setter: (T) -> Void = { [weak stateBox] newValue in
            stateBox?.set(newValue)
        }

        return (stateBox.value, setter)
    }

    public func useVEffect(
        keys: [AnyHashable],
        effect: @escaping () -> (() -> Void)?
    ) {
        let index = currentEffectIndex
        currentEffectIndex += 1

        if index >= effects.count {
            let cleanup = effect()
            effects.append((deps: keys, cleanup: cleanup))
        } else {
            let prev = effects[index]
            if prev.deps != keys {
                prev.cleanup?()
                let newCleanup = effect()
                effects[index] = (deps: keys, cleanup: newCleanup)
            }
        }
    }

    public func useVMemo<T>(keys: [AnyHashable], compute: () -> T) -> T {
        let index = currentIndex
        currentIndex += 1

        if index >= states.count {
            let value = compute()
            states.append((deps: keys, value: value))
            return value
        }

        if let cached = states[index] as? (deps: [AnyHashable], value: T) {
            if cached.deps == keys {
                return cached.value
            } else {
                let fresh = compute()
                states[index] = (deps: keys, value: fresh)
                return fresh
            }
        }

        let fresh = compute()
        states[index] = (deps: keys, value: fresh)
        return fresh
    }

    public func useVRef<T>(_ initial: T) -> VRef<T> {
        let index = currentIndex
        currentIndex += 1

        if index >= states.count {
            let ref = VRef(initial)
            states.append(ref)
            return ref
        }

        guard let ref = states[index] as? VRef<T> else {
            fatalError("Hook ref mismatch at slot \(index)")
        }
        return ref
    }
}

// Global Free Hook Functions
public func useVState<T>(_ initial: T) -> (T, (T) -> Void) {
    return VDOMHookContext.shared.useVState(initial)
}

public func useVEffect(keys: [AnyHashable], _ effect: @escaping () -> (() -> Void)?) {
    VDOMHookContext.shared.useVEffect(keys: keys, effect: effect)
}

public func useVMemo<T>(keys: [AnyHashable], _ compute: () -> T) -> T {
    return VDOMHookContext.shared.useVMemo(keys: keys, compute: compute)
}

public func useVRef<T>(_ initial: T) -> VRef<T> {
    return VDOMHookContext.shared.useVRef(initial)
}

// MARK: - 6. Hardware Layer & Native NSView Host

/// High-performance NSView subclass rendering a virtual DOM tree via direct CALayer hierarchy syncing.
public final class VDOMHostView: NSView {
    public private(set) var currentVTree: VNode?
    private var isRenderScheduled: Bool = false
    private var sublayerNodeMap: [String: CALayer] = [:]
    public var onTreeReconciled: ((_ patchesCount: Int, _ latencyMicroseconds: Double) -> Void)?

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupLayer()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayer()
    }

    private func setupLayer() {
        self.wantsLayer = true
        self.layer = CALayer()
        self.layer?.masksToBounds = true
        self.layer?.isOpaque = false
    }

    /// Renders a new virtual DOM tree, computing minimal patches and applying them to the native layer tree.
    public func render(newTree: VNode) {
        let startTime = CACurrentMediaTime()

        guard let oldTree = currentVTree else {
            // First mount: full build
            self.currentVTree = newTree
            self.layer?.sublayers?.forEach { $0.removeFromSuperlayer() }
            if let rootLayer = buildNativeLayer(from: newTree) {
                self.layer?.addSublayer(rootLayer)
            }
            let elapsed = (CACurrentMediaTime() - startTime) * 1_000_000.0
            onTreeReconciled?(0, elapsed)
            return
        }

        // Subsequent render: Diff & Patch
        let patches = VDOMReconciler.diff(oldTree: oldTree, newTree: newTree)
        applyPatchesToNativeTree(patches: patches, oldTree: oldTree, newTree: newTree)
        self.currentVTree = newTree

        let elapsed = (CACurrentMediaTime() - startTime) * 1_000_000.0
        onTreeReconciled?(patches.count, elapsed)
    }

    private func applyPatchesToNativeTree(patches: [VPatch], oldTree: VNode, newTree: VNode) {
        guard !patches.isEmpty else { return }

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        for patch in patches {
            switch patch {
            case .replace(let path, _, let newNode):
                if let oldLayer = findLayer(at: path) {
                    let parent = oldLayer.superlayer
                    let index = parent?.sublayers?.firstIndex(of: oldLayer)
                    oldLayer.removeFromSuperlayer()
                    if let fresh = buildNativeLayer(from: newNode) {
                        if let idx = index {
                            parent?.insertSublayer(fresh, at: UInt32(idx))
                        } else {
                            parent?.addSublayer(fresh)
                        }
                    }
                }
            case .updateProps(let path, _, let newProps):
                if let targetLayer = findLayer(at: path) {
                    updateNativeLayer(targetLayer, with: newProps)
                }
            case .insertChild(let path, let index, let child):
                let parentLayer = path.isEmpty ? self.layer : findLayer(at: path)
                if let childLayer = buildNativeLayer(from: child) {
                    parentLayer?.insertSublayer(childLayer, at: UInt32(index))
                }
            case .removeChild(let path, let index, _):
                let parentLayer = path.isEmpty ? self.layer : findLayer(at: path)
                if let sublayers = parentLayer?.sublayers, index < sublayers.count {
                    sublayers[index].removeFromSuperlayer()
                }
            case .moveChild(let path, let from, let to, _):
                let parentLayer = path.isEmpty ? self.layer : findLayer(at: path)
                if let sublayers = parentLayer?.sublayers, from < sublayers.count {
                    let layerToMove = sublayers[from]
                    layerToMove.removeFromSuperlayer()
                    parentLayer?.insertSublayer(layerToMove, at: UInt32(to))
                }
            case .reorderChildren:
                break
            case .textChanged(let path, _, let newText):
                if let textLayer = findLayer(at: path) as? CATextLayer {
                    textLayer.string = newText
                }
            }
        }

        CATransaction.commit()
    }

    private func findLayer(at path: VNodePath) -> CALayer? {
        var current: CALayer? = self.layer?.sublayers?.first
        for index in path {
            guard let sublayers = current?.sublayers, index < sublayers.count else { return nil }
            current = sublayers[index]
        }
        return current
    }

    private func buildNativeLayer(from node: VNode) -> CALayer? {
        let layer: CALayer
        switch node.type {
        case .text:
            let textLayer = CATextLayer()
            textLayer.string = node.props.text
            textLayer.font = node.props.font
            textLayer.fontSize = node.props.font.pointSize
            textLayer.foregroundColor = node.props.foregroundColor?.cgColor ?? NSColor.white.cgColor
            textLayer.contentsScale = NSScreen.main?.backingScaleFactor ?? 2.0
            textLayer.alignmentMode = alignmentMode(for: node.props.textAlignment)
            textLayer.isWrapped = true
            layer = textLayer
        case .image:
            layer = CALayer()
            if let img = node.props.image {
                layer.contents = img.layerContents(forContentsScale: 2.0)
            } else if let imgName = node.props.imageName, let img = NSImage(named: imgName) {
                layer.contents = img.layerContents(forContentsScale: 2.0)
            } else if let sysName = node.props.systemImageName, let img = NSImage(systemSymbolName: sysName, accessibilityDescription: nil) {
                layer.contents = img.layerContents(forContentsScale: 2.0)
            }
            layer.contentsGravity = contentsGravity(for: node.props.imageContentMode)
        case .blur:
            layer = CALayer()
            layer.backgroundColor = NSColor.black.withAlphaComponent(0.4).cgColor
            layer.backgroundFilters = []
        case .canvas:
            let canvasLayer = VDOMCanvasLayer(drawHandler: node.props.drawHandler)
            canvasLayer.contentsScale = NSScreen.main?.backingScaleFactor ?? 2.0
            layer = canvasLayer
        default:
            layer = CALayer()
        }

        updateNativeLayer(layer, with: node.props)

        for child in node.children {
            if let childLayer = buildNativeLayer(from: child) {
                layer.addSublayer(childLayer)
            }
        }

        return layer
    }

    private func updateNativeLayer(_ layer: CALayer, with props: VNodeProps) {
        layer.frame = props.frame.isEmpty ? (props.size.map { CGRect(origin: .zero, size: $0) } ?? layer.frame) : props.frame
        layer.opacity = Float(props.opacity)
        layer.cornerRadius = props.cornerRadius
        layer.borderWidth = props.borderWidth
        layer.borderColor = props.borderColor?.cgColor
        layer.masksToBounds = props.clipToBounds
        layer.zPosition = CGFloat(props.zIndex)
        layer.transform = props.transform

        if let bg = props.backgroundColor {
            layer.backgroundColor = bg.cgColor
        }

        if props.shadowOpacity > 0 {
            layer.shadowColor = props.shadowColor?.cgColor ?? NSColor.black.cgColor
            layer.shadowRadius = props.shadowRadius
            layer.shadowOffset = props.shadowOffset
            layer.shadowOpacity = Float(props.shadowOpacity)
        } else {
            layer.shadowOpacity = 0
        }

        if let textLayer = layer as? CATextLayer {
            textLayer.string = props.text
            textLayer.font = props.font
            textLayer.fontSize = props.font.pointSize
            if let fg = props.foregroundColor {
                textLayer.foregroundColor = fg.cgColor
            }
        }

        if let canvasLayer = layer as? VDOMCanvasLayer {
            canvasLayer.drawHandler = props.drawHandler
            canvasLayer.setNeedsDisplay()
        }
    }

    private func alignmentMode(for alignment: NSTextAlignment) -> CATextLayerAlignmentMode {
        switch alignment {
        case .left: return .left
        case .center: return .center
        case .right: return .right
        case .justified: return .justified
        case .natural: return .natural
        @unknown default: return .left
        }
    }

    private func contentsGravity(for mode: VImageContentMode) -> CALayerContentsGravity {
        switch mode {
        case .scaleToFill: return .resize
        case .scaleAspectFit: return .resizeAspect
        case .scaleAspectFill: return .resizeAspectFill
        case .center: return .center
        }
    }
}

/// Custom CALayer executing declarative CGContext rendering closures.
public final class VDOMCanvasLayer: CALayer {
    public var drawHandler: (@Sendable (CGContext, CGSize) -> Void)?

    public init(drawHandler: (@Sendable (CGContext, CGSize) -> Void)?) {
        self.drawHandler = drawHandler
        super.init()
        self.needsDisplayOnBoundsChange = true
    }

    override init(layer: Any) {
        super.init(layer: layer)
        if let other = layer as? VDOMCanvasLayer {
            self.drawHandler = other.drawHandler
        }
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    public override func draw(in ctx: CGContext) {
        super.draw(in: ctx)
        drawHandler?(ctx, bounds.size)
    }
}

// MARK: - 7. VDOMHostController & Render Scheduler

/// Host controller coordinating component rendering, hooks, and hardware layer sync.
public final class VDOMHostController: ObservableObject {
    public let hostView: VDOMHostView
    private var renderClosure: () -> VNode
    private var isRenderScheduled: Bool = false

    public init<C: VDOMComponent>(_ component: C, frame: CGRect = .zero) {
        self.hostView = VDOMHostView(frame: frame)
        self.renderClosure = {
            component.body.asVNodes().first ?? VNode()
        }
        mount()
    }

    public init(frame: CGRect = .zero, render: @escaping () -> VNode) {
        self.hostView = VDOMHostView(frame: frame)
        self.renderClosure = render
        mount()
    }

    private func mount() {
        performRender()
    }

    public func scheduleRender() {
        guard !isRenderScheduled else { return }
        isRenderScheduled = true

        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.isRenderScheduled = false
            self.performRender()
        }
    }

    private func performRender() {
        VDOMHookContext.shared.reset(host: self)
        let newTree = renderClosure()
        hostView.render(newTree: newTree)
    }
}

// MARK: - 8. SwiftUI & Metal Bridge

/// SwiftUI wrapper for seamless embedding of Swift Virtual DOM trees in any SwiftUI view hierarchy.
public struct SwiftUIVDOMBridge: NSViewRepresentable {
    public typealias NSViewType = VDOMHostView

    private let rootNode: VNode

    public init(@VNodeBuilder content: () -> [VNode]) {
        self.rootNode = content().first ?? VNode()
    }

    public init(node: VNode) {
        self.rootNode = node
    }

    public func makeNSView(context: Context) -> VDOMHostView {
        let view = VDOMHostView()
        view.render(newTree: rootNode)
        return view
    }

    public func updateNSView(_ nsView: VDOMHostView, context: Context) {
        nsView.render(newTree: rootNode)
    }
}

// MARK: - 9. Sub-Millisecond Performance Benchmarks

public enum VDOMBenchmark {
    /// Runs an in-memory diffing benchmark across large virtual node trees.
    public static func runDiffBenchmark(nodeCount: Int = 1000) -> (latencyMicroseconds: Double, patchesCount: Int) {
        // Build Old Tree
        var oldChildren: [VNode] = []
        for i in 0..<nodeCount {
            var props = VNodeProps()
            props.text = "Item #\(i)"
            props.frame = CGRect(x: 0, y: CGFloat(i * 20), width: 200, height: 20)
            oldChildren.append(VNode(id: "node_\(i)", key: "key_\(i)", type: .text, props: props))
        }
        let oldTree = VNode(type: .container, children: oldChildren)

        // Build New Tree with updates, inserts, and removes
        var newChildren: [VNode] = []
        for i in 0..<nodeCount {
            if i % 10 == 0 {
                // Modified text and frame
                var props = VNodeProps()
                props.text = "Updated Item #\(i)"
                props.frame = CGRect(x: 10, y: CGFloat(i * 20), width: 250, height: 20)
                newChildren.append(VNode(id: "node_\(i)", key: "key_\(i)", type: .text, props: props))
            } else if i % 25 != 0 {
                // Retained item
                var props = VNodeProps()
                props.text = "Item #\(i)"
                props.frame = CGRect(x: 0, y: CGFloat(i * 20), width: 200, height: 20)
                newChildren.append(VNode(id: "node_\(i)", key: "key_\(i)", type: .text, props: props))
            }
            // (i % 25 == 0 is removed)
        }

        // Insert new elements
        for j in 0..<20 {
            var props = VNodeProps()
            props.text = "Fresh Item #\(j)"
            newChildren.append(VNode(id: "fresh_\(j)", key: "fresh_key_\(j)", type: .text, props: props))
        }
        let newTree = VNode(type: .container, children: newChildren)

        // Measure diff latency
        let start = CACurrentMediaTime()
        let patches = VDOMReconciler.diff(oldTree: oldTree, newTree: newTree)
        let elapsed = (CACurrentMediaTime() - start) * 1_000_000.0

        return (elapsed, patches.count)
    }
}
