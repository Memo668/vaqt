#if DEBUG

import SwiftUI

// Previews des Katalogs: alle Bausteine in hell und dunkel, dazu der Bogen in den acht Zuständen der
// Abnahme von Phase 2 (docs/BUILD-PLAN.md) – jeweils im Erscheinungsbild und in der Leserichtung des
// Referenzbilds.

/// Der Bogen eines Zustands der Abnahme auf dem Seitenhintergrund.
private struct ArcStatePreview: View {
    let id: String

    var body: some View {
        if let state = CatalogFixtures.arcStates.first(where: { $0.id == id }) {
            ComponentCatalog(section: .arc, phase: state.phase)
                .environment(\.layoutDirection, state.isRightToLeft ? .rightToLeft : .leftToRight)
                .preferredColorScheme(state.isDark ? .dark : .light)
        }
    }
}

#Preview("Katalog · hell") {
    ComponentCatalog()
        .preferredColorScheme(.light)
}

#Preview("Katalog · dunkel") {
    ComponentCatalog()
        .preferredColorScheme(.dark)
}

#Preview("Bogen · 14:25") {
    ArcStatePreview(id: "14:25")
}

#Preview("Bogen · 14:25 dunkel") {
    ComponentCatalog(section: .arc)
        .preferredColorScheme(.dark)
}

#Preview("Bogen · vor Fadschr") {
    ArcStatePreview(id: "vor Fadschr")
}

#Preview("Bogen · 08:04") {
    ArcStatePreview(id: "08:04")
}

#Preview("Bogen · 07:30") {
    ArcStatePreview(id: "07:30")
}

#Preview("Bogen · 16:05") {
    ArcStatePreview(id: "16:05")
}

#Preview("Bogen · nach Ischa") {
    ArcStatePreview(id: "nach Ischa")
}

#Preview("Bogen · Jakarta") {
    ArcStatePreview(id: "Jakarta")
}

#Preview("Bogen · RTL") {
    ArcStatePreview(id: "RTL")
}

#Preview("Gebetskarten · hell") {
    ComponentCatalog(section: .rows)
        .preferredColorScheme(.light)
}

#Preview("Gebetskarten · dunkel") {
    ComponentCatalog(section: .rows)
        .preferredColorScheme(.dark)
}

#Preview("Glass · hell") {
    ComponentCatalog(section: .glass)
        .preferredColorScheme(.light)
}

#Preview("Glass · dunkel") {
    ComponentCatalog(section: .glass)
        .preferredColorScheme(.dark)
}

#Preview("Karten · hell") {
    ComponentCatalog(section: .cards)
        .preferredColorScheme(.light)
}

#Preview("Karten · dunkel") {
    ComponentCatalog(section: .cards)
        .preferredColorScheme(.dark)
}

#endif
