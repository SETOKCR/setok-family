# ST-DEV-001 — Establish first Android device enrollment and provider binding

## Status

PREFLIGHT

## Goal

Establish the first real Android device subject for the first productive SETOK Family tenant, manually enroll the approved Android device into the existing shared Cloudflare Zero Trust organization, observe and bind the resulting Cloudflare device/registration identifiers, and prove reversible/offboarding behavior without applying Gateway policy enforcement.

## Target architecture

- Platform: Android.
- Physical target: first-family `Redmi Note 13 Pro+ 5G (23090RA98G)`.
  - Corrected on 2026-10-27 after provider observation. ST-DEV-001 r2 Stage D observed this model on the enrolled handset. The Product Owner then explicitly confirmed that this handset is the intended first-family Android device and that the earlier "Xiaomi Redmi Note 14 Pro" target was a documentation error.
  - The architectural intent is unchanged: Android, Google Family Link, Cloudflare One, and no Android MDM.
- Native parental authority: Google Family Link.
- Network enforcement provider: Cloudflare One Client / Cloudflare Zero Trust.
- ManageEngine MDM: explicitly NOT used on Android.
- Cloudflare account/organization remains a shared SETOK platform boundary.
- Existing managed device profile: `SETOK-FAMILY-MANAGED`.

## Identity model

SETOK device identity and Cloudflare enrollment identity remain separate.

- Create exactly one provider-neutral internal device subject with a random SETOK `sub_` identifier and opaque alias such as `android-01`.
- The device subject is NOT a human identity and does not create a Child login.
- Cloudflare external device/registration identifiers are bindings, never SETOK primary IDs.
- Manual enrollment uses a dedicated operational integration identity for this Android device. The real email/credential must remain outside Git and versioned evidence; Git may refer only to an opaque alias such as `android-enrollment-01`.
- The enrollment identity is an implementation detail, not a SETOK Family member/role and not an Authentik family-domain authorization construct.

## Current provider facts verified during preflight

Cloudflare One currently documents that:

- Android manual enrollment uses Cloudflare One Agent, team name, authentication and Android VPN-profile approval;
- a persistent device registration is created when the client authenticates;
- deleting a device does not permanently prevent recreation if the client can authenticate again;
- service-token no-user enrollment is documented through managed deployment parameters;
- managed `unique_client_id` / Device UUID assignment on Android requires a managed deployment tool and cannot be assigned manually.

Therefore this Story uses manual enrollment and does not introduce Android MDM solely to obtain a provider UUID selector.

## Scope

### In scope

1. Read-only pre-enrollment inventory of Cloudflare devices, registrations, device profiles and enrollment configuration relevant to the target.
2. Validate that the proposed enrollment path can be scoped without altering unrelated SETOK resources.
3. Extend the provider-binding registry schema only as minimally required to represent an Android device subject and its non-sensitive platform metadata.
4. Create exactly one internal Android device subject in desired state.
5. Manual Cloudflare One Agent enrollment on the physical Android device using the dedicated operational enrollment identity.
6. Observe the new Cloudflare physical-device record and associated registration after enrollment.
7. Create exactly one ACTIVE Cloudflare `device_enrollment` binding for the internal device subject using stable non-secret external identifiers only.
8. Verify the enrolled device receives/matches the existing `SETOK-FAMILY-MANAGED` profile without mutating that profile.
9. Validate Cloudflare One Client connectivity in Traffic + DNS / WARP mode and record provider-observed evidence.
10. Reconcile desired binding against observed provider state deterministically.
11. Document rollback/offboarding semantics, including the fact that provider deletion alone does not permanently prevent re-registration while enrollment authentication remains allowed.
12. Produce evidence under `docs/evidence/ST-DEV-001/`.

### Out of scope

- Gateway DNS/HTTP/Network policy create/update/delete/reorder;
- applying ST-POL-001 or ST-POL-002;
- claiming the safe Gateway selector is solved;
- Device ID / `unique_client_id` MDM injection;
- ManageEngine on Android;
- Google Family Link reconfiguration beyond observing that it remains the native parental-control authority;
- child login identity;
- Authentik user creation for the device;
- iPad enrollment;
- anti-bypass validation;
- Phase 2 application/database/runtime.

## Enrollment strategy

Preferred first-family path:

1. Keep the existing SETOK shared Zero Trust organization and `SETOK-FAMILY-MANAGED` profile unchanged.
2. Use manual Cloudflare One Agent enrollment on Android.
3. Authenticate with a dedicated technical integration identity reserved for this device enrollment. The actual identity value/credential stays outside Git.
4. Before enrollment, inventory existing devices/registrations so the post-enrollment object can be identified by deterministic pre/post delta plus Android/provider facts.
5. After enrollment, persist only stable provider IDs required for binding; do not persist email, display name, tokens, secrets, IP history or health telemetry in desired state.

If the current enrollment permissions do not safely allow this identity without a shared-account blast-radius change, STOP before enrollment. A separate narrowly scoped provider-auth mutation must then be designed and authorized.

## Safe-selector boundary

ST-DEV-001 creates evidence required for later scoping but MUST NOT claim safe Gateway selector completion.

Reasons:

- the Cloudflare account is shared;
- the existing device profile selector is broader than one family/device;
- manually enrolled Android does not receive an administrator-supplied `unique_client_id` because Cloudflare documents that capability as managed-deployment-only;
- the later enforcement Story must prove which Cloudflare selector can isolate Familia Ulate León traffic before any policy apply.

The following are acceptable outputs of this Story:

- real SETOK device subject;
- real Cloudflare device/registration binding;
- provider-observed Cloudflare device ID(s);
- evidence about profile assignment and connectivity;
- explicit `SAFE_SELECTOR_NOT_YET_PROVEN` status.

## Provider mutation boundary

This Story authorizes no mutation during preflight.

A later explicit implementation GO may authorize only the minimum mutations required for the physical device enrollment itself. It does NOT authorize Gateway policy mutation or broad enrollment-policy changes.

Any need to create/change shared device-enrollment permissions, login methods, service tokens, device profile rules or Gateway policy is a Stop Condition unless separately added to the Work Order and explicitly authorized.

## Registry invariants

- exactly one new `device` subject;
- subject belongs to the existing first-family tenant;
- internal subject ID is independent from Cloudflare identifiers;
- exactly one active Cloudflare `device_enrollment` binding for the new subject after successful enrollment;
- provider identifiers are stored only in `external` binding data;
- no email/name/secret/token in desired registry or evidence;
- no human_kind on a device subject;
- adult human subjects remain unchanged;
- existing integrations/resources/bindings remain unchanged except for the new device subject and device binding;
- no Child login or domain authorization is introduced.

## Required validation

- `PROJECT_SCOPE_OK`;
- exact Authorized Base lineage;
- pre-enrollment Cloudflare inventory captured;
- no pre-existing device is mistaken for the target;
- physical target confirms Android/expected device characteristics;
- exactly one new internal device subject;
- successful manual Cloudflare enrollment or controlled STOP before mutation;
- deterministic identification of the newly enrolled Cloudflare device/registration;
- binding schema/registry validation PASS;
- `SETOK-FAMILY-MANAGED` observed for target or mismatch reported as STOP/FIX, never silently changed;
- Traffic + DNS / WARP connected state observed;
- repeated reconciliation returns same semantic binding result;
- Gateway policy fingerprint unchanged;
- Default profile unchanged;
- existing managed profile unchanged;
- no unrelated device/resource mutation;
- PII/secrets scan PASS;
- safe selector explicitly remains NOT PROVEN;
- rollback/offboarding plan documented.

## Rollback / offboarding contract

Rollback must distinguish:

1. SETOK desired binding retirement;
2. Cloudflare registration/device revocation or deletion;
3. local Android client disconnection/uninstall where appropriate;
4. prevention of automatic re-registration by removing/revoking the enrollment identity's authorization when permanent offboarding is intended.

Provider deletion alone is not treated as permanent offboarding because an authenticated client can create a new registration.

## Product Input Gate

NOT REQUIRED.

The frozen architecture already determines the Android platform, device class, Family Link + Cloudflare split, no Android MDM, and separation of human/device identity. The enrollment identity mechanism is a technical implementation detail and must not alter product semantics.

## Risk

RED — provider enrollment/authentication plus physical endpoint state in a shared Cloudflare boundary. The operation is reversible but has external-state and shared-account blast-radius risk; mutation must be tightly gated.

## Acceptance criteria

- one real provider-neutral Android device subject exists;
- one real Cloudflare device-enrollment binding exists after verified enrollment;
- provider/device IDs are external bindings only;
- physical device is observed enrolled and connected through the intended Cloudflare profile/mode;
- existing human identities and provider resources are not repurposed as device identity;
- no Gateway enforcement policy is applied/changed;
- no Android MDM is introduced;
- no child login is introduced;
- safe selector remains explicitly unresolved until later scoped-enforcement validation;
- rollback/offboarding semantics are documented and testable;
- no PII/secrets in Git/evidence.
