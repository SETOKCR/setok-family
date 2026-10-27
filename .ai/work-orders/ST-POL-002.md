# WORK ORDER ST-POL-002

## Identity

- **Project:** SETOK Family
- **Repository:** SETOKCR/setok-family
- **Story / Work Unit:** ST-POL-002
- **Authorized Base:** `a7d9844f00e24acb5bd4d4a2553dd88efa892859`
- **Implementation Branch:** `feature/st-pol-002`
- **Execution state:** CLOSED — ACCEPT
- **Implementation Authorization:** YES
- **Persistence:** PERSISTED

## AIDE execution context

- Framework: SETOK-AIDE v1.2.3
- Role: Development Agent
- Project binding: REQUIRED
- Story: `docs/stories/ST-POL-002.md`
- Architecture: `docs/ARCHITECTURE.md`
- Quality: `docs/QUALITY.md`
- Independent Check: `docs/development/ST-POL-002_INDEPENDENT_CHECK.md`

## Goal

Define and implement the provider-neutral contract for persistent `STANDARD` / `RESTRICTED` modes, temporary overlays, expiration/reversal semantics and deterministic composition, without provider mutation.

## Risk

**YELLOW — 6/10.**

No provider mutation was planned or performed. This unit freezes consumer-visible parental-control semantics and policy-composition rules that later enforcement will execute.

## Independent Check

**PASS WITH CONDITIONS** — all mandatory conditions satisfied by the accepted candidate.

## Product Input Gate

**CLOSED — APPROVED.**

The Product Owner explicitly approved the exact first-family semantics documented in `docs/stories/ST-POL-002.md`:

- `STANDARD` = ST-POL-001 baseline with no additional leisure restriction by default;
- `RESTRICTED` = baseline + social media BLOCK + gaming BLOCK + entertainment/streaming leisure BLOCK;
- `STUDY` = bounded temporary block of social/gaming/entertainment-streaming, preserving Essential Services and baseline;
- `ALLOW_SOCIAL` = bounded temporary allow of social media over `STUDY`/`RESTRICTED`, never weakening baseline/mandatory safety;
- `PAUSE_ENTERTAINMENT` = bounded temporary block of social/gaming/entertainment-streaming, preserving Essential Services and baseline;
- `CLEAR_TEMPORARY` = remove temporary overlays and return to persistent mode without altering baseline or recurring schedule definitions.

Approved normalized domain categories:

- `social_media`;
- `gaming`;
- `entertainment_streaming`.

## Architecture invariants

- ST-POL-001 Security / Threat Baseline remains non-overridable by ordinary modes or overlays.
- Mandatory Safety Restrictions remain non-overridable by ordinary modes or overlays.
- Essential Services may bypass ordinary leisure restrictions but never threat baseline.
- SETOK owns policy precedence.
- temporary changes are bounded, reversible and explainable;
- expiry restores the underlying persistent mode deterministically;
- provider IDs/expressions remain outside domain intent;
- no device scope is invented before enrollment;
- desired/compiled/observed states remain separate.

## Provider boundary

Cloudflare remained non-mutative in this Story.

No Gateway rule/profile mutation occurred and no policy was claimed `APPLIED`.

Accepted terminal policy state:

`DESIRED / COMPILED / APPLY_BLOCKED`

## Quality gates

- [x] Story defined.
- [x] Risk classified YELLOW 6/10.
- [x] Independent Check PASS WITH CONDITIONS.
- [x] Product Input Gate CLOSED.
- [x] Authorized Base frozen at `a7d9844f00e24acb5bd4d4a2553dd88efa892859`.
- [x] Implementation Branch created from exact Authorized Base.
- [x] Branch lineage verified by construction.
- [x] Implementation explicitly authorized by Product Owner / Technical Director GO.
- [x] Product semantics PASS.
- [x] Persistent modes 2/2 PASS.
- [x] Temporary overlays 4/4 PASS.
- [x] Baseline non-regression PASS.
- [x] Composition PASS and deterministic.
- [x] Expiration / restore PASS.
- [x] Conflict resolution PASS.
- [x] Essential Services interaction PASS.
- [x] Fail-closed tests PASS.
- [x] Provider mutation NO.
- [x] Device subjects created 0.
- [x] Device bindings created 0.
- [x] Policy claimed APPLIED NO.
- [x] Privacy/secret scan PASS.
- [x] Technical Director terminal review ACCEPT.

## Closure evidence

- Preflight architecture review: PASS
- Independent Check: PASS WITH CONDITIONS — satisfied
- Product Input Gate: CLOSED — explicit PO approval
- Authorized Base: `a7d9844f00e24acb5bd4d4a2553dd88efa892859`
- Implementation Branch: `feature/st-pol-002`
- Implementation Authorization commit: `c2b749b0e6efe26c4914265c836b0723bf604449`
- Accepted Candidate: `8e0121e2b45e39a759f2774a4427d72de5b9d155`
- Integration Commit: `a3d7aff30ff4a1f8729d5ee59d9ea2f8b572f85b`
- Technical Director Decision: `ACCEPT`
- Evidence: `docs/evidence/ST-POL-002/`
- Provider Mutation: `NO`
- Device Subjects / Bindings: `0 / 0`
- Policy APPLIED: `NO`

## Deferred apply gates

The compiled Cloudflare plan remains blocked until later work proves:

- enrolled Familia Ulate León device bindings;
- a safe selector isolated from unrelated SETOK traffic;
- explicit provider-mutation authorization plus rollback/blast-radius controls;
- actual-plan entitlement for required premium-class categories;
- real-device verification of Gateway ordering semantics.
