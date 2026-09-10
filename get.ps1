# es-abcd one-click bootstrap (remote-friendly)
# Usage (from ANY project root):
#   powershell -NoProfile -ExecutionPolicy Bypass -Command "iex (irm https://raw.githubusercontent.com/0everey/es-abcd/main/get.ps1)"
# Or with explicit target:
#   iex "& { $(irm https://raw.githubusercontent.com/0everey/es-abcd/main/get.ps1) } -TargetRoot 'C:\work\MyApp'"
#
# Local (already cloned):
#   powershell -File .\get.ps1 -TargetRoot .
#
# Design goals:
# - ONE command for first-time users
# - No ESFramework / Unity required
# - Portable governance by default
# - Install + smoke proof; never claim PlayMode

[CmdletBinding()]
param(
    [string]$TargetRoot = '',
    [string]$RepoUrl = 'https://github.com/0everey/es-abcd.git',
    [string]$Branch = 'main',
    [string]$CacheRoot = '',
    [switch]$Force,
    [switch]$SkipSmoke,
    [switch]$SkipCloneUpdate,
    [switch]$SkipChecklist
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$env:ES_ABCD_GOVERNANCE_MODE = 'portable'

function Write-Step([string]$Msg) {
    Write-Host ("[es-abcd] " + $Msg) -ForegroundColor Cyan
}
function Write-Ok([string]$Msg) {
    Write-Host ("[es-abcd] OK  " + $Msg) -ForegroundColor Green
}
function Write-WarnLine([string]$Msg) {
    Write-Host ("[es-abcd] !!  " + $Msg) -ForegroundColor Yellow
}

# Default target = caller's current directory
if ([string]::IsNullOrWhiteSpace($TargetRoot)) {
    $TargetRoot = (Get-Location).Path
}
$TargetRoot = [IO.Path]::GetFullPath($TargetRoot)
if (-not (Test-Path -LiteralPath $TargetRoot -PathType Container)) {
    New-Item -ItemType Directory -Force -Path $TargetRoot | Out-Null
}

if ([string]::IsNullOrWhiteSpace($CacheRoot)) {
    $CacheRoot = Join-Path $env:LOCALAPPDATA 'es-abcd'
}
$CacheRoot = [IO.Path]::GetFullPath($CacheRoot)
$pkg = Join-Path $CacheRoot 'repo'

Write-Host ''
Write-Host '======== es-abcd one-click ========' -ForegroundColor White
Write-Host ('  Target : ' + $TargetRoot)
Write-Host ('  Cache  : ' + $pkg)
Write-Host ('  Mode   : portable (no ESFramework host required)')
Write-Host '==================================' -ForegroundColor White
Write-Host ''

# If this script already lives inside a full es-abcd checkout, prefer it.
$selfRoot = $null
if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
    $maybe = $PSScriptRoot
    $marker = Join-Path $maybe 'package\es-abcd-portable.manifest.json'
    $marker2 = Join-Path $maybe 'ES\Automation\ABCD\ESABCDHome.psm1'
    if ((Test-Path -LiteralPath $marker) -or (Test-Path -LiteralPath $marker2)) {
        $selfRoot = (Resolve-Path -LiteralPath $maybe).Path
    } else {
        $parent = Split-Path -Parent $maybe
        $marker = Join-Path $parent 'package\es-abcd-portable.manifest.json'
        if (Test-Path -LiteralPath $marker) {
            $selfRoot = (Resolve-Path -LiteralPath $parent).Path
        }
    }
}

if ($selfRoot) {
    Write-Step ("using local checkout: " + $selfRoot)
    $pkg = $selfRoot
}
elseif ($SkipCloneUpdate -and (Test-Path (Join-Path $pkg 'package\es-abcd-portable.manifest.json'))) {
    Write-Step 'using cached package (SkipCloneUpdate)'
}
else {
    Write-Step 'ensure git package cache'
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw 'GIT_REQUIRED: install Git for Windows, then retry one-click.'
    }
    New-Item -ItemType Directory -Force -Path $CacheRoot | Out-Null
    if (-not (Test-Path -LiteralPath (Join-Path $pkg '.git'))) {
        Write-Step ("git clone " + $RepoUrl)
        if (Test-Path -LiteralPath $pkg) {
            Remove-Item -LiteralPath $pkg -Recurse -Force
        }
        & git clone --depth 1 --branch $Branch $RepoUrl $pkg
        if ($LASTEXITCODE -ne 0) { throw "GIT_CLONE_FAILED:$LASTEXITCODE" }
    }
    else {
        Write-Step 'git fetch/pull cache'
        Push-Location $pkg
        try {
            & git fetch --depth 1 origin $Branch 2>$null
            & git checkout $Branch 2>$null
            & git pull --ff-only origin $Branch 2>$null
        }
        finally { Pop-Location }
    }
}

$install = Join-Path $pkg 'scripts\Install-ESABCD.ps1'
$smoke = Join-Path $pkg 'scripts\Invoke-ESABCDSmoke.ps1'
$layout = Join-Path $pkg 'scripts\Test-ESABCDPackageLayout.ps1'
foreach ($p in @($install, $smoke, $layout)) {
    if (-not (Test-Path -LiteralPath $p -PathType Leaf)) {
        throw "PACKAGE_INCOMPLETE_MISSING:$p"
    }
}

Write-Step 'layout check'
& powershell -NoProfile -ExecutionPolicy Bypass -File $layout -PackageRoot $pkg
if ($LASTEXITCODE -ne 0) { throw 'LAYOUT_FAILED' }
Write-Ok 'layout'

Write-Step ("install overlay -> " + $TargetRoot)
$installArgs = @{
    PackageRoot = $pkg
    TargetRoot  = $TargetRoot
}
if ($Force) { $installArgs['Force'] = $true }
& powershell -NoProfile -ExecutionPolicy Bypass -File $install @installArgs
if ($LASTEXITCODE -ne 0) { throw 'INSTALL_FAILED' }
Write-Ok 'install'

$smokeReceipt = $null
if (-not $SkipSmoke) {
    Write-Step 'smoke (static; runtime-not-run expected)'
    $smokeOut = & powershell -NoProfile -ExecutionPolicy Bypass -File $smoke -ProjectRoot $TargetRoot -Mode engineering 2>&1 | Out-String
    Write-Host $smokeOut
    if ($LASTEXITCODE -ne 0) { throw 'SMOKE_FAILED' }
    $smokeDir = Join-Path $TargetRoot 'ES\Automation\ABCD\out'
    $latest = Get-ChildItem -LiteralPath $smokeDir -Filter 'smoke-*.json' -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTimeUtc -Descending |
        Select-Object -First 1
    if ($latest) { $smokeReceipt = $latest.FullName }
    Write-Ok 'smoke'
}
else {
    Write-WarnLine 'smoke skipped'
}

# Consumer helper shim for daily use
$shimDir = Join-Path $TargetRoot 'ES\Automation\ABCD'
$shim = Join-Path $shimDir 'Use-ESABCD.ps1'
$shimBody = @'
# Auto-generated by es-abcd one-click. Dot-source this file:
#   . .\ES\Automation\ABCD\Use-ESABCD.ps1
#   Invoke-ESABCDQuick -Requirement "your goal"
$ErrorActionPreference = 'Stop'
$env:ES_ABCD_GOVERNANCE_MODE = 'portable'
Import-Module (Join-Path $PSScriptRoot 'ESABCDHome.psm1') -Force -Global
Import-Module (Join-Path $PSScriptRoot 'ESABCDDivergence.psm1') -Force -Global
Import-Module (Join-Path $PSScriptRoot 'ESABCInnovationRun.psm1') -Force -Global

function Invoke-ESABCDQuick {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Requirement,
        [ValidateSet('engineering','creative-divergence','stable')][string]$Mode = 'engineering',
        [string]$ProjectRoot = ''
    )
    if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
        $here = (Get-Location).Path
        if (Test-Path (Join-Path $here 'ES\Automation\Contracts\es-ai-abc-generation-mode-v1.json')) {
            $ProjectRoot = $here
        } else {
            $ProjectRoot = Get-ESABCDPackageRoot
        }
    }
    $contract = Resolve-ESABCDContractPath -FileName 'es-ai-abc-generation-mode-v1.json' -ProjectRoot $ProjectRoot
    $hash = (Get-FileHash -LiteralPath $contract -Algorithm SHA256).Hash.ToLowerInvariant()
    $div = Invoke-ESABCModeDivergence -Requirement $Requirement -SourceHash $hash -Mode $Mode -ProjectRoot $ProjectRoot
    $sel = Select-ESABCGenerationCandidate -Candidates $div.directions -Mode $Mode
    [pscustomobject]@{
        mode = $Mode
        directionCount = [int]$div.directionCount
        selectedDirectionId = [string]$sel.selectedDirectionId
        selectionStatus = [string]$sel.selectionStatus
        claimLevel = [string]$sel.claimLevel
        candidateSetHash = [string]$div.candidateSetHash
        runtimeStatus = 'runtime-not-run'
        projectRoot = $ProjectRoot
    }
}
'@
[IO.File]::WriteAllText($shim, $shimBody, [Text.UTF8Encoding]::new($false))
Write-Ok ("shim " + $shim)

$checklistJson = $null
$checklistMd = $null
if (-not $SkipChecklist) {
    Write-Step 'adapt checklist'
    $chk = Join-Path $pkg 'scripts\New-ESABCDAdaptChecklist.ps1'
    if (Test-Path -LiteralPath $chk) {
        $chkOut = & powershell -NoProfile -ExecutionPolicy Bypass -File $chk -TargetRoot $TargetRoot -PackageRoot $pkg -OutMarkdown | Out-String
        Write-Host $chkOut
        $chkDir = Join-Path $TargetRoot 'ES\Automation\ABCD\out'
        $j = Get-ChildItem $chkDir -Filter 'adapt-checklist-*.json' -EA SilentlyContinue | Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1
        $m = Get-ChildItem $chkDir -Filter 'adapt-checklist-*.md' -EA SilentlyContinue | Sort-Object LastWriteTimeUtc -Descending | Select-Object -First 1
        if ($j) { $checklistJson = $j.FullName }
        if ($m) { $checklistMd = $m.FullName }
        Write-Ok 'checklist'
    }
    else {
        Write-WarnLine 'checklist script missing; skip'
    }
}

$receipt = [pscustomobject]@{
    schemaVersion = 1
    recordType = 'ESABCDOneClickReceipt'
    status = 'passed'
    targetRoot = $TargetRoot
    packageRoot = $pkg
    governanceMode = 'portable'
    requiresESFramework = $false
    requiresUnity = $false
    smokeReceipt = $smokeReceipt
    shim = $shim
    adaptChecklistJson = $checklistJson
    adaptChecklistMarkdown = $checklistMd
    aiPlaybook = 'docs/ai-install-playbook.md'
    next = @(
        '. .\ES\Automation\ABCD\Use-ESABCD.ps1',
        'Invoke-ESABCDQuick -Requirement "your architecture goal"',
        'Open adapt-checklist-*.md and close todo/review items'
    )
    sayToAi = 'Install es-abcd to this project and refresh the adapt checklist.'
    runtimeStatus = 'runtime-not-run'
    nonClaims = @('Unity','PlayMode','Profiler','Player','Release')
    capturedUtc = [DateTime]::UtcNow.ToString('o')
}
$outDir = Join-Path $TargetRoot 'ES\Automation\ABCD\out'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$outPath = Join-Path $outDir ('oneclick-' + [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss') + '.json')
[IO.File]::WriteAllText($outPath, ($receipt | ConvertTo-Json -Depth 6), [Text.UTF8Encoding]::new($false))

Write-Host ''
Write-Host '======== DONE ========' -ForegroundColor Green
Write-Host '  Install + smoke finished (static).'
Write-Host '  ESFramework host: NOT required'
Write-Host '  Unity / PlayMode : NOT claimed'
Write-Host ''
Write-Host '  Daily use:'
Write-Host ('    cd ' + $TargetRoot)
Write-Host '    . .\ES\Automation\ABCD\Use-ESABCD.ps1'
Write-Host '    Invoke-ESABCDQuick -Requirement "your goal"'
Write-Host ''
Write-Host '  Say to AI next time:'
Write-Host '    Install es-abcd to this project and refresh the adapt checklist.'
if ($checklistMd) { Write-Host ('  Checklist: ' + $checklistMd) }
Write-Host ('  Receipt: ' + $outPath)
Write-Host '======================' -ForegroundColor Green
Write-Host ''
$receipt | ConvertTo-Json -Depth 5
