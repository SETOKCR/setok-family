# WORK ORDER ST-ID-001

## Identidad

- **Project:** SETOK Family
- **Repository:** SETOKCR/setok-family
- **Story / Work Unit:** ST-ID-001
- **Authorized Base:** `e10279d1c31e3f02e5b7b4d4185d74f662a93877`
- **Implementation Branch:** `feature/st-id-001`
- **Estado de ejecución:** BLOCKED_ON_INFRA_CAPACITY
- **Implementation Authorization:** PAUSED — Technical Director authorization remains valid, but creation of VM 220 is explicitly withheld pending sufficient host memory capacity or an alternate approved host
- **Persistencia:** PERSISTED
- **Motivo de persistencia:** RED / authentication foundation / multi-session / auditability

### Project Binding

Antes de cualquier mutación, el Development Agent debe verificar:

`Work Order Repository == .ai/AIDE_PROJECT.yaml project.repository == live repository`

Resultado requerido: `PROJECT_SCOPE_OK`.

---

## AIDE EXECUTION CONTEXT

- **Framework:** SETOK-AIDE v1.2.3
- **Project:** SETOK Family
- **Repository:** SETOKCR/setok-family
- **Role:** Development Agent
- **Work Unit:** ST-ID-001
- **Work Order:** BLOCKED_ON_INFRA_CAPACITY
- **Authorized Base:** `e10279d1c31e3f02e5b7b4d4185d74f662a93877`
- **Implementation Branch:** `feature/st-id-001`
- **Project Binding:** REQUIRED

---

## GOAL

Establecer la foundation self-hosted de Authentik para el piloto de SETOK Family, con persistencia, bootstrap administrativo seguro, backup/restore y verificación de estado, sin crear todavía identidades reales del tenant, autorización familiar, federation, OIDC de la app ni Cloudflare Access.

---

## PRODUCT REQUIREMENT

- Referencia: `docs/PRODUCT.md`; Story `docs/stories/ST-ID-001.md`.
- Contexto mínimo: Authentik autentica personas; SETOK Family autoriza acciones dentro de familias. La familia no es un tenant Authentik.

---

## ACCEPTANCE CRITERIA

- [ ] Authentik self-hosted del piloto está desplegado y operativo en una **VM dedicada** sobre Proxmox `pve-02` o en otro host expresamente aprobado por el Technical Director.
- [ ] La VM existente `210 (setok-live-01)` no se modifica.
- [ ] Deployment base: Linux estable + Docker Engine + Docker Compose v2, siguiendo el método soportado por Authentik para esta escala.
- [ ] Sizing inicial de Authentik: **2 vCPU, 2 GiB RAM y 32–40 GiB disco**; Authentik no se reducirá por debajo de 2 GiB para resolver presión de memoria del host.
- [ ] El host seleccionado conserva margen operativo razonable cuando todos los workloads existentes vuelvan a su estado normal; no se acepta depender de que VM 210 permanezca detenida.
- [ ] El mount `/var/run/docker.sock` del compose upstream se elimina mientras Outposts sigan fuera de scope.
- [ ] No existe exposición WAN directa no protegida; cualquier publicación externa posterior debe respetar la arquitectura.
- [ ] Desired state no secreto registra versión/despliegue, hostname/base URL, persistencia y configuración reproducible.
- [ ] PostgreSQL y volúmenes persistentes relevantes tienen backup/restore documentado y backup verificable.
- [ ] Se genera al menos un backup lógico PostgreSQL y se almacena fuera de la VM de Authentik.
- [ ] Bootstrap administrativo usa secretos fuera de Git; se utiliza `AUTHENTIK_BOOTSTRAP_PASSWORD_HASH` cuando el método de instalación lo soporte.
- [ ] Secret key, PostgreSQL password, bootstrap hash y API tokens no aparecen en Git, logs persistidos ni evidencia versionada.
- [ ] Automatización futura queda separada de identidades humanas y usa service account/API token dedicado de menor privilegio cuando aplique.
- [ ] Health/API/UI checks confirman estado operativo y el estado observado coincide con el desired state verificable.
- [ ] Se registra consumo inicial de CPU/RAM tras estabilización del stack.
- [ ] No se crean usuarios reales del piloto, roles familiares, federación, OIDC de la app ni Access integration.
- [ ] Rollback/remediation y recuperación administrativa local quedan documentados sin exponer secretos.
- [ ] Rollback/remediation no impacta Cloudflare ni otros proyectos SETOK.

---

## ARCHITECTURE CONSTRAINTS

- Referencia: `docs/ARCHITECTURE.md` secciones 2, 5.2, 6.5, 7, 20 y 30.
- Authentik es Identity Plane, no Domain Core.
- Authentik no modela familias ni autorización Guardian ↔ Child.
- Piloto: self-hosted; Proxmox es válido como hosting del piloto pero no contrato de producto.
- Deployment preferido de esta Story: VM dedicada; no LXC/PCT.
- Docker Compose se ejecuta dentro de la VM Linux, no directamente sobre Proxmox ni dentro de `setok-live-01`.
- No introducir HA comercial en esta Story.
- Configuración deseada versionada; secretos separados.
- API-first/automation-first donde exista API soportada.
- No exposición directa de servicios locales a Internet.
- Authentication y authorization deben mantenerse separadas.

---

## OUT OF SCOPE

- Modificar, reducir, balloon/reconfigurar o depender del apagado permanente de `210 (setok-live-01)` para liberar recursos.
- Usuarios reales Ulate León.
- Roles de dominio y relaciones familiares.
- Google/Microsoft/Apple federation.
- OIDC provider/application de `family.setok.cr`.
- Cloudflare Access + Authentik.
- Provider/device bindings.
- MFA de consumidores.
- Authentik Outposts.
- HA comercial.
- LXC/PCT para Authentik en esta Story.
- SETOK Family App / mini app.

---

## RISK

- **Clasificación:** RED (Auto-RED `authentication`)
- **Score ordinario:** 5/10
- **Dimensiones:** Reversibilidad 1; Blast Radius 1; Datos/Estado 1; Seguridad/Finanzas 2; Contratos 0.
- **Razón principal:** la Story establece el mecanismo autoritativo de autenticación humana del producto.
- **Auto-RED aplicado:** Sí — `authentication`.
- **Independent Check:** PASS WITH CONDITIONS — `docs/development/ST-ID-001_INDEPENDENT_CHECK.md`.
- **Execution gate added:** Proxmox capacity. Observed host capacity is approximately 7.8 GiB total. Normal combined demand of VM 210 (4 GiB), planned Authentik VM (2 GiB) and host overhead (~1.3 GiB) leaves only ~0.5 GiB headroom. Technical Director rejects accepting that operational risk.

---

## TEST IMPACT

- Verify selected host has sufficient sustained memory capacity with existing workloads in normal operation.
- Verify deployment does not rely on VM 210 being stopped.
- Verify deployment clean/repeatable and health of required components.
- Verify the dedicated VM is the only target mutated and `setok-live-01` remains unchanged.
- Verify sizing effective and capture utilization.
- Verify worker does not receive Docker socket while Outposts are out of scope.
- Verify PostgreSQL persistence and required volumes.
- Verify logical backup generated and stored outside the VM.
- Verify secrets absent from Git/evidence.
- Verify no out-of-scope objects are created.

---

## QUALITY GATES

- [ ] Project Scope Handshake = `PROJECT_SCOPE_OK` before mutation.
- [x] Independent Check = PASS WITH CONDITIONS.
- [x] Authorized Base and implementation branch lineage verified.
- [ ] **Infrastructure capacity gate:** sufficient host RAM/headroom demonstrated for VM 210 + Authentik VM + Proxmox host under normal operation, or alternate host explicitly approved.
- [ ] Target VM isolated; VM 210 remains out of scope.
- [ ] Secret handling plan verified before bootstrap.
- [ ] Docker socket absent from worker.
- [ ] No direct WAN exposure.
- [ ] PostgreSQL persistence/backup verified.
- [ ] Health/API/UI checks PASS.
- [ ] Initial CPU/RAM utilization captured.
- [ ] Scope and secret scans PASS.
- [ ] Evidence sufficient for Technical Director review.

---

## EXECUTION MODEL

Preferred pattern:

`Git desired state -> PowerShell/host automation -> dedicated Linux VM -> Docker Compose -> Authentik -> observed-state verification -> evidence`

Previously approved target:

- Proxmox node: `pve-02` / `192.168.89.20`
- planned VMID: `220`
- planned name: `setok-family-idp-01`
- Authentik sizing: 2 vCPU / 2 GiB RAM / 32–40 GiB disk
- existing VM `210 (setok-live-01)`: DO NOT MODIFY

Current execution status:

- VM 220 has **not** been created.
- A local permission guard blocked the attempted create command before mutation.
- Creation remains prohibited until the infrastructure capacity gate is closed.
- Acceptable closure paths: add physical RAM to `pve-02` (preferred), or select another suitable host with sufficient sustained capacity and obtain Technical Director approval.

---

## STOP CONDITIONS

- `PROJECT_SCOPE_MISMATCH` or `PROJECT_SCOPE_UNVERIFIED`.
- Authorized Base/branch lineage not verifiable.
- Host capacity requires accepting material memory pressure on VM 210 or Proxmox.
- Execution requires modifying, shrinking, ballooning, stopping or otherwise changing VM 210 to make room.
- Target host/namespace can affect another project/service and cannot be isolated.
- Direct unprotected WAN exposure is required.
- Docker socket must remain mounted.
- Secrets must be persisted in Git/evidence.
- Real users, federation, OIDC, Access, Outposts or family authorization become necessary.
- PostgreSQL logical backup cannot be produced outside the VM.
- Material architecture change is required.

---

## Evidencia de cierre

- Project Scope outcome: `PROJECT_SCOPE_OK` reported by Development Agent before execution attempt.
- Resultado: paused before infrastructure mutation.
- Gates ejecutados: Independent Check PASS WITH CONDITIONS; Authorized Base/branch frozen; SSH target `pve-02` confirmed; infrastructure capacity gate OPEN.
- Evidence / references: `docs/development/ST-ID-001_INDEPENDENT_CHECK.md` plus Development Agent runtime discovery.
- Independent Check: PASS WITH CONDITIONS.
- VM 220 created: NO.
- VM 210 modified by this Story: NO.
- Reuse Candidates detectados: N/A.
- Unexpected Implementation Surface: host memory capacity constraint on `pve-02`.
