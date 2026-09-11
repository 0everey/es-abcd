[CmdletBinding()]
param(
    [string]$ProjectRoot = ''
)

# ABCD mode/function/level must map to generation modes only.
# Portable: no AIWarnings/AGENTS. Safe to share byte-identical with ES host repo.
# ASCII-only source for Windows PowerShell 5.1 parser safety.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $ProjectRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\..')).Path
} else {
    $ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
}
$root = $ProjectRoot
$errors = [System.Collections.Generic.List[string]]::new()

$genPath = Join-Path $root 'ES\Automation\Contracts\es-ai-abc-generation-mode-v1.json'
$regPath = Join-Path $root 'ES\Automation\Contracts\es-ai-abc-mode.registry.json'
$resolver = Join-Path $root 'ES\Automation\ABCD\Resolve-ESABCDGenerationMode.ps1'

if (-not (Test-Path -LiteralPath $genPath -PathType Leaf)) {
    [void]$errors.Add('gen-contract-missing')
} else {
    $gen = Get-Content -LiteralPath $genPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $map = $gen.abcdModeFunctionLevelMapping
    if ($null -eq $map) {
        [void]$errors.Add('mapping-missing')
    } else {
        $ids = @($map.mapsToGenerationModeIds | ForEach-Object { [string]$_ })
        foreach ($n in @('creative-divergence', 'engineering', 'stable')) {
            if ($ids -notcontains $n) { [void]$errors.Add("missing-mode:$n") }
        }
        if ($ids.Count -ne 3) { [void]$errors.Add('must-be-exactly-three') }
        $forb = @($map.forbiddenAsAbcdModeFunctionLevel | ForEach-Object { [string]$_ })
        foreach ($f in @('ABCD.Dynamic', 'ABCC.Core', 'ABCP.Part')) {
            if ($forb -notcontains $f) { [void]$errors.Add("forbidden-missing:$f") }
        }
    }
    if ($null -eq $gen.orthogonality -or [bool]$gen.orthogonality.abcdModeFunctionLevelIsGenerationModesOnly -ne $true) {
        [void]$errors.Add('orthogonality-flag-missing')
    }
}

if (-not (Test-Path -LiteralPath $regPath -PathType Leaf)) {
    [void]$errors.Add('registry-missing')
} else {
    $reg = Get-Content -LiteralPath $regPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $m = $reg.namingAuthority.abcdModeFunctionLevelMapping
    if ($null -eq $m) {
        [void]$errors.Add('registry-mapping-missing')
    } elseif ([string]$m.mapsTo -cne 'generation-modes-only') {
        [void]$errors.Add('registry-mapsTo-drift')
    }
    $lock = $reg.namingAuthority.monoSemanticLock
    if ($null -ne $lock -and [bool]$lock.abcdModeFunctionLevelMapsToGenerationModes -ne $true) {
        [void]$errors.Add('mono-lock-missing-generation-mode-flag')
    }
}

$proofs = [System.Collections.Generic.List[object]]::new()
if (-not (Test-Path -LiteralPath $resolver -PathType Leaf)) {
    [void]$errors.Add('resolver-missing')
} else {
    function Invoke-GenModeResolve([string]$prompt) {
        $json = & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $resolver -PromptText $prompt -ProjectRoot $root 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "resolver-exit-$LASTEXITCODE : $json"
        }
        return ($json | Out-String | ConvertFrom-Json)
    }

    try {
        $a = Invoke-GenModeResolve 'Select ABCD mode engineering'
        if ([string]$a.selectedGenerationModeId -cne 'engineering') { [void]$errors.Add('eng-label-fail') }
        if ([bool]$a.architectureIdentitiesAreNotAbcdModes -ne $true) { [void]$errors.Add('arch-not-mode-flag') }
        [void]$proofs.Add([ordered]@{ case = 'engineering'; selected = [string]$a.selectedGenerationModeId })

        $b = Invoke-GenModeResolve 'ABCD mode creative-divergence'
        if ([string]$b.selectedGenerationModeId -cne 'creative-divergence') { [void]$errors.Add('creative-fail') }
        [void]$proofs.Add([ordered]@{ case = 'creative'; selected = [string]$b.selectedGenerationModeId })

        $c = Invoke-GenModeResolve 'ABCD level stable'
        if ([string]$c.selectedGenerationModeId -cne 'stable') { [void]$errors.Add('stable-fail') }
        [void]$proofs.Add([ordered]@{ case = 'stable'; selected = [string]$c.selectedGenerationModeId })

        $d = Invoke-GenModeResolve 'ABCD mode is Dynamic'
        if ([string]$d.status -cne 'rejected-architecture-as-abcd-mode') { [void]$errors.Add('reject-dynamic-as-mode-fail') }
        if ([string]$d.decision -cne 'claim-cap') { [void]$errors.Add('reject-must-claim-cap') }
        $selD = [string]$d.selectedGenerationModeId
        if (-not [string]::IsNullOrWhiteSpace($selD)) {
            [void]$errors.Add('reject-must-not-select-generation-mode')
        }
        [void]$proofs.Add([ordered]@{ case = 'reject-Dynamic-as-mode'; status = [string]$d.status })

        $e = Invoke-GenModeResolve 'ABCD mode'
        if ([string]$e.selectedGenerationModeId -cne 'engineering') { [void]$errors.Add('default-should-engineering') }
        [void]$proofs.Add([ordered]@{ case = 'default'; selected = [string]$e.selectedGenerationModeId })
    }
    catch {
        [void]$errors.Add("fixture:$($_.Exception.Message)")
    }
}

$status = if ($errors.Count -eq 0) { 'passed' } else { 'failed' }
[ordered]@{
    schemaVersion = 1
    validator = 'es-abcd-mode-function-level-mapping'
    status = $status
    mapsTo = @('creative-divergence', 'engineering', 'stable')
    notArchitectureIdentities = @('ABCD.Dynamic', 'ABCC.Core', 'ABCP.Part')
    proofs = @($proofs)
    findings = @($errors)
    runtimeStatus = 'runtime-not-run'
} | ConvertTo-Json -Depth 8

if ($errors.Count -gt 0) { exit 1 } 
