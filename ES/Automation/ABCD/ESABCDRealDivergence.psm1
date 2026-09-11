# REMOVED (P0): card-pack / mutation-catalog divergence is forbidden.
# Use ESABCDModelDivergence.psm1 + ESABCDModelClient.psm1.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
function New-ESABCDRealDirectionCandidate {
    throw 'ABCD_CARD_PACK_REMOVED: use LLM divergence (Invoke-ESABCDModelModeDivergence). Prefab meat path deleted.'
}
function Get-ESABCDAxisMutationCatalog {
    throw 'ABCD_CARD_PACK_REMOVED: mutation catalog deleted.'
}
function Get-ESABCDAxisBodyFields {
    throw 'ABCD_CARD_PACK_REMOVED: axis body packs deleted. Use model divergence.'
}
Export-ModuleMember -Function New-ESABCDRealDirectionCandidate, Get-ESABCDAxisMutationCatalog, Get-ESABCDAxisBodyFields
