[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$PromptText,
    [string]$ProjectRoot = ''
)

# Portable resolver: reads only mode-registry monoSemanticLock under ProjectRoot.
# No AIWarnings/AGENTS/Unity. Host-specific gates stay in each repo's mono *test*.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$OutputEncoding = [Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)

if ([string]::IsNullOrWhiteSpace($PromptText)) {
    throw 'PromptText must not be empty.'
}

$root = if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
} else {
    (Resolve-Path -LiteralPath $ProjectRoot).Path
}

$registryPath = Join-Path $root 'ES\Automation\Contracts\es-ai-abc-mode.registry.json'
if (-not (Test-Path -LiteralPath $registryPath -PathType Leaf)) {
    throw "ABCD_MODE_REGISTRY_MISSING: $registryPath"
}

$reg = Get-Content -LiteralPath $registryPath -Raw -Encoding UTF8 | ConvertFrom-Json
$lock = $reg.namingAuthority.monoSemanticLock
if ($null -eq $lock) {
    throw 'ABCD_MONO_SEMANTIC_LOCK_MISSING'
}

$onlyModeId = [string]$lock.onlyModeId
if ($onlyModeId -cne 'ABCD.Dynamic') {
    throw "ABCD_MONO_SEMANTIC_ONLY_MODE_DRIFT: expected ABCD.Dynamic got $onlyModeId"
}

$cardinality = 1
if ($null -ne $lock.semanticCardinality) {
    $cardinality = [int]$lock.semanticCardinality
}
if ($cardinality -ne 1) {
    throw "ABCD_SEMANTIC_CARDINALITY_INVALID: must be 1, got $cardinality"
}

$possible = @($lock.possibleModeIds | ForEach-Object { [string]$_ })
if ($possible.Count -eq 0) {
    $possible = @('ABCD.Dynamic')
}
if ($possible.Count -ne 1 -or $possible[0] -cne 'ABCD.Dynamic') {
    throw 'ABCD_POSSIBLE_MODE_IDS_MUST_BE_SINGLE_ABCD.Dynamic'
}

$text = [string]$PromptText

# Word-boundary-ish ABCD hit (ASCII token). Also accept explicit mode id.
$abcdHit = $false
if ($text -match '(?i)(?<![A-Za-z0-9])ABCD(?![A-Za-z0-9])') { $abcdHit = $true }
if ($text -match '(?i)ABCD\.Dynamic') { $abcdHit = $true }
# Chinese short name: dong-tai-xie-zuo-ti (ES dynamic collaborator body)
if ($text -match "\u52a8\u6001\u534f\u4f5c\u4f53") { $abcdHit = $true }

$abccHit = [bool]($text -match '(?i)(?<![A-Za-z0-9])ABCC(?![A-Za-z0-9])' -or $text -match '(?i)ABCC\.Core')
$abcpHit = [bool]($text -match '(?i)(?<![A-Za-z0-9])ABCP(?![A-Za-z0-9])' -or $text -match '(?i)ABCP\.Part')

# Second-meaning pollution detectors. Chinese via \u to keep source ASCII-safe.
# gong-cheng = engineering; jia-gou = architecture; xing-wei = behavior;
# cheng-ben = cost; zheng-ju = evidence; jiao-fu = delivery.
$pollutionPatterns = @(
    "(?i)\u5de5\u7a0b\s*ABCD",
    "(?i)ABCD\s*\u5de5\u7a0b",
    "(?i)ABCD\s*\u5de5\u7a0b\u7ea7",
    "(?i)\u5de5\u7a0b\u7ea7\s*ABCD",
    '(?i)engineering[- ]four[- ]letter',
    '(?i)engineering\s+ABCD',
    "(?i)A\s*[=:\uFF1A]\s*\u67b6\u6784",
    "(?i)B\s*[=:\uFF1A]\s*\u884c\u4e3a",
    "(?i)C\s*[=:\uFF1A]\s*\u6210\u672c",
    "(?i)D\s*[=:\uFF1A]\s*\u8bc1\u636e",
    "(?i)D\s*[=:\uFF1A]\s*\u4ea4\u4ed8",
    # Compact Chinese four-letter without equals: A架构 B行为 C成本 D证据
    "(?i)A\u67b6\u6784.*B\u884c\u4e3a.*C\u6210\u672c.*D\u8bc1\u636e",
    '(?i)A\s*=\s*architecture',
    '(?i)C\s*=\s*cost',
    '(?i)D\s*=\s*deliver',
    '(?i)D\s*=\s*evidence',
    "(?i)\u56db\u6bb5\u68c0\u67e5.*ABCD|ABCD.*\u56db\u6bb5\u68c0\u67e5",
    "(?i)\u4e5f\u53ef\u4ee5\u6307.*ABCD|ABCD.*\u4e5f\u53ef\u4ee5\u6307",
    '(?i)second meaning of ABCD',
    '(?i)window[- ]responsibility[- ]ABCD'
)

$pollutionHits = [System.Collections.Generic.List[string]]::new()
foreach ($pat in $pollutionPatterns) {
    if ($text -match $pat) {
        [void]$pollutionHits.Add($pat)
    }
}
$pollutionDetected = $pollutionHits.Count -gt 0

# Registry permanent ban: engineering four-letter is NEVER a correct ABCD semantic.
$neverEntry = $null
foreach ($entry in @($lock.neverValidAsCorrectSemantic)) {
    if ([string]$entry.id -eq 'engineering-four-letter-ABCD') {
        $neverEntry = $entry
        break
    }
}
if ($null -eq $neverEntry) {
    throw 'ABCD_NEVER_VALID_ENGINEERING_FOUR_LETTER_MISSING'
}
if ([bool]$neverEntry.isCorrectSemantic -ne $false) {
    throw 'ABCD_ENGINEERING_FOUR_LETTER_MUST_NEVER_BE_CORRECT_SEMANTIC'
}
if ([bool]$neverEntry.mayPresentAsCorrectSemantic -ne $false) {
    throw 'ABCD_ENGINEERING_FOUR_LETTER_MAY_PRESENT_AS_CORRECT_MUST_BE_FALSE'
}
if ([bool]$neverEntry.permanent -ne $true) {
    throw 'ABCD_ENGINEERING_FOUR_LETTER_BAN_MUST_BE_PERMANENT'
}

$substituteNames = @($neverEntry.substituteNames | ForEach-Object { [string]$_ })
if ($substituteNames.Count -lt 3) {
    throw 'ABCD_ENGINEERING_SUBSTITUTE_NAMES_INCOMPLETE'
}

# Bare ABCD must never resolve to ABCC/ABCP or any other mode.
$resolvedModeId = $null
$decision = 'not-applicable'
$secondMeaningRejected = $false
$status = 'not-hit'

if ($abcdHit -or $pollutionDetected) {
    $status = 'locked'
    $resolvedModeId = 'ABCD.Dynamic'
    $secondMeaningRejected = $true
    if ($pollutionDetected) {
        $decision = if ([string]$lock.pollutionDecision) { [string]$lock.pollutionDecision } else { 'claim-cap' }
    } else {
        $decision = 'mono-semantic-lock'
    }
}

# Sibling modes are different identities; they do not rewrite ABCD.
$siblingNotes = [System.Collections.Generic.List[string]]::new()
if ($abccHit) { [void]$siblingNotes.Add('ABCC.Core-is-distinct-modeId-not-ABCD-alias') }
if ($abcpHit) { [void]$siblingNotes.Add('ABCP.Part-is-distinct-modeId-not-ABCD-alias') }

$claimCap = $false
if ($pollutionDetected) { $claimCap = $true }
if ($abcdHit -and [bool]$lock.claimCapWithoutInnovationRun) {
    # Resolver itself does not prove InnovationRun; expansion still claim-caps acceptance.
    $claimCap = $true
}

# Engineering four-letter family: hard constants — never correct, never Accepted as ABCD.
$engineeringFourLetter = [ordered]@{
    id = 'engineering-four-letter-ABCD'
    isCorrectSemantic = $false
    mayPresentAsCorrectSemantic = $false
    mayClaimAccepted = $false
    mayUseTokenABCD = $false
    permanent = $true
    hit = $pollutionDetected
    onHit = 'claim-cap'
    renameTo = $substituteNames
}

[ordered]@{
    schemaVersion = 2
    resolver = 'es-abcd-mono-semantic'
    status = $status
    token = 'ABCD'
    semanticCardinality = 1
    possibleModeIds = @('ABCD.Dynamic')
    onlyModeId = 'ABCD.Dynamic'
    resolvedModeId = $resolvedModeId
    secondMeaningPolicy = 'blocked'
    secondMeaningAllowed = $false
    secondMeaningRejected = $secondMeaningRejected
    contextCannotRewriteIdentity = $true
    abcdHit = $abcdHit
    pollutionDetected = $pollutionDetected
    pollutionPatterns = @($pollutionHits)
    decision = $decision
    claimCap = $claimCap
    # Permanent: engineering four-letter can never be emitted as the correct ABCD semantic.
    engineeringFourLetter = $engineeringFourLetter
    isCorrectSemantic = if ($pollutionDetected) { $false } else { $null }
    mayPresentAsCorrectSemantic = if ($pollutionDetected) { $false } else { $null }
    p0RuleId = [string]$lock.p0RuleId
    requiredSkillPath = [string]$lock.onlySkillPath
    requiredContractPath = 'ES/Automation/Contracts/es-ai-abc-mode.registry.json'
    siblingModeNotes = @($siblingNotes)
    hostMustResolveBeforeExpand = [bool]$lock.hostMustResolveBeforeExpand
    nonClaims = @(
        'Does not execute InnovationRun',
        'Does not prove Unity Runtime or release',
        'Does not grant write authority',
        'Engineering four-letter checklist is never a correct ABCD semantic'
    )
} | ConvertTo-Json -Depth 8
