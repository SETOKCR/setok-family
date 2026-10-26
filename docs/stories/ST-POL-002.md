# ST-POL-002 — Establish Standard / Restricted / temporary overlay policy contract

## Status

PREFLIGHT — PRODUCT INPUT APPROVED

## Goal

Define the provider-neutral contract for persistent family modes `STANDARD` and `RESTRICTED`, temporary overlays, expiration/reversal semantics and deterministic policy composition for Familia Ulate León, without applying or mutating Cloudflare policies.

## Architectural basis

This Story implements the frozen architecture concepts:

- persistent parent-visible modes: `STANDARD` and `RESTRICTED`;
- temporary overlays are not persistent profiles;
- SETOK owns policy precedence before provider compilation;
- Security / Threat Baseline and Mandatory Safety Restrictions cannot be weakened by ordinary modes, schedules or overlays;
- Essential Services survive ordinary parental restrictions but never bypass threat blocking;
- everyday changes are reversible and temporary changes expire automatically;
- desired, compiled and observed/provider state remain separate;
- child-first scope is the domain default, but no child/device entity is invented in this Story.

## Scope

### In scope

- provider-neutral mode schema/contract;
- persistent mode state machine: `STANDARD | RESTRICTED`;
- temporary overlay contract;
- overlay expiration and explicit clear/restore semantics;
- deterministic composition into an Effective Policy Decision;
- precedence tests against the accepted ST-POL-001 baseline;
- compatibility with future recurring schedules without implementing schedule runtime;
- Essential Services interaction rules;
- Cloudflare compilation semantics/plan representation only;
- fail-closed validation;
- no-provider-mutation proof;
- evidence under `docs/evidence/ST-POL-002/`.

### Out of scope

- Cloudflare Gateway CREATE/PATCH/PUT/DELETE;
- real enforcement apply;
- device enrollment or device bindings;
- Android/iPad runtime validation;
- recurring schedule provider configuration;
- Essential Services catalog population;
- Command / Execution runtime;
- Phase 2 UI/application/database;
- full Policy Precedence implementation beyond the contract needed for this Story.

## Product Input Gate

**CLOSED — APPROVED by Product Owner.**

The following first-family semantics are authoritative for this Story.

### Approved first-family semantics

`STANDARD`
- ST-POL-001 baseline remains active;
- no additional leisure-category restriction by default;
- ordinary Internet remains available subject to baseline and Essential Services rules.

`RESTRICTED`
- ST-POL-001 baseline remains active;
- social media = BLOCK;
- gaming = BLOCK;
- entertainment/streaming leisure = BLOCK;
- Essential Services remain available unless blocked by Security / Threat Baseline.

Temporary overlays:

1. `STUDY`
   - blocks social media, gaming and entertainment/streaming leisure for a bounded duration;
   - preserves Essential Services and baseline;
   - expires automatically back to the persistent mode.

2. `ALLOW_SOCIAL`
   - temporarily allows social media for a bounded duration;
   - may override `STUDY`/`RESTRICTED` social-media restriction;
   - can never weaken Security / Threat Baseline or Mandatory Safety Restrictions.

3. `PAUSE_ENTERTAINMENT`
   - blocks social media, gaming and entertainment/streaming leisure for a bounded duration;
   - preserves Essential Services and baseline.

4. `CLEAR_TEMPORARY`
   - removes temporary overlays and returns immediately to the persistent mode;
   - does not alter baseline or recurring schedule definitions.

## Composition invariants

Conceptual precedence relevant to this Story:

1. Security / Threat Baseline
2. Mandatory Safety Restrictions
3. Essential Services Availability
4. Emergency Parent Actions (contract boundary only)
5. Temporary Explicit Parent Override
6. Active Mode
7. Recurring Schedule (contract boundary only)
8. Default Family Policy

Required invariants:

- `STANDARD` and `RESTRICTED` never disable ST-POL-001 baseline controls;
- no overlay can allow malware/phishing/C2 or remove adult/gambling/SafeSearch/YouTube baseline requirements;
- Essential Services can bypass ordinary mode/overlay leisure blocks but never threat baseline;
- temporary overlays always have bounded lifetime unless they are the explicit `CLEAR_TEMPORARY` action;
- expired overlay semantics are deterministic and return to the underlying persistent state;
- the same inputs produce the same Effective Policy Decision and compiled plan;
- conflicting overlays resolve by explicit precedence/time semantics, never provider rule order accident;
- provider IDs and provider-specific expressions stay outside domain intent.

## Approved normalized categories

The domain uses provider-neutral functional categories:

- `social_media`;
- `gaming`;
- `entertainment_streaming`.

Provider/category IDs are resolved only by adapters.

## Required negative cases

- mode attempts to disable threat baseline → FAIL;
- overlay attempts to disable mandatory safety restriction → FAIL;
- Essential Service attempts to bypass malware/phishing/C2 → FAIL;
- unbounded temporary overlay → FAIL;
- unknown overlay type → FAIL;
- provider ID in domain mode/overlay intent → FAIL;
- conflicting overlays without deterministic winner → FAIL;
- invented device/family selector → FAIL;
- policy marked APPLIED without provider execution evidence → FAIL.

## Apply boundary

Any compiled Cloudflare plan from this Story must remain conceptually:

`DESIRED / COMPILED / APPLY_BLOCKED`

until later enrollment creates real device bindings and the scoped enforcement gate proves selector isolation, entitlement, rollback and blast radius.

## Acceptance criteria

- Product Input Gate CLOSED by explicit PO decision;
- schema and contract PASS;
- `STANDARD` and `RESTRICTED` semantics versioned exactly as approved;
- approved temporary overlays versioned exactly as approved;
- composition deterministic;
- precedence/invariant tests PASS;
- expiration/restore tests PASS;
- Essential Services interaction tests PASS;
- fail-closed tests PASS;
- zero Cloudflare mutation;
- zero device subjects/bindings created;
- no PII/secrets in Git/evidence;
- no policy claimed APPLIED.
