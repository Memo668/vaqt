import DesignSystem
import PrayerCore
import SwiftUI

/// „Was sind Verbotszeiten?“ – die Erklärung hinter dem Infopunkt der Kerahat-Zeilen (Spec § 10.2, § 11.6,
/// `kerahatSheet()` im Prototyp): Einleitung je Rechtsschule, die Fenster von heute mit Uhrzeit, was gilt, wenn
/// Asr noch nicht gebetet ist (nur Hanafi), die Zeiten nach dem Fadschr- und dem Asr-Gebet, das Nachholen, andere
/// Gebete, der überlieferte Grund und die Quelle der Näherungen. Fachlich noch zu prüfen (Ibrahim Gezer).
struct KerahatInfoSheet: View {
    /// Die Zeiten des Tages, dessen Fenster die Gruppe „Heute“ zeigt; `nil` ohne Ort.
    let times: DayTimes?
    /// Die Rechtsschule aus den Einstellungen – auch ohne Ort, wenn die Gruppe „Heute“ fehlt.
    let madhab: Madhab

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section {
                    prose(madhab.kerahatInfoIntro)
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
                    VStack(alignment: .leading, spacing: 0) {
                        // `.k-sheet h3 { margin: 18px 0 6px }`, `.k-sheet p { margin: 0 0 12px }`.
                        ForEach(Array(sections.enumerated()), id: \.offset) { index, section in
                            Text(section.title)
                                .textStyle(.headline, lineHeight: KerahatInfoMetrics.headlineLineHeight)
                                .foregroundStyle(Palette.label)
                                .accessibilityAddTraits(.isHeader)
                                .padding(.top, index == 0 ? KerahatInfoMetrics.firstHeadingTop : KerahatInfoMetrics.headingTop)
                                .padding(.bottom, KerahatInfoMetrics.headingBottom)
                            Text(section.body)
                                .textStyle(.body, lineHeight: KerahatInfoMetrics.bodyLineHeight)
                                .foregroundStyle(Palette.label)
                        }
                        Text(L10n.kerahatInfoP2)
                            .textStyle(.body, lineHeight: KerahatInfoMetrics.bodyLineHeight)
                            .foregroundStyle(Palette.label)
                            .padding(.top, KerahatInfoMetrics.headingTop)
                        Text(madhab.kerahatInfoFootnote)
                            .textStyle(.footnote, lineHeight: KerahatInfoMetrics.footnoteLineHeight)
                            .foregroundStyle(Palette.textSecondary)
                            .padding(.top, KerahatInfoMetrics.paragraphGap)
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

    /// Die Abschnitte mit Überschrift: „Asr noch nicht gebetet?“ nur hanafitisch, dann für alle Schulen nach
    /// dem Fadschr- und dem Asr-Gebet, das Nachholen je Schule und andere Gebete (Spec § 11.6).
    private var sections: [(title: String, body: String)] {
        var sections: [(title: String, body: String)] = []
        if madhab.hasAsrNote {
            sections.append((L10n.kerahatAsrTitle, L10n.kerahatAsrBody))
        }
        sections.append((L10n.kerahatAfterTitle, L10n.kerahatAfterBody))
        sections.append((L10n.kerahatQadaTitle, madhab.kerahatQadaText))
        sections.append((L10n.kerahatOtherTitle, L10n.kerahatOtherBody))
        return sections
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
    /// Über einer Überschrift (`h3 { margin-top: 18px }`; der Absatz davor hat 12, die Ränder fallen zusammen).
    static let headingTop: CGFloat = 18
    /// Über der ersten Überschrift des Abschnitts: Die Gruppe darüber hält schon Abstand.
    static let firstHeadingTop: CGFloat = 0
    /// Unter einer Überschrift (`h3 { margin-bottom: 6px }`).
    static let headingBottom: CGFloat = 6
    /// Punkt der Zeilen, 8 pt (`.k-row .k-dot`).
    static let dotSize: CGFloat = 8
    static let rowGap: CGFloat = 12
    /// Zeilenhöhen (`.k-sheet p`: 1,42; `h3`: 1,3; Fußnote 1,38).
    static let bodyLineHeight: CGFloat = 1.42
    static let headlineLineHeight: CGFloat = 1.3
    static let footnoteLineHeight: CGFloat = 1.38
}
