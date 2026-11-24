# PROJ-4: Deploy nach staging

**Status:** Planned
**Typ:** Plattform
**Erstellt:** {{DATE}}

## Abhängigkeiten
- PROJ-3 (Health-Check)

## Voraussetzungen (Mensch)
- [ ] Infisical-Projekt `{{PROJECT}}` (Cloud EU) mit den Umgebungen `staging` und `production`
- [ ] Maschinen-Identität für GitHub mit OIDC Auth, Subject `repo:{{OWNER}}/{{REPO}}:environment:staging` (Repos, die nach dem 15. Juli 2026 angelegt wurden, haben ein Subject mit IDs: `repo:<owner>@<id>/<repo>@<id>:environment:staging`, Präfix per `gh api repos/{{OWNER}}/{{REPO}}/actions/oidc/customization/sub`), Lesezugriff nur auf `staging`
- [ ] Variablen `INFISICAL_PROJECT_ID` und `INFISICAL_IDENTITY_ID` im GitHub-Repo gesetzt (Variablen, keine Secrets)
- [ ] GitHub-Umgebung `staging` existiert (legt `scripts/add-repo.sh` der Factory an)
<!-- nur wenn: staging auf dem Factory-Server, tier compose oder kamal -->
- [ ] Factory-Server als Deploy-Host eingerichtet (`host/install.sh` aus factory-pipelines {{PIPELINES_VERSION}} mit `--sites-dir /etc/software-factory/sites.d`)
<!-- nur wenn: staging auf eigener VM, tier compose oder kamal -->
- [ ] staging-Host ({{STAGING_HOST}}) per cloud-init aus `factory-pipelines/templates/cloud-init/compose-host.yaml` angelegt
<!-- nur wenn: tier compose oder kamal -->
- [ ] Host-Identität (Universal Auth) mit Lesezugriff auf `staging`, Client-Secret nach dem ersten Start erneuert
<!-- nur wenn: tier k3s -->
- [ ] k3s-Server für staging ({{STAGING_HOST}}) mit `factory-pipelines/templates/cloud-init/k3s-host.yaml` ({{PIPELINES_VERSION}}) als User-Data angelegt, dazu ein Deploy-Key nur mit Lesezugriff auf das Repo (bei privatem Repo) und eine Maschinen-Identität (Universal Auth) für den Cluster mit Lesezugriff auf `staging`; beide nach dem Bootstrap erneuert, weil die User-Data beim Anbieter lesbar bleibt
<!-- nur wenn: tier compose oder kamal -->
- [ ] Secrets in Infisical `staging`: `DEPLOY_HOST`, `DEPLOY_SSH_KEY`, `DEPLOY_HOST_KEY`, `HEALTH_TOKEN` und alle App-Secrets aus `docs/operations.md` (Abschnitt „Secrets“)
<!-- nur wenn: tier k3s -->
- [ ] Secrets in Infisical `staging`: `HEALTH_TOKEN`, bei privatem Image `GHCR_PULL_TOKEN` (Token mit `read:packages`), und alle App-Secrets aus `docs/operations.md` (Abschnitt „Secrets“)
- [ ] DNS: `{{STAGING_DOMAIN}}` zeigt auf den staging-Host

## User Stories
- Als Projektverantwortliche:r möchte ich, dass jeder Merge auf `main` automatisch nach staging ausgerollt und geprüft wird, damit ich jede Änderung in einer echten Umgebung sehe, bevor sie nach production geht.
- Als Projektverantwortliche:r möchte ich, dass ein kaputter Deploy automatisch zurückgerollt und gemeldet wird, damit staging nicht unbemerkt kaputt bleibt.

## Außerhalb des Umfangs
- production (PROJ-5)
- Backups (PROJ-6), Heartbeats und Logs (PROJ-7)
- Den Host selbst einrichten (macht der Mensch per cloud-init)

## Akzeptanzkriterien
<!-- nur wenn: tier compose oder kamal -->
- [ ] AK-1: Angenommen das Repo, dann enthält `.factory/delivery.json` unter `environments.staging` `port: {{STAGING_PORT}}`, `domain: "{{STAGING_DOMAIN}}"`, `autoDeploy: true` und `data: "{{STAGING_DATA}}"`, und der Check `delivery-config` ist grün.
<!-- nur wenn: tier k3s -->
- [ ] AK-1: Angenommen das Repo, dann enthält `.factory/delivery.json` unter `environments.staging` `domain: "{{STAGING_DOMAIN}}"` (ohne `port`; über die Domain prüft die Pipeline den Erfolg von außen), `autoDeploy: true` und `data: "{{STAGING_DATA}}"`, und der Check `delivery-config` ist grün.
<!-- nur wenn: tier compose oder kamal -->
- [ ] AK-2: Angenommen `deploy/compose.yml`, dann enthält sie keine Secrets, jeder Dienst hat ein Speicherlimit, die App lauscht nur auf `127.0.0.1:${PORT}`, Migrationen laufen im Dienst `migrate` (Profil `migrate`), und der Check `compose` (`docker compose config`) ist grün. In der Stufe kamal gibt es keine weitere Projektdatei (kein `config/deploy.yml`).
<!-- nur wenn: tier k3s -->
- [ ] AK-2: Angenommen `deploy/k3s/values.yaml`, dann enthält sie keine Secrets, setzt `app.port` und `app.resources` (Requests und Speicherlimit) sowie den Befehl für Migrationen (`migrate.command`), und der Check `k3s-values` ist grün. Das Projekt hat kein eigenes Helm-Chart; das Chart `charts/factory-app` kommt aus factory-pipelines.
- [ ] AK-3: Angenommen ein PR ist gemergt, wenn der Workflow `delivery` auf `main` läuft, dann wird das Image mit seinem Digest nach GHCR gepusht und automatisch nach staging ausgerollt. _(nach dem Merge)_
- [ ] AK-4: Angenommen der Deploy ist durchgelaufen, wenn `https://{{STAGING_DOMAIN}}/readyz` abgefragt wird, dann antwortet die App mit 200, und `/health` meldet den ausgerollten Commit. _(nach dem Merge)_
- [ ] AK-5: Angenommen ein Deploy nach staging, dann kommentiert die Pipeline Umgebung, Digest und Health-Ergebnis am PR bzw. Commit. _(nach dem Merge)_
- [ ] AK-6: Angenommen das Health-Gate schlägt nach einem Deploy fehl, dann rollt die Pipeline auf den vorherigen Digest zurück und öffnet ein Issue mit Label `deploy-failed`. _(nach dem Merge, sobald ein Deploy fehlschlägt; das Verhalten selbst ist im Selbsttest von factory-pipelines belegt)_
<!-- nur wenn: staging-Daten seed, tier compose oder kamal -->
- [ ] AK-7: Angenommen `deploy/compose.yml`, dann enthält sie einen Dienst `seed` mit `profiles: [seed]`, demselben Image wie die App, Entrypoint `/factory/with-secrets` und Abhängigkeit von der Datenbank; sein Befehl (z. B. `npm run seed`) füllt eine leere Datenbank mit synthetischen Beispieldaten ohne personenbezogene Daten und erzeugt bei zweimaligem Lauf keine Duplikate (belegt durch einen Test).
<!-- nur wenn: staging-Daten seed, tier k3s -->
- [ ] AK-7: Angenommen `deploy/k3s/values.yaml`, dann setzt sie `seed.command` (z. B. `["npm", "run", "seed"]`); der Befehl füllt eine leere Datenbank mit synthetischen Beispieldaten ohne personenbezogene Daten und erzeugt bei zweimaligem Lauf keine Duplikate (belegt durch einen Test).
<!-- nur wenn: staging-Daten anonymized-copy -->
- [ ] AK-7: Angenommen `deploy/anonymize.sql`, dann überschreibt es jede Spalte mit personenbezogenen Daten (laut Datenmodell) mit synthetischen Werten, und `docs/operations.md` begründet die anonymisierte Kopie. (factory-pipelines v0.3.0 spielt die Kopie noch nicht ein.)
- [ ] AK-8: Angenommen das Repo, dann enthält es keinen Secret-Wert, und jeder Secret-Name, den die App erwartet, steht in `docs/operations.md`.

## Edge Cases
- EC-1: Infisical ist beim Deploy nicht erreichbar → Deploy bricht vor dem Umschalten ab, die laufende Version bleibt, Issue `deploy-failed`.
- EC-2: Derselbe Digest wird zweimal ausgerollt → keine Änderung, kein Neustart der Datenbank.
- EC-3: Eine Migration schlägt fehl → kein Umschalten, die alte Version läuft weiter.
- EC-4: Der Seed läuft bei jedem staging-Deploy erneut → vorhandene Beispieldaten bleiben unverändert, keine Duplikate.

## Technische Anforderungen (optional)
- Vorlagen aus `factory-pipelines` in Version {{PIPELINES_VERSION}} (Stufen compose und kamal: `templates/compose.yml`; Stufe k3s: Chart `charts/factory-app` mit `deploy/k3s/values.yaml`, Beispiel in `examples/demo-app/deploy/k3s/values.yaml`), keine eigene Deploy-Logik im Projekt.
- Stufe: {{TIER}}. Host: {{STAGING_HOST}}.

## Offene Fragen
- [ ] _keine_

## Product Decisions
- staging deployt automatisch bei jedem Push auf `main` ({{DATE}}).
