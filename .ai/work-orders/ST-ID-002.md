# WORK ORDER ST-ID-002

## Identidad

- **Project:** SETOK Family
- **Repository:** SETOKCR/setok-family
- **Story / Work Unit:** ST-ID-002
- **Authorized Base:** PENDING REFREEZE AFTER PRODUCT INPUT CLOSURE
- **Implementation Branch:** `feature/st-id-002`
- **Estado de ejecución:** READY_FOR_BASE
- **Implementation Authorization:** NO
- **Persistencia:** PERSISTED
- **Motivo de persistencia:** RED / authentication / real human identity data / multi-session auditability

## AIDE EXECUTION CONTEXT

- **Framework:** SETOK-AIDE v1.2.3
- **Project:** SETOK Family
- **Repository:** SETOKCR/setok-family
- **Role:** Development Agent
- **Work Unit:** ST-ID-002
- **Work Order:** READY_FOR_BASE — preflight + Independent Check passed; Product Input Gate CLOSED; implementation not authorized
- **Authorized Base:** PENDING REFREEZE
- **Implementation Branch:** `feature/st-id-002`
- **Project Binding:** REQUIRED

## GOAL

Crear y validar las primeras identidades humanas reales de **Familia Ulate León**, primera familia productiva de SETOK Family, en Authentik, sin utilizar el IdP como modelo de familia ni autorización del dominio.

## PRODUCT REQUIREMENT

- Story: `docs/stories/ST-ID-002.md`.
- Independent Check: `docs/development/ST-ID-002_INDEPENDENT_CHECK.md`.
- Arquitectura: `docs/ARCHITECTURE.md` secciones 2, 6.3–6.5 y 7.
- Authentik autentica personas; SETOK Family autoriza acciones dentro de familias.
- `Familia Ulate León` es el primer tenant del dominio SETOK Family, no un tenant de Authentik.
- Un Child puede existir sin identidad de login.

## PRODUCT INPUT GATE

**Status: CLOSED.**

Product Owner approved:

- exactly **2 adult human identities**;
- interactive login: **YES for both**;
- child login: **NO in this Story**;
- concrete display names and email/login identifiers: supplied as operational input outside Git.

No names, full emails or passwords are persisted in this Work Order, desired state or versioned evidence.

## ACCEPTANCE CRITERIA

- [ ] Project Scope Handshake = `PROJECT_SCOPE_OK`.
- [ ] Provision exactly two adult human identities approved by PO.
- [ ] Human users are regular Authentik users; no human represented as service account.
- [ ] Neither human identity is superuser/admin in Authentik.
- [ ] No `Owner`, `Parent`, `Viewer`, `Child`, `Guardian`, `Family` or family relationships are modeled in Authentik.
- [ ] Authentik multi-tenancy is not used to represent Familia Ulate León.
- [ ] No OIDC apps/providers, federation, Cloudflare Access, device/provider bindings or Outposts are created.
- [ ] Interactive login is demonstrated for approved identities, or at minimum one identity plus reproducible validation for the second if human interaction prevents automated proof.
- [ ] Administrative recovery/recovery path verified without revealing secrets.
- [ ] Credentials and tokens absent from Git/evidence.
- [ ] Evidence minimizes PII and uses aliases/opaque references; no full names/emails persisted.
- [ ] `akadmin` remains break-glass administrative identity, separate from product humans.
- [ ] ST-ID-001 foundation remains healthy.
- [ ] Provisioning/verify is idempotent or collision-safe.
- [ ] Rollback/deactivation is limited to identities created by this Story and documented.
- [ ] Temporary provisioning credential is revoked/deleted before closure.

## ARCHITECTURE CONSTRAINTS

- Authentik = Identity Plane, not Domain Core.
- Human identity != device identity.
- Family != Authentik tenant.
- Authentication != authorization.
- Least privilege and secret separation.
- No direct WAN exposure changes.
- No child login by default merely because a Child domain entity exists.

## OUT OF SCOPE

- SETOK Family domain membership persistence.
- Owner/Parent/Viewer authorization.
- Guardian ↔ Child permissions.
- Child domain object creation.
- Child login / child experience.
- Device identities / provider bindings.
- Federation/social login.
- OIDC for `family.setok.cr`.
- Cloudflare Access integration.
- Consumer MFA/passkeys rollout.
- Authentik Outposts.
- Generic automation framework.
- SETOK Family App.

## RISK

- **Classification:** RED — Auto-RED(authentication)
- **Ordinary score:** 6/10
- Reversibility 1
- Blast Radius 1
- Data/State 2
- Security/Finance 2
- Contracts 0

Reason: real human authentication identities, credentials and recovery state are introduced.

## INDEPENDENT CHECK

**PASS WITH CONDITIONS** — `docs/development/ST-ID-002_INDEPENDENT_CHECK.md`.

Mandatory conditions:

1. exact identity count/type approved by PO before Apply;
2. no child login in this Story;
3. no family/domain role modeling in Authentik;
4. no superuser/admin privilege for human users;
5. temporary least-privilege provisioning credential, revoked after use;
6. secrets and full PII absent from Git/evidence;
7. interactive login verified;
8. recovery initiation verified without secret persistence;
9. idempotent collision-safe provisioning;
10. ST-ID-001 health regression PASS;
11. post-apply scope scan clean;
12. rollback/deactivation documented.

## EXECUTION MODEL

Preferred:

`Git non-secret desired shape -> story-specific automation -> controlled privileged bootstrap -> temporary least-privilege Authentik API credential -> supported API provisioning -> observed-state verification -> credential revocation -> non-secret evidence`

A long-lived `akadmin` API token is prohibited as steady-state automation.

A temporary dedicated service account/token is preferred when practical. If minimum required permissions cannot be achieved without broad permanent administrative privilege, STOP and return to Technical Director.

Concrete PII is injected only at execution time from a non-versioned local source or interactive secure input. It must not be written to Git or evidence.

This Story does not establish a generic reusable Authentik automation framework.

## TEST IMPACT

- capture pre-existing Authentik human/service/internal user inventory without secrets or full PII;
- collision check before create;
- create only the two approved adult human users;
- verify no superuser/admin grants;
- verify interactive login;
- verify recovery initiation path without storing recovery token/URL;
- re-run provisioning to prove idempotency/no duplicates;
- verify temporary provisioning identity/token revoked;
- verify no OIDC/federation/Access/domain-role/device-binding expansion;
- verify ST-ID-001 foundation health unchanged;
- secret and PII scan of Git/evidence.

## QUALITY GATES

- [x] Product Input Gate CLOSED.
- [ ] Project Scope = PROJECT_SCOPE_OK.
- [x] Independent Check = PASS WITH CONDITIONS.
- [ ] Authorized Base re-frozen after product-input closure.
- [ ] Branch lineage VERIFIED against re-frozen base.
- [ ] Pre-existing user inventory captured non-secretly.
- [ ] Secret/PII handling plan verified.
- [ ] Temporary provisioning credential least-privilege and revocable.
- [ ] No superuser/domain-role grants.
- [ ] Login verification PASS.
- [ ] Recovery verification PASS.
- [ ] Provisioning credential revoked.
- [ ] Foundation health regression PASS.
- [ ] Scope scan PASS.
- [ ] Secret/privacy scan PASS.
- [ ] Rollback/remediation documented.
- [ ] Evidence sufficient for Technical Director review.

## STOP CONDITIONS

- Scope mismatch/unverified.
- Authorized Base/branch lineage not verifiable.
- Implementation attempts to provision a different identity count/type than approved.
- Human account needs superuser/admin privilege.
- Family/domain authorization must be represented in Authentik.
- Secrets or full PII must enter Git/evidence.
- OIDC/federation/Access/device bindings become necessary.
- Material authentication-flow changes are required beyond approved identity/recovery scope.
- Least-privilege temporary provisioning cannot be achieved without broad permanent privilege.
- ST-ID-001 foundation becomes unhealthy.
- Unexpected material Auto-RED surface.

## Evidencia de cierre

- Preflight: PASS
- Independent Check: PASS WITH CONDITIONS
- Product Input Gate: CLOSED — 2 adults, interactive login YES, child login NO
- Authorized Base: pending re-freeze after product-input closure
- Implementation Branch: `feature/st-id-002`
- Implementation Authorization: NO
