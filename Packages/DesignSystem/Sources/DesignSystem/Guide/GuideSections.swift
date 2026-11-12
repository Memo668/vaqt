import PrayerCore
import SwiftUI

/// Der erste Teil der Anleitung: die Auswahl der fünf Gebete, die Kopfkarte und „Vorher“ – `.col-a` in
/// `guidePage()`. Auf dem inneren Display des iPhone Duo wird das die linke Spalte (Design Spec § 8).
///
/// Mit dem Seitenrand; den Abstand zur oberen Leiste setzt die Seite.
public struct GuideOverview: View {
    private let header: GuideHeader
    private let focus: AccessibilityFocusState<Prayer?>.Binding?
    private let onSelect: (Prayer) -> Void
    private let onReturn: () -> Void
    private let onOpenQibla: () -> Void

    /// - Parameters:
    ///   - focus: Fokus von VoiceOver auf einem Teil der Auswahl.
    ///   - onSelect: Tippen auf ein Gebet der Auswahl (`guide-pick`).
    ///   - onReturn: „Zum aktuellen Gebet“ (`guide-now`).
    ///   - onOpenQibla: „Qibla öffnen“.
    public init(
        header: GuideHeader, focus: AccessibilityFocusState<Prayer?>.Binding? = nil,
        onSelect: @escaping (Prayer) -> Void, onReturn: @escaping () -> Void, onOpenQibla: @escaping () -> Void
    ) {
        self.header = header
        self.focus = focus
        self.onSelect = onSelect
        self.onReturn = onReturn
        self.onOpenQibla = onOpenQibla
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SegmentedControl(
                L10n.guideChip, segments: header.segments, selection: header.prayer, focus: focus, onSelect: onSelect
            )
            .padding(.top, GuideLayout.segmentsTop)
            .padding(.bottom, GuideLayout.segmentsBottom)

            GuideHeaderCard(header, onReturn: onReturn)

            SectionHeader(L10n.beforeTitle)
                .padding(.top, SectionHeader.spacingAbove)
                .padding(.bottom, SectionHeader.spacingBelow)

            GuidePreparationList(prayer: header.prayer, onOpenQibla: onOpenQibla)
        }
        .padding(.horizontal, Layout.inset)
    }
}

/// Der zweite Teil der Anleitung: „Ablauf“ mit den sieben Schritten und die Fußnote zu den
/// Rechtsschulen – `.col-b` in `guidePage()`. Auf dem inneren Display des iPhone Duo die rechte Spalte.
///
/// Mit dem Seitenrand und dem Abstand unter der Fußnote (`margin-bottom: 8px`).
public struct GuideSteps: View {

    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeader(L10n.stepsTitle)
                .padding(.top, SectionHeader.spacingAbove)
                .padding(.bottom, SectionHeader.spacingBelow)

            GuideStepList()

            CardFootnote(L10n.guideFooter)
                .padding(.top, GuideLayout.footnoteTop)
                .padding(.bottom, GuideLayout.footnoteBottom)
        }
        .padding(.horizontal, Layout.inset)
    }
}

/// Abstände der Anleitung, die zwischen den Bausteinen liegen.
public enum GuideLayout {
    /// Auswahl der Gebete (`.seg-wide`: `margin: 4px var(--inset) 14px`).
    public static let segmentsTop: CGFloat = 4
    public static let segmentsBottom: CGFloat = 14
    /// Fußnote unter dem Ablauf (`style="margin-top:16px"`, `.card-foot`: `margin-bottom: 8px`).
    public static let footnoteTop: CGFloat = 16
    public static let footnoteBottom: CGFloat = 8
}
