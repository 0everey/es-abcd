[CmdletBinding()]
param()
$ErrorActionPreference='Stop'
Import-Module (Join-Path $PSScriptRoot 'ESABCInnovationRun.psm1') -Force
$commands=@{lifecycle={ 'lifecycle-ok' };performance={ 'performance-ok' };network={ 'network-ok' };debugging={ 'debugging-ok' };editorProduction={ 'editor-ok' }}
$valid=Invoke-ESABCEngineeringDimensionVerification -DimensionCommands $commands -TimeoutSeconds 5
$bad=$false;try{Invoke-ESABCEngineeringDimensionVerification -DimensionCommands @{lifecycle={$true}}|Out-Null}catch{$bad=$_.Exception.Message -eq 'ENGINEERING_DIMENSION_COMMANDS_INCOMPLETE'}
$pass=($valid.status -eq 'passed' -and @($valid.dimensions).Count -eq 5 -and @($valid.dimensions|Where-Object {$_.status -ne 'verified' -or $_.verificationReceipt.exitCode -ne 0}).Count -eq 0 -and $bad)
[pscustomobject]@{status=if($pass){'passed'}else{'failed'};verifiedDimensions=@($valid.dimensions|Where-Object status -eq 'verified').Count;missingCommandsBlocked=$bad;receiptsHaveHashes=(@($valid.dimensions|Where-Object {$_.evidenceHash -match '^[a-f0-9]{64}$'}).Count -eq 5)}
if(-not $pass){exit 1} 
