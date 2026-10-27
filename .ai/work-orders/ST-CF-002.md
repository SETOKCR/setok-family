# WORK ORDER ST-CF-002

## Identity

- **Project:** SETOK Family
- **Repository:** SETOKCR/setok-family
- **Story / Work Unit:** ST-CF-002
- **Authorized Base:** `0e32888cb8d78c488cbe4a231e7767a38ed9853b`
- **Implementation Branch:** `feature/st-cf-002`
- **Execution state:** READY
- **Implementation Authorization:** NO
- **Persistence:** PERSISTED

## AIDE execution context

- Framework: SETOK-AIDE v1.2.3
- Role: Development Agent
- Project binding: REQUIRED
- Story: `docs/stories/ST-CF-002.md`
- Architecture: `docs/ARCHITECTURE.md`
- Quality: `docs/QUALITY.md`
- Independent Check: `docs/development/ST-CF-002_INDEPENDENT_CHECK.md`

## Goal

Create the minimum Cloudflare Access device-enrollment authorization required for SETOK Family: one managed Access application of type `warp` and one exact-mailbox allow policy, using the existing One-time PIN IdP, without mutating Gateway, device profiles, login methods, service tokens, posture rules or devices.

## Risk

**RED.**

This Work Order changes security-sensitive enrollment authorization in the shared SETOK Cloudflare account. Blast radius is constrained by exact-mailbox scope and strict pre/post fingerprints.

## Independent Check

**PASS WITH CONDITIONS** — `docs/development/ST-CF-002_INDEPENDENT_CHECK.md`.

All Independent Check conditions are mandatory.

## Product Input Gate

**CLOSED.**

The Product Owner selected an existing SETOK IT administration mailbox capable of receiving OTP. Its real value MUST stay outside Git/versioned evidence.

Versioned alias:

`family-enrollment-01`

## Intended provider state

Create exactly one Cloudflare Access application:

- type: `warp`;
- name: `SETOK-FAMILY-DEVICE-ENROLLMENT`;
- managed by SETOK Family inside the existing shared Cloudflare integration boundary.

Create exactly one Access policy attached to it:

- decision/action: `allow`;
- include: exact real mailbox supplied operationally for alias `family-enrollment-01`;
- login: existing One-time PIN only;
- no domain-wide include;
- no `everyone`;
- no group expansion;
- no service token;
- no second identity.

## Authorized implementation shape after explicit GO

### Stage A — pre-mutation discovery

Before mutation:

1. verify `PROJECT_SCOPE_OK` and exact Authorized Base lineage;
2. verify Access apps/policies current state;
3. verify One-time PIN remains the existing IdP;
4. verify service-token state;
5. fingerprint Gateway rules/lists/config;
6. fingerprint Default and `SETOK-FAMILY-MANAGED` profiles;
7. fingerprint posture rules;
8. inventory device/registration counts;
9. verify the real enrollment mailbox operational input is available locally without placing it in Git/evidence;
10. verify the write credential is narrowly scoped and stored outside Git.

Hard STOP if an unmanaged/pre-existing `warp` application appears or any current state materially differs such that ownership is ambiguous.

### Stage B — provider mutation

Create exactly:

1. one Access application `SETOK-FAMILY-DEVICE-ENROLLMENT` of type `warp`;
2. one allow policy whose only include is the exact operational mailbox for `family-enrollment-01`.

No other provider mutation is authorized.

### Stage C — ownership/reconciliation

- observe and capture created app/policy provider IDs;
- minimally extend provider-binding resource ownership if required;
- provider IDs remain external identifiers;
- no real mailbox value in registry/evidence;
- reconcile desired vs observed state at least twice with identical semantic result.

### Stage D — blast-radius proof

Prove unchanged:

- Gateway DNS/HTTP/Network policies/rules/lists/config;
- Default device profile;
- `SETOK-FAMILY-MANAGED` profile/config/match;
- IdPs/login methods;
- service tokens;
- posture rules;
- physical devices and registrations;
- unrelated Access resources.

## Provider credential boundary

A separate narrowly scoped Cloudflare API token may be created outside this repository with only the permissions required for Access Apps/Policies write and validation reads.

Requirements:

- secret outside Git;
- local secure-storage pattern only;
- do not version token value;
- revoke after mutation/evidence collection where feasible;
- do not broaden existing ST-CF-001 token permissions silently.

If obtaining the required credential requires an unrelated persistent account-security mutation or broader privilege than reasonably necessary, STOP and escalate.

## Lifecycle / rollback

Successful normal state leaves the enrollment app/policy active because it is required for subsequent Android and iPad enrollment/re-enrollment.

Rollback:

1. delete the created policy by observed ID;
2. delete the created `warp` app by observed ID;
3. verify Access app/policy state returns to the pre-operation fingerprint/count;
4. verify all unrelated shared surfaces remain unchanged.

Rollback is not automatic cleanup after success.

## Strictly forbidden

- Gateway policy/list/config changes;
- Default profile changes;
- `SETOK-FAMILY-MANAGED` changes;
- device-profile selector changes;
- IdP/login-method changes;
- service-token creation/change;
- posture-rule changes;
- physical device enrollment;
- device subject/device binding creation;
- Android/iPad MDM changes;
- safe-selector claims;
- real mailbox value committed to Git/evidence;
- domain/everyone/group enrollment allow rules.

## Required validation

- `PROJECT_SCOPE_OK`;
- exact Authorized Base lineage;
- Product Input Gate CLOSED;
- exactly one new `warp` app;
- exactly one exact-mailbox allow policy;
- One-time PIN unchanged;
- Gateway unchanged;
- profiles unchanged;
- service-token state unchanged;
- posture rules unchanged;
- device/registration counts unchanged;
- deterministic reconciliation PASS;
- no PII/secrets in Git/evidence;
- rollback documented;
- safe selector remains NOT PROVEN.

## Stop conditions

- repository mismatch;
- Authorized Base/branch mismatch;
- unmanaged/pre-existing `warp` app appears;
- more than one enrollment identity is needed;
- domain/everyone/group policy is required;
- IdP/login-method mutation required;
- service token required;
- Gateway/profile/posture/device mutation required;
- actual mailbox would need to be versioned;
- write credential requires unjustified broad privilege;
- provider API cannot prove created state;
- unrelated Access resources would be modified;
- unexpected Auto-RED surface.

## Quality gates

- [x] Story defined.
- [x] Risk classified RED.
- [x] Independent Check PASS WITH CONDITIONS.
- [x] Product Input Gate CLOSED.
- [x] Authorized Base frozen at `0e32888cb8d78c488cbe4a231e7767a38ed9853b`.
- [x] Implementation Branch created from exact Authorized Base.
- [x] Branch lineage verified by construction.
- [ ] Explicit Technical Director implementation authorization.
- [ ] Required implementation gates PASS or controlled STOP.
- [ ] Technical Director terminal review complete.

## Closure evidence

- Preflight: PASS
- Independent Check: PASS WITH CONDITIONS
- Product Input Gate: CLOSED
- Enrollment identity alias: `family-enrollment-01`
- Real mailbox: operational input only, outside Git
- Authorized Base: `0e32888cb8d78c488cbe4a231e7767a38ed9853b`
- Implementation Branch: `feature/st-cf-002`
- Branch lineage: VERIFIED by construction from exact Authorized Base
- Implementation Authorization: NO
