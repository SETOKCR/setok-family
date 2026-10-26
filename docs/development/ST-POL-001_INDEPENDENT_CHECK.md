# ST-POL-001 — Independent Check

## Result

PASS WITH CONDITIONS

## Review focus

This check reviews the baseline policy contract as an architecture/security boundary. Provider mutation is explicitly out of scope.

## Mandatory conditions

1. Baseline Policy Intent is provider-neutral and tenant-scoped.
2. Internal policy identifiers are independent from Cloudflare rule/category identifiers.
3. Minimum baseline includes malware, phishing, command-and-control/botnet, adult content, gambling, SafeSearch and YouTube Restricted.
4. Threat baseline is structurally non-overridable by Standard, Restricted, recurring schedules, temporary overrides or Essential Services.
5. Essential Services can only survive ordinary parental restrictions; they cannot allow known threat categories.
6. Compilation targets DNS Gateway semantics only for this Story unless read-only discovery proves another capability is required; no HTTP inspection/root-certificate dependency may be introduced silently.
7. Cloudflare category/rule IDs are observed/provider facts and remain outside SETOK domain intent.
8. Compilation must fail closed on unresolved mandatory provider capability/category mapping. It must not silently omit a baseline control.
9. Shared Cloudflare account is treated as unsafe for global policy mutation until a safe family/device selector exists.
10. No Cloudflare create/update/delete/enable/disable/reorder calls.
11. No Device Profile mutation; `SETOK-FAMILY-MANAGED` remains unchanged.
12. Zero device subjects/bindings created by this Story.
13. Desired, compiled and observed representations are distinct.
14. Compiled output must be deterministic/idempotent for identical desired intent and provider capability input.
15. Negative tests must include attempted threat-baseline override, Essential Services bypass of threat baseline, missing mandatory category mapping, provider-ID leakage into domain intent and global/unscoped apply attempt.
16. Evidence must not contain API tokens, credentials or human PII.
17. No rule may be described as APPLIED/ACTIVE in provider state; execution result must clearly say provider mutation = NO.

## Architecture observations

- The current sequence is safe only if `Baseline policies` means contract + compilation readiness, not account-wide enforcement before enrollment.
- Cloudflare DNS policies currently provide Block, Safe Search and YouTube Restricted actions and category selectors; numeric provider IDs should be resolved by the adapter/discovery layer rather than encoded into Policy Intent.
- Full HTTP inspection is appropriately deferred because it has device certificate/decryption prerequisites.
- Anti-bypass remains a later evidence-driven device validation surface and must not be claimed complete here.

## Stop / escalation conditions

Escalate if any mandatory baseline control cannot be represented using currently supported provider capabilities, if family-safe scoping unexpectedly becomes a requirement for read-only planning, or if the implementation needs to mutate provider state.
