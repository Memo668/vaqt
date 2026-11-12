import DesignSystem
import PrayerCore
import SwiftUI

/// Das Adhan-Sheet: Player, Stimmen, Fadschr-Variante – `adhanSheet()` im Prototyp. Ein Sheet des Systems
/// in voller Höhe mit Greifer und Schließen-Knopf; geöffnet über „Adhan anhören“ in den Einstellungen.
struct AdhanSheet: View {
    let model: AdhanPlayerModel

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    AdhanPlayerCard(
                        title: model.title, subtitle: model.subtitle, position: model.position,
                        duration: model.duration, isPlaying: model.isPlaying,
                        onSeek: model.seek(to:), onToggle: model.togglePlay
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                }
                .listSectionSpacing(AdhanPlayerMetrics.marginBottom)
                Section {
                    ForEach(AdhanVoice.allCases, id: \.self) { voice in
                        CheckRow(L10n.voiceN(n: String(voice.number)), detail: voice.place, isSelected: model.voice == voice) {
                            model.selectVoice(voice)
                        }
                        .listRowMetrics()
                    }
                } header: {
                    ListSectionHeader(L10n.voice)
                } footer: {
                    ListSectionFooter(L10n.voiceFooter)
                }
                Section {
                    ListSwitchRow(L10n.fajrVariant, isOn: Binding(get: { model.isFajrVariant }, set: model.setFajrVariant))
                        .listRowMetrics()
                } footer: {
                    ListSectionFooter(L10n.fajrVariantFooter)
                }
            }
            .groupedListMetrics()
            .contentMargins(.top, AdhanSheetMetrics.contentTop, for: .scrollContent)
            .navigationTitle(L10n.adhan)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(role: .close) {
                        dismiss()
                    } label: {
                        Label(L10n.close, systemImage: "xmark")
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

/// Maße des Sheets (`.sheet-scroll`: `padding-top: 8px`, `.player`: `margin-top: 4px`).
enum AdhanSheetMetrics {
    /// Abstand zwischen der Leiste des Sheets und der Karte: 8 + 4 pt.
    static let contentTop: CGFloat = 8 + AdhanPlayerMetrics.marginTop
}
