# PROJ-3: Health Check

**Status:** Planned
**Type:** Platform
**Created:** {{DATE}}

## Dependencies
- PROJ-2 (CI and test environment)

## Prerequisites (human)
- [ ] List of health components in `docs/operations.md` (section "Health") confirmed: {{HEALTH_COMPONENTS}}

## User Stories
- As the pipeline I want to check after every deploy whether the app is ready and runs the right commit so that I can roll back automatically on failure.
- As the project owner I want to see the state of every main component in a protected place so that I quickly know what failed when an alert comes in.

## Out of Scope
- Heartbeats and alerts (PROJ-7)
- App metrics (`/metrics`, PROJ-7)

## Acceptance Criteria
- [ ] AC-1: Given the app runs, when `/livez` is requested, then it answers HTTP 200, even if a dependent component is down.
- [ ] AC-2: Given all critical components are reachable and the migration state matches the image, when `/readyz` is requested, then it answers HTTP 200; otherwise HTTP 503. In both cases the body contains no details about components or errors.
- [ ] AC-3: Given a request to `/health` without an `Authorization` header or with a wrong token, then the app answers HTTP 401 without details.
- [ ] AC-4: Given a request to `/health` with `Authorization: Bearer <HEALTH_TOKEN>`, then the app answers JSON with `status`, `version`, `commit` and `checks`; `checks` has exactly one entry per component from `health.components` in `.factory/delivery.json`, each with `status`, `critical` and `latencyMs` or `error`.
- [ ] AC-5: Given a critical component is down, when `/health` is requested, then `status` is `down` and the response is HTTP 503; if only a non-critical one is down, `status` is `degraded` and the response is HTTP 200.
- [ ] AC-6: Given a component does not respond, when `/health` or `/readyz` is requested, then it counts as `down` with `error: "timeout"` after at most 3 seconds, and the endpoint answers within at most 5 seconds.
- [ ] AC-7: Given the image was built with `GIT_COMMIT` and `APP_VERSION`, then `/health` returns exactly these values in `commit` and `version`.
- [ ] AC-8: Given the E2E tests in CI, then they cover all three endpoints, including 401 without a token and a failed service (caused in the test environment).
- [ ] AC-9: Given a health request, then neither the token nor component credentials appear in the response or the log.

## Edge Cases
- EC-1: A component from `health.components` does not exist in the code yet → add the check anyway, or remove the component from `health.components` with a reason in `docs/operations.md` (listed in the PR).
- EC-2: `HEALTH_TOKEN` is not set → `/health` always answers 401, the app still starts.
- EC-3: Many concurrent requests to `/health` → checks do not run several times in parallel against the same component (a short cache of a few seconds is allowed).

## Technical Requirements (optional)
- Format and rules: Software Factory conventions, section health check.
- Compose healthcheck in `deploy/compose.test.yml` and later `deploy/compose.yml` on `/livez`.

## Open Questions
- [ ] _none_

## Product Decisions
- `/readyz` and `/livez` stay public without details, `/health` only with a token ({{DATE}}).
