import SwiftUI

/// Hinweiskarte: Symbol, Titel und ein kurzer Text, an dessen Ende ein Link stehen kann – z. B. der
/// Hinweis zu hohen Breiten mit „Regel ändern“ unter den Gebetskarten.
///
/// Der Link steht im Fließtext und bricht mit ihm um, wie das `<button class="inline-link">` des
/// Prototyps. Für VoiceOver ist er zusätzlich eine Aktion der Karte. Design Spec § 3 („Banner / note /
/// hint pill“), `.note` im Prototyp.
public struct NoteCard: View {
    private let title: String?
    private let text: String
    private let systemImage: String
    private let linkTitle: String?
    private let action: () -> Void

    /// - Parameters:
    ///   - title: fette Zeile über dem Text; ohne Angabe nur der Text.
    ///   - systemImage: SF Symbol in Akzent, ohne Angabe `info.circle`.
    ///   - linkTitle: Text des Links am Ende, z. B. `L10n.highLatLink`; ohne Angabe kein Link.
    ///   - action: Tippen auf den Link.
    public init(
        title: String? = nil, text: String, systemImage: String = "info.circle",
        linkTitle: String? = nil, action: @escaping () -> Void = {}
    ) {
        self.title = title
        self.text = text
        self.systemImage = systemImage
        self.linkTitle = linkTitle
        self.action = action
    }

    public var body: some View {
        HStack(alignment: .top, spacing: NoteMetrics.gap) {
            Image(systemName: systemImage)
                .font(.system(size: NoteMetrics.symbolSize, weight: NoteMetrics.symbolWeight))
                .foregroundStyle(Palette.accent)
                .frame(width: NoteMetrics.symbolBox, height: NoteMetrics.symbolBox)
                .padding(.top, NoteMetrics.symbolTop)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: NoteMetrics.titleGap) {
                if let title {
                    Text(title)
                        .textStyle(.subheadline, weight: .bold, lineHeight: NoteMetrics.lineHeight)
                        .foregroundStyle(Palette.label)
                }
                Text(message)
                    .textStyle(.footnote, lineHeight: NoteMetrics.lineHeight)
                    .foregroundStyle(Palette.textSecondary)
                    .tint(Palette.accent)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, NoteMetrics.paddingX)
        .padding(.vertical, NoteMetrics.paddingY)
        .background(Palette.backgroundCell, in: .rect(cornerRadius: Radius.group, style: .continuous))
        // Der Link im Text öffnet nichts; er ruft die Aktion der Karte.
        .environment(\.openURL, OpenURLAction { _ in
            action()
            return .handled
        })
        .accessibilityElement(children: .combine)
        .accessibilityActions {
            if let linkTitle {
                Button(linkTitle, action: action)
            }
        }
    }

    /// Der Text mit dem Link am Ende, durch ein Leerzeichen getrennt.
    private var message: AttributedString {
        var message = AttributedString(text)
        guard let linkTitle else { return message }
        var link = AttributedString(linkTitle)
        link.link = NoteMetrics.linkMarker
        link.font = TypeScale.footnote.font(weight: .semibold).leading(.tight)
        message.append(AttributedString(" "))
        message.append(link)
        return message
    }
}

/// Maße der Hinweiskarte (`.note`).
enum NoteMetrics {
    /// Abstand zwischen Symbol und Text (`gap: 10px`).
    static let gap: CGFloat = 10
    /// Innenabstand (`padding: 12px 14px`).
    static let paddingX: CGFloat = 14
    static let paddingY: CGFloat = 12
    /// Zeilenhöhe von Titel und Text (`line-height: 1.4`).
    static let lineHeight: CGFloat = 1.4
    /// Abstand unter dem Titel (`.note strong`: `margin-bottom: 2px`).
    static let titleGap: CGFloat = 2
    /// Feld des Symbols – `ic('info', 18)` – und sein Versatz nach unten (`.note .ic`: `margin-top: 1px`).
    static let symbolBox: CGFloat = 18
    static let symbolTop: CGFloat = 1
    /// Das Symbol als Schriftgröße eines SF Symbols, im selben Verhältnis wie die Info-Marke der
    /// Gebetskarte (Feld 15 pt, Schrift 13 pt).
    static let symbolSize: CGFloat = 15.5
    static let symbolWeight: Font.Weight = .regular
    /// Marke für den Link im Text. Geöffnet wird sie nie – die Karte fängt den Aufruf ab.
    static let linkMarker = URL(string: "gebetszeiten:hinweis")
}
