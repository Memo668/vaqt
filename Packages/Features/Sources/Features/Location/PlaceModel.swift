import DesignSystem
import Foundation
import Observation
import PrayerCore

/// Welcher Ort gilt: der aktuelle Standort oder die von Hand gewählte Stadt – `cityId()` und `auto` im
/// Prototyp.
///
/// Zeiten-Seite und Qibla-Seite zeigen denselben Ort und fragen deshalb dasselbe Modell. Es liest die
/// Standortfreigabe, bestimmt den aktuellen Standort und merkt ihn in den Einstellungen; die Wahl
/// zwischen Standort und Stadt steht dort (`SettingsStore`).
@MainActor
@Observable
public final class PlaceModel {

    public let settings: SettingsStore

    @ObservationIgnored private let locationSource: any LocationSource
    @ObservationIgnored private var isActivating = false

    /// Stand der Standortfreigabe, zuletzt gelesen in `activate()`.
    public private(set) var authorization: LocationAuthorization = .notDetermined

    public init(settings: SettingsStore, locationSource: any LocationSource) {
        self.settings = settings
        self.locationSource = locationSource
    }

    // MARK: - Ort

    /// Ob der aktuelle Standort gilt – `auto` im Prototyp (`S.autoLocation && !S.locDenied`). Ohne
    /// Freigabe gilt die von Hand gewählte Stadt, auch wenn die Automatik eingeschaltet ist.
    public var isAutomatic: Bool {
        settings.autoLocation && authorization != .denied
    }

    /// Der Ort, der gilt: der aktuelle Standort oder die gewählte Stadt. `nil`, solange der Standort
    /// noch nicht bestimmt ist oder weder Freigabe noch Stadt da sind.
    public var place: Place? {
        isAutomatic ? settings.devicePlace : settings.manualPlace
    }

    /// Ob eine Stadt gelten müsste, aber keine gewählt ist – etwa nach „Nicht erlauben“, bevor das
    /// Stadt-Sheet eine Wahl bekommen hat. Der Standort kommt dann nicht mehr von selbst.
    public var needsCity: Bool {
        !isAutomatic && settings.manualPlace == nil
    }

    /// Der Ort, in dessen Umgebung die Ortssuche zuerst sucht: der, der gilt, sonst der zuletzt
    /// bestimmte Standort.
    public var searchCenter: Coordinates? {
        (place ?? settings.devicePlace ?? settings.manualPlace)?.coordinates
    }

    /// Der Name des Ortes. Solange der Name des aktuellen Standorts fehlt – noch nicht bestimmt oder
    /// ohne Netz –, steht dort „Aktueller Standort“; gibt es weder Freigabe noch Stadt, „Stadt wählen“.
    public var cityTitle: String {
        if let place, place.hasName {
            return place.name
        }
        return isAutomatic ? L10n.currentLocation : L10n.citySheetTitle
    }

    // MARK: - Ablauf

    /// Liest die Freigabe und bestimmt – wenn der aktuelle Standort gelten soll – den Ort neu. Ist noch
    /// nicht gefragt worden, fragt das Modell hier nach dem Standort.
    ///
    /// - Parameter onChange: wird nach jedem Schritt gerufen, der den Ort ändern kann: Freigabe gelesen,
    ///   Abfrage beantwortet, neuer Standort da. So zeigt die Seite mit dem bekannten Ort sofort etwas
    ///   und rechnet neu, sobald sich etwas tut.
    /// - Returns: `false`, wenn schon ein Durchlauf läuft; dann ist nichts geschehen.
    @discardableResult
    public func activate(onChange: () -> Void = {}) async -> Bool {
        guard !isActivating else { return false }
        isActivating = true
        defer { isActivating = false }

        authorization = await locationSource.authorization()
        onChange()
        guard settings.autoLocation else { return true }

        if authorization == .notDetermined {
            authorization = await locationSource.requestAuthorization()
            onChange()
        }
        if authorization == .authorized, await updateDevicePlace() {
            onChange()
        }
        return true
    }

    /// Liest nur die Freigabe – ohne zu fragen und ohne neuen Standort. Für die Hintergrundaktualisierung:
    /// Dort gilt der zuletzt bestimmte Standort oder die gewählte Stadt.
    public func readAuthorization() async {
        authorization = await locationSource.authorization()
    }

    /// Fragt nach dem Standort, falls noch nicht gefragt wurde – „Standort erlauben“ im Onboarding
    /// (`ob-loc`). Ist er schon erlaubt oder verweigert, kommt kein Dialog (iOS fragt nur einmal).
    ///
    /// - Returns: der Stand der Freigabe danach.
    @discardableResult
    public func requestAuthorization() async -> LocationAuthorization {
        authorization = await locationSource.authorization()
        if authorization == .notDetermined {
            authorization = await locationSource.requestAuthorization()
        }
        return authorization
    }

    /// Bestimmt den aktuellen Standort neu und merkt ihn sich.
    ///
    /// - Returns: ob ein Standort gekommen ist.
    @discardableResult
    public func updateDevicePlace() async -> Bool {
        guard let fresh = await locationSource.currentPlace() else { return false }
        // Ohne Netz kommt der Standort ohne Namen: Liegt er beim zuletzt bestimmten Ort, gilt der weiter.
        settings.setDevicePlace(fresh.named(after: settings.devicePlace))
        return true
    }
}
