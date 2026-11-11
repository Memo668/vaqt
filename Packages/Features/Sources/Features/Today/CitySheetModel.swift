import DesignSystem
import Foundation
import Observation
import PrayerCore

/// Der Zustand des Stadt-Sheets: Suchtext, gespeicherte Städte und Vorschläge der Ortssuche –
/// der Rechenteil von `citySheet()` im Prototyp.
///
/// Der Suchtext filtert die gespeicherten Städte. Mit Netz kommen darunter die Vorschläge der
/// Ortssuche; ohne Netz bleiben nur die gespeicherten Städte (Design Spec § 5, „Offline“).
@MainActor
@Observable
final class CitySheetModel {

    /// Der Text im Suchfeld.
    var query = ""
    /// Die Vorschläge der Ortssuche zum Suchtext.
    private(set) var suggestions: [CitySuggestion] = []
    /// Ob die Suche noch auf eine erste Antwort wartet. So lange steht „Keine Ergebnisse“ nicht da.
    private(set) var isSearching = false
    /// Der Vorschlag, dessen Ort gerade bestimmt wird.
    private(set) var resolving: CitySuggestion.ID?

    @ObservationIgnored private let today: TodayModel
    @ObservationIgnored private let search: any CitySearching
    @ObservationIgnored private let locale: Locale
    @ObservationIgnored private let debounce: Duration

    /// - Parameters:
    ///   - locale: Sprache der Ländernamen; ohne Angabe die der Texte.
    ///   - debounce: Pause nach dem letzten Tastendruck, bevor die Ortssuche fragt.
    init(
        today: TodayModel, search: any CitySearching,
        locale: Locale = L10n.locale, debounce: Duration = .milliseconds(250)
    ) {
        self.today = today
        self.search = search
        self.locale = locale
        self.debounce = debounce
    }

    // MARK: - Aktueller Standort

    /// Die Zeile „Aktueller Standort“ steht nur ohne Suchtext da (`data-hide-on-filter`).
    var showsCurrentLocation: Bool {
        !isFiltering
    }

    var isCurrentLocationSelected: Bool {
        today.isAutomatic
    }

    /// Ohne Freigabe lässt sich die Zeile nicht wählen und trägt den Zusatz „Standortzugriff verweigert“.
    var isLocationDenied: Bool {
        today.authorization == .denied
    }

    // MARK: - Städte

    /// Die gespeicherten Städte, gefiltert nach dem Suchtext: Er muss im Namen oder im Land vorkommen,
    /// Groß- und Kleinschreibung und Akzente spielen keine Rolle.
    var savedPlaces: [Place] {
        let places = today.settings.savedPlaces
        guard isFiltering else { return places }
        return places.filter { place in
            place.name.localizedStandardContains(trimmedQuery)
                || (countryName(of: place)?.localizedStandardContains(trimmedQuery) ?? false)
        }
    }

    /// Die Vorschläge der Ortssuche, ohne die Städte, die schon als gespeicherte darüber stehen.
    var visibleSuggestions: [CitySuggestion] {
        guard isFiltering, !today.isOffline else { return [] }
        let saved = savedPlaces
        return suggestions.filter { suggestion in
            !saved.contains { place in isSuggestion(suggestion, sameAs: place) }
        }
    }

    /// Ob ein Vorschlag dieselbe Stadt meint wie eine gespeicherte: gleicher Name, und das Land der
    /// gespeicherten Stadt kommt im Vorschlag vor.
    private func isSuggestion(_ suggestion: CitySuggestion, sameAs place: Place) -> Bool {
        guard suggestion.cityName.compare(place.name, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        else { return false }
        guard let country = countryName(of: place) else { return true }
        return suggestion.title.localizedStandardContains(country) || suggestion.subtitle.localizedStandardContains(country)
    }

    /// „Keine Ergebnisse“: Es gibt einen Suchtext, aber weder eine gespeicherte Stadt noch einen
    /// Vorschlag dazu.
    var showsNoResults: Bool {
        isFiltering && savedPlaces.isEmpty && visibleSuggestions.isEmpty && !isSearching
    }

    /// Ob die Gruppe der Städte überhaupt etwas zeigt.
    var showsCities: Bool {
        !savedPlaces.isEmpty || !visibleSuggestions.isEmpty || showsNoResults || footer != nil
    }

    /// Der Hinweis unter der Liste: ohne Netz „Offline: nur gespeicherte Städte“.
    var footer: String? {
        today.isOffline ? L10n.offlineCities : nil
    }

    /// Das Land einer Stadt in der Sprache der App, z. B. „Deutschland“ (`countryName()`).
    func countryName(of place: Place) -> String? {
        place.countryCode.flatMap { locale.localizedString(forRegionCode: $0) }
    }

    /// Ob die Stadt gerade gilt: nur bei gewählter Stadt, nicht beim aktuellen Standort.
    func isSelected(_ place: Place) -> Bool {
        guard !today.isAutomatic, let chosen = today.settings.manualPlace else { return false }
        return SettingsStore.isSameCity(chosen, place)
    }

    /// Ob sich die Stadt aus der Liste entfernen lässt: jede außer der, die gerade gilt.
    func canRemove(_ place: Place) -> Bool {
        !isSelected(place)
    }

    // MARK: - Aktionen

    /// Fragt die Ortssuche zum aktuellen Suchtext. Die Ansicht ruft das bei jeder Änderung des Textes
    /// neu; die vorige Suche bricht dann ab.
    func runSearch() async {
        suggestions = []
        guard isFiltering, !today.isOffline else {
            isSearching = false
            return
        }
        isSearching = true
        defer { isSearching = false }
        do {
            try await Task.sleep(for: debounce)
        } catch {
            return
        }
        for await update in await search.suggestions(for: trimmedQuery, near: today.searchCenter) {
            guard !Task.isCancelled else { return }
            suggestions = update
            isSearching = false
        }
    }

    /// Eine gespeicherte Stadt wählen.
    func choose(_ place: Place) {
        today.select(place)
    }

    /// Einen Vorschlag der Ortssuche wählen: Ort bestimmen, dann gilt und bleibt er gespeichert. Lässt er
    /// sich nicht bestimmen, bleibt das Sheet offen.
    func choose(_ suggestion: CitySuggestion) async {
        guard resolving == nil else { return }
        resolving = suggestion.id
        defer { resolving = nil }
        guard let place = await search.place(for: suggestion) else { return }
        today.select(place)
    }

    /// „Aktueller Standort“.
    func useCurrentLocation() async {
        await today.useCurrentLocation()
    }

    /// Eine gespeicherte Stadt aus der Liste entfernen. Die Stadt, die gerade gilt, bleibt.
    func remove(_ place: Place) {
        guard canRemove(place) else { return }
        today.settings.removeSavedPlace(place)
    }

    private var trimmedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var isFiltering: Bool {
        !trimmedQuery.isEmpty
    }
}
