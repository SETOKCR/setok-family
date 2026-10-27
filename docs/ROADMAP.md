# SETOK Family — ROADMAP

## Governance status

Current focus: **Phase 1 — Infrastructure, Enforcement and Identity**.

Current AIDE execution state:

- last completed unit: `ST-DEV-001 — Establish first Android device enrollment and provider binding`
- terminal decision: `ACCEPT`
- accepted candidate: `bab5ff7259491f0bb1b56d47a9bf3de901635614`
- integration commit: `afaaaf30754dca1a6312ef554017123904abfb4c`
- terminal state: `DEVICE_ENROLLED / DEVICE_BOUND / SAFE_SELECTOR_NOT_YET_PROVEN`
- next planned unit: `iPad Standard enrollment and device binding`
- implementation authorization for next unit: `NO`
- safe selector: `NOT_YET_PROVEN`

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
8. **iPad Standard enrollment and device binding — NEXT.**
9. Scoped Cloudflare enforcement apply and validation for enrolled Familia Ulate León devices.
10. iPad Enhanced / MDM enrollment.
11. PowerShell automation.
12. Anti-bypass testing.
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

## Deferred enforcement findings

Before Gateway apply, the project must still prove provider entitlement, first-match behavior, safe family/device selector isolation, rollback and blast radius. The shared `SETOK-FAMILY-MANAGED` profile still matches Android/iOS broadly; ST-DEV-001 does not claim safe policy isolation.

## Phase 1 exit condition

Phase 1 is complete only when the platform functions correctly without SETOK Family App and enforcement, bypass resistance, identities, provider APIs, modes/overlays and protection levels have been validated.

## Phase 2

SETOK Family application / mini app remains deferred until Phase 1 platform validation.

## Next governance action

Begin discovery/preflight for **iPad Standard enrollment and device binding**. No implementation authorization is implied by ROADMAP ordering; Story, risk, Independent Check and Work Order readiness must be established before any iPad or provider mutation.

## Authority

Detailed architecture and risks remain in `docs/ARCHITECTURE.md`. Story, Work Order and evidence preserve execution traceability.
