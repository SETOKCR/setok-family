# ST-ID-002 — Establish pilot human identities

## Estado

- **Project:** SETOK Family
- **Repository:** SETOKCR/setok-family
- **Phase:** Phase 1 — Infrastructure, Enforcement and Identity
- **State:** SELECTED / PREFLIGHT
- **Risk:** RED — Auto-RED(authentication), ordinary score 6/10
- **Implementation authorized:** NO

## Goal

Establecer las primeras identidades humanas reales del tenant piloto en Authentik y demostrar creación, autenticación, recuperación y administración segura, manteniendo estrictamente separadas identidad humana y autorización del dominio SETOK Family.

## Product intent

Authentik responde **quién es la persona**. SETOK Family decidirá posteriormente a qué familia pertenece y qué puede hacer dentro de ella.

Esta Story no utilizará Authentik para modelar `Family`, `Owner`, `Parent`, `Viewer`, `Guardian ↔ Child` ni dispositivos.

## Pilot identity set

La Story soporta inicialmente **1–3 identidades humanas internas** del piloto. Los datos concretos de las personas (nombre, correo y credencial inicial) se suministrarán fuera de Git durante ejecución.

No se crea una identidad de login para un menor por defecto. Un `Child` puede existir sin cuenta humana; una identidad infantil sólo se crea si el Product Owner la selecciona explícitamente para una experiencia que requiera login.

### Product Input Gate

Antes de `APPLY`, el Product Owner debe indicar el conjunto exacto de identidades humanas a provisionar. Para cada una:

- nombre visible;
- correo/identificador de login;
- si debe tener login interactivo en esta etapa.

No se solicita ni versiona contraseña elegida por el usuario. Las credenciales iniciales se generan de forma segura y se entregan/custodian fuera de Git.

## Acceptance criteria

- [ ] Project Scope Handshake = `PROJECT_SCOPE_OK` antes de mutación.
- [ ] Se provisiona únicamente el conjunto de identidades humanas aprobado por el Product Owner.
- [ ] Cada identidad humana es un usuario regular de Authentik; ninguna persona se representa mediante service account.
- [ ] Username/login identifier es único y el estado observado coincide con el conjunto aprobado.
- [ ] Ningún usuario piloto recibe privilegio de superuser ni acceso administrativo de Authentik.
- [ ] No se crean grupos o atributos `Owner`, `Parent`, `Viewer`, `Child`, `Guardian`, `Family` o equivalentes para implementar autorización del dominio.
- [ ] No se utiliza Authentik multi-tenancy para representar la familia Ulate León.
- [ ] No se crean aplicaciones OIDC, providers, federation/social login, Cloudflare Access integration ni provider/device bindings.
- [ ] Se verifica autenticación interactiva de al menos una identidad humana del piloto.
- [ ] Se verifica un camino de recuperación administrativa/recovery sin exponer secretos en evidencia.
- [ ] Las credenciales iniciales no aparecen en Git, logs persistidos ni evidencia versionada.
- [ ] Cualquier dato personal persistido en Git se limita a lo estrictamente necesario; por defecto la evidencia usa identificadores no secretos y evita correos completos.
- [ ] Se conserva `akadmin` como break-glass administrativo y no se usa como identidad humana del producto.
- [ ] La foundation ST-ID-001 permanece saludable y no se modifica su infraestructura base.
- [ ] Operaciones de provisioning/verify son idempotentes o detectan de forma segura objetos ya existentes.
- [ ] Rollback/desactivación de las identidades creadas queda documentado y limitado a esta Story.

## Architecture constraints

- Authentik = Identity Plane; SETOK Family = Domain Core.
- Human identity is separate from device identity.
- Family is not an Authentik tenant.
- Authentication and authorization remain separate.
- A Child does not require a login identity.
- Least privilege and secret separation are mandatory.
- No direct WAN exposure is introduced.
- Configuration desired state may be versioned, but personal credentials and secrets are not.

## Out of scope

- Family/domain membership persistence in the SETOK application database.
- `Owner`, `Parent`, `Viewer` authorization.
- Guardian ↔ Child permission relationships.
- Child domain object creation.
- Device identity or provider bindings.
- Google/Microsoft/Apple federation.
- OIDC application/provider for `family.setok.cr`.
- Cloudflare Access + Authentik.
- Consumer MFA rollout.
- Passkeys/WebAuthn rollout.
- Authentik Outposts.
- Generic automation framework.
- SETOK Family App / mini app.

## Risk preflight

**Classification:** RED — Auto-RED(authentication).

Ordinary score: **6/10**

- Reversibility: 1 — users can be disabled/deleted; rollback is localized.
- Blast Radius: 1 — pilot Authentik only.
- Data/State: 2 — real human identity data is introduced.
- Security/Finance: 2 — login credentials and recovery affect authentication security.
- Contracts: 0.

The RED classification is mandatory because the Story creates real authentication identities and credential/recovery state.

## Required independent check

Before implementation authorization, independently verify:

1. identity/domain separation;
2. least privilege and absence of superuser grants;
3. credential generation/custody;
4. recovery path;
5. privacy/minimization of evidence;
6. provisioning method and idempotency;
7. no OIDC/federation/Access/domain-role expansion;
8. rollback/deactivation semantics.

## Expected evidence

- non-secret desired identity set using aliases/opaque references where practical;
- pre-apply observed user inventory;
- apply result without passwords/tokens;
- post-apply user inventory;
- authentication success evidence for at least one approved identity without credential disclosure;
- recovery-path evidence;
- secret/privacy scan;
- rollback/remediation procedure.

## Stop conditions

- `PROJECT_SCOPE_MISMATCH` or `PROJECT_SCOPE_UNVERIFIED`.
- Exact pilot identity set has not been approved by Product Owner before Apply.
- Implementation requires modeling family roles/relationships inside Authentik.
- A human account would require superuser privilege.
- Secrets or passwords must be persisted in Git/evidence.
- OIDC, federation, Cloudflare Access or device bindings become necessary to complete the Story.
- Material authentication flow changes become necessary beyond creating/verifying users and recovery.
- Foundation health from ST-ID-001 is degraded by the change.
- Another material Auto-RED surface appears outside this preflight.
