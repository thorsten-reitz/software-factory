# PROJ-7: Observability and Watchdog

**Status:** Planned
**Type:** Platform
**Created:** {{DATE}}

## Dependencies
- PROJ-4 (Deploy to staging)

## Prerequisites (human)
<!-- only if: observability on -->
- [ ] Observability stack set up on the factory server (`ops/observability/` in the factory repo, via `setup.sh`), Grafana reachable at its domain
<!-- only if: observability on -->
- [ ] Credentials for log and metrics ingestion per environment in Infisical, names as in the observability stack's guide
<!-- only if: watchdog healthchecks -->
- [ ] healthchecks.io account, one heartbeat check per environment (period 5 minutes), ping URL as `HC_PING_URL` in Infisical
<!-- only if: watchdog healthchecks -->
- [ ] Read-only healthchecks.io API key in the factory's runner configuration, so that alerts arrive as `incident` issues
<!-- only if: external HTTP check -->
- [ ] UptimeRobot monitor for `https://{{PRODUCTION_DOMAIN}}/readyz`, alerts by email

## User Stories
- As the project owner I want to see logs and resources of every environment in one place so that I find errors without logging in to a server.
- As the project owner I want an issue opened automatically on an outage and closed on recovery so that I do not have to discover outages myself.
- As the project owner I want to be notified even when the factory server itself goes down.

## Out of Scope
- Building the observability stack on the factory server (part of the factory)
- Automatic handling of incidents by the factory (only when the human adds the `factory` label)

## Acceptance Criteria
- [ ] AC-1: Given the repo, then `observability` and `watchdog` in `.factory/delivery.json` match the decisions in `docs/operations.md` (section "Observability and watchdog"), and the check `delivery-config` is green.
- [ ] AC-2: Given the app runs, then it writes logs as one JSON line per entry to stdout/stderr with at least time, level and message, and neither secrets nor tokens appear in logs.
<!-- only if: metrics on -->
- [ ] AC-3: Given a request to `/metrics`, then the app returns metrics in Prometheus format (at least requests, errors and response time per route), but only with `Authorization: Bearer <HEALTH_TOKEN>` or from the internal network.
- [ ] AC-4: Given `docs/operations.md`, then it lists every watchdog check with its name, what it reports and what a missing report means, and the "Runbooks" section describes what to do on an incident.
<!-- only if: observability on -->
- [ ] AC-5: Given staging runs, then the app's logs appear in Grafana with labels for project `{{PROJECT}}`, environment and service, and the project dashboard shows health, error rate, resources and recent deploys. _(after merge)_
<!-- only if: watchdog healthchecks -->
- [ ] AC-6: Given staging runs, then the host sends a heartbeat every 5 minutes, but only while `/readyz` is green. _(after merge)_
<!-- only if: watchdog healthchecks -->
- [ ] AC-7: Given the app in staging is not ready for longer than the check's grace period, then the runner opens exactly one issue labelled `incident`, and comments on and closes it after recovery. _(after merge)_
<!-- only if: github probe on -->
- [ ] AC-8: Given the GitHub Actions probe is enabled, then it requests `/readyz` at the configured interval and opens or closes the `incident` issue itself. _(after merge)_

## Edge Cases
- EC-1: The factory server goes down → healthchecks.io notifies by email, because the runner can no longer open an issue.
- EC-2: An alert persists → no second issue, only comments on the existing one.
- EC-3: Observability is off for staging → only production sends logs, deviation in `docs/operations.md`.

## Technical Requirements (optional)
- Grafana Alloy on the host comes from factory-pipelines or the cloud-init template; the project only holds configuration.
- Watchdog provider: {{WATCHDOG}}.

## Open Questions
- [ ] _none_

## Product Decisions
- Alerts become issues labelled `incident`, never factory tasks automatically ({{DATE}}).
