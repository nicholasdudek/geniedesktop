import SwiftUI

/// Lays children out left to right and wraps to a new line when the next one will not
/// fit — the flexbox `flex-wrap: wrap` behaviour SwiftUI has no built-in for.
///
/// Used wherever a set of options has to stay fully reachable as a pane is resized:
/// a horizontal ScrollView hides options off-screen, and a fixed grid either overflows
/// narrow panes or strands whitespace in wide ones.
public struct FlowingChips<Item: Identifiable, Content: View>: View {
    private let items: [Item]
    private let horizontalSpacing: CGFloat
    private let verticalSpacing: CGFloat
    private let content: (Item) -> Content

    public init(
        items: [Item],
        horizontalSpacing: CGFloat = 8,
        verticalSpacing: CGFloat = 8,
        @ViewBuilder content: @escaping (Item) -> Content
    ) {
        self.items = items
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
        self.content = content
    }

    public var body: some View {
        // The layout reads each child's own ideal size, so chips of different widths
        // pack correctly rather than all being forced to the widest one.
        FlowLayout(horizontalSpacing: horizontalSpacing, verticalSpacing: verticalSpacing) {
            ForEach(items) { item in
                content(item)
            }
        }
    }
}

/// The wrapping layout itself. Separate from `FlowingChips` so it can also be used
/// directly with heterogeneous children.
public struct FlowLayout: Layout {
    public var horizontalSpacing: CGFloat
    public var verticalSpacing: CGFloat

    public init(horizontalSpacing: CGFloat = 8, verticalSpacing: CGFloat = 8) {
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        let rows = layout(subviews: subviews, maxWidth: maxWidth)
        let height = rows.reduce(into: CGFloat.zero) { total, row in
            total += row.height + (total > 0 ? verticalSpacing : 0)
        }
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: min(width, maxWidth == .infinity ? width : maxWidth), height: height)
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = layout(subviews: subviews, maxWidth: bounds.width)
        var y = bounds.minY
        for row in rows {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(
                    at: CGPoint(x: x, y: y),
                    anchor: .topLeading,
                    proposal: ProposedViewSize(size)
                )
                x += size.width + horizontalSpacing
            }
            y += row.height + verticalSpacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func layout(subviews: Subviews, maxWidth: CGFloat) -> [Row] {
        var rows: [Row] = []
        var current = Row()

        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let needed = current.indices.isEmpty ? size.width : current.width + horizontalSpacing + size.width

            if needed > maxWidth, !current.indices.isEmpty {
                rows.append(current)
                current = Row()
                current.indices = [index]
                current.width = size.width
                current.height = size.height
            } else {
                current.indices.append(index)
                current.width = needed
                current.height = max(current.height, size.height)
            }
        }
        if !current.indices.isEmpty { rows.append(current) }
        return rows
    }
}
