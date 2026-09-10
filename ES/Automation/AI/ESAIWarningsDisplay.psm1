Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Presentation-only projection. Machine receipts continue to use the full
# stable ruleId and English decision values; this module only formats the
# user-facing closeout summary.
function ConvertFrom-ESAIWarningsDisplayEntity([string]$Value) {
    return [Net.WebUtility]::HtmlDecode($Value)
}

$decisionLabels = @{
    'stop-and-report' = ConvertFrom-ESAIWarningsDisplayEntity '&#x505C;&#x6B62;&#x5E76;&#x62A5;&#x544A;'
    'claim-cap' = ConvertFrom-ESAIWarningsDisplayEntity '&#x9650;&#x5236;&#x58F0;&#x660E;'
    'consume-and-report' = ConvertFrom-ESAIWarningsDisplayEntity '&#x6D88;&#x8D39;&#x5E76;&#x62A5;&#x544A;'
    'review' = ConvertFrom-ESAIWarningsDisplayEntity '&#x8FDB;&#x5165;&#x590D;&#x6838;'
    'hard-block' = ConvertFrom-ESAIWarningsDisplayEntity '&#x786C;&#x963B;&#x65AD;'
    'stop-next-read' = ConvertFrom-ESAIWarningsDisplayEntity '&#x505C;&#x6B62;&#x540E;&#x7EED;&#x8BFB;&#x53D6;'
}

$purposeByRule = @{
    'es.aiwarning.p0.ai-delivery-claim-boundary' = ConvertFrom-ESAIWarningsDisplayEntity '&#x9650;&#x5236;&#x672A;&#x7ECF;&#x8BC1;&#x636E;&#x652F;&#x6301;&#x7684;&#x4EA4;&#x4ED8;&#x5B8C;&#x6210;&#x58F0;&#x660E;'
    'es.aiwarnings.agent-skills-aicommands-boundary' = ConvertFrom-ESAIWarningsDisplayEntity '&#x9650;&#x5236; Skill &#x4E0E; AICommand &#x7684;&#x6743;&#x9650;&#x548C;&#x804C;&#x8D23;&#x8D8A;&#x754C;'
    'es.aiwarning.p0.ai-collaboration-history-session-recovery.v1' = ConvertFrom-ESAIWarningsDisplayEntity '&#x9650;&#x5236;&#x4F1A;&#x8BDD;&#x6062;&#x590D;&#x65F6;&#x628A;&#x5386;&#x53F2;&#x5185;&#x5BB9;&#x5192;&#x5145;&#x4E3A;&#x5F53;&#x524D;&#x8BC1;&#x636E;'
    'es.aiwarning.arch.module-maturity-incomplete-governance' = ConvertFrom-ESAIWarningsDisplayEntity '&#x63D0;&#x793A;&#x6A21;&#x5757;&#x6210;&#x719F;&#x5EA6;&#x6216;&#x6CBB;&#x7406;&#x8BC1;&#x636E;&#x4ECD;&#x4E0D;&#x5B8C;&#x6574;'
    'es.aiwarning.esdeveloper-cockpit-architecture-contract.v1' = ConvertFrom-ESAIWarningsDisplayEntity '&#x7EA6;&#x675F; ESDeveloper Cockpit &#x67B6;&#x6784;&#x5951;&#x7EA6;&#x7684;&#x9002;&#x7528;&#x8FB9;&#x754C;'
    'es.aiwarning.validation.scene-builder-authority-backup-boundary' = ConvertFrom-ESAIWarningsDisplayEntity '&#x7EA6;&#x675F;&#x573A;&#x666F;&#x6784;&#x5EFA;&#x5668;&#x7684;&#x6743;&#x5A01;&#x4E0E;&#x5907;&#x4EFD;&#x8FB9;&#x754C;'
    'es.aiwarnings.start.readme.v1' = ConvertFrom-ESAIWarningsDisplayEntity '&#x8981;&#x6C42;&#x9075;&#x5FAA; AIWarnings &#x542F;&#x52A8;&#x5165;&#x53E3;&#x548C;&#x6700;&#x5C0F;&#x8BFB;&#x53D6;&#x94FE;'
}

function Get-ESAIWarningsDisplayRuleId {
    [CmdletBinding()]
    param([Parameter(Mandatory)][AllowEmptyString()][string]$RuleId)
    return ($RuleId -replace '(?i)^es\.aiwarnings?\.', '')
}

function Get-ESAIWarningsDisplayDecision {
    [CmdletBinding()]
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Decision)
    if ($decisionLabels.ContainsKey($Decision)) { return [string]$decisionLabels[$Decision] }
    return (ConvertFrom-ESAIWarningsDisplayEntity '&#x5F85;&#x786E;&#x8BA4;&#x5904;&#x7F6E;')
}

function Get-ESAIWarningsDisplayPurpose {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Warning)
    $ruleId = [string]$Warning.ruleId
    $purposeProperty = $Warning.PSObject.Properties['purpose']
    if ($null -ne $purposeProperty -and -not [string]::IsNullOrWhiteSpace([string]$purposeProperty.Value)) {
        return [string]$purposeProperty.Value
    }
    if ($purposeByRule.ContainsKey($ruleId)) { return [string]$purposeByRule[$ruleId] }
    switch ([string]$Warning.decision) {
        'claim-cap' { return (ConvertFrom-ESAIWarningsDisplayEntity '&#x9650;&#x5236;&#x5B8C;&#x6210;&#x58F0;&#x660E;&#x5E76;&#x4FDD;&#x7559;&#x672A;&#x9A8C;&#x8BC1;&#x9879;') }
        'stop-and-report' { return (ConvertFrom-ESAIWarningsDisplayEntity '&#x505C;&#x6B62;&#x5F53;&#x524D;&#x52A8;&#x4F5C;&#x5E76;&#x62A5;&#x544A;&#x89E6;&#x53D1;&#x539F;&#x56E0;') }
        'hard-block' { return (ConvertFrom-ESAIWarningsDisplayEntity '&#x963B;&#x6B62;&#x5F53;&#x524D;&#x5BF9;&#x8C61;&#x6216;&#x8303;&#x56F4;&#x7EE7;&#x7EED;&#x6267;&#x884C;') }
        'stop-next-read' { return (ConvertFrom-ESAIWarningsDisplayEntity '&#x505C;&#x6B62;&#x540E;&#x7EED;&#x8BFB;&#x53D6;&#x5E76;&#x5148;&#x62A5;&#x544A;&#x539F;&#x56E0;') }
        'review' { return (ConvertFrom-ESAIWarningsDisplayEntity '&#x8981;&#x6C42;&#x590D;&#x6838;&#x540E;&#x518D;&#x51B3;&#x5B9A;&#x662F;&#x5426;&#x7EE7;&#x7EED;') }
        'consume-and-report' { return (ConvertFrom-ESAIWarningsDisplayEntity '&#x6D88;&#x8D39;&#x672C;&#x6761;&#x89C4;&#x5219;&#x5E76;&#x5728;&#x6536;&#x5C3E;&#x4E2D;&#x62A5;&#x544A;') }
        default { return (ConvertFrom-ESAIWarningsDisplayEntity '&#x4F5C;&#x7528;&#x5F85;&#x4ECE;&#x89C4;&#x5219;&#x6B63;&#x6587;&#x786E;&#x8BA4;') }
    }
}

function ConvertTo-ESAIWarningsDisplay {
    [CmdletBinding()]
    param([Parameter(Mandatory)]$Warning)
    $fullRuleId = [string]$Warning.ruleId
    $displayRuleId = Get-ESAIWarningsDisplayRuleId $fullRuleId
    $decision = [string]$Warning.decision
    $displayDecision = Get-ESAIWarningsDisplayDecision $decision
    $purpose = Get-ESAIWarningsDisplayPurpose $Warning
    [pscustomobject][ordered]@{
        ruleId = $fullRuleId
        displayRuleId = $displayRuleId
        severity = [string]$Warning.severity
        decision = $decision
        displayDecision = $displayDecision
        purpose = $purpose
        displayLine = ((ConvertFrom-ESAIWarningsDisplayEntity '{0} / {1} / {2}&#xFF08;&#x4F5C;&#x7528;&#xFF1A;{3}&#xFF09;') -f $displayRuleId, [string]$Warning.severity, $displayDecision, $purpose)
    }
}

Export-ModuleMember -Function Get-ESAIWarningsDisplayRuleId, Get-ESAIWarningsDisplayDecision, Get-ESAIWarningsDisplayPurpose, ConvertTo-ESAIWarningsDisplay
