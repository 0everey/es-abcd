<#
.SYNOPSIS
  Smoke-test ABCD portable core inside a project root (static only).

.DESCRIPTION
  Loads authority + divergence modules, runs an engineering-mode divergence
  and candidate selection, and emits a machine-readable receipt. Never starts
  Unity and never claims PlayMode/runtime acceptance.

.PARAMETER ProjectRoot
  Project that already contains ES/Automation/ABCD (after Install-ESABCD).

.EXAMPLE
  ./scripts/Invoke-ESABCDSmoke.ps1 -ProjectRoot C:\work\MyProject
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ProjectRoot,
    [ValidateSet('creative-divergence','engineering','stable')]
    [string]$Mode = 'engineering',
    [string]$Requirement = 'ABCD portable smoke: prove divergence and selection work without gameplay.'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
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
$sourceHash = (Get-FileHash -LiteralPath $contract -Algorithm SHA256).Hash.ToLowerInvariant()

Import-Module $authModule -Force
Import-Module $divModule -Force
Import-Module $runModule -Force

$caps = @(Get-ESABCDCoreCapabilities)
if ($caps.Count -lt 6) { throw 'ABCD_CORE_CAPABILITIES_INCOMPLETE' }

$div = Invoke-ESABCModeDivergence -Requirement $Requirement -SourceHash $sourceHash -Mode $Mode -ProjectRoot $ProjectRoot
$sel = Select-ESABCGenerationCandidate -Candidates $div.directions -Mode $Mode

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
    claimLevel = [string]$div.claimLevel
    directionCount = [int]$div.directionCount
    candidateSetHash = [string]$div.candidateSetHash
    selectedDirectionId = [string]$sel.selectedDirectionId
    selectionStatus = [string]$sel.selectionStatus
    stableScoreStatus = [string]$score.status
    stableTotalScore = [double]$score.totalScore
    runtimeStatus = 'runtime-not-run'
    nonClaims = @('Unity','PlayMode','Profiler','Player','Release','provider-completed-final-decision')
    capturedUtc = [DateTime]::UtcNow.ToString('o')
}

$outDir = Join-Path $ProjectRoot 'ES\Automation\ABCD\out'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$outPath = Join-Path $outDir ("smoke-" + [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss') + ".json")
[IO.File]::WriteAllText($outPath, ($receipt | ConvertTo-Json -Depth 8), [Text.UTF8Encoding]::new($false))

Write-Host "ABCD smoke PASSED"
Write-Host "  mode=$Mode selected=$($sel.selectedDirectionId) score=$($score.totalScore)"
Write-Host "  receipt=$outPath"
$receipt | ConvertTo-Json -Depth 6
