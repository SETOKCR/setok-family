# WORK ORDER ST-DEV-001

## Identity

- **Project:** SETOK Family
- **Repository:** SETOKCR/setok-family
- **Story / Work Unit:** ST-DEV-001
- **Authorized Base:** `8c2758026623209a655ace744fef977b3e018fc5`
- **Implementation Branch:** `feature/st-dev-001`
- **Execution state:** AUTHORIZED
- **Implementation Authorization:** YES
- **Persistence:** PERSISTED

## AIDE execution context

- Framework: SETOK-AIDE v1.2.3
- Role: Development Agent
- Project binding: REQUIRED
- Story: `docs/stories/ST-DEV-001.md`
- Architecture: `docs/ARCHITECTURE.md`
- Quality: `docs/QUALITY.md`
- Independent Check: `docs/development/ST-DEV-001_INDEPENDENT_CHECK.md`

## Goal

Create the first real provider-neutral Android device subject, manually enroll the approved Android device into the existing shared Cloudflare Zero Trust organization using a dedicated operational integration identity, bind the observed Cloudflare device/registration to the internal subject, and prove reversible/offboarding behavior without applying Gateway policy enforcement.

## Risk

**RED.**

This unit mutates external authentication/enrollment state on a physical endpoint and a shared Cloudflare boundary. Blast radius remains constrained by making any shared enrollment-policy/profile/Gateway mutation a hard Stop Condition.

## Independent Check

**PASS WITH CONDITIONS** — `docs/development/ST-DEV-001_INDEPENDENT_CHECK.md`.

All mandatory Independent Check conditions are part of this Work Order.

## Product Input Gate

**NOT REQUIRED.**

The architecture already fixes the Android platform, Google Family Link + Cloudflare One split, no Android MDM and separation of human/device identity. Credentials and physical interaction are operational inputs, not product-semantic decisions.

## Target

- physical platform: Android;
- approved first-family device class: Xiaomi Redmi Note 14 Pro;
- SETOK alias after creation: opaque, e.g. `android-01`;
- Cloudflare organization: existing shared SETOK Zero Trust organization;
- intended existing device profile: `SETOK-FAMILY-MANAGED`;
- client mode target: Traffic + DNS / WARP;
- Android MDM: forbidden.

## Enrollment identity boundary

Manual enrollment must use a dedicated operational integration identity reserved for this device enrollment.

- actual email/login/credential stays outside Git;
- Git/evidence uses only an opaque alias such as `android-enrollment-01`;
- enrollment identity is NOT a SETOK human/member/Child identity;
- do not create an Authentik device user or Child login in this Story;
- do not persist enrollment email/display name/token/OTP/password in registry or evidence.

## Authorized implementation shape after explicit GO

### Stage A — read-only discovery

Before any external mutation:

1. verify `PROJECT_SCOPE_OK` and exact Authorized Base lineage;
2. inventory current Cloudflare devices and device registrations;
3. inventory relevant device-profile assignment and confirm `SETOK-FAMILY-MANAGED` exists unchanged;
4. inventory current enrollment permissions/login methods sufficiently to determine whether the dedicated operational identity can enroll without modifying shared account controls;
5. fingerprint Gateway policies, Default profile and `SETOK-FAMILY-MANAGED` so post-enrollment immutability can be proven;
6. verify no existing registry device subject/binding already represents the target.

If manual enrollment requires changing shared enrollment permissions, login methods, service tokens, profile match rules or Gateway configuration, STOP before mutation.

### Stage B — desired internal device identity

- minimally evolve provider-binding schema only if required to represent provider-neutral Android platform metadata;
- create exactly one internal device subject under the existing tenant;
- internal ID must be random/provider-independent;
- do not create Child/Guardian domain entities or human login identities.

### Stage C — physical manual enrollment

Only after Stage A passes:

- install/open Cloudflare One Agent as needed on the target Android device;
- enroll using the existing SETOK team name and dedicated operational enrollment identity;
- approve Android VPN connection/profile as required by the supported manual flow;
- do not use ManageEngine/MDM/service-token managed deployment;
- do not alter provider policy/profile configuration to force success.

Physical interaction may require the Product Owner to complete steps on the handset. This does not authorize additional provider changes.

### Stage D — observe and bind

After successful enrollment:

- inventory Cloudflare again;
- deterministically identify the new physical device and registration using pre/post delta and provider facts;
- capture only stable non-secret external identifiers required for binding;
- create exactly one ACTIVE `device_enrollment` binding to the existing Cloudflare enforcement integration;
- verify intended profile/mode observed;
- verify Traffic + DNS / WARP connected state where provider/device observation permits;
- reconcile desired binding against provider observation at least twice with identical semantic result.

### Stage E — immutability and rollback evidence

Prove:

- Gateway fingerprint unchanged;
- Default profile unchanged;
- `SETOK-FAMILY-MANAGED` configuration/match expression unchanged;
- no unrelated device/registration changed;
- existing human subjects/bindings unchanged;
- no policy is claimed APPLIED;
- `SAFE_SELECTOR_NOT_YET_PROVEN` remains explicit.

Document rollback/offboarding across:

1. SETOK binding retirement;
2. Cloudflare registration/device revoke/delete;
3. local Android client disconnect/uninstall as appropriate;
4. revocation/removal of enrollment authorization when permanent prevention of re-registration is intended.

Provider deletion alone must not be described as permanent offboarding.

## Provider mutation boundary

The only intended external mutation in this Story is the device's own Cloudflare enrollment/registration caused by the supported manual client flow.

Forbidden without a new explicit Technical Director authorization:

- Gateway DNS/HTTP/Network rules or lists create/update/delete/reorder;
- device-enrollment permission changes;
- login-method changes;
- service-token creation/changes;
- `SETOK-FAMILY-MANAGED` edits;
- Default profile edits;
- device profile selector/match edits;
- `unique_client_id` fabrication/injection;
- ManageEngine or other Android MDM deployment;
- mutation of unrelated Cloudflare devices/registrations.

## Registry invariants

- exactly one new device subject;
- device subject belongs to the existing first-family tenant;
- no `human_kind` on device subject;
- internal subject ID independent from provider IDs;
- exactly one ACTIVE Cloudflare `device_enrollment` binding after successful enrollment;
- real provider external IDs only inside binding `external` data;
- no real email/name/secrets/tokens in desired state/evidence;
- existing adults unchanged;
- existing integrations/resources/bindings unchanged except the new device subject/binding and minimal backward-compatible schema evolution if needed.

## Safe-selector boundary

This Work Order MUST NOT claim safe selector completion.

Successful terminal wording must retain conceptually:

`DEVICE_ENROLLED / DEVICE_BOUND / SAFE_SELECTOR_NOT_YET_PROVEN`

The later scoped-enforcement Story owns proof that a Cloudflare selector isolates only the intended family/device traffic.

## Required validation

- `PROJECT_SCOPE_OK`;
- exact Authorized Base lineage;
- pre-enrollment provider inventory/fingerprints captured;
- Product Input Gate NOT REQUIRED;
- exactly one new Android device subject;
- exactly one ACTIVE Cloudflare device binding after success;
- deterministic pre/post identification of target provider object;
- intended profile observed or controlled STOP;
- Traffic + DNS / WARP connected state observed or controlled STOP;
- repeated reconciliation deterministic;
- no Gateway mutation;
- no Default profile mutation;
- no `SETOK-FAMILY-MANAGED` mutation;
- no shared enrollment-auth mutation;
- no Android MDM;
- no Child login;
- no PII/secrets in Git/evidence;
- rollback/offboarding documented;
- safe selector NOT PROVEN.

## Stop conditions

- repository mismatch;
- Authorized Base/branch lineage mismatch;
- target cannot be uniquely distinguished from pre-existing Cloudflare devices;
- proposed manual enrollment requires shared enrollment permission/login-method/service-token mutation;
- target would require Android MDM or administrator-supplied `unique_client_id`;
- `SETOK-FAMILY-MANAGED` must be edited to enroll/match target;
- Gateway mutation is required or attempted;
- Default profile change is required or attempted;
- unrelated device/registration would be changed;
- enrollment identity must be committed to Git/evidence;
- a Child login/Auth user must be created to make enrollment work;
- existing architecture/provider facts are materially contradicted;
- unexpected Auto-RED surface.

## Quality gates

- [x] Story defined.
- [x] Risk classified RED.
- [x] Independent Check PASS WITH CONDITIONS.
- [x] Product Input Gate NOT REQUIRED.
- [x] Authorized Base frozen at `8c2758026623209a655ace744fef977b3e018fc5`.
- [x] Implementation Branch created from exact Authorized Base.
- [x] Branch lineage verified by construction.
- [x] Explicit Technical Director implementation authorization issued by Product Owner GO.
- [ ] Required implementation gates PASS or controlled STOP.
- [ ] Technical Director terminal review complete.

## Closure evidence

- Preflight: PASS
- Independent Check: PASS WITH CONDITIONS
- Product Input Gate: NOT REQUIRED
- Authorized Base: `8c2758026623209a655ace744fef977b3e018fc5`
- Implementation Branch: `feature/st-dev-001`
- Branch lineage: VERIFIED by construction from exact Authorized Base
- Implementation Authorization: YES
