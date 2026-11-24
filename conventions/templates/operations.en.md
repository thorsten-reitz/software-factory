# Operations: {{PROJECT}}

> Created by `/init` on {{DATE}}. Basis: the Software Factory operations conventions (`conventions/README.md` in the factory repo).
> Where nothing is stated, the convention applies. Every deviation is in `.factory/delivery.json` and listed under "Deviations" below with a reason.
> **Never put secret values here**, only their names.

## 1. Environments and placement

| Environment | Host | Domain | Port (127.0.0.1) | Trigger | Data |
|---|---|---|---|---|---|
| test | GitHub runner (CI only) | – | – | every PR | test values from `deploy/compose.test.yml` |
| staging | {{STAGING_HOST}} | {{STAGING_DOMAIN}} | {{STAGING_PORT}} | push to `main` | {{STAGING_DATA}} |
| production | {{PRODUCTION_HOST}} | {{PRODUCTION_DOMAIN}} | {{PRODUCTION_PORT}} | approval on the GitHub environment `production` | real data |

Server provisioning: {{PROVISIONING}} (template `factory-pipelines/templates/cloud-init/`).

`staging` and `production` are added to `.factory/delivery.json` by PROJ-4 and PROJ-5, once host and secrets are ready. Until then this table is the plan.

<!-- only if: production on the factory server -->
**Note:** production runs on the factory server. It shares resources with the agent runs, and an outage of the server hits the factory, monitoring and production at the same time.

## 2. Orchestration tier

- **Tier:** {{TIER}}
- **Reason:** _criteria from the guide: number of services and hosts, downtime during deploys, experience, cost_
- **Target tier later:** _only if different, e.g. "kamal, once factory-pipelines v0.2 is available"_

**Capacity of the factory server** (only if an environment runs there):

| Item | RAM |
|---|---|
| Server total | _16 GB_ |
| Agent runs (maxParallel × 3 GB) | _− 6 GB_ |
| Observability | − 1.5 GB |
| System, runner, Caddy | − 1 GB |
| Previews (0.5 GB per open preview) | _− …_ |
| Other environments on the server | _− …_ |
| **Free** | _…_ |
| This environment(s), sum of memory limits | _…_ |

## 3. State, backup and restore

**State** (`state` in `.factory/delivery.json`):

| Type | Name | Content | PITR |
|---|---|---|---|
| _postgres_ | _db_ | _application data_ | _no_ |
| _volume_ | _uploads_ | _uploaded files_ | – |

- **Backup:** restic to S3, daily and before every production deploy, retention 7 daily / 4 weekly / 12 monthly.
- **Restore test:** weekly on the host, result sent as a heartbeat to the watchdog.
- **Restic repository:** `s3:<endpoint>/<bucket>/{{PROJECT}}/<environment>`
- **Offline copy of `RESTIC_PASSWORD`:** _location, e.g. "password manager of …, entry {{PROJECT}} restic" (never the key itself)_
- **Staging data:** {{STAGING_DATA}}
<!-- only if: staging data seed -->
- **Seed:** service `seed` in `deploy/compose.yml` (profile `seed`, idempotent), runs on every staging deploy after the migrations. Never personal data.
<!-- only if: staging data anonymized-copy -->
- **Anonymization:** `deploy/anonymize.sql`, updated with every schema change. Not implemented yet in factory-pipelines v0.1.1. GDPR: _why an anonymized copy is needed and permitted_

## 4. Health

Endpoints: `/livez`, `/readyz`, `/health` (only with `Authorization: Bearer $HEALTH_TOKEN`).

| Component | Critical | What is checked |
|---|---|---|
| _db_ | _yes_ | _connection and migration state_ |

## 5. Observability and watchdog

- **Logs and host metrics:** _on / off_ (Grafana on the factory server)
- **App metrics (`/metrics`):** _on / off_
- **Watchdog:** _healthchecks.io_ with these checks:

| Check | Reports | Missing means |
|---|---|---|
| `{{PROJECT}}-staging` | heartbeat every 5 minutes while `/readyz` is green | staging not ready or host down |
| `{{PROJECT}}-production` | heartbeat every 5 minutes while `/readyz` is green | production not ready or host down |
| `{{PROJECT}}-backup` | after every backup | backup did not run |
| `{{PROJECT}}-restore-test` | after every restore test | restore test did not run or failed |

- **GitHub Actions probe:** _off / every N minutes_
- **External HTTP check:** _none / UptimeRobot_

Alerts appear as issues labelled `incident`, deploy failures as issues labelled `deploy-failed`. The factory only works on them if you add the `factory` label.

## 6. Secrets

Infisical Cloud EU, project `{{PROJECT}}`, environments `staging` and `production`. The GitHub repo only holds the variables `INFISICAL_PROJECT_ID` and `INFISICAL_IDENTITY_ID`.

| Name | staging | production | Purpose |
|---|---|---|---|
| `DEPLOY_HOST`, `DEPLOY_SSH_KEY`, `DEPLOY_HOST_KEY` | ✓ | ✓ | deploy via forced command |
| `HEALTH_TOKEN` | ✓ | ✓ | access to `/health` |
| `RESTIC_REPOSITORY`, `RESTIC_PASSWORD`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` | ✓ | ✓ | backup |
| `HC_PING_URL`, `HC_PING_URL_BACKUP`, `HC_PING_URL_RESTORE_TEST` | ✓ | ✓ | watchdog |
| _`DATABASE_URL`, `POSTGRES_PASSWORD`_ | ✓ | ✓ | _app_ |

**Dependency on Infisical:** running containers keep working when Infisical is unreachable. Deploys and restarting a host need Infisical.

## 7. Feature flags

- **OpenFeature + flagd:** _on / not set up yet (the first feature that needs a flag sets it up)_
- **File:** `flags/flags.json`, per-environment differences via targeting on `environment`.

## 8. Additional requirements

_Availability target, retention obligations, data location, customer requirements. Each with the decision on how the convention meets it. "None" if there are none._

## 9. Deviations from the convention

| What | Instead of the convention | Reason | Date |
|---|---|---|---|
| _–_ | | | |

## 10. Runbooks

- **Deploy:** automatic to staging on every push to `main`; production after approval on the `production` environment (Actions → delivery → run → "Review deployments").
- **Rollback:** automatic when the health gate fails. Manual: Actions → delivery → Run workflow → `rollback`, choose the environment.
- **Restore:** Actions → delivery → Run workflow → `restore`, environment, snapshot `latest` or a date. Production only with approval.
- **Recovery on a new host:** create the host via cloud-init, update `DEPLOY_HOST`/`DEPLOY_HOST_KEY` in Infisical, deploy, restore. Recommended as a drill once per quarter.
- **Incident:** read the issue labelled `incident`, open the Grafana dashboard `{{PROJECT}}`, add the `factory` label if the factory should work on it.

## 11. One-time steps (human)

- [ ] Infisical project `{{PROJECT}}` (EU) with environments `staging` and `production`
- [ ] OIDC identity for GitHub (subject prefix: `gh api repos/{{OWNER}}/{{REPO}}/actions/oidc/customization/sub`), variables `INFISICAL_PROJECT_ID` and `INFISICAL_IDENTITY_ID` in the repo
- [ ] Hosts ready (cloud-init, or `host/install.sh` on the factory server), host identities
- [ ] DNS for {{STAGING_DOMAIN}} and {{PRODUCTION_DOMAIN}}
- [ ] S3 bucket, access keys, offline copy of `RESTIC_PASSWORD`
- [ ] healthchecks.io checks and `HC_PING_URL*` in Infisical
- [ ] GitHub environments `staging` and `production` (production: approval by you, `main` only)
