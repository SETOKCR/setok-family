# ST-ID-002 — Independent Check

## Resultado

**PASS WITH CONDITIONS**

Story: `ST-ID-002 — Establish pilot human identities`

Risk: **RED — Auto-RED(authentication), ordinary score 6/10**

This check reviews architecture separation, authentication risk, privacy, credential custody, provisioning method, recovery and rollback before implementation authorization.

## 1. Identity vs domain separation — PASS

Architecture is explicit:

- Authentik authenticates the person.
- SETOK Family authorizes what the person can do inside a family.
- A Family is not an Authentik tenant.
- A Child may exist without a login identity.

Condition:

Do not create Authentik groups/attributes/tenants named or used as `Owner`, `Parent`, `Viewer`, `Child`, `Guardian`, `Family` or Guardian↔Child authorization.

## 2. Human account type / privilege — PASS WITH CONDITION

Pilot humans must be regular interactive Authentik users, never service accounts.

No pilot human receives:

- superuser;
- Authentik admin access;
- provisioning permissions;
- infrastructure credentials.

`akadmin` remains separate break-glass administration.

## 3. Product Input Gate — OPEN BY DESIGN

Before Apply, PO must provide the exact 1–3 pilot human identities to create. Personal identity values are operational input, not canonical Git configuration.

The Story must not infer that a child needs a login merely because a Child domain entity exists.

## 4. Provisioning method — PASS WITH CONDITIONS

Authentik supports automated user creation through its API. Story-specific automation should prefer the supported API for Create/Read/Verify operations.

A long-lived `akadmin` API token is prohibited as steady-state automation.

Allowed implementation pattern:

1. perform a minimal controlled privileged bootstrap using existing local administration;
2. create or obtain a **temporary provisioning credential** scoped as narrowly as practical to required user-management operations;
3. store that credential only in a local encrypted secret store / process memory outside Git;
4. use the supported Authentik API for user provisioning/verification;
5. revoke/delete the temporary provisioning credential before closure.

A dedicated temporary service account/token is preferred when practical because Authentik explicitly supports service accounts for API automation and permissions can be assigned by role/object permission.

If minimum required permissions cannot be established without broad permanent administrative privilege, STOP and return to Technical Director rather than normalizing an over-privileged automation identity.

This Story does not establish a generic reusable Authentik automation framework.

## 5. Credential generation and custody — PASS WITH CONDITIONS

Initial human credentials must:

- be randomly generated or user-established out of band;
- never be committed to Git;
- never be written to versioned evidence;
- never be echoed in persistent logs;
- be handed to/custodied by the PO in a password manager or equivalent secure channel.

Do not require the PO to type a chosen password into Git-tracked configuration.

If a temporary credential must exist locally for validation, it must be encrypted at rest and deleted when no longer needed unless PO explicitly chooses to retain it as an operational backup.

## 6. Recovery — PASS WITH CONDITIONS

SMTP/email recovery configuration is not required for this Story.

A local administrative recovery path is sufficient for pilot validation, provided:

- it is vendor-supported;
- recovery links/tokens are short-lived;
- recovery secrets/URLs are never persisted in Git/evidence;
- successful ability to initiate recovery is verified without forcing unnecessary password rotation.

Do not redesign global Authentik authentication/recovery flows unless required; a material flow change is a Stop Condition.

## 7. Privacy / evidence minimization — PASS WITH CONDITIONS

This Story introduces real personal identity data.

Versioned evidence should avoid full email addresses and unnecessary names. Prefer:

- opaque identity aliases;
- Authentik user IDs/UUIDs where non-sensitive;
- counts/status flags;
- redacted login identifiers.

The canonical repository should describe the desired *shape* of the pilot identity set without becoming a directory of family PII.

## 8. Authentication verification — PASS WITH CONDITIONS

At least one approved pilot identity must demonstrate successful interactive authentication.

Evidence may record:

- user identifier alias;
- HTTP/flow outcome;
- successful authenticated session/user identity check;

but never password, session cookie, recovery token or API token.

No direct WAN publication is required. Verification can occur from LAN against the existing Authentik foundation.

## 9. Idempotency / collision handling — PASS WITH CONDITIONS

Before Create:

- inventory current users;
- verify username/login collision;
- refuse to overwrite unrelated existing users;
- re-run must return `NONE`/already-matching rather than duplicate identities.

Changing an existing user's password or identity attributes without explicit ownership proof is prohibited.

## 10. Rollback — PASS

Rollback for identities created by this Story is localized:

- disable first when preservation/audit is useful;
- delete only after exact identity ownership is verified;
- revoke temporary provisioning token/service account;
- leave `akadmin`, embedded Authentik users and ST-ID-001 foundation untouched.

## 11. Scope scan — PASS

Must verify after Apply:

- no OIDC application/provider;
- no federation/social source;
- no Cloudflare Access integration;
- no family-domain groups/roles;
- no device/provider bindings;
- no Outposts created;
- no superuser grant to pilot humans.

## 12. Risk disposition

Ordinary risk remains **6/10**, but Auto-RED(authentication) controls the classification.

No architecture change is required.

No technical blocker prevents the Story from reaching READY once the mandatory conditions are embedded into the Work Order.

The Product Input Gate may remain open until immediately before Apply; it blocks mutation, not preflight/readiness preparation.

## Mandatory conditions for Work Order

1. exact human identity set approved by PO before Apply;
2. no child login inferred by default;
3. no domain roles/family modeling in Authentik;
4. no superuser/admin pilot human;
5. temporary/minimum-privilege API provisioning credential, revoked after use;
6. secrets and full PII absent from Git/evidence;
7. at least one interactive login verified;
8. recovery initiation verified without secret persistence;
9. idempotent collision-safe provisioning;
10. ST-ID-001 health regression check;
11. scope scan clean;
12. rollback/deactivation documented.
