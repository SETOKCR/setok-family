<#
.SYNOPSIS
  ST-CF-002: Cloudflare device enrollment permission for SETOK Family (Story-specific).

.DESCRIPTION
  Steps:
    Snapshot   read-only (ST-CF-001 token, GET only): sanitized inventory + SHA-256 fingerprints of every shared
               surface. -Label pre|post.
    Plan       read-only: verifies operational inputs exist locally, the write token is active, the existing
               One-time PIN IdP is present, and no warp application exists (else STOP). Prints the delta.
    Apply      the ONLY mutating step: creates one reusable Access allow policy whose single include is the exact
               operational mailbox, then one Access application of type warp with that policy attached and the
               One-time PIN IdP as its only allowed IdP. Idempotent: an existing app/policy is reused only if it
               is provably the SETOK-FAMILY-DEVICE-ENROLLMENT resource; anything else STOPs.
    Reconcile  read-only, run twice: desired vs observed app/policy, identical semantic result required.
    Compare    pre vs post fingerprints; expected delta = +1 warp app, +1 allow policy, nothing else.

  The mailbox and tokens are read from DPAPI files and never printed or written to evidence; reconciliation
  records only whether the include matches the operational identity.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('Snapshot', 'Plan', 'Apply', 'Reconcile', 'Compare')][string]$Step,
    [string]$Label = 'pre'
)

$ErrorActionPreference = 'Stop'
$repo       = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$evidence   = Join-Path $repo 'docs\evidence\ST-CF-002'
$local      = Join-Path $env:LOCALAPPDATA 'SETOK\setok-family'
$readToken  = Join-Path $local 'cloudflare-st-cf-001.token.xml'
$writeToken = Join-Path $local 'cloudflare-st-cf-002.token.xml'
$mailFile   = Join-Path $local 'st-cf-002-enrollment-mailbox.xml'
$reg        = Get-Content (Join-Path $repo 'infra\bindings\registry.desired.json') -Raw | ConvertFrom-Json -DateKind String
$acct       = @($reg.bindings | Where-Object { $_.binding_type -eq 'integration_account' -and $_.provider -eq 'cloudflare-zero-trust' -and $_.status -eq 'ACTIVE' })[0].external.account_id
$managedId  = @($reg.bindings | Where-Object { $_.binding_type -eq 'managed_resource' -and $_.external.profile_name -eq 'SETOK-FAMILY-MANAGED' })[0].external.policy_id
$AppName    = 'SETOK-FAMILY-DEVICE-ENROLLMENT'
$PolicyName = 'SETOK-FAMILY-DEVICE-ENROLLMENT allow family-enrollment-01'
# Cloudflare names every warp application 'Warp Login App' regardless of the requested name, so ownership is
# proven by the registry binding (observed app id + its sole attached managed policy), not by name.
$ProviderWarpName = 'Warp Login App'
$bound = @($reg.bindings | Where-Object { $_.status -eq 'ACTIVE' -and $_.external.access_app_type -eq 'warp' })[0]
$api        = 'https://api.cloudflare.com/client/v4'

function Get-Sha([string]$s) { [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($s))).ToLower() }
function Hash($o) { Get-Sha ($o | ConvertTo-Json -Depth 20 -Compress) }
function Save-Evidence([string]$Name, $Object) {
    New-Item -ItemType Directory -Force $evidence | Out-Null
    $file = Join-Path $evidence ("{0}-{1}.json" -f (Get-Date -Format 'yyyyMMddTHHmmss'), $Name)
    $Object | ConvertTo-Json -Depth 20 | Set-Content $file -Encoding utf8
    Write-Host "Evidence: $($file.Replace("$repo\", ''))"
}
function Read-Get([string]$Path, [string]$TokenFile = $readToken) {
    $r = Invoke-RestMethod -Method Get -Uri "$api$Path" -Authentication Bearer -Token (Import-Clixml $TokenFile)
    if (-not $r.success) { throw "Cloudflare GET $Path failed" }
    if ($r.result -is [array]) {
        $items = @($r.result | Where-Object { $_ })
        if ($r.result_info -and $r.result_info.total_count -gt $items.Count) { throw "GET $Path returned a partial page; refusing partial inventory" }
        return $items
    }
    $r.result
}
# The only write helper in this Story. Restricted to the two Access collection endpoints.
function Invoke-CfCreate([string]$Path, $Body) {
    if ($Path -notin "/accounts/$acct/access/policies", "/accounts/$acct/access/apps") { throw "STOP: write to $Path is not authorized by ST-CF-002" }
    try {
        $r = Invoke-RestMethod -Method Post -Uri "$api$Path" -Authentication Bearer -Token (Import-Clixml $writeToken) -ContentType 'application/json' -Body ($Body | ConvertTo-Json -Depth 10 -Compress)
    } catch { throw "Cloudflare create $Path failed: $($_.ErrorDetails.Message)" }
    if (-not $r.success) { throw "Cloudflare create $Path returned success=false" }
    $r.result
}
function Get-Mailbox { [Net.NetworkCredential]::new('', (Import-Clixml $mailFile)).Password.Trim() }

function Get-Snapshot {
    $rules = Read-Get "/accounts/$acct/gateway/rules"; $lists = Read-Get "/accounts/$acct/gateway/lists"
    $gw = Read-Get "/accounts/$acct/gateway/configuration"; $ds = Read-Get "/accounts/$acct/devices/settings"
    $default = Read-Get "/accounts/$acct/devices/policy"; $profiles = Read-Get "/accounts/$acct/devices/policies"
    $managed = @($profiles | Where-Object policy_id -eq $managedId)
    $org = Read-Get "/accounts/$acct/access/organizations"; $idps = Read-Get "/accounts/$acct/access/identity_providers"
    $apps = Read-Get "/accounts/$acct/access/apps"; $pols = Read-Get "/accounts/$acct/access/policies"
    $svc = Read-Get "/accounts/$acct/access/service_tokens"; $posture = Read-Get "/accounts/$acct/devices/posture"
    $phys = Read-Get "/accounts/$acct/devices/physical-devices"; $regs = Read-Get "/accounts/$acct/devices/registrations"
    $groups = Read-Get "/accounts/$acct/access/groups"
    $ours = { param($x) $x.name -eq $PolicyName -or ($bound -and $x.id -eq $bound.external.access_app_id) }
    [pscustomobject]@{
        observedAt = (Get-Date).ToUniversalTime().ToString('o'); account = $acct
        surfaces = [ordered]@{
            gatewayRules      = [pscustomobject]@{ count = @($rules).Count; sha256 = Hash ($rules | Sort-Object id) }
            gatewayLists      = [pscustomobject]@{ count = @($lists).Count; sha256 = Hash ($lists | Sort-Object id) }
            gatewayConfig     = [pscustomobject]@{ sha256 = Hash $gw }
            deviceSettings    = [pscustomobject]@{ sha256 = Hash $ds }
            defaultProfile    = [pscustomobject]@{ policy_id = $default.policy_id; sha256 = Hash $default }
            managedProfile    = [pscustomobject]@{ policy_id = $managedId; found = $managed.Count; match = $managed[0].match; sha256 = Hash $managed }
            allDeviceProfiles = [pscustomobject]@{ count = @($profiles).Count; sha256 = Hash ($profiles | Sort-Object policy_id) }
            accessOrganization = [pscustomobject]@{ auth_domain = $org.auth_domain; sha256 = Hash ($org | Select-Object * -ExcludeProperty updated_at) }
            identityProviders = [pscustomobject]@{ count = @($idps).Count; types = @($idps.type | Sort-Object); sha256 = Hash ($idps | Sort-Object id) }
            accessGroups      = [pscustomobject]@{ count = @($groups).Count; sha256 = Hash ($groups | Sort-Object id) }
            serviceTokens     = [pscustomobject]@{ count = @($svc).Count; sha256 = Hash ($svc | Sort-Object id) }
            postureRules      = [pscustomobject]@{ count = @($posture).Count; sha256 = Hash ($posture | Sort-Object id) }
            physicalDevices   = [pscustomobject]@{ count = @($phys).Count; sha256 = Hash (@($phys) | Sort-Object id | Select-Object id, created_at) }
            registrations     = [pscustomobject]@{ count = @($regs).Count; sha256 = Hash (@($regs) | Sort-Object id | Select-Object id, created_at) }
            unrelatedAccessApps     = [pscustomobject]@{ count = @($apps | Where-Object { -not (& $ours $_) }).Count; sha256 = Hash (@($apps | Where-Object { -not (& $ours $_) }) | Sort-Object id) }
            unrelatedAccessPolicies = [pscustomobject]@{ count = @($pols | Where-Object { -not (& $ours $_) }).Count; sha256 = Hash (@($pols | Where-Object { -not (& $ours $_) }) | Sort-Object id) }
        }
        access = [pscustomobject]@{
            apps = @($apps | Sort-Object id | ForEach-Object { [pscustomobject]@{ id = $_.id; name = $_.name; type = $_.type } })
            warpApps = @($apps | Where-Object type -eq 'warp').Count
            policies = @($pols | Sort-Object id | ForEach-Object { [pscustomobject]@{ id = $_.id; name = $_.name; decision = $_.decision; includeCount = @($_.include).Count } })
        }
    }
}

function Get-Observed {
    $mail = Get-Mailbox
    $apps = @(Read-Get "/accounts/$acct/access/apps" | Where-Object type -eq 'warp')
    $pols = @(Read-Get "/accounts/$acct/access/policies" | Where-Object name -eq $PolicyName)
    $otp  = @(Read-Get "/accounts/$acct/access/identity_providers" | Where-Object type -eq 'onetimepin')
    $app  = $apps[0]
    $appDetail = if ($app) { Read-Get "/accounts/$acct/access/apps/$($app.id)" } else { $null }
    $pol  = $pols[0]
    $inc  = @($pol.include)
    $attached = @($appDetail.policies)
    $r = [pscustomobject]@{
        warpAppCount = $apps.Count; appId = $app.id; appName = $app.name; appType = $app.type
        appAllowedIdps = @($appDetail.allowed_idps | Sort-Object); otpIdpId = $otp[0].id
        policyCountByName = $pols.Count; policyId = $pol.id; policyDecision = $pol.decision
        includeCount = $inc.Count; includeKinds = @($inc | ForEach-Object { $_.PSObject.Properties.Name } | Sort-Object)
        includeMatchesOperationalIdentity = ($inc.Count -eq 1 -and "$($inc[0].email.email)".ToLower() -eq $mail.ToLower())
        requireCount = @($pol.require).Count; excludeCount = @($pol.exclude).Count
        attachedPolicyIds = @($attached.id | Sort-Object)
    }
    Remove-Variable mail
    $r
}
function Test-Observed($o) {
    [ordered]@{
        exactlyOneWarpApp          = ($o.warpAppCount -eq 1)
        appNameProviderFixed       = ($o.appName -eq $ProviderWarpName)
        appIsRegistryBound         = [bool]($bound -and $o.appId -eq $bound.external.access_app_id -and $o.policyId -eq $bound.external.access_policy_id)
        appTypeIsWarp              = ($o.appType -eq 'warp')
        appUsesOnlyOneTimePin      = ((@($o.appAllowedIdps) -join ',') -eq "$($o.otpIdpId)")
        exactlyOneManagedPolicy    = ($o.policyCountByName -eq 1)
        policyDecisionAllow        = ($o.policyDecision -eq 'allow')
        includeCardinalityOne      = ($o.includeCount -eq 1)
        includeIsExactEmail        = ((@($o.includeKinds) -join ',') -eq 'email')
        includeIsOperationalIdentity = [bool]$o.includeMatchesOperationalIdentity
        noRequireOrExclude         = ($o.requireCount -eq 0 -and $o.excludeCount -eq 0)
        policyAttachedOnlyToApp    = ((@($o.attachedPolicyIds) -join ',') -eq "$($o.policyId)")
    }
}

switch ($Step) {
    'Snapshot' {
        $s = Get-Snapshot
        Save-Evidence "snapshot-$Label" $s
        $s.surfaces.GetEnumerator() | ForEach-Object { "{0,-24} {1}" -f $_.Key, (($_.Value | Select-Object * -ExcludeProperty sha256 | ConvertTo-Json -Compress)) }
        "access apps: $(@($s.access.apps).Count) (warp: $($s.access.warpApps)); access policies: $(@($s.access.policies).Count)"
    }
    'Plan' {
        $checks = [ordered]@{}
        $checks.mailboxStoredLocally = Test-Path $mailFile
        $checks.writeTokenStoredLocally = Test-Path $writeToken
        if ($checks.mailboxStoredLocally) { $m = Get-Mailbox; $checks.mailboxIsSingleExactAddress = ($m -match '^[^@\s,;*]+@[^@\s,;*]+\.[A-Za-z]{2,}$'); Remove-Variable m }
        if ($checks.writeTokenStoredLocally) {
            $v = Read-Get "/accounts/$acct/tokens/verify" $writeToken; $checks.writeTokenActive = ($v.status -eq 'active'); $checks.writeTokenExpiresOn = $v.expires_on
            $checks.writeTokenDistinctFromStCf001 = ([Net.NetworkCredential]::new('', (Import-Clixml $writeToken)).Password -ne [Net.NetworkCredential]::new('', (Import-Clixml $readToken)).Password)
        }
        $s = Get-Snapshot
        $checks.noWarpApp = ($s.access.warpApps -eq 0)
        $checks.noManagedPolicyYet = (@($s.access.policies | Where-Object name -eq $PolicyName).Count -eq 0)
        $checks.oneTimePinIdpPresent = ('onetimepin' -in @($s.surfaces.identityProviders.types))
        $checks.serviceTokens = $s.surfaces.serviceTokens.count
        $plan = [pscustomobject]@{ checks = $checks
            delta = @("+1 Access policy '$PolicyName' decision=allow include=[email: <family-enrollment-01>]", "+1 Access application '$AppName' type=warp allowed_idps=[One-time PIN] policies=[that policy]")
            forbidden = 'Gateway, device profiles, IdPs, service tokens, posture rules, devices, registrations, unrelated Access resources'
            rollback = 'DELETE /access/apps/{observed app id}; DELETE /access/policies/{observed policy id}; re-snapshot and compare with pre' }
        Save-Evidence 'plan' $plan
        $checks | Format-Table -AutoSize
        $plan.delta
        $blocking = @('mailboxStoredLocally', 'writeTokenStoredLocally', 'mailboxIsSingleExactAddress', 'writeTokenActive', 'writeTokenDistinctFromStCf001', 'noWarpApp', 'oneTimePinIdpPresent') | Where-Object { -not $checks[$_] }
        if ($blocking) { Write-Error "PLAN NOT READY: $($blocking -join ', ')"; exit 1 }
        'PLAN READY'
    }
    'Apply' {
        $s = Get-Snapshot
        $warp = @(Read-Get "/accounts/$acct/access/apps" | Where-Object type -eq 'warp')
        if ($warp.Count -gt 1 -or ($warp.Count -eq 1 -and -not ($bound -and $warp[0].id -eq $bound.external.access_app_id))) { throw 'STOP: a warp application exists that is not the registry-bound SETOK Family managed resource' }
        $otp = @(Read-Get "/accounts/$acct/access/identity_providers" | Where-Object type -eq 'onetimepin')
        if ($otp.Count -ne 1) { throw 'STOP: exactly one One-time PIN IdP expected' }
        $mail = Get-Mailbox
        $pol = @(Read-Get "/accounts/$acct/access/policies" | Where-Object name -eq $PolicyName)
        $actions = @()
        if ($pol.Count -gt 1) { throw 'STOP: more than one managed policy with the same name' }
        if ($pol.Count -eq 0) {
            $p = Invoke-CfCreate "/accounts/$acct/access/policies" @{ name = $PolicyName; decision = 'allow'; include = @(@{ email = @{ email = $mail } }); exclude = @(); require = @() }
            $actions += 'CREATE policy'; $polId = $p.id
        } else {
            if (@($pol[0].include).Count -ne 1 -or "$($pol[0].include[0].email.email)".ToLower() -ne $mail.ToLower() -or $pol[0].decision -ne 'allow') { throw 'STOP: existing managed policy differs from desired state' }
            $actions += 'NONE policy'; $polId = $pol[0].id
        }
        Remove-Variable mail
        if ($warp.Count -eq 0) {
            try {
                $a = Invoke-CfCreate "/accounts/$acct/access/apps" @{ name = $AppName; type = 'warp'; allowed_idps = @($otp[0].id); auto_redirect_to_identity = $false; policies = @(@{ id = $polId; precedence = 1 }) }
                $actions += 'CREATE warp app'
            } catch {
                Save-Evidence 'apply-failed' ([pscustomobject]@{ actions = $actions; policyId = $polId; error = "$_" -replace '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}', '<redacted-email>' })
                throw "App creation failed after policy creation; policy $polId remains (rollback: DELETE /access/policies/$polId). $_"
            }
        } else { $actions += 'NONE warp app (already the managed resource)' }
        $o = Get-Observed
        Save-Evidence 'apply' ([pscustomobject]@{ actions = $actions; observed = $o; checks = (Test-Observed $o) })
        $actions; (Test-Observed $o) | Format-Table -AutoSize
    }
    'Reconcile' {
        $runs = foreach ($n in 1, 2) { $o = Get-Observed; [pscustomobject]@{ run = $n; observed = $o; checks = (Test-Observed $o) } }
        $same = (($runs[0] | Select-Object observed, checks | ConvertTo-Json -Depth 10 -Compress) -eq ($runs[1] | Select-Object observed, checks | ConvertTo-Json -Depth 10 -Compress))
        $match = -not (@($runs.checks | ForEach-Object { $_.Values }) -contains $false)
        Save-Evidence 'reconcile' ([pscustomobject]@{ runs = $runs; deterministic = $same; verdict = $(if ($match) { 'MATCH' } else { 'DRIFT' }) })
        $runs[1].checks | Format-Table -AutoSize
        "verdict: $(if ($match) { 'MATCH' } else { 'DRIFT' }); deterministic: $same"
        if (-not ($match -and $same)) { exit 1 }
    }
    'Compare' {
        $find = { param($l) Get-ChildItem $evidence -Filter "*-snapshot-$l.json" | Sort-Object Name | Select-Object -Last 1 }
        $a = Get-Content (& $find 'pre') -Raw | ConvertFrom-Json -DateKind String
        $b = Get-Content (& $find 'post') -Raw | ConvertFrom-Json -DateKind String
        $rows = foreach ($p in $a.surfaces.PSObject.Properties.Name) { [pscustomobject]@{ surface = $p; unchanged = ($a.surfaces.$p.sha256 -eq $b.surfaces.$p.sha256); countBefore = $a.surfaces.$p.count; countAfter = $b.surfaces.$p.count } }
        $newApps = @($b.access.apps | Where-Object { $_.id -notin @($a.access.apps.id) })
        $newPols = @($b.access.policies | Where-Object { $_.id -notin @($a.access.policies.id) })
        $gone = @($a.access.apps | Where-Object { $_.id -notin @($b.access.apps.id) }) + @($a.access.policies | Where-Object { $_.id -notin @($b.access.policies.id) })
        $expected = ($newApps.Count -eq 1 -and $newApps[0].type -eq 'warp' -and $newPols.Count -eq 1 -and $newPols[0].decision -eq 'allow' -and $gone.Count -eq 0 -and -not ($rows.unchanged -contains $false))
        Save-Evidence 'compare-pre-post' ([pscustomobject]@{ surfaces = $rows; newAccessApps = $newApps; newAccessPolicies = $newPols; removedAccessObjects = $gone; deltaAsExpected = $expected })
        $rows | Format-Table -AutoSize
        "new apps: $($newApps.Count) ($($newApps.type -join ',')); new policies: $($newPols.Count) ($($newPols.decision -join ',')); removed: $($gone.Count); delta as expected: $expected"
        if (-not $expected) { exit 1 }
    }
}
