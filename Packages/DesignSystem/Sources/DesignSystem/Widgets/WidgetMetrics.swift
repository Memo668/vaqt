import CoreGraphics
import SwiftUI

/// Maße und Schriften der Widgets – `.w`, `.w-small`, `.w-medium`, `.wm-list` und `.acc-*` im CSS des
/// Prototyps.
///
/// Die Schriften haben die Größen des Prototyps und wachsen mit Dynamic Type begrenzt mit (`textScale`,
/// entschieden mit dem Plan für Phase 11: „Begrenzt mitwachsen“). Die Fläche selbst, ihre Ecken (Radius 22
/// laut Spec) und der Hintergrund des Sperrbildschirms kommen von iOS.
public enum WidgetMetrics {

    // MARK: - Home-Bildschirm

    /// Größe von systemSmall im Prototyp (`.w-small`). Auf dem Gerät gibt iOS die Größe vor.
    public static let smallSize = CGSize(width: 154, height: 154)
    /// Größe von systemMedium im Prototyp (`.w-medium`).
    public static let mediumSize = CGSize(width: 338, height: 154)
    /// Eckenradius der Widgets (`--r-widget`, Spec § 2) – nur für den Katalog; auf dem Gerät rundet iOS.
    public static let cornerRadius: CGFloat = 22

    /// Das mittlere Widget „Live“ im Prototyp (`.w-la`: 338 × 158, seit Phase 14). Auf dem Gerät gibt iOS
    /// die Größe vor; der Bogen behält seine feste Größe (`DayArcMetrics.liveWidget`) und steht mittig.
    public static let liveSize = CGSize(width: 338, height: 158)
    /// Innenabstand (`padding: 9px 12px 0`).
    public static let livePadding = EdgeInsets(top: 9, leading: 12, bottom: 0, trailing: 12)
    /// Der Bogen steht 2 pt unter dem Kopf (`.wla-arc`: `margin: 2px auto 0`).
    public static let liveArcTop: CGFloat = 2

    /// Innenabstand des kleinen Widgets (`padding: 14px 15px`).
    public static let smallPadding = EdgeInsets(top: 14, leading: 15, bottom: 14, trailing: 15)
    /// Innenabstand des mittleren Widgets (`padding: 14px 14px 14px 16px`).
    public static let mediumPadding = EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 14)
    /// Abstand zwischen linker Spalte und Liste (`gap: 14px`).
    public static let mediumGap: CGFloat = 14
    /// Breite der linken Spalte im mittleren Widget (`.wm-l`).
    public static let mediumLeftWidth: CGFloat = 118

    /// Laufweite aller Texte im Widget (`.w`: `letter-spacing: -.2px`).
    public static let tracking: CGFloat = -0.2
    /// Laufweite der großen Uhrzeit (`.w-time`: `-.5px`).
    public static let timeTracking: CGFloat = -0.5
    /// Laufweite der Zeile „NÄCHSTES“ (`.w-cap`: `.3px`).
    public static let captionTracking: CGFloat = 0.3

    /// Stadt oben (`.w-city`: 600 13px/16px).
    public static func cityFont(_ scale: CGFloat = 1) -> Font { .system(size: 13 * scale, weight: .semibold) }
    public static let cityLineHeight: CGFloat = 16 / 13
    /// Abstand zwischen Pfeil und Stadt (`gap: 4px`).
    public static let cityGap: CGFloat = 4
    /// Pfeil vor der Stadt – `ic('locFill', 11)`.
    public static let locationBox: CGFloat = 11
    /// Symbol des nächsten Gebets oben rechts im kleinen Widget – `ic(…, 20)`.
    public static let smallSymbolBox: CGFloat = 20
    /// „NÄCHSTES“ (`.w-cap`: 600 11px/13px, Großbuchstaben).
    public static func captionFont(_ scale: CGFloat = 1) -> Font { .system(size: 11 * scale, weight: .semibold) }
    public static let captionLineHeight: CGFloat = 13 / 11
    /// Name des nächsten Gebets (`.w-name`: 600 17px/22px, Akzent).
    public static func nameFont(_ scale: CGFloat = 1) -> Font { .system(size: 17 * scale, weight: .semibold) }
    public static let nameLineHeight: CGFloat = 22 / 17
    /// Uhrzeit groß (`.w-time`: 600 34px/38px, gerundet, Ziffern gleicher Breite).
    public static let timeSize: CGFloat = 34
    public static func timeFont(_ scale: CGFloat = 1) -> Font {
        .system(size: timeSize * scale, weight: .semibold, design: .rounded).monospacedDigit()
    }
    public static let timeLineHeight: CGFloat = 38 / 34
    /// „in 2:01:29“ (`.w-count`: 500 13px/16px).
    public static func countFont(_ scale: CGFloat = 1) -> Font { .system(size: 13 * scale, weight: .medium).monospacedDigit() }
    public static let countLineHeight: CGFloat = 16 / 13

    /// Zeile der Liste (`.wm-list li`: 500 13px/18px, `padding: 1px 8px`, Radius 6).
    public static func listFont(_ scale: CGFloat = 1, isNext: Bool = false) -> Font {
        // Die Zeile des nächsten Gebets ist fett (`li.next`: 700).
        .system(size: 13 * scale, weight: isNext ? .bold : .medium).monospacedDigit()
    }
    public static let listLineHeight: CGFloat = 18 / 13
    public static let listRowPadding = EdgeInsets(top: 1, leading: 8, bottom: 1, trailing: 8)
    public static let listRowRadius: CGFloat = 6
    /// Abstand zwischen Name und Uhrzeit einer Zeile (`gap: 6px`).
    public static let listRowGap: CGFloat = 6

    // MARK: - Ohne Hintergrund: StandBy und CarPlay (Spec § 12.1, seit Phase 19)

    /// Das kleine Widget in den Tafeln des Prototyps (`.cpw`: 158 × 158) – systemSmall auf einem iPhone mit 390 pt
    /// Breite. In StandBy und CarPlay vergrößert iOS es; die Anordnung bleibt.
    public static let smallReferenceSize = CGSize(width: 158, height: 158)
    /// Innenabstand ohne Hintergrund (`.cpw-next`: `padding: 12px 12px 12px 14px`).
    public static let barePadding = EdgeInsets(top: 12, leading: 14, bottom: 12, trailing: 12)
    /// Symbol vor dem Namen – `ic(…, 22)`, 6 pt Abstand (`.cpw-head`: `gap: 6px`).
    public static let bareSymbolBox: CGFloat = 22
    public static let bareSymbolGap: CGFloat = 6
    /// Name des Gebets (`.cpw-head`: 600 19px/1.15, `-.3px`, Akzent).
    public static let bareNameSize: CGFloat = 19
    public static func bareNameFont(_ scale: CGFloat = 1) -> Font { .system(size: bareNameSize * scale, weight: .semibold) }
    public static let bareNameLineHeight: CGFloat = 1.15
    public static let bareNameTracking: CGFloat = -0.3
    /// Uhrzeit groß (`.cpw-time`: 600 46px/1, gerundet, `-1px`, 3 pt darunter).
    public static let bareTimeSize: CGFloat = 46
    public static func bareTimeFont(_ scale: CGFloat = 1) -> Font {
        .system(size: bareTimeSize * scale, weight: .semibold, design: .rounded).monospacedDigit()
    }
    public static let bareTimeLineHeight: CGFloat = 1
    public static let bareTimeTracking: CGFloat = -1
    public static let bareTimeTop: CGFloat = 3
    /// „in 2:01:29“ (`.cpw-in`: 500 15px/1.2, Zweitschrift, 5 pt darunter).
    public static let bareCountSize: CGFloat = 15
    public static func bareCountFont(_ scale: CGFloat = 1) -> Font { .system(size: bareCountSize * scale, weight: .medium).monospacedDigit() }
    public static let bareCountLineHeight: CGFloat = 1.2
    public static let bareCountTop: CGFloat = 5
    /// „Verbotszeit bis 16:27“ (`.cpw-k`: 600 11.5px/1.2, `-.15px`, `--kerahat-text`, 6 pt darunter) mit Punkt
    /// (7 pt, 4 pt Abstand).
    public static let bareKerahatSize: CGFloat = 11.5
    public static func bareKerahatFont(_ scale: CGFloat = 1) -> Font {
        .system(size: bareKerahatSize * scale, weight: .semibold).monospacedDigit()
    }
    public static let bareKerahatLineHeight: CGFloat = 1.2
    public static let bareKerahatTracking: CGFloat = -0.15
    public static let bareKerahatTop: CGFloat = 6
    public static let kerahatDot: CGFloat = 7
    public static let bareKerahatGap: CGFloat = 4

    // MARK: - Tagesbogen (Spec § 12.2, seit Phase 19)

    /// Innenabstand (`.cpw-arcw`: `padding: 8px 6px`); Bogen und Zeile darunter stehen mittig.
    public static let arcPadding = EdgeInsets(top: 8, leading: 6, bottom: 8, trailing: 6)
    /// „Maghrib · 16:27“ im Bogen (`.cpw-name`: 600 12px/15px, Zweitschrift).
    public static let arcNameFont = Font.system(size: 12, weight: .semibold).monospacedDigit()
    public static let arcNameLineHeight: CGFloat = 15 / 12
    /// So breit darf „Sonnenaufgang · 07:14“ im Bogen werden, ohne an die Gebete an den Enden zu stoßen; sonst wird
    /// die Zeile kleiner.
    public static let arcNameMaxWidth: CGFloat = 118
    /// Countdown im Bogen (`.cpw-cd`: 700 25px/1.05, gerundet, `-.3px`).
    public static let arcCountSize: CGFloat = 25
    public static let arcCountFont = Font.system(size: 25, weight: .bold, design: .rounded).monospacedDigit()
    public static let arcCountLineHeight: CGFloat = 1.05
    public static let arcCountTracking: CGFloat = -0.3
    /// Die Zeile unter dem Bogen (`.cpw-sub`: 600 13px/1.2, 10 pt Abstand, Pfeil `ic('locFill', 12)` bzw. Punkt, 5 pt
    /// Abstand).
    public static let arcFooterSize: CGFloat = 13
    public static let arcFooterFont = Font.system(size: 13, weight: .semibold).monospacedDigit()
    public static let arcFooterLineHeight: CGFloat = 1.2
    public static let arcFooterTop: CGFloat = 10
    public static let arcFooterGap: CGFloat = 5
    public static let arcLocationBox: CGFloat = 12

    // MARK: - Sperrbildschirm

    /// accessoryCircular im Prototyp (`.acc-circ`: 72 × 72).
    public static let circularSize = CGSize(width: 72, height: 72)
    /// Radius und Stärke des Rings (`r="30"`, `stroke-width: 5`).
    public static let ringRadius: CGFloat = 30
    public static let ringWidth: CGFloat = 5
    /// Ring hinten: Weiß mit 25 % Deckkraft (`.ring-bg`).
    public static let ringTrackOpacity: Double = 0.25
    /// Symbol im Ring – `ic(…, 16)`; Abstand zur Uhrzeit (`gap: 2px`).
    public static let circularSymbolBox: CGFloat = 16
    public static let circularGap: CGFloat = 2
    /// Uhrzeit im Ring (`.acc-circ-in`: 600 13px/1, gerundet).
    public static func circularTimeFont(_ scale: CGFloat = 1) -> Font {
        .system(size: 13 * scale, weight: .semibold, design: .rounded).monospacedDigit()
    }

    /// accessoryRectangular im Prototyp (`.acc-rect`: 170 × 72, Radius 18).
    public static let rectangularSize = CGSize(width: 170, height: 72)
    public static let rectangularRadius: CGFloat = 18
    /// Innenabstand ohne Zeiten (`padding: 8px 12px`) und Abstand der Zeilen (`gap: 2px`).
    public static let rectangularPadding = EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
    public static let rectangularGap: CGFloat = 2
    /// Name der App, wenn es keine Zeiten gibt (`.ar-1`: 700 15px).
    public static func rectangularTitleFont(_ scale: CGFloat = 1) -> Font { .system(size: 15 * scale, weight: .bold) }
    /// Der Hinweis darunter (`.acc-rect`: 500 13px/1.25).
    public static func rectangularFont(_ scale: CGFloat = 1) -> Font { .system(size: 13 * scale, weight: .medium).monospacedDigit() }
    public static let rectangularLineHeight: CGFloat = 1.25

    /// Das Rechteck mit dem Bogen im Stil der Live-Aktivität (seit Phase 14, Nachtrag vom 15.11.2026): Der
    /// Bogen (`DayArcMetrics.lockScreen`, 160 × 72) steht mittig, darin „Maghrib · 16:27“ (`.acc-name`: 600
    /// 11px/13px, `opacity: .86`) und der Countdown (`.acc-count`: 700 17px/1.05, gerundet, `-.2px`).
    public static let rectangularArcNameFont = Font.system(size: 11, weight: .semibold).monospacedDigit()
    public static let rectangularArcNameLineHeight: CGFloat = 13 / 11
    public static let rectangularArcNameOpacity: Double = 0.86
    public static let rectangularArcCountSize: CGFloat = 17
    public static let rectangularArcCountFont = Font.system(size: 17, weight: .bold, design: .rounded).monospacedDigit()
    public static let rectangularArcCountLineHeight: CGFloat = 1.05
    public static let rectangularArcCountTracking: CGFloat = -0.2
    /// So breit darf „Sonnenaufgang · 07:14“ werden, ohne an die Gebete an den Enden zu stoßen; sonst wird
    /// die Zeile kleiner.
    public static let rectangularArcNameMaxWidth: CGFloat = 124
    /// Symbol in der Zeile über der Uhr – `ic(…, 15)`.
    public static let inlineSymbolBox: CGFloat = 15

    // MARK: - Symbole

    /// Ein SF Symbol als Schrift dieser Größe erscheint so breit wie die Zeichnung des Prototyps in einem
    /// Feld der Kantenlänge 1 (wie die Gebetskarte: `ic(…, 22)` ↔ 14,5 pt).
    public static let symbolFontScale: CGFloat = 14.5 / 22

    /// Schriftgröße eines SF Symbols für ein Feld der Kantenlänge `box` – z. B. `ic(…, 20)`.
    public static func symbolSize(box: CGFloat) -> CGFloat {
        box * symbolFontScale
    }

    // MARK: - Dynamic Type

    /// So weit wachsen die Texte der Widgets höchstens mit der Schriftgröße – wie die Zeiten am Bogen
    /// (`Typography.arcTimeMaxScale`). Symbole und Abstände bleiben fest.
    public static let maxTextScale: CGFloat = 1.2

    /// Der Faktor für die Texte bei einer Schriftgröße: so viel, wie Fließtext dort wächst, zwischen 1 und
    /// `maxTextScale`. Kleiner als im Prototyp werden die Texte nicht.
    public static func textScale(for size: DynamicTypeSize) -> CGFloat {
        let body = TypeScale.body
        return min(maxTextScale, max(1, body.metrics(for: size).pointSize / body.pointSize))
    }

    /// Die Faktoren, die ein Widget der Reihe nach versucht, bis sein Inhalt in die Höhe passt: der volle,
    /// die halbe Zugabe, der des Prototyps.
    static func textScaleSteps(for size: DynamicTypeSize) -> [CGFloat] {
        let scale = textScale(for: size)
        return scale > 1 ? [scale, (1 + scale) / 2, 1] : [1]
    }
}

extension EnvironmentValues {
    /// Faktor für die Texte der Widgets (`WidgetMetrics.textScale`); 1 heißt: wie im Prototyp.
    @Entry var widgetTextScale: CGFloat = 1
}

/// Die Texte eines Widgets bei Dynamic Type (entschieden mit dem Plan für Phase 11: „Begrenzt mitwachsen“):
/// Sie wachsen mit der Schriftgröße, höchstens auf das 1,2-Fache, und nur so weit, wie der Inhalt in die
/// Höhe des Widgets passt. Passt er nicht, versucht das Widget die halbe Zugabe und dann die Größe des
/// Prototyps. Zu breite Zeilen werden kleiner (`minimumScaleFactor`), statt abgeschnitten zu werden.
struct WidgetTextScaling<Content: View>: View {
    @ViewBuilder let content: Content

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let steps = WidgetMetrics.textScaleSteps(for: dynamicTypeSize)
        if steps.count == 3 {
            ViewThatFits(in: .vertical) {
                content.environment(\.widgetTextScale, steps[0])
                content.environment(\.widgetTextScale, steps[1])
                content.environment(\.widgetTextScale, steps[2])
            }
        } else {
            content.environment(\.widgetTextScale, 1)
        }
    }
}
