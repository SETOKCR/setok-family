# ST-ID-001 — Establish Authentik pilot identity foundation

**Epic:** Phase 1 — Infrastructure, Enforcement and Identity  
**Tamaño:** M

## 1. Resultado esperado

- Existe una instancia Authentik self-hosted operativa para el piloto de SETOK Family y preparada para alojar posteriormente identidades humanas, MFA, federación y OIDC sin modelar familias dentro del IdP.
- La foundation dispone de persistencia, bootstrap administrativo seguro, backup/restore verificable y una superficie de automatización separada de la identidad humana.

---

## 2. Requisito / contexto de producto

- Referencia: `docs/PRODUCT.md` y `docs/ARCHITECTURE.md` secciones 2, 5.2, 6.5, 7, 20 y 30.
- Contexto mínimo: Authentik es el IdP principal del piloto y primera etapa. Authentication pertenece a Authentik; authorization familiar pertenece a SETOK Family. La familia no debe representarse como tenant Authentik.

---

## 3. Acceptance Criteria

- [ ] Existe una instancia Authentik self-hosted del piloto desplegada en una **VM dedicada** sobre Proxmox `pve-02`, sin modificar la VM existente `210 (setok-live-01)`.
- [ ] La VM piloto usa Linux estable y el método soportado por el fabricante para esta escala: Docker Engine + Docker Compose.
- [ ] Baseline inicial de recursos: **2 vCPU, 2 GiB RAM y 32–40 GiB de disco**, sujeto a observación posterior y ampliación si la evidencia real lo requiere.
- [ ] La instancia es accesible únicamente por una ruta soportada/segura, sin exposición WAN directa no protegida.
- [ ] La versión/despliegue, hostname/base URL operativo, persistencia y parámetros no secretos necesarios para reproducibilidad quedan registrados como desired state autorizado.
- [ ] PostgreSQL y cualquier volumen persistente requerido por la foundation tienen una estrategia de backup/restore documentada y se verifica al menos la capacidad de generar un backup utilizable sin incluir secretos en Git.
- [ ] El bootstrap administrativo evita persistir contraseña de `akadmin`, secret key, PostgreSQL password o API tokens en Git; cualquier credencial operativa se mantiene fuera del repositorio.
- [ ] La administración humana inicial queda separada de una futura identidad de automatización; cualquier API token de automatización utiliza una cuenta/credencial dedicada y menor privilegio cuando se habilite.
- [ ] La instancia responde correctamente a health/API/UI checks definidos para la foundation y su estado observado coincide con el desired state verificable de esta Story.
- [ ] No se crean todavía miembros del tenant piloto, roles familiares, aplicaciones OIDC de SETOK Family, federación social ni integración Cloudflare Access.
- [ ] Existe rollback/remediation documentado para retirar o reconstruir la foundation sin afectar Cloudflare ni otros proyectos SETOK.

---

## 4. Out of Scope

- Usuarios reales del tenant Ulate León y sus credenciales.
- Roles `Owner`, `Parent`, `Viewer` como autorización de dominio.
- Relaciones Guardian ↔ Child.
- Federación con Google, Microsoft, Apple u otros IdP.
- Aplicación/provider OIDC para `family.setok.cr`.
- Cloudflare Access + Authentik.
- MFA obligatorio para usuarios finales; sólo bootstrap/administración segura de la foundation.
- Provider bindings de dispositivos.
- SETOK Family App / mini app.
- Alta disponibilidad comercial.
- Contenedor Proxmox LXC/PCT como deployment de esta Story.

---

## 5. Dependencias / precondiciones

- Proxmox `pve-02` disponible como hosting del piloto. Proxmox no se convierte en dependencia estructural del producto.
- Crear una VM dedicada nueva para Authentik; `210 (setok-live-01)` queda explícitamente fuera de alcance.
- Linux estable + Docker Engine + Docker Compose para seguir el deployment soportado por Authentik para esta escala.
- DNS/hostname operativo para el IdP debe resolverse antes de exponerlo a integraciones posteriores. El hostname concreto es configuración operacional de esta Story, no un dominio familiar.
- El Development Agent debe poder ejecutar configuración de infraestructura o detenerse si requiere una credencial/acción humana del Product Owner.
- Secretos de bootstrap deben almacenarse fuera de Git mediante mecanismo seguro local/host.

---

## 6. Decisiones de preflight

- **Hosting:** Proxmox `pve-02`.
- **Isolation boundary:** VM dedicada; no reutilizar `setok-live-01`.
- **Deployment:** Docker Compose sobre Linux en VM.
- **Sizing inicial:** 2 vCPU / 2 GiB RAM / 32–40 GiB disco.
- **HA:** no requerida para el piloto.
- **Direct WAN exposure:** prohibida.
- **Independent Check:** obligatorio por `Auto-RED(authentication)` antes de autorización de implementación.
- **Authorized Base / branch:** aún no congelados.
