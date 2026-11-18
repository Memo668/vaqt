import DesignSystem
import SwiftUI

/// Das Onboarding beim ersten Start: vier Seiten mit Punkten darunter und den Knöpfen des Schritts –
/// `onboardingHTML()` im Prototyp.
///
/// Die Seiten wechseln nur über die Knöpfe, wie im Prototyp: So lässt sich der Vorab-Bildschirm für den
/// Standort nicht wegwischen, ohne zu antworten. Die neue Seite schiebt sich von der Seite des
/// Zeilenendes herein; bei „Bewegung reduzieren“ blendet sie über.
struct OnboardingView: View {
    let model: OnboardingModel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @AccessibilityFocusState private var primaryFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            topBar
            // Die Seite steht mittig; reicht der Platz nicht – bei sehr großer Schrift –, scrollt sie, und
            // Punkte und Knöpfe bleiben unten stehen.
            GeometryReader { proxy in
                ScrollView {
                    ZStack {
                        page(model.step)
                            .id(model.step)
                            .transition(reduceMotion ? .opacity : .push(from: .trailing))
                    }
                    .frame(maxWidth: .infinity, minHeight: proxy.size.height)
                }
                .scrollBounceBehavior(.basedOnSize)
                .scrollIndicators(.automatic)
            }
            .padding(.bottom, OnboardingMetrics.pageBottom)
            .clipped()
            PageDots(count: OnboardingStep.allCases.count, current: model.step.rawValue)
            actions
        }
        .background(Palette.background.ignoresSafeArea())
        .tint(Palette.accent)
        .animation(reduceMotion ? .easeInOut(duration: 0.2) : .spring(duration: OnboardingMetrics.pageDuration), value: model.step)
        // Das Stadt-Sheet hängt an der Wurzel der App; ist es zu, entscheidet das Modell, wie es weitergeht.
        .onChange(of: model.today.isCitySheetPresented) { _, isPresented in
            if !isPresented {
                model.citySheetClosed()
            }
        }
        // Nach jedem Schritt steht der Fokus auf dem ersten Knopf (`S.focusNext = 'ob-p' + n`).
        .onChange(of: model.step) {
            primaryFocused = true
        }
    }

    // MARK: - Teile

    /// „Überspringen“ oben am Zeilenende, auf Schritt 1 und 2 (`.onb-top`).
    private var topBar: some View {
        HStack {
            Spacer()
            if model.showsSkip {
                Button(L10n.obSkip, action: model.showFree)
                    .buttonStyle(.borderless)
                    .font(TypeScale.body.font())
                    .padding(.horizontal, OnboardingMetrics.skipPaddingX)
                    .frame(minHeight: OnboardingMetrics.topBarHeight)
                    .contentShape(.rect)
            }
        }
        .padding(.horizontal, OnboardingMetrics.topBarInsetX)
        // Mindestens 44 pt; bei sehr großer Schrift wächst die Leiste mit „Überspringen“.
        .frame(minHeight: OnboardingMetrics.topBarHeight)
    }

    @ViewBuilder
    private func page(_ step: OnboardingStep) -> some View {
        switch step {
        case .welcome:
            OnboardingPage(title: L10n.ob1Title, message: L10n.ob1Body) {
                AppMark(size: .large)
            }
        case .location:
            OnboardingPage(title: L10n.ob2Title, message: L10n.ob2Body) {
                IconBadge(systemImage: "location.fill", symbolSize: IconBadgeMetrics.locationSymbolSize)
            }
        case .notifications:
            OnboardingPage(title: L10n.ob3Title, message: L10n.ob3Body) {
                IconBadge(systemImage: "bell.and.waves.left.and.right", symbolSize: IconBadgeMetrics.bellSymbolSize)
            } footer: {
                // Spec § 10.5: Hinweis auf die Live-Aktivität und wo man sie abschaltet.
                OnboardingNote(L10n.ob3Live(app: L10n.appName))
            }
        case .free:
            OnboardingPage(title: L10n.ob4Title, message: L10n.ob4Body(app: L10n.appName)) {
                IconBadge(systemImage: "heart", symbolSize: IconBadgeMetrics.heartSymbolSize)
            } footer: {
                OnboardingChips([L10n.ob4P1, L10n.ob4P2, L10n.ob4P3])
            }
        }
    }

    /// Die Knöpfe des Schritts (`.onb-actions`): oben der Hauptknopf in Akzent, darunter ein schlichter.
    private var actions: some View {
        VStack(spacing: OnboardingMetrics.actionsGap) {
            switch model.step {
            case .welcome:
                primaryButton(L10n.obContinue, action: model.next)
            case .location:
                primaryButton(L10n.ob2Allow) {
                    Task { await model.allowLocation() }
                }
                plainButton(L10n.ob2Manual, action: model.chooseCityManually)
            case .notifications:
                primaryButton(L10n.ob3Allow) {
                    Task { await model.allowNotifications() }
                }
                plainButton(L10n.ob3Later, action: model.showFree)
            case .free:
                primaryButton(L10n.ob4Start, action: model.finish)
            }
        }
        // Innen auf dem iPhone Duo (regular) schmaler und mittig (`.onb-actions`).
        .frame(maxWidth: OnboardingMetrics.actionsMaxWidth(regular: horizontalSizeClass == .regular))
        .padding(OnboardingMetrics.actionsInsets(regular: horizontalSizeClass == .regular))
    }

    /// `.btn.btn-primary`: Kapsel in Akzent, 50 pt hoch, Schrift 17 pt halbfett.
    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(TypeScale.body.font(weight: .semibold))
                .frame(maxWidth: .infinity, minHeight: OnboardingMetrics.buttonHeight)
                .contentShape(.capsule)
        }
        .buttonStyle(PrimaryCapsuleStyle())
        .accessibilityFocused($primaryFocused)
    }

    /// `.btn.btn-plain`: Text in Akzent, mittelstark, ebenso 50 pt hoch.
    private func plainButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(TypeScale.body.font(weight: .medium))
                .frame(maxWidth: .infinity, minHeight: OnboardingMetrics.buttonHeight)
                .contentShape(.rect)
        }
        .buttonStyle(.borderless)
    }
}

/// Der Hauptknopf des Onboardings (`.btn-primary`): Akzentfläche, Schrift in `--on-accent`, gedrückt
/// leicht verkleinert (`.btn:active { transform: scale(.97) }`).
private struct PrimaryCapsuleStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(Palette.onAccent)
            .background(Palette.accent, in: .capsule)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .animation(.spring(duration: 0.2), value: configuration.isPressed)
    }
}
