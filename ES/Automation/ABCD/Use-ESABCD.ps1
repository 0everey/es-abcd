# es-abcd single consumer entry. Dot-source OR Import-Module this file.
#   . .\ES\Automation\ABCD\Use-ESABCD.ps1
#   Invoke-ESABCD -Requirement "your goal"            # default: commercial brief
#   Invoke-ESABCD -Requirement "..." -Output select   # selection object only
#   Get-ESABCDIndexCatalog                            # fast index of core caps
$ErrorActionPreference = 'Stop'
$env:ES_ABCD_GOVERNANCE_MODE = 'portable'
$here = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($here)) {
    $here = Split-Path -Parent $MyInvocation.MyCommand.Path
}
Import-Module (Join-Path $here 'ESABCDHome.psm1') -Force -Global
Import-Module (Join-Path $here 'ESABCDIndex.psm1') -Force -Global
# Index owns product entry; capabilities load on demand inside Invoke-ESABCD / Import-ESABCDProfile.