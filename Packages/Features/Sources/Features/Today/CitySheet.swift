import DesignSystem
import PrayerCore
import SwiftUI

/// Das Stadt-Sheet: aktueller Standort, gespeicherte Städte und die Ortssuche – `citySheet()` im
/// Prototyp, Design Spec § 3 („Sheets“, „Searchable list“).
///
/// Ein Sheet des Systems in voller Höhe mit Greifer, „Abbrechen“ und Suchfeld. Tippen auf eine Zeile
/// wählt den Ort und schließt das Sheet. Gespeicherte Städte lassen sich mit der Wischgeste der Liste
/// entfernen, die gerade gewählte nicht. Ohne Netz stehen nur die gespeicherten Städte da.
struct CitySheet: View {
    @State private var model: CitySheetModel
    @Environment(\.dismiss) private var dismiss

    init(today: TodayModel, search: any CitySearching) {
        _model = State(initialValue: CitySheetModel(today: today, search: search))
    }

    var body: some View {
        @Bindable var model = model
        NavigationStack {
            List {
                if model.showsCurrentLocation {
                    Section {
                        currentLocationRow
                    }
                }
                if model.showsCities {
                    Section {
                        ForEach(model.savedPlaces, id: \.self) { place in
                            savedRow(place)
                                .deleteDisabled(!model.canRemove(place))
                        }
                        .onDelete { offsets in
                            let places = model.savedPlaces
                            offsets.map { places[$0] }.forEach(model.remove)
                        }
                        ForEach(model.visibleSuggestions) { suggestion in
                            suggestionRow(suggestion)
                        }
                        if model.showsNoResults {
                            Text(L10n.noResults)
                                .foregroundStyle(Palette.textSecondary)
                        }
                    } footer: {
                        if let footer = model.footer {
                            Text(footer)
                        }
                    }
                }
            }
            .listSectionSpacing(CitySheetMetrics.sectionSpacing)
            .contentMargins(.top, CitySheetMetrics.listTop, for: .scrollContent)
            // Eine Zeile ohne Zusatz ist 44 pt hoch (`--row-min`), nicht die 52 pt der Liste von iOS 26.
            .environment(\.defaultMinListRowHeight, Layout.minRowHeight)
            .navigationTitle(L10n.citySheetTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.cancel) {
                        dismiss()
                    }
                }
            }
            .searchable(
                text: $model.query, placement: .navigationBarDrawer(displayMode: .always),
                prompt: L10n.searchCity
            )
            .autocorrectionDisabled()
        }
        .tint(Palette.accent)
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .task(id: model.query) {
            await model.runSearch()
        }
    }

    // MARK: - Zeilen

    /// „Aktueller Standort“ mit Häkchen, solange er gilt. Ohne Freigabe ausgegraut, mit dem Zusatz
    /// „Standortzugriff verweigert“.
    private var currentLocationRow: some View {
        Button {
            Task { await model.useCurrentLocation() }
        } label: {
            HStack(spacing: CitySheetMetrics.gap) {
                Image(systemName: model.isLocationDenied ? "location.slash" : "location.fill")
                    .font(.system(size: CitySheetMetrics.symbolSize, weight: CitySheetMetrics.symbolWeight))
                    .foregroundStyle(Palette.accent)
                    .frame(width: CitySheetMetrics.symbolBox)
                    .accessibilityHidden(true)
                label(
                    L10n.currentLocation, detail: model.isLocationDenied ? L10n.locDenied : nil,
                    isDisabled: model.isLocationDenied
                )
                checkmark(isVisible: model.isCurrentLocationSelected)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .disabled(model.isLocationDenied)
        .listRowInsets(CitySheetMetrics.rowInsets)
        .accessibilityAddTraits(model.isCurrentLocationSelected ? .isSelected : [])
    }

    /// Eine gespeicherte Stadt mit ihrem Land; mit Häkchen, wenn sie gerade gilt.
    private func savedRow(_ place: Place) -> some View {
        Button {
            model.choose(place)
        } label: {
            HStack(spacing: CitySheetMetrics.gap) {
                label(place.name, detail: model.countryName(of: place))
                checkmark(isVisible: model.isSelected(place))
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .listRowInsets(CitySheetMetrics.rowInsets)
        .accessibilityAddTraits(model.isSelected(place) ? .isSelected : [])
    }

    /// Ein Vorschlag der Ortssuche. Während sein Ort bestimmt wird, dreht sich ein Fortschrittsrad.
    private func suggestionRow(_ suggestion: CitySuggestion) -> some View {
        Button {
            Task { await model.choose(suggestion) }
        } label: {
            HStack(spacing: CitySheetMetrics.gap) {
                label(suggestion.title, detail: suggestion.subtitle.isEmpty ? nil : suggestion.subtitle)
                if model.resolving == suggestion.id {
                    ProgressView()
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .listRowInsets(CitySheetMetrics.rowInsets)
    }

    /// Titel mit Zusatz darunter (`.row-label` und `.row-sub`), über die Breite der Zeile.
    private func label(_ title: String, detail: String?, isDisabled: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: CitySheetMetrics.detailGap) {
            Text(hyphenating: title)
                .textStyle(.body, lineHeight: CitySheetMetrics.lineHeight)
                .foregroundStyle(isDisabled ? Palette.labelTertiary : Palette.label)
            if let detail {
                Text(hyphenating: detail)
                    .textStyle(.footnote, lineHeight: CitySheetMetrics.lineHeight)
                    .foregroundStyle(Palette.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Das Häkchen der gewählten Zeile; sein Feld bleibt frei, wenn die Zeile nicht gewählt ist.
    private func checkmark(isVisible: Bool) -> some View {
        Image(systemName: "checkmark")
            .font(.system(size: CitySheetMetrics.checkSize, weight: CitySheetMetrics.symbolWeight))
            .foregroundStyle(Palette.accent)
            .frame(width: CitySheetMetrics.checkBox)
            .opacity(isVisible ? 1 : 0)
            .accessibilityHidden(true)
    }
}

/// Maße der Zeilen im Stadt-Sheet (`.row`, `.row-ic`, `.row-sub`, `.check`, `.group-wrap`).
enum CitySheetMetrics {
    /// Innenabstand einer Zeile (`padding: 11px 16px`).
    static let rowInsets = EdgeInsets(top: 11, leading: 16, bottom: 11, trailing: 16)
    /// Abstand zwischen Symbol, Text und Häkchen (`gap: 12px`).
    static let gap: CGFloat = 12
    /// Zeilenhöhe von Titel und Zusatz (`line-height: 1.3`) und ihr Abstand (`.row-sub`: `margin-top: 2px`).
    static let lineHeight: CGFloat = 1.3
    static let detailGap: CGFloat = 2
    /// Feld des Symbols vor „Aktueller Standort“ (`.row-ic`: 24 pt, `ic(…, 18)`). Als Schriftgröße
    /// eines SF Symbols so gewählt, dass der Pfeil so breit erscheint wie die Zeichnung des Prototyps
    /// (rund 13 pt).
    static let symbolBox: CGFloat = 24
    static let symbolSize: CGFloat = 12.5
    static let symbolWeight: Font.Weight = .semibold
    /// Feld des Häkchens (`.check`: 20 pt, `ic('check', 18)`); die Zeichnung ist rund 12 pt breit.
    static let checkBox: CGFloat = 20
    static let checkSize: CGFloat = 12.5
    /// Abstand zwischen den Gruppen (`.group-wrap`: `margin-bottom: 32px`).
    static let sectionSpacing: CGFloat = 32
    /// Abstand zwischen der Leiste des Sheets und der ersten Gruppe. Die Leiste endet 10 pt unter dem
    /// Suchfeld; zusammen sind es die 18 pt des Prototyps (`.searchbar`: `margin-bottom: 18px`).
    static let listTop: CGFloat = 8
}
