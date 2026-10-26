<#
.SYNOPSIS
  ST-POL-001: baseline Policy Intent validation, precedence invariants, and deterministic Cloudflare DNS
  compilation plan. Story-specific; provider access is READ-ONLY (HTTP GET only).

.DESCRIPTION
  Three separate representations:
    domain desired intent     infra/policy/baseline.desired.json         (SETOK semantics only)
    provider adapter data     infra/policy/cloudflare/dns-adapter.json   (names, not numeric IDs)
    observed capabilities     docs/evidence/ST-POL-001/*-discovery.json  (read-only Cloudflare facts)
    compiled plan             docs/evidence/ST-POL-001/*-compile.json    (COMPILED, apply BLOCKED; never APPLIED)

  Compilation fails closed: any unresolved/unsupported mandatory control fails the whole compilation; no
  partial plan is produced. Scope is resolved only from ACTIVE device_enrollment bindings in the registry;
  with zero bindings the plan is COMPILED but apply-BLOCKED. A global/unscoped scope is always rejected.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repo        = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$schemaPath  = Join-Path $repo 'infra\policy\policy-intent.schema.json'
$intentPath  = Join-Path $repo 'infra\policy\baseline.desired.json'
$adapterPath = Join-Path $repo 'infra\policy\cloudflare\dns-adapter.json'
$regPath     = Join-Path $repo 'infra\bindings\registry.desired.json'
$evidence    = Join-Path $repo 'docs\evidence\ST-POL-001'
$cfToken     = Join-Path $env:LOCALAPPDATA 'SETOK\setok-family\cloudflare-st-cf-001.token.xml'

$Required = [ordered]@{
    'threat.malware' = 'BLOCK'; 'threat.phishing' = 'BLOCK'; 'threat.command_and_control' = 'BLOCK'
    'content.adult' = 'BLOCK'; 'content.gambling' = 'BLOCK'; 'search.safe_search' = 'FORCE'; 'video.youtube_restricted' = 'FORCE'
}
$ThreatControls = @('threat.malware', 'threat.phishing', 'threat.command_and_control')

function Save-Evidence([string]$Name, $Object) {
    New-Item -ItemType Directory -Force $evidence | Out-Null
    $file = Join-Path $evidence ("{0}-{1}.json" -f (Get-Date -Format 'yyyyMMddTHHmmss'), $Name)
    $Object | ConvertTo-Json -Depth 14 | Set-Content $file -Encoding utf8
    Write-Host "Evidence: $($file.Replace("$repo\", ''))"
}
function Copy-Deep($o) { $o | ConvertTo-Json -Depth 20 | ConvertFrom-Json }
function Get-Sha([string]$s) { [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($s))).ToLower() }

# ------------------------------------------------------------ read-only Cloudflare discovery
function Invoke-CfGet([string]$Path) {
    # GET is the only verb this Story may use against Cloudflare.
    $r = Invoke-RestMethod -Method Get -Uri "https://api.cloudflare.com/client/v4$Path" -Authentication Bearer -Token (Import-Clixml $cfToken)
    if (-not $r.success) { throw "Cloudflare GET $Path failed" }
    $r.result
}
function Get-Discovery($accountId) {
    $cats     = @(Invoke-CfGet "/accounts/$accountId/gateway/categories")
    $rules    = @(Invoke-CfGet "/accounts/$accountId/gateway/rules")
    $profiles = @(Invoke-CfGet "/accounts/$accountId/devices/policies")
    $config   = Invoke-CfGet "/accounts/$accountId/gateway/configuration"
    $flat = foreach ($c in $cats) {
        [pscustomobject]@{ id = $c.id; name = $c.name; parent = $null; class = $c.class }
        foreach ($s in @($c.subcategories)) { if ($s) { [pscustomobject]@{ id = $s.id; name = $s.name; parent = $c.name; class = $c.class } } }
    }
    [pscustomobject]@{
        categories  = @($flat | Sort-Object id)
        gatewayRules = @($rules | Sort-Object id | ForEach-Object { [pscustomobject]@{ id = $_.id; name = $_.name; action = $_.action; enabled = $_.enabled; precedence = $_.precedence; filters = $_.filters } })
        managedProfile = @($profiles | Where-Object name -eq 'SETOK-FAMILY-MANAGED' | ForEach-Object { [pscustomobject]@{ policy_id = $_.policy_id; enabled = $_.enabled; precedence = $_.precedence } })
        fingerprint = [pscustomobject]@{
            rules      = Get-Sha ($rules | Sort-Object id | ConvertTo-Json -Depth 12 -Compress)
            profiles   = Get-Sha ($profiles | Sort-Object policy_id | ConvertTo-Json -Depth 12 -Compress)
            config     = Get-Sha ($config | ConvertTo-Json -Depth 12 -Compress)
            categories = Get-Sha ($cats | ConvertTo-Json -Depth 12 -Compress)
        }
    }
}

# ------------------------------------------------------------ domain intent validation
function Test-Intent($intent, $reg) {
    $v = [Collections.Generic.List[string]]::new()
    $ok = Test-Json -Json ($intent | ConvertTo-Json -Depth 20) -SchemaFile $schemaPath -ErrorAction SilentlyContinue
    if (-not $ok) { $v.Add('SCHEMA: intent does not conform to policy-intent.schema.json') }
    if (-not (@($reg.tenants | Where-Object { $_.tenant_id -eq $intent.tenant_id -and $_.status -eq 'ACTIVE' }).Count -eq 1)) { $v.Add('TENANT: intent tenant is not an ACTIVE registry tenant') }
    foreach ($k in $Required.Keys) {
        $m = @($intent.controls | Where-Object control -eq $k)
        if ($m.Count -ne 1) { $v.Add("BASELINE: mandatory control $k present $($m.Count) times (expected 1)") }
        elseif ($m[0].action -ne $Required[$k]) { $v.Add("BASELINE: $k must be $($Required[$k]) (found $($m[0].action))") }
    }
    if ($intent.overridable -ne $false) { $v.Add('BASELINE: baseline must be non-overridable') }
    # provider leakage: no provider names/syntax, numbers or UUIDs anywhere in domain intent
    $json = $intent | ConvertTo-Json -Depth 20 -Compress
    if ($json -match '(?i)(cloudflare|gateway|dns\.|security_category|content_category|wirefilter|provider_|rule_id|category_id|profile_id)') { $v.Add('PROVIDER-LEAK: provider syntax or identifier key in domain intent') }
    if ($json -match '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}') { $v.Add('PROVIDER-LEAK: UUID in domain intent') }
    if (($json -replace '"policy_contract_version":1', '') -match ':\s*-?\d+\s*[,}\]]') { $v.Add('PROVIDER-LEAK: numeric identifier in domain intent') }
    if ($intent.scope.applies_to -ne 'all_device_subjects_of_tenant') { $v.Add('SCOPE: baseline scope must be tenant device subjects, never global or an invented device list') }
    , $v.ToArray()
}

# ------------------------------------------------------------ precedence invariants
# A construct below the baseline layers may add restrictions but never weaken a baseline control.
$WeakeningActions = @('ALLOW', 'UNFORCE', 'DISABLE', 'BYPASS')
function Test-Construct($construct, $intent) {
    $v = [Collections.Generic.List[string]]::new()
    $baselineKeys = @($intent.controls.control)
    foreach ($e in @($construct.effects)) {
        if ($e.target -in $baselineKeys -and $e.action -in $WeakeningActions) { $v.Add("PRECEDENCE: $($construct.construct) cannot $($e.action) baseline control $($e.target)") }
    }
    foreach ($x in @($construct.exempt_from)) { if ($x -and $x -in $baselineKeys) { $v.Add("PRECEDENCE: $($construct.construct) cannot exempt services from baseline control $x") } }
    if ($construct.disables_baseline) { $v.Add("PRECEDENCE: $($construct.construct) cannot disable the baseline") }
    , $v.ToArray()
}
# Explainable decision for a request (ARCHITECTURE §10.4 order). Requests carry SETOK semantic categories.
function Get-Decision($intent, $constructs, $request) {
    foreach ($t in $ThreatControls) { if ($t -in $request.categories) { return [pscustomobject]@{ decision = 'BLOCK'; reason = 'security_threat_baseline'; control = $t } } }
    foreach ($c in @($intent.controls | Where-Object { $_.layer -eq 'mandatory_safety_restriction' -and $_.action -eq 'BLOCK' })) {
        if ($c.control -in $request.categories) { return [pscustomobject]@{ decision = 'BLOCK'; reason = 'mandatory_safety_restriction'; control = $c.control } }
    }
    $ordered = @($constructs | Sort-Object layer)
    foreach ($k in $ordered) {
        if ($k.construct -eq 'essential_services' -and $request.essential) { return [pscustomobject]@{ decision = 'ALLOW'; reason = 'essential_services'; control = $null } }
        foreach ($e in @($k.effects)) { if ($e.target -in $request.categories) { return [pscustomobject]@{ decision = $e.action; reason = $k.construct; control = $e.target } } }
    }
    [pscustomobject]@{ decision = 'ALLOW'; reason = 'default_family_policy'; control = $null }
}

# ------------------------------------------------------------ compilation (fail closed)
function Invoke-Compile($intent, $adapter, $disc, $reg, [string]$RequestedScope = 'tenant') {
    $errors = [Collections.Generic.List[string]]::new(); $warnings = [Collections.Generic.List[string]]::new()
    $iv = Test-Intent $intent $reg
    foreach ($x in $iv) { $errors.Add($x) }
    if ($RequestedScope -ne 'tenant') { $errors.Add("SCOPE: requested scope '$RequestedScope' rejected; only tenant device-subject scope is compilable") }
    $resolved = foreach ($c in @($intent.controls | Sort-Object control)) {
        $m = $adapter.mappings.($c.control)
        if (-not $m) { $errors.Add("UNRESOLVED: no adapter mapping for mandatory control $($c.control)"); continue }
        if ($m.action -notin $adapter.documented_dns_actions) { $errors.Add("UNSUPPORTED: action '$($m.action)' for $($c.control) is not a documented DNS action"); continue }
        if ($m.kind -eq 'action') { [pscustomobject]@{ control = $c.control; action = $m.action; selector = $null; ids = @(); entitlement = 'n/a' }; continue }
        $hits = @($disc.categories | Where-Object { $_.name -eq $m.name -and ($(if ($m.kind -eq 'parent_category') { $null -eq $_.parent } else { $_.parent -eq $m.parent })) })
        if ($hits.Count -ne 1) { $errors.Add("UNRESOLVED: $($c.control) -> provider category '$($m.parent)/$($m.name)' matched $($hits.Count) times"); continue }
        if ($hits[0].class -in $adapter.blocked_category_classes) { $errors.Add("UNSUPPORTED: $($c.control) category class '$($hits[0].class)' cannot be blocked"); continue }
        $ent = if ($hits[0].class -in $adapter.entitlement_unverified_classes) { 'UNVERIFIED_PLAN_ENTITLEMENT' } else { 'AVAILABLE' }
        if ($ent -ne 'AVAILABLE') { $warnings.Add("ENTITLEMENT: $($c.control) uses class '$($hits[0].class)'; plan entitlement must be verified before apply") }
        [pscustomobject]@{ control = $c.control; action = $m.action; selector = $m.selector; ids = @([int]$hits[0].id); entitlement = $ent }
    }
    if ($errors.Count) { return [pscustomobject]@{ state = 'FAILED_CLOSED'; errors = $errors.ToArray(); plan = $null } }
    $missing = @($Required.Keys | Where-Object { $_ -notin @($resolved.control) })
    if ($missing) { return [pscustomobject]@{ state = 'FAILED_CLOSED'; errors = @("UNRESOLVED: $($missing -join ',')"); plan = $null } }

    $devices = @($reg.bindings | Where-Object { $_.tenant_id -eq $intent.tenant_id -and $_.binding_type -eq 'device_enrollment' -and $_.status -eq 'ACTIVE' })
    $alias = @($reg.tenants | Where-Object tenant_id -eq $intent.tenant_id)[0].alias
    $group = { param($sel) @($resolved | Where-Object selector -eq $sel) }
    $rules = @(
        [pscustomobject]@{ order = 1; group = 'threats'; layer = 'security_threat_baseline'; action = 'block'
            controls = @((& $group 'dns.security_category').control); traffic = 'any(dns.security_category[*] in {' + (((& $group 'dns.security_category').ids | Sort-Object) -join ' ') + '})' }
        [pscustomobject]@{ order = 2; group = 'content'; layer = 'mandatory_safety_restriction'; action = 'block'
            controls = @((& $group 'dns.content_category').control); traffic = 'any(dns.content_category[*] in {' + (((& $group 'dns.content_category').ids | Sort-Object) -join ' ') + '})' }
        [pscustomobject]@{ order = 3; group = 'safe-search'; layer = 'mandatory_safety_restriction'; action = 'safesearch'; controls = @('search.safe_search'); traffic = 'all_dns_queries_in_scope' }
        [pscustomobject]@{ order = 4; group = 'youtube-restricted'; layer = 'mandatory_safety_restriction'; action = 'ytrestricted'; controls = @('video.youtube_restricted'); traffic = 'all_dns_queries_in_scope' }
    ) | ForEach-Object { $_ | Add-Member -NotePropertyName name -NotePropertyValue ($adapter.rule_naming.Replace('{tenant_alias}', $alias).Replace('{group}', $_.group)) -PassThru }
    $blockers = @()
    if ($devices.Count -eq 0) { $blockers += 'NO_ENROLLED_DEVICE_BINDING: scope resolves to 0 device subjects; no safe selector exists' }
    $blockers += 'SAFE_SELECTOR_NOT_PROVEN: shared Cloudflare account requires a family/device selector proven not to match unrelated SETOK traffic'
    $blockers += 'PROVIDER_MUTATION_NOT_AUTHORIZED: a separate Work Order must authorize Gateway rule creation and rollback'
    if ($warnings.Count) { $blockers += 'PLAN_ENTITLEMENT_UNVERIFIED: verify premium-class category availability on the account plan before apply' }
    $plan = [pscustomobject]@{
        policy_id = $intent.policy_id; tenant_id = $intent.tenant_id; provider = $adapter.adapter; adapter_version = $adapter.adapter_version
        state = 'COMPILED'; apply_status = 'BLOCKED'; apply_blockers = $blockers
        scope = [pscustomobject]@{ requested = 'all_device_subjects_of_tenant'; resolved_device_subjects = $devices.Count; identity_selector = $null; global_rule = $false }
        controls = @($resolved); rules = $rules; warnings = $warnings.ToArray()
    }
    $planJson = $plan | ConvertTo-Json -Depth 12 -Compress
    [pscustomobject]@{ state = 'COMPILED'; errors = @(); plan = $plan; planSha256 = Get-Sha $planJson }
}

# ------------------------------------------------------------ static read-only proof
function Test-StaticReadOnly {
    $src = Get-Content $PSCommandPath -Raw
    $httpWrite = '(?i)-Method\s+(P' + 'OST|P' + 'UT|P' + 'ATCH|D' + 'ELETE)\b'
    $verbs     = '(?i)Invoke-(RestMethod|WebRequest)(?![^\r\n]*-Method\s+Get)'
    [pscustomobject]@{ httpWriteVerbs = ([regex]::Matches($src, $httpWrite)).Count; nonGetHttpCalls = ([regex]::Matches($src, $verbs)).Count }
}

# ------------------------------------------------------------ main
$intent  = Get-Content $intentPath -Raw | ConvertFrom-Json
$adapter = Get-Content $adapterPath -Raw | ConvertFrom-Json
$reg     = Get-Content $regPath -Raw | ConvertFrom-Json
$acct    = @($reg.bindings | Where-Object { $_.binding_type -eq 'integration_account' -and $_.provider -eq 'cloudflare-zero-trust' -and $_.status -eq 'ACTIVE' })[0].external.account_id
$fail = $false

# Discovery (before), compile twice, discovery (after)
$disc1 = Get-Discovery $acct
$c1 = Invoke-Compile $intent $adapter $disc1 $reg
$c2 = Invoke-Compile (Get-Content $intentPath -Raw | ConvertFrom-Json) (Get-Content $adapterPath -Raw | ConvertFrom-Json) (Copy-Deep $disc1) (Get-Content $regPath -Raw | ConvertFrom-Json)
$disc2 = Get-Discovery $acct
$deterministic = ($c1.state -eq 'COMPILED' -and $c1.planSha256 -eq $c2.planSha256)
$fpSame = (($disc1.fingerprint | ConvertTo-Json -Compress) -eq ($disc2.fingerprint | ConvertTo-Json -Compress))
$static = Test-StaticReadOnly
$readOnly = ($fpSame -and $static.httpWriteVerbs -eq 0 -and $static.nonGetHttpCalls -eq 0)

Save-Evidence 'discovery' ([pscustomobject]@{ observedAt = (Get-Date).ToUniversalTime().ToString('o'); account = $acct; categories = $disc1.categories
    preexistingGatewayRules = $disc1.gatewayRules; managedProfile = $disc1.managedProfile; fingerprintBefore = $disc1.fingerprint; fingerprintAfter = $disc2.fingerprint })
Save-Evidence 'compile' ([pscustomobject]@{ run1 = $c1; run2sha256 = $c2.planSha256; deterministic = $deterministic
    inputs = [pscustomobject]@{ intentSha256 = (Get-FileHash $intentPath -Algorithm SHA256).Hash.ToLower(); adapterSha256 = (Get-FileHash $adapterPath -Algorithm SHA256).Hash.ToLower(); registrySha256 = (Get-FileHash $regPath -Algorithm SHA256).Hash.ToLower(); categoriesFingerprint = $disc1.fingerprint.categories } })

# Precedence: legitimate constructs (must PASS) and decision explanations
$constructs = @(
    [pscustomobject]@{ construct = 'standard_mode';      layer = 6; effects = @(@{ target = 'ordinary.social_media'; action = 'ALLOW' }, @{ target = 'ordinary.gaming'; action = 'ALLOW' }) }
    [pscustomobject]@{ construct = 'restricted_mode';    layer = 6; effects = @(@{ target = 'ordinary.social_media'; action = 'BLOCK' }, @{ target = 'ordinary.gaming'; action = 'BLOCK' }) }
    [pscustomobject]@{ construct = 'temporary_override'; layer = 5; effects = @(@{ target = 'ordinary.social_media'; action = 'ALLOW' }) }
    [pscustomobject]@{ construct = 'recurring_schedule'; layer = 7; effects = @(@{ target = 'ordinary.gaming'; action = 'BLOCK' }) }
    [pscustomobject]@{ construct = 'essential_services'; layer = 3; effects = @(); exempt_from = @('ordinary.social_media') }
)
$prec = foreach ($k in $constructs) { $v = Test-Construct $k $intent; [pscustomobject]@{ test = "legitimate $($k.construct)"; expected = 'PASS'; got = $(if ($v.Count) { 'FAIL' } else { 'PASS' }); reasons = $v } }
$decisions = @(
    @{ name = 'essential school domain categorized phishing'; req = @{ categories = @('threat.phishing'); essential = $true }; expect = 'BLOCK/security_threat_baseline' }
    @{ name = 'essential messaging domain during restricted mode'; req = @{ categories = @('ordinary.social_media'); essential = $true }; expect = 'ALLOW/essential_services' }
    @{ name = 'temporary override allows social media'; req = @{ categories = @('ordinary.social_media'); essential = $false }; expect = 'ALLOW/temporary_override' }
    @{ name = 'temporary override cannot reach gambling'; req = @{ categories = @('content.gambling', 'ordinary.social_media'); essential = $false }; expect = 'BLOCK/mandatory_safety_restriction' }
    @{ name = 'malware domain under every construct'; req = @{ categories = @('threat.malware', 'ordinary.social_media'); essential = $true }; expect = 'BLOCK/security_threat_baseline' }
    @{ name = 'C2 domain in essential list'; req = @{ categories = @('threat.command_and_control'); essential = $true }; expect = 'BLOCK/security_threat_baseline' }
)
$dec = foreach ($d in $decisions) { $r = Get-Decision $intent $constructs ([pscustomobject]$d.req); $got = "$($r.decision)/$($r.reason)"; [pscustomobject]@{ test = "decision: $($d.name)"; expected = $d.expect; got = $got } }

# Negative / fail-closed cases (each must FAIL)
$cases = [Collections.Generic.List[object]]::new()
function Add-Case($n, $i = $intent, $a = $adapter, $d = $disc1, $r = $reg, $sc = 'tenant') { $cases.Add([pscustomobject]@{ n = $n; i = $i; a = $a; d = $d; r = $r; sc = $sc }) }
$x = Copy-Deep $intent; $x.controls = @($x.controls | Where-Object control -ne 'threat.malware');                    Add-Case 'mandatory malware control removed' $x
$x = Copy-Deep $intent; ($x.controls | Where-Object control -eq 'threat.phishing').action = 'FORCE';                  Add-Case 'phishing changed from BLOCK' $x
$x = Copy-Deep $adapter; $x.mappings.PSObject.Properties.Remove('threat.command_and_control');                         Add-Case 'C2/botnet adapter mapping missing' -a $x
$x = Copy-Deep $disc1; $x.categories = @($x.categories | Where-Object name -ne 'Gambling');                            Add-Case 'provider category unresolved (gambling absent)' -d $x
$x = Copy-Deep $disc1; ($x.categories | Where-Object name -eq 'Phishing').class = 'noBlock';                            Add-Case 'provider category not blockable' -d $x
$x = Copy-Deep $adapter; $x.documented_dns_actions = @('block', 'safesearch');                                         Add-Case 'YouTube Restricted action unsupported' -a $x
$x = Copy-Deep $intent; $x.controls[0] | Add-Member -NotePropertyName provider_category -NotePropertyValue 117;          Add-Case 'provider ID introduced into domain intent' $x
$x = Copy-Deep $intent; $x.scope = [pscustomobject]@{ applies_to = 'devices'; devices = @('sub_01M5WDGX4ZZZZZZZZZZZZZZZZZ') }; Add-Case 'device scope invented without enrollment' $x
Add-Case 'global/unscoped apply scope requested' -sc 'global'
$x = Copy-Deep $intent; $x.tenant_id = 'tnt_01M5WDGX4YYYYYYYYYYYYYYYYY';                                              Add-Case 'tenant not in provider-binding registry' $x
$x = Copy-Deep $intent; $x.overridable = $true;                                                                         Add-Case 'baseline marked overridable' $x
$negResults = foreach ($k in $cases) { $r = Invoke-Compile $k.i $k.a $k.d $k.r $k.sc; [pscustomobject]@{ test = $k.n; expected = 'FAIL'; got = $(if ($r.state -eq 'COMPILED') { 'PASS' } else { 'FAIL' }); reasons = @($r.errors | Select-Object -First 3) } }
$bad = @(
    @{ n = 'Essential Services attempts to bypass threat baseline'; c = [pscustomobject]@{ construct = 'essential_services'; layer = 3; effects = @(); exempt_from = @('threat.malware', 'threat.phishing') } }
    @{ n = 'temporary override attempts to disable threat baseline'; c = [pscustomobject]@{ construct = 'temporary_override'; layer = 5; effects = @(@{ target = 'threat.command_and_control'; action = 'ALLOW' }); disables_baseline = $true } }
    @{ n = 'Standard mode weakens SafeSearch'; c = [pscustomobject]@{ construct = 'standard_mode'; layer = 6; effects = @(@{ target = 'search.safe_search'; action = 'UNFORCE' }) } }
    @{ n = 'Restricted mode allows adult content'; c = [pscustomobject]@{ construct = 'restricted_mode'; layer = 6; effects = @(@{ target = 'content.adult'; action = 'ALLOW' }) } }
    @{ n = 'recurring schedule disables gambling block'; c = [pscustomobject]@{ construct = 'recurring_schedule'; layer = 7; effects = @(@{ target = 'content.gambling'; action = 'ALLOW' }) } }
    @{ n = 'recurring schedule disables malware block'; c = [pscustomobject]@{ construct = 'recurring_schedule'; layer = 7; effects = @(@{ target = 'threat.malware'; action = 'DISABLE' }) } }
)
$negPrec = foreach ($b in $bad) { $v = Test-Construct $b.c $intent; [pscustomobject]@{ test = $b.n; expected = 'FAIL'; got = $(if ($v.Count) { 'FAIL' } else { 'PASS' }); reasons = $v } }

$tests = @($prec) + @($dec) + @($negResults) + @($negPrec)
$testsOk = -not (@($tests | Where-Object { $_.got -ne $_.expected }).Count)
$precOk = -not (@(@($prec) + @($dec) + @($negPrec) | Where-Object { $_.got -ne $_.expected }).Count)
$failClosedOk = -not (@($negResults | Where-Object { $_.got -ne $_.expected }).Count)
$summary = [pscustomobject]@{
    baselineControls = "$(@($c1.plan.controls).Count)/$($Required.Count)"
    compileState = $c1.state; applyStatus = $c1.plan.apply_status; claimedApplied = $false
    deterministic = $deterministic; precedenceTests = $precOk; failClosedTests = $failClosedOk
    deviceSubjects = @($reg.subjects | Where-Object subject_type -eq 'device').Count
    deviceBindings = @($reg.bindings | Where-Object binding_type -eq 'device_enrollment').Count
    readOnly = [pscustomobject]@{ providerFingerprintsUnchanged = $fpSame; static = $static; pass = $readOnly }
}
Save-Evidence 'tests' ([pscustomobject]@{ observedAt = (Get-Date).ToUniversalTime().ToString('o'); summary = $summary; tests = $tests })

$tests | Format-Table test, expected, got -AutoSize
$c1.plan.rules | Format-Table order, name, action, traffic -AutoSize
$summary | ConvertTo-Json -Depth 4
if (-not ($c1.state -eq 'COMPILED' -and $deterministic -and $testsOk -and $readOnly)) { Write-Error 'ST-POL-001 FAILED'; exit 1 }
'ST-POL-001: PASS (DESIRED / COMPILED / PROVIDER_CAPABILITY_VERIFIED; apply BLOCKED; nothing APPLIED)'
