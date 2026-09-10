Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot '..\AI\ESAuthorityDecisionPolicy.psm1') -Force

# This is the single canonical capability vocabulary for the ABCD/ABCC boundary.
# Mode profiles may select a bounded subset, but Dynamic and Core must remain
# closed over this vocabulary.  Keeping it here prevents a consumer from
# silently inventing a capability name or omitting one from the authority gate.
$script:CoreCapabilities = @(
    'bounded-tool-action',
    'failure-recovery',
    'branch-evaluation',
    'state-transition-guard',
    'environment-trust-gate',
    'audit-evidence-chain'
)

$script:Modes = [ordered]@{
    'full-depth' = [ordered]@{
        readBudget = 40
        capabilities = @($script:CoreCapabilities)
        deep = $true
        finalGate = $true
    }
    'shallow-fast' = [ordered]@{
        readBudget = 3
        capabilities = @('bounded-tool-action', 'audit-evidence-chain')
        deep = $false
        finalGate = $false
    }
    'core-high-risk' = [ordered]@{
        readBudget = 20
        capabilities = @($script:CoreCapabilities)
        deep = $true
        finalGate = $true
    }
}

function Get-ESABCDCoreCapabilities {
    [CmdletBinding()]
    param()
    return @($script:CoreCapabilities)
}

function Test-ESABCDPropertyPresent {
    param([AllowNull()]$Value, [Parameter(Mandatory)][string]$Name)
    if ($null -eq $Value) { return $false }
    if ($Value -is [Collections.IDictionary]) { return $Value.Contains($Name) }
    return (@($Value.PSObject.Properties | Where-Object { $_.Name -ceq $Name }).Count -gt 0)
}

function Get-ESABCDCapabilityValues {
    param([AllowNull()]$Value)
    if ($null -eq $Value) { return @() }
    return @($Value | ForEach-Object { [string]$_ } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
}

function Test-ESABCDCompleteDivergence {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Evidence)
    # 只有可重读的执行回执才能证明发散真正进入并完成；静态字段或阶段名称本身不算执行。
    $state = [ordered]@{ isComplete = $false }
    if (Test-ESABCDPropertyPresent $Evidence 'divergenceCompleted') {
        $state.isComplete = [bool]$Evidence.divergenceCompleted
    }
    $receipt = if (Test-ESABCDPropertyPresent $Evidence 'divergenceReceipt') { [string]$Evidence.divergenceReceipt } else { '' }
    [pscustomobject][ordered]@{
        completed = ($state.isComplete -and -not [string]::IsNullOrWhiteSpace($receipt))
        declared = $state.isComplete
        receipt = $receipt
        reasonCode = if ($state.isComplete -and -not [string]::IsNullOrWhiteSpace($receipt)) { $null } else { 'ABCD_DIVERGENCE_REQUIRED_FOR_ACCEPTANCE' }
    }
}

function Get-ESABCDGlobalWarningsSummary {
    $contractPath = Join-Path $PSScriptRoot '..\Contracts\es-aiwarnings-global-authority-v1.json'
    $hash = if (Test-Path -LiteralPath $contractPath) { (Get-FileHash -LiteralPath $contractPath -Algorithm SHA256).Hash.ToLowerInvariant() } else { '' }
    [pscustomobject][ordered]@{
        authorityId = 'es.aiwarnings.global.default'; authorityRank = 2; skillAuthorityRank = 1
        authorityHash = $hash; matchedRuleIds = @('es.aiwarning.p0.ai-delivery-claim-boundary')
        mainWarnings = @([pscustomobject][ordered]@{ ruleId = 'es.aiwarning.p0.ai-delivery-claim-boundary'; severity = 'P0'; decision = 'claim-cap' })
        policyDecision = 'claim-cap'; summaryRequired = $true
    }
}

function Resolve-ESABCDAuthorityDecision {
    [CmdletBinding()]
    param(
        [ValidateSet('full-depth', 'shallow-fast', 'core-high-risk')]
        [string]$Mode = 'core-high-risk',
        [ValidateSet('ai-collaboration', 'game-logic', 'editor-tooling', 'release')]
        [string]$Domain = 'ai-collaboration',
        [Parameter(Mandatory)]$Evidence,
        [string[]]$MissingFields = @()
    )

    if ($null -eq $Evidence) { throw 'AUTHORITY_EVIDENCE_REQUIRED' }
    $profile = $script:Modes[$Mode]
    $projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
    $domainPolicy = Get-ESAuthorityDecisionPolicy -ProjectRoot $projectRoot -Domain $Domain
    $safeFields = @($domainPolicy.safeDefaultFields)
    $normalized = [ordered]@{}
    $unresolved = [Collections.Generic.List[string]]::new()
    foreach ($field in @($MissingFields | ForEach-Object { [string]$_ } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)) {
        if ($field -in $safeFields) {
            $normalized[$field] = 'defaulted-from-local-observation'
        } else {
            [void]$unresolved.Add($field)
        }
    }

    $selected = @(Get-ESABCDCapabilityValues $profile.capabilities | Select-Object -Unique)
    $required = if ($Mode -in @('full-depth', 'core-high-risk')) { @($script:CoreCapabilities) } else { @($selected) }
    if (Test-ESABCDPropertyPresent $Evidence 'requiredCapabilities') {
        $required = @(Get-ESABCDCapabilityValues $Evidence.requiredCapabilities | Select-Object -Unique)
    }
    if (Test-ESABCDPropertyPresent $Evidence 'selectedCapabilities') {
        $selected = @(Get-ESABCDCapabilityValues $Evidence.selectedCapabilities | Select-Object -Unique)
    }

    $unknown = @($selected | Where-Object { $_ -notin $script:CoreCapabilities })
    $missingCapabilities = @($required | Where-Object { $_ -notin $selected })
    $duplicateCapabilities = @($profile.capabilities | Group-Object | Where-Object Count -gt 1 | ForEach-Object Name)
    $capabilityClosed = ($unknown.Count -eq 0 -and $missingCapabilities.Count -eq 0 -and $duplicateCapabilities.Count -eq 0)
    if (-not $capabilityClosed) {
        if ($unknown.Count) { [void]$unresolved.Add('unknownCapability') }
        if ($missingCapabilities.Count) { [void]$unresolved.Add('missingCapability') }
        if ($duplicateCapabilities.Count) { [void]$unresolved.Add('duplicateCapability') }
    }

    $unsafe = @($unresolved | Select-Object -Unique)
    $hardBlockFields = @($domainPolicy.hardBlockFields)
    $hardUnresolved = @($unsafe | Where-Object {
        $field = [string]$_
        @($hardBlockFields | Where-Object { $field -match [regex]::Escape([string]$_) }).Count -gt 0
    })
    if ($Mode -eq 'core-high-risk' -and $Domain -ne 'ai-collaboration') {
        $hardUnresolved = @(@($hardUnresolved + @($unsafe | Where-Object { [string]$_ -match '(?i)^(artifactHash|sourceHash|planHash|proof)$' })) | Select-Object -Unique)
    }
    $capabilityFields = @($unsafe | Where-Object { $_ -match '(?i)capability' })
    $authorizationFields = @($unsafe | Where-Object { $_ -match '(?i)authoriz|permission|unauthor|effect|write' })
    $semanticFields = @($unsafe | Where-Object { $_ -match '(?i)semantic|intent|goal|constraint|mismatch' })
    $evidenceFields = @($unsafe | Where-Object { $_ -match '(?i)evidence|artifact|receipt|hash|proof' })
    $acceptanceRequested = ((Test-ESABCDPropertyPresent $Evidence 'requiresCompleteDivergence') -and [bool]$Evidence.requiresCompleteDivergence) -or ((Test-ESABCDPropertyPresent $Evidence 'acceptanceIntent') -and ([string]$Evidence.acceptanceIntent -match '(?i)full|acceptance'))
    $divergenceDeclared = (Test-ESABCDPropertyPresent $Evidence 'divergenceCompleted') -and [bool]$Evidence.divergenceCompleted
    $divergenceReceipt = if (Test-ESABCDPropertyPresent $Evidence 'divergenceReceipt') { [string]$Evidence.divergenceReceipt } else { '' }
    $divergence = [pscustomobject][ordered]@{ completed = ($divergenceDeclared -and -not [string]::IsNullOrWhiteSpace($divergenceReceipt)); declared = $divergenceDeclared; receipt = $divergenceReceipt; reasonCode = if ($divergenceDeclared -and -not [string]::IsNullOrWhiteSpace($divergenceReceipt)) { $null } else { 'ABCD_DIVERGENCE_REQUIRED_FOR_ACCEPTANCE' } }
    $status = 'accepted'
    $claim = 'full'
    $next = 'continue'
    $reason = 'AUTHORITY_ACCEPTED'
    if ($acceptanceRequested -and -not $divergence.completed) {
        $status = 'blocked'
        $claim = 'none'
        $next = 'stop-and-report'
        $reason = 'ABCD_DIVERGENCE_REQUIRED_FOR_ACCEPTANCE'
    } elseif (-not $capabilityClosed) {
        $status = 'blocked'
        $claim = 'claim-cap'
        $next = 'stop-and-report'
        $reason = 'CAPABILITY_CLOSURE_MISSING'
    } elseif ($authorizationFields.Count) {
        $status = 'blocked'
        $claim = 'none'
        $next = 'stop-and-report'
        $reason = 'UNAUTHORIZED_EFFECT'
    } elseif ($hardUnresolved.Count) {
        $status = 'blocked'
        $claim = 'none'
        $next = 'stop-and-report'
        $reason = 'UNRESOLVED_CORE_EVIDENCE'
    } elseif ($semanticFields.Count) {
        $status = 'replan'
        $claim = 'none'
        $next = 'replan'
        $reason = 'SEMANTIC_MISMATCH_REPLAN'
    } elseif ($evidenceFields.Count) {
        $status = 'claim-cap'
        $claim = 'claim-cap'
        $next = 'replan'
        $reason = 'EVIDENCE_MISSING_CLAIM_CAP'
        if ($domainPolicy.strictOnUnresolved -and $hardUnresolved.Count) {
            $status = 'blocked'
            $next = 'stop-and-report'
        }
    } elseif ($unsafe.Count) {
        $status = 'claim-cap'
        $claim = 'claim-cap'
        $next = 'replan'
        $reason = 'UNRESOLVED_CORE_EVIDENCE'
        if ($domainPolicy.strictOnUnresolved -and $hardUnresolved.Count) {
            $status = 'blocked'
            $next = 'stop-and-report'
        }
    }

    $display = $null
    if ($status -eq 'blocked') {
        $display = '🛑⛔【ABCD核心阻断】 reason=' + $reason + ' action=stop-and-report'
    }
    $defect = $null
    if ($unsafe.Count) {
        $defect = [pscustomobject][ordered]@{
            defectDetected = $true
            severity = if ($status -eq 'blocked') { 'high' } else { 'medium' }
            reasonCode = $reason
            fields = @($unsafe)
            hardFields = @($hardUnresolved)
            correction = $next
            suppressed = $false
        }
    }
    [pscustomobject][ordered]@{
        schemaVersion = 1
        authority = 'ABCD-Authority-Kernel'
        domain = $Domain
        domainPolicy = $domainPolicy
        mode = $Mode
        profile = [pscustomobject]$profile
        status = $status
        claimLevel = $claim
        nextAction = $next
        reasonCode = $reason
        normalizedFields = $normalized
        unresolvedFields = @($unsafe)
        capabilityClosure = [pscustomobject][ordered]@{
            status = if ($capabilityClosed) { 'closed' } else { 'blocked' }
            required = @($required)
            selected = @($selected)
            missing = @($missingCapabilities)
            unknown = @($unknown)
            duplicates = @($duplicateCapabilities)
        }
        selectedCapabilities = @($selected)
        readBudget = $profile.readBudget
        deepAudit = [bool]$profile.deep
        finalGate = [bool]$profile.finalGate
        acceptanceRequested = $acceptanceRequested
        divergenceGate = $divergence
        mechanismsContinue = ($status -ne 'blocked')
        displayLine = $display
        nextOutputRequired = ($status -eq 'blocked')
        defect = $defect
        aiWarnings = Get-ESABCDGlobalWarningsSummary
    }
}

Export-ModuleMember -Function Get-ESABCDCoreCapabilities, Resolve-ESABCDAuthorityDecision
