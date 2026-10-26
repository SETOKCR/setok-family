# ST-ID-001 — Evidence

This is the non-secret evidence for the Authentik pilot identity foundation. Every file was produced by `scripts/st-id-001/Invoke-StId001.ps1`. The desired state is in `infra/authentik/st-id-001.desired.json`, and the hardened compose file is `infra/authentik/compose.yml`.

## Target

- Proxmox host `pve-02` (192.168.89.20, PVE 9.2.3). `pve-lab` (192.168.89.16) is a different host and is out of scope.
- New VM **220 `setok-family-idp-01`**:
  - 2 vCPU, 2 GiB fixed RAM (no balloon), 40 GiB on local-lvm
  - Ubuntu 24.04.5 LTS cloud image with cloud-init
  - vmbr0 with the firewall flag set, static 192.168.89.22/24
- Before creating the VM, the plan checked the address: no ping or ARP reply, and the DHCP server offers from .54 upwards.
- VM 210 `setok-live-01` was **not modified, started or stopped by this Story**. Its config hash is `77388d3a…e9d2`, identical in the plan, createvm and verify evidence. The Product Owner had stopped it before execution.

## Timeline

| File | Step | Result |
|---|---|---|
| `*-plan.json` | Plan | Node pve-02, VMID 220 absent, IP unused, image present, VM 210 hash recorded |
| `20261025T215859-createvm.json` | CreateVm | VM 220 created and started |
| `20261025T220252-runtime.json` | Runtime | docker.io 29.1.3, Compose v2.40.3, qemu-guest-agent, ufw (LAN only) |
| `20261025T220518-deploy.json` | Deploy | `.env` generated on the VM, bootstrap hash written, stack up |
| `20261025T221425-verify.json` | Verify | All healthy and checks pass (details below) |
| `20261025T221445-backup.json` | Backup | pg_dump -Fc copied to valhalla and verified |
| `20261025T221455-createvm.json` and `20261025T221500-deploy.json` | Re-run | Idempotent: "VM exists; not recreating", ".env exists; secrets kept", "Bootstrap hash already present; unchanged" |
| `20261025T221511-usage.json` and `20261025T221511-host-usage.json` | Usage | CPU and RAM after the stack stabilized |

The timestamps in file names are local time (UTC-6).

The first verify run returned UI 500. The cause was `/templates`, which had been created root-only `0750`, so Authentik (uid 1000) could not read it. The data, certs and custom-templates directories are now owned by `1000:1000` with mode 0750, and the Deploy step does this too. The run above was taken after that fix.

## Verify results

- postgresql, server and worker are running and healthy, on image `ghcr.io/goauthentik/server:2026.8.5` and `postgres:16-alpine`.
- `/-/health/live/` returns 200, `/-/health/ready/` 200, the UI 200 (`/if/flow/default-authentication-flow/`) and `/api/v3/root/config/` 200. From valhalla, `http://192.168.89.22:9000/-/health/ready/` returns 200.
- **Docker socket:** `docker_sock_mounted 0`. The worker mounts only `/data`, `/certs` and `/templates`.
- **Secrets file:** `/opt/authentik/.env` is `600 root:root`. It contains only `PG_PASS`, `AUTHENTIK_SECRET_KEY` and `AUTHENTIK_BOOTSTRAP_PASSWORD_HASH`. No plaintext `AUTHENTIK_BOOTSTRAP_PASSWORD` is used.
- **Persistence:** the PostgreSQL named volume `authentik_database` and the bind mounts `./data`, `./certs` and `./custom-templates`, which are empty apart from Authentik defaults. PostgreSQL holds the material durable state.
- **Exposure:** the VM has a single RFC1918 address. No router port-forward, Tunnel, reverse proxy or public DNS was created.
  - ufw allows 22, 9000 and 9443 only from 192.168.89.0/24.
  - Docker-published ports (9000 and 9443) skip ufw's INPUT rules, so the effective boundary for those ports is the LAN/NAT perimeter. This meets "no direct WAN exposure"; any future publication must go through the architecture's Tunnel/Access path.
- **Scope scan:**
  - users: `akadmin`, `AnonymousUser`, and `ak-outpost-…` (the built-in embedded outpost service account)
  - applications 0, providers 0, OAuth2 providers 0
  - sources: `authentik-built-in` only
  - outposts: the built-in `authentik Embedded Outpost`, an Authentik default; none were created
  - tokens: 1, the embedded outpost's own token
  - No real users, OIDC, federation, Access integration or family roles exist.
- **Local admin check:** `akadmin` exists and is a superuser. `check_password` against the DPAPI-stored password returned True. The password reached the check only over SSH stdin.

## Utilization (about 16 minutes after boot, stack stable)

| Scope | Observation |
|---|---|
| VM 220 | 1197 MiB used, 770 MiB available, 0 swap, load 0.34. Containers: server 379 MiB, worker 317 MiB, postgres 74 MiB, all under 1% CPU. Disk 5.0 of 38 GiB |
| pve-02 host | 4013 of 7819 MiB used, 3806 MiB available, swap 0, si/so 0, CPU about 98% idle. VM 220 RSS 2081 MiB |

There was no memory pressure during execution, so the Stop Condition did not trigger.

**Follow-up:** with VM 210 running again (about 3.5 GiB RSS observed before), host headroom is projected at about 0.3 GiB. The Product Owner must validate coexistence on the planned controlled restart of VM 210 by watching `free -m`, swap and ballooning on pve-02 and inside both VMs.

## Backup and restore

- Backup: `pg_dump -Fc` is streamed over SSH straight to valhalla, and no copy stays on the VM.
  - Location: `%LOCALAPPDATA%\SETOK\setok-family\backups\authentik\authentik-20261025T221441.dump`
  - Size: 3,065,821 bytes, sha256 `bf99e36a…b6d2`
  - Check: `pg_restore --list` shows 1819 TOC entries and 230 TABLE DATA entries.
- Re-run: `Invoke-StId001.ps1 -Step Backup`.
- Restore to a rebuilt VM. Run CreateVm, Runtime and Deploy as usual, then:
  1. `docker compose stop server worker`
  2. Copy the dump into the VM, then `docker compose exec -T postgresql pg_restore -U authentik -d authentik --clean --if-exists < authentik-<ts>.dump`
  3. `docker compose start server worker`, then `Invoke-StId001.ps1 -Step Verify`.

  A rebuilt VM gets a new `AUTHENTIK_SECRET_KEY`. Existing sessions and signed tokens are then invalidated and users re-login, but users, flows and configuration restore intact. Escrowing the current secret key off-VM in a secret store would avoid this; it is recommended for a later unit and is not done here.
- The bootstrap hash is a first-start control. On a restored database, akadmin keeps the password stored in the dump.

## Local administrative recovery (no secrets)

- The akadmin password is stored DPAPI-protected (CurrentUser) at `%LOCALAPPDATA%\SETOK\setok-family\authentik-akadmin.xml` on valhalla. To read it: `[Net.NetworkCredential]::new('', (Import-Clixml <file>)).Password`.
- Lockout recovery is vendor-supported. On the VM, run `cd /opt/authentik && sudo docker compose run --rm server create_recovery_key 10 akadmin`. It prints a one-time recovery URL valid for 10 minutes. Use it only from the LAN and never store the output.
- SSH to the VM uses `~/.ssh/setok_family_idp_ed25519` as `setokadmin`. Proxmox serial console access is also available (`qm terminal 220`).

## Rollback / remediation

```bash
# on pve-02 — acts only on VMID 220 after checking its name
grep -q '^name: setok-family-idp-01$' /etc/pve/qemu-server/220.conf && qm stop 220 && qm destroy 220 --purge
```

After that, remove the valhalla files (`authentik-akadmin.xml`, the backups folder, the `setok_family_idp_ed25519` key pair) and delete the `192.168.89.22` entry from `known_hosts`. This rollback touches no Cloudflare objects, no other VMs and no other SETOK projects.

## Automation identity

No API token was created. `AUTHENTIK_BOOTSTRAP_TOKEN` was deliberately not set. Future automation must use a dedicated least-privilege service account, created in its own unit, never akadmin.
