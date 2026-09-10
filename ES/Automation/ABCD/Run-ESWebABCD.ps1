[CmdletBinding()]
param(
  [Parameter(Mandatory=$true)][string]$TaskPath,
  [Parameter(Mandatory=$true)][string]$RoutePath,
  [Parameter(Mandatory=$true)][string]$RoutePlanPath,
  [Parameter(Mandatory=$true)][string]$BindingPath,
  [Parameter(Mandatory=$true)][string]$ArtifactPath,
  [Parameter(Mandatory=$true)][string]$ModelResponsePath,
  [Parameter(Mandatory=$true)][string]$Round01Path,
  [Parameter(Mandatory=$true)][string]$Round02Path,
  [Parameter(Mandatory=$true)][string]$Round03Path,
  [Parameter(Mandatory=$true)][string]$Round04Path,
  [Parameter(Mandatory=$true)][string]$Round05Path,
  [ValidateSet('deep-creative-engineering','creative-divergence','engineering','stable')][string]$GenerationProfile='deep-creative-engineering',
  [switch]$RequireFullAbcd,
  [string]$OutputPath='ES/Output/WebPageStudio/bootstrap/abcd-web-execution-receipt.json',
  [string]$AiDesignTaskOutputPath='ES/Output/WebPageStudio/bootstrap/ai-web-design-task.json'
)
$ErrorActionPreference='Stop'
$runner=Join-Path $PSScriptRoot 'Run-GitHubWebABCD.ps1'
& $runner -OutputPath $OutputPath -TaskPath $TaskPath -RoutePath $RoutePath -RoutePlanPath $RoutePlanPath -BindingPath $BindingPath -ArtifactPath $ArtifactPath -ModelResponsePath $ModelResponsePath -GenerationProfile $GenerationProfile -RequireFullAbcd:$RequireFullAbcd -Round01Path $Round01Path -Round02Path $Round02Path -Round03Path $Round03Path -Round04Path $Round04Path -Round05Path $Round05Path -AiDesignTaskOutputPath $AiDesignTaskOutputPath
