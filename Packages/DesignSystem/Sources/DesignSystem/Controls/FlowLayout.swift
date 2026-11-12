import SwiftUI

/// Setzt Bausteine nebeneinander und bricht in die nächste Reihe um, wenn der Platz nicht reicht –
/// `display: flex; flex-wrap: wrap; align-items: flex-start` im Prototyp. Jede Reihe steht oben bündig.
///
/// Braucht z. B. die Rakʿa-Folge der Anleitung: In der Standardgröße passt sie in eine Reihe, mit großer
/// Schrift oder längeren Texten bricht sie um.
public struct FlowLayout: SwiftUI.Layout {
    /// Abstand zwischen zwei Bausteinen einer Reihe.
    public var horizontalSpacing: CGFloat
    /// Abstand zwischen zwei Reihen.
    public var verticalSpacing: CGFloat

    public init(horizontalSpacing: CGFloat, verticalSpacing: CGFloat) {
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout ()) -> CGSize {
        let rows = arrange(sizes: subviews.map { $0.sizeThatFits(.unspecified) }, maxWidth: proposal.width)
        let width = rows.map(\.width).max() ?? 0
        let height = rows.map(\.height).reduce(0, +) + verticalSpacing * CGFloat(max(rows.count - 1, 0))
        return CGSize(width: proposal.width ?? width, height: height)
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: LayoutSubviews, cache: inout ()) {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        var y = bounds.minY
        for row in arrange(sizes: sizes, maxWidth: bounds.width) {
            var x = bounds.minX
            for index in row.indices {
                let size = sizes[index]
                let width = min(size.width, bounds.width)
                subviews[index].place(
                    at: CGPoint(x: x, y: y), anchor: .topLeading,
                    proposal: ProposedViewSize(width: width, height: size.height)
                )
                x += width + horizontalSpacing
            }
            y += row.height + verticalSpacing
        }
    }

    /// Eine Reihe: welche Bausteine sie trägt, wie breit und wie hoch sie ist.
    struct Row: Equatable {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    /// Verteilt Bausteine der Größe `sizes` auf Reihen von höchstens `maxWidth` Breite. Ein Baustein, der
    /// allein schon breiter ist, bekommt eine eigene Reihe.
    func arrange(sizes: [CGSize], maxWidth: CGFloat?) -> [Row] {
        let limit = maxWidth ?? .infinity
        var rows: [Row] = []
        var row = Row()
        for (index, size) in sizes.enumerated() {
            let width = min(size.width, limit)
            let needed = row.indices.isEmpty ? width : row.width + horizontalSpacing + width
            if !row.indices.isEmpty, needed > limit {
                rows.append(row)
                row = Row()
            }
            row.width = row.indices.isEmpty ? width : row.width + horizontalSpacing + width
            row.height = max(row.height, size.height)
            row.indices.append(index)
        }
        if !row.indices.isEmpty {
            rows.append(row)
        }
        return rows
    }
}
