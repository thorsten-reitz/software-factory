# PROJ-2: CI und Test-Umgebung

**Status:** Planned
**Typ:** Plattform
**Erstellt:** {{DATE}}

## Abhängigkeiten
- PROJ-1 (Konventionen prüfen)

## Voraussetzungen (Mensch)
- [ ] GitHub Actions ist im Repo erlaubt, auch für wiederverwendbare Workflows aus `thorsten-reitz/factory-pipelines` (Settings → Actions → General)
- [ ] GitHub Packages (GHCR) ist für das Repo bzw. die Organisation nicht gesperrt

## User Stories
- Als Projektverantwortliche:r möchte ich, dass jeder Pull Request automatisch Checks, Image-Bau und E2E-Tests gegen genau das gebaute Image durchläuft, damit ich nur geprüfte Änderungen merge.
- Als Factory möchte ich, dass CI dieselben Checks ausführt wie `factory-verify`, damit lokal grün und CI grün dasselbe bedeuten.

## Außerhalb des Umfangs
- Vollständiger Health-Standard mit `/health` und Komponenten (PROJ-3); hier nur ein minimales `/livez` und `/readyz`, weil die Test-Umgebung sie prüft
- Deploy nach staging oder production (PROJ-4, PROJ-5)
- Eigene Pipeline-Logik im Projekt: die Logik liegt in `factory-pipelines`

## Akzeptanzkriterien
- [ ] AK-1: Angenommen ein Pull Request wird geöffnet oder aktualisiert, wenn GitHub die Workflows startet, dann läuft `.github/workflows/delivery.yml` automatisch mit Konfigurationsprüfung, allen Checks aus `.factory/setup.json`, Image-Bau und Test-Umgebung, und auf dem PR dieser Spec ist der Lauf grün.
- [ ] AK-2: Angenommen `.factory/delivery.json` enthält einen unbekannten Schlüssel, wenn der Check `delivery-config` läuft, dann schlägt er fehl und die Meldung nennt den Schlüssel.
- [ ] AK-3: Angenommen das Repo, wenn `hadolint --failure-threshold error Dockerfile` läuft, dann meldet es keinen Fehler; das Image läuft als Nicht-root-Nutzer und nimmt die Build-Argumente `GIT_COMMIT` und `APP_VERSION` an.
- [ ] AK-4: Angenommen die Test-Umgebung aus `deploy/compose.test.yml` läuft mit dem gebauten Image, wenn `/livez` und `/readyz` abgefragt werden, dann antworten beide mit HTTP 200.
- [ ] AK-5: Angenommen die App läuft, aber eine kritische Abhängigkeit (z. B. die Datenbank) ist nicht erreichbar, wenn `/livez` und `/readyz` abgefragt werden, dann antwortet `/livez` mit 200 und `/readyz` mit 503.
- [ ] AK-6: Angenommen die Test-Umgebung läuft, wenn CI den Befehl `e2e` aus `.factory/setup.json` mit `BASE_URL` ausführt, dann läuft mindestens ein E2E-Test (Startseite bzw. Einstiegspunkt der App lädt) grün.
- [ ] AK-7: Angenommen `factory-verify` läuft, dann enthält `.factory/setup.json` die Checks `delivery-config`, `workflows`, `dockerfile` und `compose-test` und alle sind grün.
- [ ] AK-8: Angenommen ein Push auf `main`, wenn der Workflow läuft, dann baut er das Image und deployt nichts, weil `.factory/delivery.json` noch keine Umgebung `staging` oder `production` enthält. _(nach dem Merge)_
- [ ] AK-9: Angenommen das Repo, dann enthalten weder Workflow noch `deploy/compose.test.yml` noch `Dockerfile` Secrets außer erkennbaren Testwerten (z. B. `test-health-token`).

## Edge Cases
- EC-1: Das Projekt hat keine Datenbank → `deploy/compose.test.yml` startet nur die App, `/readyz` prüft nur, ob die App Anfragen bedienen kann.
- EC-2: Der Stack ist nicht Node → `e2e` nutzt das Test-Werkzeug des Stacks, das Image baut nach den Regeln des Stack-Packs.
- EC-3: Ein Check ist rot → CI zeigt alle Checks mit Ergebnis in der Zusammenfassung, nicht nur den ersten roten.

## Technische Anforderungen (optional)
- Aufruf-Workflow aus `factory-pipelines/templates/delivery.yml` in Version {{PIPELINES_VERSION}}: die Auslöser `pull_request` und `push` (Branch `main`) einschalten, sonst nichts ändern.
- `deploy/compose.test.yml` aus `factory-pipelines/templates/compose.test.yml`, `.dockerignore` aus `templates/dockerignore`. Die App ist in der Test-Umgebung unter `environments.test.url` erreichbar (Standard `http://localhost:8080`).
- Datenbank-Migrationen laufen in der Test-Umgebung als Dienst `migrate` vor der App (Befehl `migrate`, siehe Stack-Pack).

## Offene Fragen
- [ ] _keine_

## Product Decisions
- `/livez` und `/readyz` entstehen minimal schon hier, weil die Test-Umgebung der Pipeline sie prüft. PROJ-3 baut den vollständigen Standard ({{DATE}}).
