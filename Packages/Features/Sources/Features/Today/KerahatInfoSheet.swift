import DesignSystem
import PrayerCore
import SwiftUI

/// „Was sind Verbotszeiten?“ – die Erklärung hinter dem Infopunkt der Kerahat-Zeilen (Spec § 10.2,
/// `kerahatSheet()` im Prototyp): Einleitung, die drei Fenster von heute mit Uhrzeit, was gilt, wenn Asr noch
/// nicht gebetet ist, der überlieferte Grund und die Quelle der Näherungen. Fachlich noch zu prüfen.
struct KerahatInfoSheet: View {
    /// Die Zeiten des Tages, dessen Fenster die Gruppe „Heute“ zeigt; `nil` ohne Ort.
    let times: DayTimes?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    prose(L10n.kerahatInfoP1)
                }
                if let times {
                    Section {
                        ForEach(Kerahat.windows(for: times), id: \.id) { window in
                            row(window, in: times)
                                .listRowMetrics()
                        }
                    } header: {
                        ListSectionHeader(L10n.kerahatToday)
                    }
                }
                Section {
                    VStack(alignment: .leading, spacing: KerahatInfoMetrics.paragraphGap) {
                        Text(L10n.kerahatAsrTitle)
                            .textStyle(.headline, lineHeight: KerahatInfoMetrics.headlineLineHeight)
                            .foregroundStyle(Palette.label)
                            .accessibilityAddTraits(.isHeader)
                        Text(L10n.kerahatAsrBody)
                            .textStyle(.body, lineHeight: KerahatInfoMetrics.bodyLineHeight)
                            .foregroundStyle(Palette.label)
                        Text(L10n.kerahatInfoP2)
                            .textStyle(.body, lineHeight: KerahatInfoMetrics.bodyLineHeight)
                            .foregroundStyle(Palette.label)
                        Text(L10n.kerahatInfoFoot)
                            .textStyle(.footnote, lineHeight: KerahatInfoMetrics.footnoteLineHeight)
                            .foregroundStyle(Palette.textSecondary)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .listRowInsets(KerahatInfoMetrics.proseInsets)
                    .listRowBackground(Color.clear)
                }
            }
            .groupedListMetrics()
            .navigationTitle(L10n.kerahatInfoTitle)
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

    private func prose(_ text: String) -> some View {
        Text(text)
            .textStyle(.body, lineHeight: KerahatInfoMetrics.bodyLineHeight)
            .foregroundStyle(Palette.label)
            .fixedSize(horizontal: false, vertical: true)
            .listRowInsets(KerahatInfoMetrics.proseInsets)
            .listRowBackground(Color.clear)
    }

    /// Eine Zeile der Gruppe „Heute“: Punkt in Kerahat-Farbe, was das Fenster ist, die Spanne in einer Zeile.
    private func row(_ window: KerahatWindow, in times: DayTimes) -> some View {
        HStack(spacing: KerahatInfoMetrics.rowGap) {
            Circle()
                .fill(Palette.kerahat)
                .frame(width: KerahatInfoMetrics.dotSize, height: KerahatInfoMetrics.dotSize)
                .accessibilityHidden(true)
            Text(description(window.id))
                .textStyle(.body, lineHeight: KerahatInfoMetrics.bodyLineHeight)
                .foregroundStyle(Palette.label)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(L10n.timeRange(ClockTime(window.start, in: times.timeZone), ClockTime(window.end, in: times.timeZone)))
                .textStyle(.body, lineHeight: KerahatInfoMetrics.bodyLineHeight)
                .monospacedDigit()
                .foregroundStyle(Palette.textSecondary)
                .lineLimit(1)
                .fixedSize()
        }
        .accessibilityElement(children: .combine)
    }

    private func description(_ kind: KerahatWindow.Kind) -> String {
        switch kind {
        case .sunrise: L10n.kerahatInfoL1
        case .zenith: L10n.kerahatInfoL2
        case .sunset: L10n.kerahatInfoL3
        }
    }
}

/// Maße des Sheets (`.k-sheet`, `.k-row` im Prototyp).
enum KerahatInfoMetrics {
    /// Fließtext ohne Karte, 20 pt seitlich (`.k-sheet { padding: 4px 20px 0 }`).
    static let proseInsets = EdgeInsets(top: 4, leading: 20, bottom: 8, trailing: 20)
    /// Abstand der Absätze (`margin-bottom: 12px`).
    static let paragraphGap: CGFloat = 12
    /// Punkt der Zeilen, 8 pt (`.k-row .k-dot`).
    static let dotSize: CGFloat = 8
    static let rowGap: CGFloat = 12
    /// Zeilenhöhen (`.k-sheet p`: 1,42; `h3`: 1,3; Fußnote 1,38).
    static let bodyLineHeight: CGFloat = 1.42
    static let headlineLineHeight: CGFloat = 1.3
    static let footnoteLineHeight: CGFloat = 1.38
}
