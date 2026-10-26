<#
.SYNOPSIS
  ST-ID-002: first-family adult human identities in Authentik (Story-specific, not a reusable module).

.DESCRIPTION
  Git non-secret desired shape -> this script -> controlled privileged bootstrap (ak shell on the VM)
  -> temporary least-privilege service account + 60-minute API token -> Authentik API over LAN HTTPS
  -> observed-state verification -> credential revocation -> non-secret evidence.

  Steps:
    Inventory  read-only. Users (humans redacted), groups, roles, apps, providers, sources, outposts,
               brands/tenants and collision check for the approved identities.
    Apply      bootstrap temporary provisioner, create/verify the two adults idempotently, ALWAYS revoke
               the provisioner (finally block). Re-running yields action NONE.
    Verify     interactive login through the default authentication flow, non-admin proof (403 on admin
               APIs), recovery-key initiation (token deleted immediately, URL never stored), ST-ID-001
               health and post-apply scope scan.

  PII (names/emails) is read from a DPAPI file and never printed or written to evidence; evidence uses
  aliases (adult-01, adult-02) and Authentik pk/uuid. Passwords and tokens stay in memory or DPAPI files.
#>
[CmdletBinding()]
param([Parameter(Mandatory)][ValidateSet('Inventory','Apply','Verify')][string]$Step)

$ErrorActionPreference = 'Stop'
$repo     = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$evidence = Join-Path $repo 'docs\evidence\ST-ID-002'
$local    = Join-Path $env:LOCALAPPDATA 'SETOK\setok-family'
$credDir  = Join-Path $local 'st-id-002-credentials'
$key      = Join-Path $HOME '.ssh\setok_family_idp_ed25519'
$vmHost   = 'setokadmin@192.168.89.22'
$base     = 'https://192.168.89.22:9443'
$prov     = 'st-id-002-provisioner'
$ids      = [Net.NetworkCredential]::new('', (Import-Clixml (Join-Path $local 'st-id-002-identities.xml'))).Password | ConvertFrom-Json
if (@($ids).Count -ne 2) { throw 'STOP: operational input must contain exactly 2 approved identities.' }
$idJson   = $ids | Select-Object alias, @{n='username';e={$_.email}}, email | ConvertTo-Json -Compress -AsArray

function Invoke-Vm([string]$Cmd, [string]$Stdin) {
    $a = @('-o','BatchMode=yes','-i',$key,$vmHost,$Cmd)
    $out = if ($PSBoundParameters.ContainsKey('Stdin')) { $Stdin | ssh @a 2>&1 } else { ssh @a 2>&1 }
    if ($LASTEXITCODE) { throw "VM command failed:`n$out" }
    @($out | ForEach-Object { "$_" })
}
# Runs Python inside the Authentik worker (ak shell). Stdin carries operational input; never echoed.
function AkShell([string]$Py, [string]$Stdin = '') {
    Invoke-Vm "tr -d '\r' > /tmp/st-id-002.py" $Py | Out-Null
    $c = 'sudo docker compose -f /opt/authentik/compose.yml cp /tmp/st-id-002.py worker:/tmp/st-id-002.py >/dev/null 2>&1 && rm -f /tmp/st-id-002.py && ' +
         'tr -d "\r" | sudo docker compose -f /opt/authentik/compose.yml exec -T worker ak shell -c "exec(open(\"/tmp/st-id-002.py\").read())" 2>/dev/null; ' +
         'sudo docker compose -f /opt/authentik/compose.yml exec -T worker rm -f /tmp/st-id-002.py </dev/null'
    Invoke-Vm $c $Stdin | Where-Object { $_ -notmatch '^(###|\d+ objects imported)' -and $_ -ne '' }
}
function Save-Evidence([string]$Name, $Object) {
    New-Item -ItemType Directory -Force $evidence | Out-Null
    $file = Join-Path $evidence ("{0}-{1}.json" -f (Get-Date -Format 'yyyyMMddTHHmmss'), $Name)
    $Object | ConvertTo-Json -Depth 10 | Set-Content $file -Encoding utf8
    Write-Host "Evidence: $($file.Replace("$repo\", ''))"
}
function Api([string]$Method, [string]$Path, $Body, $Token, $Session) {
    $p = @{ Method = $Method; Uri = "$base$Path"; SkipCertificateCheck = $true; ContentType = 'application/json' }
    if ($Token)   { $p.Authentication = 'Bearer'; $p.Token = $Token }
    if ($Session) { $p.WebSession = $Session }
    if ($null -ne $Body) { $p.Body = ($Body | ConvertTo-Json -Depth 6 -Compress) }
    Invoke-RestMethod @p
}

$pyInventory = @'
import sys, json
from authentik.core.models import User, Group, Application, Provider, Source, Token
from authentik.rbac.models import Role
from authentik.outposts.models import Outpost
from authentik.brands.models import Brand
from authentik.tenants.models import Tenant
ids = json.loads(sys.stdin.read() or "[]")
def alias(u): return ((u.attributes or {}).get("setok") or {}).get("alias")
def label(u):
    if u.type != "internal" or u.username in ("akadmin", "AnonymousUser"): return u.username
    return "human:" + (alias(u) or "untagged")
out = {
  "users": [{"pk": u.pk, "uuid": str(u.uuid), "label": label(u), "type": u.type, "active": u.is_active,
             "superuser": u.is_superuser, "groups": u.groups.count(), "roles": u.roles.count(),
             "usablePassword": u.has_usable_password()} for u in User.objects.order_by("pk")],
  "groups": sorted(g.name for g in Group.objects.all()),
  "roles": sorted(r.name for r in Role.objects.all()),
  "applications": Application.objects.count(), "providers": Provider.objects.count(),
  "sources": sorted(s.slug for s in Source.objects.all()),
  "outposts": sorted(o.name for o in Outpost.objects.all()),
  "brands": Brand.objects.count(), "tenants": Tenant.objects.count(),
  "tokens": {i: Token.objects.filter(intent=i).count() for i in ("api","recovery","app_password","verification")},
  "provisionerPresent": {"user": User.objects.filter(username="st-id-002-provisioner").count(),
                         "role": Role.objects.filter(name="st-id-002-provisioner").count(),
                         "token": Token.objects.filter(identifier="st-id-002-provisioner").count()},
  "collisions": [{"alias": i["alias"],
                  "usernameExists": User.objects.filter(username=i["username"]).exists(),
                  "emailExists": User.objects.filter(email__iexact=i["email"]).exists(),
                  "ownedByStory": User.objects.filter(username=i["username"], attributes__setok__alias=i["alias"]).exists()} for i in ids],
}
print("JSON=" + json.dumps(out))
'@

$pyBootstrap = @'
from datetime import timedelta
from django.utils.timezone import now
from authentik.core.models import User, Token, TokenIntents, UserTypes
from authentik.rbac.models import Role
NAME = "st-id-002-provisioner"
PERMS = ["authentik_core.view_user", "authentik_core.add_user", "authentik_core.change_user", "authentik_core.reset_user_password"]
sa, _ = User.objects.get_or_create(username=NAME, defaults={"type": UserTypes.SERVICE_ACCOUNT, "name": "ST-ID-002 temporary provisioner",
        "path": "goauthentik.io/service-accounts", "attributes": {"setok": {"provisionedBy": "ST-ID-002", "temporary": True}}})
sa.set_unusable_password(); sa.save()
role, _ = Role.objects.get_or_create(name=NAME)
role.assign_perms(PERMS)
role.users.add(sa)
Token.objects.filter(identifier=NAME).delete()
t = Token.objects.create(identifier=NAME, user=sa, intent=TokenIntents.INTENT_API, expiring=True,
        expires=now() + timedelta(minutes=60), description="ST-ID-002 temporary provisioning token")
print("SA_SUPERUSER=" + str(sa.is_superuser))
print("SA_PERMS=" + ",".join(sorted(p.split(".")[1] for p in sa.get_all_permissions())))
print("TOKEN=" + t.key)
'@

$pyRevoke = @'
from authentik.core.models import User, Token
from authentik.rbac.models import Role
NAME = "st-id-002-provisioner"
Token.objects.filter(identifier=NAME).delete()
User.objects.filter(username=NAME).delete()
Role.objects.filter(name=NAME).delete()
print("REMAINING=%d,%d,%d" % (Token.objects.filter(identifier=NAME).count(), User.objects.filter(username=NAME).count(), Role.objects.filter(name=NAME).count()))
'@

$pyRecovery = @'
import sys, json, io
from django.core.management import call_command
from authentik.core.models import User, Token, TokenIntents
for i in json.loads(sys.stdin.read()):
    u = User.objects.get(username=i["username"], attributes__setok__alias=i["alias"])
    before = set(Token.objects.filter(user=u, intent=TokenIntents.INTENT_RECOVERY).values_list("pk", flat=True))
    buf = io.StringIO()
    try:
        call_command("create_recovery_key", "10", u.username, stdout=buf)
        ok = "/recovery/use-token/" in buf.getvalue()
    except Exception as e:
        ok = False; print("ERR", i["alias"], type(e).__name__)
    new = Token.objects.filter(user=u, intent=TokenIntents.INTENT_RECOVERY).exclude(pk__in=before)
    created = new.count(); new.delete()
    left = Token.objects.filter(user=u, intent=TokenIntents.INTENT_RECOVERY).count()
    print("RECOVERY=" + json.dumps({"alias": i["alias"], "linkIssued": ok, "tokensCreated": created, "recoveryTokensRemaining": left}))
'@

function Get-Inventory { ((AkShell $pyInventory $idJson) | Where-Object { $_ -like 'JSON=*' }).Substring(5) | ConvertFrom-Json }

switch ($Step) {
    'Inventory' {
        $inv = Get-Inventory
        Save-Evidence 'inventory' ([pscustomobject]@{ observedAt = (Get-Date).ToUniversalTime().ToString('o'); inventory = $inv })
        $inv | ConvertTo-Json -Depth 6
    }
    'Apply' {
        $pre = Get-Inventory
        foreach ($c in $pre.collisions) {
            if (($c.usernameExists -or $c.emailExists) -and -not $c.ownedByStory) { throw "STOP: $($c.alias) collides with an existing user not owned by ST-ID-002." }
        }
        $results = @(); $boot = $null; $revoke = $null
        try {
            $boot = AkShell $pyBootstrap
            $tokLine = $boot | Where-Object { $_ -like 'TOKEN=*' }
            if (-not $tokLine) { throw "Provisioner bootstrap failed: $($boot | Where-Object { $_ -notlike 'TOKEN=*' })" }
            $token = ConvertTo-SecureString $tokLine.Substring(6) -AsPlainText -Force
            Remove-Variable tokLine
            if (($boot -match '^SA_SUPERUSER=True')) { throw 'STOP: provisioner unexpectedly superuser.' }
            New-Item -ItemType Directory -Force $credDir | Out-Null
            foreach ($i in $ids) {
                $tag   = @{ setok = @{ provisionedBy = 'ST-ID-002'; alias = $i.alias } }
                $found = @((Api GET "/api/v3/core/users/?username=$([uri]::EscapeDataString($i.email))" $null $token).results)
                if ($found.Count -gt 1) { throw "STOP: multiple users match $($i.alias)." }
                if ($found.Count -eq 1) {
                    $u = $found[0]
                    if ($u.attributes.setok.alias -ne $i.alias) { throw "STOP: $($i.alias) exists but is not owned by ST-ID-002." }
                    $patch = @{}
                    if ($u.name -ne $i.name)   { $patch.name = $i.name }
                    if ($u.email -ne $i.email) { $patch.email = $i.email }
                    if (-not $u.is_active)     { $patch.is_active = $true }
                    if ($u.type -ne 'internal'){ $patch.type = 'internal' }
                    if (@($u.groups).Count)    { $patch.groups = @() }
                    if ($patch.Count) { Api PATCH "/api/v3/core/users/$($u.pk)/" $patch $token | Out-Null }
                    $results += [pscustomobject]@{ alias = $i.alias; pk = $u.pk; uuid = $u.uuid; action = $(if ($patch.Count) { 'UPDATE ' + ($patch.Keys -join ',') } else { 'NONE' }) }
                } else {
                    $u = Api POST '/api/v3/core/users/' @{ username = $i.email; name = $i.name; email = $i.email; is_active = $true;
                                                          type = 'internal'; path = 'users'; groups = @(); attributes = $tag } $token
                    $cf = Join-Path $credDir "$($i.alias).xml"
                    if (-not (Test-Path $cf)) {
                        $b = [byte[]]::new(18); [Security.Cryptography.RandomNumberGenerator]::Fill($b)
                        ConvertTo-SecureString ([Convert]::ToBase64String($b).Replace('+','-').Replace('/','_')) -AsPlainText -Force | Export-Clixml $cf
                    }
                    $pw = [Net.NetworkCredential]::new('', (Import-Clixml $cf)).Password
                    Api POST "/api/v3/core/users/$($u.pk)/set_password/" @{ password = $pw } $token | Out-Null
                    Remove-Variable pw
                    $results += [pscustomobject]@{ alias = $i.alias; pk = $u.pk; uuid = $u.uuid; action = 'CREATE' }
                }
            }
        }
        finally {
            Remove-Variable token -ErrorAction SilentlyContinue
            $revoke = AkShell $pyRevoke
        }
        $revoked = [bool]($revoke -match '^REMAINING=0,0,0$')
        Save-Evidence 'apply' ([pscustomobject]@{
            observedAt  = (Get-Date).ToUniversalTime().ToString('o')
            preCollisions = $pre.collisions
            provisioner = [pscustomobject]@{ bootstrap = @($boot | Where-Object { $_ -notlike 'TOKEN=*' }); revoke = $revoke; revoked = $revoked }
            results     = $results
        })
        $results | Format-Table -AutoSize
        "Provisioner revoked: $revoked"
        if (-not $revoked) { throw 'Provisioner revocation not confirmed.' }
    }
    'Verify' {
        $logins = foreach ($i in $ids) {
            $s = [Microsoft.PowerShell.Commands.WebRequestSession]::new()
            $flow = "/api/v3/flows/executor/default-authentication-flow/?query=next%3D%252F"
            $ch = Api GET $flow $null $null $s
            $pw = [Net.NetworkCredential]::new('', (Import-Clixml (Join-Path $credDir "$($i.alias).xml"))).Password
            $steps = @()
            for ($n = 0; $n -lt 6 -and $ch.component -ne 'xak-flow-redirect'; $n++) {
                $steps += $ch.component
                $body = switch ($ch.component) {
                    'ak-stage-identification' { $b = @{ component = $ch.component; uid_field = $i.email }; if ($ch.password_fields) { $b.password = $pw }; $b }
                    'ak-stage-password'       { @{ component = $ch.component; password = $pw } }
                    default { throw "Unexpected flow stage '$($ch.component)' for $($i.alias)." }
                }
                $csrf = $s.Cookies.GetCookies($base) | Where-Object Name -eq 'authentik_csrf'
                if ($csrf) { $s.Headers['X-authentik-CSRF'] = $csrf.Value }
                $ch = Api POST $flow $body $null $s
            }
            Remove-Variable pw
            $me = (Api GET '/api/v3/core/users/me/' $null $null $s).user
            $adminList = try { Api GET '/api/v3/core/users/' $null $null $s | Out-Null; 'ALLOWED' } catch { [int]$_.Exception.Response.StatusCode }
            $adminSys  = try { Api GET '/api/v3/admin/system/' $null $null $s | Out-Null; 'ALLOWED' } catch { [int]$_.Exception.Response.StatusCode }
            [pscustomobject]@{ alias = $i.alias; stages = $steps; outcome = $ch.component; sessionUserPk = $me.pk
                               sessionIsSuperuser = $me.is_superuser; listUsersApi = $adminList; adminSystemApi = $adminSys }
        }
        $recovery = @((AkShell $pyRecovery $idJson) | Where-Object { $_ -like 'RECOVERY=*' } | ForEach-Object { $_.Substring(9) | ConvertFrom-Json })
        $inv = Get-Inventory
        $health = Invoke-Vm 'sudo docker compose -f /opt/authentik/compose.yml ps --format "{{.Service}} {{.State}} {{.Health}}" && for p in live ready; do echo "$p $(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:9000/-/health/$p/)"; done'
        $report = [pscustomobject]@{ observedAt = (Get-Date).ToUniversalTime().ToString('o'); logins = $logins; recovery = $recovery; foundation = $health; inventory = $inv }
        Save-Evidence 'verify' $report
        $logins | Format-Table -AutoSize; $recovery | Format-Table -AutoSize; $health
        $inv.users | Format-Table -AutoSize
        "groups: $($inv.groups -join ', ') | roles: $($inv.roles -join ', ') | apps $($inv.applications) providers $($inv.providers) sources $($inv.sources -join ',') outposts $($inv.outposts -join ',') brands $($inv.brands) tenants $($inv.tenants)"
        "tokens: $($inv.tokens | ConvertTo-Json -Compress) provisioner: $($inv.provisionerPresent | ConvertTo-Json -Compress)"
    }
}
