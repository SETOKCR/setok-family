# ST-CF-002 — Establish Cloudflare device enrollment permissions

## Status

PREFLIGHT

## Goal

Establish the minimum Cloudflare Access configuration required to authorize SETOK Family device enrollment in the existing shared SETOK Zero Trust organization, while keeping the enrollment boundary narrowly scoped, reversible, and independent from Gateway enforcement policy.

## Trigger

ST-DEV-001 stopped correctly at Stage A because the shared Cloudflare account currently has:

- 0 Access applications;
- 0 Access policies;
- 0 service tokens;
- existing One-time PIN IdP;
- no device-enrollment permissions.

Manual Cloudflare One Agent enrollment therefore cannot proceed until a `warp` Access application and enrollment policy exist.

## Product / operational input

The Product Owner selected an existing SETOK IT administration mailbox as the enrollment identity. The real mailbox value MUST remain outside Git and versioned evidence.

Canonical versioned alias:

`family-enrollment-01`

Operational requirements:

- mailbox already exists;
- Product Owner can receive/read OTP messages;
- no new mailbox creation is part of this Story;
- no credential or email address is committed to Git.

## Architecture boundary

This Story creates a Cloudflare enrollment authorization resource, not a SETOK Family member identity.

The enrollment identity:

- is not a Child;
- is not an adult subject;
- is not the SETOK internal device identity;
- is not an Authentik family-domain principal;
- is only an operational identity permitted to authenticate device enrollment.

## Intended provider configuration

Create exactly one Cloudflare Access application for device enrollment:

- type: `warp`;
- SETOK-managed alias/name: `SETOK-FAMILY-DEVICE-ENROLLMENT`;
- shared Cloudflare account boundary remains unchanged;
- existing One-time PIN IdP remains the only login mechanism used;
- no service-token enrollment.

Create exactly one allow policy attached to that application:

- action/decision: `allow`;
- include: exact operational mailbox corresponding to versioned alias `family-enrollment-01`;
- no domain-wide rule;
- no `everyone` rule;
- no service token;
- no additional allow identities;
- no Gateway/device-profile dependency.

The actual mailbox value is supplied to the Development Agent through local secret/operational input only and must not be persisted to Git/evidence.

## Scope

### In scope

1. Re-run read-only discovery to confirm the precondition remains unchanged.
2. Obtain/use the minimum provider credential needed for Access Apps/Policies edit, stored outside Git.
3. Create one `warp` Access application.
4. Create one exact-mailbox allow policy using the existing One-time PIN login method.
5. Observe provider IDs of the created app/policy.
6. Version only sanitized managed-resource metadata necessary for ownership/reconciliation.
7. Add the created Access enrollment application as a managed Cloudflare resource in the provider-binding registry if schema/resource taxonomy requires it; evolve the schema minimally and provider-neutrally if needed.
8. Reconcile observed vs desired state deterministically.
9. Prove no Gateway, device profile, IdP/login-method, service-token, posture-rule, unrelated Access resource, or device state changed.
10. Document rollback: delete the single enrollment policy and app by observed IDs.
11. Produce evidence under `docs/evidence/ST-CF-002/`.

### Out of scope

- Android/iPad physical enrollment;
- creation of device subjects or device bindings;
- Gateway DNS/HTTP/Network policy mutation;
- changing `SETOK-FAMILY-MANAGED`;
- changing Default profile;
- changing device-profile selectors;
- adding/changing IdPs/login methods;
- service-token creation;
- Android MDM;
- safe-selector proof;
- policy enforcement apply;
- Phase 2 application/runtime.

## Lifecycle decision

`SETOK-FAMILY-DEVICE-ENROLLMENT` is intended to remain as governed SETOK Family infrastructure after ST-CF-002, not be deleted immediately after the first Android enrollment.

Rationale:

- Android enrollment resumes immediately afterward;
- iPad Standard enrollment follows in the ROADMAP;
- future re-enrollment/recovery needs a durable but tightly scoped authorization boundary;
- repeated create/delete cycles add unnecessary shared-account churn.

Rollback remains available and explicit, but normal completion leaves the managed enrollment app/policy active.

## Shared-account safety invariants

- exactly one new Access app of type `warp`;
- exactly one new allow policy;
- policy include resolves to exactly one operational mailbox;
- no existing Access app/policy is modified;
- no login method / IdP mutation;
- no service token mutation;
- no Gateway mutation;
- no device profile mutation;
- no device/profile selector mutation;
- no posture-rule mutation;
- no enrolled devices are created by this Story;
- actual mailbox value stays outside Git/evidence.

## Required provider credential boundary

The implementation may use a dedicated short-lived API token with only the minimum permissions needed to manage Access applications/policies plus read-only permissions needed for validation.

The token:

- must remain outside Git;
- should be stored locally using the existing secure local-secret pattern;
- must not be reused as a general-purpose project credential;
- should be revoked after the controlled provider mutation and evidence collection unless an explicit later governance decision retains it.

## Registry / ownership modeling

If versioned registry ownership is extended, the new Access enrollment app must be represented as a managed resource owned by SETOK Family inside the shared Cloudflare integration boundary.

Provider application/policy IDs remain external provider identifiers; they do not become SETOK internal identity.

No real email address may be persisted in the provider-binding registry.

## Risk

RED.

Reason:

- this Story mutates Cloudflare Access authorization in a shared provider account;
- the configured app governs eligibility for device enrollment;
- an overly broad rule could allow unrelated enrollment.

Blast radius is constrained by exact-mailbox allow and explicit pre/post fingerprints.

## Independent invariants / negative cases

Implementation must fail closed if any of the following is true:

- a `warp` app already exists and is not demonstrably the managed SETOK Family resource;
- a policy would include a domain or `everyone`;
- more than one email identity is required;
- a new IdP/login method is required;
- a service token is required;
- Gateway/device-profile mutation is required;
- the provider API cannot prove exact app/policy state after create;
- the mailbox must be written to Git/evidence;
- unrelated Access resources would be modified;
- existing provider fingerprints change unexpectedly.

## Acceptance criteria

- one managed `warp` Access application exists;
- one `allow` policy exists and permits only the operational alias `family-enrollment-01` at the provider via its real mailbox value;
- existing One-time PIN login remains unchanged;
- 0 service tokens remain unless they existed before (current observed count: 0);
- Gateway unchanged;
- Default and `SETOK-FAMILY-MANAGED` unchanged;
- posture rules unchanged;
- 0 devices/registrations created;
- provider IDs captured and reconciled;
- rollback documented and testable;
- no PII/secrets in Git/evidence;
- ST-DEV-001 may subsequently resume from a fresh Stage A.

## Product Input Gate

CLOSED.

Product Owner selected the existing SETOK IT-admin mailbox as the operational enrollment identity. The real value remains outside Git; versioned alias is `family-enrollment-01`.
