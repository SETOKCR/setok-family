# Policy Intent (contract v1) and Cloudflare DNS adapter

This directory was introduced by ST-POL-001. It keeps four representations strictly separate:

| Representation | Location | Contents |
|---|---|---|
| Domain desired intent | `baseline.desired.json`, schema `policy-intent.schema.json` | SETOK semantic controls only, such as `threat.malware` = BLOCK. No provider names, syntax, numbers or UUIDs. |
| Provider adapter data | `cloudflare/dns-adapter.json` | Maps each semantic control to a Cloudflare DNS selector and action **by provider category name**. It holds no numeric IDs. |
| Observed provider capabilities | `docs/evidence/ST-POL-001/*-discovery.json` | Read-only Gateway categories with their IDs and classes, the pre-existing rules, and fingerprints. |
| Compiled provider plan | `docs/evidence/ST-POL-001/*-compile.json` | A deterministic DNS rule plan in state `COMPILED`, apply status `BLOCKED`. |

The compiler and tests are in `scripts/st-pol-001/Invoke-StPol001.ps1`.

## Baseline semantics

- The baseline sits in layers 1–2 of ARCHITECTURE §10.4:
  - Security / Threat Baseline: malware, phishing, C2/botnet
  - Mandatory Safety Restrictions: adult content, gambling, SafeSearch, YouTube Restricted
- The baseline is `overridable: false`.
- Every construct below those layers can only add restrictions or allow *ordinary* categories. This covers Essential Services (layer 3), temporary override (5), modes (6) and schedules (7).
  - Any effect that would ALLOW, UNFORCE, DISABLE or BYPASS a baseline control is rejected.
  - Any `exempt_from` that names a baseline control is rejected.
- Essential Services can survive ordinary restrictions, but a request that hits a threat category is always `BLOCK / security_threat_baseline`.

## Fail-closed compilation

If any mandatory control is missing, has the wrong action, has no adapter mapping, resolves to zero or several provider categories, falls in a non-blockable class, or uses an undocumented action, the whole compilation fails. No partial plan is produced and no protection is silently omitted.

## Apply prerequisites (for a future provider-mutation Story)

All of these must hold before any Gateway rule is created:

1. **Enrollment:** at least one ACTIVE `device_enrollment` binding for the tenant exists in `infra/bindings/registry.desired.json`, backed by enrollment evidence.
2. **Safe selector:** a family/device identity or device selector is proven to match only that tenant's enrolled devices. The Cloudflare account is shared, so no global or unscoped rule is allowed.
3. **Blast radius:** the plan is reviewed against the pre-existing Gateway rules recorded in discovery. Rule precedence is chosen so that unrelated SETOK traffic is unaffected, and a dry run or targeted test device confirms it.
4. **Plan entitlement:** `content.gambling` resolves to a `premium`-class category. The account plan's entitlement must be verified, for example with a billing-read token or Cloudflare support. If it isn't entitled, apply must fail closed and must not drop the control.
5. **Rollback:** each created rule is identified by name and id, and deleting exactly those rules restores the prior state.
6. **Authorization:** a separate Work Order explicitly authorizes provider mutation.

HTTP inspection, root certificates, AV scanning and the anti-bypass work (DoH/DoT/VPN) are not part of this plan. They have not been verified.
