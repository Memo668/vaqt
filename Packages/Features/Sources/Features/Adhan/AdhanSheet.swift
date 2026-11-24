import DesignSystem
import SwiftUI

/// Das Adhan-Sheet: der Player mit der einen Aufnahme der App, darunter, wer sie aufgenommen hat und unter
/// welcher Lizenz – `adhanSheet()` im Prototyp (Spec § 11.2). Ein Sheet des Systems in voller Höhe mit
/// Greifer und Schließen-Knopf; geöffnet über „Adhan anhören“ in den Einstellungen.
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
                } footer: {
                    CardFootnote(L10n.voiceFooter)
                        .listRowInsets(AdhanSheetMetrics.footnoteInsets)
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

/// Maße des Sheets (`.sheet-scroll`: `padding-top: 8px`, `.player`: `margin: 4px 16px 10px`).
enum AdhanSheetMetrics {
    /// Abstand zwischen der Leiste des Sheets und der Karte: 8 + 4 pt.
    static let contentTop: CGFloat = 8 + AdhanPlayerMetrics.marginTop
    /// Die Fußnote steht 10 pt unter der Karte; ihren Einzug von 16 pt bringt sie mit (`.card-foot`), sonst
    /// keine Abstände der Liste.
    static let footnoteInsets = EdgeInsets(top: AdhanPlayerMetrics.marginBottom, leading: 0, bottom: 0, trailing: 0)
}
