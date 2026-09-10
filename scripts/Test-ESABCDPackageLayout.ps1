<#
.SYNOPSIS
  Verify this repository contains the portable ABCD layout.
#>
[CmdletBinding()]
param(
    [string]$PackageRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

$ErrorActionPreference = 'Stop'
$PackageRoot = (Resolve-Path -LiteralPath $PackageRoot).Path
$manifestPath = Join-Path $PackageRoot 'package\es-abcd-portable.manifest.json'
$m = Get-Content $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
$missing = New-Object System.Collections.Generic.List[string]

foreach ($d in @($m.requiredDirectories)) {
    $p = Join-Path $PackageRoot ($d.Replace('/','\'))
    if (-not (Test-Path -LiteralPath $p -PathType Container)) { [void]$missing.Add("dir:$d") }
}
foreach ($f in @($m.anchorFiles)) {
    $p = Join-Path $PackageRoot ($f.Replace('/','\'))
    if (-not (Test-Path -LiteralPath $p -PathType Leaf)) { [void]$missing.Add("file:$f") }
}

# No weapon part in portable OSS package
$weapon = Join-Path $PackageRoot 'ES\Automation\Contracts\es-ai-abc-weapon-part.v1.json'
if (Test-Path $weapon) { [void]$missing.Add('forbidden:weapon-part-present') }

$status = if ($missing.Count) { 'failed' } else { 'passed' }
[pscustomobject][ordered]@{
    status = $status
    packageId = [string]$m.packageId
    missing = @($missing)
} | ConvertTo-Json -Depth 5

if ($status -ne 'passed') { exit 1 }
