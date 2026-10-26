# ST-PB-001 — Establish initial provider-binding registry

## Status

PRE-FLIGHT

## Goal

Establish the first provider-binding registry for SETOK Family so internal domain identities remain stable while Authentik, Cloudflare and future providers are treated as replaceable external integrations.

This Story defines and validates the binding contract against the productive Familia Ulate León foundation already established by ST-CF-001, ST-ID-001 and ST-ID-002. It does not enroll devices and does not mutate provider configuration.

## Product / architecture intent

- `Familia Ulate León` is the first productive SETOK Family tenant.
- Every operational binding is tenant-scoped.
- SETOK internal IDs are authoritative references; provider IDs are replaceable bindings.
- Human identity and device identity remain separate.
- Authentik authenticates humans; it does not model family membership or SETOK authorization.
- Cloudflare is an enforcement provider; its account/profile identifiers are not SETOK domain identities.
- Desired binding configuration is versioned; observed provider state is captured separately as evidence.
- Provider reconciliation is read-only in this Story.

## In scope

1. Define a versioned, provider-neutral binding schema/registry supporting at minimum:
   - `tenant_id` / internal family reference;
   - internal subject reference and subject type;
   - provider key;
   - binding type;
   - external identifier(s);
   - status/lifecycle;
   - metadata constrained to non-secret provider facts;
   - desired vs observed separation.
2. Establish the first internal tenant reference for Familia Ulate León.
3. Establish opaque internal references for the two adult human identities without persisting real PII in the registry/evidence.
4. Bind those internal human references to the existing Authentik users created by ST-ID-002 using provider identifiers already observable in non-secret evidence.
5. Register the existing Cloudflare integration boundary and managed profile from ST-CF-001 as provider/integration bindings, without treating the profile as a device.
6. Provide a read-only PowerShell reconciliation/validation script that verifies the registry against current Authentik and Cloudflare observed state using existing local provider credentials where required.
7. Demonstrate deterministic/idempotent validation and tenant isolation constraints.
8. Document future extension for device bindings without creating device records in this Story.

## Out of scope

- Device enrollment or device identity creation.
- Child domain object or child login creation.
- Provider configuration mutation.
- Narrowing/changing the current Cloudflare mobile selector.
- Baseline policies or policy compilation.
- Owner/Parent/Viewer authorization persistence.
- Guardian↔Child authorization.
- OIDC/federation/Cloudflare Access.
- MDM/ManageEngine integration.
- SETOK Family App/runtime database implementation.
- Generic provider SDK/framework.

## Acceptance criteria

- [ ] Project Scope Handshake = `PROJECT_SCOPE_OK`.
- [ ] Versioned binding registry/schema is provider-neutral and tenant-scoped.
- [ ] Internal SETOK IDs do not derive from Authentik PK/UUID, email address, Cloudflare account ID or Cloudflare policy ID.
- [ ] Familia Ulate León has one stable internal tenant identifier.
- [ ] Exactly two adult internal subject references exist for the current human identities; no real names/emails are persisted in the binding registry or evidence.
- [ ] Each adult subject has one Authentik binding that reconciles to an existing regular non-admin user.
- [ ] Cloudflare account/org/profile facts are represented as integration/resource bindings, not human/device identity.
- [ ] Existing Cloudflare managed profile `SETOK-FAMILY-MANAGED` reconciles to the observed provider resource without mutation.
- [ ] No device binding is fabricated before enrollment.
- [ ] No child identity or authorization role is introduced.
- [ ] Observed state is separate from desired/versioned state.
- [ ] Provider secrets/tokens are absent from Git/evidence.
- [ ] Validation is read-only and repeatable with identical semantic result.
- [ ] A binding can be marked/replaced without changing the internal SETOK subject identifier.
- [ ] Tenant-scope invariant is mechanically validated.
- [ ] Evidence is sufficient for Technical Director review.

## Risk

YELLOW — ordinary score 4/10.

- Reversibility: 0
- Blast Radius: 1
- Data/State: 1
- Security: 1
- Contracts: 1

Reason: no provider mutation occurs, but this Story establishes a cross-provider identity/binding contract that future enrollment and policy work will depend on.

## Stop conditions

- Provider mutation becomes necessary.
- Real PII or secrets must be committed to Git/evidence.
- The model requires provider IDs to become SETOK primary/domain IDs.
- Family authorization must be modeled inside Authentik or Cloudflare.
- Device records must be invented before enrollment evidence exists.
- Tenant isolation cannot be enforced mechanically.
- Existing provider state materially contradicts the frozen architecture.

## Dependencies

- ST-CF-001 ACCEPT.
- ST-ID-001 ACCEPT.
- ST-ID-002 ACCEPT.
- Architecture v1.4 sections 2, 5, 6, 7 and 8.
- QUALITY provider/automation evidence rules.
