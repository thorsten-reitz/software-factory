# PROJ-6: Backup und Restore-Test

**Status:** Planned
**Typ:** Plattform
**Erstellt:** {{DATE}}

## Abhängigkeiten
- PROJ-4 (Deploy nach staging)

## Voraussetzungen (Mensch)
- [ ] S3-Bucket bei einem Anbieter deiner Wahl und Zugangsschlüssel mit Lese- und Schreibrecht nur auf diesen Bucket (optional: Object Lock bzw. Versionierung)
- [ ] Secrets in Infisical je Umgebung (`staging`, `production`): `RESTIC_REPOSITORY` (`s3:https://<endpoint>/<bucket>/{{PROJECT}}/<umgebung>`), `RESTIC_PASSWORD`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
- [ ] Offline-Kopie von `RESTIC_PASSWORD` abgelegt (Passwortmanager oder ausgedruckt) und der Ort, nicht der Schlüssel, in `docs/operations.md` eingetragen
<!-- nur wenn: watchdog healthchecks -->
- [ ] healthchecks.io-Checks für Backup und Restore-Test je Umgebung angelegt, Ping-URLs als `HC_PING_URL_BACKUP` und `HC_PING_URL_RESTORE_TEST` in Infisical
<!-- nur wenn: watchdog healthchecks, tier k3s -->
- [ ] healthchecks.io-Check für Restores auf Abruf je Umgebung, Ping-URL als `HC_PING_URL_RESTORE` in Infisical (der Restore-Job im Cluster meldet dorthin, ob der Restore gelungen ist)

## User Stories
- Als Projektverantwortliche:r möchte ich, dass alle Daten des Projekts täglich verschlüsselt außerhalb des Hosts gesichert werden, damit ein Ausfall oder Fehler nicht zu Datenverlust führt.
- Als Projektverantwortliche:r möchte ich, dass jede Woche automatisch geprüft wird, ob sich das Backup zurückspielen lässt, damit ich mich im Ernstfall darauf verlassen kann.
- Als Projektverantwortliche:r möchte ich eine Umgebung mit einem Workflow-Aufruf wiederherstellen können, ohne mich per SSH anzumelden.

## Außerhalb des Umfangs
- Point-in-Time-Recovery (WAL-G), solange factory-pipelines es nicht anbietet
- Backup des Factory-Servers selbst

## Akzeptanzkriterien
- [ ] AK-1: Angenommen das Repo, dann enthält `.factory/delivery.json` unter `state` jeden Zustand des Projekts ({{STATE}}), `backup.enabled: true`, `backup.schedule: "daily"`, `backup.retention` 7/4/12 (oder eine in `docs/operations.md` begründete Abweichung) und `backup.restoreTest: "weekly"`, und der Check `delivery-config` ist grün.
<!-- nur wenn: tier compose oder kamal -->
- [ ] AK-2: Angenommen `deploy/compose.yml`, dann steht jedes benannte Volume mit Zustand in `state`, und jedes Volume ohne Zustand (z. B. Cache) ist in `docs/operations.md` begründet ausgenommen.
- [ ] AK-3: Angenommen `docs/operations.md`, dann enthält der Abschnitt „Runbooks“ Restore auf Abruf (Actions → delivery → `restore`), Wiederanlauf auf einem neuen Host (cloud-init → Deploy → Restore) und die Empfehlung einer Übung pro Quartal, und der Abschnitt „Zustand, Backup und Restore“ nennt den Ort der Offline-Kopie.
- [ ] AK-4: Angenommen der Merge ist durch und der nächste nächtliche Backup-Lauf auf dem staging-Host ist vorbei, dann gibt es im restic-Repository von staging einen Snapshot je Eintrag in `state`. _(nach dem Merge)_
- [ ] AK-5: Angenommen der wöchentliche Restore-Test ist gelaufen, dann meldet er Erfolg an den Watchdog, und ein fehlgeschlagener oder ausbleibender Test erzeugt ein Issue mit Label `incident`. _(nach dem Merge)_
- [ ] AK-6: Angenommen ein Restore für staging mit Snapshot `latest` wird über Actions → delivery → `restore` gestartet, dann sind die Daten des letzten Backups wiederhergestellt und `/readyz` antwortet danach mit 200. _(nach dem Merge)_
- [ ] AK-7: Angenommen ein Restore für production wird gestartet, dann läuft er erst nach der Freigabe an der Umgebung `production`. _(nach dem Merge)_

## Edge Cases
- EC-1: PITR wird gebraucht (`state[].pitr: true`), factory-pipelines unterstützt es aber noch nicht → Rückfrage, nicht stillschweigend weglassen.
- EC-2: Das Projekt nutzt Supabase statt eigenem Postgres → kein `postgres`-Eintrag in `state`, Backup über Supabase, Abweichung in `docs/operations.md`.
- EC-3: Das Projekt hat gar keinen Zustand → `backup.enabled: false`, Begründung in `docs/operations.md`, AK-4 bis AK-7 entfallen.
- EC-4: Der S3-Anbieter ist nicht erreichbar → Backup schlägt fehl, Heartbeat bleibt aus, Issue `incident`; die App läuft weiter.

## Technische Anforderungen (optional)
- Backup, Restore-Test und Restore kommen vollständig aus factory-pipelines {{PIPELINES_VERSION}} (Backup-Image, systemd-Timer auf dem Host, Workflow `restore`). Im Projekt nur Konfiguration.
- Der Restore-Test läuft auf dem Host, nicht in GitHub Actions, damit Produktionsdaten nicht in GitHubs Infrastruktur geladen werden.

## Offene Fragen
- [ ] _keine_

## Product Decisions
- Ein restic-Repository pro Projekt und Umgebung, Schlüssel in Infisical und offline ({{DATE}}).
