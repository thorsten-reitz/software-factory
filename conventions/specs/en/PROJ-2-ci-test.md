# PROJ-2: CI and Test Environment

**Status:** Planned
**Type:** Platform
**Created:** {{DATE}}

## Dependencies
- PROJ-1 (Conventions check)

## Prerequisites (human)
- [ ] GitHub Actions is allowed in the repo, including reusable workflows from `thorsten-reitz/factory-pipelines` (Settings → Actions → General)
- [ ] GitHub Packages (GHCR) is not blocked for the repo or organization

## User Stories
- As the project owner I want every pull request to run checks, the image build and E2E tests against exactly the built image automatically so that I only merge tested changes.
- As the factory I want CI to run the same checks as `factory-verify` so that green locally and green in CI mean the same.

## Out of Scope
- The full health standard with `/health` and components (PROJ-3); only a minimal `/livez` and `/readyz` here, because the test environment checks them
- Deploying to staging or production (PROJ-4, PROJ-5)
- Pipeline logic of its own in the project: the logic lives in `factory-pipelines`

## Acceptance Criteria
- [ ] AC-1: Given a pull request is opened or updated, when GitHub starts the workflows, then `.github/workflows/delivery.yml` runs automatically with config validation, all checks from `.factory/setup.json`, the image build and the test environment, and the run on this spec's PR is green.
- [ ] AC-2: Given `.factory/delivery.json` contains an unknown key, when the check `delivery-config` runs, then it fails and the message names the key.
- [ ] AC-3: Given the repo, when `hadolint --failure-threshold error Dockerfile` runs, then it reports no error; the image runs as a non-root user and accepts the build arguments `GIT_COMMIT` and `APP_VERSION`.
- [ ] AC-4: Given the test environment from `deploy/compose.test.yml` runs with the built image, when `/livez` and `/readyz` are requested, then both answer with HTTP 200.
- [ ] AC-5: Given the app runs but a critical dependency (e.g. the database) is unreachable, when `/livez` and `/readyz` are requested, then `/livez` answers 200 and `/readyz` answers 503.
- [ ] AC-6: Given the test environment runs, when CI runs the `e2e` command from `.factory/setup.json` with `BASE_URL`, then at least one E2E test (the start page or entry point of the app loads) passes.
- [ ] AC-7: Given `factory-verify` runs, then `.factory/setup.json` contains the checks `delivery-config`, `workflows`, `dockerfile` and `compose-test` and all of them are green.
- [ ] AC-8: Given a push to `main`, when the workflow runs, then it builds the image and deploys nothing, because `.factory/delivery.json` has no `staging` or `production` environment yet. _(after merge)_
- [ ] AC-9: Given the repo, then neither the workflow nor `deploy/compose.test.yml` nor the `Dockerfile` contain secrets other than recognizable test values (e.g. `test-health-token`).

## Edge Cases
- EC-1: The project has no database → `deploy/compose.test.yml` only starts the app, `/readyz` only checks that the app can serve requests.
- EC-2: The stack is not Node → `e2e` uses the stack's test tool, the image is built following the stack pack.
- EC-3: A check is red → CI shows every check with its result in the summary, not just the first red one.

## Technical Requirements (optional)
- Caller workflow from `factory-pipelines/templates/delivery.yml` at version {{PIPELINES_VERSION}}: enable the triggers `pull_request` and `push` (branch `main`), change nothing else.
- `deploy/compose.test.yml` from `factory-pipelines/templates/compose.test.yml`, `.dockerignore` from `templates/dockerignore`. In the test environment the app is reachable at `environments.test.url` (default `http://localhost:8080`).
- Database migrations run in the test environment as the `migrate` service before the app (command `migrate`, see the stack pack).

## Open Questions
- [ ] _none_

## Product Decisions
- A minimal `/livez` and `/readyz` are built here already, because the pipeline's test environment checks them. PROJ-3 builds the full standard ({{DATE}}).
