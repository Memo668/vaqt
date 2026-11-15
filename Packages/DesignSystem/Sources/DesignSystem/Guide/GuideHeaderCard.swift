import PrayerCore
import SwiftUI

/// Die Kopfkarte der Anleitung: Status und Zeitfenster, Symbol und Name des Gebets, drei Fakten-Kacheln
/// (Rakʿa Fard, Rezitation, Sunna), die Rakʿa-Folge, der Hinweis zu al-Fātiḥa, der Knopf „Gebet Schritt
/// für Schritt“ (Spec § 9.6) und nach einer manuellen Wahl der Knopf „Zum aktuellen Gebet“. Die
/// `<article class="card">` in `guidePage()`.
public struct GuideHeaderCard: View {
    private let header: GuideHeader
    private let onWalk: () -> Void
    private let onReturn: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    /// - Parameters:
    ///   - onWalk: „Gebet Schritt für Schritt“ (`walk-start`) für das gezeigte Gebet.
    ///   - onReturn: „Zum aktuellen Gebet“ (`guide-now`).
    public init(_ header: GuideHeader, onWalk: @escaping () -> Void, onReturn: @escaping () -> Void) {
        self.header = header
        self.onWalk = onWalk
        self.onReturn = onReturn
    }

    public var body: some View {
        Card {
            VStack(alignment: .leading, spacing: 0) {
                // Ohne Zeiten gibt es weder Status noch Zeitfenster; dann fehlt die Zeile ganz.
                if header.status != nil || header.window != nil {
                    CardEyebrow(
                        leading: header.status ?? "", trailing: header.window ?? "",
                        trailingHasTabularDigits: true
                    )
                }

                HStack(spacing: GuideHeaderMetrics.titleGap) {
                    SymbolBadge.prayer(header.prayer.symbolName)
                    // `letter-spacing: .36px` ist die Laufweite, die das System bei 28 pt ohnehin setzt.
                    Text(header.prayer.localizedName)
                        .textStyle(.title1, weight: .bold, lineHeight: GuideHeaderMetrics.titleLineHeight)
                        .foregroundStyle(Palette.label)
                        .accessibilityAddTraits(.isHeader)
                }
                .padding(.top, GuideHeaderMetrics.titleTop)
                .padding(.bottom, GuideHeaderMetrics.titleBottom)

                facts

                RakahSequence(header.rakahs)
                    .padding(.top, GuideHeaderMetrics.sequenceTop)

                if header.rakahs.hasMoreThanTwo {
                    Text(L10n.onlyFatiha)
                        .textStyle(.footnote, lineHeight: GuideHeaderMetrics.noteLineHeight)
                        .foregroundStyle(Palette.textSecondary)
                        .padding(.top, GuideHeaderMetrics.noteTop)
                }

                walk

                if let returnPrayer = header.returnPrayer {
                    PillButton(L10n.guideBack, systemImage: returnPrayer.symbolName, action: onReturn)
                        .padding(.top, GuideHeaderMetrics.buttonTop)
                }
            }
        }
    }

    /// „Gebet Schritt für Schritt“ mit Symbol und darunter „Haltung für Haltung durch alle 4 Rakʿas von
    /// Dhuhr.“ (`.g-walk`, `.g-walk-sub`).
    private var walk: some View {
        VStack(spacing: 0) {
            PrimaryButton(L10n.wkStart, compactSymbol: GuideHeaderMetrics.walkSymbol, action: onWalk)
            Text(L10n.wkStartSub(n: String(header.rakahs.count), p: header.prayer.localizedName))
                .textStyle(.footnote, lineHeight: GuideHeaderMetrics.walkSubLineHeight)
                .foregroundStyle(Palette.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.top, GuideHeaderMetrics.walkSubTop)
        }
        .padding(.top, GuideHeaderMetrics.walkTop)
    }

    /// Drei gleich breite, gleich hohe Kacheln (`.facts`: `grid-template-columns: repeat(3,1fr)`). Ab den
    /// AX-Größen stehen sie untereinander, jede über die ganze Breite: Nebeneinander blieben für einen Wert
    /// wie „4 vorher (freiwillig)“ keine 80 pt, und die Wörter zerfielen (Phase 11).
    private var facts: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: FactTile.spacing))
            : AnyLayout(HStackLayout(alignment: .top, spacing: FactTile.spacing))
        return layout {
            FactTile(value: String(header.rakahs.count), caption: L10n.rakFard, isProminent: true)
            FactTile(value: header.rakahs.recitation.localizedName, caption: L10n.recite)
            FactTile(value: header.prayer.localizedSunna, caption: L10n.sunna)
        }
        .fixedSize(horizontal: false, vertical: true)
    }
}

/// Maße der Kopfkarte (`.g-head`: `gap: 12px; margin: 10px 0 16px`; `.g-title`: `…/1.15`;
/// `.rak`: `margin-top: 18px`; `.g-note`: `margin: 12px 0 0; line-height: 1.38`; `.g-now`: `margin-top: 14px`;
/// `.g-walk`: `margin-top: 18px`, `ic('play', 18)`; `.g-walk-sub`: `margin: 8px 0 0`, Footnote, Zeilenhöhe 1,35).
enum GuideHeaderMetrics {
    static let titleGap: CGFloat = 12
    static let titleTop: CGFloat = 10
    static let titleBottom: CGFloat = 16
    static let titleLineHeight: CGFloat = 1.15
    static let sequenceTop: CGFloat = 18
    static let noteTop: CGFloat = 12
    static let noteLineHeight: CGFloat = 1.38
    static let buttonTop: CGFloat = 14
    static let walkTop: CGFloat = 18
    static let walkSymbol = "play.fill"
    static let walkSubTop: CGFloat = 8
    static let walkSubLineHeight: CGFloat = 1.35
}
