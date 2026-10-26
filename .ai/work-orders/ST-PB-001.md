# WORK ORDER ST-PB-001

## Identity

- **Project:** SETOK Family
- **Repository:** SETOKCR/setok-family
- **Story / Work Unit:** ST-PB-001
- **Authorized Base:** PENDING
- **Implementation Branch:** `feature/st-pb-001`
- **Execution state:** PREFLIGHT
- **Implementation Authorization:** NO
- **Persistence:** PERSISTED

## AIDE execution context

- Framework: SETOK-AIDE v1.2.3
- Role: Development Agent
- Project binding: REQUIRED
- Story: `docs/stories/ST-PB-001.md`
- Architecture: `docs/ARCHITECTURE.md`
- Quality: `docs/QUALITY.md`

## Goal

Implement a provider-neutral, tenant-scoped binding registry and read-only reconciliation for the current Familia Ulate León Authentik and Cloudflare foundations.

## Binding invariants

1. SETOK internal identifiers are generated independently from provider identifiers.
2. Every binding includes an internal `tenant_id`.
3. Human subjects, devices, provider integrations and provider resources are distinct subject/resource categories.
4. Authentik user identifiers are external bindings only.
5. Cloudflare account/org/profile identifiers are integration/resource bindings only; the managed profile is not a device.
6. Desired/versioned binding state and observed/provider state remain separate.
7. Provider secrets never enter Git/evidence.
8. A provider binding may be replaced/retired without changing the SETOK internal subject ID.
9. No device binding exists before device enrollment.
10. No domain authorization roles/relationships are encoded in provider bindings.

## Required deliverables

- provider-binding schema/contract under an appropriate `domain/` or `infra/bindings/` project path;
- non-secret desired binding registry for the first productive family;
- exactly two opaque adult internal subject references with Authentik bindings;
- Cloudflare integration/resource binding for the existing shared account/org and `SETOK-FAMILY-MANAGED` profile;
- story-specific PowerShell read-only reconciliation/validation script;
- non-secret evidence under `docs/evidence/ST-PB-001/`;
- rollback/remediation guidance for versioned registry errors (provider state itself is not changed).

## Provider facts allowed in desired state

Non-secret stable external identifiers already established by accepted evidence may be stored where needed for reconciliation, including Authentik opaque user UUIDs/PK references and Cloudflare account/profile identifiers. Do not persist real names/emails, passwords, tokens, recovery URLs or other credentials.

## Required validation

- Project Scope = `PROJECT_SCOPE_OK`;
- branch lineage from exact Authorized Base;
- schema validation;
- tenant-scope validation;
- unique internal ID validation;
- exactly two human subject bindings;
- Authentik read-only reconciliation: each target resolves to one active `internal`, non-superuser user with no SETOK authorization role implied;
- Cloudflare read-only reconciliation: account/org/profile facts match ST-CF-001/current provider observation;
- profile `SETOK-FAMILY-MANAGED` exists exactly once and is not Default;
- no provider mutation calls in execution path;
- no device records/bindings;
- no PII/secrets in versioned files/evidence;
- repeat reconciliation yields same semantic result;
- replacement/lifecycle semantics documented and testable at schema level.

## Risk

YELLOW — 4/10. No provider mutation; architecture-critical binding contract.

## Independent Check

PENDING.

## Stop conditions

- scope mismatch or Authorized Base mismatch;
- provider mutation required;
- real PII/secrets required in Git/evidence;
- provider ID becomes internal SETOK identity;
- family authorization represented in provider constructs;
- device identity invented before enrollment;
- tenant isolation not mechanically enforceable;
- provider state contradicts frozen architecture materially;
- unexpected Auto-RED surface.

## Closure evidence

PENDING.
