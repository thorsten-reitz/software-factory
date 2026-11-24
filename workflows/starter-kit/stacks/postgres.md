# Stack-Pack: Postgres (selbst betrieben)

Gilt, wenn `docs/stack.md` unter „Stack-Packs" `postgres` nennt. Postgres läuft als Container neben der App (Stufe compose bzw. kamal) oder als StatefulSet (Stufe k3s), gesichert nach den Betriebskonventionen (`state` in `.factory/delivery.json`).

## Migrationen
- Schema-Änderungen **nur als Migrations-Datei** mit dem Migrationswerkzeug aus `docs/stack.md` (z. B. Drizzle Kit, node-pg-migrate, Prisma Migrate, Alembic, Laravel- oder Rails-Migrationen). Die Dateien liegen im Repo und werden nach dem Merge nie mehr geändert; Korrekturen sind eine neue Migration.
- **Nie SQL von Hand gegen eine echte Datenbank ausführen.** Die Factory hat keinen Zugriff auf staging- oder Produktionsdaten und braucht ihn nicht.
- Migrationen laufen über **einen** Befehl, den das Image enthält (Standard `npm run migrate`, bei anderen Stacks entsprechend). Die Pipeline startet ihn im Dienst `migrate`: in der Test-Umgebung (`deploy/compose.test.yml`) vor der App, beim Deploy (`deploy/compose.yml`, Profil `migrate`) vor dem Umschalten. Vor jeder Produktions-Migration entsteht ein Backup.
- Der Befehl ist idempotent: bereits angewendete Migrationen werden übersprungen.

## Expand/Contract
Jede Migration muss mit der **vorherigen** App-Version funktionieren, damit ein App-Rollback ohne DB-Rollback geht. Deshalb in zwei Schritten:

1. **Expand** (dieser PR): nur hinzufügen. Neue Tabellen, neue Spalten nullable oder mit Default, neue Indizes. Die App schreibt bei Umbenennungen in alt **und** neu und liest weiter tolerant.
2. **Contract** (ein späterer PR, nachdem die neue Version in production läuft): Altes entfernen. Spalten löschen, `NOT NULL` setzen, alte Tabellen droppen.

Regeln:
- `DROP`, Umbenennen, Typänderung, `NOT NULL` ohne Default nur im Contract-Schritt. Im PR-Text unter „Annahmen“ bzw. „Assessment“ ausdrücklich nennen.
- Umbenennen = neue Spalte anlegen, doppelt schreiben, Daten übernehmen (Backfill in Batches), Lesen umstellen, alte Spalte später entfernen.
- Indizes auf großen Tabellen mit `CREATE INDEX CONCURRENTLY` (eigene Migration ohne Transaktion, wenn das Werkzeug es verlangt).
- Lange Datenmigrationen in Batches, nie eine Tabelle minutenlang sperren.

## Zugriff aus der App
- Verbindung über `DATABASE_URL` aus der Umgebung (auf dem Host von Infisical, in der Test-Umgebung aus `deploy/compose.test.yml`). Nie Zugangsdaten im Code. Neue Secret-Namen gehören in `docs/operations.md`.
- Connection-Pool mit Obergrenze, Abfragen mit Zeitlimit.
- Zugriffsregeln in der App: Jede Abfrage auf Nutzerdaten filtert nach dem angemeldeten Nutzer bzw. Mandanten. Row Level Security zusätzlich, wenn `docs/stack.md` es vorsieht.
- Indizes auf Spalten, nach denen gefiltert oder sortiert wird. Fremdschlüssel mit bewusstem `ON DELETE`. Listen-Abfragen immer mit Limit.

## Health
- `db` ist eine kritische Komponente: `/readyz` und `/health` prüfen die Verbindung (`SELECT 1` mit Zeitlimit) und ob die neueste Migration im Image angewendet ist.

## Seeds und staging-Daten
- Synthetische Beispieldaten über einen idempotenten Befehl im Image (z. B. `npm run seed`), **nie personenbezogene Daten**. Auf staging startet ihn der Dienst `seed` in `deploy/compose.yml` (Profil `seed`) bei jedem Deploy nach den Migrationen; lokal kann derselbe Befehl als `seed` in `.factory/setup.json` stehen.
- Bei `environments.staging.data: "anonymized-copy"`: `deploy/anonymize.sql` überschreibt jede Spalte mit personenbezogenen Daten. Jede Migration, die eine solche Spalte hinzufügt, ergänzt im selben PR `deploy/anonymize.sql`.

## Tests in der Factory
- Im Job-Container gibt es keinen Docker-Daemon und keine Datenbank. Unit- und Integrationstests laufen gegen eine eingebettete Datenbank (Node: PGlite) oder mit gemocktem Datenzugriff.
- Die echte Postgres-Instanz gibt es in CI: Die Test-Umgebung aus `deploy/compose.test.yml` startet Postgres, führt die Migrationen aus und die E2E-Tests laufen gegen das gebaute Image. Damit sind die Migrationen bei jedem PR einmal gegen echtes Postgres gelaufen.

## Login
- Login über eine Bibliothek im App-Stack, Sitzungen und Konten in Postgres (Node/Next.js: z. B. Better Auth oder Auth.js; Python: z. B. FastAPI-Users; Laravel: Breeze/Fortify; Rails: eingebauter Authentication-Generator). Welche, steht in `docs/stack.md`.
- Passwörter nur gehasht durch die Bibliothek, Secrets der Bibliothek (z. B. `AUTH_SECRET`) aus der Umgebung, Name in `docs/operations.md`.

## Backup
- Der Eintrag `{ "type": "postgres", "service": "db" }` in `.factory/delivery.json` → `state` reicht: Backup, Restore-Test und Restore kommen aus factory-pipelines. Eine zweite Datenbank bekommt einen eigenen Eintrag.
