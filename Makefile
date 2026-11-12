# Gebetszeiten – Befehle zum Bauen, Testen und für den Simulator.
#
#   make help        zeigt alle Befehle
#
# Build-Daten liegen auf der externen Platte „Extern“, wenn sie angesteckt ist, sonst lokal
# unter ~/Library/Developer/Xcode/DerivedData. Mit BUILD_ROOT=… lässt sich der Ort ändern.

PROJECT   := Gebetszeiten.xcodeproj
SCHEME    := Gebetszeiten
BUNDLE_ID := com.example.gebetszeiten

# Simulator für Build, Tests und Abgleich: iPhone 18 Pro, entschieden am 10.11.2026
# (docs/OPEN-QUESTIONS.md). Ein anderer Simulator: make test SIM='iPhone 17'
SIM  ?= iPhone 18 Pro
DEST := platform=iOS Simulator,name=$(SIM)

EXTERN     := /Volumes/Extern
BUILD_ROOT ?= $(if $(wildcard $(EXTERN)),$(EXTERN)/Builds/NamazVakti,$(HOME)/Library/Developer/Xcode/DerivedData/NamazVakti)
DERIVED    := $(BUILD_ROOT)/DerivedData
CORE_BUILD := $(BUILD_ROOT)/spm-PrayerCore
APP        := $(DERIVED)/Build/Products/Debug-iphonesimulator/Gebetszeiten.app

# Startargumente für `make run`. Standard ist der Haupt-Screenshot iphone/10:
# Deutsch, Berlin, 10.11.2026, 14:25. Weitere Sätze stehen in docs/PROMPTS.md.
# Sprache und Region wie `LOC` im Prototyp (de-DE, tr-TR, en-GB, es-ES).
LANGUAGE  ?= de
LOCALE_de := de_DE
LOCALE_tr := tr_TR
LOCALE_en := en_GB
LOCALE_es := es_ES
LOCALE    ?= $(LOCALE_$(LANGUAGE))
ARGS      ?= -debugSkipOnboarding -debugFixtureTimes -debugDate 2026-11-10 -debugTime 14:25
# Uhrzeit in der Statusleiste und Ziel für `make screenshot`.
TIME ?= 14:25
SHOT ?= screenshots-out/screenshot.png

XCODEBUILD := xcodebuild -project $(PROJECT) -scheme $(SCHEME) -destination '$(DEST)' -derivedDataPath '$(DERIVED)'

.PHONY: help project strings check-strings build test test-core coverage boot run statusbar screenshot compare compare-today compare-qibla compare-guide compare-verses compare-qada compare-settings compare-system clean

help: ## Diese Übersicht
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F ':.*## ' '{printf "  make %-14s %s\n", $$1, $$2}'

project: ## Xcode-Projekt aus project.yml erzeugen
	xcodegen generate

strings: ## String Catalog und L10n.swift aus dem Prototyp neu erzeugen
	scripts/import-strings

check-strings: ## Prüfen, ob String Catalog und L10n.swift zum Prototyp passen
	scripts/import-strings --check

build: project ## App für den Simulator bauen
	$(XCODEBUILD) build

test: project check-strings ## Alle Tests im Simulator, vorher der Abgleich der Texte
	$(XCODEBUILD) test

test-core: ## Nur PrayerCore, ohne Simulator
	swift test --package-path Packages/PrayerCore --scratch-path '$(CORE_BUILD)'

coverage: ## Testabdeckung von PrayerCore, Zeile für Zeile je Datei
	swift test --package-path Packages/PrayerCore --scratch-path '$(CORE_BUILD)' --enable-code-coverage
	xcrun llvm-cov report \
	  '$(CORE_BUILD)/debug/PrayerCoreTests.xctest/Contents/MacOS/PrayerCoreTests' \
	  -instr-profile '$(CORE_BUILD)/debug/codecov/default.profdata' \
	  '$(CURDIR)/Packages/PrayerCore/Sources/PrayerCore'

boot: ## Simulator starten
	xcrun simctl boot '$(SIM)' 2>/dev/null || true
	xcrun simctl bootstatus '$(SIM)' -b

run: build boot ## App im Simulator starten (LANGUAGE=tr, ARGS='…' für andere Zustände)
	xcrun simctl install '$(SIM)' '$(APP)'
	xcrun simctl launch --terminate-running-process '$(SIM)' $(BUNDLE_ID) \
	  -AppleLanguages '($(LANGUAGE))' -AppleLocale $(LOCALE) $(ARGS)

statusbar: ## Statusleiste wie in den Referenzbildern (TIME=14:25)
	xcrun simctl status_bar '$(SIM)' override --time '$(TIME)' \
	  --batteryState discharging --batteryLevel 100 --cellularBars 4 --wifiBars 3

screenshot: ## Screenshot des Simulators nach SHOT=…
	@mkdir -p '$(dir $(SHOT))'
	xcrun simctl io '$(SIM)' screenshot '$(SHOT)'

compare: build boot ## Bausteine wie in den Referenzbildern aufnehmen und danebenlegen (STATES='10 22' für einzelne)
	xcrun simctl install '$(SIM)' '$(APP)'
	SIM='$(SIM)' scripts/compare-catalog $(STATES)

compare-today: build boot ## Zeiten-Seite wie in den Referenzbildern aufnehmen und danebenlegen (STATES='10 17' für einzelne)
	xcrun simctl install '$(SIM)' '$(APP)'
	SIM='$(SIM)' scripts/compare-today $(STATES)

compare-qibla: build boot ## Qibla-Seite wie in den Referenzbildern aufnehmen und danebenlegen (STATES='31' für einzelne)
	xcrun simctl install '$(SIM)' '$(APP)'
	SIM='$(SIM)' scripts/compare-qibla $(STATES)

compare-guide: build boot ## Anleitung wie in iphone/40 aufnehmen und danebenlegen, dazu 41 und 42, wenn aufgenommen
	xcrun simctl install '$(SIM)' '$(APP)'
	SIM='$(SIM)' scripts/compare-guide

compare-verses: build boot ## Verse wie in iphone/50 (hell) und 51 (dunkel) aufnehmen und danebenlegen
	xcrun simctl install '$(SIM)' '$(APP)'
	SIM='$(SIM)' scripts/compare-verses

compare-qada: build boot ## Nachholen wie in iphone/60 aufnehmen und danebenlegen, dazu 61, wenn aufgenommen
	xcrun simctl install '$(SIM)' '$(APP)'
	SIM='$(SIM)' scripts/compare-qada

compare-settings: build boot ## Einstellungen, Onboarding und Adhan wie in iphone/01–03, 70–81, 86 aufnehmen und danebenlegen (STATES='70 86' für einzelne)
	xcrun simctl install '$(SIM)' '$(APP)'
	SIM='$(SIM)' scripts/compare-settings $(STATES)

compare-system: build boot ## Widgets und Live-Aktivität wie in system/90, 91, 93–96 im Katalog aufnehmen und danebenlegen (STATES='93 96' für einzelne)
	xcrun simctl install '$(SIM)' '$(APP)'
	SIM='$(SIM)' scripts/compare-system $(STATES)

clean: ## Build-Daten dieses Projekts löschen
	rm -rf '$(DERIVED)' '$(CORE_BUILD)'
