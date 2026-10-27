<#
.SYNOPSIS
  ST-DEV-001 r2: first Android device enrollment and provider binding (Story-specific).

.DESCRIPTION
  Cloudflare access in this script is HTTP GET only (ST-CF-001 token). The only intended Cloudflare mutation of
  the Story is the handset's own registration, created by the supported manual Cloudflare One Agent flow.

  Steps:
    Snapshot       read-only sanitized inventory + SHA-256 fingerprints of every shared surface, the ST-CF-002
                   enrollment authorization reconciliation and devices/registrations. -Label pre|post|...
    Gate           Stage A decision from the latest 'pre' snapshot (PASS or HARD STOP with reasons).
    CreateSubject  Stage B: adds exactly one provider-neutral device subject (alias android-01) to the registry;
                   idempotent (refuses to add a second).
    Validate       offline registry validation (schema + invariants) for the device-subject state.

  Evidence never contains emails, user names, IP addresses or tokens.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('Snapshot', 'Gate', 'CreateSubject', 'Validate')][string]$Step,
    [string]$Label = 'pre'
)

$ErrorActionPreference = 'Stop'
$repo       = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$evidence   = Join-Path $repo 'docs\evidence\ST-DEV-001'
$regPath    = Join-Path $repo 'infra\bindings\registry.desired.json'
$schemaPath = Join-Path $repo 'infra\bindings\provider-binding-registry.schema.json'
$local      = Join-Path $env:LOCALAPPDATA 'SETOK\setok-family'
$cfToken    = Join-Path $local 'cloudflare-st-cf-001.token.xml'
$mailFile   = Join-Path $local 'st-cf-002-enrollment-mailbox.xml'
$api        = 'https://api.cloudflare.com/client/v4'
$DeviceAlias = 'android-01'

function Read-Registry { Get-Content $regPath -Raw | ConvertFrom-Json -DateKind String }
$reg       = Read-Registry
$tenant    = $reg.tenants[0].tenant_id
$cfInt     = @($reg.integrations | Where-Object { $_.provider -eq 'cloudflare-zero-trust' -and $_.status -eq 'ACTIVE' })[0].integration_id
$acct      = @($reg.bindings | Where-Object { $_.binding_type -eq 'integration_account' -and $_.provider -eq 'cloudflare-zero-trust' -and $_.status -eq 'ACTIVE' })[0].external.account_id
$managedId = @($reg.bindings | Where-Object { $_.binding_type -eq 'managed_resource' -and $_.external.profile_name -eq 'SETOK-FAMILY-MANAGED' -and $_.status -eq 'ACTIVE' })[0].external.policy_id
$enroll    = @($reg.bindings | Where-Object { $_.binding_type -eq 'managed_resource' -and $_.external.access_app_type -eq 'warp' -and $_.status -eq 'ACTIVE' })[0]

function Get-Sha([string]$s) { [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($s))).ToLower() }
function Hash($o) { Get-Sha ($o | ConvertTo-Json -Depth 20 -Compress) }
function Save-Evidence([string]$Name, $Object) {
    New-Item -ItemType Directory -Force $evidence | Out-Null
    $file = Join-Path $evidence ("{0}-{1}.json" -f (Get-Date -Format 'yyyyMMddTHHmmss'), $Name)
    $Object | ConvertTo-Json -Depth 20 | Set-Content $file -Encoding utf8
    Write-Host "Evidence: $($file.Replace("$repo\", ''))"
}
function Read-Get([string]$Path) {
    # GET is the only verb this script uses against Cloudflare.
    $r = Invoke-RestMethod -Method Get -Uri "$api$Path" -Authentication Bearer -Token (Import-Clixml $cfToken)
    if (-not $r.success) { throw "Cloudflare GET $Path failed" }
    if ($r.result -is [array]) {
        $items = @($r.result | Where-Object { $_ })
        if ($r.result_info -and $r.result_info.total_count -gt $items.Count) { throw "GET $Path returned a partial page; refusing partial inventory" }
        return $items
    }
    $r.result
}

function Get-Snapshot {
    $rules = Read-Get "/accounts/$acct/gateway/rules"; $lists = Read-Get "/accounts/$acct/gateway/lists"
    $gw = Read-Get "/accounts/$acct/gateway/configuration"; $ds = Read-Get "/accounts/$acct/devices/settings"
    $default = Read-Get "/accounts/$acct/devices/policy"; $profiles = @(Read-Get "/accounts/$acct/devices/policies")
    $managed = @($profiles | Where-Object policy_id -eq $managedId)
    $org = Read-Get "/accounts/$acct/access/organizations"; $idps = @(Read-Get "/accounts/$acct/access/identity_providers")
    $apps = @(Read-Get "/accounts/$acct/access/apps"); $pols = @(Read-Get "/accounts/$acct/access/policies")
    $svc = @(Read-Get "/accounts/$acct/access/service_tokens"); $posture = @(Read-Get "/accounts/$acct/devices/posture")
    $groups = @(Read-Get "/accounts/$acct/access/groups")
    $phys = @(Read-Get "/accounts/$acct/devices/physical-devices"); $regs = @(Read-Get "/accounts/$acct/devices/registrations")
    $warp = @($apps | Where-Object type -eq 'warp')
    $appDetail = if ($warp.Count -eq 1) { Read-Get "/accounts/$acct/access/apps/$($warp[0].id)" } else { $null }
    $pol = @($pols | Where-Object id -eq $enroll.external.access_policy_id)
    $otp = @($idps | Where-Object type -eq 'onetimepin')
    $mail = [Net.NetworkCredential]::new('', (Import-Clixml $mailFile)).Password.Trim()
    $inc = @($pol[0].include)
    $ea = [ordered]@{
        warpAppCount               = $warp.Count
        warpAppIdMatchesRegistry   = ($warp.Count -eq 1 -and $warp[0].id -eq $enroll.external.access_app_id)
        allowedIdpsOnlyOneTimePin  = ((@($appDetail.allowed_idps | Sort-Object) -join ',') -eq "$($otp[0].id)")
        attachedPolicyIds          = @($appDetail.policies.id | Sort-Object)
        attachedOnlyRegistryPolicy = ((@($appDetail.policies.id | Sort-Object) -join ',') -eq $enroll.external.access_policy_id)
        accessPolicyCount          = $pols.Count
        policyFound                = ($pol.Count -eq 1)
        policyDecisionAllow        = ($pol[0].decision -eq 'allow')
        includeCardinality         = $inc.Count
        includeIsExactEmail        = ((@($inc | ForEach-Object { $_.PSObject.Properties.Name }) -join ',') -eq 'email')
        includeIsOperationalIdentity = ($inc.Count -eq 1 -and "$($inc[0].email.email)".ToLower() -eq $mail.ToLower())
        noRequireOrExclude         = (@($pol[0].require).Count -eq 0 -and @($pol[0].exclude).Count -eq 0)
        identityProviderTypes      = @($idps.type | Sort-Object)
    }
    Remove-Variable mail
    $s = [pscustomobject]@{
        observedAt = (Get-Date).ToUniversalTime().ToString('o'); account = $acct
        surfaces = [ordered]@{
            gatewayRules       = [pscustomobject]@{ count = @($rules).Count; sha256 = Hash (@($rules) | Sort-Object id) }
            gatewayLists       = [pscustomobject]@{ count = @($lists).Count; sha256 = Hash (@($lists) | Sort-Object id) }
            gatewayConfig      = [pscustomobject]@{ sha256 = Hash $gw }
            deviceSettings     = [pscustomobject]@{ sha256 = Hash $ds }
            defaultProfile     = [pscustomobject]@{ policy_id = $default.policy_id; sha256 = Hash $default }
            managedProfile     = [pscustomobject]@{ policy_id = $managedId; found = $managed.Count; match = $managed[0].match; precedence = $managed[0].precedence
                                                    service_mode = $managed[0].service_mode_v2.mode; tunnel_protocol = $managed[0].tunnel_protocol; switch_locked = $managed[0].switch_locked
                                                    allowed_to_leave = $managed[0].allowed_to_leave; sha256 = Hash $managed }
            allDeviceProfiles  = [pscustomobject]@{ count = $profiles.Count; sha256 = Hash ($profiles | Sort-Object policy_id) }
            accessOrganization = [pscustomobject]@{ auth_domain = $org.auth_domain; sha256 = Hash ($org | Select-Object * -ExcludeProperty updated_at) }
            identityProviders  = [pscustomobject]@{ count = $idps.Count; sha256 = Hash ($idps | Sort-Object id) }
            accessApps         = [pscustomobject]@{ count = $apps.Count; sha256 = Hash ($apps | Sort-Object id | Select-Object * -ExcludeProperty updated_at) }
            enrollmentApp      = [pscustomobject]@{ id = $warp[0].id; sha256 = Hash ($appDetail | Select-Object * -ExcludeProperty updated_at) }
            accessPolicies     = [pscustomobject]@{ count = $pols.Count; sha256 = Hash ($pols | Sort-Object id | Select-Object * -ExcludeProperty updated_at) }
            accessGroups       = [pscustomobject]@{ count = $groups.Count; sha256 = Hash ($groups | Sort-Object id) }
            serviceTokens      = [pscustomobject]@{ count = $svc.Count; sha256 = Hash ($svc | Sort-Object id) }
            postureRules       = [pscustomobject]@{ count = $posture.Count; sha256 = Hash ($posture | Sort-Object id) }
        }
        enrollmentAuthorization = [pscustomobject]$ea
        devices = [pscustomobject]@{
            physicalCount = $phys.Count; registrationCount = $regs.Count
            physicalIds = @($phys.id | Sort-Object); registrationIds = @($regs.id | Sort-Object)
            physicalFieldNames = @($(if ($phys.Count) { $phys[0].PSObject.Properties.Name | Sort-Object }))
            registrationFieldNames = @($(if ($regs.Count) { $regs[0].PSObject.Properties.Name | Sort-Object }))
        }
        registry = [pscustomobject]@{
            sha256 = (Get-FileHash $regPath -Algorithm SHA256).Hash.ToLower()
            deviceSubjects = @($reg.subjects | Where-Object subject_type -eq 'device').Count
            deviceEnrollmentBindings = @($reg.bindings | Where-Object binding_type -eq 'device_enrollment').Count
        }
        operationalIdentityAvailableLocally = (Test-Path $mailFile)
    }
    $s
}

function Test-Registry($r) {
    $v = [Collections.Generic.List[string]]::new()
    if (-not (Test-Json -Json ($r | ConvertTo-Json -Depth 20) -SchemaFile $schemaPath -ErrorAction SilentlyContinue)) { $v.Add('SCHEMA: registry does not conform') }
    $ids = @($r.tenants.tenant_id) + @($r.subjects.subject_id) + @($r.integrations.integration_id) + @($r.resources.resource_id) + @($r.bindings.binding_id)
    if (@($ids | Group-Object | Where-Object Count -gt 1).Count) { $v.Add('UNIQUE: duplicate internal id') }
    foreach ($x in @($r.subjects) + @($r.integrations) + @($r.resources) + @($r.bindings)) { if ($x.tenant_id -notin @($r.tenants.tenant_id)) { $v.Add("TENANT: $($x.PSObject.Properties.Value[0]) has unknown tenant") } }
    $dev = @($r.subjects | Where-Object subject_type -eq 'device')
    if ($dev.Count -ne 1) { $v.Add("DEVICE: expected exactly 1 device subject (found $($dev.Count))") }
    foreach ($d in $dev) { if ($d.PSObject.Properties.Name -contains 'human_kind') { $v.Add('DEVICE: device subject must not carry human_kind') } }
    $ext = @($r.bindings | ForEach-Object { $_.external.PSObject.Properties.Value } | ForEach-Object { "$_".ToLower().Replace('-', '') } | Where-Object { $_.Length -ge 6 })
    foreach ($d in $dev) { $b = ($d.subject_id -split '_', 2)[1].ToLower(); foreach ($e in $ext) { if ($b.Contains($e) -or $e.Contains($b)) { $v.Add('INDEPENDENCE: device id overlaps a provider identifier') } } }
    $humans = @($r.subjects | Where-Object subject_type -eq 'human')
    if ($humans.Count -ne 2) { $v.Add('HUMANS: expected the 2 existing adult subjects') }
    if (($r | ConvertTo-Json -Depth 20 -Compress) -match '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}') { $v.Add('PRIVACY: email-like value in registry') }
    , $v.ToArray()
}

switch ($Step) {
    'Snapshot' {
        $s = Get-Snapshot
        Save-Evidence "snapshot-$Label" $s
        $s.surfaces.GetEnumerator() | ForEach-Object { "{0,-20} {1}" -f $_.Key, ($_.Value | Select-Object * -ExcludeProperty sha256 | ConvertTo-Json -Compress) }
        $s.enrollmentAuthorization | ConvertTo-Json -Compress
        $s.devices | Select-Object physicalCount, registrationCount | ConvertTo-Json -Compress
        $s.registry | ConvertTo-Json -Compress
        "operationalIdentityAvailableLocally: $($s.operationalIdentityAvailableLocally)"
    }
    'Gate' {
        $f = Get-ChildItem $evidence -Filter '*-snapshot-pre.json' | Sort-Object Name | Select-Object -Last 1
        $s = Get-Content $f -Raw | ConvertFrom-Json -DateKind String
        $ea = $s.enrollmentAuthorization
        $c = [ordered]@{
            noPhysicalDevices = ($s.devices.physicalCount -eq 0); noRegistrations = ($s.devices.registrationCount -eq 0)
            enrollmentAppIsRegistryBound = $ea.warpAppIdMatchesRegistry; exactlyOneWarpApp = ($ea.warpAppCount -eq 1)
            onlyOneTimePin = $ea.allowedIdpsOnlyOneTimePin; onlyRegistryPolicyAttached = $ea.attachedOnlyRegistryPolicy
            policyAllow = $ea.policyDecisionAllow; includeCardinalityOne = ($ea.includeCardinality -eq 1); includeExactEmail = $ea.includeIsExactEmail
            includeIsOperationalIdentity = $ea.includeIsOperationalIdentity; noRequireOrExclude = $ea.noRequireOrExclude
            exactlyOneAccessPolicy = ($ea.accessPolicyCount -eq 1)
            managedProfileUnchanged = ($s.surfaces.managedProfile.found -eq 1 -and $s.surfaces.managedProfile.match -eq 'os.name in {"android" "ios"}' -and $s.surfaces.managedProfile.service_mode -eq 'warp' -and $s.surfaces.managedProfile.tunnel_protocol -eq 'masque' -and $s.surfaces.managedProfile.switch_locked -and -not $s.surfaces.managedProfile.allowed_to_leave)
            zeroServiceTokens = ($s.surfaces.serviceTokens.count -eq 0)
            zeroDeviceSubjects = ($s.registry.deviceSubjects -eq 0); zeroDeviceBindings = ($s.registry.deviceEnrollmentBindings -eq 0)
            operationalIdentityAvailableLocally = $s.operationalIdentityAvailableLocally
        }
        $failed = @($c.Keys | Where-Object { -not $c[$_] })
        Save-Evidence 'stage-a-decision' ([pscustomobject]@{ snapshot = $f.Name; checks = $c; decision = $(if ($failed) { 'HARD_STOP' } else { 'PASS' }); failed = $failed
            sharedMutationRequired = 'NO: enrollment permission exists (ST-CF-002), One-time PIN available, SETOK-FAMILY-MANAGED matches android, no profile/Gateway/IdP/service-token change needed' })
        $c | Format-Table -AutoSize
        if ($failed) { Write-Error "STAGE A HARD STOP: $($failed -join ', ')"; exit 1 }
        'STAGE A: PASS'
    }
    'CreateSubject' {
        $r = Read-Registry
        $existing = @($r.subjects | Where-Object { $_.subject_type -eq 'device' })
        if ($existing.Count -eq 1 -and $existing[0].alias -eq $DeviceAlias) { "NONE: device subject $($existing[0].subject_id) already exists"; break }
        if ($existing.Count) { throw 'STOP: an unexpected device subject already exists' }
        $a = '0123456789ABCDEFGHJKMNPQRSTVWXYZ'; $ms = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds(); $t = ''
        for ($i = 0; $i -lt 10; $i++) { $t = $a[[int]($ms % 32)] + $t; $ms = [math]::Floor($ms / 32) }
        $b = [byte[]]::new(16); [Security.Cryptography.RandomNumberGenerator]::Fill($b)
        $id = "sub_$t" + (-join ($b | ForEach-Object { $a[$_ % 32] }))
        # Text insertion keeps the existing file formatting; only the subjects array gains one entry.
        $raw = [IO.File]::ReadAllText($regPath)
        $anchor = '"alias": "adult-02", "status": "ACTIVE" }'
        if (([regex]::Matches($raw, [regex]::Escape($anchor))).Count -ne 1) { throw 'STOP: registry anchor for subjects not found exactly once' }
        $entry = $anchor + ",`n    { `"subject_id`": `"$id`", `"tenant_id`": `"$tenant`", `"subject_type`": `"device`", `"alias`": `"$DeviceAlias`", `"status`": `"ACTIVE`" }"
        [IO.File]::WriteAllText($regPath, $raw.Replace($anchor, $entry))
        "CREATE: device subject $id ($DeviceAlias)"
    }
    'Validate' {
        $r = Read-Registry
        $v = Test-Registry $r
        $dev = @($r.subjects | Where-Object subject_type -eq 'device')
        Save-Evidence 'stage-b-registry-validation' ([pscustomobject]@{ registrySha256 = (Get-FileHash $regPath -Algorithm SHA256).Hash.ToLower(); deviceSubjects = @($dev | Select-Object subject_id, tenant_id, subject_type, alias, status)
            deviceEnrollmentBindings = @($r.bindings | Where-Object binding_type -eq 'device_enrollment').Count; humanSubjects = @($r.subjects | Where-Object subject_type -eq 'human' | Select-Object subject_id, alias)
            violations = $v; pass = ($v.Count -eq 0) })
        if ($v.Count) { $v; exit 1 }
        'STAGE B registry validation: PASS'
    }
}
