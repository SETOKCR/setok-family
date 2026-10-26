# SETOK Family — Arquitectura de Referencia v1.4

**Estado:** BASELINE APPROVED / ARCHITECTURE FROZEN  
**Producto:** SETOK Family  
**Hostname objetivo:** `family.setok.cr`  
**Tenant piloto:** Ulate León  
**Fecha:** 2026-10-25  
**Reemplaza:** Arquitectura de Referencia v1.3

---

## 1. Propósito

Este documento define la arquitectura de referencia para **SETOK Family**, una plataforma de control parental, seguridad y bienestar digital diseñada desde el inicio como una solución **multi-tenant**, aunque su primera implementación se realizará para una sola familia: **Ulate León**.

La arquitectura busca dos objetivos simultáneos:

1. entregar una solución técnicamente robusta para el tenant piloto;
2. conservar una evolución limpia hacia un producto comercial de alta adopción.

La facilidad de uso es un requisito arquitectónico, no únicamente de interfaz. SETOK Family debe ocultar la complejidad técnica y presentar a padres e hijos conceptos humanos, comprensibles y reversibles.

La arquitectura separa explícitamente:

- identidad humana;
- relaciones familiares;
- identidad técnica de dispositivos;
- experiencia de padres e hijos;
- onboarding y aprovisionamiento;
- intención de política;
- enforcement de seguridad y navegación;
- controles nativos de cada plataforma;
- administración MDM cuando aporte valor;
- automatización de infraestructura;
- observabilidad y auditoría.

---

## 2. Principios arquitectónicos

1. **Multi-tenant desde el modelo, single-tenant en la primera puesta en producción.**
2. **Identidad humana separada de identidad de dispositivo.**
3. **La familia es una entidad del dominio SETOK, no un tenant del IdP ni del proveedor de enforcement.**
4. **El enforcement no depende de la aplicación SETOK Family.** Si la aplicación está fuera de servicio, las políticas ya aplicadas deben continuar funcionando.
5. **Provider abstraction.** Cloudflare y ManageEngine son proveedores iniciales, no dependencias estructurales del dominio SETOK.
6. **API-first / automation-first.** Todo lo que disponga de API soportada debe poder aprovisionarse, validarse y reconciliarse por scripts PowerShell.
7. **PowerShell no forma parte del runtime de la mini app.** Se utiliza para ingeniería, despliegue, configuración, auditoría y troubleshooting.
8. **Una sola autoridad primaria por política.** Cada tipo de control debe tener una capa responsable principal.
9. **Policy Intent antes que sintaxis de proveedor.** El dominio expresa intención; los adaptadores traducen esa intención a Cloudflare, MDM u otros proveedores.
10. **Menor privilegio y separación de secretos.**
11. **Controles nativos como autoridad primaria de tiempo de pantalla y aplicaciones cuando resulten superiores a un MDM.**
12. **MDM sólo donde aporte control real sin degradar la experiencia parental.**
13. **Sin exposición directa de servicios locales a Internet.**
14. **Configuración deseada versionada; estado operativo separado.**
15. **Progressive disclosure.** La protección básica debe ser simple; las capacidades avanzadas deben habilitarse progresivamente.
16. **Common task ≤ 2 taps.** Las acciones parentales frecuentes deben poder ejecutarse en uno o dos pasos desde la pantalla principal.
17. **No technical jargon in consumer UX.** El usuario ve “Protegido”, “Modo Estudio” o “Necesita atención”, no WARP, posture, MDM UUID o Gateway rule IDs.
18. **Reversible by design.** Los cambios cotidianos deben poder deshacerse o expirar automáticamente.
19. **Child transparency.** El menor debe entender por qué algo está bloqueado y, cuando aplique, disponer de un flujo de solicitud de excepción.
20. **Fail safe.** Una caída de SETOK Family no debe desactivar el enforcement ya aplicado.
21. **Child-first scope.** La intención parental se expresa por defecto sobre el hijo y se compila hacia todos sus dispositivos compatibles; el alcance por dispositivo es una excepción explícita.
22. **Asynchronous truth.** Ninguna operación contra proveedores se considera aplicada sólo porque la API respondió correctamente; SETOK debe distinguir `REQUESTED`, `APPLYING`, `APPLIED` y `FAILED`.
23. **Idempotency by design.** Las acciones repetidas o reintentadas no deben duplicar reglas ni producir efectos inconsistentes.
24. **Policy precedence belongs to SETOK.** La prioridad funcional entre baseline, horarios, modos, excepciones y acciones de emergencia se resuelve en el dominio antes de compilar hacia proveedores.
25. **Freshness-aware protection.** Un dispositivo no puede mostrarse indefinidamente como protegido si no existe evidencia reciente; el estado incluye frescura y nivel de confianza.
26. **Relationship-based authorization.** Los permisos parentales pueden limitarse por relación `Guardian ↔ Child`, no únicamente por rol global dentro de la familia.
27. **Network reality is part of UX.** Portales cautivos, redes incompatibles, viajes y pérdida de conectividad deben traducirse a estados y remediaciones comprensibles.
28. **Notifications are product infrastructure.** Solicitudes y cambios importantes requieren un plano de notificación propio, no polling manual del dashboard.
29. **Privacy by default.** SETOK protege y explica; no debe convertirse por defecto en una herramienta de vigilancia exhaustiva de navegación.
30. **Essential services survive parental modes.** Los modos cotidianos no deben bloquear accidentalmente servicios esenciales definidos por la familia; el baseline de seguridad mantiene precedencia.
31. **Consumer continuity.** Una falla de SETOK o de un proveedor no debe dejar silenciosamente a un menor sin conectividad útil durante periodos prolongados ni desactivar protección sin visibilidad.
32. **Last Known Good.** Los cambios significativos de política deben versionarse y conservar una última configuración confirmada como válida para reconciliación o rollback.
33. **Lifecycle aware.** Dispositivos, membresías y ownership tienen ciclo de vida explícito: alta, reemplazo, pérdida, retiro, offboarding y recuperación.

---

## 3. Marca, producto y dominios

### 3.1 Marca

- **Marca paraguas:** SETOK
- **Producto:** SETOK Family

Nombre comercial:

> **SETOK Family**  
> Seguridad y bienestar digital para familias.

### 3.2 Hostnames

- Sitio/brand principal: `setok.cr`
- Aplicación de consumidor: `family.setok.cr`
- Consola administrativa futura: `admin.family.setok.cr`
- API futura, si se separa del monolito: `api.family.setok.cr`

`app.setok.cr` no se utilizará para este producto porque ya está asignado a otro servicio.

### 3.3 Familias y dominios

Las familias **no necesitan dominio propio**.

Los usuarios pueden autenticarse con cualquier correo válido, por ejemplo:

- Gmail;
- Outlook / Hotmail;
- iCloud;
- correo corporativo;
- otros proveedores federables.

Dominios personales como `ulateleon.com` podrán utilizarse en el tenant piloto como detalle práctico de integración, pero no forman parte del modelo obligatorio del producto.

---

## 4. Vista lógica de alto nivel

```text
                         SETOK FAMILY
                        family.setok.cr
                               │
                     EXPERIENCE PLANE
                               │
                ┌──────────────┴──────────────┐
                │                             │
        Parent Experience              Child Experience
                │                             │
                └──────────────┬──────────────┘
                               │
                     ENROLLMENT / ONBOARDING
                               │
                         IDENTITY PLANE
                               │
                            Authentik
                               │
                      DOMAIN / POLICY CORE
                               │
      Family → Members → Children → Devices → Protection State
                               │
                       Policy Intent Engine
                               │
                       Policy Compiler Layer
                               │
             ┌─────────────────┴──────────────────┐
             │                                    │
      ENFORCEMENT PROVIDERS                DEVICE MGMT PROVIDERS
             │                                    │
       Cloudflare Adapter                  ManageEngine Adapter
             │                                    │
       Cloudflare Zero Trust                     MDM
             │
        ┌────┴────┐
        │         │
      iPad      Android
        │         │
 Screen Time   Family Link
```

---

## 5. Arquitectura por planos

### 5.1 Experience Plane

Responsable de la experiencia visible para padres e hijos.

Incluye:

- Parent Web/PWA;
- Child Experience;
- onboarding;
- solicitudes de tiempo o acceso;
- explicación de bloqueos;
- protección y estado de dispositivos;
- acciones rápidas.

No expone conceptos técnicos de proveedores.

### 5.2 Identity Plane

Responsable de autenticación humana.

Proveedor inicial: **Authentik self-hosted**.

### 5.3 Domain Core

Responsable del modelo funcional SETOK:

```text
Family
 ├── Members / Guardians
 ├── Children
 │    └── Devices
 ├── Policy Intents
 ├── Overrides
 ├── Protection State
 └── Audit Events
```

### 5.4 Policy Plane

Responsable de transformar una intención humana en reglas técnicas.

```text
UI Mode / Action
      ↓
Policy Intent
      ↓
Policy Compiler
      ↓
Provider Adapter
      ↓
Cloudflare / MDM / future provider
```

### 5.5 Enforcement Plane

Responsable de aplicar decisiones de navegación, seguridad y acceso.

**Cloudflare es el primer Enforcement Provider, no el dominio de SETOK Family.**

### 5.6 Device Management Plane

Responsable del hardening y administración técnica del dispositivo cuando sea necesario.

**ManageEngine es el primer Device Management Provider, no un requisito permanente del producto.**

### 5.7 Automation Plane

Responsable de bootstrap, despliegue, validación y reconciliación de infraestructura mediante PowerShell/API.

---

## 6. Modelo multi-tenant

### 6.1 Entidades principales

```text
Platform
  └── Family / Tenant
       ├── Members / Guardians
       ├── Children
       │    └── Devices
       ├── Provider Integrations
       ├── Policy Configuration
       ├── Temporary Overrides
       └── Audit Events
```

### 6.2 Tenant inicial

```text
Family: Ulate León
  ├── Parent(s)
  └── Child: Yandari
       ├── iPad
       └── Redmi Note 14 Pro
```

### 6.3 Aislamiento

Toda entidad operativa debe llevar `tenant_id`.

Nunca deben existir consultas del tipo:

```sql
SELECT * FROM devices WHERE id = ?
```

sin contexto de tenant.

Patrón conceptual correcto:

```sql
SELECT *
FROM devices
WHERE id = ?
  AND tenant_id = ?
```

La autenticación identifica a la persona; SETOK Family decide a qué familias pertenece y qué puede hacer dentro de cada una.

### 6.4 Autorización Guardian ↔ Child

El rol dentro de una familia no es suficiente para representar todas las configuraciones familiares reales. SETOK Family soportará relaciones explícitas entre responsables y menores.

```text
GuardianChildPermission
  guardian_user_id
  child_id
  permissions
  status
```

Capacidades iniciales posibles:

- `manage_policy`;
- `approve_requests`;
- `view_activity`;
- `manage_devices`;
- `manage_screen_time`.

El comportamiento por defecto para familias simples podrá seguir siendo “todos los Parents administran todos los Children”, pero el modelo debe permitir restricciones por hijo sin rediseño posterior.

### 6.5 Authentik no modela familias

No utilizar la función de multi-tenancy de Authentik como representación de familias.

```text
Authentik = identidad
SETOK Family = dominio familiar
```

---

## 7. Plano de identidad

### 7.1 Authentik

SETOK Family utilizará **Authentik self-hosted** como IdP principal durante el piloto y primera etapa del producto.

Responsabilidades:

- usuarios;
- grupos;
- MFA;
- passkeys/WebAuthn cuando corresponda;
- OIDC;
- SAML/SCIM si se requieren en el futuro;
- federación con Google, Microsoft, Apple u otros IdP.

Authentik **no** es la base de datos del dominio familiar.

### 7.2 Autenticación de consumidor vs administración

#### Piloto

Se permite:

```text
family.setok.cr
      ↓
Cloudflare Access
      ↓
Authentik
      ↓
SETOK Family
```

#### Target de producto

La experiencia de consumidor debe evolucionar hacia:

```text
family.setok.cr
      ↓
SETOK Family
      ↓ OIDC
Authentik
```

La consola administrativa puede mantener una capa adicional:

```text
admin.family.setok.cr
      ↓
Cloudflare Access
      ↓
Authentik + MFA
```

Cloudflare Access se considera excelente para el piloto y para superficies administrativas, pero no una dependencia obligatoria de la experiencia final de consumidor.

### 7.3 Autenticación vs autorización

**Authentication**

```text
¿Quién eres?
→ Authentik / OIDC
```

**Authorization**

```text
¿Qué puedes hacer dentro de qué familia?
→ SETOK Family
```

### 7.4 Roles iniciales

- `Owner`
- `Parent`
- `Viewer`

### 7.5 Hijos sin cuenta obligatoria

Un `Child` puede existir sin identidad de login.

Si se habilita experiencia infantil —por ejemplo solicitar tiempo extra— se podrá asociar una identidad humana al `Child`.

### 7.6 Ownership y recuperación de familia

SETOK Family debe evitar que una familia quede permanentemente inaccesible si el único `Owner` pierde su identidad principal. Durante onboarding se recomendará:

- registrar un segundo `Owner` o responsable de confianza; y/o
- configurar un mecanismo de recuperación fuerte soportado por el IdP.

La recuperación administrativa debe validar identidad con controles equivalentes al nivel de privilegio recuperado. SETOK no implementará recuperación trivial que permita convertir un simple acceso a correo en control total de una familia.

---

## 8. Identidad de dispositivo

### 8.1 Principio

Un dispositivo no debe representarse en el modelo central como una cuenta de correo humana.

SETOK Family mantiene una identidad interna propia:

```text
device_id = ULID/UUID
child_id
platform
display_name
status
```

### 8.2 Provider bindings

La relación con proveedores externos se desacopla:

```text
provider_device_bindings
  id
  tenant_id
  device_id
  provider
  external_device_id
  external_identity
  metadata
  status
```

Esto permite que el mismo dispositivo tenga múltiples vinculaciones técnicas.

### 8.3 Tenant piloto

Durante Fase 1 se permite utilizar como mecanismo práctico:

- `ipad-yandari@ulateleon.com`
- `movil-yandari@ulateleon.com`

Estas identidades son un detalle de integración del tenant piloto y no forman parte del modelo de producto.

### 8.4 Device Registry

SETOK Family mantendrá un registro interno de dispositivos independiente de Cloudflare, MDM u otros proveedores.

El `device_id` interno es la referencia estable; los IDs del proveedor son bindings reemplazables.

---

## 9. Protection State

SETOK Family debe traducir múltiples señales técnicas a un estado comprensible.

Estados iniciales:

```text
PROTECTED
ATTENTION_REQUIRED
DEGRADED
OFFLINE
SETUP_REQUIRED
UNKNOWN
```

Cada evaluación incluirá además:

```text
confidence = HIGH | MEDIUM | LOW
last_verified_at
freshness_seconds
```

Un estado `PROTECTED` sin telemetría reciente no debe permanecer visualmente como protección confirmada. Cuando la evidencia expire, el estado debe degradarse a `UNKNOWN`, `OFFLINE` o `ATTENTION_REQUIRED` según las señales disponibles.

Ejemplo interno:

```text
ProtectionState = PROTECTED
  cloudflare_connected = true
  baseline_active = true
  native_controls_ok = true
  device_recently_seen = true
  mdm_compliant = true/optional
```

Experiencia visible:

```text
🟢 Protegido
```

No se deben exponer directamente WARP, posture, MDM compliance IDs o detalles equivalentes salvo en vistas técnicas reservadas.

### 9.1 Setup Health

Cada dispositivo tendrá un indicador de completitud del onboarding:

```text
Protection setup
██████████ 100%

✓ Internet protection
✓ SafeSearch
✓ Adult content
✓ Native parental controls
✓ Anti-removal
```

Los errores deben traducirse a acciones concretas:

> El iPad de Yandari no está completamente protegido. Cloudflare necesita reconectarse. **Corregir**.

---

## 10. Policy Intent Engine

### 10.1 Motivo

Los padres no deben administrar reglas de proveedor.

La interfaz expresa una intención:

```text
Normal
Restringido
Modo Estudio
Pausar ocio
Permitir redes 30 min
```

El core transforma esa intención en un `Policy Intent`.

### 10.2 Modelo conceptual

```text
PolicyIntent
  social_media
  gaming
  streaming
  adult_content
  safe_search
  youtube_restricted
  schedule
  temporary_expiration
```

### 10.3 Compilación

```text
Policy Intent
      ↓
Policy Compiler
      ↓
CloudflareEnforcementProvider
      ↓
Gateway rules / lists / schedules
```

En el futuro puede existir:

```text
Policy Intent
      ↓
AnotherEnforcementProvider
```

sin cambiar la experiencia ni el dominio.

### 10.4 Precedencia funcional de políticas

SETOK define la precedencia antes de traducir la intención a un proveedor. Orden conceptual inicial:

```text
1. Security / Threat Baseline
2. Mandatory Safety Restrictions
3. Essential Services Availability
4. Emergency Parent Actions
5. Temporary Explicit Parent Override
6. Active Mode
7. Recurring Schedule
8. Default Family Policy
```

El motor debe generar una `PolicyDecision` explicable:

```text
resource: social_media
decision: ALLOW
reason: parent_temporary_override
expires_at: ...
overrode: study_mode
```

Esto permite explicar el comportamiento tanto a padres como a hijos y evita depender de la precedencia implícita de Cloudflare u otro proveedor. `Essential Services Availability` nunca puede anular el baseline de amenazas; su función es evitar que modos como Estudio o Pausar ocio bloqueen servicios familiares, escolares, de ubicación o de seguridad que el responsable haya declarado esenciales.

### 10.5 Essential Services Policy

SETOK Family mantendrá una política simple de servicios esenciales que puede sobrevivir a modos cotidianos como Estudio, Restringido o Pausar ocio.

Ejemplos configurables:

- comunicación familiar seleccionada;
- servicios de ubicación/recuperación del dispositivo;
- servicios necesarios para Family Link / Apple Family / SETOK;
- aplicaciones o dominios escolares;
- autenticación y servicios básicos del dispositivo.

La inclusión de un servicio como esencial **no** lo exime del Security / Threat Baseline. Malware, phishing, C2 y otras amenazas continúan bloqueándose.

La acción de consumidor preferida será `Pausar ocio`; una acción de impacto mayor como `Bloquear Internet` se mantendrá como opción avanzada y requerirá confirmación explícita.

### 10.6 Profile vs Mode vs Policy

**Profile**  
Configuración técnica del agente/proveedor.

**Mode**  
Nombre humano de un comportamiento.

**Policy Intent**  
Representación funcional de qué se permite y qué se bloquea.

Estos conceptos deben permanecer separados.

---

## 11. Command / Execution Engine

Toda acción parental que implique cambios en proveedores externos se modelará como un comando persistente y verificable.

### 11.1 Ciclo de vida

```text
REQUESTED
   ↓
ACCEPTED
   ↓
APPLYING
   ↓
APPLIED | PARTIAL | FAILED
```

La aplicación no debe mostrar “aplicado” únicamente porque una API respondió HTTP 2xx. Debe confirmar el estado observado cuando el proveedor lo permita.

### 11.2 Idempotencia y reintentos

Cada comando tendrá al menos:

- `command_id`;
- `idempotency_key`;
- `requested_by`;
- `requested_at`;
- `desired_state`;
- `status`;
- `retry_count`;
- `provider_operations`;
- `confirmed_at`;
- `failure_reason`.

La primera implementación puede utilizar una cola persistente sobre SQLite; no se requiere un broker distribuido en la etapa piloto.

### 11.3 Ejecución child-first y éxito parcial

Una acción sobre un Child se descompone en ejecuciones por dispositivo compatible.

```text
Yandari → Study 1h
   ├── iPad  → APPLIED
   └── Móvil → PENDING / OFFLINE
```

La UX debe representar correctamente `PARTIAL` y continuar reconciliando los dispositivos pendientes.

### 11.4 Desired, Observed y Effective State

SETOK distingue:

```text
DesiredState
ObservedState
EffectiveState
```

Ejemplo:

```text
Desired: Study
Observed: Normal
Effective: Applying Study
```

Esto evita presentar como final un cambio todavía en propagación.

### 11.5 Policy Revision y Last Known Good

Toda compilación significativa de políticas tendrá una revisión lógica. SETOK conservará al menos:

```text
current_desired_revision
last_known_good_revision
provider_observed_revision / fingerprint cuando sea posible
```

Una nueva revisión permanece `APPLYING` hasta ser validada. Si falla total o parcialmente, SETOK puede reconciliar, mantener la revisión anterior o ejecutar rollback según severidad y alcance.

Ejemplo:

```text
revision 42 = LAST_KNOWN_GOOD
revision 43 = APPLYING

si 43 falla:
  effective = 42 o PARTIAL según dispositivos confirmados
  remediation = reconcile / rollback
```

El objetivo es evitar configuraciones huérfanas o estados parcialmente rotos después de cambios de política.

---

## 12. Cloudflare Enforcement Provider

Cloudflare Zero Trust es el proveedor inicial de seguridad y enforcement de red.

### 12.1 Componentes piloto

- Cloudflare Zero Trust Free;
- Cloudflare Gateway;
- Cloudflare One Client;
- WARP / Traffic + DNS;
- Cloudflare Access para piloto/admin;
- Cloudflare Tunnel;
- Gateway policies;
- schedules;
- temporary rules / expirations.

### 12.2 Device Profile técnico

Se utilizará **un solo Device Profile técnico** para hardening del agente.

Nombre sugerido:

```text
SETOK-FAMILY-MANAGED
```

Debe mantener parámetros homogéneos como:

- WARP / Traffic + DNS;
- switch locked;
- auto-connect;
- no abandonar organización;
- configuración de túnel consistente.

### 12.3 Modos parentales persistentes

Los estados persistentes visibles para padres serán:

```text
STANDARD
RESTRICTED
```

Modelo:

```text
BASELINE siempre activo
        │
        ├── STANDARD
        └── RESTRICTED
```

### 12.4 Baseline

Debe incluir como mínimo:

- malware BLOCK;
- phishing BLOCK;
- C2/botnet BLOCK;
- contenido adulto BLOCK;
- apuestas BLOCK;
- SafeSearch FORCE;
- YouTube Restricted;
- medidas anti-bypass DNS/VPN según pruebas.

### 12.5 Overlays temporales

Los overlays no son perfiles persistentes.

Ejemplos:

- Study 1h;
- Study 2h;
- Allow Social 30m;
- Allow Social 60m;
- Pause Entertainment;
- Restore / Clear temporary overrides.

Los horarios recurrentes se definen en el proveedor, no mediante tareas PowerShell.

### 12.6 Cloudflare como adapter

El dominio SETOK no debe depender de IDs o expresiones propias de Cloudflare.

Todo detalle técnico debe quedar encapsulado en un adaptador equivalente a:

```text
CloudflareEnforcementProvider
```

### 12.7 Escalabilidad

Antes de ofrecer SETOK Family como SaaS comercial debe reevaluarse:

- límites de reglas;
- límites de listas;
- límites de identidades/dispositivos;
- modelo de aislamiento entre familias;
- costos de planes superiores;
- conveniencia de múltiples cuentas/organizaciones o providers alternativos.

---

## 13. Arquitectura por plataforma

### 13.1 Android — Redmi Note 14 Pro

Arquitectura aprobada:

```text
Android / Redmi
  ├── Google Family Link
  └── Cloudflare One Client
         └── Cloudflare Enforcement Provider
```

**No utilizar ManageEngine MDM en Android.**

Family Link es autoridad primaria para:

- tiempo total;
- límites por aplicación;
- bedtime;
- School Time;
- permisos;
- Google Play.

Cloudflare controla:

- navegación;
- amenazas;
- categorías;
- SafeSearch;
- horarios de Internet;
- overlays parentales;
- anti-bypass de red.

### 13.2 iPad — Protection Levels

La arquitectura se modela por niveles de protección.

#### Standard Protection

```text
iPad
  ├── Apple Screen Time / Family
  └── Cloudflare One Client
```

Objetivo: onboarding simple y adecuado para la mayoría de familias.

#### Enhanced Protection

```text
iPad
  ├── Apple Screen Time / Family
  ├── MDM Provider
  │     └── Supervised target
  └── Cloudflare One Client
```

Objetivo: mayor resistencia frente a eliminación, cambio de configuración o bypass.

`Supervised Mode` se mantiene como target recomendado para protección reforzada, pero **no será requisito universal para comenzar a utilizar SETOK Family**.

---

## 14. Device Capabilities, Connectivity y Time Context

### 14.1 Device Capabilities

SETOK no asumirá paridad funcional entre plataformas o niveles de protección. Cada dispositivo mantiene un conjunto de capacidades normalizadas, por ejemplo:

```text
web_filter
app_time_limit
remote_network_block
tamper_protection
child_request
app_install_control
location
```

La UI sólo ofrecerá acciones compatibles y el Policy Compiler utilizará estas capacidades al compilar una intención child-first.

### 14.2 Connectivity State

El estado de conectividad se modela independientemente del estado de protección:

```text
NORMAL
CAPTIVE_PORTAL
NETWORK_INCOMPATIBLE
TEMPORARY_BYPASS
NO_CONNECTIVITY
UNKNOWN
```

SETOK debe traducir estos estados a mensajes accionables y evitar exponer errores propios de WARP, VPN o proveedor.

Para el piloto móvil, **MASQUE será el transporte objetivo inicial**, salvo que las pruebas funcionales demuestren una incompatibilidad concreta. La selección deberá poder cambiarse como detalle del provider sin afectar el dominio SETOK.

### 14.3 Time Context

Los horarios deben declarar su semántica temporal:

```text
timezone_mode = FAMILY | DEVICE_LOCAL | FIXED
timezone = nullable
```

La experiencia debe permitir comportamientos como “se ajusta automáticamente al viajar” o “mantener horario de la familia”.

### 14.4 Age / Independence Profile

El dominio podrá asociar a cada Child una etapa o perfil de autonomía sin requerir necesariamente fecha de nacimiento completa:

```text
age_band = CHILD | PRETEEN | TEEN
independence_level
```

Este dato sirve para recomendar defaults y evolucionar gradualmente de `BLOCK` a `ASK`, `WARN` o `ALLOW`; nunca debe reemplazar la decisión del responsable.

### 14.5 Consumer Continuity Policy

La continuidad se resuelve utilizando los componentes existentes (`ConnectivityState`, `ProtectionState`, provider adapters y break glass), sin introducir un plano adicional.

Comportamiento esperado:

| Situación | Comportamiento objetivo |
|---|---|
| SETOK Family App fuera de servicio | las políticas ya aplicadas continúan |
| Authentik fuera de servicio | los dispositivos continúan con el enforcement existente |
| API del provider no disponible | no se asume cambio; mantener configuración conocida y reintentar |
| dispositivo offline | conservar desired state y aplicar/reconciliar al reconectar |
| captive portal | facilitar autenticación y reanudar protección automáticamente |
| red incompatible | mostrar remediación guiada y estado degradado/unknown |
| falla prolongada del enforcement | ofrecer recuperación parental controlada; nunca degradación silenciosa |
| intento del Child de desactivar protección | bloquear cuando la plataforma/nivel de protección lo permita y alertar según severidad |

SETOK prioriza `fail safe`, pero evita un `fail closed` indiscriminado que pueda dejar a un menor sin conectividad útil por una falla de la plataforma. Toda degradación relevante debe ser visible para el responsable.

---

## 15. Device Management Provider

### 15.1 Proveedor inicial

**ManageEngine Mobile Device Manager Plus Free** para el tenant piloto.

### 15.2 Uso

En v1.4 se utiliza únicamente para iPad Enhanced Protection.

### 15.3 Responsabilidades

- enrolamiento;
- supervisión;
- hardening;
- configuración;
- instalación/configuración de Cloudflare One Client;
- inventario;
- compliance;
- protección contra cambios.

### 15.4 Abstracción

ManageEngine debe quedar detrás de un adaptador equivalente a:

```text
DeviceManagementProvider
  └── ManageEngineAdapter
```

La lógica de negocio no debe depender directamente de conceptos específicos de ManageEngine.

---

## 16. Enrollment / Provisioning Orchestrator

Esta es una pieza arquitectónica obligatoria para una experiencia comparable con productos de alta adopción.

### 16.1 Responsabilidades

- crear Family;
- crear o asociar Guardian;
- crear Child;
- registrar Device;
- identificar plataforma;
- calcular capacidades disponibles;
- seleccionar nivel de protección;
- generar flujo de enrollment;
- mostrar QR/enlace cuando aplique;
- verificar que cada paso terminó correctamente;
- calcular `ProtectionState`;
- ofrecer corrección guiada cuando algo falla.

### 16.2 Experiencia objetivo

```text
1. “Protejamos el dispositivo de Yandari”
2. Elegir iPhone/iPad o Android
3. Escanear QR / seguir enlace
4. Completar únicamente pasos que el SO requiere
5. SETOK valida automáticamente
6. “Yandari está protegida”
```

### 16.3 Progressive protection

El onboarding debe poder completar primero una protección básica y ofrecer después:

> “Activar protección reforzada”

sin impedir el uso del producto desde el primer momento.

---

## 17. Child Experience

SETOK Family no debe ser únicamente una herramienta para padres.

### 17.1 Principios

Cuando sea posible, un bloqueo debe explicar:

- qué está bloqueado;
- por qué;
- hasta cuándo;
- qué opciones tiene el menor.

Ejemplo:

> Redes sociales están pausadas durante Modo Estudio hasta las 5:00 PM.
>
> **Pedir 15 minutos**

### 17.2 Solicitudes

Flujo futuro:

```text
Child request
   ↓
SETOK Family
   ↓
Parent notification / dashboard
   ↓
Allow 15m | Allow 30m | Deny
   ↓
Temporary Policy Intent
```

### 17.3 Cuenta opcional

El menor no necesita cuenta SETOK para existir como Child.

Una identidad podrá asociarse posteriormente para habilitar solicitudes, notificaciones y experiencia propia.

### 17.4 Ruta estratégica nativa

A largo plazo se contempla una aplicación nativa SETOK para iOS/Android cuando aporte ventajas reales de integración, notificaciones y experiencia infantil.

Para iOS se contempla como línea estratégica la evaluación de APIs nativas de Family Controls / Managed Settings / Device Activity, sujeto a entitlement y requisitos de distribución de Apple.

---

## 18. Notification Plane

Las solicitudes de menores, fallas de protección y acciones que requieren atención no pueden depender de que un padre abra manualmente el dashboard.

### 18.1 Provider abstraction

```text
NotificationProvider
  ├── WebPushAdapter
  ├── EmailAdapter
  └── FutureNativePushAdapter
```

### 18.2 Casos mínimos de Fase 2

- solicitud de tiempo/acceso por un Child;
- cambio relevante de `ProtectionState`;
- comando `FAILED` o `PARTIAL` que requiera atención;
- dispositivo fuera de protección durante un umbral significativo;
- confirmación de acciones sensibles cuando corresponda.

### 18.3 Principios de UX

- actionable;
- no duplicar ruido entre canales;
- respetar preferencias y quiet hours;
- deep-link a la acción concreta;
- no incluir datos sensibles innecesarios en el mensaje.

---


---

## 19. Parent Experience

La aplicación debe representar conceptos humanos, no infraestructura técnica.

### 19.1 Home child-first

La unidad primaria de interacción es el `Child`, no el `Device`.

```text
Family: Ulate León

Yandari
  🟢 Protegida
  Modo: Normal
  [Estudio 1h] [Restringir] [Pausar ocio]

  2 dispositivos
    ✓ iPad
    ✓ Móvil
```

Las acciones se aplican por defecto a todos los dispositivos compatibles del Child. El control por dispositivo se presenta como opción secundaria.

### 19.2 Regla de experiencia

Las acciones frecuentes deben resolverse en ≤2 taps.

### 19.3 No exponer

- rule IDs;
- Gateway UUIDs;
- WARP internals;
- tokens;
- MDM IDs;
- precedencias;
- nombres técnicos de provider.

### 19.4 Mensajes accionables

No:

> Device posture failed.

Sí:

> El móvil de Yandari necesita atención. La protección de Internet lleva 2 horas desconectada. **Corregir**.

---

## 20. Plano de automatización

PowerShell se utiliza para **engineering automation**, no como runtime de SETOK Family.

### 20.1 Responsabilidades

- bootstrap de Cloudflare;
- creación/actualización de Gateway policies;
- Device Profiles;
- Access/Tunnel cuando aplique;
- ManageEngine provisioning;
- Authentik bootstrap cuando la API lo permita;
- validaciones;
- reconciliación;
- auditoría técnica;
- testing de infraestructura.

### 20.2 Cmdlets objetivo

```text
Initialize-SETOKFamilyCloudflare
Deploy-SETOKFamilyGatewayPolicies
Initialize-SETOKFamilyMDM
Initialize-SETOKFamilyIdentity
Get-SETOKFamilyInfraState
Test-SETOKFamilyCompliance
Invoke-SETOKFamilyReconcile
```

### 20.3 Secretos

Nunca hardcoded.

Se utilizarán:

- Cloudflare API Tokens con menor privilegio;
- ManageEngine OAuth;
- Authentik API credentials cuando apliquen;
- almacén seguro local compatible con PowerShell;
- separación entre token de provisioning y token de runtime.

---

## 21. SETOK Family App — Runtime de Fase 2

### 21.1 Stack

- **SvelteKit 3**;
- **TypeScript**;
- **Tailwind CSS**;
- **Drizzle ORM**;
- **SQLite**;
- Linux Debian 13 en piloto;
- Cloudflare Tunnel;
- Authentik.

### 21.2 Runtime contract

La arquitectura de producto no debe depender de Proxmox.

Contrato objetivo:

```text
Linux + Node.js + almacenamiento persistente + acceso HTTPS saliente
```

### 21.3 Pilot deployment

```text
Proxmox
  └── LXC Debian 13 no privilegiado
        ├── SETOK Family
        └── cloudflared
```

Docker dentro del LXC es opcional y no forma parte del contrato arquitectónico.

### 21.4 Publicación piloto

```text
Internet
   │
Cloudflare Edge
   │
Cloudflare Access (pilot)
   │
Cloudflare Tunnel
   │
Proxmox LXC Debian 13
   │
SETOK Family
```

No se abren puertos WAN hacia el host local.

### 21.5 Persistencia

Se utiliza un Repository Layer:

```text
Domain Services
      ↓
Repositories
      ↓
Drizzle
      ↓
SQLite
```

Esto facilita una futura migración a PostgreSQL sin modificar dominio o UI.

---

## 22. Modelo de datos inicial

```text
tenants
users
tenant_members
guardian_child_permissions
children
devices
device_capabilities
provider_integrations
provider_device_bindings
policy_templates
policy_intents
device_modes
temporary_overrides
protection_state
connectivity_state
commands
command_executions
enrollment_sessions
child_requests
notifications
audit_events
family_events
provider_state_cache
```

### 22.1 tenants

- id;
- name;
- slug;
- status;
- plan;
- locale;
- timezone;
- created_at.

### 22.2 users

- id;
- identity_email;
- display_name;
- identity_provider;
- external_identity_id;
- status.

### 22.3 tenant_members

- tenant_id;
- user_id;
- role;
- status.

### 22.4 guardian_child_permissions

- tenant_id;
- guardian_user_id;
- child_id;
- permissions;
- status.

### 22.5 children

- id;
- tenant_id;
- name;
- login_user_id nullable;
- age_band nullable;
- independence_level nullable;
- status.

### 22.6 devices

- id;
- tenant_id;
- child_id;
- name;
- platform;
- protection_level;
- status.

### 22.7 Device lifecycle

Los dispositivos tendrán un ciclo de vida explícito:

```text
ACTIVE
LOST
REPLACED
RETIRED
REMOVED
```

Casos como `Replace device` deben permitir heredar automáticamente las políticas child-first del menor, crear nuevos provider bindings y revocar/inactivar los bindings del dispositivo anterior cuando corresponda. `LOST` conserva trazabilidad y evita eliminar prematuramente información útil para recuperación.

### 22.8 device_capabilities

- device_id;
- capability;
- supported;
- source;
- last_evaluated_at.

### 22.9 provider_integrations

- id;
- tenant_id;
- provider;
- capability_type;
- mode;
- external_account_id;
- secret_reference;
- status.

### 22.10 provider_device_bindings

- id;
- tenant_id;
- device_id;
- provider;
- external_device_id;
- external_identity;
- metadata;
- status.

### 22.11 policy_intents

- id;
- tenant_id;
- device_id nullable;
- child_id nullable;
- intent_type;
- parameters;
- starts_at;
- expires_at nullable;
- status.

### 22.12 protection_state

- device_id;
- state;
- score;
- confidence;
- last_verified_at;
- freshness_seconds;
- last_evaluated_at;
- reasons;
- remediation_action.

### 22.13 connectivity_state

- device_id;
- state;
- last_changed_at;
- reason;
- remediation_action.

### 22.14 commands

- id;
- tenant_id;
- child_id nullable;
- device_id nullable;
- command_type;
- idempotency_key;
- requested_by;
- desired_state;
- status;
- requested_at;
- confirmed_at nullable;
- failure_reason nullable.

### 22.15 command_executions

- id;
- command_id;
- device_id;
- provider;
- status;
- retry_count;
- provider_operation_id nullable;
- last_attempt_at;
- confirmed_at nullable.

### 22.16 enrollment_sessions

- id;
- tenant_id;
- child_id;
- device_id nullable;
- platform;
- target_protection_level;
- current_step;
- status;
- expires_at.

### 22.17 child_requests

- id;
- tenant_id;
- child_id;
- device_id nullable;
- request_type;
- parameters;
- status;
- requested_at;
- resolved_by nullable;
- resolved_at nullable.

### 22.18 notifications

- id;
- tenant_id;
- user_id;
- event_type;
- channel;
- status;
- created_at;
- delivered_at nullable;
- read_at nullable.

### 22.19 audit_events

Debe incluir como mínimo:

- tenant;
- actor;
- action;
- child;
- device;
- previous_state;
- new_state;
- timestamp;
- provider result;
- correlation ID.

### 22.20 family_events

Los eventos técnicos se traducen a eventos comprensibles.

Ejemplo:

```text
Yandari intentó acceder a una red social durante Modo Estudio.
```

No se recomienda almacenar historiales completos de navegación salvo que exista una necesidad explícita y un fundamento de privacidad apropiado.

---

## 23. Source of Truth

### 23.1 Desired State de infraestructura

```text
Git + YAML
```

Ejemplos:

- infraestructura esperada;
- policy templates;
- nombres lógicos;
- configuración de providers;
- parámetros de bootstrap.

### 23.2 Domain State

SETOK Family es autoridad para:

- families;
- memberships;
- children;
- devices internos;
- policy intents;
- child requests;
- protection state derivado;
- historial operativo.

### 23.3 Provider State

Cloudflare / ManageEngine / otros providers son autoridad del estado técnico real de sus propios objetos.

### 23.4 SQLite

SQLite almacena:

- dominio operativo de Fase 2;
- auditoría;
- overrides;
- cache;
- referencias de integración;
- tenants/children/devices;
- enrollment sessions;
- protection states.

### 23.5 Drift detection

La aplicación debe detectar drift:

```text
SETOK intent = Restricted
Provider actual = Standard
→ OUT OF SYNC
```

Debe existir reconciliación automática o guiada según severidad.

---

## 24. Seguridad

### 24.1 Principios

- Zero Trust;
- default deny donde corresponda;
- MFA para padres;
- menor privilegio;
- secretos sólo en backend;
- no puertos WAN;
- separación tenant;
- auditoría completa;
- break glass;
- ningún secreto al navegador;
- tokens de runtime diferentes a provisioning;
- provider credentials desacopladas por tenant/integración.

### 24.2 Anti-bypass

Fase 1 debe probar:

- cambio Wi-Fi / datos móviles;
- navegador alternativo;
- DNS alternativo;
- DoH/DoT;
- VPN;
- apagar WARP;
- logout;
- desinstalación;
- reinicio;
- cambio de fecha/hora;
- hotspot externo;
- modo incógnito;
- apps con certificate pinning si se habilita inspección futura.

### 24.3 Break glass

Break glass es un mecanismo operacional, no un modo parental.

Debe contemplar:

- Cloudflare admin override code;
- recuperación MDM;
- PIN parental Apple;
- código parental Google;
- secretos fuera de la mini app;
- procedimiento documentado y auditable.

---

## 25. Observabilidad, auditoría y privacidad

### 25.1 Technical Events

Ejemplo:

```text
Gateway policy update failed
Provider = Cloudflare
Correlation-ID = ...
```

### 25.2 Family Events

Ejemplo:

```text
14:23 — Redes sociales bloqueadas durante Modo Estudio.
```

### 25.3 Principio de privacidad

SETOK Family priorizará eventos de bienestar y seguridad sobre vigilancia exhaustiva.

Por defecto debe preferirse:

```text
Social media blocked: 5
Gaming blocked: 2
Security threats blocked: 1
```

sobre almacenar o mostrar cada URL visitada.

### 25.4 Retención

La retención de logs de providers no debe considerarse auditoría de producto.

SETOK Family conservará los eventos de producto necesarios conforme a una política propia de retención.

Una futura comercialización debe contemplar expresamente privacidad de menores, consentimiento parental, retención y normativa aplicable.

---

## 26. Experiencia Apple-like — criterios de aceptación

### 26.1 Common task ≤ 2 taps

Ejemplo:

```text
Yandari → Estudio 1 hora
```

### 26.2 Zero jargon

No mostrar términos como:

```text
Gateway
WARP
MDM
SCIM
posture
```

salvo en vistas técnicas administrativas.

### 26.3 Progressive setup

Primero:

> Protección estándar.

Después:

> Activar protección reforzada.

### 26.4 Reversible actions

Toda acción temporal debe poder:

- deshacerse;
- expirar;
- mostrar cuándo termina.

### 26.5 Transparent child experience

El menor debe saber:

- qué está restringido;
- por qué;
- hasta cuándo;
- si puede solicitar una excepción.

### 26.6 One health concept

El padre debe comprender el estado usando un único concepto principal:

```text
Protected / Needs Attention / Setup Required
```

no múltiples estados técnicos.

### 26.7 Confirmación de acciones de alto impacto

Las acciones cotidianas mantienen la meta de ≤2 taps. Acciones excepcionales como `Bloquear Internet`, remover un dispositivo, transferir ownership o desactivar una integración deben mostrar una confirmación clara del alcance y consecuencias antes de ejecutarse.

### 26.8 Accessibility by default

La experiencia de consumidor debe contemplar desde el diseño:

- navegación por teclado donde aplique;
- VoiceOver / TalkBack;
- escalado de texto;
- contraste adecuado;
- estados que no dependan únicamente del color;
- targets táctiles adecuados;
- reduced motion;
- lenguaje simple y comprensible.

---

## 27. Fases del proyecto

# FASE 1 — Infraestructura, enforcement e identidad

Objetivo: tener una solución parental funcional sin depender de SETOK Family App.

Incluye:

### Cloudflare / Enforcement

- Zero Trust;
- WARP Traffic + DNS;
- Device Profile único;
- baseline;
- Standard;
- Restricted;
- overlays temporales;
- schedules;
- SafeSearch;
- YouTube Restricted;
- anti-bypass;
- Access para piloto/admin;
- Tunnel;
- API Tokens;
- PowerShell automation.

### Identity Foundation

- Authentik self-hosted;
- OIDC;
- padres;
- grupos técnicos donde sean necesarios;
- MFA/passkeys;
- tenant piloto como entidad SETOK, no tenant Authentik.

### Android

- Family Link;
- Cloudflare One;
- hardening;
- pruebas de bypass.

### iPad

- Screen Time;
- Standard Protection;
- ManageEngine + Supervised como Enhanced Protection;
- Cloudflare One;
- hardening;
- pruebas de bypass.

### Automatización

- PowerShell modules;
- desired-state YAML;
- validación;
- reconciliación.

### Criterio de salida

Fase 1 termina cuando la plataforma funciona correctamente **sin SETOK Family App** y se han validado:

- enforcement;
- bypass resistance;
- identidades;
- provider APIs;
- estados y overlays;
- diferencias Standard vs Enhanced Protection.

---

# FASE 2 — SETOK Family App

Objetivo: construir la experiencia de producto.

Incluye:

- `family.setok.cr`;
- SvelteKit 3;
- TypeScript;
- Tailwind;
- Drizzle;
- SQLite;
- multi-tenant;
- roles;
- Family → Members → Children → Devices;
- Enrollment / Provisioning Orchestrator;
- Protection State;
- Policy Intent Engine;
- Policy Decision / Precedence Engine;
- Command / Execution Engine;
- Device Capabilities;
- Connectivity State;
- Time Context;
- Notification Plane;
- Guardian ↔ Child authorization;
- Cloudflare Enforcement Adapter;
- ManageEngine Device Management Adapter;
- overlays y modos;
- child requests básicos;
- audit log;
- family events;
- drift detection;
- reconciliación;
- dashboard parental;
- experiencia de onboarding.

La aplicación será inicialmente single-tenant en producción, pero el código y esquema serán multi-tenant desde el inicio.

---

## 28. Ruta estratégica posterior a Fase 2

No forma parte del alcance inmediato, pero la arquitectura debe permitir:

- PWA avanzada;
- app nativa iOS/Android;
- notificaciones push nativas como evolución del Notification Plane;
- integración con APIs nativas de Screen Time/Family Controls cuando sea viable;
- self-service onboarding de nuevas familias;
- billing/suscripción;
- PostgreSQL;
- hosting altamente disponible;
- providers alternativos de enforcement/MDM;
- portal de soporte y operaciones.

---

## 29. Decisiones arquitectónicas cerradas — ADR Summary

### ADR-001 — Producto
**SETOK Family** es el nombre seleccionado.

### ADR-002 — Hostname
`family.setok.cr` es el hostname objetivo de consumidor.

### ADR-003 — Multi-tenancy
Multi-tenant desde diseño; tenant piloto: Ulate León.

### ADR-004 — Identity Provider
Authentik self-hosted es el IdP inicial.

### ADR-005 — Human identities
Usuarios pueden usar Gmail, Outlook, iCloud u otros proveedores.

### ADR-006 — Device identity
El modelo interno usa `device_id`; las identidades de proveedores quedan desacopladas mediante bindings.

### ADR-007 — Android
Family Link + Cloudflare; sin ManageEngine MDM.

### ADR-008 — iPad protection levels
Standard Protection no requiere MDM; Enhanced Protection utiliza MDM + Supervised target.

### ADR-009 — Cloudflare transport
WARP Traffic + DNS.

### ADR-010 — Cloudflare Device Profiles
Un único Device Profile técnico.

### ADR-011 — Parent modes
Dos modos persistentes: STANDARD y RESTRICTED.

### ADR-012 — Temporary behavior
Study, Social Allow, Pause Entertainment, etc. son overlays temporales.

### ADR-013 — Break glass
Break glass no es un perfil.

### ADR-014 — Infrastructure automation
PowerShell/API-first para infraestructura.

### ADR-015 — App runtime
PowerShell no forma parte del runtime de la app.

### ADR-016 — App stack
SvelteKit 3 + TypeScript + Tailwind + Drizzle + SQLite.

### ADR-017 — Runtime portability
El contrato de producto es Linux/Node/persistencia; Proxmox LXC Debian 13 es el despliegue piloto.

### ADR-018 — Exposure
Cloudflare Tunnel; sin puertos WAN en el piloto.

### ADR-019 — Consumer authentication
Authentik/OIDC es el target de autenticación de consumidor. Cloudflare Access se mantiene para piloto y superficies administrativas.

### ADR-020 — Authorization
SETOK Family controla tenant membership y roles.

### ADR-021 — Source of Truth
- Git/YAML = desired state de infraestructura;
- SETOK Family = estado de dominio e intención;
- providers = estado técnico real;
- SQLite = persistencia operativa inicial.

### ADR-022 — Enforcement abstraction
Cloudflare es el primer `EnforcementProvider`, no una dependencia estructural del dominio.

### ADR-023 — Device management abstraction
ManageEngine es el primer `DeviceManagementProvider`, no una dependencia estructural del dominio.

### ADR-024 — Policy Intent Engine
La UI expresa intención; el compiler/provider adapter genera la configuración técnica.

### ADR-025 — Enrollment Orchestrator
Onboarding y verificación de protección son capacidades de primer nivel del producto.

### ADR-026 — Protection State
La salud técnica se traduce a estados humanos: Protected, Attention Required, Degraded, Offline y Setup Required.

### ADR-027 — Child Experience
La experiencia infantil y las solicitudes de excepción forman parte de la arquitectura de producto.

### ADR-028 — Apple-like UX
La facilidad de adopción es requisito arquitectónico: progressive disclosure, ≤2 taps para tareas frecuentes, cero jerga y acciones reversibles.

### ADR-029 — Guardian ↔ Child Authorization
Los permisos pueden limitarse por relación responsable-menor y no únicamente por rol global de tenant.

### ADR-030 — Command Execution Model
Las operaciones hacia proveedores son asíncronas, persistentes, idempotentes y verificables; SETOK distingue estado deseado, observado y efectivo.

### ADR-031 — Policy Precedence
SETOK define precedencia funcional antes de compilar reglas hacia proveedores.

### ADR-032 — Protection Freshness
`ProtectionState` incluye nivel de confianza y frescura; no se muestra protección confirmada sin evidencia reciente.

### ADR-033 — Child-first Scope
Las acciones parentales se aplican por defecto al Child y se compilan hacia sus dispositivos compatibles.

### ADR-034 — Notification Plane
Notificaciones de solicitudes y eventos críticos forman parte de Fase 2 mediante una abstracción de proveedor.

### ADR-035 — Device Capabilities
La UI y el compiler se basan en capacidades reales de cada dispositivo/plataforma/nivel de protección.

### ADR-036 — Connectivity State
La conectividad y compatibilidad de red se modelan separadamente de la protección.

### ADR-037 — Time Context
Todo horario declara explícitamente si sigue la zona de la familia, la zona local del dispositivo o una zona fija.

### ADR-038 — Age / Independence Profile
SETOK puede recomendar comportamientos progresivos según etapa/autonomía, preservando minimización de datos y decisión parental.

### ADR-039 — Essential Services
Los modos parentales cotidianos no bloquean servicios esenciales definidos por la familia; el Security / Threat Baseline mantiene precedencia y nunca puede ser anulado por esta excepción.

### ADR-040 — Consumer Continuity
SETOK define comportamiento explícito ante fallas de aplicación, identidad, red o provider. Se prioriza continuidad segura y recuperación guiada, evitando tanto degradación silenciosa como bloqueo prolongado causado por una falla de la plataforma.

### ADR-041 — Policy Revision / Last Known Good
Toda compilación significativa de políticas se versiona. SETOK conserva una última revisión confirmada como válida y soporta reconciliación o rollback sin introducir un sistema distribuido adicional.

### ADR-042 — Device & Family Lifecycle
Dispositivos, membresías y ownership tienen ciclo de vida explícito, incluyendo reemplazo, pérdida, retiro, offboarding y recuperación administrativa.

---

## 30. Riesgos y consideraciones

1. **Cloudflare device identity:** no todos los selectores funcionan igual en todas las políticas Gateway. El piloto puede usar identidades técnicas por correo, pero el producto debe mantener provider bindings.
2. **Cloudflare scaling:** una sola cuenta/organización puede no ser apropiada para SaaS multi-familia a gran escala; reevaluar límites y aislamiento antes de comercialización.
3. **Family Link / Screen Time APIs:** no existe una API administrativa pública equivalente para automatizar todas las acciones parentales; parte de la configuración estructural seguirá siendo manual.
4. **iPad Enhanced Protection:** Supervised Mode ofrece mejor hardening pero aumenta fricción de onboarding; por eso es opcional/progresivo.
5. **Authentik availability:** el piloto puede alojarlo en Proxmox, pero una versión comercial necesita despliegue altamente disponible.
6. **ManageEngine Free:** adecuado para piloto; no debe asumirse como backend MDM de un SaaS comercial.
7. **SQLite:** adecuado para etapa inicial; migración natural a PostgreSQL si el producto escala.
8. **Provider drift:** SETOK debe detectar y reconciliar diferencias entre intención y estado real.
9. **Privacy:** cualquier evolución SaaS debe incorporar política de privacidad, retención, tratamiento de datos de menores y cumplimiento aplicable.
10. **Child bypass:** la seguridad debe equilibrar resistencia al bypass con una experiencia no hostil ni opaca.
11. **Provider lock-in:** ningún concepto de dominio debe depender de sintaxis o IDs específicos de Cloudflare/ManageEngine.
12. **Home-hosted SPOF:** Proxmox doméstico es válido para piloto, no target de disponibilidad comercial.
13. **False-positive protection:** la UI puede generar falsa confianza si no considera frescura/telemetría.
14. **Provider propagation latency:** cambios aceptados por API pueden tardar en aplicarse; deben mostrarse como `APPLYING` hasta confirmación o timeout.
15. **Conflicting guardians:** dos responsables pueden emitir acciones contradictorias; el Command/Policy Engine debe ordenar y auditar la resolución.
16. **Captive portals and incompatible networks:** WARP/VPN puede generar fricción en hoteles, colegios, aeropuertos y redes públicas; requiere `ConnectivityState` y remediación guiada.
17. **Travel/timezone ambiguity:** horarios mal interpretados durante viajes pueden generar bloqueos inesperados.
18. **Notification fatigue:** demasiadas alertas reducen confianza y adopción; deben existir severidades, quiet hours y deduplicación.
19. **Partial multi-device execution:** una acción child-first puede aplicarse sólo a parte de los dispositivos; la UI debe mostrarlo y reconciliar automáticamente.
20. **Essential-service lockout:** una política parental demasiado amplia puede bloquear comunicación, ubicación o educación necesaria; se mitiga con Essential Services Policy y confirmación para bloqueos de alto impacto.
21. **Provider outage / fail-closed:** una caída externa no debe producir pérdida prolongada de conectividad sin recuperación visible; se mitiga mediante Consumer Continuity Policy, Protection/Connectivity State y break glass.
22. **Broken policy revision:** una nueva compilación puede dejar estado parcial; se mitiga con Policy Revision, Last Known Good, reconciliación y rollback.
23. **Lost/replaced devices:** bindings antiguos pueden quedar activos o generar confusión; el lifecycle explícito debe revocar/inactivar asociaciones y preservar auditoría.
24. **Owner lockout:** una familia puede quedar sin administración si pierde acceso el único Owner; onboarding y recovery deben favorecer segundo Owner o recuperación fuerte.

---

## 31. Próximo paso

El siguiente entregable debe ser un **roadmap de Fase 1** organizado por unidades implementables, dependencias, criterios de aceptación y pruebas.

Orden recomendado:

1. foundation de Cloudflare;
2. foundation de Authentik;
3. identidades del tenant piloto;
4. modelado inicial de provider bindings;
5. políticas baseline;
6. Standard / Restricted / overlays;
7. enrolamiento Android;
8. enrolamiento iPad Standard;
9. enrolamiento iPad Enhanced/MDM;
10. automatización PowerShell;
11. pruebas anti-bypass;
12. definición de señales, freshness y confidence para Protection State;
13. matriz de Device Capabilities por plataforma;
14. validación de captive portals / MASQUE / redes incompatibles;
15. reglas de Time Context y viajes;
16. definición formal de Policy Precedence;
17. contrato de Command/Execution e idempotencia;
18. validación de Essential Services y acciones de alto impacto;
19. pruebas de Consumer Continuity y break glass móvil;
20. definición de Policy Revision / Last Known Good;
21. ciclo de vida de dispositivo y recuperación de Owner;
22. cierre de Fase 1;
23. contrato de APIs y providers para Fase 2.

---

## 32. Estado final y baseline del proyecto

**Arquitectura SETOK Family v1.4: BASELINE APPROVED / ARCHITECTURE FROZEN**

Esta versión constituye la **base arquitectónica oficial para continuar el proyecto**. El siguiente trabajo debe avanzar hacia roadmap, implementación y validación de Fase 1.

### Regla de cambio arquitectónico

A partir de v1.4 no se realizarán nuevas rondas teóricas de arquitectura. Un cambio arquitectónico deberá estar respaldado por al menos una de estas condiciones:

1. evidencia obtenida durante implementación o pruebas reales;
2. limitación confirmada de un proveedor o plataforma;
3. requisito funcional nuevo con impacto material;
4. hallazgo de seguridad, privacidad, cumplimiento o escalabilidad no cubierto por el baseline;
5. decisión explícita de productización/comercialización que cambie supuestos actuales.

Las mejoras menores de UI, copy, configuración, observabilidad o implementación que respeten los ADR existentes **no requieren modificar la arquitectura de referencia**.

El objetivo desde este punto es validar la arquitectura mediante software y dispositivos reales, evitando sobrearquitectura especulativa.
