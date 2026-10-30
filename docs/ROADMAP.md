# SETOK Family — ROADMAP

## Governance status

Current focus: **Phase 1 — Infrastructure, Enforcement and Identity**.

Current AIDE execution state:

- active unit: `ST-CF-004 — Establish dedicated per-device Cloudflare enrollment identity and fail-closed lifecycle`
- phase: `preflight / Product Input Gate`
- risk: `RED`
- Story: `DEFINED`
- Independent Check: `PASS WITH CONDITIONS — GOVERNANCE/PREFLIGHT ONLY`
- Product Input Gate: `OPEN — dedicated android-01 enrollment mailbox required`
- implementation authorization: `NO`
- provider mutation authorization: `NO`
- safe selector: `NOT PROVEN — retest required after ST-CF-004`
- iPad Standard enrollment: `DEFERRED — later Phase 1`

Last completed unit: `ST-CF-003 — Prove safe selector and scoped Cloudflare enforcement for android-01` — `ACCEPT / SAFE_SELECTOR_NOT_PROVEN / APPLY_BLOCKED`.

## Phase 1 objective

Deliver and validate a functioning parental-control platform without depending on SETOK Family App.

## Ordered Phase 1 work

1. **Cloudflare foundation — COMPLETE: ST-CF-001 ACCEPT.**
2. **Authentik foundation — COMPLETE: ST-ID-001 ACCEPT.**
3. **First-family human identities — COMPLETE: ST-ID-002 ACCEPT.**
4. **Initial provider-binding model — COMPLETE: ST-PB-001 ACCEPT.**
5. **Baseline policy contract and compilation plan — COMPLETE: ST-POL-001 ACCEPT.**
6. **Standard / Restricted / temporary overlay policy contract — COMPLETE: ST-POL-002 ACCEPT.**
7. **Android enrollment and device binding — COMPLETE: ST-DEV-001 ACCEPT.**
7a. **Cloudflare device enrollment permissions — COMPLETE: ST-CF-002 ACCEPT.**
8. **Scoped Cloudflare enforcement / safe-selector validation for `android-01` — COMPLETE DISCOVERY: ST-CF-003 `SAFE_SELECTOR_NOT_PROVEN / APPLY_BLOCKED`.**
8a. **Dedicated per-device enrollment identity and fail-closed lifecycle — ACTIVE: ST-CF-004 PREFLIGHT / PRODUCT INPUT GATE.**
8b. **Re-test safe selector and staged canary DNS enforcement — BLOCKED pending ST-CF-004.**
9. **Android anti-bypass and real-device behavior validation — BLOCKED pending safe scoped enforcement.**
10. **PowerShell automation / operational reconciliation**, refined from enforcement findings.
11. **iPad Standard enrollment and device binding — DEFERRED until Android enforcement architecture is proven.**
12. **iPad Enhanced / MDM enrollment — DEFERRED; evaluate only after Standard/iOS capability gaps are known.**
13. Define signals, freshness and confidence for Protection State.
14. Device Capabilities matrix by platform.
15. Validate captive portals / MASQUE / incompatible networks.
16. Define Time Context and travel behavior.
17. Formalize Policy Precedence.
18. Define Command / Execution and idempotency contract.
19. Validate Essential Services and high-impact actions.
20. Consumer Continuity and mobile break-glass testing.
21. Define Policy Revision / Last Known Good.
22. Device lifecycle and Owner recovery.
23. Phase 1 closure.
24. API/provider contract for Phase 2.

## Priority decision — 2026-10-27

The Product Owner elected to defer iPad work. Technical Director disposition: **APPROVED**.

Rationale:

- Android now provides a real enrolled and bound productive endpoint;
- the highest unresolved architecture risk is safe policy isolation inside the shared Cloudflare Zero Trust organization;
- adding iOS before proving scoped enforcement would increase platform surface without reducing that core risk;
- if safe selector / policy ordering requires an architecture change, it is safer to discover that with one bound endpoint before onboarding another platform.

The iPad remains in Phase 1 scope but is no longer a prerequisite for validating core enforcement architecture.

## ST-CF-002 closure

ST-CF-002 established the minimum durable Cloudflare device-enrollment authorization:

- one Access application of type `warp`;
- one exact-identity `allow` policy;
- existing One-time PIN IdP only;
- no Gateway, profile, IdP, service-token, posture, physical-device or registration mutation.

Accepted candidate: `678aaff9722af68238dec3ea5c57eeb84c1e7735`.
Integration commit: `14f38ceb2eb043e62740de6bbe2987014f7824b3`.
Evidence: `docs/evidence/ST-CF-002/`.

## ST-DEV-001 closure

ST-DEV-001 established the first real SETOK Family Android device binding.

Final physical target:

`Redmi Note 13 Pro+ 5G (23090RA98G)`

The earlier `Xiaomi Redmi Note 14 Pro` target was corrected after provider observation and explicit Product Owner confirmation. The controlled-stop history was preserved.

Final identity chain:

- SETOK subject: `sub_01M5Y0XYAMFT3MXRRJV5MFBY3N` / `android-01`;
- Cloudflare device/registration: `01a17f4d-0062-19de-b716-1df58125a3d4`;
- SETOK binding: `bnd_01M5ZND7V8TK28E2V23Z4MRFEJ`;
- binding type: `device_enrollment`;
- status: `ACTIVE`;
- observed profile: `SETOK-FAMILY-MANAGED`;
- registration type: WARP;
- tunnel: MASQUE.

Validation:

- reconciliation `MATCH` twice and deterministic;
- 15/15 shared Cloudflare surfaces unchanged;
- no Gateway policy applied or changed;
- no Android MDM;
- no Child login;
- no PII/secrets in versioned evidence;
- rollback/offboarding documented.

Evidence: `docs/evidence/ST-DEV-001/`.

Successful terminal state:

`DEVICE_ENROLLED / DEVICE_BOUND / SAFE_SELECTOR_NOT_YET_PROVEN`

## ST-CF-003 closure

ST-CF-003 executed read-only discovery against the accepted Android state and returned:

`SAFE_SELECTOR_NOT_PROVEN / APPLY_BLOCKED`

Accepted discovery candidate:

`2b63433e3af5fc6aa6c581bbb7bd290bb579cc26`

Integration commit:

`1921b2c057b820a23fe5cd3287dcd30ce15652bb`

Evidence: `docs/evidence/ST-CF-003/`.

Key findings:

- accepted `android-01` state remained `MATCH`;
- direct physical-device / registration IDs are not supported Gateway DNS/Network/HTTP selectors;
- exact `User Email` is supported but the current identity is shared/administrative and is not fail-closed;
- current identity cardinality was 1 device / 1 registration, but the active enrollment policy could immediately allow a second registration using the same identity;
- Android serial-number posture is unsupported;
- Android Device IP is unavailable as a unique device selector;
- Device UUID / `unique_client_id` requires managed deployment/MDM and is not accepted for the current Android architecture;
- 15/15 shared Cloudflare surfaces remained unchanged;
- no Gateway mutation occurred;
- ST-POL-001 and ST-POL-002 remain `APPLY_BLOCKED`.

## ST-CF-004 active boundary

ST-CF-004 remediates the selector lifecycle problem without introducing Android MDM.

Desired model:

`android-01` -> dedicated operational enrollment identity -> one intended Cloudflare registration -> replacement SETOK binding -> enrollment authorization closed again.

The actual mailbox/address remains outside Git and evidence. Versioned alias:

`android-01-enrollment`

Plus-addressing is not accepted as the isolation mechanism.

Product Input Gate requires one real dedicated mailbox/address that can receive Cloudflare One-time PIN messages, is not the account owner/admin identity and is not reused for another device.

ST-CF-004 does not apply Gateway policy. Its successful terminal state is:

`DEDICATED_IDENTITY_ENROLLED / DEVICE_REBOUND / ENROLLMENT_CLOSED / SAFE_SELECTOR_RETEST_REQUIRED`

A later unit must re-prove safe selector behavior and execute a narrowly scoped canary before any ST-POL-001/002 apply.

## Deferred enforcement findings

No existing ST-POL-001 or ST-POL-002 plan may be marked `APPLIED` until safe isolation is independently re-proven after ST-CF-004 and a later explicit implementation GO authorizes a staged provider mutation.

Premium-category entitlement remains unverified for controls including gambling, social media, gaming and streaming categories.

## Phase 1 exit condition

Phase 1 is complete only when the platform functions correctly without SETOK Family App and enforcement, bypass resistance, identities, provider APIs, modes/overlays and protection levels have been validated.

## Phase 2

SETOK Family application / mini app remains deferred until Phase 1 platform validation.

## Next governance action

Close the ST-CF-004 Product Input Gate by making available one dedicated `android-01` enrollment mailbox outside Git. Then perform a fresh read-only preflight and request explicit Technical Director implementation authorization before any Cloudflare or handset mutation.

## Authority

Detailed architecture and risks remain in `docs/ARCHITECTURE.md`. Story, Work Order and evidence preserve execution traceability.
