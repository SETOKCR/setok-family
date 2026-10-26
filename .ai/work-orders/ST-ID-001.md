# WORK ORDER ST-ID-001

## Identidad

- **Project:** SETOK Family
- **Repository:** SETOKCR/setok-family
- **Story / Work Unit:** ST-ID-001
- **Authorized Base:** N/A — not authorized yet
- **Estado de ejecución:** BLOCKED
- **Implementation Authorization:** NO
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
- **Work Order:** BLOCKED — pending Independent Check and Authorized Base
- **Authorized Base:** N/A — not authorized yet
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

- [ ] Authentik self-hosted del piloto está desplegado y operativo en una **VM dedicada** sobre Proxmox `pve-02`.
- [ ] La VM existente `210 (setok-live-01)` no se modifica.
- [ ] Deployment base: Linux estable + Docker Engine + Docker Compose, siguiendo el método soportado por Authentik para esta escala.
- [ ] Sizing inicial: **2 vCPU, 2 GiB RAM y 32–40 GiB disco**; cualquier ampliación debe justificarse por evidencia observada.
- [ ] No existe exposición WAN directa no protegida; cualquier publicación externa posterior debe respetar la arquitectura.
- [ ] Desired state no secreto registra versión/despliegue, hostname/base URL, persistencia y configuración reproducible.
- [ ] PostgreSQL y volúmenes persistentes relevantes tienen backup/restore documentado y backup verificable.
- [ ] Bootstrap administrativo usa secretos fuera de Git; se prefiere password hash para `akadmin` frente a password plaintext cuando el método de instalación lo soporte.
- [ ] Secret key, PostgreSQL password y API tokens no aparecen en Git, logs persistidos ni evidencia versionada.
- [ ] Automatización futura queda separada de identidades humanas y usa service account/API token dedicado de menor privilegio cuando aplique.
- [ ] Health/API/UI checks confirman estado operativo y el estado observado coincide con el desired state verificable.
- [ ] No se crean usuarios reales del piloto, roles familiares, federación, OIDC de la app ni Access integration.
- [ ] Rollback/remediation está documentado y no impacta Cloudflare ni otros proyectos SETOK.

---

## ARCHITECTURE CONSTRAINTS

- Referencia: `docs/ARCHITECTURE.md` secciones 2, 5.2, 6.5, 7, 20 y 30.
- Authentik es Identity Plane, no Domain Core.
- Authentik no modela familias ni autorización Guardian ↔ Child.
- Piloto: self-hosted; Proxmox es válido como hosting del piloto pero no contrato de producto.
- Deployment de esta Story: VM dedicada sobre `pve-02`; no LXC/PCT.
- Docker Compose se ejecuta dentro de la VM Linux, no directamente sobre Proxmox ni dentro de la VM `setok-live-01`.
- No introducir HA comercial en esta Story.
- Configuración deseada versionada; secretos separados.
- API-first/automation-first donde exista API soportada.
- No exposición directa de servicios locales a Internet.
- Authentication y authorization deben mantenerse separadas.

---

## OUT OF SCOPE

- Usuarios reales Ulate León.
- Roles de dominio y relaciones familiares.
- Google/Microsoft/Apple federation.
- OIDC provider/application de `family.setok.cr`.
- Cloudflare Access + Authentik.
- Provider/device bindings.
- MFA de consumidores.
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

> La clasificación RED no impide la Story; exige diseño/revisión reforzada e Independent Check antes de autorización.

---

## TEST IMPACT

- Verificar despliegue limpio/repetible y health de componentes requeridos.
- Verificar que la VM dedicada es el único target mutado y que `setok-live-01` permanece intacta.
- Verificar sizing efectivo y registrar consumo inicial para decidir si 2 GiB son suficientes.
- Verificar persistencia PostgreSQL y volúmenes requeridos.
- Verificar backup generado y procedimiento de restore/remediation sin ejecutar destrucción innecesaria.
- Verificar que secretos no estén versionados ni expuestos en evidencia.
- Verificar que `akadmin` bootstrap no dependa de password plaintext persistido cuando sea evitable.
- Verificar que no se hayan creado objetos fuera de scope (usuarios piloto, OIDC, federation, Access).
- Verificar recuperación/administración inicial suficiente para evitar lockout de la foundation.
- Regression test de aplicación: N/A; infraestructura/identity checks obligatorios.
- Secure coding/security surfaces: authentication, secret handling, privileged bootstrap, least privilege, network exposure, persistence/backup.

---

## QUALITY GATES

- [ ] Project Scope Handshake = `PROJECT_SCOPE_OK` antes de mutación.
- [ ] Independent Check de arquitectura/seguridad para la foundation = PASS antes de autorización.
- [ ] Authorized Base congelado y branch de implementación verificada antes de mutación.
- [ ] Target: VM dedicada en `pve-02`; VM 210 explícitamente fuera de alcance.
- [ ] Secret handling plan verificado antes de bootstrap.
- [ ] Network exposure path verificado; no direct WAN exposure.
- [ ] Persistencia PostgreSQL/volúmenes verificada.
- [ ] Backup/remediation path verificado.
- [ ] Health/API/UI checks PASS.
- [ ] Scope scan: no usuarios reales, OIDC, federation, Access ni roles familiares creados.
- [ ] Secret scan/review PASS.
- [ ] Evidence set suficiente para Technical Director review.

---

## EXECUTION MODEL

Patrón preferido:

`Git desired state -> PowerShell/host automation -> VM Linux -> Docker Compose -> Authentik -> observed-state verification -> evidence`

Target de infraestructura aprobado por Product Owner para el piloto:

- Proxmox node: `pve-02`
- new dedicated VM: name target `setok-family-idp-01`
- initial sizing: 2 vCPU / 2 GiB RAM / 32–40 GiB disk
- guest: stable Linux
- runtime: Docker Engine + Docker Compose
- existing VM `210 (setok-live-01)`: DO NOT MODIFY
- direct WAN exposure: forbidden

No se introduce un framework genérico de automatización en esta Story.

Las credenciales bootstrap no se entregan al agente por Git ni por documentación persistente. Si se necesita intervención humana, el Product Owner realiza sólo el paso mínimo y el agente continúa con validación automatizada.

---

## DELIVERABLE

- Authentik pilot identity foundation operativa y verificable.
- Desired state no secreto de la foundation.
- Scripts/configuración específica necesaria para bootstrap/validation.
- Evidencia de health, persistencia, backup/remediation y secret separation.
- Evidencia de que `setok-live-01` no fue alterada.

---

## STOP CONDITIONS

- `PROJECT_SCOPE_MISMATCH` o `PROJECT_SCOPE_UNVERIFIED`.
- Independent Check no aprobado.
- Target host/namespace puede afectar otro proyecto o servicio y no puede aislarse.
- La ejecución requiere modificar `210 (setok-live-01)`.
- La implementación requiere exposición WAN directa no protegida.
- Requiere persistir secretos en Git o evidencia.
- Requiere crear usuarios reales, federation, OIDC, Access o autorización familiar para completar la foundation.
- Se necesita modificar arquitectura v1.4 de forma material.
- No puede definirse backup/remediation razonable para PostgreSQL/persistencia.
- Riesgo real excede lo evaluado o aparece otra superficie Auto-RED material no contemplada.

---

## Evidencia de cierre

- Project Scope outcome: pending
- Resultado: pending
- Gates ejecutados: pending
- Evidencia / referencias: pending
- Independent Check: pending
- Reuse Candidates detectados: N/A
- Unexpected Implementation Surface: N/A
