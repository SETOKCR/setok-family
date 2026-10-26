# WORK ORDER ST-ID-002

## Identidad

- **Project:** SETOK Family
- **Repository:** SETOKCR/setok-family
- **Story / Work Unit:** ST-ID-002
- **Authorized Base:** `1d46704d15ef2721bc1cd0ec67673b8de006eb31`
- **Implementation Branch:** `feature/st-id-002`
- **Estado de ejecución:** READY
- **Implementation Authorization:** NO
- **Persistencia:** PERSISTED
- **Motivo de persistencia:** RED / authentication / real human identity data / multi-session auditability

## AIDE EXECUTION CONTEXT

- **Framework:** SETOK-AIDE v1.2.3
- **Project:** SETOK Family
- **Repository:** SETOKCR/setok-family
- **Role:** Development Agent
- **Work Unit:** ST-ID-002
- **Work Order:** READY — preflight + Independent Check passed; Product Input Gate remains open; implementation not authorized
- **Authorized Base:** `1d46704d15ef2721bc1cd0ec67673b8de006eb31`
- **Implementation Branch:** `feature/st-id-002`
- **Project Binding:** REQUIRED

## GOAL

Crear y validar las primeras identidades humanas reales del tenant piloto en Authentik, sin utilizar el IdP como modelo de familia ni autorización del dominio SETOK Family.

## PRODUCT REQUIREMENT

- Story: `docs/stories/ST-ID-002.md`.
- Independent Check: `docs/development/ST-ID-002_INDEPENDENT_CHECK.md`.
- Arquitectura: `docs/ARCHITECTURE.md` secciones 2, 6.3–6.5 y 7.
- Authentik autentica personas; SETOK Family autoriza acciones dentro de familias.
- Un Child puede existir sin identidad de login.

## PRODUCT INPUT GATE

**Status: OPEN — blocks Apply and implementation authorization.**

Antes de cualquier `APPLY`, el Product Owner debe aprobar el conjunto exacto de identidades humanas a provisionar (1–3 cuentas en esta Story). Los datos concretos se suministran fuera de Git.

Para cada identidad se requiere únicamente:

- display name;
- login/email identifier;
- login interactivo sí/no.

No se solicita al Product Owner una contraseña para versionar ni transportar por Git. Las credenciales iniciales se generan y custodian fuera de Git.

No se crea identidad de login para un menor por inferencia; requiere selección explícita del Product Owner.

## ACCEPTANCE CRITERIA

- [ ] Project Scope Handshake = `PROJECT_SCOPE_OK`.
- [ ] Sólo se provisionan las identidades explícitamente aprobadas por PO.
- [ ] Usuarios humanos regulares; ninguna persona como service account.
- [ ] Ninguna identidad piloto es superuser/admin de Authentik.
- [ ] No se modelan `Owner`, `Parent`, `Viewer`, `Child`, `Guardian`, `Family` ni relaciones familiares en Authentik.
- [ ] No se usa Authentik multi-tenancy para representar familias.
- [ ] No se crean OIDC apps/providers, federation, Cloudflare Access, device/provider bindings ni Outposts.
- [ ] Al menos una identidad aprobada demuestra login interactivo correcto.
- [ ] Recovery administrativo/recovery path verificado sin revelar secretos.
- [ ] Credenciales y tokens ausentes de Git/evidence.
- [ ] Evidencia minimiza PII; no persiste correos completos salvo necesidad justificada y aprobada.
- [ ] `akadmin` permanece break-glass administrativo, separado de usuarios producto.
- [ ] Foundation ST-ID-001 continúa healthy.
- [ ] Provisioning/verify idempotente o fail-safe ante objetos existentes.
- [ ] Rollback/desactivación limitada a identidades de esta Story documentada.
- [ ] Credencial temporal de provisioning revocada/eliminada antes del cierre.

## ARCHITECTURE CONSTRAINTS

- Authentik = Identity Plane, no Domain Core.
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

1. exact identity set approved by PO before Apply;
2. no child login inferred by default;
3. no family/domain role modeling in Authentik;
4. no superuser/admin privilege for pilot humans;
5. temporary least-privilege provisioning credential, revoked after use;
6. secrets and full PII absent from Git/evidence;
7. at least one interactive login verified;
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

This Story does not establish a generic reusable Authentik automation framework.

## TEST IMPACT

- capture pre-existing Authentik human/service/internal user inventory without secrets;
- collision check before create;
- create only approved human users;
- verify no superuser/admin grants;
- verify interactive login for at least one approved identity;
- verify recovery initiation path without storing recovery token/URL;
- re-run provisioning to prove idempotency/no duplicates;
- verify temporary provisioning identity/token revoked;
- verify no OIDC/federation/Access/domain-role/device-binding expansion;
- verify ST-ID-001 foundation health unchanged;
- secret and PII scan of Git/evidence.

## QUALITY GATES

- [ ] Product Input Gate closed before Apply.
- [ ] Project Scope = PROJECT_SCOPE_OK.
- [x] Independent Check = PASS WITH CONDITIONS.
- [x] Authorized Base frozen at `1d46704d15ef2721bc1cd0ec67673b8de006eb31`.
- [x] Implementation branch `feature/st-id-002` created from exact Authorized Base.
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
- Product Input Gate open at Apply.
- Human account needs superuser/admin privilege.
- Family/domain authorization must be represented in Authentik.
- Secrets must enter Git/evidence.
- Full personal email/name must be persisted in Git without explicit need/approval.
- OIDC/federation/Access/device bindings become necessary.
- Material authentication-flow changes are required beyond approved identity/recovery scope.
- Least-privilege temporary provisioning cannot be achieved without creating broad permanent privilege.
- ST-ID-001 foundation becomes unhealthy.
- Unexpected material Auto-RED surface.

## Evidencia de cierre

- Preflight: PASS
- Independent Check: PASS WITH CONDITIONS
- Product Input Gate: OPEN
- Authorized Base: `1d46704d15ef2721bc1cd0ec67673b8de006eb31`
- Implementation Branch: `feature/st-id-002`
- Implementation Authorization: NO
