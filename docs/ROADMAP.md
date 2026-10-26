# SETOK Family — ROADMAP

## Governance status

Current focus: **Phase 1 — Infrastructure, Enforcement and Identity**.

This roadmap orders work; implementation authority is carried by the active Story/Work Order and Technical Director state.

Current AIDE execution state:

- active unit: `NONE`
- last completed: `ST-ID-001 — Establish Authentik pilot identity foundation`
- result: `ACCEPT`
- risk: `RED — Auto-RED(authentication), ordinary score 5/10`
- implementation authorized: `NO`
- Authorized Base: `NONE`
- Active Execution Alignment: `NOT_APPLICABLE`
- open gates: `NONE`

## Phase 1 objective

Deliver and validate a functioning parental-control platform without depending on SETOK Family App.

## Ordered Phase 1 work

The approved architecture defines the following implementation order:

1. **Cloudflare foundation — COMPLETE: ST-CF-001 ACCEPT.**
2. **Authentik foundation — COMPLETE: ST-ID-001 ACCEPT.**
3. **Pilot-tenant identities — NEXT PLANNED; not yet selected or authorized.**
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

### ST-CF-001 — Cloudflare foundation

Established an isolated custom Cloudflare device profile `SETOK-FAMILY-MANAGED` in the shared SETOK Zero Trust organization without modifying the Default profile or organization. Desired state and evidence are retained under `infra/cloudflare/`, `scripts/st-cf-001/` and `docs/evidence/ST-CF-001/`.

Known deferred constraint: the current mobile selector covers Android/iOS devices in the shared Zero Trust org. Before another mobile population is introduced there, later provider-binding / identity work must narrow that selector appropriately.

### ST-ID-001 — Authentik foundation

Established the Authentik pilot Identity Plane on dedicated VM `220 setok-family-idp-01` on Proxmox `pve-02`:

- Ubuntu 24.04 LTS;
- 2 vCPU / 2 GiB RAM / 40 GiB disk;
- Docker Engine + Docker Compose v2;
- Authentik + PostgreSQL;
- no direct WAN exposure;
- no Docker socket mount in worker;
- secrets outside Git;
- PostgreSQL logical backup stored off-VM;
- health/API/UI, scope, secret, idempotency and recovery evidence retained;
- VM `210 setok-live-01` not modified by the Story.

Accepted candidate: `6bcd99024ef86f7819a957c2e17e2b9a442178f7`.
Integration commit: `e6d1bffa65762b93069fdf480d5d67628e1fbdef`.

Operational follow-up: the Product Owner will restart VM 210 under controlled observation to validate long-term memory coexistence. This is not an open implementation gate for ST-ID-001.

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

Await Product Owner direction before selecting the next Story. Architecture order indicates **Pilot-tenant identities** next. Selection is not implementation authorization; the next unit must pass the normal AIDE preflight before execution.

## Authority

Detailed scope, sequencing rationale, architecture and risks remain in `docs/ARCHITECTURE.md`. Completed Story/Work Order/evidence preserve execution traceability; this roadmap remains the planning authority.
