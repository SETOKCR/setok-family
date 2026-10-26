# SETOK Family

**SETOK Family** is a privacy-first, multi-tenant platform for family digital safety, parental control, and digital wellbeing.

Its goal is to provide parents and children with a simple, understandable, and reliable experience across multiple devices and operating systems, while keeping technical complexity hidden behind a consistent product experience.

The project is designed around a core principle:

> **Family intent first. Provider complexity second.**

Parents should think in terms of:

- Study time
- Restricted mode
- Allow 30 more minutes
- Pause entertainment
- Device protection
- Child requests

—not in terms of DNS rules, VPN profiles, MDM identifiers, posture checks, provider APIs, or policy precedence.

## Project Status

**Architecture baseline:** v1.4 — Approved / Frozen

The architecture is considered complete enough to begin implementation.

Future architectural changes should only be introduced when justified by:

- implementation evidence;
- confirmed provider limitations;
- material product requirements;
- security findings;
- real-world testing.

The current focus is **Phase 1: infrastructure, enforcement, identity, and validation**.

## Product Vision

SETOK Family aims to deliver a user experience comparable in simplicity to consumer products from companies such as Apple:

- minimal setup friction;
- progressive onboarding;
- human-readable states;
- common actions in one or two taps;
- no technical jargon in the consumer UI;
- transparent behavior for children;
- reversible actions;
- strong protection without making the product feel hostile.

The platform is designed to support both a private family deployment and a possible future SaaS offering.

## Core Architecture

SETOK Family is multi-tenant by design, although the first deployment uses a single pilot family.

```text
SETOK Family
    │
    ├── Families
    │    ├── Guardians
    │    ├── Children
    │    │    └── Devices
    │    ├── Policies
    │    ├── Overrides
    │    └── Audit Events
    │
    ├── Identity
    ├── Policy Engine
    ├── Command Execution
    ├── Enforcement Providers
    ├── Device Management Providers
    └── Notification Providers
```

The default interaction model is **child-first** rather than device-first.

For example:

```text
Yandari
  → Study for 1 hour
```

SETOK then determines which devices belong to that child, which capabilities each device supports, and how the requested intent must be translated to each provider.

## Architecture Principles

The project follows several key principles:

- Multi-tenant from the domain model.
- Human identity is separate from device identity.
- Families are SETOK domain entities, not identity-provider tenants.
- Child-first policy scope.
- Provider abstraction.
- Policy intent before provider syntax.
- Asynchronous and verifiable provider operations.
- Idempotent commands.
- Explicit policy precedence.
- Protection state based on fresh evidence.
- Privacy by default.
- Progressive disclosure.
- Fail-safe enforcement.
- Consumer continuity during provider or connectivity failures.
- Essential services remain available unless explicitly overridden.
- No dependency on a specific MDM or enforcement provider at the domain level.

## Initial Technology Stack

### Identity

**Authentik**

Used as the initial Identity Provider for:

- authentication;
- OIDC;
- MFA;
- passkeys/WebAuthn;
- federation with external identity providers.

Users may authenticate with existing identities such as Gmail, Outlook, iCloud, or corporate accounts.

SETOK Family remains responsible for authorization and family relationships.

### Network Enforcement

**Cloudflare Zero Trust**

Initial enforcement provider for:

- DNS and traffic protection;
- content categories;
- SafeSearch;
- YouTube Restricted Mode;
- schedules;
- temporary restrictions;
- security filtering;
- anti-bypass controls.

Cloudflare is implemented behind an enforcement-provider abstraction and is not a permanent dependency of the SETOK domain model.

### Android

Initial architecture:

```text
Google Family Link
+
Cloudflare One Client
```

Family Link remains the primary authority for:

- app limits;
- screen time;
- bedtime;
- School Time;
- Google Play controls.

### Apple / iPad

Two protection levels are supported conceptually.

**Standard Protection**

```text
Apple Screen Time / Family
+
Cloudflare One Client
```

**Enhanced Protection**

```text
Apple Screen Time / Family
+
MDM / Supervised Mode
+
Cloudflare One Client
```

The initial MDM provider for the pilot is ManageEngine Mobile Device Manager Plus.

MDM is not required for basic adoption.

## Policy Model

Parents interact with human concepts:

```text
Normal
Restricted
Study
Pause Entertainment
Allow Social 30 min
```

Internally:

```text
UI Action
    ↓
Policy Intent
    ↓
Policy Decision
    ↓
Policy Compiler
    ↓
Provider Adapter
    ↓
Cloudflare / MDM / future provider
```

SETOK defines policy precedence before rules are translated into a provider-specific format.

## Command Execution

Provider operations are asynchronous.

A successful API response does not automatically mean the requested behavior is active.

Commands follow a lifecycle such as:

```text
REQUESTED
    ↓
ACCEPTED
    ↓
APPLYING
    ↓
APPLIED | PARTIAL | FAILED
```

SETOK tracks:

- desired state;
- observed state;
- effective state;
- retries;
- provider execution;
- confirmation;
- failure reasons.

Commands are designed to be idempotent.

## Protection State

Technical signals are translated into a simple consumer-facing state.

Examples:

```text
Protected
Needs Attention
Offline
Setup Required
Unknown
```

Protection state includes freshness and confidence so SETOK does not report a device as protected indefinitely without recent evidence.

## Essential Services

Parental restrictions should not unintentionally remove critical family functionality.

SETOK supports the concept of essential services that can remain available during restrictions, such as:

- family communication;
- location-related services;
- required education services;
- control infrastructure;
- selected family-approved services.

Security protections against malware, phishing, and threats always retain higher priority.

## Device Lifecycle

Devices are modeled with an explicit lifecycle:

```text
ACTIVE
LOST
REPLACED
RETIRED
REMOVED
```

Policies primarily belong to the child, allowing a replacement device to inherit the child's configuration without recreating rules manually.

## Privacy

SETOK Family follows a privacy-first approach.

The platform should prefer meaningful family and safety events over exhaustive browsing surveillance.

For example:

```text
Social media blocked: 5
Gaming blocked: 2
Security threats blocked: 1
```

is preferred over storing a complete URL-by-URL browsing history unless explicitly required.

The product principle is:

> **SETOK protects. It does not spy.**

## User Experience

The consumer experience should follow these rules:

- common actions in no more than two taps;
- child-first navigation;
- zero technical jargon;
- clear explanations;
- visible expiration of temporary changes;
- reversible actions;
- actionable error messages;
- accessibility by default;
- explicit confirmation for high-impact actions.

Example:

```text
Yandari
🟢 Protected

Mode: Normal

[Study 1h]
[Restrict]
[Pause entertainment]

2 devices
✓ iPad
✓ Mobile
```

## Deployment Strategy

The pilot environment is self-hosted.

Initial runtime target:

```text
Proxmox
  └── Debian 13 LXC
        ├── SETOK Family
        └── cloudflared
```

The product architecture itself is not dependent on Proxmox.

Runtime contract:

```text
Linux
Node.js
Persistent storage
Outbound HTTPS connectivity
```

## Application Stack

Planned Phase 2 application stack:

- SvelteKit
- TypeScript
- Tailwind CSS
- Drizzle ORM
- SQLite initially
- Authentik
- Cloudflare Tunnel

SQLite is intentionally used for the early stages.

The persistence layer is abstracted to allow future migration to PostgreSQL if required.

## Automation

Infrastructure configuration follows an API-first approach.

PowerShell is used for:

- Cloudflare provisioning;
- policy deployment;
- identity bootstrap;
- MDM provisioning;
- validation;
- reconciliation;
- compliance testing;
- infrastructure troubleshooting.

PowerShell is **not** part of the SETOK Family application runtime.

## Project Phases

### Phase 1 — Infrastructure and Enforcement

Build and validate the underlying parental-control platform without depending on the SETOK Family application.

Includes:

- Cloudflare Zero Trust;
- Authentik;
- provider identities;
- baseline security policies;
- Standard and Restricted modes;
- temporary overlays;
- Android enrollment;
- iPad Standard Protection;
- iPad Enhanced Protection;
- API automation;
- anti-bypass tests;
- connectivity tests;
- policy precedence;
- provider behavior validation.

### Phase 2 — SETOK Family Application

Build the consumer product experience on top of the validated infrastructure.

Includes:

- `family.setok.cr`;
- multi-tenant application;
- child-first dashboard;
- onboarding;
- policy intents;
- command execution;
- protection state;
- guardian/child authorization;
- notification system;
- provider adapters;
- child requests;
- audit and family events;
- remediation workflows.

## Repository Structure

The repository structure will evolve during implementation.

A likely direction is:

```text
/
├── docs/
│   └── architecture/
│
├── infra/
│   ├── cloudflare/
│   ├── authentik/
│   └── mdm/
│
├── powershell/
│
├── app/
│
├── config/
│
└── README.md
```

The approved architecture document is the authoritative design baseline for implementation decisions.

## Current Milestone

The next milestone is to produce and execute the **Phase 1 implementation roadmap**, including:

- implementation units;
- dependencies;
- acceptance criteria;
- validation steps;
- rollback criteria;
- real-device testing.

## Project Philosophy

SETOK Family should remain technically strong without exposing that complexity to families.

The engineering goal is not merely to block content.

The goal is to make digital family management feel:

**simple, predictable, respectful, and trustworthy.**
