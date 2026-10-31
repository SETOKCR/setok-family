<#
.SYNOPSIS
  ST-CF-004 Stage B: enrollment authorization transition (Story-specific).

.DESCRIPTION
  Steps:
    Plan      read-only. Verifies the write token, captures the PRE snapshot (ST-DEV-001 functions), stores the exact
              PRE policy locally (DPAPI, never in Git, because it contains the shared identity) for rollback.
    Apply     the ONLY mutating step: one PUT to the existing registry-bound WARP enrollment policy, replacing its
              single include with the exact dedicated identity (alias android-01-enrollment). Every other policy
              field is sent back unchanged. Nothing else is written.
    Verify    read-only POST snapshot + the 21 Stage B assertions; on failure exits non-zero.
    Rollback  PUT of the exact PRE policy, then verification that the authorization matches PRE.

  Reads use the ST-CF-001 token (GET only). The single write helper refuses any path other than the registry-bound
  enrollment policy and uses the short-lived ST-CF-004 token.
#>
[CmdletBinding()]
param([Parameter(Mandatory)][ValidateSet('Plan', 'Apply', 'Verify', 'Rollback')][string]$Step)

$ErrorActionPreference = 'Stop'
$repo       = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$evidence   = Join-Path $repo 'docs\evidence\ST-CF-004'
$regPath    = Join-Path $repo 'infra\bindings\registry.desired.json'
$local      = Join-Path $env:LOCALAPPDATA 'SETOK\setok-family'
$cfToken    = Join-Path $local 'cloudflare-st-cf-001.token.xml'
$writeToken = Join-Path $local 'cloudflare-st-cf-004.token.xml'
$mailFile   = Join-Path $local 'st-cf-002-enrollment-mailbox.xml'
$dedFile    = Join-Path $local 'st-cf-004-android-01-enrollment.xml'
$preFile    = Join-Path $local 'st-cf-004-stage-b-pre-policy.xml'
$api        = 'https://api.cloudflare.com/client/v4'
$reg        = Get-Content $regPath -Raw | ConvertFrom-Json -DateKind String
$acct       = @($reg.bindings | Where-Object { $_.binding_type -eq 'integration_account' -and $_.provider -eq 'cloudflare-zero-trust' -and $_.status -eq 'ACTIVE' })[0].external.account_id
$managedId  = @($reg.bindings | Where-Object { $_.binding_type -eq 'managed_resource' -and $_.external.profile_name -eq 'SETOK-FAMILY-MANAGED' -and $_.status -eq 'ACTIVE' })[0].external.policy_id
$enroll     = @($reg.bindings | Where-Object { $_.binding_type -eq 'managed_resource' -and $_.external.access_app_type -eq 'warp' -and $_.status -eq 'ACTIVE' })[0]
$devBinding = @($reg.bindings | Where-Object { $_.binding_type -eq 'device_enrollment' -and $_.status -eq 'ACTIVE' })
$policyPath = "/accounts/$acct/access/policies/$($enroll.external.access_policy_id)"

$ast = [System.Management.Automation.Language.Parser]::ParseFile((Join-Path $repo 'scripts\st-dev-001\Invoke-StDev001.ps1'), [ref]$null, [ref]$null)
foreach ($f in $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -in 'Get-Sha', 'Hash', 'Read-Get', 'Get-Snapshot', 'Get-DeviceObservation' }, $true)) {
    . ([scriptblock]::Create($f.Extent.Text))
}
function Save-Evidence([string]$Name, $Object) {
    New-Item -ItemType Directory -Force $evidence | Out-Null
    $file = Join-Path $evidence ("{0}-{1}.json" -f (Get-Date -Format 'yyyyMMddTHHmmss'), $Name)
    $Object | ConvertTo-Json -Depth 20 | Set-Content $file -Encoding utf8
    Write-Host "Evidence: $($file.Replace("$repo\", ''))"
}
function Get-Secret([string]$f) { [Net.NetworkCredential]::new('', (Import-Clixml $f)).Password.Trim() }
function Norm([string]$e) { $e = "$e".ToLower(); if ($e -match '^([^+@]+)\+[^@]*(@.+)$') { $Matches[1] + $Matches[2] } else { $e } }

# The only write helper of Stage B: full replacement of the one registry-bound enrollment policy.
function Invoke-PolicyPut($Body) {
    try {
        $r = Invoke-RestMethod -Method Put -Uri "$api$policyPath" -Authentication Bearer -Token (Import-Clixml $writeToken) -ContentType 'application/json' -Body ($Body | ConvertTo-Json -Depth 10 -Compress)
    } catch { throw "Policy update failed: $(("$($_.ErrorDetails.Message)") -replace '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}', '<redacted-email>')" }
    if (-not $r.success) { throw 'Policy update returned success=false' }
    $r.result
}
# Settable fields of a reusable Access policy, copied from the observed object so nothing else changes.
function Get-PolicyBody($p, $include) {
    $b = [ordered]@{ name = $p.name; decision = $p.decision; include = $include; exclude = @($p.exclude); require = @($p.require) }
    foreach ($k in 'session_duration', 'approval_required', 'approval_groups', 'isolation_required', 'purpose_justification_required', 'purpose_justification_prompt', 'connection_rules', 'mfa_config') {
        if ($p.PSObject.Properties.Name -contains $k -and $null -ne $p.$k) { $b[$k] = $p.$k }
    }
    $b
}
function Get-Authorization {
    $ded = Norm (Get-Secret $dedFile); $shared = Norm (Get-Secret $mailFile)
    $apps = @(Read-Get "/accounts/$acct/access/apps"); $warp = @($apps | Where-Object type -eq 'warp')
    $app = if ($warp.Count -eq 1) { Read-Get "/accounts/$acct/access/apps/$($warp[0].id)" } else { $null }
    $pol = Read-Get $policyPath
    $otp = @(Read-Get "/accounts/$acct/access/identity_providers" | Where-Object type -eq 'onetimepin')
    $inc = @($pol.include)
    $r = [ordered]@{
        warpAppCount = $warp.Count; warpAppId = $warp[0].id
        attachedPolicyIds = @($app.policies.id | Sort-Object); allowedIdps = @($app.allowed_idps | Sort-Object); oneTimePinIdpId = $otp[0].id
        policyId = $pol.id; policyDecision = $pol.decision; includeCount = $inc.Count
        includeKinds = @($inc | ForEach-Object { $_.PSObject.Properties.Name } | Sort-Object -Unique)
        dedicatedPermitted = [bool](@($inc | Where-Object { (Norm $_.email.email) -eq $ded }).Count)
        sharedPermitted = [bool](@($inc | Where-Object { (Norm $_.email.email) -eq $shared }).Count)
        requireCount = @($pol.require).Count; excludeCount = @($pol.exclude).Count
        policyOtherFieldsSha256 = Hash ($pol | Select-Object * -ExcludeProperty include, updated_at, created_at)
        appOtherFieldsSha256 = Hash ($app | Select-Object * -ExcludeProperty policies, updated_at)
    }
    Remove-Variable ded, shared
    [pscustomobject]$r
}

switch ($Step) {
    'Plan' {
        if (-not (Test-Path $writeToken)) { Write-Error 'STOP: ST-CF-004 write token not stored (run Set-StCf004Token.ps1)'; exit 1 }
        # The token may be user-owned or account-owned; each is verified at its own endpoint.
        $vw = try { Invoke-RestMethod -Method Get -Uri "$api/user/tokens/verify" -Authentication Bearer -Token (Import-Clixml $writeToken) } catch { Invoke-RestMethod -Method Get -Uri "$api/accounts/$acct/tokens/verify" -Authentication Bearer -Token (Import-Clixml $writeToken) }
        $pre = Get-Snapshot
        $auth = Get-Authorization
        $pol = Read-Get $policyPath
        ConvertTo-SecureString ($pol | ConvertTo-Json -Depth 10 -Compress) -AsPlainText -Force | Export-Clixml $preFile
        $checks = [ordered]@{
            writeTokenActive = ($vw.result.status -eq 'active'); writeTokenExpiresOn = $vw.result.expires_on
            exactlyOneWarpApp = ($auth.warpAppCount -eq 1 -and $auth.warpAppId -eq $enroll.external.access_app_id)
            onlyRegistryPolicyAttached = ((@($auth.attachedPolicyIds) -join ',') -eq $enroll.external.access_policy_id)
            onlyOneTimePin = ((@($auth.allowedIdps) -join ',') -eq "$($auth.oneTimePinIdpId)")
            policyAllow = ($auth.policyDecision -eq 'allow'); includeCardinalityOne = ($auth.includeCount -eq 1)
            sharedCurrentlyPermitted = $auth.sharedPermitted; dedicatedNotYetPermitted = (-not $auth.dedicatedPermitted)
            noRequireOrExclude = ($auth.requireCount -eq 0 -and $auth.excludeCount -eq 0)
            prePolicyStoredLocallyForRollback = (Test-Path $preFile)
        }
        Save-Evidence 'stage-b-plan' ([pscustomobject]@{ observedAt = (Get-Date).ToUniversalTime().ToString('o'); checks = $checks; authorizationPre = $auth; preSurfaces = $pre.surfaces
            preDevices = $pre.devices; registrySha256 = (Get-FileHash $regPath -Algorithm SHA256).Hash.ToLower()
            delta = 'PUT ' + $policyPath + ' : include [email:<family-enrollment-01>] -> [email:<android-01-enrollment>]; all other fields unchanged' })
        $checks | Format-Table -AutoSize
        $bad = @($checks.Keys | Where-Object { $checks[$_] -eq $false })
        if ($bad) { Write-Error "PLAN NOT READY: $($bad -join ', ')"; exit 1 }
        'PLAN READY'
    }
    'Apply' {
        if (-not (Test-Path $preFile)) { throw 'STOP: run -Step Plan first (PRE policy not stored)' }
        $auth = Get-Authorization
        if ($auth.dedicatedPermitted -and -not $auth.sharedPermitted -and $auth.includeCount -eq 1) { 'NONE: dedicated identity already the sole include'; break }
        if (-not ($auth.sharedPermitted -and $auth.includeCount -eq 1 -and $auth.warpAppCount -eq 1)) { throw 'STOP: current authorization differs from the planned PRE state' }
        $pol = Read-Get $policyPath
        $ded = Get-Secret $dedFile
        $res = Invoke-PolicyPut (Get-PolicyBody $pol @(@{ email = @{ email = $ded } }))
        Remove-Variable ded
        Save-Evidence 'stage-b-apply' ([pscustomobject]@{ observedAt = (Get-Date).ToUniversalTime().ToString('o'); action = 'UPDATE enrollment policy include (single PUT)'; policyId = $res.id; authorizationPost = (Get-Authorization) })
        "UPDATED policy $($res.id)"
    }
    'Verify' {
        $plan = Get-Content (Get-ChildItem $evidence -Filter '*-stage-b-plan.json' | Sort-Object Name | Select-Object -Last 1) -Raw | ConvertFrom-Json -DateKind String
        $post = Get-Snapshot
        $a = Get-Authorization
        $obs = Get-DeviceObservation '01a17f4d-0062-19de-b716-1df58125a3d4'
        $expectChanged = @('accessPolicies', 'enrollmentApp')
        $surf = foreach ($k in $post.surfaces.Keys) { [pscustomobject]@{ surface = $k; unchanged = ($plan.preSurfaces.$k.sha256 -eq $post.surfaces[$k].sha256); expectedToChange = ($k -in $expectChanged) } }
        $u = { param($n) @($surf | Where-Object surface -eq $n)[0].unchanged }
        $c = [ordered]@{
            '01 warpEnrollmentAppIdUnchanged'     = ($a.warpAppId -eq $plan.authorizationPre.warpAppId -and $a.warpAppCount -eq 1)
            '02 exactlyOneEnrollmentPolicyAttached' = ((@($a.attachedPolicyIds) -join ',') -eq $plan.authorizationPre.policyId)
            '03 policyDecisionAllow'              = ($a.policyDecision -eq 'allow')
            '04 includeCardinalityOne'            = ($a.includeCount -eq 1)
            '05 includeIsExactEmail'              = ((@($a.includeKinds) -join ',') -eq 'email')
            '06 dedicatedIdentityPermitted'       = $a.dedicatedPermitted
            '07 previousSharedIdentityNotPermitted' = (-not $a.sharedPermitted)
            '08 oneTimePinOnlyAllowedIdp'         = ((@($a.allowedIdps) -join ',') -eq "$($a.oneTimePinIdpId)" -and (@($a.allowedIdps) -join ',') -eq (@($plan.authorizationPre.allowedIdps) -join ','))
            '09 noRequireExcludeExpansion'        = ($a.requireCount -eq $plan.authorizationPre.requireCount -and $a.excludeCount -eq $plan.authorizationPre.excludeCount)
            '09b policyOtherFieldsUnchanged'      = ($a.policyOtherFieldsSha256 -eq $plan.authorizationPre.policyOtherFieldsSha256)
            '09c appOtherFieldsUnchanged'         = ($a.appOtherFieldsSha256 -eq $plan.authorizationPre.appOtherFieldsSha256)
            '10 androidDeviceAndRegistrationUnchanged' = ($obs.physicalDeviceId -eq '01a17f4d-0062-19de-b716-1df58125a3d4' -and $obs.registrationId -eq '01a17f4d-0062-19de-b716-1df58125a3d4' -and -not $obs.revoked -and $obs.profile.policy_id -eq $managedId -and $obs.tunnel_type -eq 'masque')
            '11 noNewDeviceOrRegistration'        = ((@($post.devices.physicalIds) -join ',') -eq (@($plan.preDevices.physicalIds) -join ',') -and (@($post.devices.registrationIds) -join ',') -eq (@($plan.preDevices.registrationIds) -join ','))
            '12 setokBindingUnchanged'            = ((Get-FileHash $regPath -Algorithm SHA256).Hash.ToLower() -eq $plan.registrySha256 -and $devBinding[0].binding_id -eq 'bnd_01M5ZND7V8TK28E2V23Z4MRFEJ')
            '13 gatewayUnchanged'                 = ((& $u 'gatewayRules') -and (& $u 'gatewayLists') -and (& $u 'gatewayConfig'))
            '14 defaultAndManagedProfilesUnchanged' = ((& $u 'defaultProfile') -and (& $u 'managedProfile'))
            '15 allDeviceProfilesUnchanged'       = (& $u 'allDeviceProfiles')
            '16 accessOrganizationUnchanged'      = (& $u 'accessOrganization')
            '17 identityProvidersUnchanged'       = (& $u 'identityProviders')
            '18 unrelatedAccessAppsUnchanged'     = ((& $u 'accessApps') -or ($a.warpAppCount -eq 1 -and $post.surfaces['accessApps'].count -eq $plan.preSurfaces.accessApps.count -and $post.surfaces['accessApps'].count -eq 1))
            '19 accessGroupsUnchanged'            = (& $u 'accessGroups')
            '20 serviceTokensUnchanged'           = (& $u 'serviceTokens')
            '21 postureRulesUnchanged'            = (& $u 'postureRules')
            'deviceSettingsUnchanged'             = (& $u 'deviceSettings')
            'noFamilyGatewayEnforcement'          = (@(Read-Get "/accounts/$acct/gateway/rules" | Where-Object { $_.name -like 'SETOK-FAMILY*' }).Count -eq 0)
        }
        $failed = @($c.Keys | Where-Object { -not $c[$_] })
        Save-Evidence 'stage-b-verify' ([pscustomobject]@{ observedAt = (Get-Date).ToUniversalTime().ToString('o'); checks = $c; authorizationPost = $a; surfaces = $surf; postSurfaces = $post.surfaces
            device = $obs; decision = $(if ($failed) { 'STOP' } else { 'PASS' }); failed = $failed })
        $c.GetEnumerator() | ForEach-Object { "{0,-42} {1}" -f $_.Key, $_.Value }
        $surf | Format-Table -AutoSize
        if ($failed) { Write-Error "STAGE B VERIFY FAILED: $($failed -join ', ')"; exit 1 }
        'STAGE B VERIFY: PASS'
    }
    'Rollback' {
        $pre = [Net.NetworkCredential]::new('', (Import-Clixml $preFile)).Password | ConvertFrom-Json -DateKind String
        $res = Invoke-PolicyPut (Get-PolicyBody $pre @($pre.include))
        $a = Get-Authorization
        $ok = ($a.sharedPermitted -and -not $a.dedicatedPermitted -and $a.includeCount -eq @($pre.include).Count)
        Save-Evidence 'stage-b-rollback' ([pscustomobject]@{ observedAt = (Get-Date).ToUniversalTime().ToString('o'); restoredPolicyId = $res.id; authorization = $a; restoredToPre = $ok })
        "rollback restored to PRE: $ok"
    }
}
