# ST-ID-002 — Establish first-family human identities

## Estado

- **Project:** SETOK Family
- **Repository:** SETOKCR/setok-family
- **Phase:** Phase 1 — Infrastructure, Enforcement and Identity
- **State:** SELECTED / PREFLIGHT COMPLETE
- **Risk:** RED — Auto-RED(authentication), ordinary score 6/10
- **Implementation authorized:** NO

## Goal

Establecer las primeras identidades humanas reales de la primera familia productiva, **Familia Ulate León**, en Authentik y demostrar creación, autenticación, recuperación y administración segura, manteniendo estrictamente separadas identidad humana y autorización del dominio SETOK Family.

## Product intent

Authentik responde **quién es la persona**. SETOK Family decidirá posteriormente a qué familia pertenece y qué puede hacer dentro de ella.

Esta Story no utilizará Authentik para modelar `Family`, `Owner`, `Parent`, `Viewer`, `Guardian ↔ Child` ni dispositivos.

**Familia Ulate León es el primer tenant del dominio SETOK Family; no es un tenant de Authentik.**

## Approved identity set

El Product Owner aprobó **dos identidades humanas adultas**, ambas con login interactivo habilitado.

Los nombres visibles y correos concretos se suministran únicamente como input operativo fuera de Git durante ejecución. No deben persistirse completos en desired state, logs versionados ni evidencia salvo necesidad excepcional expresamente aprobada.

No se crea una identidad de login para un menor en esta Story. La experiencia infantil autenticada queda diferida.

### Product Input Gate

**CLOSED.**

- approved human identities: 2 adults;
- interactive login: YES for both;
- child login: NO in this Story;
- concrete PII: operational input outside Git.

No se solicita ni versiona contraseña elegida por el usuario. Las credenciales iniciales se generan de forma segura y se entregan/custodian fuera de Git.

## Acceptance criteria

- [ ] Project Scope Handshake = `PROJECT_SCOPE_OK` antes de mutación.
- [ ] Se provisionan exactamente dos identidades humanas adultas aprobadas por el Product Owner.
- [ ] Cada identidad humana es un usuario regular de Authentik; ninguna persona se representa mediante service account.
- [ ] Username/login identifier es único y el estado observado coincide con el conjunto aprobado.
- [ ] Ningún usuario recibe privilegio de superuser ni acceso administrativo de Authentik.
- [ ] No se crean grupos o atributos `Owner`, `Parent`, `Viewer`, `Child`, `Guardian`, `Family` o equivalentes para implementar autorización del dominio.
- [ ] No se utiliza Authentik multi-tenancy para representar Familia Ulate León.
- [ ] No se crean aplicaciones OIDC, providers, federation/social login, Cloudflare Access integration ni provider/device bindings.
- [ ] Se verifica autenticación interactiva de las identidades aprobadas o, como mínimo, de una con evidencia suficiente y procedimiento reproducible para la segunda.
- [ ] Se verifica un camino de recuperación administrativa/recovery sin exponer secretos en evidencia.
- [ ] Las credenciales iniciales no aparecen en Git, logs persistidos ni evidencia versionada.
- [ ] La evidencia usa aliases/opaque references y evita nombres/correos completos.
- [ ] Se conserva `akadmin` como break-glass administrativo y no se usa como identidad humana del producto.
- [ ] La foundation ST-ID-001 permanece saludable y no se modifica su infraestructura base.
- [ ] Operaciones de provisioning/verify son idempotentes o detectan de forma segura objetos ya existentes.
- [ ] Rollback/desactivación de las identidades creadas queda documentado y limitado a esta Story.
- [ ] La credencial temporal de provisioning queda revocada/eliminada antes del cierre.

## Architecture constraints

- Authentik = Identity Plane; SETOK Family = Domain Core.
- Human identity is separate from device identity.
- Family is not an Authentik tenant.
- Authentication and authorization remain separate.
- A Child does not require a login identity.
- Least privilege and secret separation are mandatory.
- No direct WAN exposure is introduced.
- Configuration desired state may be versioned, but personal credentials and full PII are not.

## Out of scope

- Family/domain membership persistence in the SETOK application database.
- `Owner`, `Parent`, `Viewer` authorization.
- Guardian ↔ Child permission relationships.
- Child domain object creation.
- Child login / child experience.
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
- Blast Radius: 1 — Authentik identity plane only.
- Data/State: 2 — real human identity data is introduced.
- Security/Finance: 2 — login credentials and recovery affect authentication security.
- Contracts: 0.

The RED classification is mandatory because the Story creates real authentication identities and credential/recovery state.

## Required independent check

Independent Check: **PASS WITH CONDITIONS** (`docs/development/ST-ID-002_INDEPENDENT_CHECK.md`).

Mandatory conditions:

1. exact identity count and type approved by PO before Apply;
2. no child login inferred by default;
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

## Expected evidence

- non-secret desired identity shape using aliases/opaque references;
- pre-apply observed user inventory;
- apply result without names, emails, passwords or tokens;
- post-apply user inventory using aliases/opaque references;
- authentication success evidence without credential disclosure;
- recovery-path evidence;
- secret/privacy scan;
- rollback/remediation procedure.

## Stop conditions

- `PROJECT_SCOPE_MISMATCH` or `PROJECT_SCOPE_UNVERIFIED`.
- Implementation attempts to provision a different identity count/type than PO approved.
- Implementation requires modeling family roles/relationships inside Authentik.
- A human account would require superuser privilege.
- Secrets, passwords, names or full emails must be persisted in Git/evidence.
- OIDC, federation, Cloudflare Access or device bindings become necessary to complete the Story.
- Material authentication flow changes become necessary beyond creating/verifying users and recovery.
- Foundation health from ST-ID-001 is degraded by the change.
- Another material Auto-RED surface appears outside this preflight.
