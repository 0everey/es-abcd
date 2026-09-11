Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'

function Select-ESAIWarningsMainSummary {
    [CmdletBinding()]
    param([object[]]$Candidates=@(),[Parameter(Mandatory)]$Policy)
    $mandatory=[string]$Policy.mandatoryFirstRuleId
    if([string]::IsNullOrWhiteSpace($mandatory)){throw 'AIWARNINGS_MANDATORY_FIRST_RULE_MISSING'}
    $decisionOrder=@($Policy.decisionPriority|ForEach-Object{[string]$_})
    $severityOrder=@($Policy.severityPriority|ForEach-Object{[string]$_})
    $deduped=@($Candidates|Where-Object{-not[string]::IsNullOrWhiteSpace([string]$_.ruleId)}|Group-Object ruleId|ForEach-Object{$_.Group|Select-Object -First 1})
    $ordered=@($deduped|Where-Object{[string]$_.ruleId -cne $mandatory}|Sort-Object @{Expression={$i=[Array]::IndexOf($decisionOrder,[string]$_.decision);if($i-lt0){999}else{$i}}},@{Expression={$i=[Array]::IndexOf($severityOrder,[string]$_.severity);if($i-lt0){999}else{$i}}},@{Expression={if($_.PSObject.Properties['relevanceScore']){-[int]$_.relevanceScore}else{0}}},@{Expression={[string]$_.ruleId}})
    $all=@([pscustomobject][ordered]@{ruleId=$mandatory;severity='P0';decision='claim-cap'})+@($ordered|ForEach-Object{[pscustomobject][ordered]@{ruleId=[string]$_.ruleId;severity=[string]$_.severity;decision=[string]$_.decision}})
    $max=[Math]::Max(1,[int]$Policy.maxMainWarnings)
    [pscustomobject][ordered]@{
        matchedRuleIds=@($all|ForEach-Object{[string]$_.ruleId})
        mainWarnings=@($all|Select-Object -First $max)
        overflowCount=[Math]::Max(0,$all.Count-$max)
        truncated=($all.Count-gt$max)
    }
}

Export-ModuleMember -Function Select-ESAIWarningsMainSummary 
