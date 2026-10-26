# ST-CF-001 — Evidence

Non-secret evidence for the Cloudflare Zero Trust pilot foundation. Snapshots were produced by
`scripts/st-cf-001/Invoke-StCf001.ps1`. The desired state lives in `infra/cloudflare/st-cf-001.desired.json`.

## Target identity (verified before mutation)

- Account: `Itadmin@setok.cr's Account` (`c2120c89f39b804e7882661f7464e89f`). This is the only account the ST-CF-001 token can reach.
- Zero Trust organization: `setok.cloudflareaccess.com`. It existed before this Story and was not modified.
- Boundary: the account is SETOK's shared corporate platform. On 2026-10-26 the Product Owner authorized SETOK Family to use it for the pilot. The Product Owner also limited ST-CF-001 to creating one isolated custom profile and ruled out any change to the Default profile or other pre-existing resources.

## Timeline

| File | Mode | Result |
|---|---|---|
| `20261025T205019-discover.json` | Discover | One account, existing org, only the Default profile (`019cbbfb-…17d9`) |
| `20261025T205043-plan.json` | Plan | Delta = CREATE `SETOK-FAMILY-MANAGED` |
| `20261025T210251-apply.json` | Apply | CREATE → policy `994b430f-fdf6-4ad9-aa6a-b7564f7133ca` |
| `20261025T210254-verify.json` | Verify | `MATCH`, managedCount = 1 |
| `20261025T210309-apply.json` | Apply (re-run) | `NONE`, idempotent, no duplicate |

The timestamps in the file names are local time (UTC-6). The `observedAt` value inside each file is UTC.

## Observed state (after)

`SETOK-FAMILY-MANAGED` has precedence 100, is enabled, and matches `os.name in {"android" "ios"}`. Its settings:

- `service_mode_v2.mode = warp` (Traffic + DNS)
- `tunnel_protocol = masque`
- `switch_locked = true`
- `auto_connect = 0`
- `allowed_to_leave = false`
- `allow_mode_switch = false`

Non-impact checks:

- The Default profile JSON before CREATE (discover) is identical to the JSON after CREATE (re-run apply `before`).
- The organization is unchanged.
- No other profiles exist.

## Rollback / remediation

```powershell
pwsh -File scripts/st-cf-001/Invoke-StCf001.ps1 -Mode Rollback -AccountId c2120c89f39b804e7882661f7464e89f
pwsh -File scripts/st-cf-001/Invoke-StCf001.ps1 -Mode Verify   # expected: DRIFT, managedCount = 0
pwsh -File scripts/st-cf-001/Set-StCf001Token.ps1 -Remove       # then revoke the token in the Cloudflare dashboard
```

Rollback stays isolated because it does the following:

- refuses to run unless `-AccountId` equals the discovered account;
- selects only the non-default profile named `SETOK-FAMILY-MANAGED`;
- refuses to run if that name matches more than one profile;
- deletes by that profile's `policy_id` (`994b430f-…33ca`), which is different from the Default profile's (`019cbbfb-…17d9`).

Rollback was walked through but not executed, so the foundation remains in place.

## Notes for the Technical Director

- Because the account is shared, the profile selects every Android or iOS device that enrolls in the `setok` org, whichever project it belongs to. Before another project enrolls mobile devices here, it needs a narrower selector, which belongs to a later identity/binding unit.
- MASQUE is configured. Real-device validation is still pending under the later enrollment and MASQUE/captive-portal units.
- Cloudflare's client settings documentation says `auto_connect = 0` together with `switch_locked = true` gives a client that always starts connected and cannot be disconnected. This has not yet been checked on a real device.
- Secrets: the token is stored with DPAPI under `%LOCALAPPDATA%\SETOK\setok-family\` and is never written to the repository or to evidence.
