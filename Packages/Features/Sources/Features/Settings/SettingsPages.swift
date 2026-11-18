import DesignSystem
import PrayerCore
import SwiftUI
import UIKit

/// Eine Seite der Einstellungen im Stapel eines Tabs – `settingsPage()` im Prototyp: Leiste mit Titel
/// und Zurück-Knopf des Systems, darunter die Gruppen. Die Startseite hat den großen Titel.
struct SettingsDestination: View {
    let route: SettingsRoute

    var body: some View {
        page
            // Innen auf dem iPhone Duo als mittige 600-pt-Spalte (Design Spec § 8).
            .centeredColumn()
            .navigationTitle(route.title)
            .navigationBarTitleDisplayMode(route == .settings ? .large : .inline)
    }

    @ViewBuilder
    private var page: some View {
        switch route {
        case .settings: SettingsPage()
        case .method: MethodPage()
        case .asr: AsrPage()
        case .highLatitude: HighLatitudePage()
        case .adjustments: AdjustmentsPage()
        case .perPrayer: PerPrayerPage()
        case .reminder: LeadTimePage(kind: .reminder)
        case .liveActivity: LeadTimePage(kind: .liveActivity)
        case .alarm: AlarmPage()
        case .sound: SoundPage()
        case .appearance: AppearancePage()
        case .language: LanguagePage()
        case .privacy: PrivacyPage()
        case .licenses: LicensesPage()
        case .support: SupportPage()
        }
    }
}

// MARK: - Startseite

/// Die Einstellungen: Standort, Berechnung, Mitteilungen, Darstellung, Unterstützen, Über (`PAGES.settings`).
struct SettingsPage: View {
    @Environment(SettingsModel.self) private var model
    @Environment(FajrAlarmModel.self) private var alarm
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        List {
            locationSection
            calculationSection
            notificationSection
            appearanceSection
            supportSection
            aboutSection
        }
        .groupedListMetrics()
        .contentMargins(.top, SettingsMetrics.largeTitleGap, for: .scrollContent)
        .task(id: scenePhase) {
            if scenePhase == .active {
                await model.refreshNotificationAuthorization()
                await alarm.refreshAuthorization()
            }
        }
    }

    private var locationSection: some View {
        Section {
            ListSwitchRow(L10n.useLocation, isOn: Binding(
                get: { model.usesCurrentLocation },
                set: { isOn in Task { await model.setUsesCurrentLocation(isOn) } }
            ))
            .disabled(model.isLocationDenied)
            .listRowMetrics()
            Button(action: model.openCitySheet) {
                ValueRowLabel(L10n.city, value: model.cityValue, showsChevron: true)
                    .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .listRowMetrics()
            if model.isLocationDenied {
                ListLinkRow(L10n.openIosSettings, systemImage: "arrow.up.right") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                }
                .listRowMetrics()
            }
        } header: {
            ListSectionHeader(L10n.secLocation)
        } footer: {
            ListSectionFooter(model.locationFooter)
        }
    }

    private var calculationSection: some View {
        Section {
            NavigationLink(value: SettingsRoute.method) {
                ValueRowLabel(L10n.method, detail: model.methodDetail, value: model.methodValue)
            }
            .listRowMetrics()
            NavigationLink(value: SettingsRoute.asr) {
                ValueRowLabel(L10n.asr, value: model.asrValue)
            }
            .listRowMetrics()
            NavigationLink(value: SettingsRoute.highLatitude) {
                ValueRowLabel(L10n.highLat, value: model.highLatitudeValue)
            }
            .listRowMetrics()
            NavigationLink(value: SettingsRoute.adjustments) {
                ValueRowLabel(L10n.adjustments, value: model.adjustmentsValue)
            }
            .listRowMetrics()
        } header: {
            ListSectionHeader(L10n.secCalc)
        } footer: {
            ListSectionFooter(L10n.calcFooter)
        }
    }

    private var notificationSection: some View {
        Section {
            NavigationLink(value: SettingsRoute.perPrayer) {
                ValueRowLabel(L10n.perPrayer, value: model.perPrayerValue)
            }
            .listRowMetrics()
            NavigationLink(value: SettingsRoute.reminder) {
                ValueRowLabel(L10n.reminder, value: model.reminderValue)
            }
            .listRowMetrics()
            NavigationLink(value: SettingsRoute.liveActivity) {
                ValueRowLabel(L10n.liveAct, value: model.liveActivityValue)
            }
            .listRowMetrics()
            NavigationLink(value: SettingsRoute.alarm) {
                ValueRowLabel(L10n.alarmRow, value: alarm.rowValue)
            }
            .listRowMetrics()
            NavigationLink(value: SettingsRoute.sound) {
                ValueRowLabel(L10n.sound, value: model.soundValue)
            }
            .listRowMetrics()
            ListLinkRow(L10n.previewAdhan, systemImage: "waveform", action: model.openAdhan)
                .listRowMetrics()
        } header: {
            ListSectionHeader(L10n.secNotif)
        } footer: {
            if let footer = model.notificationsFooter {
                ListSectionFooter(footer)
            }
        }
    }

    private var appearanceSection: some View {
        Section {
            NavigationLink(value: SettingsRoute.appearance) {
                ValueRowLabel(L10n.appearance, value: model.appearanceValue)
            }
            .listRowMetrics()
            NavigationLink(value: SettingsRoute.language) {
                ValueRowLabel(L10n.language, value: model.languageValue)
            }
            .listRowMetrics()
            ListSwitchRow(L10n.showKerahat, isOn: Binding(get: { model.showsKerahat }, set: model.setShowsKerahat))
                .listRowMetrics()
        } header: {
            ListSectionHeader(L10n.secAppearance)
        } footer: {
            ListSectionFooter(L10n.kerahatFooter)
        }
    }

    /// „Gebetszeiten unterstützen“ mit rotem Herz, auch nach dem Onboarding (Spec § 9.9).
    private var supportSection: some View {
        Section {
            NavigationLink(value: SettingsRoute.support) {
                IconRowLabel(
                    L10n.supportRow(app: L10n.appName), detail: L10n.supportRowSub,
                    systemImage: "heart", tint: Palette.red
                )
            }
            .listRowMetrics()
        }
    }

    private var aboutSection: some View {
        Section {
            if let url = model.sourceCodeURL {
                ExternalLinkRow(L10n.source, detail: L10n.sourceSub, destination: url)
                    .listRowMetrics()
            }
            NavigationLink(value: SettingsRoute.privacy) {
                ValueRowLabel(L10n.privacy, value: L10n.privacyValue)
            }
            .listRowMetrics()
            // Spec § 9.7: Lizenzen der Schriften Amiri und Amiri Quran (OFL) und von Adhan Swift (MIT).
            NavigationLink(value: SettingsRoute.licenses) {
                ValueRowLabel(L10n.licenses, value: nil)
            }
            .listRowMetrics()
            ValueRowLabel(L10n.version, value: model.version)
                .listRowMetrics()
        } header: {
            ListSectionHeader(L10n.secAbout)
        } footer: {
            VStack(spacing: 0) {
                ListSectionFooter(L10n.disclaimer)
                Tagline(L10n.tagline)
                    .padding(.top, TaglineMetrics.top)
                    .padding(.bottom, PageMetrics.contentBottom)
            }
            .listRowInsets(ListRowMetrics.footerInsets)
        }
    }
}

// MARK: - Berechnung

/// Einstellungen › Berechnungsmethode: durchsuchbar, oben die Automatik des Landes (`PAGES.method`).
struct MethodPage: View {
    @Environment(SettingsModel.self) private var model

    var body: some View {
        @Bindable var model = model
        List {
            if model.showsRecommended {
                Section {
                    CheckRow(
                        model.automaticTitle, detail: model.automaticDetail,
                        isSelected: model.settings.calculation.method == nil
                    ) {
                        model.selectMethod(nil)
                    }
                    .listRowMetrics()
                } header: {
                    ListSectionHeader(L10n.recommended)
                }
            }
            Section {
                ForEach(model.filteredMethods, id: \.self) { method in
                    CheckRow(
                        method.name, detail: model.methodSubtitle(method),
                        isSelected: model.settings.calculation.method == method
                    ) {
                        model.selectMethod(method)
                    }
                    .listRowMetrics()
                }
                if model.filteredMethods.isEmpty {
                    Text(L10n.noResults)
                        .textStyle(.body, lineHeight: ListRowMetrics.lineHeight)
                        .foregroundStyle(Palette.textSecondary)
                        .listRowMetrics()
                }
            } header: {
                ListSectionHeader(L10n.allMethods)
            }
        }
        .groupedListMetrics()
        .contentMargins(.top, SettingsMetrics.searchGap, for: .scrollContent)
        .searchable(text: $model.methodQuery, placement: .navigationBarDrawer(displayMode: .always), prompt: L10n.search)
        .autocorrectionDisabled()
        .onDisappear {
            model.methodQuery = ""
        }
    }
}

/// Einstellungen › Asr (`PAGES.asr`).
struct AsrPage: View {
    @Environment(SettingsModel.self) private var model

    var body: some View {
        SettingsList {
            Section {
                ForEach(AsrRule.allCases, id: \.self) { rule in
                    CheckRow(rule.localizedName, detail: rule.localizedDetail, isSelected: model.settings.calculation.asr == rule) {
                        model.setAsr(rule)
                    }
                    .listRowMetrics()
                }
            }
        }
    }
}

/// Einstellungen › Hohe Breitengrade (`PAGES.hl`); bei Moonsighting mit dem Hinweis, dass die Regel nicht
/// wirkt. Mit „Manuelle Winkel“ darunter die Gruppe „Dämmerungswinkel“ mit je einem Stepper für Fadschr
/// und Ischa, 10 bis 20° (Spec § 9.12).
struct HighLatitudePage: View {
    @Environment(SettingsModel.self) private var model

    var body: some View {
        SettingsList {
            Section {
                ForEach(HighLatitudeRule.allCases, id: \.self) { rule in
                    CheckRow(
                        rule.localizedName, detail: rule.localizedDetail,
                        isSelected: model.settings.calculation.highLatitudeRule == rule
                    ) {
                        model.setHighLatitudeRule(rule)
                    }
                    .listRowMetrics()
                }
            } footer: {
                ListSectionFooter(model.highLatitudeFooter)
            }
            if model.settings.calculation.highLatitudeRule == .manual {
                Section {
                    ForEach([Prayer.fajr, .isha], id: \.self) { prayer in
                        StepperRow(
                            prayer.localizedName, value: model.manualAngleText(of: prayer),
                            canDecrement: model.canStepManualAngle(of: prayer, by: -1),
                            canIncrement: model.canStepManualAngle(of: prayer, by: 1),
                            onDecrement: { model.stepManualAngle(of: prayer, by: -1) },
                            onIncrement: { model.stepManualAngle(of: prayer, by: 1) }
                        )
                        .listRowMetrics()
                    }
                } header: {
                    ListSectionHeader(L10n.hlDegHeader)
                } footer: {
                    ListSectionFooter(L10n.hlManualFooter)
                }
            }
        }
    }
}

/// Einstellungen › Minutenkorrektur: je Ereignis ±30 Minuten, „Zurücksetzen“, sobald eine geändert ist
/// (`PAGES.adjust`).
struct AdjustmentsPage: View {
    @Environment(SettingsModel.self) private var model

    var body: some View {
        SettingsList {
            Section {
                ForEach(Prayer.allCases, id: \.self) { prayer in
                    let minutes = model.adjustment(of: prayer)
                    AdjustmentRow(
                        prayer.localizedName, time: model.todayTime(of: prayer), value: model.adjustmentText(of: prayer),
                        canDecrement: minutes > MinuteAdjustments.range.lowerBound,
                        canIncrement: minutes < MinuteAdjustments.range.upperBound,
                        decrementLabel: L10n.adjMinus(p: prayer.localizedName),
                        incrementLabel: L10n.adjPlus(p: prayer.localizedName),
                        onDecrement: { model.stepAdjustment(of: prayer, by: -1) },
                        onIncrement: { model.stepAdjustment(of: prayer, by: 1) }
                    )
                    .listRowMetrics()
                }
            } footer: {
                ListSectionFooter(L10n.adjFooter)
            }
            if model.hasAdjustments {
                Section {
                    ListLinkRow(L10n.adjReset, role: .destructive, action: model.resetAdjustments)
                        .listRowMetrics()
                }
            }
        }
        .task {
            model.prepareTimes()
        }
    }
}

// MARK: - Mitteilungen

/// Einstellungen › Pro Gebet: je Ereignis Ton, Lautlos oder Aus – dieselbe Wahl wie die Glocke der
/// Gebetskarte (`PAGES.perPrayer`).
struct PerPrayerPage: View {
    @Environment(SettingsModel.self) private var model

    var body: some View {
        SettingsList {
            Section {
                ForEach(Prayer.allCases, id: \.self) { prayer in
                    PrayerNotificationRow(prayer: prayer, state: model.bell(for: prayer)) { state in
                        model.setBell(state, for: prayer)
                    }
                    .listRowMetrics()
                }
            } footer: {
                ListSectionFooter(L10n.perPrayerFooter)
            }
        }
    }
}

/// Einstellungen › Vorab-Erinnerung (`PAGES.reminder`) und › Live-Aktivität (`PAGES.live`): eine Wahl
/// unter festen Minuten, 0 heißt aus.
struct LeadTimePage: View {
    enum Kind {
        case reminder
        case liveActivity
    }

    let kind: Kind
    @Environment(SettingsModel.self) private var model

    var body: some View {
        SettingsList {
            Section {
                ForEach(choices, id: \.self) { minutes in
                    CheckRow(SettingsModel.leadText(minutes), isSelected: selection == minutes) {
                        select(minutes)
                    }
                    .listRowMetrics()
                }
            } footer: {
                if kind == .liveActivity {
                    ListSectionFooter(L10n.liveActFooter)
                }
            }
        }
    }

    private var choices: [Int] {
        kind == .reminder ? NotificationPreferences.reminderChoices : NotificationPreferences.liveActivityChoices
    }

    private var selection: Int {
        kind == .reminder ? model.settings.notifications.reminderMinutes : model.settings.notifications.liveActivityMinutes
    }

    private func select(_ minutes: Int) {
        if kind == .reminder {
            model.setReminder(minutes)
        } else {
            model.setLiveActivity(minutes)
        }
    }
}

/// Einstellungen › Klang, darunter „Adhan anhören“ (`PAGES.sound`).
struct SoundPage: View {
    @Environment(SettingsModel.self) private var model

    var body: some View {
        SettingsList {
            Section {
                ForEach(NotificationSound.allCases, id: \.self) { sound in
                    CheckRow(sound.localizedName, isSelected: model.settings.notifications.sound == sound) {
                        model.setSound(sound)
                    }
                    .listRowMetrics()
                }
            } footer: {
                ListSectionFooter(L10n.soundFooter)
            }
            Section {
                ListLinkRow(L10n.previewAdhan, systemImage: "waveform", action: model.openAdhan)
                    .listRowMetrics()
            }
        }
    }
}

// MARK: - Darstellung

/// Einstellungen › Erscheinungsbild: System, Hell, Dunkel (`PAGES.appearance`).
struct AppearancePage: View {
    @Environment(SettingsModel.self) private var model

    var body: some View {
        SettingsList {
            Section {
                ForEach(Appearance.allCases, id: \.self) { appearance in
                    CheckRow(appearance.title, isSelected: model.settings.appearance == appearance) {
                        model.setAppearance(appearance)
                    }
                    .listRowMetrics()
                }
            }
        }
    }
}

/// Einstellungen › Sprache: die 16 Sprachen in der Reihenfolge von `LANG_NAMES` (`PAGES.language`). Die Wahl wirkt
/// sofort, auch auf die Leserichtung.
struct LanguagePage: View {
    @Environment(SettingsModel.self) private var model

    var body: some View {
        SettingsList {
            Section {
                ForEach(AppLanguage.allCases, id: \.self) { language in
                    CheckRow(language.name, isSelected: model.language == language) {
                        model.setLanguage(language)
                    }
                    .environment(\.locale, Locale(identifier: language.rawValue))
                    .listRowMetrics()
                }
            }
        }
    }
}

// MARK: - Über

/// Einstellungen › Datenschutz (`PAGES.privacy`).
struct PrivacyPage: View {
    var body: some View {
        ScrollView {
            PrivacyNote(title: L10n.privacyBody1, paragraphs: [L10n.privacyBody2, L10n.privacyBody3])
                .padding(.top, SettingsMetrics.subpageGap)
        }
        .background(Palette.backgroundGrouped)
    }
}

/// Einstellungen › Lizenzen (Spec § 9.7): je fremdem Teil eine Gruppe mit seinem Namen, die Lizenz und wofür
/// die App ihn braucht; der Lizenztext klappt darunter auf, im englischen Original und auswählbar. Der
/// Prototyp hat diese Seite nicht; sie folgt den Gruppen der übrigen Unterseiten.
struct LicensesPage: View {
    var body: some View {
        SettingsList {
            ForEach(SoftwareLicense.allCases) { license in
                Section {
                    DisclosureGroup {
                        Text(englishText(license.text))
                            .font(.footnote)
                            .foregroundStyle(Palette.textSecondary)
                            .textSelection(.enabled)
                            .listRowMetrics()
                    } label: {
                        RowTitle(license.licenseName, detail: license.localizedPurpose)
                    }
                    .listRowMetrics()
                } header: {
                    ListSectionHeader(license.component)
                } footer: {
                    if license == SoftwareLicense.allCases.last {
                        ListSectionFooter(L10n.licensesFooter)
                    }
                }
            }
        }
    }

    /// Lizenztexte sind englisch: als Englisch markiert, damit VoiceOver sie mit englischer Stimme liest.
    private func englishText(_ text: String) -> AttributedString {
        var attributed = AttributedString(text)
        attributed.languageIdentifier = "en"
        return attributed
    }
}

/// Einstellungen › Unterstützen (`PAGES.support`, Spec § 9.9): wofür Spenden gedacht sind, der Hinweis,
/// dass Spenden bald möglich sind, und „App weiterempfehlen“. Gezahlt wird in v1 nichts (entschieden am
/// 15.11.2026: „Erst nur der Hinweis“).
struct SupportPage: View {
    @Environment(SettingsModel.self) private var model

    var body: some View {
        SettingsList {
            // Der Kopf hat seinen Abstand selbst (`.sup-hero`: 18 pt unten); die Liste legt keinen dazu.
            Section {
                SupportHero(title: L10n.ob4Title, message: L10n.supportLead(app: L10n.appName))
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
            }
            .listSectionSpacing(0)
            Section {
                IconRowLabel(L10n.supAcc, detail: L10n.supAccSub, systemImage: "shield")
                    .listRowMetrics()
                IconRowLabel(L10n.supCare, detail: L10n.supCareSub, systemImage: "gearshape")
                    .listRowMetrics()
                IconRowLabel(L10n.supContent, detail: L10n.supContentSub, systemImage: "book")
                    .listRowMetrics()
            } header: {
                ListSectionHeader(L10n.supportWhat)
            }
            Section {
                SupportSoonCard(title: L10n.supportSoon, message: L10n.supportSoonBody) {
                    if let url = model.appStoreURL {
                        // Während der Beta die Einladung zu TestFlight (project.yml, APP_STORE_URL).
                        ShareLink(item: url) {
                            PillButtonLabel(L10n.supportShare, systemImage: "square.and.arrow.up")
                        }
                        .buttonStyle(PillButtonStyle())
                    }
                }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
            } footer: {
                ListSectionFooter(L10n.supportFoot)
            }
        }
    }
}

// MARK: - Bausteine

/// Die Liste einer Unterseite: Gruppen wie im Prototyp, 10 pt unter der Leiste (`.nav-gap`).
struct SettingsList<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        List {
            content
        }
        .groupedListMetrics()
        .contentMargins(.top, SettingsMetrics.subpageGap, for: .scrollContent)
    }
}

/// Maße der Seiten (`.large-title`, `.nav-gap`, `.searchbar`).
enum SettingsMetrics {
    /// Abstand zwischen großem Titel und erstem Kopf (`.large-title`: `padding-bottom: 14px`). Die Zeile
    /// des großen Titels endet in iOS 26 schon 7,6 pt über der Unterkante der Leiste; gemessen auf dem
    /// iPhone 18 Pro mit iOS 27.2.
    static let largeTitleGap: CGFloat = 14 - 7.6
    /// Abstand zwischen Leiste und erster Gruppe einer Unterseite (`.nav-gap`: 10 pt).
    static let subpageGap: CGFloat = 10
    /// Abstand zwischen Suchfeld und erstem Kopf (`.searchbar`: `margin-bottom: 18px`). Die Leiste endet
    /// 10 pt unter dem Suchfeld des Systems; gemessen auf dem iPhone 18 Pro mit iOS 27.2.
    static let searchGap: CGFloat = 18 - 10
}
