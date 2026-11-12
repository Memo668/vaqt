import PrayerCore
import SwiftUI

/// „Vorher“: Gebetswaschung, reiner Ort und Kleidung, Richtung Qibla mit dem Knopf zur Qibla-Seite und
/// die Absicht mit Gebetsname und Zahl der Rakʿas. Die erste `<ul class="steps">` in `guidePage()`.
public struct GuidePreparationList: View {
    private let prayer: Prayer
    private let onOpenQibla: () -> Void

    /// - Parameters:
    ///   - prayer: das gezeigte Gebet; die Absicht nennt es.
    ///   - onOpenQibla: „Qibla öffnen“.
    public init(prayer: Prayer, onOpenQibla: @escaping () -> Void) {
        self.prayer = prayer
        self.onOpenQibla = onOpenQibla
    }

    public var body: some View {
        let rakahs = Guide.rakahs(for: prayer) ?? Rakahs(aloud: [])
        VStack(spacing: GuideListMetrics.gap) {
            ForEach(GuidePreparation.allCases) { item in
                StepCard(title: item.localizedTitle, text: item.localizedText(prayer: prayer, rakahs: rakahs)) {
                    SymbolBadge.step(item.symbolName, symbolSize: item.symbolSize)
                } extra: {
                    if item == .qibla {
                        PillButton(L10n.b_qiblaBtn, systemImage: GuideSymbols.openQibla, action: onOpenQibla)
                            .padding(.top, StepCardMetrics.buttonTop)
                    }
                }
            }
        }
    }
}

/// „Ablauf“: die sieben Schritte mit Haltungsfigur, Anweisung und Formel; nach der Niederwerfung die
/// gestrichelte Karte „Schritte 2–5 wiederholen“. Die `<ol class="steps">` in `guidePage()`.
public struct GuideStepList: View {

    public init() {}

    public var body: some View {
        VStack(spacing: GuideListMetrics.gap) {
            ForEach(Array(Guide.steps.enumerated()), id: \.element.id) { index, step in
                StepCard(
                    number: index + 1, title: step.kind.localizedTitle, text: step.kind.localizedDescription
                ) {
                    PoseFigure(step.pose)
                } extra: {
                    if let formula = step.formula {
                        FormulaBox(formula)
                            .padding(.top, FormulaMetrics.top)
                    }
                }
                if step.isFollowedByRepeatNote {
                    RepeatNoteCard(L10n.repeatNote, systemImage: GuideSymbols.repeatSteps)
                }
            }
        }
    }
}

/// Abstand zwischen den Karten einer Liste (`.steps`: `gap: 8px`).
enum GuideListMetrics {
    static let gap: CGFloat = 8
}
