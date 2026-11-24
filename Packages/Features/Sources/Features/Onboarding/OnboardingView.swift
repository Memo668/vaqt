import DesignSystem
import PrayerCore
import SwiftUI

/// Das Onboarding beim ersten Start: die Seiten mit Punkten darunter und den Knöpfen des Schritts –
/// `onboardingHTML()` im Prototyp.
///
/// Seit dem Nachtrag zu Phase 18 (Spec § 11.5) wechseln die Seiten auch per Wischen: nach links eine vor,
/// nach rechts eine zurück, im Arabischen gespiegelt. Am Anfang und am Ende federt die Seite zurück; die
/// letzte schließt nur der Knopf. Wie „Überspringen“ fragt das Wischen keine Erlaubnis ab. Dafür sind die
/// Seiten ein `TabView` im Seitenstil, wie es der Prototyp für die App vorsieht. Die Knöpfe schieben die
/// nächste Seite herein; bei „Bewegung reduzieren“ wechselt sie ohne Bewegung.
struct OnboardingView: View {
    let model: OnboardingModel

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @AccessibilityFocusState private var primaryFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            topBar
            TabView(selection: Binding(get: { model.step }, set: model.swipe(to:))) {
                ForEach(OnboardingStep.allCases, id: \.self) { step in
                    scrollingPage(step)
                        .tag(step)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .padding(.bottom, OnboardingMetrics.pageBottom)
            PageDots(count: OnboardingStep.allCases.count, current: model.step.rawValue)
            actions
        }
        .background(Palette.background.ignoresSafeArea())
        .tint(Palette.accent)
        .animation(reduceMotion ? nil : .spring(duration: OnboardingMetrics.pageDuration), value: model.step)
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

    /// Die Seite steht mittig; reicht der Platz nicht – bei sehr großer Schrift –, scrollt sie, und Punkte und
    /// Knöpfe bleiben unten stehen.
    private func scrollingPage(_ step: OnboardingStep) -> some View {
        GeometryReader { proxy in
            ScrollView {
                page(step)
                    .frame(maxWidth: .infinity, minHeight: proxy.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
            .scrollIndicators(.automatic)
        }
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
        case .madhab:
            OnboardingPage(title: L10n.obMadhabTitle, message: L10n.obMadhabBody) {
                IconBadge(systemImage: "book", symbolSize: IconBadgeMetrics.bookSymbolSize)
            } footer: {
                // Spec § 11.5: Auswahlmenü (`.ob-pick`) – ein Menü mit den vier Schulen, die gewählte mit Haken.
                MadhabMenu(selection: Binding(get: { model.madhab }, set: model.setMadhab))
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
            case .madhab:
                primaryButton(L10n.obContinue, action: model.confirmMadhab)
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

/// Die Wahl der Rechtsschule im Onboarding (`.ob-pick`, Spec § 11.5): eine Kapsel mit der gewählten Schule und
/// dem Doppelpfeil, die ein Menü mit den vier Schulen öffnet – ein `Picker` im Menü, die gewählte mit Haken. Die
/// Kapsel ist ein eigenes Etikett des Menüs, damit sie aussieht wie im Prototyp (Füllung `--fill-3`, 44 pt hoch,
/// Schrift halbfett); der `Picker` mit `.pickerStyle(.menu)` zeigte nur Text in Akzentfarbe.
private struct MadhabMenu: View {
    @Binding var selection: Madhab

    var body: some View {
        Menu {
            Picker(L10n.madhab, selection: $selection) {
                ForEach(Madhab.allCases, id: \.self) { madhab in
                    Text(madhab.localizedName).tag(madhab)
                }
            }
            .pickerStyle(.inline)
        } label: {
            HStack(spacing: MadhabMenuMetrics.gap) {
                Text(selection.localizedName)
                    .font(TypeScale.body.font(weight: .semibold))
                    .foregroundStyle(Palette.label)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: MadhabMenuMetrics.chevronSize, weight: .semibold))
                    .foregroundStyle(Palette.textSecondary)
            }
            .padding(.leading, MadhabMenuMetrics.paddingLeading)
            .padding(.trailing, MadhabMenuMetrics.paddingTrailing)
            .frame(minHeight: MadhabMenuMetrics.height)
            .background(Palette.fillTertiary, in: .capsule)
            .contentShape(.capsule)
        }
        .menuOrder(.fixed)
        .padding(.top, MadhabMenuMetrics.top)
        .accessibilityLabel(L10n.madhab)
        .accessibilityValue(selection.localizedName)
    }
}

/// Maße der Kapsel (`.ob-pick`: 44 pt hoch, innen 20 pt vorn und 18 pt hinten, 9 pt Abstand; `.ob-madhab`:
/// 26 pt über der Kapsel).
private enum MadhabMenuMetrics {
    static let top: CGFloat = 26
    static let height: CGFloat = 44
    static let paddingLeading: CGFloat = 20
    static let paddingTrailing: CGFloat = 18
    static let gap: CGFloat = 9
    /// Der Doppelpfeil, 12 × 16 pt im Prototyp.
    static let chevronSize: CGFloat = 13
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
