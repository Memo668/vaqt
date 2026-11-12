import SwiftUI

extension EnvironmentValues {

    /// Wie die Seiten ihre beiden Teile zeigen. Gesetzt wird der Wert dort, wo der Platz für den Inhalt
    /// feststeht (`readsPageArrangement()`), damit er sich beim Wischen zwischen den Seiten nicht ändert.
    /// Ohne ihn stehen die Teile untereinander, wie auf dem iPhone.
    @Entry public var pageArrangement: PageArrangement = .stacked

    /// Höhe des Platzes für den Inhalt einer Seite, ohne die Ränder des Systems – gemessen wie
    /// `pageArrangement`. Seiten, die ihre Spalten senkrecht mittig zeigen, sind mindestens so hoch.
    @Entry public var pageHeight: CGFloat = 0
}

/// Die beiden Teile einer Seite: untereinander wie auf dem iPhone, innen auf dem iPhone Duo als zwei
/// Spalten, die sich am Falz treffen – `.cols`, `.col-a`, `.col-b` im Prototyp.
///
/// In Spalten hält die zweite 8 pt Innenrand links und rechts (`.col-b`: `padding-inline: 8px`), außer
/// die Seite gibt einen anderen vor (Qibla: 28 pt ohne den Seitenrand der Teile). Beide Teile
/// bringen ihren Seitenrand selbst mit, wie auf dem iPhone.
public struct FoldColumns<First: View, Second: View>: View {
    private let alignment: VerticalAlignment
    private let secondPadding: CGFloat
    private let first: First
    private let second: Second

    @Environment(\.pageArrangement) private var arrangement

    /// - Parameters:
    ///   - alignment: senkrechte Lage der Spalten zueinander – `.top` für Anleitung, Verse und Nachholen,
    ///     `.center` für Zeiten und Qibla (`align-items: center`).
    ///   - secondPadding: Innenrand der zweiten Spalte links und rechts.
    public init(
        alignment: VerticalAlignment = .top, secondPadding: CGFloat = FoldColumnsMetrics.secondPadding,
        @ViewBuilder first: () -> First, @ViewBuilder second: () -> Second
    ) {
        self.alignment = alignment
        self.secondPadding = secondPadding
        self.first = first()
        self.second = second()
    }

    public var body: some View {
        switch arrangement {
        case .stacked, .rows:
            // Die Tischhaltung legt die Seite selbst in zwei Teile (`PageScroll`); hier stünden sie untereinander.
            VStack(spacing: 0) {
                first
                second
            }
        case .columns(let leading, let trailing):
            HStack(alignment: alignment, spacing: 0) {
                first
                    .frame(width: leading)
                second
                    .padding(.horizontal, secondPadding)
                    .frame(width: trailing)
            }
        }
    }
}

/// Maße der Spalten innen auf dem iPhone Duo.
public enum FoldColumnsMetrics {
    /// Innenrand der zweiten Spalte (`.col-b`: `padding-inline: 8px`).
    public static let secondPadding: CGFloat = 8
}
