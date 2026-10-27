# SETOK Family — ROADMAP

## Governance status

Current focus: **Phase 1 — Infrastructure, Enforcement and Identity**.

Current AIDE execution state:

- active unit: `ST-DEV-001 — Establish first Android device enrollment and provider binding`
- execution attempt: `r2`
- phase: `readiness`
- risk: `RED`
- preflight: `PASS`
- Independent Check: `PASS WITH CONDITIONS`
- Product Input Gate: `NOT REQUIRED`
- prior r1 execution: `CONTROLLED STOP at Stage A`, no external mutation
- prior r1 branch: `feature/st-dev-001` retained as historical evidence
- dependency ST-CF-002: `COMPLETE — ACCEPT`
- Authorized Base r2: `f09d114d29ae7fffc1d8516cd287c83188d4ae00`
- implementation branch r2: `feature/st-dev-001-r2`
- branch lineage: `VERIFIED — one governance-only Work Order commit ahead, zero behind`
- implementation authorized: `NO`
- safe selector: `NOT_YET_PROVEN`
- open gate: explicit Technical Director implementation authorization for r2

## Phase 1 objective

Deliver and validate a functioning parental-control platform without depending on SETOK Family App.

## Ordered Phase 1 work

1. **Cloudflare foundation — COMPLETE: ST-CF-001 ACCEPT.**
2. **Authentik foundation — COMPLETE: ST-ID-001 ACCEPT.**
3. **First-family human identities — COMPLETE: ST-ID-002 ACCEPT.**
4. **Initial provider-binding model — COMPLETE: ST-PB-001 ACCEPT.**
5. **Baseline policy contract and compilation plan — COMPLETE: ST-POL-001 ACCEPT.**
6. **Standard / Restricted / temporary overlay policy contract — COMPLETE: ST-POL-002 ACCEPT.**
7. **Android enrollment and device binding — ACTIVE/READY: ST-DEV-001 r2.**
7a. **Cloudflare device enrollment permissions — COMPLETE: ST-CF-002 ACCEPT.**
8. iPad Standard enrollment and device binding.
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

Cloudflare forces the provider display name `Warp Login App`; SETOK ownership is therefore bound by the managed provider IDs recorded in the registry.

Accepted candidate: `678aaff9722af68238dec3ea5c57eeb84c1e7735`.
Integration commit: `14f38ceb2eb043e62740de6bbe2987014f7824b3`.
Evidence: `docs/evidence/ST-CF-002/`.

The temporary ST-CF-002 write token was revoked after acceptance.

## ST-DEV-001 r2 boundary

The r1 branch is intentionally not rebased or reused. It remains historical evidence of the controlled stop at Stage A (`74cb833a1fcbc2e452fd7d0dde578b22ca9fdaf4`).

ST-DEV-001 r2 begins from the post-ST-CF-002 main state. Before any provider or handset mutation, the Development Agent must run a **fresh Stage A** and prove:

- the managed `warp` enrollment app/policy still exist and reconcile to the registry-bound IDs;
- the policy remains one exact-identity `allow` policy with One-time PIN only;
- Gateway, Default and `SETOK-FAMILY-MANAGED` remain unchanged;
- no unexpected physical devices/registrations exist;
- no additional shared-account mutation is required;
- registry still has no device subject/binding for the target.

Only after Stage A passes may r2 create exactly one provider-neutral Android device subject and proceed toward manual Cloudflare One enrollment.

The only intended provider mutation is the target Android's own supported enrollment/registration. Gateway, profile, enrollment-authorization, IdP, service-token, posture and unrelated-device changes remain forbidden.

Successful terminal state remains:

`DEVICE_ENROLLED / DEVICE_BOUND / SAFE_SELECTOR_NOT_YET_PROVEN`

## Deferred enforcement findings

Before Gateway apply, the project must still prove provider entitlement, first-match behavior, safe family/device selector isolation, rollback and blast radius.

## Phase 1 exit condition

Phase 1 is complete only when the platform functions correctly without SETOK Family App and enforcement, bypass resistance, identities, provider APIs, modes/overlays and protection levels have been validated.

## Phase 2

SETOK Family application / mini app remains deferred until Phase 1 platform validation.

## Next governance action

Await explicit Technical Director implementation authorization for ST-DEV-001 r2. The next GO authorizes fresh Stage A read-only discovery and, only if it passes, the approved device-identity/enrollment flow.

## Authority

Detailed architecture and risks remain in `docs/ARCHITECTURE.md`. Story, Work Order and evidence preserve execution traceability.
