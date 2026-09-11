[CmdletBinding()]
param([string]$ProjectRoot)
$ErrorActionPreference='Stop'
if([string]::IsNullOrWhiteSpace($ProjectRoot)){$ProjectRoot=(Get-Location).Path}
$root=(Resolve-Path -LiteralPath $ProjectRoot).Path
Push-Location $root
try {
 Import-Module (Join-Path $root 'ES/Automation/ABCD/ESABCInnovationRun.psm1') -Force
 $head=(git rev-parse HEAD).Trim();$relative='ES/Automation/ABCD/ESABCInnovationRun.psm1';$content=Get-Content -Raw -Encoding UTF8 $relative
 $hash=(Get-FileHash -LiteralPath 'ES/Automation/Contracts/es-ai-abc-engineering-architecture-competition-v1.schema.json' -Algorithm SHA256).Hash.ToLowerInvariant()
 $evidence=[pscustomobject]@{eligibleCount=2;implementationEvidenceVerifiedCount=2;independentReplayVerifiedCount=2;providerScoreComparisonStatus='stable'}
 $result=[pscustomobject]@{status='completed';completionEligible=$true;winnerId='arch-1';contractHash=$hash;evidenceSummary=$evidence}
 $candidate=[pscustomobject]@{status='candidate';generationMode='engineering';candidateSetHash=('c'*64);candidates=@([pscustomobject]@{candidateId='arch-1';proposedChanges=@([pscustomobject]@{path=$relative;changeId='noop';afterContent=$content})})}
 $out=Convert-ESABCEngineeringResultToCandidatePatchPlan -EngineeringResult $result -CandidateEnvelope $candidate -Scenario DesignChange -CurrentHead $head -AuthorizationRef 'in-process-test' -AllowedWriteScopes @($relative)
 $blocked=$false
 try {Convert-ESABCEngineeringResultToCandidatePatchPlan -EngineeringResult ([pscustomobject]@{status='review-required';completionEligible=$false;winnerId='arch-1'}) -CandidateEnvelope $candidate -Scenario DesignChange -CurrentHead $head -AuthorizationRef 'in-process-test' -AllowedWriteScopes @($relative)|Out-Null} catch {$blocked=$_.Exception.Message -like '*NOT_ELIGIBLE*'}
 $pass=($out.status -eq 'candidate-only' -and $out.patchPlan.planStatus -eq 'awaiting-abcd-audit' -and $blocked)
 [pscustomobject]@{status=if($pass){'passed'}else{'failed'};convertedStatus=$out.status;planStatus=$out.patchPlan.planStatus;reviewBlocked=$blocked}
} finally {Pop-Location}
if(-not $pass){exit 1} 
