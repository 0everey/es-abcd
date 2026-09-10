<#
.SYNOPSIS
  Install the ES ABCD portable core into a target project root.

.DESCRIPTION
  Overlays ABCD automation modules, contracts, TaskContextRuntime, minimal AI
  support modules, and Skill folders into an existing project. Does not run
  Unity, does not write credentials, and does not claim runtime acceptance.

.PARAMETER PackageRoot
  Root of this es-abcd repository (defaults to parent of /scripts).

.PARAMETER TargetRoot
  Destination project root that will receive the overlay.

.PARAMETER Force
  Replace files that already exist when content hashes differ.

.EXAMPLE
  ./scripts/Install-ESABCD.ps1 -TargetRoot C:\work\MyProject
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$PackageRoot = '',
    [Parameter(Mandatory)][string]$TargetRoot,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if ([string]::IsNullOrWhiteSpace($PackageRoot)) {
    $PackageRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
} else {
    $PackageRoot = (Resolve-Path -LiteralPath $PackageRoot).Path
}
$TargetRoot = [IO.Path]::GetFullPath($TargetRoot)
if (-not (Test-Path -LiteralPath $TargetRoot -PathType Container)) {
    throw "TargetRoot does not exist: $TargetRoot"
}
if ($TargetRoot.TrimEnd('\','/') -ieq $PackageRoot.TrimEnd('\','/')) {
    throw 'TargetRoot must not equal PackageRoot.'
}

$manifestPath = Join-Path $PackageRoot 'package\es-abcd-portable.manifest.json'
if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    throw "Manifest missing: $manifestPath"
}
$manifest = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json

$copied = New-Object System.Collections.Generic.List[string]
$skipped = New-Object System.Collections.Generic.List[string]
$replaced = New-Object System.Collections.Generic.List[string]

function Copy-Rel([string]$Rel) {
    $src = Join-Path $PackageRoot $Rel
    if (-not (Test-Path -LiteralPath $src)) {
        throw "Package path missing: $Rel"
    }
    $items = @(Get-ChildItem -LiteralPath $src -Recurse -File)
    foreach ($f in $items) {
        $rel = $f.FullName.Substring($PackageRoot.Length).TrimStart('\','/').Replace('\','/')
        # Do not overlay package meta into the consumer root as repo docs.
        if ($rel -match '^(README\.md|LICENSE|\.gitignore|docs/|package/|examples/|\.git/)') {
            continue
        }
        $dst = Join-Path $TargetRoot $rel
        $dstDir = Split-Path -Parent $dst
        if (-not (Test-Path -LiteralPath $dstDir)) {
            New-Item -ItemType Directory -Force -Path $dstDir | Out-Null
        }
        if (-not (Test-Path -LiteralPath $dst -PathType Leaf)) {
            if ($PSCmdlet.ShouldProcess($dst, 'copy')) {
                Copy-Item -LiteralPath $f.FullName -Destination $dst -Force
                [void]$copied.Add($rel)
            }
            continue
        }
        $srcHash = (Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash
        $dstHash = (Get-FileHash -LiteralPath $dst -Algorithm SHA256).Hash
        if ($srcHash -eq $dstHash) {
            [void]$skipped.Add($rel)
            continue
        }
        if ($Force) {
            if ($PSCmdlet.ShouldProcess($dst, 'replace')) {
                Copy-Item -LiteralPath $f.FullName -Destination $dst -Force
                [void]$replaced.Add($rel)
            }
        } else {
            [void]$skipped.Add($rel + ' (hash-mismatch; pass -Force to replace)')
        }
    }
}

foreach ($dir in @($manifest.requiredDirectories)) {
    $rel = $dir.Replace('/', '\')
    if ($rel -in @('scripts','docs','package')) { continue }
    Copy-Rel $rel
}

# Consumer marker
$markerDir = Join-Path $TargetRoot 'ES\Automation\ABCD'
if (-not (Test-Path $markerDir)) { New-Item -ItemType Directory -Force -Path $markerDir | Out-Null }
$marker = [ordered]@{
    schemaVersion = 1
    packageId = [string]$manifest.packageId
    installedUtc = [DateTime]::UtcNow.ToString('o')
    packageRoot = $PackageRoot
    targetRoot = $TargetRoot
    businessFree = [bool]$manifest.businessFree
    runtimeStatus = 'not-run'
}
$markerPath = Join-Path $markerDir 'es-abcd-install.receipt.json'
[IO.File]::WriteAllText(
    $markerPath,
    ($marker | ConvertTo-Json -Depth 8),
    [Text.UTF8Encoding]::new($false))

[pscustomobject][ordered]@{
    status = 'installed'
    packageId = [string]$manifest.packageId
    targetRoot = $TargetRoot
    copied = $copied.Count
    replaced = $replaced.Count
    skipped = $skipped.Count
    receipt = $markerPath
    nextStep = 'pwsh -File <package>/scripts/Invoke-ESABCDSmoke.ps1 -ProjectRoot <target>'
    nonClaims = @($manifest.nonClaims)
} | ConvertTo-Json -Depth 6
