[CmdletBinding()]
# Authority: es.aiwarnings.global.default (rank 2; below project Skill only)
param(
  [Parameter(Mandatory)][string]$PromptText,
  [ValidateSet('ai-collaboration','game-logic','editor-tooling','release')][string]$Domain='ai-collaboration',
  [string]$ProjectRoot=(Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
)
$ErrorActionPreference='Stop';$OutputEncoding=[Console]::OutputEncoding=[Text.UTF8Encoding]::new($false)
$root=(Resolve-Path -LiteralPath $ProjectRoot).Path
Import-Module (Join-Path $PSScriptRoot 'ESAIWarningsSummaryPolicy.psm1')
Import-Module (Join-Path $PSScriptRoot 'ESAIWarningsMetadataIndex.psm1')
Import-Module (Join-Path $PSScriptRoot 'ESAIWarningsPolicySourceCache.psm1')
$policySources=Get-ESAIWarningsPolicySources -ProjectRoot $root
$contract=$policySources.data.contract;$catalog=$policySources.data.catalog;$generatedMetadataIndex=$policySources.data.metadataIndex
$contractPath=[string]$policySources.data.contractPath;$catalogPath=[string]$policySources.data.catalogPath;$metadataIndexPath=[string]$policySources.data.metadataIndexPath
if([string]$generatedMetadataIndex.authorityId-cne'es.aiwarnings.global.default'-or[int]$generatedMetadataIndex.entryCount-ne@($generatedMetadataIndex.entries).Count){throw 'AIWARNINGS_METADATA_INDEX_CONTRACT_INVALID'}
$text=$PromptText.Trim();$matched=@();foreach($route in @($catalog.routes)){ $terms=@($route.match|ForEach-Object{ $s=[string]$_;if($s.Length -le 12){$s}else{@($s -split '\s+'|Where-Object{$_.Length -ge 2})} }|Where-Object{ -not [string]::IsNullOrWhiteSpace([string]$_) }|Select-Object -Unique);$hits=@($terms|Where-Object{Test-ESAIWarningsTextTerm -Text $text -Term ([string]$_)});if($hits.Count -gt 0 -and [string]$route.state -eq 'current'){$ruleId=if(-not[string]::IsNullOrWhiteSpace([string]$route.ruleId)){[string]$route.ruleId}else{[string]$route.id};$severity=if(-not[string]::IsNullOrWhiteSpace([string]$route.severity)){[string]$route.severity}elseif($ruleId-match'(?i)p0'){'P0'}else{'P1'};$routeDecision=if(-not[string]::IsNullOrWhiteSpace([string]$route.decision)){[string]$route.decision}elseif($severity-eq'P0'){'claim-cap'}else{'consume-and-report'};$matched+=[pscustomobject]@{ruleId=$ruleId;routeId=[string]$route.id;severity=$severity;relevanceScore=(100+$hits.Count);matchedTerms=$hits;mustRead=@($route.mustRead);decision=$routeDecision;source='explicit-route-catalog'}}}
$liveMetadataIndex=@(Get-ESAIWarningsMetadataIndex -ProjectRoot $root)
$metadataIndex=@($generatedMetadataIndex.entries)
$liveKeys=@($liveMetadataIndex|ForEach-Object{[string]$_.ruleId+'|'+[string]$_.sourcePath+'|'+[string]$_.metadataHeaderHash}|Sort-Object)
$generatedKeys=@($metadataIndex|ForEach-Object{[string]$_.ruleId+'|'+[string]$_.sourcePath+'|'+[string]$_.metadataHeaderHash}|Sort-Object)
if(($liveKeys|ConvertTo-Json -Compress)-cne($generatedKeys|ConvertTo-Json -Compress)){throw 'AIWARNINGS_METADATA_INDEX_STALE'}
$metadataMatches=@(Find-ESAIWarningsMetadataRoutes -PromptText $text -Index $metadataIndex)
$explicitIds=@($matched|ForEach-Object{[string]$_.ruleId})
$matched+=@($metadataMatches|Where-Object{$explicitIds -notcontains [string]$_.ruleId})
$summary=Select-ESAIWarningsMainSummary -Candidates $matched -Policy $contract.summaryPolicy
$matchedIds=@($summary.matchedRuleIds);$mainWarnings=@($summary.mainWarnings)
$mainWarningIds=@($mainWarnings|ForEach-Object{[string]$_.ruleId})
$matchedGeneratedEntries=@($metadataIndex|Where-Object{$mainWarningIds-contains[string]$_.ruleId})
foreach($entry in $matchedGeneratedEntries){$sourcePath=Join-Path $root ([string]$entry.sourcePath);if(-not(Test-Path -LiteralPath $sourcePath -PathType Leaf)-or(Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash.ToLowerInvariant()-cne[string]$entry.sourceSha256){throw 'AIWARNINGS_MATCHED_SOURCE_STALE:'+([string]$entry.ruleId)}}
$selectedMustRead=@($matched|Where-Object{$mainWarningIds -contains [string]$_.ruleId}|ForEach-Object{$_.mustRead}|ForEach-Object{[string]$_}|Where-Object{-not[string]::IsNullOrWhiteSpace($_)}|Select-Object -Unique)
$mustRead=@(@($contract.mandatoryCoreReads)+@($selectedMustRead)|Select-Object -Unique)
$hash=[string]$policySources.data.contractHash;$catalogHash=[string]$policySources.data.catalogHash;$decision=if(@($mainWarnings|Where-Object decision -eq 'claim-cap').Count -gt 0){'claim-cap'}else{'consume-and-report'}
$sha=[Security.Cryptography.SHA256]::Create();try{$inputBytes=[Text.Encoding]::UTF8.GetBytes(($Domain+"`n"+$PromptText));$inputHash=([BitConverter]::ToString($sha.ComputeHash($inputBytes))).Replace('-','').ToLowerInvariant()}finally{$sha.Dispose()}
[ordered]@{schemaVersion=1;contractId=[string]$contract.contractId;authorityId=[string]$contract.authorityId;authorityRank=[int]$contract.authorityRank;skillAuthorityRank=1;skillOverrideRank=1;domain=$Domain;prompt=$PromptText;inputHash=$inputHash;authorityHash=$hash;catalogHash=$catalogHash;policySourceCache=[ordered]@{cacheHit=[bool]$policySources.cacheHit;generationId=[string]$policySources.generationId};metadataIndex=[ordered]@{indexId=[string]$generatedMetadataIndex.indexId;indexHash=[string]$policySources.data.metadataIndexHash;sourceManifestHash=[string]$generatedMetadataIndex.sourceManifestHash;indexedCurrentWarnings=$metadataIndex.Count;matchedWarnings=$metadataMatches.Count;boundedHeaderLines=[int]$contract.metadataRoutingPolicy.boundedHeaderLines;bodyReadPolicy=[string]$contract.metadataRoutingPolicy.bodyReadPolicy;freshnessPolicy=[string]$contract.metadataRoutingPolicy.freshnessPolicy};matchedRuleIds=@($matchedIds|Where-Object{-not [string]::IsNullOrWhiteSpace([string]$_)});mainWarnings=$mainWarnings;warningOverflowCount=[int]$summary.overflowCount;warningsTruncated=[bool]$summary.truncated;mustRead=$mustRead;policyDecision=$decision;behaviorPolicy=$contract.mandatoryDefaultBehavior;requiredPhases=$contract.requiredPhases;consumedAtUtc=[DateTime]::UtcNow.ToString('o');nonClaims=$contract.nonClaims}|ConvertTo-Json -Depth 20
