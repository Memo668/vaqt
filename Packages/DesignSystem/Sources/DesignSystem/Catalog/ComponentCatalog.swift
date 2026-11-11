#if DEBUG

import PrayerCore
import SwiftUI

/// Katalog aller Bausteine des DesignSystems – nur in DEBUG-Builds.
///
/// Er dient zwei Zwecken: als Preview in Xcode (hell und dunkel) und als Bildschirm der App, wenn sie
/// mit `-debugCatalog arc|rows|glass|cards|all` startet. So lassen sich die Bausteine mit
/// `xcrun simctl io … screenshot` aufnehmen und neben die Referenzbilder legen.
///
/// Die Überschriften im Katalog sind Notizen für die Entwicklung, keine Texte der App – sie stehen
/// deshalb nicht im String Catalog. Alles, was die Bausteine selbst zeigen, kommt aus `L10n`.
public struct ComponentCatalog: View {

    /// Was der Katalog zeigt – der Wert von `-debugCatalog`.
    public enum Section: String, CaseIterable, Sendable {
        /// Nur der Bogen mit Zeile und Countdown, in Originalgröße.
        case arc
        /// Die sechs Gebetskarten.
        case rows
        /// Runder Glass-Button, Chips und die schwebende Leiste.
        case glass
        /// Karte, Fakten-Kacheln und Stepper.
        case cards
        /// Alles untereinander, zum Durchblättern.
        case all
    }

    private let section: Section
    private let phase: DayPhase
    private let isHighLatitude: Bool

    /// - Parameters:
    ///   - phase: der Zustand für Bogen und Gebetskarten; ohne Angabe Berlin um 14:25 wie `iphone/10`.
    ///   - isHighLatitude: ob Fadschr und Ischa die Info-Marke für hohe Breiten tragen.
    public init(section: Section = .all, phase: DayPhase? = nil, isHighLatitude: Bool = false) {
        self.section = section
        self.phase = phase ?? CatalogFixtures.phase(time: "14:25:01")
        self.isHighLatitude = isHighLatitude
    }

    public var body: some View {
        switch section {
        case .arc:
            capture { CatalogHero(phase: phase) }
        case .rows:
            capture { CatalogRows(phase: phase, isHighLatitude: isHighLatitude) }
        case .glass:
            capture { CatalogGlass() }
        case .cards:
            capture { CatalogCards() }
        case .all:
            everything
        }
    }

    /// Ein einzelner Abschnitt für die Aufnahme: in der Breite der Referenzbilder, an fester Stelle,
    /// auf dem Seitenhintergrund. So liegt der Baustein in jeder Aufnahme am selben Ort.
    private func capture<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .frame(width: CatalogMetrics.referenceWidth)
            .padding(.top, CatalogMetrics.captureTop)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(Palette.backgroundGrouped)
            .ignoresSafeArea()
    }

    private var everything: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.x8) {
                CatalogGroup("Bogen – die acht Zustände der Abnahme") {
                    ForEach(CatalogFixtures.arcStates) { state in
                        CatalogArcState(state: state)
                    }
                }
                CatalogGroup("Bogen – Live-Aktivität (ARCS.la)") {
                    CatalogLiveActivityArc(phase: CatalogFixtures.phase(time: "16:05:01"))
                    CatalogLiveActivityArc(phase: CatalogFixtures.phase(city: "jakarta", time: "17:57:01"))
                }
                CatalogGroup("Gebetskarten – 14:25, Asr läuft") {
                    CatalogRows(phase: CatalogFixtures.phase(time: "14:25:01"), inset: 0)
                }
                CatalogGroup("Gebetskarten – 16:05, Kerahat läuft, hohe Breiten") {
                    CatalogRows(phase: CatalogFixtures.phase(time: "16:05:01"), isHighLatitude: true, inset: 0)
                }
                CatalogGroup("Glass – Kreis, Chips, schwebende Leiste") {
                    CatalogGlass(inset: 0)
                }
                CatalogGroup("Karte, Fakten-Kacheln, Stepper") {
                    CatalogCards(inset: 0)
                }
                CatalogGroup("Banner, Hinweis-Pille, Hinweiskarte, Toast") {
                    CatalogHints()
                }
                CatalogGroup("Tokens") {
                    CatalogTokens()
                }
            }
            .padding(.horizontal, Layout.inset)
            .padding(.vertical, Spacing.x6)
        }
        .background(Palette.backgroundGrouped)
    }
}

/// Maße des Katalogs für die Aufnahme.
public enum CatalogMetrics {
    /// Breite der Referenzbilder in pt (design/screenshots/INDEX.md). In dieser Breite stehen die
    /// Bausteine, damit sie so breit sind wie auf den Bildern.
    public static let referenceWidth: CGFloat = 390
    /// Abstand des Bausteins zur Oberkante des Bildschirms bei `arc`, `rows`, `glass` und `cards`.
    public static let captureTop: CGFloat = 140
}

// MARK: - Abschnitte

/// Ein Abschnitt des Katalogs mit Überschrift.
private struct CatalogGroup<Content: View>: View {
    private let title: String
    private let content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.x3) {
            Text(title)
                .font(TypeScale.footnote.font(weight: .semibold))
                .foregroundStyle(Palette.textSecondary)
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Notiz unter einem Baustein.
private struct CatalogNote: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text)
            .font(TypeScale.caption2.font(design: .monospaced))
            .foregroundStyle(Palette.textSecondary)
    }
}

/// Der Bogen mit der Zeile „Maghrib in“ und dem Countdown – so wie er auf der Zeiten-Seite steht.
///
/// Der Katalog zeigt einen stehenden Zustand; auf der Zeiten-Seite läuft der Countdown im Sekundentakt.
struct CatalogHero: View {
    let phase: DayPhase

    var body: some View {
        DayArc(phase: phase) {
            ArcCountdown(phase: phase)
        }
    }
}

/// Ein Zustand der Abnahme im Erscheinungsbild und in der Leserichtung seines Referenzbilds.
private struct CatalogArcState: View {
    let state: CatalogFixtures.ArcState

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.x1) {
            CatalogHero(phase: state.phase)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.x3)
                .background(Palette.backgroundGrouped, in: .rect(cornerRadius: Radius.sm, style: .continuous))
                .environment(\.layoutDirection, state.isRightToLeft ? .rightToLeft : .leftToRight)
                .environment(\.colorScheme, state.isDark ? .dark : colorScheme)
            CatalogNote("\(state.id) · \(state.reference)")
        }
    }
}

/// Der kleine Bogen auf dem Akzent-Hintergrund der Live-Aktivität (`.la`: Radius 24, Innenabstand 11/14/8).
private struct CatalogLiveActivityArc: View {
    let phase: DayPhase

    var body: some View {
        DayArc(phase: phase, style: .liveActivity)
            .padding(.top, 11 + 16)
            .padding(.horizontal, 14)
            .padding(.bottom, 8)
            .frame(maxWidth: .infinity)
            .background(Palette.LiveActivity.background, in: .rect(cornerRadius: Radius.sheet, style: .continuous))
    }
}

/// Die sechs Gebetskarten eines Zustands. Die Glocken stehen wie im Prototyp und lassen sich antippen.
struct CatalogRows: View {
    let phase: DayPhase
    var isHighLatitude = false
    var inset: CGFloat = Layout.inset

    @State private var bells: [Prayer: BellState] = Dictionary(
        uniqueKeysWithValues: Prayer.allCases.map { ($0, BellState.standard(for: $0)) }
    )

    var body: some View {
        VStack(spacing: Layout.prayerRowGap) {
            ForEach(PrayerRowModel.rows(for: phase, isHighLatitude: isHighLatitude)) { row in
                let bell = bells[row.prayer] ?? .off
                PrayerRow(row, bell: bell) {
                    bells[row.prayer] = bell.next
                }
            }
        }
        .padding(.horizontal, inset)
    }
}

/// Die Glass-Bausteine: oben wie im Referenzbild (der gewählte Chip mit Titel, die anderen als Kreise),
/// darunter alle Chips mit Titel.
struct CatalogGlass: View {
    var inset: CGFloat = Layout.inset

    @State private var selection = 0

    /// Die drei Chips des Gebete-Tabs. „Anleitung“ trägt die Zeichnung des Prototyps, einen
    /// Gebetsteppich mit Mihrab-Bogen – in den SF Symbols gibt es dafür nichts (docs/OPEN-QUESTIONS.md).
    private var chips: [(title: String, symbol: GlassSymbol)] {
        [(L10n.tabToday, .system("clock")), (L10n.tabQibla, .system("safari")), (L10n.guideChip, .prayerRug)]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.x6) {
            bar(collapsed: true)
            bar(collapsed: false)
        }
        .padding(.horizontal, inset - Layout.inset)
    }

    private func bar(collapsed: Bool) -> some View {
        FloatingBar {
            GlassCircleButton(systemImage: "gearshape", label: L10n.tabSettings) {}
            ForEach(Array(chips.enumerated()), id: \.offset) { index, chip in
                GlassChip(
                    chip.title, symbol: chip.symbol,
                    isSelected: selection == index, showsTitle: !collapsed || selection == index
                ) {
                    selection = index
                }
            }
        }
    }
}

/// Karte mit Fakten-Kacheln wie in der Kopfkarte der Anleitung, darunter Stepper wie beim Nachholen.
struct CatalogCards: View {
    var inset: CGFloat = Layout.inset

    @State private var perDay = 5
    @State private var open = 501

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.x4) {
            Card {
                VStack(alignment: .leading, spacing: Spacing.x4) {
                    HStack(alignment: .top, spacing: FactTile.spacing) {
                        FactTile(value: "4", caption: L10n.rakFard, isProminent: true)
                        FactTile(value: L10n.recSilent, caption: L10n.recite)
                        FactTile(value: L10n.sunna_asr, caption: L10n.sunna)
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    Text(L10n.onlyFatiha)
                        .font(TypeScale.footnote.font())
                        .foregroundStyle(Palette.textSecondary)
                }
            }

            stepperRow(L10n.qadaPerDay, value: perDay) {
                StepperPill(L10n.qadaPerDay, value: $perDay, in: 1...20)
            }
            stepperRow(Prayer.fajr.localizedName, value: open) {
                StepperPill(
                    Prayer.fajr.localizedName, value: $open, in: 0...99_999,
                    decrementLabel: L10n.qadaMinus(p: Prayer.fajr.localizedName),
                    incrementLabel: L10n.qadaPlus(p: Prayer.fajr.localizedName)
                )
            }

            HStack(spacing: Spacing.x4) {
                StepperPill(L10n.years, canDecrement: false, onDecrement: {}, onIncrement: {})
                StepperPill(L10n.years, canIncrement: false, onDecrement: {}, onIncrement: {})
            }
        }
        .padding(.horizontal, inset)
    }

    private func stepperRow<Stepper: View>(
        _ title: String, value: Int, @ViewBuilder stepper: () -> Stepper
    ) -> some View {
        HStack(spacing: Spacing.x3) {
            Text(title)
                .font(TypeScale.body.font())
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(String(value))
                .font(TypeScale.headline.font())
                .monospacedDigit()
            stepper()
        }
        .padding(.leading, Layout.inset)
        .padding(.trailing, 10)
        .frame(minHeight: Layout.prayerRowHeight)
        .background(Palette.backgroundCell, in: .rect(cornerRadius: Radius.row, style: .continuous))
    }
}

/// Banner, Hinweis-Pille, Hinweiskarte und Toast mit den Texten der Zeiten-Seite.
struct CatalogHints: View {
    var body: some View {
        VStack(spacing: Spacing.x3) {
            HintPill(L10n.offline, systemImage: "wifi.slash")
            Banner(L10n.locOffBanner, systemImage: "location.slash", actionTitle: L10n.change) {}
            NoteCard(
                title: L10n.highLatTitle,
                text: L10n.highLatNote(city: L10n.c_berlin, rule: HighLatitudeRule.angle.localizedName),
                linkTitle: L10n.highLatLink
            )
            NoteCard(text: L10n.noTimes)
            Toast(L10n.bellToast(p: Prayer.fajr.localizedName, s: BellState.silent.localizedName), systemImage: BellState.silent.symbolName)
        }
    }
}

/// Die Tokens zum Ansehen: Farben, Schriftskala, Countdown.
private struct CatalogTokens: View {
    private var swatches: [(name: String, color: Color)] {
        [
            ("accent", Palette.accent), ("onAccent", Palette.onAccent), ("accentTint", Palette.accentTint),
            ("arcTrack", Palette.arcTrack), ("currentRow", Palette.currentRow), ("kerahat", Palette.kerahat),
            ("kerahatText", Palette.kerahatText), ("textSecondary", Palette.textSecondary),
            ("labelTertiary", Palette.labelTertiary), ("backgroundCell", Palette.backgroundCell),
            ("fillTertiary", Palette.fillTertiary), ("fillQuaternary", Palette.fillQuaternary),
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.x4) {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: Spacing.x2), count: 3), spacing: Spacing.x3) {
                ForEach(swatches, id: \.name) { swatch in
                    VStack(alignment: .leading, spacing: Spacing.x1) {
                        RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                            .fill(swatch.color)
                            .frame(height: Layout.minTapTarget)
                            .overlay(
                                RoundedRectangle(cornerRadius: Radius.sm, style: .continuous)
                                    .strokeBorder(Palette.separator, lineWidth: 0.5)
                            )
                        CatalogNote(swatch.name)
                    }
                }
            }

            VStack(alignment: .leading, spacing: Spacing.x1) {
                ForEach(TypeScale.allCases, id: \.self) { style in
                    Text("\(String(describing: style)) \(Int(style.pointSize))")
                        .font(style.font())
                }
            }

            VStack(alignment: .leading, spacing: 0) {
                Text("2:01:59")
                    .font(Typography.countdown(inArc: false))
                    .tracking(Typography.countdownTracking)
                CatalogNote("Countdown 64 pt")
                Text("2:01:59")
                    .font(Typography.countdown(inArc: true))
                    .tracking(Typography.countdownTracking)
                CatalogNote("im Bogen 56 pt")
            }
        }
    }
}

#endif
