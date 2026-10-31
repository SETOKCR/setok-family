# WORK ORDER ST-CF-004

## Identity

- **Project:** SETOK Family
- **Repository:** SETOKCR/setok-family
- **Story / Work Unit:** ST-CF-004
- **Purpose:** establish dedicated per-device Cloudflare enrollment identity and fail-closed enrollment lifecycle for `android-01`
- **Execution state:** AUTHORIZED / STAGE B ENROLLMENT AUTHORIZATION TRANSITION
- **Implementation Authorization:** YES — STAGE B ONLY
- **Provider Mutation Authorization:** YES — STAGE B ONLY
- **Risk:** RED
- **Authorized Base:** `5ed8d403a99540e45e872ed255c27abc6203577d`
- **Implementation Branch:** `feature/st-cf-004`

## Governance basis

- Story: `docs/stories/ST-CF-004.md`
- Independent Check: `docs/development/ST-CF-004_INDEPENDENT_CHECK.md`
- Independent Check decision: `PASS WITH CONDITIONS — GOVERNANCE/PREFLIGHT ONLY`
- ST-CF-003 terminal result: `SAFE_SELECTOR_NOT_PROVEN / APPLY_BLOCKED`
- ST-POL-001: `DESIRED / COMPILED / APPLY_BLOCKED`
- ST-POL-002: `DESIRED / COMPILED / APPLY_BLOCKED`
- ST-CF-004 Stage A candidate: `9db889c1dca45af21ab757423e5c03d11fc3689f`
- ST-CF-004 Stage A decision: `ACCEPTED — PASS`

## Product Input Gate

`CLOSED — PASS`

Operational input verified by Product Owner on 2026-10-30:

- one dedicated mail-enabled Microsoft 365 distribution identity exists exclusively for `android-01`;
- it successfully received a message from an external sender and delivered it to the authorized guardian destination;
- it is not implemented using plus-addressing;
- it is not intended for iPad or any other device.

Versioned alias only:

`android-01-enrollment`

The actual email and OTP values MUST remain outside Git and sanitized evidence.

## Stage A acceptance

Stage A read-only preflight is accepted on candidate:

`9db889c1dca45af21ab757423e5c03d11fc3689f`

Accepted findings:

- `PROJECT_SCOPE_OK`;
- current `android-01` accepted state = `MATCH`;
- dedicated identity existing devices = `0`;
- dedicated identity existing registrations = `0`;
- dedicated identity is not Cloudflare account owner/admin;
- dedicated identity differs from the shared enrollment identity;
- dedicated identity is not plus-address based;
- shared-surface drift = `NONE` across 15/15 observed surfaces;
- Gateway family enforcement present = `NO`;
- provider mutation during Stage A = `NO`.

## Stage B authorization boundary

The Product Owner `go` authorizes **Stage B only**.

Authorized provider mutation is limited to the existing WARP enrollment authorization required to:

1. permit exact identity alias `android-01-enrollment` to enroll using the existing One-time PIN identity provider;
2. remove the previous shared/admin enrollment identity as an alternative enrollment path;
3. verify the resulting effective enrollment authorization;
4. capture sanitized before/after evidence and blast-radius proof.

This authorization does **NOT** authorize:

- handset re-enrollment;
- OTP enrollment interaction;
- Cloudflare device creation/revocation/deletion;
- SETOK provider-binding creation/replacement/retirement;
- Gateway rule/list/config mutation;
- device-profile mutation;
- MDM;
- Stage C, D, E or F execution.

Stage B must STOP after verification, whether PASS or STOP.

## Target accepted state before Stage B mutation

SETOK subject:

`sub_01M5Y0XYAMFT3MXRRJV5MFBY3N` / `android-01`

Current binding:

`bnd_01M5ZND7V8TK28E2V23Z4MRFEJ`

Current Cloudflare physical device / registration:

`01a17f4d-0062-19de-b716-1df58125a3d4`

Expected:

- Android / Redmi Note 13 Pro+ 5G (`23090RA98G`);
- WARP;
- MASQUE;
- profile `SETOK-FAMILY-MANAGED`;
- active/not revoked;
- no Gateway family enforcement applied.

Any unexplained drift = STOP.

## Required execution stages

### Stage A — Read-only preflight

**Status: ACCEPTED — PASS**

- `PROJECT_SCOPE_OK`;
- exact repository/branch/Authorized Base lineage;
- clean working tree;
- reconcile ST-DEV-001/ST-CF-003 accepted state;
- resolve actual dedicated identity locally without versioning it;
- prove the identity has 0 existing Cloudflare physical devices/registrations;
- prove it is not account-owner/admin identity;
- capture before-fingerprints of all shared surfaces.

### Stage B — Enrollment authorization transition

**Status: AUTHORIZED — EXECUTION ALLOWED**

- re-run scope/lineage and clean-tree guard before mutation;
- re-validate Stage A safety predicates immediately before mutation;
- change only the existing WARP enrollment authorization so the dedicated identity can enroll;
- ensure the previous shared/admin enrollment identity is not left as an alternative path;
- preserve the existing WARP Access application and One-time PIN IdP;
- verify effective authorization after mutation;
- verify no unexpected policy/app/IdP changes;
- verify Gateway, profiles, device/registration state, and unrelated shared surfaces remain unchanged;
- write sanitized evidence;
- STOP after Stage B verification.

Unexpected policy/app/IdP changes = STOP. If safe rollback is required before any handset enrollment has occurred, restore the exact pre-Stage-B enrollment authorization and verify restoration.

### Stage C — Controlled handset re-enrollment

**Status: NOT AUTHORIZED**

- re-enroll the same intended Redmi handset using the dedicated identity;
- OTP is handled interactively and never versioned;
- prove provider observation identifies the intended handset;
- prove registration identity = dedicated identity;
- prove exactly one active registration/device scope for that identity.

Do not retire old SETOK binding yet.

### Stage D — Replacement binding

**Status: NOT AUTHORIZED**

- create a replacement ACTIVE `device_enrollment` binding for `android-01` pointing only to the proven new provider registration/device identifiers;
- reconcile twice deterministically;
- verify exactly one authoritative ACTIVE replacement binding is intended for final state.

Only after PASS may the old binding be retired.

### Stage E — Close enrollment fail-closed

**Status: NOT AUTHORIZED**

- remove/disable the dedicated identity's ability to create another WARP registration;
- prove provider authorization no longer permits a second enrollment with that identity;
- retain a governed reopen procedure for future re-enrollment.

If closure cannot be proven, STOP / APPLY_BLOCKED.

### Stage F — Final reconciliation / blast radius

**Status: NOT AUTHORIZED**

Prove:

- dedicated identity cardinality = 1 expected device scope / 1 active registration;
- replacement SETOK binding is ACTIVE and deterministic;
- old binding is retired only after replacement proof;
- Gateway rules/lists/config unchanged;
- managed/default profiles unchanged unless explicitly authorized otherwise;
- IdPs, service tokens, posture rules and unrelated Access resources unchanged;
- no unrelated device or registration changed;
- no PII/secrets in versioned evidence.

## Rollback boundaries

### Before new registration

Restore original enrollment authorization and keep the existing provider registration/binding authoritative.

### New registration exists, replacement binding not proven

Keep old binding authoritative. Restore provider authorization to known-good state. Do not retire old binding.

### Replacement binding proven, old binding not yet retired

Prefer completing enrollment closure. If new provider state cannot be maintained safely, restore SETOK authority to old binding and explicitly offboard the unaccepted new registration under separate controlled steps.

### Old binding retired

No silent rollback. Any provider/device offboarding or re-enrollment requires explicit governed action. Enrollment must not be left open.

## Stop conditions

- repository/project/lineage mismatch;
- identity is shared, plus-address based, owner/admin, or already used by another device;
- unexpected Cloudflare drift;
- current `android-01` accepted state no longer matches;
- Stage B would require mutation outside the existing WARP enrollment authorization;
- previous shared/admin identity cannot be removed from the effective enrollment path;
- WARP app or One-time PIN IdP would need replacement or unrelated modification;
- Gateway mutation becomes necessary;
- MDM/managed deployment becomes necessary;
- unrelated shared surface changes;
- PII/secret would need to be committed;
- any Stage C+ action becomes necessary.

## Evidence

Store sanitized evidence under:

`docs/evidence/ST-CF-004/`

Never version actual mailbox, OTP, public IP, serial, keys, tokens or unnecessary PII.

## Expected Stage B terminal state

`DEDICATED_ENROLLMENT_AUTHORIZATION_ACTIVE / SHARED_ENROLLMENT_PATH_REMOVED / HANDSET_UNCHANGED / STAGE_C_NOT_AUTHORIZED`

The overall ST-CF-004 expected terminal state remains:

`DEDICATED_IDENTITY_ENROLLED / DEVICE_REBOUND / ENROLLMENT_CLOSED / SAFE_SELECTOR_RETEST_REQUIRED`

This does NOT authorize Gateway apply. A later canary/safe-selector unit must re-prove selector behavior before ST-POL-001/002 can move from `APPLY_BLOCKED`.
