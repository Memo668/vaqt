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
    @ScaledMetric(relativeTo: .body) private var typeScale: CGFloat = 1

    var body: some View {
        ScrollView {
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

                Compass(heading: model.dialHeading, bearing: model.bearing, isAligned: model.isAligned)
                    .padding(.top, QiblaMetrics.compassTop)
                    .padding(.bottom, QiblaMetrics.compassBottom)

                status

                info
                    .padding(.top, QiblaMetrics.infoTop)
                    .padding(.bottom, QiblaMetrics.infoBottom)

                if model.showsCalibration {
                    CalibrationCard(title: L10n.calibrate, text: L10n.calibrateBody)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, Layout.inset)
            .padding(.top, PageMetrics.contentTop)
            .padding(.bottom, PageMetrics.contentBottom)
        }
        .background(Palette.backgroundGrouped)
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

    /// Die Statuszeile; leer bleibt ihr Platz stehen (`min-height: 26px`).
    private var status: some View {
        HStack(spacing: QiblaMetrics.statusGap) {
            if model.status == .facing {
                Image(systemName: "checkmark")
                    .font(.system(size: QiblaMetrics.checkSize, weight: QiblaMetrics.checkWeight))
                    .frame(width: QiblaMetrics.checkBox, height: QiblaMetrics.checkBox)
                    .accessibilityHidden(true)
            }
            if let text = model.statusText {
                Text(text)
                    .textStyle(.headline, lineHeight: QiblaMetrics.statusLineHeight)
                    .multilineTextAlignment(.center)
            }
        }
        .foregroundStyle(model.status == .facing ? Palette.accent : Palette.label)
        .frame(minHeight: QiblaMetrics.statusMinHeight)
        .accessibilityElement(children: .combine)
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

    /// Kompass (`.compass`: `margin: 40px 0 20px`).
    static let compassTop: CGFloat = 40
    static let compassBottom: CGFloat = 20

    /// Statuszeile (`.q-status`: `gap: 6px; min-height: 26px; font: 600 …/1.3`).
    static let statusGap: CGFloat = 6
    static let statusMinHeight: CGFloat = 26
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

    /// Der Knopf „Stadt wählen“ (`.text-btn`: `padding: 0 12px`).
    static let buttonPaddingX: CGFloat = 12
}
