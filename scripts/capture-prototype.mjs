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
const PROTOTYPE = pathToFileURL(join(ROOT, 'design/prayer-times-prototype.html')).href;

const hm = (h, m, s = 0) => h * 3600 + m * 60 + s;

// Ein Zustand: Datei (ohne .png), Uhrzeit in Sekunden, Änderungen an `S`, Bildlauf und dunkel/hell.
// `scroll` gibt je `data-scroll`-Bereich die Position in px an ('end' = ganz unten).
// Qibla: `drag: true` hält den Kurs fest – sonst schwankt er im Prototyp um ±0,9°.
const home = { onboarded: true, section: 'prayers', tab: 'today' };
const STATES = [
  // Onboarding – Phase 7, Änderungen 1 und 8
  { file: 'iphone/01-onboarding-1-welcome', at: hm(14, 25), s: { onboarded: false, obStep: 0 } },
  { file: 'iphone/01-onboarding-1-welcome-dark', dark: true, at: hm(14, 25), s: { onboarded: false, obStep: 0 } },
  { file: 'iphone/02-onboarding-2-location', at: hm(14, 25), s: { onboarded: false, obStep: 1 } },
  { file: 'iphone/03-onboarding-3-notifications', at: hm(14, 25), s: { onboarded: false, obStep: 2 } },
  { file: 'iphone/05-onboarding-4-free', at: hm(14, 25), s: { onboarded: false, obStep: 3 } },
  { file: 'iphone/05-onboarding-4-free-dark', dark: true, at: hm(14, 25), s: { onboarded: false, obStep: 3 } },

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

  // Verse – Phase 6
  { file: 'iphone/50-verses', at: hm(14, 25), s: { ...home, section: 'verses' } },
  { file: 'iphone/51-verses-dark', dark: true, at: hm(14, 25), s: { ...home, section: 'verses' } },

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
      await page.evaluate(({ st, dark }) => {
        // Jeder Zustand beginnt beim Ausgangszustand des Prototyps.
        Object.assign(S, {
          view: 'app', device: 'iphone', sysTheme: dark ? 'dark' : 'light', lang: 'de', rtl: false, _autoRtl: false,
          locDenied: false, offline: false, highLat: false, bigType: false,
          section: 'prayers', tab: 'today', guidePick: null, walk: null, dayOff: 0, onboarded: true, obStep: 0,
          stack: { settings: [] }, sheet: null, alert: null, city: 'berlin', deviceCity: 'berlin', autoLocation: true,
          hlRule: 'angle', hlDeg: { fajr: 15, isha: 15 }, kerahat: true, appearance: 'system',
          qibla: { heading: 99, drag: true }, scrollPos: {}, focusNext: null, _focus: null,
        }, st.s);
        S.clock = { base: st.at, anchor: Date.now(), preset: 'custom' };
        render();
        for (const [key, value] of Object.entries(st.scroll || {})) {
          const el = document.querySelector(`#stage [data-scroll="${key}"]`);
          if (!el) throw new Error(`Bildlauf ${key} nicht gefunden`);
          el.scrollTop = value === 'end' ? el.scrollHeight : value;
          markScrolled(el);
        }
        if (document.activeElement && document.activeElement.blur) document.activeElement.blur();
      }, { st, dark });
      await page.waitForTimeout(700);   // Übergänge und Animationen des Prototyps abwarten
      const target = join(OUT, `${st.file}.png`);
      mkdirSync(dirname(target), { recursive: true });
      await page.locator('#stage .screen').first().screenshot({ path: target, animations: 'disabled' });
      console.log(`  ${st.file}.png`);
    }
    await context.close();
  }
} finally {
  await browser.close();
}
