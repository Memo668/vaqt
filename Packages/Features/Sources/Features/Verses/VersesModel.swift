import DesignSystem
import Foundation
import Observation
import PrayerCore
import UIKit

/// Der Zustand der Seite „Verse“: welcher Tag heute ist und welcher Vers oben steht – `S.verseIdx` und
/// die Aktionen `verse-pick` und `verse-copy` im Prototyp.
///
/// Der Vers des Tages wechselt um Mitternacht am Ort, wie das Datum auf der Zeiten-Seite; ohne Ort um
/// Mitternacht in der Zeitzone des Geräts. Ein angetippter Eintrag der Liste bleibt oben, bis ein anderer
/// angetippt wird oder sein Tag aus der Liste fällt.
@MainActor
@Observable
public final class VersesModel {

    @ObservationIgnored private let clock: any AppClock
    @ObservationIgnored private let location: PlaceModel
    @ObservationIgnored private let toast: ToastCenter
    @ObservationIgnored private let locale: Locale
    @ObservationIgnored private let deviceTimeZone: TimeZone
    @ObservationIgnored private let copyToPasteboard: @MainActor (String) -> Void

    /// Der heutige Tag am Ort.
    public private(set) var today: CalendarDay
    /// Der Tag, dessen Vers die Karte zeigt, wenn ein Eintrag der Liste angetippt wurde; sonst `nil`.
    public private(set) var pickedDay: CalendarDay?

    /// - Parameters:
    ///   - location: der Ort der Zeiten-Seite; seine Zeitzone bestimmt, wann ein neuer Tag beginnt.
    ///   - locale: Sprache für Wochentag und Datum; ohne Angabe die der Texte.
    ///   - deviceTimeZone: Zeitzone, solange es keinen Ort gibt.
    ///   - copyToPasteboard: legt Text in die Zwischenablage; ohne Angabe die des Systems.
    public init(
        clock: any AppClock,
        location: PlaceModel,
        toast: ToastCenter,
        locale: Locale = L10n.locale,
        deviceTimeZone: TimeZone = .current,
        copyToPasteboard: @escaping @MainActor (String) -> Void = { UIPasteboard.general.string = $0 }
    ) {
        self.clock = clock
        self.location = location
        self.toast = toast
        self.locale = locale
        self.deviceTimeZone = deviceTimeZone
        self.copyToPasteboard = copyToPasteboard
        today = CalendarDay(clock.now, in: location.place?.timeZone ?? deviceTimeZone)
    }

    /// Der Tag, dessen Vers die Karte zeigt.
    public var shownDay: CalendarDay {
        pickedDay ?? today
    }

    /// Die Karte: der Vers des angetippten Tages, sonst der Vers des Tages.
    public var shown: VerseDay {
        VerseDay(shownDay, today: today, locale: locale)
    }

    /// Die Liste „Letzte Tage“: heute und die fünf Tage davor.
    public var recent: [VerseDay] {
        VerseDay.recent(endingAt: today, locale: locale)
    }

    // MARK: - Aktionen

    /// Einen Eintrag der Liste antippen (`verse-pick`): Sein Vers steht dann oben.
    public func select(_ day: CalendarDay) {
        pickedDay = day == today ? nil : day
    }

    /// „Kopieren“: Arabisch, Übersetzung und Quelle in die Zwischenablage, dazu der Toast „Kopiert“
    /// (`verse-copy`).
    public func copyShownVerse() {
        copyToPasteboard(shown.verse.shareText)
        toast.show(L10n.copied, systemImage: VersesModel.copySymbol)
    }

    // MARK: - Ablauf

    /// Liest den heutigen Tag neu. Fällt der angetippte Tag aus der Liste, steht wieder der Vers des Tages
    /// oben.
    public func refresh() {
        today = CalendarDay(clock.now, in: timeZone)
        if let pickedDay, pickedDay == today || !Verse.recentDays(endingAt: today).contains(pickedDay) {
            self.pickedDay = nil
        }
    }

    /// Liest den Tag sofort und dann jedes Mal um Mitternacht am Ort neu – bis die Aufgabe abgebrochen
    /// wird.
    public func run() async {
        while !Task.isCancelled {
            refresh()
            let midnight = today.adding(days: 1).date(at: .midnight, in: timeZone)
            let wait = max(midnight.timeIntervalSince(clock.now), 0) + VersesModel.wakeDelay
            try? await Task.sleep(for: .seconds(wait))
        }
    }

    /// Die Zeitzone des Ortes, ohne Ort die des Geräts. Wechselt der Ort in eine andere Zeitzone,
    /// startet die Seite `run()` neu.
    public var timeZone: TimeZone {
        location.place?.timeZone ?? deviceTimeZone
    }

    /// So lange nach Mitternacht wacht `run()` auf – knapp danach, damit der neue Tag sicher begonnen hat.
    nonisolated static let wakeDelay: TimeInterval = 0.5

    /// Symbol des Toasts „Kopiert“ – das Symbol des Knopfs (`toast(t('copied'), 'copy')`).
    nonisolated static let copySymbol = "doc.on.doc"
}
