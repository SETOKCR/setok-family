# ST-CF-003 — Independent Check

## Decision

**PASS WITH CONDITIONS — READ-ONLY PREFLIGHT ONLY**

## Scope reviewed

Story: `docs/stories/ST-CF-003.md`

Objective: determine whether Cloudflare Gateway can safely isolate enforcement to the first-family Android scope represented by `android-01` before any Gateway mutation.

## Architecture consistency

PASS.

The Story preserves the frozen SETOK Family architecture:

- SETOK Policy Intent remains provider-neutral;
- Cloudflare remains an enforcement provider rather than the domain model;
- provider device/registration IDs remain external bindings, not SETOK IDs;
- shared-account blast radius is treated as a hard boundary;
- Android MDM remains forbidden unless separately approved as an architecture change;
- ST-POL-001/002 remain `APPLY_BLOCKED` until selector isolation is proven;
- no Child login or human/device identity collapse is introduced.

## Main finding

The accepted ST-DEV-001 binding proves which Cloudflare device/registration belongs to `android-01`, but it does **not** prove that the same provider identifier is usable as a Gateway policy selector.

Current Cloudflare documentation supports the following relevant facts:

1. Gateway DNS/Network/HTTP policies expose traffic, identity and device-posture selectors, but not the enrolled physical-device ID / registration ID as a documented direct selector.
2. `User Email` is a supported identity selector for Gateway policies when the Cloudflare One Client carries an authenticated identity session.
3. Mobile serial-number posture is not supported for Android/iOS.
4. Mobile Device UUID posture uses `unique_client_id`, which must be assigned through managed deployment and cannot be assigned manually.
5. Device IP is not available for Android/iOS.
6. Gateway policy precedence is first-match within the applicable phase; HTTP has additional action-specific ordering, including Do Not Inspect before ordinary Allow/Block.

Therefore the Story correctly refuses to treat provider inventory IDs as a policy selector without additional supported evidence.

## Candidate exact-identity path

Conditionally viable for preflight evaluation only.

The dedicated enrollment identity could potentially provide a first-family Gateway scope because Gateway supports exact `User Email` matching. However this is **identity-scoped**, not device-ID-scoped.

It may be accepted as `SAFE_SELECTOR_PROVEN` only if live read-only discovery proves all of the following:

- Gateway sees the expected exact enrollment identity for the current `android-01` registration;
- no other physical device or registration currently uses that identity;
- the identity is operationally dedicated to this one SETOK device subject, not reused as a family-wide/general enrollment identity;
- SETOK lifecycle rules make reuse fail closed: before any future enrollment under the same identity, the current binding/scope must be retired or a new dedicated identity must be provisioned;
- desired state stores only an opaque selector reference; the real email remains outside Git/evidence;
- pre-apply reconciliation can resolve the opaque reference to the live provider identity and assert one expected registration only;
- negative-scope validation can prove non-target traffic would not match.

If any of these cannot be proven durably, exact identity must remain `NOT_PROVEN`.

## Device UUID / MDM path

Not authorized.

Cloudflare's documented mobile Device UUID posture requires `unique_client_id` supplied through managed deployment. Adopting it would violate the current Android no-MDM architecture. If it becomes the only acceptable isolation mechanism, ST-CF-003 must terminate `ARCHITECTURE_CHANGE_REQUIRED / APPLY_BLOCKED` and return to TD/PO governance.

## Risk review

Eventual implementation risk: **RED**.

Reasons:

- shared Cloudflare account;
- Gateway policy mutation can affect unrelated SETOK traffic;
- precedence/order errors can silently broaden or weaken enforcement;
- identity scope can broaden if the enrollment identity is reused;
- policy categories may have entitlement differences;
- rollback must restore current permissive/no-family-enforcement state deterministically.

Read-only discovery itself is low operational risk but inherits RED governance because it prepares a high-impact provider mutation.

## Required preflight evidence before Work Order can become implementation-ready

1. `PROJECT_SCOPE_OK` and current `main` lineage.
2. Fresh read-only Cloudflare snapshot/fingerprints for Gateway rules/lists/config, profiles, enrollment authorization, IdPs, service tokens, posture rules, devices and registrations.
3. `android-01` still reconciles to exactly one active physical device/registration.
4. Live identity association for that registration is observed without versioning the real email.
5. Cardinality check: exact enrollment identity is associated with exactly one active registration/device.
6. Current Gateway selector capability matrix for DNS, Network and HTTP.
7. Current order/precedence semantics recorded.
8. ST-POL-001 entitlement/category resolution rechecked, including gambling.
9. ST-POL-002 category capability/entitlement rechecked for social media, gaming and entertainment/streaming.
10. Proposed selector decision with explicit terminal state:
   - `SAFE_SELECTOR_PROVEN / APPLY_NOT_AUTHORIZED`, or
   - `SAFE_SELECTOR_NOT_PROVEN / APPLY_BLOCKED`, or
   - `ARCHITECTURE_CHANGE_REQUIRED / APPLY_BLOCKED`.
11. No provider mutation and no PII/secrets in evidence.

## Quality conditions

- A direct Cloudflare device/registration ID must not be used in a Gateway expression unless Cloudflare's current supported selector schema explicitly allows it.
- `device.id` appearing in logs, dynamic HTTP header variables or provider context is not sufficient evidence that it is a policy selector.
- Identity-based scope must be named accurately as identity scope.
- No full baseline/mode apply may occur in the same step that first proves selector behavior; selector isolation requires a narrowly staged canary/test before broader policy apply.
- Existing Gateway rules must be fingerprinted and preserved unless a later Work Order explicitly authorizes scoped changes.
- Real enrollment email must remain outside Git.

## Product Input Gate

**NOT REQUIRED** for this read-only preflight.

Escalate to Product Owner only if the only safe path requires changing the accepted Android architecture, such as introducing MDM/managed deployment, or if a product-level identity/lifecycle decision is unavoidable.

## Independent Check conclusion

`PASS WITH CONDITIONS`.

ST-CF-003 may proceed to controlled read-only provider discovery. It is **not** implementation-ready and no Gateway mutation is authorized.
