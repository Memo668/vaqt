import CoreText
import PrayerCore
import SwiftUI
import Testing
import UIKit
@testable import DesignSystem

/// „Gebet Schritt für Schritt“ (Spec § 9.6) und die arabischen Schriften (Spec § 9.7): Texte, Maße und
/// die eingebetteten Schriften Amiri und Amiri Quran.
@Suite("Schritt für Schritt – Bausteine")
struct WalkComponentTests {

    private func walk(_ prayer: Prayer) throws -> GuideWalk {
        try #require(GuideWalk(prayer: prayer))
    }

    // MARK: - Schrift

    @Test("Amiri und Amiri Quran liegen im Bündel und sind registriert", arguments: ArabicFont.allCases)
    func fontRegistered(typeface: ArabicFont) throws {
        ArabicFont.registerIfNeeded()
        #expect(ArabicFont.isRegistered)
        #expect(Bundle.module.url(forResource: typeface.fileName, withExtension: "ttf") != nil)
        let font = try #require(UIFont(name: typeface.postScriptName, size: 100))
        #expect(font.fontName == typeface.postScriptName)
    }

    @Test("Höhe der Schrift wie in den Dateien (Ober- plus Unterlänge)", arguments: ArabicFont.allCases)
    func fontMetrics(typeface: ArabicFont) throws {
        ArabicFont.registerIfNeeded()
        let font = CTFontCreateWithName(typeface.postScriptName as CFString, 1000, nil)
        #expect(CTFontCopyPostScriptName(font) as String == typeface.postScriptName)
        #expect(abs(CTFontGetAscent(font) + CTFontGetDescent(font) - typeface.naturalLineHeight * 1000) < 1)
        #expect(abs(CTFontGetAscent(font) - typeface.ascent * 1000) < 1)
    }

    @Test("Release 1.003 von aliftype/amiri")
    func fontVersion() throws {
        ArabicFont.registerIfNeeded()
        for typeface in ArabicFont.allCases {
            let font = CTFontCreateWithName(typeface.postScriptName as CFString, 12, nil)
            let version = try #require(CTFontCopyName(font, kCTFontVersionNameKey) as String?)
            #expect(version == "Version 1.003")
        }
    }

    @Test("Lizenztexte für die Seite Lizenzen liegen bei: SIL OFL 1.1 und MIT")
    func licenseTexts() throws {
        let ofl = try String(contentsOf: try #require(Bundle.module.url(forResource: "Amiri-OFL", withExtension: "txt")), encoding: .utf8)
        #expect(ofl.hasPrefix("Copyright 2010-2022 The Amiri Project Authors"))
        #expect(ofl.contains("SIL OPEN FONT LICENSE Version 1.1"))
        let mit = try String(contentsOf: try #require(Bundle.module.url(forResource: "AdhanSwift-LICENSE", withExtension: "txt")), encoding: .utf8)
        #expect(mit.hasPrefix("The MIT License (MIT)"))
        #expect(mit.contains("Copyright (c) 2016 Batoul Apps"))
    }

    @Test("Größen der arabischen Schrift wie im Prototyp v0.8")
    func arabicSizes() {
        #expect(FormulaMetrics.arabicSize == 23)
        #expect(FormulaMetrics.arabicLineHeight == 1.85)
        #expect(VerseCardMetrics.arabicSize == 31)
        #expect(VerseCardMetrics.arabicLineHeight == 2.15)
        #expect(WalkPageMetrics.arabicSize == 27)
        #expect(WalkPageMetrics.arabicLineHeight == 1.9)
    }

    // MARK: - Texte

    @Test("Titel und Anweisung je Schritt wie `WALK`")
    func stepTexts() throws {
        let dhuhr = try walk(.dhuhr)
        let titles = dhuhr.steps.dropFirst().dropLast().prefix(8).map(\.localizedTitle)
        #expect(titles == [
            L10n.s_takbir, L10n.s_qiyam, L10n.s_ruku, L10n.s_itidal, L10n.s_sujud, L10n.wkJalsa, L10n.wkSujud2,
            L10n.s_qiyam,
        ])
        #expect(dhuhr.step(at: 1).localizedText == L10n.s_takbirD)
        #expect(dhuhr.step(at: 5).localizedText == L10n.wkSujudD)
        #expect(dhuhr.step(at: 6).localizedText == L10n.wkJalsaD)
        #expect(dhuhr.step(at: 7).localizedText == L10n.wkSujud2D)
        #expect(dhuhr.step(at: 14).localizedTitle == L10n.wkTashFirst)
        #expect(dhuhr.step(at: 14).localizedText == L10n.wkTashFirstD)
        #expect(dhuhr.step(at: 27).localizedTitle == L10n.wkTashLast)
        #expect(dhuhr.step(at: 27).localizedText == L10n.wkTashLastD)
        #expect(dhuhr.step(at: 28).localizedText == L10n.s_salamD)
        #expect(dhuhr.step(at: 29).localizedTitle == L10n.wkDoneTitle)
        #expect(dhuhr.step(at: 29).localizedText == L10n.wkDoneBody)
    }

    @Test("Stehen: in Rakʿa 1–2 al-Fātiḥa und eine Sure, ab der 3. nur al-Fātiḥa; Marke laut/leise")
    func qiyamTexts() throws {
        let isha = try walk(.isha)
        let qiyam = isha.steps.filter { $0.kind == .qiyam }
        #expect(qiyam.map(\.localizedText) == [L10n.wkQiyam12, L10n.wkQiyam12, L10n.onlyFatiha, L10n.onlyFatiha])
        #expect(qiyam.map(\.localizedRecitationTag) == [
            "\(L10n.recite): \(L10n.recAloud)", "\(L10n.recite): \(L10n.recAloud)",
            "\(L10n.recite): \(L10n.recSilent)", "\(L10n.recite): \(L10n.recSilent)",
        ])
        #expect(isha.step(at: 1).localizedRecitationTag == nil)
    }

    @Test("Zeile oben: „Rakʿa 2 von 4 · Schritt 9 von 28“, auf Start und Ende „Gebet Schritt für Schritt“")
    func progressLine() throws {
        let dhuhr = try walk(.dhuhr)
        #expect(dhuhr.localizedProgressLine(at: 0) == L10n.wkStart)
        #expect(dhuhr.localizedProgressLine(at: 9) == "\(L10n.wkRak(r: "2", n: "4")) · \(L10n.wkStep(i: "9", k: "28"))")
        #expect(dhuhr.localizedProgressLine(at: 5) == "\(L10n.wkRak(r: "1", n: "4")) · \(L10n.wkStep(i: "5", k: "28"))")
        #expect(dhuhr.localizedProgressLine(at: 29) == L10n.wkStart)
        let fajr = try walk(.fajr)
        #expect(fajr.localizedProgressLine(at: 15) == "\(L10n.wkRak(r: "2", n: "2")) · \(L10n.wkStep(i: "15", k: "15"))")
    }

    @Test("Startseite und Name des Vollbilds nennen das Gebet")
    func introTexts() throws {
        let maghrib = try walk(.maghrib)
        #expect(maghrib.localizedIntroTitle == L10n.wkIntroTitle(p: L10n.p_maghrib, n: 3))
        #expect(maghrib.localizedIntroBody == L10n.wkIntroBody(p: L10n.p_maghrib))
        #expect(maghrib.localizedDialogLabel == "\(L10n.wkStart): \(L10n.p_maghrib)")
    }

    // MARK: - Maße

    @Test("Maße des Durchlaufs wie `.walk-*` im Prototyp")
    func metrics() {
        #expect(WalkMetrics.topBarHeight == 52)
        #expect(WalkMetrics.sideSlot == 44)
        #expect(WalkMetrics.barHeight == 4)
        #expect(WalkMetrics.barTop == 6)
        #expect(WalkMetrics.barInsetX == 20)
        #expect(WalkMetrics.bodyInsetX == 30)
        #expect(WalkMetrics.tileSize == 172)
        #expect(WalkMetrics.tileRadius == 44)
        #expect(WalkMetrics.slideDistance == 22)
        #expect(WalkMetrics.slideDuration == 0.34)
        #expect(WalkMetrics.actionsRatios == [1, 1.6])
        #expect(WalkMetrics.actionsGap == 10)
        #expect(WalkMetrics.actionsBottom == 12)
        #expect(WalkMetrics.actionsMaxWidthRegular == 420)
        #expect(WalkPageMetrics.formulaMaxWidth == 320)
        #expect(WalkPageMetrics.dotSize == 34)
        #expect(GlassMetrics.regularCircle == 44)
    }

    @Test("Knöpfe im Verhältnis 1 : 1,6: im Prototyp 127,69 und 204,31 pt")
    func proportionalRow() {
        let row = ProportionalRow(spacing: 10, ratios: [1, 1.6])
        let prototype = row.columnWidths(total: 342, idealWidths: [0, 0])
        #expect(abs(prototype[0] - 127.69) < 0.01)
        #expect(abs(prototype[1] - 204.31) < 0.01)
        let app = row.columnWidths(total: 354, idealWidths: [0, 0])
        #expect(abs(app[0] + app[1] + 10 - 354) < 0.001)
        #expect(abs(app[1] / app[0] - 1.6) < 0.001)
        // Ideale Breite: „Zurück“ braucht 150 pt, „Weiter“ 160 pt – die Spalte 1 bestimmt die Breite.
        let ideal = row.columnWidths(total: nil, idealWidths: [150, 160])
        #expect(ideal[0] == 150)
        #expect(abs(ideal[1] - 240) < 0.001)
    }

    @Test("Knopf in der Kopfkarte: „Gebet Schritt für Schritt“ mit `play.fill`, 18 pt unter dem Hinweis")
    func headerButton() {
        #expect(GuideHeaderMetrics.walkTop == 18)
        #expect(GuideHeaderMetrics.walkSymbol == "play.fill")
        #expect(GuideHeaderMetrics.walkSubTop == 8)
        #expect(UIImage(systemName: GuideHeaderMetrics.walkSymbol) != nil)
        #expect(UIImage(systemName: WalkPageMetrics.doneSymbol) != nil)
        for prayer in Prayer.five {
            #expect(UIImage(systemName: prayer.symbolName) != nil, "\(prayer)")
        }
    }
}

/// Die Seite Einstellungen › Lizenzen (Spec § 9.7).
@Suite("Lizenzen")
struct SoftwareLicenseTests {

    @Test("Amiri (OFL 1.1) und Adhan Swift (MIT), jeweils mit Text und Zweck")
    func licenses() {
        #expect(SoftwareLicense.allCases.map(\.component) == ["Amiri, Amiri Quran", "Adhan Swift"])
        #expect(SoftwareLicense.allCases.map(\.licenseName) == ["SIL Open Font License 1.1", "MIT License"])
        #expect(SoftwareLicense.amiri.localizedPurpose == L10n.licAmiriSub)
        #expect(SoftwareLicense.adhanSwift.localizedPurpose == L10n.licAdhanSub)
        #expect(SoftwareLicense.amiri.text.contains("Reserved Font Name") || SoftwareLicense.amiri.text.contains("SIL OPEN FONT LICENSE"))
        #expect(SoftwareLicense.adhanSwift.text.contains("Permission is hereby granted"))
    }
}
