import DesignSystem
import SwiftUI

/// Kopf der Zeiten-Seite: die Stadt als Button, darunter das gregorianische und das Hijri-Datum mit je
/// einem Pfeil für den Tag davor und danach, an einem anderen Tag der Textlink „Zurück zu heute“, und –
/// ohne Netz – der Hinweis „Offline“. `.home-head` und `.day-nav` im Prototyp.
struct TodayHeader: View {
    let model: TodayModel

    var body: some View {
        VStack(spacing: 0) {
            Button {
                model.isCitySheetPresented = true
            } label: {
                cityLabel
            }
            .buttonStyle(CityButtonStyle())
            .accessibilityLabel(model.cityAccessibilityLabel)

            HStack(spacing: TodayMetrics.dayNavGap) {
                dayButton(
                    systemImage: "chevron.backward", label: L10n.dayPrev,
                    isEnabled: model.canShowPreviousDay, action: model.showPreviousDay
                )
                Text(model.gregorianDateText + "\n" + model.hijriDateText)
                    .textStyle(.subheadline, lineHeight: TodayMetrics.dateLineHeight)
                    .foregroundStyle(Palette.textSecondary)
                    .multilineTextAlignment(.center)
                dayButton(
                    systemImage: "chevron.forward", label: L10n.dayNext,
                    isEnabled: model.canShowNextDay, action: model.showNextDay
                )
            }
            .padding(.top, TodayMetrics.dayNavTop)

            if model.isShowingOtherDay {
                Button(action: model.backToToday) {
                    Text(L10n.backToToday)
                        .textStyle(.caption1, weight: .medium, lineHeight: TodayMetrics.todayLinkLineHeight)
                        .foregroundStyle(Palette.accent)
                        // Die Tippfläche reicht über den Text hinaus (`.day-today::after`).
                        .padding(.vertical, TodayMetrics.todayLinkHitInsetY)
                        .padding(.horizontal, TodayMetrics.todayLinkHitInsetX)
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)
                .padding(.vertical, -TodayMetrics.todayLinkHitInsetY)
                .padding(.horizontal, -TodayMetrics.todayLinkHitInsetX)
                .padding(.top, TodayMetrics.todayLinkTop)
                .padding(.bottom, TodayMetrics.todayLinkBottom)
            }

            if model.isOffline {
                HintPill(L10n.offline, systemImage: "wifi.slash")
                    .padding(.top, TodayMetrics.hintTop)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, TodayMetrics.headerTop)
        .padding(.horizontal, Layout.inset)
    }

    /// Ein Pfeil neben dem Datum: schlicht und grau, ohne Fläche (`.day-btn`). Die Tippfläche ist 44 pt groß,
    /// im Layout zählen nur die 28 pt des Pfeils. Bei RTL zeigen die Pfeile in die andere Richtung.
    private func dayButton(
        systemImage: String, label: String, isEnabled: Bool, action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: TodayMetrics.daySymbolSize, weight: .medium))
                .foregroundStyle(Palette.labelTertiary)
                .frame(
                    width: TodayMetrics.dayButtonSize + 2 * TodayMetrics.dayButtonHitInset,
                    height: TodayMetrics.dayButtonSize + 2 * TodayMetrics.dayButtonHitInset
                )
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .padding(-TodayMetrics.dayButtonHitInset)
        .accessibilityLabel(label)
    }

    /// `location.fill` · Stadt · „manuell“.
    private var cityLabel: some View {
        HStack(spacing: TodayMetrics.cityGap) {
            if model.showsLocationSymbol {
                Image(systemName: "location.fill")
                    .font(.system(size: TodayMetrics.locationSymbolSize, weight: TodayMetrics.locationSymbolWeight))
                    .foregroundStyle(Palette.accent)
                    .frame(minWidth: TodayMetrics.locationSymbolBox)
            }
            Text(model.cityTitle)
                .textStyle(.title2, weight: .semibold, lineHeight: TodayMetrics.cityLineHeight)
                .foregroundStyle(Palette.label)
                .multilineTextAlignment(.center)
            if model.showsManualTag {
                Text(L10n.manual)
                    .font(TypeScale.caption1.font(weight: .medium))
                    .foregroundStyle(Palette.textSecondary)
                    .padding(.horizontal, TodayMetrics.tagPaddingX)
                    .padding(.vertical, TodayMetrics.tagPaddingY)
                    .background(Palette.fillTertiary, in: .capsule)
            }
        }
        .padding(.horizontal, TodayMetrics.cityPaddingX)
        .padding(.vertical, TodayMetrics.cityPaddingY)
        .frame(minHeight: Layout.minTapTarget)
    }
}

/// Der Stadt-Button hat keine eigene Fläche; nur beim Drücken liegt `--fill-4` darunter
/// (`.city-btn:active`).
private struct CityButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                configuration.isPressed ? Palette.fillQuaternary : .clear,
                in: .rect(cornerRadius: TodayMetrics.cityRadius, style: .continuous)
            )
            .contentShape(.rect(cornerRadius: TodayMetrics.cityRadius, style: .continuous))
    }
}
