import SwiftUI
import UIKit

/// Die Schriftskala – Design Spec § 2 und `--fs-*` im Prototyp.
///
/// Es sind die Textstile des Systems; sie wachsen mit Dynamic Type. Die Größen gelten für die
/// Standardgröße „Large“ (`--ts: 1`).
public enum TypeScale: CaseIterable, Sendable {
    case largeTitle
    case title1
    case title2
    case title3
    case headline
    case body
    case callout
    case subheadline
    case footnote
    case caption1
    case caption2

    /// Schriftgröße in pt bei der Standardgröße.
    public var pointSize: CGFloat {
        switch self {
        case .largeTitle: 34
        case .title1: 28
        case .title2: 22
        case .title3: 20
        case .headline, .body: 17
        case .callout: 16
        case .subheadline: 15
        case .footnote: 13
        case .caption1: 12
        case .caption2: 11
        }
    }

    /// Der Textstil des Systems.
    public var textStyle: Font.TextStyle {
        switch self {
        case .largeTitle: .largeTitle
        case .title1: .title
        case .title2: .title2
        case .title3: .title3
        case .headline: .headline
        case .body: .body
        case .callout: .callout
        case .subheadline: .subheadline
        case .footnote: .footnote
        case .caption1: .caption
        case .caption2: .caption2
        }
    }

    /// Derselbe Textstil für UIKit – zum Prüfen der Größen.
    var uiTextStyle: UIFont.TextStyle {
        switch self {
        case .largeTitle: .largeTitle
        case .title1: .title1
        case .title2: .title2
        case .title3: .title3
        case .headline: .headline
        case .body: .body
        case .callout: .callout
        case .subheadline: .subheadline
        case .footnote: .footnote
        case .caption1: .caption1
        case .caption2: .caption2
        }
    }

    /// Die Schrift des Stils. Ohne `weight` gilt die Stärke des Systems – Headline ist semibold,
    /// alles andere regular.
    public func font(weight: Font.Weight? = nil, design: Font.Design = .default) -> Font {
        let font = Font.system(textStyle, design: design)
        return weight.map { font.weight($0) } ?? font
    }
}

/// Die Schriften, die über die Skala hinausgehen, und die benannten Stile der Bausteine.
public enum Typography {

    // MARK: - Benannte Stile

    /// Seitentitel: Large Title 34 pt, bold.
    public static let largeTitle = TypeScale.largeTitle.font(weight: .bold)
    /// Name der Stadt: Title 2, 22 pt, semibold.
    public static let cityTitle = TypeScale.title2.font(weight: .semibold)
    /// Zeile über dem Countdown, z. B. „Maghrib in“: Subheadline, medium, Zeilenhöhe 1,3 (`.hero-label`).
    public static let countdownLabelWeight: Font.Weight = .medium
    public static let countdownLabelLineHeight: CGFloat = 1.3
    /// Chip „Jetzt“: Caption 2, bold, in Großbuchstaben (`.now-chip`).
    public static let nowChip = TypeScale.caption2.font(weight: .bold)
    /// Laufweite des „Jetzt“-Chips (`letter-spacing: .4px`).
    public static let nowChipTracking: CGFloat = 0.4
    /// Die Uhrzeit einer Gebetskarte läuft 0,2 pt weiter als der Fließtext (`.prow-time`: −0,2 statt −0,41).
    public static let prayerTimeTracking: CGFloat = 0.2

    // MARK: - Countdown

    /// Größe des Countdowns ohne Bogen in pt (`--fs-countdown`).
    public static let countdownSize: CGFloat = 64
    /// Größe im Bogen (`.hero:not(.no-arc) .hero-count`).
    public static let countdownSizeInArc: CGFloat = 56
    /// Größe im Bogen ab zehn Stunden (`.hero-count.wide`).
    public static let countdownSizeInArcWide: CGFloat = 50
    /// Ohne Bogen schrumpft der Countdown ab zehn Stunden auf das 0,86-Fache.
    public static let countdownWideFactor: CGFloat = 0.86
    /// Der Countdown wächst mit Dynamic Type höchstens auf das 1,05-Fache.
    public static let countdownMaxScale: CGFloat = 1.05
    /// Laufweite (`letter-spacing: -1.2px`).
    public static let countdownTracking: CGFloat = -1.2
    /// Zeilenhöhe als Vielfaches der Schriftgröße (`line-height: 1.05`).
    public static let countdownLineHeight: CGFloat = 1.05
    /// Ab dieser Restzeit gilt die schmalere Größe: zehn Stunden, dann hat der Countdown sieben Ziffern.
    public static let countdownWideThreshold: TimeInterval = 36_000

    /// Schriftgröße des Countdowns in pt.
    ///
    /// - Parameters:
    ///   - inArc: ob der Countdown im Bogen steht.
    ///   - isWide: ob die Restzeit zehn Stunden erreicht (`countdownWideThreshold`).
    ///   - typeScale: Faktor von Dynamic Type, 1 bei der Standardgröße (`--ts`).
    public static func countdownSize(inArc: Bool, isWide: Bool, typeScale: CGFloat = 1) -> CGFloat {
        let scale = min(max(typeScale, 0), countdownMaxScale)
        let base: CGFloat = if inArc {
            isWide ? countdownSizeInArcWide : countdownSizeInArc
        } else {
            isWide ? countdownSize * countdownWideFactor : countdownSize
        }
        return base * scale
    }

    /// Schrift des Countdowns: thin, mit Ziffern gleicher Breite.
    public static func countdown(inArc: Bool, isWide: Bool = false, typeScale: CGFloat = 1) -> Font {
        Font.system(size: countdownSize(inArc: inArc, isWide: isWide, typeScale: typeScale), weight: .thin)
            .monospacedDigit()
    }

    // MARK: - Zeiten am Bogen

    /// Die Zeiten am Bogen wachsen mit Dynamic Type höchstens auf das 1,2-Fache.
    public static let arcTimeMaxScale: CGFloat = 1.2
    /// Laufweite der Zeiten am Bogen (`letter-spacing: .1px`).
    public static let arcTimeTracking: CGFloat = 0.1

    /// Schrift einer Zeit am Bogen: semibold, die Zeit des laufenden Gebets bold (`.arc-t`).
    ///
    /// - Parameters:
    ///   - size: Größe bei der Standardgröße – 12 pt, in der Live-Aktivität 10,5 pt.
    ///   - scales: ob die Schrift mit Dynamic Type wächst; in der Live-Aktivität nicht.
    ///   - tabular: ob alle Ziffern gleich breit sind; in der Live-Aktivität nicht.
    public static func arcTime(
        size: CGFloat, isCurrent: Bool, scales: Bool = true, tabular: Bool = true, typeScale: CGFloat = 1
    ) -> Font {
        let scale = scales ? min(max(typeScale, 0), arcTimeMaxScale) : 1
        let font = Font.system(size: size * scale, weight: isCurrent ? .bold : .semibold)
        return tabular ? font.monospacedDigit() : font
    }
}

/// Ober- plus Unterlänge der Systemschrift als Vielfaches der Schriftgröße (SF Pro: 1950 + 494 von 2048).
/// So hoch ist eine einzelne Textzeile in SwiftUI.
let systemFontLineHeight: CGFloat = 1.1934

extension TypeScale {

    /// Maße eines Textstils bei einer Schriftgröße von Dynamic Type.
    struct Metrics: Equatable {
        /// Schriftgröße in pt.
        let pointSize: CGFloat
        /// Höhe einer einzelnen Zeile: Ober- plus Unterlänge.
        let lineHeight: CGFloat
        /// Abstand von Zeile zu Zeile mit engem Zeilenabstand (`Font.leading(.tight)`): 2 pt weniger
        /// als der Standard des Systems – z. B. 20 statt 22 pt für Fließtext.
        let tightPitch: CGFloat
    }

    /// Die Maße des Textstils, wie das System sie für `size` vorgibt.
    func metrics(for size: DynamicTypeSize) -> Metrics {
        let traits = UITraitCollection(preferredContentSizeCategory: UIContentSizeCategory(size))
        let font = UIFont.preferredFont(forTextStyle: uiTextStyle, compatibleWith: traits)
        return Metrics(
            pointSize: font.pointSize,
            lineHeight: font.lineHeight,
            tightPitch: font.lineHeight + font.leading - 2
        )
    }

    /// Wie eine Zeilenhöhe aus dem CSS in SwiftUI gesetzt wird.
    ///
    /// SwiftUI kennt kein `line-height`. Eine Zeile ist so hoch wie die Schrift; von Zeile zu Zeile gilt
    /// der Abstand des Textstils. Mit engem Zeilenabstand als Ausgangspunkt lässt sich der Abstand auf
    /// den des Prototyps anheben; über und unter dem Block fehlt dann noch je eine halbe Differenz.
    ///
    /// - Returns: `lineSpacing` für den Abstand zwischen den Zeilen und `padding` für oben und unten.
    ///   Ist die gewünschte Zeile niedriger als der enge Abstand, bleibt es zwischen den Zeilen beim
    ///   engen Abstand – enger kann SwiftUI nicht setzen.
    static func lineLayout(multiple: CGFloat, metrics: Metrics) -> (lineSpacing: CGFloat, padding: CGFloat) {
        let pitch = metrics.pointSize * multiple
        return (max(0, pitch - metrics.tightPitch), (pitch - metrics.lineHeight) / 2)
    }
}

/// Schrift und Zeilenhöhe eines Textstils, geschrieben wie `font: <Stärke> <Größe>/<Zeilenhöhe>` im CSS.
private struct TextStyleModifier: ViewModifier {
    let style: TypeScale
    let weight: Font.Weight?
    let design: Font.Design
    let lineHeight: CGFloat

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    func body(content: Content) -> some View {
        let layout = TypeScale.lineLayout(multiple: lineHeight, metrics: style.metrics(for: dynamicTypeSize))
        content
            .font(style.font(weight: weight, design: design).leading(.tight))
            .lineSpacing(layout.lineSpacing)
            .padding(.vertical, layout.padding)
    }
}

/// Zeilenhöhe für eine Schrift fester Größe. Solche Schriften haben keinen eigenen Zeilenabstand; die
/// Differenz zur Höhe der Schrift kommt zwischen die Zeilen und je zur Hälfte über und unter den Block.
private struct FixedLineHeight: ViewModifier {
    let multiple: CGFloat
    let fontSize: CGFloat

    func body(content: Content) -> some View {
        let extra = fontSize * (multiple - systemFontLineHeight)
        content
            .lineSpacing(max(0, extra))
            .padding(.vertical, extra / 2)
    }
}

extension View {

    /// Setzt Schrift und Zeilenhöhe eines Textstils der Skala – wie `font: 600 15px/1.25` im Prototyp.
    ///
    /// Jede Zeile bekommt einen Kasten der Höhe `lineHeight × Schriftgröße`, der Text steht mittig
    /// darin. So liegen Grundlinien und Blockhöhen dort, wo sie im Prototyp liegen, auch bei mehreren
    /// Zeilen. Wächst mit Dynamic Type.
    ///
    /// - Parameters:
    ///   - weight: Stärke; ohne Angabe die des Systems (Headline semibold, sonst regular).
    ///   - lineHeight: Zeilenhöhe als Vielfaches der Schriftgröße, z. B. 1,3 für Fließtext.
    public func textStyle(
        _ style: TypeScale, weight: Font.Weight? = nil, design: Font.Design = .default, lineHeight: CGFloat
    ) -> some View {
        modifier(TextStyleModifier(style: style, weight: weight, design: design, lineHeight: lineHeight))
    }

    /// Zeilenhöhe für eine Schrift fester Größe, z. B. den Countdown: ein Kasten der Höhe
    /// `multiple × fontSize` je Zeile, der Text mittig darin.
    public func lineHeight(_ multiple: CGFloat, fontSize: CGFloat) -> some View {
        modifier(FixedLineHeight(multiple: multiple, fontSize: fontSize))
    }
}
