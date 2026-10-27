# ST-CF-002 — Independent Check

## Decision

**PASS WITH CONDITIONS**

## Scope reviewed

`ST-CF-002 — Establish Cloudflare device enrollment permissions`

This unit exists solely to satisfy the provider prerequisite discovered by ST-DEV-001 Stage A. It mutates Access authorization inside a shared Cloudflare account, so RED classification is appropriate.

## Architecture fit

PASS.

The proposal preserves the approved architecture:

- Cloudflare remains the network enforcement provider;
- device enrollment authorization is modeled separately from human/device SETOK identity;
- no Android MDM is introduced;
- no Gateway enforcement policy is applied;
- shared-account resources remain explicitly bounded;
- exact-mailbox enrollment is narrower than domain/everyone rules;
- One-time PIN remains the existing IdP.

## Mandatory conditions

1. **Exact identity only.** The allow policy must include exactly one mailbox corresponding to the versioned alias `family-enrollment-01`. No email domain, group, `everyone`, service token or catch-all is allowed.

2. **Real mailbox outside Git.** The actual mailbox value must not appear in Story/Work Order/registry/evidence/scripts committed to Git. It may be supplied only as local operational input/secret.

3. **One app / one policy cardinality.** Exactly one new Access application of type `warp` and exactly one new `allow` policy may be created.

4. **Idempotent ownership detection.** If a `warp` app already exists at execution time, the agent must not create another or modify it unless it can prove it is the SETOK Family managed resource created by this Story. Otherwise STOP.

5. **Existing IdP only.** One-time PIN may be referenced/used but not changed. Creating or altering IdPs/login methods is outside scope.

6. **No service token.** Service-token creation or use as enrollment authorization is forbidden.

7. **Gateway immutable.** Gateway DNS/HTTP/Network rules, lists and configuration must remain unchanged.

8. **Device profiles immutable.** Default and `SETOK-FAMILY-MANAGED` including match expressions and mode settings must remain unchanged.

9. **No device enrollment occurs.** ST-CF-002 creates authorization infrastructure only. Physical device/registration counts must remain unchanged.

10. **Posture rules immutable.** Existing posture configuration must not change.

11. **Provider IDs remain external.** Access app/policy IDs may be stored only as external provider identifiers associated with a managed resource/binding model; they must not become internal SETOK identity.

12. **Minimal schema evolution.** Any provider-binding registry/schema change must be backward-compatible and generic enough to represent managed provider authorization resources without embedding Cloudflare-specific domain semantics in SETOK identity.

13. **Short-lived write credential.** Use only a narrowly scoped credential needed for the mutation. Secret remains outside Git. Revocation after the operation is preferred and should be evidenced where feasible.

14. **Pre/post fingerprints mandatory.** Compare Access apps/policies plus Gateway, IdPs, service tokens, profiles, posture rules and device/registration counts before and after.

15. **Rollback exact.** Rollback must target only the created policy and app by observed provider IDs. No broad reset/delete behavior.

16. **Durable normal state.** Successful completion leaves the managed enrollment app/policy present for governed future Android/iPad enrollment. Rollback is available but not automatic post-success cleanup.

17. **No safe-selector claim.** This Story changes who may enroll; it does not prove Gateway traffic isolation.

## Independent risk assessment

- Reversibility: moderate/high — app/policy can be deleted by ID.
- Blast radius: high if selector broadens; constrained by exact-mailbox rule.
- Data/state: moderate — new shared provider authorization state.
- Security/authentication: high — enrollment eligibility is security-sensitive.
- Contract impact: moderate — new managed provider resource.

**Result: RED.**

## Product Input Gate

**CLOSED.**

The Product Owner selected an existing SETOK IT administration mailbox capable of receiving OTP. The real mailbox stays outside Git under alias `family-enrollment-01`.

## Required terminal evidence

- `PROJECT_SCOPE_OK`;
- exact Authorized Base lineage;
- pre-state confirms 0 Access apps/policies or otherwise controlled STOP;
- one new `warp` app;
- one exact-mailbox allow policy;
- One-time PIN unchanged;
- Gateway fingerprints unchanged;
- Default and managed profile fingerprints unchanged;
- service-token count unchanged;
- posture rules unchanged;
- device/registration counts unchanged;
- provider IDs captured;
- deterministic reconciliation;
- PII/secrets scan PASS;
- rollback documented;
- safe selector still NOT PROVEN.

## Independent Check outcome

**PASS WITH CONDITIONS.** No architecture change is required. All conditions above are mandatory Work Order constraints.
