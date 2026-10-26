# ST-CF-001 — Establish Cloudflare Zero Trust pilot foundation

**Epic:** Phase 1 — Infrastructure, Enforcement and Identity  
**Tamaño:** M

## 1. Resultado esperado

- El tenant piloto dispone de una foundation de Cloudflare Zero Trust creada y verificable para soportar posteriormente enforcement, perfiles, políticas y enrolamiento de dispositivos de SETOK Family.
- La foundation establece únicamente los objetos y parámetros base necesarios para continuar las siguientes unidades sin introducir todavía políticas parentales, integración Authentik/Access ni automatización reusable.

---

## 2. Requisito / contexto de producto

- Referencia: `docs/PRODUCT.md` y `docs/ARCHITECTURE.md` secciones 12, 20 y 27.
- Contexto mínimo: Fase 1 debe entregar una plataforma parental funcional sin depender de SETOK Family App. Cloudflare Zero Trust es el primer Enforcement Provider y debe permanecer detrás de la abstracción definida por la arquitectura.

---

## 3. Acceptance Criteria

- [ ] Existe una organización/foundation Cloudflare Zero Trust identificable para el tenant piloto y su identidad técnica queda registrada sin secretos en el estado/versionado autorizado del proyecto.
- [ ] El modo de cliente/túnel objetivo para la foundation queda configurado conforme a la arquitectura aprobada (`Traffic + DNS`; MASQUE como transporte objetivo inicial donde aplique) sin introducir políticas parentales todavía.
- [ ] Existe un único Device Profile técnico base para SETOK Family, con los parámetros de hardening previstos por la arquitectura que sean soportados y verificables en esta etapa.
- [ ] La configuración aplicada puede observarse nuevamente en Cloudflare y existe evidencia de que el estado esperado coincide con el estado real para los objetos creados en esta Story.
- [ ] No se almacenan API tokens, credenciales, secretos ni códigos break-glass en Git.
- [ ] La Story no introduce dependencia del dominio SETOK hacia IDs/sintaxis de Cloudflare más allá de bindings/configuración de provider que correspondan a infraestructura.
- [ ] Existe una ruta documentada de reversión/eliminación de los objetos creados por esta Story sin afectar recursos ajenos a SETOK Family.

---

## 4. Out of Scope

- Baseline de malware/phishing/C2/contenido adulto/apuestas/SafeSearch/YouTube Restricted.
- Modos `STANDARD` / `RESTRICTED` y overlays temporales.
- Cloudflare Access integrado con Authentik y cualquier decisión de autenticación/autorización.
- Cloudflare Tunnel de publicación de SETOK Family App.
- Authentik foundation.
- Enrolamiento Android o iPad.
- ManageEngine MDM.
- Automatización PowerShell reusable y reconciliación general de Fase 1.
- SETOK Family App / mini app.

---

## 5. Dependencias / precondiciones

- Acceso administrativo autorizado a la cuenta Cloudflare que alojará el tenant piloto.
- Posibilidad de crear un API Token de menor privilegio si la configuración/validación se realiza por API; el secreto permanece fuera de Git.
- No debe reutilizarse o alterar silenciosamente una organización/objeto Cloudflare perteneciente a otro proyecto o cliente.
- La ejecución debe poder identificar de forma inequívoca qué objetos pertenecen a SETOK Family para permitir rollback seguro.

---

## 6. Decisiones pendientes que impiden READY

N/A. La arquitectura v1.4 ya decide proveedor, transporte objetivo, Device Profile único, separación de secretos y límites de esta foundation. Cualquier limitación real del proveedor descubierta durante ejecución activa Stop Condition y se eleva al Technical Director.
