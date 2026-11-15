import SwiftUI

/// Der Hauptknopf: eine Kapsel in Akzent, 50 pt hoch, die Breite füllend, Schrift 17 pt halbfett, davor
/// (oder dahinter) auf Wunsch ein Symbol – `.btn.btn-primary` im Prototyp. Gesperrt ist er blasser
/// (`.btn:disabled`), gedrückt leicht verkleinert (`.btn:active`).
public struct PrimaryButton: View {
    private let label: ActionButtonLabel
    private let action: () -> Void

    /// - Parameters:
    ///   - systemImage: SF Symbol neben dem Titel.
    ///   - imagePlacement: vor dem Titel (Standard) oder dahinter wie bei „Weiter ›“.
    public init(
        _ title: String, systemImage: String? = nil, imagePlacement: ActionButtonLabel.Placement = .leading,
        action: @escaping () -> Void
    ) {
        self.label = ActionButtonLabel(title: title, systemImage: systemImage, placement: imagePlacement)
        self.action = action
    }

    /// Mit einem kleinen Symbol wie `ic('chevronRight', 18)` oder `ic('play', 18)`: kleiner als die übrigen
    /// Symbole und mittig in einem Feld von 18 pt, so dass der Abstand zum Titel dem des Prototyps
    /// entspricht.
    public init(
        _ title: String, compactSymbol: String, imagePlacement: ActionButtonLabel.Placement = .leading,
        action: @escaping () -> Void
    ) {
        self.label = ActionButtonLabel(title: title, systemImage: compactSymbol, placement: imagePlacement, style: .compact)
        self.action = action
    }

    public var body: some View {
        Button(action: action) { label }
            .buttonStyle(PrimaryButtonStyle())
    }
}

/// Der getönte Knopf: dieselbe Kapsel in getöntem Akzent, Schrift in Akzent – `.btn.btn-tinted` im
/// Prototyp, z. B. „‹ Zurück“ im Durchlauf „Schritt für Schritt“.
public struct TintedButton: View {
    private let label: ActionButtonLabel
    private let action: () -> Void

    public init(
        _ title: String, systemImage: String? = nil, imagePlacement: ActionButtonLabel.Placement = .leading,
        action: @escaping () -> Void
    ) {
        self.label = ActionButtonLabel(title: title, systemImage: systemImage, placement: imagePlacement)
        self.action = action
    }

    /// Mit einem kleinen Symbol wie `ic('chevronLeft', 18)` (siehe
    /// `PrimaryButton.init(_:compactSymbol:imagePlacement:action:)`).
    public init(
        _ title: String, compactSymbol: String, imagePlacement: ActionButtonLabel.Placement = .leading,
        action: @escaping () -> Void
    ) {
        self.label = ActionButtonLabel(title: title, systemImage: compactSymbol, placement: imagePlacement, style: .compact)
        self.action = action
    }

    public var body: some View {
        Button(action: action) { label }
            .buttonStyle(TintedButtonStyle())
    }
}

/// Inhalt der Knöpfe `.btn`: Titel und Symbol mit 8 pt Abstand, mittig, mindestens 50 pt hoch.
public struct ActionButtonLabel: View {
    /// Wo das Symbol steht. Die Richtung folgt der Leserichtung; SF Symbols wie `chevron.forward` drehen
    /// sich bei Rechts nach links von selbst.
    public enum Placement: Sendable {
        case leading
        case trailing
    }

    /// Wie das Symbol gezeichnet wird.
    enum SymbolStyle: Sendable {
        /// 15 pt halbfett, so breit wie es ist – z. B. der Haken (`ic('check', 18)`).
        case standard
        /// Pfeil oder Abspielen (`ic('chevronLeft', 18)`, `ic('play', 18)`): 12 pt, mittig in einem Feld von
        /// 18 pt wie die Zeichnung im Prototyp, die nur die Mitte ihres Felds füllt.
        case compact
    }

    let title: String
    let systemImage: String?
    let placement: Placement
    var style: SymbolStyle = .standard

    /// Kleine Symbole wachsen mit dem Titel, sonst wirkten sie bei großer Schrift verloren.
    @ScaledMetric(relativeTo: .body) private var typeScale: CGFloat = 1

    public var body: some View {
        HStack(spacing: PrimaryButtonMetrics.gap) {
            if placement == .leading { symbol }
            Text(title)
                .font(TypeScale.body.font(weight: .semibold))
                .multilineTextAlignment(.center)
            if placement == .trailing { symbol }
        }
        .padding(.horizontal, PrimaryButtonMetrics.paddingX)
        .frame(maxWidth: .infinity, minHeight: PrimaryButtonMetrics.height)
        .contentShape(.capsule)
    }

    @ViewBuilder private var symbol: some View {
        if let systemImage {
            switch style {
            case .standard:
                Image(systemName: systemImage)
                    .font(.system(size: PrimaryButtonMetrics.symbolSize, weight: .semibold))
                    .accessibilityHidden(true)
            case .compact:
                Image(systemName: systemImage)
                    .font(.system(
                        size: PrimaryButtonMetrics.compactSize * max(typeScale, 1),
                        weight: PrimaryButtonMetrics.compactWeight
                    ))
                    .frame(width: PrimaryButtonMetrics.compactBox * max(typeScale, 1))
                    .accessibilityHidden(true)
            }
        }
    }
}

/// Akzentfläche, Schrift in `--on-accent`; gesperrt zu 40 %.
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Palette.onAccent)
            .background(Palette.accent, in: .capsule)
            .opacity(isEnabled ? 1 : PrimaryButtonMetrics.disabledOpacity)
            .scaleEffect(configuration.isPressed && !reduceMotion ? PrimaryButtonMetrics.pressedScale : 1)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

/// Fläche in getöntem Akzent (`--accent-tint`), Schrift in Akzent; sonst wie der Hauptknopf.
struct TintedButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Palette.accent)
            .background(Palette.accentTint, in: .capsule)
            .opacity(isEnabled ? 1 : PrimaryButtonMetrics.disabledOpacity)
            .scaleEffect(configuration.isPressed && !reduceMotion ? PrimaryButtonMetrics.pressedScale : 1)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}

/// Maße des Hauptknopfs (`.btn`: `min-height: 50px; padding: 0 20px; gap: 8px`).
enum PrimaryButtonMetrics {
    static let height: CGFloat = 50
    static let paddingX: CGFloat = 20
    static let gap: CGFloat = 8
    /// `ic('check', 18)`
    static let symbolSize: CGFloat = 15
    /// `ic('chevronLeft', 18)`: Pfeil 4,9 × 9,75 pt mit Strich 1,35 pt in einem Feld von 18 pt;
    /// `ic('play', 18)`: Dreieck 9,3 × 10,2 pt.
    static let compactSize: CGFloat = 12
    static let compactWeight: Font.Weight = .medium
    static let compactBox: CGFloat = 18
    static let disabledOpacity = 0.4
    static let pressedScale: CGFloat = 0.97
}
