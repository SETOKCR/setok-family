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
    [Parameter(Mandatory)][ValidateSet('Snapshot', 'Gate', 'CreateSubject', 'Validate', 'Bind', 'Reconcile', 'Compare')][string]$Step,
    [string]$Label = 'pre',
    [string]$ProviderDeviceId,
    [string]$Against = 'final'
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
    $db = @($r.bindings | Where-Object binding_type -eq 'device_enrollment')
    if ($db.Count -gt 1) { $v.Add("DEVICE-BINDING: at most 1 device_enrollment binding allowed (found $($db.Count))") }
    foreach ($b in $db) {
        if ($b.target.kind -ne 'subject' -or $b.target.id -notin @($dev.subject_id)) { $v.Add('DEVICE-BINDING: must target the device subject') }
        if ($b.provider -ne 'cloudflare-zero-trust' -or $b.integration_id -ne $cfInt) { $v.Add('DEVICE-BINDING: must use the Cloudflare enforcement integration') }
        if ((@($b.external.PSObject.Properties.Name | Sort-Object) -join ',') -ne 'physical_device_id,registration_id') { $v.Add('DEVICE-BINDING: external must hold only physical_device_id and registration_id') }
    }
    , $v.ToArray()
}

# Minimal, sanitized provider observation of one device (no user, email, IP, serial, key or virtual IP).
function Get-DeviceObservation([string]$Id) {
    $phys = @(Read-Get "/accounts/$acct/devices/physical-devices"); $regs = @(Read-Get "/accounts/$acct/devices/registrations")
    $p = @($phys | Where-Object id -eq $Id)[0]
    $rg = @($regs | Where-Object { $_.id -eq $Id -or $_.device.id -eq $Id })
    $rd = if ($rg.Count -eq 1) { Read-Get "/accounts/$acct/devices/registrations/$($rg[0].id)?include=policy,device" } else { $null }
    [pscustomobject]@{
        physicalDeviceCount = $phys.Count; registrationCount = $regs.Count
        physicalDeviceId = $p.id; device_type = $p.device_type; model = $p.model; model_name = $p.name; os_version = $p.os_version; client_version = $p.client_version
        active_registrations = $p.active_registrations
        registrationsForDevice = $rg.Count; registrationId = $rd.id; registration_type = $rd.registration_type; tunnel_type = $rd.tunnel_type
        registrationDeviceId = $rd.device.id
        profile = [pscustomobject]@{ policy_id = $rd.policy.id; name = $rd.policy.name; default = $rd.policy.default; deleted = $rd.policy.deleted }
        revoked = [bool]$rd.revoked_at
    }
}
function Test-Binding($obs, $binding, $managed) {
    [ordered]@{
        bindingExistsOnce        = [bool]$binding
        physicalDevicePresent    = ($obs.physicalDeviceId -eq $binding.external.physical_device_id)
        registrationPresent      = ($obs.registrationId -eq $binding.external.registration_id -and $obs.registrationsForDevice -eq 1)
        registrationPointsToDevice = ($obs.registrationDeviceId -eq $obs.physicalDeviceId)
        platformAndroid          = ($obs.device_type -eq 'android')
        modelIsApprovedTarget    = ($obs.model -eq '23090RA98G' -and $obs.model_name -eq 'Redmi Note 13 Pro+ 5G')
        registrationTypeWarp     = ($obs.registration_type -eq 'warp')
        tunnelMasque             = ($obs.tunnel_type -eq 'masque')
        intendedProfileObserved  = ($obs.profile.policy_id -eq $managedId -and $obs.profile.name -eq 'SETOK-FAMILY-MANAGED' -and -not $obs.profile.default -and -not $obs.profile.deleted)
        managedProfileTrafficAndDns = ($managed.service_mode -eq 'warp' -and $managed.switch_locked -eq $true)
        notRevoked               = (-not $obs.revoked)
        onlyDeviceInAccount      = ($obs.physicalDeviceCount -eq 1 -and $obs.registrationCount -eq 1)
    }
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
    'Bind' {
        if (-not $ProviderDeviceId) { throw '-ProviderDeviceId is required' }
        $r = Read-Registry
        $dev = @($r.subjects | Where-Object { $_.subject_type -eq 'device' -and $_.alias -eq $DeviceAlias })
        if ($dev.Count -ne 1) { throw 'STOP: device subject android-01 not found exactly once' }
        $existing = @($r.bindings | Where-Object binding_type -eq 'device_enrollment')
        if ($existing.Count -eq 1 -and $existing[0].external.physical_device_id -eq $ProviderDeviceId -and $existing[0].target.id -eq $dev[0].subject_id) { "NONE: binding $($existing[0].binding_id) already exists"; break }
        if ($existing.Count) { throw 'STOP: an unexpected device_enrollment binding already exists' }
        $obs = Get-DeviceObservation $ProviderDeviceId
        if (-not $obs.physicalDeviceId -or $obs.registrationsForDevice -ne 1 -or $obs.registrationDeviceId -ne $ProviderDeviceId -or $obs.physicalDeviceCount -ne 1) { throw 'STOP: provider device/registration cannot be bound deterministically' }
        $a = '0123456789ABCDEFGHJKMNPQRSTVWXYZ'; $ms = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds(); $t = ''
        for ($i = 0; $i -lt 10; $i++) { $t = $a[[int]($ms % 32)] + $t; $ms = [math]::Floor($ms / 32) }
        $bb = [byte[]]::new(16); [Security.Cryptography.RandomNumberGenerator]::Fill($bb)
        $bid = "bnd_$t" + (-join ($bb | ForEach-Object { $a[$_ % 32] }))
        $raw = [IO.File]::ReadAllText($regPath)
        $anchor = '"source": "ST-CF-002"' + "`n" + '    }' + "`n" + '  ]'
        if (([regex]::Matches($raw, [regex]::Escape($anchor))).Count -ne 1) { throw 'STOP: registry anchor for bindings not found exactly once' }
        $entry = @"
"source": "ST-CF-002"
    },
    {
      "binding_id": "$bid",
      "tenant_id": "$tenant",
      "target": { "kind": "subject", "id": "$($dev[0].subject_id)" },
      "provider": "cloudflare-zero-trust",
      "binding_type": "device_enrollment",
      "integration_id": "$cfInt",
      "external": { "physical_device_id": "$($obs.physicalDeviceId)", "registration_id": "$($obs.registrationId)" },
      "status": "ACTIVE",
      "valid_from": "$((Get-Date).ToUniversalTime().ToString('yyyy-MM-dd'))",
      "source": "ST-DEV-001"
    }
  ]
"@.Replace("`r`n", "`n").TrimEnd("`n")
        [IO.File]::WriteAllText($regPath, $raw.Replace($anchor, $entry))
        "CREATE: binding $bid -> $($dev[0].subject_id) (physical $($obs.physicalDeviceId), registration $($obs.registrationId))"
    }
    'Reconcile' {
        $r = Read-Registry
        $b = @($r.bindings | Where-Object { $_.binding_type -eq 'device_enrollment' -and $_.status -eq 'ACTIVE' })
        if ($b.Count -ne 1) { throw "STOP: expected exactly 1 ACTIVE device_enrollment binding (found $($b.Count))" }
        $runs = foreach ($n in 1, 2) {
            $obs = Get-DeviceObservation $b[0].external.physical_device_id
            $snap = Get-Snapshot
            [pscustomobject]@{ run = $n; observation = $obs; checks = (Test-Binding $obs $b[0] $snap.surfaces.managedProfile); enrollmentAuthorization = $snap.enrollmentAuthorization }
        }
        $sem = { param($x) $x | Select-Object @{ n = 'observation'; e = { $_.observation | Select-Object * -ExcludeProperty client_version } }, checks, enrollmentAuthorization | ConvertTo-Json -Depth 10 -Compress }
        $same = ((& $sem $runs[0]) -eq (& $sem $runs[1]))
        $match = -not (@($runs.checks | ForEach-Object { $_.Values }) -contains $false)
        Save-Evidence 'stage-d-reconcile' ([pscustomobject]@{ binding = $b[0]; runs = $runs; deterministic = $same; verdict = $(if ($match) { 'MATCH' } else { 'DRIFT' })
            note = 'Cloudflare One client UI state (Connected) is PO-observed; provider evidence = active registration, MASQUE tunnel, SETOK-FAMILY-MANAGED (Traffic + DNS) assignment.' })
        $runs[1].checks | Format-Table -AutoSize
        "verdict: $(if ($match) { 'MATCH' } else { 'DRIFT' }); deterministic: $same"
        if (-not ($match -and $same)) { exit 1 }
    }
    'Compare' {
        $find = { param($l) Get-ChildItem $evidence -Filter "*-snapshot-$l.json" | Sort-Object Name | Select-Object -Last 1 }
        $a = Get-Content (& $find $Label) -Raw | ConvertFrom-Json -DateKind String
        $b = Get-Content (& $find $Against) -Raw | ConvertFrom-Json -DateKind String
        $rows = foreach ($p in $a.surfaces.PSObject.Properties.Name) { [pscustomobject]@{ surface = $p; unchanged = ($a.surfaces.$p.sha256 -eq $b.surfaces.$p.sha256) } }
        $eaSame = (($a.enrollmentAuthorization | ConvertTo-Json -Compress) -eq ($b.enrollmentAuthorization | ConvertTo-Json -Compress))
        $newPhys = @($b.devices.physicalIds | Where-Object { $_ -notin @($a.devices.physicalIds) }); $gonePhys = @($a.devices.physicalIds | Where-Object { $_ -notin @($b.devices.physicalIds) })
        $newRegs = @($b.devices.registrationIds | Where-Object { $_ -notin @($a.devices.registrationIds) }); $goneRegs = @($a.devices.registrationIds | Where-Object { $_ -notin @($b.devices.registrationIds) })
        $res = [pscustomobject]@{ from = $Label; to = $Against; surfaces = $rows; allSharedUnchanged = -not ($rows.unchanged -contains $false); enrollmentAuthorizationUnchanged = $eaSame
            newPhysicalDevices = $newPhys; removedPhysicalDevices = $gonePhys; newRegistrations = $newRegs; removedRegistrations = $goneRegs }
        Save-Evidence "compare-$Label-$Against" $res
        $rows | Format-Table -AutoSize
        "enrollment authorization unchanged: $eaSame; new physical: $($newPhys -join ','); removed physical: $($gonePhys.Count); new regs: $($newRegs -join ','); removed regs: $($goneRegs.Count)"
    }
}
