# WORK ORDER ST-POL-002

## Identity

- **Project:** SETOK Family
- **Repository:** SETOKCR/setok-family
- **Story / Work Unit:** ST-POL-002
- **Authorized Base:** `PENDING`
- **Implementation Branch:** `PENDING`
- **Execution state:** PRODUCT_INPUT_GATE
- **Implementation Authorization:** NO
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

No provider mutation is planned, but this unit freezes consumer-visible parental-control semantics and policy-composition rules that later enforcement will execute.

## Independent Check

**PASS WITH CONDITIONS** — `docs/development/ST-POL-002_INDEPENDENT_CHECK.md`.

All mandatory Independent Check conditions become part of this Work Order.

## Product Input Gate

**OPEN.**

PO approval is required for the exact semantics of:

- `STANDARD`;
- `RESTRICTED`;
- `STUDY`;
- `ALLOW_SOCIAL`;
- `PAUSE_ENTERTAINMENT`;
- `CLEAR_TEMPORARY`.

Recommended semantics are documented in `docs/stories/ST-POL-002.md` and must be explicitly approved or amended before Authorized Base freeze.

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

Cloudflare remains non-mutative in this Story.

Forbidden:

- create/update/delete/reorder Gateway rules;
- mutate `SETOK-FAMILY-MANAGED`;
- alter Default profile;
- claim policy `APPLIED`;
- assume tenant/device selector.

Allowed terminal policy state:

`DESIRED / COMPILED / APPLY_BLOCKED`

## Expected implementation deliverables after gate closure

- provider-neutral mode/overlay schema;
- approved tenant-scoped desired mode configuration;
- deterministic composition engine/script for Story validation;
- Effective Policy Decision representation with reason/expiry metadata;
- Cloudflare compilation-plan extension isolated from domain intent;
- negative and precedence tests;
- expiry/restore tests;
- Essential Services interaction tests;
- no-mutation proof;
- evidence under `docs/evidence/ST-POL-002/`.

## Required validation after implementation

- `PROJECT_SCOPE_OK`;
- exact Authorized Base lineage;
- Product Input semantics exactly represented;
- schema PASS;
- baseline non-regression PASS;
- persistent mode composition PASS;
- overlay composition PASS;
- expiration/restore PASS;
- conflict ordering deterministic PASS;
- Essential Services interaction PASS;
- fail-closed negative tests PASS;
- provider-neutrality PASS;
- deterministic compilation PASS;
- zero Cloudflare mutation;
- zero device subjects/bindings;
- no PII/secrets;
- no policy claimed APPLIED.

## Stop conditions

- Product Input Gate not closed;
- repository scope mismatch;
- Authorized Base/branch lineage mismatch;
- mode/overlay weakens Security / Threat Baseline or Mandatory Safety Restrictions;
- Essential Services bypasses threat baseline;
- unbounded temporary overlay;
- provider mutation required or attempted;
- device scope invented;
- provider-specific IDs become domain intent;
- unexpected Auto-RED surface.

## Quality gates

- [x] Story defined.
- [x] Risk classified YELLOW 6/10.
- [x] Independent Check PASS WITH CONDITIONS.
- [ ] Product Input Gate CLOSED.
- [ ] Authorized Base frozen.
- [ ] Implementation Branch created from exact Authorized Base.
- [ ] Branch lineage verified.
- [ ] Implementation explicitly authorized.
- [ ] Required implementation gates PASS.
- [ ] Technical Director terminal review complete.

## Closure evidence

- Preflight architecture review: PASS
- Independent Check: PASS WITH CONDITIONS
- Product Input Gate: OPEN
- Authorized Base: PENDING
- Implementation Authorization: NO
