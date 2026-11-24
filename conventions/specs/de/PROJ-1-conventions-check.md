# PROJ-1: Konventionen prüfen

**Status:** Planned
**Typ:** Plattform
**Erstellt:** {{DATE}}

## Abhängigkeiten
- Keine

## Voraussetzungen (Mensch)
- [ ] `docs/operations.md` und `.factory/delivery.json` aus `/init` durchgesehen und auf den Standard-Branch gepusht

## User Stories
- Als Projektverantwortliche:r möchte ich, dass die Factory Brief, PRD, Stack, Grundgerüst und Betriebsdokumentation gegen die Betriebskonventionen abgleicht, damit Lücken auffallen, bevor die Pipelines gebaut werden.
- Als Projektverantwortliche:r möchte ich offene Betriebsentscheidungen als Rückfrage im Issue bekommen, damit nichts davon stillschweigend angenommen wird.

## Außerhalb des Umfangs
- Pipelines, Dockerfile, Health-Endpunkte oder Deploy-Dateien bauen (PROJ-2 bis PROJ-7)
- App-Code ändern
- Secrets anlegen oder Werte eintragen (macht der Mensch in Infisical)

## Akzeptanzkriterien
- [ ] AK-1: Angenommen Repo, Stack oder PRD enthalten Zustand (Datenbank, Volumes, Upload-Ordner, SQLite-Dateien, Queues, Caches mit Daten), wenn die Prüfung abgeschlossen ist, dann steht jeder gefundene Zustand in `.factory/delivery.json` unter `state` oder ist in `docs/operations.md` begründet ausgenommen.
- [ ] AK-2: Angenommen PRD, Stack oder Code nennen externe Abhängigkeiten (Datenbank, Objektspeicher, Mail, Drittanbieter-APIs), wenn die Prüfung abgeschlossen ist, dann steht jede in `health.components` oder ist in `docs/operations.md` begründet als nicht geprüft markiert.
- [ ] AK-3: Angenommen Brief oder PRD nennen Anforderungen an den Betrieb (Verfügbarkeit, Aufbewahrung, Datenstandort, Kundenvorgaben), wenn die Prüfung abgeschlossen ist, dann ist jede in `docs/operations.md` unter „Zusätzliche Anforderungen“ einer Entscheidung zugeordnet.
- [ ] AK-4: Angenommen eine Anforderung widerspricht der gewählten Stufe {{TIER}} (z. B. Deploy ohne Unterbrechung bei Stufe compose, mehrere Knoten), wenn die Prüfung das findet, dann stellt die Factory die Entscheidung als Rückfrage mit Optionen im Issue, statt sie selbst zu treffen.
- [ ] AK-5: Angenommen die Prüfung ist abgeschlossen, wenn `factory-verify` läuft, dann ist der Check `delivery-config` (Schema-Validierung von `.factory/delivery.json`) grün.
- [ ] AK-6: Angenommen die Prüfung ist abgeschlossen, dann enthält `docs/operations.md` jeden Abschnitt der Vorlage ausgefüllt, keinen Platzhalter oder kursiven Ausfüllhinweis (`_…_`) der Vorlage mehr und für die Offline-Kopie des Backup-Schlüssels einen Ort (oder die offene Rückfrage dazu), aber keinen Schlüssel.
- [ ] AK-7: Angenommen der PR der Factory liegt vor, dann ändert er nur `docs/operations.md`, `.factory/delivery.json` und `features/INDEX.md`, keinen App-Code, und der PR-Text führt jede Änderung an `.factory/delivery.json` mit Begründung auf.
- [ ] AK-8: Angenommen die Prüfung findet keine Lücke, dann enthält `docs/operations.md` trotzdem einen Abschnitt „Prüfung durch die Factory“ mit Datum, Ergebnis und der Liste der geprüften Punkte (Zustand, Abhängigkeiten, Anforderungen, Stufe, Secrets).

## Edge Cases
- EC-1: Eine Entscheidung kann nur der Mensch treffen (z. B. PITR ja/nein, Datenstandort) → Rückfrage im Issue, keine Annahme.
- EC-2: Im Repo liegt ein Secret-Wert (z. B. eine eingecheckte `.env`) → im PR als Befund nennen, ohne den Wert zu wiederholen, mit dem Hinweis, den Wert in Infisical zu rotieren.
- EC-3: Das Repo enthält nur das Grundgerüst → Prüfung anhand von Brief, PRD und `docs/stack.md`, im Abschnitt „Prüfung durch die Factory“ vermerken, dass noch kein App-Code vorlag.
- EC-4: `docs/operations.md` und `.factory/delivery.json` widersprechen sich → `.factory/delivery.json` an die dokumentierte Entscheidung angleichen, bei echter Unklarheit Rückfrage.

## Technische Anforderungen (optional)
- Grundlage ist der Leitfaden `conventions/README.md` der Software Factory (im Job unter `/factory/conventions/README.md`).
- `.factory/delivery.json` bleibt gültig gegen `factory-pipelines/schema/delivery.schema.json`.

## Offene Fragen
- [ ] _keine_

## Product Decisions
- Erste Prüfung durch die Factory zusätzlich zur Bestätigung in `/init`: so fallen Lücken auf, die im Interview niemand gesehen hat ({{DATE}}).
