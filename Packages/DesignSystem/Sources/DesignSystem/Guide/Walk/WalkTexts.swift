import PrayerCore

// Texte des Durchlaufs „Gebet Schritt für Schritt“ aus dem String Catalog – `WALK` und `walkHTML()` im
// Prototyp. Die Texte der neuen Schritte (kurzes Sitzen, zweite Niederwerfung, erstes und letztes Sitzen)
// sind Entwürfe und fachlich ungeprüft wie die übrige Anleitung (Spec § 6.14, § 9.6).

extension GuideWalk.Step {

    /// Titel des Schritts (`WALK[k][1]`), z. B. „Zweite Niederwerfung“. Start und Ende haben eigene
    /// Titel, die vom Gebet abhängen (`GuideWalk.localizedIntroTitle`, `L10n.wkDoneTitle`).
    public var localizedTitle: String {
        switch kind {
        case .intro: L10n.wkStart
        case .takbir: L10n.s_takbir
        case .qiyam: L10n.s_qiyam
        case .ruku: L10n.s_ruku
        case .itidal: L10n.s_itidal
        case .sujud: L10n.s_sujud
        case .jalsa: L10n.wkJalsa
        case .sujud2: L10n.wkSujud2
        case .tashFirst: L10n.wkTashFirst
        case .tashLast: L10n.wkTashLast
        case .salam: L10n.s_salam
        case .done: L10n.wkDoneTitle
        }
    }

    /// Anweisung zum Schritt (`WALK[k][2]`). Beim Stehen ab der 3. Rakʿa „nur al-Fātiḥa“, davor
    /// al-Fātiḥa und eine weitere Sure. Die Niederwerfungen enden mit „Sprich dreimal:“ vor der Formel.
    public var localizedText: String {
        switch kind {
        case .intro: ""
        case .takbir: L10n.s_takbirD
        case .qiyam: isOnlyFatiha ? L10n.onlyFatiha : L10n.wkQiyam12
        case .ruku: L10n.s_rukuD
        case .itidal: L10n.s_itidalD
        case .sujud: L10n.wkSujudD
        case .jalsa: L10n.wkJalsaD
        case .sujud2: L10n.wkSujud2D
        case .tashFirst: L10n.wkTashFirstD
        case .tashLast: L10n.wkTashLastD
        case .salam: L10n.s_salamD
        case .done: L10n.wkDoneBody
        }
    }

    /// Marke über dem Titel beim Stehen: „Rezitation: laut“ oder „Rezitation: leise“ (`.walk-tag`).
    public var localizedRecitationTag: String? {
        guard kind == .qiyam else { return nil }
        return "\(L10n.recite): \(isAloud ? L10n.recAloud : L10n.recSilent)"
    }
}

extension GuideWalk {

    /// Titel der Startseite: „Dhuhr · 4 Rakʿas“ (`wkIntroTitle`).
    public var localizedIntroTitle: String {
        L10n.wkIntroTitle(p: prayer.localizedName, n: String(rakahs.count))
    }

    /// Text der Startseite: Waschung, Qibla, Absicht (`wkIntroBody`).
    public var localizedIntroBody: String {
        L10n.wkIntroBody(p: prayer.localizedName)
    }

    /// Die Zeile unter dem Titel oben (`.walk-count`): „Rakʿa 2 von 4 · Schritt 9 von 28“; auf Start- und
    /// Schlussseite „Gebet Schritt für Schritt“. VoiceOver sagt sie bei jedem Schritt an (`aria-live`).
    public func localizedProgressLine(at index: Int) -> String {
        let step = step(at: index)
        guard let rakah = step.rakah, let number = stepNumber(at: index) else { return L10n.wkStart }
        let rakahLine = L10n.wkRak(r: String(rakah), n: String(rakahs.count))
        let stepLine = L10n.wkStep(i: String(number), k: String(stepCount))
        return "\(rakahLine) · \(stepLine)"
    }

    /// Name des Vollbilds für VoiceOver: „Gebet Schritt für Schritt: Dhuhr“ (`aria-label` des Dialogs).
    public var localizedDialogLabel: String {
        "\(L10n.wkStart): \(prayer.localizedName)"
    }
}
