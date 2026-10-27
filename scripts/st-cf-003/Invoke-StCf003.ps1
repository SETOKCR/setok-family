<#
.SYNOPSIS
  ST-CF-003: read-only safe-selector discovery for android-01 (Story-specific). HTTP GET only.

.DESCRIPTION
  Reuses the exact snapshot/observation functions of scripts/st-dev-001/Invoke-StDev001.ps1 (loaded from its AST)
  so fingerprints are directly comparable with the accepted ST-DEV-001 final snapshot.

  Produces (sanitized; never the real identity, IPs, serials, keys or virtual IPs):
    - accepted android-01 state reconciliation;
    - exact-identity association and cardinality for alias family-enrollment-01;
    - shared-surface fingerprints before and after discovery, compared with the ST-DEV-001 final snapshot;
    - live category/capability matrix for ST-POL-001 and ST-POL-002 controls.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repo       = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$evidence   = Join-Path $repo 'docs\evidence\ST-CF-003'
$regPath    = Join-Path $repo 'infra\bindings\registry.desired.json'
$local      = Join-Path $env:LOCALAPPDATA 'SETOK\setok-family'
$cfToken    = Join-Path $local 'cloudflare-st-cf-001.token.xml'
$mailFile   = Join-Path $local 'st-cf-002-enrollment-mailbox.xml'
$api        = 'https://api.cloudflare.com/client/v4'
$reg        = Get-Content $regPath -Raw | ConvertFrom-Json -DateKind String
$acct       = @($reg.bindings | Where-Object { $_.binding_type -eq 'integration_account' -and $_.provider -eq 'cloudflare-zero-trust' -and $_.status -eq 'ACTIVE' })[0].external.account_id
$managedId  = @($reg.bindings | Where-Object { $_.binding_type -eq 'managed_resource' -and $_.external.profile_name -eq 'SETOK-FAMILY-MANAGED' -and $_.status -eq 'ACTIVE' })[0].external.policy_id
$enroll     = @($reg.bindings | Where-Object { $_.binding_type -eq 'managed_resource' -and $_.external.access_app_type -eq 'warp' -and $_.status -eq 'ACTIVE' })[0]
$devBinding = @($reg.bindings | Where-Object { $_.binding_type -eq 'device_enrollment' -and $_.status -eq 'ACTIVE' })
$devSubject = @($reg.subjects | Where-Object subject_type -eq 'device')

# Load the accepted ST-DEV-001 snapshot functions verbatim (identical hashing semantics).
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

# ---------------------------------------------------------------- 1. accepted state + 7. fingerprints (before)
$before = Get-Snapshot
$obs = Get-DeviceObservation $devBinding[0].external.physical_device_id
$accepted = [ordered]@{
    deviceSubjectIsAndroid01     = ($devSubject.Count -eq 1 -and $devSubject[0].subject_id -eq 'sub_01M5Y0XYAMFT3MXRRJV5MFBY3N' -and $devSubject[0].alias -eq 'android-01')
    bindingIsExpected            = ($devBinding.Count -eq 1 -and $devBinding[0].binding_id -eq 'bnd_01M5ZND7V8TK28E2V23Z4MRFEJ' -and $devBinding[0].target.id -eq 'sub_01M5Y0XYAMFT3MXRRJV5MFBY3N')
    providerIdsExpected          = ($devBinding[0].external.physical_device_id -eq '01a17f4d-0062-19de-b716-1df58125a3d4' -and $devBinding[0].external.registration_id -eq '01a17f4d-0062-19de-b716-1df58125a3d4')
    exactlyOneDevice             = ($obs.physicalDeviceCount -eq 1 -and $obs.registrationCount -eq 1)
    registrationPointsToDevice   = ($obs.registrationId -eq $obs.physicalDeviceId -and $obs.registrationDeviceId -eq $obs.physicalDeviceId)
    android                      = ($obs.device_type -eq 'android')
    approvedModel                = ($obs.model -eq '23090RA98G')
    warp                         = ($obs.registration_type -eq 'warp')
    masque                       = ($obs.tunnel_type -eq 'masque')
    profileSetokFamilyManaged    = ($obs.profile.policy_id -eq $managedId -and $obs.profile.name -eq 'SETOK-FAMILY-MANAGED' -and -not $obs.profile.default)
    activeNotRevoked             = (-not $obs.revoked -and $obs.active_registrations -eq 1)
}

# ---------------------------------------------------------------- 2. exact identity (booleans/counts only)
$mail = [Net.NetworkCredential]::new('', (Import-Clixml $mailFile)).Password.Trim().ToLower()
$phys = @(Read-Get "/accounts/$acct/devices/physical-devices"); $regs = @(Read-Get "/accounts/$acct/devices/registrations")
$users = @(Read-Get "/accounts/$acct/access/users")
$norm = { param($e) $e = "$e".ToLower(); if ($e -match '^([^+@]+)\+[^@]*(@.+)$') { $Matches[1] + $Matches[2] } else { $e } }
$regsForId = @($regs | Where-Object { "$($_.user.email)".ToLower() -eq $mail -and -not $_.revoked_at -and -not $_.deleted_at })
$regsForVariant = @($regs | Where-Object { (& $norm $_.user.email) -eq (& $norm $mail) })
$physForId = @($phys | Where-Object { "$($_.last_seen_user.email)".ToLower() -eq $mail })
$userForId = @($users | Where-Object { "$($_.email)".ToLower() -eq $mail })
$uid = $userForId[0].id
$lsi = if ($uid) { Read-Get "/accounts/$acct/access/users/$uid/last_seen_identity" } else { $null }
$acctName = (Read-Get "/accounts/$acct").name
$identity = [ordered]@{
    alias                                  = 'family-enrollment-01'
    android01RegistrationIdentityMatches   = (@($regs | Where-Object { $_.id -eq $devBinding[0].external.registration_id -and "$($_.user.email)".ToLower() -eq $mail }).Count -eq 1)
    activeRegistrationsForIdentity         = $regsForId.Count
    registrationsForIdentityIncludingPlusVariants = $regsForVariant.Count
    physicalDevicesLastSeenWithIdentity    = $physForId.Count
    accessUsersInOrg                       = $users.Count
    accessUsersWithIdentity                = $userForId.Count
    identityHasGatewaySeat                 = [bool]$userForId[0].gateway_seat
    lastSeenIdentityDeviceSessions         = @($(if ($lsi.device_sessions) { $lsi.device_sessions.PSObject.Properties.Name }))
    lastSeenIdentityIdpType                = $lsi.idp.type
    identityIsCloudflareAccountOwnerAddress = ($acctName.ToLower().StartsWith($mail))
    identityPlannedForMultipleDevices      = 'YES per docs/evidence/ST-CF-002/README.md: enrollment infrastructure "for Android and later iPad Standard enrollment"'
    enrollmentPolicyStillAllowsNewRegistrations = $before.enrollmentAuthorization.includeIsOperationalIdentity
}
Remove-Variable mail

# ---------------------------------------------------------------- 6. capability matrix (live categories)
$cats = @(Read-Get "/accounts/$acct/gateway/categories")
$flat = foreach ($c in $cats) { [pscustomobject]@{ id = $c.id; name = $c.name; parent = $null; class = $c.class }; foreach ($s in @($c.subcategories)) { if ($s) { [pscustomobject]@{ id = $s.id; name = $s.name; parent = $c.name; class = $c.class } } } }
$want = @(
    @{ story = 'ST-POL-001'; control = 'threat.malware'; kind = 'category'; parent = 'Security threats'; name = 'Malware' }
    @{ story = 'ST-POL-001'; control = 'threat.phishing'; kind = 'category'; parent = 'Security threats'; name = 'Phishing' }
    @{ story = 'ST-POL-001'; control = 'threat.command_and_control'; kind = 'category'; parent = 'Security threats'; name = 'Command and Control & Botnet' }
    @{ story = 'ST-POL-001'; control = 'content.adult'; kind = 'parent'; parent = $null; name = 'Adult Themes' }
    @{ story = 'ST-POL-001'; control = 'content.gambling'; kind = 'category'; parent = 'Gambling'; name = 'Gambling' }
    @{ story = 'ST-POL-001'; control = 'search.safe_search'; kind = 'action'; action = 'safesearch'; scope = @{ parent = 'Technology'; name = 'Search Engines' } }
    @{ story = 'ST-POL-001'; control = 'video.youtube_restricted'; kind = 'action'; action = 'ytrestricted' }
    @{ story = 'ST-POL-002'; control = 'social_media'; kind = 'category'; parent = 'Society & Lifestyle'; name = 'Social Networks' }
    @{ story = 'ST-POL-002'; control = 'gaming'; kind = 'category'; parent = 'Entertainment'; name = 'Gaming' }
    @{ story = 'ST-POL-002'; control = 'entertainment_streaming'; kind = 'multi'; parts = @(@{ parent = 'Entertainment'; name = 'Video Streaming' }, @{ parent = 'Entertainment'; name = 'Audio Streaming' }) }
)
$matrix = foreach ($w in $want) {
    $resolve = { param($p, $n) @($flat | Where-Object { $_.name -eq $n -and $_.parent -eq $p }) }
    switch ($w.kind) {
        'action' {
            $note = 'documented Gateway DNS action; no read API lists actions; whether it terminates first-match evaluation is not documented'
            if ($w.scope) { $h = & $resolve $w.scope.parent $w.scope.name; $note += "; scope category '$($w.scope.name)' resolved $($h.Count)x (class $($h.class))" }
            [pscustomobject]@{ story = $w.story; control = $w.control; providerIds = @(); classes = @(); status = 'SUPPORTED'; note = $note }
        }
        'multi' {
            $hs = foreach ($p in $w.parts) { & $resolve $p.parent $p.name }
            $st = if (@($hs).Count -ne 2) { 'MAPPING_AMBIGUOUS' } elseif (@($hs.class) -contains 'premium') { 'ENTITLEMENT_UNVERIFIED' } else { 'SUPPORTED' }
            [pscustomobject]@{ story = $w.story; control = $w.control; providerIds = @($hs.id); classes = @($hs.class | Select-Object -Unique); status = $st; note = 'adapter maps to Video Streaming + Audio Streaming (SETOK interpretation of "entertainment/streaming"); YouTube is in Video Streaming' }
        }
        default {
            $h = if ($w.kind -eq 'parent') { @($flat | Where-Object { $_.name -eq $w.name -and $null -eq $_.parent }) } else { & $resolve $w.parent $w.name }
            $st = if ($h.Count -ne 1) { 'MAPPING_AMBIGUOUS' } elseif ($h[0].class -in 'noBlock', 'removalPending') { 'UNSUPPORTED' } elseif ($h[0].class -eq 'premium') { 'ENTITLEMENT_UNVERIFIED' } else { 'SUPPORTED' }
            [pscustomobject]@{ story = $w.story; control = $w.control; providerIds = @($h.id); classes = @($h.class); status = $st; note = $(if ($st -eq 'ENTITLEMENT_UNVERIFIED') { 'class=premium; account plan not readable (subscriptions 403 with current token)' } else { '' }) }
        }
    }
}
$subs = try { Read-Get "/accounts/$acct/subscriptions"; 'READABLE' } catch { 'FORBIDDEN (token lacks billing read)' }

# ---------------------------------------------------------------- 7. fingerprints (after) and comparison with ST-DEV-001 final
$after = Get-Snapshot
$devFinal = Get-Content (Get-ChildItem (Join-Path $repo 'docs\evidence\ST-DEV-001') -Filter '*-snapshot-final.json' | Sort-Object Name | Select-Object -Last 1) -Raw | ConvertFrom-Json -DateKind String
$cmp = foreach ($k in $before.surfaces.Keys) {
    [pscustomobject]@{ surface = $k; unchangedDuringDiscovery = ($before.surfaces[$k].sha256 -eq $after.surfaces[$k].sha256)
                       unchangedSinceStDev001Final = ($before.surfaces[$k].sha256 -eq $devFinal.surfaces.$k.sha256) }
}
$devCmp = [pscustomobject]@{
    physicalIdsUnchanged = ((@($after.devices.physicalIds) -join ',') -eq (@($devFinal.devices.physicalIds) -join ','))
    registrationIdsUnchanged = ((@($after.devices.registrationIds) -join ',') -eq (@($devFinal.devices.registrationIds) -join ','))
    enrollmentAuthorizationUnchanged = (($before.enrollmentAuthorization | ConvertTo-Json -Compress) -eq ($devFinal.enrollmentAuthorization | ConvertTo-Json -Compress))
}

$src = Get-Content $PSCommandPath -Raw
$writes = ([regex]::Matches($src, '(?i)-Method\s+(P' + 'OST|P' + 'UT|P' + 'ATCH|D' + 'ELETE)\b')).Count

$out = [pscustomobject]@{
    observedAt = (Get-Date).ToUniversalTime().ToString('o')
    acceptedAndroidState = [pscustomobject]$accepted; acceptedMatch = -not (@($accepted.Values) -contains $false)
    deviceObservation = $obs
    identity = [pscustomobject]$identity
    capabilityMatrix = $matrix; subscriptionsEndpoint = $subs
    fingerprints = [pscustomobject]@{ before = $before.surfaces; after = $after.surfaces; comparison = $cmp; devices = $devCmp }
    readOnly = [pscustomobject]@{ staticWriteVerbs = $writes; onlyGetHelper = 'Read-Get (from ST-DEV-001) uses -Method Get' }
}
Save-Evidence 'discovery' $out
$accepted.GetEnumerator() | ForEach-Object { "{0,-30} {1}" -f $_.Key, $_.Value }
$identity.GetEnumerator() | ForEach-Object { "{0,-46} {1}" -f $_.Key, ($_.Value -join ',') }
$matrix | Format-Table story, control, status, @{ n = 'ids'; e = { $_.providerIds -join ' ' } }, @{ n = 'class'; e = { $_.classes -join ',' } } -AutoSize
$cmp | Format-Table -AutoSize
$devCmp | Format-List
"static write verbs: $writes; subscriptions: $subs"
