# WORK ORDER ST-DEV-001

## Identity

- **Project:** SETOK Family
- **Repository:** SETOKCR/setok-family
- **Story / Work Unit:** ST-DEV-001
- **Execution attempt:** `r2`
- **Authorized Base:** `f09d114d29ae7fffc1d8516cd287c83188d4ae00`
- **Implementation Branch:** `feature/st-dev-001-r2`
- **Execution state:** READY
- **Implementation Authorization:** NO
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

Create the first real provider-neutral Android device subject, manually enroll the approved Android device into the existing shared Cloudflare Zero Trust organization using the dedicated operational enrollment identity, bind the observed Cloudflare device/registration to the internal subject, and prove reversible/offboarding behavior without applying Gateway policy enforcement.

## Risk

**RED.**

This unit mutates external authentication/enrollment state on a physical endpoint and a shared Cloudflare boundary. Blast radius remains constrained by strict read-only discovery before enrollment and hard stops on any shared provider mutation outside the device's own supported manual registration.

## Independent Check

**PASS WITH CONDITIONS** — `docs/development/ST-DEV-001_INDEPENDENT_CHECK.md`.

The original Independent Check remains applicable. No architecture or product-semantic change occurred during dependency remediation.

## Resume history

### Attempt r1 — CONTROLLED STOP

- original Authorized Base: `8c2758026623209a655ace744fef977b3e018fc5`;
- original branch: `feature/st-dev-001`;
- controlled-stop candidate/evidence commit: `74cb833a1fcbc2e452fd7d0dde578b22ca9fdaf4`;
- stopped at Stage A;
- external mutation performed: NO;
- device subjects created: 0;
- device bindings created: 0;
- blocker: Cloudflare device-enrollment permissions did not exist.

The r1 branch is retained as immutable historical evidence and MUST NOT be rebased or reused for r2.

### Dependency resolution — ST-CF-002

ST-CF-002 was accepted and integrated before r2.

Resulting provider capability:

- exactly one SETOK-managed Cloudflare Access application of type `warp` exists (provider-fixed name `Warp Login App`);
- exactly one `allow` policy exists for operational alias `family-enrollment-01`;
- existing One-time PIN IdP remains the only allowed IdP for that enrollment application;
- the application/policy are bound in the provider-binding registry as SETOK-managed `enrollment_authorization` infrastructure;
- Gateway, Default profile, `SETOK-FAMILY-MANAGED`, posture rules, service-token state, devices and registrations were unchanged by ST-CF-002;
- the temporary ST-CF-002 write token was revoked after acceptance.

Therefore the r1 blocker is resolved. ST-DEV-001 r2 MUST nevertheless repeat Stage A from fresh provider state before any device or endpoint mutation.

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

Manual enrollment uses the existing dedicated operational identity represented in Git only as `family-enrollment-01`.

- actual mailbox/login/OTP stays outside Git;
- enrollment identity is NOT a SETOK human/member/Child identity;
- do not create an Authentik device user or Child login;
- do not persist email/display name/OTP/token in registry or evidence.

## Authorized implementation shape after a new explicit GO

### Stage A — fresh read-only discovery

Before any external or endpoint mutation:

1. verify `PROJECT_SCOPE_OK` and exact r2 Authorized Base lineage;
2. inventory current Cloudflare devices and device registrations;
3. verify the ST-CF-002 `enrollment_authorization` app/policy still exist and reconcile to the registry-bound provider IDs;
4. verify policy decision remains `allow`, include cardinality remains exactly 1 and only One-time PIN is attached;
5. confirm `SETOK-FAMILY-MANAGED` exists unchanged;
6. fingerprint Gateway policies, Default profile, `SETOK-FAMILY-MANAGED`, enrollment authorization, IdPs, service tokens and posture rules;
7. verify no existing registry device subject/binding already represents the target;
8. verify the operational enrollment mailbox is still locally available without exposing it to Git/evidence.

Expected pre-enrollment device state remains 0 devices / 0 registrations unless a new external state is explicitly explained. Any unexpected device/registration or ownership ambiguity is a STOP for TD review.

If enrollment would require changing enrollment permissions, login methods, service tokens, profile match rules, Gateway configuration or the ST-CF-002 enrollment authorization, STOP before mutation.

### Stage B — desired internal device identity

Only after Stage A PASS:

- minimally evolve provider-binding schema only if required to represent provider-neutral Android platform metadata;
- create exactly one internal device subject under the existing tenant;
- internal ID must be random/provider-independent;
- do not create Child/Guardian domain entities or human login identities.

### Stage C — physical manual enrollment

Only after Stage A PASS and Stage B validation:

- install/open Cloudflare One Agent as needed on the target Android device;
- enroll using the existing SETOK team name and `family-enrollment-01` operational identity;
- approve Android VPN connection/profile as required by the supported manual flow;
- do not use ManageEngine/MDM/service-token managed deployment;
- do not alter provider policy/profile configuration to force success.

Physical interaction may require the Product Owner to complete steps on the handset. The Development Agent must stop at the exact interaction point and give precise instructions rather than bypassing it.

### Stage D — observe and bind

After successful enrollment:

- inventory Cloudflare again;
- deterministically identify the new physical device and registration using pre/post delta and provider facts;
- capture only stable non-secret external identifiers required for binding;
- create exactly one ACTIVE `device_enrollment` binding to the existing Cloudflare enforcement integration;
- verify intended profile/mode observed;
- verify Traffic + DNS / WARP connected state where provider/device observation permits;
- reconcile desired binding against observed provider state at least twice with identical semantic result.

### Stage E — immutability and rollback evidence

Prove unchanged:

- Gateway;
- Default profile;
- `SETOK-FAMILY-MANAGED` configuration/match expression;
- ST-CF-002 enrollment authorization app/policy semantics;
- IdPs/login methods;
- service tokens;
- posture rules;
- unrelated devices/registrations;
- existing human subjects/bindings.

No policy may be claimed `APPLIED` and `SAFE_SELECTOR_NOT_YET_PROVEN` must remain explicit.

## Provider mutation boundary

The only intended external provider mutation in ST-DEV-001 r2 is the target Android device's own Cloudflare enrollment/registration caused by the supported manual client flow.

Forbidden without new explicit Technical Director authorization: Gateway mutation; ST-CF-002 enrollment app/policy mutation; enrollment-permission, IdP/login, service-token, profile/default/selector changes; `unique_client_id` fabrication; Android MDM; unrelated device/registration mutation.

## Registry invariants

- exactly one new device subject;
- exactly one ACTIVE Cloudflare `device_enrollment` binding after successful enrollment;
- no human/device identity collapse;
- provider IDs only in external binding data;
- no PII/secrets in desired state/evidence;
- existing adults and ST-CF-002 enrollment authorization unchanged.

## Safe-selector boundary

Successful terminal state remains:

`DEVICE_ENROLLED / DEVICE_BOUND / SAFE_SELECTOR_NOT_YET_PROVEN`

## Stop conditions

Repository/lineage mismatch; ST-CF-002 enrollment authorization mismatch/ambiguity; unexplained pre-existing device/registration; inability to identify target deterministically; any required shared enrollment/IdP/service-token/profile/Gateway mutation; Android MDM/managed UUID requirement; PII/secret versioning; Child/Auth user requirement; unrelated device mutation; unexpected Auto-RED surface.

## Quality gates

- [x] Story defined.
- [x] Risk classified RED.
- [x] Independent Check PASS WITH CONDITIONS.
- [x] Product Input Gate NOT REQUIRED.
- [x] r1 CONTROLLED STOP preserved as historical evidence.
- [x] ST-CF-002 dependency accepted/integrated and temporary write credential revoked.
- [x] r2 Authorized Base frozen at `f09d114d29ae7fffc1d8516cd287c83188d4ae00`.
- [x] r2 Implementation Branch created from exact Authorized Base.
- [x] r2 branch lineage verified by construction.
- [ ] New explicit Technical Director implementation authorization.
- [ ] Required implementation gates PASS or controlled STOP.
- [ ] Technical Director terminal review complete.

## Closure evidence

- Resume preflight: PASS
- Independent Check: PASS WITH CONDITIONS
- Product Input Gate: NOT REQUIRED
- Prior controlled stop: `74cb833a1fcbc2e452fd7d0dde578b22ca9fdaf4`
- Dependency resolution: ST-CF-002 ACCEPT / integrated
- r2 Authorized Base: `f09d114d29ae7fffc1d8516cd287c83188d4ae00`
- r2 Implementation Branch: `feature/st-dev-001-r2`
- r2 Implementation Authorization: NO
