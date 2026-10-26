# ST-ID-002 — Evidence

This is the non-secret, PII-minimized evidence for the first-family adult identities in Authentik. Every file was produced by `scripts/st-id-002/Invoke-StId002.ps1`. The desired shape is in `infra/authentik/st-id-002.identities.json`.

Identities appear only as the aliases `adult-01` and `adult-02`, together with Authentik pk and uuid. Names, emails and passwords never appear in Git or evidence. The operational input is stored DPAPI-protected (CurrentUser) on valhalla at `%LOCALAPPDATA%\SETOK\setok-family\st-id-002-identities.xml`. The initial credentials are in `...\st-id-002-credentials\adult-0N.xml` and are for handover into the PO's password manager.

## Timeline

| File | Step | Result |
|---|---|---|
| `20261025T232219-inventory.json` | Inventory (pre) | 3 users (AnonymousUser, embedded outpost SA, akadmin). Collision check for both aliases: username/email absent |
| `20261025T232253-apply.json` | Apply | Temporary provisioner bootstrapped (not superuser; perms `add_user, change_user, reset_user_password, view_user`). `adult-01` (pk 6) and `adult-02` (pk 7) were CREATED. Provisioner revoked: `REMAINING=0,0,0` |
| `20261025T232324-verify.json` | Verify | Login, non-admin proof, recovery, health and scope checks all pass (details below) |
| `20261025T232400-apply.json` | Apply (re-run) | Both `NONE`, no duplicates. The provisioner was bootstrapped again and revoked again (`0,0,0`) |
| `*-inventory.json` (post) | Inventory | 5 users. Provisioner user, role and token are absent |

## Provisioning credential

- The service account `st-id-002-provisioner` (type `service_account`, unusable password) held a dedicated RBAC role `st-id-002-provisioner` with only the 4 user permissions listed above.
- Its API token was `expiring=True` with a 60-minute lifetime. The token lived only in process memory as a SecureString and was used over LAN HTTPS (9443).
- A `finally` block deletes the token, service account and role at the end of every run, and evidence records `REMAINING=0,0,0`.
- No `akadmin` API token was created. akadmin was used only implicitly, through local `ak shell` on the VM as the privileged bootstrap.
- The temporary user's pk 5 is consumed, so the gap between akadmin (4) and the humans (6, 7) is expected.

## Verification (`20261025T232324-verify.json`)

| Check | adult-01 | adult-02 |
|---|---|---|
| Account | pk 6, `internal`, active, groups 0, roles 0, superuser false | pk 7, same |
| Interactive login (default-authentication-flow: identification → password) | `xak-flow-redirect` | `xak-flow-redirect` |
| `/api/v3/core/users/me/` session user | pk 6, `is_superuser=false` | pk 7, `is_superuser=false` |
| Admin APIs with the user's session (`/core/users/`, `/admin/system/`) | 403 / 403 | 403 / 403 |
| Recovery initiation (vendor `create_recovery_key 10`) | link issued; 1 token created, then deleted; 0 remaining | same |

- The recovery URLs were never printed or stored, and the recovery tokens were deleted immediately. No password was rotated.
- **ST-ID-001 foundation:** postgresql, server and worker are running and healthy; `/-/health/live/` returns 200 and `/-/health/ready/` 200.
- **Scope scan, unchanged from pre-apply:**
  - groups: `authentik Admins`, `authentik Agent-Users`, `authentik Read-only`
  - roles: `ak-managed-role--user-2`, `authentik Agent-Users`, `authentik Read-only`
  - applications 0, providers 0, sources `authentik-built-in`, outposts only the built-in embedded one, brands 1, tenants 1
  - api tokens: 1, the embedded outpost's
  - recovery tokens 0
- No Owner, Parent, Viewer, Child, Guardian or Family objects exist, there is no child login, and no OIDC, federation, Access or Outposts were added. Each human carries one opaque ownership tag in `attributes.setok = {provisionedBy: ST-ID-002, alias}`. It is used only for collision-safe idempotency and rollback, not for authorization.
- akadmin remains the only superuser (break-glass).

## How a person logs in

Logins go through the LAN only, at `https://192.168.89.22:9443/` or `http://192.168.89.22:9000/`, using the login email as the identifier. The PO hands each initial password over from the DPAPI file:

```powershell
[Net.NetworkCredential]::new('', (Import-Clixml "$env:LOCALAPPDATA\SETOK\setok-family\st-id-002-credentials\adult-01.xml")).Password
```

After the passwords are in a password manager, the credential files can be deleted. The users should change their password on first use; nothing forces this, because no flow changes were in scope.

## Rollback / deactivation (only these two identities)

On the VM, as root, with `docker compose -f /opt/authentik/compose.yml exec -T worker ak shell`:

```python
from authentik.core.models import User
qs = User.objects.filter(attributes__setok__provisionedBy="ST-ID-002", attributes__setok__alias__in=["adult-01", "adult-02"], type="internal")
assert qs.count() <= 2 and not any(u.is_superuser for u in qs)
qs.update(is_active=False)   # deactivate first (keeps audit/events)
# qs.delete()                # delete only after confirming ownership by pk (6, 7)
```

After that, delete the valhalla files `st-id-002-identities.xml` and `st-id-002-credentials\`. Rollback touches nothing else: akadmin, the built-in users, the ST-ID-001 foundation and Cloudflare all stay as they are. If a run is interrupted, re-running `-Step Apply` re-creates and then revokes the provisioner, and the `0,0,0` check confirms the cleanup.
