# Analyze any target project and emit an integration profile for adaptive install.
# ASCII-primary for Windows PowerShell 5.1.
# Usage:
#   powershell -File .\scripts\Get-ESABCDProjectProfile.ps1 -TargetRoot <项目根路径>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$TargetRoot,
    [string]$PackageRoot = '',
    [switch]$WriteReceipt
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$TargetRoot = [IO.Path]::GetFullPath($TargetRoot)
if (-not (Test-Path -LiteralPath $TargetRoot -PathType Container)) {
    throw "TARGET_NOT_FOUND:$TargetRoot"
}

if ([string]::IsNullOrWhiteSpace($PackageRoot)) {
    $scriptDir = if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
    $PackageRoot = (Resolve-Path (Join-Path $scriptDir '..')).Path
} else {
    $PackageRoot = (Resolve-Path -LiteralPath $PackageRoot).Path
}

function Test-Rel([string]$Rel) {
    return (Test-Path -LiteralPath (Join-Path $TargetRoot $Rel))
}
function Find-File([string]$Filter, [int]$Depth = 2) {
    try {
        return @(Get-ChildItem -LiteralPath $TargetRoot -Filter $Filter -File -Recurse -Depth $Depth -ErrorAction SilentlyContinue | Select-Object -First 3)
    } catch { return @() }
}

$signals = [ordered]@{}
$kinds = New-Object System.Collections.Generic.List[string]

# --- signals ---
$signals['hasGit'] = Test-Rel '.git'
$signals['hasAssets'] = Test-Rel 'Assets'
$signals['hasProjectSettings'] = Test-Rel 'ProjectSettings'
$signals['hasPackagesManifest'] = Test-Rel 'Packages\manifest.json'
$signals['hasEsPlugins'] = Test-Rel 'Assets\Plugins\ES'
$signals['hasAgentsMd'] = Test-Rel 'AGENTS.md'
$signals['hasEsAiSpace'] = Test-Rel 'ES\AISpace'
$signals['hasEsAutomation'] = Test-Rel 'ES\Automation'
$signals['hasAbcdHome'] = Test-Rel 'ES\Automation\ABCD\ESABCDHome.psm1'
$signals['hasAbcdUse'] = Test-Rel 'ES\Automation\ABCD\Use-ESABCD.ps1'
$signals['hasAbcdContracts'] = Test-Rel 'ES\Automation\Contracts\es-ai-abc-generation-mode-v1.json'
$signals['hasPackageJson'] = Test-Rel 'package.json'
$signals['hasPyProject'] = Test-Rel 'pyproject.toml'
$signals['hasRequirements'] = Test-Rel 'requirements.txt'
$signals['hasCargo'] = Test-Rel 'Cargo.toml'
$signals['hasGoMod'] = Test-Rel 'go.mod'
$signals['hasGodot'] = Test-Rel 'project.godot'
$signals['hasUproject'] = (@(Find-File '*.uproject' 1).Count -gt 0)
$signals['hasSln'] = (@(Find-File '*.sln' 1).Count -gt 0)
$signals['hasCsproj'] = (@(Find-File '*.csproj' 2).Count -gt 0)
$signals['hasReadme'] = (Test-Rel 'README.md') -or (Test-Rel 'readme.md')

$fileCount = 0
try {
    $fileCount = @(Get-ChildItem -LiteralPath $TargetRoot -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -notin @('.','..') }).Count
} catch { $fileCount = -1 }
$signals['topLevelEntryCount'] = $fileCount
$signals['looksEmpty'] = ($fileCount -ge 0 -and $fileCount -le 2)

$pkgNorm = $PackageRoot.TrimEnd('\', '/').ToLowerInvariant()
$tgtNorm = $TargetRoot.TrimEnd('\', '/').ToLowerInvariant()
$signals['isSameAsPackage'] = ($pkgNorm -eq $tgtNorm)
$signals['isPackageChild'] = ($tgtNorm.StartsWith($pkgNorm + '\') -or $tgtNorm.StartsWith($pkgNorm + '/'))

# --- classify ---
if ($signals['isSameAsPackage']) { [void]$kinds.Add('es-abcd-package-self') }
if ($signals['hasAbcdHome'] -and $signals['hasAbcdContracts']) { [void]$kinds.Add('es-abcd-already-installed') }
if ($signals['hasEsPlugins'] -or $signals['hasAgentsMd'] -or $signals['hasEsAiSpace']) { [void]$kinds.Add('esframework-like') }
if ($signals['hasAssets'] -and $signals['hasProjectSettings']) { [void]$kinds.Add('unity') }
elseif ($signals['hasAssets'] -or $signals['hasPackagesManifest']) { [void]$kinds.Add('unity-partial') }
if ($signals['hasPackageJson']) { [void]$kinds.Add('node') }
if ($signals['hasPyProject'] -or $signals['hasRequirements']) { [void]$kinds.Add('python') }
if ($signals['hasCargo']) { [void]$kinds.Add('rust') }
if ($signals['hasGoMod']) { [void]$kinds.Add('go') }
if ($signals['hasGodot']) { [void]$kinds.Add('godot') }
if ($signals['hasUproject']) { [void]$kinds.Add('unreal') }
if ($signals['hasSln'] -or $signals['hasCsproj']) { [void]$kinds.Add('dotnet') }
if ($signals['looksEmpty']) { [void]$kinds.Add('empty-or-sparse') }
if ($kinds.Count -eq 0) { [void]$kinds.Add('generic') }

$kindArr = @($kinds | Select-Object -Unique)

# primary kind priority
$primary = 'generic'
foreach ($p in @(
        'es-abcd-package-self',
        'esframework-like',
        'es-abcd-already-installed',
        'unity',
        'unreal',
        'godot',
        'node',
        'dotnet',
        'python',
        'rust',
        'go',
        'empty-or-sparse',
        'generic')) {
    if ($kindArr -contains $p) { $primary = $p; break }
}

# --- adapt strategy ---
$blockInstall = $false
$forceRecommended = $false
$skipSmoke = $false
$notes = New-Object System.Collections.Generic.List[string]
$actions = New-Object System.Collections.Generic.List[string]
$risks = New-Object System.Collections.Generic.List[string]

switch ($primary) {
    'es-abcd-package-self' {
        $blockInstall = $true
        [void]$notes.Add('目标是 es-abcd 自身，请换到业务项目。')
        [void]$actions.Add('请选业务项目路径，不要用 es-abcd 仓根。')
    }
    'es-abcd-already-installed' {
        $forceRecommended = $true
        [void]$notes.Add('已检测到 es-abcd 核心，按升级/刷新处理。')
        [void]$actions.Add('用 get.ps1 -Force 刷新不一致文件。')
        [void]$actions.Add('升级后刷新适配清单。')
        if ($kindArr -contains 'esframework-like') {
            [void]$risks.Add('可能存在双套自动化核心，建议只保留一套 portable 叠加。')
        }
    }
    'esframework-like' {
        $forceRecommended = $true
        [void]$notes.Add('检测到类 ESFramework 标记；默认仍用 portable 治理。')
        [void]$actions.Add('安装或刷新叠加；不要手拷第二套核心。')
        [void]$actions.Add('在清单上检查双核与 host 语料选项。')
        [void]$risks.Add('若与旧树并行改，可能冲突。')
        if ($kindArr -contains 'unity') {
            [void]$notes.Add('Unity+ES：冒烟仅静态；PlayMode 须另证。')
        }
    }
    'unity' {
        [void]$notes.Add('检测到 Unity 工程；按项目根下 ES/Automation 布局叠加。')
        [void]$actions.Add('安装 portable 核心；保持 portable 治理。')
        [void]$actions.Add('不要把冒烟当成 PlayMode 通过。')
        [void]$risks.Add('默认不改 Unity 资产；玩法仍归你。')
    }
    'empty-or-sparse' {
        [void]$notes.Add('空或几乎空目录，可安全全新叠加。')
        [void]$actions.Add('适合完整安装叠加。')
    }
    default {
        [void]$notes.Add("Detected kinds: $($kindArr -join ', '). Core still installs via fixed ES/Automation overlay.")
        [void]$actions.Add('可安装叠加；项目类型不阻碍 ABCD 核心。')
        [void]$actions.Add('装完后用 README 工程/创意/稳定场景模板测试。')
    }
}

if ($signals['isPackageChild'] -and -not $signals['isSameAsPackage']) {
    [void]$risks.Add('目标落在 es-abcd 包目录内，通常不对；请用外部业务项目。')
}

$strategy = [pscustomobject]@{
    blockInstall      = $blockInstall
    forceRecommended  = $forceRecommended
    skipSmoke         = $skipSmoke
    governanceDefault = 'portable'
    overlayLayout     = 'ES/Automation + .agents/skills'
    anyProjectSupported = (-not $blockInstall)
}

# human summary for AI to speak
$human = New-Object System.Collections.Generic.List[string]
[void]$human.Add("目标: $TargetRoot")
[void]$human.Add("主类型: $primary")
[void]$human.Add("全部类型: $($kindArr -join ', ')")
if ($blockInstall) {
    [void]$human.Add('安装: 已拦截。请换业务项目根，不要装进 es-abcd 自身。')
} elseif ($signals['hasAbcdHome']) {
    [void]$human.Add('安装: 建议刷新/升级（哈希不一致时用 -Force）。')
} else {
    [void]$human.Add('安装: 建议完整可移植叠加。')
}
[void]$human.Add('治理: portable（不需要宿主 AIWarnings 语料）。')
foreach ($n in $notes) { [void]$human.Add("说明: $n") }
foreach ($r in $risks) { [void]$human.Add("风险: $r") }

$profile = [pscustomobject]@{
    schemaVersion   = 1
    recordType      = 'ESABCDProjectProfile'
    targetRoot      = $TargetRoot
    packageRoot     = $PackageRoot
    primaryKind     = $primary
    kinds           = $kindArr
    signals         = [pscustomobject]$signals
    strategy        = $strategy
    notes           = @($notes)
    recommendedActions = @($actions)
    risks           = @($risks)
    humanSummaryLines = @($human)
    humanSummary    = ($human -join ' | ')
    capturedUtc     = [DateTime]::UtcNow.ToString('o')
    runtimeStatus   = 'runtime-not-run'
    nonClaims       = @('Unity-PlayMode', 'Release', 'Business-content-complete')
}

if ($WriteReceipt) {
    $outDir = Join-Path $TargetRoot 'ES\Automation\ABCD\out'
    # may not exist before install — write beside target if needed
    if (-not (Test-Path -LiteralPath $outDir)) {
        $outDir = Join-Path $TargetRoot '.es-abcd-out'
        New-Item -ItemType Directory -Force -Path $outDir | Out-Null
    } else {
        New-Item -ItemType Directory -Force -Path $outDir | Out-Null
    }
    $path = Join-Path $outDir ('project-profile-' + [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss') + '.json')
    [IO.File]::WriteAllText($path, ($profile | ConvertTo-Json -Depth 8), [Text.UTF8Encoding]::new($false))
    $profile | Add-Member -NotePropertyName receiptPath -NotePropertyValue $path -Force
}

$profile | ConvertTo-Json -Depth 8 
