<#
.SYNOPSIS
  ST-CF-004: store the short-lived Cloudflare token (Account > Access: Apps and Policies > Edit) outside Git.

.DESCRIPTION
  Prompts with hidden input and writes the token DPAPI-protected (CurrentUser) to
    %LOCALAPPDATA%\SETOK\setok-family\cloudflare-st-cf-004.token.xml
  Paste the token SECRET shown once at creation/roll (about 40-53 characters), not the 32-hex token ID.
  Remove with -Remove after the Stage, and revoke the token in Cloudflare.
#>
[CmdletBinding()]
param([switch]$Remove)

$ErrorActionPreference = 'Stop'
$dir  = Join-Path $env:LOCALAPPDATA 'SETOK\setok-family'
$path = Join-Path $dir 'cloudflare-st-cf-004.token.xml'
if ($Remove) { if (Test-Path $path) { Remove-Item $path -Force; "Removed $path" } else { 'No ST-CF-004 token stored.' }; return }
New-Item -ItemType Directory -Force $dir | Out-Null
$t = Read-Host -AsSecureString 'Paste the ST-CF-004 Cloudflare API token secret (input hidden)'
if ($t.Length -lt 40) { throw "Value has $($t.Length) characters; that looks like a token ID, not the secret. Nothing stored." }
$t | Export-Clixml $path
"Stored DPAPI-protected token at $path"
