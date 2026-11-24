# PROJ-5: Production mit Freigabe

**Status:** Planned
**Typ:** Plattform
**Erstellt:** {{DATE}}

## Abhängigkeiten
- PROJ-4 (Deploy nach staging)

## Voraussetzungen (Mensch)
- [ ] GitHub-Umgebung `production` mit dir als Required Reviewer, Deployments nur vom Branch `main` (legt `scripts/add-repo.sh` der Factory an)
- [ ] Maschinen-Identität für GitHub mit OIDC Auth, Subject `repo:{{OWNER}}/{{REPO}}:environment:production`, Lesezugriff nur auf `production`
<!-- nur wenn: production auf eigener VM -->
- [ ] production-Host ({{PRODUCTION_HOST}}) per cloud-init aus `factory-pipelines/templates/cloud-init/compose-host.yaml` angelegt
<!-- nur wenn: production auf dem Factory-Server -->
- [ ] Factory-Server als Deploy-Host eingerichtet und Kapazität laut `docs/operations.md` geprüft
- [ ] Host-Identität (Universal Auth) mit Lesezugriff nur auf `production`, Client-Secret nach dem ersten Start erneuert
- [ ] Secrets in Infisical `production`: `DEPLOY_HOST`, `DEPLOY_SSH_KEY`, `DEPLOY_HOST_KEY`, `HEALTH_TOKEN` und alle App-Secrets aus `docs/operations.md`
<!-- nur wenn: backup an -->
- [ ] Backup-Secrets in Infisical `production` (`RESTIC_REPOSITORY`, `RESTIC_PASSWORD`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`), weil vor jedem Produktions-Deploy ein Backup läuft
- [ ] DNS: `{{PRODUCTION_DOMAIN}}` zeigt auf den production-Host

## User Stories
- Als Projektverantwortliche:r möchte ich selbst entscheiden, wann eine in staging geprüfte Version nach production geht, damit nichts ungewollt live geht.
- Als Projektverantwortliche:r möchte ich, dass production genau das Image bekommt, das in staging lief, damit ich mich auf den staging-Test verlassen kann.

## Außerhalb des Umfangs
- Backup-Zeitplan und Restore-Test (PROJ-6)
- Monitoring und Watchdog (PROJ-7)

## Akzeptanzkriterien
- [ ] AK-1: Angenommen das Repo, dann enthält `.factory/delivery.json` unter `environments.production` `port: {{PRODUCTION_PORT}}`, `domain: "{{PRODUCTION_DOMAIN}}"` und `approval: true`, und der Check `delivery-config` ist grün.
- [ ] AK-2: Angenommen der Aufruf-Workflow `.github/workflows/delivery.yml`, dann enthält er nur den Aufruf von `factory-pipelines` in Version {{PIPELINES_VERSION}}, keine eigenen Jobs und keine `secrets:`.
- [ ] AK-3: Angenommen der staging-Deploy nach einem Merge ist grün, dann wartet der Job „Deploy production“ auf die Freigabe an der Umgebung `production` und deployt ohne Freigabe nicht. _(nach dem Merge)_
- [ ] AK-4: Angenommen die Freigabe ist erteilt, dann wird genau der Digest ausgerollt, der in staging lief, und der Kommentar der Pipeline nennt Umgebung, Digest und Health-Ergebnis. _(nach dem Merge)_
- [ ] AK-5: Angenommen der Deploy nach production ist durchgelaufen, wenn `https://{{PRODUCTION_DOMAIN}}/readyz` abgefragt wird, dann antwortet die App mit 200. _(nach dem Merge)_
- [ ] AK-6: Angenommen der staging-Deploy schlägt fehl, dann startet der Job „Deploy production“ nicht. _(nach dem Merge, sobald es vorkommt; im Selbsttest von factory-pipelines belegt)_
- [ ] AK-7: Angenommen `docs/operations.md`, dann beschreibt der Abschnitt „Runbooks“ Freigabe, automatischen und manuellen Rollback (Actions → delivery → `rollback`) für production.

## Edge Cases
- EC-1: Die Freigabe wird abgelehnt → kein Deploy, production bleibt auf der bisherigen Version.
- EC-2: Zwischen staging-Deploy und Freigabe wird ein weiterer PR gemergt → freigegeben wird pro Lauf, jeder Lauf rollt seinen eigenen Digest aus.
- EC-3: Das Health-Gate in production schlägt fehl → automatischer Rollback, Issue `deploy-failed`.

## Technische Anforderungen (optional)
- Stufe: {{TIER}}. Host: {{PRODUCTION_HOST}}.
- Die Factory sieht nie Produktions-Secrets: production-Secrets gibt es nur per OIDC an die Umgebung `production`, die auf `main` beschränkt ist.

## Offene Fragen
- [ ] _keine_

## Product Decisions
- production nur nach Freigabe durch den Menschen, immer mit dem Digest aus staging ({{DATE}}).
