#if DEBUG

import PrayerCore
import SwiftUI

// Abschnitte des Katalogs für Phase 7: Einstellungen, Onboarding, Adhan. In der App stehen die Zeilen in
// der Liste des Systems; hier stehen sie in `InsetGroup` mit dem Innenabstand der Liste, damit sie sich
// ohne Liste ansehen lassen.

/// Die Zeilen der Einstellungen, die Tagline und die Seite „Datenschutz“.
struct CatalogSettings: View {
    @State private var isOn = true

    var body: some View {
        VStack(spacing: 0) {
            InsetGroup(header: L10n.secLocation, footer: L10n.locFooter) {
                ListSwitchRow(L10n.useLocation, isOn: $isOn)
                    .padding(ListRowMetrics.insets)
                ValueRowLabel(L10n.city, value: "Berlin", showsChevron: true)
                    .padding(ListRowMetrics.insets)
            }
            .padding(.bottom, InsetGroup<EmptyView>.spacingBelow)
            InsetGroup(header: L10n.recommended) {
                CheckRow("\(L10n.auto) · MWL", detail: L10n.autoFor(country: "Deutschland"), isSelected: true) {}
                    .padding(ListRowMetrics.insets)
                ValueRowLabel(L10n.privacy, value: L10n.privacyValue)
                    .padding(ListRowMetrics.insets)
                ExternalLinkRow(L10n.source, detail: L10n.sourceSub, destination: URL(string: "https://example.com")!)
                    .padding(ListRowMetrics.insets)
                ListLinkRow(L10n.previewAdhan, systemImage: "waveform") {}
                    .padding(ListRowMetrics.insets)
                ListLinkRow(L10n.adjReset, role: .destructive) {}
                    .padding(ListRowMetrics.insets)
            }
            .padding(.bottom, InsetGroup<EmptyView>.spacingBelow)
            InsetGroup(footer: L10n.perPrayerFooter) {
                ForEach([Prayer.fajr, .sunrise, .isha], id: \.self) { prayer in
                    PrayerNotificationRow(prayer: prayer, state: BellState.standard(for: prayer)) { _ in }
                        .padding(ListRowMetrics.insets)
                }
            }
            .padding(.bottom, InsetGroup<EmptyView>.spacingBelow)
            InsetGroup(footer: L10n.adjFooter) {
                AdjustmentRow(
                    L10n.p_fajr, time: "05:16", value: L10n.min(n: "0"), canDecrement: true, canIncrement: true,
                    decrementLabel: L10n.adjMinus(p: L10n.p_fajr), incrementLabel: L10n.adjPlus(p: L10n.p_fajr),
                    onDecrement: {}, onIncrement: {}
                )
                .padding(ListRowMetrics.insets)
            }
            .padding(.bottom, InsetGroup<EmptyView>.spacingBelow)
            Tagline(L10n.tagline)
            PrivacyNote(title: L10n.privacyBody1, paragraphs: [L10n.privacyBody2, L10n.privacyBody3])
                .padding(.top, Spacing.x8)
        }
        .padding(.horizontal, Layout.inset)
    }
}

/// Die drei Seiten des Onboardings in der Breite der Referenzbilder, mit ihren Punkten.
struct CatalogOnboarding: View {
    var body: some View {
        VStack(spacing: Spacing.x10) {
            VStack(spacing: Spacing.x6) {
                OnboardingPage(title: L10n.ob1Title, message: L10n.ob1Body) {
                    AppMark(size: .large)
                }
                PageDots(count: 3, current: 0)
            }
            VStack(spacing: Spacing.x6) {
                OnboardingPage(title: L10n.ob2Title, message: L10n.ob2Body) {
                    IconBadge(systemImage: "location.fill", symbolSize: IconBadgeMetrics.locationSymbolSize)
                }
                PageDots(count: 3, current: 1)
            }
            VStack(spacing: Spacing.x6) {
                OnboardingPage(title: L10n.ob3Title, message: L10n.ob3Body) {
                    IconBadge(systemImage: "bell.and.waves.left.and.right", symbolSize: IconBadgeMetrics.bellSymbolSize)
                }
                PageDots(count: 3, current: 2)
            }
        }
        .padding(.vertical, Spacing.x6)
        .background(Palette.background)
    }
}

/// Die Karte des Adhan-Players: still bei 0:00 wie `iphone/86`, darunter beim Abspielen nach 12,4 s.
struct CatalogAdhan: View {
    var body: some View {
        VStack(spacing: AdhanPlayerMetrics.marginBottom) {
            card(position: 0, isPlaying: false)
            card(position: 12.4, isPlaying: true)
        }
        .padding(.horizontal, Layout.inset)
    }

    private func card(position: TimeInterval, isPlaying: Bool) -> some View {
        AdhanPlayerCard(
            title: "\(L10n.voiceN(n: "1")) · \(AdhanVoice.one.place)", subtitle: L10n.shortAdhan,
            position: position, duration: 27, isPlaying: isPlaying, onSeek: { _ in }, onToggle: {}
        )
    }
}

#endif
