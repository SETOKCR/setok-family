<#
.SYNOPSIS
  ST-POL-002: persistent modes, temporary overlays, deterministic composition into an Effective Policy Decision,
  and an APPLY_BLOCKED Cloudflare DNS plan. Story-specific; makes NO network calls (provider facts come from
  ST-POL-001 read-only discovery evidence).

.DESCRIPTION
  Representations kept separate:
    domain desired     infra/policy/baseline.desired.json (ST-POL-001), infra/policy/modes.desired.json
    adapter data       infra/policy/cloudflare/dns-adapter.json, infra/policy/cloudflare/dns-adapter.modes.json
    observed           docs/evidence/ST-POL-001/20261026T093737-discovery.json (provider categories)
    effective/compiled docs/evidence/ST-POL-002/*.json (DESIRED / COMPILED / APPLY_BLOCKED; never APPLIED)

  All timestamps in tests are fixed; nothing depends on wall-clock time.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$repo      = Resolve-Path (Join-Path $PSScriptRoot '..\..')
$P = @{
    baseline   = Join-Path $repo 'infra\policy\baseline.desired.json'
    modes      = Join-Path $repo 'infra\policy\modes.desired.json'
    schema     = Join-Path $repo 'infra\policy\modes.schema.json'
    registry   = Join-Path $repo 'infra\bindings\registry.desired.json'
    adapter    = Join-Path $repo 'infra\policy\cloudflare\dns-adapter.json'
    adapterM   = Join-Path $repo 'infra\policy\cloudflare\dns-adapter.modes.json'
    discovery  = Join-Path $repo 'docs\evidence\ST-POL-001\20261026T093737-discovery.json'
}
$evidence = Join-Path $repo 'docs\evidence\ST-POL-002'

function Read-Json([string]$Path) { Get-Content $Path -Raw | ConvertFrom-Json -DateKind String }
function Copy-Deep($o) { $o | ConvertTo-Json -Depth 30 | ConvertFrom-Json -DateKind String }
function Get-Sha([string]$s) { [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($s))).ToLower() }
function T([string]$s) { [DateTimeOffset]::Parse($s, [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::AssumeUniversal) }
function Fmt($d) { if ($null -eq $d) { $null } else { $d.ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ', [Globalization.CultureInfo]::InvariantCulture) } }
function Save-Evidence([string]$Name, $Object) {
    New-Item -ItemType Directory -Force $evidence | Out-Null
    $file = Join-Path $evidence ("{0}-{1}.json" -f (Get-Date -Format 'yyyyMMddTHHmmss'), $Name)
    $Object | ConvertTo-Json -Depth 30 | Set-Content $file -Encoding utf8
    Write-Host "Evidence: $($file.Replace("$repo\", ''))"
}

# PO-approved product semantics (Product Input Gate CLOSED). The desired config must equal this exactly.
$Approved = [ordered]@{
    'mode:STANDARD'               = @()
    'mode:RESTRICTED'             = @('entertainment_streaming:BLOCK', 'gaming:BLOCK', 'social_media:BLOCK')
    'overlay:STUDY'               = @('entertainment_streaming:BLOCK', 'gaming:BLOCK', 'social_media:BLOCK')
    'overlay:ALLOW_SOCIAL'        = @('social_media:ALLOW')
    'overlay:PAUSE_ENTERTAINMENT' = @('entertainment_streaming:BLOCK', 'gaming:BLOCK', 'social_media:BLOCK')
}
$ApprovedAllowSocialOverride = @('mode:RESTRICTED', 'overlay:STUDY')
$Precedence = @('security_threat_baseline', 'mandatory_safety_restriction', 'essential_services', 'emergency_parent_action', 'temporary_override', 'active_mode', 'recurring_schedule', 'default_family_policy')
$OverlayOrder = @('STUDY', 'ALLOW_SOCIAL', 'PAUSE_ENTERTAINMENT')   # deterministic final tie-break only

# ------------------------------------------------------------ configuration validation (fail closed)
function Get-Effects($node) { @($node.effects | ForEach-Object { "$($_.category):$($_.action)" } | Sort-Object) }
function Test-Config($cfg, $baseline, $reg) {
    $v = [Collections.Generic.List[string]]::new()
    $ok = Test-Json -Json ($cfg | ConvertTo-Json -Depth 30) -SchemaFile $P.schema -ErrorAction SilentlyContinue
    if (-not $ok) { $v.Add('SCHEMA: modes config does not conform to modes.schema.json') }
    if (-not (@($reg.tenants | Where-Object { $_.tenant_id -eq $cfg.tenant_id -and $_.status -eq 'ACTIVE' }).Count -eq 1)) { $v.Add('TENANT: config tenant is not an ACTIVE registry tenant') }
    if ($cfg.tenant_id -ne $baseline.tenant_id -or $cfg.baseline_policy_id -ne $baseline.policy_id) { $v.Add('BASELINE: config is not bound to the ST-POL-001 baseline of the same tenant') }
    if ((@($cfg.precedence) -join '>') -ne ($Precedence -join '>')) { $v.Add('PRECEDENCE: layer order differs from ARCHITECTURE §10.4') }
    foreach ($k in $Approved.Keys) {
        $kind, $name = $k -split ':'
        $node = if ($kind -eq 'mode') { $cfg.persistent_modes.$name } else { $cfg.temporary_overlays.$name }
        if (-not $node) { $v.Add("SEMANTICS: $k missing"); continue }
        if ((Get-Effects $node) -join ',' -ne ($Approved[$k] -join ',')) { $v.Add("SEMANTICS: $k effects differ from PO-approved semantics") }
    }
    foreach ($o in @($cfg.temporary_overlays.PSObject.Properties.Name)) { if ("overlay:$o" -notin $Approved.Keys) { $v.Add("SEMANTICS: unknown overlay $o") } }
    if ((@($cfg.temporary_overlays.ALLOW_SOCIAL.may_override | Sort-Object) -join ',') -ne (($ApprovedAllowSocialOverride | Sort-Object) -join ',')) { $v.Add('SEMANTICS: ALLOW_SOCIAL may override only RESTRICTED or STUDY') }
    foreach ($o in 'STUDY', 'PAUSE_ENTERTAINMENT') { if (@($cfg.temporary_overlays.$o.may_override).Count) { $v.Add("SEMANTICS: $o may not override anything") } }
    # every opposing overlay pair on a category needs exactly one explicit, consistent conflict rule
    $types = @($cfg.temporary_overlays.PSObject.Properties.Name | Sort-Object)
    foreach ($cat in $cfg.leisure_categories) {
        for ($i = 0; $i -lt $types.Count; $i++) { for ($j = $i + 1; $j -lt $types.Count; $j++) {
            $a = $types[$i]; $b = $types[$j]
            $ea = @($cfg.temporary_overlays.$a.effects | Where-Object category -eq $cat).action
            $eb = @($cfg.temporary_overlays.$b.effects | Where-Object category -eq $cat).action
            if ($ea -and $eb -and $ea -ne $eb) {
                $rules = @($cfg.conflict_rules | Where-Object { $_.category -eq $cat -and (@($_.between | Sort-Object) -join ',') -eq ((@($a, $b) | Sort-Object) -join ',') })
                if ($rules.Count -ne 1) { $v.Add("CONFLICT: $a vs $b on $cat has $($rules.Count) declared winners (exactly 1 required)"); continue }
                $w = $rules[0].winner; $l = @($a, $b) | Where-Object { $_ -ne $w }
                $wAction = @($cfg.temporary_overlays.$w.effects | Where-Object category -eq $cat).action
                if ($wAction -eq 'ALLOW' -and "overlay:$l" -notin @($cfg.temporary_overlays.$w.may_override)) { $v.Add("CONFLICT: $w wins over $l on $cat without may_override authorization") }
            }
        } }
    }
    $json = $cfg | ConvertTo-Json -Depth 30 -Compress
    if ($json -match '(?i)(cloudflare|gateway|dns\.|security_category|content_category|wirefilter|provider_|rule_id|category_id|profile_id)') { $v.Add('PROVIDER-LEAK: provider syntax or identifier in domain intent') }
    if ($json -match '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}') { $v.Add('PROVIDER-LEAK: UUID in domain intent') }
    if (($json -replace '"modes_contract_version":1', '') -match ':\s*-?\d+\s*[,}\]]') { $v.Add('PROVIDER-LEAK: numeric identifier in domain intent') }
    , $v.ToArray()
}

# Essential Services contract: may exempt ordinary leisure categories only (catalog population is out of scope).
function Test-EssentialContract($es, $cfg) {
    $v = [Collections.Generic.List[string]]::new()
    foreach ($x in @($es.exempt_from)) { if ($x -and $x -notin $cfg.leisure_categories) { $v.Add("ESSENTIAL: cannot exempt from $x (only leisure categories)") } }
    , $v.ToArray()
}

# ------------------------------------------------------------ state validation
function Test-State($state, $cfg) {
    $v = [Collections.Generic.List[string]]::new()
    $allowed = @('tenant_id', 'scope', 'persistent_mode', 'overlays')
    foreach ($p in $state.PSObject.Properties.Name) { if ($p -notin $allowed) { $v.Add("STATE: unexpected field '$p' (no device/family selectors before enrollment)") } }
    if ($state.tenant_id -ne $cfg.tenant_id) { $v.Add('STATE: tenant mismatch') }
    if ($state.scope -ne 'tenant') { $v.Add("SCOPE: state scope '$($state.scope)' rejected; only tenant scope exists before enrollment") }
    if ($state.persistent_mode -notin @('STANDARD', 'RESTRICTED')) { $v.Add("STATE: unknown persistent mode '$($state.persistent_mode)'") }
    foreach ($o in @($state.overlays)) {
        if (-not $o) { continue }
        if ($o.overlay_id -notmatch '^ovl_[0-9A-HJKMNP-TV-Z]{26}$') { $v.Add('STATE: overlay_id must be an internal ovl_ ULID') }
        if ($o.type -eq 'CLEAR_TEMPORARY') { $v.Add('STATE: CLEAR_TEMPORARY is an action, not an overlay'); continue }
        if (-not $cfg.temporary_overlays.($o.type)) { $v.Add("STATE: unknown overlay type '$($o.type)'"); continue }
        if (-not $o.activated_at) { $v.Add("STATE: overlay $($o.type) has no activated_at") }
        if (-not $o.expires_at) { $v.Add("STATE: overlay $($o.type) is unbounded (no expires_at)"); continue }
        if ((T $o.expires_at) -le (T $o.activated_at)) { $v.Add("STATE: overlay $($o.type) expires_at must be after activated_at") }
    }
    , $v.ToArray()
}

# ------------------------------------------------------------ composition
function Get-Winner($cands) { @($cands | Sort-Object @{ e = { (T $_.expires_at).UtcTicks }; Descending = $true }, @{ e = { [array]::IndexOf($OverlayOrder, $_.type) } }, overlay_id)[0] }
function Get-Conflict($cfg, $cat, $a, $b) {
    @($cfg.conflict_rules | Where-Object { $_.category -eq $cat -and (@($_.between | Sort-Object) -join ',') -eq ((@($a, $b) | Sort-Object) -join ',') })
}
function Invoke-Compose($cfg, $baseline, $state, [string]$At, $Schedules = @()) {
    $errs = Test-State $state $cfg
    if ($errs.Count) { throw "STATE INVALID: $($errs -join '; ')" }
    $atTime = T $At
    $mode = $state.persistent_mode
    $active = @($state.overlays | Where-Object { $_ -and (T $_.activated_at) -le $atTime -and $atTime -lt (T $_.expires_at) } | Sort-Object overlay_id)
    $expired = @($state.overlays | Where-Object { $_ -and $atTime -ge (T $_.expires_at) } | Sort-Object overlay_id)
    $decisions = [Collections.Generic.List[object]]::new()
    foreach ($c in @($baseline.controls | Sort-Object control)) {
        $decisions.Add([pscustomobject]@{ category = $c.control; decision = $c.action; source = $c.layer; source_ref = $baseline.policy_id
            overridden = @(); expires_at = $null; next_change_at = $null; overridable = $false; essential_services = 'cannot_bypass' })
    }
    foreach ($cat in $cfg.leisure_categories) {
        $modeEff = @($cfg.persistent_modes.$mode.effects | Where-Object category -eq $cat)[0]
        $modeCand = if ($modeEff) { [pscustomobject]@{ source = 'active_mode'; source_ref = "mode:$mode"; action = $modeEff.action } } else { $null }
        $ov = foreach ($o in $active) { $e = @($cfg.temporary_overlays.($o.type).effects | Where-Object category -eq $cat)[0]; if ($e) { [pscustomobject]@{ type = $o.type; overlay_id = $o.overlay_id; action = $e.action; expires_at = $o.expires_at } } }
        $ov = @($ov)
        $blocks = @($ov | Where-Object action -eq 'BLOCK'); $allows = @($ov | Where-Object action -eq 'ALLOW')
        $schedEff = @($Schedules | Where-Object category -eq $cat)[0]
        $res = $null; $overridden = @()
        if ($ov.Count) {
            $allowWins = $false
            if ($allows.Count) {
                $allowWins = $true
                foreach ($b in $blocks) { foreach ($a in $allows) {
                    if ($a.type -eq $b.type) { continue }
                    $r = Get-Conflict $cfg $cat $a.type $b.type
                    if ($r.Count -ne 1) { throw "AMBIGUOUS: no single declared winner for $($a.type) vs $($b.type) on $cat" }
                    if ($r[0].winner -ne $a.type) { $allowWins = $false }
                } }
            }
            if ($allowWins) {
                $w = Get-Winner $allows
                $permitted = (-not $modeCand) -or $modeCand.action -eq 'ALLOW' -or ($modeCand.source_ref -in @($cfg.temporary_overlays.($w.type).may_override))
                if ($permitted) {
                    $res = [pscustomobject]@{ decision = 'ALLOW'; source = 'temporary_override'; source_ref = "overlay:$($w.type)"; overlay_id = $w.overlay_id; expires_at = $w.expires_at }
                    $overridden = @($blocks | ForEach-Object { "overlay:$($_.type)" }) + @($(if ($modeCand -and $modeCand.action -eq 'BLOCK') { $modeCand.source_ref }))
                } else {
                    $res = [pscustomobject]@{ decision = $modeCand.action; source = 'active_mode'; source_ref = $modeCand.source_ref; overlay_id = $null; expires_at = $null }
                    $overridden = @("overlay:$($w.type) (not authorized to override $($modeCand.source_ref))")
                }
            } else {
                $w = Get-Winner $blocks
                $res = [pscustomobject]@{ decision = 'BLOCK'; source = 'temporary_override'; source_ref = "overlay:$($w.type)"; overlay_id = $w.overlay_id; expires_at = $w.expires_at }
                $overridden = @($allows | ForEach-Object { "overlay:$($_.type)" }) + @($blocks | Where-Object { $_.overlay_id -ne $w.overlay_id } | ForEach-Object { "overlay:$($_.type) (superseded, same action)" }) + @($(if ($modeCand) { "$($modeCand.source_ref) (superseded)" }))
            }
        } elseif ($modeCand) {
            $res = [pscustomobject]@{ decision = $modeCand.action; source = 'active_mode'; source_ref = $modeCand.source_ref; overlay_id = $null; expires_at = $null }
            if ($schedEff) { $overridden = @('recurring_schedule (lower precedence)') }
        } elseif ($schedEff) {
            $res = [pscustomobject]@{ decision = $schedEff.action; source = 'recurring_schedule'; source_ref = 'schedule:contract-boundary'; overlay_id = $null; expires_at = $null }
        } else {
            $res = [pscustomobject]@{ decision = 'ALLOW'; source = 'default_family_policy'; source_ref = 'default'; overlay_id = $null; expires_at = $null }
        }
        $touching = @($ov | ForEach-Object { T $_.expires_at } | Sort-Object)
        $decisions.Add([pscustomobject]@{ category = $cat; decision = $res.decision; source = $res.source; source_ref = $res.source_ref
            overridden = @($overridden | Where-Object { $_ }); expires_at = $res.expires_at; next_change_at = $(if ($touching.Count) { Fmt $touching[0] } else { $null })
            overridable = $true; essential_services = $(if ($res.decision -eq 'BLOCK') { 'declared_essential_services_allowed' } else { 'n/a' }) })
    }
    [pscustomobject]@{
        tenant_id = $cfg.tenant_id; evaluated_at = Fmt $atTime; persistent_mode = $mode; underlying_persistent_mode = $mode
        active_overlays = @($active | ForEach-Object { [pscustomobject]@{ overlay_id = $_.overlay_id; type = $_.type; expires_at = $_.expires_at } })
        expired_overlays_ignored = @($expired.overlay_id)
        decisions = $decisions.ToArray(); state = 'DESIRED'
    }
}
function Invoke-ClearTemporary($state) {
    $n = Copy-Deep $state; $n.overlays = @(); $n
}
# Request-level explanation (Essential Services interaction): categories are SETOK semantic keys.
function Get-RequestDecision($eff, $request) {
    $byCat = @{}; foreach ($d in $eff.decisions) { $byCat[$d.category] = $d }
    foreach ($c in @($request.categories)) { $d = $byCat[$c]; if ($d -and $d.source -eq 'security_threat_baseline') { return [pscustomobject]@{ decision = 'BLOCK'; reason = 'security_threat_baseline'; control = $c } } }
    foreach ($c in @($request.categories)) { $d = $byCat[$c]; if ($d -and $d.source -eq 'mandatory_safety_restriction' -and $d.decision -eq 'BLOCK') { return [pscustomobject]@{ decision = 'BLOCK'; reason = 'mandatory_safety_restriction'; control = $c } } }
    $leisureBlock = @($request.categories | Where-Object { $byCat[$_] -and $byCat[$_].overridable -and $byCat[$_].decision -eq 'BLOCK' })
    if ($request.essential -and $leisureBlock.Count) { return [pscustomobject]@{ decision = 'ALLOW'; reason = 'essential_services'; control = $leisureBlock[0]; overrode = $byCat[$leisureBlock[0]].source_ref } }
    if ($leisureBlock.Count) { return [pscustomobject]@{ decision = 'BLOCK'; reason = $byCat[$leisureBlock[0]].source; control = $leisureBlock[0] } }
    [pscustomobject]@{ decision = 'ALLOW'; reason = 'no_restriction'; control = $null }
}

# ------------------------------------------------------------ compilation (APPLY_BLOCKED, fail closed)
function Resolve-Cat($disc, $parent, $name) {
    $h = @($disc.categories | Where-Object { $_.name -eq $name -and $_.parent -eq $parent })
    if ($h.Count -ne 1) { throw "UNRESOLVED: provider category '$parent/$name' matched $($h.Count) times" }
    $h[0]
}
function Invoke-CompilePlan($eff, $baseline, $adapter, $adapterM, $disc, $reg) {
    $warn = [Collections.Generic.List[string]]::new()
    $ids = { param($sel, $controls) foreach ($k in $controls) { $m = $adapter.mappings.$k; if (-not $m) { throw "UNRESOLVED: no baseline mapping for $k" }
            if ($m.kind -eq 'parent_category') { $h = @($disc.categories | Where-Object { $_.name -eq $m.name -and $null -eq $_.parent }); if ($h.Count -ne 1) { throw "UNRESOLVED: $k" }; $h[0] } else { Resolve-Cat $disc $m.parent $m.name } } }
    $threat = @(& $ids 'sec' @('threat.command_and_control', 'threat.malware', 'threat.phishing'))
    $content = @(& $ids 'cnt' @('content.adult', 'content.gambling'))
    $search = Resolve-Cat $disc $adapterM.baseline_rule_scoping.'search.safe_search'.parent $adapterM.baseline_rule_scoping.'search.safe_search'.name
    $yt = @($adapterM.baseline_rule_scoping.'video.youtube_restricted'.domains)
    if (-not $yt.Count) { throw 'UNRESOLVED: YouTube Restricted target domains' }
    $blockedLeisure = @($eff.decisions | Where-Object { $_.overridable -and $_.decision -eq 'BLOCK' } | Sort-Object category)
    $leisureIds = foreach ($d in $blockedLeisure) {
        $maps = @($adapterM.leisure_mappings.($d.category)); if (-not $maps.Count) { throw "UNRESOLVED: no leisure mapping for $($d.category)" }
        foreach ($m in $maps) { $c = Resolve-Cat $disc $m.parent $m.name; if ($c.class -eq 'premium') { $warn.Add("ENTITLEMENT: $($d.category) -> '$($m.name)' is premium-class") }; $c }
    }
    foreach ($c in @($content)) { if ($c.class -eq 'premium') { $warn.Add("ENTITLEMENT: baseline '$($c.name)' is premium-class") } }
    $excl = ' and not any(dns.security_category[*] in {' + ((@($threat.id) | Sort-Object) -join ' ') + '}) and not any(dns.content_category[*] in {' + ((@($content.id) | Sort-Object) -join ' ') + '})'
    $rules = @(
        [pscustomobject]@{ key = 'baseline-threats'; action = 'block'; traffic = 'any(dns.security_category[*] in {' + ((@($threat.id) | Sort-Object) -join ' ') + '})'; source = 'security_threat_baseline' }
        [pscustomobject]@{ key = 'baseline-content'; action = 'block'; traffic = 'any(dns.content_category[*] in {' + ((@($content.id) | Sort-Object) -join ' ') + '})'; source = 'mandatory_safety_restriction' }
        [pscustomobject]@{ key = 'essential-services-allow'; action = 'allow'; traffic = '<essential catalog: empty, rule omitted>' + $excl; source = 'essential_services'; omitted = $true }
        [pscustomobject]@{ key = 'leisure-block'; action = 'block'; source = 'effective_leisure_decision'; omitted = ($blockedLeisure.Count -eq 0)
            traffic = $(if ($blockedLeisure.Count) { 'any(dns.content_category[*] in {' + ((@($leisureIds.id) | Sort-Object -Unique) -join ' ') + '})' } else { '<no leisure category blocked>' })
            categories = @($blockedLeisure.category); valid_until = @($blockedLeisure | ForEach-Object { $_.next_change_at } | Where-Object { $_ } | Sort-Object)[0] }
        [pscustomobject]@{ key = 'baseline-safe-search'; action = 'safesearch'; traffic = "any(dns.content_category[*] in {$($search.id)})"; source = 'mandatory_safety_restriction' }
        [pscustomobject]@{ key = 'baseline-youtube-restricted'; action = 'ytrestricted'; traffic = 'any(dns.domains[*] in {' + (($yt | Sort-Object | ForEach-Object { '"' + $_ + '"' }) -join ' ') + '})'; source = 'mandatory_safety_restriction' }
    )
    $i = 0; foreach ($r in $rules) { $i++; $r | Add-Member -NotePropertyName order -NotePropertyValue $i }
    $devices = @($reg.bindings | Where-Object { $_.tenant_id -eq $eff.tenant_id -and $_.binding_type -eq 'device_enrollment' -and $_.status -eq 'ACTIVE' })
    $blockers = @('NO_ENROLLED_DEVICE_BINDING', 'SAFE_SELECTOR_NOT_PROVEN', 'PROVIDER_MUTATION_NOT_AUTHORIZED', 'PROVIDER_ORDERING_SEMANTICS_UNVERIFIED_ON_DEVICE')
    if ($warn.Count) { $blockers += 'PLAN_ENTITLEMENT_UNVERIFIED' }
    [pscustomobject]@{
        tenant_id = $eff.tenant_id; for_effective_at = $eff.evaluated_at; persistent_mode = $eff.persistent_mode
        desired_state = 'DESIRED'; compile_state = 'COMPILED'; apply_status = 'APPLY_BLOCKED'; apply_blockers = $blockers
        scope = [pscustomobject]@{ requested = 'all_device_subjects_of_tenant'; resolved_device_subjects = $devices.Count; identity_selector = $null; global_rule = $false }
        rules = $rules; warnings = @($warn | Sort-Object -Unique)
    }
}
function Test-Plan($plan, $adapterM) {
    $v = [Collections.Generic.List[string]]::new()
    if ($plan.apply_status -ne 'APPLY_BLOCKED' -or ($plan | ConvertTo-Json -Depth 20 -Compress) -match '"APPLIED"') { $v.Add('PLAN: must be APPLY_BLOCKED and never APPLIED') }
    if ($plan.scope.global_rule -or $plan.scope.identity_selector) { $v.Add('PLAN: global rule or invented selector') }
    $keys = @($plan.rules | Sort-Object order | ForEach-Object key)
    if (($keys -join ',') -ne (@($adapterM.rule_order) -join ',')) { $v.Add('PLAN: rule order differs from the adapter ordering invariant') }
    $firstAllow = @($plan.rules | Where-Object action -eq 'allow' | ForEach-Object order | Sort-Object)[0]
    foreach ($r in $plan.rules | Where-Object { $_.key -in 'baseline-threats', 'baseline-content' }) { if ($firstAllow -and $r.order -gt $firstAllow) { $v.Add("PLAN: $($r.key) must precede every allow rule") } }
    $ea = @($plan.rules | Where-Object key -eq 'essential-services-allow')[0]
    if ($ea -and $ea.traffic -notmatch 'not any\(dns\.security_category' ) { $v.Add('PLAN: essential allow must exclude threat categories') }
    , $v.ToArray()
}

# ------------------------------------------------------------ fixtures (fixed timestamps)
$baseline = Read-Json $P.baseline; $cfg = Read-Json $P.modes; $reg = Read-Json $P.registry
$adapter = Read-Json $P.adapter; $adapterM = Read-Json $P.adapterM; $disc = Read-Json $P.discovery
$tenant = $cfg.tenant_id
$baselineHashAtStart = (Get-FileHash $P.baseline).Hash
$T0 = '2026-11-02T15:00:00Z'
function St($mode, $ovs) { [pscustomobject]@{ tenant_id = $tenant; scope = 'tenant'; persistent_mode = $mode; overlays = @($ovs) } }
function Ov($id, $type, $from, $to) { [pscustomobject]@{ overlay_id = $id; type = $type; activated_at = $from; expires_at = $to } }
$oSocial = Ov 'ovl_01M60000000000000000000001' 'ALLOW_SOCIAL' '2026-11-02T15:00:00Z' '2026-11-02T15:30:00Z'
$oStudy  = Ov 'ovl_01M60000000000000000000002' 'STUDY'        '2026-11-02T15:00:00Z' '2026-11-02T16:00:00Z'
$oPause  = Ov 'ovl_01M60000000000000000000003' 'PAUSE_ENTERTAINMENT' '2026-11-02T15:00:00Z' '2026-11-02T15:45:00Z'
$oStudy2 = Ov 'ovl_01M60000000000000000000004' 'STUDY'        '2026-11-02T15:20:00Z' '2026-11-02T17:00:00Z'

$scenarios = [ordered]@{
    'S01 STANDARD'                                       = @{ s = (St 'STANDARD' @()); at = $T0; expect = @{ social_media = 'ALLOW/default_family_policy'; gaming = 'ALLOW/default_family_policy'; entertainment_streaming = 'ALLOW/default_family_policy' } }
    'S02 RESTRICTED'                                     = @{ s = (St 'RESTRICTED' @()); at = $T0; expect = @{ social_media = 'BLOCK/mode:RESTRICTED'; gaming = 'BLOCK/mode:RESTRICTED'; entertainment_streaming = 'BLOCK/mode:RESTRICTED' } }
    'S03 RESTRICTED + ALLOW_SOCIAL (active)'             = @{ s = (St 'RESTRICTED' @($oSocial)); at = '2026-11-02T15:10:00Z'; expect = @{ social_media = 'ALLOW/overlay:ALLOW_SOCIAL'; gaming = 'BLOCK/mode:RESTRICTED'; entertainment_streaming = 'BLOCK/mode:RESTRICTED' } }
    'S04 RESTRICTED + ALLOW_SOCIAL (at expiry)'          = @{ s = (St 'RESTRICTED' @($oSocial)); at = '2026-11-02T15:30:00Z'; expect = @{ social_media = 'BLOCK/mode:RESTRICTED'; gaming = 'BLOCK/mode:RESTRICTED'; entertainment_streaming = 'BLOCK/mode:RESTRICTED' } }
    'S05 STANDARD + STUDY (active)'                      = @{ s = (St 'STANDARD' @($oStudy)); at = '2026-11-02T15:05:00Z'; expect = @{ social_media = 'BLOCK/overlay:STUDY'; gaming = 'BLOCK/overlay:STUDY'; entertainment_streaming = 'BLOCK/overlay:STUDY' } }
    'S06 STANDARD + STUDY (expired)'                     = @{ s = (St 'STANDARD' @($oStudy)); at = '2026-11-02T16:00:00Z'; expect = @{ social_media = 'ALLOW/default_family_policy'; gaming = 'ALLOW/default_family_policy'; entertainment_streaming = 'ALLOW/default_family_policy' } }
    'S07 STANDARD + STUDY + ALLOW_SOCIAL'                = @{ s = (St 'STANDARD' @($oStudy, $oSocial)); at = '2026-11-02T15:15:00Z'; expect = @{ social_media = 'ALLOW/overlay:ALLOW_SOCIAL'; gaming = 'BLOCK/overlay:STUDY'; entertainment_streaming = 'BLOCK/overlay:STUDY' } }
    'S08 STUDY + ALLOW_SOCIAL after social expiry'       = @{ s = (St 'STANDARD' @($oStudy, $oSocial)); at = '2026-11-02T15:40:00Z'; expect = @{ social_media = 'BLOCK/overlay:STUDY'; gaming = 'BLOCK/overlay:STUDY'; entertainment_streaming = 'BLOCK/overlay:STUDY' } }
    'S09 RESTRICTED + PAUSE + ALLOW_SOCIAL'              = @{ s = (St 'RESTRICTED' @($oPause, $oSocial)); at = '2026-11-02T15:10:00Z'; expect = @{ social_media = 'BLOCK/overlay:PAUSE_ENTERTAINMENT'; gaming = 'BLOCK/overlay:PAUSE_ENTERTAINMENT'; entertainment_streaming = 'BLOCK/overlay:PAUSE_ENTERTAINMENT' } }
    'S10 overlapping STUDY+STUDY+PAUSE, latest wins'     = @{ s = (St 'STANDARD' @($oStudy, $oPause, $oStudy2)); at = '2026-11-02T15:30:00Z'; expect = @{ social_media = 'BLOCK/overlay:STUDY'; gaming = 'BLOCK/overlay:STUDY'; entertainment_streaming = 'BLOCK/overlay:STUDY' } }
    'S11 overlapping, after first STUDY/PAUSE expiry'    = @{ s = (St 'STANDARD' @($oStudy, $oPause, $oStudy2)); at = '2026-11-02T16:30:00Z'; expect = @{ social_media = 'BLOCK/overlay:STUDY'; gaming = 'BLOCK/overlay:STUDY'; entertainment_streaming = 'BLOCK/overlay:STUDY' } }
    'S12 overlay not yet active'                         = @{ s = (St 'STANDARD' @($oStudy2)); at = '2026-11-02T15:10:00Z'; expect = @{ social_media = 'ALLOW/default_family_policy'; gaming = 'ALLOW/default_family_policy'; entertainment_streaming = 'ALLOW/default_family_policy' } }
}

$results = [Collections.Generic.List[object]]::new()
function Add-Result($group, $name, $expected, $got, $detail = $null) { $results.Add([pscustomobject]@{ group = $group; test = $name; expected = "$expected"; got = "$got"; ok = ("$expected" -eq "$got"); detail = $detail }) }

# Config and baseline non-regression
$cfgErrors = Test-Config $cfg $baseline $reg
Add-Result 'schema/semantics' 'approved modes config validates (schema, tenant, precedence, exact PO semantics, conflicts, provider-neutral)' 'PASS' $(if ($cfgErrors.Count) { 'FAIL' } else { 'PASS' }) $cfgErrors

$effective = [ordered]@{}; $plans = [ordered]@{}
foreach ($k in $scenarios.Keys) {
    $sc = $scenarios[$k]
    $eff = Invoke-Compose $cfg $baseline $sc.s $sc.at
    $effective[$k] = $eff
    foreach ($cat in $sc.expect.Keys) {
        $d = @($eff.decisions | Where-Object category -eq $cat)[0]
        $got = "$($d.decision)/$(if ($d.source -in 'default_family_policy') { $d.source } else { $d.source_ref })"
        Add-Result 'composition' "$k :: $cat" $sc.expect[$cat] $got
    }
    $bl = @($eff.decisions | Where-Object { -not $_.overridable })
    $blOk = ($bl.Count -eq 7) -and -not (@($bl | Where-Object { $_.decision -ne @($baseline.controls | Where-Object control -eq $_.category)[0].action }).Count)
    Add-Result 'baseline-non-regression' "$k :: 7 baseline controls unchanged" 'True' $blOk
    $plan = Invoke-CompilePlan $eff $baseline $adapter $adapterM $disc $reg
    $plans[$k] = $plan
    $pv = Test-Plan $plan $adapterM
    Add-Result 'compilation' "$k :: plan COMPILED/APPLY_BLOCKED and ordering invariants" 'PASS' $(if ($pv.Count) { 'FAIL' } else { 'PASS' }) $pv
}
# overridden/expiry explanation spot checks
$d3 = @($effective['S03 RESTRICTED + ALLOW_SOCIAL (active)'].decisions | Where-Object category -eq 'social_media')[0]
Add-Result 'explanation' 'S03 social explains overridden RESTRICTED, expiry and underlying mode' 'mode:RESTRICTED|2026-11-02T15:30:00Z|RESTRICTED' "$($d3.overridden -join ',')|$($d3.expires_at)|$($effective['S03 RESTRICTED + ALLOW_SOCIAL (active)'].underlying_persistent_mode)"
$d9 = @($effective['S09 RESTRICTED + PAUSE + ALLOW_SOCIAL'].decisions | Where-Object category -eq 'social_media')[0]
Add-Result 'conflict' 'S09 ALLOW_SOCIAL listed as overridden by PAUSE_ENTERTAINMENT' 'True' ($d9.overridden -contains 'overlay:ALLOW_SOCIAL')
$d10 = @($effective['S10 overlapping STUDY+STUDY+PAUSE, latest wins'].decisions | Where-Object category -eq 'gaming')[0]
Add-Result 'conflict' 'S10 winner is the latest-expiring overlay instance' 'ovl_01M60000000000000000000004|2026-11-02T17:00:00Z' "$(@($effective['S10 overlapping STUDY+STUDY+PAUSE, latest wins'].active_overlays | Where-Object expires_at -eq $d10.expires_at)[0].overlay_id)|$($d10.expires_at)"
Add-Result 'conflict' 'S10 conflict order independent of overlay input order' ((Invoke-Compose $cfg $baseline (St 'STANDARD' @($oStudy, $oPause, $oStudy2)) '2026-11-02T15:30:00Z' | ConvertTo-Json -Depth 20 -Compress) -eq (Invoke-Compose $cfg $baseline (St 'STANDARD' @($oStudy2, $oStudy, $oPause)) '2026-11-02T15:30:00Z' | ConvertTo-Json -Depth 20 -Compress)) 'True'

# CLEAR_TEMPORARY
foreach ($pair in @(@('S07', (St 'STANDARD' @($oStudy, $oSocial)), 'STANDARD'), @('S03', (St 'RESTRICTED' @($oSocial)), 'RESTRICTED'))) {
    $before = $pair[1]; $after = Invoke-ClearTemporary $before
    $effA = Invoke-Compose $cfg $baseline $after '2026-11-02T15:15:00Z'
    $plain = Invoke-Compose $cfg $baseline (St $pair[2] @()) '2026-11-02T15:15:00Z'
    Add-Result 'clear-temporary' "CLEAR_TEMPORARY on $($pair[0]) restores $($pair[2]) immediately" 'True' (($effA.decisions | ConvertTo-Json -Depth 10 -Compress) -eq ($plain.decisions | ConvertTo-Json -Depth 10 -Compress))
    Add-Result 'clear-temporary' "CLEAR_TEMPORARY on $($pair[0]) keeps persistent mode, baseline and schedules" 'True' (($after.persistent_mode -eq $before.persistent_mode) -and (@($after.overlays).Count -eq 0) -and ((Get-FileHash $P.baseline).Hash -eq $baselineHashAtStart) -and (@($cfg.recurring_schedules).Count -eq 0))
}

# Essential Services interaction
$effR = $effective['S02 RESTRICTED']; $effStudy = $effective['S05 STANDARD + STUDY (active)']
foreach ($e in @(
    @{ n = 'essential social service under RESTRICTED'; eff = $effR; req = @{ categories = @('social_media'); essential = $true }; x = 'ALLOW/essential_services' }
    @{ n = 'essential streaming service under STUDY'; eff = $effStudy; req = @{ categories = @('entertainment_streaming'); essential = $true }; x = 'ALLOW/essential_services' }
    @{ n = 'essential service categorized phishing'; eff = $effStudy; req = @{ categories = @('threat.phishing', 'social_media'); essential = $true }; x = 'BLOCK/security_threat_baseline' }
    @{ n = 'essential service categorized malware'; eff = $effR; req = @{ categories = @('threat.malware'); essential = $true }; x = 'BLOCK/security_threat_baseline' }
    @{ n = 'essential service categorized C2'; eff = $effR; req = @{ categories = @('threat.command_and_control'); essential = $true }; x = 'BLOCK/security_threat_baseline' }
    @{ n = 'essential service categorized gambling'; eff = $effStudy; req = @{ categories = @('content.gambling'); essential = $true }; x = 'BLOCK/mandatory_safety_restriction' }
    @{ n = 'non-essential social service under RESTRICTED'; eff = $effR; req = @{ categories = @('social_media'); essential = $false }; x = 'BLOCK/active_mode' }
)) { $r = Get-RequestDecision $e.eff ([pscustomobject]$e.req); Add-Result 'essential-services' $e.n $e.x "$($r.decision)/$($r.reason)" }
$esBad = Test-EssentialContract ([pscustomobject]@{ exempt_from = @('social_media', 'threat.malware') }) $cfg
Add-Result 'essential-services' 'Essential Services contract exempting malware -> FAIL' 'FAIL' $(if ($esBad.Count) { 'FAIL' } else { 'PASS' }) $esBad

# Schedule contract boundary (fixture only; config defines no schedules)
$sched = @([pscustomobject]@{ category = 'gaming'; action = 'BLOCK' })
$e1 = Invoke-Compose $cfg $baseline (St 'STANDARD' @()) $T0 $sched
Add-Result 'schedule-boundary' 'schedule block applies under STANDARD (layer 7)' 'BLOCK/recurring_schedule' "$(@($e1.decisions | Where-Object category -eq 'gaming')[0].decision)/$(@($e1.decisions | Where-Object category -eq 'gaming')[0].source)"
$e2 = Invoke-Compose $cfg $baseline (St 'RESTRICTED' @()) $T0 @([pscustomobject]@{ category = 'gaming'; action = 'ALLOW' })
Add-Result 'schedule-boundary' 'schedule allow cannot beat RESTRICTED (layer 6 > 7)' 'BLOCK/active_mode' "$(@($e2.decisions | Where-Object category -eq 'gaming')[0].decision)/$(@($e2.decisions | Where-Object category -eq 'gaming')[0].source)"
$e3 = Invoke-Compose $cfg $baseline (St 'STANDARD' @()) $T0 @([pscustomobject]@{ category = 'threat.malware'; action = 'ALLOW' })
Add-Result 'schedule-boundary' 'schedule cannot touch malware baseline' 'BLOCK' @($e3.decisions | Where-Object category -eq 'threat.malware')[0].decision

# Fail-closed / negative cases (each must FAIL)
$negCfg = [ordered]@{}
$c = Copy-Deep $cfg; $c.persistent_modes.STANDARD.effects = @([pscustomobject]@{ category = 'threat.malware'; action = 'ALLOW' });                    $negCfg['STANDARD attempts to disable malware baseline'] = $c
$c = Copy-Deep $cfg; $c.persistent_modes.RESTRICTED.effects += [pscustomobject]@{ category = 'search.safe_search'; action = 'ALLOW' };                   $negCfg['RESTRICTED attempts to weaken SafeSearch'] = $c
$c = Copy-Deep $cfg; $c.temporary_overlays.ALLOW_SOCIAL.effects += [pscustomobject]@{ category = 'threat.phishing'; action = 'ALLOW' };                 $negCfg['overlay disables phishing'] = $c
$c = Copy-Deep $cfg; $c.temporary_overlays.STUDY.effects += [pscustomobject]@{ category = 'threat.command_and_control'; action = 'ALLOW' };             $negCfg['overlay disables C2'] = $c
$c = Copy-Deep $cfg; $c.temporary_overlays.PAUSE_ENTERTAINMENT.effects += [pscustomobject]@{ category = 'content.adult'; action = 'ALLOW' };            $negCfg['overlay disables adult content'] = $c
$c = Copy-Deep $cfg; $c.temporary_overlays.ALLOW_SOCIAL.effects += [pscustomobject]@{ category = 'content.gambling'; action = 'ALLOW' };                $negCfg['overlay disables gambling'] = $c
$c = Copy-Deep $cfg; $c.temporary_overlays.ALLOW_SOCIAL.effects += [pscustomobject]@{ category = 'video.youtube_restricted'; action = 'ALLOW' };        $negCfg['overlay disables YouTube Restricted'] = $c
$c = Copy-Deep $cfg; $c.temporary_overlays | Add-Member -NotePropertyName PARTY_MODE -NotePropertyValue (Copy-Deep $cfg.temporary_overlays.STUDY);       $negCfg['unknown overlay defined'] = $c
$c = Copy-Deep $cfg; $c.persistent_modes.RESTRICTED | Add-Member -NotePropertyName provider_category -NotePropertyValue 149;                            $negCfg['provider ID inside domain intent'] = $c
$c = Copy-Deep $cfg; $c.notes = 'compiled via dns.content_category 149';                                                                               $negCfg['provider expression inside domain intent'] = $c
$c = Copy-Deep $cfg; $c.conflict_rules = @($c.conflict_rules | Where-Object { $_.winner -ne 'PAUSE_ENTERTAINMENT' });                                  $negCfg['conflicting overlays without a declared winner'] = $c
$c = Copy-Deep $cfg; $c.conflict_rules += Copy-Deep $c.conflict_rules[1]; $c.conflict_rules[-1].winner = 'ALLOW_SOCIAL';                               $negCfg['conflicting overlays with two declared winners'] = $c
$c = Copy-Deep $cfg; $c.temporary_overlays.ALLOW_SOCIAL.may_override += 'overlay:PAUSE_ENTERTAINMENT';                                                 $negCfg['ALLOW_SOCIAL widened beyond approved override set'] = $c
$c = Copy-Deep $cfg; $c.persistent_modes.RESTRICTED.effects = @($c.persistent_modes.RESTRICTED.effects | Where-Object category -ne 'gaming');           $negCfg['RESTRICTED differs from approved semantics'] = $c
$c = Copy-Deep $cfg; $c.temporary_overlays.ALLOW_SOCIAL.effects += [pscustomobject]@{ category = 'gaming'; action = 'ALLOW' };                          $negCfg['ALLOW_SOCIAL affects gaming'] = $c
$c = Copy-Deep $cfg; $c.temporary_overlays.STUDY.requires_expiry = $false;                                                                             $negCfg['overlay contract without required expiry'] = $c
$c = Copy-Deep $cfg; $c.precedence = @($c.precedence[1], $c.precedence[0]) + @($c.precedence[2..7]);                                                  $negCfg['precedence reordered'] = $c
foreach ($k in $negCfg.Keys) { $r = Test-Config $negCfg[$k] $baseline $reg; Add-Result 'fail-closed' $k 'FAIL' $(if ($r.Count) { 'FAIL' } else { 'PASS' }) @($r | Select-Object -First 3) }
$negState = [ordered]@{
    'temporary overlay without expiry'           = (St 'STANDARD' @([pscustomobject]@{ overlay_id = 'ovl_01M60000000000000000000009'; type = 'STUDY'; activated_at = $T0 }))
    'overlay expiry before activation'           = (St 'STANDARD' @(Ov 'ovl_01M6000000000000000000000A' 'STUDY' '2026-11-02T16:00:00Z' '2026-11-02T15:00:00Z'))
    'unknown overlay type in state'              = (St 'STANDARD' @(Ov 'ovl_01M6000000000000000000000B' 'PARTY_MODE' $T0 '2026-11-02T16:00:00Z'))
    'CLEAR_TEMPORARY submitted as overlay'       = (St 'STANDARD' @(Ov 'ovl_01M6000000000000000000000C' 'CLEAR_TEMPORARY' $T0 '2026-11-02T16:00:00Z'))
    'invented device selector'                   = ((St 'RESTRICTED' @()) | Add-Member -NotePropertyName devices -NotePropertyValue @('sub_01M6000000000000000000000D') -PassThru)
    'invented family selector scope'             = ([pscustomobject]@{ tenant_id = $tenant; scope = 'family:other'; persistent_mode = 'STANDARD'; overlays = @() })
    'unknown persistent mode'                    = (St 'PARTY' @())
    'overlay id is not an internal ULID'         = (St 'STANDARD' @(Ov '994b430f-fdf6-4ad9-aa6a-b7564f7133ca' 'STUDY' $T0 '2026-11-02T16:00:00Z'))
}
foreach ($k in $negState.Keys) { $got = try { Invoke-Compose $cfg $baseline $negState[$k] '2026-11-02T15:10:00Z' | Out-Null; 'PASS' } catch { 'FAIL' }; Add-Result 'fail-closed' $k 'FAIL' $got }
$cAmb = Copy-Deep $cfg; $cAmb.conflict_rules = @($cAmb.conflict_rules | Where-Object { $_.winner -ne 'PAUSE_ENTERTAINMENT' })
$got = try { Invoke-Compose $cAmb $baseline (St 'RESTRICTED' @($oPause, $oSocial)) '2026-11-02T15:10:00Z' | Out-Null; 'PASS' } catch { 'FAIL' }
Add-Result 'fail-closed' 'composition refuses nondeterministic overlay conflict at runtime' 'FAIL' $got
$pApplied = Copy-Deep $plans['S02 RESTRICTED']; $pApplied.apply_status = 'APPLIED'
Add-Result 'fail-closed' 'compiled plan marked APPLIED' 'FAIL' $(if ((Test-Plan $pApplied $adapterM).Count) { 'FAIL' } else { 'PASS' })
$pOrder = Copy-Deep $plans['S02 RESTRICTED']; ($pOrder.rules | Where-Object key -eq 'essential-services-allow').order = 0
Add-Result 'fail-closed' 'plan with allow rule before threat baseline' 'FAIL' $(if ((Test-Plan $pOrder $adapterM).Count) { 'FAIL' } else { 'PASS' })
$pGlobal = Copy-Deep $plans['S02 RESTRICTED']; $pGlobal.scope.global_rule = $true
Add-Result 'fail-closed' 'plan with global rule' 'FAIL' $(if ((Test-Plan $pGlobal $adapterM).Count) { 'FAIL' } else { 'PASS' })
$aBad = Copy-Deep $adapterM; $aBad.leisure_mappings.gaming = @([pscustomobject]@{ selector = 'dns.content_category'; parent = 'Entertainment'; name = 'Gaming Consoles' })
$got = try { Invoke-CompilePlan $effective['S02 RESTRICTED'] $baseline $adapter $aBad $disc $reg | Out-Null; 'PASS' } catch { 'FAIL' }
Add-Result 'fail-closed' 'leisure provider category unresolved' 'FAIL' $got

# Determinism: recompute everything from freshly loaded inputs and compare
function Get-AllOutputs {
    $b2 = Read-Json $P.baseline; $c2 = Read-Json $P.modes; $r2 = Read-Json $P.registry; $a2 = Read-Json $P.adapter; $m2 = Read-Json $P.adapterM; $d2 = Read-Json $P.discovery
    $o = [ordered]@{}
    foreach ($k in $scenarios.Keys) { $e = Invoke-Compose $c2 $b2 (Copy-Deep $scenarios[$k].s) $scenarios[$k].at; $o[$k] = [ordered]@{ effective = $e; plan = (Invoke-CompilePlan $e $b2 $a2 $m2 $d2 $r2) } }
    $o
}
$h1 = Get-Sha ((Get-AllOutputs) | ConvertTo-Json -Depth 30 -Compress)
$h2 = Get-Sha ((Get-AllOutputs) | ConvertTo-Json -Depth 30 -Compress)
Add-Result 'determinism' 'composition + compilation identical across repeated runs' 'True' ($h1 -eq $h2) $h1

# Static proof: no network calls at all in this Story script
$src = Get-Content $PSCommandPath -Raw
$net = [regex]::Matches($src, '(?i)Invoke-(Rest' + 'Method|Web' + 'Request)|\bss' + 'h\b|cu' + 'rl ').Count

$fail = @($results | Where-Object { -not $_.ok })
$groupOk = { param($g) -not (@($results | Where-Object { $_.group -in $g -and -not $_.ok }).Count) }
$summary = [pscustomobject]@{
    persistentModes = "$(@($cfg.persistent_modes.PSObject.Properties).Count)/2"; temporaryOverlays = "$(@($cfg.temporary_overlays.PSObject.Properties).Count + @($cfg.actions.PSObject.Properties).Count)/4"
    productSemantics = (& $groupOk 'schema/semantics'); baselineNonRegression = (& $groupOk 'baseline-non-regression'); composition = (& $groupOk 'composition', 'explanation')
    deterministic = (& $groupOk 'determinism'); expirationRestore = (& $groupOk 'composition', 'clear-temporary'); conflictResolution = (& $groupOk 'conflict')
    essentialServices = (& $groupOk 'essential-services'); scheduleBoundary = (& $groupOk 'schedule-boundary'); failClosed = (& $groupOk 'fail-closed'); compilation = (& $groupOk 'compilation')
    outputsSha256 = $h1; networkCallsInScript = $net; providerMutation = $false; claimedApplied = $false
    deviceSubjects = @($reg.subjects | Where-Object subject_type -eq 'device').Count; deviceBindings = @($reg.bindings | Where-Object binding_type -eq 'device_enrollment').Count
    tests = $results.Count; failures = $fail.Count
}
Save-Evidence 'effective-decisions' $effective
Save-Evidence 'compiled-plans' $plans
Save-Evidence 'tests' ([pscustomobject]@{ inputs = [pscustomobject]@{ baseline = (Get-FileHash $P.baseline -Algorithm SHA256).Hash.ToLower(); modes = (Get-FileHash $P.modes -Algorithm SHA256).Hash.ToLower()
    adapter = (Get-FileHash $P.adapter -Algorithm SHA256).Hash.ToLower(); adapterModes = (Get-FileHash $P.adapterM -Algorithm SHA256).Hash.ToLower(); discovery = (Get-FileHash $P.discovery -Algorithm SHA256).Hash.ToLower()
    registry = (Get-FileHash $P.registry -Algorithm SHA256).Hash.ToLower() }; summary = $summary; results = $results })
$results | Format-Table group, test, expected, got, ok -AutoSize
$summary | ConvertTo-Json
if ($fail.Count -or $net -ne 0) { Write-Error "ST-POL-002 FAILED ($($fail.Count) failing tests)"; exit 1 }
'ST-POL-002: PASS (DESIRED / COMPILED / APPLY_BLOCKED; nothing APPLIED)'
