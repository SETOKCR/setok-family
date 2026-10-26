# WORK ORDER ST-ID-002

## Identidad

- **Project:** SETOK Family
- **Repository:** SETOKCR/setok-family
- **Story / Work Unit:** ST-ID-002
- **Estado de ejecución:** PREFLIGHT
- **Implementation Authorization:** NO
- **Persistencia:** PERSISTED
- **Motivo de persistencia:** RED / authentication / real human identity data / multi-session auditability

## AIDE EXECUTION CONTEXT

- **Framework:** SETOK-AIDE v1.2.3
- **Project:** SETOK Family
- **Repository:** SETOKCR/setok-family
- **Role:** Development Agent
- **Work Unit:** ST-ID-002
- **Work Order:** PREFLIGHT
- **Authorized Base:** NONE
- **Implementation Branch:** NONE
- **Project Binding:** REQUIRED

## GOAL

Crear y validar las primeras identidades humanas reales del tenant piloto en Authentik, sin utilizar el IdP como modelo de familia ni autorización del dominio SETOK Family.

## PRODUCT REQUIREMENT

- Story: `docs/stories/ST-ID-002.md`.
- Arquitectura: `docs/ARCHITECTURE.md` secciones 2, 6.3–6.5 y 7.
- Authentik autentica personas; SETOK Family autoriza acciones dentro de familias.
- Un Child puede existir sin identidad de login.

## PRODUCT INPUT GATE

Antes de cualquier `APPLY`, el Product Owner debe aprobar el conjunto exacto de identidades humanas a provisionar (1–3 cuentas en esta Story). Los datos concretos se suministran fuera de Git.

Para cada identidad se requiere únicamente:

- display name;
- login/email identifier;
- login interactivo sí/no.

No se solicita al Product Owner una contraseña para versionar ni transportar por chat/Git. Las credenciales iniciales se generan y custodian fuera de Git.

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

## REQUIRED INDEPENDENT CHECK

Must PASS before Authorized Base / implementation authorization.

Check:

1. identity/domain separation;
2. least privilege;
3. credential custody;
4. recovery path;
5. privacy/minimal evidence;
6. provisioning API/method and idempotency;
7. no scope expansion into federation/OIDC/Access/domain roles;
8. rollback/deactivation.

## EXECUTION MODEL

Preferred:

`Git non-secret desired state -> story-specific automation -> Authentik supported API/controlled admin bootstrap -> observed-state verification -> non-secret evidence`

If automation requires an Authentik API credential, do not use a long-lived `akadmin` token as the steady-state design. Prefer a dedicated, least-privilege and time-bounded automation identity/token, or a one-time privileged bootstrap followed by revocation, subject to Independent Check.

## QUALITY GATES

- [ ] Product Input Gate closed before Apply.
- [ ] Project Scope = PROJECT_SCOPE_OK.
- [ ] Independent Check PASS.
- [ ] Authorized Base frozen.
- [ ] Branch lineage VERIFIED.
- [ ] Pre-existing user inventory captured non-secretly.
- [ ] Secret/PII handling plan verified.
- [ ] No superuser/domain-role grants.
- [ ] Login verification PASS.
- [ ] Recovery verification PASS.
- [ ] Foundation health regression PASS.
- [ ] Scope scan PASS.
- [ ] Secret/privacy scan PASS.
- [ ] Rollback/remediation documented.

## STOP CONDITIONS

- Scope mismatch/unverified.
- Product Input Gate open at Apply.
- Human account needs superuser/admin privilege.
- Family/domain authorization must be represented in Authentik.
- Secrets must enter Git/evidence.
- OIDC/federation/Access/device bindings become necessary.
- Material authentication-flow changes are required beyond approved identity/recovery scope.
- ST-ID-001 foundation becomes unhealthy.
- Unexpected material Auto-RED surface.

## Evidencia de cierre

Pending preflight and Independent Check.
