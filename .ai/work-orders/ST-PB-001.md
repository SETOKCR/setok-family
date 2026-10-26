# WORK ORDER ST-PB-001

## Identity

- **Project:** SETOK Family
- **Repository:** SETOKCR/setok-family
- **Story / Work Unit:** ST-PB-001
- **Authorized Base:** PENDING
- **Implementation Branch:** `feature/st-pb-001`
- **Execution state:** READY_FOR_BASE
- **Implementation Authorization:** NO
- **Persistence:** PERSISTED

## AIDE execution context

- Framework: SETOK-AIDE v1.2.3
- Role: Development Agent
- Project binding: REQUIRED
- Story: `docs/stories/ST-PB-001.md`
- Architecture: `docs/ARCHITECTURE.md`
- Quality: `docs/QUALITY.md`
- Independent Check: `docs/development/ST-PB-001_INDEPENDENT_CHECK.md`

## Goal

Implement a provider-neutral, tenant-scoped binding registry and read-only reconciliation for the current Familia Ulate León Authentik and Cloudflare foundations.

## Binding invariants

1. SETOK internal identifiers are generated independently from provider identifiers and remain stable through provider replacement/retirement.
2. Every binding includes an internal `tenant_id`; schema validation rejects missing tenant scope.
3. Human subjects, devices, provider integrations and provider resources use explicit validated types and are not interchangeable.
4. Authentik user identifiers are external bindings only.
5. Cloudflare account/org/profile identifiers are integration/resource bindings only; the managed profile is not a device.
6. Desired/versioned binding state and observed/provider state remain separate; transient provider facts belong only in evidence/observed output.
7. Provider secrets and real human PII never enter Git/evidence.
8. A provider binding may be replaced/retired without changing the SETOK internal subject ID; historical traceability is preserved.
9. This Story contains zero device subjects and zero device bindings; device records require later enrollment evidence.
10. No domain authorization roles/relationships are encoded in provider bindings or Authentik.
11. The shared Cloudflare account is modeled as an integration boundary, not as exclusively owned by SETOK Family; ownership applies only to designated SETOK Family resources.
12. Binding cardinality supports multiple providers/bindings while preventing duplicate active bindings for the same tenant/subject/provider/binding-type/external identity.

## Required deliverables

- provider-binding schema/contract under an appropriate `domain/` or `infra/bindings/` project path;
- non-secret desired binding registry for the first productive family;
- one stable internal tenant ID for Familia Ulate León;
- exactly two opaque adult internal subject references with Authentik bindings;
- Cloudflare integration/resource binding for the existing shared account/org and `SETOK-FAMILY-MANAGED` profile;
- explicit lifecycle model supporting at least active, retired and error/stale-equivalent states;
- story-specific PowerShell read-only reconciliation/validation script;
- non-secret evidence under `docs/evidence/ST-PB-001/`;
- rollback/remediation guidance for versioned registry errors (provider state itself is not changed).

## Provider facts allowed in desired state

Non-secret stable external identifiers already established by accepted evidence may be stored where needed for reconciliation, including Authentik opaque user UUIDs/PK references and Cloudflare account/profile identifiers. Do not persist real names/emails, passwords, tokens, recovery URLs or other credentials.

## Required validation

- Project Scope = `PROJECT_SCOPE_OK`;
- branch lineage from exact Authorized Base;
- schema validation;
- mandatory tenant-scope validation;
- unique internal ID validation;
- explicit subject/resource/binding type validation;
- zero device subjects/bindings;
- exactly two human subject bindings;
- Authentik read-only reconciliation: each target resolves to one active `internal`, non-superuser user with no SETOK authorization role implied;
- Cloudflare read-only reconciliation: account/org/profile facts match ST-CF-001/current provider observation;
- profile `SETOK-FAMILY-MANAGED` exists exactly once and is not Default;
- shared Cloudflare account is not claimed as exclusively owned by SETOK Family;
- no provider mutation calls in execution path;
- no PII/secrets in versioned files/evidence;
- repeat reconciliation yields same semantic result;
- replacement/lifecycle semantics validated at contract/schema level;
- cardinality/duplicate-active-binding invariants validated;
- no Phase 2 runtime/database implementation.

## Risk

YELLOW — 4/10. No provider mutation; architecture-critical binding contract.

## Independent Check

**PASS WITH CONDITIONS** — `docs/development/ST-PB-001_INDEPENDENT_CHECK.md`.

All mandatory conditions are incorporated into this Work Order.

## Stop conditions

- scope mismatch or Authorized Base mismatch;
- provider mutation required;
- real PII/secrets required in Git/evidence;
- provider ID becomes internal SETOK identity;
- family authorization represented in provider constructs;
- device identity invented before enrollment;
- tenant isolation not mechanically enforceable;
- shared Cloudflare account must be treated as exclusively owned by SETOK Family;
- provider state contradicts frozen architecture materially;
- implementation requires Phase 2 runtime/database work;
- unexpected Auto-RED surface.

## Quality gates

- [x] Story defined.
- [x] Risk classified YELLOW 4/10.
- [x] Independent Check PASS WITH CONDITIONS.
- [x] Independent Check conditions incorporated.
- [ ] Authorized Base frozen.
- [ ] Branch lineage verified.
- [ ] Implementation explicitly authorized.
- [ ] Schema/tenant/cardinality checks PASS.
- [ ] Authentik reconciliation PASS.
- [ ] Cloudflare reconciliation PASS.
- [ ] Read-only/no-mutation proof PASS.
- [ ] Privacy/secret scan PASS.
- [ ] Evidence sufficient for Technical Director review.

## Closure evidence

PENDING.
