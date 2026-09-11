[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$PromptText,
    [string]$ProjectRoot = ''
)

# Resolve ABCD mode/function/level to generation modes only (not Dynamic/Core/Part).
# Portable: contracts under ProjectRoot only. No ES host corpus required.
# ASCII-only source for Windows PowerShell 5.1 parser safety.

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

$genPath = Join-Path $root 'ES\Automation\Contracts\es-ai-abc-generation-mode-v1.json'
$regPath = Join-Path $root 'ES\Automation\Contracts\es-ai-abc-mode.registry.json'
if (-not (Test-Path -LiteralPath $genPath -PathType Leaf)) {
    throw "GENERATION_MODE_CONTRACT_MISSING: $genPath"
}
if (-not (Test-Path -LiteralPath $regPath -PathType Leaf)) {
    throw "MODE_REGISTRY_MISSING: $regPath"
}

$gen = Get-Content -LiteralPath $genPath -Raw -Encoding UTF8 | ConvertFrom-Json
$map = $gen.abcdModeFunctionLevelMapping
if ($null -eq $map) {
    throw 'ABCD_MODE_FUNCTION_LEVEL_MAPPING_MISSING'
}

$allowed = @($map.mapsToGenerationModeIds | ForEach-Object { [string]$_ })
if ($allowed.Count -ne 3) {
    throw 'ABCD_MODE_FUNCTION_LEVEL_MUST_HAVE_EXACTLY_THREE_GENERATION_MODES'
}
foreach ($need in @('creative-divergence', 'engineering', 'stable')) {
    if ($allowed -notcontains $need) {
        throw "ABCD_MODE_FUNCTION_LEVEL_MISSING_MODE:$need"
    }
}

$text = [string]$PromptText
$axisHit = $false

# mode / function / level / tier + CJK via \u escapes only
$axisPatterns = @(
    '(?i)ABCD\s*mode',
    '(?i)ABCD\s*function',
    '(?i)ABCD\s*level',
    '(?i)ABCD\s*tier',
    '(?i)generation\s*mode',
    "(?i)ABCD\s*\u6a21\u5f0f",
    "(?i)ABCD\s*\u529f\u80fd",
    "(?i)ABCD\s*\u7ea7",
    "(?i)\u751f\u6210\u6a21\u5f0f"
)
foreach ($pat in $axisPatterns) {
    if ($text -match $pat) { $axisHit = $true; break }
}

$labelHits = [System.Collections.Generic.List[string]]::new()
$labelMap = @{
    'creative-divergence' = @(
        '(?i)creative-divergence',
        '(?i)\bcreative\b',
        '(?i)novelty',
        "\u521b\u610f\u6a21\u5f0f",
        "\u521b\u610f\u529f\u80fd",
        "\u521b\u610f\u7ea7"
    )
    'engineering' = @(
        '(?i)\bengineering\b',
        "\u5de5\u7a0b\u6a21\u5f0f",
        "\u5de5\u7a0b\u529f\u80fd",
        "\u5de5\u7a0b\u7ea7",
        "\u67b6\u6784\u7ade\u8d5b"
    )
    'stable' = @(
        '(?i)\bstable\b',
        "\u7a33\u5b9a\u6a21\u5f0f",
        "\u7a33\u5b9a\u529f\u80fd",
        "\u7a33\u5b9a\u7ea7",
        "\u541e\u5410",
        "\u95ed\u73af"
    )
}

foreach ($modeId in @('creative-divergence', 'engineering', 'stable')) {
    foreach ($pat in @($labelMap[$modeId])) {
        if ($text -match $pat) {
            if ($labelHits -notcontains $modeId) { [void]$labelHits.Add($modeId) }
            break
        }
    }
}

$archAsMode = $false
$archPatterns = @(
    '(?i)ABCD\s*mode\s*(is|=|:)?\s*Dynamic',
    '(?i)ABCD\s*mode\s*(is|=|:)?\s*Core',
    '(?i)ABCD\s*mode\s*(is|=|:)?\s*Part',
    '(?i)ABCD\s*\u6a21\u5f0f.*(Dynamic|ABCC|ABCP|Core|Part)',
    '(?i)(Dynamic|ABCC\.Core|ABCP\.Part)\s*(is|=|:)?\s*ABCD\s*mode'
)
foreach ($pat in $archPatterns) {
    if ($text -match $pat) { $archAsMode = $true; break }
}

$selected = $null
$status = 'not-hit'
$decision = 'not-applicable'
$ambiguous = $false

if ($archAsMode) {
    $status = 'rejected-architecture-as-abcd-mode'
    $decision = 'claim-cap'
    $selected = $null
}
elseif ($labelHits.Count -eq 1) {
    $status = 'resolved'
    $selected = [string]$labelHits[0]
    $decision = 'generation-mode'
}
elseif ($labelHits.Count -gt 1) {
    $status = 'ambiguous'
    $ambiguous = $true
    $decision = 'require-explicit-generation-mode'
    $selected = $null
}
elseif ($axisHit) {
    $status = 'resolved-default'
    $selected = if (-not [string]::IsNullOrWhiteSpace([string]$map.defaultWhenUnspecified)) {
        [string]$map.defaultWhenUnspecified
    } else {
        'engineering'
    }
    $decision = 'generation-mode-default'
}

[ordered]@{
    schemaVersion = 1
    resolver = 'es-abcd-generation-mode'
    status = $status
    axis = 'abcd-mode-function-level'
    mapsTo = 'generation-modes-only'
    possibleGenerationModeIds = @('creative-divergence', 'engineering', 'stable')
    selectedGenerationModeId = $selected
    labelHits = @($labelHits)
    axisHit = $axisHit
    ambiguous = $ambiguous
    architectureIdentityMistakenAsMode = $archAsMode
    decision = $decision
    architectureIdentityWhenAbcdRuns = 'ABCD.Dynamic'
    architectureIdentitiesAreNotAbcdModes = $true
    forbiddenAsAbcdMode = @('ABCD.Dynamic', 'ABCC.Core', 'ABCP.Part')
    stackNote = 'Architecture identities (ABCD.Dynamic/ABCC.Core/ABCP.Part) are not ABCD mode/function/level.'
    contractRef = 'ES/Automation/Contracts/es-ai-abc-generation-mode-v1.json'
    registryRef = 'ES/Automation/Contracts/es-ai-abc-mode.registry.json'
    nonClaims = @(
        'Does not execute InnovationRun',
        'Does not prove Unity Runtime',
        'Does not rewrite mono-semantic architecture lock'
    )
} | ConvertTo-Json -Depth 8 
