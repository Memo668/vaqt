#if DEBUG

extension QadaLedger {

    /// Der Stand des Nachholens aus dem Prototyp (`S.qada`): 1 Jahr 6 Monate, 545 je Gebet, davon noch
    /// 501, 523, 530, 512 und 526 offen.
    ///
    /// Nur Test-Fixture: Damit zeigt die Seite dieselben Zahlen wie `design/screenshots/iphone/60-qada.png`
    /// (2.725 gesamt, 133 nachgeholt, 4,9 %). Die App selbst startet leer.
    public static let prototypeSample = QadaLedger(
        years: 1, months: 6, days: 0, perDay: 5, includesWitr: false,
        total: [.fajr: 545, .dhuhr: 545, .asr: 545, .maghrib: 545, .isha: 545, .witr: 0],
        open: [.fajr: 501, .dhuhr: 523, .asr: 530, .maghrib: 512, .isha: 526, .witr: 0]
    )
}

#endif
