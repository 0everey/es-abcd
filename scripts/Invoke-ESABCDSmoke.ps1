<#
.SYNOPSIS
  在目标项目根目录对 ABCD 可移植核心做冒烟测试（仅静态）。

.DESCRIPTION
  加载权威与发散模块，跑 engineering（可改）发散与候选选择，写出机器可读回执。
  不启动 Unity，不声称 PlayMode/运行时验收通过。
  成功时 runtimeStatus 一般为 runtime-not-run（表示未做运行时层验收）。

.PARAMETER ProjectRoot
  已执行 Install-ESABCD 的目标项目根目录。

.EXAMPLE
  powershell -File .\scripts\Invoke-ESABCDSmoke.ps1 -ProjectRoot <项目根路径>
#>
[CmdletBinding()]
param(
    [string]$ProjectRoot = '',
    [ValidateSet('creative-divergence','engineering','stable')]
    [string]$Mode = 'engineering',
    [string]$Requirement = 'ABCD portable smoke: prove divergence and selection work without gameplay or ESFramework host.'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
    $ProjectRoot = (Resolve-Path (Join-Path $scriptDir '..')).Path
} else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
}
$env:ES_ABCD_GOVERNANCE_MODE = 'portable'
$abcd = Join-Path $ProjectRoot 'ES\Automation\ABCD'
$divModule = Join-Path $abcd 'ESABCDDivergence.psm1'
$runModule = Join-Path $abcd 'ESABCInnovationRun.psm1'
$authModule = Join-Path $abcd 'ESABCDAuthorityKernel.psm1'

foreach ($p in @($divModule, $runModule, $authModule)) {
    if (-not (Test-Path -LiteralPath $p -PathType Leaf)) {
        throw "ABCD not installed at ProjectRoot. Missing: $p"
    }
}

# Anchor hash from generation-mode contract (stable, always present after install).
$contract = Join-Path $ProjectRoot 'ES\Automation\Contracts\es-ai-abc-generation-mode-v1.json'
if (-not (Test-Path -LiteralPath $contract)) {
    throw "Missing contract: $contract"
}
Import-Module $authModule -Force
Import-Module $divModule -Force
Import-Module $runModule -Force
Import-Module (Join-Path $abcd 'ESABCDDelivery.psm1') -Force -Global
$sourceHash = Get-ESABCDFileSha256 -LiteralPath $contract

$caps = @(Get-ESABCDCoreCapabilities)
if ($caps.Count -lt 6) { throw 'ABCD_CORE_CAPABILITIES_INCOMPLETE' }

$div = Invoke-ESABCModeDivergence -Requirement $Requirement -SourceHash $sourceHash -Mode $Mode -ProjectRoot $ProjectRoot
$sel = Select-ESABCGenerationCandidate -Candidates $div.directions -Mode $Mode -Requirement $Requirement
if ($null -eq $sel.PSObject.Properties['deliveryKind'] -or [string]::IsNullOrWhiteSpace([string]$sel.deliveryKind)) {
    throw 'ABCD_DELIVERY_KIND_MISSING'
}
if ($null -eq $sel.PSObject.Properties['pipelineLevel'] -or [string]::IsNullOrWhiteSpace([string]$sel.pipelineLevel)) {
    throw 'ABCD_PIPELINE_LEVEL_MISSING'
}

$branch = [pscustomobject]@{
    playerValue = 80
    causalClarity = 85
    ownershipLifecycle = 88
    stateIntegrity = 86
    determinism = 84
    performance = 78
    failureRecovery = 82
    reuse = 86
    security = 80
    observability = 80
    counterplayClarity = 75
    complexityBudget = 80
    noveltyDelta = 70
    depth = 85
    breakthrough = 78
    reusability = 88
    longevity = 86
    projectFit = 90
    completeness = 85
    safety = 90
    closure = 88
    mechanismChangeEvidence = $true
}
$score = Invoke-ESABCStableScore -Branch $branch -GenerationMode $Mode -ReviewRounds 3

# Mono-semantic check runs against the PACKAGE root (has docs/skills),
# not the consumer project root (overlay may omit docs).
$monoScript = Join-Path $abcd 'Test-ESABCDMonoSemanticAuthority.ps1'
$monoPackageRoot = $ProjectRoot
$pkgMarker = Join-Path $ProjectRoot 'package\es-abcd-portable.manifest.json'
if (-not (Test-Path -LiteralPath $pkgMarker -PathType Leaf)) {
    # Consumer overlay: prefer package beside installed modules via Home, else script parent chain.
    $homeMod = Join-Path $abcd 'ESABCDHome.psm1'
    if (Test-Path -LiteralPath $homeMod) {
        Import-Module $homeMod -Force -Global
        try { $monoPackageRoot = Get-ESABCDPackageRoot } catch { $monoPackageRoot = $ProjectRoot }
    }
    # If Home still points at consumer (installed copy of Home resolves ..\..\.. to consumer),
    # fall back to discovering a real package by walking from this smoke script.
    if (-not (Test-Path -LiteralPath (Join-Path $monoPackageRoot 'package\es-abcd-portable.manifest.json'))) {
        $walk = if ($PSScriptRoot) { Get-Item $PSScriptRoot } else { $null }
        for ($i = 0; $i -lt 6 -and $null -ne $walk; $i++) {
            $m = Join-Path $walk.FullName 'package\es-abcd-portable.manifest.json'
            if (Test-Path -LiteralPath $m) { $monoPackageRoot = $walk.FullName; break }
            $walk = $walk.Parent
        }
    }
}
if (-not (Test-Path -LiteralPath $monoScript -PathType Leaf)) {
    $monoScript = Join-Path $monoPackageRoot 'ES\Automation\ABCD\Test-ESABCDMonoSemanticAuthority.ps1'
}
if (-not (Test-Path -LiteralPath $monoScript -PathType Leaf)) {
    throw "Missing mono-semantic test: $monoScript"
}
$monoRaw = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $monoScript -ProjectRoot $monoPackageRoot 2>&1
if ($LASTEXITCODE -ne 0) {
    throw "ABCD_MONO_SEMANTIC_FAILED: $monoRaw"
}
$monoJsonText = ($monoRaw | Where-Object { $_ -is [string] -or $_.ToString() } | ForEach-Object { "$_" }) -join "`n"
# Extract last JSON object if mixed streams
if ($monoJsonText -match '(?s)\{.*\}\s*$') {
    $mono = ($Matches[0] | ConvertFrom-Json)
} else {
    $mono = ($monoJsonText | ConvertFrom-Json)
}
if ([string]$mono.status -cne 'passed') {
    throw "ABCD_MONO_SEMANTIC_NOT_PASSED: $($mono.findings -join ';')"
}

# Generation mode mapping: ABCD mode/function/level -> creative|engineering|stable only.
$genMapScript = Join-Path $abcd 'Test-ESABCDModeFunctionLevelMapping.ps1'
if (-not (Test-Path -LiteralPath $genMapScript -PathType Leaf)) {
    $genMapScript = Join-Path $monoPackageRoot 'ES\Automation\ABCD\Test-ESABCDModeFunctionLevelMapping.ps1'
}
if (-not (Test-Path -LiteralPath $genMapScript -PathType Leaf)) {
    throw "Missing generation-mode mapping test: $genMapScript"
}
$genMapRoot = $monoPackageRoot
$genMapRaw = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $genMapScript -ProjectRoot $genMapRoot 2>&1
if ($LASTEXITCODE -ne 0) {
    throw "ABCD_MODE_FUNCTION_LEVEL_MAPPING_FAILED: $genMapRaw"
}
$genMapText = ($genMapRaw | ForEach-Object { "$_" }) -join "`n"
if ($genMapText -match '(?s)\{.*\}\s*$') {
    $genMap = ($Matches[0] | ConvertFrom-Json)
} else {
    $genMap = ($genMapText | ConvertFrom-Json)
}
if ([string]$genMap.status -cne 'passed') {
    throw "ABCD_MODE_FUNCTION_LEVEL_MAPPING_NOT_PASSED: $($genMap.findings -join ';')"
}

$receipt = [ordered]@{
    schemaVersion = 1
    recordType = 'ESABCDSmokeReceipt'
    status = 'passed'
    mode = $Mode
    projectRoot = $ProjectRoot
    sourceHash = $sourceHash
    capabilityCount = $caps.Count
    capabilities = @($caps)
    divergenceStatus = [string]$div.status
    claimLevel = [string]$sel.claimLevel
    directionCount = [int]$div.directionCount
    candidateSetHash = [string]$div.candidateSetHash
    selectedDirectionId = [string]$sel.selectedDirectionId
    selectionStatus = [string]$sel.selectionStatus
    deliveryKind = [string]$sel.deliveryKind
    pipelineLevel = [string]$sel.pipelineLevel
    deliveryStatus = [string]$sel.deliveryStatus
    domain = [string]$sel.domain
    templateCollision = $(if ($null -ne $sel.templateCollision) { [bool]$sel.templateCollision.hasCollision } else { $false })
    stableScoreStatus = [string]$score.status
    stableTotalScore = [double]$score.totalScore
    monoSemantic = [ordered]@{
        status = [string]$mono.status
        onlyModeId = [string]$mono.onlyModeId
        semanticCardinality = [int]$mono.semanticCardinality
        engineeringFourLetterNeverCorrect = [bool]$mono.engineeringFourLetterNeverCorrect
    }
    modeFunctionLevelMapping = [ordered]@{
        status = [string]$genMap.status
        mapsTo = @('creative-divergence', 'engineering', 'stable')
        notArchitectureIdentities = @('ABCD.Dynamic', 'ABCC.Core', 'ABCP.Part')
    }
    runtimeStatus = 'runtime-not-run'
    nonClaims = @('Unity','PlayMode','Profiler','Player','Release','provider-completed-final-decision','not-universal-ai-wipeout')
    capturedUtc = [DateTime]::UtcNow.ToString('o')
}

$outDir = Join-Path $ProjectRoot 'ES\Automation\ABCD\out'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$outPath = Join-Path $outDir ("smoke-" + [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss') + ".json")
[IO.File]::WriteAllText($outPath, ($receipt | ConvertTo-Json -Depth 8), [Text.UTF8Encoding]::new($false))

Write-Host "ABCD smoke PASSED"
Write-Host "  mode=$Mode selected=$($sel.selectedDirectionId) score=$($score.totalScore)"
Write-Host "  deliveryKind=$($sel.deliveryKind) pipelineLevel=$($sel.pipelineLevel) domain=$($sel.domain)"
Write-Host "  receipt=$outPath"
$receipt | ConvertTo-Json -Depth 6 
