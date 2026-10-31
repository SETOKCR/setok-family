<#
.SYNOPSIS
  ST-CF-004: store the dedicated android-01 enrollment identity (alias android-01-enrollment) outside Git.

.DESCRIPTION
  Prompts with hidden input and writes the address DPAPI-protected (CurrentUser) to
    %LOCALAPPDATA%\SETOK\setok-family\st-cf-004-android-01-enrollment.xml
  The value is never printed or written anywhere else.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$dir  = Join-Path $env:LOCALAPPDATA 'SETOK\setok-family'
$path = Join-Path $dir 'st-cf-004-android-01-enrollment.xml'
New-Item -ItemType Directory -Force $dir | Out-Null
$m = Read-Host -AsSecureString 'Type the dedicated android-01 enrollment address (input hidden)'
if ($m.Length -eq 0) { throw 'Empty value; nothing stored.' }
$m | Export-Clixml $path
"Stored DPAPI-protected identity at $path"
