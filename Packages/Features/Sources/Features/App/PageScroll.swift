import DesignSystem
import SwiftUI

/// Die senkrecht scrollende Seite eines Tabs mit ihren beiden Teilen – `.scroll`, `.cols`, `.col-a`,
/// `.col-b` im Prototyp: Inhalt mit dem Abstand zur oberen Leiste und zur Tableiste, auf dem gruppierten
/// Hintergrund.
///
/// - Auf dem iPhone und außen auf dem iPhone Duo stehen die Teile untereinander.
/// - Innen quer stehen sie als zwei Spalten am Falz (`FoldColumns`) in einer gemeinsamen Scroll-Ansicht.
///   Sollen sie mittig stehen (Zeiten, Qibla), ist der Inhalt mindestens so hoch wie der sichtbare
///   Bereich; die Spalten stehen darin senkrecht mittig (`.home .cols`, `.qibla .cols`: `min-height`,
///   `align-items: center`).
/// - In der Tischhaltung steht der erste Teil über dem Falz und der zweite darunter, jeder in einer
///   eigenen Scroll-Ansicht.
///
/// Stehen die Leisten senkrecht am Rand (iPhone Duo), gibt es oben keine Leiste: Der Inhalt beginnt
/// 14 pt unter dem oberen Rand (`padding-top: 14px`), aber nicht über dem sicheren Bereich des Systems.
struct PageScroll<First: View, Second: View>: View {
    private let centersParts: Bool
    private let alignment: VerticalAlignment
    private let secondPadding: CGFloat
    private let position: Binding<ScrollPosition>?
    private let first: First
    private let second: Second

    @Environment(\.pageArrangement) private var arrangement
    @Environment(\.pageHeight) private var pageHeight
    @Environment(\.verticalBarEdge) private var verticalBarEdge
    /// Der Rand des Systems über dem Inhalt.
    @State private var safeTop: CGFloat = 0

    /// - Parameters:
    ///   - centersParts: Spalten und Teile senkrecht mittig zeigen (Zeiten, Qibla).
    ///   - alignment: senkrechte Lage der Spalten zueinander.
    ///   - secondPadding: Innenrand der zweiten Spalte links und rechts.
    ///   - position: Scroll-Position der Seite – in der Tischhaltung die des oberen Teils.
    init(
        centersParts: Bool = false, alignment: VerticalAlignment = .top,
        secondPadding: CGFloat = FoldColumnsMetrics.secondPadding, position: Binding<ScrollPosition>? = nil,
        @ViewBuilder first: () -> First, @ViewBuilder second: () -> Second
    ) {
        self.centersParts = centersParts
        self.alignment = alignment
        self.secondPadding = secondPadding
        self.position = position
        self.first = first()
        self.second = second()
    }

    var body: some View {
        Group {
            if case .rows(let top, let gap, let bottom) = arrangement {
                VStack(spacing: gap) {
                    part(height: top, bottomPadding: PageMetrics.rowGap) { first }
                        .scrollPosition(position)
                    part(height: bottom, bottomPadding: PageMetrics.contentBottom) { second }
                }
            } else {
                page
            }
        }
        .background(Palette.backgroundGrouped)
    }

    /// Untereinander oder in Spalten, in einer Scroll-Ansicht.
    private var page: some View {
        let top = PageMetrics.contentTop(hasVerticalBar: verticalBarEdge != nil, safeAreaTop: safeTop)
        let columns = FoldColumns(alignment: alignment, secondPadding: secondPadding) { first } second: { second }
        return ScrollView {
            Group {
                if centersParts, arrangement.isColumns {
                    columns
                        .frame(
                            maxWidth: .infinity,
                            minHeight: max(0, pageHeight - top - PageMetrics.contentBottom),
                            alignment: .center
                        )
                } else {
                    columns
                }
            }
            .padding(.top, top)
            .padding(.bottom, PageMetrics.contentBottom)
        }
        .scrollPosition(position)
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
            geometry.contentInsets.top
        } action: { _, top in
            safeTop = top
        }
    }

    /// Ein Teil in der Tischhaltung: so hoch wie sein Platz über oder unter dem Falz, mit eigener
    /// Scroll-Ansicht; bei Zeiten und Qibla darin senkrecht mittig.
    private func part<Content: View>(
        height: CGFloat, bottomPadding: CGFloat, @ViewBuilder content: () -> Content
    ) -> some View {
        ScrollView {
            content()
                .frame(
                    maxWidth: .infinity,
                    minHeight: centersParts ? max(0, height - PageMetrics.contentTop - bottomPadding) : nil,
                    alignment: .center
                )
                .padding(.top, PageMetrics.contentTop)
                .padding(.bottom, bottomPadding)
        }
        .frame(height: height)
    }
}

extension View {

    /// Bindet die Scroll-Position, falls es eine gibt.
    @ViewBuilder
    fileprivate func scrollPosition(_ position: Binding<ScrollPosition>?) -> some View {
        if let position {
            scrollPosition(position)
        } else {
            self
        }
    }
}
