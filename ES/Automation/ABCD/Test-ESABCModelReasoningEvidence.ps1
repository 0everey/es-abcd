[CmdletBinding()]
param()
$ErrorActionPreference='Stop'
$module=Join-Path $PSScriptRoot 'ESABCInnovationRun.psm1'
Import-Module $module -Force
function Hash([string]$s){([Security.Cryptography.SHA256]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($s))|ForEach-Object ToString x2)-join ''}
$trace=@('identify player goal and constraints','compare two alternatives and side effects','run counterfactual replay before decision')
$alts=@('conservative increment','mechanism redesign')
$rationale='Choose redesign because it preserves role identity while creating actionable decision differences and counterplay in failure paths.'
$payload=[ordered]@{reasoningTrace=$trace;alternativesConsidered=$alts;decisionRationale=$rationale}|ConvertTo-Json -Compress -Depth 20
$requestHash=(Hash 'stage-request')
$valid=[pscustomobject]@{reasoningTrace=$trace;alternativesConsidered=$alts;decisionRationale=$rationale;modelEvidence=[pscustomobject]@{providerId='provider-real-01';requestHash=$requestHash;responseHash=(Hash 'response');analysisHash=(Hash $payload)}}
$r=Test-ESABCModelReasoningEvidence -Result $valid -RequestHash $requestHash
if(-not $r.valid){throw "valid-reasoning-rejected:$([string]::Join(',',@($r.errors)))"}
$invalid=$valid.PSObject.Copy();$invalid.modelEvidence=[pscustomobject]@{providerId='fixture-provider';requestHash=$requestHash;responseHash=(Hash 'response');analysisHash=(Hash $payload)}
$bad=Test-ESABCModelReasoningEvidence -Result $invalid -RequestHash $requestHash
if($bad.valid -or @($bad.errors) -notcontains 'modelEvidence.providerId-invalid'){throw 'invalid-reasoning-accepted'}
[pscustomobject]@{status='passed';validReasoning=$r.valid;negativeRejected=(-not $bad.valid);negativeReasons=@($bad.errors)}|ConvertTo-Json -Compress 
