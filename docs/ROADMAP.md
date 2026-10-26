# SETOK Family — ROADMAP

## Governance status

Current focus: **Phase 1 — Infrastructure, Enforcement and Identity**.

This roadmap orders work; it does **not** authorize implementation.

Current AIDE execution state:

- active unit: `ST-CF-001 — Establish Cloudflare Zero Trust pilot foundation`
- Story: `docs/stories/ST-CF-001.md`
- Work Order: `.ai/work-orders/ST-CF-001.md`
- preflight/readiness: `PASS / READY`
- risk: `AMBER 4/10`
- implementation authorized: `NO`
- Active Execution Alignment: `NOT_APPLICABLE`

## Phase 1 objective

Deliver and validate a functioning parental-control platform without depending on SETOK Family App.

## Ordered Phase 1 work

The approved architecture defines the following implementation order:

1. **Cloudflare foundation — ACTIVE: ST-CF-001, READY, implementation not yet authorized.**
2. Authentik foundation.
3. Pilot-tenant identities.
4. Initial provider-binding model.
5. Baseline policies.
6. Standard / Restricted / temporary overlays.
7. Android enrollment.
8. iPad Standard enrollment.
9. iPad Enhanced / MDM enrollment.
10. PowerShell automation.
11. Anti-bypass testing.
12. Define signals, freshness and confidence for Protection State.
13. Device Capabilities matrix by platform.
14. Validate captive portals / MASQUE / incompatible networks.
15. Define Time Context and travel behavior.
16. Formalize Policy Precedence.
17. Define Command / Execution and idempotency contract.
18. Validate Essential Services and high-impact actions.
19. Consumer Continuity and mobile break-glass testing.
20. Define Policy Revision / Last Known Good.
21. Device lifecycle and Owner recovery.
22. Phase 1 closure.
23. API/provider contract for Phase 2.

## Active unit boundary

ST-CF-001 establishes only the minimum Cloudflare Zero Trust pilot foundation. It explicitly excludes baseline policies, Standard/Restricted/overlays, Cloudflare Access + Authentik authorization, app Tunnel publication, device enrollment, MDM and reusable PowerShell automation. Those remain governed by later roadmap units.

## Phase 1 exit condition

Phase 1 is complete only when the platform functions correctly without SETOK Family App and the project has validated:

- enforcement;
- bypass resistance;
- identities;
- provider APIs;
- states and overlays;
- differences between Standard and Enhanced Protection.

## Phase 2

Phase 2 is the SETOK Family application / mini app and consumer experience. It remains intentionally deferred until the Phase 1 platform has been validated.

## Next governance action

Resolve an Authorized Base and explicit implementation authorization for `ST-CF-001` before handing the READY Work Order to a Development Agent. `READY` alone does not authorize mutation.

## Authority

Detailed scope, sequencing rationale, architecture and risks remain in `docs/ARCHITECTURE.md`. The active Story and Work Order carry execution-specific scope and gates; this roadmap remains the planning authority.
