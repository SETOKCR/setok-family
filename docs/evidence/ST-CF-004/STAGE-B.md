# ST-CF-004 Stage B — Enrollment authorization transition

**Terminal state:** `DEDICATED_ENROLLMENT_AUTHORIZATION_ACTIVE / SHARED_ENROLLMENT_PATH_REMOVED / HANDSET_UNCHANGED / STAGE_C_NOT_AUTHORIZED`

| File | Content |
|---|---|
| `20261031T104827-stage-a-preflight.json` | Stage A predicates re-run immediately before the mutation: PASS |
| `20261031T104900-stage-b-plan.json` | Readiness checks, PRE fingerprints, PRE authorization (booleans and hashes only) |
| `20261031T104917-stage-b-apply.json` | The single mutation: one PUT on enrollment policy `c991f7f4-7745-4f7f-afc6-3b868cdfca7e` |
| `20261031T104930-stage-b-verify.json` | 25 post-mutation assertions (the 21 required plus 4 extra): all PASS |

**Mutation:** the policy's only include changed from `email: <family-enrollment-01>` to `email: <android-01-enrollment>`. Name, decision (allow), require (0), exclude (0) and every other settable field were sent back unchanged; the hash of the other fields is identical before and after.

The WARP app `51a1308a-c003-465d-8bf6-b34ee6abf659` was not written. Its `allowed_idps` is still One-time PIN only, and its other fields are unchanged. A second Apply run returned `NONE`.

**Expected fingerprint changes:**
- `accessPolicies` and `enrollmentApp`: the app detail embeds the attached policy.
- `accessApps`: the list also embeds policies. It still contains exactly 1 application (the WARP app), so no unrelated app exists or changed.

**All 12 other surfaces are unchanged:**
- Gateway rules, lists and configuration;
- device settings;
- the Default profile, `SETOK-FAMILY-MANAGED` and all device profiles;
- the Access organization;
- identity providers;
- Access groups;
- service tokens;
- posture rules.

**android-01:** physical device and registration `01a17f4d-0062-19de-b716-1df58125a3d4` are unchanged: active, MASQUE, `SETOK-FAMILY-MANAGED`. No device or registration was created. The registry file hash is unchanged, so binding `bnd_01M5ZND7V8TK28E2V23Z4MRFEJ` is still authoritative.

**Credential:** a user-owned token (Access: Apps and Policies · Edit), verified at `/user/tokens/verify`, expiring 2026-11-25. Its value is stored only in a DPAPI file. Revoke it after review, or keep it until Stage E, which also needs it.

**Rollback (not executed; available before any new enrollment):** `Invoke-StCf004StageB.ps1 -Step Rollback` PUTs back the exact PRE policy. That PRE policy is stored DPAPI-protected at `%LOCALAPPDATA%\SETOK\setok-family\st-cf-004-stage-b-pre-policy.xml` and never in Git, because it contains the shared identity. The step then verifies that the shared identity is permitted again and the dedicated one is not.

**Registry note:** binding `bnd_01M5XYFZEPN4P2843AKX7MJANT` still records `enrollment_identity_alias: family-enrollment-01`. Stage B does not authorize registry changes, so updating that alias belongs to Stage D or F.

**Privacy:** the dedicated identity, the shared identity and both token values occur 0 times in `docs/evidence/ST-CF-004/` and `scripts/st-cf-004/`.
