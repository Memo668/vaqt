import SwiftUI

/// Schwebende Leiste: der Träger für die Glass-Elemente der oberen Leiste.
///
/// Die Leiste hat keine eigene Glasfläche. Ihre Elemente – Einstellungskreis und Chips – stehen als
/// einzelne Glass-Flächen mit 8 pt Abstand nebeneinander, in einem `GlassEffectContainer`, damit das
/// System sie gemeinsam zeichnet (Design Spec § 3, „TopBar“). Über dem Inhalt befestigt wird sie von
/// der Seite, z. B. mit `safeAreaBar(edge: .top)`.
public struct FloatingBar<Content: View>: View {
    private let content: Content

    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    public var body: some View {
        GlassEffectContainer(spacing: Layout.chipGap) {
            HStack(spacing: Layout.chipGap) {
                content
            }
        }
        .padding(.horizontal, Layout.inset)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
