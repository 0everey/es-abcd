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
        [void]$notes.Add('Target is the es-abcd package itself. Install into a different project root.')
        [void]$actions.Add('Pick a consumer project path, not the es-abcd repo root.')
    }
    'es-abcd-already-installed' {
        $forceRecommended = $true
        [void]$notes.Add('es-abcd core already present. Treat as upgrade/refresh.')
        [void]$actions.Add('Run get.ps1 with -Force to refresh mismatched files.')
        [void]$actions.Add('Refresh adapt checklist after upgrade.')
        if ($kindArr -contains 'esframework-like') {
            [void]$risks.Add('Possible dual ABCD/ES automation trees. Prefer single portable core overlay.')
        }
    }
    'esframework-like' {
        $forceRecommended = $true
        [void]$notes.Add('ESFramework-like markers detected. Portable governance stays default.')
        [void]$actions.Add('Install/refresh overlay; do not hand-copy a second Core.')
        [void]$actions.Add('Review dual-core and AIWarnings host options on checklist.')
        [void]$risks.Add('Old in-tree automation may conflict if edited in parallel.')
        if ($kindArr -contains 'unity') {
            [void]$notes.Add('Unity+ES tree: smoke is static only; PlayMode is separate evidence.')
        }
    }
    'unity' {
        [void]$notes.Add('Unity project detected. Overlay uses ES/Automation layout under project root.')
        [void]$actions.Add('Install portable core; keep ES_ABCD_GOVERNANCE_MODE=portable.')
        [void]$actions.Add('Do not treat smoke as PlayMode pass.')
        [void]$risks.Add('Unity assets untouched by design; gameplay still yours.')
    }
    'empty-or-sparse' {
        [void]$notes.Add('Empty or sparse folder. Safe greenfield overlay.')
        [void]$actions.Add('Full install overlay is appropriate.')
    }
    default {
        [void]$notes.Add("Detected kinds: $($kindArr -join ', '). Core still installs via fixed ES/Automation overlay.")
        [void]$actions.Add('Install overlay; project type does not block ABCD core.')
        [void]$actions.Add('Use engineering/creative/stable scenario templates from README after install.')
    }
}

if ($signals['isPackageChild'] -and -not $signals['isSameAsPackage']) {
    [void]$risks.Add('Target is inside es-abcd package tree; usually wrong. Prefer an external consumer project.')
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
[void]$human.Add("Target: $TargetRoot")
[void]$human.Add("Primary kind: $primary")
[void]$human.Add("All kinds: $($kindArr -join ', ')")
if ($blockInstall) {
    [void]$human.Add('Install: BLOCKED. Choose another project root.')
} elseif ($signals['hasAbcdHome']) {
    [void]$human.Add('Install: refresh/upgrade recommended (-Force if hashes differ).')
} else {
    [void]$human.Add('Install: full portable overlay recommended.')
}
[void]$human.Add('Governance: portable (no host ES corpus required).')
foreach ($n in $notes) { [void]$human.Add("Note: $n") }
foreach ($r in $risks) { [void]$human.Add("Risk: $r") }

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
