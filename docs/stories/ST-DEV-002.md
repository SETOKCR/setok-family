# ST-DEV-002 — iPad Standard readiness and capability preflight

## Status

`DEFINED / PREFLIGHT`

## Purpose

Prepare the first productive iPad endpoint for SETOK Family without interfering with the still-open Android remediation unit `ST-CF-004`.

This unit is intentionally limited to device-local and provider read-only discovery. It does **not** enroll the iPad into Cloudflare, does not change WARP enrollment authorization, and does not introduce MDM.

## Product context

- Product: SETOK Family
- First productive family: Familia Ulate León
- Target platform: iPadOS
- Intended SETOK device alias: `ipad-01`
- Child-first policy remains authoritative: policy intent belongs to the child; device identity is a technical selector/binding concern only.

## Current dependency state

`ST-CF-004` has accepted Stage A and Stage B. Its Cloudflare WARP enrollment policy currently permits only the dedicated `android-01-enrollment` identity and is intentionally waiting for physical access to the Redmi before Stage C.

Therefore ST-DEV-002 MUST NOT broaden or replace that enrollment authorization.

## Scope

### In scope

1. Identify the actual iPad model and iPadOS version from the device.
2. Establish the intended SETOK alias `ipad-01` without storing unnecessary PII.
3. Inventory current device-management state:
   - supervised vs unsupervised;
   - existing MDM enrollment, if any;
   - Screen Time / Family Sharing state relevant to parental control;
   - presence or absence of Cloudflare One Agent / WARP;
   - relevant native restrictions already active.
4. Determine whether Standard-mode onboarding can be performed without MDM and without erasing/resetting the device.
5. Determine what user interaction will be required for a future Cloudflare enrollment.
6. Determine whether a dedicated per-device technical enrollment identity will be required, following the accepted `Child Policy Scope -> Device Set -> Provider Selector Set` model.
7. Produce a capability/readiness matrix for the iPad covering:
   - Cloudflare enrollment feasibility;
   - native Screen Time authority;
   - anti-bypass limitations without supervision/MDM;
   - expected protection-state signals;
   - rollback/offboarding considerations.
8. Preserve all Cloudflare shared surfaces unchanged.

### Out of scope

- no Cloudflare enrollment-policy mutation;
- no WARP enrollment;
- no OTP flow;
- no Gateway rule/list/config mutation;
- no creation or replacement of SETOK provider bindings;
- no MDM enrollment;
- no Apple device erase/reset;
- no supervision transition;
- no Apple ID / Family Sharing mutation unless later separately authorized;
- no policy enforcement apply;
- no changes to `android-01` or ST-CF-004 state.

## Safety constraints

- `PROJECT_SCOPE_OK` is mandatory before execution.
- Do not infer model, OS, supervision or management state from architecture documents; observe the actual device.
- Do not version Apple ID, serial number, IMEI, UDID, public IP, recovery data or other unnecessary PII.
- Cloudflare operations, if used, must be read-only GET operations.
- Any discovery that requires a provider mutation is a STOP condition and must be raised to the Technical Director.
- Any requirement to erase/reset the iPad is a STOP condition for this unit.

## Preflight questions to answer

1. What exact iPad model and iPadOS version are currently in use?
2. Is the device supervised?
3. Is any MDM profile currently installed?
4. Is Screen Time configured, and what is its current authority relationship?
5. Is the iPad already part of Apple Family Sharing / child-account controls relevant to the design?
6. Is Cloudflare One Agent/WARP installed or previously enrolled?
7. Can Standard onboarding proceed without supervision/MDM and without reset?
8. What anti-bypass limitations remain in Standard mode?
9. What future technical identity and Cloudflare enrollment steps will be required?
10. What can safely be executed now while ST-CF-004 Stage C remains paused?

## Expected terminal state

`IPAD_READINESS_PROVEN / STANDARD_PATH_DEFINED / PROVIDER_ENROLLMENT_NOT_AUTHORIZED`

## Next gate

After read-only/device-local evidence is reviewed, the Technical Director will decide whether to:

- authorize a later iPad Standard enrollment unit;
- require additional native-control preparation; or
- defer provider enrollment until Android safe-selector remediation is complete.
