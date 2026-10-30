# ST-CF-004 — Establish dedicated per-device Cloudflare enrollment identity and fail-closed lifecycle

## Status

PREFLIGHT

## Purpose

Replace the shared operational enrollment identity currently associated with `android-01` with a dedicated per-device enrollment identity so Cloudflare Gateway `User Email` scope can later be evaluated as a fail-closed selector without introducing Android MDM.

This Story does **not** apply Gateway policy.

## Architecture basis

ST-CF-003 proved:

- direct Cloudflare physical-device / registration IDs are not supported Gateway selectors for the required Android DNS/Network/HTTP policy scope;
- exact `User Email` is supported as an identity selector;
- the current enrollment identity is shared/administrative and can create additional registrations, therefore it cannot be accepted as a fail-closed selector;
- Android serial/device-IP alternatives are unavailable and `unique_client_id` requires managed deployment/MDM;
- ST-POL-001 and ST-POL-002 remain `APPLY_BLOCKED`.

The preferred remediation is therefore one dedicated technical enrollment identity per managed device.

## Target

SETOK subject:

`sub_01M5Y0XYAMFT3MXRRJV5MFBY3N` / `android-01`

Current Cloudflare device/registration:

`01a17f4d-0062-19de-b716-1df58125a3d4`

Current binding:

`bnd_01M5ZND7V8TK28E2V23Z4MRFEJ`

The actual dedicated mailbox/address is operational secret/PII and MUST NOT be versioned. Versioned artifacts use alias:

`android-01-enrollment`

Do not use plus-addressing as the isolation mechanism.

## Desired lifecycle invariant

Exactly one active technical enrollment identity maps to at most one ACTIVE SETOK device subject and one active Cloudflare registration scope.

For `android-01`:

1. provision one dedicated enrollment identity;
2. temporarily authorize exactly that identity for WARP enrollment;
3. re-enroll the existing intended Redmi handset;
4. verify exactly one new active registration belongs to that identity and to the intended physical handset;
5. retire/replace the old SETOK `device_enrollment` binding only after the new registration is proven;
6. remove or disable enrollment authorization for the dedicated identity after successful enrollment;
7. reconciliation must fail closed if cardinality becomes anything other than exactly one expected active registration;
8. future re-enrollment requires an explicit governed reopen of enrollment authorization.

## In scope

- provider-state preflight and drift check;
- dedicated per-device identity contract;
- governed temporary change to the existing Cloudflare WARP enrollment authorization;
- controlled re-enrollment of the same `android-01` handset;
- creation of a replacement ACTIVE `device_enrollment` binding;
- retirement of the prior binding after successful replacement;
- enrollment authorization closure after success;
- reconciliation/cardinality proof;
- deterministic rollback/offboarding documentation;
- sanitized evidence.

## Out of scope

- any Gateway DNS/Network/HTTP policy create/update/delete/reorder;
- applying ST-POL-001 or ST-POL-002;
- Android MDM;
- `unique_client_id` managed deployment;
- iPad enrollment;
- Authentik human identity changes;
- child login;
- Phase 2 application work.

## Required invariants

1. Project Scope = `PROJECT_SCOPE_OK`.
2. The dedicated identity is not the Cloudflare account-owner/admin identity.
3. The dedicated identity is not reused for iPad or another device.
4. No real email address is committed to Git/evidence.
5. Existing shared Cloudflare surfaces outside the explicitly authorized enrollment policy/device registration remain unchanged.
6. No Gateway policy mutation occurs.
7. Old binding is not retired until replacement registration and binding are proven.
8. Failed re-enrollment leaves a deterministic recovery path.
9. Enrollment authorization is closed again after success.
10. Final identity cardinality is exactly 1 device scope / 1 active registration for `android-01-enrollment`.
11. ST-POL-001/002 remain `APPLY_BLOCKED` after this Story; a later canary Story must re-prove safe selector behavior before enforcement.

## Risk

RED.

Reason: shared Cloudflare enrollment authorization and a live productive device registration will be mutated. Incorrect sequencing could disconnect the handset or widen enrollment scope.

## Stop conditions

- project/repository mismatch;
- unexpected Cloudflare drift;
- dedicated identity is not exclusive to `android-01`;
- another device/registration already uses the identity;
- provider requires MDM/managed deployment;
- old registration/binding would need to be destroyed before replacement is proven;
- Gateway mutation is required;
- PII/secret must be committed;
- enrollment authorization cannot be returned to a closed fail-closed state;
- any unrelated shared surface changes.

## Expected terminal state

`DEDICATED_IDENTITY_ENROLLED / DEVICE_REBOUND / ENROLLMENT_CLOSED / SAFE_SELECTOR_RETEST_REQUIRED`

This terminal state does not itself authorize Gateway apply.
