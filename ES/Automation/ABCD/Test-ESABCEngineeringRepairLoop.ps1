[CmdletBinding()]
param()
$ErrorActionPreference='Stop';Import-Module (Join-Path $PSScriptRoot 'ESABCInnovationRun.psm1') -Force
$script:verifyCount=0
$verify={param($ctx)$script:verifyCount++;if($script:verifyCount -ge 2){[pscustomobject]@{status='passed';output='fixed'}}else{[pscustomobject]@{status='failed';output='compile-error'}}}
$repair={param($ctx)[pscustomobject]@{candidate=[pscustomobject]@{version=2;repairValidationStatus='verified'};changedFiles=@('Assets/Scripts/Feature.cs');sourceHashBefore=('a'*64);sourceHashAfter=('b'*64);agentId='engineering-agent-test';reads=@('Assets/Scripts/Feature.cs');writes=@('Assets/Scripts/Feature.cs');failureCauses=@('compile-error');nextHypotheses=@('re-run-compile');diagnosis='compile-error fixed'}}
$ok=Invoke-ESABCEngineeringRepairLoop -Candidate ([pscustomobject]@{version=1}) -VerifyInvoker $verify -RepairInvoker $repair -MaxIterations 3
$bad=$false;try{Invoke-ESABCEngineeringRepairLoop -Candidate ([pscustomobject]@{version=1}) -VerifyInvoker {param($ctx)[pscustomobject]@{status='failed'}} -RepairInvoker {param($ctx)[pscustomobject]@{candidate=[pscustomobject]@{version=2}}}|Out-Null}catch{}
$badResult=Invoke-ESABCEngineeringRepairLoop -Candidate ([pscustomobject]@{version=1}) -VerifyInvoker {param($ctx)[pscustomobject]@{status='failed'}} -RepairInvoker {param($ctx)[pscustomobject]@{candidate=[pscustomobject]@{version=2}}}
$pass=($ok.status -eq 'completed' -and @($ok.attempts|Where-Object status -eq 'repaired').Count -eq 1 -and $badResult.status -eq 'blocked' -and $badResult.reasonCode -eq 'ENGINEERING_REPAIR_EVIDENCE_REQUIRED')
[pscustomobject]@{status=if($pass){'passed'}else{'failed'};successfulRepairLoop=$ok.status;repairAttempts=@($ok.attempts).Count;invalidRepairBlocked=$badResult.status -eq 'blocked'}
if(-not $pass){exit 1} 
