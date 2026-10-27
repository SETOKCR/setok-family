<#
.SYNOPSIS
  ST-CF-002: store the operational inputs outside Git, DPAPI-protected for the current Windows user.

.DESCRIPTION
  Prompts (hidden input) for:
    1. the short-lived Cloudflare API token with Account > Access: Apps and Policies > Edit
       -> %LOCALAPPDATA%\SETOK\setok-family\cloudflare-st-cf-002.token.xml
    2. the real enrollment mailbox for alias family-enrollment-01
       -> %LOCALAPPDATA%\SETOK\setok-family\st-cf-002-enrollment-mailbox.xml
  Neither value is printed or written anywhere else.

  Remove the token after the Story with:  .\Set-StCf002Inputs.ps1 -RemoveToken   (and revoke it in Cloudflare)
#>
[CmdletBinding()]
param([switch]$RemoveToken)

$ErrorActionPreference = 'Stop'
$dir = Join-Path $env:LOCALAPPDATA 'SETOK\setok-family'
$tokenPath = Join-Path $dir 'cloudflare-st-cf-002.token.xml'
$mailPath  = Join-Path $dir 'st-cf-002-enrollment-mailbox.xml'

if ($RemoveToken) {
    if (Test-Path $tokenPath) { Remove-Item $tokenPath -Force; "Removed $tokenPath" } else { 'No ST-CF-002 token stored.' }
    return
}
New-Item -ItemType Directory -Force $dir | Out-Null
$t = Read-Host -AsSecureString 'Paste the ST-CF-002 Cloudflare API token (Access: Apps and Policies Edit; input hidden)'
if ($t.Length -eq 0) { throw 'Empty token; nothing stored.' }
$t | Export-Clixml $tokenPath
$m = Read-Host -AsSecureString 'Type the enrollment mailbox for family-enrollment-01 (input hidden)'
if ($m.Length -eq 0) { throw 'Empty mailbox; nothing stored.' }
$m | Export-Clixml $mailPath
"Stored DPAPI-protected token and mailbox under $dir"
