<#
.SYNOPSIS
  ST-DEV-001: first Android device enrollment and provider binding (Story-specific).

.DESCRIPTION
  Cloudflare access in this script is HTTP GET only. The only intended Cloudflare mutation of the Story is the
  device's own registration, created by the supported manual Cloudflare One Agent flow on the handset.

  Steps:
    Snapshot  read-only; sanitized inventory + fingerprints of every shared surface that must stay unchanged
              (Gateway rules/lists, device settings, Default + SETOK-FAMILY-MANAGED profiles, Access org,
              identity providers, Access apps/policies (device enrollment permissions), service tokens) and
              of devices/registrations. -Label names the snapshot (pre, post, ...).
    Compare   compares two snapshots (-Label pre -Against post) and reports exactly what changed.

  Evidence never contains emails, user names, IP addresses or tokens: device/registration records are reduced
  to stable ids, platform facts and timestamps; everything else is hashed.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('Snapshot', 'Compare')][string]$Step,
    [string]$Label = 'pre',
    [string]$Against
)

$ErrorActionPreference = 'Stop'
$repo     = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$evidence = Join-Path $repo 'docs\evidence\ST-DEV-001'
$regPath  = Join-Path $repo 'infra\bindings\registry.desired.json'
$cfToken  = Join-Path $env:LOCALAPPDATA 'SETOK\setok-family\cloudflare-st-cf-001.token.xml'
$reg      = Get-Content $regPath -Raw | ConvertFrom-Json -DateKind String
$acct     = @($reg.bindings | Where-Object { $_.binding_type -eq 'integration_account' -and $_.provider -eq 'cloudflare-zero-trust' -and $_.status -eq 'ACTIVE' })[0].external.account_id
$managedId = @($reg.bindings | Where-Object { $_.binding_type -eq 'managed_resource' -and $_.status -eq 'ACTIVE' })[0].external.policy_id

function Get-Sha([string]$s) { [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($s))).ToLower() }
function Hash($o) { Get-Sha ($o | ConvertTo-Json -Depth 20 -Compress) }
function Invoke-CfGet([string]$Path) {
    # GET is the only verb this Story uses against Cloudflare. Fails closed if the provider reports more
    # results than were returned (inventories here are small; silent truncation would break the delta).
    $r = Invoke-RestMethod -Method Get -Uri "https://api.cloudflare.com/client/v4$Path" -Authentication Bearer -Token (Import-Clixml $cfToken)
    if (-not $r.success) { throw "Cloudflare GET $Path failed" }
    $items = @($r.result | Where-Object { $_ })
    if ($r.result_info -and $r.result_info.total_count -and $r.result_info.total_count -gt $items.Count) { throw "Cloudflare GET $Path returned $($items.Count) of $($r.result_info.total_count); refusing a partial inventory" }
    , $items
}
function Get-CfGetOne([string]$Path) {
    $r = Invoke-RestMethod -Method Get -Uri "https://api.cloudflare.com/client/v4$Path" -Authentication Bearer -Token (Import-Clixml $cfToken)
    if (-not $r.success) { throw "Cloudflare GET $Path failed" }
    $r.result
}
function Save-Evidence([string]$Name, $Object) {
    New-Item -ItemType Directory -Force $evidence | Out-Null
    $file = Join-Path $evidence ("{0}-{1}.json" -f (Get-Date -Format 'yyyyMMddTHHmmss'), $Name)
    $Object | ConvertTo-Json -Depth 20 | Set-Content $file -Encoding utf8
    Write-Host "Evidence: $($file.Replace("$repo\", ''))"
    $file
}

function Get-Snapshot {
    $rules     = (Invoke-CfGet "/accounts/$acct/gateway/rules")
    $lists     = (Invoke-CfGet "/accounts/$acct/gateway/lists")
    $gwConfig  = Get-CfGetOne "/accounts/$acct/gateway/configuration"
    $devSet    = Get-CfGetOne "/accounts/$acct/devices/settings"
    $default   = Get-CfGetOne "/accounts/$acct/devices/policy"
    $profiles  = (Invoke-CfGet "/accounts/$acct/devices/policies")
    $managed   = @($profiles | Where-Object policy_id -eq $managedId)
    $org       = Get-CfGetOne "/accounts/$acct/access/organizations"
    $idps      = (Invoke-CfGet "/accounts/$acct/access/identity_providers")
    $apps      = (Invoke-CfGet "/accounts/$acct/access/apps")
    $policies  = (Invoke-CfGet "/accounts/$acct/access/policies")
    $svcTokens = (Invoke-CfGet "/accounts/$acct/access/service_tokens")
    $posture   = (Invoke-CfGet "/accounts/$acct/devices/posture")
    $devices   = (Invoke-CfGet "/accounts/$acct/devices/physical-devices")
    $regs      = (Invoke-CfGet "/accounts/$acct/devices/registrations")
    $legacy    = (Invoke-CfGet "/accounts/$acct/devices")
    # Sanitized device facts: ids, platform and lifecycle timestamps only (no user, email, name, IP).
    $devFacts  = @($devices | Sort-Object id | ForEach-Object { [pscustomobject]@{ id = $_.id; os = "$($_.os_name)$($_.platform)"; model = $_.model; manufacturer = $_.manufacturer; created_at = $_.created_at; client_version = $_.client_version } })
    $regFacts  = @($regs | Sort-Object id | ForEach-Object { [pscustomobject]@{ id = $_.id; device_id = $(if ($_.device) { $_.device.id } else { $_.device_id }); policy_id = $(if ($_.policy) { $_.policy.id } else { $_.policy_id }); policy_name = $(if ($_.policy) { $_.policy.name } else { $null }); created_at = $_.created_at; revoked_at = $_.revoked_at; deleted_at = $_.deleted_at } })
    $legFacts  = @($legacy | Sort-Object id | ForEach-Object { [pscustomobject]@{ id = $_.id; device_type = $_.device_type; model = $_.model; manufacturer = $_.manufacturer; created = $_.created; version = $_.version; revoked_at = $_.revoked_at; deleted = $_.deleted } })
    $warpApps  = @($apps | Where-Object type -eq 'warp')
    [pscustomobject]@{
        observedAt = (Get-Date).ToUniversalTime().ToString('o')
        account    = $acct
        shared = [pscustomobject]@{
            gatewayRules       = [pscustomobject]@{ count = $rules.Count; byFilter = @($rules | Group-Object { ($_.filters | Sort-Object) -join '+' } | Sort-Object Name | ForEach-Object { "$($_.Name)=$($_.Count)" }); sha256 = Hash ($rules | Sort-Object id) }
            gatewayLists       = [pscustomobject]@{ count = $lists.Count; sha256 = Hash ($lists | Sort-Object id) }
            gatewayConfig      = [pscustomobject]@{ sha256 = Hash $gwConfig }
            deviceSettings     = [pscustomobject]@{ sha256 = Hash $devSet }
            defaultProfile     = [pscustomobject]@{ policy_id = $default.policy_id; sha256 = Hash $default }
            managedProfile     = [pscustomobject]@{ policy_id = $managedId; found = $managed.Count; match = $managed[0].match; precedence = $managed[0].precedence; enabled = $managed[0].enabled
                                                    service_mode = $managed[0].service_mode_v2.mode; tunnel_protocol = $managed[0].tunnel_protocol; switch_locked = $managed[0].switch_locked
                                                    allowed_to_leave = $managed[0].allowed_to_leave; sha256 = Hash $managed }
            allProfiles        = [pscustomobject]@{ count = $profiles.Count; ids = @($profiles.policy_id | Sort-Object); sha256 = Hash ($profiles | Sort-Object policy_id) }
            accessOrganization = [pscustomobject]@{ auth_domain = $org.auth_domain; sha256 = Hash $org }
            identityProviders  = [pscustomobject]@{ count = $idps.Count; types = @($idps.type | Sort-Object); sha256 = Hash ($idps | Sort-Object id) }
            accessApps         = [pscustomobject]@{ count = $apps.Count; warpEnrollmentApps = $warpApps.Count; sha256 = Hash ($apps | Sort-Object id) }
            accessPolicies     = [pscustomobject]@{ count = $policies.Count; sha256 = Hash ($policies | Sort-Object id) }
            serviceTokens      = [pscustomobject]@{ count = $svcTokens.Count; sha256 = Hash ($svcTokens | Sort-Object id) }
            postureRules       = [pscustomobject]@{ count = $posture.Count; sha256 = Hash ($posture | Sort-Object id) }
        }
        devices = [pscustomobject]@{
            physicalDevices = $devFacts; registrations = $regFacts; legacyDevices = $legFacts
            sha256 = [pscustomobject]@{ physical = Hash ($devices | Sort-Object id | Select-Object id, created_at); registrations = Hash ($regs | Sort-Object id | Select-Object id, created_at) }
        }
        registry = [pscustomobject]@{
            sha256 = (Get-FileHash $regPath -Algorithm SHA256).Hash.ToLower()
            deviceSubjects = @($reg.subjects | Where-Object subject_type -eq 'device').Count
            cloudflareDeviceBindings = @($reg.bindings | Where-Object { $_.binding_type -eq 'device_enrollment' -and $_.provider -eq 'cloudflare-zero-trust' }).Count
        }
    }
}

switch ($Step) {
    'Snapshot' {
        $s = Get-Snapshot
        $null = Save-Evidence "snapshot-$Label" $s
        $s.shared | Format-List
        "devices: physical=$(@($s.devices.physicalDevices).Count) registrations=$(@($s.devices.registrations).Count) legacy=$(@($s.devices.legacyDevices).Count)"
        "registry: deviceSubjects=$($s.registry.deviceSubjects) cloudflareDeviceBindings=$($s.registry.cloudflareDeviceBindings)"
    }
    'Compare' {
        $find = { param($l) Get-ChildItem $evidence -Filter "*-snapshot-$l.json" | Sort-Object Name | Select-Object -Last 1 }
        $a = Get-Content (& $find $Label) -Raw | ConvertFrom-Json -DateKind String
        $b = Get-Content (& $find $Against) -Raw | ConvertFrom-Json -DateKind String
        $shared = foreach ($p in $a.shared.PSObject.Properties.Name) {
            [pscustomobject]@{ surface = $p; before = $a.shared.$p.sha256; after = $b.shared.$p.sha256; unchanged = ($a.shared.$p.sha256 -eq $b.shared.$p.sha256) }
        }
        $newPhys = @($b.devices.physicalDevices | Where-Object { $_.id -notin @($a.devices.physicalDevices.id) })
        $newRegs = @($b.devices.registrations | Where-Object { $_.id -notin @($a.devices.registrations.id) })
        $goneOrChanged = @($a.devices.physicalDevices | Where-Object { $o = $_; -not (@($b.devices.physicalDevices | Where-Object { $_.id -eq $o.id -and $_.created_at -eq $o.created_at }).Count) })
        $r = [pscustomobject]@{ from = $Label; to = $Against; shared = $shared; newPhysicalDevices = $newPhys; newRegistrations = $newRegs
            preExistingDevicesChangedOrRemoved = $goneOrChanged; allSharedUnchanged = -not ($shared.unchanged -contains $false) }
        $null = Save-Evidence "compare-$Label-$Against" $r
        $shared | Format-Table -AutoSize
        "new physical devices: $($newPhys.Count); new registrations: $($newRegs.Count); pre-existing changed/removed: $($goneOrChanged.Count)"
    }
}
