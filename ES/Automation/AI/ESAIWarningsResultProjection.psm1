Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
# Projection only; this module never declares task completion. It attaches the
# global warning authority receipt to a caller-owned result.

function Add-ESAIWarningsResultProjection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Result,
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$ContextText,
        [ValidateSet('ai-collaboration','game-logic','editor-tooling','release')][string]$Domain = 'ai-collaboration',
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$ConsumerId,
        [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
    )

    $resolver = Join-Path $PSScriptRoot 'Resolve-ESAIWarningsGlobalPolicy.ps1'
    $displayModule = Join-Path $PSScriptRoot 'ESAIWarningsDisplay.psm1'
    $displayWarnings = @()
    if (Test-Path -LiteralPath $displayModule -PathType Leaf) {
        Import-Module $displayModule -Force
    }
    $projectionStatus = 'resolved'
    $reasonCode = $null
    $resolutionError = $null
    try {
        if (-not (Test-Path -LiteralPath $resolver -PathType Leaf)) { throw 'AIWARNINGS_GLOBAL_RESOLVER_MISSING' }
        $policyJson = (& $resolver -PromptText $ContextText -Domain $Domain -ProjectRoot $ProjectRoot | Out-String).Trim()
        $policy = $policyJson | ConvertFrom-Json
        foreach ($field in @('authorityId','authorityHash','inputHash','matchedRuleIds','mainWarnings','policyDecision','consumedAtUtc')) {
            if ($null -eq $policy.PSObject.Properties[$field]) { throw "AIWARNINGS_PROJECTION_POLICY_FIELD_MISSING:$field" }
        }
    }
    catch {
        # A routing/index defect must cap the caller's completion claim, but it
        # must not erase an otherwise valid task result or evidence receipt.
        $projectionStatus = 'degraded'
        $reasonCode = 'AIWARNINGS_POLICY_RESOLUTION_FAILED'
        $resolutionError = $_.Exception.Message
        $sha = [Security.Cryptography.SHA256]::Create()
        try {
            $inputBytes = [Text.Encoding]::UTF8.GetBytes(($Domain + "`n" + $ContextText))
            $inputHash = ([BitConverter]::ToString($sha.ComputeHash($inputBytes))).Replace('-', '').ToLowerInvariant()
        }
        finally { $sha.Dispose() }
        $authorityPath = Join-Path $ProjectRoot 'ES/Automation/Contracts/es-aiwarnings-global-authority-v1.json'
        $authorityHash = if (Test-Path -LiteralPath $authorityPath -PathType Leaf) { (Get-FileHash -LiteralPath $authorityPath -Algorithm SHA256).Hash.ToLowerInvariant() } else { '' }
        $mandatory = [pscustomobject][ordered]@{ ruleId='es.aiwarning.p0.ai-delivery-claim-boundary'; severity='P0'; decision='claim-cap' }
        $policy = [pscustomobject][ordered]@{
            authorityId='es.aiwarnings.global.default'; authorityRank=2; skillAuthorityRank=1; authorityHash=$authorityHash; inputHash=$inputHash
            metadataIndex=[pscustomobject][ordered]@{indexId='';indexHash='';sourceManifestHash=''}
            matchedRuleIds=@([string]$mandatory.ruleId); mainWarnings=@($mandatory); warningOverflowCount=0; warningsTruncated=$false
            policyDecision='claim-cap'; consumedAtUtc=[DateTime]::UtcNow.ToString('o')
        }
    }
    if (Get-Command -Name ConvertTo-ESAIWarningsDisplay -ErrorAction SilentlyContinue) {
        $displayWarnings = @($policy.mainWarnings | ForEach-Object { ConvertTo-ESAIWarningsDisplay $_ })
    }
    $projection = [pscustomobject][ordered]@{
        projectionStatus = $projectionStatus
        reasonCode = $reasonCode
        resolutionError = $resolutionError
        authorityId = [string]$policy.authorityId
        authorityRank = [int]$policy.authorityRank
        skillAuthorityRank = [int]$policy.skillAuthorityRank
        authorityHash = [string]$policy.authorityHash
        metadataIndexId = [string]$policy.metadataIndex.indexId
        metadataIndexHash = [string]$policy.metadataIndex.indexHash
        sourceManifestHash = [string]$policy.metadataIndex.sourceManifestHash
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
    }
    $Result | Add-Member -NotePropertyName aiWarnings -NotePropertyValue $projection -Force
    return $Result
}

Export-ModuleMember -Function Add-ESAIWarningsResultProjection
