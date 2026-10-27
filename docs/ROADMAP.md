# SETOK Family — ROADMAP

## Governance status

Current focus: **Phase 1 — Infrastructure, Enforcement and Identity**.

This roadmap orders work; implementation authority is carried by the active Story/Work Order and Technical Director state.

Current AIDE execution state:

- active unit: `ST-DEV-001 — Establish first Android device enrollment and provider binding`
- Story: `docs/stories/ST-DEV-001.md`
- Work Order: `.ai/work-orders/ST-DEV-001.md`
- preflight: `PASS`
- Independent Check: `PASS WITH CONDITIONS`
- risk: `RED`
- Product Input Gate: `NOT REQUIRED`
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
7. **Android enrollment and device binding — ACTIVE: ST-DEV-001.**
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

Established the PO-approved provider-neutral policy semantics:

- `STANDARD`: baseline with no additional leisure restriction;
- `RESTRICTED`: blocks `social_media`, `gaming` and `entertainment_streaming`;
- `STUDY`: bounded temporary block of those three categories;
- `ALLOW_SOCIAL`: bounded temporary allow of social media over `RESTRICTED`/`STUDY` only;
- `PAUSE_ENTERTAINMENT`: bounded temporary block of the three leisure categories;
- `CLEAR_TEMPORARY`: clears temporary overlays and restores the persistent mode.

The Story proved baseline non-regression, deterministic composition, fixed-time expiry/restore, explicit overlay conflict resolution, Essential Services semantics and fail-closed behavior. It generated Cloudflare compilation plans only in `DESIRED / COMPILED / APPLY_BLOCKED`; no provider mutation occurred, no device subject/binding was created and no policy was claimed `APPLIED`.

Accepted candidate: `8e0121e2b45e39a759f2774a4427d72de5b9d155`.
Integration commit: `a3d7aff30ff4a1f8729d5ee59d9ea2f8b572f85b`.
Evidence: `docs/evidence/ST-POL-002/`.

Deferred enforcement findings carried forward:

- Cloudflare categories required for Gambling, Social Networks, Gaming, Video Streaming and Audio Streaming are premium-class and actual-plan entitlement must be proven before apply;
- Gateway first-match ordering and the refined SafeSearch/YouTube scoping must be validated on an enrolled test device before enforcement is accepted;
- safe family/device selector isolation remains mandatory because the Cloudflare account is shared.

## Active unit boundary — ST-DEV-001

ST-DEV-001 establishes the first real Android device identity and Cloudflare device-registration binding.

Target architecture:

- first-family Xiaomi Redmi Note 14 Pro;
- Google Family Link remains authority for screen time/apps;
- Cloudflare One Client remains network-enforcement provider;
- no ManageEngine/Android MDM;
- exactly one new SETOK device subject and, after successful enrollment, exactly one ACTIVE Cloudflare `device_enrollment` binding.

Manual enrollment must use a dedicated operational integration identity whose real value/credentials remain outside Git. That enrollment identity is not a SETOK family member, Child login or internal device identity.

Because the Cloudflare organization is shared, the only intended external mutation in this Story is the target device's supported manual enrollment/registration. Any need to change shared enrollment permissions, login methods, service tokens, device-profile selectors, `SETOK-FAMILY-MANAGED`, Default profile or Gateway policies is a hard STOP pending separate authorization.

Successful completion does **not** prove a safe Gateway selector. The required terminal state remains conceptually:

`DEVICE_ENROLLED / DEVICE_BOUND / SAFE_SELECTOR_NOT_YET_PROVEN`

Current Cloudflare documentation also indicates that administrator-supplied `unique_client_id` on Android is a managed-deployment capability and cannot be manually assigned; ST-DEV-001 therefore does not introduce MDM solely to create such a selector.

## Sequencing clarification

Policy **design/compilation** and provider **enforcement apply** are separate gates.

Android and iPad Standard enrollment create the real device identities/bindings needed to evaluate safe tenant/device scope. Only after those units may scoped Cloudflare enforcement be considered for provider mutation.

## Phase 1 exit condition

Phase 1 is complete only when the platform functions correctly without SETOK Family App and the project has validated enforcement, bypass resistance, identities, provider APIs, states/overlays and Standard vs Enhanced Protection.

## Phase 2

Phase 2 is the SETOK Family application / mini app and consumer experience. It remains intentionally deferred until the Phase 1 platform has been validated.

## Next governance action

Freeze the ST-DEV-001 Authorized Base, create `feature/st-dev-001` from that exact commit, verify branch lineage, and require explicit Technical Director implementation authorization. No physical enrollment/provider mutation is authorized before that GO.

## Authority

Detailed scope, sequencing rationale, architecture and risks remain in `docs/ARCHITECTURE.md`. Completed Story/Work Order/evidence preserve execution traceability; this roadmap remains the planning authority.
