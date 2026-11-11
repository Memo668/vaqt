import DesignSystem
import SwiftUI

/// Kopf der Zeiten-Seite: die Stadt als Button, darunter das gregorianische und das Hijri-Datum und –
/// ohne Netz – der Hinweis „Offline“. `.home-head` im Prototyp.
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

            Text(model.gregorianDateText + "\n" + model.hijriDateText)
                .textStyle(.subheadline, lineHeight: TodayMetrics.dateLineHeight)
                .foregroundStyle(Palette.textSecondary)
                .multilineTextAlignment(.center)

            if model.isOffline {
                HintPill(L10n.offline, systemImage: "wifi.slash")
                    .padding(.top, TodayMetrics.hintTop)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, TodayMetrics.headerTop)
        .padding(.horizontal, Layout.inset)
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
