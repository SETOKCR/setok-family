# SETOK Family — Product Canon

## Status

Current product baseline derives from the approved SETOK Family Architecture v1.4.

Current focus: **Phase 1 — infrastructure, enforcement, identity and validation.**

The SETOK Family application / mini app remains **Phase 2** and is not part of the current implementation focus.

## Product purpose

SETOK Family is a family digital-safety, parental-control and digital-wellbeing platform designed to provide parents and children with a simple, understandable and reliable experience across multiple devices and operating systems while hiding provider-specific technical complexity.

The product is multi-tenant by design, with an initial single-family pilot deployment.

## Product principles

- Family intent first; provider complexity remains behind the product experience.
- Child-first interaction: common parental actions target the Child by default and are compiled to compatible devices.
- Human identity and device identity remain separate.
- Privacy by default: protect and explain rather than perform exhaustive browsing surveillance.
- Progressive disclosure: basic protection should be simple; advanced controls may be enabled progressively.
- Common parental tasks target no more than two taps.
- Consumer UX avoids infrastructure jargon.
- Everyday changes should be reversible or expire automatically where applicable.
- Children should understand what is restricted, why, until when, and whether an exception can be requested.
- Protection state must reflect fresh evidence rather than stale technical state.
- Essential services should survive ordinary parental modes while security/threat protection retains precedence.

## Pilot product scope

The pilot validates the parental-control platform before the consumer application becomes a dependency.

Phase 1 includes:

- Cloudflare Zero Trust enforcement foundation;
- Authentik identity foundation;
- pilot-family provider identities/bindings;
- baseline security and content policies;
- Standard and Restricted modes plus temporary overlays;
- Android protection using Google Family Link + Cloudflare One Client;
- iPad Standard Protection using Apple Screen Time / Family + Cloudflare One Client;
- optional iPad Enhanced Protection using MDM / Supervised target + Cloudflare One Client;
- PowerShell/API-first provisioning, validation and reconciliation;
- anti-bypass, connectivity, provider-behavior and continuity validation.

## Phase boundary

Phase 1 must deliver a functioning parental-control platform **without depending on SETOK Family App**.

Phase 2 builds the consumer product experience, including `family.setok.cr`, onboarding, policy intent, command execution, protection state, notifications, provider adapters, requests, audit/family events and remediation workflows.

## Authority

Detailed product and architecture decisions remain governed by `docs/ARCHITECTURE.md` (SETOK Family Architecture v1.4). This file is intentionally minimal and does not replace or extend that baseline.
