# Local one-click wrapper (when you already cloned es-abcd).
# From your app root OR from this repo:
#   powershell -File <es-abcd>\scripts\OneClick-Install.ps1
#   powershell -File <es-abcd>\scripts\OneClick-Install.ps1 -TargetRoot <项目根路径> -Force
[CmdletBinding()]
param(
    [string]$TargetRoot = '',
    [switch]$Force,
    [switch]$SkipSmoke
)
$ErrorActionPreference = 'Stop'
$pkg = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$get = Join-Path $pkg 'get.ps1'
if (-not (Test-Path -LiteralPath $get)) { throw "get.ps1 missing: $get" }
if ([string]::IsNullOrWhiteSpace($TargetRoot)) { $TargetRoot = (Get-Location).Path }
& powershell -NoProfile -ExecutionPolicy Bypass -File $get -TargetRoot $TargetRoot -Force:$Force -SkipSmoke:$SkipSmoke
