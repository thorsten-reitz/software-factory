# PROJ-1: Conventions Check

**Status:** Planned
**Type:** Platform
**Created:** {{DATE}}

## Dependencies
- None

## Prerequisites (human)
- [ ] `docs/operations.md` and `.factory/delivery.json` from `/init` reviewed and pushed to the default branch

## User Stories
- As the project owner I want the factory to compare the briefing, PRD, stack, skeleton and operations docs against the operations conventions so that gaps are found before the pipelines are built.
- As the project owner I want open operations decisions as a question in the issue so that none of them are assumed silently.

## Out of Scope
- Building pipelines, Dockerfile, health endpoints or deploy files (PROJ-2 to PROJ-7)
- Changing app code
- Creating secrets or entering values (the human does that in Infisical)

## Acceptance Criteria
- [ ] AC-1: Given the repo, stack or PRD contain state (database, volumes, upload folders, SQLite files, queues, caches holding data), when the check is complete, then every state found is listed under `state` in `.factory/delivery.json` or excluded with a reason in `docs/operations.md`.
- [ ] AC-2: Given the PRD, stack or code name external dependencies (database, object storage, mail, third-party APIs), when the check is complete, then each one is in `health.components` or marked in `docs/operations.md` as not checked, with a reason.
- [ ] AC-3: Given the briefing or PRD name operational requirements (availability, retention, data location, customer requirements), when the check is complete, then each one is mapped to a decision in `docs/operations.md` under "Additional requirements".
- [ ] AC-4: Given a requirement contradicts the chosen tier {{TIER}} (e.g. zero-downtime deploys with tier compose, several nodes), when the check finds it, then the factory asks for the decision with options in the issue instead of making it itself.
- [ ] AC-5: Given the check is complete, when `factory-verify` runs, then the check `delivery-config` (schema validation of `.factory/delivery.json`) is green.
- [ ] AC-6: Given the check is complete, then `docs/operations.md` has every section of the template filled in, no template placeholder or italic fill-in hint (`_…_`) left, and a location for the offline copy of the backup key (or the open question about it), but never the key.
- [ ] AC-7: Given the factory's PR, then it only changes `docs/operations.md`, `.factory/delivery.json` and `features/INDEX.md`, no app code, and the PR body lists every change to `.factory/delivery.json` with a reason.
- [ ] AC-8: Given the check finds no gap, then `docs/operations.md` still gets a section "Check by the factory" with the date, the result and the list of checked items (state, dependencies, requirements, tier, secrets).

## Edge Cases
- EC-1: A decision only the human can make (e.g. PITR yes/no, data location) → question in the issue, no assumption.
- EC-2: The repo contains a secret value (e.g. a committed `.env`) → report it in the PR as a finding without repeating the value, with the advice to rotate it in Infisical.
- EC-3: The repo only contains the skeleton → check against briefing, PRD and `docs/stack.md`, note in "Check by the factory" that there was no app code yet.
- EC-4: `docs/operations.md` and `.factory/delivery.json` contradict each other → align `.factory/delivery.json` with the documented decision; ask if it is genuinely unclear.

## Technical Requirements (optional)
- Basis is the guide `conventions/README.md` of the Software Factory (in the job at `/factory/conventions/README.md`).
- `.factory/delivery.json` stays valid against `factory-pipelines/schema/delivery.schema.json`.

## Open Questions
- [ ] _none_

## Product Decisions
- A first check by the factory in addition to the confirmation in `/init`: it finds gaps nobody saw during the interview ({{DATE}}).
