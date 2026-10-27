# ST-DEV-001 — Independent Check

## Decision

**PASS WITH CONDITIONS**

## Scope reviewed

`ST-DEV-001 — Establish first Android device enrollment and provider binding`

The unit introduces the first real device subject and the first real provider device binding for SETOK Family. It also causes external state on a physical Android endpoint and Cloudflare Zero Trust, so the RED classification is appropriate.

## Architecture fit

PASS.

The Story preserves the frozen architecture:

- Android uses Google Family Link + Cloudflare One Client;
- ManageEngine is not introduced on Android;
- device identity remains separate from human identity;
- Cloudflare remains a replaceable enforcement provider;
- internal SETOK device ID remains provider-independent;
- provider state and desired state remain separate;
- Gateway enforcement apply remains a later gate.

## Mandatory conditions

1. **No human/device identity collapse.** The Cloudflare enrollment credential/identity is an operational integration mechanism only. It must not become the SETOK internal device ID, a Child login, an adult family member, or a domain authorization principal.

2. **No real enrollment identity in Git.** Email, OTP, password, token, service credential or equivalent enrollment secret must stay outside Git/evidence. Versioned state may use only an opaque alias.

3. **One-device cardinality.** Exactly one new Android device subject and at most one ACTIVE Cloudflare `device_enrollment` binding for it are permitted by this Story.

4. **Pre/post provider inventory required.** The target Cloudflare device/registration must be established by evidence, not guessed from model/name alone. Existing devices must not be modified or rebound.

5. **Shared-account mutation is narrow.** Manual device registration is the intended provider mutation. If enrollment requires changing shared enrollment permissions, login methods, service tokens, profile match rules or other shared Cloudflare controls, STOP before that mutation and return to Technical Director review.

6. **Existing profile immutable.** `SETOK-FAMILY-MANAGED` may be observed/matched, but its configuration and match expression must not change in ST-DEV-001.

7. **Gateway immutable.** No Gateway DNS, Network or HTTP policy/list/rule mutation is authorized.

8. **Default profile immutable.** No change to Cloudflare Default device profile.

9. **No Android MDM.** Do not introduce ManageEngine, Android Enterprise MDM, or a managed deployment merely to obtain `unique_client_id`.

10. **Safe selector must remain unresolved.** A real Cloudflare device ID/registration is evidence for a future selector decision, not proof that Gateway can safely isolate the family. Story terminal state must retain `SAFE_SELECTOR_NOT_YET_PROVEN`.

11. **No `unique_client_id` fabrication.** Do not manufacture or version an MDM-style Device UUID and claim Cloudflare is presenting it. Current Cloudflare documentation says administrator-supplied `unique_client_id` on Android requires managed deployment.

12. **Profile/mode observation required.** Successful enrollment is insufficient by itself. Evidence must confirm the Cloudflare registration/device state and that the intended profile/mode is observed, or surface a mismatch without silently correcting shared provider configuration.

13. **Rollback is multi-layer.** Offboarding must account for SETOK binding retirement, Cloudflare registration/device revocation/deletion, local client state, and revocation/removal of enrollment authorization when permanent re-registration prevention is intended.

14. **Provider deletion is not permanent offboarding.** Evidence/docs must explicitly preserve Cloudflare's documented re-registration behavior.

15. **Registry evolution minimal.** If provider-binding schema changes are required for device metadata, changes must be minimal, provider-neutral and backward-compatible with existing ST-PB-001 records. No runtime database/domain-core implementation.

16. **No fabricated Child relation.** This Story may create the device subject but must not invent a Child domain object or Guardian↔Child relationship merely because the physical device belongs to a child. That belongs to domain work when the corresponding canonical entity exists.

17. **PII/secret scan mandatory.** Versioned evidence must not contain the real enrollment email, display names, OTPs, tokens, secrets, IP history or other unnecessary personal/provider telemetry.

## Independent risk assessment

### Reversibility

Moderate. SETOK desired state can be reverted and Cloudflare registration/device state can be revoked/deleted, but permanent offboarding requires also preventing re-authentication.

### Blast radius

Potentially high if shared Cloudflare enrollment/profile controls are changed. The Story avoids this by making any such need a Stop Condition.

### Data/state

Moderate. First durable external device binding is introduced.

### Security/authentication

High. Enrollment authentication and endpoint VPN state are involved.

### Contract impact

Moderate. Provider-binding registry evolves from zero-device to real-device state.

**Result: RED.**

## Product Input Gate

NOT REQUIRED.

No unresolved product-semantic choice was found. Exact credentials and physical interaction are operational inputs, not product decisions.

## Required terminal evidence

A candidate may be accepted only if it shows either:

### Successful path

- `PROJECT_SCOPE_OK`;
- exact Authorized Base lineage;
- one internal Android device subject;
- one observed Cloudflare device/registration binding;
- intended profile/mode observed;
- Cloudflare connected state observed;
- existing Gateway/profile fingerprints unchanged;
- repeated binding reconciliation deterministic;
- safe selector explicitly NOT PROVEN;
- rollback/offboarding documented;
- no PII/secrets.

### Controlled-stop path

If safe manual enrollment is impossible without a shared-account mutation outside the Work Order, execution must STOP before that mutation with provider evidence and a precise remediation proposal.

## Independent Check outcome

**PASS WITH CONDITIONS.** No architecture change is required. All conditions above are mandatory Work Order constraints.
