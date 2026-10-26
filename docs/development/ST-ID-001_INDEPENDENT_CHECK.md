# ST-ID-001 — Independent Check

**Work Unit:** `ST-ID-001 — Establish Authentik pilot identity foundation`  
**Risk:** RED — Auto-RED `authentication`  
**Result:** PASS WITH CONDITIONS  
**Date:** 2026-10-25 / 2026-10-26 UTC boundary

## Purpose

Independent readiness review of the Authentik pilot foundation before any implementation authorization. The review is intentionally adversarial: confirm that the proposed deployment does not weaken the authentication boundary, mix workloads, persist secrets in Git, or create an unrecoverable identity service.

## Reviewed baseline

- `docs/ARCHITECTURE.md` v1.4 frozen baseline.
- `docs/stories/ST-ID-001.md`.
- `.ai/work-orders/ST-ID-001.md`.
- Product Owner infrastructure evidence: Proxmox `pve-02`; existing VM `210 (setok-live-01)` remains out of scope.
- Current Authentik vendor documentation for Docker Compose installation, automated bootstrap, configuration, and backup/restore.

## Findings

### 1. Deployment boundary — PASS

Use a **new dedicated VM** on `pve-02`; do not install Authentik in `210 (setok-live-01)` and do not use LXC/PCT for this Story.

This preserves a clean failure, backup and rollback boundary for the Identity Plane.

### 2. Supported deployment path — PASS

Use stable Linux + Docker Engine + Docker Compose v2 inside the dedicated VM. This follows Authentik's documented Docker Compose path for test and small-scale production.

### 3. Initial sizing — PASS WITH OBSERVATION

Initial allocation: **2 vCPU / 2 GiB RAM / 32–40 GiB disk**.

2 CPU cores and 2 GiB RAM are the documented minimum for the Docker Compose deployment. Because the pilot starts exactly at the minimum, implementation evidence must record initial memory/CPU consumption after the stack stabilizes. Resource expansion is allowed only when observed utilization warrants it; no architecture change is required for a vertical resize.

### 4. Docker socket exposure — PASS WITH REQUIRED HARDENING

The upstream Docker Compose file mounts `/var/run/docker.sock` into the Authentik worker by default for automatic Outpost management. ST-ID-001 does not require Outposts.

**Required:** remove the Docker socket mount from the worker for this Story. Do not introduce a socket proxy unless a later Story actually requires managed Outposts. This applies least privilege and avoids host-control capability that is unnecessary for the foundation.

### 5. Bootstrap administration — PASS WITH REQUIRED HARDENING

Prefer `AUTHENTIK_BOOTSTRAP_PASSWORD_HASH` over `AUTHENTIK_BOOTSTRAP_PASSWORD`. The raw administrative password must not be committed, printed into evidence, or persisted in shell history.

Bootstrap hash, Authentik secret key, PostgreSQL password and any API token remain outside Git. The bootstrap variables are first-start controls; evidence should prove successful administration without disclosing their values.

### 6. Secret handling — PASS

`.env` or equivalent runtime secret material may exist on the VM with restrictive filesystem permissions but must be excluded from Git and from persisted evidence. Non-secret desired state may record variable names, paths and configuration shape, never values.

### 7. Persistence and recovery — PASS WITH REQUIRED BACKUP

PostgreSQL is the critical durable state. Implementation must demonstrate a PostgreSQL-native backup (`pg_dump`, `pg_dumpall`, or equivalent appropriate native method) and copy/store the resulting backup **outside the Authentik VM**.

Proxmox VM backup/snapshot is useful infrastructure protection but does not replace the logical PostgreSQL recovery path.

If `/data`, `/certs`, `/custom-templates` or `/blueprints` become material, their backup requirement must be evaluated. For this minimal foundation, evidence must state which persistent directories are actually used.

### 8. Network exposure — PASS

No direct WAN exposure is required or authorized. Bootstrap and foundation validation may use the internal VM address/hostname. Stable external publication, reverse proxy, Cloudflare Tunnel/Access and consumer-facing DNS belong to later units.

### 9. Identity/domain separation — PASS

Authentik authenticates humans. It must not model Family, Guardian ↔ Child authorization, device ownership or SETOK Family tenancy. No real pilot users, OIDC app, social federation or Cloudflare Access integration are required in ST-ID-001.

### 10. Recovery from administrative lockout — PASS WITH CONDITION

Foundation evidence must document the supported local administrative recovery/remediation route available from the VM/Compose deployment so that a configuration mistake does not permanently strand the pilot IdP. This documentation must not contain secret values.

## Required implementation conditions

1. New dedicated VM on `pve-02`; VM 210 untouched.
2. 2 vCPU / 2 GiB / 32–40 GiB initial allocation; record observed utilization.
3. Stable Linux + Docker Engine + Compose v2.
4. Remove the default Docker socket mount because Outposts are out of scope.
5. Bootstrap with hashed `akadmin` password where supported; raw secret never persisted in Git/evidence.
6. Authentik secret key and PostgreSQL password outside Git with restrictive local permissions.
7. PostgreSQL logical backup demonstrated and stored outside the VM.
8. No direct WAN publication.
9. No real family users, OIDC, federation, Access integration or family authorization objects.
10. Document non-secret admin recovery/remediation route.

## Independent Check verdict

**PASS WITH CONDITIONS.**

The RED classification remains because authentication is an Auto-RED surface. No design defect blocks implementation readiness once the conditions above are incorporated into the Work Order. Implementation authorization still requires a frozen Authorized Base and implementation branch after governance documents are finalized.
