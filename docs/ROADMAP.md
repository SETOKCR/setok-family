# SETOK Family — ROADMAP

## Governance status

Current focus: **Phase 1 — Infrastructure, Enforcement and Identity**.

This roadmap orders work; implementation authority is carried by the active Story/Work Order and Technical Director state.

Current AIDE execution state:

- active unit: `ST-POL-001 — Establish baseline policy contract and Cloudflare compilation plan`
- Story: `docs/stories/ST-POL-001.md`
- Work Order: `.ai/work-orders/ST-POL-001.md`
- preflight: `PASS`
- Independent Check: `PASS WITH CONDITIONS`
- risk: `YELLOW — ordinary score 5/10`
- Authorized Base: `df0a9dd9968c44428ab69e9e19c91fc2f164809e`
- implementation branch: `feature/st-pol-001`
- branch lineage: `VERIFIED — exactly one governance-only Work Order commit above Authorized Base`
- implementation authorized: `NO`
- Product Input Gate: `NOT REQUIRED`
- open gates: explicit Technical Director implementation authorization

## Phase 1 objective

Deliver and validate a functioning parental-control platform without depending on SETOK Family App.

## Ordered Phase 1 work

1. **Cloudflare foundation — COMPLETE: ST-CF-001 ACCEPT.**
2. **Authentik foundation — COMPLETE: ST-ID-001 ACCEPT.**
3. **First-family human identities — COMPLETE: ST-ID-002 ACCEPT.**
4. **Initial provider-binding model — COMPLETE: ST-PB-001 ACCEPT.**
5. **Baseline policies — ACTIVE: ST-POL-001.**
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

## Active unit boundary — ST-POL-001

ST-POL-001 establishes the provider-neutral baseline Policy Intent and a deterministic Cloudflare DNS compilation plan, but does not apply Gateway policies yet.

Minimum baseline intent:

- malware BLOCK;
- phishing BLOCK;
- command-and-control / botnet BLOCK;
- adult content BLOCK;
- gambling BLOCK;
- SafeSearch FORCE;
- YouTube Restricted Mode FORCE.

Policy precedence remains owned by SETOK. Security / Threat Baseline cannot be weakened by Standard, Restricted, schedules, temporary overrides or Essential Services. Essential Services may survive ordinary parental modes but can never bypass threat blocking.

Current Cloudflare documentation supports DNS Block, Safe Search and YouTube Restricted actions and security/content category selectors. ST-POL-001 will discover provider capabilities read-only and compile provider-neutral intent to a plan without encoding Cloudflare numeric IDs into domain intent.

Because the Cloudflare account is shared and there are no enrolled Familia Ulate León device bindings yet, this Story MUST NOT create/update/enable/disable/reorder/delete Gateway rules. A future provider-mutation unit may apply the compiled baseline only after a safe family/device scope is proven.

HTTP inspection/root-certificate deployment and real-device anti-bypass enforcement remain deferred to their later validation units.

## Phase 1 exit condition

Phase 1 is complete only when the platform functions correctly without SETOK Family App and the project has validated enforcement, bypass resistance, identities, provider APIs, states/overlays and Standard vs Enhanced Protection.

## Phase 2

Phase 2 is the SETOK Family application / mini app and consumer experience. It remains intentionally deferred until the Phase 1 platform has been validated.

## Next governance action

Technical Director may issue explicit implementation authorization for ST-POL-001. Implementation remains contract/compilation/read-only provider discovery only; no Cloudflare Gateway mutation is authorized.

## Authority

Detailed scope, sequencing rationale, architecture and risks remain in `docs/ARCHITECTURE.md`. Completed Story/Work Order/evidence preserve execution traceability; this roadmap remains the planning authority.
