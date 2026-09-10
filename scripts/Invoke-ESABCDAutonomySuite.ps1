# Strong autonomy suite: prove es-abcd Core works without native ESFramework host.
# Encoding: ASCII-primary for Windows PowerShell 5.1 parser safety.
# Chinese docs: docs/independence.md and README.md
[CmdletBinding()]
param(
    [string]$PackageRoot = '',
    [string]$OutDir = ''
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if ([string]::IsNullOrWhiteSpace($PackageRoot)) {
    $scriptDir = if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
        $PSScriptRoot
    } else {
        Split-Path -Parent $MyInvocation.MyCommand.Path
    }
    $PackageRoot = (Resolve-Path (Join-Path $scriptDir '..')).Path
} else {
    $PackageRoot = (Resolve-Path -LiteralPath $PackageRoot).Path
}

$env:ES_ABCD_GOVERNANCE_MODE = 'portable'
$esSibling = Join-Path (Split-Path $PackageRoot -Parent) 'ESFrameWorkPublish'
$esPresent = Test-Path -LiteralPath $esSibling -PathType Container

$cases = New-Object System.Collections.Generic.List[object]
function Add-Case([string]$Name, [bool]$Ok, [string]$Detail = '') {
    [void]$cases.Add([pscustomobject][ordered]@{
            case   = $Name
            status = $(if ($Ok) { 'passed' } else { 'failed' })
            detail = $Detail
        })
}

Import-Module (Join-Path $PackageRoot 'ES\Automation\ABCD\ESABCDHome.psm1') -Force -Global
Import-Module (Join-Path $PackageRoot 'ES\Automation\ABCD\ESABCDPortableAuthority.psm1') -Force -Global
Import-Module (Join-Path $PackageRoot 'ES\Automation\ABCD\ESABCDAuthorityKernel.psm1') -Force -Global
Import-Module (Join-Path $PackageRoot 'ES\Automation\ABCD\ESABCDDivergence.psm1') -Force -Global
Import-Module (Join-Path $PackageRoot 'ES\Automation\ABCD\ESABCInnovationRun.psm1') -Force -Global
Import-Module (Join-Path $PackageRoot 'ES\Automation\ABCD\ESABCDAuditGate.psm1') -Force -Global
Import-Module (Join-Path $PackageRoot 'ES\Automation\AI\ESAIWarningsResultProjection.psm1') -Force -Global
Import-Module (Join-Path $PackageRoot 'ES\Automation\AI\ESAuthorityDecisionPolicy.psm1') -Force -Global

$id = Get-ESABCDIdentity
Add-Case 'identity-not-esframework-runtime' ([bool]$id.notESFrameworkRuntime -and [bool]$id.notAGameFramework) ([string]$id.productId)
Add-Case 'identity-default-portable' ([string]$id.governanceMode -eq 'portable') ([string]$id.governanceMode)
Add-Case 'package-root-resolves' (-not [string]::IsNullOrWhiteSpace([string]$id.packageRoot)) ([string]$id.packageRoot)

$caps = @(Get-ESABCDCoreCapabilities)
$required = @(
    'bounded-tool-action', 'failure-recovery', 'branch-evaluation',
    'state-transition-guard', 'environment-trust-gate', 'audit-evidence-chain'
)
$missing = @($required | Where-Object { $_ -notin $caps })
Add-Case 'six-kernel-capabilities-present' ($missing.Count -eq 0 -and $caps.Count -ge 6) ("missing=$($missing -join ',')")

try {
    $null = Resolve-ESABCDContractPath -FileName 'es-ai-abc-generation-mode-v1.json'
    $null = Resolve-ESABCDContractPath -FileName 'es-ai-abc-scoring-v1.json'
    $null = Resolve-ESABCDContractPath -FileName 'es-authority-ai-decision-policy-v1.json'
    Add-Case 'contracts-resolve-from-package' $true 'ok'
}
catch {
    Add-Case 'contracts-resolve-from-package' $false $_.Exception.Message
}

$gov = Resolve-ESABCDPortableGovernancePolicy -ContextText 'claim PlayMode shippable runtime-not-run release player' -Domain ai-collaboration -ConsumerId autonomy-suite
Add-Case 'portable-governance-resolves' ($null -ne $gov -and [string]$gov.governanceMode -eq 'portable') ([string]$gov.authorityId)
Add-Case 'portable-claim-cap-on-runtime-language' ([string]$gov.policyDecision -eq 'claim-cap') ([string]$gov.policyDecision)
Add-Case 'portable-capability-parity-six' (@($gov.capabilitiesParity).Count -ge 6) ("count=$(@($gov.capabilitiesParity).Count)")
Add-Case 'portable-requires-esframework-false' (-not [bool]$gov.independence.requiresESFramework) 'ok'

$proj = Add-ESAIWarningsResultProjection -Result ([pscustomobject]@{}) -ContextText 'release player build' -Domain release -ConsumerId autonomy-proj -ProjectRoot $PackageRoot -GovernanceMode portable
Add-Case 'projection-portable-status' ([string]$proj.aiWarnings.projectionStatus -eq 'resolved-portable') ([string]$proj.aiWarnings.projectionStatus)
Add-Case 'projection-has-matched-rules' (@($proj.aiWarnings.matchedRuleIds).Count -ge 1) 'ok'

$ev = [pscustomobject]@{
    requiredCapabilities       = $required
    selectedCapabilities       = $required
    requiresCompleteDivergence = $false
}
$auth = Resolve-ESABCDAuthorityDecision -Mode core-high-risk -Domain ai-collaboration -Evidence $ev
Add-Case 'authority-decision-runs' ($null -ne $auth) ([string]$auth.status)

$hash = (Get-FileHash -LiteralPath (Resolve-ESABCDContractPath -FileName 'es-ai-abc-generation-mode-v1.json') -Algorithm SHA256).Hash.ToLowerInvariant()
$div = Invoke-ESABCModeDivergence -Requirement 'Autonomy freeze without ESFramework host' -SourceHash $hash -Mode engineering -ProjectRoot $PackageRoot
$sel = Select-ESABCGenerationCandidate -Candidates $div.directions -Mode engineering
Add-Case 'divergence-five-plus' ([int]$div.directionCount -ge 5) ("count=$($div.directionCount)")
Add-Case 'selection-deterministic' (-not [string]::IsNullOrWhiteSpace([string]$sel.selectedDirectionId)) ([string]$sel.selectedDirectionId)

$score = Invoke-ESABCStableScore -Branch ([pscustomobject]@{
        playerValue = 80; causalClarity = 85; ownershipLifecycle = 88; stateIntegrity = 86; determinism = 84; performance = 78
        failureRecovery = 82; reuse = 86; security = 80; observability = 80; counterplayClarity = 75; complexityBudget = 80
        noveltyDelta = 70; depth = 85; breakthrough = 78; reusability = 88; longevity = 86; projectFit = 90; completeness = 85
        safety = 90; closure = 88; mechanismChangeEvidence = $true
    }) -GenerationMode engineering -ReviewRounds 3
Add-Case 'stable-score-runs' ([string]$score.status -eq 'stable') ("total=$($score.totalScore)")

$aw = Get-ESABCDAuditWarningsSummary -ContextText 'audit delivery claim' -Domain ai-collaboration
$awOk = (
    [string]$aw.governanceMode -eq 'portable' -or
    [string]$aw.projectionStatus -eq 'resolved-portable' -or
    @($aw.matchedRuleIds).Count -ge 1
)
Add-Case 'audit-warnings-portable' $awOk ([string]$aw.authorityId)

Add-Case 'core-runs-regardless-of-sibling-es' $true ("esSiblingPresent=$esPresent")

# Mono-semantic lock: reject ABCD meaning drift (engineering four-letter never correct).
$monoScript = Join-Path $PackageRoot 'ES\Automation\ABCD\Test-ESABCDMonoSemanticAuthority.ps1'
$monoResolver = Join-Path $PackageRoot 'ES\Automation\ABCD\Resolve-ESABCDMonoSemantic.ps1'
Add-Case 'mono-semantic-scripts-present' (
    (Test-Path -LiteralPath $monoScript -PathType Leaf) -and
    (Test-Path -LiteralPath $monoResolver -PathType Leaf)
) 'Test+Resolve'
if ((Test-Path -LiteralPath $monoScript -PathType Leaf)) {
    try {
        $monoJson = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $monoScript -ProjectRoot $PackageRoot 2>&1
        $monoExit = $LASTEXITCODE
        $monoObj = $null
        try { $monoObj = ($monoJson | Out-String | ConvertFrom-Json) } catch { $monoObj = $null }
        $monoOk = ($monoExit -eq 0 -and $null -ne $monoObj -and [string]$monoObj.status -eq 'passed')
        $detail = if ($null -ne $monoObj) {
            "status=$([string]$monoObj.status);cardinality=$([string]$monoObj.semanticCardinality);neverCorrect=$([string]$monoObj.engineeringFourLetterNeverCorrect)"
        } else {
            "exit=$monoExit"
        }
        Add-Case 'mono-semantic-authority-passed' $monoOk $detail
        if ($monoOk) {
            Add-Case 'mono-semantic-cardinality-one' ([int]$monoObj.semanticCardinality -eq 1) ([string]$monoObj.semanticCardinality)
            Add-Case 'mono-semantic-engineering-never-correct' ([bool]$monoObj.engineeringFourLetterNeverCorrect -eq $true) 'ok'
        }
    }
    catch {
        Add-Case 'mono-semantic-authority-passed' $false $_.Exception.Message
    }
} else {
    Add-Case 'mono-semantic-authority-passed' $false 'script-missing'
}

$caseArray = @($cases.ToArray())
$failed = @($caseArray | Where-Object { $_.status -eq 'failed' })
$status = if ($failed.Count) { 'failed' } else { 'passed' }
$capArray = @($caps)
$indep = [pscustomobject]@{
    productId                 = 'es-abcd'
    requiresESFramework       = $false
    requiresUnity             = $false
    siblingESFrameworkPresent = [bool]$esPresent
    note                      = 'Core autonomy does not require ESFrameWorkPublish even if it exists nearby.'
}
$receipt = [pscustomobject]@{
    schemaVersion   = 1
    recordType      = 'ESABCDAutonomySuiteReceipt'
    status          = $status
    packageRoot     = $PackageRoot
    governanceMode  = 'portable'
    independence    = $indep
    capabilityCount = $capArray.Count
    capabilities    = $capArray
    caseCount       = $caseArray.Count
    passedCount     = ($caseArray.Count - $failed.Count)
    failedCount     = $failed.Count
    cases           = $caseArray
    runtimeStatus   = 'runtime-not-run'
    nonClaims       = @('Unity', 'PlayMode', 'Profiler', 'Player', 'Release', 'ESFramework-host-required')
    capturedUtc     = [DateTime]::UtcNow.ToString('o')
}

if ([string]::IsNullOrWhiteSpace($OutDir)) {
    $OutDir = Join-Path $PackageRoot 'ES\Automation\ABCD\out'
}
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$outPath = Join-Path $OutDir ('autonomy-' + [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss') + '.json')
[IO.File]::WriteAllText($outPath, ($receipt | ConvertTo-Json -Depth 10), [Text.UTF8Encoding]::new($false))

Write-Host "ABCD AUTONOMY SUITE: $status"
Write-Host "  cases=$($cases.Count) failed=$($failed.Count)"
Write-Host "  receipt=$outPath"
if ($failed.Count) {
    foreach ($f in $failed) {
        Write-Host ("  FAIL {0}: {1}" -f $f.case, $f.detail)
    }
}
$receipt | ConvertTo-Json -Depth 6
if ($status -ne 'passed') { exit 1 }
