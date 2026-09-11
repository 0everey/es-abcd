[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)][string]$TaskPath,
    [Parameter(Mandatory=$true)][string]$RoutePlanPath,
    [Parameter(Mandatory=$true)][string]$ExchangeReceiptPath,
    [Parameter(Mandatory=$true)][string]$AuthorizationRef,
    [ValidateSet('creative-divergence','engineering','stable')][string]$GenerationMode = 'engineering',
    [ValidateSet('shallow-fast','full-depth','core-high-risk')][string]$AcceptanceProfile = 'core-high-risk',
    [switch]$RequireFullAbcd,
    [string]$OutputPath = 'ES/Output/WebPageStudio/bootstrap/abc-task-binding.json'
)

$ErrorActionPreference='Stop'
$root=(Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
function Read-StrictJson([string]$Path){
    $full=[IO.Path]::GetFullPath((Join-Path $root $Path))
    if(-not $full.StartsWith($root+'\',[StringComparison]::OrdinalIgnoreCase) -or -not(Test-Path -LiteralPath $full -PathType Leaf)){throw "input-not-found:$Path"}
    [Text.UTF8Encoding]::new($false,$true).GetString([IO.File]::ReadAllBytes($full))|ConvertFrom-Json
}
function Hash([object]$Value){
    $sha=[Security.Cryptography.SHA256]::Create()
    try {
        $bytes=[Text.UTF8Encoding]::new($false).GetBytes(($Value|ConvertTo-Json -Depth 40 -Compress))
        return ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-','').ToLowerInvariant()
    } finally {$sha.Dispose()}
}
$task=Read-StrictJson $TaskPath;$route=Read-StrictJson $RoutePlanPath;$exchange=Read-StrictJson $ExchangeReceiptPath
$effectiveAcceptance = if($RequireFullAbcd){'full-depth'}else{$AcceptanceProfile}
$taskId=[string]$task.taskId
if([string]::IsNullOrWhiteSpace($taskId)){throw 'BLOCKED_ES_ABC_BINDING_TASK_ID_MISSING'}
if([string]$exchange.recordType -cne 'ABCExchangeReceipt' -or [string]$exchange.status -cne 'accepted'){throw 'BLOCKED_ES_ABC_BINDING_EXCHANGE_NOT_ACCEPTED'}
if([string]$exchange.taskId -cne $taskId){throw 'BLOCKED_ES_ABC_BINDING_EXCHANGE_TASK_MISMATCH'}
if([string]$exchange.routePlanHash -cne [string]$route.routePlanHash){throw 'BLOCKED_ES_ABC_BINDING_EXCHANGE_ROUTE_MISMATCH'}
if([string]$exchange.sourceScopeHash -cne [string]$task.sourceScopeHash){throw 'BLOCKED_ES_ABC_BINDING_EXCHANGE_SCOPE_MISMATCH'}
if([string]::IsNullOrWhiteSpace([string]$exchange.receiptHash)){throw 'BLOCKED_ES_ABC_BINDING_EXCHANGE_HASH_MISSING'}
if([string]::IsNullOrWhiteSpace($AuthorizationRef)){throw 'BLOCKED_ES_ABC_BINDING_AUTHORIZATION_MISSING'}
$bindingId='atb-'+([Guid]::NewGuid().ToString('N'))
$binding=[ordered]@{
    schemaVersion=1;bindingId=$bindingId;taskBindingId=$bindingId;authorizationRef=$AuthorizationRef
    task=[ordered]@{taskId=$taskId;taskRevision=[int]$task.taskRevision;contextVersion=[int]$task.contextVersion}
    route=[ordered]@{routePlanId=[string]$route.routePlanId;routePlanHash=[string]$route.routePlanHash}
    abc=[ordered]@{coreRef='es.ai-abc.core.v1';generationMode=$GenerationMode;acceptanceProfile=$effectiveAcceptance;requireFullAbcd=[bool]$RequireFullAbcd;partRefs=@();exchangeReceiptHash=[string]$exchange.receiptHash;exchangeReceiptRef=[ordered]@{path=$ExchangeReceiptPath.Replace('\','/');sha256=(Get-FileHash (Join-Path $root $ExchangeReceiptPath) -Algorithm SHA256).Hash.ToLowerInvariant();producerId=[string]$exchange.producerId}}
    focus=$null;sourceScopeHash=[string]$task.sourceScopeHash;bindingHash=$null
}
$runtime=Import-Module (Join-Path $root 'ES/Automation/TaskContextRuntime/ESTaskContextRuntime.psm1') -PassThru -Force
$binding.bindingHash=Hash (& $runtime { param($v) Get-ESABCTaskBindingHashInput $v } ([pscustomobject]$binding))
$outFull=[IO.Path]::GetFullPath((Join-Path $root $OutputPath));if(-not $outFull.StartsWith($root+'\',[StringComparison]::OrdinalIgnoreCase)){throw 'OutputPath outside project root.'}
$parent=Split-Path -Parent $outFull;if(-not(Test-Path $parent)){New-Item -ItemType Directory -Path $parent -Force|Out-Null}
[IO.File]::WriteAllText($outFull,($binding|ConvertTo-Json -Depth 40),[Text.UTF8Encoding]::new($false))
[pscustomobject]@{status='created';bindingId=$binding.bindingId;taskId=$taskId;bindingHash=$binding.bindingHash;outputPath=$outFull} 
