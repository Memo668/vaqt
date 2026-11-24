// Erzeugt von scripts/import-strings aus design/prayer-times-prototype.html (`VERSES`).
// Nicht von Hand ändern – Verse im Prototyp ändern und das Skript neu ausführen.

extension Verse {

    /// Die Verse der Seite „Verse“ in der Reihenfolge des Prototyps. Übersetzungen und Namen der Suren
    /// stehen im String Catalog (`verse_<Sure>_<Vers>`, `surah_<Sure>`).
    ///
    /// Der arabische Text ist jeweils ein Teil des Verses in der Uthmani-Schreibweise von Tanzil
    /// (docs/THIRD-PARTY.md). Welche Verse die App auf Dauer zeigt, ist noch offen – Spec § 6.12, § 11.1.
    public static let all: [Verse] = [
        Verse(surah: 2, ayah: 45, arabic: "وَٱسْتَعِينُوا۟ بِٱلصَّبْرِ وَٱلصَّلَوٰةِ"),
        Verse(surah: 94, ayah: 5, arabic: "فَإِنَّ مَعَ ٱلْعُسْرِ يُسْرًا"),
        Verse(surah: 13, ayah: 28, arabic: "أَلَا بِذِكْرِ ٱللَّهِ تَطْمَئِنُّ ٱلْقُلُوبُ"),
        Verse(surah: 2, ayah: 152, arabic: "فَٱذْكُرُونِىٓ أَذْكُرْكُمْ"),
        Verse(surah: 20, ayah: 14, arabic: "وَأَقِمِ ٱلصَّلَوٰةَ لِذِكْرِىٓ"),
        Verse(surah: 2, ayah: 286, arabic: "لَا يُكَلِّفُ ٱللَّهُ نَفْسًا إِلَّا وُسْعَهَا"),
    ]
}
