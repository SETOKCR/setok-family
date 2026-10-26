# ST-PB-001 — Evidence

All evidence was produced by `scripts/st-pb-001/Invoke-StPb001.ps1 -Step All`. The contract is described in `infra/bindings/README.md`, and the desired registry is `infra/bindings/registry.desired.json`.

## Files

| File | Content |
|---|---|
| `20261025T234718-validate.json` | Schema and invariant verdicts for the registry, the registry and schema sha256, and 14 negative and replacement cases |
| `20261025T234738-reconcile.json` | Two read-only reconciliation runs: semantic results, observed Authentik and Cloudflare facts, before and after fingerprints, and the static read-only scan |

## Registry contents

- 1 tenant (`first-family`), 2 adult human subjects (`adult-01`, `adult-02`), 0 device subjects.
- 2 integrations:
  - Authentik, `ownership: dedicated`
  - Cloudflare Zero Trust, `ownership: shared`, with `not_owned` = account, ZT organization, Default device profile and any profile not bound as managed_resource
- 1 resource: `device_profile`, managed_by_setok_family.
- 4 bindings, all `ACTIVE`:
  - 2 × `identity_user` (Authentik uuid/pk 6 and 7)
  - 1 × `integration_account` (Cloudflare account and team domain)
  - 1 × `managed_resource` (`SETOK-FAMILY-MANAGED` policy id)
- 0 `device_enrollment` bindings.

## Gates

| Gate | Result |
|---|---|
| Schema validation (Test-Json, draft 2020-12) | PASS |
| Tenant scope: every record references an existing tenant, with no cross-tenant targets or integrations | PASS (0 violations) |
| Unique internal IDs, independent of provider IDs (substring overlap check) | PASS |
| Explicit subject, resource and binding type matrix | PASS |
| Exactly 2 active human identity bindings; 0 device subjects; 0 device bindings | PASS |
| Cardinality and duplicate-active-binding checks | PASS |
| Negative cases expected FAIL (missing tenant_id, duplicate active, one external for two subjects, device subject, profile as device binding, cross-tenant, provider-derived id, shared CF claimed dedicated, email present, domain role attribute, replacement without retire, STALE not counted active, RETIRED without retired_on) | 13 of 13 FAIL as expected |
| Replacement case (old RETIRED, new binding `replaces`, same `subject_id`) expected PASS | PASS |
| Authentik reconciliation (both bindings: resolves exactly once, pk match, active, `internal`, not superuser, 0 groups/roles) | PASS |
| Cloudflare reconciliation (account visible, team domain match, modeled shared, `SETOK-FAMILY-MANAGED` exactly once, policy id match, not Default, Default not bound) | PASS |
| Repeat reconciliation gives an identical semantic result (run 1 equals run 2) | PASS |
| Read-only proof | PASS (see below) |
| PII/secret scan of registry, schema, script and evidence | PASS (no names, emails, passwords, tokens or recovery URLs) |
| No Phase 2 runtime or database code | PASS (JSON contract plus PowerShell validator only) |

The read-only proof combines three checks:
- **Static scan of the script:** 0 HTTP write verbs and 0 ORM write calls.
- **Authentik fingerprint:** a hash of every user (pk, uuid, active, type, attributes, groups, roles, password hash) plus object counts for groups, roles, tokens, apps, providers, sources, flows and outposts. It was identical before and after each run, and across both runs.
- **Cloudflare fingerprint:** a hash of all device profiles and the organization. It was identical before and after each run, and across both runs.

Cloudflare was accessed with HTTP GET only, using the existing ST-CF-001 token, and the token's scope was not broadened. Authentik was read through local `ak shell` queries only; no API token was created.

## Remediation / rollback for registry mistakes

Provider state is never changed by this Story, so every remediation is a Git change to `registry.desired.json`, followed by `Invoke-StPb001.ps1 -Step All`.

- **Wrong external id:** retire the binding (`RETIRED` with `retired_on`), then add a corrected binding with `replaces`. Do not edit history in place once a binding has been used downstream.
- **Provider object disappeared, or reconciliation reports ERROR:** set the binding to `STALE` or `ERROR`, open a remediation Story, and re-bind through replacement when the cause is fixed.
- **A mistake before anything depends on the registry:** revert the commit on `feature/st-pb-001`.
- **Never** reuse or regenerate a tenant or subject internal ID to "fix" a binding. Internal IDs are permanent.
