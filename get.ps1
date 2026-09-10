# es-abcd one-click bootstrap (remote-friendly)
# Usage (from ANY project root):
#   powershell -NoProfile -ExecutionPolicy Bypass -Command "iex (irm https://raw.githubusercontent.com/0everey/es-abcd/main/get.ps1)"
# Or with explicit target:
#   iex "& { $(irm https://raw.githubusercontent.com/0everey/es-abcd/main/get.ps1) } -TargetRoot '<项目根路径>'"
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
    Write-Host ("[es-abcd] 完成 " + $Msg) -ForegroundColor Green
}
function Write-WarnLine([string]$Msg) {
    Write-Host ("[es-abcd] 注意 " + $Msg) -ForegroundColor Yellow
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
Write-Host ('  目标   : ' + $TargetRoot)
Write-Host ('  缓存   : ' + $pkg)
Write-Host ('  模式   : portable（不依赖旧 ES 宿主）')
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
    Write-Step ("使用本地包: " + $selfRoot)
    $pkg = $selfRoot
}
elseif ($SkipCloneUpdate -and (Test-Path (Join-Path $pkg 'package\es-abcd-portable.manifest.json'))) {
    Write-Step 'using cached package (SkipCloneUpdate)'
}
else {
    Write-Step '准备 git 缓存包'
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw 'GIT_REQUIRED: install Git for Windows, then retry one-click.'
    }
    New-Item -ItemType Directory -Force -Path $CacheRoot | Out-Null
    if (-not (Test-Path -LiteralPath (Join-Path $pkg '.git'))) {
        Write-Step ("克隆 " + $RepoUrl)
        if (Test-Path -LiteralPath $pkg) {
            Remove-Item -LiteralPath $pkg -Recurse -Force
        }
        & git clone --depth 1 --branch $Branch $RepoUrl $pkg
        if ($LASTEXITCODE -ne 0) { throw "GIT_CLONE_FAILED:$LASTEXITCODE" }
    }
    else {
        Write-Step '更新缓存包'
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


# --- adaptive project analysis (any project) ---
Write-Step '分析目标项目'
$profileScript = Join-Path $(if ($selfRoot) { $selfRoot } else { if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path } }) 'scripts\Get-ESABCDProjectProfile.ps1'
if (-not (Test-Path -LiteralPath $profileScript)) {
    if ($selfRoot) { $profileScript = Join-Path $selfRoot 'scripts\Get-ESABCDProjectProfile.ps1' }
}
if (-not (Test-Path -LiteralPath $profileScript) -and (Test-Path -LiteralPath (Join-Path $pkg 'scripts\Get-ESABCDProjectProfile.ps1'))) {
    $profileScript = Join-Path $pkg 'scripts\Get-ESABCDProjectProfile.ps1'
}
$projectProfile = $null
$projectProfilePath = $null
if (Test-Path -LiteralPath $profileScript -PathType Leaf) {
    $pkgForProfile = $(if ($selfRoot) { $selfRoot } elseif (Test-Path (Join-Path $pkg 'package\es-abcd-portable.manifest.json')) { $pkg } else { (Resolve-Path (Join-Path (Split-Path $profileScript -Parent) '..')).Path })
    $rawProfile = & powershell -NoProfile -ExecutionPolicy Bypass -File $profileScript -TargetRoot $TargetRoot -PackageRoot $pkgForProfile 2>&1 | Out-String
    try { $projectProfile = $rawProfile | ConvertFrom-Json } catch { Write-WarnLine '项目画像解析失败'; $projectProfile = $null }
    if ($null -ne $projectProfile) {
        Write-Host ('  primaryKind : ' + [string]$projectProfile.primaryKind)
        Write-Host ('  kinds       : ' + ((@($projectProfile.kinds) | ForEach-Object { [string]$_ }) -join ', '))
        Write-Host ('  human       : ' + [string]$projectProfile.humanSummary)
        if ([bool]$projectProfile.strategy.blockInstall) {
            throw ('INSTALL_BLOCKED: ' + [string]$projectProfile.humanSummary)
        }
        if ([bool]$projectProfile.strategy.forceRecommended -and -not $Force) {
            Write-WarnLine '按画像建议：自动启用刷新安装 (-Force)。'
            $Force = $true
        }
        $earlyOut = Join-Path $TargetRoot '.es-abcd-out'
        New-Item -ItemType Directory -Force -Path $earlyOut | Out-Null
        $projectProfilePath = Join-Path $earlyOut 'project-profile-preinstall.json'
        [IO.File]::WriteAllText($projectProfilePath, ($projectProfile | ConvertTo-Json -Depth 10), [Text.UTF8Encoding]::new($false))
        Write-Ok ('wrote ' + $projectProfilePath)
    }
} else {
    Write-WarnLine '缺少画像脚本，按通用方式安装'
}

Write-Step '检查包布局'
& powershell -NoProfile -ExecutionPolicy Bypass -File $layout -PackageRoot $pkg
if ($LASTEXITCODE -ne 0) { throw 'LAYOUT_FAILED' }
Write-Ok 'layout'

Write-Step ("叠加安装到 " + $TargetRoot)
# Do not splat -Force into nested powershell.exe (becomes String and breaks [switch]).
if ($Force) {
    & powershell -NoProfile -ExecutionPolicy Bypass -File $install -PackageRoot $pkg -TargetRoot $TargetRoot -Force
} else {
    & powershell -NoProfile -ExecutionPolicy Bypass -File $install -PackageRoot $pkg -TargetRoot $TargetRoot
}
if ($LASTEXITCODE -ne 0) { throw 'INSTALL_FAILED' }
Write-Ok 'install'

$smokeReceipt = $null
if (-not $SkipSmoke) {
    Write-Step '冒烟（静态；运行时未验为预期）'
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
    Write-WarnLine '已跳过冒烟'
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
    Write-Step '生成适配清单'
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
        Write-WarnLine '缺少清单脚本，跳过'
    }
}

$outDir = Join-Path $TargetRoot 'ES\Automation\ABCD\out'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

# Move/copy preinstall profile into official out dir
$profileOutPath = $null
if ($projectProfilePath -and (Test-Path -LiteralPath $projectProfilePath)) {
    $profileOutPath = Join-Path $outDir 'project-profile.json'
    Copy-Item -LiteralPath $projectProfilePath -Destination $profileOutPath -Force
}

$kindStr = 'unknown'
$kindsArr = @()
$humanStr = ''
if ($null -ne $projectProfile) {
    $kindStr = [string]$projectProfile.primaryKind
    $kindsArr = @($projectProfile.kinds | ForEach-Object { [string]$_ })
    $humanStr = [string]$projectProfile.humanSummary
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
    adaptive = $true
    projectPrimaryKind = $kindStr
    projectKinds = $kindsArr
    projectHumanSummary = $humanStr
    projectProfilePath = $profileOutPath
    smokeReceipt = $smokeReceipt
    shim = $shim
    adaptChecklistJson = $checklistJson
    adaptChecklistMarkdown = $checklistMd
    aiPlaybook = 'docs/ai-install-playbook.md'
    next = @(
        '阅读 project-profile.json 中的 humanSummary',
        '打开 adapt-checklist-*.md 勾待办',
        '用 README 三种模式场景模板（填你的项目路径）继续测'
    )
    sayToAi = 'es-abcd 在 <es-abcd根路径>，装到项目 <项目根路径>，先分析再按情况接入，出清单，用人话汇报。'
    runtimeStatus = 'runtime-not-run'
    nonClaims = @('Unity', 'PlayMode', 'Profiler', 'Player', 'Release')
    capturedUtc = [DateTime]::UtcNow.ToString('o')
}
$outPath = Join-Path $outDir ('oneclick-' + [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss') + '.json')
[IO.File]::WriteAllText($outPath, ($receipt | ConvertTo-Json -Depth 8), [Text.UTF8Encoding]::new($false))

Write-Host ''
Write-Host '======== DONE ========' -ForegroundColor Green
Write-Host '  已完成：项目分析 + 按情况接入 + 静态冒烟。'
Write-Host ('  项目类型: ' + $kindStr)
Write-Host '  不需要旧 ES 宿主'
Write-Host '  未宣称 Unity/PlayMode 通过'
Write-Host ''
if ($profileOutPath) { Write-Host ('  画像    : ' + $profileOutPath) }
if ($checklistMd) { Write-Host ('  清单    : ' + $checklistMd) }
Write-Host ('  回执    : ' + $outPath)
Write-Host '======================' -ForegroundColor Green
Write-Host ''
$receipt | ConvertTo-Json -Depth 6
