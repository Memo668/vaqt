import SwiftUI
import Testing
@testable import DesignSystem

/// Wie die Seiten auf dem iPhone Duo stehen – Design Spec § 8: außen untereinander wie auf dem iPhone,
/// innen zwei Spalten, die sich am Falz treffen; Einstellungen als mittige 600-pt-Spalte.
@Suite("iPhone Duo – Anordnung")
struct DuoLayoutTests {

    /// Innen quer: 951 × 669 pt, davon 84 pt senkrechte Leiste und oben und unten der sichere Bereich
    /// (24 und 34 pt). Der Falz ist ein 40 pt breiter Streifen um die Mitte des Bildschirms (475,5 pt,
    /// `--fold: 475.5px`); flach aufgeklappt meldet ihn das System als inaktiv.
    private let inner = CGSize(width: 951 - 84, height: 669 - 24 - 34)
    private let fold = Fold(axis: .vertical, position: 475.5, thickness: 40, isActive: false)

    private func resolve(
        _ sizeClass: UserInterfaceSizeClass?, _ size: CGSize, _ fold: Fold?
    ) -> PageArrangement {
        PageArrangement.resolve(horizontalSizeClass: sizeClass, size: size, fold: fold)
    }

    private func vertical(_ position: CGFloat) -> Fold {
        Fold(axis: .vertical, position: position, thickness: 40, isActive: false)
    }

    @Test("compact steht untereinander – iPhone und außen auf dem Duo", arguments: [
        (UserInterfaceSizeClass?.some(.compact), CGFloat(402)),
        (.some(.compact), 390),
        (.some(.compact), 867),
        (nil, 867),
    ])
    func compact(sizeClass: UserInterfaceSizeClass?, width: CGFloat) {
        let size = CGSize(width: width, height: 611)
        #expect(resolve(sizeClass, size, fold) == .stacked)
        #expect(resolve(sizeClass, size, nil) == .stacked)
        #expect(!resolve(sizeClass, size, nil).isSplit)
    }

    @Test("innen treffen sich die Spalten am Falz: links 475,5 pt, rechts bis zur Leiste")
    func columnsAtFold() {
        let arrangement = resolve(.regular, inner, fold)
        #expect(arrangement == .columns(leading: 475.5, trailing: 391.5))
        #expect(arrangement.isColumns)
        #expect(arrangement.isSplit)
    }

    @Test("halb aufgeklappt quer, wie ein Buch gehalten, bleiben es die Spalten am Falz")
    func columnsInBookPose() {
        var active = fold
        active.isActive = true
        #expect(resolve(.regular, inner, active) == .columns(leading: 475.5, trailing: 391.5))
    }

    @Test("in RTL liegt die erste Spalte rechts und reicht vom Falz bis zum führenden Rand")
    func columnsRightToLeft() {
        // Die Leiste bleibt rechts; vom führenden (rechten) Rand des Inhalts bis zum Falz sind es
        // 867 − 475,5 pt (`calc(100% - var(--fold))`). So meldet das System den Falz in RTL.
        #expect(resolve(.regular, inner, vertical(inner.width - 475.5)) == .columns(leading: 391.5, trailing: 475.5))
    }

    @Test("ohne Falz teilt die Mitte")
    func columnsWithoutFold() {
        #expect(resolve(.regular, CGSize(width: 800, height: 600), nil) == .columns(leading: 400, trailing: 400))
    }

    @Test("liegt der Falz zu nah am Rand, teilt die Mitte", arguments: [CGFloat(0), 120, 299, 568, 867, 1200])
    func foldTooCloseToEdge(position: CGFloat) {
        #expect(resolve(.regular, inner, vertical(position)) == .columns(leading: 433.5, trailing: 433.5))
    }

    @Test("zu schmal für zwei Spalten: untereinander, auch in regular")
    func tooNarrow() {
        #expect(resolve(.regular, CGSize(width: 599, height: 600), nil) == .stacked)
        #expect(resolve(.regular, CGSize(width: 600, height: 600), nil) == .columns(leading: 300, trailing: 300))
    }

    /// Innen hoch: 669 × 951 pt; der Falz läuft waagerecht durch die Mitte des Bildschirms. Der Platz
    /// beginnt unter der oberen Leiste, hier 100 pt tiefer, und endet über der Tableiste.
    private let portrait = CGSize(width: 669, height: 951 - 100 - 84)
    private func horizontal(active: Bool) -> Fold {
        Fold(axis: .horizontal, position: 475.5 - 100, thickness: 40, isActive: active)
    }

    @Test("innen hoch und flach: untereinander wie auf dem iPhone, auch in regular", arguments: [
        UserInterfaceSizeClass?.some(.compact), .some(.regular),
    ])
    func portraitFlat(sizeClass: UserInterfaceSizeClass?) {
        #expect(resolve(sizeClass, portrait, horizontal(active: false)) == .stacked)
    }

    @Test("Tischhaltung: der erste Teil über dem Falz, der zweite darunter, getrennt vom Streifen")
    func tablePose() {
        let arrangement = resolve(.compact, portrait, horizontal(active: true))
        #expect(arrangement == .rows(top: 355.5, gap: 40, bottom: 371.5))
        #expect(arrangement.isSplit)
        #expect(!arrangement.isColumns)
    }

    @Test("Tischhaltung mit zu wenig Platz über oder unter dem Falz: untereinander")
    func tablePoseTooSmall() {
        let low = Fold(axis: .horizontal, position: 150, thickness: 40, isActive: true)
        #expect(resolve(.compact, portrait, low) == .stacked)
        let high = Fold(axis: .horizontal, position: portrait.height - 150, thickness: 40, isActive: true)
        #expect(resolve(.compact, portrait, high) == .stacked)
    }

    @Test("Einstellungen innen als mittige 600-pt-Spalte, sonst ohne Rand", arguments: [
        (UserInterfaceSizeClass?.some(.regular), CGFloat(875), CGFloat(137.5)),
        (.some(.regular), 600, 0),
        (.some(.regular), 540, 0),
        (.some(.compact), 875, 0),
        (.some(.compact), 390, 0),
        (nil, 875, 0),
        (.some(.regular), 867, 133.5),
    ])
    func centeredColumn(sizeClass: UserInterfaceSizeClass?, width: CGFloat, margin: CGFloat) {
        #expect(CenteredColumn.margin(horizontalSizeClass: sizeClass, width: width) == margin)
    }

    @Test("„Nach Gebet“ beginnt innen die rechte Spalte oder den unteren Teil mit 24 pt, untereinander je nach Plan")
    @MainActor
    func byPrayerTop() {
        #expect(QadaLayout.byPrayerTop(afterPlan: true) == 32)
        #expect(QadaLayout.byPrayerTop(afterPlan: false) == 24)
        #expect(QadaLayout.byPrayerTop(afterPlan: true, startsPart: true) == 24)
        #expect(QadaLayout.byPrayerTop(afterPlan: false, startsPart: true) == 24)
    }

    @Test("Onboarding: auf dem iPhone die Ränder des Prototyps, innen höchstens 575 und 455 pt breit")
    func onboardingWidths() {
        #expect(OnboardingMetrics.pageMaxWidth(regular: false) == nil)
        #expect(OnboardingMetrics.actionsMaxWidth(regular: false) == nil)
        #expect(OnboardingMetrics.actionsInsets(regular: false)
            == EdgeInsets(top: 14, leading: 24, bottom: 12, trailing: 24))
        // `.onb-page`: `padding-inline: 150px`, `.onb-actions`: `padding: 10px 210px 26px` neben 875 pt.
        #expect(OnboardingMetrics.pageMaxWidth(regular: true) == 575)
        #expect(OnboardingMetrics.actionsMaxWidth(regular: true) == 455)
        #expect(OnboardingMetrics.actionsInsets(regular: true)
            == EdgeInsets(top: 10, leading: 24, bottom: 0, trailing: 24))
    }

    @Test("Tischhaltung und Spalten teilen die Seite, untereinander nicht")
    func splitFlags() {
        #expect(!PageArrangement.stacked.isSplit)
        #expect(PageArrangement.columns(leading: 400, trailing: 400).isSplit)
        #expect(PageArrangement.rows(top: 300, gap: 40, bottom: 300).isSplit)
        #expect(!PageArrangement.rows(top: 300, gap: 40, bottom: 300).isColumns)
    }
}
