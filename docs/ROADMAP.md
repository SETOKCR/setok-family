# SETOK Family — ROADMAP

## Governance status

Current focus: **Phase 1 — Infrastructure, Enforcement and Identity**.

This roadmap orders work; implementation authority is carried by the active Story/Work Order and Technical Director state.

Current AIDE execution state:

- active unit: `ST-CF-002 — Establish Cloudflare device enrollment permissions`
- Story: `docs/stories/ST-CF-002.md`
- Work Order: `.ai/work-orders/ST-CF-002.md`
- preflight: `PASS`
- Independent Check: `PASS WITH CONDITIONS`
- risk: `RED`
- Product Input Gate: `CLOSED`
- enrollment identity alias: `family-enrollment-01`
- real mailbox: operational input only, outside Git
- Authorized Base: `PENDING`
- implementation branch: `PENDING`
- implementation authorized: `NO`
- open gates: freeze Authorized Base, create/verify implementation branch, explicit Technical Director implementation authorization

## Phase 1 objective

Deliver and validate a functioning parental-control platform without depending on SETOK Family App.

## Ordered Phase 1 work

1. **Cloudflare foundation — COMPLETE: ST-CF-001 ACCEPT.**
2. **Authentik foundation — COMPLETE: ST-ID-001 ACCEPT.**
3. **First-family human identities — COMPLETE: ST-ID-002 ACCEPT.**
4. **Initial provider-binding model — COMPLETE: ST-PB-001 ACCEPT.**
5. **Baseline policy contract and compilation plan — COMPLETE: ST-POL-001 ACCEPT.**
6. **Standard / Restricted / temporary overlay policy contract — COMPLETE: ST-POL-002 ACCEPT.**
7. **Android enrollment and device binding — BLOCKED: ST-DEV-001 controlled stop at Stage A.** Requires device-enrollment permissions first.
7a. **Cloudflare device enrollment permissions — ACTIVE: ST-CF-002.**
8. iPad Standard enrollment and device binding.
9. Scoped Cloudflare enforcement apply and validation for enrolled Familia Ulate León devices. Apply baseline + approved mode/overlay compilation only after selector isolation, rollback, entitlement and blast-radius gates pass.
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

## Completed foundation evidence

### ST-CF-001 — Cloudflare foundation

Established an isolated custom Cloudflare device profile `SETOK-FAMILY-MANAGED` in the shared SETOK Zero Trust organization without modifying the Default profile or organization.

Known deferred constraint: the current mobile selector covers Android/iOS devices in the shared Zero Trust org. Before another project enrolls mobile devices here, it needs a narrower selector. ST-PB-001 models the integration/resource boundary but does not mutate or narrow this selector.

### ST-ID-001 — Authentik foundation

Established the Authentik Identity Plane on dedicated VM `220 setok-family-idp-01` on Proxmox `pve-02`, with Ubuntu 24.04 LTS, Docker Compose, Authentik + PostgreSQL, no direct WAN exposure, no Docker socket mount, secrets outside Git, off-VM PostgreSQL backup, health/API/UI validation and recovery evidence.

Accepted candidate: `6bcd99024ef86f7819a957c2e17e2b9a442178f7`.
Integration commit: `e6d1bffa65762b93069fdf480d5d67628e1fbdef`.

### ST-ID-002 — First-family human identities

Established the first two adult human authentication identities for **Familia Ulate León**, the first productive family in SETOK Family. Both are regular non-admin Authentik users; interactive login and recovery were verified; temporary provisioning privilege was revoked; no child identity or family-domain authorization was introduced.

Accepted candidate: `9111781ac67a1db4194102368be311849d59d174`.
Integration commit: `c506ac29b1d1463c5003adc98a41eaf8b5c28d05`.
Evidence: `docs/evidence/ST-ID-002/`.

### ST-PB-001 — Initial provider-binding registry

Established a provider-neutral, tenant-scoped desired-state registry for Familia Ulate León with one stable internal family tenant ID, two opaque adult subject IDs, Authentik identity bindings, shared Cloudflare integration/resource bindings, lifecycle/cardinality rules, zero device subjects/bindings, read-only provider reconciliation and no PII/secrets in versioned state.

Accepted candidate: `e3a0cce7d43e73fa4081a8a8500aea1b9aa0d3f8`.
Integration commit: `e8e3a44671f57b7d9b447bcbda3579c78924f716`.
Evidence: `docs/evidence/ST-PB-001/`.

### ST-POL-001 — Baseline policy contract and Cloudflare compilation plan

Established the provider-neutral baseline Policy Intent and deterministic Cloudflare DNS compilation plan.

Baseline contract:

- malware BLOCK;
- phishing BLOCK;
- command-and-control / botnet BLOCK;
- adult content BLOCK;
- gambling BLOCK;
- SafeSearch FORCE;
- YouTube Restricted Mode FORCE.

The compiled plan remains blocked from apply until real device scope, safe selector, provider-mutation authorization, rollback/blast-radius controls and actual-plan entitlement are proven.

Accepted candidate: `fb3ef4f429c797e1f658d65e2dc80ea305df64d6`.
Integration commit: `019dc396cd4f6f0fc3f77b5caa9073d7385c41f7`.
Evidence: `docs/evidence/ST-POL-001/`.

### ST-POL-002 — Standard / Restricted / temporary overlay policy contract

Established the PO-approved provider-neutral policy semantics and deterministic composition. No provider mutation occurred and all Cloudflare plans remain `APPLY_BLOCKED`.

Accepted candidate: `8e0121e2b45e39a759f2774a4427d72de5b9d155`.
Integration commit: `a3d7aff30ff4a1f8729d5ee59d9ea2f8b572f85b`.
Evidence: `docs/evidence/ST-POL-002/`.

Deferred enforcement findings carried forward:

- premium-class entitlement must be proven before apply;
- Gateway first-match ordering must be validated on an enrolled test device;
- safe family/device selector isolation remains mandatory because the Cloudflare account is shared.

## Blocked unit — ST-DEV-001

ST-DEV-001 stopped correctly at Stage A with **no external mutation**.

Observed:

- 0 physical devices / registrations;
- 0 Access apps;
- 0 Access policies;
- 0 service tokens;
- One-time PIN is the only IdP;
- `SETOK-FAMILY-MANAGED`, Default and Gateway remained unchanged;
- registry still has 0 device subjects and 0 device bindings.

Controlled-stop candidate/evidence commit: `74cb833a1fcbc2e452fd7d0dde578b22ca9fdaf4` on `feature/st-dev-001`.

Stop reason: manual Cloudflare One enrollment requires device-enrollment permissions, which do not yet exist and were outside ST-DEV-001 authorization.

ST-DEV-001 resumes only after ST-CF-002 is accepted, from a fresh Stage A discovery.

## Active unit boundary — ST-CF-002

ST-CF-002 creates the minimum durable enrollment authorization for SETOK Family inside the shared Cloudflare account:

- one Access application type `warp`, named `SETOK-FAMILY-DEVICE-ENROLLMENT`;
- one `allow` policy;
- exactly one operational enrollment identity, represented in Git only as `family-enrollment-01`;
- existing One-time PIN IdP only;
- no domain/everyone/group rule;
- no service token;
- no Gateway, profile, selector, posture, device or login-method changes.

The managed enrollment app/policy is intended to remain after successful completion because Android enrollment resumes next and iPad Standard enrollment follows. Rollback remains deletion of only the created policy/app by observed IDs.

The real enrollment mailbox selected by the Product Owner remains operational input outside Git/evidence.

## Sequencing clarification

Policy design/compilation and provider enforcement apply remain separate gates.

ST-CF-002 only enables authentication eligibility for device enrollment. It does not enroll a device and does not prove safe Gateway selector isolation.

## Phase 1 exit condition

Phase 1 is complete only when the platform functions correctly without SETOK Family App and the project has validated enforcement, bypass resistance, identities, provider APIs, states/overlays and Standard vs Enhanced Protection.

## Phase 2

Phase 2 is the SETOK Family application / mini app and consumer experience. It remains intentionally deferred until the Phase 1 platform has been validated.

## Next governance action

Freeze the ST-CF-002 Authorized Base, create `feature/st-cf-002` from that exact commit, verify lineage and require explicit Technical Director implementation authorization. No Cloudflare Access mutation is authorized before that GO.

## Authority

Detailed scope, sequencing rationale, architecture and risks remain in `docs/ARCHITECTURE.md`. Completed Story/Work Order/evidence preserve execution traceability; this roadmap remains the planning authority.
