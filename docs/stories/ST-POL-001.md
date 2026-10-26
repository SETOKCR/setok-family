# ST-POL-001 — Establish baseline policy contract and Cloudflare compilation plan

## Status

PRE-FLIGHT

## Purpose

Establish the provider-neutral baseline Policy Intent for SETOK Family and a deterministic Cloudflare Gateway compilation plan without applying provider policy changes yet.

The baseline is the minimum protection layer that remains conceptually active underneath Standard, Restricted, schedules and temporary overlays.

## Architecture basis

SETOK owns policy intent and precedence. Cloudflare is an enforcement provider, not the domain model.

Conceptual precedence relevant to this Story:

1. Security / Threat Baseline
2. Mandatory Safety Restrictions
3. Essential Services Availability
4. Emergency Parent Actions
5. Temporary Explicit Parent Override
6. Active Mode
7. Recurring Schedule
8. Default Family Policy

Essential Services may survive ordinary parental modes, but may never override the Security / Threat Baseline.

## Baseline intent — minimum contract

The versioned provider-neutral baseline must express at least:

- malware: BLOCK;
- phishing: BLOCK;
- command-and-control / botnet: BLOCK;
- adult content: BLOCK;
- gambling: BLOCK;
- SafeSearch: FORCE;
- YouTube Restricted Mode: FORCE.

Anti-bypass controls are not fully implemented by this Story. They remain subject to later real-device anti-bypass validation. The contract may reserve capabilities for them but must not claim them as verified.

## Cloudflare compilation boundary

Current Cloudflare Gateway documentation supports DNS policies with Block, Safe Search and YouTube Restricted actions and security/content categories. The adapter/plan must resolve provider categories by semantic/provider names or supported discovery rather than treating numeric Cloudflare category IDs as SETOK domain identifiers.

Initial compilation target is DNS Gateway policy semantics. HTTP inspection/AV policy is not required in this Story because it adds device certificate/decryption prerequisites and is deferred to later device/platform validation.

## Shared-account safety constraint

The Cloudflare Zero Trust account is shared by the wider SETOK platform. Familia Ulate León has no enrolled device subject/binding yet.

Therefore this Story MUST NOT create, update, enable, disable, reorder or delete Cloudflare Gateway rules. Global or insufficiently scoped rules could affect unrelated SETOK traffic.

Provider apply is deferred until a later Story can prove a safe family/device scope.

## Deliverables

- provider-neutral baseline policy schema/contract;
- versioned desired baseline for the first productive family tenant, referenced by opaque internal tenant ID;
- explicit immutable/high-priority baseline semantics;
- essential-services precedence invariant: essential services cannot bypass threat blocking;
- Cloudflare DNS compilation plan generated from provider-neutral intent;
- read-only discovery of current Cloudflare Gateway categories/capabilities needed by the plan;
- deterministic validation and negative tests;
- evidence under `docs/evidence/ST-POL-001/`;
- documented apply preconditions for a later provider-mutation Story.

## Required invariants

1. Every policy object is tenant-scoped.
2. SETOK policy IDs are independent from Cloudflare rule/category IDs.
3. Policy Intent uses SETOK semantics; provider syntax belongs only in compilation output/adapter data.
4. Baseline threat protections cannot be weakened by Standard, Restricted, schedules, temporary overrides or Essential Services.
5. Essential Services may bypass ordinary mode restrictions only; they never bypass malware/phishing/C2 security baseline.
6. Baseline is not a Device Profile and does not mutate `SETOK-FAMILY-MANAGED`.
7. No device subject/binding is invented in this Story.
8. Cloudflare numeric/category IDs discovered at runtime are observed/provider facts, not domain identifiers.
9. Desired state and observed provider capabilities remain separate.
10. No provider mutation is allowed.
11. No PII or secrets enter Git/evidence.
12. No baseline rule may be reported as APPLIED; this Story produces desired/compiled state only.

## Validation

- Project Scope = `PROJECT_SCOPE_OK`;
- baseline schema/contract validates;
- exactly one tenant-scoped baseline intent for the first productive family;
- minimum controls are present;
- precedence/invariant tests reject attempts to override threat baseline;
- essential-services negative test proves threat baseline remains dominant;
- Cloudflare capability/category discovery succeeds read-only;
- compilation produces deterministic DNS policy plan;
- provider-specific IDs are absent from domain intent and isolated to compiled/observed representation where necessary;
- repeat compilation is semantically identical;
- static and observed proof of no Cloudflare mutation;
- no device subjects/bindings;
- PII/secret scan clean.

## Out of scope

- applying Gateway policies;
- changing rule precedence in Cloudflare;
- Standard/Restricted definitions beyond proving they cannot weaken baseline;
- temporary overlays;
- schedules;
- device enrollment;
- device identity or posture selectors;
- HTTP inspection/root certificate deployment;
- full anti-bypass enforcement/testing;
- Essential Services catalog for a specific family;
- runtime database or Phase 2 application work.

## Risk

YELLOW — architecture/security-critical policy contract, but no provider mutation.

Ordinary score: 5/10.

- reversibility: 1;
- blast radius: 0 (provider read-only);
- data/state: 1;
- security impact: 2;
- contract/architecture impact: 1.

## Stop conditions

- provider mutation is required;
- safe family scope is assumed without enrolled/bound devices;
- a global Cloudflare rule would be created or changed;
- provider IDs become SETOK domain policy IDs;
- Essential Services can bypass threat baseline;
- PII/secrets are required in Git/evidence;
- implementation claims anti-bypass or HTTP inspection as verified without device evidence;
- unexpected Auto-RED surface.
