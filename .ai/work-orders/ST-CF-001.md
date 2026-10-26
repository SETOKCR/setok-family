# WORK ORDER ST-CF-001

## Identidad

- **Project:** SETOK Family
- **Repository:** SETOKCR/setok-family
- **Story / Work Unit:** ST-CF-001
- **Authorized Base:** `4fa82d531d1452b15b7fd409465cdcf7f7400b1e`
- **Implementation Branch:** `feature/st-cf-001`
- **Estado de ejecución:** READY
- **Implementation Authorization:** YES — Technical Director authorization after readiness revalidation
- **Persistencia:** PERSISTED
- **Motivo de persistencia:** multi-session / external-provider execution and evidence

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
- **Work Unit:** ST-CF-001
- **Work Order:** READY
- **Authorized Base:** `4fa82d531d1452b15b7fd409465cdcf7f7400b1e`
- **Implementation Branch:** `feature/st-cf-001`
- **Project Binding:** REQUIRED

---

## GOAL

Establecer y verificar la foundation mínima de Cloudflare Zero Trust para el tenant piloto de SETOK Family, dejando preparada la plataforma para las siguientes unidades de enforcement sin introducir todavía políticas parentales, autenticación/autorización de Access, enrolamiento de dispositivos ni automatización reusable.

---

## PRODUCT REQUIREMENT

- Referencia: `docs/PRODUCT.md`; Story `docs/stories/ST-CF-001.md`.
- Contexto mínimo: Fase 1 debe producir una plataforma parental funcional sin depender de SETOK Family App. Cloudflare Zero Trust es el primer Enforcement Provider y la complejidad del proveedor no debe convertirse en el dominio del producto.

---

## ACCEPTANCE CRITERIA

- [ ] Existe una organization/foundation Cloudflare Zero Trust inequívocamente asociada al tenant piloto.
- [ ] Su identidad técnica no secreta queda registrada en configuración/evidencia autorizada del proyecto.
- [ ] El modo objetivo de tráfico queda conforme a arquitectura (`Traffic + DNS`; MASQUE como transporte objetivo inicial donde aplique y sea soportado).
- [ ] Existe un único Device Profile técnico base para SETOK Family con los parámetros de hardening soportados en esta etapa.
- [ ] El estado aplicado se vuelve a consultar/observar y coincide con el desired state de los objetos incluidos en esta Story.
- [ ] No existen secretos, tokens, credenciales ni break-glass codes en Git.
- [ ] Los objetos creados pueden revertirse/eliminarse de forma identificable sin afectar recursos ajenos a SETOK Family.

---

## ARCHITECTURE CONSTRAINTS

- Referencia: `docs/ARCHITECTURE.md` secciones 2, 12, 20, 23, 24 y 27; ADR-009, ADR-010, ADR-014, ADR-021 y ADR-022.
- Cloudflare es provider, no dominio SETOK.
- Un único Device Profile técnico.
- Transporte de Cloudflare: WARP `Traffic + DNS`; MASQUE es el target inicial móvil sujeto a prueba real.
- Configuración deseada versionada y estado operativo observado separado.
- Secretos nunca hardcoded ni persistidos en Git.
- Menor privilegio para credenciales/API tokens.
- No crear exposición WAN directa.
- No introducir una decisión Type 1 nueva; una limitación real del proveedor que contradiga el baseline se eleva al Technical Director.

---

## OUT OF SCOPE

- Gateway baseline de seguridad/contenido y SafeSearch/YouTube Restricted.
- `STANDARD`, `RESTRICTED` y overlays temporales.
- Cloudflare Access + Authentik o cualquier cambio de authentication/authorization.
- Cloudflare Tunnel para publicación de la futura app.
- Authentik foundation.
- Android/iPad enrollment.
- ManageEngine MDM.
- Módulos PowerShell reutilizables, reconciliación general o cmdlets objetivo de Fase 1.
- SETOK Family App / mini app.

---

## RISK

- **Clasificación:** AMBER 4/10
- **Dimensiones:** Reversibilidad 1; Blast Radius 1; Datos/Estado 1; Seguridad/Finanzas 1; Contratos 0.
- **Razón principal:** crea/modifica configuración persistente en un proveedor de seguridad del tenant piloto; rollback es viable pero deliberado y el efecto puede alcanzar la foundation de enforcement del tenant.
- **Auto-RED aplicado:** No.
- **Auto-RED boundary:** si la ejecución requiere modificar materialmente authentication, authorization, privilege boundary, cryptography u otra superficie Auto-RED, detener y reclasificar antes de continuar.

---

## TEST IMPACT

- Verificación de configuración mediante lectura/consulta posterior al cambio; no aceptar sólo HTTP/API success.
- Validación de unicidad y parámetros del Device Profile base.
- Validación de modo `Traffic + DNS` y transporte objetivo cuando sea observable/configurable.
- Repetición controlada de consultas/acciones aplicables para demostrar ausencia de duplicación accidental en el scope autorizado.
- Verificación de que ningún secreto aparece en Git/diff/evidencia persistida.
- Prueba o walkthrough de rollback de los objetos creados, sin ejecutar destrucción irreversible sobre recursos ajenos.
- Regression test requerido: N/A para código de aplicación; sí verificación de no impacto sobre recursos Cloudflare preexistentes fuera del scope.
- Secure coding surfaces/evidence aplicables: secret handling, least privilege, provider API input/output handling si se usa scripting ad hoc.

---

## QUALITY GATES

- [ ] Project Scope Handshake = `PROJECT_SCOPE_OK` antes de mutación.
- [ ] Identidad de cuenta/organización Cloudflare objetivo verificada antes de crear/modificar objetos.
- [ ] Estado previo relevante capturado para rollback y para demostrar que no se altera un recurso ajeno.
- [ ] Configuración incluida en esta Story aplicada sin introducir superficies Out of Scope.
- [ ] Estado observado post-cambio coincide con el estado esperado.
- [ ] Device Profile único verificado.
- [ ] Secret scan/review: ningún token, secret, credential o break-glass code persistido.
- [ ] Rollback/remediation path verificado.
- [ ] Evidence set suficiente para revisión del Technical Director.
- [ ] Build/lint de aplicación: N/A para esta Story salvo que aparezca código no previsto, en cuyo caso detener por Unexpected Surface y revalidar Work Order.

---

## EXECUTION MODEL

### Standard deployment mechanism

SETOK Family utilizará, para configuraciones de proveedores que dispongan de API soportada, el siguiente patrón operativo:

`Git desired state -> PowerShell -> Provider API -> observed-state verification -> evidence`

PowerShell es el mecanismo estándar de ingeniería para bootstrap, despliegue, consulta, validación y rollback/remediation. Los scripts deben ser idempotentes o, cuando una operación del proveedor no pueda serlo, deben realizar comprobación previa suficiente para evitar duplicación accidental.

### Development Agent as default operator

La ejecución rutinaria será realizada por un Development Agent (por ejemplo Codex o Claude Code) con acceso local al repositorio y a PowerShell. El Product Owner no debe convertirse en operador manual habitual de scripts.

El Product Owner interviene únicamente cuando sea necesario por:

- autenticación interactiva, MFA o consentimiento humano;
- creación/entrega inicial de credenciales o API tokens que no puedan provisionarse de forma segura por el agente;
- aprobación explícita de una acción sensible o de alto impacto;
- validación física/visual que requiera un dispositivo o portal no accesible al agente;
- Stop Condition o decisión de producto que exceda la autoridad del Development Agent.

### Local workspace bootstrap

La primera tarea del Development Agent antes de implementar ST-CF-001 será preparar el workspace local en Windows:

```text
C:\Dev\SETOK\setok-family
```

El agente debe:

1. verificar que `C:\Dev\SETOK` existe o crearlo si está autorizado;
2. clonar `SETOKCR/setok-family` en `C:\Dev\SETOK\setok-family` si el repositorio todavía no está presente;
3. si ya existe, verificar que el remote corresponde exactamente a `SETOKCR/setok-family` y no sobrescribir trabajo local no reconocido;
4. obtener el `main` remoto y comprobar el Project Scope Handshake antes de cualquier mutación;
5. verificar que `feature/st-cf-001` desciende exactamente del Authorized Base `4fa82d531d1452b15b7fd409465cdcf7f7400b1e` antes de usarla;
6. trabajar únicamente en `feature/st-cf-001` para esta unidad;
7. no almacenar tokens, secretos ni material de autenticación en archivos versionados, comandos persistidos, logs de Git o evidencia destinada al repositorio.

La clonación y preparación del workspace son bootstrap operacional y no constituyen por sí mismas implementación funcional de Cloudflare.

### Script evolution

Para ST-CF-001 se permite crear scripts PowerShell específicos del scope cuando aporten reproducibilidad. No se debe anticipar todavía un framework general de automatización de Fase 1. Un script sólo se promueve a reusable estable cuando existe evidencia de repetición/valor suficiente; esa promoción pertenece a una unidad posterior del ROADMAP.

---

## DELIVERABLE

- Foundation Cloudflare Zero Trust del tenant piloto configurada y verificable dentro del scope de ST-CF-001.
- Configuración/evidencia no secreta estrictamente necesaria para reproducibilidad y revisión.
- Evidencia concisa de before/after, estado observado y rollback/remediation.
- Workspace local del Development Agent correctamente vinculado a `SETOKCR/setok-family` antes de cualquier mutación funcional.

---

## STOP CONDITIONS

- `PROJECT_SCOPE_MISMATCH` o `PROJECT_SCOPE_UNVERIFIED`.
- El workspace local existente en `C:\Dev\SETOK\setok-family` contiene cambios no reconocidos o apunta a otro remote y no puede reconciliarse de forma segura.
- La rama `feature/st-cf-001` no desciende del Authorized Base exacto o presenta commits no reconocidos antes del inicio del agente.
- La cuenta/organización Cloudflare objetivo no puede identificarse con certeza como autorizada para SETOK Family.
- La ejecución requiere cambiar authentication/authorization, privilege boundaries o cualquier superficie Auto-RED no prevista.
- Se requiere baseline policy, Access/Auth, Tunnel de app, enrolamiento, MDM o automatización reusable para completar esta unidad.
- Aparece una limitación confirmada de Cloudflare que contradice una decisión material de arquitectura v1.4.
- No puede asegurarse rollback sin afectar recursos ajenos al proyecto.
- Se requiere almacenar secretos en Git o exponerlos en evidencia persistente.
- El riesgo real excede AMBER 4/10 o un gate obligatorio no puede verificarse.

---

## Evidencia de cierre

- Project Scope outcome: pending
- Resultado: pending
- Gates ejecutados: pending
- Evidencia / referencias: pending
- Reuse Candidates detectados: N/A
- Unexpected Implementation Surface: N/A
