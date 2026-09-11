<#
.SYNOPSIS
  将 ES ABCD 可移植核心安装（叠加）到目标项目根目录。

.DESCRIPTION
  把 ABCD 模块、合同、TaskContextRuntime、最小 AI 辅助与 Skill 目录叠加进现有项目。
  不启动 Unity、不写入凭据、不声称运行时验收通过。
  Windows 可用系统自带 powershell 运行本脚本（不一定需要 pwsh）。

.PARAMETER PackageRoot
  本 es-abcd 仓库根目录（默认：scripts 的上一级）。

.PARAMETER TargetRoot
  接收叠加文件的目标项目根目录。

.PARAMETER Force
  当哈希不一致时覆盖目标文件（用于升级）。

.EXAMPLE
  powershell -File .\scripts\Install-ESABCD.ps1 -TargetRoot <项目根路径>
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

function Get-InstallFileSha256([string]$LiteralPath) {
    # Built-in SHA256 so install works when Get-FileHash is unavailable/shadowed.
    $bytes = [IO.File]::ReadAllBytes($LiteralPath)
    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        return ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-', '').ToLowerInvariant()
    }
    finally { $sha.Dispose() }
}

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
        $srcHash = Get-InstallFileSha256 $f.FullName
        $dstHash = Get-InstallFileSha256 $dst
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
    nextStep = 'powershell -File <package>/scripts/Invoke-ESABCDSmoke.ps1 -ProjectRoot <target>'
    nonClaims = @($manifest.nonClaims)
} | ConvertTo-Json -Depth 6 
