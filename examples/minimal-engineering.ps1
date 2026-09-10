# Minimal engineering divergence example (run after Install-ESABCD into a project).
# Usage:
#   pwsh -File examples/minimal-engineering.ps1 -ProjectRoot C:\path\to\YourProject

[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ProjectRoot
)

$ErrorActionPreference = 'Stop'
$ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path

Import-Module "$ProjectRoot\ES\Automation\ABCD\ESABCDDivergence.psm1" -Force
Import-Module "$ProjectRoot\ES\Automation\ABCD\ESABCInnovationRun.psm1" -Force

$contract = "$ProjectRoot\ES\Automation\Contracts\es-ai-abc-generation-mode-v1.json"
$hash = (Get-FileHash -LiteralPath $contract -Algorithm SHA256).Hash.ToLowerInvariant()

$requirement = @'
Freeze three architecture layers for a multi-domain product:
(1) platform domains, (2) definition tables, (3) physical/query layers.
Forbidden: encode faction rules as physics layers; add a fourth platform domain;
bypass the single execution gateway.
'@

$div = Invoke-ESABCModeDivergence `
    -Requirement $requirement `
    -SourceHash $hash `
    -Mode engineering `
    -ProjectRoot $ProjectRoot

$sel = Select-ESABCGenerationCandidate -Candidates $div.directions -Mode engineering

Write-Host "directions=$($div.directionCount) selected=$($sel.selectedDirectionId)"
Write-Host "claimLevel=$($sel.claimLevel) selectionStatus=$($sel.selectionStatus)"
Write-Host "candidateSetHash=$($div.candidateSetHash)"
Write-Host "runtimeStatus=runtime-not-run (expected for this example)"
