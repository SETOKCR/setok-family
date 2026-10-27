# ST-POL-002 — Evidence

All evidence was produced by `scripts/st-pol-002/Invoke-StPol002.ps1`, run twice as independent processes. The script makes **no network calls**. Provider category facts come from the ST-POL-001 read-only discovery evidence (`docs/evidence/ST-POL-001/20261026T093737-discovery.json`).

**Terminal state:** `DESIRED / COMPILED / APPLY_BLOCKED`. Nothing is APPLIED.

## Files

| File | Content |
|---|---|
| `infra/policy/modes.schema.json` | Provider-neutral schema for modes, overlays and actions. Only the leisure categories can be addressed, so baseline controls are not reachable. |
| `infra/policy/modes.desired.json` | The PO-approved configuration, tenant `tnt_01M5VBRV28NGNS5PX6Y1W2XJV8`, bound to baseline `pol_01M5WDGX38EV8110CN2BH1RKRQ` |
| `infra/policy/cloudflare/dns-adapter.modes.json` | Adapter data: leisure-category names, scoping for the SafeSearch and YouTube rules, and rule-order rationale |
| `20261026T131706-*.json`, `20261026T131709-*.json` | `effective-decisions` (12 fixed-time scenarios), `compiled-plans` (one plan per scenario), `tests` (111 results, summary, input hashes) |

Both processes produced the same outputs hash: `487a442e145b4dcf75a253eb8d1b6d85a27a7241d4a3e496f4d1ff5eea524e8d`. The suite also computes everything twice inside each process.

## Product semantics (exactly as approved)

| | social_media | gaming | entertainment_streaming | Notes |
|---|---|---|---|---|
| STANDARD | – | – | – | baseline only |
| RESTRICTED | BLOCK | BLOCK | BLOCK | |
| STUDY | BLOCK | BLOCK | BLOCK | expiry required, Essential Services preserved |
| ALLOW_SOCIAL | ALLOW | – | – | expiry required; may override **only** `mode:RESTRICTED` and `overlay:STUDY` |
| PAUSE_ENTERTAINMENT | BLOCK | BLOCK | BLOCK | expiry required, Essential Services preserved |
| CLEAR_TEMPORARY | action | | | removes temporary overlays; preserves persistent mode, baseline and recurring schedules |

The validator compares the configuration against this table and fails on any difference.

## Composition rules

The precedence order follows ARCHITECTURE §10.4:

1. security_threat_baseline
2. mandatory_safety_restriction
3. essential_services
4. emergency_parent_action (boundary only)
5. temporary_override
6. active_mode
7. recurring_schedule (boundary only)
8. default_family_policy

A higher layer only wins for a category it actually has an effect on.

- **Baseline:** the seven ST-POL-001 controls are always emitted unchanged, with `overridable: false`.
- **Overlay-on-overlay conflicts** are resolved only by explicit `conflict_rules`. A missing or duplicated winner fails closed, both when the configuration is validated and during composition.
  - The approved rules are ALLOW_SOCIAL beats STUDY, and PAUSE_ENTERTAINMENT beats ALLOW_SOCIAL.
  - The second rule follows from the approved wording "ALLOW_SOCIAL may override only RESTRICTED or STUDY".
- **Same-action overlays:** the winner is the latest-expiring instance. Ties break by overlay type, then by internal `ovl_` id, so the result does not depend on input order (tested).
- **Overlay ALLOW over a mode BLOCK** applies only when that mode is listed in the overlay's `may_override`.
- **Expiry boundary:** an overlay is active for `activated_at <= t < expires_at`. At `expires_at` the decision falls back to the underlying persistent mode.
- **Essential Services:** a request flagged as essential is allowed through leisure blocks from layers 5–8. It is still blocked by the threat baseline and by mandatory safety restrictions. Essential Services may exempt leisure categories only.

Each Effective Policy Decision row records:
- `category`, `decision` (ALLOW, BLOCK or FORCE), `source` and `source_ref`, which together give the winning reason;
- `overridden`, the lower-precedence or losing sources;
- `expires_at` of the winning overlay, and `next_change_at`;
- `essential_services` behavior.

The result also carries `persistent_mode`, `underlying_persistent_mode`, `active_overlays` and `expired_overlays_ignored`.

## Key scenario results (fixed timestamps, 2026-11-02 UTC)

| Scenario | social_media | gaming | entertainment_streaming |
|---|---|---|---|
| S01 STANDARD | ALLOW default | ALLOW default | ALLOW default |
| S02 RESTRICTED | BLOCK RESTRICTED | BLOCK RESTRICTED | BLOCK RESTRICTED |
| S03 RESTRICTED + ALLOW_SOCIAL @15:10 | **ALLOW ALLOW_SOCIAL** (overrode RESTRICTED, expires 15:30) | BLOCK RESTRICTED | BLOCK RESTRICTED |
| S04 same @15:30 (expiry) | BLOCK RESTRICTED | BLOCK RESTRICTED | BLOCK RESTRICTED |
| S05 STANDARD + STUDY @15:05 | BLOCK STUDY | BLOCK STUDY | BLOCK STUDY |
| S06 STUDY expired @16:00 | ALLOW default | ALLOW default | ALLOW default |
| S07 STUDY + ALLOW_SOCIAL @15:15 | **ALLOW ALLOW_SOCIAL** | BLOCK STUDY | BLOCK STUDY |
| S08 same after social expiry @15:40 | BLOCK STUDY | BLOCK STUDY | BLOCK STUDY |
| S09 RESTRICTED + PAUSE + ALLOW_SOCIAL | **BLOCK PAUSE** (ALLOW_SOCIAL overridden) | BLOCK PAUSE | BLOCK PAUSE |
| S10/S11 overlapping STUDY, STUDY and PAUSE | the latest-expiring STUDY instance wins; it stays blocked after the others expire | | |
| S12 overlay not yet active | ALLOW default | ALLOW default | ALLOW default |

CLEAR_TEMPORARY applied to S07 gives STANDARD, and applied to S03 gives RESTRICTED. Both results are identical to the plain persistent mode. The persistent mode, the baseline file hash and the schedule definitions are unchanged.

## Compiled plan (per scenario, APPLY_BLOCKED)

The plan has six rules in this order: threats → content → essential-services-allow (empty catalog, omitted) → leisure-block (only the categories whose effective decision is BLOCK) → SafeSearch → YouTube Restricted.

- `Test-Plan` rejects any plan that isn't APPLY_BLOCKED, any plan containing APPLIED, any global rule or invented selector, any allow rule placed before the baseline blocks, and an essential allow that doesn't exclude the threat and mandatory categories.
- Plan blockers:
  - `NO_ENROLLED_DEVICE_BINDING`
  - `SAFE_SELECTOR_NOT_PROVEN`
  - `PROVIDER_MUTATION_NOT_AUTHORIZED`
  - `PROVIDER_ORDERING_SEMANTICS_UNVERIFIED_ON_DEVICE`
  - `PLAN_ENTITLEMENT_UNVERIFIED`: Gaming, Video Streaming and Audio Streaming, like Gambling, are premium-class.

**Refinement over ST-POL-001:** Gateway DNS rules are first-match. The ST-POL-001 plan targeted SafeSearch and YouTube Restricted at "all DNS queries in scope", which could end evaluation before later rules. This plan scopes them to the Search Engines category and to YouTube domains, and places leisure blocks before them, so a blocked streaming service is blocked rather than rewritten. Provider ordering is still to be verified on a test device before apply.

## Test results: 111 of 111 as expected

| Group | Checks |
|---|---|
| schema and semantics | the approved configuration validates |
| composition and explanation | 36 category decisions across 12 scenarios, plus the explanation checks for overridden source, expiry and underlying mode |
| baseline non-regression | 12 of 12 scenarios emit all 7 baseline controls unchanged |
| compilation | 12 of 12 plans COMPILED, APPLY_BLOCKED, with the ordering invariants holding |
| conflict | PAUSE beats ALLOW_SOCIAL; the latest-expiring instance wins; independent of input order |
| clear-temporary | restores immediately; preserves the persistent mode, baseline and schedules |
| essential-services | an essential service is allowed through RESTRICTED and STUDY leisure blocks; an essential service categorized phishing, malware or C2 is BLOCKED by baseline; one categorized gambling is BLOCKED by mandatory safety; an Essential Services contract that exempts malware FAILS |
| schedule-boundary | a schedule applies under STANDARD; a schedule cannot beat RESTRICTED; a schedule cannot touch the baseline |
| fail-closed (30, all FAIL) | STANDARD or RESTRICTED weakening baseline; overlays disabling malware, phishing, C2, adult, gambling, SafeSearch or YouTube; unknown overlay (in config and in state); provider ID or expression in intent; conflicts without a winner or with two; ALLOW_SOCIAL widened or touching gaming; RESTRICTED differing from approved; overlay without required expiry, with no expiry, or expiring before activation; precedence reordered; CLEAR_TEMPORARY submitted as an overlay; invented device or family selector; unknown mode; non-ULID overlay id; nondeterministic runtime conflict; plan marked APPLIED; allow rule before baseline; global rule; unresolved leisure category |
| determinism | identical hash on repeated runs |

## Provider boundary and privacy

- The static scan found no network calls (`networkCallsInScript: 0`), so the script made no Cloudflare call of any kind. No Gateway rule, `SETOK-FAMILY-MANAGED` or the Default profile was touched.
- 0 device subjects and 0 device bindings exist; the registry was unchanged.
- No PII, credentials or tokens appear in any file.

## Open product note (not blocking)

Overlay durations are bounded by a required explicit `expires_at`, but the approved semantics define no maximum duration, so none is enforced. Examples in the architecture are 30 minutes, 1 hour and 2 hours. A product cap, if wanted, belongs in a later Story.
