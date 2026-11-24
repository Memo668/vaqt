import PrayerCore
import SwiftUI

/// Der erste Teil der Seite „Verse“: Titel, die Karte mit dem Vers und die Fußnote zur Übersetzung –
/// `.col-a` in `versesPage()`. Auf dem inneren Display des iPhone Duo wird das die linke Spalte
/// (Design Spec § 8).
///
/// Mit dem Seitenrand; den Abstand zur oberen Leiste setzt die Seite.
public struct VersesOverview: View {
    private let day: VerseDay
    private let onCopy: () -> Void

    /// - Parameters:
    ///   - day: der Tag, dessen Vers die Karte zeigt – heute oder ein angetippter Eintrag der Liste.
    ///   - onCopy: „Kopieren“.
    public init(day: VerseDay, onCopy: @escaping () -> Void) {
        self.day = day
        self.onCopy = onCopy
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            PageTitle(L10n.navVerses)
                .padding(.top, PageTitle.spacingAbove)
                .padding(.bottom, PageTitle.spacingBelow)
            VerseCard(day, onCopy: onCopy)
            // Nennt die Übersetzung der Sprache, auf Arabisch die Quelle des Verstexts (Spec § 11.1).
            CardFootnote(L10n.verseSource)
                .padding(.top, VersesLayout.cardBottom)
        }
        .padding(.horizontal, Layout.inset)
    }
}

/// Der zweite Teil der Seite „Verse“: „Letzte Tage“ mit den Versen von heute und den fünf Tagen davor –
/// `.col-b` in `versesPage()`. Antippen eines Eintrags zeigt seinen Vers oben in der Karte.
///
/// Mit dem Seitenrand und dem Abstand über der Überschrift (24 pt).
public struct RecentVerses: View {
    private let days: [VerseDay]
    private let selection: CalendarDay
    private let onSelect: (CalendarDay) -> Void

    /// - Parameters:
    ///   - days: die Einträge, heute zuerst.
    ///   - selection: der Tag, dessen Vers die Karte zeigt.
    ///   - onSelect: Antippen eines Eintrags (`verse-pick`).
    public init(days: [VerseDay], selection: CalendarDay, onSelect: @escaping (CalendarDay) -> Void) {
        self.days = days
        self.selection = selection
        self.onSelect = onSelect
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(L10n.versePrev)
                .padding(.top, SectionHeader.spacingAbove)
                .padding(.bottom, SectionHeader.spacingBelow)
            VStack(spacing: VerseListMetrics.gap) {
                ForEach(days) { day in
                    VerseListItem(day, isSelected: day.day == selection) {
                        onSelect(day.day)
                    }
                }
            }
        }
        .padding(.horizontal, Layout.inset)
    }
}

/// Abstände der Seite „Verse“.
enum VersesLayout {
    /// Abstand unter der Karte (`.card`: `margin-bottom: 10px`). Die Fußnote hält unten 8 pt
    /// (`.card-foot`), die Überschrift „Letzte Tage“ oben 24 pt – im CSS fallen beide zusammen auf 24 pt.
    static let cardBottom: CGFloat = 10
}
