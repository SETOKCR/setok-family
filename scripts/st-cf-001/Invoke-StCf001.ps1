<#
.SYNOPSIS
  ST-CF-001: Cloudflare Zero Trust pilot foundation for SETOK Family (Story-specific, not a reusable module).

.DESCRIPTION
  Git desired state -> PowerShell -> Cloudflare API -> observed-state verification -> evidence.

  Modes:
    Discover  read-only. Verifies the token, identifies the single account it can reach, reads the
              Zero Trust organization and every device profile. Writes a snapshot to the evidence folder.
    Plan      read-only. Discover + computes the delta between desired and observed device profile.
    Apply     mutates ONLY the SETOK-FAMILY-MANAGED custom device profile (create or patch).
              Requires -AccountId equal to the discovered account (positive identification).
    Verify    read-only. Re-reads provider state and compares it field by field with desired state.
    Rollback  deletes ONLY the SETOK-FAMILY-MANAGED profile, after re-checking its name and id.

  The API token is read from the DPAPI-protected file written by Set-StCf001Token.ps1 and is passed to
  Invoke-RestMethod as a SecureString. It is never printed or written to evidence.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('Discover','Plan','Apply','Verify','Rollback')][string]$Mode,
    [string]$AccountId
)

$ErrorActionPreference = 'Stop'
$repo        = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$desiredPath = Join-Path $repo 'infra\cloudflare\st-cf-001.desired.json'
$evidenceDir = Join-Path $repo 'docs\evidence\ST-CF-001'
$tokenPath   = Join-Path $env:LOCALAPPDATA 'SETOK\setok-family\cloudflare-st-cf-001.token.xml'
$api         = 'https://api.cloudflare.com/client/v4'
$compared    = 'service_mode_v2','tunnel_protocol','switch_locked','auto_connect','allowed_to_leave','allow_mode_switch'

if (-not (Test-Path $tokenPath)) { throw "Token file not found. Run Set-StCf001Token.ps1 first." }
$token   = Import-Clixml $tokenPath
$desired = Get-Content $desiredPath -Raw | ConvertFrom-Json

function Invoke-Cf([string]$Method, [string]$Path, $Body) {
    $p = @{ Method = $Method; Uri = "$api$Path"; Authentication = 'Bearer'; Token = $token; ContentType = 'application/json' }
    if ($null -ne $Body) { $p.Body = ($Body | ConvertTo-Json -Depth 10) }
    try { $r = Invoke-RestMethod @p }
    catch {
        $msg = $_.ErrorDetails.Message
        throw "Cloudflare $Method $Path failed: $msg"
    }
    if (-not $r.success) { throw "Cloudflare $Method $Path returned success=false: $($r.errors | ConvertTo-Json -Compress)" }
    $r.result
}

function Save-Evidence([string]$Name, $Object) {
    New-Item -ItemType Directory -Force $evidenceDir | Out-Null
    $file = Join-Path $evidenceDir ("{0}-{1}.json" -f (Get-Date -Format 'yyyyMMddTHHmmss'), $Name)
    $Object | ConvertTo-Json -Depth 12 | Set-Content -Path $file -Encoding utf8
    Write-Host "Evidence: $($file.Replace("$repo\", ''))"
}

function Get-State {
    $verify   = Invoke-Cf GET '/user/tokens/verify'
    $accounts = @(Invoke-Cf GET '/accounts')
    if ($accounts.Count -ne 1) { throw "STOP: token reaches $($accounts.Count) accounts; it must be scoped to exactly the SETOK Family account." }
    $acct = $accounts[0]
    $org = $null
    try { $org = Invoke-Cf GET "/accounts/$($acct.id)/access/organizations" } catch { $org = @{ error = "$_" } }
    $defaultProfile = Invoke-Cf GET "/accounts/$($acct.id)/devices/policy"
    $profiles = @(Invoke-Cf GET "/accounts/$($acct.id)/devices/policies")
    [pscustomobject]@{
        observedAt     = (Get-Date).ToUniversalTime().ToString('o')
        token          = [pscustomobject]@{ status = $verify.status; expires_on = $verify.expires_on }
        account        = [pscustomobject]@{ id = $acct.id; name = $acct.name; type = $acct.type }
        organization   = if ($org.auth_domain) { [pscustomobject]@{ name = $org.name; auth_domain = $org.auth_domain } } else { $org }
        defaultProfile = $defaultProfile
        profiles       = $profiles
    }
}

function Get-Managed($state) {
    @($state.profiles | Where-Object { -not $_.default -and $_.name -eq $desired.deviceProfile.name })
}

function Get-Delta($state) {
    $managed = Get-Managed $state
    if ($managed.Count -gt 1) { throw "STOP: $($managed.Count) profiles named $($desired.deviceProfile.name); refusing to choose." }
    $want = [ordered]@{
        name        = $desired.deviceProfile.name
        description = $desired.deviceProfile.description
        match       = $desired.deviceProfile.match
        precedence  = $desired.deviceProfile.precedence
        enabled     = $desired.deviceProfile.enabled
    }
    foreach ($k in $compared) { $want[$k] = $desired.deviceProfile.settings.$k }

    $others = @($state.profiles | Where-Object { -not $_.default -and $_.name -ne $desired.deviceProfile.name })
    $clash  = @($others | Where-Object { $_.precedence -eq $want.precedence })
    if ($clash) { throw "STOP: precedence $($want.precedence) already used by '$($clash[0].name)'." }

    if ($managed.Count -eq 0) {
        return [pscustomobject]@{ action = 'CREATE'; policyId = $null; changes = $want; body = $want }
    }
    $cur = $managed[0]
    $changes = [ordered]@{}
    foreach ($k in $want.Keys) {
        $a = $cur.$k | ConvertTo-Json -Depth 5 -Compress
        $b = $want[$k] | ConvertTo-Json -Depth 5 -Compress
        if ($a -ne $b) { $changes[$k] = [pscustomobject]@{ observed = $cur.$k; desired = $want[$k] } }
    }
    $body = [ordered]@{}; foreach ($k in $changes.Keys) { $body[$k] = $want[$k] }
    [pscustomobject]@{ action = $(if ($changes.Count) { 'UPDATE' } else { 'NONE' }); policyId = $cur.policy_id; changes = $changes; body = $body }
}

$state = Get-State
switch ($Mode) {
    'Discover' {
        Save-Evidence 'discover' $state
        $state | Select-Object observedAt, token, account, organization | Format-List
        "Device profiles (default + custom): {0}" -f (@($state.profiles).Count)
        $state.profiles | Select-Object name, default, precedence, enabled, match | Format-Table -AutoSize
    }
    'Plan' {
        $delta = Get-Delta $state
        Save-Evidence 'plan' ([pscustomobject]@{ state = $state; delta = $delta })
        "Account: $($state.account.name) ($($state.account.id))"
        "Action:  $($delta.action)"
        $delta.changes | ConvertTo-Json -Depth 6
        "Rollback: delete custom profile '$($desired.deviceProfile.name)' only; default and other profiles untouched."
    }
    'Apply' {
        if ($AccountId -ne $state.account.id) { throw "STOP: -AccountId does not match the discovered account; refusing to mutate." }
        $delta = Get-Delta $state
        $result = switch ($delta.action) {
            'CREATE' { Invoke-Cf POST  "/accounts/$AccountId/devices/policy" $delta.body }
            'UPDATE' { Invoke-Cf PATCH "/accounts/$AccountId/devices/policy/$($delta.policyId)" $delta.body }
            'NONE'   { 'No changes required (idempotent).' }
        }
        Save-Evidence 'apply' ([pscustomobject]@{ before = $state; delta = $delta; response = $result })
        "Applied: $($delta.action)"
    }
    'Verify' {
        $managed = Get-Managed $state
        $delta = if ($managed.Count -eq 1) { Get-Delta $state } else { $null }
        $ok = ($managed.Count -eq 1) -and ($delta.action -eq 'NONE')
        $report = [pscustomobject]@{
            verdict          = $(if ($ok) { 'MATCH' } else { 'DRIFT' })
            managedCount     = $managed.Count
            policyId         = $managed[0].policy_id
            observed         = $managed[0] | Select-Object (@('name','match','precedence','enabled') + $compared)
            delta            = $delta
            account          = $state.account
            organization     = $state.organization
            allProfiles      = $state.profiles | Select-Object policy_id, name, default, precedence, enabled, match
        }
        Save-Evidence 'verify' $report
        $report | Select-Object verdict, managedCount, policyId | Format-List
        $report.observed | Format-List
        if (-not $ok) { exit 1 }
    }
    'Rollback' {
        if ($AccountId -ne $state.account.id) { throw "STOP: -AccountId does not match the discovered account; refusing to mutate." }
        $managed = Get-Managed $state
        if ($managed.Count -eq 0) { 'Nothing to roll back.'; break }
        if ($managed.Count -gt 1) { throw "STOP: multiple managed profiles; resolve manually." }
        $result = Invoke-Cf DELETE "/accounts/$AccountId/devices/policy/$($managed[0].policy_id)"
        Save-Evidence 'rollback' ([pscustomobject]@{ deleted = $managed[0]; response = $result })
        "Deleted $($managed[0].name) ($($managed[0].policy_id))"
    }
}
