[CmdletBinding()]
param([string]$ProjectRoot)
$ErrorActionPreference='Stop'
if([string]::IsNullOrWhiteSpace($ProjectRoot)){$ProjectRoot=(Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path}
Import-Module (Join-Path $ProjectRoot 'ES/Automation/ABCD/ESABCInnovationRun.psm1') -Force
$commands=New-ESABCEngineeringProjectDimensionCommands -ProjectRoot $ProjectRoot
$required=@('lifecycle','performance','network','debugging','editorProduction')
$pass=(@($commands.Keys|Where-Object {$_ -in $required}).Count -eq 5 -and @($required|Where-Object {$commands[$_] -is [scriptblock]}).Count -eq 5)
[pscustomobject]@{status=if($pass){'passed'}else{'failed'};dimensionCount=$commands.Count;mappedDimensions=@($commands.Keys);runtimeExecution='not-run'}
if(-not $pass){exit 1} 
