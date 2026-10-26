# SETOK Family — ROADMAP

## Governance status

Current focus: **Phase 1 — Infrastructure, Enforcement and Identity**.

This roadmap orders work; implementation authority is carried by the active Story/Work Order and Technical Director state.

Current AIDE execution state:

- active unit: `ST-PB-001 — Establish initial provider-binding registry`
- Story: `docs/stories/ST-PB-001.md`
- Work Order: `.ai/work-orders/ST-PB-001.md`
- preflight: `PASS`
- Independent Check: `PASS WITH CONDITIONS`
- risk: `YELLOW — ordinary score 4/10`
- Authorized Base: `PENDING`
- implementation branch: `feature/st-pb-001`
- implementation authorized: `NO`
- Product Input Gate: `NOT REQUIRED`
- open gates: freeze Authorized Base, verify branch lineage, explicit Technical Director implementation authorization

## Phase 1 objective

Deliver and validate a functioning parental-control platform without depending on SETOK Family App.

## Ordered Phase 1 work

1. **Cloudflare foundation — COMPLETE: ST-CF-001 ACCEPT.**
2. **Authentik foundation — COMPLETE: ST-ID-001 ACCEPT.**
3. **First-family human identities — COMPLETE: ST-ID-002 ACCEPT.**
4. **Initial provider-binding model — ACTIVE: ST-PB-001.**
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

Established an isolated custom Cloudflare device profile `SETOK-FAMILY-MANAGED` in the shared SETOK Zero Trust organization without modifying the Default profile or organization.

Known deferred constraint: the current mobile selector covers Android/iOS devices in the shared Zero Trust org. Before another project enrolls mobile devices here, it needs a narrower selector. ST-PB-001 models the integration/resource boundary but does not mutate or narrow this selector.

### ST-ID-001 — Authentik foundation

Established the Authentik Identity Plane on dedicated VM `220 setok-family-idp-01` on Proxmox `pve-02`, with Ubuntu 24.04 LTS, Docker Compose, Authentik + PostgreSQL, no direct WAN exposure, no Docker socket mount, secrets outside Git, off-VM PostgreSQL backup, health/API/UI validation and recovery evidence.

Accepted candidate: `6bcd99024ef86f7819a957c2e17e2b9a442178f7`.
Integration commit: `e6d1bffa65762b93069fdf480d5d67628e1fbdef`.

Operational follow-up: Product Owner will restart VM 210 under controlled observation to validate long-term memory coexistence. This is not an implementation gate for ST-ID-001.

### ST-ID-002 — First-family human identities

Established the first two adult human authentication identities for **Familia Ulate León**, the first productive family in SETOK Family.

Boundary preserved:
- Familia Ulate León is a tenant of the SETOK Family domain, not an Authentik tenant;
- no Owner/Parent/Viewer/Child/Guardian/Family authorization modeled in Authentik;
- no child login;
- no OIDC/federation/Cloudflare Access/device-binding expansion;
- both adult identities are regular non-admin Authentik users;
- interactive login and recovery verified;
- temporary least-privilege provisioner revoked;
- evidence contains aliases only and no real PII/secrets;
- idempotent re-run verified;
- ST-ID-001 foundation remained healthy.

Accepted candidate: `9111781ac67a1db4194102368be311849d59d174`.
Integration commit: `c506ac29b1d1463c5003adc98a41eaf8b5c28d05`.
Evidence: `docs/evidence/ST-ID-002/`.

Operational custody follow-up: Product Owner confirmed both initial passwords are stored in Bitwarden. Temporary DPAPI credential copies may be removed after local confirmation; the non-secret identities input may remain for operational reconciliation while useful.

## Active unit boundary — ST-PB-001

ST-PB-001 establishes the first provider-neutral binding registry for Familia Ulate León and reconciles it read-only against the accepted Authentik and Cloudflare foundations.

The Story establishes stable internal SETOK references and external bindings without creating a Phase 2 runtime database. It must preserve these boundaries:

- every binding is tenant-scoped;
- SETOK internal IDs are independent from provider IDs;
- two opaque adult human subjects bind to the existing Authentik users;
- Cloudflare shared account/org/profile are integration/resource bindings, not family/human/device identities;
- the shared Cloudflare account is not claimed as exclusively owned by SETOK Family;
- desired state and observed provider state remain separate;
- no real PII/secrets in Git/evidence;
- no device subject or device binding is created before enrollment;
- no provider mutation is allowed;
- no Owner/Parent/Viewer/Guardian/Child authorization is encoded in providers/bindings.

Independent Check mandatory conditions additionally require explicit lifecycle/replacement semantics and cardinality that supports future multi-provider bindings without duplicate active bindings.

## Phase 1 exit condition

Phase 1 is complete only when the platform functions correctly without SETOK Family App and the project has validated enforcement, bypass resistance, identities, provider APIs, states/overlays and Standard vs Enhanced Protection.

## Phase 2

Phase 2 is the SETOK Family application / mini app and consumer experience. It remains intentionally deferred until the Phase 1 platform has been validated.

## Next governance action

Freeze the ST-PB-001 Authorized Base and verify branch lineage. No implementation is authorized until explicit Technical Director authorization is recorded.

## Authority

Detailed scope, sequencing rationale, architecture and risks remain in `docs/ARCHITECTURE.md`. Completed Story/Work Order/evidence preserve execution traceability; this roadmap remains the planning authority.
