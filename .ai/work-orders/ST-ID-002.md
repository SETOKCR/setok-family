# WORK ORDER ST-ID-002

## Identidad

- **Project:** SETOK Family
- **Repository:** SETOKCR/setok-family
- **Story / Work Unit:** ST-ID-002
- **Authorized Base:** `3494c39efd3bbdda3f52d79b2abe0bd2a6073cc9`
- **Implementation Branch:** `feature/st-id-002`
- **Accepted Candidate:** `9111781ac67a1db4194102368be311849d59d174`
- **Integration Commit:** `c506ac29b1d1463c5003adc98a41eaf8b5c28d05`
- **Estado de ejecución:** IMPLEMENTATION_DONE
- **Implementation Authorization:** CLOSED
- **Technical Director Decision:** ACCEPT
- **Persistencia:** PERSISTED

## Goal

Crear y validar las primeras identidades humanas reales de **Familia Ulate León**, primera familia productiva de SETOK Family, en Authentik, sin utilizar el IdP como modelo de familia ni autorización del dominio.

## Product boundary

- Authentik autentica personas; SETOK Family autoriza acciones dentro de familias.
- `Familia Ulate León` es tenant del dominio SETOK Family, no tenant de Authentik.
- Se aprobaron exactamente 2 identidades humanas adultas con login interactivo.
- Child login quedó fuera de alcance.
- Los nombres, correos y contraseñas permanecen fuera de Git/evidence.

## Acceptance result

- [x] Project Scope Handshake = `PROJECT_SCOPE_OK`.
- [x] Branch lineage verificada contra Authorized Base.
- [x] Exactamente 2 adultos provisionados.
- [x] Usuarios regulares `internal`; ninguna persona como service account.
- [x] Ningún humano es superuser/admin.
- [x] Ningún grupo/rol de dominio familiar fue creado en Authentik.
- [x] Authentik multi-tenancy no se usa para representar Familia Ulate León.
- [x] No se crearon OIDC apps/providers, federation, Cloudflare Access, device bindings ni Outposts adicionales.
- [x] Login interactivo verificado para ambas identidades.
- [x] Recovery path verificado sin persistir recovery URL/token.
- [x] Evidencia sin PII real ni secretos.
- [x] `akadmin` permanece break-glass y único superuser humano administrativo.
- [x] ST-ID-001 foundation healthy.
- [x] Segundo Apply idempotente: `NONE` para ambas identidades.
- [x] Temporary provisioning service account/role/token revocados y ausentes al final.
- [x] Rollback/deactivation documentado y limitado a las dos identidades.

## Independent Check

**PASS WITH CONDITIONS — all mandatory conditions satisfied.**

El provisioner temporal fue `st-id-002-provisioner`, no-superuser, con únicamente `view_user`, `add_user`, `change_user`, `reset_user_password`, token API expirable de 60 minutos y cleanup en `finally`. Evidencia final: `REMAINING=0,0,0`.

## Evidence

- `docs/evidence/ST-ID-002/README.md`
- `docs/evidence/ST-ID-002/20261025T232219-inventory.json`
- `docs/evidence/ST-ID-002/20261025T232253-apply.json`
- `docs/evidence/ST-ID-002/20261025T232324-verify.json`
- `docs/evidence/ST-ID-002/20261025T232400-apply.json`
- `docs/evidence/ST-ID-002/20261025T232407-inventory.json`
- `infra/authentik/st-id-002.identities.json`
- `scripts/st-id-002/Invoke-StId002.ps1`

## Closure

- Preflight: PASS
- Independent Check: PASS WITH CONDITIONS → SATISFIED
- Product Input Gate: CLOSED
- Project Scope: PROJECT_SCOPE_OK
- Required Gates: PASS
- Stop Conditions: NONE
- Unexpected Surface: NONE
- Technical Director Decision: **ACCEPT**
- Accepted Candidate: `9111781ac67a1db4194102368be311849d59d174`
- Integration Commit: `c506ac29b1d1463c5003adc98a41eaf8b5c28d05`

Operational custody follow-up: initial passwords are already stored by the Product Owner in Bitwarden. DPAPI credential copies may be removed after Story closure is confirmed; `st-id-002-identities.xml` may be retained until no further operational revalidation is required.
