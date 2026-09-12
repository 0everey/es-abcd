# DELETED single-layer path (P0). Multi-layer only: ESABCDMultiLayerDivergence.psm1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Invoke-ESABCDModelModeDivergence {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Requirement,
        [Parameter(Mandatory)][string]$SourceHash,
        [ValidateSet('creative-divergence','engineering','stable')][string]$Mode = 'creative-divergence',
        [int]$MinimumDirections = 0,
        [string]$ProjectRoot = '',
        [scriptblock]$ModelInvoker = $null
    )
    throw 'P0_ABCD_MULTI_LAYER_REQUIRED: single-layer ModeDivergence path is permanently deleted. Call Invoke-ESABCModeDivergence (multi-layer-v1) only.'
}

function New-ESABCDModelDirectionCandidate {
    throw 'P0_ABCD_MULTI_LAYER_REQUIRED: single-axis one-shot candidate builder deleted. Use multi-layer-v1.'
}

Export-ModuleMember -Function @(
    'Invoke-ESABCDModelModeDivergence',
    'New-ESABCDModelDirectionCandidate'
)