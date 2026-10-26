# SETOK Family — QUALITY

## Scope

This is the minimum project-local quality canon for the current **Phase 1 — Infrastructure, Enforcement and Identity**.

It does not add new product or architecture requirements. Detailed technical behavior and risks remain governed by `docs/ARCHITECTURE.md` and the SETOK-AIDE quality/risk contracts.

## Phase 1 quality objective

Evidence must demonstrate that the parental-control platform behaves correctly on real providers and devices **without depending on SETOK Family App**.

## Required validation surfaces

When a Story touches the relevant surface, its Work Order and gates must cover the applicable validation below.

### Provider and policy behavior

- requested provider configuration is verified against observed provider/device state where possible;
- an API success response is not treated as proof that a behavior is active;
- repeated/retried automation does not intentionally create duplicate or inconsistent configuration;
- baseline, Standard, Restricted and temporary overlays behave according to the approved architecture;
- provider drift and failed/partial application are observable and recoverable.

### Security and bypass resistance

Applicable device tests include the architecture-defined bypass scenarios such as alternate network paths, alternate DNS, DoH/DoT, VPN, disabling/logout/removal attempts, restart, date/time changes, hotspot use and alternate browsers/incognito behavior.

Secrets must not be hardcoded or exposed to consumer/browser surfaces. Provider credentials use least privilege appropriate to the integration.

### Device/platform validation

- Android behavior is validated with Google Family Link + Cloudflare One Client;
- iPad Standard behavior is validated with Apple Screen Time / Family + Cloudflare One Client;
- iPad Enhanced behavior is separately validated when MDM/Supervised protection is in scope;
- platform capability differences are recorded rather than assumed away.

### Connectivity and continuity

Where applicable, validate captive portals, incompatible networks, offline devices, provider/API outages, reconciliation after reconnection, essential-services behavior and break-glass/recovery paths.

### Automation

PowerShell/API automation must be deterministic enough to support bootstrap, validation and reconciliation for its authorized scope. Desired configuration belongs in versioned project state; secrets do not.

## Evidence rule

Each implementation Work Order must identify the deterministic checks, provider/device evidence and rollback/remediation evidence proportional to its SETOK-AIDE risk classification and touched surface.

Narrative review alone does not replace required technical validation.

## Phase 1 exit quality

The architecture defines Phase 1 exit validation around:

- enforcement;
- bypass resistance;
- identities;
- provider APIs;
- states and overlays;
- differences between Standard and Enhanced Protection.

Phase 1 cannot be declared complete without evidence for the applicable items above.

## Authority

This file is intentionally concise. It governs quality routing for the current phase and does not replace `docs/ARCHITECTURE.md` or the SETOK-AIDE stable quality, risk, architecture and secure-coding contracts.
