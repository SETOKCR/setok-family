# WORK ORDER ST-CF-004

## Identity

- **Project:** SETOK Family
- **Repository:** SETOKCR/setok-family
- **Story / Work Unit:** ST-CF-004
- **Purpose:** establish dedicated per-device Cloudflare enrollment identity and fail-closed enrollment lifecycle for `android-01`
- **Execution state:** READY / STAGE A READ-ONLY PREFLIGHT
- **Implementation Authorization:** NO
- **Provider Mutation Authorization:** NO
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

Closing this Product Input Gate authorizes **Stage A read-only preflight only**. It does not authorize implementation or provider mutation.

## Target accepted state before mutation

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

## Future authorized mutation boundary

When separately authorized, implementation may mutate only what is strictly required for:

1. temporary exact-identity WARP enrollment authorization for `android-01-enrollment`;
2. controlled re-enrollment of the same intended Redmi handset;
3. SETOK provider-binding replacement;
4. closure/disablement of the dedicated enrollment authorization after successful enrollment.

No Gateway rule/list create/update/delete/reorder is in scope.

## Required execution stages

### Stage A — Read-only preflight

- `PROJECT_SCOPE_OK`;
- exact repository/branch/Authorized Base lineage;
- clean working tree;
- reconcile ST-DEV-001/ST-CF-003 accepted state;
- resolve actual dedicated identity locally without versioning it;
- prove the identity has 0 existing Cloudflare physical devices/registrations;
- prove it is not account-owner/admin identity;
- capture before-fingerprints of all shared surfaces.

Failure = STOP, no mutation.

### Stage B — Enrollment authorization transition

Only after explicit implementation authorization:

- change the existing WARP enrollment authorization so the dedicated identity can enroll;
- ensure the previous shared/admin enrollment identity is not left as an alternative path unless separately required and explicitly authorized;
- verify the effective authorization matches desired state before touching the handset.

Unexpected policy/app/IdP changes = STOP.

### Stage C — Controlled handset re-enrollment

- re-enroll the same intended Redmi handset using the dedicated identity;
- OTP is handled interactively and never versioned;
- prove provider observation identifies the intended handset;
- prove registration identity = dedicated identity;
- prove exactly one active registration/device scope for that identity.

Do not retire old SETOK binding yet.

### Stage D — Replacement binding

- create a replacement ACTIVE `device_enrollment` binding for `android-01` pointing only to the proven new provider registration/device identifiers;
- reconcile twice deterministically;
- verify exactly one authoritative ACTIVE replacement binding is intended for final state.

Only after PASS may the old binding be retired.

### Stage E — Close enrollment fail-closed

- remove/disable the dedicated identity's ability to create another WARP registration;
- prove provider authorization no longer permits a second enrollment with that identity;
- retain a governed reopen procedure for future re-enrollment.

If closure cannot be proven, STOP / APPLY_BLOCKED.

### Stage F — Final reconciliation / blast radius

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
- Product Input Gate not closed;
- identity is shared, plus-address based, owner/admin, or already used by another device;
- unexpected Cloudflare drift;
- old binding must be destroyed before replacement proof;
- Gateway mutation becomes necessary;
- MDM/managed deployment becomes necessary;
- enrollment authorization cannot be closed after success;
- unrelated shared surface changes;
- PII/secret would need to be committed.

## Evidence

Store sanitized evidence under:

`docs/evidence/ST-CF-004/`

Never version actual mailbox, OTP, public IP, serial, keys, tokens or unnecessary PII.

## Expected terminal state

`DEDICATED_IDENTITY_ENROLLED / DEVICE_REBOUND / ENROLLMENT_CLOSED / SAFE_SELECTOR_RETEST_REQUIRED`

This does NOT authorize Gateway apply. A later canary/safe-selector unit must re-prove selector behavior before ST-POL-001/002 can move from `APPLY_BLOCKED`.
