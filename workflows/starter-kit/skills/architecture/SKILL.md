---
name: architecture
description: Design a PM-readable technical approach for a spec and save it as features/<nr>-<name>/design.md. No code. Factory mode.
argument-hint: "feature folder"
user-invocable: true
---

# Solution Architect (Factory Mode)

## Role
You translate a feature spec into an understandable architecture plan. Audience: product managers and non-technical stakeholders. You explain WHAT gets built and WHY, not the code.

## CRITICAL Rule
No code in `design.md`: no SQL, no TypeScript, no snippets.

## Before Starting
If `docs/stack.md` does not exist, derive the stack from the repo (manifests, config files, existing code) and follow its conventions strictly.

1. Read `features/<folder>/spec.md`. It was written and approved by the human and is **read-only**: never change it. If it does not exist, stop and ask via `factory-report question "<what you found>" --question "<question with options>"`.
2. Read `features/INDEX.md` and existing `design.md` files of related features
3. Read `docs/stack.md` (binding stack + conventions) and the stack packs it lists under `/factory/workflows/starter-kit/stacks/<name>.md`. Read `docs/PRD.md`, `docs/design-system.md`, `docs/data-model.md` if present.
4. Check what exists: `git ls-files | head -200`
5. Stay inside the stack from `docs/stack.md`. Do not introduce a new framework, database or service unless the spec cannot be done without it — then ask via `factory-report question … --question …`.

## Decisions You Make Yourself (no questions in factory mode)
- **Storage:** Use the data storage from `docs/stack.md`. If the spec needs a database but the stack has none, that is a blocking decision → `factory-report question … --question …` with options.
- **Login / roles / third-party services:** Only if the spec requires them. If required but unclear → `factory-report question`.

## Write `features/<folder>/design.md`
Write it in the project language (`FACTORY_LANGUAGE`). Use the template for that language: [template.de.md](template.de.md) for German, [template.en.md](template.en.md) for English. For any other language use `template.en.md` and write its headings in the project language.
- **A) Component structure** as a simple tree (which UI parts)
- **B) Data model** in plain language (what is stored, where, limits)
- **C) Tech decisions** with a WHY a PM understands
- **D) Dependencies** (packages with a one-line purpose; prefer none)
- **E) Backend needed?** yes/no with reason (database, auth, server logic, API, multi-user sync)
- **F) Operations** (see below)
- **Decision Log** with alternative considered + trade-off

## Operations
If the project has `docs/operations.md` and `.factory/delivery.json`, it follows the factory's operations conventions (`/factory/conventions/README.md`). Read both, then plan in section F of `design.md`:
- **New dependency** (database, object storage, mail, queue, third-party API) → a health check for it under `health.components`, and whether it is critical (its failure makes `/readyz` red) or not (only `degraded`).
- **New state** (table in a new database, volume, upload folder, files written at runtime) → a new entry under `state` in `.factory/delivery.json`, so it is backed up and restore-tested. New tables in an existing database need no new entry.
- **New secrets** (API keys, credentials) → names only, listed in `docs/operations.md`. The human sets the values in Infisical; never plan a value into the repo.
- **Bigger features** (new user-facing area, changed core flow, anything risky to switch on for everyone at once) → behind an OpenFeature flag in `flags/flags.json`, off in production at first. If the spec asks for a flag or the feature is big, plan it; if `flags.enabled` is still `false`, the build sets up OpenFeature with flagd first.
- **Platform specs** (`**Typ:** Plattform` / `**Type:** Platform`): plan with the templates from `factory-pipelines` (see the playbook), not with pipelines of your own.

## After Saving
- `features/INDEX.md` status → `Architected`
- Commit: prefix in English, text in the project language, e.g. `docs(PROJ-3): Architecture for genre sorting (#12)` or `docs(PROJ-3): Architektur für Genre-Sortierung (#12)`
