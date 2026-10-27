# WORK ORDER ST-CF-003

## Identity

- **Project:** SETOK Family
- **Repository:** SETOKCR/setok-family
- **Story / Work Unit:** ST-CF-003
- **Purpose:** prove safe selector and scoped Cloudflare enforcement boundary for `android-01`
- **Execution state:** PREFLIGHT / READ-ONLY DISCOVERY
- **Implementation Authorization:** NO
- **Provider Mutation Authorization:** NO
- **Risk:** RED for eventual implementation

## Governance basis

- Story: `docs/stories/ST-CF-003.md`
- Independent Check: `docs/development/ST-CF-003_INDEPENDENT_CHECK.md`
- Independent Check decision: `PASS WITH CONDITIONS — READ-ONLY PREFLIGHT ONLY`
- Product Input Gate: `NOT REQUIRED`
- ST-DEV-001: COMPLETE / ACCEPT
- ST-POL-001: DESIRED / COMPILED / APPLY_BLOCKED
- ST-POL-002: DESIRED / COMPILED / APPLY_BLOCKED

## Target scope

SETOK subject:

`sub_01M5Y0XYAMFT3MXRRJV5MFBY3N` / `android-01`

Current provider binding:

`bnd_01M5ZND7V8TK28E2V23Z4MRFEJ`

Expected Cloudflare physical-device / registration ID from accepted ST-DEV-001 evidence:

`01a17f4d-0062-19de-b716-1df58125a3d4`

These IDs prove ownership/reconciliation only. They MUST NOT be assumed to be Gateway policy selectors.

## Read-only discovery authorized by Product Owner GO

The Development Agent may perform GET/read-only operations necessary to establish:

1. current Cloudflare device and registration inventory;
2. current identity association for `android-01`, with the real identity value redacted from versioned evidence;
3. cardinality of active registrations/devices associated with that exact identity;
4. current Gateway DNS, Network and HTTP rules, lists and configuration;
5. current supported selector/capability facts observable through provider API/schema;
6. current device profiles and the observed `SETOK-FAMILY-MANAGED` assignment;
7. enrollment authorization, IdPs, service tokens and posture rules;
8. current category/capability mappings and entitlement relevant to ST-POL-001 and ST-POL-002;
9. deterministic fingerprints of all shared surfaces;
10. a selector decision based on live evidence.

The agent may create or update repository-local scripts and sanitized evidence required for this read-only discovery.

## Forbidden provider operations

No provider POST/PUT/PATCH/DELETE is authorized.

Specifically forbidden:

- Gateway rule/list create/update/delete/reorder;
- Gateway settings changes;
- profile/default-profile changes;
- enrollment application/policy changes;
- IdP/login changes;
- service-token changes;
- posture-rule creation/change/delete;
- device/registration revoke/delete;
- enrollment/re-enrollment;
- Android MDM / managed configuration;
- `unique_client_id` assignment;
- changing the operational enrollment identity.

Any provider mutation requirement is a HARD STOP.

## Required checks

### A. Project and lineage

- `PROJECT_SCOPE_OK`;
- exact repository `SETOKCR/setok-family`;
- execute on the dedicated ST-CF-003 branch from the frozen Authorized Base;
- clean working tree before execution.

### B. Accepted-state reconciliation

Prove that accepted ST-DEV-001 state still holds:

- exactly one expected `android-01` physical device/registration unless an external change is explicitly explainable;
- ACTIVE SETOK binding still points to the expected provider IDs;
- observed Android registration remains WARP / MASQUE;
- intended managed profile remains `SETOK-FAMILY-MANAGED`;
- no unexpected shared-surface drift.

Unexpected device/registration or ownership ambiguity = STOP.

### C. Exact-identity candidate

Without storing the actual email in Git/evidence:

- resolve the operational identity locally;
- confirm the provider registration/user identity matches it exactly;
- count physical devices/registrations using that identity;
- expected cardinality for a candidate safe scope: exactly 1 active device and exactly 1 active registration;
- confirm the operational identity is dedicated to this device enrollment and not a general family/shared enrollment identity;
- identify whether Gateway DNS/Network/HTTP identity selectors can match the same authenticated identity.

The output must use only opaque alias `family-enrollment-01` or an equivalent non-PII reference.

### D. Direct device selector test

Read-only inspect current provider selector/API schema.

Do not infer policy support from logs or dynamic variables. Record whether a documented direct physical-device ID, registration ID or `device.id` selector exists for Gateway DNS/Network/HTTP.

If unsupported, record `DIRECT_DEVICE_ID_SELECTOR_UNSUPPORTED`.

### E. Mobile posture alternatives

Confirm current provider capability for:

- serial-number posture on Android;
- Device UUID / `unique_client_id` posture and deployment prerequisite;
- Device IP on Android;
- other supported posture selectors that could uniquely and durably isolate this handset without MDM.

Do not create posture checks.

### F. Policy-builder / precedence matrix

For DNS, Network and HTTP record:

- supported identity/device-posture selectors relevant to scope;
- first-match/precedence behavior;
- action-specific ordering that affects ST-POL-001/002;
- any limitation that would make one selector inconsistent across required controls.

### G. Entitlement / category matrix

Re-evaluate live/provider capability for:

ST-POL-001:
- malware;
- phishing;
- C2/botnet;
- adult content;
- gambling;
- SafeSearch;
- YouTube Restricted Mode.

ST-POL-002:
- social media;
- gaming;
- entertainment/streaming.

Distinguish `SUPPORTED`, `UNSUPPORTED`, `ENTITLEMENT_UNVERIFIED`, and any provider mapping ambiguity.

### H. Safe-selector decision

Return exactly one terminal preflight result:

- `SAFE_SELECTOR_PROVEN / APPLY_NOT_AUTHORIZED`
- `SAFE_SELECTOR_NOT_PROVEN / APPLY_BLOCKED`
- `ARCHITECTURE_CHANGE_REQUIRED / APPLY_BLOCKED`

`SAFE_SELECTOR_PROVEN` requires all Story and Independent Check criteria to pass, including negative-scope and lifecycle reasoning.

## Exact-identity lifecycle invariant

If exact enrollment identity is proposed as the selector, it is accepted only if SETOK can enforce this lifecycle rule:

> One operational selector identity maps to at most one ACTIVE SETOK device subject / one active provider registration scope. Reuse for another device requires retiring/replacing the prior binding/scope or provisioning a new dedicated operational identity first.

If this cannot be made deterministic and fail-closed, the selector is NOT PROVEN.

## Evidence

Store sanitized evidence under:

`docs/evidence/ST-CF-003/`

No actual enrollment email, OTP, token, public IP, serial number, registration public key or other unnecessary PII/secret may be versioned.

## Stop conditions

- project/repository/lineage mismatch;
- provider mutation needed;
- unexpected shared-state drift;
- unexpected device/registration;
- ambiguous ownership/identity cardinality;
- real email/secret would need to enter Git;
- unsupported selector would need to be guessed;
- Android MDM becomes necessary to proceed;
- entitlement cannot be established read-only;
- any Auto-RED surface outside this Work Order.

## Closure of discovery

Discovery does NOT authorize apply.

After the Development Agent returns evidence, the Technical Director must review it and decide whether ST-CF-003 can become implementation-ready, remains blocked, or requires architecture change.

## Authorized Base

TO_BE_FROZEN_AFTER_THIS_PREFLIGHT_COMMIT

## Implementation Branch

TO_BE_CREATED_FROM_AUTHORIZED_BASE
