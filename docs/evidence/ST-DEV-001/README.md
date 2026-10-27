# ST-DEV-001 r2 — Evidence

**Terminal state:** `DEVICE_ENROLLED / DEVICE_BOUND / SAFE_SELECTOR_NOT_YET_PROVEN`. No Gateway policy is applied.

All provider reads were made by `scripts/st-dev-001/Invoke-StDev001.ps1` with the ST-CF-001 token, using HTTP GET only. The only provider mutation in this Story was the handset's own registration, created by the supported manual Cloudflare One Agent flow.

## History (preserved)

| Step | Commit | Result |
|---|---|---|
| r1 Stage A | `74cb833` (feature/st-dev-001) | CONTROLLED STOP: no enrollment permissions. Resolved by ST-CF-002. |
| r2 Stage A + B | `316db03` | PASS; device subject `android-01` |
| r2 Stage D stop | `dca1007` | CONTROLLED STOP: device-class mismatch. Observed `Redmi Note 13 Pro+ 5G (23090RA98G)`, documented "Xiaomi Redmi Note 14 Pro". |
| Target correction | `ab6faa5` | PO confirmed the enrolled handset is the intended device. Story and Work Order now say `Redmi Note 13 Pro+ 5G (23090RA98G)`; the stop is RESOLVED. |
| r2 Stage D + E | this commit | Bound, reconciled ×2, immutability proven |

## Files

| File | Content |
|---|---|
| `20261027T003150-snapshot-pre.json` | Stage A: 15 surface fingerprints, enrollment-authorization reconciliation, 0 devices / 0 registrations, registry with 0 device subjects / 0 bindings |
| `20261027T003158-stage-a-decision.json` | Stage A gate, 19 checks: PASS. No shared mutation required. |
| `20261027T003159-stage-b-registry-validation.json` | Device subject `sub_01M5Y0XYAMFT3MXRRJV5MFBY3N` (`android-01`, no `human_kind`): PASS |
| `20261027T154319-snapshot-post.json` | After the manual enrollment |
| `20261027T154346-stage-d-identification.json` | Sanitized pre/post delta: 1 new physical device and 1 registration, same id. Records the original model mismatch. |
| `20261027T154906-stage-d-registry-validation.json` | Registry after the binding: PASS |
| `20261027T154954-stage-d-reconcile.json` | Desired vs observed ×2: `MATCH`, `deterministic: true` |
| `20261027T155008-snapshot-final.json` | Final read-only snapshot |
| `20261027T155009-compare-pre-final.json`, `…-compare-post-final.json` | Immutability comparisons |

## Identification (deterministic)

Stage A showed 0 physical devices and 0 registrations. After enrollment there is exactly **one** new physical device and **one** new registration. They share the id `01a17f4d-0062-19de-b716-1df58125a3d4`, the registration's `device.id` is that physical device, and it was created after the Stage A snapshot.

Platform facts: `android`, model `23090RA98G` / `Redmi Note 13 Pro+ 5G`, registration type `warp`, tunnel `masque`.

Identification does not rely on model or name alone.

## Binding

| Item | Value |
|---|---|
| Device subject | `sub_01M5Y0XYAMFT3MXRRJV5MFBY3N`, alias `android-01`. Provider-neutral and unchanged since Stage B. |
| Binding | `bnd_01M5ZND7V8TK28E2V23Z4MRFEJ`, `device_enrollment`, `ACTIVE`, source `ST-DEV-001` |
| Integration | `int_01M5VBRV516Z3FXT98V4G6KT5N` (Cloudflare, shared) |
| `external` | `physical_device_id` and `registration_id` only. Both are `01a17f4d-0062-19de-b716-1df58125a3d4`. |

The binding stores none of the following: user email, user name or user id, public IP, serial number, registration public key, virtual IPv4/IPv6, or `gateway_device_id`. The schema was not changed. Running `Bind` again returns `NONE`, so no duplicate is created.

## Reconciliation (×2, identical)

All 12 checks are true in both runs:
- the binding exists once;
- the physical device and the registration are present, and the registration points to the device;
- Android, with the approved model;
- `warp` registration and MASQUE tunnel;
- **the observed profile is `SETOK-FAMILY-MANAGED` (`994b430f…`), not Default and not deleted**;
- the managed profile is Traffic + DNS (`warp`) with the switch locked;
- not revoked;
- it is the only device in the account.

**Connectivity:** the provider shows an active registration over a MASQUE tunnel, assigned to the Traffic + DNS profile. The PO observed `Connected — Your internet is protected` on the handset. The Cloudflare API does not expose live client toggle state without DEX, so that last point is a human observation.

## Immutability / blast radius (pre → final, post → final)

All 15 surfaces are **unchanged**:
- Gateway rules, lists and configuration;
- device settings;
- the Default profile, `SETOK-FAMILY-MANAGED` and all device profiles;
- the Access organization;
- identity providers (One-time PIN only);
- Access apps, the ST-CF-002 enrollment app and Access policies;
- Access groups;
- service tokens (0);
- posture rules.

The ST-CF-002 enrollment authorization reconciliation is identical before and after.

- **Device delta:** +1 physical device and +1 registration (the target), 0 removed. There were no pre-existing devices, so no unrelated device could have changed.
- **Registry delta:** +1 device subject (Stage B) and +1 `device_enrollment` binding. The 2 adult subjects and the 5 earlier bindings are unchanged.
- **PII scan:** no email address, public IP, serial number, key or virtual IP appears in the evidence or the registry. The enrollment mailbox occurs 0 times.

## Safe selector

`SAFE_SELECTOR_NOT_YET_PROVEN`. A bound Cloudflare device id is evidence for a future scoped-enforcement decision, not proof of isolation.

Note: `SETOK-FAMILY-MANAGED` still matches every Android/iOS device in the shared org. ST-POL-001 and ST-POL-002 plans remain `APPLY_BLOCKED`.

## Rollback / offboarding (documented, not executed)

1. **SETOK:** set binding `bnd_01M5ZND7V8TK28E2V23Z4MRFEJ` to `RETIRED` with `retired_on`. Retire subject `android-01` only if the device leaves the family.
2. **Cloudflare:** revoke, then delete registration `01a17f4d-0062-19de-b716-1df58125a3d4` and the physical device. This needs separate TD authorization and a token with device edit.
3. **Handset:** in Cloudflare One Agent, disconnect and log out (the switch is locked, so an admin override or revoke is needed), or uninstall the app. Remove the Android VPN profile if it remains.
4. **Enrollment authorization:** to permanently prevent re-registration, remove the `family-enrollment-01` include from policy `c991f7f4…`, or delete that policy and the warp app `51a1308a…`. This affects all future SETOK Family enrollment.

**Cloudflare deletion alone is not permanent offboarding.** A client that can still authenticate through the enrollment policy creates a new registration.
