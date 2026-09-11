Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
# Projection only; never declares task completion.
# Default path is portable ABCD governance (no ESFramework AIWarnings corpus).
# Host mode is optional when ES_ABCD_GOVERNANCE_MODE=host and host corpus is present.

function Add-ESAIWarningsResultProjection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Result,
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$ContextText,
        [ValidateSet('ai-collaboration','game-logic','editor-tooling','release')][string]$Domain = 'ai-collaboration',
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$ConsumerId,
        [string]$ProjectRoot = '',
        [ValidateSet('auto','portable','host')][string]$GovernanceMode = 'auto'
    )

    $abcdHome = Join-Path $PSScriptRoot '..\ABCD\ESABCDHome.psm1'
    $portableMod = Join-Path $PSScriptRoot '..\ABCD\ESABCDPortableAuthority.psm1'
    if (-not (Test-Path -LiteralPath $abcdHome)) { throw 'ABCD_HOME_MODULE_MISSING' }
    if (-not (Test-Path -LiteralPath $portableMod)) { throw 'ABCD_PORTABLE_AUTHORITY_MISSING' }
    Import-Module $abcdHome -Force -Global
    Import-Module $portableMod -Force -Global

    if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
        $ProjectRoot = Get-ESABCDPackageRoot
    } else {
        $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
    }

    $mode = $GovernanceMode
    if ($mode -eq 'auto') {
        $envMode = Get-ESABCDGovernanceMode
        if ($envMode -eq 'host' -and (Test-ESABCDHostWarningsAvailable -ProjectRoot $ProjectRoot)) {
            $mode = 'host'
        } else {
            $mode = 'portable'
        }
    }

    if ($mode -eq 'portable') {
        return Add-ESABCDPortableGovernanceProjection -Result $Result -ContextText $ContextText -Domain $Domain -ConsumerId $ConsumerId
    }

    # ---- optional host path (ESFramework-style corpus) ----
    $resolver = Join-Path $PSScriptRoot 'Resolve-ESAIWarningsGlobalPolicy.ps1'
    $displayModule = Join-Path $PSScriptRoot 'ESAIWarningsDisplay.psm1'
    $displayWarnings = @()
    if (Test-Path -LiteralPath $displayModule -PathType Leaf) {
        Import-Module $displayModule -Force
    }
    $projectionStatus = 'resolved-host'
    $reasonCode = $null
    $resolutionError = $null
    try {
        if (-not (Test-Path -LiteralPath $resolver -PathType Leaf)) { throw 'AIWARNINGS_GLOBAL_RESOLVER_MISSING' }
        if (-not (Test-ESABCDHostWarningsAvailable -ProjectRoot $ProjectRoot)) {
            throw 'AIWARNINGS_HOST_CORPUS_UNAVAILABLE'
        }
        $policyJson = (& $resolver -PromptText $ContextText -Domain $Domain -ProjectRoot $ProjectRoot | Out-String).Trim()
        $policy = $policyJson | ConvertFrom-Json
        foreach ($field in @('authorityId','authorityHash','inputHash','matchedRuleIds','mainWarnings','policyDecision','consumedAtUtc')) {
            if ($null -eq $policy.PSObject.Properties[$field]) { throw "AIWARNINGS_PROJECTION_POLICY_FIELD_MISSING:$field" }
        }
    }
    catch {
        # Host requested but unavailable/failed → portable full projection (no capability loss).
        return Add-ESABCDPortableGovernanceProjection -Result $Result -ContextText $ContextText -Domain $Domain -ConsumerId $ConsumerId
    }

    if (Get-Command -Name ConvertTo-ESAIWarningsDisplay -ErrorAction SilentlyContinue) {
        $displayWarnings = @($policy.mainWarnings | ForEach-Object { ConvertTo-ESAIWarningsDisplay $_ })
    }
    $meta = $policy.metadataIndex
    if ($null -eq $meta) {
        $meta = [pscustomobject][ordered]@{ indexId=''; indexHash=''; sourceManifestHash='' }
    }
    $projection = [pscustomobject][ordered]@{
        projectionStatus = $projectionStatus
        reasonCode = $reasonCode
        resolutionError = $resolutionError
        authorityId = [string]$policy.authorityId
        authorityRank = [int]$policy.authorityRank
        skillAuthorityRank = [int]$policy.skillAuthorityRank
        authorityHash = [string]$policy.authorityHash
        metadataIndexId = [string]$meta.indexId
        metadataIndexHash = [string]$meta.indexHash
        sourceManifestHash = [string]$meta.sourceManifestHash
        inputHash = [string]$policy.inputHash
        domain = $Domain
        consumerId = $ConsumerId
        matchedRuleIds = @($policy.matchedRuleIds)
        mainWarnings = @($policy.mainWarnings)
        displayWarnings = @($displayWarnings)
        warningOverflowCount = [int]$policy.warningOverflowCount
        warningsTruncated = [bool]$policy.warningsTruncated
        policyDecision = [string]$policy.policyDecision
        summaryRequired = $true
        consumedAtUtc = [string]$policy.consumedAtUtc
        governanceMode = 'host'
    }
    $Result | Add-Member -NotePropertyName aiWarnings -NotePropertyValue $projection -Force
    $Result | Add-Member -NotePropertyName abcdGovernance -NotePropertyValue $projection -Force
    return $Result
}

Export-ModuleMember -Function Add-ESAIWarningsResultProjection 
