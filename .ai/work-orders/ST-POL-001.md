# WORK ORDER ST-POL-001

## Identity

- **Project:** SETOK Family
- **Repository:** SETOKCR/setok-family
- **Story / Work Unit:** ST-POL-001
- **Authorized Base:** `df0a9dd9968c44428ab69e9e19c91fc2f164809e`
- **Implementation Branch:** `feature/st-pol-001`
- **Execution state:** IMPLEMENTATION_DONE
- **Implementation Authorization:** YES
- **Persistence:** PERSISTED

## AIDE execution context

- Framework: SETOK-AIDE v1.2.3
- Role: Development Agent
- Project binding: REQUIRED
- Story: `docs/stories/ST-POL-001.md`
- Architecture: `docs/ARCHITECTURE.md`
- Quality: `docs/QUALITY.md`
- Independent Check: `docs/development/ST-POL-001_INDEPENDENT_CHECK.md`

## Goal

Implement the provider-neutral baseline Policy Intent contract for the first productive family tenant and a deterministic Cloudflare DNS compilation plan, with read-only provider discovery and zero provider mutation.

## Required baseline intent

- malware = BLOCK
- phishing = BLOCK
- command-and-control / botnet = BLOCK
- adult content = BLOCK
- gambling = BLOCK
- SafeSearch = FORCE
- YouTube Restricted Mode = FORCE

## Precedence invariants

- Security / Threat Baseline has highest functional precedence in this Story.
- Mandatory safety restrictions cannot be weakened by ordinary modes.
- Essential Services cannot bypass threat baseline.
- Temporary overrides, Active Mode and recurring schedules cannot disable threat baseline.

## Shared-account constraint

Cloudflare is a shared SETOK platform boundary and Familia Ulate León has no enrolled device binding yet. Therefore no Gateway rule may be created, edited, enabled, disabled, reordered or deleted in this Work Order.

## Required deliverables

- baseline policy schema/contract;
- versioned tenant-scoped desired baseline intent;
- Cloudflare DNS compiler/plan representation isolated from domain intent;
- read-only discovery of provider categories/actions/capabilities needed for compilation;
- deterministic validation + negative cases;
- evidence under `docs/evidence/ST-POL-001/`;
- apply-precondition documentation for a future provider-mutation Story.

## Required validation

- `PROJECT_SCOPE_OK`;
- exact Authorized Base lineage;
- schema/contract PASS;
- exactly one tenant-scoped baseline intent;
- all mandatory baseline controls present;
- no provider IDs in domain intent;
- threat baseline cannot be overridden by modes/overrides/schedules/Essential Services;
- unresolved mandatory capability/category mapping fails closed;
- Cloudflare discovery is read-only;
- deterministic compilation result across repeated runs;
- no provider mutation verbs/calls;
- no mutation to `SETOK-FAMILY-MANAGED`;
- zero device subjects/bindings;
- desired/compiled/observed state separated;
- no PII/secrets in Git/evidence;
- no claim that anti-bypass or HTTP inspection is verified/applied.

## Risk

YELLOW — 5/10. Architecture/security-critical policy contract, provider read-only.

## Independent Check

**PASS WITH CONDITIONS** — `docs/development/ST-POL-001_INDEPENDENT_CHECK.md`.

All mandatory Independent Check conditions are part of this Work Order.

## Product Input Gate

NOT REQUIRED. The frozen architecture already defines the minimum baseline and precedence semantics for this unit.

## Stop conditions

- repository scope mismatch;
- Authorized Base/branch lineage mismatch;
- Cloudflare mutation required or attempted;
- global/unscoped Gateway rule creation/change;
- safe family/device scope assumed without enrollment evidence;
- provider ID becomes a SETOK domain policy ID;
- any mandatory baseline control is silently dropped due to provider mapping failure;
- Essential Services can bypass malware/phishing/C2 baseline;
- PII/secrets required in Git/evidence;
- device subject/binding invented;
- HTTP inspection/root certificate or anti-bypass is claimed complete without device evidence;
- unexpected Auto-RED surface.

## Quality gates

- [x] Story defined.
- [x] Risk classified YELLOW 5/10.
- [x] Independent Check PASS WITH CONDITIONS.
- [x] Product Input Gate NOT REQUIRED.
- [x] Authorized Base frozen at `df0a9dd9968c44428ab69e9e19c91fc2f164809e`.
- [x] Branch lineage verified by construction from exact Authorized Base.
- [x] Implementation explicitly authorized by Product Owner / Technical Director GO.
- [x] Baseline contract/schema PASS.
- [x] Precedence/invariant negative tests PASS.
- [x] Cloudflare read-only discovery PASS.
- [x] Deterministic compilation PASS.
- [x] No-mutation proof PASS.
- [x] Privacy/secret scan PASS.
- [x] Evidence sufficient for Technical Director review.

## Closure evidence

- Preflight: PASS
- Independent Check: PASS WITH CONDITIONS
- Product Input Gate: NOT REQUIRED
- Authorized Base: `df0a9dd9968c44428ab69e9e19c91fc2f164809e`
- Implementation Branch: `feature/st-pol-001`
- Implementation Authorization: YES
- Accepted Candidate: `fb3ef4f429c797e1f658d65e2dc80ea305df64d6`
- Integration Commit: `019dc396cd4f6f0fc3f77b5caa9073d7385c41f7`
- Technical Director Decision: `ACCEPT`
- Baseline Controls: 7/7 defined and compiled; none claimed APPLIED.
- Provider Mutation: NO.
- Apply Status: BLOCKED pending enrolled device binding, proven safe selector, separate provider-mutation authorization, and verification of the premium-class Gambling entitlement.
- Evidence: `docs/evidence/ST-POL-001/`.
