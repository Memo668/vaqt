import DesignSystem
import PrayerCore
import SwiftUI

/// Die Qibla-Seite: Ort, Kursanzeige, Kompass, Statuszeile, Richtung und Entfernung zur Kaaba und –
/// nur bei ungenauem Kompass – die Karte „Kompass kalibrieren“. `qiblaPage()` im Prototyp.
///
/// Der Kompass läuft nur, solange die Seite zu sehen ist: gewählt im Pager, die App im Vordergrund.
/// Zeigt das Gerät zur Qibla, werden Statuszeile und Peilmarke Akzent, es gibt eine Haptik, und
/// VoiceOver sagt es an. Das Drehen mit dem Finger ist Werkzeug des Prototyps und fehlt hier.
struct QiblaPage: View {
    let model: QiblaModel
    /// Ob die Seite im Pager gewählt ist.
    let isSelected: Bool
    /// „Stadt wählen“, solange kein Ort gilt.
    let onChooseCity: () -> Void

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.pageArrangement) private var arrangement
    @ScaledMetric(relativeTo: .body) private var typeScale: CGFloat = 1

    var body: some View {
        let inColumns = arrangement.isColumns
        // Untereinander mit dem Seitenrand (`.qibla`: `padding: 0 var(--inset)`); in Spalten ohne
        // (`padding: 0`), die rechte Spalte hält dann 28 pt.
        let inset = inColumns ? 0 : Layout.inset
        // Innen auf dem iPhone Duo: Titel, Kurs, Kompass und Status links, Richtung, Entfernung und die
        // Kalibrierungskarte rechts, beide senkrecht mittig (`.qibla .cols`). In der Tischhaltung stehen sie
        // untereinander: Der Kompass passt nicht über den Falz, und in der stehenden Hälfte zeigt er nicht.
        PageScroll(
            centersParts: true, splitsInTablePose: false, alignment: .center,
            secondPadding: QiblaMetrics.infoColumnPadding
        ) {
            VStack(spacing: 0) {
                Text(model.title)
                    .textStyle(.subheadline, lineHeight: QiblaMetrics.titleLineHeight)
                    .tracking(QiblaMetrics.titleTracking)
                    .textCase(.uppercase)
                    .foregroundStyle(Palette.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, QiblaMetrics.titleTop)
                    .padding(.bottom, QiblaMetrics.titleBottom)
                    .accessibilityAddTraits(.isHeader)

                if model.showsHeading {
                    readout
                }

                Compass(
                    heading: model.dialHeading, bearing: model.bearing, isAligned: model.isAligned,
                    isWithinToleranceRange: model.isWithinToleranceRange
                )
                    .padding(.top, inColumns ? QiblaMetrics.compassTopInColumns : QiblaMetrics.compassTop)
                    .padding(.bottom, inColumns ? QiblaMetrics.compassBottomInColumns : QiblaMetrics.compassBottom)

                status
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, inset)
        } second: {
            VStack(spacing: 0) {
                info
                    .padding(.top, QiblaMetrics.infoTop)
                    .padding(.bottom, model.showsToleranceLegend ? QiblaMetrics.legendTop : QiblaMetrics.infoBottom)

                if model.showsToleranceLegend {
                    ToleranceLegend()
                        .padding(.bottom, QiblaMetrics.legendBottom)
                }

                if model.showsCalibration {
                    CalibrationCard(title: L10n.calibrate, text: L10n.calibrateBody)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, inset)
        }
        // Solange die Seite zu sehen ist; verschwindet sie – andere Seite, anderer Tab, Einstellungen,
        // App im Hintergrund –, hört der Kompass auf.
        .task(id: isSelected && scenePhase == .active) {
            if isSelected, scenePhase == .active {
                await model.run()
            }
        }
        // Haptik und Ansage nur, solange die Seite zu sehen ist – eine andere Stadt kann die Ausrichtung
        // auch ändern, während eine andere Seite vorn ist.
        .sensoryFeedback(.success, trigger: model.isAligned) { _, isAligned in
            isAligned && isSelected
        }
        .onChange(of: model.isAligned) { _, isAligned in
            // Für VoiceOver, wie der Live-Bereich des Prototyps.
            if isAligned, isSelected {
                AccessibilityNotification.Announcement(L10n.facing).post()
            }
        }
    }

    // MARK: - Teile

    /// Die Kursanzeige: „98°“ groß und dünn, daneben die Himmelsrichtung. Bis der erste Kurs kommt,
    /// bleibt ihr Platz frei, damit nichts springt.
    ///
    /// Die Ziffern haben ihre natürliche Breite, wie im Referenzbild: `.q-readout` verlangt zwar gleich
    /// breite Ziffern, aber `.q-deg` setzt die Schrift neu und nimmt das damit zurück.
    private var readout: some View {
        let size = QiblaMetrics.degreesSize * min(max(typeScale, 0), QiblaMetrics.degreesMaxScale)
        let readout = model.readout
        return HStack(alignment: .firstTextBaseline, spacing: QiblaMetrics.readoutGap) {
            Text(readout?.degrees ?? "0°")
                .font(.system(size: size, weight: .thin))
                .tracking(QiblaMetrics.degreesTracking)
                .lineHeight(QiblaMetrics.readoutLineHeight, fontSize: size)
                .foregroundStyle(Palette.label)
            Text(readout?.direction ?? "")
                .textStyle(.title3, weight: .medium, lineHeight: QiblaMetrics.readoutLineHeight)
                .foregroundStyle(Palette.textSecondary)
        }
        .lineLimit(1)
        .opacity(readout == nil ? 0 : 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(readout.map { "\($0.degrees) \($0.direction)" } ?? "")
        .accessibilityAddTraits(.updatesFrequently)
        .accessibilityHidden(readout == nil)
    }

    /// Die Statuszeile; leer bleibt ihr Platz stehen (`min-height: 48px` seit v0.8). Im Toleranzbereich
    /// zwei Zeilen: „Im Toleranzbereich“ mit Haken in Akzent, darunter klein der Drehhinweis (`.q-status.tol`).
    private var status: some View {
        VStack(spacing: QiblaMetrics.statusDetailGap) {
            HStack(spacing: model.statusDetail == nil ? QiblaMetrics.statusGap : QiblaMetrics.toleranceGap) {
                if model.status == .facing || model.statusDetail != nil {
                    Image(systemName: "checkmark")
                        .font(.system(
                            size: model.statusDetail == nil ? QiblaMetrics.checkSize : QiblaMetrics.toleranceCheckSize,
                            weight: QiblaMetrics.checkWeight
                        ))
                        .frame(width: QiblaMetrics.checkBox, height: QiblaMetrics.checkBox)
                        .accessibilityHidden(true)
                }
                if let text = model.statusText {
                    Text(text)
                        .textStyle(.headline, lineHeight: QiblaMetrics.statusLineHeight)
                        .multilineTextAlignment(.center)
                }
            }
            if let detail = model.statusDetail {
                Text(detail)
                    .textStyle(.subheadline, weight: .medium, lineHeight: QiblaMetrics.statusLineHeight)
                    .foregroundStyle(Palette.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .foregroundStyle(isAccentStatus ? Palette.accent : Palette.label)
        .frame(minHeight: QiblaMetrics.statusMinHeight)
        .accessibilityElement(children: .combine)
    }

    private var isAccentStatus: Bool {
        switch model.status {
        case .facing, .withinTolerance: true
        default: false
        }
    }

    /// Richtung und Entfernung, in Mekka der Hinweis; ohne Ort der Knopf „Stadt wählen“.
    @ViewBuilder
    private var info: some View {
        if let info = model.info {
            Text(info)
                .textStyle(.subheadline, lineHeight: QiblaMetrics.infoLineHeight)
                .foregroundStyle(Palette.textSecondary)
                .multilineTextAlignment(.center)
        } else if model.needsCity {
            Button(action: onChooseCity) {
                Text(L10n.citySheetTitle)
                    .font(TypeScale.body.font())
                    .padding(.horizontal, QiblaMetrics.buttonPaddingX)
                    .frame(minHeight: Layout.minTapTarget)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .foregroundStyle(Palette.accent)
        } else {
            // Der Standort wird noch bestimmt: Der Platz der Zeile bleibt frei.
            Text(" ")
                .textStyle(.subheadline, lineHeight: QiblaMetrics.infoLineHeight)
                .accessibilityHidden(true)
        }
    }
}

/// Maße der Qibla-Seite (`.eyebrow`, `.q-readout`, `.compass`, `.q-status`, `.q-info`).
enum QiblaMetrics {
    /// Zeile über dem Kompass (`.eyebrow`: `margin: 6px 0 10px`, `font: 400 …/1.3`).
    static let titleTop: CGFloat = 6
    static let titleBottom: CGFloat = 10
    static let titleLineHeight: CGFloat = 1.3
    /// Laufweite der Zeile (`letter-spacing: .3px`). Die Systemschrift läuft bei 15 pt von sich aus
    /// 0,24 pt enger; der Wert hier ist der Unterschied dazu.
    static let titleTracking: CGFloat = 0.54

    /// Kursanzeige (`.q-readout`: `gap: 12px`; `.q-deg`: `font: 200 56px/1`, `letter-spacing: -1px`,
    /// wächst mit Dynamic Type höchstens auf das 1,2-Fache; `.q-dir`: `font: 500 …/1`).
    static let readoutGap: CGFloat = 12
    static let readoutLineHeight: CGFloat = 1
    static let degreesSize: CGFloat = 56
    static let degreesMaxScale: CGFloat = 1.2
    static let degreesTracking: CGFloat = -1

    /// Kompass (`.compass`: `margin: 40px 0 20px`); innen auf dem iPhone Duo `margin: 20px 0 16px`.
    static let compassTop: CGFloat = 40
    static let compassBottom: CGFloat = 20
    static let compassTopInColumns: CGFloat = 20
    static let compassBottomInColumns: CGFloat = 16
    /// Innenrand der rechten Spalte innen auf dem iPhone Duo (`.qibla .col-b`: `padding: 0 28px`).
    static let infoColumnPadding: CGFloat = 28

    /// Statuszeile (`.q-status`: `gap: 6px; min-height: 48px; font: 600 …/1.3`); im Toleranzbereich
    /// zwei Zeilen mit 1 pt Abstand, Haken und Text mit 6 pt (`.q-status.tol`, `.q-tol-line`), der Haken
    /// dort `ic('check', 16)`.
    static let statusGap: CGFloat = 6
    static let statusMinHeight: CGFloat = 48
    static let statusDetailGap: CGFloat = 1
    static let toleranceGap: CGFloat = 6
    static let toleranceCheckSize: CGFloat = 11
    static let statusLineHeight: CGFloat = 1.3
    /// Der Haken vor „Du blickst Richtung Qibla“ – `ic('check', 18)`, als SF Symbol so groß wie das
    /// Häkchen im Stadt-Sheet. Die Zeichnung des Prototyps ist flacher: 12 × 8,5 pt.
    static let checkBox: CGFloat = 18
    static let checkSize: CGFloat = 12.5
    static let checkWeight: Font.Weight = .semibold

    /// Info-Zeile (`.q-info`: `margin: 6px 0 24px`, Zeilenhöhe 1,3 von `.screen`).
    static let infoTop: CGFloat = 6
    static let infoBottom: CGFloat = 24
    static let infoLineHeight: CGFloat = 1.3

    /// Legende zum Keil (`.q-tolnote`: `margin: -14px 0 20px` – mit den 24 pt unter der Info-Zeile bleiben
    /// 10 pt darüber; `gap: 8px`, Fußnote, Zeilenhöhe 1,35). Das Feld davor: 14 pt, Ecken 4, Akzent zu
    /// 20 %, Rand 1,5 gestrichelt in Akzent zu 60 % (`.q-tol-swatch`).
    static let legendTop: CGFloat = 24 - 14
    static let legendBottom: CGFloat = 20
    static let legendGap: CGFloat = 8
    static let legendLineHeight: CGFloat = 1.35
    static let swatchSize: CGFloat = 14
    static let swatchRadius: CGFloat = 4
    static let swatchFill = 0.2
    static let swatchStroke = 0.6
    static let swatchStrokeWidth: CGFloat = 1.5

    /// Der Knopf „Stadt wählen“ (`.text-btn`: `padding: 0 12px`).
    static let buttonPaddingX: CGFloat = 12
}

/// Die Legende unter der Info-Zeile: ein Feld wie der Keil und „Der markierte Bereich reicht 40° zu jeder
/// Seite der Qibla.“ (`.q-tolnote`, Spec § 9.5).
private struct ToleranceLegend: View {
    var body: some View {
        HStack(spacing: QiblaMetrics.legendGap) {
            RoundedRectangle(cornerRadius: QiblaMetrics.swatchRadius, style: .continuous)
                .fill(Palette.accent.opacity(QiblaMetrics.swatchFill))
                .overlay {
                    RoundedRectangle(cornerRadius: QiblaMetrics.swatchRadius, style: .continuous)
                        .strokeBorder(
                            Palette.accent.opacity(QiblaMetrics.swatchStroke),
                            style: StrokeStyle(lineWidth: QiblaMetrics.swatchStrokeWidth, dash: [3, 2])
                        )
                }
                .frame(width: QiblaMetrics.swatchSize, height: QiblaMetrics.swatchSize)
                .accessibilityHidden(true)
            Text(L10n.tolLegend)
                .textStyle(.footnote, lineHeight: QiblaMetrics.legendLineHeight)
                .foregroundStyle(Palette.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}
