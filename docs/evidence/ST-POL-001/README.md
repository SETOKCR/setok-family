# ST-POL-001 — Evidence

All evidence was produced by `scripts/st-pol-001/Invoke-StPol001.ps1`, which was run twice as independent processes. The contract is described in `infra/policy/README.md`.

**Terminal state:** `DESIRED / COMPILED / PROVIDER_CAPABILITY_VERIFIED`. Apply status is **BLOCKED**, and nothing is APPLIED.

## Files

| File | Content |
|---|---|
| `20261026T093720-discovery.json`, `20261026T093737-discovery.json` | Read-only Gateway categories (34 parents and their subcategories, with id, name and class), the 2 pre-existing Gateway rules (`Do Not Inspect`, `Default deny for private traffic`, both unrelated to SETOK Family), the `SETOK-FAMILY-MANAGED` profile, and fingerprints of rules, profiles, Gateway configuration and categories taken before and after |
| `20261026T093720-compile.json`, `20261026T093737-compile.json` | Compiled plan (run 1), the run 2 hash, and input hashes |
| `20261026T093720-tests.json`, `20261026T093737-tests.json` | Precedence, decision, fail-closed and negative tests, plus the summary |

## Compiled plan (identical in both processes, two compilations each)

The plan's sha256 is `3e7e3fda5ca8762955d2d050b7c5fb85b8505f7d63c511f73e2a4974758241c9`.

| Order | Planned rule | Action | Traffic (provider facts, compiled only) | Controls |
|---|---|---|---|---|
| 1 | `SETOK-FAMILY first-family baseline threats` | block | `any(dns.security_category[*] in {80 117 131})` | C2/botnet, malware, phishing |
| 2 | `SETOK-FAMILY first-family baseline content` | block | `any(dns.content_category[*] in {2 99})` | adult themes, gambling |
| 3 | `SETOK-FAMILY first-family baseline safe-search` | safesearch | all DNS queries in scope | SafeSearch |
| 4 | `SETOK-FAMILY first-family baseline youtube-restricted` | ytrestricted | all DNS queries in scope | YouTube Restricted |

- Baseline controls: **7/7** resolved.
- The scope is `all_device_subjects_of_tenant`. It resolves to **0** device subjects, so there is no identity selector and no global rule.
- The plan records four apply blockers: `NO_ENROLLED_DEVICE_BINDING`, `SAFE_SELECTOR_NOT_PROVEN`, `PROVIDER_MUTATION_NOT_AUTHORIZED` and `PLAN_ENTITLEMENT_UNVERIFIED`.

**Finding:** Gambling (99) belongs to a `premium`-class category. The ST-CF-001 token cannot read the account plan; `/subscriptions` returns 403. Entitlement is therefore recorded as unverified, and it is an explicit apply precondition. The control is kept, not dropped.

The DNS actions (`block`, `safesearch`, `ytrestricted`) come from Cloudflare's documented Gateway DNS policy actions; there is no read API that lists actions. The categories were verified against live discovery.

## Tests (all as expected)

- **Legitimate constructs pass (5):** Standard, Restricted, temporary override, recurring schedule and Essential Services.
- **Decisions (6):**
  - An essential domain categorized phishing gives `BLOCK/security_threat_baseline`.
  - An essential messaging domain during restricted mode gives `ALLOW/essential_services`.
  - A temporary override on social media gives `ALLOW/temporary_override`.
  - A temporary override cannot reach gambling: `BLOCK/mandatory_safety_restriction`.
  - Malware and C2 under every construct give `BLOCK/security_threat_baseline`.
- **Fail-closed compilation (11, all FAIL):**
  - malware control removed
  - phishing not BLOCK
  - C2 mapping missing
  - gambling category unresolved
  - category not blockable
  - YouTube action unsupported
  - provider ID in domain intent
  - device scope invented
  - global scope requested
  - tenant not in registry
  - baseline overridable
- **Precedence violations (6, all FAIL):**
  - Essential Services exempting malware or phishing
  - temporary override disabling the threat baseline
  - Standard mode weakening SafeSearch
  - Restricted mode allowing adult content
  - a schedule allowing gambling
  - a schedule disabling malware

## Read-only proof

- Cloudflare was accessed with **HTTP GET only**, using the existing ST-CF-001 token: categories, rules, device policies, Gateway configuration, and the `/subscriptions` probe, which returned 403.
- The static scan of the script found 0 write verbs and 0 non-GET HTTP calls.
- The fingerprints of rules, profiles, configuration and categories were identical before and after each run, and across both runs.
- `SETOK-FAMILY-MANAGED` and the Default profile were not modified.
- 0 device subjects and 0 device bindings were created; the registry was unchanged.
- The PII/secret scan is clean: no names, emails, tokens or credentials.
