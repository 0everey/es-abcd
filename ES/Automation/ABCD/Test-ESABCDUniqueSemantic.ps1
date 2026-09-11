[CmdletBinding()]
param(
    [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$kernel = Join-Path $root 'ES\Automation\ABCD\ESABCDAuthorityKernel.psm1'
if (-not (Test-Path -LiteralPath $kernel -PathType Leaf)) { throw 'ABCD_AUTHORITY_KERNEL_MISSING' }

$required = @(
    'bounded-tool-action', 'failure-recovery', 'branch-evaluation',
    'state-transition-guard', 'environment-trust-gate', 'audit-evidence-chain'
)
$kernelText = Get-Content -LiteralPath $kernel -Raw -Encoding UTF8
$missing = @($required | Where-Object { $kernelText -notmatch [regex]::Escape("'$_'") })

$scanRoots = @(
    (Join-Path $root '.agents\skills\es-game-logic-system-development'),
    (Join-Path $root '.agents\skills\es-game-logic-content-development'),
    (Join-Path $root 'ES\Automation\ABCD'),
    (Join-Path $root 'ES\Automation\Contracts')
)
$forbidden = @()
$forbiddenPattern = ('ABCD' + 'N') + '|' + ('abcd' + 'n-')
foreach ($scanRoot in $scanRoots) {
    if (-not (Test-Path -LiteralPath $scanRoot)) { continue }
    $forbidden += @(Get-ChildItem -LiteralPath $scanRoot -Recurse -File | Where-Object { $_.FullName -ne $PSCommandPath } | Select-String -Pattern $forbiddenPattern -CaseSensitive:$false | ForEach-Object {
        [ordered]@{ path = $_.Path.Substring($root.Length).TrimStart('\'); line = $_.LineNumber }
    })
}

$engineeringMethodFindings = @()
$engineeringSkillPaths = @(
    '.agents/skills/es-game-logic-system-development/SKILL.md',
    '.agents/skills/es-game-logic-content-development/SKILL.md'
)
foreach ($relativePath in $engineeringSkillPaths) {
    $fullPath = Join-Path $root $relativePath
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        $engineeringMethodFindings += [ordered]@{ path = $relativePath; reason = 'engineering-method-skill-missing' }
        continue
    }
    $text = Get-Content -LiteralPath $fullPath -Raw -Encoding UTF8
    if ($text -notmatch [regex]::Escape('EngineeringMethodBoundary: analysis-only; no-score; no-state-machine; no-final-decision; no-acceptance')) {
        $engineeringMethodFindings += [ordered]@{ path = $relativePath; reason = 'engineering-method-boundary-statement-missing' }
    }
    if ($text -match "(?m)^\s*-\s+\*\*[ABCDN](?:\s|\b)") {
        $engineeringMethodFindings += [ordered]@{ path = $relativePath; reason = 'engineering-method-letter-stage-label-forbidden' }
    }
    if ($text -match "(?im)^\s*(?:[-*]\s*)?\*\*(?:score|status|finalDecision|final-decision)" -or $text -match "(?im)^\s*(?:score|status|finalDecision|final-decision)\s*[:=]") {
        $engineeringMethodFindings += [ordered]@{ path = $relativePath; reason = 'engineering-method-evaluation-output-forbidden' }
    }
}

$staticClaimBoundaryFindings = @()
$staticAcceptancePath = Join-Path $root 'ES/Automation/ABCD/Test-ESABCDStaticAcceptance.ps1'
if (-not (Test-Path -LiteralPath $staticAcceptancePath -PathType Leaf)) {
    $staticClaimBoundaryFindings += 'static-acceptance-script-missing'
} else {
    $staticAcceptanceText = Get-Content -LiteralPath $staticAcceptancePath -Raw -Encoding UTF8
    foreach ($requiredClaimBoundary in @(
        "runtimeStatus = 'runtime-not-run'",
        "claimLevel = 'static-only'",
        "runtimeEvidenceAccepted = `$false",
        "completionAuthority = 'none'",
        "acceptanceDecision = 'not-eligible'",
        "acceptanceEligible = `$false",
        "decisionScope = 'ABCD Static Preflight only; no ABCD acceptance conclusion'",
        'forbiddenClaims = @('
    )) {
        if ($staticAcceptanceText -notmatch [regex]::Escape($requiredClaimBoundary)) {
            $staticClaimBoundaryFindings += "static-claim-boundary-missing:$requiredClaimBoundary"
        }
    }
}

$status = if ($missing.Count -eq 0 -and $forbidden.Count -eq 0 -and $engineeringMethodFindings.Count -eq 0 -and $staticClaimBoundaryFindings.Count -eq 0) { 'passed' } else { 'failed' }
[ordered]@{
    schemaVersion = 1
    validator = 'es-abcd-unique-semantic'
    status = $status
    authorityKernel = 'ES/Automation/ABCD/ESABCDAuthorityKernel.psm1'
    requiredCanonicalCapabilities = $required
    missingCanonicalCapabilities = $missing
    forbiddenDerivedReferences = $forbidden
    engineeringMethodBoundaryFindings = $engineeringMethodFindings
    staticClaimBoundaryFindings = $staticClaimBoundaryFindings
    runtimeStatus = 'runtime-not-run'
    nonClaims = @('does not prove Unity/runtime behavior', 'does not alter ABCD authority')
} | ConvertTo-Json -Depth 8
if ($status -ne 'passed') { exit 1 } 
