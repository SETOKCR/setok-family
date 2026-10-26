# SETOK Family — ROADMAP

## Governance status

Current focus: **Phase 1 — Infrastructure, Enforcement and Identity**.

This roadmap orders work; implementation authority is carried by the active Story/Work Order and Technical Director state.

Current AIDE execution state:

- active unit: `ST-ID-001 — Establish Authentik pilot identity foundation`
- Story: `docs/stories/ST-ID-001.md`
- Work Order: `.ai/work-orders/ST-ID-001.md`
- preflight: `PASS WITH RED GATE`
- risk: `RED — Auto-RED(authentication), ordinary score 5/10`
- implementation authorized: `NO`
- Authorized Base: `NONE`
- Active Execution Alignment: `NOT_APPLICABLE`
- open gate: Independent Check before implementation authorization

## Phase 1 objective

Deliver and validate a functioning parental-control platform without depending on SETOK Family App.

## Ordered Phase 1 work

The approved architecture defines the following implementation order:

1. **Cloudflare foundation — COMPLETE: ST-CF-001 ACCEPT.**
2. **Authentik foundation — ACTIVE: ST-ID-001, preflight passed, RED gate open, implementation not authorized.**
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

## Completed foundation evidence

`ST-CF-001` established an isolated custom Cloudflare device profile `SETOK-FAMILY-MANAGED` in the shared SETOK Zero Trust organization without modifying the Default profile or organization. Desired state and evidence are retained under `infra/cloudflare/`, `scripts/st-cf-001/` and `docs/evidence/ST-CF-001/`.

Known deferred constraint: the current mobile selector covers Android/iOS devices in the shared Zero Trust org. Before another mobile population is introduced there, later provider-binding / identity work must narrow that selector appropriately.

## Active unit boundary

`ST-ID-001` establishes only the Authentik self-hosted pilot foundation: deployment, persistence, secure bootstrap, backup/remediation and operational verification. It explicitly excludes real family users, domain roles, Guardian↔Child authorization, federation, OIDC for the app, Cloudflare Access integration and commercial HA.

Because this Story establishes the authoritative human authentication mechanism, it is `RED` by `Auto-RED(authentication)`. AIDE requires reinforced review; implementation remains blocked until the Independent Check passes and an Authorized Base is frozen.

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

Perform an Independent Check of `ST-ID-001` architecture/security/readiness. Only after PASS may the Technical Director resolve an Authorized Base, create the implementation branch and consider implementation authorization.

## Authority

Detailed scope, sequencing rationale, architecture and risks remain in `docs/ARCHITECTURE.md`. Completed Story/Work Order/evidence preserve execution traceability; this roadmap remains the planning authority.
