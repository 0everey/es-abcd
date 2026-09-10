# Portable governance authority — full Core parity without ESFramework host corpus.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'ESABCDHome.psm1') -Force -Global

function Get-ESABCDPortableGovernanceContract {
    [CmdletBinding()]
    param()
    $path = Join-Path $PSScriptRoot 'portable\es-abcd-portable-governance-v1.json'
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "ABCD_PORTABLE_GOVERNANCE_MISSING:$path"
    }
    $json = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
    $hash = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
    [pscustomobject][ordered]@{
        path = $path
        hash = $hash
        contract = $json
    }
}

function Test-ESABCDPortableTextMatch {
    param([string]$Text, [string]$Term)
    if ([string]::IsNullOrWhiteSpace($Text) -or [string]::IsNullOrWhiteSpace($Term)) { return $false }
    return ($Text.IndexOf($Term, [StringComparison]::OrdinalIgnoreCase) -ge 0)
}

function Resolve-ESABCDPortableGovernancePolicy {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$ContextText,
        [ValidateSet('ai-collaboration','game-logic','editor-tooling','release')][string]$Domain = 'ai-collaboration',
        [Parameter(Mandatory)][string]$ConsumerId
    )

    $bundle = Get-ESABCDPortableGovernanceContract
    $c = $bundle.contract
    $text = if ($null -eq $ContextText) { '' } else { $ContextText.Trim() }

    $matched = New-Object System.Collections.Generic.List[object]
    foreach ($rule in @($c.mandatoryRules)) {
        $hits = @()
        foreach ($term in @($rule.match)) {
            if (Test-ESABCDPortableTextMatch -Text $text -Term ([string]$term)) { $hits += [string]$term }
        }
        $force = [bool]$c.alwaysAttachDeliveryBoundary -and [string]$rule.ruleId -eq 'es.aiwarning.p0.ai-delivery-claim-boundary'
        if ($hits.Count -gt 0 -or $force) {
            [void]$matched.Add([pscustomobject][ordered]@{
                ruleId = [string]$rule.ruleId
                severity = [string]$rule.severity
                decision = [string]$rule.decision
                matchedTerms = @($hits)
                purpose = [string]$rule.purpose
                source = 'es-abcd-portable-governance'
            })
        }
    }

    # Capability parity receipt — always present so portable mode cannot silently drop the six capabilities.
    $caps = @($c.capabilitiesParity)
    if ($caps.Count -lt 6) { throw 'ABCD_PORTABLE_CAPABILITY_PARITY_INCOMPLETE' }
    [void]$matched.Add([pscustomobject][ordered]@{
        ruleId = 'es.abcd.portable.capability-parity-receipt'
        severity = 'P0'
        decision = 'consume-and-report'
        matchedTerms = @('capabilitiesParity')
        purpose = 'Records that portable governance still requires all six ABCD kernel capabilities.'
        source = 'es-abcd-portable-governance'
        capabilities = @($caps)
    })

    $decision = [string]$c.defaultPolicyDecision
    if (@($matched | Where-Object { [string]$_.decision -eq 'claim-cap' }).Count -gt 0) {
        $decision = 'claim-cap'
    }

    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        $inputBytes = [Text.Encoding]::UTF8.GetBytes(($Domain + "`n" + $text))
        $inputHash = ([BitConverter]::ToString($sha.ComputeHash($inputBytes))).Replace('-', '').ToLowerInvariant()
    }
    finally { $sha.Dispose() }

    # Build arrays outside [ordered] to avoid PS 5.1 pipeline/enumerator type mismatches.
    $ruleIds = New-Object System.Collections.Generic.List[string]
    foreach ($item in $matched) {
        $rid = [string]$item.ruleId
        if (-not [string]::IsNullOrWhiteSpace($rid) -and -not $ruleIds.Contains($rid)) {
            [void]$ruleIds.Add($rid)
        }
    }
    $main = @($matched.ToArray())
    $parity = @($caps)
    $nonClaims = @($c.nonClaims | ForEach-Object { [string]$_ })

    return [pscustomobject]@{
        schemaVersion = 1
        contractId = [string]$c.contractId
        authorityId = [string]$c.authorityId
        authorityRank = [int]$c.authorityRank
        skillAuthorityRank = [int]$c.skillAuthorityRank
        domain = $Domain
        consumerId = $ConsumerId
        inputHash = $inputHash
        authorityHash = [string]$bundle.hash
        matchedRuleIds = @($ruleIds.ToArray())
        mainWarnings = $main
        warningOverflowCount = 0
        warningsTruncated = $false
        policyDecision = $decision
        summaryRequired = $true
        consumedAtUtc = [DateTime]::UtcNow.ToString('o')
        governanceMode = 'portable'
        independence = $c.independence
        capabilitiesParity = $parity
        nonClaims = $nonClaims
        metadataIndex = [pscustomobject]@{
            indexId = 'es-abcd-portable-inline'
            indexHash = [string]$bundle.hash
            sourceManifestHash = [string]$bundle.hash
        }
    }
}

function Add-ESABCDPortableGovernanceProjection {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Result,
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$ContextText,
        [ValidateSet('ai-collaboration','game-logic','editor-tooling','release')][string]$Domain = 'ai-collaboration',
        [Parameter(Mandatory)][ValidateNotNullOrEmpty()][string]$ConsumerId
    )
    $policy = Resolve-ESABCDPortableGovernancePolicy -ContextText $ContextText -Domain $Domain -ConsumerId $ConsumerId
    $projection = [pscustomobject][ordered]@{
        projectionStatus = 'resolved-portable'
        reasonCode = $null
        resolutionError = $null
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
        displayWarnings = @()
        warningOverflowCount = 0
        warningsTruncated = $false
        policyDecision = [string]$policy.policyDecision
        summaryRequired = $true
        consumedAtUtc = [string]$policy.consumedAtUtc
        governanceMode = 'portable'
        capabilitiesParity = @($policy.capabilitiesParity)
        independence = $policy.independence
        nonClaims = @($policy.nonClaims)
    }
    $Result | Add-Member -NotePropertyName aiWarnings -NotePropertyValue $projection -Force
    $Result | Add-Member -NotePropertyName abcdGovernance -NotePropertyValue $projection -Force
    return $Result
}

function Test-ESABCDHostWarningsAvailable {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$ProjectRoot)
    $contract = Join-Path $ProjectRoot 'ES\Automation\Contracts\es-aiwarnings-global-authority-v1.json'
    if (-not (Test-Path -LiteralPath $contract -PathType Leaf)) { return $false }
    $warningsRoot = Join-Path $ProjectRoot 'Assets\Plugins\ES\AIWarnings'
    if (-not (Test-Path -LiteralPath $warningsRoot -PathType Container)) { return $false }
    $catalog = Get-ChildItem -LiteralPath $warningsRoot -Recurse -File -Filter 'AIWarningsRouteCatalog.json' -ErrorAction SilentlyContinue | Select-Object -First 1
    return ($null -ne $catalog)
}

Export-ModuleMember -Function Get-ESABCDPortableGovernanceContract,Resolve-ESABCDPortableGovernancePolicy,Add-ESABCDPortableGovernanceProjection,Test-ESABCDHostWarningsAvailable
