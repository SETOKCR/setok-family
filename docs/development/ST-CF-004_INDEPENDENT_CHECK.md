# ST-CF-004 — Independent Check

## Decision

`PASS WITH CONDITIONS — GOVERNANCE/PREFLIGHT ONLY`

Implementation is **NOT AUTHORIZED** by this check.

## Risk classification

`RED`

Reasons:

- the shared Cloudflare WARP enrollment authorization will eventually be changed;
- the existing productive Android registration will be replaced/re-enrolled;
- sequencing errors could disconnect `android-01`, leave enrollment open, or broaden future Gateway identity scope;
- the old binding must remain recoverable until replacement state is proven.

## Architecture finding

The Story is a valid remediation for the ST-CF-003 blocker without introducing Android MDM.

A dedicated per-device operational identity can become a candidate Gateway `User Email` scope only if the enrollment lifecycle itself prevents that same identity from silently creating a second active registration.

The identity is an operational provider credential/reference. It is not:

- a SETOK human identity;
- a Child login;
- an Authentik family member;
- a Cloudflare account-owner/admin identity.

## Mandatory Product Input Gate

Before implementation authorization, the Product Owner must make available one real email address/mailbox dedicated exclusively to `android-01` that can receive Cloudflare One-time PIN messages.

Requirements:

- it MUST NOT be the Cloudflare account owner/admin address;
- it MUST NOT be reused for iPad or another device;
- plus-addressing MUST NOT be used as the isolation mechanism;
- the actual address MUST remain outside Git and sanitized evidence;
- OTP values MUST never be committed or pasted into evidence.

Versioned alias: `android-01-enrollment`.

Until this gate is closed, implementation authorization = `NO`.

## Required implementation sequence

Any future Work Order must enforce this ordering:

1. `PROJECT_SCOPE_OK` and exact Authorized Base lineage.
2. Read-only reconciliation of ST-DEV-001/ST-CF-003 accepted state.
3. Resolve the dedicated identity locally and prove it is not already associated with any Cloudflare device/registration.
4. Capture deterministic before-fingerprints for shared Cloudflare surfaces.
5. Temporarily change the existing WARP enrollment authorization to permit exactly `android-01-enrollment`.
6. Re-enroll the intended Redmi handset.
7. Prove the new registration belongs to the intended handset and exact dedicated identity.
8. Prove cardinality = exactly one active registration/device scope for the dedicated identity.
9. Create replacement ACTIVE SETOK `device_enrollment` binding.
10. Reconcile the replacement binding twice deterministically.
11. Retire the old SETOK binding only after steps 7–10 PASS.
12. Close/disable enrollment authorization for the dedicated identity.
13. Prove that a second enrollment using that identity is no longer authorized by provider configuration.
14. Capture after-fingerprints and prove unrelated surfaces unchanged.
15. Preserve rollback/offboarding evidence.

No Gateway rule may be created or changed in this unit.

## Fail-closed criteria

The terminal state is valid only if all are true:

- one dedicated identity -> one intended SETOK device subject;
- one dedicated identity -> exactly one expected active provider registration scope;
- enrollment authorization for that identity is closed after enrollment;
- old binding was not retired before replacement proof;
- no unrelated device or registration became associated with the identity;
- no Gateway policy changed;
- no PII/secret was versioned.

If enrollment authorization cannot be closed after success, terminal result must be `STOP / APPLY_BLOCKED`.

## Rollback requirement

The Work Order must define rollback separately for each boundary:

- before new registration exists: restore original enrollment authorization and keep old binding/registration authoritative;
- after new registration exists but before new binding is proven: preserve old binding and restore provider enrollment authorization; do not retire the old binding;
- after replacement binding is proven but before old binding retirement: either complete closure or revert SETOK authority to the old binding if the new provider state cannot be safely maintained;
- after old binding retirement: rollback requires explicit provider/device offboarding steps and must not silently reopen enrollment.

## Provider mutation boundary

Future implementation may authorize only the minimum provider mutations required for:

- WARP enrollment authorization;
- device re-enrollment/registration lifecycle of the intended handset.

Forbidden:

- Gateway DNS/Network/HTTP rule/list mutation;
- device-profile/default-profile mutation unless independently justified by provider behavior and separately authorized;
- IdP changes;
- service-token changes;
- posture-rule changes;
- unrelated Access application/policy changes;
- Android MDM / managed deployment.

## Independent Check conclusion

`PASS WITH CONDITIONS — GOVERNANCE/PREFLIGHT ONLY`

Open gate:

`PRODUCT_INPUT_REQUIRED: dedicated android-01 enrollment mailbox`

Implementation Authorization: `NO`.
Provider Mutation Authorization: `NO`.
