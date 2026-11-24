# PROJ-4: Deploy to Staging

**Status:** Planned
**Type:** Platform
**Created:** {{DATE}}

## Dependencies
- PROJ-3 (Health check)

## Prerequisites (human)
- [ ] Infisical project `{{PROJECT}}` (Cloud EU) with the environments `staging` and `production`
- [ ] Machine identity for GitHub with OIDC auth, subject `repo:{{OWNER}}/{{REPO}}:environment:staging` (repos created after 15 July 2026 use a subject with IDs: `repo:<owner>@<id>/<repo>@<id>:environment:staging`, prefix via `gh api repos/{{OWNER}}/{{REPO}}/actions/oidc/customization/sub`), read access to `staging` only
- [ ] Variables `INFISICAL_PROJECT_ID` and `INFISICAL_IDENTITY_ID` set in the GitHub repo (variables, not secrets)
- [ ] GitHub environment `staging` exists (created by the factory's `scripts/add-repo.sh`)
<!-- only if: staging on the factory server -->
- [ ] Factory server set up as a deploy host (`host/install.sh` from factory-pipelines {{PIPELINES_VERSION}} with `--sites-dir /etc/software-factory/sites.d`)
<!-- only if: staging on its own VM -->
- [ ] Staging host ({{STAGING_HOST}}) created via cloud-init from `factory-pipelines/templates/cloud-init/compose-host.yaml`
- [ ] Host identity (Universal Auth) with read access to `staging`, client secret renewed after the first boot
- [ ] Secrets in Infisical `staging`: `DEPLOY_HOST`, `DEPLOY_SSH_KEY`, `DEPLOY_HOST_KEY`, `HEALTH_TOKEN` and every app secret from `docs/operations.md` (section "Secrets")
- [ ] DNS: `{{STAGING_DOMAIN}}` points to the staging host

## User Stories
- As the project owner I want every merge to `main` to be deployed to staging and checked automatically so that I see every change in a real environment before it goes to production.
- As the project owner I want a broken deploy to be rolled back and reported automatically so that staging does not stay broken unnoticed.

## Out of Scope
- Production (PROJ-5)
- Backups (PROJ-6), heartbeats and logs (PROJ-7)
- Setting up the host itself (the human does that via cloud-init)

## Acceptance Criteria
- [ ] AC-1: Given the repo, then `.factory/delivery.json` has under `environments.staging` `port: {{STAGING_PORT}}`, `domain: "{{STAGING_DOMAIN}}"`, `autoDeploy: true` and `data: "{{STAGING_DATA}}"`, and the check `delivery-config` is green.
<!-- only if: tier compose or kamal -->
- [ ] AC-2: Given `deploy/compose.yml`, then it contains no secrets, every service has a memory limit, the app only listens on `127.0.0.1:${PORT}`, migrations run in the `migrate` service (profile `migrate`), and the check `compose` (`docker compose config`) is green. The kamal tier needs no further project file (no `config/deploy.yml`).
<!-- only if: tier k3s -->
- [ ] AC-2: Given the Helm chart in `deploy/helm/app`, then it contains no secrets, every container has resource limits and probes on `/livez` and `/readyz`, migrations run as a job before the rollout, and the check `helm` (`helm lint` and `kubeconform`) is green.
- [ ] AC-3: Given a PR is merged, when the `delivery` workflow runs on `main`, then the image is pushed to GHCR with its digest and deployed to staging automatically. _(after merge)_
- [ ] AC-4: Given the deploy has finished, when `https://{{STAGING_DOMAIN}}/readyz` is requested, then the app answers 200, and `/health` reports the deployed commit. _(after merge)_
- [ ] AC-5: Given a deploy to staging, then the pipeline comments environment, digest and health result on the PR or commit. _(after merge)_
- [ ] AC-6: Given the health gate fails after a deploy, then the pipeline rolls back to the previous digest and opens an issue labelled `deploy-failed`. _(after merge, once a deploy fails; the behaviour itself is covered by the factory-pipelines self-test)_
<!-- only if: staging data seed -->
- [ ] AC-7: Given `deploy/compose.yml`, then it has a service `seed` with `profiles: [seed]`, the same image as the app, entrypoint `/factory/with-secrets` and a dependency on the database; its command (e.g. `npm run seed`) fills an empty database with synthetic sample data without personal data and creates no duplicates when run twice (shown by a test).
<!-- only if: staging data anonymized-copy -->
- [ ] AC-7: Given `deploy/anonymize.sql`, then it overwrites every column with personal data (per the data model) with synthetic values, and `docs/operations.md` gives the reason for the anonymized copy. (factory-pipelines v0.2.0 does not load the copy yet.)
- [ ] AC-8: Given the repo, then it contains no secret value, and every secret name the app expects is listed in `docs/operations.md`.

## Edge Cases
- EC-1: Infisical is unreachable during the deploy → the deploy stops before switching over, the running version stays, issue `deploy-failed`.
- EC-2: The same digest is deployed twice → no change, no restart of the database.
- EC-3: A migration fails → no switch-over, the old version keeps running.
- EC-4: The `seed` service runs again on every staging deploy → existing sample data stays unchanged, no duplicates.

## Technical Requirements (optional)
- Templates from `factory-pipelines` at version {{PIPELINES_VERSION}} (`templates/compose.yml`), no deploy logic of its own in the project.
- Tier: {{TIER}}. Host: {{STAGING_HOST}}.

## Open Questions
- [ ] _none_

## Product Decisions
- Staging deploys automatically on every push to `main` ({{DATE}}).
