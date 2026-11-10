import SwiftUI

/// Die Abstandsskala in pt – `--sp-1` bis `--sp-10` im Prototyp. Der Name nennt das Vielfache von 4.
public enum Spacing {
    /// 4 pt (`--sp-1`).
    public static let x1: CGFloat = 4
    /// 8 pt (`--sp-2`).
    public static let x2: CGFloat = 8
    /// 12 pt (`--sp-3`).
    public static let x3: CGFloat = 12
    /// 16 pt (`--sp-4`).
    public static let x4: CGFloat = 16
    /// 20 pt (`--sp-5`).
    public static let x5: CGFloat = 20
    /// 24 pt (`--sp-6`).
    public static let x6: CGFloat = 24
    /// 32 pt (`--sp-8`).
    public static let x8: CGFloat = 32
    /// 40 pt (`--sp-10`).
    public static let x10: CGFloat = 40

    /// Die ganze Skala, aufsteigend.
    public static let scale: [CGFloat] = [x1, x2, x3, x4, x5, x6, x8, x10]
}

/// Feste Maße der Seiten und Bausteine – Design Spec § 2.
public enum Layout {
    /// Seitenrand und Einzug der Listen (`--inset`).
    public static let inset: CGFloat = 16
    /// Kleinstes Tippziel (`--tap`).
    public static let minTapTarget: CGFloat = 44
    /// Kleinste Höhe einer Listenzeile (`--row-min`).
    public static let minRowHeight: CGFloat = 44
    /// Höhe einer Gebetskarte (`--row-h`, Dichte „regular“).
    public static let prayerRowHeight: CGFloat = 52
    /// Abstand zwischen den Gebetskarten (`.prayers`).
    public static let prayerRowGap: CGFloat = 8
    /// Abstand zwischen den Glass-Elementen der oberen Leiste (`--chip-gap`).
    public static let chipGap: CGFloat = 8
    /// Höhe der oberen Leiste mit Chips, die nur einen Titel tragen (`--bar-h`). Eingeklappte Chips
    /// und der Einstellungskreis sind Kreise mit diesem Durchmesser.
    public static let topBarHeight: CGFloat = 52
    /// Die Leiste wächst mit Dynamic Type höchstens auf das 1,15-Fache (`min(var(--ts), 1.15)`).
    public static let topBarMaxScale: CGFloat = 1.15
}

/// Eckenradien in pt – Design Spec § 2. Karten und Gruppen sind `.continuous` gerundet; Buttons und
/// Chips sind Kapseln.
public enum Radius {
    /// 6 pt (`--r-xs`).
    public static let xs: CGFloat = 6
    /// 10 pt (`--r-sm`).
    public static let sm: CGFloat = 10
    /// 18 pt: alleinstehende Gebetskarten (`--r-row`).
    public static let row: CGFloat = 18
    /// 20 pt: Karte des Adhan-Players (`--r-card`).
    public static let playerCard: CGFloat = 20
    /// 22 pt: Widgets (`--r-widget`).
    public static let widget: CGFloat = 22
    /// 24 pt: Sheets (`--r-sheet`).
    public static let sheet: CGFloat = 24
    /// 26 pt: Karten und Listengruppen (`--r-group`).
    public static let group: CGFloat = 26
}

/// Ein Schatten in der Schreibweise des Prototyps: `box-shadow: 0 <y> <blur> <farbe>`.
public struct ShadowToken: Sendable {
    public let color: Color
    /// Weichzeichnung wie im CSS. SwiftUI erwartet die Hälfte davon als `radius`.
    public let blur: CGFloat
    public let y: CGFloat

    public init(color: Color, blur: CGFloat, y: CGFloat) {
        self.color = color
        self.blur = blur
        self.y = y
    }

    /// Ruhende Gebetskarte: `0 1px 2px rgba(0,0,0,.04)`.
    public static let row = ShadowToken(color: .black.opacity(0.04), blur: 2, y: 1)
    /// Karte des laufenden Gebets: `0 8px 22px` in Akzent mit 20 % Deckkraft.
    public static let currentRow = ShadowToken(color: Palette.accent.opacity(0.20), blur: 22, y: 8)
    /// Ausgewählter Chip: `0 10px 26px` in Akzent mit 24 % Deckkraft.
    public static let selectedChip = ShadowToken(color: Palette.accent.opacity(0.24), blur: 26, y: 10)
    /// Knopf für „jetzt“ auf dem Bogen: `drop-shadow(0 1px 2px rgba(0,0,0,.28))`. Bei `drop-shadow`
    /// ist die Angabe schon die Standardabweichung, deshalb hier das Doppelte.
    public static let knob = ShadowToken(color: .black.opacity(0.28), blur: 4, y: 1)
}

extension View {

    /// Legt einen Schatten aus den Tokens unter die Ansicht.
    public func shadow(_ token: ShadowToken) -> some View {
        shadow(color: token.color, radius: token.blur / 2, x: 0, y: token.y)
    }
}
