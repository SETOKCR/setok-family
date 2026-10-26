<#
.SYNOPSIS
  ST-CF-001: store the Cloudflare API token for this Story outside Git, encrypted for the current Windows user.

.DESCRIPTION
  Prompts for the token as a SecureString (never echoed) and writes it with Export-Clixml.
  On Windows, Export-Clixml protects SecureString values with DPAPI (CurrentUser scope), so the
  file can only be decrypted by the same Windows user on the same machine.

  Location (outside the repository, never versioned):
    %LOCALAPPDATA%\SETOK\setok-family\cloudflare-st-cf-001.token.xml

  Remove with:  .\Set-StCf001Token.ps1 -Remove   (and revoke the token in the Cloudflare dashboard)
#>
[CmdletBinding()]
param([switch]$Remove)

$ErrorActionPreference = 'Stop'
$dir  = Join-Path $env:LOCALAPPDATA 'SETOK\setok-family'
$path = Join-Path $dir 'cloudflare-st-cf-001.token.xml'

if ($Remove) {
    if (Test-Path $path) { Remove-Item $path -Force; "Removed $path" } else { "Nothing to remove." }
    return
}

New-Item -ItemType Directory -Force $dir | Out-Null
$secure = Read-Host -AsSecureString 'Paste the ST-CF-001 Cloudflare API token (input hidden)'
if ($secure.Length -eq 0) { throw 'Empty token; nothing stored.' }
$secure | Export-Clixml -Path $path
"Stored DPAPI-protected token at $path"
