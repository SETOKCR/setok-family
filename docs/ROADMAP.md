# SETOK Family — ROADMAP

## Governance status

Current focus: **Phase 1 — Infrastructure, Enforcement and Identity**.

This roadmap orders work; implementation authority is carried by the active Story/Work Order and Technical Director state.

Current AIDE execution state:

- active unit: `ST-POL-002 — Establish Standard / Restricted / temporary overlay policy contract`
- Story: `docs/stories/ST-POL-002.md`
- Work Order: `.ai/work-orders/ST-POL-002.md`
- preflight architecture review: `PASS`
- Independent Check: `PASS WITH CONDITIONS`
- risk: `YELLOW — ordinary score 6/10`
- Product Input Gate: `OPEN`
- Authorized Base: `PENDING`
- implementation branch: `PENDING`
- implementation authorized: `NO`
- open gates: Product Input approval, freeze Authorized Base, create/verify implementation branch, explicit Technical Director implementation authorization

## Phase 1 objective

Deliver and validate a functioning parental-control platform without depending on SETOK Family App.

## Ordered Phase 1 work

1. **Cloudflare foundation — COMPLETE: ST-CF-001 ACCEPT.**
2. **Authentik foundation — COMPLETE: ST-ID-001 ACCEPT.**
3. **First-family human identities — COMPLETE: ST-ID-002 ACCEPT.**
4. **Initial provider-binding model — COMPLETE: ST-PB-001 ACCEPT.**
5. **Baseline policy contract and compilation plan — COMPLETE: ST-POL-001 ACCEPT.**
6. **Standard / Restricted / temporary overlay policy contract — ACTIVE: ST-POL-002.** Product semantics require PO approval before Authorized Base freeze. No Gateway apply in this unit.
7. Android enrollment and device binding.
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

Established a provider-neutral, tenant-scoped desired-state registry for Familia Ulate León:

- one stable internal family tenant ID;
- two opaque adult internal subject IDs;
- Authentik identity bindings to the existing two adult users;
- Cloudflare modeled as a shared integration boundary;
- `SETOK-FAMILY-MANAGED` modeled as a managed provider resource, not a device;
- zero device subjects and zero device bindings;
- lifecycle `ACTIVE / RETIRED / STALE / ERROR` and replacement semantics;
- cardinality and tenant-isolation invariants;
- read-only reconciliation against Authentik and Cloudflare with unchanged provider fingerprints;
- no PII/secrets in versioned state or evidence.

Accepted candidate: `e3a0cce7d43e73fa4081a8a8500aea1b9aa0d3f8`.
Integration commit: `e8e3a44671f57b7d9b447bcbda3579c78924f716`.
Evidence: `docs/evidence/ST-PB-001/`.

### ST-POL-001 — Baseline policy contract and Cloudflare compilation plan

Established the provider-neutral baseline Policy Intent and deterministic Cloudflare DNS compilation plan for the first productive family tenant.

Baseline contract:

- malware BLOCK;
- phishing BLOCK;
- command-and-control / botnet BLOCK;
- adult content BLOCK;
- gambling BLOCK;
- SafeSearch FORCE;
- YouTube Restricted Mode FORCE.

The Story proved schema/invariants, fail-closed provider mapping, precedence protection, deterministic compilation and read-only Cloudflare capability discovery. No Gateway policy was created or changed and nothing was claimed APPLIED.

The compiled plan is intentionally `BLOCKED` from apply until all prerequisites are satisfied:

- enrolled Familia Ulate León device binding exists;
- safe family/device selector is proven not to match unrelated SETOK traffic;
- provider mutation is separately authorized with rollback and blast-radius controls;
- availability of the premium-class Cloudflare Gambling category is verified for the actual account plan.

Accepted candidate: `fb3ef4f429c797e1f658d65e2dc80ea305df64d6`.
Integration commit: `019dc396cd4f6f0fc3f77b5caa9073d7385c41f7`.
Evidence: `docs/evidence/ST-POL-001/`.

## Active unit boundary — ST-POL-002

ST-POL-002 defines provider-neutral persistent modes, temporary overlays, expiration/reversal and deterministic composition. It does not mutate Cloudflare and cannot claim enforcement `APPLIED`.

Architecture already fixes baseline protection, precedence ownership, reversibility and Essential Services behavior. Product Input is required only for the exact first-family consumer semantics of `STANDARD`, `RESTRICTED` and the initial overlay set.

Recommended semantics pending PO approval are documented in `docs/stories/ST-POL-002.md`.

## Sequencing clarification after ST-POL-001

Policy **design/compilation** and provider **enforcement apply** are explicit separate gates.

SETOK can safely define `STANDARD`, `RESTRICTED` and temporary overlays before devices are enrolled because those artifacts remain provider-neutral desired state and compilation contracts. Actual Gateway mutation must wait until enrollment creates a verifiable tenant/device scope.

This prevents a shared-account rule from affecting unrelated SETOK traffic while preserving architecture-first development.

## Phase 1 exit condition

Phase 1 is complete only when the platform functions correctly without SETOK Family App and the project has validated enforcement, bypass resistance, identities, provider APIs, states/overlays and Standard vs Enhanced Protection.

## Phase 2

Phase 2 is the SETOK Family application / mini app and consumer experience. It remains intentionally deferred until the Phase 1 platform has been validated.

## Next governance action

Close the ST-POL-002 Product Input Gate by explicit PO approval or amendment of the recommended `STANDARD`, `RESTRICTED`, `STUDY`, `ALLOW_SOCIAL`, `PAUSE_ENTERTAINMENT` and `CLEAR_TEMPORARY` semantics. Only then freeze Authorized Base and prepare implementation.

## Authority

Detailed scope, sequencing rationale, architecture and risks remain in `docs/ARCHITECTURE.md`. Completed Story/Work Order/evidence preserve execution traceability; this roadmap remains the planning authority.
