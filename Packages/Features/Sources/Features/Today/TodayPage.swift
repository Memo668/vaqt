import DesignSystem
import PrayerCore
import SwiftUI

/// Die Zeiten-Seite: Stadt und Datum, Bogen mit Countdown, die sechs Gebetskarten und die Hinweise –
/// `homePage()` im Prototyp.
///
/// Die Seite scrollt senkrecht unter der oberen Leiste. Die Pfeile neben dem Datum blättern bis zu ein
/// Jahr vor und zurück (Spec § 9.4). Tippen auf die Stadt oder auf „Ändern“ im Banner öffnet das Stadt-Sheet; „Regel ändern“ im Hinweis zu hohen Breiten führt in die Einstellungen.
/// Den Ort bestimmt der Tab (`PrayersTab`): Er gilt auch für die Qibla-Seite, und dort hängt das
/// Stadt-Sheet.
struct TodayPage: View {
    let model: TodayModel
    /// „Regel ändern“ im Hinweis zu hohen Breiten.
    let onHighLatitudeRule: () -> Void

    @Environment(\.pageArrangement) private var arrangement

    var body: some View {
        PageScroll(centersParts: true, alignment: .center) {
            overview
        } second: {
            details
        }
        .task {
            await model.observeConnectivity()
        }
        .onChange(of: model.settings.calculation) { model.refresh() }
        .onChange(of: model.settings.showKerahat) { model.refresh() }
    }

    /// Stadt, Datum, Banner und Bogen – `.col-a` in `homePage()`; innen die linke Spalte.
    private var overview: some View {
        VStack(spacing: 0) {
            TodayHeader(model: model)

            if model.showsLocationDeniedBanner {
                Banner(L10n.locOffBanner, systemImage: "location.slash", actionTitle: L10n.change) {
                    model.isCitySheetPresented = true
                }
                .padding(.top, TodayMetrics.bannerTop)
                .padding(.horizontal, Layout.inset)
            }

            if model.isShowingOtherDay, let times = model.otherDayTimes {
                // Ein anderer Tag (Spec § 9.4): sein Bogen ohne Fortschritt, statt des Countdowns der Tag.
                DayArc(times: times, showKerahat: model.settings.showKerahat) {
                    ArcDayLabel(
                        relativeDay: model.relativeDayText, date: model.shortDateText,
                        spokenDate: model.gregorianDateText
                    )
                }
                .padding(.top, TodayMetrics.heroTop)
                .padding(.bottom, arrangement.isSplit ? TodayMetrics.heroBottom : 0)
            } else if !model.isShowingOtherDay, let timeline = model.timeline {
                TodayHero(timeline: timeline, clock: model.clock, showKerahat: model.settings.showKerahat) {
                    model.refresh()
                }
                .padding(.top, TodayMetrics.heroTop)
                // In Spalten bleibt der Abstand unter dem Bogen in der linken Spalte (`.hero`:
                // `margin-bottom: 8px`); untereinander fällt er mit dem über den Karten zusammen.
                .padding(.bottom, arrangement.isSplit ? TodayMetrics.heroBottom : 0)
            } else if model.hasNoTimes {
                NoteCard(text: L10n.noTimes)
                    .padding(.top, TodayMetrics.bannerTop)
                    .padding(.horizontal, Layout.inset)
            }
        }
    }

    /// Die Gebetskarten und der Hinweis zu hohen Breiten – `.col-b` in `homePage()`; innen die rechte
    /// Spalte.
    @ViewBuilder
    private var details: some View {
        if !model.rows.isEmpty {
            VStack(spacing: 0) {
                rows
                    .padding(.top, arrangement.isSplit ? TodayMetrics.rowsTopInColumns : TodayMetrics.rowsTop)
                    .padding(.horizontal, Layout.inset)

                if model.isHighLatitude {
                    NoteCard(
                        title: L10n.highLatTitle, text: model.highLatitudeNote,
                        linkTitle: L10n.highLatLink, action: onHighLatitudeRule
                    )
                    .padding(.top, TodayMetrics.noteTop)
                    .padding(.horizontal, Layout.inset)
                }
            }
        }
    }

    /// Die sechs Gebetskarten. Die Liste trägt für VoiceOver das Datum, wie `aria-label` im Prototyp.
    private var rows: some View {
        VStack(spacing: Layout.prayerRowGap) {
            ForEach(model.rows) { row in
                PrayerRow(row, bell: model.bell(for: row.prayer)) {
                    model.cycleBell(for: row.prayer)
                } onKerahatInfo: {
                    model.isKerahatInfoPresented = true
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(model.gregorianDateText)
    }
}

/// Maße der Zeiten-Seite (`.home-head`, `.city-btn`, `.home-date`, `.hero`, `.prayers`, `.note`).
enum TodayMetrics {
    /// Kopf (`.home-head`: `padding: 10px 16px 0`).
    static let headerTop: CGFloat = 10
    /// Stadt-Button (`.city-btn`): `gap: 7px; padding: 2px 10px; border-radius: 12px`, Zeilenhöhe 1,25.
    static let cityGap: CGFloat = 7
    static let cityPaddingX: CGFloat = 10
    static let cityPaddingY: CGFloat = 2
    static let cityRadius: CGFloat = 12
    static let cityLineHeight: CGFloat = 1.25
    /// `location.fill` vor der Stadt – `ic('locFill', 17)`. Als Schriftgröße eines SF Symbols so
    /// gewählt, dass der Pfeil so groß erscheint wie die Zeichnung des Prototyps.
    static let locationSymbolBox: CGFloat = 17
    static let locationSymbolSize: CGFloat = 11
    static let locationSymbolWeight: Font.Weight = .semibold
    /// Marke „manuell“ (`.tag`: `padding: 4px 7px`).
    static let tagPaddingX: CGFloat = 7
    static let tagPaddingY: CGFloat = 4
    /// Datum (`.home-date`: `line-height: 1.38`).
    static let dateLineHeight: CGFloat = 1.38
    /// Zeile mit Datum und Pfeilen (`.day-nav`: `gap: 2px; margin-top: 2px`).
    static let dayNavGap: CGFloat = 2
    static let dayNavTop: CGFloat = 2
    /// Pfeile (`.day-btn`: 28 × 28 pt, `ic('chevronLeft', 16)` in `--label-3`, Tippfläche 8 pt größer).
    static let dayButtonSize: CGFloat = 28
    static let dayButtonHitInset: CGFloat = 8
    static let daySymbolSize: CGFloat = 13
    /// „Zurück zu heute“ (`.day-today`: `margin-top: 2px`, Caption 1 mittelstark, Zeilenhöhe 1,4;
    /// Tippfläche 12 pt höher und 8 pt breiter). Der Knopf steht im Prototyp auf einer Textzeile des Kopfes:
    /// Mit ihr liegt er 5 pt unter dem Datum, und darunter bleiben 0,3 pt – im Browser gemessen, zusammen
    /// 22,1 pt, um die der Bogen tiefer rückt.
    static let todayLinkTop: CGFloat = 5
    static let todayLinkBottom: CGFloat = 0.3
    static let todayLinkLineHeight: CGFloat = 1.4
    static let todayLinkHitInsetY: CGFloat = 12
    static let todayLinkHitInsetX: CGFloat = 8
    /// Hinweis „Offline“ unter dem Datum (`.hint-pill`: `margin: 10px 0 0`).
    static let hintTop: CGFloat = 10

    /// Banner unter dem Kopf (`.banner`: `margin: 14px … 0`).
    static let bannerTop: CGFloat = 14
    /// Bogen (`.hero`: `margin: 10px auto 8px`). Sein unterer Rand fällt mit dem oberen der
    /// Gebetskarten zusammen (`.prayers`: `margin-top: 8px`), es bleiben 8 pt.
    static let heroTop: CGFloat = 10
    static let heroBottom: CGFloat = 8
    static let rowsTop: CGFloat = 8
    /// Innen auf dem iPhone Duo stehen die Karten in der rechten Spalte: deren Innenrand oben
    /// (`.home .col-b`: `padding-top: 6px`) und der Abstand der Karten (`margin-top: 8px`).
    static let rowsTopInColumns: CGFloat = 6 + 8
    /// Hinweis zu hohen Breiten unter den Karten (`.note`: `margin: 12px … 0`).
    static let noteTop: CGFloat = 12
}
