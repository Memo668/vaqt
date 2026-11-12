import PrayerCore
import SwiftUI
import Testing
import UIKit
@testable import DesignSystem

/// Die Bausteine der Anleitung: Haltungsfiguren, Segmente, Rakʿa-Folge, Texte und Symbole.
@Suite("Anleitung – Bausteine")
struct GuideComponentTests {

    // MARK: - Haltungsfiguren

    private func expectClose(_ a: CGFloat, _ b: CGFloat, _ comment: Comment? = nil, tolerance: CGFloat = 0.01) {
        #expect(abs(a - b) < tolerance, comment)
    }

    /// Rahmen der Linien einer Figur im Raster von 48 × 48, ohne Strichstärke – ausgerechnet aus `POSE`.
    @Test("jede Figur liegt dort, wo `POSE` sie zeichnet", arguments: [
        (GuideStep.Pose.takbir, CGRect(x: 17.5, y: 4.9, width: 13, height: 37.1)),
        (.qiyam, CGRect(x: 19.5, y: 4.9, width: 8.1, height: 37.1)),
        (.ruku, CGRect(x: 14, y: 12.9, width: 25.6, height: 29.1)),
        (.itidal, CGRect(x: 20.4, y: 4.9, width: 7.2, height: 37.1)),
        (.sujud, CGRect(x: 6, y: 25.5, width: 35.1, height: 16.5)),
        (.sit, CGRect(x: 17.4, y: 7.4, width: 16.1, height: 33.1)),
        (.salam, CGRect(x: 17.4, y: 5.5, width: 16.1, height: 35)),
    ])
    func poseBounds(pose: GuideStep.Pose, expected: CGRect) {
        let bounds = PoseShape(pose).path(in: CGRect(x: 0, y: 0, width: 48, height: 48)).boundingRect
        expectClose(bounds.minX, expected.minX, "minX \(pose)")
        expectClose(bounds.minY, expected.minY, "minY \(pose)")
        expectClose(bounds.maxX, expected.maxX, "maxX \(pose)")
        expectClose(bounds.maxY, expected.maxY, "maxY \(pose)")
    }

    @Test("der Bogen beim Friedensgruß: Mittelpunkt wie SVG ihn rechnet, Enden bei 28/5,5 und 30,4/13,7")
    func salamArc() {
        let from = CGPoint(x: 28, y: 5.5)
        let to = CGPoint(x: 30.4, y: 13.7)
        let center = PoseGeometry.arcCenter(from: from, to: to, radius: 7.5, sweep: true)
        expectClose(center.x, 23.284, tolerance: 0.001)
        expectClose(center.y, 11.332, tolerance: 0.001)
        expectClose(hypot(from.x - center.x, from.y - center.y), 7.5)
        expectClose(hypot(to.x - center.x, to.y - center.y), 7.5)

        // Der Bogen läuft im Uhrzeigersinn über die rechte Seite des Kopfes: Sein äußerster Punkt liegt
        // rechts vom Mittelpunkt, nicht links.
        let path = Path { path in
            path.move(to: from)
            path.addArc(
                center: center, radius: 7.5,
                startAngle: .radians(atan2(from.y - center.y, from.x - center.x)),
                endAngle: .radians(atan2(to.y - center.y, to.x - center.x)), clockwise: false
            )
        }
        expectClose(path.boundingRect.maxX, center.x + 7.5)
        expectClose(path.currentPoint?.x ?? 0, to.x)
        expectClose(path.currentPoint?.y ?? 0, to.y)
    }

    @Test("ohne Schwung: in die andere Richtung gäbe es den großen Bogen nicht")
    func arcCenterSides() {
        let from = CGPoint(x: 28, y: 5.5)
        let to = CGPoint(x: 30.4, y: 13.7)
        let clockwise = PoseGeometry.arcCenter(from: from, to: to, radius: 7.5, sweep: true)
        let counter = PoseGeometry.arcCenter(from: from, to: to, radius: 7.5, sweep: false)
        // Die beiden Mittelpunkte liegen spiegelbildlich zur Sehne.
        expectClose((clockwise.x + counter.x) / 2, 29.2)
        expectClose((clockwise.y + counter.y) / 2, 9.6)
    }

    @Test("Bodenlinie von 5 bis 43 auf Höhe 44,5; die Figuren stehen darüber")
    func ground() {
        let rect = CGRect(x: 0, y: 0, width: 48, height: 48)
        let line = PoseGroundShape().path(in: rect).boundingRect
        #expect(line == CGRect(x: 5, y: 44.5, width: 38, height: 0))
        for pose in GuideStep.Pose.allCases {
            #expect(PoseShape(pose).path(in: rect).boundingRect.maxY <= 42.01, "\(pose)")
        }
    }

    @Test("die Figur wird mittig in ihr Feld skaliert: 46 pt auf der Kachel von 58 pt")
    func poseScaling() {
        let small = PoseShape(.takbir).path(in: CGRect(x: 0, y: 0, width: 48, height: 48)).boundingRect
        let tile = PoseShape(.takbir).path(in: CGRect(x: 6, y: 6, width: 46, height: 46)).boundingRect
        let scale: CGFloat = 46 / 48
        expectClose(tile.minX, 6 + small.minX * scale)
        expectClose(tile.width, small.width * scale)
        #expect(PoseFigureMetrics.tileSize == 58)
        #expect(PoseFigureMetrics.figureSize == 46)
        #expect(PoseFigureMetrics.tileRadius == 16)
    }

    // MARK: - Segmente

    @Test("Segmente: Spur 34 pt, Tippziel 44 pt, Schrift 13 pt höchstens 1,2-fach")
    func segmentMetrics() {
        #expect(SegmentMetrics.trackHeight == 34)
        #expect(SegmentMetrics.hitOutset == 5)
        #expect(SegmentMetrics.fontSize(typeScale: 1) == 13)
        expectClose(SegmentMetrics.fontSize(typeScale: 1.1), 14.3)
        expectClose(SegmentMetrics.fontSize(typeScale: 3), 15.6)
    }

    @Test("mit Punkt teilen sich Titel und Punkt die 30 pt wie gestreckte Rasterzeilen")
    func segmentRows() {
        let unmarked = SegmentMetrics.rows(fontSize: 13, isMarked: false)
        #expect(unmarked.title == 30)
        #expect(unmarked.dot == 0)

        // Titel 13 × 1,1934 = 15,51 pt, Punkt 6 pt, frei 8,49 pt – je die Hälfte dazu.
        let marked = SegmentMetrics.rows(fontSize: 13, isMarked: true)
        expectClose(marked.title, 19.76)
        expectClose(marked.dot, 10.24)
        expectClose(marked.title + marked.dot, 30)
        // Der Punkt sitzt damit 21,88 pt unter der Oberkante des Teils, wie im Referenzbild iphone/40.
        expectClose(marked.title + (marked.dot - SegmentMetrics.dotSize) / 2, 21.88)
    }

    @Test("der gewählte Teil: Weiß hell, #636366 dunkel")
    func segmentThumb() {
        #expect(Palette.Values.segmentThumbLight == RGBA(hex: 0xFFFFFF))
        #expect(Palette.Values.segmentThumbDark == RGBA(hex: 0x636366))
    }

    // MARK: - Fließende Reihen

    @Test("Rakʿa-Folge in einer Reihe, wenn sie passt")
    func flowFits() {
        let layout = FlowLayout(horizontalSpacing: 6, verticalSpacing: 10)
        let sizes = [
            CGSize(width: 38, height: 52.3), CGSize(width: 38, height: 52.3), CGSize(width: 50, height: 29.3),
            CGSize(width: 38, height: 52.3), CGSize(width: 38, height: 52.3), CGSize(width: 90, height: 29.3),
        ]
        let rows = layout.arrange(sizes: sizes, maxWidth: 330)
        #expect(rows.count == 1)
        #expect(rows[0].indices == Array(0..<6))
        expectClose(rows[0].width, 4 * 38 + 50 + 90 + 5 * 6)
        expectClose(rows[0].height, 52.3)
    }

    @Test("reicht der Platz nicht, bricht die Folge um; jede Reihe so hoch wie ihr höchstes Glied")
    func flowWraps() {
        let layout = FlowLayout(horizontalSpacing: 6, verticalSpacing: 10)
        let sizes = [
            CGSize(width: 38, height: 52.3), CGSize(width: 38, height: 52.3), CGSize(width: 50, height: 29.3),
            CGSize(width: 38, height: 52.3), CGSize(width: 38, height: 52.3), CGSize(width: 90, height: 29.3),
        ]
        let rows = layout.arrange(sizes: sizes, maxWidth: 250)
        #expect(rows.map(\.indices) == [[0, 1, 2, 3, 4], [5]])
        expectClose(rows[1].height, 29.3)
    }

    @Test("ein Glied, das allein zu breit ist, steht in einer eigenen Reihe")
    func flowOversized() {
        let layout = FlowLayout(horizontalSpacing: 6, verticalSpacing: 10)
        let rows = layout.arrange(
            sizes: [CGSize(width: 40, height: 10), CGSize(width: 500, height: 20), CGSize(width: 40, height: 10)],
            maxWidth: 200
        )
        #expect(rows.map(\.indices) == [[0], [1], [2]])
        #expect(rows[1].width == 200)
    }

    // MARK: - Texte und Symbole

    @Test("die Symbole der Anleitung gibt es im System", arguments: [
        "drop", "sparkles", "safari", "heart", "clock.arrow.circlepath",
    ])
    func symbolsExist(name: String) {
        #expect(UIImage(systemName: name) != nil)
    }

    @Test("„Vorher“: Gebetswaschung, reiner Ort, Qibla, Absicht – jede Karte mit eigenem Titel")
    func preparation() {
        #expect(GuidePreparation.allCases.map(\.symbolName) == ["drop", "sparkles", "safari", "heart"])
        #expect(GuidePreparation.allCases.map(\.localizedTitle) == [L10n.b_wudu, L10n.b_clean, L10n.b_qibla, L10n.b_niyya])
        #expect(GuidePreparation.qibla.symbolName == GuideSymbols.openQibla)
    }

    @Test("die Absicht nennt das Gebet und die Zahl seiner Rakʿas")
    func intention() throws {
        let rakahs = try #require(Guide.rakahs(for: .asr))
        #expect(GuidePreparation.niyya.localizedText(prayer: .asr, rakahs: rakahs) == L10n.b_niyyaD(p: L10n.p_asr, n: "4"))
        #expect(GuidePreparation.wudu.localizedText(prayer: .asr, rakahs: rakahs) == L10n.b_wuduD)
    }

    @Test("jeder Schritt hat Titel und Anweisung aus dem String Catalog")
    func stepTexts() {
        let titles = GuideStep.Kind.allCases.map(\.localizedTitle)
        let descriptions = GuideStep.Kind.allCases.map(\.localizedDescription)
        #expect(titles.first == L10n.s_takbir)
        #expect(descriptions.last == L10n.s_salamD)
        #expect(Set(titles).count == 7)
        #expect(Set(descriptions).count == 7)
        #expect(!titles.contains { $0.isEmpty || $0.hasPrefix("s_") })
    }

    @Test("Sunna und Rezitation je Gebet")
    func facts() {
        #expect(Prayer.five.map(\.localizedSunna) == [
            L10n.sunna_fajr, L10n.sunna_dhuhr, L10n.sunna_asr, L10n.sunna_maghrib, L10n.sunna_isha,
        ])
        #expect(Prayer.sunrise.localizedSunna.isEmpty)
        #expect(Rakahs.Recitation.aloud.localizedName == L10n.recAloud)
        #expect(Rakahs.Recitation.mixed.localizedName == L10n.recMixed)
        #expect(Rakahs.Recitation.silent.localizedName == L10n.recSilent)
    }

    @Test("die Rakʿa-Folge für VoiceOver: „Ablauf der Rakʿas: 1 laut, 2 laut, 3 leise“")
    func rakahAccessibility() throws {
        let maghrib = try #require(Guide.rakahs(for: .maghrib))
        #expect(maghrib.accessibilityDescription
            == "\(L10n.rakSeq): 1 \(L10n.recAloud), 2 \(L10n.recAloud), 3 \(L10n.recSilent)")
    }

    // MARK: - Kopfkarte

    #if DEBUG

    @Test("iphone/40: Asr läuft – „Jetzt“, 14:00–16:27, Punkt bei Asr, kein Knopf")
    func headerCurrent() {
        let header = CatalogFixtures.guideHeader(time: "14:25")
        #expect(header.prayer == .asr)
        #expect(header.status == L10n.now)
        #expect(header.window == "14:00\u{2060}–\u{2060}16:27")
        #expect(header.automatic == .asr)
        #expect(header.automaticStatus == L10n.now)
        #expect(header.returnPrayer == nil)
        #expect(header.rakahs.count == 4)
        #expect(header.segments.map(\.value) == Prayer.five)
        #expect(header.segments.map(\.mark) == [nil, nil, L10n.now, nil, nil])
    }

    @Test("iphone/42: Maghrib von Hand – ohne Status, 16:27–18:17, Knopf zurück zu Asr")
    func headerManualPick() {
        let header = CatalogFixtures.guideHeader(time: "14:25", pick: .maghrib)
        #expect(header.prayer == .maghrib)
        #expect(header.status == nil)
        #expect(header.window == "16:27\u{2060}–\u{2060}18:17")
        #expect(header.returnPrayer == .asr)
        #expect(header.segments.map(\.mark) == [nil, nil, L10n.now, nil, nil])
    }

    @Test("am Vormittag: Dhuhr als nächstes Gebet, der Punkt sagt „Als Nächstes“")
    func headerNext() {
        let header = CatalogFixtures.guideHeader(time: "08:04")
        #expect(header.prayer == .dhuhr)
        #expect(header.status == L10n.guideNext)
        #expect(header.window == "11:52\u{2060}–\u{2060}14:00")
        #expect(header.segments.map(\.mark) == [nil, L10n.guideNext, nil, nil, nil])
    }

    @Test("ohne Zeiten: Fadschr, ohne Status, Zeitfenster und Punkt")
    func headerWithoutTimes() {
        let header = GuideHeader(state: GuideState(phase: nil), window: nil, timeZone: .gmt)
        #expect(header.prayer == .fajr)
        #expect(header.status == nil)
        #expect(header.window == nil)
        #expect(header.automatic == nil)
        #expect(header.returnPrayer == nil)
        #expect(header.segments.allSatisfy { $0.mark == nil })
    }

    #endif
}
