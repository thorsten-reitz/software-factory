# PROJ-5: Production with Approval

**Status:** Planned
**Type:** Platform
**Created:** {{DATE}}

## Dependencies
- PROJ-4 (Deploy to staging)

## Prerequisites (human)
- [ ] GitHub environment `production` with you as required reviewer, deployments from branch `main` only (created by the factory's `scripts/add-repo.sh`)
- [ ] Machine identity for GitHub with OIDC auth, subject `repo:{{OWNER}}/{{REPO}}:environment:production` (with IDs for repos created after 15 July 2026, see PROJ-4), read access to `production` only
<!-- only if: production on its own VM, tier compose or kamal -->
- [ ] Production host ({{PRODUCTION_HOST}}) created via cloud-init from `factory-pipelines/templates/cloud-init/compose-host.yaml`
<!-- only if: production on the factory server -->
- [ ] Factory server set up as a deploy host and capacity checked as documented in `docs/operations.md`
<!-- only if: tier compose or kamal -->
- [ ] Host identity (Universal Auth) with read access to `production` only, client secret renewed after the first boot
<!-- only if: tier k3s -->
- [ ] k3s server for production ({{PRODUCTION_HOST}}) created with `factory-pipelines/templates/cloud-init/k3s-host.yaml` ({{PIPELINES_VERSION}}) as user-data, with a read-only deploy key (private repos) and a machine identity (Universal Auth) with read access to `production` only; both rotated after bootstrap
<!-- only if: tier compose or kamal -->
- [ ] Secrets in Infisical `production`: `DEPLOY_HOST`, `DEPLOY_SSH_KEY`, `DEPLOY_HOST_KEY`, `HEALTH_TOKEN` and every app secret from `docs/operations.md`
<!-- only if: tier k3s -->
- [ ] Secrets in Infisical `production`: `HEALTH_TOKEN`, for a private image `GHCR_PULL_TOKEN` (token with `read:packages`), and every app secret from `docs/operations.md`
<!-- only if: backup on -->
- [ ] Backup secrets in Infisical `production` (`RESTIC_REPOSITORY`, `RESTIC_PASSWORD`, `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`), because a backup runs before every production deploy
- [ ] DNS: `{{PRODUCTION_DOMAIN}}` points to the production host

## User Stories
- As the project owner I want to decide myself when a version tested in staging goes to production so that nothing goes live by accident.
- As the project owner I want production to get exactly the image that ran in staging so that I can rely on the staging test.

## Out of Scope
- Backup schedule and restore test (PROJ-6)
- Monitoring and watchdog (PROJ-7)

## Acceptance Criteria
<!-- only if: tier compose or kamal -->
- [ ] AC-1: Given the repo, then `.factory/delivery.json` has under `environments.production` `port: {{PRODUCTION_PORT}}`, `domain: "{{PRODUCTION_DOMAIN}}"` and `approval: true`, and the check `delivery-config` is green.
<!-- only if: tier k3s -->
- [ ] AC-1: Given the repo, then `.factory/delivery.json` has under `environments.production` `domain: "{{PRODUCTION_DOMAIN}}"` (no `port`) and `approval: true`, and the check `delivery-config` is green.
- [ ] AC-2: Given the caller workflow `.github/workflows/delivery.yml`, then it only contains the call to `factory-pipelines` at version {{PIPELINES_VERSION}}, no jobs of its own and no `secrets:`.
- [ ] AC-3: Given the staging deploy after a merge is green, then the job "Deploy production" waits for approval on the `production` environment and does not deploy without it. _(after merge)_
- [ ] AC-4: Given approval is granted, then exactly the digest that ran in staging is deployed, and the pipeline's comment names environment, digest and health result. _(after merge)_
- [ ] AC-5: Given the production deploy has finished, when `https://{{PRODUCTION_DOMAIN}}/readyz` is requested, then the app answers 200. _(after merge)_
- [ ] AC-6: Given the staging deploy fails, then the job "Deploy production" does not start. _(after merge, once it happens; covered by the factory-pipelines self-test)_
- [ ] AC-7: Given `docs/operations.md`, then the "Runbooks" section describes approval, automatic and manual rollback (Actions → delivery → `rollback`) for production.

## Edge Cases
- EC-1: Approval is rejected → no deploy, production stays on the previous version.
- EC-2: Another PR is merged between the staging deploy and the approval → approval is per run, each run deploys its own digest.
- EC-3: The health gate in production fails → automatic rollback, issue `deploy-failed`.

## Technical Requirements (optional)
- Tier: {{TIER}}. Host: {{PRODUCTION_HOST}}.
- The factory never sees production secrets: production secrets are only available via OIDC to the `production` environment, which is restricted to `main`.

## Open Questions
- [ ] _none_

## Product Decisions
- Production only after approval by the human, always with the digest from staging ({{DATE}}).
