// Erzeugt von scripts/import-strings aus design/prayer-times-prototype.html (Objekt `T`).
// Nicht von Hand ändern – Texte im Prototyp ändern und das Skript neu ausführen.
//
// Schlüssel und Argumentnamen sind die des Prototyps: `t('wIn', {t: …})` ↔ `L10n.wIn(t: …)`.

// swiftlint:disable all
import Foundation

public enum L10n {
    /// „Vaqt“
    public static var appName: String { text("appName") }
    /// „Zurück“
    public static var back: String { text("back") }
    /// „Gebete“
    public static var navPrayers: String { text("navPrayers") }
    /// „Verse“
    public static var navVerses: String { text("navVerses") }
    /// „Nachholen“
    public static var navQada: String { text("navQada") }
    /// „Anleitung“
    public static var guideChip: String { text("guideChip") }
    /// „Als Nächstes“
    public static var guideNext: String { text("guideNext") }
    /// „Zum aktuellen Gebet“
    public static var guideBack: String { text("guideBack") }
    /// „Rakʿa Fard“
    public static var rakFard: String { text("rakFard") }
    /// „Rezitation“
    public static var recite: String { text("recite") }
    /// „laut“
    public static var recAloud: String { text("recAloud") }
    /// „leise“
    public static var recSilent: String { text("recSilent") }
    /// „1.–2. laut“
    public static var recMixed: String { text("recMixed") }
    /// „Sunna“
    public static var sunna: String { text("sunna") }
    /// „2 vorher“
    public static var sunna_fajr: String { text("sunna_fajr") }
    /// „2–4 vorher, 2 danach“
    public static var sunna_dhuhr: String { text("sunna_dhuhr") }
    /// „4 vorher (freiwillig)“
    public static var sunna_asr: String { text("sunna_asr") }
    /// „2 danach“
    public static var sunna_maghrib: String { text("sunna_maghrib") }
    /// „2 danach, dann Witr“
    public static var sunna_isha: String { text("sunna_isha") }
    /// „Ab der 3. Rakʿa nur al-Fātiha.“
    public static var onlyFatiha: String { text("onlyFatiha") }
    /// „Sitzen“
    public static var tashSit: String { text("tashSit") }
    /// „Sitzen · Salām“
    public static var tashEnd: String { text("tashEnd") }
    /// „Ablauf der Rakʿas“
    public static var rakSeq: String { text("rakSeq") }
    /// „Vorher“
    public static var beforeTitle: String { text("beforeTitle") }
    /// „Ablauf“
    public static var stepsTitle: String { text("stepsTitle") }
    /// „Gebetswaschung (Wudūʾ)“
    public static var b_wudu: String { text("b_wudu") }
    /// „Hände, Mund, Nase, Gesicht, Arme, Kopf, Ohren und Füße waschen.“
    public static var b_wuduD: String { text("b_wuduD") }
    /// „Reiner Ort und Kleidung“
    public static var b_clean: String { text("b_clean") }
    /// „Bedecke den Körper nach den Regeln für Männer und Frauen.“
    public static var b_cleanD: String { text("b_cleanD") }
    /// „Richtung Qibla“
    public static var b_qibla: String { text("b_qibla") }
    /// „Wende dich zur Kaaba in Mekka.“
    public static var b_qiblaD: String { text("b_qiblaD") }
    /// „Qibla öffnen“
    public static var b_qiblaBtn: String { text("b_qiblaBtn") }
    /// „Absicht (Niyya)“
    public static var b_niyya: String { text("b_niyya") }
    /// „Fasse im Herzen die Absicht: {p}, {n} Rakʿa.“
    public static func b_niyyaD(p: String, n: String) -> String { text("b_niyyaD", p, n) }
    /// „Takbīr“
    public static var s_takbir: String { text("s_takbir") }
    /// „Hebe die Hände und sage – damit beginnt das Gebet:“
    public static var s_takbirD: String { text("s_takbirD") }
    /// „Stehen (Qiyām)“
    public static var s_qiyam: String { text("s_qiyam") }
    /// „Lies al-Fātiha. In den ersten zwei Rakʿas folgt eine weitere Sure.“
    public static var s_qiyamD: String { text("s_qiyamD") }
    /// „Verbeugung (Rukūʿ)“
    public static var s_ruku: String { text("s_ruku") }
    /// „Rücken gerade, Hände auf den Knien. Dreimal:“
    public static var s_rukuD: String { text("s_rukuD") }
    /// „Aufrichten (Iʿtidāl)“
    public static var s_itidal: String { text("s_itidal") }
    /// „Richte dich auf und sage:“
    public static var s_itidalD: String { text("s_itidalD") }
    /// „Niederwerfung (Sudschūd)“
    public static var s_sujud: String { text("s_sujud") }
    /// „Stirn, Nase, Hände, Knie und Zehen auf dem Boden. Dreimal – kurz sitzen, dann ein zweites Mal:“
    public static var s_sujudD: String { text("s_sujudD") }
    /// „Sitzen (Taschahhud)“
    public static var s_tash: String { text("s_tash") }
    /// „Nach der 2. Rakʿa und am Ende. Am Ende folgen Segensgebet und Bittgebet.“
    public static var s_tashD: String { text("s_tashD") }
    /// „Friedensgruß (Salām)“
    public static var s_salam: String { text("s_salam") }
    /// „Kopf nach rechts, dann nach links:“
    public static var s_salamD: String { text("s_salamD") }
    /// „Für jede weitere Rakʿa wiederholst du die Schritte 2–5.“
    public static var repeatNote: String { text("repeatNote") }
    /// „Die Anleitung zeigt den üblichen Ablauf. Einzelheiten unterscheiden sich je nach Rechtsschule – lerne das Gebet am besten mit deiner Moschee.“
    public static var guideFooter: String { text("guideFooter") }
    /// „{n} von 5 Gebetszeiten haben heute begonnen“
    public static func arcPrayers(n: String) -> String { text("arcPrayers", n) }
    /// „Vers des Tages“
    public static var verseToday: String { text("verseToday") }
    /// „Letzte Tage“
    public static var versePrev: String { text("versePrev") }
    /// „Teilen“
    public static var share: String { text("share") }
    /// „Kopieren“
    public static var copy: String { text("copy") }
    /// „Kopiert“
    public static var copied: String { text("copied") }
    /// „Öffnet das Teilen-Menü (Prototyp)“
    public static var shareToast: String { text("shareToast") }
    /// „Übersetzung: Platzhalter – die endgültige, lizenzierte Übersetzung folgt.“
    public static var verseSource: String { text("verseSource") }
    /// „Heute“
    public static var today: String { text("today") }
    /// „Gestern“
    public static var yesterday: String { text("yesterday") }
    /// „Behalte im Blick, welche Gebete du nachholen möchtest. Alles bleibt auf deinem Gerät.“
    public static var qadaIntro: String { text("qadaIntro") }
    /// „Verpasster Zeitraum“
    public static var qadaCalc: String { text("qadaCalc") }
    /// „Jahre“
    public static var years: String { text("years") }
    /// „Monate“
    public static var months: String { text("months") }
    /// „Tage“
    public static var days: String { text("days") }
    /// „Witr einbeziehen“
    public static var witr: String { text("witr") }
    /// „Nach hanafitischer Lehre verpflichtend“
    public static var witrSub: String { text("witrSub") }
    /// „{d} Tage · {n} Gebete“
    public static func qadaResult(d: String, n: String) -> String { text("qadaResult", d, n) }
    /// „Als offen übernehmen“
    public static var qadaApply: String { text("qadaApply") }
    /// „Ersetzt die offenen Zahlen. Ein Jahr zählt 365 Tage, ein Monat 30.“
    public static var qadaApplyFooter: String { text("qadaApplyFooter") }
    /// „Gebete noch offen“
    public static var qadaOpen: String { text("qadaOpen") }
    /// „Nach Gebet“
    public static var qadaByPrayer: String { text("qadaByPrayer") }
    /// „{a} von {b} nachgeholt“
    public static func qadaDone(a: String, b: String) -> String { text("qadaDone", a, b) }
    /// „Ein {p} nachgeholt“
    public static func qadaMinus(p: String) -> String { text("qadaMinus", p) }
    /// „Ein {p} mehr offen“
    public static func qadaPlus(p: String) -> String { text("qadaPlus", p) }
    /// „Plan“
    public static var qadaPlan: String { text("qadaPlan") }
    /// „Pro Tag nachholen“
    public static var qadaPerDay: String { text("qadaPerDay") }
    /// „Voraussichtlich fertig: {date}“
    public static func qadaFinish(date: String) -> String { text("qadaFinish", date) }
    /// „Alles nachgeholt.“
    public static var qadaAllDone: String { text("qadaAllDone") }
    /// „Ob und wie verpasste Gebete nachzuholen sind, beantworten Gelehrte unterschiedlich. Frag im Zweifel deinen Imam.“
    public static var qadaFooter: String { text("qadaFooter") }
    /// „{n} Gebete als offen übernommen“
    public static func qadaApplied(n: String) -> String { text("qadaApplied", n) }
    /// „Witr“
    public static var p_witr: String { text("p_witr") }
    /// „{x} weniger“
    public static func stepLess(x: String) -> String { text("stepLess", x) }
    /// „{x} mehr“
    public static func stepMore(x: String) -> String { text("stepMore", x) }
    /// „nachgeholt“
    public static var qadaPctLabel: String { text("qadaPctLabel") }
    /// „Noch {n} offen“
    public static func qadaLeft(n: String) -> String { text("qadaLeft", n) }
    /// „Kerahat {r}“
    public static func kerahatRow(r: String) -> String { text("kerahatRow", r) }
    /// „Kerahat bis {b}“
    public static func kerahatNow(b: String) -> String { text("kerahatNow", b) }
    /// „Kerahat-Zeiten zeigen“
    public static var showKerahat: String { text("showKerahat") }
    /// „Im Bogen eingezeichnet, die Uhrzeiten stehen bei den Zeiten: etwa 45 Min. nach Sonnenaufgang, 10 Min. vor Dhuhr und 45 Min. vor Maghrib. Nach hanafitischer Lehre wird dann nicht gebetet (das Asr des Tages ausgenommen).“
    public static var kerahatFooter: String { text("kerahatFooter") }
    /// „Live-Aktivität“
    public static var liveAct: String { text("liveAct") }
    /// „Countdown zum nächsten Gebet auf dem Sperrbildschirm und in der Dynamic Island. Endet 15 Minuten nach Gebetsbeginn.“
    public static var liveActFooter: String { text("liveActFooter") }
    /// „Überspringen“
    public static var obSkip: String { text("obSkip") }
    /// „Weiter“
    public static var obContinue: String { text("obContinue") }
    /// „Gebetszeiten. Ruhig und genau.“
    public static var ob1Title: String { text("ob1Title") }
    /// „Werbefrei, ohne Tracking und gemeinnützig. Nur das, was du brauchst.“
    public static var ob1Body: String { text("ob1Body") }
    /// „Dein Standort bleibt auf dem iPhone“
    public static var ob2Title: String { text("ob2Title") }
    /// „Die Zeiten werden direkt auf deinem Gerät berechnet. Dein Standort wird nie gesendet oder gespeichert.“
    public static var ob2Body: String { text("ob2Body") }
    /// „Standort erlauben“
    public static var ob2Allow: String { text("ob2Allow") }
    /// „Stadt manuell wählen“
    public static var ob2Manual: String { text("ob2Manual") }
    /// „Eine ruhige Erinnerung zu jedem Gebet“
    public static var ob3Title: String { text("ob3Title") }
    /// „Adhan, stille Mitteilung oder nichts – pro Gebet. Jederzeit änderbar.“
    public static var ob3Body: String { text("ob3Body") }
    /// „Mitteilungen erlauben“
    public static var ob3Allow: String { text("ob3Allow") }
    /// „Später“
    public static var ob3Later: String { text("ob3Later") }
    /// „„Vaqt“ erlauben, deinen Standort zu verwenden?“
    public static var alLocTitle: String { text("alLocTitle") }
    /// „Dein Standort wird nur auf diesem Gerät zur Berechnung der Gebetszeiten verwendet.“
    public static var alLocBody: String { text("alLocBody") }
    /// „Einmal erlauben“
    public static var alLocOnce: String { text("alLocOnce") }
    /// „Beim Verwenden der App erlauben“
    public static var alLocWhile: String { text("alLocWhile") }
    /// „Nicht erlauben“
    public static var alLocDeny: String { text("alLocDeny") }
    /// „„Vaqt“ möchte dir Mitteilungen senden“
    public static var alNotTitle: String { text("alNotTitle") }
    /// „Mitteilungen können Hinweise, Töne und Kennzeichen enthalten.“
    public static var alNotBody: String { text("alNotBody") }
    /// „Erlauben“
    public static var alNotAllow: String { text("alNotAllow") }
    /// „Nicht erlauben“
    public static var alNotDeny: String { text("alNotDeny") }
    /// „Zeiten“
    public static var tabToday: String { text("tabToday") }
    /// „Qibla“
    public static var tabQibla: String { text("tabQibla") }
    /// „Einstellungen“
    public static var tabSettings: String { text("tabSettings") }
    /// „{p} in“
    public static func nextIn(p: String) -> String { text("nextIn", p) }
    /// „{p} (morgen) in“
    public static func nextInTomorrow(p: String) -> String { text("nextInTomorrow", p) }
    /// „Jetzt“
    public static var now: String { text("now") }
    /// „Offline · alles wird auf dem Gerät berechnet“
    public static var offline: String { text("offline") }
    /// „Standortzugriff aus – Stadt manuell gewählt“
    public static var locOffBanner: String { text("locOffBanner") }
    /// „Ändern“
    public static var change: String { text("change") }
    /// „manuell“
    public static var manual: String { text("manual") }
    /// „Hohe Breitengrade“
    public static var highLatTitle: String { text("highLatTitle") }
    /// „Im Sommer wird es in {city} nachts nicht ganz dunkel. Fadschr und Ischa werden mit der Regel „{rule}“ geschätzt.“
    public static func highLatNote(city: String, rule: String) -> String { text("highLatNote", city, rule) }
    /// „Regel ändern“
    public static var highLatLink: String { text("highLatLink") }
    /// „Für diesen Ort lassen sich heute keine Gebetszeiten berechnen, weil die Sonne nicht auf- oder untergeht.“
    public static var noTimes: String { text("noTimes") }
    /// „Ton“
    public static var bellSound: String { text("bellSound") }
    /// „Lautlos“
    public static var bellSilent: String { text("bellSilent") }
    /// „Aus“
    public static var bellOff: String { text("bellOff") }
    /// „Mitteilung für {p}: {s}. Tippen zum Ändern.“
    public static func bellAria(p: String, s: String) -> String { text("bellAria", p, s) }
    /// „{p}: {s}“
    public static func bellToast(p: String, s: String) -> String { text("bellToast", p, s) }
    /// „Fadschr“
    public static var p_fajr: String { text("p_fajr") }
    /// „Sonnenaufgang“
    public static var p_sunrise: String { text("p_sunrise") }
    /// „Dhuhr“
    public static var p_dhuhr: String { text("p_dhuhr") }
    /// „Asr“
    public static var p_asr: String { text("p_asr") }
    /// „Maghrib“
    public static var p_maghrib: String { text("p_maghrib") }
    /// „Ischa“
    public static var p_isha: String { text("p_isha") }
    /// „Berlin“
    public static var c_berlin: String { text("c_berlin") }
    /// „Istanbul“
    public static var c_istanbul: String { text("c_istanbul") }
    /// „Madrid“
    public static var c_madrid: String { text("c_madrid") }
    /// „Mekka“
    public static var c_mecca: String { text("c_mecca") }
    /// „Jakarta“
    public static var c_jakarta: String { text("c_jakarta") }
    /// „Einstellungen“
    public static var settings: String { text("settings") }
    /// „Standort“
    public static var secLocation: String { text("secLocation") }
    /// „Aktuellen Standort verwenden“
    public static var useLocation: String { text("useLocation") }
    /// „Stadt“
    public static var city: String { text("city") }
    /// „Dein Standort wird nur auf diesem Gerät verwendet.“
    public static var locFooter: String { text("locFooter") }
    /// „Der Standortzugriff ist aus. Erlaube ihn in den iOS-Einstellungen oder wähle eine Stadt.“
    public static var locDeniedFooter: String { text("locDeniedFooter") }
    /// „iOS-Einstellungen öffnen“
    public static var openIosSettings: String { text("openIosSettings") }
    /// „Berechnung“
    public static var secCalc: String { text("secCalc") }
    /// „Methode“
    public static var method: String { text("method") }
    /// „Automatisch“
    public static var auto: String { text("auto") }
    /// „Automatisch für {country}“
    public static func autoFor(country: String) -> String { text("autoFor", country) }
    /// „Asr“
    public static var asr: String { text("asr") }
    /// „Standard“
    public static var asrStd: String { text("asrStd") }
    /// „Schatten = Objektlänge (Schafiʿi, Maliki, Hanbali)“
    public static var asrStdSub: String { text("asrStdSub") }
    /// „Hanafi“
    public static var asrHanafi: String { text("asrHanafi") }
    /// „Doppelte Objektlänge (Hanafi)“
    public static var asrHanafiSub: String { text("asrHanafiSub") }
    /// „Hohe Breitengrade“
    public static var highLat: String { text("highLat") }
    /// „Winkelbasiert“
    public static var hlAngle: String { text("hlAngle") }
    /// „Nachtanteil nach Dämmerungswinkel – empfohlen“
    public static var hlAngleSub: String { text("hlAngleSub") }
    /// „Ein Siebtel der Nacht“
    public static var hlSeventh: String { text("hlSeventh") }
    /// „Fadschr/Ischa höchstens 1/7 der Nacht von Sonnenauf-/-untergang entfernt“
    public static var hlSeventhSub: String { text("hlSeventhSub") }
    /// „Nachtmitte“
    public static var hlMiddle: String { text("hlMiddle") }
    /// „Fadschr und Ischa nie über die Nachtmitte hinaus“
    public static var hlMiddleSub: String { text("hlMiddleSub") }
    /// „Gilt im Sommer ab etwa 48° Breite, z. B. in Deutschland.“
    public static var hlFooter: String { text("hlFooter") }
    /// „Bei Moonsighting gilt diese Regel nicht – die Methode legt Fadschr und Ischa je nach Jahreszeit selbst fest.“
    public static var hlMoonsighting: String { text("hlMoonsighting") }
    /// „Die Zeiten werden lokal auf dem Gerät berechnet.“
    public static var calcFooter: String { text("calcFooter") }
    /// „Berechnungsmethode“
    public static var methodTitle: String { text("methodTitle") }
    /// „Empfohlen“
    public static var recommended: String { text("recommended") }
    /// „Alle Methoden“
    public static var allMethods: String { text("allMethods") }
    /// „Suchen“
    public static var search: String { text("search") }
    /// „Keine Ergebnisse“
    public static var noResults: String { text("noResults") }
    /// „saisonal“
    public static var seasonal: String { text("seasonal") }
    /// „{n} Min. nach Maghrib“
    public static func minAfterMaghrib(n: String) -> String { text("minAfterMaghrib", n) }
    /// „Minutenkorrektur“
    public static var adjustments: String { text("adjustments") }
    /// „Keine“
    public static var adjNone: String { text("adjNone") }
    /// „{n} geändert“
    public static func adjChanged(n: String) -> String { text("adjChanged", n) }
    /// „Passe einzelne Zeiten an deine Moschee an.“
    public static var adjFooter: String { text("adjFooter") }
    /// „Zurücksetzen“
    public static var adjReset: String { text("adjReset") }
    /// „{n} Min.“
    public static func min(n: String) -> String { text("min", n) }
    /// „{p} eine Minute früher“
    public static func adjMinus(p: String) -> String { text("adjMinus", p) }
    /// „{p} eine Minute später“
    public static func adjPlus(p: String) -> String { text("adjPlus", p) }
    /// „Mitteilungen“
    public static var secNotif: String { text("secNotif") }
    /// „Pro Gebet“
    public static var perPrayer: String { text("perPrayer") }
    /// „„Ton“ spielt den gewählten Klang, „Lautlos“ zeigt nur die Mitteilung.“
    public static var perPrayerFooter: String { text("perPrayerFooter") }
    /// „Vorab-Erinnerung“
    public static var reminder: String { text("reminder") }
    /// „Aus“
    public static var off: String { text("off") }
    /// „{n} Min. vorher“
    public static func minBefore(n: String) -> String { text("minBefore", n) }
    /// „Klang“
    public static var sound: String { text("sound") }
    /// „Systemton“
    public static var soundSystem: String { text("soundSystem") }
    /// „Kurzer Adhan“
    public static var soundAdhan: String { text("soundAdhan") }
    /// „Lautlos“
    public static var soundSilent: String { text("soundSilent") }
    /// „iOS erlaubt Mitteilungstöne von höchstens 30 Sekunden.“
    public static var soundFooter: String { text("soundFooter") }
    /// „Adhan anhören“
    public static var previewAdhan: String { text("previewAdhan") }
    /// „{n} von 6“
    public static func ofN(n: String) -> String { text("ofN", n) }
    /// „Mitteilungen sind in den iOS-Einstellungen deaktiviert.“
    public static var notifDeniedFooter: String { text("notifDeniedFooter") }
    /// „Darstellung“
    public static var secAppearance: String { text("secAppearance") }
    /// „Erscheinungsbild“
    public static var appearance: String { text("appearance") }
    /// „System“
    public static var apSystem: String { text("apSystem") }
    /// „Hell“
    public static var apLight: String { text("apLight") }
    /// „Dunkel“
    public static var apDark: String { text("apDark") }
    /// „Sprache“
    public static var language: String { text("language") }
    /// „Über“
    public static var secAbout: String { text("secAbout") }
    /// „Quellcode“
    public static var source: String { text("source") }
    /// „Open Source auf GitHub“
    public static var sourceSub: String { text("sourceSub") }
    /// „Datenschutz“
    public static var privacy: String { text("privacy") }
    /// „Keine Daten erhoben“
    public static var privacyValue: String { text("privacyValue") }
    /// „Version“
    public static var version: String { text("version") }
    /// „Gebetszeiten sind Berechnungen und können um einige Minuten von den Zeiten deiner Moschee abweichen.“
    public static var disclaimer: String { text("disclaimer") }
    /// „Gemeinnützig · Werbefrei · Ohne Tracking“
    public static var tagline: String { text("tagline") }
    /// „Diese App erhebt keine Daten.“
    public static var privacyBody1: String { text("privacyBody1") }
    /// „Kein Konto, keine Werbung, keine Analyse-Tools. Dein Standort wird nur auf diesem Gerät zur Berechnung verwendet und verlässt es nie.“
    public static var privacyBody2: String { text("privacyBody2") }
    /// „App-Store-Datenschutzangabe: „Keine Daten erfasst“.“
    public static var privacyBody3: String { text("privacyBody3") }
    /// „Öffnet github.com/… (Prototyp)“
    public static var linkToast: String { text("linkToast") }
    /// „Öffnet die iOS-Einstellungen (Prototyp)“
    public static var settingsToast: String { text("settingsToast") }
    /// „Stadt wählen“
    public static var citySheetTitle: String { text("citySheetTitle") }
    /// „Abbrechen“
    public static var cancel: String { text("cancel") }
    /// „Stadt suchen“
    public static var searchCity: String { text("searchCity") }
    /// „Aktueller Standort“
    public static var currentLocation: String { text("currentLocation") }
    /// „Standortzugriff verweigert“
    public static var locDenied: String { text("locDenied") }
    /// „Offline: nur gespeicherte Städte“
    public static var offlineCities: String { text("offlineCities") }
    /// „Adhan“
    public static var adhan: String { text("adhan") }
    /// „Schließen“
    public static var close: String { text("close") }
    /// „Abspielen“
    public static var play: String { text("play") }
    /// „Pausieren“
    public static var pause: String { text("pause") }
    /// „Stimme“
    public static var voice: String { text("voice") }
    /// „Stimme {n}“
    public static func voiceN(n: String) -> String { text("voiceN", n) }
    /// „Platzhalter – endgültige Aufnahmen folgen.“
    public static var voiceFooter: String { text("voiceFooter") }
    /// „Fadschr-Variante“
    public static var fajrVariant: String { text("fajrVariant") }
    /// „Mit „Aṣ-ṣalātu khairun mina n-naum“ – „Das Gebet ist besser als Schlaf“.“
    public static var fajrVariantFooter: String { text("fajrVariantFooter") }
    /// „Kurzer Adhan · für Mitteilungen“
    public static var shortAdhan: String { text("shortAdhan") }
    /// „Wiedergabeposition“
    public static var progress: String { text("progress") }
    /// „Qibla“
    public static var qibla: String { text("qibla") }
    /// „Qibla {deg}° {dir}“
    public static func qiblaAt(deg: String, dir: String) -> String { text("qiblaAt", deg, dir) }
    /// „Du blickst Richtung Qibla“
    public static var facing: String { text("facing") }
    /// „Nach links drehen“
    public static var turnLeft: String { text("turnLeft") }
    /// „Nach rechts drehen“
    public static var turnRight: String { text("turnRight") }
    /// „{km} km bis zur Kaaba“
    public static func distance(km: String) -> String { text("distance", km) }
    /// „Kompass kalibrieren“
    public static var calibrate: String { text("calibrate") }
    /// „Bewege dein iPhone in Form einer Acht, bis die Anzeige ruhig wird.“
    public static var calibrateBody: String { text("calibrateBody") }
    /// „Du bist in Mekka – richte dich zur Kaaba aus.“
    public static var inMecca: String { text("inMecca") }
    /// „Kompass. Pfeiltasten drehen das Gerät (Simulation).“
    public static var dialAria: String { text("dialAria") }
    /// „Kein Kompass verfügbar“
    public static var noCompass: String { text("noCompass") }
    /// N · NO · O · SO · S · SW · W · NW
    public static var dirs: [String] { (0..<8).map { text("dirs.\($0)") } }
    /// „Nächstes“
    public static var wNext: String { text("wNext") }
    /// „in {t}“
    public static func wIn(t: String) -> String { text("wIn", t) }
    /// „{p} · {time}“
    public static func notifPrayerTitle(p: String, time: String) -> String { text("notifPrayerTitle", p, time) }
    /// „Zeit für {p} in {city}.“
    public static func notifPrayerBody(p: String, city: String) -> String { text("notifPrayerBody", p, city) }
    /// „{p} in {n} Minuten“
    public static func notifReminderTitle(p: String, n: String) -> String { text("notifReminderTitle", p, n) }
    /// „{p} beginnt um {time} Uhr.“
    public static func notifReminderBody(p: String, time: String) -> String { text("notifReminderBody", p, time) }
    /// „jetzt“
    public static var notifNow: String { text("notifNow") }
    /// „vor {n} Min.“
    public static func notifAgo(n: String) -> String { text("notifAgo", n) }
    /// „Std.“
    public static var hShort: String { text("hShort") }
    /// „Min.“
    public static var mShort: String { text("mShort") }
    /// „Kostenlos. Ohne Werbung.“
    public static var ob4Title: String { text("ob4Title") }
    /// „{app} ist kostenlos und bleibt es. Damit wir die App pflegen und weiterentwickeln können, kannst du uns bald mit einer Spende unterstützen. Freiwillig: Die App bleibt für alle vollständig.“
    public static func ob4Body(app: String) -> String { text("ob4Body", app) }
    /// „Keine Werbung“
    public static var ob4P1: String { text("ob4P1") }
    /// „Kein Tracking“
    public static var ob4P2: String { text("ob4P2") }
    /// „Kein Konto“
    public static var ob4P3: String { text("ob4P3") }
    /// „Los geht’s“
    public static var ob4Start: String { text("ob4Start") }
    /// „{app} unterstützen“
    public static func supportRow(app: String) -> String { text("supportRow", app) }
    /// „Kostenlos und werbefrei, dank Spenden“
    public static var supportRowSub: String { text("supportRowSub") }
    /// „Unterstützen“
    public static var supportTitle: String { text("supportTitle") }
    /// „{app} ist kostenlos, ohne Werbung und ohne Tracking. Damit das so bleibt, tragen Spenden die laufenden Kosten.“
    public static func supportLead(app: String) -> String { text("supportLead", app) }
    /// „Wofür Spenden gedacht sind“
    public static var supportWhat: String { text("supportWhat") }
    /// „Apple-Entwicklerkonto“
    public static var supAcc: String { text("supAcc") }
    /// „99 € im Jahr, damit die App im App Store bleibt“
    public static var supAccSub: String { text("supAccSub") }
    /// „Pflege“
    public static var supCare: String { text("supCare") }
    /// „Anpassungen an neue iOS-Versionen und Fehlerbehebungen“
    public static var supCareSub: String { text("supCareSub") }
    /// „Inhalte“
    public static var supContent: String { text("supContent") }
    /// „Übersetzungen, Adhan-Aufnahmen und die fachliche Prüfung der Anleitung“
    public static var supContentSub: String { text("supContentSub") }
    /// „Spenden sind bald möglich“
    public static var supportSoon: String { text("supportSoon") }
    /// „Die Möglichkeit zu spenden kommt mit einem der nächsten Updates. Bis dahin hilft es schon, wenn du die App weiterempfiehlst.“
    public static var supportSoonBody: String { text("supportSoonBody") }
    /// „App weiterempfehlen“
    public static var supportShare: String { text("supportShare") }
    /// „Spenden sind freiwillig. Alle Funktionen bleiben für alle kostenlos.“
    public static var supportFoot: String { text("supportFoot") }
    /// „Kerahat-Zeiten: {list}“
    public static func kerahatArc(list: String) -> String { text("kerahatArc", list) }
    /// „Im Toleranzbereich“
    public static var inTol: String { text("inTol") }
    /// „Der markierte Bereich reicht 40° zu jeder Seite der Qibla.“
    public static var tolLegend: String { text("tolLegend") }
    /// „Gebet Schritt für Schritt“
    public static var wkStart: String { text("wkStart") }
    /// „Haltung für Haltung durch alle {n} Rakʿas von {p}.“
    public static func wkStartSub(n: String, p: String) -> String { text("wkStartSub", n, p) }
    /// „Rakʿa {r} von {n}“
    public static func wkRak(r: String, n: String) -> String { text("wkRak", r, n) }
    /// „Schritt {i} von {k}“
    public static func wkStep(i: String, k: String) -> String { text("wkStep", i, k) }
    /// „Weiter“
    public static var wkNext: String { text("wkNext") }
    /// „Zurück“
    public static var wkPrev: String { text("wkPrev") }
    /// „Beginnen“
    public static var wkBegin: String { text("wkBegin") }
    /// „Fertig“
    public static var wkDone: String { text("wkDone") }
    /// „{p} · {n} Rakʿas“
    public static func wkIntroTitle(p: String, n: String) -> String { text("wkIntroTitle", p, n) }
    /// „Nimm die Gebetswaschung vor und stell dich in Richtung Qibla. Fasse im Herzen die Absicht für {p}. Dann geht es los.“
    public static func wkIntroBody(p: String) -> String { text("wkIntroBody", p) }
    /// „Lies al-Fātiha, danach eine weitere Sure.“
    public static var wkQiyam12: String { text("wkQiyam12") }
    /// „Stirn, Nase, Hände, Knie und Zehen auf dem Boden. Sprich dreimal:“
    public static var wkSujudD: String { text("wkSujudD") }
    /// „Kurz sitzen“
    public static var wkJalsa: String { text("wkJalsa") }
    /// „Richte dich zum Sitzen auf und komm kurz zur Ruhe.“
    public static var wkJalsaD: String { text("wkJalsaD") }
    /// „Zweite Niederwerfung“
    public static var wkSujud2: String { text("wkSujud2") }
    /// „Wirf dich ein zweites Mal nieder und sprich wieder dreimal:“
    public static var wkSujud2D: String { text("wkSujud2D") }
    /// „Erstes Sitzen“
    public static var wkTashFirst: String { text("wkTashFirst") }
    /// „Lies at-Tahiyyāt, dann steh zur 3. Rakʿa auf.“
    public static var wkTashFirstD: String { text("wkTashFirstD") }
    /// „Letztes Sitzen“
    public static var wkTashLast: String { text("wkTashLast") }
    /// „Lies at-Tahiyyāt, danach das Segensgebet und ein Bittgebet.“
    public static var wkTashLastD: String { text("wkTashLastD") }
    /// „Gebet beendet“
    public static var wkDoneTitle: String { text("wkDoneTitle") }
    /// „Möge Allah dein Gebet annehmen.“
    public static var wkDoneBody: String { text("wkDoneBody") }
    /// „Nachholgebete berechnen“
    public static var qcTitle: String { text("qcTitle") }
    /// „Wie lange hast du nicht regelmäßig gebetet? Ein ungefährer Zeitraum reicht.“
    public static var qcLead: String { text("qcLead") }
    /// „Zeitraum“
    public static var qcStep1: String { text("qcStep1") }
    /// „Witr“
    public static var qcStep2: String { text("qcStep2") }
    /// „Ergebnis“
    public static var qcStep3: String { text("qcStep3") }
    /// „Gebete nachzuholen“
    public static var qcResultUnit: String { text("qcResultUnit") }
    /// „{d} Tage × {k} Gebete“
    public static func qcResultDetail(d: String, k: String) -> String { text("qcResultDetail", d, k) }
    /// „Zurück zu heute“
    public static var backToToday: String { text("backToToday") }
    /// „Vorheriger Tag“
    public static var dayPrev: String { text("dayPrev") }
    /// „Nächster Tag“
    public static var dayNext: String { text("dayNext") }
    /// „Manuelle Winkel“
    public static var hlManual: String { text("hlManual") }
    /// „Eigene Dämmerungswinkel für Fadschr und Ischa“
    public static var hlManualSub: String { text("hlManualSub") }
    /// „Dämmerungswinkel“
    public static var hlDegHeader: String { text("hlDegHeader") }
    /// „Erreicht die Sonne den eingestellten Winkel nicht, gilt der entsprechende Anteil der Nacht (Winkel ÷ 60).“
    public static var hlManualFooter: String { text("hlManualFooter") }
    /// „Lizenzen“
    public static var licenses: String { text("licenses") }
    /// „Schrift der Verse und Formeln“
    public static var licAmiriSub: String { text("licAmiriSub") }
    /// „Berechnung der Gebetszeiten“
    public static var licAdhanSub: String { text("licAdhanSub") }
    /// „Die App enthält freie Software und Schriften. Die Lizenztexte stehen im englischen Original.“
    public static var licensesFooter: String { text("licensesFooter") }

    /// Name einer Sure aus `SURAH` im Prototyp, z. B. „Al-Baqara“ für 2.
    public static func surahName(_ surah: Int) -> String { text("surah_\(surah)") }
    /// Übersetzung eines Verses aus `VERSES` im Prototyp, z. B. „Sucht Hilfe in der Geduld und im Gebet.“ für 2:45.
    /// TODO(placeholder): ein Platzhalter – die lizenzierte Übersetzung fehlt noch (Spec § 6.12).
    public static func verseTranslation(surah: Int, ayah: Int) -> String { text("verse_\(surah)_\(ayah)") }

    /// Alle Schlüssel des String Catalogs, in der Reihenfolge des Prototyps.
    public static let allKeys: [String] = [
        "appName",
        "back",
        "navPrayers",
        "navVerses",
        "navQada",
        "guideChip",
        "guideNext",
        "guideBack",
        "rakFard",
        "recite",
        "recAloud",
        "recSilent",
        "recMixed",
        "sunna",
        "sunna_fajr",
        "sunna_dhuhr",
        "sunna_asr",
        "sunna_maghrib",
        "sunna_isha",
        "onlyFatiha",
        "tashSit",
        "tashEnd",
        "rakSeq",
        "beforeTitle",
        "stepsTitle",
        "b_wudu",
        "b_wuduD",
        "b_clean",
        "b_cleanD",
        "b_qibla",
        "b_qiblaD",
        "b_qiblaBtn",
        "b_niyya",
        "b_niyyaD",
        "s_takbir",
        "s_takbirD",
        "s_qiyam",
        "s_qiyamD",
        "s_ruku",
        "s_rukuD",
        "s_itidal",
        "s_itidalD",
        "s_sujud",
        "s_sujudD",
        "s_tash",
        "s_tashD",
        "s_salam",
        "s_salamD",
        "repeatNote",
        "guideFooter",
        "arcPrayers",
        "verseToday",
        "versePrev",
        "share",
        "copy",
        "copied",
        "shareToast",
        "verseSource",
        "today",
        "yesterday",
        "qadaIntro",
        "qadaCalc",
        "years",
        "months",
        "days",
        "witr",
        "witrSub",
        "qadaResult",
        "qadaApply",
        "qadaApplyFooter",
        "qadaOpen",
        "qadaByPrayer",
        "qadaDone",
        "qadaMinus",
        "qadaPlus",
        "qadaPlan",
        "qadaPerDay",
        "qadaFinish",
        "qadaAllDone",
        "qadaFooter",
        "qadaApplied",
        "p_witr",
        "stepLess",
        "stepMore",
        "qadaPctLabel",
        "qadaLeft",
        "kerahatRow",
        "kerahatNow",
        "showKerahat",
        "kerahatFooter",
        "liveAct",
        "liveActFooter",
        "obSkip",
        "obContinue",
        "ob1Title",
        "ob1Body",
        "ob2Title",
        "ob2Body",
        "ob2Allow",
        "ob2Manual",
        "ob3Title",
        "ob3Body",
        "ob3Allow",
        "ob3Later",
        "alLocTitle",
        "alLocBody",
        "alLocOnce",
        "alLocWhile",
        "alLocDeny",
        "alNotTitle",
        "alNotBody",
        "alNotAllow",
        "alNotDeny",
        "tabToday",
        "tabQibla",
        "tabSettings",
        "nextIn",
        "nextInTomorrow",
        "now",
        "offline",
        "locOffBanner",
        "change",
        "manual",
        "highLatTitle",
        "highLatNote",
        "highLatLink",
        "noTimes",
        "bellSound",
        "bellSilent",
        "bellOff",
        "bellAria",
        "bellToast",
        "p_fajr",
        "p_sunrise",
        "p_dhuhr",
        "p_asr",
        "p_maghrib",
        "p_isha",
        "c_berlin",
        "c_istanbul",
        "c_madrid",
        "c_mecca",
        "c_jakarta",
        "settings",
        "secLocation",
        "useLocation",
        "city",
        "locFooter",
        "locDeniedFooter",
        "openIosSettings",
        "secCalc",
        "method",
        "auto",
        "autoFor",
        "asr",
        "asrStd",
        "asrStdSub",
        "asrHanafi",
        "asrHanafiSub",
        "highLat",
        "hlAngle",
        "hlAngleSub",
        "hlSeventh",
        "hlSeventhSub",
        "hlMiddle",
        "hlMiddleSub",
        "hlFooter",
        "hlMoonsighting",
        "calcFooter",
        "methodTitle",
        "recommended",
        "allMethods",
        "search",
        "noResults",
        "seasonal",
        "minAfterMaghrib",
        "adjustments",
        "adjNone",
        "adjChanged",
        "adjFooter",
        "adjReset",
        "min",
        "adjMinus",
        "adjPlus",
        "secNotif",
        "perPrayer",
        "perPrayerFooter",
        "reminder",
        "off",
        "minBefore",
        "sound",
        "soundSystem",
        "soundAdhan",
        "soundSilent",
        "soundFooter",
        "previewAdhan",
        "ofN",
        "notifDeniedFooter",
        "secAppearance",
        "appearance",
        "apSystem",
        "apLight",
        "apDark",
        "language",
        "secAbout",
        "source",
        "sourceSub",
        "privacy",
        "privacyValue",
        "version",
        "disclaimer",
        "tagline",
        "privacyBody1",
        "privacyBody2",
        "privacyBody3",
        "linkToast",
        "settingsToast",
        "citySheetTitle",
        "cancel",
        "searchCity",
        "currentLocation",
        "locDenied",
        "offlineCities",
        "adhan",
        "close",
        "play",
        "pause",
        "voice",
        "voiceN",
        "voiceFooter",
        "fajrVariant",
        "fajrVariantFooter",
        "shortAdhan",
        "progress",
        "qibla",
        "qiblaAt",
        "facing",
        "turnLeft",
        "turnRight",
        "distance",
        "calibrate",
        "calibrateBody",
        "inMecca",
        "dialAria",
        "noCompass",
        "dirs.0",
        "dirs.1",
        "dirs.2",
        "dirs.3",
        "dirs.4",
        "dirs.5",
        "dirs.6",
        "dirs.7",
        "wNext",
        "wIn",
        "notifPrayerTitle",
        "notifPrayerBody",
        "notifReminderTitle",
        "notifReminderBody",
        "notifNow",
        "notifAgo",
        "hShort",
        "mShort",
        "ob4Title",
        "ob4Body",
        "ob4P1",
        "ob4P2",
        "ob4P3",
        "ob4Start",
        "supportRow",
        "supportRowSub",
        "supportTitle",
        "supportLead",
        "supportWhat",
        "supAcc",
        "supAccSub",
        "supCare",
        "supCareSub",
        "supContent",
        "supContentSub",
        "supportSoon",
        "supportSoonBody",
        "supportShare",
        "supportFoot",
        "kerahatArc",
        "inTol",
        "tolLegend",
        "wkStart",
        "wkStartSub",
        "wkRak",
        "wkStep",
        "wkNext",
        "wkPrev",
        "wkBegin",
        "wkDone",
        "wkIntroTitle",
        "wkIntroBody",
        "wkQiyam12",
        "wkSujudD",
        "wkJalsa",
        "wkJalsaD",
        "wkSujud2",
        "wkSujud2D",
        "wkTashFirst",
        "wkTashFirstD",
        "wkTashLast",
        "wkTashLastD",
        "wkDoneTitle",
        "wkDoneBody",
        "qcTitle",
        "qcLead",
        "qcStep1",
        "qcStep2",
        "qcStep3",
        "qcResultUnit",
        "qcResultDetail",
        "backToToday",
        "dayPrev",
        "dayNext",
        "hlManual",
        "hlManualSub",
        "hlDegHeader",
        "hlManualFooter",
        "licenses",
        "licAmiriSub",
        "licAdhanSub",
        "licensesFooter",
        "surah_2",
        "surah_13",
        "surah_20",
        "surah_94",
        "verse_2_45",
        "verse_94_5",
        "verse_13_28",
        "verse_2_152",
        "verse_20_14",
        "verse_2_286",
    ]
}
