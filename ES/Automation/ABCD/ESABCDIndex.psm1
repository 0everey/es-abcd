# Fast capability index + single product entry. Load only what a profile needs.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:ESABCDIndexCache = $null
$script:ESABCDLoadedCaps = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)

function Get-ESABCDCapabilityIndexPath {
    [CmdletBinding()]
    param()
    $p = Join-Path $PSScriptRoot 'es-abcd-capability-index.json'
    if (-not (Test-Path -LiteralPath $p -PathType Leaf)) {
        throw "ESABCD_CAPABILITY_INDEX_MISSING:$p"
    }
    return (Resolve-Path -LiteralPath $p).Path
}

function Get-ESABCDCapabilityIndex {
    [CmdletBinding()]
    param([switch]$Refresh)
    if (-not $Refresh -and $null -ne $script:ESABCDIndexCache) {
        return $script:ESABCDIndexCache
    }
    $path = Get-ESABCDCapabilityIndexPath
    $raw = Get-Content -LiteralPath $path -Raw -Encoding UTF8
    $doc = $raw | ConvertFrom-Json
    if ([int]$doc.schemaVersion -lt 1) { throw 'ESABCD_CAPABILITY_INDEX_SCHEMA' }
    $script:ESABCDIndexCache = $doc
    return $doc
}

function Get-ESABCDCapability {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Id
    )
    $idx = Get-ESABCDCapabilityIndex
    $hit = @($idx.capabilities | Where-Object { [string]$_.id -ceq $Id }) | Select-Object -First 1
    if ($null -eq $hit) { throw "ESABCD_CAPABILITY_UNKNOWN:$Id" }
    return $hit
}

function Get-ESABCDIndexCatalog {
    [CmdletBinding()]
    param(
        [string]$Tier = '',
        [switch]$AsTable
    )
    $idx = Get-ESABCDCapabilityIndex
    $rows = @($idx.capabilities)
    if (-not [string]::IsNullOrWhiteSpace($Tier)) {
        $rows = @($rows | Where-Object { [string]$_.tier -ceq $Tier })
    }
    $view = @($rows | ForEach-Object {
            [pscustomobject]@{
                id      = [string]$_.id
                tier    = [string]$_.tier
                module  = [string]$_.module
                summary = [string]$_.summary
                deps    = @($_.deps) -join ','
                exports = @($_.exports).Count
            }
        })
    if ($AsTable) { return ($view | Format-Table -AutoSize | Out-String) }
    return $view
}

function Import-ESABCDCapability {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string[]]$Id,
        [switch]$WithDeps,
        [switch]$Force
    )
    $order = New-Object System.Collections.Generic.List[string]
    $seen = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)

    function Add-Cap([string]$capId) {
        if (-not $seen.Add($capId)) { return }
        $cap = Get-ESABCDCapability -Id $capId
        if ($WithDeps) {
            foreach ($d in @($cap.deps)) {
                if (-not [string]::IsNullOrWhiteSpace([string]$d)) { Add-Cap ([string]$d) }
            }
        }
        [void]$order.Add($capId)
    }

    foreach ($rawId in $Id) { Add-Cap $rawId }

    $loaded = New-Object System.Collections.Generic.List[string]
    foreach ($capId in $order) {
        if (-not $Force -and $script:ESABCDLoadedCaps.Contains($capId)) {
            [void]$loaded.Add($capId)
            continue
        }
        if ($capId -ceq 'index') {
            # already executing inside index module
            [void]$script:ESABCDLoadedCaps.Add('index')
            [void]$loaded.Add('index')
            continue
        }
        $cap = Get-ESABCDCapability -Id $capId
        $modPath = Join-Path $PSScriptRoot ([string]$cap.module)
        if (-not (Test-Path -LiteralPath $modPath -PathType Leaf)) {
            throw "ESABCD_CAPABILITY_MODULE_MISSING:$capId->$modPath"
        }
        Import-Module $modPath -Force -Global
        [void]$script:ESABCDLoadedCaps.Add($capId)
        [void]$loaded.Add($capId)
    }
    return [pscustomobject]@{
        loaded = @($loaded)
        count  = $loaded.Count
    }
}

function Import-ESABCDProfile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('brief', 'select', 'smoke', 'deep')]
        [string]$Name,
        [switch]$Force
    )
    $idx = Get-ESABCDCapabilityIndex
    $prof = $idx.profiles.PSObject.Properties | Where-Object { $_.Name -ceq $Name } | Select-Object -First 1
    if ($null -eq $prof) { throw "ESABCD_PROFILE_UNKNOWN:$Name" }
    $ids = @($prof.Value.load | ForEach-Object { [string]$_ })
    return Import-ESABCDCapability -Id $ids -WithDeps -Force:$Force
}

function Resolve-ESABCDProjectRoot {
    [CmdletBinding()]
    param([string]$ProjectRoot = '')
    if (-not [string]::IsNullOrWhiteSpace($ProjectRoot)) {
        return (Resolve-Path -LiteralPath $ProjectRoot).Path
    }
    $here = (Get-Location).Path
    if (Test-Path (Join-Path $here 'ES\Automation\Contracts\es-ai-abc-generation-mode-v1.json')) {
        return $here
    }
    Import-ESABCDCapability -Id home -WithDeps | Out-Null
    return Get-ESABCDPackageRoot
}

function Invoke-ESABCD {
    <#
    .SYNOPSIS
      Single product entry for es-abcd. Prefer this over Quick/Commercial aliases.
    .PARAMETER Output
      brief  = commercial markdown+json (default, human deliverable)
      select = divergence+selection object only
      diverge = divergence object only
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Requirement,
        [ValidateSet('engineering', 'creative-divergence', 'stable')][string]$Mode = 'creative-divergence',
        [ValidateSet('brief', 'select', 'diverge')][string]$Output = 'brief',
        [string]$ProjectRoot = '',
        [string]$OutDir = ''
    )

    $ProjectRoot = Resolve-ESABCDProjectRoot -ProjectRoot $ProjectRoot
    $profileName = if ($Output -eq 'brief') { 'brief' } else { 'select' }
    Import-ESABCDProfile -Name $profileName | Out-Null

    $contract = Resolve-ESABCDContractPath -FileName 'es-ai-abc-generation-mode-v1.json' -ProjectRoot $ProjectRoot
    $hash = Get-ESABCDFileSha256 -LiteralPath $contract
    $div = Invoke-ESABCModeDivergence -Requirement $Requirement -SourceHash $hash -Mode $Mode -ProjectRoot $ProjectRoot

    if ($Output -eq 'diverge') {
        return [pscustomobject]@{
            entry            = 'Invoke-ESABCD'
            output           = 'diverge'
            mode             = $Mode
            projectRoot      = $ProjectRoot
            divergence       = $div
            directionCount   = [int]$div.directionCount
            candidateSetHash = [string]$div.candidateSetHash
            runtimeStatus    = 'runtime-not-run'
        }
    }

    $sel = Select-ESABCGenerationCandidate -Candidates $div.directions -Mode $Mode -Requirement $Requirement

    if ($Output -eq 'select') {
        return [pscustomobject]@{
            entry                 = 'Invoke-ESABCD'
            output                = 'select'
            mode                  = $Mode
            projectRoot           = $ProjectRoot
            directionCount        = [int]$div.directionCount
            selectedDirectionId   = [string]$sel.selectedDirectionId
            selectionStatus       = [string]$sel.selectionStatus
            claimLevel            = [string]$sel.claimLevel
            deliveryKind          = [string]$sel.deliveryKind
            pipelineLevel         = [string]$sel.pipelineLevel
            deliveryStatus        = [string]$sel.deliveryStatus
            domain                = [string]$sel.domain
            candidateSetHash      = [string]$div.candidateSetHash
            commercialContent     = [bool]$sel.commercialContent
            selection             = $sel
            divergence            = $div
            runtimeStatus         = 'runtime-not-run'
        }
    }

    # brief (default): human markdown + json via content formatter
    $md = Format-ESABCDCommercialMarkdown -Selection $sel -Divergence $div -Requirement $Requirement
    if ([string]::IsNullOrWhiteSpace($OutDir)) {
        $OutDir = Join-Path $ProjectRoot 'ES\Automation\ABCD\out'
    }
    New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
    $stamp = [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss')
    $mdPath = Join-Path $OutDir ("commercial-brief-$stamp.md")
    $jsonPath = Join-Path $OutDir ("commercial-brief-$stamp.json")
    [IO.File]::WriteAllText($mdPath, $md, [Text.UTF8Encoding]::new($true))

    $payload = [pscustomobject]@{
        schemaVersion         = 1
        recordType            = 'ESABCDCommercialBrief'
        entry                 = 'Invoke-ESABCD'
        output                = 'brief'
        requirement           = $Requirement
        mode                  = $Mode
        deliveryKind          = [string]$sel.deliveryKind
        pipelineLevel         = [string]$sel.pipelineLevel
        domain                = [string]$sel.domain
        claimLevel            = [string]$sel.claimLevel
        selectedDirectionId   = [string]$sel.selectedDirectionId
        directionCount        = [int]$div.directionCount
        candidateSetHash      = [string]$div.candidateSetHash
        domainBrief           = $sel.domainBrief
        rankedSummaries       = @($sel.ranked | ForEach-Object {
                $c = $_.candidate
                [pscustomobject]@{
                    rankScore               = $_.rankScore
                    directionId             = [string]$c.directionId
                    axis                    = [string]$c.axis
                    axisZh                  = [string]$c.axisZh
                    productPitch            = [string]$c.productPitch
                    concretePlayerScenario  = [string]$c.concretePlayerScenario
                    novelMechanism          = [string]$c.novelMechanism
                }
            })
        markdownPath          = $mdPath
        jsonPath              = $jsonPath
        runtimeStatus         = 'runtime-not-run'
        commercialReady       = $true
        nonClaims             = @('not-shipped', 'not-balanced', 'not-playmode', 'not-universal-ai-wipeout')
        capturedUtc           = [DateTime]::UtcNow.ToString('o')
        projectRoot           = $ProjectRoot
    }
    [IO.File]::WriteAllText($jsonPath, ($payload | ConvertTo-Json -Depth 10), [Text.UTF8Encoding]::new($true))
    return $payload
}

# Backward-compatible thin aliases (same entry, different Output default)
function Invoke-ESABCDQuick {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Requirement,
        [ValidateSet('engineering', 'creative-divergence', 'stable')][string]$Mode = 'engineering',
        [string]$ProjectRoot = '',
        [switch]$Commercial
    )
    $out = if ($Commercial) { 'brief' } else { 'select' }
    return Invoke-ESABCD -Requirement $Requirement -Mode $Mode -ProjectRoot $ProjectRoot -Output $out
}

function Invoke-ESABCDCommercialBrief {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Requirement,
        [ValidateSet('engineering', 'creative-divergence', 'stable')][string]$Mode = 'creative-divergence',
        [string]$ProjectRoot = '',
        [string]$OutDir = ''
    )
    return Invoke-ESABCD -Requirement $Requirement -Mode $Mode -ProjectRoot $ProjectRoot -OutDir $OutDir -Output brief
}

Export-ModuleMember -Function @(
    'Get-ESABCDCapabilityIndexPath',
    'Get-ESABCDCapabilityIndex',
    'Get-ESABCDCapability',
    'Get-ESABCDIndexCatalog',
    'Import-ESABCDCapability',
    'Import-ESABCDProfile',
    'Resolve-ESABCDProjectRoot',
    'Invoke-ESABCD',
    'Invoke-ESABCDQuick',
    'Invoke-ESABCDCommercialBrief'
)