# ST-CF-003 — Prove safe selector and scoped Cloudflare enforcement for android-01

## Status

PREFLIGHT — READ-ONLY DISCOVERY

## Goal

Determine whether Cloudflare Zero Trust can isolate Gateway enforcement to the already enrolled and bound first-family Android device `android-01` without affecting unrelated devices or resources in the shared SETOK Cloudflare organization, and only if isolation is independently proven, prepare a later narrowly scoped apply/rollback execution.

This Story does not authorize Gateway mutation.

## Architecture basis

SETOK owns Policy Intent and precedence. Cloudflare is an enforcement provider.

Accepted prerequisites:

- ST-POL-001 baseline contract is `DESIRED / COMPILED / APPLY_BLOCKED`;
- ST-POL-002 Standard / Restricted / temporary overlays are `DESIRED / COMPILED / APPLY_BLOCKED`;
- ST-DEV-001 is COMPLETE / ACCEPT;
- `android-01` is provider-neutral SETOK subject `sub_01M5Y0XYAMFT3MXRRJV5MFBY3N`;
- its ACTIVE Cloudflare `device_enrollment` binding is `bnd_01M5ZND7V8TK28E2V23Z4MRFEJ`;
- physical device and registration currently observed as `01a17f4d-0062-19de-b716-1df58125a3d4`;
- observed profile is `SETOK-FAMILY-MANAGED`, WARP / MASQUE;
- the Cloudflare account/organization is shared;
- `SETOK-FAMILY-MANAGED` intentionally remains a broad Android/iOS device profile selector and is not a safe family/device enforcement selector.

## Discovery finding — selector gap

Current Cloudflare documentation does not expose the enrolled physical-device ID or registration ID as a direct Gateway DNS/Network/HTTP policy selector.

For mobile device-level policy isolation:

- serial-number posture is not supported on Android/iOS;
- Device IP is not available for Android/iOS;
- Cloudflare Device UUID / `unique_client_id` posture is supported on Android/iOS but the UUID must be supplied by managed deployment/MDM and cannot be assigned manually;
- Android MDM remains explicitly out of scope for the current SETOK Android architecture;
- Gateway identity selectors such as exact `User Email` are available, but identify the authenticated identity/session rather than the physical device itself.

Therefore the existing ST-DEV-001 provider binding is necessary for SETOK ownership/reconciliation, but by itself is not proof that Gateway can safely scope a rule to `android-01`.

## Candidate selector paths to evaluate

### A. Exact enrollment identity

Evaluate whether the existing operational identity used by `android-01` can safely act as the first-family Gateway scope.

Requirements before this can be accepted:

- prove the identity seen by Gateway is exactly the dedicated enrollment identity associated with `android-01`;
- prove no other current device/registration uses that identity;
- prove policy matching with exact identity does not match unrelated SETOK traffic;
- define lifecycle semantics preventing silent scope expansion if the same identity later enrolls another device;
- keep real email/PII outside Git; versioned desired state may use only an opaque selector reference resolved at execution time;
- explicitly classify this as identity-scoped, not cryptographically device-ID-scoped.

If these invariants cannot be made durable, this path is NOT a safe selector.

### B. Device UUID posture

Evaluate only as an architecture alternative, not as an implementation assumption.

Cloudflare documents mobile Device UUID posture through `unique_client_id`, but assignment requires managed deployment. Because Android MDM is currently forbidden, adopting this path would be an architecture change requiring a separate Product/TD decision and Work Order.

### C. Any undocumented/provider-specific device-ID expression

Do not use an undocumented Gateway expression merely because `device.id` exists in logs, headers, or provider context. It is acceptable only if current Cloudflare documentation/API schema explicitly supports it as a Gateway policy selector and read-only validation proves it works for the required policy builders.

## Scope — preflight/read-only

1. Reconstruct live Cloudflare Gateway state and fingerprints.
2. Confirm current device/registration inventory and identity association for `android-01`.
3. Enumerate supported selectors for DNS, Network and HTTP policy builders relevant to ST-POL-001/002.
4. Determine whether exact identity scope can be made durable and safe under SETOK lifecycle rules.
5. Verify current Gateway order of enforcement and first-match semantics.
6. Verify provider entitlement/capability for all ST-POL-001 and ST-POL-002 compiled controls, including previously unresolved premium-category mappings.
7. Produce a zero-mutation selector decision: `PROVEN`, `NOT_PROVEN`, or `ARCHITECTURE_CHANGE_REQUIRED`.
8. Define blast-radius and rollback requirements for a later apply unit if `PROVEN`.

## Explicitly out of scope in preflight

- CREATE/PATCH/PUT/DELETE Gateway policies or lists;
- changing Gateway policy precedence;
- changing `SETOK-FAMILY-MANAGED`;
- changing Default profile;
- changing enrollment authorization or IdP;
- enrolling another device;
- Android MDM or `unique_client_id` injection;
- changing the operational enrollment identity;
- applying ST-POL-001 or ST-POL-002;
- claiming anti-bypass validation.

## Provider-order constraints

Preflight must account for current Cloudflare enforcement behavior:

- Gateway evaluates DNS, then Network, then HTTP policy phases as applicable;
- Network and DNS filtering use precedence/first-match behavior;
- HTTP has action-specific ordering, including Do Not Inspect before ordinary Allow/Block;
- a lower precedence number is evaluated earlier within the relevant policy phase;
- a later rule cannot be assumed to override an earlier first match.

SETOK policy precedence must be compiled deliberately; provider rule order must never become accidental domain precedence.

## Safe-selector acceptance criteria

A selector is `PROVEN` only if all are true:

1. It deterministically matches the intended first-family enforcement scope.
2. It does not match any unrelated current SETOK device/resource.
3. Its lifecycle semantics prevent accidental future broadening or explicitly fail closed when ambiguity appears.
4. It is supported by current Cloudflare Gateway documentation/API for every policy builder needed by the intended controls.
5. It can be represented in SETOK desired state without storing PII/secrets.
6. It can be reconciled read-only before apply.
7. Rollback can remove all scoped rules without changing shared enrollment/profile configuration.
8. A negative test exists proving non-target traffic does not match.

If any criterion fails, `SAFE_SELECTOR_NOT_YET_PROVEN` remains authoritative and no Gateway apply may be authorized.

## Apply boundary

This Story's current phase is read-only. Even if preflight concludes `SAFE_SELECTOR_PROVEN`, a new explicit Technical Director implementation authorization is required before any Gateway mutation.

The first provider mutation, if later authorized, must be narrowly staged and reversible. A low-risk test policy should prove selector isolation before compiling/applying the full ST-POL-001 baseline or ST-POL-002 modes.

## Product Input Gate

NOT REQUIRED for preflight.

The Product Owner already approved the product semantics in ST-POL-001/002 and chose to prioritize Android scoped enforcement before iPad. Selector mechanics and blast-radius validation are Technical Director responsibilities unless the only viable path requires an architecture/product change such as Android MDM.

## Risk

RED for eventual implementation because Gateway policy mutation in a shared Cloudflare organization can affect unrelated traffic.

Preflight itself is read-only.

## Stop conditions

- any provider mutation is required to answer preflight questions;
- direct physical/registration ID scoping is assumed without supported Gateway selector evidence;
- exact-email identity is treated as device identity without proving exclusivity and lifecycle behavior;
- an MDM-only UUID path is introduced without explicit architecture authorization;
- PII/secret value is written to Git/evidence;
- current Gateway/shared-state fingerprints differ unexpectedly from accepted ST-DEV-001 evidence;
- safe isolation cannot be proven;
- unexpected Auto-RED surface.

## Expected preflight terminal states

One of:

- `SAFE_SELECTOR_PROVEN / APPLY_NOT_AUTHORIZED`
- `SAFE_SELECTOR_NOT_PROVEN / APPLY_BLOCKED`
- `ARCHITECTURE_CHANGE_REQUIRED / APPLY_BLOCKED`
