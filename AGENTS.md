# Project Agent Instructions — SETOK Family

> This file routes agents to project authority. It does not duplicate SETOK-AIDE.

## Start here

1. Read `.ai/AIDE_PROJECT.yaml` first.
2. Read the active Story / Work Order before changing code or infrastructure.
3. Verify Project Scope before any mutation: Work Order repository == manifest `project.repository` == live repository identity.
4. Load only the canonical project documents, ADRs, QUALITY rules and reusables relevant to the current work.
5. Use the applicable generic SETOK-AIDE Skill (`implement-work-order` or `investigate-defect`) when the task matches it.
6. Inspect the live repository and providers for current implementation facts; chat history and memory are context, not source of truth.

## Project Scope Handshake

Before editing files, creating commits, changing provider configuration, migrating data, deploying or performing another mutative action governed by AIDE, emit one outcome:

- `PROJECT_SCOPE_OK` — Work Order, manifest and live repository match;
- `PROJECT_SCOPE_MISMATCH` — verified identities conflict;
- `PROJECT_SCOPE_UNVERIFIED` — identity cannot yet be established safely.

`MISMATCH` and `UNVERIFIED` are hard Stop Conditions. Perform no mutation and return to the Technical Director.

## Project authority

- Product Owner → Technical Director → Development Agent.
- Canon is read from the live default branch of `SETOKCR/setok-family`.
- `docs/ARCHITECTURE.md` is the approved SETOK Family v1.4 architecture baseline.
- `docs/PRODUCT.md`, `docs/ROADMAP.md` and `docs/QUALITY.md` contain the minimum project-local canon needed for the current phase.
- SETOK-AIDE is a read-only framework source/reference unless this project is explicitly adopting a newer version.
- The resident Director State Capsule is cache/index only and never outranks Git/canon.

## Execution rules

- Respect `GOAL`, Acceptance Criteria, `OUT OF SCOPE` and `STOP CONDITIONS` from the active Work Order.
- Respect Work Order Project / Repository / Authorized Base binding.
- Backlog, ROADMAP, architecture approval, or a selected next item do not authorize implementation.
- Do not expand scope for cleanup, refactoring, upgrades or adjacent improvements unless necessary for authorized work.
- Do not change product or architecture canon without Technical Director governance and Product Owner involvement when materially required.
- Apply SETOK-AIDE architecture, security, risk and quality contracts to the surface actually touched.
- Check registered reusables before rediscovering operational procedures.
- If a material unexpected surface appears, stop the affected work and report it rather than silently expanding scope.

## Evidence

Return concise evidence: project-scope outcome, changed surface, tests/gates, material findings, Stop Conditions and Reuse Candidates when present.

For AIDE-governed execution, close with a compact `AIDE EXECUTION RESULT` including Project, Repository, Work Unit, Project Scope, Authorized Base, Implementation Commit, Scope, Required Gates, Stop Conditions and Unexpected Surface.

Do not declare `ACCEPT`, `IMPLEMENTATION_DONE` or `DELIVERY_DONE`; those remain Technical Director decisions.
