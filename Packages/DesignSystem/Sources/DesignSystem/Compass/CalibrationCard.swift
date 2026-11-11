import SwiftUI

/// Die Karte „Kompass kalibrieren“ unter dem Kompass: ein großes Symbol in Akzent, daneben Titel und
/// ein kurzer Text. Die Qibla-Seite zeigt sie nur, solange der Kompass ungenau ist (Design Spec § 4).
///
/// Das Symbol ist die liegende Acht des Prototyps – die Bewegung, mit der sich der Kompass kalibrieren
/// lässt. `.calib` im Prototyp.
public struct CalibrationCard: View {
    private let title: String
    private let text: String

    /// - Parameters:
    ///   - title: fette Zeile, z. B. `L10n.calibrate`.
    ///   - text: Text darunter, z. B. `L10n.calibrateBody`.
    public init(title: String, text: String) {
        self.title = title
        self.text = text
    }

    public var body: some View {
        HStack(spacing: CalibrationMetrics.gap) {
            Image(systemName: "infinity")
                .font(.system(size: CalibrationMetrics.symbolSize, weight: CalibrationMetrics.symbolWeight))
                .foregroundStyle(Palette.accent)
                .frame(width: CalibrationMetrics.symbolBox, height: CalibrationMetrics.symbolBox)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: CalibrationMetrics.titleGap) {
                Text(title)
                    .textStyle(.subheadline, weight: .semibold, lineHeight: CalibrationMetrics.lineHeight)
                    .foregroundStyle(Palette.label)
                Text(text)
                    .textStyle(.footnote, lineHeight: CalibrationMetrics.lineHeight)
                    .foregroundStyle(Palette.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, CalibrationMetrics.paddingX)
        .padding(.vertical, CalibrationMetrics.paddingY)
        .background(Palette.backgroundCell, in: .rect(cornerRadius: Radius.group, style: .continuous))
        .accessibilityElement(children: .combine)
    }
}

/// Maße der Kalibrierungskarte (`.calib`).
enum CalibrationMetrics {
    /// Abstand zwischen Symbol und Text (`gap: 14px`).
    static let gap: CGFloat = 14
    /// Innenabstand (`padding: 14px 16px`).
    static let paddingX: CGFloat = 16
    static let paddingY: CGFloat = 14
    /// Zeilenhöhe von Titel und Text (`line-height: 1.38`).
    static let lineHeight: CGFloat = 1.38
    /// Abstand unter dem Titel (`.calib strong`: `margin-bottom: 2px`).
    static let titleGap: CGFloat = 2
    /// Feld des Symbols – `ic('infinity', 30)`.
    static let symbolBox: CGFloat = 30
    /// Das Symbol als Schriftgröße eines SF Symbols, so breit wie die Zeichnung des Prototyps
    /// (rund 24 pt).
    static let symbolSize: CGFloat = 20
    static let symbolWeight: Font.Weight = .medium
}
