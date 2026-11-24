# PROJ-3: Health-Check

**Status:** Planned
**Typ:** Plattform
**Erstellt:** {{DATE}}

## Abhängigkeiten
- PROJ-2 (CI und Test-Umgebung)

## Voraussetzungen (Mensch)
- [ ] Liste der Health-Komponenten in `docs/operations.md` (Abschnitt „Health“) bestätigt: {{HEALTH_COMPONENTS}}

## User Stories
- Als Pipeline möchte ich nach jedem Deploy prüfen können, ob die App bereit ist und den richtigen Commit ausführt, damit ich bei einem Fehler automatisch zurückrollen kann.
- Als Projektverantwortliche:r möchte ich den Zustand jeder Hauptkomponente an einer geschützten Stelle sehen, damit ich bei einem Alarm schnell weiß, was ausgefallen ist.

## Außerhalb des Umfangs
- Heartbeats und Alarme (PROJ-7)
- App-Metriken (`/metrics`, PROJ-7)

## Akzeptanzkriterien
- [ ] AK-1: Angenommen die App läuft, wenn `/livez` abgefragt wird, dann antwortet sie mit HTTP 200, auch wenn eine abhängige Komponente ausgefallen ist.
- [ ] AK-2: Angenommen alle kritischen Komponenten sind erreichbar und der Migrationsstand entspricht dem Image, wenn `/readyz` abgefragt wird, dann antwortet sie mit HTTP 200; sonst mit HTTP 503. Der Antwortkörper enthält in beiden Fällen keine Details zu Komponenten oder Fehlern.
- [ ] AK-3: Angenommen eine Anfrage an `/health` ohne `Authorization`-Header oder mit falschem Token, dann antwortet die App mit HTTP 401 und ohne Details.
- [ ] AK-4: Angenommen eine Anfrage an `/health` mit `Authorization: Bearer <HEALTH_TOKEN>`, dann antwortet die App mit JSON mit `status`, `version`, `commit` und `checks`; `checks` enthält genau einen Eintrag pro Komponente aus `health.components` in `.factory/delivery.json`, jeweils mit `status`, `critical` und `latencyMs` bzw. `error`.
- [ ] AK-5: Angenommen eine kritische Komponente ist ausgefallen, wenn `/health` abgefragt wird, dann ist `status` `down` und die Antwort HTTP 503; ist nur eine unkritische ausgefallen, ist `status` `degraded` und die Antwort HTTP 200.
- [ ] AK-6: Angenommen eine Komponente antwortet nicht, wenn `/health` oder `/readyz` abgefragt wird, dann gilt sie nach höchstens 3 Sekunden als `down` mit `error: "timeout"`, und der Endpunkt antwortet nach höchstens 5 Sekunden.
- [ ] AK-7: Angenommen das Image wurde mit `GIT_COMMIT` und `APP_VERSION` gebaut, dann liefert `/health` genau diese Werte in `commit` und `version`.
- [ ] AK-8: Angenommen die E2E-Tests in CI, dann decken sie alle drei Endpunkte ab, einschließlich 401 bei fehlendem Token und eines ausgefallenen Dienstes (in der Test-Umgebung herbeigeführt).
- [ ] AK-9: Angenommen eine Health-Anfrage, dann erscheinen weder das Token noch Zugangsdaten von Komponenten in Antwort oder Log.

## Edge Cases
- EC-1: Eine Komponente aus `health.components` gibt es im Code noch nicht → Check trotzdem anlegen oder die Komponente in `docs/operations.md` begründet aus `health.components` entfernen (im PR aufführen).
- EC-2: `HEALTH_TOKEN` ist nicht gesetzt → `/health` antwortet immer 401, die App startet trotzdem.
- EC-3: Viele gleichzeitige Anfragen an `/health` → Prüfungen laufen nicht mehrfach parallel gegen dieselbe Komponente (kurzer Cache von wenigen Sekunden erlaubt).

## Technische Anforderungen (optional)
- Format und Regeln: Konventionen der Software Factory, Abschnitt Health-Check.
- Compose-Healthcheck in `deploy/compose.test.yml` und später `deploy/compose.yml` auf `/livez`.

## Offene Fragen
- [ ] _keine_

## Product Decisions
- `/readyz` und `/livez` bleiben öffentlich ohne Details, `/health` nur mit Token ({{DATE}}).
