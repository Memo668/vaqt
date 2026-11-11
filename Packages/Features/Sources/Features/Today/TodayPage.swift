import DesignSystem
import PrayerCore
import SwiftUI

/// Die Zeiten-Seite: Stadt und Datum, Bogen mit Countdown, die sechs Gebetskarten und die Hinweise –
/// `homePage()` im Prototyp.
///
/// Die Seite scrollt senkrecht unter der oberen Leiste. Tippen auf die Stadt oder auf „Ändern“ im
/// Banner öffnet das Stadt-Sheet; „Regel ändern“ im Hinweis zu hohen Breiten führt in die Einstellungen.
struct TodayPage: View {
    let model: TodayModel
    /// „Regel ändern“ im Hinweis zu hohen Breiten.
    let onHighLatitudeRule: () -> Void

    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        @Bindable var model = model
        ScrollView {
            VStack(spacing: 0) {
                TodayHeader(model: model)

                if model.showsLocationDeniedBanner {
                    Banner(L10n.locOffBanner, systemImage: "location.slash", actionTitle: L10n.change) {
                        model.isCitySheetPresented = true
                    }
                    .padding(.top, TodayMetrics.bannerTop)
                    .padding(.horizontal, Layout.inset)
                }

                if let timeline = model.timeline {
                    TodayHero(timeline: timeline, clock: model.clock, showKerahat: model.settings.showKerahat) {
                        model.refresh()
                    }
                    .padding(.top, TodayMetrics.heroTop)

                    rows
                        .padding(.top, TodayMetrics.rowsTop)
                        .padding(.horizontal, Layout.inset)

                    if model.isHighLatitude {
                        NoteCard(
                            title: L10n.highLatTitle, text: model.highLatitudeNote,
                            linkTitle: L10n.highLatLink, action: onHighLatitudeRule
                        )
                        .padding(.top, TodayMetrics.noteTop)
                        .padding(.horizontal, Layout.inset)
                    }
                } else if model.hasNoTimes {
                    NoteCard(text: L10n.noTimes)
                        .padding(.top, TodayMetrics.bannerTop)
                        .padding(.horizontal, Layout.inset)
                }
            }
            .padding(.top, TodayMetrics.contentTop)
            .padding(.bottom, TodayMetrics.contentBottom)
        }
        .background(Palette.backgroundGrouped)
        .task {
            await model.observeConnectivity()
        }
        // Beim ersten Erscheinen und immer, wenn die App wieder nach vorn kommt.
        .task(id: scenePhase) {
            if scenePhase == .active {
                await model.activate()
            }
        }
        .onChange(of: model.settings.calculation) { model.refresh() }
        .onChange(of: model.settings.showKerahat) { model.refresh() }
        .sheet(isPresented: $model.isCitySheetPresented) {
            CitySheet(today: model, search: model.citySearch)
        }
    }

    /// Die sechs Gebetskarten. Die Liste trägt für VoiceOver das Datum, wie `aria-label` im Prototyp.
    private var rows: some View {
        VStack(spacing: Layout.prayerRowGap) {
            ForEach(model.rows) { row in
                PrayerRow(row, bell: model.bell(for: row.prayer)) {
                    model.cycleBell(for: row.prayer)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(model.gregorianDateText)
    }
}

/// Maße der Zeiten-Seite (`.home-head`, `.city-btn`, `.home-date`, `.hero`, `.prayers`, `.note`).
enum TodayMetrics {
    /// Abstand zwischen oberer Leiste und Inhalt (`.root-page .scroll`: 8 pt unter der Leiste).
    static let contentTop: CGFloat = 8
    /// Platz unter dem letzten Element, über der Tableiste: `.tab-spacer` ist 112 pt hoch, davon liegen
    /// 84 pt hinter der Tableiste (22 pt Rand + 62 pt Leiste).
    static let contentBottom: CGFloat = 28

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
    /// Hinweis „Offline“ unter dem Datum (`.hint-pill`: `margin: 10px 0 0`).
    static let hintTop: CGFloat = 10

    /// Banner unter dem Kopf (`.banner`: `margin: 14px … 0`).
    static let bannerTop: CGFloat = 14
    /// Bogen (`.hero`: `margin: 10px auto 8px`). Sein unterer Rand fällt mit dem oberen der
    /// Gebetskarten zusammen (`.prayers`: `margin-top: 8px`), es bleiben 8 pt.
    static let heroTop: CGFloat = 10
    static let rowsTop: CGFloat = 8
    /// Hinweis zu hohen Breiten unter den Karten (`.note`: `margin: 12px … 0`).
    static let noteTop: CGFloat = 12
}
