# P0 hard gate: only multi-layer-v1 divergence is legal. Anything else throws.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Assert-ESABCDMultiLayerOrP0 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Run,
        [switch]$AllowScoreZeroOnIncomplete  # still P0 for scoring; throw unless allow soft zero only when layers attempted
    )
    $eng = ''
    if ($null -ne $Run.PSObject.Properties['divergenceEngine']) { $eng = [string]$Run.divergenceEngine }
    if ($null -ne $Run.PSObject.Properties['iterationTraceKind'] -and [string]::IsNullOrWhiteSpace($eng)) {
        $eng = [string]$Run.iterationTraceKind
    }
    $src = ''
    if ($null -ne $Run.PSObject.Properties['contentSource']) { $src = [string]$Run.contentSource }

    $forbidden = @(
        'llm-axis-divergence-v1',
        'single-layer',
        'fast-judgment',
        'synthetic-trace',
        'real-axis-branch',
        'card-pack',
        'template-scaffold'
    )
    foreach ($f in $forbidden) {
        if ($eng -match [regex]::Escape($f) -or $src -match [regex]::Escape($f)) {
            throw ("P0_ABCD_MULTI_LAYER_REQUIRED: forbidden engine/source '$eng'/'$src' (matched $f). Only multi-layer-v1 is legal.")
        }
    }
    if ($eng -ne 'multi-layer-v1' -and $eng -ne 'multi-layer-v1-failed') {
        # failed multi-layer may still report multi-layer-v1 with MULTI_LAYER_FAILED status
        if ($eng -notmatch '^multi-layer') {
            throw ("P0_ABCD_MULTI_LAYER_REQUIRED: divergenceEngine='$eng' is not multi-layer-v1.")
        }
    }

    $gate = $null
    if ($null -ne $Run.PSObject.Properties['depthGate']) { $gate = $Run.depthGate }
    if ($null -eq $gate) {
        Import-Module (Join-Path $PSScriptRoot 'ESABCDMultiLayerDivergence.psm1') -Force -Global
        $gate = Test-ESABCDMultiLayerEvidence -Run $Run
    }
    if (-not [bool]$gate.passed) {
        $miss = (@($gate.missing) -join ',')
        if ($AllowScoreZeroOnIncomplete) {
            # Caller may keep object for forensics but must not claim success
            return [pscustomobject]@{
                ok = $false
                p0 = 'P0_ABCD_MULTI_LAYER_INCOMPLETE'
                totalScore = 0
                missing = @($gate.missing)
                message = "multi-layer incomplete => score 0; missing=$miss"
            }
        }
        throw ("P0_ABCD_MULTI_LAYER_INCOMPLETE: missing=$miss. Incomplete multi-layer is P0 block (score must be 0).")
    }
    return [pscustomobject]@{
        ok = $true
        p0 = $null
        totalScore = [int]$gate.totalScore
        missing = @()
        message = 'multi-layer-v1 closed'
    }
}

function Assert-ESABCDCandidateSetMultiLayerOrP0 {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Candidates)
    $items = @($Candidates)
    foreach ($c in $items) {
        $eng = ''
        if ($null -ne $c.PSObject.Properties['divergenceEngine']) { $eng = [string]$c.divergenceEngine }
        $tier = ''
        if ($null -ne $c.PSObject.Properties['contentTier']) { $tier = [string]$c.contentTier }
        if ($eng -match 'llm-axis-divergence-v1|single-layer|fast-judgment|synthetic|real-axis|card-pack' -or
            $tier -match 'single-layer|card-pack|axis-grounded|real-axis') {
            throw ("P0_ABCD_MULTI_LAYER_REQUIRED: candidate $($c.directionId) engine='$eng' tier='$tier' is illegal.")
        }
        if ($eng -and $eng -ne 'multi-layer-v1') {
            throw ("P0_ABCD_MULTI_LAYER_REQUIRED: candidate $($c.directionId) divergenceEngine='$eng' must be multi-layer-v1.")
        }
    }
    return $true
}

Export-ModuleMember -Function @(
    'Assert-ESABCDMultiLayerOrP0',
    'Assert-ESABCDCandidateSetMultiLayerOrP0'
)
