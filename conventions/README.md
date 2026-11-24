# Betriebskonventionen für Factory-Projekte

Leitfaden für den Betrieb jedes Projekts, das die Software Factory baut. Hintergrund und Begründungen: [Vorschlag Betriebskonventionen](../docs/proposals/betriebskonventionen.md). Die Pipelines, Host-Skripte und Projektvorlagen liegen im öffentlichen Repo [`thorsten-reitz/factory-pipelines`](https://github.com/thorsten-reitz/factory-pipelines).

`/init` arbeitet diesen Leitfaden im Interview ab (Abschnitt „Betrieb“), schreibt die Entscheidungen in das Projekt und erzeugt aus [`specs/`](specs/) die Plattform-Specs, mit denen die Factory die Pipelines baut.

## Inhalt

| Pfad | Zweck |
|---|---|
| [`templates/operations.de.md`](templates/operations.de.md), [`templates/operations.en.md`](templates/operations.en.md) | Vorlage für `docs/operations.md` im Projekt |
| [`templates/delivery.example.json`](templates/delivery.example.json) | vollständiges Beispiel für `.factory/delivery.json` (alle Schalter) |
| [`specs/de/`](specs/de/), [`specs/en/`](specs/en/) | Vorlagen der Plattform-Specs PROJ-1 bis PROJ-7 |

## Grundsätze

- **Konvention vor Konfiguration:** Ohne Angabe gilt der Standard. Jede Abweichung steht in `.factory/delivery.json` und ist in `docs/operations.md` begründet.
- **Ein Image, viele Umgebungen:** einmal gebaut, staging und production bekommen denselben Digest.
- **Gemergt und freigegeben wird vom Menschen.** Die Factory merged nie, production braucht immer eine Freigabe.
- **Die Factory sieht nie Produktions-Secrets oder -Daten.** Secret-Namen stehen in `docs/operations.md`, die Werte setzt der Mensch in Infisical.

## Dateien im Projekt

| Datei | Von wem | Inhalt |
|---|---|---|
| `docs/operations.md` | `/init`, ergänzt von PROJ-1 und jedem Feature mit neuem Zustand oder Secret | Betriebsentscheidungen, Abweichungen, Secret-Namen, Runbooks |
| `.factory/delivery.json` | `/init`, ergänzt von den Plattform-Specs | Betriebsschalter, Schema: `factory-pipelines/schema/delivery.schema.json` |
| `.factory/setup.json` | `/init` | `install`, `checks` (inkl. Plattform-Checks), `e2e`, optional `seed` für die lokale Entwicklung |
| `.github/workflows/delivery.yml` | `/init` (nur manueller Start), PROJ-2 schaltet PR und Push ein | Aufruf von `thorsten-reitz/factory-pipelines/.github/workflows/delivery.yml@v0.3.0`, Rechte mit `contents: write` (die Stufe k3s schreibt den Stand je Umgebung in den Branch `factory-deploy`; die Pipeline verlangt das Recht in jeder Stufe, mit `contents: read` startet der Lauf nicht) |
| `.github/CODEOWNERS` | `/init` | Review für `.github/`, `.factory/delivery.json`, `deploy/` |
| `Dockerfile`, `.dockerignore`, `deploy/compose.test.yml` | PROJ-2 | Image und Test-Umgebung in CI |
| `deploy/compose.yml` | PROJ-4 | staging und production (Stufen compose und kamal), mit den Diensten `migrate` und, bei synthetischen staging-Daten, `seed` |
| `deploy/k3s/values.yaml` | PROJ-4 (Stufe k3s) | nur projektspezifische Werte für das Chart aus factory-pipelines: Port der App, Befehle für Migrationen und Seed, Ressourcen, Pfade der Volumes; kein eigenes Chart |
| `flags/flags.json` | erstes Feature hinter einem Flag | OpenFeature/flagd-Flags |

### Warum der Aufruf-Workflow zuerst nur manuell startet

`/init` legt `.github/workflows/delivery.yml` an, aber nur mit dem Auslöser `workflow_dispatch`. Ohne `Dockerfile` und Test-Umgebung wäre jeder PR rot, auch der PR der Factory für PROJ-1. PROJ-2 baut Image und Test-Umgebung und schaltet im selben PR `pull_request` und `push` ein. Der Lauf auf diesem PR ist dann schon der Beleg für die Abnahme.

Aus demselben Grund enthält `.factory/delivery.json` nach `/init` unter `environments` nur `test`. Die Einträge `staging` (PROJ-4) und `production` (PROJ-5) kommen erst mit ihren Specs, wenn die Voraussetzungen erfüllt sind. Sonst würde schon der erste Push auf `main` einen Deploy ohne Host und Secrets versuchen. Geplante Domains, Ports und Hosts stehen bis dahin in `docs/operations.md`.

## Umgebungen und Ort

| Umgebung | Läuft | Auslöser | Daten |
|---|---|---|---|
| test | nur in CI (GitHub-Runner, Wegwerf-Dienste aus `deploy/compose.test.yml`) | jeder PR | Testwerte |
| staging | Vorschlag: Factory-Server | Push auf `main` (`autoDeploy`) | `seed` (Standard, Dienst `seed` in `deploy/compose.yml`) oder `anonymized-copy` (noch nicht in factory-pipelines) |
| production | Vorschlag: eigene VM | Freigabe an der GitHub-Umgebung `production` | echte Daten |

production auf dem Factory-Server ist erlaubt. Dann gilt: Ressourcen werden mit den Agent-Läufen geteilt, und ein Ausfall des Servers trifft Factory, Monitoring und production gleichzeitig. Das steht dann als Abweichung in `docs/operations.md`.

**Synthetische Daten (`seed`):** Auf dem Host liegt kein Quellcode, `.factory/setup.json` → `seed` läuft dort also nicht. Stattdessen definiert `deploy/compose.yml` einen Dienst `seed` mit `profiles: [seed]`, demselben Image, Entrypoint `/factory/with-secrets` und einem idempotenten Befehl (z. B. `npm run seed`), siehe `templates/compose.yml` in factory-pipelines. `factory-host` startet ihn bei jedem staging-Deploy nach den Migrationen, wenn `environments.staging.data` `seed` ist (Standard). Ohne Dienst `seed` passiert nichts. Ein `seed`-Befehl in `package.json` bzw. `.factory/setup.json` für die lokale Entwicklung kann bleiben.

`anonymized-copy` ist in factory-pipelines v0.3.0 noch nicht umgesetzt (der Deploy vermerkt es nur im Log). Für staging nur mit Hinweis auf die DSGVO-Folgen (besonders, wenn staging auf dem Factory-Server läuft) und darauf, dass das Anonymisierungs-SQL bei jeder Schemaänderung mitgepflegt werden muss.

## Orchestrierungs-Stufe wählen

| Stufe | `tier` | Passt, wenn | Downtime beim Deploy | Vorlagen in factory-pipelines |
|---|---|---|---|---|
| **Compose + Caddy** (Standard) | `compose` | ein Host pro Umgebung, bis etwa 5 Dienste, wenige Sekunden Unterbrechung beim Deploy vertretbar | wenige Sekunden | verfügbar (seit v0.1) |
| **Kamal (kamal-proxy)** | `kamal` | wie compose (ein Host pro Umgebung, bis etwa 5 Dienste), aber Deploys ohne Unterbrechung nötig | keine | verfügbar (seit v0.2) |
| **k3s + Argo CD** | `k3s` | viele Dienste (ab etwa 6–8), Jobs oder Operatoren aus dem Kubernetes-Ökosystem, oder Kundenvorgabe Kubernetes; ein Knoten pro Cluster | keine (Rolling Update) | verfügbar (seit v0.3), ein Knoten pro Cluster |
| **Verwaltetes Kubernetes** | – (nur dokumentiert) | Hochverfügbarkeit über Zonen, Compliance- oder Kundenvorgabe | keine | keine, wie k3s mit Cluster vom Anbieter |

**So funktioniert die Stufe kamal:** Sie nutzt nur [kamal-proxy](https://github.com/basecamp/kamal-proxy), nicht die Kamal-CLI, und braucht keine eigene Projektdatei (kein `config/deploy.yml`). Das Projekt behält dieselbe `deploy/compose.yml` wie in der Stufe compose, nur `"tier": "kamal"` in `.factory/delivery.json` ändert sich. `factory-host` startet den Dienst `app` dann als eigenen Container pro Release; ein kleiner kamal-proxy je App und Umgebung auf `127.0.0.1:<port>` schaltet den Verkehr erst um, wenn `/readyz` grün ist, und lässt den alten Container auslaufen. Caddy, Port-Konvention, Health-Gate, Secrets, Backup und Seed sind identisch. Kosten: etwa 20 MB RAM pro App und Umgebung für den Proxy. Der Wechsel von compose zu kamal ist eine Zeile; der erste Deploy danach hat einmal eine kurze Unterbrechung. Ohne Kamal-CLI, weil sie einen SSH-Zugang mit Shell und Docker-Rechten (praktisch root) bräuchte; so bleibt der Deploy-Schlüssel auf deploy, rollback, restore und status beschränkt.

**So funktioniert die Stufe k3s:** GitOps mit Argo CD; die Pipeline hat keinen Zugang zum Cluster und keinen SSH-Schlüssel. Das Projekt hat **kein eigenes Helm-Chart**: Das Chart `charts/factory-app` liegt in factory-pipelines, Argo CD lädt es im selben Stand wie den Workflow. Im Projekt liegt nur, falls nötig, `deploy/k3s/values.yaml` (Port der App, Befehle für Migrationen und Seed, Ressourcen, Pfade der Volumes; [Beispiel](https://github.com/thorsten-reitz/factory-pipelines/blob/v0.3.0/examples/demo-app/deploy/k3s/values.yaml)); alles andere kommt aus `.factory/delivery.json`. CI schreibt `argocd/<umgebung>/application.json` in den Branch `factory-deploy`, wartet, bis `/health` von außen den neuen Commit meldet, und hält den Stand dann als `state/<umgebung>/good.json` fest; schlägt das fehl, schaltet sie auf den letzten guten Stand zurück. Rollback ist der vorherige gute Stand. Ein Restore ist eine Anfrage im selben Branch: Das Chart legt den Job `restore-<id>` an, der die App anhält, zurückspielt und wieder startet, und meldet das Ergebnis an `HC_PING_URL_RESTORE`. Deshalb braucht jede Umgebung in dieser Stufe `domain` (oder `url`), aber keinen `port`. Secrets kommen über den Infisical-Operator (`InfisicalStaticSecret` → Secret `app-secrets`); für private Images aus GHCR braucht jede Umgebung zusätzlich `GHCR_PULL_TOKEN` (Token mit `read:packages`). Den Cluster richtet `templates/cloud-init/k3s-host.yaml` ein (k3s mit `--secrets-encryption`, cert-manager, Argo CD, Infisical-Operator, Root-Application für `argocd/<umgebung>/`). **Grenze:** ein Knoten pro Cluster, der Zustand liegt auf dem Knoten (`local-path`). Mehrere Knoten brauchen verteilten Speicher und sind noch kein Grund für k3s.

Weitere Kriterien: verfügbare Kapazität (unten), Betriebserfahrung im Team, Kosten. **Im Zweifel die einfachere Stufe.** Ein späterer Wechsel bleibt überschaubar, weil Image und `delivery.json` gleich bleiben. k3s läuft immer auf eigenen Hosts, nie auf dem Factory-Server.

Verwaltetes Kubernetes und k3s mit mehreren Knoten liefert `factory-pipelines` nicht aus. Braucht ein Projekt das, empfiehlt `/init` die nächstpassende Stufe und hält die gewünschte Zielstufe mit Begründung in `docs/operations.md` fest.

### Kapazitätsrechnung für den Factory-Server

Bevor eine Umgebung auf den Factory-Server kommt, rechnet `/init` grob:

```
frei = RAM des Servers
     − maxParallel × 3 GB      (Agent-Läufe, Standard 2 × 3 GB)
     − 1,5 GB                  (Observability: Grafana, Loki, Prometheus)
     − 1 GB                    (System, Runner, Caddy)
     − 0,5 GB × offene Vorschauen
     − Summe der Speicherlimits der Umgebungen, die dort schon laufen
```

Beim Standard-Server (KVM 4, 16 GB, `maxParallel: 2`, ohne Vorschauen und ohne andere Umgebungen) bleiben etwa **7,5 GB**. Eine Umgebung braucht die Summe der Speicherlimits aus `deploy/compose.yml` (Vorlage: App 768 MB + Postgres 512 MB ≈ 1,3 GB). Passt eine Umgebung nur mit weniger als 1 GB Reserve, gehört sie auf eine eigene VM.

## Zustand, Backup und Restore

- **Alles mit Zustand** steht in `.factory/delivery.json` unter `state`: Postgres (`{"type": "postgres", "service": "db"}`) und Volumes (`{"type": "volume", "name": "uploads"}`). Was dort fehlt, wird weder gesichert noch im Restore-Test geprüft.
- **Backup:** restic nach S3 (Anbieter frei), täglich und vor jedem Produktions-Deploy, Aufbewahrung 7 täglich / 4 wöchentlich / 12 monatlich, wöchentlicher Restore-Test auf dem Host.
- **PITR** (`state[].pitr: true`, WAL-G) nur, wenn ein Datenverlust von bis zu einem Tag nicht tragbar ist. Noch nicht in factory-pipelines v0.1; bei Bedarf als Abweichung festhalten.
- **Schlüssel:** `RESTIC_PASSWORD` liegt in Infisical **und** offline. `docs/operations.md` nennt den Ort der Offline-Kopie, nie den Schlüssel.
- **Supabase** statt eigenem Postgres: Backup übernimmt Supabase (abhängig vom Tarif). Dann kein `postgres`-Eintrag in `state`, Abweichung in `docs/operations.md` begründen.

## Health-Check

Jede App stellt `/livez` (nur der Prozess), `/readyz` (kritische Abhängigkeiten, Migrationen aktuell, ohne Details) und `/health` (jede Komponente aus `health.components`, nur mit `Authorization: Bearer $HEALTH_TOKEN`) bereit. Format und Regeln: [Vorschlag §9](../docs/proposals/betriebskonventionen.md#9-health-check). Jede neue Abhängigkeit bekommt ihren Check (Regel im Skill `build`).

## Observability und Watchdog

- Logs und Host-Metriken gehen per Grafana Alloy an Grafana/Loki/Prometheus auf dem Factory-Server. Für production standardmäßig an (`observability.enabled`), App-Metriken (`/metrics`) als Schalter.
- **Watchdog:** healthchecks.io (Empfehlung, Heartbeat alle 5 Minuten nur bei grünem `/readyz`, dazu Backup und Restore-Test). Ergänzend GitHub-Actions-Probe (`watchdog.githubProbe`) oder externer HTTP-Check (`watchdog.externalHttp`).
- Alarme landen als Issue mit Label `incident` im Projekt, nie automatisch bei der Factory. Deploy-Fehler öffnet die Pipeline als Issue mit Label `deploy-failed`.

## Secrets

Infisical Cloud EU, pro Projekt ein Infisical-Projekt mit den Umgebungen `staging` und `production`. GitHub Actions holt Secrets per OIDC, im GitHub-Repo stehen nur die Variablen `INFISICAL_PROJECT_ID` und `INFISICAL_IDENTITY_ID`. Feste Namen:

| Name | Zweck |
|---|---|
| `DEPLOY_HOST`, `DEPLOY_SSH_KEY`, `DEPLOY_HOST_KEY` | Ziel-Host, Deploy-Schlüssel (nur Forced Command), Host-Schlüssel (Stufen compose und kamal) |
| `GHCR_PULL_TOKEN` | Stufe k3s mit privatem Image: Token mit `read:packages`, daraus entsteht das Pull-Secret |
| `HEALTH_TOKEN` | Zugang zu `/health` |
| `RESTIC_REPOSITORY`, `RESTIC_PASSWORD`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` | Backup-Ziel |
| `HC_PING_URL`, `HC_PING_URL_BACKUP`, `HC_PING_URL_RESTORE_TEST` | Heartbeats an healthchecks.io |
| `HC_PING_URL_RESTORE` | Stufe k3s: Ergebnis eines Restores auf Abruf |
| App-Secrets | z. B. `DATABASE_URL`, `POSTGRES_PASSWORD`, stehen in `docs/operations.md` |

## Feature-Flags

OpenFeature mit flagd, Flags in `flags/flags.json`, Unterschiede je Umgebung über Targeting auf `environment`. Größere Features baut die Factory hinter einem Flag, das in production zunächst aus ist. Das erste Feature, das ein Flag braucht, richtet OpenFeature ein und setzt `flags.enabled` auf `true`.

## Plattform-Specs

`/init` erzeugt aus [`specs/<sprache>/`](specs/) die Specs in `features/` und trägt sie mit Typ `Plattform` bzw. `Platform` in `features/INDEX.md` ein. Bau-Reihenfolge:

```
P0: PROJ-1 Konventionen prüfen → PROJ-2 CI (test) → PROJ-3 Health-Check → PROJ-4 Deploy staging → PROJ-5 Production-Freigabe
P1: PROJ-6 Backup + Restore-Test (braucht PROJ-4) · PROJ-7 Observability + Watchdog (braucht PROJ-4)
Produkt-Features ab PROJ-8, starten sobald PROJ-2 fertig ist
```

| Vorlage | Inhalt |
|---|---|
| `PROJ-1-conventions-check.md` | Factory gleicht Brief, PRD, Stack, Code und `docs/operations.md` ab und schließt Lücken |
| `PROJ-2-ci-test.md` | Image, Test-Umgebung, E2E im PR, Aufruf-Workflow einschalten |
| `PROJ-3-health-check.md` | `/livez`, `/readyz`, `/health` nach Standard |
| `PROJ-4-deploy-staging.md` | `deploy/compose.yml`, automatischer Deploy nach staging mit Health-Gate |
| `PROJ-5-production-approval.md` | production mit Freigabe, gleicher Digest |
| `PROJ-6-backup-restore.md` | Backup, Restore-Test, Restore auf Abruf, Runbook |
| `PROJ-7-observability-watchdog.md` | Logs, Metriken, Heartbeats, Incident-Ablauf |

**Format:** wie die Vorlagen von `/write-spec`, zusätzlich die Zeile `**Typ:** Plattform` (`**Type:** Platform`) im Kopf und der Abschnitt **Voraussetzungen (Mensch)** (**Prerequisites (human)**). Die Prüfung der Factory fragt nach, solange dort ein Punkt offen ist. Kriterien, die sich erst nach dem Merge belegen lassen, sind mit _(nach dem Merge)_ bzw. _(after merge)_ markiert.

**Platzhalter**, die `/init` ersetzt:

| Platzhalter | Wert |
|---|---|
| `{{DATE}}` | heutiges Datum, `YYYY-MM-DD` |
| `{{PROJECT}}` | Projektname (`project` in `delivery.json`, Standard: Repo-Name in Kleinbuchstaben) |
| `{{OWNER}}`, `{{REPO}}` | GitHub-Besitzer und Repo |
| `{{TIER}}` | `compose`, `kamal` oder `k3s` |
| `{{PROVISIONING}}` | `cloud-init` oder `opentofu` |
| `{{STAGING_DOMAIN}}`, `{{PRODUCTION_DOMAIN}}` | Domains |
| `{{STAGING_PORT}}`, `{{PRODUCTION_PORT}}` | Port auf `127.0.0.1` des Hosts (pro Host eindeutig, 5100–5999); in der Stufe k3s `–` |
| `{{STAGING_HOST}}`, `{{PRODUCTION_HOST}}` | Beschreibung des Hosts, z. B. „Factory-Server“ oder „eigene VM (Hetzner CX22)“ |
| `{{STAGING_DATA}}` | `seed` oder `anonymized-copy` |
| `{{STATE}}` | Liste der `state`-Einträge, z. B. „Postgres `db`, Volume `uploads`“ |
| `{{HEALTH_COMPONENTS}}` | Liste der Komponenten, z. B. „`db` (kritisch), `mail`“ |
| `{{WATCHDOG}}` | z. B. „healthchecks.io“, „healthchecks.io und GitHub-Actions-Probe alle 30 Minuten“ |
| `{{PIPELINES_VERSION}}` | Version von factory-pipelines im Aufruf-Workflow, derzeit `v0.3.0` |

Der Kommentar `<!-- nur wenn: … -->` bzw. `<!-- only if: … -->` gilt für die Zeile direkt darunter. Trifft die Bedingung nicht zu, entfernt `/init` die Zeile, sonst nur den Kommentar. Danach nummeriert `/init` die Akzeptanzkriterien lückenlos durch. Kursive Hinweise (`_…_`) in den Vorlagen sind Ausfüllhilfen und werden ersetzt.

## Plattform-Checks in `.factory/setup.json`

Die Checks laufen in der Factory (`factory-verify`) und in CI (Job „Checks“ in factory-pipelines) gleich. `/init` trägt nur Checks für Dateien ein, die es schon gibt; die übrigen bringt die Spec mit, die die Datei anlegt.

| Check | Befehl | Ab |
|---|---|---|
| `delivery-config` | `check-jsonschema --schemafile https://raw.githubusercontent.com/thorsten-reitz/factory-pipelines/v0.3.0/schema/delivery.schema.json .factory/delivery.json` | `/init` |
| `workflows` | `actionlint` | `/init` |
| `dockerfile` | `hadolint --failure-threshold error Dockerfile` | PROJ-2 |
| `compose-test` | `IMAGE=check docker compose -f deploy/compose.test.yml config -q` | PROJ-2 |
| `compose` | `IMAGE=check PROJECT_ENV=check PORT=5100 SECRETS_DIR=/tmp FACTORY_BIN=/tmp docker compose -f deploy/compose.yml config -q` | PROJ-4 (Stufen compose und kamal) |
| `k3s-values` | `yq -e '.' deploy/k3s/values.yaml >/dev/null` | PROJ-4 (Stufe k3s), nur wenn das Projekt `deploy/k3s/values.yaml` hat |

Die Schema-Version im Check `delivery-config` ist dieselbe wie im Aufruf-Workflow. Hebt Renovate die Version von factory-pipelines an, gehört die Zeile in denselben PR. Die Stufe kamal braucht keinen eigenen Check, sie nutzt `compose`. In der Stufe k3s hat das Projekt kein Chart, das sich prüfen ließe; das Chart prüft factory-pipelines selbst.

Das Job-Image der Factory enthält alle Werkzeuge dafür (`actionlint`, `check-jsonschema`, `hadolint`, `yq`, Docker-CLI mit Compose-Plugin ohne Daemon). In CI installiert factory-pipelines (seit v0.1.1) `actionlint`, `check-jsonschema` 0.33.0 und `hadolint` 2.12.0 selbst, sobald ein Check sie verwendet; Docker Compose und `yq` sind auf den Runnern vorhanden.

## Was der Mensch tut

Einmal pro Projekt bzw. Server, nichts davon per SSH:

- Infisical: Projekt (EU), Umgebungen `staging` und `production`, Identitäten (OIDC für GitHub, Universal Auth je Host), Secrets eintragen; Variablen `INFISICAL_PROJECT_ID` und `INFISICAL_IDENTITY_ID` im GitHub-Repo setzen.
  **OIDC-Subject:** Repos, die nach dem 15. Juli 2026 angelegt wurden, haben ein Subject mit IDs (`repo:<owner>@<id>/<repo>@<id>:environment:staging` statt `repo:<owner>/<repo>:environment:staging`). Das richtige Präfix zeigt `gh api repos/<owner>/<repo>/actions/oidc/customization/sub` (`sub_claim_prefix`).
- S3-Bucket und Zugangsschlüssel anlegen, Offline-Kopie des Backup-Schlüssels ablegen.
- Server per cloud-init (`factory-pipelines/templates/cloud-init/`) anlegen bzw. den Factory-Server mit `host/install.sh` vorbereiten, DNS-Einträge setzen.
- Stufe k3s: Server mit `templates/cloud-init/k3s-host.yaml` als User-Data anlegen, dafür einen Deploy-Key nur mit Lesezugriff auf das Repo (bei privaten Repos) und eine Infisical-Maschinen-Identität (Universal Auth) für den Cluster; beide nach dem Bootstrap erneuern, weil die User-Data beim Anbieter lesbar bleibt. Bei privatem Image `GHCR_PULL_TOKEN` je Umgebung in Infisical.
- healthchecks.io-Konto und Checks anlegen.
- GitHub-Umgebungen `staging` und `production` (macht `scripts/add-repo.sh`), production freigeben, PRs mergen.

Jede Plattform-Spec führt ihren Teil davon als Checkliste unter „Voraussetzungen (Mensch)“.
