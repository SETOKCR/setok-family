# WORK ORDER ST-ID-002

## Identidad

- **Project:** SETOK Family
- **Repository:** SETOKCR/setok-family
- **Story / Work Unit:** ST-ID-002
- **Authorized Base:** `3494c39efd3bbdda3f52d79b2abe0bd2a6073cc9`
- **Implementation Branch:** `feature/st-id-002`
- **Estado de ejecución:** READY
- **Implementation Authorization:** YES — explicitly authorized by Product Owner and Technical Director
- **Persistencia:** PERSISTED
- **Motivo de persistencia:** RED / authentication / real human identity data / multi-session auditability

## AIDE EXECUTION CONTEXT

- **Framework:** SETOK-AIDE v1.2.3
- **Project:** SETOK Family
- **Repository:** SETOKCR/setok-family
- **Role:** Development Agent
- **Work Unit:** ST-ID-002
- **Work Order:** READY — preflight + Independent Check passed; Product Input Gate CLOSED; implementation authorized
- **Authorized Base:** `3494c39efd3bbdda3f52d79b2abe0bd2a6073cc9`
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

Product Owner approved exactly **2 adult human identities**, both with interactive login. Child login is excluded from this Story. Concrete names/emails are operational input outside Git and must not be persisted in versioned desired state, logs or evidence.

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
- Reversibility 1; Blast Radius 1; Data/State 2; Security/Finance 2; Contracts 0.

Reason: real human authentication identities, credentials and recovery state are introduced.

## INDEPENDENT CHECK

**PASS WITH CONDITIONS** — `docs/development/ST-ID-002_INDEPENDENT_CHECK.md`.

Mandatory conditions: exact approved identity count/type; no child login; no family/domain role modeling; no human admin/superuser; temporary least-privilege provisioning credential revoked after use; no secrets/full PII in Git/evidence; interactive login verification; recovery verification; collision-safe/idempotent provisioning; ST-ID-001 health regression PASS; clean post-apply scope scan; rollback/deactivation documented.

## EXECUTION MODEL

`Git non-secret desired shape -> story-specific automation -> controlled privileged bootstrap -> temporary least-privilege Authentik API credential -> supported API provisioning -> observed-state verification -> credential revocation -> non-secret evidence`

A long-lived `akadmin` API token is prohibited. Concrete PII is injected only at execution time from a non-versioned local source or secure interactive input.

## QUALITY GATES

- [x] Product Input Gate CLOSED.
- [ ] Project Scope = PROJECT_SCOPE_OK.
- [x] Independent Check = PASS WITH CONDITIONS.
- [x] Authorized Base frozen at `3494c39efd3bbdda3f52d79b2abe0bd2a6073cc9`.
- [x] Branch lineage VERIFIED.
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
- Authorized Base: `3494c39efd3bbdda3f52d79b2abe0bd2a6073cc9`
- Implementation Branch: `feature/st-id-002`
- Branch lineage: VERIFIED
- Implementation Authorization: YES
