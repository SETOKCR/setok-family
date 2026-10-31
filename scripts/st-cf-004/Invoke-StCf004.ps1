<#
.SYNOPSIS
  ST-CF-004 Stage A: read-only preflight for the dedicated android-01 enrollment identity. HTTP GET only.

.DESCRIPTION
  Reuses the accepted ST-DEV-001 snapshot/observation functions verbatim (loaded from its AST), so fingerprints
  are comparable with ST-DEV-001 and ST-CF-003 evidence.

  Checks: accepted android-01 state; dedicated identity (alias android-01-enrollment) has 0 devices/registrations,
  0 bindings and is not the account owner, the current shared enrollment identity, a plus address or an existing
  Access user with devices; shared-surface fingerprints and drift versus ST-CF-003; no family Gateway enforcement.
  Evidence holds booleans/counts only, never the identity value, IPs, serials, keys or virtual IPs.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repo       = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$evidence   = Join-Path $repo 'docs\evidence\ST-CF-004'
$regPath    = Join-Path $repo 'infra\bindings\registry.desired.json'
$local      = Join-Path $env:LOCALAPPDATA 'SETOK\setok-family'
$cfToken    = Join-Path $local 'cloudflare-st-cf-001.token.xml'
$mailFile   = Join-Path $local 'st-cf-002-enrollment-mailbox.xml'          # current shared enrollment identity
$dedFile    = Join-Path $local 'st-cf-004-android-01-enrollment.xml'      # dedicated identity (Stage A input)
$api        = 'https://api.cloudflare.com/client/v4'
$reg        = Get-Content $regPath -Raw | ConvertFrom-Json -DateKind String
$acct       = @($reg.bindings | Where-Object { $_.binding_type -eq 'integration_account' -and $_.provider -eq 'cloudflare-zero-trust' -and $_.status -eq 'ACTIVE' })[0].external.account_id
$managedId  = @($reg.bindings | Where-Object { $_.binding_type -eq 'managed_resource' -and $_.external.profile_name -eq 'SETOK-FAMILY-MANAGED' -and $_.status -eq 'ACTIVE' })[0].external.policy_id
$enroll     = @($reg.bindings | Where-Object { $_.binding_type -eq 'managed_resource' -and $_.external.access_app_type -eq 'warp' -and $_.status -eq 'ACTIVE' })[0]
$devBinding = @($reg.bindings | Where-Object { $_.binding_type -eq 'device_enrollment' -and $_.status -eq 'ACTIVE' })
$devSubject = @($reg.subjects | Where-Object subject_type -eq 'device')

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

$before = Get-Snapshot
$obs = Get-DeviceObservation $devBinding[0].external.physical_device_id
$rules = @(Read-Get "/accounts/$acct/gateway/rules")
$accepted = [ordered]@{
    deviceSubjectIsAndroid01   = ($devSubject.Count -eq 1 -and $devSubject[0].subject_id -eq 'sub_01M5Y0XYAMFT3MXRRJV5MFBY3N' -and $devSubject[0].alias -eq 'android-01')
    bindingIsExpected          = ($devBinding.Count -eq 1 -and $devBinding[0].binding_id -eq 'bnd_01M5ZND7V8TK28E2V23Z4MRFEJ')
    providerIdsExpected        = ($devBinding[0].external.physical_device_id -eq '01a17f4d-0062-19de-b716-1df58125a3d4' -and $devBinding[0].external.registration_id -eq '01a17f4d-0062-19de-b716-1df58125a3d4')
    exactlyOneDevice           = ($obs.physicalDeviceCount -eq 1 -and $obs.registrationCount -eq 1)
    registrationPointsToDevice = ($obs.registrationDeviceId -eq $obs.physicalDeviceId)
    androidRedmiNote13ProPlus  = ($obs.device_type -eq 'android' -and $obs.model -eq '23090RA98G')
    warp                       = ($obs.registration_type -eq 'warp')
    masque                     = ($obs.tunnel_type -eq 'masque')
    profileSetokFamilyManaged  = ($obs.profile.policy_id -eq $managedId -and $obs.profile.name -eq 'SETOK-FAMILY-MANAGED' -and -not $obs.profile.default)
    activeNotRevoked           = (-not $obs.revoked -and $obs.active_registrations -eq 1)
    noFamilyGatewayEnforcement = (@($rules | Where-Object { $_.name -like 'SETOK-FAMILY*' -or "$($_.identity)" -ne '' -or "$($_.device_posture)" -ne '' }).Count -eq 0)
}

$dedicated = [ordered]@{ alias = 'android-01-enrollment'; availableLocally = (Test-Path $dedFile) }
if ($dedicated.availableLocally) {
    $d = [Net.NetworkCredential]::new('', (Import-Clixml $dedFile)).Password.Trim().ToLower()
    $shared = [Net.NetworkCredential]::new('', (Import-Clixml $mailFile)).Password.Trim().ToLower()
    $norm = { param($e) $e = "$e".ToLower(); if ($e -match '^([^+@]+)\+[^@]*(@.+)$') { $Matches[1] + $Matches[2] } else { $e } }
    $phys = @(Read-Get "/accounts/$acct/devices/physical-devices"); $regs = @(Read-Get "/accounts/$acct/devices/registrations")
    $users = @(Read-Get "/accounts/$acct/access/users"); $acctName = "$((Read-Get "/accounts/$acct").name)".ToLower()
    $members = try { @(Read-Get "/accounts/$acct/members") } catch { $null }
    $dedicated.isSingleExactAddress            = ($d -match '^[^@\s,;*]+@[^@\s,;*]+\.[a-z]{2,}$')
    $dedicated.isPlusAddress                   = ($d -match '^[^@]+\+[^@]*@')
    $dedicated.equalsCurrentSharedEnrollmentIdentity = ((& $norm $d) -eq (& $norm $shared))
    $dedicated.equalsCloudflareAccountOwnerAddress   = ($acctName.StartsWith($d) -or $acctName.StartsWith((& $norm $d)))
    $dedicated.accountMembersReadable          = ($null -ne $members)
    $dedicated.isAccountMember                 = $(if ($null -ne $members) { [bool](@($members | Where-Object { (& $norm $_.user.email) -eq (& $norm $d) }).Count) } else { 'UNVERIFIABLE_WITH_TOKEN' })
    $dedicated.existingPhysicalDevices         = @($phys | Where-Object { (& $norm $_.last_seen_user.email) -eq (& $norm $d) }).Count
    $dedicated.existingRegistrations           = @($regs | Where-Object { (& $norm $_.user.email) -eq (& $norm $d) }).Count
    $dedicated.existingAccessUsers             = @($users | Where-Object { (& $norm $_.email) -eq (& $norm $d) }).Count
    $dedicated.existingSetokDeviceBinding      = $false   # registry bindings hold only provider ids; the identity has never been bound
    $dedicated.currentlyPermittedByEnrollmentPolicy = $false
    $pol = @(Read-Get "/accounts/$acct/access/policies" | Where-Object id -eq $enroll.external.access_policy_id)
    if ($pol.Count -eq 1) { $dedicated.currentlyPermittedByEnrollmentPolicy = [bool](@($pol[0].include | Where-Object { (& $norm $_.email.email) -eq (& $norm $d) }).Count) }
    Remove-Variable d, shared
}

$cf3 = Get-Content (Get-ChildItem (Join-Path $repo 'docs\evidence\ST-CF-003') -Filter '*-discovery.json' | Sort-Object Name | Select-Object -Last 1) -Raw | ConvertFrom-Json -DateKind String
$after = Get-Snapshot
$drift = foreach ($k in $before.surfaces.Keys) {
    [pscustomobject]@{ surface = $k; unchangedDuringPreflight = ($before.surfaces[$k].sha256 -eq $after.surfaces[$k].sha256)
                       unchangedSinceStCf003 = ($before.surfaces[$k].sha256 -eq $cf3.fingerprints.after.$k.sha256) }
}
$devDrift = [pscustomobject]@{
    physicalIdsUnchangedSinceStCf003 = ((@($before.devices.physicalIds) -join ',') -eq '01a17f4d-0062-19de-b716-1df58125a3d4')
    enrollmentAuthorizationUnchangedSinceStCf003 = $null
}
$eaCf3 = (Get-Content (Get-ChildItem (Join-Path $repo 'docs\evidence\ST-DEV-001') -Filter '*-snapshot-final.json' | Sort-Object Name | Select-Object -Last 1) -Raw | ConvertFrom-Json -DateKind String).enrollmentAuthorization
$devDrift.enrollmentAuthorizationUnchangedSinceStCf003 = (($before.enrollmentAuthorization | ConvertTo-Json -Compress) -eq ($eaCf3 | ConvertTo-Json -Compress))

$stop = @()
if ($accepted.Values -contains $false) { $stop += 'ANDROID_ACCEPTED_STATE_MISMATCH: ' + (@($accepted.Keys | Where-Object { -not $accepted[$_] }) -join ',') }
if ($drift.unchangedDuringPreflight -contains $false -or $drift.unchangedSinceStCf003 -contains $false -or -not $devDrift.physicalIdsUnchangedSinceStCf003 -or -not $devDrift.enrollmentAuthorizationUnchangedSinceStCf003) { $stop += 'SHARED_SURFACE_DRIFT' }
if (-not $dedicated.availableLocally) { $stop += 'DEDICATED_IDENTITY_NOT_AVAILABLE_LOCALLY' }
else {
    if (-not $dedicated.isSingleExactAddress) { $stop += 'DEDICATED_IDENTITY_NOT_A_SINGLE_ADDRESS' }
    if ($dedicated.isPlusAddress) { $stop += 'DEDICATED_IDENTITY_IS_PLUS_ADDRESS' }
    if ($dedicated.equalsCurrentSharedEnrollmentIdentity -or $dedicated.equalsCloudflareAccountOwnerAddress -or $dedicated.isAccountMember -eq $true) { $stop += 'DEDICATED_IDENTITY_IS_OWNER_ADMIN_OR_SHARED' }
    if ($dedicated.existingPhysicalDevices -or $dedicated.existingRegistrations -or $dedicated.existingAccessUsers) { $stop += 'DEDICATED_IDENTITY_ALREADY_USED' }
}
$src = Get-Content $PSCommandPath -Raw
$writes = ([regex]::Matches($src, '(?i)-Method\s+(P' + 'OST|P' + 'UT|P' + 'ATCH|D' + 'ELETE)\b')).Count

$out = [pscustomobject]@{
    observedAt = (Get-Date).ToUniversalTime().ToString('o')
    acceptedAndroidState = [pscustomobject]$accepted; deviceObservation = $obs
    dedicatedIdentity = [pscustomobject]$dedicated
    beforeFingerprints = $before.surfaces; enrollmentAuthorization = $before.enrollmentAuthorization
    drift = $drift; deviceDrift = $devDrift
    gatewayRules = @($rules | Sort-Object precedence | ForEach-Object { [pscustomobject]@{ id = $_.id; name = $_.name; action = $_.action; enabled = $_.enabled; precedence = $_.precedence; filters = $_.filters } })
    staticWriteVerbs = $writes
    decision = $(if ($stop) { 'STOP' } else { 'PASS' }); stopReasons = $stop
}
Save-Evidence 'stage-a-preflight' $out
$accepted.GetEnumerator() | ForEach-Object { "{0,-28} {1}" -f $_.Key, $_.Value }
$dedicated.GetEnumerator() | ForEach-Object { "{0,-42} {1}" -f $_.Key, $_.Value }
$drift | Format-Table -AutoSize
$devDrift | Format-List
"static write verbs: $writes"
"STAGE A: $($out.decision) $($stop -join '; ')"
