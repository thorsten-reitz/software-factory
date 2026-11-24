# PROJ-6: Backup and Restore Test

**Status:** Planned
**Type:** Platform
**Created:** {{DATE}}

## Dependencies
- PROJ-4 (Deploy to staging)

## Prerequisites (human)
- [ ] S3 bucket at a provider of your choice and access keys with read/write access to this bucket only (optional: object lock or versioning)
- [ ] Secrets in Infisical per environment (`staging`, `production`): `RESTIC_REPOSITORY` (`s3:https://<endpoint>/<bucket>/{{PROJECT}}/<environment>`), `RESTIC_PASSWORD`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`
- [ ] Offline copy of `RESTIC_PASSWORD` stored (password manager or printed) and its location, not the key, entered in `docs/operations.md`
<!-- only if: watchdog healthchecks -->
- [ ] healthchecks.io checks for backup and restore test per environment, ping URLs as `HC_PING_URL_BACKUP` and `HC_PING_URL_RESTORE_TEST` in Infisical
<!-- only if: watchdog healthchecks, tier k3s -->
- [ ] healthchecks.io check for on-demand restores per environment, ping URL as `HC_PING_URL_RESTORE` in Infisical (the restore job in the cluster reports there whether the restore succeeded)

## User Stories
- As the project owner I want all project data backed up daily, encrypted and off the host so that an outage or mistake does not lose data.
- As the project owner I want an automatic weekly check that the backup can be restored so that I can rely on it in an emergency.
- As the project owner I want to restore an environment with one workflow run, without logging in via SSH.

## Out of Scope
- Point-in-time recovery (WAL-G) as long as factory-pipelines does not offer it
- Backing up the factory server itself

## Acceptance Criteria
- [ ] AC-1: Given the repo, then `.factory/delivery.json` lists every state of the project under `state` ({{STATE}}), `backup.enabled: true`, `backup.schedule: "daily"`, `backup.retention` 7/4/12 (or a deviation with a reason in `docs/operations.md`) and `backup.restoreTest: "weekly"`, and the check `delivery-config` is green.
<!-- only if: tier compose or kamal -->
- [ ] AC-2: Given `deploy/compose.yml`, then every named volume holding state is listed in `state`, and every volume without state (e.g. a cache) is excluded with a reason in `docs/operations.md`.
- [ ] AC-3: Given `docs/operations.md`, then the "Runbooks" section covers restore on demand (Actions → delivery → `restore`), recovery on a new host (cloud-init → deploy → restore) and the recommendation of a quarterly drill, and the section "State, backup and restore" names the location of the offline copy.
- [ ] AC-4: Given the merge is done and the next nightly backup on the staging host has run, then the staging restic repository has one snapshot per entry in `state`. _(after merge)_
- [ ] AC-5: Given the weekly restore test has run, then it reports success to the watchdog, and a failed or missing test creates an issue labelled `incident`. _(after merge)_
- [ ] AC-6: Given a restore for staging with snapshot `latest` is started via Actions → delivery → `restore`, then the data of the last backup is restored and `/readyz` answers 200 afterwards. _(after merge)_
- [ ] AC-7: Given a restore for production is started, then it only runs after approval on the `production` environment. _(after merge)_

## Edge Cases
- EC-1: PITR is needed (`state[].pitr: true`) but factory-pipelines does not support it yet → ask, do not drop it silently.
- EC-2: The project uses Supabase instead of its own Postgres → no `postgres` entry in `state`, backup via Supabase, deviation in `docs/operations.md`.
- EC-3: The project has no state at all → `backup.enabled: false`, reason in `docs/operations.md`, AC-4 to AC-7 do not apply.
- EC-4: The S3 provider is unreachable → the backup fails, the heartbeat is missing, issue `incident`; the app keeps running.

## Technical Requirements (optional)
- Backup, restore test and restore come entirely from factory-pipelines {{PIPELINES_VERSION}} (backup image, systemd timers on the host, `restore` workflow). The project only holds configuration.
- The restore test runs on the host, not in GitHub Actions, so that production data is never loaded into GitHub's infrastructure.

## Open Questions
- [ ] _none_

## Product Decisions
- One restic repository per project and environment, key in Infisical and offline ({{DATE}}).
