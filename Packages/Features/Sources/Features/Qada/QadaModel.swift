import DesignSystem
import Foundation
import Observation
import PrayerCore

/// Der Zustand der Seite „Nachholen“: der Stand (`QadaLedger`), der heutige Tag für den Plan und die
/// Aktionen `qstep`, `qwitr` und `qapply` des Prototyps.
///
/// Jede Änderung wird sofort gespeichert – als ein JSON-Eintrag in den UserDefaults der App
/// (entschieden am 12.11.2026). Die Zahlen bleiben auf dem Gerät; Widgets brauchen sie nicht, deshalb
/// liegen sie nicht in der App Group.
@MainActor
@Observable
public final class QadaModel {

    /// Wo der Stand liegt.
    public enum Storage: Equatable, Sendable {
        /// In den UserDefaults mit dieser Kennung; ohne Kennung in den Standard-Defaults der App.
        case userDefaults(suiteName: String?)
        /// Nur im Speicher, mit festem Startwert: für `-debugFixtureTimes`, Tests und Previews.
        case ephemeral(QadaLedger)
    }

    /// Der Stand des Nachholens.
    public private(set) var ledger: QadaLedger
    /// Der heutige Tag am Ort; von ihm aus zählt der Plan bis zum voraussichtlichen Ende.
    public private(set) var today: CalendarDay

    @ObservationIgnored private let clock: any AppClock
    @ObservationIgnored private let location: PlaceModel
    @ObservationIgnored private let toast: ToastCenter
    @ObservationIgnored private let locale: Locale
    @ObservationIgnored private let deviceTimeZone: TimeZone
    @ObservationIgnored private let defaults: UserDefaults?

    /// - Parameters:
    ///   - location: der Ort der Zeiten-Seite; seine Zeitzone bestimmt, wann ein neuer Tag beginnt.
    ///   - locale: Sprache für die Zahl im Toast; ohne Angabe die der Texte.
    ///   - deviceTimeZone: Zeitzone, solange es keinen Ort gibt.
    public init(
        storage: Storage,
        clock: any AppClock,
        location: PlaceModel,
        toast: ToastCenter,
        locale: Locale = L10n.locale,
        deviceTimeZone: TimeZone = .current
    ) {
        switch storage {
        case .userDefaults(let suiteName):
            let defaults = suiteName.flatMap { UserDefaults(suiteName: $0) } ?? .standard
            self.defaults = defaults
            ledger = Self.load(from: defaults)
        case .ephemeral(let start):
            defaults = nil
            ledger = start
        }
        self.clock = clock
        self.location = location
        self.toast = toast
        self.locale = locale
        self.deviceTimeZone = deviceTimeZone
        today = CalendarDay(clock.now, in: location.place?.timeZone ?? deviceTimeZone)
    }

    // MARK: - Aktionen

    /// Führt eine Aktion der Seite aus und speichert den neuen Stand. Nach „Als offen übernehmen“ nennt
    /// ein Toast die Zahl der übernommenen Gebete (`qadaApplied`).
    public func perform(_ action: QadaAction) {
        ledger.apply(action)
        save()
        if action == .applyPeriod {
            let count = QadaSummary.number(ledger.periodPrayers, locale: locale)
            toast.show(L10n.qadaApplied(n: count), systemImage: QadaModel.appliedSymbol)
        }
    }

    // MARK: - Ablauf

    /// Liest den heutigen Tag neu.
    public func refresh() {
        today = CalendarDay(clock.now, in: timeZone)
    }

    /// Liest den Tag sofort und dann jedes Mal um Mitternacht am Ort neu – bis die Aufgabe abgebrochen
    /// wird. Mit dem Tag kann sich das voraussichtliche Ende des Plans verschieben.
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

    /// Symbol des Toasts nach „Als offen übernehmen“ (`toast(…, 'check')`).
    nonisolated static let appliedSymbol = "checkmark"

    // MARK: - Lesen und Schreiben

    /// Der Schlüssel in den UserDefaults.
    nonisolated static let key = "qada.ledger"

    private static func load(from defaults: UserDefaults) -> QadaLedger {
        guard let data = defaults.data(forKey: key),
              let ledger = try? JSONDecoder().decode(QadaLedger.self, from: data)
        else { return QadaLedger() }
        return ledger
    }

    private func save() {
        guard let defaults, let data = try? JSONEncoder().encode(ledger) else { return }
        defaults.set(data, forKey: Self.key)
    }
}
