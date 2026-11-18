import DesignSystem
import PrayerCore
import SwiftUI
import UIKit

/// Einstellungen › Wecker zu Fadschr (`PAGES.alarm`, Spec § 10.8): Schalter, die Wahl „Vor Sonnenaufgang“ oder
/// „Feste Uhrzeit“, ihr Stepper und der Klang. Ohne Erlaubnis bleibt nur der gesperrte Schalter mit dem Weg in
/// die iOS-Einstellungen.
struct AlarmPage: View {
    @Environment(FajrAlarmModel.self) private var alarm
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        SettingsList {
            if alarm.isDenied {
                deniedSection
            } else {
                switchSection
                if alarm.isActive {
                    modeSection
                    stepperSection
                    soundSection
                }
            }
        }
        .task(id: scenePhase) {
            if scenePhase == .active {
                await alarm.refreshAuthorization()
            }
        }
    }

    private var deniedSection: some View {
        Section {
            ListSwitchRow(L10n.alarmSwitch, isOn: .constant(false))
                .disabled(true)
                .listRowMetrics()
            ListLinkRow(L10n.openIosSettings, systemImage: "arrow.up.right") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    openURL(url)
                }
            }
            .listRowMetrics()
        } footer: {
            ListSectionFooter(L10n.alarmDeniedFooter)
        }
    }

    private var switchSection: some View {
        Section {
            ListSwitchRow(L10n.alarmSwitch, detail: alarm.ringsText, isOn: Binding(
                get: { alarm.isActive },
                set: { isOn in Task { await alarm.setOn(isOn) } }
            ))
            .listRowMetrics()
        } footer: {
            ListSectionFooter(L10n.alarmFooter)
        }
    }

    private var modeSection: some View {
        Section {
            ForEach(FajrAlarmMode.allCases, id: \.self) { mode in
                CheckRow(mode.localizedName, isSelected: alarm.preferences.mode == mode) {
                    alarm.setMode(mode)
                }
                .listRowMetrics()
            }
        } header: {
            ListSectionHeader(L10n.alarmWhen)
        } footer: {
            ListSectionFooter(L10n.alarmFixedFooter)
        }
    }

    private var stepperSection: some View {
        Section {
            if alarm.preferences.mode == .fixedTime {
                StepperRow(
                    L10n.alarmTime, value: alarm.fixedTimeText,
                    canDecrement: alarm.canStepFixedTime(by: -1), canIncrement: alarm.canStepFixedTime(by: 1),
                    onDecrement: { alarm.stepFixedTime(by: -1) }, onIncrement: { alarm.stepFixedTime(by: 1) }
                )
                .listRowMetrics()
            } else {
                StepperRow(
                    L10n.alarmBefore, value: alarm.minutesBeforeText,
                    canDecrement: alarm.canStepMinutes(by: -1), canIncrement: alarm.canStepMinutes(by: 1),
                    onDecrement: { alarm.stepMinutes(by: -1) }, onIncrement: { alarm.stepMinutes(by: 1) }
                )
                .listRowMetrics()
            }
        } footer: {
            if let footer = alarm.todayFooter {
                ListSectionFooter(footer)
            }
        }
    }

    private var soundSection: some View {
        Section {
            ForEach(FajrAlarmSound.allCases, id: \.self) { sound in
                CheckRow(sound.localizedName, isSelected: alarm.preferences.sound == sound) {
                    alarm.setSound(sound)
                }
                .listRowMetrics()
            }
        } header: {
            ListSectionHeader(L10n.sound)
        } footer: {
            ListSectionFooter(L10n.alarmSoundFooter)
        }
    }
}

extension FajrAlarmMode {
    /// „Vor Sonnenaufgang“, „Feste Uhrzeit“.
    var localizedName: String {
        switch self {
        case .beforeSunrise: L10n.alarmModeBefore
        case .fixedTime: L10n.alarmModeFixed
        }
    }
}

extension FajrAlarmSound {
    /// „Systemton“, „Kurzer Adhan“ – dieselben Namen wie auf der Seite „Klang“ (`SOUND_KEY`).
    var localizedName: String {
        switch self {
        case .system: L10n.soundSystem
        case .adhan: L10n.soundAdhan
        }
    }
}
