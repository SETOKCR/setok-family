# ST-PB-001 — Independent Check

## Outcome

**PASS WITH CONDITIONS**

## Review objective

Challenge the proposed provider-binding registry against the frozen architecture before implementation, focusing on coupling, tenant isolation, lifecycle, privacy and future extensibility.

## Findings

### 1. Internal identity must remain provider-independent — PASS

The Story explicitly prohibits deriving SETOK IDs from Authentik or Cloudflare identifiers.

**Condition:** generated internal IDs must remain stable if a provider binding is replaced, retired or re-created.

### 2. Tenant isolation must be structural — PASS WITH CONDITION

The architecture requires tenant context on every operational entity.

**Condition:** schema validation must reject any binding without `tenant_id`; uniqueness constraints must include tenant scope where applicable.

### 3. Human/device/provider-resource categories must not collapse — PASS WITH CONDITION

The model must not represent a Cloudflare profile as a device or an Authentik user as a family/domain role.

**Condition:** binding/subject types must be explicit and validated; no polymorphic free-form type that bypasses invariants.

### 4. No fabricated device bindings — PASS

There is no real enrollment evidence yet.

**Condition:** the first registry contains zero device subjects and zero device bindings. Future enrollment Stories create those only after provider/device evidence exists.

### 5. Desired vs observed state separation — PASS WITH CONDITION

Provider observation is time-varying and must not be confused with configuration intent.

**Condition:** timestamps, health, observed labels and transient API fields belong in evidence/observed output, not desired registry state.

### 6. External identifiers and privacy — PASS WITH CONDITION

Opaque provider IDs are acceptable non-secret binding data. Real human PII is unnecessary because ST-ID-002 already established opaque aliases/UUID evidence.

**Condition:** no full names, emails, passwords, recovery URLs or tokens in registry/evidence.

### 7. Cloudflare shared-account boundary — PASS WITH CONDITION

The account is shared across SETOK surfaces. Binding the account/org/profile is useful, but it must not imply exclusive ownership of the whole account.

**Condition:** registry must model ownership/scope so SETOK Family owns/manages only its designated provider resource(s), not the shared account or Default profile.

### 8. Binding lifecycle — PASS WITH CONDITION

Future provider migration is a primary reason for this abstraction.

**Condition:** lifecycle supports at minimum `ACTIVE`, `RETIRED` and `ERROR`/`STALE` semantics, or an equivalent explicit model. Replacement must preserve the internal SETOK subject ID and allow historical binding traceability.

### 9. Cardinality — PASS WITH CONDITION

A subject may have multiple provider bindings over time and a device may eventually have multiple simultaneous provider bindings.

**Condition:** do not impose one-provider-binding-per-subject globally. Uniqueness should prevent duplicate active bindings for the same tenant/subject/provider/binding type/external identity while allowing multiple different provider types/resources.

### 10. Reconciliation must be read-only — PASS WITH CONDITION

This Story precedes policy and enrollment changes.

**Condition:** implementation must contain no provider mutation route. If current provider APIs require write-scoped credentials for read operations, use existing credentials only for read calls and do not broaden scope in this Story.

### 11. Authentik domain separation — PASS

Binding Authentik users to internal human subjects does not move family authorization into Authentik.

**Condition:** no Owner/Parent/Viewer/Guardian/Child authorization data is introduced in Authentik or inferred from binding records.

### 12. Future runtime storage — PASS

Phase 2 persistence technology is intentionally deferred.

**Condition:** this Story defines a portable contract/registry, not a SvelteKit/Drizzle runtime implementation or premature database migration.

## Mandatory conditions summary

1. Internal IDs remain stable and provider-independent.
2. `tenant_id` mandatory and mechanically validated.
3. Explicit subject/binding/resource types.
4. Zero device subjects/bindings in this Story.
5. Desired and observed state separated.
6. No real PII/secrets in Git/evidence.
7. Shared Cloudflare account is not claimed as exclusively owned by SETOK Family.
8. Explicit binding lifecycle and replacement semantics.
9. Cardinality supports multiple providers/bindings without duplicates.
10. Reconciliation is provider read-only.
11. No family authorization encoded in Authentik/bindings.
12. No Phase 2 runtime/database implementation.

## Independent Check decision

**PASS WITH CONDITIONS.** No architecture change is required. The Story may proceed to Authorized Base once these conditions are incorporated into the Work Order.
