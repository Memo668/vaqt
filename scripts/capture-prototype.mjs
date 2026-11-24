// scripts/capture-prototype.mjs
//
// Nimmt Referenzbilder aus dem Prototyp (design/prayer-times-prototype.html) auf: nur der Bildschirm
// (`.screen`) ohne Geräterahmen, 2x, wie die Bilder in design/screenshots/. Seit Phase 12 (Spec v0.8)
// entstehen die Referenzbilder damit; die Zustände stehen unten in `STATES`.
//
// Aufruf über den Wrapper scripts/capture-prototype:
//   scripts/capture-prototype                 alle Zustände nach design/screenshots/
//   scripts/capture-prototype 10 23-dark      nur diese (Präfix des Dateinamens)
//   OUT=screenshots-out/proto scripts/capture-prototype   anderer Ordner
//   PROTO_LANG=ar OUT=screenshots-out/phase-15/ar/proto scripts/capture-prototype 10 43
//                                             alle Zustände in einer anderen Sprache (Phase 15, Spec § 9.10);
//                                             ar, ur und fa spiegeln sich wie im Prototyp von selbst
//
// Datum und Uhr: Das Datum steht fest auf dem 10.11.2026 (wie in allen Referenzbildern), die Uhr des
// Prototyps auf der Zeit des Zustands. Zeitzone Europe/Berlin – in ihr rechnet der Prototyp das Datum.

import { createRequire } from 'node:module';
import { mkdirSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';

const ROOT = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const require = createRequire(join(process.env.PLAYWRIGHT_DIR, 'package.json'));
const { chromium } = require('playwright');

const OUT = resolve(ROOT, process.env.OUT || 'design/screenshots');
// Sprache aller Zustände statt der eigenen (`S.lang`); nicht `LANG`, das ist die Locale der Shell.
const PROTO_LANG = process.env.PROTO_LANG || null;
const PROTOTYPE = pathToFileURL(join(ROOT, 'design/prayer-times-prototype.html')).href;

const hm = (h, m, s = 0) => h * 3600 + m * 60 + s;

// Ein Zustand: Datei (ohne .png), Uhrzeit in Sekunden, Änderungen an `S`, Bildlauf und dunkel/hell.
// `scroll` gibt je `data-scroll`-Bereich die Position in px an ('end' = ganz unten).
// Qibla: `drag: true` hält den Kurs fest – sonst schwankt er im Prototyp um ±0,9°.
const home = { onboarded: true, section: 'prayers', tab: 'today' };
const STATES = [
  // Onboarding – Phase 7, Änderungen 1 und 8; seit dem Nachtrag zu Phase 18 (Spec § 11.5) fünf Seiten, die Rechtsschule
  // ist Seite 3 (`obStep` 2). Mitteilungen und „Kostenlos“ rücken eins weiter (05, 06; bis Phase 18 hießen sie 03 und 05).
  { file: 'iphone/01-onboarding-1-welcome', at: hm(14, 25), s: { onboarded: false, obStep: 0 } },
  { file: 'iphone/01-onboarding-1-welcome-dark', dark: true, at: hm(14, 25), s: { onboarded: false, obStep: 0 } },
  { file: 'iphone/02-onboarding-2-location', at: hm(14, 25), s: { onboarded: false, obStep: 1 } },
  { file: 'iphone/03-onboarding-3-madhab', at: hm(14, 25), s: { onboarded: false, obStep: 2 } },
  { file: 'iphone/03-onboarding-3-madhab-dark', dark: true, at: hm(14, 25), s: { onboarded: false, obStep: 2 } },
  { file: 'iphone/03-onboarding-3-madhab-menu', at: hm(14, 25), s: { onboarded: false, obStep: 2, obMenu: true } },
  // Der Dialog des Systems über Schritt 2 – nur Ablauf, iOS zeichnet ihn selbst (seit Phase 14 mit „Vaqt“).
  { file: 'iphone/04-alert-location', at: hm(14, 25), s: { onboarded: false, obStep: 1, alert: 'loc' } },
  { file: 'iphone/05-onboarding-4-notifications', at: hm(14, 25), s: { onboarded: false, obStep: 3 } },
  { file: 'iphone/06-onboarding-5-free', at: hm(14, 25), s: { onboarded: false, obStep: 4 } },
  { file: 'iphone/06-onboarding-5-free-dark', dark: true, at: hm(14, 25), s: { onboarded: false, obStep: 4 } },

  // Zeiten – Phase 2/3, Änderungen 2, 3 und 10
  { file: 'iphone/10-home-asr-active', at: hm(14, 25, 1), s: home },
  { file: 'iphone/11-home-asr-active-dark', dark: true, at: hm(14, 25, 1), s: home },
  { file: 'iphone/12-home-before-fajr', at: hm(5, 14, 45), s: home },
  { file: 'iphone/13-home-after-sunrise', at: hm(8, 4), s: home },
  { file: 'iphone/14-home-kerahat-active', at: hm(7, 30), s: home },
  { file: 'iphone/14-home-kerahat-active-dark', dark: true, at: hm(7, 30), s: home },
  { file: 'iphone/15-home-kerahat-before-maghrib', at: hm(16, 5), s: home },
  { file: 'iphone/16-home-after-isha-dark', dark: true, at: hm(23, 30), s: home },
  { file: 'iphone/17-home-location-denied-offline', at: hm(14, 25, 1), s: { ...home, locDenied: true, offline: true } },
  { file: 'iphone/18-home-high-latitude', at: hm(23, 47), s: { ...home, highLat: true } },
  { file: 'iphone/19-home-large-type', at: hm(14, 25, 1), s: { ...home, bigType: true } },
  { file: 'iphone/20-home-rtl', at: hm(14, 25, 1), s: { ...home, rtl: true, _autoRtl: false } },
  { file: 'iphone/21-home-turkish-istanbul', at: hm(16, 1), s: { ...home, lang: 'tr', city: 'istanbul', deviceCity: 'istanbul' } },
  { file: 'iphone/22-home-jakarta-close-markers', at: hm(17, 57), s: { ...home, city: 'jakarta', deviceCity: 'jakarta' } },
  { file: 'iphone/23-home-next-day', at: hm(14, 25, 1), s: { ...home, dayOff: 1 } },
  { file: 'iphone/23-home-next-day-dark', dark: true, at: hm(14, 25, 1), s: { ...home, dayOff: 1 } },
  // Nachtrag zu Phase 18: Grundfarbe Orange mit violetter Verbotszeit (§ 11.7), Verbotszeiten nach Rechtsschule (§ 11.6)
  { file: 'iphone/25-home-accent-orange-kerahat', at: hm(7, 30), s: { ...home, accent: 'orange' } },
  { file: 'iphone/25-home-accent-orange-kerahat-dark', dark: true, at: hm(7, 30), s: { ...home, accent: 'orange' } },
  { file: 'iphone/25-home-accent-ocean', at: hm(14, 25, 1), s: { ...home, accent: 'ocean' } },
  { file: 'iphone/26-home-maliki', at: hm(14, 25, 1), s: { ...home, madhab: 'maliki' } },
  { file: 'iphone/26-home-shafii-friday', at: hm(14, 25, 1), s: { ...home, madhab: 'shafii', dayOff: 3 } },
  { file: 'iphone/27-sheet-kerahat', at: hm(14, 25), s: { ...home, sheet: 'kerahat' } },
  { file: 'iphone/27-sheet-kerahat-maliki', at: hm(14, 25), s: { ...home, madhab: 'maliki', sheet: 'kerahat' } },

  // Qibla – Phase 4, Änderung 4 (Qibla Berlin 137°)
  { file: 'iphone/30-qibla', at: hm(14, 25), s: { ...home, tab: 'qibla', qibla: { heading: 98, drag: true } } },
  { file: 'iphone/31-qibla-aligned', at: hm(14, 25), s: { ...home, tab: 'qibla', qibla: { heading: 137, drag: true } } },
  { file: 'iphone/32-qibla-mecca', at: hm(15, 42), s: { ...home, tab: 'qibla', city: 'mecca', deviceCity: 'mecca', qibla: { heading: 138, drag: true } } },
  { file: 'iphone/33-qibla-tolerance', at: hm(14, 25), s: { ...home, tab: 'qibla', qibla: { heading: 112, drag: true } } },
  { file: 'iphone/33-qibla-tolerance-dark', dark: true, at: hm(14, 25), s: { ...home, tab: 'qibla', qibla: { heading: 112, drag: true } } },
  { file: 'iphone/34-qibla-outside', at: hm(14, 25), s: { ...home, tab: 'qibla', qibla: { heading: 60, drag: true } } },

  // Anleitung – Phase 5 (der Knopf „Gebet Schritt für Schritt“ kommt mit Phase 13)
  { file: 'iphone/40-guide-asr', at: hm(14, 25), s: { ...home, tab: 'guide', guidePick: null } },
  { file: 'iphone/41-guide-steps', at: hm(14, 25), s: { ...home, tab: 'guide', guidePick: null }, scroll: { guide: 640 } },
  { file: 'iphone/42-guide-manual-pick', at: hm(14, 25), s: { ...home, tab: 'guide', guidePick: 'maghrib' } },

  // Gebet Schritt für Schritt – Phase 13, Änderung 5 (`walk` im Prototyp: {p, i, dir}; i wie -debugWalkStep)
  { file: 'iphone/43-walk-intro', at: hm(14, 25), s: { ...home, tab: 'guide', walk: { p: 'dhuhr', i: 0, dir: 1 } } },
  { file: 'iphone/43-walk-intro-dark', dark: true, at: hm(14, 25), s: { ...home, tab: 'guide', walk: { p: 'dhuhr', i: 0, dir: 1 } } },
  { file: 'iphone/44-walk-takbir', at: hm(14, 25), s: { ...home, tab: 'guide', walk: { p: 'dhuhr', i: 1, dir: 1 } } },
  { file: 'iphone/45-walk-qiyam-silent', at: hm(14, 25), s: { ...home, tab: 'guide', walk: { p: 'dhuhr', i: 2, dir: 1 } } },
  { file: 'iphone/46-walk-qiyam-loud', at: hm(14, 25), s: { ...home, tab: 'guide', walk: { p: 'maghrib', i: 2, dir: 1 } } },
  { file: 'iphone/47-walk-sujud', at: hm(14, 25), s: { ...home, tab: 'guide', walk: { p: 'dhuhr', i: 5, dir: 1 } } },
  { file: 'iphone/47-walk-sujud-dark', dark: true, at: hm(14, 25), s: { ...home, tab: 'guide', walk: { p: 'dhuhr', i: 5, dir: 1 } } },
  { file: 'iphone/48-walk-tash-first', at: hm(14, 25), s: { ...home, tab: 'guide', walk: { p: 'dhuhr', i: 14, dir: 1 } } },
  { file: 'iphone/49-walk-done', at: hm(14, 25), s: { ...home, tab: 'guide', walk: { p: 'dhuhr', i: 29, dir: 1 } } },
  { file: 'iphone/49-walk-done-dark', dark: true, at: hm(14, 25), s: { ...home, tab: 'guide', walk: { p: 'dhuhr', i: 29, dir: 1 } } },

  // Verse – Phase 6; seit Phase 18 mit den Ausschnitten veröffentlichter Übersetzungen (Spec § 11.1)
  { file: 'iphone/50-verses', at: hm(14, 25), s: { ...home, section: 'verses' } },
  { file: 'iphone/51-verses-dark', dark: true, at: hm(14, 25), s: { ...home, section: 'verses' } },

  // Adhan – Phase 7; seit Phase 18 eine Aufnahme statt dreier Platzhalter-Stimmen (Spec § 11.2)
  { file: 'iphone/86-sheet-adhan', at: hm(14, 25), s: { ...home, stack: { settings: ['settings', 'sound'] }, sheet: 'adhan' } },
  { file: 'iphone/86-sheet-adhan-dark', dark: true, at: hm(14, 25), s: { ...home, stack: { settings: ['settings', 'sound'] }, sheet: 'adhan' } },

  // Nachholen – Phase 6, Änderung 7 (Rechner ganz unten)
  { file: 'iphone/60-qada', at: hm(14, 25), s: { ...home, section: 'qada' } },
  { file: 'iphone/61-qada-calculator', at: hm(14, 25), s: { ...home, section: 'qada' }, scroll: { qada: 'end' } },
  { file: 'iphone/61-qada-calculator-dark', dark: true, at: hm(14, 25), s: { ...home, section: 'qada' }, scroll: { qada: 'end' } },

  // Einstellungen – Phase 7, Änderungen 1, 8 und 12
  { file: 'iphone/70-settings', at: hm(14, 25), s: { ...home, stack: { settings: ['settings'] } } },
  { file: 'iphone/71-settings-middle', at: hm(14, 25), s: { ...home, stack: { settings: ['settings'] } }, scroll: { "pg-settings": 700 } },
  { file: 'iphone/72-settings-bottom', at: hm(14, 25), s: { ...home, stack: { settings: ['settings'] } }, scroll: { "pg-settings": 'end' } },
  { file: 'iphone/72-settings-bottom-dark', dark: true, at: hm(14, 25), s: { ...home, stack: { settings: ['settings'] } }, scroll: { "pg-settings": 'end' } },
  { file: 'iphone/75-settings-hl', at: hm(14, 25), s: { ...home, stack: { settings: ['settings', 'hl'] } } },
  { file: 'iphone/82-settings-hl-manual', at: hm(14, 25), s: { ...home, hlRule: 'manual', stack: { settings: ['settings', 'hl'] } } },
  { file: 'iphone/82-settings-hl-manual-dark', dark: true, at: hm(14, 25), s: { ...home, hlRule: 'manual', stack: { settings: ['settings', 'hl'] } } },
  { file: 'iphone/83-settings-support', at: hm(14, 25), s: { ...home, stack: { settings: ['settings', 'support'] } } },
  { file: 'iphone/83-settings-support-dark', dark: true, at: hm(14, 25), s: { ...home, stack: { settings: ['settings', 'support'] } } },

  // Wecker zu Fadschr – Phase 17 (Spec § 10.8): Seite in allen Zuständen, Chip in der Fadschr-Zeile
  { file: 'iphone/24-home-alarm-chip', at: hm(14, 25), s: { ...home, alarmOn: true } },
  { file: 'iphone/84-settings-alarm', at: hm(14, 25), s: { ...home, alarmOn: true, stack: { settings: ['settings', 'alarm'] } } },
  { file: 'iphone/84-settings-alarm-dark', dark: true, at: hm(14, 25), s: { ...home, alarmOn: true, stack: { settings: ['settings', 'alarm'] } } },
  { file: 'iphone/84-settings-alarm-fixed', at: hm(14, 25), s: { ...home, alarmOn: true, alarmMode: 'fixed', alarmSound: 'adhan', stack: { settings: ['settings', 'alarm'] } } },
  { file: 'iphone/84-settings-alarm-off', at: hm(14, 25), s: { ...home, stack: { settings: ['settings', 'alarm'] } } },
  { file: 'iphone/84-settings-alarm-denied', at: hm(14, 25), s: { ...home, alarmDenied: true, stack: { settings: ['settings', 'alarm'] } } },

  // Nachtrag zu Phase 18 (Spec § 11.3, 11.6, 11.7): Klang mit Systemton, Stil, Rechtsschule
  { file: 'iphone/80-settings-sound-system', at: hm(14, 25), s: { ...home, sound: 'system', stack: { settings: ['settings', 'sound'] } } },
  { file: 'iphone/87-settings-style', at: hm(14, 25, 1), s: { ...home, stack: { settings: ['settings', 'style'] } } },
  { file: 'iphone/87-settings-style-dark', dark: true, at: hm(14, 25, 1), s: { ...home, stack: { settings: ['settings', 'style'] } } },
  { file: 'iphone/87-settings-style-open', at: hm(14, 25, 1), s: { ...home, accent: 'orange', laStyle: 'arc', laInv: true, stack: { settings: ['settings', 'style'] } } },
  { file: 'iphone/87-settings-style-open-end', at: hm(14, 25, 1), s: { ...home, accent: 'orange', laStyle: 'arc', laInv: true, stack: { settings: ['settings', 'style'] } }, scroll: { 'pg-style': 'end' } },
  { file: 'iphone/88-settings-madhab', at: hm(14, 25), s: { ...home, stack: { settings: ['settings', 'madhab'] } } },
  { file: 'iphone/88-settings-madhab-dark', dark: true, at: hm(14, 25), s: { ...home, madhab: 'shafii', stack: { settings: ['settings', 'madhab'] } } },

  // Außerhalb der App – Phase 9, Änderungen 1 und 11 (Phase 14). Die Ansichten `widgets`, `live` und
  // `notifs` zeigen mehrere Bildschirme nebeneinander; `screen` wählt einen davon (0 = der erste).
  { file: 'system/90-lockscreen-widgets', at: hm(14, 25, 1), s: { ...home, view: 'widgets' }, screen: 0 },
  { file: 'system/91-homescreen-widgets', at: hm(14, 25, 1), s: { ...home, view: 'widgets' }, screen: 1 },
  { file: 'system/92-notifications', at: hm(11, 52), s: { ...home, view: 'notifs' }, screen: 0 },
  { file: 'system/93-live-activity-lockscreen', at: hm(14, 25, 1), s: { ...home, view: 'live' }, screen: 0 },
  { file: 'system/94-live-activity-island-compact', at: hm(14, 25, 1), s: { ...home, view: 'live' }, screen: 1 },
  { file: 'system/95-live-activity-island-expanded', at: hm(14, 25, 1), s: { ...home, view: 'live' }, screen: 2 },
  { file: 'system/96-live-activity-lockscreen-dark', dark: true, at: hm(16, 35), s: { ...home, view: 'live' }, screen: 0 },
  // Nachtrag zu Phase 18 (Spec § 11.7): die sechs Varianten der Live-Aktivität, auch in der Verbotszeit (16:05) und warm (violett)
  { file: 'system/97-live-activity-arc', at: hm(14, 25, 1), s: { ...home, view: 'live', laStyle: 'arc' }, screen: 0 },
  { file: 'system/97-live-activity-mono', at: hm(14, 25, 1), s: { ...home, view: 'live', laStyle: 'mono' }, screen: 0 },
  { file: 'system/97-live-activity-full-inverted', at: hm(14, 25, 1), s: { ...home, view: 'live', laInv: true }, screen: 0 },
  { file: 'system/97-live-activity-arc-inverted', at: hm(14, 25, 1), s: { ...home, view: 'live', laStyle: 'arc', laInv: true }, screen: 0 },
  { file: 'system/97-live-activity-mono-inverted', at: hm(14, 25, 1), s: { ...home, view: 'live', laStyle: 'mono', laInv: true }, screen: 0 },
  { file: 'system/97-live-activity-ocean', at: hm(14, 25, 1), s: { ...home, view: 'live', accent: 'ocean' }, screen: 0 },
  { file: 'system/98-live-activity-kerahat', at: hm(16, 5), s: { ...home, view: 'live' }, screen: 0 },
  { file: 'system/98-live-activity-kerahat-arc', at: hm(16, 5), s: { ...home, view: 'live', laStyle: 'arc' }, screen: 0 },
  { file: 'system/98-live-activity-kerahat-mono', at: hm(16, 5), s: { ...home, view: 'live', laStyle: 'mono' }, screen: 0 },
  { file: 'system/98-live-activity-kerahat-full-inverted', at: hm(16, 5), s: { ...home, view: 'live', laInv: true }, screen: 0 },
  { file: 'system/98-live-activity-kerahat-arc-inverted', at: hm(16, 5), s: { ...home, view: 'live', laStyle: 'arc', laInv: true }, screen: 0 },
  { file: 'system/98-live-activity-kerahat-warm', at: hm(16, 5), s: { ...home, view: 'live', accent: 'orange' }, screen: 0 },
  { file: 'system/98-live-activity-island-expanded-kerahat-warm', at: hm(16, 5), s: { ...home, view: 'live', accent: 'orange' }, screen: 2 },
  { file: 'system/98-live-activity-island-expanded-mono', at: hm(14, 25, 1), s: { ...home, view: 'live', laStyle: 'mono' }, screen: 2 },
  { file: 'system/99-homescreen-widgets-arc-inverted', at: hm(14, 25, 1), s: { ...home, view: 'widgets', laStyle: 'arc', laInv: true }, screen: 1 },
  { file: 'system/99-homescreen-widgets-ocean', at: hm(14, 25, 1), s: { ...home, view: 'widgets', accent: 'ocean' }, screen: 1 },
];

const only = process.argv.slice(2);
const states = only.length ? STATES.filter(st => only.some(p => st.file.split('/').pop().startsWith(p))) : STATES;
if (!states.length) {
  console.error(`capture-prototype: kein Zustand passt zu ${only.join(' ')}`);
  process.exit(1);
}

// Fehlt der Chromium, den dieses Playwright erwartet, nimmt das Skript den aus dem Cache (CHROMIUM_PATH).
const browser = await chromium.launch(process.env.CHROMIUM_PATH ? { executablePath: process.env.CHROMIUM_PATH } : {});
try {
  for (const dark of [false, true]) {
    const batch = states.filter(st => !!st.dark === dark);
    if (!batch.length) continue;
    const context = await browser.newContext({
      viewport: { width: 1600, height: 1100 }, deviceScaleFactor: 2,
      colorScheme: dark ? 'dark' : 'light', timezoneId: 'Europe/Berlin', locale: 'de-DE',
    });
    const page = await context.newPage();
    await page.clock.setFixedTime(new Date('2026-11-10T12:00:00+01:00'));
    await page.goto(PROTOTYPE);
    await page.evaluate(() => document.fonts.ready);
    for (const st of batch) {
      // Drei Bildschirme nebeneinander (`live`) passen erst in 2400 px ohne Verkleinerung (`layout()`).
      await page.setViewportSize({ width: st.s.view === 'live' ? 2400 : 1600, height: 1100 });
      await page.evaluate(({ st, dark, lang }) => {
        // Jeder Zustand beginnt beim Ausgangszustand des Prototyps – auch der Bildlauf: `render()` übernimmt
        // die Lage der Bereiche aus dem DOM, sonst stünde etwa iphone/42 noch so weit unten wie 41 (bis
        // Phase 13 so aufgenommen).
        document.querySelectorAll('#stage [data-scroll]').forEach(el => { el.scrollTop = 0; });
        Object.assign(S, {
          view: 'app', device: 'iphone', sysTheme: dark ? 'dark' : 'light', lang: 'de', rtl: false, _autoRtl: false,
          locDenied: false, offline: false, highLat: false, bigType: false,
          section: 'prayers', tab: 'today', guidePick: null, walk: null, dayOff: 0, onboarded: true, obStep: 0,
          stack: { settings: [] }, sheet: null, alert: null, city: 'berlin', deviceCity: 'berlin', autoLocation: true,
          hlRule: 'angle', hlDeg: { fajr: 15, isha: 15 }, kerahat: true, appearance: 'system',
          qibla: { heading: 99, drag: true }, scrollPos: {}, focusNext: null, _focus: null,
          // Nachtrag zu Phase 18: Grundfarbe, Stil der Live-Aktivität, Rechtsschule, Klang
          accent: 'teal', laStyle: 'full', laInv: false, palOpen: null, madhab: 'hanafi', obMenu: false, sound: 'adhan',
        }, st.s, lang ? { lang } : {});
        S.clock = { base: st.at, anchor: Date.now(), preset: 'custom' };
        render();
        for (const [key, value] of Object.entries(st.scroll || {})) {
          const el = document.querySelector(`#stage [data-scroll="${key}"]`);
          if (!el) throw new Error(`Bildlauf ${key} nicht gefunden`);
          el.scrollTop = value === 'end' ? el.scrollHeight : value;
          markScrolled(el);
        }
        if (document.activeElement && document.activeElement.blur) document.activeElement.blur();
      }, { st, dark, lang: PROTO_LANG });
      await page.waitForTimeout(700);   // Übergänge und Animationen des Prototyps abwarten
      const target = join(OUT, `${st.file}.png`);
      mkdirSync(dirname(target), { recursive: true });
      await page.locator('#stage .screen').nth(st.screen || 0).screenshot({ path: target, animations: 'disabled' });
      console.log(`  ${st.file}.png`);
    }
    await context.close();
  }
} finally {
  await browser.close();
}
