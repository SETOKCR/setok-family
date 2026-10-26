# WORK ORDER ST-ID-001

## Identidad

- **Project:** SETOK Family
- **Repository:** SETOKCR/setok-family
- **Story / Work Unit:** ST-ID-001
- **Authorized Base:** `e10279d1c31e3f02e5b7b4d4185d74f662a93877`
- **Implementation Branch:** `feature/st-id-001`
- **Estado de ejecución:** IMPLEMENTATION_DONE
- **Implementation Authorization:** CLOSED — implementation accepted and integrated
- **Persistencia:** PERSISTED
- **Motivo de persistencia:** RED / authentication foundation / multi-session / auditability

### Project Binding

Antes de cualquier mutación, el Development Agent debía verificar:

`Work Order Repository == .ai/AIDE_PROJECT.yaml project.repository == live repository`

Resultado requerido y obtenido: `PROJECT_SCOPE_OK`.

---

## AIDE EXECUTION CONTEXT

- **Framework:** SETOK-AIDE v1.2.3
- **Project:** SETOK Family
- **Repository:** SETOKCR/setok-family
- **Role:** Development Agent
- **Work Unit:** ST-ID-001
- **Work Order:** IMPLEMENTATION_DONE
- **Authorized Base:** `e10279d1c31e3f02e5b7b4d4185d74f662a93877`
- **Implementation Branch:** `feature/st-id-001`
- **Accepted Candidate:** `6bcd99024ef86f7819a957c2e17e2b9a442178f7`
- **Integration Commit:** `e6d1bffa65762b93069fdf480d5d67628e1fbdef`
- **Project Binding:** VERIFIED

---

## GOAL

Establecer la foundation self-hosted de Authentik para el piloto de SETOK Family, con persistencia, bootstrap administrativo seguro, backup/restore y verificación de estado, sin crear todavía identidades reales del tenant, autorización familiar, federation, OIDC de la app ni Cloudflare Access.

---

## PRODUCT REQUIREMENT

- Referencia: `docs/PRODUCT.md`; Story `docs/stories/ST-ID-001.md`.
- Contexto mínimo: Authentik autentica personas; SETOK Family autoriza acciones dentro de familias. La familia no es un tenant Authentik.

---

## ACCEPTANCE CRITERIA

- [x] Authentik self-hosted del piloto está desplegado y operativo en una **VM dedicada** sobre Proxmox `pve-02`.
- [x] La VM existente `210 (setok-live-01)` no fue modificada por esta Story.
- [x] Deployment base: Ubuntu 24.04 LTS + Docker Engine + Docker Compose v2.
- [x] Sizing inicial: **2 vCPU, 2 GiB RAM y 40 GiB disco**.
- [x] El mount `/var/run/docker.sock` del compose upstream fue eliminado mientras Outposts siguen fuera de scope.
- [x] No existe exposición WAN directa no protegida.
- [x] Desired state no secreto registra versión/despliegue, hostname/base URL, persistencia y configuración reproducible.
- [x] PostgreSQL y volúmenes persistentes relevantes tienen backup/restore documentado y backup verificable.
- [x] Se generó backup lógico PostgreSQL y se almacenó fuera de la VM de Authentik.
- [x] Bootstrap administrativo usa secretos fuera de Git y `AUTHENTIK_BOOTSTRAP_PASSWORD_HASH`.
- [x] Secret key, PostgreSQL password, bootstrap hash y API tokens no aparecen en Git ni evidencia versionada.
- [x] Automatización futura queda separada de identidades humanas; no se creó token de automatización en esta Story.
- [x] Health/API/UI checks confirman estado operativo y el estado observado coincide con desired state.
- [x] Se registró consumo inicial de CPU/RAM del guest y del host.
- [x] No se crearon usuarios reales del piloto, roles familiares, federation, OIDC de la app ni Access integration.
- [x] Rollback/remediation y recuperación administrativa local están documentados sin exponer secretos.
- [x] Rollback/remediation no impacta Cloudflare ni otros proyectos SETOK.

---

## ARCHITECTURE CONSTRAINTS

- Authentik permanece en Identity Plane, no Domain Core.
- Authentik no modela familias ni autorización Guardian ↔ Child.
- Piloto self-hosted en VM dedicada sobre `pve-02`; no LXC/PCT.
- Docker Compose se ejecuta dentro de la VM Linux.
- No se introdujo HA comercial.
- Configuración deseada versionada; secretos separados.
- No exposición directa de servicios locales a Internet.
- Authentication y authorization permanecen separadas.

---

## OUT OF SCOPE CONFIRMADO

No se implementó en esta Story:

- usuarios reales Ulate León;
- roles de dominio y relaciones familiares;
- Google/Microsoft/Apple federation;
- OIDC provider/application de `family.setok.cr`;
- Cloudflare Access + Authentik;
- provider/device bindings;
- MFA de consumidores;
- Authentik Outposts adicionales;
- HA comercial;
- LXC/PCT;
- SETOK Family App / mini app.

El `Embedded Outpost` y su cuenta/token internos observados son objetos por defecto de Authentik; no fueron creados por esta Story.

---

## RISK

- **Clasificación:** RED (Auto-RED `authentication`)
- **Score ordinario:** 5/10
- **Independent Check:** PASS WITH CONDITIONS — `docs/development/ST-ID-001_INDEPENDENT_CHECK.md`.
- **Technical Director final decision:** ACCEPT.
- **Capacity risk disposition:** aceptado temporalmente por Product Owner para el piloto. La convivencia permanente con VM 210 en ejecución requiere observación controlada posterior y no fue necesaria para aceptar la foundation.

---

## TEST IMPACT / RESULTADOS

- [x] Deployment limpio y health de PostgreSQL/server/worker.
- [x] VM 220 fue el único workload creado por la Story; VM 210 conserva fingerprint de configuración.
- [x] Docker socket ausente en worker.
- [x] Persistencia PostgreSQL y volúmenes verificados.
- [x] Backup `pg_dump -Fc` generado fuera de VM y validado con `pg_restore --list`.
- [x] Secret handling verificado.
- [x] `akadmin` existe, es superuser y la contraseña almacenada fuera de Git fue validada.
- [x] Scope scan sin objetos funcionales fuera de scope.
- [x] Recuperación administrativa local documentada.
- [x] Idempotencia demostrada para CreateVm y Deploy.
- [x] Host usage evidence corregida después de FIX y revalidada.

---

## QUALITY GATES

- [x] Project Scope Handshake = `PROJECT_SCOPE_OK`.
- [x] Independent Check = PASS WITH CONDITIONS.
- [x] Authorized Base y branch lineage verificadas.
- [x] Target VM dedicada en `pve-02`; VM 210 fuera de alcance de mutación.
- [x] Secret handling plan verificado.
- [x] Docker socket absent from worker.
- [x] No direct WAN exposure.
- [x] Persistencia PostgreSQL/volúmenes verificada.
- [x] PostgreSQL logical backup generated and stored outside the VM.
- [x] Backup/remediation and local administrative recovery verificados.
- [x] Health/API/UI checks PASS.
- [x] Initial CPU/RAM utilization captured for VM and host.
- [x] Scope scan PASS.
- [x] Secret review PASS.
- [x] Evidence sufficient for Technical Director review.
- [x] Evidence FIX `6bcd99024ef86f7819a957c2e17e2b9a442178f7` accepted.

---

## EXECUTION RESULT

```text
AIDE EXECUTION RESULT
Project: SETOK Family
Repository: SETOKCR/setok-family
Work Unit: ST-ID-001
Project Scope: PROJECT_SCOPE_OK
Authorized Base: e10279d1c31e3f02e5b7b4d4185d74f662a93877
Implementation Branch: feature/st-id-001
Implementation Commit: 6bcd99024ef86f7819a957c2e17e2b9a442178f7
Integration Commit: e6d1bffa65762b93069fdf480d5d67628e1fbdef
Scope: WITHIN WORK ORDER
Required Gates: PASS
Independent Check Conditions: PASS
Stop Conditions: NONE
Unexpected Surface: NONE — host capacity constraint was explicitly accepted for pilot execution and retained as operational follow-up
Technical Director Decision: ACCEPT
```

---

## Evidencia de cierre

- `docs/evidence/ST-ID-001/README.md`
- `docs/evidence/ST-ID-001/*.json`
- `infra/authentik/st-id-001.desired.json`
- `infra/authentik/compose.yml`
- `scripts/st-id-001/Invoke-StId001.ps1`
- `docs/development/ST-ID-001_INDEPENDENT_CHECK.md`

Operational follow-up: when Product Owner restarts VM 210, observe host/VM memory, swap and pressure before considering long-term capacity stable.
