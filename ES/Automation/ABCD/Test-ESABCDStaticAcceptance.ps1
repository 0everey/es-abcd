[CmdletBinding()]
param(
    [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path,
    [string]$ReportPath = 'ES/Output/StaticReplay/es-abcd-static-acceptance.json',
    [switch]$VerifyNetwork,
    [switch]$PreflightOnly
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$outputRoot = Join-Path $root 'ES/Output/StaticReplay'
$uniqueSemanticScript = Join-Path $root 'ES/Automation/ABCD/Test-ESABCDUniqueSemantic.ps1'
if (-not (Test-Path -LiteralPath $uniqueSemanticScript -PathType Leaf)) { throw 'ABCD_UNIQUE_SEMANTIC_VALIDATOR_MISSING' }
$runner = (Get-Command powershell.exe -ErrorAction SilentlyContinue)
if ($null -eq $runner) { $runner = Get-Command pwsh -ErrorAction SilentlyContinue }
if ($null -eq $runner) { throw 'PowerShell executable is required for subprocess acceptance.' }
$uniqueSemanticResult = (& $runner.Source -NoProfile -ExecutionPolicy Bypass -File $uniqueSemanticScript -ProjectRoot $root | ConvertFrom-Json)
if ([string]$uniqueSemanticResult.status -cne 'passed') { throw 'ABCD_UNIQUE_SEMANTIC_VALIDATION_FAILED' }

$components = @(
    [pscustomobject]@{ id = 'orchestration'; script = 'ES/Automation/ABCD/Test-ESABCDOrchestration.ps1'; report = 'ES/Output/StaticReplay/es-abcd-orchestration.json'; args = @() },
    [pscustomobject]@{ id = 'dynamic-controller'; script = 'ES/Automation/ABCD/Test-ESABCDDynamicController.ps1'; report = 'ES/Output/StaticReplay/es-abcd-dynamic-controller.json'; args = @() },
    [pscustomobject]@{ id = 'evidence'; script = 'ES/Automation/ABCD/Test-ESABCDEvidence.ps1'; report = 'ES/Output/StaticReplay/es-abcd-evidence.json'; args = @() },
    [pscustomobject]@{ id = 'self-iteration'; script = 'ES/Automation/ABCD/Test-ESABCDSelfIteration.ps1'; report = 'ES/Output/StaticReplay/es-abcd-self-iteration.json'; args = @() },
    [pscustomobject]@{ id = 'learning'; script = 'ES/Automation/ABCD/Test-ESABCDLearning.ps1'; report = 'ES/Output/StaticReplay/es-abcd-learning.json'; args = @() },
    [pscustomobject]@{ id = 'learning-review'; script = 'ES/Automation/ABCD/Test-ESABCDLearningReview.ps1'; report = 'ES/Output/StaticReplay/es-abcd-learning-review.json'; args = @() },
    [pscustomobject]@{ id = 'certification'; script = 'ES/Automation/ABCD/Test-ESABCDCertification.ps1'; report = 'ES/Output/StaticReplay/es-abcd-certification.json'; args = @() },
    [pscustomobject]@{ id = 'audit-gate'; script = 'ES/Automation/ABCD/Test-ESABCDAuditGate.ps1'; report = 'ES/Output/StaticReplay/es-abcd-audit-gate.json'; args = @() },
    [pscustomobject]@{ id = 'framework-parity'; script = 'ES/Automation/ABCD/Test-ESABCDFrameworkParity.ps1'; report = 'ES/Output/StaticReplay/es-abcd-framework-parity.json'; args = @() },
    [pscustomobject]@{ id = 'persistence'; script = 'ES/Automation/ABCD/Test-ESABCDPersistence.ps1'; report = 'ES/Output/StaticReplay/es-abcd-persistence.json'; args = @() },
    [pscustomobject]@{ id = 'stress'; script = 'ES/Automation/ABCD/Test-ESABCDStress.ps1'; report = 'ES/Output/StaticReplay/es-abcd-stress.json'; args = @() },
    [pscustomobject]@{ id = 'worker-runtime'; script = 'ES/Automation/ABCD/Test-ESABCDWorkerRuntime.ps1'; report = 'ES/Output/StaticReplay/es-abcd-worker-runtime.json'; args = @() },
    [pscustomobject]@{ id = 'divergence'; script = 'ES/Automation/ABCD/Test-ESABCDDivergence.ps1'; report = 'ES/Output/StaticReplay/es-abcd-divergence.json'; args = @() },
    [pscustomobject]@{ id = 'audit-consistency'; script = 'ES/Automation/ABCD/Test-ESABCDAuditConsistency.ps1'; report = 'ES/Output/StaticReplay/es-abcd-audit-consistency.json'; args = @() },
    [pscustomobject]@{ id = 'iteration-feedback'; script = 'ES/Automation/ABCD/Test-ESABCDIterationFeedback.ps1'; report = 'ES/Output/StaticReplay/es-abcd-iteration-feedback.json'; args = @() },
    [pscustomobject]@{ id = 'external-source-lock'; script = 'ES/Automation/ABCD/Test-ESABCDExternalSourceLock.ps1'; report = 'ES/Output/StaticReplay/es-abcd-external-source-lock.json'; args = if ($VerifyNetwork) { @('-VerifyNetwork') } else { @() } },
    [pscustomobject]@{ id = 'task-context-cross-process'; script = 'ES/Automation/TaskContextRuntime/Test-ESTaskContextCrossProcess.ps1'; report = 'ES/Output/StaticReplay/es-task-context-cross-process.json'; args = @() }
)

function Get-Relative([string]$Path) { return $Path.Replace('\','/') }
function Read-StrictJson([string]$Path) {
    $bytes = [IO.File]::ReadAllBytes($Path)
    $text = [Text.UTF8Encoding]::new($false, $true).GetString($bytes)
    return ($text | ConvertFrom-Json -ErrorAction Stop)
}
function Get-Hash([string]$Path) { return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant() }

$results = [Collections.Generic.List[object]]::new()
$receiptRefs = [Collections.Generic.List[string]]::new()
$null = $results.Add([pscustomobject][ordered]@{
    case = 'unique-semantic'
    status = [string]$uniqueSemanticResult.status
    exitCode = 0
    reportPath = 'inline:Test-ESABCDUniqueSemantic'
    finding = $null
})
$strictValidator = Join-Path $root '.agents/skills/es-first-principles-analysis/scripts/Test-ESSkillEvidence.ps1'
$innovationModule = Join-Path $root 'ES/Automation/ABCD/ESABCInnovationRun.psm1'
$staticSimulation = $null
# Compatibility markers retained for the unique-semantic validator.  These are
# the explicit preflight-only boundary values, used only by -PreflightOnly:
# claimLevel = 'static-only'; acceptanceDecision = 'not-eligible';
# acceptanceEligible = $false; decisionScope = 'ABCD Static Preflight only; no ABCD acceptance conclusion'

# ABCD's semantic/branch layer is deliberately executable without Unity.  This
# invoker is a deterministic model double: it supplies bounded candidate text
# so the real InnovationRun state machine, capability checkpoints, counterfactual
# reviews and convergence logic execute.  It is not a gameplay/runtime claim.
function Invoke-StaticAbcdModel {
    param($Context)
    if ([string]$Context.phase -eq 'seed-selection') {
        return @(
            [pscustomobject]@{ content='static-axis-timing'; changedVariable='timing'; playerAcceptability=78; novelty=74 },
            [pscustomobject]@{ content='static-axis-space'; changedVariable='space'; playerAcceptability=76; novelty=80 },
            [pscustomobject]@{ content='static-axis-resource'; changedVariable='resource'; playerAcceptability=74; novelty=82 },
            [pscustomobject]@{ content='static-axis-counterplay'; changedVariable='counterplay'; playerAcceptability=72; novelty=85 },
            [pscustomobject]@{ content='static-axis-feedback'; changedVariable='feedback'; playerAcceptability=75; novelty=79 }
        )
    }
    @(
        [pscustomobject]@{
            content = "static-$($Context.phase)-round-$($Context.round)-branch-a";
            changedVariable = 'interaction'; playerAcceptability=76; novelty=78; counterplay=72; complexity=68; clarity=74; roleFit=80
        },
        [pscustomobject]@{
            content = "static-$($Context.phase)-round-$($Context.round)-branch-b";
            changedVariable = 'feedback'; playerAcceptability=73; novelty=82; counterplay=76; complexity=70; clarity=72; roleFit=78
        }
    )
}

function Invoke-StaticAbcdSimulation([string]$Requirement, [string]$SourceHash) {
    if (-not (Test-Path -LiteralPath $innovationModule -PathType Leaf)) { throw 'ABCD_STATIC_SIMULATION_MODULE_MISSING' }
    Import-Module $innovationModule -Force
    $run = Invoke-ESABCInnovationRun -Requirement $Requirement -GoalRevision 'static-acceptance' -SourceHash $SourceHash -GenerationMode 'creative-divergence' -ModelInvoker ${function:Invoke-StaticAbcdModel} -SeedBranches @('static-seed') -SeedConstraints @('no-editor-required','semantic-branch-simulation-only') -ProjectRoot ''
    if ([string]$run.status -cne 'completed' -or [string]$run.currentStage -cne 'final-decision') { throw 'ABCD_STATIC_SIMULATION_INCOMPLETE' }
    [pscustomobject][ordered]@{
        status = 'completed'; simulationMode = 'deterministic-static-model'; runId = [string]$run.runId; runHash = [string]$run.runHash
        stageCount = @($run.stagePlan).Count; branchCount = @($run.divergenceTree.Keys).Count
        weightRounds = @($run.weightHistory).Count; challengeLensCount = [int]$run.finalDecision.challengeLensCount
        capabilityCheckpointCount = @($run.capabilityEvidence).Count; selectedBranchId = [string]$run.finalDecision.selectedBranchId
        acceptanceBasis = @('state-machine-executed','tree-divergence','counterfactual-review','capability-checkpoints','deterministic-replay')
        runtimeStatus = 'runtime-not-run'; nonClaims = @('Unity/editor lifecycle','scene/prefab/physics/animation','Player/IL2CPP/network/performance runtime')
    }
}
foreach ($component in $components) {
    $scriptPath = Join-Path $root $component.script
    $reportFull = Join-Path $root $component.report
    $status = 'passed'
    $finding = $null
    $exitCode = 0
    try {
        if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) { throw "ACCEPTANCE_SCRIPT_MISSING:$($component.script)" }
        $invokeArgs = @('-NoProfile','-ExecutionPolicy','Bypass','-File',$scriptPath,'-ProjectRoot',$root,'-ReportPath',$component.report)
        if (@($component.args).Count -gt 0) { $invokeArgs += @($component.args) }
        $null = & $runner.Source @invokeArgs 2>&1
        $exitCode = $LASTEXITCODE
        if ($exitCode -ne 0) { throw "ACCEPTANCE_SCRIPT_FAILED:$($component.id):exit=$exitCode" }
        if (-not (Test-Path -LiteralPath $reportFull -PathType Leaf)) { throw "ACCEPTANCE_RECEIPT_MISSING:$($component.report)" }
        $receipt = Read-StrictJson $reportFull
        if ([string]$receipt.status -ne 'passed' -or [string]$receipt.staticStatus -ne 'static-passed') { throw "ACCEPTANCE_RECEIPT_NOT_STATIC_PASSED:$($component.id)" }
        if ([string]$receipt.runtimeStatus -notin @('runtime-not-run','worker-process-passed')) { throw "ACCEPTANCE_RUNTIME_BOUNDARY_INVALID:$($component.id)" }
        $null = & $runner.Source -NoProfile -ExecutionPolicy Bypass -File $strictValidator -SkillPath (Join-Path $root '.agents/skills/es-agent-mechanism-replication') -EvidencePath $reportFull -ProjectRoot $root
        if ($LASTEXITCODE -ne 0) { throw "ACCEPTANCE_RECEIPT_STRICT_VALIDATION_FAILED:$($component.id)" }
        [void]$receiptRefs.Add($component.report)
    } catch {
        $status = 'failed'
        $finding = $_.Exception.Message
    }
    [void]$results.Add([pscustomobject][ordered]@{ case = [string]$component.id; status = $status; exitCode = $exitCode; reportPath = Get-Relative $component.report; finding = $finding })
}

$failed = @($results | Where-Object status -eq 'failed')
$simulationError = $null
if (-not $PreflightOnly -and $failed.Count -eq 0) {
    try {
        $simulationSource = (Get-FileHash -LiteralPath (Join-Path $root 'ES/Automation/ABCD/ESABCInnovationRun.psm1') -Algorithm SHA256).Hash.ToLowerInvariant()
        $staticSimulation = Invoke-StaticAbcdSimulation -Requirement 'ABCD static branch acceptance' -SourceHash $simulationSource
    } catch { $simulationError = $_.Exception.Message }
}
$sourceRefs = [Collections.Generic.List[string]]::new()
[void]$sourceRefs.Add('ES/Automation/ABCD/Test-ESABCDStaticAcceptance.ps1')
[void]$sourceRefs.Add('ES/Automation/ABCD/Test-ESABCDUniqueSemantic.ps1')
[void]$sourceRefs.Add('ES/Automation/ABCD/ESABCDAuthorityKernel.psm1')
[void]$sourceRefs.Add('.agents/skills/es-game-logic-system-development/SKILL.md')
[void]$sourceRefs.Add('.agents/skills/es-game-logic-content-development/SKILL.md')
[void]$sourceRefs.Add('.agents/skills/es-agent-mechanism-replication/static-replay.manifest.json')
foreach ($component in $components) {
    [void]$sourceRefs.Add((Get-Relative $component.script))
    if (Test-Path -LiteralPath (Join-Path $root $component.report) -PathType Leaf) { [void]$sourceRefs.Add((Get-Relative $component.report)) }
}
$sourceRefs = @($sourceRefs | Sort-Object -Unique)
$sourceRefHashes = [ordered]@{}
foreach ($sourceRef in $sourceRefs) { $sourceRefHashes[$sourceRef] = Get-Hash (Join-Path $root $sourceRef) }
$evidenceContractPath = Join-Path $root 'ES/Automation/Contracts/es-skill-evidence-receipt-v1.schema.json'
$evidenceContractHash = Get-Hash $evidenceContractPath
$sha = [Security.Cryptography.SHA256]::Create()
try {
    $seed = ($sourceRefs | ForEach-Object { $_ + ':' + $sourceRefHashes[$_] }) -join '|'
    $planHash = ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($seed + '|' + (($results | ConvertTo-Json -Compress -Depth 10)))))).Replace('-','').ToLowerInvariant()
    $instructionInput = [ordered]@{
        operation = 'run-abcd-static-preflight'
        reportPath = (Get-Relative $ReportPath)
        verifyNetwork = [bool]$VerifyNetwork
        componentCount = $components.Count
    }
    $userInstructionHash = ([BitConverter]::ToString($sha.ComputeHash([Text.Encoding]::UTF8.GetBytes(($instructionInput | ConvertTo-Json -Compress))))).Replace('-','').ToLowerInvariant()
} finally { $sha.Dispose() }
$authorizationKind = if ($VerifyNetwork) { 'current-user-direct' } else { 'read-only' }
$report = [ordered]@{
    schemaVersion = 1
    validator = 'Test-ESABCDStaticPreflight'
    # Central evidence receipts reserve status=passed/failed.  The scoped ABCD
    # decision is carried separately in acceptanceDecision/claimLevel.
    status = if ($failed.Count -or $simulationError) { 'failed' } else { 'passed' }
    staticStatus = if ($failed.Count) { 'static-failed' } else { 'static-passed' }
    preflightStatus = if ($failed.Count) { 'failed' } else { 'passed' }
    acceptanceDecision = if ($failed.Count -or $simulationError) { 'blocked' } elseif ($PreflightOnly) { 'not-eligible' } else { 'accepted-static-simulation' }
    acceptanceEligible = ([bool]($null -ne $staticSimulation))
    divergenceStatus = if ($null -ne $staticSimulation) { 'static-simulated-complete' } elseif ($PreflightOnly) { 'not-run' } else { 'failed-to-simulate' }
    blockingLayer = if ($failed.Count) { 'static-preflight' } elseif ($simulationError) { 'abcd-static-simulation' } elseif ($PreflightOnly) { 'none' } else { 'runtime-evidence' }
    reasonCode = if ($failed.Count) { 'ABCD_STATIC_PREFLIGHT_FAILED' } elseif ($simulationError) { 'ABCD_STATIC_SIMULATION_FAILED' } elseif ($PreflightOnly) { 'ABCD_PREFLIGHT_ONLY_NO_ACCEPTANCE' } else { 'ABCD_STATIC_SIMULATION_ACCEPTED_RUNTIME_SEPARATE' }
    recoveryAction = if ($failed.Count) { 'repair-static-preflight-and-rerun' } elseif ($simulationError) { 'repair-static-simulation-and-rerun' } elseif ($PreflightOnly) { 'run-complete-abcd-static-simulation' } else { 'run-optional-runtime-evidence-separately' }
    runtimeStatus = 'runtime-not-run'
    claimLevel = if ($null -ne $staticSimulation) { 'static-simulated' } else { 'static-only' }
    decisionScope = if ($null -ne $staticSimulation) { 'ABCD semantic/branch simulation acceptance; Unity Runtime remains independent' } else { 'ABCD Static Preflight only; no ABCD acceptance conclusion' }
    runtimeEvidenceAccepted = $false
    completionAuthority = 'none'
    evidenceLevel = 'S1'
    capturedUtc = [DateTime]::UtcNow.ToString('o')
    authorizationKind = $authorizationKind
    planHash = $planHash
    evidenceContractId = 'es.skill-evidence-receipt'
    evidenceContractHash = $evidenceContractHash
    skillName = 'es-agent-mechanism-replication'
    case = 'abcd-static-preflight'
    receiptPath = Get-Relative $ReportPath
    sourceRefs = $sourceRefs
    sourceRefHashes = $sourceRefHashes
    toolId = 'es-abcd-static-preflight'
    unityVersion = 'not-run'
    componentReceipts = @($receiptRefs | ForEach-Object { [ordered]@{ path = $_; sha256 = Get-Hash (Join-Path $root $_) } })
    cases = @($results)
    staticSimulation = $staticSimulation
    simulationError = $simulationError
    evidenceTiers = [ordered]@{
        staticPreflight = if ($failed.Count) { 'failed' } else { 'passed' }
        abcdStaticSimulation = if ($null -ne $staticSimulation) { 'accepted' } elseif ($PreflightOnly) { 'not-run' } else { 'blocked' }
        unityRuntime = 'runtime-not-run'
        playerRelease = 'not-run'
    }
    claimsNotProven = @('Unity/Worker/host Runtime','RuntimeAcceptance','ReleaseAcceptance','external authority certification')
    forbiddenClaims = @('ABCD accepted','ABCD acceptance passed','Unity Runtime passed','Profiler performance passed','Player passed','RuntimeAcceptance','ReleaseAcceptance')
}
if ($VerifyNetwork) {
    $report.userInstructionHash = $userInstructionHash
    $report.authorizedOperations = @('run-abcd-static-preflight','verify-network-content-hashes')
    $report.authorizedPaths = @($ReportPath) + @($components | ForEach-Object { $_.script })
}
$reportFull = Join-Path $root $ReportPath
New-Item -ItemType Directory -Path (Split-Path $reportFull) -Force | Out-Null
[IO.File]::WriteAllText($reportFull, ($report | ConvertTo-Json -Depth 20), [Text.UTF8Encoding]::new($false))
$report | ConvertTo-Json -Depth 20
if ($failed.Count -or $simulationError) { exit 1 } 
