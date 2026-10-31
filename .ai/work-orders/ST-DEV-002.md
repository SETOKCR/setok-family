# WORK ORDER ST-DEV-002

## Identity

- **Project:** SETOK Family
- **Repository:** SETOKCR/setok-family
- **Story / Work Unit:** ST-DEV-002
- **Purpose:** iPad Standard readiness and capability preflight
- **Execution state:** READY / READ-ONLY PREFLIGHT
- **Risk:** YELLOW
- **Authorized Base:** `abf92a3b7af10145e58077094632853fa8350988`
- **Implementation Branch:** `feature/st-dev-002`
- **Implementation Authorization:** YES — READINESS/PREFLIGHT ONLY
- **Provider Mutation Authorization:** NO
- **Device Mutation Authorization:** NO

## Governance basis

- Story: `docs/stories/ST-DEV-002.md`
- Independent Check: `docs/development/ST-DEV-002_INDEPENDENT_CHECK.md`
- Independent Check decision: `PASS WITH CONDITIONS — READINESS/PREFLIGHT ONLY`
- ST-CF-004 checkpoint integration: `e6ab00751f03474161f328d26d5c9f7c7e996253`
- ST-CF-004 state: Stage A/B accepted; Stage C paused pending physical Redmi access.

## Execution boundary

This Work Order authorizes observation and evidence collection only.

Allowed:

1. repository/project/lineage checks;
2. device-local read-only inspection with Product Owner assistance;
3. screenshots or UI observations supplied by Product Owner;
4. read-only Cloudflare API discovery if useful;
5. local scripts that collect non-sensitive readiness data without changing the device;
6. sanitized evidence committed on `feature/st-dev-002`.

Not allowed:

- no Cloudflare WARP enrollment-policy mutation;
- no WARP enrollment or OTP;
- no Gateway mutation;
- no SETOK provider-binding mutation;
- no MDM enrollment;
- no supervision transition;
- no erase/reset;
- no Screen Time setting change;
- no Apple Family Sharing change;
- no Apple ID change;
- no profile install/remove;
- no change to android-01 or ST-CF-004.

## Required preflight

Before device inspection:

1. `PROJECT_SCOPE_OK`;
2. branch exactly `feature/st-dev-002`;
3. branch descends from Authorized Base;
4. clean working tree;
5. reconstruct ST-CF-004 current checkpoint from Git, not chat memory.

## Required device observations

Using only local/device-visible information and no mutation, determine:

- iPad marketing/model family, without serial/UDID;
- current iPadOS version;
- supervised: YES/NO/UNKNOWN;
- MDM profile present: YES/NO/UNKNOWN;
- Cloudflare One Agent/WARP installed: YES/NO;
- Cloudflare currently enrolled: YES/NO/UNKNOWN;
- Screen Time configured: YES/NO/UNKNOWN;
- Family Sharing / child-control relationship relevant to SETOK: PRESENT/ABSENT/UNKNOWN, without account identifiers;
- whether Standard onboarding appears feasible without MDM and without reset;
- what anti-bypass limitations would remain in that Standard path;
- future technical identity/enrollment prerequisites;
- whether any provider mutation would be necessary to proceed beyond readiness.

## Privacy

Never version or print unnecessary operational PII, including:

- Apple ID/email;
- serial number;
- UDID;
- IMEI;
- phone number;
- public IP;
- recovery information;
- authentication tokens;
- OTP.

Use alias `ipad-01` for the device and, if needed conceptually, `ipad-01-enrollment` for a future technical identity.

## Stop conditions

STOP if:

- scope/lineage mismatch;
- inspection requires changing an iPad setting;
- inspection requires Apple account mutation;
- inspection requires provider mutation;
- inspection requires WARP enrollment;
- inspection requires MDM/supervision/reset;
- sensitive PII would have to be committed;
- ST-CF-004/android-01 state would need to change.

## Evidence

Store sanitized evidence under:

`docs/evidence/ST-DEV-002/`

## Expected terminal

`IPAD_READINESS_PROVEN / STANDARD_PATH_DEFINED / PROVIDER_ENROLLMENT_NOT_AUTHORIZED`

At terminal, STOP and return to Technical Director. No enrollment is authorized by this Work Order.
