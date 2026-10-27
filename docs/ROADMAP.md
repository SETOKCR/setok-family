# SETOK Family — ROADMAP

## Governance status

Current focus: **Phase 1 — Infrastructure, Enforcement and Identity**.

Current AIDE execution state:

- active unit: `ST-DEV-001 — Establish first Android device enrollment and provider binding`
- phase: `resume-preflight`
- ST-CF-002: `COMPLETE — ACCEPT`
- ST-CF-002 accepted candidate: `678aaff9722af68238dec3ea5c57eeb84c1e7735`
- ST-CF-002 integration commit: `14f38ceb2eb043e62740de6bbe2987014f7824b3`
- temporary ST-CF-002 write credential: revoked
- ST-DEV-001 prior execution: `CONTROLLED STOP at Stage A`, no external mutation
- ST-DEV-001 blocker: resolved by ST-CF-002
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
7. **Android enrollment and device binding — ACTIVE: ST-DEV-001, resume from fresh Stage A.**
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

The provider-binding registry now includes one provider-neutral `enrollment_authorization` resource and one `managed_resource` binding. Reconciliation was deterministic and idempotent. Blast-radius evidence proved only the expected Access app/policy delta.

Evidence: `docs/evidence/ST-CF-002/`.

## ST-DEV-001 resume condition

The previous ST-DEV-001 attempt stopped correctly before any mutation because device-enrollment permissions did not exist. That dependency is now resolved.

ST-DEV-001 must restart with a **fresh Stage A** and prove current state before any new mutation:

- managed `warp` enrollment app/policy exist and reconcile;
- One-time PIN remains the intended IdP;
- Gateway, Default and `SETOK-FAMILY-MANAGED` remain unchanged;
- zero physical devices/registrations exist before handset enrollment;
- no additional shared-account mutation is required.

Only after Stage A passes may it create exactly one Android device subject and proceed to manual enrollment.

Successful terminal state remains:

`DEVICE_ENROLLED / DEVICE_BOUND / SAFE_SELECTOR_NOT_YET_PROVEN`

## Deferred enforcement findings

Before Gateway apply, the project must still prove provider entitlement, first-match behavior, safe family/device selector isolation, rollback and blast radius.

## Phase 1 exit condition

Phase 1 is complete only when the platform functions correctly without SETOK Family App and enforcement, bypass resistance, identities, provider APIs, modes/overlays and protection levels have been validated.

## Phase 2

SETOK Family application / mini app remains deferred until Phase 1 platform validation.

## Next governance action

Refresh ST-DEV-001 Authorized Base/branch continuity against the now-integrated ST-CF-002 state, rerun Stage A read-only discovery, then require explicit implementation authorization before any new mutation.

## Authority

Detailed architecture and risks remain in `docs/ARCHITECTURE.md`. Story, Work Order and evidence preserve execution traceability.
