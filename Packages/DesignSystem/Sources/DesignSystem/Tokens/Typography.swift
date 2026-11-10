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
    /// Zeile über dem Countdown, z. B. „Maghrib in“: Subheadline, medium (`.hero-label`).
    public static let countdownLabel = TypeScale.subheadline.font(weight: .medium)
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
    public static func arcTime(size: CGFloat, isCurrent: Bool, scales: Bool = true, typeScale: CGFloat = 1) -> Font {
        let scale = scales ? min(max(typeScale, 0), arcTimeMaxScale) : 1
        return Font.system(size: size * scale, weight: isCurrent ? .bold : .semibold).monospacedDigit()
    }
}

/// Ober- plus Unterlänge der Systemschrift als Vielfaches der Schriftgröße (SF Pro: 1950 + 494 von 2048).
/// So hoch ist eine Textzeile in SwiftUI, wenn nichts anderes gesagt ist.
let systemFontLineHeight: CGFloat = 1.1934

/// Zeilenhöhe wie `line-height` im CSS: Jede Zeile bekommt einen Kasten der Höhe `multiple × Schriftgröße`,
/// der Text steht mittig darin. So liegen Grundlinien und Blockhöhen dort, wo sie im Prototyp liegen.
private struct LineHeight: ViewModifier {
    @ScaledMetric private var scaledFontSize: CGFloat
    private let fontSize: CGFloat
    private let multiple: CGFloat
    private let scales: Bool

    /// - Parameter style: der Textstil, mit dem die Schrift wächst; `nil` für eine feste Größe.
    init(multiple: CGFloat, fontSize: CGFloat, relativeTo style: Font.TextStyle?) {
        _scaledFontSize = ScaledMetric(wrappedValue: fontSize, relativeTo: style ?? .body)
        self.fontSize = fontSize
        self.multiple = multiple
        scales = style != nil
    }

    func body(content: Content) -> some View {
        let extra = (scales ? scaledFontSize : fontSize) * (multiple - systemFontLineHeight)
        // Zwischen den Zeilen kann SwiftUI nur Abstand hinzufügen; ein engerer Kasten wirkt deshalb
        // nur über und unter dem Text.
        content
            .lineSpacing(max(0, extra))
            .padding(.vertical, extra / 2)
    }
}

extension View {

    /// Zeilenhöhe eines Textstils der Skala als Vielfaches der Schriftgröße, z. B. 1,3 für Fließtext.
    /// Wächst mit Dynamic Type.
    public func lineHeight(_ multiple: CGFloat, for style: TypeScale) -> some View {
        modifier(LineHeight(multiple: multiple, fontSize: style.pointSize, relativeTo: style.textStyle))
    }

    /// Zeilenhöhe für eine Schrift fester Größe, z. B. den Countdown.
    public func lineHeight(_ multiple: CGFloat, fontSize: CGFloat) -> some View {
        modifier(LineHeight(multiple: multiple, fontSize: fontSize, relativeTo: nil))
    }
}
