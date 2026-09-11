# ES ABCD package home resolution — independent of any host game framework.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-ESABCDPackageRoot {
    [CmdletBinding()]
    param()
    # ABCD module lives at <root>/ES/Automation/ABCD  OR  <root>/src/... (future)
    $here = $PSScriptRoot
    if ([string]::IsNullOrWhiteSpace($here)) {
        throw 'ABCD_HOME_SCRIPTROOT_MISSING'
    }
    $candidate = (Resolve-Path (Join-Path $here '..\..\..')).Path
    $marker = Join-Path $candidate 'package\es-abcd-portable.manifest.json'
    $marker2 = Join-Path $candidate 'ES\Automation\ABCD\ESABCDHome.psm1'
    if ((Test-Path -LiteralPath $marker -PathType Leaf) -or (Test-Path -LiteralPath $marker2 -PathType Leaf)) {
        return $candidate
    }
    # Fallback: walk up looking for manifest
    $walk = Get-Item -LiteralPath $here
    for ($i = 0; $i -lt 8 -and $null -ne $walk; $i++) {
        $m = Join-Path $walk.FullName 'package\es-abcd-portable.manifest.json'
        if (Test-Path -LiteralPath $m -PathType Leaf) { return $walk.FullName }
        $walk = $walk.Parent
    }
    return $candidate
}

function Get-ESABCDGovernanceMode {
    [CmdletBinding()]
    param()
    # portable (default): self-contained, no host ESFramework AIWarnings corpus
    # host: use host ProjectRoot AIWarnings index when present and fresh
    $raw = [string]$env:ES_ABCD_GOVERNANCE_MODE
    if ([string]::IsNullOrWhiteSpace($raw)) { return 'portable' }
    $v = $raw.Trim().ToLowerInvariant()
    if ($v -in @('portable', 'host')) { return $v }
    throw "ABCD_GOVERNANCE_MODE_INVALID:$raw"
}

function Get-ESABCDContractsRoot {
    [CmdletBinding()]
    param(
        [string]$ProjectRoot = ''
    )
    $pkg = Get-ESABCDPackageRoot
    $pkgContracts = Join-Path $pkg 'ES\Automation\Contracts'
    if (-not [string]::IsNullOrWhiteSpace($ProjectRoot)) {
        $hostContracts = Join-Path $ProjectRoot 'ES\Automation\Contracts'
        if (Test-Path -LiteralPath $hostContracts -PathType Container) {
            # Prefer host overlay when installed into a consumer; fall back to package.
            $probe = Join-Path $hostContracts 'es-ai-abc-generation-mode-v1.json'
            if (Test-Path -LiteralPath $probe -PathType Leaf) { return (Resolve-Path -LiteralPath $hostContracts).Path }
        }
    }
    if (-not (Test-Path -LiteralPath $pkgContracts -PathType Container)) {
        throw "ABCD_CONTRACTS_ROOT_MISSING:$pkgContracts"
    }
    return (Resolve-Path -LiteralPath $pkgContracts).Path
}

function Resolve-ESABCDContractPath {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$FileName,
        [string]$ProjectRoot = ''
    )
    $root = Get-ESABCDContractsRoot -ProjectRoot $ProjectRoot
    $path = Join-Path $root $FileName
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "ABCD_CONTRACT_MISSING:$FileName"
    }
    return (Resolve-Path -LiteralPath $path).Path
}

function Get-ESABCDIdentity {
    [CmdletBinding()]
    param()
    [pscustomobject][ordered]@{
        productId = 'es-abcd'
        productName = 'ES ABCD Portable Core'
        independence = 'host-framework-optional'
        defaultGovernanceMode = 'portable'
        notAGameFramework = $true
        notESFrameworkRuntime = $true
        packageRoot = (Get-ESABCDPackageRoot)
        governanceMode = (Get-ESABCDGovernanceMode)
        sixCapabilitiesRequired = $true
        claim = 'Independent ABCD/ABCC orchestration package; ESFramework is an optional consumer/host, not a runtime dependency for Core profile.'
    }
}

Export-ModuleMember -Function Get-ESABCDPackageRoot,Get-ESABCDGovernanceMode,Get-ESABCDContractsRoot,Resolve-ESABCDContractPath,Get-ESABCDIdentity 
