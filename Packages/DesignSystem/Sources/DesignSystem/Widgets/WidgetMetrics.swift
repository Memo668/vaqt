import CoreGraphics
import SwiftUI

/// Maße und Schriften der Widgets – `.w`, `.w-small`, `.w-medium`, `.wm-list` und `.acc-*` im CSS des
/// Prototyps.
///
/// Die Schriften haben feste Größen wie im Prototyp: Ein Widget hat eine feste Fläche, die iOS vorgibt.
/// Die Fläche selbst, ihre Ecken (Radius 22 laut Spec) und der Hintergrund des Sperrbildschirms kommen
/// von iOS.
public enum WidgetMetrics {

    // MARK: - Home-Bildschirm

    /// Größe von systemSmall im Prototyp (`.w-small`). Auf dem Gerät gibt iOS die Größe vor.
    public static let smallSize = CGSize(width: 154, height: 154)
    /// Größe von systemMedium im Prototyp (`.w-medium`).
    public static let mediumSize = CGSize(width: 338, height: 154)
    /// Eckenradius der Widgets (`--r-widget`, Spec § 2) – nur für den Katalog; auf dem Gerät rundet iOS.
    public static let cornerRadius: CGFloat = 22

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
    public static let cityFont = Font.system(size: 13, weight: .semibold)
    public static let cityLineHeight: CGFloat = 16 / 13
    /// Abstand zwischen Pfeil und Stadt (`gap: 4px`).
    public static let cityGap: CGFloat = 4
    /// Pfeil vor der Stadt – `ic('locFill', 11)`.
    public static let locationBox: CGFloat = 11
    /// Symbol des nächsten Gebets oben rechts im kleinen Widget – `ic(…, 20)`.
    public static let smallSymbolBox: CGFloat = 20
    /// „NÄCHSTES“ (`.w-cap`: 600 11px/13px, Großbuchstaben).
    public static let captionFont = Font.system(size: 11, weight: .semibold)
    public static let captionLineHeight: CGFloat = 13 / 11
    /// Name des nächsten Gebets (`.w-name`: 600 17px/22px, Akzent).
    public static let nameFont = Font.system(size: 17, weight: .semibold)
    public static let nameLineHeight: CGFloat = 22 / 17
    /// Uhrzeit groß (`.w-time`: 600 34px/38px, gerundet, Ziffern gleicher Breite).
    public static let timeSize: CGFloat = 34
    public static let timeFont = Font.system(size: 34, weight: .semibold, design: .rounded).monospacedDigit()
    public static let timeLineHeight: CGFloat = 38 / 34
    /// „in 2:01:29“ (`.w-count`: 500 13px/16px).
    public static let countFont = Font.system(size: 13, weight: .medium).monospacedDigit()
    public static let countLineHeight: CGFloat = 16 / 13

    /// Zeile der Liste (`.wm-list li`: 500 13px/18px, `padding: 1px 8px`, Radius 6).
    public static let listFont = Font.system(size: 13, weight: .medium).monospacedDigit()
    /// Die Zeile des nächsten Gebets ist fett (`li.next`: 700).
    public static let listNextFont = Font.system(size: 13, weight: .bold).monospacedDigit()
    public static let listLineHeight: CGFloat = 18 / 13
    public static let listRowPadding = EdgeInsets(top: 1, leading: 8, bottom: 1, trailing: 8)
    public static let listRowRadius: CGFloat = 6
    /// Abstand zwischen Name und Uhrzeit einer Zeile (`gap: 6px`).
    public static let listRowGap: CGFloat = 6

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
    public static let circularTimeFont = Font.system(size: 13, weight: .semibold, design: .rounded).monospacedDigit()

    /// accessoryRectangular im Prototyp (`.acc-rect`: 170 × 72, Radius 18).
    public static let rectangularSize = CGSize(width: 170, height: 72)
    public static let rectangularRadius: CGFloat = 18
    /// Innenabstand (`padding: 8px 12px`) und Abstand der Zeilen (`gap: 2px`).
    public static let rectangularPadding = EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
    public static let rectangularGap: CGFloat = 2
    /// Erste Zeile: Symbol und Name (`.ar-1`: 700 15px, `gap: 5px`, `ic(…, 15)`).
    public static let rectangularTitleFont = Font.system(size: 15, weight: .bold)
    public static let rectangularTitleGap: CGFloat = 5
    public static let rectangularSymbolBox: CGFloat = 15
    /// Zweite und dritte Zeile (`.acc-rect`: 500 13px/1.25).
    public static let rectangularFont = Font.system(size: 13, weight: .medium).monospacedDigit()
    public static let rectangularLineHeight: CGFloat = 1.25
    /// Dritte Zeile, das Gebet danach (`.ar-3`: `opacity: .68`).
    public static let followingOpacity: Double = 0.68
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
}
