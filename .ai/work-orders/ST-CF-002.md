# WORK ORDER ST-CF-002

## Identity

- **Project:** SETOK Family
- **Repository:** SETOKCR/setok-family
- **Story / Work Unit:** ST-CF-002
- **Authorized Base:** `0e32888cb8d78c488cbe4a231e7767a38ed9853b`
- **Implementation Branch:** `feature/st-cf-002`
- **Execution state:** CLOSED
- **Implementation Authorization:** YES — consumed
- **Persistence:** PERSISTED

## Goal

Establish the minimum Cloudflare device-enrollment authorization for SETOK Family in the shared SETOK Cloudflare account without changing Gateway, device profiles, IdPs, service tokens, posture rules or devices.

## Risk

RED.

## Governance result

- Preflight: PASS
- Independent Check: PASS WITH CONDITIONS
- Product Input Gate: CLOSED
- Project Scope: PROJECT_SCOPE_OK
- Technical Director terminal decision: **ACCEPT**

## Accepted implementation

- Candidate: `678aaff9722af68238dec3ea5c57eeb84c1e7735`
- Integration commit: `14f38ceb2eb043e62740de6bbe2987014f7824b3`
- Evidence: `docs/evidence/ST-CF-002/`

## Provider state established

Exactly one Cloudflare Access application of type `warp` exists for SETOK Family enrollment. Cloudflare provider behavior forces its display name to `Warp Login App`; ownership is therefore bound by provider IDs, not by provider display name.

Exactly one attached Access policy exists:

- decision: `allow`;
- include cardinality: 1;
- include kind: exact email identity;
- versioned identity alias: `family-enrollment-01`;
- existing One-time PIN IdP only;
- no require/exclude clauses;
- no domain/everyone/group/service-token expansion.

Managed provider IDs:

- Access app: `51a1308a-c003-465d-8bf6-b34ee6abf659`
- Access policy: `c991f7f4-7745-4f7f-afc6-3b868cdfca7e`

The real mailbox remains operational input outside ST-CF-002 versioned state.

## Registry ownership

ST-CF-002 added one provider-neutral `enrollment_authorization` resource and one `managed_resource` binding. Cloudflare IDs remain external identifiers. Provider-binding schema evolution was backward compatible and ST-PB-001 validation remained PASS.

## Blast-radius proof

Pre/post evidence proved all 16 unrelated surfaces unchanged, including:

- Gateway rules/lists/config;
- device settings;
- Default profile;
- `SETOK-FAMILY-MANAGED` and match expression;
- all device profiles;
- Access organization;
- IdPs/login methods;
- Access groups;
- service tokens;
- posture rules;
- physical devices and registrations;
- unrelated Access apps/policies.

Expected provider delta only:

- +1 Access app type `warp`;
- +1 exact-identity allow policy;
- 0 other provider changes.

Reconciliation ran twice with `MATCH` and deterministic result. Idempotent re-run produced no additional objects.

## Credential closure

The temporary ST-CF-002 Account API token was revoked by the Product Owner after acceptance. Its DPAPI local copy was removed. The persistent ST-CF-001 credential was not broadened or changed.

## Privacy note

ST-CF-002 introduced no real mailbox or token value into its registry, scripts or evidence. A pre-existing account-name string from ST-CF-001 may contain the same mailbox; this is inherited and not an ST-CF-002 regression. Future evidence should avoid propagating account-owner PII where unnecessary.

## Rollback

Rollback remains documented, not executed:

1. delete the exact managed Access policy by observed ID;
2. delete the exact managed `warp` app by observed ID;
3. re-snapshot and verify pre-state restoration;
4. retire the SETOK managed-resource binding/resource.

A newly issued narrowly scoped Access Apps/Policies write token would be required for rollback.

## Terminal state

`DEVICE_ENROLLMENT_PERMISSION_READY / NO_DEVICE_ENROLLED / SAFE_SELECTOR_NOT_YET_PROVEN`

No Android/iPad enrollment, device subject, device binding, MDM or Gateway enforcement was performed by this Work Order.

## Quality gates

- [x] Story defined.
- [x] Risk classified RED.
- [x] Independent Check PASS WITH CONDITIONS.
- [x] Product Input Gate CLOSED.
- [x] Authorized Base frozen.
- [x] Implementation Branch verified.
- [x] Explicit implementation authorization.
- [x] Required implementation gates PASS.
- [x] Technical Director terminal review ACCEPT.
- [x] Accepted candidate integrated to main.
- [x] Temporary write credential revoked.

## Closure evidence

- Candidate: `678aaff9722af68238dec3ea5c57eeb84c1e7735`
- Integration: `14f38ceb2eb043e62740de6bbe2987014f7824b3`
- Outcome: ACCEPT
