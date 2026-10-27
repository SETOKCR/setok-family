# ST-DEV-001 — Evidence (CONTROLLED STOP at Stage A)

**Outcome: CONTROLLED STOP before any mutation.** No Cloudflare, registry or handset change was made. Stage B (internal device subject) was intentionally **not** started, because the Work Order allows it only after Stage A PASSES.

## Stage A — read-only discovery

Repository identity, the manifest, Authorized Base lineage (`8c27580…` → `aca790a` → `cdbd138`, governance only) and Work Order authorization (YES) were verified: `PROJECT_SCOPE_OK`.

`20261026T224608-snapshot-pre.json` is the sanitized inventory and fingerprints, produced by `scripts/st-dev-001/Invoke-StDev001.ps1 -Step Snapshot -Label pre` with HTTP GET only.

| Surface | Observed (pre-enrollment) |
|---|---|
| Physical devices / registrations / legacy devices | **0 / 0 / 0**: the account has no enrolled devices |
| Device profiles | 2: Default `019cbbfb…17d9` and `SETOK-FAMILY-MANAGED` `994b430f…33ca` |
| `SETOK-FAMILY-MANAGED` | match `os.name in {"android" "ios"}`, precedence 100, enabled, Traffic + DNS (`warp`), MASQUE, switch locked, not allowed to leave. This matches ST-CF-001. |
| Gateway rules | 2 pre-existing, unrelated (1 http, 1 l4); 0 Gateway lists |
| Identity providers (login methods) | 1: One-time PIN |
| **Access applications** | **0**: no `warp` (device-enrollment) application exists |
| **Access policies** | **0** |
| Service tokens | 0 |
| Device posture rules | 2 (pre-existing) |
| Registry | 0 device subjects, 0 Cloudflare `device_enrollment` bindings |

The snapshot also stores SHA-256 fingerprints of every shared surface: Gateway rules, lists and configuration; device settings; the Default and managed profiles; the Access organization; identity providers; Access apps and policies; service tokens; and posture rules. These are kept for a future post-enrollment comparison (`-Step Compare`). The evidence contains no emails, names, IP addresses or tokens.

## Stage A decision — FAIL (hard stop)

Cloudflare's manual-deployment documentation lists **"Set device enrollment permissions to specify which users can connect"** as a prerequisite for manual enrollment. Device enrollment permissions are Access policies attached to an Access application of type `warp`.

The account has **no `warp` application and no Access policies**, so the dedicated `android-enrollment-01` identity cannot be authorized to enroll unless the shared account's enrollment configuration is changed first. That change is outside this Work Order:
- "proposed manual enrollment requires shared enrollment permission … mutation" is a Stop Condition;
- the Independent Check, condition 5, says to stop before that mutation.

The existing login method (One-time PIN) is enough, so no login-method change would be needed. No service token, profile, selector or Gateway change is needed either.

Confidence note: the ST-CF-001 token read `/access/apps` and `/access/policies` successfully, returning `success: true` with 0 results rather than an authorization error. That indicates the configuration really is empty and not merely hidden from the token.

## Remediation proposal (requires separate TD authorization)

The proposal is a narrowly scoped, reversible shared-account change, made through a new Work Order amendment or Story:

1. **Create** the device enrollment permissions: one Access application of type `warp`, with exactly one Access policy.
   - Action: `allow`
   - Include: `email == <android-enrollment-01 address>`, an exact email and never a domain or "everyone"
   - Login method: the existing One-time PIN identity provider only
   - No other include/require rules, no service-token rule, no change to login methods
2. **Blast radius:** the `warp` application governs enrollment for the whole shared organization. Today 0 devices exist and nothing else enrolls, so a one-email allow rule admits only that identity and changes nothing for other SETOK surfaces. A future SETOK project that needs enrollment must extend this policy through its own governed change.
3. **Credentials:** the change needs a token with Access apps/policies **edit**. The ST-CF-001 token is Zero Trust Edit plus Access org/IdP read, and should not be assumed to have it. The proposal is a short-lived, separate token, revoked after the change.
4. **Operational input from the PO:** the dedicated enrollment mailbox, which must be able to receive OTPs. It stays outside Git and is stored as DPAPI under `%LOCALAPPDATA%\SETOK\setok-family\`.
5. **Rollback:** delete that one Access policy and the `warp` application by id. That restores today's state (0 apps, 0 policies), and the fingerprints in `snapshot-pre` allow exact comparison.
6. **Then resume ST-DEV-001 from Stage A.** Take a new pre snapshot, then follow Stage B → C (manual Cloudflare One Agent enrollment on the Redmi Note 14 Pro) → D → E, as written.

## Rollback / offboarding (for when enrollment later happens)

Offboarding has four layers:
1. retire the SETOK `device_enrollment` binding (`RETIRED`, `retired_on`);
2. revoke and delete the Cloudflare registration or device;
3. disconnect or uninstall the Cloudflare One Agent on the handset, or reset its local state;
4. remove `android-enrollment-01` from the enrollment policy, or delete that policy, when permanent prevention is intended.

**Cloudflare deletion alone is not permanent offboarding:** a client that can still authenticate creates a new registration. No step applies now, because nothing was created.

## Status

Safe selector: `NOT_YET_PROVEN`. No policy APPLIED. No Android MDM, no Child login, no Authentik user, no `unique_client_id`.
