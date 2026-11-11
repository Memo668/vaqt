import SwiftUI

/// Die drei Seiten des Gebete-Tabs nebeneinander: wechseln durch Wischen oder über die Chips der
/// oberen Leiste. Die Auswahl bleibt erhalten. `.pager` im Prototyp, Design Spec § 3 („Pager“).
///
/// Jede Seite scrollt für sich senkrecht unter der Leiste. Bei von rechts nach links laufender Schrift
/// liegt die erste Seite rechts; das macht die waagerechte `ScrollView` von selbst.
struct PrayersPager<Page: View>: View {
    @Binding private var selection: PrayersPage
    private let page: (PrayersPage) -> Page

    /// Die Seite, auf der die `ScrollView` steht. Zwischen zwei Seiten meldet sie nichts.
    @State private var scrolledPage: PrayersPage?
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(selection: Binding<PrayersPage>, @ViewBuilder page: @escaping (PrayersPage) -> Page) {
        _selection = selection
        self.page = page
    }

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 0) {
                ForEach(PrayersPage.allCases) { item in
                    page(item)
                        .containerRelativeFrame(.horizontal)
                        // Nur die sichtbare Seite ist für VoiceOver da (`aria-hidden` und `inert`).
                        .accessibilityHidden(item != selection)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollIndicators(.hidden)
        .scrollPosition(id: $scrolledPage)
        .onAppear {
            // Beim Start ohne Bewegung auf die gewählte Seite, z. B. mit `-debugTab qibla`.
            if scrolledPage != selection {
                scrolledPage = selection
            }
        }
        .onChange(of: scrolledPage) { _, page in
            // Gewischt: Die Auswahl folgt der Seite.
            if let page, page != selection {
                selection = page
            }
        }
        .onChange(of: selection) { _, page in
            // Chip angetippt: Die Seite folgt der Auswahl – bei „Bewegung reduzieren“ ohne Bewegung.
            guard scrolledPage != page else { return }
            if reduceMotion {
                scrolledPage = page
            } else {
                withAnimation(.snappy) {
                    scrolledPage = page
                }
            }
        }
    }
}
