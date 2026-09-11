[CmdletBinding()]
param(
    [string]$ProjectRoot = ''
)

# Portable mono-semantic authority check for es-abcd.
# Does NOT require ESFramework AIWarnings corpus, AGENTS super-semantics, or Unity.
# Encoding: ASCII-primary for Windows PowerShell 5.1 parser safety.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $ProjectRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
} else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
}
$root = $ProjectRoot
$errors = [System.Collections.Generic.List[string]]::new()

$registryPath = Join-Path $root 'ES\Automation\Contracts\es-ai-abc-mode.registry.json'
$resolverPath = Join-Path $root 'ES\Automation\ABCD\Resolve-ESABCDMonoSemantic.ps1'
$skillPath = Join-Path $root '.agents\skills\es-ai-abc-core\SKILL.md'
$conceptsPath = Join-Path $root 'docs\concepts.md'
$govPath = Join-Path $root 'ES\Automation\ABCD\portable\es-abcd-portable-governance-v1.json'
$readmePath = Join-Path $root 'README.md'

if (-not (Test-Path -LiteralPath $registryPath -PathType Leaf)) {
    [void]$errors.Add('mode-registry-missing')
} else {
    $reg = Get-Content -LiteralPath $registryPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $lock = $reg.namingAuthority.monoSemanticLock
    if ($null -eq $lock) {
        [void]$errors.Add('monoSemanticLock-missing')
    } else {
        if ([string]$lock.token -cne 'ABCD') { [void]$errors.Add('token-must-be-ABCD') }
        if ([string]$lock.onlyModeId -cne 'ABCD.Dynamic') { [void]$errors.Add('onlyModeId-must-be-ABCD.Dynamic') }
        if ([int]$lock.semanticCardinality -ne 1) { [void]$errors.Add('semanticCardinality-must-be-1') }
        $possible = @($lock.possibleModeIds | ForEach-Object { [string]$_ })
        if ($possible.Count -ne 1 -or $possible[0] -cne 'ABCD.Dynamic') {
            [void]$errors.Add('possibleModeIds-must-be-exactly-ABCD.Dynamic')
        }
        if ([string]$lock.secondMeaningPolicy -cne 'blocked') {
            [void]$errors.Add('secondMeaningPolicy-must-be-blocked')
        }
        if ([string]$lock.interpretationPolicy -cne 'hard-fail-second-meaning') {
            [void]$errors.Add('interpretationPolicy-must-hard-fail-second-meaning')
        }
        if ([bool]$lock.contextCannotRewriteIdentity -ne $true) {
            [void]$errors.Add('contextCannotRewriteIdentity-must-be-true')
        }
        if ([bool]$lock.hostMustResolveBeforeExpand -ne $true) {
            [void]$errors.Add('hostMustResolveBeforeExpand-must-be-true')
        }
        if ([string]$lock.resolverPath -notmatch 'Resolve-ESABCDMonoSemantic\.ps1') {
            [void]$errors.Add('resolverPath-must-point-to-Resolve-ESABCDMonoSemantic')
        }
        if ([string]$lock.roleLetters.D -notmatch 'Dynamic') { [void]$errors.Add('D-must-be-Dynamic-suffix') }
        $forb = @($lock.forbiddenInterpretations | ForEach-Object { [string]$_ })
        foreach ($need in @(
                'engineering-four-letter-checklist',
                'context-dependent-second-meaning-of-ABCD',
                'A=architecture / B=behavior-or-implementation / C=cost / D=delivery-or-evidence'
            )) {
            if ($forb -notcontains $need) { [void]$errors.Add("forbidden-missing:$need") }
        }
        if ([bool]$lock.claimCapWithoutInnovationRun -ne $true) {
            [void]$errors.Add('claimCapWithoutInnovationRun-must-be-true')
        }
        if ([string]$lock.pollutionDecision -cne 'claim-cap') {
            [void]$errors.Add('pollutionDecision-must-claim-cap')
        }
        # Portable rule id (not ESFramework AIWarnings corpus dependent).
        if ([string]$lock.p0RuleId -cne 'es.abcd.p0.abcd-identity-mono-semantic.v1') {
            [void]$errors.Add('p0RuleId-must-be-portable-es.abcd.p0.abcd-identity-mono-semantic.v1')
        }
        $never = @($lock.neverValidAsCorrectSemantic | Where-Object { [string]$_.id -eq 'engineering-four-letter-ABCD' }) |
            Select-Object -First 1
        if ($null -eq $never) {
            [void]$errors.Add('neverValidAsCorrectSemantic-engineering-four-letter-missing')
        } else {
            if ([bool]$never.isCorrectSemantic -ne $false) {
                [void]$errors.Add('engineering-four-letter-isCorrectSemantic-must-be-false')
            }
            if ([bool]$never.mayPresentAsCorrectSemantic -ne $false) {
                [void]$errors.Add('engineering-four-letter-mayPresentAsCorrectSemantic-must-be-false')
            }
            if ([bool]$never.mayClaimAccepted -ne $false) {
                [void]$errors.Add('engineering-four-letter-mayClaimAccepted-must-be-false')
            }
            if ([bool]$never.permanent -ne $true) {
                [void]$errors.Add('engineering-four-letter-ban-must-be-permanent')
            }
            if ([bool]$never.mayUseTokenABCD -ne $false) {
                [void]$errors.Add('engineering-four-letter-mayUseTokenABCD-must-be-false')
            }
            $subs = @($never.substituteNames | ForEach-Object { [string]$_ })
            foreach ($needSub in @('engineering-method', 'five-stage', 'four-layer-validation')) {
                if ($subs -notcontains $needSub) {
                    [void]$errors.Add("engineering-substitute-missing:$needSub")
                }
            }
        }
    }
}

if (-not (Test-Path -LiteralPath $govPath -PathType Leaf)) {
    [void]$errors.Add('portable-governance-missing')
} else {
    $gov = Get-Content -LiteralPath $govPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $rule = @($gov.mandatoryRules | Where-Object {
            [string]$_.ruleId -eq 'es.abcd.p0.abcd-identity-mono-semantic.v1'
        }) | Select-Object -First 1
    if ($null -eq $rule) {
        [void]$errors.Add('portable-governance-missing-mono-semantic-rule')
    } else {
        if ([string]$rule.decision -cne 'claim-cap') {
            [void]$errors.Add('portable-mono-rule-decision-must-claim-cap')
        }
        $match = @($rule.match | ForEach-Object { [string]$_ })
        foreach ($m in @('ABCD', 'engineering ABCD', 'monoSemanticLock')) {
            if ($match -notcontains $m) { [void]$errors.Add("portable-mono-rule-match-missing:$m") }
        }
    }
}

if (-not (Test-Path -LiteralPath $skillPath -PathType Leaf)) {
    [void]$errors.Add('es-ai-abc-core-missing')
} else {
    $sk = Get-Content -LiteralPath $skillPath -Raw -Encoding UTF8
    if ($sk -notmatch 'Mono-semantic lock|monoSemanticLock|semanticCardinality') {
        [void]$errors.Add('es-ai-abc-core-missing-mono-lock')
    }
    if ($sk -notmatch 'Resolve-ESABCDMonoSemantic') {
        [void]$errors.Add('es-ai-abc-core-missing-hard-resolver')
    }
    if ($sk -notmatch 'neverValidAsCorrectSemantic|engineering-four-letter') {
        [void]$errors.Add('es-ai-abc-core-missing-never-correct-engineering')
    }
}

if (-not (Test-Path -LiteralPath $conceptsPath -PathType Leaf)) {
    [void]$errors.Add('docs-concepts-missing')
} else {
    $cx = Get-Content -LiteralPath $conceptsPath -Raw -Encoding UTF8
    if ($cx -notmatch 'monoSemanticLock|semanticCardinality|ABCD\.Dynamic') {
        [void]$errors.Add('docs-concepts-missing-mono-semantic')
    }
    if ($cx -notmatch 'engineering-method|neverValidAsCorrectSemantic|isCorrectSemantic') {
        [void]$errors.Add('docs-concepts-missing-engineering-never-correct')
    }
}

# Machine naming pointers: prefer stable docs/naming-abcd.md (README is user-facing and may stay plain-language).
$namingDoc = Join-Path $root 'docs\naming-abcd.md'
$namingBlob = ''
if (Test-Path -LiteralPath $namingDoc -PathType Leaf) {
    $namingBlob = Get-Content -LiteralPath $namingDoc -Raw -Encoding UTF8
}
if (Test-Path -LiteralPath $readmePath -PathType Leaf) {
    $namingBlob += "`n" + (Get-Content -LiteralPath $readmePath -Raw -Encoding UTF8)
}
if (Test-Path -LiteralPath $conceptsPath -PathType Leaf) {
    $namingBlob += "`n" + (Get-Content -LiteralPath $conceptsPath -Raw -Encoding UTF8)
}
if ($namingBlob -notmatch 'monoSemanticLock|Resolve-ESABCDMonoSemantic|semanticCardinality') {
    [void]$errors.Add('docs-missing-mono-semantic-pointer')
}
if ($namingBlob -notmatch 'abcdModeFunctionLevelMapping|Resolve-ESABCDGenerationMode|creative-divergence') {
    [void]$errors.Add('docs-missing-generation-mode-mapping-pointer')
}

$resolveProofs = [System.Collections.Generic.List[object]]::new()
if (-not (Test-Path -LiteralPath $resolverPath -PathType Leaf)) {
    [void]$errors.Add('resolver-script-missing')
} else {
    function Invoke-MonoResolve([string]$prompt) {
        $json = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $resolverPath -PromptText $prompt -ProjectRoot $root 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "resolver-exit-$LASTEXITCODE : $json"
        }
        return ($json | Out-String | ConvertFrom-Json)
    }

    try {
        $clean = Invoke-MonoResolve 'Please run ABCD validation for this task'
        if ([string]$clean.status -cne 'locked') { [void]$errors.Add('resolve-clean-status-not-locked') }
        if ([string]$clean.resolvedModeId -cne 'ABCD.Dynamic') { [void]$errors.Add('resolve-clean-resolvedModeId-drift') }
        if ([int]$clean.semanticCardinality -ne 1) { [void]$errors.Add('resolve-clean-cardinality-not-1') }
        if ([bool]$clean.secondMeaningAllowed -ne $false) { [void]$errors.Add('resolve-clean-secondMeaningAllowed-must-false') }
        [void]$resolveProofs.Add([ordered]@{ case = 'clean-ABCD'; resolvedModeId = [string]$clean.resolvedModeId })

        $polluted = Invoke-MonoResolve 'Use engineering ABCD: A=architecture B=behavior C=cost D=evidence'
        if ([bool]$polluted.pollutionDetected -ne $true) { [void]$errors.Add('resolve-polluted-must-detect-pollution') }
        if ([string]$polluted.decision -cne 'claim-cap') { [void]$errors.Add('resolve-polluted-decision-must-claim-cap') }
        if ([bool]$polluted.isCorrectSemantic -ne $false) { [void]$errors.Add('resolve-polluted-isCorrectSemantic-must-be-false') }
        if ([bool]$polluted.mayPresentAsCorrectSemantic -ne $false) {
            [void]$errors.Add('resolve-polluted-mayPresentAsCorrectSemantic-must-be-false')
        }
        if ([string]$polluted.resolvedModeId -cne 'ABCD.Dynamic') {
            [void]$errors.Add('resolve-polluted-must-still-only-ABCD.Dynamic')
        }
        if ($null -eq $polluted.engineeringFourLetter -or [bool]$polluted.engineeringFourLetter.permanent -ne $true) {
            [void]$errors.Add('resolve-polluted-engineeringFourLetter-permanent-missing')
        }
        if ($null -ne $polluted.engineeringFourLetter -and [bool]$polluted.engineeringFourLetter.mayUseTokenABCD -ne $false) {
            [void]$errors.Add('resolve-polluted-mayUseTokenABCD-must-be-false')
        }
        [void]$resolveProofs.Add([ordered]@{
                case = 'polluted-engineering-ABCD-never-correct'
                pollutionDetected = [bool]$polluted.pollutionDetected
                isCorrectSemantic = [bool]$polluted.isCorrectSemantic
                decision = [string]$polluted.decision
                resolvedModeId = [string]$polluted.resolvedModeId
            })

        $zhPrompt = 'A' + [char]0x67B6 + [char]0x6784 + ' B' + [char]0x884C + [char]0x4E3A +
            ' C' + [char]0x6210 + [char]0x672C + ' D' + [char]0x8BC1 + [char]0x636E + ' ABCD'
        $zh = Invoke-MonoResolve $zhPrompt
        if ([bool]$zh.pollutionDetected -ne $true) { [void]$errors.Add('resolve-zh-must-detect-pollution') }
        if ([bool]$zh.isCorrectSemantic -ne $false) { [void]$errors.Add('resolve-zh-isCorrectSemantic-must-be-false') }
        if ([string]$zh.decision -cne 'claim-cap') { [void]$errors.Add('resolve-zh-decision-must-claim-cap') }
        [void]$resolveProofs.Add([ordered]@{
                case = 'zh-four-letter-never-correct'
                pollutionDetected = [bool]$zh.pollutionDetected
                isCorrectSemantic = [bool]$zh.isCorrectSemantic
                decision = [string]$zh.decision
            })
    }
    catch {
        [void]$errors.Add("resolve-fixture-exception:$($_.Exception.Message)")
    }
}

$status = if ($errors.Count -eq 0) { 'passed' } else { 'failed' }
[ordered]@{
    schemaVersion = 1
    validator = 'es-abcd-mono-semantic-authority-portable'
    package = 'es-abcd'
    status = $status
    onlyModeId = 'ABCD.Dynamic'
    semanticCardinality = 1
    possibleModeIds = @('ABCD.Dynamic')
    secondMeaningPolicy = 'blocked'
    monoSemantic = $true
    engineeringFourLetterNeverCorrect = $true
    requiresESFramework = $false
    requiresAIWarningsCorpus = $false
    resolveProofs = @($resolveProofs)
    findings = @($errors)
    runtimeStatus = 'runtime-not-run'
    nonClaims = @(
        'Does not prove InnovationRun execution',
        'Does not prove Unity Runtime or release',
        'Does not require ESFramework host'
    )
} | ConvertTo-Json -Depth 8

if ($errors.Count -gt 0) { exit 1 } 
