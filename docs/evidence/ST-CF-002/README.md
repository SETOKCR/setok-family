# ST-CF-002 — Evidence

**State:** `DEVICE_ENROLLMENT_PERMISSION_READY / NO_DEVICE_ENROLLED / SAFE_SELECTOR_NOT_YET_PROVEN`

All evidence was produced by `scripts/st-cf-002/Invoke-StCf002.ps1`. Snapshots and reconciliation use the existing ST-CF-001 token with HTTP GET only. The two creates used a separate ST-CF-002 token, through a helper that refuses any path other than the two Access collection endpoints.

## Files

| File | Content |
|---|---|
| `20261026T231611-snapshot-pre.json` | Stage A sanitized inventory and SHA-256 fingerprints of 16 surfaces |
| `20261026T234844-plan.json` | Readiness checks and the planned delta (inputs present, token active, no warp app, One-time PIN present) |
| `20261026T234906-apply.json` | Stage B: `CREATE policy`, `CREATE warp app`, and the observed result |
| `20261026T235011-reconcile.json` | Stage C: desired vs observed ×2, giving `MATCH` and `deterministic: true` |
| `20261026T235019-snapshot-post.json` | Post-change snapshot |
| `20261026T235020-compare-pre-post.json` | Stage D blast-radius comparison |
| `20261026T235041-apply.json` | Idempotent re-run: `NONE policy`, `NONE warp app` |
| `20261026T234955-registry-validate-st-pb-001.json` | ST-PB-001 registry validator after the registry extension: PASS, all 14 cases as expected |

## Stage A (pre-mutation)

The pre-state matched expectations:
- 0 Access applications, 0 warp applications, 0 Access policies, 0 Access groups;
- 1 IdP, One-time PIN;
- 0 service tokens;
- 0 physical devices and 0 registrations;
- the Default profile and `SETOK-FAMILY-MANAGED` unchanged (match `os.name in {"android" "ios"}`);
- 2 pre-existing Gateway rules, 0 lists, 2 posture rules.

Operational inputs were present locally as DPAPI files: the enrollment mailbox (a single exact address) and the ST-CF-002 token (active, distinct from ST-CF-001).

## Stage B (authorized mutation) — exactly two objects

| Object | Observed id | Facts |
|---|---|---|
| Access policy `SETOK-FAMILY-DEVICE-ENROLLMENT allow family-enrollment-01` | `c991f7f4-7745-4f7f-afc6-3b868cdfca7e` | decision `allow`; exactly 1 include of kind `email`, which matches the operational identity for `family-enrollment-01` (compared in memory; the value is not recorded); 0 require, 0 exclude |
| Access application (type `warp`) | `51a1308a-c003-465d-8bf6-b34ee6abf659` | `allowed_idps` = only the existing One-time PIN IdP; the only attached policy is the one above |

**Provider fact:** Cloudflare names every `warp` application `Warp Login App`, regardless of the requested name (`SETOK-FAMILY-DEVICE-ENROLLMENT`). Ownership therefore comes from the registry binding, which records the observed app id and its single attached managed policy, not from the name. The reconciliation checks `appNameProviderFixed` and `appIsRegistryBound`. The first apply record shows `appNameIsManaged: false` from the original name-based check, which was replaced by these two checks.

## Stage C (ownership / reconciliation)

- **Registry** (`infra/bindings/registry.desired.json`):
  - new resource `res_01M5XYFZDG31JSDHKYV16HXR8W`, `resource_type: enrollment_authorization`, alias `family-device-enrollment`;
  - new `managed_resource` binding `bnd_01M5XYFZEPN4P2843AKX7MJANT`, whose `external` holds only `access_app_id`, `access_app_type`, `access_policy_id` and the alias `family-enrollment-01`.
  - The internal IDs are random ULIDs. No mailbox is recorded.
- **Schema:** one backward-compatible change, adding `enrollment_authorization` to the `resource_type` enum. All ST-PB-001 records and gates still pass.
- **Reconciliation:** run twice, with 12 of 12 checks true in both runs. The result was identical across runs (`MATCH`, deterministic).

## Stage D (blast radius)

The comparison covers 16 surfaces, and all 16 are **unchanged**:
- Gateway rules, lists and configuration;
- device settings;
- the Default profile, `SETOK-FAMILY-MANAGED` (including its match) and all device profiles;
- the Access organization;
- identity providers;
- Access groups;
- service tokens;
- posture rules;
- physical devices and registrations;
- unrelated Access apps and unrelated Access policies.

Provider delta: **+1 Access application (warp), +1 Access policy (allow), 0 removed, 0 other changes**, so `deltaAsExpected: true`.

## Credential scope

The ST-CF-002 token is an account-owned token, verified through `/accounts/{id}/tokens/verify`: status active, expires 2026-11-03. It was requested with only Account · Access: Apps and Policies · Edit, scoped to the SETOK account. The ST-CF-001 token was not changed. The token value is stored only in `%LOCALAPPDATA%\SETOK\setok-family\cloudflare-st-cf-002.token.xml` (DPAPI).

**After acceptance, revoke the token in Cloudflare and run `scripts/st-cf-002/Set-StCf002Inputs.ps1 -RemoveToken`.** Rollback needs a newly issued token with the same scope.

## Privacy / secrets scan

ST-CF-002 files contain no email address, token or Authorization value. A literal search for the real mailbox across `docs/`, `infra/` and `scripts/` finds **0 matches in any ST-CF-002 file or in the registry**.

**Pre-existing finding, not introduced here:** the same mailbox string already appears in seven tracked ST-CF-001 files, `infra/cloudflare/st-cf-001.desired.json` and `docs/evidence/ST-CF-001/*`. It is part of Cloudflare's account *name*, "<owner>'s Account", which ST-CF-001 recorded. Remediating that is a Technical Director decision: either redact going forward, or rewrite history.

## Rollback (documented, not executed)

1. Delete the exact app: `DELETE /accounts/{acct}/access/apps/51a1308a-c003-465d-8bf6-b34ee6abf659`. Deleting the app first detaches the policy.
2. Delete the exact policy: `DELETE /accounts/{acct}/access/policies/c991f7f4-7745-4f7f-afc6-3b868cdfca7e`.
3. Run `-Step Snapshot -Label post`, then `-Step Compare`. Expect Access apps and policies back to 0/0, and every other surface unchanged against `snapshot-pre`.
4. Retire registry binding `bnd_01M5XYFZEPN4P2843AKX7MJANT` (set `RETIRED` with `retired_on`) and resource `res_01M5XYFZDG31JSDHKYV16HXR8W`.

Rollback must target only these ids; nothing broader is deleted or reset. Without this app and policy, no device can enroll. After a successful run they remain in place as SETOK Family enrollment infrastructure for ST-DEV-001 (Android) and later iPad Standard enrollment.

## Not done (by design)

The following were not touched: Android enrollment, device subjects and device bindings, MDM, Gateway, profiles, IdPs, service tokens, posture rules. The safe selector remains `NOT_YET_PROVEN`.
