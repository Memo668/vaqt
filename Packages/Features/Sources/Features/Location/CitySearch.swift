import Foundation
import MapKit
import PrayerCore

/// Ein Vorschlag der Ortssuche, wie er im Stadt-Sheet steht.
public struct CitySuggestion: Identifiable, Hashable, Sendable {
    public let id: String
    /// Name der Stadt, z. B. „München“.
    public let title: String
    /// Region und Land, z. B. „Bayern, Deutschland“.
    public let subtitle: String

    public init(id: String, title: String, subtitle: String) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
    }

    /// Der Name der Stadt ohne Zusätze: Der Dienst schreibt manche Titel als „Hamburg, PA“ oder
    /// „Istanbul, Istanbul, Türkiye“.
    public var cityName: String {
        let first = title.split(separator: ",", maxSplits: 1).first.map(String.init) ?? title
        return first.trimmingCharacters(in: .whitespaces)
    }
}

/// Die Ortssuche des Stadt-Sheets.
///
/// Sie braucht das Netz, läuft aber nur über Apple-Dienste (MapKit). Ohne Netz bietet das Sheet nur die
/// gespeicherten Städte an (Design Spec § 5, „Offline“). Views sprechen nie direkt mit MapKit.
public protocol CitySearching: Sendable {

    /// Vorschläge zum Suchtext. Die Folge liefert jede Aktualisierung und endet, sobald eine neue Suche
    /// beginnt oder die Suche keine Antwort bekommt.
    ///
    /// - Parameter center: der Ort, in dessen Umgebung Treffer zuerst stehen sollen – der, für den die
    ///   App gerade Zeiten zeigt. Ohne Angabe ordnet der Dienst ohne Ortsbezug.
    func suggestions(for query: String, near center: Coordinates?) async -> AsyncStream<[CitySuggestion]>

    /// Der Ort zu einem Vorschlag, mit Koordinaten, Land und Zeitzone; `nil`, wenn er sich nicht
    /// bestimmen lässt.
    func place(for suggestion: CitySuggestion) async -> Place?
}

/// Eine Suche ohne Vorschläge – für `-debugFixtureTimes`, Tests und Previews. Das Sheet zeigt dann nur
/// die gespeicherten Städte, gefiltert nach dem Suchtext, wie der Prototyp.
public struct NoCitySearch: CitySearching {

    public init() {}

    public func suggestions(for query: String, near center: Coordinates?) async -> AsyncStream<[CitySuggestion]> {
        AsyncStream { $0.finish() }
    }

    public func place(for suggestion: CitySuggestion) async -> Place? { nil }
}

/// Die Ortssuche mit `MKLocalSearchCompleter`, beschränkt auf Städte und Verwaltungsgebiete.
///
/// Verwaltungsgebiete gehören dazu, weil der Dienst Stadtstaaten wie Berlin, Hamburg und Wien nur als
/// solche führt; mit „nur Städte“ fehlen sie. Dadurch erscheinen auch Flächenländer wie Bayern als
/// Vorschlag (docs/OPEN-QUESTIONS.md).
@MainActor
public final class MapKitCitySearch: NSObject, CitySearching {
    private var completer: MKLocalSearchCompleter?
    /// Die Treffer der laufenden Suche, um einen Vorschlag später aufzulösen.
    private var completions: [String: MKLocalSearchCompletion] = [:]
    private var continuation: AsyncStream<[CitySuggestion]>.Continuation?
    private var center: Coordinates?

    /// Kantenlänge der Umgebung, in der Treffer zuerst stehen: rund 1000 km.
    private static let regionSpan: CLLocationDistance = 1_000_000

    public nonisolated override init() {
        super.init()
    }

    public func suggestions(for query: String, near center: Coordinates?) async -> AsyncStream<[CitySuggestion]> {
        // Eine neue Suche löst die vorige ab.
        continuation?.finish()
        let (stream, continuation) = AsyncStream.makeStream(of: [CitySuggestion].self)
        self.continuation = continuation

        let completer = self.completer ?? makeCompleter()
        if let center, center != self.center {
            // Treffer in der Umgebung zuerst; weiter entfernte bleiben möglich (`regionPriority`).
            self.center = center
            completer.region = MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: center.latitude, longitude: center.longitude),
                latitudinalMeters: Self.regionSpan, longitudinalMeters: Self.regionSpan
            )
        }
        if completer.queryFragment == query {
            // Derselbe Text noch einmal: Der Completer meldet sich dann nicht von selbst.
            continuation.yield(suggestions(from: completer.results))
        } else {
            completer.queryFragment = query
        }
        return stream
    }

    public func place(for suggestion: CitySuggestion) async -> Place? {
        guard let completion = completions[suggestion.id] else { return nil }
        let request = MKLocalSearch.Request(completion: completion)
        request.resultTypes = .address
        guard let response = try? await MKLocalSearch(request: request).start(),
              let item = response.mapItems.first
        else { return nil }
        return Place(mapItem: item, fallbackName: suggestion.cityName)
    }

    private func makeCompleter() -> MKLocalSearchCompleter {
        let completer = MKLocalSearchCompleter()
        completer.resultTypes = .address
        completer.addressFilter = MKAddressFilter(including: [.locality, .administrativeArea])
        completer.regionPriority = .default
        completer.delegate = self
        self.completer = completer
        return completer
    }

    private func suggestions(from results: [MKLocalSearchCompletion]) -> [CitySuggestion] {
        completions = [:]
        return results.enumerated().map { index, completion in
            let id = "\(index)|\(completion.title)|\(completion.subtitle)"
            completions[id] = completion
            return CitySuggestion(id: id, title: completion.title, subtitle: completion.subtitle)
        }
    }
}

// Der Completer ruft auf dem Hauptthread zurück, auf dem er angelegt wurde.
extension MapKitCitySearch: @preconcurrency MKLocalSearchCompleterDelegate {

    public func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        continuation?.yield(suggestions(from: completer.results))
    }

    public func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: any Error) {
        // Kein Netz oder keine Antwort: keine Vorschläge. Die gespeicherten Städte bleiben wählbar.
        continuation?.yield([])
        continuation?.finish()
        continuation = nil
    }
}

extension Place {

    /// Der Ort zu einem Treffer von MapKit. Ohne Zeitzone lässt sich für ihn nicht rechnen.
    ///
    /// Der Name ist der der Stadt aus der Adresse, in der Sprache der App.
    ///
    /// - Parameter fallbackName: Name, falls die Adresse keine Stadt nennt – etwa bei einem
    ///   Verwaltungsgebiet.
    init?(mapItem: MKMapItem, fallbackName: String? = nil) {
        guard let timeZone = mapItem.timeZone else { return nil }
        let address = mapItem.addressRepresentations
        let coordinate = mapItem.location.coordinate
        self.init(
            name: address?.cityName ?? fallbackName ?? mapItem.name ?? "",
            countryCode: address?.region?.identifier,
            coordinates: Coordinates(latitude: coordinate.latitude, longitude: coordinate.longitude),
            timeZoneIdentifier: timeZone.identifier
        )
    }
}
