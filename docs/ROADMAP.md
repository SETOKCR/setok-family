# SETOK Family — ROADMAP

## Governance status

Current focus: **Phase 1 — Infrastructure, Enforcement and Identity**.

Current AIDE execution state:

- active unit: `ST-CF-003 — Prove safe selector and scoped Cloudflare enforcement for android-01`
- phase: `read-only discovery / preflight`
- risk: `RED` for eventual implementation
- Story: `DEFINED`
- Independent Check: `PASS WITH CONDITIONS — READ-ONLY PREFLIGHT ONLY`
- Product Input Gate: `NOT REQUIRED`
- Authorized Base: `ce81766d2b4c7b95b0a9a116d164cda7ffa0584e`
- branch: `feature/st-cf-003`
- read-only discovery authorized: `YES`
- implementation authorization: `NO`
- provider mutation authorization: `NO`
- safe selector: `NOT_YET_PROVEN`
- iPad Standard enrollment: `DEFERRED — later Phase 1`

Last completed unit: `ST-DEV-001 — Establish first Android device enrollment and provider binding` — `ACCEPT`.

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
8. **Scoped Cloudflare enforcement / safe-selector validation for `android-01` — ACTIVE: ST-CF-003 READ-ONLY DISCOVERY.**
9. **Android anti-bypass and real-device behavior validation.**
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

## ST-CF-003 discovery boundary

ST-CF-003 exists because the accepted provider binding does not automatically imply a usable Gateway policy selector.

Current documented provider facts to validate live:

- direct physical-device / registration IDs are not currently documented as Gateway DNS/Network/HTTP selectors;
- exact authenticated user email is available as an identity selector, but is identity-scoped rather than intrinsically physical-device-scoped;
- mobile serial-number posture is not supported;
- mobile Device UUID / `unique_client_id` requires managed deployment and cannot be manually assigned;
- Device IP is not available on Android/iOS.

Therefore ST-CF-003 must test whether the dedicated enrollment identity can provide a durable fail-closed first-family scope without exposing PII in desired state. If not, enforcement remains blocked or an architecture change must be considered.

Read-only discovery must also establish current Gateway first-match/precedence semantics and entitlement/category capability for ST-POL-001/002.

No Gateway mutation is authorized during discovery.

Expected discovery terminal state is exactly one of:

- `SAFE_SELECTOR_PROVEN / APPLY_NOT_AUTHORIZED`
- `SAFE_SELECTOR_NOT_PROVEN / APPLY_BLOCKED`
- `ARCHITECTURE_CHANGE_REQUIRED / APPLY_BLOCKED`

## Deferred enforcement findings

No existing ST-POL-001 or ST-POL-002 plan may be marked `APPLIED` until ST-CF-003 proves safe isolation and a later explicit implementation GO authorizes a staged provider mutation.

## Phase 1 exit condition

Phase 1 is complete only when the platform functions correctly without SETOK Family App and enforcement, bypass resistance, identities, provider APIs, modes/overlays and protection levels have been validated.

## Phase 2

SETOK Family application / mini app remains deferred until Phase 1 platform validation.

## Next governance action

Execute the authorized **read-only ST-CF-003 discovery** on `feature/st-cf-003` from Authorized Base `ce81766d2b4c7b95b0a9a116d164cda7ffa0584e`, produce sanitized evidence, and return the selector decision to the Technical Director. Provider mutation remains forbidden.

## Authority

Detailed architecture and risks remain in `docs/ARCHITECTURE.md`. Story, Work Order and evidence preserve execution traceability.
