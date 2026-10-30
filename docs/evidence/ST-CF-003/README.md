# ST-CF-003 — Safe-selector discovery (read-only)

**Terminal decision: `SAFE_SELECTOR_NOT_PROVEN / APPLY_BLOCKED`**

The evidence was produced by `scripts/st-cf-003/Invoke-StCf003.ps1`, which reuses the accepted ST-DEV-001 snapshot functions verbatim and makes HTTP GET calls only (static scan: 0 write verbs). The output is `20261027T162616-discovery.json`. No provider mutation was made.

The identity appears only as `family-enrollment-01`. No email, IP, serial number, key or virtual IP is versioned; the real mailbox occurs 0 times in this evidence.

## 1. Accepted android-01 state: MATCH

All 11 checks are true:
- the subject is `sub_01M5Y0XYAMFT3MXRRJV5MFBY3N` and the binding is `bnd_01M5ZND7V8TK28E2V23Z4MRFEJ`;
- the provider id is `01a17f4d-0062-19de-b716-1df58125a3d4`, the only physical device and registration in the account, and the registration points to that device;
- Android, model `23090RA98G`;
- registration type `warp`, tunnel `masque`;
- assigned profile `SETOK-FAMILY-MANAGED` (not Default);
- 1 active registration, not revoked.

## 2. Exact-identity candidate (`family-enrollment-01`)

| Check | Result |
|---|---|
| android-01 registration identity equals the local operational identity | **true** |
| Active registrations with that identity (including plus-address variants) | **1** |
| Physical devices last seen with that identity | **1** |
| Access users in the whole org / with that identity | 1 / 1 (it has a Gateway seat) |
| Last-seen identity device sessions | only `01a17f4d…a3d4` (IdP: One-time PIN) |
| **Identity is dedicated to one device?** | **NO.** It is the SETOK IT-admin mailbox and the Cloudflare account owner's address. ST-CF-002 records the enrollment infrastructure as intended "for Android and later iPad Standard enrollment". |
| **Enrollment policy still lets that identity create more registrations** | **yes**: the ST-CF-002 allow policy is active |

So today's cardinality is 1 device and 1 registration. However, the identity is **planned for reuse**: the next iPad enrollment, or any WARP client the account owner signs in with, would use the same address. A Gateway `User Email` rule would match that new registration **at the provider immediately**, before any SETOK reconciliation could run.

## 3. Gateway selectors (documentation and API)

| Mechanism | DNS | Network | HTTP | Finding |
|---|---|---|---|---|
| physical device id / registration id / `device.id` | – | – | – | **`DIRECT_DEVICE_ID_SELECTOR_UNSUPPORTED`**. No documented selector exists. `cf_device_id` appears only as block-page/redirect context, not as a matcher. |
| User Email (exact) | ✓ | ✓ (`identity.email`) | ✓ | **SUPPORTED** with the Cloudflare One Client in Traffic + DNS mode; identity is refreshed at login or re-auth. DNS **Block** also matches address variants; DNS **Allow** matches only the exact address. |
| User Name / Group IDs / Group Names / Group Emails / SAML attributes | ✓ | ✓ | ✓ | Supported, but no SETOK group exists. Access rule groups cannot be used in Gateway. |
| Passed Device Posture Checks | not listed in the DNS builder | ✓ | ✓ | DNS policies **cannot** use a posture-based scope |
| Serial-number posture on Android | | | | **UNSUPPORTED** (Cloudflare client checks: ❌ on Android/ChromeOS) |
| Device UUID / `unique_client_id` on Android | | | | Supported **only** with a managed deployment: "It is not possible to assign them manually". That requires Android MDM, which is forbidden by the architecture. |
| Device IP on Android | | | | **UNAVAILABLE**: there is no Device IP check, client certificate is ❌ on Android, and Source IP / internal IP / virtual network do not identify one handset |
| Other Android posture | | | | Only OS version, Require Gateway and Require WARP, none of which identifies this handset |

## 4. Lifecycle invariant: cannot currently be made fail-closed

Required: `1 operational selector identity <= 1 ACTIVE SETOK device subject / 1 active provider registration scope`.

**Detection SETOK can implement** (read-only, every reconcile and before any apply):
1. Resolve the opaque reference to the identity locally.
2. Count active registrations, and physical devices last seen, whose user email or a plus-address variant equals the identity across the whole account. Require exactly 1, and require it to be the bound `registration_id`.
3. Require exactly 1 Access user with that identity.
4. On any other result, mark the binding `ERROR`, refuse to apply, and require removal of the scoped rules.

**Why that is not enough:**
- Gateway evaluates `User Email` at the provider. A second enrollment by the same identity is in scope the moment it registers, so SETOK detection happens *after* the scope has already widened. It is not fail-closed.
- Prevention would need an extra control that the account does not have today. The options are to make the enrollment identity single-use (remove the include after enrollment), which is a shared enrollment-authorization mutation, or a device-unique posture, which Android does not offer without MDM.
- The identity is the account-owner/IT-admin address and is planned for iPad reuse. That violates the "dedicated operational identity" condition of the Independent Check.

`IDENTITY_SCOPED` is the only candidate type. `DEVICE_ID_SCOPED` is not available on Android without MDM.

## 5. Gateway order and precedence

**Current account rules (2 pre-existing, unrelated):**
- `Do Not Inspect` (http, action `off`, precedence 0)
- `Default deny for private traffic` (l4, block, disabled, precedence 10000)

**Phases:** DNS → (egress) → Network → HTTP; HTTP/3 also runs DNS → Network → HTTP.

**Within a phase:**
- Rules use first match by precedence, with lower numbers evaluated first.
- An Allow or Block match stops evaluation in that phase.
- In DNS, pre-resolution selectors win over post-resolution ones.

**HTTP ordering:**
1. Do Not Inspect: matching traffic bypasses every other HTTP policy.
2. Isolate.
3. Allow / Block / Do Not Scan, by precedence.
4. Then body and response inspection.

**Impact on ST-POL-001 / ST-POL-002 (DNS plans):**
- Scoped rules must sit at precedence numbers lower than any broader rule. Today there is no conflicting DNS rule.
- The existing HTTP `Do Not Inspect` (precedence 0) would bypass any future HTTP-layer family rule for the traffic it matches. HTTP enforcement is also out of scope anyway, because it requires TLS decryption and a root certificate on the device.
- Cloudflare does not document whether **SafeSearch** and **YouTube Restricted** stop first-match evaluation. ST-POL-002's ordering (threats → content → essential allow → leisure block → SafeSearch → YouTube) therefore remains a device-test prerequisite.
- The `User Email` scope behaves inconsistently across actions: DNS Block matches address variants while Allow does not. The essential-services allow rule and the block rules would therefore not match identical populations.

## 6. Capability / entitlement matrix (live categories)

| Story | Control | Provider id | Class | Status |
|---|---|---|---|---|
| ST-POL-001 | malware | 117 | free | SUPPORTED |
| ST-POL-001 | phishing | 131 | free | SUPPORTED |
| ST-POL-001 | C2 / botnet | 80 | free | SUPPORTED |
| ST-POL-001 | adult content | 2 | free | SUPPORTED |
| ST-POL-001 | gambling | 99 | premium | **ENTITLEMENT_UNVERIFIED** |
| ST-POL-001 | SafeSearch | action `safesearch` | (scope category Search Engines 145 is premium) | SUPPORTED as an action. Termination semantics are undocumented, and the scope category's entitlement is unverified. |
| ST-POL-001 | YouTube Restricted | action `ytrestricted` (domain-scoped) | – | SUPPORTED as an action; termination semantics undocumented |
| ST-POL-002 | social media | 149 | premium | **ENTITLEMENT_UNVERIFIED** |
| ST-POL-002 | gaming | 100 | premium | **ENTITLEMENT_UNVERIFIED** |
| ST-POL-002 | entertainment / streaming | 164, 74 | premium | **ENTITLEMENT_UNVERIFIED**. The mapping to Video + Audio Streaming is a SETOK adapter interpretation. |

The account plan cannot be read: `/subscriptions` returns 403 with the current token, and the docs do not state a Free-plan category breakdown.

## 7. Blast radius

All 15 shared surfaces were **unchanged during discovery** and are **unchanged since the ST-DEV-001 final snapshot**:
- Gateway rules, lists and configuration;
- device settings;
- the Default profile, `SETOK-FAMILY-MANAGED` and all device profiles;
- the Access organization;
- identity providers;
- Access apps and the enrollment app;
- Access policies;
- Access groups;
- service tokens;
- posture rules.

Physical-device ids, registration ids and the enrollment-authorization reconciliation are also unchanged.

## 8. Decision and remediation options (for TD/PO)

**Decision:** `SAFE_SELECTOR_NOT_PROVEN / APPLY_BLOCKED`. Safe Selector Type: **NONE**.

Exact `User Email` is the only supported scoping mechanism, and the current identity fails three conditions: it is dedicated to one device, it fails closed against re-enrollment, and it is consistent across the policy builders.

Options:
1. **Dedicated per-device identity (recommended; no architecture change):**
   1. Provision a new mailbox reserved for `android-01` only. It must not be the account owner, IT admin or iPad identity.
   2. Change the ST-CF-002 enrollment policy include to that address, as a governed shared-auth change.
   3. Re-enroll android-01, then retire and replace binding `bnd_01M5ZND7…`.
   4. After enrollment, remove the include or disable the policy so the identity cannot create a second registration. Re-open it only through governed re-enrollment.
   5. Add the SETOK reconcile gate from §4.
   6. Then run a narrowly scoped canary DNS rule on `User Email` with a negative test before any baseline apply.

   Verify the plan entitlement for premium categories at the same time, using a billing-read token or Cloudflare support.
2. **Device UUID posture (`unique_client_id`):** needs Android managed deployment/MDM. That is `ARCHITECTURE_CHANGE_REQUIRED`, and is not recommended for the Family Link architecture.
3. **Separate Cloudflare account/organization for SETOK Family:** this removes the shared-account blast radius entirely. It is an architecture/provider-boundary decision.

No Gateway rule was created. ST-POL-001 and ST-POL-002 remain `APPLY_BLOCKED`.
