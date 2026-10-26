<#
.SYNOPSIS
  ST-PB-001: validate the provider-binding registry and reconcile it READ-ONLY against Authentik and Cloudflare.
  Story-specific; not a reusable framework or a Phase 2 runtime.

.DESCRIPTION
  Validate   offline: JSON Schema + cross-record invariants (tenant scope, unique/independent IDs, type matrix,
             cardinality, lifecycle/replacement, PII) + ST-PB-001 story gates + negative/replacement test cases.
  Reconcile  read-only: Authentik through local `ak shell` queries (no writes), Cloudflare through HTTP GET only.
             Captures provider fingerprints before/after to prove no mutation. Runs the reconciliation twice
             and requires an identical semantic result.
  All        Validate, then Reconcile.

  Observed provider state is written only to docs/evidence/ST-PB-001/, never into the registry.
#>
[CmdletBinding()]
param([ValidateSet('Validate','Reconcile','All')][string]$Step = 'All')

$ErrorActionPreference = 'Stop'
$repo       = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$schemaPath = Join-Path $repo 'infra\bindings\provider-binding-registry.schema.json'
$regPath    = Join-Path $repo 'infra\bindings\registry.desired.json'
$evidence   = Join-Path $repo 'docs\evidence\ST-PB-001'
$cfTokenFile = Join-Path $env:LOCALAPPDATA 'SETOK\setok-family\cloudflare-st-cf-001.token.xml'
$vmKey      = Join-Path $HOME '.ssh\setok_family_idp_ed25519'
$vmHost     = 'setokadmin@192.168.89.22'
$dc         = 'sudo docker compose -f /opt/authentik/compose.yml'

function Save-Evidence([string]$Name, $Object) {
    New-Item -ItemType Directory -Force $evidence | Out-Null
    $file = Join-Path $evidence ("{0}-{1}.json" -f (Get-Date -Format 'yyyyMMddTHHmmss'), $Name)
    $Object | ConvertTo-Json -Depth 12 | Set-Content $file -Encoding utf8
    Write-Host "Evidence: $($file.Replace("$repo\", ''))"
}
function Copy-Deep($o) { $o | ConvertTo-Json -Depth 20 | ConvertFrom-Json }
function Get-Sha([string]$s) { [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($s))).ToLower() }

# ---------------------------------------------------------------- validation
function Test-Schema($reg) {
    # Test-Json (PS 7.6) returns $false without populating error details, so only the verdict is recorded.
    $ok = Test-Json -Json ($reg | ConvertTo-Json -Depth 20) -SchemaFile $schemaPath -ErrorAction SilentlyContinue
    $errs = if ($ok) { @() } else { @('SCHEMA: document does not conform to provider-binding-registry.schema.json') }
    [pscustomobject]@{ ok = [bool]$ok; errors = $errs }
}

function Test-Invariants($reg) {
    $v = [Collections.Generic.List[string]]::new()
    $tenants = @{}; foreach ($t in $reg.tenants) { $tenants[$t.tenant_id] = $t }
    $subjects = @{}; foreach ($s in $reg.subjects) { $subjects[$s.subject_id] = $s }
    $ints = @{}; foreach ($i in $reg.integrations) { $ints[$i.integration_id] = $i }
    $ress = @{}; foreach ($r in $reg.resources) { $ress[$r.resource_id] = $r }
    $bnds = @{}; foreach ($b in $reg.bindings) { $bnds[$b.binding_id] = $b }

    # unique internal IDs across every record kind
    $all = @($reg.tenants.tenant_id) + @($reg.subjects.subject_id) + @($reg.integrations.integration_id) + @($reg.resources.resource_id) + @($reg.bindings.binding_id) | Where-Object { $_ }
    $dups = $all | Group-Object | Where-Object Count -gt 1
    foreach ($d in $dups) { $v.Add("UNIQUE: internal id $($d.Name) used $($d.Count) times") }

    # tenant scope: every record references an existing tenant
    foreach ($rec in @($reg.subjects) + @($reg.integrations) + @($reg.resources) + @($reg.bindings)) {
        if (-not $rec.tenant_id) { $v.Add("TENANT: record without tenant_id"); continue }
        if (-not $tenants.ContainsKey($rec.tenant_id)) { $v.Add("TENANT: unknown tenant $($rec.tenant_id)") }
    }
    foreach ($r in $reg.resources) {
        $i = $ints[$r.integration_id]
        if (-not $i) { $v.Add("REF: resource $($r.resource_id) -> unknown integration") }
        elseif ($i.tenant_id -ne $r.tenant_id) { $v.Add("TENANT: resource $($r.resource_id) crosses tenant via integration") }
    }

    # provider-independence of internal IDs
    $externals = @($reg.bindings | ForEach-Object { $_.external.PSObject.Properties.Value }) | ForEach-Object { "$_".ToLower() } | Where-Object { $_.Length -ge 4 }
    foreach ($id in $all) {
        $body = ($id -split '_', 2)[1].ToLower()
        foreach ($e in $externals) { if ($body.Contains($e.Replace('-', '')) -or $e.Replace('-', '').Contains($body)) { $v.Add("INDEPENDENCE: internal id $id overlaps provider identifier") } }
    }

    # binding type matrix, references, provider consistency
    foreach ($b in $reg.bindings) {
        $tgt = switch ($b.target.kind) { 'subject' { $subjects[$b.target.id] } 'integration' { $ints[$b.target.id] } 'resource' { $ress[$b.target.id] } }
        if (-not $tgt) { $v.Add("REF: binding $($b.binding_id) -> unknown $($b.target.kind) $($b.target.id)"); continue }
        if ($tgt.tenant_id -ne $b.tenant_id) { $v.Add("TENANT: binding $($b.binding_id) targets another tenant") }
        $int = if ($b.integration_id) { $ints[$b.integration_id] } else { $null }
        if (-not $int) { $v.Add("REF: binding $($b.binding_id) has no known integration_id"); continue }
        if ($int.tenant_id -ne $b.tenant_id) { $v.Add("TENANT: binding $($b.binding_id) uses integration of another tenant") }
        if ($int.provider -ne $b.provider) { $v.Add("TYPE: binding $($b.binding_id) provider differs from its integration") }
        switch ($b.binding_type) {
            'identity_user' {
                if ($b.target.kind -ne 'subject' -or $tgt.subject_type -ne 'human') { $v.Add("TYPE: identity_user $($b.binding_id) must target a human subject") }
                if ($int.capability_type -ne 'identity') { $v.Add("TYPE: identity_user $($b.binding_id) must use an identity integration") }
            }
            'device_enrollment' {
                if ($b.target.kind -ne 'subject' -or $tgt.subject_type -ne 'device') { $v.Add("TYPE: device_enrollment $($b.binding_id) must target a device subject") }
            }
            'integration_account' {
                if ($b.target.kind -ne 'integration' -or $b.target.id -ne $b.integration_id) { $v.Add("TYPE: integration_account $($b.binding_id) must target its own integration") }
            }
            'managed_resource' {
                if ($b.target.kind -ne 'resource' -or $tgt.integration_id -ne $b.integration_id) { $v.Add("TYPE: managed_resource $($b.binding_id) must target a resource of the same integration") }
            }
        }
    }

    # cardinality: no duplicate ACTIVE binding for tenant/target/provider/type/external, and an external identity
    # cannot be ACTIVE for two different targets of the same tenant/provider/type
    $active = @($reg.bindings | Where-Object status -eq 'ACTIVE')
    $ext = { param($b) ($b.external.PSObject.Properties | Sort-Object Name | ForEach-Object { "$($_.Name)=$($_.Value)" }) -join ';' }
    foreach ($g in ($active | Group-Object { "$($_.tenant_id)|$($_.target.id)|$($_.provider)|$($_.binding_type)|$(& $ext $_)" } | Where-Object Count -gt 1)) {
        $v.Add("CARDINALITY: duplicate active binding $($g.Name)")
    }
    foreach ($g in ($active | Group-Object { "$($_.tenant_id)|$($_.provider)|$($_.binding_type)|$(& $ext $_)" } | Where-Object { @($_.Group.target.id | Select-Object -Unique).Count -gt 1 })) {
        $v.Add("CARDINALITY: external identity active for multiple targets $($g.Name)")
    }

    # lifecycle / replacement: replacement keeps the same internal target; the replaced binding is RETIRED
    foreach ($b in $reg.bindings | Where-Object replaces) {
        $old = $bnds[$b.replaces]
        if (-not $old) { $v.Add("LIFECYCLE: $($b.binding_id) replaces unknown binding"); continue }
        if ($old.tenant_id -ne $b.tenant_id -or $old.target.id -ne $b.target.id -or $old.provider -ne $b.provider -or $old.binding_type -ne $b.binding_type) {
            $v.Add("LIFECYCLE: $($b.binding_id) must replace a binding of the same tenant/target/provider/type")
        }
        if ($b.status -eq 'ACTIVE' -and $old.status -ne 'RETIRED') { $v.Add("LIFECYCLE: $($b.replaces) must be RETIRED when replaced by an ACTIVE binding") }
    }

    # privacy: no email-like or secret-like values anywhere in the registry
    $json = $reg | ConvertTo-Json -Depth 20 -Compress
    if ($json -match '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}') { $v.Add('PRIVACY: email-like value present') }
    if ($json -match '(?i)(bearer |pbkdf2_|-----BEGIN|recovery/use-token)') { $v.Add('PRIVACY: secret-like value present') }
    , $v.ToArray()
}

function Test-StoryGates($reg) {
    $v = [Collections.Generic.List[string]]::new()
    $humans  = @($reg.subjects | Where-Object { $_.subject_type -eq 'human' -and $_.status -eq 'ACTIVE' })
    $devices = @($reg.subjects | Where-Object subject_type -eq 'device')
    $idb     = @($reg.bindings | Where-Object { $_.binding_type -eq 'identity_user' -and $_.status -eq 'ACTIVE' })
    $devb    = @($reg.bindings | Where-Object binding_type -eq 'device_enrollment')
    $cf      = @($reg.integrations | Where-Object provider -eq 'cloudflare-zero-trust')
    $mr      = @($reg.bindings | Where-Object { $_.binding_type -eq 'managed_resource' -and $_.status -eq 'ACTIVE' -and $_.external.profile_name -eq 'SETOK-FAMILY-MANAGED' })
    if (@($reg.tenants).Count -ne 1) { $v.Add('GATE: exactly one tenant expected') }
    if ($humans.Count -ne 2 -or @($humans | Where-Object human_kind -ne 'adult').Count) { $v.Add("GATE: exactly 2 adult human subjects expected (found $($humans.Count))") }
    if ($devices.Count) { $v.Add("GATE: device subjects must be 0 (found $($devices.Count))") }
    if ($devb.Count) { $v.Add("GATE: device bindings must be 0 (found $($devb.Count))") }
    if ($idb.Count -ne 2 -or @($idb.target.id | Select-Object -Unique).Count -ne 2) { $v.Add("GATE: exactly 2 active human identity bindings to distinct subjects expected") }
    if ($cf.Count -ne 1 -or $cf[0].ownership -ne 'shared') { $v.Add('GATE: Cloudflare integration must be modeled as shared') }
    if ($mr.Count -ne 1) { $v.Add('GATE: exactly one active managed_resource binding for SETOK-FAMILY-MANAGED expected') }
    if (@($reg.resources | Where-Object resource_type -eq 'device_profile').Count -ne 1) { $v.Add('GATE: exactly one device_profile resource expected') }
    , $v.ToArray()
}

function Invoke-Validation($reg) {
    $s = Test-Schema $reg
    $i = Test-Invariants $reg
    $g = Test-StoryGates $reg
    [pscustomobject]@{ schemaOk = $s.ok; schemaErrors = $s.errors; invariantViolations = $i; storyGateViolations = $g
                       pass = ($s.ok -and $i.Count -eq 0 -and $g.Count -eq 0) }
}

function Invoke-Cases($reg) {
    $t = $reg.tenants[0].tenant_id
    $cases = [ordered]@{}
    $c = Copy-Deep $reg; $c.bindings[0].PSObject.Properties.Remove('tenant_id');                $cases['missing tenant_id on binding'] = @{ reg = $c; expect = 'FAIL' }
    $c = Copy-Deep $reg; $d = Copy-Deep $c.bindings[0]; $d.binding_id = 'bnd_01M5VBRV8ZZZZZZZZZZZZZZZZZ'; $c.bindings += $d
                                                                                                $cases['duplicate active binding (same subject/provider/type/external)'] = @{ reg = $c; expect = 'FAIL' }
    $c = Copy-Deep $reg; $d = Copy-Deep $c.bindings[1]; $d.binding_id = 'bnd_01M5VBRV8YYYYYYYYYYYYYYYYY'; $d.target.id = $c.subjects[0].subject_id; $c.bindings += $d
                                                                                                $cases['same external identity active for two subjects'] = @{ reg = $c; expect = 'FAIL' }
    $c = Copy-Deep $reg; $c.subjects += [pscustomobject]@{ subject_id = 'sub_01M5VBRV8XXXXXXXXXXXXXXXXX'; tenant_id = $t; subject_type = 'device'; alias = 'device-01'; status = 'ACTIVE' }
                                                                                                $cases['device subject added in this Story'] = @{ reg = $c; expect = 'FAIL' }
    $c = Copy-Deep $reg; $c.bindings[3].binding_type = 'device_enrollment'; $c.bindings[3].target = [pscustomobject]@{ kind = 'subject'; id = $c.subjects[0].subject_id }
                                                                                                $cases['managed profile treated as a device binding'] = @{ reg = $c; expect = 'FAIL' }
    $c = Copy-Deep $reg; $c.tenants += [pscustomobject]@{ tenant_id = 'tnt_01M5VBRV8WWWWWWWWWWWWWWWWW'; tenant_type = 'family'; alias = 'other-family'; status = 'ACTIVE' }; $c.bindings[0].tenant_id = 'tnt_01M5VBRV8WWWWWWWWWWWWWWWWW'
                                                                                                $cases['cross-tenant binding'] = @{ reg = $c; expect = 'FAIL' }
    $c = Copy-Deep $reg; $c.subjects[0].subject_id = 'sub_AD9CA7D335064ACEA45F455D4E'; $c.bindings[0].target.id = $c.subjects[0].subject_id
                                                                                                $cases['internal id derived from provider uuid'] = @{ reg = $c; expect = 'FAIL' }
    $c = Copy-Deep $reg; $c.integrations[1].ownership = 'dedicated'
                                                                                                $cases['shared Cloudflare account claimed as dedicated'] = @{ reg = $c; expect = 'FAIL' }
    $c = Copy-Deep $reg; $c.subjects[0].alias = 'someone@example.com'
                                                                                                $cases['email in registry'] = @{ reg = $c; expect = 'FAIL' }
    $c = Copy-Deep $reg; $c.subjects[0] | Add-Member -NotePropertyName role -NotePropertyValue 'Owner'
                                                                                                $cases['domain role attribute on subject'] = @{ reg = $c; expect = 'FAIL' }
    # valid replacement: provider user re-created, old binding retired, internal subject unchanged
    $c = Copy-Deep $reg; $old = $c.bindings[0]; $new = Copy-Deep $old
    $old.status = 'RETIRED'; $old | Add-Member -NotePropertyName retired_on -NotePropertyValue '2026-12-01'
    $new.binding_id = 'bnd_01M5VBRV8VVVVVVVVVVVVVVVVV'; $new.external = [pscustomobject]@{ user_uuid = '00000000-0000-4000-8000-000000000001'; user_pk = 99 }
    $new.valid_from = '2026-12-01'; $new | Add-Member -NotePropertyName replaces -NotePropertyValue $old.binding_id; $c.bindings += $new
                                                                                                $cases['replacement: retire old, new binding, same subject_id'] = @{ reg = $c; expect = 'PASS' }
    $c = Copy-Deep $reg; $new = Copy-Deep $c.bindings[0]
    $new.binding_id = 'bnd_01M5VBRV8TTTTTTTTTTTTTTTTT'; $new.external = [pscustomobject]@{ user_uuid = '00000000-0000-4000-8000-000000000002'; user_pk = 98 }
    $new | Add-Member -NotePropertyName replaces -NotePropertyValue $c.bindings[0].binding_id; $c.bindings += $new
                                                                                                $cases['replacement without retiring the old binding'] = @{ reg = $c; expect = 'FAIL' }
    $c = Copy-Deep $reg; $c.bindings[0].status = 'STALE'
                                                                                                $cases['stale binding is not counted as an active human binding'] = @{ reg = $c; expect = 'FAIL' }
    $c = Copy-Deep $reg; $c.bindings[0].status = 'RETIRED'
                                                                                                $cases['RETIRED requires retired_on'] = @{ reg = $c; expect = 'FAIL' }
    foreach ($k in $cases.Keys) {
        $r = Invoke-Validation $cases[$k].reg
        $got = if ($r.pass) { 'PASS' } else { 'FAIL' }
        $why = @(@($r.schemaErrors) + @($r.invariantViolations) + @($r.storyGateViolations) | Select-Object -First 3)
        [pscustomobject]@{ case = $k; expected = $cases[$k].expect; got = $got; ok = ($got -eq $cases[$k].expect); reasons = $why }
    }
}

# ---------------------------------------------------------------- read-only reconciliation
$pyAuthentik = @'
import sys, json, hashlib
from authentik.core.models import User, Group, Token, Application, Provider, Source
from authentik.rbac.models import Role
from authentik.flows.models import Flow
from authentik.outposts.models import Outpost
want = json.loads(sys.stdin.read())
def fp():
    rows = [(u.pk, str(u.uuid), u.is_active, u.type, json.dumps(u.attributes, sort_keys=True), sorted(u.groups.values_list("pk", flat=True)), sorted(u.roles.values_list("pk", flat=True)), u.password)
            for u in User.objects.order_by("pk")]
    counts = [Group.objects.count(), Role.objects.count(), Token.objects.count(), Application.objects.count(), Provider.objects.count(), Source.objects.count(), Flow.objects.count(), Outpost.objects.count()]
    return hashlib.sha256(json.dumps([rows, counts], default=str).encode()).hexdigest(), counts
before, counts = fp()
res = []
for w in want:
    qs = User.objects.filter(uuid=w["user_uuid"])
    n = qs.count(); u = qs.first()
    res.append({"binding_id": w["binding_id"], "matches": n,
        "pk_match": bool(u and u.pk == w["user_pk"]), "active": bool(u and u.is_active), "type": u.type if u else None,
        "superuser": bool(u and u.is_superuser), "groups": u.groups.count() if u else None, "roles": u.roles.count() if u else None,
        "provisioned_alias": ((u.attributes or {}).get("setok") or {}).get("alias") if u else None})
after, _ = fp()
print("JSON=" + json.dumps({"bindings": res, "fingerprint_before": before, "fingerprint_after": after,
      "counts": dict(zip(["groups","roles","tokens","applications","providers","sources","flows","outposts"], counts)),
      "superusers": sorted(u.username for u in User.objects.all() if u.is_superuser)}))
'@

function Get-AuthentikObserved($reg) {
    $want = @($reg.bindings | Where-Object { $_.provider -eq 'authentik' -and $_.binding_type -eq 'identity_user' } |
              ForEach-Object { @{ binding_id = $_.binding_id; user_uuid = $_.external.user_uuid; user_pk = $_.external.user_pk } }) | ConvertTo-Json -Compress -AsArray
    $a = @('-o','BatchMode=yes','-i',$vmKey,$vmHost)
    $pyAuthentik | ssh @a "tr -d '\r' > /tmp/st-pb-001.py" 2>&1 | Out-Null
    $cmd = "$dc cp /tmp/st-pb-001.py worker:/tmp/st-pb-001.py >/dev/null 2>&1 && rm -f /tmp/st-pb-001.py && tr -d '\r' | $dc exec -T worker ak shell -c 'exec(open(""/tmp/st-pb-001.py"").read())' 2>/dev/null; $dc exec -T worker rm -f /tmp/st-pb-001.py </dev/null"
    $out = $want | ssh @a $cmd 2>&1
    $line = @($out | Where-Object { "$_" -like 'JSON=*' })[0]
    if (-not $line) { throw "Authentik read failed: $out" }
    "$line".Substring(5) | ConvertFrom-Json
}

function Invoke-CfGet([string]$Path) {
    # GET is the only verb this Story may use against Cloudflare.
    $r = Invoke-RestMethod -Method Get -Uri "https://api.cloudflare.com/client/v4$Path" -Authentication Bearer -Token (Import-Clixml $cfTokenFile)
    if (-not $r.success) { throw "Cloudflare GET $Path failed" }
    $r.result
}

function Get-CloudflareObserved($reg) {
    $acctBinding = @($reg.bindings | Where-Object binding_type -eq 'integration_account' | Where-Object provider -eq 'cloudflare-zero-trust')[0]
    $accounts = @(Invoke-CfGet '/accounts')
    $acct = $acctBinding.external.account_id
    $org = Invoke-CfGet "/accounts/$acct/access/organizations"
    $profiles = @(Invoke-CfGet "/accounts/$acct/devices/policies")
    [pscustomobject]@{
        accounts      = @($accounts | ForEach-Object { [pscustomobject]@{ id = $_.id; type = $_.type } })
        teamDomain    = $org.auth_domain
        profiles      = @($profiles | ForEach-Object { [pscustomobject]@{ policy_id = $_.policy_id; name = $_.name; default = [bool]$_.default; enabled = $_.enabled } })
        fingerprint   = Get-Sha (($profiles | Sort-Object policy_id | ConvertTo-Json -Depth 10 -Compress) + "|" + ($org | ConvertTo-Json -Depth 5 -Compress))
    }
}

function Get-Semantic($reg, $ak, $cf) {
    $out = foreach ($b in $reg.bindings | Where-Object status -eq 'ACTIVE') {
        $checks = [ordered]@{}
        switch ("$($b.provider)/$($b.binding_type)") {
            'authentik/identity_user' {
                $o = @($ak.bindings | Where-Object binding_id -eq $b.binding_id)[0]
                $checks.resolvesExactlyOnce = ($o.matches -eq 1); $checks.pkMatches = $o.pk_match; $checks.active = $o.active
                $checks.typeInternal = ($o.type -eq 'internal'); $checks.notSuperuser = (-not $o.superuser)
                $checks.noGroupsOrRoles = ($o.groups -eq 0 -and $o.roles -eq 0)
            }
            'cloudflare-zero-trust/integration_account' {
                $checks.accountVisible = (@($cf.accounts | Where-Object id -eq $b.external.account_id).Count -eq 1)
                $checks.teamDomainMatches = ($cf.teamDomain -eq $b.external.team_domain)
                $checks.modeledAsShared = (@($reg.integrations | Where-Object integration_id -eq $b.integration_id)[0].ownership -eq 'shared')
            }
            'cloudflare-zero-trust/managed_resource' {
                $named = @($cf.profiles | Where-Object name -eq $b.external.profile_name)
                $checks.existsExactlyOnce = ($named.Count -eq 1)
                $checks.policyIdMatches = ($named.Count -eq 1 -and $named[0].policy_id -eq $b.external.policy_id)
                $checks.notDefault = ($named.Count -eq 1 -and -not $named[0].default)
                $checks.defaultProfileNotBound = (@($cf.profiles | Where-Object default | Where-Object { $_.policy_id -in @($reg.bindings.external.policy_id) }).Count -eq 0)
            }
            default { $checks.unsupportedBinding = $false }
        }
        $ok = -not ($checks.Values -contains $false)
        [pscustomobject]@{ binding_id = $b.binding_id; provider = $b.provider; binding_type = $b.binding_type
                           observedStatus = $(if ($ok) { 'ACTIVE' } else { 'ERROR' }); checks = [pscustomobject]$checks }
    }
    @($out)
}

function Test-StaticReadOnly {
    $src = Get-Content $PSCommandPath -Raw
    $httpWrite = '(?i)-Method\s+(P' + 'OST|P' + 'UT|P' + 'ATCH|D' + 'ELETE)\b'
    $ormWrite  = '\.(sa' + 've|del' + 'ete|cre' + 'ate|upd' + 'ate|bulk_cre' + 'ate|set_pass' + 'word|get_or_cre' + 'ate)\('
    [pscustomobject]@{ httpWriteCalls = ([regex]::Matches($src, $httpWrite)).Count; ormWriteCalls = ([regex]::Matches($src, $ormWrite)).Count }
}

# ---------------------------------------------------------------- main
$reg = Get-Content $regPath -Raw | ConvertFrom-Json
$overall = $true

if ($Step -in 'Validate','All') {
    $val = Invoke-Validation $reg
    $cases = @(Invoke-Cases $reg)
    $casesOk = -not ($cases.ok -contains $false)
    Save-Evidence 'validate' ([pscustomobject]@{ observedAt = (Get-Date).ToUniversalTime().ToString('o'); registrySha256 = (Get-FileHash $regPath -Algorithm SHA256).Hash.ToLower()
        schemaSha256 = (Get-FileHash $schemaPath -Algorithm SHA256).Hash.ToLower(); registry = $val; cases = $cases; casesPass = $casesOk })
    "Schema: $($val.schemaOk)  Invariants: $(@($val.invariantViolations).Count) violations  Story gates: $(@($val.storyGateViolations).Count) violations"
    $cases | Format-Table case, expected, got, ok -AutoSize
    if (-not ($val.pass -and $casesOk)) { $overall = $false; $val.schemaErrors; $val.invariantViolations; $val.storyGateViolations }
}

if ($Step -in 'Reconcile','All') {
    $static = Test-StaticReadOnly
    $runs = foreach ($n in 1, 2) {
        $ak = Get-AuthentikObserved $reg
        $cfBefore = Get-CloudflareObserved $reg
        $sem = Get-Semantic $reg $ak $cfBefore
        $cfAfter = Get-CloudflareObserved $reg
        [pscustomobject]@{ run = $n; observedAt = (Get-Date).ToUniversalTime().ToString('o'); semantic = $sem
            authentik = $ak; cloudflare = $cfBefore
            readOnly = [pscustomobject]@{ authentikFingerprintUnchanged = ($ak.fingerprint_before -eq $ak.fingerprint_after)
                                          cloudflareFingerprintUnchanged = ($cfBefore.fingerprint -eq $cfAfter.fingerprint) } }
    }
    $sameSemantic = (($runs[0].semantic | ConvertTo-Json -Depth 8 -Compress) -eq ($runs[1].semantic | ConvertTo-Json -Depth 8 -Compress))
    $crossRunUnchanged = ($runs[0].authentik.fingerprint_before -eq $runs[1].authentik.fingerprint_after) -and ($runs[0].cloudflare.fingerprint -eq $runs[1].cloudflare.fingerprint)
    $allActive = -not (@($runs.semantic.observedStatus) -contains 'ERROR')
    $ro = ($static.httpWriteCalls -eq 0 -and $static.ormWriteCalls -eq 0 -and -not (@($runs.readOnly.authentikFingerprintUnchanged) -contains $false) -and -not (@($runs.readOnly.cloudflareFingerprintUnchanged) -contains $false) -and $crossRunUnchanged)
    Save-Evidence 'reconcile' ([pscustomobject]@{ runs = $runs; repeatSameSemanticResult = $sameSemantic; staticReadOnly = $static; providerFingerprintsUnchangedAcrossRuns = $crossRunUnchanged; readOnlyProof = $ro; reconciliationPass = $allActive })
    $runs[1].semantic | ForEach-Object { "{0} {1,-40} {2}" -f $_.binding_id, "$($_.provider)/$($_.binding_type)", $_.observedStatus }
    "Repeat same semantic result: $sameSemantic | Read-only proof: $ro (static writes: $($static.httpWriteCalls)/$($static.ormWriteCalls))"
    if (-not ($sameSemantic -and $allActive -and $ro)) { $overall = $false }
}

if (-not $overall) { Write-Error 'ST-PB-001 validation/reconciliation FAILED'; exit 1 }
'ST-PB-001: PASS'
