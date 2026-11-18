import Foundation
import PrayerCore
import Testing
@testable import DesignSystem

/// Prüft den gebauten String Catalog: Die Texte müssen im Paket-Bundle liegen und in allen
/// 16 Sprachen vollständig sein (Spec § 9.10). Ob der Katalog zum Prototyp passt, prüft
/// `scripts/import-strings --check`.
@Suite("String Catalog")
struct L10nTests {

    static let languages = AppLanguage.allCases.map(\.rawValue)

    /// Das Teil-Bundle einer Sprache – unabhängig von der Sprache des Simulators.
    private func bundle(for language: String) throws -> Bundle {
        let url = try #require(L10n.bundle.url(forResource: language, withExtension: "lproj"), "\(language).lproj fehlt")
        return try #require(Bundle(url: url))
    }

    private func text(_ key: String, in language: String) throws -> String {
        try bundle(for: language).localizedString(forKey: key, value: nil, table: nil)
    }

    @Test("Datum und Zahlen folgen der Sprache der Texte, mit der Region des Geräts, wenn sie passt", arguments: [
        ("de", "de_AT", "de_AT"),
        ("de", "fr_FR", "de_DE"),
        ("tr", "tr_TR", "tr_TR"),
        ("en", "en_US", "en_US"),
        ("en", "de_DE", "en_GB"),
        ("es", "it_IT", "es_ES"),
        ("ar", "de_DE", "ar"),
        ("ar", "ar_SA", "ar_SA"),
        ("fa", "en_US", "fa_IR"),
        ("bn", "de_DE", "bn_BD"),
        ("xx", "it_IT", "de_DE"),
    ])
    func locale(language: String, device: String, expected: String) {
        let locale = L10n.locale(language: language, device: Locale(identifier: device))
        #expect(locale.identifier == expected)
    }

    @Test("die Sprache der Texte ist eine der 16 der App, jede mit ihrer Region aus `LOC`")
    func currentLocale() {
        #expect(L10n.regions.keys.sorted() == Self.languages.sorted())
        #expect(Self.languages.contains(L10n.locale.language.languageCode?.identifier ?? ""))
    }

    @Test("die Sprachen der App heißen wie LANG_NAMES im Prototyp")
    func languageNames() {
        #expect(AppLanguage.allCases.map(\.rawValue) == [
            "de", "tr", "en", "es", "fr", "nl", "bs", "sq", "ar", "ur", "id", "ms", "bn", "fa", "ru", "it",
        ])
        #expect(AppLanguage.allCases.map(\.name) == [
            "Deutsch", "Türkçe", "English", "Español", "Français", "Nederlands", "Bosanski", "Shqip", "العربية",
            "اردو", "Bahasa Indonesia", "Bahasa Melayu", "বাংলা", "فارسی", "Русский", "Italiano",
        ])
    }

    @Test("eine in der App gewählte Sprache liest ihre Texte aus ihrem Teil-Bundle", arguments: [
        (AppLanguage.de, "Fadschr"), (.tr, "İmsak"), (.en, "Fajr"), (.es, "Fajr"), (.bs, "Sabah"), (.ar, "الفجر"),
        (.id, "Subuh"), (.bn, "ফজর"), (.fa, "صبح"), (.ru, "Фаджр"),
    ])
    func chosenLanguageBundle(language: AppLanguage, fajr: String) {
        let bundle = L10n.textBundle(for: language)
        #expect(bundle.localizedString(forKey: "p_fajr", value: nil, table: nil) == fajr)
        #expect(bundle.localizedString(forKey: "language", value: nil, table: nil) != "language")
    }

    @Test("ohne gewählte Sprache gilt das Bundle des Pakets, und die Sprache ist die des Systems")
    func systemLanguage() {
        #expect(L10n.textBundle(for: nil) == L10n.bundle)
        #expect(AppLanguage.allCases.contains(L10n.systemLanguage))
    }

    @Test("der Katalog hat 337 Schlüssel und keinen doppelt")
    func keyCount() {
        // 260 aus der Design-Übergabe v0.7, dazu `noTimes` (Phase 3), `noCompass` (Phase 4) und
        // `hlMoonsighting` (Phase 7, docs/OPEN-QUESTIONS.md), dazu aus `SURAH` und `VERSES` vier Suren und
        // sechs Verse (Phase 6); seit Phase 12 die 60 Nachträge vom 15.11.2026 (Spec § 9); seit Phase 13
        // die vier Texte der Seite „Lizenzen“ (Spec § 9.7); seit Phase 16 die 37 Nachträge vom 17./18.11.2026
        // (Spec § 10, davon elf für den Wecker aus Phase 17).
        #expect(L10n.allKeys.count == 374)
        #expect(Set(L10n.allKeys).count == L10n.allKeys.count)
    }

    @Test("jeder Vers hat seine Übersetzung und den Namen seiner Sure in jeder Sprache", arguments: languages)
    func verses(language: String) throws {
        let bundle = try bundle(for: language)
        let marker = "\u{1}fehlt"
        for verse in Verse.all {
            for key in ["verse_\(verse.surah)_\(verse.ayah)", "surah_\(verse.surah)"] {
                #expect(L10n.allKeys.contains(key), "\(key) fehlt in L10n.allKeys")
                #expect(bundle.localizedString(forKey: key, value: marker, table: nil) != marker, "\(language): \(key)")
            }
        }
    }

    @Test("Übersetzung und Sure wie im Prototyp", arguments: [
        ("de", "Sucht Hilfe in der Geduld und im Gebet.", "Al-Baqara", "Asch-Scharh"),
        ("tr", "Sabır ve namaz ile yardım dileyin.", "Bakara", "İnşirâh"),
        ("en", "Seek help through patience and prayer.", "Al-Baqarah", "Ash-Sharh"),
        ("es", "Buscad ayuda en la paciencia y en la oración.", "Al-Baqara", "Ash-Sharh"),
        // Ohne eigene Übersetzung: Englisch; Arabisch ohne Übersetzung, der Vers steht ja da (Spec § 9.10).
        ("fr", "Seek help through patience and prayer.", "Al-Baqarah", "Ash-Sharh"),
        ("ru", "Seek help through patience and prayer.", "Al-Baqarah", "Ash-Sharh"),
        ("ar", "", "Al-Baqarah", "Ash-Sharh"),
    ])
    func verseTexts(language: String, translation: String, surah2: String, surah94: String) throws {
        #expect(try text("verse_2_45", in: language) == translation)
        #expect(try text("surah_2", in: language) == surah2)
        #expect(try text("surah_94", in: language) == surah94)
    }

    @Test("L10n liest Verse und Suren über ihre Stelle")
    func verseAccessors() {
        #expect(L10n.verseTranslation(surah: 2, ayah: 45) != "verse_2_45")
        #expect(L10n.surahName(94) != "surah_94")
        #expect(!L10n.verseTranslation(surah: 2, ayah: 45).isEmpty)
    }

    @Test("jeder Schlüssel hat in jeder Sprache einen Text", arguments: languages)
    func complete(language: String) throws {
        let bundle = try bundle(for: language)
        let marker = "\u{1}fehlt"
        let missing = L10n.allKeys.filter { bundle.localizedString(forKey: $0, value: marker, table: nil) == marker }
        #expect(missing.isEmpty, "\(language): \(missing)")
    }

    @Test("kein Text enthält noch einen Platzhalter in geschweiften Klammern", arguments: languages)
    func noRawPlaceholders(language: String) throws {
        let bundle = try bundle(for: language)
        let leftovers = L10n.allKeys.filter {
            bundle.localizedString(forKey: $0, value: nil, table: nil).contains(/\{[A-Za-z0-9_]+\}/)
        }
        #expect(leftovers.isEmpty, "\(language): \(leftovers)")
    }

    @Test("die Tabs heißen wie im Prototyp", arguments: [
        ("de", ["Gebete", "Verse", "Nachholen"]),
        ("tr", ["Namaz", "Ayetler", "Kaza"]),
        ("en", ["Prayers", "Verses", "Make Up"]),
        ("es", ["Oraciones", "Versículos", "Recuperar"]),
        ("fr", ["Prières", "Versets", "Rattrapage"]),
        ("ar", ["الصلوات", "الآيات", "القضاء"]),
        ("bn", ["নামাজ", "আয়াত", "কাযা"]),
        ("ru", ["Намазы", "Аяты", "Восполнение"]),
    ])
    func tabTitles(language: String, expected: [String]) throws {
        let actual = try ["navPrayers", "navVerses", "navQada"].map { try text($0, in: language) }
        #expect(actual == expected)
    }

    @Test("der Hinweis für Geräte ohne Kompass steht in DE/TR/EN/ES wie im Prototyp", arguments: [
        ("de", "Kein Kompass verfügbar"),
        ("tr", "Pusula kullanılamıyor"),
        ("en", "No compass available"),
        ("es", "Brújula no disponible"),
    ])
    func noCompass(language: String, expected: String) throws {
        #expect(try text("noCompass", in: language) == expected)
    }

    @Test("ein Argument wird eingesetzt")
    func singleArgument() throws {
        #expect(String(format: try text("wIn", in: "de"), "2:01") == "in 2:01")
        #expect(String(format: try text("wIn", in: "tr"), "2:01") == "2:01 sonra")
    }

    @Test("mehrere Argumente behalten ihre Bedeutung, auch wenn eine Sprache sie umstellt")
    func argumentOrder() throws {
        let arguments = ["Asr", "Berlin"]
        #expect(String(format: try text("notifPrayerBody", in: "de"), arguments: arguments) == "Zeit für Asr in Berlin.")
        #expect(String(format: try text("notifPrayerBody", in: "tr"), arguments: arguments) == "Berlin için Asr vakti girdi.")
    }

    @Test("die Himmelsrichtungen stehen einzeln im Katalog")
    func directions() throws {
        let german = try (0..<8).map { try text("dirs.\($0)", in: "de") }
        #expect(german == ["N", "NO", "O", "SO", "S", "SW", "W", "NW"])
        let turkish = try (0..<8).map { try text("dirs.\($0)", in: "tr") }
        #expect(turkish == ["K", "KD", "D", "GD", "G", "GB", "B", "KB"])
    }

    @Test("L10n liest aus dem Katalog statt den Schlüssel zurückzugeben")
    func accessors() {
        #expect(!L10n.navPrayers.isEmpty)
        #expect(L10n.navPrayers != "navPrayers")
        #expect(L10n.dirs.count == 8)
        #expect(!L10n.dirs.contains { $0.hasPrefix("dirs.") })
    }

    @Test("L10n setzt Argumente ein")
    func accessorArguments() {
        #expect(L10n.wIn(t: "2:01").contains("2:01"))
        let body = L10n.notifPrayerBody(p: "Asr", city: "Berlin")
        #expect(body.contains("Asr") && body.contains("Berlin"))
        #expect(!body.contains("%"))
    }

    // MARK: - Phase 15: Mehrzahl, Ziffern, Leserichtung, Kalender

    /// Ein Text wie `L10n.text` in einer Sprache und Region – ohne die Wahl der App zu ändern.
    private func formatted(_ key: String, _ language: AppLanguage, locale: String, _ arguments: any CVarArg...) -> String {
        L10n.text(key, arguments: arguments, bundle: L10n.textBundle(for: language), locale: Locale(identifier: locale))
            .replacingOccurrences(of: "\u{2068}", with: "").replacingOccurrences(of: "\u{2069}", with: "")
    }

    @Test("Mehrzahl im Rechner: „{d} Tage × {k} Gebete“ nach den Regeln der Sprache", arguments: [
        (AppLanguage.de, "de_DE", 1, "1 Tag × 5 Gebete"), (.de, "de_DE", 2, "2 Tage × 5 Gebete"),
        (.en, "en_GB", 1, "1 day × 5 prayers"), (.fr, "fr_FR", 1, "1 jour × 5 prières"),
        (.ru, "ru_RU", 1, "1 день × 5 намазов"), (.ru, "ru_RU", 2, "2 дня × 5 намазов"),
        (.ru, "ru_RU", 5, "5 дней × 5 намазов"), (.ru, "ru_RU", 11, "11 дней × 5 намазов"),
        (.ru, "ru_RU", 21, "21 день × 5 намазов"), (.ru, "ru_RU", 22, "22 дня × 5 намазов"),
        (.bs, "bs_BA", 1, "1 dan × 5 namaza"), (.bs, "bs_BA", 3, "3 dana × 5 namaza"),
        (.bs, "bs_BA", 21, "21 dan × 5 namaza"),
        (.ar, "ar", 1, "يوم واحد × 5 صلوات"), (.ar, "ar", 2, "يومان × 5 صلوات"), (.ar, "ar", 3, "3 أيام × 5 صلوات"),
        (.ar, "ar", 11, "11 يومًا × 5 صلوات"), (.ar, "ar", 100, "100 يوم × 5 صلوات"),
        (.tr, "tr_TR", 1, "1 gün × 5 namaz"), (.fa, "fa_IR", 2, "۲ روز × ۵ نماز"),
    ])
    func pluralCalculator(language: AppLanguage, locale: String, days: Int, expected: String) {
        #expect(formatted("qcResultDetail", language, locale: locale, days, 5) == expected)
    }

    @Test("Mehrzahl ohne Zahl im Text: die Einheit unter der großen Zahl", arguments: [
        (AppLanguage.de, "de_DE", 30, "Gebete nachzuholen"), (.ru, "ru_RU", 30, "намазов к восполнению"),
        (.ru, "ru_RU", 24, "намаза к восполнению"), (.ar, "ar", 5, "صلوات للقضاء"), (.ar, "ar", 30, "صلاة للقضاء"),
        (.tr, "tr_TR", 30, "kaza namazı"),
    ])
    func pluralUnit(language: AppLanguage, locale: String, count: Int, expected: String) {
        #expect(formatted("qcResultUnit", language, locale: locale, count) == expected)
    }

    @Test("Arabisch: der Dual bei zwei Rakʿas", arguments: [
        (2, "ركعتا فرض"), (3, "ركعات فرض"), (4, "ركعات فرض"),
    ])
    func arabicDual(rakahs: Int, expected: String) {
        #expect(formatted("rakFard", .ar, locale: "ar", rakahs) == expected)
        #expect(formatted("wkIntroTitle", .ar, locale: "ar", "الظهر", 2) == "الظهر · ركعتان")
    }

    @Test("Ziffern wie das System: Persisch ۰–۹, Arabisch nach Region, sonst 0–9", arguments: [
        ("de_DE", "14:25"), ("fa_IR", "۱۴:۲۵"), ("fa_AF", "۱۴:۲۵"), ("ar_SA", "١٤:٢٥"), ("ar_EG", "١٤:٢٥"),
        ("ar", "14:25"), ("ar_DE", "14:25"), ("ur_PK", "14:25"), ("bn_BD", "14:25"), ("ru_RU", "14:25"),
    ])
    func digits(locale: String, expected: String) {
        #expect(LocalizedDigits.apply(to: "14:25", locale: Locale(identifier: locale)) == expected)
    }

    @Test("die Ziffern im Text folgen der Region, auch die festen wie „von 5“")
    func digitsInText() {
        #expect(formatted("ofN", .fa, locale: "fa_IR", "3") == "۳ از ۶")
        #expect(formatted("ofN", .ar, locale: "ar_SA", "3") == "٣ من ٦")
        #expect(formatted("ofN", .ar, locale: "ar", "3") == "3 من 6")
        #expect(formatted("qcResultDetail", .ar, locale: "ar_SA", 21, 5) == "٢١ يومًا × ٥ صلوات")
    }

    @Test("Arabisch, Urdu und Persisch laufen von rechts nach links, die übrigen von links nach rechts")
    func rightToLeft() {
        #expect(AppLanguage.allCases.filter(\.isRightToLeft) == [.ar, .ur, .fa])
    }

    @Test("Kalender der Datumszeile: der der Region, ein islamischer bleibt gregorianisch", arguments: [
        ("de_DE", Calendar.Identifier.gregorian), ("fa_IR", .persian), ("fa_AF", .persian), ("ar_SA", .gregorian),
        ("ar_EG", .gregorian), ("ar", .gregorian), ("ur_PK", .gregorian),
    ])
    func displayCalendar(locale: String, expected: Calendar.Identifier) {
        #expect(L10n.displayCalendar(for: Locale(identifier: locale)).identifier == expected)
    }

    @Test("Uhrzeiten und Zahlen der App in den Ziffern der Sprache – auf dem Simulator Deutsch, also 0–9")
    func timeAndNumber() throws {
        let time = try #require(ClockTime("05:16"))
        #expect(L10n.time(time) == LocalizedDigits.apply(to: "05:16", locale: L10n.locale))
        #expect(L10n.number(12) == LocalizedDigits.apply(to: "12", locale: L10n.locale))
    }
}
