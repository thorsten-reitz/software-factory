# Betrieb: {{PROJECT}}

> Angelegt von `/init` am {{DATE}}. Grundlage: Betriebskonventionen der Software Factory (`conventions/README.md` im Factory-Repo).
> Ohne Angabe gilt die Konvention. Jede Abweichung steht in `.factory/delivery.json` und unten unter „Abweichungen“ mit Begründung.
> **Hier stehen nie Secret-Werte**, nur ihre Namen.

## 1. Umgebungen und Ort

| Umgebung | Host | Domain | Port (127.0.0.1) | Auslöser | Daten |
|---|---|---|---|---|---|
| test | GitHub-Runner (nur CI) | – | – | jeder PR | Testwerte aus `deploy/compose.test.yml` |
| staging | {{STAGING_HOST}} | {{STAGING_DOMAIN}} | {{STAGING_PORT}} | Push auf `main` | {{STAGING_DATA}} |
| production | {{PRODUCTION_HOST}} | {{PRODUCTION_DOMAIN}} | {{PRODUCTION_PORT}} | Freigabe an der GitHub-Umgebung `production` | echte Daten |

Server bereitstellen: {{PROVISIONING}} (Vorlage `factory-pipelines/templates/cloud-init/`).

`staging` und `production` kommen erst mit PROJ-4 bzw. PROJ-5 in `.factory/delivery.json`, wenn Host und Secrets bereitstehen. Bis dahin gilt diese Tabelle als Plan.

<!-- nur wenn: production auf dem Factory-Server -->
**Hinweis:** production läuft auf dem Factory-Server. Ressourcen werden mit den Agent-Läufen geteilt, und ein Ausfall des Servers trifft Factory, Monitoring und production gleichzeitig.

## 2. Orchestrierungs-Stufe

- **Stufe:** {{TIER}}
- **Begründung:** _Kriterien aus dem Leitfaden: Anzahl Dienste und Hosts, Downtime beim Deploy, Erfahrung, Kosten_
- **Zielstufe später:** _nur wenn abweichend, z. B. „k3s, sobald factory-pipelines v0.3 verfügbar ist“_

**Kapazität des Factory-Servers** (nur wenn eine Umgebung dort läuft):

| Posten | RAM |
|---|---|
| Server gesamt | _16 GB_ |
| Agent-Läufe (maxParallel × 3 GB) | _− 6 GB_ |
| Observability | − 1,5 GB |
| System, Runner, Caddy | − 1 GB |
| Vorschauen (0,5 GB je offene Vorschau) | _− …_ |
| andere Umgebungen auf dem Server | _− …_ |
| **frei** | _…_ |
| diese Umgebung(en), Summe der Speicherlimits | _…_ |

## 3. Zustand, Backup und Restore

**Zustand** (`state` in `.factory/delivery.json`):

| Art | Name | Inhalt | PITR |
|---|---|---|---|
| _postgres_ | _db_ | _Anwendungsdaten_ | _nein_ |
| _volume_ | _uploads_ | _hochgeladene Dateien_ | – |

- **Backup:** restic nach S3, täglich und vor jedem Produktions-Deploy, Aufbewahrung 7 täglich / 4 wöchentlich / 12 monatlich.
- **Restore-Test:** wöchentlich auf dem Host, Ergebnis als Heartbeat an den Watchdog.
- **Restic-Repository:** `s3:<endpoint>/<bucket>/{{PROJECT}}/<umgebung>`
- **Offline-Kopie von `RESTIC_PASSWORD`:** _Ort, z. B. „Passwortmanager von …, Eintrag {{PROJECT}} restic“ (nie den Schlüssel selbst)_
- **staging-Daten:** {{STAGING_DATA}}
<!-- nur wenn: staging-Daten seed -->
- **Seed:** Dienst `seed` in `deploy/compose.yml` (Profil `seed`, idempotent), läuft bei jedem staging-Deploy nach den Migrationen. Nie personenbezogene Daten.
<!-- nur wenn: staging-Daten anonymized-copy -->
- **Anonymisierung:** `deploy/anonymize.sql`, wird bei jeder Schemaänderung mitgepflegt. In factory-pipelines v0.2.0 noch nicht umgesetzt. DSGVO: _Begründung, warum eine anonymisierte Kopie nötig und zulässig ist_

## 4. Health

Endpunkte: `/livez`, `/readyz`, `/health` (nur mit `Authorization: Bearer $HEALTH_TOKEN`).

| Komponente | kritisch | Was geprüft wird |
|---|---|---|
| _db_ | _ja_ | _Verbindung und Migrationsstand_ |

## 5. Observability und Watchdog

- **Logs und Host-Metriken:** _an / aus_ (Grafana auf dem Factory-Server)
- **App-Metriken (`/metrics`):** _an / aus_
- **Watchdog:** _healthchecks.io_ mit den Checks:

| Check | Meldet | Ausbleiben bedeutet |
|---|---|---|
| `{{PROJECT}}-staging` | Heartbeat alle 5 Minuten bei grünem `/readyz` | staging nicht bereit oder Host down |
| `{{PROJECT}}-production` | Heartbeat alle 5 Minuten bei grünem `/readyz` | production nicht bereit oder Host down |
| `{{PROJECT}}-backup` | nach jedem Backup | Backup ausgefallen |
| `{{PROJECT}}-restore-test` | nach jedem Restore-Test | Restore-Test ausgefallen oder fehlgeschlagen |

- **GitHub-Actions-Probe:** _aus / alle N Minuten_
- **Externer HTTP-Check:** _keiner / UptimeRobot_

Alarme erscheinen als Issue mit Label `incident`, Deploy-Fehler als Issue mit Label `deploy-failed`. Beide bearbeitet die Factory nur, wenn du das Label `factory` setzt.

## 6. Secrets

Infisical Cloud EU, Projekt `{{PROJECT}}`, Umgebungen `staging` und `production`. Im GitHub-Repo nur die Variablen `INFISICAL_PROJECT_ID` und `INFISICAL_IDENTITY_ID`.

| Name | staging | production | Zweck |
|---|---|---|---|
| `DEPLOY_HOST`, `DEPLOY_SSH_KEY`, `DEPLOY_HOST_KEY` | ✓ | ✓ | Deploy per Forced Command |
| `HEALTH_TOKEN` | ✓ | ✓ | Zugang zu `/health` |
| `RESTIC_REPOSITORY`, `RESTIC_PASSWORD`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` | ✓ | ✓ | Backup |
| `HC_PING_URL`, `HC_PING_URL_BACKUP`, `HC_PING_URL_RESTORE_TEST` | ✓ | ✓ | Watchdog |
| _`DATABASE_URL`, `POSTGRES_PASSWORD`_ | ✓ | ✓ | _App_ |

**Abhängigkeit von Infisical:** Laufende Container arbeiten weiter, wenn Infisical nicht erreichbar ist. Deploys und der Neustart eines Hosts brauchen Infisical.

## 7. Feature-Flags

- **OpenFeature + flagd:** _an / noch nicht eingerichtet (das erste Feature mit Flag richtet es ein)_
- **Datei:** `flags/flags.json`, Unterschiede je Umgebung über Targeting auf `environment`.

## 8. Zusätzliche Anforderungen

_Verfügbarkeitsziel, Aufbewahrungspflichten, Datenstandort, Kundenvorgaben. Jeweils mit der Entscheidung, wie die Konvention sie erfüllt. „Keine“, wenn es keine gibt._

## 9. Abweichungen von der Konvention

| Was | Statt Konvention | Begründung | Datum |
|---|---|---|---|
| _–_ | | | |

## 10. Runbooks

- **Deploy:** automatisch nach staging bei jedem Push auf `main`; production nach Freigabe an der Umgebung `production` (Actions → delivery → Lauf → „Review deployments“).
- **Rollback:** automatisch, wenn das Health-Gate fehlschlägt. Manuell: Actions → delivery → Run workflow → `rollback`, Umgebung wählen.
- **Restore:** Actions → delivery → Run workflow → `restore`, Umgebung, Snapshot `latest` oder Datum. production nur mit Freigabe.
- **Wiederanlauf auf neuem Host:** Host per cloud-init anlegen, `DEPLOY_HOST`/`DEPLOY_HOST_KEY` in Infisical aktualisieren, Deploy, Restore. Einmal pro Quartal als Übung empfohlen.
- **Incident:** Issue mit Label `incident` lesen, Grafana-Dashboard `{{PROJECT}}` öffnen, bei Bedarf Label `factory` setzen.

## 11. Einmalige Schritte (Mensch)

- [ ] Infisical-Projekt `{{PROJECT}}` (EU) mit Umgebungen `staging` und `production`
- [ ] OIDC-Identität für GitHub (Subject-Präfix: `gh api repos/{{OWNER}}/{{REPO}}/actions/oidc/customization/sub`), Variablen `INFISICAL_PROJECT_ID` und `INFISICAL_IDENTITY_ID` im Repo
- [ ] Hosts bereit (cloud-init bzw. `host/install.sh` auf dem Factory-Server), Host-Identitäten
- [ ] DNS für {{STAGING_DOMAIN}} und {{PRODUCTION_DOMAIN}}
- [ ] S3-Bucket, Zugangsschlüssel, Offline-Kopie von `RESTIC_PASSWORD`
- [ ] healthchecks.io-Checks und `HC_PING_URL*` in Infisical
- [ ] GitHub-Umgebungen `staging` und `production` (production: Freigabe durch dich, nur `main`)
